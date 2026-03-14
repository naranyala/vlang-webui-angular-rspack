module services

import json
import os

// Note: Enhanced service implementations are in:
// - core_services.v (ConfigService, CacheService, DatabaseService, HttpClientService)
// - additional_services.v (LoggerService, ValidationService, MetricsService, HealthCheckService, AuthService)
// - interfaces.v (Service interfaces: ILogger, IConfig, ICache, IDatabase, IHttpClient, etc.)
// - registry.v (Fluent service registration API)

// System Info Service (Legacy - kept for backward compatibility)
pub struct SystemInfoService {
pub mut:
	hostname    string
	os_info     string
	arch        string
	cpu_count   string
	initialized bool
}

pub fn new_system_info_service() &SystemInfoService {
	return &SystemInfoService{
		hostname: 'localhost'
		os_info: 'linux'
		arch: 'x64'
		cpu_count: '4'
		initialized: false
	}
}

pub fn (mut s SystemInfoService) init() bool {
	if s.initialized {
		return true
	}
	
	// Initialize with actual system info
	s.hostname = os.uname().nodename
	s.os_info = os.uname().sysname
	s.arch = os.uname().machine
	
	// Get CPU count
	cpuinfo := '/proc/cpuinfo'
	mut cores := 0
	if os.is_file(cpuinfo) {
		content := os.read_file(cpuinfo) or { '' }
		for line in content.split('\n') {
			if line.starts_with('processor') {
				cores++
			}
		}
	}
	s.cpu_count = if cores > 0 { '${cores}' } else { '1' }
	
	s.initialized = true
	return true
}

pub fn (mut s SystemInfoService) dispose() {
	// No cleanup needed
}

pub fn (s SystemInfoService) name() string {
	return 'system_info'
}

pub fn (s SystemInfoService) is_initialized() bool {
	return s.initialized
}

pub fn (s SystemInfoService) to_json() string {
	data := {
		'hostname': s.hostname
		'os': s.os_info
		'arch': s.arch
		'cpu_count': s.cpu_count
	}
	return json.encode(data)
}

pub fn (s SystemInfoService) get_hostname() string {
	return s.hostname
}

pub fn (s SystemInfoService) get_os_info() string {
	return s.os_info
}

pub fn (s SystemInfoService) get_arch() string {
	return s.arch
}

pub fn (s SystemInfoService) get_cpu_count() string {
	return s.cpu_count
}
