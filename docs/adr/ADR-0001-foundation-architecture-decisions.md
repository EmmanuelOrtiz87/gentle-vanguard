# ADR-0001: Foundation Architecture Decisions

## Status
Accepted

## Date
2026-05-08

## Context
The Foundation project requires a documented architecture decision record to track
significant technical choices, their rationale, and their implications.

## Decision
Adopt the following architecture decisions as the foundation for the project:

### 1. PowerShell-First with Multi-Language Support
The project is primarily PowerShell with supplementary languages (Go, Node.js, Python)
for specific use cases where PowerShell is not the best fit.

### 2. Lefthook v2 for Git Hooks
Use lefthook v2 instead of raw Git hooks or husky for consistent cross-platform
hook management with YAML-based configuration.

### 3. Pester 5.x for Testing
Use Pester 5.x with the `New-PesterConfiguration` API for all PowerShell testing.
Tests organized in 4 categories: unit, integration, security, performance.

### 4. Engram for Memory
Engram provides persistent cross-session memory with hot/warm/cold tiering.
All architectural decisions are stored in Engram for future reference.

### 5. 5-Layer Architecture
- Layer 1: AGENTS — Role-based AI agents (BA, DEV, QA, OPS, GOV, DOC, SAD)
- Layer 2: COMMANDS — wf.ps1 CLI, pre-process-input.ps1 routing
- Layer 3: MCP SERVERS — Model Context Protocol servers
- Layer 4: SKILLS — 126+ specialized skills with SKILL.md manifests
- Layer 5: MEMORY — Engram persistent storage

### 6. CI/CD via GitHub Actions
14 workflows covering validation, quality, security, testing, and releases.
All workflows use minimum `contents: read` permissions, concurrency groups,
and timeout limits.

### 7. Secret Detection Strategy
Multi-layer approach: trufflehog (pre-push, full scans) + pre-commit hooks (staged files)
+ secretlint (static analysis).

## Consequences
### Positive
- Clear architectural boundaries between layers
- Consistent hook management across environments
- Test results are reproducible and categorized
- Security scanning at multiple points in the pipeline

### Negative
- ADRs must be kept updated as architecture evolves
- Multi-layer architecture adds cognitive overhead for new contributors
