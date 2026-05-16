# NORMATIVAS-SOC2 — Enterprise Trust & Security Compliance

**Version**: 1.0.0  
**Last Updated**: 2026-05-15  
**Scope**: Gentle-Vanguard stack, all agents, security operations, audit trail

---

## 1. SOC2 Trust Service Criteria Overview

Gentle-Vanguard MUST comply with **5 Trust Service Principles**:

| Principle | Focus | Status |
|-----------|-------|--------|
| **CC** (Security) | Protect against unauthorized access | MANDATORY |
| **A** (Availability) | Ensure uptime/business continuity | MANDATORY |
| **PI** (Processing Integrity) | Data accuracy & completeness | MANDATORY |
| **C** (Confidentiality) | Protect sensitive data | MANDATORY |
| **PR** (Privacy) | Respect user privacy rights | MANDATORY (GDPR-linked) |

---

## 2. Security (CC) Compliance (MANDATORY)

### CC1: Governance & Risk Management
- Establish security governance policy: `/config/security-policy.json`
- Risk assessments: Quarterly (automated via `gentle-vanguard security assess-risks`)
- Authority & accountability: Document responsible parties in each policy
- Implementation:
  ```powershell
  gentle-vanguard security validate-governance
  # Outputs: Governance matrix, risk register, authority map
  ```

### CC2: Communication & Responsibility
- Every agent MUST document:
  - What security controls they implement
  - What data they protect
  - Who is responsible (security owner, agent owner)
- Location: `agent-security-charter.json` per agent
- Review cycle: Quarterly

### CC3: Risk Assessment & Response
- Automated risk scanning: Daily via `/scripts/utilities/security-risk-scanner.ps1`
- Risk levels: LOW, MEDIUM, HIGH, CRITICAL
- Response SLAs:
  - CRITICAL: Escalate within 1 hour
  - HIGH: Mitigate within 24 hours
  - MEDIUM: Plan fix within 1 week
  - LOW: Log + track

### CC4: Design of System Changes
- Every new feature/component MUST include:
  - Threat model (STRIDE analysis)
  - Security design review (peer-reviewed)
  - Pre-deployment security testing
- Implementation: `gentle-vanguard security design-review <feature_name>`

### CC5: Access Controls (MANDATORY)
- Principle of Least Privilege: Every agent gets MINIMUM required permissions
- Role-based access (RBAC): Define roles in `/config/access-control.json`
- Multi-factor authentication: REQUIRED for production access
- Session timeout: 60 minutes idle → automatic logout
- Audit logging: Every access logged with WHO/WHAT/WHEN/WHERE

**Implementation**:
```powershell
gentle-vanguard security enforce-access-controls
# Outputs: Access violation log, unauthorized attempts, remediation actions
```

### CC6: Logical Access Controls
- Authentication: Token-based (JWT) or API key with rotation
- Authorization: Verify permissions before every privileged action
- Encryption keys: Stored in secure vault (`/keys/`), NOT in code
- Session management: Revoke tokens on logout + timeout

### CC7: System Monitoring & Intrusion Detection
- Enable logging on ALL security-relevant events
- Automated alerting for:
  - Failed authentication attempts (>3 in 5 min)
  - Privilege escalation attempts
  - Data exfiltration patterns
  - Unauthorized file access
- Command: `gentle-vanguard security enable-siem-integration --provider splunk|elk|datadog`

### CC8: Encryption & Secrets Management
- Data at rest: AES-256 minimum (scripts encrypted via `protect-gentle-vanguard.ps1`)
- Data in transit: TLS 1.3 minimum
- Secrets: Never commit to git. Use vault:
  ```powershell
  gv secret set --key API_TOKEN --value <token> --ttl 90d
  gv secret get --key API_TOKEN  # Logged to audit trail
  ```
- Key rotation: Every 90 days (automated)

### CC9: Disaster Recovery & Backup
- Backup frequency: Daily (incremental), Weekly (full)
- Backup testing: Monthly full restore drill
- RTO (Recovery Time Objective): 4 hours max
- RPO (Recovery Point Objective): 24 hours max (no data loss >24h)
- Implementation: `gentle-vanguard backup verify --last-backup-age-hours 24`

---

## 3. Availability (A) Compliance (MANDATORY)

### A1: System Performance & Monitoring
- Uptime target: 99.5% SLA (max 3.6 hours downtime/month)
- Monitor: Response time, throughput, resource utilization
- Alerting: If response time >1s OR throughput <100 req/s, escalate
- Command: `gentle-vanguard monitoring validate-availability-sla --month 2026-05`

### A2: Redundancy & Failover
- Critical components: Deployed in N+1 (minimum 2 instances)
- Failover mechanism: Automatic redirect to healthy instance (<5s detection)
- Load balancing: Distribute traffic evenly

### A3: Capacity Planning
- Monitor: CPU, memory, disk usage trends
- Threshold: Alert if >80% utilization
- Quarterly forecast: Predict capacity needs 90 days ahead
- Command: `gentle-vanguard capacity plan --forecast-days 90`

---

## 4. Processing Integrity (PI) Compliance (MANDATORY)

### PI1: Data Accuracy & Completeness
- Input validation: All user input validated + sanitized
- Error detection: Catch processing errors before persistence
- Correction procedures: Fix corrupted/incomplete data automatically
- Command: `gentle-vanguard integrity validate-data --scope <domain>`

### PI2: Authorized Processing
- Segregation of duties: Approval role separate from execution
- Audit trail: Every data modification logged (WHO/WHAT/WHEN/WHY)
- Recovery procedures: Rollback to last known-good state on error
- Implementation: `gentle-vanguard integrity audit-segregation-of-duties`

