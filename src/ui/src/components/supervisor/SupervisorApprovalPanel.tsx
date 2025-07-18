import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, FileText, Users, AlertTriangle } from 'lucide-react';

interface SupervisorApprovalPanelProps {
  supervisorId: string;
}

interface PendingRequest {
  id: string;
  type: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
  employee: {
    id: string;
    name: string;
    department: string;
  };
  startDate: Date;
  endDate?: Date;
  reason: string;
  description?: string;
  submittedAt: Date;
  priority: 'low' | 'normal' | 'high';
  // For shift exchanges
  exchangeWith?: {
    id: string;
    name: string;
  };
  exchangeDate?: Date;
  exchangeTime?: string;
  // 1C ZUP integration info
  zupDocumentType?: string;
  timeTypeCreated?: string;
}

interface ApprovalDecision {
  requestId: string;
  decision: 'approve' | 'reject';
  comments?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations and 1C ZUP mappings per BDD spec
const translations = {
  title: 'Заявки на рассмотрение',
  tabs: {
    available: 'Доступные',
    pending: 'В обработке',
    completed: 'Завершенные'
  },
  requestTypes: {
    time_off: 'Отгул',
    sick_leave: 'Больничный',
    vacation: 'Внеочередной отпуск',
    shift_exchange: 'Обмен сменами'
  },
  actions: {
    approve: 'Одобрить',
    reject: 'Отклонить',
    review: 'Рассмотреть',
    viewDetails: 'Подробности'
  },
  fields: {
    employee: 'Сотрудник',
    department: 'Отдел',
    type: 'Тип заявки',
    period: 'Период',
    reason: 'Причина',
    submitted: 'Подано',
    priority: 'Приоритет',
    exchangeWith: 'Обмен с',
    comments: 'Комментарии'
  },
  zupIntegration: {
    title: 'Интеграция 1C ZUP',
    documentType: 'Тип документа',
    timeType: 'Тип времени',
    status: 'Статус интеграции'
  },
  priorities: {
    low: 'Низкий',
    normal: 'Обычный',
    high: 'Высокий'
  }
};

// 1C ZUP integration mappings per BDD spec
const zupMappings = {
  time_off: {
    documentType: 'Time off deviation document',
    timeType: 'NV (НВ) - Absence'
  },
  sick_leave: {
    documentType: 'Sick leave document',
    timeType: 'Sick leave time type'
  },
  vacation: {
    documentType: 'Unscheduled vacation document',
    timeType: 'OT (ОТ) - Vacation'
  }
};

const SupervisorApprovalPanel: React.FC<SupervisorApprovalPanelProps> = ({ supervisorId }) => {
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'available' | 'pending' | 'completed'>('available');
  const [processingRequest, setProcessingRequest] = useState<string | null>(null);
  const [selectedRequest, setSelectedRequest] = useState<PendingRequest | null>(null);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const [approvalComments, setApprovalComments] = useState('');

  useEffect(() => {
    loadPendingRequests();
  }, [supervisorId]);

  const loadPendingRequests = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `${API_BASE_URL}/requests/pending-approval?supervisor_id=${supervisorId}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        const data = await response.json();
        const mappedRequests = (data.requests || []).map((request: any) => ({
          id: request.id,
          type: request.type,
          employee: {
            id: request.employee.id,
            name: request.employee.name,
            department: request.employee.department
          },
          startDate: new Date(request.start_date),
          endDate: request.end_date ? new Date(request.end_date) : undefined,
          reason: request.reason,
          description: request.description,
          submittedAt: new Date(request.submitted_at),
          priority: request.priority || 'normal',
          exchangeWith: request.exchange_with ? {
            id: request.exchange_with.id,
            name: request.exchange_with.name
          } : undefined,
          exchangeDate: request.exchange_date ? new Date(request.exchange_date) : undefined,
          exchangeTime: request.exchange_time,
          // Add 1C ZUP integration info
          zupDocumentType: zupMappings[request.type as keyof typeof zupMappings]?.documentType,
          timeTypeCreated: zupMappings[request.type as keyof typeof zupMappings]?.timeType
        }));
        setPendingRequests(mappedRequests);
      }
    } catch (error) {
      console.error('Error loading pending requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprovalDecision = async (requestId: string, decision: 'approve' | 'reject') => {
    setProcessingRequest(requestId);
    try {
      const response = await fetch(
        `${API_BASE_URL}/requests/${requestId}/${decision}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          },
          body: JSON.stringify({
            supervisor_id: supervisorId,
            comments: approvalComments
          })
        }
      );

      if (response.ok) {
        const result = await response.json();
        
        // Log 1C ZUP integration results per BDD spec
        if (result.zup_integration) {
          console.log('1C ZUP Integration Results:', {
            step: result.zup_integration.step,
            api_call: result.zup_integration.api_call,
            result: result.zup_integration.result,
            document_created: result.zup_integration.document_created,
            integration_confirmed: result.zup_integration.integration_confirmed
          });
        }

        // Remove from pending requests
        setPendingRequests(prev => prev.filter(r => r.id !== requestId));
        setShowApprovalModal(false);
        setApprovalComments('');
        setSelectedRequest(null);
      } else {
        throw new Error(`Failed to ${decision} request`);
      }
    } catch (error) {
      console.error(`Error ${decision}ing request:`, error);
    } finally {
      setProcessingRequest(null);
    }
  };

  const openApprovalModal = (request: PendingRequest) => {
    setSelectedRequest(request);
    setShowApprovalModal(true);
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800';
      case 'normal':
        return 'bg-blue-100 text-blue-800';
      case 'low':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'time_off':
        return <Clock className="h-4 w-4 text-orange-600" />;
      case 'sick_leave':
        return <AlertTriangle className="h-4 w-4 text-red-600" />;
      case 'vacation':
        return <FileText className="h-4 w-4 text-purple-600" />;
      case 'shift_exchange':
        return <Users className="h-4 w-4 text-blue-600" />;
      default:
        return <FileText className="h-4 w-4 text-gray-600" />;
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

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-24 bg-gray-300 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="bg-white rounded-lg shadow-sm">
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-6">
            <CheckCircle className="h-6 w-6 text-blue-600" />
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
                  {key === 'available' ? pendingRequests.length : 0}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Request List */}
        <div className="p-6">
          {pendingRequests.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-4xl mb-4">✅</div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">Нет заявок на рассмотрение</h3>
              <p className="text-gray-500">Все заявки обработаны</p>
            </div>
          ) : (
            <div className="space-y-4">
              {pendingRequests.map((request) => (
                <div
                  key={request.id}
                  className="border rounded-lg p-4 hover:shadow-sm transition-shadow bg-white"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        {getTypeIcon(request.type)}
                        <h3 className="font-medium text-gray-900">
                          {translations.requestTypes[request.type as keyof typeof translations.requestTypes]}
                        </h3>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPriorityColor(request.priority)}`}>
                          {translations.priorities[request.priority as keyof typeof translations.priorities]}
                        </span>
                      </div>
                      
                      <div className="text-sm text-gray-600 mb-3 grid grid-cols-1 md:grid-cols-2 gap-2">
                        <div>
                          <strong>{translations.fields.employee}:</strong> {request.employee.name}
                        </div>
                        <div>
                          <strong>{translations.fields.department}:</strong> {request.employee.department}
                        </div>
                        <div>
                          <strong>{translations.fields.period}:</strong> {formatDateRange(request.startDate, request.endDate)}
                        </div>
                        <div>
                          <strong>{translations.fields.submitted}:</strong> {formatDate(request.submittedAt)}
                        </div>
                        {request.exchangeWith && (
                          <div>
                            <strong>{translations.fields.exchangeWith}:</strong> {request.exchangeWith.name}
                          </div>
                        )}
                        {request.exchangeDate && (
                          <div>
                            <strong>Дата обмена:</strong> {formatDate(request.exchangeDate)} {request.exchangeTime}
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

                      {/* 1C ZUP Integration Info */}
                      {request.zupDocumentType && (
                        <div className="mt-3 p-3 bg-blue-50 rounded-lg">
                          <h4 className="text-sm font-medium text-blue-900 mb-2">
                            {translations.zupIntegration.title}
                          </h4>
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
                            <div>
                              <strong>{translations.zupIntegration.documentType}:</strong> {request.zupDocumentType}
                            </div>
                            <div>
                              <strong>{translations.zupIntegration.timeType}:</strong> {request.timeTypeCreated}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                    
                    {/* Action Buttons */}
                    <div className="flex items-center gap-2 ml-4">
                      <button
                        onClick={() => openApprovalModal(request)}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        {translations.actions.review}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Approval Modal */}
      {showApprovalModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
            <div className="p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">
                Рассмотрение заявки
              </h3>
              
              <div className="space-y-4 mb-6">
                <div>
                  <strong>Сотрудник:</strong> {selectedRequest.employee.name}
                </div>
                <div>
                  <strong>Тип заявки:</strong> {translations.requestTypes[selectedRequest.type as keyof typeof translations.requestTypes]}
                </div>
                <div>
                  <strong>Период:</strong> {formatDateRange(selectedRequest.startDate, selectedRequest.endDate)}
                </div>
                <div>
                  <strong>Причина:</strong> {selectedRequest.reason}
                </div>
              </div>

              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {translations.fields.comments}
                </label>
                <textarea
                  value={approvalComments}
                  onChange={(e) => setApprovalComments(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Введите комментарии..."
                />
              </div>

              <div className="flex justify-end gap-3">
                <button
                  onClick={() => setShowApprovalModal(false)}
                  className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Отмена
                </button>
                <button
                  onClick={() => handleApprovalDecision(selectedRequest.id, 'reject')}
                  disabled={processingRequest === selectedRequest.id}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors flex items-center gap-2"
                >
                  <XCircle className="h-4 w-4" />
                  {processingRequest === selectedRequest.id ? 'Обработка...' : translations.actions.reject}
                </button>
                <button
                  onClick={() => handleApprovalDecision(selectedRequest.id, 'approve')}
                  disabled={processingRequest === selectedRequest.id}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors flex items-center gap-2"
                >
                  <CheckCircle className="h-4 w-4" />
                  {processingRequest === selectedRequest.id ? 'Обработка...' : translations.actions.approve}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SupervisorApprovalPanel;