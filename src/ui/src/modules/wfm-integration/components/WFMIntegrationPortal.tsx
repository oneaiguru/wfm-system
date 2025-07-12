import React, { useState, useEffect } from 'react';
import { 
  Link2, 
  Database, 
  Settings, 
  Activity, 
  AlertCircle, 
  CheckCircle, 
  Clock, 
  TrendingUp,
  Server,
  Zap,
  Globe,
  Shield
} from 'lucide-react';

interface WFMIntegrationPortalProps {
  currentView?: string;
  onViewChange?: (view: string) => void;
}

const WFMIntegrationPortal: React.FC<WFMIntegrationPortalProps> = ({ 
  currentView = 'dashboard', 
  onViewChange = () => {} 
}) => {
  const [isUpdating, setIsUpdating] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [systemStats, setSystemStats] = useState({
    totalConnections: 12,
    activeConnections: 9,
    failedConnections: 1,
    testingConnections: 2,
    totalMappings: 156,
    activeMappings: 142,
    syncOperations: 23847,
    errorRate: 0.02
  });

  // Real-time updates every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setLastUpdate(new Date());
        setSystemStats(prev => ({
          ...prev,
          syncOperations: prev.syncOperations + Math.floor(Math.random() * 10) + 1,
          errorRate: Math.max(0, prev.errorRate + (Math.random() - 0.5) * 0.001)
        }));
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const navigationItems = [
    { id: 'dashboard', label: 'Integration Dashboard', icon: TrendingUp },
    { id: 'connectors', label: 'System Connectors', icon: Link2 },
    { id: 'mappings', label: 'Data Mapping', icon: Database },
    { id: 'monitor', label: 'Sync Monitor', icon: Activity },
    { id: 'settings', label: 'API Settings', icon: Settings },
    { id: 'logs', label: 'Integration Logs', icon: Clock }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'testing': return 'bg-yellow-100 text-yellow-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'testing': return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'error': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Server className="h-4 w-4 text-gray-500" />;
    }
  };

  const renderDashboard = () => (
    <div className="space-y-6">
      {/* System Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Link2 className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total Connections</h3>
              <p className="text-2xl font-bold text-blue-600">{systemStats.totalConnections}</p>
              <p className="text-sm text-gray-600">Integration Points</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{systemStats.activeConnections}</p>
              <p className="text-sm text-gray-600">Running Systems</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Database className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Data Mappings</h3>
              <p className="text-2xl font-bold text-purple-600">{systemStats.totalMappings}</p>
              <p className="text-sm text-gray-600">Field Mappings</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Activity className="h-8 w-8 text-orange-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Sync Operations</h3>
              <p className="text-2xl font-bold text-orange-600">{systemStats.syncOperations.toLocaleString()}</p>
              <p className="text-sm text-gray-600">Total Processed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Real-time Status */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">System Status</h3>
          <div className="flex items-center space-x-2">
            <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-yellow-500 animate-pulse' : 'bg-green-500'}`} />
            <span className="text-sm text-gray-600">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-green-50 p-4 rounded-lg">
            <div className="flex items-center">
              <CheckCircle className="h-5 w-5 text-green-600 mr-2" />
              <span className="text-sm font-medium text-green-800">Healthy Systems</span>
            </div>
            <p className="text-2xl font-bold text-green-600 mt-2">
              {systemStats.activeConnections}/{systemStats.totalConnections}
            </p>
          </div>

          <div className="bg-yellow-50 p-4 rounded-lg">
            <div className="flex items-center">
              <Clock className="h-5 w-5 text-yellow-600 mr-2" />
              <span className="text-sm font-medium text-yellow-800">In Testing</span>
            </div>
            <p className="text-2xl font-bold text-yellow-600 mt-2">
              {systemStats.testingConnections}
            </p>
          </div>

          <div className="bg-red-50 p-4 rounded-lg">
            <div className="flex items-center">
              <AlertCircle className="h-5 w-5 text-red-600 mr-2" />
              <span className="text-sm font-medium text-red-800">Error Rate</span>
            </div>
            <p className="text-2xl font-bold text-red-600 mt-2">
              {(systemStats.errorRate * 100).toFixed(2)}%
            </p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button 
            onClick={() => onViewChange('connectors')}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left"
          >
            <div className="flex items-center">
              <Link2 className="h-5 w-5 text-blue-600 mr-3" />
              <div>
                <h4 className="font-medium text-gray-900">Add Connection</h4>
                <p className="text-sm text-gray-600 mt-1">Connect new system</p>
              </div>
            </div>
          </button>

          <button 
            onClick={() => onViewChange('mappings')}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left"
          >
            <div className="flex items-center">
              <Database className="h-5 w-5 text-purple-600 mr-3" />
              <div>
                <h4 className="font-medium text-gray-900">Map Data Fields</h4>
                <p className="text-sm text-gray-600 mt-1">Configure data mapping</p>
              </div>
            </div>
          </button>

          <button 
            onClick={() => onViewChange('monitor')}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left"
          >
            <div className="flex items-center">
              <Activity className="h-5 w-5 text-orange-600 mr-3" />
              <div>
                <h4 className="font-medium text-gray-900">Monitor Sync</h4>
                <p className="text-sm text-gray-600 mt-1">Check sync status</p>
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  );

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return renderDashboard();
      case 'connectors':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">System Connectors</h3>
            <p className="text-gray-600">Manage system connections and integration points.</p>
          </div>
        );
      case 'mappings':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Data Mapping</h3>
            <p className="text-gray-600">Configure data field mappings between systems.</p>
          </div>
        );
      case 'monitor':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Sync Monitor</h3>
            <p className="text-gray-600">Monitor real-time synchronization status.</p>
          </div>
        );
      case 'settings':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">API Settings</h3>
            <p className="text-gray-600">Configure API endpoints and authentication.</p>
          </div>
        );
      case 'logs':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Integration Logs</h3>
            <p className="text-gray-600">View integration logs and activity history.</p>
          </div>
        );
      default:
        return renderDashboard();
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-sm border-r border-gray-200">
        <div className="p-6">
          <h1 className="text-xl font-bold text-gray-900 flex items-center">
            <Zap className="h-6 w-6 mr-2 text-blue-600" />
            WFM Integration
          </h1>
          <p className="text-sm text-gray-600 mt-1">System Integration Hub</p>
        </div>

        <nav className="mt-6">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => onViewChange(item.id)}
                className={`w-full flex items-center px-6 py-3 text-left hover:bg-gray-50 ${
                  currentView === item.id ? 'bg-blue-50 text-blue-600 border-r-2 border-blue-600' : 'text-gray-700'
                }`}
              >
                <Icon className="h-5 w-5 mr-3" />
                <span className="text-sm font-medium">{item.label}</span>
              </button>
            );
          })}
        </nav>

        {/* System Health Indicator */}
        <div className="absolute bottom-4 left-4 right-4">
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-2" />
              <span className="text-sm text-gray-600">All Systems Operational</span>
            </div>
            <div className="mt-2 text-xs text-gray-500">
              Uptime: 99.9% | Latency: 45ms
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <div className="p-6">
          {renderCurrentView()}
        </div>
      </div>
    </div>
  );
};

export default WFMIntegrationPortal;