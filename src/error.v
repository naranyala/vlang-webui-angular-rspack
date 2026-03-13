module error

import time
import json

// ============================================================================
// Error Types and Structures
// ============================================================================

// ErrorCode represents structured error codes
pub enum ErrorCode {
	db_connection_failed      = 1001
	db_query_failed           = 1002
	db_constraint_violation   = 1003
	db_not_found              = 1004
	db_already_exists         = 1005
	config_not_found          = 2001
	config_invalid            = 2002
	config_missing_field      = 2003
	serialization_failed      = 3001
	deserialization_failed    = 3002
	invalid_format            = 3003
	validation_failed         = 4001
	missing_required_field    = 4002
	invalid_field_value       = 4003
	resource_not_found        = 5001
	user_not_found            = 5002
	entity_not_found          = 5003
	internal_error            = 6001
	timeout_error             = 6002
	permission_denied         = 6003
	plugin_error              = 7001
	unknown                   = 9999
}

// ErrorValue represents a structured error
pub struct ErrorValue {
pub mut:
	code      ErrorCode
	message   string
	details   string
	field     string
	cause     string
	timestamp u64
	source    string
	context   map[string]string
}

// ============================================================================
// Error Creation Functions
// ============================================================================

pub fn new(code ErrorCode, message string) ErrorValue {
	return ErrorValue{
		code:      code
		message:   message
		timestamp: u64(time.now().unix())
		source:    'backend'
		context:   map[string]string{}
	}
}

pub fn with_details(code ErrorCode, message string, details string) ErrorValue {
	mut err := new(code, message)
	err.details = details
	return err
}

pub fn with_field(code ErrorCode, message string, field string) ErrorValue {
	mut err := new(code, message)
	err.field = field
	return err
}

pub fn with_context(code ErrorCode, message string, context map[string]string) ErrorValue {
	mut err := new(code, message)
	err.context = context.clone()
	return err
}

// ============================================================================
// Specific Error Constructors
// ============================================================================

pub fn db_error(operation string, message string) ErrorValue {
	return with_context(.db_query_failed, 'Database ${operation} failed: ${message}', {'operation': operation})
}

pub fn validation_error(field string, message string) ErrorValue {
	return with_field(.validation_failed, message, field)
}

pub fn not_found_error(resource string, id string) ErrorValue {
	return with_context(.resource_not_found, '${resource} not found: ${id}', {'resource': resource, 'id': id})
}

pub fn already_exists_error(resource string, field string, value string) ErrorValue {
	return with_context(.db_already_exists, '${resource} with ${field}="${value}" already exists', {
		'resource': resource
		'field': field
		'value': value
	})
}

pub fn internal_error_msg(message string) ErrorValue {
	return new(.internal_error, message)
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

// ============================================================================
// Error Analysis
// ============================================================================

pub fn is_critical(err ErrorValue) bool {
	return err.code in [.db_connection_failed, .db_query_failed, .internal_error, .timeout_error]
}

pub fn is_warning(err ErrorValue) bool {
	return err.code in [.validation_failed, .missing_required_field, .invalid_field_value, .config_not_found]
}

pub fn get_error_category(err ErrorValue) string {
	return match err.code {
		.db_connection_failed, .db_query_failed, .db_constraint_violation, .db_not_found, .db_already_exists { 'Database Error' }
		.config_not_found, .config_invalid, .config_missing_field { 'Configuration Error' }
		.serialization_failed, .deserialization_failed, .invalid_format { 'Data Format Error' }
		.validation_failed, .missing_required_field, .invalid_field_value { 'Validation Error' }
		.resource_not_found, .user_not_found, .entity_not_found { 'Not Found Error' }
		.internal_error, .timeout_error, .permission_denied { 'System Error' }
		.plugin_error { 'Plugin Error' }
		else { 'Unknown Error' }
	}
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
	severity := if is_critical(err) { 'CRITICAL' } else { 'ERROR' }
	category := get_error_category(err)

	println('')
	println('═══════════════════════════════════════════════════════════')
	println('${timestamp} [${severity}] ${category}')
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
	println('  Source:  ${err.source}')
	println('═══════════════════════════════════════════════════════════')
	println('')
}

// ============================================================================
// JSON Helpers
// ============================================================================

pub fn ok_json(data string) string {
	return '{"success":true,"data":${data},"error":null}'
}

pub fn err_json(err ErrorValue) string {
	return to_response(err)
}

// Placeholder functions for API compatibility
pub fn get_stats() map[string]int {
	return {'total': 0, 'critical': 0, 'warnings': 0, 'info': 0}
}

pub fn get_errors(limit int) []ErrorValue {
	return []ErrorValue{}
}

pub fn clear_errors() {}
