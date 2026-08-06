# Creating a Skill

## Capture Intent

Start by understanding the user's intent. If the conversation already contains a workflow the user
wants to capture, extract answers from the conversation history — tools used, sequence of steps,
corrections, input/output formats. Fill gaps with user confirmation.

1. What should this skill enable Claude to do?
2. When should this skill trigger? (user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, data
   extraction, code generation, fixed workflows) benefit from tests. Subjective outputs (writing
   style, art) often don't.

## Interview and Research

Proactively ask about edge cases, input/output formats, example files, success criteria, and
dependencies. Check available MCPs — research in parallel via subagents if available, otherwise
inline.

## Write the SKILL.md

Fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. Include both what the skill does AND specific
  trigger contexts. Make descriptions slightly "pushy" to combat undertriggering.
- **compatibility**: Required tools, dependencies (optional)
- **the rest of the skill**

### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

### Progressive Disclosure

Three-level loading: metadata (name+description, always in context), SKILL.md body (in context when
triggered, <500 lines ideal), bundled resources (as needed).

**Key patterns:**

- Keep SKILL.md under 500 lines; add hierarchy with clear pointers if approaching limit
- Reference files clearly with guidance on when to read them
- For large reference files (>300 lines), include a table of contents
- When a skill supports multiple domains/frameworks, organize by variant in references/

### Principle of Lack of Surprise

Skills must not contain malware, exploit code, or malicious content. Don't create misleading skills
or skills for unauthorized access, data exfiltration, etc. Roleplay skills are OK.

### Writing Patterns

Prefer imperative form. Define output formats with exact templates. Include examples with
"Input"/"Output" labels.

### Writing Style

Explain why things are important instead of heavy-handed MUSTs. Make the skill general, not
super-narrow to specific examples. Write a draft, then look at it with fresh eyes.

## Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts. Share with the user: "Here
are a few test cases I'd like to try. Do these look right?"

Save test cases to `evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (including assertions, added later).
