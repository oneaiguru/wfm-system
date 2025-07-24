import React, { useState, useEffect } from 'react';
import {
  Settings,
  Server,
  Database,
  Users,
  Shield,
  Activity,
  Cpu,
  Memory,
  HardDrive,
  Network,
  Globe,
  Lock,
  Key,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Clock,
  TrendingUp,
  TrendingDown,
  BarChart3,
  Gauge,
  Zap,
  Bell,
  Eye,
  EyeOff,
  RefreshCw,
  Download,
  Upload,
  Search,
  Filter,
  Plus,
  Edit3,
  Trash2,
  Save,
  X,
  FileText,
  Calendar,
  User,
  UserCheck,
  UserX,
  Mail,
  Phone,
  MapPin,
  Building,
  Briefcase,
  Award,
  Flag,
  AlertCircle
} from 'lucide-react';

// SPEC-18: System Administration & Configuration
// Enhanced from SystemHealthDashboard.tsx, UserPermissions.tsx, SystemSettings.tsx with 90% reuse
// Focus: System administration console for administrators and super admins (5-8 daily users)

interface Spec18SystemHealth {
  component: string;
  status: 'healthy' | 'warning' | 'critical' | 'offline';
  metrics: {
    responseTime: number;
    uptimePercentage: number;
    errorRate: number;
    throughput: number;
  };
  details: {
    cpuUsage?: number;
    memoryUsage?: number;
    diskUsage?: number;
    activeConnections?: number;
    lastCheck: string;
  };
  threshold: {
    responseTime: number;
    uptime: number;
    errorRate: number;
  };
  actions: string[];
}

interface Spec18UserAccount {
  id: string;
  username: string;
  email: string;
  fullName: string;
  fullNameRu?: string; // Russian full name
  fullNameEn?: string; // English full name
  status: 'active' | 'inactive' | 'locked' | 'pending';
  role: string;
  department: string;
  position: string;
  lastLogin: string;
  createdAt: string;
  permissions: string[];
  twoFactorEnabled: boolean;
  failedLoginAttempts: number;
  accountLocked: boolean;
  lockReason?: string;
  passwordLastChanged: string;
  sessionCount: number;
}

interface Spec18SystemConfig {
  id: string;
  category: string;
  key: string;
  value: string;
  displayName: string;
  displayNameRu?: string;
  displayNameEn?: string;
  description: string;
  dataType: 'string' | 'number' | 'boolean' | 'array' | 'object';
  isReadonly: boolean;
  requiresRestart: boolean;
  validationRule?: string;
  lastModified: string;
  modifiedBy: string;
  environment: 'development' | 'staging' | 'production';
  securityLevel: 'public' | 'internal' | 'confidential' | 'restricted';
}

interface Spec18AuditEvent {
  id: string;
  timestamp: string;
  eventType: 'login' | 'logout' | 'config_change' | 'user_create' | 'user_modify' | 'permission_change' | 'system_restart' | 'backup' | 'security_violation';
  actor: string;
  target: string;
  action: string;
  details: string;
  ipAddress: string;
  userAgent?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  success: boolean;
  duration?: number;
  affectedObjects?: string[];
}

interface Spec18SystemMetric {
  name: string;
  nameRu?: string;
  nameEn?: string;
  currentValue: number;
  previousValue: number;
  threshold: number;
  unit: string;
  trend: 'up' | 'down' | 'stable';
  trendPercentage: number;
  status: 'normal' | 'warning' | 'critical';
  lastUpdated: string;
}

