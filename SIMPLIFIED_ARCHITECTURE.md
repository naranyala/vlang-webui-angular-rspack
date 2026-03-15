# Simplified Architecture

This document describes the simplified architecture of the Desktop Dashboard application.

## Key Changes

### Backend (V Language)

**Before:**
- Complex DI container with `voidptr` casting
- Multiple abstraction layers (interfaces, registry, core/additional services)
- Middleware stack for validation and rate limiting
- Event bus for pub/sub communication
- 15+ files with overlapping responsibilities

**After:**
- Direct dependency injection at composition root
- Simple service implementations (one file per service)
- Inline validation and rate limiting
- Handler modules for API endpoints
- 8 core files with clear responsibilities

### Frontend (Angular)

**Before:**
- MVVM pattern with ViewModels
- Service facade pattern
- Complex error handling (5+ services)
- 19 core services

**After:**
- Direct service injection
- Simple error handling (1 service)
- 9 core services
- No ViewModels

## New Structure

```
src/
├── main.v                          # Entry point + composition root
├── services/
│   ├── config_service.v            # Configuration management
│   ├── logger_service.v            # Logging
│   ├── cache_service.v             # In-memory caching
│   ├── validation_service.v        # Input validation
│   ├── auth_service.v              # Authentication
│   └── sqlite_service.v            # Database operations
├── handlers/
│   ├── system_handlers.v           # System info endpoints
│   ├── network_handlers.v          # Network endpoints
│   ├── process_handlers.v          # Process endpoints
│   └── user_handlers.v             # User CRUD endpoints
├── models/                         # Data models (future)
└── utils/
    └── errors.v                    # Error types and rate limiter

frontend/src/
├── core/
│   ├── api.service.ts              # Backend communication
│   ├── logger.service.ts           # Logging
│   ├── storage.service.ts          # Local storage
│   ├── http.service.ts             # HTTP client
│   ├── notification.service.ts     # Toast notifications
│   ├── loading.service.ts          # Loading states
│   ├── theme.service.ts            # Theme switching
│   ├── clipboard.service.ts        # Clipboard ops
│   ├── network-monitor.service.ts  # Network status
│   └── winbox.service.ts           # Window management
├── features/
│   ├── auth/
│   │   └── auth.component.ts
│   └── sqlite/
│       └── sqlite.component.ts
└── views/
    └── app.component.ts            # Main component
```

## Dependency Injection Approach

### Backend - Composition Root

```v
fn main() {
    // Create services directly (no DI container)
    config := new_config_service()
    logger := new_logger_service()
    cache := new_cache_service()
    db := new_sqlite_service('users.db')
    auth := new_auth_service()

    // Create handlers with explicit dependencies
    system_handlers := new_system_handlers(cache)
    user_handlers := new_user_handlers(db, cache)

    // Bind handlers
    system_handlers.bind_all(mut window_mgr)
    user_handlers.bind_all(mut window_mgr)
}
```

### Frontend - Angular DI

```typescript
@Injectable({ providedIn: 'root' })
export class ApiService {
  // Simple, no dependencies
}

@Component({...})
export class AuthComponent {
  // Direct injection
  private readonly api = inject(ApiService);
  private readonly logger = inject(LoggerService);
}
```

## Benefits

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Backend files | 15+ | 8 | ~47% |
| Frontend services | 19 | 9 | ~53% |
| ViewModels | 5 | 0 | 100% |
| Error services | 5 | 1 | 80% |
| DI complexity | High | None | 100% |
| Lines of code | ~3000 | ~1200 | ~60% |

## Migration Notes

### Backend

1. **Removed DI Container**: Services are created directly in `main.v`
2. **Removed Interfaces**: Using concrete types directly
3. **Removed Middleware**: Validation/rate limiting in handlers
4. **Removed Event Bus**: Direct function calls

### Frontend

1. **Removed ViewModels**: Logic moved to services/components
2. **Removed Facade**: Services injected directly
3. **Simplified Error Handling**: Single notification service
4. **Removed Complex Services**: Retry, recovery, telemetry removed

## Testing

### Backend

```bash
# Build
v -cc gcc -o desktop-dashboard src/

# Run
v -cc gcc run src/
```

### Frontend

```bash
cd frontend

# Development
bun run dev

# Build
bun run build:rspack
```

## Future Improvements

1. Add unit tests for services
2. Add integration tests for handlers
3. Consider adding back lightweight DI if needed
4. Add TypeScript strict mode
5. Add backend request/response typing

## Rollback

To rollback to the original architecture:

```bash
# Backend
git checkout HEAD -- src/

# Frontend
git checkout HEAD -- frontend/src/
```

---

*Last Updated: 2026-03-14*
