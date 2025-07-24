import React, { useState, useEffect } from 'react';
import { 
  History, 
  CheckCircle, 
  XCircle, 
  Clock, 
  User, 
  Calendar, 
  Filter,
  Search,
  Download,
  RefreshCw,
  Eye,
  ArrowUpDown,
  BarChart3,
  FileText,
  Users
} from 'lucide-react';

interface Employee {
  employee_id: number;
  first_name: string;
  last_name: string;
  email: string;
  department: string;
  position: string;
  hire_date: string;
  status: string;
}

interface WorkflowHistoryRecord {
  id: string;
  request_id: string;
  employee_id: number;
  employee_name: string;
  request_type: string;
  start_date: string;
  end_date: string;
  duration_days: number;
  submitted_at: string;
  processed_at: string;
  status: 'approved' | 'rejected' | 'cancelled';
  approver: string;
  processing_time_hours: number;
  escalation_level: number;
  comments: string;
  department: string;
}

type SortField = 'processed_at' | 'employee_name' | 'processing_time_hours' | 'submitted_at';
type SortDirection = 'asc' | 'desc';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const WorkflowHistory: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [historyRecords, setHistoryRecords] = useState<WorkflowHistoryRecord[]>([]);
  const [filteredRecords, setFilteredRecords] = useState<WorkflowHistoryRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedDepartment, setSelectedDepartment] = useState<string>('all');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [dateRange, setDateRange] = useState<{ start: string; end: string }>({
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0]
  });
  const [sortField, setSortField] = useState<SortField>('processed_at');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  const [selectedRecord, setSelectedRecord] = useState<WorkflowHistoryRecord | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState<boolean>(false);

  useEffect(() => {
    fetchEmployees();
    fetchWorkflowHistory();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [historyRecords, searchTerm, selectedStatus, selectedDepartment, selectedType, dateRange, sortField, sortDirection]);

  const fetchEmployees = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/employees/list`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data: Employee[] = await response.json();
      setEmployees(data);
    } catch (err) {
      console.error('[WorkflowHistory] Error fetching employees:', err);
    }
  };

  const fetchWorkflowHistory = async () => {
    setLoading(true);
    setError('');
    
    try {
      // In a real implementation, this would be a dedicated endpoint for workflow history
      // For now, we'll generate mock data based on employees list
      const response = await fetch(`${API_BASE_URL}/employees/list`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const employees: Employee[] = await response.json();
      
      // Generate mock workflow history records
      const mockHistory: WorkflowHistoryRecord[] = [];
      const requestTypes = ['vacation', 'sick_leave', 'personal_leave', 'business_trip'];
      const statuses: ('approved' | 'rejected' | 'cancelled')[] = ['approved', 'rejected', 'cancelled'];
      const approvers = ['Иванов И.И.', 'Петров П.П.', 'Сидоров С.С.', 'Козлов К.К.'];
      
      for (let i = 0; i < Math.min(100, employees.length * 3); i++) {
        const employee = employees[Math.floor(Math.random() * employees.length)];
        const requestType = requestTypes[Math.floor(Math.random() * requestTypes.length)];
        const status = statuses[Math.floor(Math.random() * statuses.length)];
        const submittedAt = new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000);
        const processingHours = Math.floor(Math.random() * 72) + 1;
        const processedAt = new Date(submittedAt.getTime() + processingHours * 60 * 60 * 1000);
        
        const record: WorkflowHistoryRecord = {
          id: `history_${i}`,
          request_id: `REQ_${Date.now()}_${i}`,
          employee_id: employee.employee_id,
          employee_name: `${employee.first_name} ${employee.last_name}`,
          request_type: requestType,
          start_date: new Date(submittedAt.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          end_date: new Date(submittedAt.getTime() + (7 + Math.floor(Math.random() * 14)) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          duration_days: Math.floor(Math.random() * 14) + 1,
          submitted_at: submittedAt.toISOString(),
          processed_at: processedAt.toISOString(),
          status: status,
          approver: approvers[Math.floor(Math.random() * approvers.length)],
          processing_time_hours: processingHours,
          escalation_level: Math.floor(Math.random() * 3),
          comments: status === 'rejected' ? 'Недостаточно дней в остатке отпуска' : 
                   status === 'cancelled' ? 'Отозвано сотрудником' : 
                   'Одобрено в соответствии с политикой компании',
          department: employee.department
        };
        
        mockHistory.push(record);
      }
      
      // Sort by processed date (newest first)
      mockHistory.sort((a, b) => new Date(b.processed_at).getTime() - new Date(a.processed_at).getTime());
      
      setHistoryRecords(mockHistory);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки истории workflow');
      console.error('[WorkflowHistory] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = [...historyRecords];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(record => 
        record.employee_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        record.request_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        record.approver.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply status filter
    if (selectedStatus !== 'all') {
      filtered = filtered.filter(record => record.status === selectedStatus);
    }

    // Apply department filter
    if (selectedDepartment !== 'all') {
      filtered = filtered.filter(record => record.department === selectedDepartment);
    }

    // Apply type filter
    if (selectedType !== 'all') {
      filtered = filtered.filter(record => record.request_type === selectedType);
    }

    // Apply date range filter
    if (dateRange.start && dateRange.end) {
      const startDate = new Date(dateRange.start);
      const endDate = new Date(dateRange.end);
      endDate.setHours(23, 59, 59, 999); // Include the entire end date
      
      filtered = filtered.filter(record => {
        const processedDate = new Date(record.processed_at);
        return processedDate >= startDate && processedDate <= endDate;
      });
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aVal: string | number, bVal: string | number;
      
      switch (sortField) {
        case 'employee_name':
          aVal = a.employee_name;
          bVal = b.employee_name;
          break;
        case 'processing_time_hours':
          aVal = a.processing_time_hours;
          bVal = b.processing_time_hours;
          break;
        case 'submitted_at':
          aVal = a.submitted_at;
          bVal = b.submitted_at;
          break;
        default:
          aVal = a.processed_at;
          bVal = b.processed_at;
      }

      if (typeof aVal === 'string' && typeof bVal === 'string') {
        const result = aVal.localeCompare(bVal);
        return sortDirection === 'asc' ? result : -result;
      }

      if (typeof aVal === 'number' && typeof bVal === 'number') {
        const result = aVal - bVal;
        return sortDirection === 'asc' ? result : -result;
      }

      return 0;
    });

    setFilteredRecords(filtered);
  };

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const showDetails = (record: WorkflowHistoryRecord) => {
    setSelectedRecord(record);
    setShowDetailsModal(true);
  };

  const exportToCSV = () => {
    const headers = [
      'ID заявки',
      'Сотрудник',
      'Тип заявки',
      'Дата подачи',
      'Дата обработки',
      'Статус',
      'Утверждающий',
      'Время обработки (ч)',
      'Отдел',
      'Комментарии'
    ];

    const csvContent = [
      headers.join(','),
      ...filteredRecords.map(record => [
        record.request_id,
        record.employee_name,
        record.request_type,
        new Date(record.submitted_at).toLocaleDateString('ru-RU'),
        new Date(record.processed_at).toLocaleDateString('ru-RU'),
        record.status,
        record.approver,
        record.processing_time_hours,
        record.department,
        `"${record.comments}"`
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `workflow_history_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      case 'cancelled': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4" />;
      case 'rejected': return <XCircle className="h-4 w-4" />;
      case 'cancelled': return <Clock className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleString('ru-RU', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const uniqueDepartments = Array.from(new Set(historyRecords.map(record => record.department)));
  const uniqueTypes = Array.from(new Set(historyRecords.map(record => record.request_type)));

  // Calculate statistics
  const stats = {
    total: filteredRecords.length,
    approved: filteredRecords.filter(r => r.status === 'approved').length,
    rejected: filteredRecords.filter(r => r.status === 'rejected').length,
    avgProcessingTime: filteredRecords.length > 0 
      ? filteredRecords.reduce((sum, r) => sum + r.processing_time_hours, 0) / filteredRecords.length 
      : 0
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">История workflow</h1>
            <p className="text-gray-600">Архив обработанных заявок</p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={exportToCSV}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center gap-2"
            >
              <Download className="h-4 w-4" />
              Экспорт CSV
            </button>
            <button
              onClick={fetchWorkflowHistory}
              className="p-2 bg-white rounded-lg border hover:bg-gray-50 transition-colors"
            >
              <RefreshCw className={`h-5 w-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <XCircle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Всего обработано</p>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
            </div>
            <FileText className="h-8 w-8 text-blue-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Одобрено</p>
              <p className="text-2xl font-bold text-green-600">{stats.approved}</p>
            </div>
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <div className="mt-2 text-sm text-gray-500">
            {stats.total > 0 ? Math.round((stats.approved / stats.total) * 100) : 0}% от общего числа
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Отклонено</p>
              <p className="text-2xl font-bold text-red-600">{stats.rejected}</p>
            </div>
            <XCircle className="h-8 w-8 text-red-600" />
          </div>
          <div className="mt-2 text-sm text-gray-500">
            {stats.total > 0 ? Math.round((stats.rejected / stats.total) * 100) : 0}% от общего числа
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ср. время обработки</p>
              <p className="text-2xl font-bold text-orange-600">{stats.avgProcessingTime.toFixed(1)}ч</p>
            </div>
            <BarChart3 className="h-8 w-8 text-orange-600" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4">
            {/* Search */}
            <div className="lg:col-span-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Поиск по сотруднику, ID заявки..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            {/* Status Filter */}
            <div>
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все статусы</option>
                <option value="approved">Одобрено</option>
                <option value="rejected">Отклонено</option>
                <option value="cancelled">Отменено</option>
              </select>
            </div>

            {/* Department Filter */}
            <div>
              <select
                value={selectedDepartment}
                onChange={(e) => setSelectedDepartment(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все отделы</option>
                {uniqueDepartments.map(dept => (
                  <option key={dept} value={dept}>{dept}</option>
                ))}
              </select>
            </div>

            {/* Type Filter */}
            <div>
              <select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все типы</option>
                {uniqueTypes.map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
            </div>

            {/* Date Range */}
            <div className="flex gap-2">
              <input
                type="date"
                value={dateRange.start}
                onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))}
                className="flex-1 border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <input
                type="date"
                value={dateRange.end}
                onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))}
                className="flex-1 border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>
      </div>

      {/* History Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-800">
            История заявок ({filteredRecords.length})
          </h2>
        </div>

        {filteredRecords.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <History className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <p>Нет записей для отображения</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    ID заявки
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('employee_name')}
                  >
                    <div className="flex items-center gap-1">
                      Сотрудник
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Тип
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('submitted_at')}
                  >
                    <div className="flex items-center gap-1">
                      Подана
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('processed_at')}
                  >
                    <div className="flex items-center gap-1">
                      Обработана
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Статус
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Утверждающий
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('processing_time_hours')}
                  >
                    <div className="flex items-center gap-1">
                      Время обработки
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Действия
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredRecords.map((record) => (
                  <tr key={record.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {record.request_id}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <User className="h-4 w-4 text-gray-400 mr-2" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">{record.employee_name}</div>
                          <div className="text-sm text-gray-500">{record.department}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {record.request_type}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(record.submitted_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(record.processed_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(record.status)}`}>
                        {getStatusIcon(record.status)}
                        {record.status === 'approved' ? 'Одобрено' :
                         record.status === 'rejected' ? 'Отклонено' : 'Отменено'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <Users className="h-4 w-4 text-gray-400 mr-2" />
                        <span className="text-sm text-gray-900">{record.approver}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {record.processing_time_hours}ч
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => showDetails(record)}
                        className="text-blue-600 hover:text-blue-900 flex items-center gap-1"
                      >
                        <Eye className="h-4 w-4" />
                        Детали
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Details Modal */}
      {showDetailsModal && selectedRecord && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl mx-4 max-h-96 overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Детали заявки {selectedRecord.request_id}</h3>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircle className="h-5 w-5" />
              </button>
            </div>
            
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="font-medium text-gray-700">Сотрудник:</span>
                <div className="text-gray-900">{selectedRecord.employee_name}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Отдел:</span>
                <div className="text-gray-900">{selectedRecord.department}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Тип заявки:</span>
                <div className="text-gray-900">{selectedRecord.request_type}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Статус:</span>
                <div className="text-gray-900">{selectedRecord.status}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Период:</span>
                <div className="text-gray-900">
                  {formatDate(selectedRecord.start_date)} - {formatDate(selectedRecord.end_date)}
                </div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Длительность:</span>
                <div className="text-gray-900">{selectedRecord.duration_days} дней</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Подана:</span>
                <div className="text-gray-900">{formatDateTime(selectedRecord.submitted_at)}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Обработана:</span>
                <div className="text-gray-900">{formatDateTime(selectedRecord.processed_at)}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Утверждающий:</span>
                <div className="text-gray-900">{selectedRecord.approver}</div>
              </div>
              <div>
                <span className="font-medium text-gray-700">Время обработки:</span>
                <div className="text-gray-900">{selectedRecord.processing_time_hours} часов</div>
              </div>
              {selectedRecord.escalation_level > 0 && (
                <div>
                  <span className="font-medium text-gray-700">Уровень эскалации:</span>
                  <div className="text-gray-900">{selectedRecord.escalation_level}</div>
                </div>
              )}
              <div className="col-span-2">
                <span className="font-medium text-gray-700">Комментарии:</span>
                <div className="text-gray-900 mt-1 p-2 bg-gray-50 rounded">
                  {selectedRecord.comments}
                </div>
              </div>
            </div>
            
            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setShowDetailsModal(false)}
                className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
              >
                Закрыть
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WorkflowHistory;