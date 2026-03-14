module result

import error
import json

// ============================================================================
// Result Type - Errors as Values
// ============================================================================

// Result represents either a success with value or an error
// This is the core of "errors as values" pattern
pub struct Result[T] {
pub mut:
	is_success bool
	value      T
	error      error.ErrorValue
}

// Ok creates a successful Result with a value
pub fn ok[T](value T) Result[T] {
	return Result[T]{
		is_success: true
		value:      value
	}
}

// Err creates a failed Result with an error
pub fn err[T](error_value error.ErrorValue) Result[T] {
	return Result[T]{
		is_success: false
		error:      error_value
	}
}

// Is_ok checks if the result is successful
pub fn (r Result[T]) is_ok() bool {
	return r.is_success
}

// Is_err checks if the result is an error
pub fn (r Result[T]) is_err() bool {
	return !r.is_success
}

// Get returns the value or default if error
pub fn (r Result[T]) get(default_value T) T {
	if r.is_success {
		return r.value
	}
	return default_value
}

// Get_or_else returns the value or computes a default
pub fn (r Result[T]) get_or_else(default_fn fn () T) T {
	if r.is_success {
		return r.value
	}
	return default_fn()
}

// Map transforms the value if successful
pub fn (r Result[T]) map[U](f fn (T) U) Result[U] {
	if r.is_success {
		return ok[U](f(r.value))
	}
	// Cast error to new type
	mut err_result := Result[U]{}
	err_result.is_success = false
	err_result.error = r.error
	return err_result
}

// Map_err transforms the error if failed
pub fn (r Result[T]) map_err(f fn (error.ErrorValue) error.ErrorValue) Result[T] {
	if r.is_err() {
		mut res := r
		res.error = f(r.error)
		return res
	}
	return r
}

// And_then chains operations that return Results
pub fn (r Result[T]) and_then[U](f fn (T) Result[U]) Result[U] {
	if r.is_success {
		return f(r.value)
	}
	// Cast error to new type
	mut err_result := Result[U]{}
	err_result.is_success = false
	err_result.error = r.error
	return err_result
}

// Or_else provides an alternative Result on error
pub fn (r Result[T]) or_else(f fn (error.ErrorValue) Result[T]) Result[T] {
	if r.is_success {
		return r
	}
	return f(r.error)
}

// To_option converts Result to Option (Some on success, None on error)
pub fn (r Result[T]) to_option() ?T {
	if r.is_success {
		return r.value
	}
	return none
}

// To_error returns the error or none if successful
pub fn (r Result[T]) to_error() ?error.ErrorValue {
	if r.is_err() {
		return r.error
	}
	return none
}

// Match performs pattern matching on the result
pub fn (r Result[T]) match(on_success fn (T), on_error fn (error.ErrorValue)) {
	if r.is_success {
		on_success(r.value)
	} else {
		on_error(r.error)
	}
}

// To_json serializes the result to JSON
pub fn (r Result[T]) to_json() string {
	if r.is_success {
		return '{"success":true,"data":${json.encode(r.value)},"error":null}'
	} else {
		return '{"success":false,"data":null,"error":${json.encode(r.error)}}'
	}
}

// To_response creates a standardized API response
pub fn (r Result[T]) to_response() string {
	return r.to_json()
}

// ============================================================================
// Result Extensions for Common Types
// ============================================================================

// Result_string helper
pub type ResultString = Result[string]

// Result_int helper
pub type ResultInt = Result[int]

// Result_f64 helper
pub type ResultF64 = Result[f64]

// Result_bool helper
pub type ResultBool = Result[bool]

// ============================================================================
// Utility Functions
// ============================================================================

// From_panic converts a panic-recover scenario to a Result
pub fn from_panic[T](f fn () T) Result[T] {
	// In V, we can't truly catch panics, but we can document this pattern
	// Use try/catch pattern instead
	return ok(f())
}

// All combines multiple results, returning first error or all values
pub fn all[T](results []Result[T]) Result[[]T] {
	mut values := []T{}
	
	for result in results {
		if result.is_err() {
			return err(result.error)
		}
		values << result.value
	}
	
	return ok(values)
}

// Sequence transforms []Result<T> to Result<[]T>
pub fn sequence[T](results []Result[T]) Result[[]T] {
	return all[T](results)
}

// Traverse applies a function returning Result to each element
pub fn traverse[T, U](items []T, f fn (T) Result[U]) Result[[]U] {
	mut results := []Result[U]{}
	
	for item in items {
		results << f(item)
	}
	
	return sequence[U](results)
}

// CombineResult holds two combined values
pub struct CombineResult[T, U] {
pub mut:
	first  T
	second U
}

// Combine merges two results, returning first error or both values
pub fn combine[T, U](result1 Result[T], result2 Result[U]) Result[CombineResult[T, U]] {
	return result1.and_then(fn (v1 T) Result[CombineResult[T, U]] {
		return result2.map(fn (v2 U) CombineResult[T, U] {
			return CombineResult[T, U]{
				first:  v1
				second: v2
			}
		})
	})
}
