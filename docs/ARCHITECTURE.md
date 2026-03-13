# Architecture Overview

This document describes the architecture of the Desktop Dashboard application.

## System Architecture

The application follows a client-server architecture with the following components:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Angular   │  │   WinBox    │  │    Error Handling       │  │
│  │  Components │  │   Windows   │  │    Services             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                           │                                       │
│                    WebSocket                                      │
└───────────────────────────┼───────────────────────────────────────┘
                            │
                            │ WebUI Bridge
                            │
┌───────────────────────────┼───────────────────────────────────────┐
│                         Backend                                    │
│                           │                                       │
│  ┌─────────────┐  ┌───────┴───────┐  ┌─────────────────────────┐  │
│  │   WebUI     │  │   API         │  │    System               │  │
│  │   Server    │  │   Handlers    │  │    Modules              │  │
│  └─────────────┘  └───────────────┘  └─────────────────────────┘  │
│                           │                                       │
│                    Linux Sysfs/Procfs                             │
└───────────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend Components

#### Angular Components

- **AppComponent**: Main application container with top/bottom panels
- **HomeComponent**: Card grid for technology information
- **DevtoolsComponent**: Debugging and monitoring panel
- **ErrorModalComponent**: Error display dialog
- **ErrorBoundaryComponent**: Component error isolation

#### Services

- **GlobalErrorService**: Centralized error state management
- **ErrorInterceptor**: Captures and logs all errors
- **RetryService**: Exponential backoff retry logic
- **NetworkMonitorService**: Connectivity monitoring
- **ErrorTelemetryService**: Error tracking and reporting
- **ErrorRecoveryService**: Circuit breaker pattern
- **WinBoxService**: Window management

#### View Models

- **EventBusViewModel**: Event publishing and subscription
- **LoggerViewModel**: Structured logging
- **WindowStateViewModel**: Window state tracking

### Backend Components

#### Main Module (main.v)

Entry point that:
- Creates WebUI window
- Registers API handlers
- Serves frontend dist
- Manages application lifecycle

#### Error Module (error.v)

Provides:
- ErrorCode enum for structured errors
- ErrorValue struct for error data
- Error creation functions
- JSON serialization
- Error logging

#### System Module (system.v)

Provides:
- System information (hostname, OS, architecture)
- Memory statistics
- CPU information and usage
- Disk usage information
- Battery status (if available)
- Uptime tracking

#### Network Module (network.v)

Provides:
- Network interface listing
- Connection status
- Network statistics
- IP address information
- DNS server information
- MAC address information

#### Process Module (process.v)

Provides:
- Process listing
- System load averages
- Process statistics
- CPU usage per process

#### Filesystem Module (filesystem.v)

Provides:
- File information
- Directory listing
- File search
- File operations (read, write, copy, delete)

## Data Flow

### Request Flow

1. User interacts with frontend component
2. Component calls API client function
3. API client sends WebSocket message via WebUI
4. V backend receives call via bound handler
5. Handler executes system query
6. Result encoded as JSON
7. Response sent back via WebSocket
8. Frontend receives and processes response
9. Component updates UI

### Error Flow

1. Error occurs (backend or frontend)
2. Error converted to ErrorValue
3. Error logged via interceptor
4. Error reported to GlobalErrorService
5. Error displayed via ErrorModalComponent
6. Error recorded in telemetry service

## Communication Protocol

### WebUI Bindings

Backend functions are exposed to frontend via WebUI bindings:

```v
w.bind('getSystemInfo', fn (e &ui.Event) string {
    info := system.get_system_info()
    return json.encode(info)
})
```

### Frontend API Calls

Frontend calls backend functions via window object:

```typescript
const result = await callBackend<User[]>('getSystemInfo');
```

### Event System

Frontend uses custom events for responses:

```typescript
window.addEventListener('system_info_response', (event: CustomEvent) => {
    const data = event.detail;
    // Process response
});
```

## State Management

### Frontend State

State is managed using Angular signals:

```typescript
// Signal declaration
readonly windowEntries = signal<WindowEntry[]>([]);

// Signal update
this.windowEntries.update(entries => [...entries, newEntry]);

// Computed signal
readonly hasErrors = computed(() => this.errorCount() > 0);
```

### Backend State

Backend is stateless - each request is independent.

## Security Considerations

### Input Validation

- All frontend inputs validated before API calls
- Backend validates all parameters
- SQL injection prevented (no direct SQL)
- Path traversal prevented in filesystem operations

### Error Information

- Sensitive details not exposed to frontend
- Stack traces logged server-side only
- Error codes used for programmatic handling

## Performance Optimizations

### Frontend

- Lazy loading of components
- Signal-based reactivity (fine-grained updates)
- Debounced search input
- Limited result sets (pagination)

### Backend

- Efficient system file parsing
- Minimal memory allocations
- Direct sysfs/procfs access
- No intermediate databases

## Scalability

### Current Limitations

- Single-instance only
- No clustering support
- Limited to local system access

### Future Enhancements

- Multi-window support
- Remote system monitoring
- Plugin architecture
- Data persistence layer

## Dependencies

### Frontend Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| @angular/core | 21.x | Framework |
| @angular/common | 21.x | Common directives |
| @angular/forms | 21.x | Form handling |
| rxjs | 7.8.x | Reactive extensions |
| zone.js | 0.15.x | Change detection |
| winbox | 0.2.x | Window management |

### Backend Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| vwebui | latest | WebUI bindings |
| webui | 2.x | WebUI C library |
| civetweb | 1.17 | Embedded web server |

## Build Pipeline

### Frontend Build

1. TypeScript compilation (esbuild)
2. CSS processing (sass-loader)
3. Asset optimization
4. Bundle generation (Rspack)
5. Output to dist/browser

### Backend Build

1. V source compilation
2. C code compilation (webui.c, civetweb.c)
3. Linking with system libraries
4. Output to binary

## Testing Architecture

### Unit Tests

- Error type tests
- Service tests
- Utility function tests

### Integration Tests

- API call flow tests
- Error handling tests
- State management tests

### E2E Tests

- User workflow tests
- Cross-browser tests (planned)
