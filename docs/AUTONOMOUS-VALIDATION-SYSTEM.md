# Autonomous Validation System

## Overview
The autonomous validation system continuously monitors workspace health and configuration.

## Components

### Comprehensive Validation
- **Script**: `scripts/utilities/WORKFLOW-ORCHESTRATION/comprehensive-validation.ps1`
- **Purpose**: End-to-end validation of entire workspace
- **Run**: `.\comprehensive-validation.ps1 -Verbose`

### Cross-Workspace Validation
- **Script**: `scripts/monitoring/cross-workspace-validator.ps1`
- **Purpose**: Ensures local and foundation stay in sync
- **Run**: `.\cross-workspace-validator.ps1 -Fix`

### Engram Optimization
- **Script**: `tools/optimize-engram-usage.ps1`
- **Purpose**: Optimizes Engram memory usage
- **Trigger**: Automatic during session autostart

## Automation
Validation runs automatically:
1. On session start (via `session-autostart.cmd`)
2. Before commit (pre-commit hook)
3. After merge (post-merge hook)

## Pass Rate Target
Target: 100% pass rate on all validations.
