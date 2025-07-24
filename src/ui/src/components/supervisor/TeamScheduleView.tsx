import React, { useState, useEffect } from 'react';
import { Calendar, Users, Clock, Filter, Download, Settings, AlertCircle, CheckCircle } from 'lucide-react';

interface TeamScheduleViewProps {
  supervisorId: string;
}

interface TeamMember {
  id: string;
  name: string;
  position: string;
  department: string;
  status: 'active' | 'on_leave' | 'sick' | 'vacation';
}

interface ShiftAssignment {
  id: string;
  employeeId: string;
  employeeName: string;
  date: Date;
  startTime: string;
  endTime: string;
  shiftType: 'regular' | 'overtime' | 'training' | 'meeting';
  location: string;
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  skills: string[];
  notes?: string;
}

interface ScheduleMetrics {
  totalShifts: number;
  confirmedShifts: number;
  vacantShifts: number;
  overtimeShifts: number;
  coveragePercentage: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations per BDD spec
const translations = {
  title: 'Расписание команды',
  filters: {
    all: 'Все',
    today: 'Сегодня',
    thisWeek: 'Эта неделя',
    nextWeek: 'Следующая неделя',
    thisMonth: 'Этот месяц'
  },
  views: {
    grid: 'Сетка',
    list: 'Список',
    calendar: 'Календарь'
  },
  metrics: {
    totalShifts: 'Всего смен',
    confirmedShifts: 'Подтвержденные',
    vacantShifts: 'Свободные',
    overtimeShifts: 'Сверхурочные',
    coveragePercentage: 'Покрытие'
  },
  shiftTypes: {
    regular: 'Обычная',
    overtime: 'Сверхурочная',
    training: 'Обучение',
    meeting: 'Встреча'
  },
  shiftStatus: {
    scheduled: 'Запланирована',
    confirmed: 'Подтверждена',
    completed: 'Завершена',
    cancelled: 'Отменена'
  },
  employeeStatus: {
    active: 'Активен',
    on_leave: 'В отпуске',
    sick: 'Болен',
    vacation: 'В отгуле'
  },
  actions: {
    assignShift: 'Назначить смену',
    editShift: 'Редактировать',
    cancelShift: 'Отменить',
    confirmShift: 'Подтвердить',
    viewDetails: 'Подробности',
    exportSchedule: 'Экспорт',
    publishSchedule: 'Опубликовать',
    bulkAssign: 'Массовое назначение'
  },
  timeSlots: {
    morning: 'Утро (08:00-16:00)',
    afternoon: 'День (16:00-24:00)',
    night: 'Ночь (00:00-08:00)'
  }
};

const TeamScheduleView: React.FC<TeamScheduleViewProps> = ({ supervisorId }) => {
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([]);
  const [shifts, setShifts] = useState<ShiftAssignment[]>([]);
  const [metrics, setMetrics] = useState<ScheduleMetrics>({
    totalShifts: 0,
    confirmedShifts: 0,
    vacantShifts: 0,
    overtimeShifts: 0,
    coveragePercentage: 0
  });
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<'grid' | 'list' | 'calendar'>('grid');
  const [timeFilter, setTimeFilter] = useState<'all' | 'today' | 'thisWeek' | 'nextWeek' | 'thisMonth'>('thisWeek');
  const [selectedShift, setSelectedShift] = useState<ShiftAssignment | null>(null);
  const [showAssignModal, setShowAssignModal] = useState(false);

  useEffect(() => {
    loadTeamSchedule();
  }, [supervisorId, selectedDate, timeFilter]);

  const loadTeamSchedule = async () => {
    setLoading(true);
    try {
      // Load team members
      const teamResponse = await fetch(
        `${API_BASE_URL}/teams/${supervisorId}/members`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (teamResponse.ok) {
        const teamData = await teamResponse.json();
        const mappedTeam = (teamData.members || []).map((member: any) => ({
          id: member.id,
          name: member.name,
          position: member.position,
          department: member.department,
          status: member.status || 'active'
        }));
        setTeamMembers(mappedTeam);
      }

      // Load schedule data
      const scheduleResponse = await fetch(
        `${API_BASE_URL}/teams/${supervisorId}/schedule?filter=${timeFilter}&date=${selectedDate.toISOString().split('T')[0]}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (scheduleResponse.ok) {
        const scheduleData = await scheduleResponse.json();
        const mappedShifts = (scheduleData.shifts || []).map((shift: any) => ({
          id: shift.id,
          employeeId: shift.employee_id,
          employeeName: shift.employee_name,
          date: new Date(shift.date),
          startTime: shift.start_time,
          endTime: shift.end_time,
          shiftType: shift.shift_type || 'regular',
          location: shift.location,
          status: shift.status || 'scheduled',
          skills: shift.skills || [],
          notes: shift.notes
        }));
        setShifts(mappedShifts);

        // Calculate metrics
        const totalShifts = mappedShifts.length;
        const confirmedShifts = mappedShifts.filter((s: ShiftAssignment) => s.status === 'confirmed').length;
        const vacantShifts = mappedShifts.filter((s: ShiftAssignment) => !s.employeeId).length;
        const overtimeShifts = mappedShifts.filter((s: ShiftAssignment) => s.shiftType === 'overtime').length;
        const coveragePercentage = totalShifts > 0 ? Math.round((confirmedShifts / totalShifts) * 100) : 0;

        setMetrics({
          totalShifts,
          confirmedShifts,
          vacantShifts,
          overtimeShifts,
          coveragePercentage
        });
      }

    } catch (error) {
      console.error('Error loading team schedule:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAssignShift = async (shiftId: string, employeeId: string) => {
    try {
      await fetch(`${API_BASE_URL}/schedule/assign`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          shift_id: shiftId,
          employee_id: employeeId,
          supervisor_id: supervisorId
        })
      });

      await loadTeamSchedule();
    } catch (error) {
      console.error('Error assigning shift:', error);
    }
  };

  const handlePublishSchedule = async () => {
    try {
      await fetch(`${API_BASE_URL}/schedule/publish`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          supervisor_id: supervisorId,
          date_range: getDateRangeForFilter()
        })
      });

      await loadTeamSchedule();
    } catch (error) {
      console.error('Error publishing schedule:', error);
    }
  };

  const getDateRangeForFilter = () => {
    const today = new Date();
    switch (timeFilter) {
      case 'today':
        return {
          start: today.toISOString().split('T')[0],
          end: today.toISOString().split('T')[0]
        };
      case 'thisWeek':
        const weekStart = new Date(today.setDate(today.getDate() - today.getDay()));
        const weekEnd = new Date(today.setDate(today.getDate() - today.getDay() + 6));
        return {
          start: weekStart.toISOString().split('T')[0],
          end: weekEnd.toISOString().split('T')[0]
        };
      case 'nextWeek':
        const nextWeekStart = new Date(today.setDate(today.getDate() - today.getDay() + 7));
        const nextWeekEnd = new Date(today.setDate(today.getDate() - today.getDay() + 13));
        return {
          start: nextWeekStart.toISOString().split('T')[0],
          end: nextWeekEnd.toISOString().split('T')[0]
        };
      case 'thisMonth':
        const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
        const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        return {
          start: monthStart.toISOString().split('T')[0],
          end: monthEnd.toISOString().split('T')[0]
        };
      default:
        return {
          start: today.toISOString().split('T')[0],
          end: new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0]
        };
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

  const getEmployeeStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'on_leave': return 'bg-blue-100 text-blue-800';
      case 'sick': return 'bg-red-100 text-red-800';
      case 'vacation': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getShiftStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-yellow-100 text-yellow-800';
      case 'confirmed': return 'bg-green-100 text-green-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'short'
    });
  };

  const renderMetricsCard = (title: string, value: number, suffix: string = '', icon: React.ReactNode) => (
    <div className="bg-white rounded-lg shadow-sm p-4 border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}{suffix}</p>
        </div>
        <div className="p-2 bg-blue-50 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );

  const renderGridView = () => (
    <div className="space-y-6">
      {/* Week Navigation */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => setSelectedDate(new Date(selectedDate.getTime() - 7 * 24 * 60 * 60 * 1000))}
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          ← Предыдущая неделя
        </button>
        <h3 className="text-lg font-medium text-gray-900">
          {formatDate(getWeekDays()[0])} - {formatDate(getWeekDays()[6])}
        </h3>
        <button
          onClick={() => setSelectedDate(new Date(selectedDate.getTime() + 7 * 24 * 60 * 60 * 1000))}
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          Следующая неделя →
        </button>
      </div>

      {/* Schedule Grid */}
      <div className="grid grid-cols-8 gap-4">
        {/* Header */}
        <div className="font-medium text-gray-900 p-3">Сотрудник</div>
        {getWeekDays().map((day, index) => (
          <div key={index} className="text-center p-3">
            <div className="font-medium text-gray-900">
              {day.toLocaleDateString('ru-RU', { weekday: 'short' })}
            </div>
            <div className="text-sm text-gray-600">{day.getDate()}</div>
          </div>
        ))}

        {/* Employee Rows */}
        {teamMembers.map((member) => (
          <React.Fragment key={member.id}>
            <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg">
              <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                <span className="text-blue-600 font-medium text-sm">
                  {member.name.split(' ').map(n => n[0]).join('')}
                </span>
              </div>
              <div>
                <div className="font-medium text-gray-900">{member.name}</div>
                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getEmployeeStatusColor(member.status)}`}>
                  {translations.employeeStatus[member.status as keyof typeof translations.employeeStatus]}
                </span>
              </div>
            </div>
            
            {getWeekDays().map((day, dayIndex) => {
              const dayShifts = getShiftsForDate(day).filter(s => s.employeeId === member.id);
              return (
                <div key={dayIndex} className="p-2 border border-gray-200 rounded-lg min-h-[80px]">
                  {dayShifts.map((shift) => (
                    <div
                      key={shift.id}
                      className="bg-blue-50 rounded p-2 text-sm cursor-pointer hover:bg-blue-100 transition-colors"
                      onClick={() => setSelectedShift(shift)}
                    >
                      <div className="font-medium text-blue-900">
                        {shift.startTime} - {shift.endTime}
                      </div>
                      <div className="text-blue-700">{shift.location}</div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getShiftStatusColor(shift.status)}`}>
                        {translations.shiftStatus[shift.status as keyof typeof translations.shiftStatus]}
                      </span>
                    </div>
                  ))}
                </div>
              );
            })}
          </React.Fragment>
        ))}
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-24 bg-gray-300 rounded"></div>
            ))}
          </div>
          <div className="h-64 bg-gray-300 rounded"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6" data-testid="team-schedule-view">
      <div className="bg-white rounded-lg shadow-sm">
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Calendar className="h-6 w-6 text-blue-600" />
              <h2 className="text-2xl font-semibold text-gray-900">{translations.title}</h2>
            </div>
            
            <div className="flex items-center gap-4">
              {/* Time Filter */}
              <select
                value={timeFilter}
                onChange={(e) => setTimeFilter(e.target.value as any)}
                className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                {Object.entries(translations.filters).map(([key, label]) => (
                  <option key={key} value={key}>{label}</option>
                ))}
              </select>

              {/* View Mode Toggle */}
              <div className="flex bg-gray-100 rounded-lg p-1">
                {Object.entries(translations.views).map(([key, label]) => (
                  <button
                    key={key}
                    onClick={() => setViewMode(key as any)}
                    className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                      viewMode === key 
                        ? 'bg-white text-blue-600 shadow-sm' 
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>

              {/* Actions */}
              <div className="flex items-center gap-2">
                <button
                  onClick={handlePublishSchedule}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  data-testid="publish-schedule-button"
                >
                  {translations.actions.publishSchedule}
                </button>
                <button
                  onClick={() => setShowAssignModal(true)}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  {translations.actions.bulkAssign}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Metrics */}
        <div className="p-6 border-b border-gray-200">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            {renderMetricsCard(
              translations.metrics.totalShifts,
              metrics.totalShifts,
              '',
              <Clock className="h-5 w-5 text-blue-600" />
            )}
            {renderMetricsCard(
              translations.metrics.confirmedShifts,
              metrics.confirmedShifts,
              '',
              <CheckCircle className="h-5 w-5 text-green-600" />
            )}
            {renderMetricsCard(
              translations.metrics.vacantShifts,
              metrics.vacantShifts,
              '',
              <AlertCircle className="h-5 w-5 text-yellow-600" />
            )}
            {renderMetricsCard(
              translations.metrics.overtimeShifts,
              metrics.overtimeShifts,
              '',
              <Clock className="h-5 w-5 text-orange-600" />
            )}
            {renderMetricsCard(
              translations.metrics.coveragePercentage,
              metrics.coveragePercentage,
              '%',
              <Users className="h-5 w-5 text-purple-600" />
            )}
          </div>
        </div>

        {/* Schedule Content */}
        <div className="p-6">
          {viewMode === 'grid' && renderGridView()}
          {viewMode === 'list' && (
            <div className="text-center py-12">
              <p className="text-gray-500">Список смен - в разработке</p>
            </div>
          )}
          {viewMode === 'calendar' && (
            <div className="text-center py-12">
              <p className="text-gray-500">Календарь - в разработке</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default TeamScheduleView;