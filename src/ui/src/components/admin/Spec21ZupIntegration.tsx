import React, { useState, useEffect } from 'react';
import {
  Database,
  RefreshCw,
  Upload,
  Download,
  Sync,
  CheckCircle,
  XCircle,
  AlertCircle,
  Clock,
  FileText,
  Users,
  Calendar,
  TrendingUp,
  TrendingDown,
  Play,
  Pause,
  Settings,
  Eye,
  AlertTriangle,
  Server,
  Activity,
  FileSpreadsheet,
  Shield,
  Zap,
  Globe,
  Flag,
  Building,
  UserCheck,
  Timer,
  BarChart3,
  PieChart,
  Search,
  Filter,
  X,
  Edit3,
  Save,
  Plus
} from 'lucide-react';

// SPEC-21: 1C ZUP Integration Management
// Enhanced from ZupSyncManager.tsx and integration components with 85% reuse
// Focus: Russian payroll system integration for HR managers, payroll specialists, system administrators (10-15+ daily users)

interface Spec21EmployeeSync {
  id: string;
  employeeName: string;
  employeeNameRu: string; // ФИО
  position: string;
  positionRu: string; // Должность
  department: string;
  departmentRu: string; // Подразделение
  salary: number;
  hireDate: string;
  zupAgentId: string;
  syncStatus: 'synced' | 'pending' | 'error' | 'not_synced';
  lastSyncTime: string;
  errorMessage?: string;
  syncAttempts: number;
}

interface Spec21TimeCodeMapping {
  code: string;
  codeRu: string; // Russian code
  nameRu: string; // Russian name
  nameEn: string; // English name
  description: string;
  multiplier: number; // Pay rate multiplier
  isActive: boolean;
  usage: number; // Hours used this month
  complianceStatus: 'compliant' | 'warning' | 'violation';
}

interface Spec21SyncOperation {
  id: string;
  operationType: 'employee_sync' | 'timesheet_export' | 'schedule_upload' | 'vacation_export' | 'full_sync';
  startTime: string;
  endTime?: string;
  status: 'running' | 'completed' | 'failed' | 'cancelled';
  progress: number;
  processedRecords: number;
  totalRecords: number;
  successCount: number;
  errorCount: number;
  warnings: string[];
  errors: string[];
  initiatedBy: string;
  duration?: number;
}

interface Spec21IntegrationHealth {
  component: string;
  status: 'healthy' | 'warning' | 'critical' | 'offline';
  responseTime: number;
  lastCheck: string;
  uptime: number;
  errorRate: number;
  throughput: number;
  details: {
    version?: string;
    database?: string;
    encoding?: string;
    timezone?: string;
  };
}

interface Spec21VacationExport {
  id: string;
  period: string;
  employeeCount: number;
  vacationDays: number;
  generatedAt: string;
  fileFormat: 'xlsx' | 'xml' | 'csv';
  fileSize: string;
  downloadUrl: string;
  uploadedToZup: boolean;
  uploadTime?: string;
  status: 'generated' | 'uploaded' | 'error';
}

