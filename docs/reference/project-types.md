# Project Types

Detailed guide for each project type supported by Workspace Foundation.

## Overview

| Type | Use Case | Default Stack |
|------|----------|---------------|
| service | REST APIs, microservices, workers | Node.js/Express |
| cli | Command-line tools | Go |
| library | Reusable packages | TypeScript |
| frontend | Web applications | React |
| fullstack | Frontend + Backend | Nx Monorepo |
| microservices | Distributed systems | Multi-service |

## Service

Backend services: REST APIs, gRPC services, background workers, daemons.

### Structure

```
my-service/
 cmd/              # Entry points
    server/      # Main application
 internal/         # Private code
    handlers/    # HTTP/gRPC handlers
    middleware/   # Middleware
    models/       # Data models
    services/    # Business logic
 pkg/             # Public packages
 api/             # API definitions (OpenAPI, protobuf)
 scripts/         # Deployment scripts
 Dockerfile
 docker-compose.yml
```

### Commands

```bash
# Development
npm run dev

# Build
npm run build

# Test
npm run test

# Docker
docker-compose up
```

## CLI

Command-line tools and utilities.

### Structure

```
my-cli/
 cmd/             # Command definitions
    root.go     # Root command
 internal/        # Implementation
 pkg/            # Reusable packages
 scripts/        # Install scripts
 main.go
```

### Commands

```bash
# Build
go build -o my-cli ./cmd

# Install
go install

# Test
go test ./...
```

## Library

Reusable packages for other projects.

### Structure

```
my-library/
 src/             # Source code
 types/          # TypeScript types
 utils/          # Utilities
 scripts/        # Build/release scripts
 package.json
 tsconfig.json
```

### Commands

```bash
# Build
npm run build

# Publish
npm publish

# Test
npm test
```

## Frontend

Web applications (SPA or SSR).

### Structure

```
my-app/
 src/
    components/   # Reusable components
    pages/       # Route pages
    hooks/       # Custom hooks
    services/    # API clients
    utils/       # Utilities
 public/          # Static assets
 tests/          # Test files
 Dockerfile
 docker-compose.yml
```

### Frameworks

| Framework | Template File | Description |
|-----------|--------------|-------------|
| React | package.json | React with Vite |
| Vue | package.vue.json | Vue 3 with Vite |
| Next.js | package.nextjs.json | Next.js 14 |
| Angular | package.nx.json | Angular with Nx |

### Commands

```bash
# Development
npm run dev

# Build
npm run build

# Test
npm test

# Lint
npm run lint
```

## Fullstack

Monorepo with frontend and backend.

### Structure

```
my-fullstack/
 apps/
    web/        # Frontend app
    api/        # Backend API
 packages/
    shared/     # Shared types
    ui/         # Shared UI components
 docker-compose.yml
 nx.json         # Nx configuration
```

### Commands

```bash
# All apps
npm run dev

# Single app
npm run dev --workspace=apps/api

# Build all
npm run build
```

## Microservices

Distributed system with multiple services.

### Structure

```
my-microservices/
 services/
    users/       # User service
    orders/      # Order service
    payments/    # Payment service
    notifications/ # Notification service
 api-gateway/    # API Gateway
 shared/         # Shared libraries
 infrastructure/ # Docker, K8s, Terraform
 docker-compose.yml
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| users | 3001 | User management |
| orders | 3002 | Order processing |
| payments | 3003 | Payment handling |
| notifications | 3004 | Email/SMS |
| api-gateway | 8080 | Request routing |

### Commands

```bash
# All services
docker-compose up

# Single service
cd services/users && npm run dev

# Test specific service
npm run test --workspace=services/users
```

## Customization

### Adding Custom Templates

1. Create your template in `templates/project-types/`
2. Add template metadata in `config/workspace.config.json`
3. The CLI will automatically detect it

### Extending Existing Templates

Override files by placing them in your project after creation:

```
my-project/
 .wf/
    templates/   # Your custom overrides
 (generated files)
```
