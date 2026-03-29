# Backend-Frontend Communication Guide

**Project:** vlang-webui-angular-rspack  
**Last Updated:** 2026-03-14

---

## Table of Contents

1. [Overview](#overview)
2. [Communication Approaches](#communication-approaches)
3. [WebUI Bridge Protocol](#webui-bridge-protocol)
4. [Message Format](#message-format)
5. [Error Handling](#error-handling)
6. [Security Considerations](#security-considerations)
7. [Best Practices](#best-practices)
8. [Examples](#examples)

---

## Overview

This application uses a **hybrid communication architecture** combining:

1. **WebUI Bridge** - Primary RPC-style communication for desktop window management
2. **HTTP/Fetch** - Standard RESTful communication (available for future expansion)
3. **Event Bus** - Pub/sub for cross-component communication

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (Angular)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Components  │  │  HttpService │  │   EventBus VM    │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                 │                    │             │
│         │          WebUI Bridge         Pub/Sub Events      │
│         │        (RPC over JS/V)             │              │
│         └────────────────┼───────────────────┘              │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           │ WebUI.bind() / window.call()
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                      Backend (V Language)                    │
│         │                 │                    │             │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌────────┴─────────┐   │
│  │ WebUI Server │  │  API Handlers│  │    Event Bus     │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Communication Approaches

### 1. WebUI Bridge (Primary)

**Type:** Synchronous RPC (Remote Procedure Call)  
**Direction:** Bidirectional  
**Use Cases:** Desktop window management, API calls, system access

#### Architecture

```
Frontend (JavaScript/TypeScript)
        ↓
window.call('functionName', data)
        ↓
WebUI Bridge (C/V)
        ↓
V Handler: w.bind('functionName', handler_fn)
        ↓
Backend Service Layer
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Protocol** | Custom RPC over WebUI library |
| **Transport** | In-process JavaScript ↔ V binding |
| **Serialization** | JSON |
| **Latency** | < 10ms (in-process) |
| **Security** | Input validation, rate limiting |

#### Example

**Backend (V):**
```v
// Register handler
w.bind('getUsers', fn [api] (e &ui.Event) string {
    users := api.get_all_users()
    data := json.encode(users)
    return '{"success":true,"data":${data}}'
})
```

**Frontend (TypeScript):**
```typescript
// Call backend function
const result = await window.call('getUsers');
const users = JSON.parse(result).data;
```

---

### 2. HTTP/Fetch (Secondary)

**Type:** RESTful HTTP  
**Direction:** Client → Server  
**Use Cases:** Future web deployment, external APIs

#### Architecture

```
Frontend HttpService
        ↓
fetch('/api/endpoint', options)
        ↓
HTTP Server (future)
        ↓
Backend Service Layer
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Protocol** | HTTP/1.1 or HTTP/2 |
| **Methods** | GET, POST, PUT, DELETE |
| **Content-Type** | application/json |
| **Caching** | TTL-based with StorageService |
| **Retry** | Exponential backoff |

#### Example

**Frontend (TypeScript):**
```typescript
// GET request with caching
async getUsers(): Promise<Result<User[]>> {
    return this.http.get<User[]>('/api/users', {
        cache: true,
        cacheTtl: 60000  // 1 minute
    });
}

// POST request with retry
async createUser(user: CreateUserRequest): Promise<Result<User>> {
    return this.http.post<User>('/api/users', user, {
        retry: true,
        maxRetries: 3
    });
}
```

---

### 3. Event Bus (Pub/Sub)

**Type:** Asynchronous Event Publishing  
**Direction:** Broadcast  
**Use Cases:** Cross-component communication, state synchronization

#### Architecture

```
Component A
    ↓ (publish)
EventBus.publish('event:name', payload)
    ↓ (broadcast)
All Subscribers
    ↓
Component B, Component C, ...
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Pattern** | Publish/Subscribe |
| **Delivery** | Synchronous (in-memory) |
| **Replay** | Optional (last message) |
| **Scope** | Frontend only |

#### Example

**Publish:**
```typescript
this.eventBus.publish('user:created', {
    userId: 123,
    username: 'john',
    timestamp: Date.now()
});
```

**Subscribe:**
```typescript
this.eventBus.subscribe('user:created', (payload) => {
    console.log('New user:', payload.username);
    this.loadUsers();  // Refresh user list
});
```

---

## WebUI Bridge Protocol

### Message Structure

**Request (Frontend → Backend):**
```typescript
{
    fn: string;      // Function name to call
    data: any;       // JSON-serializable payload
    callback?: id;   // Callback ID for async response
}
```

**Response (Backend → Frontend):**
```typescript
{
    success: boolean;
    data?: any;      // Response payload
    error?: {
        code: string;
        message: string;
        details?: string;
    };
}
```

### Handler Registration

**V Backend:**
```v
// Basic handler
w.bind('functionName', fn (e &ui.Event) string {
    // e.data contains request payload
    return json.encode(response)
})

// Handler with captured variables
w.bind('getUser', fn [api] (e &ui.Event) string {
    // api is captured from outer scope
    user := api.get_user_by_id(id)
    return json.encode(user)
})

// Handler with middleware
w.bind('createUser', fn [api, rate_limiter] (e &ui.Event) string {
    // Check rate limit first
    if !rate_limiter.is_allowed('user_create') {
        return '{"success":false,"error":"Rate limit exceeded"}'
    }
    
    // Process request
    user := api.create_user(req)
    return json.encode(user)
})
```

### Data Serialization

**Supported Types:**

| Type | Frontend | Backend | Notes |
|------|----------|---------|-------|
| String | `string` | `string` | UTF-8 encoded |
| Number | `number` | `int`, `f64` | Precision may vary |
| Boolean | `boolean` | `bool` | Direct mapping |
| Object | `{}` | `struct` | JSON encoding |
| Array | `[]` | `[]Type` | Homogeneous arrays |
| Null | `null` | `none` | Optional values |

**Unsupported Types:**
- Functions
- Class instances (must serialize first)
- Circular references
- `undefined` (use `null`)

---

## Error Handling

### Error Response Format

```json
{
    "success": false,
    "data": null,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Email is required",
        "details": "The email field cannot be empty",
        "field": "email"
    }
}
```

### Error Codes

| Code | HTTP Equivalent | Description |
|------|-----------------|-------------|
| `VALIDATION_ERROR` | 400 Bad Request | Input validation failed |
| `NOT_FOUND` | 404 Not Found | Resource not found |
| `UNAUTHORIZED` | 401 Unauthorized | Authentication required |
| `FORBIDDEN` | 403 Forbidden | Permission denied |
| `CONFLICT` | 409 Conflict | Resource conflict |
| `RATE_LIMITED` | 429 Too Many Requests | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 Internal Server Error | Server error |
| `SERVICE_UNAVAILABLE` | 503 Service Unavailable | Service down |

### Frontend Error Handling

```typescript
// Using Result type
async getUser(id: number): Promise<Result<User>> {
    const response = await window.call('getUserById', { id });
    const result = JSON.parse(response);
    
    if (result.success) {
        return ok(result.data);
    } else {
        return err({
            code: result.error.code,
            message: result.error.message
        });
    }
}

// Handling errors
const userResult = await getUser(123);
if (isOk(userResult)) {
    console.log('User:', userResult.value);
} else {
    console.error('Error:', userResult.error.message);
    this.notifications.error('Failed to load user');
}
```

### Backend Error Handling

```v
// Return structured error
pub fn get_user(api UserAPI, id int) !User {
    user := api.get_user_by_id(id) or {
        return error.not_found_error('user', id.str())
    }
    return user
}

// Handle in handler
w.bind('getUser', fn [api] (e &ui.Event) string {
    data := json.decode(map[string]string, e.data) or {
        return '{"success":false,"error":"Invalid request"}'
    }
    
    id := data['id'].int() or {
        return '{"success":false,"error":"Invalid ID"}'
    }
    
    user_result := api.get_user_by_id(id)
    if user_result is error {
        return '{"success":false,"error":"${user_result.msg}"}'
    }
    
    return '{"success":true,"data":${json.encode(user_result)}}'
})
```

---

## Security Considerations

### Input Validation

**Backend:**
```v
// Always validate input
pub fn create_user_from_req(mut api UserAPI, req CreateUserRequest) !User {
    if req.name.trim_space().len == 0 {
        return error('Name is required')
    }
    if !req.email.contains('@') {
        return error('Valid email is required')
    }
    if req.age < 1 || req.age > 150 {
        return error('Age must be between 1 and 150')
    }
    // ...
}
```

**Frontend:**
```typescript
// Client-side validation (defense in depth)
validateUser(user: CreateUserRequest): ValidationResult {
    const errors: string[] = [];
    
    if (!user.name?.trim()) {
        errors.push('Name is required');
    }
    if (!user.email?.includes('@')) {
        errors.push('Valid email is required');
    }
    
    return {
        isValid: errors.length === 0,
        errors
    };
}
```

### Rate Limiting

```v
// Backend rate limiting
w.bind('createUser', fn [api, rate_limiter] (e &ui.Event) string {
    rate_result := rate_limiter.check('client_ip', 'user_id')
    if !rate_result.allowed {
        return json.encode({
            'success': false
            'error': 'Rate limit exceeded'
            'retry_after': rate_result.retry_after
        })
    }
    // ...
})
```

### CSRF Protection

```v
// Token-based CSRF protection
w.bind('getCsrfToken', fn [csrf] (e &ui.Event) string {
    token := csrf.generate_token('session') or {
        return '{"success":false,"error":"Failed to generate token"}'
    }
    return json.encode({'success': true, 'csrf_token': token})
})

w.bind('deleteUser', fn [api, csrf] (e &ui.Event) string {
    data := json.decode(map[string]string, e.data) or {
        return '{"success":false,"error":"Invalid request"}'
    }
    
    // Validate CSRF token
    if !csrf.validate_token(data['csrf_token'], data['session_id']) {
        return '{"success":false,"error":"Invalid CSRF token"}'
    }
    // ...
})
```

---

## Best Practices

### 1. Use Type-Safe Interfaces

```typescript
// Define request/response types
interface GetUserRequest {
    id: number;
}

interface GetUserResponse {
    success: boolean;
    data?: User;
    error?: ErrorInfo;
}

// Use in handlers
async getUser(request: GetUserRequest): Promise<GetUserResponse> {
    const response = await window.call('getUserById', request);
    return JSON.parse(response) as GetUserResponse;
}
```

### 2. Implement Request Timeout

```typescript
async callWithTimeout(fn: string, data: any, timeoutMs: number = 30000): Promise<any> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    
    try {
        const result = await window.call(fn, data, { signal: controller.signal });
        clearTimeout(timeoutId);
        return result;
    } catch (error) {
        clearTimeout(timeoutId);
        if (error.name === 'AbortError') {
            throw new Error(`Request timeout after ${timeoutMs}ms`);
        }
        throw error;
    }
}
```

### 3. Add Request Deduplication

```typescript
private pendingRequests = new Map<string, Promise<any>>();

async callWithDedup(fn: string, data: any): Promise<any> {
    const key = `${fn}:${JSON.stringify(data)}`;
    
    // Return existing pending request
    if (this.pendingRequests.has(key)) {
        return this.pendingRequests.get(key);
    }
    
    const promise = window.call(fn, data);
    this.pendingRequests.set(key, promise);
    
    try {
        const result = await promise;
        return result;
    } finally {
        this.pendingRequests.delete(key);
    }
}
```

### 4. Log All Communications

```typescript
async callWithLogging(fn: string, data: any): Promise<any> {
    const startTime = Date.now();
    this.logger.debug('Calling backend', { fn, data });
    
    try {
        const result = await window.call(fn, data);
        const duration = Date.now() - startTime;
        this.logger.debug('Backend response', { fn, duration, success: true });
        return result;
    } catch (error) {
        const duration = Date.now() - startTime;
        this.logger.error('Backend error', { fn, duration, error });
        throw error;
    }
}
```

### 5. Handle Disconnections

```typescript
class ConnectionManager {
    private connected = signal(false);
    private reconnectAttempts = signal(0);
    
    async callWithReconnect(fn: string, data: any, maxRetries: number = 3): Promise<any> {
        for (let i = 0; i < maxRetries; i++) {
            try {
                const result = await window.call(fn, data);
                this.connected.set(true);
                this.reconnectAttempts.set(0);
                return result;
            } catch (error) {
                this.connected.set(false);
                this.reconnectAttempts.set(i + 1);
                
                if (i === maxRetries - 1) {
                    throw error;
                }
                
                // Exponential backoff
                await this.sleep(Math.pow(2, i) * 1000);
            }
        }
    }
    
    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
```

---

## Examples

### Complete CRUD Example

**Backend (V):**
```v
module main

import vwebui as ui
import json

// Create
w.bind('createUser', fn [api] (e &ui.Event) string {
    mut req := CreateUserRequest{}
    err := json.decode(e.json(), mut req)
    if err != nil {
        return '{"success":false,"error":"Invalid request"}'
    }

    user_result := api.create_user_from_req(req)
    if user_result is error {
        return '{"success":false,"error":"${user_result.msg}"}'
    }
    
    return '{"success":true,"data":${json.encode(user_result)}}'
})

// Read
w.bind('getUsers', fn [api] (e &ui.Event) string {
    users := api.get_all_users()
    return '{"success":true,"data":${json.encode(users)}}'
})

// Update
w.bind('updateUser', fn [api] (e &ui.Event) string {
    mut req := UpdateUserRequest{}
    err := json.decode(e.json(), mut req)
    if err != nil {
        return '{"success":false,"error":"Invalid request"}'
    }

    user_result := api.update_user_from_req(req)
    if user_result is error {
        return '{"success":false,"error":"${user_result.msg}"}'
    }
    
    return '{"success":true,"data":${json.encode(user_result)}}'
})

// Delete
w.bind('deleteUser', fn [api] (e &ui.Event) string {
    mut data := map[string]string{}
    err := json.decode(e.json(), mut data)
    if err != nil {
        return '{"success":false,"error":"Invalid request"}'
    }
    
    id := data['id'].int()
    if id == 0 {
        return '{"success":false,"error":"Invalid ID"}'
    }

    delete_result := api.delete_user_by_id(id)
    if delete_result is error {
        return '{"success":false,"error":"${delete_result.msg}"}'
    }

    return '{"success":true,"message":"User deleted"}'
})
```

**Frontend (TypeScript):**
```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
    private readonly http = inject(HttpService);

    async getUsers(): Promise<Result<User[]>> {
        return this.http.get<User[]>('getUsers');
    }

    async createUser(user: CreateUserRequest): Promise<Result<User>> {
        return this.http.post<User>('createUser', user);
    }

    async updateUser(user: UpdateUserRequest): Promise<Result<User>> {
        return this.http.put<User>('updateUser', user);
    }

    async deleteUser(id: number): Promise<Result<void>> {
        return this.http.post<void>('deleteUser', { id: id.toString() });
    }
}

// Usage in component
@Component({...})
export class UserListComponent {
    private readonly userService = inject(UserService);
    users = signal<User[]>([]);

    async loadUsers() {
        const result = await this.userService.getUsers();
        if (isOk(result)) {
            this.users.set(result.value);
        }
    }

    async deleteUser(user: User) {
        const result = await this.userService.deleteUser(user.id);
        if (isOk(result)) {
            this.users.update(users => users.filter(u => u.id !== user.id));
        }
    }
}
```

---

## Performance Optimization

### 1. Batch Requests

```v
// Backend batch endpoint
w.bind('getUsersBatch', fn [api] (e &ui.Event) string {
    mut ids := []int{}
    json.decode(e.json(), mut ids) or {
        return '{"success":false,"error":"Invalid request"}'
    }

    mut users := []User{}
    for id in ids {
        user := api.get_user_by_id(id) or { continue }
        users << user
    }

    return '{"success":true,"data":${json.encode(users)}}'
})
```

### 2. Response Caching

```typescript
// Frontend caching
async getUsersWithCache(): Promise<User[]> {
    const cached = this.storage.get<User[]>('users_cache');
    if (cached) {
        return cached;
    }

    const result = await this.userService.getUsers();
    if (isOk(result)) {
        this.storage.set('users_cache', result.value, { ttl: 60000 });
        return result.value;
    }
    
    return [];
}
```

### 3. Optimistic Updates

```typescript
async updateUserOptimistic(user: UpdateUserRequest) {
    // Update UI immediately
    this.users.update(users => 
        users.map(u => u.id === user.id ? { ...u, ...user } : u)
    );

    // Send to backend
    const result = await this.userService.updateUser(user);
    
    // Revert on error
    if (!isOk(result)) {
        this.loadUsers();  // Reload from server
        this.notifications.error('Update failed');
    }
}
```

---

*Created: 2026-03-14*
