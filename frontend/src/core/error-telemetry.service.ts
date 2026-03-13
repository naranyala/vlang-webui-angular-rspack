// frontend/src/core/error-telemetry.service.ts
// Error telemetry and reporting service for production monitoring

import { Injectable, signal, computed } from '@angular/core';
import { ErrorCode, type ErrorValue } from '../types';
import { getLogger } from '../viewmodels/logger.viewmodel';
import type { ErrorContext } from './error-interceptor';

export interface TelemetryEvent {
  id: string;
  type: 'error' | 'warning' | 'info' | 'performance' | 'user_action';
  timestamp: number;
  source: string;
  operation?: string;
  error?: ErrorValue;
  context?: Record<string, unknown>;
  metrics?: {
    duration?: number;
    memoryUsage?: number;
    networkLatency?: number;
  };
  userSession?: {
    id: string;
    duration: number;
    actionsCount: number;
  };
}

export interface TelemetryReport {
  sessionId: string;
  startTime: number;
  endTime: number;
  events: TelemetryEvent[];
  summary: {
    totalEvents: number;
    errorCount: number;
    warningCount: number;
    criticalErrors: number;
    avgResponseTime?: number;
  };
  environment: {
    userAgent: string;
    language: string;
    screenResolution: string;
    timezone: string;
    online: boolean;
  };
}

export interface TelemetryConfig {
  /** Enable/disable telemetry */
  enabled: boolean;
  /** Maximum events to buffer */
  maxBufferedEvents: number;
  /** Auto-report interval in seconds */
  autoReportIntervalSec: number;
  /** Include error details in reports */
  includeErrorDetails: boolean;
  /** Include performance metrics */
  includePerformance: boolean;
  /** Report endpoint (for future backend integration) */
  reportEndpoint?: string;
}

const DEFAULT_CONFIG: TelemetryConfig = {
  enabled: true,
  maxBufferedEvents: 500,
  autoReportIntervalSec: 60,
  includeErrorDetails: true,
  includePerformance: true,
};

@Injectable({ providedIn: 'root' })
export class ErrorTelemetryService {
  private readonly logger = getLogger('error.telemetry');
  private readonly config: TelemetryConfig;
  private readonly events = signal<TelemetryEvent[]>([]);
  private readonly sessionId: string;
  private readonly sessionStart: number;
  private userActionsCount = 0;
  private autoReportTimer?: number;

  readonly eventCount = computed(() => this.events().length);
  readonly errorCount = computed(() => 
    this.events().filter(e => e.type === 'error').length
  );
  readonly criticalCount = computed(() =>
    this.events().filter(e => {
      if (!e.error) return false;
      return [
        ErrorCode.InternalError,
        ErrorCode.DbConnectionFailed,
        ErrorCode.DbQueryFailed,
      ].includes(e.error.code);
    }).length
  );

  constructor(config?: Partial<TelemetryConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.sessionId = this.generateSessionId();
    this.sessionStart = Date.now();

    if (this.config.enabled) {
      this.startAutoReport();
      this.captureEnvironmentMetrics();
      this.logger.info('Telemetry service initialized', { sessionId: this.sessionId });
    }
  }

  /**
   * Record an error event
   */
  recordError(
    error: ErrorValue,
    context: ErrorContext & Record<string, unknown> = {}
  ): void {
    if (!this.config.enabled) return;

    const event: TelemetryEvent = {
      id: this.generateEventId(),
      type: this.isCriticalError(error.code) ? 'error' : 'warning',
      timestamp: Date.now(),
      source: context.source || 'unknown',
      operation: context.operation,
      error: this.config.includeErrorDetails ? error : { code: error.code, message: error.message },
      context: this.sanitizeContext(context),
      userSession: this.getUserSessionInfo(),
    };

    this.addEvent(event);
    this.logger.debug('Error recorded', { eventId: event.id, code: error.code });
  }

  /**
   * Record a performance metric
   */
  recordPerformance(
    operation: string,
    duration: number,
    metrics?: Record<string, number>
  ): void {
    if (!this.config.enabled || !this.config.includePerformance) return;

    const event: TelemetryEvent = {
      id: this.generateEventId(),
      type: 'performance',
      timestamp: Date.now(),
      source: 'performance',
      operation,
      metrics: {
        duration,
        ...metrics,
      },
      userSession: this.getUserSessionInfo(),
    };

    this.addEvent(event);
  }

  /**
   * Record a user action
   */
  recordUserAction(
    action: string,
    context?: Record<string, unknown>
  ): void {
    if (!this.config.enabled) return;

    this.userActionsCount++;

    const event: TelemetryEvent = {
      id: this.generateEventId(),
      type: 'user_action',
      timestamp: Date.now(),
      source: 'user',
      operation: action,
      context,
      userSession: this.getUserSessionInfo(),
    };

    this.addEvent(event);
  }

  /**
   * Record an info event
   */
  recordInfo(
    message: string,
    context?: Record<string, unknown>
  ): void {
    if (!this.config.enabled) return;

    const event: TelemetryEvent = {
      id: this.generateEventId(),
      type: 'info',
      timestamp: Date.now(),
      source: 'info',
      operation: message,
      context,
      userSession: this.getUserSessionInfo(),
    };

    this.addEvent(event);
  }

