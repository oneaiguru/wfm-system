import React, { useState } from 'react';
import EmployeeLayout from './layout/EmployeeLayout';
import PersonalDashboard from './dashboard/PersonalDashboard';
import ShiftMarketplace from './requests/ShiftMarketplace';
import RequestManager from './requests/RequestManager';
import ProfileManager from './profile/ProfileManager';
import PersonalSchedule from './schedule/PersonalSchedule';

interface EmployeePortalProps {
  employeeId?: string;
}

const EmployeePortal: React.FC<EmployeePortalProps> = ({ 
  employeeId = '1' 
}) => {
  const [currentView, setCurrentView] = useState('dashboard');

  const renderContent = () => {
    switch (currentView) {
      case 'dashboard':
        return <PersonalDashboard employeeId={employeeId} />;
      case 'schedule':
        return <PersonalSchedule employeeId={employeeId} />;
      case 'requests':
        return <RequestManager employeeId={employeeId} />;
      case 'marketplace':
        return <ShiftMarketplace currentEmployeeId={employeeId} />;
      case 'profile':
        return <ProfileManager employeeId={employeeId} />;
      default:
        return <PersonalDashboard employeeId={employeeId} />;
    }
  };

  return (
    <EmployeeLayout 
      currentView={currentView} 
      onViewChange={setCurrentView}
    >
      {renderContent()}
    </EmployeeLayout>
  );
};

export default EmployeePortal;