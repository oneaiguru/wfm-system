import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, Calendar, User, AlertCircle, Edit } from 'lucide-react';

interface PendingRequest {
  request_id: number;
  request_type: string;
  request_type_english: string;
  start_date: string;
  end_date: string;
  duration_days: number;
  status: string;
  status_english: string;
  created_date: string;
  reason: string;
  actions_available: string[];
}

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const PendingRequestsList: React.FC = () => {
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [processingId, setProcessingId] = useState<string>('');

  useEffect(() => {
    fetchPendingRequests();
  }, []);

  const fetchPendingRequests = async () => {
    setLoading(true);
    setError('');
    
    try {
      // Use working my-requests API from INTEGRATION-OPUS
      const token = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/requests/my-requests`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      // Parse the actual API response format: {"requests": [...], "total_count": 2}
      setPendingRequests(data.requests || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load pending requests');
      console.error('[PendingRequestsList] Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (requestId: string) => {
    setProcessingId(requestId);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/requests/approve/${requestId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `HTTP ${response.status}`);
      }
      
      const result = await response.json();
      console.log('[PendingRequestsList] Approved:', result);
      
      // Remove approved request from list
      setPendingRequests(prev => prev.filter(req => req.request_id !== requestId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to approve request');
      console.error('[PendingRequestsList] Approval error:', err);
    } finally {
      setProcessingId('');
    }
  };

  const handleEdit = (requestId: number) => {
    // For E2E testing - simple edit handler
    console.log('[PendingRequestsList] Edit request:', requestId);
    // In a real implementation, this would navigate to edit form or open modal
    alert(`Edit request #${requestId} - Feature coming soon!`);
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
    <div className="bg-white rounded-lg shadow">
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-gray-800 flex items-center">
            <Clock className="h-5 w-5 mr-2 text-blue-600" />
            My Requests
          </h2>
          <span className="text-sm text-gray-500">
            {pendingRequests.length} requests
          </span>
        </div>
      </div>

      {error && (
        <div className="mx-6 mt-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center">
          <AlertCircle className="h-5 w-5 text-red-600 mr-2" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      {pendingRequests.length === 0 ? (
        <div className="p-8 text-center text-gray-500">
          <Clock className="h-12 w-12 mx-auto mb-4 text-gray-300" />
          <p>No pending requests</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full bg-white">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Dates
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Days
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {pendingRequests.map((request) => (
                <tr key={request.request_id} data-testid={`request-${request.request_id}`} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {request.request_type_english} #{request.request_id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      request.status_english === 'Pending' 
                        ? 'bg-yellow-100 text-yellow-800' 
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {request.status_english === 'pending' ? 'Pending' : request.status_english}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatDate(request.start_date)} - {formatDate(request.end_date)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {request.duration_days} days
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEdit(request.request_id)}
                        className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors flex items-center gap-1"
                      >
                        <Edit className="h-3 w-3" />
                        Edit
                      </button>
                      
                      <button
                        onClick={() => handleApprove(request.request_id)}
                        disabled={processingId === request.request_id}
                        className="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 disabled:bg-gray-300 transition-colors flex items-center gap-1"
                      >
                        {processingId === request.request_id ? (
                          <>
                            <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-white"></div>
                            Processing
                          </>
                        ) : (
                          <>
                            <CheckCircle className="h-3 w-3" />
                            Approve
                          </>
                        )}
                      </button>
                      
                      <button
                        className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 transition-colors flex items-center gap-1"
                      >
                        <XCircle className="h-3 w-3" />
                        Reject
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default PendingRequestsList;