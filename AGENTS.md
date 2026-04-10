# Code Review Rules - Workspace Foundation

This file defines the coding standards enforced by **GGA** (Gentleman Guardian Angel) on every commit.

## PowerShell Scripts

- Use `$ErrorActionPreference = 'Stop'` for critical scripts
- Use `param()` with proper parameter attributes
- Use `Write-Host` with `-ForegroundColor` for status messages
- Prefer `Get-Command` over `Test-Path` for executables
- Use `Ensure-Directory` helper for directory creation
- Follow verb-noun naming convention

## Shell Scripts

- Use `set -e` for error propagation
- Use `#!/usr/bin/env bash` shebang
- Validate required commands before execution
- Use consistent error messages

## Documentation

- Write documentation in English
- Use markdown formatting
- Keep README files updated
- Document all public functions

## Project Structure

- Follow the workspace foundation conventions
- Use `scripts/` for automation
- Use `docs/` for documentation
- Use `config/` for configuration

## Git Workflow

- Use conventional commit messages
- Run validation before committing
- Keep commits focused and atomic

## Testing

- Write tests for critical functionality
- Use table-driven tests where applicable
- Mock external dependencies

## Security

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Validate all user inputs
- Follow least privilege principle
