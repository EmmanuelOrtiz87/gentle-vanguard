# Workspace Foundation

> **Agnostic template for creating standardized development projects.**
> Regardless of seniority, technology, operating system, or IDE.

## Quick Start

```powershell
# 1. Initialize workspace
.\scripts\wf.ps1 init

# 2. Create a new project (interactive wizard)
.\scripts\wf.ps1 new --interactive

# 3. Or create project with parameters
.\scripts\wf.ps1 new --name my-api --kind service --architecture clean

# 4. Validate
.\scripts\wf.ps1 validate
```

## Features

| Feature | Description |
|---------|-------------|
| **Unified CLI** | Single command (`wf`) for all operations |
| **Interactive Wizard** | Guided project creation without memorizing parameters |
| **Multi-Technology** | Supports Node.js, Go, Python, Rust, and more |
| **Cross-Platform** | Works on Windows, Linux, and macOS |
| **Templates** | service, cli, library, frontend, fullstack, microservices |
| **CI/CD** | GitHub Actions, GitLab CI, Azure DevOps |
| **Containers** | Docker and Kubernetes production-ready |
| **Validation** | Automated linting, testing, and security checks |

## CLI Commands

```bash
wf init          # Initialize workspace on a new machine
wf new          # Create project (wizard if no args)
wf validate     # Validate workspace or project
wf tools        # Install or update tools
wf skills       # Install or update skills
wf clean        # Clean runtime data
wf help         # Show help
```

## Project Types

| Type | Description | Technologies |
|------|-------------|-------------|
| `service` | API, backend, worker | Node.js, Go, Python, .NET |
| `cli` | Command-line tool | Go, Rust, Node.js |
| `library` | Reusable package | TypeScript, Go modules, PyPI |
| `frontend` | Web application | React, Vue, Angular, Next.js |
| `fullstack` | Frontend + Backend | Nx monorepo |
| `microservices` | Distributed architecture | Multi-service with API Gateway |

## Project Structure

```
workspace-foundation/
├── config/              # Global configurations
├── docs/                # Documentation
├── scripts/             # Automation scripts
│   └── wf.ps1          # Main CLI
├── skills/              # Governance skills
├── templates/           # Project templates
│   ├── project-root/   # Common base
│   └── project-types/  # By type (service, cli, frontend...)
└── tools/              # External tools
```

## Included Templates

### CI/CD
- `.github/workflows/ci.yml` - GitHub Actions
- `.gitlab-ci.yml` - GitLab CI
- `azure-pipelines.yml` - Azure DevOps

### Containers
- `Dockerfile` - Multi-stage (Node.js)
- `Dockerfile.go` - Multi-stage (Go)
- `Dockerfile.python` - Multi-stage (Python)
- `k8s/` - Kubernetes manifests

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)
- [Project Types](docs/project-types.md)
- [AI Models](docs/ai-models.md)
- [Tools](docs/tools.md)

## Requirements

| Tool | Required | Description |
|------|----------|-------------|
| Git | Yes | Version control |
| PowerShell | Yes | Automation scripts |
| Go | No | For tools written in Go |
| Node.js | No | For Node.js projects |

## License

MIT
