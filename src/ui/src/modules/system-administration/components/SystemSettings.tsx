import React, { useState, useEffect } from 'react';
import { 
  Settings, 
  Monitor, 
  Shield, 
  Zap, 
  Database, 
  Bell, 
  HardDrive,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Save,
  RotateCcw,
  Download,
  Upload,
  Activity,
  Clock,
  Cpu,
  MemoryStick,
  Play,
  Square,
  Trash2
} from 'lucide-react';
import realSystemSettingsService, { SystemSetting, SystemHealth, SystemConfiguration } from '../../../services/realSystemSettingsService';

const SystemSettings: React.FC = () => {
  const [settings, setSettings] = useState<SystemSetting[]>([]);
  const [systemHealth, setSystemHealth] = useState<SystemHealth | null>(null);
  const [activeCategory, setActiveCategory] = useState<string>('general');
  const [editingSettings, setEditingSettings] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  const categories = [
    { id: 'general', name: 'General', icon: Settings, color: 'blue' },
    { id: 'security', name: 'Security', icon: Shield, color: 'red' },
    { id: 'performance', name: 'Performance', icon: Zap, color: 'yellow' },
    { id: 'integration', name: 'Integration', icon: Database, color: 'green' },
    { id: 'notification', name: 'Notifications', icon: Bell, color: 'purple' },
    { id: 'backup', name: 'Backup & Recovery', icon: HardDrive, color: 'gray' }
  ];

  useEffect(() => {
    loadSystemSettings();
    loadSystemHealth();
  }, [activeCategory]);

  const loadSystemSettings = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realSystemSettingsService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realSystemSettingsService.getSystemSettingsByCategory(activeCategory);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded system settings:', result.data);
        setSettings(result.data);
        
        // Initialize editing state with current values
        const editingState: Record<string, any> = {};
        result.data.forEach(setting => {
          editingState[setting.key] = setting.value;
        });
        setEditingSettings(editingState);
      } else {
        setApiError(result.error || 'Failed to load system settings');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load system settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadSystemHealth = async () => {
    try {
      const result = await realSystemSettingsService.getSystemHealth();
      
      if (result.success && result.data) {
        setSystemHealth(result.data);
      }
    } catch (error) {
      console.error('[REAL COMPONENT] Failed to load system health:', error);
    }
  };

  const handleSaveSettings = async () => {
    setSaving(true);
    setApiError('');
    setSaveSuccess(false);
    
    try {
      // Prepare settings for validation and update
      const settingsToUpdate = Object.keys(editingSettings).map(key => ({
        key,
        value: editingSettings[key]
      }));

      // Validate settings first
      const validationResult = await realSystemSettingsService.validateSystemSettings(settingsToUpdate);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        const errorMessages = validationResult.data.errors.map(e => `${e.key}: ${e.message}`);
        throw new Error(errorMessages.join(', '));
      }

      // Update settings
      const result = await realSystemSettingsService.updateSystemSettings(settingsToUpdate);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Settings updated successfully:', result.data);
        setSettings(result.data);
        setSaveSuccess(true);
        
        // Hide success message after 3 seconds
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to update settings');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Save failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to save settings:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleResetSetting = async (key: string) => {
    setApiError('');
    
    try {
      const result = await realSystemSettingsService.resetSystemSetting(key);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Setting reset successfully:', result.data);
        
        // Update the setting in the list
        setSettings(prev => prev.map(setting =>
          setting.key === key ? result.data! : setting
        ));
        
        // Update editing state
        setEditingSettings(prev => ({
          ...prev,
          [key]: result.data!.value
        }));
        
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to reset setting');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Reset failed';
      setApiError(errorMessage);
    }
  };

  const handleCreateBackup = async () => {
    setApiError('');
    
    try {
      const result = await realSystemSettingsService.createConfigurationBackup();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Backup created:', result.data);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to create backup');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Backup failed';
      setApiError(errorMessage);
    }
  };

  const filteredSettings = settings.filter(setting =>
    setting.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
    setting.description.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getHealthStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-green-600 bg-green-100';
      case 'warning': return 'text-yellow-600 bg-yellow-100';
      case 'critical': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const renderSettingInput = (setting: SystemSetting) => {
    const value = editingSettings[setting.key] ?? setting.value;
    
    if (setting.isReadOnly) {
      return (
        <div className="px-3 py-2 bg-gray-50 border border-gray-300 rounded-md text-gray-500">
          {String(value)}
        </div>
      );
    }

    switch (setting.dataType) {
      case 'boolean':
        return (
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={Boolean(value)}
              onChange={(e) => setEditingSettings(prev => ({
                ...prev,
                [setting.key]: e.target.checked
              }))}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">
              {Boolean(value) ? 'Enabled' : 'Disabled'}
            </span>
          </label>
        );
      
      case 'number':
        return (
          <input
            type="number"
            value={value || ''}
            min={setting.validationRules?.min}
            max={setting.validationRules?.max}
            onChange={(e) => setEditingSettings(prev => ({
              ...prev,
              [setting.key]: parseFloat(e.target.value) || 0
            }))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        );
      
      case 'password':
        return (
          <input
            type="password"
            value={value || ''}
            onChange={(e) => setEditingSettings(prev => ({
              ...prev,
              [setting.key]: e.target.value
            }))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        );
      
      case 'json':
        return (
          <textarea
            value={typeof value === 'string' ? value : JSON.stringify(value, null, 2)}
            onChange={(e) => {
              try {
                const parsed = JSON.parse(e.target.value);
                setEditingSettings(prev => ({
                  ...prev,
                  [setting.key]: parsed
                }));
              } catch {
                setEditingSettings(prev => ({
                  ...prev,
                  [setting.key]: e.target.value
                }));
              }
            }}
            rows={4}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        );
      
      default:
        if (setting.validationRules?.options) {
          return (
            <select
              value={value || ''}
              onChange={(e) => setEditingSettings(prev => ({
                ...prev,
                [setting.key]: e.target.value
              }))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {setting.validationRules.options.map(option => (
                <option key={option} value={option}>{option}</option>
              ))}
            </select>
          );
        }
        
        return (
          <input
            type="text"
            value={value || ''}
            pattern={setting.validationRules?.pattern}
            onChange={(e) => setEditingSettings(prev => ({
              ...prev,
              [setting.key]: e.target.value
            }))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        );
    }
  };

  // Loading state
  if (loading && !settings.length) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading System Settings</h3>
          <p className="text-gray-600">Fetching configuration from server...</p>
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
          System Settings
        </h2>
        <p className="mt-2 text-gray-600">
          Configure system-wide settings and monitor system health
        </p>
      </div>

      {/* Success Message */}
      {saveSuccess && (
        <div className="mb-6 px-6 py-3 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center gap-2 text-green-800">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <div className="font-medium">Settings updated successfully!</div>
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
                <div className="font-medium">System Settings Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadSystemSettings}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* System Health Dashboard */}
      {systemHealth && (
        <div className="mb-8 bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Monitor className="h-5 w-5 mr-2 text-blue-600" />
              System Health
            </h3>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <div className="flex items-center">
                <Activity className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <div className="text-sm text-gray-600">Status</div>
                  <div className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getHealthStatusColor(systemHealth.status)}`}>
                    {systemHealth.status.toUpperCase()}
                  </div>
                </div>
              </div>
              
              <div className="flex items-center">
                <Cpu className="h-8 w-8 text-green-600 mr-3" />
                <div>
                  <div className="text-sm text-gray-600">CPU Usage</div>
                  <div className="text-lg font-semibold">{systemHealth.cpuUsage.toFixed(1)}%</div>
                </div>
              </div>
              
              <div className="flex items-center">
                <MemoryStick className="h-8 w-8 text-purple-600 mr-3" />
                <div>
                  <div className="text-sm text-gray-600">Memory Usage</div>
                  <div className="text-lg font-semibold">{systemHealth.memoryUsage.toFixed(1)}%</div>
                </div>
              </div>
              
              <div className="flex items-center">
                <Clock className="h-8 w-8 text-orange-600 mr-3" />
                <div>
                  <div className="text-sm text-gray-600">Uptime</div>
                  <div className="text-lg font-semibold">{Math.floor(systemHealth.uptime / 3600)}h</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Category Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-900">Categories</h3>
            </div>
            <nav className="p-2">
              {categories.map((category) => {
                const Icon = category.icon;
                return (
                  <button
                    key={category.id}
                    onClick={() => setActiveCategory(category.id)}
                    className={`w-full flex items-center px-3 py-2 text-sm rounded-md transition-colors ${
                      activeCategory === category.id
                        ? 'bg-blue-50 text-blue-700 border-blue-200'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                    }`}
                  >
                    <Icon className="h-4 w-4 mr-3" />
                    {category.name}
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Settings Content */}
        <div className="lg:col-span-3">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-gray-900">
                  {categories.find(c => c.id === activeCategory)?.name} Settings
                </h3>
                <div className="flex gap-3">
                  <button
                    onClick={handleCreateBackup}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    <Download className="h-4 w-4 mr-2 inline" />
                    Backup
                  </button>
                  <button
                    onClick={handleSaveSettings}
                    disabled={saving}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    {saving ? (
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    ) : (
                      <Save className="h-4 w-4 mr-2" />
                    )}
                    {saving ? 'Saving...' : 'Save Settings'}
                  </button>
                </div>
              </div>
              
              {/* Search */}
              <div className="mt-4">
                <input
                  type="text"
                  placeholder="Search settings..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div className="divide-y divide-gray-200">
              {filteredSettings.map((setting) => (
                <div key={setting.key} className="p-6">
                  <div className="flex justify-between items-start">
                    <div className="flex-1 min-w-0 mr-6">
                      <div className="flex items-center">
                        <h4 className="text-sm font-medium text-gray-900">
                          {setting.key}
                        </h4>
                        {setting.isRequired && (
                          <span className="ml-2 text-xs text-red-500">*</span>
                        )}
                        {setting.isReadOnly && (
                          <span className="ml-2 text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                            Read Only
                          </span>
                        )}
                      </div>
                      <p className="mt-1 text-sm text-gray-600">{setting.description}</p>
                      <div className="mt-3">
                        {renderSettingInput(setting)}
                      </div>
                      {setting.validationRules && (
                        <div className="mt-2 text-xs text-gray-500">
                          {setting.validationRules.min !== undefined && (
                            <span>Min: {setting.validationRules.min} </span>
                          )}
                          {setting.validationRules.max !== undefined && (
                            <span>Max: {setting.validationRules.max} </span>
                          )}
                          {setting.validationRules.pattern && (
                            <span>Pattern: {setting.validationRules.pattern}</span>
                          )}
                        </div>
                      )}
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      {!setting.isReadOnly && (
                        <button
                          onClick={() => handleResetSetting(setting.key)}
                          className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-md"
                          title="Reset to default"
                        >
                          <RotateCcw className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}

              {filteredSettings.length === 0 && !loading && (
                <div className="text-center py-12">
                  <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No settings found</h3>
                  <p className="text-gray-600">Try adjusting your search criteria.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SystemSettings;