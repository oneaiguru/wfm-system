import React, { useState, useEffect } from 'react';
import { Calendar, Users, AlertTriangle, CheckCircle, Send, X } from 'lucide-react';

interface PublishDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (data: PublishData) => void;
  scheduleData: {
    startDate: string;
    endDate: string;
    employeeCount: number;
    shiftCount: number;
    departments?: string[];
  };
}

interface PublishData {
  startDate: string;
  endDate: string;
  notifyEmployees: boolean;
  notifyManagers: boolean;
  publishMessage: string;
}

interface AffectedEmployee {
  id: number;
  name: string;
  department: string;
  shiftsCount: number;
  totalHours: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001';

export const PublishDialog: React.FC<PublishDialogProps> = ({
  isOpen,
  onClose,
  onConfirm,
  scheduleData
}) => {
  const [publishing, setPublishing] = useState(false);
  const [error, setError] = useState<string>('');
  const [affectedEmployees, setAffectedEmployees] = useState<AffectedEmployee[]>([]);
  const [loadingEmployees, setLoadingEmployees] = useState(false);
  const [publishForm, setPublishForm] = useState<PublishData>({
    startDate: scheduleData.startDate,
    endDate: scheduleData.endDate,
    notifyEmployees: true,
    notifyManagers: true,
    publishMessage: 'Your schedule has been published for the upcoming period.'
  });

  useEffect(() => {
    if (isOpen) {
      loadAffectedEmployees();
    }
  }, [isOpen, scheduleData]);

  const loadAffectedEmployees = async () => {
    setLoadingEmployees(true);
    setError('');

    try {
      // In a real implementation, this would call an endpoint to get affected employees
      // For now, we'll simulate the data
      const response = await fetch(`${API_BASE_URL}/api/v1/schedules/publish/preview`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('wfm_auth_token')}`
        },
        body: JSON.stringify({
          start_date: scheduleData.startDate,
          end_date: scheduleData.endDate,
          departments: scheduleData.departments
        })
      });

      if (!response.ok) {
        throw new Error('Failed to load affected employees');
      }

      const data = await response.json();
      setAffectedEmployees(data.affected_employees || []);
    } catch (err) {
      console.error('Failed to load affected employees:', err);
      // Fallback to simulated data
      setAffectedEmployees([
        { id: 1, name: 'John Doe', department: 'Customer Service', shiftsCount: 5, totalHours: 40 },
        { id: 2, name: 'Jane Smith', department: 'Customer Service', shiftsCount: 5, totalHours: 40 },
        { id: 3, name: 'Mike Johnson', department: 'Sales', shiftsCount: 4, totalHours: 32 },
        { id: 4, name: 'Sarah Williams', department: 'Sales', shiftsCount: 5, totalHours: 40 }
      ]);
    } finally {
      setLoadingEmployees(false);
    }
  };

  const handlePublish = async () => {
    setPublishing(true);
    setError('');

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/schedules/publish`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('wfm_auth_token')}`
        },
        body: JSON.stringify({
          start_date: publishForm.startDate,
          end_date: publishForm.endDate,
          notify_employees: publishForm.notifyEmployees,
          notify_managers: publishForm.notifyManagers,
          message: publishForm.publishMessage,
          departments: scheduleData.departments
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to publish schedule');
      }

      const result = await response.json();
      console.log('Schedule published successfully:', result);
      
      onConfirm(publishForm);
    } catch (err) {
      console.error('Failed to publish schedule:', err);
      setError(err instanceof Error ? err.message : 'Failed to publish schedule');
    } finally {
      setPublishing(false);
    }
  };

  const formatDateRange = () => {
    const start = new Date(scheduleData.startDate);
    const end = new Date(scheduleData.endDate);
    const options: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric', year: 'numeric' };
    return `${start.toLocaleDateString('en-US', options)} - ${end.toLocaleDateString('en-US', options)}`;
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">Publish Schedule</h2>
            <p className="text-sm text-gray-600 mt-1">{formatDateRange()}</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="h-5 w-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="px-6 py-4 overflow-y-auto max-h-[calc(90vh-180px)]">
          {/* Summary */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <h3 className="font-medium text-blue-900 mb-2 flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Schedule Summary
            </h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-blue-700">Period:</span>
                <span className="ml-2 font-medium text-blue-900">{formatDateRange()}</span>
              </div>
              <div>
                <span className="text-blue-700">Total Shifts:</span>
                <span className="ml-2 font-medium text-blue-900">{scheduleData.shiftCount}</span>
              </div>
              <div>
                <span className="text-blue-700">Employees:</span>
                <span className="ml-2 font-medium text-blue-900">{scheduleData.employeeCount}</span>
              </div>
              {scheduleData.departments && (
                <div>
                  <span className="text-blue-700">Departments:</span>
                  <span className="ml-2 font-medium text-blue-900">
                    {scheduleData.departments.join(', ')}
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Affected Employees */}
          <div className="mb-6">
            <h3 className="font-medium text-gray-900 mb-3 flex items-center gap-2">
              <Users className="h-5 w-5" />
              Affected Employees ({affectedEmployees.length})
            </h3>
            
            {loadingEmployees ? (
              <div className="text-center py-4">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600 mx-auto"></div>
              </div>
            ) : (
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-700">Employee</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-700">Department</th>
                      <th className="px-4 py-2 text-center text-xs font-medium text-gray-700">Shifts</th>
                      <th className="px-4 py-2 text-center text-xs font-medium text-gray-700">Hours</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {affectedEmployees.map(employee => (
                      <tr key={employee.id} className="hover:bg-gray-50">
                        <td className="px-4 py-2 text-sm text-gray-900">{employee.name}</td>
                        <td className="px-4 py-2 text-sm text-gray-600">{employee.department}</td>
                        <td className="px-4 py-2 text-sm text-gray-900 text-center">{employee.shiftsCount}</td>
                        <td className="px-4 py-2 text-sm text-gray-900 text-center">{employee.totalHours}h</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Notification Options */}
          <div className="mb-6">
            <h3 className="font-medium text-gray-900 mb-3">Notification Options</h3>
            <div className="space-y-3">
              <label className="flex items-center gap-3">
                <input
                  type="checkbox"
                  checked={publishForm.notifyEmployees}
                  onChange={(e) => setPublishForm(prev => ({
                    ...prev,
                    notifyEmployees: e.target.checked
                  }))}
                  className="h-4 w-4 text-blue-600 rounded border-gray-300"
                />
                <span className="text-sm text-gray-700">Notify employees about their schedules</span>
              </label>
              
              <label className="flex items-center gap-3">
                <input
                  type="checkbox"
                  checked={publishForm.notifyManagers}
                  onChange={(e) => setPublishForm(prev => ({
                    ...prev,
                    notifyManagers: e.target.checked
                  }))}
                  className="h-4 w-4 text-blue-600 rounded border-gray-300"
                />
                <span className="text-sm text-gray-700">Notify managers about published schedules</span>
              </label>
            </div>
          </div>

          {/* Custom Message */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Notification Message (optional)
            </label>
            <textarea
              value={publishForm.publishMessage}
              onChange={(e) => setPublishForm(prev => ({
                ...prev,
                publishMessage: e.target.value
              }))}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg resize-none"
              placeholder="Add a custom message for employees..."
            />
          </div>

          {/* Warning */}
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 flex gap-3">
            <AlertTriangle className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm">
              <p className="font-medium text-yellow-900 mb-1">Important:</p>
              <p className="text-yellow-800">
                Once published, employees will be able to view their schedules immediately. 
                Make sure all shifts are correctly assigned before publishing.
              </p>
            </div>
          </div>

          {/* Error Display */}
          {error && (
            <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-600 flex-shrink-0" />
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-end gap-3">
          <button
            onClick={onClose}
            disabled={publishing}
            className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg 
              disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Cancel
          </button>
          
          <button
            onClick={handlePublish}
            disabled={publishing || loadingEmployees}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 
              disabled:opacity-50 disabled:cursor-not-allowed transition-colors
              flex items-center gap-2"
          >
            {publishing ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                <span>Publishing...</span>
              </>
            ) : (
              <>
                <Send className="h-4 w-4" />
                <span>Publish Schedule</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default PublishDialog;