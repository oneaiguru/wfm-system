import React, { useState, useEffect } from 'react';
import { 
  Calendar, 
  Clock, 
  User, 
  CheckCircle, 
  XCircle, 
  AlertTriangle, 
  TrendingUp, 
  BarChart3, 
  RefreshCw,
  Filter
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

interface WorkflowStats {
  totalPending: number;
  avgProcessingTime: number;
  approvalRate: number;
  overdueCount: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const WorkflowDashboard: React.FC = () => {
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([]);
  const [stats, setStats] = useState<WorkflowStats>({
    totalPending: 0,
    avgProcessingTime: 0,
    approvalRate: 0,
    overdueCount: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [selectedFilter, setSelectedFilter] = useState<string>('all');
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    fetchDashboardData();
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchDashboardData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/requests/pending`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data: PendingRequest[] = await response.json();
      setPendingRequests(data);
      calculateStats(data);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных');
      console.error('[WorkflowDashboard] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const calculateStats = (requests: PendingRequest[]) => {
    const now = new Date();
    const totalPending = requests.length;
    
    // Calculate average processing time (days since submission)
    const avgProcessingTime = requests.length > 0 
      ? requests.reduce((sum, req) => {
          const submitted = new Date(req.submitted_at);
          const daysDiff = Math.floor((now.getTime() - submitted.getTime()) / (1000 * 60 * 60 * 24));
          return sum + daysDiff;
        }, 0) / requests.length
      : 0;

    // Mock approval rate (in real implementation, this would come from historical data)
    const approvalRate = 85;

    // Count overdue requests (more than 5 days old)
    const overdueCount = requests.filter(req => {
      const submitted = new Date(req.submitted_at);
      const daysDiff = Math.floor((now.getTime() - submitted.getTime()) / (1000 * 60 * 60 * 24));
      return daysDiff > 5;
    }).length;

    setStats({
      totalPending,
      avgProcessingTime,
      approvalRate,
      overdueCount
    });
  };

  const getFilteredRequests = () => {
    if (selectedFilter === 'all') return pendingRequests;
    if (selectedFilter === 'overdue') {
      const now = new Date();
      return pendingRequests.filter(req => {
        const submitted = new Date(req.submitted_at);
        const daysDiff = Math.floor((now.getTime() - submitted.getTime()) / (1000 * 60 * 60 * 24));
        return daysDiff > 5;
      });
    }
    return pendingRequests.filter(req => req.request_type === selectedFilter);
  };

  const getUrgencyLevel = (submittedAt: string) => {
    const now = new Date();
    const submitted = new Date(submittedAt);
    const daysDiff = Math.floor((now.getTime() - submitted.getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysDiff > 7) return { level: 'critical', color: 'bg-red-100 text-red-800', icon: AlertTriangle };
    if (daysDiff > 5) return { level: 'high', color: 'bg-orange-100 text-orange-800', icon: Clock };
    if (daysDiff > 3) return { level: 'medium', color: 'bg-yellow-100 text-yellow-800', icon: Clock };
    return { level: 'normal', color: 'bg-green-100 text-green-800', icon: CheckCircle };
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  };

  const filteredRequests = getFilteredRequests();

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
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Панель управления workflow</h1>
            <p className="text-gray-600">Мониторинг процессов согласования</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-sm text-gray-500">
              Обновлено: {lastUpdated.toLocaleTimeString('ru-RU')}
            </div>
            <button
              onClick={fetchDashboardData}
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
          <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ожидают рассмотрения</p>
              <p className="text-2xl font-bold text-blue-600">{stats.totalPending}</p>
            </div>
            <Clock className="h-8 w-8 text-blue-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Среднее время обработки</p>
              <p className="text-2xl font-bold text-orange-600">{stats.avgProcessingTime.toFixed(1)} дн.</p>
            </div>
            <BarChart3 className="h-8 w-8 text-orange-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Процент одобрения</p>
              <p className="text-2xl font-bold text-green-600">{stats.approvalRate}%</p>
            </div>
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <div className="mt-2">
            <TrendingUp className="h-4 w-4 text-green-500 inline mr-1" />
            <span className="text-xs text-green-600">+2% за неделю</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Просроченные</p>
              <p className="text-2xl font-bold text-red-600">{stats.overdueCount}</p>
            </div>
            <AlertTriangle className="h-8 w-8 text-red-600" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center gap-4">
            <Filter className="h-5 w-5 text-gray-500" />
            <div className="flex gap-2">
              {[
                { value: 'all', label: 'Все заявки' },
                { value: 'vacation', label: 'Отпуск' },
                { value: 'sick_leave', label: 'Больничный' },
                { value: 'overdue', label: 'Просроченные' }
              ].map((filter) => (
                <button
                  key={filter.value}
                  onClick={() => setSelectedFilter(filter.value)}
                  className={`px-4 py-2 rounded-lg transition-colors ${
                    selectedFilter === filter.value
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Requests List */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-800">
            Ожидающие рассмотрения ({filteredRequests.length})
          </h2>
        </div>

        {filteredRequests.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <Clock className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <p>Нет заявок для отображения</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {filteredRequests.slice(0, 10).map((request) => {
              const urgency = getUrgencyLevel(request.submitted_at);
              const UrgencyIcon = urgency.icon;
              
              return (
                <div key={request.request_id} className="p-6 hover:bg-gray-50 transition-colors">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center mb-2">
                        <User className="h-5 w-5 text-gray-400 mr-2" />
                        <h3 className="font-semibold text-gray-900">{request.employee_name}</h3>
                        <span className={`ml-3 px-2 py-1 text-xs rounded-full ${urgency.color} flex items-center gap-1`}>
                          <UrgencyIcon className="h-3 w-3" />
                          {urgency.level === 'critical' ? 'Критично' : 
                           urgency.level === 'high' ? 'Высокая' :
                           urgency.level === 'medium' ? 'Средняя' : 'Норма'}
                        </span>
                      </div>
                      
                      <div className="grid grid-cols-2 gap-4 text-sm text-gray-600">
                        <div className="flex items-center">
                          <Calendar className="h-4 w-4 mr-2" />
                          <span>
                            {formatDate(request.start_date)} - {formatDate(request.end_date)}
                          </span>
                        </div>
                        <div>
                          <span className="font-medium">{request.duration_days}</span> дней
                        </div>
                        <div>
                          Тип: <span className="font-medium">{request.request_type}</span>
                        </div>
                        <div>
                          Подана: {new Date(request.submitted_at).toLocaleDateString('ru-RU')}
                        </div>
                      </div>
                    </div>

                    <div className="flex gap-2 ml-4">
                      <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
                        Рассмотреть
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {filteredRequests.length > 10 && (
          <div className="px-6 py-4 border-t border-gray-200 text-center">
            <button className="text-blue-600 hover:text-blue-800 font-medium">
              Показать еще ({filteredRequests.length - 10} заявок)
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default WorkflowDashboard;