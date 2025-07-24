/**
 * Planning Module Portal - SPEC-19 Integration
 * Comprehensive workforce planning interface integrating all planning components
 * Russian localization for planning administrators and managers
 */

import React, { useState, useEffect } from 'react';
import { 
  BarChart3, TrendingUp, Calculator, Users, Target, AlertCircle,
  Calendar, DollarSign, Settings, Download, RefreshCw, Plus,
  Brain, Zap, FileText, CheckCircle, Clock, ArrowUp
} from 'lucide-react';

// Import existing planning components that SPEC-19 references
import CapacityPlanningOptimizer from './CapacityPlanningOptimizer';
import ScenarioModelingEngine from './ScenarioModelingEngine';  
import DemandForecastingEngine from './DemandForecastingEngine';
import ROICalculator from './ROICalculator';

// Real service for SPEC-19
import realPlanningService, {
  PlanningDashboardData,
  CapacityPlan,
  DemandForecast,
  ScenarioAnalysis,
  ROIAnalysis
} from '../../../services/realPlanningService';

interface PlanningModulePortalProps {
  userRole?: 'planning_admin' | 'workforce_planner' | 'manager' | 'viewer';
  departmentId?: string;
}

type PlanningView = 'dashboard' | 'capacity' | 'forecasting' | 'scenarios' | 'roi' | 'optimization' | 'workflows';

// Complete Russian translations for SPEC-19
const translations = {
  title: 'Модуль Планирования',
  subtitle: 'Комплексная система планирования рабочей силы и ресурсов',
  tabs: {
    dashboard: 'Панель управления',
    capacity: 'Планирование мощности',
    forecasting: 'Прогнозирование',
    scenarios: 'Сценарное моделирование',
    roi: 'ROI анализ',
    optimization: 'Оптимизация',
    workflows: 'Рабочие процессы'
  },
  dashboard: {
    totalPlans: 'Всего планов',
    activeScenarios: 'Активных сценариев',
    avgUtilization: 'Средняя загрузка',
    forecastAccuracy: 'Точность прогнозов',
    pendingApprovals: 'Ожидают одобрения',
    recentPlans: 'Последние планы',
    criticalAlerts: 'Критические уведомления',
    understaffed: 'Недоукомплектованные отделы',
    lowAccuracy: 'Низкая точность прогнозов',
    overdueApprovals: 'Просроченные согласования'
  },
  actions: {
    createPlan: 'Создать план',
    runForecast: 'Запустить прогноз',
    newScenario: 'Новый сценарий',
    calculateROI: 'Рассчитать ROI',
    optimize: 'Оптимизировать',
    export: 'Экспорт',
    refresh: 'Обновить',
    viewDetails: 'Подробнее',
    approve: 'Одобрить',
    compare: 'Сравнить'
  },
  status: {
    draft: 'Черновик',
    active: 'Активный',
    approved: 'Одобрен',
    archived: 'Архивирован',
    modeling: 'Моделирование',
    complete: 'Завершен',
    pending: 'Ожидание',
    rejected: 'Отклонен'
  },
  metrics: {
    confidence: 'Уверенность',
    accuracy: 'Точность',
    gap: 'Дефицит',
    recommendation: 'Рекомендация',
    impact: 'Влияние',
    payback: 'Окупаемость'
  }
};

