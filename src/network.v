module network

import os

// NetworkInfo contains network interface information
pub struct NetworkInfo {
mut:
	name        string
	ip_address  string
	ip6_address string
	mac_address string
	netmask     string
	broadcast   string
	state       string
	rx_bytes    u64
	tx_bytes    u64
	rx_packets  u64
	tx_packets  u64
}

// ConnectionStatus contains connection test results
pub struct ConnectionStatus {
mut:
	is_online   bool
	hostname    string
	ip_address  string
	public_ip   string
	country     string
	city        string
	isp         string
	latency_ms  int
	dns_servers []string
	gateway     string
}

// PortInfo contains information about an open port
pub struct PortInfo {
	port      int
	protocol  string
	state     string
	service   string
	process   string
}

// GetNetworkInterfaces returns all network interfaces
pub fn get_network_interfaces() []NetworkInfo {
	mut interfaces := []NetworkInfo{}

	// Read from /proc/net/dev for interface stats
	net_dev := '/proc/net/dev'
	if os.is_file(net_dev) {
		content := os.read_file(net_dev) or { return interfaces }
		lines := content.split('\n')

		// Skip header lines
		if lines.len > 2 {
			for i := 2; i < lines.len; i++ {
				line := lines[i].trim_space()
				if line.len == 0 {
					continue
				}

				parts := line.split(':')
				if parts.len < 2 {
					continue
				}

				name := parts[0].trim_space()
				stats := parts[1].trim_space().split(' ')

				mut iface := NetworkInfo{
					name: name
				}

				// Parse stats (format varies, but rx/tx bytes are typically at positions 0 and 8)
				if stats.len >= 16 {
					iface.rx_bytes = stats[0].u64()
					iface.rx_packets = stats[1].u64()
					iface.tx_bytes = stats[8].u64()
					iface.tx_packets = stats[9].u64()
				}

				interfaces << iface
			}
		}
	}

	// Enrich with IP addresses
	for mut iface in interfaces {
		// Get IP address using hostname or ip command simulation
		if iface.name != 'lo' {
			iface.ip_address = get_interface_ip(iface.name)
			iface.mac_address = get_mac_address(iface.name)
			iface.state = if iface.ip_address != '' { 'up' } else { 'down' }
		} else {
			iface.ip_address = '127.0.0.1'
			iface.state = 'up'
		}
	}

	return interfaces
}

// GetConnectionStatus tests and returns connection status
pub fn get_connection_status() ConnectionStatus {
	mut status := ConnectionStatus{
		is_online: false
		hostname: os.uname().nodename
		dns_servers: get_dns_servers()
		gateway: get_default_gateway()
	}

	// Get local IP
	status.ip_address = get_primary_ip()

	// Test connectivity by checking if we can resolve DNS
	status.is_online = test_connectivity()

	// Try to get public IP (non-blocking, with timeout)
	status.public_ip = get_public_ip()

	return status
}

