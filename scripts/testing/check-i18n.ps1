param(
    [Parameter(Mandatory = $false)]
    [string]$LocalesDir = "locales",

    [Parameter(Mandatory = $false)]
    [string]$SourceLocale = "en-US",

    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$FailOnMissing
)

function Get-LocaleFiles {
    param([string]$Dir)

    if (-not (Test-Path $Dir)) {
        return @()
    }

    $files = Get-ChildItem -Path $Dir -Recurse -Filter "*.json" -File

    $locales = @{}
    foreach ($file in $files) {
        $localeDir = $file.Directory.Name
        $namespace = $file.BaseName

        if (-not $locales[$localeDir]) {
            $locales[$localeDir] = @()
        }
        $locales[$localeDir] += @{
            Path = $file.FullName
            Name = $namespace
            Size = $file.Length
        }
    }

    return $locales
}

function Get-KeysFromJson {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) { return @() }

    try {
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json
        $keys = @()
        $queue = New-Object System.Collections.Queue
        $queue.Enqueue(@("", $content))

        while ($queue.Count -gt 0) {
            $item = $queue.Dequeue()
            $prefix = $item[0]
            $obj = $item[1]

            if ($obj -is [PSCustomObject]) {
                foreach ($prop in $obj.PSObject.Properties) {
                    $key = if ($prefix) { "$prefix.$($prop.Name)" } else { $prop.Name }
                    if ($prop.Value -is [PSCustomObject] -or $prop.Value -is [hashtable]) {
                        $queue.Enqueue(@($key, $prop.Value))
                    }
                    else {
                        $keys += $key
                    }
                }
            }
        }

        return $keys
    }
    catch {
        Write-Warning "Could not parse JSON: $FilePath - $_"
        return @()
    }
}

try {
    $locales = Get-LocaleFiles -Dir $LocalesDir

    if ($locales.Keys.Count -eq 0) {
        Write-Host "[I18N] No locale files found in '$LocalesDir'. Skipping." -ForegroundColor Yellow
        if ($Json) { return '{"status":"skipped","message":"No locale files found"}' }
        exit 0
    }

    Write-Host "[I18N] Found $($locales.Keys.Count) locale(s): $($locales.Keys -join ', ')" -ForegroundColor Cyan

    $sourceFiles = $locales[$SourceLocale]
    if (-not $sourceFiles) {
        Write-Error "Source locale '$SourceLocale' not found in $LocalesDir"
        exit 1
    }

    $sourceKeys = @{}
    foreach ($file in $sourceFiles) {
        $keys = Get-KeysFromJson -FilePath $file.Path
        $sourceKeys[$file.Name] = $keys
    }

    $missingSummary = @()

    foreach ($locale in $locales.Keys) {
        if ($locale -eq $SourceLocale) { continue }

        Write-Host "[I18N] Checking locale: $locale" -ForegroundColor Cyan

        foreach ($sourceFile in $sourceFiles) {
            $targetFile = $locales[$locale] | Where-Object { $_.Name -eq $sourceFile.Name }
            $targetPath = if ($targetFile) { $targetFile.Path } else { $null }

            $targetFileKeys = if ($targetPath) { Get-KeysFromJson -FilePath $targetPath } else { @() }
            $sourceFileKeys = $sourceKeys[$sourceFile.Name]

            $missing = $sourceFileKeys | Where-Object { $_ -notin $targetFileKeys }
            $extra = $targetFileKeys | Where-Object { $_ -notin $sourceFileKeys }

            if ($missing.Count -gt 0) {
                Write-Warning "[I18N] $locale/$($sourceFile.Name): $($missing.Count) missing key(s)"
                foreach ($k in $missing) { Write-Host "  MISSING: $k" -ForegroundColor Yellow }
                $missingSummary += @{
                    Locale = $locale
                    Namespace = $sourceFile.Name
                    MissingCount = $missing.Count
                    MissingKeys = $missing
                }
            }

            if ($extra.Count -gt 0) {
                Write-Host "[I18N] $locale/$($sourceFile.Name): $($extra.Count) extra key(s) (orphaned)" -ForegroundColor Gray
            }
        }
    }

    if ($Json) {
        return @{
            status = if ($missingSummary.Count -eq 0) { "PASS" } else { "FAIL" }
            localesChecked = $locales.Keys.Count - 1
            missingEntries = $missingSummary.Count
            details = $missingSummary
        } | ConvertTo-Json -Depth 5
    }

    if ($missingSummary.Count -gt 0) {
        Write-Host "[I18N] Summary: $($missingSummary.Count) locale(s) with missing keys" -ForegroundColor Yellow
        if ($FailOnMissing) {
            Write-Error "i18n check FAILED: $($missingSummary.Count) locale(s) have missing keys"
            exit 1
        }
    }
    else {
        Write-Host "[I18N] All locales are complete. No missing keys." -ForegroundColor Green
    }
}
catch {
    Write-Error "check-i18n.ps1 failed: $_"
    exit 1
}
