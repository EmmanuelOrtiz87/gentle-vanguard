# Safe Fallback Patterns and Instrumentation

---

## Safe Fallback Patterns

When under time pressure, use safe fallbacks instead of crashing:

```typescript
// Safe default + warning (instead of crashing)
function getConfig(key: string): string {
  const value = process.env[key];
  if (!value) {
    console.warn(`Missing config: ${key}, using default`);
    return DEFAULTS[key] ?? '';
  }
  return value;
}

// Graceful degradation (instead of broken feature)
function renderChart(data: ChartData[]) {
  if (data.length === 0) {
    return <EmptyState message="No data available for this period" />;
  }
  try {
    return <Chart data={data} />;
  } catch (error) {
    console.error('Chart render failed:', error);
    return <ErrorState message="Unable to display chart" />;
  }
}
```

---

## Instrumentation Guidelines

Add logging only when it helps. Remove it when done.

### When to Add Instrumentation

- You can't localize the failure to a specific line
- The issue is intermittent and needs monitoring
- The fix involves multiple interacting components

### When to Remove It

- The bug is fixed and tests guard against recurrence
- The log is only useful during development (not in production)
- It contains sensitive data (always remove these)

### Permanent Instrumentation (Keep)

- Error boundaries with error reporting
- API error logging with request context
- Performance metrics at key user flows
