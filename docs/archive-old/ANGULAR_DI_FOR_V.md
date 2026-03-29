# Angular-Inspired Dependency Injection for V

**Purpose:** Bring Angular's elegant DI workflow to V backend while staying idiomatic to V.

---

## Overview

This DI system is inspired by Angular's dependency injection but adapted for V's constraints:

| Angular Feature | V Equivalent |
|-----------------|--------------|
| `@Injectable({providedIn: 'root'})` | `injector.register_singleton()` |
| `Injector.create({providers: [...]})` | `di.new_injector()` |
| `inject(ServiceClass)` | `injector.get[&Service]('name')` |
| `EnvironmentInjector` | `injector.create_scope()` |
| `OnDestroy` | `injector.destroy()` |

---

## Core Concepts

### 1. Injector (Like Angular's Injector)

The injector is the core DI container that manages service instances.

```v
import di

// Create root injector (like Angular's root injector)
mut injector := di.new_injector()
```

### 2. Service Registration (Like Angular's providers)

Register services with different scopes:

```v
// Singleton (like @Injectable({providedIn: 'root'}))
config := new_config_service()
di.new_provider('config').in_root().build(mut injector, config)

// Or directly
injector.register_singleton('logger', logger)
```

### 3. Service Resolution (Like Angular's inject())

Retrieve services from the injector:

```v
// Get service (like inject(LoggerService))
logger := injector.get[&LoggerService]('logger') or {
    // Handle not found
    return
}
```

### 4. Scopes (Like Angular's EnvironmentInjector)

Create child injectors for scoped services:

```v
// Create child injector (like createChildInjector)
mut request_injector := injector.create_child_injector()

// Create scope (like EnvironmentInjector)
scope := request_injector.create_scope('request_1')
request_injector.use_scope('request_1')

// Register scoped service
data := map[string]string{}
di.new_provider('requestData').in_scope().build(mut request_injector, data)

// Destroy scope (like destroy on EnvironmentInjector)
request_injector.destroy_scope('request_1')
```

---

## API Reference

### Injector Creation

```v
// Create root injector
pub fn di.new_injector() &Injector

// Create child injector
pub fn (mut injector Injector) create_child_injector() &Injector
```

### Service Registration

```v
// Register singleton (like @Injectable({providedIn: 'root'}))
pub fn (mut injector Injector) register_singleton[T](name string, mut instance T)

// Register with factory (like useFactory)
pub fn (mut injector Injector) register_singleton_fn[T](name string, factory fn () T)

// Register transient (new instance each time)
pub fn (mut injector Injector) register_transient[T](name string, mut instance T)

// Register scoped (one instance per scope)
pub fn (mut injector Injector) register_scoped[T](name string, mut instance T)
```

### Provider Builder (Fluent API)

```v
// Create provider builder
pub fn di.new_provider(name string) ProviderBuilder

// Configure scope
pub fn (mut builder ProviderBuilder) in_root() ProviderBuilder
pub fn (mut builder ProviderBuilder) transient() ProviderBuilder
pub fn (mut builder ProviderBuilder) in_scope() ProviderBuilder

// Build and register
pub fn (builder ProviderBuilder) build(mut injector Injector, instance voidptr)
```

### Service Resolution

```v
// Get service (like inject())
pub fn (mut injector Injector) get[T](name string) ?T

// Check if registered
pub fn (injector Injector) has(name string) bool
```

### Scope Management

```v
// Create scope
pub fn (mut injector Injector) create_scope(scope_id string) &Scope

// Use scope
pub fn (mut injector Injector) use_scope(scope_id string) bool

// Destroy scope
pub fn (mut injector Injector) destroy_scope(scope_id string) bool
```

### Cleanup

```v
// Destroy injector (like OnDestroy)
pub fn (mut injector Injector) destroy()
```

---

## Usage Examples

### Basic Usage

```v
module main

import di

fn main() {
    // Create injector
    mut injector := di.new_injector()

    // Register services
    config := new_config_service()
    di.new_provider('config').in_root().build(mut injector, config)

    logger := new_logger_service()
    di.new_provider('logger').in_root().build(mut injector, logger)

    // Resolve services
    resolved_config := injector.get[&ConfigService]('config') or {
        println('Config not found')
        return
    }

    resolved_logger := injector.get[&LoggerService]('logger') or {
        println('Logger not found')
        return
    }

    // Use services
    resolved_config.set('key', 'value')
    resolved_logger.info('Application started')

    // Cleanup
    injector.destroy()
}
```

