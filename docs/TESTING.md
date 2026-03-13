# Testing Guide

This document describes the testing infrastructure and how to write and run tests.

## Overview

The application uses two testing frameworks:

- **Bun Test**: Frontend TypeScript/JavaScript tests
- **V Test**: Backend V language tests

## Running Tests

### Frontend Tests

```bash
cd frontend

# Run all tests
bun test

# Run specific test file
bun test error.types.test.ts

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
v test src/error_test.v

# Run with stats
v -stats test src/error_test.v
```

## Frontend Test Structure

### Test File Naming

- Unit tests: `*.test.ts`
- Component tests: `*.component.test.ts`
- Service tests: `*.service.test.ts`
- Integration tests: `*.integration.test.ts`

### Test Organization

```
frontend/src/
├── types/
│   ├── error.types.test.ts
│   └── error.types.extended.test.ts
├── core/
│   ├── error-interceptor.test.ts
│   ├── retry.service.test.ts
│   └── network-monitor.service.test.ts
├── viewmodels/
│   └── logger.viewmodel.test.ts
└── views/
    └── app.component.test.ts
```

## Writing Frontend Tests

### Basic Test Structure

```typescript
import { describe, expect, it, beforeEach } from 'bun:test';

describe('Test Suite', () => {
    let service: MyService;

    beforeEach(() => {
        service = new MyService();
    });

    describe('methodName', () => {
        it('should do something', () => {
            const result = service.method();
            expect(result).toBe('expected');
        });

        it('should handle edge case', () => {
            expect(() => service.method(null)).toThrow();
        });
    });
});
```

### Testing Error Types

```typescript
import { describe, expect, it } from 'bun:test';
import { ErrorCode, ok, err, isOk, isErr } from './error.types';

describe('ErrorCode', () => {
    it('should have validation error code', () => {
        expect(ErrorCode.ValidationFailed).toBe('VALIDATION_FAILED');
    });
});

describe('Result Type', () => {
    describe('ok()', () => {
        it('should create successful result', () => {
            const result = ok(42);
            expect(result.ok).toBe(true);
            expect(result.value).toBe(42);
        });
    });

    describe('isOk()', () => {
        it('should return true for success', () => {
            expect(isOk(ok(42))).toBe(true);
        });

        it('should return false for error', () => {
            expect(isOk(err({ code: ErrorCode.Unknown, message: 'err' }))).toBe(false);
        });
    });
});
```

### Testing Services

```typescript
import { describe, expect, it, beforeEach, mock } from 'bun:test';
import { RetryService } from './retry.service';
import { ErrorCode, ok, err } from '../types';

describe('RetryService', () => {
    let retryService: RetryService;

    beforeEach(() => {
        retryService = new RetryService();
    });

    describe('executeWithRetry', () => {
        it('should succeed on first try', async () => {
            const operation = mock(() => Promise.resolve(ok('success')));
            
            const result = await retryService.executeWithRetry(
                operation, 
                {}, 
                'TestOp'
            );
            
            expect(result.ok).toBe(true);
            expect(operation).toHaveBeenCalledTimes(1);
        });

        it('should retry on failure', async () => {
            let attempts = 0;
            const operation = mock(async () => {
                attempts++;
                if (attempts < 3) {
                    return err({ code: ErrorCode.InternalError, message: 'Fail' });
                }
                return ok('success');
            });

            const result = await retryService.executeWithRetry(
                operation,
                { maxRetries: 3, initialDelayMs: 10 },
                'TestOp'
            );

            expect(result.ok).toBe(true);
            expect(attempts).toBe(3);
        });

        it('should fail after max retries', async () => {
            const operation = mock(() => 
                Promise.resolve(err({ code: ErrorCode.InternalError, message: 'Fail' }))
            );

            const result = await retryService.executeWithRetry(
                operation,
                { maxRetries: 2 },
                'TestOp'
            );

            expect(result.ok).toBe(false);
            expect(operation).toHaveBeenCalledTimes(3);
        });
    });
});
```

### Testing with Mocks

