# Common Rationalizations

| Rationalization                           | Reality                                                                                                                                                            |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "I'm confident about this API"            | Confidence is not evidence. Training data contains outdated patterns that look correct but break against current versions. Verify.                                 |
| "Fetching docs wastes tokens"             | Hallucinating an API wastes more. The user debugs for an hour, then discovers the function signature changed. One fetch prevents hours of rework.                  |
| "The docs won't have what I need"         | If the docs don't cover it, that's valuable information — the pattern may not be officially recommended.                                                           |
| "I'll just mention it might be outdated"  | A disclaimer doesn't help. Either verify and cite, or clearly flag it as unverified. Hedging is the worst option.                                                  |
| "This is a simple task, no need to check" | Simple tasks with wrong patterns become templates. The user copies your deprecated form handler into ten components before discovering the modern approach exists. |
