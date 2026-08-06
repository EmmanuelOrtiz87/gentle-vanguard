# Advanced: Blind Comparison

For rigorous comparison between two skill versions (e.g., "is the new version actually better?"),
use the blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md` for details.

The basic idea: give two outputs to an independent agent without telling it which is which, and let
it judge quality. Then analyze why the winner won.

This is optional, requires subagents, and most users won't need it. The human review loop is usually
sufficient.
