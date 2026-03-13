# Error Handling Guide

This document describes the error handling system used throughout the application.

## Overview

The application uses a structured "errors as values" pattern for consistent error handling across backend and frontend.

## Backend Error Handling

### Error Codes

Backend defines error codes in the ErrorCode enum:

```v
pub enum ErrorCode {
    // Database errors (1000-1999)
    db_connection_failed = 1001
    db_query_failed = 1002
    db_constraint_violation = 1003
    
    // Configuration errors (2000-2999)
    config_not_found = 2001
    config_invalid = 2002
    
    // Validation errors (4000-4999)
    validation_failed = 4001
    missing_required_field = 4002
    
    // Not found errors (5000-5999)
    resource_not_found = 5001
    user_not_found = 5002
    
    // System errors (6000-6999)
    internal_error = 6001
    timeout_error = 6002
}
```

### ErrorValue Structure

```v
pub struct ErrorValue {
    code:      ErrorCode
    message:   string
    details:   string
    field:     string
    cause:     string
    timestamp: u64
    source:    string
    context:   map[string]string
}
```

### Creating Errors

```v
// Basic error
err := error.new(.validation_failed, 'Invalid input')

// With details
err := error.with_details(.internal_error, 'Failed', 'Stack trace here')

// With field (for validation)
err := error.with_field(.validation_failed, 'Required', 'email')

// With context
err := error.with_context(.db_error, 'Query failed', {'query': 'SELECT *'})

// Specific error types
err := error.validation_error('email', 'Invalid format')
err := error.not_found_error('User', '123')
err := error.db_error('query', 'Connection timeout')
err := error.timeout_error('api_call', 5000)
```

### Error Analysis

```v
// Check if critical
if error.is_critical(err) {
    // Handle critical error
}

// Check if warning
if error.is_warning(err) {
    // Handle warning
}

// Get category
category := error.get_error_category(err)
// Returns: 'Database Error', 'Validation Error', etc.
```

### Error Serialization

```v
// To JSON
json_str := error.to_json(err)

// To API response
response := error.to_response(err)
// Returns: {"success":false,"data":null,"error":{...}}

// From JSON
err := error.from_json(json_str) or {
    // Handle parse error
}
```

### Error Logging

```v
// Log single error
error.log_error(err)

// Output format:
// ═══════════════════════════════════════════════════════════
// 10:30:45 [ERROR] Validation Error
// ───────────────────────────────────────────────────────────
//   Code:    4001
//   Message: Invalid input
//   Field:   email
//   Source:  validation
// ═══════════════════════════════════════════════════════════
```

### Error Handlers

```v
// Handle API errors
fn handle_api_error(operation string, err error.ErrorValue) string {
    error.log_error(err)
    return error.to_response(err)
}

// Safe API call wrapper
fn safe_api_call[T](operation string, fn fn () T) string {
    result := fn()
    return json.encode(result) or {
        err := error.internal_error_msg('Encoding failed')
        return handle_api_error(operation, err)
    }
}
```

## Frontend Error Handling

### Error Codes

Frontend mirrors backend error codes:

```typescript
export enum ErrorCode {
    DbConnectionFailed = 'DB_CONNECTION_FAILED',
    DbQueryFailed = 'DB_QUERY_FAILED',
    ValidationFailed = 'VALIDATION_FAILED',
    ResourceNotFound = 'RESOURCE_NOT_FOUND',
    InternalError = 'INTERNAL_ERROR',
    // ... more codes
}
```

### ErrorValue Interface

```typescript
export interface ErrorValue {
    code: ErrorCode;
    message: string;
    details?: string;
    field?: string;
    cause?: string;
    context?: Record<string, string>;
}
```

### Result Type

```typescript
type Result<T, E = ErrorValue> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

// Create success
const success = ok(42);

// Create error
const failure = err({ code: ErrorCode.InternalError, message: 'Failed' });

// Check result
if (isOk(result)) {
    console.log(result.value);
} else {
    console.error(result.error);
}
```

### Result Operations

```typescript
// Unwrap with default
const value = unwrapOr(result, 'default');

// Unwrap or throw
const value = unwrap(result); // Throws on error

// Map success value
const mapped = mapResult(result, x => x * 2);

// Map error value
const mapped = mapError(result, e => ({ ...e, message: `Wrapped: ${e.message}` }));

// Chain operations
const chained = andThen(result, x => ok(x + 1));
```

### Error Factories

```typescript
// Validation error
const err = validationError('email', 'Invalid format');

// Not found error
const err = notFoundError('User', 123);

// Internal error
const err = internalError('System failure', 'Root cause');

// Generic error
const err = createError(ErrorCode.Plugin, 'Plugin failed', 'Details');
```

### User Messages

```typescript
// Convert to user-friendly message
const message = toUserMessage(error);

// Examples:
// validation_error with field -> "email: Invalid format"
// not_found -> "User not found: 123"
// db_connection -> "Unable to connect to the database..."
// internal_error -> "An unexpected error occurred..."
```

