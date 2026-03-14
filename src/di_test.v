module di

import time

// ==================== DI Container Tests ====================

fn test_new_container() {
	println('Testing: test_new_container')
	
	c := new_container()
	
	assert c.descriptors.len == 0, 'New container should have no descriptors'
	assert c.scopes.len == 0, 'New container should have no custom scopes'
	assert c.default_scope != 0, 'Default scope should exist'
	assert c.active_scope != 0, 'Active scope should exist'
	
	println('  ✓ PASSED: test_new_container')
}

fn test_register_singleton() {
	println('Testing: test_register_singleton')
	
	mut c := new_container()
	
	// Register a singleton
	instance := 42
	result := c.register_singleton('test_service', instance)
	
	assert result.success == true, 'Registration should succeed'
	assert result.error == '', 'Error should be empty'
	assert c.has('test_service') == true, 'Service should exist'
	
	// Try to register duplicate
	result2 := c.register_singleton('test_service', 100)
	assert result2.success == false, 'Duplicate registration should fail'
	
	println('  ✓ PASSED: test_register_singleton')
}

fn test_register_singleton_fn() {
	println('Testing: test_register_singleton_fn')
	
	mut c := new_container()
	
	// Register with factory
	result := c.register_singleton_fn('factory_service', fn () voidptr {
		return 123
	})
	
	assert result.success == true, 'Factory registration should succeed'
	assert c.has('factory_service') == true, 'Factory service should exist'
	
	// Resolve should call factory
	instance := c.resolve('factory_service') or {
		assert false, 'Resolution should succeed'
		return
	}
	
	assert instance == 123, 'Factory should return correct value'
	
	// Second resolve should return cached instance
	instance2 := c.resolve('factory_service') or {
		assert false, 'Second resolution should succeed'
		return
	}
	
	assert instance2 == 123, 'Cached instance should match'
	
	println('  ✓ PASSED: test_register_singleton_fn')
}

fn test_register_transient() {
	println('Testing: test_register_transient')
	
	mut c := new_container()
	
	mut counter := 0
	result := c.register_transient('counter_service', fn () voidptr {
		counter++
		return counter
	})
	
	assert result.success == true, 'Transient registration should succeed'
	
	// Each resolve should create new instance
	instance1 := c.resolve('counter_service') or {
		assert false, 'First resolution should succeed'
		return
	}
	
	instance2 := c.resolve('counter_service') or {
		assert false, 'Second resolution should succeed'
		return
	}
	
	instance3 := c.resolve('counter_service') or {
		assert false, 'Third resolution should succeed'
		return
	}
	
	assert instance1 != instance2, 'Transient instances should be different'
	assert instance2 != instance3, 'Transient instances should be different'
	assert counter == 3, 'Factory should be called 3 times'
	
	println('  ✓ PASSED: test_register_transient')
}

fn test_register_scoped() {
	println('Testing: test_register_scoped')
	
	mut c := new_container()
	
	mut counter := 0
	result := c.register_scoped('scoped_service', fn () voidptr {
		counter++
		return counter
	})
	
	assert result.success == true, 'Scoped registration should succeed'
	
	// First resolve in default scope
	instance1 := c.resolve('scoped_service') or {
		assert false, 'First resolution should succeed'
		return
	}
	
	// Second resolve in same scope should return cached
	instance2 := c.resolve('scoped_service') or {
		assert false, 'Second resolution should succeed'
		return
	}
	
	assert instance1 == instance2, 'Scoped instances in same scope should match'
	
	// Create new scope
	c.create_scope('scope1')
	c.use_scope('scope1')
	
	instance3 := c.resolve('scoped_service') or {
		assert false, 'Third resolution should succeed'
		return
	}
	
	assert instance2 != instance3, 'Scoped instances in different scopes should differ'
	
	// Back to default scope
	c.reset_scope()
	instance4 := c.resolve('scoped_service') or {
		assert false, 'Fourth resolution should succeed'
		return
	}
	
	assert instance1 == instance4, 'Default scope instance should match'
	
	println('  ✓ PASSED: test_register_scoped')
}

