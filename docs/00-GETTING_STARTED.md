# Getting Started

Welcome to Desktop Dashboard. This guide will help you get up and running quickly.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Configuration](#configuration)
6. [Project Structure](#project-structure)
7. [Development](#development)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

Desktop Dashboard is a system monitoring and data management application with:

- **Backend**: V language with WebUI for window management
- **Frontend**: Angular 21 with Rspack bundler
- **Storage**: JSON file-based persistence or SQLite
- **Security**: Password hashing, CSRF protection, rate limiting

### Key Features

- System monitoring (CPU, Memory, Disk, Network)
- Process management
- CRUD operations with SQLite or JSON storage
- Secure authentication
- Modern Angular UI with WebUI windows
- Responsive design with dark theme

---

## Prerequisites

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| V Language | 0.5.1+ | Backend development |
| Bun | 1.0+ | Frontend package manager |
| GCC | 9.0+ | C compiler for V |
| GTK3 + WebKit | Latest | Window management (Linux) |

### Installation Commands

**V Language:**
```bash
git clone https://github.com/vlang/v
cd v
make
sudo ln -s $(pwd)/v /usr/local/bin/v
v version
```

**Bun:**
```bash
curl -fsSL https://bun.sh/install | bash
bun --version
```

**GCC:**
```bash
# Ubuntu/Debian
sudo apt-get install gcc

# macOS
xcode-select --install

# Fedora
sudo dnf install gcc
```

**GTK3 + WebKit (Linux):**
```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev

# Fedora
sudo dnf install gtk3-devel webkit2gtk3-devel

# Arch
sudo pacman -S gtk3 webkit2gtk
```

---

## Installation

### Quick Install

```bash
# Clone repository
git clone <repository-url>
cd starter-vlang-webui-angular-rspack

# Run setup script
./scripts/dev-setup.sh

# Start development
./run.sh dev
```

### Manual Install

```bash
# Clone repository
git clone <repository-url>
cd starter-vlang-webui-angular-rspack

# Install backend dependencies
v install

# Install frontend dependencies
cd frontend
bun install

# Copy environment configuration
cd ..
cp .env.example .env

# Build the application
./run.sh build

# Start development
./run.sh dev
```

---

## Quick Start

1. **Start Development Mode**
   ```bash
   ./run.sh dev
   ```

2. **Access Application**
   
   Open your browser to `http://localhost:8080`

3. **Verify Installation**
   
   - Dashboard should display with navigation menu
   - Demo data should show 5 users, 8 products, 5 orders
   - DevTools should be accessible

4. **First Steps**
   
   - Navigate through the menu items
   - Try creating a new user
   - Check the DevTools for application stats

---

## Configuration

### Environment Setup

Copy the environment template:
```bash
cp .env.example .env
```

### Key Settings

```bash
# Application
APP_ENV=development
APP_DEBUG=true
APP_NAME="Desktop Dashboard"

# Server
SERVER_HOST=localhost
SERVER_PORT=8080

# Database
DB_PATH=data/duckdb_demo.json
DB_DEMO_MODE=true

# Security
SESSION_TIMEOUT=3600
CSRF_TIMEOUT=3600
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000

# Logging
LOG_LEVEL=info
LOG_TO_CONSOLE=true
LOG_TO_FILE=false
```

### Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| APP_ENV | development | Environment (development/staging/production) |
| APP_DEBUG | true | Enable debug mode |
| SERVER_PORT | 8080 | Server port |
| DB_PATH | data/duckdb_demo.json | Database file path |
| LOG_LEVEL | info | Log level (debug/info/warn/error) |
| RATE_LIMIT_PER_MINUTE | 60 | API rate limit per minute |

---

## Project Structure

```
starter-vlang-webui-angular-rspack/
├── src/                          # V Backend Source
│   ├── main.v                    # Application entry point
│   ├── api_handlers.v            # API request handlers
│   ├── validator.v               # Validation pipeline
│   ├── rate_limiter.v            # Rate limiting middleware
│   ├── json_storage_service.v    # Data storage service
│   ├── security/                 # Security modules
│   └── errors/                   # Error handling
│
├── frontend/                     # Angular Frontend
│   ├── src/
│   │   ├── views/                # Page components
│   │   ├── core/                 # Core services
│   │   ├── models/               # TypeScript interfaces
│   │   └── types/                # Type definitions
│   └── package.json
│
├── data/                         # Application Data
│   └── duckdb_demo.json
│
├── docs/                         # Documentation
│   ├── INDEX.md                  # Documentation index
│   ├── 00-DOCUMENTATION.md       # Main documentation
│   └── 01-CRUD-DEMOS.md          # CRUD demos
│
├── build/                        # Build Output
│   └── desktop-dashboard
│
├── scripts/                      # Utility Scripts
│   └── dev-setup.sh
│
├── .env.example                  # Environment template
├── LICENSE                       # MIT License
├── README.md                     # Project overview
├── run.sh                        # Main build script
└── build.config.sh               # Build configuration
```

---

## Development

### Available Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Start development mode |
| `./run.sh build` | Build production version |
| `./run.sh test` | Run all tests |
| `./run.sh clean` | Clean build artifacts |
| `./run.sh help` | Show help message |

### Hot Reload

For faster development:

```bash
# Backend with live reload
v -live run src/

# Frontend with HMR
cd frontend && bun run dev
```

### Code Style

**V Backend:**
- Function naming: snake_case (`new_config_service`, `get_all_users`)
- Struct naming: PascalCase (`ConfigService`, `User`)
- Error handling: Use `or {}` blocks

**TypeScript Frontend:**
- Use `inject()` for dependency injection
- Use signals for state management
- Avoid `any` types; use proper interfaces
- Use `LoggerService` instead of `console.log`

### Running Tests

```bash
# All tests
./run.sh test

# Backend only
v test src/

# Frontend only
cd frontend && bun test

# E2E tests
cd frontend && bunx playwright test
```

---

## Troubleshooting

### V Compiler Not Found

```bash
git clone https://github.com/vlang/v
cd v
make
sudo ln -s $(pwd)/v /usr/local/bin/v
```

### GTK3/WebKit Missing (Linux)

```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev

# Fedora
sudo dnf install gtk3-devel webkit2gtk3-devel
```

### Frontend Build Fails

```bash
cd frontend
rm -rf node_modules
bun install
bun run build
```

### Port Already in Use

```bash
# Kill process on port 8080
lsof -ti:8080 | xargs kill -9

# Or change port in .env
SERVER_PORT=8081
```

### Database File Not Found

```bash
# Create data directory
mkdir -p data

# Run application to generate demo data
./run.sh dev
```

---

## Next Steps

After completing the setup:

1. [Read the Architecture Guide](docs/00-DOCUMENTATION.md#architecture)
2. [Explore API Reference](docs/00-DOCUMENTATION.md#api-reference)
3. [Try CRUD Demos](docs/01-CRUD-DEMOS.md)
4. [Review Security Features](docs/00-DOCUMENTATION.md#security)

---

*Last Updated: 2026-03-29*
