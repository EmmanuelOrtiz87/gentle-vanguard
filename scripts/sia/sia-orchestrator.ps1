param(
    [ValidateSet('init','meta','save-target','feedback','save-review','status','score')]
    [string]$Action = 'status',
    [string]$SessionId,
    [string]$TaskSpec,
    [string]$TargetPath,
    [string]$ReviewPath,
    [string]$OutputDir = ".sia",
    [int]$ScoreThreshold = 80,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Get-SessionDir { param([string]$Sid)
    Join-Path $OutputDir $Sid
}

function Write-JsonOrText {
    param($Data, [switch]$AsJson)
    if ($AsJson) { $Data | ConvertTo-Json -Depth 4 }
    else { $Data | Out-String }
}

switch ($Action) {
    'init' {
        if (-not $SessionId) { $SessionId = "sia-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
        if (-not $TaskSpec) { throw "init requires -TaskSpec" }
        $dir = Get-SessionDir $SessionId
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Set-Content -Path (Join-Path $dir "spec.md") -Value $TaskSpec
        Set-Content -Path (Join-Path $dir "state.json") -Value '{"iteration":0,"status":"init","score":0}'
        $result = @{ sessionId=$SessionId; status="init"; iteration=0; dir=$dir }
        Write-JsonOrText $result -AsJson:$Json
    }

    'meta' {
        if (-not $SessionId) { throw "meta requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        $spec = Get-Content (Join-Path $dir "spec.md") -Raw
        $state = Get-Content (Join-Path $dir "state.json") -Raw | ConvertFrom-Json
        $state.iteration++
        $state.status = "meta-pending"
        $state | ConvertTo-Json | Set-Content (Join-Path $dir "state.json")
        $prevReview = Join-Path $dir "review-$($state.iteration-1).md"
        $feedback = if (Test-Path $prevReview) { Get-Content $prevReview -Raw } else { $null }
        $promptTemplate = Get-Content "config/agent-prompts/SIA-META.md" -Raw
        $prompt = "## TASK`n$spec`n"
        if ($feedback) { $prompt += "`n## PREVIOUS FEEDBACK (iteration $($state.iteration-1))`n$feedback`n" }
        $prompt += "`n## INSTRUCTIONS`n$promptTemplate"
        $promptPath = Join-Path $dir "prompt-meta-$($state.iteration).md"
        Set-Content -Path $promptPath -Value $prompt
        $result = @{ sessionId=$SessionId; iteration=$state.iteration; action="meta"; promptFile=$promptPath; status="pending-agent" }
        Write-JsonOrText $result -AsJson:$Json
    }

    'save-target' {
        if (-not $SessionId) { throw "save-target requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        $state = Get-Content (Join-Path $dir "state.json") -Raw | ConvertFrom-Json
        $dest = Join-Path $dir "target-$($state.iteration).ps1"
        if ($TargetPath -and (Resolve-Path $TargetPath -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $dest -ErrorAction SilentlyContinue).Path) {
            Write-Verbose "Target already at destination"
        } elseif ($TargetPath -and (Test-Path $TargetPath)) {
            Copy-Item -Path $TargetPath -Destination $dest -Force
        } else {
            throw "save-target requires -TargetPath <file> that exists"
        }
        $state.status = "target-saved"
        $state | ConvertTo-Json | Set-Content (Join-Path $dir "state.json")
        $result = @{ sessionId=$SessionId; iteration=$state.iteration; action="save-target"; dest=$dest; status="pending-feedback" }
        Write-JsonOrText $result -AsJson:$Json
    }

    'feedback' {
        if (-not $SessionId) { throw "feedback requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        $state = Get-Content (Join-Path $dir "state.json") -Raw | ConvertFrom-Json
        $target = Get-Content (Join-Path $dir "target-$($state.iteration).ps1") -Raw
        $spec = Get-Content (Join-Path $dir "spec.md") -Raw
        $promptTemplate = Get-Content "config/agent-prompts/SIA-FEEDBACK.md" -Raw
        $prompt = "## SPEC`n$spec`n`n## TARGET (iteration $($state.iteration))`n$target`n`n## INSTRUCTIONS`n$promptTemplate"
        $promptPath = Join-Path $dir "prompt-feedback-$($state.iteration).md"
        Set-Content -Path $promptPath -Value $prompt
        $state.status = "feedback-pending"
        $state | ConvertTo-Json | Set-Content (Join-Path $dir "state.json")
        $result = @{ sessionId=$SessionId; iteration=$state.iteration; action="feedback"; promptFile=$promptPath; status="pending-agent" }
        Write-JsonOrText $result -AsJson:$Json
    }

    'save-review' {
        if (-not $SessionId) { throw "save-review requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        $state = Get-Content (Join-Path $dir "state.json") -Raw | ConvertFrom-Json
        $dest = Join-Path $dir "review-$($state.iteration).md"
        if ($ReviewPath -and (Resolve-Path $ReviewPath -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $dest -ErrorAction SilentlyContinue).Path) {
            Write-Verbose "Review already at destination"
        } elseif ($ReviewPath -and (Test-Path $ReviewPath)) {
            Copy-Item -Path $ReviewPath -Destination $dest -Force
        } else {
            throw "save-review requires -ReviewPath <file> that exists"
        }
        $review = Get-Content $dest -Raw
        $score = if ($review -match 'Score:\s*(\d+)') { [int]$matches[1] } else { 0 }
        $state.score = $score
        $state.status = if ($score -ge $ScoreThreshold) { "passed" } else { "needs-retry" }
        $state | ConvertTo-Json | Set-Content (Join-Path $dir "state.json")
        $result = @{ sessionId=$SessionId; iteration=$state.iteration; score=$score; threshold=$ScoreThreshold; passed=($score -ge $ScoreThreshold); status=$state.status }
        Write-JsonOrText $result -AsJson:$Json
    }

    'status' {
        if (-not $SessionId) { throw "status requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        if (-not (Test-Path $dir)) { Write-JsonOrText @{ error="Session not found: $SessionId" } -AsJson:$Json; return }
        $statePath = Join-Path $dir "state.json"
        if (-not (Test-Path $statePath)) { Write-JsonOrText @{ sessionId=$SessionId; status="no-state"; dir=$dir } -AsJson:$Json; return }
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
        $files = Get-ChildItem $dir -Name
        $result = @{ sessionId=$SessionId; status=$state.status; iteration=$state.iteration; score=$state.score; threshold=$ScoreThreshold; files=$files; dir=$dir }
        Write-JsonOrText $result -AsJson:$Json
    }

    'score' {
        if (-not $SessionId) { throw "score requires -SessionId" }
        $dir = Get-SessionDir $SessionId
        $statePath = Join-Path $dir "state.json"
        if (-not (Test-Path $statePath)) { Write-JsonOrText @{ error="No state for session $SessionId" } -AsJson:$Json; return }
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
        Write-JsonOrText @{ sessionId=$SessionId; iteration=$state.iteration; score=$state.score; threshold=$ScoreThreshold; passed=($state.score -ge $ScoreThreshold) } -AsJson:$Json
    }
}
