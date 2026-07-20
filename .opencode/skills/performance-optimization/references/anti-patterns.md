# Common Anti-Patterns

> Part of [`performance-optimization`](../SKILL.md). Fix these before micro-optimizing.

## Bottleneck Identification

### Frontend

| Symptom           | Likely Cause                                                 | Investigation                         |
| ----------------- | ------------------------------------------------------------ | ------------------------------------- |
| Slow LCP          | Large images, render-blocking resources, slow server         | Check network waterfall, image sizes  |
| High CLS          | Images without dimensions, late-loading content, font shifts | Check layout shift attribution        |
| Poor INP          | Heavy JavaScript on main thread, large DOM updates           | Check long tasks in Performance trace |
| Slow initial load | Large bundle, many network requests                          | Check bundle size, code splitting     |

### Backend

| Symptom            | Likely Cause                                         | Investigation                    |
| ------------------ | ---------------------------------------------------- | -------------------------------- |
| Slow API responses | N+1 queries, missing indexes, unoptimized queries    | Check database query log         |
| Memory growth      | Leaked references, unbounded caches, large payloads  | Heap snapshot analysis           |
| CPU spikes         | Synchronous heavy computation, regex backtracking    | CPU profiling                    |
| High latency       | Missing caching, redundant computation, network hops | Trace requests through the stack |

## N+1 Queries (Backend)

```typescript
// BAD: N+1 — one query per task for the owner
const tasks = await db.tasks.findMany();
for (const task of tasks) {
  task.owner = await db.users.findUnique({ where: { id: task.ownerId } });
}

// GOOD: Single query with join/include
const tasks = await db.tasks.findMany({
  include: { owner: true },
});
```

## Unbounded Data Fetching

```typescript
// BAD: Fetching all records
const allTasks = await db.tasks.findMany();

// GOOD: Paginated with limits
const tasks = await db.tasks.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

## Missing Image Optimization (Frontend)

```html
<!-- BAD: No dimensions, no format optimization -->
<img src="/hero.jpg" />

<!-- GOOD: Hero / LCP image — art direction + resolution switching, high priority -->
<picture>
  <!-- Mobile: portrait crop (8:10) -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/avif"
  />
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.webp 400w, /hero-mobile-800.webp 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/webp"
  />
  <!-- Desktop: landscape crop (2:1) -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/avif"
  />
  <source
    srcset="/hero-800.webp 800w, /hero-1200.webp 1200w, /hero-1600.webp 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/webp"
  />
  <img
    src="/hero-desktop.jpg"
    width="1200"
    height="600"
    fetchpriority="high"
    alt="Hero image description"
  />
</picture>

<!-- GOOD: Below-the-fold image — lazy loaded + async decoding -->
<img
  src="/content.webp"
  width="800"
  height="400"
  loading="lazy"
  decoding="async"
  alt="Content image description"
/>
```

## Unnecessary Re-renders (React)

```tsx
// BAD: Creates new object on every render, causing children to re-render
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// GOOD: Stable reference
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// Use React.memo for expensive components
const TaskItem = React.memo(function TaskItem({ task }: Props) {
  return <div>{/* expensive render */}</div>;
});

// Use useMemo for expensive computations
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return (
    <div>
      {stats.completed} / {stats.total}
    </div>
  );
}
```

## Large Bundle Size

```typescript
// Tree-shaking automatically handles named imports with ESM + sideEffects: false.
// Profile before changing import styles — real gains come from splitting and lazy loading.

// GOOD: Dynamic import for heavy, rarely-used features
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// GOOD: Route-level code splitting wrapped in Suspense
const SettingsPage = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```

## Missing Caching (Backend)

```typescript
// Cache frequently-read, rarely-changed data
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) {
    return cachedConfig;
  }
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// HTTP caching headers for static assets
app.use(
  '/static',
  express.static('public', {
    maxAge: '1y',
    immutable: true,
  }),
);

// Cache-Control for API responses
res.set('Cache-Control', 'public, max-age=300');
```
