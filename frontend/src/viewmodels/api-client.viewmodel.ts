// frontend/src/viewmodels/api-client.viewmodel.ts
// Enhanced API client with comprehensive error handling
// Features:
// - Retry with exponential backoff
// - Circuit breaker protection
// - Network connectivity awareness
// - Error telemetry tracking
// - Timeout handling

import {
  type ApiResponse,
  ErrorCode,
  type ErrorValue,
  isError,
  isSuccess,
  type Result,
  toResult,
  err,
} from '../types';
import { getLogger } from './logger.viewmodel';
import { errorInterceptor } from '../core/error-interceptor';
import { RetryService } from '../core/retry.service';
import { ErrorRecoveryService } from '../core/error-recovery.service';
import { NetworkMonitorService } from '../core/network-monitor.service';
import { ErrorTelemetryService } from '../core/error-telemetry.service';

const logger = getLogger('api-client');

/**
 * API Client configuration
 */
export interface ApiClientConfig {
  /** Default timeout in milliseconds */
  timeoutMs: number;
  /** Enable retry logic */
  enableRetry: boolean;
  /** Enable circuit breaker */
  enableCircuitBreaker: boolean;
  /** Enable telemetry tracking */
  enableTelemetry: boolean;
}

const DEFAULT_CONFIG: ApiClientConfig = {
  timeoutMs: 30000,
  enableRetry: true,
  enableCircuitBreaker: true,
  enableTelemetry: true,
};

/**
 * Enhanced API Client with comprehensive error handling
 */
class ApiClient {
  private readonly config: ApiClientConfig;
  private readonly retryService: RetryService;
  private readonly recoveryService: ErrorRecoveryService;
  private readonly networkMonitor: NetworkMonitorService;
  private readonly telemetry: ErrorTelemetryService;

  constructor(config?: Partial<ApiClientConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.retryService = new RetryService();
    this.recoveryService = new ErrorRecoveryService(
      new NetworkMonitorService()
    );
    this.networkMonitor = new NetworkMonitorService();
    this.telemetry = new ErrorTelemetryService();

    // Register built-in recovery strategies
    this.recoveryService.registerStrategy({
      errorCodes: [ErrorCode.DbConnectionFailed, ErrorCode.InternalError],
      action: async () => {
        await new Promise(resolve => setTimeout(resolve, 1000));
        return true;
      },
      maxAttempts: 2,
    });

    logger.info('API Client initialized', { config: this.config });
  }

  /**
   * Call a backend function with full error handling
   */
  async callBackend<T>(
    functionName: string,
    args: unknown[] = [],
    options?: CallOptions
  ): Promise<Result<T>> {
    const startTime = Date.now();
    const operationName = options?.operationName || functionName;

    logger.debug(`Calling backend: ${operationName}`, { args: JSON.stringify(args) });

    // Check network status first
    if (!this.networkMonitor.isOnline()) {
      const error: ErrorValue = {
        code: ErrorCode.DbConnectionFailed,
        message: 'Network is offline. Please check your connection.',
        context: { operation: operationName },
      };
      this.telemetry.recordError(error, { source: 'api-client', operation: operationName });
      return err(error);
    }

    // Check circuit breaker
    if (this.config.enableCircuitBreaker && this.recoveryService.isCircuitOpen()) {
      const error: ErrorValue = {
        code: ErrorCode.InternalError,
        message: 'Service temporarily unavailable (circuit breaker open)',
        context: { operation: operationName, circuitState: 'open' },
      };
      this.telemetry.recordError(error, { source: 'circuit-breaker', operation: operationName });
      return err(error);
    }

    try {
      const result = await this.executeWithRetry(operationName, () =>
        this.executeCall(functionName, args, options)
      );

      // Record performance metrics
      const latency = Date.now() - startTime;
      this.networkMonitor.recordRequest(latency, isSuccessResult(result));

      if (this.config.enableTelemetry) {
        this.telemetry.recordPerformance(operationName, latency, {
          success: isSuccessResult(result) ? 1 : 0,
        });
      }

      return result;
    } catch (error) {
      const errorValue = this.normalizeError(error, operationName);
      
      if (this.config.enableTelemetry) {
        this.telemetry.recordError(errorValue, {
          source: 'api-client',
          operation: operationName,
        });
      }

      return err(errorValue);
    }
  }

  /**
   * Call with fallback function
   */
  async callWithFallback<T>(
    primaryFn: () => Promise<Result<T>>,
    fallbackFn: () => Promise<Result<T>>,
    operationName: string
  ): Promise<Result<T>> {
    const startTime = Date.now();

    try {
      const primaryResult = await this.executeWithRetry(operationName, primaryFn);

      if (isSuccessResult(primaryResult)) {
        const latency = Date.now() - startTime;
        this.networkMonitor.recordRequest(latency, true);
        return primaryResult;
      }

      logger.warn('Primary operation failed, using fallback', { operation: operationName });
      
      const fallbackResult = await fallbackFn();
      const latency = Date.now() - startTime;
      this.networkMonitor.recordRequest(latency, isSuccessResult(fallbackResult));

      return fallbackResult;
    } catch (error) {
      const errorValue = this.normalizeError(error, operationName);
      this.networkMonitor.recordRequest(Date.now() - startTime, false);
      return err(errorValue);
    }
  }

