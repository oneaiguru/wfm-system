import React, { useState, useEffect } from 'react';
import { Users, Calendar, Clock, TrendingUp, AlertCircle, CheckCircle, BarChart3, Settings } from 'lucide-react';
import SupervisorApprovalPanel from './SupervisorApprovalPanel';
import RequestStatusTracker from '../common/RequestStatusTracker';

interface TeamManagementDashboardProps {
  supervisorId: string;
}

interface TeamMetrics {
  totalEmployees: number;
  activeRequests: number;
  approvalsPending: number;
  scheduleCompliance: number;
  workloadDistribution: number;
}

interface TeamMember {
  id: string;
  name: string;
  department: string;
  position: string;
  status: 'active' | 'on_leave' | 'sick' | 'vacation';
  currentShift?: {
    startTime: string;
    endTime: string;
    location: string;
  };
  pendingRequests: number;
  workloadScore: number;
}

interface RecentActivity {
  id: string;
  type: 'request_created' | 'request_approved' | 'request_rejected' | 'shift_changed';
  employeeName: string;
  description: string;
  timestamp: Date;
  priority: 'low' | 'normal' | 'high';
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations per BDD spec
const translations = {
  title: 'Управление командой',
  tabs: {
    dashboard: 'Обзор',
    approvals: 'Заявки',
    team: 'Команда',
    schedule: 'Расписание',
    analytics: 'Аналитика'
  },
  metrics: {
    totalEmployees: 'Сотрудники',
    activeRequests: 'Активные заявки',
    approvalsPending: 'Ожидают одобрения',
    scheduleCompliance: 'Соблюдение расписания',
    workloadDistribution: 'Распределение нагрузки'
  },
  teamStatus: {
    active: 'Активен',
    on_leave: 'В отпуске',
    sick: 'Болен',
    vacation: 'В отгуле'
  },
  recentActivity: {
    title: 'Недавняя активность',
    request_created: 'Создана заявка',
    request_approved: 'Заявка одобрена',
    request_rejected: 'Заявка отклонена',
    shift_changed: 'Изменение смены'
  },
  actions: {
    viewDetails: 'Подробности',
    approveRequest: 'Одобрить',
    rejectRequest: 'Отклонить',
    viewSchedule: 'Расписание',
    editSchedule: 'Изменить расписание'
  },
  quickActions: {
    title: 'Быстрые действия',
    approveAll: 'Одобрить все',
    viewReports: 'Отчёты',
    scheduleUpdate: 'Обновить расписание',
    teamMeeting: 'Встреча команды'
  }
};

const TeamManagementDashboard: React.FC<TeamManagementDashboardProps> = ({ supervisorId }) => {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'approvals' | 'team' | 'schedule' | 'analytics'>('dashboard');
  const [metrics, setMetrics] = useState<TeamMetrics>({
    totalEmployees: 0,
    activeRequests: 0,
    approvalsPending: 0,
    scheduleCompliance: 0,
    workloadDistribution: 0
  });
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([]);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, [supervisorId]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // Load team metrics
      const metricsResponse = await fetch(
        `${API_BASE_URL}/supervisors/${supervisorId}/metrics`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (metricsResponse.ok) {
        const metricsData = await metricsResponse.json();
        setMetrics({
          totalEmployees: metricsData.total_employees || 0,
          activeRequests: metricsData.active_requests || 0,
          approvalsPending: metricsData.approvals_pending || 0,
          scheduleCompliance: metricsData.schedule_compliance || 0,
          workloadDistribution: metricsData.workload_distribution || 0
        });
      }

      // Load team members
      const teamResponse = await fetch(
        `${API_BASE_URL}/supervisors/${supervisorId}/team`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (teamResponse.ok) {
        const teamData = await teamResponse.json();
        const mappedTeam = (teamData.employees || []).map((employee: any) => ({
          id: employee.id,
          name: employee.name,
          department: employee.department,
          position: employee.position,
          status: employee.status || 'active',
          currentShift: employee.current_shift ? {
            startTime: employee.current_shift.start_time,
            endTime: employee.current_shift.end_time,
            location: employee.current_shift.location
          } : undefined,
          pendingRequests: employee.pending_requests || 0,
          workloadScore: employee.workload_score || 0
        }));
        setTeamMembers(mappedTeam);
      }

      // Load recent activity
      const activityResponse = await fetch(
        `${API_BASE_URL}/supervisors/${supervisorId}/recent-activity`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (activityResponse.ok) {
        const activityData = await activityResponse.json();
        const mappedActivity = (activityData.activities || []).map((activity: any) => ({
          id: activity.id,
          type: activity.type,
          employeeName: activity.employee_name,
          description: activity.description,
          timestamp: new Date(activity.timestamp),
          priority: activity.priority || 'normal'
        }));
        setRecentActivity(mappedActivity);
      }

    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'on_leave': return 'bg-blue-100 text-blue-800';
      case 'sick': return 'bg-red-100 text-red-800';
      case 'vacation': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'normal': return 'bg-blue-100 text-blue-800';
      case 'low': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'request_created': return <AlertCircle className="h-4 w-4 text-blue-600" />;
      case 'request_approved': return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'request_rejected': return <AlertCircle className="h-4 w-4 text-red-600" />;
      case 'shift_changed': return <Calendar className="h-4 w-4 text-purple-600" />;
      default: return <Clock className="h-4 w-4 text-gray-600" />;
    }
  };

  const formatTimestamp = (date: Date) => {
    return date.toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const renderMetricsCard = (title: string, value: number, suffix: string = '', icon: React.ReactNode) => (
    <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}{suffix}</p>
        </div>
        <div className="p-3 bg-blue-50 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );

  const renderDashboardTab = () => (
    <div className="space-y-6">
      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        {renderMetricsCard(
          translations.metrics.totalEmployees,
          metrics.totalEmployees,
          '',
          <Users className="h-6 w-6 text-blue-600" />
        )}
        {renderMetricsCard(
          translations.metrics.activeRequests,
          metrics.activeRequests,
          '',
          <Clock className="h-6 w-6 text-blue-600" />
        )}
        {renderMetricsCard(
          translations.metrics.approvalsPending,
          metrics.approvalsPending,
          '',
          <AlertCircle className="h-6 w-6 text-blue-600" />
        )}
        {renderMetricsCard(
          translations.metrics.scheduleCompliance,
          metrics.scheduleCompliance,
          '%',
          <CheckCircle className="h-6 w-6 text-blue-600" />
        )}
        {renderMetricsCard(
          translations.metrics.workloadDistribution,
          metrics.workloadDistribution,
          '%',
          <BarChart3 className="h-6 w-6 text-blue-600" />
        )}
      </div>

      {/* Team Overview & Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Team Overview */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <Users className="h-5 w-5 text-blue-600" />
              Команда
            </h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {teamMembers.slice(0, 5).map((member) => (
                <div key={member.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                      <span className="text-blue-600 font-medium text-sm">
                        {member.name.split(' ').map(n => n[0]).join('')}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{member.name}</p>
                      <p className="text-sm text-gray-600">{member.position}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(member.status)}`}>
                      {translations.teamStatus[member.status as keyof typeof translations.teamStatus]}
                    </span>
                    {member.pendingRequests > 0 && (
                      <span className="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                        {member.pendingRequests}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-blue-600" />
              {translations.recentActivity.title}
            </h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {recentActivity.slice(0, 5).map((activity) => (
                <div key={activity.id} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                  <div className="mt-1">
                    {getActivityIcon(activity.type)}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <p className="font-medium text-gray-900">{activity.employeeName}</p>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPriorityColor(activity.priority)}`}>
                        {activity.priority}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 mt-1">{activity.description}</p>
                    <p className="text-xs text-gray-500 mt-1">{formatTimestamp(activity.timestamp)}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <Settings className="h-5 w-5 text-blue-600" />
            {translations.quickActions.title}
          </h3>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <button className="p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors text-center">
              <CheckCircle className="h-6 w-6 text-blue-600 mx-auto mb-2" />
              <span className="text-sm font-medium text-blue-900">{translations.quickActions.approveAll}</span>
            </button>
            <button className="p-4 bg-green-50 rounded-lg hover:bg-green-100 transition-colors text-center">
              <BarChart3 className="h-6 w-6 text-green-600 mx-auto mb-2" />
              <span className="text-sm font-medium text-green-900">{translations.quickActions.viewReports}</span>
            </button>
            <button className="p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors text-center">
              <Calendar className="h-6 w-6 text-purple-600 mx-auto mb-2" />
              <span className="text-sm font-medium text-purple-900">{translations.quickActions.scheduleUpdate}</span>
            </button>
            <button className="p-4 bg-orange-50 rounded-lg hover:bg-orange-100 transition-colors text-center">
              <Users className="h-6 w-6 text-orange-600 mx-auto mb-2" />
              <span className="text-sm font-medium text-orange-900">{translations.quickActions.teamMeeting}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return renderDashboardTab();
      case 'approvals':
        return <SupervisorApprovalPanel supervisorId={supervisorId} />;
      case 'team':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Управление командой</h3>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {teamMembers.map((member) => (
                  <div key={member.id} className="border rounded-lg p-4">
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-blue-600 font-medium">
                          {member.name.split(' ').map(n => n[0]).join('')}
                        </span>
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{member.name}</p>
                        <p className="text-sm text-gray-600">{member.position}</p>
                      </div>
                    </div>
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Отдел:</span>
                        <span className="text-gray-900">{member.department}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Статус:</span>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(member.status)}`}>
                          {translations.teamStatus[member.status as keyof typeof translations.teamStatus]}
                        </span>
                      </div>
                      {member.currentShift && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Смена:</span>
                          <span className="text-gray-900">{member.currentShift.startTime} - {member.currentShift.endTime}</span>
                        </div>
                      )}
                      <div className="flex justify-between">
                        <span className="text-gray-600">Заявки:</span>
                        <span className="text-gray-900">{member.pendingRequests}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );
      case 'schedule':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Расписание команды</h3>
            </div>
            <div className="p-6">
              <div className="text-center py-12">
                <Calendar className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">Расписание команды</h3>
                <p className="text-gray-500">Функция в разработке</p>
              </div>
            </div>
          </div>
        );
      case 'analytics':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Аналитика</h3>
            </div>
            <div className="p-6">
              <div className="text-center py-12">
                <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">Аналитика и отчёты</h3>
                <p className="text-gray-500">Функция в разработке</p>
              </div>
            </div>
          </div>
        );
      default:
        return renderDashboardTab();
    }
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-24 bg-gray-300 rounded"></div>
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="h-64 bg-gray-300 rounded"></div>
            <div className="h-64 bg-gray-300 rounded"></div>
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
          <div className="flex items-center gap-3 mb-6">
            <Users className="h-6 w-6 text-blue-600" />
            <h2 className="text-2xl font-semibold text-gray-900">{translations.title}</h2>
          </div>

          {/* Tabs */}
          <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
            {Object.entries(translations.tabs).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setActiveTab(key as any)}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors flex-1 ${
                  activeTab === key
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Tab Content */}
        <div className="p-6">
          {renderTabContent()}
        </div>
      </div>
    </div>
  );
};

export default TeamManagementDashboard;