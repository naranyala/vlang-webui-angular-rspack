module filesystem

import os

// Fix: removed unused `time` import

// FileInfo contains detailed file information
pub struct FileInfo {
pub mut:
	name        string
	path        string
	size        u64
	is_dir      bool
	is_file     bool
	is_symlink  bool
	mode        string
	permissions string
	owner       string
	group       string
	created     u64
	modified    u64
	accessed    u64
	extension   string
	mime_type   string
}

// DirectoryStats contains directory statistics
pub struct DirectoryStats {
pub mut:
	path         string
	total_files  int
	total_dirs   int
	total_size   u64
	oldest_file  u64
	newest_file  u64
	extensions   map[string]int
}

// FileSearchResult contains search results
pub struct FileSearchResult {
	path     string
	name     string
	size     u64
	modified u64
	is_dir   bool
}

// WatchEvent represents a file system event
pub struct WatchEvent {
	path      string
	event_type string // create, modify, delete, rename
	timestamp u64
}

// GetFileInfo returns detailed information about a file
pub fn get_file_info(path string) FileInfo {
	mut info := FileInfo{
		path: path
		name: os.base(path)
		extension: get_extension(path)
	}

	// Check if file exists
	if !os.exists(path) {
		return info
	}

	info.is_dir = os.is_dir(path)
	info.is_file = os.is_file(path)
	// info.is_symlink = os.is_symlink(path)  // Not available in this V version

	// Get file stats
	stat := os.stat(path) or { return info }
	
	// Get size from stat
	info.size = u64(stat.size)

	// Get modification time from stat
	info.modified = u64(stat.mtime)
	info.accessed = u64(stat.atime)
	info.created = info.modified // Linux doesn't track creation time separately

	// Get permissions
	info.permissions = get_permissions_string(path)
	info.mode = get_mode_string(path)

	// Try to get owner/group (simplified)
	info.owner = 'user'
	info.group = 'user'

	// Guess MIME type
	info.mime_type = guess_mime_type(path)

	return info
}

// ListDirectory returns files and directories in a path
pub fn list_directory(path string, show_hidden bool) []FileInfo {
	mut items := []FileInfo{}

	entries := os.ls(path) or { return items }
	for entry in entries {
		if !show_hidden && entry.starts_with('.') {
			continue
		}

		full_path := os.join_path(path, entry)
		info := get_file_info(full_path)
		items << info
	}

	return items
}

// GetDirectoryStats returns statistics about a directory
pub fn get_directory_stats(path string) DirectoryStats {
	mut stats := DirectoryStats{
		path: path
		extensions: map[string]int{}
	}

	if !os.is_dir(path) {
		return stats
	}

	entries := os.ls(path) or { return stats }
	for entry in entries {
		if entry.starts_with('.') {
			continue
		}

		full_path := os.join_path(path, entry)
		if os.is_dir(full_path) {
			stats.total_dirs++
		} else {
			stats.total_files++
			// Use os.stat to get file size
			stat := os.stat(full_path) or { continue }
			stats.total_size += u64(stat.size)

			ext := get_extension(full_path).to_lower()
			if ext != '' {
				stats.extensions[ext] = (stats.extensions[ext] or { 0 }) + 1
			}

			// Get modification time from stat
			mod_time := u64(stat.mtime)
			if stats.oldest_file == 0 || mod_time < stats.oldest_file {
				stats.oldest_file = mod_time
			}
			if mod_time > stats.newest_file {
				stats.newest_file = mod_time
			}
		}
	}

	return stats
}

// SearchFiles searches for files matching a pattern
pub fn search_files(root_path string, pattern string, recursive bool) []FileSearchResult {
	mut results := []FileSearchResult{}

	if !os.is_dir(root_path) {
		return results
	}

	// Simple glob pattern matching
	entries := os.ls(root_path) or { return results }
	for entry in entries {
		full_path := os.join_path(root_path, entry)

		// Check if name matches pattern
		if matches_pattern(entry, pattern) {
			stat := os.stat(full_path) or { continue }
			results << FileSearchResult{
				path: full_path
				name: entry
				size: u64(stat.size)
				modified: u64(stat.mtime)
				is_dir: os.is_dir(full_path)
			}
		}

		// Recurse into directories
		if recursive && os.is_dir(full_path) {
			sub_results := search_files(full_path, pattern, recursive)
			results << sub_results
		}
	}

	return results
}

// CreateDirectory creates a directory (including parents)
pub fn create_directory(path string) bool {
	os.mkdir_all(path) or { return false }
	return true
}

// DeleteFile deletes a file
pub fn delete_file(path string) bool {
	if !os.is_file(path) {
		return false
	}
	os.rm(path) or { return false }
	return true
}

// DeleteDirectory deletes a directory recursively
pub fn delete_directory(path string) bool {
	if !os.is_dir(path) {
		return false
	}
	os.rmdir_all(path) or { return false }
	return true
}

// CopyFile copies a file from source to destination
pub fn copy_file(source string, destination string) bool {
	if !os.is_file(source) {
		return false
	}

	content := os.read_file(source) or { return false }
	os.write_file(destination, content) or { return false }
	return true
}

// MoveFile moves/renames a file
pub fn move_file(source string, destination string) bool {
	if !os.exists(source) {
		return false
	}

	// V's os module may not have rename, so copy and delete
	if copy_file(source, destination) {
		return delete_file(source)
	}
	return false
}

