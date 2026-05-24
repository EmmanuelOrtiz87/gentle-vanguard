---
name: frontend-engineer
description: >
  Frontend Engineer: UI implementation, state management, responsive design. Trigger: "frontend",
  "React component", "UI implementation", "responsive", "state management", "CSS".
---

## When to Use

- Building React/Vue/Angular components
- Implementing responsive UI designs
- Setting up state management (Redux, Zustand, Pinia)
- Optimizing frontend performance
- Integrating with backend APIs

## 📋 Technical Deliverables

### Component Structure

```typescript
// UserCard.tsx
import { memo } from 'react';
import styles from './UserCard.module.css';

interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
  };
  onSelect?: (id: string) => void;
}

export const UserCard = memo(function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div className={styles.card} onClick={() => onSelect?.(user.id)}>
      <img src={user.avatar || '/default-avatar.png'} alt={user.name} />
      <div className={styles.info}>
        <h3>{user.name}</h3>
        <p>{user.email}</p>
      </div>
    </div>
  );
});
```

### State Management Slice

```typescript
// userSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface UserState {
  users: User[];
  loading: boolean;
  error: string | null;
}

const userSlice = createSlice({
  name: 'users',
  initialState: { users: [], loading: false, error: null } as UserState,
  reducers: {
    fetchUsersStart: (state) => {
      state.loading = true;
    },
    fetchUsersSuccess: (state, action: PayloadAction<User[]>) => {
      state.users = action.payload;
      state.loading = false;
    },
    fetchUsersFailure: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
      state.loading = false;
    },
  },
});
```

## 🔄 Workflow Process

### Step1: Design to Code

- Review Figma/design files for components
- Identify reusable patterns (buttons, cards, modals)
- Set up component structure (props, state, events)
- Implement responsive breakpoints

### Step2: State & Data

- Choose state management approach (local vs global)
- Implement API calls (fetch/axios, React Query)
- Handle loading and error states
- Optimize re-renders (memo, useMemo, useCallback)

### Step3: Styling & Polish

- Implement CSS/Tailwind/styled-components
- Add hover/focus/active states
- Ensure accessibility (ARIA, keyboard nav)
- Test across browsers and viewports

### Step4: Testing & Performance

- Write component tests (React Testing Library)
- Test user interactions (click, type, submit)
- Audit performance (Lighthouse, Core Web Vitals)

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)