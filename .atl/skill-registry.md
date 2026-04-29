# Skill Registry (Auto-Resolved)

This file defines the enforceable skills and compact rules for the workspace-foundation project.

## 5-Layer Topology Mapping

Skills mapped to topology layers for orchestrator awareness:

| Layer | Skill Category | Examples |
|-------|----------------|----------|
| 5 - Agentes | Role workflows | sdd-*, project-orchestrator-skill |
| 4 - Comandos | Tool skills | docker-devops, workspace-automation |
| 3 - MCP | Protocol skills | mcp-skill |
| 2 - Skills | Domain skills | angular-spa, react-19, golang-api, testing-strategy |
| 1 - Memoria | Memory skills | session-lifecycle, engram integration |

See: `docs/architecture/layer-topology.md` and `docs/architecture/role-workflows.md`

## Skills by Role

### Product Manager
- sdd-propose, sdd-explore, sdd-onboard
- jira-epic, jira-task, issue-creation

### Architect
- sdd-design, sdd-spec, architecture-governance
- project-orchestrator-skill, skill-creator

### Developer (Frontend)
- angular-spa-skill, react-19-skill, nextjs-15-skill
- typescript-skill, tailwind-4-skill, zustand-5-skill

### Developer (Backend)
- golang-api-skill, go-api, django-drf-skill, django-drf
- database-relational-skill, database-nosql-skill

### QA
- sdd-verify, testing-strategy-skill, pytest, go-testing, playwright

### DevOps
- docker-devops-skill, workspace-automation, session-lifecycle
- github-pr, branch-pr

### UX/UI
- angular-spa-skill, react-19-skill, tailwind-4-skill, zustand-5-skill

## Skills
- testing-strategy-skill: Automated testing and coverage enforcement
- foundation-audit-skill: Structure, docs, links, and duplicate validation
- judgment-day: Adversarial review protocol
- github-pr: Pull request quality and description enforcement
- go-testing: Go test patterns and coverage
- pytest: Python test patterns
- playwright: E2E testing patterns
- reporting-skill: Generation of management reports, metrics, cost analysis, and dashboards on demand
- content-output-skill: Unified content output - technical docs, internal reports, marketing, social media, copywriting persuasivo, storytelling, speeches (Twitter/X, LinkedIn, Reddit, Discord, WhatsApp, blog)
- visual-content-skill: Visual content - ASCII art, Mermaid diagrams, presentation templates, social media cards
- session-workflow-skill: Session lifecycle management and tracking

## Usage
- Update this file when adding or removing skills.
- See docs/architecture/layer-topology.md for topology guidance.
