/**
 * Offline Mode Indicator Component
 * Shows real-time network connectivity status with visual indicators
 */
import React, { useState, useEffect } from 'react';
import { Wifi, WifiOff, Clock, CheckCircle, AlertTriangle } from 'lucide-react';

interface OfflineIndicatorProps {
  className?: string;
  showDetails?: boolean;
}

interface ConnectionStatus {
  online: boolean;
  connectionType?: string;
  effectiveType?: string;
  downlink?: number;
  rtt?: number;
  saveData?: boolean;
}

interface SyncStatus {
  status: 'synchronized' | 'syncing' | 'pending' | 'error';
  lastSync: Date | null;
  pendingChanges: number;
  syncProgress?: number;
}

export const OfflineIndicator: React.FC<OfflineIndicatorProps> = ({ 
  className = '', 
  showDetails = false 
}) => {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>({
    online: navigator.onLine
  });
  const [syncStatus, setSyncStatus] = useState<SyncStatus>({
    status: 'synchronized',
    lastSync: new Date(),
    pendingChanges: 0
  });

  // Monitor network connection
  useEffect(() => {
    const updateConnectionStatus = () => {
      const connection = (navigator as any).connection || (navigator as any).mozConnection || (navigator as any).webkitConnection;
      
      setConnectionStatus({
        online: navigator.onLine,
        connectionType: connection?.type,
        effectiveType: connection?.effectiveType,
        downlink: connection?.downlink,
        rtt: connection?.rtt,
        saveData: connection?.saveData
      });
    };

    const handleOnline = () => updateConnectionStatus();
    const handleOffline = () => updateConnectionStatus();

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    // Update connection info on change
    const connection = (navigator as any).connection;
    if (connection) {
      connection.addEventListener('change', updateConnectionStatus);
    }

    // Initial update
    updateConnectionStatus();

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      if (connection) {
        connection.removeEventListener('change', updateConnectionStatus);
      }
    };
  }, []);

  // Fetch sync status from API
  useEffect(() => {
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
          setSyncStatus({
            status: data.sync_status?.overall_status === 'synchronized' ? 'synchronized' : 'syncing',
            lastSync: new Date(data.sync_status?.last_sync),
            pendingChanges: data.sync_queue?.pending_items?.length || 0,
            syncProgress: data.sync_queue?.pending_items?.length > 0 ? 75 : 100
          });
        }
      } catch (error) {
        console.warn('Failed to fetch sync status:', error);
        setSyncStatus(prev => ({ ...prev, status: 'error' }));
      }
    };

    fetchSyncStatus();
    const interval = setInterval(fetchSyncStatus, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, []);

  const getStatusIcon = () => {
    if (!connectionStatus.online) {
      return <WifiOff className="w-4 h-4 text-red-500" />;
    }
    
    switch (syncStatus.status) {
      case 'synchronized':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'syncing':
        return <Clock className="w-4 h-4 text-blue-500 animate-spin" />;
      case 'pending':
        return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'error':
        return <AlertTriangle className="w-4 h-4 text-red-500" />;
      default:
        return <Wifi className="w-4 h-4 text-gray-500" />;
    }
  };

  const getStatusText = () => {
    if (!connectionStatus.online) {
      return 'Offline';
    }
    
    switch (syncStatus.status) {
      case 'synchronized':
        return 'Online';
      case 'syncing':
        return 'Syncing...';
      case 'pending':
        return `${syncStatus.pendingChanges} pending`;
      case 'error':
        return 'Sync error';
      default:
        return 'Unknown';
    }
  };

  const getStatusColor = () => {
    if (!connectionStatus.online) return 'bg-red-50 border-red-200';
    
    switch (syncStatus.status) {
      case 'synchronized':
        return 'bg-green-50 border-green-200';
      case 'syncing':
        return 'bg-blue-50 border-blue-200';
      case 'pending':
        return 'bg-yellow-50 border-yellow-200';
      case 'error':
        return 'bg-red-50 border-red-200';
      default:
        return 'bg-gray-50 border-gray-200';
    }
  };

  const formatLastSync = () => {
    if (!syncStatus.lastSync) return 'Never';
    
    const now = new Date();
    const diff = now.getTime() - syncStatus.lastSync.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  };

  return (
    <div className={`inline-flex items-center gap-2 ${className}`}>
      {/* Compact indicator */}
      <div className={`flex items-center gap-1 px-2 py-1 rounded-full border text-xs font-medium ${getStatusColor()}`}>
        {getStatusIcon()}
        <span>{getStatusText()}</span>
      </div>

      {/* Detailed status panel */}
      {showDetails && (
        <div className="absolute top-full left-0 mt-2 w-80 bg-white border border-gray-200 rounded-lg shadow-lg p-4 z-50">
          <div className="space-y-3">
            {/* Connection Status */}
            <div>
              <h4 className="font-medium text-gray-900 mb-2">Connection Status</h4>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Status:</span>
                  <span className={connectionStatus.online ? 'text-green-600' : 'text-red-600'}>
                    {connectionStatus.online ? 'Online' : 'Offline'}
                  </span>
                </div>
                {connectionStatus.connectionType && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Type:</span>
                    <span className="text-gray-900">{connectionStatus.connectionType}</span>
                  </div>
                )}
                {connectionStatus.effectiveType && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Speed:</span>
                    <span className="text-gray-900">{connectionStatus.effectiveType}</span>
                  </div>
                )}
                {connectionStatus.downlink && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Download:</span>
                    <span className="text-gray-900">{connectionStatus.downlink} Mbps</span>
                  </div>
                )}
              </div>
            </div>

            {/* Sync Status */}
            <div className="border-t pt-3">
              <h4 className="font-medium text-gray-900 mb-2">Sync Status</h4>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Last sync:</span>
                  <span className="text-gray-900">{formatLastSync()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Pending changes:</span>
                  <span className="text-gray-900">{syncStatus.pendingChanges}</span>
                </div>
                {syncStatus.syncProgress !== undefined && syncStatus.syncProgress < 100 && (
                  <div>
                    <div className="flex justify-between mb-1">
                      <span className="text-gray-600">Progress:</span>
                      <span className="text-gray-900">{syncStatus.syncProgress}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                        style={{ width: `${syncStatus.syncProgress}%` }}
                      ></div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Offline Mode Notice */}
            {!connectionStatus.online && (
              <div className="border-t pt-3">
                <div className="bg-blue-50 border border-blue-200 rounded p-3">
                  <div className="flex items-start gap-2">
                    <Clock className="w-4 h-4 text-blue-500 mt-0.5" />
                    <div className="text-sm">
                      <p className="font-medium text-blue-900">Offline Mode Active</p>
                      <p className="text-blue-700 mt-1">
                        Your changes are being saved locally and will sync when connection is restored.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default OfflineIndicator;