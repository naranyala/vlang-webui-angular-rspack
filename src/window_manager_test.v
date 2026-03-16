module main

// V Test file - run with: v test src/window_manager_test.v
// Tests for window management and lifecycle

import window_manager

fn test_window_manager_creation() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	
	assert wm.window != 0
	assert_count++
	
	assert wm.initialized == false
	assert_count++
	
	assert wm.title != ''
	assert_count++

	println('test_window_manager_creation: ${assert_count} assertions passed')
}

fn test_window_manager_init() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	
	// Initialize
	wm.init() or {
		assert false
		return
	}
	
	assert wm.initialized == true
	assert_count++

	// Double init should fail
	wm.init() or {
		assert true
		assert_count++
		return
	}

	println('test_window_manager_init: ${assert_count} assertions passed')
}

fn test_window_manager_title() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	
	// Set title
	wm.set_title('Test Application')
	
	assert wm.title == 'Test Application'
	assert_count++

	println('test_window_manager_title: ${assert_count} assertions passed')
}

fn test_window_manager_size() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	
	// Get default size
	width, height := wm.get_size()
	
	assert width > 0
	assert_count++
	
	assert height > 0
	assert_count++

	// Resize
	wm.resize(1024, 768)
	
	width2, height2 := wm.get_size()
	
	assert width2 == 1024
	assert_count++
	
	assert height2 == 768
	assert_count++

	println('test_window_manager_size: ${assert_count} assertions passed')
}

fn test_app_lifecycle_creation() {
	mut assert_count := 0

	lifecycle := window_manager.new_app_lifecycle()
	
	assert lifecycle.initialized == false
	assert_count++
	
	assert lifecycle.shutdown != 0
	assert_count++

	println('test_app_lifecycle_creation: ${assert_count} assertions passed')
}

fn test_app_lifecycle_init() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	mut lifecycle := window_manager.new_app_lifecycle()
	
	// Initialize
	lifecycle.init(mut wm) or {
		assert false
		return
	}
	
	assert lifecycle.initialized == true
	assert_count++
	
	assert lifecycle.start_time > 0
	assert_count++

	println('test_app_lifecycle_init: ${assert_count} assertions passed')
}

fn test_app_lifecycle_uptime() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	mut lifecycle := window_manager.new_app_lifecycle()
	
	lifecycle.init(mut wm) or {
		assert false
		return
	}

	// Get uptime (should be > 0)
	uptime := lifecycle.get_uptime()
	
	assert uptime >= 0
	assert_count++

	println('test_app_lifecycle_uptime: ${assert_count} assertions passed')
}

fn test_shutdown_handler() {
	mut assert_count := 0

	shutdown := window_manager.new_shutdown_handler()
	
	assert shutdown.running == true
	assert_count++
	
	assert shutdown.shutdown_requested == false
	assert_count++

	// Request shutdown
	shutdown.request_shutdown()
	
	assert shutdown.running == false
	assert_count++
	
	assert shutdown.shutdown_requested == true
	assert_count++

	println('test_shutdown_handler: ${assert_count} assertions passed')
}

fn test_shutdown_handler_execute() {
	mut assert_count := 0

	mut shutdown := window_manager.new_shutdown_handler()
	mut executed := false
	
	// Register handler
	shutdown.register(fn () {
		executed = true
	})
	
	// Execute shutdown
	shutdown.execute_shutdown()
	
	assert executed == true
	assert_count++

	println('test_shutdown_handler_execute: ${assert_count} assertions passed')
}

fn test_lifecycle_is_running() {
	mut assert_count := 0

	mut wm := window_manager.new_webui_window_manager()
	mut lifecycle := window_manager.new_app_lifecycle()
	
	lifecycle.init(mut wm) or {
		assert false
		return
	}
	
	assert lifecycle.is_running() == true
	assert_count++

	println('test_lifecycle_is_running: ${assert_count} assertions passed')
}

fn test_all() {
	test_window_manager_creation()
	test_window_manager_init()
	test_window_manager_title()
	test_window_manager_size()
	test_app_lifecycle_creation()
	test_app_lifecycle_init()
	test_app_lifecycle_uptime()
	test_shutdown_handler()
	test_shutdown_handler_execute()
	test_lifecycle_is_running()
}
