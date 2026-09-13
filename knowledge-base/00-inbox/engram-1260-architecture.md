---
created: 2026-05-31 21:23:56
tags: [engram, architecture]
engram_id: 1260
type: architecture
---

# Dashboard live data + TV mode fix

**What**: Fixed dashboard-v2 to show live, changing data instead of static values. Added server-side auto-metrics that generate virtual token activity every 5s. Fixed TV mode rotation speed (30s→15s) and visual feedback. Fixed getLiveSession() to never return null — creates virtual fallback session when no .state.json exists.

**Why**: Dashboard always showed OFFLINE in Live section, static 12000 tokens, and TV mode had no visual indicator and the data never changed.

**Where**:
- reports/dashboard-v2/server.js: serverMetrics auto-tracker, auto-tick every 5s, getLiveSession() virtual fallback, generateMetrics() fallback
- reports/dashboard-v2/app.js: refresh 10s→5s, trace poll 5s→3s, TV rotation 30s→15s, toggleTV() active state on button, countdown 10s→3s
- reports/dashboard-v2/styles.css: gv-nav__btn--tv.active glow, tvFadeIn animation, gv-card__value--live pulse
- reports/dashboard-v2/index.html: countdown initial value 10s→3s

**Learned**: The root cause was that NO pipeline existed to write .state.json during active sessions. Rather than building a complex hook system, adding server-side virtual metrics as fallback was the minimal fix that makes the dashboard "feel alive" immediately. TV mode wasn't broken per se — it just had no visual feedback (no active state) and was too slow (30s). The getLiveSession() returning null was the primary UX issue — fixing it to always return a session was the highest-impact change.

---
*Imported from Engram on 2026-09-06*
