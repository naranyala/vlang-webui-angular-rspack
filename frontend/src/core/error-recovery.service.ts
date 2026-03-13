// frontend/src/core/error-recovery.service.ts
// Error recovery utilities with circuit breaker and fallback patterns

import { Injectable, signal, computed } from '@angular/core';
import { ErrorCode, type ErrorValue, type Result, isOk, err, ok } from '../types';
import { getLogger } from '../viewmodels/logger.viewmodel';
import { NetworkMonitorService } from './network-monitor.service';

export interface CircuitBreakerState {
  status: 'closed' | 'open' | 'half-open';
  failureCount: number;
  successCount: number;
  lastFailureTime: number | null;
  lastSuccessTime: number | null;
  nextRetryTime: number | null;
}

export interface RecoveryStrategy {
  /** Error codes this strategy handles */
  errorCodes: ErrorCode[];
  /** Recovery action to attempt */
  action: (error: ErrorValue) => Promise<boolean>;
  /** Max attempts before giving up */
  maxAttempts: number;
}

export interface CircuitBreakerConfig {
  /** Number of failures before opening circuit */
  failureThreshold: number;
  /** Time in ms before attempting recovery */
  resetTimeoutMs: number;
  /** Number of successes in half-open state to close circuit */
  successThreshold: number;
}

const DEFAULT_CIRCUIT_BREAKER_CONFIG: CircuitBreakerConfig = {
  failureThreshold: 5,
  resetTimeoutMs: 30000,
  successThreshold: 3,
};

@Injectable({ providedIn: 'root' })
export class ErrorRecoveryService {
  private readonly logger = getLogger('error-recovery');
  private readonly networkMonitor: NetworkMonitorService;
  
  private readonly circuitState = signal<CircuitBreakerState>({
    status: 'closed',
    failureCount: 0,
    successCount: 0,
    lastFailureTime: null,
    lastSuccessTime: null,
    nextRetryTime: null,
  });

  private strategies: RecoveryStrategy[] = [];
  private config: CircuitBreakerConfig = DEFAULT_CIRCUIT_BREAKER_CONFIG;

  readonly isCircuitOpen = computed(() => this.circuitState().status === 'open');
  readonly isCircuitClosed = computed(() => this.circuitState().status === 'closed');
  readonly isCircuitHalfOpen = computed(() => this.circuitState().status === 'half-open');
  readonly failureCount = computed(() => this.circuitState().failureCount);

  constructor(networkMonitor: NetworkMonitorService) {
    this.networkMonitor = networkMonitor;
    this.startCircuitBreakerMonitor();
  }

  /**
   * Register a recovery strategy
   */
  registerStrategy(strategy: RecoveryStrategy): void {
    this.strategies.push(strategy);
    this.logger.info('Recovery strategy registered', {
      errorCodes: strategy.errorCodes,
      maxAttempts: strategy.maxAttempts,
    });
  }

  /**
   * Execute operation with circuit breaker protection
   */
  async executeWithCircuitBreaker<T>(
    operation: () => Promise<Result<T>>,
    operationName: string
  ): Promise<Result<T>> {
    // Check if circuit is open
    if (!this.canExecute()) {
      this.logger.warn('Circuit breaker is open, rejecting request', { operation: operationName });
      return err({
        code: ErrorCode.InternalError,
        message: 'Service temporarily unavailable (circuit breaker open)',
        context: { operation: operationName },
      });
    }

    try {
      const result = await operation();

      if (isOk(result)) {
        this.recordSuccess();
        return result;
      }

      // Handle error
      this.recordFailure(result.error);
      
      // Try recovery strategies
      const recovered = await this.attemptRecovery(result.error);
      if (recovered) {
        this.logger.info('Recovery successful', { operation: operationName });
        return operation(); // Retry once after recovery
      }

      return result;
    } catch (error) {
      const errorValue = this.normalizeError(error);
      this.recordFailure(errorValue);
      
      const recovered = await this.attemptRecovery(errorValue);
      if (recovered) {
        return operation(); // Retry once after recovery
      }

      return err(errorValue);
    }
  }

  /**
   * Execute with fallback on failure
   */
  async executeWithFallback<T>(
    primary: () => Promise<Result<T>>,
    fallback: () => Promise<Result<T>>,
    operationName: string
  ): Promise<Result<T>> {
    const primaryResult = await this.executeWithCircuitBreaker(primary, operationName);

    if (isOk(primaryResult)) {
      return primaryResult;
    }

    this.logger.warn('Primary operation failed, using fallback', {
      operation: operationName,
      error: primaryResult.error,
    });

    return fallback();
  }

