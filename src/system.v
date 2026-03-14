module system

import os
import time

// ============================================================================
// Data Structures
// ============================================================================

pub struct SystemInfo {
pub mut:
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

pub struct MemoryInfo {
pub mut:
	total     u64
	used      u64
	free      u64
	available u64
	percent   f64
	buffers   u64
	cached    u64
}

pub struct CPUInfo {
pub mut:
	model       string
	cores       int
	logical     int
	usage       f64
	frequency   f64
	load_avg_1  f64
	load_avg_5  f64
	load_avg_15 f64
}

pub struct DiskInfo {
pub mut:
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

// ============================================================================
// System Info Functions
// ============================================================================

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

pub fn get_memory_info() MemoryInfo {
	mut mem := MemoryInfo{}
	
	meminfo_path := '/proc/meminfo'
	if !os.is_file(meminfo_path) {
		return mem
	}
	
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
	
	if mem.total > 0 {
		mem.used = mem.total - mem.free - mem.buffers - mem.cached
		mem.percent = f64(mem.used) / f64(mem.total) * 100.0
	}
	
	return mem
}

pub fn get_cpu_info() CPUInfo {
	mut cpu := CPUInfo{
		cores: get_cpu_cores()
		logical: get_cpu_cores()
		model: get_cpu_model()
	}
	
	loadavg_path := '/proc/loadavg'
	if os.is_file(loadavg_path) {
		content := os.read_file(loadavg_path) or { '' }
		parts := content.trim_space().split(' ')
		if parts.len >= 3 {
			cpu.load_avg_1 = parts[0].f64()
			cpu.load_avg_5 = parts[1].f64()
			cpu.load_avg_15 = parts[2].f64()
		}
	}
	
	if cpu.cores > 0 {
		cpu.usage = (cpu.load_avg_1 / f64(cpu.cores)) * 100.0
		if cpu.usage > 100.0 {
			cpu.usage = 100.0
		}
	}
	
	return cpu
}

pub fn get_disk_usage(path string) DiskInfo {
	mut disk := DiskInfo{
		mountpoint: path
	}
	
	if !os.exists(path) {
		return disk
	}
	
	cmd := 'df -B1 "${path}" 2>/dev/null | tail -1'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return disk
	}
	
	output := result.output.trim_space()
	if output.len == 0 {
		return disk
	}
	
	parts := output.split(' ').filter(it.len > 0)
	if parts.len >= 5 {
		disk.total = parts[1].u64()
		disk.used = parts[2].u64()
		disk.free = parts[3].u64()
		use_percent := parts[4].replace('%', '')
		disk.percent = use_percent.f64()
	}
	
	return disk
}

pub fn get_all_disk_info() []DiskInfo {
	mut disks := []DiskInfo{}
	
	mounts_path := '/proc/mounts'
	if !os.is_file(mounts_path) {
		return disks
	}
	
	content := os.read_file(mounts_path) or { return disks }
	lines := content.split('\n')
	
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.len == 0 {
			continue
		}
		parts := trimmed.split(' ')
		if parts.len < 4 {
			continue
		}
		
		device := parts[0]
		mountpoint := parts[1]
		fstype := parts[2]
		
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

// ============================================================================
// Helper Functions
// ============================================================================

pub fn get_hostname() string {
	hostname := os.uname().nodename
	return if hostname.len > 0 { hostname } else { 'unknown' }
}

pub fn get_os_name() string {
	os_release := '/etc/os-release'
	if !os.is_file(os_release) {
		return 'Linux'
	}
	
	content := os.read_file(os_release) or { return 'Linux' }
	for line in content.split('\n') {
		if line.starts_with('PRETTY_NAME=') {
			mut result := line
			result = result.replace('PRETTY_NAME=', '')
			result = result.replace('"', '')
			return if result.len > 0 { result } else { 'Linux' }
		}
	}
	return 'Linux'
}

pub fn get_os_version() string {
	release := os.uname().release
	return if release.len > 0 { release } else { 'unknown' }
}

pub fn get_arch() string {
	arch := os.uname().machine
	return if arch.len > 0 { arch } else { 'unknown' }
}

pub fn get_cpu_model() string {
	cpuinfo := '/proc/cpuinfo'
	if !os.is_file(cpuinfo) {
		return 'Unknown'
	}
	
	content := os.read_file(cpuinfo) or { return 'Unknown' }
	for line in content.split('\n') {
		if line.starts_with('model name') {
			parts := line.split(':')
			if parts.len > 1 {
				model := parts[1].trim_space()
				return if model.len > 0 { model } else { 'Unknown' }
			}
		}
	}
	return 'Unknown'
}

pub fn get_cpu_cores() int {
	cpuinfo := '/proc/cpuinfo'
	if !os.is_file(cpuinfo) {
		return 1
	}
	
	content := os.read_file(cpuinfo) or { return 1 }
	mut cores := 0
	for line in content.split('\n') {
		if line.starts_with('processor') {
			cores++
		}
	}
	return if cores > 0 { cores } else { 1 }
}

pub fn get_uptime() u64 {
	uptime_path := '/proc/uptime'
	if !os.is_file(uptime_path) {
		return 0
	}
	
	content := os.read_file(uptime_path) or { return 0 }
	parts := content.split('.')
	if parts.len > 0 {
		return parts[0].u64()
	}
	return 0
}

pub fn get_boot_time() u64 {
	uptime := get_uptime()
	if uptime > 0 {
		diff := time.now().unix() - i64(uptime)
		if diff > 0 {
			return u64(diff)
		}
	}
	return 0
}

// ============================================================================
// Formatting Functions
// ============================================================================

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
