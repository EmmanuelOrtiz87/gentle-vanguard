# Audit Methodology

A structured audit follows five phases:

```
[SCOPE] → [RECON] → [TESTING] → [REPORTING] → [REMEDIATION]
```

## Phase 1: Scope Definition

Before any testing begins, define the boundaries:

- **In scope:** Specific domains, API endpoints, source code repositories, cloud accounts.
- **Out of scope:** Production databases (unless approved), third-party services, employee personal
  devices.
- **Testing window:** Define start/end dates and business hours for active testing.
- **Rules of engagement:** No social engineering, no DDoS, no data exfiltration outside approved
  channels.

**Deliverable:** Scope document signed by both auditor and stakeholder.

## Phase 2: Reconnaissance

Gather information about the target:

- **Passive recon:** DNS records, subdomain enumeration (Amass, Subfinder), HTTP headers, technology
  fingerprinting (Wappalyzer, whatweb).
- **Active recon:** Port scanning (Nmap), directory brute-force (ffuf, dirbuster), endpoint
  discovery.
- **Code review:** SAST scanning, hardcoded secrets detection (truffleHog, Gitleaks).
- **Dependency analysis:** SCA scanning for known CVEs.

**Commands:**

```bash
# Subdomain enumeration
subfinder -d example.com -o subdomains.txt

# Port scanning
nmap -sV -sC -p- -oA nmap_scan example.com

# Directory brute-force
ffuf -u https://example.com/FUZZ -w /usr/share/wordlists/dirb/common.txt

# Secret scanning (git repo)
gitleaks detect --source=./repo --report=gitleaks-report.json
```

## Phase 3: Testing

Execute both automated and manual testing:

- **Automated:** SAST (Semgrep, SonarQube), DAST (ZAP, Burp Suite Pro), dependency scanning (Trivy,
  Snyk).
- **Manual:** Business logic flaws, privilege escalation, IDOR, race conditions, authentication
  bypass.
- **Validation:** Reproduce every automated finding to eliminate false positives.

**Test case documentation:**

```markdown
## Test Case: A01-IDOR-001

**Target:** GET /api/orders/123 **Auth:** User A (low privilege) **Expected:** 403 Forbidden (not
your order) **Actual:** Returns order data for order 456 after changing ID **Severity:** High (CVSS
7.5) **Evidence:** [screenshot] [curl_output.txt]
```

## Phase 4: Reporting

See `references/reporting-format.md` for the complete template.

## Phase 5: Remediation

- Track each finding with a unique ID.
- Assign severity (CVSS), owner, and target fix date.
- Re-test after fixes are deployed.
- Close only after verification.
