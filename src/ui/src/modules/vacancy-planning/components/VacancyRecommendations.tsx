// BDD: Vacancy Recommendations (Feature 27 - @vacancy_planning @analysis @decision_support)
import React, { useState } from 'react';
import { AlertTriangle, Clock, TrendingUp, Users, Calendar, ChevronDown, ChevronUp, Briefcase } from 'lucide-react';
import type { HiringRecommendation } from '../types/vacancy';

export const VacancyRecommendations: React.FC = () => {
  const [expandedCategories, setExpandedCategories] = useState<Record<string, boolean>>({
    Immediate: true,
    Planned: false,
    Contingency: false,
    SkillDevelopment: false
  });

  // BDD: Generate hiring recommendations with specific position details
  const recommendations: HiringRecommendation[] = [
    // Critical - Immediate Hiring Needs (0-30 days)
    {
      category: 'Immediate',
      position: 'Оператор call-центра',
      quantity: 8,
      priorityLevel: 'Critical',
      timeline: '0-30 дней',
      skillRequirements: ['Продажи B2C', 'Техническая поддержка', 'CRM Naumen'],
      workSchedule: '2/2, 12-часовые смены',
      salaryRange: { min: 45000, max: 65000 },
      startDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      businessJustification: 'Критическая нехватка операторов приводит к потере 15% входящих звонков в пиковые часы'
    },
    {
      category: 'Immediate',
      position: 'Старший оператор',
      quantity: 3,
      priorityLevel: 'Critical',
      timeline: '0-30 дней',
      skillRequirements: ['Наставничество', 'Управление эскалациями', 'Аналитика KPI'],
      workSchedule: '5/2, 8-часовые смены',
      salaryRange: { min: 75000, max: 95000 },
      startDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      businessJustification: 'Необходимы для обучения новых операторов и контроля качества обслуживания'
    },
    
    // High - Planned Positions (30-90 days)
    {
      category: 'Planned',
      position: 'Специалист техподдержки 2-й линии',
      quantity: 5,
      priorityLevel: 'High',
      timeline: '30-90 дней',
      skillRequirements: ['IT диагностика', 'Linux/Windows', 'ITSM системы', 'SQL базовый'],
      workSchedule: '5/2 с дежурствами',
      salaryRange: { min: 80000, max: 120000 },
      startDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
      businessJustification: 'Растущая сложность технических запросов требует расширения 2-й линии поддержки'
    },
    {
      category: 'Planned',
      position: 'Менеджер по продажам B2B',
      quantity: 4,
      priorityLevel: 'High',
      timeline: '30-90 дней',
      skillRequirements: ['B2B продажи', 'Презентации', 'CRM', 'Английский B2'],
      workSchedule: '5/2, гибкий график',
      salaryRange: { min: 70000, max: 150000 },
      startDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
      businessJustification: 'Запуск нового продукта требует усиления отдела продаж'
    },
    
    // Medium - Contingency Staffing (90-180 days)
    {
      category: 'Contingency',
      position: 'Оператор call-центра (сезонный)',
      quantity: 12,
      priorityLevel: 'Medium',
      timeline: '90-180 дней',
      skillRequirements: ['Базовые навыки продаж', 'Клиентский сервис'],
      workSchedule: 'Гибкий график, частичная занятость',
      salaryRange: { min: 35000, max: 45000 },
      startDate: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000),
      businessJustification: 'Подготовка к сезонному росту нагрузки в IV квартале'
    },
    {
      category: 'Contingency',
      position: 'Аналитик данных',
      quantity: 2,
      priorityLevel: 'Medium',
      timeline: '90-180 дней',
      skillRequirements: ['SQL', 'Python', 'Power BI', 'Статистический анализ'],
      workSchedule: '5/2, удаленная работа возможна',
      salaryRange: { min: 100000, max: 150000 },
      startDate: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
      businessJustification: 'Развитие аналитических возможностей для оптимизации процессов'
    },
    
    // Low - Skill Development (180+ days)
    {
      category: 'SkillDevelopment',
      position: 'Тренер по продуктам',
      quantity: 2,
      priorityLevel: 'Low',
      timeline: '180+ дней',
      skillRequirements: ['Методология обучения', 'Создание учебных материалов', 'Публичные выступления'],
      workSchedule: '5/2, командировки',
      salaryRange: { min: 90000, max: 130000 },
      startDate: new Date(Date.now() + 200 * 24 * 60 * 60 * 1000),
      businessJustification: 'Альтернатива найму: развитие внутренних тренеров из опытных сотрудников'
    },
    {
      category: 'SkillDevelopment',
      position: 'HR Business Partner',
      quantity: 1,
      priorityLevel: 'Low',
      timeline: '180+ дней',
      skillRequirements: ['HR стратегия', 'Организационное развитие', 'Коучинг'],
      workSchedule: '5/2',
      salaryRange: { min: 120000, max: 180000 },
      startDate: new Date(Date.now() + 240 * 24 * 60 * 60 * 1000),
      businessJustification: 'Долгосрочное развитие HR функции для поддержки роста компании'
    }
  ];

  const categoryInfo = {
    Immediate: {
      title: 'Немедленный найм',
      icon: AlertTriangle,
      color: 'red',
      description: 'Критические позиции, требующие заполнения в течение 30 дней'
    },
    Planned: {
      title: 'Плановые позиции',
      icon: Calendar,
      color: 'orange',
      description: 'Запланированное расширение штата на 30-90 дней'
    },
    Contingency: {
      title: 'Резервный персонал',
      icon: Users,
      color: 'yellow',
      description: 'Сезонные и временные потребности на 90-180 дней'
    },
    SkillDevelopment: {
      title: 'Развитие навыков',
      icon: TrendingUp,
      color: 'green',
      description: 'Альтернативы найму через обучение на 180+ дней'
    }
  };

  const toggleCategory = (category: string) => {
    setExpandedCategories(prev => ({
      ...prev,
      [category]: !prev[category]
    }));
  };

  const getCategoryRecommendations = (category: string) => 
    recommendations.filter(r => r.category === category);

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'Critical': return 'text-red-600 bg-red-50';
      case 'High': return 'text-orange-600 bg-orange-50';
      case 'Medium': return 'text-yellow-600 bg-yellow-50';
      case 'Low': return 'text-green-600 bg-green-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  return (
    <div className="space-y-6">
      {/* Summary Statistics */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Сводка рекомендаций по найму</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {Object.entries(categoryInfo).map(([category, info]) => {
            const count = getCategoryRecommendations(category).reduce((sum, r) => sum + r.quantity, 0);
            return (
              <div key={category} className="text-center">
                <info.icon className={`h-8 w-8 mx-auto mb-2 text-${info.color}-500`} />
                <p className="text-2xl font-bold">{count}</p>
                <p className="text-sm text-gray-600">{info.title}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* BDD: Detailed hiring guidance by category */}
      {Object.entries(categoryInfo).map(([category, info]) => {
        const categoryRecs = getCategoryRecommendations(category);
        const isExpanded = expandedCategories[category];
        
        return (
          <div key={category} className="bg-white rounded-lg shadow">
            <button
              onClick={() => toggleCategory(category)}
              className="w-full p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <info.icon className={`h-5 w-5 text-${info.color}-500`} />
                <div className="text-left">
                  <h3 className="font-semibold">{info.title}</h3>
                  <p className="text-sm text-gray-600">{info.description}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-sm font-medium">
                  {categoryRecs.reduce((sum, r) => sum + r.quantity, 0)} позиций
                </span>
                {isExpanded ? <ChevronUp /> : <ChevronDown />}
              </div>
            </button>
            
            {isExpanded && (
              <div className="border-t">
                {categoryRecs.map((rec, index) => (
                  <div key={index} className="p-4 border-b last:border-b-0">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <Briefcase className="h-5 w-5 text-gray-400" />
                          <h4 className="font-medium text-lg">{rec.position}</h4>
                          <span className={`px-2 py-1 text-xs rounded-full ${getPriorityColor(rec.priorityLevel)}`}>
                            {rec.priorityLevel === 'Critical' ? 'Критично' :
                             rec.priorityLevel === 'High' ? 'Высокий' :
                             rec.priorityLevel === 'Medium' ? 'Средний' : 'Низкий'}
                          </span>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                          <div>
                            <p className="text-gray-600 mb-1">Количество:</p>
                            <p className="font-medium">{rec.quantity} позиций</p>
                          </div>
                          
                          <div>
                            <p className="text-gray-600 mb-1">График работы:</p>
                            <p>{rec.workSchedule}</p>
                          </div>
                          
                          <div>
                            <p className="text-gray-600 mb-1">Зарплатная вилка:</p>
                            <p className="font-medium">
                              ₽{rec.salaryRange.min.toLocaleString('ru-RU')} - ₽{rec.salaryRange.max.toLocaleString('ru-RU')}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-gray-600 mb-1">Дата начала:</p>
                            <p>{rec.startDate.toLocaleDateString('ru-RU')}</p>
                          </div>
                        </div>
                        
                        <div className="mt-3">
                          <p className="text-gray-600 mb-1 text-sm">Требуемые навыки:</p>
                          <div className="flex flex-wrap gap-1">
                            {rec.skillRequirements.map((skill, idx) => (
                              <span key={idx} className="px-2 py-1 bg-gray-100 text-xs rounded">
                                {skill}
                              </span>
                            ))}
                          </div>
                        </div>
                        
                        <div className="mt-3 p-3 bg-blue-50 rounded">
                          <p className="text-sm text-blue-800">
                            <strong>Обоснование:</strong> {rec.businessJustification}
                          </p>
                        </div>
                      </div>
                      
                      <div className="ml-4 text-right">
                        <Clock className="h-4 w-4 text-gray-400 mb-1 ml-auto" />
                        <p className="text-sm text-gray-600">{rec.timeline}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      })}

      {/* Implementation Timeline */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">График реализации плана найма</h3>
        <div className="relative">
          <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-300"></div>
          
          {recommendations
            .sort((a, b) => a.startDate.getTime() - b.startDate.getTime())
            .slice(0, 6)
            .map((rec, index) => (
              <div key={index} className="relative flex items-center mb-6 last:mb-0">
                <div className={`absolute left-0 w-8 h-8 rounded-full flex items-center justify-center ${
                  rec.priorityLevel === 'Critical' ? 'bg-red-500' :
                  rec.priorityLevel === 'High' ? 'bg-orange-500' :
                  rec.priorityLevel === 'Medium' ? 'bg-yellow-500' :
                  'bg-green-500'
                }`}>
                  <span className="text-white text-xs font-bold">{rec.quantity}</span>
                </div>
                
                <div className="ml-12 flex-1 bg-gray-50 rounded p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-medium">{rec.position}</h4>
                      <p className="text-sm text-gray-600">
                        {rec.startDate.toLocaleDateString('ru-RU')} • {rec.category === 'Immediate' ? 'Срочно' : rec.timeline}
                      </p>
                    </div>
                    <span className={`px-2 py-1 text-xs rounded ${getPriorityColor(rec.priorityLevel)}`}>
                      {rec.priorityLevel}
                    </span>
                  </div>
                </div>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
};