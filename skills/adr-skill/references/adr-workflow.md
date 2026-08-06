# ADR Workflow

```text
┌────────────┐   ┌──────────────┐   ┌────────────┐   ┌───────────────┐
│  Identify  │   │   Draft     │   │  Review   │   │   Accept &   │
│ Decision  ─┼─► │   ADR      ─┼─► │  & Discuss│──►│   Commit    │
│ Needed    │   │  (Proposed) │   │           │   │  (Accepted)  │
└────────────┘   └──────────────┘   └────────────┘   └───────────────┘
                                           │                  │
                                           │  Rejected        │  Later
                                           ▼                  ▼
                                     ┌──────────┐     ┌──────────────┐
                                     │  Revise  │     │  Superseded  │
                                     │  or File │     │  by New ADR  │
                                     └──────────┘     └──────────────┘
```

## Step 1: When to Write an ADR

Write an ADR when the decision:

- **Is significant**: Changes the architecture, not just implementation
- **Is irreversible**: Hard to undo (database, framework, cloud provider)
- **Has tradeoffs**: No obvious "right" answer
- **Will be referenced later**: Someone will ask "why?"
- **Involves cost**: Financial, operational, or opportunity cost

**ADR-worthy examples:** Choosing a database/message-queue/cache, adopting a framework, API design
(REST vs GraphQL vs gRPC), deployment strategy, data model changes, security architecture.

**Non-ADR examples:** Renaming a variable, adding a minor dependency, bug fixes, config changes.

## Step 2: Draft the ADR

```bash
mkdir -p docs/adr/
cp templates/adr-template.md docs/adr/ADR-043-use-graphql-for-public-api.md
# ADR naming: ADR-{NNN}-{short-descriptive-slug}.md
```

## Step 3: Review

Include in the same PR as implementation or as standalone PR. Reviewers should check:

- Is the context clear? Can a new member understand the problem?
- Are alternatives fairly represented?
- Are consequences honestly assessed?
- Is the decision aligned with existing architecture?
- Are there better alternatives we haven't considered?

## Step 4: Accept and Maintain

After acceptance, status changes to "Accepted". If revisited:

```markdown
## Status

Superseded by ADR-052

## Rationale for Deprecation

In 2024, a managed Kafka service became available that eliminates the operational overhead that
motivated our original SQS choice.
```

## Storing ADRs with Code

```
project/
├── docs/
│   └── adr/
│       ├── index.md              # Catalog of all ADRs
│       ├── ADR-001-initial-project-structure.md
│       ├── ADR-002-database-selection.md
│       └── ...
└── .adr-dir                      # Points to the ADR directory
```

**Why in-repo:** Version controlled alongside code, visible in same PRs, found by new team members
exploring the codebase, branch-specific ADRs for experiments.
