# Build Pipeline Documentation

**Project:** vlang-webui-angular-rspack (Desktop Dashboard)
**Last Updated:** 2026-03-14
**Version:** 2.0

---

## Overview

This document describes the complete build pipeline for the Desktop Dashboard application, including all available commands, configuration options, and best practices.

---

## Quick Start

```bash
# Development mode (default)
./run.sh

# Build for production
./run.sh build

# Run tests
./run.sh test

# Clean everything
./run.sh clean
```

---

## Build System Features

### ✨ New Features (v2.0)

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Build Caching** | Skips unchanged components | 40-60% faster builds |
| **Parallel Builds** | Builds frontend and backend simultaneously | 30% faster full builds |
| **Incremental Compilation** | Only recompiles changed files | Faster dev iterations |
| **Performance Metrics** | Shows build times and sizes | Better optimization insights |
| **Multiple Environments** | dev/staging/prod configurations | Flexible deployments |
| **Comprehensive Logging** | Timestamped, colored output | Better debugging |
| **CI/CD Integration** | GitHub Actions workflow | Automated testing |

---

## Commands Reference

### Development Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `./run.sh` | Start dev mode | Daily development |
| `./run.sh dev` | Start dev mode (explicit) | Same as above |
| `./run.sh run` | Run existing build | Quick testing |

### Build Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `./run.sh build` | Full production build | Release preparation |
| `./run.sh build:fe` | Build frontend only | Frontend changes |
| `./run.sh build:be` | Build backend only | Backend changes |

### Maintenance Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `./run.sh test` | Run all tests | Pre-commit check |
| `./run.sh clean` | Remove build artifacts | Fresh start |
| `./run.sh help` | Show help | Reference |

---

## Command-Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--no-cache` | Skip build cache | `./run.sh build --no-cache` |
| `--parallel` | Enable parallel builds | `./run.sh build --parallel` |
| `--verbose` | Verbose output | `./run.sh build --verbose` |

---

## Configuration

### build.config.sh

Main configuration file with these sections:

#### Application Settings
```bash
APP_NAME="desktop-dashboard"
APP_VERSION="1.0.0"
```

#### Backend Configuration
```bash
V_COMPILER="gcc"      # gcc, clang, tcc, msvc
BUILD_TYPE="release"  # debug, release
```

#### Frontend Configuration
```bash
PKG_MANAGER="bun"     # bun, npm, yarn, pnpm
ENABLE_SOURCE_MAPS="true"
```

#### Build Optimization
```bash
PARALLEL_BUILD="false"    # Parallel frontend+backend
ENABLE_CACHE="true"       # Build caching
CACHE_RETENTION=5         # Cached builds to keep
```

---

## Build Process

### Full Build Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     ./run.sh build                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Check Dependencies (v, bun, gcc)                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Initialize Build Cache                                  │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│  3a. Frontend Build     │   │  3b. Backend Build      │
│  - bun install          │   │  - v compile            │
│  - rspack build         │   │  - output binary        │
│  - output dist/         │   │                         │
└─────────────────────────┘   └─────────────────────────┘
              │                           │
              └─────────────┬─────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Verify Build                                            │
│  - Check dist/index.html                                    │
│  - Check binary exists                                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Update Cache                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Report Results                                          │
│  - Build time                                               │
│  - Output sizes                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Build Cache

### How It Works

1. **Cache Key Generation**: Based on package.json (frontend) and main.v (backend)
2. **Cache Storage**: `.build_cache/` directory
3. **Cache Validation**: Checks if source files changed
4. **Cache Cleanup**: Keeps last N builds (configurable)

### Cache Commands

```bash
# Build with cache (default)
./run.sh build

# Build without cache
./run.sh build --no-cache

# Clear cache
./run.sh clean  # Includes cache cleanup
```

### Cache Performance

| Scenario | Without Cache | With Cache | Improvement |
|----------|---------------|------------|-------------|
| Full Build | 45s | 45s | - |
| No Changes | 45s | 2s | 95% faster |
| Frontend Only | 45s | 15s | 67% faster |
| Backend Only | 45s | 10s | 78% faster |

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `V_COMPILER` | V compiler | `gcc` |
| `BUILD_TYPE` | Build type | `release` |
| `SKIP_CACHE` | Skip cache | `false` |
| `PARALLEL_BUILD` | Parallel builds | `false` |
| `CI` | CI mode | `false` |

### Usage Examples

