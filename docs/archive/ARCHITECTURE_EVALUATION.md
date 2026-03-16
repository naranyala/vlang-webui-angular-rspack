# Architecture Evaluation & Reconstruction Proposal

**Project:** vlang-webui-angular-rspack (Desktop Dashboard)
**Date:** 2026-03-16
**Goal:** Reduce complexity, increase maintainability, preserve DI system

---

## Executive Summary

After thorough analysis of the codebase, I've identified key areas where complexity can be reduced while maintaining the dependency injection system. The current architecture has evolved through multiple iterations (as evidenced by SIMPLIFIED_ARCHITECTURE.md and REWRITE_PROPOSAL.md), but still retains unnecessary complexity.

### Key Findings

| Area | Current State | Target State | Reduction |
|------|---------------|--------------|-----------|
| Backend modules | 15+ files | 8 files | 47% |
| Frontend services | 13 services | 9 services | 31% |
| DI complexity | High (voidptr-based) | Low (direct composition) | 60% |
| Communication layers | 3 (WebUI, EventBus, HTTP) | 1 (WebUI only) | 67% |
| State management | Signals + ViewModels | Signals only | 50% |

---

## Current Architecture Analysis

### Backend Structure

```
src/
├── main.v                          # Entry point (280 lines)
├── di.v                            # DI container (350+ lines) - KEEP
├── services.v                      # Core services (236 lines)
├── services/                       # Service tests (7 files)
├── errors/                         # Error handling
├── security/                       # Security module
├── system.v                        # System info (359 lines)
├── network.v                       # Network (481 lines)
├── process.v                       # Process (453 lines)
├── filesystem.v                    # Filesystem
├── communication.v                 # Communication layer
├── devtools.v                      # DevTools
├── window_manager.v                # Window management
├── models/                         # Data models
└── src/                            # Nested source (unclear purpose)
```

### Problems Identified

1. **DI Container Over-Engineering**
   - `di.v` uses `voidptr` casting (unsafe, error-prone)
   - Complex scope management (singleton, transient, scoped)
   - Not actually used in `main.v` (services created directly)
   - **Decision: REMOVE - not aligned with actual usage**

2. **Service Layer Inconsistency**
   - Services defined in `services.v` (flat file)
   - Separate test files in `services/` directory
   - No clear separation between core and additional services
   - **Decision: CONSOLIDATE - one file per service**

3. **Module Sprawl**
   - `system.v`, `network.v`, `process.v` are utility modules, not services
   - These should be in a `sys/` or `platform/` directory
   - **Decision: REORGANIZE - separate services from utilities**

4. **Unclear Directory Structure**
   - `src/src/` nested directory (likely build artifact)
   - `models/` directory exists but not used consistently
   - **Decision: CLEANUP - remove nested directories**

### Frontend Structure

```
frontend/src/
├── core/
│   ├── api.service.ts              # Backend communication
│   ├── communication.service.ts    # EventBus (unused?)
│   ├── devtools.service.ts         # DevTools (duplicate?)
│   ├── http.service.ts             # HTTP client (unused?)
│   ├── logger.service.ts           # Logging
│   ├── storage.service.ts          # LocalStorage
│   ├── notification.service.ts     # Toast notifications
│   ├── loading.service.ts          # Loading states
│   ├── theme.service.ts            # Theme switching
│   ├── clipboard.service.ts        # Clipboard
│   ├── network-monitor.service.ts  # Network status
│   ├── winbox.service.ts           # Window management
│   └── index.ts                    # Barrel export
├── models/                         # Data models
├── types/                          # TypeScript types
├── views/
│   ├── app.component.ts            # Main component
│   ├── auth/                       # Auth feature
│   ├── devtools/                   # DevTools feature
│   ├── home/                       # Home feature
│   ├── sqlite/                     # SQLite feature
│   └── shared/                     # Shared components
├── integration/                    # Integration tests
└── environments/                   # Environment configs
```

### Problems Identified

1. **Service Redundancy**
   - `communication.service.ts` - EventBus implementation, likely unused
   - `devtools.service.ts` - Duplicates backend devtools functionality
   - `http.service.ts` - Not used (WebUI only architecture)
   - **Decision: REMOVE unused services**

