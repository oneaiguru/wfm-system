/**
 * REAL Access Role Service - Role and permission management API
 * NO MOCK DATA - connects to real INTEGRATION-OPUS endpoints
 * Following proven realWorkRuleService.ts pattern
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface AccessRole {
  id: string;
  name: string;
  description: string;
  isActive: boolean;
  isDefault: boolean;
  permissions: Permission[];
  createdDate: string;
  lastModified: string;
  category: 'system' | 'business' | 'custom';
}

export interface Permission {
  id: string;
  category: string;
  name: string;
  description: string;
  level: 'none' | 'view' | 'edit' | 'full';
  isRequired: boolean;
}

export interface PermissionGroup {
  id: string;
  name: string;
  description: string;
  permissions: Permission[];
  category: 'personnel' | 'planning' | 'reporting' | 'system' | 'monitoring';
}

export interface RoleValidation {
  valid: boolean;
  violations: string[];
  warnings: string[];
}

export interface UserRoleAssignment {
  userId: string;
  roleId: string;
  assignedDate: string;
  assignedBy: string;
  isActive: boolean;
  effectiveDate: string;
  expiryDate?: string;
}

const API_BASE_URL = 'http://localhost:8000/api/v1';

class RealAccessRoleService {
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          ...options.headers,
        },
        ...options,
      });

      console.log(`[REAL API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[REAL API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[REAL API] Success response:`, data);
      
      return {
        success: true,
        data: data as T
      };

    } catch (error) {
      console.error(`[REAL API] Request failed:`, error);
      
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

  // System roles management
  async getSystemRoles(): Promise<ApiResponse<AccessRole[]>> {
    console.log('[REAL API] Fetching system roles...');
    
    return this.makeRequest<AccessRole[]>('/roles/system');
  }

  async getBusinessRoles(): Promise<ApiResponse<AccessRole[]>> {
    console.log('[REAL API] Fetching business roles...');
    
    return this.makeRequest<AccessRole[]>('/roles/business');
  }

  async getAllRoles(): Promise<ApiResponse<AccessRole[]>> {
    console.log('[REAL API] Fetching all roles...');
    
    return this.makeRequest<AccessRole[]>('/roles');
  }

  async getRole(id: string): Promise<ApiResponse<AccessRole>> {
    console.log(`[REAL API] Fetching role ${id}...`);
    
    return this.makeRequest<AccessRole>(`/roles/${id}`);
  }

  // Role creation and management
  async createRole(role: Omit<AccessRole, 'id' | 'createdDate' | 'lastModified'>): Promise<ApiResponse<AccessRole>> {
    console.log('[REAL API] Creating role:', role);
    
    return this.makeRequest<AccessRole>('/roles', {
      method: 'POST',
      body: JSON.stringify(role)
    });
  }

  async updateRole(id: string, role: Partial<AccessRole>): Promise<ApiResponse<AccessRole>> {
    console.log(`[REAL API] Updating role ${id}:`, role);
    
    return this.makeRequest<AccessRole>(`/roles/${id}`, {
      method: 'PUT',
      body: JSON.stringify(role)
    });
  }

  async deleteRole(id: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Deleting role ${id}...`);
    
    return this.makeRequest<{ success: boolean }>(`/roles/${id}`, {
      method: 'DELETE'
    });
  }

  // Permission management
  async getPermissionGroups(): Promise<ApiResponse<PermissionGroup[]>> {
    console.log('[REAL API] Fetching permission groups...');
    
    return this.makeRequest<PermissionGroup[]>('/permissions/groups');
  }

  async getPermissionsByCategory(category: string): Promise<ApiResponse<Permission[]>> {
    console.log(`[REAL API] Fetching permissions for category ${category}...`);
    
    return this.makeRequest<Permission[]>(`/permissions/category/${category}`);
  }

  async getAllPermissions(): Promise<ApiResponse<Permission[]>> {
    console.log('[REAL API] Fetching all permissions...');
    
    return this.makeRequest<Permission[]>('/permissions');
  }

  // Role validation
  async validateRole(role: Partial<AccessRole>): Promise<ApiResponse<RoleValidation>> {
    console.log('[REAL API] Validating role:', role);
    
    return this.makeRequest<RoleValidation>('/roles/validate', {
      method: 'POST',
      body: JSON.stringify(role)
    });
  }

  async validateRolePermissions(roleId: string, permissions: Permission[]): Promise<ApiResponse<RoleValidation>> {
    console.log(`[REAL API] Validating permissions for role ${roleId}:`, permissions);
    
    return this.makeRequest<RoleValidation>(`/roles/${roleId}/validate-permissions`, {
      method: 'POST',
      body: JSON.stringify({ permissions })
    });
  }

  // User role assignments
  async getUserRoles(userId: string): Promise<ApiResponse<UserRoleAssignment[]>> {
    console.log(`[REAL API] Fetching roles for user ${userId}...`);
    
    return this.makeRequest<UserRoleAssignment[]>(`/users/${userId}/roles`);
  }

  async assignRoleToUser(userId: string, roleId: string, effectiveDate?: string, expiryDate?: string): Promise<ApiResponse<UserRoleAssignment>> {
    console.log(`[REAL API] Assigning role ${roleId} to user ${userId}...`);
    
    return this.makeRequest<UserRoleAssignment>(`/users/${userId}/roles/${roleId}`, {
      method: 'POST',
      body: JSON.stringify({ effectiveDate, expiryDate })
    });
  }

  async removeRoleFromUser(userId: string, roleId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Removing role ${roleId} from user ${userId}...`);
    
    return this.makeRequest<{ success: boolean }>(`/users/${userId}/roles/${roleId}`, {
      method: 'DELETE'
    });
  }

  // Permission checking
  async checkUserPermission(userId: string, permission: string): Promise<ApiResponse<{ hasPermission: boolean; level: string }>> {
    console.log(`[REAL API] Checking permission ${permission} for user ${userId}...`);
    
    return this.makeRequest<{ hasPermission: boolean; level: string }>(`/users/${userId}/permissions/${permission}`);
  }

  async getUserPermissions(userId: string): Promise<ApiResponse<Permission[]>> {
    console.log(`[REAL API] Fetching all permissions for user ${userId}...`);
    
    return this.makeRequest<Permission[]>(`/users/${userId}/permissions`);
  }

  // Bulk operations
  async assignRolesToUsers(userIds: string[], roleId: string): Promise<ApiResponse<UserRoleAssignment[]>> {
    console.log(`[REAL API] Assigning role ${roleId} to ${userIds.length} users...`);
    
    return this.makeRequest<UserRoleAssignment[]>(`/roles/${roleId}/assign-bulk`, {
      method: 'POST',
      body: JSON.stringify({ userIds })
    });
  }

  async removeRoleFromUsers(userIds: string[], roleId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Removing role ${roleId} from ${userIds.length} users...`);
    
    return this.makeRequest<{ success: boolean }>(`/roles/${roleId}/remove-bulk`, {
      method: 'POST',
      body: JSON.stringify({ userIds })
    });
  }

  // Role analytics
  async getRoleUsageStats(): Promise<ApiResponse<{ roleId: string; roleName: string; userCount: number; lastUsed: string }[]>> {
    console.log('[REAL API] Fetching role usage statistics...');
    
    return this.makeRequest<{ roleId: string; roleName: string; userCount: number; lastUsed: string }[]>('/roles/usage-stats');
  }

  async getPermissionUsageStats(): Promise<ApiResponse<{ permissionId: string; permissionName: string; roleCount: number; userCount: number }[]>> {
    console.log('[REAL API] Fetching permission usage statistics...');
    
    return this.makeRequest<{ permissionId: string; permissionName: string; roleCount: number; userCount: number }[]>('/permissions/usage-stats');
  }

  // Health check
  async checkRoleApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL API] Checking role API health...');
      
      const response = await fetch(`${API_BASE_URL}/roles/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL API] Role API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realAccessRoleService = new RealAccessRoleService();
export default realAccessRoleService;