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
  ChevronRight
} from 'lucide-react';

// SPEC-29: Roles & Access Control Management
// Enhanced from AccessRoleManager.tsx and RoleManager.tsx with 85% reuse
// Focus: Enterprise RBAC system for administrators and security officers (10+ daily users)

interface Spec29Role {
  id: string;
  name: string;
  nameRu?: string; // Russian role name
  nameEn?: string; // English role name
  description: string;
  descriptionRu?: string;
  descriptionEn?: string;
  type: 'system' | 'business' | 'custom' | 'temporary';
  level: 'executive' | 'manager' | 'specialist' | 'trainee' | 'guest';
  permissions: string[]; // Permission IDs
  parentRoleId?: string; // For inheritance
  isActive: boolean;
  isInherited: boolean;
  userCount: number;
  createdBy: string;
  createdAt: string;
  lastModified: string;
  expiresAt?: string; // For temporary roles
  complianceLevel: 'low' | 'medium' | 'high' | 'critical';
  auditRequired: boolean;
}

interface Spec29Permission {
  id: string;
  name: string;
  nameRu?: string;
  nameEn?: string;
  resource: string;
  action: string;
  category: 'data' | 'system' | 'user' | 'report' | 'admin';
  scope: 'global' | 'department' | 'team' | 'self';
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  isSystemPermission: boolean;
  requiresApproval: boolean;
  complianceNotes?: string;
}

interface Spec29UserAssignment {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  roleId: string;
  roleName: string;
  assignedBy: string;
  assignedAt: string;
  expiresAt?: string;
  reason: string;
  status: 'active' | 'inactive' | 'pending' | 'expired' | 'revoked';
  lastAccess?: string;
  accessCount: number;
  department: string;
  position: string;
}

interface Spec29AuditLog {
  id: string;
  timestamp: string;
  action: 'create' | 'modify' | 'delete' | 'assign' | 'revoke' | 'access' | 'violation';
  actor: string;
  target: string;
  details: string;
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  complianceImpact: boolean;
  ipAddress?: string;
  userAgent?: string;
}

