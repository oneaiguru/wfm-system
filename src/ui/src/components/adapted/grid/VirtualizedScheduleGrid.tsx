import React, { useMemo, useCallback } from 'react';
import { FixedSizeList as List } from 'react-window';
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
import { DraggableShift } from './DraggableShift';
import { Employee, Shift, GridDate } from './types';
import { useGridSelection } from './hooks/useGridSelection';
import { useShiftManagement } from './hooks/useShiftManagement';

interface VirtualizedScheduleGridProps {
  employees: Employee[];
  dates: GridDate[];
  rowHeight?: number;
  visibleRows?: number;
  initialShifts?: Map<string, Shift>;
  onShiftMove?: (shift: Shift, targetEmployeeId: string, targetDate: string) => void;
  onCellSelect?: (selectedCells: Set<string>) => void;
  readonly?: boolean;
}

// Virtual row component
const VirtualRow: React.FC<{
  index: number;
  style: React.CSSProperties;
  data: {
    employees: Employee[];
    dates: GridDate[];
    getShiftForCell: (employeeId: string, dateIndex: number) => Shift | null;
    selectedCells: Set<string>;
    handleCellClick: (employeeId: string, dateIndex: number) => void;
    readonly: boolean;
  };
}> = ({ index, style, data }) => {
  const { employees, dates, getShiftForCell, selectedCells, handleCellClick, readonly } = data;
  const employee = employees[index];
  
  if (!employee) return null;

  const variance = employee.scheduledHours - employee.plannedHours;
  const isPositive = variance > 0;

  return (
    <div style={style}>
      <table className="w-full border-collapse">
        <tbody>
          <tr className={`h-12 ${index % 2 === 0 ? 'bg-white' : 'bg-gray-50'}`}>
            {/* Employee Info Cell */}
            <td className="w-80 px-4 py-2 border-r-2 border-gray-700 border-b border-gray-200">
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
        </tbody>
      </table>
    </div>
  );
};

export const VirtualizedScheduleGrid: React.FC<VirtualizedScheduleGridProps> = ({
  employees,
  dates,
  rowHeight = 48,
  visibleRows = 10,
  initialShifts = new Map(),
  onShiftMove,
  onCellSelect,
  readonly = false
}) => {
  const [activeShift, setActiveShift] = React.useState<Shift | null>(null);
  
  // Custom hooks
  const { selectedCells, handleCellClick } = useGridSelection(onCellSelect);
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

  const handleDragStart = useCallback((event: DragStartEvent) => {
    const { active } = event;
    const shiftData = active.data.current?.shift as Shift;
    setActiveShift(shiftData);
  }, []);

  const handleDragEnd = useCallback((event: DragEndEvent) => {
    const { active, over } = event;
    setActiveShift(null);

    if (!over || readonly) return;

    const sourceShift = active.data.current?.shift as Shift;
    const targetCell = over.data.current;

    if (!sourceShift || !targetCell || targetCell.type !== 'cell') return;

    const targetDate = dates[targetCell.dateIndex].dateString;
    const success = moveShift(sourceShift, targetCell.employeeId, targetDate);

    if (success && onShiftMove) {
      onShiftMove(sourceShift, targetCell.employeeId, targetDate);
    }
  }, [dates, moveShift, onShiftMove, readonly]);

  // Virtual list data
  const listData = useMemo(() => ({
    employees,
    dates,
    getShiftForCell,
    selectedCells,
    handleCellClick,
    readonly
  }), [employees, dates, getShiftForCell, selectedCells, handleCellClick, readonly]);

  const listHeight = rowHeight * visibleRows;

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {/* Header */}
        <div className="sticky top-0 z-20 bg-gray-50 border-b border-gray-200">
          <table className="w-full border-collapse">
            <thead>
              <tr>
                <th className="w-80 px-4 py-3 border-r-2 border-gray-700 text-left text-sm font-medium text-gray-900">
                  Employees ({employees.length})
                </th>
                {dates.map((date, index) => (
                  <th 
                    key={index}
                    className={`
                      w-[70px] px-1 py-3 border-r border-gray-200 text-center text-xs
                      ${date.isWeekend ? 'bg-gray-100 font-semibold' : 'bg-gray-50'}
                      ${date.isToday ? 'ring-2 ring-yellow-400' : ''}
                    `}
                  >
                    <div className="text-gray-700 font-medium">{date.dayName}</div>
                    <div className="text-gray-500 text-xs">
                      {String(date.day).padStart(2, '0')}.{String(date.month).padStart(2, '0')}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
          </table>
        </div>

        {/* Virtual List */}
        <List
          height={listHeight}
          itemCount={employees.length}
          itemSize={rowHeight}
          itemData={listData}
          width="100%"
          className="scrollbar-thin scrollbar-thumb-gray-400 scrollbar-track-gray-100"
        >
          {VirtualRow}
        </List>

        {/* Footer Stats */}
        <div className="border-t border-gray-200 px-4 py-3 bg-gray-50 flex justify-between items-center text-sm">
          <span className="text-gray-600">
            Showing: {employees.length} employees • Period: {dates.length} days
          </span>
          <div className="flex gap-4">
            <span className="text-gray-600">
              Coverage: <span className="font-medium text-green-600">
                {Math.round((shifts.size / (employees.length * dates.length)) * 100)}%
              </span>
            </span>
            <span className="text-gray-600">
              Selected: <span className="font-medium">{selectedCells.size}</span>
            </span>
            <span className="text-gray-600">
              Shifts: <span className="font-medium">{shifts.size}</span>
            </span>
          </div>
        </div>
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeShift ? <DraggableShift shift={activeShift} isDragOverlay /> : null}
      </DragOverlay>
    </DndContext>
  );
};