```typescript
import { describe, expect, it, mock } from 'bun:test';

describe('Mocking', () => {
    it('should mock function', () => {
        const consoleSpy = mock();
        const originalLog = console.log;
        console.log = consoleSpy;

        console.log('test');
        
        expect(consoleSpy).toHaveBeenCalledWith('test');
        
        console.log = originalLog;
    });

    it('should mock async function', async () => {
        const fetchSpy = mock(() => 
            Promise.resolve({ json: () => Promise.resolve({ data: 'test' }) })
        );

        const result = await fetchSpy();
        const json = await result.json();
        
        expect(json.data).toBe('test');
    });
});
```

### Testing Error Handling

```typescript
import { describe, expect, it } from 'bun:test';
import { errorInterceptor } from './error-interceptor';

describe('ErrorInterceptor', () => {
    beforeEach(() => {
        errorInterceptor.clear();
    });

    it('should track errors', () => {
        errorInterceptor.interceptWebUICall(
            'testOp',
            () => { throw new Error('Test error'); }
        );

        const stats = errorInterceptor.getStats();
        expect(stats.total).toBe(1);
        expect(stats.bySource.get('webui')).toBe(1);
    });

    it('should respect silent option', () => {
        const consoleSpy = mock();
        const originalGroup = console.groupCollapsed;
        console.groupCollapsed = consoleSpy;

        const context = { source: 'test', operation: 'op', timestamp: Date.now() };
        errorInterceptor.handleError(
            new Error('Silent'), 
            context, 
            { silent: true }
        );

        expect(consoleSpy).not.toHaveBeenCalled();
        
        console.groupCollapsed = originalGroup;
    });
});
```

## Backend Test Structure

### Test File Naming

- Test files: `*_test.v`
- Example: `error_test.v`, `system_test.v`

### Test Organization

```
src/
├── error_test.v
├── system_test.v
├── network_test.v
├── process_test.v
└── filesystem_test.v
```

## Writing Backend Tests

### Basic Test Structure

```v
module error

// V Test file - run with: v test src/error_test.v

fn test_error_new() {
    mut assert_count := 0
    
    err := new(.validation_failed, 'Test message')
    assert err.code == .validation_failed
    assert_count++
    
    assert err.message == 'Test message'
    assert_count++
    
    println('✓ test_error_new: ${assert_count} assertions passed')
}

fn test_error_with_details() {
    mut assert_count := 0
    
    err := with_details(.internal_error, 'Message', 'Details')
    
    assert err.code == .internal_error
    assert_count++
    
    assert err.details == 'Details'
    assert_count++
    
    println('✓ test_error_with_details: ${assert_count} assertions passed')
}

// Run all tests
fn test_all() {
    test_error_new()
    test_error_with_details()
}
```

### Testing Error Creation

```v
fn test_error_constructors() {
    mut assert_count := 0
    
    // Basic error
    err := new(.validation_failed, 'Test')
    assert err.code == .validation_failed
    assert_count++
    
    // With details
    err = with_details(.internal_error, 'Msg', 'Details')
    assert err.details == 'Details'
    assert_count++
    
    // With field
    err = with_field(.validation_failed, 'Msg', 'email')
    assert err.field == 'email'
    assert_count++
    
    println('✓ test_error_constructors: ${assert_count} assertions passed')
}
```

### Testing Specific Error Types

```v
fn test_specific_errors() {
    mut assert_count := 0
    
    // Database error
    err := db_error('query', 'Timeout')
    assert err.code == .db_query_failed
    assert_count++
    
    // Validation error
    err = validation_error('email', 'Invalid')
    assert err.field == 'email'
    assert_count++
    
    // Not found error
    err = not_found_error('User', '123')
    assert err.context['resource'] == 'User'
    assert_count++
    
    println('✓ test_specific_errors: ${assert_count} assertions passed')
}
```

### Testing Error Analysis

```v
fn test_error_analysis() {
    mut assert_count := 0
    
    // Critical error
    critical := new(.db_connection_failed, 'DB down')
    assert is_critical(critical) == true
    assert_count++
    
    // Warning error
    warning := new(.validation_failed, 'Invalid')
    assert is_warning(warning) == true
    assert_count++
    
    // Category
    category := get_error_category(critical)
    assert category == 'Database Error'
    assert_count++
    
    println('✓ test_error_analysis: ${assert_count} assertions passed')
}
```

### Testing Serialization