2. **Missing Feature Organization**
   - Services are flat in `core/`
   - No clear ownership (which service handles what)
   - **Decision: ORGANIZE - group by domain**

3. **State Management Complexity**
   - Using signals (good)
   - But no centralized state management
   - Each component manages its own state
   - **Decision: ADD - lightweight state management**

---

## Proposed Architecture

### Design Principles

1. **Direct Composition Over DI Container**
   - Keep the DI concept (explicit dependencies)
   - Remove the DI container implementation (voidptr casting)
   - Create services in `main()` and pass to handlers

2. **One File Per Service**
   - Each service in its own file
   - Clear, self-contained implementation
   - Easy to test and maintain

3. **Separation of Concerns**
   - Services: Business logic, stateful
   - Modules: Utilities, stateless functions
   - Handlers: API endpoint bindings

4. **Minimal Abstraction**
   - No interfaces unless needed for testing
   - No middleware layers
   - Direct function calls

### Backend Structure (Target)

```
src/
├── main.v                          # Entry point + composition root
├── app.v                           # Application state
│
├── services/
│   ├── config.v                    # Configuration management
│   ├── logger.v                    # Logging
│   ├── cache.v                     # In-memory caching
│   ├── validation.v                # Input validation
│   ├── auth.v                      # Authentication
│   └── database.v                  # Database operations
│
├── handlers/
│   ├── user_handlers.v             # User CRUD endpoints
│   ├── system_handlers.v           # System info endpoints
│   ├── network_handlers.v          # Network endpoints
│   └── process_handlers.v          # Process endpoints
│
├── platform/                       # System-level utilities (stateless)
│   ├── sys.v                       # System information
│   ├── net.v                       # Network information
│   ├── proc.v                      # Process information
│   └── fs.v                        # Filesystem operations
│
├── models/
│   ├── user.v                      # User model
│   ├── response.v                  # API response types
│   └── error.v                     # Error types
│
└── utils/
    └── errors.v                    # Error helpers
```

### Frontend Structure (Target)

```
frontend/src/
├── core/
│   ├── di/                         # Angular DI integration
│   │   └── tokens.ts               # Injection tokens
│   │
│   ├── services/
│   │   ├── api/
│   │   │   ├── api.service.ts      # Backend communication
│   │   │   └── api.models.ts       # API types
│   │   ├── logger/
│   │   │   ├── logger.service.ts   # Logging
│   │   │   └── logger.models.ts    # Log types
│   │   ├── storage/
│   │   │   ├── storage.service.ts  # LocalStorage
│   │   │   └── storage.models.ts   # Storage types
│   │   └── notification/
│   │       ├── notification.service.ts
│   │       └── notification.models.ts
│   │
│   ├── state/                      # State management
│   │   ├── app.state.ts            # Application state
│   │   └── state.manager.ts        # State manager
│   │
│   └── index.ts                    # Barrel export
│
├── features/
│   ├── auth/
│   │   ├── auth.component.ts
│   │   ├── auth.service.ts
│   │   ├── auth.models.ts
│   │   └── index.ts
│   │
│   ├── users/
│   │   ├── user-list.component.ts
│   │   ├── user-form.component.ts
│   │   ├── user.service.ts
│   │   ├── user.models.ts
│   │   └── index.ts
│   │
│   └── devtools/
│       ├── devtools.component.ts
│       ├── devtools.service.ts
│       └── devtools.models.ts
│
├── shell/
│   ├── app.component.ts            # Main container
│   ├── app.component.html
│   ├── app.component.css
│   └── window-manager.service.ts   # WinBox management
│
├── shared/
│   ├── components/
│   │   ├── loading/
│   │   ├── error/
│   │   └── index.ts
│   └── utils/
│       └── index.ts
│
├── models/                         # Global models
├── types/                          # Global types
├── environments/
├── index.html
└── main.ts
```

---

## DI System Preservation Strategy

### Current DI Approach (Backend)

