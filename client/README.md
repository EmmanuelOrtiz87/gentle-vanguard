# Foundation Client - Lightweight Interface

This is the **client-only** distribution of Foundation. It provides:

- TUI interface for setup
- Connection to Foundation API (server mode)
- Public documentation and theory
- NO engine implementation (protected IP)

## What's Included

```
client/
├── wf-client.exe          # Compiled CLI (PS2EXE, obfuscated)
├── foundation-tui.exe     # TUI installer (interface only)
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

To use full Foundation capabilities:

1. **Subscribe** at https://foundation.dev/pricing
2. **Get API key** from dashboard
3. **Configure client**:
   ```powershell
   .\wf-client.exe config --api-key "your-key"
   ```
4. **Use normally**:
   ```powershell
   .\wf-client.exe health
   .\wf-client.exe verify
   ```

## Local Mode (Limited)

Without server connection, you can:

- Read documentation
- Use TUI installer
- View public architecture docs
- Practice with theory

## Intellectual Property Notice

Foundation engine and core algorithms are:

- **NOT open source** (despite public docs)
- **Protected by EULA** (see LICENSE)
- **Encrypted in distribution** (AES-256)
- **Server-side execution** (for full features)

## Support

- Docs: https://foundation.dev/docs
- Issues: https://github.com/EmmanuelOrtiz87/foundation/issues
- Email: support@foundation.dev
