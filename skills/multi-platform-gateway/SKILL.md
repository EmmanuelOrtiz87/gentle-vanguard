# Multi-Platform Gateway Skill

## Purpose
Manage multi-platform messaging gateway (Telegram, Discord, WhatsApp).

## Capabilities
- Start/stop gateway connections
- Route messages between platforms
- Schedule automated tasks
- Manage agent lifecycle

## Usage
```powershell
.\scripts\gateway\gateway-manager.ps1 -Action status
.\scripts\gateway\gateway-manager.ps1 -Action start -Platform telegram
```

## Architecture
- `gateway-manager.ps1` — CLI entry point
- `gateway.js` — HTTP server
- `platforms/` — Platform adapters
- `agent/` — Agent module (agent.js, tools.js, context.js, system-prompt.js, scheduler.js)
