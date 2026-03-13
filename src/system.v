module system

import os
import time

// SystemInfo contains comprehensive system information
pub struct SystemInfo {
mut:
	hostname       string
	os_name        string
	os_version     string
	arch           string
	cpu_model      string
	cpu_cores      int
	cpu_usage      f64
	memory_total   u64
	memory_used    u64
	memory_free    u64
	memory_percent f64
	uptime         u64
	boot_time      u64
}

// MemoryInfo contains memory statistics
pub struct MemoryInfo {
mut:
	total     u64
	used      u64
	free      u64
	available u64
	percent   f64
	buffers   u64
	cached    u64
}

// CPUInfo contains CPU statistics
pub struct CPUInfo {
mut:
	model       string
	cores       int
	logical     int
	usage       f64
	frequency   f64
	load_avg_1  f64
	load_avg_5  f64
	load_avg_15 f64
}

// DiskInfo contains disk/partition statistics
pub struct DiskInfo {
mut:
	device       string
	mountpoint   string
	fstype       string
	total        u64
	used         u64
	free         u64
	percent      f64
	inodes_total u64
	inodes_used  u64
	inodes_free  u64
}

// DiskIOInfo contains disk I/O statistics
pub struct DiskIOInfo {
	read_count  u64
	write_count u64
	read_bytes  u64
	write_bytes u64
	read_time   u64
	write_time  u64
}

// BatteryInfo contains battery status (for systems with battery)
pub struct BatteryInfo {
mut:
	has_battery bool
	percent     int
	status      string
	time_left   string
	icon        string
	color       string
	voltage     f64
	energy_full u64
	energy_now  u64
}

// GetSystemInfo returns comprehensive system information
pub fn get_system_info() SystemInfo {
	mut info := SystemInfo{
		hostname: get_hostname()
		os_name: get_os_name()
		os_version: get_os_version()
		arch: get_arch()
		cpu_model: get_cpu_model()
		cpu_cores: get_cpu_cores()
		uptime: get_uptime()
		boot_time: get_boot_time()
	}

	memory := get_memory_info()
	info.memory_total = memory.total
	info.memory_used = memory.used
	info.memory_free = memory.free
	info.memory_percent = memory.percent

	cpu := get_cpu_info()
	info.cpu_usage = cpu.usage

	return info
}

// GetMemoryInfo returns memory statistics
pub fn get_memory_info() MemoryInfo {
	mut mem := MemoryInfo{}

	// Try to read from /proc/meminfo
	meminfo_path := '/proc/meminfo'
	if os.is_file(meminfo_path) {
		content := os.read_file(meminfo_path) or { return mem }
		lines := content.split('\n')

		for line in lines {
			parts := line.split(':')
			if parts.len < 2 {
				continue
			}
			key := parts[0].trim_space()
			value_parts := parts[1].trim_space().split(' ')
			value_kb := value_parts[0].u64()
			value_bytes := value_kb * 1024

			match key {
				'MemTotal' { mem.total = value_bytes }
				'MemFree' { mem.free = value_bytes }
				'MemAvailable' { mem.available = value_bytes }
				'Buffers' { mem.buffers = value_bytes }
				'Cached' { mem.cached = value_bytes }
				else {}
			}
		}

		mem.used = mem.total - mem.free - mem.buffers - mem.cached
		if mem.total > 0 {
			mem.percent = f64(mem.used) / f64(mem.total) * 100.0
		}
	}

	return mem
}

// GetCPUInfo returns CPU statistics
pub fn get_cpu_info() CPUInfo {
	mut cpu := CPUInfo{
		cores: get_cpu_cores()
		logical: get_cpu_cores()
		model: get_cpu_model()
	}

	// Read load averages
	if os.is_file('/proc/loadavg') {
		content := os.read_file('/proc/loadavg') or { '' }
		parts := content.trim_space().split(' ')
		if parts.len >= 3 {
			cpu.load_avg_1 = parts[0].f64()
			cpu.load_avg_5 = parts[1].f64()
			cpu.load_avg_15 = parts[2].f64()
		}
	}

	// Estimate CPU usage from load average
	if cpu.cores > 0 {
		cpu.usage = (cpu.load_avg_1 / f64(cpu.cores)) * 100.0
		if cpu.usage > 100.0 {
			cpu.usage = 100.0
		}
	}

	return cpu
}

