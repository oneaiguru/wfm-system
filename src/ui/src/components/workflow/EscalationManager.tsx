import React, { useState, useEffect } from 'react';
import { 
  AlertTriangle, 
  Clock, 
  User, 
  Users, 
  ArrowUp, 
  CheckCircle, 
  XCircle, 
  MessageSquare, 
  Calendar,
  RefreshCw,
  Bell,
  Target,
  Flame,
  Shield,
  Send
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

interface EscalatedRequest {
  request: PendingRequest;
  escalation_level: number;
  escalated_at: string;
  escalated_by: string;
  reason: string;
  urgency: 'low' | 'medium' | 'high' | 'critical';
  deadline: string;
  escalation_path: string[];
  current_approver: string;
  previous_approvers: string[];
  comments: EscalationComment[];
}

interface EscalationComment {
  id: string;
  author: string;
  content: string;
  timestamp: string;
  action_type?: 'escalate' | 'approve' | 'reject' | 'comment';
}

interface EscalationRule {
  id: string;
  name: string;
  condition: string;
  escalation_level: number;
  target_role: string;
  deadline_hours: number;
  auto_escalate: boolean;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const EscalationManager: React.FC = () => {
  const [escalatedRequests, setEscalatedRequests] = useState<EscalatedRequest[]>([]);
  const [selectedRequest, setSelectedRequest] = useState<EscalatedRequest | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<string>('');
  const [newComment, setNewComment] = useState<string>('');
  const [escalationRules, setEscalationRules] = useState<EscalationRule[]>([]);
  const [filterUrgency, setFilterUrgency] = useState<string>('all');
  const [filterLevel, setFilterLevel] = useState<string>('all');

  useEffect(() => {
    fetchEscalatedRequests();
    fetchEscalationRules();
    // Auto-refresh every 60 seconds
    const interval = setInterval(fetchEscalatedRequests, 60000);
    return () => clearInterval(interval);
  }, []);

  const fetchEscalatedRequests = async () => {
    setLoading(true);
    setError('');
    
    try {
      // In a real implementation, this would be a dedicated endpoint for escalated requests
      const response = await fetch(`${API_BASE_URL}/requests/pending`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const pendingRequests: PendingRequest[] = await response.json();
      
      // Mock escalated requests based on pending requests
      const escalated = pendingRequests
        .filter((_, index) => index % 3 === 0) // Mock: every third request is escalated
        .map((request, index): EscalatedRequest => {
          const escalatedDays = Math.floor((Date.now() - new Date(request.submitted_at).getTime()) / (1000 * 60 * 60 * 24));
          const urgency = escalatedDays > 7 ? 'critical' : escalatedDays > 5 ? 'high' : escalatedDays > 3 ? 'medium' : 'low';
          
          return {
            request,
            escalation_level: Math.min(Math.floor(escalatedDays / 3) + 1, 4),
            escalated_at: new Date(Date.now() - (escalatedDays - 2) * 24 * 60 * 60 * 1000).toISOString(),
            escalated_by: 'Система автоэскалации',
            reason: escalatedDays > 5 ? 'Превышен срок рассмотрения' : 'Сложность заявки',
            urgency: urgency as 'low' | 'medium' | 'high' | 'critical',
            deadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            escalation_path: ['Руководитель группы', 'Начальник отдела', 'Директор по персоналу', 'Генеральный директор'],
            current_approver: index % 2 === 0 ? 'Петров П.П.' : 'Сидоров С.С.',
            previous_approvers: ['Иванов И.И.'],
            comments: [
              {
                id: '1',
                author: 'Иванов И.И.',
                content: 'Требуется дополнительная проверка доступности замещения',
                timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
                action_type: 'escalate'
              }
            ]
          };
        });
      
      setEscalatedRequests(escalated);
      
      if (escalated.length > 0 && !selectedRequest) {
        setSelectedRequest(escalated[0]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка загрузки эскалированных заявок');
      console.error('[EscalationManager] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchEscalationRules = async () => {
    // Mock escalation rules
    const rules: EscalationRule[] = [
      {
        id: '1',
        name: 'Автоэскалация при превышении 3 дней',
        condition: 'pending_time > 72h',
        escalation_level: 1,
        target_role: 'Начальник отдела',
        deadline_hours: 24,
        auto_escalate: true
      },
      {
        id: '2',
        name: 'Критическая эскалация через 7 дней',
        condition: 'pending_time > 168h',
        escalation_level: 3,
        target_role: 'Директор по персоналу',
        deadline_hours: 12,
        auto_escalate: true
      }
    ];
    
    setEscalationRules(rules);
  };

  const handleApprove = async (requestId: string) => {
    setActionLoading(requestId);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/requests/approve/${requestId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          escalation_approval: true,
          approver_comment: newComment
        })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `HTTP ${response.status}`);
      }
      
      // Remove from escalated requests
      setEscalatedRequests(prev => prev.filter(req => req.request.request_id !== requestId));
      setSelectedRequest(null);
      setNewComment('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка при одобрении заявки');
      console.error('[EscalationManager] Approval error:', err);
    } finally {
      setActionLoading('');
    }
  };

  const handleEscalateUp = async (requestId: string) => {
    setActionLoading(`escalate_${requestId}`);
    setError('');
    
    try {
      // Mock escalation up - in real implementation this would call a dedicated endpoint
      setEscalatedRequests(prev => prev.map(escalated => {
        if (escalated.request.request_id === requestId) {
          const newLevel = Math.min(escalated.escalation_level + 1, 4);
          const newComment: EscalationComment = {
            id: Date.now().toString(),
            author: 'Текущий пользователь',
            content: newComment || 'Эскалация на следующий уровень',
            timestamp: new Date().toISOString(),
            action_type: 'escalate'
          };
          
          return {
            ...escalated,
            escalation_level: newLevel,
            current_approver: escalated.escalation_path[newLevel - 1] || 'Генеральный директор',
            urgency: newLevel >= 3 ? 'critical' : 'high',
            comments: [...escalated.comments, newComment],
            deadline: new Date(Date.now() + (newLevel >= 3 ? 12 : 24) * 60 * 60 * 1000).toISOString()
          };
        }
        return escalated;
      }));
      
      setNewComment('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка при эскалации');
      console.error('[EscalationManager] Escalation error:', err);
    } finally {
      setActionLoading('');
    }
  };

  const addComment = async () => {
    if (!newComment.trim() || !selectedRequest) return;
    
    const comment: EscalationComment = {
      id: Date.now().toString(),
      author: 'Текущий пользователь',
      content: newComment,
      timestamp: new Date().toISOString(),
      action_type: 'comment'
    };
    
    setEscalatedRequests(prev => prev.map(escalated => {
      if (escalated.request.request_id === selectedRequest.request.request_id) {
        return {
          ...escalated,
          comments: [...escalated.comments, comment]
        };
      }
      return escalated;
    }));
    
    setSelectedRequest(prev => prev ? {
      ...prev,
      comments: [...prev.comments, comment]
    } : null);
    
    setNewComment('');
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getUrgencyIcon = (urgency: string) => {
    switch (urgency) {
      case 'critical': return <Flame className="h-4 w-4" />;
      case 'high': return <AlertTriangle className="h-4 w-4" />;
      case 'medium': return <Clock className="h-4 w-4" />;
      default: return <Shield className="h-4 w-4" />;
    }
  };

  const getTimeRemaining = (deadline: string) => {
    const now = new Date();
    const deadlineDate = new Date(deadline);
    const hoursRemaining = Math.max(0, Math.floor((deadlineDate.getTime() - now.getTime()) / (1000 * 60 * 60)));
    
    if (hoursRemaining === 0) return 'Просрочено';
    if (hoursRemaining < 24) return `${hoursRemaining} ч.`;
    return `${Math.floor(hoursRemaining / 24)} дн.`;
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

  const filteredRequests = escalatedRequests.filter(escalated => {
    if (filterUrgency !== 'all' && escalated.urgency !== filterUrgency) return false;
    if (filterLevel !== 'all' && escalated.escalation_level.toString() !== filterLevel) return false;
    return true;
  });

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
            <h1 className="text-2xl font-bold text-gray-900">Менеджер эскалации</h1>
            <p className="text-gray-600">Управление эскалированными заявками</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Bell className="h-5 w-5 text-orange-500" />
              <span className="text-sm text-gray-600">
                {escalatedRequests.filter(r => r.urgency === 'critical').length} критических
              </span>
            </div>
            <button
              onClick={fetchEscalatedRequests}
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
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Всего эскалированных</p>
              <p className="text-2xl font-bold text-blue-600">{escalatedRequests.length}</p>
            </div>
            <ArrowUp className="h-8 w-8 text-blue-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Критических</p>
              <p className="text-2xl font-bold text-red-600">
                {escalatedRequests.filter(r => r.urgency === 'critical').length}
              </p>
            </div>
            <Flame className="h-8 w-8 text-red-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Просроченных</p>
              <p className="text-2xl font-bold text-orange-600">
                {escalatedRequests.filter(r => new Date(r.deadline) < new Date()).length}
              </p>
            </div>
            <Clock className="h-8 w-8 text-orange-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ср. время эскалации</p>
              <p className="text-2xl font-bold text-green-600">2.5 дн.</p>
            </div>
            <Target className="h-8 w-8 text-green-600" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-6">
          <div className="flex gap-4 items-center">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Приоритет</label>
              <select
                value={filterUrgency}
                onChange={(e) => setFilterUrgency(e.target.value)}
                className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все</option>
                <option value="critical">Критический</option>
                <option value="high">Высокий</option>
                <option value="medium">Средний</option>
                <option value="low">Низкий</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Уровень эскалации</label>
              <select
                value={filterLevel}
                onChange={(e) => setFilterLevel(e.target.value)}
                className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Все уровни</option>
                <option value="1">Уровень 1</option>
                <option value="2">Уровень 2</option>
                <option value="3">Уровень 3</option>
                <option value="4">Уровень 4</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Escalated Requests List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-800">
                Эскалированные заявки ({filteredRequests.length})
              </h2>
            </div>
            
            {filteredRequests.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <AlertTriangle className="h-12 w-12 mx-auto mb-4 text-gray-300" />
                <p>Нет эскалированных заявок</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-200 max-h-96 overflow-y-auto">
                {filteredRequests.map((escalated) => (
                  <div
                    key={escalated.request.request_id}
                    onClick={() => setSelectedRequest(escalated)}
                    className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${
                      selectedRequest?.request.request_id === escalated.request.request_id ? 
                      'bg-blue-50 border-r-4 border-blue-600' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex-1">
                        <div className="flex items-center mb-1">
                          <User className="h-4 w-4 text-gray-400 mr-2" />
                          <h3 className="font-medium text-gray-900">{escalated.request.employee_name}</h3>
                        </div>
                        <div className="text-sm text-gray-600">
                          <div>{escalated.request.request_type}</div>
                          <div className="flex items-center gap-2 mt-1">
                            <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs rounded-full ${getUrgencyColor(escalated.urgency)}`}>
                              {getUrgencyIcon(escalated.urgency)}
                              {escalated.urgency}
                            </span>
                            <span className="text-xs text-gray-500">
                              Уровень {escalated.escalation_level}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="text-right text-xs text-gray-500">
                        {getTimeRemaining(escalated.deadline)}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Request Details */}
        <div className="lg:col-span-2">
          {selectedRequest ? (
            <div className="space-y-6">
              {/* Request Info */}
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <div className="flex items-center justify-between">
                    <h2 className="text-lg font-semibold text-gray-800">
                      Заявка #{selectedRequest.request.request_id}
                    </h2>
                    <div className="flex items-center gap-2">
                      <span className={`px-3 py-1 text-sm rounded-full ${getUrgencyColor(selectedRequest.urgency)}`}>
                        {selectedRequest.urgency}
                      </span>
                      <span className="px-3 py-1 bg-purple-100 text-purple-800 text-sm rounded-full">
                        Уровень {selectedRequest.escalation_level}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="p-6">
                  <div className="grid grid-cols-2 gap-4 text-sm mb-4">
                    <div>
                      <span className="font-medium text-gray-700">Сотрудник:</span>
                      <div className="text-gray-900">{selectedRequest.request.employee_name}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Тип:</span>
                      <div className="text-gray-900">{selectedRequest.request.request_type}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Эскалирована:</span>
                      <div className="text-gray-900">{formatDateTime(selectedRequest.escalated_at)}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Дедлайн:</span>
                      <div className="text-gray-900">{formatDateTime(selectedRequest.deadline)}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Текущий утверждающий:</span>
                      <div className="text-gray-900">{selectedRequest.current_approver}</div>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Причина эскалации:</span>
                      <div className="text-gray-900">{selectedRequest.reason}</div>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2 pt-4 border-t border-gray-200">
                    <button
                      onClick={() => handleApprove(selectedRequest.request.request_id)}
                      disabled={actionLoading === selectedRequest.request.request_id}
                      className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-300 transition-colors flex items-center gap-2"
                    >
                      <CheckCircle className="h-4 w-4" />
                      Одобрить
                    </button>
                    
                    <button
                      onClick={() => handleEscalateUp(selectedRequest.request.request_id)}
                      disabled={actionLoading === `escalate_${selectedRequest.request.request_id}` || selectedRequest.escalation_level >= 4}
                      className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:bg-gray-300 transition-colors flex items-center gap-2"
                    >
                      <ArrowUp className="h-4 w-4" />
                      Эскалировать выше
                    </button>
                    
                    <button className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors flex items-center gap-2">
                      <XCircle className="h-4 w-4" />
                      Отклонить
                    </button>
                  </div>
                </div>
              </div>

              {/* Comments */}
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <h3 className="text-lg font-semibold text-gray-800">
                    История и комментарии ({selectedRequest.comments.length})
                  </h3>
                </div>
                
                <div className="p-6">
                  <div className="space-y-4 mb-4 max-h-64 overflow-y-auto">
                    {selectedRequest.comments.map((comment) => (
                      <div key={comment.id} className="border-l-4 border-blue-200 pl-4">
                        <div className="flex items-center justify-between mb-1">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-gray-900">{comment.author}</span>
                            {comment.action_type && (
                              <span className="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded">
                                {comment.action_type === 'escalate' ? 'Эскалация' :
                                 comment.action_type === 'approve' ? 'Одобрение' :
                                 comment.action_type === 'reject' ? 'Отклонение' : 'Комментарий'}
                              </span>
                            )}
                          </div>
                          <span className="text-xs text-gray-500">
                            {formatDateTime(comment.timestamp)}
                          </span>
                        </div>
                        <p className="text-gray-700 text-sm">{comment.content}</p>
                      </div>
                    ))}
                  </div>

                  {/* Add Comment */}
                  <div className="border-t border-gray-200 pt-4">
                    <div className="flex gap-2">
                      <div className="flex-1">
                        <textarea
                          value={newComment}
                          onChange={(e) => setNewComment(e.target.value)}
                          placeholder="Добавить комментарий..."
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                          rows={2}
                        />
                      </div>
                      <button
                        onClick={addComment}
                        disabled={!newComment.trim()}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 transition-colors flex items-center gap-2"
                      >
                        <Send className="h-4 w-4" />
                        Отправить
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
              <AlertTriangle className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>Выберите заявку для просмотра деталей</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default EscalationManager;