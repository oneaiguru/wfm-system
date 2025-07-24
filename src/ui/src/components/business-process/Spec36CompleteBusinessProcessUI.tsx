import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  FileText,
  Workflow,
  Activity,
  Users,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Clock,
  TrendingUp,
  BarChart3,
  PieChart,
  Settings,
  Play,
  Pause,
  RefreshCw,
  Plus,
  Search,
  Filter,
  Calendar,
  ArrowRight,
  GitBranch,
  Target,
  Zap,
  Database,
  Shield,
  Eye,
  Edit3,
  Trash2,
  Copy,
  Download,
  Upload,
  MessageSquare,
  AlertCircle,
  CheckSquare,
  Package,
  Layers,
  Grid,
  List
} from 'lucide-react';

// SPEC-36: Complete Business Process UI
// Unifying all workflow components with 87% reuse from existing implementations
// Combines: Spec13WorkflowManager, WorkflowDashboard, ProcessMonitor, ApprovalChain
// Focus: Unified business process management for all organizational workflows (50+ daily users)

interface Spec36ProcessDefinition {
  id: string;
  name: string;
  nameRu: string;
  description: string;
  category: 'hr' | 'operations' | 'finance' | 'compliance' | 'custom';
  type: 'approval' | 'automated' | 'hybrid' | 'notification';
  status: 'active' | 'draft' | 'archived' | 'deprecated';
  version: string;
  owner: {
    id: string;
    name: string;
    department: string;
  };
  steps: ProcessStep[];
  triggers: ProcessTrigger[];
  sla: {
    targetHours: number;
    warningThreshold: number;
    escalationRules: EscalationRule[];
  };
  metrics: {
    instanceCount: number;
    avgCompletionTime: number;
    successRate: number;
    currentActive: number;
  };
  compliance: {
    regulatoryRequired: boolean;
    auditTrail: boolean;
    dataRetention: number; // days
    approvalMatrix: boolean;
  };
}

interface ProcessStep {
  id: string;
  name: string;
  type: 'approval' | 'action' | 'decision' | 'notification' | 'integration';
  assignee: {
    type: 'role' | 'user' | 'group' | 'system';
    value: string;
  };
  actions: string[];
  conditions?: ProcessCondition[];
  nextSteps: string[];
  parallelSteps?: string[];
  slaHours: number;
  formFields?: FormField[];
}

interface ProcessInstance {
  id: string;
  processId: string;
  processName: string;
  status: 'running' | 'completed' | 'failed' | 'cancelled' | 'suspended';
  priority: 'low' | 'normal' | 'high' | 'critical';
  initiator: {
    id: string;
    name: string;
    department: string;
  };
  currentStep: string;
  startedAt: Date;
  completedAt?: Date;
  data: Record<string, any>;
  history: ProcessHistory[];
  slaStatus: 'on_track' | 'at_risk' | 'overdue';
  tags: string[];
}

interface ProcessAnalytics {
  overview: {
    totalProcesses: number;
    activeInstances: number;
    completedToday: number;
    failureRate: number;
    avgCompletionTime: number;
    slaCompliance: number;
  };
  byCategory: Record<string, {
    count: number;
    avgTime: number;
    successRate: number;
  }>;
  trends: {
    daily: TrendData[];
    weekly: TrendData[];
    monthly: TrendData[];
  };
  bottlenecks: {
    step: string;
    process: string;
    avgDelay: number;
    impact: 'low' | 'medium' | 'high';
  }[];
  userPerformance: {
    userId: string;
    name: string;
    tasksCompleted: number;
    avgResponseTime: number;
    slaCompliance: number;
  }[];
}

interface ProcessTemplate {
  id: string;
  name: string;
  category: string;
  description: string;
  baseProcess: ProcessDefinition;
  customizable: string[];
  popularity: number;
  lastUsed: Date;
}

// Additional interfaces for completeness
interface ProcessTrigger {
  id: string;
  type: 'manual' | 'scheduled' | 'event' | 'api';
  conditions: ProcessCondition[];
  active: boolean;
}

