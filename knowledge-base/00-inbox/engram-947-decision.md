---
created: 2026-05-18 20:34:01
tags: [engram, decision]
engram_id: 947
type: decision
---

# README governance differentiation - private vs public

**What**: Differentiated README.md (private repo) from README-PUBLIC.md (public repo) per README-GOVERNANCE.md policy
**Why**: Both repos had identical content when governance doc requires different structure and depth for each
**Where**: README.md, README-PUBLIC.md, docs/brand/assets/banner-github.svg
**Learned**:
- Private README must have: What is GV (6 bullets + Mermaid flowchart), Work Routing Ladder, Delegation Rules table, Model Routing Mermaid, 5-Layer Architecture table, Agent Ecosystem with Delegates-to column, Key Capabilities (SDD/OpenSpec, Preflight, Review Guard, Skill Registry, Chain-Delivery, Cross-Tool), Quick Start, Development commands table, CI/CD, Project Status gates, Key Documentation links
- Public README must have: What It Solves table, Skill Catalog, Quick Install, Requirements, Defensive Patterns, Security
- validate-readme.ps1 requires exact patterns: "Routes work", "Persists memory", "Enforces SDD" in What is GV section; Invoke-Pester in Development section
- Validated skill count is 134 (not 146 from filesystem SKILL.md count)
- Banner GV logo redesigned: G (#A855F7 purple) and V (#06B6D4 cyan) now separated with visual gap and distinct colors for readability

---
*Imported from Engram on 2026-09-06*
