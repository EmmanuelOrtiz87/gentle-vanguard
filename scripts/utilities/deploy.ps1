#!/usr/bin/env pwsh
# deploy.ps1 - Deploy application to various targets

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('docker', 'kubernetes', 'aws', 'azure', 'gcp', 'heroku', 'vercel', 'flyio')]
    [string]$Target,
    
    [string]$Environment = 'staging',
    [string]$Image = '',
    [string]$Namespace = '',
    [switch]$DryRun,
    [switch]$Rollback
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

function Write-Step { param([string]$Msg) Write-Host "[->] $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[[OK]] $Msg" -ForegroundColor Green }
function Write-Error { param([string]$Msg) Write-Host "[✗] $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Gray }

function Get-ProjectName {
    $packageJson = Join-Path $projectRoot 'package.json'
    if (Test-Path $packageJson) {
        return (Get-Content $packageJson -Raw | ConvertFrom-Json).name
    }
    $gitDir = Join-Path $projectRoot '.git'
    if (Test-Path $gitDir) {
        Push-Location $projectRoot
        $name = Split-Path (git remote get-url origin 2>$null) -Leaf -ErrorAction SilentlyContinue
        $name = $name -replace '\.git$', ''
        Pop-Location
        return $name
    }
    return 'app'
}

function Invoke-DockerDeploy {
    param([string]$ImageName, [string]$Env)
    
    Write-Step "Building Docker image..."
    $tag = if ($Env -eq 'production') { 'latest' } else { $Env }
    
    if (-not $DryRun) {
        docker build -t "$ImageName`:$tag" .
        docker build -t "$ImageName`:$((Get-Date).ToString('yyyyMMdd-HHmmss'))" .
        
        Write-Step "Pushing to registry..."
        docker push "$ImageName`:$tag"
        
        Write-Success "Docker image deployed: $ImageName`:$tag"
    } else {
        Write-Info "[DRY RUN] Would build and push $ImageName`:$tag"
    }
}

function Invoke-KubernetesDeploy {
    param([string]$ImageName, [string]$Ns, [string]$Env)
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl not found. Install from https://kubernetes.io/docs/tasks/tools/"
        exit 1
    }
    
    Write-Step "Deploying to Kubernetes..."
    
    $kubeContext = if ($Env -eq 'production') { 'production' } else { 'staging' }
    
    if (-not $DryRun) {
        kubectl config use-context $kubeContext
        
        $manifests = Join-Path $projectRoot 'k8s'
        if (Test-Path $manifests) {
            kubectl apply -f $manifests -n $Ns
            
            $imagePullSecret = "$ImageName-secret"
            kubectl create secret docker-registry $imagePullSecret `
                --docker-server=https://index.docker.io/v1/ `
                --docker-username=$env:DOCKER_USERNAME `
                --docker-password=$env:DOCKER_PASSWORD `
                --namespace=$Ns `
                -o yaml --dry-run=client | kubectl apply -f -
        }
        
        Write-Step "Rolling out deployment..."
        kubectl rollout status deployment/$ImageName -n $Ns --timeout=300s
        
        Write-Success "Deployed to Kubernetes in namespace: $Ns"
    } else {
        Write-Info "[DRY RUN] Would deploy to Kubernetes context: $kubeContext, namespace: $Ns"
    }
}

function Invoke-AWSDeploy {
    param([string]$ImageName, [string]$Env)
    
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI not found. Install from https://aws.amazon.com/cli/"
        exit 1
    }
    
    Write-Step "Deploying to AWS ECS..."
    
    $cluster = if ($Env -eq 'production') { 'production-cluster' } else { 'staging-cluster' }
    
    if (-not $DryRun) {
        $accountId = aws sts get-caller-identity --query Account --output text
        
        $ecrRepo = "$accountId.dkr.ecr.us-east-1.amazonaws.com/$ImageName"
        
        Write-Step "Pushing to ECR..."
        aws ecr get-login-password | docker login --username AWS --password-stdin $ecrRepo
        
        docker tag "$ImageName`:latest" "$ecrRepo`:$Env"
        docker push "$ecrRepo`:$Env"
        
        Write-Step "Updating ECS service..."
        aws ecs update-service --cluster $cluster --service $ImageName --force-new-deployment
        
        Write-Success "Deployed to AWS ECS cluster: $cluster"
    } else {
        Write-Info "[DRY RUN] Would deploy to AWS ECS cluster: $cluster"
    }
}

function Invoke-AzureDeploy {
    param([string]$ImageName, [string]$Env)
    
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Error "Azure CLI not found. Install from https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    }
    
    Write-Step "Deploying to Azure Container Apps..."
    
    if (-not $DryRun) {
        $resourceGroup = "rg-$Env"
        $appName = "$ImageName-$Env"
        
        az containerapp update `
            --name $appName `
            --resource-group $resourceGroup `
            --image "$ImageName`:latest" `
            --set-env-vars "ENVIRONMENT=$Env"
        
        Write-Success "Deployed to Azure Container Apps: $appName"
    } else {
        Write-Info "[DRY RUN] Would deploy to Azure Container Apps"
    }
}

function Invoke-VercelDeploy {
    Write-Step "Deploying to Vercel..."
    
    if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
        Write-Error "Vercel CLI not found. Run: npm i -g vercel"
        exit 1
    }
    
    if (-not $DryRun) {
        $vercelArgs = @('--yes')
        if ($Environment -eq 'production') {
            $vercelArgs += '--prod'
        }
        
        & vercel @vercelArgs
        
        Write-Success "Deployed to Vercel"
    } else {
        Write-Info "[DRY RUN] Would deploy to Vercel"
    }
}

