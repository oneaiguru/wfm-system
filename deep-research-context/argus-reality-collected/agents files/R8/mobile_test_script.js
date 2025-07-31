// R8 Mobile Testing Script - Following BDD-Guided Approach
const { chromium } = require('playwright');

(async () => {
  console.log('R8-UXMobileEnhancements: Starting BDD-guided mobile testing...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
    viewport: { width: 375, height: 667 }
  });
  
  const page = await context.newPage();
  
  try {
    // BDD Scenario: Mobile Personal Cabinet Access
    console.log('Testing mobile portal access...');
    await page.goto('https://lkcc1010wfmcc.argustelecom.ru', { timeout: 10000 });
    
    // Capture accessibility metrics
    const accessibilityMetrics = await page.evaluate(() => {
      return {
        focusableElements: document.querySelectorAll('button, input, select, textarea, a[href], [tabindex]').length,
        ariaElements: document.querySelectorAll('[aria-label], [aria-labelledby], [role]').length,
        viewport: window.innerWidth + 'x' + window.innerHeight,
        userAgent: navigator.userAgent
      };
    });
    
    console.log('R8-MCP-EVIDENCE:', JSON.stringify(accessibilityMetrics, null, 2));
    
    await page.screenshot({ path: '/Users/m/Documents/wfm/main/agents/R8/mobile_test_screenshot.png' });
    
  } catch (error) {
    console.log('R8-ERROR-CAPTURED:', error.message);
  } finally {
    await browser.close();
  }
})();