import React from 'react';
import { useDraggable, useDroppable } from '@dnd-kit/core';
import { Shift } from '../types/schedule';

// Draggable Shift Block Component
export const DraggableShiftBlock: React.FC<{
  shift: Shift;
  isDragOverlay?: boolean;
}> = ({ shift, isDragOverlay = false }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    isDragging,
  } = useDraggable({
    id: shift.id,
    data: {
      shift,
      type: 'shift',
    },
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    opacity: isDragging ? 0.5 : 1,
  } : undefined;

  return (
    <div
      ref={setNodeRef}
      style={{
        ...style,
        backgroundColor: shift.shiftTypeId === 'night' ? '#4f46e5' : '#74a689',
      }}
      {...listeners}
      {...attributes}
      className={`w-full h-full rounded text-white text-xs flex flex-col items-center justify-center font-medium cursor-grab active:cursor-grabbing transition-all duration-200 ${
        isDragOverlay ? 'rotate-3 scale-105 shadow-lg' : ''
      } ${isDragging ? 'opacity-50' : ''}`}
      title={`${shift.startTime} - ${shift.endTime}`}
    >
      <span>{shift.startTime.substring(0, 5)}</span>
      <span style={{ opacity: 0.6 }}>...</span>
      <span>{shift.endTime.substring(0, 5)}</span>
    </div>
  );
};

// Droppable Grid Cell Component
export const DroppableGridCell: React.FC<{
  employeeId: string;
  dateIndex: number;
  date: any;
  shift: Shift | null;
  isSelected: boolean;
  onCellClick: (employeeId: string, dateIndex: number) => void;
}> = ({ employeeId, dateIndex, date, shift, isSelected, onCellClick }) => {
  const {
    isOver,
    setNodeRef
  } = useDroppable({
    id: `cell-${employeeId}-${dateIndex}`,
    data: {
      employeeId,
      dateIndex,
      type: 'cell',
    },
  });

  return (
    <td 
      ref={setNodeRef}
      className={`w-[70px] h-[50px] p-1 border-r border-b cursor-pointer relative transition-colors ${
        isOver ? 'bg-blue-200' : 
        isSelected ? 'bg-blue-100' : 
        date.isToday ? 'bg-yellow-50' : 
        date.isWeekend ? 'bg-gray-100' : 'bg-transparent'
      }`}
      onClick={() => onCellClick(employeeId, dateIndex)}
    >
      {shift ? (
        <DraggableShiftBlock shift={shift} />
      ) : (
        <div className={`w-full h-full rounded flex items-center justify-center transition-all ${
          isOver ? 'bg-blue-50 border-2 border-dashed border-blue-500' : 'bg-gray-100 border border-transparent'
        }`}>
          <span className="text-gray-400 text-xs">
            {isOver ? '📍' : '—'}
          </span>
        </div>
      )}
    </td>
  );
};