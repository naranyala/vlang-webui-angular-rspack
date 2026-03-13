// frontend/src/core/error-interceptor.test.ts
// Error interceptor tests

import { describe, expect, it, beforeEach, mock } from 'bun:test';
import { errorInterceptor, setupGlobalErrorInterception } from './error-interceptor';
import { ErrorCode } from '../types';

describe('ErrorInterceptor', () => {
  beforeEach(() => {
    errorInterceptor.clear();
  });

  describe('interceptWebUICall', () => {
    it('should return result on success', () => {
      const result = errorInterceptor.interceptWebUICall(
        'testOp',
        () => 'success'
      );
      expect(result).toBe('success');
    });

    it('should handle errors and return null', () => {
      const result = errorInterceptor.interceptWebUICall(
        'testOp',
        () => { throw new Error('Test error'); }
      );
      expect(result).toBeNull();
    });

    it('should track error statistics', () => {
      errorInterceptor.interceptWebUICall(
        'testOp',
        () => { throw new Error('Test error'); }
      );

      const stats = errorInterceptor.getStats();
      expect(stats.total).toBe(1);
      expect(stats.bySource.get('webui')).toBe(1);
    });
  });

  describe('interceptWebUIAsync', () => {
    it('should return result on success', async () => {
      const result = await errorInterceptor.interceptWebUIAsync(
        'testOp',
        async () => 'success'
      );
      expect(result).toBe('success');
    });

    it('should handle async errors', async () => {
      const result = await errorInterceptor.interceptWebUIAsync(
        'testOp',
        async () => { throw new Error('Async error'); }
      );
      expect(result).toBeNull();
    });
  });

  describe('interceptHttp', () => {
    it('should return result on success', async () => {
      const result = await errorInterceptor.interceptHttp(
        'testOp',
        async () => 'success'
      );
      expect(result).toBe('success');
    });

    it('should handle HTTP errors', async () => {
      const result = await errorInterceptor.interceptHttp(
        'testOp',
        async () => { throw new Error('HTTP error'); }
      );
      expect(result).toBeNull();
    });

    it('should track HTTP errors separately', async () => {
      await errorInterceptor.interceptHttp(
        'httpOp',
        async () => { throw new Error('HTTP error'); }
      );

      const stats = errorInterceptor.getStats();
      expect(stats.bySource.get('http')).toBe(1);
    });
  });

  describe('handleError', () => {
    it('should convert Error to ErrorValue', () => {
      const error = new Error('Test message');
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      errorInterceptor.handleError(error, context);
      
      const history = errorInterceptor.getHistory(1);
      expect(history[0].error.message).toBe('Test message');
      expect(history[0].error.code).toBe(ErrorCode.InternalError);
    });

    it('should convert string to ErrorValue', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      errorInterceptor.handleError('String error', context);
      
      const history = errorInterceptor.getHistory(1);
      expect(history[0].error.message).toBe('String error');
    });

    it('should handle object errors', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      errorInterceptor.handleError({ custom: 'error' }, context);
      
      const history = errorInterceptor.getHistory(1);
      expect(history[0].error.code).toBe(ErrorCode.Unknown);
    });

    it('should respect silent option', () => {
      const consoleSpy = mock();
      const originalGroup = console.groupCollapsed;
      console.groupCollapsed = consoleSpy;

      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      errorInterceptor.handleError(new Error('Silent'), context, { silent: true });

      expect(consoleSpy).not.toHaveBeenCalled();
      
      console.groupCollapsed = originalGroup;
    });

    it('should track error codes', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      errorInterceptor.handleError(
        { code: ErrorCode.ValidationFailed, message: 'Invalid' },
        context
      );
      
      const stats = errorInterceptor.getStats();
      expect(stats.byCode.get('VALIDATION_FAILED')).toBe(1);
    });

    it('should track critical errors', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      errorInterceptor.handleError(
        { code: ErrorCode.InternalError, message: 'Critical' },
        context
      );
      
      const stats = errorInterceptor.getStats();
      expect(stats.criticalCount).toBe(1);
    });

    it('should limit history size', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      // Add 60 errors (max is 50)
      for (let i = 0; i < 60; i++) {
        errorInterceptor.handleError(new Error(`Error ${i}`), context);
      }
      
      const history = errorInterceptor.getHistory(100);
      expect(history.length).toBe(50);
      expect(history[0].error.message).toBe('Error 10'); // First 10 should be trimmed
    });
  });

  describe('getStats', () => {
    it('should return copy of stats', () => {
      const stats1 = errorInterceptor.getStats();
      const stats2 = errorInterceptor.getStats();
      
      // Should be different objects
      expect(stats1).not.toBe(stats2);
      
      // But have same values
      expect(stats1.total).toBe(stats2.total);
    });

    it('should track by source', () => {
      const context1 = { source: 'webui' as const, operation: 'op1', timestamp: Date.now() };
      const context2 = { source: 'http' as const, operation: 'op2', timestamp: Date.now() };
      
      errorInterceptor.handleError(new Error('Error 1'), context1);
      errorInterceptor.handleError(new Error('Error 2'), context2);
      
      const stats = errorInterceptor.getStats();
      expect(stats.bySource.get('webui')).toBe(1);
      expect(stats.bySource.get('http')).toBe(1);
    });
  });

  describe('getHistory', () => {
    it('should return limited history', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      for (let i = 0; i < 10; i++) {
        errorInterceptor.handleError(new Error(`Error ${i}`), context);
      }
      
      const history = errorInterceptor.getHistory(5);
      expect(history.length).toBe(5);
      expect(history[0].error.message).toBe('Error 5'); // Last 5
    });

    it('should return all history if limit not specified', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      
      for (let i = 0; i < 5; i++) {
        errorInterceptor.handleError(new Error(`Error ${i}`), context);
      }
      
      const history = errorInterceptor.getHistory();
      expect(history.length).toBe(5);
    });
  });

  describe('clear', () => {
    it('should reset all stats', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      errorInterceptor.handleError(new Error('Error'), context);
      
      errorInterceptor.clear();
      
      const stats = errorInterceptor.getStats();
      expect(stats.total).toBe(0);
      expect(stats.criticalCount).toBe(0);
      expect(stats.bySource.size).toBe(0);
    });

    it('should clear history', () => {
      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      errorInterceptor.handleError(new Error('Error'), context);
      
      errorInterceptor.clear();
      
      const history = errorInterceptor.getHistory();
      expect(history.length).toBe(0);
    });
  });

  describe('printSummary', () => {
    it('should print summary to console', () => {
      const consoleSpy = mock();
      const originalLog = console.log;
      console.log = consoleSpy;

      const context = { source: 'test', operation: 'op', timestamp: Date.now() };
      errorInterceptor.handleError(
        { code: ErrorCode.InternalError, message: 'Critical' },
        context
      );
      
      errorInterceptor.printSummary();
      
      expect(consoleSpy).toHaveBeenCalled();
      
      console.log = originalLog;
    });
  });

  describe('setupGlobalErrorInterception', () => {
    it('should register unhandledrejection handler', () => {
      const addEventListenerSpy = mock();
      const originalAddEventListener = window.addEventListener;
      window.addEventListener = addEventListenerSpy;

      setupGlobalErrorInterception();

      expect(addEventListenerSpy).toHaveBeenCalledWith(
        'unhandledrejection',
        expect.any(Function)
      );

      window.addEventListener = originalAddEventListener;
    });

    it('should register error handler', () => {
      const addEventListenerSpy = mock();
      const originalAddEventListener = window.addEventListener;
      window.addEventListener = addEventListenerSpy;

      setupGlobalErrorInterception();

      expect(addEventListenerSpy).toHaveBeenCalledWith(
        'error',
        expect.any(Function)
      );

      window.addEventListener = originalAddEventListener;
    });
  });
});
