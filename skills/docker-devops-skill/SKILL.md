---
name: docker-devops-skill
description: Use when working with Docker, Kubernetes, CI/CD pipelines, or deployment configurations. Triggers: "docker", "container", "kubernetes", "k8s", "deployment", "docker-compose", "dockerfile", "pod", "ingress", "helm".
metadata:
  source: GV-native
---

# Docker & DevOps Skill

## Purpose

Guide containerization, orchestration, CI/CD setup, and deployment practices.

## Docker Best Practices

### Dockerfile Guidelines

```dockerfile
# Use specific versións
FROM node:20-alpine

# Use non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy only necessary files
COPY package*.json ./
RUN npm ci --only=production

# Multi-stage build
FROM builder AS builder
RUN npm run build

FROM runtime
COPY --from=builder /app/dist ./dist

# Health check
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:3000/health

# Non-root execution
USER nodeuser
```

### Image Optimization

```dockerfile
# Use Alpine for smaller images
FROM node:20-alpine

# Combine RUN commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# .dockerignore
node_modules
.git
*.log
.env*
```

## Docker Compose Patterns

### Development Setup

```yaml
versión: '3.9'
services:
  app:
    build: .
    ports:
      - '3000:3000'
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Production Setup

```yaml
versión: '3.9'
services:
  app:

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
