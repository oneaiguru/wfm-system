import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './index.css';

// Direct imports for core components
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import { EmployeePortal } from './modules/employee-portal';
import { IntegrationTester } from './components/IntegrationTester';

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
                <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                  <a href="/login" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Login
                  </a>
                  <a href="/dashboard" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Dashboard
                  </a>
                  <a href="/employee-portal" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Employee Portal
                  </a>
                  <a href="/vacation-test" className="border-indigo-500 text-indigo-600 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Vacation Test
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
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/employee-portal/*" element={<EmployeePortal />} />
              <Route path="/integration-tester" element={<IntegrationTester />} />
              
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
                              const response = await fetch('http://localhost:8000/api/v1/requests/vacation', {
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