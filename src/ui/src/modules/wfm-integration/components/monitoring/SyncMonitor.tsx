import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  RefreshCw, 
  CheckCircle, 
  AlertCircle, 
  Clock, 
  Pause, 
  Play, 
  BarChart3,
  Calendar,
  Database,
  TrendingUp,
  AlertTriangle
} from 'lucide-react';
import { SyncStatus } from '../../types/integration';

const SyncMonitor: React.FC = () => {
  const [syncStatuses, setSyncStatuses] = useState<SyncStatus[]>([]);
  const [isUpdating, setIsUpdating] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [selectedTimeRange, setSelectedTimeRange] = useState<'1h' | '24h' | '7d'>('1h');

  useEffect(() => {
    const mockSyncStatuses: SyncStatus[] = [
      {
        systemId: 'sys_001',
        systemName: '1C ZUP Database',
        lastSync: new Date(Date.now() - 5 * 60 * 1000),
        nextSync: new Date(Date.now() + 10 * 60 * 1000),
        status: 'completed',
        progress: 100,
        recordsProcessed: 1247,
        recordsTotal: 1247,
        errors: []
      },
      {
        systemId: 'sys_002',
        systemName: 'Oktell API',
        lastSync: new Date(Date.now() - 2 * 60 * 1000),
        nextSync: new Date(Date.now() + 3 * 60 * 1000),
        status: 'syncing',
        progress: 67,
        recordsProcessed: 597,
        recordsTotal: 892,
        errors: []
      },
      {
        systemId: 'sys_003',
        systemName: 'LDAP Directory',
        lastSync: new Date(Date.now() - 25 * 60 * 1000),
        nextSync: new Date(Date.now() + 35 * 60 * 1000),
        status: 'completed',
        progress: 100,
        recordsProcessed: 1156,
        recordsTotal: 1156,
        errors: []
      },
      {
        systemId: 'sys_004',
        systemName: 'File Transfer System',
        lastSync: new Date(Date.now() - 90 * 60 * 1000),
        nextSync: new Date(Date.now() + 30 * 60 * 1000),
        status: 'failed',
        progress: 0,
        recordsProcessed: 0,
        recordsTotal: 456,
        errors: ['Connection timeout', 'Authentication failed']
      },
      {
        systemId: 'sys_005',
        systemName: 'Message Queue',
        lastSync: new Date(Date.now() - 15 * 60 * 1000),
        nextSync: new Date(Date.now() + 15 * 60 * 1000),
        status: 'pending',
        progress: 0,
        recordsProcessed: 0,
        recordsTotal: 2890,
        errors: []
      }
    ];

    setSyncStatuses(mockSyncStatuses);
  }, []);

  // Real-time updates every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setSyncStatuses(prev => prev.map(status => {
          if (status.status === 'syncing') {
            const newProgress = Math.min(100, status.progress + Math.random() * 15);
            return {
              ...status,
              progress: newProgress,
              recordsProcessed: Math.floor((newProgress / 100) * status.recordsTotal),
              status: newProgress >= 100 ? 'completed' as const : 'syncing' as const
            };
          }
          return status;
        }));
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'syncing': return 'bg-blue-100 text-blue-800';
      case 'failed': return 'bg-red-100 text-red-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'syncing': return <RefreshCw className="h-4 w-4 text-blue-500 animate-spin" />;
      case 'failed': return <AlertCircle className="h-4 w-4 text-red-500" />;
      case 'pending': return <Clock className="h-4 w-4 text-yellow-500" />;
      default: return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const formatTimeUntil = (date: Date) => {
    const now = new Date();
    const diff = date.getTime() - now.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    
    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m`;
    return 'Now';
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  const handleForceSync = (systemId: string) => {
    setSyncStatuses(prev => prev.map(status =>
      status.systemId === systemId
        ? { ...status, status: 'syncing' as const, progress: 0, recordsProcessed: 0 }
        : status
    ));
  };

  const handlePauseSync = (systemId: string) => {
    setSyncStatuses(prev => prev.map(status =>
      status.systemId === systemId
        ? { ...status, status: 'pending' as const }
        : status
    ));
  };

  const stats = {
    total: syncStatuses.length,
    completed: syncStatuses.filter(s => s.status === 'completed').length,
    syncing: syncStatuses.filter(s => s.status === 'syncing').length,
    failed: syncStatuses.filter(s => s.status === 'failed').length,
    pending: syncStatuses.filter(s => s.status === 'pending').length,
    totalRecords: syncStatuses.reduce((sum, s) => sum + s.recordsTotal, 0),
    processedRecords: syncStatuses.reduce((sum, s) => sum + s.recordsProcessed, 0)
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Activity className="h-6 w-6 mr-2 text-blue-600" />
          Sync Monitor
        </h2>
        <p className="mt-2 text-gray-600">
          Monitor real-time synchronization status across all systems
        </p>
      </div>

      {/* Real-time Status Indicator */}
      <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <div className={`w-3 h-3 rounded-full mr-3 ${isUpdating ? 'bg-yellow-500 animate-pulse' : 'bg-green-500'}`} />
            <span className="text-sm font-medium text-gray-900">
              {isUpdating ? 'Updating...' : 'Live Data'}
            </span>
            <span className="text-sm text-gray-500 ml-2">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </span>
          </div>
          <div className="flex items-center space-x-4">
            <select
              value={selectedTimeRange}
              onChange={(e) => setSelectedTimeRange(e.target.value as any)}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="1h">Last 1 hour</option>
              <option value="24h">Last 24 hours</option>
              <option value="7d">Last 7 days</option>
            </select>
            <button className="p-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
              <RefreshCw className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Database className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Systems</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Completed</h3>
              <p className="text-2xl font-bold text-green-600">{stats.completed}</p>
              <p className="text-sm text-gray-600">Synced</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <RefreshCw className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Syncing</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.syncing}</p>
              <p className="text-sm text-gray-600">In Progress</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Failed</h3>
              <p className="text-2xl font-bold text-red-600">{stats.failed}</p>
              <p className="text-sm text-gray-600">Errors</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <TrendingUp className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Records</h3>
              <p className="text-2xl font-bold text-purple-600">{stats.processedRecords.toLocaleString()}</p>
              <p className="text-sm text-gray-600">Processed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Sync Status List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">System Synchronization Status</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {syncStatuses.map((status) => (
            <div key={status.systemId} className="p-6 hover:bg-gray-50">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    {getStatusIcon(status.status)}
                  </div>
                  <div>
                    <h4 className="text-lg font-medium text-gray-900">{status.systemName}</h4>
                    <div className="flex items-center space-x-4 text-sm text-gray-500">
                      <span>Last sync: {formatTimeAgo(status.lastSync)}</span>
                      <span>Next sync: {formatTimeUntil(status.nextSync)}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-3">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(status.status)}`}>
                    {status.status.charAt(0).toUpperCase() + status.status.slice(1)}
                  </span>
                  <div className="flex space-x-2">
                    <button
                      onClick={() => handleForceSync(status.systemId)}
                      className="p-1 text-blue-600 hover:text-blue-800"
                      title="Force Sync"
                    >
                      <RefreshCw className="h-4 w-4" />
                    </button>
                    {status.status === 'syncing' ? (
                      <button
                        onClick={() => handlePauseSync(status.systemId)}
                        className="p-1 text-yellow-600 hover:text-yellow-800"
                        title="Pause Sync"
                      >
                        <Pause className="h-4 w-4" />
                      </button>
                    ) : (
                      <button
                        onClick={() => handleForceSync(status.systemId)}
                        className="p-1 text-green-600 hover:text-green-800"
                        title="Start Sync"
                      >
                        <Play className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* Progress Bar */}
              <div className="mb-4">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm font-medium text-gray-700">
                    Progress: {status.recordsProcessed.toLocaleString()} / {status.recordsTotal.toLocaleString()} records
                  </span>
                  <span className="text-sm font-medium text-gray-700">
                    {status.progress}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full transition-all duration-300 ${
                      status.status === 'completed' ? 'bg-green-500' :
                      status.status === 'syncing' ? 'bg-blue-500' :
                      status.status === 'failed' ? 'bg-red-500' :
                      'bg-yellow-500'
                    }`}
                    style={{ width: `${status.progress}%` }}
                  />
                </div>
              </div>

              {/* Errors */}
              {status.errors.length > 0 && (
                <div className="bg-red-50 border border-red-200 rounded-md p-3">
                  <div className="flex items-center">
                    <AlertTriangle className="h-4 w-4 text-red-600 mr-2" />
                    <span className="text-sm font-medium text-red-800">Errors:</span>
                  </div>
                  <ul className="mt-2 text-sm text-red-700">
                    {status.errors.map((error, index) => (
                      <li key={index} className="ml-6">• {error}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* System Performance Chart */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Sync Performance Overview</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-blue-50 p-4 rounded-lg">
            <div className="flex items-center">
              <BarChart3 className="h-5 w-5 text-blue-600 mr-2" />
              <span className="text-sm font-medium text-blue-800">Total Records Processed</span>
            </div>
            <p className="text-2xl font-bold text-blue-600 mt-2">
              {stats.processedRecords.toLocaleString()}
            </p>
          </div>

          <div className="bg-green-50 p-4 rounded-lg">
            <div className="flex items-center">
              <TrendingUp className="h-5 w-5 text-green-600 mr-2" />
              <span className="text-sm font-medium text-green-800">Success Rate</span>
            </div>
            <p className="text-2xl font-bold text-green-600 mt-2">
              {((stats.completed / stats.total) * 100).toFixed(1)}%
            </p>
          </div>

          <div className="bg-purple-50 p-4 rounded-lg">
            <div className="flex items-center">
              <Calendar className="h-5 w-5 text-purple-600 mr-2" />
              <span className="text-sm font-medium text-purple-800">Average Sync Time</span>
            </div>
            <p className="text-2xl font-bold text-purple-600 mt-2">
              3.2 min
            </p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Force Sync All</h4>
            <p className="text-sm text-gray-600 mt-1">Trigger synchronization for all systems</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Schedule Sync</h4>
            <p className="text-sm text-gray-600 mt-1">Configure automatic sync intervals</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Export Report</h4>
            <p className="text-sm text-gray-600 mt-1">Download sync performance report</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default SyncMonitor;