# Desktop Dashboard

A system monitoring desktop application built with V language backend and Angular frontend, using WebUI for native window management.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Dependency Injection Systems](#dependency-injection-systems)
  - [Backend DI (V Language)](#backend-di-v-language)
  - [Frontend DI (Angular)](#frontend-di-angular)
- [Project Structure](#project-structure)
- [Commands](#commands)
- [Development Workflow](#development-workflow)
- [Backend Services](#backend-services)
- [Frontend Services](#frontend-services)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)

## Overview

Desktop Dashboard provides real-time monitoring of system resources including CPU, memory, disk, network, and processes through a modern web-based interface wrapped in a native window.

**Key Features:**
- 🖥️ Real-time system monitoring (CPU, Memory, Disk, Network)
- 📊 Process management and statistics
- 🏥 Health checks and metrics tracking
- 🔐 Authentication service (token-based)
- 💾 Caching with TTL support
- ⚡ Event-driven architecture with pub/sub
- 🎨 Modern Angular frontend with WinBox.js windows
- 🔧 Comprehensive dependency injection on both backend and frontend

## Quick Start

```bash
# Clone and enter the project directory
cd vlang-webui-angular-rspack

# Development mode - rebuilds frontend and runs app
./run.sh dev

# Or simply run (dev is default)
./run.sh
```

## Dependency Injection Systems

This project features comprehensive dependency injection systems on both backend and frontend.

### Backend DI (V Language)

The V backend includes a full-featured DI container with lifecycle management.

#### Core DI Container (`src/di.v`)

```v
import di
import services as svc

// Create container
mut container := di.new_container()

// Register services with different lifecycles
container.register_singleton('logger', logger_instance)
container.register_singleton_fn('config', fn () voidptr {
    return new_config_service()
})
container.register_transient('cache', fn () voidptr {
    return new_cache_service()
})
container.register_scoped('request', fn () voidptr {
    return new_request_service()
})

// Resolve services
logger := container.resolve('logger') or {
    panic('Logger not available')
}
```

**Service Lifecycles:**
- **Singleton**: Single instance for application lifetime
- **Transient**: New instance each resolution
- **Scoped**: One instance per scope (request/session)

#### Available Backend Services

| Service | File | Description |
|---------|------|-------------|
| **ConfigService** | `services/core_services.v` | Configuration from env vars and files |
| **CacheService** | `services/core_services.v` | In-memory caching with TTL |
| **DatabaseService** | `services/core_services.v` | SQLite wrapper (skeleton) |
| **HttpClientService** | `services/core_services.v` | HTTP client wrapper |
| **LoggerService** | `services/additional_services.v` | Enhanced logging with levels |
| **ValidationService** | `services/additional_services.v` | Input validation with rules |
| **MetricsService** | `services/additional_services.v` | Application metrics/telemetry |
| **HealthCheckService** | `services/additional_services.v` | Health monitoring |
| **AuthService** | `services/additional_services.v` | Token-based authentication |
| **SystemInfoService** | `services.v` | System information |

#### Service Interfaces (`src/services/interfaces.v`)

All services implement standardized interfaces:

```v
pub interface IService {
    mut:
        init() bool
        dispose()
        name() string
        is_initialized() bool
}

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

#### Service Registry (`src/services/registry.v`)

Fluent API for service registration:

```v
import services as svc

// Create registry
mut registry := svc.new_service_registry(&container)

// Register all core services
registry.register_all_core_services()

// Or register individually
registry.register_config_service('/path/to/config')
registry.register_logger_service('info')
registry.register_cache_service(1000)
registry.register_validation_service()
registry.register_metrics_service()
registry.register_health_check_service()
registry.register_auth_service(3600)

// Type-safe resolution
logger := registry.get_logger() or { panic('No logger') }
cache := registry.get_cache() or { panic('No cache') }
config := registry.get_config() or { panic('No config') }
```

#### Usage Example

```v
fn main() {
    // Initialize DI
    mut container := di.new_container()
    mut registry := svc.new_service_registry(&container)
    
    // Register services
    registry.register_all_core_services()
    
    // Use services
    logger := registry.get_logger() or { return }
    logger.info('Application starting...')
    
    cache := registry.get_cache() or { return }
    cache.set('key', 'value', 300)
    
    health_check := registry.get_health_check() or { return }
    summary := health_check.get_status()
    
    // Cleanup
    container.dispose()
}
```

### Frontend DI (Angular)

The Angular frontend uses Angular's built-in DI with `@Injectable({ providedIn: 'root' })`.

#### Core Services (`frontend/src/core/`)

| Service | Purpose |
|---------|---------|
| **StorageService** | LocalStorage/SessionStorage with TTL |
| **HttpService** | HTTP client with caching and retry |
| **NotificationService** | Toast notification system |
| **LoadingService** | Loading spinner management |
| **ThemeService** | Dark/light theme switching |
| **ClipboardService** | Clipboard operations |
| **RetryService** | Retry with exponential backoff |
| **NetworkMonitorService** | Network connectivity monitoring |
| **ErrorRecoveryService** | Error recovery strategies |
| **ErrorTelemetryService** | Error tracking |
| **GlobalErrorService** | Global error handling |
| **WinBoxService** | WinBox window management |

#### Service Facade (`frontend/src/core/app-services.facade.ts`)

Unified access to all services:

```typescript
import { AppServices } from './core/app-services.facade';

@Component({...})
export class MyComponent {
  constructor(private services: AppServices) {}
  
  ngOnInit() {
    // Logging
    this.services.logger.info('Hello');
    
    // Storage
    this.services.storage.set('key', 'value');
    const value = this.services.storage.get<string>('key');
    
    // HTTP with caching
    const result = await this.services.http.get<ApiData>('/api/data', { cache: true });
    
    // Notifications
    this.services.notifications.success('Saved!', 'Data updated');
    this.services.notify('Processing...');
    
    // Loading
    await this.services.withLoading(
      () => this.services.http.post('/api/save', data),
      'Saving...'
    );
    
    // Theme
    this.services.theme.setTheme('dark');
    this.services.theme.toggle();
    
    // Clipboard
    await this.services.clipboard.copy('text');
    await this.services.copyWithNotify('text', 'Copied!');
    
    // Network status
    const online = this.services.network.isOnline();
    const quality = this.services.network.connectionQuality();
  }
}
```

#### Individual Service Usage

```typescript
// Storage Service
constructor(private storage: StorageService) {}

this.storage.set('user', { name: 'John' });
const user = this.storage.get<User>('user');
this.storage.delete('user');
const hasUser = this.storage.has('user');

// HTTP Service
constructor(private http: HttpService) {}

this.http.setBaseUrl('/api');
this.http.setAuthToken(token);

const result = await this.http.get<User[]>('/users');
const created = await this.http.post<User>('/users', userData);
await this.http.put('/users/1', userData);
await this.http.delete('/users/1');

// Notification Service
constructor(private notifications: NotificationService) {}

this.notifications.info('Info', 'Message');
this.notifications.success('Success', 'Message');
this.notifications.warning('Warning', 'Message');
this.notifications.error('Error', 'Message');

// Loading Service
constructor(private loading: LoadingService) {}

const id = this.loading.show('Loading...');
this.loading.hide(id);
this.loading.hideAll();

// Theme Service
constructor(private theme: ThemeService) {}

this.theme.setTheme('dark');
this.theme.setTheme('light');
this.theme.setTheme('system');
this.theme.toggle();
const isDark = this.theme.isDark();

// Clipboard Service
constructor(private clipboard: ClipboardService) {}

const result = await this.clipboard.copy('text');
const pasted = await this.clipboard.paste();
```

## Project Structure

```
.
├── src/                        # V backend source code
│   ├── main.v                  # Main application entry point
│   ├── di.v                    # Dependency Injection container
│   ├── result.v                # Result type for errors as values
│   ├── error.v                 # Error handling with structured errors
│   ├── events.v                # Event bus for pub/sub
│   ├── services.v              # System info service
│   ├── services/
│   │   ├── interfaces.v        # Service interfaces (ILogger, IConfig, etc.)
│   │   ├── core_services.v     # Config, Cache, Database, HttpClient
│   │   ├── additional_services.v # Logger, Validation, Metrics, Health, Auth
│   │   └── registry.v          # Service registry with fluent API
│   ├── system.v                # System information (CPU, memory, OS)
│   ├── network.v               # Network interfaces and connection
│   ├── process.v               # Process information and load
│   └── filesystem.v            # File system operations
│   ├── di_test.v               # DI container tests
│   └── services_test.v         # Service tests
├── frontend/                   # Angular frontend application
│   ├── src/
│   │   ├── core/
│   │   │   ├── storage.service.ts       # Storage abstraction
│   │   │   ├── http.service.ts          # HTTP client
│   │   │   ├── notification.service.ts  # Toast notifications
│   │   │   ├── loading.service.ts       # Loading management
│   │   │   ├── theme.service.ts         # Theme switching
│   │   │   ├── clipboard.service.ts     # Clipboard operations
│   │   │   ├── retry.service.ts         # Retry logic
│   │   │   ├── network-monitor.service.ts # Network monitoring
│   │   │   ├── app-services.facade.ts   # Service facade
│   │   │   └── index.ts                 # Core exports
│   │   ├── viewmodels/         # State management with signals
│   │   ├── models/             # Data models
│   │   ├── types/              # TypeScript types
│   │   └── views/              # Angular components
│   └── docs/
│       └── DI_EVALUATION.md    # Frontend DI evaluation
├── docs/                       # Documentation
│   ├── DI_SYSTEM.md            # Backend DI system documentation
│   ├── ERRORS_AS_VALUES.md     # Error handling guide
│   └── README.md               # This file
├── v.mod                       # V module configuration
├── run.sh                      # Build and run automation
└── build.config.sh             # Build configuration
```

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Start development mode |
| `./run.sh dev` | Development mode (same as above) |
| `./run.sh build` | Full production build |
| `./run.sh build:fe` | Build frontend only |
| `./run.sh build:be` | Build backend only |
| `./run.sh run` | Run existing build |
| `./run.sh clean` | Remove build artifacts |
| `./run.sh help` | Display help |

### Frontend Commands

```bash
cd frontend

bun run dev          # Development server
bun run build:rspack # Production build
bun run watch        # Watch mode
bun run lint         # Lint code
bun run lint:fix     # Fix linting
bun test             # Run tests
```

### Backend Commands

```bash
# Build backend
v -cc gcc -o desktop-dashboard src/

# Run backend
v -cc gcc run src/

# Run tests
v test src/di_test.v
v test src/services_test.v
```

## Development Workflow

### Full Development Mode

```bash
./run.sh dev
```

1. Rebuilds frontend with Rspack
2. Rebuilds backend
3. Runs application

### Separate Development

```bash
# Terminal 1 - Frontend watch
cd frontend
bun run watch

# Terminal 2 - Backend run
./run.sh run
```

## Backend Services

### ConfigService

```v
config := new_config_service()
config.init()
config.load_from_env()
config.load_from_file('.env')

name := config.get_string('app_name', 'Default')
port := config.get_int('port', 8080)
debug := config.get_bool('debug', false)
```

### CacheService

```v
cache := new_cache_service()
cache.init()
cache.max_size = 1000

cache.set('key', 'value', 300) // 5 min TTL
value := cache.get('key') or { 'default' }
has := cache.has('key')
stats := cache.get_stats()
```

### ValidationService

```v
validation := new_validation_service()
validation.add_rule('email', 'required')
validation.add_rule('email', 'email')
validation.add_rule('password', 'min:8')

result := validation.validate({'email': 'test@example.com', 'password': 'secret'})
if !result.is_valid {
    for err in result.errors {
        println('${err.field}: ${err.message}')
    }
}
```

### MetricsService

```v
metrics := new_metrics_service()
metrics.init()

metrics.increment_counter('requests', 1)
metrics.record_gauge('temperature', 25.5)
metrics.record_histogram('response_time', 150.0)
metrics.record_timing('api_call', 50.0)

all_metrics := metrics.get_all_metrics()
uptime := metrics.get_uptime_seconds()
```

### HealthCheckService

```v
health := new_health_check_service()
health.init()

health.register_check('database', fn () HealthStatus {
    // Check database connection
    return HealthStatus{...}
})

summary := health.get_status()
if !summary.is_healthy {
    println('System unhealthy: ${summary.unhealthy_checks} checks failed')
}
```

### AuthService

```v
auth := new_auth_service()
auth.init()

// Register user
auth.register_user('john', 'password123', 'john@example.com')

// Authenticate
result := auth.authenticate('john', 'password123') or {
    println('Auth failed')
    return
}
println('Token: ${result.token}')

// Validate token
validated := auth.validate_token(result.token) or {
    println('Invalid token')
    return
}

// Check permissions
if auth.has_permission('admin') {
    println('User is admin')
}
```

## Frontend Services

See [Frontend DI](#frontend-di-angular) section above for detailed usage.

## API Reference

### System Endpoints

| Endpoint | Description |
|----------|-------------|
| `getSystemInfo()` | Get comprehensive system info |
| `getMemoryInfo()` | Get memory statistics |
| `getCPUInfo()` | Get CPU information |
| `getDiskInfo()` | Get disk usage for all mounts |
| `getNetworkInfo()` | Get network interfaces |
| `getConnectionStatus()` | Get connection status |
| `getNetworkStats()` | Get network statistics |
| `getProcessInfo()` | Get running processes |
| `getSystemLoad()` | Get system load averages |
| `getProcessStats()` | Get process statistics |
| `getDashboardData()` | Get complete dashboard data |

### Service Endpoints (New)

| Endpoint | Description |
|----------|-------------|
| `getHealthStatus()` | Get health check summary |
| `getMetrics()` | Get application metrics |
| `cacheSet(data)` | Set cache value |
| `cacheGet(data)` | Get cache value |
| `cacheStats()` | Get cache statistics |
| `getConfig()` | Get configuration |
| `authLogin(data)` | Authenticate user |
| `authLogout()` | Logout user |
| `authGetCurrentUser()` | Get current user |
| `getServiceInfo()` | Get registered services info |

## Error Handling

### Backend - Errors as Values

```v
import result
import error

// Return Result types
pub fn get_user(id int) result.Result[User] {
    if id <= 0 {
        return result.err[User](error.validation_error('id', 'ID must be positive'))
    }
    
    user_result := fetch_user(id)
    if user_result.is_err() {
        return result.err[User](error.wrap(user_result.error, 'Failed to fetch user'))
    }
    
    return result.ok[User](user_result.value)
}

// Handle results
user_result := get_user(123)
match user_result {
    result.Result[User] {
        if user_result.is_ok() {
            println('User: ${user_result.value.name}')
        } else {
            error.log_error(user_result.error)
            return error.to_response(user_result.error)
        }
    }
}
```

### Frontend - Result Types

```typescript
import { type Result, isOk, err, ok } from './types';

async function getUser(id: number): Promise<Result<User>> {
    if (id <= 0) {
        return err({
            code: 'VALIDATION_ERROR',
            message: 'ID must be positive'
        });
    }
    
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
        return err({
            code: 'NOT_FOUND',
            message: 'User not found'
        });
    }
    
    return ok(await response.json());
}

// Handle results
const result = await getUser(123);
if (isOk(result)) {
    console.log('User:', result.value);
} else {
    console.error('Error:', result.error);
}
```

## Testing

### Backend Tests

```bash
# DI Container tests
v test src/di_test.v

# Service tests
v test src/services_test.v

# Error handling tests
v test src/error_test.v
```

### Frontend Tests

```bash
cd frontend
bun test
```

## Requirements

### System
- Linux (tested), macOS (partial), Windows (partial)
- 512MB RAM minimum
- 100MB disk space

### Development
- V Language 0.5.1+
- GCC
- Bun 1.0+
- Node.js 18+

### Runtime
- GTK3 (Linux)
- WebKit (Linux)
- Modern browser (Chrome, Edge, Firefox)

## Troubleshooting

### Frontend dist not found
```bash
./run.sh build:fe
```

### Backend build fails
```bash
v version
./run.sh build:be
```

### Window fails to open
```bash
ldd ./desktop-dashboard | grep -E 'gtk|webkit'
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

## Documentation

| Document | Description |
|----------|-------------|
| `docs/DI_SYSTEM.md` | Backend DI system documentation |
| `docs/ERRORS_AS_VALUES.md` | Error handling guide |
| `frontend/docs/DI_EVALUATION.md` | Frontend DI evaluation |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

## License

MIT License

## Acknowledgments

- [WebUI Library](https://webui.me)
- [V Language](https://vlang.io)
- [Angular](https://angular.dev)
- [Rspack](https://rspack.rs)
- [WinBox.js](https://winbox.kodinger.com)