  /**
   * Wait for network to be online before executing
   */
  async callWhenOnline<T>(
    functionName: string,
    args: unknown[] = [],
    timeoutMs = 60000
  ): Promise<Result<T>> {
    const isOnline = await this.networkMonitor.waitForOnline(timeoutMs);

    if (!isOnline) {
      return err({
        code: ErrorCode.DbConnectionFailed,
        message: `Network not available within ${timeoutMs}ms`,
        context: { operation: functionName, timeout: timeoutMs },
      });
    }

    return this.callBackend(functionName, args);
  }

  /**
   * Get network status
   */
  getNetworkStatus() {
    return this.networkMonitor.getStatus();
  }

  /**
   * Get circuit breaker state
   */
  getCircuitBreakerState() {
    return this.recoveryService.getState();
  }

  /**
   * Get telemetry report
   */
  getTelemetryReport() {
    return this.telemetry.generateReport();
  }

  /**
   * Clear telemetry
   */
  clearTelemetry() {
    this.telemetry.clear();
  }

  private async executeWithRetry<T>(
    operationName: string,
    operation: () => Promise<Result<T>>
  ): Promise<Result<T>> {
    if (!this.config.enableRetry) {
      return operation();
    }

    return this.retryService.executeWithRetry(operation, {
      maxRetries: 3,
      initialDelayMs: 1000,
      maxDelayMs: 10000,
      backoffMultiplier: 2,
      retryableErrorCodes: [
        ErrorCode.DbConnectionFailed,
        ErrorCode.DbQueryFailed,
        ErrorCode.InternalError,
        ErrorCode.TimeoutError,
      ],
    }, operationName);
  }

  private async executeCall<T>(
    functionName: string,
    args: unknown[],
    options?: CallOptions
  ): Promise<Result<T>> {
    return new Promise((resolve, reject) => {
      const responseEventName = getResponseEventName(functionName);
      const timeoutMs = options?.timeoutMs || this.config.timeoutMs;

      const handler = (event: CustomEvent<ApiResponse<T>>) => {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);

        const response = event.detail;

        if (isError(response)) {
          logger.warn(`Backend error: ${response.error.code}`, { error: response.error });
          
          // Use error interceptor for consistent handling
          errorInterceptor.handleError(response.error, {
            source: 'webui',
            operation: functionName,
            timestamp: Date.now(),
          });

          resolve(toResult(response));
        } else if (isSuccess(response)) {
          logger.info(`Backend success: ${functionName}`);
          resolve(toResult(response));
        }
      };

      const timeoutId = setTimeout(() => {
        window.removeEventListener(responseEventName, handler as EventListener);
        logger.error(`Backend call timeout: ${functionName}`);
        
        reject({
          code: ErrorCode.TimeoutError,
          message: `Request timeout after ${timeoutMs}ms`,
          context: { operation: functionName, timeout: timeoutMs },
        });
      }, timeoutMs);

      // Call the backend function
      try {
        const backendFn = (window as unknown as Record<string, unknown>)[functionName];

        if (typeof backendFn !== 'function') {
          clearTimeout(timeoutId);
          window.removeEventListener(responseEventName, handler as EventListener);
          logger.error(`Backend function not found: ${functionName}`);
          
          reject({
            code: ErrorCode.InternalError,
            message: `Backend function not found: ${functionName}`,
            details: 'The function is not bound or available',
          });
          return;
        }

        backendFn(...args);
        logger.debug(`Backend call initiated: ${functionName}`);
      } catch (error) {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);
        logger.error(`Backend call failed: ${functionName}`, { error: String(error) });
        reject(error);
      }
    });
  }

  private normalizeError(error: unknown, operation: string): ErrorValue {
    if (error && typeof error === 'object' && 'code' in error) {
      return error as ErrorValue;
    }
    if (error instanceof Error) {
      return {
        code: ErrorCode.InternalError,
        message: error.message,
        details: error.stack,
        context: { operation },
      };
    }
    return {
      code: ErrorCode.Unknown,
      message: String(error),
      context: { operation },
    };
  }
}

interface CallOptions {
  timeoutMs?: number;
  operationName?: string;
  skipRetry?: boolean;
  skipTelemetry?: boolean;
}

function getResponseEventName(functionName: string): string {
  const eventMap: Record<string, string> = {
    get_users: 'db_response',
    create_user: 'user_create_response',
    update_user: 'user_update_response',
    delete_user: 'user_delete_response',
    get_db_stats: 'stats_response',
    get_error_stats: 'error_stats_response',
    get_recent_errors: 'recent_errors_response',
    clear_error_history: 'error_history_cleared',
  };
  return eventMap[functionName] || `${functionName}_response`;
}

function isSuccessResult<T>(result: Result<T>): boolean {
  return result.ok === true;
}

// Singleton instance
export const apiClient = new ApiClient();

// Export convenience functions
export async function callBackend<T>(
  functionName: string,
  ...args: unknown[]
): Promise<Result<T>> {
  return apiClient.callBackend(functionName, args);
}

export async function callWhenOnline<T>(
  functionName: string,
  ...args: unknown[]
): Promise<Result<T>> {
  return apiClient.callWhenOnline(functionName, args);
}

// Re-export types
export * from './api-client.viewmodel';