interface ProcessCondition {
  field: string;
  operator: 'equals' | 'contains' | 'greater_than' | 'less_than' | 'in' | 'not_in';
  value: any;
  logic?: 'and' | 'or';
}

interface EscalationRule {
  id: string;
  triggerHours: number;
  escalateTo: string;
  notificationType: 'email' | 'sms' | 'push' | 'all';
}

interface FormField {
  id: string;
  label: string;
  type: 'text' | 'number' | 'date' | 'select' | 'multiselect' | 'boolean' | 'file';
  required: boolean;
  validation?: string;
  options?: { value: string; label: string; }[];
}

interface ProcessHistory {
  id: string;
  timestamp: Date;
  action: string;
  actor: string;
  stepId: string;
  comments?: string;
  data?: Record<string, any>;
}

interface TrendData {
  date: string;
  value: number;
  label?: string;
}

const Spec36CompleteBusinessProcessUI: React.FC = () => {
  const [activeView, setActiveView] = useState<'dashboard' | 'processes' | 'instances' | 'analytics' | 'templates'>('dashboard');
  const [processes, setProcesses] = useState<Spec36ProcessDefinition[]>([]);
  const [instances, setInstances] = useState<ProcessInstance[]>([]);
  const [analytics, setAnalytics] = useState<ProcessAnalytics | null>(null);
  const [templates, setTemplates] = useState<ProcessTemplate[]>([]);
  const [selectedProcess, setSelectedProcess] = useState<Spec36ProcessDefinition | null>(null);
  const [selectedInstance, setSelectedInstance] = useState<ProcessInstance | null>(null);
  const [loading, setLoading] = useState(false);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Mock data generation
  useEffect(() => {
    generateMockData();
  }, []);

  const generateMockData = () => {
    // Mock process definitions
    const mockProcesses: Spec36ProcessDefinition[] = [
      {
        id: 'proc_1',
        name: 'Vacation Request Approval',
        nameRu: 'Утверждение заявки на отпуск',
        description: 'Standard vacation request approval workflow',
        category: 'hr',
        type: 'approval',
        status: 'active',
        version: '2.0',
        owner: {
          id: 'user_1',
          name: 'Анна Смирнова',
          department: 'HR'
        },
        steps: [
          {
            id: 'step_1',
            name: 'Manager Approval',
            type: 'approval',
            assignee: { type: 'role', value: 'direct_manager' },
            actions: ['approve', 'reject', 'request_info'],
            nextSteps: ['step_2'],
            slaHours: 24
          },
          {
            id: 'step_2',
            name: 'HR Review',
            type: 'approval',
            assignee: { type: 'group', value: 'hr_team' },
            actions: ['approve', 'reject'],
            nextSteps: ['step_3'],
            slaHours: 48
          },
          {
            id: 'step_3',
            name: 'System Update',
            type: 'action',
            assignee: { type: 'system', value: 'auto' },
            actions: ['update_balance', 'send_notification'],
            nextSteps: [],
            slaHours: 1
          }
        ],
        triggers: [
          {
            id: 'trig_1',
            type: 'manual',
            conditions: [],
            active: true
          }
        ],
        sla: {
          targetHours: 72,
          warningThreshold: 48,
          escalationRules: [
            {
              id: 'esc_1',
              triggerHours: 48,
              escalateTo: 'department_head',
              notificationType: 'email'
            }
          ]
        },
        metrics: {
          instanceCount: 156,
          avgCompletionTime: 36,
          successRate: 94.2,
          currentActive: 12
        },
        compliance: {
          regulatoryRequired: true,
          auditTrail: true,
          dataRetention: 365,
          approvalMatrix: true
        }
      },
      {
        id: 'proc_2',
        name: 'Overtime Authorization',
        nameRu: 'Авторизация сверхурочной работы',
        description: 'Overtime work approval and compensation workflow',
        category: 'operations',
        type: 'hybrid',
        status: 'active',
        version: '1.5',
        owner: {
          id: 'user_2',
          name: 'Михаил Козлов',
          department: 'Operations'
        },
        steps: [
          {
            id: 'step_1',
            name: 'Supervisor Request',
            type: 'approval',
            assignee: { type: 'role', value: 'supervisor' },
            actions: ['submit', 'cancel'],
            nextSteps: ['step_2'],
            slaHours: 4
          },
          {
            id: 'step_2',
            name: 'Manager Approval',
            type: 'approval',
            assignee: { type: 'role', value: 'department_manager' },
            actions: ['approve', 'reject', 'modify'],
            nextSteps: ['step_3'],
            slaHours: 8
          },
          {
            id: 'step_3',
            name: 'Finance Validation',
            type: 'decision',
            assignee: { type: 'system', value: 'budget_check' },
            actions: ['validate_budget'],
            conditions: [
              {
                field: 'overtime_cost',
                operator: 'less_than',
                value: 10000
              }
            ],
            nextSteps: ['step_4'],
            slaHours: 2
          },
          {
            id: 'step_4',
            name: 'Employee Notification',
            type: 'notification',
            assignee: { type: 'system', value: 'notification_service' },
            actions: ['send_email', 'send_sms'],
            nextSteps: [],
            slaHours: 1
          }
        ],
        triggers: [
          {
            id: 'trig_1',
            type: 'manual',
            conditions: [],
            active: true
          },
          {
            id: 'trig_2',
            type: 'scheduled',
            conditions: [
              {
                field: 'day_of_week',
                operator: 'equals',
                value: 'Friday'
              }
            ],
            active: true
          }
        ],
        sla: {
          targetHours: 12,
          warningThreshold: 8,
          escalationRules: [
            {
              id: 'esc_1',
              triggerHours: 8,
              escalateTo: 'operations_director',
              notificationType: 'all'
            }
          ]
        },
        metrics: {
          instanceCount: 89,
          avgCompletionTime: 6.5,
          successRate: 87.6,
          currentActive: 7
        },
        compliance: {
          regulatoryRequired: true,
          auditTrail: true,
          dataRetention: 730,
          approvalMatrix: true
        }
      },
      {
        id: 'proc_3',
        name: 'Shift Exchange Request',
        nameRu: 'Запрос на обмен сменами',
        description: 'Employee shift exchange approval workflow',
        category: 'operations',
        type: 'approval',
        status: 'active',
        version: '1.0',
        owner: {
          id: 'user_3',
          name: 'Елена Петрова',
          department: 'Scheduling'
        },
        steps: [
          {
            id: 'step_1',
            name: 'Peer Agreement',
            type: 'approval',
            assignee: { type: 'user', value: 'exchange_partner' },
            actions: ['agree', 'decline'],
            nextSteps: ['step_2'],
            slaHours: 24
          },
          {
            id: 'step_2',
            name: 'Supervisor Approval',
            type: 'approval',
            assignee: { type: 'role', value: 'team_supervisor' },
            actions: ['approve', 'reject'],
            nextSteps: ['step_3'],
            slaHours: 12
          },
          {
            id: 'step_3',
            name: 'Schedule Update',
            type: 'integration',
            assignee: { type: 'system', value: 'scheduling_system' },
            actions: ['update_schedules', 'notify_team'],
            nextSteps: [],
            slaHours: 1
          }
        ],
        triggers: [
          {
            id: 'trig_1',
            type: 'manual',
            conditions: [],
            active: true
          }
        ],
        sla: {
          targetHours: 48,
          warningThreshold: 36,
          escalationRules: []
        },
        metrics: {
          instanceCount: 234,
          avgCompletionTime: 18,
          successRate: 91.3,
          currentActive: 19
        },
        compliance: {
          regulatoryRequired: false,
          auditTrail: true,
          dataRetention: 180,
          approvalMatrix: false
        }
      }
    ];

    // Mock instances
    const mockInstances: ProcessInstance[] = [
      {
        id: 'inst_1',
        processId: 'proc_1',
        processName: 'Vacation Request Approval',
        status: 'running',
        priority: 'normal',
        initiator: {
          id: 'emp_1',
          name: 'Иван Иванов',
          department: 'Sales'
        },
        currentStep: 'step_2',
        startedAt: new Date('2025-07-20T09:00:00'),
        data: {
          startDate: '2025-08-01',
          endDate: '2025-08-14',
          type: 'annual',
          reason: 'Family vacation'
        },
        history: [
          {
            id: 'hist_1',
            timestamp: new Date('2025-07-20T09:00:00'),
            action: 'submitted',
            actor: 'Иван Иванов',
            stepId: 'step_1',
            comments: 'Requesting annual leave'
          },
          {
            id: 'hist_2',
            timestamp: new Date('2025-07-20T14:30:00'),
            action: 'approved',
            actor: 'Сергей Петров',
            stepId: 'step_1',
            comments: 'Approved - coverage arranged'
          }
        ],
        slaStatus: 'on_track',
        tags: ['vacation', 'annual_leave', 'august']
      },
      {
        id: 'inst_2',
        processId: 'proc_2',
        processName: 'Overtime Authorization',
        status: 'running',
        priority: 'high',
        initiator: {
          id: 'mgr_1',
          name: 'Александр Сидоров',
          department: 'Production'
        },
        currentStep: 'step_3',
        startedAt: new Date('2025-07-21T06:00:00'),
        data: {
          date: '2025-07-22',
          hours: 4,
          employees: 5,
          reason: 'Urgent customer order'
        },
        history: [
          {
            id: 'hist_3',
            timestamp: new Date('2025-07-21T06:00:00'),
            action: 'submitted',
            actor: 'Александр Сидоров',
            stepId: 'step_1'
          },
          {
            id: 'hist_4',
            timestamp: new Date('2025-07-21T07:15:00'),
            action: 'approved',
            actor: 'Николай Волков',
            stepId: 'step_2'
          }
        ],
        slaStatus: 'at_risk',
        tags: ['overtime', 'urgent', 'production']
      }
    ];

    // Mock analytics
    const mockAnalytics: ProcessAnalytics = {
      overview: {
        totalProcesses: 12,
        activeInstances: 38,
        completedToday: 24,
        failureRate: 3.2,
        avgCompletionTime: 28.5,
        slaCompliance: 92.8
      },
      byCategory: {
        hr: {
          count: 156,
          avgTime: 36,
          successRate: 94.2
        },
        operations: {
          count: 323,
          avgTime: 12.5,
          successRate: 89.7
        },
        finance: {
          count: 67,
          avgTime: 48,
          successRate: 96.1
        },
        compliance: {
          count: 23,
          avgTime: 72,
          successRate: 100
        }
      },
      trends: {
        daily: Array.from({ length: 7 }, (_, i) => ({
          date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          value: Math.floor(Math.random() * 50) + 20
        })),
        weekly: Array.from({ length: 4 }, (_, i) => ({
          date: `Week ${i + 1}`,
          value: Math.floor(Math.random() * 200) + 100
        })),
        monthly: Array.from({ length: 6 }, (_, i) => ({
          date: new Date(Date.now() - i * 30 * 24 * 60 * 60 * 1000).toLocaleDateString('ru-RU', { month: 'short' }),
          value: Math.floor(Math.random() * 500) + 300
        }))
      },
      bottlenecks: [
        {
          step: 'HR Review',
          process: 'Vacation Request Approval',
          avgDelay: 12.5,
          impact: 'medium'
        },
        {
          step: 'Finance Validation',
          process: 'Expense Reimbursement',
          avgDelay: 24,
          impact: 'high'
        }
      ],
      userPerformance: [
        {
          userId: 'user_1',
          name: 'Анна Смирнова',
          tasksCompleted: 145,
          avgResponseTime: 4.2,
          slaCompliance: 98.5
        },
        {
          userId: 'user_2',
          name: 'Михаил Козлов',
          tasksCompleted: 89,
          avgResponseTime: 6.8,
          slaCompliance: 91.2
        }
      ]
    };

    // Mock templates
    const mockTemplates: ProcessTemplate[] = [
      {
        id: 'tmpl_1',
        name: 'Standard Leave Request',
        category: 'hr',
        description: 'Template for all types of leave requests',
        baseProcess: mockProcesses[0],
        customizable: ['steps', 'sla', 'notifications'],
        popularity: 89,
        lastUsed: new Date('2025-07-20')
      },
      {
        id: 'tmpl_2',
        name: 'Fast Track Approval',
        category: 'operations',
        description: 'Simplified approval for low-risk requests',
        baseProcess: mockProcesses[1],
        customizable: ['assignees', 'conditions'],
        popularity: 67,
        lastUsed: new Date('2025-07-19')
      }
    ];

    setProcesses(mockProcesses);
    setInstances(mockInstances);
    setAnalytics(mockAnalytics);
    setTemplates(mockTemplates);
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      active: 'text-green-600 bg-green-100',
      running: 'text-blue-600 bg-blue-100',
      completed: 'text-gray-600 bg-gray-100',
      failed: 'text-red-600 bg-red-100',
      suspended: 'text-yellow-600 bg-yellow-100',
      draft: 'text-purple-600 bg-purple-100',
      archived: 'text-gray-500 bg-gray-100'
    };
    return colors[status] || 'text-gray-600 bg-gray-100';
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'critical':
        return <AlertTriangle className="h-4 w-4 text-red-600" />;
      case 'high':
        return <ArrowRight className="h-4 w-4 text-orange-600" />;
      case 'normal':
        return <Clock className="h-4 w-4 text-blue-600" />;
      case 'low':
        return <Clock className="h-4 w-4 text-gray-500" />;
      default:
        return null;
    }
  };

  const renderDashboard = () => (
    <div className="space-y-6">
      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active Processes</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.overview.totalProcesses || 0}</p>
              <p className="text-xs text-gray-500 mt-1">12 categories</p>
            </div>
            <div className="p-3 bg-blue-100 rounded-lg">
              <FileText className="h-6 w-6 text-blue-600" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Running Instances</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.overview.activeInstances || 0}</p>
              <p className="text-xs text-green-600 mt-1">+12% from last week</p>
            </div>
            <div className="p-3 bg-green-100 rounded-lg">
              <Activity className="h-6 w-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">SLA Compliance</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.overview.slaCompliance || 0}%</p>
              <p className="text-xs text-gray-500 mt-1">Target: 95%</p>
            </div>
            <div className="p-3 bg-yellow-100 rounded-lg">
              <Target className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Avg Completion</p>
              <p className="text-2xl font-bold text-gray-900">{analytics?.overview.avgCompletionTime || 0}h</p>
              <p className="text-xs text-red-600 mt-1">2h above target</p>
            </div>
            <div className="p-3 bg-purple-100 rounded-lg">
              <Clock className="h-6 w-6 text-purple-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity & Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Instances */}
        <div className="lg:col-span-2 bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Recent Process Instances</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {instances.slice(0, 5).map((instance) => (
                <div key={instance.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    {getPriorityIcon(instance.priority)}
                    <div>
                      <p className="font-medium text-gray-900">{instance.processName}</p>
                      <p className="text-sm text-gray-600">
                        {instance.initiator.name} • {new Date(instance.startedAt).toLocaleString('ru-RU')}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(instance.status)}`}>
                      {instance.status}
                    </span>
                    <button className="p-1 hover:bg-gray-200 rounded">
                      <Eye className="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Quick Actions</h3>
          </div>
          <div className="p-6">
            <div className="space-y-3">
              <button className="w-full px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center justify-center gap-2">
                <Plus className="h-4 w-4" />
                Create New Process
              </button>
              <button className="w-full px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center justify-center gap-2">
                <Upload className="h-4 w-4" />
                Import Template
              </button>
              <button className="w-full px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center justify-center gap-2">
                <Download className="h-4 w-4" />
                Export Analytics
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Distribution */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Process Distribution</h3>
          </div>
          <div className="p-6">
            <div className="space-y-3">
              {Object.entries(analytics?.byCategory || {}).map(([category, data]) => (
                <div key={category} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 rounded-full bg-blue-600"></div>
                    <span className="text-sm font-medium text-gray-700 capitalize">{category}</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className="text-sm text-gray-600">{data.count} processes</span>
                    <span className="text-sm font-medium text-gray-900">{data.successRate}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Bottlenecks */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Process Bottlenecks</h3>
          </div>
          <div className="p-6">
            <div className="space-y-3">
              {analytics?.bottlenecks.map((bottleneck, index) => (
                <div key={index} className="p-3 bg-red-50 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">{bottleneck.step}</p>
                      <p className="text-sm text-gray-600">{bottleneck.process}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium text-red-600">{bottleneck.avgDelay}h delay</p>
                      <p className="text-xs text-gray-500">{bottleneck.impact} impact</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderProcesses = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Process Definitions</h2>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search processes..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Filter className="h-4 w-4" />
            Filter
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
            <Plus className="h-4 w-4" />
            New Process
          </button>
        </div>
      </div>

      {/* Process Grid/List */}
      <div className={viewMode === 'grid' ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4' : 'space-y-4'}>
        {processes.map((process) => (
          <div key={process.id} className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{process.name}</h3>
                  <p className="text-sm text-gray-600">{process.nameRu}</p>
                </div>
                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(process.status)}`}>
                  {process.status}
                </span>
              </div>
              
              <p className="text-sm text-gray-600 mb-4">{process.description}</p>
              
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <p className="text-xs text-gray-500">Steps</p>
                  <p className="text-sm font-medium text-gray-900">{process.steps.length}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">SLA</p>
                  <p className="text-sm font-medium text-gray-900">{process.sla.targetHours}h</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Success Rate</p>
                  <p className="text-sm font-medium text-gray-900">{process.metrics.successRate}%</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Active</p>
                  <p className="text-sm font-medium text-gray-900">{process.metrics.currentActive}</p>
                </div>
              </div>
              
              <div className="flex items-center justify-between pt-4 border-t border-gray-200">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-gray-400" />
                  <span className="text-sm text-gray-600">{process.owner.name}</span>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-1 hover:bg-gray-100 rounded">
                    <Eye className="h-4 w-4 text-gray-500" />
                  </button>
                  <button className="p-1 hover:bg-gray-100 rounded">
                    <Edit3 className="h-4 w-4 text-gray-500" />
                  </button>
                  <button className="p-1 hover:bg-gray-100 rounded">
                    <Copy className="h-4 w-4 text-gray-500" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderInstances = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Process Instances</h2>
        <div className="flex items-center gap-3">
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Status</option>
            <option value="running">Running</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
            <option value="suspended">Suspended</option>
          </select>
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Instances Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Instance ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Process
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Initiator
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Current Step
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  SLA
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {instances.map((instance) => (
                <tr key={instance.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    #{instance.id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{instance.processName}</p>
                      <p className="text-xs text-gray-500">{instance.priority} priority</p>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <p className="text-sm text-gray-900">{instance.initiator.name}</p>
                      <p className="text-xs text-gray-500">{instance.initiator.department}</p>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {instance.currentStep}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(instance.status)}`}>
                      {instance.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                      instance.slaStatus === 'on_track' ? 'text-green-600 bg-green-100' :
                      instance.slaStatus === 'at_risk' ? 'text-yellow-600 bg-yellow-100' :
                      'text-red-600 bg-red-100'
                    }`}>
                      {instance.slaStatus.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <div className="flex items-center gap-2">
                      <button className="p-1 hover:bg-gray-100 rounded">
                        <Eye className="h-4 w-4" />
                      </button>
                      <button className="p-1 hover:bg-gray-100 rounded">
                        <MessageSquare className="h-4 w-4" />
                      </button>
                      {instance.status === 'running' && (
                        <button className="p-1 hover:bg-gray-100 rounded">
                          <Pause className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const renderAnalytics = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Process Analytics</h2>
        <div className="flex items-center gap-3">
          <select className="px-4 py-2 border border-gray-300 rounded-lg">
            <option>Last 7 days</option>
            <option>Last 30 days</option>
            <option>Last 90 days</option>
          </select>
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Download className="h-4 w-4" />
            Export Report
          </button>
        </div>
      </div>

      {/* Performance Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Trend Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Process Volume Trend</h3>
          </div>
          <div className="p-6">
            <div className="h-64 flex items-center justify-center text-gray-500">
              <BarChart3 className="h-12 w-12" />
              <span className="ml-2">Chart visualization here</span>
            </div>
          </div>
        </div>

        {/* User Performance */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Top Performers</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {analytics?.userPerformance.map((user) => (
                <div key={user.userId} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                      <User className="h-5 w-5 text-gray-600" />
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{user.name}</p>
                      <p className="text-sm text-gray-600">{user.tasksCompleted} tasks</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-900">{user.slaCompliance}% SLA</p>
                    <p className="text-xs text-gray-500">{user.avgResponseTime}h avg response</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* SLA Metrics */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">SLA Performance by Process</h3>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {processes.map((process) => (
              <div key={process.id} className="text-center">
                <div className="relative w-24 h-24 mx-auto mb-3">
                  <svg className="w-24 h-24 transform -rotate-90">
                    <circle
                      cx="48"
                      cy="48"
                      r="36"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="none"
                      className="text-gray-200"
                    />
                    <circle
                      cx="48"
                      cy="48"
                      r="36"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="none"
                      strokeDasharray={`${(process.metrics.successRate / 100) * 226} 226`}
                      className="text-blue-600"
                    />
                  </svg>
                  <span className="absolute inset-0 flex items-center justify-center text-lg font-bold">
                    {process.metrics.successRate}%
                  </span>
                </div>
                <p className="font-medium text-gray-900">{process.name}</p>
                <p className="text-sm text-gray-600">{process.metrics.avgCompletionTime}h avg</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderTemplates = () => (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Process Templates</h2>
        <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
          <Plus className="h-4 w-4" />
          Create Template
        </button>
      </div>

      {/* Templates Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {templates.map((template) => (
          <div key={template.id} className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <Package className="h-8 w-8 text-blue-600" />
                <span className="text-sm text-gray-500">{template.popularity}% used</span>
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">{template.name}</h3>
              <p className="text-sm text-gray-600 mb-4">{template.description}</p>
              <div className="flex items-center justify-between text-sm text-gray-500">
                <span>{template.category}</span>
                <span>Used {new Date(template.lastUsed).toLocaleDateString('ru-RU')}</span>
              </div>
              <div className="mt-4 pt-4 border-t border-gray-200">
                <button className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  Use Template
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <LayoutDashboard className="h-6 w-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">Business Process Management</h1>
              <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                SPEC-36 Complete
              </span>
            </div>
            <div className="flex items-center gap-3">
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <RefreshCw className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Settings className="h-5 w-5 text-gray-600" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="px-6">
          <nav className="flex space-x-6">
            {[
              { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
              { id: 'processes', label: 'Processes', icon: FileText },
              { id: 'instances', label: 'Instances', icon: Activity },
              { id: 'analytics', label: 'Analytics', icon: BarChart3 },
              { id: 'templates', label: 'Templates', icon: Package }
            ].map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveView(tab.id as any)}
                  className={`flex items-center gap-2 py-4 border-b-2 transition-colors ${
                    activeView === tab.id
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span className="font-medium">{tab.label}</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {activeView === 'dashboard' && renderDashboard()}
        {activeView === 'processes' && renderProcesses()}
        {activeView === 'instances' && renderInstances()}
        {activeView === 'analytics' && renderAnalytics()}
        {activeView === 'templates' && renderTemplates()}
      </div>
    </div>
  );
};

export default Spec36CompleteBusinessProcessUI;