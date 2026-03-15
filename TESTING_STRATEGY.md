# Comprehensive Testing Strategy

**Project:** vlang-webui-angular-rspack (Desktop Dashboard)
**Created:** 2026-03-14
**Last Updated:** 2026-03-14
**Target Coverage:** 90%+

---

## Executive Summary

This document outlines the comprehensive testing strategy to achieve maximum test coverage across backend (V) and frontend (Angular/TypeScript).

### Current State

| Category | Count | Coverage | Status |
|----------|-------|----------|--------|
| Backend Unit Tests | 11 files | ~60% | [DONE] Good |
| Frontend Unit Tests | 9 files | ~65% | [DONE] Good |
| Integration Tests | 2 files | ~40% | [WARNING] Needs Work |
| E2E Tests | 0 files | 0% | [TODO] Missing |
| Performance Tests | 0 files | 0% | [TODO] Missing |
| Security Tests | 0 files | 0% | [TODO] Missing |
| **Total** | **22 files** | **~55%** | [WARNING] **Needs Enrichment** |

### Target State

| Category | Target Files | Target Coverage | Priority |
|----------|--------------|-----------------|----------|
| Backend Unit Tests | 20 files | 90% | P0 |
| Frontend Unit Tests | 20 files | 90% | P0 |
| Integration Tests | 10 files | 85% | P0 |
| E2E Tests | 8 files | Critical paths | P1 |
| Performance Tests | 5 files | Key operations | P1 |
| Security Tests | 5 files | OWASP Top 10 | P0 |
| **Total** | **68 files** | **85%+** | - |

---

## Test Pyramid

```
                    /\
                   /  \
                  / E2E \              (10% - 8 tests)
                 /--------\
                / Integration\          (20% - 10 tests)
               /--------------\
              /   Unit Tests   \        (70% - 40 files)
             /------------------\
```

---

## Backend Testing (V Language)

### Unit Tests - Current Coverage

| Module | File | Tests | Coverage | Missing |
|--------|------|-------|----------|---------|
| **Core Services** |
| Config | `config_service_test.v` | 12 | 80% | File I/O errors |
| Logger | `logger_service_test.v` | 9 | 75% | File logging |
| Cache | `cache_service_test.v` | 14 | 85% | Edge cases |
| Validation | `validation_service_test.v` | 13 | 90% | - |
| Auth | `auth_service_test.v` | 15 | 80% | Token edge cases |
| SQLite | `sqlite_service_test.v` | 11 | 70% | Error handling |
| **Utils** |
| Errors | `errors_test.v` | 7 | 60% | More error types |
| Circuit Breaker | `circuit_breaker_test.v` | 8 | 75% | Timeout scenarios |
| **Integration** |
| Services | `integration_test.v` | 9 | 50% | More scenarios |
| **System** |
| Error | `error_test.v` | 20+ | 85% | - |
| System | `system_test.v` | 15+ | 80% | - |
| Network | `network_test.v` | 12+ | 75% | - |

### Unit Tests - Missing Coverage

#### 1. Security Module Tests (`security_test.v`) ⏹️ NEW
- [ ] Password hashing tests
- [ ] Password verification tests
- [ ] Token generation tests
- [ ] Token validation tests
- [ ] Input sanitization tests
- [ ] CSRF token tests
- [ ] Rate limiting tests

#### 2. Window Manager Tests (`window_manager_test.v`) ⏹️ NEW
- [ ] Window creation tests
- [ ] Window lifecycle tests
- [ ] Event binding tests
- [ ] Shutdown handler tests

#### 3. Handler Tests (Expanded)
- [ ] `system_handlers_test.v` - All endpoints
- [ ] `network_handlers_test.v` - All endpoints
- [ ] `process_handlers_test.v` - All endpoints
- [ ] `user_handlers_test.v` - All CRUD operations

#### 4. Edge Case Tests
- [ ] Empty inputs
- [ ] Maximum values
- [ ] Concurrent access
- [ ] Memory limits
- [ ] Timeout scenarios

