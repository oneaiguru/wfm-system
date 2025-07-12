import React, { useState, useEffect } from 'react';
import { 
  FileText, 
  Clock, 
  CheckCircle, 
  XCircle, 
  AlertTriangle,
  User,
  Calendar,
  MessageSquare,
  ArrowRight,
  Plus,
  Edit,
  Eye,
  Filter,
  RefreshCw,
  Target
} from 'lucide-react';

// BDD: Business process workflows - Adapted from RequestManager
// Based on: 03-complete-business-process.feature

interface ProcessWorkflow {
  id: string;
  type: 'sick_leave' | 'vacation' | 'shift_exchange' | 'overtime' | 'training_request';
  title: string;
  status: 'draft' | 'submitted' | 'in_review' | 'approved' | 'rejected' | 'cancelled' | 'completed';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  requestedBy: {
    id: string;
    name: string;
    department: string;
    position: string;
  };
  assignedTo?: {
    id: string;
    name: string;
    role: string;
  };
  createdAt: Date;
  updatedAt: Date;
  dueDate?: Date;
  processSteps: ProcessStep[];
  validationMessages: ValidationMessage[];
  statusProgression: StatusProgression[];
  businessRules: {
    requiredApprovals: number;
    autoApprovalThreshold?: number;
    escalationHours: number;
    complianceChecks: string[];
  };
  documents: Document[];
  metrics: {
    processingTime: number;
    currentStepDuration: number;
    slaCompliance: boolean;
  };
}

interface ProcessStep {
  id: string;
  name: string;
  status: 'pending' | 'in_progress' | 'completed' | 'skipped' | 'failed';
  assignedTo?: string;
  completedAt?: Date;
  estimatedHours: number;
  actualHours?: number;
  required: boolean;
  automationLevel: 'manual' | 'semi_auto' | 'auto';
}

interface ValidationMessage {
  id: string;
  type: 'error' | 'warning' | 'info';
  field: string;
  message: string;
  severity: number;
  resolved: boolean;
}

interface StatusProgression {
  status: string;
  timestamp: Date;
  actor: string;
  comments?: string;
  systemAction: boolean;
}

interface Document {
  id: string;
  name: string;
  type: string;
  size: number;
  uploadedAt: Date;
  required: boolean;
  verified: boolean;
}

