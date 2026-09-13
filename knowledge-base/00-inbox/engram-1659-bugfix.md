---
created: 2026-07-14 19:20:07
tags: [engram, bugfix]
engram_id: 1659
type: bugfix
---

# Tracing Prometheus metrics fix + session cleanup span-close fix

**What**: Fixed two tracing issues: (1) Prometheus .prom file never updated on session start, (2) session cleanup silently ignored span-close failures

**Why**: Watchtower reported "Prometheus metrics: FAIL (last export 106.2 hrs ago)" because the `start` action in tracing-instrument.ts never called getPrometheusMetrics(), and session-cleanup-start.ts unconditionally logged success even when spawnSync failed

**Where**: src/tracing-instrument.ts:283 (added getPrometheusMetrics call to start action), src/session-cleanup-start.ts:154-179 (check spawnSync result, pass startTimeUnixNano attribute, added warn() function)

**Learned**:
- The start action only wrote spans to file but not Prometheus metrics — now it does
- Session cleanup was missing startTimeUnixNano attribute in end call, so duration would calculate from epoch 0
- The Docker OTel stack (gv-otel, gv-prometheus, gv-jaeger) is not running — .prom file is the only export path
- All spans had startTimeUnixNano === endTimeUnixNano because end was never called
- auto-delegation.json (2420 lines) is ALL active config — no templates/placeholders to clean up

---
*Imported from Engram on 2026-09-06*
