#!/usr/bin/env bash
# ==============================================================================
# Desktop Dashboard - Build & Run Pipeline
# ==============================================================================
# A modern, robust build system with:
# - Parallel builds
# - Incremental compilation
# - Build caching
# - Comprehensive error handling
# - Build performance metrics
# - Multiple environments (dev/staging/prod)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/build.config.sh"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "❌ Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# ==============================================================================
# Colors & Formatting
# ==============================================================================

declare -A COLORS=(
    [reset]='\033[0m'
    [bold]='\033[1m'
    [dim]='\033[2m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [yellow]='\033[0;33m'
    [blue]='\033[0;34m'
    [cyan]='\033[0;36m'
    [magenta]='\033[0;35m'
    [white]='\033[0;37m'
)

# ==============================================================================
# Logging Functions
# ==============================================================================

log() {
    local level="$1"
    shift
    local color="${COLORS[$level]:-${COLORS[white]}}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${COLORS[dim]}[$timestamp]${COLORS[reset]} ${color}${level}${COLORS[reset]} $*" >&2
}

log_info()    { log "INFO"    "${COLORS[blue]}" "$@"; }
log_success() { log "SUCCESS" "${COLORS[green]}" "$@"; }
log_warn()    { log "WARN"    "${COLORS[yellow]}" "$@"; }
log_error()   { log "ERROR"   "${COLORS[red]}" "$@"; }
log_step()    { log "STEP"    "${COLORS[cyan]}" "$@"; }
log_v()       { log "VLANG"   "${COLORS[magenta]}" "$@"; }
log_fe()      { log "FE"      "${COLORS[cyan]}" "$@"; }
log_perf()    { log "PERF"    "${COLORS[yellow]}" "$@"; }

# ==============================================================================
# Utility Functions
# ==============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check required dependencies
check_dependencies() {
    local missing=()
    
    if ! command_exists v; then
        missing+=("v (V language)")
    fi
    
    if ! command_exists bun; then
        missing+=("bun")
    fi
    
    if ! command_exists gcc; then
        missing+=("gcc")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 1
    fi
    
    log_success "All dependencies satisfied"
}

# Get system info
get_system_info() {
    local os_name
    local cpu_count
    
    os_name="$(uname -s)"
    cpu_count="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)"
    
    echo "OS: $os_name | CPUs: $cpu_count"
}

# Calculate file hash for caching
get_file_hash() {
    local file="$1"
    if [[ -f "$file" ]]; then
        md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file" 2>/dev/null || echo "unknown"
    else
        echo "not_found"
    fi
}

# ==============================================================================
# Build Cache Management
# ==============================================================================

BUILD_CACHE_DIR="${SCRIPT_DIR}/.build_cache"
CACHE_VERSION="1.0"

init_cache() {
    mkdir -p "$BUILD_CACHE_DIR"
    echo "$CACHE_VERSION" > "$BUILD_CACHE_DIR/version"
}

get_cache_key() {
    local component="$1"
    local hash_file=""
    
    case "$component" in
        frontend)
            hash_file="${SCRIPT_DIR}/frontend/package.json"
            ;;
        backend)
            hash_file="${SCRIPT_DIR}/src/main.v"
            ;;
    esac
    
    get_file_hash "$hash_file"
}

is_cached() {
    local component="$1"
    local cache_key
    cache_key="$(get_cache_key "$component")"
    local cache_file="${BUILD_CACHE_DIR}/${component}_${cache_key}"
    
    [[ -f "$cache_file" ]]
}

update_cache() {
    local component="$1"
    local cache_key
    cache_key="$(get_cache_key "$component")"
    local cache_file="${BUILD_CACHE_DIR}/${component}_${cache_key}"
    
    touch "$cache_file"
    
    # Clean old cache entries (keep last 5)
    find "$BUILD_CACHE_DIR" -name "${component}_*" -type f -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | tail -n +6 | cut -d' ' -f2- | xargs rm -f 2>/dev/null || true
}

