import React, { useState, useEffect } from 'react';
import { Wrench, AlertTriangle, Clock, TrendingUp, Download, RefreshCw, Settings, Play } from 'lucide-react';

interface MaintenanceEvent {
  id: string;
  assetId: string;
  assetName: string;
  assetType: 'server' | 'network' | 'phone_system' | 'software' | 'workstation';
  eventType: 'scheduled' | 'predictive' | 'emergency' | 'routine';
  predictionDate: Date;
  actualDate?: Date;
  severity: 'low' | 'medium' | 'high' | 'critical';
  estimatedDuration: number; // hours
  impactAssessment: {
    affectedAgents: number;
    serviceInterruption: boolean;
    costEstimate: number;
    businessImpact: 'minimal' | 'moderate' | 'significant' | 'severe';
  };
  maintenance: {
    description: string;
    requiredSkills: string[];
    estimatedCost: number;
    vendor?: string;
  };
  prediction: {
    confidence: number;
    algorithm: string;
    riskLevel: number;
    indicators: string[];
  };
}

interface AssetHealth {
  assetId: string;
  assetName: string;
  assetType: string;
  healthScore: number;
  failureProbability: number;
  nextMaintenanceDate: Date;
  status: 'healthy' | 'warning' | 'critical' | 'offline';
  metrics: {
    uptime: number;
    performance: number;
    errorRate: number;
    lastIncident?: Date;
  };
  trends: {
    uptimeTrend: 'improving' | 'stable' | 'declining';
    performanceTrend: 'improving' | 'stable' | 'declining';
    errorTrend: 'improving' | 'stable' | 'declining';
  };
}

interface PredictionModel {
  id: string;
  name: string;
  description: string;
  algorithm: 'ml_regression' | 'survival_analysis' | 'time_series' | 'ensemble';
  accuracy: number;
  lastTrained: Date;
  features: string[];
  enabled: boolean;
}

