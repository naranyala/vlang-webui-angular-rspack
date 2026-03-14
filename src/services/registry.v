module services

import di

// ServiceRegistry provides fluent API for service registration
pub struct ServiceRegistry {
pub mut:
	container   &di.Container
	registered  []string
}

// NewServiceRegistry creates a new service registry
pub fn new_service_registry(container &di.Container) &ServiceRegistry {
	return &ServiceRegistry{
		container: container
		registered: []string{}
	}
}

// ==================== Core Service Registration ====================

// RegisterConfigService registers the ConfigService as a singleton
pub fn (mut sr ServiceRegistry) register_config_service(config_path string) &ServiceRegistry {
	result := sr.container.register_singleton_fn('config', fn () voidptr {
		mut service := new_config_service()
		service.init()
		
		if config_path != '' {
			service.load_from_file(config_path)
		}
		
		return service
	})
	
	if result.success {
		sr.registered << 'config'
	}
	
	return sr
}

// RegisterLoggerService registers the LoggerService as a singleton
pub fn (mut sr ServiceRegistry) register_logger_service(min_level string) &ServiceRegistry {
	result := sr.container.register_singleton_fn('logger', fn () voidptr {
		mut service := new_logger_service()
		service.init()
		service.set_min_level(min_level)
		return service
	})
	
	if result.success {
		sr.registered << 'logger'
	}
	
	return sr
}

// RegisterCacheService registers the CacheService as a singleton
pub fn (mut sr ServiceRegistry) register_cache_service(max_size int) &ServiceRegistry {
	result := sr.container.register_singleton_fn('cache', fn () voidptr {
		mut service := new_cache_service()
		service.init()
		service.max_size = max_size
		return service
	})
	
	if result.success {
		sr.registered << 'cache'
	}
	
	return sr
}

// RegisterDatabaseService registers the DatabaseService as a singleton
pub fn (mut sr ServiceRegistry) register_database_service(connection_string string) &ServiceRegistry {
	result := sr.container.register_singleton_fn('database', fn () voidptr {
		mut service := new_database_service()
		service.init()
		service.set_connection_string(connection_string)
		service.connect()
		return service
	})
	
	if result.success {
		sr.registered << 'database'
	}
	
	return sr
}

// RegisterHttpClientService registers the HttpClientService as a singleton
pub fn (mut sr ServiceRegistry) register_http_client_service(base_url string, timeout_ms int) &ServiceRegistry {
	result := sr.container.register_singleton_fn('http_client', fn () voidptr {
		mut service := new_http_client_service()
		service.init()
		service.set_base_url(base_url)
		service.set_timeout(timeout_ms)
		return service
	})
	
	if result.success {
		sr.registered << 'http_client'
	}
	
	return sr
}

// ==================== Additional Service Registration ====================

// RegisterValidationService registers the ValidationService as a singleton
pub fn (mut sr ServiceRegistry) register_validation_service() &ServiceRegistry {
	result := sr.container.register_singleton_fn('validation', fn () voidptr {
		mut service := new_validation_service()
		service.init()
		return service
	})
	
	if result.success {
		sr.registered << 'validation'
	}
	
	return sr
}

// RegisterMetricsService registers the MetricsService as a singleton
pub fn (mut sr ServiceRegistry) register_metrics_service() &ServiceRegistry {
	result := sr.container.register_singleton_fn('metrics', fn () voidptr {
		mut service := new_metrics_service()
		service.init()
		return service
	})
	
	if result.success {
		sr.registered << 'metrics'
	}
	
	return sr
}

// RegisterHealthCheckService registers the HealthCheckService as a singleton
pub fn (mut sr ServiceRegistry) register_health_check_service() &ServiceRegistry {
	result := sr.container.register_singleton_fn('health_check', fn () voidptr {
		mut service := new_health_check_service()
		service.init()
		return service
	})
	
	if result.success {
		sr.registered << 'health_check'
	}
	
	return sr
}

// RegisterAuthService registers the AuthService as a singleton
pub fn (mut sr ServiceRegistry) register_auth_service(token_expiry_sec int) &ServiceRegistry {
	result := sr.container.register_singleton_fn('auth', fn () voidptr {
		mut service := new_auth_service()
		service.init()
		service.token_expiry_sec = token_expiry_sec
		return service
	})
	
	if result.success {
		sr.registered << 'auth'
	}
	
	return sr
}

// RegisterSystemInfoService registers the SystemInfoService as a singleton
pub fn (mut sr ServiceRegistry) register_system_info_service() &ServiceRegistry {
	result := sr.container.register_singleton_fn('system_info', fn () voidptr {
		mut service := new_system_info_service()
		service.init()
		return service
	})
	
	if result.success {
		sr.registered << 'system_info'
	}
	
	return sr
}

// ==================== Bulk Registration ====================

// RegisterAllCoreServices registers all core services with default configuration
pub fn (mut sr ServiceRegistry) register_all_core_services() &ServiceRegistry {
	sr.register_logger_service('info')
	sr.register_config_service('')
	sr.register_cache_service(1000)
	sr.register_validation_service()
	sr.register_metrics_service()
	sr.register_health_check_service()
	
	return sr
}

