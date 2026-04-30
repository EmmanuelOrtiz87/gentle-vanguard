#!/usr/bin/env bash
# deploy.sh - Deploy application to various targets (Linux/macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
TARGET=""
ENVIRONMENT="staging"
IMAGE=""
NAMESPACE=""
DRY_RUN=false

# Help function
show_help() {
    echo "Usage: $0 --target <target> [--env <environment>] [--image <image>] [--namespace <namespace>] [--dry-run]"
    echo ""
    echo "Targets:"
    echo "  docker       - Build and push Docker image"
    echo "  kubernetes   - Deploy to Kubernetes"
    echo "  aws          - Deploy to AWS ECS"
    echo "  azure        - Deploy to Azure Container Apps"
    echo "  gcp          - Deploy to Google Cloud Run"
    echo "  heroku       - Deploy to Heroku"
    echo "  vercel       - Deploy to Vercel"
    echo "  flyio        - Deploy to Fly.io"
    echo ""
    echo "Examples:"
    echo "  $0 --target docker --env production"
    echo "  $0 --target kubernetes --env staging --namespace myapp"
    echo "  $0 --target docker --dry-run"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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

# Get project name
get_project_name() {
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        node -p "require('./package.json').name"
    elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        basename "$PROJECT_ROOT"
    else
        echo "app"
    fi
}

# Logging functions
log_step() { echo -e "${YELLOW}[]${NC} $1"; }
log_success() { echo -e "${GREEN}[]${NC} $1"; }
log_error() { echo -e "${RED}[]${NC} $1"; }

# Docker deployment
deploy_docker() {
    local image_name="${IMAGE:-$(get_project_name)}"
    local tag="${ENVIRONMENT}"
    
    log_step "Building Docker image..."
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would build: $image_name:$tag"
        return
    fi
    
    docker build -t "$image_name:$tag" .
    docker build -t "$image_name:$(date +%Y%m%d-%H%M%S)" .
    
    log_step "Pushing to registry..."
    docker push "$image_name:$tag"
    
    log_success "Docker image deployed: $image_name:$tag"
}

# Kubernetes deployment
deploy_kubernetes() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Install from https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    local image_name="${IMAGE:-$(get_project_name)}"
    local ns="${NAMESPACE:-default}"
    
    log_step "Deploying to Kubernetes..."
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would deploy to Kubernetes, namespace: $ns"
        return
    fi
    
    kubectl config use-context "${ENVIRONMENT}" 2>/dev/null || true
    
    if [[ -d "$PROJECT_ROOT/k8s" ]]; then
        kubectl apply -f "$PROJECT_ROOT/k8s" -n "$ns"
    fi
    
    log_step "Rolling out deployment..."
    kubectl rollout status deployment/"$image_name" -n "$ns" --timeout=300s || true
    
    log_success "Deployed to Kubernetes in namespace: $ns"
}

# AWS deployment
deploy_aws() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Install from https://aws.amazon.com/cli/"
        exit 1
    fi
    
    local image_name="${IMAGE:-$(get_project_name)}"
    local cluster="${ENVIRONMENT}"
    
    log_step "Deploying to AWS ECS..."
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would deploy to AWS ECS cluster: $cluster"
        return
    fi
    
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text)
    local ecr_repo="$account_id.dkr.ecr.us-east-1.amazonaws.com/$image_name"
    
    log_step "Pushing to ECR..."
    aws ecr get-login-password | docker login --username AWS --password-stdin "$ecr_repo"
    docker tag "$image_name:latest" "$ecr_repo:$ENVIRONMENT"
    docker push "$ecr_repo:$ENVIRONMENT"
    
    log_step "Updating ECS service..."
    aws ecs update-service --cluster "$cluster-cluster" --service "$image_name" --force-new-deployment || true
    
    log_success "Deployed to AWS ECS cluster: $cluster-cluster"
}

# Main
main() {
    if [[ -z "$TARGET" ]]; then
        log_error "Target is required. Use --target <target>"
        show_help
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deploy: $(get_project_name)${NC}"
    echo -e "${GREEN}  Target: $TARGET${NC}"
    echo -e "${GREEN}  Environment: $ENVIRONMENT${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    case "$TARGET" in
        docker)
            deploy_docker
            ;;
        kubernetes|k8s)
            deploy_kubernetes
            ;;
        aws)
            deploy_aws
            ;;
        azure|gcp|heroku|vercel|flyio)
            log_error "Target '$TARGET' requires additional setup. See deploy.ps1 for full implementation."
            exit 1
            ;;
        *)
            log_error "Unknown target: $TARGET"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    log_success "Deployment complete!"
}

main
