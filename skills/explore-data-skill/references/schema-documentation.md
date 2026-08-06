## Schema Understanding and Documentation

### Schema Documentation Template

```markdown
## Table: [schema.table_name]

**Description**: [What this table represents] **Grain**: [One row per...] **Primary Key**:
[column(s)] **Row Count**: [approximate, with date] **Update Frequency**: [real-time / hourly /
daily / weekly] **Owner**: [team or person]

### Key Columns

| Column     | Type      | Description                | Example Values              | Notes                        |
| ---------- | --------- | -------------------------- | --------------------------- | ---------------------------- |
| user_id    | STRING    | Unique user identifier     | "usr_abc123"                | FK to users.id               |
| event_type | STRING    | Type of event              | "click", "view", "purchase" | 15 distinct values           |
| revenue    | DECIMAL   | Transaction revenue in USD | 29.99, 149.00               | Null for non-purchase events |
| created_at | TIMESTAMP | When event occurred        | 2024-01-15 14:23:01         | Partitioned on this column   |

### Relationships

- Joins to `users` on `user_id`
- Joins to `products` on `product_id`
- Parent of `event_details` (1:many on event_id)

### Known Issues & Common Query Patterns

Document gotchas, quality issues, and typical use cases.
```

### Schema Exploration Queries (PostgreSQL)

```sql
-- List tables in a schema
SELECT table_name, table_type FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;

-- Column details
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'my_table' ORDER BY ordinal_position;

-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;
```

### Lineage and Dependencies

1. Start with output tables (what reports/dashboards consume)
2. Trace upstream: what tables feed into them?
3. Identify raw/staging/mart layers
4. Map the transformation chain
5. Note where data is enriched, filtered, or aggregated
