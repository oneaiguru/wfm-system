import React from 'react';
import { useDroppable } from '@dnd-kit/core';
import { DraggableShift } from './DraggableShift';
import { Shift, GridDate } from './types';

interface GridCellProps {
  employeeId: string;
  dateIndex: number;
  date: GridDate;
  shift: Shift | null;
  isSelected: boolean;
  onCellClick: (employeeId: string, dateIndex: number) => void;
  readonly?: boolean;
}

export const GridCell: React.FC<GridCellProps> = ({
  employeeId,
  dateIndex,
  date,
  shift,
  isSelected,
  onCellClick,
  readonly = false
}) => {
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
    disabled: readonly
  });

  const handleClick = () => {
    if (!readonly) {
      onCellClick(employeeId, dateIndex);
    }
  };

  const getCellBackground = () => {
    if (isOver) return 'bg-blue-200';
    if (isSelected) return 'bg-blue-100';
    if (date.isToday) return 'bg-yellow-50';
    if (date.isWeekend) return 'bg-gray-50';
    return 'bg-transparent';
  };

  return (
    <td 
      ref={setNodeRef}
      className={`
        w-[70px] h-12 p-1 border-r border-b border-gray-200
        cursor-pointer transition-all duration-200
        ${getCellBackground()}
        hover:bg-gray-100
      `}
      onClick={handleClick}
    >
      {shift ? (
        <DraggableShift shift={shift} disabled={readonly} />
      ) : (
        <div className={`
          w-full h-full rounded flex items-center justify-center
          ${isOver ? 'border-2 border-dashed border-blue-400 bg-blue-50' : 'bg-gray-100'}
          transition-all duration-200
        `}>
          <span className="text-gray-400 text-xs">
            {isOver ? '📍' : '—'}
          </span>
        </div>
      )}
    </td>
  );
};