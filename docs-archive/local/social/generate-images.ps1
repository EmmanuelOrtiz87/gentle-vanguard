<#
.SYNOPSIS
    Generate social media images for Gentle-Vanguard
.DESCRIPTION
    Creates PNG images for Twitter, LinkedIn, Reddit, Discord, WhatsApp
    Uses .NET System.Drawing for image generation
#>

param(
    [ValidateSet("all", "twitter", "linkedin", "reddit", "discord", "whatsapp")]
    [string]$Platform = "all",
    [string]$OutputDir = ".local/social/images"
)

$ErrorActionPreference = 'Continue'

# Colors
$DarkBg = "#1a1a2e"
$AccentCyan = "#00d4ff"
$AccentPurple = "#7b2cbf"
$TextWhite = "#ffffff"
$TextGray = "#a0a0a0"

function New-SocialImage {
    param(
        [int]$Width,
        [int]$Height,
        [string]$Title,
        [string]$Subtitle,
        [string]$Hashtag,
        [string]$OutputPath
    )
    
    Add-Type -AssemblyName System.Drawing
    
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Background gradient (simplified)
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml($DarkBg))
    
    # Title font
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 36, [System.Drawing.FontStyle]::Bold)
    $subtitleFont = New-Object System.Drawing.Font("Segoe UI", 18)
    $hashtagFont = New-Object System.Drawing.Font("Segoe UI", 14)
    
    # Title
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($AccentCyan))
    $titleRect = New-Object System.Drawing.RectangleF(40, 40, $Width - 80, 60)
    $graphics.DrawString($Title, $titleFont, $titleBrush, $titleRect)
    
    # Subtitle
    $subtitleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $subtitleRect = New-Object System.Drawing.RectangleF(40, 110, $Width - 80, 40)
    $graphics.DrawString($Subtitle, $subtitleFont, $subtitleBrush, $subtitleRect)
    
    # Hashtag
    $hashtagBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($TextGray))
    $hashtagRect = New-Object System.Drawing.RectangleF(40, $Height - 50, $Width - 80, 30)
    $graphics.DrawString($Hashtag, $hashtagFont, $hashtagBrush, $hashtagRect)
    
    # Decorative line
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($AccentPurple), 3)
    $graphics.DrawLine($pen, 40, 170, $Width - 40, 170)
    
    # Save
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Cleanup
    $graphics.Dispose()
    $bitmap.Dispose()
    
    Write-Host "[OK] Created: $OutputPath" -ForegroundColor Green
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Twitter/X (1200x675 - 16:9)
if ($Platform -eq "all" -or $Platform -eq "twitter") {
    New-SocialImage -Width 1200 -Height 675 `
        -Title "Gentle-Vanguard v2.0" `
        -Subtitle "AI Development Stack" `
        -Hashtag "#Gentle-VanguardStack #AI #DevTools" `
        -OutputPath "$OutputDir/twitter-announce.png"
}

# LinkedIn (1200x627 - 1.91:1)
if ($Platform -eq "all" -or $Platform -eq "linkedin") {
    New-SocialImage -Width 1200 -Height 627 `
        -Title "Introducing Gentle-Vanguard v2.0" `
        -Subtitle "Auto-delegation + Persistent Memory + 7D Validation" `
        -Hashtag "#AIDevelopment #SoftwareEngineering" `
        -OutputPath "$OutputDir/linkedin-announce.png"
}

# Reddit (1200x1200 - square)
if ($Platform -eq "all" -or $Platform -eq "reddit") {
    New-SocialImage -Width 1200 -Height 1200 `
        -Title "Gentle-Vanguard" `
        -Subtitle "AI Development Stack v2.0" `
        -Hashtag "#github #programming" `
        -OutputPath "$OutputDir/reddit-show.png"
}

# Discord (800x400)
if ($Platform -eq "all" -or $Platform -eq "discord") {
    New-SocialImage -Width 800 -Height 400 `
        -Title "Gentle-Vanguard v2.0" `
        -Subtitle "Now Available" `
        -Hashtag "#Gentle-VanguardStack" `
        -OutputPath "$OutputDir/discord-announce.png"
}

# WhatsApp (800x800 - square)
if ($Platform -eq "all" -or $Platform -eq "whatsapp") {
    New-SocialImage -Width 800 -Height 800 `
        -Title "Gentle-Vanguard v2.0" `
        -Subtitle "AI Development Stack" `
        -Hashtag "#Gentle-VanguardStack" `
        -OutputPath "$OutputDir/whatsapp-announce.png"
}

Write-Host ""
Write-Host "Images created in: $OutputDir" -ForegroundColor Cyan
