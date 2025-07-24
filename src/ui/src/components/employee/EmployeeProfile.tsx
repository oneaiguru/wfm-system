import React, { useState, useEffect } from 'react';
import { User, Mail, Calendar, MapPin, Edit, AlertCircle, UserCheck, Clock } from 'lucide-react';

// API Response type based on I's /employees/me endpoint
interface ApiEmployee {
  id: number;
  username: string;
  full_name: string;
  email: string;
  employee_number: string;
  hire_date: string;
  department: string;
  position: string;
  role: string;
  skills: string[];
}

export interface EmployeeProfileProps {
  employeeId: string;
  onEdit?: () => void;
}

const EmployeeProfile: React.FC<EmployeeProfileProps> = ({ employeeId, onEdit }) => {
  const [employee, setEmployee] = useState<ApiEmployee | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

  useEffect(() => {
    fetchEmployee();
  }, [employeeId]);

  const fetchEmployee = async () => {
    setIsLoading(true);
    setError('');

    try {
      // Use I's verified current employee endpoint
      console.log(`[EMPLOYEE PROFILE] Fetching current employee from: ${API_BASE_URL}/employees/me`);
      const token = localStorage.getItem('authToken');
      
      const response = await fetch(`${API_BASE_URL}/employees/me`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Employee not found`);
      }

      const employeeData = await response.json();
      console.log('[EMPLOYEE PROFILE] Employee data received:', employeeData);
      
      setEmployee(employeeData);
    } catch (err) {
      console.error('[EMPLOYEE PROFILE] Error fetching employee:', err);
      setError(err instanceof Error ? err.message : 'Failed to load employee');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString: string | null): string => {
    if (!dateString) return 'Не указано';
    
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('ru-RU', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    } catch {
      return 'Неверная дата';
    }
  };

  const getStatusColor = (isActive: boolean): string => {
    return isActive ? 'text-green-600 bg-green-100' : 'text-red-600 bg-red-100';
  };

  const getStatusText = (isActive: boolean): string => {
    return isActive ? 'Активен' : 'Неактивен';
  };

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="animate-pulse">
            <div className="flex items-center space-x-4 mb-6">
              <div className="w-20 h-20 bg-gray-300 rounded-full"></div>
              <div className="flex-1">
                <div className="h-6 bg-gray-300 rounded w-1/3 mb-2"></div>
                <div className="h-4 bg-gray-300 rounded w-1/4"></div>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="h-32 bg-gray-300 rounded"></div>
              <div className="h-32 bg-gray-300 rounded"></div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">Ошибка загрузки</h3>
              <p className="text-gray-600 mb-4">{error}</p>
              <button
                onClick={fetchEmployee}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                Попробовать снова
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!employee) {
    return (
      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="text-center py-12">
            <User className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">Сотрудник не найден</h3>
            <p className="text-gray-600">Сотрудник с ID {employeeId} не существует</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-800 px-6 py-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-20 h-20 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
                <User className="h-10 w-10 text-white" />
              </div>
              <div className="text-white">
                <h1 className="text-2xl font-bold">
                  {employee.first_name} {employee.last_name}
                </h1>
                <p className="text-blue-100">
                  Код агента: {employee.agent_code}
                </p>
                <div className="mt-2">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(employee.is_active)}`}>
                    <UserCheck className="h-3 w-3 mr-1" />
                    {getStatusText(employee.is_active)}
                  </span>
                </div>
              </div>
            </div>
            {onEdit && (
              <button
                onClick={onEdit}
                className="flex items-center px-4 py-2 bg-white bg-opacity-20 text-white rounded-md hover:bg-opacity-30 focus:outline-none focus:ring-2 focus:ring-white focus:ring-opacity-50"
              >
                <Edit className="h-4 w-4 mr-2" />
                Редактировать
              </button>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Personal Information */}
            <div className="bg-gray-50 rounded-lg p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Личная информация
              </h2>
              <div className="space-y-4">
                <div className="flex items-center">
                  <User className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm text-gray-600">Полное имя</p>
                    <p className="font-medium text-gray-900">
                      {employee.first_name} {employee.last_name}
                    </p>
                  </div>
                </div>
                <div className="flex items-center">
                  <Mail className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm text-gray-600">Email</p>
                    <p className="font-medium text-gray-900">
                      {employee.email}
                    </p>
                  </div>
                </div>
                {employee.employee_id && (
                  <div className="flex items-center">
                    <UserCheck className="h-5 w-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm text-gray-600">ID сотрудника</p>
                      <p className="font-medium text-gray-900">
                        {employee.employee_id}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Work Information */}
            <div className="bg-gray-50 rounded-lg p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Рабочая информация
              </h2>
              <div className="space-y-4">
                {employee.primary_group_name && (
                  <div className="flex items-center">
                    <User className="h-5 w-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm text-gray-600">Основная группа</p>
                      <p className="font-medium text-gray-900">
                        {employee.primary_group_name}
                      </p>
                    </div>
                  </div>
                )}
                <div className="flex items-center">
                  <MapPin className="h-5 w-5 text-gray-400 mr-3" />
                  <div>
                    <p className="text-sm text-gray-600">Временная зона</p>
                    <p className="font-medium text-gray-900">
                      {employee.time_zone}
                    </p>
                  </div>
                </div>
                {employee.hire_date && (
                  <div className="flex items-center">
                    <Calendar className="h-5 w-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm text-gray-600">Дата найма</p>
                      <p className="font-medium text-gray-900">
                        {formatDate(employee.hire_date)}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Schedule Information */}
            {(employee.default_shift_start || employee.default_shift_end) && (
              <div className="bg-gray-50 rounded-lg p-6 md:col-span-2">
                <h2 className="text-lg font-semibold text-gray-900 mb-4">
                  График работы
                </h2>
                <div className="flex items-center space-x-6">
                  {employee.default_shift_start && (
                    <div className="flex items-center">
                      <Clock className="h-5 w-5 text-gray-400 mr-3" />
                      <div>
                        <p className="text-sm text-gray-600">Начало смены</p>
                        <p className="font-medium text-gray-900">
                          {employee.default_shift_start}
                        </p>
                      </div>
                    </div>
                  )}
                  {employee.default_shift_end && (
                    <div className="flex items-center">
                      <Clock className="h-5 w-5 text-gray-400 mr-3" />
                      <div>
                        <p className="text-sm text-gray-600">Конец смены</p>
                        <p className="font-medium text-gray-900">
                          {employee.default_shift_end}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeProfile;