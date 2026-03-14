module services

import time
import os

// ==================== ConfigService Tests ====================

fn test_config_service_init() {
	println('Testing: test_config_service_init')
	
	mut service := new_config_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'config', 'Name should be config'
	
	println('  ✓ PASSED: test_config_service_init')
}

fn test_config_service_set_get() {
	println('Testing: test_config_service_set_get')
	
	mut service := new_config_service()
	service.init()
	
	service.set('app_name', 'TestApp')
	service.set('version', '1.0.0')
	service.set('debug', 'true')
	
	assert service.has('app_name') == true, 'Should have app_name'
	assert service.get_string('app_name', 'default') == 'TestApp', 'Should get correct value'
	assert service.get_string('nonexistent', 'default') == 'default', 'Should get default value'
	
	assert service.get_int('version', 0) == 1, 'Should parse int correctly'
	assert service.get_bool('debug', false) == true, 'Should parse bool correctly'
	
	println('  ✓ PASSED: test_config_service_set_get')
}

fn test_config_service_get_all() {
	println('Testing: test_config_service_get_all')
	
	mut service := new_config_service()
	service.init()
	
	service.set('key1', 'value1')
	service.set('key2', 'value2')
	service.set('key3', 'value3')
	
	all := service.get_all()
	assert all.len == 3, 'Should have 3 entries'
	assert all['key1'] == 'value1', 'Value should match'
	
	println('  ✓ PASSED: test_config_service_get_all')
}

// ==================== CacheService Tests ====================

fn test_cache_service_init() {
	println('Testing: test_cache_service_init')
	
	mut service := new_cache_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'cache', 'Name should be cache'
	
	println('  ✓ PASSED: test_cache_service_init')
}

fn test_cache_service_set_get() {
	println('Testing: test_cache_service_set_get')
	
	mut service := new_cache_service()
	service.init()
	
	service.set('key1', 'value1', 300)
	service.set('key2', 'value2', 300)
	
	assert service.has('key1') == true, 'Should have key1'
	assert service.has('key2') == true, 'Should have key2'
	
	value := service.get('key1') or {
		assert false, 'Should get value'
		return
	}
	assert value == 'value1', 'Value should match'
	
	println('  ✓ PASSED: test_cache_service_set_get')
}

fn test_cache_service_delete() {
	println('Testing: test_cache_service_delete')
	
	mut service := new_cache_service()
	service.init()
	
	service.set('key1', 'value1', 300)
	assert service.has('key1') == true, 'Should have key1'
	
	success := service.delete('key1')
	assert success == true, 'Delete should succeed'
	assert service.has('key1') == false, 'Should not have key1 after delete'
	
	println('  ✓ PASSED: test_cache_service_delete')
}

fn test_cache_service_clear() {
	println('Testing: test_cache_service_clear')
	
	mut service := new_cache_service()
	service.init()
	
	service.set('key1', 'value1', 300)
	service.set('key2', 'value2', 300)
	service.set('key3', 'value3', 300)
	
	assert service.count() == 3, 'Should have 3 entries'
	
	service.clear()
	assert service.count() == 0, 'Should be empty after clear'
	
	println('  ✓ PASSED: test_cache_service_clear')
}

fn test_cache_service_ttl() {
	println('Testing: test_cache_service_ttl')
	
	mut service := new_cache_service()
	service.init()
	
	// Set with 0 TTL (should still work)
	service.set('immediate', 'value', 0)
	assert service.has('immediate') == true, 'Should have immediate value'
	
	println('  ✓ PASSED: test_cache_service_ttl')
}

fn test_cache_service_stats() {
	println('Testing: test_cache_service_stats')
	
	mut service := new_cache_service()
	service.init()
	
	service.set('key1', 'value1', 300)
	service.set('key2', 'value2', 300)
	
	_ = service.get('key1')
	_ = service.get('key1')
	_ = service.get('key2')
	_ = service.get('nonexistent')
	
	stats := service.get_stats()
	assert stats.total_entries == 2, 'Should have 2 entries'
	assert stats.hit_count == 3, 'Should have 3 hits'
	assert stats.miss_count == 1, 'Should have 1 miss'
	
	println('  ✓ PASSED: test_cache_service_stats')
}

// ==================== ValidationService Tests ====================

fn test_validation_service_init() {
	println('Testing: test_validation_service_init')
	
	mut service := new_validation_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'validation', 'Name should be validation'
	
	println('  ✓ PASSED: test_validation_service_init')
}

