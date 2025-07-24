import { test, expect } from '@playwright/test';

test.describe('SPEC-43: Manager Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the manager dashboard page
    await page.goto('http://localhost:3000/manager-dashboard');
  });

  test('should display manager dashboard page', async ({ page }) => {
    // Check that the manager dashboard page is displayed
    await expect(page.locator('h1:has-text("Manager Dashboard")')).toBeVisible();
    
    // Check for description
    await expect(page.locator('text=Manage your team and approve requests')).toBeVisible();
  });

  test('should display navigation tabs', async ({ page }) => {
    // Check for tab navigation
    await expect(page.getByRole('button', { name: 'Overview' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Requests' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Schedule' })).toBeVisible();
  });

  test('should display team overview metrics', async ({ page }) => {
    // Check for metric cards
    await expect(page.locator('text=Total Members')).toBeVisible();
    await expect(page.locator('text=Active')).toBeVisible();
    await expect(page.locator('text=On Leave')).toBeVisible();
    await expect(page.locator('text=Pending Requests')).toBeVisible();
    await expect(page.locator('text=Weekly Hours')).toBeVisible();
    
    // Check that metrics have values
    const totalMembers = page.locator('p:has-text("Total Members") + p');
    await expect(totalMembers).toHaveText(/\d+/);
  });

  test('should display team members list', async ({ page }) => {
    // Check for team members section
    await expect(page.locator('h2:has-text("Team Members")')).toBeVisible();
    
    // Check for at least one team member
    await expect(page.locator('text=John Doe')).toBeVisible();
    await expect(page.locator('text=Customer Service Rep')).toBeVisible();
    
    // Check for member status badges
    await expect(page.locator('text=active').first()).toBeVisible();
  });

  test('should display quick actions', async ({ page }) => {
    // Check for quick actions section
    await expect(page.locator('h2:has-text("Quick Actions")')).toBeVisible();
    
    // Check for action buttons
    await expect(page.locator('text=Review Pending Requests')).toBeVisible();
    await expect(page.locator('text=View Team Schedule')).toBeVisible();
    await expect(page.locator('text=Team Performance')).toBeVisible();
    
    // Check for pending requests count
    await expect(page.locator('text=3 requests awaiting approval')).toBeVisible();
  });

  test('should display team member details', async ({ page }) => {
    // Check for team member cards with details
    const memberCards = page.locator('[class*="border"][class*="rounded"]').filter({ has: page.locator('text=40h') });
    
    // Should have multiple team members
    const count = await memberCards.count();
    expect(count).toBeGreaterThan(0);
    
    // Check first member has required info
    const firstMember = memberCards.first();
    await expect(firstMember.locator('text=/\\d+h/')).toBeVisible(); // Hours
    await expect(firstMember.locator('text=/\\d+ shifts?/')).toBeVisible(); // Shifts
  });

  test('should show different member statuses', async ({ page }) => {
    // Check for different status types
    await expect(page.locator('text=active')).toBeVisible();
    await expect(page.locator('text=on leave')).toBeVisible();
    
    // Sick status might be present
    const sickStatus = page.locator('text=sick');
    if (await sickStatus.count() > 0) {
      await expect(sickStatus.first()).toBeVisible();
    }
  });

  test('should handle demo fallback gracefully', async ({ page }) => {
    // Check for fallback indicator
    const fallbackText = page.locator('text=Failed to load formal dashboard data - using demo fallback');
    
    // If API is not available, fallback message should be shown
    if (await fallbackText.isVisible()) {
      await expect(fallbackText).toBeVisible();
    }
    
    // Even with fallback, dashboard should still show data
    await expect(page.locator('text=Total Members')).toBeVisible();
    await expect(page.locator('text=Team Members')).toBeVisible();
  });

  test('should have back to demo navigation', async ({ page }) => {
    // Check for back button
    await expect(page.getByRole('button', { name: 'Back to Demo' })).toBeVisible();
  });
});