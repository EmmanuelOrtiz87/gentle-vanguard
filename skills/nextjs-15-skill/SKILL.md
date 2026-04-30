---
name: nextjs-15-skill
description: >
  Next.js 15 App Router patterns: Server Components, Server Actions, data fetching.
  Trigger: "Next.js", "Next.js 15", "App Router", "Server Component", "Server Action", "next.config".
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

```typescript
// Parallel fetching
const [users, posts] = await Promise.all([
  fetch('/api/users').then(r => r.json()),
  fetch('/api/posts').then(r => r.json())
]);

// Sequential
const users = await fetchUsers();
const posts = await fetchPostsForUsers(users);
```

## Route Handler

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET() {
  const users = await db.user.findMany();
  return NextResponse.json(users);
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const user = await db.user.create({ data: body });
  return NextResponse.json(user, { status: 201 });
}
```

## Dynamic Routes

```typescript
// app/users/[id]/page.tsx
export default async function UserPage({ 
  params 
}: { params: { id: string } }) {
  const user = await db.user.findUnique({
    where: { id: params.id }
  });
  
  if (!user) notFound();
  
  return <div>{user.name}</div>;
}
```

## Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(req: NextRequest) {
  // Check auth
  const token = req.cookies.get('token');
  
  if (!token && req.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', req.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*']
};
```

## Quick Reference

| Pattern | Code |
|---------|------|
| Server Component | Default (no 'use client') |
| Client Component | 'use client' at top |
| Server Action | 'use server' in async function |
| Route Handler | app/api/*/route.ts |
| Revalidate | revalidatePath('/path') |
| Redirect | redirect('/path') |
