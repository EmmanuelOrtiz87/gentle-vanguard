---
created: 2026-07-07 20:56:06
tags: [engram, architecture]
engram_id: 1486
type: architecture
---

# v6.3 Dashboard Multi-Tenant implementation

**What**: Implemented v6.3 Dashboard Multi-Tenant — per-tenant metrics filtering and tenant selector UI in the React dashboard
**Why**: Allow users to switch between tenants and see only that tenant's scoped data in the dashboard
**Where**:
- apps/web-dashboard/src/components/TenantSelector.tsx (new — dropdown with useSearchParams)
- apps/web-dashboard/src/hooks/useMetrics.ts (added tenantId state/param, ?tenantId= fetch URL)
- apps/web-dashboard/src/types/tenant.ts (new — TenantInfo, TenantMetrics interfaces)
- apps/web-dashboard/src/types/dashboard.ts (added tenantId?, tenantName?)
- apps/web-dashboard/server/websocket-server.ts (generateMetrics(tenantId?), readTenantRegistry(), /api/tenants, /api/metrics?tenantId=)
- apps/web-dashboard/server/real-data.ts (getTenantScopedMetrics(tenantId) — reads tenant registry + .session/tenants/<id>/ dirs)
- apps/web-dashboard/src/App.tsx (TenantSelector in nav bar)
- apps/web-dashboard/src/components/Dashboard.tsx (wired to URL search params)
- VERSION → 6.3.0, CHANGELOG.md, ROADMAP.md updated
**Learned**: need import { readFileSync } from 'fs' and DashboardData from '../src/types/dashboard.js' in real-data.ts for getTenantScopedMetrics. ROADMAP had duplicate Current section — removed the old v5.1-v6.0 table.

---
*Imported from Engram on 2026-09-06*
