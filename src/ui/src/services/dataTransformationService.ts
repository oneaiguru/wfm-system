/**
 * WFM Enterprise Data Transformation Service
 * Handles data mapping, transformation, and normalization between different formats
 * Supports Argus compatibility, API responses, and UI component requirements
 */

import { format, parseISO, isValid, startOfDay, endOfDay, startOfWeek, endOfWeek } from 'date-fns';

// ===== TYPE DEFINITIONS =====

export interface TransformationOptions {
  dateFormat?: string;
  timezone?: string;
  precision?: number;
  nullHandling?: 'skip' | 'default' | 'error';
  validation?: boolean;
  locale?: string;
}

export interface DataValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  correctedData?: any;
}

export interface ArgusDataFormat {
  // Legacy Argus format mappings
  agent_data: {
    id: string;
    name: string;
    login_id: string;
    skills: string[];
    status: string;
    location: string;
  };
  queue_data: {
    queue_id: string;
    name: string;
    type: string;
    priority: number;
    sla_threshold: number;
    current_load: number;
  };
  schedule_data: {
    schedule_id: string;
    agent_id: string;
    date: string;
    shift_start: string;
    shift_end: string;
    break_schedule: string[];
    assigned_queues: string[];
  };
  forecast_data: {
    interval: string;
    call_volume: number;
    avg_handle_time: number;
    service_level: number;
    abandonment_rate: number;
  };
}

export interface WFMDataFormat {
  // Modern WFM format
  agents: {
    id: string;
    name: string;
    email: string;
    skills: Array<{ skillId: string; level: number; certified: boolean }>;
    status: 'available' | 'busy' | 'break' | 'offline';
    location: string;
    department: string;
    schedule: string;
  };
  queues: {
    id: string;
    name: string;
    description: string;
    type: 'inbound' | 'outbound' | 'chat' | 'email';
    priority: 'low' | 'medium' | 'high' | 'critical';
    sla: {
      target: number;
      threshold: number;
      unit: 'seconds' | 'minutes';
    };
    metrics: {
      callsInQueue: number;
      avgWaitTime: number;
      serviceLevel: number;
      abandonment: number;
      timestamp: string;
    };
  };
  schedules: {
    id: string;
    agentId: string;
    date: string;
    shifts: Array<{
      startTime: string;
      endTime: string;
      type: 'regular' | 'overtime' | 'break';
      skills: string[];
      location?: string;
    }>;
    breaks: Array<{
      startTime: string;
      endTime: string;
      type: 'lunch' | 'break' | 'meeting';
      duration: number;
    }>;
    assignedQueues: string[];
    totalHours: number;
    overtime: number;
  };
  forecasts: {
    id: string;
    timeRange: { start: string; end: string };
    intervals: Array<{
      timestamp: string;
      callVolume: number;
      aht: number;
      serviceLevel: number;
      abandonment: number;
      requiredAgents: number;
      confidence: { lower: number; upper: number };
    }>;
    accuracy: {
      mape: number;
      rmse: number;
      mae: number;
      r2: number;
    };
    metadata: {
      algorithm: string;
      parameters: Record<string, any>;
      generatedAt: string;
      version: string;
    };
  };
}

export interface ChartDataFormat {
  labels: string[];
  datasets: Array<{
    label: string;
    data: number[];
    borderColor?: string;
    backgroundColor?: string;
    fill?: boolean;
    tension?: number;
    pointRadius?: number;
    pointHoverRadius?: number;
  }>;
}

export interface TableDataFormat {
  columns: Array<{
    key: string;
    label: string;
    type: 'text' | 'number' | 'date' | 'boolean' | 'status';
    sortable?: boolean;
    filterable?: boolean;
    width?: number;
    formatter?: (value: any) => string;
  }>;
  rows: Array<Record<string, any>>;
  pagination?: {
    page: number;
    limit: number;
    total: number;
  };
  sorting?: {
    column: string;
    direction: 'asc' | 'desc';
  };
  filters?: Record<string, any>;
}

