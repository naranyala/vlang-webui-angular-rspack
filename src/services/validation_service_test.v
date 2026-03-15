module services

// V Test file - run with: v test src/services/validation_service_test.v

fn test_new_validation_service() {
	mut assert_count := 0

	validation := new_validation_service()

	assert validation != 0
	assert_count++

	assert validation.initialized == false
	assert_count++

	assert validation.rules.len == 0
	assert_count++

	assert validation.errors.len == 0
	assert_count++

	println('test_new_validation_service: ${assert_count} assertions passed')
}

fn test_init() {
	mut assert_count := 0

	validation := new_validation_service()
	result := validation.init()

	assert result == true
	assert_count++

	assert validation.initialized == true
	assert_count++

	println('test_init: ${assert_count} assertions passed')
}

fn test_add_rule() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()

	// Add required rule
	validation.add_rule('email', 'required')
	assert validation.rules.len == 1
	assert_count++

	// Add email rule
	validation.add_rule('email', 'email')
	assert validation.rules.len == 2
	assert_count++

	// Add min length rule
	validation.add_rule('password', 'min:8')
	assert validation.rules.len == 3
	assert_count++

	// Add max length rule
	validation.add_rule('name', 'max:50')
	assert validation.rules.len == 4
	assert_count++

	// Add numeric rule
	validation.add_rule('age', 'numeric')
	assert validation.rules.len == 5
	assert_count++

	println('test_add_rule: ${assert_count} assertions passed')
}

fn test_validate_required() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('name', 'required')

	// Valid - has value
	mut data1 := map[string]string{}
	data1['name'] = 'John'
	result1 := validation.validate(data1)
	assert result1.is_valid == true
	assert_count++

	// Invalid - empty string
	mut data2 := map[string]string{}
	data2['name'] = ''
	result2 := validation.validate(data2)
	assert result2.is_valid == false
	assert_count++

	// Invalid - whitespace only
	mut data3 := map[string]string{}
	data3['name'] = '   '
	result3 := validation.validate(data3)
	assert result3.is_valid == false
	assert_count++

	// Invalid - missing key
	mut data4 := map[string]string{}
	result4 := validation.validate(data4)
	assert result4.is_valid == false
	assert_count++

	println('test_validate_required: ${assert_count} assertions passed')
}

fn test_validate_email() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('email', 'email')

	// Valid emails
	mut valid_emails := ['test@example.com', 'user@domain.org', 'a@b.co']
	for email in valid_emails {
		mut data := map[string]string{}
		data['email'] = email
		result := validation.validate(data)
		assert result.is_valid == true
		assert_count++
	}

	// Invalid emails
	mut invalid_emails := ['invalid', 'no@domain', '@missing.local', '']
	for email in invalid_emails {
		mut data := map[string]string{}
		data['email'] = email
		result := validation.validate(data)
		assert result.is_valid == false
		assert_count++
	}

	println('test_validate_email: ${assert_count} assertions passed')
}

fn test_validate_min_length() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('password', 'min:8')

	// Valid - meets minimum
	mut data1 := map[string]string{}
	data1['password'] = 'password123'
	result1 := validation.validate(data1)
	assert result1.is_valid == true
	assert_count++

	// Valid - exactly minimum
	mut data2 := map[string]string{}
	data2['password'] = '12345678'
	result2 := validation.validate(data2)
	assert result2.is_valid == true
	assert_count++

	// Invalid - below minimum
	mut data3 := map[string]string{}
	data3['password'] = 'short'
	result3 := validation.validate(data3)
	assert result3.is_valid == false
	assert_count++

	println('test_validate_min_length: ${assert_count} assertions passed')
}

fn test_validate_max_length() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('name', 'max:10')

	// Valid - under maximum
	mut data1 := map[string]string{}
	data1['name'] = 'John'
	result1 := validation.validate(data1)
	assert result1.is_valid == true
	assert_count++

	// Valid - exactly maximum
	mut data2 := map[string]string{}
	data2['name'] = '1234567890'
	result2 := validation.validate(data2)
	assert result2.is_valid == true
	assert_count++

	// Invalid - over maximum
	mut data3 := map[string]string{}
	data3['name'] = 'ThisNameIsTooLong'
	result3 := validation.validate(data3)
	assert result3.is_valid == false
	assert_count++

	println('test_validate_max_length: ${assert_count} assertions passed')
}

