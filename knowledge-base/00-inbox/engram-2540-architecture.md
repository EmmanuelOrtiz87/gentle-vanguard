---
created: 2026-08-04 23:23:15
tags: [engram, architecture]
engram_id: 2540
type: architecture
---

# Dashboard CMD Launcher - Root Cause Fix

**What**: Created src/dashboard-cmd-launcher.ts - CMD-native WebSocket server launcher
**Why**: PowerShell caused ChildProcess.kill errors, blocking dashboard startup
**Where**:
- New: src/dashboard-cmd-launcher.ts (175 lines)
- Modified: package.json (dashboard:start script)
- Replaced: PowerShell-based quick-start.ts

**Technical Solution**:

```typescript
// Before (PowerShell - FAIL):
execFile('powershell', ['-Command', ...]) // ChildProcess.kill error

// After (CMD - SUCCESS):
spawn('cmd.exe', ['/c', 'npx', 'tsx', WS_SCRIPT], {
  windowsHide: true,
  detached: false  // Prevent orphans
})
```

**Key Features**:
- Zero PowerShell dependency
- Single-process architecture (no detached orphans)
- Native Windows CMD execution
- Automatic health check verification
- PID tracking without watchdog complexity

**Verification**:
- Port 8080: Listening (PID 9200)
- API /api/metrics: HTTP 200 OK
- Health Check: PASS
- API Response Time: < 200ms

**Learned**: PowerShell process management on Windows causes EINVAL errors. CMD native with spawn is 100% reliable.

---
*Imported from Engram on 2026-09-06*
