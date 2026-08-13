# Hooks Implementation Guide

## Overview

This document describes the hooks system implemented in gentle-vanguard.

## Available Hooks

### Pre-Process Input

- **Script**: `src/pre-process-input.ts`
- **Purpose**: Detect skill triggers from user input
- **Trigger**: Before processing any user command

### Post Session

- **Script**: `scripts/utilities/session-end-hook.ps1`
<!-- REF-OBSOLETA: scripts/utilities/session-end-hook.ps1 no tiene equivalente TS (migración PS1→TS) -->
- **Purpose**: Cleanup and save session artifacts
- **Trigger**: When session ends

### Pre-Commit

- **Script**: `scripts/utilities/pre-commit-hook.ps1`
<!-- REF-OBSOLETA: scripts/utilities/pre-commit-hook.ps1 no tiene equivalente TS (migración PS1→TS) -->
- **Purpose**: Validate before git commit
- **Trigger**: Before git commit

### Post-Merge

- **Script**: `src/post-merge-sync.ts`
- **Purpose**: Sync after git merge
- **Trigger**: After git merge

## Configuration

Hooks are configured in `config/hooks-config.json`.

## Adding New Hooks

1. Create script in appropriate directory
2. Register in `config/hooks-config.json`
3. Update `scripts/utilities/WORKFLOW-ORCHESTRATION/hook-registry.json`
