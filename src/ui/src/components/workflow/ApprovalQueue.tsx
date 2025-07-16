import React, { useState, useEffect } from 'react';
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  Calendar, 
  User, 
  AlertTriangle, 
  Search,
  Filter,
  ArrowUpDown,
  RefreshCw
} from 'lucide-react';

interface PendingRequest {
  request_id: string;
  employee_id: number;
  employee_name: string;
  request_type: string;
  start_date: string;
  end_date: string;
  duration_days: number;
  submitted_at: string;
  status: string;
}

type SortField = 'submitted_at' | 'employee_name' | 'duration_days' | 'start_date';
type SortDirection = 'asc' | 'desc';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const ApprovalQueue: React.FC = () => {
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([]);
  const [filteredRequests, setFilteredRequests] = useState<PendingRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [processingId, setProcessingId] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [sortField, setSortField] = useState<SortField>('submitted_at');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  const [selectedRequests, setSelectedRequests] = useState<Set<string>>(new Set());

  useEffect(() => {
    fetchPendingRequests();
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchPendingRequests, 30000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    let filtered = [...pendingRequests];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(req => 
        req.employee_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        req.request_type.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply type filter
    if (selectedType !== 'all') {
      filtered = filtered.filter(req => req.request_type === selectedType);
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aVal: string | number, bVal: string | number;
      
      switch (sortField) {
        case 'employee_name':
          aVal = a.employee_name;
          bVal = b.employee_name;
          break;
        case 'duration_days':
          aVal = a.duration_days;
          bVal = b.duration_days;
          break;
        case 'start_date':
          aVal = a.start_date;
          bVal = b.start_date;
          break;
        default:
          aVal = a.submitted_at;
          bVal = b.submitted_at;
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

    setFilteredRequests(filtered);
  }, [pendingRequests, searchTerm, selectedType, sortField, sortDirection]);

  const fetchPendingRequests = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/requests/pending`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data: PendingRequest[] = await response.json();
      setPendingRequests(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки очереди заявок');
      console.error('[ApprovalQueue] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (requestId: string) => {
    setProcessingId(requestId);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/requests/approve/${requestId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `HTTP ${response.status}`);
      }
      
      const result = await response.json();
      console.log('[ApprovalQueue] Approved:', result);
      
      // Remove approved request from list
      setPendingRequests(prev => prev.filter(req => req.request_id !== requestId));
      setSelectedRequests(prev => {
        const newSet = new Set(prev);
        newSet.delete(requestId);
        return newSet;
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка при одобрении заявки');
      console.error('[ApprovalQueue] Approval error:', err);
    } finally {
      setProcessingId('');
    }
  };

  const handleBulkApproval = async () => {
    if (selectedRequests.size === 0) return;

    setLoading(true);
    const errors: string[] = [];

    for (const requestId of Array.from(selectedRequests)) {
      try {
        await handleApprove(requestId);
      } catch (err) {
        errors.push(`Заявка ${requestId}: ${err instanceof Error ? err.message : 'Ошибка'}`);
      }
    }

    if (errors.length > 0) {
      setError(`Ошибки при массовом одобрении: ${errors.join(', ')}`);
    }

    setSelectedRequests(new Set());
    setLoading(false);
  };

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const toggleRequestSelection = (requestId: string) => {
    setSelectedRequests(prev => {
      const newSet = new Set(prev);
      if (newSet.has(requestId)) {
        newSet.delete(requestId);
      } else {
        newSet.add(requestId);
      }
      return newSet;
    });
  };

  const selectAllVisible = () => {
    const allIds = new Set(filteredRequests.map(req => req.request_id));
    setSelectedRequests(allIds);
  };

  const clearSelection = () => {
    setSelectedRequests(new Set());
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

  const getUrgencyBadge = (submittedAt: string) => {
    const now = new Date();
    const submitted = new Date(submittedAt);
    const daysDiff = Math.floor((now.getTime() - submitted.getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysDiff > 7) return { text: 'Критично', class: 'bg-red-100 text-red-800' };
    if (daysDiff > 5) return { text: 'Срочно', class: 'bg-orange-100 text-orange-800' };
    if (daysDiff > 3) return { text: 'Средне', class: 'bg-yellow-100 text-yellow-800' };
    return { text: 'Норма', class: 'bg-green-100 text-green-800' };
  };

  const uniqueTypes = Array.from(new Set(pendingRequests.map(req => req.request_type)));

  if (loading && pendingRequests.length === 0) {
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
            <h1 className="text-2xl font-bold text-gray-900">Очередь согласования</h1>
            <p className="text-gray-600">Управление заявками на рассмотрение</p>
          </div>
          <button
            onClick={fetchPendingRequests}
            className="p-2 bg-white rounded-lg border hover:bg-gray-50 transition-colors"
          >
            <RefreshCw className={`h-5 w-5 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      {/* Filters and Search */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-6">
          <div className="flex flex-wrap gap-4 items-center">
            {/* Search */}
            <div className="flex-1 min-w-64">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Поиск по сотруднику или типу заявки..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            {/* Type Filter */}
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-500" />
              <select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value)}
                className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все типы</option>
                {uniqueTypes.map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
            </div>

            {/* Bulk Actions */}
            {selectedRequests.size > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600">
                  Выбрано: {selectedRequests.size}
                </span>
                <button
                  onClick={handleBulkApproval}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  Одобрить выбранные
                </button>
                <button
                  onClick={clearSelection}
                  className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                >
                  Очистить
                </button>
              </div>
            )}
          </div>

          {filteredRequests.length > 0 && (
            <div className="mt-4 flex items-center gap-2">
              <button
                onClick={selectAllVisible}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                Выбрать все ({filteredRequests.length})
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Requests Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-800">
            Заявки в очереди ({filteredRequests.length})
          </h2>
        </div>

        {filteredRequests.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <Clock className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <p>Нет заявок в очереди</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={selectedRequests.size === filteredRequests.length && filteredRequests.length > 0}
                      onChange={selectedRequests.size === filteredRequests.length ? clearSelection : selectAllVisible}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
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
                    Тип заявки
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('start_date')}
                  >
                    <div className="flex items-center gap-1">
                      Период
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('duration_days')}
                  >
                    <div className="flex items-center gap-1">
                      Дни
                      <ArrowUpDown className="h-3 w-3" />
                    </div>
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Приоритет
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Действия
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredRequests.map((request) => {
                  const urgency = getUrgencyBadge(request.submitted_at);
                  return (
                    <tr key={request.request_id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <input
                          type="checkbox"
                          checked={selectedRequests.has(request.request_id)}
                          onChange={() => toggleRequestSelection(request.request_id)}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <User className="h-4 w-4 text-gray-400 mr-2" />
                          <div className="text-sm font-medium text-gray-900">
                            {request.employee_name}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="text-sm text-gray-900">{request.request_type}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {formatDate(request.start_date)} - {formatDate(request.end_date)}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="text-sm font-medium text-gray-900">
                          {request.duration_days}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="text-sm text-gray-500">
                          {formatDateTime(request.submitted_at)}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${urgency.class}`}>
                          {urgency.text}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end gap-2">
                          <button
                            onClick={() => handleApprove(request.request_id)}
                            disabled={processingId === request.request_id}
                            className="inline-flex items-center px-3 py-1 bg-green-600 text-white text-xs rounded hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
                          >
                            {processingId === request.request_id ? (
                              <>
                                <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-white mr-1"></div>
                                Обработка...
                              </>
                            ) : (
                              <>
                                <CheckCircle className="h-3 w-3 mr-1" />
                                Одобрить
                              </>
                            )}
                          </button>
                          <button className="inline-flex items-center px-3 py-1 bg-red-600 text-white text-xs rounded hover:bg-red-700 transition-colors">
                            <XCircle className="h-3 w-3 mr-1" />
                            Отклонить
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default ApprovalQueue;