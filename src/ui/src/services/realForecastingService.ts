// Real Forecasting Service - NO MOCK FALLBACKS
// This service makes REAL API calls to backend forecasting endpoints
// If the API fails, it returns REAL errors to the user

interface ForecastDataPoint {
  timestamp: string;
  predicted: number;
  actual?: number;
  confidence: number;
  adjustments?: number;
  requiredAgents: number;
  isWeekend: boolean;
  hour: number;
  dayOfWeek: number;
}

interface ForecastRequest {
  algorithm: string;
  startDate: string;
  endDate: string;
  interval: 'hourly' | 'daily' | 'weekly';
  includeHistorical?: boolean;
}

interface ForecastResponse {
  success: boolean;
  data?: {
    forecasts: ForecastDataPoint[];
    algorithm: string;
    accuracy?: {
      mape: number;
      wape: number;
      confidence: number;
    };
    metadata: {
      generatedAt: string;
      dataPoints: number;
      coverage: string;
    };
  };
  error?: string;
}

interface AlgorithmOption {
  id: string;
  name: string;
  description: string;
  accuracy: number;
  enabled: boolean;
}

interface AccuracyMetrics {
  mape: number;
  wape: number;
  mae: number;
  rmse: number;
  confidence: number;
  lastUpdated: string;
}

interface ImportDataRequest {
  file: File;
  format: 'csv' | 'excel';
  mapping: {
    timestamp: string;
    volume: string;
    actual?: string;
  };
}

const API_BASE_URL = 'http://localhost:8001';

class RealForecastingService {
  private token: string | null = null;

  constructor() {
    this.token = localStorage.getItem('authToken');
  }

  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;
    
    const headers = {
      'Content-Type': 'application/json',
      ...(this.token && { 'Authorization': `Bearer ${this.token}` }),
      ...options.headers,
    };

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Forecasting API Error: ${error.message}`);
      }
      throw new Error('Unknown forecasting API error');
    }
  }

  // Health check to verify API connectivity
  async checkApiHealth(): Promise<{ healthy: boolean; message: string }> {
    try {
      const response = await this.makeRequest<{ status: string; service: string }>('/health');
      return {
        healthy: response.status === 'healthy',
        message: `API Health: ${response.status} - ${response.service}`
      };
    } catch (error) {
      return {
        healthy: false,
        message: error instanceof Error ? error.message : 'Health check failed'
      };
    }
  }

  // Generate forecasts using specified algorithm
  async generateForecast(request: ForecastRequest): Promise<ForecastResponse> {
    try {
      const response = await this.makeRequest<ForecastResponse>('/api/v1/forecasting/generate', {
        method: 'POST',
        body: JSON.stringify(request),
      });

      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Forecast generation failed'
      };
    }
  }

  // Get available forecasting algorithms
  async getAvailableAlgorithms(): Promise<{ success: boolean; algorithms?: AlgorithmOption[]; error?: string }> {
    try {
      const response = await this.makeRequest<{ algorithms: AlgorithmOption[] }>('/api/v1/forecasting/algorithms');
      
      return {
        success: true,
        algorithms: response.algorithms
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch algorithms'
      };
    }
  }

  // Get historical forecast accuracy metrics
  async getAccuracyMetrics(algorithm?: string): Promise<{ success: boolean; metrics?: AccuracyMetrics; error?: string }> {
    try {
      const endpoint = algorithm 
        ? `/api/v1/forecasting/accuracy?algorithm=${algorithm}`
        : '/api/v1/forecasting/accuracy';
      
      const response = await this.makeRequest<{ metrics: AccuracyMetrics }>(endpoint);
      
      return {
        success: true,
        metrics: response.metrics
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch accuracy metrics'
      };
    }
  }

  // Import historical data for forecasting
  async importHistoricalData(request: ImportDataRequest): Promise<{ success: boolean; imported?: number; error?: string }> {
    try {
      const formData = new FormData();
      formData.append('file', request.file);
      formData.append('format', request.format);
      formData.append('mapping', JSON.stringify(request.mapping));

      const response = await this.makeRequest<{ imported: number }>('/api/v1/forecasting/import', {
        method: 'POST',
        headers: {}, // Don't set Content-Type for FormData
        body: formData,
      });

      return {
        success: true,
        imported: response.imported
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to import data'
      };
    }
  }

  // Get current forecast for specific time range
  async getCurrentForecast(
    startDate: string, 
    endDate: string, 
    algorithm = 'enhanced-arima'
  ): Promise<{ success: boolean; data?: ForecastDataPoint[]; error?: string }> {
    try {
      const params = new URLSearchParams({
        start_date: startDate,
        end_date: endDate,
        algorithm: algorithm
      });

      const response = await this.makeRequest<{ forecasts: ForecastDataPoint[] }>(`/api/v1/forecasting/current?${params}`);
      
      return {
        success: true,
        data: response.forecasts
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch current forecast'
      };
    }
  }

  // Update forecast with real-time adjustments
  async updateForecast(
    timestamp: string, 
    adjustments: { predicted?: number; confidence?: number }
  ): Promise<{ success: boolean; error?: string }> {
    try {
      await this.makeRequest('/api/v1/forecasting/adjust', {
        method: 'PUT',
        body: JSON.stringify({ timestamp, adjustments }),
      });

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update forecast'
      };
    }
  }
}

// Export singleton instance
const realForecastingService = new RealForecastingService();
export default realForecastingService;

// Export types for use in components
export type {
  ForecastDataPoint,
  ForecastRequest,
  ForecastResponse,
  AlgorithmOption,
  AccuracyMetrics,
  ImportDataRequest
};