const PlanningModulePortal: React.FC<PlanningModulePortalProps> = ({
  userRole = 'planning_admin',
  departmentId
}) => {
  const [activeView, setActiveView] = useState<PlanningView>('dashboard');
  const [loading, setLoading] = useState(false);
  const [apiHealthy, setApiHealthy] = useState(false);
  const [dashboardData, setDashboardData] = useState<PlanningDashboardData | null>(null);
  const [recentPlans, setRecentPlans] = useState<CapacityPlan[]>([]);
  const [recentForecasts, setRecentForecasts] = useState<DemandForecast[]>([]);

  // Demo data for when API is not available
  const demoDashboardData: PlanningDashboardData = {
    summary: {
      total_plans: 24,
      active_scenarios: 8,
      avg_capacity_utilization: 87.5,
      forecast_accuracy: 89.2,
      pending_approvals: 5
    },
    recent_plans: [
      {
        id: '1',
        name: 'Q3 Customer Support Expansion',
        department_id: 'cs',
        department_name: 'Служба поддержки',
        current_staff: 45,
        demand_forecast: 52,
        capacity_gap: -7,
        recommendation: 'Нанять 7 агентов',
        confidence_level: 85,
        planning_period: '2025-Q3',
        created_at: '2025-07-20',
        status: 'active'
      },
      {
        id: '2',
        name: 'Technical Support Optimization',
        department_id: 'tech',
        department_name: 'Техподдержка',
        current_staff: 20,
        demand_forecast: 18,
        capacity_gap: 2,
        recommendation: 'Перераспределить ресурсы',
        confidence_level: 92,
        planning_period: '2025-Q3',
        created_at: '2025-07-19',
        status: 'approved'
      }
    ],
    recent_forecasts: [
      {
        id: '1',
        period: '2025-Q3',
        forecast_type: 'call_volume',
        predicted_value: 125000,
        confidence_interval: { min: 118000, max: 132000 },
        accuracy_score: 89.2,
        model_used: 'ARIMA + ML',
        factors: ['Сезонность', 'Маркетинговые кампании', 'Исторические данные'],
        created_at: '2025-07-21'
      }
    ],
    critical_alerts: {
      understaffed_departments: ['Служба поддержки', 'Продажи'],
      low_forecast_accuracy: ['Техподдержка'],
      overdue_approvals: ['Q3 Budget Plan', 'Vacation Coverage']
    }
  };

  useEffect(() => {
    checkApiHealth();
    loadDashboardData();
  }, []);

  const checkApiHealth = async () => {
    try {
      const healthy = await realPlanningService.checkPlanningApiHealth();
      setApiHealthy(healthy);
      console.log(`[PLANNING PORTAL] API Health: ${healthy ? 'OK' : 'ERROR'}`);
    } catch (error) {
      console.error('[PLANNING PORTAL] Health check failed:', error);
      setApiHealthy(false);
    }
  };

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      if (apiHealthy) {
        console.log('[PLANNING PORTAL] Loading dashboard data from API...');
        const result = await realPlanningService.getPlanningDashboard();
        
        if (result.success && result.data) {
          setDashboardData(result.data);
          setRecentPlans(result.data.recent_plans);
          setRecentForecasts(result.data.recent_forecasts);
        } else {
          console.log('[PLANNING PORTAL] API returned no data, using demo data');
          setDashboardData(demoDashboardData);
          setRecentPlans(demoDashboardData.recent_plans);
          setRecentForecasts(demoDashboardData.recent_forecasts);
        }
      } else {
        console.log('[PLANNING PORTAL] API unhealthy, using demo data');
        setDashboardData(demoDashboardData);
        setRecentPlans(demoDashboardData.recent_plans);
        setRecentForecasts(demoDashboardData.recent_forecasts);
      }
    } catch (error) {
      console.error('[PLANNING PORTAL] Load dashboard error:', error);
      setDashboardData(demoDashboardData);
      setRecentPlans(demoDashboardData.recent_plans);
      setRecentForecasts(demoDashboardData.recent_forecasts);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'active': return 'bg-blue-100 text-blue-800';
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'archived': return 'bg-yellow-100 text-yellow-800';
      case 'pending': return 'bg-orange-100 text-orange-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const renderDashboard = () => {
    if (!dashboardData) return null;

    return (
      <div className="space-y-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <FileText className="h-8 w-8 text-blue-600" />
              </div>
              <div className="ml-4">
                <div className="text-2xl font-bold text-gray-900">{dashboardData.summary.total_plans}</div>
                <div className="text-sm text-gray-600">{translations.dashboard.totalPlans}</div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Brain className="h-8 w-8 text-purple-600" />
              </div>
              <div className="ml-4">
                <div className="text-2xl font-bold text-gray-900">{dashboardData.summary.active_scenarios}</div>
                <div className="text-sm text-gray-600">{translations.dashboard.activeScenarios}</div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <BarChart3 className="h-8 w-8 text-green-600" />
              </div>
              <div className="ml-4">
                <div className="text-2xl font-bold text-gray-900">{dashboardData.summary.avg_capacity_utilization}%</div>
                <div className="text-sm text-gray-600">{translations.dashboard.avgUtilization}</div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Target className="h-8 w-8 text-orange-600" />
              </div>
              <div className="ml-4">
                <div className="text-2xl font-bold text-gray-900">{dashboardData.summary.forecast_accuracy}%</div>
                <div className="text-sm text-gray-600">{translations.dashboard.forecastAccuracy}</div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Clock className="h-8 w-8 text-red-600" />
              </div>
              <div className="ml-4">
                <div className="text-2xl font-bold text-gray-900">{dashboardData.summary.pending_approvals}</div>
                <div className="text-sm text-gray-600">{translations.dashboard.pendingApprovals}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Plans and Critical Alerts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Plans */}
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">{translations.dashboard.recentPlans}</h3>
              <button
                onClick={() => setActiveView('capacity')}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                {translations.actions.viewDetails}
              </button>
            </div>
            <div className="divide-y divide-gray-200">
              {recentPlans.map((plan) => (
                <div key={plan.id} className="p-6 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-medium text-gray-900">{plan.name}</h4>
                      <p className="text-sm text-gray-600">{plan.department_name}</p>
                      <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                        <span>👥 {plan.current_staff} → {plan.demand_forecast}</span>
                        <span className={plan.capacity_gap < 0 ? 'text-red-600' : 'text-green-600'}>
                          {plan.capacity_gap < 0 ? `${Math.abs(plan.capacity_gap)} дефицит` : `+${plan.capacity_gap} избыток`}
                        </span>
                        <span>🎯 {plan.confidence_level}% {translations.metrics.confidence}</span>
                      </div>
                      <p className="text-sm text-blue-600 mt-1">{plan.recommendation}</p>
                    </div>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(plan.status)}`}>
                      {translations.status[plan.status as keyof typeof translations.status]}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Critical Alerts */}
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">{translations.dashboard.criticalAlerts}</h3>
            </div>
            <div className="p-6 space-y-4">
              {dashboardData.critical_alerts.understaffed_departments.length > 0 && (
                <div className="flex items-start gap-3">
                  <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <div className="font-medium text-gray-900">{translations.dashboard.understaffed}</div>
                    <div className="text-sm text-gray-600">
                      {dashboardData.critical_alerts.understaffed_departments.join(', ')}
                    </div>
                  </div>
                </div>
              )}

              {dashboardData.critical_alerts.low_forecast_accuracy.length > 0 && (
                <div className="flex items-start gap-3">
                  <Target className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <div className="font-medium text-gray-900">{translations.dashboard.lowAccuracy}</div>
                    <div className="text-sm text-gray-600">
                      {dashboardData.critical_alerts.low_forecast_accuracy.join(', ')}
                    </div>
                  </div>
                </div>
              )}

              {dashboardData.critical_alerts.overdue_approvals.length > 0 && (
                <div className="flex items-start gap-3">
                  <Clock className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <div className="font-medium text-gray-900">{translations.dashboard.overdueApprovals}</div>
                    <div className="text-sm text-gray-600">
                      {dashboardData.critical_alerts.overdue_approvals.join(', ')}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        {userRole === 'planning_admin' && (
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Быстрые действия</h3>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <button
                onClick={() => setActiveView('capacity')}
                className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-400 hover:bg-blue-50 transition-colors text-left group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <Users className="h-5 w-5 text-blue-600" />
                  <span className="font-medium text-gray-900 group-hover:text-blue-900">{translations.actions.createPlan}</span>
                </div>
                <p className="text-sm text-gray-600">Создать план мощности</p>
              </button>

              <button
                onClick={() => setActiveView('forecasting')}
                className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-green-400 hover:bg-green-50 transition-colors text-left group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <TrendingUp className="h-5 w-5 text-green-600" />
                  <span className="font-medium text-gray-900 group-hover:text-green-900">{translations.actions.runForecast}</span>
                </div>
                <p className="text-sm text-gray-600">Запустить прогнозирование</p>
              </button>

              <button
                onClick={() => setActiveView('scenarios')}
                className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-purple-400 hover:bg-purple-50 transition-colors text-left group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <Brain className="h-5 w-5 text-purple-600" />
                  <span className="font-medium text-gray-900 group-hover:text-purple-900">{translations.actions.newScenario}</span>
                </div>
                <p className="text-sm text-gray-600">Создать сценарий</p>
              </button>

              <button
                onClick={() => setActiveView('roi')}
                className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-orange-400 hover:bg-orange-50 transition-colors text-left group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <Calculator className="h-5 w-5 text-orange-600" />
                  <span className="font-medium text-gray-900 group-hover:text-orange-900">{translations.actions.calculateROI}</span>
                </div>
                <p className="text-sm text-gray-600">Анализ рентабельности</p>
              </button>
            </div>
          </div>
        )}
      </div>
    );
  };

  const renderActiveView = () => {
    switch (activeView) {
      case 'dashboard':
        return renderDashboard();
      case 'capacity':
        return <CapacityPlanningOptimizer />;
      case 'forecasting':
        return <DemandForecastingEngine />;
      case 'scenarios':
        return <ScenarioModelingEngine />;
      case 'roi':
        return <ROICalculator />;
      case 'optimization':
        return (
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Оптимизация рабочей силы</h3>
            <p className="text-gray-600">Функционал в разработке - автоматическая оптимизация распределения ресурсов</p>
          </div>
        );
      case 'workflows':
        return (
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Рабочие процессы планирования</h3>
            <p className="text-gray-600">Функционал в разработке - управление процессами планирования</p>
          </div>
        );
      default:
        return renderDashboard();
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{translations.title}</h1>
          <p className="text-gray-600">{translations.subtitle}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-sm text-gray-500">Роль: {userRole === 'planning_admin' ? 'Администратор планирования' : 'Планировщик'}</span>
            <span className={`text-xs px-2 py-1 rounded-full ${apiHealthy ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
              API: {apiHealthy ? 'SPEC-19 ✅' : 'Demo режим'}
            </span>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={loadDashboardData}
            disabled={loading}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            {translations.actions.refresh}
          </button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {Object.entries(translations.tabs).map(([key, label]) => (
            <button
              key={key}
              onClick={() => setActiveView(key as PlanningView)}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeView === key
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {label}
            </button>
          ))}
        </nav>
      </div>

      {/* Active View Content */}
      {renderActiveView()}
    </div>
  );
};

export default PlanningModulePortal;