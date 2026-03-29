# Desktop Dashboard - Documentation

Welcome to the Desktop Dashboard documentation. This guide covers everything you need to know to develop, build, and deploy the application.

---

## Table of Contents

### 🚀 Getting Started
- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)

### 🏗️ Architecture
- [System Overview](#system-overview)
- [Backend Architecture](#backend-architecture)
- [Frontend Architecture](#frontend-architecture)
- [Communication Layer](#communication-layer)
- [Security Architecture](#security-architecture)

### 📚 API Reference
- [API Overview](#api-overview)
- [User Endpoints](#user-endpoints)
- [Product Endpoints](#product-endpoints)
- [Order Endpoints](#order-endpoints)
- [DevTools Endpoints](#devtools-endpoints)

### 🔒 Security
- [Password Hashing](#password-hashing)
- [Token Generation](#token-generation)
- [CSRF Protection](#csrf-protection)
- [Rate Limiting](#rate-limiting)
- [Input Validation](#input-validation)

### 🛠️ Development
- [Developer Experience Guide](#developer-experience-guide)
- [Code Style](#code-style)
- [Testing](#testing)
- [Debugging](#debugging)
- [Common Tasks](#common-tasks)

### 📦 Deployment
- [Build Process](#build-process)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Docker Deployment](#docker-deployment)

### 📝 Changelog
- [Recent Changes](#recent-changes)
- [Migration Guide](#migration-guide)

---

## Getting Started

### Introduction

Desktop Dashboard is a system monitoring application with:

- **Backend**: V language with WebUI for window management
- **Frontend**: Angular 21 with Rspack bundler
- **Storage**: JSON file-based persistence
- **Security**: Password hashing, CSRF protection, rate limiting

**Key Features:**
- System monitoring (CPU, Memory, Disk, Network)
- Process management
- CRUD operations with JSON storage
- Secure authentication
- Modern Angular UI with WebUI windows

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd starter-vlang-webui-angular-rspack

# Quick setup
./scripts/dev-setup.sh

# Start development mode
./run.sh dev

# Or use Makefile (if available)
make dev
```

Access the application at `http://localhost:8080`.

### Installation

#### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| V Language | 0.5.1+ | Backend development |
| Bun | 1.0+ | Frontend package manager |
| GCC | 9.0+ | C compiler for V |
| GTK3 + WebKit | Latest | Window management (Linux) |

#### Install Dependencies

```bash
# Backend dependencies
v install

# Frontend dependencies
cd frontend
bun install

# Verify installation
cd ..
./run.sh build
```

#### Troubleshooting

**Issue: V compiler not found**
```bash
# Install V language
git clone https://github.com/vlang/v
cd v
make
sudo ln -s $(pwd)/v /usr/local/bin/v
```

**Issue: GTK3/WebKit missing (Linux)**
```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev

# Fedora
sudo dnf install gtk3-devel webkit2gtk3-devel

# Arch
sudo pacman -S gtk3 webkit2gtk
```

### Development Setup

#### 1. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

**Key Settings:**
```bash
APP_ENV=development
APP_DEBUG=true
SERVER_PORT=8080
DB_PATH=data/duckdb_demo.json
LOG_LEVEL=debug
```

#### 2. IDE Setup

**VS Code Extensions:**
- V Language Server (`vlang.v-language-server`)
- Angular Language Service (`Angular.ng-template`)
- ESLint (`dbaeumer.vscode-eslint`)
- Prettier (`esbenp.prettier-vscode`)

**Settings (`.vscode/settings.json`):**
```json
{
  "v.vexePath": "/usr/bin/v",
  "angular.enableIvy": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  }
}
```

#### 3. Pre-commit Hooks

```bash
# Install Husky
cd frontend
bun add -D husky lint-staged
bunx husky install

# Configure pre-commit
bunx husky add .husky/pre-commit "bunx lint-staged"
```

#### 4. Verify Setup

```bash
# Run all tests
./run.sh test

# Build production
./run.sh build

# Start development
./run.sh dev
```

### Project Structure

```
starter-vlang-webui-angular-rspack/
├── src/                          # V Backend Source
│   ├── main.v                    # Application entry point
│   ├── api_handlers.v            # API request handlers
│   ├── validator.v               # Validation pipeline
│   ├── api_response.v            # Response helpers
│   ├── rate_limiter.v            # Rate limiting middleware
│   ├── json_storage_service.v    # Data storage service
│   ├── config_service.v          # Configuration service
│   ├── logger_service.v          # Logging service
│   ├── cache_service.v           # Caching service
│   ├── communication.v           # Backend communication
│   ├── devtools.v                # Developer tools
│   ├── window_manager.v          # Window management
│   ├── security/                 # Security modules
│   │   ├── password.v            # Password hashing
│   │   ├── token.v               # Token generation
│   │   └── validation.v          # Input validation
│   └── errors/                   # Error handling
│       ├── errors.v
│       └── types.v
│
├── frontend/                     # Angular Frontend
│   ├── src/
│   │   ├── views/                # Page components
│   │   │   ├── dashboard/
│   │   │   ├── auth/
│   │   │   ├── duckdb/
│   │   │   └── shared/
│   │   ├── core/                 # Core services
│   │   │   ├── api.service.ts
│   │   │   ├── logger.service.ts
│   │   │   ├── storage.service.ts
│   │   │   └── webui/
│   │   ├── models/               # TypeScript interfaces
│   │   ├── types/                # Type definitions
│   │   └── integration/          # Integration tests
│   ├── tests/
│   │   └── e2e/                  # E2E tests
│   ├── package.json
│   ├── angular.json
│   └── rspack.config.js
│
├── data/                         # Application Data
│   └── duckdb_demo.json
│
├── docs/                         # Documentation
│   ├── demos/                    # Demo files
│   └── testing/
│
├── build/                        # Build Output
│   └── desktop-dashboard
│
├── scripts/                      # Utility Scripts
│   └── dev-setup.sh
│
├── .env.example                  # Environment template
├── .gitignore                    # Git ignore rules
├── LICENSE                       # MIT License
├── README.md                     # Project overview
├── CHANGELOG.md                  # Version history
├── run.sh                        # Main build script
└── build.config.sh               # Build configuration
```

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Desktop Dashboard                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Angular    │◄───────►│   WebUI      │                 │
│  │   Frontend   │  HTTP   │   Bridge     │                 │
│  │  (Port 8080) │         │              │                 │
│  └──────────────┘         └──────┬───────┘                 │
│                                  │                          │
│                          ┌───────▼───────┐                 │
│                          │   V Backend    │                 │
│                          │   (WebUI)      │                 │
│                          └───────┬───────┘                 │
│                                  │                          │
│              ┌───────────────────┼───────────────────┐     │
│              │                   │                   │     │
│       ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐│
│       │   Storage   │    │   Security  │    │   System    ││
│       │   Service   │    │   Module    │    │   Monitor   ││
│       │  (JSON)     │    │             │    │             ││
│       └─────────────┘    └─────────────┘    └─────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Backend Architecture

#### Module Structure

```
┌─────────────────────────────────────────────────────────┐
│                      main.v                              │
│  (Entry point, service initialization, window setup)    │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
┌────────▼────┐ ┌────▼─────┐ ┌──▼──────────┐
│ api_handlers│ │ devtools │ │window_manager│
│   .v        │ │   .v     │ │    .v        │
└─────────────┘ └──────────┘ └──────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
┌────────▼────┐ ┌────▼─────┐ ┌──▼──────────┐
│   services  │ │ security │ │   errors    │
│   (various) │ │  module  │ │   module    │
└─────────────┘ └──────────┘ └──────────────┘
```

#### Service Layer

| Service | Purpose | File |
|---------|---------|------|
| ConfigService | Environment configuration | `config_service.v` |
| LoggerService | Application logging | `logger_service.v` |
| CacheService | In-memory caching | `cache_service.v` |
| ValidationService | Input validation | `validation_service.v` |
| JsonStorageService | JSON file persistence | `json_storage_service.v` |
| CommunicationService | Backend-frontend messaging | `communication.v` |
| DevToolsService | Developer tools | `devtools.v` |

#### Security Module

| Component | Purpose | File |
|-----------|---------|------|
| Password Hashing | Multi-round key stretching | `security/password.v` |
| Token Generation | High-entropy tokens | `security/token.v` |
| Input Validation | Sanitization functions | `security/validation.v` |
| CSRF Protection | Single-use tokens | `security/token.v` |
| Rate Limiting | API protection | `rate_limiter.v` |

### Frontend Architecture

#### Component Hierarchy

```
AppComponent
├── DashboardComponent
│   ├── Navigation
│   ├── Content Area
│   │   ├── DuckdbUsersComponent
│   │   ├── DuckdbProductsComponent
│   │   ├── DuckdbOrdersComponent
│   │   └── DataTableComponent (shared)
│   └── DevToolsComponent
├── AuthComponent
└── HomeComponent
```

#### Service Layer

| Service | Purpose | Location |
|---------|---------|----------|
| ApiService | Backend API calls | `core/api.service.ts` |
| LoggerService | Application logging | `core/logger.service.ts` |
| StorageService | Local storage | `core/storage.service.ts` |
| WebUIService | WebUI communication | `core/webui/webui.service.ts` |
| HttpService | HTTP client wrapper | `core/http.service.ts` |
| ThemeService | Theme management | `core/theme.service.ts` |
| WinBoxService | Window management | `core/winbox.service.ts` |

#### State Management

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

### Communication Layer

#### Backend-Frontend Communication

```
┌─────────────┐                    ┌─────────────┐
│   Angular   │                    │   V Backend │
│   Frontend  │                    │             │
│             │   webui.call()     │             │
│             │───────────────────►│             │
│             │                    │  Handler    │
│             │   Response JSON    │             │
│             │◄───────────────────│             │
│             │                    │             │
└─────────────┘                    └─────────────┘
```

#### API Call Pattern

```typescript
// Frontend service
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

#### Backend Handler Pattern

```v
// Handler registration
window_mgr.bind('getUsers', fn [storage] (e &ui.Event) string {
    users := storage.get_all_users()
    return ok(json.encode(users))
})
```

### Security Architecture

#### Password Hashing Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   User      │    │  Password   │    │   Storage   │
│   Input     │    │   Service   │    │             │
│             │    │             │    │             │
│ "mypassword"│───►│ generate    │───►│ v1$salt$    │
│             │    │ salt        │    │ iterations$ │
│             │    │             │    │ hash        │
│             │    │ stretch_key │    │             │
│             │    │ (10000x)    │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

#### Token Generation

```v
// High-entropy token generation
pub fn generate_secure_token(prefix string) string {
    // Generate 32 bytes of entropy
    random_bytes := generate_entropy_bytes(32)
    random_part := bytes_to_hex(random_bytes)
    
    // Add timestamp for uniqueness
    timestamp := time.now().unix_nano()
    
    return '${prefix}_${random_part}_${timestamp}'
}
```

#### Rate Limiting

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Request   │    │   Rate      │    │   Handler   │
│             │    │   Limiter   │    │             │
│             │───►│ check()     │───►│ Execute     │
│             │    │             │    │ or Reject   │
│             │    │ - Per min   │    │             │
│             │    │ - Per hour  │    │             │
│             │    │ - Burst     │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## API Reference

### API Overview

All API endpoints follow a consistent pattern:

**Request:**
```json
{
  "method": "endpoint_name",
  "params": { ... }
}
```

**Response:**
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

### User Endpoints

#### GET Users

```typescript
// Request
const response = await api.call<User[]>('getUsers');

// Response
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

#### CREATE User

```typescript
// Request
const response = await api.call<User>('createUser', {
  name: 'Jane Smith',
  email: 'jane@example.com',
  age: 34
});

// Validation Rules:
// - name: required, min 1 character
// - email: required, valid email format
// - age: required, 1-150
```

#### UPDATE User

```typescript
// Request
const response = await api.call<User>('updateUser', {
  id: 1,
  name: 'John Updated',
  email: 'john.updated@example.com',
  age: 29
});
```

#### DELETE User

```typescript
// Request
const response = await api.call('deleteUser', { id: 1 });

// Response
{
  "success": true,
  "message": "User deleted"
}
```

#### GET User Stats

```typescript
// Request
const response = await api.call<UserStats>('getUserStats');

// Response
{
  "success": true,
  "data": {
    "total_users": 5,
    "today_count": 0,
    "unique_domains": 3
  }
}
```

### Product Endpoints

#### GET Products

```typescript
const response = await api.call<Product[]>('getProducts');
```

#### CREATE Product

```typescript
const response = await api.call<Product>('createProduct', {
  name: 'Laptop Pro',
  description: 'High-performance laptop',
  price: 1299.99,
  stock: 50,
  category: 'Electronics'
});
```

#### UPDATE Product

```typescript
const response = await api.call<Product>('updateProduct', {
  id: 1,
  name: 'Laptop Pro Updated',
  description: 'Updated description',
  price: 1199.99,
  stock: 45,
  category: 'Electronics'
});
```

#### DELETE Product

```typescript
const response = await api.call('deleteProduct', { id: 1 });
```

### Order Endpoints

#### GET Orders

```typescript
const response = await api.call<Order[]>('getOrders');
```

#### CREATE Order

```typescript
const response = await api.call<Order>('createOrder', {
  user_id: 1,
  user_name: 'John Doe',
  items: [],
  total: 1299.99,
  status: 'pending'
});
```

#### UPDATE Order

```typescript
const response = await api.call<Order>('updateOrder', {
  id: 1,
  status: 'completed'
});
```

#### DELETE Order

```typescript
const response = await api.call('deleteOrder', { id: 1 });
```

### DevTools Endpoints

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `devtools.getStats` | Get statistics | Stats object |
| `devtools.getLogs` | Get recent logs | Log entries |
| `devtools.getErrors` | Get error reports | Error list |
| `devtools.getMetrics` | Get performance metrics | Metrics object |
| `devtools.getUptime` | Get application uptime | Uptime seconds |
| `devtools.log` | Log a message | Success |
| `devtools.reportError` | Report an error | Success |
| `devtools.clearLogs` | Clear logs | Success |
| `devtools.clearErrors` | Clear errors | Success |

---

## Security

### Password Hashing

#### Implementation

```v
// Multi-round key stretching (10,000 iterations)
pub fn hash_password(password string) string {
    salt := generate_salt(password)
    iterations := 10000
    hash := stretch_key(password, salt, iterations)
    return 'v1$${salt}$${iterations}$${hash}'
}
```

#### Salt Generation

```v
fn generate_salt(password string) string {
    now := time.now()
    // Multiple entropy sources
    entropy := '${now.unix_nano()}_${password.len}_${int(password[0])}'
    
    // Generate 16-character salt
    salt_chars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    // ... salt generation logic
    return salt
}
```

#### Verification

```v
pub fn verify_password(password string, hash_string string) bool {
    parts := hash_string.split('$')
    salt := parts[1]
    iterations := parts[2].int()
    stored_hash := parts[3]
    
    computed_hash := stretch_key(password, salt, iterations)
    return secure_compare(computed_hash, stored_hash)
}
```

### Token Generation

#### High-Entropy Tokens

```v
pub fn generate_secure_token(prefix string) string {
    // 32 bytes of entropy using xorshift64*
    random_bytes := generate_entropy_bytes(32)
    random_part := bytes_to_hex(random_bytes)
    timestamp := time.now().unix_nano()
    
    return '${prefix}_${random_part}_${timestamp}'
}
```

#### Token Types

| Type | Length | Use Case |
|------|--------|----------|
| Session Token | 64 bytes | User sessions |
| CSRF Token | 32 bytes | Form protection |
| API Key | 32 bytes | API authentication |
| Request ID | 16 bytes | Request tracking |

### CSRF Protection

#### Token Generation

```v
pub fn (mut p CSRFProtection) generate_token(user_id string) !string {
    // High-entropy random token
    random_bytes := generate_entropy_bytes(32)
    token := 'csrf_${bytes_to_hex(random_bytes)}'
    
    p.tokens[token] = CSRFToken{
        token: token
        user_id: user_id
        expires_at: now + 3600  // 1 hour
        used: false  // Single-use
    }
    
    return token
}
```

#### Token Validation

```v
pub fn (mut p CSRFProtection) validate_token(token string, user_id string) bool {
    stored := p.tokens[token] or { return false }
    
    // Single-use check
    if stored.used {
        p.tokens.delete(token)
        return false
    }
    
    // Expiration check
    if is_token_expired(stored.expires_at) {
        p.tokens.delete(token)
        return false
    }
    
    // User ID match
    if stored.user_id != user_id {
        return false
    }
    
    // Mark as used
    p.tokens[token].used = true
    return true
}
```

### Rate Limiting

#### Configuration

```v
pub fn default_rate_limit_config() RateLimitConfig {
    return RateLimitConfig{
        requests_per_minute: 60
        requests_per_hour: 1000
        burst_limit: 10
    }
}
```

#### Usage

```v
// Create rate limiter
rate_limiter := new_rate_limiter()

// Check if request is allowed
if !rate_limiter.is_allowed(user_id) {
    return rate_limit_response(60)  // Retry after 60 seconds
}

// Get rate limit headers
headers := rate_limiter.get_rate_limit_headers(user_id)
// X-RateLimit-Limit-Minute: 60
// X-RateLimit-Remaining-Minute: 59
```

### Input Validation

#### Sanitization Functions

```v
// Remove dangerous characters
pub fn sanitize_input(input string) !string {
    mut result := input.replace('\x00', '')
    result = result.replace('<script>', '')
    result = result.replace('javascript:', '')
    return result
}

// Remove HTML tags
pub fn sanitize_html(input string) string {
    mut in_tag := false
    mut output := ''
    for i := 0; i < input.len; i++ {
        c := input[i]
        if c == '<'[0] {
            in_tag = true
        } else if c == '>'[0] {
            in_tag = false
        } else if !in_tag {
            output += c.str()
        }
    }
    return output
}
```

#### Validation Functions

```v
// Validate email format
pub fn validate_email(email string) bool {
    return email.contains('@') && email.contains('.') && email.len > 5
}

// Validate username
pub fn sanitize_username(username string) !string {
    if username.len < 3 || username.len > 32 {
        return error('Username must be 3-32 characters')
    }
    // ... validation logic
    return username
}
```

---

## Development

### Developer Experience Guide

#### Quick Commands

```bash
# Start development
./run.sh dev

# Build production
./run.sh build

# Run tests
./run.sh test

# Clean build artifacts
./run.sh clean

# View help
./run.sh help
```

#### Hot Reload

```bash
# Backend with live reload
v -live run src/

# Frontend with HMR
cd frontend && bun run dev
```

#### Debugging

**Backend:**
```v
// Use println for debugging
println('Debug: ${variable}')

// Or use logger service
logger.info('Debug message')
logger.error('Error: ${err}')
```

**Frontend:**
```typescript
// Use LoggerService
private readonly logger = inject(LoggerService);
this.logger.info('Debug message', data);
this.logger.error('Error', error);
```

### Code Style

#### V Backend

```v
// Function naming: snake_case
pub fn new_config_service() &ConfigService {}
pub fn get_all_users() []User {}

// Struct naming: PascalCase
pub struct ConfigService {}
pub struct User {}

// Error handling
user := storage.get_user_by_id(id) or {
    return error_response('User not found')
}

// Comments: // for single line
// Multi-line comments use multiple //
```

#### TypeScript Frontend

```typescript
// Use inject() for DI
private readonly logger = inject(LoggerService);

// Signal-based state
users = signal<User[]>([]);
isLoading = signal(false);

// Computed values
stats = computed(() => this.users().length);

// Type annotations
interface User {
  id: number;
  name: string;
  email: string;
}
```

### Testing

#### Backend Tests

```v
// Test file: src/cache_service_test.v
fn test_new_cache_service() {
    mut assert_count := 0
    
    cache := new_cache_service()
    assert cache.cache.len == 0
    assert_count++
    
    println('Tests passed: ${assert_count}')
}
```

#### Frontend Tests

```typescript
// Test file: *.test.ts
import { describe, expect, it } from 'bun:test';

describe('ApiService', () => {
  it('should call backend', async () => {
    const api = new ApiService();
    const response = await api.call('test');
    expect(response.success).toBe(true);
  });
});
```

#### Run Tests

```bash
# All tests
./run.sh test

# Backend only
v test src/

# Frontend only
cd frontend && bun test
```

### Common Tasks

#### Add New API Endpoint

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

#### Add New Model

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

---

## Deployment

### Build Process

#### Production Build

```bash
# Full production build
./run.sh build

# Or manually:
# 1. Build frontend
cd frontend && bun run build

# 2. Build backend
cd .. && v -prod -o build/desktop-dashboard src/
```

#### Build Output

```
build/
└── desktop-dashboard    # Backend binary
frontend/
└── dist/
    └── browser/         # Frontend assets
        ├── index.html
        ├── *.js
        └── *.css
```

### Configuration

#### Environment Variables

```bash
# Copy template
cp .env.example .env

# Edit values
nano .env
```

**Production Settings:**
```bash
APP_ENV=production
APP_DEBUG=false
SERVER_PORT=8080
DB_PATH=/var/lib/dashboard/data.json
LOG_LEVEL=error
LOG_TO_FILE=true
LOG_FILE_PATH=/var/log/dashboard/app.log
```

### Docker Deployment

#### Dockerfile

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    v-lang \
    bun \
    gcc \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev

WORKDIR /app
COPY . .

# Build
RUN v -prod -o build/desktop-dashboard src/
RUN cd frontend && bun install && bun run build

# Run
CMD ["./build/desktop-dashboard"]
```

#### Docker Compose

```yaml
version: '3.8'
services:
  dashboard:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - dashboard-data:/app/data
    environment:
      - APP_ENV=production

volumes:
  dashboard-data:
```

---

## Changelog

### Recent Changes (2026-03-29)

#### Security Improvements

- **SEC-001:** Replaced weak password hashing with multi-round key stretching (10,000 iterations)
- **SEC-002:** Implemented high-entropy token generation using xorshift64*
- **SEC-003:** Added comprehensive rate limiting middleware
- **SEC-004:** Enhanced CSRF protection with single-use tokens

#### Architecture Changes

- Removed unnecessary DI system (-350 lines)
- Simplified communication system (5 channels → 1)
- Extracted API handlers from main.v (60% reduction)
- Added StorageService interface for testability
- Created validation pipeline for consistent validation

#### Code Quality

- Removed ~2,200 lines of dead/duplicate code
- Standardized DI pattern (inject() function)
- Removed `any` types, added proper interfaces
- Replaced console.log with LoggerService
- Removed redundant is_initialized() methods

#### Documentation

- Added comprehensive CHANGELOG.md
- Created .env.example template
- Added MIT LICENSE file
- Updated README with accurate information

### Migration Guide

#### Password Migration

Existing passwords will be re-hashed on next login:

```v
// Old passwords use timestamp-based salt
// New passwords use entropy-based salt with 10,000 iterations

// Automatic migration on login
if verify_password_old(password, hash) {
    // Re-hash with new algorithm
    new_hash := hash_password(password)
    update_user_hash(user_id, new_hash)
}
```

#### API Changes

Rate limit headers now included:

```
X-RateLimit-Limit-Minute: 60
X-RateLimit-Remaining-Minute: 59
X-RateLimit-Limit-Hour: 1000
X-RateLimit-Remaining-Hour: 999
Retry-After: 60  (if rate limited)
```

---

## Support

For issues, questions, or contributions:

1. **Documentation:** Check this documentation first
2. **Issues:** Open a GitHub issue
3. **Discussions:** Use GitHub Discussions for questions
4. **Security:** Report security issues privately

---

*Last Updated: 2026-03-29*
