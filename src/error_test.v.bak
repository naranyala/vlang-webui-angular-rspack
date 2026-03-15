module error

// V Test file - run with: v test src/error_test.v
// Each function starting with test_ is automatically executed

// ============================================================================
// Error Creation Tests
// ============================================================================

fn test_error_new() {
	mut assert_count := 0
	
	err := new(.validation_failed, 'Test message')
	assert err.code == .validation_failed
	assert_count++
	
	assert err.message == 'Test message'
	assert_count++
	
	assert err.source == 'backend'
	assert_count++
	
	assert err.context.len == 0
	assert_count++
	
	println('✓ test_error_new: ${assert_count} assertions passed')
}

fn test_error_with_details() {
	mut assert_count := 0
	
	err := with_details(.internal_error, 'Message', 'Detailed info')
	
	assert err.code == .internal_error
	assert_count++
	
	assert err.message == 'Message'
	assert_count++
	
	assert err.details == 'Detailed info'
	assert_count++
	
	println('test_error_with_details: ${assert_count} assertions passed')
}

fn test_error_with_field() {
	mut assert_count := 0
	
	err := with_field(.validation_failed, 'Invalid value', 'email')
	
	assert err.code == .validation_failed
	assert_count++
	
	assert err.field == 'email'
	assert_count++
	
	assert err.message == 'Invalid value'
	assert_count++
	
	println('test_error_with_field: ${assert_count} assertions passed')
}

fn test_error_with_context() {
	mut assert_count := 0
	
	mut ctx := map[string]string{}
	ctx['key1'] = 'value1'
	ctx['key2'] = 'value2'
	
	err := with_context(.db_query_failed, 'DB failed', ctx)
	
	assert err.code == .db_query_failed
	assert_count++
	
	assert err.context['key1'] == 'value1'
	assert_count++
	
	assert err.context['key2'] == 'value2'
	assert_count++
	
	println('✓ test_error_with_context: ${assert_count} assertions passed')
}

// ============================================================================
// Specific Error Constructor Tests
// ============================================================================

fn test_db_error() {
	mut assert_count := 0
	
	err := db_error('query', 'Connection timeout')
	
	assert err.code == .db_query_failed
	assert_count++
	
	assert err.message.contains('query')
	assert_count++
	
	assert err.message.contains('Connection timeout')
	assert_count++
	
	assert err.context['operation'] == 'query'
	assert_count++
	
	println('test_db_error: ${assert_count} assertions passed')
}

fn test_validation_error() {
	mut assert_count := 0
	
	err := validation_error('password', 'Must be at least 8 characters')
	
	assert err.code == .validation_failed
	assert_count++
	
	assert err.field == 'password'
	assert_count++
	
	assert err.message == 'Must be at least 8 characters'
	assert_count++
	
	println('test_validation_error: ${assert_count} assertions passed')
}

fn test_not_found_error() {
	mut assert_count := 0
	
	err := not_found_error('User', '12345')
	
	assert err.code == .resource_not_found
	assert_count++
	
	assert err.message.contains('User')
	assert_count++
	
	assert err.message.contains('12345')
	assert_count++
	
	assert err.context['resource'] == 'User'
	assert_count++
	
	assert err.context['id'] == '12345'
	assert_count++
	
	println('test_not_found_error: ${assert_count} assertions passed')
}

fn test_already_exists_error() {
	mut assert_count := 0
	
	err := already_exists_error('User', 'email', 'test@example.com')
	
	assert err.code == .db_already_exists
	assert_count++
	
	assert err.message.contains('email')
	assert_count++
	
	assert err.message.contains('test@example.com')
	assert_count++
	
	assert err.context['resource'] == 'User'
	assert_count++
	
	assert err.context['field'] == 'email'
	assert_count++
	
	assert err.context['value'] == 'test@example.com'
	assert_count++
	
	println('test_already_exists_error: ${assert_count} assertions passed')
}

fn test_internal_error_msg() {
	mut assert_count := 0
	
	err := internal_error_msg('System failure')
	
	assert err.code == .internal_error
	assert_count++
	
	assert err.message == 'System failure'
	assert_count++
	
	println('test_internal_error_msg: ${assert_count} assertions passed')
}

fn test_timeout_error() {
	mut assert_count := 0
	
	err := timeout_error('api_call', 5000)
	
	assert err.code == .timeout_error
	assert_count++
	
	assert err.message.contains('api_call')
	assert_count++
	
	assert err.message.contains('5000')
	assert_count++
	
	assert err.context['operation'] == 'api_call'
	assert_count++
	
	assert err.context['timeout_ms'] == '5000'
	assert_count++
	
	println('test_timeout_error: ${assert_count} assertions passed')
}

fn test_permission_error() {
	mut assert_count := 0
	
	err := permission_error('admin_panel', 'access')
	
	assert err.code == .permission_denied
	assert_count++
	
	assert err.message.contains('admin_panel')
	assert_count++
	
	assert err.message.contains('access')
	assert_count++
	
	assert err.context['resource'] == 'admin_panel'
	assert_count++
	
	assert err.context['action'] == 'access'
	assert_count++
	
	println('test_permission_error: ${assert_count} assertions passed')
}

