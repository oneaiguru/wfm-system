import React, { useState, useCallback, useMemo } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay,
  DragStartEvent,
  DragEndEvent,
} from '@dnd-kit/core';
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable';
import { GridCell } from './GridCell';
import { GridHeader } from './GridHeader';
import { DraggableShift } from './DraggableShift';
import { useGridSelection } from './hooks/useGridSelection';
import { useShiftManagement } from './hooks/useShiftManagement';
import { Employee, Shift, GridDate } from './types';

interface ScheduleGridProps {
  employees: Employee[];
  dates: GridDate[];
  initialShifts?: Map<string, Shift>;
  onShiftMove?: (shift: Shift, targetEmployeeId: string, targetDate: string) => void;
  onCellSelect?: (selectedCells: Set<string>) => void;
  readonly?: boolean;
  className?: string;
}

export const ScheduleGrid: React.FC<ScheduleGridProps> = ({
  employees,
  dates,
  initialShifts = new Map(),
  onShiftMove,
  onCellSelect,
  readonly = false,
  className = ''
}) => {
  // State management
  const [activeShift, setActiveShift] = useState<Shift | null>(null);
  
  // Custom hooks for selection and shift management
  const { selectedCells, handleCellClick, clearSelection } = useGridSelection(onCellSelect);
  const { shifts, moveShift, getShiftForCell } = useShiftManagement(initialShifts);

  // Drag and drop sensors
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Handle drag start
  const handleDragStart = useCallback((event: DragStartEvent) => {
    const { active } = event;
    const shiftData = active.data.current?.shift as Shift;
    setActiveShift(shiftData);
  }, []);

  // Handle drag end
  const handleDragEnd = useCallback((event: DragEndEvent) => {
    const { active, over } = event;
    setActiveShift(null);

    if (!over || readonly) return;

    const sourceShift = active.data.current?.shift as Shift;
    const targetCell = over.data.current;

    if (!sourceShift || !targetCell || targetCell.type !== 'cell') return;

    const sourceDateIndex = dates.findIndex(d => d.dateString === sourceShift.date);
    const sourceKey = `${sourceShift.employeeId}-${sourceDateIndex}`;
    const targetKey = `${targetCell.employeeId}-${targetCell.dateIndex}`;

    if (sourceKey === targetKey) return;

    // Perform the move
    const targetDate = dates[targetCell.dateIndex].dateString;
    const success = moveShift(sourceShift, targetCell.employeeId, targetDate);

    if (success && onShiftMove) {
      onShiftMove(sourceShift, targetCell.employeeId, targetDate);
    }
  }, [dates, moveShift, onShiftMove, readonly]);

  // Memoized row rendering for performance
  const renderEmployeeRow = useCallback((employee: Employee, empIndex: number) => {
    const variance = employee.scheduledHours - employee.plannedHours;
    const isPositive = variance > 0;

    return (
      <tr 
        key={employee.id}
        className={`h-12 ${empIndex % 2 === 0 ? 'bg-white' : 'bg-gray-50'} hover:bg-gray-100 transition-colors`}
      >
        {/* Employee Info Cell */}
        <td className="px-4 py-2 border-r-2 border-gray-700 bg-inherit sticky left-0 z-10">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-sm font-bold text-blue-700">
              {employee.photo}
            </div>
            
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-gray-900 truncate">
                {employee.fullName}
              </div>
              <div className="text-xs text-gray-600">
                {employee.role}
              </div>
              <div className="text-xs">
                <span className="text-gray-900 font-medium">{employee.scheduledHours}</span>
                <span className="text-gray-600"> / {employee.plannedHours}</span>
                <span className="text-gray-600"> | </span>
                <span className={isPositive ? 'text-green-600' : 'text-red-600'}>
                  {isPositive ? '+' : ''}{variance} h
                </span>
              </div>
            </div>
          </div>
        </td>
        
        {/* Schedule Cells */}
        {dates.map((date, dateIndex) => {
          const shift = getShiftForCell(employee.id, dateIndex);
          const cellId = `${employee.id}-${dateIndex}`;
          const isSelected = selectedCells.has(cellId);
          
          return (
            <GridCell
              key={dateIndex}
              employeeId={employee.id}
              dateIndex={dateIndex}
              date={date}
              shift={shift}
              isSelected={isSelected}
              onCellClick={handleCellClick}
              readonly={readonly}
            />
          );
        })}
      </tr>
    );
  }, [dates, getShiftForCell, selectedCells, handleCellClick, readonly]);

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className={`relative overflow-auto bg-white rounded-lg shadow-sm ${className}`}>
        <table className="w-full border-collapse">
          <GridHeader dates={dates} />
          <tbody>
            {employees.map((employee, index) => renderEmployeeRow(employee, index))}
          </tbody>
        </table>
        
        {/* Selection info */}
        {selectedCells.size > 0 && (
          <div className="absolute bottom-4 right-4 bg-blue-600 text-white px-3 py-1 rounded-full text-sm shadow-lg">
            {selectedCells.size} cells selected
            <button
              onClick={clearSelection}
              className="ml-2 hover:text-blue-200"
            >
              ✕
            </button>
          </div>
        )}
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeShift ? <DraggableShift shift={activeShift} isDragOverlay /> : null}
      </DragOverlay>
    </DndContext>
  );
};