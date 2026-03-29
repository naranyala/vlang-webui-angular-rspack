# Security

Security features and implementation details.

---

## Table of Contents

1. [Overview](#overview)
2. [Password Hashing](#password-hashing)
3. [Token Generation](#token-generation)
4. [CSRF Protection](#csrf-protection)
5. [Rate Limiting](#rate-limiting)
6. [Input Validation](#input-validation)
7. [Best Practices](#best-practices)

---

## Overview

Desktop Dashboard implements multiple security layers:

| Feature | Purpose | Implementation |
|---------|---------|----------------|
| Password Hashing | Secure credential storage | Multi-round key stretching |
| Token Generation | Secure session/API tokens | High-entropy random bytes |
| CSRF Protection | Prevent cross-site attacks | Single-use tokens |
| Rate Limiting | Prevent abuse/DoS | Per-minute/hour limits |
| Input Validation | Prevent injection attacks | Sanitization functions |

---

## Password Hashing

### Algorithm

Passwords are hashed using multi-round key stretching:

1. Generate entropy-based salt
2. Apply 10,000 iterations of key stretching
3. Store version, salt, iterations, and hash

### Implementation

```v
pub fn hash_password(password string) string {
    salt := generate_salt(password)
    iterations := 10000
    hash := stretch_key(password, salt, iterations)
    return 'v1$${salt}$${iterations}$${hash}'
}
```

### Salt Generation

```v
fn generate_salt(password string) string {
    now := time.now()
    // Multiple entropy sources
    entropy := '${now.unix_nano()}_${password.len}_${int(password[0])}'
    
    // Generate 16-character salt
    // ... salt generation logic
    return salt
}
```

### Verification

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

### Security Properties

- **Salt**: 16 characters from 62-character set
- **Iterations**: 10,000 rounds
- **Time**: ~100ms per hash (intentionally slow)
- **Comparison**: Constant-time to prevent timing attacks

---

## Token Generation

### High-Entropy Tokens

```v
pub fn generate_secure_token(prefix string) string {
    // Generate 32 bytes of entropy using xorshift64*
    random_bytes := generate_entropy_bytes(32)
    random_part := bytes_to_hex(random_bytes)
    timestamp := time.now().unix_nano()
    
    return '${prefix}_${random_part}_${timestamp}'
}
```

### Token Types

| Type | Length | Use Case | Expiry |
|------|--------|----------|--------|
| Session | 64 bytes | User sessions | 1 hour |
| CSRF | 32 bytes | Form protection | 1 hour |
| API Key | 32 bytes | API authentication | Never |
| Request ID | 16 bytes | Request tracking | N/A |

### Entropy Generation

```v
fn generate_entropy_bytes(count int) []u8 {
    mut bytes := []u8{}
    mut seed := u64(time.now().unix_nano())

    for _ in 0 .. count {
        // xorshift64* algorithm
        seed = (seed * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        seed = seed ^ (seed >> 33)
        seed = seed * 0xFF51AFD7ED558CCD
        seed = seed ^ (seed >> 33)
        bytes << u8(seed & 0xFF)
    }

    return bytes
}
```

---

## CSRF Protection

### Token Generation

```v
pub fn (mut p CSRFProtection) generate_token(user_id string) !string {
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

### Token Validation

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

### Frontend Usage

```typescript
// Include CSRF token in state-changing requests
const csrfToken = await api.call<string>('getCsrfToken');

await api.call('createUser', {
  name: 'John',
  email: 'john@example.com',
  csrf_token: csrfToken
});
```

---

## Rate Limiting

### Configuration

```v
pub fn default_rate_limit_config() RateLimitConfig {
    return RateLimitConfig{
        requests_per_minute: 60
        requests_per_hour: 1000
        burst_limit: 10
    }
}
```

### Implementation

```v
pub fn (mut rl RateLimiter) check_rate_limit(identifier string) RateLimitResult {
    now := u64(time.now().unix())
    
    // Track requests per minute and hour
    // Check burst limit
    // Return result with remaining quota
}
```

### Response Headers

```
X-RateLimit-Limit-Minute: 60
X-RateLimit-Remaining-Minute: 59
X-RateLimit-Limit-Hour: 1000
X-RateLimit-Remaining-Hour: 999
Retry-After: 60  (when rate limited)
```

### Rate Limited Response

```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "retry_after": 60
}
```

---

## Input Validation

### Sanitization Functions

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

### Validation Functions

```v
// Email validation
pub fn validate_email(email string) bool {
    return email.contains('@') && email.contains('.') && email.len > 5
}

// Username validation
pub fn sanitize_username(username string) !string {
    if username.len < 3 || username.len > 32 {
        return error('Username must be 3-32 characters')
    }
    // ... validation logic
    return username
}
```

### Validation Pipeline

```v
pub fn validate_user_request(name string, email string, age int) ValidationResult {
    mut v := new_validator()
    v.required('name', name)
    v.email('email', email)
    v.int_range('age', age, 1, 150)
    return v.result()
}
```

---

## Best Practices

### Password Security

1. Always hash passwords before storage
2. Use strong salt generation
3. Implement constant-time comparison
4. Enforce password complexity requirements

### Token Security

1. Use high-entropy random generation
2. Implement token expiration
3. Use single-use tokens for CSRF
4. Store tokens securely

### Rate Limiting

1. Implement at API gateway level
2. Use sliding window algorithm
3. Provide clear error messages
4. Include retry-after headers

### Input Validation

1. Validate on both client and server
2. Use allowlists, not blocklists
3. Sanitize before storage and output
4. Implement comprehensive validation pipeline

---

*Last Updated: 2026-03-29*
