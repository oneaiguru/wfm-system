import React, { useState, useEffect } from 'react';
import { Layers, Play, Copy, Save, Trash2, TrendingUp, AlertTriangle, Download, Plus } from 'lucide-react';

interface Scenario {
  id: string;
  name: string;
  description: string;
  baselineId: string;
  parameters: {
    demandChange: number;
    seasonalityAdjustment: number;
    trendModification: number;
    volatilityFactor: number;
    externalFactors: Array<{
      name: string;
      impact: number;
      probability: number;
    }>;
  };
  results: {
    forecastAccuracy: number;
    confidenceInterval: [number, number];
    riskLevel: 'low' | 'medium' | 'high';
    impactAssessment: {
      staffingRequirement: number;
      costImpact: number;
      serviceLevel: number;
    };
  };
  createdAt: Date;
  lastModified: Date;
  status: 'draft' | 'validated' | 'approved' | 'archived';
}

interface ComparisonResult {
  scenarios: string[];
  metrics: Array<{
    name: string;
    values: number[];
    unit: string;
    bestScenario: number;
  }>;
  recommendations: Array<{
    scenario: string;
    priority: 'high' | 'medium' | 'low';
    action: string;
    rationale: string;
  }>;
}

interface ExternalFactor {
  id: string;
  name: string;
  category: 'economic' | 'seasonal' | 'business' | 'external';
  description: string;
  impact_range: [number, number];
  probability_default: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const ScenarioModelingEngine: React.FC = () => {
  const [scenarios, setScenarios] = useState<Scenario[]>([]);
  const [selectedScenarios, setSelectedScenarios] = useState<string[]>([]);
  const [comparisonResult, setComparisonResult] = useState<ComparisonResult | null>(null);
  const [externalFactors, setExternalFactors] = useState<ExternalFactor[]>([]);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [isRunning, setIsRunning] = useState(false);
  const [newScenario, setNewScenario] = useState({
    name: '',
    description: '',
    demandChange: 0,
    seasonalityAdjustment: 0,
    trendModification: 0,
    volatilityFactor: 1.0,
    selectedFactors: [] as Array<{ factorId: string; impact: number; probability: number }>
  });

  const loadScenarioData = async () => {
    try {
      console.log('[SCENARIO MODELING] Loading scenario modeling data...');

      // Load scenarios
      const scenariosResponse = await fetch(`${API_BASE_URL}/forecasting/scenarios`);
      if (!scenariosResponse.ok) {
        throw new Error(`Scenarios API failed: ${scenariosResponse.status}`);
      }

      const scenariosData = await scenariosResponse.json();
      const realScenarios = (scenariosData.scenarios || []).map((scenario: any) => ({
        id: scenario.id || `scenario_${Date.now()}`,
        name: scenario.name || scenario.scenario_name,
        description: scenario.description || scenario.summary,
        baselineId: scenario.baseline_id || scenario.baselineId || 'baseline-1',
        parameters: scenario.parameters || {},
        results: scenario.results || {},
        createdAt: new Date(scenario.created_at || scenario.createdAt || Date.now()),
        lastModified: new Date(scenario.last_modified || scenario.lastModified || Date.now()),
        status: scenario.status || 'draft'
      }));

      setScenarios(realScenarios);

      // Load external factors
      const factorsResponse = await fetch(`${API_BASE_URL}/forecasting/external-factors`);
      if (factorsResponse.ok) {
        const factorsData = await factorsResponse.json();
        setExternalFactors(factorsData.factors || []);
      }

      console.log(`[SCENARIO MODELING] Loaded ${realScenarios.length} scenarios`);

    } catch (error) {
      console.error('[SCENARIO MODELING] Error loading data:', error);

      // Fallback data for demo
      const fallbackScenarios: Scenario[] = [
        {
          id: 'baseline-scenario',
          name: 'Базовый сценарий',
          description: 'Текущие условия работы без изменений',
          baselineId: 'baseline-1',
          parameters: {
            demandChange: 0,
            seasonalityAdjustment: 0,
            trendModification: 0,
            volatilityFactor: 1.0,
            externalFactors: []
          },
          results: {
            forecastAccuracy: 94.2,
            confidenceInterval: [92.1, 96.3],
            riskLevel: 'low',
            impactAssessment: {
              staffingRequirement: 100,
              costImpact: 0,
              serviceLevel: 95.0
            }
          },
          createdAt: new Date(Date.now() - 86400000 * 7),
          lastModified: new Date(Date.now() - 86400000),
          status: 'approved'
        },
        {
          id: 'growth-scenario',
          name: 'Сценарий роста',
          description: 'Увеличение спроса на 15% из-за маркетинговой кампании',
          baselineId: 'baseline-1',
          parameters: {
            demandChange: 15,
            seasonalityAdjustment: 5,
            trendModification: 10,
            volatilityFactor: 1.2,
            externalFactors: [
              { name: 'Маркетинговая кампания', impact: 12, probability: 0.85 },
              { name: 'Сезонный рост', impact: 8, probability: 0.70 }
            ]
          },
          results: {
            forecastAccuracy: 91.8,
            confidenceInterval: [87.2, 94.4],
            riskLevel: 'medium',
            impactAssessment: {
              staffingRequirement: 115,
              costImpact: 18500,
              serviceLevel: 93.5
            }
          },
          createdAt: new Date(Date.now() - 86400000 * 5),
          lastModified: new Date(Date.now() - 86400000 * 2),
          status: 'validated'
        },
        {
          id: 'crisis-scenario',
          name: 'Кризисный сценарий',
          description: 'Снижение спроса на 25% в результате экономического кризиса',
          baselineId: 'baseline-1',
          parameters: {
            demandChange: -25,
            seasonalityAdjustment: -10,
            trendModification: -20,
            volatilityFactor: 1.8,
            externalFactors: [
              { name: 'Экономический кризис', impact: -30, probability: 0.35 },
              { name: 'Снижение потребления', impact: -15, probability: 0.60 }
            ]
          },
          results: {
            forecastAccuracy: 87.3,
            confidenceInterval: [82.1, 91.5],
            riskLevel: 'high',
            impactAssessment: {
              staffingRequirement: 75,
              costImpact: -12000,
              serviceLevel: 97.8
            }
          },
          createdAt: new Date(Date.now() - 86400000 * 3),
          lastModified: new Date(Date.now() - 86400000),
          status: 'draft'
        },
        {
          id: 'optimistic-scenario',
          name: 'Оптимистичный сценарий',
          description: 'Максимальный рост спроса при всех благоприятных факторах',
          baselineId: 'baseline-1',
          parameters: {
            demandChange: 30,
            seasonalityAdjustment: 15,
            trendModification: 25,
            volatilityFactor: 1.4,
            externalFactors: [
              { name: 'Новые продукты', impact: 20, probability: 0.70 },
              { name: 'Партнерства', impact: 15, probability: 0.80 },
              { name: 'Технологические улучшения', impact: 10, probability: 0.90 }
            ]
          },
          results: {
            forecastAccuracy: 89.1,
            confidenceInterval: [83.7, 92.8],
            riskLevel: 'high',
            impactAssessment: {
              staffingRequirement: 130,
              costImpact: 35000,
              serviceLevel: 91.2
            }
          },
          createdAt: new Date(Date.now() - 86400000 * 2),
          lastModified: new Date(Date.now() - 86400000),
          status: 'draft'
        }
      ];

      const fallbackFactors: ExternalFactor[] = [
        {
          id: 'marketing-campaign',
          name: 'Маркетинговая кампания',
          category: 'business',
          description: 'Влияние рекламных и маркетинговых активностей',
          impact_range: [5, 25],
          probability_default: 0.75
        },
        {
          id: 'economic-conditions',
          name: 'Экономические условия',
          category: 'economic',
          description: 'Общее состояние экономики и покупательная способность',
          impact_range: [-30, 15],
          probability_default: 0.60
        },
        {
          id: 'seasonal-events',
          name: 'Сезонные события',
          category: 'seasonal',
          description: 'Праздники, каникулы и сезонные колебания',
          impact_range: [-15, 20],
          probability_default: 0.85
        },
        {
          id: 'competitor-actions',
          name: 'Действия конкурентов',
          category: 'external',
          description: 'Активность конкурентов и изменения рынка',
          impact_range: [-20, 10],
          probability_default: 0.50
        },
        {
          id: 'product-launches',
          name: 'Запуск новых продуктов',
          category: 'business',
          description: 'Влияние новых продуктов или услуг',
          impact_range: [10, 40],
          probability_default: 0.65
        }
      ];

      setScenarios(fallbackScenarios);
      setExternalFactors(fallbackFactors);
    }
  };

  useEffect(() => {
    loadScenarioData();
  }, []);

  const runScenarioComparison = async () => {
    if (selectedScenarios.length < 2) return;

    setIsRunning(true);

    try {
      const response = await fetch(`${API_BASE_URL}/forecasting/compare-scenarios`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          scenario_ids: selectedScenarios
        })
      });

