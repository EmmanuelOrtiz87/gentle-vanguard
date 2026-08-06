# Gentle-Vanguard PROJECT - COMPREHENSIVE NORMATIVES

**Version**: 2.0.0  
**Date**: August 04, 2026  
**Status**: Active  
**Author**: Gentle-Vanguard Governance Team  
**Normativas Activas**: 54 archivos

---

## Table of Contents

### Core Normativas (NORMATIVAS-*.md)

1. [Architecture](#architecture-normatives)
2. [Autonomous Evolution](#autonomous-evolution-normatives)
3. [CI/CD Self-Healing](#cicd-self-healing-normatives)
4. [Code Quality](#code-quality-normatives)
5. [Enforcement](#enforcement--governance)
6. [Eval Quality](#eval-quality-normatives)
7. [Multi-Tenant](#multi-tenant-normatives)
8. [Ops & DevOps](#ops--devops-normatives)
9. [Performance](#performance-normatives)
10. [Security & Compliance](#security--compliance-normatives)
11. [Workflow](#workflow-normatives)

### Special Normativas

- [Nexus Database](#nexus-database-normativa)
- [RDD (Rules-Driven Development)](#rdd-normativa)
- [Session Management](#session-management-normativa)
- [Recovery & Disaster](#recovery-normativa)

### Supporting Rules

- [AI & ML](#ai--ml-rules)
- [Code & Standards](#code--standards-rules)
- [Process & Workflow](#process--workflow-rules)
- [Security & Secrets](#security--secrets-rules)

---

## Architecture Normatives

See `rules/NORMATIVAS-ARCHITECTURE.md` - System architecture, patterns, and design principles.

---

## Autonomous Evolution Normatives

See `rules/NORMATIVAS-AUTONOMOUS-EVOLUTION.md` - Self-improving systems and adaptive processes.

---

## CI/CD Self-Healing Normatives

See `rules/NORMATIVAS-CICD-SELF-HEALING.md` - Automated recovery and resilience patterns.

---

## Code Quality Normatives

See `rules/NORMATIVAS-CODE-QUALITY.md` - Standards for code quality and maintainability.

---

## Enforcement & Governance

See `rules/NORMATIVAS-ENFORCEMENT.md` - How normatives are enforced and audited.

---

## Eval Quality Normatives

See `rules/NORMATIVAS-EVAL-QUALITY.md` - Quality gates for evaluations and assessments.

---

## Multi-Tenant Normatives

See `rules/NORMATIVAS-MULTI-TENANT.md` - Isolation and resource management for multi-tenant
operations.

---

## Ops & DevOps Normatives

See `rules/NORMATIVAS-OPS-DEVOPS.md` - Operations, infrastructure, and DevOps practices.

---

## Performance Normatives

See `rules/NORMATIVAS-PERFORMANCE.md` - Latency, throughput, and efficiency requirements.

---

## Security & Compliance Normatives

See `rules/NORMATIVAS-SECURITY-COMPLIANCE.md` - Security standards and compliance requirements.

---

## Workflow Normatives

See `rules/NORMATIVAS-WORKFLOW.md` - Process workflows and task management standards.

---

## Special Normativas

### Nexus Database Normativa

See `rules/NEXUS-NORMATIVA.md` - Operational database identity and lifecycle.

### RDD Normativa

See `rules/RDD-NORMATIVA.md` - Rules-Driven Development enforcement and validation.

### Session Management Normativa

See `rules/SESSION-CLOSE-NORMATIVA.md` - Session lifecycle and closure protocols.

### Recovery Normativa

See `rules/RECOVERY-NORMATIVA.md` - Disaster recovery and rollback procedures.

---

## AI & ML Rules

Core AI and machine learning guidelines:

- `rules/AI-NORMATIVES.md` - General AI principles and constraints
- `rules/AI-MODEL-SELECTION.md` - Model routing and selection criteria
- `rules/PROMPT-ENGINEERING.md` - Prompt design and optimization
- `rules/CONTEXT-ENGINEERING.md` - Context window management
- `rules/HALLUCINATION-PREVENTION.md` - Mitigation strategies
- `rules/HUMAN-IN-THE-LOOP.md` - When to require human approval

### AI Governance

- `rules/PER-PHASE-MODEL-ROUTING.md` - Model assignment by SDD phase
- `rules/AUTO-CONTRIBUTION.md` - Automated contribution guidelines

---

## Code & Standards Rules

Programming and development standards:

- `rules/DEVELOPMENT-STANDARDS.md` - General development practices
- `rules/CODE-REVIEW-STANDARDS.md` - Code review requirements
- `rules/TESTING-STANDARDS.md` - Testing methodologies
- `rules/UNIT-TEST-REQUIREMENTS.md` - Unit testing mandates
- `rules/SDD-STRICT-TDD.md` - Test-driven development requirements
- `rules/TYPESCRIPT-FIRST-POLICY.md` - TypeScript priority over PowerShell
- `rules/POWERSHELL-STANDARDS.md` - PowerShell scripting standards (legacy)
- `rules/SKILL-STYLE-GUIDE.md` - Skill documentation standards
- `rules/TOPIC-KEY-CONVENTION.md` - Topic key naming conventions

### CI/CD & Quality

- `rules/CI-HARDENING-STANDARDS.md` - CI pipeline security
- `rules/SELF-HEALING-CI.md` - Automated CI recovery
- `rules/EVAL-GATES-ENFORCEMENT.md` - Quality gate enforcement

---

## Process & Workflow Rules

Project management and workflow guidelines:

- `rules/DELEGATION-RULES.md` - Agent delegation and routing
- `rules/PR-WORKFLOW.md` - Pull request procedures
- `rules/PROJECT-CONFIG.md` - Project configuration standards
- `rules/PLANNING-ESTIMATION-FRAMEWORK.md` - Task estimation methods
- `rules/INTER-AGENT-COMMUNICATION.md` - Communication between agents
- `rules/INCIDENT-RESPONSE.md` - Incident handling procedures
- `rules/DOCUMENTATION-SYNC-POLICY.md` - Documentation maintenance
- `rules/CONTINUOUS-IMPROVEMENT.md` - Improvement processes

### Local-First & Recovery

- `rules/LOCAL-FIRST-PREFERENCE.md` - Local execution priority
- `rules/STALE-FILE-CLEANUP.md` - Automatic cleanup policies

---

## Security & Secrets Rules

Security and secret management:

- `rules/SECRETS-MANAGEMENT.md` - Secret handling procedures
- `rules/NORMATIVA-PNPM-SECURITY.md` - Package security with pnpm
- `rules/DEPENDENCY-HEALTH.md` - Dependency vulnerability management
- `rules/REVIEW-AUTHORITY-THREAT-MODEL.md` - Code review security model

### Cost & Token Management

- `rules/TOKEN-BUDGET-POLICY.md` - Token usage policies
- `rules/COST-ATTRIBUTION.md` - Cost tracking and attribution

### Observability

- `rules/OBSERVABILITY-SLOS.md` - Service Level Objectives
- `rules/README-GOVERNANCE.md` - README maintenance standards

---

## Appendix A: Hand-Written Norms

See `rules/HAND-WRITTEN-NORMS.md` - User-contributed conventions and patterns.

---

## Appendix B: Normatives Checklist

### Pre-Commit Checklist

- [ ] Code follows naming conventions (see CODE-QUALITY)
- [ ] Code is properly organized
- [ ] Comments explain WHY (not WHAT)
- [ ] Error handling implemented
- [ ] Logging implemented
- [ ] No sensitive data in code
- [ ] Tests written (see SDD-STRICT-TDD)
- [ ] Token budget respected
- [ ] Documentation updated
- [ ] No normative violations

### Code Review Checklist

- [ ] Architecture compliance (NORMATIVAS-ARCHITECTURE)
- [ ] Code quality (NORMATIVAS-CODE-QUALITY)
- [ ] Test coverage > 80% (TESTING-STANDARDS)
- [ ] Documentation (DOCUMENTATION-SYNC-POLICY)
- [ ] Security review (NORMATIVAS-SECURITY-COMPLIANCE)
- [ ] Performance impact (NORMATIVAS-PERFORMANCE)
- [ ] Token efficiency
- [ ] Error handling
- [ ] No violations found

### Deployment Checklist

- [ ] All tests passing
- [ ] Security scan passed
- [ ] Performance validated
- [ ] Documentation updated
- [ ] Configuration validated
- [ ] Monitoring configured
- [ ] Rollback plan ready
- [ ] Stakeholders notified
- [ ] Deployment procedure followed
- [ ] Post-deployment verification

---

## Appendix C: Normatives Violations

### Violation Severity Levels

**Critical**:

- Security vulnerabilities
- Data loss
- Compliance violations
- System outages

**High**:

- Architecture violations
- Major code quality issues
- Test coverage below 80%
- Performance degradation

**Medium**:

- Naming convention violations
- Documentation gaps
- Minor code quality issues
- Process deviations

**Low**:

- Style issues
- Minor documentation gaps
- Non-critical process deviations

### Violation Response

**Critical**: Immediate action required  
**High**: Action required within 24 hours  
**Medium**: Action required within 1 week  
**Low**: Action required within 1 month

---

## Document Status

**Version**: 2.0.0  
**Status**: Active  
**Last Updated**: August 04, 2026  
**Next Review**: November 04, 2026  
**Total Normativas**: 54 files  
**Approval**: Gentle-Vanguard Governance Team

---

**These normatives are mandatory for all Gentle-Vanguard projects and members.**

---

_Última actualización: 2026-08-04 - Índice reconstruido con 54 normativas reales_
