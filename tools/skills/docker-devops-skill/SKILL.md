---
name: docker-devops-skill
description: Use when working with Docker, Kubernetes, CI/CD pipelines, or deployment configurations. Triggers: "docker", "container", "kubernetes", "k8s", "deployment", "docker-compose", "dockerfile", "pod", "ingress", "helm".
---

# Docker & DevOps Skill

## Purpose

Guide containerization, orchestration, CI/CD setup, and deployment practices.

## Docker Best Practices

### Dockerfile Guidelines

```dockerfile
# Use specific versions
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
version: '3.9'
services:
  app:
    build: .
    ports:
      - "3000:3000"
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
      test: ["CMD-SHELL", "pg_isready -U postgres"]
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
version: '3.9'
services:
  app:
    image: myapp:latest
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Kubernetes Manifests

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: app
          image: myapp:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 20
```

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-svc
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## CI/CD Pipeline Example

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test:coverage
      - uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
      - uses: docker/build-push-action@v5
        with:
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/k8s-deploy@v4
        with:
          namespace: production
          manifests: k8s/
          images: |
            ghcr.io/${{ github.repository }}:${{ github.sha }}
```

## Deployment Checklist

- [ ] Docker image builds successfully
- [ ] Health checks implemented
- [ ] Resource limits set
- [ ] Secrets managed securely
- [ ] Logging configured
- [ ] Monitoring set up
- [ ] Rollback strategy defined
- [ ] Database migrations handled
- [ ] Feature flags ready
- [ ] CDN caching configured

## Common Commands

```bash
# Build
docker build -t myapp:latest .
docker build -t myapp:latest --platform linux/amd64 .

# Run
docker run -d -p 3000:3000 --name myapp myapp:latest
docker-compose up -d

# Inspect
docker ps
docker logs -f myapp
docker exec -it myapp sh

# Clean up
docker system prune -af
docker-compose down -v

# Kubernetes
kubectl apply -f deployment.yaml
kubectl get pods -o wide
kubectl describe pod myapp-pod-name
kubectl logs -f deployment/myapp
kubectl rollout restart deployment/myapp
kubectl rollout undo deployment/myapp
```
