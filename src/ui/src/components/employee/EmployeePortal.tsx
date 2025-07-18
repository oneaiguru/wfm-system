import React, { useState, useEffect } from 'react';
import { Calendar, FileText, User, BarChart3, Settings, LogOut, Home } from 'lucide-react';
import CalendarTab from './CalendarTab';
import RequestsTab from './RequestsTab';
import PersonalDashboard from '../../modules/employee-portal/components/dashboard/PersonalDashboard';
import PersonalSchedule from '../../modules/employee-portal/components/schedule/PersonalSchedule';
import { realAuthService } from '../../services/realAuthService';

interface EmployeePortalProps {
  employeeId: string;
}

interface Employee {
  id: string;
  name: string;
  email: string;
  role: string;
  department: string;
}

// Russian translations per BDD spec
const translations = {
  title: 'Личный кабинет сотрудника',
  greeting: 'Здравствуйте',
  navigation: {
    dashboard: 'Домашняя страница',
    calendar: 'Календарь',
    requests: 'Заявки',
    profile: 'Мой профиль',
    schedule: 'График работы',
    settings: 'Настройки',
    logout: 'Выход из системы'
  },
  welcome: {
    title: 'Добро пожаловать в систему WFM',
    subtitle: 'Управляйте своим рабочим временем и заявками'
  }
};

const EmployeePortal: React.FC<EmployeePortalProps> = ({ employeeId }) => {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'calendar' | 'requests' | 'profile' | 'schedule'>('dashboard');
  const [employee, setEmployee] = useState<Employee | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadEmployeeData();
  }, [employeeId]);

  const loadEmployeeData = async () => {
    try {
      // Try to get employee data from auth service first
      const currentUser = realAuthService.getCurrentUser();
      if (currentUser) {
        setEmployee({
          id: currentUser.id.toString(),
          name: currentUser.name,
          email: currentUser.email,
          role: currentUser.role,
          department: currentUser.department
        });
      } else {
        // Fallback to API call
        const response = await fetch(`${process.env.VITE_API_URL || 'http://localhost:8001/api/v1'}/employees/${employeeId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        });

        if (response.ok) {
          const employeeData = await response.json();
          setEmployee({
            id: employeeData.id,
            name: employeeData.name || employeeData.full_name,
            email: employeeData.email,
            role: employeeData.role || 'Сотрудник',
            department: employeeData.department || 'Отдел'
          });
        }
      }
    } catch (error) {
      console.error('Error loading employee data:', error);
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
      case 'calendar':
        return <Calendar className="h-5 w-5" />;
      case 'requests':
        return <FileText className="h-5 w-5" />;
      case 'profile':
        return <User className="h-5 w-5" />;
      case 'schedule':
        return <BarChart3 className="h-5 w-5" />;
      default:
        return <Home className="h-5 w-5" />;
    }
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <PersonalDashboard employeeId={employeeId} />;
      case 'calendar':
        return <CalendarTab employeeId={employeeId} />;
      case 'requests':
        return <RequestsTab employeeId={employeeId} />;
      case 'schedule':
        return <PersonalSchedule employeeId={employeeId} />;
      case 'profile':
        return (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h2 className="text-2xl font-semibold text-gray-900 mb-6">Мой профиль</h2>
              {employee && (
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Имя</label>
                      <p className="mt-1 text-sm text-gray-900">{employee.name}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Email</label>
                      <p className="mt-1 text-sm text-gray-900">{employee.email}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Роль</label>
                      <p className="mt-1 text-sm text-gray-900">{employee.role}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Отдел</label>
                      <p className="mt-1 text-sm text-gray-900">{employee.department}</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        );
      default:
        return <PersonalDashboard employeeId={employeeId} />;
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
    <div className="min-h-screen bg-gray-50" data-testid="employee-portal">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-lg">WFM</span>
                </div>
                <h1 className="text-xl font-semibold text-gray-900">
                  {translations.title}
                </h1>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              {employee && (
                <div className="text-sm text-gray-600">
                  <span className="font-medium">
                    {translations.greeting}, {employee.name}!
                  </span>
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
              !['settings', 'logout'].includes(key)
            ).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setActiveTab(key as any)}
                className={`flex items-center gap-2 px-3 py-4 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === key
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
                data-testid={`nav-${key}`}
              >
                {getTabIcon(key)}
                {label}
              </button>
            ))}
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

export default EmployeePortal;