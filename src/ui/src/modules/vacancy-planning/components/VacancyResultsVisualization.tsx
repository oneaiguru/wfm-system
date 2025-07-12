// BDD: Vacancy Results Visualization (Feature 27 - @vacancy_planning @analysis @high)
import React, { useState, useEffect } from 'react';
import { Download, Filter, ZoomIn, BarChart3, TrendingDown, Calendar, DollarSign } from 'lucide-react';
import type { VacancyAnalysisResult, StaffingGap } from '../types/vacancy';

export const VacancyResultsVisualization: React.FC = () => {
  const [selectedDepartment, setSelectedDepartment] = useState<string>('all');
  const [selectedPeriod, setSelectedPeriod] = useState<string>('month');
  const [analysisResults, setAnalysisResults] = useState<VacancyAnalysisResult | null>(null);

  // BDD: Mock comprehensive analysis results
  useEffect(() => {
    const mockResults: VacancyAnalysisResult = {
      id: 'analysis-1',
      status: 'completed',
      progress: 100,
      currentStep: 'Анализ завершен',
      totalDeficit: 25,
      estimatedCost: 2500000,
      serviceImpact: 15,
      staffingGaps: [
        {
          position: 'Оператор call-центра',
          department: 'Служба поддержки',
          deficit: 8,
          skillsRequired: ['Продажи', 'Техподдержка', 'CRM'],
          priority: 'Critical',
          recommendedStartDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        },
        {
          position: 'Старший оператор',
          department: 'Служба поддержки',
          deficit: 3,
          skillsRequired: ['Управление', 'Обучение', 'Аналитика'],
          priority: 'High',
          recommendedStartDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
        },
        {
          position: 'Специалист техподдержки',
          department: 'IT поддержка',
          deficit: 5,
          skillsRequired: ['IT', 'Диагностика', 'Клиентский сервис'],
          priority: 'High',
          recommendedStartDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000)
        },
        {
          position: 'Менеджер по продажам',
          department: 'Отдел продаж',
          deficit: 4,
          skillsRequired: ['B2B продажи', 'Презентации', 'CRM'],
          priority: 'Medium',
          recommendedStartDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        },
        {
          position: 'Аналитик данных',
          department: 'Аналитика',
          deficit: 2,
          skillsRequired: ['SQL', 'Python', 'Визуализация данных'],
          priority: 'Medium',
          recommendedStartDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000)
        },
        {
          position: 'HR специалист',
          department: 'HR',
          deficit: 3,
          skillsRequired: ['Рекрутинг', 'Обучение', 'HR системы'],
          priority: 'Low',
          recommendedStartDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)
        }
      ],
      recommendations: []
    };
    setAnalysisResults(mockResults);
  }, []);

  const departments = ['all', 'Служба поддержки', 'IT поддержка', 'Отдел продаж', 'Аналитика', 'HR'];
  
  const filteredGaps = analysisResults?.staffingGaps.filter(gap => 
    selectedDepartment === 'all' || gap.department === selectedDepartment
  ) || [];

  // BDD: Calculate statistics for visualization
  const totalByPriority = {
    Critical: filteredGaps.filter(g => g.priority === 'Critical').reduce((sum, g) => sum + g.deficit, 0),
    High: filteredGaps.filter(g => g.priority === 'High').reduce((sum, g) => sum + g.deficit, 0),
    Medium: filteredGaps.filter(g => g.priority === 'Medium').reduce((sum, g) => sum + g.deficit, 0),
    Low: filteredGaps.filter(g => g.priority === 'Low').reduce((sum, g) => sum + g.deficit, 0)
  };

  const maxDeficit = Math.max(...filteredGaps.map(g => g.deficit), 1);

  // BDD: Export functionality
  const exportData = (format: string) => {
    console.log(`[EXPORT] Exporting vacancy analysis results in ${format} format`);
    // Simulate export
    const filename = `vacancy_analysis_${new Date().toISOString().split('T')[0]}.${format}`;
    alert(`Экспорт в ${format.toUpperCase()}: ${filename}`);
  };

  if (!analysisResults) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-500">Нет результатов анализа для отображения</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Общий дефицит</p>
              <p className="text-2xl font-bold text-red-600">{analysisResults.totalDeficit}</p>
              <p className="text-xs text-gray-500">позиций</p>
            </div>
            <TrendingDown className="h-8 w-8 text-red-200" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Влияние на SLA</p>
              <p className="text-2xl font-bold text-orange-600">-{analysisResults.serviceImpact}%</p>
              <p className="text-xs text-gray-500">снижение</p>
            </div>
            <BarChart3 className="h-8 w-8 text-orange-200" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Стоимость найма</p>
              <p className="text-2xl font-bold text-blue-600">
                {(analysisResults.estimatedCost / 1000000).toFixed(1)}М
              </p>
              <p className="text-xs text-gray-500">рублей</p>
            </div>
            <DollarSign className="h-8 w-8 text-blue-200" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Критичных</p>
              <p className="text-2xl font-bold text-red-600">{totalByPriority.Critical}</p>
              <p className="text-xs text-gray-500">позиций</p>
            </div>
            <Calendar className="h-8 w-8 text-red-200" />
          </div>
        </div>
      </div>

      {/* Filters and Export */}
      <div className="bg-white rounded-lg shadow p-4">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-500" />
              <select
                value={selectedDepartment}
                onChange={(e) => setSelectedDepartment(e.target.value)}
                className="rounded-md border-gray-300 text-sm"
              >
                <option value="all">Все отделы</option>
                {departments.slice(1).map(dept => (
                  <option key={dept} value={dept}>{dept}</option>
                ))}
              </select>
            </div>

            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="rounded-md border-gray-300 text-sm"
            >
              <option value="week">Неделя</option>
              <option value="month">Месяц</option>
              <option value="quarter">Квартал</option>
              <option value="year">Год</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => exportData('pdf')}
              className="flex items-center gap-1 px-3 py-1.5 text-sm border rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4" />
              PDF
            </button>
            <button
              onClick={() => exportData('excel')}
              className="flex items-center gap-1 px-3 py-1.5 text-sm border rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4" />
              Excel
            </button>
            <button
              onClick={() => exportData('png')}
              className="flex items-center gap-1 px-3 py-1.5 text-sm border rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4" />
              PNG
            </button>
          </div>
        </div>
      </div>

      {/* BDD: Staffing Gap Chart */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">График кадрового дефицита</h3>
        
        <div className="space-y-4">
          {filteredGaps.map((gap, index) => (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-0.5 text-xs rounded-full ${
                      gap.priority === 'Critical' ? 'bg-red-100 text-red-700' :
                      gap.priority === 'High' ? 'bg-orange-100 text-orange-700' :
                      gap.priority === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {gap.priority === 'Critical' ? 'Критично' :
                       gap.priority === 'High' ? 'Высокий' :
                       gap.priority === 'Medium' ? 'Средний' : 'Низкий'}
                    </span>
                    <h4 className="font-medium">{gap.position}</h4>
                    <span className="text-sm text-gray-500">({gap.department})</span>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Навыки: {gap.skillsRequired.join(', ')}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-lg">{gap.deficit}</p>
                  <p className="text-xs text-gray-500">позиций</p>
                </div>
              </div>
              
              <div className="relative">
                <div className="w-full bg-gray-200 rounded-full h-6">
                  <div 
                    className={`h-6 rounded-full flex items-center justify-end pr-2 ${
                      gap.priority === 'Critical' ? 'bg-red-500' :
                      gap.priority === 'High' ? 'bg-orange-500' :
                      gap.priority === 'Medium' ? 'bg-yellow-500' :
                      'bg-gray-400'
                    }`}
                    style={{ width: `${(gap.deficit / maxDeficit) * 100}%` }}
                  >
                    <span className="text-xs text-white font-medium">{gap.deficit}</span>
                  </div>
                </div>
              </div>
              
              <p className="text-xs text-gray-500">
                Рекомендуемая дата начала: {gap.recommendedStartDate.toLocaleDateString('ru-RU')}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* BDD: Service Level Impact */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Влияние на уровень обслуживания</h3>
          
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span>Текущий SLA</span>
                <span className="font-medium">95%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: '95%' }} />
              </div>
            </div>
            
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span>Прогноз без найма</span>
                <span className="font-medium text-red-600">80%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-red-500 h-2 rounded-full" style={{ width: '80%' }} />
              </div>
            </div>
            
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span>Прогноз с наймом</span>
                <span className="font-medium text-green-600">98%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: '98%' }} />
              </div>
            </div>
          </div>
        </div>

        {/* BDD: Cost Analysis */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Анализ затрат</h3>
          
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-sm text-gray-600">Зарплаты новых сотрудников</span>
              <span className="font-medium">₽1,800,000</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-gray-600">Затраты на найм</span>
              <span className="font-medium">₽300,000</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-gray-600">Обучение и адаптация</span>
              <span className="font-medium">₽400,000</span>
            </div>
            <div className="border-t pt-3 flex justify-between">
              <span className="font-medium">Итого</span>
              <span className="font-bold text-lg">₽2,500,000</span>
            </div>
            
            <div className="mt-4 p-3 bg-green-50 rounded-lg">
              <p className="text-sm text-green-800">
                <strong>ROI:</strong> Инвестиции окупятся за 4 месяца за счет повышения SLA и снижения потерь клиентов
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};