  /**
   * Generate a telemetry report
   */
  generateReport(): TelemetryReport {
    const events = this.events();
    const now = Date.now();

    // Calculate summary
    const errorEvents = events.filter(e => e.type === 'error');
    const warningEvents = events.filter(e => e.type === 'warning');
    const performanceEvents = events.filter(e => e.type === 'performance');

    const avgResponseTime = performanceEvents.length > 0
      ? performanceEvents.reduce((sum, e) => sum + (e.metrics?.duration || 0), 0) / performanceEvents.length
      : undefined;

    return {
      sessionId: this.sessionId,
      startTime: this.sessionStart,
      endTime: now,
      events: [...events],
      summary: {
        totalEvents: events.length,
        errorCount: errorEvents.length,
        warningCount: warningEvents.length,
        criticalErrors: errorEvents.filter(e => 
          e.error && [ErrorCode.InternalError, ErrorCode.DbConnectionFailed].includes(e.error.code)
        ).length,
        avgResponseTime,
      },
      environment: this.getEnvironmentInfo(),
    };
  }

  /**
   * Clear all buffered events
   */
  clear(): void {
    this.events.set([]);
    this.logger.info('Telemetry buffer cleared');
  }

  /**
   * Export report to console or send to backend
   */
  async exportReport(): Promise<void> {
    const report = this.generateReport();
    
    this.logger.info('Telemetry Report', {
      sessionId: report.sessionId,
      duration: report.endTime - report.startTime,
      totalEvents: report.summary.totalEvents,
      errors: report.summary.errorCount,
      critical: report.summary.criticalErrors,
    });

    // Log full report to console for debugging
    console.group('📊 Telemetry Report');
    console.log('Session:', report.sessionId);
    console.log('Duration:', this.formatDuration(report.endTime - report.startTime));
    console.log('Environment:', report.environment);
    console.log('Summary:', report.summary);
    console.log('Events:', report.events);
    console.groupEnd();

    // TODO: Send to backend endpoint if configured
    if (this.config.reportEndpoint) {
      try {
        await fetch(this.config.reportEndpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(report),
        });
        this.logger.info('Report sent to backend');
      } catch (error) {
        this.logger.error('Failed to send telemetry report', { error });
      }
    }
  }

  /**
   * Get recent events
   */
  getRecentEvents(limit = 50): TelemetryEvent[] {
    return this.events().slice(-limit);
  }

  /**
   * Get events by type
   */
  getEventsByType(type: TelemetryEvent['type']): TelemetryEvent[] {
    return this.events().filter(e => e.type === type);
  }

  private addEvent(event: TelemetryEvent): void {
    this.events.update(events => {
      const updated = [...events, event];
      // Trim if exceeding max buffer
      if (updated.length > this.config.maxBufferedEvents) {
        return updated.slice(updated.length - this.config.maxBufferedEvents);
      }
      return updated;
    });
  }

  private startAutoReport(): void {
    if (this.config.autoReportIntervalSec > 0) {
      this.autoReportTimer = window.setInterval(
        () => this.exportReport(),
        this.config.autoReportIntervalSec * 1000
      );
    }
  }

  private captureEnvironmentMetrics(): void {
    // Capture initial memory metrics if available
    if (typeof performance !== 'undefined' && (performance as any).memory) {
      const memory = (performance as any).memory;
      this.recordPerformance('memory_snapshot', 0, {
        jsHeapSize: memory.jsHeapSizeLimit,
        usedJSHeapSize: memory.usedJSHeapSize,
        totalJSHeapSize: memory.totalJSHeapSize,
      });
    }
  }

  private getUserSessionInfo(): TelemetryEvent['userSession'] {
    return {
      id: this.sessionId,
      duration: Date.now() - this.sessionStart,
      actionsCount: this.userActionsCount,
    };
  }

  private getEnvironmentInfo(): TelemetryReport['environment'] {
    return {
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : 'unknown',
      language: typeof navigator !== 'undefined' ? navigator.language : 'unknown',
      screenResolution: typeof screen !== 'undefined' ? `${screen.width}x${screen.height}` : 'unknown',
      timezone: typeof Intl !== 'undefined' ? Intl.DateTimeFormat().resolvedOptions().timeZone : 'unknown',
      online: typeof navigator !== 'undefined' ? navigator.onLine : false,
    };
  }

  private sanitizeContext(context: Record<string, unknown>): Record<string, unknown> {
    const sanitized: Record<string, unknown> = {};
    const redactKeys = ['password', 'token', 'secret', 'authorization', 'cookie', 'key'];

    for (const [key, value] of Object.entries(context)) {
      const lowerKey = key.toLowerCase();
      if (redactKeys.some(k => lowerKey.includes(k))) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  private isCriticalError(code: ErrorCode): boolean {
    return [
      ErrorCode.InternalError,
      ErrorCode.DbConnectionFailed,
      ErrorCode.DbQueryFailed,
      ErrorCode.SerializationFailed,
    ].includes(code);
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
  }

  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
  }
}
