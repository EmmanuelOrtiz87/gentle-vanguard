# ADR Templates

## Lightweight ADR Template

For quick decisions that still need recording:

```markdown
# ADR-042: Use PostgreSQL for Analytics Store

**Status**: Accepted **Date**: 2024-03-15 **Author**: Alice Chen **Deciders**: Alice Chen, Bob
Smith, Carol Davis

## Context

We need a store for aggregated analytics data. Requirements: JSON support, time-series optimized.

## Decision

Use PostgreSQL with TimescaleDB extension on RDS.

## Rationale

- JSONB for flexible event schemas
- TimescaleDB hypertables for time-series queries
- RDS for managed operations
- Team already familiar with PostgreSQL

## Alternatives

- **MongoDB**: Better for unstructured data, but adds ops complexity → rejected
- **ClickHouse**: Excellent for analytics but overkill for our volume → rejected

## Consequences

- Existing PostgreSQL expertise applies
- Single database reduces operational burden
- - Need to learn TimescaleDB syntax
- - JSONB queries less performant than dedicated document store
```

## Y-Statements

A concise format for decisions with clear tradeoffs:

```markdown
## Decision (Y-Statement)

In the context of {situation/need}, facing {constraint/force}, we decided for {option A} over
{option B} to achieve {positive consequence}, accepting {negative consequence}.

**Example:** In the context of needing real-time notifications across services, facing the
constraint of not wanting to manage a dedicated messaging infrastructure, we decided for AWS SNS
over RabbitMQ to achieve zero operational overhead, accepting vendor lock-in to AWS.
```

## Capturing Rejected Decisions

Sometimes the most valuable ADR is about a decision you _didn't_ take:

```markdown
# ADR-017: Rejected — Migrate to Microservices

**Status**: Rejected **Date**: 2024-02-01

## Context

Proposal to break the monolith into microservices for better scalability.

## Decision

We decided NOT to pursue microservice decomposition at this time.

## Rationale

- Team size (6 engineers) is too small to manage N services
- Current monolith handles 10k RPM comfortably
- Deployment frequency is satisfactory (daily)
- Distributed transactions would add complexity without clear benefit
- We'll revisit when: a) Team grows to 15+ b) Deployment takes >30m c) Features need different
  scaling
```

## ADR Index Template

```markdown
# Architecture Decision Records

## Active (Accepted)

| ADR     | Title                 | Date       | Area |
| ------- | --------------------- | ---------- | ---- |
| ADR-003 | API Protocol: GraphQL | 2024-01-20 | API  |
| ADR-002 | Database: PostgreSQL  | 2024-01-15 | Data |

## Proposed

| ADR     | Title                                    | Date       | Author |
| ------- | ---------------------------------------- | ---------- | ------ |
| ADR-009 | Cache Strategy: Redis with write-through | 2024-03-01 | Alice  |

## Deprecated / Superseded

| ADR     | Title           | Superseded By | Date       |
| ------- | --------------- | ------------- | ---------- |
| ADR-001 | Initial: SQLite | ADR-002       | 2024-01-15 |
```
