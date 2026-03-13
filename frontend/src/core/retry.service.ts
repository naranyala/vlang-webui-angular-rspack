// frontend/src/core/retry.service.ts
// Retry logic with exponential backoff for resilient operations

import { Injectable, signal, computed } from '@angular/core';
import { ErrorCode, type ErrorValue, type Result, isOk, err, ok } from '../types';
import { getLogger } from '../viewmodels/logger.viewmodel';

export interface RetryConfig {
  /** Maximum number of retry attempts */
  maxRetries: number;
  /** Initial delay in milliseconds */
  initialDelayMs: number;
  /** Maximum delay in milliseconds */
  maxDelayMs: number;
  /** Backoff multiplier (e.g., 2 = exponential) */
  backoffMultiplier: number;
  /** Which error codes should trigger retry */
  retryableErrorCodes: ErrorCode[];
  /** Whether to add jitter to delays */
  useJitter: boolean;
}

export interface RetryState {
  attempt: number;
  lastError: ErrorValue | null;
  lastDelay: number;
  startTime: number;
  endTime: number | null;
  success: boolean;
}

const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  retryableErrorCodes: [
    ErrorCode.DbConnectionFailed,
    ErrorCode.DbQueryFailed,
    ErrorCode.InternalError,
    ErrorCode.TimeoutError,
    ErrorCode.Unknown,
  ],
  useJitter: true,
};

@Injectable({ providedIn: 'root' })
export class RetryService {
  private readonly logger = getLogger('retry.service');
  private readonly state = signal<RetryState>({
    attempt: 0,
    lastError: null,
    lastDelay: 0,
    startTime: 0,
    endTime: null,
    success: false,
  });

  readonly currentAttempt = computed(() => this.state().attempt);
  readonly isRetrying = computed(() => !this.state().success && this.state().endTime === null);
  readonly lastError = computed(() => this.state().lastError);

  /**
   * Execute an async operation with retry logic
   */
  async executeWithRetry<T>(
    operation: () => Promise<Result<T>>,
    config: Partial<RetryConfig> = {},
    operationName = 'Operation'
  ): Promise<Result<T>> {
    const finalConfig = { ...DEFAULT_RETRY_CONFIG, ...config };
    const state = this.createInitialState();
    
    this.state.set(state);
    this.logger.info(`Starting ${operationName} with retry`, {
      maxRetries: finalConfig.maxRetries,
      initialDelay: finalConfig.initialDelayMs,
    });

    let lastResult: Result<T> | null = null;

    for (let attempt = 0; attempt <= finalConfig.maxRetries; attempt++) {
      state.attempt = attempt;
      
      if (attempt > 0) {
        // Calculate delay with exponential backoff
        const delay = this.calculateDelay(attempt, finalConfig);
        state.lastDelay = delay;
        
        this.logger.warn(`${operationName} failed, retrying in ${delay}ms`, {
          attempt,
          maxRetries: finalConfig.maxRetries,
          error: state.lastError,
        });

        await this.sleep(delay);
      }

      try {
        lastResult = await operation();
        
        if (isOk(lastResult)) {
          state.success = true;
          state.endTime = Date.now();
          this.state.set({ ...state });
          
          this.logger.info(`${operationName} succeeded after ${attempt + 1} attempt(s)`, {
            duration: state.endTime - state.startTime,
          });
          
          return lastResult;
        }

        // Check if error is retryable
        if (!this.isRetryableError(lastResult.error, finalConfig)) {
          this.logger.info(`${operationName} failed with non-retryable error`, {
            error: lastResult.error,
          });
          break;
        }

        state.lastError = lastResult.error;
      } catch (error) {
        const errorValue = this.normalizeError(error);
        state.lastError = errorValue;
        
        if (!this.isRetryableError(errorValue, finalConfig)) {
          this.logger.info(`${operationName} failed with non-retryable exception`, {
            error: errorValue,
          });
          break;
        }
      }

      this.state.set({ ...state });
    }

    // All retries exhausted or non-retryable error
    state.endTime = Date.now();
    state.success = false;
    this.state.set(state);

    this.logger.error(`${operationName} failed after ${state.attempt + 1} attempt(s)`, {
      error: state.lastError,
      duration: state.endTime - state.startTime,
    });

    return lastResult ?? err({
      code: ErrorCode.InternalError,
      message: `${operationName} failed after ${state.attempt + 1} attempts`,
      cause: state.lastError?.message,
    });
  }

  /**
   * Execute with retry and exponential backoff, returning just the value or null
   */
  async executeWithRetryOr<T>(
    operation: () => Promise<Result<T>>,
    config: Partial<RetryConfig> = {},
    operationName = 'Operation'
  ): Promise<T | null> {
    const result = await this.executeWithRetry(operation, config, operationName);
    return isOk(result) ? result.value : null;
  }

  /**
   * Reset retry state
   */
  reset(): void {
    this.state.set(this.createInitialState());
  }

  /**
   * Get retry statistics
   */
  getStats(): { attempt: number; success: boolean; lastError: ErrorValue | null } {
    const s = this.state();
    return {
      attempt: s.attempt,
      success: s.success,
      lastError: s.lastError,
    };
  }

  private createInitialState(): RetryState {
    return {
      attempt: 0,
      lastError: null,
      lastDelay: 0,
      startTime: Date.now(),
      endTime: null,
      success: false,
    };
  }

  private calculateDelay(attempt: number, config: RetryConfig): number {
    // Exponential backoff: delay = initial * (multiplier ^ (attempt - 1))
    const exponentialDelay = config.initialDelayMs * Math.pow(config.backoffMultiplier, attempt - 1);
    
    // Cap at max delay
    const cappedDelay = Math.min(exponentialDelay, config.maxDelayMs);
    
    // Add jitter if configured (±25% randomization)
    if (config.useJitter) {
      const jitter = cappedDelay * 0.25 * (Math.random() * 2 - 1);
      return Math.max(0, Math.round(cappedDelay + jitter));
    }
    
    return Math.round(cappedDelay);
  }

  private isRetryableError(error: ErrorValue, config: RetryConfig): boolean {
    return config.retryableErrorCodes.includes(error.code);
  }

  private normalizeError(error: unknown): ErrorValue {
    if (error && typeof error === 'object' && 'code' in error) {
      return error as ErrorValue;
    }
    if (error instanceof Error) {
      return {
        code: ErrorCode.InternalError,
        message: error.message,
        details: error.stack,
      };
    }
    return {
      code: ErrorCode.Unknown,
      message: String(error),
    };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Higher-order function for creating retryable operations
 */
export function withRetry<T>(
  operation: () => Promise<Result<T>>,
  config?: Partial<RetryConfig>,
  name?: string
): () => Promise<Result<T>> {
  const retryService = new RetryService();
  return () => retryService.executeWithRetry(operation, config, name);
}
