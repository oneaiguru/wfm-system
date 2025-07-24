/**
 * Sync Manager Component
 * Provides manual sync controls and displays sync queue status
 */
import React, { useState, useEffect } from 'react';
import { RefreshCw, Upload, Download, Settings, AlertCircle, CheckCircle, XCircle } from 'lucide-react';

interface SyncItem {
  id: string;
  type: string;
  created_offline: string;
  retry_count: number;
  status: 'pending' | 'syncing' | 'completed' | 'failed';
  data?: any;
}

interface SyncStatus {
  overall_status: string;
  last_sync: string;
  next_sync_scheduled: string;
  sync_mode: string;
  connection_type: string;
  data_status: Record<string, any>;
  sync_queue: {
    pending_items: SyncItem[];
    failed_items: SyncItem[];
    completed_today: number;
  };
  storage_info: {
    total_cache_size: string;
    available_space: string;
    cache_limit: string;
    auto_cleanup_enabled: boolean;
  };
  sync_settings: {
    wifi_only: boolean;
    background_sync: boolean;
    sync_interval: string;
    data_retention_days: number;
  };
}

interface SyncManagerProps {
  className?: string;
}

export const SyncManager: React.FC<SyncManagerProps> = ({ className = '' }) => {
  const [syncStatus, setSyncStatus] = useState<SyncStatus | null>(null);
  const [isManualSyncing, setIsManualSyncing] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch sync status
  const fetchSyncStatus = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('/api/v1/mobile/cabinet/sync/status', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setSyncStatus(data);
        setError(null);
      } else {
        throw new Error('Failed to fetch sync status');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  // Manual sync trigger
  const triggerManualSync = async () => {
    setIsManualSyncing(true);
    try {
      const token = localStorage.getItem('auth_token');
      
      // Get offline changes from localStorage
      const offlineChanges = JSON.parse(localStorage.getItem('offline_changes') || '[]');
      
      if (offlineChanges.length > 0) {
        const response = await fetch('/api/v1/mobile/sync/upload-changes', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ offline_changes: offlineChanges })
        });

        if (response.ok) {
          const result = await response.json();
          console.log('Sync completed:', result);
          
          // Clear successfully synced items
          if (result.processed_changes?.length > 0) {
            const processedIds = result.processed_changes.map((c: any) => c.change_id);
            const remainingChanges = offlineChanges.filter((change: any) => !processedIds.includes(change.id));
            localStorage.setItem('offline_changes', JSON.stringify(remainingChanges));
          }
        }
      }

      // Refresh status
      await fetchSyncStatus();
    } catch (err) {
      console.error('Manual sync failed:', err);
      setError('Manual sync failed');
    } finally {
      setIsManualSyncing(false);
    }
  };

  // Retry failed sync item
  const retryFailedItem = async (itemId: string) => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/mobile/sync/retry/${itemId}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        await fetchSyncStatus();
      }
    } catch (err) {
      console.error('Retry failed:', err);
    }
  };

  // Clear cache
  const clearCache = async () => {
    try {
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map(name => caches.delete(name)));
      }
      
      // Clear localStorage offline data
      localStorage.removeItem('offline_changes');
      localStorage.removeItem('cached_schedule');
      localStorage.removeItem('cached_requests');
      
      await fetchSyncStatus();
    } catch (err) {
      console.error('Clear cache failed:', err);
    }
  };

  useEffect(() => {
    fetchSyncStatus();
    const interval = setInterval(fetchSyncStatus, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className={`p-4 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="animate-pulse">
          <div className="h-4 bg-gray-300 rounded w-1/4 mb-2"></div>
          <div className="h-3 bg-gray-300 rounded w-1/2"></div>
        </div>
      </div>
    );
  }

  if (error || !syncStatus) {
    return (
      <div className={`p-4 bg-red-50 border border-red-200 rounded-lg ${className}`}>
        <div className="flex items-center gap-2 text-red-700">
          <XCircle className="w-4 h-4" />
          <span className="text-sm font-medium">Sync Error</span>
        </div>
        <p className="text-red-600 text-xs mt-1">{error || 'Failed to load sync status'}</p>
        <button
          onClick={fetchSyncStatus}
          className="text-red-700 text-xs underline mt-2"
        >
          Retry
        </button>
      </div>
    );
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const getSyncStatusIcon = (status: string) => {
    switch (status) {
      case 'synchronized':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'syncing':
        return <RefreshCw className="w-4 h-4 text-blue-500 animate-spin" />;
      default:
        return <AlertCircle className="w-4 h-4 text-yellow-500" />;
    }
  };

  const getItemStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-3 h-3 text-green-500" />;
      case 'failed':
        return <XCircle className="w-3 h-3 text-red-500" />;
      case 'syncing':
        return <RefreshCw className="w-3 h-3 text-blue-500 animate-spin" />;
      default:
        return <AlertCircle className="w-3 h-3 text-yellow-500" />;
    }
  };

  return (
    <div className={`bg-white border border-gray-200 rounded-lg ${className}`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {getSyncStatusIcon(syncStatus.overall_status)}
            <h3 className="font-medium text-gray-900">Sync Manager</h3>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={triggerManualSync}
              disabled={isManualSyncing || !navigator.onLine}
              className="flex items-center gap-1 px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <RefreshCw className={`w-3 h-3 ${isManualSyncing ? 'animate-spin' : ''}`} />
              Sync Now
            </button>
            <button
              onClick={() => setShowSettings(!showSettings)}
              className="p-1 text-gray-400 hover:text-gray-600"
            >
              <Settings className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Status Summary */}
        <div className="mt-3 grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-gray-600">Status:</span>
            <span className="ml-2 text-gray-900">{syncStatus.overall_status}</span>
          </div>
          <div>
            <span className="text-gray-600">Last sync:</span>
            <span className="ml-2 text-gray-900">{formatDate(syncStatus.last_sync)}</span>
          </div>
          <div>
            <span className="text-gray-600">Pending:</span>
            <span className="ml-2 text-gray-900">{syncStatus.sync_queue.pending_items.length}</span>
          </div>
          <div>
            <span className="text-gray-600">Completed today:</span>
            <span className="ml-2 text-gray-900">{syncStatus.sync_queue.completed_today}</span>
          </div>
        </div>
      </div>

      {/* Sync Queue */}
      {(syncStatus.sync_queue.pending_items.length > 0 || syncStatus.sync_queue.failed_items.length > 0) && (
        <div className="p-4 border-b border-gray-200">
          <h4 className="font-medium text-gray-900 mb-3">Sync Queue</h4>
          
          {/* Pending Items */}
          {syncStatus.sync_queue.pending_items.length > 0 && (
            <div className="mb-3">
              <div className="flex items-center gap-2 mb-2">
                <Upload className="w-3 h-3 text-blue-500" />
                <span className="text-sm font-medium text-gray-700">Pending ({syncStatus.sync_queue.pending_items.length})</span>
              </div>
              <div className="space-y-1">
                {syncStatus.sync_queue.pending_items.slice(0, 3).map((item) => (
                  <div key={item.id} className="flex items-center justify-between p-2 bg-blue-50 rounded text-xs">
                    <div className="flex items-center gap-2">
                      {getItemStatusIcon(item.status)}
                      <span className="text-gray-900">{item.type.replace('_', ' ')}</span>
                    </div>
                    <span className="text-gray-600">{formatDate(item.created_offline)}</span>
                  </div>
                ))}
                {syncStatus.sync_queue.pending_items.length > 3 && (
                  <div className="text-xs text-gray-500 text-center py-1">
                    +{syncStatus.sync_queue.pending_items.length - 3} more items
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Failed Items */}
          {syncStatus.sync_queue.failed_items.length > 0 && (
            <div>
              <div className="flex items-center gap-2 mb-2">
                <XCircle className="w-3 h-3 text-red-500" />
                <span className="text-sm font-medium text-gray-700">Failed ({syncStatus.sync_queue.failed_items.length})</span>
              </div>
              <div className="space-y-1">
                {syncStatus.sync_queue.failed_items.map((item) => (
                  <div key={item.id} className="flex items-center justify-between p-2 bg-red-50 rounded text-xs">
                    <div className="flex items-center gap-2">
                      {getItemStatusIcon(item.status)}
                      <span className="text-gray-900">{item.type.replace('_', ' ')}</span>
                      <span className="text-red-600">(retry #{item.retry_count})</span>
                    </div>
                    <button
                      onClick={() => retryFailedItem(item.id)}
                      className="text-red-600 hover:text-red-800 underline"
                    >
                      Retry
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Data Status */}
      <div className="p-4 border-b border-gray-200">
        <h4 className="font-medium text-gray-900 mb-3">Data Status</h4>
        <div className="grid grid-cols-2 gap-3 text-xs">
          {Object.entries(syncStatus.data_status).map(([key, status]: [string, any]) => (
            <div key={key} className="flex items-center justify-between p-2 bg-gray-50 rounded">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${
                  status.status === 'up_to_date' ? 'bg-green-500' : 
                  status.status === 'syncing' ? 'bg-blue-500' : 'bg-yellow-500'
                }`}></div>
                <span className="text-gray-900 capitalize">{key}</span>
              </div>
              <span className="text-gray-600">{status.size}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && (
        <div className="p-4">
          <h4 className="font-medium text-gray-900 mb-3">Sync Settings</h4>
          <div className="space-y-3 text-sm">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">WiFi Only</span>
              <div className={`w-10 h-5 rounded-full ${syncStatus.sync_settings.wifi_only ? 'bg-blue-500' : 'bg-gray-300'} relative`}>
                <div className={`w-4 h-4 bg-white rounded-full absolute top-0.5 transition-transform ${syncStatus.sync_settings.wifi_only ? 'translate-x-5' : 'translate-x-0.5'}`}></div>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Background Sync</span>
              <div className={`w-10 h-5 rounded-full ${syncStatus.sync_settings.background_sync ? 'bg-blue-500' : 'bg-gray-300'} relative`}>
                <div className={`w-4 h-4 bg-white rounded-full absolute top-0.5 transition-transform ${syncStatus.sync_settings.background_sync ? 'translate-x-5' : 'translate-x-0.5'}`}></div>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Sync Interval</span>
              <span className="text-gray-900">{syncStatus.sync_settings.sync_interval}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Data Retention</span>
              <span className="text-gray-900">{syncStatus.sync_settings.data_retention_days} days</span>
            </div>
          </div>

          {/* Storage Info */}
          <div className="mt-4 pt-3 border-t border-gray-200">
            <h5 className="font-medium text-gray-900 text-sm mb-2">Storage</h5>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-gray-600">Cache size:</span>
                <span className="text-gray-900">{syncStatus.storage_info.total_cache_size}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Available space:</span>
                <span className="text-gray-900">{syncStatus.storage_info.available_space}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Cache limit:</span>
                <span className="text-gray-900">{syncStatus.storage_info.cache_limit}</span>
              </div>
            </div>
            <button
              onClick={clearCache}
              className="mt-2 text-xs text-red-600 hover:text-red-800 underline"
            >
              Clear Cache
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default SyncManager;