# Documentation Index

Welcome to the Desktop Dashboard documentation. This guide provides comprehensive information about the application architecture, services, APIs, and development practices.

## Documentation Structure

### Core Documentation

| Document | Description |
|----------|-------------|
| [01-ARCHITECTURE.md](01-ARCHITECTURE.md) | System architecture and design patterns |
| [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) | DI systems for backend and frontend |
| [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) | Error handling patterns and guides |
| [04-API_REFERENCE.md](04-API_REFERENCE.md) | Complete API documentation |
| [05-COMMUNICATION.md](05-COMMUNICATION.md) | Backend-frontend communication protocols |
| [05-SERVICES_GUIDE.md](05-SERVICES_GUIDE.md) | Services implementation guide |
| [06-DEPLOYMENT.md](06-DEPLOYMENT.md) | Deployment guide |
| [07-TESTING.md](07-TESTING.md) | Testing guide |

### Specialized Documentation

| Document | Description |
|----------|-------------|
| [ANGULAR_DI_FOR_V.md](ANGULAR_DI_FOR_V.md) | Angular-inspired DI for V backend |
| [MULTI_CHANNEL_COMMUNICATION.md](MULTI_CHANNEL_COMMUNICATION.md) | Multi-channel communication patterns |

### Project Documentation

| Document | Description |
|----------|-------------|
| [../README.md](../README.md) | Project overview and quick start |
| [../SQLITE_SETUP.md](../SQLITE_SETUP.md) | Database setup guide |
| [../BUILD_PIPELINE.md](../BUILD_PIPELINE.md) | Build system documentation |
| [../BUILD_OUTPUT_STRUCTURE.md](../BUILD_OUTPUT_STRUCTURE.md) | Build output structure |
| [../OPTIMIZATION_REPORT.md](../OPTIMIZATION_REPORT.md) | Optimization report |
| [../TESTING_STRATEGY.md](../TESTING_STRATEGY.md) | Testing strategy |
| [../TESTING_EVALUATION_REPORT.md](../TESTING_EVALUATION_REPORT.md) | Testing evaluation |
| [../FIXES_APPLIED.md](../FIXES_APPLIED.md) | Applied fixes report |
| [../CODEBASE_INCONSISTENCY_REPORT.md](../CODEBASE_INCONSISTENCY_REPORT.md) | Codebase analysis |
| [../audit/README.md](../audit/README.md) | Security and code quality audit |

---

## Quick Start

### For New Developers

1. Read [../README.md](../README.md) for project overview
2. Read [01-ARCHITECTURE.md](01-ARCHITECTURE.md) for system design
3. Read [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) for service patterns
4. Read [05-COMMUNICATION.md](05-COMMUNICATION.md) for communication patterns
5. Read [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) for error patterns

### For Backend Developers

1. Read [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) - Backend DI patterns
2. Read [ANGULAR_DI_FOR_V.md](ANGULAR_DI_FOR_V.md) - Angular-inspired DI
3. Read [05-SERVICES_GUIDE.md](05-SERVICES_GUIDE.md) - Service implementation
4. Read [04-API_REFERENCE.md](04-API_REFERENCE.md) - API endpoints

### For Frontend Developers

1. Read [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) - Frontend DI patterns
2. Read [05-COMMUNICATION.md](05-COMMUNICATION.md) - Backend communication
3. Read [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) - Error handling
4. Read [MULTI_CHANNEL_COMMUNICATION.md](MULTI_CHANNEL_COMMUNICATION.md) - Communication channels

### For DevOps

1. Read [06-DEPLOYMENT.md](06-DEPLOYMENT.md) - Deployment procedures
2. Read [../BUILD_PIPELINE.md](../BUILD_PIPELINE.md) - Build system
3. Read [07-TESTING.md](07-TESTING.md) - Testing procedures
4. Read [../BUILD_OUTPUT_STRUCTURE.md](../BUILD_OUTPUT_STRUCTURE.md) - Build outputs

---

## Project Overview

Desktop Dashboard is a system monitoring application with:

- **V Language Backend** - Native Linux system access with modular architecture
- **Angular Frontend** - Modern reactive UI with signal-based state management
- **WebUI Integration** - Native window management
- **Dependency Injection** - Angular-inspired DI on both tiers
- **Error Handling** - Structured error handling throughout
- **Multi-Channel Communication** - WebUI Bridge, Event Bus, Shared State, Message Queue, Broadcast

### Architecture Highlights

```
+-----------------------------------------------------------------+
|                         Frontend (Angular)                       |
|  +-------------+  +-------------+  +-------------------------+  |
|  |   Angular   |  |   WinBox    |  |    Service Layer        |  |
|  |  Components |  |   Windows   |  |    (Signal-based)       |  |
|  +-------------+  +-------------+  +-------------------------+  |
|         |                |                    |                  |
|         |          WebSocket              EventBus               |
|         |                |                    |                  |
|         +----------------+--------------------+                  |
+--------------------------+---------------------------------------+
                           |
                           | WebUI Bridge
                           |
+--------------------------+---------------------------------------+
|                         Backend (V Language)                      |
|                          |                                        |
|  +-------------+  +------+-------+  +-------------------------+  |
|  |   WebUI     |  |   Services   |  |    Modular Structure    |  |
|  |   Server    |  |   (Direct)   |  |    (errors/, security/) |  |
|  +-------------+  +--------------+  +-------------------------+  |
|                          |                                        |
|                   Linux Sysfs / Procfs                            |
+-------------------------------------------------------------------+
```

