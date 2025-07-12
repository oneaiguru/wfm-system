import React, { useState } from 'react';
import { 
  Calendar, 
  Users, 
  Clock, 
  Target, 
  AlertTriangle, 
  CheckCircle,
  Plus,
  Edit,
  Trash2,
  Play,
  Pause,
  UserCheck,
  Settings,
  TrendingUp
} from 'lucide-react';

// BDD: Multi-skill planning workflows - Adapted from ShiftTemplateManager
// Based on: 19-planning-module-detailed-workflows.feature

interface SkillPlanTemplate {
  id: string;
  name: string;
  primarySkill: string;
  secondarySkills: string[];
  requiredAgents: number;
  targetCoverage: number;
  currentCoverage: number;
  priority: 'high' | 'medium' | 'low';
  timeSlots: string[];
  planningHorizon: string;
  optimizationLevel: 'basic' | 'standard' | 'advanced';
  isActive: boolean;
  constraints: {
    maxConsecutiveDays: number;
    minRestHours: number;
    skillRequirements: string[];
  };
  metrics: {
    efficiency: number;
    coverage: number;
    satisfaction: number;
  };
}

const MultiSkillPlanningManager: React.FC = () => {
  const [planTemplates, setPlanTemplates] = useState<SkillPlanTemplate[]>([
    {
      id: '1',
      name: 'Техподдержка + Продажи',
      primarySkill: 'Техническая поддержка',
      secondarySkills: ['Продажи', 'Консультации'],
      requiredAgents: 12,
      targetCoverage: 95.0,
      currentCoverage: 87.5,
      priority: 'high',
      timeSlots: ['09:00-12:00', '12:00-15:00', '15:00-18:00'],
      planningHorizon: '4 недели',
      optimizationLevel: 'advanced',
      isActive: true,
      constraints: {
        maxConsecutiveDays: 5,
        minRestHours: 11,
        skillRequirements: ['Технические знания', 'Коммуникация']
      },
      metrics: {
        efficiency: 92.3,
        coverage: 87.5,
        satisfaction: 89.1
      }
    },
    {
      id: '2',
      name: 'Мультиканальность',
      primarySkill: 'Голосовые звонки',
      secondarySkills: ['Чат', 'Email', 'Социальные сети'],
      requiredAgents: 8,
      targetCoverage: 90.0,
      currentCoverage: 94.2,
      priority: 'medium',
      timeSlots: ['08:00-16:00', '16:00-00:00'],
      planningHorizon: '2 недели',
      optimizationLevel: 'standard',
      isActive: true,
      constraints: {
        maxConsecutiveDays: 4,
        minRestHours: 12,
        skillRequirements: ['Мультиканальность', 'Адаптивность']
      },
      metrics: {
        efficiency: 88.7,
        coverage: 94.2,
        satisfaction: 86.4
      }
    },
    {
      id: '3',
      name: 'VIP Клиенты',
      primarySkill: 'VIP обслуживание',
      secondarySkills: ['Эскалация', 'Специальные запросы'],
      requiredAgents: 4,
      targetCoverage: 100.0,
      currentCoverage: 92.8,
      priority: 'high',
      timeSlots: ['09:00-18:00'],
      planningHorizon: '1 неделя',
      optimizationLevel: 'advanced',
      isActive: true,
      constraints: {
        maxConsecutiveDays: 3,
        minRestHours: 16,
        skillRequirements: ['Экспертный уровень', 'Эмпатия', 'Лидерство']
      },
      metrics: {
        efficiency: 95.1,
        coverage: 92.8,
        satisfaction: 97.3
      }
    }
  ]);

  const [isCreating, setIsCreating] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<SkillPlanTemplate | null>(null);
  const [formData, setFormData] = useState<Partial<SkillPlanTemplate>>({
    name: '',
    primarySkill: '',
    secondarySkills: [],
    requiredAgents: 5,
    targetCoverage: 95.0,
    priority: 'medium',
    timeSlots: ['09:00-17:00'],
    planningHorizon: '2 недели',
    optimizationLevel: 'standard',
    isActive: true,
    constraints: {
      maxConsecutiveDays: 5,
      minRestHours: 11,
      skillRequirements: []
    }
  });

  // BDD: Planning optimization logic
  const calculatePlanEfficiency = (template: SkillPlanTemplate): number => {
    const coverageWeight = 0.4;
    const efficiencyWeight = 0.3;
    const satisfactionWeight = 0.3;
    
    return (
      template.metrics.coverage * coverageWeight +
      template.metrics.efficiency * efficiencyWeight +
      template.metrics.satisfaction * satisfactionWeight
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const newTemplate: SkillPlanTemplate = {
      id: editingTemplate?.id || Date.now().toString(),
      name: formData.name!,
      primarySkill: formData.primarySkill!,
      secondarySkills: formData.secondarySkills || [],
      requiredAgents: formData.requiredAgents!,
      targetCoverage: formData.targetCoverage!,
      currentCoverage: Math.random() * 100, // Mock calculation
      priority: formData.priority!,
      timeSlots: formData.timeSlots!,
      planningHorizon: formData.planningHorizon!,
      optimizationLevel: formData.optimizationLevel!,
      isActive: formData.isActive!,
      constraints: formData.constraints!,
      metrics: {
        efficiency: 85 + Math.random() * 15,
        coverage: 80 + Math.random() * 20,
        satisfaction: 82 + Math.random() * 18
      }
    };

    if (editingTemplate) {
      setPlanTemplates(prev => prev.map(t => t.id === editingTemplate.id ? newTemplate : t));
    } else {
      setPlanTemplates(prev => [...prev, newTemplate]);
    }

    handleCancel();
  };

  const handleEdit = (template: SkillPlanTemplate) => {
    setEditingTemplate(template);
    setFormData(template);
    setIsCreating(true);
  };

  const handleDelete = (id: string) => {
    setPlanTemplates(prev => prev.filter(t => t.id !== id));
  };

  const handleCancel = () => {
    setIsCreating(false);
    setEditingTemplate(null);
    setFormData({
      name: '',
      primarySkill: '',
      secondarySkills: [],
      requiredAgents: 5,
      targetCoverage: 95.0,
      priority: 'medium',
      timeSlots: ['09:00-17:00'],
      planningHorizon: '2 недели',
      optimizationLevel: 'standard',
      isActive: true,
      constraints: {
        maxConsecutiveDays: 5,
        minRestHours: 11,
        skillRequirements: []
      }
    });
  };

  const toggleStatus = (id: string) => {
    setPlanTemplates(prev => prev.map(t => 
      t.id === id ? { ...t, isActive: !t.isActive } : t
    ));
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800 border-red-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low': return 'bg-green-100 text-green-800 border-green-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  };

  const getOptimizationIcon = (level: string) => {
    switch (level) {
      case 'basic': return '⚙️';
      case 'standard': return '🔧';
      case 'advanced': return '🚀';
      default: return '⚙️';
    }
  };

  const getCoverageColor = (current: number, target: number) => {
    const ratio = current / target;
    if (ratio >= 0.95) return 'text-green-600';
    if (ratio >= 0.85) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header - BDD: Multi-skill planning interface */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Users className="h-6 w-6 mr-2 text-blue-600" />
              Мульти-скилл планирование
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">🎯</span>
              Управление рабочими шаблонами с множественными навыками
            </p>
          </div>
          
          <button
            onClick={() => setIsCreating(true)}
            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4 mr-2" />
            Создать план
          </button>
        </div>
      </div>

      {/* Statistics Dashboard - BDD: Planning metrics overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Target className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Активных планов</h3>
              <p className="text-2xl font-bold text-blue-600">
                {planTemplates.filter(t => t.isActive).length}
              </p>
              <p className="text-sm text-gray-600">Из {planTemplates.length} общих</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <TrendingUp className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Средняя эффективность</h3>
              <p className="text-2xl font-bold text-green-600">
                {(planTemplates.reduce((acc, t) => acc + t.metrics.efficiency, 0) / planTemplates.length).toFixed(1)}%
              </p>
              <p className="text-sm text-gray-600">Оптимизация</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <UserCheck className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Агентов задействовано</h3>
              <p className="text-2xl font-bold text-purple-600">
                {planTemplates.reduce((acc, t) => acc + t.requiredAgents, 0)}
              </p>
              <p className="text-sm text-gray-600">Всего ресурсов</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Покрытие целей</h3>
              <p className="text-2xl font-bold text-yellow-600">
                {planTemplates.filter(t => t.currentCoverage >= t.targetCoverage).length}
              </p>
              <p className="text-sm text-gray-600">Выполнено планов</p>
            </div>
          </div>
        </div>
      </div>

      {/* Planning Templates Grid - BDD: Multi-skill template management */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {planTemplates.map(template => (
          <div
            key={template.id}
            className={`bg-white rounded-lg shadow-sm border-2 p-6 ${
              template.isActive ? 'border-blue-200' : 'border-gray-200 opacity-75'
            }`}
          >
            {/* Template Header */}
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="flex items-center space-x-2 mb-2">
                  <span className="text-lg">{getPriorityIcon(template.priority)}</span>
                  <h3 className="text-lg font-semibold text-gray-900">{template.name}</h3>
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(template.priority)}`}>
                    {template.priority}
                  </span>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <span>🎯 {template.primarySkill}</span>
                  <span>•</span>
                  <span>{getOptimizationIcon(template.optimizationLevel)} {template.optimizationLevel}</span>
                </div>
              </div>

              <div className="flex space-x-2">
                <button
                  onClick={() => handleEdit(template)}
                  className="p-2 text-gray-400 hover:text-blue-600"
                >
                  <Edit className="h-4 w-4" />
                </button>
                <button
                  onClick={() => toggleStatus(template.id)}
                  className={`p-2 ${template.isActive ? 'text-yellow-600' : 'text-green-600'}`}
                >
                  {template.isActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                </button>
                <button
                  onClick={() => handleDelete(template.id)}
                  className="p-2 text-gray-400 hover:text-red-600"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>

            {/* Coverage Progress */}
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-gray-700">Покрытие целей</span>
                <span className={`text-sm font-bold ${getCoverageColor(template.currentCoverage, template.targetCoverage)}`}>
                  {template.currentCoverage.toFixed(1)}% / {template.targetCoverage.toFixed(1)}%
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div 
                  className={`h-2 rounded-full transition-all duration-300 ${
                    template.currentCoverage >= template.targetCoverage ? 'bg-green-500' :
                    template.currentCoverage >= template.targetCoverage * 0.85 ? 'bg-yellow-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${Math.min((template.currentCoverage / template.targetCoverage) * 100, 100)}%` }}
                ></div>
              </div>
            </div>

            {/* Skills and Resources */}
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">Агентов требуется</p>
                <p className="text-xl font-bold text-gray-900">{template.requiredAgents}</p>
              </div>
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">Временные слоты</p>
                <p className="text-sm text-gray-700">{template.timeSlots.length} интервала</p>
              </div>
            </div>

            {/* Secondary Skills */}
            <div className="mb-4">
              <p className="text-xs font-medium text-gray-500 mb-2">Дополнительные навыки</p>
              <div className="flex flex-wrap gap-1">
                {template.secondarySkills.map((skill, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {skill}
                  </span>
                ))}
              </div>
            </div>

            {/* Metrics Dashboard */}
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="bg-gray-50 rounded-lg p-2">
                <p className="text-xs text-gray-500">Эффективность</p>
                <p className="text-sm font-bold text-gray-900">{template.metrics.efficiency.toFixed(1)}%</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-2">
                <p className="text-xs text-gray-500">Покрытие</p>
                <p className="text-sm font-bold text-gray-900">{template.metrics.coverage.toFixed(1)}%</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-2">
                <p className="text-xs text-gray-500">Удовлетворенность</p>
                <p className="text-sm font-bold text-gray-900">{template.metrics.satisfaction.toFixed(1)}%</p>
              </div>
            </div>

            {/* Constraints Summary */}
            <div className="mt-4 p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-4 text-xs text-gray-600">
                <span>Макс дней: {template.constraints.maxConsecutiveDays}</span>
                <span>•</span>
                <span>Отдых: {template.constraints.minRestHours}ч</span>
                <span>•</span>
                <span>Горизонт: {template.planningHorizon}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Create/Edit Modal - BDD: Planning template form */}
      {isCreating && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold text-gray-900 mb-6">
              {editingTemplate ? 'Редактировать план' : 'Создать новый план'}
            </h2>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Название плана
                </label>
                <input
                  type="text"
                  value={formData.name || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Основной навык
                  </label>
                  <input
                    type="text"
                    value={formData.primarySkill || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, primarySkill: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Приоритет
                  </label>
                  <select
                    value={formData.priority || 'medium'}
                    onChange={(e) => setFormData(prev => ({ ...prev, priority: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="low">🟢 Низкий</option>
                    <option value="medium">🟡 Средний</option>
                    <option value="high">🔴 Высокий</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Требуется агентов
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="50"
                    value={formData.requiredAgents || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, requiredAgents: parseInt(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Целевое покрытие (%)
                  </label>
                  <input
                    type="number"
                    min="50"
                    max="100"
                    step="0.1"
                    value={formData.targetCoverage || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, targetCoverage: parseFloat(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Горизонт планирования
                  </label>
                  <select
                    value={formData.planningHorizon || '2 недели'}
                    onChange={(e) => setFormData(prev => ({ ...prev, planningHorizon: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="1 неделя">1 неделя</option>
                    <option value="2 недели">2 недели</option>
                    <option value="4 недели">4 недели</option>
                    <option value="8 недель">8 недель</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Уровень оптимизации
                  </label>
                  <select
                    value={formData.optimizationLevel || 'standard'}
                    onChange={(e) => setFormData(prev => ({ ...prev, optimizationLevel: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="basic">⚙️ Базовый</option>
                    <option value="standard">🔧 Стандартный</option>
                    <option value="advanced">🚀 Продвинутый</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center">
                <input
                  id="isActive"
                  type="checkbox"
                  checked={formData.isActive ?? true}
                  onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="isActive" className="ml-2 block text-sm text-gray-900">
                  Активировать план
                </label>
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={handleCancel}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Отмена
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700"
                >
                  {editingTemplate ? 'Обновить' : 'Создать'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MultiSkillPlanningManager;