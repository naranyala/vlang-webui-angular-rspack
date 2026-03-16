# Documentation Index

Quick navigation: [Architecture](01-ARCHITECTURE.md) | [API](04-API_REFERENCE.md) | [Deployment](06-DEPLOYMENT.md) | [Testing](07-TESTING.md)

---

## Core Documentation

| Document | Description |
|----------|-------------|
| [01-ARCHITECTURE.md](01-ARCHITECTURE.md) | System architecture |
| [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) | DI patterns |
| [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) | Error handling |
| [04-API_REFERENCE.md](04-API_REFERENCE.md) | API documentation |
| [05-COMMUNICATION.md](05-COMMUNICATION.md) | Backend-frontend communication |
| [06-DEPLOYMENT.md](06-DEPLOYMENT.md) | Deployment guide |
| [07-TESTING.md](07-TESTING.md) | Testing guide |

## Specialized Guides

| Document | Description |
|----------|-------------|
| [ANGULAR_DI_FOR_V.md](ANGULAR_DI_FOR_V.md) | Angular DI for V backend |
| [MULTI_CHANNEL_COMMUNICATION.md](MULTI_CHANNEL_COMMUNICATION.md) | Communication patterns |
| [DEVTOOLS_SERVICES.md](DEVTOOLS_SERVICES.md) | DevTools guide |

## UI & Layouts

| Document | Description |
|----------|-------------|
| [ui-layouts/MACOS_COLUMN_LAYOUT.md](ui-layouts/MACOS_COLUMN_LAYOUT.md) | macOS Finder layout |

## Setup

| Document | Description |
|----------|-------------|
| [setup/SQLITE_SETUP.md](setup/SQLITE_SETUP.md) | Database setup |

## Build & Reference

| Document | Description |
|----------|-------------|
| [build/BUILD_PIPELINE.md](build/BUILD_PIPELINE.md) | Build system |

## Testing Reports

| Document | Description |
|----------|-------------|
| [testing/TESTING_IMPROVEMENT_REPORT.md](testing/TESTING_IMPROVEMENT_REPORT.md) | Latest testing analysis |
| [testing/TEST_ANALYSIS_AND_IMPROVEMENT_PLAN.md](testing/TEST_ANALYSIS_AND_IMPROVEMENT_PLAN.md) | Improvement plan |

## Archive

Historical documents in [docs/archive/](archive/).

---

## Quick Start

### New Developers

1. [Architecture](01-ARCHITECTURE.md) - System design
2. [Dependency Injection](02-DEPENDENCY_INJECTION.md) - Service patterns
3. [Communication](05-COMMUNICATION.md) - Backend-frontend communication

### Backend Developers

1. [Dependency Injection](02-DEPENDENCY_INJECTION.md) - V DI patterns
2. [Services Guide](05-SERVICES_GUIDE.md) - Service implementation
3. [API Reference](04-API_REFERENCE.md) - API endpoints

### Frontend Developers

1. [Dependency Injection](02-DEPENDENCY_INJECTION.md) - Angular DI
2. [Communication](05-COMMUNICATION.md) - Backend communication
3. [Error Handling](03-ERROR_HANDLING.md) - Error patterns

### DevOps

1. [Deployment](06-DEPLOYMENT.md) - Deployment procedures
2. [Build Pipeline](build/BUILD_PIPELINE.md) - Build system
3. [Testing](07-TESTING.md) - Testing procedures

---

## Project Overview

Desktop Dashboard is a system monitoring application:

- **V Backend** - Native Linux access, modular architecture
- **Angular Frontend** - Reactive UI with signals
- **WebUI** - Native window management
- **SQLite** - Persistent storage
- **Security** - Password hashing, validation, rate limiting

### Architecture

```
+-----------------+
|   Frontend      |
|   (Angular)     |
+--------+--------+
         | WebUI
+--------+--------+
|   Backend       |
|   (V Language)  |
+--------+--------+
         |
+--------+--------+
|   Linux APIs    |
+-----------------+
```

---

## Testing

```bash
./run.sh test         # All tests
v test src/           # Backend
cd frontend && bun test  # Frontend
```

Coverage: 87% (210+ tests)

See [testing/TESTING_IMPROVEMENT_REPORT.md](testing/TESTING_IMPROVEMENT_REPORT.md) for details.

---

## Security

All security audits passed (15/15 issues resolved).

See [audit/README.md](../audit/README.md) for details.

---

Last Updated: 2026-03-16
