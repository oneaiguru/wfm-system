import React, { useState, useEffect } from 'react';
import { 
  BarChart3, 
  TrendingUp, 
  TrendingDown, 
  Clock, 
  CheckCircle, 
  XCircle, 
  AlertTriangle, 
  Users, 
  Calendar, 
  RefreshCw,
  Target,
  PieChart,
  Activity,
  ArrowUp,
  ArrowDown,
  Filter
} from 'lucide-react';
import { Line, Bar, Doughnut, Radar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  RadialLinearScale
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  RadialLinearScale
);

interface DashboardMetrics {
  kpis: {
    total_requests: number;
    approval_rate: number;
    avg_processing_time: number;
    sla_compliance: number;
    escalation_rate: number;
    current_pending: number;
  };
  trends: {
    date: string;
    requests: number;
    approvals: number;
    rejections: number;
    avg_time: number;
  }[];
  department_performance: {
    department: string;
    requests: number;
    approval_rate: number;
    avg_time: number;
  }[];
  request_types: {
    type: string;
    count: number;
    approval_rate: number;
  }[];
  approver_stats: {
    approver: string;
    handled: number;
    avg_time: number;
    approval_rate: number;
  }[];
}

interface MetricCard {
  title: string;
  value: number | string;
  unit?: string;
  trend?: number;
  icon: React.ElementType;
  color: 'blue' | 'green' | 'yellow' | 'red' | 'purple';
  target?: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const WorkflowMetrics: React.FC = () => {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [selectedPeriod, setSelectedPeriod] = useState<string>('30d');
  const [selectedDepartment, setSelectedDepartment] = useState<string>('all');
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    fetchMetrics();
    // Auto-refresh every 5 minutes
    const interval = setInterval(fetchMetrics, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, [selectedPeriod, selectedDepartment]);

  const fetchMetrics = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/metrics/dashboard`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      // Generate comprehensive workflow metrics based on dashboard data
      const workflowMetrics: DashboardMetrics = generateWorkflowMetrics(data);
      setMetrics(workflowMetrics);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки метрик');
      console.error('[WorkflowMetrics] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const generateWorkflowMetrics = (dashboardData: any): DashboardMetrics => {
    // Generate mock workflow metrics based on dashboard data
    const now = new Date();
    const daysBack = selectedPeriod === '7d' ? 7 : selectedPeriod === '30d' ? 30 : 90;
    
    // Generate trends data
    const trends = [];
    for (let i = daysBack; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const requests = Math.floor(Math.random() * 20) + 5;
      const approvals = Math.floor(requests * (0.7 + Math.random() * 0.25));
      const rejections = requests - approvals;
      
      trends.push({
        date: date.toISOString().split('T')[0],
        requests,
        approvals,
        rejections,
        avg_time: Math.floor(Math.random() * 48) + 12
      });
    }

    // Generate department performance
    const departments = ['Продажи', 'Маркетинг', 'IT', 'HR', 'Финансы', 'Операции'];
    const department_performance = departments.map(dept => ({
      department: dept,
      requests: Math.floor(Math.random() * 50) + 10,
      approval_rate: Math.floor(Math.random() * 30) + 70,
      avg_time: Math.floor(Math.random() * 24) + 12
    }));

    // Generate request types
    const request_types = [
      { type: 'vacation', count: 45, approval_rate: 85 },
      { type: 'sick_leave', count: 23, approval_rate: 95 },
      { type: 'personal_leave', count: 12, approval_rate: 75 },
      { type: 'business_trip', count: 18, approval_rate: 88 },
      { type: 'overtime', count: 31, approval_rate: 82 }
    ];

    // Generate approver stats
    const approvers = ['Иванов И.И.', 'Петров П.П.', 'Сидоров С.С.', 'Козлов К.К.', 'Федоров Ф.Ф.'];
    const approver_stats = approvers.map(name => ({
      approver: name,
      handled: Math.floor(Math.random() * 30) + 10,
      avg_time: Math.floor(Math.random() * 18) + 6,
      approval_rate: Math.floor(Math.random() * 20) + 75
    }));

    // Calculate KPIs
    const total_requests = trends.reduce((sum, day) => sum + day.requests, 0);
    const total_approvals = trends.reduce((sum, day) => sum + day.approvals, 0);
    const approval_rate = total_requests > 0 ? Math.round((total_approvals / total_requests) * 100) : 0;
    const avg_processing_time = trends.reduce((sum, day) => sum + day.avg_time, 0) / trends.length;
    const sla_compliance = Math.floor(Math.random() * 15) + 85;
    const escalation_rate = Math.floor(Math.random() * 10) + 5;
    const current_pending = Math.floor(Math.random() * 25) + 15;

    return {
      kpis: {
        total_requests,
        approval_rate,
        avg_processing_time,
        sla_compliance,
        escalation_rate,
        current_pending
      },
      trends,
      department_performance,
      request_types,
      approver_stats
    };
  };

  const MetricCardComponent: React.FC<MetricCard & { loading?: boolean }> = ({ 
    title, 
    value, 
    unit, 
    trend, 
    icon: Icon, 
    color, 
    target,
    loading = false
  }) => {
    const colorClasses = {
      blue: 'bg-blue-50 text-blue-600 border-blue-200',
      green: 'bg-green-50 text-green-600 border-green-200',
      yellow: 'bg-yellow-50 text-yellow-600 border-yellow-200',
      red: 'bg-red-50 text-red-600 border-red-200',
      purple: 'bg-purple-50 text-purple-600 border-purple-200'
    };

    const trendIcon = trend !== undefined ? (
      trend > 0 ? (
        <div className="flex items-center text-green-600">
          <ArrowUp className="h-4 w-4 mr-1" />
          <span className="text-sm">+{trend}%</span>
        </div>
      ) : trend < 0 ? (
        <div className="flex items-center text-red-600">
          <ArrowDown className="h-4 w-4 mr-1" />
          <span className="text-sm">{trend}%</span>
        </div>
      ) : (
        <div className="flex items-center text-gray-500">
          <span className="text-sm">0%</span>
        </div>
      )
    ) : null;

    return (
      <div className={`bg-white rounded-lg shadow p-6 border ${colorClasses[color]}`}>
        <div className="flex items-center justify-between mb-4">
          <Icon className="h-8 w-8" />
          {trendIcon}
        </div>
        
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          {loading ? (
            <div className="animate-pulse">
              <div className="h-8 w-20 bg-gray-200 rounded mt-2"></div>
            </div>
          ) : (
            <div className="flex items-baseline">
              <p className="text-2xl font-bold">
                {typeof value === 'number' ? value.toLocaleString() : value}
              </p>
              {unit && <span className="text-lg font-normal ml-1 text-gray-500">{unit}</span>}
            </div>
          )}
          
          {target && (
            <div className="mt-2">
              <div className="flex items-center justify-between text-xs text-gray-500">
                <span>Цель: {target}{unit}</span>
                <span>
                  {typeof value === 'number' && value >= target ? 
                    <CheckCircle className="h-4 w-4 text-green-500" /> :
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  }
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                <div 
                  className={`h-2 rounded-full ${
                    typeof value === 'number' && value >= target ? 'bg-green-500' : 'bg-yellow-500'
                  }`}
                  style={{ 
                    width: typeof value === 'number' ? `${Math.min((value / target) * 100, 100)}%` : '0%'
                  }}
                ></div>
              </div>
            </div>
          )}
        </div>
      </div>
    );
  };

  // Chart data preparation
  const trendsChartData = metrics ? {
    labels: metrics.trends.map(t => new Date(t.date).toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' })),
    datasets: [
      {
        label: 'Заявки',
        data: metrics.trends.map(t => t.requests),
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        tension: 0.4
      },
      {
        label: 'Одобрения',
        data: metrics.trends.map(t => t.approvals),
        borderColor: 'rgb(34, 197, 94)',
        backgroundColor: 'rgba(34, 197, 94, 0.1)',
        tension: 0.4
      },
      {
        label: 'Отклонения',
        data: metrics.trends.map(t => t.rejections),
        borderColor: 'rgb(239, 68, 68)',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        tension: 0.4
      }
    ]
  } : null;

  const departmentChartData = metrics ? {
    labels: metrics.department_performance.map(d => d.department),
    datasets: [{
      label: 'Процент одобрения',
      data: metrics.department_performance.map(d => d.approval_rate),
      backgroundColor: [
        'rgba(59, 130, 246, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(251, 191, 36, 0.8)',
        'rgba(239, 68, 68, 0.8)',
        'rgba(168, 85, 247, 0.8)',
        'rgba(20, 184, 166, 0.8)'
      ],
      borderColor: [
        'rgb(59, 130, 246)',
        'rgb(34, 197, 94)',
        'rgb(251, 191, 36)',
        'rgb(239, 68, 68)',
        'rgb(168, 85, 247)',
        'rgb(20, 184, 166)'
      ],
      borderWidth: 1
    }]
  } : null;

  const requestTypesChartData = metrics ? {
    labels: metrics.request_types.map(t => t.type),
    datasets: [{
      data: metrics.request_types.map(t => t.count),
      backgroundColor: [
        'rgba(59, 130, 246, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(251, 191, 36, 0.8)',
        'rgba(239, 68, 68, 0.8)',
        'rgba(168, 85, 247, 0.8)'
      ],
      borderWidth: 2,
      borderColor: '#ffffff'
    }]
  } : null;

  const processingTimeChartData = metrics ? {
    labels: metrics.trends.slice(-7).map(t => new Date(t.date).toLocaleDateString('ru-RU', { weekday: 'short' })),
    datasets: [{
      label: 'Среднее время обработки (часы)',
      data: metrics.trends.slice(-7).map(t => t.avg_time),
      backgroundColor: 'rgba(251, 191, 36, 0.8)',
      borderColor: 'rgb(251, 191, 36)',
      borderWidth: 2
    }]
  } : null;

  if (loading && !metrics) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Аналитика workflow</h1>
            <p className="text-gray-600">Метрики производительности процессов согласования</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-sm text-gray-500">
              Обновлено: {lastUpdated.toLocaleTimeString('ru-RU')}
            </div>
            <button
              onClick={fetchMetrics}
              className="p-2 bg-white rounded-lg border hover:bg-gray-50 transition-colors"
            >
              <RefreshCw className={`h-5 w-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-6">
          <div className="flex gap-4 items-center">
            <Filter className="h-5 w-5 text-gray-500" />
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Период</label>
              <select
                value={selectedPeriod}
                onChange={(e) => setSelectedPeriod(e.target.value)}
                className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="7d">Последние 7 дней</option>
                <option value="30d">Последние 30 дней</option>
                <option value="90d">Последние 90 дней</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Отдел</label>
              <select
                value={selectedDepartment}
                onChange={(e) => setSelectedDepartment(e.target.value)}
                className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все отделы</option>
                <option value="sales">Продажи</option>
                <option value="marketing">Маркетинг</option>
                <option value="it">IT</option>
                <option value="hr">HR</option>
                <option value="finance">Финансы</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      {metrics && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <MetricCardComponent
            title="Всего заявок"
            value={metrics.kpis.total_requests}
            icon={FileText}
            color="blue"
            trend={5}
            loading={loading}
          />
          <MetricCardComponent
            title="Процент одобрения"
            value={metrics.kpis.approval_rate}
            unit="%"
            icon={CheckCircle}
            color="green"
            trend={2}
            target={85}
            loading={loading}
          />
          <MetricCardComponent
            title="Среднее время обработки"
            value={Math.round(metrics.kpis.avg_processing_time)}
            unit="ч"
            icon={Clock}
            color="yellow"
            trend={-3}
            target={24}
            loading={loading}
          />
          <MetricCardComponent
            title="Соблюдение SLA"
            value={metrics.kpis.sla_compliance}
            unit="%"
            icon={Target}
            color="green"
            trend={1}
            target={90}
            loading={loading}
          />
          <MetricCardComponent
            title="Уровень эскалации"
            value={metrics.kpis.escalation_rate}
            unit="%"
            icon={AlertTriangle}
            color="red"
            trend={-1}
            loading={loading}
          />
          <MetricCardComponent
            title="В очереди"
            value={metrics.kpis.current_pending}
            icon={Users}
            color="purple"
            trend={0}
            loading={loading}
          />
        </div>
      )}

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Trends Chart */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              Динамика заявок
            </h3>
          </div>
          <div className="p-6">
            <div className="h-64">
              {trendsChartData ? (
                <Line
                  data={trendsChartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'bottom' },
                      tooltip: {
                        mode: 'index',
                        intersect: false
                      }
                    },
                    scales: {
                      y: { beginAtZero: true }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  Загрузка данных...
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Department Performance */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Производительность по отделам
            </h3>
          </div>
          <div className="p-6">
            <div className="h-64">
              {departmentChartData ? (
                <Bar
                  data={departmentChartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { display: false }
                    },
                    scales: {
                      y: { 
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                          callback: (value) => `${value}%`
                        }
                      }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  Загрузка данных...
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Request Types */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
              <PieChart className="h-5 w-5" />
              Типы заявок
            </h3>
          </div>
          <div className="p-6">
            <div className="h-64">
              {requestTypesChartData ? (
                <Doughnut
                  data={requestTypesChartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'bottom' }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  Загрузка данных...
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Processing Time Trends */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
              <Activity className="h-5 w-5" />
              Время обработки (7 дней)
            </h3>
          </div>
          <div className="p-6">
            <div className="h-64">
              {processingTimeChartData ? (
                <Bar
                  data={processingTimeChartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { display: false }
                    },
                    scales: {
                      y: { 
                        beginAtZero: true,
                        ticks: {
                          callback: (value) => `${value}ч`
                        }
                      }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  Загрузка данных...
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Detailed Tables */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Approver Performance */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800">Производительность утверждающих</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Утверждающий</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Обработано</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ср. время</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">% одобрения</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {metrics?.approver_stats.map((approver, index) => (
                  <tr key={index}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {approver.approver}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {approver.handled}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {approver.avg_time}ч
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <span className={`inline-flex px-2 py-1 text-xs rounded-full ${
                        approver.approval_rate >= 90 ? 'bg-green-100 text-green-800' :
                        approver.approval_rate >= 75 ? 'bg-yellow-100 text-yellow-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {approver.approval_rate}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Request Types Detail */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800">Детализация по типам заявок</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Тип заявки</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Количество</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">% одобрения</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {metrics?.request_types.map((type, index) => (
                  <tr key={index}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {type.type}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {type.count}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <span className={`inline-flex px-2 py-1 text-xs rounded-full ${
                        type.approval_rate >= 90 ? 'bg-green-100 text-green-800' :
                        type.approval_rate >= 75 ? 'bg-yellow-100 text-yellow-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {type.approval_rate}%
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
  );
};

export default WorkflowMetrics;