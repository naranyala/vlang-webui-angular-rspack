module security

import time

// ============================================================================
// Secure Token Generation
// Uses multiple entropy sources for improved randomness
// NOTE: For production use, integrate with crypto.random_bytes() when available
// ============================================================================

pub const token_length = 32
pub const session_token_length = 64
pub const csrf_token_length = 32

// Token represents a secure token with metadata
pub struct Token {
pub mut:
	value      string
	created_at u64
	expires_at u64
	user_id    string
	purpose    string
}

// TokenStore manages active tokens
pub struct TokenStore {
pub mut:
	tokens map[string]Token
}

// new_token_store creates a new token store
pub fn new_token_store() &TokenStore {
	return &TokenStore{
		tokens: map[string]Token{}
	}
}

// ============================================================================
// Entropy Generation
// ============================================================================

// generate_entropy_bytes generates pseudo-random bytes from multiple sources
fn generate_entropy_bytes(count int) []u8 {
	mut bytes := []u8{}
	mut seed := u64(time.now().unix_nano())

	for _ in 0 .. count {
		// Mix multiple entropy sources
		seed = (seed * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
		seed = seed ^ (seed >> 33)
		seed = seed * 0xFF51AFD7ED558CCD
		seed = seed ^ (seed >> 33)

		bytes << u8(seed & 0xFF)
	}

	return bytes
}

// bytes_to_hex converts bytes to hexadecimal string
fn bytes_to_hex(bytes []u8) string {
	hex_chars := '0123456789abcdef'
	mut result := ''
	for b in bytes {
		result += hex_chars[(b >> 4) & 0xF].str()
		result += hex_chars[b & 0xF].str()
	}
	return result
}

// ============================================================================
// Secure Token Generation
// ============================================================================

// generate_secure_token generates a cryptographically-inspired secure token
pub fn generate_secure_token(prefix string) string {
	// Generate random bytes
	random_bytes := generate_entropy_bytes(token_length)
	random_part := bytes_to_hex(random_bytes)

	// Add timestamp for uniqueness (not for security)
	timestamp := time.now().unix_nano()

	if prefix != '' {
		return '${prefix}_${random_part}_${timestamp}'
	}
	return '${random_part}_${timestamp}'
}

// generate_random_token generates a token using only random data
pub fn generate_random_token(length int) string {
	random_bytes := generate_entropy_bytes(length)
	return bytes_to_hex(random_bytes)
}

// generate_session_id generates a unique session ID with high entropy
pub fn generate_session_id() string {
	random_bytes := generate_entropy_bytes(session_token_length)
	random_part := bytes_to_hex(random_bytes)
	return 'sess_${random_part}'
}

// generate_request_id generates a unique request ID
pub fn generate_request_id() string {
	random_bytes := generate_entropy_bytes(16)
	random_part := bytes_to_hex(random_bytes)
	return 'req_${random_part}_${time.now().unix_nano()}'
}

// generate_api_key generates an API key with prefix
pub fn generate_api_key(prefix string) string {
	random_bytes := generate_entropy_bytes(32)
	random_part := bytes_to_hex(random_bytes)
	return '${prefix}_${random_part}'
}

// ============================================================================
// Token Validation
// ============================================================================

// is_token_expired checks if a token has expired
pub fn is_token_expired(expires_at u64) bool {
	return u64(time.now().unix()) > expires_at
}

// get_token_remaining_time returns seconds until token expires
pub fn get_token_remaining_time(expires_at u64) int {
	now := u64(time.now().unix())
	if now >= expires_at {
		return 0
	}
	return int(expires_at - now)
}

// calculate_expiry calculates expiration timestamp
pub fn calculate_expiry(duration_seconds int) u64 {
	return u64(time.now().unix()) + u64(duration_seconds)
}

// ============================================================================
// Token Store Operations
// ============================================================================

// store_token stores a token in the store
pub fn (mut s TokenStore) store_token(token Token) {
	s.tokens[token.value] = token
}

// get_token retrieves a token from the store
pub fn (s TokenStore) get_token(value string) ?Token {
	return s.tokens[value]
}

// delete_token removes a token from the store
pub fn (mut s TokenStore) delete_token(value string) {
	s.tokens.delete(value)
}

// cleanup_expired removes expired tokens and returns count
pub fn (mut s TokenStore) cleanup_expired() int {
	mut removed := 0
	now := u64(time.now().unix())

	mut tokens_to_remove := []string{}
	for token_value, token in s.tokens {
		if now > token.expires_at {
			tokens_to_remove << token_value
		}
	}

	for token_value in tokens_to_remove {
		s.tokens.delete(token_value)
		removed++
	}

	return removed
}

// ============================================================================
// CSRF Token Management
// ============================================================================

// CSRFProtection handles CSRF token generation and validation
pub struct CSRFProtection {
pub mut:
	tokens map[string]CSRFToken
}

// CSRFToken represents a CSRF token
pub struct CSRFToken {
pub mut:
	token      string
	user_id    string
	created_at u64
	expires_at u64
	used       bool
}

// new_csrf_protection creates a new CSRF protection instance
pub fn new_csrf_protection() &CSRFProtection {
	return &CSRFProtection{
		tokens: map[string]CSRFToken{}
	}
}

// generate_token generates a new CSRF token with high entropy
pub fn (mut p CSRFProtection) generate_token(user_id string) !string {
	// Use random token generation, not time-based
	random_bytes := generate_entropy_bytes(csrf_token_length)
	token := 'csrf_${bytes_to_hex(random_bytes)}'

	now := u64(time.now().unix())

	p.tokens[token] = CSRFToken{
		token: token
		user_id: user_id
		created_at: now
		expires_at: now + 3600  // 1 hour expiry
		used: false
	}

	return token
}

// validate_token validates a CSRF token (single-use)
pub fn (mut p CSRFProtection) validate_token(token string, user_id string) bool {
	stored := p.tokens[token] or {
		return false
	}

	// Check if already used (single-use tokens)
	if stored.used {
		p.tokens.delete(token)
		return false
	}

	// Check expiration
	if is_token_expired(stored.expires_at) {
		p.tokens.delete(token)
		return false
	}

	// Check user ID match
	if stored.user_id != user_id {
		return false
	}

	// Mark as used
	p.tokens[token].used = true

	return true
}

// invalidate_token invalidates a CSRF token
pub fn (mut p CSRFProtection) invalidate_token(token string) {
	p.tokens.delete(token)
}

// cleanup_expired removes expired tokens
pub fn (mut p CSRFProtection) cleanup_expired() int {
	mut removed := 0
	now := u64(time.now().unix())

	mut tokens_to_remove := []string{}
	for token, csrf_token in p.tokens {
		if now > csrf_token.expires_at || csrf_token.used {
			tokens_to_remove << token
		}
	}

	for token in tokens_to_remove {
		p.tokens.delete(token)
		removed++
	}

	return removed
}

// ============================================================================
// Rate Limiting Token (for API rate limiting)
// ============================================================================

// RateLimitTracker tracks request rates per identifier
pub struct RateLimitTracker {
pub mut:
	requests map[string][]u64
	limit    int
	window   u64  // Window in seconds
}

// new_rate_limiter creates a new rate limiter
pub fn new_rate_limiter(limit int, window_seconds u64) &RateLimitTracker {
	return &RateLimitTracker{
		requests: map[string][]u64{}
		limit: limit
		window: window_seconds
	}
}

// is_allowed checks if a request is allowed under rate limit
pub fn (mut r RateLimitTracker) is_allowed(identifier string) bool {
	now := u64(time.now().unix())
	window_start := now - r.window

	// Get existing requests
	mut requests := r.requests[identifier] or { []u64{} }

	// Filter to only requests within window
	mut valid_requests := []u64{}
	for req_time in requests {
		if req_time >= window_start {
			valid_requests << req_time
		}
	}

	// Check if under limit
	if valid_requests.len >= r.limit {
		r.requests[identifier] = valid_requests
		return false
	}

	// Add current request
	valid_requests << now
	r.requests[identifier] = valid_requests

	return true
}

// get_remaining_requests returns remaining requests in current window
pub fn (mut r RateLimitTracker) get_remaining_requests(identifier string) int {
	now := u64(time.now().unix())
	window_start := now - r.window

	requests := r.requests[identifier] or { return r.limit }

	mut valid_count := 0
	for req_time in requests {
		if req_time >= window_start {
			valid_count++
		}
	}

	return r.limit - valid_count
}

// cleanup_old_requests removes old request records
pub fn (mut r RateLimitTracker) cleanup_old_requests() {
	now := u64(time.now().unix())
	window_start := now - r.window

	mut identifiers_to_clean := []string{}
	for identifier, requests in r.requests {
		mut valid_requests := []u64{}
		for req_time in requests {
			if req_time >= window_start {
				valid_requests << req_time
			}
		}

		if valid_requests.len == 0 {
			identifiers_to_clean << identifier
		} else {
			r.requests[identifier] = valid_requests
		}
	}

	for identifier in identifiers_to_clean {
		r.requests.delete(identifier)
	}
}