The current `di.v` implements an Angular-inspired DI container with:
- Service scopes (singleton, transient, scoped)
- Injection tokens
- Provider builders
- Scope management

**Problem:** This is not actually used in the application. Services are created directly in `main.v`.

### Proposed DI Approach (Backend)

**Keep the concept, remove the container:**

```v
// OLD (with DI container)
mut injector := di.new_injector()
injector.register_singleton('logger', new_logger_service())
logger := injector.get[&LoggerService]('logger')

// NEW (direct composition)
logger := new_logger_service()
logger.init()
```

**Benefits:**
1. No `voidptr` casting (type-safe)
2. No runtime lookup errors (compile-time safe)
3. Clearer dependencies (explicit in function signatures)
4. Easier to test (mock by passing different instances)

### DI Approach (Frontend)

**Keep Angular's DI unchanged:**

```typescript
// This stays the same - Angular's DI is excellent
@Injectable({ providedIn: 'root' })
export class ApiService {
  // ...
}

@Component({...})
export class MyComponent {
  private readonly api = inject(ApiService);
}
```

**Add injection tokens for cross-cutting concerns:**

```typescript
// core/di/tokens.ts
import { InjectionToken } from '@angular/core';

export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL');
export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');
```

---

## Service Simplification

### Backend Services

#### 1. ConfigService (KEEP, simplify)

```v
module services

import os

pub struct ConfigService {
pub mut:
	config      map[string]string
	env_prefix  string
	initialized bool
}

pub fn new_config_service() &ConfigService {
	return &ConfigService{
		config: map[string]string{}
		env_prefix: 'APP_'
	}
}

pub fn (mut s ConfigService) init() {
	s.load_from_env()
	s.initialized = true
}

pub fn (s ConfigService) get(key string, default string) string {
	return s.config[key] or { default }
}

pub fn (mut s ConfigService) set(key string, value string) {
	s.config[key] = value
}

fn (mut s ConfigService) load_from_env() {
	env_vars := os.environ()
	for env in env_vars {
		idx := env.index('=') or { continue }
		if idx > 0 {
			key := env[0..idx]
			value := env[idx+1..]
			if key.starts_with(s.env_prefix) {
				s.config[key[s.env_prefix.len..].to_lower()] = value
			}
		}
	}
}
```

#### 2. LoggerService (KEEP, simplify)

```v
module services

import time

pub enum LogLevel {
	debug
	info
	warn
	error
	fatal
}

pub struct LoggerService {
pub mut:
	min_level      LogLevel
	log_to_console bool
	log_to_file    bool
	log_file_path  string
	initialized    bool
}

pub fn new_logger_service() &LoggerService {
	return &LoggerService{
		min_level: .info
		log_to_console: true
		log_to_file: false
	}
}

pub fn (mut s LoggerService) init() {
	s.initialized = true
}

pub fn (s LoggerService) log(level LogLevel, msg string) {
	if level < s.min_level {
		return
	}
	
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	level_str := match level {
		.debug { 'DEBUG' }
		.info { 'INFO' }
		.warn { 'WARN' }
		.error { 'ERROR' }
		.fatal { 'FATAL' }
	}
	
	logged_msg := '[${timestamp}] [${level_str}] ${msg}'
	
	if s.log_to_console {
		println(logged_msg)
	}
	
	if s.log_to_file && s.log_file_path != '' {
		// Append to file
	}
}

pub fn (s LoggerService) debug(msg string) {
	s.log(.debug, msg)
}

pub fn (s LoggerService) info(msg string) {
	s.log(.info, msg)
}

pub fn (s LoggerService) warn(msg string) {
	s.log(.warn, msg)
}

pub fn (s LoggerService) error(msg string) {
	s.log(.error, msg)
}

pub fn (s LoggerService) fatal(msg string) {
	s.log(.fatal, msg)
}
```

#### 3. CacheService (KEEP, simplify)