      if (response.ok) {
        const result = await response.json();
        setComparisonResult(result.comparison);
      }
    } catch (error) {
      console.error('Failed to run scenario comparison:', error);
      
      // Generate mock comparison result
      const mockComparison: ComparisonResult = {
        scenarios: selectedScenarios,
        metrics: [
          {
            name: 'Точность прогноза',
            values: selectedScenarios.map(id => {
              const scenario = scenarios.find(s => s.id === id);
              return scenario?.results.forecastAccuracy || 90;
            }),
            unit: '%',
            bestScenario: 0
          },
          {
            name: 'Потребность в персонале',
            values: selectedScenarios.map(id => {
              const scenario = scenarios.find(s => s.id === id);
              return scenario?.results.impactAssessment.staffingRequirement || 100;
            }),
            unit: 'чел',
            bestScenario: 0
          },
          {
            name: 'Финансовое влияние',
            values: selectedScenarios.map(id => {
              const scenario = scenarios.find(s => s.id === id);
              return scenario?.results.impactAssessment.costImpact || 0;
            }),
            unit: 'руб',
            bestScenario: 0
          },
          {
            name: 'Уровень сервиса',
            values: selectedScenarios.map(id => {
              const scenario = scenarios.find(s => s.id === id);
              return scenario?.results.impactAssessment.serviceLevel || 95;
            }),
            unit: '%',
            bestScenario: selectedScenarios.length - 1
          }
        ],
        recommendations: [
          {
            scenario: selectedScenarios[0],
            priority: 'high',
            action: 'Принять как базовый план',
            rationale: 'Оптимальное соотношение риска и доходности'
          },
          {
            scenario: selectedScenarios[1] || selectedScenarios[0],
            priority: 'medium',
            action: 'Подготовить план готовности',
            rationale: 'Высокая вероятность реализации сценария'
          }
        ]
      };

      setComparisonResult(mockComparison);
    } finally {
      setTimeout(() => setIsRunning(false), 2000);
    }
  };

  const createScenario = async () => {
    if (!newScenario.name.trim()) return;

    const scenario: Scenario = {
      id: `scenario_${Date.now()}`,
      name: newScenario.name,
      description: newScenario.description,
      baselineId: 'baseline-1',
      parameters: {
        demandChange: newScenario.demandChange,
        seasonalityAdjustment: newScenario.seasonalityAdjustment,
        trendModification: newScenario.trendModification,
        volatilityFactor: newScenario.volatilityFactor,
        externalFactors: newScenario.selectedFactors.map(f => {
          const factor = externalFactors.find(ef => ef.id === f.factorId);
          return {
            name: factor?.name || '',
            impact: f.impact,
            probability: f.probability
          };
        })
      },
      results: {
        forecastAccuracy: 90 + Math.random() * 10,
        confidenceInterval: [85 + Math.random() * 5, 95 + Math.random() * 5],
        riskLevel: Math.abs(newScenario.demandChange) > 20 ? 'high' : Math.abs(newScenario.demandChange) > 10 ? 'medium' : 'low',
        impactAssessment: {
          staffingRequirement: Math.round(100 * (1 + newScenario.demandChange / 100)),
          costImpact: Math.round(newScenario.demandChange * 1000),
          serviceLevel: 95 - Math.abs(newScenario.demandChange) * 0.1
        }
      },
      createdAt: new Date(),
      lastModified: new Date(),
      status: 'draft'
    };

    try {
      const response = await fetch(`${API_BASE_URL}/forecasting/scenarios`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(scenario)
      });

      if (response.ok) {
        setScenarios(prev => [scenario, ...prev]);
      }
    } catch (error) {
      // Fallback to local update
      setScenarios(prev => [scenario, ...prev]);
    }

    setShowCreateDialog(false);
    setNewScenario({
      name: '',
      description: '',
      demandChange: 0,
      seasonalityAdjustment: 0,
      trendModification: 0,
      volatilityFactor: 1.0,
      selectedFactors: []
    });
  };

  const duplicateScenario = (scenarioId: string) => {
    const originalScenario = scenarios.find(s => s.id === scenarioId);
    if (!originalScenario) return;

    const duplicatedScenario: Scenario = {
      ...originalScenario,
      id: `scenario_${Date.now()}`,
      name: `${originalScenario.name} (копия)`,
      createdAt: new Date(),
      lastModified: new Date(),
      status: 'draft'
    };

    setScenarios(prev => [duplicatedScenario, ...prev]);
  };

  const deleteScenario = (scenarioId: string) => {
    setScenarios(prev => prev.filter(s => s.id !== scenarioId));
    setSelectedScenarios(prev => prev.filter(id => id !== scenarioId));
  };

  const exportComparison = () => {
    if (!comparisonResult) return;

    const exportData = {
      comparison: comparisonResult,
      scenarios: scenarios.filter(s => selectedScenarios.includes(s.id)),
      timestamp: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `scenario-comparison-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getStatusColor = (status: Scenario['status']) => {
    switch (status) {
      case 'approved':
        return 'bg-green-100 text-green-800';
      case 'validated':
        return 'bg-blue-100 text-blue-800';
      case 'draft':
        return 'bg-yellow-100 text-yellow-800';
      case 'archived':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getRiskColor = (risk: 'low' | 'medium' | 'high') => {
    switch (risk) {
      case 'low':
        return 'bg-green-100 text-green-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'high':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const addExternalFactor = () => {
    if (externalFactors.length === 0) return;
    
    const firstFactor = externalFactors[0];
    setNewScenario(prev => ({
      ...prev,
      selectedFactors: [
        ...prev.selectedFactors,
        {
          factorId: firstFactor.id,
          impact: firstFactor.impact_range[0],
          probability: firstFactor.probability_default
        }
      ]
    }));
  };

  const removeExternalFactor = (index: number) => {
    setNewScenario(prev => ({
      ...prev,
      selectedFactors: prev.selectedFactors.filter((_, i) => i !== index)
    }));
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Layers className="h-6 w-6 mr-2 text-blue-600" />
              Движок Сценарного Моделирования
            </h2>
            <p className="mt-2 text-gray-600">
              Создание и сравнение различных сценариев прогнозирования
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowCreateDialog(true)}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Plus className="h-4 w-4 mr-2" />
              Создать сценарий
            </button>
            {comparisonResult && (
              <button
                onClick={exportComparison}
                className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                <Download className="h-4 w-4 mr-2" />
                Экспорт сравнения
              </button>
            )}
            <button
              onClick={runScenarioComparison}
              disabled={isRunning || selectedScenarios.length < 2}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <Play className="h-4 w-4 mr-2" />
              {isRunning ? 'Сравниваем...' : 'Сравнить сценарии'}
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Scenarios List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Сценарии</h3>
              <p className="text-sm text-gray-500">Выберите 2+ для сравнения</p>
            </div>
            
            <div className="p-4 space-y-3 max-h-96 overflow-y-auto">
              {scenarios.map((scenario) => (
                <div
                  key={scenario.id}
                  className={`p-3 border rounded-lg transition-colors ${
                    selectedScenarios.includes(scenario.id)
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <label className="flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedScenarios.includes(scenario.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedScenarios(prev => [...prev, scenario.id]);
                          } else {
                            setSelectedScenarios(prev => prev.filter(id => id !== scenario.id));
                          }
                        }}
                        className="mr-2 rounded"
                      />
                      <span className="text-sm font-medium text-gray-900 truncate">
                        {scenario.name}
                      </span>
                    </label>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => duplicateScenario(scenario.id)}
                        className="p-1 text-gray-400 hover:text-gray-600"
                        title="Дублировать"
                      >
                        <Copy className="h-3 w-3" />
                      </button>
                      <button
                        onClick={() => deleteScenario(scenario.id)}
                        className="p-1 text-gray-400 hover:text-red-600"
                        title="Удалить"
                      >
                        <Trash2 className="h-3 w-3" />
                      </button>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between text-xs mb-2">
                    <span className={`px-2 py-1 rounded-full ${getStatusColor(scenario.status)}`}>
                      {scenario.status === 'approved' ? 'Утвержден' :
                       scenario.status === 'validated' ? 'Проверен' :
                       scenario.status === 'draft' ? 'Черновик' : 'Архив'}
                    </span>
                    <span className={`px-2 py-1 rounded-full ${getRiskColor(scenario.results.riskLevel)}`}>
                      {scenario.results.riskLevel === 'low' ? 'Низкий риск' :
                       scenario.results.riskLevel === 'medium' ? 'Средний риск' : 'Высокий риск'}
                    </span>
                  </div>
                  
                  <p className="text-xs text-gray-600 mb-2 line-clamp-2">
                    {scenario.description}
                  </p>
                  
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="text-center p-1 bg-gray-50 rounded">
                      <div className="font-medium text-gray-900">{scenario.parameters.demandChange > 0 ? '+' : ''}{scenario.parameters.demandChange}%</div>
                      <div className="text-gray-500">Спрос</div>
                    </div>
                    <div className="text-center p-1 bg-gray-50 rounded">
                      <div className="font-medium text-gray-900">{scenario.results.forecastAccuracy.toFixed(1)}%</div>
                      <div className="text-gray-500">Точность</div>
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-500 mt-2">
                    Изменен: {scenario.lastModified.toLocaleDateString('ru-RU')}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Comparison Results */}
        <div className="lg:col-span-2">
          {comparisonResult ? (
            <div className="space-y-6">
              {/* Metrics Comparison */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Сравнение метрик</h3>
                
                <div className="overflow-x-auto">
                  <table className="min-w-full">
                    <thead>
                      <tr className="border-b border-gray-200">
                        <th className="text-left text-sm font-medium text-gray-500 py-2">Метрика</th>
                        {comparisonResult.scenarios.map((scenarioId, index) => {
                          const scenario = scenarios.find(s => s.id === scenarioId);
                          return (
                            <th key={scenarioId} className="text-center text-sm font-medium text-gray-500 py-2">
                              {scenario?.name || `Сценарий ${index + 1}`}
                            </th>
                          );
                        })}
                        <th className="text-center text-sm font-medium text-gray-500 py-2">Лучший</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {comparisonResult.metrics.map((metric, metricIndex) => (
                        <tr key={metricIndex}>
                          <td className="py-3 text-sm font-medium text-gray-900">
                            {metric.name}
                          </td>
                          {metric.values.map((value, valueIndex) => (
                            <td key={valueIndex} className="py-3 text-center">
                              <span className={`text-sm ${
                                valueIndex === metric.bestScenario 
                                  ? 'font-bold text-green-600' 
                                  : 'text-gray-900'
                              }`}>
                                {typeof value === 'number' ? value.toFixed(1) : value} {metric.unit}
                              </span>
                            </td>
                          ))}
                          <td className="py-3 text-center">
                            <TrendingUp className="h-4 w-4 text-green-500 mx-auto" />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Recommendations */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Рекомендации</h3>
                
                <div className="space-y-4">
                  {comparisonResult.recommendations.map((rec, index) => {
                    const scenario = scenarios.find(s => s.id === rec.scenario);
                    return (
                      <div key={index} className="p-4 border border-gray-200 rounded-lg">
                        <div className="flex items-center justify-between mb-2">
                          <h4 className="text-sm font-medium text-gray-900">
                            {scenario?.name || 'Сценарий'}
                          </h4>
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            rec.priority === 'high' ? 'bg-red-100 text-red-800' :
                            rec.priority === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-green-100 text-green-800'
                          }`}>
                            {rec.priority === 'high' ? 'Высокий' :
                             rec.priority === 'medium' ? 'Средний' : 'Низкий'} приоритет
                          </span>
                        </div>
                        <div className="text-sm text-gray-900 mb-1">
                          <strong>Действие:</strong> {rec.action}
                        </div>
                        <div className="text-sm text-gray-600">
                          <strong>Обоснование:</strong> {rec.rationale}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
              <Layers className="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Выберите сценарии для сравнения
              </h3>
              <p className="text-gray-600 mb-4">
                Отметьте 2 или более сценария в списке слева и нажмите "Сравнить сценарии"
              </p>
              <p className="text-sm text-gray-500">
                Выбрано сценариев: <strong>{selectedScenarios.length}</strong>
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Create Scenario Dialog */}
      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Создать новый сценарий</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Название сценария
                </label>
                <input
                  type="text"
                  value={newScenario.name}
                  onChange={(e) => setNewScenario(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Введите название сценария"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Описание
                </label>
                <textarea
                  value={newScenario.description}
                  onChange={(e) => setNewScenario(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Опишите условия и предположения сценария"
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Изменение спроса (%)
                  </label>
                  <input
                    type="number"
                    value={newScenario.demandChange}
                    onChange={(e) => setNewScenario(prev => ({ ...prev, demandChange: Number(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="0"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Корректировка сезонности (%)
                  </label>
                  <input
                    type="number"
                    value={newScenario.seasonalityAdjustment}
                    onChange={(e) => setNewScenario(prev => ({ ...prev, seasonalityAdjustment: Number(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="0"
                  />
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Модификация тренда (%)
                  </label>
                  <input
                    type="number"
                    value={newScenario.trendModification}
                    onChange={(e) => setNewScenario(prev => ({ ...prev, trendModification: Number(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="0"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Фактор волатильности
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={newScenario.volatilityFactor}
                    onChange={(e) => setNewScenario(prev => ({ ...prev, volatilityFactor: Number(e.target.value) }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="1.0"
                  />
                </div>
              </div>
              
              {/* External Factors */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="block text-sm font-medium text-gray-700">
                    Внешние факторы
                  </label>
                  <button
                    onClick={addExternalFactor}
                    className="flex items-center px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                  >
                    <Plus className="h-3 w-3 mr-1" />
                    Добавить
                  </button>
                </div>
                
                <div className="space-y-2">
                  {newScenario.selectedFactors.map((factor, index) => {
                    const factorDef = externalFactors.find(f => f.id === factor.factorId);
                    return (
                      <div key={index} className="p-3 border border-gray-200 rounded-md">
                        <div className="flex items-center justify-between mb-2">
                          <select
                            value={factor.factorId}
                            onChange={(e) => {
                              const newFactors = [...newScenario.selectedFactors];
                              newFactors[index].factorId = e.target.value;
                              setNewScenario(prev => ({ ...prev, selectedFactors: newFactors }));
                            }}
                            className="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
                          >
                            {externalFactors.map(ef => (
                              <option key={ef.id} value={ef.id}>{ef.name}</option>
                            ))}
                          </select>
                          <button
                            onClick={() => removeExternalFactor(index)}
                            className="ml-2 p-1 text-red-600 hover:text-red-800"
                          >
                            <Trash2 className="h-3 w-3" />
                          </button>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <div>
                            <label className="block text-xs text-gray-600">Влияние (%)</label>
                            <input
                              type="number"
                              value={factor.impact}
                              onChange={(e) => {
                                const newFactors = [...newScenario.selectedFactors];
                                newFactors[index].impact = Number(e.target.value);
                                setNewScenario(prev => ({ ...prev, selectedFactors: newFactors }));
                              }}
                              className="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                            />
                          </div>
                          <div>
                            <label className="block text-xs text-gray-600">Вероятность</label>
                            <input
                              type="number"
                              step="0.01"
                              min="0"
                              max="1"
                              value={factor.probability}
                              onChange={(e) => {
                                const newFactors = [...newScenario.selectedFactors];
                                newFactors[index].probability = Number(e.target.value);
                                setNewScenario(prev => ({ ...prev, selectedFactors: newFactors }));
                              }}
                              className="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                            />
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
            
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowCreateDialog(false)}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Отмена
              </button>
              <button
                onClick={createScenario}
                disabled={!newScenario.name.trim()}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                <Save className="h-4 w-4 mr-2 inline" />
                Создать сценарий
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ScenarioModelingEngine;