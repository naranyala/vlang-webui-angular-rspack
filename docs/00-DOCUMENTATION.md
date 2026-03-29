# Desktop Dashboard Documentation

Welcome to the Desktop Dashboard documentation. This is your comprehensive guide to understanding, developing, and deploying the application.

---

## Navigation

### First Menu Group: Core Documentation

| Document | File | Description |
|----------|------|-------------|
| Documentation Index | INDEX.md | Overview and quick links |
| Getting Started | 00-GETTING_STARTED.md | Installation and setup guide |
| Architecture | 01-ARCHITECTURE.md | System design and components |
| CRUD Demos | 01-CRUD-DEMOS.md | SQLite and DuckDB examples |
| API Reference | 02-API_REFERENCE.md | Complete API documentation |
| Security | 03-SECURITY.md | Security features |
| Development | 04-DEVELOPMENT.md | Developer guide |
| Deployment | 05-DEPLOYMENT.md | Build and deployment |

### Second Menu Group: CRUD Demos

| Document | Section | Description |
|----------|---------|-------------|
| SQLite Demo | 01-CRUD-DEMOS.md#sqlite-demo | SQLite CRUD operations |
| DuckDB Demo | 01-CRUD-DEMOS.md#duckdb-demo | DuckDB CRUD operations |
| Testing Checklist | 01-CRUD-DEMOS.md#testing-checklist | Test coverage checklist |

---

## Quick Reference

### Commands

```bash
# Start development
./run.sh dev

# Build production
./run.sh build

# Run tests
./run.sh test

# Clean build
./run.sh clean
```

### API Endpoints

| Category | Endpoints |
|----------|-----------|
| Users | getUsers, createUser, updateUser, deleteUser |
| Products | getProducts, createProduct, updateProduct, deleteProduct |
| Orders | getOrders, createOrder, updateOrder, deleteOrder |
| DevTools | getStats, getLogs, getErrors, getMetrics |

### Configuration

```bash
# Copy environment template
cp .env.example .env

# Key settings
APP_ENV=development
SERVER_PORT=8080
DB_PATH=data/duckdb_demo.json
LOG_LEVEL=info
```

---

## Documentation Overview

### Getting Started (00-GETTING_STARTED.md)

Complete guide for new developers:
- Prerequisites and installation
- Quick start guide
- Configuration options
- Project structure
- Development workflow
- Troubleshooting

### Architecture (01-ARCHITECTURE.md)

System design documentation:
- System overview
- Backend architecture
- Frontend architecture
- Communication layer
- Data flow diagrams
- Security architecture

### CRUD Demos (01-CRUD-DEMOS.md)

Hands-on CRUD implementation guides:
- SQLite setup and operations
- DuckDB setup and operations
- Common patterns
- Testing checklists
- Best practices

### API Reference (02-API_REFERENCE.md)

Complete API documentation:
- Request/response formats
- All endpoint documentation
- Error codes
- Rate limiting
- Examples

### Security (03-SECURITY.md)

Security features documentation:
- Password hashing
- Token generation
- CSRF protection
- Rate limiting
- Input validation

### Development (04-DEVELOPMENT.md)

Developer guide:
- Code style
- Testing
- Debugging
- Common tasks
- Pre-commit hooks

### Deployment (05-DEPLOYMENT.md)

Deployment instructions:
- Production build
- Configuration
- Docker deployment
- Environment variables

---

## For Different Audiences

### New Developers

Start here:
1. [Getting Started](00-GETTING_STARTED.md)
2. [Architecture Overview](01-ARCHITECTURE.md)
3. [Code Style Guide](04-DEVELOPMENT.md#code-style)

### API Consumers

Start here:
1. [API Reference](02-API_REFERENCE.md)
2. [Quick Start](00-GETTING_STARTED.md#quick-start)

### Contributors

Start here:
1. [Development Guide](04-DEVELOPMENT.md)
2. [Testing Guide](04-DEVELOPMENT.md#testing)
3. [CRUD Demos](01-CRUD-DEMOS.md)

### DevOps

Start here:
1. [Deployment Guide](05-DEPLOYMENT.md)
2. [Configuration](00-GETTING_STARTED.md#configuration)
3. [Security](03-SECURITY.md)

---

## Support

### Getting Help

1. Search this documentation
2. Check [Troubleshooting](00-GETTING_STARTED.md#troubleshooting)
3. Review [CHANGELOG.md](../CHANGELOG.md)
4. Open a GitHub issue

### Reporting Issues

When reporting issues, include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, versions)
- Error messages/logs

---

## Version Information

| Component | Version |
|-----------|---------|
| V Language | 0.5.1+ |
| Angular | 21.1.5 |
| Bun | 1.3.11 |
| Rspack | 1.7.6 |

---

## Contributing to Documentation

To contribute to documentation:

1. Follow the markdown style guide
2. Use clear, concise language
3. Include code examples where relevant
4. Update the table of contents
5. Test any code snippets
6. Submit a pull request

---

*Last Updated: 2026-03-29*
