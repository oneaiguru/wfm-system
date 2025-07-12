/**
 * WFM API Integration Hooks
 * React hooks for seamless API integration with caching, error handling, and real-time updates
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import apiIntegrationService from '@/services/apiIntegrationService';
import dataTransformationService from '@/services/dataTransformationService';
import type { 
  DashboardData, 
  ScheduleData, 
  ForecastData, 
  PersonnelData 
} from '@/services/apiIntegrationService';

// ===== BASE HOOK TYPES =====

interface UseApiOptions {
  enabled?: boolean;
  refetchInterval?: number;
  staleTime?: number;
  retry?: boolean;
  retryCount?: number;
  retryDelay?: number;
}

interface UseApiState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  isStale: boolean;
  lastFetch: Date | null;
}

interface UseApiActions<T> {
  refetch: () => Promise<void>;
  refresh: () => Promise<void>;
  setData: (data: T | null) => void;
  clearError: () => void;
}

type UseApiResult<T> = UseApiState<T> & UseApiActions<T>;

// ===== REAL-TIME SUBSCRIPTION TYPES =====

interface UseRealTimeOptions {
  eventTypes: string[];
  enabled?: boolean;
  onData?: (eventType: string, data: any) => void;
  onError?: (error: Error) => void;
  onConnect?: () => void;
  onDisconnect?: () => void;
}

interface UseRealTimeState {
  connected: boolean;
  subscriptions: string[];
  lastEvent: { type: string; data: any; timestamp: Date } | null;
  connectionAttempts: number;
}

// ===== BASE API HOOK =====

function useApi<T>(
  fetchFn: () => Promise<T>,
  options: UseApiOptions = {}
): UseApiResult<T> {
  const {
    enabled = true,
    refetchInterval = 0,
    staleTime = 5 * 60 * 1000, // 5 minutes
    retry = true,
    retryCount = 3,
    retryDelay = 1000
  } = options;

  const [state, setState] = useState<UseApiState<T>>({
    data: null,
    loading: false,
    error: null,
    isStale: false,
    lastFetch: null
  });

  const retryCountRef = useRef(0);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const fetchData = useCallback(async (isRefresh = false) => {
    if (!enabled) return;

    setState(prev => ({ ...prev, loading: true, error: isRefresh ? null : prev.error }));

    try {
      const data = await fetchFn();
      setState(prev => ({
        ...prev,
        data,
        loading: false,
        error: null,
        isStale: false,
        lastFetch: new Date()
      }));
      retryCountRef.current = 0;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      
      if (retry && retryCountRef.current < retryCount) {
        retryCountRef.current++;
        timeoutRef.current = setTimeout(() => fetchData(isRefresh), retryDelay);
      } else {
        setState(prev => ({ ...prev, loading: false, error: errorObj }));
      }
    }
  }, [enabled, fetchFn, retry, retryCount, retryDelay]);

  const refetch = useCallback(() => fetchData(false), [fetchData]);
  const refresh = useCallback(() => fetchData(true), [fetchData]);

  const setData = useCallback((data: T | null) => {
    setState(prev => ({ ...prev, data }));
  }, []);

  const clearError = useCallback(() => {
    setState(prev => ({ ...prev, error: null }));
  }, []);

  // Check if data is stale
  useEffect(() => {
    if (state.lastFetch && staleTime > 0) {
      const checkStale = () => {
        const now = new Date().getTime();
        const lastFetchTime = state.lastFetch!.getTime();
        const isStale = now - lastFetchTime > staleTime;
        
        setState(prev => ({ ...prev, isStale }));
      };

      checkStale();
      const interval = setInterval(checkStale, 30000); // Check every 30 seconds
      return () => clearInterval(interval);
    }
  }, [state.lastFetch, staleTime]);

  // Auto-refetch interval
  useEffect(() => {
    if (enabled && refetchInterval > 0) {
      intervalRef.current = setInterval(() => {
        if (!state.loading) {
          fetchData(false);
        }
      }, refetchInterval);

      return () => {
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
        }
      };
    }
  }, [enabled, refetchInterval, fetchData, state.loading]);

  // Initial fetch
  useEffect(() => {
    if (enabled) {
      fetchData(false);
    }

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [enabled, fetchData]);

  return {
    ...state,
    refetch,
    refresh,
    setData,
    clearError
  };
}

// ===== DASHBOARD HOOK =====

export function useDashboard(options: UseApiOptions = {}) {
  const result = useApi<DashboardData>(
    () => apiIntegrationService.getDashboardData(),
    {
      refetchInterval: 30000, // 30 seconds
      staleTime: 60000, // 1 minute
      ...options
    }
  );

  return result;
}

// ===== SCHEDULE HOOK =====

export function useSchedule(scheduleId?: string, options: UseApiOptions = {}) {
  const result = useApi<ScheduleData>(
    () => apiIntegrationService.getScheduleData(scheduleId),
    {
      refetchInterval: 60000, // 1 minute
      staleTime: 300000, // 5 minutes
      ...options
    }
  );

  const updateSchedule = useCallback(async (updates: Partial<ScheduleData>) => {
    if (!scheduleId) throw new Error('Schedule ID is required for updates');
    
    await apiIntegrationService.updateSchedule(scheduleId, updates);
    await result.refetch();
  }, [scheduleId, result]);

  const optimizeSchedule = useCallback(async (parameters: Record<string, any>) => {
    if (!scheduleId) throw new Error('Schedule ID is required for optimization');
    
    const optimization = await apiIntegrationService.optimizeSchedule(scheduleId, parameters);
    await result.refetch();
    return optimization;
  }, [scheduleId, result]);

  const publishSchedule = useCallback(async () => {
    if (!scheduleId) throw new Error('Schedule ID is required for publishing');
    
    await apiIntegrationService.publishSchedule(scheduleId);
    await result.refetch();
  }, [scheduleId, result]);

  return {
    ...result,
    updateSchedule,
    optimizeSchedule,
    publishSchedule
  };
}

// ===== FORECAST HOOK =====

export function useForecast(forecastId?: string, options: UseApiOptions = {}) {
  const result = useApi<ForecastData>(
    () => apiIntegrationService.getForecastData(forecastId),
    {
      refetchInterval: 300000, // 5 minutes
      staleTime: 600000, // 10 minutes
      ...options
    }
  );

  const generateForecast = useCallback(async (parameters: Record<string, any>) => {
    const forecast = await apiIntegrationService.generateForecast(parameters);
    result.setData(forecast);
    return forecast;
  }, [result]);

  const adjustForecast = useCallback(async (adjustments: any[]) => {
    if (!forecastId) throw new Error('Forecast ID is required for adjustments');
    
    await apiIntegrationService.adjustForecast(forecastId, adjustments);
    await result.refetch();
  }, [forecastId, result]);

  return {
    ...result,
    generateForecast,
    adjustForecast
  };
}

// ===== PERSONNEL HOOK =====

export function usePersonnel(options: UseApiOptions = {}) {
  const result = useApi<PersonnelData>(
    () => apiIntegrationService.getPersonnelData(),
    {
      refetchInterval: 0, // No auto-refresh for personnel data
      staleTime: 1800000, // 30 minutes
      ...options
    }
  );

  const updateEmployee = useCallback(async (employeeId: string, updates: any) => {
    await apiIntegrationService.updateEmployee(employeeId, updates);
    await result.refetch();
  }, [result]);

  const assignSkill = useCallback(async (employeeId: string, skillId: string, level: number) => {
    await apiIntegrationService.assignSkill(employeeId, skillId, level);
    await result.refetch();
  }, [result]);

  const createGroup = useCallback(async (group: any) => {
    const newGroup = await apiIntegrationService.createGroup(group);
    await result.refetch();
    return newGroup;
  }, [result]);

  return {
    ...result,
    updateEmployee,
    assignSkill,
    createGroup
  };
}

// ===== REAL-TIME HOOK =====

export function useRealTime(options: UseRealTimeOptions) {
  const { eventTypes, enabled = true, onData, onError, onConnect, onDisconnect } = options;
  
  const [state, setState] = useState<UseRealTimeState>({
    connected: false,
    subscriptions: [],
    lastEvent: null,
    connectionAttempts: 0
  });

  const subscriptionsRef = useRef<Array<() => void>>([]);

  // Subscribe to events
  useEffect(() => {
    if (!enabled) return;

    // Clear existing subscriptions
    subscriptionsRef.current.forEach(unsubscribe => unsubscribe());
    subscriptionsRef.current = [];

    // Create new subscriptions
    eventTypes.forEach(eventType => {
      const unsubscribe = apiIntegrationService.subscribe(eventType, (data) => {
        const event = {
          type: eventType,
          data,
          timestamp: new Date()
        };
        
        setState(prev => ({ ...prev, lastEvent: event }));
        onData?.(eventType, data);
      });
      
      subscriptionsRef.current.push(unsubscribe);
    });

    setState(prev => ({ ...prev, subscriptions: eventTypes }));

    return () => {
      subscriptionsRef.current.forEach(unsubscribe => unsubscribe());
      subscriptionsRef.current = [];
    };
  }, [eventTypes, enabled, onData]);

  // Monitor connection status
  useEffect(() => {
    if (!enabled) return;

    const checkConnection = () => {
      const connected = apiIntegrationService.isWebSocketConnected();
      
      setState(prev => {
        if (prev.connected !== connected) {
          if (connected) {
            onConnect?.();
          } else {
            onDisconnect?.();
          }
        }
        return { ...prev, connected };
      });
    };

    checkConnection();
    const interval = setInterval(checkConnection, 5000);

    return () => clearInterval(interval);
  }, [enabled, onConnect, onDisconnect]);

  const reconnect = useCallback(() => {
    setState(prev => ({ ...prev, connectionAttempts: prev.connectionAttempts + 1 }));
    // Trigger reconnection logic
  }, []);

  return {
    ...state,
    reconnect
  };
}

// ===== ALGORITHM HOOK =====

export function useAlgorithms(options: UseApiOptions = {}) {
  const [calculationLoading, setCalculationLoading] = useState(false);
  const [optimizationLoading, setOptimizationLoading] = useState(false);

  const statusResult = useApi(
    () => apiIntegrationService.getAlgorithmStatus(),
    {
      refetchInterval: 60000, // 1 minute
      ...options
    }
  );

  const calculateErlangC = useCallback(async (parameters: Record<string, any>) => {
    setCalculationLoading(true);
    try {
      const result = await apiIntegrationService.calculateErlangC(parameters);
      return result;
    } finally {
      setCalculationLoading(false);
    }
  }, []);

  const runMultiSkillOptimization = useCallback(async (parameters: Record<string, any>) => {
    setOptimizationLoading(true);
    try {
      const result = await apiIntegrationService.runMultiSkillOptimization(parameters);
      return result;
    } finally {
      setOptimizationLoading(false);
    }
  }, []);

  return {
    ...statusResult,
    calculateErlangC,
    runMultiSkillOptimization,
    calculationLoading,
    optimizationLoading
  };
}

// ===== REPORTING HOOK =====

export function useReporting() {
  const [reportGenerationLoading, setReportGenerationLoading] = useState<Record<string, boolean>>({});
  const [reportStatuses, setReportStatuses] = useState<Record<string, any>>({});

  const generateReport = useCallback(async (reportType: string, parameters: Record<string, any>) => {
    setReportGenerationLoading(prev => ({ ...prev, [reportType]: true }));
    
    try {
      const result = await apiIntegrationService.generateReport(reportType, parameters);
      setReportStatuses(prev => ({ ...prev, [result.reportId]: result }));
      return result;
    } finally {
      setReportGenerationLoading(prev => ({ ...prev, [reportType]: false }));
    }
  }, []);

  const checkReportStatus = useCallback(async (reportId: string) => {
    const status = await apiIntegrationService.getReportStatus(reportId);
    setReportStatuses(prev => ({ ...prev, [reportId]: status }));
    return status;
  }, []);

  const downloadReport = useCallback(async (reportId: string) => {
    const blob = await apiIntegrationService.downloadReport(reportId);
    
    // Create download link
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `report_${reportId}.pdf`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }, []);

  return {
    generateReport,
    checkReportStatus,
    downloadReport,
    reportGenerationLoading,
    reportStatuses
  };
}

// ===== CHART DATA HOOK =====

export function useChartData<T>(
  data: T[] | null,
  options: {
    xAxis: string;
    yAxis: string | string[];
    chartType: 'line' | 'bar' | 'area';
    colors?: string[];
    timeFormat?: string;
  }
) {
  const [chartData, setChartData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!data || data.length === 0) {
      setChartData(null);
      return;
    }

    setLoading(true);
    try {
      const transformedData = dataTransformationService.transformToChartData(data, options);
      setChartData(transformedData);
    } catch (error) {
      console.error('Chart data transformation failed:', error);
      setChartData(null);
    } finally {
      setLoading(false);
    }
  }, [data, options]);

  return { chartData, loading };
}

// ===== TABLE DATA HOOK =====

export function useTableData<T>(
  data: T[] | null,
  options: {
    columns: Array<{
      key: string;
      label: string;
      type: 'text' | 'number' | 'date' | 'boolean' | 'status';
      formatter?: (value: any) => string;
    }>;
    pagination?: { page: number; limit: number };
    sorting?: { column: string; direction: 'asc' | 'desc' };
    filters?: Record<string, any>;
  }
) {
  const [tableData, setTableData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!data || data.length === 0) {
      setTableData(null);
      return;
    }

    setLoading(true);
    try {
      const transformedData = dataTransformationService.transformToTableData(data, options);
      setTableData(transformedData);
    } catch (error) {
      console.error('Table data transformation failed:', error);
      setTableData(null);
    } finally {
      setLoading(false);
    }
  }, [data, options]);

  return { tableData, loading };
}

// ===== INTEGRATION STATUS HOOK =====

export function useIntegrationStatus(options: UseApiOptions = {}) {
  const result = useApi(
    () => apiIntegrationService.getIntegrationStatus(),
    {
      refetchInterval: 60000, // 1 minute
      ...options
    }
  );

  const testIntegration = useCallback(async (integrationType: string) => {
    return await apiIntegrationService.testIntegration(integrationType);
  }, []);

  const syncExternalData = useCallback(async (integrationType: string, parameters: Record<string, any>) => {
    return await apiIntegrationService.syncExternalData(integrationType, parameters);
  }, []);

  return {
    ...result,
    testIntegration,
    syncExternalData
  };
}

// ===== HEALTH CHECK HOOK =====

export function useHealthCheck(options: UseApiOptions = {}) {
  return useApi(
    () => apiIntegrationService.healthCheck(),
    {
      refetchInterval: 30000, // 30 seconds
      staleTime: 60000, // 1 minute
      ...options
    }
  );
}

// ===== CACHE MANAGEMENT HOOK =====

export function useCacheManager() {
  const [cacheStats, setCacheStats] = useState<any>(null);

  const getCacheStats = useCallback(() => {
    const stats = apiIntegrationService.getCacheStats();
    setCacheStats(stats);
    return stats;
  }, []);

  const clearCache = useCallback(() => {
    apiIntegrationService.clearCache();
    setCacheStats(null);
  }, []);

  useEffect(() => {
    getCacheStats();
  }, [getCacheStats]);

  return {
    cacheStats,
    getCacheStats,
    clearCache
  };
}