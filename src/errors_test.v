module main

// V Test file - run with: v test src/errors_test.v
// Comprehensive tests for error handling module

import errors

fn test_error_creation() {
	mut assert_count := 0

	// Create basic error
	err := errors.create('TEST_ERROR', 'Test error message')
	
	assert err.code == 'TEST_ERROR'
	assert_count++
	
	assert err.message == 'Test error message'
	assert_count++
	
	assert err.severity == errors.Severity.error
	assert_count++

	println('test_error_creation: ${assert_count} assertions passed')
}

fn test_error_with_context() {
	mut assert_count := 0

	// Create error with context
	mut ctx := map[string]string{}
	ctx['user_id'] = '123'
	ctx['action'] = 'delete'
	
	err := errors.create_with_context('PERMISSION_ERROR', 'Access denied', ctx)
	
	assert err.code == 'PERMISSION_ERROR'
	assert_count++
	
	assert err.context['user_id'] == '123'
	assert_count++
	
	assert err.context['action'] == 'delete'
	assert_count++

	println('test_error_with_context: ${assert_count} assertions passed')
}

fn test_error_severity_levels() {
	mut assert_count := 0

	// Test different severity levels
	err_info := errors.create('INFO', 'Informational')
	assert err_info.severity == errors.Severity.info
	assert_count++

	err_warn := errors.create('WARN', 'Warning')
	assert err_warn.severity == errors.Severity.warning
	assert_count++

	err_error := errors.create('ERROR', 'Error')
	assert err_error.severity == errors.Severity.error
	assert_count++

	err_critical := errors.create('CRITICAL', 'Critical')
	assert err_critical.severity == errors.Severity.critical
	assert_count++

	println('test_error_severity_levels: ${assert_count} assertions passed')
}

fn test_error_to_string() {
	mut assert_count := 0

	err := errors.create('TEST', 'Test message')
	str := err.to_string()
	
	assert str.contains('TEST')
	assert_count++
	
	assert str.contains('Test message')
	assert_count++

	println('test_error_to_string: ${assert_count} assertions passed')
}

fn test_error_wrap() {
	mut assert_count := 0

	original := errors.create('ORIGINAL', 'Original error')
	wrapped := errors.wrap(original, 'WRAPPED', 'Wrapped with more context')
	
	assert wrapped.code == 'WRAPPED'
	assert_count++
	
	assert wrapped.cause != 0
	assert_count++
	
	assert wrapped.cause.code == 'ORIGINAL'
	assert_count++

	println('test_error_wrap: ${assert_count} assertions passed')
}

fn test_error_is_code() {
	mut assert_count := 0

	err := errors.create('SPECIFIC_ERROR', 'Message')
	
	assert errors.is_code(err, 'SPECIFIC_ERROR') == true
	assert_count++
	
	assert errors.is_code(err, 'OTHER_ERROR') == false
	assert_count++

	println('test_error_is_code: ${assert_count} assertions passed')
}

fn test_error_chain() {
	mut assert_count := 0

	// Create error chain
	err1 := errors.create('ROOT', 'Root cause')
	err2 := errors.wrap(err1, 'LEVEL1', 'First wrap')
	err3 := errors.wrap(err2, 'LEVEL2', 'Second wrap')
	
	// Find root cause
	root := errors.get_root_cause(err3)
	assert root.code == 'ROOT'
	assert_count++
	
	// Check chain length
	chain := errors.get_chain(err3)
	assert chain.len == 3
	assert_count++

	println('test_error_chain: ${assert_count} assertions passed')
}

fn test_error_recovery() {
	mut assert_count := 0

	// Test recoverable error
	err := errors.create_recoverable('RECOVERABLE', 'Can be recovered', fn () {
		// Recovery action
	})
	
	assert err.recoverable == true
	assert_count++
	
	assert err.code == 'RECOVERABLE'
	assert_count++

	println('test_error_recovery: ${assert_count} assertions passed')
}

fn test_error_batch() {
	mut assert_count := 0

	// Create multiple errors
	mut errs := []errors.Error{}
	errs << errors.create('ERR1', 'Error 1')
	errs << errors.create('ERR2', 'Error 2')
	errs << errors.create('ERR3', 'Error 3')
	
	// Create batch error
	batch := errors.create_batch('BATCH', 'Multiple errors', errs)
	
	assert batch.code == 'BATCH'
	assert_count++
	
	assert batch.errors.len == 3
	assert_count++
	
	// Check if has specific error
	assert errors.has_code(batch, 'ERR2') == true
	assert_count++

	println('test_error_batch: ${assert_count} assertions passed')
}

fn test_error_utils() {
	mut assert_count := 0

	// Test is_nil
	nil_err := errors.Error{}
	assert errors.is_nil(nil_err) == true
	assert_count++

	// Test is_not_nil
	err := errors.create('TEST', 'Message')
	assert errors.is_not_nil(err) == true
	assert_count++

	// Test get_message
	msg := errors.get_message(err)
	assert msg == 'Message'
	assert_count++

	// Test get_code
	code := errors.get_code(err)
	assert code == 'TEST'
	assert_count++

	println('test_error_utils: ${assert_count} assertions passed')
}

fn test_all() {
	test_error_creation()
	test_error_with_context()
	test_error_severity_levels()
	test_error_to_string()
	test_error_wrap()
	test_error_is_code()
	test_error_chain()
	test_error_recovery()
	test_error_batch()
	test_error_utils()
}
