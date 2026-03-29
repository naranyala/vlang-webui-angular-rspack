# Serialization/Deserialization Evaluation

## Current Implementation Analysis

### Backend (V Language)

#### Response Serialization
```v
// Current approach: Manual JSON encoding
window_mgr.bind('getUsers', fn [db] (e &ui.Event) string {
    users := db.get_all_users()
    return '{"success":true,"data":${json.encode(users)}}'
})
```

**Issues:**
1. ❌ Manual JSON string construction - error-prone
2. ❌ No type safety for response structure
3. ❌ Inconsistent error response format
4. ❌ Numbers serialized as strings in some cases (age_str, id_str)
5. ❌ No centralized error handling

#### Request Deserialization
```v
// Current approach: Decode to map[string]string
user_data := json.decode(map[string]string, e.element) or {
    return '{"success":false,"error":"Invalid JSON"}'
}
name := user_data['name'] or { '' }
age_str := user_data['age'] or { '0' }
age := age_str.int()  // Manual type conversion needed!
```

**Issues:**
1. ❌ All values decoded as strings - requires manual type conversion
2. ❌ No validation of required fields
3. ❌ Type conversions can fail silently
4. ❌ Repetitive boilerplate code
5. ❌ f64 parsing: `price_str.f64()` - not robust

### Frontend (Angular/TypeScript)

#### Request Serialization
```typescript
// Current approach: JSON.stringify in component
await this.api.callOrThrow('updateUser', [
  JSON.stringify({
    id: this.editingUser()!.id,
    name: data.name || '',
    email: data.email || '',
    age: data.age || 25
  })
]);
```

**Issues:**
1. ❌ Manual JSON.stringify in each component
2. ❌ No centralized request formatting
3. ❌ Type information lost in serialization
4. ❌ Inconsistent null/undefined handling

#### Response Deserialization
```typescript
// Current approach: Generic ApiResponse<T>
async callOrThrow<T>(functionName: string, args: unknown[] = []): Promise<T> {
  const response = await this.call<T>(functionName, args);
  if (!response.success) {
    throw new Error(response.error ?? 'Unknown error');
  }
  return response.data as T;
}
```

**Issues:**
1. ✅ Good: Generic type parameter
2. ❌ No runtime type validation
3. ❌ Type assertion `as T` is unsafe
4. ❌ No transformation of snake_case to camelCase

## Data Flow Issues

### 1. Type Safety Gaps

```
Frontend (TypeScript)     Backend (V)          Frontend Response
-------------------       -------------        -----------------
age: number          →    age_str: string  →   age: any (untyped)
price: number        →    price_str: string →  price: any (untyped)
id: number           →    id_str: string   →   id: any (untyped)
```

**Problem**: Numbers become strings, then get parsed back with no validation

### 2. Inconsistent Error Handling

```v
// Sometimes returns error field
return '{"success":false,"error":"${err.msg}"}'

// Sometimes returns message field  
return '{"success":true,"message":"User deleted"}'
```

### 3. Missing Field Validation

No validation for:
- Required fields
- Email format
- Number ranges
- String lengths

### 4. No Request/Response Standardization

Each handler implements its own:
- JSON parsing logic
- Error handling
- Response format

## Recommended Improvements

### Backend Improvements

1. **Centralized Response Type**
```v
pub struct ApiResponse[T] {
    success bool
    data    T
    error   string
    message string
}
```

2. **Helper Functions**
```v
fn ok_response[T](data T) string {
    return json.encode(ApiResponse[T]{
        success: true
        data: data
    })
}

fn error_response(msg string) string {
    return json.encode(ApiResponse[void]{
        success: false
        error: msg
    })
}
```

3. **Type-Safe Request Parsing**
```v
pub struct CreateUserRequest {
    name  string
    email string
    age   int
}

// Direct decode to struct with validation
mut req := json.decode(CreateUserRequest, e.element) or {
    return error_response('Invalid request format')
}
if !validate_email(req.email) {
    return error_response('Invalid email format')
}
```

### Frontend Improvements

1. **Centralized Request Builder**
```typescript
export class RequestBuilder {
  static create<T>(data: T): string {
    return JSON.stringify(data);
  }
}
```

2. **Type Guards for Runtime Validation**
```typescript
export function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'name' in data &&
    typeof (data as any).id === 'number'
  );
}
```

3. **Transform snake_case to camelCase**
```typescript
function transformResponse<T>(data: unknown): T {
  return transformKeys(data, snakeToCamel);
}
```

## Implementation Priority

1. ✅ Backend: Centralized response type
2. ✅ Backend: Helper functions for responses
3. ✅ Backend: Request DTOs with validation
4. ✅ Frontend: Centralized request/response handling
5. ✅ Frontend: Type guards and validation
6. ✅ Frontend: Key transformation utilities
