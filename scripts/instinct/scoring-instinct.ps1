#!/usr/bin/env pwsh
<#
.SYNOPSIS
  ECC-inspired instinct scoring for Engram observations
.DESCRIPTION
  Enriches mem_save observations with confidence, evidence_trail, domain_tags,
  and project_scope metadata. Accepts pipeline or parameter input.
.PARAMETER Observation
  Hashtable with instinct data fields
.PARAMETER Confidence
  Confidence level: 0.3 (tentative), 0.6 (plausible), 0.9 (near-certain)
.PARAMETER EvidenceTrail
  Array of file/command/observation citations
.PARAMETER DomainTags
  Array of domain tags (optimization, security, architecture, pattern, config, bugfix)
.PARAMETER ProjectScope
  Scope: project (default) or global
.PARAMETER Validate
  Switch to validate schema without producing output
.EXAMPLE
  @{Title="test"; Confidence=0.6; EvidenceTrail=@("src/main.ps1"); DomainTags=@("bugfix")} | ./scoring-instinct.ps1
.EXAMPLE
  ./scoring-instinct.ps1 -Confidence 0.9 -EvidenceTrail "config/routing.json","docs/ARCH.md" -DomainTags "architecture","pattern" -ProjectScope project
#>

param(
  [Parameter(ValueFromPipeline = $true, DontShow = $true)]
  [hashtable]$Observation,

  [ValidateScript({ $_ -ge 0.01 -and $_ -le 1.0 })]
  [double]$Confidence,

  [string[]]$EvidenceTrail,

  [ValidateSet("optimization", "security", "architecture", "pattern", "config", "bugfix")]
  [string[]]$DomainTags,

  [ValidateSet("project", "global")]
  [string]$ProjectScope = "project",

  [switch]$Validate
)

begin {
  $results = @()
  $validationErrors = @()
}

process {
  $item = $Observation ?? @{}

  if ($Confidence) { $item.Confidence = $Confidence }
  if ($EvidenceTrail) { $item.EvidenceTrail = $EvidenceTrail }
  if ($DomainTags) { $item.DomainTags = $DomainTags }
  if ($ProjectScope) { $item.ProjectScope = $ProjectScope }

  $errors = @()

  if ($null -eq $item.Confidence -or -not ($item.Confidence -ge 0.01 -and $item.Confidence -le 1.0)) {
    $errors += "Confidence must be between 0.01 and 1.0"
  }
  if ($null -eq $item.EvidenceTrail -or $item.EvidenceTrail.Count -eq 0) {
    $errors += "EvidenceTrail must contain at least one citation"
  }
  if ($null -eq $item.DomainTags -or $item.DomainTags.Count -eq 0) {
    $errors += "DomainTags must contain at least one tag"
  }

  if ($errors.Count -gt 0) {
    $validationErrors += @{ Input = $item; Errors = $errors }
    return
  }

  $confidenceLabel = switch ($item.Confidence) {
    { $_ -le 0.4 } { "tentative"; break }
    { $_ -le 0.8 } { "plausible"; break }
    default { "near-certain" }
  }

  $output = @{
    Confidence = [math]::Round($item.Confidence, 2)
    ConfidenceLabel = $confidenceLabel
    EvidenceTrail = $item.EvidenceTrail
    DomainTags = $item.DomainTags
    ProjectScope = $item.ProjectScope
    EngramReady = $true
    GeneratedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
  }

  $results += $output
}

end {
  if ($Validate) {
    if ($validationErrors.Count -gt 0) {
      Write-Output ($validationErrors | ConvertTo-Json -Depth 3)
      exit 1
    }
    Write-Output "[]"
    exit 0
  }

  if ($results.Count -eq 0 -and $validationErrors.Count -eq 0) {
    Write-Output "No input provided"
    return
  }

  if ($validationErrors.Count -gt 0) {
    Write-Error ($validationErrors | ConvertTo-Json -Depth 3)
    exit 1
  }

  if ($results.Count -eq 1) {
    Write-Output ($results[0] | ConvertTo-Json -Depth 3)
  } else {
    Write-Output ($results | ConvertTo-Json -Depth 3)
  }
}
