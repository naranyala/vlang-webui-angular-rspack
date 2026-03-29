# Services Guide

Complete guide to using services in both backend and frontend.

## Backend Services

### ConfigService

Configuration management with environment and file support.

```v
import services as svc

config := registry.get_config() or { return }
config.init()

// Load from environment (APP_ prefix)
config.load_from_env()

// Load from file
config.load_from_file('.env')

// Get values
name := config.get_string('app_name', 'Default')
port := config.get_int('port', 8080)
debug := config.get_bool('debug', false)
timeout := config.get_float('timeout', 30.0)

// Check existence
if config.has('api_key') {
    api_key := config.get('api_key') or { '' }
}

// Set value
config.set('custom_key', 'custom_value')

// Get all
all_config := config.get_all()
```

---

### CacheService

In-memory caching with TTL support.

```v
cache := registry.get_cache() or { return }
cache.init()
cache.max_size = 1000

// Set with TTL (seconds)
cache.set('user:123', user_json, 300)  // 5 minutes

// Get value
user_json := cache.get('user:123') or {
    // Cache miss - fetch from source
    fetch_user(123)
}

// Check existence
if cache.has('user:123') {
    // Use cached value
}

// Delete
cache.delete('user:123')

// Clear all
cache.clear()

// Get statistics
stats := cache.get_stats()
println('Hit rate: ${stats.hit_rate}%')
```

---

### LoggerService

Structured logging with levels.

```v
logger := registry.get_logger() or { return }
logger.init()
logger.set_min_level('info')

// Log at different levels
logger.debug('Debug message')
logger.info('Info message')
logger.warn('Warning message')
logger.error('Error message')
logger.fatal('Fatal message')

// Log with custom level
logger.log('custom', 'Custom message')

// Enable file logging
logger.enable_file_logging('/var/log/app.log')
```

---

### ValidationService

Input validation with rules.

```v
validation := registry.get_validation() or { return }
validation.init()

// Add rules
validation.add_rule('email', 'required')
validation.add_rule('email', 'email')
validation.add_rule('password', 'min:8')
validation.add_rule('password', 'max:100')
validation.add_rule('username', 'min:3')
validation.add_rule('username', 'max:20')
validation.add_rule('username', 'alphanumeric')
validation.add_rule('age', 'numeric')

// Validate
data := {
    'email': 'test@example.com'
    'password': 'secret123'
    'username': 'john'
    'age': '25'
}

result := validation.validate(data)

if !result.is_valid {
    for err in result.errors {
        println('${err.field}: ${err.message}')
    }
} else {
    println('Validation passed!')
}
```

---

### MetricsService

Application metrics and telemetry.

```v
metrics := registry.get_metrics() or { return }
metrics.init()

// Increment counter
metrics.increment_counter('requests', 1)
metrics.increment_counter('errors', 1)

// Record gauge
metrics.record_gauge('temperature', 25.5)
metrics.record_gauge('memory_percent', 45.2)

// Record histogram
metrics.record_histogram('response_time', 150.0)
metrics.record_histogram('response_time', 200.0)

// Record timing
start := time.now()
// ... operation ...
duration := f64(time.now().unix() - start) * 1000.0
metrics.record_timing('api_call', duration)

// Get metrics
all_metrics := metrics.get_all_metrics()
uptime := metrics.get_uptime_seconds()

// Get timing stats
timing_stats := metrics.get_timing_stats('api_call')
println('Avg: ${timing_stats.avg}ms')
```

---

### HealthCheckService

Health monitoring with custom checks.

```v
health := registry.get_health_check() or { return }
health.init()

// Register custom check
health.register_check('database', fn () HealthStatus {
    connected := check_database_connection()
    
    return HealthStatus{
        name: 'database'
        is_healthy: connected
        status: if connected { 'healthy' } else { 'unhealthy' }
        message: if connected { 'Database connected' } else { 'Connection failed' }
        timestamp: u64(time.now().unix())
        details: map[string]string{}
    }
})

// Run all checks
summary := health.get_status()

if !summary.is_healthy {
    println('System unhealthy: ${summary.unhealthy_checks} checks failed')
}

// Run specific check
check_result := health.run_check('database') or {
    println('Check not found')
    return
}
```

