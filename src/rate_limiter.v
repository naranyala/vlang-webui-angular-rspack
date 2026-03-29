module main

import time

// ============================================================================
// Rate Limiting Middleware
// Protects API endpoints from abuse and DoS attacks
// ============================================================================

// RateLimitConfig defines rate limiting configuration
pub struct RateLimitConfig {
pub mut:
	requests_per_minute int
	requests_per_hour   int
	burst_limit         int
}

// default_rate_limit_config returns default rate limit settings
pub fn default_rate_limit_config() RateLimitConfig {
	return RateLimitConfig{
		requests_per_minute: 60
		requests_per_hour: 1000
		burst_limit: 10
	}
}

// RateLimiter manages rate limiting for API endpoints
pub struct RateLimiter {
pub mut:
	config           RateLimitConfig
	minute_requests  map[string][]u64
	hour_requests    map[string][]u64
	burst_tracker    map[string]int
	burst_reset      map[string]u64
}

// RateLimitResult holds rate limit check result
pub struct RateLimitResult {
pub mut:
	allowed       bool
	remaining_min int
	remaining_hr  int
	retry_after   int
}

// new_rate_limiter creates a new rate limiter
pub fn new_rate_limiter() &RateLimiter {
	return &RateLimiter{
		config: default_rate_limit_config()
		minute_requests: map[string][]u64{}
		hour_requests: map[string][]u64{}
		burst_tracker: map[string]int{}
		burst_reset: map[string]u64{}
	}
}

// new_rate_limiter_with_config creates a rate limiter with custom config
pub fn new_rate_limiter_with_config(config RateLimitConfig) &RateLimiter {
	return &RateLimiter{
		config: config
		minute_requests: map[string][]u64{}
		hour_requests: map[string][]u64{}
		burst_tracker: map[string]int{}
		burst_reset: map[string]u64{}
	}
}

// check_rate_limit checks if a request is allowed
pub fn (mut rl RateLimiter) check_rate_limit(identifier string) RateLimitResult {
	now := u64(time.now().unix())
	minute_ago := now - 60
	hour_ago := now - 3600

	// Clean and count minute requests
	mut minute_reqs := rl.minute_requests[identifier] or { []u64{} }
	mut valid_minute := []u64{}
	for t in minute_reqs {
		if t >= minute_ago {
			valid_minute << t
		}
	}
	rl.minute_requests[identifier] = valid_minute

	// Clean and count hour requests
	mut hour_reqs := rl.hour_requests[identifier] or { []u64{} }
	mut valid_hour := []u64{}
	for t in hour_reqs {
		if t >= hour_ago {
			valid_hour << t
		}
	}
	rl.hour_requests[identifier] = valid_hour

	// Check burst limit
	burst_reset_time := rl.burst_reset[identifier] or { u64(0) }
	if now >= burst_reset_time {
		rl.burst_tracker[identifier] = 0
		rl.burst_reset[identifier] = now + 1  // Reset every second
	}

	// Check all limits
	mut result := RateLimitResult{
		allowed: true
		remaining_min: rl.config.requests_per_minute - valid_minute.len
		remaining_hr: rl.config.requests_per_hour - valid_hour.len
		retry_after: 0
	}

	// Check burst limit first (most restrictive)
	if rl.burst_tracker[identifier] >= rl.config.burst_limit {
		result.allowed = false
		result.retry_after = 1
		return result
	}

	// Check minute limit
	if valid_minute.len >= rl.config.requests_per_minute {
		result.allowed = false
		if valid_minute.len > 0 {
			result.retry_after = int(60 - (now - valid_minute[0]))
			if result.retry_after < 1 {
				result.retry_after = 1
			}
		}
		return result
	}

	// Check hour limit
	if valid_hour.len >= rl.config.requests_per_hour {
		result.allowed = false
		if valid_hour.len > 0 {
			result.retry_after = int(3600 - (now - valid_hour[0]))
			if result.retry_after < 1 {
				result.retry_after = 1
			}
		}
		return result
	}

	// Record this request
	valid_minute << now
	valid_hour << now
	rl.minute_requests[identifier] = valid_minute
	rl.hour_requests[identifier] = valid_hour
	rl.burst_tracker[identifier]++

	return result
}

// is_allowed checks if request is allowed (simple boolean)
pub fn (mut rl RateLimiter) is_allowed(identifier string) bool {
	result := rl.check_rate_limit(identifier)
	return result.allowed
}

// get_rate_limit_headers returns rate limit headers for response
pub fn (mut rl RateLimiter) get_rate_limit_headers(identifier string) map[string]string {
	result := rl.check_rate_limit(identifier)
	mut headers := map[string]string{}

	headers['X-RateLimit-Limit-Minute'] = rl.config.requests_per_minute.str()
	headers['X-RateLimit-Remaining-Minute'] = result.remaining_min.str()
	headers['X-RateLimit-Limit-Hour'] = rl.config.requests_per_hour.str()
	headers['X-RateLimit-Remaining-Hour'] = result.remaining_hr.str()

	if !result.allowed {
		headers['Retry-After'] = result.retry_after.str()
	}

	return headers
}

// cleanup_old_entries removes old rate limit entries
pub fn (mut rl RateLimiter) cleanup_old_entries() {
	now := u64(time.now().unix())
	minute_ago := now - 60
	hour_ago := now - 3600

	// Clean minute requests
	mut identifiers_to_clean := []string{}
	for identifier, requests in rl.minute_requests {
		mut valid := []u64{}
		for t in requests {
			if t >= minute_ago {
				valid << t
			}
		}
		if valid.len == 0 {
			identifiers_to_clean << identifier
		} else {
			rl.minute_requests[identifier] = valid
		}
	}

	// Clean hour requests
	for identifier, requests in rl.hour_requests {
		mut valid := []u64{}
		for t in requests {
			if t >= hour_ago {
				valid << t
			}
		}
		if valid.len == 0 {
			identifiers_to_clean << identifier
		} else {
			rl.hour_requests[identifier] = valid
		}
	}

	// Remove empty identifiers
	for identifier in identifiers_to_clean {
		rl.minute_requests.delete(identifier)
		rl.hour_requests.delete(identifier)
		rl.burst_tracker.delete(identifier)
		rl.burst_reset.delete(identifier)
	}
}

// get_stats returns rate limiter statistics
pub fn (rl RateLimiter) get_stats() map[string]int {
	mut stats := map[string]int{}
	stats['tracked_identifiers'] = rl.minute_requests.len
	stats['minute_buckets'] = rl.minute_requests.len
	stats['hour_buckets'] = rl.hour_requests.len
	return stats
}

// ============================================================================
// API Request Validation
// Validates incoming API requests
// ============================================================================

// RequestValidationResult holds validation outcome
pub struct RequestValidationResult {
pub mut:
	is_valid bool
	errors   []string
}

// error_response creates error JSON response
pub fn validation_error_response(msg string) string {
	return '{"success":false,"error":"${msg}"}'
}

// rate_limit_response creates rate limit error response
pub fn rate_limit_response(retry_after int) string {
	return '{"success":false,"error":"Rate limit exceeded","retry_after":${retry_after}}'
}
