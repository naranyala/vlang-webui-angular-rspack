// HTTP client service with error handling, caching, and retry support
import { Injectable, signal, computed } from '@angular/core';
import { ErrorCode, type ErrorValue, type Result, err, ok, isOk } from '../types';
import { getLogger } from '../viewmodels/logger.viewmodel';
import { StorageService } from './storage.service';

export interface HttpRequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  body?: unknown;
  timeout?: number;
  cache?: boolean;
  cacheTtl?: number;
  retry?: boolean;
  maxRetries?: number;
}

export interface HttpResponse<T> {
  status: number;
  statusText: string;
  headers: Record<string, string>;
  body: T;
  url?: string;
  ok: boolean;
}

export interface HttpStats {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  avgLatency: number;
  cacheHits: number;
  cacheMisses: number;
}

const DEFAULT_TIMEOUT = 30000;
const DEFAULT_CACHE_TTL = 60000; // 1 minute
const DEFAULT_MAX_RETRIES = 3;

@Injectable({ providedIn: 'root' })
export class HttpService {
  private readonly logger = getLogger('http.service');
  private readonly storage: StorageService;

  private readonly baseUrl = signal<string>('');
  private readonly defaultHeaders = signal<Record<string, string>>({
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  });

  private readonly stats = signal<HttpStats>({
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    avgLatency: 0,
    cacheHits: 0,
    cacheMisses: 0,
  });

  private readonly pendingRequests = new Map<string, AbortController>();

  readonly isBusy = computed(() => this.pendingRequests.size > 0);
  readonly requestCount = computed(() => this.stats().totalRequests);
  readonly successRate = computed(() => {
    const s = this.stats();
    if (s.totalRequests === 0) return 100;
    return Math.round((s.successfulRequests / s.totalRequests) * 100);
  });

  constructor(storage: StorageService) {
    this.storage = storage;
    this.logger.debug('HTTP service initialized');
  }

  /**
   * Set the base URL for all requests
   */
  setBaseUrl(url: string): void {
    this.baseUrl.set(url);
    this.logger.debug('Base URL set', { url });
  }

  /**
   * Set default headers
   */
  setDefaultHeaders(headers: Record<string, string>): void {
    this.defaultHeaders.set({ ...this.defaultHeaders(), ...headers });
  }

  /**
   * Add an authorization header
   */
  setAuthToken(token: string): void {
    this.defaultHeaders.update(headers => ({
      ...headers,
      'Authorization': `Bearer ${token}`,
    }));
  }

  /**
   * Clear authorization header
   */
  clearAuthToken(): void {
    this.defaultHeaders.update(({ Authorization, ...rest }) => rest);
  }

  /**
   * GET request
   */
  async get<T>(url: string, options?: HttpRequestOptions): Promise<Result<T>> {
    return this.request<T>(url, { ...options, method: 'GET' });
  }

  /**
   * POST request
   */
  async post<T>(url: string, body?: unknown, options?: HttpRequestOptions): Promise<Result<T>> {
    return this.request<T>(url, { ...options, method: 'POST', body });
  }

  /**
   * PUT request
   */
  async put<T>(url: string, body?: unknown, options?: HttpRequestOptions): Promise<Result<T>> {
    return this.request<T>(url, { ...options, method: 'PUT', body });
  }

  /**
   * DELETE request
   */
  async delete<T>(url: string, options?: HttpRequestOptions): Promise<Result<T>> {
    return this.request<T>(url, { ...options, method: 'DELETE' });
  }

  /**
   * PATCH request
   */
  async patch<T>(url: string, body?: unknown, options?: HttpRequestOptions): Promise<Result<T>> {
    return this.request<T>(url, { ...options, method: 'PATCH', body });
  }

  /**
   * Generic request method
   */
  async request<T>(url: string, options: HttpRequestOptions = {}): Promise<Result<T>> {
    const startTime = Date.now();
    const method = options.method ?? 'GET';
    const fullUrl = this.buildUrl(url);
    const cacheKey = this.getCacheKey(fullUrl, options);

    this.updateStats({ totalRequests: s => s + 1 });

    // Check cache for GET requests
    if (method === 'GET' && options.cache !== false) {
      const cached = this.getCachedResponse<T>(cacheKey);
      if (cached) {
        this.updateStats({ cacheHits: s => s + 1 });
        this.logger.debug('Cache hit', { url: fullUrl });
        return ok(cached);
      }
      this.updateStats({ cacheMisses: s => s + 1 });
    }

    // Check for pending request
    if (this.pendingRequests.has(cacheKey)) {
      this.logger.debug('Request already pending, skipping', { url: fullUrl });
      return err({
        code: ErrorCode.RequestAborted,
        message: 'Request already in progress',
      });
    }

    const controller = new AbortController();
    this.pendingRequests.set(cacheKey, controller);

    try {
      const timeout = options.timeout ?? DEFAULT_TIMEOUT;
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      const headers = {
        ...this.defaultHeaders(),
        ...options.headers,
      };

      const response = await fetch(fullUrl, {
        method,
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      this.pendingRequests.delete(cacheKey);

      const latency = Date.now() - startTime;
      this.updateStats({
        avgLatency: (s, count) => ((s * count) + latency) / (count + 1),
      });

      // Parse response
      const contentType = response.headers.get('content-type');
      let body: T;

      if (contentType?.includes('application/json')) {
        body = await response.json();
      } else {
        body = await response.text() as unknown as T;
      }

      const httpResponse: HttpResponse<T> = {
        status: response.status,
        statusText: response.statusText,
        headers: Object.fromEntries(response.headers.entries()),
        body,
        url: response.url,
        ok: response.ok,
      };

      if (response.ok) {
        this.updateStats({ successfulRequests: s => s + 1 });

        // Cache successful GET responses
        if (method === 'GET' && options.cache !== false) {
          this.cacheResponse(cacheKey, httpResponse, options.cacheTtl ?? DEFAULT_CACHE_TTL);
        }

        this.logger.debug('Request successful', { url: fullUrl, status: response.status, latency });
        return ok(body);
      } else {
        this.updateStats({ failedRequests: s => s + 1 });
        this.logger.warn('Request failed', { url: fullUrl, status: response.status, body });

        return err({
          code: this.mapStatusCodeToErrorCode(response.status),
          message: `HTTP ${response.status}: ${response.statusText}`,
          details: JSON.stringify(body),
        });
      }
    } catch (error) {
      this.pendingRequests.delete(cacheKey);
      this.updateStats({ failedRequests: s => s + 1 });

      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          this.logger.warn('Request timeout', { url: fullUrl, timeout });
          return err({
            code: ErrorCode.TimeoutError,
            message: `Request timeout after ${timeout}ms`,
          });
        }

        if (error.message.includes('Failed to fetch')) {
          this.logger.error('Network error', { url: fullUrl });
          return err({
            code: ErrorCode.NetworkError,
            message: 'Network error - unable to reach server',
          });
        }
      }

      this.logger.error('Request error', { url: fullUrl, error });
      return err({
        code: ErrorCode.InternalError,
        message: error instanceof Error ? error.message : 'Unknown error',
        details: error instanceof Error ? error.stack : undefined,
      });
    }
  }

