import React, { ReactNode } from 'react';

interface AdminLayoutProps {
  children: ReactNode;
  currentTab?: string;
  onTabChange?: (tab: string) => void;
}

const AdminLayout: React.FC<AdminLayoutProps> = ({ 
  children, 
  currentTab = 'schedule', 
  onTabChange 
}) => {
  const tabs = [
    { id: 'schedule', label: 'Schedule', icon: '📅' },
    { id: 'shifts', label: 'Shifts', icon: '🕐' },
    { id: 'schemas', label: 'Schemas', icon: '⚙️' },
    { id: 'exceptions', label: 'Exceptions', icon: '📋' },
  ];

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <div className="w-64 bg-slate-800 text-white flex flex-col">
        <div className="p-4 border-b border-slate-700">
          <h1 className="text-lg font-bold text-white">
            Call Center 1010
          </h1>
        </div>
        
        <nav className="flex-1 p-2">
          <div className="w-full flex items-center px-4 py-3 mb-1 rounded-lg bg-slate-700 bg-opacity-50">
            <span className="mr-3 text-xl">📊</span>
            <span>Planning</span>
          </div>
        </nav>

        <div className="p-4 border-t border-slate-700">
          <div className="flex items-center">
            <div className="w-10 h-10 bg-blue-500 rounded-full mr-3 flex items-center justify-center">
              <span className="text-white font-bold">A</span>
            </div>
            <div className="text-sm font-medium">Administrator</div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Top Navigation */}
        <header className="bg-white border-b border-gray-200">
          <div className="px-6 py-3">
            <div className="flex gap-6">
              {tabs.map(tab => (
                <button
                  key={tab.id}
                  onClick={() => onTabChange?.(tab.id)}
                  className={`px-3 py-2 text-sm font-medium flex items-center gap-2 transition-colors ${
                    currentTab === tab.id
                      ? 'text-blue-600 border-b-2 border-blue-600'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <span>{tab.icon}</span>
                  {tab.label}
                </button>
              ))}
            </div>
          </div>
        </header>

        {/* Control Panel */}
        <div className="bg-gray-50 border-b border-gray-200 px-6 py-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900">
              {tabs.find(t => t.id === currentTab)?.label || 'Schedule'}
            </h2>
            <div className="flex items-center gap-3">
              {currentTab === 'schedule' && (
                <>
                  <button 
                    className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm"
                    onClick={() => console.log('Build schedule clicked!')}
                  >
                    ➕ Build
                  </button>
                  <button 
                    className="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm"
                    onClick={() => console.log('FTE calculation clicked!')}
                  >
                    FTE
                  </button>
                </>
              )}
              {currentTab === 'shifts' && (
                <button className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm">
                  ➕ Create Shift
                </button>
              )}
              {currentTab === 'schemas' && (
                <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm">
                  ➕ New Schema
                </button>
              )}
              {currentTab === 'exceptions' && (
                <button className="px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white rounded-md text-sm">
                  ➕ Add Exception
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Main Content Area */}
        <main className="flex-1 overflow-hidden">
          {children}
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;