module main

import vwebui as ui
import os
import json
import time
import system
import network
import filesystem
import process
import error

// Application name and version
const app_name = 'Desktop Dashboard'
const app_version = '1.0.0'

// Verbose logging function - outputs to terminal (stdout)
fn vlog(msg string) {
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	println('[${timestamp}] ${msg}')
}

// ============================================================================
// Error Handling Helpers
// ============================================================================

// handle_api_error logs and registers API handler errors
fn handle_api_error(operation string, err error.ErrorValue) string {
	error.log_error(err)
	return error.to_response(err)
}

// safe_api_call wraps API calls with error handling
fn safe_api_call[T](operation string, fn fn () T) string {
	result := fn()
	return json.encode(result) or {
		err := error.internal_error_msg('Failed to encode ${operation} result')
		return handle_api_error(operation, err)
	}
}

// ============================================================================
// API Handlers - Exposed to frontend via WebUI bindings
// ============================================================================

// GetSystemInfoHandler returns comprehensive system information
fn get_system_info_handler() string {
	vlog('Fetching system information...')
	info := system.get_system_info()
	return json.encode(info)
}

// GetMemoryInfoHandler returns memory statistics
fn get_memory_info_handler() string {
	vlog('Fetching memory information...')
	memory := system.get_memory_info()
	return json.encode(memory)
}

// GetCPUInfoHandler returns CPU statistics
fn get_cpu_info_handler() string {
	vlog('Fetching CPU information...')
	cpu := system.get_cpu_info()
	return json.encode(cpu)
}

// GetDiskInfoHandler returns disk usage information
fn get_disk_info_handler() string {
	vlog('Fetching disk information...')
	disks := system.get_all_disk_info()
	return json.encode(disks)
}

// GetBatteryInfoHandler returns battery information (if available)
fn get_battery_info_handler() string {
	vlog('Fetching battery information...')
	battery := system.get_battery_info()
	return json.encode(battery)
}

// GetNetworkInfoHandler returns network interface information
fn get_network_info_handler() string {
	vlog('Fetching network information...')
	interfaces := network.get_network_interfaces()
	return json.encode(interfaces)
}

// GetConnectionStatusHandler returns connection status
fn get_connection_status_handler() string {
	vlog('Checking connection status...')
	status := network.get_connection_status()
	return json.encode(status)
}

// GetProcessInfoHandler returns process information
fn get_process_info_handler() string {
	vlog('Fetching process information...')
	mut processes := process.get_all_processes()
	// Limit to first 100 processes for performance
	if processes.len > 100 {
		processes = processes[..].clone()[..100]
	}
	return json.encode(processes)
}

// GetSystemLoadHandler returns system load information
fn get_system_load_handler() string {
	vlog('Fetching system load...')
	load := process.get_system_load()
	return json.encode(load)
}

// GetProcessStatsHandler returns process statistics
fn get_process_stats_handler() string {
	vlog('Fetching process statistics...')
	stats := process.get_process_stats()
	return json.encode(stats)
}

// GetNetworkStatsHandler returns network I/O statistics
fn get_network_stats_handler() string {
	vlog('Fetching network statistics...')
	stats := network.get_network_stats()
	return json.encode(stats)
}

// GetFileInfoHandler returns information about a specific file
fn get_file_info_handler(path string) string {
	vlog('Fetching file info: ${path}')
	info := filesystem.get_file_info(path)
	return json.encode(info)
}

// ListDirectoryHandler lists directory contents
fn list_directory_handler(path string, show_hidden bool) string {
	vlog('Listing directory: ${path}')
	items := filesystem.list_directory(path, show_hidden)
	return json.encode(items)
}

// DashboardData contains all dashboard information
struct DashboardData {
	system        system.SystemInfo
	memory        system.MemoryInfo
	cpu           system.CPUInfo
	battery       system.BatteryInfo
	network       []network.NetworkInfo
	connection    network.ConnectionStatus
	load          process.SystemLoad
	process_stats process.ProcessStats
	network_stats network.NetworkStats
	timestamp     i64
}

