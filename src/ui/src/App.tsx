import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from 'react-router-dom';
import './index.css';

// Direct imports for core components
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import { EmployeePortal } from './modules/employee-portal';
import { IntegrationTester } from './components/IntegrationTester';

// Import our demo components
import DemoShowcase from './components/DemoShowcase';
import EmployeeDashboard from './components/EmployeeDashboard';
import ScheduleView from './components/ScheduleView';
import RequestForm from './components/RequestForm';
import PendingRequestsList from './components/requests/PendingRequestsList';
import ManagerDashboard from './components/manager/ManagerDashboard';
import NotificationCenter from './components/NotificationCenter';
import TeamScheduleView from './components/manager/TeamScheduleView';
import ApprovalQueue from './components/manager/ApprovalQueue';
import ShiftSwapModal from './components/modals/ShiftSwapModal';
import Spec39ReportingDashboard from './components/reports/Spec39ReportingDashboard';
import TimeAttendanceSystem from './components/time-attendance/TimeAttendanceSystem';
import TrainingProgramManager from './components/employee-enhanced/TrainingProgramManager';
import ShiftTradingManagement from './components/shift-trading/ShiftTradingManagement';

// Import mobile components
import MobileLogin from './components/mobile/MobileLogin';
import MobileCalendar from './components/mobile/MobileCalendar';
import MobileRequestForm from './components/mobile/MobileRequestForm';
import MobileDashboard from './components/mobile/MobileDashboard';

// Loading component
const Loading = () => <div style={{ padding: '20px', textAlign: 'center' }}>Loading...</div>;

