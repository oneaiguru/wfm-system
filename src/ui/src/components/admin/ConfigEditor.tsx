import React, { useState, useEffect } from 'react';
import { Settings, Upload, Download, Save, Check, X, AlertCircle, CheckCircle, Loader2, FileText, Database, Users, Edit3, RotateCcw } from 'lucide-react';

interface BulkConfigItem {
  id: string;
  employeeId: string;
  employeeName: string;
  field: string;
  oldValue: string;
  newValue: string;
  status: 'pending' | 'applied' | 'error';
  errorMessage?: string;
}

interface ConfigTemplate {
  id: string;
  name: string;
  description: string;
  fields: ConfigField[];
}

interface ConfigField {
  key: string;
  label: string;
  type: 'text' | 'select' | 'boolean' | 'number';
  options?: string[];
  required: boolean;
  description: string;
}

interface Employee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}

const ConfigEditor: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [templates, setTemplates] = useState<ConfigTemplate[]>([]);
  const [bulkChanges, setBulkChanges] = useState<BulkConfigItem[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [isApplying, setIsApplying] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [csvData, setCsvData] = useState('');
  const [showPreview, setShowPreview] = useState(false);
  const [activeTab, setActiveTab] = useState('template');

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

  // Initialize configuration templates
  const initializeTemplates = (): ConfigTemplate[] => {
    return [
      {
        id: 'employee_status',
        name: 'Статус сотрудников',
        description: 'Массовое изменение статуса активности сотрудников',
        fields: [
          {
            key: 'is_active',
            label: 'Статус активности',
            type: 'boolean',
            required: true,
            description: 'Активен ли сотрудник в системе'
          }
        ]
      },
      {
        id: 'employee_roles',
        name: 'Роли сотрудников',
        description: 'Массовое назначение ролей сотрудникам',
        fields: [
          {
            key: 'role',
            label: 'Роль',
            type: 'select',
            options: ['operator', 'supervisor', 'manager', 'admin'],
            required: true,
            description: 'Роль пользователя в системе'
          }
        ]
      },
      {
        id: 'employee_departments',
        name: 'Отделы сотрудников',
        description: 'Массовое изменение отделов',
        fields: [
          {
            key: 'department',
            label: 'Отдел',
            type: 'select',
            options: ['Call Center', 'Sales', 'Support', 'Management', 'HR', 'IT'],
            required: true,
            description: 'Подразделение сотрудника'
          }
        ]
      },
      {
        id: 'employee_shifts',
        name: 'Смены сотрудников',
        description: 'Массовое назначение предпочтительных смен',
        fields: [
          {
            key: 'preferred_shift',
            label: 'Предпочтительная смена',
            type: 'select',
            options: ['morning', 'day', 'evening', 'night', 'flexible'],
            required: false,
            description: 'Предпочтительное время работы'
          },
          {
            key: 'max_hours_per_week',
            label: 'Максимум часов в неделю',
            type: 'number',
            required: false,
            description: 'Максимальное количество рабочих часов в неделю'
          }
        ]
      }
    ];
  };

  // Fetch employees data
  const fetchEmployees = async () => {
    try {
      console.log(`[CONFIG EDITOR] Fetching employees from: ${API_BASE_URL}/employees/list`);
      
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeData = await response.json();
      console.log('[CONFIG EDITOR] Employees fetched:', employeeData);
      
      setEmployees(employeeData);
      setTemplates(initializeTemplates());
      
    } catch (err) {
      console.error('[CONFIG EDITOR] Error fetching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      // Set defaults even on error
      setEmployees([]);
      setTemplates(initializeTemplates());
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

  // Generate bulk changes from template
  const generateFromTemplate = () => {
    const template = templates.find(t => t.id === selectedTemplate);
    if (!template || !employees.length) return;

    const changes: BulkConfigItem[] = [];
    
    employees.forEach(emp => {
      template.fields.forEach(field => {
        let oldValue = '';
        let newValue = '';
        
        // Mock current values based on field
        switch (field.key) {
          case 'is_active':
            oldValue = emp.is_active.toString();
            newValue = 'true'; // Default new value
            break;
          case 'role':
            oldValue = emp.email?.includes('admin') ? 'admin' : 
                      emp.first_name?.toLowerCase().includes('manager') ? 'manager' : 'operator';
            newValue = 'operator'; // Default new value
            break;
          case 'department':
            oldValue = 'Call Center'; // Mock current value
            newValue = 'Call Center'; // Default new value
            break;
          case 'preferred_shift':
            oldValue = 'day'; // Mock current value
            newValue = 'day'; // Default new value
            break;
          case 'max_hours_per_week':
            oldValue = '40'; // Mock current value
            newValue = '40'; // Default new value
            break;
          default:
            oldValue = '';
            newValue = '';
        }

        changes.push({
          id: `${emp.id}_${field.key}_${Date.now()}`,
          employeeId: emp.id.toString(),
          employeeName: `${emp.first_name} ${emp.last_name}`,
          field: field.key,
          oldValue,
          newValue,
          status: 'pending'
        });
      });
    });

    setBulkChanges(changes);
    setShowPreview(true);
  };

  // Parse CSV data
  const parseCsvData = () => {
    if (!csvData.trim()) {
      setError('CSV данные не введены');
      return;
    }

    try {
      const lines = csvData.trim().split('\n');
      const headers = lines[0].split(',').map(h => h.trim());
      
      // Validate headers
      const requiredHeaders = ['employee_id', 'field', 'new_value'];
      const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));
      if (missingHeaders.length > 0) {
        setError(`Отсутствуют обязательные столбцы: ${missingHeaders.join(', ')}`);
        return;
      }

      const changes: BulkConfigItem[] = [];
      
      for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(',').map(v => v.trim());
        if (values.length !== headers.length) continue;

        const rowData: Record<string, string> = {};
        headers.forEach((header, index) => {
          rowData[header] = values[index];
        });

        const employee = employees.find(emp => emp.id.toString() === rowData.employee_id);
        if (!employee) {
          console.warn(`Employee not found: ${rowData.employee_id}`);
          continue;
        }

        changes.push({
          id: `csv_${i}_${Date.now()}`,
          employeeId: rowData.employee_id,
          employeeName: `${employee.first_name} ${employee.last_name}`,
          field: rowData.field,
          oldValue: rowData.old_value || 'N/A',
          newValue: rowData.new_value,
          status: 'pending'
        });
      }

      setBulkChanges(changes);
      setShowPreview(true);
      setError('');
      
    } catch (err) {
      setError('Ошибка парсинга CSV данных: ' + (err instanceof Error ? err.message : 'Неизвестная ошибка'));
    }
  };

  // Apply bulk changes
  const applyBulkChanges = async () => {
    if (bulkChanges.length === 0) return;

    setIsApplying(true);
    setError('');

    try {
      console.log('[CONFIG EDITOR] Applying bulk changes:', bulkChanges);

      // Prepare bulk update data
      const bulkUpdateData = {
        updates: bulkChanges.map(change => ({
          employee_id: change.employeeId,
          field: change.field,
          value: change.newValue
        }))
      };

      // Use POST bulk endpoint
      const response = await fetch(`${API_BASE_URL}/employees/bulk`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(bulkUpdateData)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Failed to apply bulk changes`);
      }

      const result = await response.json();
      console.log('[CONFIG EDITOR] Bulk update result:', result);

      // Update status of changes
      setBulkChanges(prev => prev.map(change => ({
        ...change,
        status: 'applied' as const
      })));

      setSuccess(`Массовые изменения успешно применены к ${bulkChanges.length} записям`);
      
      // Clear success message after 5 seconds
      setTimeout(() => setSuccess(''), 5000);
      
    } catch (err) {
      console.error('[CONFIG EDITOR] Error applying bulk changes:', err);
      
      // Mark all changes as error
      setBulkChanges(prev => prev.map(change => ({
        ...change,
        status: 'error' as const,
        errorMessage: err instanceof Error ? err.message : 'Неизвестная ошибка'
      })));
      
      setError(err instanceof Error ? err.message : 'Ошибка применения изменений');
    } finally {
      setIsApplying(false);
    }
  };

  const updateChangeValue = (changeId: string, newValue: string) => {
    setBulkChanges(prev => prev.map(change => 
      change.id === changeId ? { ...change, newValue } : change
    ));
  };

  const removeChange = (changeId: string) => {
    setBulkChanges(prev => prev.filter(change => change.id !== changeId));
  };

  const clearAllChanges = () => {
    setBulkChanges([]);
    setShowPreview(false);
    setCsvData('');
    setSelectedTemplate('');
  };

  const exportTemplate = () => {
    const csvContent = [
      'employee_id,employee_name,field,old_value,new_value',
      ...employees.slice(0, 5).map(emp => 
        `${emp.id},"${emp.first_name} ${emp.last_name}",is_active,true,true`
      )
    ].join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'bulk_config_template.csv';
    link.click();
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'applied': return <Check className="h-4 w-4 text-green-600" />;
      case 'error': return <X className="h-4 w-4 text-red-600" />;
      default: return <Edit3 className="h-4 w-4 text-blue-600" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'applied': return 'bg-green-100 text-green-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-blue-100 text-blue-800';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Загрузка редактора конфигураций...</p>
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
            <h1 className="text-2xl font-semibold text-gray-900">Массовое редактирование конфигураций</h1>
            <p className="text-gray-600 mt-1">Групповое изменение настроек сотрудников</p>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={exportTemplate}
              className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <Download className="h-4 w-4 mr-2" />
              Шаблон CSV
            </button>
            {bulkChanges.length > 0 && (
              <button
                onClick={clearAllChanges}
                className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <RotateCcw className="h-4 w-4 mr-2" />
                Очистить
              </button>
            )}
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

      {/* Tab Navigation */}
      <div className="px-6 pt-4">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('template')}
              className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === 'template'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Settings className="h-4 w-4" />
              <span>Шаблоны</span>
            </button>
            <button
              onClick={() => setActiveTab('csv')}
              className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === 'csv'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <FileText className="h-4 w-4" />
              <span>CSV Import</span>
            </button>
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {activeTab === 'template' && (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Выберите шаблон конфигурации
              </label>
              <select
                value={selectedTemplate}
                onChange={(e) => setSelectedTemplate(e.target.value)}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">-- Выберите шаблон --</option>
                {templates.map(template => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
              {selectedTemplate && (
                <p className="mt-2 text-sm text-gray-600">
                  {templates.find(t => t.id === selectedTemplate)?.description}
                </p>
              )}
            </div>

            {selectedTemplate && (
              <div className="border border-gray-200 rounded-lg p-4">
                <h4 className="font-medium text-gray-900 mb-3">Поля шаблона:</h4>
                <div className="space-y-3">
                  {templates.find(t => t.id === selectedTemplate)?.fields.map(field => (
                    <div key={field.key} className="flex items-center justify-between p-3 bg-gray-50 rounded-md">
                      <div>
                        <p className="font-medium text-sm text-gray-900">{field.label}</p>
                        <p className="text-xs text-gray-600">{field.description}</p>
                        <p className="text-xs text-gray-500">
                          Тип: {field.type} | {field.required ? 'Обязательное' : 'Опциональное'}
                        </p>
                      </div>
                      {field.type === 'select' && field.options && (
                        <div className="text-xs text-gray-600">
                          Варианты: {field.options.join(', ')}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                <button
                  onClick={generateFromTemplate}
                  disabled={!selectedTemplate}
                  className="mt-4 flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                >
                  <Database className="h-4 w-4 mr-2" />
                  Сгенерировать изменения
                </button>
              </div>
            )}
          </div>
        )}

        {activeTab === 'csv' && (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                CSV данные для импорта
              </label>
              <p className="text-sm text-gray-600 mb-3">
                Формат: employee_id,field,old_value,new_value (один заголовок на первой строке)
              </p>
              <textarea
                value={csvData}
                onChange={(e) => setCsvData(e.target.value)}
                rows={10}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 font-mono text-sm"
                placeholder={`employee_id,field,old_value,new_value
1,is_active,false,true
2,role,operator,supervisor
3,department,Call Center,Sales`}
              />
            </div>
            <button
              onClick={parseCsvData}
              disabled={!csvData.trim()}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              <Upload className="h-4 w-4 mr-2" />
              Импортировать CSV
            </button>
          </div>
        )}

        {/* Preview Changes */}
        {showPreview && bulkChanges.length > 0 && (
          <div className="mt-8 border-t border-gray-200 pt-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">
                Предварительный просмотр изменений ({bulkChanges.length})
              </h3>
              <button
                onClick={applyBulkChanges}
                disabled={isApplying || bulkChanges.every(c => c.status === 'applied')}
                className="flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 disabled:opacity-50"
              >
                {isApplying ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                Применить изменения
              </button>
            </div>

            <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
              <table className="min-w-full divide-y divide-gray-300">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Сотрудник
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Поле
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Старое значение
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Новое значение
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Статус
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Действия
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {bulkChanges.map((change) => (
                    <tr key={change.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <div className="flex items-center">
                          <Users className="h-4 w-4 text-gray-400 mr-2" />
                          {change.employeeName}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {change.field}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {change.oldValue}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {change.status === 'pending' ? (
                          <input
                            type="text"
                            value={change.newValue}
                            onChange={(e) => updateChangeValue(change.id, e.target.value)}
                            className="block w-full px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                          />
                        ) : (
                          change.newValue
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(change.status)}`}>
                          {getStatusIcon(change.status)}
                          <span className="ml-1 capitalize">{change.status}</span>
                        </span>
                        {change.errorMessage && (
                          <p className="text-xs text-red-600 mt-1">{change.errorMessage}</p>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        {change.status === 'pending' && (
                          <button
                            onClick={() => removeChange(change.id)}
                            className="text-red-600 hover:text-red-900"
                          >
                            Удалить
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Summary */}
            <div className="mt-4 p-4 bg-gray-50 rounded-md">
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-blue-500 rounded-full mr-2" />
                  <span>Ожидает: {bulkChanges.filter(c => c.status === 'pending').length}</span>
                </div>
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-green-500 rounded-full mr-2" />
                  <span>Применено: {bulkChanges.filter(c => c.status === 'applied').length}</span>
                </div>
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-red-500 rounded-full mr-2" />
                  <span>Ошибки: {bulkChanges.filter(c => c.status === 'error').length}</span>
                </div>
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-gray-500 rounded-full mr-2" />
                  <span>Всего: {bulkChanges.length}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Empty State */}
        {!showPreview && (
          <div className="text-center py-12 border-2 border-dashed border-gray-300 rounded-lg">
            <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Нет изменений для предварительного просмотра</h3>
            <p className="text-gray-600">Выберите шаблон или импортируйте CSV файл для начала работы</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ConfigEditor;