// ============================================================================
// Error Analysis Tests
// ============================================================================

fn test_is_critical() {
	mut assert_count := 0
	
	critical_err := new(.db_connection_failed, 'DB down')
	assert is_critical(critical_err) == true
	assert_count++
	
	critical_err2 := new(.internal_error, 'System crash')
	assert is_critical(critical_err2) == true
	assert_count++
	
	non_critical := new(.validation_failed, 'Bad input')
	assert is_critical(non_critical) == false
	assert_count++
	
	println('test_is_critical: ${assert_count} assertions passed')
}

fn test_is_warning() {
	mut assert_count := 0
	
	warning_err := new(.validation_failed, 'Invalid')
	assert is_warning(warning_err) == true
	assert_count++
	
	warning_err2 := new(.config_not_found, 'Missing')
	assert is_warning(warning_err2) == true
	assert_count++
	
	non_warning := new(.internal_error, 'Crash')
	assert is_warning(non_warning) == false
	assert_count++
	
	println('test_is_warning: ${assert_count} assertions passed')
}

fn test_get_error_category() {
	mut assert_count := 0
	
	db_err := new(.db_query_failed, 'Query failed')
	assert get_error_category(db_err) == 'Database Error'
	assert_count++
	
	config_err := new(.config_invalid, 'Bad config')
	assert get_error_category(config_err) == 'Configuration Error'
	assert_count++
	
	validation_err := new(.validation_failed, 'Invalid')
	assert get_error_category(validation_err) == 'Validation Error'
	assert_count++
	
	not_found_err := new(.resource_not_found, 'Missing')
	assert get_error_category(not_found_err) == 'Not Found Error'
	assert_count++
	
	system_err := new(.internal_error, 'Crash')
	assert get_error_category(system_err) == 'System Error'
	assert_count++
	
	println('test_get_error_category: ${assert_count} assertions passed')
}

// ============================================================================
// Serialization Tests
// ============================================================================

fn test_to_json() {
	mut assert_count := 0
	
	err := new(.validation_failed, 'Test')
	json_str := to_json(err)
	
	assert json_str.contains('validation_failed')
	assert_count++
	
	assert json_str.contains('Test')
	assert_count++
	
	assert json_str.contains('backend')
	assert_count++
	
	println('test_to_json: ${assert_count} assertions passed')
}

fn test_to_response() {
	mut assert_count := 0
	
	err := new(.internal_error, 'Server error')
	response := to_response(err)
	
	assert response.contains('"success":false')
	assert_count++
	
	assert response.contains('"error"')
	assert_count++
	
	assert response.contains('internal_error')
	assert_count++
	
	println('test_to_response: ${assert_count} assertions passed')
}

fn test_from_json() {
	mut assert_count := 0
	
	json_str := '{"code":4001,"message":"Test error","details":"Details here","field":"email","cause":"Root cause","timestamp":12345,"source":"test","context":{}}'
	
	err := from_json(json_str) or {
		assert false
		return
	}
	
	assert err.code == .validation_failed
	assert_count++
	
	assert err.message == 'Test error'
	assert_count++
	
	assert err.details == 'Details here'
	assert_count++
	
	assert err.field == 'email'
	assert_count++
	
	println('test_from_json: ${assert_count} assertions passed')
}

fn test_from_json_invalid() {
	mut assert_count := 0
	
	invalid_json := 'not valid json'
	
	err := from_json(invalid_json) or {
		assert true  // Expected to fail
		assert_count++
		return
	}
	
	// Should not reach here
	assert false
	assert_count++
	
	println('test_from_json_invalid: ${assert_count} assertions passed')
}

// ============================================================================
// JSON Helper Tests
// ============================================================================

fn test_ok_json() {
	mut assert_count := 0
	
	response := ok_json('{"data":"test"}')
	
	assert response.contains('"success":true')
	assert_count++
	
	assert response.contains('"data":{"data":"test"}')
	assert_count++
	
	assert response.contains('"error":null')
	assert_count++
	
	println('test_ok_json: ${assert_count} assertions passed')
}

fn test_err_json() {
	mut assert_count := 0
	
	err := new(.unknown, 'Error occurred')
	response := err_json(err)
	
	assert response.contains('"success":false')
	assert_count++
	
	assert response.contains('unknown')
	assert_count++
	
	assert response.contains('Error occurred')
	assert_count++
	
	println('test_err_json: ${assert_count} assertions passed')
}

// ============================================================================
// Test Runner
// ============================================================================

fn test_all() {
	// Error creation tests
	test_error_new()
	test_error_with_details()
	test_error_with_field()
	test_error_with_context()
	
	// Specific error constructors
	test_db_error()
	test_validation_error()
	test_not_found_error()
	test_already_exists_error()
	test_internal_error_msg()
	test_timeout_error()
	test_permission_error()
	
	// Error analysis
	test_is_critical()
	test_is_warning()
	test_get_error_category()
	
	// Serialization
	test_to_json()
	test_to_response()
	test_from_json()
	test_from_json_invalid()
	
	// JSON helpers
	test_ok_json()
	test_err_json()
}
