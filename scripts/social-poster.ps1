#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Gentle-Vanguard Social Media Poster Automation
    
.DESCRIPTION
    Automates posting to multiple social media platforms with templates,
    scheduling, and analytics tracking.
    
.EXAMPLE
    ./social-poster.ps1 -Platform LinkedIn -Template launch
    ./social-poster.ps1 -Platform All -ContentFile post.md -Schedule 9:00
    
.NOTES
    Version: 1.0
    Part of Gentle-Vanguard Marketing Suite
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('LinkedIn', 'Twitter', 'GitHub', 'ProductHunt', 'DevTo', 'All')]
    [string]$Platform,
    
    [Parameter()]
    [ValidateSet('launch', 'feature', 'migration', 'tutorial', 'case-study')]
    [string]$Template,
    
    [Parameter()]
    [string]$ContentFile,
    
    [Parameter()]
    [string]$Schedule,
    
    [Parameter()]
    [switch]$DryRun
)

# Configuration
$Config = @{
    PostDirectory = ".session/social-posts"
    TemplatesDirectory = "docs/presentations/social-templates"
    AnalyticsFile = ".session/social-analytics.json"
    
    # Platform specific settings
    Platforms = @{
        LinkedIn = @{
            MaxLength = 3000
            Hashtags = 5
            ImageRecommended = $true
            BestTimes = @("8:00", "12:00", "17:00")
        }
        Twitter = @{
            MaxLength = 280
            Hashtags = 3
            Threads = $true
            BestTimes = @("9:00", "15:00", "19:00")
        }
        GitHub = @{
            MaxLength = 5000
            Format = "Markdown"
            BestTimes = @("14:00", "16:00")
        }
        ProductHunt = @{
            RequiresImages = $true
            Format = "Structured"
            BestTimes = @("00:01", "8:00")
        }
        DevTo = @{
            MaxLength = 25000
            Format = "Markdown"
            BestTimes = @("9:00", "14:00")
        }
    }
    
    # Common hashtags by category
    Hashtags = @{
        AI = @("#AI", "#MachineLearning", "#ArtificialIntelligence", "#GenAI")
        Dev = @("#DevTools", "#Developer", "#Coding", "#Programming")
        Tech = @("#Tech", "#Technology", "#Innovation", "#Future")
        Product = @("#ProductHunt", "#Startup", "#SaaS", "#OpenSource")
        GentleVanguard = @("#GentleVanguard", "#AutonomousAI", "#FutureOfCoding")
    }
}

# Initialize directories
function Initialize-Environment {
    $directories = @($Config.PostDirectory, $Config.TemplatesDirectory, ".session")
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Verbose "Created directory: $dir"
        }
    }
    
    # Initialize analytics file
    if (!(Test-Path $Config.AnalyticsFile)) {
        @{ Posts = @(); LastRun = $null } | ConvertTo-Json | Set-Content $Config.AnalyticsFile
    }
}

# Template functions
function Get-Template {
    param([string]$Name)
    
    $templates = @{
        launch = @{
            LinkedIn = @"
🚀 Introducing Gentle-Vanguard v4.0 — The first 100% Autonomous AI Stack

After 24 migration waves and 390+ scripts refactored to TypeScript, I'm excited to share what we've built:

✅ 21 synchronized AI agents working in harmony
✅ Self-healing, self-learning, self-evolving architecture  
✅ Works with OpenCode, Claude, Cursor, Copilot, and more
✅ Zero external dependencies — everything native TypeScript

The future of development is autonomous. The stack literally improves itself through 82 health checks, circuit breakers, and an executive loop that never stops.

You can use it free today. The code is open source.

What would you build with 10× developer productivity?

#AI #DevTools #Automation #OpenSource #Startup

@GentleVanguard
"@
            Twitter = @"
🚀 Gentle-Vanguard v4.0 is live!

The first 100% Autonomous AI Stack:
• 21 AI agents working together
• Self-healing architecture
• Native TypeScript — zero deps
• 10× developer productivity

Free & open source.

What would you build?

#AI #DevTools #OpenSource
"@
            GitHub = @"
## 🚀 Gentle-Vanguard v4.0

The first **100% Autonomous AI Stack** — self-healing, self-learning, and self-evolving.

### What makes it different?

- **21 Specialized Agents**: From BA exploration to QA verification
- **Native TypeScript**: 390+ scripts migrated, zero external dependencies  
- **Adaptive Intelligence**: 53-step pipeline that auto-optimizes
- **Enterprise Security**: Circuit breakers, audit trails, hash-chained events

### Core Features

✅ Circuit Breaker pattern (CLOSED/OPEN/HALF_OPEN)
✅ Auto-Apply Safe with rollback
✅ Real token tracking (agnostic)
✅ Dual-provider web crawler
✅ 103 test files, 82 health checks

### Quick Start

```bash
git clone https://github.com/emmanuelortiz/gentle-vanguard.git
cd gentle-vanguard
npm install
npm run session:autostart
```

### Product Ecosystem

- **Gentle-Music**: AI music streaming ($4.99/mo)
- **Doc-Gentle**: Document intelligence ($15/mo)
- **Stock-Vanguard**: Argentine stock & billing ($29/mo)

[Documentation](https://emmanuelortiz.github.io/gentle-vanguard) | [v4.0 Features](docs/presentations/v4-features.html)

---

⭐ If you find this helpful, please star the repo!

#opensource #ai #typescript #automation
"@
        }
        
        feature = @{
            LinkedIn = @"
💡 New in Gentle-Vanguard v4.0: Adaptive Steps System

Tired of AI agents running out of steps mid-task? We fixed that.

The Adaptive Steps System intelligently assigns 24-80 steps based on task complexity:

🔍 Exploratory tasks (BA): 38 steps
🏗️ Design tasks (SAD): 30 steps  
📝 Implementation (DEV): 52 steps
✅ Verification (QA): 36 steps

The system learns from historical executions and auto-adjusts. No more "maximum steps reached" failures.

This is what 100% autonomous operation looks like. The stack manages itself.

#AI #DevTools #Innovation #AdaptiveIntelligence
"@
        }
        
        migration = @{
            LinkedIn = @"
📝 24 Migration Waves Later: From PowerShell to TypeScript

We've completed the migration of 390+ scripts from PowerShell to native TypeScript.

Why? Three reasons:

1. **Performance**: 5× faster execution with Promise.allSettled parallel processing
2. **Type Safety**: Compile-time verification catches errors before runtime
3. **Ecosystem**: Native access to npm packages without wrappers

The stack is now 100% TypeScript. Every health check, every pipeline step, every agent.

And it's fully backward compatible. Your existing configs work unchanged.

#TypeScript #Refactoring #Performance #CodeQuality
"@
        }
    }
    
    if ($templates[$Name]) {
        return $templates[$Name]
    }
    
    return $null
}

# Platform posting functions
function Publish-LinkedIn {
    param([string]$content)
    
    Write-Host "Publishing to LinkedIn..." -ForegroundColor Blue
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Content would be posted to LinkedIn:" -ForegroundColor Cyan
        Write-Host $content -ForegroundColor Gray
        return @{ Success = $true; PostId = "dry-run-12345" }
    }
    
    # LinkedIn API integration would go here
    # For now, output to file for manual posting
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "$Config.PostDirectory/linkedin-$timestamp.md"
    $content | Set-Content $filename
    
    Write-Host "Content saved to: $filename" -ForegroundColor Green
    Write-Host "Manual posting required - LinkedIn API requires OAuth setup" -ForegroundColor Yellow
    
    return @{ Success = $true; FilePath = $filename }
}

