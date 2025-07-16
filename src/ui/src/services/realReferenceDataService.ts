/**
 * REAL Reference Data Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for reference data management
 */

import { realAuthService } from './realAuthService';

export interface ReferenceDataItem {
  id: string;
  category: string;
  key: string;
  value: any;
  displayName: string;
  description?: string;
  dataType: 'string' | 'number' | 'boolean' | 'array' | 'object';
  isSystemManaged: boolean;
  isActive: boolean;
  validationRules?: {
    required?: boolean;
    minLength?: number;
    maxLength?: number;
    min?: number;
    max?: number;
    pattern?: string;
    options?: any[];
  };
  metadata?: {
    tags?: string[];
    department?: string;
    lastSyncDate?: string;
    source?: string;
  };
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface ReferenceDataCategory {
  id: string;
  name: string;
  description: string;
  iconName?: string;
  isSystemCategory: boolean;
  itemCount: number;
  lastModified: string;
}

export interface ReferenceDataValidationResult {
  valid: boolean;
  errors: Array<{
    field: string;
    message: string;
    code: string;
  }>;
  warnings: Array<{
    field: string;
    message: string;
    code: string;
  }>;
}

export interface ReferenceDataImportResult {
  success: boolean;
  imported: number;
  skipped: number;
  errors: Array<{
    row: number;
    field: string;
    message: string;
  }>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealReferenceDataService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making reference data request to: ${API_BASE_URL}${endpoint}`);
      
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`,
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        const errorText = await response.text();
        
