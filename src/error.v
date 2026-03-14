module error

import time
import json

// ============================================================================
// Error Types and Structures
// ============================================================================

// ErrorCode represents structured error codes
pub enum ErrorCode {
	// Database errors (1000-1999)
	db_connection_failed      = 1001
	db_query_failed           = 1002
	db_constraint_violation   = 1003
	db_not_found              = 1004
	db_already_exists         = 1005
	db_transaction_failed     = 1006
	
	// Configuration errors (2000-2999)
	config_not_found          = 2001
	config_invalid            = 2002
	config_missing_field      = 2003
	config_parse_error        = 2004
	
	// Data format errors (3000-3999)
	serialization_failed      = 3001
	deserialization_failed    = 3002
	invalid_format            = 3003
	encoding_error            = 3004
	decoding_error            = 3005
	
	// Validation errors (4000-4999)
	validation_failed         = 4001
	missing_required_field    = 4002
	invalid_field_value       = 4003
	field_too_short           = 4004
	field_too_long            = 4005
	invalid_email             = 4006
	invalid_phone             = 4007
	
	// Resource errors (5000-5999)
	resource_not_found        = 5001
	user_not_found            = 5002
	entity_not_found          = 5003
	file_not_found            = 5004
	directory_not_found       = 5005
	
	// System errors (6000-6999)
	internal_error            = 6001
	timeout_error             = 6002
	permission_denied         = 6003
	rate_limit_exceeded       = 6004
	service_unavailable       = 6005
	unsupported_operation     = 6006
	
	// Network errors (7000-7999)
	network_error             = 7001
	connection_refused        = 7002
	dns_resolution_failed     = 7003
	ssl_error                 = 7004
	
	// Plugin/Extension errors (8000-8999)
	plugin_error              = 8001
	plugin_not_found          = 8002
	plugin_load_failed        = 8003
	
	// Unknown error
	unknown                   = 9999
}

// ErrorSeverity indicates the severity level of an error
pub enum ErrorSeverity {
	info
	warning
	error
	critical
	fatal
}

// ErrorValue represents a structured error with full context
pub struct ErrorValue {
pub mut:
	code             ErrorCode
	message          string
	details          string
	field            string
	cause            string
	timestamp        u64
	source           string
	source_file      string
	source_line      int
	context          map[string]string
	stack_trace      []string
	severity         ErrorSeverity
	retryable        bool
	recovery_suggestion string
}

// ============================================================================
// Error Creation Functions
// ============================================================================

// New creates a basic error with code and message
pub fn new(code ErrorCode, message string) ErrorValue {
	return ErrorValue{
		code:      code
		message:   message
		timestamp: u64(time.now().unix())
		source:    'backend'
		context:   map[string]string{}
		severity:  .error
		retryable: false
	}
}

// Newf creates an error with formatted message
pub fn newf(code ErrorCode, format string, args ...string) ErrorValue {
	mut message := format
	for arg in args {
		idx := message.index('{}') or { break }
		if idx >= 0 {
			message = message[..idx] + arg + message[idx+2..]
		}
	}
	return new(code, message)
}

// With_details adds details to an error
pub fn with_details(code ErrorCode, message string, details string) ErrorValue {
	mut err := new(code, message)
	err.details = details
	return err
}

// With_field adds field context to an error
pub fn with_field(code ErrorCode, message string, field string) ErrorValue {
	mut err := new(code, message)
	err.field = field
	return err
}

// With_context adds context map to an error
pub fn with_context(code ErrorCode, message string, context map[string]string) ErrorValue {
	mut err := new(code, message)
	err.context = context.clone()
	return err
}

// With_severity sets the severity level
pub fn with_severity(code ErrorCode, message string, severity ErrorSeverity) ErrorValue {
	mut err := new(code, message)
	err.severity = severity
	return err
}

// With_source adds source location information
pub fn with_source(code ErrorCode, message string, source_file string, source_line int) ErrorValue {
	mut err := new(code, message)
	err.source_file = source_file
	err.source_line = source_line
	return err
}

