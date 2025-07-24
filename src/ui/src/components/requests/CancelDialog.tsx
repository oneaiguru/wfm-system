import React, { useState } from 'react';
import realRequestService from '../../services/realRequestService';

interface CancelDialogProps {
  request: {
    id: string;
    title: string;
    type: string;
    startDate: Date | string;
    endDate?: Date | string;
  };
  onConfirm: (reason: string) => void;
  onCancel: () => void;
}

const CancelDialog: React.FC<CancelDialogProps> = ({ request, onConfirm, onCancel }) => {
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleConfirm = async () => {
    if (!reason.trim()) {
      setError('Please provide a reason for cancellation');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Call real API to delete/cancel request
      const response = await realRequestService.deleteRequest(request.id, reason);

      if (response.success) {
        onConfirm(reason);
      } else {
        setError(response.error || 'Failed to cancel request');
      }
    } catch (err) {
      setError('Failed to cancel request');
      console.error('Error canceling request:', err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (date: Date | string) => {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full m-4">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Cancel Request</h2>
          <p className="text-sm text-gray-500 mt-1">
            This action cannot be undone
          </p>
        </div>

        <div className="p-6">
          {error && (
            <div className="bg-red-50 text-red-700 p-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          {/* Request Details */}
          <div className="bg-gray-50 p-4 rounded-lg mb-4">
            <h3 className="font-medium text-gray-900 mb-2">{request.title}</h3>
            <div className="text-sm text-gray-600 space-y-1">
              <p>Type: {request.type}</p>
              <p>
                Dates: {formatDate(request.startDate)}
                {request.endDate && ` - ${formatDate(request.endDate)}`}
              </p>
            </div>
          </div>

          {/* Warning Message */}
          <div className="bg-yellow-50 text-yellow-800 p-3 rounded-lg mb-4 flex items-start">
            <span className="text-xl mr-2">⚠️</span>
            <div className="text-sm">
              <p className="font-medium">Are you sure you want to cancel this request?</p>
              <p className="mt-1">
                Once cancelled, you will need to submit a new request if you change your mind.
              </p>
            </div>
          </div>

          {/* Cancellation Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Reason for Cancellation <span className="text-red-500">*</span>
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Please provide a reason for cancelling this request..."
              autoFocus
            />
            <p className="text-xs text-gray-500 mt-1">
              This information will be recorded for audit purposes
            </p>
          </div>
        </div>

        {/* Actions */}
        <div className="p-6 border-t border-gray-200 flex justify-end gap-3">
          <button
            onClick={onCancel}
            disabled={loading}
            className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Keep Request
          </button>
          <button
            onClick={handleConfirm}
            disabled={loading || !reason.trim()}
            className={`px-4 py-2 rounded-lg text-white transition-colors ${
              loading || !reason.trim()
                ? 'bg-gray-400 cursor-not-allowed' 
                : 'bg-red-600 hover:bg-red-700'
            }`}
          >
            {loading ? 'Cancelling...' : 'Cancel Request'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CancelDialog;