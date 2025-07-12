import React, { useState, useEffect } from 'react';
import { Settings, CheckCircle, XCircle, Clock, AlertTriangle, Users } from 'lucide-react';

interface StatusChange {
  id: string;
  employeeId: string;
  employeeName: string;
  fromStatus: string;
  toStatus: string;
  reason: string;
  requestedBy: string;
  requestedAt: Date;
  approvedBy?: string;
  approvedAt?: Date;
  status: 'pending' | 'approved' | 'rejected';
}

const EmployeeStatusManager: React.FC = () => {
  const [statusChanges, setStatusChanges] = useState<StatusChange[]>([]);
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending');
  const [selectedChanges, setSelectedChanges] = useState<string[]>([]);

  // Generate mock data
  useEffect(() => {
    const mockChanges: StatusChange[] = [
      {
        id: 'sc_001',
        employeeId: 'EMP001',
        employeeName: 'Anna Petrov',
        fromStatus: 'active',
        toStatus: 'vacation',
        reason: 'Annual vacation - 2 weeks',
        requestedBy: 'Anna Petrov',
        requestedAt: new Date('2024-07-10'),
        status: 'pending'
      },
      {
        id: 'sc_002',
        employeeId: 'EMP002',
        employeeName: 'Mikhail Volkov',
        fromStatus: 'probation',
        toStatus: 'active',
        reason: 'Completed probation period successfully',
        requestedBy: 'Manager Smith',
        requestedAt: new Date('2024-07-09'),
        approvedBy: 'HR Admin',
        approvedAt: new Date('2024-07-09'),
        status: 'approved'
      },
      {
        id: 'sc_003',
        employeeId: 'EMP003',
        employeeName: 'Elena Kozlov',
        fromStatus: 'active',
        toStatus: 'inactive',
        reason: 'Medical leave - 1 month',
        requestedBy: 'Elena Kozlov',
        requestedAt: new Date('2024-07-08'),
        status: 'pending'
      },
      {
        id: 'sc_004',
        employeeId: 'EMP004',
        employeeName: 'Pavel Orlov',
        fromStatus: 'inactive',
        toStatus: 'terminated',
        reason: 'End of contract - performance issues',
        requestedBy: 'Manager Johnson',
        requestedAt: new Date('2024-07-07'),
        approvedBy: 'HR Director',
        approvedAt: new Date('2024-07-08'),
        status: 'approved'
      },
      {
        id: 'sc_005',
        employeeId: 'EMP005',
        employeeName: 'Sofia Ivanov',
        fromStatus: 'vacation',
        toStatus: 'active',
        reason: 'Returning from vacation',
        requestedBy: 'Sofia Ivanov',
        requestedAt: new Date('2024-07-06'),
        status: 'pending'
      }
    ];

    setStatusChanges(mockChanges);
  }, []);

  const filteredChanges = statusChanges.filter(change => 
    filter === 'all' || change.status === filter
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'inactive':
        return 'bg-gray-100 text-gray-800';
      case 'vacation':
        return 'bg-blue-100 text-blue-800';
      case 'probation':
        return 'bg-yellow-100 text-yellow-800';
      case 'terminated':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getChangeStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'approved':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'rejected':
        return <XCircle className="h-4 w-4 text-red-500" />;
      default:
        return <AlertTriangle className="h-4 w-4 text-gray-500" />;
    }
  };

  const handleApprove = (changeId: string) => {
    setStatusChanges(prev => prev.map(change => 
      change.id === changeId 
        ? { ...change, status: 'approved' as const, approvedBy: 'Current User', approvedAt: new Date() }
        : change
    ));
  };

  const handleReject = (changeId: string) => {
    setStatusChanges(prev => prev.map(change => 
      change.id === changeId 
        ? { ...change, status: 'rejected' as const, approvedBy: 'Current User', approvedAt: new Date() }
        : change
    ));
  };

  const handleBulkApprove = () => {
    setStatusChanges(prev => prev.map(change => 
      selectedChanges.includes(change.id) && change.status === 'pending'
        ? { ...change, status: 'approved' as const, approvedBy: 'Current User', approvedAt: new Date() }
        : change
    ));
    setSelectedChanges([]);
  };

  const handleSelectChange = (changeId: string) => {
    setSelectedChanges(prev =>
      prev.includes(changeId)
        ? prev.filter(id => id !== changeId)
        : [...prev, changeId]
    );
  };

  const pendingCount = statusChanges.filter(c => c.status === 'pending').length;

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Settings className="h-6 w-6 mr-2 text-blue-600" />
          Employee Status Manager
        </h2>
        <p className="mt-2 text-gray-600">
          Review and approve employee status changes and requests
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Pending</h3>
              <p className="text-2xl font-bold text-yellow-600">{pendingCount}</p>
              <p className="text-sm text-gray-600">Awaiting Approval</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Approved</h3>
              <p className="text-2xl font-bold text-green-600">
                {statusChanges.filter(c => c.status === 'approved').length}
              </p>
              <p className="text-sm text-gray-600">This Week</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <XCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Rejected</h3>
              <p className="text-2xl font-bold text-red-600">
                {statusChanges.filter(c => c.status === 'rejected').length}
              </p>
              <p className="text-sm text-gray-600">This Week</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Users className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{statusChanges.length}</p>
              <p className="text-sm text-gray-600">All Requests</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Actions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Requests</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>

            <span className="text-sm text-gray-600">
              {filteredChanges.length} requests
            </span>
          </div>

          {selectedChanges.length > 0 && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">
                {selectedChanges.length} selected
              </span>
              <button
                onClick={handleBulkApprove}
                className="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 text-sm"
              >
                Bulk Approve
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Status Change Requests */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Status Change Requests</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredChanges.map((change) => (
            <div key={change.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4">
                  {change.status === 'pending' && (
                    <input
                      type="checkbox"
                      checked={selectedChanges.includes(change.id)}
                      onChange={() => handleSelectChange(change.id)}
                      className="mt-1 rounded"
                    />
                  )}
                  
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="text-lg font-medium text-gray-900">
                        {change.employeeName}
                      </h4>
                      <span className="text-sm text-gray-500">({change.employeeId})</span>
                      {getChangeStatusIcon(change.status)}
                    </div>

                    <div className="flex items-center space-x-4 mb-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(change.fromStatus)}`}>
                        {change.fromStatus}
                      </span>
                      <span className="text-gray-400">→</span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(change.toStatus)}`}>
                        {change.toStatus}
                      </span>
                    </div>

                    <p className="text-gray-700 mb-2">{change.reason}</p>
                    
                    <div className="text-sm text-gray-500">
                      <p>Requested by: {change.requestedBy} on {change.requestedAt.toLocaleDateString()}</p>
                      {change.approvedBy && (
                        <p>
                          {change.status === 'approved' ? 'Approved' : 'Rejected'} by: {change.approvedBy} on {change.approvedAt?.toLocaleDateString()}
                        </p>
                      )}
                    </div>
                  </div>
                </div>

                {change.status === 'pending' && (
                  <div className="flex space-x-2">
                    <button
                      onClick={() => handleReject(change.id)}
                      className="px-3 py-2 border border-red-300 text-red-700 rounded-md hover:bg-red-50"
                    >
                      Reject
                    </button>
                    <button
                      onClick={() => handleApprove(change.id)}
                      className="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                    >
                      Approve
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {filteredChanges.length === 0 && (
          <div className="text-center py-12">
            <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No status changes found</h3>
            <p className="text-gray-600">No requests match the selected filter.</p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Bulk Status Update</h4>
            <p className="text-sm text-gray-600 mt-1">Update multiple employees at once</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Generate Report</h4>
            <p className="text-sm text-gray-600 mt-1">Export status change history</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Set Automation Rules</h4>
            <p className="text-sm text-gray-600 mt-1">Configure auto-approval criteria</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default EmployeeStatusManager;