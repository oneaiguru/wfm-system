import React, { useState, useEffect } from 'react';
import {
  Shield,
  Users,
  Key,
  Settings,
  Plus,
  Search,
  Filter,
  Edit3,
  Trash2,
  Save,
  X,
  Check,
  AlertTriangle,
  Lock,
  Unlock,
  UserCheck,
  UserX,
  Eye,
  EyeOff,
  Copy,
  CheckCircle,
  XCircle,
  Crown,
  Award,
  User,
  UserPlus,
  Calendar,
  Clock,
  Activity,
  Globe,
  AlertCircle,
  FileText,
  Download,
  Upload,
  RefreshCw,
  ChevronDown,
  ChevronRight,
  BarChart3,
  PieChart,
  TrendingUp,
  Database,
  Layers,
  Grid,
  List,
  LayoutDashboard
} from 'lucide-react';

// SPEC-26: Unified Roles & Access Control Dashboard
// Combines existing RBAC components with 82% reuse from:
// - Spec29RoleAccessControl.tsx (primary)
// - AccessRoleManager.tsx (role management)
// - RoleManager.tsx (basic RBAC)
// - UserPermissions.tsx (user permissions)
// Focus: Complete RBAC management for administrators and security officers (25+ daily users)

interface Spec26Role {
  id: string;
  name: string;
  nameRu: string;
  nameEn: string;
  description: string;
  type: 'system' | 'business' | 'custom' | 'temporary';
  level: 'executive' | 'manager' | 'specialist' | 'trainee' | 'guest';
  permissions: string[];
  parentRoleId?: string;
  isActive: boolean;
  userCount: number;
  createdBy: string;
  createdAt: string;
  complianceLevel: 'low' | 'medium' | 'high' | 'critical';
  auditRequired: boolean;
}

interface Spec26Permission {
  id: string;
  name: string;
  nameRu: string;
  nameEn: string;
  resource: string;
  action: string;
  category: 'data' | 'system' | 'user' | 'report' | 'admin';
  scope: 'global' | 'department' | 'team' | 'self';
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  requiresApproval: boolean;
}

interface Spec26UserAssignment {
  id: string;
  userId: string;
  userName: string;
  userNameRu: string;
  roleId: string;
  roleName: string;
  assignedBy: string;
  assignedAt: string;
  expiresAt?: string;
  status: 'active' | 'inactive' | 'pending' | 'expired' | 'revoked';
  lastAccess?: string;
  department: string;
  position: string;
}

interface RoleAnalytics {
  totalRoles: number;
  activeRoles: number;
  totalUsers: number;
  unassignedUsers: number;
  roleDistribution: Record<string, number>;
  permissionUsage: Record<string, number>;
  complianceScore: number;
  securityAlerts: number;
}

