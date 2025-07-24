import React, { useState, useEffect, useCallback } from 'react';
import { 
  Calendar, Users, Clock, AlertTriangle, CheckCircle, 
  Edit3, Save, X, MoreVertical, Filter, Download,
  Plus, Copy, RotateCcw, Zap, Grid, List
} from 'lucide-react';

interface TeamMember {
  id: number;
  name: string;
  agent_code: string;
  role: 'member' | 'lead' | 'senior';
  skills: string[];
  availability_score: number;
}

interface ShiftAssignment {
  id: string;
  employee_id: number;
  employee_name: string;
  date: string;
  start_time: string;
  end_time: string;
  shift_type: 'regular' | 'overtime' | 'split' | 'on_call';
  status: 'scheduled' | 'confirmed' | 'pending' | 'conflict';
  coverage_weight: number;
  skills_required: string[];
}

interface CoverageGap {
  date: string;
  time_slot: string;
  required_staff: number;
  current_staff: number;
  gap_severity: 'low' | 'medium' | 'high' | 'critical';
  suggested_actions: string[];
}

interface ScheduleConflict {
  id: string;
  type: 'overlap' | 'skill_gap' | 'overtime_limit' | 'availability';
  description: string;
  affected_shifts: string[];
  resolution_options: string[];
  priority: 'low' | 'medium' | 'high';
}

interface TeamScheduleData {
  team: {
    id: number;
    name: string;
    manager_id: number;
    total_members: number;
  };
  schedule_period: {
    start_date: string;
    end_date: string;
    week_number: number;
  };
  team_members: TeamMember[];
  shift_assignments: ShiftAssignment[];
  coverage_analysis: {
    overall_coverage: number;
    gaps: CoverageGap[];
    efficiency_score: number;
  };
  conflicts: ScheduleConflict[];
  templates: {
    id: string;
    name: string;
    description: string;
  }[];
}

const russianTranslations = {
  title: 'Управление Расписанием Команды',
  teamSchedule: 'Расписание Команды',
  weekView: 'Неделя',
  monthView: 'Месяц',
  coverage: 'Покрытие',
  conflicts: 'Конфликты',
  members: 'Сотрудники',
  shiftTypes: {
    regular: 'Обычная',
    overtime: 'Сверхурочная',
    split: 'Разделенная',
    on_call: 'Дежурство'
  },
  status: {
    scheduled: 'Запланировано',
    confirmed: 'Подтверждено',
    pending: 'Ожидание',
    conflict: 'Конфликт'
  },
  actions: {
    edit: 'Редактировать',
    save: 'Сохранить',
    cancel: 'Отмена',
    bulkEdit: 'Массовое редактирование',
    applyTemplate: 'Применить шаблон',
    resolveConflicts: 'Решить конфликты',
    export: 'Экспорт',
    refresh: 'Обновить'
  },
  coverageGaps: {
    title: 'Пробелы в покрытии',
    low: 'Низкий',
    medium: 'Средний',  
    high: 'Высокий',
    critical: 'Критический'
  },
  conflictTypes: {
    overlap: 'Пересечение смен',
    skill_gap: 'Недостаток навыков',
    overtime_limit: 'Превышение сверхурочных',
    availability: 'Недоступность сотрудника'
  }
};

const API_BASE_URL = 'http://localhost:8001/api/v1';