  /**
   * Attempt to recover from an error using registered strategies
   */
  async attemptRecovery(error: ErrorValue): Promise<boolean> {
    for (const strategy of this.strategies) {
      if (strategy.errorCodes.includes(error.code) || strategy.errorCodes.includes(ErrorCode.Unknown)) {
        this.logger.info('Attempting recovery strategy', {
          errorCode: error.code,
          maxAttempts: strategy.maxAttempts,
        });

        for (let attempt = 0; attempt < strategy.maxAttempts; attempt++) {
          try {
            const success = await strategy.action(error);
            if (success) {
              this.logger.info('Recovery strategy succeeded', {
                errorCode: error.code,
                attempt: attempt + 1,
              });
              return true;
            }
          } catch (recoveryError) {
            this.logger.warn('Recovery strategy attempt failed', {
              errorCode: error.code,
              attempt: attempt + 1,
              error: recoveryError,
            });
          }
        }
      }
    }

    return false;
  }

  /**
   * Reset circuit breaker to closed state
   */
  reset(): void {
    this.circuitState.set({
      status: 'closed',
      failureCount: 0,
      successCount: 0,
      lastFailureTime: null,
      lastSuccessTime: null,
      nextRetryTime: null,
    });
    this.logger.info('Circuit breaker reset');
  }

  /**
   * Get circuit breaker state
   */
  getState(): CircuitBreakerState {
    return { ...this.circuitState() };
  }

  private canExecute(): boolean {
    const state = this.circuitState();

    if (state.status === 'closed') {
      return true;
    }

    if (state.status === 'open' && state.nextRetryTime) {
      if (Date.now() >= state.nextRetryTime) {
        // Transition to half-open
        this.circuitState.update(s => ({
          ...s,
          status: 'half-open',
          successCount: 0,
        }));
        this.logger.info('Circuit breaker transitioning to half-open');
        return true;
      }
      return false;
    }

    // Half-open state allows requests
    return state.status === 'half-open';
  }

  private recordSuccess(): void {
    const state = this.circuitState();
    const successCount = state.successCount + 1;

    this.circuitState.set({
      ...state,
      successCount,
      lastSuccessTime: Date.now(),
      status: state.status === 'half-open' && successCount >= this.config.successThreshold
        ? 'closed'
        : state.status,
      failureCount: state.status === 'half-open' && successCount >= this.config.successThreshold
        ? 0
        : state.failureCount,
    });

    if (this.circuitState().status === 'closed') {
      this.logger.info('Circuit breaker closed after successful recovery');
    }
  }

  private recordFailure(error: ErrorValue): void {
    const state = this.circuitState();
    const failureCount = state.failureCount + 1;
    const now = Date.now();

    let newStatus = state.status;
    let nextRetryTime = state.nextRetryTime;

    // Open circuit if threshold exceeded
    if (failureCount >= this.config.failureThreshold && state.status !== 'open') {
      newStatus = 'open';
      nextRetryTime = now + this.config.resetTimeoutMs;
      this.logger.warn('Circuit breaker opened', {
        failureCount,
        threshold: this.config.failureThreshold,
        resetIn: this.config.resetTimeoutMs,
      });
    }

    this.circuitState.set({
      ...state,
      failureCount,
      lastFailureTime: now,
      status: newStatus,
      nextRetryTime,
    });

    // Check if error is network-related and network is offline
    if (this.isNetworkError(error) && this.networkMonitor.isOffline()) {
      this.logger.warn('Network-related error detected, monitoring connectivity');
    }
  }

  private isNetworkError(error: ErrorValue): boolean {
    return [
      ErrorCode.DbConnectionFailed,
      ErrorCode.InternalError,
      ErrorCode.Unknown,
    ].includes(error.code);
  }

  private startCircuitBreakerMonitor(): void {
    // Check every 5 seconds if we should transition from open to half-open
    setInterval(() => {
      const state = this.circuitState();
      if (state.status === 'open' && state.nextRetryTime && Date.now() >= state.nextRetryTime) {
        this.circuitState.update(s => ({
          ...s,
          status: 'half-open',
          successCount: 0,
        }));
        this.logger.info('Circuit breaker auto-transitioned to half-open');
      }
    }, 5000);
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
}

/**
 * Built-in recovery strategies
 */
export const createRecoveryStrategies = (): RecoveryStrategy[] => [
  {
    errorCodes: [ErrorCode.DbConnectionFailed, ErrorCode.InternalError],
    action: async () => {
      // Wait a bit and retry
      await new Promise(resolve => setTimeout(resolve, 1000));
      return true;
    },
    maxAttempts: 2,
  },
  {
    errorCodes: [ErrorCode.TimeoutError],
    action: async () => {
      // Wait longer for timeout errors
      await new Promise(resolve => setTimeout(resolve, 3000));
      return true;
    },
    maxAttempts: 1,
  },
];
