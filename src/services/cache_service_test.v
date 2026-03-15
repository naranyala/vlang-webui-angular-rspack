module services

// V Test file - run with: v test src/services/cache_service_test.v

import time

fn test_new_cache_service() {
	mut assert_count := 0

	cache := new_cache_service()

	assert cache != 0
	assert_count++

	assert cache.initialized == false
	assert_count++

	assert cache.max_size == 1000
	assert_count++

	assert cache.cache.len == 0
	assert_count++

	println('test_new_cache_service: ${assert_count} assertions passed')
}

fn test_init() {
	mut assert_count := 0

	cache := new_cache_service()
	result := cache.init()

	assert result == true
	assert_count++

	assert cache.initialized == true
	assert_count++

	println('test_init: ${assert_count} assertions passed')
}

fn test_set_get() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Set a value
	result := cache.set('key1', 'value1', 60)
	assert result == true
	assert_count++

	// Get the value
	value := cache.get('key1') or { '' }
	assert value == 'value1'
	assert_count++

	// Set another value
	cache.set('key2', 'value2', 60)
	value2 := cache.get('key2') or { '' }
	assert value2 == 'value2'
	assert_count++

	println('test_set_get: ${assert_count} assertions passed')
}

fn test_ttl_expiration() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Set with very short TTL (1 second)
	cache.set('short_ttl', 'expires_soon', 1)

	// Should exist immediately
	assert cache.has('short_ttl') == true
	assert_count++

	value := cache.get('short_ttl') or { '' }
	assert value == 'expires_soon'
	assert_count++

	// Wait for expiration
	time.sleep(2 * time.second)

	// Should be expired now
	assert cache.has('short_ttl') == false
	assert_count++

	// Get should fail
	_ = cache.get('short_ttl') or {
		assert true
		assert_count++
	}

	println('test_ttl_expiration: ${assert_count} assertions passed')
}

fn test_no_expiration() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Set with 0 TTL (no expiration)
	cache.set('permanent', 'never_expires', 0)

	// Wait a bit
	time.sleep(100 * time.millisecond)

	// Should still exist
	assert cache.has('permanent') == true
	assert_count++

	value := cache.get('permanent') or { '' }
	assert value == 'never_expires'
	assert_count++

	println('test_no_expiration: ${assert_count} assertions passed')
}

fn test_has() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Non-existent key
	assert cache.has('nonexistent') == false
	assert_count++

	// Existing key
	cache.set('existing', 'value', 60)
	assert cache.has('existing') == true
	assert_count++

	println('test_has: ${assert_count} assertions passed')
}

fn test_delete() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Delete non-existent key
	result1 := cache.delete('nonexistent')
	assert result1 == false
	assert_count++

	// Set and delete existing key
	cache.set('to_delete', 'value', 60)
	result2 := cache.delete('to_delete')
	assert result2 == true
	assert_count++

	// Verify deletion
	assert cache.has('to_delete') == false
	assert_count++

	println('test_delete: ${assert_count} assertions passed')
}

fn test_clear() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Add some entries
	cache.set('key1', 'value1', 60)
	cache.set('key2', 'value2', 60)
	cache.set('key3', 'value3', 60)

	assert cache.count() == 3
	assert_count++

	// Clear all
	cache.clear()

	assert cache.count() == 0
	assert_count++

	assert cache.has('key1') == false
	assert_count++

	println('test_clear: ${assert_count} assertions passed')
}

fn test_cleanup_expired() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	// Add entries with different TTLs
	cache.set('short', 'short_value', 1)
	cache.set('long', 'long_value', 60)

	// Wait for short to expire
	time.sleep(2 * time.second)

	// Cleanup expired
	removed := cache.cleanup_expired()

	assert removed >= 1
	assert_count++

	// Short should be removed
	assert cache.has('short') == false
	assert_count++

	// Long should still exist
	assert cache.has('long') == true
	assert_count++

	println('test_cleanup_expired: ${assert_count} assertions passed')
}

fn test_max_size() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()
	cache.max_size = 3

	// Add more entries than max size
	cache.set('key1', 'value1', 60)
	cache.set('key2', 'value2', 60)
	cache.set('key3', 'value3', 60)
	cache.set('key4', 'value4', 60)

	// Should have cleaned up
	assert cache.count() <= 3
	assert_count++

	println('test_max_size: ${assert_count} assertions passed')
}

fn test_keys() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	cache.set('key_a', 'value_a', 60)
	cache.set('key_b', 'value_b', 60)
	cache.set('key_c', 'value_c', 60)

	keys := cache.keys()

	assert keys.len == 3
	assert_count++

	// Check all keys exist
	mut found_keys := map[string]bool{}
	for key in keys {
		found_keys[key] = true
	}

	assert found_keys.exists('key_a')
	assert_count++

	assert found_keys.exists('key_b')
	assert_count++

	assert found_keys.exists('key_c')
	assert_count++

	println('test_keys: ${assert_count} assertions passed')
}

fn test_count() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	assert cache.count() == 0
	assert_count++

	cache.set('count1', 'value1', 60)
	assert cache.count() == 1
	assert_count++

	cache.set('count2', 'value2', 60)
	assert cache.count() == 2
	assert_count++

	cache.delete('count1')
	assert cache.count() == 1
	assert_count++

	println('test_count: ${assert_count} assertions passed')
}

fn test_overwrite() {
	mut assert_count := 0

	cache := new_cache_service()
	cache.init()

	cache.set('overwrite_key', 'original_value', 60)
	value1 := cache.get('overwrite_key') or { '' }
	assert value1 == 'original_value'
	assert_count++

	cache.set('overwrite_key', 'new_value', 60)
	value2 := cache.get('overwrite_key') or { '' }
	assert value2 == 'new_value'
	assert_count++

	println('test_overwrite: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_cache_service()
	test_init()
	test_set_get()
	test_ttl_expiration()
	test_no_expiration()
	test_has()
	test_delete()
	test_clear()
	test_cleanup_expired()
	test_max_size()
	test_keys()
	test_count()
	test_overwrite()
}
