# Multi-Channel Communication Guide

**Purpose:** Provide multiple non-HTTP communication patterns between backend (V) and frontend (Angular).

---

## Overview

This application uses **five distinct communication channels** instead of traditional HTTP/HTTPS:

1. **WebUI Bridge** - RPC-style synchronous calls
2. **Event Bus** - Pub/Sub event system
3. **Shared State** - Memory-like shared data
4. **Message Queue** - Async message processing
5. **Broadcast** - One-to-many messaging

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend (Angular)                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CommunicationService                                     │   │
│  │  ├─ call()           → WebUI Bridge                      │   │
│  │  ├─ publish/emit()   → Event Bus                         │   │
│  │  ├─ setState/getState() → Shared State                  │   │
│  │  ├─ enqueue/dequeue() → Message Queue                   │   │
│  │  └─ broadcast()      → Broadcast Channel                │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ WebUI Bridge (window.call / window.bind)
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    Backend (V Language)                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CommunicationService                                     │   │
│  │  ├─ send_request()   ← WebUI Bridge                      │   │
│  │  ├─ publish()        ← Event Bus                         │   │
│  │  ├─ set_state/get_state() ← Shared State                │   │
│  │  ├─ enqueue/dequeue() ← Message Queue                   │   │
│  │  └─ broadcast()      ← Broadcast Channel                │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Channel 1: WebUI Bridge (RPC)

**Pattern:** Request/Response
**Use Case:** Synchronous API calls
**Latency:** <10ms

### Backend (V)

```v
// Register handler
window_mgr.bind('getUsers', fn [db] (e &ui.Event) string {
    users := db.get_all_users()
    return '{"success":true,"data":${json.encode(users)}}'
})
```

### Frontend (TypeScript)

```typescript
// Call backend
const users = await comm.call<User[]>('getUsers');

// Or with error throwing
const users = await api.callOrThrow<User[]>('getUsers');
```

### API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `call<T>(fn, args)` | Call backend function | Promise<T> |
| `callWithResponse<T>(fn, args)` | Call with event response | Promise<T> |

---

## Channel 2: Event Bus (Pub/Sub)

**Pattern:** Publish/Subscribe
**Use Case:** Async event notification
**Latency:** <5ms

### Backend (V)

```v
// Subscribe to event
comm.subscribe('user_created', fn (msg &Message) {
    println('New user: ${msg.data}')
})

// Publish event
comm.publish('user_created', 'User data here', 'backend')
```

### Frontend (TypeScript)

```typescript
// Subscribe to event
const unsubscribe = comm.subscribe('user_created', (data, event) => {
    console.log('New user created:', data);
});

// Publish event (to backend)
await comm.publish('user_created', { id: 1, name: 'John' });

// Emit local event (frontend only)
comm.emit('local_event', { data: 'value' });

// Unsubscribe
unsubscribe();
```

### API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `subscribe(event, handler)` | Subscribe to event | Unsubscribe fn |
| `publish(event, data)` | Publish to backend | Promise<void> |
| `emit(event, data)` | Emit local event | void |
| `getEventHistory()` | Get event history | Promise<Message[]> |

---

## Channel 3: Shared State

**Pattern:** Key-Value Store
**Use Case:** Shared configuration, cached data
**Latency:** <1ms (local), ~50ms (sync)

### Backend (V)

```v
// Set state
comm.set_state('user_count', '42')

// Get state
count := comm.get_state('user_count')

// Get all state
all_state := comm.get_all_state()
```

### Frontend (TypeScript)

```typescript
// Set state
await comm.setState('user_count', 42);

// Get state
const count = comm.getState<number>('user_count');

// Get all state
const allState = comm.getAllState();

// Subscribe to state changes
const unsubscribe = comm.subscribeState((key, value) => {
    console.log(`State changed: ${key} = ${value}`);
});
```

### API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `getState<T>(key)` | Get state value | T \| undefined |
| `setState(key, value)` | Set state value | Promise<void> |
| `getAllState()` | Get all state | SharedState |
| `subscribeState(handler)` | Subscribe to changes | Unsubscribe fn |

---

## Channel 4: Message Queue

**Pattern:** Queue (FIFO)
**Use Case:** Async task processing, background jobs
**Latency:** Variable (queue-dependent)

### Backend (V)

```v
// Enqueue message
comm.enqueue('email_service', 'Send welcome email', 2)

// Dequeue message
msg := comm.dequeue() or {
    // Queue empty
    return
}
println('Processing: ${msg.data}')

// Peek at next message
msg := comm.peek() or {
    // Queue empty
    return
}

// Get queue length
length := comm.queue_length()
```

### Frontend (TypeScript)

```typescript
// Enqueue message
await comm.enqueue('notification', {
    type: 'email',
    to: 'user@example.com',
    subject: 'Welcome!'
}, 2); // priority 2 (high)

// Dequeue message
const message = await comm.dequeue<MessageData>();
if (message) {
    console.log('Processing:', message);
}

// Peek at next message
const next = comm.peek();

// Get queue length
const length = comm.queueLength();

// Clear queue
comm.clearQueue();
```

