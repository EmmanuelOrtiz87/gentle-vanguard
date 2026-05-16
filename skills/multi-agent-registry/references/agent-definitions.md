# Agent Definitions

## AGENT-BA: Business Analyst

**Role**: Analyzes requirements, creates BDD scenarios, defines acceptance criteria. **Skills**:
bdd-scenarios-skill, documentation-governance, requirements patterns **Triggers**: requirements,
user story, BDD, Gherkin, acceptance criteria, feature analysis, especificación funcional
**Deliverables**: BDD scenario files (`docs/sdd/*.feature`), acceptance criteria documents, user
story mappings, requirements traceability matrix **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent BA "<task>"
.\scripts\utilities\gv.ps1 bdd "<feature-description>"
```

## AGENT-SAD: Solution Architect & Designer

**Role**: Defines system architecture, creates SDD documents, makes technical decisions. **Skills**:
architecture-governance, api-design-skill, database-relational-skill, database-nosql-skill,
typescript-skill, golang-api-skill **Triggers**: architecture, design, SDD, system design, API
design, database schema, technical decision, arquitectura, diseño **Deliverables**: SDD documents
(`docs/sdd/SDD-*.md`), Architecture Decision Records (ADR), API contracts and schemas, database
design documents **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent SAD "<task>"
.\scripts\utilities\gv.ps1 sdd "<feature-name>"
```

## AGENT-DEV: Senior Developer

**Role**: Implements features, writes code, performs refactoring. **Skills**: angular-spa-skill,
react-19-skill, nextjs-15-skill, tailwind-4-skill, zustand-5-skill, zod-4-skill, security-skill,
technical-debt-skill **Triggers**: implement, code, develop, feature, refactor, fix bug, frontend,
backend, component, API endpoint **Deliverables**: Source code implementations, code refactoring,
technical debt records, security hardening **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent DEV "<task>"
.\scripts\utilities\gv.ps1 scaffold "<component-name>"
```

## AGENT-QA: Quality Assurance

**Role**: Creates tests, validates functionality, ensures quality gates. Owns Judgment Day:
dual-review adversarial protocol for pre-merge validation. **Skills**: testing-strategy-skill,
testing-skill, playwright-skill, pytest-skill, code-review-orchestrator-skill **Triggers**: test,
testing, QA, validation, E2E, unit test, integration test, playwright, pytest, calidad, judgment
day, juicio final, dia del juicio, revision de a pares, dual review, adversarial review, corre
juicio, ejecuta juicio, activa juicio, realizar juicio, corre dual review, corre adversarial,
revision profunda pre-merge **Deliverables**: Test files and suites, E2E test scenarios, coverage
reports, validation evidence, Judgment Day verdict reports **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent QA "<task>"
.\scripts\utilities\gv.ps1 test "<scope>"
.\scripts\utilities\gv.ps1 review --scope judgment-day
.\scripts\utilities\gv.ps1 review --scope judgment-day --target <path>
```

## AGENT-OPS: DevOps & Infrastructure

**Role**: Manages deployment, CI/CD, infrastructure as code. **Skills**: docker-devops-skill,
kubernetes-deployment, terraform-infrastructure, git-workflow-skill, release-management-skill
**Triggers**: deploy, CI/CD, Docker, Kubernetes, infrastructure, Terraform, helm, release, ops,
DevOps **Deliverables**: Docker configurations, Kubernetes manifests, CI/CD pipeline definitions,
deployment runbooks **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent OPS "<task>"
.\scripts\utilities\gv.ps1 deploy "<environment>"
```

## AGENT-GOV: Governance & Observability

**Role**: Ensures compliance, monitors metrics, handles incidents. **Skills**: observability-skill,
incident-response-plan, security-skill, code-review-orchestrator-skill **Triggers**: governance,
compliance, metrics, monitoring, observability, incident, security audit, review, auditoría
**Deliverables**: Audit reports, compliance documentation, incident runbooks, monitoring dashboards
**Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent GOV "<task>"
.\scripts\utilities\gv.ps1 audit
```

## AGENT-DOC: Documentation

**Role**: Creates and maintains all project documentation. **Skills**: documentation-governance,
sdd-skill, github-pr-skill **Triggers**: documentation, docs, README, guide, runbook, BDD specs, SDD
specs, specification **Deliverables**: README files, API documentation, runbooks and guides, BDD/SDD
specifications **Commands**:

```powershell
.\scripts\utilities\gv.ps1 agent DOC "<task>"
.\scripts\utilities\gv.ps1 docs "<type>"
```

