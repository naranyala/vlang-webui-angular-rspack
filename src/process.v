module process

import os
import time

// ProcessInfo contains information about a running process
pub struct ProcessInfo {
mut:
	pid          int
	ppid         int
	name         string
	cmdline      string
	status       string
	user         string
	cpu_percent  f64
	memory_percent f64
	memory_rss   u64
	memory_vms   u64
	threads      int
	created      u64
	nice         int
}

// SystemLoad contains system load information
pub struct SystemLoad {
mut:
	load_avg_1     f64
	load_avg_5     f64
	load_avg_15    f64
	running_procs  int
	total_procs    int
	last_pid       int
}

// ProcessStats contains process statistics
pub struct ProcessStats {
mut:
	total_processes    int
	running_processes  int
	sleeping_processes int
	zombie_processes   int
	stopped_processes  int
}

// GetProcessInfo returns information about a specific process
pub fn get_process_info(pid int) !ProcessInfo {
	proc_path := '/proc/${pid}'
	if !os.is_dir(proc_path) {
		return error('Process not found')
	}

	mut proc := ProcessInfo{
		pid: pid
	}

	// Read process name from comm
	comm_path := os.join_path(proc_path, 'comm')
	if os.is_file(comm_path) {
		proc.name = os.read_file(comm_path) or { 'unknown' }
		proc.name = proc.name.trim_space()
	}

	// Read detailed info from stat
	stat_path := os.join_path(proc_path, 'stat')
	if os.is_file(stat_path) {
		content := os.read_file(stat_path) or { '' }
		parse_proc_stat(content, mut proc)
	}

	// Read command line
	cmdline_path := os.join_path(proc_path, 'cmdline')
	if os.is_file(cmdline_path) {
		cmdline := os.read_file(cmdline_path) or { '' }
		proc.cmdline = cmdline.replace('\x00', ' ').trim_space()
	}

	// Read memory info
	status_path := os.join_path(proc_path, 'status')
	if os.is_file(status_path) {
		content := os.read_file(status_path) or { '' }
		parse_proc_status(content, mut proc)
	}

	// Get process state
	state_path := os.join_path(proc_path, 'stat')
	if os.is_file(state_path) {
		content := os.read_file(state_path) or { '' }
		proc.status = get_process_state(content)
	}

	return proc
}

// GetAllProcesses returns information about all running processes
pub fn get_all_processes() []ProcessInfo {
	mut processes := []ProcessInfo{}

	// List all numeric directories in /proc (these are PIDs)
	proc_entries := os.ls('/proc') or { return processes }
	for entry in proc_entries {
		// Check if entry is a number (PID)
		if !entry[0].is_digit() {
			continue
		}
		pid := entry.int()
		proc := get_process_info(pid) or { continue }
		processes << proc
	}

	return processes
}

// GetProcessStats returns statistics about all processes
pub fn get_process_stats() ProcessStats {
	mut stats := ProcessStats{}

	processes := get_all_processes()
	stats.total_processes = processes.len

	for proc in processes {
		match proc.status {
			'Running', 'R' { stats.running_processes++ }
			'Sleeping', 'S', 'D' { stats.sleeping_processes++ }
			'Zombie', 'Z' { stats.zombie_processes++ }
			'Stopped', 'T' { stats.stopped_processes++ }
			else {}
		}
	}

	return stats
}

// GetSystemLoad returns system load information
pub fn get_system_load() SystemLoad {
	mut load := SystemLoad{}

	// Read from /proc/loadavg
	loadavg_path := '/proc/loadavg'
	if os.is_file(loadavg_path) {
		content := os.read_file(loadavg_path) or { return load }
		parts := content.trim_space().split(' ')

		if parts.len >= 1 {
			load.load_avg_1 = parts[0].f64()
		}
		if parts.len >= 2 {
			load.load_avg_5 = parts[1].f64()
		}
		if parts.len >= 3 {
			load.load_avg_15 = parts[2].f64()
		}
		if parts.len >= 4 {
			// Running/Total processes
			rt := parts[3].split('/')
			if rt.len >= 2 {
				load.running_procs = rt[0].int()
				load.total_procs = rt[1].int()
			}
		}
		if parts.len >= 5 {
			load.last_pid = parts[4].int()
		}
	}

	return load
}

// KillProcess terminates a process
pub fn kill_process(pid int, signal string) bool {
	sig := match signal {
		'SIGTERM', 'TERM', 'term' { 15 }
		'SIGKILL', 'KILL', 'kill' { 9 }
		'SIGHUP', 'HUP', 'hup' { 1 }
		'SIGINT', 'INT', 'int' { 2 }
		'SIGUSR1', 'USR1', 'usr1' { 10 }
		'SIGUSR2', 'USR2', 'usr2' { 12 }
		else { 15 } // Default to SIGTERM
	}

	cmd := 'kill -${sig} ${pid} 2>&1'
	result := os.execute(cmd)
	return result.exit_code == 0
}

// KillProcessByName terminates all processes with a given name
pub fn kill_process_by_name(name string, signal string) int {
	mut killed := 0

	processes := get_all_processes()
	for proc in processes {
		if proc.name == name || proc.cmdline.contains(name) {
			if kill_process(proc.pid, signal) {
				killed++
			}
		}
	}

	return killed
}

// FindProcessesByName finds processes matching a name pattern
pub fn find_processes_by_name(pattern string) []ProcessInfo {
	mut results := []ProcessInfo{}

	processes := get_all_processes()
	for proc in processes {
		if proc.name.contains(pattern) || proc.cmdline.contains(pattern) {
			results << proc
		}
	}

	return results
}

// GetProcessChildren returns child processes of a given process
pub fn get_process_children(pid int) []ProcessInfo {
	mut children := []ProcessInfo{}

	processes := get_all_processes()
	for proc in processes {
		if proc.ppid == pid {
			children << proc
		}
	}

	return children
}

