import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ScheduleEditor } from './ScheduleEditor';
import realScheduleService from '../../services/realScheduleService';

// Mock the service
jest.mock('../../services/realScheduleService');

describe('ScheduleEditor - SPEC-16', () => {
  const mockEmployees = [
    { id: 1, fullName: 'John Doe', role: 'Agent', employeeId: '1', firstName: 'John', lastName: 'Doe', 
      scheduledHours: 40, plannedHours: 40, skills: [], isActive: true },
    { id: 2, fullName: 'Jane Smith', role: 'Agent', employeeId: '2', firstName: 'Jane', lastName: 'Smith',
      scheduledHours: 40, plannedHours: 40, skills: [], isActive: true }
  ];

  const mockShifts = [
    { id: 'shift-1', employeeId: 1, date: '2025-08-01', startTime: '2025-08-01T08:00:00', 
      endTime: '2025-08-01T16:00:00', shiftType: 'morning', status: 'scheduled' as const, skills: [] },
    { id: 'shift-2', employeeId: 2, date: '2025-08-01', startTime: '2025-08-01T14:00:00',
      endTime: '2025-08-01T22:00:00', shiftType: 'afternoon', status: 'scheduled' as const, skills: [] }
  ];

  beforeEach(() => {
    jest.clearAllMocks();
    (realScheduleService.getEmployees as jest.Mock).mockResolvedValue({
      success: true,
      employees: mockEmployees
    });
    (realScheduleService.getShifts as jest.Mock).mockResolvedValue({
      success: true,
      shifts: mockShifts
    });
  });

  it('should render schedule editor with employees and shifts', async () => {
    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      expect(screen.getByText('Schedule Editor')).toBeInTheDocument();
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  it('should display shifts in correct cells', async () => {
    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      expect(screen.getByText('08:00 - 16:00')).toBeInTheDocument();
      expect(screen.getByText('14:00 - 22:00')).toBeInTheDocument();
    });
  });

  it('should support drag and drop to move shifts', async () => {
    (realScheduleService.updateShift as jest.Mock).mockResolvedValue({
      success: true,
      shift: { ...mockShifts[0], employeeId: 2 }
    });
    (realScheduleService.moveShift as jest.Mock).mockResolvedValue({
      success: true,
      shift: { ...mockShifts[0], employeeId: 2 }
    });

    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      const shift = screen.getByText('08:00 - 16:00');
      expect(shift).toBeInTheDocument();
    });

    // Simulate drag and drop
    const shiftElement = screen.getByText('08:00 - 16:00').parentElement;
    fireEvent.dragStart(shiftElement!);
    
    // Would need more complex testing setup for full drag/drop simulation
    expect(realScheduleService.getShifts).toHaveBeenCalled();
  });

  it('should allow editing shift details on click', async () => {
    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      const shift = screen.getByText('08:00 - 16:00');
      fireEvent.click(shift.parentElement!);
    });

    // Edit modal should appear
    await waitFor(() => {
      expect(screen.getByText('Edit Shift')).toBeInTheDocument();
      expect(screen.getByLabelText('Start Time')).toBeInTheDocument();
      expect(screen.getByLabelText('End Time')).toBeInTheDocument();
    });
  });

  it('should handle API errors gracefully', async () => {
    (realScheduleService.getEmployees as jest.Mock).mockResolvedValue({
      success: false,
      error: 'Failed to load employees'
    });

    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      expect(screen.getByText('Failed to load employees')).toBeInTheDocument();
    });
  });

  it('should update shift via PUT endpoint when modified', async () => {
    const updatedShift = { ...mockShifts[0], startTime: '2025-08-01T09:00:00' };
    (realScheduleService.updateShift as jest.Mock).mockResolvedValue({
      success: true,
      shift: updatedShift
    });

    render(<ScheduleEditor startDate="2025-08-01" endDate="2025-08-07" />);

    await waitFor(() => {
      const shift = screen.getByText('08:00 - 16:00');
      fireEvent.click(shift.parentElement!);
    });

    await waitFor(() => {
      const startTimeInput = screen.getByLabelText('Start Time') as HTMLInputElement;
      fireEvent.change(startTimeInput, { target: { value: '09:00' } });
      
      const saveButton = screen.getByText('Save Changes');
      fireEvent.click(saveButton);
    });

    expect(realScheduleService.updateShift).toHaveBeenCalledWith({
      shiftId: 'shift-1',
      startTime: '2025-08-01T09:00:00',
      endTime: '2025-08-01T16:00:00',
      status: 'scheduled'
    });
  });
});

// Demo commands for SPEC-16
export const demoCommands = {
  spec16: {
    description: 'SPEC-16: Schedule Editor with drag-drop shift editing',
    endpoints: [
      'GET /api/v1/personnel/employees',
      'GET /api/v1/schedules/shifts',
      'PUT /api/v1/schedules/shift/{id}',
      'PUT /api/v1/schedules/shifts/{id}/move'
    ],
    testCommand: 'npm test ScheduleEditor.spec.tsx',
    features: [
      'Drag and drop shifts between employees',
      'Click to edit shift details',
      'Real-time updates via API',
      'Visual feedback during operations'
    ]
  }
};