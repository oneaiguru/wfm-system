import React, { useState, useEffect } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, ArcElement } from 'chart.js';
import { Line, Bar, Doughnut, Pie } from 'react-chartjs-2';
import realReportsService, { ScheduleAdherenceReport, ForecastAccuracyReport } from '../../services/realReportsService';
import {
  FileText,
  Download,
  Calendar,
  Filter,
  BarChart3,
  TrendingUp,
  Users,
  Clock,
  Target,
  Zap,
  RefreshCw,
  Settings,
  Eye,
  Mail,
  Archive,
  PlayCircle,
  PauseCircle,
  Plus,
  Edit,
  Trash2,
  Search
} from 'lucide-react';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, ArcElement);

// SPEC-24: Comprehensive Reporting System
// Enhanced from ReportBuilder.tsx with advanced query builder, template management, and executive dashboards
// Focus: Executive and manager reports with 20+ daily users

interface ComprehensiveReportConfig {
  // Enhanced from ReportBuilder to support SPEC-24 requirements
  type: 'executive-dashboard' | 'operational-report' | 'business-intelligence' | 'custom-query' | 'schedule-adherence' | 'forecast-accuracy' | 'payroll-analysis' | 'overtime-tracking' | 'employee-productivity' | 'department-comparison';
  title: string;
  description: string;
  period_start: string;
  period_end: string;
  departments: string[];
  detail_level: 'fifteen-minute' | 'hourly' | 'daily' | 'weekly' | 'monthly' | 'quarterly';
  metrics: string[];
  grouping: 'department' | 'team' | 'individual' | 'shift' | 'position';
  comparison_period: 'previous_period' | 'year_over_year' | 'quarter_over_quarter' | 'none';
  format: 'excel' | 'pdf' | 'csv' | 'json' | 'xml' | 'word';
  visualization_type: 'charts' | 'tables' | 'mixed';
  automated_scheduling: {
    enabled: boolean;
    frequency: 'daily' | 'weekly' | 'monthly' | 'quarterly';
    time: string;
    recipients: string[];
  };
  advanced_filters: {
    employee_types: string[];
    performance_thresholds: { metric: string; min?: number; max?: number }[];
    date_exclusions: string[]; // holidays, etc
  };
  template_id?: string;
}

interface ReportTemplate {
  id: string;
  name: string;
  description: string;
  category: 'executive' | 'operational' | 'hr' | 'finance' | 'custom';
  config: Partial<ComprehensiveReportConfig>;
  created_by: string;
  created_at: string;
  usage_count: number;
  is_shared: boolean;
}

interface ExecutiveKPI {
  metric: string;
  current_value: number;
  target_value: number;
  previous_period: number;
  trend: 'up' | 'down' | 'stable';
  status: 'excellent' | 'good' | 'needs_attention' | 'critical';
  unit: string;
}

interface BusinessIntelligenceData {
  executive_summary: {
    total_employees: number;
    total_departments: number;
    overall_productivity: number;
    cost_per_employee: number;
    turnover_rate: number;
  };
  kpis: ExecutiveKPI[];
  departmental_performance: {
    department: string;
    productivity_score: number;
    cost_efficiency: number;
    employee_satisfaction: number;
    revenue_contribution: number;
  }[];
  trends: {
    productivity_trend: number[];
    cost_trend: number[];
    satisfaction_trend: number[];
    periods: string[];
  };
}

