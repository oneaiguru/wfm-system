import React from 'react';
import { X } from 'lucide-react';

interface ApprovalDialogProps {
  request: ApprovalRequest | undefined;
  isOpen: boolean;
  onClose: () => void;
  onApprove: (requestId: string, notes: string) => void;
  onReject: (requestId: string, reason: string) => void;
}

interface ApprovalRequest {
  id: string;
  type: 'time_off' | 'shift_change' | 'overtime' | 'vacation' | 'sick_leave';
  title: string;
  status: 'draft' | 'submitted' | 'pending_approval' | 'approved' | 'rejected' | 'cancelled';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  startDate: Date;
  endDate?: Date;
  reason: string;
  submittedAt: Date;
  employeeName: string;
  employeeId: string;
  approver?: {
    name: string;
    comments?: string;
  };
  daysRequested?: number;
  actionRequired?: boolean;
}

const ApprovalDialog: React.FC<ApprovalDialogProps> = ({
  request,
  isOpen,
  onClose,
  onApprove,
  onReject
}) => {
  const [notes, setNotes] = React.useState('');
  const [rejectionReason, setRejectionReason] = React.useState('');
  const [showApprovalForm, setShowApprovalForm] = React.useState(false);
  const [showRejectionForm, setShowRejectionForm] = React.useState(false);

  React.useEffect(() => {
    if (!isOpen) {
      setNotes('');
      setRejectionReason('');
      setShowApprovalForm(false);
      setShowRejectionForm(false);
    }
  }, [isOpen]);

  if (!isOpen || !request) return null;

  const handleApprove = () => {
    if (showApprovalForm) {
      onApprove(request.id, notes);
      onClose();
    } else {
      setShowApprovalForm(true);
    }
  };

  const handleReject = () => {
    if (showRejectionForm) {
      if (!rejectionReason.trim()) {
        alert('Please provide a reason for rejection');
        return;
      }
      onReject(request.id, rejectionReason);
      onClose();
    } else {
      setShowRejectionForm(true);
    }
  };

  const getPriorityColor = (priority: string) => {
    const colors = {
      low: 'text-gray-600',
      normal: 'text-blue-600', 
      high: 'text-orange-600',
      urgent: 'text-red-600'
    };
    return colors[priority as keyof typeof colors] || 'text-gray-600';
  };

  const getTypeIcon = (type: string) => {
    const icons = {
      time_off: '🕐',
      shift_change: '🔄',
      overtime: '⏰', 
      vacation: '🏖️',
      sick_leave: '🏥'
    };
    return icons[type as keyof typeof icons] || '📝';
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 bg-gradient-to-r from-blue-600 to-blue-700">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-2xl">{getTypeIcon(request.type)}</span>
              <div>
                <h2 className="text-xl font-semibold text-white">
                  Request Approval
                </h2>
                <p className="text-blue-100 text-sm">
                  Review and approve employee request
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-white hover:text-blue-200 transition-colors p-1"
            >
              <X className="h-6 w-6" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 py-6 overflow-y-auto max-h-[60vh]">
          <div className="space-y-6">
            {/* Employee Info */}
            <div className="bg-blue-50 rounded-lg p-4">
              <h3 className="font-medium text-blue-900 mb-3 flex items-center gap-2">
                👤 Employee Information
              </h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-blue-700 font-medium">Name:</span>
                  <p className="text-blue-900">{request.employeeName}</p>
                </div>
                <div>
                  <span className="text-blue-700 font-medium">Employee ID:</span>
                  <p className="text-blue-900">{request.employeeId}</p>
                </div>
              </div>
            </div>

            {/* Request Info */}
            <div className="bg-gray-50 rounded-lg p-4">
              <h3 className="font-medium text-gray-900 mb-3 flex items-center gap-2">
                📋 Request Details
              </h3>
              <dl className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <dt className="text-gray-600 font-medium">Type:</dt>
                  <dd className="font-medium flex items-center gap-1">
                    {getTypeIcon(request.type)} {request.type.replace('_', ' ')}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600 font-medium">Title:</dt>
                  <dd className="font-medium">{request.title}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600 font-medium">Priority:</dt>
                  <dd className={`font-medium uppercase ${getPriorityColor(request.priority)}`}>
                    {request.priority}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600 font-medium">Start Date:</dt>
                  <dd className="font-medium">{request.startDate.toLocaleDateString()}</dd>
                </div>
                {request.endDate && (
                  <div className="flex justify-between">
                    <dt className="text-gray-600 font-medium">End Date:</dt>
                    <dd className="font-medium">{request.endDate.toLocaleDateString()}</dd>
                  </div>
                )}
                {request.daysRequested && (
                  <div className="flex justify-between">
                    <dt className="text-gray-600 font-medium">Days Requested:</dt>
                    <dd className="font-medium">{request.daysRequested}</dd>
                  </div>
                )}
                <div className="flex justify-between">
                  <dt className="text-gray-600 font-medium">Submitted:</dt>
                  <dd className="font-medium">{request.submittedAt.toLocaleDateString()}</dd>
                </div>
              </dl>
            </div>

            {/* Reason */}
            <div>
              <h3 className="font-medium text-gray-900 mb-2 flex items-center gap-2">
                💭 Request Reason
              </h3>
              <p className="text-sm text-gray-600 bg-gray-50 p-3 rounded border-l-4 border-blue-400">
                {request.reason}
              </p>
            </div>

            {/* Action Required Alert */}
            {request.actionRequired && (
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <div className="flex items-center gap-2">
                  <span className="text-orange-500 text-lg">⚠️</span>
                  <h3 className="font-medium text-orange-900">Action Required</h3>
                </div>
                <p className="text-sm text-orange-700 mt-1">
                  This request requires additional documentation or action before approval.
                </p>
              </div>
            )}

            {/* Approval Form */}
            {showApprovalForm && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <h3 className="font-medium text-green-900 mb-3 flex items-center gap-2">
                  ✅ Approval Notes
                </h3>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Add any notes or conditions for approval (optional)..."
                  className="w-full p-3 border border-green-300 rounded-lg resize-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                  rows={3}
                />
              </div>
            )}

            {/* Rejection Form */}
            {showRejectionForm && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <h3 className="font-medium text-red-900 mb-3 flex items-center gap-2">
                  ❌ Rejection Reason
                </h3>
                <textarea
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="Please provide a clear reason for rejection (required)..."
                  className="w-full p-3 border border-red-300 rounded-lg resize-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  rows={3}
                  required
                />
              </div>
            )}

            {/* Impact Analysis */}
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <h3 className="font-medium text-yellow-900 mb-3 flex items-center gap-2">
                📊 Impact Analysis
              </h3>
              <div className="space-y-2 text-sm text-yellow-800">
                <p>• Schedule coverage: {request.daysRequested ? `${request.daysRequested} days affected` : 'Single day impact'}</p>
                <p>• Team capacity: Review for coverage gaps</p>
                <p>• Workload distribution: May require rebalancing</p>
                {request.priority === 'urgent' && (
                  <p className="font-medium">• ⚡ Urgent priority - expedited review recommended</p>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-500">
              💡 Review carefully before making a decision
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Close
              </button>
              <button
                onClick={handleReject}
                className="px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors"
              >
                {showRejectionForm ? 'Confirm Rejection' : 'Reject'}
              </button>
              <button
                onClick={handleApprove}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors shadow-sm"
              >
                {showApprovalForm ? 'Confirm Approval' : 'Approve'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ApprovalDialog;