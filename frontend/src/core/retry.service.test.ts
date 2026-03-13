// frontend/src/core/retry.service.test.ts
// Retry service tests with exponential backoff

import { describe, expect, it, beforeEach, mock, spyOn } from 'bun:test';
import { RetryService } from './retry.service';
import { ErrorCode, type Result, ok, err } from '../types';

describe('RetryService', () => {
  let retryService: RetryService;

  beforeEach(() => {
    retryService = new RetryService();
  });

  describe('executeWithRetry', () => {
    it('should return successful result on first try', async () => {
      const operation = mock(() => Promise.resolve(ok('success')));
      
      const result = await retryService.executeWithRetry(operation, {}, 'TestOp');
      
      expect(result.ok).toBe(true);
      expect(operation).toHaveBeenCalledTimes(1);
    });

    it('should retry on failure and succeed', async () => {
      let attempts = 0;
      const operation = mock(async (): Promise<Result<string>> => {
        attempts++;
        if (attempts < 3) {
          return err({ code: ErrorCode.InternalError, message: 'Temporary failure' });
        }
        return ok('success');
      });

      const result = await retryService.executeWithRetry(operation, {
        maxRetries: 3,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(result.ok).toBe(true);
      expect(attempts).toBe(3);
    });

    it('should fail after max retries', async () => {
      const operation = mock(async (): Promise<Result<string>> => {
        return err({ code: ErrorCode.InternalError, message: 'Always fails' });
      });

      const result = await retryService.executeWithRetry(operation, {
        maxRetries: 2,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(result.ok).toBe(false);
      expect(operation).toHaveBeenCalledTimes(3); // Initial + 2 retries
    });

    it('should not retry non-retryable errors', async () => {
      let attempts = 0;
      const operation = mock(async (): Promise<Result<string>> => {
        attempts++;
        return err({ code: ErrorCode.ValidationFailed, message: 'Invalid input' });
      });

      const result = await retryService.executeWithRetry(operation, {
        maxRetries: 3,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(result.ok).toBe(false);
      expect(attempts).toBe(1); // Should not retry
    });

    it('should handle exceptions from operation', async () => {
      const operation = mock(() => {
        throw new Error('Unexpected exception');
      });

      const result = await retryService.executeWithRetry(operation, {
        maxRetries: 1,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(result.ok).toBe(false);
      expect(result.error.code).toBe(ErrorCode.InternalError);
    });
  });

  describe('executeWithRetryOr', () => {
    it('should return value on success', async () => {
      const operation = mock(() => Promise.resolve(ok(42)));
      
      const result = await retryService.executeWithRetryOr(operation, {}, 'TestOp');
      
      expect(result).toBe(42);
    });

    it('should return null on failure', async () => {
      const operation = mock(() => Promise.resolve(err({ 
        code: ErrorCode.InternalError, 
        message: 'Failed' 
      })));
      
      const result = await retryService.executeWithRetryOr(operation, {}, 'TestOp');
      
      expect(result).toBeNull();
    });
  });

  describe('Retry State', () => {
    it('should track current attempt', async () => {
      let attempts = 0;
      const operation = mock(async (): Promise<Result<string>> => {
        attempts++;
        expect(retryService.currentAttempt()).toBe(attempts - 1);
        if (attempts < 2) {
          return err({ code: ErrorCode.InternalError, message: 'Fail' });
        }
        return ok('success');
      });

      await retryService.executeWithRetry(operation, {
        initialDelayMs: 10,
      }, 'TestOp');

      expect(attempts).toBe(2);
    });

    it('should track retrying state', async () => {
      const operation = mock(async (): Promise<Result<string>> => {
        expect(retryService.isRetrying()).toBe(true);
        return err({ code: ErrorCode.InternalError, message: 'Fail' });
      });

      await retryService.executeWithRetry(operation, {
        maxRetries: 1,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(retryService.isRetrying()).toBe(false);
    });

    it('should track last error', async () => {
      const operation = mock(() => Promise.resolve(err({ 
        code: ErrorCode.TimeoutError, 
        message: 'Timeout' 
      })));

      await retryService.executeWithRetry(operation, {
        maxRetries: 1,
        initialDelayMs: 10,
      }, 'TestOp');

      expect(retryService.lastError()?.code).toBe(ErrorCode.TimeoutError);
    });
  });

  describe('Exponential Backoff', () => {
    it('should increase delay with each attempt', async () => {
      const delays: number[] = [];
      let attempt = 0;
      
      const originalSleep = (retryService as any).sleep;
      (retryService as any).sleep = mock(async (ms: number) => {
        delays.push(ms);
      });

      const operation = mock(async (): Promise<Result<string>> => {
        attempt++;
        if (attempt < 4) {
          return err({ code: ErrorCode.InternalError, message: 'Fail' });
        }
        return ok('success');
      });

      await retryService.executeWithRetry(operation, {
        maxRetries: 3,
        initialDelayMs: 100,
        backoffMultiplier: 2,
        useJitter: false,
      }, 'TestOp');

      // Delays should be: 100, 200, 400 (exponential)
      expect(delays[0]).toBeGreaterThanOrEqual(100);
      expect(delays[1]).toBeGreaterThan(delays[0]);
      expect(delays[2]).toBeGreaterThan(delays[1]);
    });

    it('should cap delay at maxDelayMs', async () => {
      const delays: number[] = [];
      
      const originalSleep = (retryService as any).sleep;
      (retryService as any).sleep = mock(async (ms: number) => {
        delays.push(ms);
      });

      let attempt = 0;
      const operation = mock(async (): Promise<Result<string>> => {
        attempt++;
        if (attempt < 5) {
          return err({ code: ErrorCode.InternalError, message: 'Fail' });
        }
        return ok('success');
      });

      await retryService.executeWithRetry(operation, {
        maxRetries: 4,
        initialDelayMs: 1000,
        maxDelayMs: 2000,
        backoffMultiplier: 2,
        useJitter: false,
      }, 'TestOp');

      // All delays after reaching max should be capped
      delays.forEach(delay => {
        expect(delay).toBeLessThanOrEqual(2000);
      });
    });
  });

  describe('getStats', () => {
    it('should return current stats', async () => {
      const operation = mock(() => Promise.resolve(err({ 
        code: ErrorCode.InternalError, 
        message: 'Fail' 
      })));

      await retryService.executeWithRetry(operation, {
        maxRetries: 1,
        initialDelayMs: 10,
      }, 'TestOp');

      const stats = retryService.getStats();
      expect(stats.attempt).toBe(1);
      expect(stats.success).toBe(false);
      expect(stats.lastError).not.toBeNull();
    });
  });

  describe('reset', () => {
    it('should reset state', async () => {
      const operation = mock(() => Promise.resolve(err({ 
        code: ErrorCode.InternalError, 
        message: 'Fail' 
      })));

      await retryService.executeWithRetry(operation, {
        maxRetries: 1,
        initialDelayMs: 10,
      }, 'TestOp');

      retryService.reset();

      expect(retryService.currentAttempt()).toBe(0);
      expect(retryService.lastError()).toBeNull();
    });
  });
});
