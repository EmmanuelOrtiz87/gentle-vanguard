# Release & Versioning

Commits are how _you_ track change; a **version** is how your _consumers_ track it. The moment
anything else depends on your code — another team, a published package, a deployed client — "latest
on main" stops being a sufficient answer to "what am I running, and is it safe to upgrade?" A
version number and a changelog are the contract that answers it.

## Semantic Versioning

For anything with consumers, version `MAJOR.MINOR.PATCH` and let the number carry meaning:

```
  MAJOR  breaking change — consumers must change their code to upgrade
  MINOR  new functionality, backward-compatible — safe to upgrade
  PATCH  bug fix, backward-compatible — safe to upgrade
```

The number is a promise, so make the code match it. A "patch" that changes behavior consumers relied
on is a major change wearing a disguise (Hyrum's Law — see the `api-and-interface-design` skill).
When unsure whether a change is breaking, assume it is; a surprise major is far cheaper than a
broken consumer.

## Tag the Release, and Let the Tag Be the Source of Truth

A release is an immutable point in history, not a moving branch. Tag it so it can always be
reproduced:

```bash
git tag -a v1.4.0 -m "Release 1.4.0"
git push origin v1.4.0
```

Derive the version from the tag rather than hand-editing it in scattered files, so the artifact, the
tag, and the changelog can never disagree.

## Keep a Changelog Written for Humans

A changelog is not `git log`. It's the curated, consumer-facing answer to "what changed and do I
care?" — grouped by `Added / Changed / Fixed / Deprecated / Removed / Security`, newest on top,
every entry phrased around user impact, not internal mechanics.

```markdown
## [1.4.0] - 2025-06-12

### Added

- Bulk task import via CSV

### Fixed

- Timezone drift in recurring task due dates

### Deprecated

- `GET /v1/tasks/all` — use the paginated `GET /v1/tasks` (removal in 2.0)
```

Write the entry in the same change that makes the change, while the impact is fresh — not
reconstructed from commit archaeology at release time. Breaking changes get a migration note and a
deprecation window (follow the `deprecation-and-migration` skill); shipping the actual release is
the `shipping-and-launch` skill's job — this section is the versioning contract that feeds it.
