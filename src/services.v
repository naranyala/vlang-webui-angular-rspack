module main

import os
import time
import json

// ============================================================================
// Minimal Services for V 0.5.1 Compatibility
// ============================================================================

// ConfigService
pub struct ConfigService {
pub mut:
	config      map[string]string
	env_prefix  string
	initialized bool
}

pub fn new_config_service() &ConfigService {
	return &ConfigService{
		config: map[string]string{}
		env_prefix: 'APP_'
	}
}

pub fn (mut s ConfigService) init() bool {
	s.load_from_env()
	s.initialized = true
	return true
}

pub fn (s ConfigService) get_string(key string, default string) string {
	return s.config[key] or { default }
}

pub fn (mut s ConfigService) set(key string, value string) {
	s.config[key] = value
}

pub fn (mut s ConfigService) load_from_env() bool {
	env_vars := os.environ()
	for _, env in env_vars {
		idx := env.index('=') or { continue }
		if idx > 0 {
			key := env[0..idx]
			value := env[idx+1..]
			if key.starts_with(s.env_prefix) {
				config_key := key[s.env_prefix.len..].to_lower()
				s.config[config_key] = value
			}
		}
	}
	return true
}

// LoggerService
pub struct LoggerService {
pub mut:
	min_level      string
	log_to_console bool
}

pub fn new_logger_service() &LoggerService {
	return &LoggerService{
		min_level: 'info'
		log_to_console: true
	}
}

pub fn (s LoggerService) init() bool { return true }
pub fn (s LoggerService) info(msg string) { if s.log_to_console { println(msg) } }
pub fn (s LoggerService) error(msg string) { if s.log_to_console { println('ERROR: ' + msg) } }

// CacheService
pub struct CacheService {
pub mut:
	cache       map[string]CacheEntry
	initialized bool
}

pub struct CacheEntry {
pub mut:
	value      string
	expires_at u64
}

pub fn new_cache_service() &CacheService {
	return &CacheService{
		cache: map[string]CacheEntry{}
	}
}

pub fn (mut s CacheService) init() bool { s.initialized = true; return true }
pub fn (mut s CacheService) dispose() { s.cache = map[string]CacheEntry{} }

// ValidationService (simplified)
pub struct ValidationService {
pub mut:
	initialized bool
}

pub fn new_validation_service() &ValidationService {
	return &ValidationService{}
}

pub fn (mut s ValidationService) init() bool { s.initialized = true; return true }
pub fn (s ValidationService) dispose() {}

// ============================================================================
// SQLite Service (File-based JSON storage)
// ============================================================================

pub struct User {
pub mut:
	id          int
	name        string
	email       string
	age         int
	created_at  string
}

pub struct UserStats {
pub mut:
	total_users    int
	today_count    int
	unique_domains int
}

pub struct SqliteService {
pub mut:
	initialized bool
	db_path     string
	db          UserDatabase
}

pub struct UserDatabase {
pub mut:
	users     []User
	next_id   int
}

pub fn new_sqlite_service(db_path string) !&SqliteService {
	mut s := &SqliteService{
		initialized: false
		db_path: db_path
		db: UserDatabase{ users: [], next_id: 1 }
	}
	if os.exists(db_path) {
		data := os.read_file(db_path) or {
			s.insert_demo_data()
			s.initialized = true
			return s
		}
		mut db := json.decode(UserDatabase, data) or {
			s.insert_demo_data()
			s.initialized = true
			return s
		}
		s.db = db
	} else {
		s.insert_demo_data()
	}
	s.initialized = true
	return s
}

pub fn (s SqliteService) init() bool { return s.initialized }
pub fn (s SqliteService) dispose() {}

fn (mut s SqliteService) insert_demo_data() {
	s.db.users = [
		User{id: s.db.next_id, name: 'John Doe', email: 'john@example.com', age: 28, created_at: time.now().str()},
		User{id: s.db.next_id+1, name: 'Jane Smith', email: 'jane@gmail.com', age: 34, created_at: time.now().str()},
		User{id: s.db.next_id+2, name: 'Bob Wilson', email: 'bob@company.org', age: 45, created_at: time.now().str()},
	]
	s.db.next_id += 3
}

pub fn (s SqliteService) get_all_users() []User {
	mut users := s.db.users.clone()
	users.reverse()
	return users
}

pub fn (mut s SqliteService) create_user(name string, email string, age int) !User {
	if !email.contains('@') {
		return error('Invalid email')
	}
	user := User{
		id: s.db.next_id
		name: name
		email: email
		age: age
		created_at: time.now().str()
	}
	s.db.next_id++
	s.db.users << user
	return user
}

pub fn (mut s SqliteService) update_user(id int, name string, email string, age int) !User {
	for i, user in s.db.users {
		if user.id == id {
			s.db.users[i].name = name
			s.db.users[i].email = email
			s.db.users[i].age = age
			return s.db.users[i]
		}
	}
	return error('User not found')
}

pub fn (mut s SqliteService) delete_user(id int) ! {
	mut found := false
	mut new_users := []User{}
	for user in s.db.users {
		if user.id == id {
			found = true
			continue
		}
		new_users << user
	}
	if !found {
		return error('User not found')
	}
	s.db.users = new_users
}

pub fn (s SqliteService) get_stats() UserStats {
	return UserStats{
		total_users: s.db.users.len
		today_count: 0
		unique_domains: 1
	}
}
