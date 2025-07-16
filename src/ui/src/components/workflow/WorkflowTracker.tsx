import React, { useState, useEffect } from 'react';
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  User, 
  AlertTriangle, 
  ArrowRight,
  ArrowLeft,
  Eye,
  MessageSquare,
  FileText,
  Users,
  Calendar,
  PlayCircle,
  PauseCircle,
  RotateCcw
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

interface WorkflowStep {
  id: string;
  name: string;
  description: string;
  status: 'completed' | 'current' | 'pending' | 'rejected';
  assignee?: string;
  completedAt?: string;
  comments?: string;
  order: number;
}

interface WorkflowProcess {
  requestId: string;
  currentStep: number;
  steps: WorkflowStep[];
  totalSteps: number;
  startedAt: string;
  estimatedCompletion?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const WorkflowTracker: React.FC = () => {
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([]);
  const [selectedRequest, setSelectedRequest] = useState<PendingRequest | null>(null);
  const [workflowProcess, setWorkflowProcess] = useState<WorkflowProcess | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<string>('');
  const [comment, setComment] = useState<string>('');
  const [showCommentModal, setShowCommentModal] = useState<boolean>(false);
  const [actionType, setActionType] = useState<'approve' | 'reject' | 'escalate'>('approve');

  useEffect(() => {
    fetchPendingRequests();
  }, []);

  useEffect(() => {
    if (selectedRequest) {
      generateWorkflowProcess(selectedRequest);
    }
  }, [selectedRequest]);

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
      
      // Auto-select first request if none selected
      if (data.length > 0 && !selectedRequest) {
        setSelectedRequest(data[0]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки заявок');
      console.error('[WorkflowTracker] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const generateWorkflowProcess = (request: PendingRequest) => {
    // Generate a mock workflow process based on request type
    const baseSteps: WorkflowStep[] = [
      {
        id: 'initial_review',
        name: 'Первичная проверка',
        description: 'Проверка корректности заполнения заявки',
        status: 'completed',
        assignee: 'Система',
        completedAt: request.submitted_at,
        order: 1
      },
      {
        id: 'manager_review',
        name: 'Рассмотрение руководителем',
        description: 'Проверка и одобрение непосредственным руководителем',
        status: 'current',
        assignee: 'Иванов И.И.',
        order: 2
      },
      {
        id: 'hr_approval',
        name: 'Согласование с HR',
        description: 'Проверка соответствия политикам компании',
        status: 'pending',
        assignee: 'Петрова П.П.',
        order: 3
      },
      {
        id: 'final_approval',
        name: 'Финальное утверждение',
        description: 'Окончательное утверждение заявки',
        status: 'pending',
        assignee: 'Сидоров С.С.',
        order: 4
      }
    ];

    // Add additional steps for vacation requests
    if (request.request_type === 'vacation') {
      baseSteps.splice(2, 0, {
        id: 'schedule_check',
        name: 'Проверка графика',
        description: 'Проверка возможности предоставления отпуска',
        status: 'pending',
        assignee: 'Планировщик',
        order: 3
      });
      
      // Update order for remaining steps
      baseSteps.forEach((step, index) => {
        if (index >= 3) step.order = index + 1;
      });
    }

    const process: WorkflowProcess = {
      requestId: request.request_id,
      currentStep: 2,
      steps: baseSteps,
      totalSteps: baseSteps.length,
      startedAt: request.submitted_at,
      estimatedCompletion: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString()
    };

    setWorkflowProcess(process);
  };

  const handleStepAction = async (stepId: string, action: 'approve' | 'reject' | 'escalate') => {
    if (!selectedRequest) return;

    setActionLoading(stepId);
    setError('');
    
    try {
      if (action === 'approve') {
        const response = await fetch(`${API_BASE_URL}/requests/approve/${selectedRequest.request_id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            comment: comment,
            step_id: stepId
          })
        });
        
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.detail || `HTTP ${response.status}`);
        }
        
        // Update workflow process
        setWorkflowProcess(prev => {
          if (!prev) return prev;
          
          const updatedSteps = prev.steps.map(step => {
            if (step.id === stepId) {
              return {
                ...step,
                status: 'completed' as const,
                completedAt: new Date().toISOString(),
                comments: comment
              };
            }
            return step;
          });

          // Move to next step
          const currentStepIndex = updatedSteps.findIndex(step => step.id === stepId);
          if (currentStepIndex < updatedSteps.length - 1) {
            updatedSteps[currentStepIndex + 1].status = 'current';
          }

          return {
            ...prev,
            steps: updatedSteps,
            currentStep: Math.min(prev.currentStep + 1, prev.totalSteps)
          };
        });

        // If all steps completed, remove from pending list
        const allCompleted = workflowProcess?.steps.every(step => 
          step.status === 'completed' || step.id === stepId
        );
        
        if (allCompleted) {
          setPendingRequests(prev => prev.filter(req => req.request_id !== selectedRequest.request_id));
          setSelectedRequest(prev => {
            const remaining = pendingRequests.filter(req => req.request_id !== selectedRequest.request_id);
            return remaining.length > 0 ? remaining[0] : null;
          });
        }
      }
      
      setComment('');
      setShowCommentModal(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка выполнения действия');
      console.error('[WorkflowTracker] Action error:', err);
    } finally {
      setActionLoading('');
    }
  };

  const openActionModal = (action: 'approve' | 'reject' | 'escalate') => {
    setActionType(action);
    setShowCommentModal(true);
  };

  const getStepIcon = (status: WorkflowStep['status']) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-6 w-6 text-green-600" />;
      case 'current':
        return <PlayCircle className="h-6 w-6 text-blue-600" />;
      case 'pending':
        return <Clock className="h-6 w-6 text-gray-400" />;
      case 'rejected':
        return <XCircle className="h-6 w-6 text-red-600" />;
      default:
        return <Clock className="h-6 w-6 text-gray-400" />;
    }
  };

  const getProgressPercentage = () => {
    if (!workflowProcess) return 0;
    const completedSteps = workflowProcess.steps.filter(step => step.status === 'completed').length;
    return (completedSteps / workflowProcess.totalSteps) * 100;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
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
        <h1 className="text-2xl font-bold text-gray-900">Отслеживание workflow</h1>
        <p className="text-gray-600">Многоэтапное согласование заявок</p>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Requests List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-800">
                Активные заявки ({pendingRequests.length})
              </h2>
            </div>
            
            {pendingRequests.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <FileText className="h-12 w-12 mx-auto mb-4 text-gray-300" />
                <p>Нет активных заявок</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-200 max-h-96 overflow-y-auto">
                {pendingRequests.map((request) => (
                  <div
                    key={request.request_id}
                    onClick={() => setSelectedRequest(request)}
                    className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${
                      selectedRequest?.request_id === request.request_id ? 'bg-blue-50 border-r-4 border-blue-600' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center mb-2">
                          <User className="h-4 w-4 text-gray-400 mr-2" />
                          <h3 className="font-medium text-gray-900">{request.employee_name}</h3>
                        </div>
                        <div className="text-sm text-gray-600">
                          <div>{request.request_type}</div>
                          <div>{formatDate(request.start_date)}</div>
                          <div className="text-xs text-gray-500 mt-1">
                            {formatDateTime(request.submitted_at)}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className="h-4 w-4 text-gray-400" />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Workflow Details */}
        <div className="lg:col-span-2">
          {selectedRequest && workflowProcess ? (
            <div className="space-y-6">
              {/* Request Details */}
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <div className="flex items-center justify-between">
                    <h2 className="text-lg font-semibold text-gray-800">
                      Заявка #{selectedRequest.request_id}
                    </h2>
                    <span className="px-3 py-1 bg-yellow-100 text-yellow-800 text-sm rounded-full">
                      В процессе
                    </span>
                  </div>
                </div>
                
                <div className="p-6">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="font-medium text-gray-700">Сотрудник:</span>
                      <div className="text-gray-900">{selectedRequest.employee_name}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Тип:</span>
                      <div className="text-gray-900">{selectedRequest.request_type}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Период:</span>
                      <div className="text-gray-900">
                        {formatDate(selectedRequest.start_date)} - {formatDate(selectedRequest.end_date)}
                      </div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Длительность:</span>
                      <div className="text-gray-900">{selectedRequest.duration_days} дней</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Progress Bar */}
              <div className="bg-white rounded-lg shadow p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-medium text-gray-900">Прогресс выполнения</h3>
                  <span className="text-sm text-gray-500">
                    {workflowProcess.currentStep} из {workflowProcess.totalSteps} этапов
                  </span>
                </div>
                
                <div className="w-full bg-gray-200 rounded-full h-2 mb-4">
                  <div 
                    className="bg-blue-600 h-2 rounded-full transition-all duration-500"
                    style={{ width: `${getProgressPercentage()}%` }}
                  ></div>
                </div>
                
                <div className="text-sm text-gray-600">
                  <div>Начато: {formatDateTime(workflowProcess.startedAt)}</div>
                  {workflowProcess.estimatedCompletion && (
                    <div>Ожидаемое завершение: {formatDateTime(workflowProcess.estimatedCompletion)}</div>
                  )}
                </div>
              </div>

              {/* Workflow Steps */}
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <h3 className="text-lg font-semibold text-gray-800">Этапы согласования</h3>
                </div>
                
                <div className="p-6">
                  <div className="space-y-4">
                    {workflowProcess.steps.map((step, index) => (
                      <div key={step.id} className="flex items-start gap-4">
                        <div className="flex-shrink-0">
                          {getStepIcon(step.status)}
                        </div>
                        
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <h4 className="font-medium text-gray-900">{step.name}</h4>
                            {step.status === 'current' && (
                              <div className="flex gap-2">
                                <button
                                  onClick={() => openActionModal('approve')}
                                  disabled={actionLoading === step.id}
                                  className="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 disabled:bg-gray-300 transition-colors"
                                >
                                  Одобрить
                                </button>
                                <button
                                  onClick={() => openActionModal('reject')}
                                  className="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition-colors"
                                >
                                  Отклонить
                                </button>
                                <button
                                  onClick={() => openActionModal('escalate')}
                                  className="px-3 py-1 bg-yellow-600 text-white text-sm rounded hover:bg-yellow-700 transition-colors"
                                >
                                  Эскалировать
                                </button>
                              </div>
                            )}
                          </div>
                          
                          <p className="text-sm text-gray-600 mt-1">{step.description}</p>
                          
                          <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                            {step.assignee && (
                              <div className="flex items-center gap-1">
                                <Users className="h-3 w-3" />
                                {step.assignee}
                              </div>
                            )}
                            {step.completedAt && (
                              <div className="flex items-center gap-1">
                                <Calendar className="h-3 w-3" />
                                {formatDateTime(step.completedAt)}
                              </div>
                            )}
                          </div>
                          
                          {step.comments && (
                            <div className="mt-2 p-2 bg-gray-50 rounded text-sm text-gray-700">
                              <div className="flex items-center gap-1 mb-1">
                                <MessageSquare className="h-3 w-3" />
                                Комментарий:
                              </div>
                              {step.comments}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
              <Eye className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>Выберите заявку для отслеживания workflow</p>
            </div>
          )}
        </div>
      </div>

      {/* Comment Modal */}
      {showCommentModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">
                {actionType === 'approve' ? 'Одобрить этап' :
                 actionType === 'reject' ? 'Отклонить этап' : 'Эскалировать этап'}
              </h3>
              <button
                onClick={() => setShowCommentModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircle className="h-5 w-5" />
              </button>
            </div>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Комментарий (необязательно)
              </label>
              <textarea
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="Добавьте комментарий к решению..."
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                rows={3}
              />
            </div>
            
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowCommentModal(false)}
                className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Отмена
              </button>
              <button
                onClick={() => {
                  const currentStep = workflowProcess?.steps.find(step => step.status === 'current');
                  if (currentStep) {
                    handleStepAction(currentStep.id, actionType);
                  }
                }}
                className={`px-4 py-2 text-white rounded-lg transition-colors ${
                  actionType === 'approve' ? 'bg-green-600 hover:bg-green-700' :
                  actionType === 'reject' ? 'bg-red-600 hover:bg-red-700' :
                  'bg-yellow-600 hover:bg-yellow-700'
                }`}
              >
                {actionType === 'approve' ? 'Одобрить' :
                 actionType === 'reject' ? 'Отклонить' : 'Эскалировать'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WorkflowTracker;