### With Dependencies

```v
// Services with dependencies
cache := new_cache_service(logger)  // Manual resolution
di.new_provider('cache').in_root().build(mut injector, cache)

user_service := new_user_service(logger, cache, config)
di.new_provider('userService').in_root().build(mut injector, user_service)
```

### Scoped Services

```v
// Create request scope
mut request_injector := injector.create_child_injector()
scope := request_injector.create_scope('request_1')
request_injector.use_scope('request_1')

// Register request-scoped data
request_data := map[string]string{}
di.new_provider('requestData').in_scope().build(mut request_injector, request_data)

// Use scoped service
scoped_data := request_injector.get[map[string]string]('requestData')

// Destroy scope when done
request_injector.destroy_scope('request_1')
```

---

## Comparison: Angular vs V DI

### Angular

```typescript
// Service definition
@Injectable({providedIn: 'root'})
export class LoggerService {
  info(msg: string) { console.log(msg); }
}

// Component with injection
@Component({...})
export class AppComponent {
  constructor(private logger: LoggerService) {}
  
  ngOnInit() {
    this.logger.info('App initialized');
  }
}
```

### V Equivalent

```v
// Service definition
pub struct LoggerService {
pub mut:
    min_level string
}

pub fn new_logger_service() &LoggerService {
    return &LoggerService{min_level: 'info'}
}

pub fn (s LoggerService) info(msg string) {
    println('[INFO] ${msg}')
}

// Main with injection
fn main() {
    mut injector := di.new_injector()
    
    logger := new_logger_service()
    di.new_provider('logger').in_root().build(mut injector, logger)
    
    resolved_logger := injector.get[&LoggerService]('logger') or { return }
    resolved_logger.info('App initialized')
    
    injector.destroy()
}
```

---

## Best Practices

### 1. Register Services Early

```v
// Good: Register all services at startup
fn main() {
    mut injector := di.new_injector()
    
    // Register all services
    register_all_services(mut injector)
    
    // Run application
    run_app(mut injector)
}
```

### 2. Use Appropriate Scopes

```v
// Singleton for stateless services
di.new_provider('config').in_root().build(mut injector, config)

// Scoped for request-specific data
di.new_provider('requestData').in_scope().build(mut request_injector, data)
```

### 3. Clean Up Properly

```v
// Register cleanup handler
lifecycle.on_shutdown(fn [mut injector] () {
    injector.destroy()
})
```

### 4. Handle Missing Services

```v
// Always handle none case
service := injector.get[&Service]('name') or {
    // Handle missing service
    println('Service not registered')
    return
}
```

---

## Limitations (vs Angular)

1. **No Automatic Resolution**: V doesn't support constructor injection, so dependencies must be manually resolved
2. **No Type Tokens**: Services are identified by string names, not types
3. **No Hierarchical Injectors**: Child injectors exist but don't automatically inherit parent providers
4. **No Lazy Loading**: All services must be registered upfront

---

## Migration Guide

### From Manual DI

**Before:**
```v
config := new_config_service()
logger := new_logger_service(config)
cache := new_cache_service(logger)
```

**After:**
```v
mut injector := di.new_injector()

config := new_config_service()
di.new_provider('config').in_root().build(mut injector, config)

logger := new_logger_service()
di.new_provider('logger').in_root().build(mut injector, logger)

cache := new_cache_service(logger)
di.new_provider('cache').in_root().build(mut injector, cache)
```

### From Old DI Container

**Before:**
```v
container.register_singleton('logger', logger)
logger := container.resolve('logger') or { panic('No logger') }
```

**After:**
```v
di.new_provider('logger').in_root().build(mut injector, logger)
logger := injector.get[&LoggerService]('logger') or { return }
```

---

## Troubleshooting

### Service Not Found

**Problem:** `injector.get()` returns `none`

**Solution:**
1. Check service is registered before getting
2. Verify service name matches exactly
3. Check scope is active

### Scope Issues

**Problem:** Scoped service not found

**Solution:**
1. Ensure scope is created: `injector.create_scope()`
2. Ensure scope is active: `injector.use_scope()`
3. Register service in correct injector

### Memory Leaks

**Problem:** Services not cleaned up

**Solution:**
1. Call `injector.destroy()` on shutdown
2. Destroy scopes when done: `injector.destroy_scope()`

---

*Last Updated: 2026-03-16*
*Version: 1.0*
