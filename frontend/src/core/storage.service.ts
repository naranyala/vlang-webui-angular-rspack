// Storage service with LocalStorage, SessionStorage, and Memory backends
import { Injectable, signal, computed } from '@angular/core';
import { getLogger } from '../viewmodels/logger.viewmodel';

export type StorageBackend = 'local' | 'session' | 'memory';

export interface StorageOptions {
  prefix?: string;
  ttl?: number; // Time to live in milliseconds
}

export interface StorageEntry<T> {
  value: T;
  expires?: number;
  createdAt: number;
}

@Injectable({ providedIn: 'root' })
export class StorageService {
  private readonly logger = getLogger('storage.service');
  private readonly prefix: string;
  private readonly ttl?: number;
  private readonly memoryStore = new Map<string, StorageEntry<unknown>>();

  private readonly keys = signal<string[]>([]);

  readonly count = computed(() => this.keys().length);

  constructor(options: StorageOptions = {}) {
    this.prefix = options.prefix ?? 'app:';
    this.ttl = options.ttl;
    this.loadKeys();
    this.logger.debug('Storage service initialized', { prefix: this.prefix, ttl: this.ttl });
  }

  /**
   * Get a value from storage
   */
  get<T>(key: string, defaultValue?: T): T | null {
    const fullKey = this.prefix + key;
    const entry = this.getEntry(fullKey);

    if (!entry) {
      return defaultValue ?? null;
    }

    // Check expiration
    if (entry.expires && Date.now() > entry.expires) {
      this.delete(key);
      return defaultValue ?? null;
    }

    return entry.value as T;
  }

  /**
   * Set a value in storage
   */
  set<T>(key: string, value: T, options?: { ttl?: number }): void {
    const fullKey = this.prefix + key;
    const entry: StorageEntry<T> = {
      value,
      createdAt: Date.now(),
      expires: options?.ttl ?? this.ttl ? Date.now() + (options?.ttl ?? this.ttl!) : undefined,
    };

    try {
      localStorage.setItem(fullKey, JSON.stringify(entry));
      this.loadKeys();
      this.logger.debug('Value set', { key, hasExpiry: !!entry.expires });
    } catch (error) {
      // Fallback to memory storage if localStorage fails (quota exceeded, private mode, etc.)
      this.logger.warn('LocalStorage failed, using memory storage', { error });
      this.memoryStore.set(fullKey, entry as StorageEntry<unknown>);
      this.loadKeys();
    }
  }

  /**
   * Delete a value from storage
   */
  delete(key: string): boolean {
    const fullKey = this.prefix + key;

    try {
      localStorage.removeItem(fullKey);
      this.loadKeys();
      this.logger.debug('Value deleted', { key });
      return true;
    } catch {
      this.memoryStore.delete(fullKey);
      this.loadKeys();
      return true;
    }
  }

  /**
   * Check if a key exists in storage
   */
  has(key: string): boolean {
    const fullKey = this.prefix + key;
    return this.getEntry(fullKey) !== null;
  }

  /**
   * Get all keys
   */
  getAllKeys(): string[] {
    return this.keys();
  }

  /**
   * Get all values
   */
  getAll<T>(): Record<string, T> {
    const result: Record<string, T> = {};
    for (const key of this.keys()) {
      const value = this.get<T>(key);
      if (value !== null) {
        result[key] = value;
      }
    }
    return result;
  }

  /**
   * Clear all storage
   */
  clear(): void {
    try {
      for (const key of this.keys()) {
        const fullKey = this.prefix + key;
        localStorage.removeItem(fullKey);
      }
      this.memoryStore.clear();
      this.loadKeys();
      this.logger.info('Storage cleared');
    } catch (error) {
      this.logger.error('Failed to clear storage', { error });
    }
  }

  /**
   * Get storage statistics
   */
  getStats(): { count: number; estimatedSize: number; backend: StorageBackend } {
    let estimatedSize = 0;
    let backend: StorageBackend = 'local';

    try {
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key?.startsWith(this.prefix)) {
          const value = localStorage.getItem(key);
          estimatedSize += (key.length + (value?.length ?? 0)) * 2; // UTF-16
        }
      }
    } catch {
      backend = 'memory';
      for (const [key, entry] of this.memoryStore.entries()) {
        if (key.startsWith(this.prefix)) {
          estimatedSize += (key.length + JSON.stringify(entry.value).length) * 2;
        }
      }
    }

    return {
      count: this.keys().length,
      estimatedSize,
      backend,
    };
  }

  /**
   * Clean up expired entries
   */
  cleanup(): number {
    let cleaned = 0;
    for (const key of this.keys()) {
      const fullKey = this.prefix + key;
      const entry = this.getEntry(fullKey);
      if (entry && entry.expires && Date.now() > entry.expires) {
        this.delete(key);
        cleaned++;
      }
    }
    if (cleaned > 0) {
      this.logger.debug('Cleaned up expired entries', { count: cleaned });
    }
    return cleaned;
  }

  private getEntry<T>(key: string): StorageEntry<T> | null {
    try {
      const item = localStorage.getItem(key);
      if (item) {
        return JSON.parse(item) as StorageEntry<T>;
      }
    } catch {
      // Item not found or parse error
    }

    return (this.memoryStore.get(key) as StorageEntry<T>) ?? null;
  }

  private loadKeys(): void {
    const keys: string[] = [];

    try {
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key?.startsWith(this.prefix)) {
          keys.push(key.replace(this.prefix, ''));
        }
      }
    } catch {
      // localStorage not available
    }

    // Also include memory storage keys
    for (const key of this.memoryStore.keys()) {
      if (key.startsWith(this.prefix)) {
        keys.push(key.replace(this.prefix, ''));
      }
    }

    this.keys.set(keys);
  }
}

/**
 * Convenience wrapper for session storage
 */
@Injectable({ providedIn: 'root' })
export class SessionStorageService {
  private readonly storage: StorageService;

  constructor() {
    this.storage = new StorageService({ prefix: 'session:', ttl: undefined });
  }

  get<T>(key: string, defaultValue?: T): T | null {
    return this.storage.get<T>(key, defaultValue);
  }

  set<T>(key: string, value: T): void {
    this.storage.set(key, value);
  }

  delete(key: string): boolean {
    return this.storage.delete(key);
  }

  has(key: string): boolean {
    return this.storage.has(key);
  }

  clear(): void {
    this.storage.clear();
  }
}

/**
 * Convenience wrapper for persistent storage with long TTL
 */
@Injectable({ providedIn: 'root' })
export class PersistentStorageService {
  private readonly storage: StorageService;

  constructor() {
    // 30 days TTL
    this.storage = new StorageService({ prefix: 'persist:', ttl: 30 * 24 * 60 * 60 * 1000 });
  }

  get<T>(key: string, defaultValue?: T): T | null {
    return this.storage.get<T>(key, defaultValue);
  }

  set<T>(key: string, value: T): void {
    // Persistent storage doesn't expire by default
    this.storage.set(key, value, { ttl: undefined });
  }

  delete(key: string): boolean {
    return this.storage.delete(key);
  }

  has(key: string): boolean {
    return this.storage.has(key);
  }

  clear(): void {
    this.storage.clear();
  }
}
