// API Service with progressive enhancement
// Try real API → Fallback to mock data

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

// Mock data fallbacks
const mockData = {
  user: {
    id: 1,
    name: 'Anna Petrov',
    email: 'anna.petrov@technoservice.ru',
    role: 'Supervisor',
    department: 'Call Center Operations'
  },
  metrics: {
    activeAgents: 127,
    serviceLevel: 94.2,
    callsHandled: 3847,
    avgWaitTime: '0:45',
    forecastAccuracy: 95.6,
    utilization: 87.3,
    satisfaction: 4.3
  },
  employees: [
    { id: 'EMP001', name: 'Anna Petrov', status: 'active', department: 'Support', efficiency: 92.5 },
    { id: 'EMP002', name: 'Mikhail Volkov', status: 'active', department: 'Sales', efficiency: 88.3 },
    { id: 'EMP003', name: 'Elena Kozlov', status: 'vacation', department: 'Technical', efficiency: 94.1 },
    { id: 'EMP004', name: 'Pavel Orlov', status: 'training', department: 'Support', efficiency: 87.7 },
    { id: 'EMP005', name: 'Sofia Ivanov', status: 'active', department: 'Management', efficiency: 91.2 }
  ]
};

// API wrapper with fallback
async function apiCall<T>(endpoint: string, options?: RequestInit): Promise<T> {
  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers
      }
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.warn(`API call failed, using mock data for ${endpoint}:`, error);
    
    // Return mock data based on endpoint
    if (endpoint.includes('/auth/login')) {
      return { token: 'mock-token', user: mockData.user } as any;
    }
    if (endpoint.includes('/metrics')) {
      return mockData.metrics as any;
    }
    if (endpoint.includes('/employees')) {
      return mockData.employees as any;
    }
    
    throw error;
  }
}

// Auth API
export const authAPI = {
  login: async (email: string, password: string) => {
    return apiCall('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
  },
  
  logout: async () => {
    return apiCall('/auth/logout', { method: 'POST' });
  }
};

// Metrics API
export const metricsAPI = {
  getDashboardMetrics: async () => {
    return apiCall<typeof mockData.metrics>('/metrics/dashboard');
  },
  
  getRealtimeMetrics: async () => {
    return apiCall<typeof mockData.metrics>('/metrics/realtime');
  }
};

// Employees API
export const employeesAPI = {
  getAll: async () => {
    return apiCall<typeof mockData.employees>('/personnel/employees');
  },
  
  getById: async (id: string) => {
    const employees = await employeesAPI.getAll();
    return employees.find(emp => emp.id === id);
  }
};

// Schedule API
export const scheduleAPI = {
  getSchedule: async (date?: Date) => {
    const dateStr = date?.toISOString().split('T')[0] || new Date().toISOString().split('T')[0];
    return apiCall(`/schedule?date=${dateStr}`);
  }
};

// Forecasting API
export const forecastingAPI = {
  getForecast: async (period: string = 'week') => {
    return apiCall(`/forecast?period=${period}`);
  },
  
  getAccuracy: async () => {
    return apiCall<{ accuracy: number }>('/forecast/accuracy');
  }
};

// Reports API
export const reportsAPI = {
  getKPIs: async () => {
    return apiCall('/reports/kpis');
  },
  
  generateReport: async (type: string, params: any) => {
    return apiCall('/reports/generate', {
      method: 'POST',
      body: JSON.stringify({ type, params })
    });
  }
};

// WebSocket for real-time updates (with fallback)
export const createRealtimeConnection = () => {
  try {
    const ws = new WebSocket(`ws://localhost:3001/ws`);
    
    ws.onerror = () => {
      console.warn('WebSocket connection failed, using polling fallback');
    };
    
    return ws;
  } catch (error) {
    console.warn('WebSocket not available, using polling');
    return null;
  }
};

export default {
  auth: authAPI,
  metrics: metricsAPI,
  employees: employeesAPI,
  schedule: scheduleAPI,
  forecasting: forecastingAPI,
  reports: reportsAPI,
  createRealtimeConnection
};