  /**
   * Cancel a pending request
   */
  cancel(url: string): void {
    const fullUrl = this.buildUrl(url);
    const cacheKey = this.getCacheKey(fullUrl, {});
    const controller = this.pendingRequests.get(cacheKey);

    if (controller) {
      controller.abort();
      this.pendingRequests.delete(cacheKey);
      this.logger.debug('Request cancelled', { url });
    }
  }

  /**
   * Cancel all pending requests
   */
  cancelAll(): void {
    for (const [key, controller] of this.pendingRequests.entries()) {
      controller.abort();
      this.pendingRequests.delete(key);
    }
    this.logger.debug('All requests cancelled');
  }

  /**
   * Get HTTP statistics
   */
  getStats(): HttpStats {
    return { ...this.stats() };
  }

  /**
   * Reset statistics
   */
  resetStats(): void {
    this.stats.set({
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      avgLatency: 0,
      cacheHits: 0,
      cacheMisses: 0,
    });
  }

  /**
   * Clear HTTP cache
   */
  clearCache(): void {
    this.storage.clear();
    this.logger.info('HTTP cache cleared');
  }

  private buildUrl(url: string): string {
    const base = this.baseUrl();
    if (!base) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    
    const baseUrl = base.endsWith('/') ? base.slice(0, -1) : base;
    const requestUrl = url.startsWith('/') ? url : '/' + url;
    return baseUrl + requestUrl;
  }

  private getCacheKey(url: string, options: HttpRequestOptions): string {
    const method = options.method ?? 'GET';
    const body = options.body ? JSON.stringify(options.body) : '';
    return `http:cache:${method}:${url}:${body}`;
  }

  private getCachedResponse<T>(cacheKey: string): T | null {
    return this.storage.get<T>(cacheKey);
  }

  private cacheResponse<T>(cacheKey: string, response: HttpResponse<T>, ttl: number): void {
    this.storage.set(cacheKey, response.body, { ttl });
  }

  private updateStats(updates: Partial<{
    totalRequests: (s: number) => number;
    successfulRequests: (s: number) => number;
    failedRequests: (s: number) => number;
    avgLatency: (s: number, count: number) => number;
    cacheHits: (s: number) => number;
    cacheMisses: (s: number) => number;
  }>): void {
    this.stats.update(s => {
      const updatesCopy = { ...updates };
      const result: HttpStats = { ...s };

      if (updatesCopy.totalRequests) {
        result.totalRequests = updatesCopy.totalRequests(s.totalRequests);
      }
      if (updatesCopy.successfulRequests) {
        result.successfulRequests = updatesCopy.successfulRequests(s.successfulRequests);
      }
      if (updatesCopy.failedRequests) {
        result.failedRequests = updatesCopy.failedRequests(s.failedRequests);
      }
      if (updatesCopy.avgLatency) {
        result.avgLatency = updatesCopy.avgLatency(s.avgLatency, s.totalRequests);
      }
      if (updatesCopy.cacheHits) {
        result.cacheHits = updatesCopy.cacheHits(s.cacheHits);
      }
      if (updatesCopy.cacheMisses) {
        result.cacheMisses = updatesCopy.cacheMisses(s.cacheMisses);
      }

      return result;
    });
  }

  private mapStatusCodeToErrorCode(status: number): ErrorCode {
    switch (status) {
      case 400: return ErrorCode.InvalidInput;
      case 401: return ErrorCode.Unauthorized;
      case 403: return ErrorCode.PermissionDenied;
      case 404: return ErrorCode.NotFound;
      case 408: return ErrorCode.TimeoutError;
      case 409: return ErrorCode.Conflict;
      case 422: return ErrorCode.InvalidInput;
      case 429: return ErrorCode.RateLimitExceeded;
      case 500: return ErrorCode.InternalError;
      case 502: return ErrorCode.NetworkError;
      case 503: return ErrorCode.ServiceUnavailable;
      case 504: return ErrorCode.TimeoutError;
      default: return ErrorCode.Unknown;
    }
  }
}
