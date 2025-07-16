import React, { useState, useEffect } from 'react';
import { User, Shield, Save, Search, Edit, Eye, Key, CheckCircle, AlertCircle, Loader2, UserCheck, Lock, Unlock } from 'lucide-react';

interface Permission {
  id: string;
  module: string;
  action: string;
  description: string;
  category: 'read' | 'write' | 'admin';
}

interface UserPermission {
  userId: string;
  permissions: string[];
  role: string;
  lastUpdated: string;
  isActive: boolean;
}

interface Employee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}

const UserPermissions: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [userPermissions, setUserPermissions] = useState<UserPermission[]>([]);
  const [selectedUser, setSelectedUser] = useState<Employee | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterRole, setFilterRole] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

  // Initialize permissions
  const initializePermissions = (): Permission[] => {
    return [
      { id: 'emp_read', module: 'employees', action: 'read', description: 'Просмотр сотрудников', category: 'read' },
      { id: 'emp_write', module: 'employees', action: 'write', description: 'Редактирование сотрудников', category: 'write' },
      { id: 'emp_delete', module: 'employees', action: 'delete', description: 'Удаление сотрудников', category: 'admin' },
      { id: 'schedule_read', module: 'schedule', action: 'read', description: 'Просмотр расписания', category: 'read' },
      { id: 'schedule_write', module: 'schedule', action: 'write', description: 'Создание и редактирование расписания', category: 'write' },
      { id: 'schedule_publish', module: 'schedule', action: 'publish', description: 'Публикация расписания', category: 'admin' },
      { id: 'reports_read', module: 'reports', action: 'read', description: 'Просмотр отчетов', category: 'read' },
      { id: 'reports_generate', module: 'reports', action: 'generate', description: 'Генерация отчетов', category: 'write' },
      { id: 'reports_export', module: 'reports', action: 'export', description: 'Экспорт отчетов', category: 'write' },
      { id: 'forecasting_read', module: 'forecasting', action: 'read', description: 'Просмотр прогнозов', category: 'read' },
      { id: 'forecasting_write', module: 'forecasting', action: 'write', description: 'Создание прогнозов', category: 'write' },
      { id: 'admin_users', module: 'admin', action: 'users', description: 'Управление пользователями', category: 'admin' },
      { id: 'admin_system', module: 'admin', action: 'system', description: 'Системные настройки', category: 'admin' },
      { id: 'admin_audit', module: 'admin', action: 'audit', description: 'Просмотр журнала аудита', category: 'admin' }
    ];
  };

  // Generate user permissions based on employee data
  const generateUserPermissions = (employeeData: Employee[]): UserPermission[] => {
    return employeeData.map(emp => {
      let role = 'operator';
      let permissions: string[] = ['emp_read', 'schedule_read', 'reports_read'];

      // Assign roles and permissions based on email/name patterns
      if (emp.email?.includes('admin')) {
        role = 'admin';
        permissions = [
          'emp_read', 'emp_write', 'emp_delete',
          'schedule_read', 'schedule_write', 'schedule_publish',
          'reports_read', 'reports_generate', 'reports_export',
          'forecasting_read', 'forecasting_write',
          'admin_users', 'admin_system', 'admin_audit'
        ];
      } else if (emp.first_name?.toLowerCase().includes('manager') || emp.email?.includes('manager')) {
        role = 'manager';
        permissions = [
          'emp_read', 'emp_write',
          'schedule_read', 'schedule_write', 'schedule_publish',
          'reports_read', 'reports_generate', 'reports_export',
          'forecasting_read', 'forecasting_write'
        ];
      } else if (emp.first_name?.toLowerCase().includes('supervisor')) {
        role = 'supervisor';
        permissions = [
          'emp_read',
          'schedule_read', 'schedule_write',
          'reports_read', 'reports_generate',
          'forecasting_read'
        ];
      }

      return {
        userId: emp.id.toString(),
        permissions,
        role,
        lastUpdated: new Date().toISOString(),
        isActive: emp.is_active
      };
    });
  };

  // Fetch employees data
  const fetchEmployees = async () => {
    try {
      console.log(`[USER PERMISSIONS] Fetching employees from: ${API_BASE_URL}/employees/list`);
      
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeData = await response.json();
      console.log('[USER PERMISSIONS] Employees fetched:', employeeData);
      
      setEmployees(employeeData);
      setPermissions(initializePermissions());
      setUserPermissions(generateUserPermissions(employeeData));
      
    } catch (err) {
      console.error('[USER PERMISSIONS] Error fetching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      // Set defaults even on error
      setEmployees([]);
      setPermissions(initializePermissions());
      setUserPermissions([]);
    }
  };

  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true);
      setError('');
      
      await fetchEmployees();
      
      setIsLoading(false);
    };

    loadData();
  }, []);

  // Save user permissions
  const saveUserPermissions = async (userId: string, newPermissions: string[]) => {
    setSaving(true);
    setError('');
    
    try {
      console.log(`[USER PERMISSIONS] Saving permissions for user ${userId}:`, newPermissions);
      
      // Use PUT endpoint to update employee permissions
      const response = await fetch(`${API_BASE_URL}/employees/${userId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          permissions: newPermissions,
          updated_at: new Date().toISOString()
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Failed to update permissions`);
      }

      // Update local state
      setUserPermissions(prev => prev.map(up => 
        up.userId === userId 
          ? { ...up, permissions: newPermissions, lastUpdated: new Date().toISOString() }
          : up
      ));
      
      setSuccess('Разрешения пользователя успешно обновлены');
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
      
    } catch (err) {
      console.error('[USER PERMISSIONS] Error saving permissions:', err);
      setError(err instanceof Error ? err.message : 'Ошибка сохранения разрешений');
    } finally {
      setSaving(false);
    }
  };

  const getUserPermissions = (userId: string): UserPermission | undefined => {
    return userPermissions.find(up => up.userId === userId);
  };

  const handlePermissionToggle = (userId: string, permissionId: string) => {
    const userPerms = getUserPermissions(userId);
    if (!userPerms) return;

    const hasPermission = userPerms.permissions.includes(permissionId);
    const newPermissions = hasPermission
      ? userPerms.permissions.filter(p => p !== permissionId)
      : [...userPerms.permissions, permissionId];

    // Update local state immediately for UI responsiveness
    setUserPermissions(prev => prev.map(up => 
      up.userId === userId 
        ? { ...up, permissions: newPermissions }
        : up
    ));
  };

  const handleSaveUserPermissions = async (userId: string) => {
    const userPerms = getUserPermissions(userId);
    if (!userPerms) return;
    
    await saveUserPermissions(userId, userPerms.permissions);
  };

  const getPermissionCategory = (category: string) => {
    switch (category) {
      case 'read': return { icon: Eye, color: 'text-blue-600', bg: 'bg-blue-100', label: 'Чтение' };
      case 'write': return { icon: Edit, color: 'text-green-600', bg: 'bg-green-100', label: 'Запись' };
      case 'admin': return { icon: Shield, color: 'text-red-600', bg: 'bg-red-100', label: 'Админ' };
      default: return { icon: Key, color: 'text-gray-600', bg: 'bg-gray-100', label: 'Прочее' };
    }
  };

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case 'admin': return 'bg-red-100 text-red-800';
      case 'manager': return 'bg-purple-100 text-purple-800';
      case 'supervisor': return 'bg-blue-100 text-blue-800';
      case 'operator': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  // Filter employees
  const filteredEmployees = employees.filter(emp => {
    const userPerms = getUserPermissions(emp.id.toString());
    
    const matchesSearch = searchQuery === '' || 
      emp.first_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.last_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.agent_code.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesRole = filterRole === 'all' || userPerms?.role === filterRole;
    const matchesStatus = filterStatus === 'all' || 
      (filterStatus === 'active' && emp.is_active) ||
      (filterStatus === 'inactive' && !emp.is_active);
    
    return matchesSearch && matchesRole && matchesStatus;
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Загрузка разрешений пользователей...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Разрешения пользователей</h1>
            <p className="text-gray-600 mt-1">Управление индивидуальными разрешениями сотрудников</p>
          </div>
        </div>
      </div>

      {/* Status Messages */}
      {error && (
        <div className="mx-6 mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <span className="text-red-700">{error}</span>
          </div>
        </div>
      )}

      {success && (
        <div className="mx-6 mt-4 p-4 bg-green-50 border border-green-200 rounded-md">
          <div className="flex items-center">
            <CheckCircle className="h-5 w-5 text-green-500 mr-2" />
            <span className="text-green-700">{success}</span>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
          <div className="lg:col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">Поиск пользователей</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                placeholder="Поиск по имени, email или коду..."
              />
            </div>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Роль</label>
            <select
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            >
              <option value="all">Все роли</option>
              <option value="admin">Администратор</option>
              <option value="manager">Менеджер</option>
              <option value="supervisor">Супервайзер</option>
              <option value="operator">Оператор</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Статус</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            >
              <option value="all">Все статусы</option>
              <option value="active">Активные</option>
              <option value="inactive">Неактивные</option>
            </select>
          </div>
        </div>
        
        <div className="mt-4 text-sm text-gray-600">
          Найдено пользователей: {filteredEmployees.length} из {employees.length}
        </div>
      </div>

      {/* User List with Permissions */}
      <div className="divide-y divide-gray-200">
        {filteredEmployees.map(employee => {
          const userPerms = getUserPermissions(employee.id.toString());
          if (!userPerms) return null;

          return (
            <div key={employee.id} className="p-6">
              {/* User Header */}
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mr-4">
                    <User className="h-6 w-6 text-blue-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">
                      {employee.first_name} {employee.last_name}
                    </h3>
                    <div className="flex items-center space-x-4 text-sm text-gray-600">
                      <span>{employee.email || employee.agent_code}</span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getRoleBadgeColor(userPerms.role)}`}>
                        {userPerms.role}
                      </span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        employee.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {employee.is_active ? (
                          <>
                            <Unlock className="h-3 w-3 mr-1" />
                            Активен
                          </>
                        ) : (
                          <>
                            <Lock className="h-3 w-3 mr-1" />
                            Заблокирован
                          </>
                        )}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">
                      Последнее обновление: {new Date(userPerms.lastUpdated).toLocaleString('ru-RU')}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => handleSaveUserPermissions(employee.id.toString())}
                  disabled={isSaving}
                  className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                >
                  {isSaving ? (
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4 mr-2" />
                  )}
                  Сохранить
                </button>
              </div>

              {/* Permissions Grid */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                {['read', 'write', 'admin'].map(category => {
                  const categoryPerms = permissions.filter(p => p.category === category);
                  const categoryInfo = getPermissionCategory(category);
                  
                  return (
                    <div key={category} className="border border-gray-200 rounded-lg">
                      <div className={`px-4 py-3 border-b border-gray-200 ${categoryInfo.bg}`}>
                        <div className="flex items-center">
                          <categoryInfo.icon className={`h-5 w-5 ${categoryInfo.color} mr-2`} />
                          <h4 className={`font-medium ${categoryInfo.color}`}>
                            {categoryInfo.label} ({categoryPerms.filter(p => userPerms.permissions.includes(p.id)).length}/{categoryPerms.length})
                          </h4>
                        </div>
                      </div>
                      <div className="p-4 space-y-3">
                        {categoryPerms.map(permission => {
                          const hasPermission = userPerms.permissions.includes(permission.id);
                          
                          return (
                            <div key={permission.id} className="flex items-center">
                              <input
                                type="checkbox"
                                id={`${employee.id}_${permission.id}`}
                                checked={hasPermission}
                                onChange={() => handlePermissionToggle(employee.id.toString(), permission.id)}
                                disabled={!employee.is_active}
                                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mr-3 disabled:opacity-50"
                              />
                              <label 
                                htmlFor={`${employee.id}_${permission.id}`}
                                className={`text-sm cursor-pointer ${
                                  employee.is_active ? 'text-gray-900' : 'text-gray-500'
                                }`}
                              >
                                <div>{permission.description}</div>
                                <div className="text-xs text-gray-500">
                                  {permission.module}.{permission.action}
                                </div>
                              </label>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Permission Summary */}
              <div className="mt-4 p-3 bg-gray-50 rounded-md">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600">
                    Активных разрешений: {userPerms.permissions.length} из {permissions.length}
                  </span>
                  <div className="flex items-center space-x-4">
                    <span className="flex items-center">
                      <div className="w-2 h-2 bg-blue-500 rounded-full mr-2" />
                      Чтение: {permissions.filter(p => p.category === 'read' && userPerms.permissions.includes(p.id)).length}
                    </span>
                    <span className="flex items-center">
                      <div className="w-2 h-2 bg-green-500 rounded-full mr-2" />
                      Запись: {permissions.filter(p => p.category === 'write' && userPerms.permissions.includes(p.id)).length}
                    </span>
                    <span className="flex items-center">
                      <div className="w-2 h-2 bg-red-500 rounded-full mr-2" />
                      Админ: {permissions.filter(p => p.category === 'admin' && userPerms.permissions.includes(p.id)).length}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Empty State */}
      {filteredEmployees.length === 0 && !isLoading && (
        <div className="text-center py-12">
          <UserCheck className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Пользователи не найдены</h3>
          <p className="text-gray-600">Попробуйте изменить фильтры поиска</p>
        </div>
      )}
    </div>
  );
};

export default UserPermissions;