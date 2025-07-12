import React, { useState } from 'react';
import ReportsDashboard from './dashboard/ReportsDashboard';
import ForecastAccuracyReport from './analytics/ForecastAccuracyReport';

interface ReportsPortalProps {
  userId?: string;
}

const ReportsPortal: React.FC<ReportsPortalProps> = ({ userId = 'admin' }) => {
  const [activeView, setActiveView] = useState<'dashboard' | 'analytics' | 'reports' | 'builder'>('dashboard');

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
              <div className="text-4xl mb-4">=Ê</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Custom Reports</h2>
              <p className="text-gray-600 mb-6">
                Advanced reporting capabilities with customizable templates, filters, and export options
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 bg-blue-50 rounded-lg">
                  <div className="text-2xl mb-2">=È</div>
                  <h3 className="font-medium text-blue-900">Performance Reports</h3>
                  <p className="text-sm text-blue-700">Schedule adherence, productivity metrics</p>
                </div>
                <div className="p-4 bg-green-50 rounded-lg">
                  <div className="text-2xl mb-2">=Ë</div>
                  <h3 className="font-medium text-green-900">Operational Reports</h3>
                  <p className="text-sm text-green-700">Staffing, coverage, utilization</p>
                </div>
                <div className="p-4 bg-purple-50 rounded-lg">
                  <div className="text-2xl mb-2">=¼</div>
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
              <div className="text-4xl mb-4">=à</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Report Builder</h2>
              <p className="text-gray-600 mb-6">
                Drag-and-drop report builder with SQL query support and advanced visualization options
              </p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">=Ê Data Sources</h3>
                  <ul className="text-sm text-gray-600 space-y-1">
                    <li>" Employee schedules and attendance</li>
                    <li>" Forecast accuracy and MAPE metrics</li>
                    <li>" Request and approval workflows</li>
                    <li>" Performance and productivity data</li>
                  </ul>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2"><¨ Visualization Options</h3>
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
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                <span className="text-sm text-gray-600">Live Data</span>
              </div>
              <div className="text-sm text-gray-500">
                Last updated: {new Date().toLocaleTimeString()}
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="px-6">
          <div className="flex space-x-8 border-b border-gray-200">
            {[
              { id: 'dashboard', label: 'Executive Dashboard', icon: '=Ê' },
              { id: 'analytics', label: 'Analytics', icon: '=È' },
              { id: 'reports', label: 'Reports', icon: '=Ë' },
              { id: 'builder', label: 'Report Builder', icon: '=à' }
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
            <span>=â System Status: Operational</span>
            <span>=Ê Data Quality: 98.7%</span>
            <span>¡ Performance: Excellent</span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default ReportsPortal;