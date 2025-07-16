// Performance Components Index
// Export all performance monitoring components

export { default as RealtimeMetrics } from './RealtimeMetrics';
export { default as SLAMonitor } from './SLAMonitor';
export { default as ExecutiveDashboard } from './ExecutiveDashboard';
export { default as AlertConfiguration } from './AlertConfiguration';
export { default as TrendAnalysis } from './TrendAnalysis';
export { default as IntegrationMonitor } from './IntegrationMonitor';

// Performance component types and interfaces
export type PerformanceComponentName = 
  | 'RealtimeMetrics'
  | 'SLAMonitor' 
  | 'ExecutiveDashboard'
  | 'AlertConfiguration'
  | 'TrendAnalysis'
  | 'IntegrationMonitor';

export interface PerformanceRoute {
  path: string;
  component: PerformanceComponentName;
  name: string;
  description: string;
  endpoint: string;
}

export const PERFORMANCE_ROUTES: PerformanceRoute[] = [
  {
    path: '/performance/realtime-metrics',
    component: 'RealtimeMetrics',
    name: 'Real-time Metrics',
    description: 'Live system performance monitoring dashboard',
    endpoint: 'GET /api/v1/monitoring/operational'
  },
  {
    path: '/performance/sla-monitor',
    component: 'SLAMonitor',
    name: 'SLA Compliance Monitor',
    description: 'Service Level Agreement monitoring and compliance tracking',
    endpoint: 'GET /api/v1/metrics/dashboard'
  },
  {
    path: '/performance/executive-dashboard',
    component: 'ExecutiveDashboard',
    name: 'Executive Dashboard',
    description: 'High-level business performance overview and KPIs',
    endpoint: 'GET /api/v1/metrics/dashboard'
  },
  {
    path: '/performance/alert-configuration',
    component: 'AlertConfiguration',
    name: 'Alert Configuration',
    description: 'Alert rule configuration and management',
    endpoint: 'GET /api/v1/alerts/list'
  },
  {
    path: '/performance/trend-analysis',
    component: 'TrendAnalysis',
    name: 'Trend Analysis',
    description: 'Advanced forecasting and trend analysis with predictive analytics',
    endpoint: 'GET /api/v1/forecasting/calculate'
  },
  {
    path: '/performance/integration-monitor',
    component: 'IntegrationMonitor',
    name: 'Integration Monitor',
    description: 'Monitor external system integrations and service health',
    endpoint: 'GET /api/v1/reports/list'
  }
];