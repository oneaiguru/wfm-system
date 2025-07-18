import React, { useState, useEffect } from 'react';
import { Shield, Users, Loader2, AlertCircle } from 'lucide-react';
import Login from './Login';
import EmployeePortal from './employee/EmployeePortal';
import SupervisorPortal from './supervisor/SupervisorPortal';
import { realAuthService } from '../services/realAuthService';

interface User {
  id: string;
  name: string;
  email: string;
  role: 'employee' | 'supervisor' | 'admin';
  department: string;
}

interface MainAppProps {
  initialUser?: User;
}

// Russian translations per BDD spec
const translations = {
  loading: 'Загрузка...',
  error: 'Ошибка',
  unauthorized: 'Неавторизован',
  loginRequired: 'Требуется авторизация',
  invalidRole: 'Недопустимая роль пользователя',
  systemError: 'Системная ошибка',
  retry: 'Повторить попытку',
  roles: {
    employee: 'Сотрудник',
    supervisor: 'Руководитель',
    admin: 'Администратор'
  }
};

const MainApp: React.FC<MainAppProps> = ({ initialUser }) => {
  const [user, setUser] = useState<User | null>(initialUser || null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    if (!initialUser) {
      checkAuthentication();
    } else {
      setLoading(false);
      setAuthChecked(true);
    }
  }, [initialUser]);

  const checkAuthentication = async () => {
    try {
      setLoading(true);
      setError(null);

      // Check if user is authenticated
      const currentUser = realAuthService.getCurrentUser();
      const isAuthenticated = realAuthService.isAuthenticated();

      if (isAuthenticated && currentUser) {
        // Validate user data
        if (!currentUser.role || !['employee', 'supervisor', 'admin'].includes(currentUser.role)) {
          throw new Error('Invalid user role');
        }

        setUser({
          id: currentUser.id.toString(),
          name: currentUser.name,
          email: currentUser.email,
          role: currentUser.role as 'employee' | 'supervisor' | 'admin',
          department: currentUser.department
        });
      } else {
        // Clear any invalid auth state
        setUser(null);
      }
    } catch (error) {
      console.error('Authentication check failed:', error);
      setError('Ошибка проверки авторизации');
      setUser(null);
    } finally {
      setLoading(false);
      setAuthChecked(true);
    }
  };

  const handleLoginSuccess = (userData: any) => {
    try {
      // Validate login response
      if (!userData || !userData.role) {
        throw new Error('Invalid user data received');
      }

      const mappedUser: User = {
        id: userData.id?.toString() || userData.user_id?.toString(),
        name: userData.name || userData.full_name,
        email: userData.email,
        role: userData.role,
        department: userData.department || 'Не указан'
      };

      setUser(mappedUser);
      setError(null);
    } catch (error) {
      console.error('Login success handler error:', error);
      setError('Ошибка обработки данных пользователя');
    }
  };

  const handleLogout = () => {
    setUser(null);
    setError(null);
    // Login component will handle the actual logout
  };

  const renderUserPortal = () => {
    if (!user) return null;

    switch (user.role) {
      case 'employee':
        return <EmployeePortal employeeId={user.id} />;
      case 'supervisor':
        return <SupervisorPortal supervisorId={user.id} />;
      case 'admin':
        // Admin portal would go here
        return (
          <div className="min-h-screen bg-gray-50 flex items-center justify-center">
            <div className="bg-white rounded-lg shadow-sm p-8 max-w-md w-full mx-4">
              <div className="text-center">
                <Shield className="h-12 w-12 text-blue-600 mx-auto mb-4" />
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  Панель администратора
                </h2>
                <p className="text-gray-600 mb-6">
                  Функция в разработке
                </p>
                <button
                  onClick={handleLogout}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Выйти из системы
                </button>
              </div>
            </div>
          </div>
        );
      default:
        return (
          <div className="min-h-screen bg-gray-50 flex items-center justify-center">
            <div className="bg-white rounded-lg shadow-sm p-8 max-w-md w-full mx-4">
              <div className="text-center">
                <AlertCircle className="h-12 w-12 text-red-600 mx-auto mb-4" />
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  {translations.invalidRole}
                </h2>
                <p className="text-gray-600 mb-6">
                  Роль пользователя: {user.role}
                </p>
                <button
                  onClick={handleLogout}
                  className="w-full bg-red-600 text-white py-2 px-4 rounded-lg hover:bg-red-700 transition-colors"
                >
                  {translations.retry}
                </button>
              </div>
            </div>
          </div>
        );
    }
  };

  // Show loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-12 w-12 text-blue-600 mx-auto mb-4 animate-spin" />
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            {translations.loading}
          </h2>
          <p className="text-gray-600">
            Проверка авторизации...
          </p>
        </div>
      </div>
    );
  }

  // Show error state
  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white rounded-lg shadow-sm p-8 max-w-md w-full mx-4">
          <div className="text-center">
            <AlertCircle className="h-12 w-12 text-red-600 mx-auto mb-4" />
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              {translations.error}
            </h2>
            <p className="text-gray-600 mb-6">{error}</p>
            <button
              onClick={checkAuthentication}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors"
            >
              {translations.retry}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Show login if not authenticated
  if (!user && authChecked) {
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  // Show user portal
  return renderUserPortal();
};

export default MainApp;