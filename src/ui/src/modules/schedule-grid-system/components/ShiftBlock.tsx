import React from 'react';
import { Shift } from '../types/schedule';

interface ShiftBlockProps {
  shift: Shift;
  onDragStart?: (e: React.DragEvent) => void;
  onDragEnd?: (e: React.DragEvent) => void;
  isDragging?: boolean;
  isSelected?: boolean;
  onClick?: () => void;
}

const ShiftBlock: React.FC<ShiftBlockProps> = ({
  shift,
  onDragStart,
  onDragEnd,
  isDragging = false,
  isSelected = false,
  onClick
}) => {
  const getShiftTypeClass = () => {
    switch (shift.shiftTypeId) {
      case 'night': return 'night-shift';
      case 'overtime': return 'overtime';
      default: return 'day-shift';
    }
  };

  const formatTime = (time: string) => time.substring(0, 5);

  return (
    <div 
      className={`schedule-shift-block ${getShiftTypeClass()} ${
        isDragging ? 'dragging' : ''
      } ${isSelected ? 'ring-2 ring-white ring-opacity-80' : ''}`}
      draggable
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      onClick={onClick}
      title={`${shift.startTime} - ${shift.endTime} (${Math.floor(shift.duration / 60)}ч ${shift.duration % 60}м)`}
    >
      <span className="text-xs leading-tight">{formatTime(shift.startTime)}</span>
      <span className="text-xs opacity-60">...</span>
      <span className="text-xs leading-tight">{formatTime(shift.endTime)}</span>
    </div>
  );
};

export default ShiftBlock;
