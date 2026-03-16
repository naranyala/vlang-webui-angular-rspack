# Desktop Dashboard

A system monitoring desktop application built with V language backend and Angular frontend, using WebUI for native window management.

## Quick Start

```bash
# Clone and enter the project directory
cd vlang-webui-angular-rspack

# Development mode (rebuilds frontend and runs app)
./run.sh

# Or build for production
./run.sh build
```

## Overview

Desktop Dashboard provides real-time monitoring of system resources including CPU, memory, disk, network, and processes through a modern web-based interface wrapped in a native window.

### Key Features

- Real-time system monitoring (CPU, Memory, Disk, Network)
- Process management and statistics
- Secure authentication (password hashing, input validation)
- SQLite/JSON persistent storage with CRUD operations
- In-memory caching with TTL support
- Modern Angular frontend with WinBox.js windows
- Rate limiting and input validation
- Multi-channel communication (WebUI Bridge, Event Bus, Shared State)

## Documentation

For detailed information, see the [docs](docs/) directory:

- [Documentation Index](docs/00-README.md) - Complete documentation guide
- [Architecture](docs/01-ARCHITECTURE.md) - System architecture and design
- [Dependency Injection](docs/02-DEPENDENCY_INJECTION.md) - DI patterns
- [Error Handling](docs/03-ERROR_HANDLING.md) - Error patterns
- [API Reference](docs/04-API_REFERENCE.md) - API documentation
- [Communication](docs/05-COMMUNICATION.md) - Backend-frontend communication
- [Services Guide](docs/05-SERVICES_GUIDE.md) - Services implementation
- [Deployment](docs/06-DEPLOYMENT.md) - Deployment guide
- [Testing](docs/07-TESTING.md) - Testing guide
- [Angular DI for V](docs/ANGULAR_DI_FOR_V.md) - Angular-inspired DI
- [Multi-Channel Communication](docs/MULTI_CHANNEL_COMMUNICATION.md) - Communication patterns

## Project Structure

```
vlang-webui-angular-rspack/
├── src/                        # V backend source
│   ├── main.v                  # Application entry
│   ├── errors/                 # Error handling module
│   ├── security/               # Security module
│   ├── di.v                    # Dependency injection
│   └── ...
├── frontend/                   # Angular frontend
│   ├── src/
│   │   ├── core/               # Core services
│   │   ├── views/              # Components
│   │   └── types/              # TypeScript types
│   └── dist/                   # Build output
├── build/                      # Backend binary
├── docs/                       # Documentation
├── audit/                      # Audit reports
└── run.sh                      # Build script
```

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Development mode |
| `./run.sh build` | Production build |
| `./run.sh build:fe` | Build frontend only |
| `./run.sh build:be` | Build backend only |
| `./run.sh run` | Run existing build |
| `./run.sh clean` | Clean build artifacts |
| `./run.sh help` | Show help |

### Frontend Commands

```bash
cd frontend

bun run dev          # Development server
bun run build:rspack # Production build
bun run watch        # Watch mode
bun run lint         # Lint code
bun test             # Run tests
```

### Backend Commands

```bash
# Build
v -cc gcc -o build/desktop-dashboard src/

# Run
v -cc gcc run src/

# Test
v test src/
```

## Requirements

### Development

- V Language 0.5.1+
- GCC
- Bun 1.0+
- Node.js 18+

### Runtime

- GTK3 (Linux)
- WebKit (Linux)
- Modern browser (Chrome, Edge, Firefox)

## Testing

```bash
# Backend tests
v test src/

# Frontend tests
cd frontend && bun test

# All tests
./run.sh test
```

## Audit Status

All 15 audit findings have been resolved:

- Security: 7/7 resolved
- Code Quality: 3/3 resolved
- Architecture: 5/5 resolved

See [audit/README.md](audit/README.md) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

## License

MIT License

## Acknowledgments

- WebUI Library (https://webui.me)
- V Language (https://vlang.io)
- Angular (https://angular.dev)
- Rspack (https://rspack.rs)
- WinBox.js (https://winbox.kodinger.com)

---

Last Updated: 2026-03-16
