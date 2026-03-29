# Desktop Dashboard

A modern system monitoring and data management application built with V language backend and Angular frontend.

## Overview

Desktop Dashboard provides a complete solution for system monitoring, data management, and CRUD operations. It features a secure backend with password hashing, CSRF protection, and rate limiting, paired with a modern Angular frontend using signals and standalone components.

## Features

- System monitoring (CPU, Memory, Disk, Network)
- Process management
- SQLite and DuckDB storage backends
- Secure authentication with multi-round password hashing
- CSRF protection for state-changing operations
- Rate limiting for API endpoints
- Modern Angular UI with WebUI window management
- Responsive design with dark theme

## Technology Stack

### Backend
- **Language**: V 0.5.1+
- **Window Management**: WebUI
- **Storage**: SQLite / JSON-based persistence
- **Security**: Custom password hashing, CSRF tokens, rate limiting

### Frontend
- **Framework**: Angular 21
- **Bundler**: Rspack
- **Package Manager**: Bun
- **Styling**: CSS with dark theme
- **State Management**: Angular Signals

## Quick Start

### Prerequisites

- V Language 0.5.1 or higher
- Bun 1.0 or higher
- GCC 9.0 or higher
- GTK3 + WebKit (Linux only)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd starter-vlang-webui-angular-rspack
   ```

2. Run the setup script:
   ```bash
   ./scripts/dev-setup.sh
   ```

3. Start development mode:
   ```bash
   ./run.sh dev
   ```

4. Access the application at `http://localhost:8080`

### Manual Setup

If the setup script fails, follow these steps:

```bash
# Install backend dependencies
v install

# Install frontend dependencies
cd frontend
bun install

# Copy environment configuration
cd ..
cp .env.example .env

# Build the application
./run.sh build
```

## Project Structure

```
starter-vlang-webui-angular-rspack/
├── src/                          # V Backend Source
│   ├── main.v                    # Application entry point
│   ├── api_handlers.v            # API request handlers
│   ├── validator.v               # Validation pipeline
│   ├── rate_limiter.v            # Rate limiting middleware
│   ├── json_storage_service.v    # Data storage service
│   ├── security/                 # Security modules
│   │   ├── password.v            # Password hashing
│   │   ├── token.v               # Token generation
│   │   └── validation.v          # Input validation
│   └── errors/                   # Error handling
│
├── frontend/                     # Angular Frontend
│   ├── src/
│   │   ├── views/                # Page components
│   │   ├── core/                 # Core services
│   │   ├── models/               # TypeScript interfaces
│   │   └── types/                # Type definitions
│   └── package.json
│
├── data/                         # Application Data
│   └── duckdb_demo.json
│
├── docs/                         # Documentation
│   ├── 00-DOCUMENTATION.md       # Main documentation
│   ├── 01-CRUD-DEMOS.md          # CRUD demos
│   └── DEVELOPER_EXPERIENCE_IMPROVEMENTS.md
│
├── build/                        # Build Output
│   └── desktop-dashboard
│
├── scripts/                      # Utility Scripts
│   └── dev-setup.sh
│
├── .env.example                  # Environment template
├── LICENSE                       # MIT License
├── CHANGELOG.md                  # Version history
├── README.md                     # This file
├── run.sh                        # Main build script
└── build.config.sh               # Build configuration
```

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Start development mode |
| `./run.sh build` | Build production version |
| `./run.sh test` | Run all tests |
| `./run.sh clean` | Clean build artifacts |
| `./run.sh help` | Show help message |

## Configuration

Copy `.env.example` to `.env` and configure your environment:

```bash
cp .env.example .env
```

### Key Configuration Options

```bash
# Application
APP_ENV=development
APP_DEBUG=true
APP_NAME="Desktop Dashboard"

# Server
SERVER_HOST=localhost
SERVER_PORT=8080

# Database
DB_PATH=data/duckdb_demo.json
DB_DEMO_MODE=true

# Security
SESSION_TIMEOUT=3600
CSRF_TIMEOUT=3600
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000

# Logging
LOG_LEVEL=info
LOG_TO_CONSOLE=true
LOG_TO_FILE=false
```

## Security Features

### Password Hashing

Passwords are hashed using multi-round key stretching with 10,000 iterations and entropy-based salt generation.

```v
// Hash a password
hash := hash_password("mypassword")
// Returns: v1$salt$10000$hash_value

// Verify a password
if verify_password("mypassword", hash) {
    // Password is valid
}
```

