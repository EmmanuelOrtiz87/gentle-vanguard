# OpenCode Configuration Validator Enhancement

## Problem Statement

The current configuration validation system needs enhancement to provide:

1. More comprehensive structural validation
2. Better error reporting for configuration issues
3. Automated repair capabilities
4. Integration with existing safeguard mechanisms

## Enhanced Validation Features

### 1. Structural Integrity Checks

The enhanced validator will now perform deeper structural checks:

- Agent mode consistency validation
- Required property presence verification
- Type consistency validation
- Reference integrity checks

### 2. Error Reporting Improvements

Enhanced error messaging with:

- Specific line numbers for issues
- Contextual information for fixes
- Priority classification of issues (critical, warning, info)
- Suggested remediation steps

### 3. Automated Repair Capabilities

Smart repair features including:

- Removal of unrecognized properties with warnings
- Structural normalization of agent configurations
- Validation of required fields presence

## Implementation Plan

### Phase 1: Enhanced Validation Engine

Modify `src/validate-opencode-config.ts` to include:

- Deep structural validation
- More specific error reporting
- Better handling of complex nested structures

### Phase 2: Integration with Existing Systems

Ensure integration with:

- Session autostart validation pipeline
- Lefthook pre-commit hooks
- CI/CD validation processes

### Phase 3: Documentation and Training

Update documentation to cover:

- New validation rules
- Error interpretation guide
- Best practices for configuration changes

## Technical Specification

### Validation Rules

1. **JSON Syntax Validation**
   - Ensure valid JSON structure
   - Reject malformed JSON with clear error messages

2. **Property Recognition**
   - Only allow recognized top-level properties
   - Flag unrecognized nested properties
   - Warn about deprecated properties

3. **Agent Structure Validation**
   - Verify required agent properties are present
   - Validate agent mode values
   - Check steps field is numeric and positive

4. **MCP Structure Validation**
   - Validate service types are supported
   - Ensure required command/args are present for stdio services
   - Check service enablement states

5. **Permission Structure Validation**
   - Verify permission nesting is consistent
   - Validate permission values are correctly formatted
   - Check for conflicting permission rules

## Backward Compatibility

The enhanced validator maintains full backward compatibility with existing configurations while
adding stricter enforcement of standards.

## Testing Strategy

1. Unit tests for individual validation functions
2. Integration tests with sample configurations
3. Regression tests for existing validation behavior
4. Performance tests to ensure minimal startup overhead
