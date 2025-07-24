import React, { useState } from 'react';
import RequestForm from './RequestForm';
import RequestList from './RequestList';

interface RequestManagerProps {
  employeeId: string;
}

interface RequestFormData {
  id?: string;
  type: 'vacation' | 'sick_leave' | 'time_off' | 'shift_change' | 'overtime' | '';
  title: string;
  startDate: string;
  endDate: string;
  reason: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  attachments: File[];
  additionalInfo: {
    emergencyContact?: string;
    halfDay?: boolean;
    currentShift?: string;
    requestedShift?: string;
    medicalCertificate?: boolean;
    overtimeHours?: number;
  };
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

const RequestManager: React.FC<RequestManagerProps> = ({ employeeId }) => {
  const [showRequestForm, setShowRequestForm] = useState(false);
  const [editingRequest, setEditingRequest] = useState<RequestFormData | undefined>();
  const [viewingRequest, setViewingRequest] = useState<Request | undefined>();

  const handleNewRequest = () => {
    setEditingRequest(undefined);
    setShowRequestForm(true);
  };

  const handleEditRequest = (request: Request) => {
    // Convert Request to RequestFormData format
    const formData: RequestFormData = {
      id: request.id,
      type: request.type,
      title: request.title,
      startDate: request.startDate.toISOString().split('T')[0],
      endDate: request.endDate?.toISOString().split('T')[0] || '',
      reason: request.reason,
      priority: request.priority,
      attachments: [], // Files would need to be loaded from server
      additionalInfo: {}
    };
    
    setEditingRequest(formData);
    setShowRequestForm(true);
  };

  const handleViewRequest = (request: Request) => {
    setViewingRequest(request);
  };

  const handleFormSubmit = (requestData: RequestFormData) => {
    console.log('Submitting request:', requestData);
    // In a real app, this would call an API to save the request
    setShowRequestForm(false);
    setEditingRequest(undefined);
  };

  const handleCloseForm = () => {
    setShowRequestForm(false);
    setEditingRequest(undefined);
  };

  const handleCloseView = () => {
    setViewingRequest(undefined);
  };

  return (
    <div className="p-6">
      <RequestList
        employeeId={employeeId}
        onNewRequest={handleNewRequest}
        onEditRequest={handleEditRequest}
        onViewRequest={handleViewRequest}
      />

      {/* Request Form Modal */}
      <RequestForm
        isOpen={showRequestForm}
        onClose={handleCloseForm}
        onSubmit={handleFormSubmit}
        editRequest={editingRequest}
      />

      {/* Request View Modal */}
      {viewingRequest && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold text-gray-900">
                  Request Details
                </h2>
                <button
                  onClick={handleCloseView}
                  className="text-gray-400 hover:text-gray-600 transition-colors"
                >
                  
                </button>
              </div>
            </div>

            {/* Content */}
            <div className="px-6 py-6 overflow-y-auto max-h-[70vh]">
              <div className="space-y-6">
                {/* Request Info */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="font-medium text-gray-900 mb-3">Request Information</h3>
                  <dl className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Type:</dt>
                      <dd className="font-medium">{viewingRequest.type.replace('_', ' ')}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Title:</dt>
                      <dd className="font-medium">{viewingRequest.title}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Status:</dt>
                      <dd className="font-medium">{viewingRequest.status.replace('_', ' ')}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Priority:</dt>
                      <dd className="font-medium">{viewingRequest.priority}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Start Date:</dt>
                      <dd className="font-medium">{viewingRequest.startDate.toLocaleDateString()}</dd>
                    </div>
                    {viewingRequest.endDate && (
                      <div className="flex justify-between">
                        <dt className="text-gray-600">End Date:</dt>
                        <dd className="font-medium">{viewingRequest.endDate.toLocaleDateString()}</dd>
                      </div>
                    )}
                    {viewingRequest.daysRequested && (
                      <div className="flex justify-between">
                        <dt className="text-gray-600">Days Requested:</dt>
                        <dd className="font-medium">{viewingRequest.daysRequested}</dd>
                      </div>
                    )}
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Submitted:</dt>
                      <dd className="font-medium">{viewingRequest.submittedAt.toLocaleDateString()}</dd>
                    </div>
                  </dl>
                </div>

                {/* Reason */}
                <div>
                  <h3 className="font-medium text-gray-900 mb-2">Reason</h3>
                  <p className="text-sm text-gray-600 bg-gray-50 p-3 rounded">
                    {viewingRequest.reason}
                  </p>
                </div>

                {/* Approver Comments */}
                {viewingRequest.approver && (
                  <div>
                    <h3 className="font-medium text-gray-900 mb-2">Approval Information</h3>
                    <div className="bg-gray-50 p-3 rounded">
                      <p className="text-sm text-gray-600 mb-1">
                        <strong>Reviewed by:</strong> {viewingRequest.approver.name}
                      </p>
                      {viewingRequest.approver.comments && (
                        <p className="text-sm text-gray-600">
                          <strong>Comments:</strong> {viewingRequest.approver.comments}
                        </p>
                      )}
                    </div>
                  </div>
                )}

                {/* Action Required */}
                {viewingRequest.actionRequired && (
                  <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                    <div className="flex items-center gap-2">
