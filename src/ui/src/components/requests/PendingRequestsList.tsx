import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, Calendar, User, AlertCircle } from 'lucide-react';

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

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

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
      const response = await fetch(`${API_BASE_URL}/requests/pending`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data: PendingRequest[] = await response.json();
      setPendingRequests(data);
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
            Pending Vacation Requests
          </h2>
          <span className="text-sm text-gray-500">
            {pendingRequests.length} pending
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
        <div className="divide-y divide-gray-200">
          {pendingRequests.map((request) => (
            <div key={request.request_id} className="p-6 hover:bg-gray-50 transition-colors">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center mb-2">
                    <User className="h-5 w-5 text-gray-400 mr-2" />
                    <h3 className="font-semibold text-gray-900">{request.employee_name}</h3>
                    <span className="ml-3 px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                      {request.status}
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 text-sm text-gray-600">
                    <div className="flex items-center">
                      <Calendar className="h-4 w-4 mr-2" />
                      <span>
                        {formatDate(request.start_date)} - {formatDate(request.end_date)}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium">{request.duration_days}</span> days
                    </div>
                    <div>
                      Type: <span className="font-medium">{request.request_type}</span>
                    </div>
                    <div>
                      Submitted: {formatDateTime(request.submitted_at)}
                    </div>
                  </div>
                </div>

                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => handleApprove(request.request_id)}
                    disabled={processingId === request.request_id}
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 
                             disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors
                             flex items-center gap-2"
                  >
                    {processingId === request.request_id ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                        Processing...
                      </>
                    ) : (
                      <>
                        <CheckCircle className="h-4 w-4" />
                        Approve
                      </>
                    )}
                  </button>
                  
                  <button
                    className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 
                             transition-colors flex items-center gap-2"
                  >
                    <XCircle className="h-4 w-4" />
                    Reject
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

export default PendingRequestsList;