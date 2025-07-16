import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import ErrorBoundary from './components/ErrorBoundary';
import ScheduleGridPortal from './modules/schedule-grid-system/components/ScheduleGridPortal';
import ForecastingPortal from './modules/forecasting-analytics/components/ForecastingPortal';
import ReportsPortal from './modules/reports-analytics/components/ReportsPortal';
import MobilePersonalCabinet from './modules/mobile-personal-cabinet/components/MobilePersonalCabinet';
import SystemUserManagement from './modules/system-administration/components/SystemUserManagement';
import DatabaseAdminDashboard from './modules/system-administration/components/DatabaseAdminDashboard';
import ServiceManagementConsole from './modules/system-administration/components/ServiceManagementConsole';
import OperationalControlDashboard from './modules/real-time-monitoring/components/OperationalControlDashboard';
import MobileMonitoringDashboard from './modules/real-time-monitoring/components/MobileMonitoringDashboard';
import MultiSkillPlanningManager from './modules/planning-workflows/components/MultiSkillPlanningManager';
import ProcessWorkflowManager from './modules/business-process-workflows/components/ProcessWorkflowManager';
import ReferenceDataConfigurationUI from './modules/reference-data-management/components/ReferenceDataConfigurationUI';
import AdvancedUIManager from './modules/advanced-ui-ux/components/AdvancedUIManager';
import EnhancedEmployeeProfilesUI from './modules/employee-management-enhanced/components/EnhancedEmployeeProfilesUI';
import ReportBuilderUI from './modules/reporting-analytics/components/ReportBuilderUI';
import LoadPlanningUI from './modules/forecasting-ui/components/LoadPlanningUI';
import ScheduleOptimizationUI from './modules/schedule-optimization/components/ScheduleOptimizationUI';
import TimeAttendanceUI from './modules/time-attendance/components/TimeAttendanceUI';
import IntegrationDashboardUI from './modules/integration-ui/components/IntegrationDashboardUI';
import { VacancyPlanningModule } from './modules/vacancy-planning';
import { EmployeePortal } from './modules/employee-portal';
import { IntegrationTester } from './components/IntegrationTester';
import PendingRequestsList from './components/requests/PendingRequestsList';
import EmployeeProfile from './components/employee/EmployeeProfile';
import EmployeeSearch from './components/employee/EmployeeSearch';
import WorkflowDashboard from './components/workflow/WorkflowDashboard';
import WorkflowAutomation from './components/workflow-advanced/WorkflowAutomation';
import WorkflowTemplates from './components/workflow-advanced/WorkflowTemplates';
import WorkflowReporting from './components/workflow-advanced/WorkflowReporting';
import WorkflowIntegrations from './components/workflow-advanced/WorkflowIntegrations';
import WorkflowOptimization from './components/workflow-advanced/WorkflowOptimization';
import ApprovalQueue from './components/workflow/ApprovalQueue';
import WorkflowTracker from './components/workflow/WorkflowTracker';
import EscalationManager from './components/workflow/EscalationManager';
import WorkflowHistory from './components/workflow/WorkflowHistory';
import WorkflowMetrics from './components/workflow/WorkflowMetrics';
// Agent 7: Integration & Reporting Components
import SystemHealthMonitor from './components/integration-reporting/SystemHealthMonitor';
import ApiEndpointTester from './components/integration-reporting/ApiEndpointTester';
import RealtimeDataMonitor from './components/integration-reporting/RealtimeDataMonitor';
import DataSyncDashboard from './components/integration-reporting/DataSyncDashboard';
import DatabaseQueryBuilder from './components/integration-reporting/DatabaseQueryBuilder';
import BusinessIntelligenceReports from './components/integration-reporting/BusinessIntelligenceReports';
// Admin Components
import SystemSettings from './components/admin/SystemSettings';
import RoleManager from './components/admin/RoleManager';
import AuditLog from './components/admin/AuditLog';
import UserPermissions from './components/admin/UserPermissions';
import ConfigEditor from './components/admin/ConfigEditor';
import SystemHealth from './components/admin/SystemHealth';
// Performance Monitoring Components
import RealtimeMetrics from './components/performance/RealtimeMetrics';
import SLAMonitor from './components/performance/SLAMonitor';
import ExecutiveDashboard from './components/performance/ExecutiveDashboard';
import AlertConfiguration from './components/performance/AlertConfiguration';
import TrendAnalysis from './components/performance/TrendAnalysis';
import IntegrationMonitor from './components/performance/IntegrationMonitor';
// Mobile Components
import MobileLogin from './components/mobile/MobileLogin';
import MobileCalendarView from './components/mobile/MobileCalendarView';
import MobileRequestForm from './components/mobile/MobileRequestForm';
import MobileNotifications from './components/mobile/MobileNotifications';
import MobileProfile from './components/mobile/MobileProfile';
import MobileShiftExchange from './components/mobile/MobileShiftExchange';
import MobileOfflineIndicator from './components/mobile/MobileOfflineIndicator';
// Enhanced Admin Components - Components 50-54
import SystemConfigManager from './components/admin-enhanced/SystemConfigManager';
import AdvancedRoleEditor from './components/admin-enhanced/AdvancedRoleEditor';
import SecurityAuditDashboard from './components/admin-enhanced/SecurityAuditDashboard';
import UserActivityMonitor from './components/admin-enhanced/UserActivityMonitor';
import SystemBackupManager from './components/admin-enhanced/SystemBackupManager';
// Advanced Analytics Components - Components 55-60
import AdvancedMetricsAnalyzer from './components/analytics-advanced/AdvancedMetricsAnalyzer';
import PerformanceForecastDashboard from './components/analytics-advanced/PerformanceForecastDashboard';
import BusinessIntelligenceDashboard from './components/analytics-advanced/BusinessIntelligenceDashboard';
import RealTimeDataVisualization from './components/analytics-advanced/RealTimeDataVisualization';
import ComplianceReportingCenter from './components/analytics-advanced/ComplianceReportingCenter';
import PredictiveAnalyticsEngine from './components/analytics-advanced/PredictiveAnalyticsEngine';
// Advanced Forecasting Components - Agent 8 (FINAL)
import MultiHorizonForecaster from './components/advanced-forecasting/MultiHorizonForecaster';
import AccuracyMetricsDashboard from './components/advanced-forecasting/AccuracyMetricsDashboard';
import ScenarioModelingEngine from './components/advanced-forecasting/ScenarioModelingEngine';
import SeasonalTrendAnalyzer from './components/advanced-forecasting/SeasonalTrendAnalyzer';
import CapacityPlanningOptimizer from './components/advanced-forecasting/CapacityPlanningOptimizer';
import DemandVariabilityAnalyzer from './components/advanced-forecasting/DemandVariabilityAnalyzer';
import PredictiveMaintenanceForecaster from './components/advanced-forecasting/PredictiveMaintenanceForecaster';
import './index.css';

