# Common Patterns to Catch

### The Blame Stop

```
BAD: "Why did it fail?" → "Engineer didn't test properly" → STOP

BETTER: → "Why was it possible to deploy without proper testing?"
        → "Why doesn't the pipeline enforce testing?"
        → System/process root cause
```

### The Premature Technical Stop

```
BAD: "Why was it slow?" → "Query was inefficient" → STOP

BETTER: → "Why was an inefficient query in production?"
        → "Why didn't code review catch it?"
        → "Why don't we have query performance testing?"
```

### The Circular Why

```
DETECT: "Why A?" → "Because B" → "Why B?" → "Because A"

BREAK: Introduce external evidence or third factor
```

### The Speculation Dive

```
DETECT: Answers become increasingly speculative without evidence

BREAK: "What evidence do we have for this?"
       If none, mark as hypothesis and seek evidence
```
