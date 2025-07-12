import React, { useState } from 'react';
import { ChevronLeft, ChevronRight, Calendar, Clock } from 'lucide-react';

// BDD: Calendar view type can be: month, week, 4-day, day
type ViewType = 'month' | 'week' | '4day' | 'day';

const MobileCalendar: React.FC = () => {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewType, setViewType] = useState<ViewType>('month');
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);

  // Mock shift data
  const shifts = {
    '2024-07-15': { start: '09:00', end: '18:00', type: 'work' },
    '2024-07-16': { start: '09:00', end: '18:00', type: 'work' },
    '2024-07-17': { start: '14:00', end: '22:00', type: 'work' },
    '2024-07-18': { type: 'dayoff' },
    '2024-07-19': { start: '09:00', end: '18:00', type: 'work' },
    '2024-07-22': { type: 'vacation' },
    '2024-07-23': { type: 'vacation' },
    '2024-07-24': { type: 'vacation' }
  };

  const getShiftColor = (type: string) => {
    switch (type) {
      case 'work': return 'bg-blue-100 text-blue-800';
      case 'dayoff': return 'bg-gray-100 text-gray-800';
      case 'vacation': return 'bg-green-100 text-green-800';
      case 'sick': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const renderMonthView = () => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const days = [];

    // Empty cells for days before month starts
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="p-2" />);
    }

    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateKey = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const shift = shifts[dateKey];
      const isToday = new Date().getDate() === day && new Date().getMonth() === month;
      
      days.push(
        <button
          key={day}
          onClick={() => setSelectedDate(new Date(year, month, day))}
          className={`p-2 text-center rounded-lg transition-colors ${
            isToday ? 'ring-2 ring-blue-500' : ''
          } ${shift ? getShiftColor(shift.type) : 'hover:bg-gray-100'}`}
        >
          <div className="text-sm font-medium">{day}</div>
          {shift && shift.type === 'work' && (
            <div className="text-xs mt-1">{shift.start}</div>
          )}
        </button>
      );
    }

    return (
      <div className="grid grid-cols-7 gap-1">
        {['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'].map(day => (
          <div key={day} className="text-center text-xs font-semibold text-gray-600 p-2">
            {day}
          </div>
        ))}
        {days}
      </div>
    );
  };

  const renderWeekView = () => {
    const days = [];
    const startOfWeek = new Date(currentDate);
    startOfWeek.setDate(currentDate.getDate() - currentDate.getDay());

    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek);
      date.setDate(startOfWeek.getDate() + i);
      const dateKey = date.toISOString().split('T')[0];
      const shift = shifts[dateKey];
      
      days.push(
        <div key={i} className="border-b border-gray-200 p-4">
          <div className="flex justify-between items-center mb-2">
            <div>
              <p className="font-medium text-gray-900">
                {date.toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' })}
              </p>
            </div>
            {shift && (
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${getShiftColor(shift.type)}`}>
                {shift.type === 'work' ? `${shift.start} - ${shift.end}` : 
                 shift.type === 'dayoff' ? 'Выходной' : 'Отпуск'}
              </span>
            )}
          </div>
        </div>
      );
    }

    return <div className="space-y-1">{days}</div>;
  };

  const renderDayView = () => {
    const dateKey = currentDate.toISOString().split('T')[0];
    const shift = shifts[dateKey];

    return (
      <div className="bg-white rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          {currentDate.toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
        </h3>
        
        {shift ? (
          <div className="space-y-4">
            <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getShiftColor(shift.type)}`}>
              {shift.type === 'work' ? 'Рабочий день' : 
               shift.type === 'dayoff' ? 'Выходной' : 'Отпуск'}
            </div>
            
            {shift.type === 'work' && (
              <>
                <div className="flex items-center space-x-2">
                  <Clock className="h-5 w-5 text-gray-400" />
                  <span className="text-gray-900">Начало: {shift.start}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Clock className="h-5 w-5 text-gray-400" />
                  <span className="text-gray-900">Конец: {shift.end}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Clock className="h-5 w-5 text-gray-400" />
                  <span className="text-gray-900">Перерыв: 13:00 - 14:00</span>
                </div>
              </>
            )}
          </div>
        ) : (
          <p className="text-gray-600">Нет запланированных смен</p>
        )}
      </div>
    );
  };

  const navigateDate = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    switch (viewType) {
      case 'month':
        newDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1));
        break;
      case 'week':
      case '4day':
        newDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7));
        break;
      case 'day':
        newDate.setDate(currentDate.getDate() + (direction === 'next' ? 1 : -1));
        break;
    }
    setCurrentDate(newDate);
  };

  return (
    <div className="space-y-4">
      {/* View Type Selector */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Календарь</h2>
          <select
            value={viewType}
            onChange={(e) => setViewType(e.target.value as ViewType)}
            className="px-3 py-1 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="month">Месяц</option>
            <option value="week">Неделя</option>
            <option value="4day">4 дня</option>
            <option value="day">День</option>
          </select>
        </div>

        {/* Navigation */}
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={() => navigateDate('prev')}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <h3 className="text-center font-medium text-gray-900">
            {viewType === 'month' 
              ? currentDate.toLocaleDateString('ru-RU', { month: 'long', year: 'numeric' })
              : currentDate.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' })
            }
          </h3>
          <button
            onClick={() => navigateDate('next')}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>

        {/* Calendar Content */}
        {viewType === 'month' && renderMonthView()}
        {viewType === 'week' && renderWeekView()}
        {viewType === 'day' && renderDayView()}
      </div>

      {/* Selected Date Details */}
      {selectedDate && viewType === 'month' && (
        <div className="bg-white rounded-lg shadow-sm p-4">
          <h3 className="font-semibold text-gray-900 mb-2">
            {selectedDate.toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' })}
          </h3>
          <div className="text-sm text-gray-600">
            {shifts[selectedDate.toISOString().split('T')[0]] ? (
              <div>
                Смена: {shifts[selectedDate.toISOString().split('T')[0]].start || 'Выходной'}
              </div>
            ) : (
              'Нет запланированных смен'
            )}
          </div>
        </div>
      )}

      {/* Legend */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <h3 className="font-semibold text-gray-900 mb-3">Обозначения</h3>
        <div className="space-y-2">
          <div className="flex items-center space-x-3">
            <span className="w-4 h-4 bg-blue-100 rounded"></span>
            <span className="text-sm text-gray-600">Рабочий день</span>
          </div>
          <div className="flex items-center space-x-3">
            <span className="w-4 h-4 bg-gray-100 rounded"></span>
            <span className="text-sm text-gray-600">Выходной</span>
          </div>
          <div className="flex items-center space-x-3">
            <span className="w-4 h-4 bg-green-100 rounded"></span>
            <span className="text-sm text-gray-600">Отпуск</span>
          </div>
          <div className="flex items-center space-x-3">
            <span className="w-4 h-4 bg-red-100 rounded"></span>
            <span className="text-sm text-gray-600">Больничный</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MobileCalendar;