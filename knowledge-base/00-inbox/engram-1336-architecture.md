---
created: 2026-06-05 03:52:34
tags: [engram, architecture]
engram_id: 1336
type: architecture
---

# Community Skills system implementation

**What**: Implemented the complete Community Skills system for Gentle-Vanguard

**Where**:
- Created: `.github/ISSUE_TEMPLATE/skill-contribution.yml`
- Created: `.github/workflows/community-skill-review.yml`
- Updated: `apps/web-dashboard/server/marketplace-api.ts` — replaced mock data with real skills/ directory scanning, added `validateSkillStructure()`, `CreateSkillPayload` interface, `getSkillContent()`
- Created: `apps/web-dashboard/server/marketplace-server-routes.ts` — Express-compatible route handlers for marketplace API
- Updated: `apps/web-dashboard/server/websocket-server.ts` — integrated marketplace API routes into HTTP handler
- Created: `scripts/utilities/SKILLS-TOOLS/submit-community-skill.ps1` — contributor packaging script with validation
- Updated: `apps/web-dashboard/src/components/Marketplace.tsx` — fetches real data from /api/marketplace, added Submit Skill dialog with form validation

**Learned**: The websocket-server.ts uses raw Node.js HTTP (not Express), so marketplace routes had to be integrated manually into handleRequest() rather than mounting an Express router. The marketplace-server-routes.ts is still available as an Express-compatible router for future Express migration.

---
*Imported from Engram on 2026-09-06*
