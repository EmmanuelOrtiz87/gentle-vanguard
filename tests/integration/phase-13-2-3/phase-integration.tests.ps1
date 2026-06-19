#Requires -Version 7.0
<#
.SYNOPSIS
    Integration tests for Phases 1.3 (Tracing), 2 (State Persistence), 3 (Audit), 5 (Event Sourcing)
#>

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$tracer = Join-Path $repoRoot 'scripts/utilities/ops/TRACING/tracing-instrument.ps1'
$ckptMgr = Join-Path $repoRoot 'scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1'
$rollback = Join-Path $repoRoot 'scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1'
$snapMgr = Join-Path $repoRoot 'scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1'
$auditPipe = Join-Path $repoRoot 'scripts/security/audit-pipeline.ps1'
$evtStore = Join-Path $repoRoot 'scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1'
$sagaOrch = Join-Path $repoRoot 'scripts/utilities/ops/ADVANCED-PATTERNS/saga-orchestrator.ps1'

# ===== Phase 1.3 — Tracing =====

Describe 'Phase 1.3 — Distributed Tracing' {
    It 'tracing-instrument.ps1 should exist' {
        Test-Path $tracer | Should -Be $true
    }

    It 'should start a tracing span' {
        $result = & $tracer -Action start -SpanName test-span -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.traceId | Should -Not -BeNullOrEmpty
        $result.spanId | Should -Not -BeNullOrEmpty
    }

    It 'should end a tracing span' {
        $span = & $tracer -Action start -SpanName test-end-span -Quiet 2>&1
        $result = & $tracer -Action end -TraceId $span.traceId -SpanId $span.spanId -SpanName test-end-span -Attributes @{startTimeUnixNano = $span.startNs } -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.durationMs | Should -BeGreaterThan 0
    }

    It 'should record an error span' {
        $span = & $tracer -Action start -SpanName test-error-span -Quiet 2>&1
        $result = & $tracer -Action error -TraceId $span.traceId -SpanId $span.spanId -SpanName test-error-span -ErrorMessage 'test error' -Attributes @{startTimeUnixNano = $span.startNs } -Quiet 2>&1
        $result.error | Should -Be 'test error'
    }

    It 'should write span files to .telemetry' {
        $tracesDir = Join-Path $repoRoot '.telemetry' 'traces'
        $spansDir = Join-Path $repoRoot '.telemetry' 'spans'
        (Test-Path $tracesDir) | Should -Be $true
        (Get-ChildItem $spansDir -Filter '*.jsonl' -ErrorAction SilentlyContinue).Count | Should -BeGreaterThan 0
    }
}

# ===== Phase 2 — State Persistence =====

Describe 'Phase 2 — State Persistence' {
    It 'checkpoint-manager.ps1 should exist' {
        Test-Path $ckptMgr | Should -Be $true
    }

    It 'should create a checkpoint' {
        $result = & $ckptMgr -Action create -Label test-integration -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.checkpointId | Should -Match '^ckpt-'
        $result.count | Should -BeGreaterThan 0
    }

    It 'should list checkpoints' {
        $result = & $ckptMgr -Action list -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.Count | Should -BeGreaterThan 0
    }

    It 'should verify a checkpoint' {
        $list = & $ckptMgr -Action list -Quiet 2>&1
        $latestId = $list[0].id
        $result = & $ckptMgr -Action verify -CheckpointId $latestId -Quiet 2>&1
        $result.status | Should -Be 'INTACT'
    }

    It 'should diff a checkpoint' {
        $list = & $ckptMgr -Action list -Quiet 2>&1
        $latestId = $list[0].id
        $result = & $ckptMgr -Action diff -CheckpointId $latestId -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.checkpointId | Should -Be $latestId
    }

    It 'rollback-orchestrator.ps1 should exist' {
        Test-Path $rollback | Should -Be $true
    }

    It 'rollback dry-run should work' {
        $result = & $rollback -CheckpointId (Get-ChildItem (Join-Path $repoRoot '.session' 'checkpoints') -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1).Name -DryRun -Quiet 2>&1
        $result.dryRun | Should -Be $true
        $result.valid | Should -Be $true
    }

    It 'snapshot-manager.ps1 should exist' {
        Test-Path $snapMgr | Should -Be $true
    }

    It 'should take a snapshot' {
        $result = & $snapMgr -Action snapshot -Label test-integration -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.id | Should -Match '^snap-'
    }

    It 'should list snapshots' {
        $result = & $snapMgr -Action list -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.Count | Should -BeGreaterThan 0
    }

    It 'backup-rotation.json config should exist and be valid' {
        $cfgPath = Join-Path $repoRoot 'config/backup-rotation.json'
        Test-Path $cfgPath | Should -Be $true
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $cfg.checkpoints.maxCount | Should -BeGreaterThan 0
        $cfg.snapshots.retentionDays | Should -BeGreaterThan 0
    }
}

# ===== Phase 3 — Audit Pipeline =====