clean_cache() {
    if [[ -d "$BUILD_CACHE_DIR" ]]; then
        rm -rf "$BUILD_CACHE_DIR"/*
        log_success "Build cache cleared"
    fi
}

# ==============================================================================
# Frontend Build
# ==============================================================================

FE_DIR="${SCRIPT_DIR}/frontend"
FE_DIST_DIR="${FE_DIR}/dist/browser"

check_frontend() {
    if [[ ! -d "$FE_DIR" ]]; then
        log_error "Frontend directory not found: $FE_DIR"
        exit 1
    fi
    
    if [[ ! -f "$FE_DIR/package.json" ]]; then
        log_error "package.json not found in $FE_DIR"
        exit 1
    fi
}

build_frontend() {
    local start_time
    start_time=$(date +%s.%N)
    
    log_step "Building frontend..."
    log_fe "Working directory: $FE_DIR"
    
    check_frontend
    
    # Check cache
    if [[ "${SKIP_CACHE:-false}" != "true" ]] && is_cached "frontend"; then
        log_info "Frontend build cached, skipping..."
        return 0
    fi
    
    # Install dependencies
    log_fe "Installing dependencies..."
    cd "$FE_DIR"
    
    if ! bun install --frozen-lockfile 2>&1 | tee /tmp/bun_install.log; then
        log_error "Frontend dependency installation failed"
        exit 1
    fi
    
    # Build with Rspack
    log_fe "Building with Rspack..."
    if ! bun run build:rspack 2>&1 | tee /tmp/rspack_build.log; then
        log_error "Frontend build failed"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    
    # Verify build
    if [[ ! -d "$FE_DIST_DIR" ]] || [[ ! -f "$FE_DIST_DIR/index.html" ]]; then
        log_error "Frontend build failed - dist not created"
        exit 1
    fi
    
    # Update cache
    if [[ "${SKIP_CACHE:-false}" != "true" ]]; then
        update_cache "frontend"
    fi
    
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(awk "BEGIN {printf \"%.2f\", $end_time - $start_time}")
    
    log_success "Frontend build complete (${duration}s)"
    log_perf "Output: $FE_DIST_DIR ($(du -sh "$FE_DIST_DIR" | cut -f1))"
}

# ==============================================================================
# Backend Build
# ==============================================================================

build_backend() {
    local start_time
    start_time=$(date +%s.%N)
    
    log_step "Building backend (V lang)..."
    log_v "Compiler: ${V_COMPILER:-gcc}"
    log_v "Output: ${OUTPUT_BINARY}"
    log_v "Source: ./${SRC_DIR}"
    
    # Check cache
    if [[ "${SKIP_CACHE:-false}" != "true" ]] && is_cached "backend"; then
        log_info "Backend build cached, skipping..."
        return 0
    fi
    
    # Create build directory
    mkdir -p "$(dirname "$SCRIPT_DIR/${OUTPUT_BINARY}")"

    # Build with V compiler
    if ! v -cc "${V_COMPILER:-gcc}" -o "${OUTPUT_BINARY}" "${SRC_DIR}/" 2>&1 | tee /tmp/v_build.log; then
        log_error "Backend build failed"
        exit 1
    fi
    
    # Verify binary
    if [[ ! -f "$SCRIPT_DIR/${OUTPUT_BINARY}" ]]; then
        log_error "Backend build failed - binary not created"
        exit 1
    fi
    
    # Update cache
    if [[ "${SKIP_CACHE:-false}" != "true" ]]; then
        update_cache "backend"
    fi
    
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(awk "BEGIN {printf \"%.2f\", $end_time - $start_time}" )
    
    log_success "Backend build complete (${duration}s)"
    log_perf "Binary: $(ls -lh "$SCRIPT_DIR/${OUTPUT_BINARY}" | awk '{print $5}')"
}

# ==============================================================================
# Full Build
# ==============================================================================

build_all() {
    local start_time
    start_time=$(date +%s.%N)
    
    log_step "Building entire application..."
    log_info "System: $(get_system_info)"
    
    # Initialize cache
    init_cache
    
    # Build frontend and backend in parallel (if supported)
    if [[ "${PARALLEL_BUILD:-false}" == "true" ]]; then
        log_info "Running parallel build..."
        build_frontend &
        local fe_pid=$!
        
        build_backend &
        local be_pid=$!
        
        # Wait for both to complete
        if ! wait $fe_pid; then
            log_error "Frontend build failed"
            exit 1
        fi
        
        if ! wait $be_pid; then
            log_error "Backend build failed"
            exit 1
        fi
    else
        build_frontend
        build_backend
    fi
    
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(awk "BEGIN {printf \"%.2f\", $end_time - $start_time}" )
    
    echo ""
    log_success "✓ Full build complete (${duration}s)"
    echo ""
    log_info "Frontend: $FE_DIST_DIR"
    log_info "Backend:  $SCRIPT_DIR/${OUTPUT_BINARY}"
}

# ==============================================================================
# Development Mode
# ==============================================================================

run_dev() {
    log_step "Starting development mode..."
    log_info "System: $(get_system_info)"
    
    # Always rebuild frontend in dev mode
    log_info "Rebuilding frontend..."
    build_frontend
    echo ""
    
    # Check backend
    if [[ ! -f "$SCRIPT_DIR/${OUTPUT_BINARY}" ]]; then
        log_info "Backend binary not found, building..."
        build_backend
        echo ""
    else
        log_info "Using existing backend binary"
        log_info "Run './run.sh build' to rebuild backend"
        echo ""
    fi
    
    # Runtime info
    log_step "Starting application..."
    log_info "Frontend: $FE_DIST_DIR"
    log_info "Backend:  $SCRIPT_DIR/${OUTPUT_BINARY}"
    echo ""
    log_info "Press Ctrl+C to stop"
    echo ""
    echo -e "${COLORS[green]}========================================${COLORS[reset]}"
    echo -e "${COLORS[green]}  Application Starting...${COLORS[reset]}"
    echo -e "${COLORS[green]}========================================${COLORS[reset]}"
    echo ""
    
    # Run application
    v -cc gcc run "${SRC_DIR}/" 2>&1 | while read -r line; do
        echo -e "${COLORS[magenta]}[APP]${COLORS[reset]} $line"
    done
}

# ==============================================================================
# Clean
# ==============================================================================

clean() {
    log_step "Cleaning build artifacts..."
    
    # Clean backend
    if [[ -f "$SCRIPT_DIR/${OUTPUT_BINARY}" ]]; then
        rm -f "$SCRIPT_DIR/${OUTPUT_BINARY}"
        log_info "Removed: ${OUTPUT_BINARY}"
    fi
    
    # Clean frontend
    if [[ -d "$FE_DIST_DIR" ]]; then
        rm -rf "$FE_DIST_DIR"
        log_info "Removed: $FE_DIST_DIR"
    fi
    
    # Clean caches
    if [[ -d "$FE_DIR/.angular" ]]; then
        rm -rf "$FE_DIR/.angular"
        log_info "Removed: .angular cache"
    fi
    
    if [[ -d "$FE_DIR/node_modules" ]]; then
        rm -rf "$FE_DIR/node_modules"
        log_info "Removed: node_modules"
    fi
    
    # Clean build cache
    clean_cache
    
    log_success "✓ Clean complete"
}

# ==============================================================================
# Test
# ==============================================================================

run_tests() {
    log_step "Running tests..."
    
    # Backend tests
    log_step "Running backend tests..."
    if ! v test "${SRC_DIR}/" 2>&1; then
        log_error "Backend tests failed"
        return 1
    fi
    
    # Frontend tests
    log_step "Running frontend tests..."
    cd "$FE_DIR"
    if ! bun test 2>&1; then
        log_error "Frontend tests failed"
        return 1
    fi
    cd "$SCRIPT_DIR"
    
    log_success "✓ All tests passed"
}

# ==============================================================================
# Help
# ==============================================================================

show_help() {
    cat << EOF
${COLORS[bold]}Desktop Dashboard Build System${COLORS[reset]}

${COLORS[bold]}Usage:${COLORS[reset]} ./run.sh [command] [options]

${COLORS[bold]}Commands:${COLORS[reset]}
  ${COLORS[cyan]}dev${COLORS[reset]}       Start development mode (rebuilds frontend)
  ${COLORS[cyan]}build${COLORS[reset]}     Build frontend and backend
  ${COLORS[cyan]}build:fe${COLORS[reset]}  Build frontend only
  ${COLORS[cyan]}build:be${COLORS[reset]}  Build backend only
  ${COLORS[cyan]}run${COLORS[reset]}       Run existing build
  ${COLORS[cyan]}test${COLORS[reset]}      Run all tests
  ${COLORS[cyan]}clean${COLORS[reset]}     Remove all build artifacts
  ${COLORS[cyan]}help${COLORS[reset]}      Show this help

${COLORS[bold]}Options:${COLORS[reset]}
  ${COLORS[cyan]}--no-cache${COLORS[reset]}    Skip build cache
  ${COLORS[cyan]}--parallel${COLORS[reset]}    Enable parallel builds
  ${COLORS[cyan]}--verbose${COLORS[reset]}     Enable verbose output

${COLORS[bold]}Examples:${COLORS[reset]}
  ./run.sh                    # Start dev mode
  ./run.sh build              # Full build
  ./run.sh build --no-cache   # Full build without cache
  ./run.sh test               # Run all tests
  ./run.sh clean              # Clean everything

${COLORS[bold]}Environment Variables:${COLORS[reset]}
  V_COMPILER      V compiler (default: gcc)
  BUILD_TYPE      Build type: debug/release (default: release)
  SKIP_CACHE      Skip build cache: true/false
  PARALLEL_BUILD  Enable parallel builds: true/false

EOF
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local cmd="${1:-dev}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-cache)
                export SKIP_CACHE="true"
                ;;
            --parallel)
                export PARALLEL_BUILD="true"
                ;;
            --verbose)
                set -x
                ;;
            *)
                log_warn "Unknown option: $1"
                ;;
        esac
        shift
    done
    
    log_info "Command: $cmd"
    log_info "Directory: $SCRIPT_DIR"
    echo ""
    
    # Check dependencies first
    check_dependencies
    
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
            if [[ ! -f "$SCRIPT_DIR/${OUTPUT_BINARY}" ]]; then
                log_error "Binary not found. Run './run.sh build' first."
                exit 1
            fi
            if [[ ! -d "$FE_DIST_DIR" ]]; then
                log_error "Frontend dist not found. Run './run.sh build' first."
                exit 1
            fi
            log_step "Running application..."
            exec "./${OUTPUT_BINARY}"
            ;;
        test)
            run_tests
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
