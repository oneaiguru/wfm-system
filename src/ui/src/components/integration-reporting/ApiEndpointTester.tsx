import React, { useState, useEffect } from 'react';
import { Play, Copy, Download, History, Code, Clock, CheckCircle, XCircle } from 'lucide-react';

interface EndpointTest {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  url: string;
  headers: Record<string, string>;
  body?: string;
  expectedStatus: number;
  description: string;
}

interface TestResult {
  id: string;
  endpointId: string;
  timestamp: Date;
  status: number;
  responseTime: number;
  success: boolean;
  response: any;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const ApiEndpointTester: React.FC = () => {
  const [endpoints, setEndpoints] = useState<EndpointTest[]>([]);
  const [testResults, setTestResults] = useState<TestResult[]>([]);
  const [selectedEndpoint, setSelectedEndpoint] = useState<EndpointTest | null>(null);
  const [isRunning, setIsRunning] = useState(false);
  const [runningEndpoints, setRunningEndpoints] = useState<Set<string>>(new Set());
  const [customRequest, setCustomRequest] = useState({
    method: 'GET' as const,
    url: '',
    headers: '{}',
    body: ''
  });

  const predefinedEndpoints: EndpointTest[] = [
    {
      id: 'employees-list',
      name: 'Список сотрудников',
      method: 'GET',
      url: `${API_BASE_URL}/employees`,
      headers: { 'Content-Type': 'application/json' },
      expectedStatus: 200,
      description: 'Получение списка всех сотрудников'
    },
    {
      id: 'employee-create',
      name: 'Создание сотрудника',
      method: 'POST',
      url: `${API_BASE_URL}/employees`,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        firstName: 'Тест',
        lastName: 'Сотрудник',
        email: 'test@example.com',
        phone: '+7-900-123-4567',
        position: 'Junior Operator',
        teamId: 't1',
        department: 'Support',
        contractType: 'full-time',
        workLocation: 'Moscow Office',
        hireDate: '2025-07-14'
      }, null, 2),
      expectedStatus: 201,
      description: 'Создание нового сотрудника'
    },
    {
      id: 'schedules-current',
      name: 'Текущие расписания',
      method: 'GET',
      url: `${API_BASE_URL}/schedules/current`,
      headers: { 'Content-Type': 'application/json' },
      expectedStatus: 200,
      description: 'Получение текущих расписаний'
    },
    {
      id: 'system-health',
      name: 'Статус системы',
      method: 'GET',
      url: `${API_BASE_URL}/system/health`,
      headers: { 'Content-Type': 'application/json' },
      expectedStatus: 200,
      description: 'Проверка состояния системы'
    },
    {
      id: 'auth-token',
      name: 'Получение токена',
      method: 'POST',
      url: `${API_BASE_URL}/auth/token`,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'test@example.com',
        password: 'testpassword'
      }, null, 2),
      expectedStatus: 200,
      description: 'Аутентификация и получение JWT токена'
    },
    {
      id: 'analytics-dashboard',
      name: 'Данные дашборда',
      method: 'GET',
      url: `${API_BASE_URL}/analytics/dashboard`,
      headers: { 'Content-Type': 'application/json' },
      expectedStatus: 200,
      description: 'Получение данных для дашборда аналитики'
    }
  ];

  useEffect(() => {
    setEndpoints(predefinedEndpoints);
    setSelectedEndpoint(predefinedEndpoints[0]);
  }, []);

  const runTest = async (endpoint: EndpointTest) => {
    setRunningEndpoints(prev => new Set(prev).add(endpoint.id));

    const startTime = Date.now();
    const testId = `test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    try {
      console.log(`[API TEST] Running test for ${endpoint.name}: ${endpoint.method} ${endpoint.url}`);

      const requestOptions: RequestInit = {
        method: endpoint.method,
        headers: endpoint.headers
      };

      if (endpoint.body && (endpoint.method === 'POST' || endpoint.method === 'PUT' || endpoint.method === 'PATCH')) {
        requestOptions.body = endpoint.body;
      }

      const response = await fetch(endpoint.url, requestOptions);
      const responseTime = Date.now() - startTime;
      
      let responseData;
      const contentType = response.headers.get('Content-Type');
      
      if (contentType && contentType.includes('application/json')) {
        responseData = await response.json();
      } else {
        responseData = await response.text();
      }

      const success = response.status === endpoint.expectedStatus;

      const result: TestResult = {
        id: testId,
        endpointId: endpoint.id,
        timestamp: new Date(),
        status: response.status,
        responseTime,
        success,
        response: responseData,
        error: success ? undefined : `Expected status ${endpoint.expectedStatus}, got ${response.status}`
      };

      setTestResults(prev => [result, ...prev.slice(0, 49)]); // Keep last 50 results
      console.log(`[API TEST] Test completed: ${success ? 'SUCCESS' : 'FAILED'} (${responseTime}ms)`);

    } catch (error) {
      const responseTime = Date.now() - startTime;
      const result: TestResult = {
        id: testId,
        endpointId: endpoint.id,
        timestamp: new Date(),
        status: 0,
        responseTime,
        success: false,
        response: null,
        error: error instanceof Error ? error.message : 'Network error'
      };

      setTestResults(prev => [result, ...prev.slice(0, 49)]);
      console.error(`[API TEST] Test failed for ${endpoint.name}:`, error);
    } finally {
      setRunningEndpoints(prev => {
        const newSet = new Set(prev);
        newSet.delete(endpoint.id);
        return newSet;
      });
    }
  };

  const runAllTests = async () => {
    setIsRunning(true);
    
    for (const endpoint of endpoints) {
      await runTest(endpoint);
      // Small delay between tests
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    setIsRunning(false);
  };

  const runCustomRequest = async () => {
    try {
      const headers = JSON.parse(customRequest.headers);
      const customEndpoint: EndpointTest = {
        id: 'custom',
        name: 'Пользовательский запрос',
        method: customRequest.method,
        url: customRequest.url,
        headers,
        body: customRequest.body || undefined,
        expectedStatus: 200,
        description: 'Пользовательский API запрос'
      };
      
      await runTest(customEndpoint);
    } catch (error) {
      console.error('Invalid custom request:', error);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const exportResults = () => {
    const data = JSON.stringify(testResults, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `api-test-results-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getStatusColor = (success: boolean, status: number) => {
    if (success) return 'text-green-600';
    if (status === 0) return 'text-red-600';
    if (status >= 400) return 'text-red-600';
    return 'text-yellow-600';
  };

  const formatResponseTime = (time: number) => {
    if (time < 1000) return `${time}ms`;
    return `${(time / 1000).toFixed(2)}s`;
  };

  const getResultsForEndpoint = (endpointId: string) => {
    return testResults.filter(result => result.endpointId === endpointId).slice(0, 5);
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Code className="h-6 w-6 mr-2 text-blue-600" />
          Тестер API Эндпоинтов
        </h2>
        <p className="mt-2 text-gray-600">
          Тестирование и мониторинг API эндпоинтов в реальном времени
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Endpoints List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Эндпоинты</h3>
              <button
                onClick={runAllTests}
                disabled={isRunning}
                className="flex items-center px-3 py-1 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                <Play className="h-4 w-4 mr-1" />
                Все тесты
              </button>
            </div>
            
            <div className="p-4 space-y-2">
              {endpoints.map((endpoint) => {
                const isRunning = runningEndpoints.has(endpoint.id);
                const recentResults = getResultsForEndpoint(endpoint.id);
                const lastResult = recentResults[0];
                
                return (
                  <div
                    key={endpoint.id}
                    className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                      selectedEndpoint?.id === endpoint.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                    onClick={() => setSelectedEndpoint(endpoint)}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-1 text-xs font-medium rounded ${
                          endpoint.method === 'GET' ? 'bg-green-100 text-green-800' :
                          endpoint.method === 'POST' ? 'bg-blue-100 text-blue-800' :
                          endpoint.method === 'PUT' ? 'bg-yellow-100 text-yellow-800' :
                          endpoint.method === 'DELETE' ? 'bg-red-100 text-red-800' :
                          'bg-gray-100 text-gray-800'
                        }`}>
                          {endpoint.method}
                        </span>
                        <span className="text-sm font-medium text-gray-900">{endpoint.name}</span>
                      </div>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          runTest(endpoint);
                        }}
                        disabled={isRunning}
                        className="p-1 text-blue-600 hover:text-blue-800 disabled:opacity-50"
                      >
                        <Play className={`h-4 w-4 ${isRunning ? 'animate-pulse' : ''}`} />
                      </button>
                    </div>
                    
                    {lastResult && (
                      <div className="flex items-center gap-2 text-xs">
                        {lastResult.success ? (
                          <CheckCircle className="h-3 w-3 text-green-500" />
                        ) : (
                          <XCircle className="h-3 w-3 text-red-500" />
                        )}
                        <span className={getStatusColor(lastResult.success, lastResult.status)}>
                          {lastResult.status}
                        </span>
                        <span className="text-gray-500">
                          {formatResponseTime(lastResult.responseTime)}
                        </span>
                        <span className="text-gray-400">
                          {lastResult.timestamp.toLocaleTimeString('ru-RU')}
                        </span>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Custom Request */}
          <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Пользовательский запрос</h3>
            </div>
            
            <div className="p-4 space-y-4">
              <div className="flex gap-2">
                <select
                  value={customRequest.method}
                  onChange={(e) => setCustomRequest(prev => ({ ...prev, method: e.target.value as any }))}
                  className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="GET">GET</option>
                  <option value="POST">POST</option>
                  <option value="PUT">PUT</option>
                  <option value="DELETE">DELETE</option>
                  <option value="PATCH">PATCH</option>
                </select>
                <input
                  type="text"
                  placeholder="URL эндпоинта"
                  value={customRequest.url}
                  onChange={(e) => setCustomRequest(prev => ({ ...prev, url: e.target.value }))}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <textarea
                placeholder="Headers (JSON)"
                value={customRequest.headers}
                onChange={(e) => setCustomRequest(prev => ({ ...prev, headers: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={3}
              />
              
              <textarea
                placeholder="Request Body (JSON)"
                value={customRequest.body}
                onChange={(e) => setCustomRequest(prev => ({ ...prev, body: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={4}
              />
              
              <button
                onClick={runCustomRequest}
                disabled={!customRequest.url}
                className="w-full flex items-center justify-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
              >
                <Play className="h-4 w-4 mr-2" />
                Выполнить запрос
              </button>
            </div>
          </div>
        </div>

        {/* Endpoint Details & Results */}
        <div className="lg:col-span-2 space-y-6">
          {/* Selected Endpoint Details */}
          {selectedEndpoint && (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="px-4 py-3 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900">{selectedEndpoint.name}</h3>
                <p className="text-sm text-gray-600">{selectedEndpoint.description}</p>
              </div>
              
              <div className="p-4 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">URL</label>
                  <div className="flex items-center gap-2">
                    <code className="flex-1 px-3 py-2 bg-gray-50 rounded-md text-sm">
                      {selectedEndpoint.method} {selectedEndpoint.url}
                    </code>
                    <button
                      onClick={() => copyToClipboard(selectedEndpoint.url)}
                      className="p-2 text-gray-500 hover:text-gray-700"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Headers</label>
                  <pre className="px-3 py-2 bg-gray-50 rounded-md text-sm overflow-x-auto">
                    {JSON.stringify(selectedEndpoint.headers, null, 2)}
                  </pre>
                </div>
                
                {selectedEndpoint.body && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Request Body</label>
                    <pre className="px-3 py-2 bg-gray-50 rounded-md text-sm overflow-x-auto">
                      {selectedEndpoint.body}
                    </pre>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Test Results */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Результаты тестов</h3>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-500">
                  {testResults.length} результатов
                </span>
                <button
                  onClick={exportResults}
                  className="flex items-center px-3 py-1 text-sm text-gray-600 hover:text-gray-800"
                >
                  <Download className="h-4 w-4 mr-1" />
                  Экспорт
                </button>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Время
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Эндпоинт
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Статус
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Время отклика
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Результат
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {testResults.map((result) => {
                    const endpoint = endpoints.find(e => e.id === result.endpointId);
                    return (
                      <tr key={result.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <div className="flex items-center gap-2">
                            <Clock className="h-4 w-4" />
                            {result.timestamp.toLocaleTimeString('ru-RU')}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {endpoint?.name || 'Пользовательский'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`text-sm font-medium ${getStatusColor(result.success, result.status)}`}>
                            {result.status || 'N/A'}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {formatResponseTime(result.responseTime)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            {result.success ? (
                              <CheckCircle className="h-4 w-4 text-green-500" />
                            ) : (
                              <XCircle className="h-4 w-4 text-red-500" />
                            )}
                            <span className={`text-sm ${result.success ? 'text-green-600' : 'text-red-600'}`}>
                              {result.success ? 'Успех' : (result.error || 'Ошибка')}
                            </span>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              
              {testResults.length === 0 && (
                <div className="p-8 text-center text-gray-500">
                  <History className="h-8 w-8 mx-auto mb-4 opacity-50" />
                  <p>Нет результатов тестов</p>
                  <p className="text-sm">Запустите тест для просмотра результатов</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ApiEndpointTester;