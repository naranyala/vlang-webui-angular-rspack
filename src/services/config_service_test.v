module services

// V Test file - run with: v test src/services/config_service_test.v

import os
import time

fn test_new_config_service() {
	mut assert_count := 0

	config := new_config_service()

	assert config != 0
	assert_count++

	assert config.env_prefix == 'APP_'
	assert_count++

	assert config.initialized == false
	assert_count++

	assert config.config.len == 0
	assert_count++

	println('test_new_config_service: ${assert_count} assertions passed')
}

fn test_init() {
	mut assert_count := 0

	config := new_config_service()
	result := config.init()

	assert result == true
	assert_count++

	assert config.initialized == true
	assert_count++

	// Second init should return true
	result2 := config.init()
	assert result2 == true
	assert_count++

	println('test_init: ${assert_count} assertions passed')
}

fn test_get_string() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('test_key', 'test_value')
	value := config.get_string('test_key', 'default')

	assert value == 'test_value'
	assert_count++

	// Test default value
	default_value := config.get_string('missing_key', 'default_value')
	assert default_value == 'default_value'
	assert_count++

	println('test_get_string: ${assert_count} assertions passed')
}

fn test_get_int() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('int_key', '42')
	value := config.get_int('int_key', 0)

	assert value == 42
	assert_count++

	// Test default value
	default_value := config.get_int('missing_key', 100)
	assert default_value == 100
	assert_count++

	println('test_get_int: ${assert_count} assertions passed')
}

fn test_get_bool() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	// Test true values
	config.set('bool_key1', 'true')
	assert config.get_bool('bool_key1', false) == true
	assert_count++

	config.set('bool_key2', '1')
	assert config.get_bool('bool_key2', false) == true
	assert_count++

	config.set('bool_key3', 'yes')
	assert config.get_bool('bool_key3', false) == true
	assert_count++

	// Test false values
	config.set('bool_key4', 'false')
	assert config.get_bool('bool_key4', true) == false
	assert_count++

	// Test default value
	default_value := config.get_bool('missing_key', true)
	assert default_value == true
	assert_count++

	println('test_get_bool: ${assert_count} assertions passed')
}

fn test_get_float() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('float_key', '3.14')
	value := config.get_float('float_key', 0.0)

	assert value == 3.14
	assert_count++

	// Test default value
	default_value := config.get_float('missing_key', 2.71)
	assert default_value == 2.71
	assert_count++

	println('test_get_float: ${assert_count} assertions passed')
}

fn test_set() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('new_key', 'new_value')
	value := config.get_string('new_key', '')

	assert value == 'new_value'
	assert_count++

	// Test overwrite
	config.set('new_key', 'updated_value')
	value2 := config.get_string('new_key', '')

	assert value2 == 'updated_value'
	assert_count++

	println('test_set: ${assert_count} assertions passed')
}

fn test_has() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	assert config.has('missing_key') == false
	assert_count++

	config.set('existing_key', 'value')
	assert config.has('existing_key') == true
	assert_count++

	println('test_has: ${assert_count} assertions passed')
}

fn test_load_from_env() {
	mut assert_count := 0

	config := new_config_service()
	config.env_prefix = 'TEST_CONFIG_'

	// Set a test environment variable
	os.putenv('TEST_CONFIG_TEST_KEY', 'test_value')
	os.putenv('TEST_CONFIG_ANOTHER_KEY', 'another_value')

	config.load_from_env()

	assert config.has('test_key') == true
	assert_count++

	assert config.get_string('test_key', '') == 'test_value'
	assert_count++

	assert config.has('another_key') == true
	assert_count++

	// Cleanup
	os.putenv('TEST_CONFIG_TEST_KEY', '')
	os.putenv('TEST_CONFIG_ANOTHER_KEY', '')

	println('test_load_from_env: ${assert_count} assertions passed')
}

fn test_load_from_file() {
	mut assert_count := 0

	config := new_config_service()

	// Create a temporary config file
	temp_file := '/tmp/test_config_${u64(time.now().unix())}.conf'
	content := '# Test Config\nkey1=value1\nkey2=value2\nkey3="quoted value"\n'
	os.write_file(temp_file, content) or {
		println('Failed to create temp config file')
		return
	}

	result := config.load_from_file(temp_file)
	assert result == true
	assert_count++

	assert config.has('key1') == true
	assert_count++

	assert config.get_string('key1', '') == 'value1'
	assert_count++

	assert config.get_string('key2', '') == 'value2'
	assert_count++

	assert config.get_string('key3', '') == 'quoted value'
	assert_count++

	// Cleanup
	os.rm(temp_file)

	println('test_load_from_file: ${assert_count} assertions passed')
}

fn test_save_to_file() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('save_key1', 'save_value1')
	config.set('save_key2', 'save_value2')

	temp_file := '/tmp/test_save_config_${u64(time.now().unix())}.conf'
	result := config.save_to_file(temp_file)

	assert result == true
	assert_count++

	// Verify file exists
	assert os.exists(temp_file) == true
	assert_count++

	// Read and verify content
	content := os.read_file(temp_file) or { '' }
	assert content.contains('save_key1=save_value1')
	assert_count++

	assert content.contains('save_key2=save_value2')
	assert_count++

	// Cleanup
	os.rm(temp_file)

	println('test_save_to_file: ${assert_count} assertions passed')
}

fn test_get_all() {
	mut assert_count := 0

	config := new_config_service()
	config.init()

	config.set('all_key1', 'all_value1')
	config.set('all_key2', 'all_value2')
	config.set('all_key3', 'all_value3')

	all := config.get_all()

	assert all.len == 3
	assert_count++

	assert all['all_key1'] == 'all_value1'
	assert_count++

	assert all['all_key2'] == 'all_value2'
	assert_count++

	assert all['all_key3'] == 'all_value3'
	assert_count++

	println('test_get_all: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_config_service()
	test_init()
	test_get_string()
	test_get_int()
	test_get_bool()
	test_get_float()
	test_set()
	test_has()
	test_load_from_env()
	test_load_from_file()
	test_save_to_file()
	test_get_all()
}
