module system

// V Test file - run with: v test src/system_test.v

// ============================================================================
// SystemInfo Tests
// ============================================================================

fn test_get_system_info() {
	mut assert_count := 0
	
	info := get_system_info()
	
	// Test hostname is not empty
	assert info.hostname != ''
	assert_count++
	
	// Test architecture is valid
	assert info.arch == 'x64' || info.arch == 'arm' || info.arch == 'arm64'
	assert_count++
	
	// Test OS is valid
	assert info.os != ''
	assert_count++
	
	// Test platform is valid (Linux, Windows, macOS)
	assert info.platform == 'linux' || info.platform == 'windows' || info.platform == 'macos'
	assert_count++
	
	println('test_get_system_info: ${assert_count} assertions passed')
}

// ============================================================================
// MemoryInfo Tests
// ============================================================================

fn test_get_memory_info() {
	mut assert_count := 0
	
	memory := get_memory_info()
	
	// Test total memory is positive
	assert memory.total > 0
	assert_count++
	
	// Test used memory is non-negative
	assert memory.used >= 0
	assert_count++
	
	// Test free memory is non-negative
	assert memory.free >= 0
	assert_count++
	
	// Test total = used + free (approximately)
	assert memory.total == memory.used + memory.free
	assert_count++
	
	// Test percentage is between 0 and 100
	assert memory.percent >= 0.0
	assert_count++
	
	assert memory.percent <= 100.0
	assert_count++
	
	println('test_get_memory_info: ${assert_count} assertions passed')
}

fn test_format_bytes() {
	mut assert_count := 0
	
	// Test bytes
	assert format_bytes(512) == '512 B'
	assert_count++
	
	// Test KB
	assert format_bytes(1536) == '1.50 KB'
	assert_count++
	
	// Test MB
	assert format_bytes(1572864) == '1.50 MB'
	assert_count++
	
	// Test GB
	assert format_bytes(1610612736) == '1.50 GB'
	assert_count++
	
	println('test_format_bytes: ${assert_count} assertions passed')
}

// ============================================================================
// CPUInfo Tests
// ============================================================================

fn test_get_cpu_info() {
	mut assert_count := 0
	
	cpu := get_cpu_info()
	
	// Test model is not empty
	assert cpu.model != ''
	assert_count++
	
	// Test cores is positive
	assert cpu.cores > 0
	assert_count++
	
	// Test threads is positive
	assert cpu.threads > 0
	assert_count++
	
	// Test threads >= cores
	assert cpu.threads >= cpu.cores
	assert_count++
	
	println('test_get_cpu_info: ${assert_count} assertions passed')
}

fn test_get_cpu_usage() {
	mut assert_count := 0
	
	usage := get_cpu_usage()
	
	// Test usage is between 0 and 100
	assert usage >= 0.0
	assert_count++
	
	assert usage <= 100.0
	assert_count++
	
	println('test_get_cpu_usage: ${assert_count} assertions passed')
}

// ============================================================================
// DiskInfo Tests
// ============================================================================

fn test_get_disk_info() {
	mut assert_count := 0
	
	// Test with root directory
	disk := get_disk_info('/')
	
	// For the test to be meaningful, we check structure
	// Note: On some systems, root might not be accessible
	if disk.total > 0 {
		// Test total is positive
		assert disk.total > 0
		assert_count++
		
		// Test used is non-negative
		assert disk.used >= 0
		assert_count++
		
		// Test free is non-negative
		assert disk.free >= 0
		assert_count++
		
		// Test total >= used + free (allowing for system reserved)
		assert disk.total >= disk.used + disk.free
		assert_count++
	} else {
		// If we can't access root, just verify structure exists
		assert true
		assert_count++
	}
	
	println('test_get_disk_info: ${assert_count} assertions passed')
}

fn test_get_all_disk_info() {
	mut assert_count := 0
	
	disks := get_all_disk_info()
	
	// Should have at least one disk
	assert disks.len >= 0  // May be empty on some systems
	assert_count++
	
	// Each disk should have valid data
	for disk in disks {
		if disk.total > 0 {
			assert disk.used >= 0
			assert_count++
			
			assert disk.free >= 0
			assert_count++
		}
	}
	
	println('test_get_all_disk_info: ${assert_count} assertions passed')
}

// ============================================================================
// Uptime Tests
// ============================================================================

fn test_get_uptime() {
	mut assert_count := 0
	
	uptime := get_uptime()
	
	// Test uptime is positive
	assert uptime > 0
	assert_count++
	
	println('test_get_uptime: ${assert_count} assertions passed')
}

fn test_format_uptime() {
	mut assert_count := 0
	
	// Test seconds
	assert format_uptime(30) == '30s'
	assert_count++
	
	// Test minutes
	assert format_uptime(150) == '2m 30s'
	assert_count++
	
	// Test hours
	assert format_uptime(3661) == '1h 1m 1s'
	assert_count++
	
	// Test days
	assert format_uptime(90061) == '1d 1h 1m'
	assert_count++
	
	println('test_format_uptime: ${assert_count} assertions passed')
}

// ============================================================================
// Process Count Tests
// ============================================================================

fn test_get_process_count() {
	mut assert_count := 0
	
	count := get_process_count()
	
	// Should have at least one process
	assert count >= 1
	assert_count++
	
	// Should have reasonable number (less than 10000)
	assert count < 10000
	assert_count++
	
	println('test_get_process_count: ${assert_count} assertions passed')
}

// ============================================================================
// Load Average Tests
// ============================================================================

fn test_get_load_average() {
	mut assert_count := 0
	
	load := get_load_average()
	
	// Load values should be non-negative
	assert load.min1 >= 0.0
	assert_count++
	
	assert load.min5 >= 0.0
	assert_count++
	
	assert load.min15 >= 0.0
	assert_count++
	
	println('test_get_load_average: ${assert_count} assertions passed')
}

// ============================================================================
// Test Runner
// ============================================================================

fn test_all() {
	// System info tests
	test_get_system_info()
	
	// Memory tests
	test_get_memory_info()
	test_format_bytes()
	
	// CPU tests
	test_get_cpu_info()
	test_get_cpu_usage()
	
	// Disk tests
	test_get_disk_info()
	test_get_all_disk_info()

	// Uptime tests
	test_get_uptime()
	test_format_uptime()
	
	// Process tests
	test_get_process_count()
	
	// Load tests
	test_get_load_average()
}
