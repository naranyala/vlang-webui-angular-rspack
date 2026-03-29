# CRUD Demos

Hands-on guides for implementing CRUD operations with SQLite and DuckDB storage backends.

---

## Table of Contents

1. [Overview](#overview)
2. [SQLite Demo](#sqlite-demo)
3. [DuckDB Demo](#duckdb-demo)
4. [Testing Checklist](#testing-checklist)

---

## Overview

This guide provides complete CRUD (Create, Read, Update, Delete) implementation examples for both SQLite and DuckDB storage backends.

### Comparison

| Feature | SQLite | DuckDB (JSON) |
|---------|--------|---------------|
| Storage Type | File-based SQLite | In-memory with JSON persistence |
| Setup Complexity | Medium | Simple |
| Performance | Fast (disk-based) | Very Fast (memory-based) |
| Persistence | Automatic | Manual (JSON export) |
| Best For | Production use | Demo/Prototyping |

---

## SQLite Demo

### Setup

1. Install SQLite module:
```bash
v install sqlite
```

2. Configure database path in `.env`:
```bash
DB_TYPE=sqlite
DB_PATH=data/app.db
```

3. Initialize database with schema:
```v
pub fn (mut s SqliteService) create_tables() ! {
    s.db.exec(`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            age INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    `) or { return err }
}
```

### CRUD Operations

**CREATE:**
```v
pub fn (mut s SqliteService) create_user(name string, email string, age int) !User {
    s.db.exec(`INSERT INTO users (name, email, age) VALUES (?, ?, ?)`, 
        [name, email, age.str()]) or { return err }
    
    user_id := s.db.last_insert_id()
    return s.get_user_by_id(user_id) or { return error('User created but not found') }
}
```

**READ:**
```v
pub fn (s SqliteService) get_all_users() []User {
    mut users := []User{}
    rows := s.db.query(`SELECT * FROM users ORDER BY id DESC`) or { return users }
    
    for rows.next() {
        users << User{
            id: rows.int('id')
            name: rows.text('name')
            email: rows.text('email')
            age: rows.int('age')
            created_at: rows.text('created_at')
        }
    }
    return users
}
```

**UPDATE:**
```v
pub fn (mut s SqliteService) update_user(id int, name string, email string, age int) !User {
    s.db.exec(`UPDATE users SET name = ?, email = ?, age = ? WHERE id = ?`,
        [name, email, age.str(), id.str()]) or { return err }
    
    if s.db.rows_affected() == 0 {
        return error('User not found')
    }
    return s.get_user_by_id(id) or { return error('User updated but not found') }
}
```

**DELETE:**
```v
pub fn (mut s SqliteService) delete_user(id int) ! {
    s.db.exec(`DELETE FROM users WHERE id = ?`, [id.str()]) or { return err }
    
    if s.db.rows_affected() == 0 {
        return error('User not found')
    }
}
```

---

## DuckDB Demo

### Setup

1. Configure JSON storage path in `.env`:
```bash
DB_TYPE=duckdb
DB_PATH=data/duckdb_demo.json
DB_DEMO_MODE=true
```

2. Initialize service:
```v
pub fn new_duckdb_service(db_path string) !&DuckDBService {
    mut s := &DuckDBService{
        db_path: db_path
        next_user_id: 1
        initialized: false
    }
    
    if os.exists(db_path) {
        s.load_from_file() or { s.insert_demo_data() }
    } else {
        s.insert_demo_data()
    }
    
    s.initialized = true
    return s
}
```

### CRUD Operations

**CREATE:**
```v
pub fn (mut s DuckDBService) create_user(name string, email string, age int) !User {
    user := User{
        id: s.next_user_id++
        name: name
        email: email
        age: age
        created_at: time.now().str()
    }
    
    s.users << user
    s.save_to_file() or { println('Warning: Could not save user') }
    return user
}
```

**READ:**
```v
pub fn (s DuckDBService) get_all_users() []User {
    mut users := s.users.clone()
    users.reverse()  // Show newest first
    return users
}
```

**UPDATE:**
```v
pub fn (mut s DuckDBService) update_user(id int, name string, email string, age int) !User {
    for i, user in s.users {
        if user.id == id {
            s.users[i].name = name
            s.users[i].email = email
            s.users[i].age = age
            s.save_to_file() or { println('Warning: Could not save updated user') }
            return s.users[i]
        }
    }
    return error('User not found')
}
```

**DELETE:**
```v
pub fn (mut s DuckDBService) delete_user(id int) ! {
    mut found := false
    mut new_users := []User{}
    
    for user in s.users {
        if user.id == id {
            found = true
            continue
        }
        new_users << user
    }
    
    if !found {
        return error('User not found')
    }
    
    s.users = new_users
    s.save_to_file() or { println('Warning: Could not save deleted user') }
}
```

---

## Testing Checklist

### Backend Tests

- [ ] CREATE: Create valid user
- [ ] CREATE: Create user with invalid email
- [ ] CREATE: Create user with missing name
- [ ] READ: Get all users
- [ ] READ: Get user by ID
- [ ] READ: Get user by ID (not found)
- [ ] UPDATE: Update existing user
- [ ] UPDATE: Update non-existent user
- [ ] DELETE: Delete existing user
- [ ] DELETE: Delete non-existent user

### Frontend Tests

- [ ] DataTable renders correctly
- [ ] Search filters items
- [ ] Pagination works
- [ ] Create modal opens
- [ ] Edit modal populates data
- [ ] Delete confirmation works

### Integration Tests

- [ ] Application starts
- [ ] Dashboard loads
- [ ] Users table displays
- [ ] Create user succeeds
- [ ] Update user persists
- [ ] Delete user removes from list
- [ ] Search returns correct results

---

*Last Updated: 2026-03-29*
