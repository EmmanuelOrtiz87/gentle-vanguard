# Increment Checklist

After each increment, verify:

- [ ] The change does one thing and does it completely
- [ ] All existing tests still pass (`npm test`)
- [ ] The build succeeds (`npm run build`)
- [ ] Type checking passes (`npx tsc --noEmit`)
- [ ] Linting passes (`npm run lint`)
- [ ] The new functionality works as expected
- [ ] The change is committed with a descriptive message

**Note:** Run each verification command after a change that could affect it. After a successful run,
don't repeat the same command unless the code has changed since.

## Common Rationalizations

| Rationalization                                      | Reality                                                                                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| "I'll test it all at the end"                        | Bugs compound. A bug in Slice 1 makes Slices 2-5 wrong. Test each slice.                          |
| "It's faster to do it all at once"                   | It _feels_ faster until something breaks and you can't find which of 500 changed lines caused it. |
| "These changes are too small to commit separately"   | Small commits are free. Large commits hide bugs.                                                  |
| "I'll add the feature flag later"                    | If the feature isn't complete, it shouldn't be user-visible. Add the flag now.                    |
| "This refactor is small enough to include"           | Refactors mixed with features make both harder to review and debug.                               |
| "Let me run the build command again just to be sure" | After a successful run, repeating adds nothing unless the code has changed.                       |

## Red Flags

- More than 100 lines of code written without running tests
- Multiple unrelated changes in a single increment
- "Let me just quickly add this too" scope expansion
- Skipping the test/verify step to move faster
- Build or tests broken between increments
- Large uncommitted changes accumulating
- Building abstractions before the third use case demands it
- Touching files outside the task scope "while I'm here"
- Creating new utility files for one-time operations
- Running the same build/test command twice without any intervening code change

## Verification

After completing all increments for a task:

- [ ] Each increment was individually tested and committed
- [ ] The full test suite passes
- [ ] The build is clean
- [ ] The feature works end-to-end as specified
- [ ] No uncommitted changes remain
