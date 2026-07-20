# Common Pitfalls

## Rationalizations

| Rationalization                                            | Reality                                                                                                                           |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| "I'll add logging after it works"                          | "After" becomes "after the first incident", which is the most expensive moment to discover you're blind.                          |
| "More logs = more observability"                           | Unstructured noise makes incidents slower. Three queryable events beat three hundred prose lines.                                 |
| "console.log is fine for now"                              | Unstructured output can't be filtered, correlated, or alerted on. The structured logger costs five extra minutes once.            |
| "We can just look at dashboards when something breaks"     | Dashboards without defined questions show you everything except the answer.                                                       |
| "Alert on everything important, we'll tune later"          | A noisy pager trains people to ignore it. The tuning never happens; the missed real page does.                                    |
| "User ID as a metric label makes debugging easier"         | It also makes your metrics backend fall over. High-cardinality belongs in logs and traces.                                        |
| "Tracing is overkill for our two services"                 | Two services already means cross-service latency questions logs can't answer. Auto-instrumentation makes the cost trivial.        |

## Red Flags

- A feature PR with retries, queues, or external calls and zero new telemetry
- Log lines built by string interpolation instead of structured fields
- No correlation/request ID — each log line is an orphan
- Metrics labeled with user IDs, raw URLs, or error message text (cardinality bomb)
- Latency tracked as an average with no percentiles
- Alerts that fire daily and get acknowledged without action
- Alerts on causes (CPU, memory) paging humans while user-facing error rate is unmonitored
- Secrets, tokens, or full request bodies appearing in logs
- "It works on my machine" as the only evidence a production feature is healthy
