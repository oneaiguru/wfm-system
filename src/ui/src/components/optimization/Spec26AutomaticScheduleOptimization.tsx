import React, { useState, useEffect, useCallback } from 'react';
import {
  Play,
  Pause,
  Square,
  Settings,
  BarChart3,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  Clock,
  Users,
  DollarSign,
  Star,
  Target,
  Zap,
  Shield,
  RefreshCw,
  Activity,
  Eye,
  Save,
  Download,
  Upload,
  Globe
} from 'lucide-react';

// SPEC-26: Automatic Schedule Optimization 
// Enhanced from ScheduleOptimizer.tsx with genetic algorithm visualization and multi-objective optimization
// Focus: Scheduling managers, operations managers, team leads (20+ daily users)

interface GeneticParameters {
  populationSize: number;
  generations: number;
  crossoverRate: number;
  mutationRate: number;
  elitePreservation: number;
}

interface OptimizationObjective {
  id: string;
  name: string;
  nameRu: string;
  weight: number;
  current: number;
  target: number;
  improvement: number;
  unit: string;
}

interface OptimizationConstraint {
  id: string;
  type: string;
  name: string;
  nameRu: string;
  status: 'satisfied' | 'violated' | 'warning';
  current: string;
  limit: string;
  severity: 'high' | 'medium' | 'low';
}

interface OptimizationProgress {
  generation: number;
  bestFitness: number;
  averageFitness: number;
  convergence: number;
  timeElapsed: number;
  estimatedRemaining: number;
}

interface OptimizationResult {
  id: string;
  objectives: OptimizationObjective[];
  constraints: OptimizationConstraint[];
  progress: OptimizationProgress;
  status: 'running' | 'completed' | 'failed' | 'paused';
  startTime: string;
  endTime?: string;
  recommendations: {
    category: string;
    suggestion: string;
    impact: string;
    effort: 'low' | 'medium' | 'high';
    priority: 'high' | 'medium' | 'low';
  }[];
}

