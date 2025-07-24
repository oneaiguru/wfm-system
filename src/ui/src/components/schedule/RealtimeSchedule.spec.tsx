import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { RealtimeSchedule } from './RealtimeSchedule';
import realScheduleService from '../../services/realScheduleService';

// Mock the service and fetch
jest.mock('../../services/realScheduleService');
global.fetch = jest.fn();

describe('RealtimeSchedule - SPEC-24', () => {
  const mockEmployees = [
    { id: 1, fullName: 'John Doe', role: 'Agent', employeeId: '1', firstName: 'John', lastName: 'Doe',
      scheduledHours: 40, plannedHours: 40, skills: [], isActive: true },
    { id: 2, fullName: 'Jane Smith', role: 'Agent', employeeId: '2', firstName: 'Jane', lastName: 'Smith',
      scheduledHours: 40, plannedHours: 40, skills: [], isActive: true }
  ];

  const now = new Date();
  const mockShifts = [
    { 
      id: 'shift-1', 
      employeeId: 1, 
      date: now.toISOString().split('T')[0], 
      startTime: `${now.toISOString().split('T')[0]}T${(now.getHours() - 1).toString().padStart(2, '0')}:00:00`,
      endTime: `${now.toISOString().split('T')[0]}T${(now.getHours() + 3).toString().padStart(2, '0')}:00:00`,
      shiftType: 'regular', 
      status: 'scheduled' as const, 
      skills: [] 
    },
    { 
      id: 'shift-2', 
      employeeId: 2, 
      date: now.toISOString().split('T')[0],
      startTime: `${now.toISOString().split('T')[0]}T${(now.getHours() + 1).toString().padStart(2, '0')}:00:00`,
      endTime: `${now.toISOString().split('T')[0]}T${(now.getHours() + 5).toString().padStart(2, '0')}:00:00`,
      shiftType: 'regular', 
      status: 'scheduled' as const, 
      skills: [] 
    }
  ];

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    
    (realScheduleService.getEmployees as jest.Mock).mockResolvedValue({
      success: true,
      employees: mockEmployees
    });
    
    (realScheduleService.getShifts as jest.Mock).mockResolvedValue({
      success: true,
      shifts: mockShifts
    });

    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      json: async () => ({ updates: [] })
    });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should render realtime schedule monitor', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      expect(screen.getByText('Realtime Schedule Monitor')).toBeInTheDocument();
      expect(screen.getByText('Live updates every 30 seconds')).toBeInTheDocument();
    });
  });

  it('should display currently working employees', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      expect(screen.getByText('Currently Working')).toBeInTheDocument();
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('1')).toBeInTheDocument(); // Count
    });
  });

  it('should display employees starting soon', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      expect(screen.getByText('Starting Soon')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  it('should show connection status', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      expect(screen.getByText('Connected')).toBeInTheDocument();
    });
  });

  it('should support auto-refresh toggle', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      const autoRefreshCheckbox = screen.getByLabelText('Auto-refresh');
      expect(autoRefreshCheckbox).toBeChecked();
      
      fireEvent.click(autoRefreshCheckbox);
      expect(autoRefreshCheckbox).not.toBeChecked();
    });
  });

  it('should fetch updates periodically when auto-refresh is enabled', async () => {
    render(<RealtimeSchedule refreshInterval={5} />);

    await waitFor(() => {
      expect(screen.getByText('Realtime Schedule Monitor')).toBeInTheDocument();
    });

    // Fast-forward time to trigger refresh
    jest.advanceTimersByTime(5000);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/schedules/realtime/updates'),
        expect.any(Object)
      );
    });
  });

  it('should handle realtime updates', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        updates: [{
          type: 'shift_created',
          employee_id: 3,
          employee_name: 'Mike Johnson',
          details: 'New shift created',
          shift: {
            id: 'shift-3',
            employeeId: 3,
            date: now.toISOString().split('T')[0],
            startTime: `${now.toISOString().split('T')[0]}T14:00:00`,
            endTime: `${now.toISOString().split('T')[0]}T22:00:00`,
            shiftType: 'regular',
            status: 'scheduled'
          }
        }]
      })
    });

    render(<RealtimeSchedule refreshInterval={1} />);

    jest.advanceTimersByTime(1000);

    await waitFor(() => {
      expect(screen.getByText('Recent Updates')).toBeInTheDocument();
      expect(screen.getByText('Mike Johnson')).toBeInTheDocument();
      expect(screen.getByText('New shift created')).toBeInTheDocument();
    });
  });

  it('should handle manual refresh', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      const refreshButton = screen.getByTitle('Refresh now');
      fireEvent.click(refreshButton);
    });

    expect(realScheduleService.getEmployees).toHaveBeenCalledTimes(2); // Initial + refresh
    expect(realScheduleService.getShifts).toHaveBeenCalledTimes(2);
  });

  it('should display summary statistics', async () => {
    render(<RealtimeSchedule />);

    await waitFor(() => {
      expect(screen.getByText('Total Employees')).toBeInTheDocument();
      expect(screen.getByText('2')).toBeInTheDocument(); // Total employees count
      
      expect(screen.getByText('Active Now')).toBeInTheDocument();
      expect(screen.getByText('Next 2 Hours')).toBeInTheDocument();
      expect(screen.getByText("Today's Shifts")).toBeInTheDocument();
    });
  });
});

// Demo commands for SPEC-24
export const demoCommands = {
  spec24: {
    description: 'SPEC-24: Realtime Schedule with live updates',
    endpoints: [
      'GET /api/v1/personnel/employees',
      'GET /api/v1/schedules/shifts',
      'GET /api/v1/schedules/realtime/updates',
      'WS /ws/schedules/realtime (future)'
    ],
    testCommand: 'npm test RealtimeSchedule.spec.tsx',
    features: [
      'Currently working employees display',
      'Upcoming shifts in next 2 hours',
      'Recent schedule updates feed',
      'Auto-refresh with configurable interval',
      'Manual refresh option',
      'Connection status indicator',
      'Summary statistics',
      'WebSocket support (fallback to polling)'
    ]
  }
};