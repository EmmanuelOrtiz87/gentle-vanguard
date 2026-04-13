# Automatic Tool Activation - Gentleman Foundation

This system ensures that all development tools are automatically activated and ready for coordinated workflow development.

## 🚀 Quick Setup

### 1. Copy PowerShell Profile (Optional)
For automatic activation when entering Gentleman Foundation projects:

```powershell
# Copy to your PowerShell profile location
Copy-Item "scripts/utilities/Microsoft.PowerShell_profile.ps1" $PROFILE
```

### 2. Configure Git Hooks (Recommended)
Git hooks automatically validate tools before commits:

```powershell
# Copy pre-commit hook
Copy-Item "hooks/pre-commit.ps1" ".git/hooks/pre-commit.ps1"
```

### 3. Manual Activation
Activate tools anytime with:

```powershell
# Check and activate all tools
.\wf.ps1 health

# Force auto-start missing tools
.\wf.ps1 health -Force

# Auto-init environment (any directory)
.\scripts\utilities\auto-init-dev-environment.ps1
```

## 🛠️ Tools Activated

### Core Tools
- **Engram**: Memory persistence system for AI context
- **GGA**: Gentleman Guardian Angel (AI code review)
- **Gentle-AI**: AI CLI assistant for development
- **Orchestrator Skills**: Coordinated workflow management

### Validation Checks
- Tool availability verification
- Automatic installation attempts (where possible)
- Background service startup
- Workflow system readiness

## 🔄 Activation Triggers

### Automatic
- **Pre-commit hook**: Validates tools before each commit
- **PowerShell profile**: Activates when entering GF projects
- **Session start**: Health checks run automatically

### Manual
- `.\wf.ps1 health`: Check and activate tools
- `.\scripts\utilities\auto-init-dev-environment.ps1`: Full environment init

## 📋 Status Indicators

- ✅ **Available**: Tool is ready and functional
- ⚠️ **Warning**: Tool not available but not critical
- ❌ **Error**: Tool failed to activate

## 🎯 Benefits

1. **Guaranteed Readiness**: All tools active before development
2. **AI Context Persistence**: Engram ensures memory continuity
3. **Coordinated Workflow**: Orchestrator skills guide development
4. **Quality Assurance**: Pre-commit validation prevents issues
5. **Seamless Experience**: Automatic activation reduces manual setup

## 🔧 Troubleshooting

### Tools Not Activating
```powershell
# Force activation with verbose output
.\wf.ps1 health -Force
```

### Profile Not Loading
```powershell
# Check profile path
$PROFILE

# Reload profile
. $PROFILE
```

### Git Hooks Not Working
```powershell
# Ensure hook is executable
chmod +x .git/hooks/pre-commit.ps1
```

## 📚 Integration

This system integrates with:
- **Foundation Template**: Automatic setup for new projects
- **Workflow CLI**: `wf.ps1` commands
- **Session Management**: Coordinated development sessions
- **Quality Gates**: Pre-commit validation

The automatic activation ensures that every Gentleman Foundation project starts with a fully prepared development environment, maximizing productivity and maintaining development standards.