const Spec26AutomaticScheduleOptimization: React.FC = () => {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [optimizing, setOptimizing] = useState(false);
  const [paused, setPaused] = useState(false);
  const [results, setResults] = useState<OptimizationResult | null>(null);
  const [apiError, setApiError] = useState<string>('');
  const [selectedScenario, setSelectedScenario] = useState<string>('balanced');
  const [showAdvancedSettings, setShowAdvancedSettings] = useState(false);
  
  // Genetic Algorithm Parameters
  const [geneticParams, setGeneticParams] = useState<GeneticParameters>({
    populationSize: 100,
    generations: 50,
    crossoverRate: 0.8,
    mutationRate: 0.1,
    elitePreservation: 10
  });

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

  // Optimization scenarios
  const optimizationScenarios = {
    balanced: {
      name: 'Balanced Optimization',
      nameRu: 'Сбалансированная оптимизация',
      description: 'Optimal balance between cost, coverage, and satisfaction',
      descriptionRu: 'Оптимальный баланс между стоимостью, покрытием и удовлетворенностью',
      icon: Target
    },
    cost: {
      name: 'Cost Minimization',
      nameRu: 'Минимизация затрат',
      description: 'Focus on reducing labor costs and overtime',
      descriptionRu: 'Фокус на снижении трудозатрат и сверхурочных',
      icon: DollarSign
    },
    coverage: {
      name: 'Coverage Optimization',
      nameRu: 'Оптимизация покрытия',
      description: 'Maximize service level and response times',
      descriptionRu: 'Максимизация уровня обслуживания и времени отклика',
      icon: Shield
    },
    satisfaction: {
      name: 'Employee Satisfaction',
      nameRu: 'Удовлетворенность сотрудников',
      description: 'Prioritize work-life balance and preferences',
      descriptionRu: 'Приоритет баланса работы и жизни, предпочтения',
      icon: Star
    },
    emergency: {
      name: 'Emergency Response',
      nameRu: 'Экстренная оптимизация',
      description: 'Rapid optimization for crisis situations',
      descriptionRu: 'Быстрая оптимизация для кризисных ситуаций',
      icon: Zap
    }
  };

  const translations = {
    ru: {
      title: 'Автоматическая Оптимизация Расписаний',
      subtitle: 'SPEC-26: Генетический алгоритм с многоцелевой оптимизацией',
      startOptimization: 'Запустить Оптимизацию',
      pauseOptimization: 'Приостановить',
      stopOptimization: 'Остановить',
      resumeOptimization: 'Продолжить',
      optimizationRunning: 'Выполняется оптимизация...',
      optimizationPaused: 'Оптимизация приостановлена',
      optimizationCompleted: 'Оптимизация завершена',
      scenario: 'Сценарий',
      geneticParameters: 'Параметры генетического алгоритма',
      populationSize: 'Размер популяции',
      generations: 'Поколения',
      crossoverRate: 'Скорость скрещивания',
      mutationRate: 'Скорость мутации',
      elitePreservation: 'Сохранение элиты (%)',
      objectives: 'Цели оптимизации',
      constraints: 'Ограничения',
      progress: 'Прогресс',
      generation: 'Поколение',
      bestFitness: 'Лучшая приспособленность',
      averageFitness: 'Средняя приспособленность',
      convergence: 'Сходимость',
      timeElapsed: 'Прошло времени',
      estimatedRemaining: 'Осталось (примерно)',
      recommendations: 'Рекомендации',
      advancedSettings: 'Расширенные настройки',
      satisfied: 'Выполнено',
      violated: 'Нарушено',
      warning: 'Предупреждение',
      high: 'Высокий',
      medium: 'Средний',
      low: 'Низкий'
    },
    en: {
      title: 'Automatic Schedule Optimization',
      subtitle: 'SPEC-26: Genetic Algorithm with Multi-Objective Optimization',
      startOptimization: 'Start Optimization',
      pauseOptimization: 'Pause',
      stopOptimization: 'Stop',
      resumeOptimization: 'Resume',
      optimizationRunning: 'Optimization running...',
      optimizationPaused: 'Optimization paused',
      optimizationCompleted: 'Optimization completed',
      scenario: 'Scenario',
      geneticParameters: 'Genetic Algorithm Parameters',
      populationSize: 'Population Size',
      generations: 'Generations',
      crossoverRate: 'Crossover Rate',
      mutationRate: 'Mutation Rate',
      elitePreservation: 'Elite Preservation (%)',
      objectives: 'Optimization Objectives',
      constraints: 'Constraints',
      progress: 'Progress',
      generation: 'Generation',
      bestFitness: 'Best Fitness',
      averageFitness: 'Average Fitness',
      convergence: 'Convergence',
      timeElapsed: 'Time Elapsed',
      estimatedRemaining: 'Estimated Remaining',
      recommendations: 'Recommendations',
      advancedSettings: 'Advanced Settings',
      satisfied: 'Satisfied',
      violated: 'Violated',
      warning: 'Warning',
      high: 'High',
      medium: 'Medium',
      low: 'Low'
    }
  };

  const t = translations[language];

  // Demo optimization objectives
  const getObjectives = useCallback((): OptimizationObjective[] => [
    {
      id: 'cost',
      name: 'Cost Efficiency',
      nameRu: 'Эффективность затрат',
      weight: 0.3,
      current: 12450,
      target: 10200,
      improvement: -18.1,
      unit: '₽/неделя'
    },
    {
      id: 'coverage',
      name: 'Coverage Quality',
      nameRu: 'Качество покрытия',
      weight: 0.3,
      current: 87,
      target: 94,
      improvement: 8.0,
      unit: '%'
    },
    {
      id: 'satisfaction',
      name: 'Employee Satisfaction',
      nameRu: 'Удовлетворенность сотрудников',
      weight: 0.25,
      current: 3.2,
      target: 4.1,
      improvement: 28.1,
      unit: '/5'
    },
    {
      id: 'adherence',
      name: 'Schedule Adherence',
      nameRu: 'Соблюдение расписания',
      weight: 0.15,
      current: 89,
      target: 95,
      improvement: 6.7,
      unit: '%'
    }
  ], []);

  // Demo constraints
  const getConstraints = useCallback((): OptimizationConstraint[] => [
    {
      id: 'maxHours',
      type: 'labor_law',
      name: 'Maximum Hours per Week',
      nameRu: 'Максимум часов в неделю',
      status: 'satisfied',
      current: '38.5 ч',
      limit: '40 ч',
      severity: 'high'
    },
    {
      id: 'restPeriod',
      type: 'labor_law',
      name: 'Rest Period Between Shifts',
      nameRu: 'Отдых между сменами',
      status: 'satisfied',
      current: '12 ч',
      limit: '11 ч',
      severity: 'high'
    },
    {
      id: 'overtime',
      type: 'labor_law',
      name: 'Daily Overtime Limit',
      nameRu: 'Лимит сверхурочных в день',
      status: 'warning',
      current: '3.5 ч',
      limit: '4 ч',
      severity: 'medium'
    },
    {
      id: 'coverage',
      type: 'business',
      name: 'Minimum Coverage',
      nameRu: 'Минимальное покрытие',
      status: 'satisfied',
      current: '94%',
      limit: '90%',
      severity: 'high'
    }
  ], []);

  // Simulate optimization progress
  useEffect(() => {
    if (optimizing && !paused) {
      const interval = setInterval(() => {
        if (results) {
          const newGeneration = Math.min(results.progress.generation + 1, geneticParams.generations);
          const convergenceRate = newGeneration / geneticParams.generations;
          
          setResults(prev => prev ? {
            ...prev,
            progress: {
              ...prev.progress,
              generation: newGeneration,
              bestFitness: 95.2 + (convergenceRate * 4.3), // Improving fitness
              averageFitness: 78.5 + (convergenceRate * 12.7),
              convergence: convergenceRate * 100,
              timeElapsed: prev.progress.timeElapsed + 1,
              estimatedRemaining: Math.max(0, 
                (geneticParams.generations - newGeneration) * 
                (prev.progress.timeElapsed / Math.max(1, newGeneration))
              )
            },
            status: newGeneration >= geneticParams.generations ? 'completed' : 'running'
          } : null);

          if (newGeneration >= geneticParams.generations) {
            setOptimizing(false);
          }
        }
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [optimizing, paused, results, geneticParams.generations]);

  const startOptimization = async () => {
    setOptimizing(true);
    setPaused(false);
    setApiError('');

    try {
      console.log('[SPEC-26 OPTIMIZATION] Starting genetic algorithm optimization...', {
        scenario: selectedScenario,
        parameters: geneticParams
      });

      // Initialize demo results
      const initialResult: OptimizationResult = {
        id: Date.now().toString(),
        objectives: getObjectives(),
        constraints: getConstraints(),
        progress: {
          generation: 0,
          bestFitness: 78.5,
          averageFitness: 65.2,
          convergence: 0,
          timeElapsed: 0,
          estimatedRemaining: geneticParams.generations * 1.2
        },
        status: 'running',
        startTime: new Date().toISOString(),
        recommendations: [
          {
            category: 'Coverage Gap',
            suggestion: language === 'ru' ? 
              'Добавить 2 part-time сотрудников в период 14:00-16:00' : 
              'Add 2 part-time agents during 14:00-16:00',
            impact: '+5% service level',
            effort: 'medium',
            priority: 'high'
          },
          {
            category: 'Cost Efficiency',
            suggestion: language === 'ru' ? 
              'Перераспределить смены для снижения сверхурочных' : 
              'Redistribute shifts to reduce overtime costs',
            impact: '-12% labor costs',
            effort: 'low',
            priority: 'high'
          },
          {
            category: 'Skill Optimization',
            suggestion: language === 'ru' ? 
              'Переназначить специалистов на соответствующие смены' : 
              'Reallocate specialists to matching shifts',
            impact: '+8% first call resolution',
            effort: 'low',
            priority: 'medium'
          }
        ]
      };

      setResults(initialResult);

      // In real implementation, this would call SPEC-26 genetic optimization API
      // const response = await fetch(`${API_BASE_URL}/optimization/genetic/start`, {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify({
      //     scenario: selectedScenario,
      //     parameters: geneticParams,
      //     language: language
      //   })
      // });

    } catch (error) {
      setApiError('Failed to start optimization process');
      console.error('[SPEC-26 OPTIMIZATION] Error:', error);
      setOptimizing(false);
    }
  };

  const pauseOptimization = () => {
    setPaused(true);
    if (results) {
      setResults({...results, status: 'paused'});
    }
  };

  const resumeOptimization = () => {
    setPaused(false);
    if (results) {
      setResults({...results, status: 'running'});
    }
  };

  const stopOptimization = () => {
    setOptimizing(false);
    setPaused(false);
    if (results) {
      setResults({
        ...results, 
        status: 'completed',
        endTime: new Date().toISOString()
      });
    }
  };

  const getConstraintIcon = (status: string) => {
    switch (status) {
      case 'satisfied': return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'violated': return <AlertTriangle className="h-4 w-4 text-red-600" />;
      case 'warning': return <AlertTriangle className="h-4 w-4 text-yellow-600" />;
      default: return <CheckCircle className="h-4 w-4 text-gray-400" />;
    }
  };

  const getConstraintColor = (status: string) => {
    switch (status) {
      case 'satisfied': return 'border-green-200 bg-green-50';
      case 'violated': return 'border-red-200 bg-red-50';
      case 'warning': return 'border-yellow-200 bg-yellow-50';
      default: return 'border-gray-200 bg-gray-50';
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{t.title}</h1>
              <p className="text-gray-600 mt-1">{t.subtitle}</p>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
                className="flex items-center gap-2 px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Globe size={16} />
                {language === 'ru' ? 'EN' : 'RU'}
              </button>
            </div>
          </div>
        </div>

        {/* Error Message */}
        {apiError && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
            <AlertTriangle className="h-5 w-5 text-red-600 mr-3" />
            <div>
              <p className="font-medium text-red-800">Error</p>
              <p className="text-red-700 text-sm">{apiError}</p>
            </div>
          </div>
        )}

        {/* Control Panel */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-medium text-gray-900">Optimization Control Panel</h2>
            <button
              onClick={() => setShowAdvancedSettings(!showAdvancedSettings)}
              className="flex items-center gap-2 px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              <Settings size={16} />
              {t.advancedSettings}
            </button>
          </div>

          {/* Scenario Selection */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">{t.scenario}</label>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
              {Object.entries(optimizationScenarios).map(([key, scenario]) => {
                const IconComponent = scenario.icon;
                return (
                  <button
                    key={key}
                    onClick={() => setSelectedScenario(key)}
                    className={`p-4 border-2 rounded-lg text-left transition-colors ${
                      selectedScenario === key
                        ? 'border-blue-500 bg-blue-50 text-blue-900'
                        : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <IconComponent size={20} className={selectedScenario === key ? 'text-blue-600' : 'text-gray-600'} />
                    </div>
                    <div className="font-medium text-sm">
                      {language === 'ru' ? scenario.nameRu : scenario.name}
                    </div>
                    <div className="text-xs text-gray-600 mt-1">
                      {language === 'ru' ? scenario.descriptionRu : scenario.description}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Advanced Settings */}
          {showAdvancedSettings && (
            <div className="mb-6 p-4 bg-gray-50 rounded-lg">
              <h3 className="text-md font-medium text-gray-900 mb-4">{t.geneticParameters}</h3>
              <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">{t.populationSize}</label>
                  <input
                    type="number"
                    min="50"
                    max="200"
                    value={geneticParams.populationSize}
                    onChange={(e) => setGeneticParams({...geneticParams, populationSize: parseInt(e.target.value) || 100})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">{t.generations}</label>
                  <input
                    type="number"
                    min="20"
                    max="100"
                    value={geneticParams.generations}
                    onChange={(e) => setGeneticParams({...geneticParams, generations: parseInt(e.target.value) || 50})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">{t.crossoverRate}</label>
                  <input
                    type="number"
                    min="0.1"
                    max="1.0"
                    step="0.1"
                    value={geneticParams.crossoverRate}
                    onChange={(e) => setGeneticParams({...geneticParams, crossoverRate: parseFloat(e.target.value) || 0.8})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">{t.mutationRate}</label>
                  <input
                    type="number"
                    min="0.01"
                    max="0.5"
                    step="0.01"
                    value={geneticParams.mutationRate}
                    onChange={(e) => setGeneticParams({...geneticParams, mutationRate: parseFloat(e.target.value) || 0.1})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">{t.elitePreservation}</label>
                  <input
                    type="number"
                    min="5"
                    max="25"
                    value={geneticParams.elitePreservation}
                    onChange={(e) => setGeneticParams({...geneticParams, elitePreservation: parseInt(e.target.value) || 10})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Control Buttons */}
          <div className="flex items-center space-x-3">
            {!optimizing ? (
              <button
                onClick={startOptimization}
                className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Play size={16} />
                {t.startOptimization}
              </button>
            ) : (
              <div className="flex items-center space-x-3">
                {paused ? (
                  <button
                    onClick={resumeOptimization}
                    className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                  >
                    <Play size={16} />
                    {t.resumeOptimization}
                  </button>
                ) : (
                  <button
                    onClick={pauseOptimization}
                    className="flex items-center gap-2 px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700"
                  >
                    <Pause size={16} />
                    {t.pauseOptimization}
                  </button>
                )}
                <button
                  onClick={stopOptimization}
                  className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                >
                  <Square size={16} />
                  {t.stopOptimization}
                </button>
              </div>
            )}
            
            <div className="flex items-center space-x-2">
              <button className="flex items-center gap-2 px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Save size={16} />
                Save Configuration
              </button>
              <button className="flex items-center gap-2 px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Download size={16} />
                Export Results
              </button>
            </div>
          </div>
        </div>

        {/* Optimization Results */}
        {results && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Progress Panel */}
            <div className="lg:col-span-2 space-y-6">
              {/* Progress Status */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-medium text-gray-900">{t.progress}</h3>
                  <div className="flex items-center space-x-2">
                    <Activity className={`h-5 w-5 ${optimizing && !paused ? 'text-blue-600 animate-pulse' : 'text-gray-400'}`} />
                    <span className={`text-sm font-medium ${
                      results.status === 'running' ? 'text-blue-600' :
                      results.status === 'completed' ? 'text-green-600' :
                      results.status === 'paused' ? 'text-yellow-600' :
                      'text-red-600'
                    }`}>
                      {results.status === 'running' && t.optimizationRunning}
                      {results.status === 'paused' && t.optimizationPaused}
                      {results.status === 'completed' && t.optimizationCompleted}
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                  <div className="text-center">
                    <div className="text-2xl font-bold text-blue-600">{results.progress.generation}</div>
                    <div className="text-sm text-gray-600">{t.generation}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-green-600">{results.progress.bestFitness.toFixed(1)}</div>
                    <div className="text-sm text-gray-600">{t.bestFitness}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-gray-600">{results.progress.averageFitness.toFixed(1)}</div>
                    <div className="text-sm text-gray-600">{t.averageFitness}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-purple-600">{results.progress.convergence.toFixed(1)}%</div>
                    <div className="text-sm text-gray-600">{t.convergence}</div>
                  </div>
                </div>

                <div className="w-full bg-gray-200 rounded-full h-3 mb-4">
                  <div 
                    className="bg-blue-600 h-3 rounded-full transition-all duration-1000" 
                    style={{width: `${results.progress.convergence}%`}}
                  ></div>
                </div>

                <div className="flex justify-between text-sm text-gray-600">
                  <span>{t.timeElapsed}: {formatTime(results.progress.timeElapsed)}</span>
                  <span>{t.estimatedRemaining}: {formatTime(Math.round(results.progress.estimatedRemaining))}</span>
                </div>
              </div>

              {/* Objectives */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">{t.objectives}</h3>
                <div className="space-y-4">
                  {results.objectives.map((objective) => (
                    <div key={objective.id} className="border border-gray-200 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <div>
                          <h4 className="font-medium text-gray-900">
                            {language === 'ru' ? objective.nameRu : objective.name}
                          </h4>
                          <div className="text-sm text-gray-600">Weight: {(objective.weight * 100).toFixed(0)}%</div>
                        </div>
                        <div className="text-right">
                          <div className={`flex items-center gap-1 text-sm font-medium ${
                            objective.improvement > 0 ? 'text-green-600' : 'text-red-600'
                          }`}>
                            {objective.improvement > 0 ? (
                              <TrendingUp size={14} />
                            ) : (
                              <TrendingDown size={14} />
                            )}
                            {objective.improvement > 0 ? '+' : ''}{objective.improvement.toFixed(1)}%
                          </div>
                        </div>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span>Current: {objective.current.toLocaleString()}{objective.unit}</span>
                        <span>Target: {objective.target.toLocaleString()}{objective.unit}</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                        <div 
                          className={`h-2 rounded-full ${objective.improvement > 0 ? 'bg-green-500' : 'bg-red-500'}`}
                          style={{
                            width: `${Math.min(100, Math.abs(objective.improvement) * 5)}%`
                          }}
                        ></div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Side Panel */}
            <div className="space-y-6">
              {/* Constraints */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">{t.constraints}</h3>
                <div className="space-y-3">
                  {results.constraints.map((constraint) => (
                    <div key={constraint.id} className={`border-2 rounded-lg p-3 ${getConstraintColor(constraint.status)}`}>
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-2">
                          {getConstraintIcon(constraint.status)}
                          <span className="font-medium text-sm">
                            {language === 'ru' ? constraint.nameRu : constraint.name}
                          </span>
                        </div>
                        <span className={`text-xs px-2 py-1 rounded ${
                          constraint.severity === 'high' ? 'bg-red-100 text-red-800' :
                          constraint.severity === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-blue-100 text-blue-800'
                        }`}>
                          {t[constraint.severity as keyof typeof t]}
                        </span>
                      </div>
                      <div className="text-xs text-gray-600">
                        {constraint.current} / {constraint.limit}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Recommendations */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">{t.recommendations}</h3>
                <div className="space-y-3">
                  {results.recommendations.map((rec, index) => (
                    <div key={index} className="border border-gray-200 rounded-lg p-3">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-medium text-blue-600 uppercase">{rec.category}</span>
                        <div className="flex items-center gap-2">
                          <span className={`text-xs px-2 py-1 rounded ${
                            rec.priority === 'high' ? 'bg-red-100 text-red-800' :
                            rec.priority === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-green-100 text-green-800'
                          }`}>
                            {t[rec.priority as keyof typeof t]}
                          </span>
                          <span className={`text-xs px-2 py-1 rounded ${
                            rec.effort === 'high' ? 'bg-red-100 text-red-800' :
                            rec.effort === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-green-100 text-green-800'
                          }`}>
                            {t[rec.effort as keyof typeof t]}
                          </span>
                        </div>
                      </div>
                      <p className="text-sm text-gray-900 mb-1">{rec.suggestion}</p>
                      <p className="text-xs text-green-600 font-medium">{rec.impact}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Initial State */}
        {!results && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <BarChart3 className="h-16 w-16 mx-auto mb-4 text-gray-400" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {language === 'ru' ? 'Готов к оптимизации' : 'Ready for Optimization'}
            </h3>
            <p className="text-gray-600 mb-6">
              {language === 'ru' ? 
                'Настройте параметры и выберите сценарий оптимизации для начала работы генетического алгоритма' :
                'Configure parameters and select optimization scenario to start genetic algorithm processing'
              }
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div className="text-center">
                <Users className="h-8 w-8 mx-auto mb-2 text-blue-600" />
                <div className="font-medium">Population: {geneticParams.populationSize}</div>
              </div>
              <div className="text-center">
                <Target className="h-8 w-8 mx-auto mb-2 text-green-600" />
                <div className="font-medium">Generations: {geneticParams.generations}</div>
              </div>
              <div className="text-center">
                <Activity className="h-8 w-8 mx-auto mb-2 text-purple-600" />
                <div className="font-medium">Crossover: {(geneticParams.crossoverRate * 100).toFixed(0)}%</div>
              </div>
              <div className="text-center">
                <Zap className="h-8 w-8 mx-auto mb-2 text-orange-600" />
                <div className="font-medium">Mutation: {(geneticParams.mutationRate * 100).toFixed(0)}%</div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec26AutomaticScheduleOptimization;