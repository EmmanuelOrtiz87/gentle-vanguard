# Gentle-Vanguard API Documentation

**Version**: 1.0.0  
**Base URL**: `http://localhost:8080`  
**WebSocket**: `ws://localhost:8080`  
**Last Updated**: August 04, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [REST API Endpoints](#rest-api-endpoints)
4. [WebSocket API](#websocket-api)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)

---

## Overview

The Gentle-Vanguard API provides programmatic access to:
- Real-time metrics and telemetry
- Session management and traces
- Alert configuration and notifications
- Feedback collection
- Agent marketplace operations
- MCP gateway operations
- Health monitoring

### Architecture

| Component | Technology | Port |
|-----------|-----------|------|
| HTTP Server | Node.js | 8080 |
| WebSocket | ws library | 8080 |
| Database | SQLite (Nexus) | - |
| Metrics | In-memory + persisted | - |

---

## Authentication

Currently **no authentication** required for local deployments. Future versions will support:
- API key authentication
- JWT tokens
- OAuth 2.0

---

## REST API Endpoints

### Health & Status

#### `GET /api/health`

Returns overall system health status.

**Response:**
```json
{
  "status": "healthy",
  "components": {
    "websocket": "ok",
    "mcp": "ok",
    "database": "ok",
    "tracing": "ok",
    "audit": "ok",
    "checkpoints": "ok",
    "cloud": "unknown"
  },
  "timestamp": "2026-08-04T02:55:00Z"
}
```

---

### Metrics

#### `GET /api/metrics`

Returns current system metrics.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| type | string | Filter by type: token, cost, quality |

**Response:**
```json
{
  "sessions": {
    "total": 149,
    "active": 1,
    "completed": 148
  },
  "tokens": {
    "daily_budget": 60000,
    "used_today": 2400,
    "remaining": 57600
  },
  "agents": {
    "dispatched": 523,
    "completed": 512,
    "failed": 11
  }
}
```

#### `POST /api/metrics/filter`

Filter metrics with custom criteria.

**Request Body:**
```json
{
  "startTime": "2026-08-01T00:00:00Z",
  "endTime": "2026-08-04T23:59:59Z",
  "agent_codes": ["DEV", "QA"],
  "min_duration_ms": 1000
}
```

---

### Sessions

#### `GET /api/sessions`

List all sessions.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| limit | int | Max results (default: 50) |
| offset | int | Pagination offset |
| status | string | Filter by status: active, completed, failed |

**Response:**
```json
{
  "sessions": [
    {
      "id": "ses_0355e3267ffeFYPeEFyRE1z32J",
      "agent": "orchestrator",
      "status": "active",
      "start_time": "2026-08-04T02:31:00Z",
      "token_count": 4534
    }
  ],
  "total": 149,
  "limit": 50,
  "offset": 0
}
```

#### `GET /api/sessions/:id`

Get specific session details.

**Response:**
```json
{
  "id": "ses_0355e3267ffeFYPeEFyRE1z32J",
  "agent": "orchestrator",
  "status": "active",
  "messages": [...],
  "tool_calls": [...],
  "createdAt": "2026-08-04T02:31:00Z",
  "updatedAt": "2026-08-04T02:55:00Z"
}
```

---

### Traces

#### `GET /api/traces`

Get distributed tracing data.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| trace_id | string | Filter by trace ID |
| session_id | string | Filter by session |
| limit | int | Max results |

**Response:**
```json
{
  "traces": [
    {
      "trace_id": "abc123",
      "span_id": "span456",
      "parent_id": null,
      "operation": "session-autostart",
      "status": "success",
      "duration_ms": 14500
    }
  ]
}
```

---

### Alerts

#### `GET /api/alerts`

Get current alerts.

**Response:**
```json
{
  "alerts": [
    {
      "id": "alert_001",
      "severity": "warning",
      "component": "model-provider",
      "message": "Model in cooldown",
      "created_at": "2026-08-04T02:30:00Z"
    }
  ],
  "total": 2
}
```

#### `POST /api/alerts/acknowledge`

Acknowledge an alert.

**Request Body:**
```json
{ "alert_id": "alert_001" }
```

---

### Feedback

#### `GET /api/feedback`

Get collected feedback.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| session_id | string | Filter by session |
| rating | int | Filter by rating (1-5) |

#### `POST /api/feedback`

Submit feedback.

**Request Body:**
```json
{
  "span_id": "span_123",
  "rating": 5,
  "comment": "Very helpful explanation",
  "session_id": "ses_abc123"
}
```

---

### Marketplace

#### `GET /api/marketplace/skills`

List available skills.

**Response:**
```json
{
  "skills": [
    {
      "id": "api-design",
      "name": "API Design",
      "description": "Design stable APIs",
      "version": "1.0.0",
      "downloads": 42,
      "rating": 4.8
    }
  ],
  "total": 49
}
```

#### `GET /api/marketplace/skills/:id`

Get skill details.

#### `POST /api/marketplace/skills/:id/download`

Download/install a skill.

---

### MCP Gateway

#### `GET /api/mcp/servers`

List MCP servers.

**Response:**
```json
{
  "servers": [
    { "name": "skill-server", "status": "connected" },
    { "name": "engram-mcp", "status": "connected" }
  ]
}
```

#### `POST /api/mcp/servers/:name/action`

Execute action on MCP server.

**Request Body:**
```json
{
  "action": "restart",
  "params": {}
}
```

---

## WebSocket API

### Connection

Connect to: `ws://localhost:8080`

**Handshake:**
```javascript
const ws = new WebSocket('ws://localhost:8080');
ws.onopen = () => {
  console.log('Connected');
};
```

### Messages

#### Client → Server

Subscribe to real-time updates:
```json
{
  "type": "subscribe",
  "channel": "metrics",
  "filters": ["token_usage", "session_count"]
}
```

#### Server → Client

Real-time metric update:
```json
{
  "type": "metrics",
  "timestamp": "2026-08-04T02:55:30Z",
  "data": {
    "session_count": 1,
    "active_agents": 0,
    "token_usage_5s": 234
  }
}
```

Alert notification:
```json
{
  "type": "alert",
  "severity": "warning",
  "message": "Token budget above 70%",
  "timestamp": "2026-08-04T02:55:30Z"
}
```

### Channels

| Channel | Description | Update Frequency |
|---------|-------------|-----------------|
| metrics | Agent and system metrics | Every 5 seconds |
| traces | Distributed trace updates | Real-time |
| alerts | Alert notifications | Real-time |
| sessions | Session state changes | Real-time |

---

## Error Handling

All errors follow this format:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Session not found",
    "status": 404
  }
}
```

### Error Codes

| Code | Status | Description |
|------|--------|-------------|
| RESOURCE_NOT_FOUND | 404 | Requested resource doesn't exist |
| INVALID_REQUEST | 400 | Malformed request |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |
| GATEWAY_TIMEOUT | 504 | Upstream timeout |

---

## Rate Limiting

Current limits:
- **REST API**: 100 requests/minute per IP
- **WebSocket**: 5 concurrent connections per IP

Headers included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1722853200
```

---

## SDK and Client Libraries

### TypeScript/JavaScript
```bash
npm install @gentle-vanguard/api-client
```

```typescript
import { GentleVanguardClient } from '@gentle-vanguard/api-client';

const client = new GentleVanguardClient('http://localhost:8080');
const metrics = await client.metrics.get();
```

### PowerShell
```powershell
$api = "http://localhost:8080/api"
$metrics = Invoke-RestMethod -Uri "$api/metrics" -Method GET
```

---

## Changelog

### v1.0.0 (2026-08-04)
- Initial API documentation
- 25+ endpoints documented
- WebSocket real-time API

---

*For questions or issues, see `docs/operations/procedures/API-TROUBLESHOOTING.md`*
