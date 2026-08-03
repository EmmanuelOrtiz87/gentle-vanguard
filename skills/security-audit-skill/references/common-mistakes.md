# Common Mistakes

### 1. Only Running Automated Scanners

Automated tools miss business logic flaws, race conditions, authorization bypasses, and complex
injection chains. Always pair automated scanning with manual testing.

### 2. Ignoring Out-of-Scope Systems

Attackers don't respect scope boundaries. A vuln in an "out of scope" third-party integration can be
a pivot point into the target. Document risks even if you don't test them.

### 3. Not Validating Findings

SAST tools generate false positives. Every finding must be manually verified before it enters the
report. Reporting a false positive erodes trust.

### 4. Vague Remediation Advice

Bad: "Fix the SQL injection." Good: "Replace string concatenation with parameterized queries in
`UserRepository.php` lines 42-58 using PDO prepared statements."

### 5. Skipping Threat Modeling

Finding bugs is reactive. Threat modeling is proactive. Skipping it means you're only finding what
scanners can see.

### 6. Over-relying on CVSS Scores

CVSS doesn't account for business context. A CVSS 6.0 finding on a PII endpoint may be more critical
to your organization than a CVSS 9.0 on a public information page.

### 7. No Retesting

A finding is not resolved until it's verified as fixed. "We fixed it" must be followed by "Show me."

### 8. Poor Communication

Dropping a 200-page report on the engineering team with no summary, no triage guidance, and no
walkthrough leads to findings being ignored or deprioritized.

### 9. No Timeline for Remediation

Without deadlines, critical findings accumulate. Use SLAs: Critical = 24h, High = 1 week, Medium = 1
month, Low = next release.

### 10. Testing Only in Production

By the time a vulnerability is found in production, data may already be compromised. Test in
staging, CI/CD, and development environments.

### 11. Missing Authentication Testing

Don't assume authentication works. Test for session fixation, missing logout, JWT none-algorithm
attacks, and token leakage in URLs/referrers.

### 12. Not Checking for Backups and Shadow IT

Developers often deploy separate staging environments, test APIs, or personal cloud accounts without
security review. Audit for shadow IT.
