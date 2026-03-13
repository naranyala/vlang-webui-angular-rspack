// frontend/src/core/network-monitor.service.ts
// Network connectivity monitoring with automatic status updates

import { Injectable, signal, computed } from '@angular/core';
import { EventBusViewModel } from '../viewmodels/event-bus.viewmodel';
import { getLogger } from '../viewmodels/logger.viewmodel';

export interface NetworkStatus {
  online: boolean;
  connectionType: 'wifi' | 'cellular' | 'ethernet' | 'unknown';
  downlink?: number;
  rtt?: number;
  effectiveType?: '2g' | '3g' | '4g' | '5g';
  saveData?: boolean;
}

export interface ConnectionQuality {
  status: 'excellent' | 'good' | 'fair' | 'poor' | 'offline';
  latency: number;
  jitter: number;
  packetLoss: number;
  lastCheck: number;
}

export interface NetworkStats {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  avgLatency: number;
  lastLatency: number;
  connectionDrops: number;
  reconnects: number;
}

@Injectable({ providedIn: 'root' })
export class NetworkMonitorService {
  private readonly logger = getLogger('network-monitor');
  private readonly eventBus: EventBusViewModel<Record<string, unknown>>;
  
  private readonly status = signal<NetworkStatus>({
    online: typeof navigator !== 'undefined' ? navigator.onLine : false,
    connectionType: 'unknown',
  });

  private readonly quality = signal<ConnectionQuality>({
    status: 'offline',
    latency: 0,
    jitter: 0,
    packetLoss: 0,
    lastCheck: 0,
  });

  private readonly stats = signal<NetworkStats>({
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    avgLatency: 0,
    lastLatency: 0,
    connectionDrops: 0,
    reconnects: 0,
  });

  private latencyHistory: number[] = [];
  private checkInterval?: number;
  private lastOnlineState = true;

  readonly isOnline = computed(() => this.status().online);
  readonly isOffline = computed(() => !this.status().online);
  readonly connectionQuality = computed(() => this.quality().status);
  readonly currentLatency = computed(() => this.stats().lastLatency);
  readonly successRate = computed(() => {
    const s = this.stats();
    if (s.totalRequests === 0) return 100;
    return Math.round((s.successfulRequests / s.totalRequests) * 100);
  });

  constructor() {
    const debugWindow = window as unknown as {
      __FRONTEND_EVENT_BUS__?: EventBusViewModel<Record<string, unknown>>;
    };
    this.eventBus =
      debugWindow.__FRONTEND_EVENT_BUS__ ?? new EventBusViewModel<Record<string, unknown>>();

    if (typeof window !== 'undefined') {
      this.setupEventListeners();
      this.detectConnectionType();
      this.startMonitoring();
      this.logger.info('Network monitor initialized', { online: this.status().online });
    }
  }

  /**
   * Record a network request for statistics
   */
  recordRequest(latency: number, success: boolean): void {
    this.stats.update(s => {
      const totalRequests = s.totalRequests + 1;
      const successfulRequests = s.successfulRequests + (success ? 1 : 0);
      const failedRequests = s.failedRequests + (success ? 0 : 1);
      
      // Update average latency
      const avgLatency = ((s.avgLatency * s.totalRequests) + latency) / totalRequests;

      return {
        ...s,
        totalRequests,
        successfulRequests,
        failedRequests,
        avgLatency: Math.round(avgLatency),
        lastLatency: Math.round(latency),
      };
    });

    // Update latency history for jitter calculation
    this.latencyHistory.push(latency);
    if (this.latencyHistory.length > 20) {
      this.latencyHistory.shift();
    }

    this.updateConnectionQuality();
  }

  /**
   * Record a connection drop
   */
  recordConnectionDrop(): void {
    this.stats.update(s => ({
      ...s,
      connectionDrops: s.connectionDrops + 1,
    }));
  }

  /**
   * Record a reconnection
   */
  recordReconnect(): void {
    this.stats.update(s => ({
      ...s,
      reconnects: s.reconnects + 1,
    }));
  }

  /**
   * Get current network status
   */
  getStatus(): NetworkStatus {
    return { ...this.status() };
  }

  /**
   * Get connection quality metrics
   */
  getQuality(): ConnectionQuality {
    return { ...this.quality() };
  }

  /**
   * Get network statistics
   */
  getStats(): NetworkStats {
    return { ...this.stats() };
  }

  /**
   * Force a connectivity check
   */
  async checkConnectivity(): Promise<boolean> {
    const startTime = Date.now();
    
    try {
      // Try to fetch a small resource
      const response = await fetch('/favicon.ico', {
        method: 'HEAD',
        cache: 'no-cache',
      });
      
      const latency = Date.now() - startTime;
      this.recordRequest(latency, response.ok);
      
      const wasOffline = !this.status().online;
      this.status.update(s => ({ ...s, online: response.ok }));
      
      if (wasOffline && response.ok) {
        this.recordReconnect();
        this.publishStatusChange('reconnected');
      }
      
      return response.ok;
    } catch {
      const latency = Date.now() - startTime;
      this.recordRequest(latency, false);
      this.status.update(s => ({ ...s, online: false }));
      
      if (this.lastOnlineState) {
        this.recordConnectionDrop();
        this.publishStatusChange('disconnected');
      }
      
      return false;
    }
  }

