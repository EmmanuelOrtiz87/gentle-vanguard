# DOCUMENTATION-SYNC-POLICY

**Status:** ACTIVE — 2026-07-29

---

## 1. Purpose

Mantener consistencia total entre lo documentado y lo realmente implementado. Cada cambio técnico,
de arquitectura, de negocio o de migración debe reflejarse en TODOS los artefactos relevantes.
La deuda documental es deuda técnica.

## 2. The Sync Rule

> **DOC-001**: For EVERY change, update ALL of the following that are affected:
>
> - 📄 **Source code** comments, JSDoc, type annotations
> - 📝 **Documentation** (.md files in `docs/`, `rules/`, `config/`)
> - 🖥️ **Presentations** (HTML pages in `docs/presentations/`)
> - 📊 **Diagrams** (SVG, Mermaid, architecture maps)
> - ⚙️ **Configurations** (JSON, YAML, TOML)
> - 📜 **Normativas & Policies** (in `rules/`)
> - 📖 **README files** (root, subprojects)
> - 🔧 **CLAUDE.md / agent tool profiles** (in `config/tool-profiles/`)
> - 🔄 **CI/CD workflows** (in `.github/workflows/`)
> - 🧪 **Tests** that reference the changed behavior

## 3. Change Types & Required Updates

| Change Type | Must Update |
|-------------|-------------|
| **New script/module** | `package.json` scripts, README, relevant docs, CLAUDE.md if agent-facing |
| **API change** | Type definitions, JSDoc, ADR, presentation, tests |
| **Architecture change** | ADR, presentation (architecture.html), diagrams, NORMATIVAS |
| **Migration (PS1→TS)** | This policy (historical context), scripts table, presentations, CLAUDE.md |
| **Config change** | Schema files, JSON validator, documentation, examples |
| **Policy change** | All references to the old policy, README-rules, presentation pages |
| **Feature addition** | Presentations (add card/section), quickstart, README, tests |
| **Bug fix** | Comments in fixed code, CHANGELOG, relevant docs if behavior changed |

## 4. The Documentation Gap Process

When a documentation gap is detected (something is documented but not implemented, or implemented
but not documented):

```
1. Create GAPS-BACKLOG entry with severity (critical/high/medium/low)
2. Fix the gap immediately if severity is CRITICAL or HIGH
3. For MEDIUM/LOW: schedule in next session, tag with #doc-sync
4. Verify fix: grep for stale references, update presentations
```

## 5. Pre-Commit Documentation Check

Before committing, the agent MUST self-check:

- [ ] Are there any stale `.ps1` references in docs?
- [ ] Do presentations match actual implementation?
- [ ] Is package.json in sync with available scripts?
- [ ] Does `CLAUDE.md` reference real files?
- [ ] Do diagrams reflect current architecture?

## 6. Enforcement

- **Review gate**: Any PR with documentation inconsistencies should be BLOCKED
- **GAPS-BACKLOG**: All gaps tracked and triaged
- **Watchtower** (future): Add `doc-sync` component that checks presentation references against
  actual files
