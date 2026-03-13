# API Reference

This document describes the backend API handlers exposed to the frontend.

## Overview

Backend functions are exposed via WebUI bindings and called from frontend JavaScript.

## API Handlers

### System Information

#### getSystemInfo

Returns comprehensive system information.

**Handler:**
```v
fn get_system_info_handler() string
```

**Response:**
```json
{
    "hostname": "mycomputer",
    "arch": "x64",
    "os": "Linux",
    "platform": "linux",
    "kernel": "5.15.0",
    "cpu_count": 8
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<SystemInfo>('getSystemInfo');
```

---

#### getMemoryInfo

Returns memory statistics.

**Handler:**
```v
fn get_memory_info_handler() string
```

**Response:**
```json
{
    "total": 16777216,
    "used": 8388608,
    "free": 8388608,
    "percent": 50.0
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<MemoryInfo>('getMemoryInfo');
```

---

#### getCPUInfo

Returns CPU information.

**Handler:**
```v
fn get_cpu_info_handler() string
```

**Response:**
```json
{
    "model": "Intel Core i7",
    "cores": 8,
    "threads": 16,
    "usage": 25.5
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<CPUInfo>('getCPUInfo');
```

---

#### getDiskInfo

Returns disk usage information.

**Handler:**
```v
fn get_disk_info_handler() string
```

**Response:**
```json
[
    {
        "device": "/dev/sda1",
        "mount": "/",
        "total": 500000000000,
        "used": 250000000000,
        "free": 250000000000
    }
]
```

**Frontend Usage:**
```typescript
const result = await callBackend<DiskInfo[]>('getDiskInfo');
```

---

#### getBatteryInfo

Returns battery information.

**Handler:**
```v
fn get_battery_info_handler() string
```

**Response:**
```json
{
    "present": true,
    "capacity": 50000,
    "percent": 75,
    "state": "discharging",
    "time_remaining": 7200
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<BatteryInfo>('getBatteryInfo');
```

---

### Network Information

#### getNetworkInfo

Returns network interface information.

**Handler:**
```v
fn get_network_info_handler() string
```

**Response:**
```json
[
    {
        "name": "eth0",
        "ip": "192.168.1.100",
        "mac": "00:1A:2B:3C:4D:5E",
        "is_up": true,
        "is_loopback": false
    }
]
```

**Frontend Usage:**
```typescript
const result = await callBackend<NetworkInfo[]>('getNetworkInfo');
```

---

#### getConnectionStatus

Returns connection status.

**Handler:**
```v
fn get_connection_status_handler() string
```

**Response:**
```json
{
    "is_connected": true,
    "ip": "192.168.1.100",
    "gateway": "192.168.1.1",
    "dns": ["8.8.8.8", "8.8.4.4"]
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<ConnectionStatus>('getConnectionStatus');
```

---

#### getNetworkStats

Returns network I/O statistics.

**Handler:**
```v
fn get_network_stats_handler() string
```

**Response:**
```json
{
    "bytes_received": 1000000,
    "bytes_sent": 500000,
    "packets_received": 1000,
    "packets_sent": 500
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<NetworkStats>('getNetworkStats');
```

---

### Process Information

#### getProcessInfo

Returns process information.

**Handler:**
```v
fn get_process_info_handler() string
```

**Response:**
```json
[
    {
        "pid": 1234,
        "name": "chrome",
        "cpu": 5.5,
        "memory": 256000000,
        "status": "running"
    }
]
```

**Frontend Usage:**
```typescript
const result = await callBackend<ProcessInfo[]>('getProcessInfo');
```

---

#### getSystemLoad

Returns system load averages.

**Handler:**
```v
fn get_system_load_handler() string
```

**Response:**
```json
{
    "min1": 1.5,
    "min5": 1.2,
    "min15": 0.9
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<SystemLoad>('getSystemLoad');
```

---

#### getProcessStats

Returns process statistics.

**Handler:**
```v
fn get_process_stats_handler() string
```

**Response:**
```json
{
    "total": 250,
    "running": 5,
    "sleeping": 240,
    "stopped": 0,
    "zombie": 5
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<ProcessStats>('getProcessStats');
```

---

### Dashboard Data

#### getDashboardData

Returns all dashboard data in one call.

**Handler:**
```v
fn get_dashboard_data_handler() string
```

**Response:**
```json
{
    "system": { "hostname": "...", ... },
    "memory": { "total": ..., ... },
    "cpu": { "model": "...", ... },
    "battery": { "present": true, ... },
    "network": [...],
    "connection": { "is_connected": true, ... },
    "load": { "min1": 1.5, ... },
    "process_stats": { "total": 250, ... },
    "network_stats": { "bytes_received": ..., ... },
    "timestamp": 1234567890
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<DashboardData>('getDashboardData');
```

