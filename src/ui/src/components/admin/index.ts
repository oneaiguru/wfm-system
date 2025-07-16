// Admin Component Exports
export { default as SystemSettings } from './SystemSettings';
export { default as RoleManager } from './RoleManager';
export { default as AuditLog } from './AuditLog';
export { default as UserPermissions } from './UserPermissions';
export { default as ConfigEditor } from './ConfigEditor';
export { default as SystemHealth } from './SystemHealth';

// Component Information
export const ADMIN_COMPONENTS = [
  {
    id: 'system-settings',
    name: 'System Settings',
    description: 'System configuration management',
    path: '/admin/system-settings',
    component: 'SystemSettings',
    endpoints: ['GET /api/v1/employees/list']
  },
  {
    id: 'role-manager',
    name: 'Role Manager',
    description: 'User role and permission management',
    path: '/admin/role-manager',
    component: 'RoleManager',
    endpoints: ['GET /api/v1/employees/list']
  },
  {
    id: 'audit-log',
    name: 'Audit Log',
    description: 'System audit trail viewer',
    path: '/admin/audit-log',
    component: 'AuditLog',
    endpoints: ['GET /api/v1/employees/{id}']
  },
  {
    id: 'user-permissions',
    name: 'User Permissions',
    description: 'Individual user permission management',
    path: '/admin/user-permissions',
    component: 'UserPermissions',
    endpoints: ['PUT /api/v1/employees/{id}']
  },
  {
    id: 'config-editor',
    name: 'Config Editor',
    description: 'Bulk configuration management',
    path: '/admin/config-editor',
    component: 'ConfigEditor',
    endpoints: ['POST /api/v1/employees/bulk']
  },
  {
    id: 'system-health',
    name: 'System Health',
    description: 'System health monitoring',
    path: '/admin/system-health',
    component: 'SystemHealth',
    endpoints: ['GET /api/v1/monitoring/operational']
  }
] as const;

export type AdminComponentId = typeof ADMIN_COMPONENTS[number]['id'];