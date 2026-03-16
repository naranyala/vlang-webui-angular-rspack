# Desktop Dashboard

A system monitoring application with V backend and Angular frontend.

## Quick Start

```bash
./run.sh              # Development mode
./run.sh build        # Production build
```

## Features

- System monitoring (CPU, Memory, Disk, Network)
- Process management
- SQLite database with CRUD operations
- Secure authentication with password hashing
- Modern Angular UI with WinBox.js windows

## Documentation

See [docs/](docs/) for detailed guides:

- [Getting Started](docs/00-README.md)
- [Architecture](docs/01-ARCHITECTURE.md)
- [API Reference](docs/04-API_REFERENCE.md)
- [Deployment](docs/06-DEPLOYMENT.md)
- [Testing](docs/testing/TESTING_IMPROVEMENT_REPORT.md)

## Requirements

- V Language 0.5.1+
- Bun 1.0+
- GCC
- GTK3 + WebKit (Linux)

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Start development |
| `./run.sh build` | Build production |
| `./run.sh test` | Run tests |
| `./run.sh clean` | Clean build |

## Testing

```bash
./run.sh test         # All tests
v test src/           # Backend
cd frontend && bun test  # Frontend
```

Coverage: 87% (210+ tests)

## Security

All security audits passed. See [audit/README.md](audit/README.md) for details.

## License

MIT

---

Last Updated: 2026-03-16
