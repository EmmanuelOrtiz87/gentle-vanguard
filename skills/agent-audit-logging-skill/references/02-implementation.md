# Implementation

## Step 1: Define the Audit Event Schema

```python
from dataclasses import dataclass, field, asdict
from typing import Any, Optional
from enum import Enum
import json
import time
import uuid

class EventType(Enum):
    INVOCATION = "agent.invocation"
    REASONING = "agent.reasoning"
    TOOL_CALL = "agent.tool_call"
    TOOL_RESULT = "agent.tool_result"
    DECISION = "agent.decision"
    LLM_RESPONSE = "agent.llm_response"
    ERROR = "agent.error"
    HANDOFF = "agent.handoff"
    HUMAN_INTERVENTION = "agent.human_intervention"
    TOKEN_USAGE = "agent.token_usage"

@dataclass
class AuditEvent:
    """Structured audit event for any agent action."""

    event_id: str = None
    event_type: EventType = None
    agent_name: str = ""
    task_id: str = ""
    session_id: str = ""
    action: str = ""
    params: dict = field(default_factory=dict)
    result: Any = None
    reasoning: str = ""
    confidence: float = 0.0
    source: str = ""
    parent_event_id: Optional[str] = None
    trace_id: str = ""
    timestamp: float = None
    duration_ms: float = 0.0
    token_count: int = 0
    model: str = ""
    version: str = ""
    error: Optional[str] = None
    error_type: Optional[str] = None

    def __post_init__(self):
        if self.event_id is None:
            self.event_id = str(uuid.uuid4())
        if self.timestamp is None:
            self.timestamp = time.time()
        if not self.trace_id:
            self.trace_id = self.event_id

    def serialize(self) -> dict:
        data = asdict(self)
        data["event_type"] = self.event_type.value
        data["timestamp"] = self.timestamp
        return data
```

## Step 2: Build the Audit Logger

```python
class AuditLogger:
    """Structured audit logger with multiple backends."""

    def __init__(self, storage_backend, buffer_size: int = 100):
        self.storage = storage_backend
        self.buffer = []
        self.buffer_size = buffer_size
        self._lock = threading.Lock()

    def log(self, event: AuditEvent):
        with self._lock:
            self.buffer.append(event)
            if len(self.buffer) >= self.buffer_size:
                self.flush()

    def flush(self):
        with self._lock:
            if not self.buffer:
                return
            events = self.buffer.copy()
            self.buffer.clear()
        asyncio.create_task(self.storage.batch_write([e.serialize() for e in events]))

    async def log_invocation(self, agent_name, task, session_id, trace_id=None):
        self.log(AuditEvent(event_type=EventType.INVOCATION, agent_name=agent_name,
            action="invocation", params={"task": task}, session_id=session_id,
            trace_id=trace_id or str(uuid.uuid4()), source="user"))

    async def log_tool_call(self, agent_name, tool_name, params, trace_id, parent_id=None):
        self.log(AuditEvent(event_type=EventType.TOOL_CALL, agent_name=agent_name,
            action=f"tool_call:{tool_name}", params=params, trace_id=trace_id,
            parent_event_id=parent_id))

    async def log_decision(self, agent_name, decision, reasoning, confidence, trace_id):
        self.log(AuditEvent(event_type=EventType.DECISION, agent_name=agent_name,
            action=f"decision:{decision}", reasoning=reasoning, confidence=confidence,
            trace_id=trace_id))

    async def log_error(self, agent_name, error, context, trace_id):
        self.log(AuditEvent(event_type=EventType.ERROR, agent_name=agent_name,
            action="error", error=str(error), error_type=type(error).__name__,
            params=context, trace_id=trace_id))
```

## Step 3: Traceability Chain

