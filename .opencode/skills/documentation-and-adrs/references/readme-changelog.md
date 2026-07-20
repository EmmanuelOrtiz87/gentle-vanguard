# README & Changelog

## README Structure

```markdown
# Project Name

One-paragraph description of what this project does.

## Quick Start

1. Clone the repo
2. Install dependencies: `npm install`
3. Set up environment: `cp .env.example .env`
4. Run the dev server: `npm run dev`

## Commands

| Command         | Description              |
| --------------- | ------------------------ |
| `npm run dev`   | Start development server |
| `npm test`      | Run tests                |
| `npm run build` | Production build         |
| `npm run lint`  | Run linter               |

## Architecture

Brief overview of the project structure and key design decisions. Link to ADRs for details.

## Contributing

How to contribute, coding standards, PR process.
```

## Changelog

For shipped features:

```markdown
# Changelog

## [1.2.0] - 2025-01-20

### Added

- Task sharing: users can share tasks with team members (#123)
- Email notifications for task assignments (#124)

### Fixed

- Duplicate tasks appearing when rapidly clicking create button (#125)

### Changed

- Task list now loads 50 items per page (was 20) for better UX (#126)
```

## Documentation for Agents

- **CLAUDE.md / rules files** — Document project conventions so agents follow them
- **Spec files** — Keep specs updated so agents build the right thing
- **ADRs** — Help agents understand why past decisions were made (prevents re-deciding)
- **Inline gotchas** — Prevent agents from falling into known traps