fn test_validation_service_required() {
	println('Testing: test_validation_service_required')
	
	mut service := new_validation_service()
	service.init()
	
	service.add_rule('username', 'required')
	service.add_rule('email', 'required')
	
	// Valid data
	data := {
		'username': 'john'
		'email': 'john @example.com'
	}
	result := service.validate(data)
	assert result.is_valid == true, 'Should be valid'
	
	// Invalid data (missing required)
	invalid_data := {
		'username': ''
		'email': 'john @example.com'
	}
	result2 := service.validate(invalid_data)
	assert result2.is_valid == false, 'Should be invalid'
	assert result2.errors.len > 0, 'Should have errors'
	
	println('  ✓ PASSED: test_validation_service_required')
}

fn test_validation_service_min_max() {
	println('Testing: test_validation_service_min_max')
	
	mut service := new_validation_service()
	service.init()
	
	service.add_rule('password', 'min:6')
	service.add_rule('username', 'max:20')
	
	// Valid
	data := {
		'password': '123456'
		'username': 'john'
	}
	result := service.validate(data)
	assert result.is_valid == true, 'Should be valid'
	
	// Invalid - too short
	invalid_data := {
		'password': '123'
		'username': 'john'
	}
	result2 := service.validate(invalid_data)
	assert result2.is_valid == false, 'Should be invalid (too short)'
	
	// Invalid - too long
	invalid_data2 := {
		'password': '123456'
		'username': 'this_username_is_way_too_long'
	}
	result3 := service.validate(invalid_data2)
	assert result3.is_valid == false, 'Should be invalid (too long)'
	
	println('  ✓ PASSED: test_validation_service_min_max')
}

fn test_validation_service_email() {
	println('Testing: test_validation_service_email')
	
	mut service := new_validation_service()
	service.init()
	
	service.add_rule('email', 'email')
	
	// Valid emails
	valid_emails := ['test @example.com', 'user @domain.org', 'a @b.co']
	for email in valid_emails {
		data := {'email': email}
		result := service.validate(data)
		assert result.is_valid == true, 'Should be valid email: ${email}'
	}
	
	// Invalid emails
	invalid_emails := ['invalid', 'no @sign', ' @missing.local']
	for email in invalid_emails {
		data := {'email': email}
		result := service.validate(data)
		assert result.is_valid == false, 'Should be invalid email: ${email}'
	}
	
	println('  ✓ PASSED: test_validation_service_email')
}

fn test_validation_service_numeric() {
	println('Testing: test_validation_service_numeric')
	
	mut service := new_validation_service()
	service.init()
	
	service.add_rule('age', 'numeric')
	
	// Valid
	data := {'age': '123'}
	result := service.validate(data)
	assert result.is_valid == true, 'Should be valid numeric'
	
	// Invalid
	invalid_data := {'age': 'abc'}
	result2 := service.validate(invalid_data)
	assert result2.is_valid == false, 'Should be invalid numeric'
	
	println('  ✓ PASSED: test_validation_service_numeric')
}

// ==================== MetricsService Tests ====================

fn test_metrics_service_init() {
	println('Testing: test_metrics_service_init')
	
	mut service := new_metrics_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'metrics', 'Name should be metrics'
	
	println('  ✓ PASSED: test_metrics_service_init')
}

fn test_metrics_service_counter() {
	println('Testing: test_metrics_service_counter')
	
	mut service := new_metrics_service()
	service.init()
	
	service.increment_counter('requests', 1)
	service.increment_counter('requests', 5)
	service.increment_counter('requests', 10)
	
	assert service.get_counter('requests') == 16, 'Counter should be 16'
	assert service.get_counter('nonexistent') == 0, 'Nonexistent counter should be 0'
	
	println('  ✓ PASSED: test_metrics_service_counter')
}

fn test_metrics_service_gauge() {
	println('Testing: test_metrics_service_gauge')
	
	mut service := new_metrics_service()
	service.init()
	
	service.record_gauge('temperature', 25.5)
	assert service.get_gauge('temperature') == 25.5, 'Gauge should be 25.5'
	
	service.record_gauge('temperature', 30.0)
	assert service.get_gauge('temperature') == 30.0, 'Gauge should be updated'
	
	println('  ✓ PASSED: test_metrics_service_gauge')
}

