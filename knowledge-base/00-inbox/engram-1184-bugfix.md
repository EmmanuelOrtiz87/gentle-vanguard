---
created: 2026-05-27 19:16:11
tags: [engram, bugfix]
engram_id: 1184
type: bugfix
---

# Dashboard: Suppress browser extension errors

**What**: Added console.error override to suppress browser extension errors (ad-blockers, password managers, etc.)

**Why**: User was seeing 'A listener indicated an asynchronous response by returning true, but the message channel closed before a response was received' errors during auto-refresh. These errors come from browser extensions, not from dashboard code.

**Where**: reports/dashboard-v2/app.js (lines 1-12)

**Learned**:
- This error is caused by browser extensions (ad-blockers, password managers, etc.) that use chrome extension messaging APIs
- The dashboard code is not the source - it's external extensions interfering
- Solution: Override console.error to filter out these specific extension-related error messages
- Dashboard functionality is completely unaffected by these errors

---
*Imported from Engram on 2026-09-06*