// GetDiskUsage returns disk usage for a given path
pub fn get_disk_usage(path string) DiskInfo {
	mut disk := DiskInfo{
		mountpoint: path
	}

	// Use df command to get disk info
	cmd := 'df -B1 "${path}" 2>/dev/null | tail -1'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return disk
	}

	output := result.output.trim_space()
	if output.len == 0 {
		return disk
	}

	// Parse df output: Filesystem 1B-blocks Used Available Use% Mounted
	parts := output.split(' ').filter(it.len > 0)
	if parts.len >= 5 {
		// parts[0] = filesystem, parts[1] = total, parts[2] = used, parts[3] = available, parts[4] = use%
		disk.total = parts[1].u64()
		disk.used = parts[2].u64()
		disk.free = parts[3].u64()
		
		use_percent := parts[4].replace('%', '')
		disk.percent = use_percent.f64()
	}

	return disk
}

// GetAllDiskInfo returns information about all mounted filesystems
pub fn get_all_disk_info() []DiskInfo {
	mut disks := []DiskInfo{}

	// Read /proc/mounts
	mounts_path := '/proc/mounts'
	if !os.is_file(mounts_path) {
		return disks
	}

	content := os.read_file(mounts_path) or { return disks }
	lines := content.split('\n')

	for line in lines {
		if line.trim_space().len == 0 {
			continue
		}
		parts := line.split(' ')
		if parts.len < 4 {
			continue
		}

		device := parts[0]
		mountpoint := parts[1]
		fstype := parts[2]

		// Skip pseudo filesystems
		if device.starts_with('none') || device.starts_with('tmpfs') || 
		   device.starts_with('devtmpfs') || mountpoint.starts_with('/sys') ||
		   mountpoint.starts_with('/proc') || mountpoint.starts_with('/run') {
			continue
		}

		mut disk := get_disk_usage(mountpoint)
		disk.device = device
		disk.fstype = fstype
		disks << disk
	}

	return disks
}

// GetBatteryInfo returns battery information
pub fn get_battery_info() BatteryInfo {
	mut battery := BatteryInfo{
		has_battery: false
		percent: 0
		status: 'Unknown'
		time_left: '−'
		icon: '?'
		color: '#888888'
	}

	// Find battery path
	mut battery_path := '/sys/class/power_supply/BAT0'
	if !os.is_dir(battery_path) {
		battery_path = '/sys/class/power_supply/BAT1'
	}

	if !os.is_dir(battery_path) {
		return battery
	}

	battery.has_battery = true

	// Read capacity
	cap_str := os.read_file(os.join_path(battery_path, 'capacity')) or { '0' }
	battery.percent = cap_str.trim_space().int()
	if battery.percent < 0 {
		battery.percent = 0
	}
	if battery.percent > 100 {
		battery.percent = 100
	}

	// Read status
	stat_str := os.read_file(os.join_path(battery_path, 'status')) or { 'Unknown' }
	battery.status = stat_str.trim_space()

	// Read time remaining
	time_str := os.read_file(os.join_path(battery_path, 'time_to_empty_now')) or { '' }
	if time_str.trim_space().len > 0 && battery.status == 'Discharging' {
		secs := time_str.trim_space().int()
		if secs > 0 {
			h := secs / 3600
			m := (secs % 3600) / 60
			battery.time_left = '${h}h ${m:02}m'
		}
	} else if battery.status == 'Charging' {
		battery.time_left = 'charging'
	}

	// Read voltage (if available)
	volt_str := os.read_file(os.join_path(battery_path, 'voltage_now')) or { '0' }
	battery.voltage = f64(volt_str.trim_space().int()) / 1000000.0

	// Read energy (if available)
	energy_full_str := os.read_file(os.join_path(battery_path, 'energy_full')) or { '0' }
	energy_now_str := os.read_file(os.join_path(battery_path, 'energy_now')) or { '0' }
	battery.energy_full = u64(energy_full_str.trim_space().int())
	battery.energy_now = u64(energy_now_str.trim_space().int())

	// Set icon and color based on status and level
	battery.icon = match battery.status {
		'Charging' { '⚡' }
		'Full' { '✓' }
		'Discharging' {
			if battery.percent < 20 {
				'!'
			} else if battery.percent < 50 {
				'B'
			} else {
				'B'
			}
		}
		else { '?' }
	}

	battery.color = if battery.percent >= 60 {
		'#4ade80'
	} else if battery.percent >= 30 {
		'#facc15'
	} else {
		'#f87171'
	}

	return battery
}

