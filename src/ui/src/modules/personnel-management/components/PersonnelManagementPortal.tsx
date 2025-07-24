/**
 * Personnel Management Portal - SPEC-16 Integration
 * Comprehensive HR management interface with organizational structure
 * Russian localization for HR administrators and managers
 */

import React, { useState, useEffect } from 'react';
import { 
  Users, Building2, UserPlus, Search, BarChart3, Calendar, 
  FileText, Settings, Download, Filter, RefreshCw, AlertCircle
} from 'lucide-react';

// Import existing components and new SPEC-16 components
import EmployeeListContainer from '../../employee-management/components/crud/EmployeeListContainer';
import EmployeeSearch from '../../../components/employee/EmployeeSearch';
import OrgChart from './OrgChart';
import realPersonnelService, { 
  OrganizationalHierarchy, 
  Employee, 
  LifecycleEvent,
  SpanOfControlAnalysis 
} from '../../../services/realPersonnelService';

interface PersonnelManagementPortalProps {
  userRole?: 'hr_admin' | 'manager' | 'viewer';
  departmentId?: string;
}

type ViewMode = 'overview' | 'orgchart' | 'employees' | 'lifecycle' | 'analytics' | 'search';

// Complete Russian translations for SPEC-16
const translations = {
  title: 'Управление Персоналом',
  subtitle: 'Комплексная система управления сотрудниками и организационной структурой',
  tabs: {
    overview: 'Обзор',
    orgchart: 'Оргструктура',
    employees: 'Сотрудники',
    lifecycle: 'Жизненный цикл',
    analytics: 'Аналитика',
    search: 'Поиск'
  },
  overview: {
    totalEmployees: 'Всего сотрудников',
    activeDepartments: 'Активных отделов',
    pendingActions: 'Ожидающих действий',
    recentHires: 'Новых сотрудников',
    upcomingEvents: 'Предстоящие события',
    criticalAlerts: 'Критические уведомления'
  },
  actions: {
    addEmployee: 'Добавить сотрудника',
    createDepartment: 'Создать отдел',
    exportData: 'Экспорт данных',
    generateReport: 'Создать отчет',
    refresh: 'Обновить',
    viewDetails: 'Подробнее'
  },
  lifecycle: {
    hired: 'Принят на работу',
    promoted: 'Повышен',
    transferred: 'Переведен',
    leave: 'В отпуске',
    return: 'Возвращается',
    terminated: 'Уволен',
    scheduled: 'Запланировано',
    active: 'Активно',
    completed: 'Завершено'
  }
};

