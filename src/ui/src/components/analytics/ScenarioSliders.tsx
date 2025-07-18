import React, { useState, useEffect } from 'react';
import { Sliders, Play, RotateCcw, Save, TrendingUp, Users, Clock, Target } from 'lucide-react';

interface ScenarioSlidersProps {
  onScenarioChange?: (scenario: ScenarioParameters) => void;
  initialScenario?: ScenarioParameters;
  readOnly?: boolean;
}

interface ScenarioParameters {
  callVolumeMultiplier: number;
  ahtMultiplier: number;
  staffingLevel: number;
  serviceLevel: number;
  skillMix: {
    basic: number;
    advanced: number;
    expert: number;
  };
  timeDistribution: {
    morning: number;
    afternoon: number;
    evening: number;
  };
  seasonalityFactor: number;
  attritionRate: number;
}

interface ScenarioResult {
  id: string;
  name: string;
  parameters: ScenarioParameters;
  results: {
    predictedVolume: number;
    requiredStaff: number;
    expectedServiceLevel: number;
    costImpact: number;
    riskLevel: 'low' | 'medium' | 'high';
  };
  createdAt: Date;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations
const translations = {
  title: 'Сценарии "Что если"',
  subtitle: 'Моделирование различных условий работы',
  parameters: {
    callVolumeMultiplier: 'Множитель объема звонков',
    ahtMultiplier: 'Множитель времени обработки',
    staffingLevel: 'Уровень штатного расписания',
    serviceLevel: 'Целевой уровень сервиса',
    skillMix: 'Распределение навыков',
    timeDistribution: 'Распределение времени',
    seasonalityFactor: 'Сезонный фактор',
    attritionRate: 'Уровень текучести кадров'
  },
  skillLevels: {
    basic: 'Базовые навыки',
    advanced: 'Продвинутые навыки',
    expert: 'Экспертные навыки'
  },
  timePeriods: {
    morning: 'Утро (8-16)',
    afternoon: 'День (16-24)',
    evening: 'Вечер (0-8)'
  },
  results: {
    predictedVolume: 'Прогнозируемый объем',
    requiredStaff: 'Требуемый персонал',
    expectedServiceLevel: 'Ожидаемый уровень сервиса',
    costImpact: 'Влияние на затраты',
    riskLevel: 'Уровень риска'
  },
  riskLevels: {
    low: 'Низкий',
    medium: 'Средний',
    high: 'Высокий'
  },
  actions: {
    runScenario: 'Запустить сценарий',
    saveScenario: 'Сохранить сценарий',
    resetToDefault: 'Сбросить к умолчанию',
    loadPreset: 'Загрузить шаблон',
    compareScenarios: 'Сравнить сценарии'
  },
  presets: {
    current: 'Текущие условия',
    peakSeason: 'Пиковый сезон',
    lowSeason: 'Низкий сезон',
    staffReduction: 'Сокращение штата',
    serviceImprovement: 'Улучшение сервиса',
    costOptimization: 'Оптимизация затрат'
  },
  validation: {
    invalidParameters: 'Некорректные параметры',
    totalMustBe100: 'Общая сумма должна быть 100%',
    valueTooHigh: 'Значение слишком высокое',
    valueTooLow: 'Значение слишком низкое'
  }
};

const ScenarioSliders: React.FC<ScenarioSlidersProps> = ({
  onScenarioChange,
  initialScenario,
  readOnly = false
}) => {
  const [scenario, setScenario] = useState<ScenarioParameters>(initialScenario || {
    callVolumeMultiplier: 1.0,
    ahtMultiplier: 1.0,
    staffingLevel: 100,
    serviceLevel: 80,
    skillMix: { basic: 60, advanced: 30, expert: 10 },
    timeDistribution: { morning: 40, afternoon: 35, evening: 25 },
    seasonalityFactor: 1.0,
    attritionRate: 15
  });

  const [results, setResults] = useState<ScenarioResult['results'] | null>(null);
  const [isRunning, setIsRunning] = useState(false);
  const [savedScenarios, setSavedScenarios] = useState<ScenarioResult[]>([]);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (onScenarioChange) {
      onScenarioChange(scenario);
    }
  }, [scenario, onScenarioChange]);

  useEffect(() => {
    loadSavedScenarios();
  }, []);

  const loadSavedScenarios = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/forecasts/scenarios/saved`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setSavedScenarios(data.scenarios || []);
      }
    } catch (error) {
      console.error('Error loading saved scenarios:', error);
    }
  };

  const validateScenario = (): boolean => {
    const newErrors: Record<string, string> = {};

    // Validate skill mix totals 100%
    const skillTotal = scenario.skillMix.basic + scenario.skillMix.advanced + scenario.skillMix.expert;
    if (Math.abs(skillTotal - 100) > 0.1) {
      newErrors.skillMix = translations.validation.totalMustBe100;
    }

    // Validate time distribution totals 100%
    const timeTotal = scenario.timeDistribution.morning + scenario.timeDistribution.afternoon + scenario.timeDistribution.evening;
    if (Math.abs(timeTotal - 100) > 0.1) {
      newErrors.timeDistribution = translations.validation.totalMustBe100;
    }

    // Validate ranges
    if (scenario.callVolumeMultiplier < 0.1 || scenario.callVolumeMultiplier > 5.0) {
      newErrors.callVolumeMultiplier = translations.validation.valueTooHigh;
    }

    if (scenario.serviceLevel < 10 || scenario.serviceLevel > 100) {
      newErrors.serviceLevel = translations.validation.valueTooHigh;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const runScenario = async () => {
    if (!validateScenario()) return;

    setIsRunning(true);
    try {
      const response = await fetch(`${API_BASE_URL}/forecasts/scenarios`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          parameters: scenario,
          run_simulation: true
        })
      });

      if (response.ok) {
        const data = await response.json();
        setResults(data.results);
      }
    } catch (error) {
      console.error('Error running scenario:', error);
    } finally {
      setIsRunning(false);
    }
  };

  const saveScenario = async () => {
    if (!validateScenario()) return;

    const scenarioName = prompt('Введите название сценария:');
    if (!scenarioName) return;

    try {
      const response = await fetch(`${API_BASE_URL}/forecasts/scenarios/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          name: scenarioName,
          parameters: scenario
        })
      });

      if (response.ok) {
        await loadSavedScenarios();
      }
    } catch (error) {
      console.error('Error saving scenario:', error);
    }
  };

  const resetToDefault = () => {
    setScenario({
      callVolumeMultiplier: 1.0,
      ahtMultiplier: 1.0,
      staffingLevel: 100,
      serviceLevel: 80,
      skillMix: { basic: 60, advanced: 30, expert: 10 },
      timeDistribution: { morning: 40, afternoon: 35, evening: 25 },
      seasonalityFactor: 1.0,
      attritionRate: 15
    });
    setResults(null);
    setErrors({});
  };

  const loadPreset = (presetName: string) => {
    const presets: Record<string, Partial<ScenarioParameters>> = {
      current: {},
      peakSeason: {
        callVolumeMultiplier: 1.3,
        seasonalityFactor: 1.25,
        staffingLevel: 120
      },
      lowSeason: {
        callVolumeMultiplier: 0.7,
        seasonalityFactor: 0.85,
        staffingLevel: 80
      },
      staffReduction: {
        staffingLevel: 85,
        attritionRate: 20,
        serviceLevel: 75
      },
      serviceImprovement: {
        serviceLevel: 95,
        ahtMultiplier: 0.9,
        skillMix: { basic: 40, advanced: 40, expert: 20 }
      },
      costOptimization: {
        staffingLevel: 90,
        skillMix: { basic: 70, advanced: 25, expert: 5 },
        attritionRate: 12
      }
    };

    const preset = presets[presetName];
    if (preset) {
      setScenario(prev => ({ ...prev, ...preset }));
      setResults(null);
      setErrors({});
    }
  };

  const updateScenario = (field: keyof ScenarioParameters, value: any) => {
    if (readOnly) return;

    setScenario(prev => ({ ...prev, [field]: value }));
    setResults(null);
    
    // Clear specific field error
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const updateSkillMix = (skill: keyof ScenarioParameters['skillMix'], value: number) => {
    updateScenario('skillMix', { ...scenario.skillMix, [skill]: value });
  };

  const updateTimeDistribution = (time: keyof ScenarioParameters['timeDistribution'], value: number) => {
    updateScenario('timeDistribution', { ...scenario.timeDistribution, [time]: value });
  };

  const getRiskColor = (level: string) => {
    switch (level) {
      case 'low': return 'text-green-600 bg-green-100';
      case 'medium': return 'text-yellow-600 bg-yellow-100';
      case 'high': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const renderSlider = (
    label: string,
    value: number,
    min: number,
    max: number,
    step: number,
    onChange: (value: number) => void,
    suffix: string = '',
    error?: string
  ) => (
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <label className="text-sm font-medium text-gray-700">{label}</label>
        <span className="text-sm text-gray-900 font-medium">{value}{suffix}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
        disabled={readOnly}
        className={`w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer ${
          readOnly ? 'opacity-50' : 'hover:bg-gray-300'
        }`}
      />
      {error && (
        <p className="text-xs text-red-600">{error}</p>
      )}
    </div>
  );

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200" data-testid="scenario-sliders">
      {/* Header */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Sliders className="h-6 w-6 text-blue-600" />
            <div>
              <h3 className="text-lg font-semibold text-gray-900">{translations.title}</h3>
              <p className="text-sm text-gray-600">{translations.subtitle}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <select
              onChange={(e) => loadPreset(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              disabled={readOnly}
            >
              <option value="">{translations.actions.loadPreset}</option>
              {Object.entries(translations.presets).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>
            
            {!readOnly && (
              <>
                <button
                  onClick={saveScenario}
                  className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                  title={translations.actions.saveScenario}
                >
                  <Save className="h-5 w-5" />
                </button>
                
                <button
                  onClick={resetToDefault}
                  className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                  title={translations.actions.resetToDefault}
                >
                  <RotateCcw className="h-5 w-5" />
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      <div className="p-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Parameter Controls */}
          <div className="space-y-6">
            <h4 className="text-md font-semibold text-gray-900">Параметры сценария</h4>
            
            {/* Basic Parameters */}
            <div className="space-y-4">
              {renderSlider(
                translations.parameters.callVolumeMultiplier,
                scenario.callVolumeMultiplier,
                0.1,
                5.0,
                0.1,
                (value) => updateScenario('callVolumeMultiplier', value),
                'x',
                errors.callVolumeMultiplier
              )}

              {renderSlider(
                translations.parameters.ahtMultiplier,
                scenario.ahtMultiplier,
                0.5,
                2.0,
                0.05,
                (value) => updateScenario('ahtMultiplier', value),
                'x',
                errors.ahtMultiplier
              )}

              {renderSlider(
                translations.parameters.staffingLevel,
                scenario.staffingLevel,
                50,
                200,
                5,
                (value) => updateScenario('staffingLevel', value),
                '%',
                errors.staffingLevel
              )}

              {renderSlider(
                translations.parameters.serviceLevel,
                scenario.serviceLevel,
                50,
                100,
                1,
                (value) => updateScenario('serviceLevel', value),
                '%',
                errors.serviceLevel
              )}

              {renderSlider(
                translations.parameters.seasonalityFactor,
                scenario.seasonalityFactor,
                0.5,
                2.0,
                0.05,
                (value) => updateScenario('seasonalityFactor', value),
                'x',
                errors.seasonalityFactor
              )}

              {renderSlider(
                translations.parameters.attritionRate,
                scenario.attritionRate,
                0,
                50,
                1,
                (value) => updateScenario('attritionRate', value),
                '%',
                errors.attritionRate
              )}
            </div>

            {/* Skill Mix */}
            <div className="space-y-4">
              <h5 className="text-sm font-semibold text-gray-900">{translations.parameters.skillMix}</h5>
              
              {renderSlider(
                translations.skillLevels.basic,
                scenario.skillMix.basic,
                0,
                100,
                5,
                (value) => updateSkillMix('basic', value),
                '%'
              )}

              {renderSlider(
                translations.skillLevels.advanced,
                scenario.skillMix.advanced,
                0,
                100,
                5,
                (value) => updateSkillMix('advanced', value),
                '%'
              )}

              {renderSlider(
                translations.skillLevels.expert,
                scenario.skillMix.expert,
                0,
                100,
                5,
                (value) => updateSkillMix('expert', value),
                '%'
              )}

              {errors.skillMix && (
                <p className="text-xs text-red-600">{errors.skillMix}</p>
              )}
            </div>

            {/* Time Distribution */}
            <div className="space-y-4">
              <h5 className="text-sm font-semibold text-gray-900">{translations.parameters.timeDistribution}</h5>
              
              {renderSlider(
                translations.timePeriods.morning,
                scenario.timeDistribution.morning,
                0,
                100,
                5,
                (value) => updateTimeDistribution('morning', value),
                '%'
              )}

              {renderSlider(
                translations.timePeriods.afternoon,
                scenario.timeDistribution.afternoon,
                0,
                100,
                5,
                (value) => updateTimeDistribution('afternoon', value),
                '%'
              )}

              {renderSlider(
                translations.timePeriods.evening,
                scenario.timeDistribution.evening,
                0,
                100,
                5,
                (value) => updateTimeDistribution('evening', value),
                '%'
              )}

              {errors.timeDistribution && (
                <p className="text-xs text-red-600">{errors.timeDistribution}</p>
              )}
            </div>
          </div>

          {/* Results */}
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h4 className="text-md font-semibold text-gray-900">Результаты сценария</h4>
              
              {!readOnly && (
                <button
                  onClick={runScenario}
                  disabled={isRunning}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center gap-2"
                >
                  <Play className="h-4 w-4" />
                  {isRunning ? 'Выполнение...' : translations.actions.runScenario}
                </button>
              )}
            </div>

            {results ? (
              <div className="space-y-4">
                <div className="bg-blue-50 rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingUp className="h-5 w-5 text-blue-600" />
                    <span className="text-sm font-medium text-blue-900">
                      {translations.results.predictedVolume}
                    </span>
                  </div>
                  <div className="text-2xl font-bold text-blue-900">
                    {results.predictedVolume.toLocaleString('ru-RU')}
                  </div>
                </div>

                <div className="bg-green-50 rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Users className="h-5 w-5 text-green-600" />
                    <span className="text-sm font-medium text-green-900">
                      {translations.results.requiredStaff}
                    </span>
                  </div>
                  <div className="text-2xl font-bold text-green-900">
                    {results.requiredStaff}
                  </div>
                </div>

                <div className="bg-purple-50 rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Target className="h-5 w-5 text-purple-600" />
                    <span className="text-sm font-medium text-purple-900">
                      {translations.results.expectedServiceLevel}
                    </span>
                  </div>
                  <div className="text-2xl font-bold text-purple-900">
                    {results.expectedServiceLevel}%
                  </div>
                </div>

                <div className="bg-orange-50 rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Clock className="h-5 w-5 text-orange-600" />
                    <span className="text-sm font-medium text-orange-900">
                      {translations.results.costImpact}
                    </span>
                  </div>
                  <div className="text-2xl font-bold text-orange-900">
                    {results.costImpact > 0 ? '+' : ''}{results.costImpact}%
                  </div>
                </div>

                <div className="bg-gray-50 rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-sm font-medium text-gray-900">
                      {translations.results.riskLevel}
                    </span>
                  </div>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getRiskColor(results.riskLevel)}`}>
                    {translations.riskLevels[results.riskLevel as keyof typeof translations.riskLevels]}
                  </span>
                </div>
              </div>
            ) : (
              <div className="text-center py-12 text-gray-500">
                <Play className="h-12 w-12 mx-auto mb-4 text-gray-400" />
                <p>Запустите сценарий для просмотра результатов</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ScenarioSliders;