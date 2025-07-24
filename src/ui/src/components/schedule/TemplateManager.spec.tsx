import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { TemplateManager } from './TemplateManager';

describe('TemplateManager - SPEC-20', () => {
  it('should render template manager wrapper', () => {
    render(<TemplateManager />);
    
    // Since this wraps ShiftTemplateManager, we just verify it renders
    expect(screen.getByTestId('template-manager')).toBeInTheDocument();
  });

  it('should delegate to ShiftTemplateManager component', async () => {
    render(<TemplateManager />);
    
    // ShiftTemplateManager will handle all the functionality
    await waitFor(() => {
      // The wrapped component should be rendered
      const container = screen.getByTestId('template-manager');
      expect(container).toBeInTheDocument();
      expect(container.children.length).toBeGreaterThan(0);
    });
  });
});

// Demo commands for SPEC-20
export const demoCommands = {
  spec20: {
    description: 'SPEC-20: Template Manager for shift templates',
    endpoints: [
      'GET /api/v1/schedules/templates',
      'POST /api/v1/schedules/templates',
      'PUT /api/v1/schedules/templates/{id}',
      'DELETE /api/v1/schedules/templates/{id}'
    ],
    testCommand: 'npm test TemplateManager.spec.tsx',
    features: [
      'List all shift templates',
      'Create new templates with customization',
      'Edit existing templates',
      'Delete templates',
      'Toggle active/inactive status',
      'Visual template preview'
    ],
    implementation: 'Uses existing ShiftTemplateManager component which already implements full CRUD functionality'
  }
};