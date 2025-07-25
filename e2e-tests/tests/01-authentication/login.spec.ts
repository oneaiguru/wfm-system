import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('Login with valid credentials', async ({ page }) => {
    // Fill login form
    await page.fill('[name="username"]', 'john.doe');
    await page.fill('[name="password"]', 'test');
    
    // Submit form
    await page.click('button[type="submit"]');
    
    // Should redirect to dashboard
    await expect(page).toHaveURL('/dashboard', { timeout: 10000 });
    
    // Should show user info
    await expect(page.locator('text=John Doe')).toBeVisible({ timeout: 5000 });
  });

  test('Login with invalid credentials shows error', async ({ page }) => {
    // Fill with invalid credentials
    await page.fill('[name="username"]', 'invalid');
    await page.fill('[name="password"]', 'wrong');
    
    // Submit form
    await page.click('button[type="submit"]');
    
    // Should show error message
    await expect(page.locator('text=Invalid credentials')).toBeVisible({ timeout: 5000 });
    
    // Should stay on login page
    await expect(page).toHaveURL('/login');
  });

  test('Login form validation', async ({ page }) => {
    // Try to submit empty form
    await page.click('button[type="submit"]');
    
    // Should show validation errors
    await expect(page.locator('text=Username is required')).toBeVisible();
    await expect(page.locator('text=Password is required')).toBeVisible();
  });

  test('JWT token is stored after login', async ({ page }) => {
    // Login
    await page.fill('[name="username"]', 'john.doe');
    await page.fill('[name="password"]', 'test');
    await page.click('button[type="submit"]');
    
    // Wait for redirect
    await page.waitForURL('/dashboard');
    
    // Check localStorage for token
    const token = await page.evaluate(() => localStorage.getItem('token'));
    expect(token).toBeTruthy();
    expect(token).toMatch(/^eyJ/); // JWT tokens start with eyJ
  });

  test('Logout clears session', async ({ page }) => {
    // First login
    await page.fill('[name="username"]', 'john.doe');
    await page.fill('[name="password"]', 'test');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
    
    // Click logout
    await page.click('[data-testid="logout-button"]');
    
    // Should redirect to login
    await expect(page).toHaveURL('/login');
    
    // Token should be cleared
    const token = await page.evaluate(() => localStorage.getItem('token'));
    expect(token).toBeNull();
  });
});