// With_cause sets the underlying cause
pub fn with_cause(code ErrorCode, message string, cause string) ErrorValue {
	mut err := new(code, message)
	err.cause = cause
	return err
}

// Retryable marks an error as retryable
pub fn retryable(code ErrorCode, message string) ErrorValue {
	mut err := new(code, message)
	err.retryable = true
	return err
}

// With_recovery adds a recovery suggestion
pub fn with_recovery(code ErrorCode, message string, suggestion string) ErrorValue {
	mut err := new(code, message)
	err.recovery_suggestion = suggestion
	return err
}

// ============================================================================
// Specific Error Constructors - Database
// ============================================================================

pub fn db_error(operation string, message string) ErrorValue {
	return with_context(.db_query_failed, 'Database ${operation} failed: ${message}', {
		'operation': operation
	})
}

pub fn db_connection_error(host string, port int) ErrorValue {
	return with_context(.db_connection_failed, 'Failed to connect to database at ${host}:${port}', {
		'host': host
		'port': port.str()
	})
}

pub fn db_not_found(table string, field string, value string) ErrorValue {
	return with_context(.db_not_found, 'No record found in ${table} where ${field}=${value}', {
		'table': table
		'field': field
		'value': value
	})
}

pub fn db_already_exists(resource string, field string, value string) ErrorValue {
	return with_context(.db_already_exists, '${resource} with ${field}="${value}" already exists', {
		'resource': resource
		'field': field
		'value': value
	})
}

pub fn db_constraint_violation(constraint string, message string) ErrorValue {
	return with_context(.db_constraint_violation, 'Constraint violation: ${constraint}', {
		'constraint': constraint
		'details': message
	})
}

// ============================================================================
// Specific Error Constructors - Validation
// ============================================================================

pub fn validation_error(field string, message string) ErrorValue {
	return with_field(.validation_failed, message, field)
}

pub fn missing_field(field string) ErrorValue {
	return with_field(.missing_required_field, 'Required field "${field}" is missing', field)
}

pub fn invalid_field(field string, expected string, actual string) ErrorValue {
	return with_context(.invalid_field_value, 'Invalid value for field "${field}": expected ${expected}, got ${actual}', {
		'field': field
		'expected': expected
		'actual': actual
	})
}

pub fn field_too_short(field string, min int, actual int) ErrorValue {
	return with_context(.field_too_short, 'Field "${field}" must be at least ${min} characters, got ${actual}', {
		'field': field
		'min': min.str()
		'actual': actual.str()
	})
}

pub fn field_too_long(field string, max int, actual int) ErrorValue {
	return with_context(.field_too_long, 'Field "${field}" must be at most ${max} characters, got ${actual}', {
		'field': field
		'max': max.str()
		'actual': actual.str()
	})
}

pub fn invalid_email(email string) ErrorValue {
	return with_context(.invalid_email, 'Invalid email address: ${email}', {
		'email': email
	})
}

// ============================================================================
// Specific Error Constructors - Resource
// ============================================================================

pub fn not_found_error(resource string, id string) ErrorValue {
	return with_context(.resource_not_found, '${resource} not found: ${id}', {
		'resource': resource
		'id': id
	})
}

pub fn user_not_found(user_id string) ErrorValue {
	return with_context(.user_not_found, 'User not found: ${user_id}', {
		'user_id': user_id
	})
}

pub fn file_not_found(path string) ErrorValue {
	return with_context(.file_not_found, 'File not found: ${path}', {
		'path': path
	})
}

pub fn directory_not_found(path string) ErrorValue {
	return with_context(.directory_not_found, 'Directory not found: ${path}', {
		'path': path
	})
}

// ============================================================================
// Specific Error Constructors - System
// ============================================================================

pub fn internal_error_msg(message string) ErrorValue {
	return new(.internal_error, message)
}

pub fn internal_error_with_cause(message string, cause string) ErrorValue {
	return with_cause(.internal_error, message, cause)
}