// GetProcessTree returns the process tree for a given PID
pub fn get_process_tree(pid int) []ProcessInfo {
	mut tree := []ProcessInfo{}

	proc := get_process_info(pid) or { return tree }
	tree << proc

	// Add children recursively
	children := get_process_children(pid)
	for child in children {
		child_tree := get_process_tree(child.pid)
		tree << child_tree
	}

	return tree
}

// StartProcess starts a new process
pub fn start_process(command string, args []string) ProcessResult {
	mut full_cmd := command
	for arg in args {
		full_cmd += ' ' + arg
	}

	result := os.execute(full_cmd)
	return ProcessResult{
		exit_code: result.exit_code
		output: result.output
		stderr: result.output // Simplified
	}
}

// StartProcessBackground starts a process in the background
pub fn start_process_background(command string, args []string) int {
	mut full_cmd := command
	for arg in args {
		full_cmd += ' ' + arg
	}

	// Run in background with nohup
	background_cmd := 'nohup ${full_cmd} > /dev/null 2>&1 &'
	result := os.execute(background_cmd)

	if result.exit_code == 0 {
		// Try to get the PID of the last background process
		return get_last_pid()
	}
	return -1
}

// ProcessResult contains the result of a process execution
pub struct ProcessResult {
	exit_code int
	output    string
	stderr    string
	duration_ms int
}

// GetTopProcesses returns the top N processes by CPU or memory usage
pub fn get_top_processes(n int, by string) []ProcessInfo {
	mut processes := get_all_processes()

	// Sort by CPU or memory (simplified - just take first N)
	if by == 'cpu' || by == 'memory' || by == 'mem' {
		// In production, implement proper sorting
	}

	mut result := []ProcessInfo{}
	for i, proc in processes {
		if i >= n {
			break
		}
		result << proc
	}

	return result
}

// GetProcessCount returns the total number of running processes
pub fn get_process_count() int {
	proc_entries := os.ls('/proc') or { return 0 }
	mut count := 0
	for entry in proc_entries {
		// Check if entry is a number (PID)
		if entry[0].is_digit() {
			count++
		}
	}
	return count
}

// Helper functions

fn parse_proc_stat(content string, mut proc ProcessInfo) {
	// Format: pid (comm) state ppid pgrp session tty_nr tpgid flags minflt cminflt majflt cmajflt
	// utime stime cutime cstime priority nice num_threads itrealvalue starttime vsize rss ...

	// Extract name from parentheses
	start := content.index('(') or { return }
	end := content.index(')') or { return }
	if start < end {
		proc.name = content[start+1..end]
	}

	// Parse fields after the name
	after_name := content[end+1..].trim_space()
	fields := after_name.split(' ')

	if fields.len >= 20 {
		proc.status = fields[0]
		proc.ppid = fields[1].int()
		proc.threads = fields[17].int()
	}

	if fields.len >= 20 {
		// Calculate CPU time (simplified)
		utime := fields[10].u64()
		stime := fields[11].u64()
		// CPU percent would need delta calculation over time
		proc.cpu_percent = f64(utime + stime) / 100.0
	}
}

fn parse_proc_status(content string, mut proc ProcessInfo) {
	lines := content.split('\n')
	for line in lines {
		line_parts := line.split(':')
		if line_parts.len < 2 {
			continue
		}
		key := line_parts[0].trim_space()
		value := line_parts[1].trim_space()

		match key {
			'VmRSS' {
				val_parts := value.split(' ')
				if val_parts.len > 0 {
					kb := val_parts[0].u64()
					proc.memory_rss = kb * 1024
				}
			}
			'VmSize' {
				val_parts := value.split(' ')
				if val_parts.len > 0 {
					kb := val_parts[0].u64()
					proc.memory_vms = kb * 1024
				}
			}
			'Uid' {
				val_parts := value.split(' ')
				if val_parts.len > 0 {
					proc.user = val_parts[0]
				}
			}
			'Nice' {
				proc.nice = value.int()
			}
			else {}
		}
	}
}

fn get_process_state(content string) string {
	// Extract state character from stat file
	// State is typically after the closing parenthesis
	end := content.index(')') or { return 'Unknown' }
	if end + 2 < content.len {
		state_char := content[end + 2]
		return match state_char {
			`R` { 'Running' }
			`S` { 'Sleeping' }
			`D` { 'Sleeping (disk)' }
			`Z` { 'Zombie' }
			`T` { 'Stopped' }
			`t` { 'Tracing stop' }
			`X` { 'Dead' }
			else { 'Unknown' }
		}
	}
	return 'Unknown'
}

fn get_last_pid() int {
	// Read from /proc/sys/kernel/pid_max or use stat
	stat_path := '/proc/stat'
	if os.is_file(stat_path) {
		content := os.read_file(stat_path) or { return 0 }
		for line in content.split('\n') {
			if line.starts_with('processes') {
				parts := line.split(' ')
				if parts.len > 1 {
					return parts[1].int()
				}
			}
		}
	}
	return 0
}

// Format process uptime
pub fn format_process_uptime(pid int) string {
	proc := get_process_info(pid) or { return 'Unknown' }
	if proc.created == 0 {
		return 'Unknown'
	}

	uptime := time.now().unix() - i64(proc.created)
	if uptime < 0 {
		return 'Unknown'
	}

	seconds := u64(uptime)
	days := seconds / 86400
	hours := (seconds % 86400) / 3600
	mins := (seconds % 3600) / 60

	if days > 0 {
		return '${days}d ${hours}h'
	} else if hours > 0 {
		return '${hours}h ${mins}m'
	} else {
		return '${mins}m'
	}
}
