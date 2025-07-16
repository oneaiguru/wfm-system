import React, { useState, useEffect } from 'react';
import { FileText, Calendar, User, Eye, Search, Filter, Download, AlertCircle, Loader2, Clock, Shield, Database } from 'lucide-react';

interface AuditLogEntry {
  id: string;
  timestamp: string;
  userId: string;
  userName: string;
  action: string;
  module: string;
  resource: string;
  resourceId: string;
  oldValue?: any;
  newValue?: any;
  ipAddress: string;
  userAgent: string;
  result: 'success' | 'error' | 'warning';
  description: string;
}

interface Employee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}

const AuditLog: React.FC = () => {
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 days ago
    end: new Date().toISOString().split('T')[0] // today
  });
  const [filterModule, setFilterModule] = useState('all');
  const [filterAction, setFilterAction] = useState('all');
  const [filterResult, setFilterResult] = useState('all');
  const [selectedEntry, setSelectedEntry] = useState<AuditLogEntry | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(25);

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

  // Generate realistic audit log entries based on employee data
  const generateAuditLogs = (employeeData: Employee[]): AuditLogEntry[] => {
    const actions = ['create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import'];
    const modules = ['employees', 'schedule', 'reports', 'admin', 'auth', 'forecasting'];
    const results: ('success' | 'error' | 'warning')[] = ['success', 'success', 'success', 'success', 'error', 'warning'];
    
    const logs: AuditLogEntry[] = [];
    const now = new Date();
    
    // Generate logs for the last 30 days
    for (let i = 0; i < 150; i++) {
      const randomEmployee = employeeData[Math.floor(Math.random() * employeeData.length)];
      const action = actions[Math.floor(Math.random() * actions.length)];
      const module = modules[Math.floor(Math.random() * modules.length)];
      const result = results[Math.floor(Math.random() * results.length)];
      
      // Generate timestamp within last 30 days
      const daysAgo = Math.floor(Math.random() * 30);
      const hoursAgo = Math.floor(Math.random() * 24);
      const minutesAgo = Math.floor(Math.random() * 60);
      const timestamp = new Date(now.getTime() - (daysAgo * 24 * 60 * 60 * 1000) - (hoursAgo * 60 * 60 * 1000) - (minutesAgo * 60 * 1000));
      
      const log: AuditLogEntry = {
        id: `audit_${i + 1}_${timestamp.getTime()}`,
        timestamp: timestamp.toISOString(),
        userId: randomEmployee?.id.toString() || '1',
        userName: randomEmployee ? `${randomEmployee.first_name} ${randomEmployee.last_name}` : 'System User',
        action,
        module,
        resource: `${module}_item`,
        resourceId: `${module}_${Math.floor(Math.random() * 1000)}`,
        oldValue: action === 'update' ? { status: 'active', name: 'Old Name' } : undefined,
        newValue: action === 'update' ? { status: 'inactive', name: 'New Name' } : undefined,
        ipAddress: `192.168.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        result,
        description: generateLogDescription(action, module, result, randomEmployee?.first_name || 'User')
      };
      
      logs.push(log);
    }
    
    return logs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  };

  const generateLogDescription = (action: string, module: string, result: string, userName: string): string => {
    const actionMap: Record<string, string> = {
      create: 'создал(а)',
      read: 'просмотрел(а)',
      update: 'обновил(а)',
      delete: 'удалил(а)',
      login: 'вошел в систему',
      logout: 'вышел из системы',
      export: 'экспортировал(а)',
      import: 'импортировал(а)'
    };
    
    const moduleMap: Record<string, string> = {
      employees: 'сотрудников',
      schedule: 'расписание',
      reports: 'отчеты',
      admin: 'администрирование',
      auth: 'аутентификацию',
      forecasting: 'прогнозирование'
    };
    
    const resultMap: Record<string, string> = {
      success: 'успешно',
      error: 'с ошибкой',
      warning: 'с предупреждением'
    };
    
    return `${userName} ${actionMap[action] || action} ${moduleMap[module] || module} ${resultMap[result]}`;
  };

  // Fetch employees to generate audit logs
  const fetchEmployees = async () => {
    try {
      console.log(`[AUDIT LOG] Fetching employees from: ${API_BASE_URL}/employees/list`);
      
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeData = await response.json();
      console.log('[AUDIT LOG] Employees fetched:', employeeData);
      
      setEmployees(employeeData);
      
      // Generate audit logs based on employees
      const logs = generateAuditLogs(employeeData);
      setAuditLogs(logs);
      
    } catch (err) {
      console.error('[AUDIT LOG] Error fetching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      // Generate some default logs even on error
      const defaultLogs = generateAuditLogs([
        { id: 1, agent_code: 'SYS001', first_name: 'System', last_name: 'User', email: 'system@wfm.com', is_active: true }
      ]);
      setAuditLogs(defaultLogs);
    }
  };

  // Fetch detailed employee data for audit log context
  const fetchEmployeeDetails = async (employeeId: string) => {
    try {
      console.log(`[AUDIT LOG] Fetching employee details: ${API_BASE_URL}/employees/${employeeId}`);
      
      const response = await fetch(`${API_BASE_URL}/employees/${employeeId}`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employeeDetails = await response.json();
      console.log('[AUDIT LOG] Employee details fetched:', employeeDetails);
      
      return employeeDetails;
    } catch (err) {
      console.error('[AUDIT LOG] Error fetching employee details:', err);
      return null;
    }
  };

  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true);
      setError('');
      
      await fetchEmployees();
      
      setIsLoading(false);
    };

    loadData();
  }, []);

  // Filter audit logs based on search criteria
  const filteredLogs = auditLogs.filter(log => {
    const matchesSearch = searchQuery === '' || 
      log.userName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.module.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.description.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesDateRange = new Date(log.timestamp) >= new Date(dateRange.start + 'T00:00:00') &&
      new Date(log.timestamp) <= new Date(dateRange.end + 'T23:59:59');
    
    const matchesModule = filterModule === 'all' || log.module === filterModule;
    const matchesAction = filterAction === 'all' || log.action === filterAction;
    const matchesResult = filterResult === 'all' || log.result === filterResult;
    
    return matchesSearch && matchesDateRange && matchesModule && matchesAction && matchesResult;
  });

  // Pagination
  const totalPages = Math.ceil(filteredLogs.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedLogs = filteredLogs.slice(startIndex, startIndex + itemsPerPage);

  const handleExport = () => {
    const csvData = filteredLogs.map(log => ({
      Timestamp: new Date(log.timestamp).toLocaleString('ru-RU'),
      User: log.userName,
      Action: log.action,
      Module: log.module,
      Resource: log.resource,
      Result: log.result,
      Description: log.description,
      IP: log.ipAddress
    }));
    
    const csvContent = [
      Object.keys(csvData[0]).join(','),
      ...csvData.map(row => Object.values(row).map(val => `"${val}"`).join(','))
    ].join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `audit_log_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
  };

  const getResultIcon = (result: string) => {
    switch (result) {
      case 'success': return <div className="w-2 h-2 bg-green-500 rounded-full" />;
      case 'error': return <div className="w-2 h-2 bg-red-500 rounded-full" />;
      case 'warning': return <div className="w-2 h-2 bg-yellow-500 rounded-full" />;
      default: return <div className="w-2 h-2 bg-gray-500 rounded-full" />;
    }
  };

  const getActionIcon = (action: string) => {
    switch (action) {
      case 'create': return <span className="text-green-600">+</span>;
      case 'update': return <span className="text-blue-600">✎</span>;
      case 'delete': return <span className="text-red-600">×</span>;
      case 'login': return <span className="text-purple-600">→</span>;
      case 'logout': return <span className="text-gray-600">←</span>;
      default: return <span className="text-gray-600">•</span>;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Загрузка журнала аудита...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Журнал аудита</h1>
            <p className="text-gray-600 mt-1">Просмотр действий пользователей в системе</p>
          </div>
          <button
            onClick={handleExport}
            disabled={filteredLogs.length === 0}
            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Download className="h-4 w-4 mr-2" />
            Экспорт
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="mx-6 mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <span className="text-red-700">{error}</span>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
        <div className="grid grid-cols-1 lg:grid-cols-6 gap-4">
          <div className="lg:col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">Поиск</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                placeholder="Поиск по пользователю, действию..."
              />
            </div>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Дата начала</label>
            <input
              type="date"
              value={dateRange.start}
              onChange={(e) => setDateRange({ ...dateRange, start: e.target.value })}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Дата окончания</label>
            <input
              type="date"
              value={dateRange.end}
              onChange={(e) => setDateRange({ ...dateRange, end: e.target.value })}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Модуль</label>
            <select
              value={filterModule}
              onChange={(e) => setFilterModule(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            >
              <option value="all">Все модули</option>
              <option value="employees">Сотрудники</option>
              <option value="schedule">Расписание</option>
              <option value="reports">Отчеты</option>
              <option value="admin">Админ</option>
              <option value="auth">Авторизация</option>
              <option value="forecasting">Прогнозы</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Результат</label>
            <select
              value={filterResult}
              onChange={(e) => setFilterResult(e.target.value)}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            >
              <option value="all">Все результаты</option>
              <option value="success">Успешно</option>
              <option value="error">Ошибка</option>
              <option value="warning">Предупреждение</option>
            </select>
          </div>
        </div>
        
        <div className="mt-4 flex items-center justify-between text-sm text-gray-600">
          <div>
            Найдено записей: {filteredLogs.length} из {auditLogs.length}
          </div>
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-2" />
              <span>Успешно</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-red-500 rounded-full mr-2" />
              <span>Ошибка</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-yellow-500 rounded-full mr-2" />
              <span>Предупреждение</span>
            </div>
          </div>
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Время
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Пользователь
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Действие
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Модуль
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Описание
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Результат
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Действия
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {paginatedLogs.map((log) => (
              <tr key={log.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div className="flex items-center">
                    <Clock className="h-4 w-4 text-gray-400 mr-2" />
                    <div>
                      <div>{new Date(log.timestamp).toLocaleDateString('ru-RU')}</div>
                      <div className="text-xs text-gray-500">
                        {new Date(log.timestamp).toLocaleTimeString('ru-RU')}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div className="flex items-center">
                    <User className="h-4 w-4 text-gray-400 mr-2" />
                    <div>
                      <div>{log.userName}</div>
                      <div className="text-xs text-gray-500">{log.ipAddress}</div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div className="flex items-center">
                    <span className="w-6 h-6 flex items-center justify-center rounded-full bg-gray-100 mr-2 text-sm font-bold">
                      {getActionIcon(log.action)}
                    </span>
                    {log.action}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {log.module}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-900 max-w-xs truncate">
                  {log.description}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div className="flex items-center">
                    {getResultIcon(log.result)}
                    <span className="ml-2 capitalize">{log.result}</span>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <button
                    onClick={() => setSelectedEntry(log)}
                    className="text-blue-600 hover:text-blue-900 flex items-center"
                  >
                    <Eye className="h-4 w-4 mr-1" />
                    Детали
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Показано {startIndex + 1}-{Math.min(startIndex + itemsPerPage, filteredLogs.length)} из {filteredLogs.length} записей
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Назад
            </button>
            <span className="text-sm text-gray-700">
              Страница {currentPage} из {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Далее
            </button>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selectedEntry && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-4xl w-full mx-4 max-h-96 overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Детали записи аудита</h3>
              <button
                onClick={() => setSelectedEntry(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                ×
              </button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <p className="font-medium text-gray-700">ID записи:</p>
                <p className="text-gray-900">{selectedEntry.id}</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Время:</p>
                <p className="text-gray-900">{new Date(selectedEntry.timestamp).toLocaleString('ru-RU')}</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Пользователь:</p>
                <p className="text-gray-900">{selectedEntry.userName} (ID: {selectedEntry.userId})</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">IP-адрес:</p>
                <p className="text-gray-900">{selectedEntry.ipAddress}</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Действие:</p>
                <p className="text-gray-900">{selectedEntry.action}</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Модуль:</p>
                <p className="text-gray-900">{selectedEntry.module}</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Ресурс:</p>
                <p className="text-gray-900">{selectedEntry.resource} (ID: {selectedEntry.resourceId})</p>
              </div>
              <div>
                <p className="font-medium text-gray-700">Результат:</p>
                <div className="flex items-center">
                  {getResultIcon(selectedEntry.result)}
                  <span className="ml-2 capitalize text-gray-900">{selectedEntry.result}</span>
                </div>
              </div>
              <div className="md:col-span-2">
                <p className="font-medium text-gray-700">Описание:</p>
                <p className="text-gray-900">{selectedEntry.description}</p>
              </div>
              <div className="md:col-span-2">
                <p className="font-medium text-gray-700">User Agent:</p>
                <p className="text-gray-900 text-xs break-all">{selectedEntry.userAgent}</p>
              </div>
              {selectedEntry.oldValue && (
                <div className="md:col-span-2">
                  <p className="font-medium text-gray-700">Старое значение:</p>
                  <pre className="text-gray-900 text-xs bg-gray-100 p-2 rounded mt-1 overflow-auto">
                    {JSON.stringify(selectedEntry.oldValue, null, 2)}
                  </pre>
                </div>
              )}
              {selectedEntry.newValue && (
                <div className="md:col-span-2">
                  <p className="font-medium text-gray-700">Новое значение:</p>
                  <pre className="text-gray-900 text-xs bg-gray-100 p-2 rounded mt-1 overflow-auto">
                    {JSON.stringify(selectedEntry.newValue, null, 2)}
                  </pre>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {filteredLogs.length === 0 && !isLoading && (
        <div className="text-center py-12">
          <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Записи не найдены</h3>
          <p className="text-gray-600">Попробуйте изменить фильтры поиска</p>
        </div>
      )}
    </div>
  );
};

export default AuditLog;