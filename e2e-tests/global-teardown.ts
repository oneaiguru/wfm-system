import { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  console.log('🧹 Running global teardown...');
  // Add any cleanup tasks here if needed
  console.log('✅ Global teardown complete');
}

export default globalTeardown;