### Error Services

#### GlobalErrorService

Central error state management:

```typescript
// Report error
const state = errorService.report(error, {
    source: 'user-list',
    title: 'Failed to load'
});

// Handle result
const users = errorService.handleResult(result, {
    source: 'api',
    title: 'API Error'
});

// Dismiss error
errorService.dismiss();

// Check for error
if (errorService.hasError()) {
    const error = errorService.activeError();
}
```

#### ErrorInterceptor

Captures all errors:

```typescript
// Intercept WebUI call
const result = errorInterceptor.interceptWebUICall(
    'getUsers',
    () => window.getUsers()
);

// Intercept async call
const result = await errorInterceptor.interceptWebUIAsync(
    'getUsers',
    async () => window.getUsers()
);

// Get statistics
const stats = errorInterceptor.getStats();
// { total: 5, bySource: Map, byCode: Map, criticalCount: 2 }

// Get history
const history = errorInterceptor.getHistory(10);

// Clear
errorInterceptor.clear();
```

#### RetryService

Exponential backoff retry:

```typescript
// Execute with retry
const result = await retryService.executeWithRetry(
    () => apiCall(),
    {
        maxRetries: 3,
        initialDelayMs: 1000,
        maxDelayMs: 30000,
        backoffMultiplier: 2,
        retryableErrorCodes: [
            ErrorCode.DbConnectionFailed,
            ErrorCode.InternalError,
        ],
    },
    'Operation Name'
);

// Execute or null
const result = await retryService.executeWithRetryOr(
    () => apiCall(),
    {},
    'Operation Name'
);
```

#### ErrorRecoveryService

Circuit breaker pattern:

```typescript
// Execute with circuit breaker
const result = await recoveryService.executeWithCircuitBreaker(
    () => apiCall(),
    'Operation Name'
);

// Execute with fallback
const result = await recoveryService.executeWithFallback(
    () => primaryCall(),
    () => fallbackCall(),
    'Operation Name'
);

// Register recovery strategy
recoveryService.registerStrategy({
    errorCodes: [ErrorCode.TimeoutError],
    action: async (error) => {
        await sleep(3000);
        return true;
    },
    maxAttempts: 1,
});
```

#### NetworkMonitorService

Connectivity monitoring:

```typescript
// Check status
if (networkMonitor.isOnline()) {
    // Make API call
}

// Wait for online
const isOnline = await networkMonitor.waitForOnline(30000);

// Get quality
const quality = networkMonitor.getQuality();
// { status: 'excellent' | 'good' | 'fair' | 'poor' | 'offline', ... }

// Get stats
const stats = networkMonitor.getStats();
// { totalRequests, successfulRequests, failedRequests, avgLatency }
```

#### ErrorTelemetryService

Error tracking:

```typescript
// Record error
telemetry.recordError(error, {
    source: 'api-client',
    operation: 'getUsers'
});

// Record performance
telemetry.recordPerformance('api_call', 150, {
    success: 1
});

// Record user action
telemetry.recordUserAction('button_click', {
    buttonId: 'submit'
});

// Generate report
const report = telemetry.generateReport();

// Export report
await telemetry.exportReport();
```

### Error Boundary Component

Isolate component errors:

```html
<app-error-boundary
    [componentId]="'user-list'"
    [autoRetry]="true"
    [maxRetries]="3"
    (errorCaught)="handleError($event)"
    (recovered)="handleRecovery()">
    
    <user-list-component />
    
</app-error-boundary>
```

## Best Practices

### Backend

1. Always use structured errors
2. Include relevant context
3. Log errors at appropriate severity
4. Return JSON error responses
5. Never expose stack traces to frontend

### Frontend

1. Use Result types for operations
2. Handle errors at appropriate level
3. Show user-friendly messages
4. Log technical details
5. Implement retry for transient errors
6. Use circuit breakers for external calls
7. Track errors for monitoring

### Error Message Guidelines

1. Be specific about what went wrong
2. Include actionable next steps
3. Avoid technical jargon for users
4. Include error codes for support
5. Localize messages when possible

## Testing Errors

### Backend Tests

```v
fn test_error_creation() {
    err := error.new(.validation_failed, 'Test')
    assert err.code == .validation_failed
    assert err.message == 'Test'
}

fn test_error_serialization() {
    err := error.new(.internal_error, 'Test')
    json_str := error.to_json(err)
    assert json_str.contains('internal_error')
}
```

### Frontend Tests

```typescript
describe('Error Handling', () => {
    it('should create validation error', () => {
        const error = validationError('email', 'Invalid');
        expect(error.code).toBe(ErrorCode.ValidationFailed);
        expect(error.field).toBe('email');
    });

    it('should handle result', () => {
        const result = ok(42);
        expect(isOk(result)).toBe(true);
        expect(unwrap(result)).toBe(42);
    });
});
```
