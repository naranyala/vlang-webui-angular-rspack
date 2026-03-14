// Service facade providing unified access to all core services
import { Injectable } from '@angular/core';
import { Logger, getLogger } from '../viewmodels/logger.viewmodel';
import { EventBusViewModel } from './event-bus.viewmodel';
import { HttpService } from '../core/http.service';
import { StorageService } from '../core/storage.service';
import { NotificationService } from '../core/notification.service';
import { LoadingService } from '../core/loading.service';
import { ThemeService } from '../core/theme.service';
import { ClipboardService } from '../core/clipboard.service';
import { RetryService } from '../core/retry.service';
import { NetworkMonitorService } from '../core/network-monitor.service';

/**
 * Application Services Facade
 * 
 * Provides unified access to all commonly used services.
 * Inject this single service instead of multiple individual services.
 * 
 * @example
 * constructor(private services: AppServices) {}
 * 
 * ngOnInit() {
 *   this.services.logger.info('Hello');
 *   this.services.storage.set('key', 'value');
 *   this.services.notifications.success('Done!');
 * }
 */
@Injectable({ providedIn: 'root' })
export class AppServices {
  public readonly logger: Logger;
  public readonly eventBus: EventBusViewModel<Record<string, unknown>>;

  constructor(
    public readonly http: HttpService,
    public readonly storage: StorageService,
    public readonly notifications: NotificationService,
    public readonly loading: LoadingService,
    public readonly theme: ThemeService,
    public readonly clipboard: ClipboardService,
    public readonly retry: RetryService,
    public readonly network: NetworkMonitorService,
  ) {
    this.logger = getLogger('app.services');
    this.eventBus = this.getEventBus();
    
    this.logger.debug('AppServices facade initialized');
  }

  /**
   * Get the event bus instance
   */
  private getEventBus(): EventBusViewModel<Record<string, unknown>> {
    const debugWindow = window as unknown as {
      __FRONTEND_EVENT_BUS__?: EventBusViewModel<Record<string, unknown>>;
    };
    return debugWindow.__FRONTEND_EVENT_BUS__ ?? new EventBusViewModel();
  }

  /**
   * Quick info notification
   */
  notify(message: string, title = 'Info'): void {
    this.notifications.info(title, message);
  }

  /**
   * Quick success notification
   */
  success(message: string, title = 'Success'): void {
    this.notifications.success(title, message);
  }

  /**
   * Quick error notification
   */
  error(message: string, title = 'Error'): void {
    this.notifications.error(title, message);
  }

  /**
   * Wrap an async operation with loading and error handling
   */
  async withLoading<T>(
    operation: () => Promise<T>,
    message = 'Loading...',
    errorMessage = 'Operation failed'
  ): Promise<T | null> {
    const id = this.loading.show(message);
    try {
      const result = await operation();
      this.loading.hide(id);
      return result;
    } catch (error) {
      this.loading.hide(id);
      this.error(errorMessage, error instanceof Error ? error.message : 'Error');
      return null;
    }
  }

  /**
   * Copy text to clipboard with notification
   */
  async copyWithNotify(text: string, successMessage = 'Copied!'): Promise<boolean> {
    const result = await this.clipboard.copy(text);
    if (result.success) {
      this.success(successMessage);
      return true;
    } else {
      this.error(result.error ?? 'Failed to copy');
      return false;
    }
  }

  /**
   * Get storage statistics
   */
  getStorageStats(): { count: number; estimatedSize: number } {
    const stats = this.storage.getStats();
    return {
      count: stats.count,
      estimatedSize: stats.estimatedSize,
    };
  }

  /**
   * Get HTTP statistics
   */
  getHttpStats(): { total: number; success: number; failed: number; avgLatency: number } {
    const stats = this.http.getStats();
    return {
      total: stats.totalRequests,
      success: stats.successfulRequests,
      failed: stats.failedRequests,
      avgLatency: stats.avgLatency,
    };
  }

  /**
   * Get network statistics
   */
  getNetworkStats(): { online: boolean; quality: string; latency: number } {
    return {
      online: this.network.isOnline(),
      quality: this.network.connectionQuality(),
      latency: this.network.currentLatency(),
    };
  }
}
