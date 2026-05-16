# Software Design Document (SDD) - Gentle-Vanguard

**versión:** 1.0  
**Date:** April 11, 2026  
**Authors:** Orchestrator AI Assistant  
**Status:** Active

## 1. Overview

### Purpose

Gentle-Vanguard is the base framework for creating standardized, cross-platform development
projects. It provides:

- Project scaffolding and templates
- Cross-platform setup scripts (Windows/Linux/macOS/WSL)
- Orchestrator-coordinated development workflow
- Standardized documentation and governance
- Reusable skills and patterns

### Scope

**Included:**

- Project bootstrapping system
- Cross-platform compatibility layer
- Documentation governance
- Skill-based development coordination
- Template management

**Excluded:**

- Specific application logic (handled by generated projects)
- Database implementations (project-specific)
- UI frameworks (project-specific)

### Assumptions

- Target platforms: Windows (PowerShell/pwsh), Linux, macOS, WSL
- Development environments support Bash/PowerShell scripting
- Git is available for versión control
- Projects will follow orchestrator standards

## 2. System Architecture

### High-level Design

```
Gentle-Vanguard
 Core Components
    Bootstrap System (scripts/gentle-vanguard/bootstrap.ps1)
    Setup Scripts (scripts/gentle-vanguard/setup.sh, scripts/utilities/gv.ps1)
    Template Engine (templates/)
    Skill Registry (skills/)
 Governance Layer
    Documentation Standards (docs/)
    Orchestrator Integration (config/orchestrator.json)
    Cross-platform Routing (scripts/)
 Project Generation
     Scaffold Creation (projects/)
     Configuration Management (config/)
     Validation System (scripts/validation/*.ps1)
```

### Technology Stack

- **Languages:** PowerShell, Bash, Go (for generated projects)
- **Platforms:** Cross-platform (Windows/Linux/macOS/WSL)
- **Tools:** Git, Orchestrator, AI-assisted development
- **Documentation:** Markdown with structured directories

### Deployment

- **Distribution:** Git repository as template
- **Installation:** Canonical setup entrypoints are `bash scripts/gentle-vanguard/setup.sh` or
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gentle-vanguard\bootstrap.ps1`
- **Updates:** Git-based with validation scripts

## 3. Detailed Design

### Modules/Components

#### Bootstrap System

**Responsibilities:**

- Project scaffolding from templates
- Configuration file generation
- Dependency setup and validation

**Key Files:**

- `scripts/gentle-vanguard/bootstrap.ps1` - Canonical PowerShell bootstrap script
- `scripts/project/new-project.ps1` - Canonical project creation entrypoint
- `templates/` - Project templates
- `config/` - Configuration templates

#### Cross-Platform Layer

**Responsibilities:**

- OS detection and shell routing
- Command normalization
- Environment setup

**Implementation:**

```powershell
# Platform detection
$os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "macos" } else { "linux" }

# Shell routing
$shell = if ($PSversiónTable.PSEdition -eq "Core") { "pwsh" } else { "powershell" }
```

#### Documentation Governance

**Responsibilities:**

- Enforce documentation standards
- Maintain navigation structure
- Generate indexes and redirects

**Structure:**

```
docs/
 README.md                    # Master index
 getting-started/            # Setup guides
 guides/                     # Strategies and initiatives
 reference/                  # Technical specs
 supplementary/              # Resources and summaries
 sdd/                        # Design documents
 sessions/                   # Development notes
```

### Data Flow

```
User Request  Canonical Bootstrap Script  Template Selection  Configuration  Validation  Project Ready

           Orchestrator Coordination  Skill Loading  Implementation  Documentation
```

### APIs/Interfaces

#### Bootstrap API

```powershell
# Main entry point
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gentle-vanguard\bootstrap.ps1

# Canonical project creation entry point
.\scripts\project\new-project.ps1 -Name "MyProject" -Kind "service"

