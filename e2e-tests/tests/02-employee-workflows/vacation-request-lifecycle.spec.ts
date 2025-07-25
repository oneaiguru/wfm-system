import { test, expect } from '../../fixtures/auth.fixture';

test.describe('Vacation Request Lifecycle', () => {
  test('Complete vacation request flow', async ({ authenticatedPage }) => {
    const page = authenticatedPage;
    
    // Navigate to vacation requests
    await page.click('text=Time Off');
    await page.click('text=New Request');
    
    // Fill request form
    const startDate = new Date();
    startDate.setDate(startDate.getDate() + 30); // 30 days from now
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 4); // 5 day vacation
    
    await page.fill('[name="startDate"]', startDate.toISOString().split('T')[0]);
    await page.fill('[name="endDate"]', endDate.toISOString().split('T')[0]);
    await page.selectOption('[name="type"]', 'vacation');
    await page.fill('[name="reason"]', 'Summer holiday with family');
    
    // Submit request
    await page.click('button:text("Submit Request")');
    
    // Should show success message
    await expect(page.locator('text=Request submitted successfully')).toBeVisible();
    
    // Should redirect to request history
    await expect(page).toHaveURL(/\/requests\/history/);
    
    // New request should appear in list with pending status
    const newRequest = page.locator('tr:has-text("Summer holiday with family")');
    await expect(newRequest).toBeVisible();
    await expect(newRequest.locator('text=Pending')).toBeVisible();
  });

  test('Edit pending vacation request', async ({ authenticatedPage }) => {
    const page = authenticatedPage;
    
    // Navigate to request history
    await page.goto('/requests/history');
    
    // Find a pending request and click edit
    const pendingRequest = page.locator('tr:has-text("Pending")').first();
    await pendingRequest.locator('button:text("Edit")').click();
    
    // Modify end date
    const newEndDate = new Date();
    newEndDate.setDate(newEndDate.getDate() + 35);
    await page.fill('[name="endDate"]', newEndDate.toISOString().split('T')[0]);
    
    // Save changes
    await page.click('button:text("Save Changes")');
    
    // Should show success message
    await expect(page.locator('text=Request updated successfully')).toBeVisible();
  });

  test('Cancel approved request with reason', async ({ authenticatedPage }) => {
    const page = authenticatedPage;
    
    // Navigate to request history
    await page.goto('/requests/history');
    
    // Find an approved request
    const approvedRequest = page.locator('tr:has-text("Approved")').first();
    
    // If no approved requests, skip test
    if (await approvedRequest.count() === 0) {
      test.skip();
      return;
    }
    
    // Click cancel button
    await approvedRequest.locator('button:text("Cancel")').click();
    
    // Fill cancellation reason in dialog
    await page.fill('[name="cancellationReason"]', 'Plans changed due to project deadline');
    await page.click('button:text("Confirm Cancellation")');
    
    // Should show success message
    await expect(page.locator('text=Request cancelled successfully')).toBeVisible();
    
    // Status should update to cancelled
    await expect(approvedRequest.locator('text=Cancelled')).toBeVisible();
  });

  test('View request details and history', async ({ authenticatedPage }) => {
    const page = authenticatedPage;
    
    // Navigate to request history
    await page.goto('/requests/history');
    
    // Click on a request to view details
    const firstRequest = page.locator('tr[data-testid^="request-"]').first();
    await firstRequest.click();
    
    // Should show request details modal/page
    await expect(page.locator('h2:text("Request Details")')).toBeVisible();
    
    // Should show request timeline
    await expect(page.locator('text=Request Timeline')).toBeVisible();
    await expect(page.locator('text=Submitted')).toBeVisible();
  });

  test('Request validation prevents invalid dates', async ({ authenticatedPage }) => {
    const page = authenticatedPage;
    
    // Navigate to new request
    await page.goto('/requests/new');
    
    // Try to submit request with past dates
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 10);
    
    await page.fill('[name="startDate"]', pastDate.toISOString().split('T')[0]);
    await page.fill('[name="endDate"]', pastDate.toISOString().split('T')[0]);
    await page.click('button:text("Submit Request")');
    
    // Should show validation error
    await expect(page.locator('text=Start date cannot be in the past')).toBeVisible();
    
    // Try end date before start date
    const futureStart = new Date();
    futureStart.setDate(futureStart.getDate() + 10);
    const beforeStart = new Date();
    beforeStart.setDate(beforeStart.getDate() + 5);
    
    await page.fill('[name="startDate"]', futureStart.toISOString().split('T')[0]);
    await page.fill('[name="endDate"]', beforeStart.toISOString().split('T')[0]);
    await page.click('button:text("Submit Request")');
    
    // Should show validation error
    await expect(page.locator('text=End date must be after start date')).toBeVisible();
  });
});