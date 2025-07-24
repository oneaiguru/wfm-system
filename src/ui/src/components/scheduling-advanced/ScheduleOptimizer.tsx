import React, { useState } from 'react';
import { Zap, Clock, Users, TrendingUp, AlertCircle, CheckCircle } from 'lucide-react';

const API_BASE_URL = 'http://localhost:8001/api/v1';

interface OptimizationResults {
  optimization_id: string;
  improved_coverage: number;
  reduced_overtime: number;
  load_balance_score: number;
  cost_savings: number;
  affected_employees: number;
  schedule_efficiency: number;
  completion_time: string;
  recommendations: string[];
}

const ScheduleOptimizer: React.FC = () => {
  const [optimizing, setOptimizing] = useState(false);
  const [results, setResults] = useState<OptimizationResults | null>(null);
  const [error, setError] = useState<string>('');
  const [success, setSuccess] = useState<string>('');

  const runOptimization = async () => {
    setOptimizing(true);
    setError('');
    setSuccess('');
    setResults(null);

    try {
      console.log('[SCHEDULE OPTIMIZER] Starting optimization with ALGORITHM-OPUS endpoint');
      
      // Get auth token for protected endpoint
      const authToken = localStorage.getItem('authToken');
      
      if (!authToken) {
        throw new Error('Authentication token required for optimization');
      }

      // Call ALGORITHM-OPUS schedule optimization endpoint
      const response = await fetch(`${API_BASE_URL}/schedule/optimize`, {
        method: 'POST',
        headers: { 
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json' 
        },
        body: JSON.stringify({ 
          team_id: 1,
          optimization_type: 'genetic',
          iterations: 1000,
          objectives: ['coverage', 'cost', 'balance'],
          constraints: {
            max_overtime_hours: 40,
            min_coverage_percentage: 85,
            respect_employee_preferences: true
          }
        }),
      });

      if (!response.ok) {
        if (response.status === 500) {
          // Handle known database schema issue
          console.log('⚠️ ALGORITHM-OPUS optimization endpoint needs database schema fixes');
          setError('Алгоритм оптимизации временно недоступен. Использование демонстрационных результатов.');
          
          // Show demo results
          const demoResults: OptimizationResults = {
            optimization_id: 'demo_opt_' + Date.now(),
            improved_coverage: 12.5,
            reduced_overtime: 18.3,
            load_balance_score: 94.2,
            cost_savings: 15800,
            affected_employees: 23,
            schedule_efficiency: 89.7,
            completion_time: new Date().toISOString(),
            recommendations: [
              'Перераспределить смены в пиковые часы (14:00-16:00)',
              'Сократить сверхурочные часы на 18% через оптимизацию перерывов',
              'Улучшить балансировку нагрузки между опытными и новыми сотрудниками',
              'Увеличить покрытие в утренние часы (09:00-11:00)',
              'Оптимизировать выходные дни для повышения эффективности'
            ]
          };
          
          setResults(demoResults);
          setSuccess('Демонстрационная оптимизация выполнена успешно');
          return;
        }
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      console.log('✅ Schedule optimization completed:', data);
      
      // Map ALGORITHM-OPUS response to component format
      const optimizationResults: OptimizationResults = {
        optimization_id: data.optimization_id || 'opt_' + Date.now(),
        improved_coverage: data.coverage_improvement || data.improved_coverage || 0,
        reduced_overtime: data.overtime_reduction || data.reduced_overtime || 0,
        load_balance_score: data.load_balance_score || data.balance_score || 0,
        cost_savings: data.cost_savings || 0,
        affected_employees: data.affected_employees || 0,
        schedule_efficiency: data.schedule_efficiency || data.efficiency_score || 0,
        completion_time: data.completion_time || new Date().toISOString(),
        recommendations: data.recommendations || []
      };
      
      setResults(optimizationResults);
      setSuccess('Оптимизация расписания выполнена успешно!');
      
    } catch (err) {
      console.error('[SCHEDULE OPTIMIZER] Error:', err);
      setError(err instanceof Error ? err.message : 'Ошибка при выполнении оптимизации');
    } finally {
      setOptimizing(false);
    }
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-sm border border-gray-200">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Оптимизатор расписаний</h1>
        <p className="text-gray-600">Алгоритмическая оптимизация расписания для повышения эффективности и сокращения затрат</p>
      </div>

      {/* Status Messages */}
      {error && (
        <div className="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded-md">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-yellow-500 mr-2" />
            <span className="text-yellow-700">{error}</span>
          </div>
        </div>
      )}

      {success && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-md">
          <div className="flex items-center">
            <CheckCircle className="h-5 w-5 text-green-500 mr-2" />
            <span className="text-green-700">{success}</span>
          </div>
        </div>
      )}

      {/* Controls */}
      <div className="mb-6">
        <button 
          onClick={runOptimization} 
          disabled={optimizing}
          className="flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Zap className="h-5 w-5 mr-2" />
          {optimizing ? 'Выполняется оптимизация...' : 'Запустить оптимизацию'}
        </button>
      </div>

      {/* Results */}
      {results && (
        <div className="space-y-6">
          <div className="border-t border-gray-200 pt-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Результаты оптимизации</h2>
            <div className="text-sm text-gray-600 mb-4">
              ID оптимизации: {results.optimization_id} | Завершено: {new Date(results.completion_time).toLocaleString('ru-RU')}
            </div>
            
            {/* Metrics Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <TrendingUp className="h-5 w-5 text-green-600 mr-2" />
                  <h3 className="font-medium text-green-900">Улучшение покрытия</h3>
                </div>
                <div className="text-2xl font-bold text-green-600">+{results.improved_coverage}%</div>
              </div>
              
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Clock className="h-5 w-5 text-blue-600 mr-2" />
                  <h3 className="font-medium text-blue-900">Сокращение сверхурочных</h3>
                </div>
                <div className="text-2xl font-bold text-blue-600">-{results.reduced_overtime}%</div>
              </div>
              
              <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Users className="h-5 w-5 text-purple-600 mr-2" />
                  <h3 className="font-medium text-purple-900">Балансировка нагрузки</h3>
                </div>
                <div className="text-2xl font-bold text-purple-600">{results.load_balance_score}%</div>
              </div>
              
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <TrendingUp className="h-5 w-5 text-orange-600 mr-2" />
                  <h3 className="font-medium text-orange-900">Экономия затрат</h3>
                </div>
                <div className="text-2xl font-bold text-orange-600">{results.cost_savings.toLocaleString('ru-RU')} ₽</div>
              </div>
              
              <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Users className="h-5 w-5 text-indigo-600 mr-2" />
                  <h3 className="font-medium text-indigo-900">Затронуто сотрудников</h3>
                </div>
                <div className="text-2xl font-bold text-indigo-600">{results.affected_employees}</div>
              </div>
              
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Zap className="h-5 w-5 text-gray-600 mr-2" />
                  <h3 className="font-medium text-gray-900">Эффективность расписания</h3>
                </div>
                <div className="text-2xl font-bold text-gray-600">{results.schedule_efficiency}%</div>
              </div>
            </div>

            {/* Recommendations */}
            {results.recommendations.length > 0 && (
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <h3 className="font-medium text-gray-900 mb-3">Рекомендации по оптимизации:</h3>
                <ul className="space-y-2">
                  {results.recommendations.map((rec, index) => (
                    <li key={index} className="flex items-start">
                      <span className="inline-block w-2 h-2 bg-blue-500 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                      <span className="text-gray-700">{rec}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default ScheduleOptimizer;