interface MaintenanceSchedule {
  date: string;
  events: Array<{
    assetName: string;
    eventType: MaintenanceEvent['eventType'];
    severity: MaintenanceEvent['severity'];
    duration: number;
    affectedAgents: number;
  }>;
  totalDowntime: number;
  totalCost: number;
  riskLevel: 'low' | 'medium' | 'high';
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const PredictiveMaintenanceForecaster: React.FC = () => {
  const [maintenanceEvents, setMaintenanceEvents] = useState<MaintenanceEvent[]>([]);
  const [assetHealth, setAssetHealth] = useState<AssetHealth[]>([]);
  const [predictionModels, setPredictionModels] = useState<PredictionModel[]>([]);
  const [maintenanceSchedule, setMaintenanceSchedule] = useState<MaintenanceSchedule[]>([]);
  const [selectedAssetType, setSelectedAssetType] = useState<string>('all');
  const [predictionHorizon, setPredictionHorizon] = useState('30days');
  const [selectedModel, setSelectedModel] = useState<string>('ensemble');
  const [isRunning, setIsRunning] = useState(false);
  const [analysisProgress, setAnalysisProgress] = useState(0);
  const [showSettings, setShowSettings] = useState(false);

  const loadMaintenanceData = async () => {
    try {
      console.log('[PREDICTIVE MAINTENANCE] Loading predictive maintenance data...');

      // Load maintenance events
      const eventsResponse = await fetch(`${API_BASE_URL}/maintenance/events?asset_type=${selectedAssetType}&horizon=${predictionHorizon}`);
      if (!eventsResponse.ok) {
        throw new Error(`Events API failed: ${eventsResponse.status}`);
      }

      const eventsData = await eventsResponse.json();
      const realEvents = (eventsData.events || []).map((event: any) => ({
        id: event.id || `event_${Date.now()}`,
        assetId: event.asset_id || event.assetId,
        assetName: event.asset_name || event.assetName,
        assetType: event.asset_type || event.assetType || 'server',
        eventType: event.event_type || event.eventType || 'scheduled',
        predictionDate: new Date(event.prediction_date || event.predictionDate || Date.now()),
        actualDate: event.actual_date ? new Date(event.actual_date) : undefined,
        severity: event.severity || 'medium',
        estimatedDuration: event.estimated_duration || event.estimatedDuration || 4,
        impactAssessment: event.impact_assessment || event.impactAssessment || {},
        maintenance: event.maintenance || {},
        prediction: event.prediction || {}
      }));

      setMaintenanceEvents(realEvents);

      // Load asset health
      const healthResponse = await fetch(`${API_BASE_URL}/maintenance/asset-health?asset_type=${selectedAssetType}`);
      if (healthResponse.ok) {
        const healthData = await healthResponse.json();
        setAssetHealth(healthData.assets || []);
      }

      // Load prediction models
      const modelsResponse = await fetch(`${API_BASE_URL}/maintenance/models`);
      if (modelsResponse.ok) {
        const modelsData = await modelsResponse.json();
        setPredictionModels(modelsData.models || []);
      }

      // Load maintenance schedule
      const scheduleResponse = await fetch(`${API_BASE_URL}/maintenance/schedule?horizon=${predictionHorizon}`);
      if (scheduleResponse.ok) {
        const scheduleData = await scheduleResponse.json();
        setMaintenanceSchedule(scheduleData.schedule || []);
      }

      console.log(`[PREDICTIVE MAINTENANCE] Loaded ${realEvents.length} maintenance events`);

    } catch (error) {
      console.error('[PREDICTIVE MAINTENANCE] Error loading data:', error);

      // Fallback data for demo
      const fallbackEvents: MaintenanceEvent[] = [
        {
          id: 'maint-001',
          assetId: 'server-01',
          assetName: 'Основной сервер обработки звонков',
          assetType: 'server',
          eventType: 'predictive',
          predictionDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          severity: 'high',
          estimatedDuration: 6,
          impactAssessment: {
            affectedAgents: 45,
            serviceInterruption: true,
            costEstimate: 350000,
            businessImpact: 'significant'
          },
          maintenance: {
            description: 'Замена жестких дисков в RAID-массиве перед предсказанным отказом',
            requiredSkills: ['Системное администрирование', 'Работа с RAID'],
            estimatedCost: 180000,
            vendor: 'Dell Technologies'
          },
          prediction: {
            confidence: 0.87,
            algorithm: 'ensemble',
            riskLevel: 0.92,
            indicators: ['Увеличение числа ошибок диска', 'Рост температуры', 'Снижение скорости записи']
          }
        },
        {
          id: 'maint-002',
          assetId: 'phone-sys-01',
          assetName: 'IP-телефонная система',
          assetType: 'phone_system',
          eventType: 'scheduled',
          predictionDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
          severity: 'medium',
          estimatedDuration: 4,
          impactAssessment: {
            affectedAgents: 80,
            serviceInterruption: false,
            costEstimate: 120000,
            businessImpact: 'moderate'
          },
          maintenance: {
            description: 'Плановое обновление прошивки и конфигурации',
            requiredSkills: ['IP-телефония', 'Сетевое администрирование'],
            estimatedCost: 45000,
            vendor: 'Cisco Systems'
          },
          prediction: {
            confidence: 0.95,
            algorithm: 'time_series',
            riskLevel: 0.35,
            indicators: ['Плановый цикл обновлений', 'Уязвимости безопасности']
          }
        },
        {
          id: 'maint-003',
          assetId: 'network-sw-01',
          assetName: 'Коммутатор ядра сети',
          assetType: 'network',
          eventType: 'predictive',
          predictionDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
          severity: 'critical',
          estimatedDuration: 8,
          impactAssessment: {
            affectedAgents: 120,
            serviceInterruption: true,
            costEstimate: 850000,
            businessImpact: 'severe'
          },
          maintenance: {
            description: 'Замена коммутатора из-за критического износа портов',
            requiredSkills: ['Сетевое администрирование', 'Высоковольтные работы'],
            estimatedCost: 650000,
            vendor: 'Juniper Networks'
          },
          prediction: {
            confidence: 0.78,
            algorithm: 'ml_regression',
            riskLevel: 0.95,
            indicators: ['Рост числа CRC-ошибок', 'Перегрев портов', 'Нестабильная работа']
          }
        }
      ];

      const fallbackHealth: AssetHealth[] = [
        {
          assetId: 'server-01',
          assetName: 'Основной сервер обработки звонков',
          assetType: 'server',
          healthScore: 65,
          failureProbability: 0.35,
          nextMaintenanceDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          status: 'warning',
          metrics: {
            uptime: 97.2,
            performance: 82,
            errorRate: 0.08,
            lastIncident: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000)
          },
          trends: {
            uptimeTrend: 'declining',
            performanceTrend: 'declining',
            errorTrend: 'declining'
          }
        },
        {
          assetId: 'phone-sys-01',
          assetName: 'IP-телефонная система',
          assetType: 'phone_system',
          healthScore: 88,
          failureProbability: 0.12,
          nextMaintenanceDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
          status: 'healthy',
          metrics: {
            uptime: 99.1,
            performance: 94,
            errorRate: 0.02
          },
          trends: {
            uptimeTrend: 'stable',
            performanceTrend: 'improving',
            errorTrend: 'improving'
          }
        },
        {
          assetId: 'network-sw-01',
          assetName: 'Коммутатор ядра сети',
          assetType: 'network',
          healthScore: 45,
          failureProbability: 0.55,
          nextMaintenanceDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
          status: 'critical',
          metrics: {
            uptime: 94.8,
            performance: 68,
            errorRate: 0.15,
            lastIncident: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
          },
          trends: {
            uptimeTrend: 'declining',
            performanceTrend: 'declining',
            errorTrend: 'declining'
          }
        }
      ];

      const fallbackModels: PredictionModel[] = [
        {
          id: 'ensemble-model',
          name: 'Ансамбль моделей',
          description: 'Комбинированная модель с регрессией, временными рядами и анализом выживаемости',
          algorithm: 'ensemble',
          accuracy: 0.89,
          lastTrained: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
          features: ['uptime', 'error_rate', 'performance', 'temperature', 'age'],
          enabled: true
        },
        {
          id: 'ml-regression',
          name: 'ML Регрессия',
          description: 'Машинное обучение на основе исторических данных отказов',
          algorithm: 'ml_regression',
          accuracy: 0.82,
          lastTrained: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
          features: ['usage_pattern', 'error_frequency', 'load_average'],
          enabled: true
        },
        {
          id: 'time-series',
          name: 'Временные ряды',
          description: 'Прогнозирование на основе временных паттернов',
          algorithm: 'time_series',
          accuracy: 0.76,
          lastTrained: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
          features: ['seasonal_patterns', 'trend_analysis', 'cyclical_behavior'],
          enabled: true
        }
      ];

      const fallbackSchedule: MaintenanceSchedule[] = Array.from({ length: 30 }, (_, i) => {
        const date = new Date(Date.now() + i * 24 * 60 * 60 * 1000);
        const eventCount = Math.floor(Math.random() * 3);
        
        return {
          date: date.toISOString().split('T')[0],
          events: Array.from({ length: eventCount }, (_, j) => ({
            assetName: `Актив ${j + 1}`,
            eventType: (['scheduled', 'predictive', 'routine'] as const)[Math.floor(Math.random() * 3)],
            severity: (['low', 'medium', 'high'] as const)[Math.floor(Math.random() * 3)],
            duration: 2 + Math.floor(Math.random() * 6),
            affectedAgents: 10 + Math.floor(Math.random() * 50)
          })),
          totalDowntime: eventCount * (2 + Math.floor(Math.random() * 4)),
          totalCost: eventCount * (50000 + Math.floor(Math.random() * 200000)),
          riskLevel: eventCount > 1 ? 'high' : eventCount > 0 ? 'medium' : 'low'
        };
      });

      setMaintenanceEvents(fallbackEvents);
      setAssetHealth(fallbackHealth);
      setPredictionModels(fallbackModels);
      setMaintenanceSchedule(fallbackSchedule);
    }
  };