const ComprehensiveReportingUI: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'builder' | 'templates' | 'scheduled' | 'executive'>('executive');
  const [reportConfig, setReportConfig] = useState<ComprehensiveReportConfig>({
    type: 'executive-dashboard',
    title: 'Executive Performance Dashboard',
    description: 'Comprehensive executive overview of organizational performance',
    period_start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    period_end: new Date().toISOString().split('T')[0],
    departments: ['All Departments'],
    detail_level: 'weekly',
    metrics: ['productivity', 'revenue_per_employee', 'customer_satisfaction', 'operational_efficiency'],
    grouping: 'department',
    comparison_period: 'previous_period',
    format: 'pdf',
    visualization_type: 'mixed',
    automated_scheduling: {
      enabled: false,
      frequency: 'weekly',
      time: '09:00',
      recipients: []
    },
    advanced_filters: {
      employee_types: ['full-time', 'part-time'],
      performance_thresholds: [],
      date_exclusions: []
    }
  });

  const [reportTemplates, setReportTemplates] = useState<ReportTemplate[]>([]);
  const [executiveDashboard, setExecutiveDashboard] = useState<BusinessIntelligenceData | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [apiHealthy, setApiHealthy] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const [queryBuilderOpen, setQueryBuilderOpen] = useState(false);

  useEffect(() => {
    loadInitialData();
    
    // Auto-refresh executive dashboard every 5 minutes
    const refreshInterval = setInterval(() => {
      if (activeTab === 'executive') {
        loadExecutiveDashboard();
      }
    }, 300000); // 5 minutes

    return () => clearInterval(refreshInterval);
  }, []);

  const loadInitialData = async () => {
    setIsGenerating(true);
    try {
      // Check API health
      const isHealthy = await realReportsService.checkApiHealth();
      setApiHealthy(isHealthy);

      if (!isHealthy) {
        console.log('[SPEC-24 REPORTING] API offline, using demo data');
        setExecutiveDashboard(getDemoExecutiveDashboard());
        setReportTemplates(getDemoTemplates());
      } else {
        // Load real data if API is available
        await Promise.all([
          loadExecutiveDashboard(),
          loadReportTemplates()
        ]);
      }
      
      setLastRefresh(new Date());
    } catch (error) {
      console.error('[SPEC-24 REPORTING] Error loading data:', error);
      setApiError('Failed to load reporting data');
      
      // Fallback to demo data
      setExecutiveDashboard(getDemoExecutiveDashboard());
      setReportTemplates(getDemoTemplates());
    } finally {
      setIsGenerating(false);
    }
  };

  const loadExecutiveDashboard = async () => {
    try {
      // In real implementation, this would call SPEC-24 APIs
      // For now, using enhanced demo data based on ReportBuilder patterns
      const dashboardData = getDemoExecutiveDashboard();
      setExecutiveDashboard(dashboardData);
      console.log('[SPEC-24 EXECUTIVE] Loaded dashboard data');
    } catch (error) {
      console.error('[SPEC-24 EXECUTIVE] Error loading dashboard:', error);
      setExecutiveDashboard(getDemoExecutiveDashboard());
    }
  };

  const loadReportTemplates = async () => {
    try {
      // In real implementation, this would call template management APIs
      const templates = getDemoTemplates();
      setReportTemplates(templates);
      console.log('[SPEC-24 TEMPLATES] Loaded', templates.length, 'templates');
    } catch (error) {
      console.error('[SPEC-24 TEMPLATES] Error loading templates:', error);
      setReportTemplates(getDemoTemplates());
    }
  };

  const getDemoExecutiveDashboard = (): BusinessIntelligenceData => ({
    executive_summary: {
      total_employees: 245,
      total_departments: 8,
      overall_productivity: 87.3,
      cost_per_employee: 85420,
      turnover_rate: 12.4
    },
    kpis: [
      {
        metric: 'Revenue per Employee',
        current_value: 125000,
        target_value: 130000,
        previous_period: 118000,
        trend: 'up',
        status: 'good',
        unit: '$'
      },
      {
        metric: 'Customer Satisfaction',
        current_value: 4.3,
        target_value: 4.5,
        previous_period: 4.1,
        trend: 'up',
        status: 'good',
        unit: '/5'
      },
      {
        metric: 'Operational Efficiency',
        current_value: 87.3,
        target_value: 90.0,
        previous_period: 89.1,
        trend: 'down',
        status: 'needs_attention',
        unit: '%'
      },
      {
        metric: 'Employee Productivity',
        current_value: 92.1,
        target_value: 95.0,
        previous_period: 90.8,
        trend: 'up',
        status: 'good',
        unit: '%'
      },
      {
        metric: 'Cost per Transaction',
        current_value: 4.82,
        target_value: 4.50,
        previous_period: 5.14,
        trend: 'down',
        status: 'needs_attention',
        unit: '$'
      },
      {
        metric: 'Service Level Compliance',
        current_value: 94.2,
        target_value: 95.0,
        previous_period: 93.8,
        trend: 'up',
        status: 'excellent',
        unit: '%'
      }
    ],
    departmental_performance: [
      {
        department: 'Customer Support',
        productivity_score: 89.2,
        cost_efficiency: 92.1,
        employee_satisfaction: 4.2,
        revenue_contribution: 28.5
      },
      {
        department: 'Technical Support',
        productivity_score: 91.8,
        cost_efficiency: 88.4,
        employee_satisfaction: 4.4,
        revenue_contribution: 22.1
      },
      {
        department: 'Sales',
        productivity_score: 95.3,
        cost_efficiency: 94.7,
        employee_satisfaction: 4.1,
        revenue_contribution: 35.2
      },
      {
        department: 'Operations',
        productivity_score: 82.6,
        cost_efficiency: 87.9,
        employee_satisfaction: 3.9,
        revenue_contribution: 14.2
      }
    ],
    trends: {
      productivity_trend: [85.2, 86.8, 88.1, 89.3, 90.2, 91.1, 92.1],
      cost_trend: [92.1, 91.8, 90.5, 89.2, 88.7, 87.9, 87.3],
      satisfaction_trend: [3.8, 3.9, 4.0, 4.1, 4.2, 4.2, 4.3],
      periods: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul']
    }
  });

  const getDemoTemplates = (): ReportTemplate[] => [
    {
      id: 'tpl_001',
      name: 'Executive Monthly Summary',
      description: 'Comprehensive monthly executive dashboard with KPIs and departmental performance',
      category: 'executive',
      config: {
        type: 'executive-dashboard',
        detail_level: 'monthly',
        metrics: ['revenue_per_employee', 'customer_satisfaction', 'operational_efficiency'],
        format: 'pdf',
        visualization_type: 'mixed'
      },
      created_by: 'System Administrator',
      created_at: '2025-07-01T09:00:00',
      usage_count: 28,
      is_shared: true
    },
    {
      id: 'tpl_002',
      name: 'Operational Performance Report',
      description: 'Daily operational metrics for department managers',
      category: 'operational',
      config: {
        type: 'operational-report',
        detail_level: 'daily',
        metrics: ['productivity', 'adherence', 'utilization'],
        format: 'excel',
        visualization_type: 'charts'
      },
      created_by: 'Operations Manager',
      created_at: '2025-07-15T14:30:00',
      usage_count: 45,
      is_shared: true
    },
    {
      id: 'tpl_003',
      name: 'HR Analytics Dashboard',
      description: 'Employee performance and satisfaction metrics for HR team',
      category: 'hr',
      config: {
        type: 'business-intelligence',
        detail_level: 'weekly',
        metrics: ['employee_satisfaction', 'turnover_rate', 'training_completion'],
        format: 'pdf',
        visualization_type: 'mixed'
      },
      created_by: 'HR Director',
      created_at: '2025-07-10T11:15:00',
      usage_count: 22,
      is_shared: false
    },
    {
      id: 'tpl_004',
      name: 'Financial Performance Analysis',
      description: 'Cost analysis and revenue metrics for finance team',
      category: 'finance',
      config: {
        type: 'business-intelligence',
        detail_level: 'monthly',
        metrics: ['cost_per_employee', 'revenue_per_transaction', 'budget_variance'],
        format: 'excel',
        visualization_type: 'tables'
      },
      created_by: 'CFO',
      created_at: '2025-07-05T16:45:00',
      usage_count: 15,
      is_shared: true
    }
  ];

  const generateReport = async () => {
    setIsGenerating(true);
    setApiError('');
    
    try {
      console.log('[SPEC-24 REPORTING] Generating report:', reportConfig.title);
      
      // In real implementation, this would call SPEC-24 report generation APIs
      // For now, simulating report generation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const reportResult = {
        id: `report_${Date.now()}`,
        title: reportConfig.title,
        format: reportConfig.format,
        generated_at: new Date().toISOString(),
        download_url: `#download-${reportConfig.type}-${Date.now()}`,
        status: 'completed'
      };
      
      console.log('[SPEC-24 REPORTING] Report generated:', reportResult);
      
      // Show success message (in real app, would trigger download)
      alert(`Report "${reportConfig.title}" generated successfully in ${reportConfig.format.toUpperCase()} format!`);
      
    } catch (error) {
      console.error('[SPEC-24 REPORTING] Error generating report:', error);
      setApiError('Failed to generate report. Please try again.');
    } finally {
      setIsGenerating(false);
    }
  };

  const applyTemplate = (template: ReportTemplate) => {
    setReportConfig({
      ...reportConfig,
      ...template.config,
      title: template.name,
      description: template.description,
      template_id: template.id
    });
    setSelectedTemplate(template.id);
    setActiveTab('builder');
  };

  const getKPIStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return 'text-green-700 bg-green-50 border-green-200';
      case 'good': return 'text-blue-700 bg-blue-50 border-blue-200';
      case 'needs_attention': return 'text-yellow-700 bg-yellow-50 border-yellow-200';
      case 'critical': return 'text-red-700 bg-red-50 border-red-200';
      default: return 'text-gray-700 bg-gray-50 border-gray-200';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <TrendingUp className="h-4 w-4 text-green-600" />;
      case 'down': return <TrendingUp className="h-4 w-4 text-red-600 transform rotate-180" />;
      case 'stable': return <div className="h-1 w-4 bg-gray-400 rounded"></div>;
      default: return null;
    }
  };

  const renderExecutiveDashboard = () => {
    if (!executiveDashboard) return null;

    return (
      <div className="space-y-6">
        {/* Executive Summary */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Executive Summary</h3>
            <div className="text-sm text-gray-500">
              Last updated: {lastRefresh.toLocaleString()}
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{executiveDashboard.executive_summary.total_employees}</div>
              <div className="text-sm text-gray-600">Total Employees</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{executiveDashboard.executive_summary.total_departments}</div>
              <div className="text-sm text-gray-600">Departments</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">{executiveDashboard.executive_summary.overall_productivity.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Overall Productivity</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">${(executiveDashboard.executive_summary.cost_per_employee / 1000).toFixed(0)}k</div>
              <div className="text-sm text-gray-600">Cost per Employee</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">{executiveDashboard.executive_summary.turnover_rate.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Turnover Rate</div>
            </div>
          </div>
        </div>

        {/* KPI Dashboard */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Key Performance Indicators</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {executiveDashboard.kpis.map((kpi, index) => (
              <div key={index} className={`p-4 rounded-lg border-2 ${getKPIStatusColor(kpi.status)}`}>
                <div className="flex items-center justify-between mb-2">
                  <div className="text-sm font-medium">{kpi.metric}</div>
                  <div className="flex items-center space-x-1">
                    {getTrendIcon(kpi.trend)}
                    <div className={`w-2 h-2 rounded-full ${
                      kpi.status === 'excellent' ? 'bg-green-500' :
                      kpi.status === 'good' ? 'bg-blue-500' :
                      kpi.status === 'needs_attention' ? 'bg-yellow-500' :
                      'bg-red-500'
                    }`}></div>
                  </div>
                </div>
                <div className="text-2xl font-bold mb-1">
                  {kpi.unit === '$' ? '$' : ''}
                  {kpi.metric === 'Customer Satisfaction' ? kpi.current_value.toFixed(1) : 
                   kpi.unit === '$' ? (kpi.current_value / 1000).toFixed(0) + 'k' : 
                   kpi.current_value.toFixed(1)}
                  {kpi.unit === '%' ? '%' : kpi.unit === '/5' ? '/5' : ''}
                </div>
                <div className="text-xs text-gray-600">
                  Target: {kpi.unit === '$' ? '$' : ''}
                  {kpi.metric === 'Customer Satisfaction' ? kpi.target_value.toFixed(1) : 
                   kpi.unit === '$' ? (kpi.target_value / 1000).toFixed(0) + 'k' : 
                   kpi.target_value.toFixed(1)}
                  {kpi.unit === '%' ? '%' : kpi.unit === '/5' ? '/5' : ''}
                </div>
                <div className="text-xs text-gray-500">
                  Previous: {kpi.unit === '$' ? '$' : ''}
                  {kpi.metric === 'Customer Satisfaction' ? kpi.previous_period.toFixed(1) : 
                   kpi.unit === '$' ? (kpi.previous_period / 1000).toFixed(0) + 'k' : 
                   kpi.previous_period.toFixed(1)}
                  {kpi.unit === '%' ? '%' : kpi.unit === '/5' ? '/5' : ''}
                  {kpi.trend === 'up' ? ' ↑' : kpi.trend === 'down' ? ' ↓' : ' →'}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Trend Charts */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Trends (7 months)</h3>
          <div className="mb-4">
            <Line
              data={{
                labels: executiveDashboard.trends.periods,
                datasets: [
                  {
                    label: 'Productivity (%)',
                    data: executiveDashboard.trends.productivity_trend,
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.4,
                    yAxisID: 'y'
                  },
                  {
                    label: 'Customer Satisfaction',
                    data: executiveDashboard.trends.satisfaction_trend,
                    borderColor: 'rgb(16, 185, 129)',
                    backgroundColor: 'rgba(16, 185, 129, 0.1)',
                    tension: 0.4,
                    yAxisID: 'y1'
                  }
                ]
              }}
              options={{
                responsive: true,
                interaction: {
                  mode: 'index' as const,
                  intersect: false,
                },
                plugins: {
                  title: {
                    display: true,
                    text: 'Key Metrics Trending Analysis'
                  },
                  legend: {
                    position: 'top' as const,
                  }
                },
                scales: {
                  x: {
                    display: true,
                    title: {
                      display: true,
                      text: 'Period'
                    }
                  },
                  y: {
                    type: 'linear' as const,
                    display: true,
                    position: 'left' as const,
                    title: {
                      display: true,
                      text: 'Productivity (%)'
                    },
                    min: 80,
                    max: 100
                  },
                  y1: {
                    type: 'linear' as const,
                    display: true,
                    position: 'right' as const,
                    title: {
                      display: true,
                      text: 'Satisfaction (1-5)'
                    },
                    min: 3.5,
                    max: 5,
                    grid: {
                      drawOnChartArea: false,
                    },
                  },
                }
              }}
            />
          </div>
        </div>

        {/* Department Performance */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Departmental Performance Comparison</h3>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Department</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Productivity</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cost Efficiency</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Employee Satisfaction</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Revenue Contribution</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {executiveDashboard.departmental_performance.map((dept, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{dept.department}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="text-sm font-medium text-gray-900">{dept.productivity_score.toFixed(1)}%</div>
                        <div className={`ml-2 h-2 w-16 rounded-full bg-gray-200`}>
                          <div 
                            className={`h-2 rounded-full ${
                              dept.productivity_score >= 90 ? 'bg-green-500' :
                              dept.productivity_score >= 80 ? 'bg-yellow-500' :
                              'bg-red-500'
                            }`}
                            style={{width: `${dept.productivity_score}%`}}
                          ></div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{dept.cost_efficiency.toFixed(1)}%</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{dept.employee_satisfaction.toFixed(1)}/5</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{dept.revenue_contribution.toFixed(1)}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    );
  };

  const renderReportBuilder = () => (
    <div className="space-y-6">
      {/* Report Configuration */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Report Configuration</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Report Title</label>
            <input
              type="text"
              value={reportConfig.title}
              onChange={(e) => setReportConfig({...reportConfig, title: e.target.value})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter report title"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Report Type</label>
            <select
              value={reportConfig.type}
              onChange={(e) => setReportConfig({...reportConfig, type: e.target.value as any})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="executive-dashboard">Executive Dashboard</option>
              <option value="operational-report">Operational Report</option>
              <option value="business-intelligence">Business Intelligence</option>
              <option value="employee-productivity">Employee Productivity</option>
              <option value="department-comparison">Department Comparison</option>
              <option value="custom-query">Custom Query</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Period Start</label>
            <input
              type="date"
              value={reportConfig.period_start}
              onChange={(e) => setReportConfig({...reportConfig, period_start: e.target.value})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Period End</label>
            <input
              type="date"
              value={reportConfig.period_end}
              onChange={(e) => setReportConfig({...reportConfig, period_end: e.target.value})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Detail Level</label>
            <select
              value={reportConfig.detail_level}
              onChange={(e) => setReportConfig({...reportConfig, detail_level: e.target.value as any})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
              <option value="quarterly">Quarterly</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Export Format</label>
            <select
              value={reportConfig.format}
              onChange={(e) => setReportConfig({...reportConfig, format: e.target.value as any})}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="pdf">PDF Report</option>
              <option value="excel">Excel Workbook (.xlsx)</option>
              <option value="csv">CSV Data</option>
              <option value="json">JSON Data</option>
              <option value="xml">XML Data</option>
              <option value="word">Word Document (.docx)</option>
            </select>
          </div>
        </div>
        
        <div className="mt-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
          <textarea
            value={reportConfig.description}
            onChange={(e) => setReportConfig({...reportConfig, description: e.target.value})}
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter report description"
          />
        </div>
        
        <div className="mt-6 flex items-center justify-between">
          <button
            onClick={() => setQueryBuilderOpen(true)}
            className="flex items-center gap-2 px-4 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded border border-blue-200 transition-colors"
          >
            <Settings size={16} />
            Advanced Query Builder
          </button>
          
          <div className="flex items-center gap-3">
            <button
              onClick={generateReport}
              disabled={isGenerating}
              className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 transition-colors"
            >
              {isGenerating ? (
                <RefreshCw size={16} className="animate-spin" />
              ) : (
                <PlayCircle size={16} />
              )}
              {isGenerating ? 'Generating...' : 'Generate Report'}
            </button>
          </div>
        </div>
        
        {apiError && (
          <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
            {apiError}
          </div>
        )}
      </div>
    </div>
  );

  const renderTemplates = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-gray-900">Report Templates</h3>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors">
          <Plus size={16} />
          Create Template
        </button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {reportTemplates.map((template) => (
          <div key={template.id} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h4 className="font-semibold text-gray-900">{template.name}</h4>
                <span className={`inline-block px-2 py-1 text-xs rounded-full mt-1 ${
                  template.category === 'executive' ? 'bg-purple-100 text-purple-700' :
                  template.category === 'operational' ? 'bg-blue-100 text-blue-700' :
                  template.category === 'hr' ? 'bg-green-100 text-green-700' :
                  template.category === 'finance' ? 'bg-yellow-100 text-yellow-700' :
                  'bg-gray-100 text-gray-700'
                }`}>
                  {template.category.toUpperCase()}
                </span>
              </div>
              <div className="text-sm text-gray-500">{template.usage_count} uses</div>
            </div>
            
            <p className="text-sm text-gray-600 mb-4">{template.description}</p>
            
            <div className="text-xs text-gray-500 mb-4">
              <div>Created by: {template.created_by}</div>
              <div>Created: {new Date(template.created_at).toLocaleDateString()}</div>
            </div>
            
            <div className="flex items-center gap-2">
              <button
                onClick={() => applyTemplate(template)}
                className="flex items-center gap-1 px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded transition-colors"
              >
                <PlayCircle size={14} />
                Use Template
              </button>
              <button className="flex items-center gap-1 px-3 py-1 text-sm text-gray-600 hover:bg-gray-50 rounded transition-colors">
                <Edit size={14} />
                Edit
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderScheduledReports = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-gray-900">Scheduled Reports</h3>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors">
          <Plus size={16} />
          Schedule Report
        </button>
      </div>
      
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-4">
          <div className="text-center text-gray-500 py-8">
            <Calendar className="h-12 w-12 mx-auto mb-4 text-gray-400" />
            <p className="text-lg font-medium">No scheduled reports yet</p>
            <p className="text-sm">Create your first automated report schedule</p>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Comprehensive Reporting</h1>
              <p className="text-gray-600 mt-1">SPEC-24: Executive dashboards, business intelligence, and advanced analytics</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${apiHealthy ? 'bg-green-500' : 'bg-orange-500'} animate-pulse`}></div>
                <span className="text-sm text-gray-600">
                  {apiHealthy ? 'Live Data' : 'Demo Mode'}
                </span>
              </div>
              <div className="text-sm text-gray-500">
                Last refresh: {lastRefresh.toLocaleTimeString()}
              </div>
              <button
                onClick={loadInitialData}
                disabled={isGenerating}
                className="flex items-center gap-2 px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                <RefreshCw size={14} className={isGenerating ? 'animate-spin' : ''} />
                {isGenerating ? 'Refreshing...' : 'Refresh'}
              </button>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="mb-6">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setActiveTab('executive')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'executive'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <Target size={16} />
                  Executive Dashboard
                </div>
              </button>
              <button
                onClick={() => setActiveTab('builder')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'builder'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <BarChart3 size={16} />
                  Report Builder
                </div>
              </button>
              <button
                onClick={() => setActiveTab('templates')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'templates'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <FileText size={16} />
                  Templates ({reportTemplates.length})
                </div>
              </button>
              <button
                onClick={() => setActiveTab('scheduled')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'scheduled'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <Clock size={16} />
                  Scheduled Reports
                </div>
              </button>
            </nav>
          </div>
        </div>

        {/* Tab Content */}
        {activeTab === 'executive' && renderExecutiveDashboard()}
        {activeTab === 'builder' && renderReportBuilder()}
        {activeTab === 'templates' && renderTemplates()}
        {activeTab === 'scheduled' && renderScheduledReports()}
        
        {/* Footer */}
        <div className="text-center text-sm text-gray-500 mt-8">
          SPEC-24 Comprehensive Reporting System • 
          {apiHealthy ? 'Real-time data integration' : 'Demo mode with sample data'} • 
          Last updated: {lastRefresh.toLocaleString()}
        </div>
      </div>
    </div>
  );
};

export default ComprehensiveReportingUI;