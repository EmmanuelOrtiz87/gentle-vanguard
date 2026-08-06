# Common Rationalizations

| Rationalization                                                  | Reality                                                                                                                  |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| "It still works, why remove it?"                                 | Working code that nobody maintains accumulates security debt and complexity. Maintenance cost grows silently.            |
| "Someone might need it later"                                    | If it's needed later, it can be rebuilt. Keeping unused code "just in case" costs more than rebuilding.                  |
| "The migration is too expensive"                                 | Compare migration cost to ongoing maintenance cost over 2-3 years. Migration is usually cheaper long-term.               |
| "We'll deprecate it after we finish the new system"              | Deprecation planning starts at design time. By the time the new system is done, you'll have new priorities. Plan now.    |
| "Users will migrate on their own"                                | They won't. Provide tooling, documentation, and incentives — or do the migration yourself (the Churn Rule).              |
| "We can maintain both systems indefinitely"                      | Two systems doing the same thing is double the maintenance, testing, documentation, and onboarding cost.                 |
| "Just rename the column, it's one line"                          | During the rollout, old and new code run together — one will query a column that no longer exists. Expand/contract only. |
| "I'll add the column and drop the old one in the same migration" | Drops get their own deploy, after no code references the old shape.                                                      |
| "We'll write the rollback if we need it"                         | A migration with no down path is a deploy you can't reverse. Write and run the `down` before merging.                    |
