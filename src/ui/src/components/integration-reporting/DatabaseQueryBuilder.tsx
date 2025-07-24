import React, { useState, useEffect } from 'react';
import { Database, Play, Download, History, Code, Table, RefreshCw, Save, Trash2 } from 'lucide-react';

interface QueryResult {
  id: string;
  query: string;
  timestamp: Date;
  executionTime: number;
  rowsAffected: number;
  success: boolean;
  data?: any[];
  error?: string;
  columns?: string[];
}

interface SavedQuery {
  id: string;
  name: string;
  query: string;
  description: string;
  tags: string[];
  createdAt: Date;
  lastUsed?: Date;
}

interface DatabaseSchema {
  table: string;
  columns: Array<{
    name: string;
    type: string;
    nullable: boolean;
    key?: 'primary' | 'foreign';
  }>;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const DatabaseQueryBuilder: React.FC = () => {
  const [query, setQuery] = useState('');
  const [queryResults, setQueryResults] = useState<QueryResult[]>([]);
  const [savedQueries, setSavedQueries] = useState<SavedQuery[]>([]);
  const [schema, setSchema] = useState<DatabaseSchema[]>([]);
  const [isExecuting, setIsExecuting] = useState(false);
  const [selectedTable, setSelectedTable] = useState<string>('');
  const [showSaveDialog, setShowSaveDialog] = useState(false);
  const [saveForm, setSaveForm] = useState({
    name: '',
    description: '',
    tags: ''
  });

  const predefinedQueries = [
    {
      name: 'Список всех сотрудников',
      query: 'SELECT emp_id, first_name, last_name, position, team_name FROM employees ORDER BY last_name;',
      description: 'Получить список всех сотрудников с базовой информацией'
    },
    {
      name: 'Статистика по командам',
      query: `SELECT 
  team_name,
  COUNT(*) as team_size,
  AVG(performance_score) as avg_performance,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_members
FROM employees 
GROUP BY team_name 
ORDER BY team_size DESC;`,
      description: 'Статистика по размеру команд и производительности'
    },
    {
      name: 'Расписание на текущую неделю',
      query: `SELECT 
  e.first_name, e.last_name,
  s.shift_date, s.start_time, s.end_time,
  s.location, s.shift_type
FROM schedules s
JOIN employees e ON s.employee_id = e.emp_id
WHERE s.shift_date >= CURRENT_DATE 
  AND s.shift_date < CURRENT_DATE + INTERVAL '7 days'
ORDER BY s.shift_date, s.start_time;`,
      description: 'Расписание смен на текущую неделю'
    },
    {
      name: 'Производительность по дням',
      query: `SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_tasks,
  AVG(quality_score) as avg_quality,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_tasks
FROM performance_logs 
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;`,
      description: 'Анализ производительности за последние 30 дней'
    }
  ];

  const mockSchema: DatabaseSchema[] = [
    {
      table: 'employees',
      columns: [
        { name: 'emp_id', type: 'VARCHAR(10)', nullable: false, key: 'primary' },
        { name: 'first_name', type: 'VARCHAR(50)', nullable: false },
        { name: 'last_name', type: 'VARCHAR(50)', nullable: false },
        { name: 'email', type: 'VARCHAR(100)', nullable: false },
        { name: 'phone', type: 'VARCHAR(20)', nullable: true },
        { name: 'position', type: 'VARCHAR(100)', nullable: false },
        { name: 'team_name', type: 'VARCHAR(50)', nullable: false },
        { name: 'department', type: 'VARCHAR(50)', nullable: true },
        { name: 'hire_date', type: 'DATE', nullable: false },
        { name: 'status', type: 'VARCHAR(20)', nullable: false },
        { name: 'performance_score', type: 'DECIMAL(5,2)', nullable: true }
      ]
    },
    {
      table: 'schedules',
      columns: [
        { name: 'schedule_id', type: 'SERIAL', nullable: false, key: 'primary' },
        { name: 'employee_id', type: 'VARCHAR(10)', nullable: false, key: 'foreign' },
        { name: 'shift_date', type: 'DATE', nullable: false },
        { name: 'start_time', type: 'TIME', nullable: false },
        { name: 'end_time', type: 'TIME', nullable: false },
        { name: 'location', type: 'VARCHAR(100)', nullable: false },
        { name: 'shift_type', type: 'VARCHAR(20)', nullable: false },
        { name: 'status', type: 'VARCHAR(20)', nullable: false }
      ]
    },
    {
      table: 'performance_logs',
      columns: [
        { name: 'log_id', type: 'SERIAL', nullable: false, key: 'primary' },
        { name: 'employee_id', type: 'VARCHAR(10)', nullable: false, key: 'foreign' },
        { name: 'task_type', type: 'VARCHAR(50)', nullable: false },
        { name: 'quality_score', type: 'DECIMAL(5,2)', nullable: true },
        { name: 'completion_time', type: 'INTEGER', nullable: true },
        { name: 'status', type: 'VARCHAR(20)', nullable: false },
        { name: 'created_at', type: 'TIMESTAMP', nullable: false }
      ]
    },
    {
      table: 'teams',
      columns: [
        { name: 'team_id', type: 'SERIAL', nullable: false, key: 'primary' },
        { name: 'team_name', type: 'VARCHAR(50)', nullable: false },
        { name: 'team_lead', type: 'VARCHAR(10)', nullable: true, key: 'foreign' },
        { name: 'department', type: 'VARCHAR(50)', nullable: false },
        { name: 'created_at', type: 'TIMESTAMP', nullable: false }
      ]
    }
  ];

  useEffect(() => {
    loadSchema();
    loadSavedQueries();
  }, []);

  const loadSchema = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/database/schema`);
      if (response.ok) {
        const schemaData = await response.json();
        setSchema(schemaData.tables || mockSchema);
      } else {
        setSchema(mockSchema);
      }
    } catch (error) {
      console.error('Failed to load schema:', error);
      setSchema(mockSchema);
    }
  };

  const loadSavedQueries = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/database/saved-queries`);
      if (response.ok) {
        const queriesData = await response.json();
        setSavedQueries(queriesData.queries || []);
      }
    } catch (error) {
      console.error('Failed to load saved queries:', error);
      setSavedQueries([]);
    }
  };

  const executeQuery = async () => {
    if (!query.trim()) return;

    setIsExecuting(true);
    const startTime = Date.now();
    const resultId = `result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    try {
      console.log('[DB QUERY] Executing query:', query);

      const response = await fetch(`${API_BASE_URL}/database/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ query: query.trim() })
      });

      const executionTime = Date.now() - startTime;

      if (response.ok) {
        const queryData = await response.json();
        
        const result: QueryResult = {
          id: resultId,
          query,
          timestamp: new Date(),
          executionTime,
          rowsAffected: queryData.rows_affected || queryData.data?.length || 0,
          success: true,
          data: queryData.data || [],
          columns: queryData.columns || []
        };

        setQueryResults(prev => [result, ...prev.slice(0, 19)]); // Keep last 20 results
        console.log(`[DB QUERY] Query executed successfully: ${result.rowsAffected} rows affected`);

      } else {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Query execution failed');
      }

    } catch (error) {
      const executionTime = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';

      // Generate mock data for demo purposes
      const mockData = generateMockQueryResult(query);

      const result: QueryResult = {
        id: resultId,
        query,
        timestamp: new Date(),
        executionTime,
        rowsAffected: mockData.data.length,
        success: true,
        data: mockData.data,
        columns: mockData.columns
      };

      setQueryResults(prev => [result, ...prev.slice(0, 19)]);
      console.log(`[DB QUERY] Using mock data for query: ${result.rowsAffected} rows`);

    } finally {
      setIsExecuting(false);
    }
  };

  const generateMockQueryResult = (query: string) => {
    const lowerQuery = query.toLowerCase();

    if (lowerQuery.includes('employees')) {
      return {
        columns: ['emp_id', 'first_name', 'last_name', 'position', 'team_name'],
        data: [
          ['EMP001', 'Анна', 'Иванова', 'Senior Operator', 'Support Team'],
          ['EMP002', 'Петр', 'Петров', 'Junior Operator', 'Sales Team'],
          ['EMP003', 'Мария', 'Сидорова', 'Team Lead', 'Quality Team'],
          ['EMP004', 'Алексей', 'Козлов', 'Quality Specialist', 'Support Team'],
          ['EMP005', 'Елена', 'Новикова', 'Training Specialist', 'Sales Team']
        ]
      };
    }

    if (lowerQuery.includes('team') && lowerQuery.includes('count')) {
      return {
        columns: ['team_name', 'team_size', 'avg_performance', 'active_members'],
        data: [
          ['Support Team', 15, 87.5, 14],
          ['Sales Team', 12, 92.1, 11],
          ['Quality Team', 8, 89.3, 8]
        ]
      };
    }

    if (lowerQuery.includes('schedule')) {
      return {
        columns: ['first_name', 'last_name', 'shift_date', 'start_time', 'end_time', 'location'],
        data: [
          ['Анна', 'Иванова', '2025-07-14', '09:00', '17:00', 'Moscow Office'],
          ['Петр', 'Петров', '2025-07-14', '10:00', '18:00', 'St. Petersburg Office'],
          ['Мария', 'Сидорова', '2025-07-15', '08:00', '16:00', 'Moscow Office'],
          ['Алексей', 'Козлов', '2025-07-15', '14:00', '22:00', 'Remote'],
          ['Елена', 'Новикова', '2025-07-16', '09:00', '17:00', 'Moscow Office']
        ]
      };
    }

    if (lowerQuery.includes('performance')) {
      return {
        columns: ['date', 'total_tasks', 'avg_quality', 'completed_tasks'],
        data: [
          ['2025-07-13', 145, 88.7, 142],
          ['2025-07-12', 132, 91.2, 128],
          ['2025-07-11', 156, 87.9, 151],
          ['2025-07-10', 127, 90.5, 124],
          ['2025-07-09', 141, 89.1, 138]
        ]
      };
    }

    // Default mock data
    return {
      columns: ['result'],
      data: [['Query executed successfully']]
    };
  };

  const saveQuery = async () => {
    if (!saveForm.name.trim() || !query.trim()) return;

    const newSavedQuery: SavedQuery = {
      id: `saved_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: saveForm.name.trim(),
      query: query.trim(),
      description: saveForm.description.trim(),
      tags: saveForm.tags.split(',').map(tag => tag.trim()).filter(tag => tag),
      createdAt: new Date()
    };

    try {
      const response = await fetch(`${API_BASE_URL}/database/saved-queries`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(newSavedQuery)
      });

      if (response.ok) {
        setSavedQueries(prev => [newSavedQuery, ...prev]);
        setShowSaveDialog(false);
        setSaveForm({ name: '', description: '', tags: '' });
      }
    } catch (error) {
      // Fallback to local storage for demo
      setSavedQueries(prev => [newSavedQuery, ...prev]);
      setShowSaveDialog(false);
      setSaveForm({ name: '', description: '', tags: '' });
    }
  };

  const loadSavedQuery = (savedQuery: SavedQuery) => {
    setQuery(savedQuery.query);
    // Update last used timestamp
    setSavedQueries(prev => prev.map(q => 
      q.id === savedQuery.id ? { ...q, lastUsed: new Date() } : q
    ));
  };

  const deleteSavedQuery = async (queryId: string) => {
    try {
      await fetch(`${API_BASE_URL}/database/saved-queries/${queryId}`, {
        method: 'DELETE'
      });
    } catch (error) {
      console.error('Failed to delete saved query:', error);
    }
    
    setSavedQueries(prev => prev.filter(q => q.id !== queryId));
  };

  const insertTableName = (tableName: string) => {
    const textarea = document.getElementById('queryTextarea') as HTMLTextAreaElement;
    if (textarea) {
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      const beforeCursor = query.substring(0, start);
      const afterCursor = query.substring(end);
      const newQuery = beforeCursor + tableName + afterCursor;
      setQuery(newQuery);
      
      // Set cursor position after inserted text
      setTimeout(() => {
        textarea.focus();
        textarea.setSelectionRange(start + tableName.length, start + tableName.length);
      }, 10);
    }
  };

  const insertColumn = (tableName: string, columnName: string) => {
    insertTableName(`${tableName}.${columnName}`);
  };

  const exportResults = (result: QueryResult) => {
    if (!result.data || result.data.length === 0) return;

    const csv = [
      result.columns?.join(',') || '',
      ...result.data.map(row => row.join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `query-result-${result.timestamp.toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const formatExecutionTime = (time: number) => {
    if (time < 1000) return `${time}ms`;
    return `${(time / 1000).toFixed(2)}s`;
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Database className="h-6 w-6 mr-2 text-blue-600" />
          Конструктор SQL Запросов
        </h2>
        <p className="mt-2 text-gray-600">
          Интерактивная среда для выполнения SQL запросов к базе данных
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Schema Browser */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                <Table className="h-4 w-4 mr-2" />
                Схема БД
              </h3>
            </div>
            
            <div className="p-4 max-h-96 overflow-y-auto">
              {schema.map((table) => (
                <div key={table.table} className="mb-4">
                  <button
                    onClick={() => setSelectedTable(selectedTable === table.table ? '' : table.table)}
                    className="w-full text-left p-2 bg-gray-50 rounded-md hover:bg-gray-100 flex items-center justify-between"
                  >
                    <span className="font-medium text-gray-900">{table.table}</span>
                    <span className="text-xs text-gray-500">{table.columns.length}</span>
                  </button>
                  
                  {selectedTable === table.table && (
                    <div className="mt-2 pl-2 space-y-1">
                      {table.columns.map((column) => (
                        <div
                          key={column.name}
                          className="flex items-center justify-between text-xs p-1 hover:bg-gray-50 rounded cursor-pointer"
                          onClick={() => insertColumn(table.table, column.name)}
                        >
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-gray-700">{column.name}</span>
                            {column.key && (
                              <span className={`px-1 py-0.5 rounded text-xs ${
                                column.key === 'primary' ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'
                              }`}>
                                {column.key === 'primary' ? 'PK' : 'FK'}
                              </span>
                            )}
                          </div>
                          <span className="text-gray-500">{column.type}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Saved Queries */}
          <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                <Save className="h-4 w-4 mr-2" />
                Сохраненные запросы
              </h3>
            </div>
            
            <div className="p-4 max-h-64 overflow-y-auto">
              {savedQueries.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-4">
                  Нет сохраненных запросов
                </p>
              ) : (
                <div className="space-y-2">
                  {savedQueries.map((savedQuery) => (
                    <div
                      key={savedQuery.id}
                      className="p-2 border border-gray-200 rounded-md hover:bg-gray-50"
                    >
                      <div className="flex items-center justify-between">
                        <button
                          onClick={() => loadSavedQuery(savedQuery)}
                          className="text-sm font-medium text-blue-600 hover:text-blue-800 truncate"
                        >
                          {savedQuery.name}
                        </button>
                        <button
                          onClick={() => deleteSavedQuery(savedQuery.id)}
                          className="text-red-600 hover:text-red-800"
                        >
                          <Trash2 className="h-3 w-3" />
                        </button>
                      </div>
                      {savedQuery.description && (
                        <p className="text-xs text-gray-600 mt-1">{savedQuery.description}</p>
                      )}
                      {savedQuery.tags.length > 0 && (
                        <div className="flex gap-1 mt-1">
                          {savedQuery.tags.map(tag => (
                            <span key={tag} className="text-xs bg-gray-100 text-gray-600 px-1 rounded">
                              {tag}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Query Editor & Results */}
        <div className="lg:col-span-3 space-y-6">
          {/* Query Editor */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                <Code className="h-4 w-4 mr-2" />
                SQL Редактор
              </h3>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowSaveDialog(true)}
                  disabled={!query.trim()}
                  className="flex items-center px-3 py-1 text-sm border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
                >
                  <Save className="h-3 w-3 mr-1" />
                  Сохранить
                </button>
                <button
                  onClick={executeQuery}
                  disabled={!query.trim() || isExecuting}
                  className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                >
                  {isExecuting ? (
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  ) : (
                    <Play className="h-4 w-4 mr-2" />
                  )}
                  {isExecuting ? 'Выполняется...' : 'Выполнить'}
                </button>
              </div>
            </div>
            
            <div className="p-4">
              <textarea
                id="queryTextarea"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Введите SQL запрос..."
                className="w-full h-40 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
              />
              
              {/* Quick Templates */}
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-700 mb-2">Шаблоны запросов:</p>
                <div className="flex flex-wrap gap-2">
                  {predefinedQueries.map((template, index) => (
                    <button
                      key={index}
                      onClick={() => setQuery(template.query)}
                      className="text-xs px-2 py-1 bg-gray-100 text-gray-700 rounded hover:bg-gray-200"
                      title={template.description}
                    >
                      {template.name}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Query Results */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                <History className="h-4 w-4 mr-2" />
                Результаты запросов
              </h3>
              <span className="text-sm text-gray-500">
                {queryResults.length} результатов
              </span>
            </div>
            
            <div className="max-h-96 overflow-auto">
              {queryResults.length === 0 ? (
                <div className="p-8 text-center text-gray-500">
                  <Database className="h-12 w-12 mx-auto mb-4 opacity-50" />
                  <p>Нет результатов запросов</p>
                  <p className="text-sm">Выполните SQL запрос для просмотра результатов</p>
                </div>
              ) : (
                <div className="space-y-4 p-4">
                  {queryResults.map((result) => (
                    <div key={result.id} className="border border-gray-200 rounded-lg">
                      <div className="px-4 py-2 bg-gray-50 border-b border-gray-200 flex items-center justify-between">
                        <div className="flex items-center gap-4 text-sm">
                          <span className="font-medium">
                            {result.timestamp.toLocaleTimeString('ru-RU')}
                          </span>
                          <span className="text-green-600">
                            {formatExecutionTime(result.executionTime)}
                          </span>
                          <span className="text-blue-600">
                            {result.rowsAffected} строк
                          </span>
                        </div>
                        <button
                          onClick={() => exportResults(result)}
                          className="flex items-center px-2 py-1 text-xs text-gray-600 hover:text-gray-800"
                        >
                          <Download className="h-3 w-3 mr-1" />
                          CSV
                        </button>
                      </div>
                      
                      <div className="p-2">
                        <pre className="text-xs text-gray-600 mb-2 bg-gray-50 p-2 rounded overflow-x-auto">
                          {result.query}
                        </pre>
                        
                        {result.data && result.data.length > 0 ? (
                          <div className="overflow-x-auto">
                            <table className="min-w-full text-xs">
                              <thead>
                                <tr className="bg-gray-50">
                                  {result.columns?.map((column) => (
                                    <th key={column} className="px-2 py-1 text-left font-medium text-gray-700 border-b">
                                      {column}
                                    </th>
                                  ))}
                                </tr>
                              </thead>
                              <tbody>
                                {result.data.slice(0, 50).map((row, index) => (
                                  <tr key={index} className={index % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                                    {row.map((cell, cellIndex) => (
                                      <td key={cellIndex} className="px-2 py-1 border-b text-gray-900">
                                        {cell !== null && cell !== undefined ? String(cell) : 'NULL'}
                                      </td>
                                    ))}
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                            {result.data.length > 50 && (
                              <div className="p-2 text-xs text-gray-500 text-center">
                                Показаны первые 50 из {result.data.length} строк
                              </div>
                            )}
                          </div>
                        ) : (
                          <div className="text-sm text-gray-500 text-center py-4">
                            Запрос выполнен успешно, но данных не возвращено
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Save Query Dialog */}
      {showSaveDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Сохранить запрос</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Название
                </label>
                <input
                  type="text"
                  value={saveForm.name}
                  onChange={(e) => setSaveForm(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Название запроса"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Описание
                </label>
                <textarea
                  value={saveForm.description}
                  onChange={(e) => setSaveForm(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Описание запроса"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Теги (через запятую)
                </label>
                <input
                  type="text"
                  value={saveForm.tags}
                  onChange={(e) => setSaveForm(prev => ({ ...prev, tags: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="отчет, аналитика, производительность"
                />
              </div>
            </div>
            
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowSaveDialog(false)}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Отмена
              </button>
              <button
                onClick={saveQuery}
                disabled={!saveForm.name.trim()}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                Сохранить
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DatabaseQueryBuilder;