function Invoke-FlyIODeploy {
    Write-Step "Deploying to Fly.io..."
    
    if (-not (Get-Command fly -ErrorAction SilentlyContinue)) {
        Write-Error "Fly.io CLI not found. Run: npm i -g @fly/fly"
        exit 1
    }
    
    if (-not $DryRun) {
        Push-Location $projectRoot
        
        if (-not (Test-Path 'fly.toml')) {
            & fly launch --no-generate-names
        }
        
        & fly deploy --env $Environment
        
        Pop-Location
        
        Write-Success "Deployed to Fly.io"
    } else {
        Write-Info "[DRY RUN] Would deploy to Fly.io"
    }
}

function Invoke-Rollback {
    param([string]$Target, [string]$Env)
    
    Write-Step "Rolling back deployment..."
    
    switch ($Target) {
        'kubernetes' {
            kubectl rollout undo deployment/$ImageName -n $Namespace
        }
        'aws' {
            $cluster = if ($Env -eq 'production') { 'production-cluster' } else { 'staging-cluster' }
            aws ecs update-service --cluster $cluster --service $ImageName --force-new-deployment
        }
    }
    
    Write-Success "Rollback initiated"
}

$projectName = Get-ProjectName
$imageName = if ($Image) { $Image } else { $projectName }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deploy: $projectName" -ForegroundColor Cyan
Write-Host "  Target: $Target" -ForegroundColor Cyan
Write-Host "  Environment: $Environment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($Rollback) {
    Invoke-Rollback -Target $Target -Env $Environment
    exit 0
}

switch ($Target) {
    'docker' { Invoke-DockerDeploy -ImageName $imageName -Env $Environment }
    'kubernetes' { Invoke-KubernetesDeploy -ImageName $imageName -Ns $Namespace -Env $Environment }
    'aws' { Invoke-AWSDeploy -ImageName $imageName -Env $Environment }
    'azure' { Invoke-AzureDeploy -ImageName $imageName -Env $Environment }
    'vercel' { Invoke-VercelDeploy }
    'flyio' { Invoke-FlyIODeploy }
}

Write-Host "`n[DONE] Deployment complete!" -ForegroundColor Green
