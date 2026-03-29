# Dependency Injection Guide

Comprehensive guide to dependency injection systems in both backend (V) and frontend (Angular).

## Table of Contents

1. [Overview](#overview)
2. [Backend DI System](#backend-di-system)
3. [Frontend DI System](#frontend-di-system)
4. [Service Catalog](#service-catalog)
5. [Best Practices](#best-practices)

---

## Overview

This project implements dependency injection on both tiers using different approaches:

| Aspect | Backend (V) | Frontend (Angular) |
|--------|-------------|-------------------|
| Pattern | Direct Composition | Angular Built-in DI |
| Registration | Direct instantiation | providedIn: 'root' |
| Lifecycles | Manual management | Singleton (default) |
| Resolution | Direct variable access | Constructor injection |
| Interfaces | Struct definitions | TypeScript interfaces |

---

## Backend DI System

### Direct Composition Pattern

The backend uses direct composition instead of a DI container. Services are created in main() and passed to components that need them.

### Service Creation

```v
fn main() {
    // Create services directly
    config := new_config_service()
    config.init()

    logger := new_logger_service()
    logger.init()

    cache := new_cache_service()
    cache.init()

    validation := new_validation_service()
    validation.init()

    db := new_sqlite_service('users.db') or {
        println('Failed to initialize database')
        return
    }
}
```

### Service Passing to Handlers

```v
// Pass services to handlers
window_mgr.bind('getUsers', fn [db] (e &ui.Event) string {
    users := db.get_all_users()
    return '{"success":true,"data":${json.encode(users)}}'
})

window_mgr.bind('createUser', fn [mut db] (e &ui.Event) string {
    user_result := db.create_user('Name', 'email@test.com', 25) or {
        return '{"success":false,"error":"${err.msg}"}'
    }
    return '{"success":true,"data":${json.encode(user_result)}}'
})
```

### Service Lifecycle Management

```v
// Setup graceful shutdown
mut lifecycle := window_manager.new_app_lifecycle()
lifecycle.init(mut window_mgr) or {
    return
}

// Register cleanup handlers
lifecycle.on_shutdown(fn [db, cache] () {
    println('Cleaning up services...')
    db.dispose()
    cache.dispose()
})
```

---

## Frontend DI System

### Angular Built-in DI

The frontend uses Angular's built-in dependency injection with providedIn: 'root' for singleton services.

### Service Definition

```typescript
import { Injectable, signal, computed } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly defaultTimeout = 30000;
  
  // Internal state signals
  private readonly loading = signal(false);
  private readonly error = signal<string | null>(null);
  
  // Public readonly signals
  readonly isLoading = this.loading.asReadonly();
  readonly error$ = this.error.asReadonly();
  
  // Computed signals
  readonly hasError = computed(() => this.error() !== null);
  readonly isReady = computed(() => !this.loading() && this.error() === null);
  
  async call<T>(functionName: string, args: unknown[] = []): Promise<T> {
    this.loading.set(true);
    this.error.set(null);
    // ... implementation
  }
}
```

### Service Injection

```typescript
import { Component, inject } from '@angular/core';
import { ApiService } from './core/api.service';
import { LoggerService } from './core/logger.service';
import { NotificationService } from './core/notification.service';

@Component({
  selector: 'app-example',
  template: `...`,
})
export class ExampleComponent {
  // Using inject() function
  private readonly api = inject(ApiService);
  private readonly logger = inject(LoggerService);
  private readonly notifications = inject(NotificationService);
  
  async loadData() {
    try {
      const data = await this.api.callOrThrow('getData');
      this.logger.info('Data loaded', data);
    } catch (error) {
      this.notifications.error('Failed to load data');
    }
  }
}
```

### Signal-Based Services

```typescript
@Injectable({ providedIn: 'root' })
export class StorageService {
  private readonly prefix = 'app:';
  private readonly memoryStore = new Map<string, StorageEntry<unknown>>();
  
  // Signal-based state tracking
  private readonly keys = signal<Set<string>>(new Set());
  private readonly stats = signal<StorageStats>({
    count: 0,
    memoryCount: 0,
    localStorageCount: 0,
  });
  
  // Public readonly signals
  readonly allKeys = this.keys.asReadonly();
  readonly storageStats = this.stats.asReadonly();
  
  // Computed signals
  readonly count = computed(() => this.stats().count);
  readonly hasItems = computed(() => this.stats().count > 0);
  readonly isEmpty = computed(() => this.stats().count === 0);
  
  get<T>(key: string, defaultValue?: T): T | null {
    // Implementation
  }
  
  set<T>(key: string, value: T, options?: { ttl?: number }): void {
    // Implementation
  }
}
```

---

## Service Catalog

### Backend Services

#### ConfigService

Manages application configuration.

```v
config := new_config_service()
config.init()

// Get values
value := config.get_string('key', 'default')
int_val := config.get_int('number', 0)
bool_val := config.get_bool('flag', false)

// Set values
config.set('key', 'value')
```

**File:** src/services.v
**Lifecycle:** Application lifetime
**Dependencies:** None

#### LoggerService

Provides structured logging.

```v
logger := new_logger_service()
logger.init()

logger.debug('Debug message')
logger.info('Info message')
logger.warn('Warning message')
logger.error('Error message')
logger.fatal('Fatal message')
```

**File:** src/services.v
**Lifecycle:** Application lifetime
**Dependencies:** None

#### CacheService

In-memory caching with TTL.

```v
cache := new_cache_service()
cache.init()

cache.set('key', 'value', 300)  // 5 minute TTL
value := cache.get('key') or { /* handle not found */ }
cache.delete('key')
cache.clear()
```

**File:** src/services.v
**Lifecycle:** Application lifetime
**Dependencies:** None

#### ValidationService

Input validation.

```v
validation := new_validation_service()
validation.init()

validation.add_rule('email', 'required')
validation.add_rule('email', 'email')

result := validation.validate(data)
if !result.is_valid {
    // Handle errors
}
```

**File:** src/services.v
**Lifecycle:** Application lifetime
**Dependencies:** None

#### SqliteService

Database operations.

```v
db := new_sqlite_service('users.db') or { /* handle error */ }

users := db.get_all_users()
user := db.create_user('Name', 'email@test.com', 25) or { /* handle error */ }
db.update_user(1, 'Name', 'email@test.com', 25) or { /* handle error */ }
db.delete_user(1) or { /* handle error */ }
```

**File:** src/services.v
**Lifecycle:** Application lifetime
**Dependencies:** os, json, security

### Frontend Services

#### ApiService

Backend communication.

```typescript
readonly api = inject(ApiService);

const result = await api.call('getUsers');
const data = await api.callOrThrow('getData');
```

**File:** frontend/src/core/api.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### StorageService

LocalStorage abstraction.

```typescript
readonly storage = inject(StorageService);

storage.set('key', 'value');
const value = storage.get('key', 'default');
storage.delete('key');
```

**File:** frontend/src/core/storage.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### LoggerService

Application logging.

```typescript
readonly logger = inject(LoggerService);

logger.debug('Debug', { data });
logger.info('Info');
logger.warn('Warning');
logger.error('Error', error);
```

**File:** frontend/src/core/logger.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### NotificationService

Toast notifications.

```typescript
readonly notifications = inject(NotificationService);

notifications.success('Success');
notifications.error('Error');
notifications.info('Info');
notifications.warning('Warning');
```

**File:** frontend/src/core/notification.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### LoadingService

Loading state management.

```typescript
readonly loading = inject(LoadingService);

loading.show('Loading...');
loading.hide();
loading.hideAll();
```

**File:** frontend/src/core/loading.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### ThemeService

Theme management.

```typescript
readonly theme = inject(ThemeService);

theme.setTheme('dark');
theme.setTheme('light');
theme.toggle();
const current = theme.getTheme();
```

**File:** frontend/src/core/theme.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### ClipboardService

Clipboard operations.

```typescript
readonly clipboard = inject(ClipboardService);

await clipboard.copy('text');
const text = await clipboard.read();
```

**File:** frontend/src/core/clipboard.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

#### NetworkMonitorService

Network status monitoring.

```typescript
readonly network = inject(NetworkMonitorService);

const online = network.isOnline();
const status = network.getStatus();
await network.waitForOnline(5000);
```

**File:** frontend/src/core/network-monitor.service.ts
**Lifecycle:** Singleton
**Dependencies:** None

---

## Best Practices

### Backend

1. **Create services in main()** - All services should be created in the main function
2. **Pass services to handlers** - Use closure capture to pass services to handlers
3. **Dispose on shutdown** - Register cleanup handlers for graceful shutdown
4. **Use mut for mutable services** - Mark services as mut when they need modification
5. **Check initialization** - Always call init() after creating services

### Frontend

1. **Use providedIn: 'root'** - For singleton services
2. **Use inject() in components** - Prefer inject() over constructor injection
3. **Use signals for state** - Use signal-based state management
4. **Expose readonly signals** - Use asReadonly() for public API
5. **Use computed for derived state** - Use computed() for derived values
6. **Clean up subscriptions** - Use effects with proper cleanup

### Service Communication

1. **Backend to Frontend** - Use WebUI bridge for RPC calls
2. **Frontend to Backend** - Use api.call() or api.callOrThrow()
3. **Error Handling** - Handle errors consistently across services
4. **Loading States** - Show loading indicators during async operations

---

*Last Updated: 2026-03-14*
