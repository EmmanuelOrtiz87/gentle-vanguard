#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Platform Helpers - Cross-Platform Compatibility Functions
    
.DESCRIPTION
    Provides cross-platform compatibility functions for Windows, Linux, and macOS
    
.NOTES
    Version: 1.0.0
    Supports: PowerShell 7+
#>

# Platform Detection
function Get-OSType {
    <#
    .SYNOPSIS
        Detects the current operating system
        
    .OUTPUTS
        [string] - "Windows", "Linux", "macOS", or "Unknown"
    #>
    
    if ($PSVersionTable.Platform -eq "Win32NT" -or $PSVersionTable.Platform -eq "Windows") {
        return "Windows"
    }
    elseif ($PSVersionTable.OS -like "*Linux*") {
        return "Linux"
    }
    elseif ($PSVersionTable.OS -like "*Darwin*") {
        return "macOS"
    }
    else {
        return "Unknown"
    }
}

function Get-IsWindows {
    return (Get-OSType) -eq "Windows"
}

function Get-IsUnix {
    $os = Get-OSType
    return $os -eq "Linux" -or $os -eq "macOS"
}

# Path Helpers
function Get-SafePath {
    <#
    .SYNOPSIS
        Creates a platform-safe path
        
    .PARAMETER PathComponents
        Array of path components
        
    .OUTPUTS
        [string] - Combined path
    #>
    
    param([string[]]$PathComponents)
    
    if ($PathComponents.Count -eq 0) {
        return "."
    }
    
    return [System.IO.Path]::Combine($PathComponents)
}

function Get-UserHome {
    <#
    .SYNOPSIS
        Gets the user home directory
        
    .OUTPUTS
        [string] - Home directory path
    #>
    
    return [Environment]::GetFolderPath("UserProfile")
}

function Get-TempPath {
    <#
    .SYNOPSIS
        Gets the system temp directory
        
    .OUTPUTS
        [string] - Temp directory path
    #>
    
    return [System.IO.Path]::GetTempPath()
}

function Get-ConfigPath {
    <#
    .SYNOPSIS
        Gets the config directory
        
    .OUTPUTS
        [string] - Config directory path
    #>
    
    return Get-SafePath @(".", "config")
}

function Get-ScriptsPath {
    <#
    .SYNOPSIS
        Gets the scripts directory
        
    .OUTPUTS
        [string] - Scripts directory path
    #>
    
    return Get-SafePath @(".", "scripts")
}

function Get-DocsPath {
    <#
    .SYNOPSIS
        Gets the docs directory
        
    .OUTPUTS
        [string] - Docs directory path
    #>
    
    return Get-SafePath @(".", "docs")
}

function Get-TestsPath {
    <#
    .SYNOPSIS
        Gets the tests directory
        
    .OUTPUTS
        [string] - Tests directory path
    #>
    
    return Get-SafePath @(".", "tests")
}

function Get-LogsPath {
    <#
    .SYNOPSIS
        Gets the logs directory
        
    .OUTPUTS
        [string] - Logs directory path
    #>
    
    return Get-SafePath @(".", "logs")
}

# File Helpers
function New-SafeDirectory {
    <#
    .SYNOPSIS
        Creates a directory safely across platforms
        
    .PARAMETER Path
        Directory path to create
    #>
    
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Remove-ItemSafely {
    <#
    .SYNOPSIS
        Removes items safely across platforms
        
    .PARAMETER Path
        Path to remove
    #>
    
    param([string]$Path)
    
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function Set-ExecutablePermission {
    <#
    .SYNOPSIS
        Sets executable permission on Unix systems
        
    .PARAMETER FilePath
        File path to make executable
    #>
    
    param([string]$FilePath)
    
    if (Get-IsUnix) {
        try {
            & chmod +x $FilePath
        }
        catch {
            Write-Warning "Could not set executable permission on $FilePath"
        }
    }
}

# Environment Helpers
function Get-EnvironmentVariable {
    <#
    .SYNOPSIS
        Gets environment variable safely
        
    .PARAMETER Name
        Variable name
        
    .PARAMETER Default
        Default value if not found
        
    .OUTPUTS
        [string] - Variable value
    #>
    
    param(
        [string]$Name,
        [string]$Default = ""
    )
    
    $value = [Environment]::GetEnvironmentVariable($Name, "User")
    
    if ([string]::IsNullOrEmpty($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    }
    
    if ([string]::IsNullOrEmpty($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    }
    
    return if ([string]::IsNullOrEmpty($value)) { $Default } else { $value }
}

function Set-EnvironmentVariable {
    <#
    .SYNOPSIS
        Sets environment variable safely
        
    .PARAMETER Name
        Variable name
        
    .PARAMETER Value
        Variable value
    #>
    
    param(
        [string]$Name,
        [string]$Value
    )
    
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
}

# Logging Helpers
function Write-Log {
    <#
    .SYNOPSIS
        Writes log message with timestamp
        
    .PARAMETER Message
        Message to log
        
    .PARAMETER Level
        Log level (info, warn, error, debug)
    #>
    
    param(
        [string]$Message,
        [ValidateSet('info', 'warn', 'error', 'debug', 'success')]
        [string]$Level = 'info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'info' { 'Cyan' }
        'warn' { 'Yellow' }
        'error' { 'Red' }
        'debug' { 'Gray' }
        'success' { 'Green' }
        default { 'White' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Command Helpers
function Invoke-CommandSafely {
    <#
    .SYNOPSIS
        Invokes command safely with error handling
        
    .PARAMETER Command
        Command to invoke
        
    .PARAMETER Arguments
        Command arguments
    #>
    
    param(
        [string]$Command,
        [string[]]$Arguments
    )
    
    try {
        if ($Arguments) {
            & $Command @Arguments
        }
        else {
            & $Command
        }
        return $true
    }
    catch {
        Write-Log "Command failed: $Command" "error"
        Write-Log $_.Exception.Message "error"
        return $false
    }
}

# Validation Helpers
function Test-CommandExists {
    <#
    .SYNOPSIS
        Tests if a command exists
        
    .PARAMETER Command
        Command name
        
    .OUTPUTS
        [bool] - True if command exists
    #>
    
    param([string]$Command)
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

function Test-FileReadable {
    <#
    .SYNOPSIS
        Tests if a file is readable
        
    .PARAMETER Path
        File path
        
    .OUTPUTS
        [bool] - True if readable
    #>
    
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    try {
        $file = Get-Item $Path
        $null = [System.IO.File]::OpenRead($file.FullName).Dispose()
        return $true
    }
    catch {
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-OSType',
    'Get-IsWindows',
    'Get-IsUnix',
    'Get-SafePath',
    'Get-UserHome',
    'Get-TempPath',
    'Get-ConfigPath',
    'Get-ScriptsPath',
    'Get-DocsPath',
    'Get-TestsPath',
    'Get-LogsPath',
    'New-SafeDirectory',
    'Remove-ItemSafely',
    'Set-ExecutablePermission',
    'Get-EnvironmentVariable',
    'Set-EnvironmentVariable',
    'Write-Log',
    'Invoke-CommandSafely',
    'Test-CommandExists',
    'Test-FileReadable'
)