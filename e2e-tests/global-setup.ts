import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  console.log('🚀 Starting global setup...');
  
  // Start browser for setup tasks
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  try {
    // Check if API is running
    const apiResponse = await page.request.get('http://localhost:8001/health');
    if (!apiResponse.ok()) {
      throw new Error('API server is not running on http://localhost:8001');
    }
    console.log('✅ API server is running');
    
    // Check if UI is running
    const uiResponse = await page.goto('http://localhost:3000', { timeout: 5000 });
    if (!uiResponse) {
      throw new Error('UI server is not running on http://localhost:3000');
    }
    console.log('✅ UI server is running');
    
    // Create test user if needed
    const loginResponse = await page.request.post('http://localhost:8001/api/v1/auth/login', {
      data: {
        username: 'john.doe',
        password: 'test'
      }
    });
    
    if (loginResponse.ok()) {
      console.log('✅ Test user verified');
    } else {
      console.log('⚠️  Test user login failed, tests may fail');
    }
    
  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  } finally {
    await browser.close();
  }
  
  console.log('✅ Global setup complete');
}

export default globalSetup;