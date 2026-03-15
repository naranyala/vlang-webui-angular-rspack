module services

// V Test file - run with: v test src/services/auth_service_test.v

import time

fn test_new_auth_service() {
	mut assert_count := 0

	auth := new_auth_service()

	assert auth != 0
	assert_count++

	assert auth.initialized == false
	assert_count++

	assert auth.token_expiry_sec == 3600
	assert_count++

	assert auth.users.len == 0
	assert_count++

	assert auth.tokens.len == 0
	assert_count++

	println('test_new_auth_service: ${assert_count} assertions passed')
}

fn test_init() {
	mut assert_count := 0

	auth := new_auth_service()
	result := auth.init()

	assert result == true
	assert_count++

	assert auth.initialized == true
	assert_count++

	println('test_init: ${assert_count} assertions passed')
}

fn test_register_user() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register a new user
	result := auth.register_user('testuser', 'password123', 'test@example.com')
	assert result == true
	assert_count++

	// Try to register same user again
	result2 := auth.register_user('testuser', 'password456', 'test2@example.com')
	assert result2 == false
	assert_count++

	// Register different user
	result3 := auth.register_user('user2', 'password456', 'user2@example.com')
	assert result3 == true
	assert_count++

	println('test_register_user: ${assert_count} assertions passed')
}

fn test_authenticate_success() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register user
	auth.register_user('authuser', 'securepass', 'auth@example.com')

	// Authenticate with correct credentials
	result := auth.authenticate('authuser', 'securepass') or {
		assert false
		return
	}

	assert result.success == true
	assert_count++

	assert result.user_id != ''
	assert_count++

	assert result.username == 'authuser'
	assert_count++

	assert result.token != ''
	assert_count++

	assert result.expires_at > u64(time.now().unix())
	assert_count++

	println('test_authenticate_success: ${assert_count} assertions passed')
}

fn test_authenticate_failure() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register user
	auth.register_user('failuser', 'correctpass', 'fail@example.com')

	// Try wrong password
	_ = auth.authenticate('failuser', 'wrongpass') or {
		assert true
		assert_count++
	}

	// Try non-existent user
	_ = auth.authenticate('nonexistent', 'anypass') or {
		assert true
		assert_count++
	}

	println('test_authenticate_failure: ${assert_count} assertions passed')
}

fn test_validate_token() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register and authenticate
	auth.register_user('tokenuser', 'pass123', 'token@example.com')
	auth_result := auth.authenticate('tokenuser', 'pass123') or {
		assert false
		return
	}

	// Validate the token
	result := auth.validate_token(auth_result.token) or {
		assert false
		return
	}

	assert result.success == true
	assert_count++

	assert result.user_id == auth_result.user_id
	assert_count++

	println('test_validate_token: ${assert_count} assertions passed')
}

fn test_token_expiration() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()
	auth.token_expiry_sec = 1 // 1 second expiry

	// Register and authenticate
	auth.register_user('expireuser', 'pass123', 'expire@example.com')
	auth_result := auth.authenticate('expireuser', 'pass123') or {
		assert false
		return
	}

	// Token should be valid immediately
	result1 := auth.validate_token(auth_result.token) or {
		assert false
		return
	}
	assert result1.success == true
	assert_count++

	// Wait for expiration
	time.sleep(2 * time.second)

	// Token should be expired
	_ = auth.validate_token(auth_result.token) or {
		assert true
		assert_count++
	}

	println('test_token_expiration: ${assert_count} assertions passed')
}

fn test_revoke_token() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register and authenticate
	auth.register_user('revokeuser', 'pass123', 'revoke@example.com')
	auth_result := auth.authenticate('revokeuser', 'pass123') or {
		assert false
		return
	}

	// Revoke the token
	result := auth.revoke_token(auth_result.token)
	assert result == true
	assert_count++

	// Try to revoke again
	result2 := auth.revoke_token(auth_result.token)
	assert result2 == false
	assert_count++

	// Token should no longer be valid
	_ = auth.validate_token(auth_result.token) or {
		assert true
		assert_count++
	}

	println('test_revoke_token: ${assert_count} assertions passed')
}

