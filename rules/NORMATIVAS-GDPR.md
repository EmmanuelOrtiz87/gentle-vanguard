# NORMATIVAS-GDPR — Legal & Data Protection Compliance

**Version**: 1.0.0  
**Last Updated**: 2026-05-15  
**Scope**: Gentle-Vanguard stack, all agents, data processing, user privacy

---

## 1. Principles (MANDATORY)

All AI agents and Gentle-Vanguard systems MUST comply with GDPR Article 5 principles:

1. **Lawfulness, Fairness, Transparency**: Justify processing. Disclose AI decision logic.
2. **Purpose Limitation**: Process data only for declared purposes. NO secondary use without consent.
3. **Data Minimization**: Collect ONLY data necessary for purpose.
4. **Accuracy**: Ensure data is accurate, current, corrected when stale.
5. **Storage Limitation**: Delete/pseudonymize after retention period ends.
6. **Integrity & Confidentiality**: Secure against unauthorized processing or destruction.
7. **Accountability**: Maintain proof of compliance (audit logs, impact assessments).

---

## 2. User Rights (MANDATORY ENFORCEMENT)

### Right to Access (Article 15)
- Users MAY request all personal data Gentle-Vanguard processes about them
- Agent response time: **30 calendar days** (HARD DEADLINE)
- Implementation: `gentle-vanguard privacy export-user-data <user_id>` command
- Output: JSON/CSV with all PII, processing history, retention dates

### Right to Erasure (Article 17 — "Right to be Forgotten")
- Users MAY request deletion of personal data
- Exceptions: Legal obligation, contractual necessity, law enforcement
- Agent response time: **30 calendar days**
- Implementation: `gentle-vanguard privacy delete-user-data <user_id>` command
- Verification: Confirm deletion in audit log within 48 hours

### Right to Rectification (Article 16)
- Users MAY correct inaccurate data
- Agent responds within **14 calendar days**
- Implementation: `gentle-vanguard privacy update-user-data <user_id> <json_patch>`
- Audit log entry: WHO corrected WHAT, WHEN

### Right to Data Portability (Article 20)
- Users MAY export data in machine-readable format (JSON/CSV/Parquet)
- Response time: **30 calendar days**
- Implementation: `gentle-vanguard privacy export-portable <user_id> --format json|csv|parquet`

### Right to Object (Article 21)
- Users MAY opt out of processing for marketing, profiling, automated decisions
- Agent honor opt-out within **5 business days**
- Configuration: Store in `~/.gentle-vanguard/privacy-preferences.json`

---

## 3. Data Processing (MANDATORY)

### Processing Agreement
- Every data processing operation MUST have explicit legal basis
- Basis categories: Consent, Contract, Legal Obligation, Vital Interest, Public Task, Legitimate Interest
- Agent logs basis + timestamp for every operation: `[GDPR] Processing <data_type> via <basis>`

### Consent Management (Where Required)
- Before collecting PII: Obtain explicit, informed, freely-given, specific consent
- Store consent record: `{ user_id, data_type, timestamp, consent_version, duration }`
- Consent duration default: **365 days** (renewable annually)
- Withdrawal: Users may withdraw anytime via `gentle-vanguard privacy revoke-consent <data_type>`

### Automated Decision-Making (Article 22 — CRITICAL)
- NO fully automated decisions affecting user rights WITHOUT transparency + opt-out
- Example: Auto-delete old sessions, auto-disable accounts, auto-flag as spam
- For ALL automated decisions: Provide explanation + right to human review
- Implementation: Add `explainability` field to decision log
  ```json
  {
    "decision": "session_auto_deleted",
    "reasoning": "inactivity > 180 days",
    "affected_user": "user_id",
    "right_to_review": "gentle-vanguard privacy request-human-review <decision_id>",
    "timestamp": "2026-05-15T16:00:00Z"
  }
  ```

---

## 4. Data Retention (MANDATORY)

### Default Retention Periods
| Data Type | Retention | Reason |
|-----------|-----------|--------|
| Session logs | 90 days | Debugging + security |
| Audit logs | 2 years | Legal requirement |
| User PII | Until deletion request | User consent |
| Error telemetry | 30 days | Performance analysis |
| Payment/billing | 7 years | Tax/legal requirement |
| Learning logs (Engram) | 365 days | Model improvement (consent-based) |

### Retention Enforcement
- Automated purge every 30 days: `gentle-vanguard privacy purge-expired-data`
- Verify purge: `gentle-vanguard privacy audit-retention-compliance`
- Output: List of deleted records, timestamps, audit trail

---

## 5. Data Breach Response (MANDATORY)

### Incident Classification
- **LOW**: <10 users affected, no PII exposed → Log only
- **MEDIUM**: 10-1000 users, limited PII → Notify users + authorities within 72h
- **CRITICAL**: >1000 users OR sensitive categories (health, race, financial) → IMMEDIATE escalation

