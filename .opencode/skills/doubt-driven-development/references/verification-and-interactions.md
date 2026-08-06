# Verification Checklist

After applying doubt-driven development:

- [ ] Every non-trivial decision (per the definition) was named explicitly as a CLAIM before
      standing
- [ ] At least one fresh-context review per non-trivial artifact (a failing test produced by TDD's
      RED step satisfies this for behavioral claims)
- [ ] The reviewer received ARTIFACT + CONTRACT — NOT the CLAIM, NOT your reasoning
- [ ] The reviewer's prompt was adversarial ("find issues"), not validating ("is it good")
- [ ] Findings were classified against the artifact text (not rubber-stamped) using the precedence:
      contract misread / actionable / trade-off / noise
- [ ] A stop condition was met (trivial findings, 3 cycles, or user override)
- [ ] In interactive mode, cross-model was **explicitly offered** to the user (regardless of
      artifact stakes) and the response was acknowledged in the output
- [ ] In non-interactive mode, cross-model was skipped and the skip was announced
- [ ] Any external CLI invocation was preceded by a PATH check, a working-binary test, syntax
      confirmation with the user, and explicit authorization to run

# Interaction with Other Skills

- **`code-review-and-quality` / `/review`**: complementary. `/review` is post-hoc PR verdict;
  doubt-driven is in-flight per-decision. Use both.
- **`source-driven-development`**: SDD verifies _facts about frameworks_ against official docs.
  Doubt-driven verifies _your reasoning about the artifact_. SDD checks the API exists; doubt-driven
  checks you used it correctly under the contract.
- **`test-driven-development`**: TDD's RED step is doubt made concrete — a failing test is a
  disproof attempt. When TDD applies, that failing test _is_ the doubt step for behavioral claims.
- **`debugging-and-error-recovery`**: when the reviewer surfaces a real failure mode, drop into the
  debugging skill to localize and fix.
- **Repo orchestration rules** (`references/orchestration-patterns.md`): this skill orchestrates
  from the main session. A persona calling another persona is anti-pattern B — see Loading
  Constraints in the main SKILL.md.