// ===== DATA TRANSFORMATION SERVICE =====

class DataTransformationService {
  private defaultOptions: TransformationOptions = {
    dateFormat: 'yyyy-MM-dd HH:mm:ss',
    timezone: 'UTC',
    precision: 2,
    nullHandling: 'default',
    validation: true,
    locale: 'en-US'
  };

  // ===== ARGUS COMPATIBILITY =====

  /**
   * Transform Argus format data to WFM format
   */
  transformArgusToWFM(argusData: any, dataType: keyof ArgusDataFormat): any {
    switch (dataType) {
      case 'agent_data':
        return this.transformArgusAgentData(argusData);
      case 'queue_data':
        return this.transformArgusQueueData(argusData);
      case 'schedule_data':
        return this.transformArgusScheduleData(argusData);
      case 'forecast_data':
        return this.transformArgusForecastData(argusData);
      default:
        throw new Error(`Unknown Argus data type: ${dataType}`);
    }
  }

  private transformArgusAgentData(argusData: ArgusDataFormat['agent_data']): WFMDataFormat['agents'] {
    return {
      id: argusData.id,
      name: argusData.name,
      email: `${argusData.login_id}@company.com`, // Default email pattern
      skills: argusData.skills.map(skill => ({
        skillId: skill,
        level: 3, // Default level
        certified: true
      })),
      status: this.mapArgusStatus(argusData.status),
      location: argusData.location,
      department: 'Contact Center', // Default department
      schedule: 'standard' // Default schedule
    };
  }

  private transformArgusQueueData(argusData: ArgusDataFormat['queue_data']): WFMDataFormat['queues'] {
    return {
      id: argusData.queue_id,
      name: argusData.name,
      description: `Queue ${argusData.name}`,
      type: this.mapArgusQueueType(argusData.type),
      priority: this.mapArgusPriority(argusData.priority),
      sla: {
        target: argusData.sla_threshold,
        threshold: argusData.sla_threshold * 0.8, // 80% of target
        unit: 'seconds'
      },
      metrics: {
        callsInQueue: argusData.current_load,
        avgWaitTime: 0, // Not available in Argus format
        serviceLevel: 0, // Not available in Argus format
        abandonment: 0, // Not available in Argus format
        timestamp: new Date().toISOString()
      }
    };
  }

  private transformArgusScheduleData(argusData: ArgusDataFormat['schedule_data']): WFMDataFormat['schedules'] {
    const shifts = [{
      startTime: argusData.shift_start,
      endTime: argusData.shift_end,
      type: 'regular' as const,
      skills: [], // Not available in Argus format
      location: undefined
    }];

    const breaks = argusData.break_schedule.map(breakTime => ({
      startTime: breakTime,
      endTime: this.calculateBreakEnd(breakTime), // Default 15-minute break
      type: 'break' as const,
      duration: 15
    }));

    return {
      id: argusData.schedule_id,
      agentId: argusData.agent_id,
      date: argusData.date,
      shifts,
      breaks,
      assignedQueues: argusData.assigned_queues,
      totalHours: this.calculateTotalHours(shifts),
      overtime: 0 // Calculate separately
    };
  }

  private transformArgusForecastData(argusData: ArgusDataFormat['forecast_data']): WFMDataFormat['forecasts']['intervals'][0] {
    return {
      timestamp: argusData.interval,
      callVolume: argusData.call_volume,
      aht: argusData.avg_handle_time,
      serviceLevel: argusData.service_level,
      abandonment: argusData.abandonment_rate,
      requiredAgents: Math.ceil(argusData.call_volume * argusData.avg_handle_time / 3600), // Basic calculation
      confidence: {
        lower: argusData.call_volume * 0.9,
        upper: argusData.call_volume * 1.1
      }
    };
  }

  // ===== WFM TO CHART DATA =====

