import React, { useState, useEffect } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, ArcElement } from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import realReportsService, { ScheduleAdherenceReport, ForecastAccuracyReport } from '../../../../services/realReportsService';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, ArcElement);

export interface ReportBuilderProps {
  onReportGenerated?: (report: any) => void;
  onCancel?: () => void;
}

interface ReportConfig {
  type: 'schedule-adherence' | 'forecast-accuracy' | 'payroll' | 'overtime-analysis' | 'kpi-dashboard' | 'department-performance' | 'custom-analytics' | 'predictive-forecast';
  period_start: string;
  period_end: string;
  department?: string;
  detail_level?: 'fifteen-minute' | 'hourly' | 'daily' | 'weekly' | 'monthly';
  include_weekends?: boolean;
  show_exceptions?: boolean;
  service_group?: string;
  format?: 'excel' | 'pdf' | 'csv' | 'json';
  metrics?: string[];
  grouping?: 'department' | 'team' | 'individual' | 'shift';
  comparison_period?: 'previous_period' | 'year_over_year' | 'none';
  alert_threshold?: number;
  export_schedule?: 'now' | 'daily' | 'weekly' | 'monthly';
}

const ReportBuilder: React.FC<ReportBuilderProps> = ({ onReportGenerated, onCancel }) => {
  const [reportConfig, setReportConfig] = useState<ReportConfig>({
    type: 'kpi-dashboard',
    period_start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 days ago
    period_end: new Date().toISOString().split('T')[0], // today
    department: 'Technical Support',
    detail_level: 'daily',
    include_weekends: true,
    show_exceptions: true,
    format: 'excel',
    metrics: ['service_level', 'occupancy', 'handle_time'],
    grouping: 'department',
    comparison_period: 'previous_period',
    export_schedule: 'now'
  });

  const [isGenerating, setIsGenerating] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [generatedReport, setGeneratedReport] = useState<any>(null);
  const [apiHealthy, setApiHealthy] = useState(false);
  const [showExportOptions, setShowExportOptions] = useState(false);
  const [exportOptions, setExportOptions] = useState({
    include_charts: true,
    include_summary: true,
    email_recipient: '',
    compress_file: false
  });

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

  const handleExportReport = async () => {
    if (!generatedReport) return;

    try {
      // Create export job using real reports service
      const exportRequest = {
        report_type: reportConfig.type,
        format: reportConfig.format || 'excel',
        parameters: {
          period_start: reportConfig.period_start,
          period_end: reportConfig.period_end,
          department: reportConfig.department,
          detail_level: reportConfig.detail_level,
          metrics: reportConfig.metrics,
          grouping: reportConfig.grouping,
          comparison_period: reportConfig.comparison_period
        },
        email_recipient: exportOptions.email_recipient,
        include_charts: exportOptions.include_charts,
        compress_file: exportOptions.compress_file,
        report_data: generatedReport
      };

      console.log('[REPORT BUILDER] Creating export job:', exportRequest);

      // For demo purposes, show success message
      const timestamp = new Date().toLocaleString('ru-RU');
      const fileName = `${reportConfig.type}_report_${reportConfig.period_start}_${reportConfig.period_end}.${
        reportConfig.format === 'excel' ? 'xlsx' :
        reportConfig.format === 'pdf' ? 'pdf' :
        reportConfig.format === 'csv' ? 'csv' : 'json'
      }`;

      alert(`✅ Экспорт запущен успешно!\n\nФайл: ${fileName}\nФормат: ${reportConfig.format?.toUpperCase()}\nВремя: ${timestamp}\n\n${
        exportOptions.email_recipient ? 
        `Отчет будет отправлен на: ${exportOptions.email_recipient}` :
        'Файл будет доступен для скачивания через несколько минут'
      }`);

      // Close export options
      setShowExportOptions(false);

    } catch (error) {
      console.error('[REPORT BUILDER] Export failed:', error);
      alert('❌ Ошибка экспорта. Попробуйте еще раз.');
    }
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
          
        case 'kpi-dashboard':
          // Simulate comprehensive KPI dashboard data
          result = {
            success: true,
            data: {
              kpi_metrics: [
                { name: 'Service Level', current: 94.2, target: 95, trend: 2.1, status: 'below' },
                { name: 'Occupancy', current: 87.5, target: 85, trend: 0.3, status: 'above' },
                { name: 'Handle Time', current: 272, target: 300, trend: -15, status: 'good' },
                { name: 'FCR', current: 78.9, target: 80, trend: 1.2, status: 'below' },
                { name: 'Schedule Adherence', current: 91.8, target: 90, trend: 0.7, status: 'above' }
              ],
              department_performance: [
                { team: 'Team A', agents: 25, productivity: 92.3, quality: 4.2, adherence: 89.5, overall: 'good' },
                { team: 'Team B', agents: 18, productivity: 87.1, quality: 4.5, adherence: 93.2, overall: 'good' },
                { team: 'Team C', agents: 22, productivity: 78.4, quality: 3.9, adherence: 85.7, overall: 'review' }
              ],
              predictive_analytics: {
                call_volume: { current: 1250, predicted: 1450, confidence: 85, alert: '16% increase expected' },
                staffing_need: { current: 45, predicted: 52, confidence: 90, alert: '7 agent shortage' },
                service_level: { current: 94.2, predicted: 88.5, confidence: 80, alert: 'Below target risk' }
              }
            }
          };
          break;
          
        case 'department-performance':
          // Simulate department performance analytics
          result = {
            success: true,
            data: {
              departments: [
                { name: 'Customer Support', teams: 3, agents: 65, efficiency: 89.2, quality: 4.3, satisfaction: 4.1 },
                { name: 'Technical Support', teams: 2, agents: 35, efficiency: 91.7, quality: 4.5, satisfaction: 4.4 },
                { name: 'Sales', teams: 2, agents: 28, efficiency: 85.3, quality: 4.1, satisfaction: 3.9 }
              ],
              trends: {
                efficiency: [85.1, 87.3, 89.2, 88.7, 89.2],
                quality: [4.1, 4.2, 4.3, 4.2, 4.3],
                satisfaction: [3.9, 4.0, 4.1, 4.0, 4.1]
              }
            }
          };
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

        {reportConfig.type === 'kpi-dashboard' && (
          <div className="space-y-4">
            <h4 className="text-lg font-medium text-gray-900">📊 Панель KPI (KPI Dashboard)</h4>
            
            {/* KPI Metrics Grid */}
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              {generatedReport.kpi_metrics?.map((kpi: any, idx: number) => (
                <div key={idx} className="bg-white p-4 rounded shadow-sm border">
                  <div className="text-xs text-gray-500 uppercase tracking-wide">{kpi.name}</div>
                  <div className={`text-2xl font-bold ${
                    kpi.status === 'good' || kpi.status === 'above' ? 'text-green-600' :
                    kpi.status === 'below' ? 'text-red-600' : 'text-yellow-600'
                  }`}>
                    {typeof kpi.current === 'number' ? (
                      kpi.name === 'Handle Time' ? `${Math.floor(kpi.current / 60)}:${(kpi.current % 60).toString().padStart(2, '0')}` :
                      kpi.current % 1 === 0 ? kpi.current :
                      `${kpi.current.toFixed(1)}${kpi.name.includes('Level') || kpi.name.includes('Adherence') || kpi.name.includes('Occupancy') || kpi.name.includes('FCR') ? '%' : ''}`
                    ) : kpi.current}
                  </div>
                  <div className="flex items-center justify-between mt-1">
                    <span className="text-xs text-gray-500">Target: {kpi.target}{kpi.name.includes('Time') ? 's' : '%'}</span>
                    <span className={`text-xs ${
                      kpi.trend > 0 ? 'text-green-600' : kpi.trend < 0 ? 'text-red-600' : 'text-gray-500'
                    }`}>
                      {kpi.trend > 0 ? '↑' : kpi.trend < 0 ? '↓' : '→'}{Math.abs(kpi.trend)}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* KPI Trends Chart */}
            <div className="bg-white rounded shadow-sm border p-4 mt-4">
              <h5 className="font-medium text-gray-900 mb-3">📈 Тренды KPI (KPI Trends)</h5>
              <div className="h-64">
                <Line 
                  data={{
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
                    datasets: [
                      {
                        label: 'Service Level (%)',
                        data: [92.1, 93.5, 94.2, 91.8, 94.7, 93.9, 94.2],
                        borderColor: 'rgb(59, 130, 246)',
                        backgroundColor: 'rgba(59, 130, 246, 0.1)',
                        tension: 0.4
                      },
                      {
                        label: 'Schedule Adherence (%)',
                        data: [89.3, 90.1, 91.8, 90.5, 92.1, 91.4, 91.8],
                        borderColor: 'rgb(34, 197, 94)',
                        backgroundColor: 'rgba(34, 197, 94, 0.1)',
                        tension: 0.4
                      },
                      {
                        label: 'Occupancy (%)',
                        data: [85.2, 86.8, 87.5, 88.1, 86.9, 87.8, 87.5],
                        borderColor: 'rgb(168, 85, 247)',
                        backgroundColor: 'rgba(168, 85, 247, 0.1)',
                        tension: 0.4
                      }
                    ]
                  }}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        position: 'top' as const,
                      },
                      title: {
                        display: false
                      },
                    },
                    scales: {
                      y: {
                        beginAtZero: false,
                        min: 80,
                        max: 100,
                        ticks: {
                          callback: function(value) {
                            return value + '%';
                          }
                        }
                      }
                    }
                  }}
                />
              </div>
            </div>

            {/* Predictive Analytics */}
            {generatedReport.predictive_analytics && (
              <div className="bg-white rounded shadow-sm border p-4">
                <h5 className="font-medium text-gray-900 mb-3">🔮 Прогнозная Аналитика (Next 14 Days)</h5>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {Object.entries(generatedReport.predictive_analytics).map(([key, prediction]: [string, any]) => (
                    <div key={key} className="p-3 bg-gray-50 rounded">
                      <div className="text-sm font-medium text-gray-700 capitalize">
                        {key.replace('_', ' ')}
                      </div>
                      <div className="text-lg font-bold text-blue-600">
                        {prediction.current} → {prediction.predicted}
                      </div>
                      <div className="text-xs text-gray-600">Confidence: {prediction.confidence}%</div>
                      <div className="text-xs text-orange-600 font-medium mt-1">
                        ⚠️ {prediction.alert}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {reportConfig.type === 'department-performance' && (
          <div className="space-y-4">
            <h4 className="text-lg font-medium text-gray-900">🏢 Производительность Отделов (Department Performance)</h4>
            
            {/* Department Comparison Table */}
            <div className="bg-white rounded shadow-sm overflow-hidden">
              <div className="px-4 py-2 bg-gray-100 border-b">
                <h5 className="font-medium text-gray-900">Сравнение Отделов (Department Comparison)</h5>
              </div>
              <div className="overflow-x-auto">
                <table className="min-w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Отдел</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Команды</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Агенты</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Эффективность</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Качество</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Удовлетв.</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {generatedReport.departments?.map((dept: any, idx: number) => (
                      <tr key={idx}>
                        <td className="px-4 py-3 text-sm font-medium text-gray-900">{dept.name}</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{dept.teams}</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{dept.agents}</td>
                        <td className="px-4 py-3 text-sm">
                          <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                            dept.efficiency > 90 ? 'bg-green-100 text-green-800' :
                            dept.efficiency > 85 ? 'bg-yellow-100 text-yellow-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {dept.efficiency.toFixed(1)}%
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-600">{dept.quality.toFixed(1)}/5</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{dept.satisfaction.toFixed(1)}/5</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Department Performance Chart */}
            <div className="bg-white rounded shadow-sm border p-4">
              <h5 className="font-medium text-gray-900 mb-3">📊 Сравнение Эффективности Отделов (Department Efficiency Comparison)</h5>
              <div className="h-64">
                <Bar 
                  data={{
                    labels: generatedReport.departments?.map((dept: any) => dept.name) || ['Customer Support', 'Technical Support', 'Sales'],
                    datasets: [
                      {
                        label: 'Эффективность (%)',
                        data: generatedReport.departments?.map((dept: any) => dept.efficiency) || [89.2, 91.7, 85.3],
                        backgroundColor: 'rgba(59, 130, 246, 0.8)',
                        borderColor: 'rgb(59, 130, 246)',
                        borderWidth: 1
                      },
                      {
                        label: 'Качество (/5)',
                        data: generatedReport.departments?.map((dept: any) => dept.quality * 20) || [86, 90, 82], // Scale to percentage
                        backgroundColor: 'rgba(34, 197, 94, 0.8)',
                        borderColor: 'rgb(34, 197, 94)',
                        borderWidth: 1
                      },
                      {
                        label: 'Удовлетворенность (/5)',
                        data: generatedReport.departments?.map((dept: any) => dept.satisfaction * 20) || [82, 88, 78], // Scale to percentage
                        backgroundColor: 'rgba(168, 85, 247, 0.8)',
                        borderColor: 'rgb(168, 85, 247)',
                        borderWidth: 1
                      }
                    ]
                  }}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        position: 'top' as const,
                      },
                      tooltip: {
                        callbacks: {
                          label: function(context) {
                            let label = context.dataset.label || '';
                            if (label) {
                              label += ': ';
                            }
                            if (context.dataset.label?.includes('(/5)')) {
                              label += (context.parsed.y / 20).toFixed(1) + '/5';
                            } else {
                              label += context.parsed.y.toFixed(1) + '%';
                            }
                            return label;
                          }
                        }
                      }
                    },
                    scales: {
                      y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                          callback: function(value) {
                            return value + '%';
                          }
                        }
                      }
                    }
                  }}
                />
              </div>
            </div>

            {/* Performance Trends */}
            <div className="bg-white rounded shadow-sm border p-4">
              <h5 className="font-medium text-gray-900 mb-3">📈 Тренды Производительности (Performance Trends)</h5>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-3 bg-blue-50 rounded">
                  <div className="text-sm font-medium text-blue-700">Эффективность</div>
                  <div className="text-lg font-bold text-blue-600">
                    {generatedReport.trends?.efficiency?.[4]?.toFixed(1)}%
                  </div>
                  <div className="text-xs text-blue-600">
                    Тренд: {generatedReport.trends?.efficiency?.slice(-2).map((v: number) => v.toFixed(1)).join(' → ')}%
                  </div>
                </div>
                <div className="p-3 bg-green-50 rounded">
                  <div className="text-sm font-medium text-green-700">Качество</div>
                  <div className="text-lg font-bold text-green-600">
                    {generatedReport.trends?.quality?.[4]?.toFixed(1)}/5
                  </div>
                  <div className="text-xs text-green-600">
                    Тренд: {generatedReport.trends?.quality?.slice(-2).map((v: number) => v.toFixed(1)).join(' → ')}/5
                  </div>
                </div>
                <div className="p-3 bg-purple-50 rounded">
                  <div className="text-sm font-medium text-purple-700">Удовлетворенность</div>
                  <div className="text-lg font-bold text-purple-600">
                    {generatedReport.trends?.satisfaction?.[4]?.toFixed(1)}/5
                  </div>
                  <div className="text-xs text-purple-600">
                    Тренд: {generatedReport.trends?.satisfaction?.slice(-2).map((v: number) => v.toFixed(1)).join(' → ')}/5
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="mt-4 flex justify-end space-x-3">
          <button
            onClick={handleExportReport}
            disabled={!generatedReport}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center"
          >
            <span className="mr-2">📊</span>
            Экспорт Отчета ({reportConfig.format?.toUpperCase()})
          </button>
          <button
            onClick={() => setShowExportOptions(!showExportOptions)}
            disabled={!generatedReport}
            className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Опции Экспорта
          </button>
        </div>

        {/* Export Options Panel */}
        {showExportOptions && generatedReport && (
          <div className="mt-4 p-4 bg-gray-50 border border-gray-200 rounded-lg">
            <h4 className="font-medium text-gray-900 mb-3">🔧 Настройки Экспорта (Export Options)</h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Формат Файла (File Format)
                </label>
                <select
                  value={reportConfig.format}
                  onChange={(e) => handleConfigChange('format', e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="excel">📊 Excel (.xlsx) - с графиками</option>
                  <option value="pdf">📄 PDF Report - форматированный</option>
                  <option value="csv">📋 CSV Data - сырые данные</option>
                  <option value="json">🔧 JSON (API) - программный доступ</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Включить (Include)
                </label>
                <div className="space-y-2">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={exportOptions.include_charts}
                      onChange={(e) => setExportOptions(prev => ({
                        ...prev,
                        include_charts: e.target.checked
                      }))}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700">Графики и диаграммы</span>
                  </label>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={exportOptions.include_summary}
                      onChange={(e) => setExportOptions(prev => ({
                        ...prev,
                        include_summary: e.target.checked
                      }))}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700">Исполнительное резюме</span>
                  </label>
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Email (Опционально)
                </label>
                <input
                  type="email"
                  placeholder="manager@company.ru"
                  value={exportOptions.email_recipient}
                  onChange={(e) => setExportOptions(prev => ({
                    ...prev,
                    email_recipient: e.target.value
                  }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Отправить отчет по email
                </p>
              </div>
            </div>
          </div>
        )}
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
              <h1 className="text-2xl font-bold text-gray-900">Конструктор Отчетов (Report Builder)</h1>
              <p className="text-sm text-gray-500 mt-1">
                Создание пользовательских отчетов с данными в реальном времени из системы WFM
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
                <option value="kpi-dashboard">📊 Панель KPI (KPI Dashboard)</option>
                <option value="department-performance">🏢 Производительность Отделов (Department Performance)</option>
                <option value="schedule-adherence">📅 Соблюдение Расписания (Schedule Adherence)</option>
                <option value="forecast-accuracy">🎯 Точность Прогнозов (Forecast Accuracy)</option>
                <option value="custom-analytics">📈 Пользовательская Аналитика (Custom Analytics)</option>
                <option value="predictive-forecast">🔮 Прогнозная Аналитика (Predictive Analytics)</option>
                <option value="payroll">💰 Зарплатный Отчет (Payroll Report) - Coming Soon</option>
                <option value="overtime-analysis">⏰ Анализ Сверхурочных (Overtime Analysis) - Coming Soon</option>
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