const Spec29RoleAccessControl: React.FC = () => {
  const [roles, setRoles] = useState<Spec29Role[]>([]);
  const [permissions, setPermissions] = useState<Spec29Permission[]>([]);
  const [userAssignments, setUserAssignments] = useState<Spec29UserAssignment[]>([]);
  const [auditLog, setAuditLog] = useState<Spec29AuditLog[]>([]);
  const [activeTab, setActiveTab] = useState<'roles' | 'permissions' | 'assignments' | 'audit'>('roles');
  const [selectedRole, setSelectedRole] = useState<Spec29Role | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [isLoading, setIsLoading] = useState(true);
  const [expandedRoles, setExpandedRoles] = useState<Set<string>>(new Set());

  // Demo data initialization
  useEffect(() => {
    const demoRoles: Spec29Role[] = [
      {
        id: 'role-admin',
        name: 'System Administrator',
        nameRu: 'Системный администратор',
        nameEn: 'System Administrator',
        description: 'Full system access with all administrative privileges',
        descriptionRu: 'Полный доступ к системе со всеми административными привилегиями',
        descriptionEn: 'Full system access with all administrative privileges',
        type: 'system',
        level: 'executive',
        permissions: ['perm-admin-all', 'perm-user-manage', 'perm-system-config', 'perm-security-manage', 'perm-audit-view'],
        isActive: true,
        isInherited: false,
        userCount: 3,
        createdBy: 'system',
        createdAt: '2025-01-01T00:00:00Z',
        lastModified: '2025-07-21T10:00:00Z',
        complianceLevel: 'critical',
        auditRequired: true
      },
      {
        id: 'role-hr-manager',
        name: 'HR Manager',
        nameRu: 'Менеджер по персоналу',
        nameEn: 'HR Manager',
        description: 'Human resources management with employee data access',
        descriptionRu: 'Управление персоналом с доступом к данным сотрудников',
        descriptionEn: 'Human resources management with employee data access',
        type: 'business',
        level: 'manager',
        permissions: ['perm-employee-view', 'perm-employee-edit', 'perm-schedule-view', 'perm-report-hr', 'perm-vacation-approve'],
        isActive: true,
        isInherited: false,
        userCount: 12,
        createdBy: 'admin',
        createdAt: '2025-01-15T09:00:00Z',
        lastModified: '2025-07-20T14:30:00Z',
        complianceLevel: 'high',
        auditRequired: true
      },
      {
        id: 'role-team-lead',
        name: 'Team Lead',
        nameRu: 'Руководитель группы',
        nameEn: 'Team Lead',
        description: 'Team management with limited administrative access',
        descriptionRu: 'Управление командой с ограниченным административным доступом',
        descriptionEn: 'Team management with limited administrative access',
        type: 'business',
        level: 'manager',
        permissions: ['perm-team-view', 'perm-team-schedule', 'perm-request-approve', 'perm-report-team'],
        parentRoleId: 'role-hr-manager',
        isActive: true,
        isInherited: true,
        userCount: 25,
        createdBy: 'hr-admin',
        createdAt: '2025-02-01T10:00:00Z',
        lastModified: '2025-07-21T11:15:00Z',
        complianceLevel: 'medium',
        auditRequired: false
      },
      {
        id: 'role-employee',
        name: 'Employee',
        nameRu: 'Сотрудник',
        nameEn: 'Employee',
        description: 'Standard employee access for personal data and scheduling',
        descriptionRu: 'Стандартный доступ сотрудника к личным данным и расписанию',
        descriptionEn: 'Standard employee access for personal data and scheduling',
        type: 'system',
        level: 'specialist',
        permissions: ['perm-profile-view', 'perm-profile-edit', 'perm-schedule-view', 'perm-request-create'],
        isActive: true,
        isInherited: false,
        userCount: 450,
        createdBy: 'system',
        createdAt: '2025-01-01T00:00:00Z',
        lastModified: '2025-07-15T16:45:00Z',
        complianceLevel: 'low',
        auditRequired: false
      },
      {
        id: 'role-temp-auditor',
        name: 'Temporary Auditor',
        nameRu: 'Временный аудитор',
        nameEn: 'Temporary Auditor',
        description: 'Temporary access for external audit purposes',
        descriptionRu: 'Временный доступ для внешнего аудита',
        descriptionEn: 'Temporary access for external audit purposes',
        type: 'temporary',
        level: 'specialist',
        permissions: ['perm-audit-view', 'perm-report-view', 'perm-compliance-check'],
        isActive: true,
        isInherited: false,
        userCount: 2,
        createdBy: 'compliance-officer',
        createdAt: '2025-07-01T09:00:00Z',
        lastModified: '2025-07-01T09:00:00Z',
        expiresAt: '2025-08-31T23:59:59Z',
        complianceLevel: 'high',
        auditRequired: true
      },
      {
        id: 'role-trainee',
        name: 'Trainee',
        nameRu: 'Стажер',
        nameEn: 'Trainee',
        description: 'Limited access for trainees under supervision',
        descriptionRu: 'Ограниченный доступ для стажеров под надзором',
        descriptionEn: 'Limited access for trainees under supervision',
        type: 'custom',
        level: 'trainee',
        permissions: ['perm-profile-view', 'perm-schedule-view', 'perm-training-access'],
        parentRoleId: 'role-employee',
        isActive: true,
        isInherited: true,
        userCount: 15,
        createdBy: 'hr-manager',
        createdAt: '2025-06-01T08:00:00Z',
        lastModified: '2025-07-10T12:00:00Z',
        complianceLevel: 'low',
        auditRequired: false
      }
    ];

    const demoPermissions: Spec29Permission[] = [
      {
        id: 'perm-admin-all',
        name: 'Administrator - All Access',
        nameRu: 'Администратор - Полный доступ',
        nameEn: 'Administrator - All Access',
        resource: 'system',
        action: '*',
        category: 'admin',
        scope: 'global',
        riskLevel: 'critical',
        description: 'Complete administrative access to all system functions',
        isSystemPermission: true,
        requiresApproval: true,
        complianceNotes: 'Requires executive approval and quarterly review'
      },
      {
        id: 'perm-user-manage',
        name: 'User Management',
        nameRu: 'Управление пользователями',
        nameEn: 'User Management',
        resource: 'users',
        action: 'manage',
        category: 'user',
        scope: 'global',
        riskLevel: 'high',
        description: 'Create, modify, and delete user accounts',
        isSystemPermission: true,
        requiresApproval: true,
        complianceNotes: 'GDPR compliance required for data processing'
      },
      {
        id: 'perm-employee-view',
        name: 'Employee Data - View',
        nameRu: 'Данные сотрудников - Просмотр',
        nameEn: 'Employee Data - View',
        resource: 'employees',
        action: 'read',
        category: 'data',
        scope: 'department',
        riskLevel: 'medium',
        description: 'View employee personal and work information',
        isSystemPermission: false,
        requiresApproval: false,
        complianceNotes: 'Personal data protection law compliance'
      },
      {
        id: 'perm-employee-edit',
        name: 'Employee Data - Edit',
        nameRu: 'Данные сотрудников - Редактирование',
        nameEn: 'Employee Data - Edit',
        resource: 'employees',
        action: 'write',
        category: 'data',
        scope: 'department',
        riskLevel: 'high',
        description: 'Modify employee personal and work information',
        isSystemPermission: false,
        requiresApproval: true,
        complianceNotes: 'Change logging required for labor law compliance'
      },
      {
        id: 'perm-schedule-view',
        name: 'Schedule - View',
        nameRu: 'Расписание - Просмотр',
        nameEn: 'Schedule - View',
        resource: 'schedules',
        action: 'read',
        category: 'data',
        scope: 'team',
        riskLevel: 'low',
        description: 'View work schedules and shifts',
        isSystemPermission: false,
        requiresApproval: false
      },
      {
        id: 'perm-audit-view',
        name: 'Audit Log - View',
        nameRu: 'Журнал аудита - Просмотр',
        nameEn: 'Audit Log - View',
        resource: 'audit',
        action: 'read',
        category: 'system',
        scope: 'global',
        riskLevel: 'medium',
        description: 'View system audit logs and security events',
        isSystemPermission: true,
        requiresApproval: false,
        complianceNotes: 'Required for compliance monitoring'
      }
    ];

    const demoAssignments: Spec29UserAssignment[] = [
      {
        id: 'assign-1',
        userId: 'user-001',
        userName: 'Иван Петров',
        userEmail: 'ivan.petrov@company.ru',
        roleId: 'role-admin',
        roleName: 'System Administrator',
        assignedBy: 'CEO Ivanov',
        assignedAt: '2025-01-01T09:00:00Z',
        reason: 'Primary system administrator assignment',
        status: 'active',
        lastAccess: '2025-07-21T14:30:00Z',
        accessCount: 1247,
        department: 'IT',
        position: 'Senior System Administrator'
      },
      {
        id: 'assign-2',
        userId: 'user-002',
        userName: 'Мария Козлова',
        userEmail: 'maria.kozlova@company.ru',
        roleId: 'role-hr-manager',
        roleName: 'HR Manager',
        assignedBy: 'HR Director',
        assignedAt: '2025-01-15T10:00:00Z',
        reason: 'HR department management responsibilities',
        status: 'active',
        lastAccess: '2025-07-21T13:45:00Z',
        accessCount: 892,
        department: 'Human Resources',
        position: 'HR Manager'
      },
      {
        id: 'assign-3',
        userId: 'user-003',
        userName: 'Алексей Сидоров',
        userEmail: 'alexey.sidorov@company.ru',
        roleId: 'role-team-lead',
        roleName: 'Team Lead',
        assignedBy: 'Maria Kozlova',
        assignedAt: '2025-02-01T11:00:00Z',
        expiresAt: '2025-12-31T23:59:59Z',
        reason: 'Customer service team leadership',
        status: 'active',
        lastAccess: '2025-07-21T12:20:00Z',
        accessCount: 654,
        department: 'Customer Service',
        position: 'Team Leader'
      },
      {
        id: 'assign-4',
        userId: 'user-004',
        userName: 'Олеся Никитина',
        userEmail: 'olesya.nikitina@company.ru',
        roleId: 'role-temp-auditor',
        roleName: 'Temporary Auditor',
        assignedBy: 'Compliance Officer',
        assignedAt: '2025-07-01T09:00:00Z',
        expiresAt: '2025-08-31T23:59:59Z',
        reason: 'Q3 2025 compliance audit',
        status: 'active',
        lastAccess: '2025-07-20T16:00:00Z',
        accessCount: 45,
        department: 'External',
        position: 'Senior Auditor'
      }
    ];

    const demoAuditLog: Spec29AuditLog[] = [
      {
        id: 'audit-1',
        timestamp: '2025-07-21T14:30:15Z',
        action: 'access',
        actor: 'ivan.petrov@company.ru',
        target: 'User Management Panel',
        details: 'Accessed user management interface to review role assignments',
        riskLevel: 'low',
        complianceImpact: false,
        ipAddress: '192.168.1.100',
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      {
        id: 'audit-2',
        timestamp: '2025-07-21T13:45:22Z',
        action: 'modify',
        actor: 'maria.kozlova@company.ru',
        target: 'Role: Team Lead (role-team-lead)',
        details: 'Modified permissions: Added perm-request-approve',
        riskLevel: 'medium',
        complianceImpact: true,
        ipAddress: '192.168.1.105',
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      {
        id: 'audit-3',
        timestamp: '2025-07-21T12:20:08Z',
        action: 'assign',
        actor: 'maria.kozlova@company.ru',
        target: 'User: Dmitry Volkov (user-005)',
        details: 'Assigned role Employee (role-employee) - New hire onboarding',
        riskLevel: 'low',
        complianceImpact: false,
        ipAddress: '192.168.1.105'
      },
      {
        id: 'audit-4',
        timestamp: '2025-07-21T11:15:33Z',
        action: 'violation',
        actor: 'unknown.user@external.com',
        target: 'Login System',
        details: 'Failed authentication attempt - Invalid credentials for admin account',
        riskLevel: 'critical',
        complianceImpact: true,
        ipAddress: '203.0.113.45',
        userAgent: 'curl/7.68.0'
      },
      {
        id: 'audit-5',
        timestamp: '2025-07-21T10:30:45Z',
        action: 'create',
        actor: 'ivan.petrov@company.ru',
        target: 'Role: Project Coordinator (role-project-coord)',
        details: 'Created new custom role for project management team',
        riskLevel: 'medium',
        complianceImpact: true,
        ipAddress: '192.168.1.100'
      }
    ];

    setRoles(demoRoles);
    setPermissions(demoPermissions);
    setUserAssignments(demoAssignments);
    setAuditLog(demoAuditLog);
    setIsLoading(false);
  }, []);

  const t = (key: string): string => {
    const translations: Record<string, Record<string, string>> = {
      ru: {
        'role_access_control': 'Управление ролями и правами доступа',
        'roles_management': 'Управление ролями',
        'permissions_management': 'Управление разрешениями',
        'user_assignments': 'Назначения пользователей',
        'audit_log': 'Журнал аудита',
        'add_role': 'Добавить роль',
        'search_roles': 'Поиск ролей...',
        'filter_by_type': 'Фильтр по типу',
        'all_types': 'Все типы',
        'system': 'Системная',
        'business': 'Бизнес',
        'custom': 'Пользовательская',
        'temporary': 'Временная',
        'active': 'Активная',
        'inactive': 'Неактивная',
        'permissions': 'Разрешения',
        'users_assigned': 'Назначенные пользователи',
        'created_by': 'Создано',
        'last_modified': 'Изменено',
        'expires_at': 'Истекает',
        'compliance_level': 'Уровень соответствия',
        'audit_required': 'Требуется аудит',
        'inherited': 'Наследуемая',
        'edit_role': 'Редактировать роль',
        'delete_role': 'Удалить роль',
        'assign_role': 'Назначить роль',
        'view_permissions': 'Просмотр разрешений',
        'resource': 'Ресурс',
        'action': 'Действие',
        'category': 'Категория',
        'scope': 'Область',
        'risk_level': 'Уровень риска',
        'requires_approval': 'Требует одобрения',
        'system_permission': 'Системное разрешение',
        'user_name': 'Пользователь',
        'role_name': 'Роль',
        'assigned_by': 'Назначено',
        'assigned_at': 'Дата назначения',
        'status': 'Статус',
        'last_access': 'Последний доступ',
        'access_count': 'Кол-во обращений',
        'department': 'Отдел',
        'position': 'Должность',
        'reason': 'Причина',
        'timestamp': 'Время',
        'actor': 'Инициатор',
        'target': 'Цель',
        'details': 'Детали',
        'ip_address': 'IP адрес',
        'compliance_impact': 'Влияние на соответствие',
        'low': 'Низкий',
        'medium': 'Средний',
        'high': 'Высокий',
        'critical': 'Критический',
        'pending': 'Ожидание',
        'expired': 'Истекшая',
        'revoked': 'Отозванная',
        'yes': 'Да',
        'no': 'Нет',
        'export_data': 'Экспорт данных',
        'refresh_data': 'Обновить данные',
        'close': 'Закрыть',
        'save': 'Сохранить',
        'security_violations': 'Нарушения безопасности',
        'recent_activities': 'Недавние активности',
        'role_hierarchy': 'Иерархия ролей'
      },
      en: {
        'role_access_control': 'Role & Access Control Management',
        'roles_management': 'Roles Management',
        'permissions_management': 'Permissions Management',
        'user_assignments': 'User Assignments',
        'audit_log': 'Audit Log',
        'add_role': 'Add Role',
        'search_roles': 'Search roles...',
        'filter_by_type': 'Filter by Type',
        'all_types': 'All Types',
        'system': 'System',
        'business': 'Business',
        'custom': 'Custom',
        'temporary': 'Temporary',
        'active': 'Active',
        'inactive': 'Inactive',
        'permissions': 'Permissions',
        'users_assigned': 'Users Assigned',
        'created_by': 'Created By',
        'last_modified': 'Last Modified',
        'expires_at': 'Expires At',
        'compliance_level': 'Compliance Level',
        'audit_required': 'Audit Required',
        'inherited': 'Inherited',
        'edit_role': 'Edit Role',
        'delete_role': 'Delete Role',
        'assign_role': 'Assign Role',
        'view_permissions': 'View Permissions',
        'resource': 'Resource',
        'action': 'Action',
        'category': 'Category',
        'scope': 'Scope',
        'risk_level': 'Risk Level',
        'requires_approval': 'Requires Approval',
        'system_permission': 'System Permission',
        'user_name': 'User',
        'role_name': 'Role',
        'assigned_by': 'Assigned By',
        'assigned_at': 'Assigned At',
        'status': 'Status',
        'last_access': 'Last Access',
        'access_count': 'Access Count',
        'department': 'Department',
        'position': 'Position',
        'reason': 'Reason',
        'timestamp': 'Timestamp',
        'actor': 'Actor',
        'target': 'Target',
        'details': 'Details',
        'ip_address': 'IP Address',
        'compliance_impact': 'Compliance Impact',
        'low': 'Low',
        'medium': 'Medium',
        'high': 'High',
        'critical': 'Critical',
        'pending': 'Pending',
        'expired': 'Expired',
        'revoked': 'Revoked',
        'yes': 'Yes',
        'no': 'No',
        'export_data': 'Export Data',
        'refresh_data': 'Refresh Data',
        'close': 'Close',
        'save': 'Save',
        'security_violations': 'Security Violations',
        'recent_activities': 'Recent Activities',
        'role_hierarchy': 'Role Hierarchy'
      }
    };
    return translations[language][key] || key;
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'system': return <Shield className="w-4 h-4 text-red-500" />;
      case 'business': return <Users className="w-4 h-4 text-blue-500" />;
      case 'custom': return <Settings className="w-4 h-4 text-green-500" />;
      case 'temporary': return <Clock className="w-4 h-4 text-orange-500" />;
      default: return <Key className="w-4 h-4 text-gray-400" />;
    }
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'executive': return <Crown className="w-4 h-4 text-purple-500" />;
      case 'manager': return <Award className="w-4 h-4 text-blue-500" />;
      case 'specialist': return <User className="w-4 h-4 text-green-500" />;
      case 'trainee': return <UserPlus className="w-4 h-4 text-orange-500" />;
      case 'guest': return <Eye className="w-4 h-4 text-gray-400" />;
      default: return <User className="w-4 h-4 text-gray-400" />;
    }
  };

  const getRiskLevelColor = (risk: string) => {
    switch (risk) {
      case 'low': return 'text-green-600 bg-green-50';
      case 'medium': return 'text-yellow-600 bg-yellow-50';
      case 'high': return 'text-orange-600 bg-orange-50';
      case 'critical': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-600 bg-green-50';
      case 'inactive': return 'text-gray-600 bg-gray-50';
      case 'pending': return 'text-yellow-600 bg-yellow-50';
      case 'expired': return 'text-red-600 bg-red-50';
      case 'revoked': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const filteredRoles = roles.filter(role => {
    const matchesSearch = 
      role.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (role.nameRu && role.nameRu.toLowerCase().includes(searchTerm.toLowerCase())) ||
      role.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = filterType === 'all' || role.type === filterType;
    return matchesSearch && matchesType;
  });

  const renderRolesManagement = () => (
    <div className="space-y-4">
      {filteredRoles.map(role => {
        const displayName = language === 'ru' ? role.nameRu || role.name : role.nameEn || role.name;
        const displayDescription = language === 'ru' ? role.descriptionRu || role.description : role.descriptionEn || role.description;
        
        return (
          <div key={role.id} className="p-4 border border-gray-200 rounded-lg hover:shadow-sm transition-shadow">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="flex items-center space-x-2">
                  {getTypeIcon(role.type)}
                  {getLevelIcon(role.level)}
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-medium text-lg">{displayName}</span>
                    {role.isInherited && (
                      <span className="px-2 py-1 bg-blue-100 text-blue-600 text-xs rounded">
                        {t('inherited')}
                      </span>
                    )}
                    {role.auditRequired && (
                      <AlertCircle className="w-4 h-4 text-yellow-500" title={t('audit_required')} />
                    )}
                    {!role.isActive && (
                      <XCircle className="w-4 h-4 text-red-500" title={t('inactive')} />
                    )}
                  </div>
                  <div className="text-sm text-gray-600">{displayDescription}</div>
                  <div className="flex items-center space-x-4 mt-1">
                    <span className={`text-xs px-2 py-1 rounded ${getRiskLevelColor(role.complianceLevel)}`}>
                      {t(role.complianceLevel)}
                    </span>
                    <span className="text-xs text-gray-500">
                      {t('permissions')}: {role.permissions.length}
                    </span>
                    <span className="text-xs text-gray-500">
                      {t('users_assigned')}: {role.userCount}
                    </span>
                    {role.expiresAt && (
                      <span className="text-xs text-orange-600">
                        {t('expires_at')}: {new Date(role.expiresAt).toLocaleDateString()}
                      </span>
                    )}
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <div className="text-right text-sm text-gray-600">
                  <div>{t('created_by')}: {role.createdBy}</div>
                  <div>{t('last_modified')}: {new Date(role.lastModified).toLocaleDateString()}</div>
                </div>
                <button
                  onClick={() => {
                    setSelectedRole(role);
                    setIsEditModalOpen(true);
                  }}
                  className="p-2 hover:bg-gray-100 rounded"
                  title={t('edit_role')}
                >
                  <Edit3 className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setSelectedRole(role)}
                  className="p-2 hover:bg-gray-100 rounded"
                  title={t('view_permissions')}
                >
                  <Eye className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );

  const renderPermissionsManagement = () => (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {permissions.map(permission => {
        const displayName = language === 'ru' ? permission.nameRu || permission.name : permission.nameEn || permission.name;
        
        return (
          <div key={permission.id} className="p-4 border border-gray-200 rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center space-x-2">
                <Key className="w-4 h-4 text-blue-500" />
                <span className="font-medium">{displayName}</span>
                {permission.isSystemPermission && (
                  <Shield className="w-4 h-4 text-red-500" title={t('system_permission')} />
                )}
                {permission.requiresApproval && (
                  <AlertTriangle className="w-4 h-4 text-yellow-500" title={t('requires_approval')} />
                )}
              </div>
              <span className={`px-2 py-1 rounded text-xs ${getRiskLevelColor(permission.riskLevel)}`}>
                {t(permission.riskLevel)}
              </span>
            </div>
            
            <div className="text-sm text-gray-600 mb-3">{permission.description}</div>
            
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div><span className="text-gray-500">{t('resource')}:</span> {permission.resource}</div>
              <div><span className="text-gray-500">{t('action')}:</span> {permission.action}</div>
              <div><span className="text-gray-500">{t('category')}:</span> {t(permission.category)}</div>
              <div><span className="text-gray-500">{t('scope')}:</span> {t(permission.scope)}</div>
            </div>
            
            {permission.complianceNotes && (
              <div className="mt-2 p-2 bg-blue-50 rounded text-xs text-blue-700">
                <FileText className="w-3 h-3 inline mr-1" />
                {permission.complianceNotes}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );

  const renderUserAssignments = () => (
    <div className="space-y-4">
      {userAssignments.map(assignment => (
        <div key={assignment.id} className="p-4 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <UserCheck className="w-5 h-5 text-green-500" />
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-medium text-lg">{assignment.userName}</span>
                  <span className={`px-2 py-1 rounded text-xs ${getStatusColor(assignment.status)}`}>
                    {t(assignment.status)}
                  </span>
                </div>
                <div className="text-sm text-gray-600">{assignment.userEmail}</div>
                <div className="flex items-center space-x-4 mt-1 text-xs text-gray-500">
                  <span>{t('department')}: {assignment.department}</span>
                  <span>{t('position')}: {assignment.position}</span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <div className="font-medium text-blue-600">{assignment.roleName}</div>
              <div className="text-sm text-gray-600">
                {t('assigned_by')}: {assignment.assignedBy}
              </div>
              <div className="text-xs text-gray-500">
                {t('assigned_at')}: {new Date(assignment.assignedAt).toLocaleDateString()}
              </div>
              {assignment.expiresAt && (
                <div className="text-xs text-orange-600">
                  {t('expires_at')}: {new Date(assignment.expiresAt).toLocaleDateString()}
                </div>
              )}
            </div>
          </div>
          
          <div className="mt-3 flex justify-between items-center text-sm">
            <div className="text-gray-600">
              {t('reason')}: {assignment.reason}
            </div>
            <div className="flex space-x-4 text-xs text-gray-500">
              <span>{t('last_access')}: {assignment.lastAccess ? new Date(assignment.lastAccess).toLocaleString() : 'Never'}</span>
              <span>{t('access_count')}: {assignment.accessCount}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  const renderAuditLog = () => (
    <div className="space-y-3">
      {auditLog.map(log => (
        <div key={log.id} className={`p-4 border-l-4 rounded-r-lg ${
          log.riskLevel === 'critical' ? 'border-red-500 bg-red-50' :
          log.riskLevel === 'high' ? 'border-orange-500 bg-orange-50' :
          log.riskLevel === 'medium' ? 'border-yellow-500 bg-yellow-50' :
          'border-blue-500 bg-blue-50'
        }`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              {log.action === 'violation' && <AlertTriangle className="w-5 h-5 text-red-500" />}
              {log.action === 'create' && <Plus className="w-5 h-5 text-green-500" />}
              {log.action === 'modify' && <Edit3 className="w-5 h-5 text-blue-500" />}
              {log.action === 'delete' && <Trash2 className="w-5 h-5 text-red-500" />}
              {log.action === 'assign' && <UserCheck className="w-5 h-5 text-green-500" />}
              {log.action === 'revoke' && <UserX className="w-5 h-5 text-red-500" />}
              {log.action === 'access' && <Eye className="w-5 h-5 text-gray-500" />}
              
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-medium">{log.actor}</span>
                  <span className="text-gray-400">→</span>
                  <span className="text-gray-700">{log.target}</span>
                  <span className={`px-2 py-1 rounded text-xs ${getRiskLevelColor(log.riskLevel)}`}>
                    {t(log.riskLevel)}
                  </span>
                </div>
                <div className="text-sm text-gray-600">{log.details}</div>
              </div>
            </div>
            <div className="text-right text-xs text-gray-500">
              <div>{new Date(log.timestamp).toLocaleString()}</div>
              {log.ipAddress && <div>IP: {log.ipAddress}</div>}
              {log.complianceImpact && (
                <div className="text-orange-600 font-medium">
                  {t('compliance_impact')}: {t('yes')}
                </div>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="w-8 h-8 animate-spin text-blue-500" />
        <span className="ml-2">Загрузка данных RBAC...</span>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Shield className="w-8 h-8 text-red-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {t('role_access_control')}
                </h1>
                <p className="text-gray-600">
                  Управление {roles.length} ролями, {permissions.length} разрешениями, {userAssignments.length} назначениями
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              <button
                onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
                className="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Globe className="w-4 h-4 mr-2" />
                {language.toUpperCase()}
              </button>
              <button className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                <Download className="w-4 h-4" />
                <span>{t('export_data')}</span>
              </button>
              <button 
                onClick={() => setIsLoading(true)}
                className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <RefreshCw className="w-4 h-4" />
                <span>{t('refresh_data')}</span>
              </button>
            </div>
          </div>
        </div>

        {/* Security Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <Users className="w-5 h-5 text-blue-500" />
              <span className="text-sm text-gray-600">Всего ролей</span>
            </div>
            <div className="text-2xl font-bold text-blue-600">{roles.length}</div>
            <div className="text-xs text-gray-500">
              Активных: {roles.filter(r => r.isActive).length}
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <Key className="w-5 h-5 text-green-500" />
              <span className="text-sm text-gray-600">Разрешений</span>
            </div>
            <div className="text-2xl font-bold text-green-600">{permissions.length}</div>
            <div className="text-xs text-gray-500">
              Системных: {permissions.filter(p => p.isSystemPermission).length}
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <UserCheck className="w-5 h-5 text-purple-500" />
              <span className="text-sm text-gray-600">Назначений</span>
            </div>
            <div className="text-2xl font-bold text-purple-600">{userAssignments.length}</div>
            <div className="text-xs text-gray-500">
              Активных: {userAssignments.filter(a => a.status === 'active').length}
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              <span className="text-sm text-gray-600">{t('security_violations')}</span>
            </div>
            <div className="text-2xl font-bold text-red-600">
              {auditLog.filter(log => log.action === 'violation').length}
            </div>
            <div className="text-xs text-gray-500">
              За сегодня
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex space-x-8 px-6">
              {[
                { id: 'roles', label: t('roles_management'), icon: Users },
                { id: 'permissions', label: t('permissions_management'), icon: Key },
                { id: 'assignments', label: t('user_assignments'), icon: UserCheck },
                { id: 'audit', label: t('audit_log'), icon: Activity }
              ].map(tab => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as any)}
                    className={`flex items-center space-x-2 py-4 border-b-2 font-medium text-sm ${
                      activeTab === tab.id
                        ? 'border-red-500 text-red-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Filters */}
        {activeTab === 'roles' && (
          <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
            <div className="flex items-center space-x-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    placeholder={t('search_roles')}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
              </div>
              
              <div className="flex items-center space-x-2">
                <Filter className="w-5 h-5 text-gray-400" />
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                >
                  <option value="all">{t('all_types')}</option>
                  <option value="system">{t('system')}</option>
                  <option value="business">{t('business')}</option>
                  <option value="custom">{t('custom')}</option>
                  <option value="temporary">{t('temporary')}</option>
                </select>
              </div>
              
              <button className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
                <Plus className="w-4 h-4" />
                <span>{t('add_role')}</span>
              </button>
            </div>
          </div>
        )}

        {/* Content */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          {activeTab === 'roles' && renderRolesManagement()}
          {activeTab === 'permissions' && renderPermissionsManagement()}
          {activeTab === 'assignments' && renderUserAssignments()}
          {activeTab === 'audit' && renderAuditLog()}
        </div>

        {/* Selected Role Details Modal */}
        {selectedRole && !isEditModalOpen && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-semibold">
                    {language === 'ru' ? selectedRole.nameRu || selectedRole.name : selectedRole.nameEn || selectedRole.name}
                  </h3>
                  <button
                    onClick={() => setSelectedRole(null)}
                    className="p-2 hover:bg-gray-100 rounded-lg"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>
              
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Детали роли</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="text-gray-600">Тип:</span> {t(selectedRole.type)}</div>
                      <div><span className="text-gray-600">Уровень:</span> {selectedRole.level}</div>
                      <div><span className="text-gray-600">Статус:</span> {selectedRole.isActive ? t('active') : t('inactive')}</div>
                      <div><span className="text-gray-600">Наследуемая:</span> {selectedRole.isInherited ? t('yes') : t('no')}</div>
                      <div><span className="text-gray-600">Создано:</span> {selectedRole.createdBy}</div>
                      <div><span className="text-gray-600">Дата создания:</span> {new Date(selectedRole.createdAt).toLocaleDateString()}</div>
                      {selectedRole.expiresAt && (
                        <div><span className="text-gray-600">Истекает:</span> {new Date(selectedRole.expiresAt).toLocaleDateString()}</div>
                      )}
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Разрешения ({selectedRole.permissions.length})</h4>
                    <div className="space-y-1 text-sm max-h-40 overflow-y-auto">
                      {selectedRole.permissions.map(permId => {
                        const permission = permissions.find(p => p.id === permId);
                        if (!permission) return null;
                        const displayName = language === 'ru' ? permission.nameRu || permission.name : permission.nameEn || permission.name;
                        return (
                          <div key={permId} className="flex items-center space-x-2">
                            <Key className="w-3 h-3 text-blue-500" />
                            <span>{displayName}</span>
                            <span className={`px-1 py-0.5 rounded text-xs ${getRiskLevelColor(permission.riskLevel)}`}>
                              {t(permission.riskLevel)}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec29RoleAccessControl;