        // Handle specific error codes
        if (response.status === 401) {
          throw new Error('Authentication failed. Please log in again.');
        } else if (response.status === 403) {
          throw new Error('Access denied. Administrator privileges required.');
        } else if (response.status === 404) {
          throw new Error('Reference data not found.');
        } else if (response.status === 409) {
          throw new Error('Reference data conflict. Item may already exist.');
        }
        
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] Reference data request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }

  /**
   * Get all reference data categories
   */
  async getReferenceDataCategories(): Promise<ApiResponse<ReferenceDataCategory[]>> {
    console.log('[REAL API] Fetching reference data categories');
    
    return this.makeRequest<ReferenceDataCategory[]>('/reference-data/categories', {
      method: 'GET'
    });
  }

  /**
   * Get reference data items by category
   */
  async getReferenceDataByCategory(category: string): Promise<ApiResponse<ReferenceDataItem[]>> {
    console.log('[REAL API] Fetching reference data for category:', category);
    
    return this.makeRequest<ReferenceDataItem[]>(`/reference-data/category/${encodeURIComponent(category)}`, {
      method: 'GET'
    });
  }

  /**
   * Get all reference data items with optional filtering
   */
  async getAllReferenceData(filters?: {
    category?: string;
    isActive?: boolean;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<ApiResponse<{ items: ReferenceDataItem[]; total: number }>> {
    console.log('[REAL API] Fetching all reference data with filters:', filters);
    
    const params = new URLSearchParams();
    if (filters?.category) params.append('category', filters.category);
    if (filters?.isActive !== undefined) params.append('isActive', filters.isActive.toString());
    if (filters?.search) params.append('search', filters.search);
    if (filters?.limit) params.append('limit', filters.limit.toString());
    if (filters?.offset) params.append('offset', filters.offset.toString());
    
    const queryString = params.toString();
    const endpoint = queryString ? `/reference-data?${queryString}` : '/reference-data';
    
    return this.makeRequest<{ items: ReferenceDataItem[]; total: number }>(endpoint, {
      method: 'GET'
    });
  }

  /**
   * Get specific reference data item by ID
   */
  async getReferenceDataItem(id: string): Promise<ApiResponse<ReferenceDataItem>> {
    console.log('[REAL API] Fetching reference data item:', id);
    
    return this.makeRequest<ReferenceDataItem>(`/reference-data/${encodeURIComponent(id)}`, {
      method: 'GET'
    });
  }

  /**
   * Create new reference data item
   */
  async createReferenceDataItem(item: Omit<ReferenceDataItem, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy'>): Promise<ApiResponse<ReferenceDataItem>> {
    console.log('[REAL API] Creating reference data item:', item);
    
    return this.makeRequest<ReferenceDataItem>('/reference-data', {
      method: 'POST',
      body: JSON.stringify(item)
    });
  }

  /**
   * Update existing reference data item
   */
  async updateReferenceDataItem(id: string, updates: Partial<ReferenceDataItem>): Promise<ApiResponse<ReferenceDataItem>> {
    console.log('[REAL API] Updating reference data item:', id, updates);
    
    return this.makeRequest<ReferenceDataItem>(`/reference-data/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  /**
   * Delete reference data item
   */
  async deleteReferenceDataItem(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL API] Deleting reference data item:', id);
    
    return this.makeRequest<{ deleted: boolean }>(`/reference-data/${encodeURIComponent(id)}`, {
      method: 'DELETE'
    });
  }

  /**
   * Bulk update reference data items
   */
  async bulkUpdateReferenceData(updates: Array<{ id: string; data: Partial<ReferenceDataItem> }>): Promise<ApiResponse<{ updated: number; errors: Array<{ id: string; error: string }> }>> {
    console.log('[REAL API] Bulk updating reference data items:', updates);
    
    return this.makeRequest<{ updated: number; errors: Array<{ id: string; error: string }> }>('/reference-data/bulk-update', {
      method: 'PUT',
      body: JSON.stringify({ updates })
    });
  }

  /**
   * Bulk delete reference data items
   */
  async bulkDeleteReferenceData(ids: string[]): Promise<ApiResponse<{ deleted: number; errors: Array<{ id: string; error: string }> }>> {
    console.log('[REAL API] Bulk deleting reference data items:', ids);
    
    return this.makeRequest<{ deleted: number; errors: Array<{ id: string; error: string }> }>('/reference-data/bulk-delete', {
      method: 'DELETE',
      body: JSON.stringify({ ids })
    });
  }

  /**
   * Validate reference data item before saving
   */
  async validateReferenceDataItem(item: Partial<ReferenceDataItem>): Promise<ApiResponse<ReferenceDataValidationResult>> {
    console.log('[REAL API] Validating reference data item:', item);
    
    return this.makeRequest<ReferenceDataValidationResult>('/reference-data/validate', {
      method: 'POST',
      body: JSON.stringify(item)
    });
  }

  /**
   * Create new reference data category
   */
  async createReferenceDataCategory(category: Omit<ReferenceDataCategory, 'id' | 'itemCount' | 'lastModified'>): Promise<ApiResponse<ReferenceDataCategory>> {
    console.log('[REAL API] Creating reference data category:', category);
    
    return this.makeRequest<ReferenceDataCategory>('/reference-data/categories', {
      method: 'POST',
      body: JSON.stringify(category)
    });
  }

  /**
   * Update reference data category
   */
  async updateReferenceDataCategory(id: string, updates: Partial<ReferenceDataCategory>): Promise<ApiResponse<ReferenceDataCategory>> {
    console.log('[REAL API] Updating reference data category:', id, updates);
    
    return this.makeRequest<ReferenceDataCategory>(`/reference-data/categories/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  /**
   * Delete reference data category
   */
  async deleteReferenceDataCategory(id: string, moveItemsToCategory?: string): Promise<ApiResponse<{ deleted: boolean; movedItems?: number }>> {
    console.log('[REAL API] Deleting reference data category:', id);
    
    const body = moveItemsToCategory ? { moveItemsToCategory } : {};
    
    return this.makeRequest<{ deleted: boolean; movedItems?: number }>(`/reference-data/categories/${encodeURIComponent(id)}`, {
      method: 'DELETE',
      body: JSON.stringify(body)
    });
  }

  /**
   * Import reference data from CSV/Excel
   */
  async importReferenceData(file: File, category: string, options?: {
    skipDuplicates?: boolean;
    updateExisting?: boolean;
  }): Promise<ApiResponse<ReferenceDataImportResult>> {
    console.log('[REAL API] Importing reference data from file:', file.name, 'to category:', category);
    
    const formData = new FormData();
    formData.append('file', file);
    formData.append('category', category);
    if (options?.skipDuplicates) {
      formData.append('skipDuplicates', 'true');
    }
    if (options?.updateExisting) {
      formData.append('updateExisting', 'true');
    }

    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/reference-data/import`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          // Don't set Content-Type for FormData, let browser set it
        },
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as ReferenceDataImportResult };

    } catch (error) {
      console.error('[REAL API] Import failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Import failed'
      };
    }
  }

  /**
   * Export reference data to CSV/Excel
   */
  async exportReferenceData(category?: string, format: 'csv' | 'excel' = 'csv'): Promise<ApiResponse<Blob>> {
    console.log('[REAL API] Exporting reference data:', category, format);
    
    const params = new URLSearchParams();
    if (category) params.append('category', category);
    params.append('format', format);
    
    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/reference-data/export?${params.toString()}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${authToken}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const blob = await response.blob();
      return { success: true, data: blob };

    } catch (error) {
      console.error('[REAL API] Export failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Export failed'
      };
    }
  }

  /**
   * Sync reference data with external systems
   */
  async syncReferenceDataWithExternalSystems(category?: string): Promise<ApiResponse<{ synced: number; errors: string[] }>> {
    console.log('[REAL API] Syncing reference data with external systems:', category);
    
    const body = category ? { category } : {};
    
    return this.makeRequest<{ synced: number; errors: string[] }>('/reference-data/sync', {
      method: 'POST',
      body: JSON.stringify(body)
    });
  }

  /**
   * Get reference data usage analytics
   */
  async getReferenceDataAnalytics(category?: string): Promise<ApiResponse<{
    totalItems: number;
    activeItems: number;
    inactiveItems: number;
    recentlyModified: number;
    usage: Array<{
      key: string;
      usageCount: number;
      lastUsed: string;
    }>;
  }>> {
    console.log('[REAL API] Fetching reference data analytics:', category);
    
    const endpoint = category 
      ? `/reference-data/analytics?category=${encodeURIComponent(category)}`
      : '/reference-data/analytics';
    
    return this.makeRequest<{
      totalItems: number;
      activeItems: number;
      inactiveItems: number;
      recentlyModified: number;
      usage: Array<{
        key: string;
        usageCount: number;
        lastUsed: string;
      }>;
    }>(endpoint, {
      method: 'GET'
    });
  }

  /**
   * Search reference data with advanced filters
   */
  async searchReferenceData(query: {
    text?: string;
    category?: string;
    dataType?: string;
    isActive?: boolean;
    tags?: string[];
    dateRange?: {
      from: string;
      to: string;
    };
  }): Promise<ApiResponse<ReferenceDataItem[]>> {
    console.log('[REAL API] Searching reference data:', query);
    
    return this.makeRequest<ReferenceDataItem[]>('/reference-data/search', {
      method: 'POST',
      body: JSON.stringify(query)
    });
  }

  /**
   * Get work rules (no auth required)
   */
  async getWorkRules(): Promise<ApiResponse<any>> {
    console.log('[REAL API] Fetching work rules');
    
    try {
      const response = await fetch(`${API_BASE_URL}/work-rules`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error) {
      console.error('[REAL API] Failed to fetch work rules:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch work rules'
      };
    }
  }

  /**
   * Get vacation schemes (no auth required)
   */
  async getVacationSchemes(): Promise<ApiResponse<any>> {
    console.log('[REAL API] Fetching vacation schemes');
    
    try {
      const response = await fetch(`${API_BASE_URL}/vacation-schemes`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error) {
      console.error('[REAL API] Failed to fetch vacation schemes:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch vacation schemes'
      };
    }
  }
}

export const realReferenceDataService = new RealReferenceDataService();
export default realReferenceDataService;