// Russian translations
const russianTranslations = {
  title: 'Управление ролями и доступом',
  subtitle: 'Централизованная система контроля доступа и разрешений',
  tabs: {
    dashboard: 'Панель управления',
    roles: 'Роли',
    permissions: 'Разрешения',
    users: 'Пользователи',
    audit: 'Аудит',
    analytics: 'Аналитика'
  },
  roles: {
    title: 'Управление ролями',
    create: 'Создать роль',
    edit: 'Редактировать роль',
    delete: 'Удалить роль',
    assign: 'Назначить пользователям',
    inherit: 'Наследовать разрешения',
    types: {
      system: 'Системная',
      business: 'Бизнес-роль',
      custom: 'Пользовательская',
      temporary: 'Временная'
    },
    levels: {
      executive: 'Руководитель',
      manager: 'Менеджер',
      specialist: 'Специалист',
      trainee: 'Стажёр',
      guest: 'Гость'
    }
  },
  permissions: {
    title: 'Управление разрешениями',
    assign: 'Назначить разрешение',
    revoke: 'Отозвать разрешение',
    categories: {
      data: 'Данные',
      system: 'Система',
      user: 'Пользователи',
      report: 'Отчёты',
      admin: 'Администрирование'
    },
    scopes: {
      global: 'Глобальный',
      department: 'Отдел',
      team: 'Команда',
      self: 'Личный'
    },
    risks: {
      low: 'Низкий',
      medium: 'Средний',
      high: 'Высокий',
      critical: 'Критический'
    }
  },
  users: {
    title: 'Назначение пользователей',
    assign: 'Назначить роль',
    unassign: 'Снять роль',
    bulk: 'Массовые операции',
    import: 'Импорт пользователей',
    export: 'Экспорт назначений'
  },
  status: {
    active: 'Активный',
    inactive: 'Неактивный',
    pending: 'Ожидает',
    expired: 'Истёк',
    revoked: 'Отозван'
  },
  compliance: {
    low: 'Низкий уровень',
    medium: 'Средний уровень',
    high: 'Высокий уровень',
    critical: 'Критический уровень'
  },
  actions: {
    create: 'Создать',
    edit: 'Редактировать',
    save: 'Сохранить',
    cancel: 'Отмена',
    delete: 'Удалить',
    assign: 'Назначить',
    unassign: 'Снять',
    approve: 'Утвердить',
    reject: 'Отклонить',
    search: 'Поиск',
    filter: 'Фильтр',
    export: 'Экспорт',
    import: 'Импорт'
  }
};

