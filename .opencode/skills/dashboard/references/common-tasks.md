# Common Tasks

## Adding a Metric Card

1. Add metric to `types/dashboard.ts` (e.g., `DashboardData.cost.byModel`)
2. Compute in `server/real-data.ts` — read from `.state.json`
3. Add API endpoint in `server/websocket-server.ts` or extend existing
4. Display in `Dashboard.tsx` using `MetricsCard` with `infoKey`
5. Add translations to `useLocale.ts` (3 languages)
6. Verify: `cd apps/web-dashboard && npm run build`

## Adding an Alert Rule

1. Add entry to `config/dashboard-alerts.json` (threshold, direction, severity)
2. Add evaluation in `websocket-server.ts` `/api/alerts` handler
3. Test both `direction: "above"` and `direction: "below"` scenarios

## Adding i18n Language

1. Add language entries for all 14 metrics in `useLocale.ts`
2. Add flag emoji to language selector in `Dashboard.tsx`
3. Test language switch in browser

## Testing Checklist

- [ ] Dashboard loads with real data on cold refresh
- [ ] WebSocket indicator shows green
- [ ] HTTP fallback works when WS server is killed
- [ ] Language switch works (EN → ES → PT-BR)
- [ ] Info popup opens on ℹ click, closes on Escape / click-outside
- [ ] Alerts evaluate correctly (both directions)
- [ ] Feedback thumbs persist to `.runtime/metrics/feedback.json`
- [ ] `npm run build` exits 0
- [ ] Session pipeline auto-starts WS server (`dashboard-ws-start` step)
