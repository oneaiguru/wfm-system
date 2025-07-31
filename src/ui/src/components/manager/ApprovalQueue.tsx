import React, { useEffect, useState } from 'react';
import { AlertCircle, CheckCircle, XCircle, Clock, User, Calendar } from 'lucide-react';

interface Approval {
  id: number;
  employee_name: string;
  employee_id: number;
  request_type: string;
  start_date: string;
  end_date: string;
  reason: string;
  urgency: 'low' | 'medium' | 'high';
  status: string;
  created_at: string;
}

const ApprovalQueue: React.FC = () => {
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [processingId, setProcessingId] = useState<number | null>(null);

  useEffect(() => {
    fetchApprovals();
  }, []);

  const fetchApprovals = async () => {
    try {
      setError(null);
      const response = await fetch('/api/v1/manager/approvals', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token') || localStorage.getItem('authToken')}`
        }
      });
      
      if (!response.ok) {
        throw new Error(`Failed to fetch approvals: ${response.status}`);
      }
      
      const data = await response.json();
      setApprovals(data.pending_approvals || []);
    } catch (error) {
      console.error('Failed to fetch approvals:', error);
      setError('Failed to load approval requests. Please try again.');
      // Set demo data as fallback
      setApprovals([
        {
          id: 1,
          employee_name: 'Jane Smith',
          employee_id: 2,
          request_type: 'Vacation',
          start_date: '2025-08-01',
          end_date: '2025-08-05',
          reason: 'Family vacation',
          urgency: 'medium',
          status: 'pending',
          created_at: '2025-07-26T10:00:00Z'
        },
        {
          id: 2,
          employee_name: 'Jane Smith',
          employee_id: 2,
          request_type: 'Sick Leave',
          start_date: '2025-07-27',
          end_date: '2025-07-27',
          reason: 'Medical appointment',
          urgency: 'high',
          status: 'pending',
          created_at: '2025-07-26T11:00:00Z'
        },
        {
          id: 3,
          employee_name: 'Jane Smith',
          employee_id: 2,
          request_type: 'Remote Work',
          start_date: '2025-07-28',
          end_date: '2025-07-30',
          reason: 'Home repairs',
          urgency: 'low',
          status: 'pending',
          created_at: '2025-07-26T12:00:00Z'
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (id: number) => {
    setProcessingId(id);
    try {
      const response = await fetch(`/api/v1/manager/approvals/${id}/approve`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token') || localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        // Remove from list or refresh
        setApprovals(prev => prev.filter(a => a.id !== id));
      } else {
        throw new Error('Failed to approve request');
      }
    } catch (error) {
      console.error('Failed to approve:', error);
      setError('Failed to approve request. Please try again.');
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (id: number) => {
    setProcessingId(id);
    try {
      const response = await fetch(`/api/v1/manager/approvals/${id}/reject`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token') || localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        // Remove from list or refresh
        setApprovals(prev => prev.filter(a => a.id !== id));
      } else {
        throw new Error('Failed to reject request');
      }
    } catch (error) {
      console.error('Failed to reject:', error);
      setError('Failed to reject request. Please try again.');
    } finally {
      setProcessingId(null);
    }
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'high':
        return 'text-red-600 bg-red-100';
      case 'medium':
        return 'text-yellow-600 bg-yellow-100';
      case 'low':
        return 'text-green-600 bg-green-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading approvals...</p>
        </div>
      </div>
    );
  }

  return (
    <div data-testid="approval-queue" className="max-w-6xl mx-auto p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Approval Queue</h1>
        <p className="text-gray-600 mt-2">
          Pending Approvals ({approvals.length})
        </p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <AlertCircle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-700">{error}</span>
        </div>
      )}

      {approvals.length === 0 ? (
        <div className="bg-white rounded-lg shadow p-8 text-center">
          <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-900 mb-2">All Caught Up!</h3>
          <p className="text-gray-600">No pending approval requests at this time.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {approvals.map(approval => (
            <div
              key={approval.id}
              data-testid={`approval-${approval.id}`}
              className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow"
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <div className="flex items-center mb-2">
                    <User className="h-5 w-5 text-gray-400 mr-2" />
                    <h3 className="text-lg font-semibold text-gray-900">
                      {approval.employee_name}
                    </h3>
                    <span className={`ml-3 px-2 py-1 rounded-full text-xs font-medium ${getUrgencyColor(approval.urgency)}`}>
                      {approval.urgency.toUpperCase()} PRIORITY
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4">
                    <div>
                      <p className="text-sm text-gray-600">Request Type</p>
                      <p className="font-medium">{approval.request_type}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Duration</p>
                      <p className="font-medium flex items-center">
                        <Calendar className="h-4 w-4 mr-1 text-gray-400" />
                        {formatDate(approval.start_date)} - {formatDate(approval.end_date)}
                      </p>
                    </div>
                  </div>
                  
                  <div className="mb-4">
                    <p className="text-sm text-gray-600">Reason</p>
                    <p className="text-gray-900">{approval.reason}</p>
                  </div>
                  
                  <div className="flex items-center text-sm text-gray-500">
                    <Clock className="h-4 w-4 mr-1" />
                    Submitted {formatDate(approval.created_at)}
                  </div>
                </div>
                
                <div className="flex flex-col space-y-2 ml-4">
                  <button
                    onClick={() => handleApprove(approval.id)}
                    disabled={processingId === approval.id}
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 
                             disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    <CheckCircle className="h-4 w-4 mr-2" />
                    {processingId === approval.id ? 'Processing...' : 'Approve'}
                  </button>
                  <button
                    onClick={() => handleReject(approval.id)}
                    disabled={processingId === approval.id}
                    className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 
                             disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    <XCircle className="h-4 w-4 mr-2" />
                    {processingId === approval.id ? 'Processing...' : 'Reject'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default ApprovalQueue;