import React, { useState, useEffect } from 'react';
import {
  Bell,
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
  Settings,
  Mail,
  MessageSquare,
  Smartphone,
  Webhook,
  Slack,
  Activity,
  BarChart3,
  Clock,
  Users,
  Zap,
  AlertTriangle,
  Server,
  Globe
} from 'lucide-react';
import realNotificationSettingsService, {
  NotificationTemplate,
  NotificationRule,
  NotificationChannel,
  NotificationLog,
  NotificationStats
} from '../../../services/realNotificationSettingsService';

const NotificationSettings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'templates' | 'rules' | 'channels' | 'logs' | 'stats'>('templates');
  const [templates, setTemplates] = useState<NotificationTemplate[]>([]);
  const [rules, setRules] = useState<NotificationRule[]>([]);
  const [channels, setChannels] = useState<NotificationChannel[]>([]);
  const [logs, setLogs] = useState<NotificationLog[]>([]);
  const [stats, setStats] = useState<NotificationStats | null>(null);
  
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showTestModal, setShowTestModal] = useState(false);
  const [editingItem, setEditingItem] = useState<any>(null);
  const [testResult, setTestResult] = useState<any>(null);
  const [validationErrors, setValidationErrors] = useState<Array<{ field: string; message: string }>>([]);

  const tabs = [
    { id: 'templates', name: 'Templates', icon: Mail, count: templates.length },
    { id: 'rules', name: 'Rules', icon: Settings, count: rules.length },
    { id: 'channels', name: 'Channels', icon: Zap, count: channels.length },
    { id: 'logs', name: 'Logs', icon: Activity, count: logs.length },
    { id: 'stats', name: 'Statistics', icon: BarChart3, count: 0 }
  ];

  const notificationTypes = [
    { value: 'email', label: 'Email', icon: Mail },
    { value: 'sms', label: 'SMS', icon: MessageSquare },
    { value: 'push', label: 'Push', icon: Smartphone },
    { value: 'webhook', label: 'Webhook', icon: Webhook },
    { value: 'slack', label: 'Slack', icon: Slack },
    { value: 'teams', label: 'Teams', icon: Users }
  ];

  const categories = [
    { value: 'schedule', label: 'Schedule' },
    { value: 'request', label: 'Request' },
    { value: 'alert', label: 'Alert' },
    { value: 'reminder', label: 'Reminder' },
    { value: 'system', label: 'System' },
    { value: 'emergency', label: 'Emergency' }
  ];

  const priorities = [
    { value: 'low', label: 'Low', color: 'bg-gray-100 text-gray-800' },
    { value: 'medium', label: 'Medium', color: 'bg-blue-100 text-blue-800' },
    { value: 'high', label: 'High', color: 'bg-yellow-100 text-yellow-800' },
    { value: 'urgent', label: 'Urgent', color: 'bg-red-100 text-red-800' }
  ];

  useEffect(() => {
    loadData();

    // Subscribe to real-time updates
    const unsubscribe = realNotificationSettingsService.subscribeToNotificationUpdates((update) => {
      console.log('[REAL COMPONENT] Received real-time notification update:', update);
      
      if (update.type === 'sent' || update.type === 'delivered' || update.type === 'failed') {
        // Refresh logs if we're viewing them
        if (activeTab === 'logs') {
          loadLogs();
        }
        // Refresh stats if we're viewing them
        if (activeTab === 'stats') {
          loadStats();
        }
      }
    });

    return unsubscribe;
  }, []);

  useEffect(() => {
    loadData();
  }, [activeTab]);

  const loadData = async () => {
    switch (activeTab) {
      case 'templates':
        await loadTemplates();
        break;
      case 'rules':
        await loadRules();
        break;
      case 'channels':
        await loadChannels();
        break;
      case 'logs':
        await loadLogs();
        break;
      case 'stats':
        await loadStats();
        break;
    }
  };

  const loadTemplates = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realNotificationSettingsService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realNotificationSettingsService.getNotificationTemplates();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded notification templates:', result.data);
        setTemplates(result.data);
      } else {
        setApiError(result.error || 'Failed to load notification templates');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load templates:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadRules = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      const result = await realNotificationSettingsService.getNotificationRules();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded notification rules:', result.data);
        setRules(result.data);
      } else {
        setApiError(result.error || 'Failed to load notification rules');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load rules:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadChannels = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      const result = await realNotificationSettingsService.getNotificationChannels();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded notification channels:', result.data);
        setChannels(result.data);
      } else {
        setApiError(result.error || 'Failed to load notification channels');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load channels:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadLogs = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      const result = await realNotificationSettingsService.getNotificationLogs({
        limit: 100,
        offset: 0
      });
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded notification logs:', result.data);
        setLogs(result.data.logs);
      } else {
        setApiError(result.error || 'Failed to load notification logs');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load logs:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      const result = await realNotificationSettingsService.getNotificationStats();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded notification stats:', result.data);
        setStats(result.data);
      } else {
        setApiError(result.error || 'Failed to load notification statistics');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleTestChannel = async (channelId: string) => {
    setApiError('');
    setTestResult(null);
    
    try {
      const result = await realNotificationSettingsService.testNotificationChannel(channelId, {
        recipient: 'test@example.com',
        subject: 'Test Notification',
        body: 'This is a test notification from the WFM system.'
      });
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Channel test completed:', result.data);
        setTestResult(result.data);
        setShowTestModal(true);
      } else {
        setApiError(result.error || 'Failed to test channel');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Test failed';
      setApiError(errorMessage);
    }
  };

  const handleToggleRule = async (ruleId: string, active: boolean) => {
    setApiError('');
    
    try {
      const result = await realNotificationSettingsService.toggleNotificationRule(ruleId, active);
      
      if (result.success) {
        console.log('[REAL COMPONENT] Rule toggled successfully');
        await loadRules();
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to toggle rule');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Toggle failed';
      setApiError(errorMessage);
    }
  };

  const getTypeIcon = (type: string) => {
    const typeConfig = notificationTypes.find(t => t.value === type);
    return typeConfig?.icon || Bell;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'sent':
      case 'delivered':
        return 'bg-green-100 text-green-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'failed':
      case 'bounced':
        return 'bg-red-100 text-red-800';
      case 'cancelled':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-blue-100 text-blue-800';
    }
  };

  const getPriorityColor = (priority: string) => {
    const priorityConfig = priorities.find(p => p.value === priority);
    return priorityConfig?.color || 'bg-gray-100 text-gray-800';
  };

  // Filter function for search
  const filterItems = (items: any[]) => {
    if (!searchTerm) return items;
    
    return items.filter(item =>
      item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.type?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.category?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  };

  // Loading state
  if (loading && (templates.length === 0 && rules.length === 0 && channels.length === 0 && logs.length === 0)) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Notification Settings</h3>
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
          <Bell className="h-6 w-6 mr-2 text-blue-600" />
          Notification Settings
        </h2>
        <p className="mt-2 text-gray-600">
          Configure notification templates, rules, and delivery channels
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
                <div className="font-medium">Notification Settings Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadData}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Tabs */}
        <div className="border-b border-gray-200">
          <nav className="flex space-x-8 px-6" aria-label="Tabs">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`${
                    activeTab === tab.id
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center`}
                >
                  <Icon className="h-4 w-4 mr-2" />
                  {tab.name}
                  {tab.count > 0 && (
                    <span className="ml-2 bg-gray-100 text-gray-900 py-0.5 px-2.5 rounded-full text-xs">
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Toolbar */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex justify-between items-center">
            <div className="flex-1 max-w-md">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder={`Search ${activeTab}...`}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              {activeTab !== 'logs' && activeTab !== 'stats' && (
                <button
                  onClick={() => setShowCreateModal(true)}
                  className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Add {activeTab.slice(0, -1)}
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          {/* Templates Tab */}
          {activeTab === 'templates' && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filterItems(templates).map((template) => {
                const TypeIcon = getTypeIcon(template.type);
                return (
                  <div key={template.id} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center">
                        <TypeIcon className="h-8 w-8 text-blue-600 mr-3" />
                        <div>
                          <h3 className="text-lg font-medium text-gray-900">{template.name}</h3>
                          <p className="text-sm text-gray-500">{template.type.toUpperCase()}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-1">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(template.metadata.priority)}`}>
                          {template.metadata.priority}
                        </span>
                        {template.isActive ? (
                          <CheckCircle className="h-5 w-5 text-green-500" />
                        ) : (
                          <AlertCircle className="h-5 w-5 text-gray-400" />
                        )}
                      </div>
                    </div>
                    
                    <div className="mb-4">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                        {template.category}
                      </span>
                    </div>
                    
                    {template.subject && (
                      <div className="mb-2">
                        <div className="text-sm font-medium text-gray-700">Subject:</div>
                        <div className="text-sm text-gray-600 truncate">{template.subject}</div>
                      </div>
                    )}
                    
                    <div className="mb-4">
                      <div className="text-sm font-medium text-gray-700">Variables:</div>
                      <div className="text-sm text-gray-600">{template.variables.length} defined</div>
                    </div>
                    
                    <div className="flex items-center justify-between">
                      <div className="text-xs text-gray-500">
                        {template.isSystem ? 'System Template' : 'Custom Template'}
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => {
                            setEditingItem({ ...template });
                            setShowEditModal(true);
                          }}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                          title="Edit"
                        >
                          <Edit3 className="h-4 w-4" />
                        </button>
                        
                        {!template.isSystem && (
                          <button
                            className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
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
              
              {filterItems(templates).length === 0 && (
                <div className="col-span-full text-center py-12">
                  <Mail className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No templates found</h3>
                  <p className="text-gray-600">Create your first notification template to get started.</p>
                </div>
              )}
            </div>
          )}

          {/* Rules Tab */}
          {activeTab === 'rules' && (
            <div className="space-y-4">
              {filterItems(rules).map((rule) => (
                <div key={rule.id} className="border border-gray-200 rounded-lg p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center mb-2">
                        <h3 className="text-lg font-medium text-gray-900 mr-3">{rule.name}</h3>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(rule.priority)}`}>
                          {rule.priority}
                        </span>
                        {rule.isActive ? (
                          <CheckCircle className="h-5 w-5 text-green-500 ml-2" />
                        ) : (
                          <Square className="h-5 w-5 text-gray-400 ml-2" />
                        )}
                      </div>
                      
                      <p className="text-gray-600 mb-4">{rule.description}</p>
                      
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                        <div>
                          <span className="font-medium text-gray-700">Trigger:</span>
                          <div className="text-gray-600">{rule.triggerEvent}</div>
                        </div>
                        <div>
                          <span className="font-medium text-gray-700">Conditions:</span>
                          <div className="text-gray-600">{rule.conditions.length} defined</div>
                        </div>
                        <div>
                          <span className="font-medium text-gray-700">Channels:</span>
                          <div className="text-gray-600">{rule.channels.length} configured</div>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2 ml-4">
                      <button
                        onClick={() => handleToggleRule(rule.id, !rule.isActive)}
                        className={`p-2 rounded text-white ${
                          rule.isActive ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
                        }`}
                        title={rule.isActive ? 'Disable' : 'Enable'}
                      >
                        {rule.isActive ? <Square className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                      </button>
                      
                      <button
                        onClick={() => {
                          setEditingItem({ ...rule });
                          setShowEditModal(true);
                        }}
                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                        title="Edit"
                      >
                        <Edit3 className="h-4 w-4" />
                      </button>
                      
                      <button
                        className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
                        title="Delete"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
              
              {filterItems(rules).length === 0 && (
                <div className="text-center py-12">
                  <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No rules found</h3>
                  <p className="text-gray-600">Create notification rules to automate your communications.</p>
                </div>
              )}
            </div>
          )}

          {/* Channels Tab */}
          {activeTab === 'channels' && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filterItems(channels).map((channel) => {
                const TypeIcon = getTypeIcon(channel.type);
                return (
                  <div key={channel.id} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center">
                        <TypeIcon className="h-8 w-8 text-blue-600 mr-3" />
                        <div>
                          <h3 className="text-lg font-medium text-gray-900">{channel.name}</h3>
                          <p className="text-sm text-gray-500">{channel.type.toUpperCase()}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-1">
                        {channel.isDefault && (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            Default
                          </span>
                        )}
                        {channel.healthCheck.isHealthy ? (
                          <CheckCircle className="h-5 w-5 text-green-500" />
                        ) : (
                          <AlertTriangle className="h-5 w-5 text-red-500" />
                        )}
                      </div>
                    </div>
                    
                    <div className="space-y-3 mb-4">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Status:</span>
                        <span className={channel.isActive ? 'text-green-600' : 'text-red-600'}>
                          {channel.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Total Sent:</span>
                        <span className="text-gray-900">{channel.metrics.totalSent}</span>
                      </div>
                      
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Success Rate:</span>
                        <span className="text-gray-900">
                          {channel.metrics.totalSent > 0 
                            ? Math.round((channel.metrics.successfulSent / channel.metrics.totalSent) * 100) + '%'
                            : 'N/A'}
                        </span>
                      </div>
                    </div>
                    
                    {channel.healthCheck.errorMessage && (
                      <div className="mb-4 p-2 bg-red-50 border border-red-200 rounded text-xs text-red-800">
                        <AlertTriangle className="h-3 w-3 inline mr-1" />
                        {channel.healthCheck.errorMessage}
                      </div>
                    )}
                    
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => handleTestChannel(channel.id)}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                          title="Test Channel"
                        >
                          <TestTube className="h-4 w-4" />
                        </button>
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => {
                            setEditingItem({ ...channel });
                            setShowEditModal(true);
                          }}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                          title="Edit"
                        >
                          <Edit3 className="h-4 w-4" />
                        </button>
                        
                        <button
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
              
              {filterItems(channels).length === 0 && (
                <div className="col-span-full text-center py-12">
                  <Zap className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No channels found</h3>
                  <p className="text-gray-600">Configure delivery channels to send notifications.</p>
                </div>
              )}
            </div>
          )}

          {/* Logs Tab */}
          {activeTab === 'logs' && (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Timestamp
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Type
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Recipient
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Subject
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {logs.map((log) => {
                    const TypeIcon = getTypeIcon(log.type);
                    return (
                      <tr key={log.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {new Date(log.createdAt).toLocaleString()}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <TypeIcon className="h-4 w-4 text-gray-400 mr-2" />
                            <span className="text-sm text-gray-900">{log.type.toUpperCase()}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {log.recipient}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(log.status)}`}>
                            {log.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-900 max-w-xs truncate">
                          {log.subject || 'No subject'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <button
                            className="p-1 text-gray-400 hover:text-blue-600"
                            title="View Details"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>

              {logs.length === 0 && (
                <div className="text-center py-12">
                  <Activity className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No logs found</h3>
                  <p className="text-gray-600">Notification logs will appear here once notifications are sent.</p>
                </div>
              )}
            </div>
          )}

          {/* Statistics Tab */}
          {activeTab === 'stats' && stats && (
            <div className="space-y-6">
              {/* Summary Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div className="bg-blue-50 p-6 rounded-lg">
                  <div className="flex items-center">
                    <Bell className="h-8 w-8 text-blue-600 mr-3" />
                    <div>
                      <div className="text-2xl font-bold text-blue-900">{stats.totalNotifications}</div>
                      <div className="text-sm text-blue-600">Total Notifications</div>
                    </div>
                  </div>
                </div>
                
                <div className="bg-green-50 p-6 rounded-lg">
                  <div className="flex items-center">
                    <CheckCircle className="h-8 w-8 text-green-600 mr-3" />
                    <div>
                      <div className="text-2xl font-bold text-green-900">{stats.sentNotifications}</div>
                      <div className="text-sm text-green-600">Successfully Sent</div>
                    </div>
                  </div>
                </div>
                
                <div className="bg-red-50 p-6 rounded-lg">
                  <div className="flex items-center">
                    <AlertCircle className="h-8 w-8 text-red-600 mr-3" />
                    <div>
                      <div className="text-2xl font-bold text-red-900">{stats.failedNotifications}</div>
                      <div className="text-sm text-red-600">Failed</div>
                    </div>
                  </div>
                </div>
                
                <div className="bg-purple-50 p-6 rounded-lg">
                  <div className="flex items-center">
                    <BarChart3 className="h-8 w-8 text-purple-600 mr-3" />
                    <div>
                      <div className="text-2xl font-bold text-purple-900">{stats.deliveryRate.toFixed(1)}%</div>
                      <div className="text-sm text-purple-600">Delivery Rate</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Channel Statistics */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white border border-gray-200 rounded-lg p-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">By Channel</h3>
                  <div className="space-y-3">
                    {stats.byChannel.map((channel) => (
                      <div key={channel.type} className="flex items-center justify-between">
                        <div className="flex items-center">
                          {React.createElement(getTypeIcon(channel.type), { className: "h-4 w-4 text-gray-400 mr-2" })}
                          <span className="text-sm font-medium text-gray-900">{channel.type.toUpperCase()}</span>
                        </div>
                        <div className="text-sm text-gray-600">
                          {channel.sent}/{channel.total} ({channel.total > 0 ? Math.round((channel.sent / channel.total) * 100) : 0}%)
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-white border border-gray-200 rounded-lg p-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">By Category</h3>
                  <div className="space-y-3">
                    {stats.byCategory.map((category) => (
                      <div key={category.category} className="flex items-center justify-between">
                        <span className="text-sm font-medium text-gray-900">{category.category}</span>
                        <div className="text-sm text-gray-600">
                          {category.sent}/{category.total} ({category.total > 0 ? Math.round((category.sent / category.total) * 100) : 0}%)
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Failure Reasons */}
              {stats.topFailureReasons.length > 0 && (
                <div className="bg-white border border-gray-200 rounded-lg p-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Top Failure Reasons</h3>
                  <div className="space-y-3">
                    {stats.topFailureReasons.map((reason, index) => (
                      <div key={index} className="flex items-center justify-between">
                        <span className="text-sm text-gray-900">{reason.reason}</span>
                        <span className="text-sm font-medium text-red-600">{reason.count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Test Result Modal */}
      {showTestModal && testResult && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-lg w-full">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Channel Test Result</h3>
            </div>
            <div className="p-6">
              <div className={`flex items-center mb-4 ${testResult.success ? 'text-green-800' : 'text-red-800'}`}>
                {testResult.success ? (
                  <CheckCircle className="h-6 w-6 mr-2 text-green-500" />
                ) : (
                  <AlertCircle className="h-6 w-6 mr-2 text-red-500" />
                )}
                <span className="font-medium">
                  {testResult.success ? 'Test Successful' : 'Test Failed'}
                </span>
              </div>
              
              <div className="space-y-2 text-sm">
                <div>
                  <span className="font-medium">Message:</span> {testResult.message}
                </div>
                {testResult.deliveryTime && (
                  <div>
                    <span className="font-medium">Delivery Time:</span> {testResult.deliveryTime}ms
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

export default NotificationSettings;