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
          
          {/* Default redirect to login */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          </Routes>
        </div>
      </Router>
    </ErrorBoundary>
  );
}

export default App;