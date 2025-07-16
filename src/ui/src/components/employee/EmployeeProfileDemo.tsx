import React from 'react';
import EmployeeProfile from './EmployeeProfile';

/**
 * Demo page to test the EmployeeProfile component
 * Access at: http://localhost:3000/employee-profile-demo
 */
const EmployeeProfileDemo: React.FC = () => {
  const handleEdit = () => {
    alert('Edit functionality will be implemented in the future');
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="py-8">
        <div className="max-w-6xl mx-auto px-4">
          <h1 className="text-3xl font-bold text-gray-900 mb-8 text-center">
            Employee Profile Component Demo
          </h1>
          
          <div className="space-y-8">
            {/* Test with employee ID 1 (we know this exists from our curl test) */}
            <div>
              <h2 className="text-xl font-semibold text-gray-800 mb-4">
                Employee ID: 1 (Anna Kuznetsova)
              </h2>
              <EmployeeProfile employeeId="1" onEdit={handleEdit} />
            </div>
            
            {/* Test with non-existent employee */}
            <div>
              <h2 className="text-xl font-semibold text-gray-800 mb-4">
                Non-existent Employee (ID: 999)
              </h2>
              <EmployeeProfile employeeId="999" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeProfileDemo;