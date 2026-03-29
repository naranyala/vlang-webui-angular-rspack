# DevTools Backend Services Guide

**Purpose:** Provide comprehensive debugging and monitoring capabilities for the Desktop Dashboard application.

---

## Overview

The DevTools backend services provide real-time access to application statistics, logs, errors, and performance metrics. These services are designed to be consumed by the frontend DevTools panel for debugging and monitoring purposes.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend DevTools Panel                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Statistics │  │    Logs     │  │      Errors         │  │
│  │   Panel     │  │    Panel    │  │      Panel          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│         │                │                    │              │
│         └────────────────┼────────────────────┘              │
│                          │                                   │
│              DevToolsService (Angular)                       │
│                          │                                   │
│                    WebUI Bridge                              │
└──────────────────────────┼───────────────────────────────────┘
                           │
                           │ API Calls
                           │
┌──────────────────────────┼───────────────────────────────────┐
│                    Backend (V Language)                       │
│                          │                                    │
│              DevToolsService (V)                              │
│                          │                                    │
│  ┌─────────────┐  ┌──────┴───────┐  ┌─────────────────────┐  │
│  │   Logs      │  │   Errors     │  │    Metrics          │  │
│  │  Collector  │  │  Collector   │  │    Collector        │  │
│  └─────────────┘  └──────────────┘  └─────────────────────┘  │
│                          │                                    │
│              Application Services                             │
└───────────────────────────────────────────────────────────────┘
```

---

## Backend API Reference

### Data Structures

#### DevToolsStats

Comprehensive application statistics.

```v
pub struct DevToolsStats {
pub mut:
    uptime_seconds      u64          // Application uptime in seconds
    memory_usage        MemoryStats  // Memory usage statistics
    system_info         SystemSummary // System information
    active_connections  int          // Number of active connections
    request_count       int          // Total requests processed
    error_count         int          // Total errors encountered
    cache_stats         CacheSummary // Cache statistics
    database_stats      DatabaseSummary // Database statistics
    last_updated        u64          // Last update timestamp
}
```

#### MemoryStats

Memory usage information.

```v
pub struct MemoryStats {
pub mut:
    used_mb      f64   // Memory used in MB
    total_mb     f64   // Total memory in MB
    percent      f64   // Memory usage percentage
    available_mb f64   // Available memory in MB
}
```

#### LogEntry

Represents a single log entry.

```v
pub struct LogEntry {
pub mut:
    timestamp  u64                // Unix timestamp
    level      string             // Log level (debug, info, warn, error)
    message    string             // Log message
    source     string             // Log source
    context    map[string]string  // Additional context
}
```

#### ErrorReport

Represents an error report.

```v
pub struct ErrorReport {
pub mut:
    timestamp    u64                // Unix timestamp
    error_code   string             // Error code
    message      string             // Error message
    source       string             // Error source
    stack_trace  string             // Stack trace
    context      map[string]string  // Additional context
    resolved     bool               // Whether error is resolved
}
```

#### PerformanceMetric

Represents a performance metric.

```v
pub struct PerformanceMetric {
pub mut:
    name      string               // Metric name
    value     f64                  // Metric value
    unit      string               // Metric unit (ms, bytes, etc.)
    timestamp u64                  // Unix timestamp
    tags      map[string]string    // Metric tags
}
```

---

## API Endpoints

### Statistics Endpoints

#### `devtools.getStats`

Get comprehensive application statistics.

**Request:**
```json
{
    "fn": "devtools.getStats",
    "data": {}
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "uptime_seconds": 3600,
        "memory_usage": {
            "used_mb": 256.5,
            "total_mb": 1024.0,
            "percent": 25.0,
            "available_mb": 768.5
        },
        "system_info": {
            "hostname": "localhost",
            "os": "linux",
            "arch": "x64",
            "cpu_cores": 4,
            "load_avg": [0.5, 0.3, 0.2]
        },
        "request_count": 150,
        "error_count": 3
    }
}
```

#### `devtools.getUptime`

Get application uptime.

**Request:**
```json
{
    "fn": "devtools.getUptime"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "uptime": 3600
    }
}
```

---

### Logs Endpoints

#### `devtools.getLogs`

Get recent log entries.

**Request:**
```json
{
    "fn": "devtools.getLogs"
}
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "timestamp": 1234567890,
            "level": "info",
            "message": "Application started",
            "source": "main",
            "context": {}
        }
    ]
}
```

#### `devtools.log`

Add a log entry from frontend.

**Request:**
```json
{
    "fn": "devtools.log",
    "data": {
        "level": "info",
        "message": "User action performed",
        "source": "frontend"
    }
}
```

**Response:**
```json
{
    "success": true
}
```

#### `devtools.clearLogs`

Clear all log entries.

**Request:**
```json
{
    "fn": "devtools.clearLogs"
}
```

**Response:**
```json
{
    "success": true
}
```

---

### Errors Endpoints

#### `devtools.getErrors`

Get error reports.

**Request:**
```json
{
    "fn": "devtools.getErrors"
}
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "timestamp": 1234567890,
            "error_code": "VALIDATION_ERROR",
            "message": "Invalid input",
            "source": "api",
            "stack_trace": "",
            "resolved": false
        }
    ]
}
```

#### `devtools.reportError`

Report an error from frontend.

**Request:**
```json
{
    "fn": "devtools.reportError",
    "data": {
        "code": "FRONTEND_ERROR",
        "message": "Component failed to render",
        "source": "ui"
    }
}
```

**Response:**
```json
{
    "success": true
}
```

#### `devtools.clearErrors`

Clear all error reports.

**Request:**
```json
{
    "fn": "devtools.clearErrors"
}
```

**Response:**
```json
{
    "success": true
}
```

---

### Metrics Endpoints

#### `devtools.getMetrics`

Get performance metrics.

**Request:**
```json
{
    "fn": "devtools.getMetrics"
}
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "name": "api_response_time",
            "value": 45.2,
            "unit": "ms",
            "timestamp": 1234567890,
            "tags": {}
        }
    ]
}
```

#### `devtools.recordMetric`

Record a performance metric from frontend.

**Request:**
```json
{
    "fn": "devtools.recordMetric",
    "data": {
        "name": "component_render_time",
        "value": 12.5,
        "unit": "ms"
    }
}
```

**Response:**
```json
{
    "success": true
}
```

---

## Frontend Service Usage

### DevToolsService

The Angular service for interacting with backend DevTools APIs.

```typescript
import { inject } from '@angular/core';
import { DevToolsService } from './core/devtools.service';

