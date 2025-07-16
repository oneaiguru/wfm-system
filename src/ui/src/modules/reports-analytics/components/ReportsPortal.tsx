import React, { useState, useEffect } from 'react';
import ReportsDashboard from './dashboard/ReportsDashboard';
import ForecastAccuracyReport from './analytics/ForecastAccuracyReport';
import realReportsService, { ReportListItem, RealtimeMetrics } from '../../../services/realReportsService';

interface ReportsPortalProps {
  userId?: string;
}

const ReportsPortal: React.FC<ReportsPortalProps> = ({ userId = 'admin' }) => {
  const [activeView, setActiveView] = useState<'dashboard' | 'analytics' | 'reports' | 'builder'>('dashboard');
  const [reportsList, setReportsList] = useState<ReportListItem[]>([]);
  const [realtimeMetrics, setRealtimeMetrics] = useState<RealtimeMetrics | null>(null);
  const [apiError, setApiError] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);
  const [apiHealthy, setApiHealthy] = useState(false);

  // Load reports data on component mount
  useEffect(() => {
    loadReportsData();
    loadRealtimeMetrics();
    
    // Set up real-time metrics refresh
    const metricsInterval = setInterval(() => {
      loadRealtimeMetrics();
    }, 30000); // Refresh every 30 seconds
    
    return () => clearInterval(metricsInterval);
  }, []);

  const loadReportsData = async () => {
    setIsLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isHealthy = await realReportsService.checkApiHealth();
      setApiHealthy(isHealthy);
      
      if (!isHealthy) {
        throw new Error('Reports API server is not available. Please try again later.');
      }
      
      // Load reports list
      const result = await realReportsService.getReportsList();
      
      if (result.success && result.data) {
        setReportsList(result.data);
        console.log('[REAL REPORTS PORTAL] Loaded reports:', result.data);
      } else {
        setApiError(result.error || 'Failed to load reports list');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL REPORTS PORTAL] Error loading reports:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadRealtimeMetrics = async () => {
    try {
      const result = await realReportsService.getRealtimeMetrics();
      
      if (result.success && result.data) {
        setRealtimeMetrics(result.data);
      } else {
        console.warn('[REAL REPORTS PORTAL] Failed to load real-time metrics:', result.error);
      }
      
    } catch (error) {
      console.warn('[REAL REPORTS PORTAL] Error loading real-time metrics:', error);
    }
  };

  const renderContent = () => {
    switch (activeView) {
      case 'dashboard':
        return <ReportsDashboard />;
      case 'analytics':
        return <ForecastAccuracyReport />;
      case 'reports':
        return (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
              <div className="text-4xl mb-4">=�</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Custom Reports</h2>
              <p className="text-gray-600 mb-6">
                Advanced reporting capabilities with customizable templates, filters, and export options
              </p>
              {/* Real Reports List */}
              <div className="mb-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Available Reports</h3>
                {isLoading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    <span className="ml-2 text-gray-600">Loading reports...</span>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {reportsList.map((report) => (
                      <div key={report.report_id} className="p-4 bg-white border border-gray-200 rounded-lg hover:shadow-md transition-shadow">
                        <div className="flex items-start justify-between mb-2">
                          <h4 className="font-medium text-gray-900">{report.name}</h4>
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                            report.status === 'completed' ? 'bg-green-100 text-green-800' :
                            report.status === 'running' ? 'bg-blue-100 text-blue-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {report.status}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 mb-3">{report.description}</p>
                        <div className="flex items-center justify-between text-xs text-gray-500">
                          <span>Format: {report.format.toUpperCase()}</span>
                          <span>Size: {report.size_mb}MB</span>
                        </div>
                        <div className="mt-2 text-xs text-gray-500">
                          Last generated: {new Date(report.last_generated).toLocaleDateString()}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 bg-blue-50 rounded-lg">
                  <div className="text-2xl mb-2">📊</div>
                  <h3 className="font-medium text-blue-900">Performance Reports</h3>
                  <p className="text-sm text-blue-700">Schedule adherence, productivity metrics</p>
                </div>
                <div className="p-4 bg-green-50 rounded-lg">
                  <div className="text-2xl mb-2">📈</div>
                  <h3 className="font-medium text-green-900">Operational Reports</h3>
                  <p className="text-sm text-green-700">Staffing, coverage, utilization</p>
                </div>
                <div className="p-4 bg-purple-50 rounded-lg">
                  <div className="text-2xl mb-2">📋</div>
                  <h3 className="font-medium text-purple-900">Executive Reports</h3>
                  <p className="text-sm text-purple-700">KPIs, trends, strategic insights</p>
                </div>
              </div>
            </div>
          </div>
        );
      case 'builder':
        return (
          <div className="p-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
              <div className="text-4xl mb-4">=�</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Report Builder</h2>
              <p className="text-gray-600 mb-6">
                Drag-and-drop report builder with SQL query support and advanced visualization options
              </p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">=� Data Sources</h3>
                  <ul className="text-sm text-gray-600 space-y-1">
                    <li>" Employee schedules and attendance</li>
                    <li>" Forecast accuracy and MAPE metrics</li>
                    <li>" Request and approval workflows</li>
                    <li>" Performance and productivity data</li>
                  </ul>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2"><� Visualization Options</h3>
                  <ul className="text-sm text-gray-600 space-y-1">
                    <li>" Charts: Line, bar, pie, scatter</li>
                    <li>" Tables: Sortable, filterable, paginated</li>
                    <li>" Heatmaps and trend analysis</li>
                    <li>" Export: PDF, Excel, CSV formats</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        );
      default:
        return <ReportsDashboard />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Reports & Analytics</h1>
              <p className="text-sm text-gray-500 mt-1">
                Executive dashboards, real-time monitoring, and business intelligence
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full animate-pulse ${
                  apiHealthy ? 'bg-green-500' : 'bg-red-500'
                }`}></div>
                <span className="text-sm text-gray-600">
                  {apiHealthy ? 'Live Data' : 'API Offline'}
                </span>
              </div>
              <div className="text-sm text-gray-500">
                Last updated: {realtimeMetrics?.timestamp ? new Date(realtimeMetrics.timestamp).toLocaleTimeString() : new Date().toLocaleTimeString()}
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="px-6">
          <div className="flex space-x-8 border-b border-gray-200">
            {[
              { id: 'dashboard', label: 'Executive Dashboard', icon: '=�' },
              { id: 'analytics', label: 'Analytics', icon: '=�' },
              { id: 'reports', label: 'Reports', icon: '=�' },
              { id: 'builder', label: 'Report Builder', icon: '=�' }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveView(tab.id as any)}
                className={`flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm ${
                  activeView === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <span className="text-lg">{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* API Error Display */}
      {apiError && (
        <div className="mx-6 mt-4 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-center gap-2 text-red-800">
            <span className="text-red-500">❌</span>
            <div>
              <div className="font-medium">Reports API Error</div>
              <div className="text-sm">{apiError}</div>
            </div>
            <button
              onClick={loadReportsData}
              className="ml-auto px-3 py-1 bg-red-100 hover:bg-red-200 text-red-700 text-sm rounded transition-colors"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Main Content */}
      <main className="flex-1">
        {renderContent()}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-500">
            WFM Reports & Analytics " Powered by AI-driven insights
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🟢 System Status: {realtimeMetrics?.system_health.integration_status || 'Unknown'}</span>
            <span>📊 Database: {realtimeMetrics?.system_health.database_status || 'Unknown'}</span>
            <span>⚡ API Response: {realtimeMetrics?.system_health.api_response_time ? `${Math.round(realtimeMetrics.system_health.api_response_time)}ms` : 'Unknown'}</span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default ReportsPortal;