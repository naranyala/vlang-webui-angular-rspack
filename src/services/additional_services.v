module services

import os
import time
import json

// ==================== LoggerService (Enhanced) ====================

pub struct LoggerService {
pub mut:
	service_name   string
	min_level      string
	log_to_console bool
	log_to_file    bool
	log_file_path  string
	initialized    bool
	log_count      int
}

pub fn new_logger_service() &LoggerService {
	return &LoggerService{
		service_name: 'logger'
		min_level: 'info'
		log_to_console: true
		log_to_file: false
		log_file_path: ''
		initialized: false
		log_count: 0
	}
}

pub fn (s &LoggerService) init() bool {
	if s.initialized {
		return true
	}
	s.initialized = true
	return true
}

pub fn (s &LoggerService) dispose() {
	// Flush any buffered logs if needed
}

pub fn (s &LoggerService) name() string {
	return s.service_name
}

pub fn (s &LoggerService) is_initialized() bool {
	return s.initialized
}

pub fn (s &LoggerService) set_min_level(level string) {
	s.min_level = level
}

pub fn (s &LoggerService) get_min_level() string {
	return s.min_level
}

pub fn (s &LoggerService) enable_file_logging(path string) {
	s.log_to_file = true
	s.log_file_path = path
}

pub fn (s &LoggerService) disable_file_logging() {
	s.log_to_file = false
}

pub fn (s &LoggerService) log(level string, message string) {
	if !s.should_log(level) {
		return
	}
	
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	log_line := '[${timestamp}] [${level.to_upper()}] [${s.service_name}] ${message}'
	
	if s.log_to_console {
		println(log_line)
	}
	
	if s.log_to_file && s.log_file_path != '' {
		s.write_to_file(log_line)
	}
	
	s.log_count++
}

pub fn (s &LoggerService) debug(message string) {
	s.log('debug', message)
}

pub fn (s &LoggerService) info(message string) {
	s.log('info', message)
}

pub fn (s &LoggerService) warn(message string) {
	s.log('warn', message)
}

pub fn (s &LoggerService) error(message string) {
	s.log('error', message)
}

pub fn (s &LoggerService) fatal(message string) {
	s.log('fatal', message)
}

fn (s &LoggerService) should_log(level string) bool {
	levels := ['debug', 'info', 'warn', 'error', 'fatal']
	min_idx := levels.index(s.min_level) or { return true }
	log_idx := levels.index(level) or { return true }
	
	return log_idx >= min_idx
}

fn (s &LoggerService) write_to_file(line string) {
	os.append_file(s.log_file_path, line + '\n') or {}
}

pub fn (s &LoggerService) get_log_count() int {
	return s.log_count
}

pub fn (s &LoggerService) reset_log_count() {
	s.log_count = 0
}

// ==================== ValidationService ====================

pub struct ValidationRule {
pub mut:
	field   string
	rule    string
	message string
}

pub struct ValidationService {
pub mut:
	rules       []ValidationRule
	errors      []ValidationError
	initialized bool
}

pub fn new_validation_service() &ValidationService {
	return &ValidationService{
		rules: []ValidationRule{}
		errors: []ValidationError{}
		initialized: false
	}
}

pub fn (s &ValidationService) init() bool {
	if s.initialized {
		return true
	}
	s.initialized = true
	return true
}

pub fn (s &ValidationService) dispose() {
	s.clear_rules()
}

pub fn (s &ValidationService) name() string {
	return 'validation'
}

pub fn (s &ValidationService) is_initialized() bool {
	return s.initialized
}

pub fn (s &ValidationService) add_rule(field string, rule string) {
	mut message := 'Validation failed'
	
	// Parse rule and set default message
	if rule.starts_with('required') {
		message = '${field} is required'
	} else if rule.starts_with('min:') {
		parts := rule.split(':')
		if parts.len > 1 {
			message = '${field} must be at least ${parts[1]} characters'
		}
	} else if rule.starts_with('max:') {
		parts := rule.split(':')
		if parts.len > 1 {
			message = '${field} must be at most ${parts[1]} characters'
		}
	} else if rule.starts_with('email') {
		message = '${field} must be a valid email address'
	} else if rule.starts_with('numeric') {
		message = '${field} must be a number'
	} else if rule.starts_with('alpha') {
		message = '${field} must contain only letters'
	} else if rule.starts_with('alphanumeric') {
		message = '${field} must contain only letters and numbers'
	} else if rule.starts_with('regex:') {
		message = '${field} format is invalid'
	}
	
	s.rules << ValidationRule{
		field: field
		rule: rule
		message: message
	}
}

pub fn (s &ValidationService) add_rule_with_message(field string, rule string, message string) {
	s.rules << ValidationRule{
		field: field
		rule: rule
		message: message
	}
}

