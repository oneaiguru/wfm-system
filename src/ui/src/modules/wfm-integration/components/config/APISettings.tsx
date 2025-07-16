import React, { useState, useEffect } from 'react';
import { 
  Settings, 
  Key, 
  Shield, 
  Globe, 
  TestTube, 
  CheckCircle, 
  AlertCircle, 
  Clock, 
  Plus,
  Edit,
  Trash2,
  Eye,
  Copy,
  RefreshCw,
  Download,
  Upload
} from 'lucide-react';
import realIntegrationService, { APIEndpoint, IntegrationConfig } from '../../../services/realIntegrationService';

const APISettings: React.FC = () => {
  const [endpoints, setEndpoints] = useState<APIEndpoint[]>([]);
  const [integrationConfigs, setIntegrationConfigs] = useState<IntegrationConfig[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'testing'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedEndpoint, setSelectedEndpoint] = useState<APIEndpoint | null>(null);
  const [showTokens, setShowTokens] = useState(false);
  const [loading, setLoading] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);

  useEffect(() => {
    loadIntegrationConfigs();
  }, []);

  const loadIntegrationConfigs = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realIntegrationService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realIntegrationService.getIntegrationConfigs();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded integration configs:', result.data);
        setIntegrationConfigs(result.data);
        
        // Extract all endpoints from configs
        const allEndpoints = result.data.flatMap(config => config.endpoints || []);
        setEndpoints(allEndpoints);
      } else {
        setApiError(result.error || 'Failed to load integration configurations');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load integration configs:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredEndpoints = endpoints.filter(endpoint => {
    const matchesFilter = filter === 'all' || endpoint.status === filter;
    const matchesSearch = 
      endpoint.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      endpoint.url.toLowerCase().includes(searchTerm.toLowerCase()) ||
      endpoint.method.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'testing': return 'bg-yellow-100 text-yellow-800';
      case 'inactive': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'testing': return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'inactive': return <AlertCircle className="h-4 w-4 text-gray-500" />;
      default: return <Settings className="h-4 w-4 text-gray-500" />;
    }
  };

  const getMethodColor = (method: string) => {
    switch (method) {
      case 'GET': return 'bg-green-100 text-green-800';
      case 'POST': return 'bg-blue-100 text-blue-800';
      case 'PUT': return 'bg-yellow-100 text-yellow-800';
      case 'DELETE': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getAuthIcon = (type: string) => {
    switch (type) {
      case 'bearer': return <Shield className="h-4 w-4 text-blue-600" />;
      case 'basic': return <Key className="h-4 w-4 text-purple-600" />;
      case 'api-key': return <Key className="h-4 w-4 text-green-600" />;
      default: return <Globe className="h-4 w-4 text-gray-600" />;
    }
  };

  const formatResponseTime = (ms: number) => {
    if (ms === 0) return 'N/A';
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  };

  const formatTimeSince = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  const handleTestEndpoint = async (endpointId: string) => {
    setApiError('');
    setIsConnecting(true);
    
    // Update UI to show testing status
    setEndpoints(prev => prev.map(endpoint =>
      endpoint.id === endpointId
        ? { ...endpoint, status: 'testing' as const }
        : endpoint
    ));

    try {
      const result = await realIntegrationService.testEndpoint(endpointId);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Test result:', result.data);
        
        // Update endpoint with real test results
        setEndpoints(prev => prev.map(endpoint =>
          endpoint.id === endpointId
            ? { 
                ...endpoint, 
                status: result.data!.success ? 'active' as const : 'inactive' as const,
                lastTest: new Date(),
                responseTime: result.data!.responseTime
              }
            : endpoint
        ));
        
        // Also refresh stats
        await refreshEndpointStats(endpointId);
      } else {
        setApiError(result.error || 'Endpoint test failed');
        // Set status back to inactive on failure
        setEndpoints(prev => prev.map(endpoint =>
          endpoint.id === endpointId
            ? { ...endpoint, status: 'inactive' as const }
            : endpoint
        ));
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Test failed';
      setApiError(errorMessage);
      // Set status back to inactive on error
      setEndpoints(prev => prev.map(endpoint =>
        endpoint.id === endpointId
          ? { ...endpoint, status: 'inactive' as const }
          : endpoint
      ));
    } finally {
      setIsConnecting(false);
    }
  };

  const refreshEndpointStats = async (endpointId: string) => {
    try {
      const result = await realIntegrationService.getEndpointStats(endpointId);
      
      if (result.success && result.data) {
        setEndpoints(prev => prev.map(endpoint =>
          endpoint.id === endpointId
            ? { 
                ...endpoint, 
                successRate: result.data!.successRate,
                responseTime: result.data!.avgResponseTime
              }
            : endpoint
        ));
      }
    } catch (error) {
      console.error('[REAL COMPONENT] Failed to refresh stats:', error);
    }
  };

  const handleExportConfiguration = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      const result = await realIntegrationService.exportConfiguration();
      
      if (result.success && result.data) {
        // Create download link
        const blob = new Blob([result.data.configData], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = result.data.filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      } else {
        setApiError(result.error || 'Export failed');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Export failed';
      setApiError(errorMessage);
    } finally {
      setIsConnecting(false);
    }
  };

  const handleTestAllEndpoints = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      const testPromises = endpoints.map(endpoint => handleTestEndpoint(endpoint.id));
      await Promise.all(testPromises);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to test all endpoints';
      setApiError(errorMessage);
    } finally {
      setIsConnecting(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const stats = {
    total: endpoints.length,
    active: endpoints.filter(e => e.status === 'active').length,
    testing: endpoints.filter(e => e.status === 'testing').length,
    inactive: endpoints.filter(e => e.status === 'inactive').length,
    avgResponseTime: endpoints.filter(e => e.responseTime > 0).reduce((sum, e) => sum + e.responseTime, 0) / endpoints.filter(e => e.responseTime > 0).length,
    avgSuccessRate: endpoints.filter(e => e.successRate > 0).reduce((sum, e) => sum + e.successRate, 0) / endpoints.filter(e => e.successRate > 0).length
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Settings className="h-6 w-6 mr-2 text-blue-600" />
          API Settings
        </h2>
        <p className="mt-2 text-gray-600">
          Configure API endpoints, authentication, and connection settings
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Globe className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Endpoints</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{stats.active}</p>
              <p className="text-sm text-gray-600">Working</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Avg Response</h3>
              <p className="text-2xl font-bold text-purple-600">{formatResponseTime(stats.avgResponseTime)}</p>
              <p className="text-sm text-gray-600">Response Time</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Shield className="h-8 w-8 text-orange-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Success Rate</h3>
              <p className="text-2xl font-bold text-orange-600">{stats.avgSuccessRate.toFixed(1)}%</p>
              <p className="text-sm text-gray-600">Average</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <TestTube className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Testing</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.testing}</p>
              <p className="text-sm text-gray-600">In Progress</p>
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
                placeholder="Search endpoints..."
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
              <option value="all">All Endpoints</option>
              <option value="active">Active</option>
              <option value="testing">Testing</option>
              <option value="inactive">Inactive</option>
            </select>

            <button
              onClick={() => setShowTokens(!showTokens)}
              className={`px-3 py-2 rounded-md text-sm ${showTokens ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}
            >
              {showTokens ? 'Hide' : 'Show'} Tokens
            </button>

            <span className="text-sm text-gray-600">
              {filteredEndpoints.length} endpoints
            </span>
          </div>

          <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Add Endpoint
          </button>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Configuration</h3>
          <p className="text-gray-600">Fetching integration settings from server...</p>
        </div>
      )}

      {/* API Error Display */}
      {apiError && (
        <div className="bg-white rounded-lg shadow-sm border border-red-200 mb-6">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Integration Configuration Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadIntegrationConfigs}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Endpoints List */}
      {!loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">API Endpoints</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredEndpoints.map((endpoint) => (
            <div key={endpoint.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    <Globe className="h-6 w-6 text-blue-600" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="text-lg font-medium text-gray-900">{endpoint.name}</h4>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getMethodColor(endpoint.method)}`}>
                        {endpoint.method}
                      </span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(endpoint.status)}`}>
                        {getStatusIcon(endpoint.status)}
                        <span className="ml-1 capitalize">{endpoint.status}</span>
                      </span>
                    </div>
                    
                    <div className="mb-3">
                      <div className="flex items-center space-x-2">
                        <span className="text-sm text-gray-600 font-mono">{endpoint.url}</span>
                        <button
                          onClick={() => copyToClipboard(endpoint.url)}
                          className="p-1 text-gray-400 hover:text-gray-600"
                          title="Copy URL"
                        >
                          <Copy className="h-3 w-3" />
                        </button>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                      <div>
                        <span className="text-gray-500">Authentication:</span>
                        <div className="flex items-center mt-1">
                          {getAuthIcon(endpoint.authentication?.type || 'none')}
                          <span className="ml-1 capitalize">{endpoint.authentication?.type || 'None'}</span>
                        </div>
                      </div>
                      <div>
                        <span className="text-gray-500">Response Time:</span>
                        <div className="font-medium mt-1">{formatResponseTime(endpoint.responseTime)}</div>
                      </div>
                      <div>
                        <span className="text-gray-500">Success Rate:</span>
                        <div className="font-medium mt-1">{endpoint.successRate.toFixed(1)}%</div>
                      </div>
                      <div>
                        <span className="text-gray-500">Last Test:</span>
                        <div className="font-medium mt-1">{formatTimeSince(endpoint.lastTest)}</div>
                      </div>
                    </div>

                    {/* Authentication Token */}
                    {showTokens && endpoint.authentication?.token && (
                      <div className="mt-3 p-3 bg-gray-50 rounded-md">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-600">Token:</span>
                          <button
                            onClick={() => copyToClipboard(endpoint.authentication?.token || '')}
                            className="p-1 text-gray-400 hover:text-gray-600"
                            title="Copy Token"
                          >
                            <Copy className="h-3 w-3" />
                          </button>
                        </div>
                        <div className="text-sm font-mono text-gray-800 mt-1 truncate">
                          {endpoint.authentication.token}
                        </div>
                      </div>
                    )}

                    {/* Headers */}
                    <div className="mt-3">
                      <span className="text-sm text-gray-600">Headers:</span>
                      <div className="mt-1 space-y-1">
                        {Object.entries(endpoint.headers).map(([key, value]) => (
                          <div key={key} className="text-sm">
                            <span className="text-gray-500">{key}:</span>{' '}
                            <span className="font-mono text-gray-800">{value}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleTestEndpoint(endpoint.id)}
                    disabled={isConnecting || endpoint.status === 'testing'}
                    className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-md disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Test Endpoint"
                  >
                    {endpoint.status === 'testing' ? (
                      <RefreshCw className="h-4 w-4 animate-spin" />
                    ) : (
                      <TestTube className="h-4 w-4" />
                    )}
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="View Details">
                    <Eye className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="Edit">
                    <Edit className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-md" title="Delete">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredEndpoints.length === 0 && !loading && (
          <div className="text-center py-12">
            <Globe className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No endpoints found</h3>
            <p className="text-gray-600">Try adjusting your search criteria or add a new endpoint.</p>
          </div>
        )}
        </div>
      )}

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button 
            onClick={handleTestAllEndpoints}
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <TestTube className="h-5 w-5 text-blue-600 mr-2" />
              <h4 className="font-medium text-gray-900">Test All Endpoints</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Run connectivity tests for all APIs</p>
          </button>
          
          <button 
            onClick={handleExportConfiguration}
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <Download className="h-5 w-5 text-green-600 mr-2" />
              <h4 className="font-medium text-gray-900">Export Configuration</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Download API settings as JSON</p>
          </button>
          
          <button 
            disabled={isConnecting || loading}
            className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div className="flex items-center">
              <Upload className="h-5 w-5 text-purple-600 mr-2" />
              <h4 className="font-medium text-gray-900">Import Settings</h4>
            </div>
            <p className="text-sm text-gray-600 mt-1">Upload API configuration file</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default APISettings;