# Prerequisites

## Install Order

1. Git
2. PowerShell 7
3. Go
4. External tools
5. Workspace skills
6. AI model setup if required
7. Project clone

## External Tools

- `engram`
- project skills or rules

## Workspace Skills

- `documentation-governance`
- `architecture-governance`

## AI Model Setup

- The workspace foundation does not require a base model installed locally.
- If a project uses AI-assisted workflows, follow `docs/ai-models.md`.
- Choose either a local model path or a cloud model path, not both unless the project explicitly
  needs a fallback.
- Record the selected provider and mode in `docs/project-context.md` or `ARCHITECTURE.md`.

## Validation

```powershell
git --version
pwsh --version
go version
engram --help
```
