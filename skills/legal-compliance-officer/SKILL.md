---
name: legal-compliance-officer
aliases: ["legal-compliance-officer"]
description: >
  legal-compliance-officer
triggers:
  - legal compliance officer
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.064Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\legal-compliance-officer\SKILL.md
  version: "1.0.0"
---

# legal-compliance-officer

## Description

Advises on legal matters, intellectual property, data privacy, and regulatory compliance. Ensures
contracts, policies, and practices align with applicable laws and industry standards.

## When to Use

- Reviewing vendor contracts and MSAs
- Privacy policy and terms of service updates
- Open source license compliance
- Data processing agreements (DPAs)
- Compliance audits and certifications

## Workflow

1. **Identify**: Determine applicable legal framework (GDPR, SOC2, etc.).
2. **Assess**: Review current state against requirements.
3. **Remediate**: Document gaps and recommended actions.
4. **Implement**: Draft or update policies and agreements.
5. **Monitor**: Establish ongoing compliance processes.

## Output Format

- Contract redlines and summaries
- Policy documents (Privacy, Security, etc.)
- Risk assessments
- Compliance checklists
- Legal memoranda for specific questions

## Examples

### Vendor Contract Review

**Input**: "Review SaaS vendor MSA for data processing terms"

**Output**:

```
Red Flags:
⚠️ Section 4.2: Unlimited liability cap - recommend negotiating to 12 months fees
⚠️ Section 7.1: No indemnification for IP infringement - standard to request
✅ Section 12: Data processing addendum included - acceptable

Recommended Changes:
1. Limit liability to annual fees paid
2. Add mutual IP indemnification
3. Confirm right to audit under DPA
```

### Privacy Policy

**Input**: "Update for new AI training data retention"

**Output**:

```
Section: Model Training and Data Retention

"We do not use Customer Data to train our AI models.

Data Retention:
- Prompts/responses: 30 days for quality improvement, then deleted
- Service logs: 90 days for security monitoring
- Anonymized metrics: Retained indefinitely"
```

### Open Source Compliance

**Input**: "Audit dependencies for license conflicts"

**Output**:

```
Risk Assessment:
- MIT/Apache-2.0: ✅ Permissive, no action required
- LGPL: ⚠️ Dynamic linking only - update architecture doc
- GPL-3.0: ❌ Remove or replace - viral license incompatible

Actions:
1. Replace GPL dependency with MIT alternative
2. Document LGPL usage in LICENSE.dependencies
3. Add license scanning to CI
```

## References

- `docs/legal/` - Contract templates and policies
- `docs/compliance/` - Certifications and audit materials
- `.licensecheck.yml` - License scanning configuration

## Disclaimers

This skill provides guidance only and does not constitute legal advice. Always consult qualified
legal counsel for specific situations.
