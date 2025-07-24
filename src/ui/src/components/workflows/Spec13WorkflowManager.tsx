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
  Target,
  Users,
  AlertCircle
} from 'lucide-react';

// SPEC-13: Business Process Management Workflows
// Enhanced from ProcessWorkflowManager.tsx for manager approval workflows
// Focus: Vacation approval, overtime requests, shift exchanges with 20+ daily manager users

interface Spec13Workflow {
  id: string;
  type: 'vacation_approval' | 'overtime_request' | 'shift_exchange' | 'emergency_leave' | 'schedule_change';
  title: string;
  status: 'submitted' | 'manager_review' | 'hr_review' | 'approved' | 'rejected' | 'escalated';
  priority: 'normal' | 'urgent' | 'emergency';
  employee: {
    id: string;
    name: string;
    department: string;
    position: string;
    manager: string;
  };
  assignedTo?: {
    id: string;
    name: string;
    role: 'manager' | 'hr_admin' | 'department_head';
  };
  createdAt: Date;
  updatedAt: Date;
  dueDate?: Date;
  approvalChain: ApprovalStep[];
  businessRules: {
    requiredApprovals: string[]; // ['manager', 'hr_admin']
    autoApprovalConditions?: string[];
    escalationHours: number;
    slaCompliance: boolean;
  };
  requestDetails: {
    startDate?: string;
    endDate?: string;
    duration?: number;
    reason: string;
    coverageArrangement?: string;
    urgencyLevel: string;
  };
  analytics: {
    processingTime: number; // hours
    currentStepDuration: number;
    slaStatus: 'on_time' | 'at_risk' | 'overdue';
    bottleneckStage?: string;
  };
}

interface ApprovalStep {
  id: string;
  stage: string;
  approverRole: string;
  approverName?: string;
  status: 'pending' | 'in_progress' | 'approved' | 'rejected' | 'escalated';
  completedAt?: Date;
  comments?: string;
  slaHours: number;
  actualHours?: number;
  isParallel?: boolean; // for parallel approvals
}

interface WorkflowAnalytics {
  totalRequests: number;
  avgProcessingTime: number;
  approvalRates: {
    manager: number;
    hr: number;
    overall: number;
  };
  slaCompliance: number;
  bottlenecks: string[];
  escalatedCount: number;
}

