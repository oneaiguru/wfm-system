import { test, expect } from '@playwright/test';

test.describe('SPEC-09: Request History', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to login and authenticate
    await page.goto('http://localhost:3000/login');
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'password');
    await page.click('button[type="submit"]');
    
    // Wait for navigation to complete
    await page.waitForLoadState('networkidle');
    
    // Navigate to employee portal
    await page.goto('http://localhost:3000/employee-portal');
    await page.waitForSelector('text=My Requests');
  });

  test('should display request history tab', async ({ page }) => {
    // Check that history tab exists
    await expect(page.locator('button:has-text("History")')).toBeVisible();
    
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Verify tab is active
    const historyTab = page.locator('button:has-text("History")');
    await expect(historyTab).toHaveClass(/bg-white text-blue-600/);
  });

  test('should load historical requests from API', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Wait for requests to load
    await page.waitForTimeout(1000); // Allow time for API call
    
    // Should show approved, rejected, or cancelled requests
    const historicalStatuses = ['Approved', 'Rejected', 'Cancelled'];
    
    // Check that at least one historical request is shown
    let foundHistorical = false;
    for (const status of historicalStatuses) {
      if (await page.locator(`text=${status}`).isVisible()) {
        foundHistorical = true;
        break;
      }
    }
    
    if (!foundHistorical) {
      // If no real data, should show empty state
      await expect(page.locator('text=Request history is empty')).toBeVisible();
    }
  });

  test('should display request details with status badges', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Look for any historical request
    const requestCard = page.locator('div[class*="border"][class*="rounded-lg"]').first();
    
    if (await requestCard.isVisible()) {
      // Check for status badge
      const statusBadge = requestCard.locator('span[class*="rounded-full"][class*="px-2"]');
      await expect(statusBadge).toBeVisible();
      
      // Check for request details
      await expect(requestCard.locator('text=Type:')).toBeVisible();
      await expect(requestCard.locator('text=Period:')).toBeVisible();
      await expect(requestCard.locator('text=Reason:')).toBeVisible();
      await expect(requestCard.locator('text=Submitted:')).toBeVisible();
    }
  });

  test('should show approver information for reviewed requests', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Look for an approved or rejected request
    const reviewedCard = page.locator('div:has(span:has-text("Approved")), div:has(span:has-text("Rejected"))').first();
    
    if (await reviewedCard.isVisible()) {
      // Should show approver name
      await expect(reviewedCard.locator('text=Reviewed by:')).toBeVisible();
      
      // Check for approval comments if present
      const comments = reviewedCard.locator('div.bg-gray-100.rounded.text-xs');
      if (await comments.isVisible()) {
        await expect(comments.locator('text=Comments:')).toBeVisible();
      }
    }
  });

  test('should filter history by request type', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Use the type filter dropdown
    const typeFilter = page.locator('select').filter({ hasText: 'All Types' });
    await typeFilter.selectOption('vacation');
    
    // Wait for filter to apply
    await page.waitForTimeout(500);
    
    // Check that only vacation requests are shown
    const requestCards = page.locator('div[class*="border"][class*="rounded-lg"]');
    const count = await requestCards.count();
    
    if (count > 0) {
      // All visible requests should be vacation type
      for (let i = 0; i < count; i++) {
        const card = requestCards.nth(i);
        if (await card.isVisible()) {
          await expect(card.locator('text=Type: Vacation')).toBeVisible();
        }
      }
    }
  });

  test('should sort history by date', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Change sort order
    const sortDropdown = page.locator('select').filter({ hasText: 'Date' });
    
    // Sort by oldest first
    await sortDropdown.selectOption('date-asc');
    await page.waitForTimeout(500);
    
    // Get dates from visible requests
    const dates = await page.locator('text=Submitted:').evaluateAll(elements => 
      elements.map(el => {
        const text = el.textContent || '';
        const dateMatch = text.match(/Submitted: (.+)/);
        return dateMatch ? new Date(dateMatch[1]).getTime() : 0;
      })
    );
    
    // Verify dates are in ascending order
    for (let i = 1; i < dates.length; i++) {
      expect(dates[i]).toBeGreaterThanOrEqual(dates[i - 1]);
    }
  });

  test('should search history by keywords', async ({ page }) => {
    // Click on history tab
    await page.click('button:has-text("History")');
    
    // Use search input
    const searchInput = page.locator('input[placeholder*="Search"]');
    await searchInput.fill('vacation');
    
    // Wait for search to apply
    await page.waitForTimeout(500);
    
    // Check that results contain the search term
    const requestCards = page.locator('div[class*="border"][class*="rounded-lg"]');
    const visibleCount = await requestCards.count();
    
    if (visibleCount > 0) {
      // At least one result should contain 'vacation' in title or reason
      let foundMatch = false;
      for (let i = 0; i < visibleCount; i++) {
        const card = requestCards.nth(i);
        const text = await card.textContent();
        if (text?.toLowerCase().includes('vacation')) {
          foundMatch = true;
          break;
        }
      }
      expect(foundMatch).toBeTruthy();
    }
  });
});