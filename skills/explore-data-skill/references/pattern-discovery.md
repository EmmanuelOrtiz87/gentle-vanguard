## Pattern Discovery Techniques

### Distribution Analysis

- **Normal**: Mean ≈ median, bell-shaped
- **Skewed right**: Long tail of high values (common for revenue, session duration)
- **Skewed left**: Long tail of low values
- **Bimodal**: Two peaks (two distinct populations)
- **Power law**: Few large values, many small (common for user activity)
- **Uniform**: Equal frequency across range (synthetic/random)

### Temporal Patterns

- **Trend**: sustained upward/downward movement
- **Seasonality**: repeating weekly/monthly/quarterly/annual patterns
- **Day-of-week effects**: weekday vs weekend
- **Holiday effects**: drops/spikes around known holidays
- **Change points**: sudden level/trend shifts
- **Anomalies**: individual data points breaking the pattern

### Segmentation Discovery

- Find categorical columns with 3-20 distinct values
- Compare metric distributions across segment values
- Look for segments with significantly different behavior
- Test segment homogeneity vs sub-segments

### Correlation Exploration

- Compute correlation matrix for all metric pairs
- Flag strong correlations (|r| > 0.7)
- Note: correlation ≠ causation
- Check for non-linear relationships (quadratic, logarithmic)