// RegisterAllServices registers all available services
pub fn (mut sr ServiceRegistry) register_all_services() &ServiceRegistry {
	sr.register_all_core_services()
	sr.register_http_client_service('', 30000)
	sr.register_auth_service(3600)
	sr.register_system_info_service()
	
	return sr
}

// ==================== Service Resolution Helpers ====================

// GetConfig resolves and casts to ConfigService
pub fn (sr ServiceRegistry) get_config() ?&ConfigService {
	instance := sr.container.resolve('config') or {
		return error('ConfigService not registered')
	}
	unsafe {
		return &ConfigService(instance)
	}
}

// GetLogger resolves and casts to LoggerService
pub fn (sr ServiceRegistry) get_logger() ?&LoggerService {
	instance := sr.container.resolve('logger') or {
		return error('LoggerService not registered')
	}
	unsafe {
		return &LoggerService(instance)
	}
}

// GetCache resolves and casts to CacheService
pub fn (sr ServiceRegistry) get_cache() ?&CacheService {
	instance := sr.container.resolve('cache') or {
		return error('CacheService not registered')
	}
	unsafe {
		return &CacheService(instance)
	}
}

// GetDatabase resolves and casts to DatabaseService
pub fn (sr ServiceRegistry) get_database() ?&DatabaseService {
	instance := sr.container.resolve('database') or {
		return error('DatabaseService not registered')
	}
	unsafe {
		return &DatabaseService(instance)
	}
}

// GetHttpClient resolves and casts to HttpClientService
pub fn (sr ServiceRegistry) get_http_client() ?&HttpClientService {
	instance := sr.container.resolve('http_client') or {
		return error('HttpClientService not registered')
	}
	unsafe {
		return &HttpClientService(instance)
	}
}

// GetValidation resolves and casts to ValidationService
pub fn (sr ServiceRegistry) get_validation() ?&ValidationService {
	instance := sr.container.resolve('validation') or {
		return error('ValidationService not registered')
	}
	unsafe {
		return &ValidationService(instance)
	}
}

// GetMetrics resolves and casts to MetricsService
pub fn (sr ServiceRegistry) get_metrics() ?&MetricsService {
	instance := sr.container.resolve('metrics') or {
		return error('MetricsService not registered')
	}
	unsafe {
		return &MetricsService(instance)
	}
}

// GetHealthCheck resolves and casts to HealthCheckService
pub fn (sr ServiceRegistry) get_health_check() ?&HealthCheckService {
	instance := sr.container.resolve('health_check') or {
		return error('HealthCheckService not registered')
	}
	unsafe {
		return &HealthCheckService(instance)
	}
}

// GetAuth resolves and casts to AuthService
pub fn (sr ServiceRegistry) get_auth() ?&AuthService {
	instance := sr.container.resolve('auth') or {
		return error('AuthService not registered')
	}
	unsafe {
		return &AuthService(instance)
	}
}

// GetSystemInfo resolves and casts to SystemInfoService
pub fn (sr ServiceRegistry) get_system_info() ?&SystemInfoService {
	instance := sr.container.resolve('system_info') or {
		return error('SystemInfoService not registered')
	}
	unsafe {
		return &SystemInfoService(instance)
	}
}

// ==================== Utility Methods ====================

// GetRegisteredServices returns list of registered service names
pub fn (sr ServiceRegistry) get_registered_services() []string {
	return sr.registered.clone()
}

// HasService checks if a service is registered
pub fn (sr ServiceRegistry) has_service(name string) bool {
	return sr.container.has(name)
}

// GetRegistrationCount returns number of registered services
pub fn (sr ServiceRegistry) get_registration_count() int {
	return sr.registered.len
}

// PrintRegisteredServices prints all registered services
pub fn (sr ServiceRegistry) print_registered_services() {
	println('Registered Services (${sr.registered.len}):')
	for service in sr.registered {
		println('  - ${service}')
	}
}

// Build finalizes the registry and returns the container
pub fn (sr ServiceRegistry) build() &di.Container {
	return sr.container
}

// ==================== Service Provider ====================

// ServiceProvider provides lazy service resolution
pub struct ServiceProvider {
pub mut:
	container &di.Container
	cache     map[string]voidptr
}

pub fn new_service_provider(container &di.Container) &ServiceProvider {
	return &ServiceProvider{
		container: container
		cache: map[string]voidptr{}
	}
}

pub fn (mut sp ServiceProvider) get(name string) ?voidptr {
	// Check cache first
	cached := sp.cache[name]
	if cached != 0 {
		return cached
	}
	
	// Resolve from container
	instance := sp.container.resolve(name) or {
		return error('Service "${name}" not found')
	}
	
	// Cache for singleton services
	descriptor := sp.container.get_service_info(name) or {
		return instance
	}
	
	if descriptor.lifecycle == .singleton {
		sp.cache[name] = instance
	}
	
	return instance
}

pub fn (sp ServiceProvider) clear_cache() {
	sp.cache = map[string]voidptr{}
}