# Parameters:
# -Name: Project name
# -Kind: Project type/profile selector
```

#### Setup API

```bash
# Cross-platform setup
bash scripts/gentle-vanguard/setup.sh    # Linux/macOS/WSL
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gentle-vanguard\bootstrap.ps1   # Windows
```

## 4. Implementation Plan

### Phases

#### Phase 1: Core Gentle-Vanguard (Current)

- Bootstrap system
- Cross-platform setup
- Basic templates
- Documentation structure

#### Phase 2: Advanced Features (Next)

- AI-assisted scaffolding
- Advanced templates
- Integrated testing
- Performance monitoring

#### Phase 3: Ecosystem Integration

- Plugin system
- Cloud deployment templates
- Multi-language support

### Dependencies

- **External:** Git, PowerShell/Bash
- **Internal:** Orchestrator skills, Template engine
- **Optional:** Docker, Kubernetes tools

### Risks and Mitigations

| Risk                          | Impact | Mitigation                             |
| ----------------------------- | ------ | -------------------------------------- |
| Platform compatibility issues | High   | Comprehensive testing on all platforms |
| Template maintenance          | Medium | Automated validation scripts           |
| Documentation drift           | Low    | Orchestrator-enforced standards        |
| Skill versión conflicts       | Medium | versión pinning and testing            |

## 5. Testing Strategy

### Unit Tests

- Bootstrap script functionality
- Template validation
- Configuration generation
- Cross-platform compatibility

### Integration Tests

- End-to-end project creation
- Setup script execution
- Documentation generation
- Orchestrator integration

### Acceptance Criteria

- Projects bootstrap successfully on all platforms
- Generated projects follow standards
- Documentation is navigable and complete
- Orchestrator coordination works seamlessly

## 6. AI-Assisted Development Notes

### Prompts Used

- "Create a cross-platform bootstrap system for project scaffolding"
- "Design documentation governance with orchestrator coordination"
- "Implement error handling patterns for gentle-vanguard scripts"

### Code Generation

- Bootstrap scripts with platform detection
- Template validation logic
- Documentation structure automation

### Review Points

- Security: Input validation in scripts
- Performance: Script execution time
- Compatibility: Testing on all target platforms

## 7. Error Handling Patterns

### Implementation in Gentle-Vanguard

#### Structured Error Handling

```powershell
function Invoke-SafeOperation {
    param([scriptblock]$Operation, [string]$Context)

    try {
        & $Operation
    } catch {
        Write-ErrorLog -Message $_.Exception.Message -Context $Context -Stack $_.ScriptStackTrace
        throw
    }
}
```

#### Platform-Specific Error Handling

```bash
# Bash error handling
set -e  # Exit on error
trap 'handle_error $LINENO' ERR

handle_error() {
    echo "Error on line $1" >&2
    exit 1
}
```

### Error Types Handled

- File system errors (permissions, missing files)
- Network errors (downloads, API calls)
- Platform detection failures
- Template validation errors

## 8. Performance Optimization Patterns

### Script Optimization

- Use streaming for large file operations
- Cache expensive operations (platform detection)
- Parallel processing where possible

### Template Optimization

- Lazy loading of templates
- Minimal configuration generation
- Efficient validation algorithms

### Monitoring

- Execution time logging
- Memory usage tracking
- Success/failure metrics

## 9. Specification Driven Design (TDD/BDD)

### Bootstrap Specifications

```
Given a template type and project name
When bootstrap is executed
Then project structure is created
And configuration files are generated
And dependencies are installed
```

### Cross-Platform Specifications

```
Given any supported platform
When setup script runs
Then environment is configured
And orchestrator is activated
And commands work identically
```

### Implementation Approach

- Write specifications first
- Implement minimal code to pass specs
- Refactor for optimization
- Repeat for each feature

---

**This SDD serves as the gentle-vanguard for all projects created from Gentle-Vanguard. All
generated projects should reference and extend this document.**

