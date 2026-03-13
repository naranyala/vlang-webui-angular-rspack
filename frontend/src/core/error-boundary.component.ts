// frontend/src/core/error-boundary.component.ts
// Angular error boundary for isolating component errors

import {
  Component,
  Input,
  Output,
  EventEmitter,
  type OnInit,
  type OnDestroy,
  type OnChanges,
  signal,
  computed,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { GlobalErrorService } from './global-error.service';
import { ErrorCode, type ErrorValue } from '../types';
import { getLogger } from '../viewmodels/logger.viewmodel';

interface ErrorBoundaryState {
  hasError: boolean;
  error: ErrorValue | null;
  errorCount: number;
  lastErrorTime: number | null;
  componentId: string;
}

@Component({
  selector: 'app-error-boundary',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (hasError()) {
      <div class="error-boundary" [class.error-boundary--critical]="isCritical()">
        <div class="error-boundary__content">
          <div class="error-boundary__icon">{{ getErrorIcon() }}</div>
          <h3 class="error-boundary__title">{{ title() || 'Component Error' }}</h3>
          <p class="error-boundary__message">{{ getErrorMessage() }}</p>
          
          @if (showDetails()) {
            <div class="error-boundary__details">
              <code>{{ getErrorDetails() }}</code>
            </div>
          }
          
          <div class="error-boundary__actions">
            <button type="button" class="btn btn--primary" (click)="retry()">
              ↻ Retry
            </button>
            <button type="button" class="btn btn--secondary" (click)="dismiss()">
              Dismiss
            </button>
            @if (fallbackContent) {
              <button type="button" class="btn btn--secondary" (click)="showFallback()">
                Show Alternative
              </button>
            }
          </div>
        </div>
      </div>
    } @else {
      <ng-content></ng-content>
    }
  `,
  styles: [`
    .error-boundary {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 200px;
      padding: 32px;
      background: linear-gradient(135deg, #fef5f5 0%, #fff5f5 100%);
      border: 2px solid #feb2b2;
      border-radius: 12px;
      text-align: center;
      animation: shake 0.5s ease-in-out;
    }

    .error-boundary--critical {
      background: linear-gradient(135deg, #7f1d1d 0%, #991b1b 100%);
      border-color: #dc2626;
      color: white;
    }

    @keyframes shake {
      0%, 100% { transform: translateX(0); }
      10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
      20%, 40%, 60%, 80% { transform: translateX(5px); }
    }

    .error-boundary__content {
      max-width: 400px;
    }

    .error-boundary__icon {
      font-size: 48px;
      margin-bottom: 16px;
    }

    .error-boundary__title {
      margin: 0 0 8px;
      font-size: 20px;
      font-weight: 600;
      color: #1a1a1a;
    }

    .error-boundary--critical .error-boundary__title {
      color: white;
    }

    .error-boundary__message {
      margin: 0 0 24px;
      color: #666;
      line-height: 1.5;
    }

    .error-boundary--critical .error-boundary__message {
      color: #fca5a5;
    }

    .error-boundary__details {
      margin-bottom: 24px;
      padding: 12px;
      background: rgba(0, 0, 0, 0.05);
      border-radius: 6px;
      text-align: left;
      overflow: auto;
      max-height: 200px;
    }

    .error-boundary__details code {
      font-family: 'SF Mono', 'Consolas', monospace;
      font-size: 12px;
      color: #dc2626;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .error-boundary__actions {
      display: flex;
      gap: 12px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .btn {
      padding: 10px 20px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn--primary {
      background: #0f3460;
      color: white;
    }

    .btn--primary:hover {
      background: #1a4a7a;
      transform: translateY(-1px);
    }

    .btn--secondary {
      background: #e5e7eb;
      color: #374151;
    }

    .btn--secondary:hover {
      background: #d1d5db;
    }
  `],
})
export class ErrorBoundaryComponent implements OnInit, OnDestroy, OnChanges {
  @Input() title?: string;
  @Input() componentId?: string;
  @Input() showDetails = false;
  @Input() autoRetry = false;
  @Input() maxRetries = 3;
  @Input() fallbackContent?: unknown;
  
  @Output() errorCaught = new EventEmitter<ErrorValue>();
  @Output() recovered = new EventEmitter<void>();
  @Output() retryAttempt = new EventEmitter<number>();

  private readonly errorService = inject(GlobalErrorService);
  private readonly logger = getLogger('error-boundary');
  
  private retryCount = 0;
  private state: ErrorBoundaryState = {
    hasError: false,
    error: null,
    errorCount: 0,
    lastErrorTime: null,
    componentId: '',
  };

  readonly hasError = signal(false);
  readonly errorCount = signal(0);

  readonly isCritical = computed(() => {
    const err = this.state.error;
    if (!err) return false;
    return [
      ErrorCode.InternalError,
      ErrorCode.DbConnectionFailed,
      ErrorCode.DbQueryFailed,
      ErrorCode.SerializationFailed,
    ].includes(err.code);
  });

  ngOnInit(): void {
    this.state.componentId = this.componentId || `boundary-${Date.now()}`;
    this.logger.debug('Error boundary initialized', { componentId: this.state.componentId });
  }

  ngOnChanges(): void {
    if (this.componentId) {
      this.state.componentId = this.componentId;
    }
  }

  ngOnDestroy(): void {
    this.logger.debug('Error boundary destroyed', { componentId: this.state.componentId });
  }

  /**
   * Catch an error and display the error boundary
   */
  catchError(error: ErrorValue | unknown): void {
    const errorValue = this.normalizeError(error);
    
    this.state = {
      hasError: true,
      error: errorValue,
      errorCount: this.state.errorCount + 1,
      lastErrorTime: Date.now(),
      componentId: this.state.componentId,
    };

    this.hasError.set(true);
    this.errorCount.set(this.state.errorCount);
    this.errorCaught.emit(errorValue);

    this.logger.error('Error caught by boundary', {
      componentId: this.state.componentId,
      error: errorValue,
    });

    // Auto-retry if configured and not exceeded max retries
    if (this.autoRetry && this.retryCount < this.maxRetries) {
      setTimeout(() => this.retry(), 1000 * (this.retryCount + 1));
    }
  }

  /**
   * Retry the failed operation
   */
  retry(): void {
    this.retryCount++;
    this.retryAttempt.emit(this.retryCount);
    
    this.logger.info('Retry attempt', {
      componentId: this.state.componentId,
      attempt: this.retryCount,
    });

    // Reset error state but keep count
    this.state.hasError = false;
    this.state.error = null;
    this.hasError.set(false);
  }

  /**
   * Dismiss the error and show fallback content
   */
  dismiss(): void {
    this.state.hasError = false;
    this.state.error = null;
    this.hasError.set(false);
    this.retryCount = 0;
    
    this.recovered.emit();
    this.logger.info('Error dismissed', { componentId: this.state.componentId });
  }

  /**
   * Show fallback content if available
   */
  showFallback(): void {
    this.dismiss();
    this.logger.info('Showing fallback content', { componentId: this.state.componentId });
  }

  /**
   * Get error icon based on error type
   */
  getErrorIcon(): string {
    const err = this.state.error;
    if (!err) return '⚠';

    switch (err.code) {
      case ErrorCode.ValidationFailed:
        return '✏';
      case ErrorCode.ResourceNotFound:
      case ErrorCode.EntityNotFound:
        return '🔍';
      case ErrorCode.DbConnectionFailed:
      case ErrorCode.DbQueryFailed:
        return '🗄';
      case ErrorCode.InternalError:
        return '💥';
      case ErrorCode.TimeoutError:
        return '⏱';
      default:
        return '⚠';
    }
  }

  /**
   * Get user-friendly error message
   */
  getErrorMessage(): string {
    const err = this.state.error;
    if (!err) return 'An error occurred';

    if (err.field) {
      return `Invalid value for "${err.field}". ${err.message}`;
    }

    return err.message || 'An unexpected error occurred';
  }

  /**
   * Get technical error details
   */
  getErrorDetails(): string {
    const err = this.state.error;
    if (!err) return '';

    const details: string[] = [];
    if (err.code) details.push(`Code: ${err.code}`);
    if (err.details) details.push(`Details: ${err.details}`);
    if (err.cause) details.push(`Cause: ${err.cause}`);
    if (err.context) {
      details.push(`Context: ${JSON.stringify(err.context, null, 2)}`);
    }

    return details.join('\n');
  }

  /**
   * Normalize unknown error to ErrorValue
   */
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

    if (typeof error === 'string') {
      return {
        code: ErrorCode.InternalError,
        message: error,
      };
    }

    return {
      code: ErrorCode.Unknown,
      message: 'An unknown error occurred',
      details: typeof error === 'object' ? JSON.stringify(error) : String(error),
    };
  }
}
