import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Settings,
  Users,
  Shield,
  Plus,
  Edit,
  Trash2,
  Save,
  X,
  Check,
  AlertTriangle,
  Search,
  Filter,
  Globe,
  Copy,
  Download,
  Upload,
  Clock,
  Ban,
  Target,
  TrendingUp,
  FileText,
  Calculator,
  AlertCircle,
  CheckCircle,
  Info
} from 'lucide-react';
import realVacationSchemeService, { 
  VacationScheme, 
  VacationSchemeTemplate, 
  BlackoutPeriod, 
  BusinessRule,
  VacationBalance,
  VacationValidation
} from '../services/realVacationSchemeService';

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Конфигуратор схем отпусков',
    subtitle: 'Управление схемами отпусков и правилами',
    schemes: 'Схемы отпусков',
    templates: 'Шаблоны',
    blackouts: 'Периоды блокировки',
    rules: 'Бизнес правила',
    balances: 'Балансы',
    analytics: 'Аналитика',
    createScheme: 'Создать схему',
    editScheme: 'Редактировать схему',
    deleteScheme: 'Удалить схему',
    duplicateScheme: 'Дублировать схему',
    exportScheme: 'Экспорт схемы',
    importScheme: 'Импорт схемы',
    search: 'Поиск...',
    filter: 'Фильтр',
    save: 'Сохранить',
    cancel: 'Отменить',
    apply: 'Применить',
    fields: {
      name: 'Название схемы',
      description: 'Описание',
      type: 'Тип отпуска',
      active: 'Активная',
      default: 'По умолчанию',
      entitlementDays: 'Количество дней',
      maxConsecutiveDays: 'Макс. дней подряд',
      minAdvanceNotice: 'Мин. уведомление (дни)',
      maxAdvanceBooking: 'Макс. бронирование (дни)',
      allowPartialDays: 'Разрешить частичные дни',
      requiresApproval: 'Требует согласования'
    },
    types: {
      annual: 'Ежегодный отпуск',
      sick: 'Больничный',
      unpaid: 'Неоплачиваемый',
      maternity: 'Материнский',
      study: 'Учебный',
      custom: 'Пользовательский'
    },
    categories: {
      standard: 'Стандартный',
      industry: 'Отраслевой',
      legal: 'Законодательный',
      custom: 'Пользовательский'
    },
    blackoutPeriod: {
      title: 'Период блокировки',
      create: 'Создать блокировку',
      edit: 'Редактировать блокировку',
      name: 'Название',
      startDate: 'Дата начала',
      endDate: 'Дата окончания',
      reason: 'Причина',
      isRecurring: 'Повторяющийся',
      exceptions: 'Исключения'
    },
    businessRule: {
      title: 'Бизнес правило',
      create: 'Создать правило',
      edit: 'Редактировать правило',
      name: 'Название',
      type: 'Тип',
      condition: 'Условие',
      action: 'Действие',
      priority: 'Приоритет',
      types: {
        validation: 'Валидация',
        calculation: 'Расчет',
        notification: 'Уведомление',
        approval: 'Согласование'
      }
    },
    carryover: {
      title: 'Настройки переноса',
      enabled: 'Включить перенос',
      maxDays: 'Макс. дней для переноса',
      expiryDate: 'Дата истечения',
      requiresApproval: 'Требует согласования'
    },
    accrual: {
      title: 'Настройки накопления',
      method: 'Метод',
      rate: 'Ставка',
      maxAccrual: 'Макс. накопление',
      resetDate: 'Дата сброса',
      methods: {
        monthly: 'Ежемесячно',
        quarterly: 'Ежеквартально',
        annually: 'Ежегодно',
        per_hour: 'За час'
      }
    },
    validation: {
      nameRequired: 'Название схемы обязательно',
      nameExists: 'Схема с таким именем уже существует',
      nameLength: 'Название должно быть 3-50 символов',
      descriptionLength: 'Описание не более 500 символов',
      entitlementRequired: 'Количество дней обязательно',
      entitlementMin: 'Минимум 1 день',
      entitlementMax: 'Максимум 365 дней',
      dateRequired: 'Дата обязательна',
      dateInvalid: 'Неверная дата',
      dateRange: 'Дата окончания должна быть после даты начала'
    },
    status: {
      loading: 'Загрузка...',
      saving: 'Сохранение...',
      saved: 'Сохранено',
      error: 'Ошибка',
      success: 'Успешно',
      active: 'Активна',
      inactive: 'Неактивна',
      default: 'По умолчанию',
      valid: 'Валидно',
      invalid: 'Невалидно',
      warning: 'Предупреждение'
    },
    stats: {
      totalSchemes: 'Всего схем',
      activeSchemes: 'Активных схем',
      totalEmployees: 'Всего сотрудников',
      activeRequests: 'Активных заявок',
      avgDaysUsed: 'Средн. дней использовано',
      balanceUtilization: 'Использование баланса'
    },
    actions: {
      view: 'Просмотреть',
      edit: 'Редактировать',
      delete: 'Удалить',
      duplicate: 'Дублировать',
      export: 'Экспорт',
      import: 'Импорт',
      validate: 'Валидировать',
      activate: 'Активировать',
      deactivate: 'Деактивировать'
    }
  },
  en: {
    title: 'Vacation Scheme Configurator',
    subtitle: 'Manage vacation schemes and rules',
    schemes: 'Vacation Schemes',
    templates: 'Templates',
    blackouts: 'Blackout Periods',
    rules: 'Business Rules',
    balances: 'Balances',
    analytics: 'Analytics',
    createScheme: 'Create Scheme',
    editScheme: 'Edit Scheme',
    deleteScheme: 'Delete Scheme',
    duplicateScheme: 'Duplicate Scheme',
    exportScheme: 'Export Scheme',
    importScheme: 'Import Scheme',
    search: 'Search...',
    filter: 'Filter',
    save: 'Save',
    cancel: 'Cancel',
    apply: 'Apply',
    fields: {
      name: 'Scheme Name',
      description: 'Description',
      type: 'Vacation Type',
      active: 'Active',
      default: 'Default',
      entitlementDays: 'Entitlement Days',
      maxConsecutiveDays: 'Max Consecutive Days',
      minAdvanceNotice: 'Min Advance Notice (days)',
      maxAdvanceBooking: 'Max Advance Booking (days)',
      allowPartialDays: 'Allow Partial Days',
      requiresApproval: 'Requires Approval'
    },
    types: {
      annual: 'Annual Leave',
      sick: 'Sick Leave',
      unpaid: 'Unpaid Leave',
      maternity: 'Maternity Leave',
      study: 'Study Leave',
      custom: 'Custom'
    },
    categories: {
      standard: 'Standard',
      industry: 'Industry',
      legal: 'Legal',
      custom: 'Custom'
    },
    blackoutPeriod: {
      title: 'Blackout Period',
      create: 'Create Blackout',
      edit: 'Edit Blackout',
      name: 'Name',
      startDate: 'Start Date',
      endDate: 'End Date',
      reason: 'Reason',
      isRecurring: 'Recurring',
      exceptions: 'Exceptions'
    },
    businessRule: {
      title: 'Business Rule',
      create: 'Create Rule',
      edit: 'Edit Rule',
      name: 'Name',
      type: 'Type',
      condition: 'Condition',
      action: 'Action',
      priority: 'Priority',
      types: {
        validation: 'Validation',
        calculation: 'Calculation',
        notification: 'Notification',
        approval: 'Approval'
      }
    },
    carryover: {
      title: 'Carryover Settings',
      enabled: 'Enable Carryover',
      maxDays: 'Max Days to Carry',
      expiryDate: 'Expiry Date',
      requiresApproval: 'Requires Approval'
    },
    accrual: {
      title: 'Accrual Settings',
      method: 'Method',
      rate: 'Rate',
      maxAccrual: 'Max Accrual',
      resetDate: 'Reset Date',
      methods: {
        monthly: 'Monthly',
        quarterly: 'Quarterly',
        annually: 'Annually',
        per_hour: 'Per Hour'
      }
    },
    validation: {
      nameRequired: 'Scheme name is required',
      nameExists: 'Scheme name already exists',
      nameLength: 'Name must be 3-50 characters',
      descriptionLength: 'Description max 500 characters',
      entitlementRequired: 'Entitlement days required',
      entitlementMin: 'Minimum 1 day',
      entitlementMax: 'Maximum 365 days',
      dateRequired: 'Date is required',
      dateInvalid: 'Invalid date',
      dateRange: 'End date must be after start date'
    },
    status: {
      loading: 'Loading...',
      saving: 'Saving...',
      saved: 'Saved',
      error: 'Error',
      success: 'Success',
      active: 'Active',
      inactive: 'Inactive',
      default: 'Default',
      valid: 'Valid',
      invalid: 'Invalid',
      warning: 'Warning'
    },
    stats: {
      totalSchemes: 'Total Schemes',
      activeSchemes: 'Active Schemes',
      totalEmployees: 'Total Employees',
      activeRequests: 'Active Requests',
      avgDaysUsed: 'Avg Days Used',
      balanceUtilization: 'Balance Utilization'
    },
    actions: {
      view: 'View',
      edit: 'Edit',
      delete: 'Delete',
      duplicate: 'Duplicate',
      export: 'Export',
      import: 'Import',
      validate: 'Validate',
      activate: 'Activate',
      deactivate: 'Deactivate'
    }
  }
};

