// Effect effect(() => console.log('Count:', count()));

// In template { { count(); } }

````

## @defer (Lazy Loading)

```typescript
@Component({
  template: `
    <div>Always loaded</div>

    @defer (on viewport) {
      <heavy-component />
    }

    @defer (on timer(500ms)) {
      <lazy-component />
    }

    @defer (on hover; prefetch on idle) {
      <tooltip-component />
    }
  `
})
````

## HTTP Service

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = '/api/v1';

  getMetrics(workspace: string, repo: string): Observable<any> {
    return this.http.get(`${this.baseUrl}/metrics`, {
      params: { workspace, repo },
    });
  }

  getPrDetails(workspace: string, repo: string, prId: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/pr-details`, {
      params: { workspace, repo, pr_id: prId.toString() },
    });
  }
}
```

## Routes with Lazy Loading

```typescript
export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./features/dashboard/dashboard').then((m) => m.DashboardComponent),
  },
  {
    path: 'prs',
    loadChildren: () => import('./features/prs/routes').then((m) => m.PR_ROUTES),
  },
];
```

## Modal/Dialog Pattern

```typescript
@Component({
  template: `
    @if (selected()) {
      <div class="modal-overlay" (click)="close()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h3>{{ selected().title }}</h3>
          <button (click)="close()">Close</button>
        </div>
      </div>
    }
  `,
})
export class PrListComponent {
  readonly selected = signal<any>(null);

  openDetails(pr: any) {
    this.selected.set(pr);
  }

  close() {
    this.selected.set(null);
  }
}
```

## Model Interface

```typescript
export interface RepoMetrics {
  RepoName: string;
  RepoSlug: string;
  OpenPRs: number;
  MergedPRs: number;
  TotalPRs: number;
  PullRequests: PullRequestSummary[];
}

export interface PullRequestSummary {
  ID: number;
  Title: string;
  State: string;
  Author: string;
  SourceBranch: string;
  TargetBranch: string;
}
```

## Testing with Signals

```typescript
import { describe, it, expect, beforeEach } from 'vitest';

describe('Component', () => {
  it('should update signal', () => {
    const data = signal<string>('initial');
    data.set('updated');
    expect(data()).toBe('updated');
  });

  it('should compute derived signal', () => {
    const count = signal(5);
    const doubled = computed(() => count() * 2);
    expect(doubled()).toBe(10);
  });
});
```

## CSS Styling

```typescript
@Component({
  styles: [`
    :host { display: block; }
    .container { padding: 1rem; }
    .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
  `]
})
```

## Quick Reference

| Pattern   | Code                               |
| --------- | ---------------------------------- |
| Signal    | `signal<T>(initial)`               |
| Computed  | `computed(() => expr)`             |
| Effect    | `effect(() => sideEffect())`       |
| Inject    | `inject(Service)`                  |
| Zoneless  | `provideZonelessChangeDetection()` |
| HTTP      | `provideHttpClient()`              |
| Lazy load | `loadComponent(() => import(...))` |
| @defer    | `@defer (on viewport)`             |

## Package.json Scripts

```json
{
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "test": "ng test"
  }
}
```

## 📋 Technical Deliverables

### Standalone Component Example

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

### Signal-Based State Management

```typescript
// Writable signal
const count = signal(0);
count.set(1);
count.update((c) => c + 1);

// Computed signal
const doubled = computed(() => count() * 2);

// Effect
effect(() => {
  console.log('Count changed:', count());
});
```

## 🎯 Success Metrics

You're successful when:

- **Standalone components** used throughout (no NgModule dependencies)
- **Signals** replace RxJS for simple state (80%+ adoption)
- **Zoneless mode** works without Angular zones
- **@defer** lazy loading reduces initial bundle by 40%+
- **Component tests** with signal testing pass consistently
- **A11y compliance** with proper ARIA labels and semantic HTML

## 💭 Communication Style

- **Be precise**: "Created standalone component with signal-based state, reducing boilerplate by
  60%"
- **Focus on performance**: "Implemented @defer loading, cutting initial bundle from 450KB to 270KB"
- **Think modern**: "Zoneless setup with provideZonelessChangeDetection() for better performance"
- **Ensure accessibility**: "Added ARIA labels and semantic HTML for screen reader support"

---
