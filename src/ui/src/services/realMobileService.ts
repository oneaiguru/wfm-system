/**
 * REAL Mobile Service - Mobile real-time sync capability
 * NO MOCK DATA - connects to real INTEGRATION-OPUS mobile endpoints
 * Following pattern from realDashboardService.ts
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface MobileSync {
  lastSync: string;
  pendingActions: number;
  onlineStatus: 'online' | 'offline' | 'syncing';
  syncQueue: SyncAction[];
}

export interface SyncAction {
  id: string;
  type: 'request' | 'shift_exchange' | 'notification_read' | 'profile_update';
  data: any;
  timestamp: string;
  status: 'pending' | 'syncing' | 'completed' | 'failed';
}

export interface MobileData {
  user: {
    id: string;
    name: string;
    avatar?: string;
    department: string;
    role: string;
  };
  schedule: {
    shifts: Array<{
      id: string;
      date: string;
      startTime: string;
      endTime: string;
      type: string;
      status: string;
    }>;
    requests: Array<{
      id: string;
      type: string;
      status: string;
      date: string;
      description: string;
    }>;
  };
  notifications: Array<{
    id: string;
    title: string;
    message: string;
    type: 'info' | 'warning' | 'success' | 'error';
    timestamp: string;
    read: boolean;
  }>;
  exchanges: Array<{
    id: string;
    fromUser: string;
    toUser: string;
    shiftDate: string;
    shiftTime: string;
    status: 'pending' | 'accepted' | 'rejected';
    type: 'offer' | 'request';
  }>;
}

const API_BASE_URL = 'http://localhost:8000/api/v1';
const WS_BASE_URL = 'ws://localhost:8000/ws';

class RealMobileService {
  private ws: WebSocket | null = null;
  private syncInterval: NodeJS.Timeout | null = null;
  private onlineStatus: 'online' | 'offline' | 'syncing' = 'offline';
  private listeners: Array<(data: MobileData) => void> = [];

  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL MOBILE API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          ...options.headers,
        },
        ...options,
      });

      console.log(`[REAL MOBILE API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[REAL MOBILE API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[REAL MOBILE API] Success response:`, data);
      
      return {
        success: true,
        data: data as T
      };

    } catch (error) {
      console.error(`[REAL MOBILE API] Request failed:`, error);
      
      // NO MOCK FALLBACK - return real error
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  private getAuthToken(): string {
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('No authentication token found');
    }
    return token;
  }

  async getMobileData(): Promise<ApiResponse<MobileData>> {
    console.log('[REAL MOBILE API] Fetching mobile data...');
    
    return this.makeRequest<MobileData>('/mobile/data');
  }

  async syncOfflineData(): Promise<ApiResponse<{ synced: number; failed: number }>> {
    console.log('[REAL MOBILE API] Syncing offline data...');
    
    const pendingActions = this.getPendingActions();
    
    return this.makeRequest<{ synced: number; failed: number }>('/mobile/sync', {
      method: 'POST',
      body: JSON.stringify({ actions: pendingActions })
    });
  }

  async queueOfflineAction(action: Omit<SyncAction, 'id' | 'timestamp' | 'status'>): Promise<void> {
    const syncAction: SyncAction = {
      id: Date.now().toString(),
      timestamp: new Date().toISOString(),
      status: 'pending',
      ...action
    };
    
    console.log('[REAL MOBILE API] Queueing offline action:', syncAction);
    
    // Store in localStorage for offline capability
    const existing = this.getPendingActions();
    existing.push(syncAction);
    localStorage.setItem('mobileSyncQueue', JSON.stringify(existing));
    
    // Try to sync immediately if online
    if (this.onlineStatus === 'online') {
      await this.syncOfflineData();
    }
  }

  private getPendingActions(): SyncAction[] {
    const stored = localStorage.getItem('mobileSyncQueue');
    return stored ? JSON.parse(stored) : [];
  }

  private clearPendingActions(): void {
    localStorage.removeItem('mobileSyncQueue');
  }

  async getCachedData(): Promise<MobileData | null> {
    const cached = localStorage.getItem('mobileDataCache');
    return cached ? JSON.parse(cached) : null;
  }

  private setCachedData(data: MobileData): void {
    localStorage.setItem('mobileDataCache', JSON.stringify(data));
    localStorage.setItem('mobileDataCacheTime', new Date().toISOString());
  }

  startRealTimeSync(): () => void {
    console.log('[REAL MOBILE API] Starting real-time sync...');
    
    // WebSocket connection for real-time updates
    this.connectWebSocket();
    
    // Periodic sync every 30 seconds
    this.syncInterval = setInterval(async () => {
      if (navigator.onLine && this.onlineStatus !== 'syncing') {
        await this.performSync();
      }
    }, 30000);
    
    // Network status listeners
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);
    
    // Initial sync
    this.performSync();
    
    // Return cleanup function
    return () => {
      console.log('[REAL MOBILE API] Stopping real-time sync...');
      
      if (this.ws) {
        this.ws.close();
        this.ws = null;
      }
      
      if (this.syncInterval) {
        clearInterval(this.syncInterval);
        this.syncInterval = null;
      }
      
      window.removeEventListener('online', this.handleOnline);
      window.removeEventListener('offline', this.handleOffline);
    };
  }

  private connectWebSocket(): void {
    try {
      this.ws = new WebSocket(`${WS_BASE_URL}/mobile/stream`);
      
      this.ws.onopen = () => {
        console.log('[REAL MOBILE API] WebSocket connected');
        this.onlineStatus = 'online';
        
        // Send authentication
        this.ws?.send(JSON.stringify({
          type: 'auth',
          token: this.getAuthToken()
        }));
      };
      
      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log('[REAL MOBILE API] Received update:', data);
          
          if (data.type === 'mobile_data_update') {
            this.setCachedData(data.data);
            this.notifyListeners(data.data);
          }
        } catch (error) {
          console.error('[REAL MOBILE API] Failed to parse WebSocket message:', error);
        }
      };
      
      this.ws.onclose = () => {
        console.log('[REAL MOBILE API] WebSocket disconnected');
        this.onlineStatus = 'offline';
        
        // Attempt to reconnect after 5 seconds
        setTimeout(() => {
          if (navigator.onLine) {
            this.connectWebSocket();
          }
        }, 5000);
      };
      
      this.ws.onerror = (error) => {
        console.error('[REAL MOBILE API] WebSocket error:', error);
        this.onlineStatus = 'offline';
      };
      
    } catch (error) {
      console.error('[REAL MOBILE API] Failed to connect WebSocket:', error);
      this.onlineStatus = 'offline';
    }
  }

  private handleOnline = async () => {
    console.log('[REAL MOBILE API] Device came online');
    this.onlineStatus = 'online';
    
    // Reconnect WebSocket if needed
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.connectWebSocket();
    }
    
    // Sync any pending actions
    await this.performSync();
  };

  private handleOffline = () => {
    console.log('[REAL MOBILE API] Device went offline');
    this.onlineStatus = 'offline';
  };

  private async performSync(): Promise<void> {
    if (!navigator.onLine) {
      this.onlineStatus = 'offline';
      return;
    }
    
    try {
      this.onlineStatus = 'syncing';
      
      // Sync pending actions
      const pendingActions = this.getPendingActions();
      if (pendingActions.length > 0) {
        const syncResult = await this.syncOfflineData();
        if (syncResult.success) {
          this.clearPendingActions();
          console.log(`[REAL MOBILE API] Synced ${syncResult.data?.synced} actions`);
        }
      }
      
      // Fetch fresh data
      const dataResult = await this.getMobileData();
      if (dataResult.success && dataResult.data) {
        this.setCachedData(dataResult.data);
        this.notifyListeners(dataResult.data);
      }
      
      this.onlineStatus = 'online';
      
    } catch (error) {
      console.error('[REAL MOBILE API] Sync failed:', error);
      this.onlineStatus = 'offline';
    }
  }

  subscribeToUpdates(callback: (data: MobileData) => void): () => void {
    this.listeners.push(callback);
    
    return () => {
      this.listeners = this.listeners.filter(listener => listener !== callback);
    };
  }

  private notifyListeners(data: MobileData): void {
    this.listeners.forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        console.error('[REAL MOBILE API] Listener error:', error);
      }
    });
  }

  getSyncStatus(): MobileSync {
    const pendingActions = this.getPendingActions();
    const lastSync = localStorage.getItem('mobileDataCacheTime') || new Date().toISOString();
    
    return {
      lastSync,
      pendingActions: pendingActions.length,
      onlineStatus: this.onlineStatus,
      syncQueue: pendingActions
    };
  }

  // Health check
  async checkMobileApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL MOBILE API] Checking mobile API health...');
      
      const response = await fetch(`${API_BASE_URL}/mobile/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL MOBILE API] Mobile API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL MOBILE API] Health check failed:', error);
      return false;
    }
  }
}

export const realMobileService = new RealMobileService();
export default realMobileService;