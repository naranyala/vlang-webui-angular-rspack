# API Reference

Complete API documentation for Desktop Dashboard.

---

## Table of Contents

1. [Overview](#overview)
2. [Request/Response Format](#requestresponse-format)
3. [User Endpoints](#user-endpoints)
4. [Product Endpoints](#product-endpoints)
5. [Order Endpoints](#order-endpoints)
6. [DevTools Endpoints](#devtools-endpoints)
7. [Error Codes](#error-codes)
8. [Rate Limiting](#rate-limiting)

---

## Overview

All API endpoints follow a consistent request/response pattern through the WebUI bridge.

### Base URL

```
webui://localhost:8080/api
```

### Authentication

Most endpoints require authentication via session token included in the request context.

---

## Request/Response Format

### Request Format

```typescript
interface ApiRequest {
  method: string;
  params?: Record<string, unknown>;
}
```

### Response Format

**Success:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

### Usage Example

```typescript
// TypeScript
const response = await api.call<User[]>('getUsers');
console.log(response.data);

// With params
const user = await api.call<User>('createUser', {
  name: 'John Doe',
  email: 'john@example.com',
  age: 28
});
```

---

## User Endpoints

### getUsers

Get all users.

**Method:** `getUsers`

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "age": 28,
      "created_at": "2026-03-29T10:00:00Z"
    }
  ]
}
```

**Example:**
```typescript
const users = await api.call<User[]>('getUsers');
```

---

### getUserById

Get user by ID.

**Method:** `getUserById`

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | number | Yes | User ID |

**Request:**
```json
{
  "method": "getUserById",
  "params": { "id": 1 }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "age": 28,
    "created_at": "2026-03-29T10:00:00Z"
  }
}
```

**Example:**
```typescript
const user = await api.call<User>('getUserById', { id: 1 });
```

---

### createUser

Create a new user.

**Method:** `createUser`

**Parameters:**
| Name | Type | Required | Validation |
|------|------|----------|------------|
| name | string | Yes | Min 1 character |
| email | string | Yes | Valid email format |
| age | number | Yes | 1-150 |

**Request:**
```json
{
  "method": "createUser",
  "params": {
    "name": "Jane Smith",
    "email": "jane@example.com",
    "age": 34
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 6,
    "name": "Jane Smith",
    "email": "jane@example.com",
    "age": 34,
    "created_at": "2026-03-29T12:00:00Z"
  },
  "message": "User created successfully"
}
```

**Example:**
```typescript
const user = await api.call<User>('createUser', {
  name: 'Jane Smith',
  email: 'jane@example.com',
  age: 34
});
```

**Errors:**
| Code | Message |
|------|---------|
| VALIDATION_ERROR | Name is required |
| VALIDATION_ERROR | Invalid email format |
| VALIDATION_ERROR | Age must be between 1 and 150 |

---

### updateUser

Update an existing user.

**Method:** `updateUser`

**Parameters:**
| Name | Type | Required | Validation |
|------|------|----------|------------|
| id | number | Yes | Must exist |
| name | string | Yes | Min 1 character |
| email | string | Yes | Valid email format |
| age | number | Yes | 1-150 |

**Request:**
```json
{
  "method": "updateUser",
  "params": {
    "id": 1,
    "name": "John Updated",
    "email": "john.updated@example.com",
    "age": 29
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Updated",
    "email": "john.updated@example.com",
    "age": 29,
    "created_at": "2026-03-29T10:00:00Z"
  }
}
```

**Example:**
```typescript
const user = await api.call<User>('updateUser', {
  id: 1,
  name: 'John Updated',
  email: 'john.updated@example.com',
  age: 29
});
```

---

### deleteUser

Delete a user.

**Method:** `deleteUser`

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | number | Yes | User ID |

**Request:**
```json
{
  "method": "deleteUser",
  "params": { "id": 1 }
}
```

**Response:**
```json
{
  "success": true,
  "message": "User deleted"
}
```

**Example:**
```typescript
await api.call('deleteUser', { id: 1 });
```

---

### getUserStats

Get user statistics.

**Method:** `getUserStats`

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "data": {
    "total_users": 5,
    "today_count": 0,
    "unique_domains": 3
  }
}
```

**Example:**
```typescript
const stats = await api.call<UserStats>('getUserStats');
```

---

## Product Endpoints

### getProducts

Get all products.

**Method:** `getProducts`

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Laptop Pro",
      "description": "High-performance laptop",
      "price": 1299.99,
      "stock": 50,
      "category": "Electronics",
      "created_at": "2026-03-29T10:00:00Z"
    }
  ]
}
```

**Example:**
```typescript
const products = await api.call<Product[]>('getProducts');
```

---

### createProduct

Create a new product.

**Method:** `createProduct`

**Parameters:**
| Name | Type | Required | Validation |
|------|------|----------|------------|
| name | string | Yes | Min 1 character |
| description | string | No | - |
| price | number | Yes | Must be positive |
| stock | number | Yes | Non-negative |
| category | string | No | - |

**Request:**
```json
{
  "method": "createProduct",
  "params": {
    "name": "New Product",
    "description": "Product description",
    "price": 99.99,
    "stock": 100,
    "category": "Electronics"
  }
}
```

**Example:**
```typescript
const product = await api.call<Product>('createProduct', {
  name: 'New Product',
  description: 'Product description',
  price: 99.99,
  stock: 100,
  category: 'Electronics'
});
```

---

### updateProduct

Update an existing product.

**Method:** `updateProduct`

**Parameters:**
| Name | Type | Required |
|------|------|----------|
| id | number | Yes |
| name | string | Yes |
| description | string | No |
| price | number | Yes |
| stock | number | Yes |
| category | string | No |

**Example:**
```typescript
const product = await api.call<Product>('updateProduct', {
  id: 1,
  name: 'Updated Product',
  price: 89.99,
  stock: 50
});
```

---

### deleteProduct

Delete a product.

**Method:** `deleteProduct`

**Parameters:**
| Name | Type | Required |
|------|------|----------|
| id | number | Yes |

**Example:**
```typescript
await api.call('deleteProduct', { id: 1 });
```

---

## Order Endpoints

### getOrders

Get all orders.

**Method:** `getOrders`

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "user_name": "John Doe",
      "items": [],
      "total": 1299.99,
      "status": "completed",
      "created_at": "2026-03-29T10:00:00Z"
    }
  ]
}
```

**Example:**
```typescript
const orders = await api.call<Order[]>('getOrders');
```

---

### createOrder

Create a new order.

**Method:** `createOrder`

**Parameters:**
| Name | Type | Required | Validation |
|------|------|----------|------------|
| user_id | number | Yes | Must exist |
| user_name | string | Yes | Min 1 character |
| items | array | No | - |
| total | number | Yes | Must be positive |
| status | string | No | pending/completed/shipped |

**Example:**
```typescript
const order = await api.call<Order>('createOrder', {
  user_id: 1,
  user_name: 'John Doe',
  items: [],
  total: 1299.99,
  status: 'pending'
});
```

---

### updateOrder

Update order status.

**Method:** `updateOrder`

**Parameters:**
| Name | Type | Required |
|------|------|----------|
| id | number | Yes |
| status | string | Yes |

**Example:**
```typescript
const order = await api.call<Order>('updateOrder', {
  id: 1,
  status: 'completed'
});
```

---

### deleteOrder

Delete an order.

**Method:** `deleteOrder`

**Parameters:**
| Name | Type | Required |
|------|------|----------|
| id | number | Yes |

**Example:**
```typescript
await api.call('deleteOrder', { id: 1 });
```

---

## DevTools Endpoints

### devtools.getStats

Get application statistics.

**Method:** `devtools.getStats`

**Response:**
```json
{
  "success": true,
  "data": {
    "uptime": 3600,
    "request_count": 150,
    "error_count": 2,
    "memory_usage": 45000000
  }
}
```

---

### devtools.getLogs

Get recent logs.

**Method:** `devtools.getLogs`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "timestamp": "2026-03-29T10:00:00Z",
      "level": "info",
      "message": "Application started"
    }
  ]
}
```

---

### devtools.getErrors

Get error reports.

**Method:** `devtools.getErrors`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "timestamp": "2026-03-29T10:05:00Z",
      "code": "API_ERROR",
      "message": "Failed to process request"
    }
  ]
}
```

