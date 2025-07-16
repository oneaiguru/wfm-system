import React, { useState, useEffect } from 'react';
import { 
  TrendingUp, 
  TrendingDown,
  Users, 
  Target, 
  Award, 
  BarChart3,
  Clock,
  CheckCircle,
  Star,
  AlertTriangle,
  RefreshCw,
  Download,
  Filter,
  Calendar
} from 'lucide-react';
import realPerformanceService, { PerformanceData, PerformanceMetric, AgentPerformance, TeamPerformance } from '../../services/realPerformanceService';

// BDD: Performance metrics dashboard with comprehensive KPI tracking
// Based on: performance-metrics-dashboard.feature

const PerformanceMetrics: React.FC = () => {
  const [performanceData, setPerformanceData] = useState<PerformanceData | null>(null);
  const [selectedPeriod, setSelectedPeriod] = useState<string>('today');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Available periods
  const periods = [
    { value: 'today', label: 'Today' },
    { value: 'week', label: 'This Week' },
    { value: 'month', label: 'This Month' },
    { value: 'quarter', label: 'This Quarter' }
  ];

  // Load initial performance data
  useEffect(() => {
    loadPerformanceData();
  }, [selectedPeriod]);

  const loadPerformanceData = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realPerformanceService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call
      const result = await realPerformanceService.getPerformanceMetrics(selectedPeriod);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Performance data loaded:', result.data);
        setPerformanceData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load performance metrics');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Performance load error:', errorMessage);
    } finally {
      setIsLoading(false);
      setIsConnecting(false);
    }
  };

  // Auto-refresh functionality
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        const result = await realPerformanceService.refreshPerformanceMetrics(selectedPeriod);
        if (result.success && result.data) {
          setPerformanceData(result.data);
        }
      } catch (error) {
        console.warn('[REAL COMPONENT] Auto-refresh failed:', error);
      }
      
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 60000); // 1 minute intervals for performance data

    return () => clearInterval(interval);
  }, [autoRefresh, selectedPeriod]);

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'efficiency': return 'text-blue-600 bg-blue-100 border-blue-200';
      case 'quality': return 'text-green-600 bg-green-100 border-green-200';
      case 'productivity': return 'text-purple-600 bg-purple-100 border-purple-200';
      case 'satisfaction': return 'text-orange-600 bg-orange-100 border-orange-200';
      default: return 'text-gray-600 bg-gray-100 border-gray-200';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'efficiency': return Clock;
      case 'quality': return Star;
      case 'productivity': return BarChart3;
      case 'satisfaction': return Award;
      default: return Target;
    }
  };

  const getTrendIcon = (trend: string, changePercent: number) => {
    if (trend === 'up') {
      return <TrendingUp className={`h-4 w-4 ${changePercent > 0 ? 'text-green-500' : 'text-red-500'}`} />;
    } else if (trend === 'down') {
      return <TrendingDown className={`h-4 w-4 ${changePercent < 0 ? 'text-red-500' : 'text-green-500'}`} />;
    }
    return <div className="w-4 h-4 bg-gray-300 rounded-full" />;
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'sec' || unit === 'seconds') return `${Math.round(value)}s`;
    if (unit === 'min' || unit === 'minutes') return `${Math.round(value)}m`;
    if (unit === 'score') return `${value.toFixed(1)}/10`;
    if (unit === 'rating') return `${value.toFixed(1)}/5`;
    return value.toLocaleString();
  };

  const getPerformanceRating = (value: number, target: number) => {
    const percentage = (value / target) * 100;
    if (percentage >= 95) return { rating: 'Excellent', color: 'text-green-600', bg: 'bg-green-100' };
    if (percentage >= 85) return { rating: 'Good', color: 'text-blue-600', bg: 'bg-blue-100' };
    if (percentage >= 70) return { rating: 'Average', color: 'text-yellow-600', bg: 'bg-yellow-100' };
    return { rating: 'Below Target', color: 'text-red-600', bg: 'bg-red-100' };
  };

  const handleExportReport = async () => {
    try {
      const result = await realPerformanceService.exportPerformanceReport(selectedPeriod, 'pdf');
      if (result.success && result.data) {
        window.open(result.data.downloadUrl, '_blank');
      } else {
        console.error('Export failed:', result.error);
      }
    } catch (error) {
      console.error('Export error:', error);
    }
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="p-6 space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1,2,3,4,5,6,7,8].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-24 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const overallMetrics = performanceData?.overallMetrics || [];
  const agentPerformance = performanceData?.agentPerformance || [];
  const teamPerformance = performanceData?.teamPerformance || [];

  const filteredMetrics = selectedCategory === 'all' 
    ? overallMetrics 
    : overallMetrics.filter(metric => metric.category === selectedCategory);

  return (
    <div className="p-6 space-y-6">
      {/* API Error Display */}
      {apiError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Operation Failed</div>
              <div className="text-sm">{apiError}</div>
            </div>
            <button
              onClick={loadPerformanceData}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Header with Controls */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <BarChart3 className="h-6 w-6 mr-2 text-purple-600" />
              Performance Metrics
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">📈</span>
              Comprehensive KPI tracking and analysis
            </p>
          </div>
          
          <div className="flex items-center space-x-4">
            {/* Period Selector */}
            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {periods.map(period => (
                <option key={period.value} value={period.value}>{period.label}</option>
              ))}
            </select>

            {/* Category Filter */}
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Categories</option>
              <option value="efficiency">Efficiency</option>
              <option value="quality">Quality</option>
              <option value="productivity">Productivity</option>
              <option value="satisfaction">Satisfaction</option>
            </select>

            {/* Export Button */}
            <button
              onClick={handleExportReport}
              className="flex items-center space-x-2 px-3 py-2 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
            >
              <Download className="h-4 w-4" />
              <span>Export</span>
            </button>

            {/* Auto-refresh Toggle */}
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm transition-colors ${
                autoRefresh ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
              }`}
            >
              <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
              <span>{autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}</span>
            </button>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
          <div className="flex items-center space-x-2">
            <Calendar className="h-4 w-4" />
            <span>Period: {periods.find(p => p.value === selectedPeriod)?.label}</span>
          </div>
          <div className={`flex items-center space-x-2 ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
            <span>Updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>

      {/* Performance Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {filteredMetrics.map((metric) => {
          const Icon = getCategoryIcon(metric.category);
          const rating = getPerformanceRating(metric.value, metric.target);
          
          return (
            <div 
              key={metric.id} 
              className={`bg-white rounded-lg shadow-sm border-2 p-6 transition-all hover:shadow-lg ${getCategoryColor(metric.category)}`}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-2">
                  <Icon className="h-6 w-6" />
                  <h3 className="font-semibold text-gray-900">{metric.name}</h3>
                </div>
                {getTrendIcon(metric.trend, metric.changePercent)}
              </div>
              
              <div className="mb-2">
                <div className="flex items-baseline space-x-2">
                  <span className="text-3xl font-bold text-gray-900">
                    {formatValue(metric.value, metric.unit)}
                  </span>
                  <span className="text-sm text-gray-600">
                    / {formatValue(metric.target, metric.unit)}
                  </span>
                </div>
              </div>

              <div className="mb-3">
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full transition-all duration-300 ${
                      rating.rating === 'Excellent' ? 'bg-green-500' :
                      rating.rating === 'Good' ? 'bg-blue-500' :
                      rating.rating === 'Average' ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ width: `${Math.min((metric.value / metric.target) * 100, 100)}%` }}
                  ></div>
                </div>
              </div>

              <div className="flex items-center justify-between text-sm mb-2">
                <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${rating.bg} ${rating.color}`}>
                  {rating.rating}
                </span>
                <span className={`font-medium ${
                  metric.changePercent > 0 ? 'text-green-600' : 
                  metric.changePercent < 0 ? 'text-red-600' : 'text-gray-600'
                }`}>
                  {metric.changePercent > 0 ? '+' : ''}{metric.changePercent.toFixed(1)}%
                </span>
              </div>

              <p className="text-xs text-gray-600">{metric.description}</p>
            </div>
          );
        })}
      </div>

      {/* Top Performers */}
      {agentPerformance.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Award className="h-5 w-5 mr-2" />
              Top Agent Performers
            </h3>
          </div>

          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {agentPerformance.slice(0, 6).map((agent, index) => (
                <div key={agent.agentId} className={`p-4 rounded-lg border-2 ${
                  index < 3 ? 'border-yellow-200 bg-yellow-50' : 'border-gray-200 bg-gray-50'
                }`}>
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center space-x-2">
                      {index < 3 && <Star className="h-4 w-4 text-yellow-500" />}
                      <span className="font-medium text-gray-900">{agent.agentName}</span>
                    </div>
                    <span className="text-sm text-gray-500">#{agent.rank}</span>
                  </div>
                  
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span>Calls Handled:</span>
                      <span className="font-medium">{agent.metrics.callsHandled}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>CSAT:</span>
                      <span className="font-medium">{agent.metrics.customerSatisfaction.toFixed(1)}/5</span>
                    </div>
                    <div className="flex justify-between">
                      <span>FCR:</span>
                      <span className="font-medium">{agent.metrics.firstCallResolution.toFixed(1)}%</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Utilization:</span>
                      <span className="font-medium">{agent.metrics.utilizationRate.toFixed(1)}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Team Performance */}
      {teamPerformance.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Users className="h-5 w-5 mr-2" />
              Team Performance Overview
            </h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Team</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Agents</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Efficiency</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">CSAT</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Utilization</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quality Score</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Target Achievement</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {teamPerformance.map((team) => (
                  <tr key={team.teamId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="font-medium text-gray-900">{team.teamName}</div>
                      <div className="text-sm text-gray-500">ID: {team.teamId}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {team.agentCount}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="w-16 bg-gray-200 rounded-full h-2 mr-2">
                          <div 
                            className={`h-2 rounded-full ${
                              team.metrics.teamEfficiency >= 90 ? 'bg-green-500' :
                              team.metrics.teamEfficiency >= 75 ? 'bg-yellow-500' : 'bg-red-500'
                            }`}
                            style={{ width: `${team.metrics.teamEfficiency}%` }}
                          ></div>
                        </div>
                        <span className="text-sm text-gray-900">{team.metrics.teamEfficiency.toFixed(1)}%</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {team.metrics.avgCustomerSatisfaction.toFixed(1)}/5
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {team.metrics.teamUtilization.toFixed(1)}%
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {team.metrics.qualityScore.toFixed(1)}/10
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                        team.metrics.targetAchievement >= 100 ? 'bg-green-100 text-green-800' :
                        team.metrics.targetAchievement >= 85 ? 'bg-yellow-100 text-yellow-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {team.metrics.targetAchievement.toFixed(1)}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Benchmarks */}
      {performanceData?.benchmarks && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <Target className="h-5 w-5 mr-2" />
            Performance Benchmarks
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{performanceData.benchmarks.industry.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Industry Average</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{performanceData.benchmarks.internal.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Internal Benchmark</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">{performanceData.benchmarks.target.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Target Goal</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PerformanceMetrics;