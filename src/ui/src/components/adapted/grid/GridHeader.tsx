import React from 'react';
import { GridDate } from './types';

interface GridHeaderProps {
  dates: GridDate[];
  onDateClick?: (dateIndex: number) => void;
}

export const GridHeader: React.FC<GridHeaderProps> = ({ dates, onDateClick }) => {
  return (
    <thead className="sticky top-0 z-20 bg-gray-50">
      <tr>
        <th className="w-80 px-4 py-3 bg-gray-50 border-r-2 border-gray-700 border-b text-left text-sm font-medium text-gray-900 sticky left-0 z-30">
          Employees
        </th>
        {dates.map((date, index) => (
          <th 
            key={index}
            className={`
              w-[70px] px-1 py-3 border-r border-b border-gray-200 text-center text-xs
              ${date.isWeekend ? 'bg-gray-100 font-semibold' : 'bg-gray-50'}
              ${date.isToday ? 'ring-2 ring-yellow-400' : ''}
              ${onDateClick ? 'cursor-pointer hover:bg-gray-200' : ''}
              transition-colors
            `}
            onClick={() => onDateClick?.(index)}
          >
            <div className="text-gray-700 font-medium">{date.dayName}</div>
            <div className="text-gray-500 text-xs">
              {String(date.day).padStart(2, '0')}.{String(date.month).padStart(2, '0')}
            </div>
          </th>
        ))}
      </tr>
    </thead>
  );
};