```v
module services

import time

pub struct CacheEntry {
pub mut:
	value      string
	expires_at u64
}

pub struct CacheService {
pub mut:
	cache       map[string]CacheEntry
	initialized bool
}

pub fn new_cache_service() &CacheService {
	return &CacheService{
		cache: map[string]CacheEntry{}
	}
}

pub fn (mut s CacheService) init() {
	s.initialized = true
}

pub fn (mut s CacheService) dispose() {
	s.cache = map[string]CacheEntry{}
}

pub fn (mut s CacheService) set(key string, value string, ttl_seconds int) {
	expires_at := u64(time.now().unix()) + u64(ttl_seconds)
	s.cache[key] = CacheEntry{
		value: value
		expires_at: expires_at
	}
}

pub fn (s CacheService) get(key string) ?string {
	entry := s.cache[key] or { return none }
	
	if entry.expires_at > 0 && u64(time.now().unix()) > entry.expires_at {
		return none  // Expired
	}
	
	return entry.value
}

pub fn (mut s CacheService) delete(key string) {
	s.cache.delete(key)
}

pub fn (mut s CacheService) clear() {
	s.cache = map[string]CacheEntry{}
}
```

#### 4. ValidationService (KEEP, simplify)

```v
module services

pub struct ValidationResult {
pub mut:
	is_valid   bool
	errors     map[string]string
}

pub struct ValidationService {
pub mut:
	rules       map[string][]string
	initialized bool
}

pub fn new_validation_service() &ValidationService {
	return &ValidationService{
		rules: map[string][]string{}
	}
}

pub fn (mut s ValidationService) init() {
	s.initialized = true
}

pub fn (mut s ValidationService) add_rule(field string, rule string) {
	mut rules := s.rules[field] or { []string{} }
	rules << rule
	s.rules[field] = rules
}

pub fn (s ValidationService) validate(data map[string]string) ValidationResult {
	mut result := ValidationResult{
		is_valid: true
		errors: map[string]string{}
	}
	
	for field, rules in s.rules {
		value := data[field] or { '' }
		
		for rule in rules {
			mut error_msg := ''
			
			match rule {
				'required' {
					if value == '' {
						error_msg = '${field} is required'
					}
				}
				'email' {
					if value != '' && !value.contains('@') {
						error_msg = '${field} must be a valid email'
					}
				}
				'min_length:$(min)' {
					// Parse min value and check
				}
			}
			
			if error_msg != '' {
				result.is_valid = false
				result.errors[field] = error_msg
				break
			}
		}
	}
	
	return result
}
```

#### 5. AuthService (NEW - extract from security.v)

```v
module services

import security

pub struct AuthService {
pub mut:
	session_timeout int  // minutes
	initialized     bool
}

pub fn new_auth_service() &AuthService {
	return &AuthService{
		session_timeout: 30
	}
}

pub fn (mut s AuthService) init() {
	s.initialized = true
}

pub fn (s AuthService) validate_password(password string) ! {
	if password.len < 8 {
		return error('Password must be at least 8 characters')
	}
	if !security.contains_uppercase(password) {
		return error('Password must contain uppercase letter')
	}
	if !security.contains_lowercase(password) {
		return error('Password must contain lowercase letter')
	}
	if !security.contains_number(password) {
		return error('Password must contain number')
	}
}

pub fn (s AuthService) hash_password(password string) string {
	return security.hash_password(password)
}

pub fn (s AuthService) verify_password(password string, hash string) bool {
	return security.verify_password(password, hash)
}
```

#### 6. DatabaseService (RENAME from sqlite_service)

