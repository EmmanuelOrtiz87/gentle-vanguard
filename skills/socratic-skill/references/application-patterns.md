# Socratic Questioning — Application Patterns

## For Requirements Gathering

```
Stakeholder: "We need a dashboard."
Clarification: "What decisions will the dashboard help you make?"
Assumptions: "What are we assuming about who will use this?"
Evidence: "What data shows this is the highest priority?"
Perspective: "How do different user roles need different views?"
Implications: "If we build this, what won't we build?"
Meta: "Is a dashboard the best solution, or is there another approach?"
```

## For Debugging

```
Report: "The system is slow."
Clarification: "Which operations are slow? How slow?"
Assumptions: "What are we assuming about where the bottleneck is?"
Evidence: "What metrics/traces support this?"
Perspective: "Is it slow for all users or specific patterns?"
Implications: "If we fix this, what else might change?"
Meta: "Is 'slow' the right frame? Could it be 'inconsistent'?"
```

## For Design Review

```
Proposal: "We should use event sourcing."
Clarification: "What do you mean by event sourcing in this context?"
Assumptions: "What are we assuming about our query patterns?"
Evidence: "What evidence suggests this fits our use case?"
Perspective: "How would ops view this? New team members?"
Implications: "What are the consequences for debugging? Storage?"
Meta: "Is the real question about event sourcing or auditability?"
```