const Spec21ZupIntegration: React.FC = () => {
  const [employeeSync, setEmployeeSync] = useState<Spec21EmployeeSync[]>([]);
  const [timeCodeMappings, setTimeCodeMappings] = useState<Spec21TimeCodeMapping[]>([]);
  const [syncOperations, setSyncOperations] = useState<Spec21SyncOperation[]>([]);
  const [integrationHealth, setIntegrationHealth] = useState<Spec21IntegrationHealth[]>([]);
  const [vacationExports, setVacationExports] = useState<Spec21VacationExport[]>([]);
  const [activeTab, setActiveTab] = useState<'dashboard' | 'employees' | 'timecodes' | 'operations' | 'health'>('dashboard');
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedOperation, setSelectedOperation] = useState<Spec21SyncOperation | null>(null);

  // Demo data initialization
  useEffect(() => {
    const demoEmployeeSync: Spec21EmployeeSync[] = [
      {
        id: 'emp-001',
        employeeName: 'Ivan Petrov',
        employeeNameRu: 'Иван Иванович Петров',
        position: 'Senior Agent',
        positionRu: 'Старший специалист',
        department: 'Customer Support',
        departmentRu: 'Служба поддержки',
        salary: 85000,
        hireDate: '2025-01-15',
        zupAgentId: 'AG-001-2025',
        syncStatus: 'synced',
        lastSyncTime: '2025-07-21T14:30:00Z',
        syncAttempts: 1
      },
      {
        id: 'emp-002',
        employeeName: 'Maria Kozlova',
        employeeNameRu: 'Мария Сергеевна Козлова',
        position: 'Team Lead',
        positionRu: 'Руководитель группы',
        department: 'Technical Support',
        departmentRu: 'Техническая поддержка',
        salary: 120000,
        hireDate: '2024-11-20',
        zupAgentId: 'AG-002-2025',
        syncStatus: 'synced',
        lastSyncTime: '2025-07-21T14:25:00Z',
        syncAttempts: 1
      },
      {
        id: 'emp-003',
        employeeName: 'Dmitry Volkov',
        employeeNameRu: 'Дмитрий Александрович Волков',
        position: 'Specialist',
        positionRu: 'Специалист',
        department: 'Sales',
        departmentRu: 'Отдел продаж',
        salary: 75000,
        hireDate: '2025-03-01',
        zupAgentId: 'AG-003-2025',
        syncStatus: 'error',
        lastSyncTime: '2025-07-21T14:20:00Z',
        errorMessage: 'Ошибка валидации ФИО в 1С ЗУП',
        syncAttempts: 3
      },
      {
        id: 'emp-004',
        employeeName: 'Anna Sidorova',
        employeeNameRu: 'Анна Петровна Сидорова',
        position: 'Junior Agent',
        positionRu: 'Младший специалист',
        department: 'Customer Support',
        departmentRu: 'Служба поддержки',
        salary: 65000,
        hireDate: '2025-06-01',
        zupAgentId: '',
        syncStatus: 'pending',
        lastSyncTime: '',
        syncAttempts: 0
      }
    ];

    const demoTimeCodeMappings: Spec21TimeCodeMapping[] = [
      {
        code: 'Я/I',
        codeRu: 'Я',
        nameRu: 'Явки',
        nameEn: 'Regular Work',
        description: 'Стандартное рабочее время согласно ТК РФ',
        multiplier: 1.0,
        isActive: true,
        usage: 6720, // 168 hours * 40 employees
        complianceStatus: 'compliant'
      },
      {
        code: 'Н/H',
        codeRu: 'Н',
        nameRu: 'Ночные',
        nameEn: 'Night Work',
        description: 'Работа в ночное время (с 22:00 до 6:00) - ст. 96 ТК РФ',
        multiplier: 1.2,
        isActive: true,
        usage: 240, // 24 hours * 10 employees
        complianceStatus: 'compliant'
      },
      {
        code: 'В/B',
        codeRu: 'В',
        nameRu: 'Выходные',
        nameEn: 'Weekend Work',
        description: 'Работа в выходные и нерабочие праздничные дни - ст. 113 ТК РФ',
        multiplier: 2.0,
        isActive: true,
        usage: 64, // 16 hours * 4 employees
        complianceStatus: 'compliant'
      },
      {
        code: 'СВ/OT',
        codeRu: 'СВ',
        nameRu: 'Сверхурочные',
        nameEn: 'Overtime',
        description: 'Сверхурочная работа - ст. 99 ТК РФ (макс. 4 часа в день)',
        multiplier: 1.5,
        isActive: true,
        usage: 120, // 8 hours * 15 employees
        complianceStatus: 'warning'
      },
      {
        code: 'БЛ/SL',
        codeRu: 'БЛ',
        nameRu: 'Больничный',
        nameEn: 'Sick Leave',
        description: 'Временная нетрудоспособность - ФЗ №255',
        multiplier: 0.0,
        isActive: true,
        usage: 456, // Sick days
        complianceStatus: 'compliant'
      },
      {
        code: 'ОТ/VAC',
        codeRu: 'ОТ',
        nameRu: 'Отпуск',
        nameEn: 'Vacation',
        description: 'Ежегодный оплачиваемый отпуск - ст. 114 ТК РФ',
        multiplier: 1.0,
        isActive: true,
        usage: 840, // Vacation days
        complianceStatus: 'compliant'
      }
    ];

    const demoSyncOperations: Spec21SyncOperation[] = [
      {
        id: 'sync-001',
        operationType: 'full_sync',
        startTime: '2025-07-21T14:30:00Z',
        endTime: '2025-07-21T14:45:00Z',
        status: 'completed',
        progress: 100,
        processedRecords: 150,
        totalRecords: 150,
        successCount: 147,
        errorCount: 3,
        warnings: ['3 сотрудника без ИНН', 'Проверьте данные паспорта для Волкова Д.А.'],
        errors: ['Ошибка подключения к базе 1С в 14:42', 'Тайм-аут синхронизации для 2 записей'],
        initiatedBy: 'maria.kozlova',
        duration: 15 * 60 * 1000 // 15 minutes
      },
      {
        id: 'sync-002',
        operationType: 'timesheet_export',
        startTime: '2025-07-21T13:00:00Z',
        endTime: '2025-07-21T13:05:00Z',
        status: 'completed',
        progress: 100,
        processedRecords: 2240, // Time entries
        totalRecords: 2240,
        successCount: 2240,
        errorCount: 0,
        warnings: ['Некоторые коды времени превышают норму'],
        errors: [],
        initiatedBy: 'ivan.petrov',
        duration: 5 * 60 * 1000 // 5 minutes
      },
      {
        id: 'sync-003',
        operationType: 'vacation_export',
        startTime: '2025-07-21T12:00:00Z',
        status: 'running',
        progress: 65,
        processedRecords: 32,
        totalRecords: 50,
        successCount: 30,
        errorCount: 2,
        warnings: ['2 сотрудника с пересекающимися отпусками'],
        errors: ['Неверный формат даты для Петрова И.И.', 'Превышение лимита отпускных дней'],
        initiatedBy: 'hr.manager'
      },
      {
        id: 'sync-004',
        operationType: 'employee_sync',
        startTime: '2025-07-21T11:30:00Z',
        endTime: '2025-07-21T11:32:00Z',
        status: 'failed',
        progress: 30,
        processedRecords: 15,
        totalRecords: 50,
        successCount: 10,
        errorCount: 5,
        warnings: [],
        errors: ['Критическая ошибка подключения к 1С ЗУП', 'Тайм-аут соединения с сервером 192.168.1.50'],
        initiatedBy: 'system.scheduler',
        duration: 2 * 60 * 1000 // 2 minutes
      }
    ];

    const demoIntegrationHealth: Spec21IntegrationHealth[] = [
      {
        component: '1C ZUP Connection',
        status: 'healthy',
        responseTime: 245,
        lastCheck: '2025-07-21T14:35:00Z',
        uptime: 99.2,
        errorRate: 0.5,
        throughput: 45,
        details: {
          version: '8.3.24.1467',
          database: 'ZUP_COMPANY_2025',
          encoding: 'UTF-8',
          timezone: 'Europe/Moscow'
        }
      },
      {
        component: 'Employee Sync Service',
        status: 'warning',
        responseTime: 892,
        lastCheck: '2025-07-21T14:34:30Z',
        uptime: 97.8,
        errorRate: 2.1,
        throughput: 12,
        details: {
          version: '2.1.3',
          database: 'wfm_enterprise'
        }
      },
      {
        component: 'Time Code Processor',
        status: 'healthy',
        responseTime: 156,
        lastCheck: '2025-07-21T14:35:15Z',
        uptime: 99.8,
        errorRate: 0.1,
        throughput: 67,
        details: {
          version: '1.4.2',
          encoding: 'UTF-8'
        }
      },
      {
        component: 'Excel Export Generator',
        status: 'healthy',
        responseTime: 334,
        lastCheck: '2025-07-21T14:34:45Z',
        uptime: 98.9,
        errorRate: 0.8,
        throughput: 23,
        details: {
          version: '3.2.1',
          encoding: 'UTF-8'
        }
      }
    ];

    const demoVacationExports: Spec21VacationExport[] = [
      {
        id: 'export-001',
        period: 'Июль 2025',
        employeeCount: 45,
        vacationDays: 180,
        generatedAt: '2025-07-21T12:00:00Z',
        fileFormat: 'xlsx',
        fileSize: '2.1 MB',
        downloadUrl: '/exports/vacation_july_2025.xlsx',
        uploadedToZup: true,
        uploadTime: '2025-07-21T12:15:00Z',
        status: 'uploaded'
      },
      {
        id: 'export-002',
        period: 'Июнь 2025',
        employeeCount: 42,
        vacationDays: 165,
        generatedAt: '2025-06-30T23:45:00Z',
        fileFormat: 'xlsx',
        fileSize: '1.9 MB',
        downloadUrl: '/exports/vacation_june_2025.xlsx',
        uploadedToZup: true,
        uploadTime: '2025-07-01T08:30:00Z',
        status: 'uploaded'
      }
    ];

    setEmployeeSync(demoEmployeeSync);
    setTimeCodeMappings(demoTimeCodeMappings);
    setSyncOperations(demoSyncOperations);
    setIntegrationHealth(demoIntegrationHealth);
    setVacationExports(demoVacationExports);
    setIsLoading(false);

    // Auto-refresh for running operations
    const interval = setInterval(() => {
      if (autoRefresh) {
        setSyncOperations(prev => prev.map(op => {
          if (op.status === 'running' && op.progress < 100) {
            const newProgress = Math.min(op.progress + Math.random() * 10, 100);
            const newProcessed = Math.floor((newProgress / 100) * op.totalRecords);
            
            if (newProgress >= 100) {
              return {
                ...op,
                progress: 100,
                processedRecords: op.totalRecords,
                status: Math.random() > 0.2 ? 'completed' : 'failed',
                endTime: new Date().toISOString(),
                duration: Date.now() - new Date(op.startTime).getTime()
              };
            }
            
            return {
              ...op,
              progress: newProgress,
              processedRecords: newProcessed,
              successCount: newProcessed - op.errorCount
            };
          }
          return op;
        }));
      }
    }, 5000); // 5 seconds

    return () => clearInterval(interval);
  }, [autoRefresh]);

  const t = (key: string): string => {
    const translations: Record<string, Record<string, string>> = {
      ru: {
        'zup_integration': 'Интеграция с 1С ЗУП',
        'integration_dashboard': 'Панель интеграции',
        'employee_sync': 'Синхронизация сотрудников',
        'time_codes': 'Коды времени',
        'sync_operations': 'Операции синхронизации',
        'integration_health': 'Состояние интеграции',
        'sync_status': 'Статус синхронизации',
        'last_sync': 'Последняя синхронизация',
        'sync_attempts': 'Попытки синхронизации',
        'employee_name': 'ФИО сотрудника',
        'position': 'Должность',
        'department': 'Подразделение',
        'salary': 'Оклад',
        'hire_date': 'Дата приема',
        'zup_agent_id': 'ID агента в ЗУП',
        'synced': 'Синхронизировано',
        'pending': 'Ожидание',
        'error': 'Ошибка',
        'not_synced': 'Не синхронизировано',
        'running': 'Выполняется',
        'completed': 'Завершено',
        'failed': 'Ошибка',
        'cancelled': 'Отменено',
        'healthy': 'Исправно',
        'warning': 'Предупреждение',
        'critical': 'Критическое',
        'offline': 'Отключено',
        'time_code': 'Код времени',
        'russian_code': 'Русский код',
        'english_name': 'Английское название',
        'description': 'Описание',
        'multiplier': 'Коэффициент',
        'usage_hours': 'Часы использования',
        'compliance_status': 'Статус соответствия',
        'compliant': 'Соответствует',
        'violation': 'Нарушение',
        'operation_type': 'Тип операции',
        'start_time': 'Время начала',
        'duration': 'Длительность',
        'processed_records': 'Обработано записей',
        'success_count': 'Успешно',
        'error_count': 'Ошибки',
        'initiated_by': 'Инициировано',
        'component': 'Компонент',
        'response_time': 'Время отклика',
        'uptime': 'Время работы',
        'error_rate': 'Частота ошибок',
        'throughput': 'Пропускная способность',
        'last_check': 'Последняя проверка',
        'version': 'Версия',
        'database': 'База данных',
        'encoding': 'Кодировка',
        'timezone': 'Часовой пояс',
        'vacation_export': 'Экспорт отпусков',
        'period': 'Период',
        'employee_count': 'Количество сотрудников',
        'vacation_days': 'Дни отпуска',
        'file_format': 'Формат файла',
        'file_size': 'Размер файла',
        'generated_at': 'Создано',
        'uploaded_to_zup': 'Загружено в ЗУП',
        'upload_time': 'Время загрузки',
        'download_file': 'Скачать файл',
        'upload_to_zup': 'Загрузить в ЗУП',
        'sync_now': 'Синхронизировать',
        'export_vacation': 'Экспорт отпусков',
        'export_timesheet': 'Экспорт табеля',
        'full_sync': 'Полная синхронизация',
        'auto_refresh': 'Автообновление',
        'refresh_data': 'Обновить данные',
        'search_employees': 'Поиск сотрудников...',
        'filter_by_status': 'Фильтр по статусу',
        'all_statuses': 'Все статусы',
        'view_details': 'Подробнее',
        'retry_sync': 'Повторить синхронизацию',
        'cancel_operation': 'Отменить операцию',
        'warnings': 'Предупреждения',
        'errors': 'Ошибки',
        'progress': 'Прогресс',
        'russian_labor_code': 'Трудовой кодекс РФ',
        'zup_version': 'Версия 1С ЗУП',
        'connection_status': 'Статус соединения',
        'integration_settings': 'Настройки интеграции',
        'close': 'Закрыть',
        'ms': 'мс',
        'rec_min': 'зап./мин'
      },
      en: {
        'zup_integration': '1C ZUP Integration',
        'integration_dashboard': 'Integration Dashboard',
        'employee_sync': 'Employee Synchronization',
        'time_codes': 'Time Codes',
        'sync_operations': 'Sync Operations',
        'integration_health': 'Integration Health',
        'sync_status': 'Sync Status',
        'last_sync': 'Last Sync',
        'sync_attempts': 'Sync Attempts',
        'employee_name': 'Employee Name',
        'position': 'Position',
        'department': 'Department',
        'salary': 'Salary',
        'hire_date': 'Hire Date',
        'zup_agent_id': 'ZUP Agent ID',
        'synced': 'Synced',
        'pending': 'Pending',
        'error': 'Error',
        'not_synced': 'Not Synced',
        'running': 'Running',
        'completed': 'Completed',
        'failed': 'Failed',
        'cancelled': 'Cancelled',
        'healthy': 'Healthy',
        'warning': 'Warning',
        'critical': 'Critical',
        'offline': 'Offline',
        'time_code': 'Time Code',
        'russian_code': 'Russian Code',
        'english_name': 'English Name',
        'description': 'Description',
        'multiplier': 'Multiplier',
        'usage_hours': 'Usage Hours',
        'compliance_status': 'Compliance Status',
        'compliant': 'Compliant',
        'violation': 'Violation',
        'operation_type': 'Operation Type',
        'start_time': 'Start Time',
        'duration': 'Duration',
        'processed_records': 'Processed Records',
        'success_count': 'Success',
        'error_count': 'Errors',
        'initiated_by': 'Initiated By',
        'component': 'Component',
        'response_time': 'Response Time',
        'uptime': 'Uptime',
        'error_rate': 'Error Rate',
        'throughput': 'Throughput',
        'last_check': 'Last Check',
        'version': 'Version',
        'database': 'Database',
        'encoding': 'Encoding',
        'timezone': 'Timezone',
        'vacation_export': 'Vacation Export',
        'period': 'Period',
        'employee_count': 'Employee Count',
        'vacation_days': 'Vacation Days',
        'file_format': 'File Format',
        'file_size': 'File Size',
        'generated_at': 'Generated At',
        'uploaded_to_zup': 'Uploaded to ZUP',
        'upload_time': 'Upload Time',
        'download_file': 'Download File',
        'upload_to_zup': 'Upload to ZUP',
        'sync_now': 'Sync Now',
        'export_vacation': 'Export Vacation',
        'export_timesheet': 'Export Timesheet',
        'full_sync': 'Full Sync',
        'auto_refresh': 'Auto Refresh',
        'refresh_data': 'Refresh Data',
        'search_employees': 'Search employees...',
        'filter_by_status': 'Filter by Status',
        'all_statuses': 'All Statuses',
        'view_details': 'View Details',
        'retry_sync': 'Retry Sync',
        'cancel_operation': 'Cancel Operation',
        'warnings': 'Warnings',
        'errors': 'Errors',
        'progress': 'Progress',
        'russian_labor_code': 'Russian Labor Code',
        'zup_version': '1C ZUP Version',
        'connection_status': 'Connection Status',
        'integration_settings': 'Integration Settings',
        'close': 'Close',
        'ms': 'ms',
        'rec_min': 'rec/min'
      }
    };
    return translations[language][key] || key;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'synced':
      case 'completed':
      case 'healthy':
      case 'uploaded':
      case 'compliant': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'warning': return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'error':
      case 'failed':
      case 'critical':
      case 'violation': return <XCircle className="w-4 h-4 text-red-500" />;
      case 'pending':
      case 'running': return <Clock className="w-4 h-4 text-blue-500" />;
      case 'not_synced':
      case 'offline': return <AlertCircle className="w-4 h-4 text-gray-400" />;
      case 'cancelled': return <XCircle className="w-4 h-4 text-gray-400" />;
      case 'generated': return <FileSpreadsheet className="w-4 h-4 text-blue-500" />;
      default: return <AlertCircle className="w-4 h-4 text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'synced':
      case 'completed':
      case 'healthy':
      case 'uploaded':
      case 'compliant': return 'text-green-600 bg-green-50';
      case 'warning': return 'text-yellow-600 bg-yellow-50';
      case 'error':
      case 'failed':
      case 'critical':
      case 'violation': return 'text-red-600 bg-red-50';
      case 'pending':
      case 'running': return 'text-blue-600 bg-blue-50';
      case 'not_synced':
      case 'offline': return 'text-gray-600 bg-gray-50';
      case 'cancelled': return 'text-gray-600 bg-gray-50';
      case 'generated': return 'text-blue-600 bg-blue-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const formatDuration = (milliseconds: number | undefined): string => {
    if (!milliseconds) return '-';
    const minutes = Math.floor(milliseconds / 60000);
    const seconds = Math.floor((milliseconds % 60000) / 1000);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  const filteredEmployees = employeeSync.filter(emp => {
    const matchesSearch = 
      emp.employeeName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      emp.employeeNameRu.toLowerCase().includes(searchTerm.toLowerCase()) ||
      emp.department.toLowerCase().includes(searchTerm.toLowerCase()) ||
      emp.zupAgentId.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || emp.syncStatus === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const renderDashboard = () => (
    <div className="space-y-6">
      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="flex items-center space-x-2">
            <Users className="w-5 h-5 text-blue-500" />
            <span className="text-sm text-gray-600">Сотрудники в ЗУП</span>
          </div>
          <div className="text-2xl font-bold text-blue-600">
            {employeeSync.filter(e => e.syncStatus === 'synced').length}
          </div>
          <div className="text-xs text-gray-500">
            из {employeeSync.length} всего
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="flex items-center space-x-2">
            <Timer className="w-5 h-5 text-green-500" />
            <span className="text-sm text-gray-600">Коды времени</span>
          </div>
          <div className="text-2xl font-bold text-green-600">
            {timeCodeMappings.filter(t => t.isActive).length}
          </div>
          <div className="text-xs text-gray-500">
            активных кодов
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="flex items-center space-x-2">
            <Activity className="w-5 h-5 text-purple-500" />
            <span className="text-sm text-gray-600">Активные операции</span>
          </div>
          <div className="text-2xl font-bold text-purple-600">
            {syncOperations.filter(op => op.status === 'running').length}
          </div>
          <div className="text-xs text-gray-500">
            в процессе
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="flex items-center space-x-2">
            <Server className="w-5 h-5 text-orange-500" />
            <span className="text-sm text-gray-600">Состояние ЗУП</span>
          </div>
          <div className="text-2xl font-bold text-orange-600">
            {integrationHealth.filter(h => h.status === 'healthy').length}/4
          </div>
          <div className="text-xs text-gray-500">
            компонентов исправны
          </div>
        </div>
      </div>

      {/* Recent Operations */}
      <div className="bg-white rounded-lg border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold">Недавние операции</h3>
        </div>
        <div className="p-4">
          <div className="space-y-3">
            {syncOperations.slice(0, 3).map(operation => (
              <div key={operation.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-blue-100 rounded">
                    <Sync className="w-4 h-4 text-blue-600" />
                  </div>
                  <div>
                    <div className="font-medium">{t(operation.operationType)}</div>
                    <div className="text-sm text-gray-600">
                      {t('initiated_by')}: {operation.initiatedBy}
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className={`px-2 py-1 rounded text-xs ${getStatusColor(operation.status)}`}>
                    {t(operation.status)}
                  </div>
                  <div className="text-xs text-gray-500 mt-1">
                    {operation.status === 'running' ? `${operation.progress}%` : formatDuration(operation.duration)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Integration Health Status */}
      <div className="bg-white rounded-lg border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold">Состояние интеграции</h3>
        </div>
        <div className="p-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {integrationHealth.map(component => (
              <div key={component.component} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center space-x-3">
                  {getStatusIcon(component.status)}
                  <div>
                    <div className="font-medium">{component.component}</div>
                    <div className="text-sm text-gray-600">
                      {component.responseTime}{t('ms')} • {component.throughput} {t('rec_min')}
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className={`px-2 py-1 rounded text-xs ${getStatusColor(component.status)}`}>
                    {t(component.status)}
                  </div>
                  <div className="text-xs text-gray-500">
                    {component.uptime.toFixed(1)}% uptime
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderEmployeeSync = () => (
    <div className="space-y-4">
      {filteredEmployees.map(employee => {
        const displayName = language === 'ru' ? employee.employeeNameRu : employee.employeeName;
        const displayPosition = language === 'ru' ? employee.positionRu : employee.position;
        const displayDepartment = language === 'ru' ? employee.departmentRu : employee.department;
        
        return (
          <div key={employee.id} className="p-4 border border-gray-200 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <UserCheck className="w-5 h-5 text-blue-500" />
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-medium text-lg">{displayName}</span>
                    <span className={`px-2 py-1 rounded text-xs ${getStatusColor(employee.syncStatus)}`}>
                      {t(employee.syncStatus)}
                    </span>
                    {employee.zupAgentId && (
                      <span className="px-2 py-1 bg-blue-100 text-blue-600 text-xs rounded">
                        {employee.zupAgentId}
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-gray-600">
                    {displayPosition} • {displayDepartment}
                  </div>
                  <div className="flex items-center space-x-4 mt-1 text-xs text-gray-500">
                    <span>{t('salary')}: ₽{employee.salary.toLocaleString()}</span>
                    <span>{t('hire_date')}: {new Date(employee.hireDate).toLocaleDateString()}</span>
                    <span>{t('sync_attempts')}: {employee.syncAttempts}</span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-sm text-gray-600">
                  {employee.lastSyncTime ? (
                    <div>{t('last_sync')}: {new Date(employee.lastSyncTime).toLocaleString()}</div>
                  ) : (
                    <div className="text-gray-400">Не синхронизировано</div>
                  )}
                </div>
                <div className="flex space-x-2 mt-2">
                  <button className="p-2 hover:bg-gray-100 rounded" title={t('sync_now')}>
                    <Sync className="w-4 h-4 text-blue-500" />
                  </button>
                  <button className="p-2 hover:bg-gray-100 rounded" title={t('view_details')}>
                    <Eye className="w-4 h-4 text-gray-500" />
                  </button>
                </div>
              </div>
            </div>
            
            {employee.errorMessage && (
              <div className="mt-3 p-2 bg-red-50 border border-red-200 rounded text-sm">
                <AlertTriangle className="w-4 h-4 text-red-500 inline mr-2" />
                {employee.errorMessage}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );

  const renderTimeCodes = () => (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {timeCodeMappings.map(timeCode => (
        <div key={timeCode.code} className="p-4 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center space-x-2">
              <Timer className="w-5 h-5 text-blue-500" />
              <span className="font-medium text-lg">{timeCode.code}</span>
              <span className="px-2 py-1 bg-gray-100 text-gray-600 text-sm rounded">
                {language === 'ru' ? timeCode.nameRu : timeCode.nameEn}
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <span className={`px-2 py-1 rounded text-xs ${getStatusColor(timeCode.complianceStatus)}`}>
                {t(timeCode.complianceStatus)}
              </span>
              <span className="text-lg font-bold text-blue-600">
                {timeCode.multiplier}x
              </span>
            </div>
          </div>
          
          <div className="text-sm text-gray-600 mb-3">{timeCode.description}</div>
          
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <span className="text-gray-500">Часы за месяц:</span>
              <div className="font-medium">{timeCode.usage.toLocaleString()}</div>
            </div>
            <div>
              <span className="text-gray-500">Статус:</span>
              <div className={timeCode.isActive ? 'text-green-600' : 'text-gray-400'}>
                {timeCode.isActive ? 'Активен' : 'Неактивен'}
              </div>
            </div>
          </div>
          
          {timeCode.complianceStatus === 'warning' && (
            <div className="mt-3 p-2 bg-yellow-50 border border-yellow-200 rounded text-sm text-yellow-700">
              <AlertTriangle className="w-4 h-4 inline mr-2" />
              Превышение рекомендуемых норм - проверьте соответствие ТК РФ
            </div>
          )}
        </div>
      ))}
    </div>
  );

  const renderSyncOperations = () => (
    <div className="space-y-4">
      {syncOperations.map(operation => (
        <div key={operation.id} className="p-4 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center space-x-3">
              <div className={`p-2 rounded ${
                operation.status === 'running' ? 'bg-blue-100' :
                operation.status === 'completed' ? 'bg-green-100' :
                operation.status === 'failed' ? 'bg-red-100' :
                'bg-gray-100'
              }`}>
                {operation.status === 'running' && <Play className="w-4 h-4 text-blue-600" />}
                {operation.status === 'completed' && <CheckCircle className="w-4 h-4 text-green-600" />}
                {operation.status === 'failed' && <XCircle className="w-4 h-4 text-red-600" />}
                {operation.status === 'cancelled' && <Pause className="w-4 h-4 text-gray-600" />}
              </div>
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-medium">{t(operation.operationType)}</span>
                  <span className={`px-2 py-1 rounded text-xs ${getStatusColor(operation.status)}`}>
                    {t(operation.status)}
                  </span>
                </div>
                <div className="text-sm text-gray-600">
                  {t('initiated_by')}: {operation.initiatedBy} • {new Date(operation.startTime).toLocaleString()}
                </div>
              </div>
            </div>
            <div className="text-right">
              <div className="text-sm text-gray-600">
                {operation.status === 'running' ? (
                  <div>{operation.progress.toFixed(1)}%</div>
                ) : (
                  <div>{formatDuration(operation.duration)}</div>
                )}
              </div>
              <button 
                onClick={() => setSelectedOperation(operation)}
                className="text-xs text-blue-600 hover:underline"
              >
                {t('view_details')}
              </button>
            </div>
          </div>
          
          {operation.status === 'running' && (
            <div className="mb-3">
              <div className="flex justify-between text-sm text-gray-600 mb-1">
                <span>{operation.processedRecords}/{operation.totalRecords} записей</span>
                <span>{operation.progress.toFixed(1)}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div 
                  className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${operation.progress}%` }}
                ></div>
              </div>
            </div>
          )}
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <span className="text-gray-500">Обработано:</span>
              <div className="font-medium">{operation.processedRecords}</div>
            </div>
            <div>
              <span className="text-gray-500">Успешно:</span>
              <div className="font-medium text-green-600">{operation.successCount}</div>
            </div>
            <div>
              <span className="text-gray-500">Ошибки:</span>
              <div className="font-medium text-red-600">{operation.errorCount}</div>
            </div>
            <div>
              <span className="text-gray-500">Предупреждения:</span>
              <div className="font-medium text-yellow-600">{operation.warnings.length}</div>
            </div>
          </div>
          
          {operation.warnings.length > 0 && (
            <div className="mt-3 p-2 bg-yellow-50 border border-yellow-200 rounded">
              <div className="text-sm font-medium text-yellow-800 mb-1">{t('warnings')}:</div>
              <ul className="text-sm text-yellow-700 space-y-1">
                {operation.warnings.map((warning, index) => (
                  <li key={index}>• {warning}</li>
                ))}
              </ul>
            </div>
          )}
          
          {operation.errors.length > 0 && (
            <div className="mt-3 p-2 bg-red-50 border border-red-200 rounded">
              <div className="text-sm font-medium text-red-800 mb-1">{t('errors')}:</div>
              <ul className="text-sm text-red-700 space-y-1">
                {operation.errors.map((error, index) => (
                  <li key={index}>• {error}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      ))}
    </div>
  );

  const renderIntegrationHealth = () => (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {integrationHealth.map(component => (
        <div key={component.component} className="p-6 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-3">
              <Server className="w-6 h-6 text-blue-500" />
              <span className="font-medium text-lg">{component.component}</span>
            </div>
            <div className="flex items-center space-x-2">
              {getStatusIcon(component.status)}
              <span className={`px-3 py-1 rounded text-sm ${getStatusColor(component.status)}`}>
                {t(component.status)}
              </span>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="bg-blue-50 p-3 rounded">
              <div className="text-sm text-gray-600">{t('response_time')}</div>
              <div className="text-xl font-bold text-blue-600">
                {component.responseTime}{t('ms')}
              </div>
            </div>
            
            <div className="bg-green-50 p-3 rounded">
              <div className="text-sm text-gray-600">{t('uptime')}</div>
              <div className="text-xl font-bold text-green-600">
                {component.uptime.toFixed(1)}%
              </div>
            </div>
            
            <div className="bg-purple-50 p-3 rounded">
              <div className="text-sm text-gray-600">{t('throughput')}</div>
              <div className="text-xl font-bold text-purple-600">
                {component.throughput}
              </div>
            </div>
            
            <div className="bg-orange-50 p-3 rounded">
              <div className="text-sm text-gray-600">{t('error_rate')}</div>
              <div className="text-xl font-bold text-orange-600">
                {component.errorRate.toFixed(1)}%
              </div>
            </div>
          </div>
          
          <div className="space-y-2 text-sm">
            {component.details.version && (
              <div className="flex justify-between">
                <span className="text-gray-600">{t('version')}:</span>
                <span>{component.details.version}</span>
              </div>
            )}
            {component.details.database && (
              <div className="flex justify-between">
                <span className="text-gray-600">{t('database')}:</span>
                <span>{component.details.database}</span>
              </div>
            )}
            {component.details.encoding && (
              <div className="flex justify-between">
                <span className="text-gray-600">{t('encoding')}:</span>
                <span>{component.details.encoding}</span>
              </div>
            )}
            {component.details.timezone && (
              <div className="flex justify-between">
                <span className="text-gray-600">{t('timezone')}:</span>
                <span>{component.details.timezone}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-gray-600">{t('last_check')}:</span>
              <span>{new Date(component.lastCheck).toLocaleString()}</span>
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
        <span className="ml-2">Загрузка интеграции с 1С ЗУП...</span>
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
              <Database className="w-8 h-8 text-blue-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {t('zup_integration')}
                </h1>
                <p className="text-gray-600">
                  Интеграция с системой "1С:Зарплата и управление персоналом" версии 8.3
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
                <Flag className="w-4 h-4 mr-2" />
                {language.toUpperCase()}
              </button>
              <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                <Sync className="w-4 h-4" />
                <span>{t('full_sync')}</span>
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

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex space-x-8 px-6">
              {[
                { id: 'dashboard', label: t('integration_dashboard'), icon: BarChart3 },
                { id: 'employees', label: t('employee_sync'), icon: Users },
                { id: 'timecodes', label: t('time_codes'), icon: Timer },
                { id: 'operations', label: t('sync_operations'), icon: Activity },
                { id: 'health', label: t('integration_health'), icon: Server }
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

        {/* Filters for Employee Sync */}
        {activeTab === 'employees' && (
          <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
            <div className="flex items-center space-x-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    placeholder={t('search_employees')}
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
                  <option value="synced">{t('synced')}</option>
                  <option value="pending">{t('pending')}</option>
                  <option value="error">{t('error')}</option>
                  <option value="not_synced">{t('not_synced')}</option>
                </select>
              </div>
              
              <button className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                <Upload className="w-4 h-4" />
                <span>{t('export_vacation')}</span>
              </button>
            </div>
          </div>
        )}

        {/* Content */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          {activeTab === 'dashboard' && renderDashboard()}
          {activeTab === 'employees' && renderEmployeeSync()}
          {activeTab === 'timecodes' && renderTimeCodes()}
          {activeTab === 'operations' && renderSyncOperations()}
          {activeTab === 'health' && renderIntegrationHealth()}
        </div>

        {/* Operation Details Modal */}
        {selectedOperation && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-semibold">
                    {t(selectedOperation.operationType)} - Детали операции
                  </h3>
                  <button
                    onClick={() => setSelectedOperation(null)}
                    className="p-2 hover:bg-gray-100 rounded-lg"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>
              
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Общая информация</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="text-gray-600">Статус:</span> {t(selectedOperation.status)}</div>
                      <div><span className="text-gray-600">Прогресс:</span> {selectedOperation.progress.toFixed(1)}%</div>
                      <div><span className="text-gray-600">Начало:</span> {new Date(selectedOperation.startTime).toLocaleString()}</div>
                      {selectedOperation.endTime && (
                        <div><span className="text-gray-600">Окончание:</span> {new Date(selectedOperation.endTime).toLocaleString()}</div>
                      )}
                      <div><span className="text-gray-600">Длительность:</span> {formatDuration(selectedOperation.duration)}</div>
                      <div><span className="text-gray-600">Инициатор:</span> {selectedOperation.initiatedBy}</div>
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Статистика</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="text-gray-600">Всего записей:</span> {selectedOperation.totalRecords}</div>
                      <div><span className="text-gray-600">Обработано:</span> {selectedOperation.processedRecords}</div>
                      <div><span className="text-gray-600">Успешно:</span> <span className="text-green-600">{selectedOperation.successCount}</span></div>
                      <div><span className="text-gray-600">Ошибки:</span> <span className="text-red-600">{selectedOperation.errorCount}</span></div>
                      <div><span className="text-gray-600">Предупреждения:</span> <span className="text-yellow-600">{selectedOperation.warnings.length}</span></div>
                    </div>
                  </div>
                </div>
                
                {selectedOperation.warnings.length > 0 && (
                  <div className="mb-4">
                    <h4 className="font-medium text-gray-900 mb-2">Предупреждения</h4>
                    <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
                      <ul className="text-sm text-yellow-700 space-y-1">
                        {selectedOperation.warnings.map((warning, index) => (
                          <li key={index}>• {warning}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                )}
                
                {selectedOperation.errors.length > 0 && (
                  <div className="mb-4">
                    <h4 className="font-medium text-gray-900 mb-2">Ошибки</h4>
                    <div className="bg-red-50 border border-red-200 rounded p-3">
                      <ul className="text-sm text-red-700 space-y-1">
                        {selectedOperation.errors.map((error, index) => (
                          <li key={index}>• {error}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                )}
                
                <div className="flex space-x-3">
                  <button 
                    onClick={() => setSelectedOperation(null)}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  >
                    {t('close')}
                  </button>
                  {selectedOperation.status === 'running' && (
                    <button className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
                      {t('cancel_operation')}
                    </button>
                  )}
                  {selectedOperation.status === 'failed' && (
                    <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                      {t('retry_sync')}
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec21ZupIntegration;