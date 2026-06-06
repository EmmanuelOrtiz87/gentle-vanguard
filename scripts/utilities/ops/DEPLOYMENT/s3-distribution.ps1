<#
.SYNOPSIS
    S3 distribution for Gentle-Vanguard releases
.DESCRIPTION
    Uploads releases and assets to S3 for global distribution.
    Supports CloudFront invalidation.
.PARAMETER Upload
    Upload current release
.PARAMETER Invalidate
    Invalidate CloudFront cache
.PARAMETER Version
    Version to upload
.EXAMPLE
    .\s3-distribution.ps1 -Upload -Version 2.30.0
#>
[CmdletBinding()]
param(
    [switch]$Upload,
    [switch]$Invalidate,
    [string]$Version = "",
    [string]$Bucket = "gentle-vanguard-releases",
    [string]$Region = "us-east-1",
    [string]$DistributionId = ""
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-AwsCli {
    try {
        aws --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Upload-ToS3 {
    param([string]$Ver)
    
    if (-not (Test-AwsCli)) {
        Write-Log "ERROR" "AWS CLI not found. Install: https://aws.amazon.com/cli/"
        exit 1
    }
    
    $releaseDir = Join-Path $PSScriptRoot "..\..\..\releases"
    $versionDir = Join-Path $releaseDir $Ver
    
    if (-not (Test-Path $versionDir)) {
        Write-Log "ERROR" "Release not found: $versionDir"
        exit 1
    }
    
    Write-Log "INFO" "Uploading release $Ver to S3..."
    
    # Upload with cache headers
    aws s3 sync $versionDir "s3://$Bucket/releases/$Ver/" `
        --region $Region `
        --cache-control "max-age=3600" `
        --metadata-directive REPLACE
    
    # Upload latest symlink
    aws s3 cp "s3://$Bucket/releases/$Ver/" "s3://$Bucket/releases/latest/" `
        --recursive --region $Region
    
    Write-Log "SUCCESS" "Upload complete: s3://$Bucket/releases/$Ver/"
}

function Invalidate-Cache {
    if (-not $DistributionId) {
        Write-Log "WARN" "No CloudFront DistributionId provided"
        return
    }
    
    Write-Log "INFO" "Invalidating CloudFront cache..."
    
    aws cloudfront create-invalidation `
        --distribution-id $DistributionId `
        --paths "/releases/*" "/latest/*" `
        --region $Region
    
    Write-Log "SUCCESS" "Cache invalidation created"
}

# Main
if ($Upload) {
    if (-not $Version) {
        $Version = (Get-Content (Join-Path $PSScriptRoot "..\..\..\VERSION") -Raw).Trim()
    }
    
    Upload-ToS3 -Ver $Version
    
    if ($Invalidate) {
        Invalidate-Cache
    }
}

if ($Invalidate -and -not $Upload) {
    Invalidate-Cache
}
