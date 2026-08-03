---
name: deprecation-and-migration
description: Manage deprecation and migration. Remove old systems, migrate users between implementations, decide on feature sunsetting.
triggers:
  - deprecate
  - migration
  - sunset
  - legacy
  - migrate
---

# Deprecation and Migration

## Overview

Code is a liability — every line has ongoing maintenance cost. Deprecation removes code that no
longer earns its keep. Migration moves users safely from old to new.

## When to Use

- Replacing old systems, APIs, or libraries
- Sunsetting features, consolidating duplicates, removing zombie code
- Planning lifecycle at design time (not after the replacement is built)
- Deciding whether to maintain legacy or invest in migration

## Core Principles

1. **Code Is a Liability.** Every line needs tests, docs, patches, updates, and mental overhead.
   Value is the *functionality*, not the code itself.
2. **Hyrum's Law.** With enough users, every behavior is depended on — bugs, timing, side effects.
   Deprecation requires active migration, not just announcements.
3. **Plan at Design Time.** Ask "how would we remove this in 3 years?" when building something new.
   Clean interfaces and feature flags make deprecation cheaper.

## The Deprecation Decision

Before deprecating: Does it still provide unique value? How many consumers? Does a replacement exist?
What's the migration cost vs. the ongoing cost of *not* deprecating?

See [`references/deprecation-decision.md`](references/deprecation-decision.md) for the full 5-question
decision framework.

## Compulsory vs Advisory

| Type | When | Mechanism |
|------|------|-----------|
| **Advisory** | Migration optional, system stable | Warnings, docs, nudges. Users migrate on their own timeline. |
| **Compulsory** | Security risk, blocks progress, cost unsustainable | Hard deadline + migration tooling, docs, and support |

**Default to advisory.** Compulsory requires providing migration tooling and support — you can't just
announce a deadline.

## The Migration Process

1. **Build the replacement** — proven in production, covering critical use cases
2. **Announce and document** — deprecation notice with status, replacement, and migration guide
3. **Migrate incrementally** — one consumer at a time; verify each before moving on
4. **Remove the old system** — only after zero active usage is confirmed

**The Churn Rule:** If you own the deprecated system, you are responsible for migrating your users.

See [`references/migration-process.md`](references/migration-process.md) for full details.

## Migration Patterns

- **Strangler Pattern** — Run old + new in parallel, route traffic incrementally
- **Adapter Pattern** — Old interface wraps new implementation; consumers don't change
- **Feature Flag Migration** — Switch consumers one at a time via flags
- **Expand/Contract (DB Schema)** — Add columns first, backfill, dual-write, then drop

See [`references/migration-patterns.md`](references/migration-patterns.md) for code examples and
the full Expand/Contract worked example.

## Zombie Code

Code nobody owns but everybody depends on — no commits in 6+ months, no maintainer, failing tests,
unpatched vulnerabilities. Either assign an owner and maintain it, or deprecate with a migration plan.

See [`references/zombie-code.md`](references/zombie-code.md).

## Common Rationalizations

"It still works", "someone might need it", "the migration is too expensive", "users will migrate" —
common refutations live in [`references/common-rationalizations.md`](references/common-rationalizations.md).

## Red Flags & Verification

Deprecating without a replacement, zombie code with no owner, adding features to deprecated systems,
schema changes shipped in the same deploy as code changes, migrations with no down path.

See the full checklist at [`references/red-flags-and-verification.md`](references/red-flags-and-verification.md).