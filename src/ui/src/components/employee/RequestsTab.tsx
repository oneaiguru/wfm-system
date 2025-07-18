import React, { useState, useEffect } from 'react';
import { FileText, Clock, CheckCircle, XCircle, AlertCircle, Users, Calendar } from 'lucide-react';

interface RequestsTabProps {
  employeeId: string;
}

interface Request {
  id: string;
  type: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
  title: string;
  status: 'created' | 'pending' | 'approved' | 'rejected';
  startDate: Date;
  endDate?: Date;
  reason: string;
  description?: string;
  submittedAt: Date;
  approver?: {
    name: string;
    comments?: string;
  };
  exchangeEmployee?: {
    id: string;
    name: string;
  };
  exchangeDate?: Date;
  exchangeTime?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations per BDD spec
const translations = {
  title: 'Заявки',
  tabs: {
    all: 'Все',
    available: 'Доступные', // For shift exchanges
    pending: 'На рассмотрении',
    approved: 'Одобренные',
    rejected: 'Отклоненные'
  },
  requestTypes: {
    time_off: 'Отгул',
    sick_leave: 'Больничный',
    vacation: 'Внеочередной отпуск',
    shift_exchange: 'Обмен сменами'
  },
  statuses: {
    created: 'Создана',
    pending: 'На рассмотрении',
    approved: 'Одобрена',
    rejected: 'Отклонена'
  },
  actions: {
    accept: 'Принять',
    decline: 'Отклонить',
    view: 'Просмотр',
    cancel: 'Отменить'
  },
  fields: {
    type: 'Тип',
    period: 'Период',
    reason: 'Причина',
    submitted: 'Подано',
    approver: 'Руководитель',
    status: 'Статус',
    exchangeWith: 'Обмен с',
    exchangeDate: 'Дата обмена'
  }
};

const RequestsTab: React.FC<RequestsTabProps> = ({ employeeId }) => {
  const [requests, setRequests] = useState<Request[]>([]);
  const [availableExchanges, setAvailableExchanges] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'all' | 'available' | 'pending' | 'approved' | 'rejected'>('all');
  const [processingRequest, setProcessingRequest] = useState<string | null>(null);

  useEffect(() => {
    loadRequests();
  }, [employeeId]);

  const loadRequests = async () => {
    setLoading(true);
    try {
      // Load employee's own requests
      const myRequestsResponse = await fetch(
        `${API_BASE_URL}/requests/my-requests?employee_id=${employeeId}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );
      
      if (myRequestsResponse.ok) {
        const myRequestsData = await myRequestsResponse.json();
        const mappedRequests = (myRequestsData.requests || []).map((request: any) => ({
          id: request.id,
          type: request.type,
          title: getRequestTitle(request.type, request.reason),
          status: request.status,
          startDate: new Date(request.start_date),
          endDate: request.end_date ? new Date(request.end_date) : undefined,
          reason: request.reason,
          description: request.description,
          submittedAt: new Date(request.submitted_at),
          approver: request.approver ? {
            name: request.approver.name,
            comments: request.approver.comments
          } : undefined,
          exchangeEmployee: request.exchange_employee ? {
            id: request.exchange_employee.id,
            name: request.exchange_employee.name
          } : undefined,
          exchangeDate: request.exchange_date ? new Date(request.exchange_date) : undefined,
          exchangeTime: request.exchange_time
        }));
        setRequests(mappedRequests);
      }

      // Load available shift exchanges from other employees
      const availableExchangesResponse = await fetch(
        `${API_BASE_URL}/requests/available-exchanges?employee_id=${employeeId}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );
      
      if (availableExchangesResponse.ok) {
        const availableExchangesData = await availableExchangesResponse.json();
        const mappedExchanges = (availableExchangesData.exchanges || []).map((exchange: any) => ({
          id: exchange.id,
          type: 'shift_exchange',
          title: `Обмен смены - ${exchange.requester_name}`,
          status: 'pending',
          startDate: new Date(exchange.original_date),
          reason: exchange.reason,
          submittedAt: new Date(exchange.submitted_at),
          exchangeEmployee: {
            id: exchange.requester_id,
            name: exchange.requester_name
          },
          exchangeDate: new Date(exchange.exchange_date),
          exchangeTime: exchange.exchange_time
        }));
        setAvailableExchanges(mappedExchanges);
      }

    } catch (error) {
      console.error('Error loading requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const getRequestTitle = (type: string, reason: string) => {
    const typeLabel = translations.requestTypes[type as keyof typeof translations.requestTypes];
    return reason ? `${typeLabel} - ${reason.substring(0, 30)}...` : typeLabel;
  };

  const getFilteredRequests = () => {
    switch (activeTab) {
      case 'available':
        return availableExchanges;
      case 'pending':
        return requests.filter(r => r.status === 'pending');
      case 'approved':
        return requests.filter(r => r.status === 'approved');
      case 'rejected':
        return requests.filter(r => r.status === 'rejected');
      default:
        return requests;
    }
  };

  const handleAcceptShiftExchange = async (requestId: string) => {
    setProcessingRequest(requestId);
    try {
      const response = await fetch(
        `${API_BASE_URL}/requests/accept-exchange/${requestId}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          },
          body: JSON.stringify({ employee_id: employeeId })
        }
      );

      if (response.ok) {
        // Remove from available exchanges and reload requests
        await loadRequests();
      } else {
        throw new Error('Failed to accept shift exchange');
      }
    } catch (error) {
      console.error('Error accepting shift exchange:', error);
    } finally {
      setProcessingRequest(null);
    }
  };

  const handleDeclineShiftExchange = async (requestId: string) => {
    setProcessingRequest(requestId);
    try {
      const response = await fetch(
        `${API_BASE_URL}/requests/decline-exchange/${requestId}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          },
          body: JSON.stringify({ employee_id: employeeId })
        }
      );

      if (response.ok) {
        // Remove from available exchanges
        setAvailableExchanges(prev => prev.filter(r => r.id !== requestId));
      } else {
        throw new Error('Failed to decline shift exchange');
      }
    } catch (error) {
      console.error('Error declining shift exchange:', error);
    } finally {
      setProcessingRequest(null);
    }
  };

  const handleCancelRequest = async (requestId: string) => {
    if (!confirm('Вы уверены, что хотите отменить эту заявку?')) return;

    setProcessingRequest(requestId);
    try {
      const response = await fetch(
        `${API_BASE_URL}/requests/${requestId}/cancel`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        // Remove from requests list
        setRequests(prev => prev.filter(r => r.id !== requestId));
      } else {
        throw new Error('Failed to cancel request');
      }
    } catch (error) {
      console.error('Error canceling request:', error);
    } finally {
      setProcessingRequest(null);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'created':
      case 'pending':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'approved':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'rejected':
        return <XCircle className="h-4 w-4 text-red-500" />;
      default:
        return <AlertCircle className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'created':
        return 'bg-gray-100 text-gray-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'approved':
        return 'bg-green-100 text-green-800';
      case 'rejected':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'time_off':
        return <Clock className="h-4 w-4" />;
      case 'sick_leave':
        return <AlertCircle className="h-4 w-4" />;
      case 'vacation':
        return <Calendar className="h-4 w-4" />;
      case 'shift_exchange':
        return <Users className="h-4 w-4" />;
      default:
        return <FileText className="h-4 w-4" />;
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const formatDateRange = (start: Date, end?: Date) => {
    if (!end) return formatDate(start);
    return `${formatDate(start)} - ${formatDate(end)}`;
  };

  const getTabCount = (tab: string) => {
    switch (tab) {
      case 'all':
        return requests.length;
      case 'available':
        return availableExchanges.length;
      case 'pending':
        return requests.filter(r => r.status === 'pending').length;
      case 'approved':
        return requests.filter(r => r.status === 'approved').length;
      case 'rejected':
        return requests.filter(r => r.status === 'rejected').length;
      default:
        return 0;
    }
  };

  const filteredRequests = getFilteredRequests();

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-20 bg-gray-300 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="bg-white rounded-lg shadow-sm" data-testid="requests-tab">
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-6">
            <FileText className="h-6 w-6 text-blue-600" />
            <h2 className="text-2xl font-semibold text-gray-900">{translations.title}</h2>
          </div>

          {/* Tabs */}
          <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
            {Object.entries(translations.tabs).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setActiveTab(key as any)}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors flex-1 ${
                  activeTab === key
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {label}
                <span className="ml-2 px-2 py-0.5 bg-gray-200 text-gray-600 text-xs rounded-full">
                  {getTabCount(key)}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Request List */}
        <div className="p-6">
          {filteredRequests.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-4xl mb-4">📝</div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {activeTab === 'available' ? 'Нет доступных обменов' : 'Нет заявок'}
              </h3>
              <p className="text-gray-500">
                {activeTab === 'available' 
                  ? 'В настоящее время нет доступных обменов смен'
                  : 'Здесь будут отображаться ваши заявки'
                }
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredRequests.map((request) => (
                <div
                  key={request.id}
                  className="border rounded-lg p-4 hover:shadow-sm transition-shadow bg-white"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className="text-blue-600">
                          {getTypeIcon(request.type)}
                        </div>
                        <h3 className="font-medium text-gray-900">{request.title}</h3>
                        <div className="flex items-center gap-2">
                          {getStatusIcon(request.status)}
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(request.status)}`}>
                            {translations.statuses[request.status as keyof typeof translations.statuses]}
                          </span>
                        </div>
                      </div>
                      
                      <div className="text-sm text-gray-600 mb-3 grid grid-cols-1 md:grid-cols-2 gap-2">
                        <div>
                          <strong>{translations.fields.type}:</strong> {translations.requestTypes[request.type as keyof typeof translations.requestTypes]}
                        </div>
                        <div>
                          <strong>{translations.fields.period}:</strong> {formatDateRange(request.startDate, request.endDate)}
                        </div>
                        <div>
                          <strong>{translations.fields.submitted}:</strong> {formatDate(request.submittedAt)}
                        </div>
                        {request.approver && (
                          <div>
                            <strong>{translations.fields.approver}:</strong> {request.approver.name}
                          </div>
                        )}
                        {request.exchangeEmployee && (
                          <div>
                            <strong>{translations.fields.exchangeWith}:</strong> {request.exchangeEmployee.name}
                          </div>
                        )}
                        {request.exchangeDate && (
                          <div>
                            <strong>{translations.fields.exchangeDate}:</strong> {formatDate(request.exchangeDate)} {request.exchangeTime}
                          </div>
                        )}
                      </div>
                      
                      <div className="text-sm text-gray-700 mb-3">
                        <strong>{translations.fields.reason}:</strong> {request.reason}
                      </div>

                      {request.description && (
                        <div className="text-sm text-gray-700 mb-3">
                          <strong>Описание:</strong> {request.description}
                        </div>
                      )}

                      {request.approver?.comments && (
                        <div className="mt-2 p-2 bg-gray-100 rounded text-sm">
                          <strong>Комментарии:</strong> {request.approver.comments}
                        </div>
                      )}
                    </div>
                    
                    {/* Action Buttons */}
                    <div className="flex items-center gap-2 ml-4">
                      {activeTab === 'available' && (
                        <>
                          <button
                            onClick={() => handleAcceptShiftExchange(request.id)}
                            disabled={processingRequest === request.id}
                            className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 transition-colors"
                          >
                            {processingRequest === request.id ? 'Обработка...' : translations.actions.accept}
                          </button>
                          <button
                            onClick={() => handleDeclineShiftExchange(request.id)}
                            disabled={processingRequest === request.id}
                            className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 transition-colors"
                          >
                            {translations.actions.decline}
                          </button>
                        </>
                      )}
                      
                      {activeTab !== 'available' && (request.status === 'created' || request.status === 'pending') && (
                        <button
                          onClick={() => handleCancelRequest(request.id)}
                          disabled={processingRequest === request.id}
                          className="px-3 py-1 text-sm border border-red-300 text-red-600 rounded hover:bg-red-50 disabled:opacity-50 transition-colors"
                        >
                          {processingRequest === request.id ? 'Отмена...' : translations.actions.cancel}
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default RequestsTab;