```python
class TraceabilityChain:
    """Build and query traceability chains across events."""

    def __init__(self, storage):
        self.storage = storage

    async def get_trace(self, trace_id: str) -> list[AuditEvent]:
        events = await self.storage.query(f"trace:{trace_id}", sort_key="timestamp")
        return [AuditEvent(**e) for e in events]

    async def get_timeline(self, trace_id: str) -> list[dict]:
        events = await self.get_trace(trace_id)
        timeline = []
        for event in events:
            timeline.append({
                "time": datetime.fromtimestamp(event.timestamp).isoformat(),
                "agent": event.agent_name,
                "action": event.action,
                "details": self._summarize_event(event),
                "duration": f"{event.duration_ms:.0f}ms" if event.duration_ms else "",
                "status": "error" if event.error else "success"
            })
        return timeline

    def _summarize_event(self, event: AuditEvent) -> str:
        if event.event_type == EventType.INVOCATION:
            return f"Task received: {event.params.get('task', '')[:100]}"
        elif event.event_type == EventType.TOOL_CALL:
            return f"Called tool '{event.action.split(':')[1]}' with {len(event.params)} params"
        elif event.event_type == EventType.DECISION:
            return f"Decision: {event.action} (confidence: {event.confidence:.0%})"
        elif event.event_type == EventType.ERROR:
            return f"Error: {event.error}"
        elif event.event_type == EventType.HANDOFF:
            return f"Handoff to {event.params.get('target', 'unknown')}"
        return event.action

    async def trace_graph(self, trace_id: str) -> dict:
        events = await self.get_trace(trace_id)
        nodes, edges = [], []
        for event in events:
            node_id = event.event_id
            nodes.append({"id": node_id, "label": self._summarize_event(event),
                "type": event.event_type.value, "agent": event.agent_name})
            if event.parent_event_id:
                edges.append({"from": event.parent_event_id, "to": node_id})
        return {"nodes": nodes, "edges": edges}
```

## Step 4: Compliance Reports

```python
class ComplianceReporter:
    """Generate compliance and governance reports from audit logs."""

    def __init__(self, storage):
        self.storage = storage

    async def generate_report(self, start_date, end_date, report_type="summary") -> dict:
        events = await self.storage.query_range(f"events:{start_date}", f"events:{end_date}")
        if report_type == "summary":
            return self._summary_report(events)
        elif report_type == "tool_usage":
            return self._tool_usage_report(events)
        elif report_type == "error_analysis":
            return self._error_analysis_report(events)
        elif report_type == "compliance_check":
            return self._compliance_check_report(events)

    def _summary_report(self, events):
        total_events = len(events)
        agent_counts = Counter(e["agent_name"] for e in events)
        error_count = sum(1 for e in events if e.get("error"))
        handoff_count = sum(1 for e in events if e.get("event_type") == "agent.handoff")
        return {
            "period": {"start": events[0]["timestamp"] if events else "",
                       "end": events[-1]["timestamp"] if events else ""},
            "total_events": total_events, "total_errors": error_count,
            "error_rate": f"{error_count/total_events*100:.1f}%" if total_events else "0%",
            "total_handoffs": handoff_count, "agents_active": len(agent_counts),
            "top_agents": agent_counts.most_common(5)
        }

    def _tool_usage_report(self, events):
        tool_calls = [e for e in events if e.get("event_type") == "agent.tool_call"]
        tool_counts, tool_errors, tool_latency = Counter(), Counter(), defaultdict(list)
        for call in tool_calls:
            tool_name = call["action"].split(":")[1]
            tool_counts[tool_name] += 1
            if call.get("error"):
                tool_errors[tool_name] += 1
            tool_latency[tool_name].append(call.get("duration_ms", 0))
        return {
            "total_tool_calls": len(tool_calls),
            "tool_breakdown": [{"tool": t, "calls": c, "errors": tool_errors[t],
                "error_rate": f"{tool_errors[t]/c*100:.1f}%",
                "avg_latency_ms": statistics.mean(tool_latency[t]) if tool_latency[t] else 0}
                for t, c in tool_counts.most_common()]
        }

    def _error_analysis_report(self, events):
        errors = [e for e in events if e.get("error")]
        error_types = Counter(e["error_type"] for e in errors if e.get("error_type"))
        error_messages = Counter(e["error"][:100] for e in errors if e.get("error"))
        errors_by_agent = Counter(e["agent_name"] for e in errors)
        return {
            "total_errors": len(errors), "error_types": dict(error_types.most_common()),
            "most_common_errors": dict(error_messages.most_common(10)),
            "errors_by_agent": dict(errors_by_agent.most_common()),
            "suggested_actions": self._suggest_actions(error_types)
        }

    def _suggest_actions(self, error_types):
        suggestions = []
        if error_types.get("TimeoutError", 0) > 10:
            suggestions.append("Increase timeouts or add async fallbacks")
        if error_types.get("RateLimitError", 0) > 5:
            suggestions.append("Implement more aggressive rate limiting or add buffer")
        if error_types.get("ValidationError", 0) > 3:
            suggestions.append("Review tool parameter validation")
        return suggestions

    def _compliance_check_report(self, events):
        checks = {
            "human_escalation_rate": self._check_escalation_rate(events),
            "tool_approval_rate": self._check_tool_approvals(events),
            "data_access_audit": self._check_data_access(events),
            "token_budget_compliance": self._check_budget_compliance(events),
        }
        return {
            "compliant": all(c["passed"] for c in checks.values()),
            "checks": checks,
            "recommendations": [c.get("recommendation", "") for c in checks.values() if not c["passed"]]
        }
```

