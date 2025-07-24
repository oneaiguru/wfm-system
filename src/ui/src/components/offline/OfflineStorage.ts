/**
 * Offline Storage Utility
 * Handles client-side caching and offline data management
 */

interface OfflineChange {
  id: string;
  type: string;
  data: any;
  timestamp: string;
  retry_count: number;
  status: 'pending' | 'failed' | 'synced';
}

interface CacheEntry<T> {
  data: T;
  timestamp: string;
  expiry?: string;
  version: string;
}

interface StorageQuota {
  usage: number;
  quota: number;
  available: number;
}

export class OfflineStorage {
  private static instance: OfflineStorage;
  private dbName = 'wfm_offline_db';
  private dbVersion = 1;
  private db: IDBDatabase | null = null;

  private constructor() {}

  public static getInstance(): OfflineStorage {
    if (!OfflineStorage.instance) {
      OfflineStorage.instance = new OfflineStorage();
    }
    return OfflineStorage.instance;
  }

  // Initialize IndexedDB
  public async initialize(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Create object stores
        if (!db.objectStoreNames.contains('cache')) {
          const cacheStore = db.createObjectStore('cache', { keyPath: 'key' });
          cacheStore.createIndex('expiry', 'expiry', { unique: false });
        }

        if (!db.objectStoreNames.contains('offline_changes')) {
          const changesStore = db.createObjectStore('offline_changes', { keyPath: 'id' });
          changesStore.createIndex('timestamp', 'timestamp', { unique: false });
          changesStore.createIndex('status', 'status', { unique: false });
        }

        if (!db.objectStoreNames.contains('user_data')) {
          db.createObjectStore('user_data', { keyPath: 'key' });
        }
      };
    });
  }

  // Cache Management
  public async setCache<T>(key: string, data: T, ttl?: number): Promise<void> {
    if (!this.db) await this.initialize();

    const entry: CacheEntry<T> = {
      data,
      timestamp: new Date().toISOString(),
      version: '1.0'
    };

    if (ttl) {
      entry.expiry = new Date(Date.now() + ttl * 1000).toISOString();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const request = store.put({ key, ...entry });

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  public async getCache<T>(key: string): Promise<T | null> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['cache'], 'readonly');
      const store = transaction.objectStore('cache');
      const request = store.get(key);

      request.onsuccess = () => {
        const result = request.result;
        if (!result) {
          resolve(null);
          return;
        }

        // Check expiry
        if (result.expiry && new Date(result.expiry) < new Date()) {
          this.deleteCache(key);
          resolve(null);
          return;
        }

        resolve(result.data);
      };
      request.onerror = () => reject(request.error);
    });
  }

  public async deleteCache(key: string): Promise<void> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const request = store.delete(key);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  public async clearExpiredCache(): Promise<void> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const index = store.index('expiry');
      const now = new Date().toISOString();
      const range = IDBKeyRange.upperBound(now);
      const request = index.openCursor(range);

      request.onsuccess = () => {
        const cursor = request.result;
        if (cursor) {
          cursor.delete();
          cursor.continue();
        } else {
          resolve();
        }
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Offline Changes Management
  public async addOfflineChange(change: Omit<OfflineChange, 'id' | 'timestamp' | 'retry_count' | 'status'>): Promise<string> {
    if (!this.db) await this.initialize();

    const offlineChange: OfflineChange = {
      ...change,
      id: `change_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date().toISOString(),
      retry_count: 0,
      status: 'pending'
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['offline_changes'], 'readwrite');
      const store = transaction.objectStore('offline_changes');
      const request = store.add(offlineChange);

      request.onsuccess = () => resolve(offlineChange.id);
      request.onerror = () => reject(request.error);
    });
  }

  public async getOfflineChanges(status?: string): Promise<OfflineChange[]> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['offline_changes'], 'readonly');
      const store = transaction.objectStore('offline_changes');
      
      let request: IDBRequest;
      if (status) {
        const index = store.index('status');
        request = index.getAll(status);
      } else {
        request = store.getAll();
      }

      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  public async updateOfflineChange(id: string, updates: Partial<OfflineChange>): Promise<void> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['offline_changes'], 'readwrite');
      const store = transaction.objectStore('offline_changes');
      
      const getRequest = store.get(id);
      getRequest.onsuccess = () => {
        const change = getRequest.result;
        if (change) {
          const updatedChange = { ...change, ...updates };
          const putRequest = store.put(updatedChange);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          reject(new Error('Change not found'));
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  public async deleteOfflineChange(id: string): Promise<void> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['offline_changes'], 'readwrite');
      const store = transaction.objectStore('offline_changes');
      const request = store.delete(id);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  // User Data Management
  public async setUserData(key: string, data: any): Promise<void> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['user_data'], 'readwrite');
      const store = transaction.objectStore('user_data');
      const request = store.put({ key, data, timestamp: new Date().toISOString() });

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  public async getUserData(key: string): Promise<any> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['user_data'], 'readonly');
      const store = transaction.objectStore('user_data');
      const request = store.get(key);

      request.onsuccess = () => {
        const result = request.result;
        resolve(result ? result.data : null);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Storage Quota Management
  public async getStorageQuota(): Promise<StorageQuota> {
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      const estimate = await navigator.storage.estimate();
      return {
        usage: estimate.usage || 0,
        quota: estimate.quota || 0,
        available: (estimate.quota || 0) - (estimate.usage || 0)
      };
    }
    
    // Fallback for browsers without Storage API
    return { usage: 0, quota: 0, available: 0 };
  }

  // Cleanup old data
  public async cleanup(retentionDays: number = 30): Promise<void> {
    const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000).toISOString();
    
    // Clear expired cache
    await this.clearExpiredCache();
    
    // Remove old offline changes that are synced
    if (this.db) {
      return new Promise((resolve, reject) => {
        const transaction = this.db!.transaction(['offline_changes'], 'readwrite');
        const store = transaction.objectStore('offline_changes');
        const index = store.index('timestamp');
        const range = IDBKeyRange.upperBound(cutoffDate);
        const request = index.openCursor(range);

        request.onsuccess = () => {
          const cursor = request.result;
          if (cursor) {
            const change = cursor.value;
            if (change.status === 'synced') {
              cursor.delete();
            }
            cursor.continue();
          } else {
            resolve();
          }
        };
        request.onerror = () => reject(request.error);
      });
    }
  }

  // Export/Import for debugging
  public async exportData(): Promise<string> {
    const cache = await this.getAllCache();
    const changes = await this.getOfflineChanges();
    const userData = await this.getAllUserData();

    return JSON.stringify({
      cache,
      offline_changes: changes,
      user_data: userData,
      exported_at: new Date().toISOString()
    }, null, 2);
  }

  private async getAllCache(): Promise<any[]> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['cache'], 'readonly');
      const store = transaction.objectStore('cache');
      const request = store.getAll();

      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  private async getAllUserData(): Promise<any[]> {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(['user_data'], 'readonly');
      const store = transaction.objectStore('user_data');
      const request = store.getAll();

      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }
}

// Export singleton instance
export const offlineStorage = OfflineStorage.getInstance();

// Helper functions for common operations
export const cacheScheduleData = async (scheduleData: any, ttl: number = 86400) => {
  await offlineStorage.setCache('schedule_data', scheduleData, ttl);
};

export const getCachedScheduleData = async (): Promise<any> => {
  return await offlineStorage.getCache('schedule_data');
};

export const cacheUserProfile = async (profileData: any, ttl: number = 3600) => {
  await offlineStorage.setCache('user_profile', profileData, ttl);
};

export const getCachedUserProfile = async (): Promise<any> => {
  return await offlineStorage.getCache('user_profile');
};

export const addOfflineRequest = async (requestData: any): Promise<string> => {
  return await offlineStorage.addOfflineChange({
    type: 'request_creation',
    data: requestData
  });
};

export const addOfflineProfileUpdate = async (profileData: any): Promise<string> => {
  return await offlineStorage.addOfflineChange({
    type: 'profile_update',
    data: profileData
  });
};