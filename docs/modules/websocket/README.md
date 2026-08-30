# 🔌 WebSocket Server Module Architecture

**Location:** `apps/web-dashboard/server/websocket-server/`  
**Barrel Entry:** `apps/web-dashboard/server/websocket-server.ts` (18 lines)  
**Status:** Dashboard Real-Time Core  
**Structure:** 18 native modules behind a thin barrel entry

---

## Overview

The WebSocket Server manages bidirectional real-time communication between the dashboard and the Gentle-Vanguard backend. It handles 30+ message types, maintains 100+ concurrent connections, and ensures data consistency via acks and retries.

**Key Responsibility:** Reliable real-time observability streaming with recovery.

---

## Module Structure (18 modules)

```
websocket-server/
├── connection.ts        # Client lifecycle (connect, auth, close)
├── message-handler.ts   # Route & validate incoming messages
├── metrics-stream.ts    # Real-time metrics push
├── traces-stream.ts     # Request trace streaming
├── alerts-stream.ts     # Alert delivery + escalation
├── session-sync.ts      # Session state synchronization
├── tenant-manager.ts    # Multi-tenant isolation
├── auth.ts              # WebSocket authentication
├── rate-limiter.ts      # Per-client rate limits
├── retry-queue.ts       # Unacked message retry
├── compression.ts       # Message compression (gzip)
├── heartbeat.ts         # Ping/pong keepalive
├── reconnect.ts         # Reconnection handshake
├── state-cache.ts       # Client state snapshots
├── error-handler.ts     # Error recovery
├── telemetry.ts         # WS metrics collection
├── cli.ts               # Management CLI
└── index.ts             # Main server (18 lines)
```

---

## Connection Flow

```
Client Connect
  ↓
[connection.ts] - Acquire connection ID
  ↓
[auth.ts] - JWT validation, user lookup
  ↓
[tenant-manager.ts] - RBAC checks, tenant isolation
  ↓
[state-cache.ts] - Send initial state (metrics, last 100 traces)
  ↓
[heartbeat.ts] - Start ping/pong (30s interval)
  ↓
Ready for messages
```

---

## Message Types (30+)

| Category | Messages |
|----------|----------|
| **Metrics** | metric:cpu, metric:memory, metric:latency, metric:throughput |
| **Traces** | trace:new, trace:complete, trace:error |
| **Alerts** | alert:trigger, alert:resolve, alert:acknowledge |
| **Sessions** | session:started, session:ended, session:error |
| **Config** | config:reload, config:update |
| **Feedback** | feedback:submit, feedback:ack |
| **Control** | ping, pong, reconnect, close |

---

## Key Features

### 1. **Multi-Tenant Isolation** (tenant-manager.ts)
- Clients can only see their tenant's data
- Row-level security on all streams
- Audit logging per tenant

### 2. **Rate Limiting** (rate-limiter.ts)
- Per-client: 1000 msg/s
- Per-tenant: 100k msg/s
- Circuit breaker on burst

### 3. **Automatic Retries** (retry-queue.ts)
- Unacked messages queued for 30s
- Exponential backoff
- Fallback to polling if WS fails

### 4. **Compression** (compression.ts)
- DEFLATE compression on >1KB messages
- Reduces bandwidth 70-80%
- Transparent to client

### 5. **Heartbeat & Reconnect** (heartbeat.ts, reconnect.ts)
- Ping every 30s
- Timeout: 60s
- Reconnect preserves session state

### 6. **State Snapshots** (state-cache.ts)
- On reconnect, send full state (metrics, last 100 traces, current alerts)
- Prevents UI desync
- <500ms overhead per reconnect

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Message latency | <50ms (p95) |
| Connection setup | <500ms |
| Concurrent connections | 100+ |
| Throughput | 10k msg/s |
| Bandwidth (compressed) | <2Mbps per 100 clients |
| Memory per client | ~5MB |

---

## Configuration

**File:** `config/websocket.json`

```json
{
  "port": 3001,
  "host": "localhost",
  "maxConnections": 500,
  "messageTimeout": 30000,
  "heartbeatInterval": 30000,
  "compression": {
    "enabled": true,
    "threshold": 1024
  },
  "rateLimits": {
    "perClientPerSec": 1000,
    "perTenantPerSec": 100000
  }
}
```

---

## CLI Management

```bash
# Server status
npm run ws:status

# List active connections
npm run ws:connections

# Broadcast message to all clients
npm run ws:broadcast --message '{"type":"alert","level":"info"}'

# Drop specific client
npm run ws:drop-client --clientId abc123

# Start server
npm run ws:start

# Stop server
npm run ws:stop
```

---

## Monitoring

**Metrics exposed:**
- Active connections
- Messages/sec
- Error rate (%)
- Reconnect rate
- Compression ratio
- Memory usage

**Dashboard:** Real-time in `app/web-dashboard` → System → WebSocket

---

## Error Handling

| Error | Action |
|-------|--------|
| Auth failure | Close (1008) + retry with new token |
| Rate limit | 429 + backoff 5-60s |
| Tenant mismatch | Drop connection (1003) |
| Malformed message | Log + continue (no close) |
| Network timeout | Retry (heartbeat detects) |

---

## Integration

**Connects to:**
- Authentication (auth.ts ← Session DB)
- Real-data pipeline (metrics-stream ← real-data/)
- Alerts (alerts-stream ← alerts system)
- Session manager (session-sync)
- Tenant system (tenant-manager)

**Used by:**
- `apps/web-dashboard` (React client)
- External monitoring tools (WebSocket client libs)

---

## Test Coverage

**Location:** `tests/e2e/dashboard-websocket/`
- `connection.test.ts` - Connect/auth/close
- `message-flow.test.ts` - Send/recv/ack
- `reconnection.test.ts` - State recovery
- `performance.test.ts` - Throughput benchmarks
- `tenant-isolation.test.ts` - RBAC validation

**Target:** 85%+ coverage

---

## Troubleshooting

**Q: Connections drop frequently**
```bash
npm run ws:status
# Check heartbeat interval, network latency
```

**Q: Memory growing unbounded**
```bash
npm run ws:memory-profile
# Check state-cache size, message queue
```

**Q: High latency**
```bash
npm run ws:latency-report
# Check compression ratio, throughput
```

---

**See:** `docs/modules/MODULE-STRUCTURE.md`  
**Dashboard:** `apps/web-dashboard/`  
**Tests:** `tests/e2e/dashboard-websocket/*.test.ts`