## Step 5: Real-Time Audit Dashboard

```python
class AuditDashboard:
    """Real-time monitoring dashboard for agent activity."""

    def __init__(self, logger: AuditLogger):
        self.logger = logger

    def recent_activity(self, minutes: int = 60) -> dict:
        cutoff = time.time() - (minutes * 60)
        recent = [e for e in self.logger.buffer if e.timestamp > cutoff]
        return {
            "period_minutes": minutes, "total_events": len(recent),
            "events_per_second": len(recent) / (minutes * 60),
            "agents_active": len(set(e.agent_name for e in recent)),
            "errors_last_hour": sum(1 for e in recent if e.error),
            "recent_errors": [{"time": datetime.fromtimestamp(e.timestamp).isoformat(),
                "agent": e.agent_name, "error": e.error} for e in recent[-10:] if e.error]
        }

    def live_feed(self, limit: int = 20) -> list[dict]:
        recent = self.logger.buffer[-limit:]
        return [{"timestamp": datetime.fromtimestamp(e.timestamp).isoformat(),
            "agent": e.agent_name, "event": e.action,
            "type": e.event_type.value.split(".")[-1], "has_error": bool(e.error)}
            for e in reversed(recent)]
```

## Step 6: Audit Log Storage & Retention

```python
class AuditStorage:
    """Storage backend for audit logs with retention policies."""

    def __init__(self, connection_string: str):
        self.conn = connection_string
        self.retention_days = {"debug": 7, "info": 30, "compliance": 365, "critical": 730}

    async def store(self, event: dict):
        tier = self._classify_event(event)
        event["_ttl"] = self.retention_days[tier] * 86400
        event["_tier"] = tier
        date_key = datetime.fromtimestamp(event["timestamp"]).strftime("%Y-%m-%d")
        await self._write(f"events:{date_key}", event)

    def _classify_event(self, event: dict) -> str:
        event_type = event.get("event_type", "")
        has_error = bool(event.get("error"))
        if has_error or event_type in ("agent.security", "agent.compliance"):
            return "critical"
        elif event_type in ("agent.decision", "agent.handoff", "agent.human_intervention"):
            return "compliance"
        elif event_type in ("agent.invocation", "agent.tool_call", "agent.token_usage"):
            return "info"
        return "debug"

    async def query_by_agent(self, agent_name, start_date, end_date, limit=100):
        results = []
        current = start_date
        while current <= end_date and len(results) < limit:
            events = await self._read(f"events:{current}")
            results.extend(e for e in events if e.get("agent_name") == agent_name)
            date = datetime.strptime(current, "%Y-%m-%d")
            current = (date + timedelta(days=1)).strftime("%Y-%m-%d")
        return results[:limit]
```
