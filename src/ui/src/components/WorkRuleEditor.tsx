import React, { useState, useEffect } from 'react';
import {
  Settings,
  Clock,
  Calendar,
  Plus,
  Save,
  X,
  Copy,
  AlertTriangle,
  CheckCircle,
  Globe,
  RotateCcw
} from 'lucide-react';
import realWorkRuleService, { WorkRule, WorkRuleTemplate } from '../services/realWorkRuleService';

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Редактор правил работы',
    subtitle: 'Создание и настройка правил работы с ротацией',
    create: 'Создать правило',
    edit: 'Редактировать правило',
    save: 'Сохранить',
    cancel: 'Отменить',
    duplicate: 'Дублировать',
    delete: 'Удалить',
    fields: {
      name: 'Название правила',
      mode: 'Режим работы',
      timezone: 'Часовой пояс',
      holidayConsideration: 'Учитывать праздники',
      rotationPattern: 'Шаблон ротации',
      constraints: 'Ограничения'
    },
    modes: {
      with_rotation: 'С ротацией',
      without_rotation: 'Без ротации'
    },
    constraints: {
      minHoursBetweenShifts: 'Мин. часов между сменами',
      maxConsecutiveHours: 'Макс. часов подряд',
      maxConsecutiveDays: 'Макс. дней подряд'
    },
    templates: {
      title: 'Шаблоны правил',
      standard: 'Стандартная неделя 5/2',
      flexible: 'Гибкий график',
      split: 'Раздельная смена',
      night: 'Ночная смена'
    },
    validation: {
      nameRequired: 'Название обязательно',
      timezoneRequired: 'Выберите часовой пояс',
      invalidConstraints: 'Неверные ограничения',
      patternRequired: 'Шаблон ротации обязателен'
    },
    status: {
      loading: 'Загрузка...',
      saving: 'Сохранение...',
      saved: 'Сохранено',
      error: 'Ошибка',
      validated: 'Проверено'
    }
  },
  en: {
    title: 'Work Rule Editor',
    subtitle: 'Create and configure work rules with rotation',
    create: 'Create Rule',
    edit: 'Edit Rule',
    save: 'Save',
    cancel: 'Cancel',
    duplicate: 'Duplicate',
    delete: 'Delete',
    fields: {
      name: 'Rule Name',
      mode: 'Work Mode',
      timezone: 'Timezone',
      holidayConsideration: 'Consider Holidays',
      rotationPattern: 'Rotation Pattern',
      constraints: 'Constraints'
    },
    modes: {
      with_rotation: 'With Rotation',
      without_rotation: 'Without Rotation'
    },
    constraints: {
      minHoursBetweenShifts: 'Min hours between shifts',
      maxConsecutiveHours: 'Max consecutive hours',
      maxConsecutiveDays: 'Max consecutive days'
    },
    templates: {
      title: 'Rule Templates',
      standard: 'Standard 5/2 Week',
      flexible: 'Flexible Schedule',
      split: 'Split Shift',
      night: 'Night Shift'
    },
    validation: {
      nameRequired: 'Name is required',
      timezoneRequired: 'Select timezone',
      invalidConstraints: 'Invalid constraints',
      patternRequired: 'Rotation pattern required'
    },
    status: {
      loading: 'Loading...',
      saving: 'Saving...',
      saved: 'Saved',
      error: 'Error',
      validated: 'Validated'
    }
  }
};

interface WorkRuleEditorProps {
  workRuleId?: string;
  isOpen: boolean;
  onClose: () => void;
  onSaved: (workRule: WorkRule) => void;
}

