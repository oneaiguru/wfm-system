import React, { useState, useEffect } from 'react';
import { Settings, Database, Shield, Bell, Globe, Save, RotateCcw, AlertCircle, CheckCircle, Loader2, Users, Server } from 'lucide-react';

interface SystemConfig {
  id: string;
  category: string;
  key: string;
  value: string;
  description: string;
  type: 'string' | 'number' | 'boolean' | 'select';
  options?: string[];
  required: boolean;
}

interface Employee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}

const SystemSettings: React.FC = () => {
  const [configs, setConfigs] = useState<SystemConfig[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [activeTab, setActiveTab] = useState('general');
  const [hasChanges, setHasChanges] = useState(false);
  const [employeeStats, setEmployeeStats] = useState({ total: 0, active: 0, inactive: 0 });

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

  // Initialize system configuration with defaults
  const initializeSystemConfig = (): SystemConfig[] => {
    return [
      {
        id: 'sys_001',
        category: 'general',
        key: 'system_name',
        value: 'WFM System',
        description: 'Название системы управления персоналом',
        type: 'string',
        required: true
      },
      {
        id: 'sys_002', 
        category: 'general',
        key: 'max_employees',
        value: '1000',
        description: 'Максимальное количество сотрудников в системе',
        type: 'number',
        required: true
      },
      {
        id: 'sys_003',
        category: 'security',
        key: 'session_timeout',
        value: '30',
        description: 'Время истечения сессии (минуты)',
        type: 'number',
        required: true
      },
      {
        id: 'sys_004',
        category: 'security',
        key: 'password_policy',
        value: 'strong',
        description: 'Политика паролей',
        type: 'select',
        options: ['weak', 'medium', 'strong'],
        required: true
      },
      {
        id: 'sys_005',
        category: 'notifications',
        key: 'enable_email_notifications',
        value: 'true',
        description: 'Включить email уведомления',
        type: 'boolean',
        required: false
      },
      {
        id: 'sys_006',
        category: 'localization',
        key: 'default_language',
        value: 'ru',
        description: 'Язык системы по умолчанию',
        type: 'select',
        options: ['ru', 'en', 'ky'],
        required: true
      },
      {
        id: 'sys_007',
        category: 'database',
        key: 'backup_frequency',
        value: 'daily',
        description: 'Частота резервного копирования',
        type: 'select',
        options: ['hourly', 'daily', 'weekly'],
        required: true
      }
    ];
  };

  // Fetch employees data to populate config context
  const fetchEmployees = async () => {
    try {
      console.log(`[SYSTEM SETTINGS] Fetching employees from: ${API_BASE_URL}/employees/list`);
      
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeData = await response.json();
      console.log('[SYSTEM SETTINGS] Employees fetched:', employeeData);
      
      setEmployees(employeeData);
      
      // Calculate stats
      const active = employeeData.filter((emp: Employee) => emp.is_active).length;
      const inactive = employeeData.length - active;
      setEmployeeStats({
        total: employeeData.length,
        active,
        inactive
      });

      // Update dynamic configs based on actual data
      const dynamicConfigs = initializeSystemConfig().map(config => {
        if (config.key === 'max_employees') {
          return { ...config, value: Math.max(employeeData.length * 2, 100).toString() };
        }
        return config;
      });
      
      setConfigs(dynamicConfigs);
      
    } catch (err) {
      console.error('[SYSTEM SETTINGS] Error fetching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      // Set default configs even on error
      setConfigs(initializeSystemConfig());
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

  const handleConfigChange = (configId: string, newValue: string) => {
    setConfigs(prev => prev.map(config => 
      config.id === configId ? { ...config, value: newValue } : config
    ));
    setHasChanges(true);
    setSuccess('');
  };

  const handleSave = async () => {
    setSaving(true);
    setError('');
    
    try {
      // Simulate saving configuration
      console.log('[SYSTEM SETTINGS] Saving configurations:', configs);
      
      // In a real implementation, this would save to the backend
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setSuccess('Настройки системы успешно сохранены');
      setHasChanges(false);
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка сохранения настроек');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    setConfigs(initializeSystemConfig());
    setHasChanges(false);
    setSuccess('');
    setError('');
  };

  const renderConfigField = (config: SystemConfig) => {
    const commonProps = {
      id: config.id,
      required: config.required,
      className: "block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
    };

    switch (config.type) {
      case 'boolean':
        return (
          <select
            {...commonProps}
            value={config.value}
            onChange={(e) => handleConfigChange(config.id, e.target.value)}
          >
            <option value="true">Включено</option>
            <option value="false">Отключено</option>
          </select>
        );
      
      case 'select':
        return (
          <select
            {...commonProps}
            value={config.value}
            onChange={(e) => handleConfigChange(config.id, e.target.value)}
          >
            {config.options?.map(option => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        );
      
      case 'number':
        return (
          <input
            type="number"
            {...commonProps}
            value={config.value}
            onChange={(e) => handleConfigChange(config.id, e.target.value)}
          />
        );
      
      default:
        return (
          <input
            type="text"
            {...commonProps}
            value={config.value}
            onChange={(e) => handleConfigChange(config.id, e.target.value)}
          />
        );
    }
  };

  const getTabIcon = (tab: string) => {
    switch (tab) {
      case 'general': return <Settings className="h-4 w-4" />;
      case 'security': return <Shield className="h-4 w-4" />;
      case 'notifications': return <Bell className="h-4 w-4" />;
      case 'localization': return <Globe className="h-4 w-4" />;
      case 'database': return <Database className="h-4 w-4" />;
      default: return <Settings className="h-4 w-4" />;
    }
  };

  const tabs = [
    { id: 'general', name: 'Общие' },
    { id: 'security', name: 'Безопасность' },
    { id: 'notifications', name: 'Уведомления' },
    { id: 'localization', name: 'Локализация' },
    { id: 'database', name: 'База данных' }
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Загрузка настроек системы...</p>
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
            <h1 className="text-2xl font-semibold text-gray-900">Настройки системы</h1>
            <p className="text-gray-600 mt-1">Управление конфигурацией системы WFM</p>
          </div>
          <div className="flex items-center space-x-3">
            {hasChanges && (
              <span className="text-sm text-orange-600 flex items-center">
                <AlertCircle className="h-4 w-4 mr-1" />
                Есть несохраненные изменения
              </span>
            )}
            <button
              onClick={handleReset}
              disabled={isSaving}
              className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              <RotateCcw className="h-4 w-4 mr-2" />
              Сбросить
            </button>
            <button
              onClick={handleSave}
              disabled={!hasChanges || isSaving}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
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

      {/* System Stats */}
      <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="flex items-center">
            <Users className="h-8 w-8 text-blue-600 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Всего сотрудников</p>
              <p className="text-lg font-semibold">{employeeStats.total}</p>
            </div>
          </div>
          <div className="flex items-center">
            <Server className="h-8 w-8 text-green-600 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Активных</p>
              <p className="text-lg font-semibold text-green-600">{employeeStats.active}</p>
            </div>
          </div>
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Неактивных</p>
              <p className="text-lg font-semibold text-red-600">{employeeStats.inactive}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="px-6 pt-4">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            {tabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {getTabIcon(tab.id)}
                <span>{tab.name}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Configuration Form */}
      <div className="p-6">
        <div className="space-y-6">
          {configs
            .filter(config => config.category === activeTab)
            .map(config => (
              <div key={config.id}>
                <label htmlFor={config.id} className="block text-sm font-medium text-gray-700 mb-2">
                  {config.description}
                  {config.required && <span className="text-red-500 ml-1">*</span>}
                </label>
                {renderConfigField(config)}
                <p className="mt-1 text-xs text-gray-500">
                  Ключ: {config.key} | Тип: {config.type}
                </p>
              </div>
            ))}
        </div>

        {configs.filter(config => config.category === activeTab).length === 0 && (
          <div className="text-center py-8">
            <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Нет настроек</h3>
            <p className="text-gray-600">В этой категории пока нет настроек</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default SystemSettings;