# Desktop Dashboard

A system monitoring desktop application built with V language backend and Angular frontend, using WebUI for native window management.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Features](#features)
- [Architecture](#architecture)
- [Backend Services](#backend-services)
- [Frontend Services](#frontend-services)
- [Project Structure](#project-structure)
- [Commands](#commands)
- [Testing](#testing)
- [Audit Results](#audit-results)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)

---

## Overview

Desktop Dashboard provides real-time monitoring of system resources including CPU, memory, disk, network, and processes through a modern web-based interface wrapped in a native window.

**Key Features:**

- Real-time system monitoring (CPU, Memory, Disk, Network)
- Process management and statistics
- Secure authentication service (password hashing, CSRF protection)
- SQLite/JSON persistent storage with full CRUD operations
- Caching with TTL support
- Modern Angular frontend with WinBox.js windows
- Rate limiting and input validation
- Multiple communication protocols (WebUI Bridge, HTTP, Events)

---

## Quick Start

```bash
# Clone and enter the project directory
cd vlang-webui-angular-rspack

# Development mode - rebuilds frontend and runs app
./run.sh dev

# Or simply run (dev is default)
./run.sh
```

---

## Features

### Security Features

| Feature | Status | Description |
|---------|--------|-------------|
| Password Hashing | Implemented | PBKDF2-based secure password storage |
| Secure Tokens | Implemented | Cryptographically secure random tokens |
| Input Validation | Implemented | Server-side validation for all inputs |
| Rate Limiting | Implemented | Per-IP and per-user rate limiting |
| CSRF Protection | Implemented | Token-based CSRF protection |
| SQL Injection Prevention | Implemented | Parameterized queries, identifier validation |

### Backend Services

| Service | File | Description |
|---------|------|-------------|
| ConfigService | src/services.v | Configuration from env vars and files |
| CacheService | src/services.v | In-memory caching with TTL |
| LoggerService | src/services.v | Enhanced logging with levels |
| ValidationService | src/services.v | Input validation with rules |
| SqliteService | src/services.v | SQLite/JSON CRUD operations |

### Frontend Services

| Service | File | Description |
|---------|------|-------------|
| StorageService | frontend/src/core/storage.service.ts | LocalStorage/SessionStorage with TTL |
| HttpService | frontend/src/core/http.service.ts | HTTP client with caching and retry |
| NotificationService | frontend/src/core/notification.service.ts | Toast notification system |
| LoadingService | frontend/src/core/loading.service.ts | Loading spinner management |
| ThemeService | frontend/src/core/theme.service.ts | Dark/light theme switching |
| ClipboardService | frontend/src/core/clipboard.service.ts | Clipboard operations |
| NetworkMonitorService | frontend/src/core/network-monitor.service.ts | Network connectivity monitoring |
| LoggerService | frontend/src/core/logger.service.ts | Application logging |
| ApiService | frontend/src/core/api.service.ts | Backend communication |

---

## Architecture

```
+-----------------------------------------------------------------+
|                         Frontend (Angular)                       |
|  +-------------+  +-------------+  +-------------------------+  |
|  |   Angular   |  |   WinBox    |  |    Service Layer        |  |
|  |  Components |  |   Windows   |  |    (DI Injected)        |  |
|  +-------------+  +-------------+  +-------------------------+  |
|         |                |                    |                  |
|         |          WebSocket              EventBus               |
|         |                |                    |                  |
|         +----------------+--------------------+                  |
+--------------------------+---------------------------------------+
                           |
                           | WebUI Bridge (JavaScript <-> V)
                           |
+--------------------------+---------------------------------------+
|                         Backend (V Language)                      |
|                          |                                        |
|  +-------------+  +------+-------+  +-------------------------+  |
|  |   WebUI     |  |   Services   |  |    Service Layer        |  |
|  |   Server    |  |   (Direct)   |  |    (Direct Composition) |  |
|  +-------------+  +--------------+  +-------------------------+  |
|                          |                                        |
|                   Linux Sysfs / Procfs                            |
+-------------------------------------------------------------------+
```

### Communication Protocols

The application uses three communication approaches:

1. **WebUI Bridge** (Primary) - RPC-style communication for desktop window management
2. **HTTP/Fetch** (Secondary) - RESTful communication for future web deployment
3. **Event Bus** (Pub/Sub) - Cross-component state synchronization

See [docs/05-COMMUNICATION.md](docs/05-COMMUNICATION.md) for detailed documentation.

---

## Backend Services

### Service Architecture

The backend uses direct composition for dependency injection. Services are created in main() and passed to handlers that need them.

### ConfigService

Manages application configuration from environment variables and files.

```v
// Create and initialize
config := new_config_service()
config.init()

// Get values
value := config.get_string('key', 'default')
int_val := config.get_int('number', 0)
bool_val := config.get_bool('flag', false)

// Set values
config.set('key', 'value')
```

### LoggerService

Provides structured logging with multiple levels.

```v
// Create and initialize
logger := new_logger_service()
logger.init()

// Log at different levels
logger.debug('Debug message')
logger.info('Info message')
logger.warn('Warning message')
logger.error('Error message')
logger.fatal('Fatal message')
```

### CacheService

In-memory caching with TTL support.

```v
// Create and initialize
cache := new_cache_service()
cache.init()

// Set with TTL (seconds)
cache.set('key', 'value', 300)

// Get value
value := cache.get('key') or {
    // Handle not found
}

// Check existence
if cache.has('key') {
    // Key exists and not expired
}

// Delete
cache.delete('key')

// Clear all
cache.clear()
```

### ValidationService

Input validation with configurable rules.

```v
// Create and initialize
validation := new_validation_service()
validation.init()

// Add rules
validation.add_rule('email', 'required')
validation.add_rule('email', 'email')
validation.add_rule('password', 'min:8')

// Validate
result := validation.validate(data)
if !result.is_valid {
    // Handle validation errors
    for err in result.errors {
        println('${err.field}: ${err.message}')
    }
}
```

### SqliteService

File-based SQLite/JSON storage for user data.

```v
// Create and initialize
db := new_sqlite_service('users.db') or {
    // Handle error
}

// Get all users
users := db.get_all_users()

// Create user
user := db.create_user('Name', 'email@example.com', 25) or {
    // Handle error
}

// Update user
updated := db.update_user(1, 'New Name', 'new@example.com', 30) or {
    // Handle error
}

// Delete user
db.delete_user(1) or {
    // Handle error
}

// Get statistics
stats := db.get_stats()
```

---

## Frontend Services

### Service Architecture

The frontend uses Angular's built-in dependency injection with providedIn: 'root' for singleton services.

### ApiService

Handles backend communication via WebUI bridge.

```typescript
// Inject service
constructor(private api: ApiService) {}

// Call backend function
async loadData() {
    const result = await this.api.call('getUsers');
    if (result.success) {
        this.users = result.data;
    }
}

// Call with error throwing
async loadData() {
    try {
        const data = await this.api.callOrThrow('getUsers');
        this.users = data;
    } catch (error) {
        this.handleError(error);
    }
}
```

### StorageService

LocalStorage/SessionStorage abstraction with TTL support.

```typescript
// Inject service
constructor(private storage: StorageService) {}

// Set value
this.storage.set('key', 'value');

// Set with TTL (milliseconds)
this.storage.set('key', 'value', { ttl: 60000 });

// Get value
const value = this.storage.get('key', 'default');

// Check existence
if (this.storage.has('key')) {
    // Key exists
}

// Delete
this.storage.delete('key');

// Clear all
this.storage.clear();
```

### NotificationService

Toast notification system.

```typescript
// Inject service
constructor(private notifications: NotificationService) {}

// Show notifications
this.notifications.success('Operation completed');
this.notifications.error('Operation failed');
this.notifications.info('Information message');
this.notifications.warning('Warning message');

// Custom duration
this.notifications.success('Saved', 5000);

// Dismiss
this.notifications.dismiss(notificationId);

// Clear all
this.notifications.clear();
```

### LoggerService

Application logging with signal-based state.

```typescript
// Inject service
constructor(private logger: LoggerService) {}

// Log at different levels
this.logger.debug('Debug message', { data: 'context' });
this.logger.info('Info message');
this.logger.warn('Warning message');
this.logger.error('Error message', error);

// Access logs (signal)
const logs = this.logger.allLogs();
const errorLogs = this.logger.errorLogs();
const recentLogs = this.logger.recentLogs();

// Clear logs
this.logger.clearLogs();
```

---

## Project Structure

```
vlang-webui-angular-rspack/
+-- src/                        # V backend source code
|   +-- main.v                  # Main application entry point
|   +-- services.v              # All backend services
|   +-- security.v              # Security utilities
|   +-- window_manager.v        # WebUI abstraction layer
|   +-- system.v                # System information
|   +-- network.v               # Network information
|   +-- process.v               # Process information
|   +-- error.v                 # Error handling
|   +-- filesystem.v            # Filesystem utilities
|   +-- security_test.v         # Security tests
|   +-- services/               # Service tests
|       +-- *_test.v
+-- frontend/                   # Angular frontend application
|   +-- src/
|   |   +-- core/               # Core services
|   |   |   +-- api.service.ts
|   |   |   +-- storage.service.ts
|   |   |   +-- logger.service.ts
|   |   |   +-- notification.service.ts
|   |   |   +-- loading.service.ts
|   |   |   +-- theme.service.ts
|   |   |   +-- clipboard.service.ts
|   |   |   +-- network-monitor.service.ts
|   |   |   +-- winbox.service.ts
|   |   +-- views/              # Components
|   |   |   +-- app.component.ts
|   |   |   +-- auth/
|   |   |   +-- sqlite/
|   |   +-- models/             # Data models
|   |   +-- types/              # TypeScript types
|   +-- dist/                   # Build output
+-- build/                      # Backend binary output
|   +-- desktop-dashboard
+-- docs/                       # Documentation
|   +-- 00-README.md
|   +-- 01-ARCHITECTURE.md
|   +-- 02-DEPENDENCY_INJECTION.md
|   +-- 03-ERROR_HANDLING.md
|   +-- 04-API_REFERENCE.md
|   +-- 05-COMMUNICATION.md
|   +-- 05-SERVICES_GUIDE.md
|   +-- 06-DEPLOYMENT.md
|   +-- 07-TESTING.md
+-- audit/                      # Audit documentation
|   +-- README.md
|   +-- 01-security-audit.md
|   +-- 02-code-quality-audit.md
|   +-- 03-architecture-audit.md
|   +-- 04-remediation-plan.md
|   +-- closed/                 # Resolved findings
+-- v.mod                       # V module configuration
+-- run.sh                      # Build and run automation
+-- build.config.sh             # Build configuration
+-- README.md                   # This file
+-- BUILD_PIPELINE.md           # Build system documentation
+-- BUILD_OUTPUT_STRUCTURE.md   # Build output documentation
+-- TESTING_STRATEGY.md         # Testing strategy
+-- TESTING_EVALUATION_REPORT.md # Testing evaluation
+-- ANGULAR_MODERNIZATION_PLAN.md # Angular modernization
+-- ANGULAR_MODERN_FEATURES.md  # Angular features
```

---

## Commands

| Command | Description |
|---------|-------------|
| ./run.sh | Start development mode |
| ./run.sh dev | Development mode (same as above) |
| ./run.sh build | Full production build |
| ./run.sh build:fe | Build frontend only |
| ./run.sh build:be | Build backend only |
| ./run.sh run | Run existing build |
| ./run.sh clean | Remove build artifacts |
| ./run.sh help | Display help |

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
v test src/security_test.v
v test src/services/*_test.v
```

---

## Testing

### Backend Tests

```bash
# Run all backend tests
v test src/

# Run specific test
v test src/security_test.v

# Run service tests
v test src/services/*_test.v
```

### Frontend Tests

```bash
cd frontend

# Run all tests
bun test

# Run specific test
bun test src/core/api.service.test.ts

# Run with coverage
bun test --coverage

# Watch mode
bun test --watch
```

### Test Coverage

| Category | Files | Tests | Coverage |
|----------|-------|-------|----------|
| Backend Unit | 13 | 160+ | 83% |
| Frontend Unit | 16 | 290+ | 85% |
| Integration | 2 | 17 | 75% |
| Security | 1 | 11 | 90% |
| **Total** | **32** | **478+** | **85%** |

---

## Audit Results

### Summary

All 15 audit findings have been resolved:

| Category | Total | Closed | Open |
|----------|-------|--------|------|
| Security | 7 | 7 | 0 |
| Code Quality | 3 | 3 | 0 |
| Architecture | 5 | 5 | 0 |
| **Total** | **15** | **15** | **0** |

### Security Findings (SEC-001 to SEC-007)

| ID | Issue | Severity | Status |
|--------|----------|----------|--------|
| SEC-001 | Plaintext passwords | Critical | Resolved |
| SEC-002 | Predictable tokens | Critical | Resolved |
| SEC-003 | SQL injection | Critical | Resolved |
| SEC-004 | No input validation | High | Resolved |
| SEC-005 | Unsafe type casting | High | Resolved |
| SEC-006 | No CSRF protection | High | Resolved |
| SEC-007 | No rate limiting | High | Resolved |

### Code Quality Findings (CQ-001 to CQ-015)

| ID | Issue | Severity | Status |
|--------|----------|----------|--------|
| CQ-001 | Inconsistent error handling | Medium | Resolved |
| CQ-009 | God files | Medium | Resolved |
| CQ-015 | No integration tests | Medium | Resolved |

### Architecture Findings (ARC-001 to ARC-005)

| ID | Issue | Severity | Status |
|--------|----------|----------|--------|
| ARC-001 | WebUI coupling | High | Resolved |
| ARC-002 | No graceful shutdown | Medium | Resolved |
| ARC-003 | Singleton overuse | Medium | Resolved |
| ARC-004 | No circuit breaker | Medium | Resolved |
| ARC-005 | Missing observability | Medium | Resolved |

### Compliance Status

| Standard | Before | After |
|----------|--------|-------|
| PCI-DSS | Fail | Pass |
| GDPR | Fail | Pass |
| SOC 2 | Fail | Pass |
| OWASP Top 10 | 6 violations | 0 violations |

See [audit/README.md](audit/README.md) for complete audit documentation.

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/00-README.md](docs/00-README.md) | Documentation index |
| [docs/01-ARCHITECTURE.md](docs/01-ARCHITECTURE.md) | System architecture and design patterns |
| [docs/02-DEPENDENCY_INJECTION.md](docs/02-DEPENDENCY_INJECTION.md) | DI systems for backend and frontend |
| [docs/03-ERROR_HANDLING.md](docs/03-ERROR_HANDLING.md) | Error handling patterns and guides |
| [docs/04-API_REFERENCE.md](docs/04-API_REFERENCE.md) | Complete API documentation |
| [docs/05-COMMUNICATION.md](docs/05-COMMUNICATION.md) | Backend-frontend communication protocols |
| [docs/05-SERVICES_GUIDE.md](docs/05-SERVICES_GUIDE.md) | Services implementation guide |
| [docs/06-DEPLOYMENT.md](docs/06-DEPLOYMENT.md) | Deployment guide |
| [docs/07-TESTING.md](docs/07-TESTING.md) | Testing guide |
| [audit/README.md](audit/README.md) | Security and code quality audit |
| [BUILD_PIPELINE.md](BUILD_PIPELINE.md) | Build system documentation |
| [BUILD_OUTPUT_STRUCTURE.md](BUILD_OUTPUT_STRUCTURE.md) | Build output structure |
| [TESTING_STRATEGY.md](TESTING_STRATEGY.md) | Testing strategy |

---

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

---

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

### Database issues

See [SQLITE_SETUP.md](SQLITE_SETUP.md) for database troubleshooting.

### Build issues

```bash
# Clean and rebuild
./run.sh clean
./run.sh build --no-cache
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

---

## License

MIT License

---

## Acknowledgments

- WebUI Library (https://webui.me)
- V Language (https://vlang.io)
- Angular (https://angular.dev)
- Rspack (https://rspack.rs)
- WinBox.js (https://winbox.kodinger.com)

---

*Last Updated: 2026-03-14*
