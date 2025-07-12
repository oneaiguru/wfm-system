import React from 'react';
import { useDraggable } from '@dnd-kit/core';
import { Shift } from './types';

interface DraggableShiftProps {
  shift: Shift;
  isDragOverlay?: boolean;
  disabled?: boolean;
}

export const DraggableShift: React.FC<DraggableShiftProps> = ({ 
  shift, 
  isDragOverlay = false,
  disabled = false 
}) => {
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
    disabled
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
  } : undefined;

  const getShiftColor = () => {
    switch (shift.shiftTypeId) {
      case 'night':
        return 'bg-indigo-600 hover:bg-indigo-700';
      case 'overtime':
        return 'bg-red-600 hover:bg-red-700';
      default:
        return 'bg-green-600 hover:bg-green-700';
    }
  };

  const formatTime = (time: string) => time.substring(0, 5);

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...(disabled ? {} : listeners)}
      {...attributes}
      className={`
        w-full h-full rounded text-white text-xs flex flex-col items-center justify-center font-medium
        ${getShiftColor()}
        ${disabled ? '' : 'cursor-grab active:cursor-grabbing'}
        ${isDragOverlay ? 'rotate-3 scale-105 shadow-lg ring-2 ring-white ring-opacity-50' : ''}
        ${isDragging ? 'opacity-50' : ''}
        transition-all duration-200
      `}
      title={`${shift.startTime} - ${shift.endTime} (${Math.floor(shift.duration / 60)}h ${shift.duration % 60}m)`}
    >
      <span className="leading-tight">{formatTime(shift.startTime)}</span>
      <span className="opacity-60 text-[10px]">•••</span>
      <span className="leading-tight">{formatTime(shift.endTime)}</span>
    </div>
  );
};