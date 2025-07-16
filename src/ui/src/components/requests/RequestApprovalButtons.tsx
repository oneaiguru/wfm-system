import React, { useState } from 'react';
import { CheckCircle, XCircle, AlertCircle } from 'lucide-react';

interface RequestApprovalButtonsProps {
  requestId: string;
  onApprove: () => void;
  onReject: () => void;
  size?: 'sm' | 'md' | 'lg';
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const RequestApprovalButtons: React.FC<RequestApprovalButtonsProps> = ({
  requestId,
  onApprove,
  onReject,
  size = 'md'
}) => {
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string>('');

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg'
  };

  const iconSizes = {
    sm: 'h-3 w-3',
    md: 'h-4 w-4',
    lg: 'h-5 w-5'
  };

  const handleApprove = async () => {
    setIsProcessing(true);
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
      console.log('[RequestApprovalButtons] Approved:', result);
      
      // Call parent callback
      onApprove();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to approve request');
      console.error('[RequestApprovalButtons] Approval error:', err);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleReject = async () => {
    setIsProcessing(true);
    setError('');
    
    try {
      // For now, just call the callback since reject endpoint isn't implemented
      console.log('[RequestApprovalButtons] Reject not implemented yet');
      onReject();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to reject request');
      console.error('[RequestApprovalButtons] Rejection error:', err);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="flex flex-col gap-2">
      {error && (
        <div className="flex items-center gap-2 text-red-600 text-sm">
          <AlertCircle className="h-4 w-4" />
          <span>{error}</span>
        </div>
      )}
      
      <div className="flex gap-2">
        <button
          onClick={handleApprove}
          disabled={isProcessing}
          className={`
            ${sizeClasses[size]}
            bg-green-600 text-white rounded-lg hover:bg-green-700 
            disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors
            flex items-center gap-2 font-medium
          `}
        >
          {isProcessing ? (
            <>
              <div className={`animate-spin rounded-full ${iconSizes[size]} border-b-2 border-white`}></div>
              Processing...
            </>
          ) : (
            <>
              <CheckCircle className={iconSizes[size]} />
              Approve
            </>
          )}
        </button>
        
        <button
          onClick={handleReject}
          disabled={isProcessing}
          className={`
            ${sizeClasses[size]}
            bg-red-600 text-white rounded-lg hover:bg-red-700 
            disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors
            flex items-center gap-2 font-medium
          `}
        >
          <XCircle className={iconSizes[size]} />
          Reject
        </button>
      </div>
    </div>
  );
};

export default RequestApprovalButtons;