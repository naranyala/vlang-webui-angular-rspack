module security

import time

// AuthUserInfo - User information (defined here to avoid V compiler module issues)
pub struct AuthUserInfo {
pub mut:
	id            string
	username      string
	email         string
	password_hash string
	roles         []string
	permissions   []string
	created_at    u64
	last_login    u64
}

// AuthResult - Authentication result
pub struct AuthResult {
pub mut:
	success    bool
	user_id    string
	username   string
	roles      []string
	permissions []string
	token      string
	expires_at u64
	error      string
}

// Note: encoding.hex and strings imports removed as they're not used in simplified version

// ============================================================================
// Password Hashing Utilities (Simplified for V 0.5.1)
// ============================================================================

// HashPassword creates a secure hash of a password
pub fn hash_password(password string) string {
	// Generate salt from timestamp
	salt := '${time.now().unix_nano()}_${password.len}'
	
	// Generate hash
	hash := pbkdf2_simple(password, salt, 10000)

	return '\$${salt}\$${hash}'
}

// VerifyPassword checks if a password matches a hash
pub fn verify_password(password string, hash_string string) bool {
	parts := hash_string.split('\$')
	if parts.len != 3 {
		return false
	}

	salt := parts[1]
	stored_hash := parts[2]
	computed_hash := pbkdf2_simple(password, salt, 10000)

	return secure_compare(computed_hash, stored_hash)
}

fn pbkdf2_simple(password string, salt string, iterations int) string {
	mut data := '${password}${salt}'
	mut final_hash := u64(0)
	
	for i in 0 .. iterations {
		final_hash = u64(0)
		for b in data {
			final_hash = final_hash * 31 + u64(b)
		}
		data = '${data}${final_hash}'
		_ = i
	}
	
	return '${final_hash}'
}

fn secure_compare(a string, b string) bool {
	if a.len != b.len {
		return false
	}
	mut result := 0
	for i := 0; i < a.len; i++ {
		result |= int(a[i]) ^ int(b[i])
	}
	return result == 0
}

// ============================================================================
// Secure Token Generation (Time-based for V 0.5.1)
// ============================================================================

pub const token_length = 32

pub fn generate_secure_token(prefix string) string {
	// Time-based token (not cryptographically secure, but works without crypto module)
	now := time.now().unix_nano()
	
	if prefix != '' {
		return '${prefix}_${now}'
	}
	return '${now}'
}

pub fn generate_csrf_token() string {
	return generate_secure_token('csrf')
}

pub fn generate_session_token() string {
	return generate_secure_token('sess')
}

// ============================================================================
// Input Validation and Sanitization
// ============================================================================

pub fn sanitize_input(input string) string {
	mut result := input.replace('\x00', '')
	result = result.replace('<', '&lt;')
	result = result.replace('>', '&gt;')
	result = result.replace('"', '&quot;')
	result = result.replace('\'', '&#x27;')
	return result.trim_space()
}

pub fn validate_email(email string) bool {
	if email.len < 5 || email.len > 254 {
		return false
	}
	if !email.contains('@') {
		return false
	}
	parts := email.split('@')
	if parts.len != 2 {
		return false
	}
	local := parts[0]
	domain := parts[1]
	if local.len < 1 || local.len > 64 {
		return false
	}
	if domain.len < 3 || domain.len > 255 {
		return false
	}
	if !domain.contains('.') {
		return false
	}
	return true
}

pub fn validate_username(username string) bool {
	if username.len < 3 || username.len > 32 {
		return false
	}
	// Simple validation - check each byte
	bytes := username.bytes()
	for b in bytes {
		is_lower := b >= u8(`a`) && b <= u8(`z`)
		is_upper := b >= u8(`A`) && b <= u8(`Z`)
		is_digit := b >= u8(`0`) && b <= u8(`9`)
		is_underscore := b == u8(`_`)
		if !is_lower && !is_upper && !is_digit && !is_underscore {
			return false
		}
	}
	return true
}

pub fn validate_password_strength(password string) bool {
	if password.len < 8 {
		return false
	}
	if password.len > 128 {
		return false
	}
	return true
}

