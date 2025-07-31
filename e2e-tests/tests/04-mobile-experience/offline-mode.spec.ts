// MOBILE OFFLINE FEATURES NOT IMPLEMENTED
// These tests are skipped until Service Worker and offline functionality is ready
// See AGENT_MESSAGES for implementation tasks

import { test, expect, devices } from '@playwright/test';

// Use iPhone 13 device settings
test.use(devices['iPhone 13']);

test.describe('Mobile Offline Mode', () => {
  test.beforeEach(async ({ page }) => {
    // Login on mobile
    await page.goto('/mobile/login');
    await page.fill('[name="username"]', 'john.doe');
    await page.fill('[name="password"]', 'test');
    await page.tap('button[type="submit"]');
    
    // Wait for mobile dashboard
    await page.waitForURL(/\/mobile\/dashboard/, { timeout: 10000 });
  });

  test.skip('Queue requests when offline', async ({ page, context }) => {
    // First ensure we're online and load some data
    await page.goto('/mobile/schedule');
    await page.waitForSelector('[data-testid="schedule-data"]', { state: 'visible' });
    
    // Go offline
    await context.setOffline(true);
    
    // Verify offline indicator appears
    await expect(page.locator('[data-testid="offline-indicator"]')).toBeVisible({ timeout: 5000 });
    
    // Try to create a new request while offline
    await page.tap('[data-testid="create-request"]');
    
    // Fill request form
    const startDate = new Date();
    startDate.setDate(startDate.getDate() + 14);
    await page.fill('[name="startDate"]', startDate.toISOString().split('T')[0]);
    
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 2);
    await page.fill('[name="endDate"]', endDate.toISOString().split('T')[0]);
    
    await page.selectOption('[name="type"]', 'vacation');
    await page.fill('[name="reason"]', 'Offline request test');
    
    // Submit request
    await page.tap('button[type="submit"]');
    
    // Should show queued status
    await expect(page.locator('[data-testid="sync-status"]')).toContainText('Pending sync');
    
    // Should show in local queue
    await expect(page.locator('text=1 request pending sync')).toBeVisible();
    
    // Go back online
    await context.setOffline(false);
    
    // Wait for sync to complete
    await page.waitForSelector('[data-testid="sync-complete"]', { 
      state: 'visible',
      timeout: 10000 
    });
    
    // Verify request was synced
    await expect(page.locator('text=Request synced successfully')).toBeVisible();
  });

  test.skip('View cached schedule data offline', async ({ page, context }) => {
    // Load schedule while online
    await page.goto('/mobile/schedule');
    await page.waitForSelector('[data-testid="schedule-grid"]', { state: 'visible' });
    
    // Store some schedule data to verify later
    const scheduleDates = await page.locator('[data-testid="schedule-date"]').allTextContents();
    expect(scheduleDates.length).toBeGreaterThan(0);
    
    // Go offline
    await context.setOffline(true);
    await expect(page.locator('[data-testid="offline-indicator"]')).toBeVisible();
    
    // Navigate away and back
    await page.goto('/mobile/dashboard');
    await page.goto('/mobile/schedule');
    
    // Schedule should still be visible from cache
    await expect(page.locator('[data-testid="schedule-grid"]')).toBeVisible();
    
    // Should show cached data indicator
    await expect(page.locator('[data-testid="cached-data-indicator"]')).toBeVisible();
    
    // Verify same dates are shown
    const cachedDates = await page.locator('[data-testid="schedule-date"]').allTextContents();
    expect(cachedDates).toEqual(scheduleDates);
  });

  test.skip('Conflict resolution when syncing', async ({ page, context }) => {
    // Create a request while online
    await page.goto('/mobile/requests/new');
    const startDate = new Date();
    startDate.setDate(startDate.getDate() + 20);
    
    await page.fill('[name="startDate"]', startDate.toISOString().split('T')[0]);
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 1);
    await page.fill('[name="endDate"]', endDate.toISOString().split('T')[0]);
    await page.selectOption('[name="type"]', 'vacation');
    await page.tap('button[type="submit"]');
    
    // Wait for success
    await page.waitForSelector('text=Request submitted successfully');
    
    // Go offline
    await context.setOffline(true);
    
    // Try to edit the same request offline
    await page.goto('/mobile/requests');
    const request = page.locator('[data-testid^="request-"]:has-text("Pending")').first();
    await request.tap();
    
    // Edit the request
    await page.tap('button:text("Edit")');
    await page.fill('[name="reason"]', 'Updated offline');
    await page.tap('button:text("Save")');
    
    // Should queue the update
    await expect(page.locator('[data-testid="sync-status"]')).toContainText('Pending sync');
    
    // Go back online
    await context.setOffline(false);
    
    // Should detect conflict if request was modified on server
    // This test assumes conflict detection is implemented
    const conflictDialog = page.locator('[data-testid="conflict-dialog"]');
    if (await conflictDialog.isVisible({ timeout: 5000 })) {
      // Choose local version
      await page.tap('button:text("Keep Local")');
      await expect(page.locator('text=Conflict resolved')).toBeVisible();
    }
  });

  test.skip('PWA installation prompt', async ({ page }) => {
    // Check if PWA installation is available
    const installButton = page.locator('[data-testid="pwa-install"]');
    
    if (await installButton.isVisible({ timeout: 5000 })) {
      // Click install
      await installButton.tap();
      
      // Should show installation dialog (browser-specific)
      // We can't actually install in test, but verify the prompt works
      await expect(page.locator('text=Install WFM Mobile')).toBeVisible();
    } else {
      // If no install button, check if already installed indicator exists
      await expect(page.locator('[data-testid="pwa-installed"]')).toBeVisible();
    }
  });

  test.skip('Background sync for notifications', async ({ page, context }) => {
    // Enable notifications if prompted
    await context.grantPermissions(['notifications']);
    
    // Go to notification settings
    await page.goto('/mobile/settings/notifications');
    
    // Enable background sync
    const bgSyncToggle = page.locator('[data-testid="background-sync-toggle"]');
    if (await bgSyncToggle.isVisible()) {
      await bgSyncToggle.tap();
      
      // Should show enabled state
      await expect(bgSyncToggle).toBeChecked();
      
      // Go offline
      await context.setOffline(true);
      
      // Create an action that would trigger notification
      await page.goto('/mobile/requests/new');
      await page.fill('[name="startDate"]', new Date().toISOString().split('T')[0]);
      await page.tap('button[type="submit"]');
      
      // Should queue for background sync
      await expect(page.locator('text=Will notify when synced')).toBeVisible();
    }
  });
});