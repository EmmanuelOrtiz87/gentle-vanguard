# User Story Writing

Good user stories are:

- **Independent**: Can be developed and delivered on their own
- **Negotiable**: Details can be discussed, the story is not a contract
- **Valuable**: Delivers value to the user (not just the team)
- **Estimable**: The team can roughly estimate the effort
- **Small**: Can be completed in one sprint/iteration
- **Testable**: There is a clear way to verify it works

## Common Mistakes in User Stories

- Too vague: "As a user, I want the product to be faster" — what specifically should be faster?
- Solution-prescriptive: "As a user, I want a dropdown menu" — describe the need, not the UI widget
- No benefit: "As a user, I want to click a button" — why? What does it accomplish?
- Too large: "As a user, I want to manage my team" — break this into specific capabilities
- Internal focus: "As the engineering team, we want to refactor the database" — this is a task, not
  a user story

# Requirements Categorization

## MoSCoW Framework

- **Must have**: Without these, the feature is not viable. Non-negotiable.
- **Should have**: Important but not critical for launch. High-priority fast follows.
- **Could have**: Desirable if time permits. Will not delay delivery if cut.
- **Won't have (this time)**: Explicitly out of scope. May revisit in future versions.

## Tips for Categorization

- Be ruthless about P0s. The tighter the must-have list, the faster you ship and learn.
- If everything is P0, nothing is P0. Challenge every must-have: "Would we really not ship without
  this?"
- P1s should be things you are confident you will build soon, not a wish list.
- P2s are architectural insurance — they guide design decisions even though you are not building
  them now.

# Acceptance Criteria

Write acceptance criteria in Given/When/Then format or as a checklist:

**Given/When/Then**:

- Given [precondition or context]
- When [action the user takes]
- Then [expected outcome]

Example:

- Given the admin has configured SSO for their organization
- When a team member visits the login page
- Then they are automatically redirected to the organization's SSO provider

**Checklist format**:

- [ ] Admin can enter SSO provider URL in organization settings
- [ ] Team members see "Log in with SSO" button on login page
- [ ] SSO login creates a new account if one does not exist
- [ ] SSO login links to existing account if email matches
- [ ] Failed SSO attempts show a clear error message

## Tips for Acceptance Criteria

- Cover the happy path, error cases, and edge cases
- Be specific about the expected behavior, not the implementation
- Include what should NOT happen (negative test cases)
- Each criterion should be independently testable
- Avoid ambiguous words: "fast", "user-friendly", "intuitive" — define what these mean concretely