### API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `enqueue(dest, data, priority)` | Add to queue | Promise<void> |
| `dequeue<T>()` | Remove from queue | Promise<T \| null> |
| `peek()` | View next message | Message \| null |
| `queueLength()` | Get queue size | number |
| `clearQueue()` | Clear all messages | void |

---

## Channel 5: Broadcast

**Pattern:** One-to-Many
**Use Case:** Global notifications, system-wide events
**Latency:** <10ms

### Backend (V)

```v
// Broadcast to all clients
comm.broadcast('system_update', 'System will restart in 5 minutes')
```

### Frontend (TypeScript)

```typescript
// Broadcast to all clients
await comm.broadcast('announcement', {
    message: 'Meeting in 5 minutes',
    priority: 'high'
});

// Listen for broadcasts
comm.onBroadcast((data, event) => {
    console.log('Broadcast received:', data);
});
```

### API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `broadcast(event, data)` | Send to all | Promise<void> |
| `onBroadcast(handler)` | Listen for broadcasts | Unsubscribe fn |

---

## Communication Statistics

### Get Stats

```typescript
// Frontend
const stats = comm.getStats();
console.log('Total messages:', stats.totalMessages);
console.log('By channel:', stats.messagesByChannel);
console.log('Queue length:', stats.queueLength);
```

```v
// Backend
stats := comm.get_stats()
println('Total: ${stats.total_messages}')
println('Queue: ${stats.queue_length}')
```

### Stats Structure

```typescript
interface CommunicationStats {
  totalMessages: number;
  messagesByChannel: Record<string, number>;
  messagesByType: Record<string, number>;
  queueLength: number;
  broadcastCount: number;
  activeSubscriptions: number;
  stateVersion: number;
  lastActivity: number;
}
```

---

## Best Practices

### 1. Choose the Right Channel

| Use Case | Recommended Channel |
|----------|---------------------|
| API call, get data | WebUI Bridge |
| User action notification | Event Bus |
| App configuration | Shared State |
| Background task | Message Queue |
| System announcement | Broadcast |

### 2. Handle Errors Gracefully

```typescript
try {
    await comm.call('getData');
} catch (error) {
    // Fallback to shared state
    const cachedData = comm.getState('cached_data');
}
```

### 3. Clean Up Subscriptions

```typescript
ngOnInit() {
    this.unsubscribe = this.comm.subscribe('event', handler);
}

ngOnDestroy() {
    this.unsubscribe();
}
```

### 4. Use Priority for Messages

```typescript
// Low priority (0)
comm.enqueue('log', data, 0);

// Normal priority (1)
comm.enqueue('email', data, 1);

// High priority (2)
comm.enqueue('alert', data, 2);

// Critical priority (3)
comm.enqueue('emergency', data, 3);
```

### 5. Monitor Statistics

```typescript
// Check queue health
if (comm.queueLength() > 100) {
    console.warn('Message queue backing up!');
}

// Monitor channel usage
const usage = comm.getChannelUsage();
console.log('Most used channel:', 
    Object.entries(usage).sort((a, b) => b[1] - a[1])[0]?.[0]);
```

---

## Performance Considerations

### Latency by Channel

| Channel | Typical Latency | Max Throughput |
|---------|----------------|----------------|
| WebUI Bridge | <10ms | 1000 req/s |
| Event Bus | <5ms | 5000 events/s |
| Shared State | <1ms | 10000 ops/s |
| Message Queue | Variable | 500 msg/s |
| Broadcast | <10ms | 1000 msg/s |

### Optimization Tips

1. **Batch messages** - Group related messages
2. **Use shared state for caching** - Reduce backend calls
3. **Prioritize critical messages** - Use priority levels
4. **Clean up subscriptions** - Prevent memory leaks
5. **Monitor queue length** - Prevent backlog

---

## Security Considerations

1. **Validate all input** - Sanitize data from frontend
2. **Rate limit broadcasts** - Prevent abuse
3. **Authenticate events** - Verify event sources
4. **Encrypt sensitive state** - Don't store secrets in shared state
5. **Monitor message patterns** - Detect anomalies

---

## Troubleshooting

### Issue: Messages not being received

**Solution:**
1. Check subscription is active
2. Verify event name matches
3. Check message priority
4. Monitor queue length

### Issue: Shared state out of sync

**Solution:**
1. Force sync: `comm.getAllState()`
2. Check state version
3. Verify backend set_state called
4. Check for race conditions

### Issue: Queue backing up

**Solution:**
1. Increase dequeue frequency
2. Add more workers
3. Check for processing errors
4. Clear old messages: `comm.clearQueue()`

---

## Migration from HTTP

### Before (HTTP)

```typescript
// HTTP GET
const users = await http.get('/api/users');

// HTTP POST
await http.post('/api/events', { type: 'click' });

// WebSocket
socket.emit('message', data);
```

### After (Multi-Channel)

```typescript
// WebUI Bridge (replaces HTTP GET)
const users = await comm.call<User[]>('getUsers');

// Event Bus (replaces HTTP POST)
await comm.publish('event', { type: 'click' });

// Message Queue (replaces WebSocket)
await comm.enqueue('processor', data);
```

---

*Last Updated: 2026-03-16*
*Version: 1.0*
