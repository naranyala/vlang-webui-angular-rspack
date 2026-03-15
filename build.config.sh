# ==============================================================================
# Build Configuration - Centralized Settings
# ==============================================================================
# This file contains all build configuration for the Desktop Dashboard project.
# Edit these values to customize the build process.
# ==============================================================================

# ------------------------------------------------------------------------------
# Application Settings
# ------------------------------------------------------------------------------

# Application name
readonly APP_NAME="desktop-dashboard"

# Application version (semver)
readonly APP_VERSION="1.0.0"

# Application description
readonly APP_DESCRIPTION="Desktop Dashboard with system monitoring using WebUI"

# ------------------------------------------------------------------------------
# Directory Structure
# ------------------------------------------------------------------------------

# Source directories
readonly SRC_DIR="src"
readonly FRONTEND_DIR="frontend"

# Output directories
readonly DIST_DIR="${FRONTEND_DIR}/dist/browser"
readonly BUILD_DIR="build"
readonly CACHE_DIR=".build_cache"

# ------------------------------------------------------------------------------
# Backend Configuration
# ------------------------------------------------------------------------------

# Output binary path (inside build directory)
readonly OUTPUT_BINARY="${BUILD_DIR}/${APP_NAME}"

# V compiler to use
# Options: gcc, clang, tcc, msvc
readonly V_COMPILER="gcc"

# Build type
# Options: debug, release
readonly BUILD_TYPE="release"

# V compiler flags
readonly V_FLAGS="-skip-unused"

# Enable V hot reload in dev mode
readonly V_HOT_RELOAD="false"

# ------------------------------------------------------------------------------
# Frontend Configuration
# ------------------------------------------------------------------------------

# Node package manager
# Options: bun, npm, yarn, pnpm
readonly PKG_MANAGER="bun"

# Rspack build mode
# Options: development, production
readonly RSPACK_MODE="production"

# Enable source maps
readonly ENABLE_SOURCE_MAPS="true"

# Enable bundle analysis
readonly ENABLE_BUNDLE_ANALYSIS="false"

# ------------------------------------------------------------------------------
# Build Optimization
# ------------------------------------------------------------------------------

# Enable parallel builds (build frontend and backend simultaneously)
readonly PARALLEL_BUILD="false"

# Enable build caching (skip unchanged components)
readonly ENABLE_CACHE="true"

# Cache retention (number of cached builds to keep)
readonly CACHE_RETENTION=5

# ------------------------------------------------------------------------------
# Testing Configuration
# ------------------------------------------------------------------------------

# Run tests before build
readonly RUN_TESTS_BEFORE_BUILD="false"

# Fail build on test failure
readonly FAIL_ON_TEST_FAILURE="true"

# Test coverage threshold (percentage)
readonly COVERAGE_THRESHOLD=80

# ------------------------------------------------------------------------------
# Logging Configuration
# ------------------------------------------------------------------------------

# Log level
# Options: debug, info, warn, error
readonly LOG_LEVEL="info"

# Enable colored output
readonly ENABLE_COLORS="true"

# Enable timestamps in logs
readonly ENABLE_TIMESTAMPS="true"

# ------------------------------------------------------------------------------
# Environment-Specific Settings
# ------------------------------------------------------------------------------

# Development environment
DEV_API_URL="http://localhost:8080"
DEV_ENABLE_DEBUG="true"
DEV_ENABLE_LOGGING="true"

# Production environment
PROD_API_URL=""
PROD_ENABLE_DEBUG="false"
PROD_ENABLE_LOGGING="false"

# ------------------------------------------------------------------------------
# Performance Tuning
# ------------------------------------------------------------------------------

# Maximum memory for Node.js/Bun (in MB)
readonly MAX_MEMORY="4096"

# Number of parallel jobs for builds
# Set to 0 for auto-detection
readonly BUILD_JOBS="0"

# ------------------------------------------------------------------------------
# Optional Features
# ------------------------------------------------------------------------------

# Enable TypeScript strict mode
readonly TS_STRICT="true"

# Enable ESLint/Biome linting
readonly ENABLE_LINTING="true"

# Enable Prettier/Biome formatting
readonly ENABLE_FORMATTING="true"

# Enable security audit
readonly ENABLE_SECURITY_AUDIT="false"

# ------------------------------------------------------------------------------
# CI/CD Configuration
# ------------------------------------------------------------------------------

# CI environment detection
readonly CI="${CI:-false}"

# Enable verbose output in CI
readonly CI_VERBOSE="true"

# Upload build artifacts
readonly UPLOAD_ARTIFACTS="true"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get build ID (for caching)
get_build_id() {
    echo "${APP_NAME}-${APP_VERSION}-$(date +%Y%m%d-%H%M%S)"
}

# Check if running in CI
is_ci() {
    [[ "$CI" == "true" ]] || [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$GITLAB_CI" ]]
}

# Check if running in development mode
is_dev() {
    [[ "$BUILD_TYPE" == "debug" ]]
}

# Print configuration summary
print_config() {
    echo "Build Configuration:"
    echo "  App:        $APP_NAME v$APP_VERSION"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Compiler:   $V_COMPILER"
    echo "  Frontend:   $PKG_MANAGER + Rspack"
    echo "  Cache:      $ENABLE_CACHE"
    echo "  Parallel:   $PARALLEL_BUILD"
    echo "  CI Mode:    $(is_ci && echo 'yes' || echo 'no')"
}

# Export configuration for subprocesses
export_config() {
    export APP_NAME
    export APP_VERSION
    export V_COMPILER
    export BUILD_TYPE
    export PKG_MANAGER
    export ENABLE_CACHE
    export PARALLEL_BUILD
}

# Initialize build environment
init_build() {
    # Create necessary directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$CACHE_DIR"
    
    # Export configuration
    export_config
    
    # Print configuration if verbose
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        print_config
    fi
}
