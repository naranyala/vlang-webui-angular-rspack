# Documentation Index

Welcome to the Desktop Dashboard documentation. This directory contains comprehensive guides for the application.

## Getting Started

- [README](../README.md) - Main project overview and quick start guide

## Core Documentation

### Architecture

- [Architecture Overview](./ARCHITECTURE.md) - System architecture and component details
  - Component structure
  - Data flow
  - Communication protocol
  - State management

### Error Handling

- [Error Handling Guide](./ERROR_HANDLING.md) - Comprehensive error handling documentation
  - Backend error system
  - Frontend error system
  - Error services
  - Best practices

### Testing

- [Testing Guide](./TESTING.md) - Testing infrastructure and practices
  - Frontend testing with Bun
  - Backend testing with V
  - Writing tests
  - Running tests

### Deployment

- [Deployment Guide](./DEPLOYMENT.md) - Build and deployment instructions
  - Build process
  - Installation methods
  - Configuration
  - Troubleshooting

### API Reference

- [API Reference](./API_REFERENCE.md) - Backend API documentation
  - API handlers
  - Data types
  - Error responses

## Quick Reference

### Commands

```bash
# Development
./run.sh dev          # Start development mode
./run.sh build        # Production build
./run.sh clean        # Clean build artifacts

# Frontend
cd frontend
bun test              # Run tests
bun run build:rspack  # Build with Rspack

# Backend
v test src/           # Run V tests
v -cc gcc -o battery src/  # Build backend
```

### Project Structure

```
.
├── src/                    # V backend source
├── frontend/src/           # Angular frontend source
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md
│   ├── ERROR_HANDLING.md
│   ├── TESTING.md
│   ├── DEPLOYMENT.md
│   └── API_REFERENCE.md
└── thirdparty/             # Third-party libraries
```

### Key Files

| File | Purpose |
|------|---------|
| `src/main.v` | Backend entry point |
| `src/error.v` | Error handling module |
| `frontend/src/main.ts` | Frontend entry point |
| `frontend/src/types/error.types.ts` | Error type definitions |
| `run.sh` | Build automation |

## Documentation Maintenance

### Adding New Documentation

1. Create markdown file in `docs/`
2. Add to this index
3. Update cross-references
4. Commit with descriptive message

### Documentation Standards

- Use clear, concise language
- Include code examples
- Avoid emojis and informal language
- Use consistent formatting
- Include troubleshooting sections

### Review Process

1. Author creates documentation
2. Review for accuracy
3. Check for clarity
4. Verify code examples
5. Merge to main branch

## Support

For questions or issues:

1. Check relevant documentation
2. Search existing issues
3. Create new issue with details
4. Contact maintainers

## Version Information

| Component | Version |
|-----------|---------|
| Application | 1.0.0 |
| Documentation | 1.0.0 |
| Last Updated | 2026-03-13 |

## Contributing

Contributions to documentation are welcome. Please:

1. Follow existing style
2. Update relevant sections
3. Test code examples
4. Submit pull request

## License

Documentation is licensed under MIT License, same as the project.
