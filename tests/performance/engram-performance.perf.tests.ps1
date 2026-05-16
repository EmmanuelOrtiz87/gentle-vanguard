#!/usr/bin/env pwsh

$script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$script:engram = Join-Path $script:root 'tools\engram.exe'
$env:ENGRAM_DATA_DIR = Join-Path $script:root '.engram-data'
$env:ENGRAM_SKIP_UPDATE = '1'

Describe "Engram Performance Tests" {

    Context "Search Latency" {
        It "engram search completes under 1000ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $null = & $script:engram search "Session start:" --project foundation --limit 5 2>&1
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should BeLessThan 1000
        }
    }

    Context "Stats Latency" {
        It "engram stats completes under 1000ms for foundation project" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $null = & $script:engram stats --project foundation 2>&1
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should BeLessThan 1000
        }
    }

    Context "Doctor Latency" {
        It "engram doctor --json completes under 1000ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $null = & $script:engram doctor --json 2>&1
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should BeLessThan 1000
        }
    }

    Context "Consecutive Query Performance" {
        It "3 consecutive searches complete within 2000ms total" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $null = & $script:engram search "session" --project foundation --limit 3 2>&1
            $null = & $script:engram search "test" --project foundation --limit 3 2>&1
            $null = & $script:engram search "config" --project foundation --limit 3 2>&1
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should BeLessThan 2000
        }
    }
}