const Spec13WorkflowManager: React.FC = () => {
  const [workflows, setWorkflows] = useState<Spec13Workflow[]>([]);
  const [filteredWorkflows, setFilteredWorkflows] = useState<Spec13Workflow[]>([]);
  const [analytics, setAnalytics] = useState<WorkflowAnalytics | null>(null);
  const [selectedWorkflow, setSelectedWorkflow] = useState<Spec13Workflow | null>(null);
  const [viewMode, setViewMode] = useState<'queue' | 'analytics' | 'designer'>('queue');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [filterType, setFilterType] = useState<string>('all');
  const [isLoading, setIsLoading] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  useEffect(() => {
    loadWorkflows();
    
    // Auto-refresh every 30 seconds for real-time workflow monitoring
    const refreshInterval = setInterval(() => {
      loadWorkflows();
    }, 30000);

    return () => clearInterval(refreshInterval);
  }, []);

  useEffect(() => {
    // Apply filters when workflows or filters change
    let filtered = workflows;
    
    if (filterStatus !== 'all') {
      filtered = filtered.filter(wf => wf.status === filterStatus);
    }
    
    if (filterType !== 'all') {
      filtered = filtered.filter(wf => wf.type === filterType);
    }
    
    setFilteredWorkflows(filtered);
  }, [workflows, filterStatus, filterType]);

  const loadWorkflows = async () => {
    setIsLoading(true);
    
    try {
      // In a real implementation, this would call SPEC-13 workflow APIs
      // For now, using demo data that matches SPEC-13 BDD scenarios
      const demoWorkflows = getDemoWorkflows();
      const demoAnalytics = getDemoAnalytics();
      
      setWorkflows(demoWorkflows);
      setAnalytics(demoAnalytics);
      setLastRefresh(new Date());
      
      console.log('[SPEC-13 WORKFLOWS] Loaded', demoWorkflows.length, 'workflows');
    } catch (error) {
      console.error('[SPEC-13 WORKFLOWS] Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getDemoWorkflows = (): Spec13Workflow[] => [
    {
      id: 'wf_001',
      type: 'vacation_approval',
      title: 'Vacation Request - John Doe (Aug 15-22)',
      status: 'manager_review',
      priority: 'normal',
      employee: {
        id: 'emp_001',
        name: 'John Doe',
        department: 'Customer Support',
        position: 'Senior Agent',
        manager: 'Sarah Manager'
      },
      assignedTo: {
        id: 'mgr_001',
        name: 'Sarah Manager',
        role: 'manager'
      },
      createdAt: new Date('2025-07-20T09:00:00'),
      updatedAt: new Date('2025-07-21T10:30:00'),
      dueDate: new Date('2025-07-24T17:00:00'),
      approvalChain: [
        {
          id: 'step_001',
          stage: 'Manager Review',
          approverRole: 'manager',
          approverName: 'Sarah Manager',
          status: 'in_progress',
          slaHours: 72,
          actualHours: 25.5,
          isParallel: false
        },
        {
          id: 'step_002',
          stage: 'HR Review',
          approverRole: 'hr_admin',
          status: 'pending',
          slaHours: 24,
          isParallel: false
        }
      ],
      businessRules: {
        requiredApprovals: ['manager', 'hr_admin'],
        escalationHours: 72,
        slaCompliance: true
      },
      requestDetails: {
        startDate: '2025-08-15',
        endDate: '2025-08-22',
        duration: 7,
        reason: 'Family vacation',
        coverageArrangement: 'Jane Smith (backup)',
        urgencyLevel: 'normal'
      },
      analytics: {
        processingTime: 25.5,
        currentStepDuration: 25.5,
        slaStatus: 'on_time',
        bottleneckStage: undefined
      }
    },
    {
      id: 'wf_002',
      type: 'overtime_request',
      title: 'Overtime Authorization - Mike Jones (Project Deadline)',
      status: 'manager_review',
      priority: 'urgent',
      employee: {
        id: 'emp_002',
        name: 'Mike Jones',
        department: 'Technical Support',
        position: 'Technical Lead',
        manager: 'Dave Smith'
      },
      assignedTo: {
        id: 'mgr_002',
        name: 'Dave Smith',
        role: 'manager'
      },
      createdAt: new Date('2025-07-21T14:00:00'),
      updatedAt: new Date('2025-07-21T14:00:00'),
      dueDate: new Date('2025-07-22T09:00:00'),
      approvalChain: [
        {
          id: 'step_001',
          stage: 'Manager Review',
          approverRole: 'manager',
          approverName: 'Dave Smith',
          status: 'in_progress',
          slaHours: 24,
          actualHours: 2.0,
          isParallel: false
        }
      ],
      businessRules: {
        requiredApprovals: ['manager'],
        autoApprovalConditions: ['under_10_hours', 'business_critical'],
        escalationHours: 24,
        slaCompliance: true
      },
      requestDetails: {
        duration: 8,
        reason: 'Critical project deadline - system deployment',
        urgencyLevel: 'urgent'
      },
      analytics: {
        processingTime: 2.0,
        currentStepDuration: 2.0,
        slaStatus: 'on_time'
      }
    },
    {
      id: 'wf_003',
      type: 'shift_exchange',
      title: 'Shift Exchange - Elena Volkova ↔ Alexey Morozov',
      status: 'approved',
      priority: 'normal',
      employee: {
        id: 'emp_003',
        name: 'Elena Volkova',
        department: 'Customer Support',
        position: 'Agent',
        manager: 'Sarah Manager'
      },
      assignedTo: {
        id: 'mgr_001',
        name: 'Sarah Manager',
        role: 'manager'
      },
      createdAt: new Date('2025-07-19T16:00:00'),
      updatedAt: new Date('2025-07-20T09:15:00'),
      dueDate: new Date('2025-07-22T17:00:00'),
      approvalChain: [
        {
          id: 'step_001',
          stage: 'Manager Review',
          approverRole: 'manager',
          approverName: 'Sarah Manager',
          status: 'approved',
          completedAt: new Date('2025-07-20T09:15:00'),
          slaHours: 48,
          actualHours: 17.25,
          comments: 'Approved - good coverage arrangement'
        }
      ],
      businessRules: {
        requiredApprovals: ['manager'],
        escalationHours: 48,
        slaCompliance: true
      },
      requestDetails: {
        reason: 'Medical appointment scheduling conflict',
        coverageArrangement: 'Mutual agreement with Alexey Morozov',
        urgencyLevel: 'normal'
      },
      analytics: {
        processingTime: 17.25,
        currentStepDuration: 0,
        slaStatus: 'on_time'
      }
    },
    {
      id: 'wf_004',
      type: 'vacation_approval',
      title: 'Emergency Leave - Anna Petrov (Family Emergency)',
      status: 'escalated',
      priority: 'emergency',
      employee: {
        id: 'emp_004',
        name: 'Anna Petrov',
        department: 'Sales',
        position: 'Sales Representative',
        manager: 'Pavel Orlov'
      },
      assignedTo: {
        id: 'dept_001',
        name: 'Department Head',
        role: 'department_head'
      },
      createdAt: new Date('2025-07-18T08:00:00'),
      updatedAt: new Date('2025-07-21T10:00:00'),
      dueDate: new Date('2025-07-19T17:00:00'),
      approvalChain: [
        {
          id: 'step_001',
          stage: 'Manager Review',
          approverRole: 'manager',
          approverName: 'Pavel Orlov',
          status: 'escalated',
          slaHours: 24,
          actualHours: 74,
          comments: 'Manager unavailable - auto-escalated'
        },
        {
          id: 'step_002',
          stage: 'Department Head Review',
          approverRole: 'department_head',
          status: 'in_progress',
          slaHours: 12,
          actualHours: 2,
          isParallel: false
        }
      ],
      businessRules: {
        requiredApprovals: ['manager', 'department_head'],
        escalationHours: 24,
        slaCompliance: false
      },
      requestDetails: {
        startDate: '2025-07-18',
        endDate: '2025-07-25',
        duration: 7,
        reason: 'Family medical emergency',
        urgencyLevel: 'emergency'
      },
      analytics: {
        processingTime: 74,
        currentStepDuration: 2,
        slaStatus: 'overdue',
        bottleneckStage: 'Manager Review'
      }
    }
  ];

  const getDemoAnalytics = (): WorkflowAnalytics => ({
    totalRequests: 156,
    avgProcessingTime: 2.5, // days
    approvalRates: {
      manager: 0.85,
      hr: 0.95,
      overall: 0.81
    },
    slaCompliance: 0.90,
    bottlenecks: ['Manager Review', 'Coverage Planning'],
    escalatedCount: 8
  });

  const handleApproval = async (workflowId: string, action: 'approve' | 'reject', comments?: string) => {
    const workflow = workflows.find(wf => wf.id === workflowId);
    if (!workflow) return;

    console.log(`[SPEC-13 WORKFLOW] ${action.toUpperCase()}:`, workflowId, comments);

    // Update workflow status based on action
    const updatedWorkflows = workflows.map(wf => {
      if (wf.id === workflowId) {
        const currentStep = wf.approvalChain.find(step => step.status === 'in_progress');
        if (currentStep) {
          currentStep.status = action === 'approve' ? 'approved' : 'rejected';
          currentStep.completedAt = new Date();
          currentStep.comments = comments;
        }

        // Determine next status
        let newStatus: Spec13Workflow['status'] = wf.status;
        if (action === 'reject') {
          newStatus = 'rejected';
        } else if (action === 'approve') {
          const nextPendingStep = wf.approvalChain.find(step => step.status === 'pending');
          if (nextPendingStep) {
            nextPendingStep.status = 'in_progress';
            newStatus = nextPendingStep.approverRole === 'hr_admin' ? 'hr_review' : 'manager_review';
          } else {
            newStatus = 'approved';
          }
        }

        return {
          ...wf,
          status: newStatus,
          updatedAt: new Date()
        };
      }
      return wf;
    });

    setWorkflows(updatedWorkflows);
  };

  const getStatusColor = (status: Spec13Workflow['status']) => {
    switch (status) {
      case 'approved': return 'text-green-600 bg-green-50';
      case 'rejected': return 'text-red-600 bg-red-50';
      case 'escalated': return 'text-orange-600 bg-orange-50';
      case 'manager_review': return 'text-blue-600 bg-blue-50';
      case 'hr_review': return 'text-purple-600 bg-purple-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getPriorityColor = (priority: Spec13Workflow['priority']) => {
    switch (priority) {
      case 'emergency': return 'text-red-700 bg-red-100 border-red-200';
      case 'urgent': return 'text-orange-700 bg-orange-100 border-orange-200';
      default: return 'text-gray-700 bg-gray-100 border-gray-200';
    }
  };

  const getSLAStatusColor = (slaStatus: string) => {
    switch (slaStatus) {
      case 'on_time': return 'text-green-600';
      case 'at_risk': return 'text-yellow-600';
      case 'overdue': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const renderWorkflowCard = (workflow: Spec13Workflow) => (
    <div key={workflow.id} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <h3 className="text-lg font-semibold text-gray-900">{workflow.title}</h3>
            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(workflow.priority)}`}>
              {workflow.priority.toUpperCase()}
            </span>
          </div>
          <div className="flex items-center gap-4 text-sm text-gray-600 mb-3">
            <div className="flex items-center gap-1">
              <User size={14} />
              <span>{workflow.employee.name} ({workflow.employee.department})</span>
            </div>
            <div className="flex items-center gap-1">
              <Calendar size={14} />
              <span>{workflow.createdAt.toLocaleDateString()}</span>
            </div>
          </div>
        </div>
        <div className="flex flex-col items-end gap-2">
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(workflow.status)}`}>
            {workflow.status.replace('_', ' ').toUpperCase()}
          </span>
          <div className={`text-sm font-medium ${getSLAStatusColor(workflow.analytics.slaStatus)}`}>
            SLA: {workflow.analytics.slaStatus.replace('_', ' ').toUpperCase()}
          </div>
        </div>
      </div>

      {/* Request Details */}
      <div className="bg-gray-50 p-3 rounded mb-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
          <div><strong>Type:</strong> {workflow.type.replace('_', ' ')}</div>
          <div><strong>Duration:</strong> {workflow.requestDetails.duration || 'N/A'} days</div>
          <div><strong>Reason:</strong> {workflow.requestDetails.reason}</div>
          {workflow.requestDetails.coverageArrangement && (
            <div><strong>Coverage:</strong> {workflow.requestDetails.coverageArrangement}</div>
          )}
        </div>
      </div>

      {/* Approval Chain Progress */}
      <div className="mb-4">
        <div className="text-sm font-medium text-gray-700 mb-2">Approval Progress</div>
        <div className="flex items-center gap-2">
          {workflow.approvalChain.map((step, index) => (
            <div key={step.id} className="flex items-center">
              <div className={`flex items-center gap-2 px-3 py-1 rounded text-sm ${
                step.status === 'approved' ? 'bg-green-100 text-green-700' :
                step.status === 'rejected' ? 'bg-red-100 text-red-700' :
                step.status === 'in_progress' ? 'bg-blue-100 text-blue-700' :
                step.status === 'escalated' ? 'bg-orange-100 text-orange-700' :
                'bg-gray-100 text-gray-500'
              }`}>
                {step.status === 'approved' ? <CheckCircle size={14} /> :
                 step.status === 'rejected' ? <XCircle size={14} /> :
                 step.status === 'escalated' ? <AlertTriangle size={14} /> :
                 step.status === 'in_progress' ? <Clock size={14} /> :
                 <div className="w-3 h-3 rounded-full border-2 border-gray-400"></div>
                }
                <span>{step.stage}</span>
                {step.actualHours && (
                  <span className="text-xs">({step.actualHours}h)</span>
                )}
              </div>
              {index < workflow.approvalChain.length - 1 && (
                <ArrowRight size={14} className="text-gray-400 mx-1" />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setSelectedWorkflow(workflow)}
            className="flex items-center gap-1 px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded transition-colors"
          >
            <Eye size={14} />
            View Details
          </button>
        </div>
        
        {(workflow.status === 'manager_review' || workflow.status === 'hr_review') && (
          <div className="flex items-center gap-2">
            <button
              onClick={() => handleApproval(workflow.id, 'reject', 'Declined by manager')}
              className="flex items-center gap-1 px-3 py-1 text-sm text-white bg-red-600 hover:bg-red-700 rounded transition-colors"
            >
              <XCircle size={14} />
              Reject
            </button>
            <button
              onClick={() => handleApproval(workflow.id, 'approve', 'Approved by manager')}
              className="flex items-center gap-1 px-3 py-1 text-sm text-white bg-green-600 hover:bg-green-700 rounded transition-colors"
            >
              <CheckCircle size={14} />
              Approve
            </button>
          </div>
        )}
      </div>
    </div>
  );

  const renderAnalytics = () => {
    if (!analytics) return null;

    return (
      <div className="space-y-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Requests</p>
                <p className="text-2xl font-bold text-gray-900">{analytics.totalRequests}</p>
              </div>
              <FileText className="h-8 w-8 text-blue-600" />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Avg Processing Time</p>
                <p className="text-2xl font-bold text-gray-900">{analytics.avgProcessingTime} days</p>
              </div>
              <Clock className="h-8 w-8 text-green-600" />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">SLA Compliance</p>
                <p className="text-2xl font-bold text-gray-900">{Math.round(analytics.slaCompliance * 100)}%</p>
              </div>
              <Target className="h-8 w-8 text-purple-600" />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Escalated</p>
                <p className="text-2xl font-bold text-gray-900">{analytics.escalatedCount}</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-orange-600" />
            </div>
          </div>
        </div>

        {/* Approval Rates */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Approval Rates by Stage</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between items-center mb-1">
                <span className="text-sm font-medium text-gray-700">Manager Approval</span>
                <span className="text-sm text-gray-600">{Math.round(analytics.approvalRates.manager * 100)}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-blue-600 h-2 rounded-full" style={{width: `${analytics.approvalRates.manager * 100}%`}}></div>
              </div>
            </div>
            
            <div>
              <div className="flex justify-between items-center mb-1">
                <span className="text-sm font-medium text-gray-700">HR Approval</span>
                <span className="text-sm text-gray-600">{Math.round(analytics.approvalRates.hr * 100)}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-green-600 h-2 rounded-full" style={{width: `${analytics.approvalRates.hr * 100}%`}}></div>
              </div>
            </div>
            
            <div>
              <div className="flex justify-between items-center mb-1">
                <span className="text-sm font-medium text-gray-700">Overall Success Rate</span>
                <span className="text-sm text-gray-600">{Math.round(analytics.approvalRates.overall * 100)}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-purple-600 h-2 rounded-full" style={{width: `${analytics.approvalRates.overall * 100}%`}}></div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottlenecks */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Process Bottlenecks</h3>
          <div className="space-y-2">
            {analytics.bottlenecks.map((bottleneck, index) => (
              <div key={index} className="flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-yellow-600" />
                <span className="text-sm text-gray-700">{bottleneck} stage experiencing delays</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Business Process Workflows</h1>
              <p className="text-gray-600 mt-1">SPEC-13: Manager approval workflows for vacation, overtime, and shift exchanges</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-sm text-gray-500">
                Last refresh: {lastRefresh.toLocaleTimeString()}
              </div>
              <button
                onClick={loadWorkflows}
                disabled={isLoading}
                className="flex items-center gap-2 px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                <RefreshCw size={14} className={isLoading ? 'animate-spin' : ''} />
                {isLoading ? 'Refreshing...' : 'Refresh'}
              </button>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="mb-6">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setViewMode('queue')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  viewMode === 'queue'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <Users size={16} />
                  Approval Queue ({filteredWorkflows.length})
                </div>
              </button>
              <button
                onClick={() => setViewMode('analytics')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  viewMode === 'analytics'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <Target size={16} />
                  Analytics & SLA
                </div>
              </button>
            </nav>
          </div>
        </div>

        {viewMode === 'queue' && (
          <>
            {/* Filters */}
            <div className="mb-6">
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <Filter size={16} className="text-gray-600" />
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="px-3 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">All Statuses</option>
                    <option value="manager_review">Manager Review</option>
                    <option value="hr_review">HR Review</option>
                    <option value="escalated">Escalated</option>
                    <option value="approved">Approved</option>
                    <option value="rejected">Rejected</option>
                  </select>
                </div>
                
                <div className="flex items-center gap-2">
                  <select
                    value={filterType}
                    onChange={(e) => setFilterType(e.target.value)}
                    className="px-3 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">All Types</option>
                    <option value="vacation_approval">Vacation Approval</option>
                    <option value="overtime_request">Overtime Request</option>
                    <option value="shift_exchange">Shift Exchange</option>
                    <option value="emergency_leave">Emergency Leave</option>
                  </select>
                </div>
                
                <div className="text-sm text-gray-600">
                  Showing {filteredWorkflows.length} of {workflows.length} workflows
                </div>
              </div>
            </div>

            {/* Workflows Grid */}
            <div className="space-y-4">
              {filteredWorkflows.map(renderWorkflowCard)}
            </div>

            {filteredWorkflows.length === 0 && (
              <div className="text-center py-12">
                <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600">No workflows match your current filters</p>
              </div>
            )}
          </>
        )}

        {viewMode === 'analytics' && renderAnalytics()}

        {/* Selected Workflow Details Modal would go here */}
        {selectedWorkflow && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[80vh] overflow-y-auto">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold text-gray-900">Workflow Details</h2>
                <button
                  onClick={() => setSelectedWorkflow(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <XCircle size={24} />
                </button>
              </div>
              
              <div className="space-y-4">
                <div><strong>Title:</strong> {selectedWorkflow.title}</div>
                <div><strong>Employee:</strong> {selectedWorkflow.employee.name} ({selectedWorkflow.employee.department})</div>
                <div><strong>Status:</strong> <span className={`px-2 py-1 rounded text-sm ${getStatusColor(selectedWorkflow.status)}`}>{selectedWorkflow.status}</span></div>
                <div><strong>Created:</strong> {selectedWorkflow.createdAt.toLocaleString()}</div>
                <div><strong>Reason:</strong> {selectedWorkflow.requestDetails.reason}</div>
                
                <div>
                  <strong>Approval Chain:</strong>
                  <div className="mt-2 space-y-2">
                    {selectedWorkflow.approvalChain.map(step => (
                      <div key={step.id} className="border border-gray-200 rounded p-3">
                        <div className="flex items-center justify-between mb-2">
                          <span className="font-medium">{step.stage}</span>
                          <span className={`px-2 py-1 rounded text-sm ${
                            step.status === 'approved' ? 'bg-green-100 text-green-700' :
                            step.status === 'rejected' ? 'bg-red-100 text-red-700' :
                            step.status === 'in_progress' ? 'bg-blue-100 text-blue-700' :
                            step.status === 'escalated' ? 'bg-orange-100 text-orange-700' :
                            'bg-gray-100 text-gray-600'
                          }`}>{step.status}</span>
                        </div>
                        <div className="text-sm text-gray-600">
                          <div>Approver: {step.approverName || step.approverRole}</div>
                          <div>SLA: {step.slaHours}h (Actual: {step.actualHours || 0}h)</div>
                          {step.comments && <div>Comments: {step.comments}</div>}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec13WorkflowManager;