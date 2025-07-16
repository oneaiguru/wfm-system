import React, { useState, useEffect } from 'react';
import realReportsService, { ScheduleAdherenceReport, ForecastAccuracyReport } from '../../../../services/realReportsService';

export interface ReportBuilderProps {
  onReportGenerated?: (report: any) => void;
  onCancel?: () => void;
}

interface ReportConfig {
  type: 'schedule-adherence' | 'forecast-accuracy' | 'payroll' | 'overtime-analysis';
  period_start: string;
  period_end: string;
  department?: string;
  detail_level?: 'fifteen-minute' | 'hourly' | 'daily' | 'weekly' | 'monthly';
  include_weekends?: boolean;
  show_exceptions?: boolean;
  service_group?: string;
  format?: 'excel' | 'pdf' | 'csv' | 'json';
}

const ReportBuilder: React.FC<ReportBuilderProps> = ({ onReportGenerated, onCancel }) => {
  const [reportConfig, setReportConfig] = useState<ReportConfig>({
    type: 'schedule-adherence',
    period_start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 days ago
    period_end: new Date().toISOString().split('T')[0], // today
    department: 'Technical Support',
    detail_level: 'fifteen-minute',
    include_weekends: true,
    show_exceptions: true,
    format: 'excel'
  });

  const [isGenerating, setIsGenerating] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [generatedReport, setGeneratedReport] = useState<any>(null);
  const [apiHealthy, setApiHealthy] = useState(false);

  useEffect(() => {
    checkApiHealth();
  }, []);

  const checkApiHealth = async () => {
    try {
      const isHealthy = await realReportsService.checkApiHealth();
      setApiHealthy(isHealthy);
      if (!isHealthy) {
        setApiError('Reports API is not available. Please check the backend service.');
      }
    } catch (error) {
      setApiHealthy(false);
      setApiError('Failed to connect to Reports API');
    }
  };

  const handleConfigChange = (field: keyof ReportConfig, value: any) => {
    setReportConfig(prev => ({
      ...prev,
      [field]: value
    }));
    setApiError(''); // Clear error when user makes changes
  };

  const generateReport = async () => {
    setIsGenerating(true);
    setApiError('');
    setGeneratedReport(null);

    try {
      // Check API health first
      if (!apiHealthy) {
        const isHealthy = await realReportsService.checkApiHealth();
        if (!isHealthy) {
          throw new Error('Reports API server is not available. Please try again later.');
        }
        setApiHealthy(true);
      }

      console.log('[REAL REPORT BUILDER] Generating report:', reportConfig);

      let result;
      
      switch (reportConfig.type) {
        case 'schedule-adherence':
          result = await realReportsService.generateScheduleAdherenceReport({
            period_start: reportConfig.period_start,
            period_end: reportConfig.period_end,
            department: reportConfig.department,
            detail_level: reportConfig.detail_level,
            include_weekends: reportConfig.include_weekends,
            show_exceptions: reportConfig.show_exceptions
          });
          break;
          
        case 'forecast-accuracy':
          result = await realReportsService.getForecastAccuracyReport({
            period_start: reportConfig.period_start,
            period_end: reportConfig.period_end,
            service_group: reportConfig.service_group
          });
          break;
          
        default:
          throw new Error(`Report type '${reportConfig.type}' is not implemented yet`);
      }

      if (result.success && result.data) {
        setGeneratedReport(result.data);
        console.log('[REAL REPORT BUILDER] Report generated successfully:', result.data);
        
        if (onReportGenerated) {
          onReportGenerated(result.data);
        }
      } else {
        setApiError(result.error || 'Failed to generate report');
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL REPORT BUILDER] Error generating report:', error);
    } finally {
      setIsGenerating(false);
    }
  };

  const renderReportPreview = () => {
    if (!generatedReport) return null;

    return (
      <div className="mt-6 p-6 bg-gray-50 rounded-lg">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Generated Report Preview</h3>
        
        {reportConfig.type === 'schedule-adherence' && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">Average Adherence</div>
                <div className="text-xl font-bold text-blue-600">
                  {generatedReport.average_adherence?.toFixed(1)}%
                </div>
              </div>
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">Total Scheduled</div>
                <div className="text-xl font-bold text-green-600">
                  {generatedReport.total_scheduled_hours?.toFixed(0)}h
                </div>
              </div>
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">Total Actual</div>
                <div className="text-xl font-bold text-purple-600">
                  {generatedReport.total_actual_hours?.toFixed(0)}h
                </div>
              </div>
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">Employees</div>
                <div className="text-xl font-bold text-gray-700">
                  {generatedReport.employees?.length || 0}
                </div>
              </div>
            </div>
            
            {generatedReport.employees && generatedReport.employees.length > 0 && (
              <div className="bg-white rounded shadow-sm overflow-hidden">
                <div className="px-4 py-2 bg-gray-100 border-b">
                  <h4 className="font-medium text-gray-900">Employee Details</h4>
                </div>
                <div className="max-h-60 overflow-y-auto">
                  <table className="min-w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Employee</th>
                        <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Scheduled</th>
                        <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Actual</th>
                        <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Adherence</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {generatedReport.employees.slice(0, 5).map((emp: any, idx: number) => (
                        <tr key={idx}>
                          <td className="px-4 py-2 text-sm text-gray-900">{emp.employee_name}</td>
                          <td className="px-4 py-2 text-sm text-gray-600">{emp.scheduled_hours?.toFixed(1)}h</td>
                          <td className="px-4 py-2 text-sm text-gray-600">{emp.actual_hours?.toFixed(1)}h</td>
                          <td className="px-4 py-2 text-sm">
                            <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                              emp.adherence_percentage > 85 ? 'bg-green-100 text-green-800' :
                              emp.adherence_percentage > 70 ? 'bg-yellow-100 text-yellow-800' :
                              'bg-red-100 text-red-800'
                            }`}>
                              {emp.adherence_percentage?.toFixed(1)}%
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {generatedReport.employees.length > 5 && (
                    <div className="px-4 py-2 text-sm text-gray-500 bg-gray-50">
                      ... and {generatedReport.employees.length - 5} more employees
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {reportConfig.type === 'forecast-accuracy' && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">MAPE</div>
                <div className="text-xl font-bold text-blue-600">
                  {generatedReport.overall_metrics?.mape?.toFixed(1)}%
                </div>
              </div>
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">WAPE</div>
                <div className="text-xl font-bold text-green-600">
                  {generatedReport.overall_metrics?.wape?.toFixed(1)}%
                </div>
              </div>
              <div className="bg-white p-3 rounded shadow-sm">
                <div className="text-sm text-gray-500">Forecast Bias</div>
                <div className="text-xl font-bold text-purple-600">
                  {generatedReport.overall_metrics?.bias?.toFixed(1)}%
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="mt-4 flex justify-end space-x-3">
          <button
            onClick={() => console.log('Export functionality not implemented yet')}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
          >
            Export Report
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Report Builder</h1>
              <p className="text-sm text-gray-500 mt-1">
                Create custom reports with real-time data from the WFM system
              </p>
            </div>
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${apiHealthy ? 'bg-green-500' : 'bg-red-500'}`}></div>
              <span className="text-sm text-gray-600">
                API {apiHealthy ? 'Connected' : 'Offline'}
              </span>
            </div>
          </div>
        </div>

        {/* Configuration Form */}
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Report Type */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Report Type
              </label>
              <select
                value={reportConfig.type}
                onChange={(e) => handleConfigChange('type', e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="schedule-adherence">Schedule Adherence Report</option>
                <option value="forecast-accuracy">Forecast Accuracy Analysis</option>
                <option value="payroll">Payroll Report (Coming Soon)</option>
                <option value="overtime-analysis">Overtime Analysis (Coming Soon)</option>
              </select>
            </div>

            {/* Department */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Department
              </label>
              <select
                value={reportConfig.department}
                onChange={(e) => handleConfigChange('department', e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="Technical Support">Technical Support</option>
                <option value="Sales">Sales</option>
                <option value="Customer Service">Customer Service</option>
                <option value="All Departments">All Departments</option>
              </select>
            </div>

            {/* Period Start */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Period Start
              </label>
              <input
                type="date"
                value={reportConfig.period_start}
                onChange={(e) => handleConfigChange('period_start', e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Period End */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Period End
              </label>
              <input
                type="date"
                value={reportConfig.period_end}
                onChange={(e) => handleConfigChange('period_end', e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Detail Level (for schedule adherence) */}
            {reportConfig.type === 'schedule-adherence' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Detail Level
                </label>
                <select
                  value={reportConfig.detail_level}
                  onChange={(e) => handleConfigChange('detail_level', e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="fifteen-minute">15-minute intervals</option>
                  <option value="hourly">Hourly</option>
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
            )}

            {/* Service Group (for forecast accuracy) */}
            {reportConfig.type === 'forecast-accuracy' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Service Group (Optional)
                </label>
                <input
                  type="text"
                  placeholder="e.g., Technical Support"
                  value={reportConfig.service_group || ''}
                  onChange={(e) => handleConfigChange('service_group', e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            )}
          </div>

          {/* Options (for schedule adherence) */}
          {reportConfig.type === 'schedule-adherence' && (
            <div className="mt-6">
              <label className="block text-sm font-medium text-gray-700 mb-3">Options</label>
              <div className="flex space-x-6">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={reportConfig.include_weekends}
                    onChange={(e) => handleConfigChange('include_weekends', e.target.checked)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Include weekends</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={reportConfig.show_exceptions}
                    onChange={(e) => handleConfigChange('show_exceptions', e.target.checked)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Show exceptions</span>
                </label>
              </div>
            </div>
          )}
        </div>

        {/* API Error Display */}
        {apiError && (
          <div className="mx-6 mb-6 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-center gap-2 text-red-800">
              <span className="text-red-500">❌</span>
              <div>
                <div className="font-medium">Report Generation Failed</div>
                <div className="text-sm">{apiError}</div>
              </div>
              <button
                onClick={checkApiHealth}
                className="ml-auto px-3 py-1 bg-red-100 hover:bg-red-200 text-red-700 text-sm rounded transition-colors"
              >
                Retry
              </button>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-between">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={generateReport}
            disabled={isGenerating || !apiHealthy}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center"
          >
            {isGenerating ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Generating...
              </>
            ) : (
              'Generate Report'
            )}
          </button>
        </div>

        {/* Report Preview */}
        {renderReportPreview()}
      </div>
    </div>
  );
};

export default ReportBuilder;