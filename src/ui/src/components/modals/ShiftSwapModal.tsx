import React, { useState, useEffect } from 'react';
import { X, Calendar, Clock, User, ArrowLeftRight } from 'lucide-react';
import { realShiftService, Shift } from '../../services/realShiftService';
import { realAuthService } from '../../services/realAuthService';

interface ShiftSwapModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

const ShiftSwapModal: React.FC<ShiftSwapModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const [myShifts, setMyShifts] = useState<Shift[]>([]);
  const [availableShifts, setAvailableShifts] = useState<Shift[]>([]);
  const [selectedMyShift, setSelectedMyShift] = useState<number | null>(null);
  const [selectedRequestedShift, setSelectedRequestedShift] = useState<number | null>(null);
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitLoading, setSubmitLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadShifts();
    }
  }, [isOpen]);

  const loadShifts = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Get current user
      const user = realAuthService.getCurrentUser();
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Load my shifts for next 30 days
      const startDate = new Date().toISOString().split('T')[0];
      const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      
      const [myShiftsData, availableShiftsData] = await Promise.all([
        realShiftService.getEmployeeShifts(user.id, startDate, endDate),
        realShiftService.getAvailableShifts(user.id)
      ]);

      setMyShifts(myShiftsData);
      setAvailableShifts(availableShiftsData);
    } catch (err) {
      console.error('Failed to load shifts:', err);
      setError(err instanceof Error ? err.message : 'Failed to load shifts');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!selectedMyShift || !selectedRequestedShift) {
      setError('Please select both your shift and the requested shift');
      return;
    }

    if (!reason.trim()) {
      setError('Please provide a reason for the shift swap');
      return;
    }

    setSubmitLoading(true);
    setError(null);

    try {
      await realShiftService.requestShiftTrade({
        myShiftId: selectedMyShift,
        requestedShiftId: selectedRequestedShift,
        reason: reason.trim()
      });

      // Success!
      if (onSuccess) {
        onSuccess();
      }
      
      // Reset form
      setSelectedMyShift(null);
      setSelectedRequestedShift(null);
      setReason('');
      
      // Close modal
      onClose();
    } catch (err) {
      console.error('Failed to submit shift swap request:', err);
      setError(err instanceof Error ? err.message : 'Failed to submit request');
    } finally {
      setSubmitLoading(false);
    }
  };

  const formatShiftDisplay = (shift: Shift) => {
    const date = new Date(shift.date);
    return `${date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    })} - ${shift.startTime} to ${shift.endTime} (${shift.employeeName})`;
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <ArrowLeftRight className="h-6 w-6 text-blue-600" />
              <h2 className="text-xl font-semibold text-gray-900">Request Shift Swap</h2>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <X className="h-5 w-5 text-gray-500" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 py-4 overflow-y-auto max-h-[calc(90vh-200px)]">
          {loading ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
              <p className="text-gray-600 mt-4">Loading shifts...</p>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Error display */}
              {error && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <p className="text-red-800 text-sm">{error}</p>
                </div>
              )}

              {/* My Shift Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  <div className="flex items-center gap-2 mb-2">
                    <Calendar className="h-4 w-4 text-gray-500" />
                    <span>Select Your Shift to Swap</span>
                  </div>
                </label>
                <select
                  value={selectedMyShift || ''}
                  onChange={(e) => setSelectedMyShift(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Choose a shift...</option>
                  {myShifts.map((shift) => (
                    <option key={shift.id} value={shift.id}>
                      {formatShiftDisplay(shift)}
                    </option>
                  ))}
                </select>
              </div>

              {/* Requested Shift Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  <div className="flex items-center gap-2 mb-2">
                    <Clock className="h-4 w-4 text-gray-500" />
                    <span>Select Requested Shift</span>
                  </div>
                </label>
                <select
                  value={selectedRequestedShift || ''}
                  onChange={(e) => setSelectedRequestedShift(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  disabled={!selectedMyShift}
                >
                  <option value="">Choose a shift to swap with...</option>
                  {availableShifts.map((shift) => (
                    <option key={shift.id} value={shift.id}>
                      {formatShiftDisplay(shift)}
                    </option>
                  ))}
                </select>
                {!selectedMyShift && (
                  <p className="text-sm text-gray-500 mt-1">
                    Please select your shift first
                  </p>
                )}
              </div>

              {/* Reason */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  <div className="flex items-center gap-2 mb-2">
                    <User className="h-4 w-4 text-gray-500" />
                    <span>Reason for Swap</span>
                  </div>
                </label>
                <textarea
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  rows={3}
                  placeholder="Please explain why you need to swap this shift..."
                />
              </div>

              {/* Shift Preview */}
              {selectedMyShift && selectedRequestedShift && (
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="font-medium text-gray-900 mb-3">Shift Swap Preview</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-gray-600">You give up:</span>
                      <span className="font-medium">
                        {myShifts.find(s => s.id === selectedMyShift) && 
                          formatShiftDisplay(myShifts.find(s => s.id === selectedMyShift)!)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-gray-600">You receive:</span>
                      <span className="font-medium">
                        {availableShifts.find(s => s.id === selectedRequestedShift) &&
                          formatShiftDisplay(availableShifts.find(s => s.id === selectedRequestedShift)!)}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-end gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={submitLoading}
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={!selectedMyShift || !selectedRequestedShift || !reason.trim() || submitLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {submitLoading ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Submitting...</span>
                </>
              ) : (
                <>
                  <ArrowLeftRight className="h-4 w-4" />
                  <span>Submit Swap Request</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ShiftSwapModal;