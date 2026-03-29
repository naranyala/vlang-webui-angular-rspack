# Development

Developer guide for Desktop Dashboard.

---

## Table of Contents

1. [Development Setup](#development-setup)
2. [Code Style](#code-style)
3. [Testing](#testing)
4. [Debugging](#debugging)
5. [Common Tasks](#common-tasks)
6. [Pre-commit Hooks](#pre-commit-hooks)

---

## Development Setup

### IDE Configuration

**VS Code Extensions:**
- V Language Server
- Angular Language Service
- ESLint
- Prettier

### Hot Reload

```bash
# Backend with live reload
v -live run src/

# Frontend with HMR
cd frontend && bun run dev
```

---

## Code Style

### V Backend

**Naming Conventions:**
```v
// Functions: snake_case
pub fn new_config_service() &ConfigService {}
pub fn get_all_users() []User {}

// Structs: PascalCase
pub struct ConfigService {}
pub struct User {}

// Constants: UPPER_SNAKE_CASE
pub const MAX_USERS = 1000
```

**Error Handling:**
```v
// Use or {} blocks
user := storage.get_user_by_id(id) or {
    return error_response('User not found')
}

// Or propagate errors
pub fn get_user(id int) !User {
    return storage.get_user_by_id(id)
}
```

**Comments:**
```v
// Single line comment

// Multi-line comments
// use multiple //
// for consistency
```

### TypeScript Frontend

**Dependency Injection:**
```typescript
// Use inject() function
private readonly logger = inject(LoggerService);
private readonly api = inject(ApiService);

// Avoid constructor injection
// ❌ OLD
constructor(private logger: LoggerService) {}

// ✅ NEW
private readonly logger = inject(LoggerService);
constructor() {}
```

**State Management:**
```typescript
// Use signals
users = signal<User[]>([]);
isLoading = signal(false);

// Use computed
stats = computed(() => this.users().length);

// Use effects
effect(() => {
    console.log('Users changed:', this.users());
});
```

**Type Safety:**
```typescript
// ✅ GOOD: Proper types
interface User {
    id: number;
    name: string;
    email: string;
}

// ❌ BAD: Avoid any
const data: any = getData();
```

---

## Testing

### Run Tests

```bash
# All tests
./run.sh test

# Backend only
v test src/

# Frontend only
cd frontend && bun test

# E2E tests
cd frontend && bunx playwright test
```

### Backend Tests

```v
fn test_new_cache_service() {
    mut assert_count := 0
    
    cache := new_cache_service()
    assert cache.cache.len == 0
    assert_count++
    
    println('Tests passed: ${assert_count}')
}
```

### Frontend Tests

```typescript
import { describe, expect, it } from 'bun:test';

describe('ApiService', () => {
  it('should call backend', async () => {
    const api = new ApiService();
    const response = await api.call('test');
    expect(response.success).toBe(true);
  });
});
```

---

## Debugging

### Backend Debugging

```v
// Use println for debugging
println('Debug: ${variable}')

// Or use logger service
logger.info('Debug message')
logger.error('Error: ${err}')
```

### Frontend Debugging

```typescript
// Use LoggerService
private readonly logger = inject(LoggerService);

this.logger.info('Debug message', data);
this.logger.error('Error', error);

// Avoid console.log in production code
```

### DevTools

Access DevTools in the application:
- View application statistics
- Check recent logs
- Review error reports
- Monitor performance metrics

---

## Common Tasks

### Add New API Endpoint

1. **Backend Handler** (`src/api_handlers.v`):
```v
window_mgr.bind('getItems', fn [storage] (e &ui.Event) string {
    items := storage.get_all_items()
    return ok(json.encode(items))
})
```

2. **Frontend Service**:
```typescript
async getItems(): Promise<Item[]> {
    const response = await this.api.call<Item[]>('getItems');
    return response.data;
}
```

3. **Frontend Component**:
```typescript
items = signal<Item[]>([]);

async ngOnInit() {
    this.items.set(await this.api.getItems());
}
```

### Add New Model

1. **Backend Model** (`src/json_storage_service.v`):
```v
pub struct Item {
pub mut:
    id          int
    name        string
    created_at  string
}
```

2. **Frontend Interface** (`src/models/duckdb.models.ts`):
```typescript
export interface Item {
  id: number;
  name: string;
  created_at: string;
}
```

### Add New Service

1. **Create Service File** (`src/my_service.v`):
```v
module main

pub struct MyService {
pub mut:
    initialized bool
}

pub fn new_my_service() &MyService {
    return &MyService{
        initialized: false
    }
}

pub fn (mut s MyService) init() bool {
    s.initialized = true
    return true
}
```

2. **Register in main.v**:
```v
mut my_service := new_my_service()
my_service.init()
```

---

## Pre-commit Hooks

### Setup

```bash
cd frontend
bun add -D husky lint-staged
bunx husky install
bunx husky add .husky/pre-commit "bunx lint-staged"
```

### Configuration

```json
{
  "lint-staged": {
    "*.v": ["v fmt"],
    "*.ts": ["biome check --write"],
    "*.html": ["biome check --write"]
  }
}
```

---

*Last Updated: 2026-03-29*
