module services

// V Test file - run with: v test src/services/integration_test.v
// Integration tests for service interactions

import time

fn test_service_composition() {
	mut assert_count := 0

	// Create all services
	config := new_config_service()
	config.init()

	logger := new_logger_service()
	logger.init()

	cache := new_cache_service()
	cache.init()

	validation := new_validation_service()
	validation.init()

	// Verify all services are initialized
	assert config.initialized == true
	assert_count++

	assert logger.initialized == true
	assert_count++

	assert cache.initialized == true
	assert_count++

	assert validation.initialized == true
	assert_count++

	println('test_service_composition: ${assert_count} assertions passed')
}

fn test_logger_with_config() {
	mut assert_count := 0

	config := new_config_service()
	config.init()
	config.set('log_level', 'debug')

	logger := new_logger_service()
	logger.init()
	logger.set_min_level(config.get_string('log_level', 'info'))

	// Logger should use config level
	logger.debug('Debug message')
	logger.info('Info message')

	assert logger.get_log_count() == 2
	assert_count++

	assert logger.get_min_level() == 'debug'
	assert_count++

	println('test_logger_with_config: ${assert_count} assertions passed')
}

fn test_cache_with_validation() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	validation := new_validation_service()
	validation.init()
	validation.add_rule('email', 'required')
	validation.add_rule('email', 'email')

	// Validate and cache result
	mut data := map[string]string{}
	data['email'] = 'test@example.com'

	result := validation.validate(data)
	if result.is_valid {
		cache.set('validation_result', 'valid', 60)
	}

	assert cache.has('validation_result') == true
	assert_count++

	value := cache.get('validation_result') or { '' }
	assert value == 'valid'
	assert_count++

	println('test_cache_with_validation: ${assert_count} assertions passed')
}

fn test_auth_with_cache() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	cache := new_cache_service()
	cache.init()

	// Register user
	auth.register_user('cachetest', 'password123', 'cache@example.com')

	// Cache user info
	cache.set('user_cachetest', 'active', 300)

	// Authenticate
	result := auth.authenticate('cachetest', 'password123') or {
		assert false
		return
	}

	// Cache token
	if result.success {
		cache.set('token_${result.user_id}', result.token, 3600)
	}

	assert cache.has('user_cachetest') == true
	assert_count++

	assert cache.has('token_${result.user_id}') == true
	assert_count++

	println('test_auth_with_cache: ${assert_count} assertions passed')
}

fn test_validation_with_logger() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()
	logger.set_min_level('debug')

	validation := new_validation_service()
	validation.init()
	validation.add_rule('name', 'required')

	// Log validation start
	logger.debug('Starting validation')

	// Validate invalid data
	mut data := map[string]string{}
	data['name'] = ''
	result := validation.validate(data)

	// Log validation result
	if !result.is_valid {
		logger.warn('Validation failed')
	}

	assert result.is_valid == false
	assert_count++

	// Check logs
	assert logger.get_log_count() >= 2
	assert_count++

	println('test_validation_with_logger: ${assert_count} assertions passed')
}

fn test_sqlite_with_validation() {
	mut assert_count := 0

	import os

	temp_db := '/tmp/test_integration_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	validation := new_validation_service()
	validation.init()
	validation.add_rule('email', 'required')
	validation.add_rule('email', 'email')

	// Validate before creating
	mut data := map[string]string{}
	data['email'] = 'valid@example.com'
	result := validation.validate(data)

	if result.is_valid {
		user := db.create_user('Valid User', 'valid@example.com', 25) or {
			assert false
			return
		}
		assert user.id > 0
		assert_count++
	}

	// Try invalid email
	data['email'] = 'invalid-email'
	result2 := validation.validate(data)

	assert result2.is_valid == false
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_sqlite_with_validation: ${assert_count} assertions passed')
}

fn test_auth_with_validation() {
	mut assert_count := 0

	auth := new_auth_service()
	auth.init()

	validation := new_validation_service()
	validation.init()
	validation.add_rule('username', 'required')
	validation.add_rule('password', 'min:6')

	// Validate registration data
	mut reg_data := map[string]string{}
	reg_data['username'] = 'validuser'
	reg_data['password'] = 'securepass123'

	result := validation.validate(reg_data)
	assert result.is_valid == true
	assert_count++

	// Register if valid
	if result.is_valid {
		registered := auth.register_user('validuser', 'securepass123', 'valid@example.com')
		assert registered == true
		assert_count++
	}

	// Validate login data
	mut login_data := map[string]string{}
	login_data['username'] = 'validuser'
	login_data['password'] = 'securepass123'

	login_result := validation.validate(login_data)
	assert login_result.is_valid == true
	assert_count++

	println('test_auth_with_validation: ${assert_count} assertions passed')
}

fn test_service_lifecycle() {
	mut assert_count := 0

	// Create services
	config := new_config_service()
	logger := new_logger_service()
	cache := new_cache_service()
	validation := new_validation_service()
	auth := new_auth_service()

	// Initialize all
	config.init()
	logger.init()
	cache.init()
	validation.init()
	auth.init()

	// Use services
	config.set('test', 'value')
	logger.info('Test log')
	cache.set('key', 'value', 60)
	validation.add_rule('field', 'required')
	auth.register_user('lifecycle', 'pass123', 'lifecycle@example.com')

	// Dispose all
	config.dispose()
	logger.dispose()
	cache.dispose()
	validation.dispose()
	auth.dispose()

	// Verify disposal (cache should be cleared)
	assert cache.count() == 0
	assert_count++

	println('test_service_lifecycle: ${assert_count} assertions passed')
}

fn test_concurrent_cache_access() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Simulate concurrent writes
	for i in 0..10 {
		cache.set('key_${i}', 'value_${i}', 60)
	}

	// Verify all writes
	for i in 0..10 {
		value := cache.get('key_${i}') or { '' }
		assert value == 'value_${i}'
		assert_count++
	}

	assert cache.count() == 10
	assert_count++

	println('test_concurrent_cache_access: ${assert_count} assertions passed')
}

fn test_all() {
	test_service_composition()
	test_logger_with_config()
	test_cache_with_validation()
	test_auth_with_cache()
	test_validation_with_logger()
	test_sqlite_with_validation()
	test_auth_with_validation()
	test_service_lifecycle()
	test_concurrent_cache_access()
}
