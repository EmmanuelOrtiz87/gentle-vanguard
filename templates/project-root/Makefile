# Makefile for {{project-name}}
# Common development tasks

.PHONY: help install dev build test lint clean docker-start docker-stop

# Variables
PROJECT_NAME := {{project-name}}
DOCKER_COMPOSE := docker-compose

# Colors
GREEN  := \033[0;32m
YELLOW := \033[1;33m
NC     := \033[0m

# Default target
help:
	@echo "$(GREEN){{project-name}} - Available commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup:$(NC)"
	@echo "  make install        Install dependencies"
	@echo "  make dev            Start development server"
	@echo ""
	@echo "$(YELLOW)Quality:$(NC)"
	@echo "  make test           Run tests"
	@echo "  make lint           Run linter"
	@echo "  make typecheck      Run type checker"
	@echo ""
	@echo "$(YELLOW)Build:$(NC)"
	@echo "  make build          Build for production"
	@echo "  make clean          Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)Docker:$(NC)"
	@echo "  make docker-start   Start Docker containers"
	@echo "  make docker-stop    Stop Docker containers"
	@echo "  make docker-logs   View Docker logs"
	@echo ""
	@echo "$(YELLOW)Database:$(NC)"
	@echo "  make db-migrate     Run database migrations"
	@echo "  make db-seed        Seed database"
	@echo "  make db-reset       Reset database"
	@echo ""
	@echo "$(YELLOW)CI/CD:$(NC)"
	@echo "  make ci             Run CI pipeline locally"
	@echo ""

# Setup
install:
	@echo "Installing dependencies..."
	@npm install

# Development
dev:
	@echo "Starting development server..."
	@npm run dev

# Quality
test:
	@echo "Running tests..."
	@npm run test

test:watch:
	@echo "Running tests in watch mode..."
	@npm run test:watch

test:coverage:
	@echo "Running tests with coverage..."
	@npm run test:coverage

lint:
	@echo "Running linter..."
	@npm run lint

lint:fix:
	@echo "Fixing linting issues..."
	@npm run lint:fix

typecheck:
	@echo "Running type checker..."
	@npm run typecheck

format:
	@echo "Formatting code..."
	@npm run format

# Build
build:
	@echo "Building for production..."
	@npm run build

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf dist build coverage .next
	@npm cache clean --force

# Docker
docker-start:
	@echo "Starting Docker containers..."
	@$(DOCKER_COMPOSE) up -d

docker-stop:
	@echo "Stopping Docker containers..."
	@$(DOCKER_COMPOSE) down

docker-logs:
	@$(DOCKER_COMPOSE) logs -f

docker-build:
	@echo "Building Docker images..."
	@$(DOCKER_COMPOSE) build

# Database
db-migrate:
	@echo "Running migrations..."
	@npm run db:migrate

db-seed:
	@echo "Seeding database..."
	@npm run db:seed

db-reset:
	@echo "Resetting database..."
	@npm run db:reset

# CI/CD
ci: lint typecheck test build

# Security
security:audit:
	@echo "Running security audit..."
	@npm audit --audit-level=high

# Docs
docs:generate:
	@echo "Generating documentation..."
	@npm run docs:generate

# Deploy
deploy:staging:
	@echo "Deploying to staging..."
	@./scripts/deploy.ps1 -Target kubernetes -Environment staging

deploy:production:
	@echo "Deploying to production..."
	@./scripts/deploy.ps1 -Target kubernetes -Environment production

# Health check
health:
	@curl -s http://localhost:3000/health || echo "Service not responding"
