# Desktop Dashboard

A system monitoring desktop application built with V language backend and Angular frontend, using WebUI for native window management.

## Overview

Desktop Dashboard provides real-time monitoring of system resources including CPU, memory, disk, network, and processes through a modern web-based interface wrapped in a native window.

## Quick Start

```bash
# Clone and enter the project directory
cd vlang-webui-angular-rspack

# Development mode - rebuilds frontend and runs app
./run.sh dev

# Or simply run (dev is default)
./run.sh
```

## Project Structure

```
.
├── src/                        # V backend source code
│   ├── main.v                  # Main application entry point and API handlers
│   ├── error.v                 # Error handling module with structured errors
│   ├── system.v                # System information (CPU, memory, OS)
│   ├── network.v               # Network interfaces and connection status
│   ├── process.v               # Process information and system load
│   └── filesystem.v            # File system operations and directory listing
├── v.mod                       # V module configuration
├── run.sh                      # Build and run automation script
├── frontend/                   # Angular frontend application
│   ├── src/                    # TypeScript source files
│   │   ├── core/               # Core services (error handling, retry, network)
│   │   ├── types/              # TypeScript type definitions
│   │   ├── models/             # Data models
│   │   ├── viewmodels/         # View models and state management
│   │   └── views/              # Angular components and views
│   ├── dist/                   # Build output (generated)
│   └── package.json            # Frontend dependencies
├── thirdparty/                 # Third-party libraries
│   ├── v-webui/                # WebUI V language bindings
│   └── webui/                  # WebUI C library (includes civetweb)
└── battery                     # Compiled binary (generated)
```

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Start development mode (rebuilds frontend, runs app) |
| `./run.sh dev` | Same as above - development mode |
| `./run.sh build` | Build frontend and backend for production |
| `./run.sh build:fe` | Build frontend only |
| `./run.sh build:be` | Build backend only |
| `./run.sh run` | Run existing build without rebuilding |
| `./run.sh clean` | Remove all build artifacts |
| `./run.sh help` | Display help information |

## Development Workflow

### Full Development Mode

The development mode provides a complete rebuild and run cycle:

```bash
./run.sh dev
```

This command:
1. Rebuilds the frontend with Rspack
2. Checks if backend needs rebuilding
3. Runs the application with verbose logging

### Separate Frontend Development

For frontend-only development with hot reload:

```bash
# Terminal 1 - Watch frontend for changes
cd frontend
bun run watch

# Terminal 2 - Run backend with existing dist
./run.sh run
```

### Production Build

Create a production-ready build:

```bash
# Full production build
./run.sh build

# Run the compiled binary
./battery
```

## Logging

All logs are output to the terminal (stdout). No log files are created.

### Build Log Prefixes

| Prefix | Description |
|--------|-------------|
| `[INFO]` | General information messages |
| `[SUCCESS]` | Successful operation completions |
| `[WARN]` | Warning messages |
| `[ERROR]` | Error messages |
| `[STEP]` | Build step indicators |
| `[VLANG]` or `[V]` | V compiler output |
| `[FRONTEND]` | Frontend build output |
| `[BUN]` | Bun package manager output |
| `[RSPACK]` | Rspack bundler output |
| `[DIST]` | Distribution directory listing |
| `[BINARY]` | Binary build information |
| `[APP]` | Application runtime logs |

## Frontend Commands

Navigate to the frontend directory for frontend-specific commands:

```bash
cd frontend

# Development server with hot reload
bun run dev

# Build for production with Rspack
bun run build:rspack

# Build with verbose output
bun run build:verbose

# Watch mode (rebuilds on file changes)
bun run watch

# Lint code
bun run lint

# Fix linting issues
bun run lint:fix

# Format code
bun run format

# Format and fix code
bun run format:fix

# Run tests
bun test
```

## Backend Commands

V backend commands are run from the project root:

```bash
# Build backend only
v -cc gcc -o battery src/

# Run backend without building
v -cc gcc run src/

# Run backend tests (when available)
v test src/error_test.v
```

## Requirements

### System Requirements

- **Operating System**: Linux (tested), macOS (partial), Windows (partial)
- **Memory**: Minimum 512MB RAM
- **Disk**: Minimum 100MB free space

