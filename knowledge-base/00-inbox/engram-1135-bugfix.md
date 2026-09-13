---
created: 2026-05-26 01:47:50
tags: [engram, bugfix]
engram_id: 1135
type: bugfix
---

# Fixed compact toggle + double-toggle + banner bugs

**What**: 6 bugs fixed in token notification system
- **Compact toggle broken**: `-Enable/-Disable -Type compact` and `toggle -Type compact` had no "compact" case in `Update-IndividualToggle` switch. Fix: added direct `$config.compactMode = $val` branches in both paths.
- **Master toggle missing compactMode**: `/notif on`/`/notif toggle` only set individualToggles, not `$config.compactMode`. Fix: added `$config.compactMode = $val` in -Type all branches.
- **Banner literal-text bug**: `` `$((35-$label.Length).ToString().PadLeft(1)) `` printed literal text instead of evaluating. Fix: replaced with `$padding = " " * (41 - $label.Length)`.
- **Double-toggle bug**: toggle-token-display.ps1 called `& $tokenNotifier -Action toggle` AFTER `Save-Config`, and the notifier's `Toggle-Display` function toggled `$config.enabled` AGAIN — undoing the save. Fix: removed the redundant notifier call from toggle-token-display.ps1.
- **Notifier leaked boolean**: `Toggle-Display` had `return $config.enabled` which leaked `True`/`False` to stdout. Fix: removed return value.
- **Notifier banner misaligned**: Had ugly if/else for ENABLED/DISABLED padding. Fix: replaced with `$padding = " " * (22 - $status.Length)` single-line pattern.

**Why**: User demanded no warnings, no errors, no incomplete items, nothing partial.

**Where**: scripts/utilities/toggle-token-display.ps1, scripts/utilities/token-usage-notifier.ps1:120-138

**Learned**:
- The notifier's Toggle-Display was independently toggling AND saving $config.enabled — a dual source of bugs. Rule: only one script should own toggle logic; the other should only display.
- The `return $value` pattern in PowerShell functions leaks to stdout when the caller uses `&` instead of `$null = &`.
- Compact mode is stored at top level in config ($config.compactMode), NOT in individualToggles — it's display format, not content type. Any toggle logic must handle it separately.

---
*Imported from Engram on 2026-09-06*
