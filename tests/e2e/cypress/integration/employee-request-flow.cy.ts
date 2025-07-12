/**
 * E2E tests for employee request workflow
 */
describe('Employee Request Flow', () => {
  beforeEach(() => {
    // Reset database and seed test data
    cy.task('db:seed');
    
    // Login as employee
    cy.visit('/login');
    cy.get('[data-cy=email]').type('employee@test.com');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=login-btn]').click();
    
    // Wait for dashboard to load
    cy.get('[data-cy=employee-dashboard]').should('be.visible');
  });

  afterEach(() => {
    cy.task('db:cleanup');
  });

  describe('Vacation Request', () => {
    it('creates and tracks a vacation request', () => {
      // Navigate to requests page
      cy.get('[data-cy=nav-requests]').click();
      cy.url().should('include', '/requests');
      
      // Click create new request
      cy.get('[data-cy=create-request-btn]').click();
      
      // Select vacation request type
      cy.get('[data-cy=request-type-select]').click();
      cy.get('[data-cy=request-type-vacation]').click();
      
      // Fill in vacation details
      cy.get('[data-cy=vacation-start-date]').type('2024-02-01');
      cy.get('[data-cy=vacation-end-date]').type('2024-02-05');
      cy.get('[data-cy=vacation-reason]').type('Family vacation to Hawaii');
      
      // Check available balance
      cy.get('[data-cy=vacation-balance]').should('contain', '15 days available');
      cy.get('[data-cy=days-requested]').should('contain', '5 days');
      
      // Submit request
      cy.get('[data-cy=submit-request-btn]').click();
      
      // Verify confirmation
      cy.get('[data-cy=success-toast]').should('contain', 'Vacation request submitted successfully');
      
      // Check request appears in list
      cy.get('[data-cy=requests-list]').within(() => {
        cy.get('[data-cy=request-item]').first().within(() => {
          cy.get('[data-cy=request-status]').should('contain', 'Pending');
          cy.get('[data-cy=request-dates]').should('contain', 'Feb 1 - Feb 5, 2024');
          cy.get('[data-cy=request-type]').should('contain', 'Vacation');
        });
      });
      
      // Click on request to view details
      cy.get('[data-cy=request-item]').first().click();
      
      // Verify request details page
      cy.get('[data-cy=request-details]').within(() => {
        cy.get('[data-cy=request-id]').should('be.visible');
        cy.get('[data-cy=request-timeline]').should('be.visible');
        cy.get('[data-cy=approval-chain]').should('contain', 'Waiting for manager approval');
      });
    });

    it('handles vacation request with conflicts', () => {
      // Create request that conflicts with existing schedule
      cy.get('[data-cy=nav-requests]').click();
      cy.get('[data-cy=create-request-btn]').click();
      cy.get('[data-cy=request-type-select]').click();
      cy.get('[data-cy=request-type-vacation]').click();
      
      // Select dates that conflict with important shift
      cy.get('[data-cy=vacation-start-date]').type('2024-01-15');
      cy.get('[data-cy=vacation-end-date]').type('2024-01-17');
      
      // System should show conflict warning
      cy.get('[data-cy=conflict-warning]').should('be.visible');
      cy.get('[data-cy=conflict-warning]').should('contain', 'You are scheduled for critical shifts during this period');
      
      // Show affected shifts
      cy.get('[data-cy=affected-shifts]').within(() => {
        cy.get('[data-cy=shift-item]').should('have.length', 3);
        cy.get('[data-cy=shift-item]').first().should('contain', 'Jan 15: 08:00-16:00 (Sales)');
      });
      
      // Option to request anyway with justification
      cy.get('[data-cy=request-anyway-checkbox]').check();
      cy.get('[data-cy=urgent-reason]').should('be.visible');
      cy.get('[data-cy=urgent-reason]').type('Medical procedure that cannot be rescheduled');
      
      cy.get('[data-cy=submit-request-btn]').click();
      
      // Should be flagged as urgent
      cy.get('[data-cy=success-toast]').should('contain', 'Urgent vacation request submitted');
      cy.get('[data-cy=requests-list]').within(() => {
        cy.get('[data-cy=request-item]').first().should('have.class', 'urgent-request');
      });
    });
  });

  describe('Shift Swap Request', () => {
    it('completes a shift swap with another employee', () => {
      // View current schedule
      cy.get('[data-cy=nav-schedule]').click();
      cy.get('[data-cy=my-shifts]').should('be.visible');
      
      // Click on a future shift to swap
      cy.get('[data-cy=shift-2024-01-20-morning]').click();
      cy.get('[data-cy=shift-actions]').should('be.visible');
      cy.get('[data-cy=request-swap-btn]').click();
      
      // Fill swap request form
      cy.get('[data-cy=swap-reason]').type('Doctor appointment');
      cy.get('[data-cy=find-replacement]').click();
      
      // System suggests eligible employees
      cy.get('[data-cy=eligible-employees]').should('be.visible');
      cy.get('[data-cy=employee-suggestion]').should('have.length.greaterThan', 0);
      
      // Filter by skill match
      cy.get('[data-cy=filter-skill-match]').check();
      cy.get('[data-cy=employee-suggestion]').should('have.length.greaterThan', 0);
      
      // Select an employee
      cy.get('[data-cy=employee-suggestion]').first().within(() => {
        cy.get('[data-cy=employee-name]').should('contain', 'Jane Smith');
        cy.get('[data-cy=availability-status]').should('contain', 'Available');
        cy.get('[data-cy=select-employee-btn]').click();
      });
      
      // Submit swap request
      cy.get('[data-cy=submit-swap-request]').click();
      
      // Verify request sent
      cy.get('[data-cy=success-toast]').should('contain', 'Swap request sent to Jane Smith');
      
      // Switch to Jane's account to accept
      cy.get('[data-cy=logout]').click();
      cy.visit('/login');
      cy.get('[data-cy=email]').type('jane.smith@test.com');
      cy.get('[data-cy=password]').type('password123');
      cy.get('[data-cy=login-btn]').click();
      
      // Check notifications
      cy.get('[data-cy=notification-bell]').should('have.class', 'has-notifications');
      cy.get('[data-cy=notification-bell]').click();
      cy.get('[data-cy=notification-item]').first().click();
      
      // Review and accept swap
      cy.get('[data-cy=swap-request-details]').should('be.visible');
      cy.get('[data-cy=original-shift]').should('contain', 'Jan 20: 08:00-16:00');
      cy.get('[data-cy=requester-name]').should('contain', 'John Doe');
      cy.get('[data-cy=accept-swap-btn]').click();
      
      // Confirm acceptance
      cy.get('[data-cy=confirm-dialog]').within(() => {
        cy.get('[data-cy=confirm-message]').should('contain', 'Are you sure you want to accept this shift?');
        cy.get('[data-cy=confirm-btn]').click();
      });
      
      // Verify swap completed
      cy.get('[data-cy=success-toast]').should('contain', 'Shift swap accepted');
      cy.get('[data-cy=nav-schedule]').click();
      cy.get('[data-cy=shift-2024-01-20-morning]').should('exist');
    });

    it('handles shift swap marketplace', () => {
      cy.get('[data-cy=nav-marketplace]').click();
      
      // View available shifts for pickup
      cy.get('[data-cy=available-shifts-tab]').click();
      cy.get('[data-cy=shift-card]').should('have.length.greaterThan', 0);
      
      // Filter shifts
      cy.get('[data-cy=filter-date-range]').click();
      cy.get('[data-cy=date-start]').type('2024-01-15');
      cy.get('[data-cy=date-end]').type('2024-01-31');
      cy.get('[data-cy=apply-filters]').click();
      
      cy.get('[data-cy=filter-skills]').click();
      cy.get('[data-cy=skill-sales]').check();
      cy.get('[data-cy=apply-filters]').click();
      
      // View shift details
      cy.get('[data-cy=shift-card]').first().click();
      cy.get('[data-cy=shift-modal]').within(() => {
        cy.get('[data-cy=shift-date]').should('be.visible');
        cy.get('[data-cy=shift-time]').should('be.visible');
        cy.get('[data-cy=required-skills]').should('contain', 'Sales');
        cy.get('[data-cy=location]').should('be.visible');
        cy.get('[data-cy=current-coverage]').should('be.visible');
        
        // Check eligibility
        cy.get('[data-cy=eligibility-check]').should('contain', 'You are eligible for this shift');
        
        // Claim shift
        cy.get('[data-cy=claim-shift-btn]').click();
      });
      
      // Verify shift added to schedule
      cy.get('[data-cy=success-toast]').should('contain', 'Shift successfully added to your schedule');
      cy.get('[data-cy=nav-schedule]').click();
      cy.get('[data-cy=my-shifts]').should('contain', 'Jan 25: 14:00-22:00');
    });
  });

  describe('Time Off Request with Manager Approval', () => {
    it('follows complete approval workflow', () => {
      // Employee creates request
      cy.get('[data-cy=nav-requests]').click();
      cy.get('[data-cy=create-request-btn]').click();
      cy.get('[data-cy=request-type-select]').click();
      cy.get('[data-cy=request-type-time-off]').click();
      
      cy.get('[data-cy=time-off-date]').type('2024-01-25');
      cy.get('[data-cy=time-off-hours]').type('4');
      cy.get('[data-cy=time-off-reason]').select('Personal');
      cy.get('[data-cy=time-off-notes]').type('Need to handle some personal matters');
      
      cy.get('[data-cy=submit-request-btn]').click();
      
      // Get request ID for tracking
      cy.get('[data-cy=success-toast]').then(($toast) => {
        const requestId = $toast.text().match(/Request #(\d+)/)[1];
        
        // Switch to manager account
        cy.get('[data-cy=logout]').click();
        cy.visit('/login');
        cy.get('[data-cy=email]').type('manager@test.com');
        cy.get('[data-cy=password]').type('password123');
        cy.get('[data-cy=login-btn]').click();
        
        // Navigate to pending approvals
        cy.get('[data-cy=nav-approvals]').click();
        cy.get('[data-cy=pending-tab]').click();
        
        // Find the request
        cy.get(`[data-cy=request-${requestId}]`).within(() => {
          cy.get('[data-cy=requester-name]').should('contain', 'John Doe');
          cy.get('[data-cy=request-type]').should('contain', 'Time Off');
          cy.get('[data-cy=request-date]').should('contain', 'Jan 25');
          cy.get('[data-cy=view-details-btn]').click();
        });
        
        // Review request details
        cy.get('[data-cy=request-detail-modal]').within(() => {
          // Check coverage impact
          cy.get('[data-cy=coverage-impact]').should('be.visible');
          cy.get('[data-cy=coverage-before]').should('contain', '100%');
          cy.get('[data-cy=coverage-after]').should('contain', '87%');
          
          // Check employee history
          cy.get('[data-cy=employee-history-tab]').click();
          cy.get('[data-cy=time-off-balance]').should('be.visible');
          cy.get('[data-cy=recent-requests]').should('be.visible');
          
          // Add approval comment
          cy.get('[data-cy=approval-comment]').type('Approved. Please ensure your tasks are covered.');
          
          // Approve request
          cy.get('[data-cy=approve-btn]').click();
        });
        
        // Confirm approval
        cy.get('[data-cy=confirm-dialog]').within(() => {
          cy.get('[data-cy=confirm-btn]').click();
        });
        
        cy.get('[data-cy=success-toast]').should('contain', 'Request approved successfully');
      });
      
      // Switch back to employee to verify
      cy.get('[data-cy=logout]').click();
      cy.visit('/login');
      cy.get('[data-cy=email]').type('employee@test.com');
      cy.get('[data-cy=password]').type('password123');
      cy.get('[data-cy=login-btn]').click();
      
      // Check notification
      cy.get('[data-cy=notification-bell]').should('have.class', 'has-notifications');
      cy.get('[data-cy=notification-bell]').click();
      cy.get('[data-cy=notification-item]').first().should('contain', 'Your time off request has been approved');
      
      // Verify in calendar
      cy.get('[data-cy=nav-schedule]').click();
      cy.get('[data-cy=calendar-view]').click();
      cy.get('[data-cy=date-2024-01-25]').should('have.class', 'time-off-approved');
    });
  });

  describe('Mobile Responsiveness', () => {
    beforeEach(() => {
      cy.viewport('iphone-x');
    });

    it('works on mobile devices', () => {
      // Check mobile menu
      cy.get('[data-cy=mobile-menu-toggle]').should('be.visible');
      cy.get('[data-cy=mobile-menu-toggle]').click();
      
      // Navigate to requests
      cy.get('[data-cy=mobile-nav-requests]').click();
      
      // Create request on mobile
      cy.get('[data-cy=create-request-btn]').click();
      cy.get('[data-cy=request-type-select]').should('be.visible');
      
      // Check touch interactions
      cy.get('[data-cy=request-type-select]').click();
      cy.get('[data-cy=request-type-vacation]').click();
      
      // Date picker should be mobile-friendly
      cy.get('[data-cy=vacation-start-date]').click();
      cy.get('[data-cy=mobile-date-picker]').should('be.visible');
    });
  });
});