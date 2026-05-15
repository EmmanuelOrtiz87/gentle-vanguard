#!/usr/bin/env pwsh

Describe 'Engram Session Persistence Integration Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:sessionManager = Join-Path $script:root 'scripts\utilities\session-manager.ps1'
        $script:postSessionLearning = Join-Path $script:root 'scripts\utilities\post-session-learning.ps1'
        $script:engram = Join-Path $script:root 'tools\engram.exe'
        $env:ENGRAM_DATA_DIR = Join-Path $script:root '.engram-data'
        $env:ENGRAM_SKIP_UPDATE = '1'
        $script:runId = Get-Date -Format 'yyyyMMddHHmmss'
        $script:sessionDirRelative = '.\tmp-session-tests'
        $script:sessionDir = Join-Path $script:root 'tmp-session-tests'
        $script:autoStartDirRelative = '.\tmp-session-autostart-tests'
        $script:autoStartDir = Join-Path $script:root 'tmp-session-autostart-tests'
        $script:emptyDirRelative = '.\tmp-session-empty-tests'
        $script:emptyDir = Join-Path $script:root 'tmp-session-empty-tests'
        $script:learningSessionId = "engram-learning-$($script:runId)"

        if (Test-Path $script:sessionDir) {
            Remove-Item -Path $script:sessionDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:autoStartDir) {
            Remove-Item -Path $script:autoStartDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:emptyDir) {
            Remove-Item -Path $script:emptyDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $script:sessionDir -Force | Out-Null
        New-Item -ItemType Directory -Path $script:autoStartDir -Force | Out-Null
        New-Item -ItemType Directory -Path $script:emptyDir -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $script:sessionDir) {
            Remove-Item -Path $script:sessionDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:autoStartDir) {
            Remove-Item -Path $script:autoStartDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:emptyDir) {
            Remove-Item -Path $script:emptyDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Session Manager Persistence' {
        It 'handles empty session directories without throwing' {
            $null = & $script:sessionManager -Mode Health -SessionDir $script:emptyDirRelative -NoExit 2>&1
            $null = & $script:sessionManager -Mode Cleanup -SessionDir $script:emptyDirRelative -NoExit 2>&1
            (Get-ChildItem -Path $script:emptyDir -ErrorAction SilentlyContinue | Measure-Object).Count | Should Be 0
        }

        It 'supports AutoStart mode in an isolated session directory' {
            $null = & $script:sessionManager -Mode AutoStart -SessionDir $script:autoStartDirRelative -NoExit 2>&1
            $autoStartSession = Get-ChildItem -Path $script:autoStartDir -Filter 'session-*.json' | Select-Object -First 1
            $autoStartSession | Should Not BeNullOrEmpty
        }

        It 'persists session start in Engram and creates an active session file' {
            Test-Path $script:engram | Should Be $true

            $output = & $script:sessionManager -Mode Manual -SessionDir $script:sessionDirRelative -NoExit 2>&1
            $sessionFile = Get-ChildItem -Path $script:sessionDir -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $sessionFile | Should Not BeNullOrEmpty

            $sessionData = Get-Content -Path $sessionFile.FullName -Raw | ConvertFrom-Json
            $sessionData.status | Should Be 'active'

            $searchOutput = & $script:engram search "Session start: $($sessionData.sessionId)" --project foundation --limit 5 2>&1 | Out-String
            ($searchOutput -match [regex]::Escape($sessionData.sessionId)) | Should Be $true
        }

        It 'reports health and cleans orphaned plus corrupt sessions in isolated directory' {
            $orphanPath = Join-Path $script:sessionDir 'session-2000-01-01-01.json'
            $orphanData = @{
                sessionId = 'session-2000-01-01-01'
                project = 'foundation'
                mode = 'Manual'
                startTime = '2000-01-01T00:00:00Z'
                status = 'active'
                version = '2.0'
            }
            $orphanData | ConvertTo-Json | Set-Content -Path $orphanPath -Encoding UTF8

            $corruptPath = Join-Path $script:sessionDir 'session-corrupt.json'
            '{invalid-json' | Set-Content -Path $corruptPath -Encoding UTF8

            $null = & $script:sessionManager -Mode Health -SessionDir $script:sessionDirRelative -NoExit 2>&1

            $null = & $script:sessionManager -Mode Cleanup -SessionDir $script:sessionDirRelative -OrphanMaxAgeHours 1 -NoExit 2>&1
            Test-Path (Join-Path $script:sessionDir 'archive\session-corrupt.json') | Should Be $true

            $updatedOrphan = Get-Content -Path $orphanPath -Raw | ConvertFrom-Json
            $updatedOrphan.status | Should Be 'orphaned'
        }

        It 'persists session closure in Engram when ending the latest session' {
            $activeSession = Get-ChildItem -Path $script:sessionDir -Filter 'session-*.json' |
                Where-Object {
                    try {
                        (Get-Content -Path $_.FullName -Raw | ConvertFrom-Json).status -eq 'active'
                    }
                    catch {
                        $false
                    }
                } |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
            $activeSession | Should Not BeNullOrEmpty
            $activeSessionData = Get-Content -Path $activeSession.FullName -Raw | ConvertFrom-Json

            $output = & $script:sessionManager -Mode End -SessionDir $script:sessionDirRelative -SkipPreCloseValidation -NoExit 2>&1
            $endedSessionData = Get-Content -Path $activeSession.FullName -Raw | ConvertFrom-Json
            $endedSessionData.status | Should Be 'ended'

            $searchOutput = & $script:engram search "Session closure: $($activeSessionData.sessionId)" --project foundation --limit 5 2>&1 | Out-String
            ($searchOutput -match [regex]::Escape($activeSessionData.sessionId)) | Should Be $true
        }
    }

    Context 'Post-session Learning Persistence' {
        It 'persists a searchable learning summary in Engram' {
            $output = & $script:postSessionLearning -SessionId $script:learningSessionId -NoExit 2>&1
            $searchOutput = & $script:engram search $script:learningSessionId --project foundation --limit 5 2>&1 | Out-String
            ($searchOutput -match [regex]::Escape($script:learningSessionId)) | Should Be $true
        }
    }
}