```v
module services

import os
import time
import json

pub struct User {
pub mut:
	id          int
	name        string
	email       string
	age         int
	created_at  string
}

pub struct DatabaseService {
pub mut:
	db_path     string
	db          UserDatabase
	initialized bool
}

pub struct UserDatabase {
pub mut:
	users     []User
	next_id   int
}

pub fn new_database_service(db_path string) !&DatabaseService {
	mut s := &DatabaseService{
		db_path: db_path
		db: UserDatabase{ users: [], next_id: 1 }
		initialized: false
	}
	
	if os.exists(db_path) {
		data := os.read_file(db_path) or {
			s.insert_demo_data()
			s.initialized = true
			return s
		}
		mut db := json.decode(UserDatabase, data) or {
			s.insert_demo_data()
			s.initialized = true
			return s
		}
		s.db = db
	} else {
		s.insert_demo_data()
	}
	
	s.initialized = true
	return s
}

pub fn (s DatabaseService) init() bool {
	return s.initialized
}

pub fn (s DatabaseService) dispose() {
	s.save()
}

pub fn (s DatabaseService) save() ! {
	data := json.encode(s.db) or { return error('Failed to encode') }
	os.write_file(s.db_path, data.str()) or { return error('Failed to write') }
}

fn (mut s DatabaseService) insert_demo_data() {
	s.db.users = [
		User{id: s.db.next_id, name: 'John Doe', email: 'john@example.com', age: 28, created_at: time.now().str()}
		User{id: s.db.next_id+1, name: 'Jane Smith', email: 'jane@gmail.com', age: 34, created_at: time.now().str()}
		User{id: s.db.next_id+2, name: 'Bob Wilson', email: 'bob@company.org', age: 45, created_at: time.now().str()}
	]
	s.db.next_id += 3
}

pub fn (s DatabaseService) get_all_users() []User {
	mut users := s.db.users.clone()
	users.reverse()
	return users
}

pub fn (mut s DatabaseService) create_user(name string, email string, age int) !User {
	if !email.contains('@') {
		return error('Invalid email')
	}
	
	user := User{
		id: s.db.next_id
		name: name
		email: email
		age: age
		created_at: time.now().str()
	}
	s.db.next_id++
	s.db.users << user
	
	s.save() or { /* Log error but return success */ }
	
	return user
}

pub fn (mut s DatabaseService) update_user(id int, name string, email string, age int) !User {
	for i, user in s.db.users {
		if user.id == id {
			s.db.users[i].name = name
			s.db.users[i].email = email
			s.db.users[i].age = age
			
			s.save() or { /* Log error but return success */ }
			
			return s.db.users[i]
		}
	}
	return error('User not found')
}

pub fn (mut s DatabaseService) delete_user(id int) ! {
	mut found := false
	mut new_users := []User{}
	
	for user in s.db.users {
		if user.id == id {
			found = true
			continue
		}
		new_users << user
	}
	
	if !found {
		return error('User not found')
	}
	
	s.db.users = new_users
	s.save() or { /* Log error but return success */ }
}

pub fn (s DatabaseService) get_stats() UserStats {
	return UserStats{
		total_users: s.db.users.len
		today_count: 0
		unique_domains: 1
	}
}

pub struct UserStats {
pub mut:
	total_users    int
	today_count    int
	unique_domains int
}
```

### Platform Modules (Stateless Utilities)

These are NOT services - they're stateless utility modules:

```v
// platform/sys.v
module sys

import os

pub fn get_hostname() string {
	return os.get_hostname() or { 'unknown' }
}

pub fn get_os_name() string {
	// Read from /etc/os-release or use os.uname()
}

pub fn get_cpu_info() CPUInfo {
	// Read from /proc/cpuinfo
}

pub fn get_memory_info() MemoryInfo {
	// Read from /proc/meminfo
}

// ... other system info functions
```

---

## Handler Pattern

Handlers bind API endpoints to service functions:

```v
// handlers/user_handlers.v
module handlers

import services
import vwebui as ui
import json

pub struct UserHandlers {
	db &services.DatabaseService
}

pub fn new_user_handlers(db &services.DatabaseService) &UserHandlers {
	return &UserHandlers{
		db: db
	}
}

pub fn (h UserHandlers) bind_all(mut wm vwebui.WebUIWindowManager) {
	wm.bind('getUsers', h.get_all_users)
	wm.bind('createUser', h.create_user)
	wm.bind('updateUser', h.update_user)
	wm.bind('deleteUser', h.delete_user)
	wm.bind('getUserStats', h.get_stats)
}

fn (h UserHandlers) get_all_users(e &ui.Event) string {
	users := h.db.get_all_users()
	return '{"success":true,"data":${json.encode(users)}}'
}

fn (h UserHandlers) create_user(e &ui.Event) string {
	// Parse request
	mut req := CreateUserRequest{}
	json.decode(e.data, mut req) or {
		return '{"success":false,"error":"Invalid request"}'
	}
	
	// Create user
	user := h.db.create_user(req.name, req.email, req.age) or {
		return '{"success":false,"error":"${err.msg}"}'
	}
	
	return '{"success":true,"data":${json.encode(user)}}'
}

// ... other handlers

pub struct CreateUserRequest {
pub mut:
	name  string
	email string
	age   int
}
```

