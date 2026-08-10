#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Gentle-Vanguard Presentations to Vercel/Netlify
.DESCRIPTION
    Automates deployment process with validation steps
.EXAMPLE
    ./deploy-presentations.ps1 -Platform vercel
    ./deploy-presentations.ps1 -Platform netlify -Preview
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('vercel', 'netlify')]
    [string]$Platform,
    
    [Parameter()]
    [switch]$Preview,
    
    [Parameter()]
    [string]$Domain
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Gentle-Vanguard Deploy Tool" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Validation steps
function Test-Prerequisites {
    Write-Host "🔍 Running validations..." -ForegroundColor Yellow
    
    # Check if in correct directory
    if (-not (Test-Path "docs/presentations")) {
        Write-Error "❌ Must run from project root"
        exit 1
    }
    
    # Check required files
    $requiredFiles = @(
        "docs/presentations/index.html",
        "docs/presentations/marketing.html",
        "docs/presentations/v4-features.html",
        "docs/presentations/resources-index.html"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Warning "⚠️ Missing file: $file"
        }
    }
    
    # Check for broken links
    Write-Host "  Checking links..." -ForegroundColor Gray
    $htmlFiles = Get-ChildItem "docs/presentations" -Filter "*.html" -Recurse
    $brokenLinks = @()
    
    foreach ($file in $htmlFiles) {
        $content = Get-Content $file.FullName -Raw
        $links = [regex]::Matches($content, 'href="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        
        foreach ($link in $links) {
            if ($link -match '^[^http]') {
                $targetPath = Join-Path $file.DirectoryName $link
                if (-not (Test-Path $targetPath) -and $link -notmatch '^#') {
                    $brokenLinks += "$($file.Name) -> $link"
                }
            }
        }
    }
    
    if ($brokenLinks.Count -gt 0) {
        Write-Warning "⚠️ Broken links found:"
        $brokenLinks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    } else {
        Write-Host "  ✅ All links validated" -ForegroundColor Green
    }
    
    Write-Host ""
}

function Deploy-Vercel {
    Write-Host "☁️ Deploying to Vercel..." -ForegroundColor Cyan
    
    if (-not (Get-Command "vercel" -ErrorAction SilentlyContinue)) {
        Write-Error "❌ Vercel CLI not installed. Run: npm i -g vercel"
        exit 1
    }
    
    if ($Preview) {
        Write-Host "  Creating preview deployment..." -ForegroundColor Gray
        vercel --cwd docs/presentations
    } else {
        Write-Host "  Deploying to production..." -ForegroundColor Gray
        vercel --cwd docs/presentations --prod
    }
    
    if ($Domain) {
        Write-Host "  Assigning domain: $Domain" -ForegroundColor Gray
        vercel domains add $Domain
    }
}

function Deploy-Netlify {
    Write-Host "☁️ Deploying to Netlify..." -ForegroundColor Cyan
    
    if (-not (Get-Command "netlify" -ErrorAction SilentlyContinue)) {
        Write-Error "❌ Netlify CLI not installed. Run: npm i -g netlify-cli"
        exit 1
    }
    
    if ($Preview) {
        Write-Host "  Creating draft deployment..." -ForegroundColor Gray
        netlify deploy --dir=docs/presentations
    } else {
        Write-Host "  Deploying to production..." -ForegroundColor Gray
        netlify deploy --dir=docs/presentations --prod
    }
}

# Main
Test-Prerequisites

switch ($Platform) {
    "vercel" { Deploy-Vercel }
    "netlify" { Deploy-Netlify }
}

Write-Host ""
Write-Host "✅ Deploy complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Visit the deployment URL" -ForegroundColor Gray
Write-Host "  2. Test all pages and links" -ForegroundColor Gray
Write-Host "  3. Configure custom domain if needed" -ForegroundColor Gray
Write-Host ""
