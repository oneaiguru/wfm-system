import React, { useState } from 'react';
import { Users, UserPlus, Search, BarChart3, Settings, Eye, Grid, List, Award } from 'lucide-react';
import EmployeeListContainer from './crud/EmployeeListContainer';
import EmployeePhotoGallery from './admin/EmployeePhotoGallery';
import PerformanceMetricsView from './analytics/PerformanceMetricsView';
import QuickAddEmployee from './crud/QuickAddEmployee';
import EmployeeStatusManager from './admin/EmployeeStatusManager';
import CertificationTracker from './admin/CertificationTracker';

interface EmployeeManagementPortalProps {
  currentView?: string;
  onViewChange?: (view: string) => void;
}

const EmployeeManagementPortal: React.FC<EmployeeManagementPortalProps> = ({ 
  currentView = 'list',
  onViewChange 
}) => {
  const [viewMode, setViewMode] = useState<'list' | 'grid' | 'gallery'>('list');
  const [totalEmployees] = useState(247);
  const [activeEmployees] = useState(221);
  const [newHires] = useState(8);

  const navigationItems = [
    { id: 'list', label: 'Employee List', icon: List },
    { id: 'add', label: 'Quick Add', icon: UserPlus },
    { id: 'gallery', label: 'Photo Gallery', icon: Eye },
    { id: 'performance', label: 'Performance', icon: BarChart3 },
    { id: 'status', label: 'Status Manager', icon: Settings },
    { id: 'certifications', label: 'Certifications', icon: Award },
  ];

  const renderContent = () => {
    switch (currentView) {
      case 'list':
        return <EmployeeListContainer viewMode={viewMode} />;
      case 'add':
        return <QuickAddEmployee />;
      case 'gallery':
        return <EmployeePhotoGallery />;
      case 'performance':
        return <PerformanceMetricsView />;
      case 'status':
        return <EmployeeStatusManager />;
      case 'certifications':
        return <CertificationTracker />;
      default:
        return <EmployeeListContainer viewMode={viewMode} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-gray-900">
                Employee Management
              </h1>
              <div className="ml-8 flex items-center space-x-6">
                <div className="flex items-center text-sm">
                  <Users className="h-4 w-4 text-gray-400 mr-1" />
                  <span className="text-gray-600">Total: </span>
                  <span className="font-medium text-gray-900">{totalEmployees}</span>
                </div>
                <div className="flex items-center text-sm">
                  <div className="h-2 w-2 bg-green-500 rounded-full mr-2" />
                  <span className="text-gray-600">Active: </span>
                  <span className="font-medium text-green-600">{activeEmployees}</span>
                </div>
                <div className="flex items-center text-sm">
                  <div className="h-2 w-2 bg-blue-500 rounded-full mr-2" />
                  <span className="text-gray-600">New: </span>
                  <span className="font-medium text-blue-600">{newHires}</span>
                </div>
              </div>
            </div>
            
            {/* View Mode Selector (only for list view) */}
            {currentView === 'list' && (
              <div className="flex items-center space-x-2">
                <span className="text-sm text-gray-600">View:</span>
                <div className="flex rounded-md border border-gray-300">
                  <button
                    onClick={() => setViewMode('list')}
                    className={`px-3 py-1 text-sm ${
                      viewMode === 'list' 
                        ? 'bg-blue-500 text-white' 
                        : 'bg-white text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <List className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => setViewMode('grid')}
                    className={`px-3 py-1 text-sm border-l border-gray-300 ${
                      viewMode === 'grid' 
                        ? 'bg-blue-500 text-white' 
                        : 'bg-white text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <Grid className="h-4 w-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="flex h-[calc(100vh-4rem)]">
        {/* Sidebar Navigation */}
        <div className="w-64 bg-white shadow-md">
          <nav className="mt-5 px-2">
            {navigationItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentView === item.id;
              
              return (
                <button
                  key={item.id}
                  onClick={() => onViewChange?.(item.id)}
                  className={`
                    w-full group flex items-center px-2 py-2 text-sm font-medium rounded-md mb-1
                    ${isActive 
                      ? 'bg-blue-100 text-blue-900' 
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                    }
                  `}
                >
                  <Icon className={`
                    mr-3 h-5 w-5
                    ${isActive ? 'text-blue-600' : 'text-gray-400 group-hover:text-gray-500'}
                  `} />
                  {item.label}
                </button>
              );
            })}
          </nav>

          {/* Quick Stats */}
          <div className="mt-8 px-4">
            <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg p-4 text-white">
              <h3 className="text-sm font-semibold mb-3">Quick Stats</h3>
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs">Active Rate</span>
                  <span className="text-lg font-bold">89.5%</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">Avg Performance</span>
                  <span className="text-lg font-bold">92.1%</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">Teams</span>
                  <span className="text-lg font-bold">12</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">Certifications</span>
                  <span className="text-lg font-bold">184</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          <div className="p-6">
            {renderContent()}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeManagementPortal;