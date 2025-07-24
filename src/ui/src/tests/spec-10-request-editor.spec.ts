import { test, expect } from '@playwright/test';

test.describe('SPEC-10: Request Editor', () => {
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

  test('should display edit button for pending requests', async ({ page }) => {
    // Look for a pending request
    const pendingRequest = page.locator('text=Pending Approval').first();
    
    if (await pendingRequest.isVisible()) {
      // Check that edit button exists for pending request
      const requestCard = pendingRequest.locator('xpath=ancestor::div[contains(@class, "border")]');
      const editButton = requestCard.locator('button:has-text("Edit")');
      await expect(editButton).toBeVisible();
    }
  });

  test('should open edit modal when clicking edit', async ({ page }) => {
    // Find and click edit button
    const editButton = page.locator('button:has-text("Edit")').first();
    
    if (await editButton.isVisible()) {
      await editButton.click();
      
      // Verify modal opened
      await expect(page.locator('h2:has-text("Edit Request")')).toBeVisible();
      await expect(page.locator('text=Date Range')).toBeVisible();
      await expect(page.locator('textarea[placeholder*="reason"]')).toBeVisible();
    }
  });

  test('should update request when saving changes', async ({ page }) => {
    // Find and click edit button
    const editButton = page.locator('button:has-text("Edit")').first();
    
    if (await editButton.isVisible()) {
      await editButton.click();
      
      // Wait for modal
      await page.waitForSelector('h2:has-text("Edit Request")');
      
      // Update the reason
      const reasonTextarea = page.locator('textarea[placeholder*="reason"]');
      await reasonTextarea.clear();
      await reasonTextarea.fill('Updated reason for my request - family emergency');
      
      // Update end date if possible
      const endDateInput = page.locator('input[type="date"]:nth-of-type(2)');
      if (await endDateInput.isEnabled()) {
        await endDateInput.fill('2025-08-10');
      }
      
      // Save changes
      await page.click('button:has-text("Save Changes")');
      
      // Verify modal closed and request updated
      await expect(page.locator('h2:has-text("Edit Request")')).not.toBeVisible();
      
      // Check that the updated reason appears in the list
      await expect(page.locator('text=Updated reason for my request')).toBeVisible();
    }
  });

  test('should not allow editing approved requests', async ({ page }) => {
    // Look for an approved request
    const approvedRequest = page.locator('text=Approved').first();
    
    if (await approvedRequest.isVisible()) {
      const requestCard = approvedRequest.locator('xpath=ancestor::div[contains(@class, "border")]');
      
      // Should not have edit button, only view and cancel
      const editButton = requestCard.locator('button:has-text("Edit")');
      await expect(editButton).not.toBeVisible();
      
      // Should have cancel button instead
      const cancelButton = requestCard.locator('button:has-text("Cancel")');
      await expect(cancelButton).toBeVisible();
    }
  });

  test('should validate date range selection', async ({ page }) => {
    const editButton = page.locator('button:has-text("Edit")').first();
    
    if (await editButton.isVisible()) {
      await editButton.click();
      
      // Wait for modal
      await page.waitForSelector('h2:has-text("Edit Request")');
      
      // Try to set end date before start date
      const startDateInput = page.locator('input[type="date"]:nth-of-type(1)');
      const endDateInput = page.locator('input[type="date"]:nth-of-type(2)');
      
      await startDateInput.fill('2025-08-15');
      await endDateInput.fill('2025-08-10');
      
      // The end date should have min attribute preventing this
      const endDateMin = await endDateInput.getAttribute('min');
      expect(endDateMin).toBe('2025-08-15');
    }
  });
});