# Testing Guide

Testing infrastructure and guidelines for Desktop Dashboard.

## Overview

| Framework | Platform | Purpose |
|-----------|----------|---------|
| Bun Test | Frontend | TypeScript/JavaScript tests |
| V Test | Backend | V language tests |

## Running Tests

### Frontend Tests

```bash
cd frontend

# Run all tests
bun test

# Run specific file
bun test retry.service.test.ts

# Run tests matching pattern
bun test error

# Run with coverage (when available)
bun test --coverage
```

### Backend Tests

```bash
# Run all tests in directory
v test src/

# Run specific test file
v test src/di_test.v
v test src/services_test.v

# Run with stats
v -stats test src/di_test.v
```

## Frontend Test Structure

### Test File Naming

- Unit tests: `*.test.ts`
- Component tests: `*.component.test.ts`
- Service tests: `*.service.test.ts`

### Test Example

```typescript
// retry.service.test.ts
import { RetryService } from './retry.service';

describe('RetryService', () => {
  let service: RetryService;
  
  beforeEach(() => {
    service = new RetryService();
  });
  
  it('should retry on failure', async () => {
    let attempts = 0;
    const operation = async () => {
      attempts++;
      if (attempts < 3) {
        return { ok: false, error: { code: 'TIMEOUT' } };
      }
      return { ok: true, value: 'success' };
    };
    
    const result = await service.executeWithRetry(operation, {
      maxRetries: 3
    });
    
    expect(result.ok).toBe(true);
    expect(attempts).toBe(3);
  });
  
  it('should not retry on non-retryable error', async () => {
    let attempts = 0;
    const operation = async () => {
      attempts++;
      return { ok: false, error: { code: 'VALIDATION_ERROR' } };
    };
    
    await service.executeWithRetry(operation, {
      maxRetries: 3
    });
    
    expect(attempts).toBe(1);
  });
});
```

## Backend Test Structure

### Test File Naming

- Unit tests: `*_test.v`
- Integration tests: `*_integration_test.v`

### Test Example

```v
// di_test.v
module di

fn test_new_container() {
    println('Testing: test_new_container')
    
    c := new_container()
    
    assert c.descriptors.len == 0, 'New container should be empty'
    assert c.default_scope != 0, 'Default scope should exist'
    
    println('  ✓ PASSED: test_new_container')
}

fn test_register_singleton() {
    println('Testing: test_register_singleton')
    
    mut c := new_container()
    
    instance := 42
    result := c.register_singleton('test', instance)
    
    assert result.success == true, 'Registration should succeed'
    assert c.has('test') == true, 'Service should exist'
    
    println('  ✓ PASSED: test_register_singleton')
}

fn test_resolve_singleton() {
    println('Testing: test_resolve_singleton')
    
    mut c := new_container()
    
    c.register_singleton_fn('factory', fn () voidptr {
        return 123
    })
    
    instance := c.resolve('factory') or {
        assert false, 'Resolution should succeed'
        return
    }
    
    assert instance == 123, 'Factory should return correct value'
    
    println('  ✓ PASSED: test_resolve_singleton')
}

// Run all tests
pub fn run_all_tests() {
    println('Running DI Tests')
    println('================')
    
    test_new_container()
    test_register_singleton()
    test_resolve_singleton()
    
    println('')
    println('All tests passed!')
}
```

### Service Test Example

```v
// services_test.v
module services

fn test_cache_service_set_get() {
    println('Testing: test_cache_service_set_get')
    
    mut service := new_cache_service()
    service.init()
    
    service.set('key1', 'value1', 300)
    
    assert service.has('key1') == true, 'Should have key1'
    
    value := service.get('key1') or {
        assert false, 'Should get value'
        return
    }
    assert value == 'value1', 'Value should match'
    
    println('  ✓ PASSED: test_cache_service_set_get')
}

fn test_validation_service() {
    println('Testing: test_validation_service')
    
    mut service := new_validation_service()
    service.init()
    
    service.add_rule('email', 'required')
    service.add_rule('email', 'email')
    
    // Valid data
    valid_data := {
        'email': 'test@example.com'
    }
    result := service.validate(valid_data)
    assert result.is_valid == true, 'Should be valid'
    
    // Invalid data
    invalid_data := {
        'email': ''
    }
    result2 := service.validate(invalid_data)
    assert result2.is_valid == false, 'Should be invalid'
    
    println('  ✓ PASSED: test_validation_service')
}
```

## Test Categories

### Unit Tests

