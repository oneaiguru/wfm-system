import React, { useState, useEffect } from 'react';
import { Users, Settings, LogOut, Shield, BarChart3, FileText, Calendar, Home } from 'lucide-react';
import TeamManagementDashboard from './TeamManagementDashboard';
import SupervisorApprovalPanel from './SupervisorApprovalPanel';
import { realAuthService } from '../../services/realAuthService';

interface SupervisorPortalProps {
  supervisorId: string;
}

interface Supervisor {
  id: string;
  name: string;
  email: string;
  role: string;
  department: string;
  teamSize: number;
  permissions: string[];
}

// Russian translations per BDD spec
const translations = {
  title: 'Портал руководителя',
  greeting: 'Здравствуйте',
  navigation: {
    dashboard: 'Обзор',
    team: 'Команда',
    approvals: 'Заявки',
    schedule: 'Расписание',
    reports: 'Отчёты',
    settings: 'Настройки',
    logout: 'Выход из системы'
  },
  welcome: {
    title: 'Добро пожаловать в портал руководителя',
    subtitle: 'Управляйте командой и утверждайте заявки'
  },
  permissions: {
    approve_requests: 'Утверждение заявок',
    manage_schedules: 'Управление расписанием',
    view_reports: 'Просмотр отчётов',
    team_management: 'Управление командой'
  }
};

const SupervisorPortal: React.FC<SupervisorPortalProps> = ({ supervisorId }) => {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'team' | 'approvals' | 'schedule' | 'reports' | 'settings'>('dashboard');
  const [supervisor, setSupervisor] = useState<Supervisor | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSupervisorData();
  }, [supervisorId]);

  const loadSupervisorData = async () => {
    try {
      // Try to get supervisor data from auth service first
      const currentUser = realAuthService.getCurrentUser();
      if (currentUser && currentUser.role === 'supervisor') {
        setSupervisor({
          id: currentUser.id.toString(),
          name: currentUser.name,
          email: currentUser.email,
          role: currentUser.role,
          department: currentUser.department,
          teamSize: 0, // Will be loaded from API
          permissions: ['approve_requests', 'manage_schedules', 'view_reports', 'team_management']
        });
      } else {
        // Fallback to API call
        const response = await fetch(`${process.env.VITE_API_URL || 'http://localhost:8001/api/v1'}/supervisors/${supervisorId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        });

        if (response.ok) {
          const supervisorData = await response.json();
          setSupervisor({
            id: supervisorData.id,
            name: supervisorData.name || supervisorData.full_name,
            email: supervisorData.email,
            role: supervisorData.role || 'Руководитель',
            department: supervisorData.department || 'Отдел',
            teamSize: supervisorData.team_size || 0,
            permissions: supervisorData.permissions || ['approve_requests', 'manage_schedules', 'view_reports', 'team_management']
          });
        }
      }
    } catch (error) {
      console.error('Error loading supervisor data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      await realAuthService.logout();
      window.location.href = '/login';
    } catch (error) {
      console.error('Logout error:', error);
      // Force logout even if API fails
      window.location.href = '/login';
    }
  };

  const getTabIcon = (tab: string) => {
    switch (tab) {
      case 'dashboard':
        return <Home className="h-5 w-5" />;
      case 'team':
        return <Users className="h-5 w-5" />;
      case 'approvals':
        return <FileText className="h-5 w-5" />;
      case 'schedule':
        return <Calendar className="h-5 w-5" />;
      case 'reports':
        return <BarChart3 className="h-5 w-5" />;
      case 'settings':
        return <Settings className="h-5 w-5" />;
      default:
        return <Home className="h-5 w-5" />;
    }
  };

  const hasPermission = (permission: string) => {
    return supervisor?.permissions.includes(permission) || false;
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dashboard':
      case 'team':
        return <TeamManagementDashboard supervisorId={supervisorId} />;
      case 'approvals':
        return hasPermission('approve_requests') ? (
          <SupervisorApprovalPanel supervisorId={supervisorId} />
        ) : (
          <div className="p-6 text-center">
            <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Доступ ограничен</h3>
            <p className="text-gray-500">У вас нет прав для просмотра этого раздела</p>
          </div>
        );
      case 'schedule':
        return hasPermission('manage_schedules') ? (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900">Управление расписанием</h3>
              </div>
              <div className="p-6">
                <div className="text-center py-12">
                  <Calendar className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Расписание команды</h3>
                  <p className="text-gray-500">Функция в разработке</p>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="p-6 text-center">
            <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Доступ ограничен</h3>
            <p className="text-gray-500">У вас нет прав для управления расписанием</p>
          </div>
        );
      case 'reports':
        return hasPermission('view_reports') ? (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900">Отчёты и аналитика</h3>
              </div>
              <div className="p-6">
                <div className="text-center py-12">
                  <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Отчёты</h3>
                  <p className="text-gray-500">Функция в разработке</p>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="p-6 text-center">
            <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Доступ ограничен</h3>
            <p className="text-gray-500">У вас нет прав для просмотра отчётов</p>
          </div>
        );
      case 'settings':
        return (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900">Настройки</h3>
              </div>
              <div className="p-6">
                {supervisor && (
                  <div className="space-y-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Имя</label>
                        <p className="mt-1 text-sm text-gray-900">{supervisor.name}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Email</label>
                        <p className="mt-1 text-sm text-gray-900">{supervisor.email}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Роль</label>
                        <p className="mt-1 text-sm text-gray-900">{supervisor.role}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Отдел</label>
                        <p className="mt-1 text-sm text-gray-900">{supervisor.department}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Размер команды</label>
                        <p className="mt-1 text-sm text-gray-900">{supervisor.teamSize} сотрудников</p>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-3">Права доступа</label>
                      <div className="space-y-2">
                        {supervisor.permissions.map((permission) => (
                          <div key={permission} className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                            <span className="text-sm text-gray-700">
                              {translations.permissions[permission as keyof typeof translations.permissions]}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        );
      default:
        return <TeamManagementDashboard supervisorId={supervisorId} />;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                  <Shield className="h-6 w-6 text-white" />
                </div>
                <h1 className="text-xl font-semibold text-gray-900">
                  {translations.title}
                </h1>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              {supervisor && (
                <div className="text-sm text-gray-600">
                  <span className="font-medium">
                    {translations.greeting}, {supervisor.name}!
                  </span>
                  <div className="text-xs text-gray-500">
                    {supervisor.department} • {supervisor.teamSize} сотрудников
                  </div>
                </div>
              )}
              
              <button
                onClick={handleLogout}
                className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <LogOut className="h-4 w-4" />
                {translations.navigation.logout}
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {Object.entries(translations.navigation).filter(([key]) => 
              !['logout'].includes(key)
            ).map(([key, label]) => {
              // Check permissions for certain tabs
              if (key === 'approvals' && !hasPermission('approve_requests')) return null;
              if (key === 'schedule' && !hasPermission('manage_schedules')) return null;
              if (key === 'reports' && !hasPermission('view_reports')) return null;
              
              return (
                <button
                  key={key}
                  onClick={() => setActiveTab(key as any)}
                  className={`flex items-center gap-2 px-3 py-4 text-sm font-medium border-b-2 transition-colors ${
                    activeTab === key
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {getTabIcon(key)}
                  {label}
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {renderTabContent()}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-4 text-center text-sm text-gray-500">
            © 2025 WFM System. Все права защищены.
          </div>
        </div>
      </footer>
    </div>
  );
};

export default SupervisorPortal;