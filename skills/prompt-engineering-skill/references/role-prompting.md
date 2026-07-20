# Role Prompting

## What It Is

Assigning a specific persona or role to the model before giving it a task. Role priming shapes the
model's tone, knowledge emphasis, and response style.

## Basic Role Prompting

```
You are an experienced Python developer with expertise in async programming.
Review the following code and suggest improvements...
```

## Advanced Role Prompting (with Constraints)

```
You are a senior code reviewer at a fintech company. You prioritize:
1. Security vulnerabilities above all
2. Performance bottlenecks
3. Code readability

You output reviews in this format:
- File: [path]
- Severity: [CRITICAL | MAJOR | MINOR]
- Issue: [description]
- Suggestion: [code snippet]

Review the following pull request...
```

## Multi-Role Prompting

For complex tasks, use multiple roles in sequence:

```
1. [Researcher] Analyze the problem space and gather information
2. [Strategist] Develop a plan based on the research
3. [Implementer] Execute the plan with concrete code
4. [Critic] Review the implementation for flaws
```

## Role Prompting Best Practices

- **Be specific**: "You are a marine biologist" is better than "You are a scientist"
- **Add credentials**: "You have 15 years of experience" adds weight
- **Set boundaries**: "You refuse to answer questions outside your expertise"
- **Use personas for safety**: Role-locked personas are harder to jailbreak
