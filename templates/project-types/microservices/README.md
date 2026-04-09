# Microservices Project Template

## Structure

```
{{project-name}}/
├── services/
│   ├── users/        # User service
│   ├── orders/       # Orders service
│   ├── payments/    # Payment service
│   └── notifications/ # Notification service
├── api-gateway/     # API Gateway (Kong/Nginx)
├── shared/          # Shared libraries
├── infrastructure/  # Docker, K8s, Terraform
└── docker-compose.yml
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| users | 3001 | User management |
| orders | 3002 | Order processing |
| payments | 3003 | Payment handling |
| notifications | 3004 | Email/SMS notifications |
| api-gateway | 8080 | Request routing |

## Quick Start

```bash
# All services
docker-compose up

# Single service
cd services/users && npm run dev

# Run tests
npm run test --workspace=services/users
```

## Communication

- **Sync**: REST/gRPC via API Gateway
- **Async**: RabbitMQ/Kafka for events
- **Service Discovery**: Consul/etcd

## Commands

```bash
# Build all
npm run build --workspaces

# Test all
npm run test --workspaces

# Lint all
npm run lint --workspaces
```
