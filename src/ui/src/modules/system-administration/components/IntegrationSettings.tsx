import React, { useState, useEffect } from 'react';
import {
  Settings,
  Plus,
  Search,
  Filter,
  Download,
  Upload,
  Edit3,
  Trash2,
  Save,
  X,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Eye,
  EyeOff,
  Play,
  Square,
  TestTube,
  Shield,
  Database,
  Globe,
  Zap,
  Activity,
  Clock,
  AlertTriangle,
  Wifi,
  WifiOff,
  Sync,
  BarChart3,
  FileText,
  Key,
  Server
} from 'lucide-react';
import realIntegrationSettingsService, {
  IntegrationConfig,
  IntegrationTestResult
} from '../../../services/realIntegrationSettingsService';

const IntegrationSettings: React.FC = () => {
  const [integrations, setIntegrations] = useState<IntegrationConfig[]>([]);
  const [filteredIntegrations, setFilteredIntegrations] = useState<IntegrationConfig[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [hasAdminPermission, setHasAdminPermission] = useState(false);
  
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<string>('');
  
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showTestModal, setShowTestModal] = useState(false);
  const [editingIntegration, setEditingIntegration] = useState<IntegrationConfig | null>(null);
  const [testResult, setTestResult] = useState<IntegrationTestResult | null>(null);
  const [validationErrors, setValidationErrors] = useState<Array<{ field: string; message: string }>>([]);
  
  const [newIntegration, setNewIntegration] = useState<Partial<IntegrationConfig>>({
    name: '',
    type: 'api',
    provider: '',
    description: '',
    isEnabled: true,
    isSystem: false,
    version: '1.0.0',
    connectionConfig: {},
    authConfig: { type: 'none' },
    mappingConfig: {},
    monitoringConfig: {
      healthCheckEnabled: true,
      healthCheckInterval: 300,
      alertOnFailure: true,
      alertRecipients: [],
      metricsEnabled: true,
      logLevel: 'info'
    },
    metadata: { tags: [] }
  });

  const integrationTypes = [
    { value: 'api', label: 'REST API', icon: Globe },
    { value: 'database', label: 'Database', icon: Database },
    { value: 'file', label: 'File System', icon: FileText },
    { value: 'webhook', label: 'Webhook', icon: Zap },
    { value: 'service', label: 'Service', icon: Server }
  ];

  const authTypes = [
    { value: 'none', label: 'None' },
    { value: 'basic', label: 'Basic Auth' },
    { value: 'bearer', label: 'Bearer Token' },
    { value: 'oauth2', label: 'OAuth 2.0' },
    { value: 'api_key', label: 'API Key' },
    { value: 'certificate', label: 'Certificate' }
  ];

  const logLevels = [
    { value: 'debug', label: 'Debug' },
    { value: 'info', label: 'Info' },
    { value: 'warn', label: 'Warning' },
    { value: 'error', label: 'Error' }
  ];

  useEffect(() => {
    checkPermissions();
    loadIntegrations();
  }, []);

  useEffect(() => {
    // Filter integrations based on search and filters
    let filtered = integrations;

    if (searchTerm) {
      filtered = filtered.filter(integration =>
        integration.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        integration.provider.toLowerCase().includes(searchTerm.toLowerCase()) ||
        integration.description.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (filterType) {
      filtered = filtered.filter(integration => integration.type === filterType);
    }

    if (filterStatus) {
      if (filterStatus === 'enabled') {
        filtered = filtered.filter(integration => integration.isEnabled);
      } else if (filterStatus === 'disabled') {
        filtered = filtered.filter(integration => !integration.isEnabled);
      } else if (filterStatus === 'connected') {
        filtered = filtered.filter(integration => integration.status.isConnected);
      } else if (filterStatus === 'disconnected') {
        filtered = filtered.filter(integration => !integration.status.isConnected);
      }
    }

    setFilteredIntegrations(filtered);
  }, [integrations, searchTerm, filterType, filterStatus]);

  const checkPermissions = async () => {
    try {
      const result = await realIntegrationSettingsService.checkAdminPermissions();
      
      if (result.success && result.data) {
        setHasAdminPermission(result.data.hasPermission);
        if (!result.data.hasPermission) {
          setApiError('Administrator privileges required to manage integration settings.');
        }
      } else {
        setApiError(result.error || 'Failed to check permissions');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Permission check failed';
      setApiError(errorMessage);
    }
  };

  const loadIntegrations = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realIntegrationSettingsService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realIntegrationSettingsService.getAllIntegrationConfigs();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded integration configurations:', result.data);
        setIntegrations(result.data);
      } else {
        setApiError(result.error || 'Failed to load integration configurations');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load integrations:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateIntegration = async () => {
    if (!hasAdminPermission) {
      setApiError('Administrator privileges required.');
      return;
    }

    setSaving(true);
    setApiError('');
    setValidationErrors([]);
    
    try {
      // Validate integration first
      const validationResult = await realIntegrationSettingsService.validateIntegrationConfig(newIntegration);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        setValidationErrors(validationResult.data.errors);
        return;
      }

      // Create integration
      const result = await realIntegrationSettingsService.createIntegrationConfig(newIntegration as any);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Integration created successfully:', result.data);
        await loadIntegrations();
        setShowCreateModal(false);
        setNewIntegration({
          name: '',
          type: 'api',
          provider: '',
          description: '',
          isEnabled: true,
          isSystem: false,
          version: '1.0.0',
          connectionConfig: {},
          authConfig: { type: 'none' },
          mappingConfig: {},
          monitoringConfig: {
            healthCheckEnabled: true,
            healthCheckInterval: 300,
            alertOnFailure: true,
            alertRecipients: [],
            metricsEnabled: true,
            logLevel: 'info'
          },
          metadata: { tags: [] }
        });
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to create integration');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Creation failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to create integration:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateIntegration = async () => {
    if (!editingIntegration || !hasAdminPermission) {
      setApiError('Administrator privileges required.');
      return;
    }
    
    setSaving(true);
    setApiError('');
    setValidationErrors([]);
    
    try {
      // Validate integration first
      const validationResult = await realIntegrationSettingsService.validateIntegrationConfig(editingIntegration);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        setValidationErrors(validationResult.data.errors);
        return;
      }

      // Update integration
      const result = await realIntegrationSettingsService.updateIntegrationConfig(editingIntegration.id, editingIntegration);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Integration updated successfully:', result.data);
        await loadIntegrations();
        setShowEditModal(false);
        setEditingIntegration(null);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to update integration');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Update failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to update integration:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteIntegration = async (id: string) => {
    if (!hasAdminPermission) {
      setApiError('Administrator privileges required.');
      return;
    }

    if (!confirm('Are you sure you want to delete this integration?')) return;
    
    setApiError('');
    
    try {
      const result = await realIntegrationSettingsService.deleteIntegrationConfig(id);
      
      if (result.success) {
        console.log('[REAL COMPONENT] Integration deleted successfully');
        await loadIntegrations();
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to delete integration');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Delete failed';
      setApiError(errorMessage);
    }
  };

  const handleToggleIntegration = async (id: string, enabled: boolean) => {
    if (!hasAdminPermission) {
      setApiError('Administrator privileges required.');
      return;
    }

    setApiError('');
    
    try {
      const result = await realIntegrationSettingsService.toggleIntegrationStatus(id, enabled);
      
      if (result.success) {
        console.log('[REAL COMPONENT] Integration status toggled successfully');
        await loadIntegrations();
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to toggle integration status');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Status toggle failed';
      setApiError(errorMessage);
    }
  };

  const handleTestIntegration = async (id: string) => {
    setApiError('');
    setTestResult(null);
    
    try {
      const result = await realIntegrationSettingsService.testIntegrationConnection(id);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Integration test completed:', result.data);
        setTestResult(result.data);
        setShowTestModal(true);
      } else {
        setApiError(result.error || 'Failed to test integration');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Test failed';
      setApiError(errorMessage);
    }
  };

  const handleSyncIntegration = async (id: string) => {
    setApiError('');
    
    try {
      const result = await realIntegrationSettingsService.syncIntegrationData(id);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Integration sync completed:', result.data);
        await loadIntegrations();
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to sync integration');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Sync failed';
      setApiError(errorMessage);
    }
  };

  const getStatusColor = (integration: IntegrationConfig) => {
    if (!integration.isEnabled) return 'bg-gray-100 text-gray-800';
    if (!integration.status.isConnected) return 'bg-red-100 text-red-800';
    if (integration.status.lastError) return 'bg-yellow-100 text-yellow-800';
    return 'bg-green-100 text-green-800';
  };

  const getStatusText = (integration: IntegrationConfig) => {
    if (!integration.isEnabled) return 'Disabled';
    if (!integration.status.isConnected) return 'Disconnected';
    if (integration.status.lastError) return 'Warning';
    return 'Connected';
  };

  const getTypeIcon = (type: string) => {
    const typeConfig = integrationTypes.find(t => t.value === type);
    return typeConfig?.icon || Server;
  };

  // Loading state
  if (loading && integrations.length === 0) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Integration Settings</h3>
          <p className="text-gray-600">Fetching configurations from server...</p>
        </div>
      </div>
    );
  }

  // Permission denied state
  if (!hasAdminPermission && !loading) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <Shield className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Access Denied</h3>
          <p className="text-gray-600 mb-4">
            Administrator privileges are required to manage integration settings.
          </p>
          <button
            onClick={checkPermissions}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Check Permissions Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Settings className="h-6 w-6 mr-2 text-blue-600" />
          Integration Settings
        </h2>
        <p className="mt-2 text-gray-600">
          Configure and manage system integrations
        </p>
      </div>

      {/* Success Message */}
      {saveSuccess && (
        <div className="mb-6 px-6 py-3 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center gap-2 text-green-800">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <div className="font-medium">Operation completed successfully!</div>
          </div>
        </div>
      )}

      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <div className="mb-6 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-start gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500 mt-0.5" />
            <div>
              <div className="font-medium">Validation errors:</div>
              <ul className="text-sm list-disc list-inside">
                {validationErrors.map((error, index) => (
                  <li key={index}>{error.field}: {error.message}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Error Message */}
      {apiError && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-red-200">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Integration Settings Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadIntegrations}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Toolbar */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center">
            <div className="flex-1 max-w-md">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search integrations..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">All Types</option>
                {integrationTypes.map(type => (
                  <option key={type.value} value={type.value}>{type.label}</option>
                ))}
              </select>
              
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">All Status</option>
                <option value="enabled">Enabled</option>
                <option value="disabled">Disabled</option>
                <option value="connected">Connected</option>
                <option value="disconnected">Disconnected</option>
              </select>
              
              <button
                onClick={() => setShowCreateModal(true)}
                disabled={!hasAdminPermission}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Integration
              </button>
            </div>
          </div>
        </div>

        {/* Integrations Grid */}
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredIntegrations.map((integration) => {
              const TypeIcon = getTypeIcon(integration.type);
              return (
                <div key={integration.id} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center">
                      <TypeIcon className="h-8 w-8 text-blue-600 mr-3" />
                      <div>
                        <h3 className="text-lg font-medium text-gray-900">{integration.name}</h3>
                        <p className="text-sm text-gray-500">{integration.provider}</p>
                      </div>
                    </div>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(integration)}`}>
                      {integration.status.isConnected ? (
                        <Wifi className="h-3 w-3 mr-1" />
                      ) : (
                        <WifiOff className="h-3 w-3 mr-1" />
                      )}
                      {getStatusText(integration)}
                    </span>
                  </div>
                  
                  <p className="text-sm text-gray-600 mb-4">{integration.description}</p>
                  
                  <div className="flex items-center justify-between text-xs text-gray-500 mb-4">
                    <span>Type: {integration.type.toUpperCase()}</span>
                    <span>v{integration.version}</span>
                  </div>
                  
                  {integration.status.lastError && (
                    <div className="mb-4 p-2 bg-red-50 border border-red-200 rounded text-xs text-red-800">
                      <AlertTriangle className="h-3 w-3 inline mr-1" />
                      {integration.status.lastError}
                    </div>
                  )}
                  
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleToggleIntegration(integration.id, !integration.isEnabled)}
                        disabled={!hasAdminPermission || integration.isSystem}
                        className={`p-2 rounded text-white disabled:opacity-50 disabled:cursor-not-allowed ${
                          integration.isEnabled ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
                        }`}
                        title={integration.isEnabled ? 'Disable' : 'Enable'}
                      >
                        {integration.isEnabled ? <Square className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                      </button>
                      
                      <button
                        onClick={() => handleTestIntegration(integration.id)}
                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                        title="Test Connection"
                      >
                        <TestTube className="h-4 w-4" />
                      </button>
                      
                      <button
                        onClick={() => handleSyncIntegration(integration.id)}
                        disabled={!integration.isEnabled}
                        className="p-2 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded disabled:opacity-50"
                        title="Sync Data"
                      >
                        <Sync className="h-4 w-4" />
                      </button>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => {
                          setEditingIntegration({ ...integration });
                          setShowEditModal(true);
                        }}
                        disabled={!hasAdminPermission}
                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded disabled:opacity-50"
                        title="Edit"
                      >
                        <Edit3 className="h-4 w-4" />
                      </button>
                      
                      {!integration.isSystem && (
                        <button
                          onClick={() => handleDeleteIntegration(integration.id)}
                          disabled={!hasAdminPermission}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded disabled:opacity-50"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {filteredIntegrations.length === 0 && !loading && (
            <div className="text-center py-12">
              <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No integrations found</h3>
              <p className="text-gray-600">
                {searchTerm || filterType || filterStatus 
                  ? 'Try adjusting your search criteria.' 
                  : 'Add your first integration to get started.'}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Create Integration Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-96 overflow-y-auto">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Add Integration</h3>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                  <input
                    type="text"
                    value={newIntegration.name || ''}
                    onChange={(e) => setNewIntegration(prev => ({ ...prev, name: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Provider</label>
                  <input
                    type="text"
                    value={newIntegration.provider || ''}
                    onChange={(e) => setNewIntegration(prev => ({ ...prev, provider: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newIntegration.description || ''}
                  onChange={(e) => setNewIntegration(prev => ({ ...prev, description: e.target.value }))}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                  <select
                    value={newIntegration.type || 'api'}
                    onChange={(e) => setNewIntegration(prev => ({ ...prev, type: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {integrationTypes.map(type => (
                      <option key={type.value} value={type.value}>{type.label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Authentication</label>
                  <select
                    value={newIntegration.authConfig?.type || 'none'}
                    onChange={(e) => setNewIntegration(prev => ({ 
                      ...prev, 
                      authConfig: { ...prev.authConfig, type: e.target.value as any }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {authTypes.map(auth => (
                      <option key={auth.value} value={auth.value}>{auth.label}</option>
                    ))}
                  </select>
                </div>
              </div>
              
              <div className="flex items-center space-x-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={newIntegration.isEnabled || false}
                    onChange={(e) => setNewIntegration(prev => ({ ...prev, isEnabled: e.target.checked }))}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Enabled</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={newIntegration.isSystem || false}
                    onChange={(e) => setNewIntegration(prev => ({ ...prev, isSystem: e.target.checked }))}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">System Integration</span>
                </label>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
              <button
                onClick={() => setShowCreateModal(false)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateIntegration}
                disabled={saving}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                {saving ? (
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                {saving ? 'Creating...' : 'Create Integration'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Test Result Modal */}
      {showTestModal && testResult && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-lg w-full">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Integration Test Result</h3>
            </div>
            <div className="p-6">
              <div className={`flex items-center mb-4 ${testResult.success ? 'text-green-800' : 'text-red-800'}`}>
                {testResult.success ? (
                  <CheckCircle className="h-6 w-6 mr-2 text-green-500" />
                ) : (
                  <AlertCircle className="h-6 w-6 mr-2 text-red-500" />
                )}
                <span className="font-medium">
                  {testResult.success ? 'Connection Successful' : 'Connection Failed'}
                </span>
              </div>
              
              <div className="space-y-2 text-sm">
                <div>
                  <span className="font-medium">Message:</span> {testResult.message}
                </div>
                <div>
                  <span className="font-medium">Response Time:</span> {testResult.responseTime}ms
                </div>
                
                {testResult.details && (
                  <div className="mt-4 p-3 bg-gray-50 rounded">
                    <div className="font-medium mb-2">Details:</div>
                    <div className="space-y-1 text-xs">
                      <div>Connection: {testResult.details.connectionStatus ? '✓' : '✗'}</div>
                      <div>Authentication: {testResult.details.authStatus ? '✓' : '✗'}</div>
                      <div>Data Access: {testResult.details.dataAccessStatus ? '✓' : '✗'}</div>
                      {testResult.details.errorDetails && (
                        <div className="text-red-600 mt-2">{testResult.details.errorDetails}</div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end">
              <button
                onClick={() => setShowTestModal(false)}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default IntegrationSettings;