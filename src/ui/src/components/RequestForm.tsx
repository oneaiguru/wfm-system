import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Calendar, Clock, FileText, AlertTriangle, CheckCircle } from 'lucide-react';

interface RequestFormData {
  type: 'vacation' | 'sick' | 'personal' | 'training';
  startDate: Date;
  endDate: Date;
  reason: string;
  coverageNotes?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const RequestForm: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState<RequestFormData>({
    type: 'vacation',
    startDate: new Date(),
    endDate: new Date(),
    reason: '',
    coverageNotes: ''
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      // Use I's verified vacation request endpoint and format
      const token = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/requests/vacation`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          start_date: formData.startDate.toISOString().split('T')[0],
          end_date: formData.endDate.toISOString().split('T')[0],
          request_type: formData.type,
          reason: formData.reason
        })
      });

      if (response.ok) {
        const result = await response.json();
        setSuccess(true);
        
        // Show success for 2 seconds then navigate
        setTimeout(() => {
          navigate('/requests/history');
        }, 2000);
      } else {
        const errorData = await response.json();
        setError(errorData.message || errorData.detail || 'Failed to submit request');
      }
    } catch (err) {
      setError('Network error. Please try again.');
      console.error('Request submission error:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const calculateDays = () => {
    const diffTime = Math.abs(formData.endDate.getTime() - formData.startDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return diffDays;
  };

  const formatDate = (date: Date) => {
    return date.toISOString().split('T')[0];
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white rounded-lg shadow-sm border p-8 text-center max-w-md">
          <CheckCircle className="h-16 w-16 text-green-600 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Request Submitted!</h2>
          <p className="text-gray-600 mb-4">
            Your {formData.type} request has been submitted successfully.
          </p>
          <p className="text-sm text-gray-500">
            Redirecting to request history...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-3xl mx-auto px-4 py-6">
          <div className="flex items-center gap-3">
            <FileText className="h-6 w-6 text-blue-600" />
            <h1 className="text-2xl font-bold text-gray-900">Submit Time Off Request</h1>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="max-w-3xl mx-auto px-4 py-6">
        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-sm border p-6">
          {/* Request Type */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Request Type
            </label>
            <select 
              name="type"
              value={formData.type}
              onChange={(e) => setFormData({...formData, type: e.target.value as any})}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="vacation">Vacation</option>
              <option value="sick">Sick Leave</option>
              <option value="personal">Personal Time</option>
              <option value="training">Training</option>
            </select>
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Start Date
              </label>
              <input
                name="startDate"
                type="date"
                value={formatDate(formData.startDate)}
                onChange={(e) => setFormData({...formData, startDate: new Date(e.target.value)})}
                min={formatDate(new Date())}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                End Date
              </label>
              <input
                name="endDate"
                type="date"
                value={formatDate(formData.endDate)}
                onChange={(e) => setFormData({...formData, endDate: new Date(e.target.value)})}
                min={formatDate(formData.startDate)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
          </div>

          {/* Days Info */}
          <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-center gap-2">
              <Calendar className="h-5 w-5 text-blue-600" />
              <span className="font-medium text-blue-900">
                Total Days: {calculateDays()}
              </span>
            </div>
          </div>

          {/* Reason */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Reason
            </label>
            <textarea
              value={formData.reason}
              onChange={(e) => setFormData({...formData, reason: e.target.value})}
              placeholder="Please provide a reason for your request..."
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          {/* Coverage Notes */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Coverage Notes (Optional)
            </label>
            <textarea
              value={formData.coverageNotes}
              onChange={(e) => setFormData({...formData, coverageNotes: e.target.value})}
              placeholder="Any notes about coverage arrangements..."
              rows={2}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Error Message */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <div className="flex items-center">
                <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
                <div>
                  <p className="text-red-800 font-medium">Submission Failed</p>
                  <p className="text-red-700 text-sm">{error}</p>
                </div>
              </div>
            </div>
          )}

          {/* Policy Reminders */}
          <div className="mb-6 p-4 bg-gray-50 border border-gray-200 rounded-lg">
            <h4 className="font-medium text-gray-900 mb-2">Policy Reminders:</h4>
            <ul className="text-sm text-gray-700 space-y-1">
              <li>• Vacation requests require 2 weeks advance notice</li>
              <li>• Your remaining balance: 15 days</li>
              <li>• Manager approval required for 3+ consecutive days</li>
            </ul>
          </div>

          {/* Actions */}
          <div className="flex gap-3">
            <button 
              type="button" 
              onClick={() => navigate(-1)}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              disabled={submitting}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {submitting ? (
                <div className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Submitting...
                </div>
              ) : (
                'Submit Request'
              )}
            </button>
          </div>
        </form>

        {/* BDD Compliance Note */}
        <div className="mt-6 text-center">
          <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm">
            <FileText className="h-4 w-4 mr-2" />
            BDD Compliant: Time Off Request Form
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestForm;