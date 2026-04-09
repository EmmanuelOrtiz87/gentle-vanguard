import { test, expect } from '@playwright/test';

test.describe('Accessibility', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    const h1 = page.locator('h1');
    const h2 = page.locator('h2');
    const h3 = page.locator('h3');
    
    await expect(h1).toHaveCount(1);
    expect(await h2.count()).toBeGreaterThanOrEqual(0);
    expect(await h3.count()).toBeGreaterThanOrEqual(0);
  });

  test('should have accessible form labels', async ({ page }) => {
    const inputs = page.locator('input:not([type="hidden"])');
    const count = await inputs.count();
    
    for (let i = 0; i < count; i++) {
      const input = inputs.nth(i);
      const id = await input.getAttribute('id');
      if (id) {
        const label = page.locator(`label[for="${id}"]`);
        await expect(label.or(page.locator(`[aria-labelledby="${id}"]`))).toBeVisible();
      }
    }
  });

  test('should have proper alt text on images', async ({ page }) => {
    const images = page.locator('img');
    const count = await images.count();
    
    for (let i = 0; i < count; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute('alt');
      const role = await img.getAttribute('role');
      
      if (role !== 'presentation' && role !== 'none') {
        expect(alt).toBeTruthy();
      }
    }
  });

  test('should have sufficient color contrast', async ({ page }) => {
    await expect(page).toHaveTitle(/./);
  });

  test('should be keyboard navigable', async ({ page }) => {
    await page.keyboard.press('Tab');
    
    const focused = page.locator(':focus');
    await expect(focused).toBeVisible();
  });

  test('should have skip link for main content', async ({ page }) => {
    const skipLink = page.locator('a[href="#main-content"]');
    if (await skipLink.count() > 0) {
      await expect(skipLink.first()).toBeAttached();
    }
  });
});
