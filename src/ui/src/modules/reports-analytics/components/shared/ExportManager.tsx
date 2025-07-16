import React, { useState, useEffect } from 'react';
import realReportsService, { ExportJob, ExportRequest } from '../../../../services/realReportsService';

export interface ExportManagerProps {
  onExportComplete?: (job: ExportJob) => void;
  initialReportType?: string;
}

const ExportManager: React.FC<ExportManagerProps> = ({ onExportComplete, initialReportType }) => {
  const [exportJobs, setExportJobs] = useState<ExportJob[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [apiHealthy, setApiHealthy] = useState(false);
  const [showNewExportForm, setShowNewExportForm] = useState(false);
  
  // New export form state
  const [exportForm, setExportForm] = useState<ExportRequest>({
    report_type: (initialReportType as any) || 'schedule-adherence',
    format: 'excel',
    parameters: {},
    email_recipient: '',
    include_charts: true,
    compress_file: false
  });

  useEffect(() => {
    loadExportJobs();
    checkApiHealth();
    
    // Poll for job status updates every 10 seconds
    const pollInterval = setInterval(() => {
      loadExportJobs();
    }, 10000);

    return () => clearInterval(pollInterval);
  }, []);

  const checkApiHealth = async () => {
    try {
      const isHealthy = await realReportsService.checkApiHealth();
      setApiHealthy(isHealthy);
      if (!isHealthy) {
        setApiError('Export API is not available. Please check the backend service.');
      }
    } catch (error) {
      setApiHealthy(false);
      setApiError('Failed to connect to Export API');
    }
  };

  const loadExportJobs = async () => {
    try {
      const result = await realReportsService.getExportJobs(20);
      
      if (result.success && result.data) {
        setExportJobs(result.data);
        setApiError(''); // Clear any previous errors
      } else {
        console.warn('[EXPORT MANAGER] Failed to load export jobs:', result.error);
      }
    } catch (error) {
      console.error('[EXPORT MANAGER] Error loading export jobs:', error);
    }
  };

  const createExportJob = async () => {
    setIsLoading(true);
    setApiError('');

    try {
      // Check API health first
      if (!apiHealthy) {
        const isHealthy = await realReportsService.checkApiHealth();
        if (!isHealthy) {
          throw new Error('Export API server is not available. Please try again later.');
        }
        setApiHealthy(true);
      }

      console.log('[EXPORT MANAGER] Creating export job:', exportForm);

      const result = await realReportsService.createExportJob(exportForm);

      if (result.success && result.data) {
        console.log('[EXPORT MANAGER] Export job created:', result.data);
        
        // Add new job to the list
        setExportJobs(prev => [result.data!, ...prev]);
        
        // Reset form and hide it
        setShowNewExportForm(false);
        setExportForm({
          report_type: 'schedule-adherence',
          format: 'excel',
          parameters: {},
          email_recipient: '',
          include_charts: true,
          compress_file: false
        });

        if (onExportComplete) {
          onExportComplete(result.data);
        }
      } else {
        setApiError(result.error || 'Failed to create export job');
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[EXPORT MANAGER] Error creating export job:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const downloadFile = async (job: ExportJob) => {
    try {
      await realReportsService.downloadExportFile(job.job_id);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Download failed';
      setApiError(errorMessage);
    }
  };

  const cancelJob = async (jobId: string) => {
    try {
      const result = await realReportsService.cancelExportJob(jobId);
      
      if (result.success) {
        // Update job status in the list
        setExportJobs(prev => prev.map(job => 
          job.job_id === jobId 
            ? { ...job, status: 'failed', error_message: 'Cancelled by user' }
            : job
        ));
      } else {
        setApiError(result.error || 'Failed to cancel job');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Cancel failed';
      setApiError(errorMessage);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'processing': return 'bg-blue-100 text-blue-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'failed': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return '✅';
      case 'processing': return '⏳';
      case 'pending': return '⏸️';
      case 'failed': return '❌';
      default: return '❓';
    }
  };

  const renderNewExportForm = () => {
    if (!showNewExportForm) return null;

    return (
      <div className="bg-white border border-gray-200 rounded-lg p-6 mb-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Create New Export</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Report Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Report Type
            </label>
            <select
              value={exportForm.report_type}
              onChange={(e) => setExportForm(prev => ({ ...prev, report_type: e.target.value as any }))}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="schedule-adherence">Schedule Adherence Report</option>
              <option value="forecast-accuracy">Forecast Accuracy Analysis</option>
              <option value="payroll">Payroll Report</option>
              <option value="kpi-dashboard">KPI Dashboard</option>
              <option value="real-time">Real-time Metrics</option>
            </select>
          </div>

          {/* Format */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Export Format
            </label>
            <select
              value={exportForm.format}
              onChange={(e) => setExportForm(prev => ({ ...prev, format: e.target.value as any }))}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="excel">Excel (.xlsx)</option>
              <option value="pdf">PDF (.pdf)</option>
              <option value="csv">CSV (.csv)</option>
              <option value="json">JSON (.json)</option>
            </select>
          </div>

          {/* Email Recipient */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Email Recipient (Optional)
            </label>
            <input
              type="email"
              placeholder="user@company.com"
              value={exportForm.email_recipient}
              onChange={(e) => setExportForm(prev => ({ ...prev, email_recipient: e.target.value }))}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Date Range - simplified for demo */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date Range
            </label>
            <select
              onChange={(e) => {
                const value = e.target.value;
                const now = new Date();
                let startDate: Date;
                
                switch (value) {
                  case 'last-7-days':
                    startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                    break;
                  case 'last-30-days':
                    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                    break;
                  case 'current-month':
                    startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                    break;
                  case 'last-month':
                    startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
                    break;
                  default:
                    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                }
                
                setExportForm(prev => ({ 
                  ...prev, 
                  parameters: { 
                    ...prev.parameters,
                    period_start: startDate.toISOString().split('T')[0],
                    period_end: now.toISOString().split('T')[0]
                  } 
                }));\n              }}\n              className=\"w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500\"\n            >\n              <option value=\"last-7-days\">Last 7 days</option>\n              <option value=\"last-30-days\">Last 30 days</option>\n              <option value=\"current-month\">Current month</option>\n              <option value=\"last-month\">Last month</option>\n            </select>\n          </div>\n        </div>\n\n        {/* Options */}\n        <div className=\"mt-4\">\n          <label className=\"block text-sm font-medium text-gray-700 mb-3\">Options</label>\n          <div className=\"flex space-x-6\">\n            <label className=\"flex items-center\">\n              <input\n                type=\"checkbox\"\n                checked={exportForm.include_charts}\n                onChange={(e) => setExportForm(prev => ({ ...prev, include_charts: e.target.checked }))}\n                className=\"h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded\"\n              />\n              <span className=\"ml-2 text-sm text-gray-700\">Include charts and visualizations</span>\n            </label>\n            <label className=\"flex items-center\">\n              <input\n                type=\"checkbox\"\n                checked={exportForm.compress_file}\n                onChange={(e) => setExportForm(prev => ({ ...prev, compress_file: e.target.checked }))}\n                className=\"h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded\"\n              />\n              <span className=\"ml-2 text-sm text-gray-700\">Compress file (ZIP)</span>\n            </label>\n          </div>\n        </div>\n\n        {/* Actions */}\n        <div className=\"mt-6 flex justify-end space-x-3\">\n          <button\n            onClick={() => setShowNewExportForm(false)}\n            className=\"px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors\"\n          >\n            Cancel\n          </button>\n          <button\n            onClick={createExportJob}\n            disabled={isLoading || !apiHealthy}\n            className=\"px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center\"\n          >\n            {isLoading ? (\n              <>\n                <div className=\"animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2\"></div>\n                Creating...\n              </>\n            ) : (\n              'Create Export'\n            )}\n          </button>\n        </div>\n      </div>\n    );\n  };\n\n  return (\n    <div className=\"max-w-6xl mx-auto p-6\">\n      <div className=\"bg-white rounded-lg shadow-sm border border-gray-200\">\n        {/* Header */}\n        <div className=\"px-6 py-4 border-b border-gray-200\">\n          <div className=\"flex items-center justify-between\">\n            <div>\n              <h1 className=\"text-2xl font-bold text-gray-900\">Export Manager</h1>\n              <p className=\"text-sm text-gray-500 mt-1\">\n                Create and manage report exports with real backend processing\n              </p>\n            </div>\n            <div className=\"flex items-center space-x-4\">\n              <div className=\"flex items-center space-x-2\">\n                <div className={`w-2 h-2 rounded-full ${apiHealthy ? 'bg-green-500' : 'bg-red-500'}`}></div>\n                <span className=\"text-sm text-gray-600\">\n                  Export API {apiHealthy ? 'Connected' : 'Offline'}\n                </span>\n              </div>\n              <button\n                onClick={() => setShowNewExportForm(true)}\n                disabled={!apiHealthy}\n                className=\"px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors\"\n              >\n                New Export\n              </button>\n            </div>\n          </div>\n        </div>\n\n        {/* API Error Display */}\n        {apiError && (\n          <div className=\"mx-6 mt-4 px-6 py-3 bg-red-50 border border-red-200 rounded-lg\">\n            <div className=\"flex items-center gap-2 text-red-800\">\n              <span className=\"text-red-500\">❌</span>\n              <div>\n                <div className=\"font-medium\">Export Operation Failed</div>\n                <div className=\"text-sm\">{apiError}</div>\n              </div>\n              <button\n                onClick={checkApiHealth}\n                className=\"ml-auto px-3 py-1 bg-red-100 hover:bg-red-200 text-red-700 text-sm rounded transition-colors\"\n              >\n                Retry\n              </button>\n            </div>\n          </div>\n        )}\n\n        <div className=\"p-6\">\n          {/* New Export Form */}\n          {renderNewExportForm()}\n\n          {/* Export Jobs List */}\n          <div>\n            <div className=\"flex items-center justify-between mb-4\">\n              <h2 className=\"text-lg font-medium text-gray-900\">Export Jobs</h2>\n              <button\n                onClick={loadExportJobs}\n                className=\"text-sm text-blue-600 hover:text-blue-700\"\n              >\n                Refresh\n              </button>\n            </div>\n\n            {exportJobs.length === 0 ? (\n              <div className=\"text-center py-8 text-gray-500\">\n                <div className=\"text-4xl mb-2\">📂</div>\n                <div>No export jobs found</div>\n                <div className=\"text-sm\">Create your first export to get started</div>\n              </div>\n            ) : (\n              <div className=\"space-y-3\">\n                {exportJobs.map((job) => (\n                  <div key={job.job_id} className=\"border border-gray-200 rounded-lg p-4\">\n                    <div className=\"flex items-center justify-between\">\n                      <div className=\"flex-1\">\n                        <div className=\"flex items-center space-x-3\">\n                          <span className=\"text-lg\">{getStatusIcon(job.status)}</span>\n                          <div>\n                            <div className=\"font-medium text-gray-900\">\n                              {job.report_type.replace('-', ' ').replace(/\\b\\w/g, l => l.toUpperCase())} Export\n                            </div>\n                            <div className=\"text-sm text-gray-500\">\n                              Format: {job.format.toUpperCase()} • \n                              Created: {new Date(job.created_at).toLocaleString()}\n                              {job.completed_at && (\n                                <> • Completed: {new Date(job.completed_at).toLocaleString()}</>\n                              )}\n                            </div>\n                          </div>\n                        </div>\n                        {job.error_message && (\n                          <div className=\"mt-2 text-sm text-red-600\">\n                            Error: {job.error_message}\n                          </div>\n                        )}\n                      </div>\n                      \n                      <div className=\"flex items-center space-x-3\">\n                        <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(job.status)}`}>\n                          {job.status}\n                        </span>\n                        \n                        {job.file_size_mb && (\n                          <span className=\"text-sm text-gray-500\">\n                            {job.file_size_mb.toFixed(1)} MB\n                          </span>\n                        )}\n                        \n                        <div className=\"flex space-x-2\">\n                          {job.status === 'completed' && job.file_url && (\n                            <button\n                              onClick={() => downloadFile(job)}\n                              className=\"px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 transition-colors\"\n                            >\n                              Download\n                            </button>\n                          )}\n                          \n                          {(job.status === 'pending' || job.status === 'processing') && (\n                            <button\n                              onClick={() => cancelJob(job.job_id)}\n                              className=\"px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition-colors\"\n                            >\n                              Cancel\n                            </button>\n                          )}\n                        </div>\n                      </div>\n                    </div>\n                  </div>\n                ))}\n              </div>\n            )}\n          </div>\n        </div>\n      </div>\n    </div>\n  );\n};\n\nexport default ExportManager;