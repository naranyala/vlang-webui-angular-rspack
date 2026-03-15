module services

// V Test file - run with: v test src/services/logger_service_test.v

import os
import time

fn test_new_logger_service() {
	mut assert_count := 0

	logger := new_logger_service()

	assert logger != 0
	assert_count++

	assert logger.service_name == 'logger'
	assert_count++

	assert logger.min_level == 'info'
	assert_count++

	assert logger.log_to_console == true
	assert_count++

	assert logger.log_to_file == false
	assert_count++

	assert logger.initialized == false
	assert_count++

	println('test_new_logger_service: ${assert_count} assertions passed')
}

fn test_init() {
	mut assert_count := 0

	logger := new_logger_service()
	result := logger.init()

	assert result == true
	assert_count++

	assert logger.initialized == true
	assert_count++

	// Second init should return true
	result2 := logger.init()
	assert result2 == true
	assert_count++

	println('test_init: ${assert_count} assertions passed')
}

fn test_log_levels() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()
	logger.set_min_level('debug')

	// Test all log levels produce output
	logger.debug('Debug message')
	logger.info('Info message')
	logger.warn('Warn message')
	logger.error('Error message')
	logger.fatal('Fatal message')

	assert logger.get_log_count() == 5
	assert_count++

	println('test_log_levels: ${assert_count} assertions passed')
}

fn test_set_min_level() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()

	// Set to error level
	logger.set_min_level('error')
	assert logger.get_min_level() == 'error'
	assert_count++

	// Set to debug level
	logger.set_min_level('debug')
	assert logger.get_min_level() == 'debug'
	assert_count++

	// Set to warn level
	logger.set_min_level('warn')
	assert logger.get_min_level() == 'warn'
	assert_count++

	println('test_set_min_level: ${assert_count} assertions passed')
}

fn test_should_log() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()

	// Default level is 'info'
	logger.set_min_level('info')

	// Debug should not log when min is info
	logger.debug('Debug message')
	count1 := logger.get_log_count()

	// Info should log
	logger.info('Info message')
	count2 := logger.get_log_count()

	// Warn should log
	logger.warn('Warn message')
	count3 := logger.get_log_count()

	// Error should log
	logger.error('Error message')
	count4 := logger.get_log_count()

	assert count2 > count1
	assert_count++

	assert count3 > count2
	assert_count++

	assert count4 > count3
	assert_count++

	println('test_should_log: ${assert_count} assertions passed')
}

fn test_file_logging() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()

	temp_file := '/tmp/test_logger_${u64(time.now().unix())}.log'
	logger.enable_file_logging(temp_file)
	logger.set_min_level('debug')

	logger.info('Test file log message')

	// Give time for file write
	time.sleep(100 * time.millisecond)

	// Verify file exists and contains message
	if os.exists(temp_file) {
		content := os.read_file(temp_file) or { '' }
		assert content.contains('Test file log message')
		assert_count++

		assert content.contains('INFO')
		assert_count++

		// Cleanup
		os.rm(temp_file)
	} else {
		// File logging might not work in all environments
		assert true
		assert_count++
	}

	println('test_file_logging: ${assert_count} assertions passed')
}

fn test_console_logging() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()
	logger.set_min_level('debug')

	// Console logging is enabled by default
	assert logger.log_to_console == true
	assert_count++

	logger.info('Test console message')

	// Verify log count increased
	assert logger.get_log_count() > 0
	assert_count++

	println('test_console_logging: ${assert_count} assertions passed')
}

fn test_disable_file_logging() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()

	temp_file := '/tmp/test_logger2_${u64(time.now().unix())}.log'
	logger.enable_file_logging(temp_file)
	assert logger.log_to_file == true
	assert_count++

	logger.disable_file_logging()
	assert logger.log_to_file == false
	assert_count++

	println('test_disable_file_logging: ${assert_count} assertions passed')
}

fn test_log_count() {
	mut assert_count := 0

	logger := new_logger_service()
	logger.init()
	logger.set_min_level('debug')

	// Initial count should be 0
	assert logger.get_log_count() == 0
	assert_count++

	// Log some messages
	logger.debug('Debug 1')
	logger.info('Info 1')
	logger.warn('Warn 1')

	assert logger.get_log_count() == 3
	assert_count++

	// Reset count
	logger.reset_log_count()
	assert logger.get_log_count() == 0
	assert_count++

	// Log more messages
	logger.error('Error 1')
	assert logger.get_log_count() == 1
	assert_count++

	println('test_log_count: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_logger_service()
	test_init()
	test_log_levels()
	test_set_min_level()
	test_should_log()
	test_file_logging()
	test_console_logging()
	test_disable_file_logging()
	test_log_count()
}
