# Common System Patterns

## Cascading Failure

```
One component fails → Dependent components overload → They fail
                                                     ↓
                              ← More traffic to remaining ←
```

**Mitigation:** Circuit breakers, bulkheads, graceful degradation

## Thundering Herd

```
Cache expires → All requests hit backend simultaneously → Overload
```

**Mitigation:** Jittered expiration, cache warming, request coalescing

## Queue Backup

```
Processing rate < Arrival rate → Queue grows → Memory pressure → OOM
```

**Mitigation:** Backpressure, rate limiting, queue bounds

## Resource Contention

```
Multiple processes → Same resource → Lock contention → Serialization
                                                     ↓
                    Throughput collapses despite available CPU
```

**Mitigation:** Sharding, optimistic locking, resource isolation