fn test_metrics_service_histogram() {
	println('Testing: test_metrics_service_histogram')
	
	mut service := new_metrics_service()
	service.init()
	
	service.record_histogram('response_time', 10.0)
	service.record_histogram('response_time', 20.0)
	service.record_histogram('response_time', 30.0)
	
	hist := service.get_histogram('response_time')
	assert hist.count == 3, 'Count should be 3'
	assert hist.sum == 60.0, 'Sum should be 60'
	assert hist.min == 10.0, 'Min should be 10'
	assert hist.max == 30.0, 'Max should be 30'
	assert hist.avg == 20.0, 'Avg should be 20'
	
	println('  ✓ PASSED: test_metrics_service_histogram')
}

fn test_metrics_service_timing() {
	println('Testing: test_metrics_service_timing')
	
	mut service := new_metrics_service()
	service.init()
	
	service.record_timing('api_call', 100.0)
	service.record_timing('api_call', 150.0)
	service.record_timing('api_call', 200.0)
	
	stats := service.get_timing_stats('api_call')
	assert stats.count == 3, 'Count should be 3'
	assert stats.total == 450.0, 'Total should be 450'
	assert stats.avg == 150.0, 'Avg should be 150'
	
	println('  ✓ PASSED: test_metrics_service_timing')
}

fn test_metrics_service_reset() {
	println('Testing: test_metrics_service_reset')
	
	mut service := new_metrics_service()
	service.init()
	
	service.increment_counter('test', 10)
	service.record_gauge('test', 5.0)
	
	service.reset()
	
	assert service.get_counter('test') == 0, 'Counter should be reset'
	assert service.get_gauge('test') == 0.0, 'Gauge should be reset'
	
	println('  ✓ PASSED: test_metrics_service_reset')
}

// ==================== LoggerService Tests ====================

fn test_logger_service_init() {
	println('Testing: test_logger_service_init')
	
	mut service := new_logger_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	
	println('  ✓ PASSED: test_logger_service_init')
}

fn test_logger_service_levels() {
	println('Testing: test_logger_service_levels')
	
	mut service := new_logger_service()
	service.init()
	
	service.set_min_level('warn')
	assert service.get_min_level() == 'warn', 'Min level should be warn'
	
	service.set_min_level('debug')
	assert service.get_min_level() == 'debug', 'Min level should be debug'
	
	println('  ✓ PASSED: test_logger_service_levels')
}

fn test_logger_service_log_count() {
	println('Testing: test_logger_service_log_count')
	
	mut service := new_logger_service()
	service.init()
	
	service.set_min_level('debug')
	
	initial_count := service.get_log_count()
	
	service.debug('test1')
	service.info('test2')
	service.warn('test3')
	service.error('test4')
	
	final_count := service.get_log_count()
	assert final_count == initial_count + 4, 'Should have logged 4 messages'
	
	service.reset_log_count()
	assert service.get_log_count() == 0, 'Count should be reset'
	
	println('  ✓ PASSED: test_logger_service_log_count')
}

// ==================== HealthCheckService Tests ====================

fn test_health_check_service_init() {
	println('Testing: test_health_check_service_init')
	
	mut service := new_health_check_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'health_check', 'Name should be health_check'
	
	println('  ✓ PASSED: test_health_check_service_init')
}

fn test_health_check_service_register() {
	println('Testing: test_health_check_service_register')
	
	mut service := new_health_check_service()
	service.init()
	
	service.register_check('custom', fn () HealthStatus {
		return HealthStatus{
			name: 'custom'
			is_healthy: true
			status: 'healthy'
			message: 'Custom check passed'
			duration_ms: 0
			timestamp: u64(time.now().unix())
			details: map[string]string{}
		}
	})
	
	status := service.run_check('custom') or {
		assert false, 'Should get status'
		return
	}
	
	assert status.name == 'custom', 'Name should match'
	assert status.is_healthy == true, 'Should be healthy'
	
	println('  ✓ PASSED: test_health_check_service_register')
}

fn test_health_check_service_run_all() {
	println('Testing: test_health_check_service_run_all')
	
	mut service := new_health_check_service()
	service.init()
	
	results := service.run_all_checks()
	assert results.len > 0, 'Should have at least one check'
	
	summary := service.get_status()
	assert summary.total_checks > 0, 'Should have checks'
	assert summary.is_healthy == true, 'Default should be healthy'
	
	println('  ✓ PASSED: test_health_check_service_run_all')
}

// ==================== AuthService Tests ====================

