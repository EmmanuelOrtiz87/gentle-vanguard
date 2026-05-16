$script:fCommands = @(
    'review', 'audit', 'pr', 'push', 'publish', 'status', 'health', 'update',
    'update-all', 'update-tools', 'install', 'install-engram', 'orchestrator-status',
    'stack-dashboard', 'runtime-route', 'runtime-gate', 'custom-rules-status',
    'response-mode', 'ide-status', 'diagnose', 'verify', 'start-session',
    'end-session', 'day-end-closure', 'task-brief', 'migrate-structure',
    'context-pack', 'compact-start', 'context-metrics', 'token-guard',
    'checkpoint', 'list-checkpoints', 'rollback-checkpoint', 'clean-branches',
    'homologate', 'foundation-sync', 'release-homologation', 'agent-alert',
    'agent', 'skills', 'dispatch', 'events', 'reset-demo', 'judgment-day',
    'simplify-text', 'context-dashboard', 'dashboard', 'mq', 'export-metrics',
    'monthly-report', 'platform-info', 'sdd-gate', 'sdd-metrics', 'sync-drift',
    'benchmark', 'version', 'route', 'webhook', 'predictor', 'sla-dashboard',
    'escalation', 'live-server', 'learning', 'watchtower', 'heal', 'help'
)

$script:fSubs = @{
    agent          = 'BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'status', 'list'
    dashboard      = 'open', 'live', 'auto', 'status', 'stop'
    review         = 'security', 'quality', 'all', 'judgment-day'
    audit          = 'quick', 'standard', 'full', 'deep', 'judgment', 'unified'
    skills         = 'discover', 'map', 'agents', 'validate'
    'clean-branches' = 'apply'
    homologate     = 'apply'
    'foundation-sync' = 'apply'
    'agent-alert'  = 'strict'
    'sla-dashboard' = 'open'
    webhook        = 'test'
    learning       = 'auto', 'apply', 'auto-pr'
    watchtower     = 'fix', 'quiet', 'all', 'heal'
    heal           = 'fix', 'config', 'hooks', 'session', 'skills', 'engram'
    benchmark      = 'full'
    dispatch       = 'memory', 'list', 'sync'
    events         = 'list', 'publish', 'subscribe', 'unsubscribe'
    mq             = 'status', 'publish', 'consume', 'test'
    'export-metrics'  = 'csv', 'jsonl', 'sqlite', 'all'
    'monthly-report'  = 'csv', 'jsonl', 'sqlite', 'all'
    'runtime-gate'    = 'ai', 'heavy-ai', 'network', 'local', 'metrics', 'any'
    'response-mode'   = 'list', 'ahorro', 'normal', 'detallado'
    'token-guard'     = 'auto'
    push           = 'pr', 'later'
    publish        = 'pr', 'later'
}

$script:fSwitches = @(
    '-Force', '-SkipTests', '-SkipReview', '-JSON',
    '-StrictCleanup', '-SkipHomologationGate'
)

$script:completer = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $elements = $commandAst.CommandElements | ForEach-Object { $_.Extent.Text }
    $idx = $elements.Count - 1
    $raw = $wordToComplete.TrimStart("'", '"')

    if ($idx -le 0) { return }
    if ($raw.StartsWith('-')) {
        return $script:fSwitches | Where-Object { $_ -like "$raw*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'Parameter', $_)
        }
    }

    if ($idx -eq 1) {
        return $script:fCommands | Where-Object { $_ -like "$raw*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', " ($($script:fSubs[$_] -join '|'))")
        }
    }

    $cmd = $elements[1].TrimStart("'", '"')
    if ($script:fSubs.ContainsKey($cmd)) {
        return $script:fSubs[$cmd] | Where-Object { $_ -like "$raw*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $script:fSwitches | Where-Object { $_ -like "$raw*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'Parameter', $_)
    }
}

Register-ArgumentCompleter -CommandName 'foundation' -ScriptBlock $script:completer
