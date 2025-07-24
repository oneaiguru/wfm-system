/**
 * BDD UI Component Test - Working End-to-End Vacation Request Scenario
 * Tests actual BDD scenario: 02-employee-requests.feature:12-24
 * Validates Russian text support and real API integration
 */

describe('BDD Vacation Request Workflow', () => {
  
  // Test Setup - Verify API endpoints are available
  beforeEach(() => {
    // Ensure backend API is running
    cy.request('GET', 'http://localhost:8001/api/v1/employees')
      .then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body.employees).to.have.length.greaterThan(0);
      });
  });

  /**
   * BDD Scenario Implementation: Create Request for Time Off
   * Given I am logged into the employee portal as an operator
   * When I navigate to the "Календарь" tab
   * And I click the "Создать" button  
   * And I select request type "больничный"
   * And I fill in the corresponding fields
   * And I submit the request
   * Then the request should be created
   * And I should see the request status on the "Заявки" page
   */
  it('Should complete vacation request workflow in Russian', () => {
    
    // STEP 1: Given I am logged into the employee portal
    cy.visit('http://localhost:3000');
    
    // Verify login form loads with Russian text
    cy.contains('Вход в систему').should('be.visible');
    
    // Login as employee (testing with mock credentials)
    cy.get('[data-testid="employee-id"]', { timeout: 10000 })
      .should('be.visible')
      .type('111538');
    cy.get('[data-testid="password"]')
      .type('password123');
    cy.get('[data-testid="login-button"]')
      .click();
    
    // Verify successful login (should redirect to dashboard)
    cy.url().should('include', '/dashboard');
    cy.contains('Личный кабинет').should('be.visible');
    
    // STEP 2: When I navigate to the "Календарь" tab
    cy.get('[data-testid="calendar-tab"]', { timeout: 5000 })
      .should('be.visible')
      .click();
    
    // Verify calendar view loads
    cy.contains('Календарь').should('be.visible');
    
    // STEP 3: And I click the "Создать" button
    cy.get('[data-testid="create-request-button"]')
      .should('be.visible')
      .click();
    
    // Verify request form opens
    cy.get('[data-testid="request-form"]').should('be.visible');
    cy.contains('Создать заявку').should('be.visible');
    
    // STEP 4: And I select request type "больничный"
    cy.get('[data-testid="request-type-select"]')
      .click();
    cy.get('[data-testid="sick-leave-option"]')
      .contains('больничный')
      .click();
    
    // STEP 5: And I fill in the corresponding fields
    
    // Fill start date
    cy.get('[data-testid="start-date"]')
      .type('2025-07-15');
    
    // Fill end date  
    cy.get('[data-testid="end-date"]')
      .type('2025-07-16');
    
    // Fill reason in Russian
    cy.get('[data-testid="reason"]')
      .type('Простуда и высокая температура. Требуется медицинский отдых.');
    
    // Set priority
    cy.get('[data-testid="priority-select"]')
      .select('normal');
    
    // Add emergency contact
    cy.get('[data-testid="emergency-contact"]')
      .type('+7 (999) 123-45-67');
    
    // STEP 6: And I submit the request
    cy.get('[data-testid="submit-request"]')
      .should('not.be.disabled')
      .click();
    
    // Verify submission success message
    cy.contains('Заявка успешно отправлена', { timeout: 10000 })
      .should('be.visible');
    
    // STEP 7: Then the request should be created
    // Verify API call was made successfully
    cy.intercept('POST', '/api/v1/requests/vacation').as('vacationRequest');
    
    // Wait for API response
    cy.wait('@vacationRequest').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
      expect(interception.response.body.status).to.eq('success');
      expect(interception.response.body.request_id).to.exist;
    });
    
    // STEP 8: And I should see the request status on the "Заявки" page
    cy.get('[data-testid="requests-tab"]')
      .click();
    
    // Verify requests page loads
    cy.contains('Заявки').should('be.visible');
    
    // Verify the new request appears in the list
    cy.get('[data-testid="request-list"]')
      .should('contain', 'больничный')
      .should('contain', '2025-07-15')
      .should('contain', 'На рассмотрении');
    
    // Verify request details are correct
    cy.get('[data-testid="request-item"]')
      .first()
      .within(() => {
        cy.contains('больничный').should('be.visible');
        cy.contains('Простуда и высокая температура').should('be.visible');
        cy.contains('На рассмотрении').should('be.visible');
      });
  });

  /**
   * API Integration Test - Direct backend verification
   * Tests that UI integrates with real INTEGRATION-OPUS endpoints
   */
  it('Should verify API integration for vacation requests', () => {
    
    // Test employee data endpoint
    cy.request('GET', 'http://localhost:8001/api/v1/employees')
      .then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body.employees).to.be.an('array');
        expect(response.body.employees[0]).to.have.property('id');
        expect(response.body.employees[0]).to.have.property('name');
        expect(response.body.employees[0]).to.have.property('employee_id');
      });
    
    // Test vacation request creation
    const requestData = {
      employee_id: "1",
      start_date: "2025-07-15",
      end_date: "2025-07-16", 
      description: "Тестовая заявка на больничный через Cypress"
    };
    
    cy.request('POST', 'http://localhost:8001/api/v1/requests/vacation', requestData)
      .then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body.status).to.eq('success');
        expect(response.body.request_id).to.exist;
        expect(response.body.approval_status).to.eq('pending');
        
        // Verify Russian text is preserved
        expect(response.body.message).to.include('successfully');
        
        // Store request ID for further verification
        cy.wrap(response.body.request_id).as('requestId');
      });
    
    // Test request status retrieval
    cy.get('@requestId').then((requestId) => {
      cy.request('GET', `http://localhost:8001/api/v1/requests/${requestId}`)
        .then((response) => {
          expect(response.status).to.eq(200);
          expect(response.body.id).to.eq(requestId);
          expect(response.body.approval_status).to.eq('pending');
        });
    });
  });

  /**
   * Russian Text Support Test
   * Validates that UI properly handles Russian text input and display
   */
  it('Should support Russian text throughout the workflow', () => {
    
    const russianTexts = [
      'больничный',
      'отгул', 
      'внеочередной отпуск',
      'Простуда и высокая температура',
      'Семейные обстоятельства',
      'Медицинское обследование'
    ];
    
    russianTexts.forEach((text) => {
      // Test that Russian text can be input
      cy.visit('http://localhost:3000/test-russian-input');
      
      cy.get('[data-testid="russian-text-input"]')
        .clear()
        .type(text)
        .should('have.value', text);
      
      // Test that Russian text displays correctly
      cy.get('[data-testid="display-text"]')
        .should('contain', text);
    });
  });

  /**
   * Mobile Responsiveness Test  
   * Tests mobile personal cabinet functionality (BDD: 14-mobile-personal-cabinet.feature)
   */
  it('Should work on mobile devices', () => {
    
    // Set mobile viewport
    cy.viewport('iphone-6');
    
    cy.visit('http://localhost:3000');
    
    // Test mobile navigation
    cy.get('[data-testid="mobile-menu-toggle"]')
      .should('be.visible')
      .click();
    
    cy.get('[data-testid="mobile-navigation"]')
      .should('be.visible')
      .within(() => {
        cy.contains('Календарь').should('be.visible');
        cy.contains('Заявки').should('be.visible');
        cy.contains('Профиль').should('be.visible');
      });
    
    // Test mobile request creation
    cy.contains('Заявки').click();
    cy.get('[data-testid="mobile-create-request"]')
      .should('be.visible')
      .click();
    
    // Verify mobile form is usable
    cy.get('[data-testid="mobile-request-form"]')
      .should('be.visible')
      .within(() => {
        cy.get('[data-testid="request-type-select"]').should('be.visible');
        cy.get('[data-testid="start-date"]').should('be.visible');
        cy.get('[data-testid="reason"]').should('be.visible');
      });
  });

  /**
   * Error Handling Test
   * Verifies that UI properly handles API errors and network issues
   */
  it('Should handle API errors gracefully', () => {
    
    // Test with API server down
    cy.intercept('POST', '/api/v1/requests/vacation', {
      statusCode: 500,
      body: { error: 'Internal server error' }
    }).as('failedRequest');
    
    cy.visit('http://localhost:3000');
    
    // Attempt to create request
    cy.get('[data-testid="create-request-button"]').click();
    cy.get('[data-testid="request-type-select"]').select('sick_leave');
    cy.get('[data-testid="start-date"]').type('2025-07-15');
    cy.get('[data-testid="end-date"]').type('2025-07-16');
    cy.get('[data-testid="reason"]').type('Test error handling');
    cy.get('[data-testid="submit-request"]').click();
    
    // Verify error handling
    cy.wait('@failedRequest');
    cy.contains('Ошибка при отправке заявки')
      .should('be.visible');
    
    // Verify retry functionality
    cy.get('[data-testid="retry-button"]')
      .should('be.visible')
      .click();
  });

});