pub fn (s &ValidationService) validate(data map[string]string) ValidationResult {
	s.errors = []ValidationError{}
	
	for rule in s.rules {
		value := data[rule.field] or { '' }
		
		if !s.validate_rule(rule, value) {
			s.errors << ValidationError{
				field: rule.field
				rule: rule.rule
				message: rule.message
			}
		}
	}
	
	return ValidationResult{
		is_valid: s.errors.len == 0
		errors: s.errors.clone()
	}
}

pub fn (s &ValidationService) is_valid(data map[string]string) bool {
	result := s.validate(data)
	return result.is_valid
}

pub fn (s &ValidationService) get_errors() []ValidationError {
	return s.errors.clone()
}

pub fn (s &ValidationService) clear_rules() {
	s.rules = []ValidationRule{}
}

pub fn (s &ValidationService) clear_errors() {
	s.errors = []ValidationError{}
}

fn (s &ValidationService) validate_rule(rule ValidationRule, value string) bool {
	r := rule.rule
	
	// Required check
	if r == 'required' {
		return value.trim_space().len > 0
	}
	
	// Min length check
	if r.starts_with('min:') {
		parts := r.split(':')
		if parts.len > 1 {
			min_len := parts[1].int()
			return value.len >= min_len
		}
		return true
	}
	
	// Max length check
	if r.starts_with('max:') {
		parts := r.split(':')
		if parts.len > 1 {
			max_len := parts[1].int()
			return value.len <= max_len
		}
		return true
	}
	
	// Email validation
	if r == 'email' {
		return s.is_valid_email(value)
	}
	
	// Numeric check
	if r == 'numeric' {
		return s.is_numeric(value)
	}
	
	// Integer check
	if r == 'integer' {
		return s.is_integer(value)
	}
	
	// Alpha check (letters only)
	if r == 'alpha' {
		return s.is_alpha(value)
	}
	
	// Alphanumeric check
	if r == 'alphanumeric' {
		return s.is_alphanumeric(value)
	}
	
	// Regex check
	if r.starts_with('regex:') {
		// Simplified - in production would use actual regex
		return value.len > 0
	}
	
	// Custom function check
	if r.starts_with('fn:') {
		// Would call custom validation function
		return true
	}
	
	return true
}

fn (s &ValidationService) is_valid_email(email string) bool {
	// Simple email validation
	return email.contains('@') && email.contains('.') && email.len > 5
}

fn (s &ValidationService) is_numeric(value string) bool {
	if value.len == 0 {
		return false
	}
	
	// Try to parse as float
	_ = value.f64() or { return false }
	return true
}

fn (s &ValidationService) is_integer(value string) bool {
	if value.len == 0 {
		return false
	}
	
	// Try to parse as int
	_ = value.int() or { return false }
	return true
}

fn (s &ValidationService) is_alpha(value string) bool {
	for c in value {
		if !c.is_letter() {
			return false
		}
	}
	return value.len > 0
}

fn (s &ValidationService) is_alphanumeric(value string) bool {
	for c in value {
		if !c.is_letter() && !c.is_digit() {
			return false
		}
	}
	return value.len > 0
}

// ==================== MetricsService ====================

pub struct MetricsService {
pub mut:
	counters    map[string]int
	gauges      map[string]f64
	histograms  map[string]&HistogramData
	timings     map[string][]f64
	initialized bool
	start_time  u64
}

pub fn new_metrics_service() &MetricsService {
	return &MetricsService{
		counters: map[string]int{}
		gauges: map[string]f64{}
		histograms: map[string]&HistogramData{}
		timings: map[string][]f64{}
		initialized: false
		start_time: u64(time.now().unix())
	}
}

pub fn (s &MetricsService) init() bool {
	if s.initialized {
		return true
	}
	s.initialized = true
	return true
}

pub fn (s &MetricsService) dispose() {
	s.reset()
}

pub fn (s &MetricsService) name() string {
	return 'metrics'
}

pub fn (s &MetricsService) is_initialized() bool {
	return s.initialized
}

pub fn (s &MetricsService) increment_counter(name string, value int) {
	current := s.counters[name] or { 0 }
	s.counters[name] = current + value
}

pub fn (s &MetricsService) record_gauge(name string, value f64) {
	s.gauges[name] = value
}

pub fn (s &MetricsService) record_histogram(name string, value f64) {
	hist := s.histograms[name] or {
		s.histograms[name] = &HistogramData{
			count: 0
			sum: 0
			min: value
			max: value
			avg: value
		}
		hist = s.histograms[name]
	}
	
	hist.count++
	hist.sum += value
	if value < hist.min {
		hist.min = value
	}
	if value > hist.max {
		hist.max = value
	}
	hist.avg = hist.sum / f64(hist.count)
}