### Development Requirements

- **V Language**: Version 0.5.1 or higher
- **GCC**: GNU Compiler Collection for C compilation
- **Bun**: JavaScript runtime and package manager (version 1.0+)
- **Node.js**: Version 18+ (for Bun compatibility)

### Runtime Requirements

- **Web Browser**: Chromium-based browser (Chrome, Edge) or Firefox
- **GTK3**: For WebUI window management (Linux)
- **WebKit**: For embedded browser (Linux)

## Technology Stack

### Backend

- **Language**: V (vlang.io)
- **Web Framework**: v-webui (WebUI bindings)
- **Embedded Server**: CivetWeb (lightweight HTTP/WebSocket server)
- **System Access**: Direct Linux sysfs and procfs access

### Frontend

- **Framework**: Angular 21
- **Build Tool**: Rspack (fast Rust-based bundler)
- **Language**: TypeScript 5.9
- **Runtime**: Bun (development), Browser (production)
- **Styling**: CSS with custom design system
- **Window Management**: WinBox.js

### Communication

- **Protocol**: WebSocket for real-time updates
- **Data Format**: JSON
- **Error Handling**: Structured error types with codes

## Architecture

### Backend Architecture

The V backend exposes API handlers through WebUI bindings:

1. **Request Flow**: Frontend JavaScript calls bound function
2. **Handler Execution**: V function executes system query
3. **Response**: JSON-encoded result returned to frontend
4. **Error Handling**: Structured error objects with codes

### Frontend Architecture

The Angular frontend uses a component-based architecture:

1. **Components**: Standalone Angular components
2. **Services**: Injectable services for shared logic
3. **View Models**: State management with signals
4. **Error Handling**: Global error service with boundaries

## Error Handling

### Backend Errors

Errors are structured with the following format:

```v
pub struct ErrorValue {
    code:      ErrorCode
    message:   string
    details:   string
    field:     string
    cause:     string
    timestamp: u64
    source:    string
    context:   map[string]string
}
```

### Frontend Errors

Frontend uses Result types for error handling:

```typescript
type Result<T, E = ErrorValue> = 
  | { ok: true; value: T } 
  | { ok: false; error: E };
```

## Testing

### Running Tests

```bash
# Frontend tests
cd frontend
bun test

# Backend tests (when V compiler is configured)
v test src/error_test.v
v test src/system_test.v
v test src/network_test.v
```

### Test Coverage

- **Error Types**: Complete coverage of error codes and utilities
- **Retry Service**: Exponential backoff and circuit breaker tests
- **Error Interceptor**: WebUI and HTTP call interception tests
- **Backend Modules**: System, network, and error module tests

## Configuration

### Environment Variables

No environment variables are required for basic operation.

### Build Configuration

Frontend build configuration is in `frontend/rspack.config.js`.

Backend build flags are in `thirdparty/v-webui/src/lib.c.v`.

## Troubleshooting

### Common Issues

**Frontend dist not found**
```bash
# Rebuild frontend
./run.sh build:fe
```

**Backend binary not created**
```bash
# Check V installation
v version

# Rebuild backend
./run.sh build:be
```

**Window fails to open**
```bash
# Check GTK/WebKit installation
ldd ./battery | grep -E 'gtk|webkit'

# Install dependencies (Ubuntu/Debian)
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

**Port already in use**
```bash
# Find and kill process on port
lsof -ti:8080 | xargs kill -9
```

## Performance

### Build Times

- **Frontend (Rspack)**: 2-4 seconds
- **Backend (V)**: 1-2 seconds
- **Full Build**: 5-8 seconds

### Runtime Performance

- **Memory Usage**: 20-50MB (frontend)
- **CPU Usage**: <1% (idle), <5% (active)
- **Startup Time**: <2 seconds

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests
5. Submit pull request

## License

MIT License - See LICENSE file for details.

## Acknowledgments

- WebUI Library (https://webui.me)
- V Language (https://vlang.io)
- Angular (https://angular.dev)
- Rspack (https://rspack.rs)
- CivetWeb (https://github.com/civetweb/civetweb)
