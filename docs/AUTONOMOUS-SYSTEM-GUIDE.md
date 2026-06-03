# Autonomous System Guide

## Overview

This guide covers the autonomous systems in gentle-vanguard.

## Systems

### Session Management

- Auto-starts sessions with `session-autostart.cmd`
- Tracks session state in `.session/` directory
- Runs distributed tracing automatically

### Trigger Detection

- Detects skill triggers from user input
- Auto-loads relevant skills
- Routes to appropriate agents

### Context Efficiency

- Target: 100% efficiency
- Uses tiered memory (hot/warm/cold)
- Compression and optimization via `pre-compact-hook.ps1`

### Validation

- Comprehensive validation achieves 100% pass rate
- Cross-workspace sync maintains consistency
- Autonomous hooks ensure code quality

## Workflow

1. User input → Trigger detection
2. Skill auto-loading
3. Task execution
4. Session cleanup
5. Context compression

## Monitoring

Check `.session/reports/` for validation reports and session artifacts.
