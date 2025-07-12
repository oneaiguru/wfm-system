// WFM Integration Module - System Integration Hub
export { default as WFMIntegrationPortal } from './components/WFMIntegrationPortal';

// Admin Components
export { default as SystemConnectors } from './components/admin/SystemConnectors';

// Configuration Components
export { default as DataMappingTool } from './components/config/DataMappingTool';
export { default as APISettings } from './components/config/APISettings';

// Monitoring Components
export { default as SyncMonitor } from './components/monitoring/SyncMonitor';

// Shared Components
export { default as IntegrationLogs } from './components/shared/IntegrationLogs';

// Types
export * from './types/integration';

// Module exports for easy integration
export * from './components/WFMIntegrationPortal';
export * from './components/admin/SystemConnectors';
export * from './components/config/DataMappingTool';
export * from './components/config/APISettings';
export * from './components/monitoring/SyncMonitor';
export * from './components/shared/IntegrationLogs';