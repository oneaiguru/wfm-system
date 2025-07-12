/**
 * Unit tests for ScheduleGrid component
 */
import React from 'react';
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ScheduleGrid } from '@/components/ScheduleGrid';
import { mockScheduleData, mockEmployees } from '@tests/fixtures/scheduleData';
import { ScheduleProvider } from '@/contexts/ScheduleContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Mock dependencies
jest.mock('@/hooks/useWebSocket', () => ({
  useWebSocket: () => ({
    connected: true,
    send: jest.fn(),
    subscribe: jest.fn(),
    unsubscribe: jest.fn()
  })
}));

// Test wrapper with providers
const TestWrapper = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });

  return (
    <QueryClientProvider client={queryClient}>
      <ScheduleProvider>
        {children}
      </ScheduleProvider>
    </QueryClientProvider>
  );
};

describe('ScheduleGrid', () => {
  const defaultProps = {
    data: mockScheduleData,
    employees: mockEmployees,
    startDate: '2024-01-01',
    endDate: '2024-01-07',
    onCellClick: jest.fn(),
    onScheduleUpdate: jest.fn()
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders schedule grid with correct structure', () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      // Check header row
      expect(screen.getByText('Employee')).toBeInTheDocument();
      expect(screen.getByText('Mon 01/01')).toBeInTheDocument();
      expect(screen.getByText('Tue 01/02')).toBeInTheDocument();
      
      // Check employee rows
      mockEmployees.forEach(employee => {
        expect(screen.getByText(employee.name)).toBeInTheDocument();
      });

      // Check shift cells
      const shifts = screen.getAllByTestId(/schedule-cell-/);
      expect(shifts).toHaveLength(mockEmployees.length * 7); // 7 days
    });

    it('displays shift information correctly', () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      const firstShift = mockScheduleData.shifts[0];
      const shiftCell = screen.getByTestId(`schedule-cell-${firstShift.employeeId}-${firstShift.date}`);
      
      expect(shiftCell).toHaveTextContent('08:00-16:00');
      expect(shiftCell).toHaveClass('bg-blue-100');
    });

    it('highlights conflicts in red', () => {
      const dataWithConflicts = {
        ...mockScheduleData,
        conflicts: [
          { employeeId: 1, date: '2024-01-01', reason: 'Overlapping shifts' }
        ]
      };

      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} data={dataWithConflicts} />
        </TestWrapper>
      );

      const conflictCell = screen.getByTestId('schedule-cell-1-2024-01-01');
      expect(conflictCell).toHaveClass('bg-red-100');
      expect(conflictCell).toHaveAttribute('title', 'Overlapping shifts');
    });

    it('shows employee statistics', () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} showStats={true} />
        </TestWrapper>
      );

      // Check for stats columns
      expect(screen.getByText('Total Hours')).toBeInTheDocument();
      expect(screen.getByText('Avg Hours/Day')).toBeInTheDocument();
      
      // Check individual stats
      const employee1Stats = screen.getByTestId('employee-1-stats');
      expect(employee1Stats).toHaveTextContent('40'); // Total hours
      expect(employee1Stats).toHaveTextContent('8'); // Avg hours
    });
  });

  describe('Interactions', () => {
    it('handles cell click events', async () => {
      const user = userEvent.setup();
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      const cell = screen.getByTestId('schedule-cell-1-2024-01-01');
      await user.click(cell);

      expect(defaultProps.onCellClick).toHaveBeenCalledWith({
        employeeId: 1,
        date: '2024-01-01',
        currentShift: expect.any(Object)
      });
    });

    it('supports drag and drop for shift swapping', async () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} enableDragDrop={true} />
        </TestWrapper>
      );

      const sourceCell = screen.getByTestId('schedule-cell-1-2024-01-01');
      const targetCell = screen.getByTestId('schedule-cell-2-2024-01-01');

      // Simulate drag and drop
      fireEvent.dragStart(sourceCell);
      fireEvent.dragEnter(targetCell);
      fireEvent.dragOver(targetCell);
      fireEvent.drop(targetCell);
      fireEvent.dragEnd(sourceCell);

      await waitFor(() => {
        expect(defaultProps.onScheduleUpdate).toHaveBeenCalledWith({
          type: 'swap',
          source: { employeeId: 1, date: '2024-01-01' },
          target: { employeeId: 2, date: '2024-01-01' }
        });
      });
    });

    it('filters by employee or skill group', async () => {
      const user = userEvent.setup();
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} showFilters={true} />
        </TestWrapper>
      );

      // Filter by skill
      const skillFilter = screen.getByLabelText('Filter by skill');
      await user.selectOptions(skillFilter, 'support');

      // Should only show employees with support skill
      expect(screen.queryByText('John Doe')).not.toBeInTheDocument(); // Assuming John doesn't have support skill
      expect(screen.getByText('Jane Smith')).toBeInTheDocument(); // Assuming Jane has support skill
    });

    it('handles keyboard navigation', async () => {
      const user = userEvent.setup();
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      const firstCell = screen.getByTestId('schedule-cell-1-2024-01-01');
      firstCell.focus();

      // Navigate with arrow keys
      await user.keyboard('{ArrowRight}');
      expect(screen.getByTestId('schedule-cell-1-2024-01-02')).toHaveFocus();

      await user.keyboard('{ArrowDown}');
      expect(screen.getByTestId('schedule-cell-2-2024-01-02')).toHaveFocus();

      // Edit with Enter key
      await user.keyboard('{Enter}');
      expect(defaultProps.onCellClick).toHaveBeenCalled();
    });
  });

  describe('Advanced Features', () => {
    it('displays coverage metrics', () => {
      const dataWithCoverage = {
        ...mockScheduleData,
        coverage: {
          '2024-01-01': { required: 10, scheduled: 8, percentage: 0.8 },
          '2024-01-02': { required: 10, scheduled: 10, percentage: 1.0 }
        }
      };

      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} data={dataWithCoverage} showCoverage={true} />
        </TestWrapper>
      );

      const coverageRow = screen.getByTestId('coverage-row');
      expect(coverageRow).toHaveTextContent('80%'); // Monday
      expect(coverageRow).toHaveTextContent('100%'); // Tuesday
      
      // Check visual indicators
      const mondayCoverage = within(coverageRow).getByTestId('coverage-2024-01-01');
      expect(mondayCoverage).toHaveClass('text-orange-600'); // Under-coverage warning
    });

    it('exports schedule data', async () => {
      const user = userEvent.setup();
      const onExport = jest.fn();
      
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} onExport={onExport} showToolbar={true} />
        </TestWrapper>
      );

      const exportButton = screen.getByRole('button', { name: /export/i });
      await user.click(exportButton);

      const excelOption = screen.getByText('Export as Excel');
      await user.click(excelOption);

      expect(onExport).toHaveBeenCalledWith({
        format: 'excel',
        data: mockScheduleData,
        dateRange: { start: '2024-01-01', end: '2024-01-07' }
      });
    });

    it('handles real-time updates via WebSocket', async () => {
      const { rerender } = render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} enableRealTimeUpdates={true} />
        </TestWrapper>
      );

      // Simulate WebSocket update
      const updatedData = {
        ...mockScheduleData,
        shifts: [
          ...mockScheduleData.shifts,
          { employeeId: 3, date: '2024-01-01', startTime: '14:00', endTime: '22:00' }
        ]
      };

      rerender(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} data={updatedData} enableRealTimeUpdates={true} />
        </TestWrapper>
      );

      // Check new shift appears
      const newShift = screen.getByTestId('schedule-cell-3-2024-01-01');
      expect(newShift).toHaveTextContent('14:00-22:00');
      expect(newShift).toHaveClass('animate-highlight'); // Visual feedback for new data
    });
  });

  describe('Accessibility', () => {
    it('provides proper ARIA labels', () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      const grid = screen.getByRole('grid');
      expect(grid).toHaveAttribute('aria-label', 'Employee Schedule Grid');

      const cells = screen.getAllByRole('gridcell');
      cells.forEach(cell => {
        expect(cell).toHaveAttribute('aria-label');
      });
    });

    it('announces changes to screen readers', async () => {
      const user = userEvent.setup();
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} />
        </TestWrapper>
      );

      const cell = screen.getByTestId('schedule-cell-1-2024-01-01');
      await user.click(cell);

      const announcement = screen.getByRole('status');
      expect(announcement).toHaveTextContent('Editing shift for John Doe on Monday, January 1st');
    });
  });

  describe('Error Handling', () => {
    it('displays error message when data fails to load', () => {
      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} data={null} error="Failed to load schedule data" />
        </TestWrapper>
      );

      expect(screen.getByRole('alert')).toHaveTextContent('Failed to load schedule data');
      expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    });

    it('handles missing employee data gracefully', () => {
      const incompleteData = {
        ...mockScheduleData,
        shifts: [{ employeeId: 999, date: '2024-01-01', startTime: '08:00', endTime: '16:00' }]
      };

      render(
        <TestWrapper>
          <ScheduleGrid {...defaultProps} data={incompleteData} />
        </TestWrapper>
      );

      expect(screen.getByText('Unknown Employee')).toBeInTheDocument();
    });
  });
});