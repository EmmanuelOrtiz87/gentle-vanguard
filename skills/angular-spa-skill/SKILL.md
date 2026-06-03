---
name: angular-spa-skill
description: >
  Angular 19+ SPA patterns: signals, zoneless, standalone components, defer loading. Trigger:
  "Angular", "Angular component", "Angular service", "Angular signal", "Angular SPA", "@defer",
  "standalone component".
metadata:
  source: GV-native
---

## When to Use

- Creating Angular components
- Using signals for state management
- Setting up zoneless change detection
- Lazy loading with @defer
- Angular HTTP services

## Project Structure

```
src/app/
 core/
    models/           # Interfaces
    services/         # API services (injectable)
 features/
    feature-name/
        feature.ts     # Component
        feature.spec.ts # Tests
 app.config.ts         # App providers
 app.routes.ts         # Routes
 app.ts               # Root component
```

## Standalone Component

```typescript
import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../../core/services/api.service';

@Component({
  selector: 'app-feature',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (loading()) {
      <div class="loading">Loading...</div>
    } @else if (data()) {
      <div>{{ data().name }}</div>
    } @else {
      <div class="empty">No data</div>
    }
  `,
  styles: [
    `
      .loading {
        color: #666;
      }
      .empty {
        color: #999;
      }
    `,
  ],
})
export class FeatureComponent {
  private readonly api = inject(ApiService);
  readonly data = signal<any>(null);
  readonly loading = signal(false);

  constructor() {
    this.loadData();
  }

  loadData() {
    this.loading.set(true);
    this.api.getData().subscribe({
      next: (data) => {
        this.data.set(data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
```

## App Config (Zoneless)

```typescript
import { ApplicationConfig, provideZonelessChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [provideZonelessChangeDetection(), provideRouter(routes), provideHttpClient()],
};
```

## Signals Pattern

```typescript
// Writable signal
const count = signal(0);
count.set(1);
count.update((c) => c + 1);

// Computed signal
const doubled = computed(() => count() * 2);

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