  /**
   * Wait for network to be online
   */
  async waitForOnline(timeoutMs = 30000): Promise<boolean> {
    if (this.status().online) return true;

    return new Promise(resolve => {
      const startTime = Date.now();
      
      const checkOnline = () => {
        if (this.status().online) {
          resolve(true);
          return;
        }
        
        if (Date.now() - startTime > timeoutMs) {
          resolve(false);
          return;
        }
        
        setTimeout(checkOnline, 500);
      };
      
      checkOnline();
    });
  }

  private setupEventListeners(): void {
    // Online/Offline events
    window.addEventListener('online', () => {
      this.logger.info('Network connection restored');
      this.status.update(s => ({ ...s, online: true }));
      this.recordReconnect();
      this.publishStatusChange('reconnected');
      this.checkConnectivity();
    });

    window.addEventListener('offline', () => {
      this.logger.warn('Network connection lost');
      this.status.update(s => ({ ...s, online: false }));
      this.recordConnectionDrop();
      this.publishStatusChange('disconnected');
    });

    // Connection change events (Chrome/Edge)
    if (typeof navigator !== 'undefined' && 'connection' in navigator) {
      const conn = (navigator as any).connection;
      if (conn) {
        conn.addEventListener('change', () => {
          this.detectConnectionType();
          this.publishStatusChange('connection_changed');
        });
      }
    }
  }

  private startMonitoring(): void {
    // Check connectivity every 30 seconds
    this.checkInterval = window.setInterval(() => {
      this.checkConnectivity();
    }, 30000);
  }

  private detectConnectionType(): void {
    if (typeof navigator === 'undefined') return;

    const nav = navigator as any;
    const conn = nav.connection || nav.mozConnection || nav.webkitConnection;

    if (conn) {
      const type = conn.effectiveType || conn.type;
      const downlink = conn.downlink;
      const rtt = conn.rtt;
      const saveData = conn.saveData;

      this.status.update(s => ({
        ...s,
        connectionType: this.mapConnectionType(type),
        downlink,
        rtt,
        effectiveType: this.mapEffectiveType(type),
        saveData,
      }));

      // Update quality based on connection info
      this.updateConnectionQuality();
    }
  }

  private updateConnectionQuality(): void {
    const s = this.status();
    const stats = this.stats();

    if (!s.online) {
      this.quality.set({
        status: 'offline',
        latency: 0,
        jitter: 0,
        packetLoss: 0,
        lastCheck: Date.now(),
      });
      return;
    }

    const latency = stats.lastLatency || s.rtt || 0;
    
    // Calculate jitter from latency history
    const jitter = this.calculateJitter();
    
    // Estimate packet loss from failed requests
    const packetLoss = stats.totalRequests > 0
      ? (stats.failedRequests / stats.totalRequests) * 100
      : 0;

    // Determine quality status
    let status: ConnectionQuality['status'] = 'excellent';
    
    if (latency > 500 || packetLoss > 20 || jitter > 100) {
      status = 'poor';
    } else if (latency > 200 || packetLoss > 10 || jitter > 50) {
      status = 'fair';
    } else if (latency > 100 || packetLoss > 5 || jitter > 20) {
      status = 'good';
    }

    this.quality.set({
      status,
      latency: Math.round(latency),
      jitter: Math.round(jitter),
      packetLoss: Math.round(packetLoss * 10) / 10,
      lastCheck: Date.now(),
    });
  }

  private calculateJitter(): number {
    if (this.latencyHistory.length < 2) return 0;

    const diffs: number[] = [];
    for (let i = 1; i < this.latencyHistory.length; i++) {
      diffs.push(Math.abs(this.latencyHistory[i] - this.latencyHistory[i - 1]));
    }

    const sum = diffs.reduce((a, b) => a + b, 0);
    return sum / diffs.length;
  }

  private mapConnectionType(type: string): NetworkStatus['connectionType'] {
    const typeMap: Record<string, NetworkStatus['connectionType']> = {
      'wifi': 'wifi',
      'bluetooth': 'unknown',
      'cellular': 'cellular',
      'ethernet': 'ethernet',
      'mixed': 'unknown',
      'none': 'unknown',
      'unknown': 'unknown',
    };
    return typeMap[type] || 'unknown';
  }

  private mapEffectiveType(type: string): NetworkStatus['effectiveType'] {
    if (type === '2g') return '2g';
    if (type === '3g') return '3g';
    if (type === '4g') return '4g';
    if (type === '5g') return '5g';
    return undefined;
  }

  private publishStatusChange(changeType: string): void {
    this.eventBus.publish('network:status_changed', {
      type: changeType,
      online: this.status().online,
      quality: this.quality().status,
      timestamp: Date.now(),
    });

    this.lastOnlineState = this.status().online;
  }

  ngOnDestroy(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }
  }
}