pub fn (s &MetricsService) record_timing(name string, duration_ms f64) {
	timings := s.timings[name] or { []f64{} }
	timings << duration_ms
	s.timings[name] = timings
}

pub fn (s &MetricsService) get_counter(name string) int {
	return s.counters[name] or { 0 }
}

pub fn (s &MetricsService) get_gauge(name string) f64 {
	return s.gauges[name] or { 0.0 }
}

pub fn (s &MetricsService) get_histogram(name string) HistogramData {
	hist := s.histograms[name] or {
		return HistogramData{
			count: 0
			sum: 0
			min: 0
			max: 0
			avg: 0
		}
	}
	
	return HistogramData{
		count: hist.count
		sum: hist.sum
		min: hist.min
		max: hist.max
		avg: hist.avg
	}
}

pub fn (s &MetricsService) reset() {
	s.counters = map[string]int{}
	s.gauges = map[string]f64{}
	s.histograms = map[string]&HistogramData{}
	s.timings = map[string][]f64{}
	s.start_time = u64(time.now().unix())
}

pub fn (s &MetricsService) get_all_metrics() map[string]MetricData {
	mut metrics := map[string]MetricData{}
	now := u64(time.now().unix())
	
	for name, value in s.counters {
		metrics[name] = MetricData{
			name: name
			value: f64(value)
			count: value
			last_updated: now
		}
	}
	
	for name, value in s.gauges {
		metrics[name] = MetricData{
			name: name
			value: value
			count: 1
			last_updated: now
		}
	}
	
	return metrics
}

pub fn (s &MetricsService) get_uptime_seconds() u64 {
	return u64(time.now().unix()) - s.start_time
}

pub fn (s &MetricsService) get_timing_stats(name string) TimingStats {
	timings := s.timings[name] or {
		return TimingStats{
			count: 0
			min: 0
			max: 0
			avg: 0
			total: 0
		}
	}
	
	if timings.len == 0 {
		return TimingStats{
			count: 0
			min: 0
			max: 0
			avg: 0
			total: 0
		}
	}
	
	mut stats := TimingStats{
		count: timings.len
		min: timings[0]
		max: timings[0]
		total: 0
	}
	
	for t in timings {
		stats.total += t
		if t < stats.min {
			stats.min = t
		}
		if t > stats.max {
			stats.max = t
		}
	}
	
	stats.avg = stats.total / f64(stats.count)
	
	return stats
}

pub struct TimingStats {
pub mut:
	count int
	min   f64
	max   f64
	avg   f64
	total f64
}

// ==================== HealthCheckService ====================

pub struct HealthCheckService {
pub mut:
	checks      map[string]fn () HealthStatus
	initialized bool
	last_run    u64
}

pub fn new_health_check_service() &HealthCheckService {
	return &HealthCheckService{
		checks: map[string]fn () HealthStatus
		initialized: false
		last_run: 0
	}
}

pub fn (s &HealthCheckService) init() bool {
	if s.initialized {
		return true
	}
	
	// Register default system health check
	s.register_check('system', fn () HealthStatus {
		return HealthStatus{
			name: 'system'
			is_healthy: true
			status: 'healthy'
			message: 'System is running'
			duration_ms: 0
			timestamp: u64(time.now().unix())
			details: map[string]string{}
		}
	})
	
	s.initialized = true
	return true
}

pub fn (s &HealthCheckService) dispose() {
	s.checks = map[string]fn () HealthStatus
}

pub fn (s &HealthCheckService) name() string {
	return 'health_check'
}

pub fn (s &HealthCheckService) is_initialized() bool {
	return s.initialized
}

pub fn (s &HealthCheckService) register_check(name string, check_fn fn () HealthStatus) {
	s.checks[name] = check_fn
}

pub fn (s &HealthCheckService) remove_check(name string) {
	delete s.checks, name
}

pub fn (s &HealthCheckService) run_all_checks() map[string]HealthStatus {
	mut results := map[string]HealthStatus{}
	
	for name, check_fn in s.checks {
		start := time.now().unix()
		status := check_fn()
		end := time.now().unix()
		
		status.duration_ms = f64(end - start) * 1000.0
		status.timestamp = u64(end)
		results[name] = status
	}
	
	s.last_run = u64(time.now().unix())
	
	return results
}

pub fn (s &HealthCheckService) run_check(name string) ?HealthStatus {
	check_fn := s.checks[name] or {
		return error('Check "${name}" not found')
	}
	
	start := time.now().unix()
	status := check_fn()
	end := time.now().unix()
	
	status.duration_ms = f64(end - start) * 1000.0
	status.timestamp = u64(end)
	
	return status
}

pub fn (s &HealthCheckService) is_healthy() bool {
	results := s.run_all_checks()
	
	for _, status in results {
		if !status.is_healthy {
			return false
		}
	}
	
	return true
}

