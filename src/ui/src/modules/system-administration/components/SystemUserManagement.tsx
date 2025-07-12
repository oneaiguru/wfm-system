import React, { useState, useEffect } from 'react';
import { Search, Filter, Download, Upload, Users, Grid, List, RefreshCw, Settings, Shield, Key } from 'lucide-react';

// BDD: User account management interfaces - Adapted from EmployeeListContainer
// Based on: 18-system-administration-configuration.feature

interface SystemUser {
  id: string;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'supervisor' | 'agent' | 'readonly';
  permissions: string[];
  lastLogin: Date | null;
  isActive: boolean;
  groups: string[];
  department: string;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  failedLoginAttempts: number;
  accountLocked: boolean;
  passwordExpiry: Date;
  mfaEnabled: boolean;
}

interface UserFilters {
  search: string;
  role: string;
  department: string;
  status: string;
  group: string;
  sortBy: 'username' | 'role' | 'department' | 'lastLogin' | 'createdAt';
  sortOrder: 'asc' | 'desc';
  showInactive: boolean;
}

interface UserStats {
  total: number;
  admins: number;
  supervisors: number;
  agents: number;
  readonly: number;
  active: number;
  locked: number;
}

const SystemUserManagement: React.FC = () => {
  const [users, setUsers] = useState<SystemUser[]>([]);
  const [filteredUsers, setFilteredUsers] = useState<SystemUser[]>([]);
  const [filters, setFilters] = useState<UserFilters>({
    search: '',
    role: '',
    department: '',
    status: '',
    group: '',
    sortBy: 'username',
    sortOrder: 'asc',
    showInactive: false
  });
  const [stats, setStats] = useState<UserStats>({
    total: 0,
    admins: 0,
    supervisors: 0,
    agents: 0,
    readonly: 0,
    active: 0,
    locked: 0
  });
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');

  // BDD: Mock system users data generation
  useEffect(() => {
    const mockUsers: SystemUser[] = [
      {
        id: 'usr_001',
        username: 'admin',
        email: 'admin@technoservice.ru',
        firstName: 'Администратор',
        lastName: 'Системы',
        role: 'admin',
        permissions: ['system:admin', 'user:manage', 'config:edit', 'reports:view', 'backup:create'],
        lastLogin: new Date('2024-07-15T08:30:00Z'),
        isActive: true,
        groups: ['Administrators', 'IT Department'],
        department: 'IT',
        createdAt: new Date('2024-01-01T00:00:00Z'),
        updatedAt: new Date(),
        createdBy: 'system',
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordExpiry: new Date('2024-12-31T23:59:59Z'),
        mfaEnabled: true
      },
      {
        id: 'usr_002',
        username: 'supervisor1',
        email: 'anna.petrova@technoservice.ru',
        firstName: 'Анна',
        lastName: 'Петрова',
        role: 'supervisor',
        permissions: ['team:manage', 'schedule:edit', 'reports:view', 'employee:view'],
        lastLogin: new Date('2024-07-15T09:15:00Z'),
        isActive: true,
        groups: ['Supervisors', 'Support Team'],
        department: 'Техподдержка',
        createdAt: new Date('2024-02-15T00:00:00Z'),
        updatedAt: new Date(),
        createdBy: 'admin',
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordExpiry: new Date('2024-08-15T23:59:59Z'),
        mfaEnabled: true
      },
      {
        id: 'usr_003',
        username: 'agent001',
        email: 'mikhail.volkov@technoservice.ru',
        firstName: 'Михаил',
        lastName: 'Волков',
        role: 'agent',
        permissions: ['schedule:view', 'request:create', 'profile:edit'],
        lastLogin: new Date('2024-07-14T17:45:00Z'),
        isActive: true,
        groups: ['Agents', 'Sales Team'],
        department: 'Продажи',
        createdAt: new Date('2024-03-01T00:00:00Z'),
        updatedAt: new Date(),
        createdBy: 'supervisor1',
        failedLoginAttempts: 1,
        accountLocked: false,
        passwordExpiry: new Date('2024-09-01T23:59:59Z'),
        mfaEnabled: false
      },
      {
        id: 'usr_004',
        username: 'readonly_audit',
        email: 'auditor@technoservice.ru',
        firstName: 'Аудитор',
        lastName: 'Системы',
        role: 'readonly',
        permissions: ['reports:view', 'audit:view'],
        lastLogin: new Date('2024-07-10T14:20:00Z'),
        isActive: true,
        groups: ['Auditors'],
        department: 'Безопасность',
        createdAt: new Date('2024-01-15T00:00:00Z'),
        updatedAt: new Date(),
        createdBy: 'admin',
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordExpiry: new Date('2024-12-31T23:59:59Z'),
        mfaEnabled: true
      },
      {
        id: 'usr_005',
        username: 'temp_user',
        email: 'temp@technoservice.ru',
        firstName: 'Временный',
        lastName: 'Пользователь',
        role: 'agent',
        permissions: ['schedule:view'],
        lastLogin: null,
        isActive: false,
        groups: [],
        department: 'Временные',
        createdAt: new Date('2024-07-01T00:00:00Z'),
        updatedAt: new Date(),
        createdBy: 'admin',
        failedLoginAttempts: 5,
        accountLocked: true,
        passwordExpiry: new Date('2024-07-31T23:59:59Z'),
        mfaEnabled: false
      }
    ];

    setUsers(mockUsers);
    setFilteredUsers(mockUsers);

    // Calculate stats
    const statsData = mockUsers.reduce((acc, user) => {
      acc.total++;
      acc[user.role + 's' as keyof UserStats]++;
      if (user.isActive) acc.active++;
      if (user.accountLocked) acc.locked++;
      return acc;
    }, { total: 0, admins: 0, supervisors: 0, agents: 0, readonly: 0, active: 0, locked: 0 });

    setStats(statsData);
  }, []);

  // Real-time update simulation
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  // Filter users
  useEffect(() => {
    let filtered = [...users];

    if (filters.search) {
      filtered = filtered.filter(user =>
        user.username.toLowerCase().includes(filters.search.toLowerCase()) ||
        user.firstName.toLowerCase().includes(filters.search.toLowerCase()) ||
        user.lastName.toLowerCase().includes(filters.search.toLowerCase()) ||
        user.email.toLowerCase().includes(filters.search.toLowerCase())
      );
    }

    if (filters.role) {
      filtered = filtered.filter(user => user.role === filters.role);
    }

    if (filters.department) {
      filtered = filtered.filter(user => user.department === filters.department);
    }

    if (filters.status) {
      if (filters.status === 'active') {
        filtered = filtered.filter(user => user.isActive && !user.accountLocked);
      } else if (filters.status === 'locked') {
        filtered = filtered.filter(user => user.accountLocked);
      } else if (filters.status === 'inactive') {
        filtered = filtered.filter(user => !user.isActive);
      }
    }

    if (!filters.showInactive) {
      filtered = filtered.filter(user => user.isActive);
    }

    // Sort
    filtered.sort((a, b) => {
      let aValue: any, bValue: any;
      
      switch (filters.sortBy) {
        case 'username':
          aValue = a.username;
          bValue = b.username;
          break;
        case 'role':
          aValue = a.role;
          bValue = b.role;
          break;
        case 'department':
          aValue = a.department;
          bValue = b.department;
          break;
        case 'lastLogin':
          aValue = a.lastLogin || new Date(0);
          bValue = b.lastLogin || new Date(0);
          break;
        case 'createdAt':
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        default:
          aValue = a.username;
          bValue = b.username;
      }

      if (filters.sortOrder === 'desc') {
        return aValue > bValue ? -1 : 1;
      }
      return aValue < bValue ? -1 : 1;
    });

    setFilteredUsers(filtered);
  }, [users, filters]);

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return 'bg-red-100 text-red-800';
      case 'supervisor': return 'bg-blue-100 text-blue-800';
      case 'agent': return 'bg-green-100 text-green-800';
      case 'readonly': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusColor = (user: SystemUser) => {
    if (user.accountLocked) return 'bg-red-100 text-red-800';
    if (!user.isActive) return 'bg-gray-100 text-gray-800';
    return 'bg-green-100 text-green-800';
  };

  const getStatusText = (user: SystemUser) => {
    if (user.accountLocked) return 'Заблокирован';
    if (!user.isActive) return 'Неактивен';
    return 'Активен';
  };

  const getRoleText = (role: string) => {
    switch (role) {
      case 'admin': return 'Администратор';
      case 'supervisor': return 'Супервайзер';
      case 'agent': return 'Агент';
      case 'readonly': return 'Только чтение';
      default: return role;
    }
  };

  const handleSelectUser = (userId: string) => {
    setSelectedUsers(prev =>
      prev.includes(userId)
        ? prev.filter(id => id !== userId)
        : [...prev, userId]
    );
  };

  const handleSelectAll = () => {
    setSelectedUsers(
      selectedUsers.length === filteredUsers.length
        ? []
        : filteredUsers.map(user => user.id)
    );
  };

  return (
    <div>
      {/* Header with Stats */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-900">Управление пользователями системы</h2>
          <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
            <span>Обновлено: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>

        {/* Quick Stats - BDD: Account statistics */}
        <div className="grid grid-cols-2 md:grid-cols-7 gap-4 mb-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
            <div className="text-sm text-gray-600">Всего</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-red-600">{stats.admins}</div>
            <div className="text-sm text-gray-600">Админы</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-blue-600">{stats.supervisors}</div>
            <div className="text-sm text-gray-600">Супервайзеры</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-green-600">{stats.agents}</div>
            <div className="text-sm text-gray-600">Агенты</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-600">{stats.readonly}</div>
            <div className="text-sm text-gray-600">Только чтение</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-green-600">{stats.active}</div>
            <div className="text-sm text-gray-600">Активные</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-red-600">{stats.locked}</div>
            <div className="text-sm text-gray-600">Заблокированные</div>
          </div>
        </div>
      </div>

      {/* Filters and Actions - BDD: User filtering and management */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Поиск пользователей..."
                value={filters.search}
                onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filters.role}
              onChange={(e) => setFilters(prev => ({ ...prev, role: e.target.value }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Все роли</option>
              <option value="admin">Администратор</option>
              <option value="supervisor">Супервайзер</option>
              <option value="agent">Агент</option>
              <option value="readonly">Только чтение</option>
            </select>

            <select
              value={filters.status}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Все статусы</option>
              <option value="active">Активные</option>
              <option value="locked">Заблокированные</option>
              <option value="inactive">Неактивные</option>
            </select>
          </div>

          <div className="flex items-center space-x-2">
            {selectedUsers.length > 0 && (
              <span className="text-sm text-gray-600">
                Выбрано: {selectedUsers.length}
              </span>
            )}
            <button className="flex items-center px-3 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
              <Users className="h-4 w-4 mr-2" />
              Создать пользователя
            </button>
            <button className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
              <Download className="h-4 w-4 mr-2" />
              Экспорт
            </button>
          </div>
        </div>
      </div>

      {/* User List - BDD: User account listing with permissions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left">
                  <input
                    type="checkbox"
                    checked={selectedUsers.length === filteredUsers.length}
                    onChange={handleSelectAll}
                    className="rounded"
                  />
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Пользователь
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Роль
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Отдел
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Статус
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Последний вход
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Безопасность
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Действия
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <input
                      type="checkbox"
                      checked={selectedUsers.includes(user.id)}
                      onChange={() => handleSelectUser(user.id)}
                      className="rounded"
                    />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {user.firstName} {user.lastName}
                      </div>
                      <div className="text-sm text-gray-500">@{user.username}</div>
                      <div className="text-sm text-gray-500">{user.email}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getRoleColor(user.role)}`}>
                      {getRoleText(user.role)}
                    </span>
                    <div className="text-xs text-gray-500 mt-1">
                      {user.permissions.length} разрешений
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{user.department}</div>
                    <div className="text-sm text-gray-500">
                      {user.groups.length > 0 ? user.groups.join(', ') : 'Нет групп'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(user)}`}>
                      {getStatusText(user)}
                    </span>
                    {user.failedLoginAttempts > 0 && (
                      <div className="text-xs text-red-600 mt-1">
                        Ошибок входа: {user.failedLoginAttempts}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {user.lastLogin ? 
                      user.lastLogin.toLocaleString('ru-RU') : 
                      'Никогда'
                    }
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      {user.mfaEnabled ? (
                        <Shield className="h-4 w-4 text-green-600" title="MFA включен" />
                      ) : (
                        <Shield className="h-4 w-4 text-red-600" title="MFA отключен" />
                      )}
                      <Key className="h-4 w-4 text-gray-400" title="Пароль" />
                    </div>
                    <div className="text-xs text-gray-500">
                      Истекает: {user.passwordExpiry.toLocaleDateString('ru-RU')}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button className="text-blue-600 hover:text-blue-900 mr-3">
                      Редактировать
                    </button>
                    <button className="text-red-600 hover:text-red-900">
                      {user.accountLocked ? 'Разблокировать' : 'Заблокировать'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default SystemUserManagement;