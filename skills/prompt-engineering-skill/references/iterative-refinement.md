# Iterative Refinement

## The Prompt Engineering Loop

```
1. Draft Prompt → 2. Test Output → 3. Evaluate → 4. Refine → 5. Repeat
```

## Common Refinement Strategies

**Strategy 1: Add Constraints**

```
Before: "Write a summary."
After:  "Write a 3-sentence summary.
         Sentence 1: What happened.
         Sentence 2: Why it matters.
         Sentence 3: What happens next."
```

**Strategy 2: Provide a Skeleton**

```
Before: "Write a blog post."
After:  "Fill in this outline:
         ## The Problem
         [2-3 sentences describing the pain point]

         ## The Solution
         [3-4 sentences describing your approach]

         ## The Results
         [2-3 sentences with specific metrics]"
```

**Strategy 3: Negative Constraints**

```
"Analyze this code. Do NOT suggest:
- Rewriting the entire codebase
- Switching languages or frameworks
- Adding dependencies unless absolutely necessary"
```

**Strategy 4: Chain of Draft** For complex tasks, break into smaller sub-prompts and chain them
together:

```
1. "Summarize this document in 200 words."
2. "Based on the summary, identify the 3 key decisions made."
3. "Format these decisions as a JSON array with 'decision' and 'rationale' fields."
```
