<#
.SYNOPSIS
Automatic installation and integration script for parallel-execution-limits skill

.DESCRIPTION
Configures the parallel-execution-limits skill in the Foundation stack,
registers it in the skill index, and updates orchestrator configuration.

.VERSION
1.0.0

.AUTHOR
Foundation Team

.LICENSE
MIT
#>

param(
    [string]$SkillPath = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$FoundationRoot = (git rev-parse --show-toplevel 2>$null),
    [switch]$Force
)

# ============================================================================
# Validation
# ============================================================================

Write-Host "🔍 Validating parallel-execution-limits skill installation..." -ForegroundColor Cyan

if (-not (Test-Path $SkillPath)) {
    Write-Host "❌ Skill path not found: $SkillPath" -ForegroundColor Red
    exit 1
}

if (-not $FoundationRoot) {
    Write-Host "❌ Not in a git repository" -ForegroundColor Red
    exit 1
}

# Verify required files
$requiredFiles = @(
    "SKILL.md"
    "README.md"
    "dependency-graph.ps1"
    "parallelism-rules.ps1"
    "resource-pooling.ps1"
    "circuit-breaker.ps1"
    "parallel-executor.ps1"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path "$SkillPath\$file")) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "✅ All required files present" -ForegroundColor Green

# ============================================================================
# Register in Skill Index
# ============================================================================

Write-Host "`n📝 Registering skill in index..." -ForegroundColor Cyan

$skillIndexPath = "$FoundationRoot\skills\SKILL_INDEX.md"

if (Test-Path $skillIndexPath) {
    $indexContent = Get-Content $skillIndexPath -Raw
    
    if ($indexContent -notlike "*parallel-execution-limits*") {
        $newEntry = "`n`n### parallel-execution-limits`n`nAdvanced parallel execution management with dependency graphs, resource pooling, and token budget circuit breaker.`n`n- **Trigger**: `"parallel execution`", `"ejecución paralela`", `"execution limits`"`n- **Use when**: Complex workflows with >10 tasks, GPU/CPU constraints, token budget protection`n- **Key Functions**: `n  - Initialize-ParallelExecutor - Initialize all components`n  - Plan-ParallelExecution - Create execution plan`n  - Invoke-ParallelExecution - Execute tasks in parallel`n  - Get-ExecutionStatus - Monitor execution`n  - Export-ExecutionReport - Generate reports`n`n**Path**: skills/parallel-execution-limits/`n**Documentation**: skills/parallel-execution-limits/SKILL.md"
        
        Add-Content -Path $skillIndexPath -Value $newEntry -Encoding UTF8
        Write-Host "✅ Skill registered in index" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Skill already registered in index" -ForegroundColor Yellow
    }
}

# ============================================================================
# Update Orchestrator Configuration
# ============================================================================

Write-Host "`n⚙️  Updating orchestrator configuration..." -ForegroundColor Cyan

$orchestratorConfigPath = "$FoundationRoot\config\orchestrator.json"

if (Test-Path $orchestratorConfigPath) {
    $config = Get-Content $orchestratorConfigPath | ConvertFrom-Json
    
    # Add parallel-execution-limits to skills if not present
    if (-not $config.skills) {
        $config | Add-Member -Type NoteProperty -Name "skills" -Value @()
    }
    
    if ($config.skills -notcontains "parallel-execution-limits") {
        $config.skills += "parallel-execution-limits"
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $orchestratorConfigPath -Encoding UTF8
        Write-Host "✅ Orchestrator configuration updated" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Skill already in orchestrator configuration" -ForegroundColor Yellow
    }
}

# ============================================================================
# Create Integration Configuration
# ============================================================================

Write-Host "`n📋 Creating integration configuration..." -ForegroundColor Cyan

$integrationConfigPath = "$SkillPath\integration-config.json"