const Spec18SystemAdministration: React.FC = () => {
  const [systemHealth, setSystemHealth] = useState<Spec18SystemHealth[]>([]);
  const [userAccounts, setUserAccounts] = useState<Spec18UserAccount[]>([]);
  const [systemConfigs, setSystemConfigs] = useState<Spec18SystemConfig[]>([]);
  const [auditEvents, setAuditEvents] = useState<Spec18AuditEvent[]>([]);
  const [systemMetrics, setSystemMetrics] = useState<Spec18SystemMetric[]>([]);
  const [activeTab, setActiveTab] = useState<'dashboard' | 'users' | 'config' | 'audit' | 'monitoring'>('dashboard');
  const [selectedUser, setSelectedUser] = useState<Spec18UserAccount | null>(null);
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [isLoading, setIsLoading] = useState(true);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Demo data initialization
  useEffect(() => {
    const demoSystemHealth: Spec18SystemHealth[] = [
      {
        component: 'Database Server',
        status: 'healthy',
        metrics: {
          responseTime: 45,
          uptimePercentage: 99.8,
          errorRate: 0.1,
          throughput: 1245
        },
        details: {
          cpuUsage: 32,
          memoryUsage: 67,
          diskUsage: 45,
          activeConnections: 145,
          lastCheck: '2025-07-21T14:35:00Z'
        },
        threshold: {
          responseTime: 100,
          uptime: 99.0,
          errorRate: 5.0
        },
        actions: ['Monitor', 'Optimize Queries']
      },
      {
        component: 'API Server',
        status: 'healthy',
        metrics: {
          responseTime: 85,
          uptimePercentage: 99.2,
          errorRate: 0.8,
          throughput: 2456
        },
        details: {
          cpuUsage: 54,
          memoryUsage: 78,
          diskUsage: 32,
          activeConnections: 89,
          lastCheck: '2025-07-21T14:34:30Z'
        },
        threshold: {
          responseTime: 200,
          uptime: 98.0,
          errorRate: 2.0
        },
        actions: ['Monitor', 'Scale Up']
      },
      {
        component: 'Integration Services',
        status: 'warning',
        metrics: {
          responseTime: 234,
          uptimePercentage: 97.5,
          errorRate: 3.2,
          throughput: 456
        },
        details: {
          cpuUsage: 78,
          memoryUsage: 85,
          diskUsage: 56,
          activeConnections: 34,
          lastCheck: '2025-07-21T14:33:45Z'
        },
        threshold: {
          responseTime: 200,
          uptime: 98.0,
          errorRate: 2.0
        },
        actions: ['Investigate', 'Restart Service', 'Check Logs']
      },
      {
        component: 'File Storage',
        status: 'critical',
        metrics: {
          responseTime: 156,
          uptimePercentage: 99.1,
          errorRate: 0.5,
          throughput: 789
        },
        details: {
          cpuUsage: 45,
          memoryUsage: 56,
          diskUsage: 92,
          activeConnections: 67,
          lastCheck: '2025-07-21T14:34:15Z'
        },
        threshold: {
          responseTime: 150,
          uptime: 99.0,
          errorRate: 1.0
        },
        actions: ['URGENT', 'Clean Up Disk', 'Archive Old Files', 'Add Storage']
      },
      {
        component: 'Security Gateway',
        status: 'healthy',
        metrics: {
          responseTime: 12,
          uptimePercentage: 99.9,
          errorRate: 0.01,
          throughput: 3456
        },
        details: {
          cpuUsage: 23,
          memoryUsage: 34,
          diskUsage: 28,
          activeConnections: 234,
          lastCheck: '2025-07-21T14:35:12Z'
        },
        threshold: {
          responseTime: 50,
          uptime: 99.5,
          errorRate: 0.1
        },
        actions: ['Monitor', 'Update Rules']
      }
    ];

    const demoUserAccounts: Spec18UserAccount[] = [
      {
        id: 'user-001',
        username: 'ivan.petrov',
        email: 'ivan.petrov@company.ru',
        fullName: 'Иван Петров',
        fullNameRu: 'Иван Петров',
        fullNameEn: 'Ivan Petrov',
        status: 'active',
        role: 'System Administrator',
        department: 'IT',
        position: 'Senior System Administrator',
        lastLogin: '2025-07-21T14:30:00Z',
        createdAt: '2025-01-15T10:00:00Z',
        permissions: ['admin_full', 'user_manage', 'system_config', 'backup_manage'],
        twoFactorEnabled: true,
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordLastChanged: '2025-07-01T09:00:00Z',
        sessionCount: 3
      },
      {
        id: 'user-002',
        username: 'maria.kozlova',
        email: 'maria.kozlova@company.ru',
        fullName: 'Мария Козлова',
        fullNameRu: 'Мария Козлова',
        fullNameEn: 'Maria Kozlova',
        status: 'active',
        role: 'HR Manager',
        department: 'Human Resources',
        position: 'HR Manager',
        lastLogin: '2025-07-21T13:45:00Z',
        createdAt: '2025-01-20T11:00:00Z',
        permissions: ['employee_view', 'employee_edit', 'schedule_manage', 'report_access'],
        twoFactorEnabled: true,
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordLastChanged: '2025-06-15T14:00:00Z',
        sessionCount: 2
      },
      {
        id: 'user-003',
        username: 'alex.sidorov',
        email: 'alex.sidorov@company.ru',
        fullName: 'Алексей Сидоров',
        fullNameRu: 'Алексей Сидоров',
        fullNameEn: 'Alexey Sidorov',
        status: 'locked',
        role: 'Team Lead',
        department: 'Customer Service',
        position: 'Team Leader',
        lastLogin: '2025-07-20T16:30:00Z',
        createdAt: '2025-02-01T09:00:00Z',
        permissions: ['team_manage', 'schedule_view', 'report_team'],
        twoFactorEnabled: false,
        failedLoginAttempts: 5,
        accountLocked: true,
        lockReason: 'Превышено количество попыток входа',
        passwordLastChanged: '2025-03-10T12:00:00Z',
        sessionCount: 0
      },
      {
        id: 'user-004',
        username: 'olga.nikitina',
        email: 'olga.nikitina@company.ru',
        fullName: 'Ольга Никитина',
        fullNameRu: 'Ольга Никитина',
        fullNameEn: 'Olga Nikitina',
        status: 'pending',
        role: 'Employee',
        department: 'Finance',
        position: 'Accountant',
        lastLogin: '',
        createdAt: '2025-07-21T10:00:00Z',
        permissions: ['profile_view', 'schedule_view'],
        twoFactorEnabled: false,
        failedLoginAttempts: 0,
        accountLocked: false,
        passwordLastChanged: '',
        sessionCount: 0
      }
    ];

    const demoSystemConfigs: Spec18SystemConfig[] = [
      {
        id: 'config-001',
        category: 'Authentication',
        key: 'session_timeout',
        value: '28800',
        displayName: 'Session Timeout (seconds)',
        displayNameRu: 'Тайм-аут сессии (секунды)',
        displayNameEn: 'Session Timeout (seconds)',
        description: 'Maximum session duration before automatic logout',
        dataType: 'number',
        isReadonly: false,
        requiresRestart: false,
        validationRule: 'min:300,max:86400',
        lastModified: '2025-07-15T14:30:00Z',
        modifiedBy: 'ivan.petrov',
        environment: 'production',
        securityLevel: 'internal'
      },
      {
        id: 'config-002',
        category: 'Security',
        key: 'max_failed_login_attempts',
        value: '5',
        displayName: 'Maximum Failed Login Attempts',
        displayNameRu: 'Максимум неудачных попыток входа',
        displayNameEn: 'Maximum Failed Login Attempts',
        description: 'Number of failed attempts before account lockout',
        dataType: 'number',
        isReadonly: false,
        requiresRestart: false,
        validationRule: 'min:3,max:10',
        lastModified: '2025-07-10T11:00:00Z',
        modifiedBy: 'maria.kozlova',
        environment: 'production',
        securityLevel: 'confidential'
      },
      {
        id: 'config-003',
        category: 'Database',
        key: 'connection_pool_size',
        value: '50',
        displayName: 'Database Connection Pool Size',
        displayNameRu: 'Размер пула соединений БД',
        displayNameEn: 'Database Connection Pool Size',
        description: 'Maximum number of database connections in pool',
        dataType: 'number',
        isReadonly: false,
        requiresRestart: true,
        validationRule: 'min:10,max:200',
        lastModified: '2025-07-01T16:45:00Z',
        modifiedBy: 'ivan.petrov',
        environment: 'production',
        securityLevel: 'internal'
      },
      {
        id: 'config-004',
        category: 'System',
        key: 'backup_retention_days',
        value: '90',
        displayName: 'Backup Retention Period (days)',
        displayNameRu: 'Период хранения резервных копий (дни)',
        displayNameEn: 'Backup Retention Period (days)',
        description: 'Number of days to retain system backups',
        dataType: 'number',
        isReadonly: false,
        requiresRestart: false,
        validationRule: 'min:7,max:365',
        lastModified: '2025-06-20T13:15:00Z',
        modifiedBy: 'ivan.petrov',
        environment: 'production',
        securityLevel: 'internal'
      },
      {
        id: 'config-005',
        category: 'Notifications',
        key: 'email_smtp_server',
        value: 'smtp.company.ru',
        displayName: 'SMTP Server Address',
        displayNameRu: 'Адрес SMTP сервера',
        displayNameEn: 'SMTP Server Address',
        description: 'Email server configuration for system notifications',
        dataType: 'string',
        isReadonly: false,
        requiresRestart: true,
        validationRule: 'required,domain',
        lastModified: '2025-05-15T10:30:00Z',
        modifiedBy: 'ivan.petrov',
        environment: 'production',
        securityLevel: 'restricted'
      }
    ];

    const demoAuditEvents: Spec18AuditEvent[] = [
      {
        id: 'audit-001',
        timestamp: '2025-07-21T14:35:22Z',
        eventType: 'config_change',
        actor: 'ivan.petrov',
        target: 'System Configuration',
        action: 'Modified session_timeout from 7200 to 28800',
        details: 'Updated session timeout configuration for improved security',
        ipAddress: '192.168.1.100',
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        severity: 'medium',
        success: true,
        duration: 245,
        affectedObjects: ['session_timeout']
      },
      {
        id: 'audit-002',
        timestamp: '2025-07-21T14:30:15Z',
        eventType: 'login',
        actor: 'ivan.petrov',
        target: 'System Administration Panel',
        action: 'Successful admin login',
        details: 'Administrator logged into system administration interface',
        ipAddress: '192.168.1.100',
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        severity: 'low',
        success: true,
        duration: 1250
      },
      {
        id: 'audit-003',
        timestamp: '2025-07-21T14:25:45Z',
        eventType: 'user_modify',
        actor: 'maria.kozlova',
        target: 'User: alex.sidorov',
        action: 'Account locked due to failed login attempts',
        details: 'User account automatically locked after 5 failed login attempts',
        ipAddress: '192.168.1.105',
        severity: 'high',
        success: true,
        affectedObjects: ['alex.sidorov']
      },
      {
        id: 'audit-004',
        timestamp: '2025-07-21T14:20:33Z',
        eventType: 'security_violation',
        actor: 'unknown',
        target: 'Authentication System',
        action: 'Multiple failed login attempts detected',
        details: 'Suspicious login activity detected from IP 203.0.113.45',
        ipAddress: '203.0.113.45',
        userAgent: 'curl/7.68.0',
        severity: 'critical',
        success: false,
        duration: 5000
      },
      {
        id: 'audit-005',
        timestamp: '2025-07-21T14:15:12Z',
        eventType: 'user_create',
        actor: 'maria.kozlova',
        target: 'User: olga.nikitina',
        action: 'Created new user account',
        details: 'New employee account created for Finance department',
        ipAddress: '192.168.1.105',
        severity: 'low',
        success: true,
        duration: 890,
        affectedObjects: ['olga.nikitina']
      }
    ];

    const demoSystemMetrics: Spec18SystemMetric[] = [
      {
        name: 'CPU Usage',
        nameRu: 'Использование CPU',
        nameEn: 'CPU Usage',
        currentValue: 34.5,
        previousValue: 32.1,
        threshold: 80,
        unit: '%',
        trend: 'up',
        trendPercentage: 7.5,
        status: 'normal',
        lastUpdated: '2025-07-21T14:35:00Z'
      },
      {
        name: 'Memory Usage',
        nameRu: 'Использование памяти',
        nameEn: 'Memory Usage',
        currentValue: 67.8,
        previousValue: 65.2,
        threshold: 85,
        unit: '%',
        trend: 'up',
        trendPercentage: 4.0,
        status: 'normal',
        lastUpdated: '2025-07-21T14:35:00Z'
      },
      {
        name: 'Disk Usage',
        nameRu: 'Использование диска',
        nameEn: 'Disk Usage',
        currentValue: 92.3,
        previousValue: 89.1,
        threshold: 90,
        unit: '%',
        trend: 'up',
        trendPercentage: 3.6,
        status: 'critical',
        lastUpdated: '2025-07-21T14:35:00Z'
      },
      {
        name: 'Network Throughput',
        nameRu: 'Пропускная способность сети',
        nameEn: 'Network Throughput',
        currentValue: 1245.7,
        previousValue: 1189.3,
        threshold: 2000,
        unit: 'Mbps',
        trend: 'up',
        trendPercentage: 4.7,
        status: 'normal',
        lastUpdated: '2025-07-21T14:35:00Z'
      },
      {
        name: 'Active Sessions',
        nameRu: 'Активные сессии',
        nameEn: 'Active Sessions',
        currentValue: 145,
        previousValue: 152,
        threshold: 500,
        unit: 'sessions',
        trend: 'down',
        trendPercentage: -4.6,
        status: 'normal',
        lastUpdated: '2025-07-21T14:35:00Z'
      }
    ];

    setSystemHealth(demoSystemHealth);
    setUserAccounts(demoUserAccounts);
    setSystemConfigs(demoSystemConfigs);
    setAuditEvents(demoAuditEvents);
    setSystemMetrics(demoSystemMetrics);
    setIsLoading(false);

    // Auto-refresh setup
    const interval = setInterval(() => {
      if (autoRefresh && activeTab === 'dashboard') {
        // Simulate metric updates
        setSystemMetrics(prev => prev.map(metric => ({
          ...metric,
          previousValue: metric.currentValue,
          currentValue: metric.currentValue + (Math.random() - 0.5) * 5,
          lastUpdated: new Date().toISOString()
        })));
      }
    }, 30000); // 30 seconds

    return () => clearInterval(interval);
  }, [autoRefresh, activeTab]);

  const t = (key: string): string => {
    const translations: Record<string, Record<string, string>> = {
      ru: {
        'system_administration': 'Системное администрирование',
        'system_dashboard': 'Панель системы',
        'user_management': 'Управление пользователями',
        'system_configuration': 'Конфигурация системы',
        'audit_log': 'Журнал аудита',
        'system_monitoring': 'Мониторинг системы',
        'system_health': 'Состояние системы',
        'performance_metrics': 'Метрики производительности',
        'security_status': 'Статус безопасности',
        'component': 'Компонент',
        'status': 'Статус',
        'response_time': 'Время отклика',
        'uptime': 'Время работы',
        'error_rate': 'Частота ошибок',
        'throughput': 'Пропускная способность',
        'cpu_usage': 'Использование CPU',
        'memory_usage': 'Использование памяти',
        'disk_usage': 'Использование диска',
        'active_connections': 'Активные соединения',
        'last_check': 'Последняя проверка',
        'actions': 'Действия',
        'healthy': 'Исправен',
        'warning': 'Предупреждение',
        'critical': 'Критический',
        'offline': 'Отключен',
        'username': 'Имя пользователя',
        'email': 'Email',
        'full_name': 'Полное имя',
        'role': 'Роль',
        'department': 'Отдел',
        'position': 'Должность',
        'last_login': 'Последний вход',
        'created_at': 'Дата создания',
        'active': 'Активен',
        'inactive': 'Неактивен',
        'locked': 'Заблокирован',
        'pending': 'Ожидание',
        'two_factor_enabled': '2FA включена',
        'failed_attempts': 'Неудачные попытки',
        'account_locked': 'Аккаунт заблокирован',
        'sessions': 'Сессии',
        'edit_user': 'Редактировать пользователя',
        'delete_user': 'Удалить пользователя',
        'unlock_user': 'Разблокировать пользователя',
        'reset_password': 'Сбросить пароль',
        'add_user': 'Добавить пользователя',
        'search_users': 'Поиск пользователей...',
        'filter_by_status': 'Фильтр по статусу',
        'all_statuses': 'Все статусы',
        'category': 'Категория',
        'key': 'Ключ',
        'value': 'Значение',
        'display_name': 'Отображаемое имя',
        'description': 'Описание',
        'data_type': 'Тип данных',
        'readonly': 'Только чтение',
        'requires_restart': 'Требует перезапуска',
        'last_modified': 'Последнее изменение',
        'modified_by': 'Изменено кем',
        'environment': 'Среда',
        'security_level': 'Уровень безопасности',
        'timestamp': 'Время',
        'event_type': 'Тип события',
        'actor': 'Инициатор',
        'target': 'Цель',
        'action': 'Действие',
        'details': 'Детали',
        'ip_address': 'IP адрес',
        'severity': 'Важность',
        'success': 'Успех',
        'duration': 'Длительность',
        'low': 'Низкая',
        'medium': 'Средняя',
        'high': 'Высокая',
        'critical': 'Критическая',
        'current_value': 'Текущее значение',
        'threshold': 'Порог',
        'trend': 'Тренд',
        'normal': 'Норма',
        'up': 'Вверх',
        'down': 'Вниз',
        'stable': 'Стабильно',
        'yes': 'Да',
        'no': 'Нет',
        'auto_refresh': 'Автообновление',
        'refresh_data': 'Обновить данные',
        'export_data': 'Экспорт данных',
        'close': 'Закрыть',
        'save': 'Сохранить',
        'cancel': 'Отменить'
      },
      en: {
        'system_administration': 'System Administration',
        'system_dashboard': 'System Dashboard',
        'user_management': 'User Management',
        'system_configuration': 'System Configuration',
        'audit_log': 'Audit Log',
        'system_monitoring': 'System Monitoring',
        'system_health': 'System Health',
        'performance_metrics': 'Performance Metrics',
        'security_status': 'Security Status',
        'component': 'Component',
        'status': 'Status',
        'response_time': 'Response Time',
        'uptime': 'Uptime',
        'error_rate': 'Error Rate',
        'throughput': 'Throughput',
        'cpu_usage': 'CPU Usage',
        'memory_usage': 'Memory Usage',
        'disk_usage': 'Disk Usage',
        'active_connections': 'Active Connections',
        'last_check': 'Last Check',
        'actions': 'Actions',
        'healthy': 'Healthy',
        'warning': 'Warning',
        'critical': 'Critical',
        'offline': 'Offline',
        'username': 'Username',
        'email': 'Email',
        'full_name': 'Full Name',
        'role': 'Role',
        'department': 'Department',
        'position': 'Position',
        'last_login': 'Last Login',
        'created_at': 'Created At',
        'active': 'Active',
        'inactive': 'Inactive',
        'locked': 'Locked',
        'pending': 'Pending',
        'two_factor_enabled': '2FA Enabled',
        'failed_attempts': 'Failed Attempts',
        'account_locked': 'Account Locked',
        'sessions': 'Sessions',
        'edit_user': 'Edit User',
        'delete_user': 'Delete User',
        'unlock_user': 'Unlock User',
        'reset_password': 'Reset Password',
        'add_user': 'Add User',
        'search_users': 'Search users...',
        'filter_by_status': 'Filter by Status',
        'all_statuses': 'All Statuses',
        'category': 'Category',
        'key': 'Key',
        'value': 'Value',
        'display_name': 'Display Name',
        'description': 'Description',
        'data_type': 'Data Type',
        'readonly': 'Read Only',
        'requires_restart': 'Requires Restart',
        'last_modified': 'Last Modified',
        'modified_by': 'Modified By',
        'environment': 'Environment',
        'security_level': 'Security Level',
        'timestamp': 'Timestamp',
        'event_type': 'Event Type',
        'actor': 'Actor',
        'target': 'Target',
        'action': 'Action',
        'details': 'Details',
        'ip_address': 'IP Address',
        'severity': 'Severity',
        'success': 'Success',
        'duration': 'Duration',
        'low': 'Low',
        'medium': 'Medium',
        'high': 'High',
        'critical': 'Critical',
        'current_value': 'Current Value',
        'threshold': 'Threshold',
        'trend': 'Trend',
        'normal': 'Normal',
        'up': 'Up',
        'down': 'Down',
        'stable': 'Stable',
        'yes': 'Yes',
        'no': 'No',
        'auto_refresh': 'Auto Refresh',
        'refresh_data': 'Refresh Data',
        'export_data': 'Export Data',
        'close': 'Close',
        'save': 'Save',
        'cancel': 'Cancel'
      }
    };
    return translations[language][key] || key;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
      case 'active':
      case 'normal': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'warning': return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'critical': return <XCircle className="w-4 h-4 text-red-500" />;
      case 'offline':
      case 'inactive':
      case 'locked': return <XCircle className="w-4 h-4 text-gray-400" />;
      case 'pending': return <Clock className="w-4 h-4 text-blue-500" />;
      default: return <AlertCircle className="w-4 h-4 text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
      case 'active':
      case 'normal': return 'text-green-600 bg-green-50';
      case 'warning': return 'text-yellow-600 bg-yellow-50';
      case 'critical': return 'text-red-600 bg-red-50';
      case 'offline':
      case 'inactive': return 'text-gray-600 bg-gray-50';
      case 'locked': return 'text-red-600 bg-red-50';
      case 'pending': return 'text-blue-600 bg-blue-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'text-green-600 bg-green-50';
      case 'medium': return 'text-yellow-600 bg-yellow-50';
      case 'high': return 'text-orange-600 bg-orange-50';
      case 'critical': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <TrendingUp className="w-4 h-4 text-red-500" />;
      case 'down': return <TrendingDown className="w-4 h-4 text-green-500" />;
      case 'stable': return <BarChart3 className="w-4 h-4 text-gray-400" />;
      default: return <BarChart3 className="w-4 h-4 text-gray-400" />;
    }
  };

  const filteredUsers = userAccounts.filter(user => {
    const matchesSearch = 
      user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (user.fullNameRu && user.fullNameRu.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesStatus = filterStatus === 'all' || user.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const renderSystemDashboard = () => (
    <div className="space-y-6">
      {/* System Health Overview */}
      <div>
        <h3 className="text-lg font-semibold mb-4">{t('system_health')}</h3>
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {systemHealth.map(component => (
            <div key={component.component} className="p-4 border border-gray-200 rounded-lg">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center space-x-2">
                  <Server className="w-5 h-5 text-blue-500" />
                  <span className="font-medium">{component.component}</span>
                </div>
                <div className="flex items-center space-x-2">
                  {getStatusIcon(component.status)}
                  <span className={`px-2 py-1 rounded text-xs ${getStatusColor(component.status)}`}>
                    {t(component.status)}
                  </span>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-2 text-sm mb-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">{t('response_time')}:</span>
                  <span className={component.metrics.responseTime > component.threshold.responseTime ? 'text-red-600' : 'text-green-600'}>
                    {component.metrics.responseTime}ms
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">{t('uptime')}:</span>
                  <span className={component.metrics.uptimePercentage < component.threshold.uptime ? 'text-red-600' : 'text-green-600'}>
                    {component.metrics.uptimePercentage}%
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">{t('error_rate')}:</span>
                  <span className={component.metrics.errorRate > component.threshold.errorRate ? 'text-red-600' : 'text-green-600'}>
                    {component.metrics.errorRate}%
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">{t('throughput')}:</span>
                  <span className="text-blue-600">{component.metrics.throughput}/min</span>
                </div>
              </div>
              
              {component.details && (
                <div className="grid grid-cols-2 gap-2 text-xs text-gray-500 mb-3">
                  {component.details.cpuUsage && (
                    <div>CPU: {component.details.cpuUsage}%</div>
                  )}
                  {component.details.memoryUsage && (
                    <div>Memory: {component.details.memoryUsage}%</div>
                  )}
                  {component.details.diskUsage && (
                    <div>Disk: {component.details.diskUsage}%</div>
                  )}
                  {component.details.activeConnections && (
                    <div>Connections: {component.details.activeConnections}</div>
                  )}
                </div>
              )}
              
              <div className="text-xs text-gray-400 mb-2">
                {t('last_check')}: {new Date(component.details.lastCheck).toLocaleString()}
              </div>
              
              <div className="flex flex-wrap gap-1">
                {component.actions.map((action, index) => (
                  <button
                    key={index}
                    className={`px-2 py-1 text-xs rounded ${
                      action === 'URGENT' ? 'bg-red-100 text-red-700' :
                      action.includes('Monitor') ? 'bg-blue-100 text-blue-700' :
                      'bg-gray-100 text-gray-700'
                    } hover:bg-opacity-80`}
                  >
                    {action}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
      
      {/* Performance Metrics */}
      <div>
        <h3 className="text-lg font-semibold mb-4">{t('performance_metrics')}</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          {systemMetrics.map(metric => {
            const displayName = language === 'ru' ? metric.nameRu || metric.name : metric.nameEn || metric.name;
            return (
              <div key={metric.name} className="p-4 bg-white border border-gray-200 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600">{displayName}</span>
                  <div className="flex items-center space-x-1">
                    {getTrendIcon(metric.trend)}
                    <span className={`text-xs ${metric.trend === 'up' ? 'text-red-500' : metric.trend === 'down' ? 'text-green-500' : 'text-gray-500'}`}>
                      {metric.trendPercentage > 0 ? '+' : ''}{metric.trendPercentage.toFixed(1)}%
                    </span>
                  </div>
                </div>
                <div className="text-2xl font-bold mb-1">
                  <span className={metric.status === 'critical' ? 'text-red-600' : metric.status === 'warning' ? 'text-yellow-600' : 'text-green-600'}>
                    {metric.currentValue.toFixed(1)}
                  </span>
                  <span className="text-sm text-gray-500 ml-1">{metric.unit}</span>
                </div>
                <div className="flex justify-between text-xs text-gray-500">
                  <span>Threshold: {metric.threshold}{metric.unit}</span>
                  <span className={`px-1 rounded ${getStatusColor(metric.status)}`}>
                    {t(metric.status)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );

  const renderUserManagement = () => (
    <div className="space-y-4">
      {filteredUsers.map(user => {
        const displayName = language === 'ru' ? user.fullNameRu || user.fullName : user.fullNameEn || user.fullName;
        return (
          <div key={user.id} className="p-4 border border-gray-200 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <UserCheck className="w-5 h-5 text-blue-500" />
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-medium text-lg">{displayName}</span>
                    <span className="text-gray-500">({user.username})</span>
                    <span className={`px-2 py-1 rounded text-xs ${getStatusColor(user.status)}`}>
                      {t(user.status)}
                    </span>
                    {user.twoFactorEnabled && (
                      <Shield className="w-4 h-4 text-green-500" title="2FA Enabled" />
                    )}
                    {user.accountLocked && (
                      <Lock className="w-4 h-4 text-red-500" title="Account Locked" />
                    )}
                  </div>
                  <div className="text-sm text-gray-600">{user.email}</div>
                  <div className="flex items-center space-x-4 mt-1 text-xs text-gray-500">
                    <span>{user.department} - {user.position}</span>
                    <span>{t('role')}: {user.role}</span>
                    <span>{t('sessions')}: {user.sessionCount}</span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-sm text-gray-600">
                  {user.lastLogin ? (
                    <div>{t('last_login')}: {new Date(user.lastLogin).toLocaleString()}</div>
                  ) : (
                    <div className="text-gray-400">Never logged in</div>
                  )}
                  <div>{t('created_at')}: {new Date(user.createdAt).toLocaleDateString()}</div>
                </div>
                <div className="flex space-x-2 mt-2">
                  <button
                    onClick={() => {
                      setSelectedUser(user);
                      setIsUserModalOpen(true);
                    }}
                    className="p-2 hover:bg-gray-100 rounded"
                    title={t('edit_user')}
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>
                  {user.status === 'locked' && (
                    <button className="p-2 hover:bg-gray-100 rounded" title={t('unlock_user')}>
                      <Unlock className="w-4 h-4 text-green-500" />
                    </button>
                  )}
                  <button className="p-2 hover:bg-gray-100 rounded" title={t('reset_password')}>
                    <Key className="w-4 h-4 text-blue-500" />
                  </button>
                </div>
              </div>
            </div>
            
            {user.failedLoginAttempts > 0 && (
              <div className="mt-3 p-2 bg-yellow-50 border border-yellow-200 rounded text-sm">
                <AlertTriangle className="w-4 h-4 text-yellow-500 inline mr-2" />
                {t('failed_attempts')}: {user.failedLoginAttempts}/5
                {user.lockReason && <span className="ml-2 text-red-600">({user.lockReason})</span>}
              </div>
            )}
            
            <div className="mt-3 flex flex-wrap gap-1">
              {user.permissions.map(permission => (
                <span key={permission} className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded">
                  {permission}
                </span>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );

  const renderSystemConfiguration = () => (
    <div className="space-y-4">
      {systemConfigs.map(config => {
        const displayName = language === 'ru' ? config.displayNameRu || config.displayName : config.displayNameEn || config.displayName;
        return (
          <div key={config.id} className="p-4 border border-gray-200 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Settings className="w-5 h-5 text-gray-500" />
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-medium">{displayName}</span>
                    <span className="text-sm text-gray-500">({config.key})</span>
                    {config.isReadonly && (
                      <Lock className="w-4 h-4 text-gray-400" title={t('readonly')} />
                    )}
                    {config.requiresRestart && (
                      <RefreshCw className="w-4 h-4 text-orange-500" title={t('requires_restart')} />
                    )}
                  </div>
                  <div className="text-sm text-gray-600">{config.description}</div>
                  <div className="flex items-center space-x-4 mt-1 text-xs text-gray-500">
                    <span>{t('category')}: {config.category}</span>
                    <span>{t('data_type')}: {config.dataType}</span>
                    <span>{t('environment')}: {config.environment}</span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="font-mono text-lg bg-gray-100 px-2 py-1 rounded">
                  {config.value}
                </div>
                <div className="text-xs text-gray-500 mt-1">
                  <div>{t('last_modified')}: {new Date(config.lastModified).toLocaleString()}</div>
                  <div>{t('modified_by')}: {config.modifiedBy}</div>
                </div>
                <div className="flex space-x-2 mt-2">
                  <button className="p-1 hover:bg-gray-100 rounded" title="Edit">
                    <Edit3 className="w-3 h-3" />
                  </button>
                  <button className="p-1 hover:bg-gray-100 rounded" title="History">
                    <Clock className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
            
            <div className="mt-3 flex items-center space-x-4">
              <span className={`px-2 py-1 rounded text-xs ${
                config.securityLevel === 'restricted' ? 'bg-red-100 text-red-700' :
                config.securityLevel === 'confidential' ? 'bg-orange-100 text-orange-700' :
                config.securityLevel === 'internal' ? 'bg-blue-100 text-blue-700' :
                'bg-gray-100 text-gray-700'
              }`}>
                {config.securityLevel}
              </span>
              {config.validationRule && (
                <span className="text-xs text-gray-500">Validation: {config.validationRule}</span>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );

  const renderAuditLog = () => (
    <div className="space-y-3">
      {auditEvents.map(event => (
        <div key={event.id} className={`p-4 border-l-4 rounded-r-lg ${
          event.severity === 'critical' ? 'border-red-500 bg-red-50' :
          event.severity === 'high' ? 'border-orange-500 bg-orange-50' :
          event.severity === 'medium' ? 'border-yellow-500 bg-yellow-50' :
          'border-blue-500 bg-blue-50'
        }`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              {event.eventType === 'login' && <User className="w-5 h-5 text-green-500" />}
              {event.eventType === 'logout' && <UserX className="w-5 h-5 text-gray-500" />}
              {event.eventType === 'config_change' && <Settings className="w-5 h-5 text-blue-500" />}
              {event.eventType === 'user_create' && <UserCheck className="w-5 h-5 text-green-500" />}
              {event.eventType === 'user_modify' && <Edit3 className="w-5 h-5 text-blue-500" />}
              {event.eventType === 'permission_change' && <Key className="w-5 h-5 text-purple-500" />}
              {event.eventType === 'system_restart' && <RefreshCw className="w-5 h-5 text-orange-500" />}
              {event.eventType === 'security_violation' && <Shield className="w-5 h-5 text-red-500" />}
              
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-medium">{event.actor}</span>
                  <span className="text-gray-400">→</span>
                  <span className="text-gray-700">{event.target}</span>
                  <span className={`px-2 py-1 rounded text-xs ${getSeverityColor(event.severity)}`}>
                    {t(event.severity)}
                  </span>
                  <span className={`px-2 py-1 rounded text-xs ${
                    event.success ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {event.success ? 'Success' : 'Failed'}
                  </span>
                </div>
                <div className="text-sm text-gray-600 mt-1">{event.action}</div>
                <div className="text-sm text-gray-500">{event.details}</div>
              </div>
            </div>
            <div className="text-right text-xs text-gray-500">
              <div>{new Date(event.timestamp).toLocaleString()}</div>
              <div>IP: {event.ipAddress}</div>
              {event.duration && <div>Duration: {event.duration}ms</div>}
              {event.affectedObjects && (
                <div>Objects: {event.affectedObjects.length}</div>
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
        <span className="ml-2">Загрузка системных данных...</span>
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
              <Settings className="w-8 h-8 text-blue-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {t('system_administration')}
                </h1>
                <p className="text-gray-600">
                  Управление системой • {systemHealth.filter(h => h.status === 'healthy').length}/{systemHealth.length} компонентов исправны
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="autoRefresh"
                  checked={autoRefresh}
                  onChange={(e) => setAutoRefresh(e.target.checked)}
                  className="rounded border-gray-300"
                />
                <label htmlFor="autoRefresh" className="text-sm text-gray-600">
                  {t('auto_refresh')}
                </label>
              </div>
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
                onClick={() => {
                  setIsLoading(true);
                  setTimeout(() => setIsLoading(false), 1000);
                }}
                className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <RefreshCw className="w-4 h-4" />
                <span>{t('refresh_data')}</span>
              </button>
            </div>
          </div>
        </div>

        {/* System Status Summary */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span className="text-sm text-gray-600">Исправные компоненты</span>
            </div>
            <div className="text-2xl font-bold text-green-600">
              {systemHealth.filter(h => h.status === 'healthy').length}
            </div>
            <div className="text-xs text-gray-500">
              из {systemHealth.length} компонентов
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <Users className="w-5 h-5 text-blue-500" />
              <span className="text-sm text-gray-600">Активные пользователи</span>
            </div>
            <div className="text-2xl font-bold text-blue-600">
              {userAccounts.filter(u => u.status === 'active').length}
            </div>
            <div className="text-xs text-gray-500">
              из {userAccounts.length} аккаунтов
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              <span className="text-sm text-gray-600">Критические события</span>
            </div>
            <div className="text-2xl font-bold text-red-600">
              {auditEvents.filter(e => e.severity === 'critical').length}
            </div>
            <div className="text-xs text-gray-500">
              за последний час
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="flex items-center space-x-2">
              <Activity className="w-5 h-5 text-purple-500" />
              <span className="text-sm text-gray-600">Системная нагрузка</span>
            </div>
            <div className="text-2xl font-bold text-purple-600">
              {systemMetrics.find(m => m.name === 'CPU Usage')?.currentValue.toFixed(0) || '0'}%
            </div>
            <div className="text-xs text-gray-500">
              CPU usage
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex space-x-8 px-6">
              {[
                { id: 'dashboard', label: t('system_dashboard'), icon: Activity },
                { id: 'users', label: t('user_management'), icon: Users },
                { id: 'config', label: t('system_configuration'), icon: Settings },
                { id: 'audit', label: t('audit_log'), icon: FileText },
                { id: 'monitoring', label: t('system_monitoring'), icon: BarChart3 }
              ].map(tab => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as any)}
                    className={`flex items-center space-x-2 py-4 border-b-2 font-medium text-sm ${
                      activeTab === tab.id
                        ? 'border-blue-500 text-blue-600'
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

        {/* Filters for User Management */}
        {activeTab === 'users' && (
          <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
            <div className="flex items-center space-x-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    placeholder={t('search_users')}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              </div>
              
              <div className="flex items-center space-x-2">
                <Filter className="w-5 h-5 text-gray-400" />
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="all">{t('all_statuses')}</option>
                  <option value="active">{t('active')}</option>
                  <option value="inactive">{t('inactive')}</option>
                  <option value="locked">{t('locked')}</option>
                  <option value="pending">{t('pending')}</option>
                </select>
              </div>
              
              <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                <Plus className="w-4 h-4" />
                <span>{t('add_user')}</span>
              </button>
            </div>
          </div>
        )}

        {/* Content */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          {activeTab === 'dashboard' && renderSystemDashboard()}
          {activeTab === 'users' && renderUserManagement()}
          {activeTab === 'config' && renderSystemConfiguration()}
          {activeTab === 'audit' && renderAuditLog()}
          {activeTab === 'monitoring' && (
            <div className="text-center py-12">
              <BarChart3 className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500">{t('system_monitoring')} - Detailed metrics dashboard</p>
            </div>
          )}
        </div>

        {/* User Details Modal */}
        {selectedUser && isUserModalOpen && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-semibold">
                    {language === 'ru' ? selectedUser.fullNameRu || selectedUser.fullName : selectedUser.fullNameEn || selectedUser.fullName}
                  </h3>
                  <button
                    onClick={() => {
                      setSelectedUser(null);
                      setIsUserModalOpen(false);
                    }}
                    className="p-2 hover:bg-gray-100 rounded-lg"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>
              
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Account Information</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="text-gray-600">Username:</span> {selectedUser.username}</div>
                      <div><span className="text-gray-600">Email:</span> {selectedUser.email}</div>
                      <div><span className="text-gray-600">Role:</span> {selectedUser.role}</div>
                      <div><span className="text-gray-600">Department:</span> {selectedUser.department}</div>
                      <div><span className="text-gray-600">Position:</span> {selectedUser.position}</div>
                      <div><span className="text-gray-600">Status:</span> {t(selectedUser.status)}</div>
                      <div><span className="text-gray-600">2FA Enabled:</span> {selectedUser.twoFactorEnabled ? t('yes') : t('no')}</div>
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Security Information</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="text-gray-600">Failed Attempts:</span> {selectedUser.failedLoginAttempts}/5</div>
                      <div><span className="text-gray-600">Account Locked:</span> {selectedUser.accountLocked ? t('yes') : t('no')}</div>
                      {selectedUser.lockReason && (
                        <div><span className="text-gray-600">Lock Reason:</span> {selectedUser.lockReason}</div>
                      )}
                      <div><span className="text-gray-600">Active Sessions:</span> {selectedUser.sessionCount}</div>
                      <div><span className="text-gray-600">Last Login:</span> {selectedUser.lastLogin ? new Date(selectedUser.lastLogin).toLocaleString() : 'Never'}</div>
                      <div><span className="text-gray-600">Created:</span> {new Date(selectedUser.createdAt).toLocaleDateString()}</div>
                      <div><span className="text-gray-600">Password Changed:</span> {selectedUser.passwordLastChanged ? new Date(selectedUser.passwordLastChanged).toLocaleDateString() : 'Never'}</div>
                    </div>
                  </div>
                </div>
                
                <div className="mt-6">
                  <h4 className="font-medium text-gray-900 mb-3">Permissions ({selectedUser.permissions.length})</h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedUser.permissions.map(permission => (
                      <span key={permission} className="px-3 py-1 bg-blue-100 text-blue-700 text-sm rounded-full">
                        {permission}
                      </span>
                    ))}
                  </div>
                </div>
                
                <div className="mt-6 flex space-x-3">
                  <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                    {t('save')}
                  </button>
                  <button 
                    onClick={() => {
                      setSelectedUser(null);
                      setIsUserModalOpen(false);
                    }}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  >
                    {t('cancel')}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec18SystemAdministration;