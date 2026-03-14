module di

import time

// ServiceLifecycle defines how services are instantiated
pub enum ServiceLifecycle {
	singleton   // Single instance for entire application
	transient   // New instance each time
	scoped      // Single instance per scope (request, session, etc.)
}

// ServiceDescriptor holds metadata about a registered service
@[heap]
pub struct ServiceDescriptor {
pub mut:
	name          string
	lifecycle     ServiceLifecycle
	instance      voidptr
	factory       fn () voidptr = unsafe { nil }
	initialized   bool
	created_at    u64
}

// ServiceScope represents a scoped context (e.g., request, session)
@[heap]
pub struct ServiceScope {
pub mut:
	id              string
	created_at      u64
	services        map[string]voidptr
	disposed        bool
	parent          &Container
}

// Container is the main DI container
@[heap]
pub struct Container {
pub mut:
	descriptors     map[string]ServiceDescriptor
	scopes          map[string]&ServiceScope
	active_scope    &ServiceScope
	default_scope   &ServiceScope
	is_building     bool
}

// ServiceRegistryResult tracks registration success
pub struct ServiceRegistryResult {
	success bool
	error   string
}

// NewContainer creates a new DI container
pub fn new_container() Container {
	mut c := Container{
		descriptors: map[string]ServiceDescriptor{}
		scopes: map[string]&ServiceScope{}
		is_building: false
		active_scope: unsafe { nil }
		default_scope: unsafe { nil }
	}
	
	// Create default scope
	mut default_scope := &ServiceScope{
		id: 'default'
		created_at: u64(time.now().unix())
		services: map[string]voidptr{}
		disposed: false
		parent: &c
	}
	c.default_scope = default_scope
	c.active_scope = default_scope
	
	return c
}

// ==================== Registration Methods ====================

// RegisterSingleton registers a service as a singleton
pub fn (mut c Container) register_singleton(name string, instance voidptr) ServiceRegistryResult {
	if name in c.descriptors {
		return ServiceRegistryResult{
			success: false
			error: 'Service "${name}" is already registered'
		}
	}
	
	c.descriptors[name] = ServiceDescriptor{
		name: name
		lifecycle: .singleton
		instance: instance
		initialized: true
		created_at: u64(time.now().unix())
		factory: fn () voidptr { return 0 }
	}
	
	return ServiceRegistryResult{
		success: true
		error: ''
	}
}

// RegisterSingletonFn registers a singleton with a factory function
pub fn (mut c Container) register_singleton_fn(name string, factory fn () voidptr) ServiceRegistryResult {
	if name in c.descriptors {
		return ServiceRegistryResult{
			success: false
			error: 'Service "${name}" is already registered'
		}
	}
	
	c.descriptors[name] = ServiceDescriptor{
		name: name
		lifecycle: .singleton
		instance: 0
		factory: factory
		initialized: false
		created_at: u64(time.now().unix())
	}
	
	return ServiceRegistryResult{
		success: true
		error: ''
	}
}

// RegisterTransient registers a service as transient (new instance each time)
pub fn (mut c Container) register_transient(name string, factory fn () voidptr) ServiceRegistryResult {
	if name in c.descriptors {
		return ServiceRegistryResult{
			success: false
			error: 'Service "${name}" is already registered'
		}
	}
	
	c.descriptors[name] = ServiceDescriptor{
		name: name
		lifecycle: .transient
		instance: 0
		factory: factory
		initialized: false
		created_at: u64(time.now().unix())
	}
	
	return ServiceRegistryResult{
		success: true
		error: ''
	}
}

// RegisterScoped registers a service as scoped (one instance per scope)
pub fn (mut c Container) register_scoped(name string, factory fn () voidptr) ServiceRegistryResult {
	if name in c.descriptors {
		return ServiceRegistryResult{
			success: false
			error: 'Service "${name}" is already registered'
		}
	}
	
	c.descriptors[name] = ServiceDescriptor{
		name: name
		lifecycle: .scoped
		instance: 0
		factory: factory
		initialized: false
		created_at: u64(time.now().unix())
	}
	
	return ServiceRegistryResult{
		success: true
		error: ''
	}
}

// ==================== Resolution Methods ====================

// Resolve gets a service instance by name
pub fn (mut c Container) resolve(name string) !voidptr {
	descriptor := c.descriptors[name] or {
		return error('Service "${name}" is not registered')
	}
	
	match descriptor.lifecycle {
		.singleton {
			if !descriptor.initialized {
				// Create instance using factory
				instance := descriptor.factory()
				unsafe {
					c.descriptors[name].instance = instance
					c.descriptors[name].initialized = true
				}
				return instance
			}
			return descriptor.instance
		}
		.transient {
			return descriptor.factory()
		}
		.scoped {
			// Check scope cache first
			cached := unsafe { c.active_scope.services[name] }
			if cached != 0 {
				return cached
			}
			
			instance := descriptor.factory()
			unsafe {
				c.active_scope.services[name] = instance
			}
			return instance
		}
	}
}

// Has checks if a service is registered
pub fn (c Container) has(name string) bool {
	return name in c.descriptors
}

// ==================== Scope Management ====================

// CreateScope creates a new service scope
pub fn (mut c Container) create_scope(scope_id string) &ServiceScope {
	mut scope := &ServiceScope{
		id: scope_id
		created_at: u64(time.now().unix())
		services: map[string]voidptr{}
		disposed: false
		parent: &c
	}
	c.scopes[scope_id] = scope
	return scope
}

// UseScope sets the active scope
pub fn (mut c Container) use_scope(scope_id string) bool {
	scope := c.scopes[scope_id] or {
		return false
	}
	c.active_scope = scope
	return true
}

// ResetScope resets to default scope
pub fn (mut c Container) reset_scope() {
	c.active_scope = c.default_scope
}

// DisposeScope disposes a scope and its services
pub fn (mut c Container) dispose_scope(scope_id string) bool {
	mut scope := c.scopes[scope_id] or {
		return false
	}
	
	if scope.disposed {
		return true
	}
	
	scope.disposed = true
	c.scopes.delete(scope_id)
	
	if c.active_scope.id == scope_id {
		c.reset_scope()
	}
	
	return true
}

// ==================== Container Lifecycle ====================

// Dispose disposes the entire container
pub fn (mut c Container) dispose() {
	// Dispose all scopes first
	for scope_id, _ in c.scopes {
		c.dispose_scope(scope_id)
	}
	
	// Clear descriptors
	c.descriptors = map[string]ServiceDescriptor{}
}

// GetServiceInfo returns information about a registered service
pub fn (c Container) get_service_info(name string) !ServiceDescriptor {
	return unsafe { c.descriptors[name] }
}

// GetRegisteredServices returns list of all registered service names
pub fn (c Container) get_registered_services() []string {
	mut names := []string{}
	for name, _ in c.descriptors {
		names << name
	}
	return names
}

// GetScopeInfo returns information about scopes
pub fn (c Container) get_scope_info() map[string][]string {
	mut info := map[string][]string{}
	
	for scope_id, scope in c.scopes {
		mut services := []string{}
		for name, _ in scope.services {
			services << name
		}
		info[scope_id] = services
	}
	
	return info
}

// ==================== Service Scope Methods ====================

// GetScoped resolves a service from the scope
pub fn (mut s ServiceScope) resolve(name string) !voidptr {
	// Check scope cache
	instance := unsafe { s.services[name] }
	if instance != 0 {
		return instance
	}
	
	// Fall back to parent container
	return s.parent.resolve(name)
}

// Dispose disposes the scope
pub fn (mut s ServiceScope) dispose() {
	s.disposed = true
}
