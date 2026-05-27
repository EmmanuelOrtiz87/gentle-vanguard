#!/usr/bin/env pwsh
# normativa-resolver.ps1
# Lazy loader for normativas - loads only when referenced
# Prevents system prompt bloat by loading rules on-demand

param(
    [Parameter(Mandatory=$true)]
    [string]$Reference,
    
    [string]$WorkspaceRoot = ".",
    
    [switch]$AsSummary,
    
    [switch]$CacheResult
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CACHE SETUP
# ============================================================================
$cacheDir = Join-Path $WorkspaceRoot ".session/normativa-cache"
$indexFile = Join-Path $cacheDir "normativa-index.json"

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
}

# ============================================================================
# PARSE REFERENCE
# ============================================================================
function Parse-Reference {
    param([string]$Ref)
    
    # Format: "rules/NORMATIVAS-CODIGO.md#section-name" or "rules/NORMATIVAS-CODIGO.md"
    if ($Ref -match '^(.+\.md)(?:#(.+))?$') {
        return @{
            File = $Matches[1]
            Section = $Matches[2]
            FullPath = Join-Path $WorkspaceRoot $Matches[1]
        }
    }
    
    throw "Invalid reference format: $Ref. Expected: 'path/file.md#section' or 'path/file.md'"
}

# ============================================================================
# LOAD AND CACHE INDEX
# ============================================================================
function Get-NormativaIndex {
    if (Test-Path $indexFile) {
        try {
            return Get-Content $indexFile -Raw | ConvertFrom-Json
        } catch {}
    }
    
    # Build index from scratch
    $index = @{}
    $normFiles = Get-ChildItem -Path (Join-Path $WorkspaceRoot "rules") -Filter "NORMATIVAS-*.md"
    
    foreach ($file in $normFiles) {
        $content = Get-Content $file.FullName -Raw
        $sections = @()
        
        # Extract section headers
        $matches = [regex]::Matches($content, '^## (.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $matches) {
            $sections += $match.Groups[1].Value.Trim()
        }
        
        $relPath = "rules/$($file.Name)"
        $index[$relPath] = @{
            LastModified = $file.LastWriteTimeUtc.ToString("o")
            Sections = $sections
            Size = $content.Length
            LineCount = ($content -split "`n").Count
        }
    }
    
    # Save index
    $index | ConvertTo-Json -Depth 3 | Set-Content $indexFile
    
    return $index
}

# ============================================================================
# EXTRACT SECTION
# ============================================================================
function Get-SectionContent {
    param(
        [string]$Content,
        [string]$SectionName
    )
    
    if (-not $SectionName) {
        return $Content
    }
    
    # Find section header
    $escapedSection = [regex]::Escape($SectionName)
    $pattern = "(?s)^##\s+$escapedSection\s*\r?\n(.*?)(?=^## |\z)"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    
    return $null
}

# ============================================================================
# GENERATE SUMMARY
# ============================================================================
function Get-ContentSummary {
    param([string]$Content)
    
    $lines = $Content -split "`n"
    $summaryLines = @()
    $inCodeBlock = $false
    
    foreach ($line in $lines) {
        # Skip code blocks in summary
        if ($line -match '^```') {
            $inCodeBlock = -not $inCodeBlock
            continue
        }
        
        if ($inCodeBlock) { continue }
        
        # Keep headers and key points
        if ($line -match '^(#{1,3} |\* |\d+\. |MUST|SHOULD|MAY|NOTE|WARNING)') {
            $summaryLines += $line
        }
    }
    
    return ($summaryLines -join "`n").Substring(0, [Math]::Min(2000, ($summaryLines -join "`n").Length))
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

$parsed = Parse-Reference -Ref $Reference
$index = Get-NormativaIndex

# Check if file exists
if (-not (Test-Path $parsed.FullPath)) {
    throw "Normativa file not found: $($parsed.FullPath)"
}

# Check cache
$cacheKey = ($Reference -replace '[^a-zA-Z0-9]', '_') + ".txt"
$cachePath = Join-Path $cacheDir $cacheKey

if ($CacheResult -and (Test-Path $cachePath)) {
    $cached = Get-Content $cachePath -Raw
    return $cached
}

# Load content
$content = Get-Content $parsed.FullPath -Raw

# Extract section if specified
if ($parsed.Section) {
    $content = Get-SectionContent -Content $content -SectionName $parsed.Section
    if (-not $content) {
        throw "Section '$($parsed.Section)' not found in $($parsed.File)"
    }
}

# Generate summary if requested
if ($AsSummary) {
    $content = Get-ContentSummary -Content $content
    $content = "[SUMMARY: $Reference]`n$content"
}

# Add reference header
$content = "[REF: $Reference]`n$content"

# Cache if requested
if ($CacheResult) {
    $content | Set-Content $cachePath
}

return $content