// GetOpenPorts returns list of open ports (requires appropriate permissions)
pub fn get_open_ports() []PortInfo {
	mut ports := []PortInfo{}

	// Read TCP connections from /proc/net/tcp
	tcp_path := '/proc/net/tcp'
	if os.is_file(tcp_path) {
		content := os.read_file(tcp_path) or { return ports }
		lines := content.split('\n')

		// Skip header
		if lines.len > 1 {
			for i := 1; i < lines.len; i++ {
				line := lines[i].trim_space()
				if line.len == 0 {
					continue
				}

				parts := line.split(' ')
				if parts.len < 4 {
					continue
				}

				// Parse local address (format: hex IP:hex port)
				local_addr := parts[1]
				addr_parts := local_addr.split(':')
				if addr_parts.len < 2 {
					continue
				}

				port_hex := addr_parts[1]
				port := u16_from_hex(port_hex)

				// Parse state (01 = ESTABLISHED, 0A = LISTEN)
				state_hex := parts[3]
				state := match state_hex {
					'01' { 'ESTABLISHED' }
					'02' { 'SYN_SENT' }
					'03' { 'SYN_RECV' }
					'04' { 'FIN_WAIT1' }
					'05' { 'FIN_WAIT2' }
					'06' { 'TIME_WAIT' }
					'07' { 'CLOSE' }
					'08' { 'CLOSE_WAIT' }
					'09' { 'LAST_ACK' }
					'0A' { 'LISTEN' }
					'0B' { 'CLOSING' }
					else { 'UNKNOWN' }
				}

				// Only include listening ports
				if state == 'LISTEN' {
					ports << PortInfo{
						port: int(port)
						protocol: 'tcp'
						state: state
						service: get_service_name(int(port))
					}
				}
			}
		}
	}

	// Also check UDP (similar process)
	udp_path := '/proc/net/udp'
	if os.is_file(udp_path) {
		content := os.read_file(udp_path) or { return ports }
		lines := content.split('\n')

		if lines.len > 1 {
			for i := 1; i < lines.len; i++ {
				line := lines[i].trim_space()
				if line.len == 0 {
					continue
				}

				parts := line.split(' ')
				if parts.len < 4 {
					continue
				}

				local_addr := parts[1]
				addr_parts := local_addr.split(':')
				if addr_parts.len < 2 {
					continue
				}

				port_hex := addr_parts[1]
				port := u16_from_hex(port_hex)

				ports << PortInfo{
					port: int(port)
					protocol: 'udp'
					state: 'OPEN'
					service: get_service_name(int(port))
				}
			}
		}
	}

	return ports
}

// TestConnectivity tests if the system has internet connectivity
pub fn test_connectivity() bool {
	// Try to connect to a well-known DNS server
	// This is a simple check without actually making HTTP requests
	dns_servers := get_dns_servers()
	if dns_servers.len == 0 {
		return false
	}

	// Check if we have a default route
	gateway := get_default_gateway()
	return gateway != ''
}

// Get primary IP address
fn get_primary_ip() string {
	interfaces := get_network_interfaces()
	for iface in interfaces {
		if iface.name != 'lo' && iface.ip_address != '' && !iface.ip_address.starts_with('fe80') {
			return iface.ip_address
		}
	}
	return '127.0.0.1'
}

// Get IP address for a specific interface
fn get_interface_ip(iface_name string) string {
	// Try using ip command or read from /proc
	cmd_output := os.execute('ip addr show ${iface_name} 2>/dev/null | grep "inet " | awk \'{print $2}\' | cut -d/ -f1')
	if cmd_output.exit_code == 0 && cmd_output.output.trim_space().len > 0 {
		return cmd_output.output.trim_space()
	}
	return ''
}

// Get MAC address for a specific interface
fn get_mac_address(iface_name string) string {
	addr_path := '/sys/class/net/${iface_name}/address'
	if os.is_file(addr_path) {
		return os.read_file(addr_path) or { '' }
	}
	return ''
}

// Get DNS servers from resolv.conf
fn get_dns_servers() []string {
	mut dns_servers := []string{}

	resolv_conf := '/etc/resolv.conf'
	if os.is_file(resolv_conf) {
		content := os.read_file(resolv_conf) or { return dns_servers }
		for mut line in content.split('\n') {
			line = line.trim_space()
			if line.starts_with('nameserver') {
				parts := line.split(' ')
				if parts.len > 1 {
					dns_servers << parts[1].trim_space()
				}
			}
		}
	}

	if dns_servers.len == 0 {
		dns_servers << '8.8.8.8'
		dns_servers << '8.8.4.4'
	}

	return dns_servers
}

// Get default gateway
fn get_default_gateway() string {
	route_path := '/proc/net/route'
	if os.is_file(route_path) {
		content := os.read_file(route_path) or { return '' }
		lines := content.split('\n')

		// Skip header
		if lines.len > 1 {
			for line in lines[1..] {
				parts := line.trim_space().split('\t')
				if parts.len >= 3 {
					destination := parts[1]
					if destination == '00000000' {
						// This is the default route, get gateway
						gateway_hex := parts[2]
						return ip_from_hex(gateway_hex)
					}
				}
			}
		}
	}
	return ''
}

