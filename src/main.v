module main

import os
import time
import vwebui as ui
import window_manager
import json

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

	// Core services
	mut config := new_config_service()
	config.init()

	mut logger := new_logger_service()
	logger.init()

	mut cache := new_cache_service()
	cache.init()

	mut validation := new_validation_service()
	validation.init()

	// Database service
	mut db := new_sqlite_service('users.db') or {
		vlog('ERROR: Failed to initialize database')
		return
	}

	// DevTools service
	mut devtools := new_devtools_service()
	devtools.init()

	vlog('All services initialized')

	// Window Manager Setup
	mut window_mgr := window_manager.new_webui_window_manager()
	window_mgr.init() or {
		vlog('ERROR: Failed to initialize window manager')
		return
	}

	// Setup graceful shutdown
	mut lifecycle := window_manager.new_app_lifecycle()
	lifecycle.init(mut window_mgr) or {
		vlog('ERROR: Failed to initialize lifecycle')
		return
	}

	// Register cleanup handlers
	lifecycle.on_shutdown(fn [mut db, mut cache] () {
		vlog('Cleaning up services...')
		db.dispose()
		cache.dispose()
	})

	// Verify Frontend Build
	dist_path := 'frontend/dist/browser'
	if !os.is_dir(dist_path) {
		vlog('ERROR: Frontend dist not found at ${dist_path}')
		vlog('Please run: ./run.sh build')
		return
	}

	vlog('Frontend dist verified')

	// ============================================================================
	// API Handlers - Minimal working set for V 0.5.1
	// ============================================================================

	// User CRUD Handlers
	window_mgr.bind('getUsers', fn [db] (e &ui.Event) string {
		users := db.get_all_users()
		return '{"success":true,"data":${json.encode(users)}}'
	})

	window_mgr.bind('createUser', fn [mut db] (e &ui.Event) string {
		user_result := db.create_user('Demo User', 'demo@example.com', 25) or {
			return '{"success":false,"error":"${err.msg}"}'
		}
		return '{"success":true,"data":${json.encode(user_result)}}'
	})

	window_mgr.bind('updateUser', fn [mut db] (e &ui.Event) string {
		user_result := db.update_user(1, 'Updated User', 'updated@example.com', 30) or {
			return '{"success":false,"error":"${err.msg}"}'
		}
		return '{"success":true,"data":${json.encode(user_result)}}'
	})

	window_mgr.bind('deleteUser', fn [mut db] (e &ui.Event) string {
		db.delete_user(1) or {
			return '{"success":false,"error":"${err.msg}"}'
		}
		return '{"success":true,"message":"User deleted"}'
	})

	window_mgr.bind('getUserStats', fn [db] (e &ui.Event) string {
		stats := db.get_stats()
		return '{"success":true,"data":${json.encode(stats)}}'
	})

	// ============================================================================
	// DevTools API Handlers
	// ============================================================================

	// Get comprehensive devtools statistics
	window_mgr.bind('devtools.getStats', fn [mut devtools] (e &ui.Event) string {
		devtools.increment_request_count()
		stats := devtools.get_stats()
		return '{"success":true,"data":${json.encode(stats)}}'
	})

	// Get recent logs
	window_mgr.bind('devtools.getLogs', fn [devtools] (e &ui.Event) string {
		logs := devtools.get_logs()
		return '{"success":true,"data":${json.encode(logs)}}'
	})

	// Get error reports
	window_mgr.bind('devtools.getErrors', fn [devtools] (e &ui.Event) string {
		errors := devtools.get_errors()
		return '{"success":true,"data":${json.encode(errors)}}'
	})

	// Get performance metrics
	window_mgr.bind('devtools.getMetrics', fn [devtools] (e &ui.Event) string {
		metrics := devtools.get_metrics()
		return '{"success":true,"data":${json.encode(metrics)}}'
	})

	// Get application uptime
	window_mgr.bind('devtools.getUptime', fn [devtools] (e &ui.Event) string {
		uptime := devtools.get_uptime()
		return '{"success":true,"data":{"uptime":${uptime}}}'
	})

	// Log a message from frontend
	window_mgr.bind('devtools.log', fn [mut devtools] (e &ui.Event) string {
		// Parse log data from event
		devtools.log('info', 'Frontend log', 'devtools')
		return '{"success":true}'
	})

	// Report an error from frontend
	window_mgr.bind('devtools.reportError', fn [mut devtools] (e &ui.Event) string {
		// Parse error data from event
		devtools.report_error('FRONTEND_ERROR', 'Error from frontend', 'devtools')
		return '{"success":true}'
	})

	// Record a performance metric from frontend
	window_mgr.bind('devtools.recordMetric', fn [mut devtools] (e &ui.Event) string {
		// Parse metric data from event
		devtools.record_metric('frontend_metric', 0.0, 'ms')
		return '{"success":true}'
	})

	// Clear logs
	window_mgr.bind('devtools.clearLogs', fn [mut devtools] (e &ui.Event) string {
		devtools.logs = []LogEntry{}
		return '{"success":true}'
	})

	// Clear errors
	window_mgr.bind('devtools.clearErrors', fn [mut devtools] (e &ui.Event) string {
		devtools.errors = []ErrorReport{}
		return '{"success":true}'
	})

	// Window configuration
	window_mgr.set_title(app_name)

	vlog('========================================')
	vlog('Application running')
	vlog('Press Ctrl+C to exit')
	vlog('========================================')

	// Run with graceful shutdown
	lifecycle.run('index.html') or {
		vlog('ERROR: Application run failed')
	}

	vlog('Application closed')
}