  /**
   * Transform WFM data to chart format
   */
  transformToChartData(data: any[], options: {
    xAxis: string;
    yAxis: string | string[];
    chartType: 'line' | 'bar' | 'area';
    colors?: string[];
    timeFormat?: string;
  }): ChartDataFormat {
    const labels = data.map(item => {
      let label = item[options.xAxis];
      if (options.timeFormat && this.isValidDate(label)) {
        label = format(parseISO(label), options.timeFormat);
      }
      return label;
    });

    const yAxisKeys = Array.isArray(options.yAxis) ? options.yAxis : [options.yAxis];
    const colors = options.colors || this.generateColors(yAxisKeys.length);

    const datasets = yAxisKeys.map((key, index) => ({
      label: this.formatLabel(key),
      data: data.map(item => item[key] || 0),
      borderColor: colors[index],
      backgroundColor: options.chartType === 'area' ? this.hexToRgba(colors[index], 0.2) : colors[index],
      fill: options.chartType === 'area',
      tension: options.chartType === 'line' ? 0.4 : 0,
      pointRadius: options.chartType === 'line' ? 3 : 0,
      pointHoverRadius: options.chartType === 'line' ? 5 : 0
    }));

    return { labels, datasets };
  }

  // ===== WFM TO TABLE DATA =====

  /**
   * Transform WFM data to table format
   */
  transformToTableData(data: any[], options: {
    columns: Array<{
      key: string;
      label: string;
      type: 'text' | 'number' | 'date' | 'boolean' | 'status';
      formatter?: (value: any) => string;
    }>;
    pagination?: { page: number; limit: number };
    sorting?: { column: string; direction: 'asc' | 'desc' };
    filters?: Record<string, any>;
  }): TableDataFormat {
    let processedData = [...data];

    // Apply filters
    if (options.filters) {
      processedData = this.applyFilters(processedData, options.filters);
    }

    // Apply sorting
    if (options.sorting) {
      processedData = this.applySorting(processedData, options.sorting);
    }

    // Calculate pagination
    const total = processedData.length;
    let paginatedData = processedData;
    if (options.pagination) {
      const start = (options.pagination.page - 1) * options.pagination.limit;
      const end = start + options.pagination.limit;
      paginatedData = processedData.slice(start, end);
    }

    // Format data
    const rows = paginatedData.map(item => {
      const row: Record<string, any> = {};
      options.columns.forEach(column => {
        let value = item[column.key];
        
        // Apply formatter if provided
        if (column.formatter) {
          value = column.formatter(value);
        } else {
          // Apply default formatting based on type
          value = this.formatValue(value, column.type);
        }
        
        row[column.key] = value;
      });
      return row;
    });

    return {
      columns: options.columns.map(col => ({
        ...col,
        sortable: col.sortable ?? true,
        filterable: col.filterable ?? true
      })),
      rows,
      pagination: options.pagination ? {
        ...options.pagination,
        total
      } : undefined,
      sorting: options.sorting,
      filters: options.filters
    };
  }

  // ===== REAL-TIME DATA TRANSFORMATION =====

  /**
   * Transform real-time WebSocket data
   */
  transformRealTimeData(data: any, eventType: string): any {
    switch (eventType) {
      case 'agent_status':
        return this.transformAgentStatusUpdate(data);
      case 'queue_metrics':
        return this.transformQueueMetricsUpdate(data);
      case 'forecast_update':
        return this.transformForecastUpdate(data);
      case 'schedule_change':
        return this.transformScheduleChange(data);
      default:
        return data;
    }
  }

  private transformAgentStatusUpdate(data: any) {
    return {
      agentId: data.agent_id,
      status: data.status,
      previousStatus: data.previous_status,
      timestamp: this.formatTimestamp(data.timestamp),
      location: data.location,
      skills: data.skills || [],
      metadata: {
        statusDuration: this.calculateStatusDuration(data.timestamp, data.previous_timestamp),
        autoGenerated: data.auto_generated || false
      }
    };
  }

