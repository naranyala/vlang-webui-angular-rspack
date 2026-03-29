# Architecture Overview

This document describes the architecture of the Desktop Dashboard application.

## System Architecture

The application follows a client-server architecture with dependency injection on both tiers and multiple communication protocols:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (Angular)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Angular   │  │   WinBox    │  │    Service Layer        │  │
│  │  Components │  │   Windows   │  │    (DI Injected)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│         │                │                    │                  │
│         │          WebUI Bridge           EventBus               │
│         │          (RPC Protocol)            │                  │
│         └────────────────┼───────────────────┘                  │
└──────────────────────────┼───────────────────────────────────────┘
                           │
                           │ WebUI Bridge (JavaScript ↔ V)
                           │
┌──────────────────────────┼───────────────────────────────────────┐
│                         Backend (V Language)                      │
│                          │                                        │
│  ┌─────────────┐  ┌──────┴───────┐  ┌─────────────────────────┐  │
│  │   WebUI     │  │   DI         │  │    Service Layer        │  │
│  │   Server    │  │   Container  │  │    (Injected Services)  │  │
│  └─────────────┘  └──────────────┘  └─────────────────────────┘  │
│                          │                                        │
│                   Linux Sysfs / Procfs                            │
└───────────────────────────────────────────────────────────────────┘
```

## Communication Protocols

The application uses three communication approaches:

| Protocol | Type | Direction | Use Case |
|----------|------|-----------|----------|
| **WebUI Bridge** | RPC | Bidirectional | Desktop window management, API calls |
| **HTTP/Fetch** | REST | Client→Server | Future web deployment, external APIs |
| **Event Bus** | Pub/Sub | Broadcast | Cross-component state sync |

See [05-COMMUNICATION.md](05-COMMUNICATION.md) for detailed protocol documentation.

## Component Layers

### Frontend Architecture

#### Presentation Layer
- **AppComponent** - Main container with collapsible panels
- **HomeComponent** - Card grid for technology browsing
- **DevtoolsComponent** - Debugging and monitoring tools
- **ErrorBoundaryComponent** - Error isolation and recovery
- **ErrorModalComponent** - Error display dialogs

#### Service Layer (Dependency Injected)
All services use Angular's `@Injectable({ providedIn: 'root' })`:

| Service | Purpose |
|---------|---------|
| `StorageService` | LocalStorage/SessionStorage with TTL |
| `HttpService` | HTTP client with caching and retry |
| `NotificationService` | Toast notification system |
| `LoadingService` | Loading spinner management |
| `ThemeService` | Dark/light theme switching |
| `ClipboardService` | Clipboard operations |
| `RetryService` | Retry with exponential backoff |
| `NetworkMonitorService` | Network connectivity monitoring |

#### State Management
- **Signals** - Angular's reactive primitives
- **ViewModels** - Business logic with computed signals
- **EventBus** - Pub/sub for cross-component communication

### Backend Architecture

#### Presentation Layer
- **main.v** - Application entry point
- **WebUI Handlers** - API endpoint bindings

#### Service Layer (Dependency Injected)
Services registered in DI container with lifecycles:

| Service | Lifecycle | Purpose |
|---------|-----------|---------|
| `ConfigService` | Singleton | Configuration management |
| `CacheService` | Singleton | In-memory caching with TTL |
| `LoggerService` | Singleton | Structured logging |
| `ValidationService` | Singleton | Input validation |
| `MetricsService` | Singleton | Application metrics |
| `HealthCheckService` | Singleton | Health monitoring |
| `AuthService` | Singleton | Authentication |
| `DatabaseService` | Singleton | Database operations |
| `HttpClientService` | Singleton | HTTP client |
| `SystemInfoService` | Singleton | System information |

#### Data Access Layer
- **system.v** - System information via /proc and /sys
- **network.v** - Network interfaces and statistics
- **process.v** - Process management
- **filesystem.v** - File operations

## Data Flow

### Request Flow (Frontend → Backend)

```
1. User Action
       ↓
2. Component Event Handler
       ↓
3. Service Call (via DI)
       ↓
