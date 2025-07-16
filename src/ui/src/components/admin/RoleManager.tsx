import React, { useState, useEffect } from 'react';
import { Shield, Users, Edit, Save, Plus, Trash2, Eye, AlertCircle, CheckCircle, Loader2, UserCheck, Crown, Key } from 'lucide-react';

interface Role {
  id: string;
  name: string;
  description: string;
  permissions: string[];
  userCount: number;
  isSystem: boolean;
  createdAt: string;
  updatedAt: string;
}

interface Permission {
  id: string;
  module: string;
  action: string;
  description: string;
  category: 'read' | 'write' | 'admin';
}

interface Employee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
  role?: string;
  permissions?: string[];
}

const RoleManager: React.FC = () => {
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);
  const [editingRole, setEditingRole] = useState<Role | null>(null);
  const [showCreateRole, setShowCreateRole] = useState(false);
  const [activeTab, setActiveTab] = useState('roles');

  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

  // Initialize default roles and permissions
  const initializeRolesAndPermissions = (employeeData: Employee[]) => {
    const defaultPermissions: Permission[] = [
      { id: 'emp_read', module: 'employees', action: 'read', description: 'Просмотр сотрудников', category: 'read' },
      { id: 'emp_write', module: 'employees', action: 'write', description: 'Редактирование сотрудников', category: 'write' },
      { id: 'emp_delete', module: 'employees', action: 'delete', description: 'Удаление сотрудников', category: 'admin' },
      { id: 'schedule_read', module: 'schedule', action: 'read', description: 'Просмотр расписания', category: 'read' },
      { id: 'schedule_write', module: 'schedule', action: 'write', description: 'Редактирование расписания', category: 'write' },
      { id: 'reports_read', module: 'reports', action: 'read', description: 'Просмотр отчетов', category: 'read' },
      { id: 'reports_generate', module: 'reports', action: 'generate', description: 'Генерация отчетов', category: 'write' },
      { id: 'admin_users', module: 'admin', action: 'users', description: 'Управление пользователями', category: 'admin' },
      { id: 'admin_system', module: 'admin', action: 'system', description: 'Администрирование системы', category: 'admin' }
    ];

    const defaultRoles: Role[] = [
      {
        id: 'admin',
        name: 'Администратор',
        description: 'Полные права доступа к системе',
        permissions: defaultPermissions.map(p => p.id),
        userCount: employeeData.filter(emp => emp.email?.includes('admin')).length,
        isSystem: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        id: 'manager',
        name: 'Менеджер',
        description: 'Управление сотрудниками и расписанием',
        permissions: ['emp_read', 'emp_write', 'schedule_read', 'schedule_write', 'reports_read', 'reports_generate'],
        userCount: employeeData.filter(emp => emp.first_name?.toLowerCase().includes('manager')).length,
        isSystem: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        id: 'operator',
        name: 'Оператор',
        description: 'Базовые права для операторов',
        permissions: ['emp_read', 'schedule_read', 'reports_read'],
        userCount: employeeData.filter(emp => !emp.email?.includes('admin') && !emp.first_name?.toLowerCase().includes('manager')).length,
        isSystem: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];

    setPermissions(defaultPermissions);
    setRoles(defaultRoles);
  };

  // Fetch employees data
  const fetchEmployees = async () => {
    try {
      console.log(`[ROLE MANAGER] Fetching employees from: ${API_BASE_URL}/employees/list`);
      
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeData = await response.json();
      console.log('[ROLE MANAGER] Employees fetched:', employeeData);
      
      // Assign mock roles to employees for demonstration
      const employeesWithRoles = employeeData.map((emp: Employee) => ({
        ...emp,
        role: emp.email?.includes('admin') ? 'admin' : 
              emp.first_name?.toLowerCase().includes('manager') ? 'manager' : 'operator',
        permissions: emp.email?.includes('admin') ? 
          ['emp_read', 'emp_write', 'emp_delete', 'schedule_read', 'schedule_write', 'reports_read', 'reports_generate', 'admin_users', 'admin_system'] :
          emp.first_name?.toLowerCase().includes('manager') ?
          ['emp_read', 'emp_write', 'schedule_read', 'schedule_write', 'reports_read', 'reports_generate'] :
          ['emp_read', 'schedule_read', 'reports_read']
      }));
      
      setEmployees(employeesWithRoles);
      initializeRolesAndPermissions(employeesWithRoles);
      
    } catch (err) {
      console.error('[ROLE MANAGER] Error fetching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      // Set default data even on error
      setEmployees([]);
      initializeRolesAndPermissions([]);
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

  const handleCreateRole = () => {
    const newRole: Role = {
      id: `role_${Date.now()}`,
      name: '',
      description: '',
      permissions: [],
      userCount: 0,
      isSystem: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    setEditingRole(newRole);
    setShowCreateRole(true);
  };

  const handleEditRole = (role: Role) => {
    if (role.isSystem) {
      setError('Системные роли нельзя изменять');
      return;
    }
    setEditingRole({ ...role });
    setShowCreateRole(false);
  };

  const handleSaveRole = async () => {
    if (!editingRole) return;

    if (!editingRole.name.trim()) {
      setError('Название роли обязательно');
      return;
    }

    setSaving(true);
    setError('');
    
    try {
      console.log('[ROLE MANAGER] Saving role:', editingRole);
      
      // Simulate saving role
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      if (showCreateRole) {
        // Add new role
        setRoles(prev => [...prev, editingRole]);
        setSuccess('Роль успешно создана');
      } else {
        // Update existing role
        setRoles(prev => prev.map(role => 
          role.id === editingRole.id ? editingRole : role
        ));
        setSuccess('Роль успешно обновлена');
      }
      
      setEditingRole(null);
      setShowCreateRole(false);
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка сохранения роли');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteRole = async (roleId: string) => {
    const role = roles.find(r => r.id === roleId);
    if (!role) return;
    
    if (role.isSystem) {
      setError('Системные роли нельзя удалять');
      return;
    }

    if (role.userCount > 0) {
      setError('Нельзя удалить роль, назначенную пользователям');
      return;
    }

    if (!confirm(`Удалить роль "${role.name}"?`)) return;

    setSaving(true);
    setError('');
    
    try {
      console.log('[ROLE MANAGER] Deleting role:', roleId);
      
      // Simulate deleting role
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setRoles(prev => prev.filter(role => role.id !== roleId));
      setSuccess('Роль успешно удалена');
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка удаления роли');
    } finally {
      setSaving(false);
    }
  };

  const handlePermissionToggle = (permissionId: string) => {
    if (!editingRole) return;
    
    const hasPermission = editingRole.permissions.includes(permissionId);
    const newPermissions = hasPermission
      ? editingRole.permissions.filter(p => p !== permissionId)
      : [...editingRole.permissions, permissionId];
    
    setEditingRole({ ...editingRole, permissions: newPermissions });
  };

  const getPermissionCategory = (category: string) => {
    switch (category) {
      case 'read': return { icon: Eye, color: 'text-blue-600', bg: 'bg-blue-100' };
      case 'write': return { icon: Edit, color: 'text-green-600', bg: 'bg-green-100' };
      case 'admin': return { icon: Crown, color: 'text-red-600', bg: 'bg-red-100' };
      default: return { icon: Key, color: 'text-gray-600', bg: 'bg-gray-100' };
    }
  };

  const getUsersWithRole = (roleId: string) => {
    return employees.filter(emp => emp.role === roleId);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Загрузка ролей и разрешений...</p>
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
            <h1 className="text-2xl font-semibold text-gray-900">Управление ролями</h1>
            <p className="text-gray-600 mt-1">Настройка ролей и разрешений пользователей</p>
          </div>
          <button
            onClick={handleCreateRole}
            disabled={isSaving}
            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
          >
            <Plus className="h-4 w-4 mr-2" />
            Создать роль
          </button>
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

      {/* Tab Navigation */}
      <div className="px-6 pt-4">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('roles')}
              className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === 'roles'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Shield className="h-4 w-4" />
              <span>Роли</span>
            </button>
            <button
              onClick={() => setActiveTab('users')}
              className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === 'users'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Users className="h-4 w-4" />
              <span>Пользователи</span>
            </button>
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {activeTab === 'roles' && (
          <>
            {/* Roles List */}
            {!editingRole && (
              <div className="space-y-4">
                {roles.map(role => (
                  <div key={role.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3">
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                            role.isSystem ? 'bg-red-100' : 'bg-blue-100'
                          }`}>
                            {role.isSystem ? (
                              <Crown className={`h-5 w-5 ${role.isSystem ? 'text-red-600' : 'text-blue-600'}`} />
                            ) : (
                              <Shield className="h-5 w-5 text-blue-600" />
                            )}
                          </div>
                          <div>
                            <h3 className="text-lg font-medium text-gray-900">
                              {role.name}
                              {role.isSystem && (
                                <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                                  Системная
                                </span>
                              )}
                            </h3>
                            <p className="text-gray-600">{role.description}</p>
                            <div className="flex items-center space-x-4 mt-2 text-sm text-gray-500">
                              <span>{role.permissions.length} разрешений</span>
                              <span>{role.userCount} пользователей</span>
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => setSelectedRole(role)}
                          className="p-2 text-gray-400 hover:text-gray-600 focus:outline-none"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        {!role.isSystem && (
                          <>
                            <button
                              onClick={() => handleEditRole(role)}
                              disabled={isSaving}
                              className="p-2 text-gray-400 hover:text-blue-600 focus:outline-none disabled:opacity-50"
                            >
                              <Edit className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDeleteRole(role.id)}
                              disabled={isSaving || role.userCount > 0}
                              className="p-2 text-gray-400 hover:text-red-600 focus:outline-none disabled:opacity-50"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Role Editor */}
            {editingRole && (
              <div className="space-y-6">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-medium text-gray-900">
                    {showCreateRole ? 'Создание новой роли' : 'Редактирование роли'}
                  </h3>
                  <div className="flex items-center space-x-3">
                    <button
                      onClick={() => {
                        setEditingRole(null);
                        setShowCreateRole(false);
                        setError('');
                      }}
                      disabled={isSaving}
                      className="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                    >
                      Отмена
                    </button>
                    <button
                      onClick={handleSaveRole}
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
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Название роли *
                      </label>
                      <input
                        type="text"
                        value={editingRole.name}
                        onChange={(e) => setEditingRole({ ...editingRole, name: e.target.value })}
                        className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Введите название роли"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Описание
                      </label>
                      <textarea
                        value={editingRole.description}
                        onChange={(e) => setEditingRole({ ...editingRole, description: e.target.value })}
                        rows={3}
                        className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Введите описание роли"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Разрешения ({editingRole.permissions.length})
                    </label>
                    <div className="border border-gray-200 rounded-md max-h-96 overflow-y-auto">
                      {permissions.map(permission => {
                        const categoryInfo = getPermissionCategory(permission.category);
                        const isSelected = editingRole.permissions.includes(permission.id);
                        
                        return (
                          <div
                            key={permission.id}
                            onClick={() => handlePermissionToggle(permission.id)}
                            className={`p-3 border-b border-gray-100 cursor-pointer hover:bg-gray-50 ${
                              isSelected ? 'bg-blue-50 border-blue-200' : ''
                            }`}
                          >
                            <div className="flex items-center">
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => {}} // Handled by onClick
                                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mr-3"
                              />
                              <div className={`w-8 h-8 rounded-full flex items-center justify-center mr-3 ${categoryInfo.bg}`}>
                                <categoryInfo.icon className={`h-4 w-4 ${categoryInfo.color}`} />
                              </div>
                              <div className="flex-1">
                                <p className="text-sm font-medium text-gray-900">{permission.description}</p>
                                <p className="text-xs text-gray-500">{permission.module}.{permission.action}</p>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
        )}

        {activeTab === 'users' && (
          <div className="space-y-6">
            {roles.map(role => {
              const roleUsers = getUsersWithRole(role.id);
              return (
                <div key={role.id} className="border border-gray-200 rounded-lg">
                  <div className="px-4 py-3 bg-gray-50 border-b border-gray-200">
                    <div className="flex items-center">
                      <Shield className="h-5 w-5 text-blue-600 mr-3" />
                      <h3 className="text-lg font-medium text-gray-900">{role.name}</h3>
                      <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {roleUsers.length} пользователей
                      </span>
                    </div>
                  </div>
                  <div className="p-4">
                    {roleUsers.length > 0 ? (
                      <div className="space-y-3">
                        {roleUsers.map(user => (
                          <div key={user.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-md">
                            <div className="flex items-center">
                              <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                                <UserCheck className="h-4 w-4 text-blue-600" />
                              </div>
                              <div>
                                <p className="text-sm font-medium text-gray-900">
                                  {user.first_name} {user.last_name}
                                </p>
                                <p className="text-xs text-gray-500">
                                  {user.email || user.agent_code}
                                </p>
                              </div>
                            </div>
                            <div className="flex items-center">
                              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                user.is_active 
                                  ? 'bg-green-100 text-green-800' 
                                  : 'bg-red-100 text-red-800'
                              }`}>
                                {user.is_active ? 'Активен' : 'Неактивен'}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-gray-500 text-center py-4">Нет пользователей с этой ролью</p>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Role Details Modal */}
      {selectedRole && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-96 overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Детали роли</h3>
              <button
                onClick={() => setSelectedRole(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                ×
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-700">Название:</p>
                <p className="text-gray-900">{selectedRole.name}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-700">Описание:</p>
                <p className="text-gray-900">{selectedRole.description}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-700">Разрешения:</p>
                <div className="mt-2 space-y-2">
                  {selectedRole.permissions.map(permId => {
                    const permission = permissions.find(p => p.id === permId);
                    if (!permission) return null;
                    const categoryInfo = getPermissionCategory(permission.category);
                    
                    return (
                      <div key={permId} className="flex items-center">
                        <div className={`w-6 h-6 rounded-full flex items-center justify-center mr-2 ${categoryInfo.bg}`}>
                          <categoryInfo.icon className={`h-3 w-3 ${categoryInfo.color}`} />
                        </div>
                        <span className="text-sm text-gray-900">{permission.description}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default RoleManager;