# API Reference

Complete API reference for backend handlers exposed to the frontend.

## Table of Contents

1. [System Endpoints](#system-endpoints)
2. [Network Endpoints](#network-endpoints)
3. [Process Endpoints](#process-endpoints)
4. [Service Endpoints](#service-endpoints)
5. [Error Endpoints](#error-endpoints)

## System Endpoints

### getSystemInfo

Returns comprehensive system information.

**Handler:** `getSystemInfo()`

**Response:**
```json
{
    "hostname": "mycomputer",
    "os_name": "Linux",
    "os_version": "5.15.0-generic",
    "arch": "x86_64",
    "cpu_model": "Intel Core i7",
    "cpu_cores": 8,
    "cpu_usage": 25.5,
    "memory_total": 17179869184,
    "memory_used": 8589934592,
    "memory_free": 8589934592,
    "memory_percent": 50.0,
    "uptime": 86400,
    "boot_time": 1234567890
}
```

**Frontend Usage:**
```typescript
const info = await callBackend<SystemInfo>('getSystemInfo');
```

---

### getMemoryInfo

Returns memory statistics.

**Handler:** `getMemoryInfo()`

**Response:**
```json
{
    "total": 17179869184,
    "used": 8589934592,
    "free": 8589934592,
    "available": 10737418240,
    "percent": 50.0,
    "buffers": 536870912,
    "cached": 2147483648
}
```

---

### getCPUInfo

Returns CPU statistics.

**Handler:** `getCPUInfo()`

**Response:**
```json
{
    "model": "Intel Core i7",
    "cores": 8,
    "logical": 16,
    "usage": 25.5,
    "frequency": 3500,
    "load_avg_1": 1.5,
    "load_avg_5": 1.2,
    "load_avg_15": 1.0
}
```

---

### getDiskInfo

Returns disk usage for all mounted filesystems.

**Handler:** `getDiskInfo()`

**Response:**
```json
[
    {
        "device": "/dev/sda1",
        "mountpoint": "/",
        "fstype": "ext4",
        "total": 536870912000,
        "used": 268435456000,
        "free": 268435456000,
        "percent": 50.0
    }
]
```

---

## Network Endpoints

### getNetworkInfo

Returns network interface information.

**Handler:** `getNetworkInfo()`

**Response:**
```json
[
    {
        "name": "eth0",
        "ip_address": "192.168.1.100",
        "ip6_address": "fe80::1",
        "mac_address": "00:11:22:33:44:55",
        "netmask": "255.255.255.0",
        "state": "up",
        "rx_bytes": 1234567890,
        "tx_bytes": 987654321
    }
]
```

---

### getConnectionStatus

Returns connection status.

**Handler:** `getConnectionStatus()`

**Response:**
```json
{
    "is_online": true,
    "hostname": "mycomputer",
    "ip_address": "192.168.1.100",
    "public_ip": "203.0.113.1",
    "latency_ms": 25,
    "dns_servers": ["8.8.8.8", "8.8.4.4"],
    "gateway": "192.168.1.1"
}
```

---

### getNetworkStats

Returns network statistics.

**Handler:** `getNetworkStats()`

**Response:**
```json
{
    "bytes_sent": 987654321,
    "bytes_received": 1234567890,
    "packets_sent": 1234567,
    "packets_received": 7654321,
    "errors_in": 0,
    "errors_out": 0,
    "dropped_in": 0,
    "dropped_out": 0
}
```

---

## Process Endpoints

### getProcessInfo

Returns running process information.

**Handler:** `getProcessInfo()`

**Response:**
```json
[
    {
        "pid": 1234,
        "ppid": 1,
        "name": "firefox",
        "cmdline": "firefox --new-window",
        "status": "Running",
        "user": "user",
        "cpu_percent": 5.5,
        "memory_percent": 10.2,
        "memory_rss": 536870912,
        "threads": 48
    }
]
```

---

### getSystemLoad

Returns system load averages.

**Handler:** `getSystemLoad()`

**Response:**
```json
{
    "load_avg_1": 1.5,
    "load_avg_5": 1.2,
    "load_avg_15": 1.0,
    "running_procs": 5,
    "total_procs": 250,
    "last_pid": 12345
}
```

---

### getProcessStats

Returns process statistics.

**Handler:** `getProcessStats()`

**Response:**
```json
{
    "total_processes": 250,
    "running_processes": 5,
    "sleeping_processes": 240,
    "zombie_processes": 0,
    "stopped_processes": 5
}
```

---

## Service Endpoints

### getHealthStatus

Returns health check summary.

**Handler:** `getHealthStatus()`

**Response:**
```json
{
    "is_healthy": true,
    "total_checks": 3,
    "healthy_checks": 3,
    "unhealthy_checks": 0,
    "status": "healthy",
    "checks": {
        "memory": {
            "is_healthy": true,
            "status": "healthy",
            "message": "Memory usage: 45.2%"
        },
        "disk": {
            "is_healthy": true,
            "status": "healthy",
            "message": "All disks OK"
        },
        "processes": {
            "is_healthy": true,
            "status": "healthy",
            "message": "Total: 250, Zombies: 0"
        }
    }
}
```

---

### getMetrics

Returns application metrics.

**Handler:** `getMetrics()`

**Response:**
```json
{
    "metrics": {
        "app.starts": {"value": 5, "count": 5},
        "api.calls": {"value": 1000, "count": 1000}
    },
    "uptime_seconds": 86400
}
```

---

### cacheSet

Sets a cache value.

**Handler:** `cacheSet(data)`

**Request:**
```json
{
    "key": "user:123",
    "value": "{\"name\":\"John\"}",
    "ttl": 300
}
```

**Response:**
```json
{
    "success": true,
    "key": "user:123"
}
```

---

### cacheGet

Gets a cache value.

**Handler:** `cacheGet(data)`

**Request:**
```json
{
    "key": "user:123"
}
```

**Response:**
```json
{
    "success": true,
    "key": "user:123",
    "value": "{\"name\":\"John\"}"
}
```

---

### cacheStats

Returns cache statistics.

**Handler:** `cacheStats()`

**Response:**
```json
{
    "total_entries": 50,
    "hit_count": 1000,
    "miss_count": 100,
    "max_size": 1000,
    "hit_rate": 90.9
}
```

---

### getConfig

Returns configuration.

**Handler:** `getConfig()`

**Response:**
```json
{
    "app_name": "Desktop Dashboard",
    "debug": "true",
    "port": "8080"
}
```

---

### authLogin

Authenticates a user.

**Handler:** `authLogin(data)`

**Request:**
```json
{
    "username": "john",
    "password": "secret"
}
```

**Response:**
```json
{
    "success": true,
    "user_id": "user_123",
    "username": "john",
    "roles": ["user"],
    "permissions": ["read"],
    "token": "token_user_123_1234567890",
    "expires_at": 1234571490
}
```

---

### authLogout

Logs out the current user.

**Handler:** `authLogout()`

**Response:**
```json
{
    "success": true
}
```

---

### authGetCurrentUser

Gets the current user.

**Handler:** `authGetCurrentUser()`

**Response:**
```json
{
    "id": "user_123",
    "username": "john",
    "email": "john@example.com",
    "roles": ["user"],
    "permissions": ["read"],
    "created_at": 1234567890,
    "last_login": 1234567890
}
```

---

### getServiceInfo

Returns registered service information.

**Handler:** `getServiceInfo()`

**Response:**
```json
{
    "registered_services": [
        "logger",
        "config",
        "cache",
        "validation",
        "metrics",
        "health_check",
        "system_info",
        "auth"
    ],
    "count": 8
}
```

---

## Error Endpoints

### getErrorStats

Returns error statistics.

**Handler:** `getErrorStats()`

**Response:**
```json
{
    "total": 100,
    "critical": 5,
    "warnings": 20,
    "info": 75
}
```

---

### getRecentErrors

Returns recent errors.

**Handler:** `getRecentErrors()`

**Response:**
```json
[
    {
        "code": 5002,
        "message": "User not found: 123",
        "timestamp": 1234567890,
        "source": "backend",
        "severity": "warning"
    }
]
```

---

### clearErrorHistory

Clears error history.

**Handler:** `clearErrorHistory()`

**Response:**
```json
{
    "success": true
}
```

---

## Error Response Format

All error responses follow this format:

```json
{
    "success": false,
    "data": null,
    "error": {
        "code": 5002,
        "message": "User not found: 123",
        "details": "",
        "field": "",
        "cause": "",
        "timestamp": 1234567890,
        "source": "backend",
        "context": {},
        "severity": "warning",
        "retryable": false
    }
}
```

## Success Response Format

All success responses follow this format:

```json
{
    "success": true,
    "data": { ... },
    "error": null
}
```