interface VacationSchemeConfiguratorProps {
  initialView?: 'schemes' | 'templates' | 'blackouts' | 'rules' | 'balances' | 'analytics';
  onSchemeSelect?: (scheme: VacationScheme) => void;
  onClose?: () => void;
}

const VacationSchemeConfigurator: React.FC<VacationSchemeConfiguratorProps> = ({
  initialView = 'schemes',
  onSchemeSelect,
  onClose
}) => {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [activeView, setActiveView] = useState(initialView);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  
  // Scheme management state
  const [schemes, setSchemes] = useState<VacationScheme[]>([]);
  const [templates, setTemplates] = useState<VacationSchemeTemplate[]>([]);
  const [selectedScheme, setSelectedScheme] = useState<VacationScheme | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  // Blackout periods state
  const [blackoutPeriods, setBlackoutPeriods] = useState<BlackoutPeriod[]>([]);
  const [selectedBlackout, setSelectedBlackout] = useState<BlackoutPeriod | null>(null);
  const [isCreatingBlackout, setIsCreatingBlackout] = useState(false);
  const [isEditingBlackout, setIsEditingBlackout] = useState(false);
  
  // Business rules state
  const [businessRules, setBusinessRules] = useState<BusinessRule[]>([]);
  const [selectedRule, setSelectedRule] = useState<BusinessRule | null>(null);
  const [isCreatingRule, setIsCreatingRule] = useState(false);
  const [isEditingRule, setIsEditingRule] = useState(false);
  
  // Form state
  const [formData, setFormData] = useState<Partial<VacationScheme>>({
    name: '',
    description: '',
    type: 'annual',
    isActive: true,
    isDefault: false,
    configuration: {
      entitlementDays: 20,
      maxConsecutiveDays: 14,
      minAdvanceNotice: 14,
      maxAdvanceBooking: 365,
      allowPartialDays: false,
      requiresApproval: true,
      blackoutPeriods: [],
      carryoverSettings: {
        enabled: true,
        maxDays: 5,
        expiryDate: '03-31',
        requiresApproval: false
      },
      accruralSettings: {
        method: 'annually',
        rate: 1,
        maxAccrual: 40,
        resetDate: '01-01'
      }
    },
    businessRules: [],
    applicableTo: []
  });
  
  // Blackout form state
  const [blackoutFormData, setBlackoutFormData] = useState<Partial<BlackoutPeriod>>({
    name: '',
    startDate: '',
    endDate: '',
    reason: '',
    isRecurring: false,
    exceptions: []
  });
  
  // Rule form state
  const [ruleFormData, setRuleFormData] = useState<Partial<BusinessRule>>({
    name: '',
    type: 'validation',
    condition: '',
    action: '',
    isActive: true,
    priority: 1
  });
  
  // Validation state
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [validationResult, setValidationResult] = useState<VacationValidation | null>(null);
  
  // Statistics
  const [stats, setStats] = useState({
    totalSchemes: 0,
    activeSchemes: 0,
    totalEmployees: 0,
    activeRequests: 0,
    avgDaysUsed: 0,
    balanceUtilization: 0
  });
  
  const t = translations[language];

  useEffect(() => {
    loadInitialData();
  }, []);

  const loadInitialData = async () => {
    setIsLoading(true);
    setError('');
    
    try {
      const [schemesResult, templatesResult] = await Promise.all([
        realVacationSchemeService.getVacationSchemes(),
        realVacationSchemeService.getVacationSchemeTemplates()
      ]);
      
      if (schemesResult.success && schemesResult.data) {
        setSchemes(schemesResult.data);
        setStats(prev => ({
          ...prev,
          totalSchemes: schemesResult.data.length,
          activeSchemes: schemesResult.data.filter(s => s.isActive).length
        }));
      }
      
      if (templatesResult.success && templatesResult.data) {
        setTemplates(templatesResult.data);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateScheme = () => {
    setIsCreating(true);
    setIsEditing(false);
    setSelectedScheme(null);
    setFormData({
      name: '',
      description: '',
      type: 'annual',
      isActive: true,
      isDefault: false,
      configuration: {
        entitlementDays: 20,
        maxConsecutiveDays: 14,
        minAdvanceNotice: 14,
        maxAdvanceBooking: 365,
        allowPartialDays: false,
        requiresApproval: true,
        blackoutPeriods: [],
        carryoverSettings: {
          enabled: true,
          maxDays: 5,
          expiryDate: '03-31',
          requiresApproval: false
        },
        accruralSettings: {
          method: 'annually',
          rate: 1,
          maxAccrual: 40,
          resetDate: '01-01'
        }
      },
      businessRules: [],
      applicableTo: []
    });
    setValidationErrors([]);
    setValidationResult(null);
  };

  const handleEditScheme = (scheme: VacationScheme) => {
    setIsEditing(true);
    setIsCreating(false);
    setSelectedScheme(scheme);
    setFormData(scheme);
    setValidationErrors([]);
    setValidationResult(null);
  };

  const handleSaveScheme = async () => {
    if (!(await validateSchemeForm())) {
      return;
    }
    
    setIsSaving(true);
    setError('');
    
    try {
      let result;
      
      if (isCreating) {
        result = await realVacationSchemeService.createVacationScheme(
          formData as Omit<VacationScheme, 'id' | 'createdDate' | 'lastModified' | 'createdBy'>
        );
      } else if (selectedScheme) {
        result = await realVacationSchemeService.updateVacationScheme(selectedScheme.id, formData);
      }
      
      if (result?.success && result.data) {
        if (isCreating) {
          setSchemes(prev => [...prev, result.data]);
        } else {
          setSchemes(prev => prev.map(s => s.id === result.data.id ? result.data : s));
        }
        
        setIsCreating(false);
        setIsEditing(false);
        setSelectedScheme(null);
        
        if (onSchemeSelect && result.data) {
          onSchemeSelect(result.data);
        }
      } else {
        setError(result?.error || 'Failed to save scheme');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save scheme');
    } finally {
      setIsSaving(false);
    }
  };

  const validateSchemeForm = async (): Promise<boolean> => {
    const errors: string[] = [];
    
    if (!formData.name?.trim()) {
      errors.push(t.validation.nameRequired);
    }
    
    if (formData.name && (formData.name.length < 3 || formData.name.length > 50)) {
      errors.push(t.validation.nameLength);
    }
    
    if (formData.description && formData.description.length > 500) {
      errors.push(t.validation.descriptionLength);
    }
    
    if (!formData.configuration?.entitlementDays) {
      errors.push(t.validation.entitlementRequired);
    }
    
    if (formData.configuration?.entitlementDays && formData.configuration.entitlementDays < 1) {
      errors.push(t.validation.entitlementMin);
    }
    
    if (formData.configuration?.entitlementDays && formData.configuration.entitlementDays > 365) {
      errors.push(t.validation.entitlementMax);
    }
    
    // Check for name uniqueness
    if (formData.name && (!selectedScheme || selectedScheme.name !== formData.name)) {
      const existingScheme = schemes.find(s => s.name === formData.name);
      if (existingScheme) {
        errors.push(t.validation.nameExists);
      }
    }
    
    setValidationErrors(errors);
    
    // Server-side validation
    if (errors.length === 0) {
      const validationResult = await realVacationSchemeService.validateVacationScheme(formData);
      
      if (validationResult.success && validationResult.data) {
        setValidationResult(validationResult.data);
        if (!validationResult.data.valid) {
          setValidationErrors(validationResult.data.violations);
          return false;
        }
      }
    }
    
    return errors.length === 0;
  };

  const handleDeleteScheme = async (schemeId: string) => {
    if (!confirm('Вы уверены, что хотите удалить эту схему отпуска?')) {
      return;
    }
    
    try {
      const result = await realVacationSchemeService.deleteVacationScheme(schemeId);
      if (result.success) {
        setSchemes(prev => prev.filter(s => s.id !== schemeId));
      } else {
        setError(result.error || 'Failed to delete scheme');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete scheme');
    }
  };

  const handleDuplicateScheme = async (schemeId: string) => {
    const scheme = schemes.find(s => s.id === schemeId);
    if (!scheme) return;
    
    const newName = `${scheme.name} (копия)`;
    
    try {
      const result = await realVacationSchemeService.duplicateVacationScheme(schemeId, newName);
      if (result.success && result.data) {
        setSchemes(prev => [...prev, result.data]);
      } else {
        setError(result.error || 'Failed to duplicate scheme');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to duplicate scheme');
    }
  };

  const applyTemplate = (template: VacationSchemeTemplate) => {
    setFormData(prev => ({
      ...prev,
      ...template.template,
      name: template.russianName
    }));
  };

  const getFilteredSchemes = () => {
    return schemes.filter(scheme => {
      const matchesSearch = scheme.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          scheme.description.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesType = filterType === 'all' || scheme.type === filterType;
      return matchesSearch && matchesType;
    });
  };

  const getSchemeTypeColor = (type: string) => {
    switch (type) {
      case 'annual': return 'bg-green-100 text-green-800';
      case 'sick': return 'bg-red-100 text-red-800';
      case 'unpaid': return 'bg-gray-100 text-gray-800';
      case 'maternity': return 'bg-pink-100 text-pink-800';
      case 'study': return 'bg-blue-100 text-blue-800';
      default: return 'bg-purple-100 text-purple-800';
    }
  };

  const getValidationStatusColor = (validation: VacationValidation) => {
    if (validation.valid) return 'text-green-600';
    if (validation.violations.length > 0) return 'text-red-600';
    if (validation.warnings.length > 0) return 'text-yellow-600';
    return 'text-gray-600';
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">{t.status.loading}</span>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg h-full flex flex-col">
      {/* Header */}
      <div className="border-b px-6 py-4 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">{t.title}</h2>
          <p className="text-sm text-gray-600">{t.subtitle}</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
            className="p-2 text-gray-500 hover:text-gray-700"
          >
            <Globe className="h-4 w-4" />
          </button>
          {onClose && (
            <button
              onClick={onClose}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mx-6 mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-3" />
          <div>
            <p className="font-medium text-red-800">{t.status.error}</p>
            <p className="text-red-700 text-sm">{error}</p>
          </div>
        </div>
      )}

      {/* Statistics */}
      <div className="px-6 py-4 bg-gray-50 border-b">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">{stats.totalSchemes}</div>
            <div className="text-sm text-gray-600">{t.stats.totalSchemes}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-600">{stats.activeSchemes}</div>
            <div className="text-sm text-gray-600">{t.stats.activeSchemes}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{stats.totalEmployees}</div>
            <div className="text-sm text-gray-600">{t.stats.totalEmployees}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-purple-600">{stats.activeRequests}</div>
            <div className="text-sm text-gray-600">{t.stats.activeRequests}</div>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="border-b">
        <nav className="flex px-6">
          <button
            onClick={() => setActiveView('schemes')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'schemes'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Calendar className="h-4 w-4 inline mr-2" />
            {t.schemes}
          </button>
          <button
            onClick={() => setActiveView('templates')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'templates'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <FileText className="h-4 w-4 inline mr-2" />
            {t.templates}
          </button>
          <button
            onClick={() => setActiveView('blackouts')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'blackouts'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Ban className="h-4 w-4 inline mr-2" />
            {t.blackouts}
          </button>
          <button
            onClick={() => setActiveView('rules')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'rules'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Settings className="h-4 w-4 inline mr-2" />
            {t.rules}
          </button>
          <button
            onClick={() => setActiveView('analytics')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'analytics'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <TrendingUp className="h-4 w-4 inline mr-2" />
            {t.analytics}
          </button>
        </nav>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden flex">
        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          {activeView === 'schemes' && (
            <div className="p-6">
              {/* Controls */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
                    <input
                      type="text"
                      placeholder={t.search}
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <select
                    value={filterType}
                    onChange={(e) => setFilterType(e.target.value)}
                    className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">Все типы</option>
                    <option value="annual">{t.types.annual}</option>
                    <option value="sick">{t.types.sick}</option>
                    <option value="unpaid">{t.types.unpaid}</option>
                    <option value="maternity">{t.types.maternity}</option>
                    <option value="study">{t.types.study}</option>
                    <option value="custom">{t.types.custom}</option>
                  </select>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => {/* handleImportScheme */}}
                    className="flex items-center gap-2 px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    <Upload className="h-4 w-4" />
                    {t.importScheme}
                  </button>
                  <button
                    onClick={handleCreateScheme}
                    className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    <Plus className="h-4 w-4" />
                    {t.createScheme}
                  </button>
                </div>
              </div>

              {/* Schemes List */}
              <div className="space-y-4">
                {getFilteredSchemes().map((scheme) => (
                  <div
                    key={scheme.id}
                    className="border rounded-lg p-4 hover:shadow-md transition-shadow"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="text-lg font-medium text-gray-900">{scheme.name}</h3>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getSchemeTypeColor(scheme.type)}`}>
                            {t.types[scheme.type as keyof typeof t.types]}
                          </span>
                          {scheme.isDefault && (
                            <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium">
                              {t.status.default}
                            </span>
                          )}
                        </div>
                        <p className="text-gray-600 text-sm mb-2">{scheme.description}</p>
                        <div className="flex items-center gap-4 text-sm text-gray-500">
                          <span>{scheme.configuration.entitlementDays} дней</span>
                          <span className={scheme.isActive ? 'text-green-600' : 'text-gray-400'}>
                            {scheme.isActive ? t.status.active : t.status.inactive}
                          </span>
                          <span>
                            {scheme.configuration.requiresApproval ? 'Требует согласования' : 'Автоматическое'}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleEditScheme(scheme)}
                          className="p-2 text-gray-500 hover:text-gray-700"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDuplicateScheme(scheme.id)}
                          className="p-2 text-gray-500 hover:text-gray-700"
                        >
                          <Copy className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => {/* handleExportScheme */}}
                          className="p-2 text-gray-500 hover:text-gray-700"
                        >
                          <Download className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteScheme(scheme.id)}
                          className="p-2 text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeView === 'templates' && (
            <div className="p-6">
              <div className="space-y-6">
                <div className="text-center py-12">
                  <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">{t.templates}</h3>
                  <p className="text-gray-600">Шаблоны схем отпусков для быстрого создания</p>
                </div>
                
                {templates.length > 0 && (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {templates.map((template) => (
                      <div
                        key={template.id}
                        className="border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
                        onClick={() => applyTemplate(template)}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <h4 className="font-medium text-gray-900">{template.russianName}</h4>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            template.category === 'standard' ? 'bg-blue-100 text-blue-800' :
                            template.category === 'legal' ? 'bg-green-100 text-green-800' :
                            'bg-gray-100 text-gray-800'
                          }`}>
                            {t.categories[template.category as keyof typeof t.categories]}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600">{template.description}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {activeView === 'blackouts' && (
            <div className="p-6">
              <div className="text-center py-12">
                <Ban className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">{t.blackouts}</h3>
                <p className="text-gray-600">Управление периодами блокировки отпусков</p>
              </div>
            </div>
          )}

          {activeView === 'rules' && (
            <div className="p-6">
              <div className="text-center py-12">
                <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">{t.rules}</h3>
                <p className="text-gray-600">Настройка бизнес-правил для схем отпусков</p>
              </div>
            </div>
          )}

          {activeView === 'analytics' && (
            <div className="p-6">
              <div className="text-center py-12">
                <TrendingUp className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">{t.analytics}</h3>
                <p className="text-gray-600">Аналитика использования схем отпусков</p>
              </div>
            </div>
          )}
        </div>

        {/* Side Panel for Scheme Creation/Editing */}
        {(isCreating || isEditing) && (
          <div className="w-96 border-l bg-gray-50 p-6 overflow-y-auto">
            <div className="mb-6">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {isCreating ? t.createScheme : t.editScheme}
              </h3>
              <p className="text-sm text-gray-600">
                {isCreating ? 'Создание новой схемы отпуска' : 'Редактирование существующей схемы'}
              </p>
            </div>

            {/* Form */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.name}
                </label>
                <input
                  type="text"
                  value={formData.name || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Введите название схемы"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.description}
                </label>
                <textarea
                  value={formData.description || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Описание схемы отпуска"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.type}
                </label>
                <select
                  value={formData.type || 'annual'}
                  onChange={(e) => setFormData(prev => ({ ...prev, type: e.target.value as any }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="annual">{t.types.annual}</option>
                  <option value="sick">{t.types.sick}</option>
                  <option value="unpaid">{t.types.unpaid}</option>
                  <option value="maternity">{t.types.maternity}</option>
                  <option value="study">{t.types.study}</option>
                  <option value="custom">{t.types.custom}</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.fields.entitlementDays}
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="365"
                    value={formData.configuration?.entitlementDays || 20}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        entitlementDays: parseInt(e.target.value)
                      }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.fields.maxConsecutiveDays}
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={formData.configuration?.maxConsecutiveDays || 14}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        maxConsecutiveDays: parseInt(e.target.value)
                      }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.fields.minAdvanceNotice}
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={formData.configuration?.minAdvanceNotice || 14}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        minAdvanceNotice: parseInt(e.target.value)
                      }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.fields.maxAdvanceBooking}
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={formData.configuration?.maxAdvanceBooking || 365}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        maxAdvanceBooking: parseInt(e.target.value)
                      }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.isActive || false}
                    onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.active}</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.isDefault || false}
                    onChange={(e) => setFormData(prev => ({ ...prev, isDefault: e.target.checked }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.default}</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.configuration?.allowPartialDays || false}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        allowPartialDays: e.target.checked
                      }
                    }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.allowPartialDays}</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.configuration?.requiresApproval || false}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      configuration: {
                        ...prev.configuration!,
                        requiresApproval: e.target.checked
                      }
                    }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.requiresApproval}</span>
                </label>
              </div>

              {/* Validation Results */}
              {validationResult && (
                <div className={`p-4 rounded-lg ${
                  validationResult.valid ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'
                }`}>
                  <div className="flex items-center mb-2">
                    {validationResult.valid ? (
                      <CheckCircle className="h-5 w-5 text-green-600 mr-2" />
                    ) : (
                      <AlertCircle className="h-5 w-5 text-red-600 mr-2" />
                    )}
                    <p className={`font-medium ${validationResult.valid ? 'text-green-800' : 'text-red-800'}`}>
                      {validationResult.valid ? t.status.valid : t.status.invalid}
                    </p>
                  </div>
                  {validationResult.violations.length > 0 && (
                    <ul className="text-red-700 text-sm space-y-1">
                      {validationResult.violations.map((violation, index) => (
                        <li key={index}>• {violation}</li>
                      ))}
                    </ul>
                  )}
                  {validationResult.warnings.length > 0 && (
                    <ul className="text-yellow-700 text-sm space-y-1">
                      {validationResult.warnings.map((warning, index) => (
                        <li key={index}>⚠ {warning}</li>
                      ))}
                    </ul>
                  )}
                </div>
              )}

              {/* Validation Errors */}
              {validationErrors.length > 0 && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <div className="flex items-center mb-2">
                    <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
                    <p className="font-medium text-red-800">Ошибки валидации:</p>
                  </div>
                  <ul className="text-red-700 text-sm space-y-1">
                    {validationErrors.map((error, index) => (
                      <li key={index}>• {error}</li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-3 pt-4">
                <button
                  onClick={handleSaveScheme}
                  disabled={isSaving}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {isSaving ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  {isSaving ? t.status.saving : t.save}
                </button>
                <button
                  onClick={() => {
                    setIsCreating(false);
                    setIsEditing(false);
                    setSelectedScheme(null);
                  }}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  {t.cancel}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VacationSchemeConfigurator;