fn test_auth_service_init() {
	println('Testing: test_auth_service_init')
	
	mut service := new_auth_service()
	result := service.init()
	
	assert result == true, 'Init should succeed'
	assert service.is_initialized() == true, 'Should be initialized'
	assert service.name() == 'auth', 'Name should be auth'
	
	println('  ✓ PASSED: test_auth_service_init')
}

fn test_auth_service_register_user() {
	println('Testing: test_auth_service_register_user')
	
	mut service := new_auth_service()
	service.init()
	
	success := service.register_user('testuser', 'password123', 'test @example.com')
	assert success == true, 'Registration should succeed'
	
	// Try to register same user again
	success2 := service.register_user('testuser', 'password123', 'test @example.com')
	assert success2 == false, 'Duplicate registration should fail'
	
	println('  ✓ PASSED: test_auth_service_register_user')
}

fn test_auth_service_authenticate() {
	println('Testing: test_auth_service_authenticate')
	
	mut service := new_auth_service()
	service.init()
	
	service.register_user('testuser', 'password123', 'test @example.com')
	
	result := service.authenticate('testuser', 'password123') or {
		assert false, 'Authentication should succeed'
		return
	}
	
	assert result.success == true, 'Should be successful'
	assert result.username == 'testuser', 'Username should match'
	assert result.token != '', 'Should have token'
	
	println('  ✓ PASSED: test_auth_service_authenticate')
}

fn test_auth_service_token_validation() {
	println('Testing: test_auth_service_token_validation')
	
	mut service := new_auth_service()
	service.init()
	
	service.register_user('testuser', 'password123', 'test @example.com')
	result := service.authenticate('testuser', 'password123') or {
		assert false, 'Authentication should succeed'
		return
	}
	
	// Validate token
	validated := service.validate_token(result.token) or {
		assert false, 'Token validation should succeed'
		return
	}
	
	assert validated.success == true, 'Should be valid'
	assert validated.user_id == result.user_id, 'User ID should match'
	
	// Revoke token
	revoked := service.revoke_token(result.token)
	assert revoked == true, 'Revocation should succeed'
	
	// Try to validate revoked token
	revoked_result := service.validate_token(result.token)
	assert revoked_result is error, 'Revoked token should be invalid'
	
	println('  ✓ PASSED: test_auth_service_token_validation')
}

fn test_auth_service_permissions() {
	println('Testing: test_auth_service_permissions')
	
	mut service := new_auth_service()
	service.init()
	
	service.register_user('testuser', 'password123', 'test @example.com')
	service.authenticate('testuser', 'password123')
	service.set_current_user('testuser')
	
	// Check default permissions
	has_read := service.has_permission('read')
	assert has_read == true, 'Should have read permission'
	
	has_admin := service.has_permission('admin')
	assert has_admin == false, 'Should not have admin permission'
	
	// Add permission
	service.add_permission_to_user('testuser', 'admin')
	has_admin2 := service.has_permission('admin')
	assert has_admin2 == true, 'Should have admin permission after adding'
	
	println('  ✓ PASSED: test_auth_service_permissions')
}

// Run all service tests
pub fn run_all_tests() {
	println('')
	println('========================================')
	println('Running Service Tests')
	println('========================================')
	println('')
	
	// ConfigService tests
	test_config_service_init()
	test_config_service_set_get()
	test_config_service_get_all()
	
	// CacheService tests
	test_cache_service_init()
	test_cache_service_set_get()
	test_cache_service_delete()
	test_cache_service_clear()
	test_cache_service_ttl()
	test_cache_service_stats()
	
	// ValidationService tests
	test_validation_service_init()
	test_validation_service_required()
	test_validation_service_min_max()
	test_validation_service_email()
	test_validation_service_numeric()
	
	// MetricsService tests
	test_metrics_service_init()
	test_metrics_service_counter()
	test_metrics_service_gauge()
	test_metrics_service_histogram()
	test_metrics_service_timing()
	test_metrics_service_reset()
	
	// LoggerService tests
	test_logger_service_init()
	test_logger_service_levels()
	test_logger_service_log_count()
	
	// HealthCheckService tests
	test_health_check_service_init()
	test_health_check_service_register()
	test_health_check_service_run_all()
	
	// AuthService tests
	test_auth_service_init()
	test_auth_service_register_user()
	test_auth_service_authenticate()
	test_auth_service_token_validation()
	test_auth_service_permissions()
	
	println('')
	println('========================================')
	println('All Service Tests Passed!')
	println('========================================')
	println('')
}
