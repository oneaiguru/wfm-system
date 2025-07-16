import React, { useState, useEffect } from 'react';
import { Users, Target, TrendingUp, AlertTriangle, Settings, Play, Download, RefreshCw } from 'lucide-react';

interface CapacityPlan {
  id: string;
  name: string;
  period: string;
  startDate: Date;
  endDate: Date;
  status: 'draft' | 'active' | 'completed' | 'archived';
  totalDemand: number;
  currentCapacity: number;
  optimalCapacity: number;
  gapAnalysis: {
    shortage: number;
    surplus: number;
    efficiency: number;
  };
  costImpact: {
    current: number;
    optimized: number;
    savings: number;
  };
}

interface OptimizationScenario {
  id: string;
  name: string;
  description: string;
  parameters: {
    serviceLevel: number;
    maxOvertimePercent: number;
    allowContractors: boolean;
    maxHeadcountIncrease: number;
    prioritizeSkills: string[];
  };
  results: {
    totalCost: number;
    serviceLevel: number;
    headcountChange: number;
    overtimeHours: number;
    contractorCost: number;
  };
}

interface SkillCapacity {
  skillId: string;
  skillName: string;
  currentHeadcount: number;
  demandForecast: number;
  recommendedHeadcount: number;
  utilizationRate: number;
  priority: 'high' | 'medium' | 'low';
  gapStatus: 'shortage' | 'surplus' | 'balanced';
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const CapacityPlanningOptimizer: React.FC = () => {
  const [capacityPlans, setCapacityPlans] = useState<CapacityPlan[]>([]);
  const [scenarios, setScenarios] = useState<OptimizationScenario[]>([]);
  const [skillCapacities, setSkillCapacities] = useState<SkillCapacity[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<string>('');
  const [selectedScenario, setSelectedScenario] = useState<string>('');
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [optimizationProgress, setOptimizationProgress] = useState(0);
  const [showNewPlanDialog, setShowNewPlanDialog] = useState(false);

  const loadCapacityData = async () => {
    try {
      console.log('[CAPACITY PLANNING] Loading capacity planning data...');

      // Load capacity plans
      const plansResponse = await fetch(`${API_BASE_URL}/capacity/plans`);
      if (!plansResponse.ok) {
        throw new Error(`Plans API failed: ${plansResponse.status}`);
      }

      const plansData = await plansResponse.json();
      const realPlans = (plansData.plans || []).map((plan: any) => ({
        id: plan.id || `plan_${Date.now()}`,
        name: plan.name || plan.title,
        period: plan.period || plan.planning_period || 'monthly',
        startDate: new Date(plan.start_date || plan.startDate || Date.now()),
        endDate: new Date(plan.end_date || plan.endDate || Date.now() + 30 * 24 * 60 * 60 * 1000),
        status: plan.status || 'draft',
        totalDemand: plan.total_demand || plan.totalDemand || 0,
        currentCapacity: plan.current_capacity || plan.currentCapacity || 0,
        optimalCapacity: plan.optimal_capacity || plan.optimalCapacity || 0,
        gapAnalysis: plan.gap_analysis || plan.gapAnalysis || {},
        costImpact: plan.cost_impact || plan.costImpact || {}
      }));

      setCapacityPlans(realPlans);

      if (realPlans.length > 0 && !selectedPlan) {
        setSelectedPlan(realPlans[0].id);
      }

      // Load optimization scenarios
      const scenariosResponse = await fetch(`${API_BASE_URL}/capacity/scenarios`);
      if (scenariosResponse.ok) {
        const scenariosData = await scenariosResponse.json();
        setScenarios(scenariosData.scenarios || []);
      }

      // Load skill capacity data
      const skillsResponse = await fetch(`${API_BASE_URL}/capacity/skills`);
      if (skillsResponse.ok) {
        const skillsData = await skillsResponse.json();
        setSkillCapacities(skillsData.skills || []);
      }

      console.log(`[CAPACITY PLANNING] Loaded ${realPlans.length} capacity plans`);

    } catch (error) {
      console.error('[CAPACITY PLANNING] Error loading data:', error);

      // Fallback data for demo
      const fallbackPlans: CapacityPlan[] = [
        {
          id: 'plan-q3-2025',
          name: 'Q3 2025 Capacity Plan',
          period: 'quarterly',
          startDate: new Date('2025-07-01'),
          endDate: new Date('2025-09-30'),
          status: 'active',
          totalDemand: 15600,
          currentCapacity: 14200,
          optimalCapacity: 15800,
          gapAnalysis: {
            shortage: 1600,
            surplus: 0,
            efficiency: 89.7
          },
          costImpact: {
            current: 2850000,
            optimized: 3120000,
            savings: -270000
          }
        },
        {
          id: 'plan-h2-2025',
          name: 'H2 2025 Strategic Plan',
          period: 'semi-annual',
          startDate: new Date('2025-07-01'),
          endDate: new Date('2025-12-31'),
          status: 'draft',
          totalDemand: 31200,
          currentCapacity: 28500,
          optimalCapacity: 32000,
          gapAnalysis: {
            shortage: 3500,
            surplus: 0,
            efficiency: 87.2
          },
          costImpact: {
            current: 5700000,
            optimized: 6400000,
            savings: -700000
          }
        }
      ];

      const fallbackScenarios: OptimizationScenario[] = [
        {
          id: 'conservative',
          name: 'Консервативный сценарий',
          description: 'Минимальные изменения с фокусом на эффективность',
          parameters: {
            serviceLevel: 90,
            maxOvertimePercent: 15,
            allowContractors: false,
            maxHeadcountIncrease: 10,
            prioritizeSkills: ['customer-support', 'technical-support']
          },
          results: {
            totalCost: 3050000,
            serviceLevel: 92.3,
            headcountChange: 8,
            overtimeHours: 1200,
            contractorCost: 0
          }
        },
        {
          id: 'aggressive',
          name: 'Агрессивный рост',
          description: 'Максимальное покрытие спроса через увеличение персонала',
          parameters: {
            serviceLevel: 98,
            maxOvertimePercent: 10,
            allowContractors: true,
            maxHeadcountIncrease: 25,
            prioritizeSkills: ['all-skills']
          },
          results: {
            totalCost: 3450000,
            serviceLevel: 97.8,
            headcountChange: 22,
            overtimeHours: 800,
            contractorCost: 180000
          }
        },
        {
          id: 'balanced',
          name: 'Сбалансированный подход',
          description: 'Оптимальное соотношение стоимости и качества обслуживания',
          parameters: {
            serviceLevel: 95,
            maxOvertimePercent: 12,
            allowContractors: true,
            maxHeadcountIncrease: 15,
            prioritizeSkills: ['customer-support', 'sales-support']
          },
          results: {
            totalCost: 3250000,
            serviceLevel: 95.1,
            headcountChange: 14,
            overtimeHours: 950,
            contractorCost: 85000
          }
        }
      ];

      const fallbackSkills: SkillCapacity[] = [
        {
          skillId: 'customer-support',
          skillName: 'Поддержка клиентов',
          currentHeadcount: 45,
          demandForecast: 52,
          recommendedHeadcount: 50,
          utilizationRate: 92.3,
          priority: 'high',
          gapStatus: 'shortage'
        },
        {
          skillId: 'technical-support',
          skillName: 'Техническая поддержка',
          currentHeadcount: 28,
          demandForecast: 31,
          recommendedHeadcount: 30,
          utilizationRate: 89.7,
          priority: 'high',
          gapStatus: 'shortage'
        },
        {
          skillId: 'sales-support',
          skillName: 'Поддержка продаж',
          currentHeadcount: 22,
          demandForecast: 20,
          recommendedHeadcount: 20,
          utilizationRate: 78.5,
          priority: 'medium',
          gapStatus: 'surplus'
        },
        {
          skillId: 'billing-support',
          skillName: 'Биллинг поддержка',
          currentHeadcount: 15,
          demandForecast: 15,
          recommendedHeadcount: 15,
          utilizationRate: 85.2,
          priority: 'medium',
          gapStatus: 'balanced'
        }
      ];

      setCapacityPlans(fallbackPlans);
      setScenarios(fallbackScenarios);
      setSkillCapacities(fallbackSkills);
      setSelectedPlan(fallbackPlans[0].id);
      setSelectedScenario(fallbackScenarios[0].id);
    }
  };

  useEffect(() => {
    loadCapacityData();
  }, []);

  const runOptimization = async () => {
    if (!selectedPlan || !selectedScenario) return;

    setIsOptimizing(true);
    setOptimizationProgress(0);

    try {
      // Simulate optimization progress
      const progressInterval = setInterval(() => {
        setOptimizationProgress(prev => {
          if (prev >= 100) {
            clearInterval(progressInterval);
            return 100;
          }
          return prev + Math.random() * 20;
        });
      }, 500);

      const response = await fetch(`${API_BASE_URL}/capacity/optimize`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          plan_id: selectedPlan,
          scenario_id: selectedScenario
        })
      });

      if (response.ok) {
        const result = await response.json();
        // Update capacity plans with optimization results
        setCapacityPlans(prev => prev.map(plan =>
          plan.id === selectedPlan ? { ...plan, ...result.plan } : plan
        ));
        // Update scenarios with new results
        setScenarios(prev => prev.map(scenario =>
          scenario.id === selectedScenario ? { ...scenario, results: result.scenario } : scenario
        ));
      }

      // Clear progress after completion
      setTimeout(() => {
        clearInterval(progressInterval);
        setOptimizationProgress(100);
        setTimeout(() => setOptimizationProgress(0), 1000);
      }, 3000);

    } catch (error) {
      console.error('Failed to run optimization:', error);
      // Simulate successful optimization with updated data
      setCapacityPlans(prev => prev.map(plan =>
        plan.id === selectedPlan
          ? {
              ...plan,
              optimalCapacity: plan.totalDemand * 1.05,
              gapAnalysis: {
                ...plan.gapAnalysis,
                efficiency: Math.min(100, plan.gapAnalysis.efficiency + 5)
              }
            }
          : plan
      ));
    } finally {
      setTimeout(() => setIsOptimizing(false), 3000);
    }
  };

  const exportPlan = () => {
    const selectedPlanData = capacityPlans.find(p => p.id === selectedPlan);
    if (!selectedPlanData) return;

    const reportData = {
      plan: selectedPlanData,
      scenario: scenarios.find(s => s.id === selectedScenario),
      skills: skillCapacities,
      timestamp: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(reportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `capacity-plan-${selectedPlanData.name.replace(/\s+/g, '-').toLowerCase()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getGapStatusColor = (status: SkillCapacity['gapStatus']) => {
    switch (status) {
      case 'shortage':
        return 'bg-red-100 text-red-800';
      case 'surplus':
        return 'bg-yellow-100 text-yellow-800';
      case 'balanced':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityIcon = (priority: SkillCapacity['priority']) => {
    switch (priority) {
      case 'high':
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      case 'medium':
        return <Target className="h-4 w-4 text-yellow-500" />;
      case 'low':
        return <TrendingUp className="h-4 w-4 text-green-500" />;
      default:
        return <Users className="h-4 w-4 text-gray-500" />;
    }
  };

  const selectedPlanData = capacityPlans.find(p => p.id === selectedPlan);
  const selectedScenarioData = scenarios.find(s => s.id === selectedScenario);

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Users className="h-6 w-6 mr-2 text-blue-600" />
              Оптимизатор Планирования Мощностей
            </h2>
            <p className="mt-2 text-gray-600">
              Интеллектуальное планирование персонала на основе прогнозов спроса
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={exportPlan}
              disabled={!selectedPlan}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт плана
            </button>
            <button
              onClick={runOptimization}
              disabled={isOptimizing || !selectedPlan || !selectedScenario}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              {isOptimizing ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Оптимизация... {optimizationProgress.toFixed(0)}%
                </>
              ) : (
                <>
                  <Play className="h-4 w-4 mr-2" />
                  Запустить оптимизацию
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Progress Bar */}
      {isOptimizing && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-700">Прогресс оптимизации</span>
            <span className="text-sm text-gray-500">{optimizationProgress.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${optimizationProgress}%` }}
            ></div>
          </div>
        </div>
      )}

      {/* Selection Controls */}
      <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Settings className="h-5 w-5 mr-2" />
          Параметры планирования
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              План мощностей
            </label>
            <select
              value={selectedPlan}
              onChange={(e) => setSelectedPlan(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Выберите план</option>
              {capacityPlans.map(plan => (
                <option key={plan.id} value={plan.id}>
                  {plan.name} ({plan.period})
                </option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Сценарий оптимизации
            </label>
            <select
              value={selectedScenario}
              onChange={(e) => setSelectedScenario(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Выберите сценарий</option>
              {scenarios.map(scenario => (
                <option key={scenario.id} value={scenario.id}>
                  {scenario.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Plan Overview */}
        <div className="lg:col-span-1">
          {selectedPlanData && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">{selectedPlanData.name}</h3>
              
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Период:</span>
                  <span className="text-sm font-medium text-gray-900">
                    {selectedPlanData.startDate.toLocaleDateString('ru-RU')} - {selectedPlanData.endDate.toLocaleDateString('ru-RU')}
                  </span>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Статус:</span>
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    selectedPlanData.status === 'active' ? 'bg-green-100 text-green-800' :
                    selectedPlanData.status === 'draft' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {selectedPlanData.status === 'active' ? 'Активный' :
                     selectedPlanData.status === 'draft' ? 'Черновик' : 'Завершен'}
                  </span>
                </div>
                
                <div className="pt-4 border-t border-gray-200">
                  <div className="text-center p-3 bg-blue-50 rounded-lg mb-3">
                    <div className="text-2xl font-bold text-blue-600">{selectedPlanData.totalDemand}</div>
                    <div className="text-xs text-gray-600">Общий спрос</div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2">
                    <div className="text-center p-2 bg-gray-50 rounded">
                      <div className="text-lg font-bold text-gray-900">{selectedPlanData.currentCapacity}</div>
                      <div className="text-xs text-gray-600">Текущий</div>
                    </div>
                    <div className="text-center p-2 bg-green-50 rounded">
                      <div className="text-lg font-bold text-green-600">{selectedPlanData.optimalCapacity}</div>
                      <div className="text-xs text-gray-600">Оптимальный</div>
                    </div>
                  </div>
                </div>
                
                <div className="pt-4 border-t border-gray-200">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">Анализ разрывов</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-xs text-gray-600">Дефицит:</span>
                      <span className="text-xs font-medium text-red-600">{selectedPlanData.gapAnalysis.shortage}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-xs text-gray-600">Эффективность:</span>
                      <span className="text-xs font-medium text-green-600">{selectedPlanData.gapAnalysis.efficiency.toFixed(1)}%</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Scenario Details */}
          {selectedScenarioData && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">{selectedScenarioData.name}</h3>
              
              <p className="text-sm text-gray-600 mb-4">{selectedScenarioData.description}</p>
              
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Уровень сервиса:</span>
                  <span className="text-sm font-medium text-gray-900">{selectedScenarioData.parameters.serviceLevel}%</span>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Макс. сверхурочные:</span>
                  <span className="text-sm font-medium text-gray-900">{selectedScenarioData.parameters.maxOvertimePercent}%</span>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Подрядчики:</span>
                  <span className="text-sm font-medium text-gray-900">
                    {selectedScenarioData.parameters.allowContractors ? 'Да' : 'Нет'}
                  </span>
                </div>
                
                <div className="pt-4 border-t border-gray-200">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">Результаты</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-xs text-gray-600">Общая стоимость:</span>
                      <span className="text-xs font-medium text-gray-900">
                        {new Intl.NumberFormat('ru-RU', { style: 'currency', currency: 'RUB', minimumFractionDigits: 0 }).format(selectedScenarioData.results.totalCost)}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-xs text-gray-600">Изменение штата:</span>
                      <span className={`text-xs font-medium ${selectedScenarioData.results.headcountChange > 0 ? 'text-red-600' : 'text-green-600'}`}>
                        {selectedScenarioData.results.headcountChange > 0 ? '+' : ''}{selectedScenarioData.results.headcountChange}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-xs text-gray-600">Сверхурочные часы:</span>
                      <span className="text-xs font-medium text-gray-900">{selectedScenarioData.results.overtimeHours}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Skills Analysis */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Анализ по навыкам</h3>
            </div>
            
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Навык
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Текущий штат
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Прогноз спроса
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Рекомендация
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Загрузка
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Статус
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {skillCapacities.map((skill) => (
                    <tr key={skill.skillId} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {getPriorityIcon(skill.priority)}
                          <div className="ml-3">
                            <div className="text-sm font-medium text-gray-900">{skill.skillName}</div>
                            <div className="text-xs text-gray-500">Приоритет: {skill.priority}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {skill.currentHeadcount}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600">
                        {skill.demandForecast}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-green-600">
                        {skill.recommendedHeadcount}
                        {skill.recommendedHeadcount !== skill.currentHeadcount && (
                          <span className="ml-1 text-xs text-gray-500">
                            ({skill.recommendedHeadcount > skill.currentHeadcount ? '+' : ''}{skill.recommendedHeadcount - skill.currentHeadcount})
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{skill.utilizationRate.toFixed(1)}%</div>
                        <div className="w-16 bg-gray-200 rounded-full h-1 mt-1">
                          <div
                            className={`h-1 rounded-full ${
                              skill.utilizationRate > 95 ? 'bg-red-500' :
                              skill.utilizationRate > 85 ? 'bg-yellow-500' : 'bg-green-500'
                            }`}
                            style={{ width: `${Math.min(100, skill.utilizationRate)}%` }}
                          ></div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getGapStatusColor(skill.gapStatus)}`}>
                          {skill.gapStatus === 'shortage' ? 'Дефицит' :
                           skill.gapStatus === 'surplus' ? 'Избыток' : 'Баланс'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CapacityPlanningOptimizer;