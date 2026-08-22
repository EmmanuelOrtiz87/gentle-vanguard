# Legacy reference policy

Gentle-Vanguard is TypeScript-first. Runtime paths must resolve to native TypeScript modules unless
a PowerShell script is explicitly listed as an active integration.

The PS1 reference audit distinguishes three safe cases from broken runtime dependencies:

- **Active PS1 integration:** `export-kit.ps1` remains a supported content export boundary.
- **Native-first fallback:** migration shims may retain a PS1 path only after checking and using the
  TypeScript implementation first.
- **Migration inventory/documentation:** historical paths used by migration tooling or documentation
  are not runtime dependencies.

Verify with:

```powershell
npx tsx src/audit-ps1-refs.ts
```

The required result is `Functional refs to MISSING ps1 (BROKEN): 0`.