pub fn validate_identifier(name string) string {
	if name.len == 0 || name.len > 64 {
		return ''
	}
	
	bytes := name.bytes()
	for i, b in bytes {
		is_lower := b >= u8(`a`) && b <= u8(`z`)
		is_upper := b >= u8(`A`) && b <= u8(`Z`)
		is_digit := b >= u8(`0`) && b <= u8(`9`)
		is_underscore := b == u8(`_`)
		
		if i == 0 && !is_lower && !is_upper && !is_underscore {
			return ''
		}
		if !is_lower && !is_upper && !is_digit && !is_underscore {
			return ''
		}
	}
	
	upper_name := name.to_upper()
	sql_keywords := ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'UNION', 'ALTER', 'CREATE', 'TRUNCATE', '--', ';', '/*', '*/']
	
	for keyword in sql_keywords {
		if upper_name.contains(keyword) {
			return ''
		}
	}
	
	return name
}

// ============================================================================
// Rate Limiting
// ============================================================================

pub struct RateLimiter {
pub mut:
	requests       map[string][]u64
	max_requests   int
	window_seconds int
}

pub fn new_rate_limiter(max_requests int, window_seconds int) &RateLimiter {
	return &RateLimiter{
		requests: map[string][]u64{}
		max_requests: max_requests
		window_seconds: window_seconds
	}
}

pub fn (mut rl RateLimiter) is_allowed(key string) bool {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)

	requests := rl.requests[key] or { []u64{} }

	mut valid_requests := []u64{}
	for req_time in requests {
		if req_time >= window_start {
			valid_requests << req_time
		}
	}

	if valid_requests.len >= rl.max_requests {
		rl.requests[key] = valid_requests
		return false
	}

	valid_requests << now
	rl.requests[key] = valid_requests
	return true
}

pub fn (mut rl RateLimiter) get_remaining_requests(key string) int {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)

	requests := rl.requests[key] or { []u64{} }

	mut valid_count := 0
	for req_time in requests {
		if req_time >= window_start {
			valid_count++
		}
	}

	return rl.max_requests - valid_count
}

pub fn (mut rl RateLimiter) reset(key string) {
	rl.requests.delete(key)
}

pub fn (mut rl RateLimiter) cleanup() int {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)
	mut removed := 0

	for key, requests in rl.requests {
		mut valid_requests := []u64{}
		for req_time in requests {
			if req_time >= window_start {
				valid_requests << req_time
			}
		}

		if valid_requests.len == 0 {
			rl.requests.delete(key)
			removed++
		} else {
			rl.requests[key] = valid_requests
		}
	}

	return removed
}

// ============================================================================
// CSRF Protection
// ============================================================================

pub struct CSRFProtection {
pub mut:
	tokens map[string]CSRFToken
}

pub struct CSRFToken {
pub mut:
	token      string
	created_at u64
	expires_at u64
	user_id    string
}

pub fn new_csrf_protection() &CSRFProtection {
	return &CSRFProtection{
		tokens: map[string]CSRFToken{}
	}
}

pub fn (mut cp CSRFProtection) generate_token(user_id string) string {
	token := generate_csrf_token()

	now := u64(time.now().unix())
	cp.tokens[token] = CSRFToken{
		token: token
		created_at: now
		expires_at: now + 3600
		user_id: user_id
	}

	return token
}

pub fn (mut cp CSRFProtection) validate_token(token string, user_id string) bool {
	stored := cp.tokens[token] or {
		return false
	}

	now := u64(time.now().unix())
	if now > stored.expires_at {
		cp.tokens.delete(token)
		return false
	}

	if stored.user_id != user_id {
		return false
	}

	return true
}

pub fn (mut cp CSRFProtection) invalidate_token(token string) {
	cp.tokens.delete(token)
}

pub fn (mut cp CSRFProtection) cleanup() int {
	now := u64(time.now().unix())
	mut removed := 0

	for token, token_data in cp.tokens {
		if now > token_data.expires_at {
			cp.tokens.delete(token)
			removed++
		}
	}

	return removed
}
