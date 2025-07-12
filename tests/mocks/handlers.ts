/**
 * MSW (Mock Service Worker) handlers for API mocking in tests
 */
import { rest } from 'msw';

const API_URL = 'http://localhost:8000';

export const handlers = [
  // Authentication
  rest.post(`${API_URL}/api/auth/login`, (req, res, ctx) => {
    const { email, password } = req.body as any;
    
    if (email === 'admin@test.com' && password === 'password123') {
      return res(
        ctx.status(200),
        ctx.json({
          access_token: 'mock-jwt-token',
          token_type: 'bearer',
          user: {
            id: 1,
            email: 'admin@test.com',
            role: 'admin',
            name: 'Admin User'
          }
        })
      );
    }
    
    return res(
      ctx.status(401),
      ctx.json({ detail: 'Invalid credentials' })
    );
  }),

  // Employees
  rest.get(`${API_URL}/api/employees`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        {
          id: 1,
          name: 'John Doe',
          email: 'john.doe@test.com',
          skills: ['sales', 'support'],
          max_hours_per_week: 40
        },
        {
          id: 2,
          name: 'Jane Smith',
          email: 'jane.smith@test.com',
          skills: ['support'],
          max_hours_per_week: 35
        }
      ])
    );
  }),

  rest.get(`${API_URL}/api/employees/:id`, (req, res, ctx) => {
    const { id } = req.params;
    
    return res(
      ctx.status(200),
      ctx.json({
        id: Number(id),
        name: 'John Doe',
        email: 'john.doe@test.com',
        skills: ['sales', 'support'],
        max_hours_per_week: 40,
        shift_preference: 'morning',
        hire_date: '2023-01-15'
      })
    );
  }),

  // Schedules
  rest.get(`${API_URL}/api/schedules`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        {
          id: 1,
          name: 'Week 1 Schedule',
          start_date: '2024-01-01',
          end_date: '2024-01-07',
          status: 'published',
          created_at: '2023-12-20T10:00:00Z'
        }
      ])
    );
  }),

  rest.post(`${API_URL}/api/schedules`, (req, res, ctx) => {
    const body = req.body as any;
    
    return res(
      ctx.status(201),
      ctx.json({
        id: Math.floor(Math.random() * 1000),
        ...body,
        status: 'draft',
        created_at: new Date().toISOString()
      })
    );
  }),

  rest.post(`${API_URL}/api/schedules/generate`, async (req, res, ctx) => {
    // Simulate processing delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return res(
      ctx.status(201),
      ctx.json({
        id: Math.floor(Math.random() * 1000),
        status: 'generated',
        shifts: generateMockShifts(),
        metrics: {
          coverage: 0.95,
          efficiency: 0.88,
          cost: 12500.00
        }
      })
    );
  }),

  // Shifts
  rest.get(`${API_URL}/api/schedules/:scheduleId/shifts`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json(generateMockShifts())
    );
  }),

  rest.post(`${API_URL}/api/shifts/swap`, (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        id: Math.floor(Math.random() * 1000),
        status: 'pending',
        created_at: new Date().toISOString()
      })
    );
  }),

  // Forecasts
  rest.post(`${API_URL}/api/forecasts/generate`, async (req, res, ctx) => {
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    return res(
      ctx.status(201),
      ctx.json({
        forecast_id: Math.floor(Math.random() * 1000),
        accuracy: {
          mape: 8.5,
          rmse: 12.3
        },
        data: generateMockForecast()
      })
    );
  }),

  // Real-time updates (simulated)
  rest.get(`${API_URL}/api/realtime/poll`, (req, res, ctx) => {
    const updates = Math.random() > 0.7 ? [{
      type: 'schedule_update',
      data: {
        schedule_id: 1,
        message: 'Schedule has been updated'
      },
      timestamp: new Date().toISOString()
    }] : [];
    
    return res(
      ctx.status(200),
      ctx.json(updates)
    );
  }),

  // Error scenarios
  rest.get(`${API_URL}/api/error/500`, (req, res, ctx) => {
    return res(
      ctx.status(500),
      ctx.json({ detail: 'Internal server error' })
    );
  }),

  rest.get(`${API_URL}/api/error/timeout`, async (req, res, ctx) => {
    await new Promise(resolve => setTimeout(resolve, 10000));
    return res(ctx.status(200));
  })
];

// Helper functions
function generateMockShifts() {
  const shifts = [];
  const employees = [1, 2, 3, 4, 5];
  const startDate = new Date('2024-01-01');
  
  for (let day = 0; day < 7; day++) {
    for (const employeeId of employees) {
      if (Math.random() > 0.3) { // 70% chance of shift
        const date = new Date(startDate);
        date.setDate(date.getDate() + day);
        
        shifts.push({
          id: shifts.length + 1,
          employee_id: employeeId,
          date: date.toISOString().split('T')[0],
          start_time: Math.random() > 0.5 ? '08:00' : '14:00',
          end_time: Math.random() > 0.5 ? '16:00' : '22:00',
          skill_id: Math.floor(Math.random() * 3) + 1
        });
      }
    }
  }
  
  return shifts;
}

function generateMockForecast() {
  const forecast = [];
  const startDate = new Date('2024-01-01');
  
  for (let day = 0; day < 30; day++) {
    const date = new Date(startDate);
    date.setDate(date.getDate() + day);
    
    const hourlyData = [];
    for (let hour = 0; hour < 24; hour++) {
      const baseVolume = hour >= 8 && hour <= 20 ? 100 : 20;
      const volume = baseVolume + Math.floor(Math.random() * 50 - 25);
      
      hourlyData.push({
        hour,
        volume,
        confidence_lower: Math.floor(volume * 0.85),
        confidence_upper: Math.floor(volume * 1.15)
      });
    }
    
    forecast.push({
      date: date.toISOString().split('T')[0],
      hourly_volumes: hourlyData
    });
  }
  
  return forecast;
}

// Dynamic handlers for specific test scenarios
export const createScheduleErrorHandler = () => {
  return rest.post(`${API_URL}/api/schedules`, (req, res, ctx) => {
    return res(
      ctx.status(400),
      ctx.json({ 
        detail: 'Insufficient employees for requested period',
        required: 50,
        available: 30
      })
    );
  });
};

export const createSlowResponseHandler = (endpoint: string, delay: number) => {
  return rest.get(`${API_URL}${endpoint}`, async (req, res, ctx) => {
    await new Promise(resolve => setTimeout(resolve, delay));
    return res(ctx.status(200), ctx.json({ data: 'slow response' }));
  });
};