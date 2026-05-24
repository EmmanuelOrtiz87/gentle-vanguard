    image: myapp:latest
    restart: unless-stopped
    ports:
      - '80:8080'
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
      test: ['CMD', 'curl', '-f', 'http://localhost:8080/health']
      interval: 30s
      timeout: 10s
      retries: 3
```

## Kubernetes Manifests

### Deployment

```yaml
apiversión: apps/v1
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
              memory: '128Mi'
              cpu: '100m'
            limits:
              memory: '512Mi'
              cpu: '500m'
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
apiversión: v1
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
apiversión: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiversión: apps/v1
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
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v4
        with:
          node-versión: '20'
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
      - uses: actions/checkout@v6
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
            type=semver,pattern={{versión}}
      - uses: docker/build-push-action@v5
        with:
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
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