pub fn timeout_error(operation string, timeout_ms int) ErrorValue {
	return with_context(.timeout_error, 'Operation "${operation}" timed out after ${timeout_ms}ms', {
		'operation': operation
		'timeout_ms': timeout_ms.str()
	})
}

pub fn permission_error(resource string, action string) ErrorValue {
	return with_context(.permission_denied, 'Permission denied: cannot ${action} ${resource}', {
		'resource': resource
		'action': action
	})
}

pub fn rate_limit_error(limit int, retry_after_ms int) ErrorValue {
	mut err := with_context(.rate_limit_exceeded, 'Rate limit exceeded: ${limit} requests per minute', {
		'limit': limit.str()
		'retry_after_ms': retry_after_ms.str()
	})
	err.recovery_suggestion = 'Wait ${retry_after_ms}ms before retrying'
	return err
}

pub fn service_unavailable_error(service string, reason string) ErrorValue {
	return with_context(.service_unavailable, 'Service "${service}" is unavailable: ${reason}', {
		'service': service
		'reason': reason
	})
}

// ============================================================================
// Specific Error Constructors - Network
// ============================================================================

pub fn network_error_msg(message string) ErrorValue {
	return new(.network_error, message)
}

pub fn connection_refused_error(host string, port int) ErrorValue {
	return with_context(.connection_refused, 'Connection refused to ${host}:${port}', {
		'host': host
		'port': port.str()
	})
}

pub fn dns_error(hostname string) ErrorValue {
	return with_context(.dns_resolution_failed, 'Failed to resolve hostname: ${hostname}', {
		'hostname': hostname
	})
}

// ============================================================================
// Specific Error Constructors - Configuration
// ============================================================================

pub fn config_error(key string, message string) ErrorValue {
	return with_context(.config_invalid, 'Configuration error for key "${key}": ${message}', {
		'key': key
	})
}

pub fn config_missing(key string) ErrorValue {
	return with_context(.config_not_found, 'Configuration key not found: ${key}', {
		'key': key
	})
}

// ============================================================================
// Error Analysis
// ============================================================================

pub fn is_critical(err ErrorValue) bool {
	return err.severity == .critical || err.severity == .fatal || err.code in [
		.db_connection_failed
		.db_query_failed
		.internal_error
		.timeout_error
		.service_unavailable
	]
}

pub fn is_warning(err ErrorValue) bool {
	return err.severity == .warning || err.code in [
		.validation_failed
		.missing_required_field
		.invalid_field_value
		.config_not_found
		.resource_not_found
	]
}

pub fn is_retryable(err ErrorValue) bool {
	return err.retryable || err.code in [
		.timeout_error
		.network_error
		.connection_refused
		.service_unavailable
		.db_connection_failed
	]
}

pub fn get_error_category(err ErrorValue) string {
	return match err.code {
		.db_connection_failed, .db_query_failed, .db_constraint_violation, .db_not_found, .db_already_exists, .db_transaction_failed { 'Database Error' }
		.config_not_found, .config_invalid, .config_missing_field, .config_parse_error { 'Configuration Error' }
		.serialization_failed, .deserialization_failed, .invalid_format, .encoding_error, .decoding_error { 'Data Format Error' }
		.validation_failed, .missing_required_field, .invalid_field_value, .field_too_short, .field_too_long, .invalid_email, .invalid_phone { 'Validation Error' }
		.resource_not_found, .user_not_found, .entity_not_found, .file_not_found, .directory_not_found { 'Not Found Error' }
		.internal_error, .timeout_error, .permission_denied, .rate_limit_exceeded, .service_unavailable, .unsupported_operation { 'System Error' }
		.network_error, .connection_refused, .dns_resolution_failed, .ssl_error { 'Network Error' }
		.plugin_error, .plugin_not_found, .plugin_load_failed { 'Plugin Error' }
		else { 'Unknown Error' }
	}
}

pub fn get_severity(err ErrorValue) ErrorSeverity {
	return err.severity
}

// ============================================================================
// Error Chain and Context
// ============================================================================

