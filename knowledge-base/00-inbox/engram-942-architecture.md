---
created: 2026-05-18 17:57:16
tags: [engram, architecture]
engram_id: 942
type: architecture
---

# README governance — restored comprehensive READMEs, added protection

**What**: Restored both READMEs (private: 35→350 lines, public: 107→240 lines) recovering v2.16.0/v2.9.0 essence. Added governance policy, validation script, pre-commit hook.

**Why**: READMEs had been reduced to minimal stubs losing Mermaid diagrams, architecture, delegation rules, agent ecosystem, skill catalog, CI/CD pipeline, development commands.

**Where**:
- README.md (private repo)
- gentle-vanguard-public/README.md (public repo)
- rules/README-GOVERNANCE.md (new — mandatory sections, prohibited actions, modification protocol)
- scripts/utilities/validate-readme.ps1 (new — automated governance checks)
- hooks/validate-readme-hook.ps1 (new — pre-commit protection)
- hooks/pre-commit.ps1 (modified — integrated README governance check)
- CHANGELOG.md (added v2.18.0 entry)

**Learned**:
- Agent count is 17 (Orchestrator + 16 sub-agents). GITFLOW and SCRIPT are routing profiles, not agents. hallucinationGuardLevels is a config entry, not an agent.
- Validation script must exclude non-agent profiles from count: hallucinationGuardLevels, GITFLOW, SCRIPT
- Public repo CI/CD table must include sync-public.yml
- Version badge must match CHANGELOG.md latest entry

---
*Imported from Engram on 2026-09-06*
