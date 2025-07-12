import React, { useState, useEffect } from 'react';

interface KPIMetric {
  id: string;
  name: string;
  value: number;
  target?: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  lastUpdated: Date;
}

interface KPICardProps {
  metric: KPIMetric;
}

const KPICard: React.FC<KPICardProps> = ({ metric }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'hours') return `${value.toFixed(1)}h`;
    return value.toFixed(1);
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return '—';
      case 'down': return '˜';
      case 'stable': return '’';
      default: return '’';
    }
  };

  const getTrendColor = (trend: string) => {
    switch (trend) {
      case 'up': return 'text-green-600';
      case 'down': return 'text-red-600';
      case 'stable': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  const progressPercentage = metric.target ? Math.min((metric.value / metric.target) * 100, 100) : 0;

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600">{metric.name}</p>
          <div className="mt-1 flex items-baseline">
            <p className="text-2xl font-semibold text-gray-900">
              {formatValue(metric.value, metric.unit)}
            </p>
            {metric.target && (
              <p className="ml-2 text-sm text-gray-500">
                / {formatValue(metric.target, metric.unit)}
              </p>
            )}
          </div>
        </div>
        
        <div className="flex flex-col items-end">
          <div 
            className="w-3 h-3 rounded-full mb-2"
            style={{ backgroundColor: getStatusColor(metric.status) }}
          ></div>
          <div className={`flex items-center ${getTrendColor(metric.trend)}`}>
            <span className="text-lg mr-1">{getTrendIcon(metric.trend)}</span>
            <span className="text-sm font-medium">
              {Math.abs(metric.changePercent).toFixed(1)}%
            </span>
          </div>
        </div>
      </div>
      
      {metric.target && (
        <div className="mt-4">
          <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
            <span>Progress to Target</span>
            <span>{progressPercentage.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <div 
              className="h-1.5 rounded-full transition-all duration-300"
              style={{ 
                width: `${progressPercentage}%`,
                backgroundColor: getStatusColor(metric.status)
              }}
            ></div>
          </div>
        </div>
      )}
      
      <div className="mt-3 text-xs text-gray-400">
        Updated: {metric.lastUpdated.toLocaleTimeString()}
      </div>
    </div>
  );
};

const ReportsDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<KPIMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  // Mock real-time data updates
  useEffect(() => {
    const loadMetrics = () => {
      const now = new Date();
      const mockMetrics: KPIMetric[] = [
        {
          id: '1',
          name: 'Service Level',
          value: 87.3,
          target: 85.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 2.4,
          lastUpdated: now
        },
        {
          id: '2',
          name: 'Schedule Adherence',
          value: 96.1,
          target: 95.0,
          unit: '%',
          status: 'excellent',
          trend: 'stable',
          changePercent: 0.3,
          lastUpdated: now
        },
        {
          id: '3',
          name: 'Forecast Accuracy',
          value: 87.6,
          target: 90.0,
          unit: '%',
          status: 'warning',
          trend: 'down',
          changePercent: -1.2,
          lastUpdated: now
        },
        {
          id: '4',
          name: 'Absenteeism Rate',
          value: 4.2,
          target: 5.0,
          unit: '%',
          status: 'good',
          trend: 'down',
          changePercent: -0.8,
          lastUpdated: now
        },
        {
          id: '5',
          name: 'Request Approval Rate',
          value: 94.3,
          target: 92.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 1.7,
          lastUpdated: now
        },
        {
          id: '6',
          name: 'Average Response Time',
          value: 2.3,
          target: 3.0,
          unit: 'hours',
          status: 'good',
          trend: 'down',
          changePercent: -14.8,
          lastUpdated: now
        }
      ];
      
      setMetrics(mockMetrics);
      setLoading(false);
      setLastRefresh(now);
    };

    loadMetrics();
    
    // Real-time updates every 30 seconds
    const interval = setInterval(() => {
      loadMetrics();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const getOverallStatus = () => {
    const excellentCount = metrics.filter(m => m.status === 'excellent').length;
    const goodCount = metrics.filter(m => m.status === 'good').length;
    const total = metrics.length;
    
    if (excellentCount >= total * 0.7) return { status: 'excellent', text: 'Excellent Performance' };
    if ((excellentCount + goodCount) >= total * 0.8) return { status: 'good', text: 'Good Performance' };
    return { status: 'warning', text: 'Requires Attention' };
  };

  const overallStatus = getOverallStatus();

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-300 rounded w-1/3 mb-4"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-300 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Executive Dashboard</h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">=Ê</span>
              {new Date().toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </p>
          </div>
          
          <div className="text-right">
            <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
              overallStatus.status === 'excellent' ? 'bg-green-100 text-green-800' :
              overallStatus.status === 'good' ? 'bg-blue-100 text-blue-800' :
              'bg-yellow-100 text-yellow-800'
            }`}>
              <div 
                className="w-2 h-2 rounded-full mr-2"
                style={{ backgroundColor: getStatusColor(overallStatus.status) }}
              ></div>
              {overallStatus.text}
            </div>
            <p className="text-sm text-gray-500 mt-1">
              Overall System Status
            </p>
            <p className="text-xs text-gray-400 mt-1">
              Last refresh: {lastRefresh.toLocaleTimeString()}
            </p>
          </div>
        </div>
      </div>

      {/* KPI Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {metrics.map((metric) => (
          <KPICard key={metric.id} metric={metric} />
        ))}
      </div>

      {/* Quick Insights */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Key Insights</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-2 flex items-center">
              <span className="text-lg mr-2"><¯</span>
              Achievements
            </h4>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>" Schedule adherence exceeds target by 1.1%</li>
              <li>" Response time improved by 14.8%</li>
              <li>" Absenteeism decreased and is below target</li>
              <li>" Service level maintaining excellence</li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium text-gray-900 mb-2 flex items-center">
              <span className="text-lg mr-2">=È</span>
              Areas for Improvement
            </h4>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>" Monitor forecast accuracy trends</li>
              <li>" Optimize evening coverage</li>
              <li>" Enhance request processing workflows</li>
              <li>" Review capacity planning models</li>
            </ul>
          </div>
        </div>
      </div>

      {/* Real-time Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Live Data</span>
            </div>
            <div className="text-sm text-gray-500">
              Updates every 30 seconds
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>=â {metrics.filter(m => m.status === 'excellent').length} Excellent</span>
            <span>=5 {metrics.filter(m => m.status === 'good').length} Good</span>
            <span>=á {metrics.filter(m => m.status === 'warning').length} Warning</span>
            <span>=4 {metrics.filter(m => m.status === 'critical').length} Critical</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReportsDashboard;