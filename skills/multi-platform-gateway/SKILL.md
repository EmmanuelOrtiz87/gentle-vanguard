---
name: multi-platform-gateway
description: >
  Multi-platform messaging gateway for Telegram, Discord, and WhatsApp. Manages
  inbound message processing, outbound delivery, and persistent service lifecycle.
---

# Multi-Platform Gateway

## Activation

Use when user mentions "gateway", "telegram", "discord", "whatsapp", "mensaje",
"notificación", "notificaciones", "alerta", "reporte automático", or when
processing inbound messages from external platforms.

## Architecture

```
Telegram ─┐
Discord  ─┤── gateway.js ──► .session/gateway/inbox/ ──► gv gateway process
WhatsApp ─┘                      │
                          .session/gateway/outbox/ ◄── gv gateway send
                                 │
                          Platform adapters ──► Send to user
```

## How It Works (IMPORTANT)

The gateway is a **message relay**, NOT a 24/7 AI assistant. GV only thinks when you're in a coding session (OpenCode, Claude Code).

**Flow:**
1. You send a message on WhatsApp/Telegram
2. Gateway receives it, auto-replies "✅ Mensaje recibido", saves to inbox
3. When you start a GV session, pending messages are loaded into context
4. GV processes them and suggests responses
5. You approve / GV queues responses to outbox
6. Gateway automatically sends them

**You cannot start a GV session from WhatsApp/Telegram.** GV needs the coding tool running.

**Allowed numbers:** Auto-reply only goes to numbers in `allowedNumbers` / `allowedChatIds`. Other contacts are silently logged without response.

## Hard Rules

- ALL inbound messages are saved to `.session/gateway/inbox/` as JSON
- ALL outbound messages go through `.session/gateway/outbox/` as JSON
- Gateway MUST be running for real-time message delivery
- Inbox messages are loaded into session context via `gv gateway process`
- Gateway config is in `config/gateway.json`
- Auto-reply only to `allowedNumbers` (WhatsApp) / `allowedChatIds` (Telegram)

## Commands

| Command | Description |
|---------|-------------|
| `gv gateway start` | Start gateway process in background |
| `gv gateway stop` | Stop gateway process |
| `gv gateway status` | Show gateway status and stats |
| `gv gateway process` | Load pending inbound messages into session |
| `gv gateway send <platform> <to> <message>` | Queue a message to send |
| `gv gateway logs` | Show last 50 log lines |
| `gv gateway install` | Install as Windows scheduled task (auto-start) |
| `gv gateway uninstall` | Remove scheduled task |
| `gv gateway setup` | Show setup instructions |

## Send Examples

```powershell
# WhatsApp (formato: codigo_pais + numero sin espacios + @c.us)
gv gateway send whatsapp 541155512345@c.us Hola, soy GV

# Telegram (chatId numérico)
gv gateway send telegram 123456789 Hola desde GV

# Direct file (alternativa: crear archivo en outbox manualmente)
Ruta: .session/gateway/outbox/msg-20260520-hola.json
Contenido: {"platform":"whatsapp","to":"541155512345@c.us","text":"mensaje"}
```

## Session Integration

When `gv gateway process` is called:
1. Read all `.json` files from `.session/gateway/inbox/`
2. Display each message with platform, sender, timestamp
3. Mark messages as processed
4. User can respond via `gv gateway send`

When session-autostart runs (step in autostart pipeline):
1. Check if gateway is running
2. If `isPeakHour=false`, auto-process inbox
3. Notify user of unread messages count

## Platform Setup

### Telegram
1. Chat @BotFather on Telegram → `/newbot` → get token
2. Get your chat ID: message @userinfobot
3. Set `telegram.token` and `telegram.allowedChatIds` in `config/gateway.json`

### Discord
1. Go to https://discord.com/developers/applications
2. New Application → Bot → Copy token → Enable Message Content Intent
3. Invite bot to server with `bot` + `messages.read` scopes
4. Set `discord.token` and `discord.allowedChannelIds` in config

### WhatsApp
1. Set `whatsapp.enabled: true` in config
2. Start gateway — QR code appears in terminal
3. Scan with WhatsApp app (Settings → Linked Devices)
4. Session persists in `.session/gateway/whatsapp-session/`
5. Set `whatsapp.allowedNumbers` in config (your phone number without country code prefix):
   ```json
   "allowedNumbers": ["1155512345"]
   ```
   Leave empty `[]` to auto-reply to ALL contacts (not recommended).

## References

- Gateway process: `scripts/gateway/gateway.js`
- Manager script: `scripts/gateway/gateway-manager.ps1`
- Config: `config/gateway.json`
- Platform adapters: `scripts/gateway/platforms/`
