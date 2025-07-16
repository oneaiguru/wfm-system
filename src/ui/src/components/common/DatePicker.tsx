import React from 'react';
import { Calendar } from 'lucide-react';

interface DatePickerProps {
  selected?: Date | null;
  onChange?: (date: Date | null) => void;
  placeholderText?: string;
  className?: string;
}

export const DatePicker: React.FC<DatePickerProps> = ({ 
  selected, 
  onChange, 
  placeholderText = 'Выберите дату', 
  className = '' 
}) => {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (onChange) {
      onChange(value ? new Date(value) : null);
    }
  };
  
  const formatDate = (date: Date | null) => {
    if (!date) return '';
    return date.toISOString().split('T')[0];
  };
  
  return (
    <div className={`relative ${className}`}>
      <input
        type="date"
        value={formatDate(selected)}
        onChange={handleChange}
        className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500"
        placeholder={placeholderText}
      />
      <Calendar className="absolute right-3 top-2.5 h-4 w-4 text-gray-400 pointer-events-none" />
    </div>
  );
};