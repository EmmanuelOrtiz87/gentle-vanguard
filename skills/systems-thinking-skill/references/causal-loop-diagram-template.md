# Causal Loop Diagram Template

```
┌──────────────────────────────────────────────────────────────┐
│                    System: [Name]                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│    ┌─────────┐                        ┌─────────┐           │
│    │ Factor  │──────(+)──────────────▶│ Factor  │           │
│    │    A    │                        │    B    │           │
│    └─────────┘                        └────┬────┘           │
│         ▲                                  │                │
│         │                                  │                │
│        (-)                                (+)               │
│         │                                  │                │
│         │         ┌─────────┐              │                │
│         └─────────│ Factor  │◀─────────────┘                │
│                   │    C    │                               │
│                   └─────────┘                               │
│                                                              │
│   Legend: (+) = same direction, (-) = opposite direction    │
│   Loop type: Reinforcing / Balancing                        │
└──────────────────────────────────────────────────────────────┘
```

Use `(+)` for same-direction relationships and `(-)` for opposite-direction relationships. Label
each loop as **Reinforcing** (self-amplifying) or **Balancing** (self-correcting).
