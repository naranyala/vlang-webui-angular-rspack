# CRUD Demos - SQLite & DuckDB

Hands-on guides for implementing CRUD operations with SQLite and DuckDB storage backends.

---

## Table of Contents

### 📋 Overview
- [Demo Comparison](#demo-comparison)
- [Quick Start Checklist](#quick-start-checklist)
- [Architecture Overview](#architecture-overview)

### 🗄️ SQLite Demo
- [SQLite Setup](#sqlite-setup)
- [SQLite CRUD Operations](#sqlite-crud-operations)
- [SQLite Best Practices](#sqlite-best-practices)
- [SQLite Troubleshooting](#sqlite-troubleshooting)

### 🦆 DuckDB Demo
- [DuckDB Setup](#duckdb-setup)
- [DuckDB CRUD Operations](#duckdb-crud-operations)
- [DuckDB Best Practices](#duckdb-best-practices)
- [DuckDB Troubleshooting](#duckdb-troubleshooting)

### 🔧 Common Patterns
- [Data Models](#data-models)
- [API Handlers](#api-handlers)
- [Frontend Components](#frontend-components)
- [Validation](#validation)

### ✅ Testing Checklist
- [Backend Tests](#backend-tests)
- [Frontend Tests](#frontend-tests)
- [Integration Tests](#integration-tests)

---

## Demo Comparison

| Feature | SQLite Demo | DuckDB Demo |
|---------|-------------|-------------|
| **Storage Type** | File-based SQLite | In-memory with JSON persistence |
| **Setup Complexity** | Medium | Simple |
| **Performance** | Fast (disk-based) | Very Fast (memory-based) |
| **Persistence** | Automatic | Manual (JSON export) |
| **Query Language** | SQL | SQL (DuckDB dialect) |
| **Best For** | Production use | Demo/Prototyping |
| **File Location** | `data/app.db` | `data/duckdb_demo.json` |

---

## Quick Start Checklist

### Prerequisites

- [ ] V Language 0.5.1+ installed
- [ ] Bun 1.0+ installed
- [ ] GCC compiler installed
- [ ] GTK3 + WebKit (Linux only)

### Setup Steps

- [ ] Clone repository
- [ ] Run `./scripts/dev-setup.sh`
- [ ] Copy `.env.example` to `.env`
- [ ] Run `./run.sh dev`
- [ ] Verify application at `http://localhost:8080`

### Demo Verification

- [ ] Users table displays 5 demo users
- [ ] Products table displays 8 demo products
- [ ] Orders table displays 5 demo orders
- [ ] Create new user works
- [ ] Update user works
- [ ] Delete user works
- [ ] Search/filter works
- [ ] Pagination works

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CRUD Architecture                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Angular    │         │   DataTable  │                 │
│  │  Component   │◄───────►│   Component  │                 │
│  └──────────────┘         └──────┬───────┘                 │
│                                  │                          │
│                          ┌───────▼───────┐                 │
│                          │   ApiService   │                 │
│                          └───────┬───────┘                 │
│                                  │                          │
│                          ┌───────▼───────┐                 │
│                          │  API Handlers │                 │
│                          └───────┬───────┘                 │
│                                  │                          │
│              ┌───────────────────┼───────────────────┐     │
│              │                   │                   │     │
│       ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐│
│       │   SQLite    │    │   DuckDB    │    │   JSON      ││
│       │   Service   │    │   Service   │    │   Storage   ││
│       └─────────────┘    └─────────────┘    └─────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## SQLite Demo

### SQLite Setup

#### 1. Install SQLite Module

```bash
# V has built-in SQLite support
# No additional installation needed
v install sqlite
```

#### 2. Configure Database Path

```bash
# In .env file
DB_TYPE=sqlite
DB_PATH=data/app.db
```

#### 3. Initialize Database

```v
// src/services/sqlite_service.v
module services

import sqlite

pub struct SqliteService {
pub mut:
    db_path     string
    db          sqlite.DB
    initialized bool
}

pub fn new_sqlite_service(db_path string) !&SqliteService {
    mut s := &SqliteService{
        db_path: db_path
        initialized: false
    }
    
    // Create directory if not exists
    if !os.exists(db_path.dir()) {
        os.mkdir_all(db_path.dir()) or {
            return error('Failed to create database directory')
        }
    }
    
    // Open database
    s.db = sqlite.open(db_path) or {
        return error('Failed to open database: ${err}')
    }
    
    // Initialize tables
    s.create_tables() or {
        return error('Failed to create tables: ${err}')
    }
    
    s.initialized = true
    return s
}

fn (mut s SqliteService) create_tables() ! {
    // Users table
    s.db.exec(`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            age INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    `) or {
        return err
    }
    
    // Products table
    s.db.exec(`
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL,
            stock INTEGER,
            category TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    `) or {
        return err
    }
    
    // Orders table
    s.db.exec(`
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            user_name TEXT,
            total REAL,
            status TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    `) or {
        return err
    }
}
```

#### 4. Insert Demo Data

```v
pub fn (mut s SqliteService) insert_demo_data() ! {
    // Insert demo users
    s.db.exec(`
        INSERT OR IGNORE INTO users (name, email, age) VALUES
        ('John Doe', 'john@example.com', 28),
        ('Jane Smith', 'jane@gmail.com', 34),
        ('Bob Wilson', 'bob@company.org', 45),
        ('Alice Brown', 'alice@tech.io', 29),
        ('Charlie Davis', 'charlie@web.com', 38)
    `) or {
        return err
    }
    
    // Insert demo products
    s.db.exec(`
        INSERT OR IGNORE INTO products (name, description, price, stock, category) VALUES
        ('Laptop Pro', 'High-performance laptop', 1299.99, 50, 'Electronics'),
        ('Wireless Mouse', 'Ergonomic wireless mouse', 49.99, 200, 'Electronics'),
        ('USB-C Hub', '7-in-1 USB-C hub', 79.99, 150, 'Accessories'),
        ('Mechanical Keyboard', 'RGB mechanical keyboard', 159.99, 75, 'Electronics'),
        ('Monitor 27"', '4K UHD monitor', 449.99, 30, 'Electronics'),
        ('Desk Chair', 'Ergonomic office chair', 299.99, 40, 'Furniture'),
        ('Desk Lamp', 'LED desk lamp', 39.99, 100, 'Furniture'),
        ('Webcam HD', '1080p webcam', 89.99, 80, 'Electronics')
    `) or {
        return err
    }
}
```

### SQLite CRUD Operations

#### CREATE

```v
// Create User
pub fn (mut s SqliteService) create_user(name string, email string, age int) !User {
    // Validate input
    if name.trim_space().len == 0 {
        return error('Name is required')
    }
    if !email.contains('@') {
        return error('Invalid email')
    }
    if age < 1 || age > 150 {
        return error('Age must be between 1 and 150')
    }
    
    // Insert user
    s.db.exec(`
        INSERT INTO users (name, email, age)
        VALUES (?, ?, ?)
    `, [name, email, age.str()]) or {
        return error('Failed to create user: ${err}')
    }
    
    // Get last inserted ID
    user_id := s.db.last_insert_id()
    
    // Return created user
    return s.get_user_by_id(user_id) or {
        return error('User created but not found')
    }
}

// Create Product
pub fn (mut s SqliteService) create_product(
    name string, 
    description string, 
    price f64, 
    stock int, 
    category string
) !Product {
    if name.trim_space().len == 0 {
        return error('Product name is required')
    }
    if price <= 0 {
        return error('Price must be positive')
    }
    if stock < 0 {
        return error('Stock cannot be negative')
    }
    
    s.db.exec(`
        INSERT INTO products (name, description, price, stock, category)
        VALUES (?, ?, ?, ?, ?)
    `, [name, description, price.str(), stock.str(), category]) or {
        return error('Failed to create product: ${err}')
    }
    
    product_id := s.db.last_insert_id()
    return s.get_product_by_id(product_id) or {
        return error('Product created but not found')
    }
}
```

#### READ

```v
// Get All Users
pub fn (s SqliteService) get_all_users() []User {
    mut users := []User{}
    
    rows := s.db.query(`
        SELECT id, name, email, age, created_at
        FROM users
        ORDER BY id DESC
    `) or {
        println('Query failed: ${err}')
        return users
    }
    
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

// Get User by ID
pub fn (s SqliteService) get_user_by_id(id int) ?User {
    rows := s.db.query(`
        SELECT id, name, email, age, created_at
        FROM users
        WHERE id = ?
    `, [id.str()]) or {
        return none
    }
    
    if !rows.next() {
        return none
    }
    
    return User{
        id: rows.int('id')
        name: rows.text('name')
        email: rows.text('email')
        age: rows.int('age')
        created_at: rows.text('created_at')
    }
}

// Get Users with Pagination
pub fn (s SqliteService) get_users_paginated(limit int, offset int) []User {
    mut users := []User{}
    
    rows := s.db.query(`
        SELECT id, name, email, age, created_at
        FROM users
        ORDER BY id DESC
        LIMIT ? OFFSET ?
    `, [limit.str(), offset.str()]) or {
        return users
    }
    
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

// Get User Count
pub fn (s SqliteService) get_user_count() int {
    rows := s.db.query(`
        SELECT COUNT(*) as count
        FROM users
    `) or {
        return 0
    }
    
    if rows.next() {
        return rows.int('count')
    }
    return 0
}
```

#### UPDATE

```v
// Update User
pub fn (mut s SqliteService) update_user(
    id int, 
    name string, 
    email string, 
    age int
) !User {
    // Validate
    if id <= 0 {
        return error('Invalid user ID')
    }
    if name.trim_space().len == 0 {
        return error('Name is required')
    }
    if !email.contains('@') {
        return error('Invalid email')
    }
    
    // Update
    s.db.exec(`
        UPDATE users
        SET name = ?, email = ?, age = ?
        WHERE id = ?
    `, [name, email, age.str(), id.str()]) or {
        return error('Failed to update user: ${err}')
    }
    
    // Verify update
    if s.db.rows_affected() == 0 {
        return error('User not found')
    }
    
    return s.get_user_by_id(id) or {
        return error('User updated but not found')
    }
}
```

#### DELETE

```v
// Delete User
pub fn (mut s SqliteService) delete_user(id int) ! {
    if id <= 0 {
        return error('Invalid user ID')
    }
    
    s.db.exec(`
        DELETE FROM users
        WHERE id = ?
    `, [id.str()]) or {
        return error('Failed to delete user: ${err}')
    }
    
    if s.db.rows_affected() == 0 {
        return error('User not found')
    }
}
```

### SQLite Best Practices

#### 1. Use Prepared Statements

```v
// ✅ GOOD: Prepared statement
s.db.exec(`
    INSERT INTO users (name, email, age)
    VALUES (?, ?, ?)
`, [name, email, age.str()])

// ❌ BAD: String interpolation (SQL injection risk)
s.db.exec(`
    INSERT INTO users (name, email, age)
    VALUES ('${name}', '${email}', ${age})
`)
```

#### 2. Use Transactions for Batch Operations

```v
pub fn (mut s SqliteService) create_users_batch(users []User) ! {
    s.db.exec('BEGIN TRANSACTION') or {
        return err
    }
    
    for user in users {
        s.db.exec(`
            INSERT INTO users (name, email, age)
            VALUES (?, ?, ?)
        `, [user.name, user.email, user.age.str()]) or {
            s.db.exec('ROLLBACK')
            return error('Failed to insert user: ${err}')
        }
    }
    
    s.db.exec('COMMIT') or {
        s.db.exec('ROLLBACK')
        return error('Failed to commit: ${err}')
    }
}
```

#### 3. Add Indexes for Frequently Queried Columns

```v
fn (mut s SqliteService) create_indexes() ! {
    s.db.exec(`
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)
    `) or {
        return err
    }
    
    s.db.exec(`
        CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)
    `) or {
        return err
    }
}
```

#### 4. Handle Database Connections Properly

```v
pub fn (s SqliteService) dispose() {
    s.db.close()
}

// In main.v cleanup
lifecycle.on_shutdown(fn [mut db] () {
    db.dispose()
})
```

### SQLite Troubleshooting

| Issue | Solution |
|-------|----------|
| Database locked | Close other connections, check for unclosed transactions |
| Table not found | Run `create_tables()` on initialization |
| Constraint violation | Check UNIQUE constraints on email |
| Slow queries | Add indexes, use EXPLAIN QUERY PLAN |
| Memory leak | Always call `dispose()` on shutdown |

---

## DuckDB Demo

### DuckDB Setup

#### 1. Configure DuckDB Path

```bash
# In .env file
DB_TYPE=duckdb
DB_PATH=data/duckdb_demo.json
DB_DEMO_MODE=true
```

#### 2. Initialize DuckDB Service

```v
// src/services/duckdb_service.v
module services

import time
import json

pub struct DuckDBService {
pub mut:
    db_path     string
    users       []User
    products    []Product
    orders      []Order
    next_user_id    int
    next_product_id int
    next_order_id   int
    initialized bool
}

pub fn new_duckdb_service(db_path string) !&DuckDBService {
    mut s := &DuckDBService{
        db_path: db_path
        next_user_id: 1
        next_product_id: 1
        next_order_id: 1
        initialized: false
    }
    
    // Load existing data or initialize demo data
    if os.exists(db_path) {
        s.load_from_file() or {
            s.insert_demo_data()
        }
    } else {
        s.insert_demo_data()
    }
    
    s.initialized = true
    return s
}
```

#### 3. Load/Save JSON Data

```v
pub fn (mut s DuckDBService) load_from_file() ! {
    data := os.read_file(s.db_path) or {
        return error('Failed to read database file')
    }
    
    mut db_data := json.decode(DbData, data) or {
        return error('Failed to parse database file')
    }
    
    s.users = db_data.users
    s.products = db_data.products
    s.orders = db_data.orders
    s.next_user_id = db_data.next_user_id
    s.next_product_id = db_data.next_product_id
    s.next_order_id = db_data.next_order_id
}

pub fn (s DuckDBService) save_to_file() ! {
    db_data := DbData{
        users: s.users
        products: s.products
        orders: s.orders
        next_user_id: s.next_user_id
        next_product_id: s.next_product_id
        next_order_id: s.next_order_id
    }
    
    json_data := json.encode(db_data)
    os.write_file(s.db_path, json_data) or {
        return error('Failed to write database file')
    }
}

pub struct DbData {
pub mut:
    users       []User
    products    []Product
    orders      []Order
    next_user_id    int
    next_product_id int
    next_order_id   int
}
```

#### 4. Insert Demo Data

```v
fn (mut s DuckDBService) insert_demo_data() {
    // Demo Users
    s.users = [
        User{id: s.next_user_id++, name: 'John Doe', email: 'john@example.com', age: 28, created_at: time.now().str()},
        User{id: s.next_user_id++, name: 'Jane Smith', email: 'jane@gmail.com', age: 34, created_at: time.now().str()},
        User{id: s.next_user_id++, name: 'Bob Wilson', email: 'bob@company.org', age: 45, created_at: time.now().str()},
        User{id: s.next_user_id++, name: 'Alice Brown', email: 'alice@tech.io', age: 29, created_at: time.now().str()},
        User{id: s.next_user_id++, name: 'Charlie Davis', email: 'charlie@web.com', age: 38, created_at: time.now().str()},
    ]
    
    // Demo Products
    s.products = [
        Product{id: s.next_product_id++, name: 'Laptop Pro', description: 'High-performance laptop', price: 1299.99, stock: 50, category: 'Electronics', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Wireless Mouse', description: 'Ergonomic wireless mouse', price: 49.99, stock: 200, category: 'Electronics', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'USB-C Hub', description: '7-in-1 USB-C hub', price: 79.99, stock: 150, category: 'Accessories', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Mechanical Keyboard', description: 'RGB mechanical keyboard', price: 159.99, stock: 75, category: 'Electronics', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Monitor 27"', description: '4K UHD monitor', price: 449.99, stock: 30, category: 'Electronics', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Desk Chair', description: 'Ergonomic office chair', price: 299.99, stock: 40, category: 'Furniture', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Desk Lamp', description: 'LED desk lamp', price: 39.99, stock: 100, category: 'Furniture', created_at: time.now().str()},
        Product{id: s.next_product_id++, name: 'Webcam HD', description: '1080p webcam', price: 89.99, stock: 80, category: 'Electronics', created_at: time.now().str()},
    ]
    
    // Demo Orders
    s.orders = [
        Order{id: s.next_order_id++, user_id: 1, user_name: 'John Doe', items: [], total: 1299.99, status: 'completed', created_at: time.now().str()},
        Order{id: s.next_order_id++, user_id: 2, user_name: 'Jane Smith', items: [], total: 179.97, status: 'pending', created_at: time.now().str()},
        Order{id: s.next_order_id++, user_id: 3, user_name: 'Bob Wilson', items: [], total: 159.99, status: 'completed', created_at: time.now().str()},
        Order{id: s.next_order_id++, user_id: 1, user_name: 'John Doe', items: [], total: 749.98, status: 'shipped', created_at: time.now().str()},
        Order{id: s.next_order_id++, user_id: 4, user_name: 'Alice Brown', items: [], total: 169.97, status: 'pending', created_at: time.now().str()},
    ]
    
    s.save_to_file() or {
        println('Warning: Could not save demo data')
    }
}
```

### DuckDB CRUD Operations

#### CREATE

```v
// Create User
pub fn (mut s DuckDBService) create_user(name string, email string, age int) !User {
    if !email.contains('@') {
        return error('Invalid email')
    }
    
    user := User{
        id: s.next_user_id++
        name: name
        email: email
        age: age
        created_at: time.now().str()
    }
    
    s.users << user
    s.save_to_file() or {
        println('Warning: Could not save user to file')
    }
    
    return user
}

// Create Product
pub fn (mut s DuckDBService) create_product(
    name string, 
    description string, 
    price f64, 
    stock int, 
    category string
) !Product {
    product := Product{
        id: s.next_product_id++
        name: name
        description: description
        price: price
        stock: stock
        category: category
        created_at: time.now().str()
    }
    
    s.products << product
    s.save_to_file() or {
        println('Warning: Could not save product to file')
    }
    
    return product
}
```

#### READ

```v
// Get All Users
pub fn (s DuckDBService) get_all_users() []User {
    mut users := s.users.clone()
    users.reverse()  // Show newest first
    return users
}

// Get User by ID
pub fn (s DuckDBService) get_user_by_id(id int) ?User {
    for user in s.users {
        if user.id == id {
            return user
        }
    }
    return none
}

// Get Users with Pagination
pub fn (s DuckDBService) get_users_paginated(limit int, offset int) []User {
    mut users := s.users.clone()
    users.reverse()
    
    if offset >= users.len {
        return []User{}
    }
    
    end := math.min(offset + limit, users.len)
    return users[offset..end]
}

// Get User Count
pub fn (s DuckDBService) get_user_count() int {
    return s.users.len
}

// Search Users
pub fn (s DuckDBService) search_users(query string) []User {
    mut results := []User{}
    query_lower := query.to_lower()
    
    for user in s.users {
        if user.name.to_lower().contains(query_lower) ||
           user.email.to_lower().contains(query_lower) {
            results << user
        }
    }
    
    return results
}
```

#### UPDATE

```v
// Update User
pub fn (mut s DuckDBService) update_user(id int, name string, email string, age int) !User {
    for i, user in s.users {
        if user.id == id {
            s.users[i].name = name
            s.users[i].email = email
            s.users[i].age = age
            s.save_to_file() or {
                println('Warning: Could not save updated user')
            }
            return s.users[i]
        }
    }
    return error('User not found')
}

// Update Product
pub fn (mut s DuckDBService) update_product(
    id int, 
    name string, 
    description string, 
    price f64, 
    stock int, 
    category string
) !Product {
    for i, product in s.products {
        if product.id == id {
            s.products[i].name = name
            s.products[i].description = description
            s.products[i].price = price
            s.products[i].stock = stock
            s.products[i].category = category
            s.save_to_file() or {
                println('Warning: Could not save updated product')
            }
            return s.products[i]
        }
    }
    return error('Product not found')
}
```

#### DELETE

```v
// Delete User
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
    s.save_to_file() or {
        println('Warning: Could not save deleted user')
    }
}

// Delete Product
pub fn (mut s DuckDBService) delete_product(id int) ! {
    mut found := false
    mut new_products := []Product{}
    
    for product in s.products {
        if product.id == id {
            found = true
            continue
        }
        new_products << product
    }
    
    if !found {
        return error('Product not found')
    }
    
    s.products = new_products
    s.save_to_file() or {
        println('Warning: Could not save deleted product')
    }
}
```

### DuckDB Best Practices

#### 1. Batch Save Operations

```v
// ✅ GOOD: Save once after multiple operations
pub fn (mut s DuckDBService) update_user_and_order(user_id int, order_id int) ! {
    // Update user
    for i, user in s.users {
        if user.id == user_id {
            s.users[i].name = 'Updated Name'
            break
        }
    }
    
    // Update order
    for i, order in s.orders {
        if order.id == order_id {
            s.orders[i].status = 'completed'
            break
        }
    }
    
    // Save once
    s.save_to_file() or {
        return err
    }
}

// ❌ BAD: Save after each operation
pub fn (mut s DuckDBService) update_user_and_order_bad(user_id int, order_id int) ! {
    // Update user and save
    // Update order and save (unnecessary second save)
}
```

#### 2. Use Cloning for Immutability

```v
// ✅ GOOD: Clone before modifying
pub fn (s DuckDBService) get_sorted_users() []User {
    mut users := s.users.clone()
    users.sort(fn (a &User, b &User) int {
        return a.name.compare(b.name)
    })
    return users
}

// ❌ BAD: Modifying original array
pub fn (s DuckDBService) get_sorted_users_bad() []User {
    s.users.sort(...)  // Modifies original!
    return s.users
}
```

#### 3. Implement Search with Debouncing

```v
// Frontend service with debounce
private searchDebounce?: ReturnType<typeof setTimeout>;

searchUsers(query: string): void {
    if (this.searchDebounce) {
        clearTimeout(this.searchDebounce);
    }
    
    this.searchDebounce = setTimeout(async () => {
        const results = await this.api.call<User[]>('searchUsers', { query });
        this.users.set(results.data);
    }, 300);
}
```

### DuckDB Troubleshooting

| Issue | Solution |
|-------|----------|
| Data not persisting | Check `save_to_file()` is called after mutations |
| JSON parse error | Verify JSON file format, check for corruption |
| ID conflicts | Ensure `next_*_id` counters are saved/loaded |
| Slow search | Implement indexing or use SQLite for large datasets |
| Memory usage | DuckDB stores all data in memory; use SQLite for large datasets |

---

## Common Patterns

### Data Models

```v
// src/models/models.v
module models

pub struct User {
pub mut:
    id          int
    name        string
    email       string
    age         int
    created_at  string
}

pub struct Product {
pub mut:
    id          int
    name        string
    description string
    price       f64
    stock       int
    category    string
    created_at  string
}

pub struct Order {
pub mut:
    id          int
    user_id     int
    user_name   string
    items       []OrderItem
    total       f64
    status      string
    created_at  string
}

pub struct OrderItem {
pub mut:
    product_id   int
    product_name string
    quantity    int
    price       f64
}

pub struct UserStats {
pub mut:
    total_users    int
    today_count    int
    unique_domains int
}
```

### API Handlers

```v
// src/api_handlers.v
module main

import vwebui as ui
import json

// Register all CRUD handlers
pub fn register_crud_handlers(mut window_mgr &ui.WebUIWindowManager, mut storage &StorageService) {
    register_user_handlers(mut window_mgr, mut storage)
    register_product_handlers(mut window_mgr, mut storage)
    register_order_handlers(mut window_mgr, mut storage)
}

// User Handlers
fn register_user_handlers(mut window_mgr &ui.WebUIWindowManager, mut storage &StorageService) {
    // GET all users
    window_mgr.bind('getUsers', fn [storage] (e &ui.Event) string {
        users := storage.get_all_users()
        return ok(json.encode(users))
    })
    
    // GET user by ID
    window_mgr.bind('getUserById', fn [storage] (e &ui.Event) string {
        mut req := GetUserRequest{}
        json.decode(GetUserRequest, e.element) or {
            return bad_request('Invalid request')
        }
        
        user := storage.get_user_by_id(req.id) or {
            return not_found('User')
        }
        return ok(json.encode(user))
    })
    
    // CREATE user
    window_mgr.bind('createUser', fn [mut storage] (e &ui.Event) string {
        mut req := CreateUserRequest{}
        json.decode(CreateUserRequest, e.element) or {
            return bad_request('Invalid request')
        }
        
        // Validate
        result := validate_user_request(req.name, req.email, req.age)
        if !result.is_valid {
            return validation_error(result.first_error())
        }
        
        user := storage.create_user(req.name, req.email, req.age) or {
            return bad_request('${err}')
        }
        return created(json.encode(user))
    })
    
    // UPDATE user
    window_mgr.bind('updateUser', fn [mut storage] (e &ui.Event) string {
        mut req := UpdateUserRequest{}
        json.decode(UpdateUserRequest, e.element) or {
            return bad_request('Invalid request')
        }
        
        user := storage.update_user(req.id, req.name, req.email, req.age) or {
            return not_found('User')
        }
        return ok(json.encode(user))
    })
    
    // DELETE user
    window_mgr.bind('deleteUser', fn [mut storage] (e &ui.Event) string {
        mut req := DeleteUserRequest{}
        json.decode(DeleteUserRequest, e.element) or {
            return bad_request('Invalid request')
        }
        
        storage.delete_user(req.id) or {
            return not_found('User')
        }
        return message_response('User deleted')
    })
}
```

### Frontend Components

```typescript
// frontend/src/views/shared/data-table.component.ts
@Component({
  selector: 'app-data-table',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="data-table">
      <!-- Search -->
      <div class="table-header">
        <input 
          type="text" 
          [(ngModel)]="searchQuery"
          (input)="filterItems()"
          placeholder="Search..."
        />
        <button (click)="showCreateModal()">Create New</button>
      </div>
      
      <!-- Table -->
      <table>
        <thead>
          <tr>
            @for (column of config.columns; track column.key) {
              <th [style.width]="column.width">{{ column.label }}</th>
            }
          </tr>
        </thead>
        <tbody>
          @for (item of filteredItems; track item.id) {
            <tr>
              @for (column of config.columns; track column.key) {
                <td>{{ item[column.key] }}</td>
              }
            </tr>
          }
        </tbody>
      </table>
      
      <!-- Pagination -->
      <div class="pagination">
        <button (click)="previousPage()" [disabled]="currentPage === 0">Previous</button>
        <span>Page {{ currentPage + 1 }} of {{ totalPages }}</span>
        <button (click)="nextPage()" [disabled]="currentPage >= totalPages - 1">Next</button>
      </div>
    </div>
  `
})
export class DataTableComponent<T extends { id: number }> {
  @Input() config: DataTableConfig | null = null;
  @Input() items: T[] = [];
  @Output() itemsChange = new EventEmitter<T[]>();
  
  filteredItems: T[] = [];
  searchQuery = '';
  currentPage = 0;
  pageSize = 10;
  
  get totalPages(): number {
    return Math.ceil(this.filteredItems.length / this.pageSize);
  }
  
  filterItems(): void {
    const query = this.searchQuery.toLowerCase();
    if (!query) {
      this.filteredItems = [...this.items];
      return;
    }
    
    this.filteredItems = this.items.filter(item =>
      Object.values(item).some(val =>
        String(val).toLowerCase().includes(query)
      )
    );
    this.currentPage = 0;
  }
  
  showCreateModal(): void {
    // Open create modal
  }
}
```

### Validation

```v
// src/validator.v
module main

pub struct ValidationResult {
pub mut:
    is_valid bool
    errors   []ValidationError
}

pub struct ValidationError {
pub mut:
    field   string
    message string
}

// User Validation
pub fn validate_user_request(name string, email string, age int) ValidationResult {
    mut v := new_validator()
    v.required('name', name)
    v.email('email', email)
    v.int_range('age', age, 1, 150)
    return v.result()
}

// Product Validation
pub fn validate_product_request(name string, price f64, stock int) ValidationResult {
    mut v := new_validator()
    v.required('name', name)
    v.positive('price', price)
    v.non_negative('stock', stock)
    return v.result()
}

// Validator Implementation
pub struct Validator {
pub mut:
    errors []ValidationError
}

pub fn new_validator() &Validator {
    return &Validator{
        errors: []ValidationError{}
    }
}

pub fn (mut v Validator) required(field string, value string) &Validator {
    if value.trim_space().len == 0 {
        v.errors << ValidationError{
            field: field
            message: '${field} is required'
        }
    }
    return v
}

pub fn (mut v Validator) email(field string, value string) &Validator {
    if value.len > 0 && !value.contains('@') {
        v.errors << ValidationError{
            field: field
            message: 'Invalid email format'
        }
    }
    return v
}

pub fn (mut v Validator) int_range(field string, value int, min int, max int) &Validator {
    if value < min || value > max {
        v.errors << ValidationError{
            field: field
            message: '${field} must be between ${min} and ${max}'
        }
    }
    return v
}

pub fn (v Validator) result() ValidationResult {
    return ValidationResult{
        is_valid: v.errors.len == 0
        errors: v.errors.clone()
    }
}

pub fn (v Validator) first_error() string {
    if v.errors.len == 0 {
        return ''
    }
    return v.errors[0].message
}
```

---

## Testing Checklist

### Backend Tests

- [ ] **CREATE Tests**
  - [ ] Create valid user
  - [ ] Create user with invalid email
  - [ ] Create user with missing name
  - [ ] Create product with negative price
  - [ ] Create order with invalid user_id

- [ ] **READ Tests**
  - [ ] Get all users
  - [ ] Get user by ID
  - [ ] Get user by ID (not found)
  - [ ] Get users with pagination
  - [ ] Search users by name
  - [ ] Search users by email

- [ ] **UPDATE Tests**
  - [ ] Update existing user
  - [ ] Update non-existent user
  - [ ] Update with invalid email
  - [ ] Update product price

- [ ] **DELETE Tests**
  - [ ] Delete existing user
  - [ ] Delete non-existent user
  - [ ] Delete cascades to orders

- [ ] **Validation Tests**
  - [ ] Required field validation
  - [ ] Email format validation
  - [ ] Age range validation
  - [ ] Price validation

### Frontend Tests

- [ ] **Component Tests**
  - [ ] DataTable renders correctly
  - [ ] Search filters items
  - [ ] Pagination works
  - [ ] Create modal opens
  - [ ] Edit modal populates data

- [ ] **Service Tests**
  - [ ] ApiService calls backend
  - [ ] Error handling works
  - [ ] Loading state updates
  - [ ] Cache works correctly

- [ ] **Integration Tests**
  - [ ] Create user flow
  - [ ] Edit user flow
  - [ ] Delete user flow
  - [ ] Search and filter flow

### Integration Tests

- [ ] **End-to-End Flow**
  - [ ] Application starts
  - [ ] Dashboard loads
  - [ ] Users table displays
  - [ ] Create user succeeds
  - [ ] Update user persists
  - [ ] Delete user removes from list
  - [ ] Search returns correct results
  - [ ] Pagination navigates correctly

- [ ] **Error Scenarios**
  - [ ] Invalid email shows error
  - [ ] Missing required field shows error
  - [ ] Network error handled gracefully
  - [ ] Duplicate email rejected

---

## Quick Reference

### SQLite Commands

```bash
# Open database
sqlite3 data/app.db

# List tables
.tables

# View schema
.schema users

# Query data
SELECT * FROM users LIMIT 10;

# Export data
.dump > backup.sql

# Import data
.read backup.sql
```

### DuckDB Commands

```bash
# View JSON data
cat data/duckdb_demo.json | jq

# Validate JSON
cat data/duckdb_demo.json | jq '.' > /dev/null && echo "Valid JSON"

# Backup data
cp data/duckdb_demo.json data/duckdb_backup.json
```

### Common Queries

```sql
-- Get user count
SELECT COUNT(*) FROM users;

-- Get users by domain
SELECT *, substr(email, instr(email, '@') + 1) as domain 
FROM users 
GROUP BY domain;

-- Get product categories
SELECT category, COUNT(*) as count 
FROM products 
GROUP BY category;

-- Get order statistics
SELECT status, COUNT(*) as count, SUM(total) as revenue 
FROM orders 
GROUP BY status;
```

---

*Last Updated: 2026-03-29*