fn test_get_current_user() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// No current user initially
	_ = auth.get_current_user() or {
		assert true
		assert_count++
	}

	// Register and set current user
	auth.register_user('currentuser', 'pass123', 'current@example.com')
	auth.set_current_user('currentuser')

	user := auth.get_current_user() or {
		assert false
		return
	}

	assert user.username == 'currentuser'
	assert_count++

	assert user.email == 'current@example.com'
	assert_count++

	println('test_get_current_user: ${assert_count} assertions passed')
}

fn test_has_permission() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// No current user
	assert auth.has_permission('read') == false
	assert_count++

	// Register and set current user
	auth.register_user('permuser', 'pass123', 'perm@example.com')
	auth.set_current_user('permuser')

	// Default user has 'read' permission
	assert auth.has_permission('read') == true
	assert_count++

	// Default user doesn't have 'admin' permission
	assert auth.has_permission('admin') == false
	assert_count++

	println('test_has_permission: ${assert_count} assertions passed')
}

fn test_has_role() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// No current user
	assert auth.has_role('user') == false
	assert_count++

	// Register and set current user
	auth.register_user('roleuser', 'pass123', 'role@example.com')
	auth.set_current_user('roleuser')

	// Default user has 'user' role
	assert auth.has_role('user') == true
	assert_count++

	// Default user doesn't have 'admin' role
	assert auth.has_role('admin') == false
	assert_count++

	println('test_has_role: ${assert_count} assertions passed')
}

fn test_logout() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register and set current user
	auth.register_user('logoutuser', 'pass123', 'logout@example.com')
	auth.set_current_user('logoutuser')

	// Verify current user is set
	assert auth.get_current_user() is not error
	assert_count++

	// Logout
	auth.logout()

	// No current user after logout
	_ = auth.get_current_user() or {
		assert true
		assert_count++
	}

	println('test_logout: ${assert_count} assertions passed')
}

fn test_get_user() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register user
	auth.register_user('getuser', 'pass123', 'get@example.com')

	// Get existing user
	user := auth.get_user('getuser') or {
		assert false
		return
	}

	assert user.username == 'getuser'
	assert_count++

	assert user.email == 'get@example.com'
	assert_count++

	// Get non-existent user
	_ = auth.get_user('nonexistent') or {
		assert true
		assert_count++
	}

	println('test_get_user: ${assert_count} assertions passed')
}

fn test_add_role_to_user() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register user
	auth.register_user('roleadduser', 'pass123', 'roleadd@example.com')

	// Add role
	result := auth.add_role_to_user('roleadduser', 'admin')
	assert result == true
	assert_count++

	// User should now have admin role
	auth.set_current_user('roleadduser')
	assert auth.has_role('admin') == true
	assert_count++

	// Adding same role again should return true (no duplicate)
	result2 := auth.add_role_to_user('roleadduser', 'admin')
	assert result2 == true
	assert_count++

	// Non-existent user
	result3 := auth.add_role_to_user('nonexistent', 'admin')
	assert result3 == false
	assert_count++

	println('test_add_role_to_user: ${assert_count} assertions passed')
}

fn test_add_permission_to_user() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	// Register user
	auth.register_user('permadduser', 'pass123', 'permadd@example.com')

	// Add permission
	result := auth.add_permission_to_user('permadduser', 'write')
	assert result == true
	assert_count++

	// User should now have write permission
	auth.set_current_user('permadduser')
	assert auth.has_permission('write') == true
	assert_count++

	// Non-existent user
	result2 := auth.add_permission_to_user('nonexistent', 'write')
	assert result2 == false
	assert_count++

	println('test_add_permission_to_user: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_auth_service()
	test_init()
	test_register_user()
	test_authenticate_success()
	test_authenticate_failure()
	test_validate_token()
	test_token_expiration()
	test_revoke_token()
	test_get_current_user()
	test_has_permission()
	test_has_role()
	test_logout()
	test_get_user()
	test_add_role_to_user()
	test_add_permission_to_user()
}