---

## Communication Protocols

The application uses three communication approaches:

### 1. WebUI Bridge (Primary)

- **Type:** Synchronous RPC
- **Use Case:** Desktop window management, API calls
- **Protocol:** Custom RPC over WebUI library
- **Latency:** Less than 10ms (in-process)

### 2. Event Bus (Pub/Sub)

- **Type:** Asynchronous Events
- **Use Case:** Cross-component communication
- **Pattern:** Publish/Subscribe
- **Scope:** Frontend and backend

### 3. Additional Channels

See [MULTI_CHANNEL_COMMUNICATION.md](MULTI_CHANNEL_COMMUNICATION.md) for:
- Shared State channel
- Message Queue channel
- Broadcast channel

---

## Development Workflow

### Setting Up Development Environment

```bash
# Clone repository
git clone <repository-url>
cd vlang-webui-angular-rspack

# Install backend dependencies (V modules)
v install

# Install frontend dependencies
cd frontend
bun install

# Run development mode
cd ..
./run.sh
```

### Making Changes

1. Make changes to source code
2. Run tests: `./run.sh test`
3. Build: `./run.sh build`
4. Verify: Check build outputs

### Commit Guidelines

1. Write clear commit messages
2. Reference issue numbers
3. Include test coverage
4. Update documentation if needed

---

## Module Structure

### Backend Modules

```
src/
├── errors/                 # Error handling module
│   ├── types.v            # Error types and enums
│   ├── errors.v           # Error creation functions
│   ├── utils.v            # Error utilities
│   └── index.v            # Module index
├── security/              # Security module
│   ├── password.v         # Password hashing
│   ├── token.v            # Token generation
│   ├── validation.v       # Input validation
│   └── index.v            # Module index
├── di.v                   # Dependency injection
├── main.v                 # Application entry
└── ...
```

### Frontend Modules

```
frontend/src/
├── core/                  # Core services
│   ├── api.service.ts     # Backend communication
│   ├── logger.service.ts  # Logging
│   ├── storage.service.ts # Storage
│   └── ...
├── views/                 # Components
│   ├── app.component.ts   # Main component
│   ├── auth/              # Auth components
│   └── sqlite/            # SQLite components
├── types/                 # TypeScript types
└── models/                # Data models
```

---

## Key Concepts

### Dependency Injection

The application uses dependency injection on both tiers:

**Backend (V):**
- Direct composition pattern
- Angular-inspired injector
- Service scopes (singleton, transient, scoped)

**Frontend (Angular):**
- Built-in Angular DI
- Signal-based services
- providedIn: 'root' pattern

See [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) for details.

### Error Handling

Structured error handling throughout:

- Error codes for categorization
- Error severity levels
- Error context and metadata
- Error recovery patterns

See [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) for details.

### Communication

Multiple communication channels:

- WebUI Bridge for RPC calls
- Event Bus for pub/sub
- Shared State for configuration
- Message Queue for async tasks
- Broadcast for one-to-many

See [MULTI_CHANNEL_COMMUNICATION.md](MULTI_CHANNEL_COMMUNICATION.md) for details.

---

## Testing

### Running Tests

```bash
# All tests
./run.sh test

# Backend tests
v test src/

# Frontend tests
cd frontend && bun test
```

### Test Coverage

| Category | Files | Tests | Coverage |
|----------|-------|-------|----------|
| Backend Unit | 13 | 160+ | 83% |
| Frontend Unit | 16 | 290+ | 85% |
| Integration | 2 | 17 | 75% |
| Security | 1 | 11 | 90% |

See [07-TESTING.md](07-TESTING.md) for testing guide.

---

## Deployment

### Build Outputs

```
build/
└── desktop-dashboard    # Backend binary (749K)

frontend/dist/browser/
├── index.html           # Entry point
├── main.*.js           # Application code
├── vendor.*.js         # Vendor code
└── ...                 # Assets
```

### Deployment Steps

1. Build: `./run.sh build`
2. Verify outputs
3. Deploy binary and frontend dist
4. Configure environment
5. Start application

See [06-DEPLOYMENT.md](06-DEPLOYMENT.md) for deployment guide.

---

## Troubleshooting

### Common Issues

**Frontend dist not found:**
```bash
./run.sh build:fe
```

**Backend build fails:**
```bash
v version
./run.sh build:be
```

**Window fails to open:**
```bash
ldd ./build/desktop-dashboard | grep -E 'gtk|webkit'
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

### Getting Help

1. Check documentation in docs/
2. Review audit reports in audit/
3. Check build logs in terminal output
4. Review error messages

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-03-16 | Modular architecture, optimization |
| 1.2 | 2026-03-14 | Communication protocols |
| 1.1 | 2026-03-14 | Security audit and fixes |
| 1.0 | 2026-03-14 | Initial release |

---

## Contributing

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

### Code Style

- Follow existing code patterns
- Write tests for new features
- Update documentation
- Use meaningful commit messages

---

Last Updated: 2026-03-16
