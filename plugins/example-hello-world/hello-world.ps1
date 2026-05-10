# example-plugin-hello.ps1
# Example plugin for Foundation
# Adds a simple 'hello' command

param(
    [string]$Name = "World"
)

Write-Host "Hello, $Name! from Foundation Plugin System (FF-011)" -ForegroundColor Green
Write-Host "This is an example plugin demonstrating the plugin architecture." -ForegroundColor Gray
