module security

// V Test file - run with: v test src/security_test.v
// Comprehensive security tests for password hashing, tokens, and input validation

import time

fn test_hash_password() {
	mut assert_count := 0

	// Test password hashing
	password := 'SecurePassword123!'
	hash := hash_password(password)

	// Hash should not be empty
	assert hash != ''
	assert_count++

	// Hash should contain salt and hash parts
	parts := hash.split('$')
	assert parts.len == 3
	assert_count++

	// Hash should be different each time (different salt)
	hash2 := hash_password(password)
	assert hash != hash2
	assert_count++

	// Hash should not contain plaintext password
	assert !hash.contains(password)
	assert_count++

	println('test_hash_password: ${assert_count} assertions passed')
}

fn test_verify_password_success() {
	mut assert_count := 0

	password := 'TestPassword456!'
	hash := hash_password(password)

	// Verify correct password
	result := verify_password(password, hash)
	assert result == true
	assert_count++

	println('test_verify_password_success: ${assert_count} assertions passed')
}

fn test_verify_password_failure() {
	mut assert_count := 0

	password := 'CorrectPassword'
	wrong_password := 'WrongPassword'
	hash := hash_password(password)

	// Verify wrong password fails
	result := verify_password(wrong_password, hash)
	assert result == false
	assert_count++

	// Verify empty password fails
	result2 := verify_password('', hash)
	assert result2 == false
	assert_count++

	println('test_verify_password_failure: ${assert_count} assertions passed')
}

fn test_verify_password_invalid_hash() {
	mut assert_count := 0

	// Invalid hash format
	result := verify_password('password', 'invalid_hash')
	assert result == false
	assert_count++

	// Empty hash
	result2 := verify_password('password', '')
	assert result2 == false
	assert_count++

	println('test_verify_password_invalid_hash: ${assert_count} assertions passed')
}

fn test_generate_secure_token() {
	mut assert_count := 0

	// Generate token
	token := generate_secure_token('test') or {
		assert false
		return
	}

	// Token should not be empty
	assert token != ''
	assert_count++

	// Token should contain prefix
	assert token.starts_with('test_')
	assert_count++

	// Token should be sufficiently long (at least 32 chars of randomness)
	assert token.len > 37  // prefix (5) + underscore (1) + random (32)
	assert_count++

	// Tokens should be unique
	token2 := generate_secure_token('test') or {
		assert false
		return
	}
	assert token != token2
	assert_count++

	println('test_generate_secure_token: ${assert_count} assertions passed')
}

fn test_generate_secure_token_randomness() {
	mut assert_count := 0

	// Generate multiple tokens and check uniqueness
	mut tokens := []string{}
	for i in 0..100 {
		token := generate_secure_token('tok') or {
			assert false
			return
		}
		tokens << token
	}

	// All tokens should be unique
	mut unique_count := 0
	for i in 0..tokens.len {
		mut is_unique := true
		for j in 0..tokens.len {
			if i != j && tokens[i] == tokens[j] {
				is_unique = false
				break
			}
		}
		if is_unique {
			unique_count++
		}
	}

	assert unique_count == 100
	assert_count++

	println('test_generate_secure_token_randomness: ${assert_count} assertions passed')
}

fn test_validate_password_strength() {
	mut assert_count := 0

	// Strong password should pass
	result := validate_password_strength('StrongPass123!')
	assert result is not error
	assert_count++

	// Too short should fail
	result2 := validate_password_strength('Short1!')
	assert result2 is error
	assert_count++

	// No uppercase should fail
	result3 := validate_password_strength('lowercase123!')
	assert result3 is error
	assert_count++

	// No lowercase should fail
	result4 := validate_password_strength('UPPERCASE123!')
	assert result4 is error
	assert_count++

	// No number should fail
	result5 := validate_password_strength('NoNumbers!')
	assert result5 is error
	assert_count++

	// No special char should fail
	result6 := validate_password_strength('NoSpecial123')
	assert result6 is error
	assert_count++

	println('test_validate_password_strength: ${assert_count} assertions passed')
}

fn test_sanitize_input() {
	mut assert_count := 0

	// Normal input should pass through
	clean := 'Hello World'
	result := sanitize_input(clean) or {
		assert false
		return
	}
	assert result == clean
	assert_count++

	// SQL injection attempt should be sanitized
	sql_injection := "'; DROP TABLE users; --"
	result2 := sanitize_input(sql_injection) or {
		// Sanitization might reject this
		assert true
		assert_count++
		return
	}
	// If not rejected, should be sanitized
	assert !result2.contains('DROP')
	assert_count++

	// XSS attempt should be sanitized
	xss := '<script>alert("xss")</script>'
	result3 := sanitize_input(xss) or {
		assert true
		assert_count++
		return
	}
	// If not rejected, should be sanitized
	assert !result3.contains('<script>')
	assert_count++

	println('test_sanitize_input: ${assert_count} assertions passed')
}

fn test_validate_identifier() {
	mut assert_count := 0

	// Valid identifiers
	result := validate_identifier('valid_name')
	assert result is not error
	assert_count++

	result2 := validate_identifier('_valid')
	assert result2 is not error
	assert_count++

	result3 := validate_identifier('name123')
	assert result3 is not error
	assert_count++

	// Invalid identifiers
	result4 := validate_identifier('invalid-name')
	assert result4 is error
	assert_count++

	result5 := validate_identifier('invalid.name')
	assert result5 is error
	assert_count++

	result6 := validate_identifier('123invalid')
	assert result6 is error
	assert_count++

	println('test_validate_identifier: ${assert_count} assertions passed')
}

fn test_secure_compare() {
	mut assert_count := 0

	// Equal strings should match
	result := secure_compare('test', 'test')
	assert result == true
	assert_count++

	// Different strings should not match
	result2 := secure_compare('test', 'different')
	assert result2 == false
	assert_count++

	// Empty strings should match
	result3 := secure_compare('', '')
	assert result3 == true
	assert_count++

	// Case sensitive
	result4 := secure_compare('Test', 'test')
	assert result4 == false
	assert_count++

	println('test_secure_compare: ${assert_count} assertions passed')
}

fn test_pbkdf2_simple() {
	mut assert_count := 0

	password := 'test_password'
	salt := 'test_salt'

	// Hash should be generated
	hash := pbkdf2_simple(password, salt, 1000)
	assert hash != ''
	assert_count++

	// Same inputs should produce same hash
	hash2 := pbkdf2_simple(password, salt, 1000)
	assert hash == hash2
	assert_count++

	// Different salt should produce different hash
	hash3 := pbkdf2_simple(password, 'different_salt', 1000)
	assert hash != hash3
	assert_count++

	// Different iterations should produce different hash
	hash4 := pbkdf2_simple(password, salt, 2000)
	assert hash != hash4
	assert_count++

	println('test_pbkdf2_simple: ${assert_count} assertions passed')
}

fn test_all() {
	test_hash_password()
	test_verify_password_success()
	test_verify_password_failure()
	test_verify_password_invalid_hash()
	test_generate_secure_token()
	test_generate_secure_token_randomness()
	test_validate_password_strength()
	test_sanitize_input()
	test_validate_identifier()
	test_secure_compare()
	test_pbkdf2_simple()
}
