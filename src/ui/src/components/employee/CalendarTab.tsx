import React, { useState, useEffect } from 'react';
import { Calendar, Clock, MoreVertical, Plus, AlertCircle } from 'lucide-react';
import RequestCreationModal from './RequestCreationModal';

interface CalendarTabProps {
  employeeId: string;
}

interface ShiftData {
  id: string;
  date: Date;
  startTime: string;
  endTime: string;
  type: 'regular' | 'overtime' | 'training' | 'holiday';
  status: 'scheduled' | 'completed' | 'cancelled' | 'pending';
  location: string;
  notes?: string;
}

interface RequestData {
  id: string;
  type: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
  startDate: Date;
  endDate?: Date;
  status: 'created' | 'pending' | 'approved' | 'rejected';
  reason: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations per BDD spec
const translations = {
  title: 'Календарь',
  createButton: 'Создать',
  today: 'Сегодня',
  weekView: 'Неделя',
  monthView: 'Месяц',
  shift: 'Смена',
  request: 'Заявка',
  shiftActions: {
    createRequest: 'Создать заявку',
    exchangeShift: 'Обменять смену',
    viewDetails: 'Подробности'
  },
  requestTypes: {
    time_off: 'Отгул',
    sick_leave: 'Больничный',
    vacation: 'Отпуск',
    shift_exchange: 'Обмен смен'
  },
  statuses: {
    scheduled: 'Запланировано',
    completed: 'Выполнено',
    cancelled: 'Отменено',
    pending: 'Ожидает',
    created: 'Создана',
    approved: 'Одобрена',
    rejected: 'Отклонена'
  }
};

const CalendarTab: React.FC<CalendarTabProps> = ({ employeeId }) => {
  const [shifts, setShifts] = useState<ShiftData[]>([]);
  const [requests, setRequests] = useState<RequestData[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<'week' | 'month'>('week');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedShift, setSelectedShift] = useState<ShiftData | null>(null);
  const [showShiftMenu, setShowShiftMenu] = useState<string | null>(null);

  useEffect(() => {
    loadCalendarData();
  }, [employeeId, selectedDate]);

  const loadCalendarData = async () => {
    setLoading(true);
    try {
      // Load shifts
      const shiftsResponse = await fetch(
        `${API_BASE_URL}/schedules/employee/${employeeId}?month=${selectedDate.getMonth() + 1}&year=${selectedDate.getFullYear()}`
      );
      
      if (shiftsResponse.ok) {
        const shiftsData = await shiftsResponse.json();
        const mappedShifts = (shiftsData.shifts || []).map((shift: any) => ({
          id: shift.id,
          date: new Date(shift.date),
          startTime: shift.start_time,
          endTime: shift.end_time,
          type: shift.type || 'regular',
          status: shift.status || 'scheduled',
          location: shift.location || 'Офис',
          notes: shift.notes
        }));
        setShifts(mappedShifts);
      }

      // Load requests
      const requestsResponse = await fetch(
        `${API_BASE_URL}/requests/my-requests?employee_id=${employeeId}`
      );
      
      if (requestsResponse.ok) {
        const requestsData = await requestsResponse.json();
        const mappedRequests = (requestsData.requests || []).map((request: any) => ({
          id: request.id,
          type: request.type,
          startDate: new Date(request.start_date),
          endDate: request.end_date ? new Date(request.end_date) : undefined,
          status: request.status,
          reason: request.reason
        }));
        setRequests(mappedRequests);
      }

    } catch (error) {
      console.error('Error loading calendar data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getWeekDays = () => {
    const start = new Date(selectedDate);
    const diff = start.getDate() - start.getDay();
    const sunday = new Date(start.setDate(diff));
    
    const weekDays = [];
    for (let i = 0; i < 7; i++) {
      const day = new Date(sunday);
      day.setDate(sunday.getDate() + i);
      weekDays.push(day);
    }
    return weekDays;
  };

  const getShiftsForDate = (date: Date) => {
    return shifts.filter(shift => 
      shift.date.toDateString() === date.toDateString()
    );
  };

  const getRequestsForDate = (date: Date) => {
    return requests.filter(request => {
      const requestStart = new Date(request.startDate);
      const requestEnd = request.endDate ? new Date(request.endDate) : requestStart;
      return date >= requestStart && date <= requestEnd;
    });
  };

  const handleCreateRequest = async (requestData: any) => {
    try {
      const response = await fetch(`${API_BASE_URL}/requests`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          employee_id: employeeId,
          type: requestData.type,
          start_date: requestData.startDate,
          end_date: requestData.endDate,
          reason: requestData.reason,
          description: requestData.description,
          exchange_employee_id: requestData.exchangeEmployeeId,
          exchange_date: requestData.exchangeDate,
          exchange_time: requestData.exchangeTime
        })
      });

      if (response.ok) {
        // Reload calendar data to show new request
        await loadCalendarData();
        setShowCreateModal(false);
      } else {
        throw new Error('Failed to create request');
      }
    } catch (error) {
      console.error('Error creating request:', error);
    }
  };