---

### devtools.getMetrics

Get performance metrics.

**Method:** `devtools.getMetrics`

**Response:**
```json
{
  "success": true,
  "data": {
    "avg_response_time": 45,
    "requests_per_minute": 60,
    "cache_hit_rate": 0.85
  }
}
```

---

### devtools.getUptime

Get application uptime.

**Method:** `devtools.getUptime`

**Response:**
```json
{
  "success": true,
  "data": {
    "uptime": 3600
  }
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid input parameters |
| NOT_FOUND | 404 | Resource not found |
| UNAUTHORIZED | 401 | Authentication required |
| FORBIDDEN | 403 | Insufficient permissions |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Internal server error |

---

## Rate Limiting

### Limits

| Scope | Limit |
|-------|-------|
| Per minute | 60 requests |
| Per hour | 1000 requests |
| Burst | 10 requests |

### Response Headers

| Header | Description |
|--------|-------------|
| X-RateLimit-Limit-Minute | Requests per minute limit |
| X-RateLimit-Remaining-Minute | Remaining requests this minute |
| X-RateLimit-Limit-Hour | Requests per hour limit |
| X-RateLimit-Remaining-Hour | Remaining requests this hour |
| Retry-After | Seconds until retry (when rate limited) |

### Example

```
X-RateLimit-Limit-Minute: 60
X-RateLimit-Remaining-Minute: 59
X-RateLimit-Limit-Hour: 1000
X-RateLimit-Remaining-Hour: 999
```

When rate limited:
```
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "success": false,
  "error": "Rate limit exceeded",
  "retry_after": 60
}
```

---

*Last Updated: 2026-03-29*
