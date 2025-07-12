// BDD: Vacancy Planning Module - Main Container (Feature 27)
import React, { useState, useEffect } from 'react';
import { Navigate, Routes, Route, useNavigate } from 'react-router-dom';
import { Bell, Settings, BarChart3, Calendar, FileText, ArrowRight, AlertCircle } from 'lucide-react';
import { VacancyPlanningSettings } from './VacancyPlanningSettings';
import { VacancyAnalysisDashboard } from './VacancyAnalysisDashboard';
import { VacancyResultsVisualization } from './VacancyResultsVisualization';
import { VacancyRecommendations } from './VacancyRecommendations';
import { VacancyIntegration } from './VacancyIntegration';
import { VacancyReporting } from './VacancyReporting';
import type { VacancyPlanningSettings as VacancySettings } from '../types/vacancy';

// BDD: Access Control Scenario - Check System_AccessVacancyPlanning permission
const checkVacancyPlanningAccess = (): boolean => {
  const userRoles = JSON.parse(localStorage.getItem('userRoles') || '[]');
  return userRoles.includes('System_AccessVacancyPlanning');
};

export const VacancyPlanningModule: React.FC = () => {
  const navigate = useNavigate();
  const [hasAccess, setHasAccess] = useState<boolean | null>(null);
  const [settings, setSettings] = useState<VacancySettings>({
    minimumVacancyEfficiency: 85,
    analysisPeriod: 30,
    forecastConfidence: 95,
    workRuleOptimization: true,
    integrationWithExchange: true
  });

  useEffect(() => {
    // BDD: Verify access permissions on mount
    const accessGranted = checkVacancyPlanningAccess();
    setHasAccess(accessGranted);
    
    if (!accessGranted) {
      // BDD: Log security event for audit trail
      console.log('[AUDIT] Access denied to Vacancy Planning Module - missing System_AccessVacancyPlanning role');
    }
  }, []);

  // BDD: Show loading while checking permissions
  if (hasAccess === null) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Проверка прав доступа...</p>
        </div>
      </div>
    );
  }

  // BDD: Deny access without proper permissions
  if (!hasAccess) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-md">
          <div className="flex items-center gap-3 text-red-800">
            <AlertCircle className="h-6 w-6" />
            <div>
              <h3 className="font-semibold">Доступ запрещен</h3>
              <p className="text-sm mt-1">
                Требуется роль System_AccessVacancyPlanning для доступа к модулю планирования вакансий
              </p>
              <button
                onClick={() => navigate('/')}
                className="mt-4 text-sm text-blue-600 hover:text-blue-800"
              >
                Вернуться к авторизованным модулям →
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // BDD: Main module interface with all vacancy planning functions
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-semibold text-gray-900">
                Планирование вакансий
              </h1>
              <p className="text-sm text-gray-600 mt-1">
                Анализ кадровых потребностей и оптимизация найма
              </p>
            </div>
            <div className="flex items-center gap-4">
              <Bell className="h-5 w-5 text-gray-500 cursor-pointer hover:text-gray-700" />
              <Settings 
                className="h-5 w-5 text-gray-500 cursor-pointer hover:text-gray-700"
                onClick={() => navigate('/vacancy-planning/settings')}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            <button
              onClick={() => navigate('/vacancy-planning/analysis')}
              className="py-4 px-1 border-b-2 border-blue-500 text-sm font-medium text-blue-600"
            >
              <div className="flex items-center gap-2">
                <BarChart3 className="h-4 w-4" />
                Анализ
              </div>
            </button>
            <button
              onClick={() => navigate('/vacancy-planning/results')}
              className="py-4 px-1 border-b-2 border-transparent text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300"
            >
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                Результаты
              </div>
            </button>
            <button
              onClick={() => navigate('/vacancy-planning/recommendations')}
              className="py-4 px-1 border-b-2 border-transparent text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300"
            >
              <div className="flex items-center gap-2">
                <FileText className="h-4 w-4" />
                Рекомендации
              </div>
            </button>
            <button
              onClick={() => navigate('/vacancy-planning/integration')}
              className="py-4 px-1 border-b-2 border-transparent text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300"
            >
              <div className="flex items-center gap-2">
                <ArrowRight className="h-4 w-4" />
                Интеграция
              </div>
            </button>
            <button
              onClick={() => navigate('/vacancy-planning/reports')}
              className="py-4 px-1 border-b-2 border-transparent text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300"
            >
              <div className="flex items-center gap-2">
                <FileText className="h-4 w-4" />
                Отчеты
              </div>
            </button>
          </nav>
        </div>
      </div>

      {/* Content Area */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <Routes>
          <Route path="/" element={<Navigate to="/vacancy-planning/analysis" replace />} />
          <Route path="/settings" element={<VacancyPlanningSettings settings={settings} onSave={setSettings} />} />
          <Route path="/analysis" element={<VacancyAnalysisDashboard settings={settings} />} />
          <Route path="/results" element={<VacancyResultsVisualization />} />
          <Route path="/recommendations" element={<VacancyRecommendations />} />
          <Route path="/integration" element={<VacancyIntegration />} />
          <Route path="/reports" element={<VacancyReporting />} />
        </Routes>
      </div>
    </div>
  );
};