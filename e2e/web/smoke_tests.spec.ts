import { test, expect } from '@playwright/test';

test.describe('Web Smoke Tests', () => {
  test('Landing page loads successfully', async ({ page }) => {
    await page.goto('http://localhost:3000'); // Adjust port as needed

    // Check page title
    await expect(page).toHaveTitle(/Gulf Lands/);

    // Check main heading
    await expect(page.locator('h2')).toContainText('Discover Your Dream Land');

    // Check navigation
    await expect(page.locator('nav')).toBeVisible();

    // Check hero section
    await expect(page.locator('.hero')).toBeVisible();

    // Check stats
    await expect(page.locator('.stat')).toHaveCount(3);
  });

  test('Analytics dispatch on page load', async ({ page }) => {
    // Mock analytics endpoint
    await page.route('**/track', (route) => {
      expect(route.request().method()).toBe('POST');
      const body = route.request().postDataJSON();
      expect(body).toHaveProperty('event_type');
      expect(body.event_type).toBe('page_view');
      route.fulfill({ status: 200 });
    });

    await page.goto('http://localhost:3000');

    // Wait for analytics call
    await page.waitForRequest('**/track');
  });

  test('Navigation works', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // Click on listings link
    await page.locator('a[href="#listings"]').click();

    // Check if scrolled to listings section
    await expect(page.locator('#listings')).toBeInViewport();
  });

  test('Contact form submission', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // Assuming there's a contact form
    const nameInput = page.locator('input[name="name"]');
    const emailInput = page.locator('input[name="email"]');
    const submitButton = page.locator('button[type="submit"]');

    if (await nameInput.isVisible()) {
      await nameInput.fill('Test User');
      await emailInput.fill('test@example.com');
      await submitButton.click();

      // Check for success message or analytics dispatch
      await page.waitForRequest('**/track');
    }
  });

  test('Responsive design', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 }); // Mobile
    await page.goto('http://localhost:3000');

    await expect(page.locator('.hero')).toBeVisible();

    await page.setViewportSize({ width: 1024, height: 768 }); // Desktop
    await expect(page.locator('.hero')).toBeVisible();
  });
});