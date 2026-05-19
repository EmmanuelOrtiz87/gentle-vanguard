# Gentle-Vanguard Client - Lightweight Interface

This is the **client-only** distribution of Gentle-Vanguard. It provides:

- TUI interface for setup
- Connection to Gentle-Vanguard API (server mode)
- Public documentation and theory
- NO engine implementation (protected IP)

## What's Included

```
client/
├── gv-client.exe          # Compiled CLI (PS2EXE, obfuscated)
├── gentle-vanguard-tui.exe     # TUI installer (interface only)
├── config/
│   └── server-endpoint.json  # API connection config
└── docs/                 # Public docs (theory, architecture)
```

## What's NOT Included (Protected IP)

- Core engine scripts (`scripts/utilities/`)
- Skill implementations (`skills/*/SKILL.md` - only metadata)
- Internal orchestration logic
- Token budgeting algorithms
- Security orchestrator implementation

## Server Mode

To use full Gentle-Vanguard capabilities:

1. **Subscribe** at https://gentle-vanguard.dev/pricing
2. **Get API key** from dashboard
3. **Configure client**:
   ```powershell
   .\gv-client.exe config --api-key "your-key"
   ```
4. **Use normally**:
   ```powershell
   .\gv-client.exe health
   .\gv-client.exe verify
   ```

## Local Mode (Limited)

Without server connection, you can:

- Read documentation
- Use TUI installer
- View public architecture docs
- Practice with theory

## Intellectual Property Notice

Gentle-Vanguard engine and core algorithms are:

- **NOT open source** (despite public docs)
- **Protected by EULA** (see LICENSE)
- **Encrypted in distribution** (AES-256)
- **Server-side execution** (for full features)

## Support

- Docs: https://gentle-vanguard.dev/docs
- Issues: https://github.com/EmmanuelOrtiz87/gentle-vanguard/issues
- Email: support@gentle-vanguard.dev