function Publish-Twitter {
    param([string]$content)
    
    Write-Host "Publishing to Twitter..." -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Content ready for Twitter:" -ForegroundColor Cyan
        Write-Host $content -ForegroundColor Gray
        return @{ Success = $true }
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "$Config.PostDirectory/twitter-$timestamp.txt"
    $content | Set-Content $filename
    
    Write-Host "Content saved to: $filename" -ForegroundColor Green
    Write-Host "Manual posting required - Twitter API requires setup" -ForegroundColor Yellow
    
    return @{ Success = $true; FilePath = $filename }
}

function Publish-GitHub {
    param([string]$content)
    
    Write-Host "Publishing to GitHub Discussions..." -ForegroundColor White
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Content for GitHub:" -ForegroundColor Cyan
        Write-Host $content -ForegroundColor Gray
        return @{ Success = $true }
    }
    
    # Could use gh CLI if available
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "$Config.PostDirectory/github-$timestamp.md"
    $content | Set-Content $filename
    
    Write-Host "Content saved to: $filename" -ForegroundColor Green
    
    return @{ Success = $true; FilePath = $filename }
}

# Analytics tracking
function Save-Analytics {
    param(
        [string]$Platform,
        [string]$Content,
        [string]$PostUrl = $null,
        [bool]$Success = $false
    )
    
    $analytics = Get-Content $Config.AnalyticsFile | ConvertFrom-Json
    
    $entry = @{
        Timestamp = (Get-Date -Format "o")
        Platform = $Platform
        Content = $Content.Substring(0, [Math]::Min(100, $Content.Length))
        PostUrl = $PostUrl
        Success = $Success
    }
    
    $analytics.Posts += $entry
    $analytics.LastRun = Get-Date -Format "o"
    
    $analytics | ConvertTo-Json -Depth 10 | Set-Content $Config.AnalyticsFile
    
    Write-Verbose "Analytics saved"
}

# Main execution
function Main {
    Write-Host "=== Gentle-Vanguard Social Poster v1.0 ===" -ForegroundColor Green
    Write-Host ""
    
    Initialize-Environment
    
    if ($Template) {
        $template = Get-Template -Name $Template
        if (!$template) {
            Write-Error "Template '$Template' not found"
            return
        }
    }
    
    if ($ContentFile) {
        if (!(Test-Path $ContentFile)) {
            Write-Error "Content file not found: $ContentFile"
            return
        }
        $content = Get-Content $ContentFile -Raw
    }
    
    # If using template, get platform-specific content
    if ($Template) {
        $platformsToPost = if ($Platform -eq 'All') { @('LinkedIn', 'Twitter', 'GitHub') } else { @($Platform) }
        
        foreach ($p in $platformsToPost) {
            if ($template[$p]) {
                $content = $template[$p]
                
                switch ($p) {
                    'LinkedIn' { Publish-LinkedIn -content $content }
                    'Twitter' { Publish-Twitter -content $content }
                    'GitHub' { Publish-GitHub -content $content }
                }
                
                Save-Analytics -Platform $p -Content $content -Success $true
            }
            else {
                Write-Warning "No template for platform: $p"
            }
        }
    }
    else {
        # Direct content posting
        switch ($Platform) {
            'LinkedIn' { Publish-LinkedIn -content $content }
            'Twitter' { Publish-Twitter -content $content }
            'GitHub' { Publish-GitHub -content $content }
            default { Write-Warning "Direct posting to $Platform not implemented" }
        }
    }
    
    Write-Host ""
    Write-Host "=== Posting complete ===" -ForegroundColor Green
}

# Execute
. Main