fn test_resolve_nonexistent() {
	println('Testing: test_resolve_nonexistent')
	
	c := new_container()
	
	result := c.resolve('nonexistent')
	assert result is error, 'Resolving nonexistent service should fail'
	
	println('  ✓ PASSED: test_resolve_nonexistent')
}

fn test_scope_management() {
	println('Testing: test_scope_management')
	
	mut c := new_container()
	
	// Create scope
	scope := c.create_scope('test_scope')
	assert scope != 0, 'Scope should be created'
	assert scope.id == 'test_scope', 'Scope ID should match'
	
	// Use scope
	success := c.use_scope('test_scope')
	assert success == true, 'Should switch to scope'
	
	// Dispose scope
	success = c.dispose_scope('test_scope')
	assert success == true, 'Should dispose scope'
	
	// Try to dispose again
	success = c.dispose_scope('test_scope')
	assert success == false, 'Should fail to dispose already disposed scope'
	
	println('  ✓ PASSED: test_scope_management')
}

fn test_container_dispose() {
	println('Testing: test_container_dispose')
	
	mut c := new_container()
	
	mut disposed := false
	c.register_singleton_fn('disposable', fn () voidptr {
		return 1
	})
	
	c.dispose()
	
	assert c.descriptors.len == 0, 'Descriptors should be cleared'
	
	println('  ✓ PASSED: test_container_dispose')
}

fn test_get_service_info() {
	println('Testing: test_get_service_info')
	
	mut c := new_container()
	
	c.register_singleton_fn('test', fn () voidptr {
		return 1
	})
	
	info := c.get_service_info('test') or {
		assert false, 'Service info should exist'
		return
	}
	
	assert info.name == 'test', 'Name should match'
	assert info.lifecycle == .singleton, 'Lifecycle should match'
	assert info.initialized == false, 'Should not be initialized yet'
	
	// Resolve to initialize
	c.resolve('test')
	
	info2 := c.get_service_info('test') or {
		assert false, 'Service info should exist'
		return
	}
	
	assert info2.initialized == true, 'Should be initialized after resolve'
	
	println('  ✓ PASSED: test_get_service_info')
}

fn test_get_registered_services() {
	println('Testing: test_get_registered_services')
	
	mut c := new_container()
	
	c.register_singleton_fn('service1', fn () voidptr { return 1 })
	c.register_singleton_fn('service2', fn () voidptr { return 2 })
	c.register_singleton_fn('service3', fn () voidptr { return 3 })
	
	names := c.get_registered_services()
	assert names.len == 3, 'Should have 3 registered services'
	
	println('  ✓ PASSED: test_get_registered_services')
}

fn test_lifecycle_enum() {
	println('Testing: test_lifecycle_enum')
	
	singleton := ServiceLifecycle.singleton
	transient := ServiceLifecycle.transient
	scoped := ServiceLifecycle.scoped
	
	assert singleton != transient, 'Singleton should differ from transient'
	assert transient != scoped, 'Transient should differ from scoped'
	assert singleton != scoped, 'Singleton should differ from scoped'
	
	println('  ✓ PASSED: test_lifecycle_enum')
}

// Run all DI tests
pub fn run_all_tests() {
	println('')
	println('========================================')
	println('Running DI Container Tests')
	println('========================================')
	println('')
	
	test_new_container()
	test_register_singleton()
	test_register_singleton_fn()
	test_register_transient()
	test_register_scoped()
	test_resolve_nonexistent()
	test_scope_management()
	test_container_dispose()
	test_get_service_info()
	test_get_registered_services()
	test_lifecycle_enum()
	
	println('')
	println('========================================')
	println('All DI Container Tests Passed!')
	println('========================================')
	println('')
}