### Response Protocol (72-Hour Requirement)
1. **Identify** breach scope (who, what data, when discovered)
2. **Contain** immediately (revoke tokens, freeze accounts if necessary)
3. **Notify** Gentle-Vanguard security team + legal (within 2 hours)
4. **Assess** risk to individuals
5. **Notify** supervisory authority (WITHIN 72 HOURS) if required by Article 33
6. **Notify** affected users if high risk (WITHIN 72 HOURS) — Article 34
7. **Document** incident: Root cause, remediation, prevention measures

### Breach Notification Template
```
Subject: Data Breach Notification — Gentle-Vanguard [INCIDENT_ID]

Dear [User],
On [DATE], we discovered a security incident affecting [X] user accounts.
Affected data: [LIST DATA TYPES]
We have taken the following measures: [ACTIONS]
You can request more details: gentle-vanguard privacy breach-details [INCIDENT_ID]
Supervisory authority notification: [AUTHORITY], [DATE]
```

---

## 6. Data Protection Impact Assessment (DPIA) (MANDATORY for High-Risk)

### Trigger: Run DPIA If
- New AI agent introduced
- Processing logic changes significantly
- Large-scale PII collection begins
- Automated decision-making implemented
- Data shared with third parties

### DPIA Sections (Required)
1. **Purpose**: Why process this data?
2. **Necessity**: Is it minimized? Could purpose be achieved with less data?
3. **Risk Assessment**: What could go wrong? (unauthorized access, data loss, profiling, discrimination)
4. **Mitigation**: How reduce risks? (encryption, access controls, audit logging)
5. **Legal Basis**: What justifies this processing?
6. **Third-Party Transfers**: If sharing data, what are safeguards?

### Implementation
```powershell
gentle-vanguard privacy run-dpia --agent <agent_name> --scope <data_types> --output report.json
```

---

## 7. Third-Party Processors (MANDATORY)

### Processor Agreements
- Every third-party service (cloud, analytics, logging) MUST sign DPA (Data Processing Agreement)
- DPA checklist: Security measures, sub-processor approval, data deletion, audit rights
- Store all DPAs: `config/dpas/<processor_name>.json`

### Sub-Processor Changes
- Gentle-Vanguard MUST notify users if sub-processors change
- User opt-out right: If user disagrees, delete account/data on demand
- Update audit trail: `[GDPR] Sub-processor changed: <old> → <new>, users notified [TIMESTAMP]`

---

## 8. Vendor Audit Requirements

### Annual Audit Checklist
- [ ] All consent records valid + auditable
- [ ] No data retention exceeded
- [ ] All deletion requests honored
- [ ] Breach response documented + timely
- [ ] DPIA completed for new processing
- [ ] Third-party DPAs current
- [ ] Encryption keys managed securely
- [ ] Access logs complete (who accessed what, when)

### Audit Command
```powershell
gentle-vanguard privacy audit-gdpr --year 2026 --output audit-report-2026.md
```

---

## 9. Agent Compliance Requirements

### Per-Agent Checklist (MANDATORY BEFORE DEPLOYMENT)
- [ ] Disclose what data I collect
- [ ] Justify legal basis for processing
- [ ] Implement right to access (export user data)
- [ ] Implement right to erasure (delete user data)
- [ ] Log all PII processing with timestamp + basis
- [ ] No decision-making about users without explainability
- [ ] No unauthorized third-party sharing
- [ ] Encrypt PII at rest + in transit
- [ ] Comply with 30/72-hour response times
- [ ] Document retention policy

### Deployment Gate: GDPR Compliance Validator
```powershell
gentle-vanguard privacy validate-agent-compliance <agent_name>
```
Exit code 0 = Compliant; Exit code 1 = BLOCK deployment

---

## 10. Monitoring & Enforcement

### Automated Compliance Checks (DAILY)
1. Scan audit logs for unlogged PII processing
2. Verify retention purge ran successfully
3. Check for unauthorized third-party access
4. Alert on any consent violations

### Command
```powershell
gentle-vanguard privacy monitor-daily --alert-email compliance@gentle-vanguard.local
```

---

## References

- GDPR (General Data Protection Regulation): https://gdpr-info.eu/
- Article 5 (Principles): https://gdpr-info.eu/art-5-gdpr/
- Article 15-21 (User Rights): https://gdpr-info.eu/chapter-3/
- Article 22 (Automated Decision-Making): https://gdpr-info.eu/art-22-gdpr/
- Article 33-34 (Breach Notification): https://gdpr-info.eu/art-33-gdpr/

---

**Status**: MANDATORY — All agents MUST comply by 2026-06-01  
**Violation**: Non-compliance blocks production deployment  
**Review Cycle**: Annual + quarterly updates per emerging regulations