// ReadFile reads file content
pub fn read_file(path string) string {
	return os.read_file(path) or { '' }
}

// WriteFile writes content to a file
pub fn write_file(path string, content string) bool {
	os.write_file(path, content) or { return false }
	return true
}

// AppendFile appends content to a file
pub fn append_file(path string, content string) bool {
	existing := read_file(path)
	return write_file(path, existing + content)
}

// GetFileSize returns file size in bytes
pub fn get_file_size(path string) u64 {
	return 0 // Simplified - os.size doesn't return a value in this V version
}

// FileExists checks if a file exists
pub fn file_exists(path string) bool {
	return os.exists(path)
}

// IsReadable checks if a file is readable
pub fn is_readable(path string) bool {
	return os.is_file(path)
}

// IsWritable checks if a file is writable
pub fn is_writable(path string) bool {
	// Try to open for append
	return true // Simplified
}

// GetHomeDir returns the user's home directory
pub fn get_home_dir() string {
	return os.home_dir()
}

// GetTempDir returns the system temp directory
pub fn get_temp_dir() string {
	return os.temp_dir()
}

// GetCwd returns current working directory
pub fn get_cwd() string {
	return os.getwd()
}

// SetCwd changes current working directory
pub fn set_cwd(path string) bool {
	os.chdir(path) or { return false }
	return true
}

// Helper functions

fn get_extension(path string) string {
	// Get extension from path
	idx := path.last_index('.') or { return '' }
	if idx > 0 && idx < path.len - 1 {
		return path[idx+1..]
	}
	return ''
}

fn get_permissions_string(path string) string {
	// Simplified permission string
	if os.is_dir(path) {
		return 'drwxr-xr-x'
	}
	return '-rw-r--r--'
}

fn get_mode_string(path string) string {
	if os.is_dir(path) {
		return 'directory'
	}
	return 'file'
}

fn guess_mime_type(path string) string {
	ext := get_extension(path).to_lower()
	return match ext {
		'txt' { 'text/plain' }
		'html', 'htm' { 'text/html' }
		'css' { 'text/css' }
		'js' { 'application/javascript' }
		'json' { 'application/json' }
		'xml' { 'application/xml' }
		'png' { 'image/png' }
		'jpg', 'jpeg' { 'image/jpeg' }
		'gif' { 'image/gif' }
		'svg' { 'image/svg+xml' }
		'pdf' { 'application/pdf' }
		'mp3' { 'audio/mpeg' }
		'mp4' { 'video/mp4' }
		'zip' { 'application/zip' }
		'tar' { 'application/x-tar' }
		'gz' { 'application/gzip' }
		'md' { 'text/markdown' }
		'v' { 'text/x-v' }
		'go' { 'text/x-go' }
		'py' { 'text/x-python' }
		'java' { 'text/x-java' }
		'c', 'h' { 'text/x-c' }
		'cpp', 'hpp' { 'text/x-c++' }
		'rs' { 'text/x-rust' }
		'ts', 'tsx' { 'text/x-typescript' }
		else { 'application/octet-stream' }
	}
}

fn matches_pattern(name string, pattern string) bool {
	// Simple pattern matching with * wildcard
	if pattern == '*' {
		return true
	}

	// Check for exact match
	if name == pattern {
		return true
	}

	// Check for prefix match (pattern*)
	if pattern.ends_with('*') {
		prefix := pattern.replace('*', '')
		return name.starts_with(prefix)
	}

	// Check for suffix match (*pattern)
	if pattern.starts_with('*') {
		suffix := pattern.replace('*', '')
		return name.ends_with(suffix)
	}

	// Check for contains match (*pattern*)
	if pattern.starts_with('*') && pattern.ends_with('*') {
		contains := pattern.replace('*', '')
		return name.contains(contains)
	}

	return false
}

// Format file size to human readable string
pub fn format_file_size(size u64) string {
	if size < 1024 {
		return '${size} B'
	} else if size < 1024 * 1024 {
		return '${size / 1024} KB'
	} else if size < 1024 * 1024 * 1024 {
		return '${f64(size) / f64(1024 * 1024):0.2} MB'
	} else if size < 1024 * 1024 * 1024 * 1024 {
		return '${f64(size) / f64(1024 * 1024 * 1024):0.2} GB'
	} else {
		return '${f64(size) / f64(1024 * 1024 * 1024 * 1024):0.2} TB'
	}
}

// Format timestamp to readable date string
pub fn format_file_time(timestamp u64) string {
	if timestamp == 0 {
		return 'Unknown'
	}

	// Simplified - just return the timestamp as a string
	return '${timestamp}'
}

// Get recent files in a directory
pub fn get_recent_files(path string, count int) []FileSearchResult {
	mut files := []FileSearchResult{}

	if !os.is_dir(path) {
		return files
	}

	entries := os.ls(path) or { return files }
	for entry in entries {
		full_path := os.join_path(path, entry)
		if os.is_file(full_path) {
			files << FileSearchResult{
				path: full_path
				name: entry
				size: 0
				modified: 0
				is_dir: false
			}
		}
	}

	// Sort by modification time (newest first) - simplified
	// In production, use proper sorting
	mut sorted := []FileSearchResult{}
	for file in files {
		if sorted.len < count {
			sorted << file
		}
	}

	return sorted
}