const ProcessWorkflowManager: React.FC = () => {
  const [workflows, setWorkflows] = useState<ProcessWorkflow[]>([]);
  const [selectedWorkflow, setSelectedWorkflow] = useState<ProcessWorkflow | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [filter, setFilter] = useState<{
    status: string;
    type: string;
    priority: string;
  }>({
    status: 'all',
    type: 'all', 
    priority: 'all'
  });

  // BDD: Load process workflows with complete business logic
  useEffect(() => {
    const mockWorkflows: ProcessWorkflow[] = [
      {
        id: 'wf_001',
        type: 'sick_leave',
        title: 'Больничный лист - Елена Козлова',
        status: 'in_review',
        priority: 'high',
        requestedBy: {
          id: 'emp_003',
          name: 'Елена Козлова',
          department: 'Техподдержка',
          position: 'Оператор'
        },
        assignedTo: {
          id: 'mgr_001',
          name: 'Анна Петрова',
          role: 'Руководитель группы'
        },
        createdAt: new Date('2024-07-10T09:00:00'),
        updatedAt: new Date('2024-07-10T14:30:00'),
        dueDate: new Date('2024-07-12T17:00:00'),
        processSteps: [
          {
            id: 'step_001',
            name: 'Подача заявления',
            status: 'completed',
            completedAt: new Date('2024-07-10T09:15:00'),
            estimatedHours: 0.25,
            actualHours: 0.25,
            required: true,
            automationLevel: 'semi_auto'
          },
          {
            id: 'step_002', 
            name: 'Проверка документов',
            status: 'in_progress',
            assignedTo: 'Отдел кадров',
            estimatedHours: 2,
            actualHours: 1.5,
            required: true,
            automationLevel: 'manual'
          },
          {
            id: 'step_003',
            name: 'Согласование руководителя',
            status: 'pending',
            estimatedHours: 1,
            required: true,
            automationLevel: 'manual'
          },
          {
            id: 'step_004',
            name: 'Корректировка расписания',
            status: 'pending',
            estimatedHours: 0.5,
            required: true,
            automationLevel: 'auto'
          }
        ],
        validationMessages: [
          {
            id: 'val_001',
            type: 'warning',
            field: 'медицинская_справка',
            message: 'Требуется загрузить медицинскую справку',
            severity: 2,
            resolved: false
          }
        ],
        statusProgression: [
          {
            status: 'submitted',
            timestamp: new Date('2024-07-10T09:00:00'),
            actor: 'Елена Козлова',
            systemAction: false
          },
          {
            status: 'in_review',
            timestamp: new Date('2024-07-10T09:30:00'),
            actor: 'Система',
            comments: 'Автоматический переход на проверку',
            systemAction: true
          }
        ],
        businessRules: {
          requiredApprovals: 2,
          escalationHours: 24,
          complianceChecks: ['medical_certificate', 'manager_approval', 'schedule_impact']
        },
        documents: [
          {
            id: 'doc_001',
            name: 'заявление_больничный.pdf',
            type: 'application/pdf',
            size: 245760,
            uploadedAt: new Date('2024-07-10T09:05:00'),
            required: true,
            verified: true
          }
        ],
        metrics: {
          processingTime: 5.5,
          currentStepDuration: 1.5,
          slaCompliance: true
        }
      },
      {
        id: 'wf_002',
        type: 'vacation',
        title: 'Отпуск - Михаил Волков',
        status: 'approved',
        priority: 'normal',
        requestedBy: {
          id: 'emp_002',
          name: 'Михаил Волков',
          department: 'Продажи',
          position: 'Старший оператор'
        },
        assignedTo: {
          id: 'mgr_002',
          name: 'Павел Орлов',
          role: 'Менеджер отдела'
        },
        createdAt: new Date('2024-07-08T10:00:00'),
        updatedAt: new Date('2024-07-09T16:00:00'),
        dueDate: new Date('2024-07-15T17:00:00'),
        processSteps: [
          {
            id: 'step_001',
            name: 'Подача заявления',
            status: 'completed',
            completedAt: new Date('2024-07-08T10:15:00'),
            estimatedHours: 0.25,
            actualHours: 0.25,
            required: true,
            automationLevel: 'semi_auto'
          },
          {
            id: 'step_002',
            name: 'Проверка остатка отпуска',
            status: 'completed',
            completedAt: new Date('2024-07-08T11:00:00'),
            estimatedHours: 0.5,
            actualHours: 0.75,
            required: true,
            automationLevel: 'auto'
          },
          {
            id: 'step_003',
            name: 'Согласование замещения',
            status: 'completed',
            completedAt: new Date('2024-07-09T14:00:00'),
            estimatedHours: 4,
            actualHours: 6,
            required: true,
            automationLevel: 'manual'
          },
          {
            id: 'step_004',
            name: 'Финальное утверждение',
            status: 'completed',
            completedAt: new Date('2024-07-09T16:00:00'),
            estimatedHours: 1,
            actualHours: 1,
            required: true,
            automationLevel: 'manual'
          }
        ],
        validationMessages: [],
        statusProgression: [
          {
            status: 'submitted',
            timestamp: new Date('2024-07-08T10:00:00'),
            actor: 'Михаил Волков',
            systemAction: false
          },
          {
            status: 'approved',
            timestamp: new Date('2024-07-09T16:00:00'),
            actor: 'Павел Орлов',
            comments: 'Утверждено с заменой на Анну Петрову',
            systemAction: false
          }
        ],
        businessRules: {
          requiredApprovals: 1,
          autoApprovalThreshold: 5,
          escalationHours: 48,
          complianceChecks: ['vacation_balance', 'replacement_coverage', 'team_capacity']
        },
        documents: [],
        metrics: {
          processingTime: 30,
          currentStepDuration: 0,
          slaCompliance: true
        }
      },
      {
        id: 'wf_003',
        type: 'shift_exchange',
        title: 'Обмен смен - София Иванова',
        status: 'submitted',
        priority: 'normal',
        requestedBy: {
          id: 'emp_005',
          name: 'София Иванова',
          department: 'Обучение',
          position: 'Специалист по обучению'
        },
        createdAt: new Date('2024-07-11T08:00:00'),
        updatedAt: new Date('2024-07-11T08:00:00'),
        dueDate: new Date('2024-07-13T17:00:00'),
        processSteps: [
          {
            id: 'step_001',
            name: 'Подача заявления',
            status: 'completed',
            completedAt: new Date('2024-07-11T08:15:00'),
            estimatedHours: 0.25,
            actualHours: 0.25,
            required: true,
            automationLevel: 'semi_auto'
          },
          {
            id: 'step_002',
            name: 'Поиск обменщика',
            status: 'in_progress',
            estimatedHours: 8,
            actualHours: 2,
            required: true,
            automationLevel: 'manual'
          },
          {
            id: 'step_003',
            name: 'Согласование обеих сторон',
            status: 'pending',
            estimatedHours: 2,
            required: true,
            automationLevel: 'manual'
          }
        ],
        validationMessages: [
          {
            id: 'val_002',
            type: 'info',
            field: 'обменщик',
            message: 'Идет поиск подходящего сотрудника для обмена',
            severity: 1,
            resolved: false
          }
        ],
        statusProgression: [
          {
            status: 'submitted',
            timestamp: new Date('2024-07-11T08:00:00'),
            actor: 'София Иванова',
            systemAction: false
          }
        ],
        businessRules: {
          requiredApprovals: 1,
          escalationHours: 48,
          complianceChecks: ['skill_compatibility', 'schedule_conflicts', 'mutual_consent']
        },
        documents: [],
        metrics: {
          processingTime: 3,
          currentStepDuration: 2,
          slaCompliance: true
        }
      }
    ];

    setWorkflows(mockWorkflows);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800 border-green-200';
      case 'in_review': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'submitted': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'rejected': return 'bg-red-100 text-red-800 border-red-200';
      case 'cancelled': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'completed': return 'bg-purple-100 text-purple-800 border-purple-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4" />;
      case 'in_review': return <Clock className="h-4 w-4" />;
      case 'submitted': return <FileText className="h-4 w-4" />;
      case 'rejected': return <XCircle className="h-4 w-4" />;
      case 'cancelled': return <XCircle className="h-4 w-4" />;
      case 'completed': return <Target className="h-4 w-4" />;
      default: return <AlertTriangle className="h-4 w-4" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent': return 'text-red-600';
      case 'high': return 'text-orange-600';
      case 'normal': return 'text-blue-600';
      case 'low': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'sick_leave': return 'Больничный';
      case 'vacation': return 'Отпуск';
      case 'shift_exchange': return 'Обмен смен';
      case 'overtime': return 'Сверхурочные';
      case 'training_request': return 'Обучение';
      default: return type;
    }
  };

  const getStepStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-500';
      case 'in_progress': return 'bg-blue-500';
      case 'pending': return 'bg-gray-300';
      case 'failed': return 'bg-red-500';
      case 'skipped': return 'bg-yellow-500';
      default: return 'bg-gray-300';
    }
  };

  const calculateProgress = (workflow: ProcessWorkflow): number => {
    const completed = workflow.processSteps.filter(step => step.status === 'completed').length;
    return (completed / workflow.processSteps.length) * 100;
  };

  const filteredWorkflows = workflows.filter(workflow => {
    const statusMatch = filter.status === 'all' || workflow.status === filter.status;
    const typeMatch = filter.type === 'all' || workflow.type === filter.type;
    const priorityMatch = filter.priority === 'all' || workflow.priority === filter.priority;
    return statusMatch && typeMatch && priorityMatch;
  });

  const workflowStats = {
    total: workflows.length,
    pending: workflows.filter(w => ['submitted', 'in_review'].includes(w.status)).length,
    approved: workflows.filter(w => w.status === 'approved').length,
    slaCompliant: workflows.filter(w => w.metrics.slaCompliance).length
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header - BDD: Business process workflow management */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <FileText className="h-6 w-6 mr-2 text-blue-600" />
              Бизнес-процессы и рабочие потоки
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">⚙️</span>
              Управление процессами заявок и согласований
            </p>
          </div>
          
          <button
            onClick={() => setIsCreating(true)}
            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4 mr-2" />
            Создать процесс
          </button>
        </div>
      </div>

      {/* Statistics Dashboard - BDD: Process metrics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <FileText className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Всего процессов</h3>
              <p className="text-2xl font-bold text-blue-600">{workflowStats.total}</p>
              <p className="text-sm text-gray-600">Активных и завершенных</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">В обработке</h3>
              <p className="text-2xl font-bold text-yellow-600">{workflowStats.pending}</p>
              <p className="text-sm text-gray-600">Требуют внимания</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Утверждено</h3>
              <p className="text-2xl font-bold text-green-600">{workflowStats.approved}</p>
              <p className="text-sm text-gray-600">За этот период</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Target className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">SLA выполнение</h3>
              <p className="text-2xl font-bold text-purple-600">
                {Math.round((workflowStats.slaCompliant / workflowStats.total) * 100)}%
              </p>
              <p className="text-sm text-gray-600">Соблюдение сроков</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center space-x-4">
          <Filter className="h-5 w-5 text-gray-400" />
          <select
            value={filter.status}
            onChange={(e) => setFilter(prev => ({ ...prev, status: e.target.value }))}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Все статусы</option>
            <option value="submitted">Подано</option>
            <option value="in_review">На рассмотрении</option>
            <option value="approved">Утверждено</option>
            <option value="rejected">Отклонено</option>
          </select>

          <select
            value={filter.type}
            onChange={(e) => setFilter(prev => ({ ...prev, type: e.target.value }))}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Все типы</option>
            <option value="sick_leave">Больничный</option>
            <option value="vacation">Отпуск</option>
            <option value="shift_exchange">Обмен смен</option>
            <option value="overtime">Сверхурочные</option>
          </select>

          <select
            value={filter.priority}
            onChange={(e) => setFilter(prev => ({ ...prev, priority: e.target.value }))}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Все приоритеты</option>
            <option value="urgent">Срочно</option>
            <option value="high">Высокий</option>
            <option value="normal">Обычный</option>
            <option value="low">Низкий</option>
          </select>

          <button className="flex items-center px-3 py-2 text-gray-600 hover:text-blue-600">
            <RefreshCw className="h-4 w-4 mr-1" />
            Обновить
          </button>
        </div>
      </div>

      {/* Workflow List - BDD: Process tracking */}
      <div className="space-y-4">
        {filteredWorkflows.map(workflow => (
          <div
            key={workflow.id}
            className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
          >
            {/* Header */}
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-3">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border-2 ${getStatusColor(workflow.status)}`}>
                  {getStatusIcon(workflow.status)}
                  <span className="ml-1">{workflow.status.replace('_', ' ')}</span>
                </span>
                <span className="text-sm font-medium text-gray-600">
                  {getTypeLabel(workflow.type)}
                </span>
                <span className={`text-sm font-medium ${getPriorityColor(workflow.priority)}`}>
                  {workflow.priority}
                </span>
              </div>

              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setSelectedWorkflow(workflow)}
                  className="p-2 text-gray-400 hover:text-blue-600"
                >
                  <Eye className="h-4 w-4" />
                </button>
                <button className="p-2 text-gray-400 hover:text-green-600">
                  <Edit className="h-4 w-4" />
                </button>
              </div>
            </div>

            {/* Content */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Column */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  {workflow.title}
                </h3>
                
                <div className="space-y-2 text-sm text-gray-600 mb-4">
                  <div className="flex items-center">
                    <User className="h-4 w-4 mr-2" />
                    <span>{workflow.requestedBy.name} ({workflow.requestedBy.department})</span>
                  </div>
                  <div className="flex items-center">
                    <Calendar className="h-4 w-4 mr-2" />
                    <span>Создано: {workflow.createdAt.toLocaleDateString('ru-RU')}</span>
                  </div>
                  {workflow.dueDate && (
                    <div className="flex items-center">
                      <Clock className="h-4 w-4 mr-2" />
                      <span>Срок: {workflow.dueDate.toLocaleDateString('ru-RU')}</span>
                    </div>
                  )}
                </div>

                {/* Validation Messages */}
                {workflow.validationMessages.length > 0 && (
                  <div className="space-y-2">
                    {workflow.validationMessages.filter(msg => !msg.resolved).map(msg => (
                      <div
                        key={msg.id}
                        className={`p-2 rounded-md text-sm ${
                          msg.type === 'error' ? 'bg-red-50 text-red-700' :
                          msg.type === 'warning' ? 'bg-yellow-50 text-yellow-700' :
                          'bg-blue-50 text-blue-700'
                        }`}
                      >
                        <div className="flex items-center">
                          {msg.type === 'error' && <XCircle className="h-4 w-4 mr-2" />}
                          {msg.type === 'warning' && <AlertTriangle className="h-4 w-4 mr-2" />}
                          {msg.type === 'info' && <MessageSquare className="h-4 w-4 mr-2" />}
                          {msg.message}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Right Column - Process Steps */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h4 className="text-sm font-medium text-gray-900">Прогресс процесса</h4>
                  <span className="text-sm text-gray-600">
                    {Math.round(calculateProgress(workflow))}% завершено
                  </span>
                </div>

                {/* Progress Bar */}
                <div className="w-full bg-gray-200 rounded-full h-2 mb-4">
                  <div 
                    className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${calculateProgress(workflow)}%` }}
                  ></div>
                </div>

                {/* Process Steps */}
                <div className="space-y-2">
                  {workflow.processSteps.map((step, index) => (
                    <div key={step.id} className="flex items-center space-x-3">
                      <div className={`w-3 h-3 rounded-full ${getStepStatusColor(step.status)}`}></div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {step.name}
                        </p>
                        <div className="flex items-center space-x-2 text-xs text-gray-500">
                          <span>{step.status.replace('_', ' ')}</span>
                          {step.actualHours && (
                            <>
                              <span>•</span>
                              <span>{step.actualHours}ч</span>
                            </>
                          )}
                        </div>
                      </div>
                      {index < workflow.processSteps.length - 1 && (
                        <ArrowRight className="h-3 w-3 text-gray-400" />
                      )}
                    </div>
                  ))}
                </div>

                {/* Metrics */}
                <div className="mt-4 pt-4 border-t border-gray-100">
                  <div className="grid grid-cols-2 gap-4 text-center">
                    <div>
                      <p className="text-xs text-gray-500">Время обработки</p>
                      <p className="text-sm font-bold text-gray-900">
                        {workflow.metrics.processingTime}ч
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">SLA статус</p>
                      <p className={`text-sm font-bold ${workflow.metrics.slaCompliance ? 'text-green-600' : 'text-red-600'}`}>
                        {workflow.metrics.slaCompliance ? 'Соблюден' : 'Нарушен'}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Empty State */}
      {filteredWorkflows.length === 0 && (
        <div className="text-center py-12">
          <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Процессы не найдены</h3>
          <p className="text-gray-600">Попробуйте изменить фильтры или создать новый процесс</p>
        </div>
      )}

      {/* Workflow Detail Modal - BDD: Detailed process view */}
      {selectedWorkflow && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold text-gray-900">
                  Детали процесса: {selectedWorkflow.title}
                </h2>
                <button
                  onClick={() => setSelectedWorkflow(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
            </div>

            <div className="px-6 py-6 overflow-y-auto max-h-[75vh]">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Process Information */}
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">Информация о процессе</h3>
                    <div className="bg-gray-50 rounded-lg p-4 space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Тип:</span>
                        <span className="font-medium">{getTypeLabel(selectedWorkflow.type)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Статус:</span>
                        <span className="font-medium">{selectedWorkflow.status.replace('_', ' ')}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Приоритет:</span>
                        <span className="font-medium">{selectedWorkflow.priority}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Создан:</span>
                        <span className="font-medium">{selectedWorkflow.createdAt.toLocaleString('ru-RU')}</span>
                      </div>
                      {selectedWorkflow.dueDate && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Срок выполнения:</span>
                          <span className="font-medium">{selectedWorkflow.dueDate.toLocaleString('ru-RU')}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">История статусов</h3>
                    <div className="space-y-3">
                      {selectedWorkflow.statusProgression.map((progression, index) => (
                        <div key={index} className="flex items-start space-x-3">
                          <div className="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                          <div className="flex-1">
                            <div className="flex items-center space-x-2">
                              <span className="font-medium text-gray-900">{progression.status}</span>
                              <span className="text-xs text-gray-500">
                                {progression.timestamp.toLocaleString('ru-RU')}
                              </span>
                            </div>
                            <p className="text-sm text-gray-600">{progression.actor}</p>
                            {progression.comments && (
                              <p className="text-sm text-gray-600 italic">{progression.comments}</p>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Process Steps Detail */}
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">Этапы процесса</h3>
                    <div className="space-y-4">
                      {selectedWorkflow.processSteps.map(step => (
                        <div key={step.id} className="border border-gray-200 rounded-lg p-4">
                          <div className="flex items-center justify-between mb-2">
                            <h4 className="font-medium text-gray-900">{step.name}</h4>
                            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(step.status)}`}>
                              {step.status.replace('_', ' ')}
                            </span>
                          </div>
                          <div className="grid grid-cols-2 gap-4 text-sm text-gray-600">
                            <div>
                              <span className="font-medium">Плановое время:</span> {step.estimatedHours}ч
                            </div>
                            {step.actualHours && (
                              <div>
                                <span className="font-medium">Фактическое время:</span> {step.actualHours}ч
                              </div>
                            )}
                            <div>
                              <span className="font-medium">Обязательный:</span> {step.required ? 'Да' : 'Нет'}
                            </div>
                            <div>
                              <span className="font-medium">Автоматизация:</span> {step.automationLevel}
                            </div>
                          </div>
                          {step.assignedTo && (
                            <div className="mt-2 text-sm text-gray-600">
                              <span className="font-medium">Назначен:</span> {step.assignedTo}
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">Метрики процесса</h3>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-blue-50 rounded-lg p-4 text-center">
                        <p className="text-2xl font-bold text-blue-600">
                          {selectedWorkflow.metrics.processingTime}ч
                        </p>
                        <p className="text-sm text-blue-600">Время обработки</p>
                      </div>
                      <div className={`rounded-lg p-4 text-center ${
                        selectedWorkflow.metrics.slaCompliance ? 'bg-green-50' : 'bg-red-50'
                      }`}>
                        <p className={`text-2xl font-bold ${
                          selectedWorkflow.metrics.slaCompliance ? 'text-green-600' : 'text-red-600'
                        }`}>
                          {selectedWorkflow.metrics.slaCompliance ? '✓' : '✗'}
                        </p>
                        <p className={`text-sm ${
                          selectedWorkflow.metrics.slaCompliance ? 'text-green-600' : 'text-red-600'
                        }`}>
                          SLA соблюден
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="px-6 py-4 border-t border-gray-200 flex justify-end">
              <button
                onClick={() => setSelectedWorkflow(null)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
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

export default ProcessWorkflowManager;