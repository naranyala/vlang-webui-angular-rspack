# Error Handling Guide

Comprehensive guide to error handling using the "Errors as Values" pattern.

## Table of Contents

1. [Overview](#overview)
2. [Backend Error Handling](#backend-error-handling)
3. [Frontend Error Handling](#frontend-error-handling)
4. [Error Codes Reference](#error-codes-reference)
5. [Best Practices](#best-practices)

## Overview

This project uses "Errors as Values" pattern throughout:

| Aspect | Approach |
|--------|----------|
| Error Type | `ErrorValue` struct with full context |
| Return Type | `Result[T]` - Success or Error |
| Propagation | Explicit via return values |
| Handling | Pattern matching on Result |
| Logging | Structured with severity levels |

## Backend Error Handling

### Result Type

```v
import result
import error

// Result wraps success value or error
pub fn get_user(id int) result.Result[User] {
    if id <= 0 {
        return result.err[User](error.validation_error('id', 'Invalid ID'))
    }
    
    user := fetch_user(id)
    if user == none {
        return result.err[User](error.user_not_found(id))
    }
    
    return result.ok[User](user)
}
```

### Handling Results

```v
// Pattern matching
user_result := get_user(123)

match user_result {
    result.Result[User] {
        if user_result.is_ok() {
            println('User: ${user_result.value.name}')
        } else {
            error.log_error(user_result.error)
            return error.to_response(user_result.error)
        }
    }
}

// Or with explicit check
if user_result.is_err() {
    log_error(user_result.error)
    return error.to_response(user_result.error)
}

user := user_result.value
```

### Result Combinators

```v
// Chain operations
profile_result := get_user(id)
    .and_then(fn (user User) result.Result[Profile] {
        return get_profile(user.profile_id)
    })

// Transform value
name_result := get_user(id)
    .map(fn (user User) string {
        return user.name
    })

// Transform error
result := operation()
    .map_err(fn (err error.ErrorValue) error.ErrorValue {
        return error.wrap(err, 'Operation failed')
    })

// Provide fallback
value := get_config('key')
    .or_else(fn (err error.ErrorValue) result.Result[string] {
        return result.ok[string]('default_value')
    })
```

### ErrorValue Structure

```v
pub struct ErrorValue {
pub mut:
    code             ErrorCode          // Structured error code
    message          string             // Human-readable message
    details          string             // Additional details
    field            string             // Field name (validation errors)
    cause            string             // Underlying cause
    timestamp        u64                // When error occurred
    source           string             // Source system
    source_file      string             // Source file
    source_line      int                // Source line
    context          map[string]string  // Additional context
    stack_trace      []string           // Stack trace
    severity         ErrorSeverity      // Severity level
    retryable        bool               // Can be retried
    recovery_suggestion string          // How to recover
}
```

### Creating Errors

```v
// Basic error
err := error.new(.internal_error, 'Something went wrong')

// With field context (validation)
err := error.validation_error('email', 'Invalid email format')

// With context
err := error.with_context(.db_query_failed, 'Query failed', {
    'table': 'users'
    'query': 'SELECT * FROM users'
})

// With severity
err := error.with_severity(.internal_error, 'Critical failure', .critical)

// Retryable error
err := error.retryable(.network_error, 'Network unavailable')

// With recovery suggestion
err := error.with_recovery(.rate_limit_exceeded, 'Rate limit exceeded', 
    'Wait 60 seconds before retrying')

// Wrap existing error
if inner_result.is_err() {
    return result.err[User](error.wrap(inner_result.error, 'Failed to fetch user'))
}
```

### Error Codes

Organized by category:

```v
pub enum ErrorCode {
    // Database errors (1000-1999)
    db_connection_failed      = 1001
    db_query_failed           = 1002
    db_constraint_violation   = 1003
    db_not_found              = 1004
    db_already_exists         = 1005
    
    // Configuration errors (2000-2999)
    config_not_found          = 2001
    config_invalid            = 2002
    config_missing_field      = 2003
    
    // Validation errors (4000-4999)
    validation_failed         = 4001
    missing_required_field    = 4002
    invalid_field_value       = 4003
    
    // Resource errors (5000-5999)
    resource_not_found        = 5001
    user_not_found            = 5002
    entity_not_found          = 5003
    
    // System errors (6000-6999)
    internal_error            = 6001
    timeout_error             = 6002
    permission_denied         = 6003
    
    // Network errors (7000-7999)
    network_error             = 7001
    connection_refused        = 7002
}
```

### Error Severity

```v
pub enum ErrorSeverity {
    info       // Informational
    warning    // Warning, not critical
    error      // Standard error
    critical   // Critical, needs attention
    fatal      // Fatal, application may not continue
}
```

### API Error Responses

```v
// Standard error response
w.bind('getUser', fn (e &ui.Event) string {
    user_result := get_user(id)
    
    match user_result {
        result.Result[User] {
            if user_result.is_ok() {
                return json.encode(user_result.value)
            } else {
                error.log_error(user_result.error)
                return error.to_response(user_result.error)
            }
        }
    }
})

// Response format
{
    "success": false,
    "data": null,
    "error": {
        "code": 5002,
        "message": "User not found: 123",
        "field": "",
        "details": "",
        "timestamp": 1234567890,
        "source": "backend"
    }
}
```

## Frontend Error Handling

### Result Type

```typescript
import { Result, ok, err, isOk } from './types';

async function getUser(id: number): Promise<Result<User>> {
    if (id <= 0) {
        return err({
            code: 'VALIDATION_ERROR',
            message: 'ID must be positive',
            field: 'id'
        });
    }
    
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
        return err({
            code: 'NOT_FOUND',
            message: 'User not found'
        });
    }
    
    return ok(await response.json());
}
```

### Handling Results

```typescript
// Pattern matching with type guard
const result = await getUser(123);

if (isOk(result)) {
    console.log('User:', result.value);
} else {
    console.error('Error:', result.error);
    notificationService.error(result.error.message);
}

// Using match helper
result.match(
    (user) => console.log('User:', user),
    (error) => console.error('Error:', error)
);
```

### Error Types

```typescript
export interface ErrorValue {
    code: ErrorCode;
    message: string;
    details?: string;
    field?: string;
    cause?: string;
    timestamp?: number;
    source?: string;
    context?: Record<string, string>;
    severity?: ErrorSeverity;
    retryable?: boolean;
}

export type ErrorCode = 
    | 'VALIDATION_ERROR'
    | 'NOT_FOUND'
    | 'INTERNAL_ERROR'
    | 'NETWORK_ERROR'
    | 'TIMEOUT_ERROR'
    | 'UNAUTHORIZED'
    | 'FORBIDDEN';

export type ErrorSeverity = 'info' | 'warning' | 'error' | 'critical' | 'fatal';
```

### Error Interceptor

```typescript
// Global error interceptor
@Injectable({ providedIn: 'root' })
export class ErrorInterceptor {
  constructor(
    private errorService: GlobalErrorService,
    private logger: Logger
  ) {}
  
  intercept(operation: string, fn: () => void): void {
    try {
      fn();
    } catch (error) {
      const errorValue = this.normalizeError(error);
      this.errorService.handle(errorValue);
      this.logger.error(`Error in ${operation}`, errorValue);
    }
  }
  
  private normalizeError(error: unknown): ErrorValue {
    if (error instanceof Error) {
      return {
        code: 'INTERNAL_ERROR',
        message: error.message,
        details: error.stack
      };
    }
    return {
      code: 'UNKNOWN',
      message: String(error)
    };
  }
}
```

### Error Boundary

```typescript
@Component({...})
export class ErrorBoundaryComponent {
  error = signal<ErrorValue | null>(null);
  
  handleError(error: ErrorValue) {
    this.error.set(error);
    
    // Log to telemetry
    this.telemetry.trackError(error);
    
    // Show notification
    this.notifications.error('Error', error.message);
  }
  
  dismiss() {
    this.error.set(null);
  }
}
```

## Error Codes Reference

### Backend Error Codes

| Code | Name | Category | Description |
|------|------|----------|-------------|
| 1001 | db_connection_failed | Database | Failed to connect to database |
| 1002 | db_query_failed | Database | Query execution failed |
| 1003 | db_constraint_violation | Database | Constraint violation |
| 1004 | db_not_found | Database | Record not found |
| 1005 | db_already_exists | Database | Record already exists |
| 2001 | config_not_found | Config | Configuration key not found |
| 2002 | config_invalid | Config | Invalid configuration value |
| 2003 | config_missing_field | Config | Missing required config field |
| 4001 | validation_failed | Validation | General validation failure |
| 4002 | missing_required_field | Validation | Required field missing |
| 4003 | invalid_field_value | Validation | Invalid field value |
| 5001 | resource_not_found | Resource | Resource not found |
| 5002 | user_not_found | Resource | User not found |
| 5003 | entity_not_found | Resource | Entity not found |
| 6001 | internal_error | System | Internal system error |
| 6002 | timeout_error | System | Operation timed out |
| 6003 | permission_denied | System | Permission denied |
| 7001 | network_error | Network | Network error |
| 7002 | connection_refused | Network | Connection refused |

### Frontend Error Codes

| Code | Description |
|------|-------------|
| VALIDATION_ERROR | Input validation failed |
| NOT_FOUND | Resource not found |
| INTERNAL_ERROR | Internal application error |
| NETWORK_ERROR | Network request failed |
| TIMEOUT_ERROR | Request timed out |
| UNAUTHORIZED | Authentication required |
| FORBIDDEN | Permission denied |
| UNKNOWN | Unknown error |

## Best Practices

### 1. Always Return Results

```v
// Good - explicit error handling
pub fn get_user(id int) result.Result[User]

// Bad - hidden errors
pub fn get_user(id int) User
```

### 2. Wrap Errors with Context

```v
// Good - adds context
user_result := fetch_user(id)
if user_result.is_err() {
    return result.err[User](error.wrap(user_result.error, 'Failed to fetch user profile'))
}

// Bad - loses context
if user_result.is_err() {
    return user_result
}
```

### 3. Use Specific Error Constructors

```v
// Good - specific
return result.err[User](error.user_not_found(user_id))

// Bad - generic
return result.err[User](error.internal_error_msg('User not found'))
```

### 4. Mark Retryable Errors

```v
if is_network_error(err) {
    err := error.retryable(.network_error, 'Network unavailable')
}
```

### 5. Provide Recovery Suggestions

```v
err := error.with_recovery(
    .rate_limit_exceeded, 
    'Rate limit exceeded',
    'Retry after 60 seconds with exponential backoff'
)
```

### 6. Log Errors Appropriately

```v
// Log with severity
if error.is_critical(err) {
    error.log_error(err)  // Full logging
} else if error.is_warning(err) {
    logger.warn('${err.code}: ${err.message}')
}
```

### 7. Handle Errors at Boundaries

```typescript
// Component boundary
try {
    await this.loadData();
} catch (error) {
    this.errorHandler.handle(error);
    this.showErrorUI();
}

// API boundary
w.bind('getData', fn (e &ui.Event) string {
    result := get_data()
    if result.is_err() {
        error.log_error(result.error)
        return error.to_response(result.error)
    }
    return json.encode(result.value)
})
```

### 8. Transform Errors for Users

```v
// Internal error
err := error.internal_error_msg('Database connection pool exhausted')

// Transform for API response
user_facing_err := error.ErrorValue{
    code: .service_unavailable
    message: 'Service temporarily unavailable. Please try again later.'
    retryable: true
}
```

## Error Monitoring

### Backend

```v
// Error telemetry
pub fn track_error(err ErrorValue) {
    error_count.increment()
    
    if is_critical(err) {
        send_alert(err)
    }
    
    log_error(err)
}
```

### Frontend

```typescript
// Error telemetry service
@Injectable({ providedIn: 'root' })
export class ErrorTelemetryService {
  private errors = signal<ErrorValue[]>([]);
  
  track(error: ErrorValue): void {
    this.errors.update(e => [...e, error]);
    
    // Send to backend
    this.http.post('/api/errors', error);
    
    // Alert on critical
    if (error.severity === 'critical') {
        this.alertService.send(error);
    }
  }
  
  getStats(): ErrorStats {
    const errors = this.errors();
    return {
        total: errors.length,
        critical: errors.filter(e => e.severity === 'critical').length,
        byCode: this.groupByCode(errors)
    };
  }
}
```
