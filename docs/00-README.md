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
| 05 | [COMMUNICATION.md](05-COMMUNICATION.md) | Backend-frontend communication protocols |
| 05 | [SERVICES_GUIDE.md](05-SERVICES_GUIDE.md) | Services implementation guide |
| 06 | [DEPLOYMENT.md](06-DEPLOYMENT.md) | Deployment guide |
| 07 | [TESTING.md](07-TESTING.md) | Testing guide |

### Additional Documentation

| Document | Description |
|----------|-------------|
| [../README.md](../README.md) | Project overview and quick start |
| [../SQLITE_SETUP.md](../SQLITE_SETUP.md) | Database setup and persistence guide |
| [../audit/README.md](../audit/README.md) | Security and code quality audit |
| [../BUILD_PIPELINE.md](../BUILD_PIPELINE.md) | Build system documentation |
| [../BUILD_OUTPUT_STRUCTURE.md](../BUILD_OUTPUT_STRUCTURE.md) | Build output structure |
| [../TESTING_STRATEGY.md](../TESTING_STRATEGY.md) | Testing strategy |

### Quick Links

- [Backend Source](../src/) - V language backend code
- [Frontend Source](../frontend/src/) - Angular frontend code
- [Audit Findings](../audit/) - Resolved and open findings

---

## Project Overview

Desktop Dashboard is a system monitoring application with:

- **V Language Backend** - Native Linux system access
- **Angular Frontend** - Modern reactive UI
- **WebUI Integration** - Native window management
- **Dependency Injection** - Direct composition pattern
- **Error Handling** - Structured error handling throughout
- **Multiple Communication Protocols** - WebUI Bridge, HTTP, Events

---

## Communication Protocols

The application supports three communication approaches:

### 1. WebUI Bridge (Primary)

- **Type:** Synchronous RPC
- **Use Case:** Desktop window management, API calls
- **Protocol:** Custom RPC over WebUI library
- **Latency:** Less than 10ms (in-process)

### 2. HTTP/Fetch (Secondary)

- **Type:** RESTful HTTP
- **Use Case:** Future web deployment, external APIs
- **Protocol:** HTTP/1.1 or HTTP/2
- **Features:** Caching, retry, timeout

### 3. Event Bus (Pub/Sub)

- **Type:** Asynchronous Events
- **Use Case:** Cross-component communication
- **Pattern:** Publish/Subscribe
- **Scope:** Frontend only

See [COMMUNICATION.md](05-COMMUNICATION.md) for detailed documentation.

---

## Getting Started

1. Read [../README.md](../README.md) for project overview
2. Read [01-ARCHITECTURE.md](01-ARCHITECTURE.md) for system design
3. Read [05-COMMUNICATION.md](05-COMMUNICATION.md) for communication patterns
4. Read [02-DEPENDENCY_INJECTION.md](02-DEPENDENCY_INJECTION.md) for service patterns
5. Read [03-ERROR_HANDLING.md](03-ERROR_HANDLING.md) for error patterns
6. Read [SQLITE_SETUP.md](../SQLITE_SETUP.md) for database setup

---

## Documentation Maintenance

When adding new features:

1. Update relevant documentation files
2. Keep code examples in sync with implementation
3. Update the API reference for new endpoints
4. Add tests and document them
5. Update communication guide if new protocols added

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-03-14 | Complete documentation rewrite |
| 1.2 | 2026-03-14 | Added communication protocols documentation |
| 1.1 | 2026-03-14 | Security audit and fixes |
| 1.0 | 2026-03-14 | Initial documentation |

---

*Last Updated: 2026-03-14*