  useEffect(() => {
    loadMaintenanceData();
  }, [selectedAssetType, predictionHorizon, selectedModel]);

  const runPredictiveAnalysis = async () => {
    setIsRunning(true);
    setAnalysisProgress(0);

    try {
      // Simulate analysis progress
      const progressInterval = setInterval(() => {
        setAnalysisProgress(prev => {
          if (prev >= 100) {
            clearInterval(progressInterval);
            return 100;
          }
          return prev + Math.random() * 15;
        });
      }, 300);

      const response = await fetch(`${API_BASE_URL}/maintenance/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          asset_type: selectedAssetType,
          horizon: predictionHorizon,
          model: selectedModel
        })
      });

      if (response.ok) {
        const result = await response.json();
        setMaintenanceEvents(result.events || []);
        setAssetHealth(result.health || []);
        setMaintenanceSchedule(result.schedule || []);
      }

      // Clear progress after completion
      setTimeout(() => {
        clearInterval(progressInterval);
        setAnalysisProgress(100);
        setTimeout(() => setAnalysisProgress(0), 1000);
      }, 2000);

    } catch (error) {
      console.error('Failed to run predictive analysis:', error);
      // Reload fallback data
      await loadMaintenanceData();
    } finally {
      setTimeout(() => setIsRunning(false), 2000);
    }
  };

  const exportMaintenancePlan = () => {
    const exportData = {
      events: maintenanceEvents,
      assetHealth,
      schedule: maintenanceSchedule,
      models: predictionModels,
      parameters: {
        assetType: selectedAssetType,
        horizon: predictionHorizon,
        model: selectedModel
      },
      timestamp: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `maintenance-plan-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getAssetTypeIcon = (type: AssetHealth['assetType']) => {
    switch (type) {
      case 'server':
        return '🖥️';
      case 'network':
        return '🌐';
      case 'phone_system':
        return '📞';
      case 'software':
        return '💻';
      case 'workstation':
        return '🖱️';
      default:
        return '⚙️';
    }
  };

  const getHealthStatusColor = (status: AssetHealth['status']) => {
    switch (status) {
      case 'healthy':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'warning':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'offline':
        return 'bg-gray-100 text-gray-800 border-gray-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getSeverityColor = (severity: MaintenanceEvent['severity']) => {
    switch (severity) {
      case 'low':
        return 'text-green-600';
      case 'medium':
        return 'text-yellow-600';
      case 'high':
        return 'text-orange-600';
      case 'critical':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const getTrendIcon = (trend: 'improving' | 'stable' | 'declining') => {
    switch (trend) {
      case 'improving':
        return <TrendingUp className="h-3 w-3 text-green-500" />;
      case 'declining':
        return <TrendingUp className="h-3 w-3 text-red-500 rotate-180" />;
      default:
        return <div className="h-3 w-3 bg-gray-400 rounded-full" />;
    }
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Wrench className="h-6 w-6 mr-2 text-blue-600" />
              Предиктивное Обслуживание
            </h2>
            <p className="mt-2 text-gray-600">
              Прогнозирование технических сбоев и планирование профилактического обслуживания
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowSettings(!showSettings)}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Settings className="h-4 w-4 mr-2" />
              Настройки
            </button>
            <button
              onClick={exportMaintenancePlan}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт плана
            </button>
            <button
              onClick={runPredictiveAnalysis}
              disabled={isRunning}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              {isRunning ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Анализ... {analysisProgress.toFixed(0)}%
                </>
              ) : (
                <>
                  <Play className="h-4 w-4 mr-2" />
                  Запустить анализ
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Analysis Progress */}
      {isRunning && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-700">Предиктивный анализ</span>
            <span className="text-sm text-gray-500">{analysisProgress.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${analysisProgress}%` }}
            ></div>
          </div>
        </div>
      )}

      {/* Settings Panel */}
      {showSettings && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Параметры анализа</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Тип активов
              </label>
              <select
                value={selectedAssetType}
                onChange={(e) => setSelectedAssetType(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Все активы</option>
                <option value="server">Серверы</option>
                <option value="network">Сетевое оборудование</option>
                <option value="phone_system">Телефонные системы</option>
                <option value="software">Программное обеспечение</option>
                <option value="workstation">Рабочие станции</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Горизонт прогнозирования
              </label>
              <select
                value={predictionHorizon}
                onChange={(e) => setPredictionHorizon(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="7days">7 дней</option>
                <option value="30days">30 дней</option>
                <option value="90days">90 дней</option>
                <option value="1year">1 год</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Модель прогнозирования
              </label>
              <select
                value={selectedModel}
                onChange={(e) => setSelectedModel(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {predictionModels.filter(m => m.enabled).map(model => (
                  <option key={model.id} value={model.id}>
                    {model.name} ({(model.accuracy * 100).toFixed(1)}%)
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Asset Health Overview */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Состояние активов</h3>
            </div>
            
            <div className="p-4 space-y-4 max-h-96 overflow-y-auto">
              {assetHealth.map((asset) => (
                <div key={asset.assetId} className={`p-4 border rounded-lg ${getHealthStatusColor(asset.status)}`}>
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <span className="text-lg">{getAssetTypeIcon(asset.assetType)}</span>
                      <span className="text-sm font-medium text-gray-900">{asset.assetName}</span>
                    </div>
                    <span className="text-xs px-2 py-1 bg-gray-100 rounded-full">
                      {asset.status === 'healthy' ? 'Норма' :
                       asset.status === 'warning' ? 'Внимание' :
                       asset.status === 'critical' ? 'Критично' : 'Офлайн'}
                    </span>
                  </div>
                  
                  <div className="mb-3">
                    <div className="flex items-center justify-between text-sm mb-1">
                      <span className="text-gray-600">Состояние здоровья</span>
                      <span className="font-medium">{asset.healthScore}/100</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          asset.healthScore >= 80 ? 'bg-green-500' :
                          asset.healthScore >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                        }`}
                        style={{ width: `${asset.healthScore}%` }}
                      ></div>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-2 text-xs mb-3">
                    <div className="text-center">
                      <div className="font-medium text-gray-900">{asset.metrics.uptime.toFixed(1)}%</div>
                      <div className="text-gray-500 flex items-center justify-center">
                        Uptime {getTrendIcon(asset.trends.uptimeTrend)}
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="font-medium text-gray-900">{asset.metrics.performance}%</div>
                      <div className="text-gray-500 flex items-center justify-center">
                        Производ. {getTrendIcon(asset.trends.performanceTrend)}
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="font-medium text-gray-900">{(asset.failureProbability * 100).toFixed(0)}%</div>
                      <div className="text-gray-500">Риск</div>
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-600">
                    Следующее ТО: {asset.nextMaintenanceDate.toLocaleDateString('ru-RU')}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Maintenance Events & Schedule */}
        <div className="lg:col-span-2 space-y-6">
          {/* Upcoming Events */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Предстоящие события</h3>
            </div>
            
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Актив
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Событие
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Дата
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Влияние
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Уверенность
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {maintenanceEvents.slice(0, 8).map((event) => (
                    <tr key={event.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="text-lg mr-3">{getAssetTypeIcon(event.assetType)}</span>
                          <div>
                            <div className="text-sm font-medium text-gray-900">{event.assetName}</div>
                            <div className="text-sm text-gray-500">{event.assetType}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm text-gray-900">{event.maintenance.description}</div>
                          <div className={`text-sm font-medium ${getSeverityColor(event.severity)}`}>
                            {event.severity === 'low' ? 'Низкий' :
                             event.severity === 'medium' ? 'Средний' :
                             event.severity === 'high' ? 'Высокий' : 'Критичный'} приоритет
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {event.predictionDate.toLocaleDateString('ru-RU')}
                        </div>
                        <div className="text-sm text-gray-500">
                          {event.estimatedDuration}ч
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {event.impactAssessment.affectedAgents} агентов
                        </div>
                        <div className="text-sm text-gray-500">
                          {new Intl.NumberFormat('ru-RU', { 
                            style: 'currency', 
                            currency: 'RUB', 
                            minimumFractionDigits: 0 
                          }).format(event.impactAssessment.costEstimate)}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-blue-600">
                          {(event.prediction.confidence * 100).toFixed(0)}%
                        </div>
                        <div className="text-sm text-gray-500">
                          {event.prediction.algorithm}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Maintenance Calendar */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Календарь обслуживания</h3>
            
            <div className="grid grid-cols-7 gap-2 mb-4">
              {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map(day => (
                <div key={day} className="text-center text-sm font-medium text-gray-500 p-2">
                  {day}
                </div>
              ))}
            </div>
            
            <div className="grid grid-cols-7 gap-2">
              {maintenanceSchedule.slice(0, 28).map((day, index) => (
                <div key={index} className="border border-gray-200 rounded p-2 min-h-[80px]">
                  <div className="text-xs font-medium text-gray-700 mb-1">
                    {new Date(day.date).getDate()}
                  </div>
                  {day.events.length > 0 && (
                    <div className="space-y-1">
                      {day.events.slice(0, 2).map((event, idx) => (
                        <div key={idx} className={`text-xs px-1 py-0.5 rounded ${
                          event.severity === 'critical' ? 'bg-red-100 text-red-700' :
                          event.severity === 'high' ? 'bg-orange-100 text-orange-700' :
                          event.severity === 'medium' ? 'bg-yellow-100 text-yellow-700' :
                          'bg-green-100 text-green-700'
                        }`}>
                          {event.assetName.slice(0, 8)}...
                        </div>
                      ))}
                      {day.events.length > 2 && (
                        <div className="text-xs text-gray-500">
                          +{day.events.length - 2} ещё
                        </div>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
            
            <div className="mt-4 flex items-center gap-4 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-red-100 rounded"></div>
                <span className="text-gray-600">Критичные</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-orange-100 rounded"></div>
                <span className="text-gray-600">Высокий приоритет</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-yellow-100 rounded"></div>
                <span className="text-gray-600">Средний приоритет</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-green-100 rounded"></div>
                <span className="text-gray-600">Плановые</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PredictiveMaintenanceForecaster;