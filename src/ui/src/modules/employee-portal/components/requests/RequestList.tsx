import React, { useState, useEffect } from 'react';

interface RequestListProps {
  employeeId: string;
  onNewRequest?: () => void;
  onEditRequest?: (request: Request) => void;
  onViewRequest?: (request: Request) => void;
}

interface Request {
  id: string;
  type: 'time_off' | 'shift_change' | 'overtime' | 'vacation' | 'sick_leave';
  title: string;
  status: 'draft' | 'submitted' | 'pending_approval' | 'approved' | 'rejected' | 'cancelled';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  startDate: Date;
  endDate?: Date;
  reason: string;
  submittedAt: Date;
  approver?: {
    name: string;
    comments?: string;
  };
  daysRequested?: number;
  actionRequired?: boolean;
}

interface RequestFilters {
  status?: string;
  type?: string;
  dateRange?: 'all' | 'last_month' | 'last_3_months' | 'this_year';
  search?: string;
}

const RequestList: React.FC<RequestListProps> = ({ 
  employeeId, 
  onNewRequest, 
  onEditRequest, 
  onViewRequest 
}) => {
  const [requests, setRequests] = useState<Request[]>([]);
  const [filteredRequests, setFilteredRequests] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'active' | 'pending' | 'history'>('active');
  const [filters, setFilters] = useState<RequestFilters>({});
  const [sortBy, setSortBy] = useState<'date' | 'type' | 'status'>('date');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Mock data
  useEffect(() => {
    const loadRequests = async () => {
      setLoading(true);
      
      await new Promise(resolve => setTimeout(resolve, 800));
      
      const mockRequests: Request[] = [
        {
          id: '1',
          type: 'vacation',
          title: 'Vacation - Family Emergency',
          status: 'pending_approval',
          priority: 'normal',
          startDate: new Date('2025-07-15'),
          endDate: new Date('2025-07-19'),
          reason: 'Family emergency, need to attend important family event',
          submittedAt: new Date('2025-06-01'),
          daysRequested: 5,
          actionRequired: false
        },
        {
          id: '2',
          type: 'shift_change',
          title: 'Shift Change - June 10th',
          status: 'approved',
          priority: 'normal',
          startDate: new Date('2025-06-10'),
          reason: 'Medical appointment, cannot reschedule',
          submittedAt: new Date('2025-05-25'),
          approver: {
            name: 'Sarah Johnson',
            comments: 'Approved. Shift changed from morning to evening.'
          }
        },
        {
          id: '3',
          type: 'sick_leave',
          title: 'Sick Leave - Medical Certificate',
          status: 'submitted',
          priority: 'high',
          startDate: new Date('2025-06-03'),
          endDate: new Date('2025-06-05'),
          reason: 'Flu symptoms, medical certificate attached',
          submittedAt: new Date('2025-06-03'),
          daysRequested: 3,
          actionRequired: true
        },
        {
          id: '4',
          type: 'overtime',
          title: 'Overtime Work - May 15th',
          status: 'rejected',
          priority: 'low',
          startDate: new Date('2025-05-15'),
          reason: 'Need to cover colleague shift',
          submittedAt: new Date('2025-05-10'),
          approver: {
            name: 'Michael Chen',
            comments: 'Rejected. Monthly overtime limit exceeded.'
          }
        },
        {
          id: '5',
          type: 'time_off',
          title: 'Compensatory Time Off',
          status: 'draft',
          priority: 'normal',
          startDate: new Date('2025-06-20'),
          reason: 'Compensation for overtime work in May',
          submittedAt: new Date('2025-06-01'),
          actionRequired: true
        },
        {
          id: '6',
          type: 'vacation',
          title: 'Summer Vacation',
          status: 'approved',
          priority: 'normal',
          startDate: new Date('2025-08-01'),
          endDate: new Date('2025-08-14'),
          reason: 'Annual vacation with family',
          submittedAt: new Date('2025-05-15'),
          daysRequested: 10,
          approver: {
            name: 'Lisa Rodriguez',
            comments: 'Approved. Enjoy your vacation!'
          }
        }
      ];
      
      setRequests(mockRequests);
      setLoading(false);
    };
    
    loadRequests();
  }, [employeeId]);

  // Filter and sort requests
  useEffect(() => {
    let filtered = [...requests];
    
    // Tab filtering
    switch (activeTab) {
      case 'active':
        filtered = filtered.filter(r => 
          ['draft', 'submitted', 'pending_approval'].includes(r.status)
        );
        break;
      case 'pending':
        filtered = filtered.filter(r => 
          ['submitted', 'pending_approval'].includes(r.status)
        );
        break;
      case 'history':
        filtered = filtered.filter(r => 
          ['approved', 'rejected', 'cancelled'].includes(r.status)
        );
        break;
    }
    
    // Additional filters
    if (filters.status) {
      filtered = filtered.filter(r => r.status === filters.status);
    }
    
    if (filters.type) {
      filtered = filtered.filter(r => r.type === filters.type);
    }
    
    if (filters.search) {
      const search = filters.search.toLowerCase();
      filtered = filtered.filter(r => 
        r.title.toLowerCase().includes(search) ||
        r.reason.toLowerCase().includes(search)
      );
    }
    
    // Sorting
    filtered.sort((a, b) => {
      let comparison = 0;
      
      switch (sortBy) {
        case 'date':
          comparison = a.submittedAt.getTime() - b.submittedAt.getTime();
          break;
        case 'type':
          comparison = a.type.localeCompare(b.type);
          break;
        case 'status':
          comparison = a.status.localeCompare(b.status);
          break;
      }
      
      return sortOrder === 'desc' ? -comparison : comparison;
    });
    
    setFilteredRequests(filtered);
  }, [requests, activeTab, filters, sortBy, sortOrder]);

  const getStatusColor = (status: Request['status']) => {
    const colors = {
      draft: 'bg-gray-100 text-gray-800',
      submitted: 'bg-blue-100 text-blue-800',
      pending_approval: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      cancelled: 'bg-gray-100 text-gray-600'
    };
    return colors[status];
  };

  const getStatusText = (status: Request['status']) => {
    const texts = {
      draft: 'Draft',
      submitted: 'Submitted',
      pending_approval: 'Pending Approval',
      approved: 'Approved',
      rejected: 'Rejected',
      cancelled: 'Cancelled'
    };
    return texts[status];
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
      low: 'border-gray-300',
      normal: 'border-blue-300',
      high: 'border-orange-300',
      urgent: 'border-red-400'
    };
    return colors[priority];
  };

  const handleRequestAction = (requestId: string, action: 'view' | 'edit' | 'cancel' | 'submit') => {
    const request = requests.find(r => r.id === requestId);
    if (!request) return;
    
    switch (action) {
      case 'view':
        onViewRequest?.(request);
        break;
      case 'edit':
        onEditRequest?.(request);
        break;
      case 'cancel':
        if (window.confirm('Are you sure you want to cancel this request?')) {
          setRequests(prev => 
            prev.map(r => 
              r.id === requestId 
                ? { ...r, status: 'cancelled' as const }
                : r
            )
          );
        }
        break;
      case 'submit':
        setRequests(prev => 
          prev.map(r => 
            r.id === requestId 
              ? { ...r, status: 'submitted' as const, submittedAt: new Date() }
              : r
          )
        );
        break;
    }
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

  const getTabCount = (tab: 'active' | 'pending' | 'history') => {
    switch (tab) {
      case 'active':
        return requests.filter(r => ['draft', 'submitted', 'pending_approval'].includes(r.status)).length;
      case 'pending':
        return requests.filter(r => ['submitted', 'pending_approval'].includes(r.status)).length;
      case 'history':
        return requests.filter(r => ['approved', 'rejected', 'cancelled'].includes(r.status)).length;
      default:
        return 0;
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-sm">
      {/* Header */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          <div>
            <h2 className="text-2xl font-semibold text-gray-900">My Requests</h2>
            <p className="text-sm text-gray-500 mt-1">
              Manage vacation, schedule changes, and other requests
            </p>
          </div>
          
          <button
            onClick={onNewRequest}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
          >
            <span>➕</span>
            New Request
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 mt-6 bg-gray-100 rounded-lg p-1">
          {(['active', 'pending', 'history'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors flex-1 ${
                activeTab === tab
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {tab === 'active' && 'Active'}
              {tab === 'pending' && 'Pending'}
              {tab === 'history' && 'History'}
              <span className="ml-2 px-2 py-0.5 bg-gray-200 text-gray-600 text-xs rounded-full">
                {getTabCount(tab)}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Filters and Search */}
      <div className="p-6 border-b border-gray-200 bg-gray-50">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search by title or reason..."
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
          
          {/* Sort */}
          <select
            value={`${sortBy}-${sortOrder}`}
            onChange={(e) => {
              const [sort, order] = e.target.value.split('-');
              setSortBy(sort as 'date' | 'type' | 'status');
              setSortOrder(order as 'asc' | 'desc');
            }}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="date-desc">Date (Newest)</option>
            <option value="date-asc">Date (Oldest)</option>
            <option value="type-asc">Type (A-Z)</option>
            <option value="status-asc">Status (A-Z)</option>
          </select>
        </div>
      </div>

      {/* Request List */}
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
            <div className="text-4xl mb-4">📝</div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Requests</h3>
            <p className="text-gray-500 mb-4">
              {activeTab === 'active' 
                ? 'You have no active requests'
                : activeTab === 'pending'
                ? 'No pending requests'
                : 'Request history is empty'
              }
            </p>
            <button
              onClick={onNewRequest}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Create Request
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredRequests.map((request) => (
              <div
                key={request.id}
                className={`border rounded-lg p-4 hover:shadow-sm transition-shadow ${
                  getPriorityColor(request.priority)
                } ${request.actionRequired ? 'bg-orange-50' : 'bg-white'}`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-xl">{getTypeIcon(request.type)}</span>
                      <h3 className="font-medium text-gray-900">{request.title}</h3>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(request.status)}`}>
                        {getStatusText(request.status)}
                      </span>
                      {request.actionRequired && (
                        <span className="px-2 py-1 text-xs font-medium bg-orange-100 text-orange-800 rounded-full">
                          Action Required
                        </span>
                      )}
                    </div>
                    
                    <div className="text-sm text-gray-600 mb-3">
                      <div className="flex items-center gap-4 mb-1">
                        <span><strong>Type:</strong> {getTypeText(request.type)}</span>
                        <span><strong>Period:</strong> {formatDateRange(request.startDate, request.endDate)}</span>
                        {request.daysRequested && (
                          <span><strong>Days:</strong> {request.daysRequested}</span>
                        )}
                      </div>
                      <div className="mb-2">
                        <strong>Reason:</strong> {request.reason}
                      </div>
                      <div className="text-xs text-gray-500">
                        Submitted: {formatDate(request.submittedAt)}
                        {request.approver && (
                          <span className="ml-4">
                            Reviewed by: {request.approver.name}
                          </span>
                        )}
                      </div>
                      {request.approver?.comments && (
                        <div className="mt-2 p-2 bg-gray-100 rounded text-xs">
                          <strong>Comments:</strong> {request.approver.comments}
                        </div>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      onClick={() => handleRequestAction(request.id, 'view')}
                      className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 transition-colors"
                    >
                      View
                    </button>
                    
                    {request.status === 'draft' && (
                      <>
                        <button
                          onClick={() => handleRequestAction(request.id, 'edit')}
                          className="px-3 py-1 text-sm border border-blue-300 text-blue-600 rounded hover:bg-blue-50 transition-colors"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => handleRequestAction(request.id, 'submit')}
                          className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                        >
                          Submit
                        </button>
                      </>
                    )}
                    
                    {['submitted', 'pending_approval'].includes(request.status) && (
                      <button
                        onClick={() => handleRequestAction(request.id, 'cancel')}
                        className="px-3 py-1 text-sm border border-red-300 text-red-600 rounded hover:bg-red-50 transition-colors"
                      >
                        Cancel
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
  );
};

export default RequestList;