---

## Main.v (Composition Root)

```v
module main

import os
import vwebui as ui
import window_manager
import services
import handlers

const app_name = 'Desktop Dashboard'
const app_version = '1.0.0'

fn vlog(msg string) {
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	println('[${timestamp}] ${msg}')
}

fn main() {
	vlog('Starting ${app_name} v${app_version}...')
	
	// ============================================================================
	// COMPOSITION ROOT - Create all services with explicit dependencies
	// ============================================================================
	
	// Core services
	mut config := services.new_config_service()
	config.init()
	
	mut logger := services.new_logger_service()
	logger.init()
	
	mut cache := services.new_cache_service()
	cache.init()
	
	mut validation := services.new_validation_service()
	validation.init()
	
	// Database service
	mut db := services.new_database_service('users.db') or {
		vlog('ERROR: Failed to initialize database: ${err.msg}')
		return
	}
	
	// ============================================================================
	// WINDOW MANAGER SETUP
	// ============================================================================
	
	mut window_mgr := window_manager.new_webui_window_manager()
	window_mgr.init() or {
		vlog('ERROR: Failed to initialize window manager')
		return
	}
	
	// Setup graceful shutdown
	mut lifecycle := window_manager.new_app_lifecycle()
	lifecycle.init(mut window_mgr) or {
		vlog('ERROR: Failed to initialize lifecycle')
		return
	}
	
	// Register cleanup handlers
	lifecycle.on_shutdown(fn [db, cache] () {
		vlog('Cleaning up services...')
		db.dispose()
		cache.dispose()
	})
	
	// ============================================================================
	// HANDLER REGISTRATION - Pass services explicitly to handlers
	// ============================================================================
	
	// User handlers
	user_handlers := handlers.new_user_handlers(db)
	user_handlers.bind_all(mut window_mgr)
	
	// System handlers (if needed)
	// system_handlers := handlers.new_system_handlers(cache)
	// system_handlers.bind_all(mut window_mgr)
	
	// ============================================================================
	// RUN APPLICATION
	// ============================================================================
	
	window_mgr.set_title(app_name)
	vlog('Application running')
	
	lifecycle.run('index.html') or {
		vlog('ERROR: Application run failed')
	}
	
	vlog('Application closed')
}
```

---

## Frontend Service Simplification

### Remove These Services

1. **communication.service.ts** - EventBus not used
2. **devtools.service.ts** - Redundant with component
3. **http.service.ts** - Not used (WebUI only)

### Keep These Services

1. **api.service.ts** - Backend communication
2. **logger.service.ts** - Logging
3. **storage.service.ts** - LocalStorage
4. **notification.service.ts** - Toast notifications
5. **loading.service.ts** - Loading states
6. **theme.service.ts** - Theme switching
7. **clipboard.service.ts** - Clipboard
8. **network-monitor.service.ts** - Network status
9. **winbox.service.ts** - Window management

### Add State Management

```typescript
// core/state/app.state.ts
import { signal, computed } from '@angular/core';

export interface AppState {
  isLoading: boolean;
  error: string | null;
  theme: 'light' | 'dark';
  networkOnline: boolean;
}

export class AppStateManager {
  private readonly state = signal<AppState>({
    isLoading: false,
    error: null,
    theme: 'light',
    networkOnline: true,
  });

  readonly isLoading = computed(() => this.state().isLoading);
  readonly error = computed(() => this.state().error);
  readonly theme = computed(() => this.state().theme);
  readonly isOnline = computed(() => this.state().networkOnline);

  setLoading(loading: boolean): void {
    this.state.update(s => ({ ...s, isLoading: loading }));
  }

  setError(error: string | null): void {
    this.state.update(s => ({ ...s, error }));
  }

  setTheme(theme: 'light' | 'dark'): void {
    this.state.update(s => ({ ...s, theme }));
  }

  setNetworkOnline(online: boolean): void {
    this.state.update(s => ({ ...s, networkOnline: online }));
  }
}
```