### Integration Tests - Missing

#### 1. API Integration (`api_integration_test.v`) ⏹️ NEW
- [ ] Request/response flow
- [ ] Error propagation
- [ ] Rate limiting integration
- [ ] Validation pipeline

#### 2. Database Integration (`db_integration_test.v`) ⏹️ NEW
- [ ] Transaction handling
- [ ] Concurrent writes
- [ ] Data integrity
- [ ] Migration tests

#### 3. Security Integration (`security_integration_test.v`) ⏹️ NEW
- [ ] Auth flow
- [ ] CSRF protection
- [ ] Input validation chain
- [ ] Session management

---

## Frontend Testing (Angular/Bun)

### Unit Tests - Current Coverage

| Module | File | Tests | Coverage | Missing |
|--------|------|-------|----------|---------|
| **Core Services** |
| API | `api.service.test.ts` | 8 | 70% | Error scenarios |
| Logger | `logger.service.test.ts` | 10 | 80% | - |
| Storage | `storage.service.test.ts` | 18 | 85% | - |
| HTTP | [TODO] Missing | 0 | 0% | All |
| Notification | `notification.service.test.ts` | 12 | 80% | - |
| Loading | [TODO] Missing | 0 | 0% | All |
| Theme | [TODO] Missing | 0 | 0% | All |
| Clipboard | [TODO] Missing | 0 | 0% | All |
| Network Monitor | [TODO] Missing | 0 | 0% | All |
| WinBox | [TODO] Missing | 0 | 0% | All |
| **Components** |
| Auth | `auth.component.test.ts` | 12 | 70% | Error states |
| SQLite | `sqlite.component.test.ts` | 16 | 75% | Loading states |
| App | [TODO] Missing | 0 | 0% | All |
| Home | [TODO] Missing | 0 | 0% | All |
| **Types** |
| Error Types | `error.types.test.ts` | 20+ | 90% | - |
| Error Extended | `error.types.extended.test.ts` | 40+ | 95% | - |

### Unit Tests - Missing

#### 1. Service Tests ⏹️ NEW
- [ ] `http.service.test.ts` - HTTP client
- [ ] `loading.service.test.ts` - Loading states
- [ ] `theme.service.test.ts` - Theme switching
- [ ] `clipboard.service.test.ts` - Clipboard ops
- [ ] `network-monitor.service.test.ts` - Network status
- [ ] `winbox.service.test.ts` - Window management

#### 2. Component Tests ⏹️ NEW
- [ ] `app.component.test.ts` - Main app component
- [ ] `home.component.test.ts` - Home/dashboard
- [ ] `error-boundary.component.test.ts` - Error handling
- [ ] `loading-spinner.component.test.ts` - Loading UI

#### 3. Pipe Tests ⏹️ NEW
- [ ] `date-format.pipe.test.ts` - Date formatting
- [ ] `number-format.pipe.test.ts` - Number formatting
- [ ] `truncate.pipe.test.ts` - Text truncation

---

## Integration Tests

### Backend Integration

#### 1. Service Communication (`service_communication_test.v`) ⏹️ NEW
- [ ] Cache + Database interaction
- [ ] Auth + Validation flow
- [ ] Logger + All services

#### 2. API End-to-End (`api_e2e_test.v`) ⏹️ NEW
- [ ] Full request lifecycle
- [ ] Error handling chain
- [ ] Response formatting

### Frontend Integration

#### 1. Service Integration (Existing)
- [DONE] `services.integration.test.ts` - Service composition

#### 2. Component Integration (`component_integration.test.ts`) ⏹️ NEW
- [ ] Parent-child communication
- [ ] Service injection
- [ ] Event propagation

#### 3. API Integration (`api_integration.test.ts`) ⏹️ NEW
- [ ] Backend communication
- [ ] Error handling
- [ ] Loading states

---

## E2E Tests (Playwright)

### Test Scenarios

#### 1. App Loading (`app-loading.e2e.test.ts`) ⏹️ NEW
- [ ] App loads successfully
- [ ] WinBox is available
- [ ] Panels render correctly
- [ ] No console errors

