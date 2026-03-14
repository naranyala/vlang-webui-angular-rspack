module main

import vwebui as ui
import os
import json
import time
import system
import network
import process
import error
import events

const app_name = 'Desktop Dashboard'
const app_version = '1.0.0'

fn vlog(msg string) {
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	println('[${timestamp}] ${msg}')
}

fn main() {
	vlog('========================================')
	vlog('Starting ${app_name} v${app_version}...')
	vlog('========================================')
	vlog('Working directory: ${os.getwd()}')

	mut event_bus := events.new_event_bus()

	event_bus.subscribe('app:log', fn (event &events.Event) {
		println('[EVENT] ${event.name}: ${event.data}')
	})
	vlog('Event bus setup complete')

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

	mut w := ui.new_window()
	vlog('Window created successfully')

	vlog('Registering API handlers...')
	register_api_handlers(mut w, mut event_bus)
	vlog('All API handlers registered')

	ui.set_root_folder(dist_path)
	vlog('Setting root folder: ${dist_path}')

	vlog('Opening window with index.html')
	w.show('index.html')!

	vlog('========================================')
	vlog('Application running')
	vlog('Press Ctrl+C to exit')
	vlog('========================================')

	event_bus.publish('app:started', '${app_name} v${app_version}', 'main')

	ui.wait()

	vlog('Application exited')

	event_bus.publish('app:stopped', 'Application closed', 'main')

	event_bus.print_debug()
}

fn register_api_handlers(mut w ui.Window, mut event_bus events.EventBus) {
	w.bind('getSystemInfo', fn [event_bus] (e &ui.Event) string {
		vlog('Fetching system information...')
		info := system.get_system_info()
		event_bus.publish('system:info', 'System info fetched', 'api')
		return json.encode(info)
	})

	w.bind('getMemoryInfo', fn [event_bus] (e &ui.Event) string {
		vlog('Fetching memory information...')
		memory := system.get_memory_info()
		event_bus.publish('system:memory', 'Memory info fetched', 'api')
		return json.encode(memory)
	})

	w.bind('getCPUInfo', fn (e &ui.Event) string {
		vlog('Fetching CPU information...')
		cpu := system.get_cpu_info()
		return json.encode(cpu)
	})

	w.bind('getDiskInfo', fn (e &ui.Event) string {
		vlog('Fetching disk information...')
		disks := system.get_all_disk_info()
		return json.encode(disks)
	})

	w.bind('getNetworkInfo', fn (e &ui.Event) string {
		vlog('Fetching network information...')
		interfaces := network.get_network_interfaces()
		return json.encode(interfaces)
	})

	w.bind('getConnectionStatus', fn (e &ui.Event) string {
		vlog('Checking connection status...')
		status := network.get_connection_status()
		return json.encode(status)
	})

	w.bind('getNetworkStats', fn (e &ui.Event) string {
		vlog('Fetching network statistics...')
		stats := network.get_network_stats()
		return json.encode(stats)
	})

	w.bind('getProcessInfo', fn (e &ui.Event) string {
		vlog('Fetching process information...')
		mut processes := process.get_all_processes()
		if processes.len > 100 {
			processes = processes[..].clone()[..100]
		}
		return json.encode(processes)
	})

	w.bind('getSystemLoad', fn (e &ui.Event) string {
		vlog('Fetching system load...')
		load := process.get_system_load()
		return json.encode(load)
	})

	w.bind('getProcessStats', fn (e &ui.Event) string {
		vlog('Fetching process statistics...')
		stats := process.get_process_stats()
		return json.encode(stats)
	})

	w.bind('getDashboardData', fn [event_bus] (e &ui.Event) string {
		vlog('Fetching complete dashboard data...')
		data := system.get_system_info()
		event_bus.publish('dashboard:update', 'Dashboard data fetched', 'api')
		return json.encode(data)
	})

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

	w.bind('clearErrorHistory', fn [event_bus] (e &ui.Event) string {
		vlog('Clearing error history...')
		error.clear_errors()
		event_bus.publish('errors:cleared', 'Error history cleared', 'api')
		return '{"success": true}'
	})
}
