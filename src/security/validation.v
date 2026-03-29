module security

import time

// ============================================================================
// Input Sanitization
// ============================================================================

// sanitize_input removes potentially dangerous characters from input
pub fn sanitize_input(input string) !string {
	if input.len == 0 {
		return error('Empty input')
	}

	// Remove null bytes
	mut result := input.replace('\x00', '')

	// Remove script tags
	result = result.replace('<script>', '').replace('</script>', '')

	// Remove event handlers
	result = result.replace('onclick=', '').replace('onerror=', '').replace('onload=', '')

	// Remove javascript: protocol
	result = result.replace('javascript:', '')

	// Limit length
	if result.len > 10000 {
		result = result[..10000]
	}

	return result
}

// sanitize_html removes HTML tags from input
pub fn sanitize_html(input string) string {
	mut in_tag := false
	mut output := ''

	for i := 0; i < input.len; i++ {
		c := input[i]
		if c == `<`[0] {
			in_tag = true
		} else if c == `>`[0] {
			in_tag = false
		} else if !in_tag {
			output += c.str()
		}
	}

	return output
}

// sanitize_sql_identifier validates SQL identifier (table/column names)
pub fn sanitize_sql_identifier(identifier string) !string {
	if identifier.len == 0 {
		return error('Empty identifier')
	}

	// Check first character
	first := identifier[0]
	if !first.is_letter() && first != `_`[0] {
		return error('Identifier must start with letter or underscore')
	}

	// Check all characters
	for i := 0; i < identifier.len; i++ {
		c := identifier[i]
		if !c.is_letter() && !c.is_digit() && c != `_`[0] {
			return error('Invalid character in identifier: ${c.str()}')
		}
	}

	// Limit length
	if identifier.len > 64 {
		return error('Identifier too long (max 64 characters)')
	}

	return identifier
}

// sanitize_filename validates and sanitizes a filename
pub fn sanitize_filename(name string) !string {
	if name.len == 0 {
		return error('Empty filename')
	}

	// Check for path traversal
	if name.contains('../') || name.contains('..\\') {
		return error('Invalid filename: path traversal detected')
	}

	// Check for null bytes
	if name.contains('\x00') {
		return error('Invalid filename: null byte detected')
	}
    
	for i := 0; i < name.len; i++ {
		c := name[i]
		if !c.is_letter() && !c.is_digit() && c != `_`[0] && c != `-`[0] && c != `.`[0] {
			return error('Invalid character: ${c.str()}')
		}
	}

	// Limit length
	if name.len > 255 {
		return error('Filename too long (max 255 characters)')
	}

	return name
}

// sanitize_phone removes non-numeric characters from phone number
pub fn sanitize_phone(phone string) string {
	mut result := ''
	for i := 0; i < phone.len; i++ {
		c := phone[i]
		if c.is_digit() || c == ` `[0] || c == `-`[0] || c == `(`[0] || c == `)`[0] || c == `+`[0] {
			result += c.str()
		}
	}
	return result
}

// is_valid_phone checks if phone number is valid
pub fn is_valid_phone(phone string) bool {
	if phone.len < 7 || phone.len > 20 {
		return false
	}
	// Allow digits, spaces, dashes, parentheses, and plus
	for i := 0; i < phone.len; i++ {
		c := phone[i]
		if !c.is_digit() && c != ` `[0] && c != `-`[0] && c != `(`[0] && c != `)`[0] && c != `+`[0] {
			return false
		}
	}
	return true
}

// sanitize_username validates username
pub fn sanitize_username(username string) !string {
	if username.len < 3 || username.len > 32 {
		return error('Username must be 3-32 characters')
	}

	for i := 0; i < username.len; i++ {
		c := username[i]
		if !c.is_letter() && !c.is_digit() && c != `_`[0] && c != `.`[0] {
			return error('Invalid character: ${c.str()}')
		}
	}

	return username
}

// is_valid_username checks if username is valid
pub fn is_valid_username(username string) bool {
	if username.len < 3 || username.len > 32 {
		return false
	}
	for i := 0; i < username.len; i++ {
		c := username[i]
		if !c.is_letter() && !c.is_digit() && c != `_`[0] && c != `.`[0] {
			return false
		}
	}
	return true
}

// ============================================================================
// Rate Limiter (Simple Implementation)
// ============================================================================

// RateLimiter implements a simple rate limiter
pub struct RateLimiter {
pub mut:
	window_seconds int
	max_requests   int
	requests       map[string][]u64
}

// new_rate_limiter creates a new rate limiter
pub fn new_rate_limiter(max_requests int, window_seconds int) &RateLimiter {
	return &RateLimiter{
		window_seconds: window_seconds
		max_requests: max_requests
		requests: map[string][]u64{}
	}
}

// check checks if request is allowed
pub fn (mut rl RateLimiter) check(key string) bool {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)

	// Get existing requests
	mut requests := rl.requests[key] or { []u64{} }

	// Filter to only requests within window
	mut valid_requests := []u64{}
	for t in requests {
		if t >= window_start {
			valid_requests << t
		}
	}

	// Check if under limit
	if valid_requests.len >= rl.max_requests {
		rl.requests[key] = valid_requests
		return false
	}

	// Add current request
	valid_requests << now
	rl.requests[key] = valid_requests

	return true
}

// get_remaining returns remaining requests in current window
pub fn (mut rl RateLimiter) get_remaining(key string) int {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)

	requests := rl.requests[key] or { return rl.max_requests }

	mut valid_count := 0
	for t in requests {
		if t >= window_start {
			valid_count++
		}
	}

	return rl.max_requests - valid_count
}

// cleanup removes old entries
pub fn (mut rl RateLimiter) cleanup() int {
	now := u64(time.now().unix())
	window_start := now - u64(rl.window_seconds)

	mut removed := 0
	mut keys_to_clean := []string{}

	for key, requests in rl.requests {
		mut valid_requests := []u64{}
		for t in requests {
			if t >= window_start {
				valid_requests << t
			}
		}

		if valid_requests.len == 0 {
			keys_to_clean << key
			removed++
		} else {
			rl.requests[key] = valid_requests
		}
	}

	for key in keys_to_clean {
		rl.requests.delete(key)
	}

	return removed
}
