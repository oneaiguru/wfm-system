import React, { useState, useEffect, useRef } from 'react';
import './MobileCalendarView.css';

interface ShiftData {
  id: string;
  start_time: string;
  end_time: string;
  break_time?: number;
  position: string;
  location: string;
  status: 'scheduled' | 'confirmed' | 'requested' | 'cancelled';
  overtime?: boolean;
  notes?: string;
}

interface CalendarDay {
  date: Date;
  shifts: ShiftData[];
  is_weekend: boolean;
  is_holiday: boolean;
  is_current_month: boolean;
}

interface WeekView {
  dates: Date[];
  shifts: Record<string, ShiftData[]>;
}

type ViewMode = 'monthly' | 'weekly' | 'daily';

interface MobileCalendarViewProps {
  employeeId: string;
  initialDate?: Date;
  onShiftSelect?: (shift: ShiftData) => void;
  onDateSelect?: (date: Date) => void;
}

const MobileCalendarView: React.FC<MobileCalendarViewProps> = ({
  employeeId,
  initialDate = new Date(),
  onShiftSelect,
  onDateSelect
}) => {
  const [currentDate, setCurrentDate] = useState(initialDate);
  const [viewMode, setViewMode] = useState<ViewMode>('monthly');
  const [calendarData, setCalendarData] = useState<CalendarDay[]>([]);
  const [weekData, setWeekData] = useState<WeekView | null>(null);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [loading, setLoading] = useState(false);
  const [swipeStart, setSwipeStart] = useState<number | null>(null);
  const calendarRef = useRef<HTMLDivElement>(null);

  const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  const weekdaysFull = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];

  useEffect(() => {
    loadCalendarData();
  }, [currentDate, viewMode, employeeId]);

  const loadCalendarData = async () => {
    setLoading(true);
    try {
      const startDate = getViewStartDate();
      const endDate = getViewEndDate();
      
      const response = await fetch('/api/v1/mobile/calendar/schedule', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        params: new URLSearchParams({
          employee_id: employeeId,
          start_date: startDate.toISOString().split('T')[0],
          end_date: endDate.toISOString().split('T')[0],
          view_mode: viewMode
        })
      });

      if (response.ok) {
        const data = await response.json();
        
        if (viewMode === 'monthly') {
          setCalendarData(processMonthlyData(data.schedule));
        } else if (viewMode === 'weekly') {
          setWeekData(processWeeklyData(data.schedule));
        }
      }
    } catch (error) {
      console.error('Ошибка загрузки календаря:', error);
    } finally {
      setLoading(false);
    }
  };

  const getViewStartDate = () => {
    if (viewMode === 'monthly') {
      const start = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
      start.setDate(start.getDate() - start.getDay() + 1); // Start from Monday
      return start;
    } else if (viewMode === 'weekly') {
      const start = new Date(currentDate);
      start.setDate(start.getDate() - start.getDay() + 1);
      return start;
    } else {
      return new Date(currentDate);
    }
  };

  const getViewEndDate = () => {
    if (viewMode === 'monthly') {
      const end = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
      end.setDate(end.getDate() + (7 - end.getDay()));
      return end;
    } else if (viewMode === 'weekly') {
      const end = new Date(currentDate);
      end.setDate(end.getDate() - end.getDay() + 7);
      return end;
    } else {
      return new Date(currentDate);
    }
  };

  const processMonthlyData = (scheduleData: any[]): CalendarDay[] => {
    const days: CalendarDay[] = [];
    const startDate = getViewStartDate();
    const endDate = getViewEndDate();
    
    let currentDay = new Date(startDate);
    
    while (currentDay <= endDate) {
      const dayShifts = scheduleData.filter(shift => 
        new Date(shift.date).toDateString() === currentDay.toDateString()
      );
      
      days.push({
        date: new Date(currentDay),
        shifts: dayShifts,
        is_weekend: currentDay.getDay() === 0 || currentDay.getDay() === 6,
        is_holiday: false, // Would be determined by business logic
        is_current_month: currentDay.getMonth() === currentDate.getMonth()
      });
      
      currentDay.setDate(currentDay.getDate() + 1);
    }
    
    return days;
  };

  const processWeeklyData = (scheduleData: any[]): WeekView => {
    const startDate = getViewStartDate();
    const dates: Date[] = [];
    const shifts: Record<string, ShiftData[]> = {};
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      dates.push(date);
      
      const dateKey = date.toISOString().split('T')[0];
      shifts[dateKey] = scheduleData.filter(shift => 
        new Date(shift.date).toDateString() === date.toDateString()
      );
    }
    
    return { dates, shifts };
  };

  const navigateCalendar = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    
    if (viewMode === 'monthly') {
      newDate.setMonth(newDate.getMonth() + (direction === 'next' ? 1 : -1));
    } else if (viewMode === 'weekly') {
      newDate.setDate(newDate.getDate() + (direction === 'next' ? 7 : -7));
    } else {
      newDate.setDate(newDate.getDate() + (direction === 'next' ? 1 : -1));
    }
    
    setCurrentDate(newDate);
  };

  const handleSwipeStart = (e: React.TouchEvent) => {
    setSwipeStart(e.touches[0].clientX);
  };

  const handleSwipeEnd = (e: React.TouchEvent) => {
    if (swipeStart === null) return;
    
    const swipeEnd = e.changedTouches[0].clientX;
    const swipeDistance = swipeStart - swipeEnd;
    const minSwipeDistance = 50;
    
    if (Math.abs(swipeDistance) > minSwipeDistance) {
      if (swipeDistance > 0) {
        navigateCalendar('next');
      } else {
        navigateCalendar('prev');
      }
    }
    
    setSwipeStart(null);
  };

  const handleDateClick = (date: Date) => {
    setSelectedDate(date);
    onDateSelect?.(date);
  };

  const handleShiftClick = (shift: ShiftData) => {
    onShiftSelect?.(shift);
  };

  const formatTime = (time: string) => {
    return new Date(`2000-01-01T${time}`).toLocaleTimeString('ru-RU', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getShiftStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return '#48bb78';
      case 'scheduled': return '#4299e1';
      case 'requested': return '#ed8936';
      case 'cancelled': return '#f56565';
      default: return '#a0aec0';
    }
  };

  const renderMonthlyView = () => (
    <div className="mobile-calendar__monthly">
      <div className="mobile-calendar__weekdays">
        {weekdays.map(day => (
          <div key={day} className="mobile-calendar__weekday">{day}</div>
        ))}
      </div>
      
      <div className="mobile-calendar__days">
        {calendarData.map((day, index) => (
          <div
            key={index}
            className={`mobile-calendar__day ${
              !day.is_current_month ? 'mobile-calendar__day--other-month' : ''
            } ${
              day.is_weekend ? 'mobile-calendar__day--weekend' : ''
            } ${
              selectedDate && day.date.toDateString() === selectedDate.toDateString() 
                ? 'mobile-calendar__day--selected' : ''
            }`}
            onClick={() => handleDateClick(day.date)}
          >
            <div className="mobile-calendar__day-number">
              {day.date.getDate()}
            </div>
            
            {day.shifts.length > 0 && (
              <div className="mobile-calendar__day-shifts">
                {day.shifts.slice(0, 2).map((shift, idx) => (
                  <div
                    key={idx}
                    className="mobile-calendar__shift-indicator"
                    style={{ backgroundColor: getShiftStatusColor(shift.status) }}
                    onClick={(e) => {
                      e.stopPropagation();
                      handleShiftClick(shift);
                    }}
                  >
                    {formatTime(shift.start_time)}
                  </div>
                ))}
                {day.shifts.length > 2 && (
                  <div className="mobile-calendar__shift-more">
                    +{day.shifts.length - 2}
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );

  const renderWeeklyView = () => (
    <div className="mobile-calendar__weekly">
      {weekData?.dates.map((date, index) => {
        const dateKey = date.toISOString().split('T')[0];
        const dayShifts = weekData.shifts[dateKey] || [];
        
        return (
          <div key={index} className="mobile-calendar__week-day">
            <div className="mobile-calendar__week-header">
              <div className="mobile-calendar__week-weekday">
                {weekdays[date.getDay() === 0 ? 6 : date.getDay() - 1]}
              </div>
              <div className="mobile-calendar__week-date">
                {date.getDate()}
              </div>
            </div>
            
            <div className="mobile-calendar__week-shifts">
              {dayShifts.map((shift, idx) => (
                <div
                  key={idx}
                  className="mobile-calendar__week-shift"
                  style={{ borderLeftColor: getShiftStatusColor(shift.status) }}
                  onClick={() => handleShiftClick(shift)}
                >
                  <div className="mobile-calendar__shift-time">
                    {formatTime(shift.start_time)} - {formatTime(shift.end_time)}
                  </div>
                  <div className="mobile-calendar__shift-position">
                    {shift.position}
                  </div>
                  {shift.overtime && (
                    <div className="mobile-calendar__shift-overtime">
                      Сверхурочно
                    </div>
                  )}
                </div>
              ))}
              
              {dayShifts.length === 0 && (
                <div className="mobile-calendar__no-shifts">
                  Выходной
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );

  const renderDailyView = () => {
    const dayShifts = calendarData.find(day => 
      day.date.toDateString() === currentDate.toDateString()
    )?.shifts || [];
    
    return (
      <div className="mobile-calendar__daily">
        <div className="mobile-calendar__daily-header">
          <h3>{weekdaysFull[currentDate.getDay()]}</h3>
          <p>{currentDate.toLocaleDateString('ru-RU')}</p>
        </div>
        
        <div className="mobile-calendar__daily-shifts">
          {dayShifts.length > 0 ? (
            dayShifts.map((shift, index) => (
              <div
                key={index}
                className="mobile-calendar__daily-shift"
                onClick={() => handleShiftClick(shift)}
              >
                <div className="mobile-calendar__shift-header">
                  <div className="mobile-calendar__shift-time">
                    {formatTime(shift.start_time)} - {formatTime(shift.end_time)}
                  </div>
                  <div 
                    className="mobile-calendar__shift-status"
                    style={{ backgroundColor: getShiftStatusColor(shift.status) }}
                  >
                    {shift.status}
                  </div>
                </div>
                
                <div className="mobile-calendar__shift-details">
                  <div>📍 {shift.location}</div>
                  <div>👤 {shift.position}</div>
                  {shift.break_time && (
                    <div>☕ Перерыв: {shift.break_time} мин</div>
                  )}
                  {shift.overtime && (
                    <div>⏰ Сверхурочно</div>
                  )}
                </div>
                
                {shift.notes && (
                  <div className="mobile-calendar__shift-notes">
                    💬 {shift.notes}
                  </div>
                )}
              </div>
            ))
          ) : (
            <div className="mobile-calendar__no-shifts-daily">
              <div className="mobile-calendar__no-shifts-icon">🏖️</div>
              <h4>Выходной день</h4>
              <p>У вас нет запланированных смен на сегодня</p>
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="mobile-calendar" ref={calendarRef}>
      <div className="mobile-calendar__header">
        <button
          className="mobile-calendar__nav-button"
          onClick={() => navigateCalendar('prev')}
          disabled={loading}
        >
          ◀️
        </button>
        
        <div className="mobile-calendar__title">
          <h2>{months[currentDate.getMonth()]} {currentDate.getFullYear()}</h2>
          {viewMode === 'daily' && (
            <p>{currentDate.toLocaleDateString('ru-RU')}</p>
          )}
        </div>
        
        <button
          className="mobile-calendar__nav-button"
          onClick={() => navigateCalendar('next')}
          disabled={loading}
        >
          ▶️
        </button>
      </div>

      <div className="mobile-calendar__view-switcher">
        <button
          className={`mobile-calendar__view-button ${viewMode === 'monthly' ? 'active' : ''}`}
          onClick={() => setViewMode('monthly')}
        >
          Месяц
        </button>
        <button
          className={`mobile-calendar__view-button ${viewMode === 'weekly' ? 'active' : ''}`}
          onClick={() => setViewMode('weekly')}
        >
          Неделя
        </button>
        <button
          className={`mobile-calendar__view-button ${viewMode === 'daily' ? 'active' : ''}`}
          onClick={() => setViewMode('daily')}
        >
          День
        </button>
      </div>

      <div
        className="mobile-calendar__content"
        onTouchStart={handleSwipeStart}
        onTouchEnd={handleSwipeEnd}
      >
        {loading ? (
          <div className="mobile-calendar__loading">
            <div className="mobile-calendar__spinner"></div>
            <p>Загрузка расписания...</p>
          </div>
        ) : (
          <>
            {viewMode === 'monthly' && renderMonthlyView()}
            {viewMode === 'weekly' && renderWeeklyView()}
            {viewMode === 'daily' && renderDailyView()}
          </>
        )}
      </div>
    </div>
  );
};

export default MobileCalendarView;