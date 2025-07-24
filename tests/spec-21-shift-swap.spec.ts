import { test, expect } from '@playwright/test';

test.describe('SPEC-21: Shift Swapping', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the schedule page
    await page.goto('http://localhost:3000/schedule');
  });

  test('should display shift swap button on schedule page', async ({ page }) => {
    // Check that the shift swap button is visible
    await expect(page.getByRole('button', { name: 'Request Shift Swap' })).toBeVisible();
  });

  test('should open shift swap modal when button clicked', async ({ page }) => {
    // Click the shift swap button
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Modal should be visible
    await expect(page.locator('h2:has-text("Request Shift Swap")')).toBeVisible();
    
    // Modal should have all required fields
    await expect(page.locator('text=Select Your Shift to Swap')).toBeVisible();
    await expect(page.locator('text=Select Requested Shift')).toBeVisible();
    await expect(page.locator('text=Reason for Swap')).toBeVisible();
  });

  test('should show shift selection dropdowns', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Check for my shift dropdown
    const myShiftSelect = page.locator('select').first();
    await expect(myShiftSelect).toBeVisible();
    await expect(myShiftSelect).toHaveAttribute('placeholder', '');
    
    // Check for requested shift dropdown (should be disabled initially)
    const requestedShiftSelect = page.locator('select').nth(1);
    await expect(requestedShiftSelect).toBeVisible();
    await expect(requestedShiftSelect).toBeDisabled();
    
    // Should show helper text
    await expect(page.locator('text=Please select your shift first')).toBeVisible();
  });

  test('should have reason textarea', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Check for reason textarea
    const reasonTextarea = page.locator('textarea[placeholder*="explain why you need to swap"]');
    await expect(reasonTextarea).toBeVisible();
    await expect(reasonTextarea).toBeEnabled();
  });

  test('should have submit and cancel buttons', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Check for buttons
    await expect(page.getByRole('button', { name: 'Cancel' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Submit Swap Request' })).toBeVisible();
    
    // Submit button should be disabled initially
    await expect(page.getByRole('button', { name: 'Submit Swap Request' })).toBeDisabled();
  });

  test('should close modal when cancel clicked', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Modal should be visible
    await expect(page.locator('h2:has-text("Request Shift Swap")')).toBeVisible();
    
    // Click cancel
    await page.getByRole('button', { name: 'Cancel' }).click();
    
    // Modal should be hidden
    await expect(page.locator('h2:has-text("Request Shift Swap")')).not.toBeVisible();
  });

  test('should close modal when X clicked', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Modal should be visible
    await expect(page.locator('h2:has-text("Request Shift Swap")')).toBeVisible();
    
    // Click X button (close button in modal header)
    await page.locator('button').filter({ hasText: '' }).nth(2).click();
    
    // Modal should be hidden
    await expect(page.locator('h2:has-text("Request Shift Swap")')).not.toBeVisible();
  });

  test('should display API error when endpoints unavailable', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Should show error message about failed API calls
    await expect(page.locator('text=Failed to fetch available shifts')).toBeVisible();
  });

  test('should require all fields before enabling submit', async ({ page }) => {
    // Open modal
    await page.getByRole('button', { name: 'Request Shift Swap' }).click();
    
    // Submit should be disabled initially
    const submitButton = page.getByRole('button', { name: 'Submit Swap Request' });
    await expect(submitButton).toBeDisabled();
    
    // Fill in reason
    await page.locator('textarea[placeholder*="explain why you need to swap"]').fill('Family emergency');
    
    // Submit should still be disabled without shift selections
    await expect(submitButton).toBeDisabled();
  });
});