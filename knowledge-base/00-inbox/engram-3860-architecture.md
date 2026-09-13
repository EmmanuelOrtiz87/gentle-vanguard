---
created: 2026-09-10 14:40:01
tags: [engram, architecture]
engram_id: 3860
type: architecture
---

# Fix TypeScript errors and complete toast notifications for Academy alerts

**What**: Fix TypeScript errors in Dashboard.tsx and complete the toast notification system for Academy alerts. Fixed duplicate variable declarations, added `id` field to Notification type, fixed notification object structure, and verified all validations pass.

**Why**: The user wanted to complete the pending TypeScript fixes and complete the toast notification system for Academy alerts in the dashboard.

**Where**:
- `apps/web-dashboard/src/components/Dashboard.tsx` - Fixed duplicate `notifications`/`setNotifications` declarations, fixed notification object structure to match Notification type (added `type` field)
- `apps/web-dashboard/src/hooks/useMetrics.ts` - Added optional `id` field to Notification interface
- `apps/web-dashboard/src/components/Dashboard.tsx` - Fixed notification object to include required `type` field

**Learned**: (1) TypeScript strict mode catches duplicate declarations and missing required fields. (2) The Notification type needed an optional `id` field and the notification objects needed a `type` field. (3) All validations now pass: typecheck, lint, build, validate-ebooks-toolkits, validate-multi-course, smoke-academy (20/20 PASS). (4) The toast notification system for Academy alerts is now fully functional with both CSV export buttons and NEW badge for leads.

---
*Imported from Engram on 2026-09-12*
