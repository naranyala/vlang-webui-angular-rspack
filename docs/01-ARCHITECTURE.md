# Architecture

This document describes the Desktop Dashboard system architecture.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Backend Architecture](#backend-architecture)
3. [Frontend Architecture](#frontend-architecture)
4. [Communication Layer](#communication-layer)
5. [Data Flow](#data-flow)
6. [Security Architecture](#security-architecture)

---

## System Overview

```
+------------------------------------------------------------------+
|                     Desktop Dashboard                             |
+------------------------------------------------------------------+
|                                                                   |
|  +------------------+         +------------------+                |
|  |   Angular        |         |   WebUI          |                |
|  |   Frontend       |<------->|   Bridge         |                |
|  |  (Port 8080)     |  HTTP   |                  |                |
|  +------------------+         +--------+---------+                |
|                                       |                           |
|                               +-------v--------+                  |
|                               |   V Backend    |                  |
|                               |   (WebUI)      |                  |
|                               +-------+--------+                  |
|                                       |                           |
|              +------------------------+------------------------+  |
|              |                        |                        |  |
|       +------v------+         +-------v------+        +--------v-+|
|       |   Storage   |         |   Security |        |  System   ||
|       |   Service   |         |   Module   |        |  Monitor  ||
|       |  (JSON/SQL) |         |            |        |           ||
|       +-------------+         +------------+        +-----------+|
|                                                                   |
+------------------------------------------------------------------+
```

### Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Frontend | Angular 21 | User interface |
| WebUI Bridge | WebUI | Backend-frontend communication |
| Backend | V Language | Business logic, API |
| Storage | JSON/SQLite | Data persistence |
| Security | Custom | Authentication, authorization |
| System Monitor | V + OS APIs | System metrics |

---

## Backend Architecture

### Module Structure

```
+--------------------------------------------------+
|                      main.v                       |
|  (Entry point, service initialization, window)   |
+------------------------+--------------------------+
                         |
         +---------------+---------------+
         |               |               |
+--------v-----+  +------v------+  +-----v----------+
| api_handlers |  |  devtools   |  |window_manager  |
+--------------+  +-------------+  +----------------+
                         |
         +---------------+---------------+
         |               |               |
+--------v-----+  +------v------+  +-----v----------+
|   services   |  |  security   |  |    errors      |
+--------------+  +-------------+  +----------------+
```

### Service Layer

| Service | File | Purpose |
|---------|------|---------|
| ConfigService | config_service.v | Environment configuration |
| LoggerService | logger_service.v | Application logging |
| CacheService | cache_service.v | In-memory caching |
| ValidationService | validation_service.v | Input validation |
| JsonStorageService | json_storage_service.v | JSON file persistence |
| CommunicationService | communication.v | Backend-frontend messaging |
| DevToolsService | devtools.v | Developer tools |

### Security Module

| Component | File | Purpose |
|-----------|------|---------|
| Password Hashing | security/password.v | Multi-round key stretching |
| Token Generation | security/token.v | High-entropy tokens |
| Input Validation | security/validation.v | Sanitization functions |
| CSRF Protection | security/token.v | Single-use tokens |
| Rate Limiting | rate_limiter.v | API protection |

---

## Frontend Architecture

### Component Hierarchy

```
AppComponent
+-- DashboardComponent
|   +-- Navigation
|   +-- Content Area
|   |   +-- DuckdbUsersComponent
|   |   +-- DuckdbProductsComponent
|   |   +-- DuckdbOrdersComponent
|   |   +-- DataTableComponent (shared)
|   +-- DevToolsComponent
+-- AuthComponent
+-- HomeComponent
```

### Service Layer

| Service | Location | Purpose |
|---------|----------|---------|
| ApiService | core/api.service.ts | Backend API calls |
| LoggerService | core/logger.service.ts | Application logging |
| StorageService | core/storage.service.ts | Local storage |
| WebUIService | core/webui/webui.service.ts | WebUI communication |
| HttpService | core/http.service.ts | HTTP client wrapper |
| ThemeService | core/theme.service.ts | Theme management |
| WinBoxService | core/winbox.service.ts | Window management |

### State Management

```typescript
// Signal-based state (modern Angular)
export class DashboardComponent {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);
  
  // State signals
  activeView = signal<string>('README');
  isLoading = signal(false);
  users = signal<User[]>([]);
  products = signal<Product[]>([]);
  orders = signal<Order[]>([]);
  
  // Computed signals
  stats = computed(() => ({
    totalUsers: this.users().length,
    totalProducts: this.products().length,
    totalOrders: this.orders().length
  }));
}
```

---

## Communication Layer

### Backend-Frontend Communication

```
+----------------+                    +----------------+
|    Angular     |                    |   V Backend    |
|    Frontend    |                    |                |
|                |   webui.call()     |                |
|                |------------------->|                |
|                |                    |   Handler      |
|                |   Response JSON    |                |
|                |<-------------------|                |
|                |                    |                |
+----------------+                    +----------------+
```

### API Call Pattern

**Frontend Service:**
```typescript
@Injectable({ providedIn: 'root' })
export class ApiService {
  async call<T>(method: string, params?: any): Promise<ApiResponse<T>> {
    const response = await webui.call(method, JSON.stringify(params));
    return JSON.parse(response);
  }
}

// Usage
const users = await api.call<User[]>('getUsers');
```

**Backend Handler:**
```v
// Handler registration
window_mgr.bind('getUsers', fn [storage] (e &ui.Event) string {
    users := storage.get_all_users()
    return ok(json.encode(users))
})
```

### Response Format

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message"
}
```

---

## Data Flow

### CREATE Operation

```
+----------+     +----------+     +----------+     +----------+
|  User    |     |  Angular |     |   API    |     | Storage  |
|  Input   |     |  Frontend|     | Handler  |     | Service  |
+----+-----+     +----+-----+     +----+-----+     +----+-----+
     |               |               |               |
     | 1. Enter data |               |               |
     |-------------->|               |               |
     |               |               |               |
     |               | 2. Validate   |               |
     |               |-------------->|               |
     |               |               |               |
     |               |               | 3. Create     |
     |               |               |-------------->|
     |               |               |               |
     |               |               | 4. Return ID  |
     |               |               |<--------------|
     |               |               |               |
     |               | 5. Success    |               |
     |               |<--------------|               |
     |               |               |               |
     | 6. Confirm    |               |               |
     |<--------------|               |               |
     |               |               |               |
```

### READ Operation

```
+----------+     +----------+     +----------+     +----------+
|  User    |     |  Angular |     |   API    |     | Storage  |
|  Request |     |  Frontend|     | Handler  |     | Service  |
+----+-----+     +----+-----+     +----+-----+     +----+-----+
     |               |               |               |
     | 1. Request    |               |               |
     |-------------->|               |               |
     |               |               |               |
     |               | 2. GET /users |               |
     |               |-------------->|               |
     |               |               |               |
     |               |               | 3. Query      |
     |               |               |-------------->|
     |               |               |               |
     |               |               | 4. Return []  |
     |               |               |<--------------|
     |               |               |               |
     |               | 5. Render     |               |
     |               |<--------------|               |
     |               |               |               |
     | 6. Display    |               |               |
     |<--------------|               |               |
     |               |               |               |
```

---

## Security Architecture

### Password Hashing Flow

```
+----------+     +----------+     +----------+
|  User    |     | Password |     | Storage  |
|  Input   |     | Service  |     |          |
+----+-----+     +----+-----+     +----+-----+
     |               |               |
     | "password"    |               |
     |-------------->|               |
     |               |               |
     |               | Generate salt |
     |               |---------------|
     |               |               |
     |               | stretch_key   |
     |               | (10000x)      |
     |               |---------------|
     |               |               |
     |               | v1$salt$      |
     |               | iterations$   |
     |               | hash          |
     |               |-------------->|
     |               |               |
```

### Token Generation

```v
pub fn generate_secure_token(prefix string) string {
    // Generate 32 bytes of entropy
    random_bytes := generate_entropy_bytes(32)
    random_part := bytes_to_hex(random_bytes)
    
    // Add timestamp for uniqueness
    timestamp := time.now().unix_nano()
    
    return '${prefix}_${random_part}_${timestamp}'
}
```

### Rate Limiting

```
+----------+     +----------+     +----------+
| Request  |     |   Rate   |     | Handler  |
|          |     | Limiter  |     |          |
+----+-----+     +----+-----+     +----+-----+
     |               |               |
     |-------------->| check()       |
     |               |               |
     |               | - Per min     |
     |               | - Per hour    |
     |               | - Burst       |
     |               |               |
     |               | Execute or    |
     |               | Reject        |
     |               |-------------->|
     |               |               |
```

### CSRF Protection

1. Server generates unique token per session
2. Token included in forms/requests
3. Server validates token on state-changing operations
4. Token is single-use (invalidated after use)

---

## Deployment Architecture

### Development

```
+-------------------+     +-------------------+
|   V -live run     |     |   bun run dev     |
|   (Backend)       |     |   (Frontend)      |
+-------------------+     +-------------------+
         |                         |
         +------------+------------+
                      |
              +-------v-------+
              |   Browser     |
              | localhost:8080|
              +---------------+
```

### Production

```
+-------------------------------------------+
|           Production Server               |
+-------------------------------------------+
|                                           |
|  +------------------+                     |
|  |  nginx/Apache    |                     |
|  |  (Static files)  |                     |
|  +--------+---------+                     |
|           |                               |
|  +--------v---------+                     |
|  |  V Backend       |                     |
|  |  (Compiled)      |                     |
|  +--------+---------+                     |
|           |                               |
|  +--------v---------+                     |
|  |  Data Files      |                     |
|  |  (JSON/SQLite)   |                     |
|  +------------------+                     |
|                                           |
+-------------------------------------------+
```

---

*Last Updated: 2026-03-29*
