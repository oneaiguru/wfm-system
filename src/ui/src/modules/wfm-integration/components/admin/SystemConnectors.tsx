import React, { useState, useEffect } from 'react';
import { 
  Link2, 
  Database, 
  Globe, 
  Server, 
  CheckCircle, 
  AlertCircle, 
  Clock, 
  Settings, 
  Plus,
  Edit,
  Trash2,
  TestTube,
  Eye,
  RefreshCw,
  Sync,
  Download,
  Upload
} from 'lucide-react';
import realReferenceDataService, { SystemConnection } from '../../../../services/realReferenceDataService';

const SystemConnectors: React.FC = () => {
  const [connections, setConnections] = useState<SystemConnection[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'error'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [syncingConnections, setSyncingConnections] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadSystemConnections();
  }, []);

  const loadSystemConnections = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realReferenceDataService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realReferenceDataService.getSystemConnections();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded system connections:', result.data);
        setConnections(result.data);
      } else {
        setApiError(result.error || 'Failed to load system connections');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load system connections:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredConnections = connections.filter(conn => {
    const matchesFilter = filter === 'all' || conn.status === filter;
    const matchesSearch = 
      conn.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conn.type.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conn.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

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

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'database': return <Database className="h-5 w-5 text-blue-600" />;
      case 'api': return <Globe className="h-5 w-5 text-green-600" />;
      case 'file': return <Server className="h-5 w-5 text-purple-600" />;
      case 'queue': return <Link2 className="h-5 w-5 text-orange-600" />;
      default: return <Server className="h-5 w-5 text-gray-600" />;
    }
  };

  const getTimeSinceSync = (lastSync: Date) => {
    const now = new Date();
    const diff = now.getTime() - lastSync.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  const handleTestConnection = async (connectionId: string) => {
    setApiError('');
    setIsConnecting(true);
    
    // Update UI to show testing status
    setConnections(prev => prev.map(conn =>
      conn.id === connectionId
        ? { ...conn, status: 'testing' as const }
        : conn
    ));

    try {
      const result = await realReferenceDataService.testSystemConnection(connectionId);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Test result:', result.data);
        
        // Update connection with real test results
        setConnections(prev => prev.map(conn =>
          conn.id === connectionId
            ? { 
                ...conn, 
                status: result.data!.success ? 'active' as const : 'error' as const,
                lastSync: new Date()
              }
            : conn
        ));
        
        // Also refresh connection stats
        await refreshConnectionStats(connectionId);
      } else {
        setApiError(result.error || 'Connection test failed');
        // Set status back to error on failure
        setConnections(prev => prev.map(conn =>
          conn.id === connectionId
            ? { ...conn, status: 'error' as const }
            : conn
        ));
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Test failed';
      setApiError(errorMessage);
      // Set status back to error on exception
      setConnections(prev => prev.map(conn =>
        conn.id === connectionId
          ? { ...conn, status: 'error' as const }
          : conn
      ));
    } finally {
      setIsConnecting(false);
    }
  };

  const refreshConnectionStats = async (connectionId: string) => {
    try {
      const result = await realReferenceDataService.getConnectionStats(connectionId);
      
      if (result.success && result.data) {
        setConnections(prev => prev.map(conn =>
          conn.id === connectionId
            ? { 
                ...conn, 
                syncCount: result.data!.totalSyncs,
                errorCount: Math.round((1 - result.data!.successRate / 100) * result.data!.totalSyncs)
              }
            : conn
        ));
      }
    } catch (error) {
      console.error('[REAL COMPONENT] Failed to refresh stats:', error);
    }
  };

  const handleTriggerSync = async (connectionId: string) => {
    setApiError('');
    setSyncingConnections(prev => new Set([...prev, connectionId]));
    
    try {
      const result = await realReferenceDataService.triggerSync(connectionId);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Sync triggered:', result.data);
        // Update last sync time
        setConnections(prev => prev.map(conn =>
          conn.id === connectionId
            ? { ...conn, lastSync: new Date() }
            : conn
        ));
      } else {
        setApiError(result.error || 'Failed to trigger sync');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Sync trigger failed';
      setApiError(errorMessage);
    } finally {
      setSyncingConnections(prev => {
        const newSet = new Set(prev);
        newSet.delete(connectionId);
        return newSet;
      });
    }
  };

  const handleDeleteConnection = async (connectionId: string) => {
    if (!window.confirm('Are you sure you want to delete this connection?')) {
      return;
    }
    
    setApiError('');
    
    try {
      const result = await realReferenceDataService.deleteSystemConnection(connectionId);
      
      if (result.success) {
        console.log('[REAL COMPONENT] Connection deleted:', connectionId);
        setConnections(prev => prev.filter(conn => conn.id !== connectionId));
      } else {
        setApiError(result.error || 'Failed to delete connection');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Delete failed';
      setApiError(errorMessage);
    }
  };

  const handleTestAllConnections = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      const testPromises = connections.map(conn => handleTestConnection(conn.id));
      await Promise.all(testPromises);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to test all connections';
      setApiError(errorMessage);
    } finally {
      setIsConnecting(false);
    }
  };

  const stats = {
    total: connections.length,
    active: connections.filter(c => c.status === 'active').length,
    testing: connections.filter(c => c.status === 'testing').length,
    error: connections.filter(c => c.status === 'error').length,
    inactive: connections.filter(c => c.status === 'inactive').length
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Link2 className="h-6 w-6 mr-2 text-blue-600" />
          System Connectors
        </h2>
        <p className="mt-2 text-gray-600">
          Manage connections to external systems and data sources
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Server className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Connections</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{stats.active}</p>
              <p className="text-sm text-gray-600">Running</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Testing</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.testing}</p>
              <p className="text-sm text-gray-600">In Progress</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Errors</h3>
              <p className="text-2xl font-bold text-red-600">{stats.error}</p>
              <p className="text-sm text-gray-600">Need Attention</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Settings className="h-8 w-8 text-gray-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Inactive</h3>
              <p className="text-2xl font-bold text-gray-600">{stats.inactive}</p>
              <p className="text-sm text-gray-600">Disabled</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search connections..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-4 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Connections</option>
              <option value="active">Active</option>
              <option value="testing">Testing</option>
              <option value="error">Error</option>
              <option value="inactive">Inactive</option>
            </select>

            <span className="text-sm text-gray-600">
              {filteredConnections.length} connections
            </span>
          </div>

          <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Add Connection
          </button>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Connections</h3>
          <p className="text-gray-600">Fetching system connections from server...</p>
        </div>
      )}

      {/* API Error Display */}
      {apiError && (
        <div className="bg-white rounded-lg shadow-sm border border-red-200 mb-6">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">System Connections Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadSystemConnections}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Connection List */}
      {!loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">System Connections</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredConnections.map((connection) => (
            <div key={connection.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    {getTypeIcon(connection.type)}
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="text-lg font-medium text-gray-900">
                        {connection.name}
                      </h4>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(connection.status)}`}>
                        {getStatusIcon(connection.status)}
                        <span className="ml-1 capitalize">{connection.status}</span>
                      </span>
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-2">{connection.description}</p>
                    
                    <div className="flex items-center space-x-4 text-sm text-gray-500">
                      <span>Type: {connection.type.toUpperCase()}</span>
                      <span>Last sync: {getTimeSinceSync(connection.lastSync)}</span>
                      <span>Syncs: {connection.syncCount.toLocaleString()}</span>
                      <span>Errors: {connection.errorCount}</span>
                    </div>
                    
                    <div className="mt-2 text-xs text-gray-400 font-mono">
                      {connection.url}
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleTestConnection(connection.id)}
                    disabled={isConnecting || connection.status === 'testing'}
                    className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-md disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Test Connection"
                  >
                    {connection.status === 'testing' ? (
                      <RefreshCw className="h-4 w-4 animate-spin" />
                    ) : (
                      <TestTube className="h-4 w-4" />
                    )}
                  </button>
                  
                  <button 
                    onClick={() => handleTriggerSync(connection.id)}
                    disabled={syncingConnections.has(connection.id)}
                    className="p-2 text-green-600 hover:text-green-800 hover:bg-green-50 rounded-md disabled:opacity-50 disabled:cursor-not-allowed" 
                    title="Trigger Sync"
                  >
                    {syncingConnections.has(connection.id) ? (
                      <RefreshCw className="h-4 w-4 animate-spin" />
                    ) : (
                      <Sync className="h-4 w-4" />
                    )}
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="View Details">
                    <Eye className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="Edit">
                    <Edit className="h-4 w-4" />
                  </button>
                  
                  <button 
                    onClick={() => handleDeleteConnection(connection.id)}
                    disabled={isConnecting}
                    className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-md disabled:opacity-50 disabled:cursor-not-allowed" 
                    title="Delete"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredConnections.length === 0 && !loading && (
          <div className="text-center py-12">
            <Link2 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No connections found</h3>
            <p className="text-gray-600">Try adjusting your search criteria or add a new connection.</p>
          </div>
        )}
        </div>
      )}

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button 
            onClick={handleTestAllConnections}
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <TestTube className="h-5 w-5 text-blue-600 mr-2" />
              <h4 className="font-medium text-gray-900">Test All Connections</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Verify all connection statuses</p>
          </button>
          
          <button 
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <Download className="h-5 w-5 text-green-600 mr-2" />
              <h4 className="font-medium text-gray-900">Export Configuration</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Download connection settings</p>
          </button>
          
          <button 
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <Upload className="h-5 w-5 text-purple-600 mr-2" />
              <h4 className="font-medium text-gray-900">Import Settings</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Upload connection configurations</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default SystemConnectors;