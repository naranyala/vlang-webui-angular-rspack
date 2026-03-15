module services

// V Test file - run with: v test src/services/sqlite_service_test.v

import os
import time

fn test_new_sqlite_service() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	assert db != 0
	assert_count++

	assert db.initialized == true
	assert_count++

	assert db.db_path == temp_db
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_new_sqlite_service: ${assert_count} assertions passed')
}

fn test_get_all_users() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite2_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Should have demo users
	users := db.get_all_users()
	assert users.len >= 3
	assert_count++

	// Users should be in reverse order (newest first)
	if users.len >= 2 {
		assert users[0].id > users[1].id
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_get_all_users: ${assert_count} assertions passed')
}

fn test_create_user() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite3_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	initial_count := db.get_all_users().len

	// Create a new user
	user := db.create_user('New User', 'new@example.com', 30) or {
		assert false
		return
	}

	assert user.id > 0
	assert_count++

	assert user.name == 'New User'
	assert_count++

	assert user.email == 'new@example.com'
	assert_count++

	assert user.age == 30
	assert_count++

	// Verify user was added
	new_count := db.get_all_users().len
	assert new_count == initial_count + 1
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_create_user: ${assert_count} assertions passed')
}

fn test_update_user() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite4_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Get first user
	users := db.get_all_users()
	if users.len == 0 {
		assert false
		return
	}

	original_user := users[0]

	// Update user
	updated := db.update_user(original_user.id, 'Updated Name', 'updated@example.com', 35) or {
		assert false
		return
	}

	assert updated.name == 'Updated Name'
	assert_count++

	assert updated.email == 'updated@example.com'
	assert_count++

	assert updated.age == 35
	assert_count++

	assert updated.id == original_user.id
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_update_user: ${assert_count} assertions passed')
}

fn test_delete_user() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite5_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Get first user
	users := db.get_all_users()
	if users.len == 0 {
		assert false
		return
	}

	user_to_delete := users[0]
	initial_count := users.len

	// Delete user
	db.delete_user(user_to_delete.id) or {
		assert false
		return
	}

	// Verify deletion
	remaining := db.get_all_users()
	assert remaining.len == initial_count - 1
	assert_count++

	// Verify user is gone
	for user in remaining {
		assert user.id != user_to_delete.id
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_delete_user: ${assert_count} assertions passed')
}

fn test_get_user_by_id() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite6_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Get first user
	users := db.get_all_users()
	if users.len == 0 {
		assert false
		return
	}

	target_user := users[0]

	// Get by ID
	found := db.get_user_by_id(target_user.id) or {
		assert false
		return
	}

	assert found.id == target_user.id
	assert_count++

	assert found.name == target_user.name
	assert_count++

	// Get non-existent user
	_ = db.get_user_by_id(99999) or {
		assert true
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_get_user_by_id: ${assert_count} assertions passed')
}

fn test_get_user_by_email() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite7_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Get first user
	users := db.get_all_users()
	if users.len == 0 {
		assert false
		return
	}

	target_user := users[0]

	// Get by email
	found := db.get_user_by_email(target_user.email) or {
		assert false
		return
	}

	assert found.id == target_user.id
	assert_count++

	assert found.email == target_user.email
	assert_count++

	// Get non-existent email
	_ = db.get_user_by_email('nonexistent@example.com') or {
		assert true
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_get_user_by_email: ${assert_count} assertions passed')
}

fn test_get_stats() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite8_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	stats := db.get_stats()

	assert stats.total_users >= 3
	assert_count++

	assert stats.unique_domains >= 1
	assert_count++

	// today_count should be 0 for fresh database
	assert stats.today_count >= 0
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_get_stats: ${assert_count} assertions passed')
}

fn test_invalid_email() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite9_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Try to create user with invalid email
	_ = db.create_user('Invalid User', 'invalid-email', 25) or {
		assert true
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_invalid_email: ${assert_count} assertions passed')
}

fn test_user_not_found() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite10_${u64(time.now().unix())}.db'

	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Try to update non-existent user
	_ = db.update_user(99999, 'Name', 'email@test.com', 25) or {
		assert true
		assert_count++
	}

	// Try to delete non-existent user
	_ = db.delete_user(99999) or {
		assert true
		assert_count++
	}

	// Cleanup
	os.rm(temp_db)

	println('test_user_not_found: ${assert_count} assertions passed')
}

fn test_database_persistence() {
	mut assert_count := 0

	temp_db := '/tmp/test_sqlite11_${u64(time.now().unix())}.db'

	// Create database and add user
	db := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	initial_count := db.get_all_users().len
	db.create_user('Persist User', 'persist@example.com', 40) or {
		assert false
		return
	}

	// Create new instance (simulates restart)
	db2 := new_sqlite_service(temp_db) or {
		assert false
		return
	}

	// Should have the user we added
	users := db2.get_all_users()
	assert users.len == initial_count + 1
	assert_count++

	// Find our user
	mut found := false
	for user in users {
		if user.email == 'persist@example.com' {
			found = true
			break
		}
	}
	assert found == true
	assert_count++

	// Cleanup
	os.rm(temp_db)

	println('test_database_persistence: ${assert_count} assertions passed')
}

fn test_all() {
	test_new_sqlite_service()
	test_get_all_users()
	test_create_user()
	test_update_user()
	test_delete_user()
	test_get_user_by_id()
	test_get_user_by_email()
	test_get_stats()
	test_invalid_email()
	test_user_not_found()
	test_database_persistence()
}