$integrationConfig = @{
    skill = "parallel-execution-limits"
    version = "1.0.0"
    installed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    components = @(
        @{
            name = "dependency-graph"
            file = "dependency-graph.ps1"
            functions = @(
                "Initialize-DependencyGraph"
                "Add-GraphTask"
                "Validate-DependencyGraph"
                "Resolve-TaskDependencies"
                "Get-CriticalPath"
            )
        }
        @{
            name = "parallelism-rules"
            file = "parallelism-rules.ps1"
            functions = @(
                "Initialize-ParallelismRules"
                "Add-ParallelismRule"
                "Apply-ParallelismRules"
                "Generate-ExecutionPlan"
            )
        }
        @{
            name = "resource-pooling"
            file = "resource-pooling.ps1"
            functions = @(
                "Initialize-ResourcePool"
                "Allocate-Resources"
                "Release-Resources"
                "Get-ResourceUtilization"
            )
        }
        @{
            name = "circuit-breaker"
            file = "circuit-breaker.ps1"
            functions = @(
                "Initialize-CircuitBreaker"
                "Test-CircuitBreaker"
                "Track-TokenUsage"
                "Get-TokenBudgetStatus"
            )
        }
        @{
            name = "parallel-executor"
            file = "parallel-executor.ps1"
            functions = @(
                "Initialize-ParallelExecutor"
                "Plan-ParallelExecution"
                "Invoke-ParallelExecution"
                "Get-ExecutionStatus"
            )
        }
    )
    dependencies = @(
        "workflow-orchestrator"
        "project-orchestrator-skill"
        "monitoring-aggregator"
    )
    configuration = @{
        strategies = @("Conservative", "Balanced", "Aggressive")
        defaultStrategy = "Balanced"
        tokenBudgetDefault = 100000
        maxParallelTasksDefault = 8
    }
}

$integrationConfig | ConvertTo-Json -Depth 10 | Set-Content $integrationConfigPath -Encoding UTF8
Write-Host "✅ Integration configuration created" -ForegroundColor Green

# ============================================================================
# Create Activation Hook
# ============================================================================

Write-Host "`n🔗 Creating activation hook..." -ForegroundColor Cyan

$hookPath = "$SkillPath\activate.ps1"

$hookContent = @'
<#
.SYNOPSIS
Activation hook for parallel-execution-limits skill

.DESCRIPTION
Automatically loads the skill when Foundation stack initializes.
#>

# Get skill path
$skillPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import main executor module
. "$skillPath\parallel-executor.ps1"

# Register skill as active
$global:FoundationSkills = $global:FoundationSkills -or @{}
$global:FoundationSkills["parallel-execution-limits"] = @{
    Path = $skillPath
    Loaded = Get-Date
    Status = "Active"
}

Write-Host "✅ parallel-execution-limits skill activated" -ForegroundColor Green
'@

Set-Content -Path $hookPath -Value $hookContent -Encoding UTF8
Write-Host "✅ Activation hook created" -ForegroundColor Green

# ============================================================================
# Validation
# ============================================================================

Write-Host "`n✔️  Validating installation..." -ForegroundColor Cyan

# Test imports
try {
    . "$SkillPath\parallel-executor.ps1" -ErrorAction Stop
    Write-Host "✅ Module imports successful" -ForegroundColor Green
}
catch {
    Write-Host "❌ Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test basic initialization
try {
    $testExecutor = Initialize-ParallelExecutor -Config @{
        Strategy = "Balanced"
        TokenBudget = 100000
    }
    Write-Host "✅ Executor initialization successful" -ForegroundColor Green
}
catch {
    Write-Host "❌ Executor initialization failed: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Summary
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ✅ parallel-execution-limits skill installed successfully  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📚 Documentation:" -ForegroundColor Green
Write-Host "  - Skill Guide: $SkillPath\SKILL.md"
Write-Host "  - Quick Start: $SkillPath\README.md"

Write-Host "`n🚀 Quick Start:" -ForegroundColor Green
Write-Host "  1. Import: . `"$SkillPath\parallel-executor.ps1`""
Write-Host "  2. Initialize: `$executor = Initialize-ParallelExecutor"
Write-Host "  3. Add tasks: Add-GraphTask -Graph `$executor.DependencyGraph ..."
Write-Host "  4. Execute: Invoke-ParallelExecution -Executor `$executor"

Write-Host "`n📋 Configuration:" -ForegroundColor Green
Write-Host "  - Integration Config: $integrationConfigPath"
Write-Host "  - Orchestrator Config: $orchestratorConfigPath"

Write-Host "`n" -ForegroundColor Cyan