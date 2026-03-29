# Deployment Guide

Build and deployment instructions for Desktop Dashboard.

## Quick Start

```bash
# Development mode
./run.sh dev

# Production build
./run.sh build
```

## Build Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Development mode (rebuild + run) |
| `./run.sh dev` | Same as above |
| `./run.sh build` | Full production build |
| `./run.sh build:fe` | Frontend only |
| `./run.sh build:be` | Backend only |
| `./run.sh run` | Run existing build |
| `./run.sh clean` | Clean build artifacts |

## Build Process

### Frontend Build

```bash
cd frontend

# Install dependencies
bun install

# Development build
bun run build:rspack

# Production build (optimized)
bun run build:verbose

# Watch mode
bun run watch
```

**Output:**
- `frontend/dist/browser/main.[hash].js` - Application bundle
- `frontend/dist/browser/main.[hash].js.map` - Source maps
- `frontend/dist/browser/index.html` - Entry point

### Backend Build

```bash
# Build
v -cc gcc -o desktop-dashboard src/

# Run without building
v -cc gcc run src/

# With optimizations
v -prod -cc gcc -o desktop-dashboard src/
```

## Development Workflow

### Full Development

```bash
./run.sh dev
```

This:
1. Installs frontend dependencies
2. Builds frontend with Rspack
3. Builds backend with V
4. Runs the application

### Separate Development

**Terminal 1 - Frontend:**
```bash
cd frontend
bun run watch
```

**Terminal 2 - Backend:**
```bash
./run.sh run
```

## Production Deployment

### Build for Production

```bash
./run.sh build
```

### Verify Build

```bash
# Check binary
ls -la desktop-dashboard
file desktop-dashboard

# Check frontend dist
ls -la frontend/dist/browser/
cat frontend/dist/browser/index.html
```

### Run Production Build

```bash
./desktop-dashboard
```

## Build Configuration

### build.config.sh

```bash
# Application name
APP_NAME="desktop-dashboard"

# Version
APP_VERSION="1.0.0"

# Source directory
SRC_DIR="src"

# Frontend directory
FRONTEND_DIR="frontend"
```

### Frontend Configuration

**rspack.config.js:**
- Entry point configuration
- Output path and naming
- Optimization settings
- Plugin configuration

### Backend Configuration

**v.mod:**
- Module name
- Dependencies
- Build flags

## System Requirements

### Development

| Requirement | Version |
|-------------|---------|
| V Language | 0.5.1+ |
| GCC | Any recent version |
| Bun | 1.0+ |
| Node.js | 18+ |

### Runtime

| Requirement | Version |
|-------------|---------|
| GTK3 | Linux |
| WebKit | Linux |
| Browser | Chrome/Edge/Firefox |

### Install Dependencies (Ubuntu/Debian)

```bash
# V Language
curl -o- https://raw.githubusercontent.com/vlang/v/master/install.sh | sh

# GCC
sudo apt-get install gcc

# Bun
curl -fsSL https://bun.sh/install | bash

# GTK3 and WebKit
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

## Troubleshooting

### Frontend dist not found

```bash
./run.sh build:fe
```

### Backend build fails

```bash
# Check V installation
v version

# Rebuild
./run.sh build:be
```

### Window fails to open

```bash
# Check dependencies
ldd ./desktop-dashboard | grep -E 'gtk|webkit'

# Install missing
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

### Port already in use

```bash
# Find process
lsof -ti:8080

# Kill process
lsof -ti:8080 | xargs kill -9
```

## Performance

### Build Times

| Component | Time |
|-----------|------|
| Frontend (Rspack) | 2-4s |
| Backend (V) | 1-2s |
| Full Build | 5-8s |

### Runtime

| Metric | Value |
|--------|-------|
| Memory | 20-50MB |
| CPU (idle) | <1% |
| CPU (active) | <5% |
| Startup | <2s |

## Logging

All logs output to stdout:

| Prefix | Description |
|--------|-------------|
| `[INFO]` | Information |
| `[SUCCESS]` | Success |
| `[WARN]` | Warning |
| `[ERROR]` | Error |
| `[STEP]` | Build step |
| `[VLANG]` | V compiler |
| `[FRONTEND]` | Frontend build |
| `[RSPACK]` | Rspack output |

## Environment Variables

No environment variables required for basic operation.

Optional:
- `APP_DEBUG=true` - Enable debug mode
- `APP_PORT=8080` - Custom port
- `APP_CONFIG=/path/to/config` - Config file path
