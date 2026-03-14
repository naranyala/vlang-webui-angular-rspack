# Dependency Injection Guide

Comprehensive guide to dependency injection systems in both backend (V) and frontend (Angular).

## Table of Contents

1. [Overview](#overview)
2. [Backend DI System](#backend-di-system)
3. [Frontend DI System](#frontend-di-system)
4. [Service Catalog](#service-catalog)
5. [Best Practices](#best-practices)

## Overview

This project implements dependency injection on both tiers:

| Aspect | Backend (V) | Frontend (Angular) |
|--------|-------------|-------------------|
| Container | Custom DI Container | Angular Built-in |
| Registration | Manual with registry | `providedIn: 'root'` |
| Lifecycles | Singleton, Transient, Scoped | Singleton (default) |
| Resolution | `resolve()` method | Constructor injection |
| Interfaces | Explicit interfaces | TypeScript interfaces |

## Backend DI System

### Container Basics

```v
import di
import services as svc

// Create container
mut container := di.new_container()

// Create registry for fluent API
mut registry := svc.new_service_registry(&container)
```

### Service Lifecycles

#### Singleton
Single instance for application lifetime:

```v
container.register_singleton('logger', logger_instance)

// Or with factory
container.register_singleton_fn('config', fn () voidptr {
    mut service := new_config_service()
    service.init()
    return service
})
```

#### Transient
New instance each resolution:

```v
container.register_transient('request_handler', fn () voidptr {
    return new_request_handler()
})
```

#### Scoped
One instance per scope (request/session):

```v
container.register_scoped('session', fn () voidptr {
    return new_session_service()
})

// Create and use scope
container.create_scope('request_1')
container.use_scope('request_1')
// ... use scoped services ...
container.dispose_scope('request_1')
```

### Service Registry

Fluent API for registration:

```v
// Register all core services
registry.register_all_core_services()

// Register individually
registry.register_config_service('/path/to/config')
registry.register_logger_service('info')
registry.register_cache_service(1000)
registry.register_validation_service()
registry.register_metrics_service()
registry.register_health_check_service()
registry.register_auth_service(3600)  // 1 hour token expiry
registry.register_system_info_service()

// Register additional services
registry.register_http_client_service('https://api.example.com', 30000)
registry.register_database_service('sqlite:///app.db')
```

### Service Resolution

```v
// Type-safe resolution helpers
logger := registry.get_logger() or {
    panic('Logger not available')
}

cache := registry.get_cache() or {
    panic('Cache not available')
}

config := registry.get_config() or {
    panic('Config not available')
}

// Generic resolution
service := container.resolve('my_service') or {
    panic('Service not found')
}
unsafe {
    my_service := &MyService(service)
    my_service.do_something()
}
```

### Service Interfaces

All services implement `IService`:

```v
pub interface IService {
    mut:
        init() bool
        dispose()
        name() string
        is_initialized() bool
}
```

Additional interfaces for specific capabilities:

```v
pub interface ILogger {
    mut:
        debug(message string)
        info(message string)
        warn(message string)
        error(message string)
        fatal(message string)
}

pub interface IConfig {
    mut:
        get(key string) ?string
        get_string(key string, default string) string
        get_int(key string, default int) int
        get_bool(key string, default bool) bool
        set(key string, value string)
        has(key string) bool
}

pub interface ICache {
    mut:
        get(key string) ?string
        set(key string, value string, ttl_seconds int) bool
        delete(key string) bool
        has(key string) bool
        clear()
}
```

## Frontend DI System

### Angular DI

Services use `@Injectable({ providedIn: 'root' })`:

```typescript
@Injectable({ providedIn: 'root' })
export class StorageService {
  constructor() {}
  
  get<T>(key: string): T | null {
    // Implementation
  }
}
```

### Service Facade

Unified access via `AppServices`:

```typescript
import { AppServices } from './core/app-services.facade';

@Component({...})
export class MyComponent {
  constructor(private services: AppServices) {}
  
  ngOnInit() {
    // All services available through single injection
    this.services.logger.info('Hello');
    this.services.storage.set('key', 'value');
    this.services.notifications.success('Done!');
  }
}
```

### Individual Service Injection

```typescript
@Component({...})
export class MyComponent {
  constructor(
    private storage: StorageService,
    private http: HttpService,
    private notifications: NotificationService,
    private loading: LoadingService,
    private theme: ThemeService,
    private clipboard: ClipboardService,
  ) {}
}
```

## Service Catalog

### Backend Services

| Service | File | Interface | Description |
|---------|------|-----------|-------------|
| **ConfigService** | `core_services.v` | `IConfig` | Environment and file configuration |
| **CacheService** | `core_services.v` | `ICache` | In-memory caching with TTL |
| **DatabaseService** | `core_services.v` | `IDatabase` | SQLite wrapper |
| **HttpClientService** | `core_services.v` | `IHttpClient` | HTTP client wrapper |
| **LoggerService** | `additional_services.v` | `ILogger` | Structured logging with levels |
| **ValidationService** | `additional_services.v` | `IValidationService` | Input validation with rules |
| **MetricsService** | `additional_services.v` | `IMetricsService` | Application metrics |
| **HealthCheckService** | `additional_services.v` | `IHealthCheck` | Health monitoring |
| **AuthService** | `additional_services.v` | `IAuthService` | Token-based authentication |
| **SystemInfoService** | `services.v` | `IService` | System information |

### Frontend Services

| Service | File | Description |
|---------|------|-------------|
| **StorageService** | `storage.service.ts` | LocalStorage/SessionStorage with TTL |
| **HttpService** | `http.service.ts` | HTTP client with caching and retry |
| **NotificationService** | `notification.service.ts` | Toast notifications |
| **LoadingService** | `loading.service.ts` | Loading spinner management |
| **ThemeService** | `theme.service.ts` | Dark/light theme switching |
| **ClipboardService** | `clipboard.service.ts` | Clipboard operations |
| **RetryService** | `retry.service.ts` | Retry with exponential backoff |
| **NetworkMonitorService** | `network-monitor.service.ts` | Network connectivity |
| **ErrorRecoveryService** | `error-recovery.service.ts` | Error recovery |
| **ErrorTelemetryService** | `error-telemetry.service.ts` | Error tracking |
| **GlobalErrorService** | `global-error.service.ts` | Global error state |
| **WinBoxService** | `winbox.service.ts` | WinBox window management |

## Usage Examples

### Backend - ConfigService

```v
config := registry.get_config() or { return }
config.init()
config.load_from_env()
config.load_from_file('.env')

app_name := config.get_string('app_name', 'Default')
port := config.get_int('port', 8080)
debug := config.get_bool('debug', false)
```

### Backend - CacheService

```v
cache := registry.get_cache() or { return }
cache.init()
cache.max_size = 1000

cache.set('user:123', user_json, 300)  // 5 min TTL
user_json := cache.get('user:123') or { fetch_user(123) }
stats := cache.get_stats()
```

### Backend - ValidationService

```v
validation := registry.get_validation() or { return }
validation.init()

validation.add_rule('email', 'required')
validation.add_rule('email', 'email')
validation.add_rule('password', 'min:8')

result := validation.validate(data)
if !result.is_valid {
    for err in result.errors {
        println('${err.field}: ${err.message}')
    }
}
```

### Frontend - StorageService

```typescript
constructor(private storage: StorageService) {}

// Set with TTL
this.storage.set('user', user, { ttl: 3600000 }); // 1 hour

// Get with default
const user = this.storage.get<User>('user', defaultUser);

// Check existence
const hasUser = this.storage.has('user');

// Get stats
const stats = this.storage.getStats();
```

### Frontend - HttpService

```typescript
constructor(private http: HttpService) {}

// Set base URL and auth
this.http.setBaseUrl('/api');
this.http.setAuthToken(token);

// GET with caching
const result = await this.http.get<User[]>('/users', { 
  cache: true, 
  cacheTtl: 60000 
});

// POST with retry
const created = await this.http.post<User>('/users', userData, {
  retry: true,
  maxRetries: 3
});
```

### Frontend - NotificationService

```typescript
constructor(private notifications: NotificationService) {}

// Info
this.notifications.info('Info', 'Message');

// Success
this.notifications.success('Saved!', 'Data updated successfully');

// Warning
this.notifications.warning('Warning', 'Data is stale');

// Error
this.notifications.error('Error', 'Failed to save data');

// With custom duration
this.notifications.show('Title', 'Message', { duration: 10000 });
```

## Best Practices

### 1. Use Interfaces

Define interfaces for testability:

```v
// Backend
pub interface ILogger {
    info(message string)
    error(message string)
}

// Use interface in structs
pub struct MyService {
    logger &ILogger  // Can be mocked in tests
}
```

```typescript
// Frontend
export interface IStorage {
  get<T>(key: string): T | null;
  set<T>(key: string, value: T): void;
}

// Use interface in constructors
constructor(private storage: IStorage) {}
```

### 2. Proper Lifecycle Selection

| Use Case | Lifecycle |
|----------|-----------|
| Configuration | Singleton |
| Logging | Singleton |
| Cache | Singleton |
| Database Connection | Singleton |
| HTTP Client | Singleton |
| Request Handler | Transient |
| Session Data | Scoped |

### 3. Dispose Resources

Implement cleanup:

```v
pub fn (s &DatabaseService) dispose() {
    s.disconnect()
}

pub fn (s &CacheService) dispose() {
    s.clear()
}

// Container calls dispose on all services
container.dispose()
```

```typescript
@Injectable({ providedIn: 'root' })
export class NetworkMonitorService implements OnDestroy {
  ngOnDestroy(): void {
    clearInterval(this.checkInterval);
  }
}
```

### 4. Service Composition

Compose services via facade:

```typescript
// Good - Single injection point
constructor(private services: AppServices) {}

async saveData(data: any) {
  await this.services.withLoading(
    () => this.services.http.post('/api/save', data),
    'Saving...'
  );
  this.services.notifications.success('Saved!');
}
```

### 5. Error Handling in Services

Return Result types:

```v
pub fn get_user(id int) result.Result[User] {
    if id <= 0 {
        return result.err[User](error.validation_error('id', 'Invalid'))
    }
    return fetch_user(id)
}
```

```typescript
async getUser(id: number): Promise<Result<User>> {
    if (id <= 0) {
        return err({ code: 'VALIDATION_ERROR', message: 'Invalid' });
    }
    return ok(await this.http.get<User>(`/users/${id}`));
}
```

## Testing Services

### Backend Tests

```v
fn test_cache_service() {
    mut cache := new_cache_service()
    cache.init()
    
    cache.set('key', 'value', 300)
    assert cache.has('key') == true
    
    value := cache.get('key') or {
        assert false
        return
    }
    assert value == 'value'
}
```

### Frontend Tests

```typescript
describe('StorageService', () => {
  let service: StorageService;
  
  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(StorageService);
  });
  
  it('should store and retrieve values', () => {
    service.set('key', 'value');
    expect(service.get('key')).toBe('value');
  });
});
```

## Migration Guide

### Adding a New Service

1. Create service file in appropriate location
2. Implement interface if applicable
3. Register in DI container/registry
4. Add to service catalog in documentation
5. Write tests

### Backend Registration

```v
// In registry.v
pub fn (mut sr ServiceRegistry) register_my_service() &ServiceRegistry {
    result := sr.container.register_singleton_fn('my_service', fn () voidptr {
        mut service := new_my_service()
        service.init()
        return service
    })
    
    if result.success {
        sr.registered << 'my_service'
    }
    
    return sr
}
```

### Frontend Registration

```typescript
// Just use providedIn: 'root'
@Injectable({ providedIn: 'root' })
export class MyService {
  // Automatically available
}
```