// GetDashboardDataHandler returns all dashboard data in one call
fn get_dashboard_data_handler() string {
	vlog('Fetching complete dashboard data...')

	data := DashboardData{
		system: system.get_system_info()
		memory: system.get_memory_info()
		cpu: system.get_cpu_info()
		battery: system.get_battery_info()
		network: network.get_network_interfaces()
		connection: network.get_connection_status()
		load: process.get_system_load()
		process_stats: process.get_process_stats()
		network_stats: network.get_network_stats()
		timestamp: time.now().unix()
	}

	return json.encode(data)
}

// ============================================================================
// Main Application
// ============================================================================

fn main() {
	vlog('========================================')
	vlog('Starting ${app_name} v${app_version}...')
	vlog('========================================')
	vlog('Working directory: ${os.getwd()}')

	// Verify frontend dist exists
	dist_path := 'frontend/dist/browser'
	vlog('Checking frontend dist: ${dist_path}')

	if !os.is_dir(dist_path) {
		vlog('ERROR: Frontend dist not found at ${dist_path}')
		vlog('Please run: ./run.sh build')
		return
	}

	index_path := os.join_path(dist_path, 'index.html')
	if !os.exists(index_path) {
		vlog('ERROR: index.html not found at ${index_path}')
		vlog('Please run: ./run.sh build')
		return
	}

	vlog('Frontend dist verified: ${index_path}')

	// Create WebUI window
	mut w := ui.new_window()
	vlog('Window created successfully')

	// Register all API handlers
	vlog('Registering API handlers...')

	// System info endpoints
	w.bind('getSystemInfo', fn (e &ui.Event) string {
		return get_system_info_handler()
	})

	w.bind('getMemoryInfo', fn (e &ui.Event) string {
		return get_memory_info_handler()
	})

	w.bind('getCPUInfo', fn (e &ui.Event) string {
		return get_cpu_info_handler()
	})

	w.bind('getDiskInfo', fn (e &ui.Event) string {
		return get_disk_info_handler()
	})

	w.bind('getBatteryInfo', fn (e &ui.Event) string {
		return get_battery_info_handler()
	})

	// Network endpoints
	w.bind('getNetworkInfo', fn (e &ui.Event) string {
		return get_network_info_handler()
	})

	w.bind('getConnectionStatus', fn (e &ui.Event) string {
		return get_connection_status_handler()
	})

	w.bind('getNetworkStats', fn (e &ui.Event) string {
		return get_network_stats_handler()
	})

	// Process endpoints
	w.bind('getProcessInfo', fn (e &ui.Event) string {
		return get_process_info_handler()
	})

	w.bind('getSystemLoad', fn (e &ui.Event) string {
		return get_system_load_handler()
	})

	w.bind('getProcessStats', fn (e &ui.Event) string {
		return get_process_stats_handler()
	})

	// Dashboard endpoint (all-in-one)
	w.bind('getDashboardData', fn (e &ui.Event) string {
		return get_dashboard_data_handler()
	})

	// Error management endpoints
	w.bind('getErrorStats', fn (e &ui.Event) string {
		vlog('Fetching error statistics...')
		stats := error.get_stats()
		return json.encode(stats)
	})

	w.bind('getRecentErrors', fn (e &ui.Event) string {
		vlog('Fetching recent errors...')
		limit := 10
		errors := error.get_errors(limit)
		return json.encode(errors)
	})

	w.bind('clearErrorHistory', fn (e &ui.Event) string {
		vlog('Clearing error history...')
		error.clear_errors()
		return '{"success": true}'
	})

	w.bind('logErrorMessage', fn (e &ui.Event) string {
		// Called from frontend to log messages to backend console
		return '{"success": true}'
	})

	vlog('All API handlers registered')
	vlog('Setting root folder: ${dist_path}')

	// Set root folder and show window
	ui.set_root_folder(dist_path)

	vlog('Opening window with index.html')
	w.show('index.html')!

	vlog('========================================')
	vlog('Application running')
	vlog('Press Ctrl+C to exit')
	vlog('========================================')

	// Wait for window to close
	ui.wait()

	vlog('Application exited')
}
