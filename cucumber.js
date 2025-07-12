/**
 * Cucumber configuration for BDD tests
 */
module.exports = {
  default: {
    paths: ['tests/bdd/features/**/*.feature'],
    require: [
      'tests/bdd/step_definitions/**/*.js',
      'tests/bdd/support/**/*.js'
    ],
    format: [
      'progress-bar',
      'html:test-results/cucumber-report.html',
      'json:test-results/cucumber-report.json',
      'junit:test-results/cucumber-junit.xml'
    ],
    formatOptions: {
      snippetInterface: 'async-await'
    },
    publishQuiet: true,
    dryRun: false,
    failFast: false,
    parallel: 2,
    retry: 1,
    retryTagFilter: '@flaky',
    strict: true,
    worldParameters: {
      baseUrl: process.env.BASE_URL || 'http://localhost:3000',
      apiUrl: process.env.API_URL || 'http://localhost:8000',
      headless: process.env.HEADLESS !== 'false'
    }
  },
  
  // Profile for CI/CD
  ci: {
    format: [
      'progress',
      'json:test-results/cucumber-report.json',
      'junit:test-results/cucumber-junit.xml'
    ],
    parallel: 4,
    retry: 2,
    strict: true
  },
  
  // Profile for smoke tests
  smoke: {
    tags: '@smoke and not @slow',
    failFast: true,
    retry: 0
  },
  
  // Profile for development
  dev: {
    format: ['progress-bar'],
    parallel: 1,
    retry: 0,
    strict: false
  }
};