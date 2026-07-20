## Decision Flow

> Extracted from the original SKILL.md. ASCII decision tree for navigating the model router.

```
START HERE
    │
    ▼
┌─────────────────────┐
│ What's your domain? │
└──────────┬──────────┘
           │
     ┌─────┴─────┬──────────┬──────────┬──────────┐
     ▼           ▼          ▼          ▼          ▼
  Coding    Architecture  Product   Strategy   Personal
     │           │          │          │          │
     ▼           ▼          ▼          ▼          ▼
┌─────────────────────┐
│ What problem type?  │
│ Diagnose/Decide/    │
│ Understand/Create/  │
│ Evaluate/Predict    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Look up in domain   │
│ table above         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Single model enough?│
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
   YES           NO
    │             │
    ▼             ▼
 Apply it    Use Model Combination
             (Sequential/Parallel/Nested)
```