---

### Error Management

#### getErrorStats

Returns error statistics.

**Handler:**
```v
fn get_error_stats() string
```

**Response:**
```json
{
    "total": 10,
    "critical": 2,
    "warnings": 5,
    "info": 3
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<ErrorStats>('getErrorStats');
```

---

#### getRecentErrors

Returns recent errors.

**Handler:**
```v
fn get_recent_errors() string
```

**Response:**
```json
[
    {
        "code": 6001,
        "message": "System failure",
        "timestamp": 1234567890,
        "source": "backend"
    }
]
```

**Frontend Usage:**
```typescript
const result = await callBackend<ErrorValue[]>('getRecentErrors');
```

---

#### clearErrorHistory

Clears error history.

**Handler:**
```v
fn clear_error_history() string
```

**Response:**
```json
{
    "success": true
}
```

**Frontend Usage:**
```typescript
const result = await callBackend<void>('clearErrorHistory');
```

---

### Filesystem Operations

#### getFileInfo

Returns file information.

**Handler:**
```v
fn get_file_info_handler(path string) string
```

**Request:**
```typescript
const result = await callBackend<FileInfo>('getFileInfo', '/path/to/file');
```

**Response:**
```json
{
    "name": "file.txt",
    "path": "/path/to/file",
    "size": 1024,
    "is_dir": false,
    "is_file": true,
    "modified": 1234567890,
    "permissions": "rw-r--r--"
}
```

---

#### listDirectory

Lists directory contents.

**Handler:**
```v
fn list_directory_handler(path string, show_hidden bool) string
```

**Request:**
```typescript
const result = await callBackend<FileInfo[]>('listDirectory', '/path', false);
```

**Response:**
```json
[
    {
        "name": "file.txt",
        "path": "/path/file.txt",
        "is_dir": false,
        "size": 1024
    }
]
```

---

## Data Types

### SystemInfo

```typescript
interface SystemInfo {
    hostname: string;
    arch: string;
    os: string;
    platform: string;
    kernel: string;
    cpu_count: number;
}
```

### MemoryInfo

```typescript
interface MemoryInfo {
    total: number;
    used: number;
    free: number;
    percent: number;
}
```

### CPUInfo

```typescript
interface CPUInfo {
    model: string;
    cores: number;
    threads: number;
    usage: number;
}
```

### DiskInfo

```typescript
interface DiskInfo {
    device: string;
    mount: string;
    total: number;
    used: number;
    free: number;
}
```

### BatteryInfo

```typescript
interface BatteryInfo {
    present: boolean;
    capacity: number;
    percent: number;
    state: string;
    time_remaining: number;
}
```

### NetworkInfo

```typescript
interface NetworkInfo {
    name: string;
    ip: string;
    mac: string;
    is_up: boolean;
    is_loopback: boolean;
}
```

### ConnectionStatus

```typescript
interface ConnectionStatus {
    is_connected: boolean;
    ip: string;
    gateway: string;
    dns: string[];
}
```

### NetworkStats

```typescript
interface NetworkStats {
    bytes_received: number;
    bytes_sent: number;
    packets_received: number;
    packets_sent: number;
}
```

### ProcessInfo

```typescript
interface ProcessInfo {
    pid: number;
    name: string;
    cpu: number;
    memory: number;
    status: string;
}
```

### SystemLoad

```typescript
interface SystemLoad {
    min1: number;
    min5: number;
    min15: number;
}
```

### ProcessStats

```typescript
interface ProcessStats {
    total: number;
    running: number;
    sleeping: number;
    stopped: number;
    zombie: number;
}
```

### DashboardData

```typescript
interface DashboardData {
    system: SystemInfo;
    memory: MemoryInfo;
    cpu: CPUInfo;
    battery: BatteryInfo;
    network: NetworkInfo[];
    connection: ConnectionStatus;
    load: SystemLoad;
    process_stats: ProcessStats;
    network_stats: NetworkStats;
    timestamp: number;
}
```

### FileInfo

```typescript
interface FileInfo {
    name: string;
    path: string;
    size: number;
    is_dir: boolean;
    is_file: boolean;
    modified: number;
    permissions: string;
}
```

## Error Responses

All API calls may return error responses:

```json
{
    "success": false,
    "data": null,
    "error": {
        "code": "INTERNAL_ERROR",
        "message": "Error description",
        "details": "Technical details",
        "field": "field_name"
    }
}
```

## Rate Limiting

Currently, no rate limiting is implemented. Future versions may add:
- Request throttling
- Maximum concurrent calls
- Cooldown periods

## Versioning

API version is tied to application version. Breaking changes will increment major version.

Current version: 1.0.0
