# OpenCode Configuration Standards

## Overview

This document establishes the standards and guidelines for maintaining proper OpenCode
configurations within the Gentle Vanguard system.

## 1. Configuration Structure

### 1.1 Top-Level Properties

All opencode.json configurations must only include the following recognized properties:

- `$schema`: JSON schema reference for validation
- `agent`: Agent definitions and configurations
- `mcp`: Model Context Protocol service configuration
- `tools`: Available tool integrations
- `permission`: Permission policies
- `watcher`: File system watching patterns
- `compaction`: Data compaction settings
- `default_agent`: Default agent selector
- `share`: Sharing policy
- `references`: Configuration references

## 2. Agent Configuration Standards

### 2.1 Required Agent Properties

Each agent must have:

- `mode`: Either "primary" or "subagent"
- `model`: Valid model identifier
- `steps`: Positive integer defining maximum steps
- `permission`: Permission configuration

### 2.2 Agent Type Definitions

- **Primary Agents**: Main coordinators with higher step counts
- **Subagents**: Specialized workers with limited step counts

## 3. MCP Service Standards

### 3.1 Service Types

MCP services must define:

- `type`: Either "local" or "stdio"
- `command`: Executable command with arguments
- `enabled`: Boolean indicating service activation

## 4. Permission Policies

Permission structures must follow these patterns:

- Simple boolean permissions (allow/deny)
- Task-specific permissions using wildcards ("*")
- Nested permission objects with appropriate scopes

## 5. Validation Pipeline

### 5.1 Validation Sequence

The validation process occurs in this order:

1. JSON syntax validation
2. Property recognition validation
3. Structural integrity validation
4. Semantic correctness validation

### 5.2 Validation Failure Handling

- Invalid configurations halt session startup
- Error messages indicate specific issues
- Automatic repair options available with warnings
- Detailed logging for troubleshooting

## 6. Configuration Best Practices

### 6.1 Change Process

When modifying configurations:

1. Verify JSON syntax is valid
2. Ensure all properties are recognized
3. Validate structural integrity
4. Test session startup with changes
5. Document impact of changes

### 6.2 Version Control Guidelines

- Commit configuration changes atomically
- Include descriptive commit messages
- Tag breaking changes with major version bumps
- Maintain backward compatibility where possible

## 7. Implementation

### 7.1 Technical Requirements

All validation must be performed by:

- `src/validate-opencode-config.ts`
- Built-in session startup validation
- CI/CD pipeline integration
- Pre-commit hook enforcement

### 7.2 Integration Points

Validations must integrate with:

- Session startup pipeline
- Tool configuration validation
- Configuration change detection
- Automated monitoring systems