#### 2. Authentication Flow (`auth-flow.e2e.test.ts`) ⏹️ NEW
- [ ] Open auth window
- [ ] Switch login/register tabs
- [ ] Form validation
- [ ] Submit credentials
- [ ] Error display

#### 3. SQLite CRUD (`sqlite-crud.e2e.test.ts`) ⏹️ NEW
- [ ] View user list
- [ ] Create new user
- [ ] Edit existing user
- [ ] Delete user
- [ ] Search/filter users
- [ ] Stats update

#### 4. Window Management (`window-management.e2e.test.ts`) ⏹️ NEW
- [ ] Open multiple windows
- [ ] Focus/blur windows
- [ ] Minimize/restore
- [ ] Close windows
- [ ] Window resize

#### 5. Responsive Design (`responsive.e2e.test.ts`) ⏹️ NEW
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)

#### 6. Error Handling (`error-handling.e2e.test.ts`) ⏹️ NEW
- [ ] Network errors
- [ ] API errors
- [ ] Validation errors
- [ ] Error display

#### 7. Performance (`performance.e2e.test.ts`) ⏹️ NEW
- [ ] Initial load time < 3s
- [ ] Window open time < 500ms
- [ ] API response time < 200ms

#### 8. Accessibility (`accessibility.e2e.test.ts`) ⏹️ NEW
- [ ] Keyboard navigation
- [ ] Screen reader support
- [ ] Color contrast
- [ ] Focus indicators

---

## Performance Tests

### Backend Performance

#### 1. Service Benchmarks (`service_benchmarks_test.v`) ⏹️ NEW
- [ ] Config service: get/set latency
- [ ] Cache service: operations/sec
- [ ] Validation service: validations/sec
- [ ] Database service: queries/sec

#### 2. API Performance (`api_performance_test.v`) ⏹️ NEW
- [ ] Request throughput
- [ ] Concurrent requests
- [ ] Memory usage under load

### Frontend Performance

#### 1. Component Benchmarks (`component_benchmarks.test.ts`) ⏹️ NEW
- [ ] Component render time
- [ ] Change detection cycles
- [ ] Memory leaks

#### 2. Bundle Analysis (`bundle_analysis.test.ts`) ⏹️ NEW
- [ ] Bundle size < 1MB
- [ ] Lazy loading effectiveness
- [ ] Tree shaking verification

---

## Security Tests

### OWASP Top 10 Coverage

#### 1. Injection Tests (`injection_security_test.v`) ⏹️ NEW
- [ ] SQL injection prevention
- [ ] Command injection prevention
- [ ] XSS prevention

#### 2. Authentication Tests (`auth_security_test.v`) ⏹️ NEW
- [ ] Password strength validation
- [ ] Token security
- [ ] Session management
- [ ] Brute force protection

#### 3. Input Validation Tests (`validation_security_test.v`) ⏹️ NEW
- [ ] Input sanitization
- [ ] Output encoding
- [ ] CSRF protection

#### 4. Data Protection Tests (`data_protection_test.v`) ⏹️ NEW
- [ ] Sensitive data encryption
- [ ] Secure storage
- [ ] Data masking

#### 5. Error Handling Tests (`error_security_test.v`) ⏹️ NEW
- [ ] No sensitive info in errors
- [ ] Proper error codes
- [ ] Error logging

---

## Test Implementation Priority

### P0 - Critical (Week 1-2)

1. **Security Tests** (5 files)
   - All OWASP Top 10 coverage
   - Authentication security
   - Input validation

2. **Missing Service Tests** (6 files)
   - HTTP, Loading, Theme, Clipboard, Network, WinBox

3. **Handler Tests** (4 files)
   - All API endpoints

### P1 - High (Week 3-4)

1. **Integration Tests** (4 files)
   - API, Database, Security, Service communication

2. **E2E Tests** (5 files)
   - App loading, Auth flow, CRUD, Window management, Error handling

3. **Component Tests** (4 files)
   - App, Home, Error boundary, Loading

