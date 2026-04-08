# Technical Specification: Workspace Architecture (Template)

## Directory Structure
- `/scripts`: Automation engines in PowerShell Core (platform agnostic).
- `/tools`: Integrated core tools (AI Skills, Security Scanners).
- `/config`: Centralized JSON configuration with support for dynamic variable resolution.
- `/.ai-data`: Context persistence for language models (isolated from source code).

## Critical Components

### 1. The Bootstrap Orchestrator (`bootstrap.ps1`)
Uses local dependency verification logic. The script ensures the project has everything needed to be autonomous and deterministic from its own root.

### 2. Validation Protocol (`validate-project.ps1`)
Implements a validation hierarchy:
1. **Security:** Invokes local security scanners.
2. **AI Integrity:** Verifies AI skill libraries.
3. **Documentation:** Triggers session review generation.

### 3. Session Persistence and AI Memory
The system generates Markdown files in `docs/code-reviews/` internally. These files serve as long-term memory specific to the evolution of this independent repository.

### 4. Agnostic Configuration Model
The configuration files use placeholders (e.g., `{workspaceRoot}`) that resolve at runtime, allowing the project to be moved between different paths or servers without breaking.

## Autonomous Workflow
The `finalize-session.ps1` script ensures publication atomicity:
```powershell
Validation -> Tagging -> Commit -> Push (Auto-Upstream) -> Pull Request (gh)
```
Esto crea un historial de Git inmaculado y listo para despliegues basados en Tags.

## Requisitos de Sistema
- PowerShell Core 7+
- Git 2.30+
- Go 1.20+ (para herramientas backend)