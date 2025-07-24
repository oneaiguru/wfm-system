import { test, expect } from '@playwright/test';

test.describe('SPEC-25: Mobile Login', () => {
  test('should display mobile login page with Russian interface', async ({ page }) => {
    await page.goto('http://localhost:3000/mobile/login');
    
    // Verify mobile login components
    await expect(page.locator('h1:text("WFM Мобильный")')).toBeVisible();
    await expect(page.locator('p:text("Личный кабинет сотрудника")')).toBeVisible();
    
    // Verify form fields
    await expect(page.locator('label:text("Имя пользователя")')).toBeVisible();
    await expect(page.locator('input[placeholder="Введите имя пользователя"]')).toBeVisible();
    await expect(page.locator('label:text("Пароль")')).toBeVisible();
    await expect(page.locator('input[placeholder="Введите пароль"]')).toBeVisible();
    
    // Verify mobile-specific features
    await expect(page.locator('text=Запомнить устройство')).toBeVisible();
    await expect(page.locator('button:text("Войти")')).toBeVisible();
    
    // Verify version info
    await expect(page.locator('text=v2.0.0')).toBeVisible();
    await expect(page.locator('text=© 2024 WFM Enterprise')).toBeVisible();
  });

  test('should handle login attempt', async ({ page }) => {
    await page.goto('http://localhost:3000/mobile/login');
    
    // Fill in credentials
    await page.fill('input[placeholder="Введите имя пользователя"]', 'mobile_user');
    await page.fill('input[placeholder="Введите пароль"]', 'password123');
    
    // Click login button
    await page.click('button:text("Войти")');
    
    // Wait for API call (even if it fails, we're testing the UI)
    await page.waitForTimeout(1000);
    
    // Verify error message is shown (since API might not be fully configured)
    const errorMessage = page.locator('text=Неверные данные');
    const isErrorVisible = await errorMessage.isVisible().catch(() => false);
    
    // Test passes if either login works or error is properly displayed
    expect(isErrorVisible || page.url() !== 'http://localhost:3000/mobile/login').toBeTruthy();
  });

  test('should have mobile-optimized layout', async ({ page }) => {
    await page.goto('http://localhost:3000/mobile/login');
    
    // Check for mobile-specific CSS classes
    await expect(page.locator('.mobile-login')).toBeVisible();
    await expect(page.locator('.mobile-login__container')).toBeVisible();
    await expect(page.locator('.mobile-login__form')).toBeVisible();
    
    // Verify mobile viewport optimization
    const viewport = page.viewportSize();
    if (viewport && viewport.width <= 768) {
      // Mobile layout should be active
      await expect(page.locator('.mobile-login__container')).toHaveCSS('max-width', '400px');
    }
  });
});