pub fn (s &HealthCheckService) get_status() HealthSummary {
	results := s.run_all_checks()
	
	mut summary := HealthSummary{
		total_checks: results.len
		healthy_checks: 0
		unhealthy_checks: 0
		checks: results
	}
	
	for _, status in results {
		if status.is_healthy {
			summary.healthy_checks++
		} else {
			summary.unhealthy_checks++
		}
	}
	
	summary.is_healthy = summary.unhealthy_checks == 0
	summary.status = if summary.is_healthy { 'healthy' } else { 'unhealthy' }
	
	return summary
}

// ==================== AuthService (Basic Implementation) ====================

pub struct AuthService {
pub mut:
	users           map[string]UserInfo
	tokens          map[string]AuthResult
	current_user    &UserInfo
	initialized     bool
	token_expiry_sec int
}

pub fn new_auth_service() &AuthService {
	return &AuthService{
		users: map[string]UserInfo{}
		tokens: map[string]AuthResult{}
		current_user: 0
		initialized: false
		token_expiry_sec: 3600 // 1 hour default
	}
}

pub fn (s &AuthService) init() bool {
	if s.initialized {
		return true
	}
	s.initialized = true
	return true
}

pub fn (s &AuthService) dispose() {
	s.tokens = map[string]AuthResult{}
}

pub fn (s &AuthService) name() string {
	return 'auth'
}

pub fn (s &AuthService) is_initialized() bool {
	return s.initialized
}

pub fn (s &AuthService) register_user(username string, password string, email string) bool {
	if s.users.exists(username) {
		return false
	}
	
	now := u64(time.now().unix())
	s.users[username] = UserInfo{
		id: 'user_${now}'
		username: username
		email: email
		roles: ['user']
		permissions: ['read']
		created_at: now
		last_login: 0
	}
	
	return true
}

pub fn (s &AuthService) authenticate(username string, password string) ?AuthResult {
	user := s.users[username] or {
		return error('User not found')
	}
	
	// In production, verify password hash
	// For demo, accept any non-empty password
	if password.trim_space().len == 0 {
		return error('Invalid password')
	}
	
	// Generate token
	token := s.generate_token(user.id, user.roles)
	
	result := AuthResult{
		success: true
		user_id: user.id
		username: user.username
		roles: user.roles.clone()
		permissions: user.permissions.clone()
		token: token
		expires_at: u64(time.now().unix()) + u64(s.token_expiry_sec)
		error: ''
	}
	
	s.tokens[token] = result
	
	// Update last login
	user.last_login = u64(time.now().unix())
	s.users[username] = user
	
	return result
}

pub fn (s &AuthService) validate_token(token string) ?AuthResult {
	result := s.tokens[token] or {
		return error('Invalid token')
	}
	
	// Check expiration
	if u64(time.now().unix()) > result.expires_at {
		delete s.tokens, token
		return error('Token expired')
	}
	
	return result
}

pub fn (s &AuthService) generate_token(user_id string, roles []string) string {
	// Simple token generation (in production, use JWT or similar)
	now := u64(time.now().unix())
	return 'token_${user_id}_${now}'
}

pub fn (s &AuthService) revoke_token(token string) bool {
	_, exists := s.tokens[token]
	if exists {
		delete s.tokens, token
		return true
	}
	return false
}

pub fn (s &AuthService) get_current_user() ?UserInfo {
	if s.current_user == 0 {
		return error('No user logged in')
	}
	return s.current_user
}

pub fn (s &AuthService) set_current_user(username string) bool {
	user := s.users[username] or {
		return false
	}
	s.current_user = &user
	return true
}

pub fn (s &AuthService) has_permission(permission string) bool {
	if s.current_user == 0 {
		return false
	}
	
	for p in s.current_user.permissions {
		if p == permission {
			return true
		}
	}
	
	return false
}

pub fn (s &AuthService) has_role(role string) bool {
	if s.current_user == 0 {
		return false
	}
	
	for r in s.current_user.roles {
		if r == role {
			return true
		}
	}
	
	return false
}

pub fn (s &AuthService) logout() {
	s.current_user = 0
}

pub fn (s &AuthService) get_user(username string) ?UserInfo {
	return s.users[username]
}

pub fn (s &AuthService) add_role_to_user(username string, role string) bool {
	mut user := s.users[username] or {
		return false
	}
	
	for r in user.roles {
		if r == role {
			return true
		}
	}
	
	user.roles << role
	s.users[username] = user
	return true
}

pub fn (s &AuthService) add_permission_to_user(username string, permission string) bool {
	mut user := s.users[username] or {
		return false
	}
	
	for p in user.permissions {
		if p == permission {
			return true
		}
	}
	
	user.permissions << permission
	s.users[username] = user
	return true
}