### P2 - Medium (Week 5-6)

1. **Performance Tests** (4 files)
   - Service benchmarks, API performance, Component benchmarks, Bundle analysis

2. **E2E Tests** (3 files)
   - Responsive, Performance, Accessibility

3. **Edge Case Tests** (3 files)
   - Empty inputs, Maximum values, Concurrent access

---

## Test Quality Metrics

### Coverage Targets

| Component | Unit | Integration | E2E | Total |
|-----------|------|-------------|-----|-------|
| Services | 90% | 85% | - | 88% |
| Components | 85% | 80% | 70% | 82% |
| Handlers | 95% | 90% | - | 93% |
| Utils | 90% | 85% | - | 88% |
| **Overall** | **90%** | **85%** | **70%** | **85%** |

### Quality Gates

| Metric | Threshold | Status |
|--------|-----------|--------|
| Unit Test Coverage | >90% | [WARNING] Current: 60% |
| Integration Coverage | >85% | [WARNING] Current: 40% |
| E2E Coverage | >70% critical paths | [TODO] Current: 0% |
| Test Execution Time | <5 min | ⏹️ TBD |
| Flaky Tests | 0 | ⏹️ TBD |
| Security Tests | Pass all | ⏹️ TBD |

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup V
        uses: vlang/setup-v@v2
      
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
      
      - name: Setup Playwright
        uses: microsoft/playwright-github-action@v1
      
      - name: Install dependencies
        run: |
          cd frontend
          bun install
      
      - name: Backend Unit Tests
        run: v test src/
      
      - name: Frontend Unit Tests
        run: |
          cd frontend
          bun test
      
      - name: Integration Tests
        run: |
          cd frontend
          bun test src/integration/
      
      - name: E2E Tests
        run: |
          cd frontend
          bunx playwright test
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella
```

---

## Test Data Management

### Test Fixtures

```typescript
// frontend/src/fixtures/users.fixture.ts
export const testUsers = {
  valid: {
    name: 'Test User',
    email: 'test@example.com',
    age: 25
  },
  invalid: {
    emptyName: { name: '', email: 'test@example.com', age: 25 },
    invalidEmail: { name: 'Test', email: 'invalid', age: 25 }
  }
};
```

### Mock Data

```v
// src/test_utils.v
pub fn create_test_user() User {
    return User{
        id: 1
        name: 'Test User'
        email: 'test@example.com'
        age: 25
        created_at: time.now().str()
    }
}
```

---

## Test Documentation

### Test Naming Convention

```
test_[module]_[function]_[scenario]()
test_cache_set_get_success()
test_auth_login_invalid_credentials()
test_api_get_users_success()
```

### Test Documentation Template

```v
// test_cache_service.v

// Test: Cache set and get operations
// Given: A new cache service
// When: Setting and getting a value
// Then: Value should be retrieved correctly
fn test_cache_set_get() {
    // ...
}
```

---

## Maintenance

### Test Review Checklist

- [ ] Tests are independent
- [ ] Tests are repeatable
- [ ] Tests are fast (<100ms per test)
- [ ] Tests have clear assertions
- [ ] Tests cover edge cases
- [ ] Tests are documented

### Test Debt Management

| Issue | Priority | Action |
|-------|----------|--------|
| Flaky tests | P0 | Fix or remove |
| Slow tests | P1 | Optimize |
| Missing coverage | P1 | Add tests |
| Duplicate tests | P2 | Consolidate |

---

## Success Criteria

### Phase 1 (Week 2)
- [ ] All security tests passing
- [ ] All service tests implemented
- [ ] Coverage >75%

### Phase 2 (Week 4)
- [ ] All integration tests passing
- [ ] E2E critical paths covered
- [ ] Coverage >85%

### Phase 3 (Week 6)
- [ ] All performance tests passing
- [ ] All E2E tests passing
- [ ] Coverage >90%
- [ ] CI/CD pipeline green

---

*Last Updated: 2026-03-14*
*Next Review: 2026-03-21*
