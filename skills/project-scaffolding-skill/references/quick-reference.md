# Workspace Foundation - Quick Reference

## CLI Commands

```powershell
# Initialize workspace
.\scripts\foundation\wf.ps1 init

# Create project
.\scripts\foundation\wf.ps1 new --name <name> --kind <type> [options]

# Validate
.\scripts\foundation\wf.ps1 validate [--project <name>] [--full]

# Tools
.\scripts\foundation\wf.ps1 tools [--install|--list|--update]

# Skills
.\scripts\foundation\wf.ps1 skills [--install|--list]

# Clean
.\scripts\foundation\wf.ps1 clean [--data|--cache|--all]

# Help
.\scripts\foundation\wf.ps1 help
```

## Project Creation Options

| Option | Description | Values |
|--------|-------------|--------|
| `--name` | Project name | String |
| `--kind` | Project type | service, cli, library, frontend, fullstack, microservices |
| `--architecture` | Pattern | layered, clean, modular, microservices |
| `--ai-mode` | AI mode | none, local, cloud |
| `--ai-provider` | AI provider | openai, anthropic, gemini, ollama |
| `--ai-model` | Model name | gpt-4, claude-3-opus, etc. |
| `--framework` | Frontend framework | react, vue, angular, nextjs |
| `--clone` | Clone URL | Git repository URL |
| `--output` | Output path | Directory path |
| `--interactive` | Wizard mode | Flag |

## Template Structure

```
templates/
 project-root/
    README.md
    AGENTS.md
    ARCHITECTURE.md
    docs/
        project-context.md
 project-types/
     service/
        Dockerfile
        .github/workflows/
        k8s/
     cli/
     library/
     frontend/
     fullstack/
     microservices/
```

## File Replacements

When applying templates, replace these placeholders:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `{{project-name}}` | Project name | my-api |
| `{{namespace}}` | K8s namespace | production |
| `{{domain}}` | Domain | api.example.com |
| `{{version}}` | Version | 1.0.0 |
| `{{image}}` | Docker image | ghcr.io/user/repo |

## Common Commands by Stack

### Node.js
```bash
npm install
npm run dev
npm run build
npm test
npm run lint
```

### Go
```bash
go mod download
go run ./cmd/server
go build ./...
go test ./...
go vet ./...
```

### Python
```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
python -m pytest
```

## Docker Commands
```bash
docker build -t my-image .
docker run -p 8080:8080 my-image
docker-compose up
docker-compose down
```

## Kubernetes Commands
```bash
kubectl apply -f k8s/
kubectl get pods
kubectl logs -f deployment/my-app
kubectl rollout restart deployment/my-app
```

## Git Workflow
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <url>
git push -u origin main
```

## Environment Variables Template

Create `.env.example` with all required variables:

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# API Keys
API_KEY=your-api-key-here

# Configuration
NODE_ENV=development
PORT=3000
```

## Validation Checklist

- [ ] README.md has project name and description
- [ ] docs/project-context.md is complete
- [ ] .env.example exists with all required vars
- [ ] package.json/go.mod has correct name/version
- [ ] Git initialized
- [ ] Initial commit made
- [ ] Validation passed

## Project Type Defaults

| Type | Default Port | Default Test | Default Build |
|------|-------------|--------------|---------------|
| service | 3000/8080 | npm test / go test | npm run build / go build |
| cli | N/A | npm test / go test | go build |
| library | N/A | npm test | npm run build |
| frontend | 3000 | npm test | npm run build |
| fullstack | 3000/3001 | npm test | npm run build |
| microservices | varies | npm test | varies |
