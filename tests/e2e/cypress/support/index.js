/**
 * Cypress support file - loaded before every test file
 */

// Import commands
import './commands';

// Import custom commands for WFM testing
Cypress.Commands.add('login', (email, password) => {
  cy.session([email, password], () => {
    cy.visit('/login');
    cy.get('[data-cy=email]').type(email);
    cy.get('[data-cy=password]').type(password);
    cy.get('[data-cy=login-btn]').click();
    cy.get('[data-cy=dashboard]').should('be.visible');
  });
});

Cypress.Commands.add('loginAsManager', () => {
  cy.login('manager@test.com', 'password123');
});

Cypress.Commands.add('loginAsEmployee', () => {
  cy.login('employee@test.com', 'password123');
});

Cypress.Commands.add('createSchedule', (startDate, endDate, employees = []) => {
  cy.visit('/schedules/new');
  cy.get('[data-cy=schedule-name]').type(`Test Schedule ${Date.now()}`);
  cy.get('[data-cy=start-date]').type(startDate);
  cy.get('[data-cy=end-date]').type(endDate);
  
  if (employees.length > 0) {
    employees.forEach(emp => {
      cy.get('[data-cy=employee-select]').click();
      cy.get(`[data-cy=employee-option-${emp}]`).click();
    });
  }
  
  cy.get('[data-cy=generate-btn]').click();
  cy.get('[data-cy=schedule-grid]').should('be.visible');
});

Cypress.Commands.add('selectDateRange', (startDate, endDate) => {
  cy.get('[data-cy=date-range-picker]').click();
  cy.get('[data-cy=start-date-input]').clear().type(startDate);
  cy.get('[data-cy=end-date-input]').clear().type(endDate);
  cy.get('[data-cy=apply-date-range]').click();
});

Cypress.Commands.add('waitForScheduleGeneration', () => {
  cy.get('[data-cy=generation-progress]', { timeout: 30000 }).should('not.exist');
  cy.get('[data-cy=schedule-grid]').should('be.visible');
});

Cypress.Commands.add('verifyNotification', (message) => {
  cy.get('[data-cy=notification-toast]').should('be.visible').and('contain', message);
});

// API command helpers
Cypress.Commands.add('apiLogin', (email = 'admin@test.com', password = 'password123') => {
  return cy.request('POST', '/api/auth/login', { email, password })
    .then((response) => {
      window.localStorage.setItem('authToken', response.body.access_token);
      return response.body.access_token;
    });
});

Cypress.Commands.add('apiRequest', (method, url, body = {}) => {
  const token = window.localStorage.getItem('authToken');
  
  return cy.request({
    method,
    url,
    body,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
});

// Intercept common API calls
beforeEach(() => {
  // Intercept and alias common API endpoints
  cy.intercept('GET', '/api/employees*', { fixture: 'employees.json' }).as('getEmployees');
  cy.intercept('GET', '/api/schedules*', { fixture: 'schedules.json' }).as('getSchedules');
  cy.intercept('POST', '/api/auth/login', { fixture: 'auth-success.json' }).as('login');
});

// Configure viewport
Cypress.on('window:before:load', (win) => {
  // Stub window.fetch to use cy.intercept
  win.fetch = null;
});

// Handle uncaught exceptions
Cypress.on('uncaught:exception', (err, runnable) => {
  // returning false here prevents Cypress from failing the test
  if (err.message.includes('ResizeObserver loop limit exceeded')) {
    return false;
  }
  // Let other errors fail the test
  return true;
});

// Add custom assertions
chai.Assertion.addMethod('scheduled', function (expected) {
  const obj = this._obj;
  
  new chai.Assertion(obj).to.have.property('shifts');
  
  const actualCount = obj.shifts.length;
  
  this.assert(
    actualCount === expected,
    `expected schedule to have ${expected} shifts but got ${actualCount}`,
    `expected schedule not to have ${expected} shifts`,
    expected,
    actualCount
  );
});

// Performance monitoring
let performanceMetrics = [];

Cypress.on('test:before:run', () => {
  performanceMetrics = [];
});

Cypress.on('test:after:run', (test, runnable) => {
  if (performanceMetrics.length > 0) {
    const avgLoadTime = performanceMetrics.reduce((a, b) => a + b, 0) / performanceMetrics.length;
    cy.task('log', `Average page load time: ${avgLoadTime}ms`);
    
    if (avgLoadTime > 3000) {
      cy.task('log', '⚠️  Performance warning: Average load time exceeds 3 seconds');
    }
  }
});

// Utility functions available in all tests
window.testHelpers = {
  generateEmployeeData: (count = 10) => {
    return Array.from({ length: count }, (_, i) => ({
      id: i + 1,
      name: `Employee ${i + 1}`,
      email: `employee${i + 1}@test.com`,
      skills: ['sales', 'support'].slice(0, (i % 2) + 1),
      maxHours: 40
    }));
  },
  
  generateShiftData: (employeeId, startDate, days = 7) => {
    const shifts = [];
    const start = new Date(startDate);
    
    for (let i = 0; i < days; i++) {
      const date = new Date(start);
      date.setDate(date.getDate() + i);
      
      if (i % 2 === 0) { // Work every other day
        shifts.push({
          employeeId,
          date: date.toISOString().split('T')[0],
          startTime: '08:00',
          endTime: '16:00'
        });
      }
    }
    
    return shifts;
  },
  
  formatDate: (date) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }
};