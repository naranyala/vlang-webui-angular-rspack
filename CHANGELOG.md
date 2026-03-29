# Changelog

All notable changes to the Desktop Dashboard project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - 2026-03-29

### 🔒 Security

#### Fixed

**SEC-001: Weak Password Hashing** (`src/security/password.v`)
- **WHAT:** Replaced simple timestamp-based password hashing with multi-round key stretching
- **WHY:** The previous implementation used predictable timestamps as salt and a weak custom hash function, making passwords vulnerable to rainbow table and brute-force attacks
- **CHANGE:** 
  - Implemented 10,000 iteration key stretching
  - Added entropy-based salt generation from multiple sources
  - Added dual-hash function combination for increased complexity
  - Added password entropy calculation function

**SEC-002: Predictable Token Generation** (`src/security/token.v`)
- **WHAT:** Replaced time-based token generation with high-entropy random token generation
- **WHY:** Tokens generated from timestamps are predictable and can be guessed by attackers, enabling session hijacking and CSRF attacks
- **CHANGE:**
  - Implemented `generate_entropy_bytes()` using xorshift64* algorithm
  - Added hex encoding for token representation
  - Created separate functions for different token types (session, API key, CSRF)
  - CSRF tokens now use 32 bytes of entropy instead of timestamps

**SEC-003: No Rate Limiting** (`src/rate_limiter.v`)
- **WHAT:** Added comprehensive rate limiting middleware
- **WHY:** Without rate limiting, the API was vulnerable to DoS attacks, brute-force attacks, and resource exhaustion
- **CHANGE:**
  - New `RateLimiter` struct with per-minute, per-hour, and burst limits
  - Default configuration: 60 req/min, 1000 req/hour, 10 burst
  - Added `RateLimitResult` for detailed rate limit information
  - Added rate limit headers for client awareness (`X-RateLimit-*`)

**SEC-004: Missing CSRF Protection** (`src/security/token.v`)
- **WHAT:** Enhanced CSRF protection with single-use tokens
- **WHY:** Previous CSRF tokens were time-based and could be reused, enabling CSRF attacks
- **CHANGE:**
  - CSRF tokens now use high-entropy random generation
  - Tokens are single-use (marked as `used` after validation)
  - Added automatic cleanup of expired/used tokens

### 🏗️ Architecture

#### Changed

**Removed Unnecessary DI System** (`src/di.v` - DELETED)
- **WHAT:** Removed entire 350-line dependency injection system
- **WHY:** 
  - The DI system was over-engineered for V language capabilities
  - Empty `unsafe {}` blocks indicated incomplete implementation
  - V doesn't have runtime type reflection like Angular
  - Simple module-level instances work better in V
- **IMPACT:** -350 lines, simpler code, no functionality loss

**Simplified Communication System** (`src/communication.v`)
- **WHAT:** Reduced from 5 communication channels to 1
- **WHY:** Only `webui_bridge` was actually used; the other 4 channels (event_bus, shared_state, message_queue, broadcast) were dead code
- **CHANGE:** Removed unused channels, reduced from ~250 lines to ~100 lines
- **IMPACT:** -150 lines, clearer communication patterns

**Consolidated API Handlers** (`src/api_handlers.v`)
- **WHAT:** Extracted API handlers from `main.v` into dedicated module
- **WHY:** `main.v` had grown to 382 lines with all API handlers inline, making it hard to maintain
- **CHANGE:** Created separate `api_handlers.v` module with organized handler registration
- **IMPACT:** `main.v` reduced from 382 to 155 lines (60% reduction)

#### Added

**Storage Service Interface** (`src/storage_interface.v`)
- **WHAT:** Added `StorageService` interface for data persistence abstraction
- **WHY:** Enables swapping storage backends (JSON, SQLite, etc.) and improves testability
- **IMPACT:** Better separation of concerns, enables mocking for tests

**Validation Pipeline** (`src/validator.v`)
- **WHAT:** Created fluent validation API for request validation
- **WHY:** Validation logic was duplicated across 9+ API handlers with inconsistent patterns
- **CHANGE:** 
  - Created `Validator` struct with chainable validation methods
  - Added pre-built validators for User, Product, Order requests
  - Added `ValidationResult` with `first_error()` and `error_messages()` helpers
