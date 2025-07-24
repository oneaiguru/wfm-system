import React, { useState, useEffect } from 'react';
import realRequestService from '../../services/realRequestService';

interface RequestEditorProps {
  request: {
    id: string;
    type: string;
    title: string;
    status: string;
    priority: string;
    startDate: Date | string;
    endDate?: Date | string;
    reason: string;
    daysRequested?: number;
  };
  onSave: (request: any) => void;
  onCancel: () => void;
}

const RequestEditor: React.FC<RequestEditorProps> = ({ request, onSave, onCancel }) => {
  const [editedRequest, setEditedRequest] = useState({
    ...request,
    startDate: typeof request.startDate === 'string' 
      ? request.startDate 
      : request.startDate.toISOString().split('T')[0],
    endDate: request.endDate 
      ? typeof request.endDate === 'string'
        ? request.endDate
        : request.endDate.toISOString().split('T')[0]
      : ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const calculateDays = (start: string, end: string) => {
    if (!start || !end) return 0;
    const startDate = new Date(start);
    const endDate = new Date(end);
    const diffTime = Math.abs(endDate.getTime() - startDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return diffDays;
  };

  useEffect(() => {
    const days = calculateDays(editedRequest.startDate, editedRequest.endDate);
    setEditedRequest(prev => ({ ...prev, daysRequested: days }));
  }, [editedRequest.startDate, editedRequest.endDate]);

  const handleSave = async () => {
    setLoading(true);
    setError(null);

    try {
      // Call real API to update request
      const response = await realRequestService.updateRequest(request.id, {
        start_date: editedRequest.startDate,
        end_date: editedRequest.endDate,
        description: editedRequest.reason
      });

      if (response.success) {
        onSave({
          ...editedRequest,
          startDate: new Date(editedRequest.startDate),
          endDate: editedRequest.endDate ? new Date(editedRequest.endDate) : undefined
        });
      } else {
        setError(response.error || 'Failed to update request');
      }
    } catch (err) {
      setError('Failed to save changes');
      console.error('Error updating request:', err);
    } finally {
      setLoading(false);
    }
  };

  const isEditable = ['draft', 'pending_approval', 'submitted'].includes(request.status);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full m-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-2xl font-semibold text-gray-900">Edit Request</h2>
          <p className="text-sm text-gray-500 mt-1">
            {isEditable ? 'Update your request details' : 'View request details (read-only)'}
          </p>
        </div>

        <div className="p-6 space-y-4">
          {error && (
            <div className="bg-red-50 text-red-700 p-3 rounded-lg">
              {error}
            </div>
          )}

          {/* Request Info */}
          <div className="bg-gray-50 p-4 rounded-lg">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <span className="text-sm font-medium text-gray-500">Type</span>
                <p className="text-gray-900">{editedRequest.type}</p>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">Status</span>
                <p className="text-gray-900">{editedRequest.status}</p>
              </div>
            </div>
          </div>

          {/* Date Range */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date Range
            </label>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs text-gray-500 mb-1">Start Date</label>
                <input
                  type="date"
                  value={editedRequest.startDate}
                  onChange={(e) => setEditedRequest({ ...editedRequest, startDate: e.target.value })}
                  disabled={!isEditable}
                  className={`w-full px-3 py-2 border rounded-lg ${
                    isEditable 
                      ? 'border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500' 
                      : 'border-gray-200 bg-gray-100 cursor-not-allowed'
                  }`}
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 mb-1">End Date</label>
                <input
                  type="date"
                  value={editedRequest.endDate}
                  onChange={(e) => setEditedRequest({ ...editedRequest, endDate: e.target.value })}
                  disabled={!isEditable}
                  min={editedRequest.startDate}
                  className={`w-full px-3 py-2 border rounded-lg ${
                    isEditable 
                      ? 'border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500' 
                      : 'border-gray-200 bg-gray-100 cursor-not-allowed'
                  }`}
                />
              </div>
            </div>
            {editedRequest.daysRequested > 0 && (
              <p className="text-sm text-gray-600 mt-2">
                Total days: {editedRequest.daysRequested}
              </p>
            )}
          </div>

          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Reason
            </label>
            <textarea
              value={editedRequest.reason}
              onChange={(e) => setEditedRequest({ ...editedRequest, reason: e.target.value })}
              disabled={!isEditable}
              rows={4}
              className={`w-full px-3 py-2 border rounded-lg ${
                isEditable 
                  ? 'border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500' 
                  : 'border-gray-200 bg-gray-100 cursor-not-allowed'
              }`}
              placeholder="Please provide a reason for your request..."
            />
          </div>

          {/* Priority */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Priority
            </label>
            <select
              value={editedRequest.priority}
              onChange={(e) => setEditedRequest({ ...editedRequest, priority: e.target.value })}
              disabled={!isEditable}
              className={`w-full px-3 py-2 border rounded-lg ${
                isEditable 
                  ? 'border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500' 
                  : 'border-gray-200 bg-gray-100 cursor-not-allowed'
              }`}
            >
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
              <option value="urgent">Urgent</option>
            </select>
          </div>
        </div>

        {/* Actions */}
        <div className="p-6 border-t border-gray-200 flex justify-end gap-3">
          <button
            onClick={onCancel}
            className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            {isEditable ? 'Cancel' : 'Close'}
          </button>
          {isEditable && (
            <button
              onClick={handleSave}
              disabled={loading}
              className={`px-4 py-2 rounded-lg text-white transition-colors ${
                loading 
                  ? 'bg-gray-400 cursor-not-allowed' 
                  : 'bg-blue-600 hover:bg-blue-700'
              }`}
            >
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default RequestEditor;