class MyComponent {
  private readonly devTools = inject(DevToolsService);

  // Get statistics
  async getStats() {
    const stats = await this.devTools.getStats();
    console.log('Uptime:', stats.uptime_seconds);
    console.log('Memory:', stats.memory_usage);
  }

  // Get logs
  async getLogs() {
    const logs = await this.devTools.getLogs();
    logs.forEach(log => {
      console.log(`[${log.level}] ${log.message}`);
    });
  }

  // Get errors
  async getErrors() {
    const errors = await this.devTools.getErrors();
    const critical = errors.filter(e => e.error_code.includes('CRITICAL'));
    console.log('Critical errors:', critical.length);
  }

  // Record metric
  async recordRenderTime(time: number) {
    await this.devTools.recordMetric('component_render', time, 'ms');
  }

  // Report error
  async reportError(error: Error) {
    await this.devTools.reportError(
      'COMPONENT_ERROR',
      error.message,
      'my-component'
    );
  }

  // Refresh all data
  async refresh() {
    await this.devTools.refresh();
  }
}
```

### Using Signals

The service provides reactive signals for real-time updates.

```typescript
class DevToolsComponent {
  private readonly devTools = inject(DevToolsService);

  // Subscribe to signals
  readonly stats = this.devTools.devToolsStats;
  readonly logs = this.devTools.recentLogs;
  readonly errors = this.devTools.recentErrors;
  readonly metrics = this.devTools.recentMetrics;

  // Computed values
  readonly errorCount = computed(() => this.errors().length);
  readonly hasErrors = computed(() => this.errorCount() > 0);
  readonly criticalErrors = computed(() => 
    this.errors().filter(e => e.error_code.includes('CRITICAL'))
  );
}
```

---

## Best Practices

### 1. Log Appropriately

```typescript
// Good: Specific log levels
this.devTools.log('debug', 'Component initialized', 'my-component');
this.devTools.log('info', 'User logged in', 'auth');
this.devTools.log('warn', 'Cache miss rate high', 'cache');
this.devTools.log('error', 'Failed to load data', 'api');

// Bad: Generic logs
this.devTools.log('info', 'Something happened', 'unknown');
```

### 2. Report Errors with Context

```typescript
// Good: Detailed error reporting
try {
  await this.loadData();
} catch (error) {
  await this.devTools.reportError(
    'DATA_LOAD_ERROR',
    error instanceof Error ? error.message : 'Unknown error',
    'data-component'
  );
}

// Bad: Minimal error reporting
catch (error) {
  console.error(error);
}
```

### 3. Record Meaningful Metrics

```typescript
// Good: Specific metrics with units
await this.devTools.recordMetric('api_latency', 45.2, 'ms');
await this.devTools.recordMetric('bundle_size', 256.5, 'KB');
await this.devTools.recordMetric('cache_hit_rate', 0.85, 'ratio');

// Bad: Vague metrics
await this.devTools.recordMetric('performance', 100, '');
```

### 4. Refresh Strategically

```typescript
// Good: Refresh on demand or at intervals
ngOnInit() {
  this.refresh();
  // Refresh every 30 seconds
  setInterval(() => this.refresh(), 30000);
}

// Bad: Continuous refreshing
ngOnInit() {
  setInterval(() => this.refresh(), 100); // Too frequent!
}
```

---

## Troubleshooting

### Issue: No statistics displayed

**Solution:**
1. Check backend service is initialized
2. Verify API endpoint is registered
3. Check browser console for errors

### Issue: Logs not appearing

**Solution:**
1. Ensure `devtools.getLogs` is called
2. Check log level filtering
3. Verify backend log collection is enabled

### Issue: Metrics not recording

**Solution:**
1. Check metric name is valid
2. Ensure value is a number
3. Verify unit is specified

---

## Performance Considerations

1. **Limit log retention** - Keep last 100 logs maximum
2. **Batch metric recording** - Record metrics in batches when possible
3. **Throttle refresh** - Don't refresh more than once per 30 seconds
4. **Filter errors** - Keep only last 50 errors

---

## Security Considerations

1. **Don't log sensitive data** - Avoid logging passwords, tokens
2. **Sanitize error messages** - Remove stack traces in production
3. **Rate limit endpoints** - Prevent abuse of DevTools APIs
4. **Access control** - Restrict DevTools access in production

---

*Last Updated: 2026-03-15*
