---
description: Build and deploy the Docker stack
agent: ops-agent
---

Build and deploy the Gentle-Vanguard Docker stack:

1. Verify Docker is running: `docker info`
2. Build the image: `docker build -t gentle-vanguard .`
3. Run tests: `docker compose -f docker-compose.test.yml up --abort-on-container-exit`
4. If tests pass, deploy: `docker compose up -d`
5. Verify services: `docker compose ps`
6. Check health endpoints

Services to verify:

- web-dashboard (port 8080)
- mcp-server (port 3001)
- websocket-server (port 8081)
- health-api (port 9090)
- jaeger (port 16686)
- prometheus (port 9091)

$ARGUMENTS