- **IMPACT:** Reduced validation code duplication, consistent error messages

**API Response Builder** (`src/api_response.v`)
- **WHAT:** Created type-safe API response helpers
- **WHY:** Manual JSON string concatenation was error-prone and inconsistent
- **CHANGE:** Added `ok()`, `created()`, `bad_request()`, `validation_error()`, etc.
- **IMPACT:** Consistent response format, fewer JSON encoding errors

### 🧹 Code Quality

#### Removed

**Duplicate Frontend Communication Services**
- **WHAT:** Removed duplicate `CommunicationService` from `frontend/src/app/services/`
- **WHY:** Same service existed in both `core/` and `app/services/` causing confusion
- **IMPACT:** Single source of truth for communication

**Dead Data Transform Services** (`frontend/src/app/services/data-transform/` - DELETED)
- **WHAT:** Removed entire directory with 12 files (~1,400 lines)
- **WHY:** Services were wrappers around native JavaScript functions with no actual usage
- **IMPACT:** -1,400 lines, simpler dependency tree

**Orphaned Frontend Directories** (`frontend-alt88/`, `frontend-alt99/`)
- **WHAT:** Removed two complete duplicate frontend implementations
- **WHY:** Experimental/legacy versions not referenced in build or documentation
- **IMPACT:** ~100MB saved, clearer project structure

**Empty Module Files** (`src/security.v`, `src/error.v`)
- **WHAT:** Deleted files containing only comments
- **WHY:** Added no functionality, just confusion
- **IMPACT:** Cleaner codebase

**Backup Files** (`*.origin`, `*.bak`, `*.old`)
- **WHAT:** Removed version control backup files from source tree
- **WHY:** Clutter, potential confusion about canonical files
- **IMPACT:** Added patterns to `.gitignore`

#### Changed

**Standardized Dependency Injection** (Frontend)
- **WHAT:** Converted all constructor injection to `inject()` function
- **WHY:** Angular 14+ recommends `inject()` for cleaner, more testable code
- **FILES:** `webui.service.ts`, `http.service.ts`, `update.service.ts`, `error-tracking.service.ts`, `webui-demo.component.ts`
- **BEFORE:**
  ```typescript
  constructor(private ngZone: NgZone) {}
  ```
- **AFTER:**
  ```typescript
  private readonly ngZone = inject(NgZone);
  constructor() {}
  ```

**Removed `any` Types** (Frontend)
- **WHAT:** Replaced `any[]` with proper generic types and interfaces
- **WHY:** `any` undermines TypeScript's type safety
- **FILES:** `data-table.component.ts`, `duckdb-*.component.ts`, `dashboard.component.ts`, `auth.component.ts`
- **BEFORE:**
  ```typescript
  @Input() items: any[] = [];
  (statsChange)="onStatsUpdate($any($event))"
  ```
- **AFTER:**
  ```typescript
  @Input() items: T[] = [];
  (statsChange)="onStatsUpdate($event)"
  ```

**Removed `console.log`** (Frontend)
- **WHAT:** Replaced direct `console.log` calls with `LoggerService`
- **WHY:** Consistent logging enables log aggregation and control
- **FILES:** `app.component.ts`, `webui-demo.component.ts`
- **BEFORE:**
  ```typescript
  console.log('Application Initialized')
  console.error('Error:', error)
  ```
- **AFTER:**
  ```typescript
  this.logger.info('Application Initialized')
  this.logger.error('Error:', error)
  ```

**Removed Redundant Methods** (Backend)
- **WHAT:** Removed `is_initialized()` and empty `dispose()` methods from all services
- **WHY:** Methods were never called and added no value
- **FILES:** All service files (`config_service.v`, `logger_service.v`, `cache_service.v`, etc.)
- **IMPACT:** -40 lines of dead code

### 📁 Project Structure

#### Changed

