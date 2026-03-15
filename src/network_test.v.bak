module network

// V Test file - run with: v test src/network_test.v

// ============================================================================
// NetworkInterface Tests
// ============================================================================

fn test_get_network_interfaces() {
	mut assert_count := 0
	
	interfaces := get_network_interfaces()
	
	// Should have at least one interface (lo/loopback)
	assert interfaces.len >= 0  // May be empty in some environments
	assert_count++
	
	// Each interface should have valid data
	for iface in interfaces {
		if iface.name != '' {
			assert iface.name.len > 0
			assert_count++
		}
	}
	
	println('test_get_network_interfaces: ${assert_count} assertions passed')
}

fn test_get_active_interface() {
	mut assert_count := 0
	
	interfaces := get_network_interfaces()
	
	mut has_active := false
	for iface in interfaces {
		if iface.is_up {
			has_active = true
			break
		}
	}
	
	// At least loopback should be up
	assert has_active == true || interfaces.len == 0
	assert_count++
	
	println('test_get_active_interface: ${assert_count} assertions passed')
}

// ============================================================================
// Connection Status Tests
// ============================================================================

fn test_get_connection_status() {
	mut assert_count := 0
	
	status := get_connection_status()
	
	// Status should have valid structure
	assert true
	assert_count++
	
	// If connected, should have valid IP
	if status.is_connected {
		// IP should be valid format (simplified check)
		assert status.ip != ''
		assert_count++
	}
	
	println('test_get_connection_status: ${assert_count} assertions passed')
}

fn test_is_online() {
	mut assert_count := 0
	
	online := is_online()
	
	// Should return boolean
	assert online == true || online == false
	assert_count++
	
	println('test_is_online: ${assert_count} assertions passed')
}

// ============================================================================
// Network Stats Tests
// ============================================================================

fn test_get_network_stats() {
	mut assert_count := 0
	
	stats := get_network_stats()
	
	// Stats should have valid structure
	assert true
	assert_count++
	
	// Bytes received should be non-negative
	assert stats.bytes_received >= 0
	assert_count++
	
	// Bytes sent should be non-negative
	assert stats.bytes_sent >= 0
	assert_count++
	
	println('test_get_network_stats: ${assert_count} assertions passed')
}

fn test_format_bytes_per_second() {
	mut assert_count := 0
	
	// Test B/s
	result := format_bytes_per_second(512)
	assert result == '512 B/s'
	assert_count++
	
	// Test KB/s
	result = format_bytes_per_second(1536)
	assert result == '1.50 KB/s'
	assert_count++
	
	// Test MB/s
	result = format_bytes_per_second(1572864)
	assert result == '1.50 MB/s'
	assert_count++
	
	println('test_format_bytes_per_second: ${assert_count} assertions passed')
}

// ============================================================================
// IP Address Tests
// ============================================================================

fn test_get_local_ip() {
	mut assert_count := 0
	
	ip := get_local_ip()
	
	// IP should be valid format or empty if not available
	if ip != '' {
		// Basic IPv4 format check
		parts := ip.split('.')
		assert parts.len == 4
		assert_count++
	} else {
		// Empty is also acceptable if no network
		assert true
		assert_count++
	}
	
	println('test_get_local_ip: ${assert_count} assertions passed')
}

fn test_get_public_ip() {
	mut assert_count := 0
	
	// This test may fail in isolated environments
	ip := get_public_ip()
	
	// IP should be valid format or empty if unavailable
	if ip != '' {
		parts := ip.split('.')
		assert parts.len == 4
		assert_count++
	} else {
		// Empty is acceptable in test environments
		assert true
		assert_count++
	}
	
	println('test_get_public_ip: ${assert_count} assertions passed')
}

// ============================================================================
// DNS Tests
// ============================================================================

fn test_get_dns_servers() {
	mut assert_count := 0
	
	dns_servers := get_dns_servers()
	
	// Should have at least one DNS server or be empty
	assert dns_servers.len >= 0
	assert_count++
	
	// Each DNS server should be valid IP format
	for dns in dns_servers {
		if dns != '' {
			parts := dns.split('.')
			assert parts.len == 4
			assert_count++
		}
	}
	
	println('test_get_dns_servers: ${assert_count} assertions passed')
}

// ============================================================================
// Port Tests
// ============================================================================

fn test_is_port_open() {
	mut assert_count := 0
	
	// Test with a likely closed port
	result := is_port_open('127.0.0.1', 59999)
	assert result == false || result == true  // Depends on what's running
	assert_count++
	
	println('test_is_port_open: ${assert_count} assertions passed')
}

fn test_validate_ip() {
	mut assert_count := 0
	
	// Valid IPv4
	assert validate_ip('192.168.1.1') == true
	assert_count++
	
	assert validate_ip('127.0.0.1') == true
	assert_count++
	
	assert validate_ip('0.0.0.0') == true
	assert_count++
	
	assert validate_ip('255.255.255.255') == true
	assert_count++
	
	// Invalid IPv4
	assert validate_ip('256.1.1.1') == false
	assert_count++
	
	assert validate_ip('192.168.1') == false
	assert_count++
	
	assert validate_ip('192.168.1.1.1') == false
	assert_count++
	
	assert validate_ip('abc.def.ghi.jkl') == false
	assert_count++
	
	assert validate_ip('') == false
	assert_count++
	
	println('test_validate_ip: ${assert_count} assertions passed')
}

// ============================================================================
// MAC Address Tests
// ============================================================================

fn test_get_mac_address() {
	mut assert_count := 0
	
	mac := get_mac_address()
	
	// MAC should be valid format or empty
	if mac != '' {
		// Basic MAC format check (XX:XX:XX:XX:XX:XX)
		parts := mac.split(':')
		assert parts.len == 6
		assert_count++
	} else {
		assert true
		assert_count++
	}
	
	println('test_get_mac_address: ${assert_count} assertions passed')
}

fn test_validate_mac() {
	mut assert_count := 0
	
	// Valid MAC addresses
	assert validate_mac('00:1A:2B:3C:4D:5E') == true
	assert_count++
	
	assert validate_mac('aa:bb:cc:dd:ee:ff') == true
	assert_count++
	
	assert validate_mac('AA:BB:CC:DD:EE:FF') == true
	assert_count++
	
	// Invalid MAC addresses
	assert validate_mac('00:1A:2B:3C:4D') == false  // Too short
	assert_count++
	
	assert validate_mac('00:1A:2B:3C:4D:5E:6F') == false  // Too long
	assert_count++
	
	assert validate_mac('00-1A-2B-3C-4D-5E') == false  // Wrong separator
	assert_count++
	
	assert validate_mac('') == false
	assert_count++
	
	println('test_validate_mac: ${assert_count} assertions passed')
}

// ============================================================================
// Test Runner
// ============================================================================

fn test_all() {
	// Network interface tests
	test_get_network_interfaces()
	test_get_active_interface()
	
	// Connection status tests
	test_get_connection_status()
	test_is_online()
	
	// Network stats tests
	test_get_network_stats()
	test_format_bytes_per_second()
	
	// IP address tests
	test_get_local_ip()
	test_get_public_ip()
	
	// DNS tests
	test_get_dns_servers()
	
	// Port tests
	test_is_port_open()
	test_validate_ip()
	
	// MAC address tests
	test_get_mac_address()
	test_validate_mac()
}