---

### AuthService

Token-based authentication.

```v
auth := registry.get_auth() or { return }
auth.init()

// Register user
success := auth.register_user('john', 'password123', 'john@example.com')

// Authenticate
result := auth.authenticate('john', 'password123') or {
    println('Authentication failed')
    return
}

println('Token: ${result.token}')
println('Expires: ${result.expires_at}')

// Validate token
validated := auth.validate_token(result.token) or {
    println('Invalid token')
    return
}

// Set current user
auth.set_current_user('john')

// Check permissions
if auth.has_permission('admin') {
    println('User is admin')
}

if auth.has_role('user') {
    println('User has user role')
}

// Logout
auth.logout()
```

---

## Frontend Services

### StorageService

```typescript
constructor(private storage: StorageService) {}

// Set with TTL
this.storage.set('user', user, { ttl: 3600000 }); // 1 hour

// Get with default
const user = this.storage.get<User>('user', defaultUser);

// Check existence
const hasUser = this.storage.has('user');

// Delete
this.storage.delete('user');

// Get all
const all = this.storage.getAll<User>();

// Get stats
const stats = this.storage.getStats();
```

---

### HttpService

```typescript
constructor(private http: HttpService) {}

// Configure
this.http.setBaseUrl('/api');
this.http.setAuthToken(token);

// GET with caching
const users = await this.http.get<User[]>('/users', { 
  cache: true, 
  cacheTtl: 60000 
});

// POST with retry
const created = await this.http.post<User>('/users', userData, {
  retry: true,
  maxRetries: 3
});

// PUT
await this.http.put('/users/1', userData);

// DELETE
await this.http.delete<User>('/users/1');

// Get stats
const stats = this.http.getStats();
```

---

### NotificationService

```typescript
constructor(private notifications: NotificationService) {}

// Info
this.notifications.info('Info', 'Message');

// Success
this.notifications.success('Saved!', 'Data updated');

// Warning
this.notifications.warning('Warning', 'Data is stale');

// Error
this.notifications.error('Error', 'Failed to save');

// Custom duration
this.notifications.show('Title', 'Message', { duration: 10000 });

// Dismiss
this.notifications.dismiss(id);
this.notifications.dismissAll();
```

---

### LoadingService

```typescript
constructor(private loading: LoadingService) {}

// Show
const id = this.loading.show('Loading...');

// Hide
this.loading.hide(id);
this.loading.hideAll();

// Wrap promise
const result = await this.loading.wrap(
  () => this.http.post('/api/save', data),
  'Saving...'
);

// Wrap multiple
const results = await this.loading.wrapAll([
  this.http.get('/api/data1'),
  this.http.get('/api/data2')
], 'Loading data...');
```

---

### ThemeService

```typescript
constructor(private theme: ThemeService) {}

// Initialize
this.theme.init();

// Set theme
this.theme.setTheme('dark');
this.theme.setTheme('light');
this.theme.setTheme('system');

// Toggle
this.theme.toggle();

// Check state
const isDark = this.theme.isDark();
const isLight = this.theme.isLight();
const effectiveTheme = this.theme.getEffectiveTheme();
```

---

### ClipboardService

```typescript
constructor(private clipboard: ClipboardService) {}

// Copy
const result = await this.clipboard.copy('text to copy');
if (result.success) {
  console.log('Copied!');
}

// Paste
const pasted = await this.clipboard.paste();

// Check availability
const available = this.clipboard.isAvailable();

// Copy with notification
await this.clipboard.copyWithNotify('text', 'Copied to clipboard!');
```

---

### AppServices Facade

Unified access to all services:

```typescript
constructor(private services: AppServices) {}

// Quick notifications
this.services.notify('Processing...');
this.services.success('Done!');
this.services.error('Failed!');

// With loading
const result = await this.services.withLoading(
  () => this.services.http.post('/api/save', data),
  'Saving...',
  'Save failed'
);

// Copy with notification
await this.services.copyWithNotify('text', 'Copied!');

// Get stats
const storageStats = this.services.getStorageStats();
const httpStats = this.services.getHttpStats();
const networkStats = this.services.getNetworkStats();
```
