#!/usr/bin/env bash
# Battery Monitor - Build & Run Script with Full Pipeline
# All logs are output to terminal (no log files)

set -e

# Colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="${SCRIPT_DIR}/frontend"
DIST_DIR="${FRONTEND_DIR}/dist/browser"

# Log functions - all output goes to terminal
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_v() {
    echo -e "${MAGENTA}[VLANG]${NC} $1"
}

log_frontend() {
    echo -e "${CYAN}[FRONTEND]${NC} $1"
}

# Check if frontend dist exists
check_frontend_dist() {
    if [ ! -d "$DIST_DIR" ]; then
        log_warn "Frontend dist not found at $DIST_DIR"
        return 1
    fi
    if [ ! -f "$DIST_DIR/index.html" ]; then
        log_warn "index.html not found in $DIST_DIR"
        return 1
    fi
    return 0
}

# Build frontend
build_frontend() {
    log_step "Building frontend..."
    log_frontend "Working directory: $FRONTEND_DIR"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        log_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    if [ ! -f "$FRONTEND_DIR/package.json" ]; then
        log_error "package.json not found in $FRONTEND_DIR"
        exit 1
    fi
    
    log_frontend "Installing dependencies..."
    cd "$FRONTEND_DIR"
    bun install --verbose 2>&1 | while read line; do
        echo -e "${CYAN}[BUN]${NC} $line"
    done
    
    log_frontend "Building with Rspack..."
    # Enable verbose output from rspack
    RSPACK_VERBOSE=1 bun run build:rspack 2>&1 | while read line; do
        echo -e "${CYAN}[RSPACK]${NC} $line"
    done
    
    cd "$SCRIPT_DIR"
    
    if check_frontend_dist; then
        log_success "Frontend build complete"
        log_info "Output: $DIST_DIR"
        ls -la "$DIST_DIR" 2>&1 | while read line; do
            echo -e "${CYAN}[DIST]${NC} $line"
        done
    else
        log_error "Frontend build failed - dist not created"
        exit 1
    fi
}

# Build backend (V lang)
build_backend() {
    log_step "Building backend (V lang)..."
    log_v "Compiler: gcc"
    log_v "Output: battery"
    log_v "Source: ./src"

    # Build with V compiler from src directory
    v -cc gcc -o battery src/ 2>&1 | while read line; do
        echo -e "${MAGENTA}[V]${NC} $line"
    done

    if [ -f "$SCRIPT_DIR/battery" ]; then
        log_success "Backend build complete"
        log_info "Binary: $SCRIPT_DIR/battery"
        ls -lh "$SCRIPT_DIR/battery" 2>&1 | while read line; do
            echo -e "${MAGENTA}[BINARY]${NC} $line"
        done
    else
        log_error "Backend build failed - binary not created"
        exit 1
    fi
}

# Build everything
build_all() {
    log_step "Building entire application..."
    echo ""
    build_frontend
    echo ""
    build_backend
    echo ""
    log_success "✓ Full build complete"
}

# Run in development mode (rebuild frontend + run backend with hot reload)
run_dev() {
    log_step "Starting development mode..."
    echo ""
    
    # Always rebuild frontend first
    log_info "Rebuilding frontend..."
    build_frontend
    echo ""
    
    # Check if backend needs rebuilding
    if [ ! -f "$SCRIPT_DIR/battery" ]; then
        log_info "Backend binary not found, building..."
        build_backend
        echo ""
    else
        log_info "Backend binary exists, skipping rebuild"
        log_info "Run './run.sh build' to rebuild backend"
        echo ""
    fi
    
    # Show runtime info
    log_step "Starting application..."
    log_info "Frontend: $DIST_DIR"
    log_info "Backend: $SCRIPT_DIR/battery"
    echo ""
    log_info "Press Ctrl+C to stop"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Application Starting...${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Run with verbose output (V doesn't have verbose flag for run)
    v -cc gcc run src/ 2>&1 | while read line; do
        echo -e "${MAGENTA}[APP]${NC} $line"
    done
}

# Clean build artifacts
clean() {
    log_step "Cleaning build artifacts..."
    
    if [ -f "$SCRIPT_DIR/battery" ]; then
        rm -f "$SCRIPT_DIR/battery"
        log_info "Removed: battery"
    fi
    
    if [ -d "$DIST_DIR" ]; then
        rm -rf "$DIST_DIR"
        log_info "Removed: $DIST_DIR"
    fi
    
    # Clean frontend node_modules cache
    if [ -d "$FRONTEND_DIR/.angular" ]; then
        rm -rf "$FRONTEND_DIR/.angular"
        log_info "Removed: .angular cache"
    fi
    
    log_success "✓ Clean complete"
}

# Show usage
show_usage() {
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  dev       - Rebuild frontend and run app (default)"
    echo "  build     - Build frontend and backend"
    echo "  build:fe  - Build frontend only"
    echo "  build:be  - Build backend only"
    echo "  run       - Run without rebuilding"
    echo "  clean     - Remove build artifacts"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./run.sh           # Start dev mode (rebuilds frontend)"
    echo "  ./run.sh dev       # Same as above"
    echo "  ./run.sh build     # Build everything"
    echo "  ./run.sh build:fe  # Build frontend only"
    echo "  ./run.sh run       # Run existing build"
    echo ""
}

# Main command handler
cmd="${1:-dev}"

log_info "Command: $cmd"
log_info "Working directory: $SCRIPT_DIR"
echo ""

case "$cmd" in
    dev)
        run_dev
        ;;
    build)
        build_all
        ;;
    build:fe|build:frontend)
        build_frontend
        ;;
    build:be|build:backend)
        build_backend
        ;;
    run)
        log_step "Running existing build..."
        if [ ! -f "$SCRIPT_DIR/battery" ]; then
            log_error "Binary not found. Run './run.sh build' first."
            exit 1
        fi
        if ! check_frontend_dist; then
            log_error "Frontend dist not found. Run './run.sh build' first."
            exit 1
        fi
        log_info "Starting application..."
        v -cc gcc run src/ 2>&1 | while read line; do
            echo -e "${MAGENTA}[APP]${NC} $line"
        done
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log_error "Unknown command: $cmd"
        echo ""
        show_usage
        exit 1
        ;;
esac