function App() {
  console.log('App component rendered successfully!');
  
  return (
    <Router>
      <div className="App min-h-screen bg-gray-50">
        {/* Navigation Header */}
        <nav className="bg-white shadow-sm border-b border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex">
                <div className="flex-shrink-0 flex items-center">
                  <h1 className="text-xl font-semibold">WFM Enterprise System</h1>
                </div>
                <div className="sm:ml-6 flex sm:space-x-8 overflow-x-auto">
                  <Link to="/login" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Login
                  </Link>
                  <Link to="/dashboard" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Dashboard
                  </Link>
                  <Link to="/schedule" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    My Schedule
                  </Link>
                  <Link to="/employee-portal" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Employee Portal
                  </Link>
                  <Link to="/requests" data-testid="time-off-link" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Time Off
                  </Link>
                  <a href="/team-calendar" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Team Calendar
                  </a>
                  <a href="/manager-dashboard" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Manager Dashboard
                  </a>
                  <a href="/demo" className="border-indigo-500 text-indigo-600 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Demo Showcase
                  </a>
                  <a href="/demo/spec39-reporting" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    SPEC-39 Reports
                  </a>
                  <a href="/demo/spec38-attendance" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    SPEC-38 Attendance
                  </a>
                  <a href="/demo/spec40-training" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    SPEC-40 Training
                  </a>
                  <a href="/demo/spec37-shifts" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    SPEC-37 Shifts
                  </a>
                  <a href="/demo/spec41-training-portal" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    SPEC-41 Portal
                  </a>
                  <a href="/mobile/login" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Mobile Login
                  </a>
                  <a href="/mobile/schedule" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Mobile Schedule
                  </a>
                  <a href="/vacation-test" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    API Test
                  </a>
                </div>
              </div>
            </div>
          </div>
        </nav>
        
        {/* Main Content */}
        <main className="flex-1">
          <Suspense fallback={<Loading />}>
            <Routes>
              {/* Core routes */}
              <Route path="/login" element={<Login />} />
              <Route path="/mobile/login" element={<Navigate to="/login" replace />} />
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/schedule" element={<ScheduleView />} />
              <Route path="/requests" element={<RequestForm />} />
              <Route path="/requests/new" element={<RequestForm />} />
              <Route path="/requests/history" element={
                <div className="min-h-screen bg-gray-50">
                  <div className="max-w-7xl mx-auto py-6 px-4">
                    <div className="mb-6 flex justify-between items-center">
                      <div>
                        <h1 className="text-3xl font-bold text-gray-900">Request History</h1>
                        <p className="text-gray-600 mt-2">View and manage your time-off requests</p>
                      </div>
                      <Link 
                        to="/requests" 
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        New Request
                      </Link>
                    </div>
                    <PendingRequestsList />
                  </div>
                </div>
              } />
              <Route path="/employee-portal/*" element={<EmployeePortal />} />
              <Route path="/integration-tester" element={<IntegrationTester />} />
              <Route path="/team-calendar" element={<TeamScheduleView managerId={7} />} />
              <Route path="/manager-dashboard" element={<ManagerDashboard managerId={7} />} />
              <Route path="/manager/dashboard" element={<ManagerDashboard managerId={7} />} />
              <Route path="/manager/approvals" element={<ApprovalQueue />} />
              
              {/* Demo showcase routes */}
              <Route path="/demo" element={<DemoShowcase />} />
              <Route path="/demo/employee-dashboard" element={<EmployeeDashboard />} />
              <Route path="/demo/schedule-view" element={<ScheduleView />} />
              <Route path="/demo/request-form" element={<RequestForm />} />
              <Route path="/demo/manager-dashboard" element={<ManagerDashboard managerId={7} />} />
              <Route path="/demo/notifications" element={<NotificationCenter />} />
              <Route path="/demo/spec39-reporting" element={<Spec39ReportingDashboard />} />
              <Route path="/demo/spec38-attendance" element={<TimeAttendanceSystem />} />
              <Route path="/demo/spec40-training" element={<TrainingProgramManager />} />
              <Route path="/demo/spec37-shifts" element={<ShiftTradingManagement />} />
              <Route path="/demo/spec41-training-portal" element={<TrainingProgramManager />} />
              
              {/* Mobile routes */}
              <Route path="/mobile/login" element={<MobileLogin onLogin={async (credentials) => {
                console.log('Mobile login attempt:', credentials);
                try {
                  const response = await fetch('http://localhost:8001/api/v1/mobile/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(credentials)
                  });
                  const data = await response.json();
                  if (response.ok) {
                    alert('✅ Mobile login successful!');
                    console.log('Mobile login response:', data);
                  } else {
                    alert('❌ Mobile login failed: ' + data.detail);
                  }
                } catch (error) {
                  alert('❌ Error: ' + error);
                  console.error('Mobile login error:', error);
                }
              }} />} />
              <Route path="/mobile/schedule" element={<MobileCalendar />} />
              <Route path="/mobile/dashboard" element={<MobileDashboard />} />
              <Route path="/mobile/requests/new" element={<MobileRequestForm />} />
              
              {/* Vacation test route */}
              <Route path="/vacation-test" element={
                <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
                  <div className="px-4 py-6 sm:px-0">
                    <div className="bg-white overflow-hidden shadow rounded-lg">
                      <div className="px-4 py-5 sm:p-6">
                        <h2 className="text-lg font-medium text-gray-900 mb-4">Vacation Request Test</h2>
                        <div className="bg-gray-50 p-4 rounded mb-4">
                          <pre className="text-sm">
{JSON.stringify({
  employee_id: 2,
  request_type: 'vacation',
  start_date: '2025-08-20',
  end_date: '2025-08-25',
  description: 'Professional UI Test'
}, null, 2)}
                          </pre>
                        </div>
                        <button
                          onClick={async () => {
                            try {
                              const response = await fetch('http://localhost:8001/api/v1/requests/vacation', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({
                                  employee_id: 2,
                                  request_type: 'vacation',
                                  start_date: '2025-08-20',
                                  end_date: '2025-08-25',
                                  description: 'Professional UI Test'
                                })
                              });
                              const data = await response.json();
                              alert('✅ Success! Request ID: ' + data.id);
                              console.log('Vacation request response:', data);
                            } catch (error) {
                              alert('❌ Error: ' + error);
                              console.error('Vacation request error:', error);
                            }
                          }}
                          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                          Submit Vacation Request
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              } />
              
              {/* Default redirect */}
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </Suspense>
        </main>
      </div>
    </Router>
  );
}

export default App;