Describe 'Phase 3 — Audit Pipeline' {
    It 'audit-pipeline.ps1 should exist' {
        Test-Path $auditPipe | Should -Be $true
    }

    It 'should log an event' {
        $result = & $auditPipe -Action log -EventType session.start -Component test -Operation integration -Actor system -Status success -Message 'Integration test event' -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.id | Should -Match '^aud-'
        $result.type | Should -Be 'session.start'
        $result.status | Should -Be 'success'
    }

    It 'should query events by type' {
        $result = & $auditPipe -Action query -EventType session.start -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.Count | Should -BeGreaterThan 0
    }

    It 'should show audit status' {
        $result = & $auditPipe -Action status -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.totalEvents | Should -BeGreaterThan 0
        $result.byType | Should -Not -BeNullOrEmpty
    }

    It 'rbac-policy.json config should exist and be valid' {
        $rbacPath = Join-Path $repoRoot 'config/rbac-policy.json'
        Test-Path $rbacPath | Should -Be $true
        $rbac = Get-Content $rbacPath -Raw | ConvertFrom-Json
        $rbac.roles.owner | Should -Not -BeNullOrEmpty
        $rbac.roles.'ai-agent' | Should -Not -BeNullOrEmpty
    }

    It 'security-csp.json config should exist and be valid' {
        $cspPath = Join-Path $repoRoot 'config/security-csp.json'
        Test-Path $cspPath | Should -Be $true
        $csp = Get-Content $cspPath -Raw | ConvertFrom-Json
        $csp.csp.dashboard | Should -Not -BeNullOrEmpty
        $csp.headers.'X-Content-Type-Options' | Should -Be 'nosniff'
    }
}

# ===== Phase 5 — Event Sourcing & Saga =====

Describe 'Phase 5 — Event Sourcing & Saga' {
    It 'event-sourcing.ps1 should exist' {
        Test-Path $evtStore | Should -Be $true
    }

    It 'should append an event' {
        $result = & $evtStore -Action append -AggregateId test-aggregate -EventType test.event -EventData '{"key":"value"}' -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.eventId | Should -Match '^evt-'
        $result.type | Should -Be 'test.event'
    }

    It 'should list aggregates' {
        $result = & $evtStore -Action list -Quiet 2>&1
        $result | Should -Not -Be $null
        ($result | Where-Object { $_.aggregateId -eq 'test-aggregate' }).Count | Should -BeGreaterThan 0
    }

    It 'should replay events' {
        $result = & $evtStore -Action replay -AggregateId test-aggregate -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.Count | Should -BeGreaterThan 0
    }

    It 'should build a projection' {
        $result = & $evtStore -Action project -AggregateId test-aggregate -Quiet 2>&1
        $result | Should -Not -Be $null
        $result.eventsCount | Should -BeGreaterThan 0
    }

    It 'saga-orchestrator.ps1 should exist' {
        Test-Path $sagaOrch | Should -Be $true
    }

    It 'should list sagas (empty)' {
        $result = & $sagaOrch -Action list -Quiet 2>&1
        $result | Should -Not -Be $null
    }
}

# ===== Cross-Phase Integration =====

Describe 'Cross-Phase Integration' {
    It 'session-autostart steps should reference all new phases' {
        $cfgPath = Join-Path $repoRoot 'config/session-autostart.config.json'
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $stepIds = $cfg.pipeline.steps.id
        $stepIds -contains 'tracing-init' | Should -Be $true
        $stepIds -contains 'checkpoint-auto-create' | Should -Be $true
        $stepIds -contains 'audit-pipeline-init' | Should -Be $true
        $stepIds -contains 'event-sourcing-init' | Should -Be $true
        $stepIds -contains 'judgment-day-correction' | Should -Be $true
        $stepIds -contains 'cloud-connectors-init' | Should -Be $true
    }

    It 'maintenance-watchtower should have all new check functions' {
        $content = Get-Content (Join-Path $repoRoot 'scripts/maintenance/maintenance-watchtower.ps1') -Raw
        $content -match 'function Check-CloudConnectors' | Should -Be $true
        $content -match 'function Check-Tracing' | Should -Be $true
        $content -match 'function Check-StatePersistence' | Should -Be $true
        $content -match 'function Check-AuditPipeline' | Should -Be $true
        $content -match 'Check-CloudConnectors' | Should -Be $true
        $content -match 'Check-Tracing' | Should -Be $true
        $content -match 'Check-StatePersistence' | Should -Be $true
        $content -match 'Check-AuditPipeline' | Should -Be $true
    }

    It 'correction-rules-engine should validate 12 rules' {
        $result = & (Join-Path $repoRoot 'scripts/adaptive/correction-rules-engine.ps1') -Mode validate -Quiet 2>&1
        $result | Should -Be $true
    }

    It 'dashboard should build with new types' {
        $buildDir = Join-Path $repoRoot 'apps/web-dashboard/dist'
        (Test-Path (Join-Path $buildDir 'index.html')) | Should -Be $true
    }

    It 'session-cleanup should call tracing/checkpoint/audit' {
        $content = Get-Content (Join-Path $repoRoot 'scripts/utilities/session/session-cleanup-start.ps1') -Raw
        $content -match 'tracing-instrument.*Action end' | Should -Be $true
        $content -match 'checkpoint-manager.*Action prune' | Should -Be $true
        $content -match 'audit-pipeline.*session.end' | Should -Be $true
        $content -match 'event-sourcing.*session.ended' | Should -Be $true
    }
}
