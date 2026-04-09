import { test, expect } from '@playwright/test';

test.describe('Homepage', () => {
  test('should display the page title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/{{project-name}}/i);
  });

  test('should navigate to about page', async ({ page }) => {
    await page.goto('/');
    await page.click('a[href="/about"]');
    await expect(page).toHaveURL('/about');
  });
});

test.describe('Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should have working navigation links', async ({ page }) => {
    const links = page.locator('nav a');
    const count = await links.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should highlight active link', async ({ page }) => {
    const activeLink = page.locator('nav a.active');
    await expect(activeLink).toBeVisible();
  });
});

test.describe('API Integration', () => {
  test('should fetch and display data', async ({ page }) => {
    await page.goto('/');
    const dataContainer = page.locator('[data-testid="data-container"]');
    await expect(dataContainer).toBeVisible({ timeout: 5000 });
  });

  test('should handle API errors gracefully', async ({ page }) => {
    await page.route('**/api/**', route => route.abort());
    await page.goto('/');
    const errorMessage = page.locator('[data-testid="error-message"]');
    await expect(errorMessage).toBeVisible();
  });
});
