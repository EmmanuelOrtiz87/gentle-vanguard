function Get-FoundationRepoRoot {
    if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) {
        return (Resolve-Path $env:FOUNDATION_BASE_DIR).Path
    }

    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) {
        $root = Split-Path -Parent $root
    }

    if (-not $root) {
        return (Get-Location).Path
    }

    return $root
}

function Resolve-FoundationEngramBinary {
    param([string]$RepoRoot = (Get-FoundationRepoRoot))

    if ($env:ENGRAM_CMD -and (Test-Path $env:ENGRAM_CMD)) {
        return (Resolve-Path $env:ENGRAM_CMD).Path
    }

    $candidatePaths = @(
        (Join-Path $RepoRoot 'tools\engram.exe'),
        (Join-Path ($env:USERPROFILE ? $env:USERPROFILE : $env:HOME) 'bin\engram.exe'),
        (Join-Path ($env:GOPATH ? $env:GOPATH : (Join-Path $env:USERPROFILE 'go')) 'bin\engram.exe')
    )

    foreach ($candidate in $candidatePaths) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd -and $engramCmd.Source) {
        return $engramCmd.Source
    }

    return $null
}

function Initialize-FoundationEngramEnvironment {
    param([string]$RepoRoot = (Get-FoundationRepoRoot))

    $dataDir = Join-Path $RepoRoot '.engram-data'
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $env:ENGRAM_DATA_DIR = $dataDir
    $env:ENGRAM_SKIP_UPDATE = '1'

    return $dataDir
}

function Remove-FoundationEngramNoise {
    param([object[]]$Output)

    $lines = @($Output | ForEach-Object { [string]$_ })
    return @($lines | Where-Object {
        $_ -notmatch '^Could not check for updates:' -and
        $_ -notmatch '^Get "https://api\.github\.com/repos/Gentleman-Programming/engram/releases/latest"'
    })
}

function Write-FoundationEngramFallback {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments,
        [int]$ExitCode,
        [object[]]$Output
    )

    try {
        $dataDir = Initialize-FoundationEngramEnvironment -RepoRoot $RepoRoot
        $fallback = Join-Path $dataDir 'fallback-memory.jsonl'
        $entry = @{
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            args = $Arguments
            exitCode = $ExitCode
            output = (@($Output) -join "`n")
        }
        $entry | ConvertTo-Json -Compress -Depth 8 | Out-File -FilePath $fallback -Append -Encoding UTF8
    }
    catch {
    }
}

function Invoke-FoundationEngram {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$RepoRoot = (Get-FoundationRepoRoot),
        [int]$MaxAttempts = 3
    )

    $engramBin = Resolve-FoundationEngramBinary -RepoRoot $RepoRoot
    if (-not $engramBin) {
        return [pscustomobject]@{
            Success = $false
            ExitCode = 127
            Output = @('Engram CLI not found')
            RawOutput = @('Engram CLI not found')
            DataDir = Initialize-FoundationEngramEnvironment -RepoRoot $RepoRoot
        }
    }

    $dataDir = Initialize-FoundationEngramEnvironment -RepoRoot $RepoRoot
    $mutex = [System.Threading.Mutex]::new($false, 'Global\FoundationEngramCli')
    $attempt = 0
    $rawOutput = @()
    $exitCode = 1

    try {
        while ($attempt -lt $MaxAttempts) {
            $attempt++
            $lockTaken = $false

            try {
                $lockTaken = $mutex.WaitOne([TimeSpan]::FromSeconds(20))
                if (-not $lockTaken) {
                    $rawOutput = @('Timed out waiting for Engram lock')
                    $exitCode = 124
                    continue
                }

                $rawOutput = @(& $engramBin @Arguments 2>&1)
                $exitCode = $LASTEXITCODE
            }
            finally {
                if ($lockTaken) {
                    $mutex.ReleaseMutex()
                }
            }

            $rawText = $rawOutput -join "`n"
            if ($exitCode -eq 0) {
                break
            }

            if ($rawText -notmatch 'database is locked|SQLITE_BUSY|database table is locked') {
                break
            }

            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }
    finally {
        $mutex.Dispose()
    }

    $cleanOutput = Remove-FoundationEngramNoise -Output $rawOutput
    if ($exitCode -ne 0) {
        Write-FoundationEngramFallback -RepoRoot $RepoRoot -Arguments $Arguments -ExitCode $exitCode -Output $cleanOutput
    }

    return [pscustomobject]@{
        Success = ($exitCode -eq 0)
        ExitCode = $exitCode
        Output = $cleanOutput
        RawOutput = $rawOutput
        DataDir = $dataDir
    }
}
