import React, { useState, useEffect } from 'react';
import { CheckSquare, Square } from 'lucide-react';
import ApprovalDialog from './ApprovalDialog';

interface ApprovalQueueProps {
  managerId: number;
}

interface Request {
  id: string;
  type: 'time_off' | 'shift_change' | 'overtime' | 'vacation' | 'sick_leave';
  title: string;
  status: 'pending_approval'; // Manager only sees pending requests
  priority: 'low' | 'normal' | 'high' | 'urgent';
  startDate: Date;
  endDate?: Date;
  reason: string;
  submittedAt: Date;
  employeeName: string; // Added for manager view
  employeeId: string; // Added for manager view
  team?: string; // Added for manager view
  daysRequested?: number;
  actionRequired?: boolean;
  coverageImpact?: 'low' | 'medium' | 'high'; // Added for manager view
}

interface RequestFilters {
  type?: string;
  priority?: string;
  dateRange?: 'all' | 'today' | 'this_week' | 'this_month';
  search?: string;
}

const ApprovalQueue: React.FC<ApprovalQueueProps> = ({ managerId }) => {
  const [requests, setRequests] = useState<Request[]>([]);
  const [filteredRequests, setFilteredRequests] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<RequestFilters>({});
  const [sortBy, setSortBy] = useState<'date' | 'priority' | 'employee'>('priority');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  
  // Bulk selection state (copied from EmployeeStatusManager.tsx)
  const [selectedRequests, setSelectedRequests] = useState<string[]>([]);
  const [bulkActionMode, setBulkActionMode] = useState(false);
  
  // Approval dialog state
  const [showApprovalDialog, setShowApprovalDialog] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<Request | undefined>();

  // Load pending requests using I's verified manager endpoint
  useEffect(() => {
    const loadRequests = async () => {
      setLoading(true);
      
      try {
        // Use I's verified manager pending approvals endpoint
        const authToken = localStorage.getItem('authToken');
        console.log(`[APPROVAL QUEUE] Calling I's verified endpoint: /api/v1/managers/${managerId}/pending-approvals`);
        
        const response = await fetch(`http://localhost:8001/api/v1/managers/${managerId}/pending-approvals`, {
          headers: {
            'Authorization': `Bearer ${authToken}`,
            'Content-Type': 'application/json'
          }
        });

        if (response.ok) {
          const rawData = await response.json();
          console.log('✅ I-VERIFIED pending approvals loaded:', rawData);
          
          // Parse I's response into component format
          const parsedRequests: Request[] = rawData.pending_requests?.map((req: any) => ({
            id: req.id || req.request_id,
            type: req.type || 'vacation',
            title: req.title || `${req.type} Request`,
            status: 'pending_approval',
            priority: req.priority || 'normal',
            startDate: new Date(req.start_date || req.date),
            endDate: req.end_date ? new Date(req.end_date) : undefined,
            reason: req.reason || req.description || '',
            submittedAt: new Date(req.submitted_at || req.created_at || Date.now()),
            employeeName: req.employee_name || req.employee?.name || 'Unknown Employee',
            employeeId: req.employee_id || req.employee?.id || '0',
            team: req.team_name || req.team || 'Unknown Team',
            daysRequested: req.days_requested || 1,
            coverageImpact: req.coverage_impact || 'medium',
            actionRequired: req.action_required || false
          })) || [];
          
          setRequests(parsedRequests);
        } else {
          console.error(`❌ Manager pending approvals API error: ${response.status}`);
          // Fallback to demo data for development
          const mockRequests: Request[] = [
          {
            id: '1',
            type: 'vacation',
            title: 'Summer Vacation',
            status: 'pending_approval',
            priority: 'normal',
            startDate: new Date('2025-08-01'),
            endDate: new Date('2025-08-14'),
            reason: 'Annual vacation with family',
            submittedAt: new Date('2025-07-15'),
            employeeName: 'John Smith',
            employeeId: '101',
            team: 'Customer Service',
            daysRequested: 10,
            coverageImpact: 'medium',
            actionRequired: false
          },
          {
            id: '2',
            type: 'sick_leave',
            title: 'Medical Leave',
            status: 'pending_approval',
            priority: 'urgent',
            startDate: new Date('2025-07-20'),
            endDate: new Date('2025-07-22'),
            reason: 'Emergency medical procedure',
            submittedAt: new Date('2025-07-19'),
            employeeName: 'Sarah Johnson',
            employeeId: '102',
            team: 'Customer Service',
            daysRequested: 3,
            coverageImpact: 'high',
            actionRequired: true
          },
          {
            id: '3',
            type: 'shift_change',
            title: 'Shift Swap Request',
            status: 'pending_approval',
            priority: 'normal',
            startDate: new Date('2025-07-25'),
            reason: 'Personal appointment',
            submittedAt: new Date('2025-07-17'),
            employeeName: 'Michael Chen',
            employeeId: '103',
            team: 'Customer Service',
            daysRequested: 1,
            coverageImpact: 'low',
            actionRequired: false
          },
          {
            id: '4',
            type: 'overtime',
            title: 'Weekend Overtime',
            status: 'pending_approval',
            priority: 'high',
            startDate: new Date('2025-07-22'),
            endDate: new Date('2025-07-23'),
            reason: 'Project deadline coverage',
            submittedAt: new Date('2025-07-18'),
            employeeName: 'Emily Davis',
            employeeId: '104',
            team: 'Customer Service',
            daysRequested: 2,
            coverageImpact: 'low',
            actionRequired: false
          },
          {
            id: '5',
            type: 'time_off',
            title: 'Personal Day',
            status: 'pending_approval',
            priority: 'low',
            startDate: new Date('2025-07-30'),
            reason: 'Family event',
            submittedAt: new Date('2025-07-16'),
            employeeName: 'Robert Wilson',
            employeeId: '105',
            team: 'Customer Service',
            daysRequested: 1,
            coverageImpact: 'low',
            actionRequired: false
          }
        ];
        
        setRequests(mockRequests);
      } catch (error) {
        console.error('Failed to load approval requests:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadRequests();
  }, [managerId]);

  // Filter and sort requests (copied from RequestList.tsx)
  useEffect(() => {
    let filtered = [...requests];
    
    // Apply filters
    if (filters.type) {
      filtered = filtered.filter(r => r.type === filters.type);
    }
    
    if (filters.priority) {
      filtered = filtered.filter(r => r.priority === filters.priority);
    }
    
    if (filters.search) {
      const search = filters.search.toLowerCase();
      filtered = filtered.filter(r => 
        r.title.toLowerCase().includes(search) ||
        r.reason.toLowerCase().includes(search) ||
        r.employeeName.toLowerCase().includes(search) // Added employee name search
      );
    }
    
    // Date range filtering
    if (filters.dateRange && filters.dateRange !== 'all') {
      const today = new Date();
      const startOfToday = new Date(today);
      startOfToday.setHours(0, 0, 0, 0);
      
      switch (filters.dateRange) {
        case 'today':
          filtered = filtered.filter(r => {
            const reqDate = new Date(r.startDate);
            return reqDate.toDateString() === today.toDateString();
          });
          break;
        case 'this_week':
          const startOfWeek = new Date(today);
          startOfWeek.setDate(today.getDate() - today.getDay());
          const endOfWeek = new Date(startOfWeek);
          endOfWeek.setDate(startOfWeek.getDate() + 6);
          filtered = filtered.filter(r => {
            const reqDate = new Date(r.startDate);
            return reqDate >= startOfWeek && reqDate <= endOfWeek;
          });
          break;
        case 'this_month':
          const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
          const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
          filtered = filtered.filter(r => {
            const reqDate = new Date(r.startDate);
            return reqDate >= startOfMonth && reqDate <= endOfMonth;
          });
          break;
      }
    }
    
    // Sorting (modified for manager view)
    filtered.sort((a, b) => {
      let comparison = 0;
      
      switch (sortBy) {
        case 'date':
          comparison = a.submittedAt.getTime() - b.submittedAt.getTime();
          break;
        case 'priority':
          const priorityOrder = { urgent: 0, high: 1, normal: 2, low: 3 };
          comparison = priorityOrder[a.priority as keyof typeof priorityOrder] - 
                      priorityOrder[b.priority as keyof typeof priorityOrder];
          break;
        case 'employee':
          comparison = a.employeeName.localeCompare(b.employeeName);
          break;
      }
      
      return sortOrder === 'desc' ? -comparison : comparison;
    });
    
    setFilteredRequests(filtered);
  }, [requests, filters, sortBy, sortOrder]);

  // Utility functions (copied from RequestList.tsx)
  const getStatusColor = (status: Request['status']) => {
    return 'bg-yellow-100 text-yellow-800'; // Only pending approval for managers
  };

  const getStatusText = (status: Request['status']) => {
    return 'Pending Approval';
  };

  const getTypeText = (type: Request['type']) => {
    const types = {
      time_off: 'Time Off',
      shift_change: 'Shift Change',
      overtime: 'Overtime',
      vacation: 'Vacation',
      sick_leave: 'Sick Leave'
    };
    return types[type];
  };

  const getTypeIcon = (type: Request['type']) => {
    const icons = {
      time_off: '🕐',
      shift_change: '🔄',
      overtime: '⏰',
      vacation: '🏖️',
      sick_leave: '🏥'
    };
    return icons[type];
  };

  const getPriorityColor = (priority: Request['priority']) => {
    const colors = {
      low: 'border-gray-300 bg-white',
      normal: 'border-blue-300 bg-blue-50',
      high: 'border-orange-300 bg-orange-50',
      urgent: 'border-red-400 bg-red-50'
    };
    return colors[priority];
  };

  const getCoverageImpactColor = (impact?: string) => {
    const colors = {
      low: 'text-green-600',
      medium: 'text-yellow-600',
      high: 'text-red-600'
    };
    return colors[impact as keyof typeof colors] || 'text-gray-600';
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const formatDateRange = (start: Date, end?: Date) => {
    if (!end) return formatDate(start);
    return `${formatDate(start)} - ${formatDate(end)}`;
  };

  // Manager-specific actions
  const handleApprove = async (requestId: string, notes: string) => {
    try {
      // TODO: API call to approve request
      console.log(`Request ${requestId} approved with notes: ${notes}`);
      setRequests(prev => prev.filter(r => r.id !== requestId));
      setSelectedRequests(prev => prev.filter(id => id !== requestId));
    } catch (error) {
      console.error('Failed to approve request:', error);
    }
  };

  const handleReject = async (requestId: string, reason: string) => {
    try {
      // TODO: API call to reject request
      console.log(`Request ${requestId} rejected with reason: ${reason}`);
      setRequests(prev => prev.filter(r => r.id !== requestId));
      setSelectedRequests(prev => prev.filter(id => id !== requestId));
    } catch (error) {
      console.error('Failed to reject request:', error);
    }
  };

  // Bulk selection functions (copied from EmployeeStatusManager.tsx)
  const handleSelectRequest = (requestId: string) => {
    setSelectedRequests(prev =>
      prev.includes(requestId)
        ? prev.filter(id => id !== requestId)
        : [...prev, requestId]
    );
  };

  const handleSelectAll = () => {
    if (selectedRequests.length === filteredRequests.length) {
      setSelectedRequests([]);
    } else {
      setSelectedRequests(filteredRequests.map(r => r.id));
    }
  };

  const handleBulkApprove = async () => {
    if (selectedRequests.length === 0) return;
    
    try {
      console.log(`Bulk approved ${selectedRequests.length} requests`);
      setRequests(prev => prev.filter(r => !selectedRequests.includes(r.id)));
      setSelectedRequests([]);
      setBulkActionMode(false);
    } catch (error) {
      console.error('Failed to bulk approve requests:', error);
    }
  };

  const handleReviewRequest = (request: Request) => {
    const fullRequest = {
      ...request,
      employeeName: request.employeeName,
      employeeId: request.employeeId
    };
    setSelectedRequest(fullRequest);
    setShowApprovalDialog(true);
  };

  return (
    <div className="bg-white rounded-lg shadow-sm">
      {/* Header (modified from RequestList.tsx) */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          <div>
            <h2 className="text-2xl font-semibold text-gray-900">Approval Queue</h2>
            <p className="text-sm text-gray-500 mt-1">
              Review and approve team requests
            </p>
          </div>
          
          {/* Bulk Actions Toggle (copied from EmployeeStatusManager.tsx) */}
          <div className="flex items-center gap-3">
            <button
              onClick={() => setBulkActionMode(!bulkActionMode)}
              className={`px-4 py-2 rounded-lg transition-colors flex items-center gap-2 ${
                bulkActionMode
                  ? 'bg-blue-600 text-white hover:bg-blue-700'
                  : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              {bulkActionMode ? <CheckSquare className="h-4 w-4" /> : <Square className="h-4 w-4" />}
              Bulk Actions
            </button>
            
            {bulkActionMode && selectedRequests.length > 0 && (
              <button
                onClick={handleBulkApprove}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                Approve Selected ({selectedRequests.length})
              </button>
            )}
          </div>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
          <div className="bg-yellow-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-yellow-600">{requests.length}</div>
            <div className="text-sm text-yellow-800">Total Pending</div>
          </div>
          <div className="bg-red-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-red-600">
              {requests.filter(r => r.priority === 'urgent').length}
            </div>
            <div className="text-sm text-red-800">Urgent</div>
          </div>
          <div className="bg-orange-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-orange-600">
              {requests.filter(r => r.coverageImpact === 'high').length}
            </div>
            <div className="text-sm text-orange-800">High Impact</div>
          </div>
          <div className="bg-blue-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-blue-600">
              {requests.filter(r => {
                const today = new Date();
                const weekEnd = new Date(today);
                weekEnd.setDate(today.getDate() + 7);
                return new Date(r.startDate) <= weekEnd;
              }).length}
            </div>
            <div className="text-sm text-blue-800">Starting Soon</div>
          </div>
        </div>
      </div>

      {/* Filters and Search (modified from RequestList.tsx) */}
      <div className="p-6 border-b border-gray-200 bg-gray-50">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search by employee name, title, or reason..."
              value={filters.search || ''}
              onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          
          {/* Type Filter */}
          <select
            value={filters.type || ''}
            onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value || undefined }))}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Types</option>
            <option value="vacation">Vacation</option>
            <option value="sick_leave">Sick Leave</option>
            <option value="time_off">Time Off</option>
            <option value="shift_change">Shift Change</option>
            <option value="overtime">Overtime</option>
          </select>
          
          {/* Priority Filter */}
          <select
            value={filters.priority || ''}
            onChange={(e) => setFilters(prev => ({ ...prev, priority: e.target.value || undefined }))}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Priorities</option>
            <option value="urgent">Urgent</option>
            <option value="high">High</option>
            <option value="normal">Normal</option>
            <option value="low">Low</option>
          </select>
          
          {/* Date Range Filter */}
          <select
            value={filters.dateRange || 'all'}
            onChange={(e) => setFilters(prev => ({ ...prev, dateRange: e.target.value as any }))}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Dates</option>
            <option value="today">Starting Today</option>
            <option value="this_week">This Week</option>
            <option value="this_month">This Month</option>
          </select>
          
          {/* Sort */}
          <select
            value={`${sortBy}-${sortOrder}`}
            onChange={(e) => {
              const [sort, order] = e.target.value.split('-');
              setSortBy(sort as 'date' | 'priority' | 'employee');
              setSortOrder(order as 'asc' | 'desc');
            }}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="priority-asc">Priority (Urgent First)</option>
            <option value="date-desc">Date (Newest)</option>
            <option value="date-asc">Date (Oldest)</option>
            <option value="employee-asc">Employee (A-Z)</option>
          </select>
        </div>
      </div>

      {/* Request List (modified from RequestList.tsx) */}
      <div className="p-6">
        {loading ? (
          <div className="space-y-4">
            {[1, 2, 3].map(i => (
              <div key={i} className="animate-pulse border border-gray-200 rounded-lg p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="h-4 bg-gray-200 rounded w-1/3 mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-2/3 mb-3"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                  <div className="h-6 bg-gray-200 rounded w-20"></div>
                </div>
              </div>
            ))}
          </div>
        ) : filteredRequests.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-4">✅</div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Pending Requests</h3>
            <p className="text-gray-500">
              All requests have been reviewed
            </p>
          </div>
        ) : (
          <>
            {/* Bulk Selection Header */}
            {bulkActionMode && (
              <div className="flex items-center gap-2 p-2 bg-blue-50 rounded-lg mb-4">
                <button
                  onClick={handleSelectAll}
                  className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                >
                  {selectedRequests.length === filteredRequests.length ? 'Deselect All' : 'Select All'}
                </button>
                <span className="text-sm text-blue-600">
                  ({selectedRequests.length} of {filteredRequests.length} selected)
                </span>
              </div>
            )}
            
            <div className="space-y-4">
              {filteredRequests.map((request) => {
                const isSelected = selectedRequests.includes(request.id);
                
                return (
                  <div
                    key={request.id}
                    className={`border rounded-lg p-4 hover:shadow-sm transition-all ${
                      getPriorityColor(request.priority)
                    } ${request.actionRequired ? 'ring-2 ring-orange-400' : ''} ${
                      isSelected ? 'ring-2 ring-blue-500' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-3 flex-1">
                        {/* Bulk Selection Checkbox */}
                        {bulkActionMode && (
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => handleSelectRequest(request.id)}
                            className="mt-1 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          />
                        )}
                        
                        <div className="flex-1">
                          <div className="flex items-center gap-3 mb-2">
                            <span className="text-xl">{getTypeIcon(request.type)}</span>
                            <h3 className="font-medium text-gray-900">{request.title}</h3>
                            <span className={`px-2 py-1 text-xs font-medium rounded-full uppercase ${
                              request.priority === 'urgent' ? 'bg-red-100 text-red-800' :
                              request.priority === 'high' ? 'bg-orange-100 text-orange-800' :
                              request.priority === 'normal' ? 'bg-blue-100 text-blue-800' :
                              'bg-gray-100 text-gray-800'
                            }`}>
                              {request.priority}
                            </span>
                            {request.coverageImpact && (
                              <span className={`text-xs font-medium ${getCoverageImpactColor(request.coverageImpact)}`}>
                                {request.coverageImpact} impact
                              </span>
                            )}
                            {request.actionRequired && (
                              <span className="px-2 py-1 text-xs font-medium bg-orange-100 text-orange-800 rounded-full">
                                Action Required
                              </span>
                            )}
                          </div>
                          
                          <div className="text-sm text-gray-600 mb-3 grid grid-cols-1 md:grid-cols-2 gap-2">
                            <div>
                              <strong>Employee:</strong> {request.employeeName} • {request.team}
                            </div>
                            <div>
                              <strong>Period:</strong> {formatDateRange(request.startDate, request.endDate)}
                            </div>
                            <div>
                              <strong>Days:</strong> {request.daysRequested}
                            </div>
                            <div>
                              <strong>Submitted:</strong> {formatDate(request.submittedAt)}
                            </div>
                          </div>
                          
                          <div className="text-sm text-gray-700">
                            <strong>Reason:</strong> {request.reason}
                          </div>
                        </div>
                      </div>
                      
                      {/* Action Buttons */}
                      {!bulkActionMode && (
                        <div className="flex items-center gap-2 ml-4">
                          <button
                            onClick={() => handleReviewRequest(request)}
                            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                          >
                            Review
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>

      {/* Approval Dialog */}
      {showApprovalDialog && selectedRequest && (
        <ApprovalDialog
          request={selectedRequest as any}
          isOpen={showApprovalDialog}
          onClose={() => {
            setShowApprovalDialog(false);
            setSelectedRequest(undefined);
          }}
          onApprove={handleApprove}
          onReject={handleReject}
        />
      )}
    </div>
  );
};

export default ApprovalQueue;