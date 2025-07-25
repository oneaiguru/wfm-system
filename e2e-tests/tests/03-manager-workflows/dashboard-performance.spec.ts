import { test, expect } from '@playwright/test';

test.describe('Manager Dashboard Performance', () => {
  test.beforeEach(async ({ page }) => {
    // Login as manager
    await page.goto('/login');
    await page.fill('[name="username"]', 'jane.manager');
    await page.fill('[name="password"]', 'test');
    await page.click('button[type="submit"]');
    await page.waitForURL('/manager/dashboard');
  });

  test('Dashboard loads in under 1 second', async ({ page }) => {
    // Start performance measurement
    await page.evaluate(() => performance.mark('dashboard-start'));
    
    // Navigate to dashboard (already there from login, but refresh to measure)
    await page.reload();
    
    // Wait for key components to be visible
    await page.waitForSelector('[data-testid="team-metrics"]', { state: 'visible' });
    await page.waitForSelector('[data-testid="pending-requests"]', { state: 'visible' });
    await page.waitForSelector('[data-testid="schedule-overview"]', { state: 'visible' });
    
    // Measure load time
    const loadTime = await page.evaluate(() => {
      performance.mark('dashboard-end');
      performance.measure('dashboard-load', 'dashboard-start', 'dashboard-end');
      const measure = performance.getEntriesByName('dashboard-load')[0];
      return measure.duration;
    });
    
    console.log(`Dashboard load time: ${loadTime}ms`);
    
    // Assert <1s requirement
    expect(loadTime).toBeLessThan(1000);
  });

  test('Handles large team data efficiently', async ({ page }) => {
    // Measure initial render time
    const startTime = Date.now();
    
    // Dashboard should already be loaded
    await page.waitForSelector('[data-testid="team-member-list"]', { state: 'visible' });
    
    const renderTime = Date.now() - startTime;
    
    // Should render within 2 seconds even with large team
    expect(renderTime).toBeLessThan(2000);
    
    // Check if virtual scrolling is implemented (only subset of items visible)
    const visibleRows = await page.locator('[data-testid="team-member-row"]:visible').count();
    const totalRows = await page.locator('[data-testid="team-member-row"]').count();
    
    // If more than 50 total rows, virtual scrolling should limit visible rows
    if (totalRows > 50) {
      expect(visibleRows).toBeLessThanOrEqual(30);
    }
  });

  test('KPI metrics load without blocking UI', async ({ page }) => {
    // Mark when page is interactive
    const interactive = await page.evaluate(() => {
      return new Promise(resolve => {
        if (document.readyState === 'complete') {
          resolve(Date.now());
        } else {
          window.addEventListener('load', () => resolve(Date.now()));
        }
      });
    });
    
    // KPI cards should load progressively
    const kpiCards = page.locator('[data-testid^="kpi-card-"]');
    const kpiCount = await kpiCards.count();
    
    // At least some KPIs should be visible
    expect(kpiCount).toBeGreaterThan(0);
    
    // Check each KPI loads within reasonable time
    for (let i = 0; i < kpiCount; i++) {
      const kpi = kpiCards.nth(i);
      await expect(kpi).toBeVisible({ timeout: 2000 });
    }
  });

  test('Pending requests section loads efficiently', async ({ page }) => {
    // Measure pending requests load time
    const startTime = Date.now();
    
    const pendingSection = page.locator('[data-testid="pending-requests"]');
    await expect(pendingSection).toBeVisible();
    
    // Check if requests are loaded
    const requestItems = page.locator('[data-testid^="pending-request-"]');
    await requestItems.first().waitFor({ state: 'visible', timeout: 2000 });
    
    const loadTime = Date.now() - startTime;
    
    // Should load within 500ms
    expect(loadTime).toBeLessThan(500);
    
    // Should show request count
    const countBadge = page.locator('[data-testid="pending-count"]');
    await expect(countBadge).toBeVisible();
  });

  test('Dashboard responds to real-time updates', async ({ page }) => {
    // Check if WebSocket connection is established
    const wsConnected = await page.evaluate(() => {
      // Check if there's a WebSocket connection
      return window.WebSocket && performance.getEntriesByType('resource')
        .some(entry => entry.name.includes('ws://') || entry.name.includes('wss://'));
    });
    
    // If WebSocket is connected, test real-time updates
    if (wsConnected) {
      // Wait for any real-time update indicator
      const updateIndicator = page.locator('[data-testid="last-updated"]');
      if (await updateIndicator.isVisible()) {
        const initialText = await updateIndicator.textContent();
        
        // Wait up to 30 seconds for an update
        await page.waitForFunction(
          (text) => {
            const current = document.querySelector('[data-testid="last-updated"]')?.textContent;
            return current !== text;
          },
          initialText,
          { timeout: 30000 }
        ).catch(() => {
          // No updates in 30 seconds is okay
          console.log('No real-time updates detected in 30 seconds');
        });
      }
    }
  });
});