# Documentation Index

Welcome to the Desktop Dashboard documentation. This index provides an organized guide to all documentation files.

## Documentation Structure

### Core Documentation

| # | Document | Description |
|---|----------|-------------|
| 01 | [ARCHITECTURE.md](01-ARCHITECTURE.md) | System architecture and design patterns |
| 02 | [DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) | DI systems for backend and frontend |
| 03 | [ERROR_HANDLING.md](03-ERROR_HANDLING.md) | Error handling patterns and guides |
| 04 | [API_REFERENCE.md](04-API_REFERENCE.md) | Complete API documentation |
| 05 | [SERVICES_GUIDE.md](05-SERVICES_GUIDE.md) | Services usage guide |
| 06 | [DEPLOYMENT.md](06-DEPLOYMENT.md) | Build and deployment instructions |
| 07 | [TESTING.md](07-TESTING.md) | Testing infrastructure and guides |

### Quick Links

- **[Main README](../README.md)** - Project overview and quick start
- **[Backend Source](../src/)** - V language backend code
- **[Frontend Source](../frontend/src/)** - Angular frontend code

## Project Overview

Desktop Dashboard is a system monitoring application with:

- **V Language Backend** - Native Linux system access
- **Angular Frontend** - Modern reactive UI
- **WebUI Integration** - Native window management
- **Dependency Injection** - Full DI on both backend and frontend
- **Error Handling** - "Errors as values" pattern throughout

## Architecture Highlights

### Backend Services

```
src/
├── di.v                          # DI Container
├── result.v                      # Result type for errors
├── error.v                       # Error definitions
├── services/
│   ├── interfaces.v              # Service interfaces
│   ├── core_services.v           # Core services (Config, Cache, DB, HTTP)
│   ├── additional_services.v     # Additional services (Logger, Metrics, etc.)
│   └── registry.v                # Service registry
├── system.v                      # System information
├── network.v                     # Network monitoring
├── process.v                     # Process management
└── filesystem.v                  # File operations
```

### Frontend Services

```
frontend/src/core/
├── storage.service.ts            # Storage abstraction
├── http.service.ts               # HTTP client
├── notification.service.ts       # Toast notifications
├── loading.service.ts            # Loading management
├── theme.service.ts              # Theme switching
├── clipboard.service.ts          # Clipboard operations
├── retry.service.ts              # Retry logic
├── network-monitor.service.ts    # Network monitoring
├── app-services.facade.ts        # Service facade
└── index.ts                      # Exports
```

## Getting Started

1. Read [ARCHITECTURE.md](01-ARCHITECTURE.md) for system overview
2. Read [DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) for service patterns
3. Read [ERROR_HANDLING.md](03-ERROR_HANDLING.md) for error patterns
4. Read [DEPLOYMENT.md](06-DEPLOYMENT.md) for build instructions

## Documentation Maintenance

When adding new features:
1. Update relevant documentation files
2. Keep code examples in sync with implementation
3. Update the API reference for new endpoints
4. Add tests and document them in TESTING.md
