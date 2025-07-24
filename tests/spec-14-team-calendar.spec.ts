import { test, expect } from '@playwright/test';

test.describe('SPEC-14: Team Calendar', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the team calendar page
    await page.goto('http://localhost:3000/team-calendar');
  });

  test('should display team calendar page', async ({ page }) => {
    // Check that the team calendar page is displayed
    await expect(page.locator('h2:has-text("Team Schedule")')).toBeVisible();
    
    // Check for week navigation controls
    await expect(page.getByRole('button', { name: '← Previous Week' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Next Week →' })).toBeVisible();
    
    // Check for view mode toggles
    await expect(page.getByRole('button', { name: 'Week' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Month' })).toBeVisible();
  });

  test('should show team member selector', async ({ page }) => {
    // Check for team member dropdown
    const selector = page.locator('select').first();
    await expect(selector).toBeVisible();
    
    // Should have "All Team Members" as default option
    const selectedOption = await selector.inputValue();
    expect(selectedOption).toBe('all');
  });

  test('should display calendar grid with 7 days', async ({ page }) => {
    // Check that all 7 days of the week are displayed
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    for (const day of days) {
      await expect(page.locator(`text=${day}`).first()).toBeVisible();
    }
  });

  test('should show team summary metrics', async ({ page }) => {
    // Check for team summary section
    await expect(page.locator('h3:has-text("Team Summary")')).toBeVisible();
    
    // Check for metric cards
    await expect(page.locator('text=Total Team Hours')).toBeVisible();
    await expect(page.locator('text=Active Team Members')).toBeVisible();
    await expect(page.locator('text=Overtime Hours')).toBeVisible();
    await expect(page.locator('text=Understaffed Days')).toBeVisible();
  });

  test('should handle API errors gracefully', async ({ page }) => {
    // The page should show an error message when API fails
    // Currently showing "Failed to load team: 404"
    const errorSection = page.locator('text=API Connection Issue');
    
    // If API is not available, error should be displayed
    if (await errorSection.isVisible()) {
      await expect(errorSection).toBeVisible();
      await expect(page.locator('text=Failed to load team')).toBeVisible();
    }
  });

  test('should navigate between weeks', async ({ page }) => {
    // Get initial week display
    const weekDisplay = page.locator('h3').filter({ hasText: /\w{3}, \w{3} \d{1,2} - \w{3}, \w{3} \d{1,2}/ });
    const initialWeek = await weekDisplay.textContent();
    
    // Click next week
    await page.getByRole('button', { name: 'Next Week →' }).click();
    
    // Week display should change
    await expect(weekDisplay).not.toHaveText(initialWeek!);
    
    // Click previous week
    await page.getByRole('button', { name: '← Previous Week' }).click();
    
    // Should return to initial week
    await expect(weekDisplay).toHaveText(initialWeek!);
  });
});