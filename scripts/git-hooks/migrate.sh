#!/usr/bin/env bash
# migrate.sh - Database migration runner (Linux/macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
ACTION="up"
STEPS=1

# Help function
show_help() {
    echo "Usage: $0 [--action <action>] [--steps <steps>]"
    echo ""
    echo "Actions:"
    echo "  up      - Run pending migrations (default)"
    echo "  down    - Rollback last migration"
    echo "  status  - Show migration status"
    echo "  fresh   - Reset and re-run all migrations"
    echo "  seed    - Run database seeders"
    echo ""
    echo "Examples:"
    echo "  $0 --action up"
    echo "  $0 --action down --steps 1"
    echo "  $0 --action fresh"
    echo "  $0 --action seed"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --action)
            ACTION="$2"
            shift 2
            ;;
        --steps)
            STEPS="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Logging
log_step() { echo -e "${YELLOW}[→]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Prisma migrations
run_prisma_migrate() {
    log_step "Running Prisma migrate $ACTION..."
    
    if [[ ! -d "$PROJECT_ROOT/prisma" ]]; then
        log_error "Prisma directory not found"
        return 1
    fi
    
    case "$ACTION" in
        up)
            if [[ $STEPS -gt 1 ]]; then
                npx prisma migrate dev --create-only
            else
                npx prisma migrate dev
            fi
            ;;
        down)
            npx prisma migrate reset --force
            ;;
        status)
            npx prisma migrate status
            ;;
        fresh)
            npx prisma migrate reset --force
            npx prisma db push
            ;;
        seed)
            if [[ -f "$PROJECT_ROOT/prisma/seed.ts" ]]; then
                npx tsx prisma/seed.ts
            fi
            ;;
    esac
    
    log_success "Prisma migration complete"
}

# TypeORM migrations
run_typeorm_migrate() {
    log_step "Running TypeORM migration $ACTION..."
    
    case "$ACTION" in
        up)
            npx typeorm migration:run
            ;;
        down)
            npx typeorm migration:revert
            ;;
        status)
            npx typeorm migration:show
            ;;
        fresh)
            npx typeorm schema:drop
            npx typeorm migration:run
            ;;
        seed)
            if [[ -f "$PROJECT_ROOT/src/database/seed.ts" ]]; then
                npx ts-node src/database/seed.ts
            fi
            ;;
    esac
    
    log_success "TypeORM migration complete"
}

# Knex migrations
run_knex_migrate() {
    log_step "Running Knex migration $ACTION..."
    
    case "$ACTION" in
        up)
            npx knex migrate:latest --knexfile knexfile.ts
            ;;
        down)
            npx knex migrate:down --knexfile knexfile.ts
            ;;
        status)
            npx knex migrate:status --knexfile knexfile.ts
            ;;
        fresh)
            npx knex migrate:rollback --knexfile knexfile.ts
            npx knex migrate:latest --knexfile knexfile.ts
            ;;
        seed)
            npx knex seed:run --knexfile knexfile.ts
            ;;
    esac
    
    log_success "Knex migration complete"
}

# Go migrations
run_go_migrate() {
    log_step "Running Go migrate $ACTION..."
    
    if ! command -v migrate &> /dev/null; then
        log_error "golang-migrate not found. Install: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
        return 1
    fi
    
    local db_url="${DATABASE_URL}"
    
    if [[ -z "$db_url" ]]; then
        # Try to read from .env
        if [[ -f "$PROJECT_ROOT/.env" ]]; then
            db_url=$(grep DATABASE_URL "$PROJECT_ROOT/.env" | cut -d'=' -f2)
        fi
    fi
    
    if [[ -z "$db_url" ]]; then
        log_error "DATABASE_URL not set"
        return 1
    fi
    
    local migrations_dir="$PROJECT_ROOT/migrations"
    
    case "$ACTION" in
        up)
            migrate -path "$migrations_dir" -database "$db_url" up
            ;;
        down)
            migrate -path "$migrations_dir" -database "$db_url" down "$STEPS"
            ;;
        status)
            migrate -path "$migrations_dir" -database "$db_url" version
            ;;
        fresh)
            migrate -path "$migrations_dir" -database "$db_url" down
            migrate -path "$migrations_dir" -database "$db_url" up
            ;;
    esac
    
    log_success "Go migration complete"
}

# Main
main() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Database Migration: $ACTION${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [[ -f "$PROJECT_ROOT/prisma/schema.prisma" ]]; then
        run_prisma_migrate
    elif [[ -d "$PROJECT_ROOT/src/database" ]] && ls "$PROJECT_ROOT/src/database"/*migration* &>/dev/null; then
        run_typeorm_migrate
    elif [[ -f "$PROJECT_ROOT/knexfile.ts" ]]; then
        run_knex_migrate
    elif [[ -f "$PROJECT_ROOT/go.mod" ]] && [[ -d "$PROJECT_ROOT/migrations" ]]; then
        run_go_migrate
    else
        log_error "No migration tool detected (Prisma, TypeORM, Knex, or golang-migrate)"
        exit 1
    fi
}

main