// Wrap adds context to an existing error
pub fn wrap(err ErrorValue, context string) ErrorValue {
	mut new_err := err
	new_err.cause = err.message
	new_err.message = '${context}: ${err.message}'
	return new_err
}

// Chain links errors together
pub fn chain(cause ErrorValue, new_error ErrorValue) ErrorValue {
	mut err := new_error
	err.cause = cause.message
	err.stack_trace = cause.stack_trace.clone()
	err.stack_trace << '${cause.source_file}:${cause.source_line}'
	return err
}

// ============================================================================
// Serialization
// ============================================================================

pub fn to_json(err ErrorValue) string {
	return json.encode(err)
}

pub fn to_response(err ErrorValue) string {
	err_json := json.encode(err)
	return '{"success":false,"data":null,"error":${err_json}}'
}

pub fn from_json(json_str string) !ErrorValue {
	mut err := ErrorValue{}
	err = json.decode(ErrorValue, json_str) or {
		return new(.unknown, 'Failed to parse error from JSON')
	}
	return err
}

// ============================================================================
// Logging
// ============================================================================

pub fn log_error(err ErrorValue) {
	t := time.now()
	timestamp := '${t.hour:02}:${t.minute:02}:${t.second:02}'
	severity_str := match err.severity {
		.info { 'INFO' }
		.warning { 'WARN' }
		.error { 'ERROR' }
		.critical { 'CRITICAL' }
		.fatal { 'FATAL' }
	}
	category := get_error_category(err)

	println('')
	println('═══════════════════════════════════════════════════════════')
	println('${timestamp} [${severity_str}] ${category}')
	println('───────────────────────────────────────────────────────────')
	println('  Code:    ${err.code}')
	println('  Message: ${err.message}')
	if err.field != '' {
		println('  Field:   ${err.field}')
	}
	if err.details != '' {
		println('  Details: ${err.details}')
	}
	if err.cause != '' {
		println('  Cause:   ${err.cause}')
	}
	if err.source_file != '' {
		println('  Source:  ${err.source_file}:${err.source_line}')
	}
	if err.retryable {
		println('  Retryable: Yes')
	}
	if err.recovery_suggestion != '' {
		println('  Recovery:  ${err.recovery_suggestion}')
	}
	println('═══════════════════════════════════════════════════════════')
	println('')
}

// ============================================================================
// JSON Response Helpers
// ============================================================================

pub fn ok_json[T](data T) string {
	return '{"success":true,"data":${json.encode(data)},"error":null}'
}

pub fn err_json(err ErrorValue) string {
	return to_response(err)
}

pub fn result_json[T](data T, err ErrorValue) string {
	if err.code == .unknown && err.message == '' {
		return ok_json(data)
	}
	return err_json(err)
}

// ============================================================================
// Error Collection
// ============================================================================

pub struct ErrorCollection {
pub mut:
	errors []ErrorValue
}

pub fn new_error_collection() ErrorCollection {
	return ErrorCollection{
		errors: []ErrorValue{}
	}
}

pub fn (mut c ErrorCollection) add(err ErrorValue) {
	c.errors << err
}

pub fn (mut c ErrorCollection) add_all(errors []ErrorValue) {
	c.errors << errors
}

pub fn (c ErrorCollection) has_errors() bool {
	return c.errors.len > 0
}

pub fn (c ErrorCollection) error_count() int {
	return c.errors.len
}

pub fn (c ErrorCollection) get_errors() []ErrorValue {
	return c.errors.clone()
}

pub fn (mut c ErrorCollection) clear() {
	c.errors = []ErrorValue{}
}

pub fn (c ErrorCollection) to_result() ![]ErrorValue {
	if c.has_errors() {
		return error('Validation failed with ${c.errors.len} error(s)')
	}
	return c.errors
}

// Placeholder functions for API compatibility
pub fn get_stats() map[string]int {
	return {'total': 0, 'critical': 0, 'warnings': 0, 'info': 0}
}

pub fn get_errors(limit int) []ErrorValue {
	return []ErrorValue{}
}

pub fn clear_errors() {}
