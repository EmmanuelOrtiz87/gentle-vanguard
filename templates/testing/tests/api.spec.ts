import { test, expect } from '@playwright/test';

test.describe('API Tests', () => {
  const apiClient = async (request: any) => {
    return {
      get: async (endpoint: string) => request.get(endpoint),
      post: async (endpoint: string, data: any) => request.post(endpoint, { data }),
      put: async (endpoint: string, data: any) => request.put(endpoint, { data }),
      delete: async (endpoint: string) => request.delete(endpoint)
    };
  };

  test('GET /api/users should return users list', async ({ request }) => {
    const response = await request.get('/api/users');
    expect(response.ok()).toBeTruthy();
    
    const users = await response.json();
    expect(Array.isArray(users)).toBeTruthy();
  });

  test('POST /api/users should create user', async ({ request }) => {
    const newUser = {
      name: 'Test User',
      email: `test${Date.now()}@example.com`,
      password: 'password123'
    };
    
    const response = await request.post('/api/users', { data: newUser });
    expect(response.status()).toBe(201);
    
    const user = await response.json();
    expect(user).toHaveProperty('id');
    expect(user.email).toBe(newUser.email);
  });

  test('GET /api/users/:id should return single user', async ({ request }) => {
    const response = await request.get('/api/users/1');
    expect(response.ok()).toBeTruthy();
    
    const user = await response.json();
    expect(user).toHaveProperty('id');
  });

  test('PUT /api/users/:id should update user', async ({ request }) => {
    const updateData = { name: 'Updated Name' };
    const response = await request.put('/api/users/1', { data: updateData });
    expect(response.ok()).toBeTruthy();
    
    const user = await response.json();
    expect(user.name).toBe(updateData.name);
  });

  test('DELETE /api/users/:id should remove user', async ({ request }) => {
    const response = await request.delete('/api/users/999');
    expect(response.status()).toBe(204);
  });

  test('should handle 404 for non-existent resource', async ({ request }) => {
    const response = await request.get('/api/users/999999');
    expect(response.status()).toBe(404);
  });

  test('should require authentication for protected routes', async ({ request }) => {
    const response = await request.get('/api/protected');
    expect(response.status()).toBe(401);
  });
});