function App() {
  return (
    <ErrorBoundary>
      <Router>
        <div className="App">
          <Routes>
          {/* Login Route */}
          <Route path="/login" element={<Login />} />
          
          {/* Main Dashboard */}
          <Route path="/dashboard" element={<Dashboard />} />
          
          {/* Core WFM Modules */}
          <Route path="/schedule" element={<ScheduleGridPortal />} />
          <Route path="/forecasting" element={<ForecastingPortal />} />
          <Route path="/reports" element={<ReportsPortal />} />
          
          {/* Mobile Personal Cabinet - BDD Feature 14 */}
          <Route path="/mobile/*" element={<MobilePersonalCabinet />} />
          
          {/* System Administration - BDD Feature 18 */}
          <Route path="/admin/users" element={<SystemUserManagement />} />
          <Route path="/admin/database" element={<DatabaseAdminDashboard />} />
          <Route path="/admin/services" element={<ServiceManagementConsole />} />
          
          {/* New Admin Components - Components 21-26 */}
          <Route path="/admin/system-settings" element={<SystemSettings />} />
          <Route path="/admin/role-manager" element={<RoleManager />} />
          <Route path="/admin/audit-log" element={<AuditLog />} />
          <Route path="/admin/user-permissions" element={<UserPermissions />} />
          <Route path="/admin/config-editor" element={<ConfigEditor />} />
          <Route path="/admin/system-health" element={<SystemHealth />} />
          
          {/* Real-time Monitoring - BDD Feature 15 */}
          <Route path="/monitoring/operational" element={<OperationalControlDashboard />} />
          <Route path="/monitoring/mobile" element={<MobileMonitoringDashboard />} />
          
          {/* Planning Workflows - BDD Feature 19 */}
          <Route path="/planning/multi-skill" element={<MultiSkillPlanningManager />} />
          
          {/* Business Process Workflows - BDD Feature 03 */}
          <Route path="/workflows/process" element={<ProcessWorkflowManager />} />
          
          {/* Reference Data Management - BDD Feature 17 */}
          <Route path="/reference-data/config" element={<ReferenceDataConfigurationUI />} />
          
          {/* Advanced UI/UX - BDD Feature 25 */}
          <Route path="/ui/advanced" element={<AdvancedUIManager />} />
          
          {/* Enhanced Employee Management - BDD Feature 16 */}
          <Route path="/employees/enhanced-profiles" element={<EnhancedEmployeeProfilesUI />} />
          
          {/* Reporting Analytics - BDD Feature 12 */}
          <Route path="/reports/builder" element={<ReportBuilderUI />} />
          
          {/* Forecasting UI - BDD Feature 08 */}
          <Route path="/forecasting/load-planning" element={<LoadPlanningUI />} />
          
          {/* Schedule Optimization - BDD Feature 24 */}
          <Route path="/scheduling/optimization" element={<ScheduleOptimizationUI />} />
          
          {/* Time & Attendance - BDD Feature 29 */}
          <Route path="/time-attendance/dashboard" element={<TimeAttendanceUI />} />
          
          {/* Integration UI - BDD Feature 21 */}
          <Route path="/integrations/dashboard" element={<IntegrationDashboardUI />} />
          
          {/* Vacancy Planning Module - BDD Feature 27 */}
          <Route path="/vacancy-planning/*" element={<VacancyPlanningModule />} />
          
          {/* Employee Portal - For Vacation Request BDD Scenario */}
          <Route path="/employee-portal" element={<EmployeePortal />} />
          
          {/* Integration Tester - For INTEGRATION-OPUS */}
          <Route path="/integration-tester" element={<IntegrationTester />} />
          
          {/* Pending Requests - Component 11 */}
          <Route path="/requests/pending" element={<PendingRequestsList />} />
          
          {/* Employee Components - Components 13 & 14 */}
          <Route path="/employees/profile/:id" element={<EmployeeProfile employeeId="" />} />
          <Route path="/employees/search" element={<EmployeeSearch />} />
          
          {/* Workflow Components - Components 15-20 */}
          <Route path="/workflow/dashboard" element={<WorkflowDashboard />} />
          <Route path="/workflow/approval-queue" element={<ApprovalQueue />} />
          <Route path="/workflow/tracker" element={<WorkflowTracker />} />
          
          {/* Advanced Workflow Components - Components 40-44 */}
          <Route path="/workflow-advanced/automation" element={<WorkflowAutomation />} />
          <Route path="/workflow-advanced/templates" element={<WorkflowTemplates />} />
          <Route path="/workflow-advanced/reporting" element={<WorkflowReporting />} />
          <Route path="/workflow-advanced/integrations" element={<WorkflowIntegrations />} />
          <Route path="/workflow-advanced/optimization" element={<WorkflowOptimization />} />
          <Route path="/workflow/escalation" element={<EscalationManager />} />
          <Route path="/workflow/history" element={<WorkflowHistory />} />
          <Route path="/workflow/metrics" element={<WorkflowMetrics />} />
          
          {/* Advanced Workflow Components - Components 40-44 */}
          <Route path="/workflow-advanced/automation" element={<WorkflowAutomation />} />
          <Route path="/workflow-advanced/templates" element={<WorkflowTemplates />} />
          <Route path="/workflow-advanced/reporting" element={<WorkflowReporting />} />
          <Route path="/workflow-advanced/integrations" element={<WorkflowIntegrations />} />
          <Route path="/workflow-advanced/optimization" element={<WorkflowOptimization />} />
          
          {/* Performance Monitoring Components - Components 27-32 */}
          <Route path="/performance/realtime-metrics" element={<RealtimeMetrics />} />
          <Route path="/performance/sla-monitor" element={<SLAMonitor />} />
          <Route path="/performance/executive-dashboard" element={<ExecutiveDashboard />} />
          <Route path="/performance/alert-configuration" element={<AlertConfiguration />} />
          <Route path="/performance/trend-analysis" element={<TrendAnalysis />} />
          <Route path="/performance/integration-monitor" element={<IntegrationMonitor />} />
          
          {/* Mobile Components - Components 33-39 */}
          <Route path="/mobile/login" element={<MobileLogin onLogin={async () => {}} />} />
          <Route path="/mobile/calendar" element={<MobileCalendarView employeeId="current" />} />
          <Route path="/mobile/requests" element={<MobileRequestForm employeeId="current" onSubmit={async () => {}} />} />
          <Route path="/mobile/notifications" element={<MobileNotifications employeeId="current" />} />
          <Route path="/mobile/profile" element={<MobileProfile employeeId="current" />} />
          <Route path="/mobile/shift-exchange" element={<MobileShiftExchange employeeId="current" />} />
          <Route path="/mobile/offline-status" element={<MobileOfflineIndicator showDetails={true} />} />
          
          {/* Enhanced Admin Components - Components 50-54 */}
          <Route path="/admin-enhanced/config-manager" element={<SystemConfigManager />} />
          <Route path="/admin-enhanced/role-editor" element={<AdvancedRoleEditor />} />
          <Route path="/admin-enhanced/security-audit" element={<SecurityAuditDashboard />} />
          <Route path="/admin-enhanced/user-activity" element={<UserActivityMonitor />} />
          <Route path="/admin-enhanced/backup-manager" element={<SystemBackupManager />} />
          
          {/* Agent 7: Integration & Reporting Components */}
          <Route path="/integration-reporting/system-health" element={<SystemHealthMonitor />} />
          <Route path="/integration-reporting/api-tester" element={<ApiEndpointTester />} />
          <Route path="/integration-reporting/realtime-monitor" element={<RealtimeDataMonitor />} />
          <Route path="/integration-reporting/data-sync" element={<DataSyncDashboard />} />
          <Route path="/integration-reporting/query-builder" element={<DatabaseQueryBuilder />} />
          <Route path="/integration-reporting/business-intelligence" element={<BusinessIntelligenceReports />} />
          
          {/* Advanced Analytics Components - Components 55-60 */}
          <Route path="/analytics-advanced/metrics-analyzer" element={<AdvancedMetricsAnalyzer />} />
          <Route path="/analytics-advanced/performance-forecast" element={<PerformanceForecastDashboard />} />
          <Route path="/analytics-advanced/business-intelligence" element={<BusinessIntelligenceDashboard />} />
          <Route path="/analytics-advanced/realtime-data" element={<RealTimeDataVisualization />} />
          <Route path="/analytics-advanced/compliance-reporting" element={<ComplianceReportingCenter />} />
          <Route path="/analytics-advanced/predictive-analytics" element={<PredictiveAnalyticsEngine />} />
          
          {/* Advanced Forecasting Components - Agent 8 (FINAL) */}
          <Route path="/advanced-forecasting/multi-horizon" element={<MultiHorizonForecaster />} />
          <Route path="/advanced-forecasting/accuracy-metrics" element={<AccuracyMetricsDashboard />} />
          <Route path="/advanced-forecasting/scenario-modeling" element={<ScenarioModelingEngine />} />
          <Route path="/advanced-forecasting/seasonal-analysis" element={<SeasonalTrendAnalyzer />} />
          <Route path="/advanced-forecasting/capacity-planning" element={<CapacityPlanningOptimizer />} />
          <Route path="/advanced-forecasting/demand-variability" element={<DemandVariabilityAnalyzer />} />
          <Route path="/advanced-forecasting/predictive-maintenance" element={<PredictiveMaintenanceForecaster />} />
          
          {/* Default redirect to login */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          </Routes>
        </div>
      </Router>
    </ErrorBoundary>
  );
}

export default App;