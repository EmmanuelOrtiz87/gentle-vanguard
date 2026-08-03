# Inversion Examples — Reference

## Application Patterns

### Technical Design

```
Goal: Build scalable API
Invert: How to make it fail under load?
- No caching → Add caching layer
- Synchronous everything → Add async where appropriate
- No connection pooling → Implement pooling
- N+1 queries → Eager loading, query optimization
- No circuit breakers → Add circuit breakers
```

### Code Review

```
Goal: Merge high-quality code
Invert: What would make this PR problematic?
- Introduces security vulnerability
- Breaks existing functionality
- No tests for new behavior
- Unclear intent/poor naming
- Performance regression
- Missing error handling
```

### Career/Team Building

```
Goal: Build successful engineering career
Invert (Munger's list of what to avoid):
- Be unreliable
- Learn only from your own mistakes (ignore others')
- Give up after first failure
- Be resentful and envious
- Stay within comfort zone
- Avoid difficult conversations
- Don't learn continuously
```

### Project Planning

```
Goal: Successful product launch
Invert: How to guarantee launch failure?
- No user research → Validate with users
- No load testing → Load test before launch
- No rollback capability → Build rollback
- No success metrics defined → Define metrics upfront
- Team burnout → Sustainable pace
- No communication plan → Prepare stakeholder comms
```

## Common Inversions for Software

| Domain          | Goal             | Key Inversions to Avoid                                    |
| --------------- | ---------------- | ---------------------------------------------------------- |
| Security        | Secure system    | Trusting user input, weak auth, exposed secrets            |
| Performance     | Fast system      | No caching, blocking calls, no indexes                     |
| Reliability     | Stable system    | No monitoring, no redundancy, no graceful degradation      |
| Maintainability | Clean code       | No tests, cryptic names, tight coupling                    |
| Team            | High performance | Poor communication, no psychological safety, unclear goals |
