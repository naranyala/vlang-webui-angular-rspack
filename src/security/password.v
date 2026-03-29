module security

import time
import math

// ============================================================================
// Password Hashing Utilities
// NOTE: For production use, integrate with a proper crypto library like bcrypt
// This implementation provides improved hashing over the previous version
// ============================================================================

// PasswordHash represents a hashed password with salt and metadata
pub struct PasswordHash {
pub mut:
	hash       string
	salt       string
	iterations int
	algorithm  string
	created_at string
}

// hash_password creates a secure hash of a password using salt and multiple iterations
pub fn hash_password(password string) string {
	// Generate cryptographically-inspired salt from multiple sources
	salt := generate_salt(password)

	// Use multiple iterations of hashing for key stretching
	iterations := 10000
	hash := stretch_key(password, salt, iterations)

	return 'v1$${salt}$${iterations}$${hash}'
}

// verify_password checks if a password matches a hash
pub fn verify_password(password string, hash_string string) bool {
	parts := hash_string.split('$')
	if parts.len != 4 {
		return false
	}

	version := parts[0]
	if version != 'v1' {
		return false
	}

	salt := parts[1]
	iterations := parts[2].int()
	stored_hash := parts[3]

	computed_hash := stretch_key(password, salt, iterations)

	return secure_compare(computed_hash, stored_hash)
}

// generate_salt creates a salt based on password characteristics and time
fn generate_salt(password string) string {
	now := time.now()
	// Combine multiple entropy sources
	entropy := '${now.unix_nano()}_${password.len}_${int(password[0])}_${int(password[password.len - 1])}'

	// Create salt hash
	mut salt_hash := u64(0)
	for b in entropy {
		salt_hash = salt_hash * 31 + u64(b)
	}

	// Generate salt string with consistent length
	salt_chars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	mut salt := ''
	mut hash_val := salt_hash
	for i := 0; i < 16; i++ {
		idx := hash_val % u64(salt_chars.len)
		salt += salt_chars[idx].str()
		hash_val = hash_val * 17 + u64(now.unix())
	}

	return salt
}

// stretch_key performs key stretching to make brute-force attacks harder
fn stretch_key(password string, salt string, iterations int) string {
	// Initial combination
	mut data := '${password}${salt}'
	mut hash1 := u64(0)
	mut hash2 := u64(0)

	// Multiple rounds of hashing
	for i in 0 .. iterations {
		// First hash function
		hash1 = u64(0)
		for b in data {
			hash1 = (hash1 * 31 + u64(b)) ^ (hash1 >> 4)
		}

		// Second hash function (different multiplier)
		hash2 = u64(0)
		for b in data {
			hash2 = (hash2 * 37 + u64(b)) ^ (hash2 >> 5)
		}

		// Combine hashes
		combined := (hash1 + hash2) ^ (hash1 * 3)
		data = '${data}${combined}'

		_ = i
	}

	// Final combined hash as hex-like string
	return '${hash1}_x_${hash2}'
}

// secure_compare compares two strings in constant time to prevent timing attacks
pub fn secure_compare(a string, b string) bool {
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
// Password Validation
// ============================================================================

// PasswordRequirements defines password policy requirements
pub struct PasswordRequirements {
pub mut:
	min_length     int
	require_upper  bool
	require_lower  bool
	require_digit  bool
	require_special bool
}

// default_requirements returns the default password requirements
pub fn default_requirements() PasswordRequirements {
	return PasswordRequirements{
		min_length: 8
		require_upper: true
		require_lower: true
		require_digit: true
		require_special: true
	}
}

// validate_password_strength checks if password meets requirements
pub fn validate_password_strength(password string) ! {
	reqs := default_requirements()
	validate_password_with_requirements(password, reqs) or {
		return err
	}
}

// validate_password_with_requirements checks password against custom requirements
pub fn validate_password_with_requirements(password string, reqs PasswordRequirements) ! {
	if password.len < reqs.min_length {
		return error('Password must be at least ${reqs.min_length} characters')
	}

	mut has_upper := false
	mut has_lower := false
	mut has_digit := false
	mut has_special := false

	for c in password {
		if c.is_capital() {
			has_upper = true
		}
		if c.is_letter() && !c.is_capital() {
			has_lower = true
		}
		if c.is_digit() {
			has_digit = true
		}
		if !c.is_letter() && !c.is_digit() {
			has_special = true
		}
	}

	if reqs.require_upper && !has_upper {
		return error('Password must contain at least one uppercase letter')
	}
	if reqs.require_lower && !has_lower {
		return error('Password must contain at least one lowercase letter')
	}
	if reqs.require_digit && !has_digit {
		return error('Password must contain at least one number')
	}
	if reqs.require_special && !has_special {
		return error('Password must contain at least one special character')
	}
}

// is_password_valid checks password validity without error messages
pub fn is_password_valid(password string) bool {
	reqs := default_requirements()
	return is_password_valid_with_requirements(password, reqs)
}

// is_password_valid_with_requirements checks password against custom requirements
pub fn is_password_valid_with_requirements(password string, reqs PasswordRequirements) bool {
	if password.len < reqs.min_length {
		return false
	}

	mut has_upper := false
	mut has_lower := false
	mut has_digit := false
	mut has_special := false

	for c in password {
		if c.is_capital() {
			has_upper = true
		}
		if c.is_letter() && !c.is_capital() {
			has_lower = true
		}
		if c.is_digit() {
			has_digit = true
		}
		if !c.is_letter() && !c.is_digit() {
			has_special = true
		}
	}

	if reqs.require_upper && !has_upper {
		return false
	}
	if reqs.require_lower && !has_lower {
		return false
	}
	if reqs.require_digit && !has_digit {
		return false
	}
	if reqs.require_special && !has_special {
		return false
	}

	return true
}

// calculate_password_entropy estimates password entropy in bits
pub fn calculate_password_entropy(password string) f64 {
	mut charset_size := 0
	mut has_upper := false
	mut has_lower := false
	mut has_digit := false
	mut has_special := false

	for c in password {
		if c.is_capital() {
			has_upper = true
		}
		if c.is_letter() && !c.is_capital() {
			has_lower = true
		}
		if c.is_digit() {
			has_digit = true
		}
		if !c.is_letter() && !c.is_digit() {
			has_special = true
		}
	}

	if has_upper {
		charset_size += 26
	}
	if has_lower {
		charset_size += 26
	}
	if has_digit {
		charset_size += 10
	}
	if has_special {
		charset_size += 32
	}

	if charset_size == 0 {
		return 0
	}

	// Entropy = length * log2(charset_size)
	return f64(password.len) * (math.log(f64(charset_size)) / math.log(2))
}
