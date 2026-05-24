
```typescript
// Parallel fetching
const [users, posts] = await Promise.all([
  fetch('/api/users').then((r) => r.json()),
  fetch('/api/posts').then((r) => r.json()),
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
  matcher: ['/dashboard/:path*', '/admin/:path*'],
};
```

## Quick Reference

| Pattern          | Code                           |
| ---------------- | ------------------------------ |
| Server Component | Default (no 'use client')      |
| Client Component | 'use client' at top            |
| Server Action    | 'use server' in async function |
| Route Handler    | app/api/\*/route.ts            |
| Revalidate       | revalidatePath('/path')        |
| Redirect         | redirect('/path')              |