// Get public IP (simplified - would need actual HTTP request in production)
fn get_public_ip() string {
	// In a real implementation, this would make an HTTP request to a service like
	// ifconfig.me or api.ipify.org
	// For now, return empty as it requires network access
	return ''
}

// Get service name for common ports
fn get_service_name(port int) string {
	return match port {
		22 { 'ssh' }
		80 { 'http' }
		443 { 'https' }
		21 { 'ftp' }
		25 { 'smtp' }
		53 { 'dns' }
		110 { 'pop3' }
		143 { 'imap' }
		3306 { 'mysql' }
		5432 { 'postgresql' }
		6379 { 'redis' }
		8080 { 'http-alt' }
		27017 { 'mongodb' }
		else { 'unknown' }
	}
}

// Helper: Convert hex string to u16
fn u16_from_hex(hex string) u16 {
	// Simple hex to int conversion
	mut result := u16(0)
	mut multiplier := u16(1)

	for i := hex.len - 1; i >= 0; i-- {
		c := hex[i]
		digit := match c {
			`0`...`9` { c - `0` }
			`a`...`f` { c - `a` + 10 }
			`A`...`F` { c - `A` + 10 }
			else { 0 }
		}
		result += u16(digit) * multiplier
		multiplier *= 16
	}

	return result
}

// Helper: Convert hex IP to dotted notation
fn ip_from_hex(hex string) string {
	if hex.len != 8 {
		return ''
	}

	// Linux stores IP in little-endian format in /proc/net/route
	a := u16_from_hex(hex[6..8])
	b := u16_from_hex(hex[4..6])
	c := u16_from_hex(hex[2..4])
	d := u16_from_hex(hex[0..2])

	return '${a}.${b}.${c}.${d}'
}

// Ping a host (simplified - uses system ping)
pub fn ping_host(host string, count int) []PingResult {
	mut results := []PingResult{}

	// Execute ping command
	cmd := 'ping -c ${count} -W 1 ${host} 2>&1'
	exec_result := os.execute(cmd)

	if exec_result.exit_code == 0 {
		// Parse ping output
		output := exec_result.output
		lines := output.split('\n')

		for line in lines {
			if line.contains('icmp_seq') {
				// Extract time from output like "64 bytes from ... icmp_seq=1 ttl=118 time=12.3 ms"
				if line.contains('time=') {
					time_parts := line.split('time=')
					if time_parts.len > 1 {
						mut time_str := time_parts[1].split(' ')[0]
						time_str = time_str.replace(' ms', '')
						time_ms := time_str.int()
						results << PingResult{
							success: true
							time_ms: time_ms
						}
					}
				}
			}
		}
	}

	return results
}

// PingResult contains result of a single ping
pub struct PingResult {
	success bool
	time_ms int
	timeout bool
}

// NetworkStats contains network I/O statistics
pub struct NetworkStats {
mut:
	bytes_sent       u64
	bytes_received   u64
	packets_sent     u64
	packets_received u64
	errors_in        u64
	errors_out       u64
	dropped_in       u64
	dropped_out      u64
}

// GetNetworkStats returns network statistics for all interfaces
pub fn get_network_stats() NetworkStats {
	mut stats := NetworkStats{}

	net_dev := '/proc/net/dev'
	if os.is_file(net_dev) {
		content := os.read_file(net_dev) or { return stats }
		lines := content.split('\n')

		// Skip header lines
		if lines.len > 2 {
			for i := 2; i < lines.len; i++ {
				line := lines[i].trim_space()
				if line.len == 0 || line.starts_with('lo:') {
					continue
				}

				parts := line.split(':')
				if parts.len < 2 {
					continue
				}

				stats_parts := parts[1].trim_space().split(' ')
				if stats_parts.len >= 11 {
					stats.bytes_received += stats_parts[0].u64()
					stats.packets_received += stats_parts[1].u64()
					stats.errors_in += stats_parts[2].u64()
					stats.dropped_in += stats_parts[3].u64()
					stats.bytes_sent += stats_parts[8].u64()
					stats.packets_sent += stats_parts[9].u64()
					stats.errors_out += stats_parts[10].u64()
					stats.dropped_out += stats_parts[11].u64()
				}
			}
		}
	}

	return stats
}
