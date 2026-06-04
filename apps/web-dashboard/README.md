# Gentle Vanguard Web Dashboard

Real-time metrics dashboard with CopilotKit-native agent interaction patterns. Provides agent chat,
HITL approvals, shared state, task control, and event timeline — all over WebSocket/MCP.

## Features

### Agent Chat (`/agents`)

- Conversational interface with 6 agents (DEV, QA, BA, GOV, OPS, DOC)
- **@mentions autocomplete**: Type `@` in input to mention and route to any agent
- **Suggested actions**: Quick-action chips (Run tests, Check skills, Review logs, Analyze) in empty
  state
- **Streaming responses**: Real-time message streaming with typing indicators
- **Tool calls**: Expandable tool call cards with status (pending/running/completed/error)
- **ui_hints rendering**: Native React components from agent responses:
  - `metric` — Color-coded metric cards (info/warning/error)
  - `datatable` — Sortable HTML tables
  - `chart` — Bar charts with multiple series
  - `diff` — Before/after side-by-side
  - `form` — Dynamic forms with submit
  - `list` — Bulleted lists with severity
  - `alert` — Alert banners with severity
- **Session history**: Persistent sessions loaded from disk, browsable in sidebar

### Human-in-the-Loop (`/agents`)

- 4 HITL modes: confirmation, selection, form, review
- Auto-detected when user messages contain "approve", "confirm", "delegate", "revisar"
- Agent pauses execution and shows modal; user response resumes

### Agent Tasks (`/tasks`)

- Real-time task monitoring from the event bus
- Active/running/completed/error/cancelled status with icons
- Quick actions to dispatch DEV or QA agents

### Event Timeline (`/timeline`)

- Visual timeline of event bus events
- 10 event types with distinct icons (dispatch, agent, session, workflow, validation)
- Expandable JSON payload viewer
- Real-time updates via WebSocket

### Dashboard (`/`)

- Live metrics (tokens, sessions, git, health)
- MCP skill statistics with per-agent breakdown
- Agent Activity section

## Architecture

```
apps/web-dashboard/
├── server/
│   ├── websocket-server.ts       # WebSocket + HTTP server (metrics, agents, HITL, state)
│   ├── mcp-bridge.ts             # MCP stdio ↔ WebSocket bridge singleton
│   └── shared-state-bridge.ts    # Event bus filesystem watcher singleton
├── src/
│   ├── components/
│   │   ├── Dashboard.tsx         # Main dashboard with metrics
│   │   ├── AgentChat.tsx         # Agent chat with @mentions, suggested actions
│   │   ├── AgentMessage.tsx      # Message renderer with ui_hints + tool calls
│   │   ├── HitlModal.tsx         # HITL modal (4 modes)
│   │   ├── TaskControl.tsx       # Task monitoring + quick dispatch
│   │   ├── SessionTimeline.tsx   # Event timeline with expandable payloads
│   │   ├── TracingDashboard.tsx  # OpenTelemetry traces
│   │   ├── Marketplace.tsx       # Skill publishing/browsing
│   │   └── InteractiveDocs.tsx   # Guided tutorials
│   ├── hooks/
│   │   ├── useAgentStream.ts     # Agent sessions, messages, tools, HITL, history
│   │   └── useSharedState.ts     # Event bus state (events, tasks)
│   ├── types/
│   │   └── agent.ts              # Agent types (ui_hints, messages, sessions, etc.)
│   └── App.tsx                   # Router with 6 routes (+/tasks, /timeline)
```

## Quick Start

```bash
# Install dependencies
pnpm install

# Terminal 1: Start WebSocket + HTTP server (port 8080)
node server/websocket-server.ts

# Terminal 2: Start dev server
pnpm dev

# Build for production
pnpm build
```

The dashboard auto-connects to `ws://localhost:8080`.

## WebSocket Protocol

### Agent Commands (type: "agent")

| action           | Description                  |
| ---------------- | ---------------------------- |
| `create_session` | Create new agent session     |
| `send_message`   | Send message to session      |
| `list_sessions`  | List active sessions         |
| `list_history`   | List all persistent sessions |
| `get_session`    | Get session by ID            |
| `list_tools`     | List MCP bridge tools        |
| `execute_skill`  | Execute skill via MCP bridge |
| `subscribe`      | Subscribe to session stream  |
| `hitl_response`  | Resolve HITL request         |
| `emit_event`     | Emit event to event bus      |

### Message Types (server → client)

| type                    | Description                          |
| ----------------------- | ------------------------------------ |
| `metrics`               | Live dashboard metrics (5s interval) |
| `bridge_status`         | MCP bridge connection status         |
| `agent_session_created` | New session created                  |
| `agent_session`         | Session state snapshot               |
| `agent_sessions`        | List of sessions                     |
| `agent_message`         | New/updated message in session       |
| `agent_stream_done`     | Message streaming complete           |
| `agent_tools`           | Available MCP tools                  |
| `agent_history`         | Persistent session history           |
| `hitl_request`          | HITL approval requested              |
| `hitl_resolved`         | HITL request resolved                |
| `state_history`         | Event bus history                    |
| `state_event`           | New event bus event                  |
| `state_tasks`           | Active agent tasks                   |

### CopilotKit Patterns Implemented

The dashboard implements 5 patterns from CopilotKit natively over MCP:

| Pattern            | Implementation                                       | Files                                         |
| ------------------ | ---------------------------------------------------- | --------------------------------------------- |
| **AG-UI Protocol** | `ui_hints` in message payload → 7 React renderers    | `AgentMessage.tsx`, `agent.ts`                |
| **Streaming**      | WebSocket agent channels with `streaming` flag       | `websocket-server.ts`, `useAgentStream.ts`    |
| **HITL UI**        | 4-mode modal, auto-detected from keywords            | `HitlModal.tsx`, `websocket-server.ts`        |
| **Shared State**   | Event bus polling + 3 WS channels                    | `shared-state-bridge.ts`, `useSharedState.ts` |
| **Chat Interface** | AgentChat with @mentions, history, suggested actions | `AgentChat.tsx`, `useAgentStream.ts`          |

## HTTP API

- `GET /api/metrics` — Dashboard metrics
- `GET /api/mcp/metrics` — MCP skill statistics
- `GET /api/health` — Server health
- `GET /api/agent/tools` — Available MCP tools
- `GET /api/agent/sessions` — Session list
- `GET /api/agent/session/:id` — Single session
- `GET /api/state/events` — Event bus history
- `GET /api/state/tasks` — Active tasks
- `POST /api/state/emit` — Emit event to bus

## Environment Variables

- `WS_PORT`: WebSocket/HTTP server port (default: 8080)
- `VITE_API_URL`: API base URL for HTTP fallback

## Scripts

- `pnpm dev` — Start Vite dev server
- `pnpm build` — TypeScript check + Vite production build
- `pnpm preview` — Preview production build
- `pnpm lint` — Run ESLint
