// BDD: Integration Testing Component - Help INTEGRATION-OPUS test UI-API connections
import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, RefreshCw, AlertTriangle, Database, Zap, Users, BarChart } from 'lucide-react';
import apiIntegrationService from '../services/apiIntegrationService';
import vacancyPlanningService from '../services/vacancyPlanningService';

interface TestResult {
  name: string;
  endpoint: string;
  status: 'pending' | 'success' | 'failed' | 'testing';
  latency?: number;
  error?: string;
  data?: any;
}

interface TestSuite {
  name: string;
  description: string;
  icon: React.ComponentType<any>;
  tests: TestResult[];
}

export const IntegrationTester: React.FC = () => {
  const [testSuites, setTestSuites] = useState<TestSuite[]>([]);
  const [isRunning, setIsRunning] = useState(false);
  const [overallStatus, setOverallStatus] = useState<'idle' | 'running' | 'completed'>('idle');

  // Initialize test suites
  useEffect(() => {
    setTestSuites([
      {
        name: 'Core API Connections',
        description: 'Basic API connectivity and health checks',
        icon: Database,
        tests: [
          { name: 'API Health Check', endpoint: '/health', status: 'pending' },
          { name: 'Authentication', endpoint: '/auth/test', status: 'pending' },
          { name: 'Database Health', endpoint: '/integration/database/health', status: 'pending' },
          { name: 'Algorithm Status', endpoint: '/integration/algorithms/test-integration', status: 'pending' }
        ]
      },
      {
        name: 'Personnel Management',
        description: 'Employee and organizational data APIs',
        icon: Users,
        tests: [
          { name: 'Get Employees', endpoint: '/personnel/employees', status: 'pending' },
          { name: 'Create Employee', endpoint: 'POST /personnel/employees', status: 'pending' },
          { name: 'Assign Skills', endpoint: 'POST /personnel/employees/{id}/skills', status: 'pending' },
          { name: 'Work Settings', endpoint: '/personnel/employees/{id}/work-settings', status: 'pending' }
        ]
      },
      {
        name: 'Vacancy Planning',
        description: 'Vacancy planning module API connections',
        icon: BarChart,
        tests: [
          { name: 'Settings API', endpoint: '/vacancy-planning/settings', status: 'pending' },
          { name: 'Analysis API', endpoint: '/vacancy-planning/analysis', status: 'pending' },
          { name: 'Exchange Integration', endpoint: '/vacancy-planning/exchange', status: 'pending' },
          { name: 'Reporting API', endpoint: '/vacancy-planning/reports', status: 'pending' }
        ]
      },
      {
        name: 'Real-time Features',
        description: 'WebSocket and real-time update testing',
        icon: Zap,
        tests: [
          { name: 'WebSocket Connection', endpoint: 'ws://localhost:8001/ws', status: 'pending' },
          { name: 'Real-time Metrics', endpoint: '/monitoring/operational', status: 'pending' },
          { name: 'Agent Status Updates', endpoint: '/monitoring/agents', status: 'pending' },
          { name: 'Schedule Changes', endpoint: '/schedules/current', status: 'pending' }
        ]
      }
    ]);
  }, []);

  // Run individual test
  const runTest = async (suiteIndex: number, testIndex: number): Promise<void> => {
    const newSuites = [...testSuites];
    newSuites[suiteIndex].tests[testIndex].status = 'testing';
    setTestSuites(newSuites);

    const test = newSuites[suiteIndex].tests[testIndex];
    const startTime = Date.now();

    try {
      let result: any;
      
      // Route to appropriate service based on endpoint
      if (test.endpoint.includes('/vacancy-planning')) {
        result = await vacancyPlanningService.testIntegrationConnections();
      } else if (test.endpoint.includes('/health')) {
        result = await apiIntegrationService.healthCheck();
      } else if (test.endpoint.includes('/personnel')) {
        result = await apiIntegrationService.getPersonnelData();
      } else if (test.endpoint.includes('/monitoring')) {
        result = await apiIntegrationService.getDashboardData();
      } else if (test.endpoint.includes('/integration/algorithms')) {
        result = await apiIntegrationService.getAlgorithmStatus();
      } else if (test.endpoint.includes('/integration/database')) {
        result = await apiIntegrationService.getIntegrationStatus();
      } else {
        // Generic API test
        result = await fetch(`http://localhost:8001/api/v1${test.endpoint}`);
        result = await result.json();
      }

      const latency = Date.now() - startTime;
      
      newSuites[suiteIndex].tests[testIndex] = {
        ...test,
        status: 'success',
        latency,
        data: result
      };
      
      console.log(`[INTEGRATION] ✅ ${test.name} passed in ${latency}ms`);
    } catch (error) {
      const latency = Date.now() - startTime;
      
      newSuites[suiteIndex].tests[testIndex] = {
        ...test,
        status: 'failed',
        latency,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      console.log(`[INTEGRATION] ❌ ${test.name} failed: ${error}`);
    }

    setTestSuites(newSuites);
  };

  // Run all tests in a suite
  const runSuite = async (suiteIndex: number): Promise<void> => {
    const suite = testSuites[suiteIndex];
    
    for (let testIndex = 0; testIndex < suite.tests.length; testIndex++) {
      await runTest(suiteIndex, testIndex);
      // Small delay between tests
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  };

  // Run all tests
  const runAllTests = async (): Promise<void> => {
    setIsRunning(true);
    setOverallStatus('running');
    
    // Reset all tests
    const resetSuites = testSuites.map(suite => ({
      ...suite,
      tests: suite.tests.map(test => ({ ...test, status: 'pending' as const }))
    }));
    setTestSuites(resetSuites);

    // Run each suite sequentially
    for (let suiteIndex = 0; suiteIndex < testSuites.length; suiteIndex++) {
      await runSuite(suiteIndex);
    }

    setIsRunning(false);
    setOverallStatus('completed');
    
    // Generate summary report
    generateSummaryReport();
  };

  // Generate summary for INTEGRATION-OPUS
  const generateSummaryReport = (): void => {
    const allTests = testSuites.flatMap(suite => suite.tests);
    const totalTests = allTests.length;
    const passedTests = allTests.filter(test => test.status === 'success').length;
    const failedTests = allTests.filter(test => test.status === 'failed').length;
    const avgLatency = allTests
      .filter(test => test.latency)
      .reduce((sum, test) => sum + (test.latency || 0), 0) / allTests.length;

    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        total: totalTests,
        passed: passedTests,
        failed: failedTests,
        success_rate: Math.round((passedTests / totalTests) * 100),
        avg_latency: Math.round(avgLatency)
      },
      suites: testSuites.map(suite => ({
        name: suite.name,
        passed: suite.tests.filter(t => t.status === 'success').length,
        failed: suite.tests.filter(t => t.status === 'failed').length,
        tests: suite.tests
      })),
      recommendations: generateRecommendations(allTests)
    };

    console.log('[INTEGRATION] Test Summary Report:', report);
    
    // Store for INTEGRATION-OPUS
    localStorage.setItem('ui_integration_test_report', JSON.stringify(report, null, 2));
  };

  const generateRecommendations = (tests: TestResult[]): string[] => {
    const recommendations: string[] = [];
    
    const failedTests = tests.filter(test => test.status === 'failed');
    const slowTests = tests.filter(test => test.latency && test.latency > 2000);
    
    if (failedTests.length > 0) {
      recommendations.push(`Fix ${failedTests.length} failed API endpoints`);
    }
    
    if (slowTests.length > 0) {
      recommendations.push(`Optimize ${slowTests.length} slow endpoints (>2s response time)`);
    }
    
    const databaseTests = tests.filter(test => test.endpoint.includes('database'));
    if (databaseTests.some(test => test.status === 'failed')) {
      recommendations.push('Database integration needs attention - check DATABASE-OPUS migration');
    }
    
    const algorithmTests = tests.filter(test => test.endpoint.includes('algorithm'));
    if (algorithmTests.some(test => test.status === 'failed')) {
      recommendations.push('Algorithm integration issues - check ALGORITHM-OPUS connections');
    }
    
    return recommendations;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success': return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'failed': return <XCircle className="h-5 w-5 text-red-500" />;
      case 'testing': return <Clock className="h-5 w-5 text-blue-500 animate-pulse" />;
      default: return <div className="h-5 w-5 rounded-full border-2 border-gray-300" />;
    }
  };

  const getSuiteStatus = (suite: TestSuite) => {
    const tests = suite.tests;
    const passed = tests.filter(t => t.status === 'success').length;
    const failed = tests.filter(t => t.status === 'failed').length;
    const total = tests.length;
    
    if (failed > 0) return 'failed';
    if (passed === total) return 'success';
    if (tests.some(t => t.status === 'testing')) return 'testing';
    return 'pending';
  };

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              UI-API Integration Tester
            </h1>
            <p className="text-gray-600 mt-1">
              Test all API connections between UI-OPUS and INTEGRATION-OPUS
            </p>
          </div>
          
          <button
            onClick={runAllTests}
            disabled={isRunning}
            className={`flex items-center gap-2 px-4 py-2 rounded-md ${
              isRunning 
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                : 'bg-blue-600 text-white hover:bg-blue-700'
            }`}
          >
            {isRunning ? (
              <RefreshCw className="h-4 w-4 animate-spin" />
            ) : (
              <Zap className="h-4 w-4" />
            )}
            {isRunning ? 'Running Tests...' : 'Run All Tests'}
          </button>
        </div>
        
        {overallStatus === 'completed' && (
          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-800">
              ✅ Test run completed! Results saved to localStorage for INTEGRATION-OPUS analysis.
            </p>
          </div>
        )}
      </div>

      {/* Test Suites */}
      {testSuites.map((suite, suiteIndex) => {
        const Icon = suite.icon;
        const suiteStatus = getSuiteStatus(suite);
        
        return (
          <div key={suiteIndex} className="bg-white rounded-lg shadow">
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Icon className="h-6 w-6 text-gray-500" />
                  <div>
                    <h3 className="font-semibold">{suite.name}</h3>
                    <p className="text-sm text-gray-600">{suite.description}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  {getStatusIcon(suiteStatus)}
                  <button
                    onClick={() => runSuite(suiteIndex)}
                    disabled={isRunning}
                    className="text-sm px-3 py-1 border rounded hover:bg-gray-50 disabled:opacity-50"
                  >
                    Run Suite
                  </button>
                </div>
              </div>
            </div>
            
            <div className="p-4">
              <div className="space-y-3">
                {suite.tests.map((test, testIndex) => (
                  <div key={testIndex} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex items-center gap-3">
                      {getStatusIcon(test.status)}
                      <div>
                        <p className="font-medium">{test.name}</p>
                        <p className="text-sm text-gray-500">{test.endpoint}</p>
                        {test.error && (
                          <p className="text-sm text-red-600 mt-1">{test.error}</p>
                        )}
                      </div>
                    </div>
                    
                    <div className="text-right">
                      {test.latency && (
                        <p className="text-sm text-gray-600">{test.latency}ms</p>
                      )}
                      <button
                        onClick={() => runTest(suiteIndex, testIndex)}
                        disabled={isRunning || test.status === 'testing'}
                        className="text-xs px-2 py-1 border rounded hover:bg-gray-50 disabled:opacity-50"
                      >
                        Test
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );
      })}

      {/* Help for INTEGRATION-OPUS */}
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div className="flex items-start gap-3">
          <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5" />
          <div>
            <h4 className="font-medium text-yellow-800">For INTEGRATION-OPUS:</h4>
            <ul className="text-sm text-yellow-700 mt-1 list-disc list-inside space-y-1">
              <li>This tester connects UI to your API endpoints</li>
              <li>Failed tests indicate missing or broken API endpoints</li>
              <li>Test results are saved to localStorage for your analysis</li>
              <li>Check console for detailed error messages</li>
              <li>API base URL: http://localhost:8001/api/v1</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

