import React from 'react';
import ReportsPortal from './ReportsPortal';

// This component demonstrates how to integrate the Reports & Analytics module
// into the main WFM system navigation

interface ReportsIntegrationProps {
  // Integration props that would come from the main system
  userRole: 'admin' | 'manager' | 'supervisor';
  userId: string;
  onNavigateBack?: () => void;
}

const ReportsIntegration: React.FC<ReportsIntegrationProps> = ({
  userRole,
  userId,
  onNavigateBack
}) => {
  // Role-based access control
  const hasAccessToReports = ['admin', 'manager', 'supervisor'].includes(userRole);

  if (!hasAccessToReports) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-6xl mb-4">=</div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Access Restricted</h2>
          <p className="text-gray-600">
            You don't have permission to access Reports & Analytics.
          </p>
          {onNavigateBack && (
            <button
              onClick={onNavigateBack}
              className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Go Back
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      {/* Integration Header - shows connection to main system */}
      {onNavigateBack && (
        <div className="bg-blue-600 text-white px-6 py-2 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <button
              onClick={onNavigateBack}
              className="text-white hover:text-blue-200 transition-colors"
            >