4. HTTP/WebSocket via WebUI
       ↓
5. Backend Handler (via DI Container)
       ↓
6. Service Execution
       ↓
7. Result/Error Response
       ↓
8. Frontend State Update
       ↓
9. UI Re-render (via Signals)
```

### Error Flow

```
1. Error Occurs
       ↓
2. Error Wrapped in Result Type
       ↓
3. Propagated Up Call Stack
       ↓
4. Handler Matches on Result
       ↓
5. Error Logged (via LoggerService)
       ↓
6. Error Response Sent to Frontend
       ↓
7. Frontend Displays Error (via NotificationService)
```

## Design Patterns

### Dependency Injection

**Backend (V):**
```v
// Create container
mut container := di.new_container()

// Register services
container.register_singleton_fn('logger', fn () voidptr {
    return new_logger_service()
})

// Resolve services
logger := container.resolve('logger') or { panic('No logger') }
```

**Frontend (Angular):**
```typescript
@Injectable({ providedIn: 'root' })
export class StorageService {
  // Automatically injected
}

// Usage via facade
constructor(private services: AppServices) {}

this.services.storage.set('key', 'value');
```

### Errors as Values

**Backend:**
```v
pub fn get_user(id int) result.Result[User] {
    if id <= 0 {
        return result.err[User](error.validation_error('id', 'Invalid'))
    }
    return result.ok[User](user)
}
```

**Frontend:**
```typescript
async getUser(id: number): Promise<Result<User>> {
    if (id <= 0) {
        return err({ code: 'VALIDATION_ERROR', message: 'Invalid' });
    }
    return ok(user);
}
```

### Event-Driven Architecture

**Backend Event Bus:**
```v
mut event_bus := events.new_event_bus()
event_bus.subscribe('app:log', fn (event &events.Event) {
    println('Event: ${event.data}')
})
event_bus.publish('app:started', 'App started', 'main')
```

**Frontend Event Bus:**
```typescript
this.eventBus.subscribe('network:status_changed', (payload) => {
    console.log('Network status:', payload);
});
this.eventBus.publish('window:opened', { id: '1', title: 'Window' });
```

## Security Considerations

### Backend
- Input validation on all API handlers
- Error messages don't expose internal details
- File access restricted to allowed paths

### Frontend
- Error boundaries prevent cascade failures
- Sanitized error display
- Secure storage practices

## Performance Optimizations

### Frontend
- **Lazy Loading** - Components loaded on demand
- **Signal-based Updates** - Fine-grained reactivity
- **Caching** - HTTP responses cached with TTL
- **Debouncing** - Search and input handling

### Backend
- **Singleton Services** - Shared instances
- **Caching** - In-memory cache with TTL
- **Efficient System Access** - Direct /proc and /sys access
- **Minimal Allocations** - Stack-based where possible

## File Structure

```
vlang-webui-angular-rspack/
├── src/
│   ├── di.v                          # DI Container
│   ├── result.v                      # Result type
│   ├── error.v                       # Error definitions
│   ├── events.v                      # Event bus
│   ├── main.v                        # Entry point
│   ├── services/
│   │   ├── interfaces.v              # Interfaces
│   │   ├── core_services.v           # Core services
│   │   ├── additional_services.v     # Additional services
│   │   └── registry.v                # Registry
│   ├── system.v                      # System info
│   ├── network.v                     # Network
│   ├── process.v                     # Processes
│   └── filesystem.v                  # Filesystem
├── frontend/src/
│   ├── core/                         # Services
│   ├── viewmodels/                   # State management
│   ├── models/                       # Data models
│   ├── types/                        # TypeScript types
│   └── views/                        # Components
├── docs/                             # Documentation
└── thirdparty/                       # Third-party libs
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Backend Language | V | System programming |
| Frontend Framework | Angular 21 | UI framework |
| Build Tool | Rspack | Fast bundling |
| Window Management | WebUI + WinBox.js | Native windows |
| State Management | Signals | Reactive state |
| DI Container | Custom (V) + Angular | Dependency injection |
| Error Handling | Result types | Errors as values |
