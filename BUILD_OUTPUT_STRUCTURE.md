# Build Output Structure

**Last Updated:** 2026-03-14
**Build System Version:** 2.0

---

## Directory Structure

```
vlang-webui-angular-rspack/
├── build/                          # ← Backend binary output
│   └── desktop-dashboard           # ← Final executable
│
├── frontend/
│   └── dist/
│       └── browser/                # ← Frontend build output
│           ├── index.html
│           ├── main.[hash].js
│           ├── vendor.[hash].js
│           ├── angular.[hash].js
│           └── assets/
│
├── .build_cache/                   # ← Build cache (auto-managed)
│   ├── frontend_<hash>
│   └── backend_<hash>
│
└── src/                            # ← Source code
    ├── main.v
    ├── services.v
    └── ...
```

---

## Build Outputs

### Backend Binary

**Location:** `./build/desktop-dashboard`

**Properties:**
- Size: ~6-8MB (release build)
- Platform: Linux x64
- Dependencies: GTK3, WebKit2GTK

**Usage:**
```bash
# Run directly
./build/desktop-dashboard

# Or use run.sh
./run.sh run
```

### Frontend Build

**Location:** `./frontend/dist/browser/`

**Files:**
| File | Purpose | Size (typical) |
|------|---------|----------------|
| `index.html` | Entry point | ~1.5KB |
| `main.[hash].js` | Application code | ~48KB |
| `vendor.[hash].js` | Third-party libs | ~36KB |
| `angular-*.js` | Angular framework | ~900KB |
| `zone.[hash].js` | Zone.js | ~33KB |
| `assets/` | Static assets | Variable |

**Total Size:** ~1.2MB (gzipped: ~400KB)

---

## Build Configuration

### Output Paths (build.config.sh)

```bash
# Backend output
readonly BUILD_DIR="build"
readonly OUTPUT_BINARY="${BUILD_DIR}/${APP_NAME}"

# Frontend output
readonly DIST_DIR="${FRONTEND_DIR}/dist/browser"

# Cache
readonly CACHE_DIR=".build_cache"
```

---

## Build Commands

### Full Build
```bash
./run.sh build
```

**Outputs:**
- `./build/desktop-dashboard`
- `./frontend/dist/browser/`

### Backend Only
```bash
./run.sh build:be
```

**Output:**
- `./build/desktop-dashboard`

### Frontend Only
```bash
./run.sh build:fe
```

**Output:**
- `./frontend/dist/browser/`

### Clean Build
```bash
./run.sh clean && ./run.sh build
```

**Outputs:** Fresh build in both directories

---

## CI/CD Artifacts

### GitHub Actions

The CI/CD pipeline uploads these artifacts:

1. **desktop-dashboard-linux**
   - Path: `./build/desktop-dashboard`
   - Retention: 30 days

2. **frontend-dist**
   - Path: `./frontend/dist/browser`
   - Retention: 30 days

### Release Package

On version tags (e.g., `v1.0.0`):
```
desktop-dashboard-v1.0.0-linux.tar.gz
├── build/desktop-dashboard
├── frontend/dist/browser/
└── README.md
```

---

## Build Cache

### Location
`.build_cache/`

### Contents
- `frontend_<hash>` - Frontend build cache entries
- `backend_<hash>` - Backend build cache entries

### Management
```bash
# Clear cache
./run.sh clean

# Build without cache
./run.sh build --no-cache
```

### Retention
- Keeps last 5 builds per component
- Auto-cleanup on each build

---

## Verification

### Check Build Outputs

```bash
# Verify backend binary
test -f ./build/desktop-dashboard && echo "✓ Backend binary exists"

# Verify frontend
test -f ./frontend/dist/browser/index.html && echo "✓ Frontend built"

# Check binary size
ls -lh ./build/desktop-dashboard

# Check frontend size
du -sh ./frontend/dist/browser
```

### Test Build

```bash
# Run application
./build/desktop-dashboard

# Or use run.sh
./run.sh run
```

---

## Troubleshooting

### Binary Not in build/

**Symptom:** Binary appears in project root instead

**Cause:** Old configuration

**Fix:**
```bash
# Clean old builds
rm -f ./desktop-dashboard
rm -rf ./build

# Rebuild
./run.sh build
```

### Frontend Not in dist/browser/

**Symptom:** Frontend builds to wrong directory

**Cause:** Rspack configuration issue

**Fix:**
```bash
# Check rspack.config.js
grep -A3 "output:" frontend/rspack.config.js

# Rebuild
./run.sh clean
./run.sh build:fe
```

### Cache Issues

**Symptom:** Build skips when it shouldn't

**Cause:** Stale cache

**Fix:**
```bash
./run.sh clean
./run.sh build --no-cache
```

---

## Performance

### Typical Build Times

| Component | Cold Build | Cached Build |
|-----------|------------|--------------|
| Frontend | 12-15s | 2-3s |
| Backend | 8-12s | 1-2s |
| **Total** | **20-27s** | **3-5s** |

### Output Sizes

| Component | Size | Compressed |
|-----------|------|------------|
| Backend | 6-8MB | 3-4MB |
| Frontend | 1.2MB | 400KB |
| **Total** | **~9MB** | **~3.4MB** |

---

## Environment Variables

Override output paths:

```bash
# Custom build directory
BUILD_DIR=dist ./run.sh build

# Custom binary name
APP_NAME=my-app ./run.sh build
```

---

*Build Pipeline Documentation v2.0*