export const TeamScheduleGrid: React.FC = () => {
  const [scheduleData, setScheduleData] = useState<TeamScheduleData | null>(null);
  const [selectedWeek, setSelectedWeek] = useState(new Date());
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [editingShift, setEditingShift] = useState<string | null>(null);
  const [selectedShifts, setSelectedShifts] = useState<string[]>([]);
  const [showConflicts, setShowConflicts] = useState(false);
  const [bulkEditMode, setBulkEditMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [filterSkills, setFilterSkills] = useState<string[]>([]);

  useEffect(() => {
    loadTeamSchedule();
  }, [selectedWeek]);

  const loadTeamSchedule = async () => {
    setLoading(true);
    setError('');

    try {
      // Try SPEC-05 formal team schedule endpoint (I-stage complete)
      const authToken = localStorage.getItem('authToken');
      const teamId = 1; // Default team for demo
      const weekStart = selectedWeek.toISOString().split('T')[0];
      
      const response = await fetch(`${API_BASE_URL}/teams/${teamId}/schedule?week_start=${weekStart}`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const apiData = await response.json();
        console.log('✅ Raw API data received:', apiData);
        
        // Convert I's API format to component format
        const adaptedData: TeamScheduleData = {
          team: {
            id: apiData.team_id || 1,
            name: apiData.team_name || 'Customer Service Team',
            manager_id: 1,
            total_members: apiData.team_members?.length || 0
          },
          schedule_period: {
            start_date: apiData.week_start || '2025-07-28',
            end_date: apiData.week_end || '2025-08-03',
            week_number: parseInt(apiData.week?.split('-W')[1]) || 30
          },
          team_members: apiData.team_members?.map((member: any) => ({
            id: member.id,
            name: member.name,
            agent_code: member.position || `EMP-${member.id}`,
            role: member.position?.includes('Lead') ? 'lead' : 'member',
            skills: ['customer_service'],
            availability_score: 90
          })) || [],
          shift_assignments: apiData.schedule_grid?.flatMap((day: any) => 
            day.shifts?.map((shift: any) => ({
              id: `shift-${shift.employee_id}-${day.date}`,
              employee_id: shift.employee_id,
              employee_name: shift.employee_name,
              date: day.date,
              start_time: shift.start_time,
              end_time: shift.end_time,
              shift_type: shift.shift_type || 'regular',
              status: shift.status || 'confirmed',
              coverage_weight: 1.0,
              skills_required: ['customer_service']
            })) || []
          ) || [],
          coverage_analysis: {
            overall_coverage: apiData.team_metrics?.coverage_percentage || 95,
            gaps: [], // API doesn't provide gaps in this format
            efficiency_score: apiData.team_metrics?.efficiency_score || 88.5
          },
          conflicts: [], // API doesn't provide conflicts in this format
          templates: []
        };
        
        setScheduleData(adaptedData);
        console.log('✅ Adapted team schedule data:', adaptedData);
      } else {
        // Use comprehensive demo data for SPEC-05 team schedule
        console.log('⚠️ SPEC-05 team schedule APIs not available, using demo data');
        setScheduleData(generateTeamScheduleDemo());
        setError('Демо данные - SPEC-05 team schedule APIs в разработке');
      }
    } catch (err) {
      console.log('⚠️ Team schedule API error, using demo data');
      setScheduleData(generateTeamScheduleDemo());
      setError('Сетевая ошибка - использование демо данных');
    } finally {
      setLoading(false);
    }
  };

  const generateTeamScheduleDemo = (): TeamScheduleData => {
    const teamMembers: TeamMember[] = [
      { id: 1, name: 'Иван Петров', agent_code: 'EMP-001', role: 'lead', skills: ['customer_service', 'escalation'], availability_score: 95 },
      { id: 2, name: 'Мария Сидорова', agent_code: 'EMP-002', role: 'senior', skills: ['customer_service', 'technical'], availability_score: 88 },
      { id: 3, name: 'Алексей Козлов', agent_code: 'EMP-003', role: 'member', skills: ['customer_service'], availability_score: 92 },
      { id: 4, name: 'Елена Новикова', agent_code: 'EMP-004', role: 'member', skills: ['customer_service', 'billing'], availability_score: 85 },
      { id: 5, name: 'Дмитрий Волков', agent_code: 'EMP-005', role: 'member', skills: ['technical', 'escalation'], availability_score: 90 }
    ];

    const shifts: ShiftAssignment[] = [];
    const days = ['2025-07-21', '2025-07-22', '2025-07-23', '2025-07-24', '2025-07-25'];
    
    teamMembers.forEach((member, memberIndex) => {
      days.forEach((date, dayIndex) => {
        if (dayIndex === 4 && memberIndex >= 3) return; // Some members off Friday
        
        const baseHour = 9 + (memberIndex * 2) % 3; // Stagger start times
        shifts.push({
          id: `shift-${member.id}-${date}`,
          employee_id: member.id,
          employee_name: member.name,
          date,
          start_time: `${baseHour.toString().padStart(2, '0')}:00`,
          end_time: `${(baseHour + 8).toString().padStart(2, '0')}:00`,
          shift_type: dayIndex === 4 ? 'overtime' : 'regular',
          status: Math.random() > 0.1 ? 'confirmed' : 'pending',
          coverage_weight: 1.0,
          skills_required: member.skills.slice(0, 2)
        });
      });
    });

    const coverageGaps: CoverageGap[] = [
      {
        date: '2025-07-25',
        time_slot: '15:00-17:00',
        required_staff: 5,
        current_staff: 3,
        gap_severity: 'medium',
        suggested_actions: ['Запросить сверхурочную работу', 'Перенести с другой смены']
      }
    ];

    const conflicts: ScheduleConflict[] = [
      {
        id: 'conflict-1',
        type: 'overtime_limit',
        description: 'Дмитрий Волков превышает лимит сверхурочных часов',
        affected_shifts: ['shift-5-2025-07-25'],
        resolution_options: ['Назначить другого сотрудника', 'Сократить смену'],
        priority: 'medium'
      }
    ];

    return {
      team: {
        id: 1,
        name: 'Команда Клиентского Сервиса',
        manager_id: 10,
        total_members: 5
      },
      schedule_period: {
        start_date: '2025-07-21',
        end_date: '2025-07-25',
        week_number: 30
      },
      team_members: teamMembers,
      shift_assignments: shifts,
      coverage_analysis: {
        overall_coverage: 92,
        gaps: coverageGaps,
        efficiency_score: 88.5
      },
      conflicts: conflicts,
      templates: [
        { id: 'template-1', name: 'Стандартная неделя', description: '5 дней по 8 часов' },
        { id: 'template-2', name: 'Праздничная неделя', description: 'Сокращенные смены' }
      ]
    };
  };

  const handleShiftEdit = async (shiftId: string, updates: Partial<ShiftAssignment>) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/teams/${scheduleData?.team.id}/schedule/shift/${shiftId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updates)
      });

      if (response.ok) {
        console.log('✅ Shift updated successfully');
        await loadTeamSchedule(); // Refresh data
      } else {
        console.log('⚠️ Shift update demo mode');
        // Optimistic update for demo
        if (scheduleData) {
          const updatedShifts = scheduleData.shift_assignments.map(shift =>
            shift.id === shiftId ? { ...shift, ...updates } : shift
          );
          setScheduleData({ ...scheduleData, shift_assignments: updatedShifts });
        }
      }
    } catch (error) {
      console.log('⚠️ Shift update error, demo mode active');
    }
    setEditingShift(null);
  };

  const handleBulkOperation = async (operation: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/teams/${scheduleData?.team.id}/schedule/bulk`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          shift_ids: selectedShifts,
          operation: operation
        })
      });

      if (response.ok) {
        console.log('✅ Bulk operation completed');
        await loadTeamSchedule();
      } else {
        console.log('⚠️ Bulk operation demo mode');
      }
    } catch (error) {
      console.log('⚠️ Bulk operation error, demo mode active');
    }
    setSelectedShifts([]);
    setBulkEditMode(false);
  };

  const resolveConflict = async (conflictId: string, resolution: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/teams/${scheduleData?.team.id}/schedule/conflicts/${conflictId}/resolve`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ resolution })
      });

      if (response.ok) {
        console.log('✅ Conflict resolved');
        await loadTeamSchedule();
      } else {
        console.log('⚠️ Conflict resolution demo mode');
      }
    } catch (error) {
      console.log('⚠️ Conflict resolution error, demo mode active');
    }
  };

  const getShiftsByDate = (date: string) => {
    return scheduleData?.shift_assignments.filter(shift => shift.date === date) || [];
  };

  const getShiftStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-800 border-green-200';
      case 'pending': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'conflict': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getCoverageColor = (coverage: number) => {
    if (coverage >= 95) return 'text-green-600';
    if (coverage >= 85) return 'text-yellow-600';
    return 'text-red-600';
  };

  const renderScheduleGrid = () => {
    if (!scheduleData) return null;

    const days = ['2025-07-21', '2025-07-22', '2025-07-23', '2025-07-24', '2025-07-25'];
    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт'];

    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Grid Header */}
        <div className="grid grid-cols-6 border-b border-gray-200">
          <div className="p-3 bg-gray-50 font-medium text-gray-900">Сотрудник</div>
          {days.map((date, index) => (
            <div key={date} className="p-3 bg-gray-50 text-center border-l border-gray-200">
              <div className="font-medium text-gray-900">{dayNames[index]}</div>
              <div className="text-sm text-gray-600">{new Date(date).getDate()}.07</div>
            </div>
          ))}
        </div>

        {/* Team Members and Shifts */}
        {scheduleData.team_members.map((member) => (
          <div key={member.id} className="grid grid-cols-6 border-b border-gray-200 hover:bg-gray-50">
            {/* Employee Info */}
            <div className="p-3 border-r border-gray-200">
              <div className="font-medium text-gray-900">{member.name}</div>
              <div className="text-sm text-gray-600">{member.agent_code}</div>
              <div className="flex gap-1 mt-1">
                {member.skills.slice(0, 2).map(skill => (
                  <span key={skill} className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                    {skill}
                  </span>
                ))}
              </div>
            </div>

            {/* Daily Shifts */}
            {days.map((date) => {
              const shift = scheduleData.shift_assignments.find(
                s => s.employee_id === member.id && s.date === date
              );
              
              return (
                <div key={`${member.id}-${date}`} className="p-2 border-l border-gray-200 min-h-[80px]">
                  {shift ? (
                    <div 
                      className={`p-2 rounded border cursor-pointer hover:shadow-sm ${getShiftStatusColor(shift.status)} ${
                        selectedShifts.includes(shift.id) ? 'ring-2 ring-blue-500' : ''
                      }`}
                      onClick={() => {
                        if (bulkEditMode) {
                          setSelectedShifts(prev => 
                            prev.includes(shift.id) 
                              ? prev.filter(id => id !== shift.id)
                              : [...prev, shift.id]
                          );
                        } else {
                          setEditingShift(shift.id);
                        }
                      }}
                    >
                      <div className="text-sm font-medium">
                        {shift.start_time}-{shift.end_time}
                      </div>
                      <div className="text-xs">
                        {russianTranslations.shiftTypes[shift.shift_type]}
                      </div>
                      <div className="text-xs mt-1">
                        {russianTranslations.status[shift.status]}
                      </div>
                    </div>
                  ) : (
                    <div className="h-full flex items-center justify-center text-gray-400">
                      <button
                        onClick={() => {/* Add shift logic */}}
                        className="p-2 hover:bg-gray-100 rounded-lg"
                      >
                        <Plus className="h-4 w-4" />
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    );
  };

  const renderCoverageAnalysis = () => {
    if (!scheduleData) return null;

    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Анализ Покрытия</h3>
        
        <div className="grid grid-cols-3 gap-4 mb-4">
          <div className="text-center">
            <div className={`text-2xl font-bold ${getCoverageColor(scheduleData.coverage_analysis.overall_coverage)}`}>
              {scheduleData.coverage_analysis.overall_coverage}%
            </div>
            <div className="text-sm text-gray-600">Общее покрытие</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">
              {scheduleData.coverage_analysis.efficiency_score}%
            </div>
            <div className="text-sm text-gray-600">Эффективность</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-orange-600">
              {scheduleData.coverage_analysis.gaps.length}
            </div>
            <div className="text-sm text-gray-600">Пробелы</div>
          </div>
        </div>

        {scheduleData.coverage_analysis.gaps.length > 0 && (
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Пробелы в покрытии:</h4>
            {scheduleData.coverage_analysis.gaps.map((gap, index) => (
              <div key={index} className="mb-2 p-3 bg-orange-50 border border-orange-200 rounded-lg">
                <div className="flex justify-between items-start">
                  <div>
                    <div className="font-medium text-orange-900">
                      {gap.date} - {gap.time_slot}
                    </div>
                    <div className="text-sm text-orange-800">
                      Требуется: {gap.required_staff}, Назначено: {gap.current_staff}
                    </div>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded ${
                    gap.gap_severity === 'critical' ? 'bg-red-100 text-red-800' :
                    gap.gap_severity === 'high' ? 'bg-orange-100 text-orange-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {russianTranslations.coverageGaps[gap.gap_severity]}
                  </span>
                </div>
                <div className="mt-2">
                  <div className="text-sm text-gray-700">Предложения:</div>
                  <ul className="text-sm text-gray-600 list-disc list-inside">
                    {gap.suggested_actions.map((action, i) => (
                      <li key={i}>{action}</li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  };

  const renderConflicts = () => {
    if (!scheduleData || scheduleData.conflicts.length === 0) return null;

    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Конфликты Расписания</h3>
        
        {scheduleData.conflicts.map((conflict) => (
          <div key={conflict.id} className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex justify-between items-start mb-2">
              <div>
                <div className="font-medium text-red-900">{conflict.description}</div>
                <div className="text-sm text-red-800">
                  Тип: {russianTranslations.conflictTypes[conflict.type]}
                </div>
              </div>
              <span className={`text-xs px-2 py-1 rounded ${
                conflict.priority === 'high' ? 'bg-red-100 text-red-800' :
                conflict.priority === 'medium' ? 'bg-orange-100 text-orange-800' :
                'bg-yellow-100 text-yellow-800'
              }`}>
                {conflict.priority}
              </span>
            </div>
            
            <div className="mb-3">
              <div className="text-sm text-gray-700 mb-2">Варианты решения:</div>
              <div className="space-y-1">
                {conflict.resolution_options.map((option, index) => (
                  <button
                    key={index}
                    onClick={() => resolveConflict(conflict.id, option)}
                    className="block w-full text-left text-sm text-blue-600 hover:text-blue-800 hover:bg-blue-50 px-2 py-1 rounded"
                  >
                    • {option}
                  </button>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Загрузка расписания команды...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6" data-testid="team-schedule-grid">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
          {scheduleData && (
            <p className="text-gray-600">
              {scheduleData.team.name} - Неделя {scheduleData.schedule_period.week_number}
            </p>
          )}
        </div>
        
        <div className="flex items-center gap-3">
          <button
            onClick={() => setViewMode(viewMode === 'grid' ? 'list' : 'grid')}
            className="flex items-center gap-2 px-3 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            {viewMode === 'grid' ? <List className="h-4 w-4" /> : <Grid className="h-4 w-4" />}
            {viewMode === 'grid' ? 'Список' : 'Сетка'}
          </button>
          
          <button
            onClick={() => setBulkEditMode(!bulkEditMode)}
            className={`flex items-center gap-2 px-3 py-2 rounded-lg ${
              bulkEditMode ? 'bg-blue-600 text-white' : 'text-gray-700 border border-gray-300 hover:bg-gray-50'
            }`}
          >
            <Edit3 className="h-4 w-4" />
            {russianTranslations.actions.bulkEdit}
          </button>
          
          <button
            onClick={loadTeamSchedule}
            className="flex items-center gap-2 px-3 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            <RotateCcw className="h-4 w-4" />
            {russianTranslations.actions.refresh}
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-yellow-800">{error}</p>
        </div>
      )}

      {/* Bulk Edit Actions */}
      {bulkEditMode && selectedShifts.length > 0 && (
        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <div className="flex items-center justify-between">
            <span className="text-blue-800">
              Выбрано смен: {selectedShifts.length}
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => handleBulkOperation('extend_1h')}
                className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
              >
                Продлить на 1ч
              </button>
              <button
                onClick={() => handleBulkOperation('shift_start_1h')}
                className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
              >
                Сдвинуть на 1ч
              </button>
              <button
                onClick={() => setSelectedShifts([])}
                className="px-3 py-1 bg-gray-300 text-gray-700 text-sm rounded hover:bg-gray-400"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Schedule Grid */}
      {renderScheduleGrid()}

      {/* Coverage Analysis and Conflicts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {renderCoverageAnalysis()}
        {scheduleData && scheduleData.conflicts.length > 0 && renderConflicts()}
      </div>
    </div>
  );
};

export default TeamScheduleGrid;