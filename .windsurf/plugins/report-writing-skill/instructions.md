# report-writing-skill

> Gentle-Vanguard Skill

## Description
Bug bounty report writing for H1/Bugcrowd/Intigriti/Immunefi — templates, human tone, impact-first writing, CVSS 3.1 scoring, title formula, severity guide, downgrade counters, checklist. Never use "could potentially".

## Triggers


## Instructions
# REPORT WRITING

Impact-first. Human tone. No theoretical language. Triagers are people.

---

## THE MOST IMPORTANT RULE

> **Never use "could potentially" or "could be used to" or "may allow".** Either it does the thing or it doesn't.

BAD: "could potentially allow an attacker to access user data."
GOOD: "An attacker can access any user's order history by changing the user_id parameter. Confirmed using two test accounts (attacker@test.com ID 123 retrieved victim@test.com ID 456 orders, shipping address, payment last 4)."

---

## TITLE FORMULA

`[Bug Class] in [Endpoint] allows [role] to [impact] [scope]`

**Good:** IDOR in /api/v2/invoices/{id} allows user to read any customer's invoices | Missing auth on POST /api/admin/users allows unauthenticated admin creation | SSRF via image import reaches AWS metadata | Race condition in coupon redemption allows unlimited use

**Bad:** IDOR vulnerability found / Broken access control / XSS in user input / Security issue in API

---

## PLATFORM TEMPLATES

See `references/`:
- `hackerone-template.md` — Summary → Steps → Impact → Fix
- `bugcrowd-template.md` — VRT → Title → Body → Remediation
- `intigriti-template.md` — Summary → PoC → Impact → Rec
- `immunefi-template.md` — Working PoC → Walkthrough → Impact

---

## CVSS & SEVERITY

See `references/cvss-scoring.md`, `references/severity-guide.md`, `references/downgrade-counters.md`, `references/pre-submit-checklist.md`

---

## STEPS TO REPRODUCE

**Setup:** Account A (attacker), Account B (victim) — normal accounts
**Steps:** Login → Send request with victim ID → Show response with victim's data
**Expected:** 403 | **Actual:** 200 OK. Include copy-paste-ready HTTP request in code block.

---

## HUMAN TONE

- Get to impact in sentence 1. Use "I" not "the researcher".
- Short paragraphs, bullet points for steps.
- **Escalation:** "Only a free account required" / "PII subject to GDPR" / "Automate all N records in minutes"
- **Avoid:** Jargon, IDOR explanations, theoretical chains, passive voice, "seems to" / "appears to"

---

## RELATED SKILLS

- **`triage-validation`** — Never write before 7-Question Gate passes
- **`bugcrowd-reporting`** — VRT selection + severity-request overlay
- **`evidence-hygiene`** — Cookie/PII redaction before attaching artifacts
- **`redteam-report-template`** — Red team engagements (not bug bounty)
- **`bb-methodology`** — Phase 5 loads this skill for platform template

---

## OPERATOR NOTES (Claude-BugHunter)

**Title in practice:** `<asset> | <bug class> | <impact>` — triagers read in ~3s.

**Reading sequence:** Title(3s) → First paragraph(15s) → HTTP request(30s) → Steps → Rest. Optimize top ruthlessly.

**Severity mismatch:** CVSS, platform default, VRT disagree ~30%. File severity-request paragraph anchored in vector + business impact.

**Evidence:** Throwaway accounts, rotate tokens per submission, redact screenshots, no production PII.

**Biggest mistake:** Claiming "could be chained to" without demonstrating it. Show end-to-end or downgrade claim.
