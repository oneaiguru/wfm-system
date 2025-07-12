// System Administration Types - BDD Specification
// Based on: 18-system-administration-configuration.feature

export interface DatabaseStatus {
  status: 'healthy' | 'degraded' | 'critical';
  connections: {
    active: number;
    max: number;
    idle: number;
  };
  performance: {
    queryTime: number;
    throughput: number;
    cpuUsage: number;
    memoryUsage: number;
  };
  backups: {
    lastBackup: string;
    status: 'success' | 'failed' | 'running';
    size: string;
  };
}

export interface DockerService {
  id: string;
  name: string;
  image: string;
  status: 'running' | 'stopped' | 'restarting' | 'error';
  ports: string[];
  cpu: number;
  memory: number;
  restarts: number;
  created: string;
  uptime: string;
}

export interface LoadBalancerGroup {
  id: string;
  name: string;
  algorithm: 'round_robin' | 'least_connections' | 'ip_hash';
  servers: {
    id: string;
    host: string;
    port: number;
    weight: number;
    status: 'healthy' | 'unhealthy' | 'maintenance';
    responseTime: number;
  }[];
  healthCheck: {
    enabled: boolean;
    interval: number;
    timeout: number;
    path: string;
  };
}

export interface SystemUser {
  id: string;
  username: string;
  email: string;
  role: 'admin' | 'supervisor' | 'agent' | 'readonly';
  permissions: string[];
  lastLogin: string;
  isActive: boolean;
  groups: string[];
  department: string;
}

export interface DirectoryStructure {
  path: string;
  type: 'file' | 'directory';
  size?: number;
  permissions: string;
  owner: string;
  group: string;
  modified: string;
  children?: DirectoryStructure[];
}

export interface EnvironmentVariable {
  key: string;
  value: string;
  service: string;
  category: 'database' | 'api' | 'cache' | 'logging' | 'security';
  required: boolean;
  encrypted: boolean;
  description?: string;
}

export interface SystemAlert {
  id: string;
  type: 'error' | 'warning' | 'info';
  title: string;
  message: string;
  service: string;
  timestamp: string;
  resolved: boolean;
  severity: 'low' | 'medium' | 'high' | 'critical';
}