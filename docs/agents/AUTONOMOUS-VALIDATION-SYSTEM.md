# Autonomous Validation System

## Overview

The autonomous validation system continuously monitors workspace health and configuration.

## Components

### Comprehensive Validation

- **Script**: `src/comprehensive-validation.ts`

<!-- REF-OBSOLETA: src/comprehensive-validation.ts no existe (ruta migrada o eliminada) -->

- **Purpose**: End-to-end validation of entire workspace
- **Run**: `.\comprehensive-validation.ps1 -Verbose`

### Cross-Workspace Validation

- **Script**: `src/cross-workspace-validator.ts`
- **Purpose**: Ensures local and gentle-vanguard stay in sync
- **Run**: `.\cross-workspace-validator.ps1 -Fix`

### Engram Optimization

- **Script**: `src/optimize-engram-usage.ts`
- **Purpose**: Optimizes Engram memory usage
- **Trigger**: Automatic during session autostart

## Automation

Validation runs automatically:

1. On session start (via `session-autostart.cmd`)
2. Before commit (pre-commit hook)
3. After merge (post-merge hook)

## Pass Rate Target

Target: 100% pass rate on all validations.
