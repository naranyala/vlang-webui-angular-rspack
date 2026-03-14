module services

// IService is the base interface for all services
pub interface IService {
	mut:
		init() bool
		dispose()
		name() string
		is_initialized() bool
}

// ILogger interface for logging services
pub interface ILogger {
	mut:
		debug(message string)
		info(message string)
		warn(message string)
		error(message string)
		fatal(message string)
		log(level string, message string)
		set_min_level(level string)
		get_min_level() string
}

// IConfig interface for configuration services
pub interface IConfig {
	mut:
		get(key string) ?string
		get_string(key string, default string) string
		get_int(key string, default int) int
		get_bool(key string, default bool) bool
		get_float(key string, default f64) f64
		set(key string, value string)
		has(key string) bool
		load_from_env() bool
		load_from_file(path string) bool
		save_to_file(path string) bool
		get_all() map[string]string
}

// ICache interface for caching services
pub interface ICache {
	mut:
		get(key string) ?string
		set(key string, value string, ttl_seconds int) bool
		delete(key string) bool
		has(key string) bool
		clear()
		keys() []string
		count() int
		cleanup_expired() int
}

// IDatabase interface for database services
pub interface IDatabase {
	mut:
		connect() bool
		disconnect()
		is_connected() bool
		execute(query string, params []string) bool
		query(query string, params []string) []map[string]string
		query_one(query string, params []string) ?map[string]string
		insert(table string, data map[string]string) ?int
		update(table string, data map[string]string, where string) bool
		delete(table string, where string) bool
		table_exists(table_name string) bool
		get_last_error() string
}

// IHttpClient interface for HTTP client services
pub interface IHttpClient {
	mut:
		get(url string, headers map[string]string) ?HttpResponse
		post(url string, body string, headers map[string]string) ?HttpResponse
		put(url string, body string, headers map[string]string) ?HttpResponse
		delete_req(url string, headers map[string]string) ?HttpResponse
		set_timeout(milliseconds int)
		set_base_url(url string)
		add_header(key string, value string)
		remove_header(key string)
		clear_headers()
}

// HttpResponse represents an HTTP response
pub struct HttpResponse {
pub mut:
	status_code int
	body        string
	headers     map[string]string
	success     bool
	error       string
}

// IEventBus interface for event pub/sub
pub interface IEventBus {
	mut:
		subscribe(event_name string, handler fn (&Event))
		publish(event_name string, data string, source string)
		unsubscribe(event_name string, handler fn (&Event))
		clear(event_name string)
		subscriber_count(event_name string) int
}

// Event data structure (shared with events module)
pub struct Event {
pub mut:
	name      string
	data      string
	timestamp u64
	source    string
}

// IValidationService interface for input validation
pub interface IValidationService {
mut:
	add_rule(field string, rule string)
	validate(data map[string]string) ValidationResult
	is_valid(data map[string]string) bool
	get_errors() []ValidationError
	clear_rules()
}

// ValidationResult holds validation outcome
pub struct ValidationResult {
pub mut:
	is_valid bool
	errors   []ValidationError
}

// ValidationError represents a single validation error
pub struct ValidationError {
pub mut:
	field   string
	rule    string
	message string
}

// IMetricsService interface for application metrics
pub interface IMetricsService {
mut:
	increment_counter(name string, value int)
	record_gauge(name string, value f64)
	record_histogram(name string, value f64)
	record_timing(name string, duration_ms f64)
	get_counter(name string) int
	get_gauge(name string) f64
	get_histogram(name string) HistogramData
	reset()
	get_all_metrics() map[string]MetricData
}

// HistogramData holds histogram statistics
pub struct HistogramData {
pub mut:
	count int
	sum   f64
	min   f64
	max   f64
	avg   f64
}

// MetricData holds generic metric data
pub struct MetricData {
pub mut:
	name       string
	value      f64
	count      int
	last_updated u64
}

// IAuthService interface for authentication/authorization
pub interface IAuthService {
mut:
	authenticate(username string, password string) ?AuthResult
	validate_token(token string) ?AuthResult
	generate_token(user_id string, roles []string) string
	revoke_token(token string) bool
	get_current_user() ?UserInfo
	has_permission(permission string) bool
	has_role(role string) bool
	logout()
}

// AuthResult holds authentication result
pub struct AuthResult {
pub mut:
	success    bool
	user_id    string
	username   string
	roles      []string
	permissions []string
	token      string
	expires_at u64
	error      string
}

// UserInfo holds user information
pub struct UserInfo {
pub mut:
	id          string
	username    string
	email       string
	roles       []string
	permissions []string
	created_at  u64
	last_login  u64
}

// IHealthCheck interface for health monitoring
pub interface IHealthCheck {
mut:
	register_check(name string, check_fn fn () HealthStatus)
	remove_check(name string)
	run_all_checks() map[string]HealthStatus
	run_check(name string) ?HealthStatus
	is_healthy() bool
	get_status() HealthSummary
}

// HealthStatus represents the status of a health check
pub struct HealthStatus {
pub mut:
	name       string
	is_healthy bool
	status     string
	message    string
	duration_ms f64
	timestamp  u64
	details    map[string]string
}

// HealthSummary provides overall health status
pub struct HealthSummary {
pub mut:
	is_healthy      bool
	total_checks    int
	healthy_checks  int
	unhealthy_checks int
	status          string
	checks          map[string]HealthStatus
}