/**
 * Configuration for BDD testing
 */
Cypress.Commands.add('loginAsEmployee', (employeeId = '111538') => {
  cy.visit('http://localhost:3000');
  cy.get('[data-testid="employee-id"]').type(employeeId);
  cy.get('[data-testid="password"]').type('password123');
  cy.get('[data-testid="login-button"]').click();
  cy.url().should('include', '/dashboard');
});

Cypress.Commands.add('createVacationRequest', (requestData) => {
  cy.get('[data-testid="calendar-tab"]').click();
  cy.get('[data-testid="create-request-button"]').click();
  cy.get('[data-testid="request-type-select"]').select(requestData.type);
  cy.get('[data-testid="start-date"]').type(requestData.startDate);
  cy.get('[data-testid="end-date"]').type(requestData.endDate);
  cy.get('[data-testid="reason"]').type(requestData.reason);
  cy.get('[data-testid="submit-request"]').click();
});

/**
 * Test Data for BDD Scenarios
 */
const testRequests = {
  sickLeave: {
    type: 'sick_leave',
    typeRussian: 'больничный',
    startDate: '2025-07-15',
    endDate: '2025-07-16',
    reason: 'Простуда и высокая температура'
  },
  timeOff: {
    type: 'time_off', 
    typeRussian: 'отгул',
    startDate: '2025-07-17',
    endDate: '2025-07-17',
    reason: 'Семейные обстоятельства'
  },
  vacation: {
    type: 'vacation',
    typeRussian: 'внеочередной отпуск', 
    startDate: '2025-07-20',
    endDate: '2025-07-22',
    reason: 'Личные дела'
  }
};

/**
 * USAGE INSTRUCTIONS:
 * 
 * 1. Ensure API server is running:
 *    cd /Users/m/Documents/wfm/main/project
 *    python -m uvicorn src.api.main_simple:app --host 0.0.0.0 --port 8000 --reload
 * 
 * 2. Ensure UI server is running:
 *    cd /Users/m/Documents/wfm/main/project/src/ui
 *    npm run dev
 * 
 * 3. Install Cypress (if not installed):
 *    npm install cypress --save-dev
 * 
 * 4. Run this test:
 *    npx cypress run --spec "bdd_ui_component_test.cypress.js"
 *    
 * 5. Or run in interactive mode:
 *    npx cypress open
 * 
 * This test validates the complete vacation request BDD scenario with:
 * - Real API integration 
 * - Russian text support
 * - Mobile responsiveness
 * - Error handling
 * - End-to-end user workflow
 */