  const handleShiftMenuClick = (shiftId: string, action: string) => {
    const shift = shifts.find(s => s.id === shiftId);
    if (!shift) return;

    switch (action) {
      case 'createRequest':
        setSelectedShift(shift);
        setShowCreateModal(true);
        break;
      case 'exchangeShift':
        setSelectedShift(shift);
        setShowCreateModal(true);
        break;
      case 'viewDetails':
        // TODO: Implement shift details view
        break;
    }
    setShowShiftMenu(null);
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'short'
    });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800';
      case 'completed': return 'bg-green-100 text-green-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getRequestTypeColor = (type: string) => {
    switch (type) {
      case 'time_off': return 'bg-orange-100 text-orange-800';
      case 'sick_leave': return 'bg-red-100 text-red-800';
      case 'vacation': return 'bg-purple-100 text-purple-800';
      case 'shift_exchange': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const navigateWeek = (direction: 'prev' | 'next') => {
    const newDate = new Date(selectedDate);
    newDate.setDate(selectedDate.getDate() + (direction === 'next' ? 7 : -7));
    setSelectedDate(newDate);
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-7 gap-4">
            {[...Array(7)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-300 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="bg-white rounded-lg shadow-sm">
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex justify-between items-center">
            <div className="flex items-center gap-3">
              <Calendar className="h-6 w-6 text-blue-600" />
              <h2 className="text-2xl font-semibold text-gray-900">{translations.title}</h2>
            </div>
            
            <div className="flex items-center gap-4">
              {/* Create Button - per BDD spec */}
              <button
                onClick={() => setShowCreateModal(true)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
                data-testid="create-button"
              >
                <Plus className="h-4 w-4" />
                {translations.createButton}
              </button>
              
              {/* View Mode Toggle */}
              <div className="flex bg-gray-100 rounded-lg p-1">
                <button
                  onClick={() => setViewMode('week')}
                  className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                    viewMode === 'week' 
                      ? 'bg-white text-blue-600 shadow-sm' 
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {translations.weekView}
                </button>
                <button
                  onClick={() => setViewMode('month')}
                  className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                    viewMode === 'month' 
                      ? 'bg-white text-blue-600 shadow-sm' 
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {translations.monthView}
                </button>
              </div>
            </div>
          </div>

          {/* Week Navigation */}
          <div className="flex items-center justify-between mt-6">
            <button
              onClick={() => navigateWeek('prev')}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              ← Предыдущая неделя
            </button>
            
            <h3 className="text-lg font-medium text-gray-900">
              {formatDate(getWeekDays()[0])} - {formatDate(getWeekDays()[6])}
            </h3>
            
            <button
              onClick={() => navigateWeek('next')}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              Следующая неделя →
            </button>
          </div>
        </div>

        {/* Calendar Grid */}
        <div className="p-6">
          <div className="grid grid-cols-7 gap-4">
            {getWeekDays().map((day, index) => {
              const dayShifts = getShiftsForDate(day);
              const dayRequests = getRequestsForDate(day);
              const isToday = day.toDateString() === new Date().toDateString();
              
              return (
                <div
                  key={index}
                  className={`border rounded-lg p-4 min-h-[200px] ${
                    isToday ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white'
                  }`}
                >
                  {/* Day Header */}
                  <div className="text-center mb-3">
                    <div className="text-sm font-medium text-gray-900">
                      {day.toLocaleDateString('ru-RU', { weekday: 'short' })}
                    </div>
                    <div className={`text-lg font-bold ${
                      isToday ? 'text-blue-600' : 'text-gray-900'
                    }`}>
                      {day.getDate()}
                    </div>
                  </div>
                  
                  {/* Shifts */}
                  <div className="space-y-2">
                    {dayShifts.map((shift) => (
                      <div
                        key={shift.id}
                        className="relative bg-gray-50 rounded-md p-3 text-sm border-l-4 border-l-blue-400"
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Clock className="h-4 w-4 text-gray-500" />
                            <span className="font-medium text-gray-900">
                              {shift.startTime} - {shift.endTime}
                            </span>
                          </div>
                          
                          {/* Three dots menu - per BDD spec */}
                          <div className="relative">
                            <button
                              onClick={() => setShowShiftMenu(showShiftMenu === shift.id ? null : shift.id)}
                              className="p-1 hover:bg-gray-200 rounded"
                              data-testid="three-dots-menu"
                            >
                              <MoreVertical className="h-4 w-4 text-gray-500" />
                            </button>
                            
                            {showShiftMenu === shift.id && (
                              <div className="absolute right-0 mt-1 w-48 bg-white rounded-md shadow-lg border z-10">
                                <button
                                  onClick={() => handleShiftMenuClick(shift.id, 'createRequest')}
                                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                >
                                  {translations.shiftActions.createRequest}
                                </button>
                                <button
                                  onClick={() => handleShiftMenuClick(shift.id, 'exchangeShift')}
                                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                >
                                  {translations.shiftActions.exchangeShift}
                                </button>
                                <button
                                  onClick={() => handleShiftMenuClick(shift.id, 'viewDetails')}
                                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                >
                                  {translations.shiftActions.viewDetails}
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                        
                        <div className="text-gray-600 mt-1">
                          {shift.location}
                        </div>
                        
                        <div className="flex items-center justify-between mt-2">
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(shift.status)}`}>
                            {translations.statuses[shift.status as keyof typeof translations.statuses]}
                          </span>
                        </div>
                      </div>
                    ))}
                    
                    {/* Requests */}
                    {dayRequests.map((request) => (
                      <div
                        key={request.id}
                        className="bg-orange-50 rounded-md p-3 text-sm border-l-4 border-l-orange-400"
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <AlertCircle className="h-4 w-4 text-orange-500" />
                          <span className="font-medium text-orange-900">
                            {translations.requestTypes[request.type as keyof typeof translations.requestTypes]}
                          </span>
                        </div>
                        
                        <div className="text-orange-700 text-xs mb-2">
                          {request.reason}
                        </div>
                        
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getRequestTypeColor(request.type)}`}>
                          {translations.statuses[request.status as keyof typeof translations.statuses]}
                        </span>
                      </div>
                    ))}
                    
                    {/* Empty state */}
                    {dayShifts.length === 0 && dayRequests.length === 0 && (
                      <div className="text-center text-gray-400 text-sm py-4">
                        Нет событий
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Request Creation Modal */}
      {showCreateModal && (
        <RequestCreationModal
          isOpen={showCreateModal}
          onClose={() => {
            setShowCreateModal(false);
            setSelectedShift(null);
          }}
          onSubmit={handleCreateRequest}
          requestType={selectedShift ? 'shift_exchange' : 'time_off'}
        />
      )}
    </div>
  );
};

export default CalendarTab;