const PersonnelManagementPortal: React.FC<PersonnelManagementPortalProps> = ({
  userRole = 'hr_admin',
  departmentId
}) => {
  const [activeView, setActiveView] = useState<ViewMode>('overview');
  const [loading, setLoading] = useState(false);
  const [apiHealthy, setApiHealthy] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [selectedDepartment, setSelectedDepartment] = useState<OrganizationalHierarchy | null>(null);
  const [upcomingEvents, setUpcomingEvents] = useState<LifecycleEvent[]>([]);
  const [overviewStats, setOverviewStats] = useState({
    totalEmployees: 245,
    activeDepartments: 8,
    pendingActions: 12,
    recentHires: 5
  });

  // Demo upcoming lifecycle events
  const demoUpcomingEvents: LifecycleEvent[] = [
    {
      id: '1',
      employee_id: 'emp-001',
      event_type: 'return',
      event_date: '2025-07-25',
      details: 'Анна Иванова возвращается из декретного отпуска',
      status: 'scheduled',
      created_by: 'hr-admin',
      notes: 'Подготовить рабочее место'
    },
    {
      id: '2',
      employee_id: 'emp-002',
      event_type: 'promoted',
      event_date: '2025-08-01',
      details: 'Дмитрий Петров - повышение до старшего менеджера',
      previous_position: 'Менеджер',
      new_position: 'Старший менеджер',
      status: 'scheduled',
      created_by: 'hr-admin'
    },
    {
      id: '3',
      employee_id: 'emp-003',
      event_type: 'hired',
      event_date: '2025-08-05',
      details: 'Елена Козлова - новый специалист по подбору',
      new_position: 'Специалист по подбору',
      status: 'scheduled',
      created_by: 'hr-admin'
    }
  ];

  useEffect(() => {
    checkApiHealth();
    loadOverviewData();
  }, []);

  const checkApiHealth = async () => {
    try {
      const healthy = await realPersonnelService.checkPersonnelApiHealth();
      setApiHealthy(healthy);
      console.log(`[PERSONNEL PORTAL] API Health: ${healthy ? 'OK' : 'ERROR'}`);
    } catch (error) {
      console.error('[PERSONNEL PORTAL] Health check failed:', error);
      setApiHealthy(false);
    }
  };

  const loadOverviewData = async () => {
    setLoading(true);
    try {
      if (apiHealthy) {
        console.log('[PERSONNEL PORTAL] Loading overview data from API...');
        
        // Load upcoming lifecycle events
        const eventsResult = await realPersonnelService.getUpcomingLifecycleActions();
        if (eventsResult.success && eventsResult.data) {
          setUpcomingEvents(eventsResult.data);
        } else {
          setUpcomingEvents(demoUpcomingEvents);
        }
        
        // Load organizational metrics (would come from API)
        // For now using demo data
        setOverviewStats({
          totalEmployees: 245,
          activeDepartments: 8,
          pendingActions: 12,
          recentHires: 5
        });
      } else {
        console.log('[PERSONNEL PORTAL] API unhealthy, using demo data');
        setUpcomingEvents(demoUpcomingEvents);
      }
    } catch (error) {
      console.error('[PERSONNEL PORTAL] Load overview error:', error);
      setUpcomingEvents(demoUpcomingEvents);
    } finally {
      setLoading(false);
    }
  };

  const getEventTypeIcon = (eventType: string) => {
    switch (eventType) {
      case 'hired': return '👋';
      case 'promoted': return '⬆️';
      case 'transferred': return '↔️';
      case 'leave': return '🏖️';
      case 'return': return '🔄';
      case 'terminated': return '👋';
      default: return '📅';
    }
  };

  const getEventStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800';
      case 'active': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <Users className="h-8 w-8 text-blue-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">{overviewStats.totalEmployees}</div>
              <div className="text-sm text-gray-600">{translations.overview.totalEmployees}</div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <Building2 className="h-8 w-8 text-green-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">{overviewStats.activeDepartments}</div>
              <div className="text-sm text-gray-600">{translations.overview.activeDepartments}</div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <AlertCircle className="h-8 w-8 text-orange-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">{overviewStats.pendingActions}</div>
              <div className="text-sm text-gray-600">{translations.overview.pendingActions}</div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <UserPlus className="h-8 w-8 text-purple-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">{overviewStats.recentHires}</div>
              <div className="text-sm text-gray-600">{translations.overview.recentHires}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Upcoming Lifecycle Events */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">{translations.overview.upcomingEvents}</h3>
        </div>
        <div className="divide-y divide-gray-200">
          {upcomingEvents.length === 0 ? (
            <div className="p-6 text-center">
              <Calendar className="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <p className="text-gray-600">Нет предстоящих событий</p>
            </div>
          ) : (
            upcomingEvents.map((event) => (
              <div key={event.id} className="p-6 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="text-2xl">{getEventTypeIcon(event.event_type)}</div>
                    <div>
                      <h4 className="font-medium text-gray-900">
                        {translations.lifecycle[event.event_type as keyof typeof translations.lifecycle]}
                      </h4>
                      <p className="text-sm text-gray-600">{event.details}</p>
                      <div className="flex items-center gap-4 mt-1 text-xs text-gray-500">
                        <span>📅 {event.event_date}</span>
                        {event.new_position && <span>🎯 {event.new_position}</span>}
                        {event.notes && <span>📝 {event.notes}</span>}
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getEventStatusColor(event.status)}`}>
                      {translations.lifecycle[event.status as keyof typeof translations.lifecycle]}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Quick Actions */}
      {userRole === 'hr_admin' && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Быстрые действия</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button
              onClick={() => setActiveView('employees')}
              className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-400 hover:bg-blue-50 transition-colors text-left group"
            >
              <div className="flex items-center gap-3 mb-2">
                <UserPlus className="h-5 w-5 text-blue-600" />
                <span className="font-medium text-gray-900 group-hover:text-blue-900">{translations.actions.addEmployee}</span>
              </div>
              <p className="text-sm text-gray-600">Добавить нового сотрудника в систему</p>
            </button>

            <button
              onClick={() => setActiveView('orgchart')}
              className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-green-400 hover:bg-green-50 transition-colors text-left group"
            >
              <div className="flex items-center gap-3 mb-2">
                <Building2 className="h-5 w-5 text-green-600" />
                <span className="font-medium text-gray-900 group-hover:text-green-900">{translations.actions.createDepartment}</span>
              </div>
              <p className="text-sm text-gray-600">Создать новый отдел или команду</p>
            </button>

            <button
              onClick={() => setActiveView('analytics')}
              className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-purple-400 hover:bg-purple-50 transition-colors text-left group"
            >
              <div className="flex items-center gap-3 mb-2">
                <BarChart3 className="h-5 w-5 text-purple-600" />
                <span className="font-medium text-gray-900 group-hover:text-purple-900">{translations.actions.generateReport}</span>
              </div>
              <p className="text-sm text-gray-600">Создать отчет по персоналу</p>
            </button>
          </div>
        </div>
      )}
    </div>
  );

  const renderActiveView = () => {
    switch (activeView) {
      case 'overview':
        return renderOverview();
      case 'orgchart':
        return (
          <OrgChart 
            editable={userRole === 'hr_admin'}
            showMetrics={true}
            onEmployeeSelect={setSelectedEmployee}
            onDepartmentSelect={setSelectedDepartment}
          />
        );
      case 'employees':
        return <EmployeeListContainer />;
      case 'search':
        return (
          <div className="space-y-6">
            <EmployeeSearch 
              onEmployeeSelect={setSelectedEmployee}
              showFilters={true}
            />
          </div>
        );
      case 'lifecycle':
        return (
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Управление жизненным циклом сотрудников</h3>
            <p className="text-gray-600">Функционал в разработке - отслеживание карьерного пути сотрудников</p>
          </div>
        );
      case 'analytics':
        return (
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">HR Аналитика</h3>
            <p className="text-gray-600">Функционал в разработке - аналитика по персоналу и KPI</p>
          </div>
        );
      default:
        return renderOverview();
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{translations.title}</h1>
          <p className="text-gray-600">{translations.subtitle}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-sm text-gray-500">Роль: {userRole === 'hr_admin' ? 'HR Администратор' : 'Менеджер'}</span>
            <span className={`text-xs px-2 py-1 rounded-full ${apiHealthy ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
              API: {apiHealthy ? 'SPEC-16 ✅' : 'Demo режим'}
            </span>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={loadOverviewData}
            disabled={loading}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            {translations.actions.refresh}
          </button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {Object.entries(translations.tabs).map(([key, label]) => (
            <button
              key={key}
              onClick={() => setActiveView(key as ViewMode)}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeView === key
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {label}
            </button>
          ))}
        </nav>
      </div>

      {/* Active View Content */}
      {renderActiveView()}
    </div>
  );
};

export default PersonnelManagementPortal;