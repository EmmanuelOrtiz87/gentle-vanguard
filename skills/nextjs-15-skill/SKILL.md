---
name: nextjs-15-skill
description: >
  Next.js 15 App Router patterns: Server Components, Server Actions, data fetching. Trigger:
  "Next.js", "Next.js 15", "App Router", "Server Component", "Server Action", "next.config".
---

## When to Use

- Building Next.js applications
- Using App Router (app/)
- Server Components vs Client Components
- Data fetching patterns
- Server Actions

## Project Structure

```
app/
 layout.tsx        # Root layout
 page.tsx         # Home page
 about/
    page.tsx    # /about
 api/
    route.ts    # API routes
 actions/
    form.ts     # Server Actions
components/
 ui/             # UI components
 providers.tsx   # Client providers
```

## Server Component (Default)

```typescript
// app/page.tsx - Server Component by default
import { db } from '@/lib/db';

export default async function Page() {
  const users = await db.user.findMany();

  return (
    <main>
      <h1>Users</h1>
      <ul>
        {users.map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </main>
  );
}
```

## Client Component

```typescript
// components/counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count}
    </button>
  );
}
```

## Server Action

```typescript
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { db } from '@/lib/db';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;

  await db.user.create({ data: { name } });

  revalidatePath('/users');
  redirect('/users');
}

// app/users/new/page.tsx
import { createUser } from '@/app/actions';

export default function NewUserPage() {
  return (
    <form action={createUser}>
      <input name="name" type="text" />
      <button type="submit">Create</button>
    </form>
  );
}
```

## Data Fetching

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)