### Token Generation

High-entropy tokens are generated using xorshift64* algorithm for sessions, CSRF, and API keys.

```v
// Generate secure token
token := generate_secure_token("csrf")
// Returns: csrf_randomhex_timestamp
```

### Rate Limiting

API endpoints are protected with configurable rate limits:

- 60 requests per minute
- 1000 requests per hour
- 10 requests burst limit

Rate limit headers are included in responses:
```
X-RateLimit-Limit-Minute: 60
X-RateLimit-Remaining-Minute: 59
Retry-After: 60
```

### CSRF Protection

State-changing operations (POST, PUT, DELETE, PATCH) require CSRF tokens. Tokens are single-use and expire after 1 hour.

## API Endpoints

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `getUsers` | Get all users |
| GET | `getUserById` | Get user by ID |
| POST | `createUser` | Create new user |
| PUT | `updateUser` | Update user |
| DELETE | `deleteUser` | Delete user |
| GET | `getUserStats` | Get user statistics |

### Product Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `getProducts` | Get all products |
| POST | `createProduct` | Create new product |
| PUT | `updateProduct` | Update product |
| DELETE | `deleteProduct` | Delete product |

### Order Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `getOrders` | Get all orders |
| POST | `createOrder` | Create new order |
| PUT | `updateOrder` | Update order status |
| DELETE | `deleteOrder` | Delete order |

### DevTools Endpoints

| Endpoint | Description |
|----------|-------------|
| `devtools.getStats` | Get application statistics |
| `devtools.getLogs` | Get recent logs |
| `devtools.getErrors` | Get error reports |
| `devtools.getMetrics` | Get performance metrics |
| `devtools.getUptime` | Get application uptime |

## Testing

### Run All Tests

```bash
./run.sh test
```

### Backend Tests

```bash
v test src/
```

### Frontend Tests

```bash
cd frontend
bun test
```

### E2E Tests

```bash
cd frontend
bunx playwright test
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- [Main Documentation](docs/00-DOCUMENTATION.md) - Complete guide
- [CRUD Demos](docs/01-CRUD-DEMOS.md) - SQLite and DuckDB examples
- [Developer Experience](docs/DEVELOPER_EXPERIENCE_IMPROVEMENTS.md) - DX improvements
- [Architecture](docs/01-ARCHITECTURE.md) - System design
- [API Reference](docs/04-API_REFERENCE.md) - API documentation

## Development

### Hot Reload

For faster development, use hot reload:

```bash
# Backend with live reload
v -live run src/

# Frontend with HMR
cd frontend && bun run dev
```

### Code Style

#### V Backend

- Function naming: snake_case (`new_config_service`, `get_all_users`)
- Struct naming: PascalCase (`ConfigService`, `User`)
- Error handling: Use `or {}` blocks

#### TypeScript Frontend

- Use `inject()` for dependency injection
- Use signals for state management
- Avoid `any` types; use proper interfaces
- Use `LoggerService` instead of `console.log`

### Pre-commit Hooks

```bash
cd frontend
bun add -D husky lint-staged
bunx husky install
bunx husky add .husky/pre-commit "bunx lint-staged"
```

## Deployment

### Production Build

```bash
./run.sh build
```

### Docker Deployment

```bash
# Build Docker image
docker build -t desktop-dashboard .

# Run container
docker run -p 8080:8080 desktop-dashboard
```

### Environment Variables for Production

```bash
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=error
LOG_TO_FILE=true
DB_PATH=/var/lib/dashboard/data.json
```

## Troubleshooting

### V Compiler Not Found

```bash
git clone https://github.com/vlang/v
cd v
make
sudo ln -s $(pwd)/v /usr/local/bin/v
```

### GTK3/WebKit Missing (Linux)

```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev

# Fedora
sudo dnf install gtk3-devel webkit2gtk3-devel
```

### Frontend Build Fails

```bash
cd frontend
rm -rf node_modules
bun install
bun run build
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m "feat: add new feature"`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation
- Ensure all tests pass

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and recent changes.

## Support

For issues, questions, or contributions:

1. Check the [documentation](docs/)
2. Open a GitHub issue
3. Use GitHub Discussions for questions
4. Report security issues privately

## Acknowledgments

- V Language team for the V compiler
- Angular team for the Angular framework
- WebUI library for window management
- All contributors to this project

---

Last Updated: 2026-03-29
