// Notification service for toast notifications
import { Injectable, signal, computed } from '@angular/core';
import { getLogger } from '../viewmodels/logger.viewmodel';

export type NotificationType = 'info' | 'success' | 'warning' | 'error';

export interface Notification {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  duration?: number;
  createdAt: number;
  dismissible: boolean;
}

export interface NotificationOptions {
  type?: NotificationType;
  duration?: number;
  dismissible?: boolean;
  action?: {
    label: string;
    onClick: () => void;
  };
}

const DEFAULT_DURATION = 5000;

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private readonly logger = getLogger('notification.service');

  private readonly notifications = signal<Notification[]>([]);
  private readonly maxNotifications = 5;

  readonly items = computed(() => this.notifications());
  readonly count = computed(() => this.notifications().length);

  /**
   * Show an info notification
   */
  info(title: string, message: string, options?: NotificationOptions): string {
    return this.show(title, message, { ...options, type: 'info' });
  }

  /**
   * Show a success notification
   */
  success(title: string, message: string, options?: NotificationOptions): string {
    return this.show(title, message, { ...options, type: 'success' });
  }

  /**
   * Show a warning notification
   */
  warning(title: string, message: string, options?: NotificationOptions): string {
    return this.show(title, message, { ...options, type: 'warning' });
  }

  /**
   * Show an error notification
   */
  error(title: string, message: string, options?: NotificationOptions): string {
    return this.show(title, message, { ...options, type: 'error' });
  }

  /**
   * Show a notification
   */
  show(title: string, message: string, options: NotificationOptions = {}): string {
    const id = this.generateId();
    const notification: Notification = {
      id,
      type: options.type ?? 'info',
      title,
      message,
      duration: options.duration ?? DEFAULT_DURATION,
      dismissible: options.dismissible ?? true,
      createdAt: Date.now(),
    };

    this.notifications.update(notifications => {
      const updated = [...notifications, notification];
      // Remove oldest if exceeding max
      if (updated.length > this.maxNotifications) {
        updated.shift();
      }
      return updated;
    });

    this.logger.debug('Notification shown', { id, type: notification.type, title });

    // Auto-dismiss after duration
    if (notification.duration && notification.duration > 0) {
      setTimeout(() => this.dismiss(id), notification.duration);
    }

    return id;
  }

  /**
   * Dismiss a notification
   */
  dismiss(id: string): void {
    const notification = this.notifications().find(n => n.id === id);
    if (notification) {
      this.notifications.update(notifications =>
        notifications.filter(n => n.id !== id)
      );
      this.logger.debug('Notification dismissed', { id });
    }
  }

  /**
   * Dismiss all notifications
   */
  dismissAll(): void {
    this.notifications.set([]);
    this.logger.debug('All notifications dismissed');
  }

  /**
   * Update a notification
   */
  update(id: string, updates: Partial<Pick<Notification, 'title' | 'message' | 'duration'>>): void {
    this.notifications.update(notifications =>
      notifications.map(n =>
        n.id === id ? { ...n, ...updates } : n
      )
    );
  }

  /**
   * Get notification by ID
   */
  get(id: string): Notification | undefined {
    return this.notifications().find(n => n.id === id);
  }

  private generateId(): string {
    return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