Test individual functions and methods:

```typescript
// Frontend
describe('StorageService', () => {
  it('should store and retrieve values', () => {
    const service = new StorageService();
    service.set('key', 'value');
    expect(service.get('key')).toBe('value');
  });
});
```

```v
// Backend
fn test_config_service_get() {
    mut service := new_config_service()
    service.init()
    
    service.set('key', 'value')
    assert service.get_string('key', 'default') == 'value'
}
```

### Integration Tests

Test service interactions:

```v
fn test_di_container_with_services() {
    mut container := di.new_container()
    mut registry := svc.new_service_registry(&container)
    
    registry.register_logger_service('info')
    registry.register_cache_service(1000)
    
    logger := registry.get_logger() or {
        assert false
        return
    }
    
    cache := registry.get_cache() or {
        assert false
        return
    }
    
    assert logger != 0, 'Logger should be available'
    assert cache != 0, 'Cache should be available'
}
```

### Error Handling Tests

Test error scenarios:

```typescript
describe('HttpService', () => {
  it('should handle network errors', async () => {
    const http = new HttpService();
    
    // Mock fetch to fail
    global.fetch = jest.fn().mockRejectedValue(new Error('Network error'));
    
    const result = await http.get('/api/test');
    
    expect(result.ok).toBe(false);
    expect(result.error.code).toBe('NETWORK_ERROR');
  });
});
```

```v
fn test_result_error_handling() {
    err_result := result.err[string](error.internal_error_msg('Test error'))
    
    assert err_result.is_err() == true
    assert err_result.is_ok() == false
    
    default := err_result.get('default')
    assert default == 'default'
}
```

## Test Coverage

### Frontend Coverage

```bash
cd frontend
bun test --coverage

# View coverage report
# Coverage report will be generated in coverage/
```

### Backend Coverage

V test doesn't have built-in coverage, but you can:

1. Add print statements to track test execution
2. Use manual tracking in test functions
3. Ensure all code paths are tested

## Best Practices

### 1. Test Naming

Use descriptive names:

```typescript
// Good
it('should return cached value when available', () => {});
it('should fetch from server when cache miss', () => {});

// Bad
it('test cache', () => {});
```

```v
// Good
fn test_cache_service_hit_on_existing_key()

// Bad
fn test_cache()
```

### 2. Arrange-Act-Assert

```typescript
it('should increment counter', () => {
  // Arrange
  const service = new MetricsService();
  
  // Act
  service.incrementCounter('requests', 1);
  service.incrementCounter('requests', 2);
  
  // Assert
  expect(service.getCounter('requests')).toBe(3);
});
```

```v
fn test_counter_increment() {
    // Arrange
    mut service := new_metrics_service()
    service.init()
    
    // Act
    service.increment_counter('requests', 1)
    service.increment_counter('requests', 2)
    
    // Assert
    assert service.get_counter('requests') == 3
}
```

### 3. Test Edge Cases

```typescript
it('should handle empty input', () => {
  expect(service.validate('')).toBe(false);
});

it('should handle null input', () => {
  expect(service.validate(null)).toBe(false);
});

it('should handle very large input', () => {
  const large = 'x'.repeat(1000000);
  expect(() => service.validate(large)).not.toThrow();
});
```

### 4. Mock External Dependencies

```typescript
// Mock HTTP
const mockFetch = jest.fn().mockResolvedValue({
  ok: true,
  json: () => Promise.resolve({ data: 'test' })
});
global.fetch = mockFetch;

// Mock storage
const mockStorage = {
  get: jest.fn(),
  set: jest.fn(),
  delete: jest.fn()
};
```

### 5. Clean Up After Tests

```typescript
afterEach(() => {
  jest.clearAllMocks();
});

afterAll(() => {
  service.dispose();
});
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
      
      - name: Setup V
        uses: vlang/setup-v@v1
      
      - name: Install dependencies
        run: cd frontend && bun install
      
      - name: Run frontend tests
        run: cd frontend && bun test
      
      - name: Run backend tests
        run: v test src/
```

## Test Files Reference

### Frontend Test Files

| File | Tests |
|------|-------|
| `retry.service.test.ts` | Retry logic |
| `error-interceptor.test.ts` | Error interception |
| `error.types.test.ts` | Error types |

### Backend Test Files

| File | Tests |
|------|-------|
| `di_test.v` | DI container |
| `services_test.v` | All services |
| `error_test.v` | Error handling |
| `system_test.v` | System modules |
| `network_test.v` | Network modules |