  private transformQueueMetricsUpdate(data: any) {
    return {
      queueId: data.queue_id,
      groupId: data.group_id,
      timestamp: this.formatTimestamp(data.timestamp),
      metrics: {
        callsInQueue: data.metrics.calls_in_queue || 0,
        avgWaitTime: data.metrics.avg_wait_time || 0,
        serviceLevel: data.metrics.service_level || 0,
        abandonment: data.metrics.abandonment || 0,
        throughput: data.metrics.throughput || 0
      },
      thresholds: data.thresholds || {},
      alerts: this.generateMetricAlerts(data.metrics, data.thresholds)
    };
  }

  private transformForecastUpdate(data: any) {
    return {
      forecastId: data.forecast_id,
      intervalStart: this.formatTimestamp(data.interval_start),
      metrics: {
        callVolume: data.call_volume || 0,
        aht: data.aht || 0,
        staffingRequirement: data.staffing_requirement || 0,
        accuracy: data.accuracy_metrics || {}
      },
      confidence: {
        level: data.confidence_level || 0.95,
        interval: data.confidence_interval || { lower: 0, upper: 0 }
      },
      error: data.error_message || null
    };
  }

  private transformScheduleChange(data: any) {
    return {
      scheduleId: data.schedule_id,
      agentId: data.agent_id,
      changeType: data.change_type,
      timestamp: this.formatTimestamp(data.timestamp),
      changes: {
        previous: data.previous_schedule || null,
        current: data.current_schedule || null,
        details: data.shift_details || {}
      },
      optimization: data.optimization_metrics || null,
      impact: this.calculateScheduleImpact(data)
    };
  }

  // ===== DATA VALIDATION =====

  /**
   * Validate and clean data
   */
  validateData(data: any, schema: any): DataValidationResult {
    const result: DataValidationResult = {
      valid: true,
      errors: [],
      warnings: []
    };

    try {
      // Basic validation
      if (!data) {
        result.valid = false;
        result.errors.push('Data is null or undefined');
        return result;
      }

      // Type validation
      if (schema.type && typeof data !== schema.type) {
        result.valid = false;
        result.errors.push(`Expected type ${schema.type}, got ${typeof data}`);
      }

      // Required fields validation
      if (schema.required && Array.isArray(schema.required)) {
        for (const field of schema.required) {
          if (!(field in data) || data[field] === null || data[field] === undefined) {
            result.valid = false;
            result.errors.push(`Required field '${field}' is missing`);
          }
        }
      }

      // Field-specific validation
      if (schema.properties) {
        for (const [key, fieldSchema] of Object.entries(schema.properties)) {
          if (key in data) {
            const fieldResult = this.validateField(data[key], fieldSchema);
            if (!fieldResult.valid) {
              result.valid = false;
              result.errors.push(...fieldResult.errors.map(err => `${key}: ${err}`));
            }
            result.warnings.push(...fieldResult.warnings.map(warn => `${key}: ${warn}`));
          }
        }
      }

      // Data cleaning
      if (result.valid) {
        result.correctedData = this.cleanData(data, schema);
      }

    } catch (error) {
      result.valid = false;
      result.errors.push(`Validation error: ${error.message}`);
    }

    return result;
  }

  private validateField(value: any, schema: any): DataValidationResult {
    const result: DataValidationResult = {
      valid: true,
      errors: [],
      warnings: []
    };

    // Type validation
    if (schema.type && typeof value !== schema.type) {
      result.valid = false;
      result.errors.push(`Expected type ${schema.type}, got ${typeof value}`);
    }

    // Range validation for numbers
    if (schema.type === 'number') {
      if (schema.minimum !== undefined && value < schema.minimum) {
        result.valid = false;
        result.errors.push(`Value ${value} is below minimum ${schema.minimum}`);
      }
      if (schema.maximum !== undefined && value > schema.maximum) {
        result.valid = false;
        result.errors.push(`Value ${value} is above maximum ${schema.maximum}`);
      }
    }

    // String validation
    if (schema.type === 'string') {
      if (schema.minLength !== undefined && value.length < schema.minLength) {
        result.valid = false;
        result.errors.push(`String length ${value.length} is below minimum ${schema.minLength}`);
      }
      if (schema.maxLength !== undefined && value.length > schema.maxLength) {
        result.valid = false;
        result.errors.push(`String length ${value.length} is above maximum ${schema.maxLength}`);
      }
      if (schema.pattern && !new RegExp(schema.pattern).test(value)) {
        result.valid = false;
        result.errors.push(`String does not match pattern ${schema.pattern}`);
      }
    }

    // Date validation
    if (schema.format === 'date' || schema.format === 'datetime') {
      if (!this.isValidDate(value)) {
        result.valid = false;
        result.errors.push(`Invalid date format: ${value}`);
      }
    }

    return result;
  }

