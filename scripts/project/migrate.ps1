#!/usr/bin/env pwsh
# migrate.ps1 - Database migration runner

param(
    [ValidateSet('up', 'down', 'status', 'fresh', 'seed')]
    [string]$Action = 'up',
    
    [string]$Database = '',
    [int]$Steps = 1,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

function Write-Step { param([string]$Msg) Write-Host "[->] $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[[OK]] $Msg" -ForegroundColor Green }
function Write-Error { param([string]$Msg) Write-Host "[] $Msg" -ForegroundColor Red }

function Get-DatabaseUrl {
    $envVar = if ($Database) { $Database } else { 'DATABASE_URL' }
    $url = $env:$envVar
    
    if ([string]::IsNullOrWhiteSpace($url)) {
        $envExample = Join-Path $projectRoot '.env.example'
        if (Test-Path $envExample) {
            $content = Get-Content $envExample -Raw
            if ($content -match "$envVar=(.+)") {
                $url = $matches[1]
            }
        }
    }
    
    return $url
}

function Invoke-PrismaMigrate {
    param([string]$DbAction, [int]$DbSteps
    
    $prismaDir = Join-Path $projectRoot 'prisma'
    if (-not (Test-Path $prismaDir)) {
        Write-Error "Prisma directory not found"
        return
    }
    
    Write-Step "Running Prisma migrate $DbAction..."
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: prisma migrate $DbAction" -ForegroundColor Gray
        return
    }
    
    switch ($DbAction) {
        'up' {
            if ($Steps -gt 1) {
                & prisma migrate dev --create-only
            } else {
                & prisma migrate dev
            }
        }
        'down' {
            & prisma migrate reset --force
        }
        'status' {
            & prisma migrate status
        }
        'fresh' {
            & prisma migrate reset --force
            & prisma db push
        }
        'seed' {
            if (Test-Path (Join-Path $projectRoot 'prisma\seed.ts')) {
                & npx tsx prisma/seed.ts
            }
        }
    }
}

function Invoke-TypeORMMigrate {
    param([string]$DbAction)
    
    Write-Step "Running TypeORM migration $DbAction..."
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run typeorm migration:$DbAction" -ForegroundColor Gray
        return
    }
    
    switch ($DbAction) {
        'up' { & npx typeorm migration:run }
        'down' { & npx typeorm migration:revert }
        'status' { & npx typeorm migration:show }
        'fresh' { & npx typeorm schema:drop && & npx typeorm migration:run }
        'seed' { & npx ts-node src/database/seed.ts }
    }
}

function Invoke-KnexMigrate {
    param([string]$DbAction, [int]$DbSteps)
    
    Write-Step "Running Knex migration $DbAction..."
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run knex migrate:$DbAction" -ForegroundColor Gray
        return
    }
    
    switch ($DbAction) {
        'up' { & npx knex migrate:latest --knexfile knexfile.ts }
        'down' { & npx knex migrate:down --knexfile knexfile.ts }
        'status' { & npx knex migrate:status --knexfile knexfile.ts }
        'fresh' { & npx knex migrate:rollback --knexfile knexfile.ts && & npx knex migrate:latest --knexfile knexfile.ts }
        'seed' { & npx knex seed:run --knexfile knexfile.ts }
    }
}

function Invoke-GoMigrate {
    param([string]$DbAction)
    
    Write-Step "Running Go migrate $DbAction..."
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run golang-migrate $DbAction" -ForegroundColor Gray
        return
    }
    
    $dbUrl = Get-DatabaseUrl
    $migrationsDir = Join-Path $projectRoot 'migrations'
    
    switch ($DbAction) {
        'up' { & migrate -path $migrationsDir -database $dbUrl up }
        'down' { & migrate -path $migrationsDir -database $dbUrl down $Steps }
        'status' { & migrate -path $migrationsDir -database $dbUrl version }
        'fresh' { & migrate -path $migrationsDir -database $dbUrl down && & migrate -path $migrationsDir -database $dbUrl up }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Database Migration: $Action" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (Test-Path (Join-Path $projectRoot 'prisma\schema.prisma')) {
    Invoke-PrismaMigrate -DbAction $Action -DbSteps $Steps
}
elseif (Test-Path (Join-Path $projectRoot 'src\database\**\*migrations*')) {
    Invoke-TypeORMMigrate -DbAction $Action
}
elseif (Test-Path (Join-Path $projectRoot 'knexfile.ts')) {
    Invoke-KnexMigrate -DbAction $Action -DbSteps $Steps
}
elseif (Test-Path (Join-Path $projectRoot 'go.mod')) {
    Invoke-GoMigrate -DbAction $Action
}
else {
    Write-Error "No migration tool detected (Prisma, TypeORM, Knex, or golang-migrate)"
    exit 1
}

Write-Success "Migration complete!"