---

## 5. Confidentiality (C) Compliance (MANDATORY)

### C1: Classification & Handling
- Data classification: PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED
- Handling rules: Apply different controls per classification level
- Implementation: Every config/script has `@confidentiality_level` comment

### C2: Encryption & Obfuscation
- All PII encrypted at rest (AES-256)
- Logs: Redact sensitive data (passwords, tokens, API keys)
- Masking: In dev/test environments, use fake data not production PII

### C3: Access Restrictions
- Confidential data: Access ONLY with explicit approval + MFA
- Audit access: Log every confidential data access with context
- Revocation: Remove access immediately on employee departure

### C4: Third-Party Access
- Contracts: Every third party MUST sign NDA + DPA
- Monitoring: Detect unauthorized third-party access
- Restrictions: NO cross-sharing between tenants (if multi-tenant)

---

## 6. Privacy (PR) Compliance (GDPR-Linked, MANDATORY)

See **NORMATIVAS-GDPR.md** for full privacy requirements. SOC2 PR principle covers:
- User consent for data processing
- Right to access, rectification, erasure
- Breach notification procedures
- Data retention + deletion
- Third-party processor management

---

## 7. Agent-Level Security Requirements

### Pre-Deployment Security Checklist (BLOCKING)
- [ ] Security policy documented + reviewed
- [ ] Threat model completed (STRIDE)
- [ ] Access controls implemented (least privilege)
- [ ] Encryption enabled for sensitive data
- [ ] Logging enabled for all security events
- [ ] Error handling: NO sensitive data in error messages
- [ ] Input validation: ALL external inputs validated
- [ ] Dependencies scanned for vulnerabilities
- [ ] SAST/DAST testing passed
- [ ] Peer security review approved

### Deployment Gate: Security Compliance Validator
```powershell
gentle-vanguard security validate-agent-soc2 <agent_name>
```
Exit code 0 = Compliant; Exit code 1 = BLOCK deployment

---

## 8. Automated Compliance Monitoring

### Daily Compliance Checks (MANDATORY)
```powershell
gentle-vanguard compliance check-soc2-daily
```

Checks performed:
1. All privileged actions logged? ✓
2. Encryption keys rotated on schedule? ✓
3. Failed access attempts <threshold? ✓
4. Backup completed successfully? ✓
5. System uptime within SLA? ✓

### Weekly Audit Report
```powershell
gentle-vanguard compliance audit-soc2-weekly --report audit-week-$(Get-Date -UFormat %U-%Y).json
```

### Annual SOC2 Audit Preparation
```powershell
gentle-vanguard compliance prepare-soc2-audit --year 2026
# Outputs: Audit evidence bundle (documentation, logs, test results, remediation proof)
```

---

## 9. Incident Response (CRITICAL)

### Classification & Response Times
| Severity | Definition | Response SLA | Escalation |
|----------|-----------|--------------|-----------|
| P1 | Service down, data compromised | 15 min | CISO + Exec |
| P2 | Partial degradation, sensitive data access anomaly | 1 hour | Security team |
| P3 | Minor issue, low risk | 24 hours | Team lead |
| P4 | Informational, compliance tracking | 1 week | Compliance |

### Incident Response Process
1. **Detect** → Automated alerts + manual reports
2. **Triage** → Classify severity + impact
3. **Contain** → Stop ongoing damage (revoke access, isolate systems)
4. **Investigate** → Root cause analysis, scope assessment
5. **Remediate** → Fix vulnerability + apply patches
6. **Communicate** → Notify stakeholders + customers per policy
7. **Document** → Post-incident review, prevention measures

### Command
```powershell
gentle-vanguard incident report --severity P1 --description "Unauthorized access to PII database"
# Triggers: Automated escalation, stakeholder notification, audit logging
```

---

## 10. Compliance Auditing & Reporting

### Quarterly Compliance Report
```powershell
gentle-vanguard compliance generate-report --quarter Q2-2026 --format pdf
```

Report contents:
- Security incidents + response times
- Access control violations + corrective actions
- Encryption key rotations + audit
- Backup success rate + recovery drills
- Third-party security assessments
- Risk register + mitigation progress
- Recommendation dashboard

### Annual Attestation
SOC2 Type II audit (annual third-party validation) to produce:
- **Management Attestation**: Confirms controls are operating effectively
- **Auditor Report**: Independent validation of compliance
- **Certificates**: Issued by Big 4 firm or qualified auditor

---

## 11. Success Metrics (KPIs)

| Metric | Target | Review |
|--------|--------|--------|
| MTTR (Mean Time To Respond to incidents) | <1 hour | Weekly |
| MTRR (Mean Time To Resolve) | <4 hours | Weekly |
| System uptime | 99.5% | Daily |
| Failed login attempts blocked | 100% | Daily |
| Data encryption compliance | 100% | Daily |
| Backup success rate | 100% | Daily |
| Audit log completeness | 100% | Weekly |
| Risk remediation on-time | >95% | Monthly |

---

## References

- SOC2 Trust Services Principles: https://www.aicpa.org/soc-2
- AICPA Trust Services Criteria: https://www.aicpa.org/interestareas/informationsystems/pages/soc-2-service-organization-control.aspx
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
- OWASP Top 10: https://owasp.org/www-project-top-ten/

---

**Status**: MANDATORY — All agents MUST comply by 2026-06-01  
**Violation**: Non-compliance blocks production deployment  
**Audit Cycle**: Continuous automated checks + Annual SOC2 Type II audit