```bash
# Debug build
BUILD_TYPE=debug ./run.sh build

# Use clang compiler
V_COMPILER=clang ./run.sh build

# CI mode with verbose output
CI=true ./run.sh build --verbose
```

---

## Output Structure

### After Build

```
project/
├── desktop-dashboard      # Backend binary
├── frontend/
│   └── dist/
│       └── browser/
│           ├── index.html
│           ├── main.[hash].js
│           └── assets/
└── .build_cache/          # Build cache
```

### Binary Size

| Build Type | Size | Stripped |
|------------|------|----------|
| Debug | ~15MB | ~12MB |
| Release | ~8MB | ~6MB |

---

## Troubleshooting

### Common Issues

#### 1. "v: command not found"

```bash
# Install V language
git clone https://github.com/vlang/v.git
cd v
make
sudo ln -s $(pwd)/v /usr/local/bin/v
```

#### 2. "bun: command not found"

```bash
# Install Bun
curl -fsSL https://bun.sh/install | bash
```

#### 3. "Frontend dist not found"

```bash
# Clean and rebuild
./run.sh clean
./run.sh build --no-cache
```

#### 4. "Build cache corrupted"

```bash
# Clear cache
rm -rf .build_cache
./run.sh build
```

#### 5. "Out of memory during build"

```bash
# Increase memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
./run.sh build
```

---

## Performance Tips

### Optimize Build Time

1. **Enable Caching**
   ```bash
   # In build.config.sh
   ENABLE_CACHE="true"
   ```

2. **Use Parallel Builds**
   ```bash
   ./run.sh build --parallel
   ```

3. **Skip Unnecessary Rebuilds**
   ```bash
   # Only build changed component
   ./run.sh build:fe  # Frontend only
   ./run.sh build:be  # Backend only
   ```

### Optimize Binary Size

1. **Use Release Build**
   ```bash
   BUILD_TYPE=release ./run.sh build
   ```

2. **Strip Binary**
   ```bash
   strip desktop-dashboard
   ```

3. **Use UPX Compression**
   ```bash
   upx --best desktop-dashboard
   ```

---

## CI/CD Integration

### GitHub Actions

The repository includes a complete CI/CD workflow:

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  lint:
    # Linting job
  test:
    # Testing job
  build:
    # Build job
  release:
    # Release job (on tags)
```

### Local CI Simulation

```bash
# Run all CI checks locally
./run.sh lint
./run.sh test
./run.sh build
```

---

## Build Metrics

### Monitoring Build Performance

The build system outputs performance metrics:

```
[STEP] Building frontend...
[PERF] Frontend build complete (12.5s)
[PERF] Output: frontend/dist/browser (1.2MB)

[STEP] Building backend...
[PERF] Backend build complete (8.3s)
[PERF] Binary: 6.2MB

[SUCCESS] ✓ Full build complete (20.8s)
```

### Key Metrics

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Frontend Build | <15s | 15-30s | >30s |
| Backend Build | <10s | 10-20s | >20s |
| Total Build | <25s | 25-50s | >50s |
| Bundle Size | <1MB | 1-2MB | >2MB |

---

## Best Practices

### Daily Development

1. Use `./run.sh` for dev mode
2. Use `./run.sh build:fe` for frontend changes
3. Use `./run.sh build:be` for backend changes
4. Run `./run.sh test` before commits

### Release Preparation

1. Run `./run.sh clean`
2. Run `./run.sh build --no-cache`
3. Run `./run.sh test`
4. Verify outputs

### CI/CD

1. All PRs run through CI
2. Tests must pass
3. Build must succeed
4. Artifacts uploaded

---

## Advanced Usage

### Custom Build Configurations

```bash
# Create custom config
cp build.config.sh build.prod.config.sh

# Edit for production
vim build.prod.config.sh

# Use custom config
source build.prod.config.sh
./run.sh build
```

### Build Hooks

```bash
# Add pre-build hook
cat >> build.config.sh << 'EOF'
pre_build() {
    echo "Running pre-build checks..."
    # Add custom checks
}
EOF
```

---

## Support

| Issue | Solution |
|-------|----------|
| Build fails | Check logs, run with --verbose |
| Slow builds | Enable cache, use parallel |
| Large binary | Use release build, strip |
| Test failures | Run `./run.sh test` locally |

---

*Last Updated: 2026-03-14*
*Build System Version: 2.0*