**Reorganized Source Directory**
- **WHAT:** Removed empty directories, moved orphaned files
- **WHY:** Cleaner structure, files in logical locations
- **CHANGES:**
  - Removed empty `src/network/`, `src/process/`, `src/system/`
  - Moved `web/index.html` → `docs/demos/battery_monitor.html`
  - Moved `users.db` → `data/users.db`
  - Created `data/` directory for application data

**Updated `.gitignore`**
- **WHAT:** Added comprehensive ignore patterns
- **WHY:** Prevent committing generated/secret files
- **ADDED:**
  ```gitignore
  # Backup files
  *.bak
  *.origin
  *.old
  *.tmp
  
  # Environment
  .env
  .env.local
  .env.*.local
  
  # Data
  data/*.db
  data/*.json
  *.db
  
  # Logs
  logs/
  *.log
  
  # Test coverage
  coverage/
  ```

### 📚 Documentation

#### Added

**LICENSE File**
- **WHAT:** Added MIT LICENSE file
- **WHY:** README claimed MIT license but file didn't exist (legal ambiguity)

**Environment Configuration Template** (`.env.example`)
- **WHAT:** Created comprehensive environment variable template
- **WHY:** Developers didn't know what environment variables were needed
- **INCLUDES:** 30+ documented variables for app, server, database, security, logging, cache

**Updated README.md**
- **WHAT:** Comprehensive README update
- **WHY:** Documentation didn't match implementation
- **CHANGES:**
  - Updated storage description (JSON, not DuckDB)
  - Added security features section
  - Added project structure diagram
  - Added configuration instructions

#### Changed

**Fixed Documentation Mismatch**
- **WHAT:** Updated documentation to accurately describe JSON storage
- **WHY:** README mentioned DuckDB but implementation used JSON files
- **IMPACT:** Accurate documentation prevents confusion

---

## [Previous] - 2026-03-16

### Summary

Previous changes included initial security audit fixes, test infrastructure setup, and CI/CD pipeline configuration. See `docs/archive/` for historical changelogs.

---

## Impact Summary

### Lines of Code

| Category | Before | After | Change |
|----------|--------|-------|--------|
| Dead Code Removed | - | - | ~2,200 lines |
| Security Code Added | - | - | +400 lines |
| Abstraction Code Added | - | - | +240 lines |
| **Net Change** | - | - | **-1,560 lines** |

### Security Improvements

| Vulnerability | Before | After |
|--------------|--------|-------|
| Password Hashing | Timestamp-based salt | 10,000-iteration key stretching |
| Token Generation | Predictable timestamps | High-entropy random bytes |
| Rate Limiting | None | Per-minute/hour/burst limits |
| CSRF Protection | Time-based tokens | Single-use random tokens |
| Input Validation | Inconsistent | Comprehensive sanitization |

### Code Quality Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| `any` type usages | 61 | ~45 | -26% |
| Constructor injection | 8 files | 0 files | -100% |
| `console.log` usage | 36 | ~30 | -17% |
| Duplicate services | 2 CommunicationService | 1 | -50% |
| Test coverage | ~30% | ~30% | No change |

### Build Performance

| Metric | Before | After |
|--------|--------|-------|
| Backend compile time | ~8s | ~8s |
| Frontend compile time | 2.47s | 2.53s |
| Bundle size | 5.6M | 5.6M |

---

## Migration Guide

### For Developers

1. **Update Environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

2. **Password Migration:**
   - Existing passwords will need to be re-hashed on next login
   - New passwords use improved hashing automatically

3. **API Changes:**
   - Rate limit headers now included in responses
   - CSRF tokens required for all state-changing operations

### For Maintainers

1. **Code Style:**
   - Use `inject()` for DI in Angular components
   - Avoid `any` types; use proper interfaces
   - Use `LoggerService` instead of `console.log`

2. **Security:**
   - All new API endpoints must include rate limiting
   - CSRF tokens required for POST/PUT/DELETE/PATCH
   - Input validation required for all user input

---

## See Also

- [Architecture Documentation](docs/01-ARCHITECTURE.md)
- [Security Audit Report](audit/README.md)
- [API Reference](docs/04-API_REFERENCE.md)
- [Testing Guide](docs/testing/TESTING_IMPROVEMENT_REPORT.md)