const WorkRuleEditor: React.FC<WorkRuleEditorProps> = ({
  workRuleId,
  isOpen,
  onClose,
  onSaved
}) => {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string>('');
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  
  // Form state
  const [formData, setFormData] = useState<Partial<WorkRule>>({
    name: '',
    mode: 'with_rotation',
    timezone: 'Europe/Moscow',
    holidayConsideration: true,
    rotationPattern: 'WWWWWRR',
    constraints: {
      minHoursBetweenShifts: 11,
      maxConsecutiveHours: 40,
      maxConsecutiveDays: 5
    },
    shifts: [],
    isActive: true
  });
  
  const [templates, setTemplates] = useState<WorkRuleTemplate[]>([]);
  const [timezones, setTimezones] = useState<string[]>([]);
  
  const t = translations[language];

  useEffect(() => {
    if (isOpen) {
      loadInitialData();
    }
  }, [isOpen, workRuleId]);

  const loadInitialData = async () => {
    setIsLoading(true);
    setError('');
    
    try {
      // Load templates and timezones
      const [templatesResult, timezonesResult] = await Promise.all([
        realWorkRuleService.getWorkRuleTemplates(),
        realWorkRuleService.getTimezones()
      ]);
      
      if (templatesResult.success && templatesResult.data) {
        setTemplates(templatesResult.data);
      }
      
      if (timezonesResult.success && timezonesResult.data) {
        setTimezones(timezonesResult.data);
      }
      
      // Load existing work rule if editing
      if (workRuleId) {
        const workRuleResult = await realWorkRuleService.getWorkRule(workRuleId);
        if (workRuleResult.success && workRuleResult.data) {
          setFormData(workRuleResult.data);
        } else {
          setError(workRuleResult.error || 'Failed to load work rule');
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
    
    // Clear validation errors when user types
    if (validationErrors.length > 0) {
      setValidationErrors([]);
    }
  };

  const handleConstraintChange = (constraint: string, value: number) => {
    setFormData(prev => ({
      ...prev,
      constraints: {
        ...prev.constraints!,
        [constraint]: value
      }
    }));
  };

  const validateForm = async (): Promise<boolean> => {
    const errors: string[] = [];
    
    if (!formData.name?.trim()) {
      errors.push(t.validation.nameRequired);
    }
    
    if (!formData.timezone) {
      errors.push(t.validation.timezoneRequired);
    }
    
    if (formData.mode === 'with_rotation' && !formData.rotationPattern) {
      errors.push(t.validation.patternRequired);
    }
    
    // Validate constraints
    if (formData.constraints) {
      const { minHoursBetweenShifts, maxConsecutiveHours, maxConsecutiveDays } = formData.constraints;
      
      if (minHoursBetweenShifts < 8 || minHoursBetweenShifts > 24) {
        errors.push('Минимальное время между сменами должно быть 8-24 часа');
      }
      
      if (maxConsecutiveHours < 8 || maxConsecutiveHours > 60) {
        errors.push('Максимальные часы подряд должны быть 8-60');
      }
      
      if (maxConsecutiveDays < 1 || maxConsecutiveDays > 14) {
        errors.push('Максимальные дни подряд должны быть 1-14');
      }
    }
    
    setValidationErrors(errors);
    
    // Additional server-side validation
    if (errors.length === 0) {
      const validationResult = await realWorkRuleService.validateWorkRule(formData);
      if (validationResult.success && validationResult.data) {
        if (!validationResult.data.valid) {
          setValidationErrors(validationResult.data.violations);
          return false;
        }
      }
    }
    
    return errors.length === 0;
  };

  const handleSave = async () => {
    if (!(await validateForm())) {
      return;
    }
    
    setIsSaving(true);
    setError('');
    
    try {
      let result;
      
      if (workRuleId) {
        result = await realWorkRuleService.updateWorkRule(workRuleId, formData);
      } else {
        result = await realWorkRuleService.createWorkRule(formData as Omit<WorkRule, 'id' | 'createdDate' | 'lastModified'>);
      }
      
      if (result.success && result.data) {
        onSaved(result.data);
        onClose();
      } else {
        setError(result.error || 'Failed to save work rule');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save work rule');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDuplicate = async () => {
    if (workRuleId && formData.name) {
      const result = await realWorkRuleService.duplicateWorkRule(workRuleId, `${formData.name} (копия)`);
      if (result.success && result.data) {
        onSaved(result.data);
        onClose();
      }
    }
  };

  const applyTemplate = (template: WorkRuleTemplate) => {
    setFormData(prev => ({
      ...prev,
      ...template.template,
      name: template.russianName
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-900">
              {workRuleId ? t.edit : t.create}
            </h2>
            <p className="text-sm text-gray-600">{t.subtitle}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <Globe className="h-4 w-4" />
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Loading state */}
        {isLoading && (
          <div className="p-6 text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p className="text-gray-600">{t.status.loading}</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="p-6">
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
              <AlertTriangle className="h-5 w-5 text-red-600 mr-3" />
              <div>
                <p className="font-medium text-red-800">{t.status.error}</p>
                <p className="text-red-700 text-sm">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Form content */}
        {!isLoading && !error && (
          <div className="p-6 space-y-6">
            {/* Templates */}
            {templates.length > 0 && (
              <div>
                <h3 className="text-lg font-medium mb-3">{t.templates.title}</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {templates.map((template) => (
                    <button
                      key={template.id}
                      onClick={() => applyTemplate(template)}
                      className="p-3 text-left border rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      <div className="font-medium text-sm">{template.russianName}</div>
                      <div className="text-xs text-gray-500 mt-1">{template.description}</div>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Basic Information */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.name}
                </label>
                <input
                  type="text"
                  value={formData.name || ''}
                  onChange={(e) => handleInputChange('name', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Введите название правила"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.mode}
                </label>
                <select
                  value={formData.mode || ''}
                  onChange={(e) => handleInputChange('mode', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="with_rotation">{t.modes.with_rotation}</option>
                  <option value="without_rotation">{t.modes.without_rotation}</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.timezone}
                </label>
                <select
                  value={formData.timezone || ''}
                  onChange={(e) => handleInputChange('timezone', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {timezones.map((tz) => (
                    <option key={tz} value={tz}>{tz}</option>
                  ))}
                </select>
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="holidayConsideration"
                  checked={formData.holidayConsideration || false}
                  onChange={(e) => handleInputChange('holidayConsideration', e.target.checked)}
                  className="mr-3"
                />
                <label htmlFor="holidayConsideration" className="text-sm font-medium text-gray-700">
                  {t.fields.holidayConsideration}
                </label>
              </div>
            </div>

            {/* Rotation Pattern */}
            {formData.mode === 'with_rotation' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.rotationPattern}
                </label>
                <input
                  type="text"
                  value={formData.rotationPattern || ''}
                  onChange={(e) => handleInputChange('rotationPattern', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="WWWWWRR (W=работа, R=отдых)"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Используйте W для рабочих дней, R для выходных
                </p>
              </div>
            )}

            {/* Constraints */}
            <div>
              <h3 className="text-lg font-medium mb-3">{t.fields.constraints}</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.constraints.minHoursBetweenShifts}
                  </label>
                  <input
                    type="number"
                    min="8"
                    max="24"
                    value={formData.constraints?.minHoursBetweenShifts || 11}
                    onChange={(e) => handleConstraintChange('minHoursBetweenShifts', parseInt(e.target.value))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.constraints.maxConsecutiveHours}
                  </label>
                  <input
                    type="number"
                    min="8"
                    max="60"
                    value={formData.constraints?.maxConsecutiveHours || 40}
                    onChange={(e) => handleConstraintChange('maxConsecutiveHours', parseInt(e.target.value))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t.constraints.maxConsecutiveDays}
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="14"
                    value={formData.constraints?.maxConsecutiveDays || 5}
                    onChange={(e) => handleConstraintChange('maxConsecutiveDays', parseInt(e.target.value))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

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
          </div>
        )}

        {/* Footer */}
        <div className="sticky bottom-0 bg-gray-50 border-t px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            {workRuleId && (
              <button
                onClick={handleDuplicate}
                className="flex items-center gap-2 px-4 py-2 text-blue-600 border border-blue-300 rounded-lg hover:bg-blue-50"
              >
                <Copy className="h-4 w-4" />
                {t.duplicate}
              </button>
            )}
          </div>
          
          <div className="flex items-center gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              {t.cancel}
            </button>
            <button
              onClick={handleSave}
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
          </div>
        </div>
      </div>
    </div>
  );
};

export default WorkRuleEditor;