  private cleanData(data: any, schema: any): any {
    const cleaned = { ...data };

    // Remove null/undefined values based on nullHandling
    if (this.defaultOptions.nullHandling === 'skip') {
      Object.keys(cleaned).forEach(key => {
        if (cleaned[key] === null || cleaned[key] === undefined) {
          delete cleaned[key];
        }
      });
    }

    // Apply default values
    if (schema.properties) {
      for (const [key, fieldSchema] of Object.entries(schema.properties)) {
        if (!(key in cleaned) && (fieldSchema as any).default !== undefined) {
          cleaned[key] = (fieldSchema as any).default;
        }
      }
    }

    // Format dates
    if (schema.properties) {
      for (const [key, fieldSchema] of Object.entries(schema.properties)) {
        if (key in cleaned && (fieldSchema as any).format === 'date') {
          cleaned[key] = this.formatTimestamp(cleaned[key]);
        }
      }
    }

    return cleaned;
  }

  // ===== UTILITY METHODS =====

  private mapArgusStatus(status: string): 'available' | 'busy' | 'break' | 'offline' {
    const statusMap: Record<string, 'available' | 'busy' | 'break' | 'offline'> = {
      'Ready': 'available',
      'Busy': 'busy',
      'Break': 'break',
      'Offline': 'offline',
      'Away': 'break',
      'Unavailable': 'offline'
    };
    return statusMap[status] || 'offline';
  }

  private mapArgusQueueType(type: string): 'inbound' | 'outbound' | 'chat' | 'email' {
    const typeMap: Record<string, 'inbound' | 'outbound' | 'chat' | 'email'> = {
      'Inbound': 'inbound',
      'Outbound': 'outbound',
      'Chat': 'chat',
      'Email': 'email',
      'Voice': 'inbound'
    };
    return typeMap[type] || 'inbound';
  }

  private mapArgusPriority(priority: number): 'low' | 'medium' | 'high' | 'critical' {
    if (priority <= 1) return 'low';
    if (priority <= 3) return 'medium';
    if (priority <= 5) return 'high';
    return 'critical';
  }

  private calculateBreakEnd(breakStart: string): string {
    const start = parseISO(breakStart);
    const end = new Date(start.getTime() + 15 * 60 * 1000); // 15 minutes
    return end.toISOString();
  }

  private calculateTotalHours(shifts: any[]): number {
    return shifts.reduce((total, shift) => {
      const start = parseISO(shift.startTime);
      const end = parseISO(shift.endTime);
      return total + (end.getTime() - start.getTime()) / (1000 * 60 * 60);
    }, 0);
  }

  private isValidDate(date: string): boolean {
    return isValid(parseISO(date));
  }

  private formatTimestamp(timestamp: string): string {
    if (!this.isValidDate(timestamp)) return timestamp;
    return format(parseISO(timestamp), this.defaultOptions.dateFormat!);
  }

  private formatLabel(key: string): string {
    return key.replace(/([A-Z])/g, ' $1')
              .replace(/^./, str => str.toUpperCase())
              .replace(/_/g, ' ');
  }

  private formatValue(value: any, type: string): any {
    if (value === null || value === undefined) return '';

    switch (type) {
      case 'number':
        return typeof value === 'number' ? 
          value.toFixed(this.defaultOptions.precision) : 
          value;
      case 'date':
        return this.isValidDate(value) ? 
          format(parseISO(value), 'yyyy-MM-dd') : 
          value;
      case 'boolean':
        return value ? 'Yes' : 'No';
      case 'status':
        return this.formatStatus(value);
      default:
        return value;
    }
  }

