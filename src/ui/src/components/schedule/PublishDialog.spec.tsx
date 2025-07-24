import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { PublishDialog } from './PublishDialog';

// Mock fetch
global.fetch = jest.fn();

describe('PublishDialog - SPEC-22', () => {
  const mockScheduleData = {
    startDate: '2025-08-01',
    endDate: '2025-08-07',
    employeeCount: 10,
    shiftCount: 50,
    departments: ['Customer Service', 'Sales']
  };

  const mockOnClose = jest.fn();
  const mockOnConfirm = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      json: async () => ({
        affected_employees: [
          { id: 1, name: 'John Doe', department: 'Customer Service', shiftsCount: 5, totalHours: 40 },
          { id: 2, name: 'Jane Smith', department: 'Sales', shiftsCount: 4, totalHours: 32 }
        ]
      })
    });
  });

  it('should render publish dialog when open', () => {
    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    expect(screen.getByText('Publish Schedule')).toBeInTheDocument();
    expect(screen.getByText('Schedule Summary')).toBeInTheDocument();
  });

  it('should not render when closed', () => {
    render(
      <PublishDialog 
        isOpen={false}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    expect(screen.queryByText('Publish Schedule')).not.toBeInTheDocument();
  });

  it('should display schedule summary information', () => {
    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    expect(screen.getByText(/Aug 1, 2025 - Aug 7, 2025/)).toBeInTheDocument();
    expect(screen.getByText('50')).toBeInTheDocument(); // shift count
    expect(screen.getByText('10')).toBeInTheDocument(); // employee count
    expect(screen.getByText('Customer Service, Sales')).toBeInTheDocument();
  });

  it('should load and display affected employees', async () => {
    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('40h')).toBeInTheDocument();
      expect(screen.getByText('32h')).toBeInTheDocument();
    });
  });

  it('should handle notification options', () => {
    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    const employeeCheckbox = screen.getByLabelText('Notify employees about their schedules');
    const managerCheckbox = screen.getByLabelText('Notify managers about published schedules');

    expect(employeeCheckbox).toBeChecked();
    expect(managerCheckbox).toBeChecked();

    fireEvent.click(employeeCheckbox);
    expect(employeeCheckbox).not.toBeChecked();
  });

  it('should publish schedule when confirmed', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ affected_employees: [] })
    }).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true, published_count: 50 })
    });

    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    const publishButton = screen.getByText('Publish Schedule');
    fireEvent.click(publishButton);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/schedules/publish'),
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json'
          }),
          body: expect.stringContaining('notify_employees')
        })
      );
    });

    expect(mockOnConfirm).toHaveBeenCalled();
  });

  it('should display error message on publish failure', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ affected_employees: [] })
    }).mockResolvedValueOnce({
      ok: false,
      json: async () => ({ detail: 'Schedule conflicts detected' })
    });

    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    const publishButton = screen.getByText('Publish Schedule');
    fireEvent.click(publishButton);

    await waitFor(() => {
      expect(screen.getByText('Schedule conflicts detected')).toBeInTheDocument();
    });
  });

  it('should close dialog when cancel is clicked', () => {
    render(
      <PublishDialog 
        isOpen={true}
        onClose={mockOnClose}
        onConfirm={mockOnConfirm}
        scheduleData={mockScheduleData}
      />
    );

    const cancelButton = screen.getByText('Cancel');
    fireEvent.click(cancelButton);

    expect(mockOnClose).toHaveBeenCalled();
  });
});

// Demo commands for SPEC-22
export const demoCommands = {
  spec22: {
    description: 'SPEC-22: Publish Dialog with confirmation and notifications',
    endpoints: [
      'POST /api/v1/schedules/publish/preview',
      'POST /api/v1/schedules/publish'
    ],
    testCommand: 'npm test PublishDialog.spec.tsx',
    features: [
      'Display affected employees and dates',
      'Schedule summary with metrics',
      'Notification options for employees and managers',
      'Custom message support',
      'Validation warnings',
      'Confirmation before publishing'
    ]
  }
};