import React, { useState, useEffect } from 'react';
import { 
  Calendar, Users, TrendingUp, AlertCircle, Clock, Target,
  BarChart3, FileText, Settings, ChevronRight, Plus,
  Edit, Trash2, Copy, Save, X, Check, AlertTriangle
} from 'lucide-react';

interface PlanningTemplate {
  id: string;
  name: string;
  groups: string[];
  type: 'multi-skill' | 'standard';
  created: string;
  modified: string;
  status: 'active' | 'draft' | 'archived';
  operatorCount: number;
  schedules: number;
}

interface PlanningMetrics {
  totalTemplates: number;
  activeSchedules: number;
  operatorsCovered: number;
  capacityUtilization: number;
  planningAccuracy: number;
  openVacancies: number;
}

interface GroupConflict {
  groupId: string;
  groupName: string;
  conflictingTemplate: string;
  operators: string[];
}

// Russian translations for SPEC-14 compliance
const russianTranslations = {
  title: 'Модуль планирования',
  subtitle: 'Управление шаблонами и расписаниями',
  sections: {
    templates: 'Шаблоны планирования',
    metrics: 'Показатели',
    actions: 'Быстрые действия',
    recent: 'Недавние действия'
  },
  template: {
    multiSkill: 'Мультинавыковый',
    standard: 'Стандартный',
    create: 'Создать шаблон',
    rename: 'Переименовать шаблон',
    delete: 'Удалить шаблон',
    addGroup: 'Добавить группу',
    removeGroup: 'Удалить группу',
    groups: 'Группы',
    operators: 'операторов',
    schedules: 'расписаний'
  },
  metrics: {
    totalTemplates: 'Всего шаблонов',
    activeSchedules: 'Активные расписания',
    operatorsCovered: 'Охвачено операторов',
    capacityUtilization: 'Использование мощности',
    planningAccuracy: 'Точность планирования',
    openVacancies: 'Открытые вакансии'
  },
  actions: {
    createTemplate: 'Создать новый шаблон',
    planSchedule: 'Планировать расписание',
    analyzeCapacity: 'Анализ мощности',
    viewReports: 'Просмотр отчетов'
  },
  dialogs: {
    createTitle: 'Создать шаблон планирования',
    templateName: 'Название шаблона',
    templateType: 'Тип шаблона',
    save: 'Сохранить',
    cancel: 'Отмена',
    deleteConfirm: 'Вы уверены, что хотите удалить этот шаблон?',
    deleteWarning: 'Это действие нельзя отменить',
    deleteImpact: 'Все связанные расписания будут автоматически удалены',
    yes: 'Да',
    no: 'Нет'
  },
  conflicts: {
    title: 'Конфликт групп',
    message: 'Оператор может находиться только в одном мультинавыковом шаблоне',
    conflictingTemplate: 'Конфликтующий шаблон',
    suggestAlternative: 'Предлагаемые альтернативы'
  },
  status: {
    active: 'Активный',
    draft: 'Черновик',
    archived: 'Архивный'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const PlanningModuleDashboard: React.FC = () => {
  const [templates, setTemplates] = useState<PlanningTemplate[]>([]);
  const [metrics, setMetrics] = useState<PlanningMetrics | null>(null);
  const [selectedTemplate, setSelectedTemplate] = useState<PlanningTemplate | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showRenameDialog, setShowRenameDialog] = useState(false);
  const [showAddGroupDialog, setShowAddGroupDialog] = useState(false);
  const [groupConflict, setGroupConflict] = useState<GroupConflict | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  // Form states
  const [newTemplateName, setNewTemplateName] = useState('');
  const [newTemplateType, setNewTemplateType] = useState<'multi-skill' | 'standard'>('multi-skill');
  const [selectedGroups, setSelectedGroups] = useState<string[]>([]);

  useEffect(() => {
    loadPlanningData();
  }, []);

  const loadPlanningData = async () => {
    setLoading(true);
    setError('');

    try {
      const authToken = localStorage.getItem('authToken');
      
      // Load templates
      const templatesResponse = await fetch(`${API_BASE_URL}/planning/templates`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      // Load metrics
      const metricsResponse = await fetch(`${API_BASE_URL}/planning/metrics`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (templatesResponse.ok && metricsResponse.ok) {
        const templatesData = await templatesResponse.json();
        const metricsData = await metricsResponse.json();
        setTemplates(templatesData.templates || []);
        setMetrics(metricsData);
        console.log('✅ SPEC-19 Planning data loaded');
      } else {
        // Use demo data as fallback
        console.log('⚠️ Planning APIs not available, using demo data');
        setTemplates(generateDemoTemplates());
        setMetrics(generateDemoMetrics());
      }
    } catch (err) {
      console.log('⚠️ Planning API error, using demo data');
      setTemplates(generateDemoTemplates());
      setMetrics(generateDemoMetrics());
      setError('Используются демонстрационные данные');
    } finally {
      setLoading(false);
    }
  };

  const generateDemoTemplates = (): PlanningTemplate[] => [
    {
      id: 'tpl-1',
      name: 'Основная поддержка 24/7',
      groups: ['Группа A', 'Группа B', 'Группа C'],
      type: 'multi-skill',
      created: '2025-07-01',
      modified: '2025-07-20',
      status: 'active',
      operatorCount: 45,
      schedules: 3
    },
    {
      id: 'tpl-2',
      name: 'Техническая поддержка',
      groups: ['Техническая группа 1', 'Техническая группа 2'],
      type: 'multi-skill',
      created: '2025-06-15',
      modified: '2025-07-18',
      status: 'active',
      operatorCount: 28,
      schedules: 2
    },
    {
      id: 'tpl-3',
      name: 'Выходные смены',
      groups: ['Группа выходного дня'],
      type: 'standard',
      created: '2025-07-10',
      modified: '2025-07-10',
      status: 'draft',
      operatorCount: 15,
      schedules: 0
    }
  ];

  const generateDemoMetrics = (): PlanningMetrics => ({
    totalTemplates: 12,
    activeSchedules: 8,
    operatorsCovered: 156,
    capacityUtilization: 87.5,
    planningAccuracy: 92.3,
    openVacancies: 5
  });

  const handleCreateTemplate = async () => {
    if (!newTemplateName.trim()) return;

    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/planning/templates`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: newTemplateName,
          type: newTemplateType,
          groups: []
        })
      });

      if (response.ok) {
        console.log('✅ Template created');
        await loadPlanningData();
        setShowCreateDialog(false);
        setNewTemplateName('');
      } else {
        // Demo mode - add to local state
        const newTemplate: PlanningTemplate = {
          id: `tpl-${Date.now()}`,
          name: newTemplateName,
          groups: [],
          type: newTemplateType,
          created: new Date().toISOString(),
          modified: new Date().toISOString(),
          status: 'draft',
          operatorCount: 0,
          schedules: 0
        };
        setTemplates([...templates, newTemplate]);
        setShowCreateDialog(false);
        setNewTemplateName('');
      }
    } catch (err) {
      console.log('⚠️ Create template error, demo mode');
    }
  };

  const handleDeleteTemplate = async () => {
    if (!selectedTemplate) return;

    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/planning/templates/${selectedTemplate.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        console.log('✅ Template deleted');
        await loadPlanningData();
        setShowDeleteDialog(false);
        setSelectedTemplate(null);
      } else {
        // Demo mode - remove from local state
        setTemplates(templates.filter(t => t.id !== selectedTemplate.id));
        setShowDeleteDialog(false);
        setSelectedTemplate(null);
      }
    } catch (err) {
      console.log('⚠️ Delete template error, demo mode');
    }
  };

  const checkGroupConflicts = (groupName: string): GroupConflict | null => {
    // Check if operators in this group exist in other multi-skill templates
    const conflictingTemplate = templates.find(t => 
      t.type === 'multi-skill' && 
      t.id !== selectedTemplate?.id &&
      t.groups.includes(groupName)
    );

    if (conflictingTemplate) {
      return {
        groupId: groupName,
        groupName: groupName,
        conflictingTemplate: conflictingTemplate.name,
        operators: ['Оператор 1', 'Оператор 2'] // Demo data
      };
    }

    return null;
  };

  const renderMetricsCards = () => {
    if (!metrics) return null;

    const metricsConfig = [
      { key: 'totalTemplates', icon: FileText, color: 'bg-blue-500' },
      { key: 'activeSchedules', icon: Calendar, color: 'bg-green-500' },
      { key: 'operatorsCovered', icon: Users, color: 'bg-purple-500' },
      { key: 'capacityUtilization', icon: BarChart3, color: 'bg-orange-500', suffix: '%' },
      { key: 'planningAccuracy', icon: Target, color: 'bg-indigo-500', suffix: '%' },
      { key: 'openVacancies', icon: AlertCircle, color: 'bg-red-500' }
    ];

    return (
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">
        {metricsConfig.map(({ key, icon: Icon, color, suffix = '' }) => (
          <div key={key} className="bg-white rounded-lg shadow p-4">
            <div className={`${color} rounded-lg p-2 w-fit mb-2`}>
              <Icon className="h-5 w-5 text-white" />
            </div>
            <div className="text-2xl font-bold text-gray-900">
              {metrics[key as keyof PlanningMetrics]}{suffix}
            </div>
            <div className="text-sm text-gray-600">
              {russianTranslations.metrics[key as keyof typeof russianTranslations.metrics]}
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderTemplateList = () => (
    <div className="bg-white rounded-lg shadow">
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900">
            {russianTranslations.sections.templates}
          </h3>
          <button
            onClick={() => setShowCreateDialog(true)}
            className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4" />
            {russianTranslations.template.create}
          </button>
        </div>
      </div>

      <div className="divide-y divide-gray-200">
        {templates.map((template) => (
          <div
            key={template.id}
            className={`p-4 hover:bg-gray-50 cursor-pointer transition-colors ${
              selectedTemplate?.id === template.id ? 'bg-blue-50' : ''
            }`}
            onClick={() => setSelectedTemplate(template)}
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-medium text-gray-900">{template.name}</h4>
                <div className="flex items-center gap-4 mt-1">
                  <span className="text-sm text-gray-500">
                    {template.type === 'multi-skill' 
                      ? russianTranslations.template.multiSkill 
                      : russianTranslations.template.standard}
                  </span>
                  <span className="text-sm text-gray-500">
                    {template.operatorCount} {russianTranslations.template.operators}
                  </span>
                  <span className="text-sm text-gray-500">
                    {template.schedules} {russianTranslations.template.schedules}
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className={`px-2 py-1 rounded text-xs font-medium ${
                  template.status === 'active' 
                    ? 'bg-green-100 text-green-800'
                    : template.status === 'draft'
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {russianTranslations.status[template.status]}
                </span>
                <ChevronRight className="h-4 w-4 text-gray-400" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderTemplateDetails = () => {
    if (!selectedTemplate) {
      return (
        <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
          Выберите шаблон для просмотра деталей
        </div>
      );
    }

    return (
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">
              {selectedTemplate.name}
            </h3>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowRenameDialog(true)}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded"
                title={russianTranslations.template.rename}
              >
                <Edit className="h-4 w-4" />
              </button>
              <button
                onClick={() => setShowDeleteDialog(true)}
                className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded"
                title={russianTranslations.template.delete}
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>

        <div className="p-4">
          <div className="space-y-4">
            <div>
              <h4 className="font-medium text-gray-900 mb-2">
                {russianTranslations.template.groups}
              </h4>
              <div className="space-y-2">
                {selectedTemplate.groups.map((group, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-2 bg-gray-50 rounded"
                  >
                    <span className="text-gray-700">{group}</span>
                    <button
                      onClick={() => {
                        // Handle remove group
                      }}
                      className="text-red-600 hover:text-red-800"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                ))}
                <button
                  onClick={() => setShowAddGroupDialog(true)}
                  className="w-full py-2 border-2 border-dashed border-gray-300 rounded text-gray-600 hover:border-gray-400 hover:text-gray-800"
                >
                  <Plus className="h-4 w-4 mx-auto" />
                  {russianTranslations.template.addGroup}
                </button>
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-gray-500">Создан:</span>
                  <span className="ml-2 text-gray-900">
                    {new Date(selectedTemplate.created).toLocaleDateString('ru-RU')}
                  </span>
                </div>
                <div>
                  <span className="text-gray-500">Изменен:</span>
                  <span className="ml-2 text-gray-900">
                    {new Date(selectedTemplate.modified).toLocaleDateString('ru-RU')}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderQuickActions = () => (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
      {[
        { icon: Plus, label: russianTranslations.actions.createTemplate, onClick: () => setShowCreateDialog(true) },
        { icon: Calendar, label: russianTranslations.actions.planSchedule, onClick: () => {} },
        { icon: BarChart3, label: russianTranslations.actions.analyzeCapacity, onClick: () => {} },
        { icon: FileText, label: russianTranslations.actions.viewReports, onClick: () => {} }
      ].map((action, index) => (
        <button
          key={index}
          onClick={action.onClick}
          className="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-center"
        >
          <action.icon className="h-8 w-8 text-blue-600 mx-auto mb-2" />
          <span className="text-sm text-gray-700">{action.label}</span>
        </button>
      ))}
    </div>
  );

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-96">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Загрузка модуля планирования...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6" data-testid="planning-module-dashboard">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
        <p className="text-gray-600">{russianTranslations.subtitle}</p>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-yellow-800">{error}</p>
        </div>
      )}

      {/* Metrics Cards */}
      {renderMetricsCards()}

      {/* Quick Actions */}
      {renderQuickActions()}

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Template List */}
        {renderTemplateList()}

        {/* Template Details */}
        {renderTemplateDetails()}
      </div>

      {/* Create Template Dialog */}
      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-96 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              {russianTranslations.dialogs.createTitle}
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {russianTranslations.dialogs.templateName}
                </label>
                <input
                  type="text"
                  value={newTemplateName}
                  onChange={(e) => setNewTemplateName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Введите название"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {russianTranslations.dialogs.templateType}
                </label>
                <select
                  value={newTemplateType}
                  onChange={(e) => setNewTemplateType(e.target.value as 'multi-skill' | 'standard')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="multi-skill">{russianTranslations.template.multiSkill}</option>
                  <option value="standard">{russianTranslations.template.standard}</option>
                </select>
              </div>
            </div>
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowCreateDialog(false)}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                {russianTranslations.dialogs.cancel}
              </button>
              <button
                onClick={handleCreateTemplate}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                {russianTranslations.dialogs.save}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Dialog */}
      {showDeleteDialog && selectedTemplate && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-96 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-red-100 rounded-lg">
                <AlertTriangle className="h-6 w-6 text-red-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">
                {russianTranslations.template.delete}
              </h3>
            </div>
            <p className="text-gray-700 mb-2">{russianTranslations.dialogs.deleteConfirm}</p>
            <p className="text-sm text-red-600 mb-1">{russianTranslations.dialogs.deleteWarning}</p>
            <p className="text-sm text-gray-600 mb-4">{russianTranslations.dialogs.deleteImpact}</p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowDeleteDialog(false)}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                {russianTranslations.dialogs.no}
              </button>
              <button
                onClick={handleDeleteTemplate}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                {russianTranslations.dialogs.yes}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Group Conflict Dialog */}
      {groupConflict && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-96 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-yellow-100 rounded-lg">
                <AlertCircle className="h-6 w-6 text-yellow-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">
                {russianTranslations.conflicts.title}
              </h3>
            </div>
            <p className="text-gray-700 mb-4">{russianTranslations.conflicts.message}</p>
            <div className="bg-gray-50 rounded-lg p-3 mb-4">
              <p className="text-sm text-gray-600">
                {russianTranslations.conflicts.conflictingTemplate}: 
                <span className="font-medium text-gray-900 ml-1">
                  {groupConflict.conflictingTemplate}
                </span>
              </p>
            </div>
            <div className="flex justify-end">
              <button
                onClick={() => setGroupConflict(null)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Понятно
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PlanningModuleDashboard;