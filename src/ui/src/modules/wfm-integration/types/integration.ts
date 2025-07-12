// WFM Integration Module Types

export interface SystemConnection {
  id: string;
  name: string;
  type: 'database' | 'api' | 'file' | 'queue';
  status: 'active' | 'inactive' | 'error' | 'testing';
  url: string;
  lastSync: Date;
  syncCount: number;
  errorCount: number;
  description: string;
}

export interface DataMapping {
  id: string;
  sourceSystem: string;
  targetSystem: string;
  sourceField: string;
  targetField: string;
  transformation?: string;
  status: 'active' | 'inactive' | 'error';
  lastMapped: Date;
  recordCount: number;
}

export interface IntegrationLog {
  id: string;
  timestamp: Date;
  level: 'info' | 'warning' | 'error' | 'success';
  system: string;
  operation: string;
  message: string;
  details?: string;
  duration?: number;
}

export interface SyncStatus {
  systemId: string;
  systemName: string;
  lastSync: Date;
  nextSync: Date;
  status: 'syncing' | 'completed' | 'failed' | 'pending';
  progress: number;
  recordsProcessed: number;
  recordsTotal: number;
  errors: string[];
}

export interface APIEndpoint {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;
  status: 'active' | 'inactive' | 'testing';
  lastTest: Date;
  responseTime: number;
  successRate: number;
  headers: Record<string, string>;
  authentication?: {
    type: 'bearer' | 'basic' | 'api-key';
    token?: string;
  };
}

export interface IntegrationSettings {
  id: string;
  category: 'sync' | 'mapping' | 'security' | 'performance';
  name: string;
  value: string | number | boolean;
  description: string;
  isRequired: boolean;
  lastModified: Date;
  modifiedBy: string;
}

export interface ConnectorHealth {
  systemId: string;
  systemName: string;
  status: 'healthy' | 'warning' | 'critical' | 'unknown';
  uptime: number;
  avgResponseTime: number;
  errorRate: number;
  lastHealthCheck: Date;
  metrics: {
    cpu: number;
    memory: number;
    diskSpace: number;
    networkLatency: number;
  };
}