# Fullstack Project Template
# Monorepo structure with frontend and backend

## Structure

```
{{project-name}}/
 apps/
    web/          # Frontend application
    api/          # Backend API service
 packages/
    shared/       # Shared types and utilities
    ui/           # Shared UI components
 docker-compose.yml
 nx.json           # Nx monorepo config
```

## Quick Start

```bash
# Development
npm run dev

# Build all
npm run build

# Test all
npm run test

# Docker
docker-compose up
```

## Architecture

- **Monorepo**: Nx for workspace management
- **Frontend**: React/Next.js SPA
- **Backend**: Node.js/Go/FastAPI API
- **Shared**: TypeScript types, validation schemas, utilities

## Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start all apps in dev mode |
| `npm run build` | Build all apps |
| `npm run test` | Run all tests |
| `npm run lint` | Lint all apps |
| `docker-compose up` | Run full stack in Docker |
