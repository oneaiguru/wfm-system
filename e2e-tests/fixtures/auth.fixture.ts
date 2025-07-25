import { test as base, expect, Page } from '@playwright/test';

type User = {
  id: string;
  username: string;
  role: string;
  employeeId: string;
};

type AuthFixtures = {
  authenticatedPage: Page;
  employeeAuth: { token: string; user: User };
  managerAuth: { token: string; user: User };
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ page }, use) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('[name="username"]', 'john.doe');
    await page.fill('[name="password"]', 'test');
    await page.click('button[type="submit"]');
    
    // Wait for navigation to dashboard
    await page.waitForURL('/dashboard', { timeout: 10000 });
    
    // Use the authenticated page
    await use(page);
    
    // Logout after test (if logout button exists)
    const logoutButton = page.locator('[data-testid="logout-button"]');
    if (await logoutButton.isVisible()) {
      await logoutButton.click();
    }
  },
  
  employeeAuth: async ({ request }, use) => {
    const response = await request.post('http://localhost:8001/api/v1/auth/login', {
      data: { username: 'john.doe', password: 'test' }
    });
    
    if (!response.ok()) {
      throw new Error(`Login failed: ${response.status()}`);
    }
    
    const data = await response.json();
    await use({ token: data.token, user: data.user });
  },
  
  managerAuth: async ({ request }, use) => {
    const response = await request.post('http://localhost:8001/api/v1/auth/login', {
      data: { username: 'jane.manager', password: 'test' }
    });
    
    if (!response.ok()) {
      throw new Error(`Manager login failed: ${response.status()}`);
    }
    
    const data = await response.json();
    await use({ token: data.token, user: data.user });
  },
});

export { expect } from '@playwright/test';