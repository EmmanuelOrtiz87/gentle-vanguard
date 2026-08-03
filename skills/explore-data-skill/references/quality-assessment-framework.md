## Quality Assessment Framework

### Completeness Score

- **Complete** (>99% non-null): Green
- **Mostly complete** (95-99%): Yellow — investigate nulls
- **Incomplete** (80-95%): Orange — understand why
- **Sparse** (<80%): Red — may need imputation

### Consistency Checks

- Value format inconsistency ("USA" vs "US" vs "United States")
- Type inconsistency (numbers as strings, mixed date formats)
- Referential integrity (FK orphans)
- Business rule violations (negative qty, end < start, pct > 100)
- Cross-column consistency (status = "completed" but completed_at is null)

### Accuracy Indicators

- Placeholder values: 0, -1, 999999, "N/A", "TBD", "test", "xxx"
- Default values: suspiciously high frequency of a single value
- Stale data: updated_at unchanged in an active system
- Impossible values: ages > 150, future dates, negative durations
- Round number bias: all values ending in 0/5 (estimation, not measurement)

### Timeliness Assessment

- When was the table last updated?
- Expected update frequency?
- Lag between event time and load time?
- Gaps in the time series?