```v
fn test_error_serialization() {
    mut assert_count := 0
    
    err := new(.internal_error, 'Test')
    
    // To JSON
    json_str := to_json(err)
    assert json_str.contains('internal_error')
    assert_count++
    
    // To response
    response := to_response(err)
    assert response.contains('"success":false')
    assert_count++
    
    // From JSON
    parsed := from_json(json_str) or {
        assert false
        return
    }
    assert parsed.code == .internal_error
    assert_count++
    
    println('✓ test_error_serialization: ${assert_count} assertions passed')
}
```

### Testing System Module

```v
module system

fn test_get_system_info() {
    mut assert_count := 0
    
    info := get_system_info()
    
    assert info.hostname != ''
    assert_count++
    
    assert info.arch == 'x64' || info.arch == 'arm' || info.arch == 'arm64'
    assert_count++
    
    assert info.os != ''
    assert_count++
    
    println('✓ test_get_system_info: ${assert_count} assertions passed')
}

fn test_get_memory_info() {
    mut assert_count := 0
    
    memory := get_memory_info()
    
    assert memory.total > 0
    assert_count++
    
    assert memory.used >= 0
    assert_count++
    
    assert memory.free >= 0
    assert_count++
    
    assert memory.total == memory.used + memory.free
    assert_count++
    
    println('✓ test_get_memory_info: ${assert_count} assertions passed')
}
```

### Testing Network Module

```v
module network

fn test_validate_ip() {
    mut assert_count := 0
    
    // Valid IPs
    assert validate_ip('192.168.1.1') == true
    assert_count++
    
    assert validate_ip('127.0.0.1') == true
    assert_count++
    
    // Invalid IPs
    assert validate_ip('256.1.1.1') == false
    assert_count++
    
    assert validate_ip('192.168.1') == false
    assert_count++
    
    assert validate_ip('') == false
    assert_count++
    
    println('✓ test_validate_ip: ${assert_count} assertions passed')
}

fn test_validate_mac() {
    mut assert_count := 0
    
    // Valid MAC
    assert validate_mac('00:1A:2B:3C:4D:5E') == true
    assert_count++
    
    // Invalid MAC
    assert validate_mac('00:1A:2B:3C:4D') == false
    assert_count++
    
    assert validate_mac('') == false
    assert_count++
    
    println('✓ test_validate_mac: ${assert_count} assertions passed')
}
```

## Test Coverage

### Current Coverage

| Module | Tests | Status |
|--------|-------|--------|
| Error Types | 60+ | Complete |
| Retry Service | 15 | Complete |
| Error Interceptor | 25 | Complete |
| Error Module (V) | 20 | Complete |
| System Module (V) | 15 | Complete |
| Network Module (V) | 15 | Complete |

### Coverage Goals

- Critical paths: 100%
- Error handling: 90%
- UI components: 80%
- Integration tests: 70%

## Best Practices

### General

1. Name tests descriptively
2. Test one thing per test
3. Use Arrange-Act-Assert pattern
4. Keep tests independent
5. Clean up after tests

### Frontend

1. Mock external dependencies
2. Test error cases
3. Test edge cases
4. Use beforeEach for setup
5. Test async code properly

### Backend

1. Use assert_count for tracking
2. Print assertion counts
3. Test all error paths
4. Test serialization
5. Test with real system data

## Continuous Integration

### Test Command

```bash
# Full test suite
./run.sh test

# Frontend only
cd frontend && bun test

# Backend only
v test src/
```

### Pre-commit Checks

```bash
# Run linting
bun run lint

# Run tests
bun test

# Build
./run.sh build
```

## Debugging Tests

### Frontend

```bash
# Run with verbose output
bun test --verbose

# Run specific test
bun test --test-name-pattern "should create validation error"
```

### Backend

```bash
# Run with verbose output
v -stats test src/error_test.v

# Debug specific test
v test src/error_test.v -filter test_error_new
```

## Common Issues

### Test Timeout

```typescript
// Increase timeout
it('should complete', async () => {
    // Long running test
}, 10000); // 10 second timeout
```

### Mock Not Working

```typescript
// Ensure mock is set up before test
beforeEach(() => {
    mockFunction = mock(() => 'value');
});
```

### V Test Compilation

```bash
# Ensure V compiler is installed
v version

# Check C compiler
gcc --version

# Install missing headers
sudo apt-get install libc6-dev
```
