# Dependency Security Policies Configuration

This document describes the dependency security policies enforced by Gentle-Vanguard and how to
configure them.

## 1. Security Policies Overview

The following security policies are enforced for all project dependencies:

### 1.1 Vulnerability Scan

- **Purpose**: Detect security vulnerabilities in dependencies
- **Command**: `pnpm audit --audit-level=high`
- **Severity**: Critical
- **Remediation**: Run `pnpm audit fix` or manually update vulnerable packages

### 1.2 License Compliance

- **Purpose**: Ensure all dependencies comply with project license policies
- **Command**: `pnpm licenses list --json`
- **Severity**: High
- **Remediation**: Review and approve licenses for all dependencies

### 1.3 Dependency Lock Integrity

- **Purpose**: Verify dependency integrity through lock file
- **Command**: `pnpm install --frozen-lockfile`
- **Severity**: Critical
- **Remediation**: Run `pnpm install` to regenerate lockfile if needed

### 1.4 Security Updates

- **Purpose**: Check for security updates on dependencies
- **Command**: `pnpm outdated --long`
- **Severity**: High
- **Remediation**: Update dependencies to versions with security patches

### 1.5 Deprecated Packages

- **Purpose**: Identify and remove deprecated packages
- **Command**: `pnpm list --deprecated`
- **Severity**: Medium
- **Remediation**: Replace deprecated packages with maintained alternatives

### 1.6 Unused Dependencies

- **Purpose**: Remove unused dependencies to reduce attack surface
- **Command**: `pnpm list --unused`
- **Severity**: Medium
- **Remediation**: Remove unused dependencies

## 2. Configuration Options

### 2.1 Enabling/Disabling Policies

Each policy can be enabled or disabled by modifying the `enabled` field in the policy configuration:

```json
{
  "name": "vulnerability-scan",
  "description": "Scan for security vulnerabilities in dependencies",
  "checkCommand": "pnpm audit --audit-level=moderate",
  "remediation": "Run \"pnpm audit fix\" or manually update vulnerable packages",
  "severity": "critical",
  "enabled": true
}
```

### 2.2 Policy Severity Levels

- **Critical**: Must be addressed immediately - can lead to security breaches
- **High**: Should be addressed soon - significant security implication
- **Medium**: Should be considered - moderate security impact
- **Low**: Informational - minimal security impact

## 3. Remediation Procedures

### 3.1 Vulnerability Fixes

```bash
# Fix security vulnerabilities
pnpm audit fix

# For critical vulnerabilities, manual intervention may be required
pnpm install <package>@<version>
```

### 3.2 License Compliance

```bash
# View current licenses
pnpm licenses list

# Approve specific licenses
pnpm licenses allow <license-type>
```

### 3.3 Dependency Updates

```bash
# Check for outdated packages
pnpm outdated

# Update all packages
pnpm update

# Update specific package
pnpm update <package-name>
```

### 3.4 Removing Deprecated Packages

```bash
# Remove deprecated packages
pnpm remove <deprecated-package-name>
```

### 3.5 Removing Unused Dependencies

```bash
# Remove unused dependencies
pnpm remove <unused-package-name>
```

## 4. Integration with CI/CD

The dependency security policies are automatically enforced during:

- Session startup (through `session-autostart.config.json`)
- Pre-commit hooks
- CI/CD pipeline runs

## 5. Monitoring and Reporting

### 5.1 Security Reports

Security reports are generated automatically and include:

- Overall compliance status
- Detailed breakdown by policy type
- Severity classification
- Remediation recommendations

### 5.2 Automated Remediation

Some policies support automated remediation:

- Vulnerability fixes via `pnpm audit fix`
- Dependency updates via `pnpm update`

## 6. Customization

To customize policies:

1. Modify the `src/dependency-security-enforcer.ts` file
2. Add new policies to the `policies` array
3. Configure severity levels and remediation steps
4. Test the changes with the verification script

## 7. Best Practices

### 7.1 Regular Audits

- Run dependency security checks regularly
- Monitor for new vulnerabilities
- Update dependencies promptly

### 7.2 Policy Maintenance

- Review and update policies quarterly
- Adjust severity levels based on project needs
- Document policy changes in version control

### 7.3 Team Awareness

- Train team members on security policies
- Communicate policy changes effectively
- Encourage proactive security practices

## 8. Troubleshooting

### 8.1 Common Issues

- **Lockfile conflicts**: Run `pnpm install` to regenerate
- **Vulnerability false positives**: Review audit results carefully
- **License compliance issues**: Approve or replace problematic licenses

### 8.2 Debugging

```bash
# Run individual checks manually
pnpm audit --audit-level=moderate
pnpm licenses list --json
pnpm outdated --long
```

This configuration ensures that Gentle-Vanguard maintains strong security posture through
comprehensive dependency management and continuous monitoring.
