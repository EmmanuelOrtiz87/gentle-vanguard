---
name: architecture
description: Architecture governance skill - ensures proper project structure and layer separation
---

# Architecture Skill

REJECT if:
- Cross-layer imports (e.g., UI imports infra directly)
- Violations of project structure (e.g., domain logic in controllers)

REQUIRE:
- Clear separation of concerns (domain, infra, UI, etc.)

PREFER:
- Modular, decoupled components

