// src/views/devtools/devtools.component.ts
// Simplified DevTools panel for debugging

import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { errorInterceptor } from '../../core/error-interceptor';
import { EventBusViewModel } from '../../viewmodels/event-bus.viewmodel';
import { getLogger } from '../../viewmodels/logger.viewmodel';

const logger = getLogger('devtools');

@Component({
  selector: 'app-devtools',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="devtools">
      <div class="devtools__header">
        <h3>DevTools</h3>
        <div class="devtools__actions">
          <button type="button" class="btn btn--icon" (click)="refresh()" title="Refresh">⟳</button>
          <button type="button" class="btn btn--icon" (click)="clearLogs()" title="Clear">🗔</button>
        </div>
      </div>

      <div class="devtools__tabs">
        @for (tab of tabs; track tab.id) {
          <button type="button"
                  class="devtools__tab"
                  [class.active]="activeTab() === tab.id"
                  (click)="activeTab.set(tab.id)">
            {{ tab.icon }} {{ tab.label }}
          </button>
        }
      </div>

      <div class="devtools__content">
        @if (activeTab() === 'frontend') {
          <div class="devtools-panel">
            <div class="panel-section">
              <h4>Frontend Error Stats</h4>
              <div class="stats-grid">
                <div class="stat-card">
                  <div class="stat-card__value">{{ errorStats.total }}</div>
                  <div class="stat-card__label">Total Errors</div>
                </div>
                <div class="stat-card stat-card--critical">
                  <div class="stat-card__value">{{ errorStats.criticalCount }}</div>
                  <div class="stat-card__label">Critical</div>
                </div>
              </div>
            </div>

            <div class="panel-section">
              <h4>Errors by Source</h4>
              <div class="breakdown-list">
                @for (entry of errorStats.bySource | keyvalue; track entry.key) {
                  <div class="breakdown-item">
                    <span class="breakdown-item__label">{{ entry.key }}</span>
                    <span class="breakdown-item__value">{{ entry.value }}</span>
                  </div>
                } @empty {
                  <div class="empty-state">No errors recorded</div>
                }
              </div>
            </div>
          </div>
        }

        @if (activeTab() === 'events') {
          <div class="devtools-panel">
            <div class="panel-section">
              <h4>Event Bus Stats</h4>
              <div class="stats-grid">
                <div class="stat-card">
                  <div class="stat-card__value">{{ eventBusHistory.length }}</div>
                  <div class="stat-card__label">Events in History</div>
                </div>
                <div class="stat-card">
                  <div class="stat-card__value">{{ eventBusEnabled ? '✓' : '✗' }}</div>
                  <div class="stat-card__label">Enabled</div>
                </div>
              </div>
            </div>

            <div class="panel-section">
              <h4>Recent Events</h4>
              <div class="events-list">
                @for (event of eventBusHistory.slice(0, 20); track event.id) {
                  <div class="event-item">
                    <span class="event-item__time">{{ formatTime(event.timestamp) }}</span>
                    <span class="event-item__name">{{ event.name }}</span>
                  </div>
                } @empty {
                  <div class="empty-state">No events recorded</div>
                }
              </div>
            </div>
          </div>
        }

        @if (activeTab() === 'env') {
          <div class="devtools-panel">
            <div class="panel-section">
              <h4>Environment</h4>
              <div class="env-grid">
                <div class="env-item">
                  <span class="env-label">User Agent:</span>
                  <span class="env-value env-value--small">{{ userAgent }}</span>
                </div>
                <div class="env-item">
                  <span class="env-label">Language:</span>
                  <span class="env-value">{{ language }}</span>
                </div>
                <div class="env-item">
                  <span class="env-label">Screen:</span>
                  <span class="env-value">{{ screenResolution }}</span>
                </div>
                <div class="env-item">
                  <span class="env-label">Timezone:</span>
                  <span class="env-value">{{ timezone }}</span>
                </div>
              </div>
            </div>
          </div>
        }

        @if (activeTab() === 'actions') {
          <div class="devtools-panel">
            <div class="panel-section">
              <h4>Quick Actions</h4>
              <div class="actions-grid">
                <button type="button" class="action-btn" (click)="clearLocalStorage()">
                  Clear LocalStorage
                </button>
                <button type="button" class="action-btn" (click)="printErrorSummary()">
                  Print Error Summary
                </button>
                <button type="button" class="action-btn" (click)="triggerTestError()">
                  Trigger Test Error
                </button>
              </div>
            </div>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .devtools {
      display: flex;
      flex-direction: column;
      height: 100%;
      font-family: 'Courier New', monospace;
      font-size: 12px;
      background: #1e1e1e;
      color: #d4d4d4;
    }

    .devtools__header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      background: #252526;
      border-bottom: 1px solid #3c3c3c;
    }

    .devtools__header h3 {
      margin: 0;
      font-size: 14px;
      color: #fff;
    }

    .devtools__actions {
      display: flex;
      gap: 4px;
    }

    .btn--icon {
      background: #3c3c3c;
      border: none;
      color: #d4d4d4;
      padding: 4px 8px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
    }

    .btn--icon:hover {
      background: #4c4c4c;
    }

    .devtools__tabs {
      display: flex;
      gap: 2px;
      padding: 4px 8px;
      background: #252526;
      border-bottom: 1px solid #3c3c3c;
    }

    .devtools__tab {
      background: transparent;
      border: none;
      color: #858585;
      padding: 6px 12px;
      border-radius: 4px 4px 0 0;
      cursor: pointer;
      white-space: nowrap;
      font-size: 11px;
    }

    .devtools__tab:hover {
      background: #2a2a2a;
      color: #d4d4d4;
    }

    .devtools__tab.active {
      background: #1e1e1e;
      color: #fff;
    }

    .devtools__content {
      flex: 1;
      overflow-y: auto;
      padding: 12px;
    }

    .devtools-panel {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .panel-section {
      background: #252526;
      border-radius: 6px;
      padding: 12px;
    }

    .panel-section h4 {
      margin: 0 0 12px 0;
      font-size: 13px;
      color: #fff;
      border-bottom: 1px solid #3c3c3c;
      padding-bottom: 8px;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
      gap: 8px;
    }

    .stat-card {
      background: #1e1e1e;
      padding: 12px;
      border-radius: 4px;
      text-align: center;
      border-left: 3px solid #007acc;
    }

    .stat-card--critical {
      border-left-color: #c7254e;
    }

    .stat-card__value {
      font-size: 20px;
      font-weight: bold;
      color: #fff;
    }

    .stat-card__label {
      font-size: 10px;
      color: #858585;
      margin-top: 4px;
    }

    .breakdown-list {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .breakdown-item {
      display: flex;
      justify-content: space-between;
      padding: 6px 8px;
      background: #1e1e1e;
      border-radius: 4px;
    }

    .breakdown-item__label {
      color: #858585;
    }

    .breakdown-item__value {
      color: #fff;
    }

    .events-list {
      display: flex;
      flex-direction: column;
      gap: 4px;
      max-height: 300px;
      overflow-y: auto;
    }

    .event-item {
      display: grid;
      grid-template-columns: 60px 1fr;
      gap: 8px;
      padding: 6px 8px;
      background: #1e1e1e;
      border-radius: 4px;
      font-size: 11px;
    }

    .event-item__time {
      color: #858585;
    }

    .event-item__name {
      color: #9cdcfe;
    }

    .env-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 8px;
    }

    .env-item {
      display: flex;
      flex-direction: column;
      gap: 4px;
      padding: 8px;
      background: #1e1e1e;
      border-radius: 4px;
    }

    .env-label {
      color: #858585;
      font-size: 10px;
    }

    .env-value {
      color: #d4d4d4;
      font-size: 11px;
    }

    .env-value--small {
      font-size: 10px;
      word-break: break-all;
    }

    .actions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 8px;
    }

    .action-btn {
      background: #0e639c;
      border: none;
      color: #fff;
      padding: 10px 16px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
    }

    .action-btn:hover {
      background: #1177bb;
    }

    .empty-state {
      text-align: center;
      padding: 20px;
      color: #858585;
    }
  `],
})
export class DevtoolsComponent {
  activeTab = signal<'frontend' | 'events' | 'env' | 'actions'>('frontend');
  
  tabs = [
    { id: 'frontend', label: 'Frontend', icon: 'F' },
    { id: 'events', label: 'Events', icon: 'E' },
    { id: 'env', label: 'Environment', icon: '⚙' },
    { id: 'actions', label: 'Actions', icon: '⚡' },
  ];

  errorStats = { total: 0, criticalCount: 0, bySource: new Map<string, number>() };
  eventBusHistory: Array<{ id: number; name: string; timestamp: string }> = [];
  eventBusEnabled = true;
  userAgent = '';
  language = '';
  screenResolution = '';
  timezone = '';

  constructor(
    private readonly eventBus: EventBusViewModel<Record<string, unknown>>
  ) {
    if (typeof window !== 'undefined') {
      this.userAgent = navigator.userAgent;
      this.language = navigator.language;
      this.screenResolution = `${screen.width}x${screen.height}`;
      this.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }
  }

  ngOnInit(): void {
    this.refresh();
  }

  refresh(): void {
    const stats = errorInterceptor.getStats();
    this.errorStats = {
      total: stats.total,
      criticalCount: stats.criticalCount,
      bySource: stats.bySource,
    };

    const history = this.eventBus.getHistory();
    this.eventBusHistory = history.map((h, i) => ({
      id: i,
      name: h.type,
      timestamp: new Date(h.timestamp).toISOString(),
    }));

    this.eventBusEnabled = this.eventBus.isEnabled();
  }

  clearLogs(): void {
    errorInterceptor.clear();
    this.refresh();
  }

  clearLocalStorage(): void {
    localStorage.clear();
    logger.info('LocalStorage cleared');
  }

  printErrorSummary(): void {
    errorInterceptor.printSummary();
  }

  triggerTestError(): void {
    errorInterceptor.capture(
      new Error('Test error from DevTools'),
      { source: 'devtools', title: 'Test Error' }
    );
    this.refresh();
  }

  formatTime(timestamp: string): string {
    try {
      return new Date(timestamp).toLocaleTimeString();
    } catch {
      return timestamp;
    }
  }
}
