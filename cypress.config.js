import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    supportFile: 'tests/e2e/cypress/support/index.js',
    specPattern: 'tests/e2e/cypress/integration/**/*.cy.{js,jsx,ts,tsx}',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true,
    videosFolder: 'tests/e2e/cypress/videos',
    screenshotsFolder: 'tests/e2e/cypress/screenshots',
    env: {
      apiUrl: 'http://localhost:8000',
      coverage: true
    },
    setupNodeEvents(on, config) {
      // Implement code coverage
      require('@cypress/code-coverage/task')(on, config);
      
      // Custom tasks
      on('task', {
        'db:seed': () => {
          // Seed test database with sample data
          console.log('Seeding test database...');
          return null;
        },
        'db:cleanup': () => {
          // Cleanup test data after tests
          console.log('Cleaning up test database...');
          return null;
        },
        log(message) {
          console.log(message);
          return null;
        }
      });
      
      return config;
    },
    retries: {
      runMode: 2,
      openMode: 0
    },
    defaultCommandTimeout: 10000,
    requestTimeout: 10000,
    responseTimeout: 10000
  },
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite'
    },
    specPattern: 'tests/components/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'tests/e2e/cypress/support/component.js'
  }
});