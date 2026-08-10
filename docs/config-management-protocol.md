# OpenCode Configuration Management Protocol

## Overview

This document outlines the protocol for maintaining correct, functional, integrated, autonomous,
documented, learned, updated, and normalized opencode configurations within the Gentle Vanguard
stack.

## 1. Configuration Integrity Requirements

### 1.1 Syntax Validation

- All opencode.json must pass strict JSON parsing validation
- No duplicate properties or malformed syntax allowed
- All configuration values must be valid according to OpenCode schema

### 1.2 Structural Validation

- Configuration must use only defined properties from the official OpenCode schema
- Undocumented properties must be moved to appropriate configuration sections or removed
- All agent configurations must follow required structure

### 1.3 Validation Pipeline

The system automatically validates configuration on session startup through the following steps:

1. `json-validator-verify` - Ensures JSON syntax is valid
2. `opencode-config-validate` - Checks for unrecognized properties
3. `validate-tool-configs` - Validates all tool configs against official schemas

## 2. Automated Safeguards

### 2.1 Session Startup Blocking

When configuration validation fails, the session startup process halts with detailed error messages:

- Invalid JSON syntax prevents session from initializing
- Unrecognized properties cause startup failure with clear reporting
- Validation errors are logged to `.runtime/validation-errors.log` for forensic analysis

### 2.2 Pre-commit Validation

Lefthook configuration enforces:

- Configuration file syntax checks before commits
- No broken configurations can be committed to version control
- Automatic repair suggestions for common configuration issues

### 2.3 Runtime Monitoring

Continuous monitoring detects:

- Configuration file corruption
- Unauthorized modification attempts
- Validation state changes during runtime

## 3. Configuration Best Practices

### 3.1 Documentation Standards

All configuration changes must include:

- Inline comments explaining purpose of non-obvious settings
- Rationale for significant configuration decisions
- Version control tracking of configuration evolution

### 3.2 Change Management

When modifying opencode.json:

1. Validate changes against existing configuration patterns
2. Verify all referenced agents and tools exist
3. Test session startup with new configuration
4. Document impact of changes in changelog format

### 3.3 Backup and Recovery

- Automated backups of configuration files before modifications
- Atomic updates ensuring no partial writes occur
- Rollback capability for failed configuration changes

## 4. Integration Protocols

### 4.1 Cross-System Validation

Configuration must be validated across:

- Agent runtime environments
- Tool integration points
- External dependency interfaces
- Security boundary conditions

### 4.2 Continuous Integration

CI/CD pipeline enforces:

- All configuration files pass validation
- No regressions in configuration behavior
- Consistent formatting and standards adherence

## 5. Autonomous Operation

### 5.1 Self-Healing Configuration

The system automatically:

- Detects configuration anomalies
- Attempts correction for common issues
- Flags critical mismatches for manual review
- Maintains operational state when configuration is inconsistent

### 5.2 Learning from Configuration Patterns

The system tracks:

- Historical configuration changes
- Common error patterns and solutions
- Optimization opportunities based on usage
- Evolutionary trends in configuration requirements

## 6. Normalization and Updates

### 6.1 Standardized Templates

All configurations follow templates with:

- Consistent organizational structure
- Uniform property ordering
- Standardized naming conventions
- Verified compatibility between versions

### 6.2 Update Procedures

Configuration updates follow the cycle:

1. Assessment of impact areas
2. Testing in controlled environment
3. Staged rollout to production
4. Monitoring for unintended consequences
5. Post-update validation and documentation

## Implementation Plan

### Immediate Actions

1. Ensure all existing configurations conform to documented patterns
2. Establish validation as hard requirement in CI/CD pipeline
3. Create automated backup procedures for config files

### Ongoing Operations

1. Weekly configuration health audits
2. Monthly pattern analysis and optimization reviews
3. Quarterly full-spectrum configuration assessments
4. Continuous monitoring and reporting of configuration stability

## Compliance Matrix

| Requirement              | Status         | Owner       | Due Date  |
| ------------------------ | -------------- | ----------- | --------- |
| Configuration Validation | ✅ Implemented | System      | Ongoing   |
| Backup & Recovery        | ✅ Partial     | Team        | Q2 2026   |
| Change Documentation     | ⚠️ Manual      | Developer   | As Needed |
| Automated Repair         | ❌ Planned     | Engineering | Q3 2026   |

This protocol ensures that opencode configurations remain correct, functional, integrated,
autonomous, documented, learned, updated, and normalized at all times.