// Helper functions

fn get_hostname() string {
	return os.uname().nodename
}

fn get_os_name() string {
	// Try to read from /etc/os-release
	os_release := '/etc/os-release'
	if os.is_file(os_release) {
		content := os.read_file(os_release) or { return 'Linux' }
		for line in content.split('\n') {
			if line.starts_with('PRETTY_NAME=') {
				mut result := line
				result = result.replace('PRETTY_NAME=', '')
				result = result.replace('"', '')
				return result
			}
		}
	}
	return 'Linux'
}

fn get_os_version() string {
	return os.uname().release
}

fn get_arch() string {
	return os.uname().machine
}

fn get_cpu_model() string {
	cpuinfo := '/proc/cpuinfo'
	if os.is_file(cpuinfo) {
		content := os.read_file(cpuinfo) or { return 'Unknown' }
		for line in content.split('\n') {
			if line.starts_with('model name') {
				parts := line.split(':')
				if parts.len > 1 {
					return parts[1].trim_space()
				}
			}
		}
	}
	return 'Unknown'
}

fn get_cpu_cores() int {
	cpuinfo := '/proc/cpuinfo'
	if os.is_file(cpuinfo) {
		content := os.read_file(cpuinfo) or { return 1 }
		mut cores := 0
		for line in content.split('\n') {
			if line.starts_with('processor') {
				cores++
			}
		}
		if cores > 0 {
			return cores
		}
	}
	return 1
}

fn get_uptime() u64 {
	uptime_path := '/proc/uptime'
	if os.is_file(uptime_path) {
		content := os.read_file(uptime_path) or { return 0 }
		parts := content.split('.')
		if parts.len > 0 {
			return parts[0].u64()
		}
	}
	return 0
}

fn get_boot_time() u64 {
	uptime := get_uptime()
	if uptime > 0 {
		diff := time.now().unix() - i64(uptime)
		if diff > 0 {
			return u64(diff)
		}
	}
	return 0
}

// Format bytes to human readable string
pub fn format_bytes(bytes u64) string {
	if bytes < 1024 {
		return '${bytes} B'
	} else if bytes < 1024 * 1024 {
		return '${bytes / 1024} KB'
	} else if bytes < 1024 * 1024 * 1024 {
		return '${f64(bytes) / f64(1024 * 1024):0.2} MB'
	} else if bytes < 1024 * 1024 * 1024 * 1024 {
		return '${f64(bytes) / f64(1024 * 1024 * 1024):0.2} GB'
	} else {
		return '${f64(bytes) / f64(1024 * 1024 * 1024 * 1024):0.2} TB'
	}
}

// Format uptime to human readable string
pub fn format_uptime(seconds u64) string {
	days := seconds / 86400
	hours := (seconds % 86400) / 3600
	mins := (seconds % 3600) / 60

	if days > 0 {
		return '${days}d ${hours}h ${mins}m'
	} else if hours > 0 {
		return '${hours}h ${mins}m'
	} else {
		return '${mins}m'
	}
}