fn test_validate_numeric() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('age', 'numeric')

	// Valid numeric values
	mut valid_numbers := ['123', '0', '-456', '3.14']
	for num in valid_numbers {
		mut data := map[string]string{}
		data['age'] = num
		result := validation.validate(data)
		assert result.is_valid == true
		assert_count++
	}

	// Invalid numeric values
	mut invalid_numbers := ['abc', '12abc', '', ' ']
	for num in invalid_numbers {
		mut data := map[string]string{}
		data['age'] = num
		result := validation.validate(data)
		assert result.is_valid == false
		assert_count++
	}

	println('test_validate_numeric: ${assert_count} assertions passed')
}

fn test_get_errors() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('email', 'required')
	validation.add_rule('email', 'email')

	// Validate with invalid data
	mut data := map[string]string{}
	data['email'] = 'invalid'
	result := validation.validate(data)

	assert result.is_valid == false
	assert_count++

	errors := validation.get_errors()
	assert errors.len > 0
	assert_count++

	// Check error structure
	if errors.len > 0 {
		assert errors[0].field == 'email'
		assert_count++

		assert errors[0].message.len > 0
		assert_count++
	}

	println('test_get_errors: ${assert_count} assertions passed')
}

fn test_is_valid() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('name', 'required')

	// Valid data
	mut data1 := map[string]string{}
	data1['name'] = 'John'
	assert validation.is_valid(data1) == true
	assert_count++

	// Invalid data
	mut data2 := map[string]string{}
	data2['name'] = ''
	assert validation.is_valid(data2) == false
	assert_count++

	println('test_is_valid: ${assert_count} assertions passed')
}

fn test_clear_rules() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()

	validation.add_rule('field1', 'required')
	validation.add_rule('field2', 'email')
	assert validation.rules.len == 2
	assert_count++

	validation.clear_rules()
	assert validation.rules.len == 0
	assert_count++

	println('test_clear_rules: ${assert_count} assertions passed')
}

fn test_clear_errors() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('name', 'required')

	// Generate errors
	mut data := map[string]string{}
	data['name'] = ''
	validation.validate(data)

	assert validation.errors.len > 0
	assert_count++

	validation.clear_errors()
	assert validation.errors.len == 0
	assert_count++

	println('test_clear_errors: ${assert_count} assertions passed')
}

fn test_multiple_rules() {
	mut assert_count := 0

	validation := new_validation_service()
	validation.init()
	validation.add_rule('email', 'required')
	validation.add_rule('email', 'email')
	validation.add_rule('password', 'required')
	validation.add_rule('password', 'min:8')

	// All valid
	mut data1 := map[string]string{}
	data1['email'] = 'test@example.com'
	data1['password'] = 'securepass123'
	result1 := validation.validate(data1)
	assert result1.is_valid == true
	assert_count++

	// Email invalid
	mut data2 := map[string]string{}
	data2['email'] = 'invalid'
	data2['password'] = 'securepass123'
	result2 := validation.validate(data2)
	assert result2.is_valid == false
	assert_count++

	// Password invalid
	mut data3 := map[string]string{}
	data3['email'] = 'test@example.com'
	data3['password'] = 'short'
	result3 := validation.validate(data3)
	assert result3.is_valid == false
	assert_count++

	// Both invalid
	mut data4 := map[string]string{}
	data4['email'] = 'invalid'
	data4['password'] = 'short'
	result4 := validation.validate(data4)
	assert result4.is_valid == false
	assert_count++

	// Check error count
	assert result4.errors.len >= 2
	assert_count++

	println('test_multiple_rules: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_validation_service()
	test_init()
	test_add_rule()
	test_validate_required()
	test_validate_email()
	test_validate_min_length()
	test_validate_max_length()
	test_validate_numeric()
	test_get_errors()
	test_is_valid()
	test_clear_rules()
	test_clear_errors()
	test_multiple_rules()
}