  private formatStatus(status: string): string {
    return status.replace(/_/g, ' ')
                .replace(/\b\w/g, l => l.toUpperCase());
  }

  private generateColors(count: number): string[] {
    const colors = [
      '#3B82F6', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#06B6D4', '#84CC16', '#F97316',
      '#EC4899', '#6B7280', '#14B8A6', '#F43F5E'
    ];
    return Array.from({ length: count }, (_, i) => colors[i % colors.length]);
  }

  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  private applyFilters(data: any[], filters: Record<string, any>): any[] {
    return data.filter(item => {
      return Object.entries(filters).every(([key, value]) => {
        if (value === null || value === undefined || value === '') return true;
        
        const itemValue = item[key];
        if (typeof value === 'string') {
          return itemValue?.toString().toLowerCase().includes(value.toLowerCase());
        }
        return itemValue === value;
      });
    });
  }

  private applySorting(data: any[], sorting: { column: string; direction: 'asc' | 'desc' }): any[] {
    return [...data].sort((a, b) => {
      const aVal = a[sorting.column];
      const bVal = b[sorting.column];
      
      if (aVal === bVal) return 0;
      
      let comparison = 0;
      if (typeof aVal === 'string' && typeof bVal === 'string') {
        comparison = aVal.localeCompare(bVal);
      } else if (typeof aVal === 'number' && typeof bVal === 'number') {
        comparison = aVal - bVal;
      } else if (this.isValidDate(aVal) && this.isValidDate(bVal)) {
        comparison = parseISO(aVal).getTime() - parseISO(bVal).getTime();
      } else {
        comparison = String(aVal).localeCompare(String(bVal));
      }
      
      return sorting.direction === 'asc' ? comparison : -comparison;
    });
  }

  private calculateStatusDuration(currentTimestamp: string, previousTimestamp?: string): number {
    if (!previousTimestamp) return 0;
    return parseISO(currentTimestamp).getTime() - parseISO(previousTimestamp).getTime();
  }

  private generateMetricAlerts(metrics: any, thresholds: any): any[] {
    const alerts: any[] = [];
    
    Object.entries(thresholds).forEach(([metric, threshold]) => {
      const value = metrics[metric];
      if (value !== undefined && value > threshold) {
        alerts.push({
          metric,
          value,
          threshold,
          severity: this.calculateAlertSeverity(value, threshold as number),
          message: `${metric} (${value}) exceeds threshold (${threshold})`
        });
      }
    });
    
    return alerts;
  }

  private calculateAlertSeverity(value: number, threshold: number): 'low' | 'medium' | 'high' | 'critical' {
    const ratio = value / threshold;
    if (ratio > 2) return 'critical';
    if (ratio > 1.5) return 'high';
    if (ratio > 1.2) return 'medium';
    return 'low';
  }

  private calculateScheduleImpact(data: any): any {
    return {
      agentsAffected: data.agents_affected || 1,
      hoursChanged: data.hours_changed || 0,
      costImpact: data.cost_impact || 0,
      coverageImpact: data.coverage_impact || 0,
      automationApplied: data.automation_applied || false
    };
  }

  // ===== PUBLIC UTILITY METHODS =====

  public getTransformationOptions(): TransformationOptions {
    return { ...this.defaultOptions };
  }

  public setTransformationOptions(options: Partial<TransformationOptions>): void {
    this.defaultOptions = { ...this.defaultOptions, ...options };
  }

  public resetTransformationOptions(): void {
    this.defaultOptions = {
      dateFormat: 'yyyy-MM-dd HH:mm:ss',
      timezone: 'UTC',
      precision: 2,
      nullHandling: 'default',
      validation: true,
      locale: 'en-US'
    };
  }
}

// ===== SINGLETON INSTANCE =====

const dataTransformationService = new DataTransformationService();
export default dataTransformationService;
export { DataTransformationService };