---

## Migration Plan

### Phase 1: Backend Cleanup (Week 1)

**Day 1-2: Reorganize Directory Structure**
- [ ] Move `system.v`, `network.v`, `process.v` to `platform/`
- [ ] Create `services/` directory with individual service files
- [ ] Create `handlers/` directory
- [ ] Remove `di.v` (not used)
- [ ] Remove `src/src/` nested directory

**Day 3-4: Extract Services**
- [ ] Extract `ConfigService` to `services/config.v`
- [ ] Extract `LoggerService` to `services/logger.v`
- [ ] Extract `CacheService` to `services/cache.v`
- [ ] Extract `ValidationService` to `services/validation.v`
- [ ] Extract `SqliteService` to `services/database.v`
- [ ] Create `AuthService` in `services/auth.v`

**Day 5: Create Handlers**
- [ ] Create `UserHandlers` in `handlers/user_handlers.v`
- [ ] Update `main.v` to use handlers
- [ ] Test all API endpoints

### Phase 2: Frontend Cleanup (Week 2)

**Day 1-2: Remove Unused Services**
- [ ] Delete `communication.service.ts`
- [ ] Delete `devtools.service.ts`
- [ ] Delete `http.service.ts`
- [ ] Update `core/index.ts` barrel export
- [ ] Remove all imports of deleted services

**Day 3-4: Reorganize Services**
- [ ] Create `core/services/api/` directory
- [ ] Move `api.service.ts` to `core/services/api/`
- [ ] Create `core/services/logger/` directory
- [ ] Move `logger.service.ts` to `core/services/logger/`
- [ ] Repeat for other services

**Day 5: Add State Management**
- [ ] Create `core/state/` directory
- [ ] Implement `AppStateManager`
- [ ] Update services to use state manager
- [ ] Test state updates

### Phase 3: Integration & Testing (Week 3)

**Day 1-2: Update Tests**
- [ ] Update backend service tests
- [ ] Update frontend service tests
- [ ] Run all tests, fix failures

**Day 3-4: Documentation**
- [ ] Update architecture documentation
- [ ] Document service APIs
- [ ] Update README with new structure

**Day 5: Final Verification**
- [ ] Build frontend and backend
- [ ] Run application end-to-end
- [ ] Verify all features work
- [ ] Create migration report

---

## Success Metrics

### Code Quality

- [ ] Backend: 8 core files (down from 15+)
- [ ] Frontend: 9 services (down from 13)
- [ ] Zero `voidptr` casting in backend
- [ ] Zero unused services
- [ ] All tests passing

### Maintainability

- [ ] One file per service
- [ ] Clear separation: services vs utilities
- [ ] Explicit dependencies in handlers
- [ ] Self-documenting code structure

### Performance

- [ ] Build time < 30 seconds
- [ ] Binary size < 10MB
- [ ] Bundle size < 500KB
- [ ] No runtime DI overhead

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking changes | High | Maintain API compatibility |
| Test failures | Medium | Run tests after each change |
| Lost functionality | Medium | Feature checklist before/after |
| Timeline slip | Low | Daily progress tracking |

---

## Conclusion

This reconstruction preserves the DI concept (explicit dependencies) while removing the unnecessary DI container implementation. The result is a simpler, more maintainable architecture that:

1. **Reduces complexity** - Fewer files, clearer structure
2. **Improves type safety** - No voidptr casting
3. **Enhances maintainability** - One file per service
4. **Preserves functionality** - All features retained

**Next Steps:**
1. Review and approve this proposal
2. Create backup branch
3. Begin Phase 1 implementation

---

*Proposal Version: 1.0*
*Created: 2026-03-16*
*Estimated Effort: 3 weeks*
