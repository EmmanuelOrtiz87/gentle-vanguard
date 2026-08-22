---
name: process-debugging
aliases: ["process-debugging"]
description: >
  
triggers:
  - process debug
  - trace process
  - why is this running
  - find parent
  - port conflict
  - what is using port
  - investigate process
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.077Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\process-debugging\SKILL.md
  version: "1.0.0"
---

# Process Debugging Skill

## Overview

Uses **witr** (github.com/pranshuparmar/witr — "Why Is This Running?") to answer the question every
operator asks: _why is this process running, and who started it?_ witr resolves a target (PID, port,
file, or container) back to its full **causal chain** — the ancestor lineage (e.g.
`systemd → PM2 → node`) plus the source unit (systemd unit, PM2 app name, launch agent) that owns
it.

The witr binary is auto-installed on first use into `.runtime/tools/witr/`; the wrapper redacts
sensitive env vars before anything reaches logs or reports.

## When to Use

- The maintenance watchtower (`npm run watchtower:health`) reports a FAIL or WARN and you need to
  know _which process owns the failing port_.
- A port is already in use (`EADDRINUSE`) and you need to find and inspect the owner.
- A process is running that shouldn't be — who launched it, from where, under what source?
- A file is locked and you need to see which process holds it.
- You want the ancestor chain of a specific PID before deciding to kill anything.

## CLI Commands

| Task                      | Command                                        |
| ------------------------- | ---------------------------------------------- |
| Trace a process by PID    | `npm run process:trace -- <pid>`               |
| Trace what owns a port    | `npm run port:trace -- <port>`                 |
| Trace what holds a file   | `npm run file:trace -- <path>`                 |
| Trace a container         | `npx tsx src/web/witr-cli.ts container <name>`     |
| Install the witr binary   | `npx tsx src/web/witr-cli.ts install`              |
| Check witr availability   | `npx tsx src/web/witr-cli.ts status`               |
| Causal chain only (short) | `npm run port:trace -- 8080 --short`           |
| Machine-readable JSON     | `npm run port:trace -- 8080` (default is JSON) |

Direct invocations are equivalent:

```bash
npx tsx src/web/witr-cli.ts process 1234
npx tsx src/web/witr-cli.ts port 8080
npx tsx src/web/witr-cli.ts file /var/lib/dpkg/lock
npx tsx src/web/witr-cli.ts container redis
npx tsx src/web/witr-cli.ts install
npx tsx src/web/witr-cli.ts status
```

## How to Read Causal Chains

The causal chain is the **ancestor lineage** of the traced process, printed oldest → newest:

```
systemd (pid 1) → pm2 (pid 1187) → node (pid 24501)
```

Read it left to right as _who launched whom_:

| Chain link | What it tells you                                         |
| ---------- | --------------------------------------------------------- |
| Leftmost   | The init/supervisor root — `systemd`, `init`, `launchd`   |
| Middle     | Process managers — `pm2`, `supervisord`, shell parents    |
| Rightmost  | The actual process — often `node`, `python`, `java`, etc. |

The **source** field names the owning unit: a systemd unit file (`foo.service`), a PM2 app
(`app_name`), or a launch agent. If `health` is present it reflects process health (e.g. `healthy`,
`unhealthy`). `warnings` surface anomalies (mismatched exe, missing unit file, unexpected parent).

The watchtower integrates this automatically: when a component FAILs/WARNs, it traces the component
port and prints `[witr] port 8080 → systemd (pid 1) → pm2 (pid 1187) → node (pid 24501)` in the same
run.

## Worked Example — Port Conflict

A dashboard WS server fails to bind port 8080:

```bash
npm run port:trace -- 8080
```

```
Process   : node (pid 24501)
Command   : /usr/bin/node src/dashboard-ws-autostart.ts
Source    : systemd (dashboard-ws.service)
Health    : healthy
Causal chain:
systemd (pid 1) → pm2 (pid 1187) → node (pid 24501)
```

You now know a previous watchdog instance (via PM2) is still bound to the port. Kill the PM2 app or
`Stop-Process -Id 24501`, then restart cleanly.

## Security & Hygiene

- **Never** blindly kill a process from a trace — verify the chain and source unit first.
- The wrapper strips env vars containing `TOKEN`, `SECRET`, `KEY`, `GH_`, `AWS_`, `OPENAI_`,
  `ANTHROPIC_`, etc. before output — secrets never leak into reports.
- witr needs elevated privileges on some platforms to read other users' processes; run from an
  elevated shell if traces come back empty.
- If witr is not installed, `ensureWitrInstalled()` auto-installs it via
  `scripts/utilities/maintenance/witr-installer.ps1`. If that fails, run the installer manually.

## Integration with debugging-and-error-recovery

This skill is the **localize** step of the debugging pipeline. When something breaks:

1. Reproduce → 2. **Localize (this skill)** → 3. Reduce → 4. Root-cause fix → 5. Guard → 6. Verify

Load `debugging-and-error-recovery` for the full triage checklist. Use `process-debugging` when the
failure is infrastructure-shaped: "port already in use", "process exited unexpectedly", "service
won't start", "file locked". Diagnose _who owns the resource_ before guessing at fixes.

## Resources

- `src/web/witr-wrapper.ts` — typed TS wrapper (`witr.traceProcess/Port/File/Container`)
- `src/web/witr-cli.ts` — CLI front-end
- `scripts/utilities/maintenance/witr-installer.ps1` — binary installer
- `src/core/maintenance-watchtower.ts` — automatic FAIL/WARN → port trace integration
- `.runtime/tools/witr/witr[.exe]` — installed binary location
