import { test, expect } from '@playwright/test';

test.describe('SPEC-11: Cancel Dialog', () => {
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

  test('should display cancel button for approved requests', async ({ page }) => {
    // Look for an approved request
    const approvedRequest = page.locator('text=Approved').first();
    
    if (await approvedRequest.isVisible()) {
      // Check that cancel button exists for approved request
      const requestCard = approvedRequest.locator('xpath=ancestor::div[contains(@class, "border")]');
      const cancelButton = requestCard.locator('button:has-text("Cancel")');
      await expect(cancelButton).toBeVisible();
    }
  });

  test('should open cancel dialog when clicking cancel', async ({ page }) => {
    // Find and click cancel button on an approved request
    const approvedCard = page.locator('div:has(span:has-text("Approved"))').first();
    
    if (await approvedCard.isVisible()) {
      const cancelButton = approvedCard.locator('button:has-text("Cancel")');
      await cancelButton.click();
      
      // Verify dialog opened
      await expect(page.locator('h2:has-text("Cancel Request")')).toBeVisible();
      await expect(page.locator('text=This action cannot be undone')).toBeVisible();
      await expect(page.locator('text=Are you sure you want to cancel this request?')).toBeVisible();
    }
  });

  test('should require cancellation reason', async ({ page }) => {
    // Find and click cancel button
    const approvedCard = page.locator('div:has(span:has-text("Approved"))').first();
    
    if (await approvedCard.isVisible()) {
      const cancelButton = approvedCard.locator('button:has-text("Cancel")');
      await cancelButton.click();
      
      // Wait for dialog
      await page.waitForSelector('h2:has-text("Cancel Request")');
      
      // Try to cancel without reason
      const confirmButton = page.locator('button:has-text("Cancel Request")').last();
      await expect(confirmButton).toBeDisabled();
      
      // Enter a reason
      const reasonTextarea = page.locator('textarea[placeholder*="reason for cancelling"]');
      await reasonTextarea.fill('Plans have changed due to project deadline');
      
      // Now button should be enabled
      await expect(confirmButton).toBeEnabled();
    }
  });

  test('should cancel request with reason', async ({ page }) => {
    // Find and click cancel button
    const approvedCard = page.locator('div:has(span:has-text("Approved"))').first();
    
    if (await approvedCard.isVisible()) {
      const cancelButton = approvedCard.locator('button:has-text("Cancel")');
      await cancelButton.click();
      
      // Wait for dialog
      await page.waitForSelector('h2:has-text("Cancel Request")');
      
      // Enter cancellation reason
      const reasonTextarea = page.locator('textarea[placeholder*="reason for cancelling"]');
      await reasonTextarea.fill('Project deadline moved up, need to be present');
      
      // Confirm cancellation
      await page.click('button:has-text("Cancel Request"):last-of-type');
      
      // Dialog should close
      await expect(page.locator('h2:has-text("Cancel Request")')).not.toBeVisible();
      
      // Request status should update to cancelled
      await expect(page.locator('text=Cancelled')).toBeVisible();
    }
  });

  test('should allow keeping request when clicking Keep Request', async ({ page }) => {
    // Find and click cancel button
    const approvedCard = page.locator('div:has(span:has-text("Approved"))').first();
    
    if (await approvedCard.isVisible()) {
      const cancelButton = approvedCard.locator('button:has-text("Cancel")');
      await cancelButton.click();
      
      // Wait for dialog
      await page.waitForSelector('h2:has-text("Cancel Request")');
      
      // Click Keep Request
      await page.click('button:has-text("Keep Request")');
      
      // Dialog should close without changing request
      await expect(page.locator('h2:has-text("Cancel Request")')).not.toBeVisible();
      
      // Request should still be approved
      await expect(approvedCard.locator('text=Approved')).toBeVisible();
    }
  });

  test('should display request details in cancel dialog', async ({ page }) => {
    // Find an approved request with known details
    const approvedCard = page.locator('div:has(span:has-text("Approved"))').first();
    
    if (await approvedCard.isVisible()) {
      // Get request details from card
      const requestTitle = await approvedCard.locator('h3').textContent();
      
      // Open cancel dialog
      const cancelButton = approvedCard.locator('button:has-text("Cancel")');
      await cancelButton.click();
      
      // Verify request details appear in dialog
      await expect(page.locator('h2:has-text("Cancel Request")')).toBeVisible();
      
      // Check that some request info is shown
      const dialogContent = page.locator('div.bg-gray-50.p-4.rounded-lg');
      await expect(dialogContent).toBeVisible();
      await expect(dialogContent.locator('text=Type:')).toBeVisible();
      await expect(dialogContent.locator('text=Dates:')).toBeVisible();
    }
  });
});