import React from 'react';
import ShiftTemplateManager from '../../modules/schedule-grid-system/components/ShiftTemplateManager';

// SPEC-20: Template Manager Component
// This component wraps the existing ShiftTemplateManager which already implements
// all required functionality for template CRUD operations

export const TemplateManager: React.FC = () => {
  return (
    <div data-testid="template-manager">
      <ShiftTemplateManager />
    </div>
  );
};

export default TemplateManager;