import React, { useState, useEffect, useRef } from 'react';
import { Calendar, Clock, Save, User, AlertCircle, Move, Edit3 } from 'lucide-react';
import realScheduleService, { Shift, Employee } from '../../services/realScheduleService';

interface ScheduleEditorProps {
  startDate: string;
  endDate: string;
  departmentId?: number;
  onScheduleUpdate?: () => void;
}

interface DraggedShift {
  shift: Shift;
  originalEmployeeId: number;
}

export const ScheduleEditor: React.FC<ScheduleEditorProps> = ({
  startDate,
  endDate,
  departmentId,
  onScheduleUpdate
}) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [saving, setSaving] = useState(false);
  const [draggedShift, setDraggedShift] = useState<DraggedShift | null>(null);
  const [highlightedCell, setHighlightedCell] = useState<{ employeeId: number; date: string } | null>(null);
  const [editingShift, setEditingShift] = useState<Shift | null>(null);

  const gridRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadScheduleData();
  }, [startDate, endDate, departmentId]);

  const loadScheduleData = async () => {
    setLoading(true);
    setError('');

    try {
      // Load employees and shifts
      const [employeesResult, shiftsResult] = await Promise.all([
        realScheduleService.getEmployees(false),
        realScheduleService.getShifts(startDate, endDate)
      ]);

      if (employeesResult.success && employeesResult.employees) {
        setEmployees(employeesResult.employees);
      } else {
        throw new Error(employeesResult.error || 'Failed to load employees');
      }

      if (shiftsResult.success && shiftsResult.shifts) {
        setShifts(shiftsResult.shifts);
      } else {
        throw new Error(shiftsResult.error || 'Failed to load shifts');
      }
    } catch (err) {
      console.error('Schedule loading error:', err);
      setError(err instanceof Error ? err.message : 'Failed to load schedule data');
    } finally {
      setLoading(false);
    }
  };

  const getDatesInRange = () => {
    const dates: string[] = [];
    const current = new Date(startDate);
    const end = new Date(endDate);

    while (current <= end) {
      dates.push(current.toISOString().split('T')[0]);
      current.setDate(current.getDate() + 1);
    }

    return dates;
  };

  const getShiftForCell = (employeeId: number, date: string): Shift | undefined => {
    return shifts.find(shift => 
      shift.employeeId === employeeId && 
      shift.date === date
    );
  };

  const handleDragStart = (e: React.DragEvent, shift: Shift, employeeId: number) => {
    setDraggedShift({ shift, originalEmployeeId: employeeId });
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', ''); // Firefox compatibility
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  };

  const handleDragEnter = (e: React.DragEvent, employeeId: number, date: string) => {
    e.preventDefault();
    setHighlightedCell({ employeeId, date });
  };

  const handleDragLeave = (e: React.DragEvent) => {
    const relatedTarget = e.relatedTarget as HTMLElement;
    if (!relatedTarget || !relatedTarget.closest('.schedule-cell')) {
      setHighlightedCell(null);
    }
  };

  const handleDrop = async (e: React.DragEvent, targetEmployeeId: number, targetDate: string) => {
    e.preventDefault();
    setHighlightedCell(null);

    if (!draggedShift) return;

    const { shift, originalEmployeeId } = draggedShift;

    // Don't do anything if dropped on the same cell
    if (shift.employeeId === targetEmployeeId && shift.date === targetDate) {
      setDraggedShift(null);
      return;
    }

    setSaving(true);
    setError('');

    try {
      // Check if there's already a shift in the target cell
      const existingShift = getShiftForCell(targetEmployeeId, targetDate);
      if (existingShift) {
        throw new Error('Target cell already has a shift. Please remove it first.');
      }

      // Update shift via API
      const result = await realScheduleService.updateShift({
        shiftId: shift.id,
        // If date changed, we need to update times to match the new date
        ...(shift.date !== targetDate && {
          startTime: shift.startTime.replace(shift.date, targetDate),
          endTime: shift.endTime.replace(shift.date, targetDate)
        })
      });

      if (result.success) {
        // Then move it to new employee if needed
        if (shift.employeeId !== targetEmployeeId) {
          const moveResult = await realScheduleService.moveShift(
            shift.id,
            targetEmployeeId,
            shift.startTime.replace(shift.date, targetDate),
            shift.endTime.replace(shift.date, targetDate)
          );

          if (!moveResult.success) {
            throw new Error(moveResult.error || 'Failed to move shift');
          }
        }

        // Update local state
        setShifts(prev => prev.map(s => 
          s.id === shift.id 
            ? { ...s, employeeId: targetEmployeeId, date: targetDate,
                startTime: s.startTime.replace(s.date, targetDate),
                endTime: s.endTime.replace(s.date, targetDate) }
            : s
        ));

        if (onScheduleUpdate) {
          onScheduleUpdate();
        }
      } else {
        throw new Error(result.error || 'Failed to update shift');
      }
    } catch (err) {
      console.error('Failed to move shift:', err);
      setError(err instanceof Error ? err.message : 'Failed to move shift');
    } finally {
      setSaving(false);
      setDraggedShift(null);
    }
  };

  const handleShiftClick = (shift: Shift) => {
    setEditingShift(shift);
  };

  const handleShiftUpdate = async (updatedShift: Shift) => {
    setSaving(true);
    setError('');

    try {
      const result = await realScheduleService.updateShift({
        shiftId: updatedShift.id,
        startTime: updatedShift.startTime,
        endTime: updatedShift.endTime,
        status: updatedShift.status
      });

      if (result.success && result.shift) {
        setShifts(prev => prev.map(s => 
          s.id === updatedShift.id ? result.shift! : s
        ));
        setEditingShift(null);
        
        if (onScheduleUpdate) {
          onScheduleUpdate();
        }
      } else {
        throw new Error(result.error || 'Failed to update shift');
      }
    } catch (err) {
      console.error('Failed to update shift:', err);
      setError(err instanceof Error ? err.message : 'Failed to update shift');
    } finally {
      setSaving(false);
    }
  };

  const formatShiftTime = (shift: Shift) => {
    const start = new Date(shift.startTime);
    const end = new Date(shift.endTime);
    return `${start.getHours().toString().padStart(2, '0')}:${start.getMinutes().toString().padStart(2, '0')} - ${end.getHours().toString().padStart(2, '0')}:${end.getMinutes().toString().padStart(2, '0')}`;
  };

  const getShiftColor = (shift: Shift) => {
    switch (shift.shiftType) {
      case 'morning': return 'bg-yellow-100 border-yellow-300 text-yellow-800';
      case 'afternoon': return 'bg-blue-100 border-blue-300 text-blue-800';
      case 'night': return 'bg-purple-100 border-purple-300 text-purple-800';
      case 'overtime': return 'bg-red-100 border-red-300 text-red-800';
      default: return 'bg-green-100 border-green-300 text-green-800';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Loading schedule editor...</p>
        </div>
      </div>
    );
  }

  const dates = getDatesInRange();

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6" data-testid="schedule-editor">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">Schedule Editor</h2>
          <p className="text-sm text-gray-600 mt-1">
            Drag and drop shifts to reschedule employees
          </p>
        </div>
        
        {saving && (
          <div className="flex items-center gap-2 text-sm text-blue-600">
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
            <span>Saving changes...</span>
          </div>
        )}
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2">
          <AlertCircle className="h-4 w-4 text-red-600 flex-shrink-0" />
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}

      {/* Instructions */}
      <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
        <div className="flex items-center gap-2 mb-2">
          <Move className="h-4 w-4 text-blue-600" />
          <span className="text-sm font-medium text-blue-900">How to use:</span>
        </div>
        <ul className="text-sm text-blue-800 space-y-1 ml-6">
          <li>• Drag shifts from one cell to another to reassign</li>
          <li>• Click on a shift to edit its details</li>
          <li>• Changes are saved automatically</li>
        </ul>
      </div>

      {/* Schedule Grid */}
      <div className="overflow-x-auto" ref={gridRef}>
        <div className="min-w-max">
          {/* Date Headers */}
          <div className="grid grid-cols-[200px_repeat(7,1fr)] gap-1 mb-2">
            <div className="p-3 font-medium text-gray-700">Employee</div>
            {dates.map(date => {
              const dateObj = new Date(date);
              const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'short' });
              const dayNum = dateObj.getDate();
              return (
                <div key={date} className="p-3 text-center">
                  <div className="text-sm font-medium text-gray-700">{dayName}</div>
                  <div className="text-xs text-gray-500">{dayNum}</div>
                </div>
              );
            })}
          </div>

          {/* Employee Rows */}
          {employees.map(employee => (
            <div key={employee.id} className="grid grid-cols-[200px_repeat(7,1fr)] gap-1 mb-1">
              {/* Employee Name */}
              <div className="p-3 bg-gray-50 border border-gray-200 rounded flex items-center gap-2">
                <User className="h-4 w-4 text-gray-400" />
                <div>
                  <div className="font-medium text-sm text-gray-900">{employee.fullName}</div>
                  <div className="text-xs text-gray-500">{employee.role}</div>
                </div>
              </div>

              {/* Schedule Cells */}
              {dates.map(date => {
                const shift = getShiftForCell(employee.id, date);
                const isHighlighted = highlightedCell?.employeeId === employee.id && 
                                    highlightedCell?.date === date;

                return (
                  <div
                    key={`${employee.id}-${date}`}
                    className={`schedule-cell relative min-h-[80px] p-2 border rounded transition-colors ${
                      isHighlighted 
                        ? 'border-blue-400 bg-blue-50' 
                        : 'border-gray-200 bg-gray-50 hover:bg-gray-100'
                    }`}
                    onDragOver={handleDragOver}
                    onDragEnter={(e) => handleDragEnter(e, employee.id, date)}
                    onDragLeave={handleDragLeave}
                    onDrop={(e) => handleDrop(e, employee.id, date)}
                  >
                    {shift && (
                      <div
                        draggable
                        onDragStart={(e) => handleDragStart(e, shift, employee.id)}
                        onClick={() => handleShiftClick(shift)}
                        className={`cursor-move p-2 rounded border ${getShiftColor(shift)} 
                          hover:shadow-md transition-shadow`}
                      >
                        <div className="flex items-center gap-1 mb-1">
                          <Clock className="h-3 w-3" />
                          <span className="text-xs font-medium">{formatShiftTime(shift)}</span>
                        </div>
                        <div className="text-xs opacity-80">{shift.shiftType}</div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          ))}
        </div>
      </div>

      {/* Edit Shift Modal */}
      {editingShift && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96 max-w-full">
            <h3 className="text-lg font-semibold mb-4">Edit Shift</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Start Time
                </label>
                <input
                  type="time"
                  value={editingShift.startTime.split('T')[1]?.substring(0, 5) || ''}
                  onChange={(e) => setEditingShift({
                    ...editingShift,
                    startTime: `${editingShift.date}T${e.target.value}:00`
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  End Time
                </label>
                <input
                  type="time"
                  value={editingShift.endTime.split('T')[1]?.substring(0, 5) || ''}
                  onChange={(e) => setEditingShift({
                    ...editingShift,
                    endTime: `${editingShift.date}T${e.target.value}:00`
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Status
                </label>
                <select
                  value={editingShift.status}
                  onChange={(e) => setEditingShift({
                    ...editingShift,
                    status: e.target.value as Shift['status']
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                >
                  <option value="scheduled">Scheduled</option>
                  <option value="confirmed">Confirmed</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => handleShiftUpdate(editingShift)}
                disabled={saving}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 
                  disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                <Save className="h-4 w-4" />
                Save Changes
              </button>
              <button
                onClick={() => setEditingShift(null)}
                className="flex-1 px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ScheduleEditor;