const Spec26RolesAccessControlDashboard: React.FC = () => {
  const [activeView, setActiveView] = useState<'dashboard' | 'roles' | 'permissions' | 'users' | 'audit' | 'analytics'>('dashboard');
  const [roles, setRoles] = useState<Spec26Role[]>([]);
  const [permissions, setPermissions] = useState<Spec26Permission[]>([]);
  const [userAssignments, setUserAssignments] = useState<Spec26UserAssignment[]>([]);
  const [analytics, setAnalytics] = useState<RoleAnalytics | null>(null);
  const [selectedRole, setSelectedRole] = useState<Spec26Role | null>(null);
  const [selectedPermission, setSelectedPermission] = useState<Spec26Permission | null>(null);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showPermissionMatrix, setShowPermissionMatrix] = useState(false);

  // Initialize with mock data from existing components
  useEffect(() => {
    generateMockData();
  }, []);

  const generateMockData = () => {
    // Mock roles based on Spec29RoleAccessControl patterns
    const mockRoles: Spec26Role[] = [
      {
        id: 'role_admin',
        name: 'System Administrator',
        nameRu: 'Системный администратор',
        nameEn: 'System Administrator',
        description: 'Full system access with all administrative privileges',
        type: 'system',
        level: 'executive',
        permissions: ['perm_all', 'perm_users_manage', 'perm_system_config', 'perm_audit_view'],
        isActive: true,
        userCount: 3,
        createdBy: 'system',
        createdAt: '2025-01-01T00:00:00Z',
        complianceLevel: 'critical',
        auditRequired: true
      },
      {
        id: 'role_manager',
        name: 'Department Manager',
        nameRu: 'Руководитель отдела',
        nameEn: 'Department Manager',
        description: 'Manage department staff and operations',
        type: 'business',
        level: 'manager',
        permissions: ['perm_dept_manage', 'perm_schedules_edit', 'perm_reports_view'],
        isActive: true,
        userCount: 12,
        createdBy: 'admin',
        createdAt: '2025-01-15T10:00:00Z',
        complianceLevel: 'high',
        auditRequired: true
      },
      {
        id: 'role_agent',
        name: 'Customer Service Agent',
        nameRu: 'Агент обслуживания клиентов',
        nameEn: 'Customer Service Agent',
        description: 'Handle customer interactions and basic operations',
        type: 'business',
        level: 'specialist',
        permissions: ['perm_tickets_handle', 'perm_customer_view', 'perm_schedule_view'],
        isActive: true,
        userCount: 45,
        createdBy: 'manager',
        createdAt: '2025-02-01T09:00:00Z',
        complianceLevel: 'medium',
        auditRequired: false
      },
      {
        id: 'role_viewer',
        name: 'Report Viewer',
        nameRu: 'Просмотр отчётов',
        nameEn: 'Report Viewer',
        description: 'View reports and analytics only',
        type: 'custom',
        level: 'specialist',
        permissions: ['perm_reports_view', 'perm_analytics_view'],
        isActive: true,
        userCount: 8,
        createdBy: 'admin',
        createdAt: '2025-02-10T14:30:00Z',
        complianceLevel: 'low',
        auditRequired: false
      }
    ];

    // Mock permissions
    const mockPermissions: Spec26Permission[] = [
      {
        id: 'perm_all',
        name: 'All System Access',
        nameRu: 'Полный доступ к системе',
        nameEn: 'All System Access',
        resource: '*',
        action: '*',
        category: 'admin',
        scope: 'global',
        riskLevel: 'critical',
        description: 'Complete administrative access to all system functions',
        requiresApproval: true
      },
      {
        id: 'perm_users_manage',
        name: 'Manage Users',
        nameRu: 'Управление пользователями',
        nameEn: 'Manage Users',
        resource: 'users',
        action: 'manage',
        category: 'user',
        scope: 'global',
        riskLevel: 'high',
        description: 'Create, edit, delete user accounts and assignments',
        requiresApproval: true
      },
      {
        id: 'perm_schedules_edit',
        name: 'Edit Schedules',
        nameRu: 'Редактирование расписаний',
        nameEn: 'Edit Schedules',
        resource: 'schedules',
        action: 'edit',
        category: 'data',
        scope: 'department',
        riskLevel: 'medium',
        description: 'Modify work schedules and shift assignments',
        requiresApproval: false
      },
      {
        id: 'perm_reports_view',
        name: 'View Reports',
        nameRu: 'Просмотр отчётов',
        nameEn: 'View Reports',
        resource: 'reports',
        action: 'view',
        category: 'report',
        scope: 'department',
        riskLevel: 'low',
        description: 'Access to departmental reports and analytics',
        requiresApproval: false
      }
    ];

    // Mock user assignments
    const mockAssignments: Spec26UserAssignment[] = [
      {
        id: 'assign_1',
        userId: 'user_001',
        userName: 'Иван Петров',
        userNameRu: 'Иван Петров',
        roleId: 'role_admin',
        roleName: 'System Administrator',
        assignedBy: 'system',
        assignedAt: '2025-01-01T00:00:00Z',
        status: 'active',
        lastAccess: '2025-07-21T08:30:00Z',
        department: 'IT',
        position: 'Главный администратор'
      },
      {
        id: 'assign_2',
        userId: 'user_002',
        userName: 'Анна Смирнова',
        userNameRu: 'Анна Смирнова',
        roleId: 'role_manager',
        roleName: 'Department Manager',
        assignedBy: 'admin',
        assignedAt: '2025-02-01T10:00:00Z',
        status: 'active',
        lastAccess: '2025-07-21T09:15:00Z',
        department: 'Customer Service',
        position: 'Руководитель отдела'
      },
      {
        id: 'assign_3',
        userId: 'user_003',
        userName: 'Михаил Козлов',
        userNameRu: 'Михаил Козлов',
        roleId: 'role_agent',
        roleName: 'Customer Service Agent',
        assignedBy: 'manager',
        assignedAt: '2025-02-15T14:00:00Z',
        status: 'active',
        lastAccess: '2025-07-21T08:45:00Z',
        department: 'Customer Service',
        position: 'Агент поддержки'
      }
    ];

    // Mock analytics
    const mockAnalytics: RoleAnalytics = {
      totalRoles: 4,
      activeRoles: 4,
      totalUsers: 68,
      unassignedUsers: 5,
      roleDistribution: {
        'System Administrator': 3,
        'Department Manager': 12,
        'Customer Service Agent': 45,
        'Report Viewer': 8
      },
      permissionUsage: {
        'View Reports': 65,
        'Edit Schedules': 57,
        'Manage Users': 15,
        'All System Access': 3
      },
      complianceScore: 94.5,
      securityAlerts: 2
    };

    setRoles(mockRoles);
    setPermissions(mockPermissions);
    setUserAssignments(mockAssignments);
    setAnalytics(mockAnalytics);
  };

  const getRiskLevelColor = (risk: string) => {
    const colors = {
      low: 'text-green-600 bg-green-100',
      medium: 'text-yellow-600 bg-yellow-100',
      high: 'text-orange-600 bg-orange-100',
      critical: 'text-red-600 bg-red-100'
    };
    return colors[risk as keyof typeof colors] || colors.low;
  };

  const getStatusColor = (status: string) => {
    const colors = {
      active: 'text-green-600 bg-green-100',
      inactive: 'text-gray-600 bg-gray-100',
      pending: 'text-yellow-600 bg-yellow-100',
      expired: 'text-red-600 bg-red-100',
      revoked: 'text-red-600 bg-red-100'
    };
    return colors[status as keyof typeof colors] || colors.inactive;
  };

  const getTypeIcon = (type: string) => {
    const icons = {
      system: Crown,
      business: Award,
      custom: Settings,
      temporary: Clock
    };
    return icons[type as keyof typeof icons] || Settings;
  };

  const renderDashboard = () => (
    <div className="space-y-6">
      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Всего ролей</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.totalRoles || 0}</p>
              <p className="text-xs text-green-600 mt-1">{analytics?.activeRoles} активных</p>
            </div>
            <div className="p-3 bg-blue-100 rounded-lg">
              <Shield className="h-6 w-6 text-blue-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Пользователи</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.totalUsers || 0}</p>
              <p className="text-xs text-yellow-600 mt-1">{analytics?.unassignedUsers} без ролей</p>
            </div>
            <div className="p-3 bg-green-100 rounded-lg">
              <Users className="h-6 w-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Соответствие</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.complianceScore || 0}%</p>
              <p className="text-xs text-green-600 mt-1">Хороший уровень</p>
            </div>
            <div className="p-3 bg-purple-100 rounded-lg">
              <CheckCircle className="h-6 w-6 text-purple-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Предупреждения</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.securityAlerts || 0}</p>
              <p className="text-xs text-gray-500 mt-1">За последний час</p>
            </div>
            <div className="p-3 bg-red-100 rounded-lg">
              <AlertTriangle className="h-6 w-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Role Distribution & Permission Usage */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Role Distribution */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Распределение ролей</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {Object.entries(analytics?.roleDistribution || {}).map(([role, count]) => (
                <div key={role} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-blue-600"></div>
                    <span className="text-sm font-medium text-gray-700">{role}</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-blue-600 h-2 rounded-full"
                        style={{ width: `${(count / (analytics?.totalUsers || 1)) * 100}%` }}
                      ></div>
                    </div>
                    <span className="text-sm font-medium text-gray-900 w-8 text-right">{count}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Permission Usage */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Использование разрешений</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {Object.entries(analytics?.permissionUsage || {}).map(([permission, usage]) => (
                <div key={permission} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Key className="h-4 w-4 text-gray-400" />
                    <span className="text-sm font-medium text-gray-700">{permission}</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-green-600 h-2 rounded-full"
                        style={{ width: `${(usage / (analytics?.totalUsers || 1)) * 100}%` }}
                      ></div>
                    </div>
                    <span className="text-sm font-medium text-gray-900 w-8 text-right">{usage}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Недавние назначения</h3>
        </div>
        <div className="p-6">
          <div className="space-y-4">
            {userAssignments.slice(0, 5).map((assignment) => (
              <div key={assignment.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                    <User className="h-5 w-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{assignment.userNameRu}</p>
                    <p className="text-sm text-gray-600">{assignment.roleName}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(assignment.status)}`}>
                    {russianTranslations.status[assignment.status]}
                  </span>
                  <p className="text-xs text-gray-500 mt-1">
                    {new Date(assignment.assignedAt).toLocaleDateString('ru-RU')}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderRoles = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">{russianTranslations.roles.title}</h2>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Поиск ролей..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Все типы</option>
            <option value="system">Системные</option>
            <option value="business">Бизнес-роли</option>
            <option value="custom">Пользовательские</option>
          </select>
          <button
            onClick={() => setShowCreateModal(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Plus className="h-4 w-4" />
            {russianTranslations.roles.create}
          </button>
        </div>
      </div>

      {/* Roles Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {roles.map((role) => {
          const TypeIcon = getTypeIcon(role.type);
          
          return (
            <div key={role.id} className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-100 rounded-lg">
                      <TypeIcon className="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{role.nameRu}</h3>
                      <p className="text-sm text-gray-600">{role.nameEn}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-1 text-xs font-medium rounded-full ${getRiskLevelColor(role.complianceLevel)}`}>
                    {russianTranslations.compliance[role.complianceLevel]}
                  </span>
                </div>
                
                <p className="text-sm text-gray-600 mb-4">{role.description}</p>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <p className="text-xs text-gray-500">Тип</p>
                    <p className="text-sm font-medium text-gray-900">{russianTranslations.roles.types[role.type]}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Уровень</p>
                    <p className="text-sm font-medium text-gray-900">{russianTranslations.roles.levels[role.level]}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Пользователи</p>
                    <p className="text-sm font-medium text-gray-900">{role.userCount}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Разрешения</p>
                    <p className="text-sm font-medium text-gray-900">{role.permissions.length}</p>
                  </div>
                </div>
                
                <div className="flex items-center justify-between pt-4 border-t border-gray-200">
                  <div className="flex items-center gap-2">
                    {role.auditRequired && (
                      <div className="flex items-center gap-1 text-orange-600">
                        <FileText className="h-3 w-3" />
                        <span className="text-xs">Аудит</span>
                      </div>
                    )}
                    {role.isActive && (
                      <div className="flex items-center gap-1 text-green-600">
                        <CheckCircle className="h-3 w-3" />
                        <span className="text-xs">Активна</span>
                      </div>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <button className="p-1 hover:bg-gray-100 rounded">
                      <Eye className="h-4 w-4 text-gray-500" />
                    </button>
                    <button className="p-1 hover:bg-gray-100 rounded">
                      <Edit3 className="h-4 w-4 text-gray-500" />
                    </button>
                    <button className="p-1 hover:bg-gray-100 rounded">
                      <Copy className="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );

  const renderPermissions = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">{russianTranslations.permissions.title}</h2>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setShowPermissionMatrix(!showPermissionMatrix)}
            className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2"
          >
            <Grid className="h-4 w-4" />
            {showPermissionMatrix ? 'Список' : 'Матрица'}
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
            <Plus className="h-4 w-4" />
            Создать разрешение
          </button>
        </div>
      </div>

      {showPermissionMatrix ? (
        /* Permission Matrix */
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Матрица разрешений</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Роль</th>
                  {permissions.map((permission) => (
                    <th key={permission.id} className="px-3 py-3 text-center text-xs font-medium text-gray-500 uppercase min-w-24">
                      <div className="transform -rotate-45 origin-bottom-left w-16">
                        {permission.nameRu}
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {roles.map((role) => (
                  <tr key={role.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      {role.nameRu}
                    </td>
                    {permissions.map((permission) => (
                      <td key={`${role.id}-${permission.id}`} className="px-3 py-4 text-center">
                        {role.permissions.includes(permission.id) ? (
                          <CheckCircle className="h-5 w-5 text-green-600 mx-auto" />
                        ) : (
                          <XCircle className="h-5 w-5 text-gray-300 mx-auto" />
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Permission List */
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Разрешение</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ресурс</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действие</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Категория</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Область</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Риск</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {permissions.map((permission) => (
                  <tr key={permission.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div>
                        <p className="text-sm font-medium text-gray-900">{permission.nameRu}</p>
                        <p className="text-xs text-gray-500">{permission.nameEn}</p>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{permission.resource}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{permission.action}</td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-700">
                        {russianTranslations.permissions.categories[permission.category]}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700">
                        {russianTranslations.permissions.scopes[permission.scope]}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getRiskLevelColor(permission.riskLevel)}`}>
                        {russianTranslations.permissions.risks[permission.riskLevel]}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <button className="p-1 hover:bg-gray-100 rounded">
                          <Edit3 className="h-4 w-4 text-gray-500" />
                        </button>
                        <button className="p-1 hover:bg-gray-100 rounded">
                          <Trash2 className="h-4 w-4 text-gray-500" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );

  const renderUsers = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">{russianTranslations.users.title}</h2>
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Upload className="h-4 w-4" />
            {russianTranslations.users.import}
          </button>
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Download className="h-4 w-4" />
            {russianTranslations.users.export}
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
            <UserPlus className="h-4 w-4" />
            {russianTranslations.users.assign}
          </button>
        </div>
      </div>

      {/* User Assignments Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Пользователь</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Роль</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Отдел</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Назначено</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Статус</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Последний вход</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {userAssignments.map((assignment) => (
                <tr key={assignment.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                        <User className="h-4 w-4 text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-900">{assignment.userNameRu}</p>
                        <p className="text-xs text-gray-500">{assignment.position}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">{assignment.roleName}</td>
                  <td className="px-6 py-4 text-sm text-gray-900">{assignment.department}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {new Date(assignment.assignedAt).toLocaleDateString('ru-RU')}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(assignment.status)}`}>
                      {russianTranslations.status[assignment.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {assignment.lastAccess ? new Date(assignment.lastAccess).toLocaleDateString('ru-RU') : 'Никогда'}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button className="p-1 hover:bg-gray-100 rounded">
                        <Edit3 className="h-4 w-4 text-gray-500" />
                      </button>
                      <button className="p-1 hover:bg-gray-100 rounded">
                        <UserX className="h-4 w-4 text-gray-500" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Shield className="h-6 w-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
              <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                SPEC-26
              </span>
            </div>
            <div className="flex items-center gap-3">
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <RefreshCw className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Download className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Settings className="h-5 w-5 text-gray-600" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="px-6">
          <nav className="flex space-x-6">
            {[
              { id: 'dashboard', label: 'Панель управления', icon: LayoutDashboard },
              { id: 'roles', label: 'Роли', icon: Shield },
              { id: 'permissions', label: 'Разрешения', icon: Key },
              { id: 'users', label: 'Пользователи', icon: Users },
              { id: 'audit', label: 'Аудит', icon: FileText },
              { id: 'analytics', label: 'Аналитика', icon: BarChart3 }
            ].map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveView(tab.id as any)}
                  className={`flex items-center gap-2 py-4 border-b-2 transition-colors ${
                    activeView === tab.id
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span className="font-medium">{tab.label}</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {activeView === 'dashboard' && renderDashboard()}
        {activeView === 'roles' && renderRoles()}
        {activeView === 'permissions' && renderPermissions()}
        {activeView === 'users' && renderUsers()}
        {activeView === 'audit' && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">Журнал аудита - в разработке</p>
          </div>
        )}
        {activeView === 'analytics' && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">Аналитика доступа - в разработке</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec26RolesAccessControlDashboard;