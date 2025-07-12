// Simple Express server for mock API during development
// Run with: node mock-api-server.js

const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Mock data
const mockData = {
  user: {
    id: 1,
    name: 'Анна Петрова',
    email: 'anna.petrova@technoservice.ru',
    role: 'Супервайзер',
    department: 'ООО "ТехноСервис" - Контакт-центр',
    company: 'ООО "ТехноСервис"'
  },
  metrics: {
    activeAgents: 47,  // ТехноСервис: 50 total, 3 on break
    serviceLevel: 94.2,
    callsHandled: 1847,  // Realistic for 50 agents
    avgWaitTime: '0:45',
    forecastAccuracy: 95.6,
    utilization: 87.3,
    satisfaction: 4.3,
    totalAgents: 50,
    company: 'ООО "ТехноСервис"'
  },
  // ООО "ТехноСервис" - 50 agents scenario
  employees: [
    // Team 1 - Technical Support (15 agents)
    { id: 'TS001', name: 'Анна Петрова', status: 'active', department: 'Техподдержка', efficiency: 92.5, skills: ['Русский', 'Английский', 'Техническая поддержка'] },
    { id: 'TS002', name: 'Михаил Волков', status: 'active', department: 'Техподдержка', efficiency: 88.3, skills: ['Русский', 'Техническая поддержка', '1С'] },
    { id: 'TS003', name: 'Елена Козлова', status: 'vacation', department: 'Техподдержка', efficiency: 94.1, skills: ['Русский', 'Английский', 'IT-системы'] },
    { id: 'TS004', name: 'Павел Орлов', status: 'training', department: 'Техподдержка', efficiency: 87.7, skills: ['Русский', 'Клиентский сервис'] },
    { id: 'TS005', name: 'София Иванова', status: 'active', department: 'Техподдержка', efficiency: 91.2, skills: ['Русский', 'Английский', 'Аналитика'] },
    
    // Team 2 - Sales (20 agents)
    { id: 'SL006', name: 'Дмитрий Федоров', status: 'active', department: 'Продажи', efficiency: 89.5, skills: ['Русский', 'Продажи B2B'] },
    { id: 'SL007', name: 'Наталья Смирнова', status: 'active', department: 'Продажи', efficiency: 93.2, skills: ['Русский', 'Английский', 'Продажи'] },
    { id: 'SL008', name: 'Виктор Петров', status: 'active', department: 'Продажи', efficiency: 90.8, skills: ['Русский', 'Холодные звонки'] },
    { id: 'SL009', name: 'Ольга Морозова', status: 'active', department: 'Продажи', efficiency: 91.5, skills: ['Русский', 'CRM', 'Продажи'] },
    { id: 'SL010', name: 'Алексей Новиков', status: 'active', department: 'Продажи', efficiency: 88.9, skills: ['Русский', 'Презентации'] },
    
    // Team 3 - Customer Service (15 agents)
    { id: 'CS011', name: 'Татьяна Белова', status: 'active', department: 'Клиентский сервис', efficiency: 92.3, skills: ['Русский', 'Эмпатия', 'Конфликтология'] },
    { id: 'CS012', name: 'Игорь Черный', status: 'active', department: 'Клиентский сервис', efficiency: 87.6, skills: ['Русский', 'Английский'] },
    { id: 'CS013', name: 'Марина Золотова', status: 'active', department: 'Клиентский сервис', efficiency: 94.7, skills: ['Русский', 'VIP-клиенты'] },
    { id: 'CS014', name: 'Андрей Серов', status: 'lunch', department: 'Клиентский сервис', efficiency: 89.2, skills: ['Русский', 'Жалобы'] },
    { id: 'CS015', name: 'Екатерина Зеленова', status: 'active', department: 'Клиентский сервис', efficiency: 91.8, skills: ['Русский', 'Чат-поддержка'] }
  ],
  schedule: {
    date: new Date().toISOString().split('T')[0],
    shifts: [
      { employeeId: 'EMP001', start: '09:00', end: '17:00', break: '13:00-14:00' },
      { employeeId: 'EMP002', start: '10:00', end: '18:00', break: '14:00-15:00' },
      { employeeId: 'EMP004', start: '08:00', end: '16:00', break: '12:00-13:00' },
      { employeeId: 'EMP006', start: '11:00', end: '19:00', break: '15:00-16:00' },
      { employeeId: 'EMP007', start: '09:00', end: '17:00', break: '13:00-14:00' }
    ]
  },
  forecast: {
    period: 'week',
    data: [
      { day: 'Monday', predicted: 850, actual: 823, variance: -3.2 },
      { day: 'Tuesday', predicted: 920, actual: 934, variance: 1.5 },
      { day: 'Wednesday', predicted: 890, actual: 878, variance: -1.3 },
      { day: 'Thursday', predicted: 950, actual: 968, variance: 1.9 },
      { day: 'Friday', predicted: 1020, actual: null, variance: null }
    ],
    accuracy: 95.6
  }
};

// Routes

// Auth endpoints
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  // Accept demo credentials
  if (email === 'admin@demo.com' && password === 'AdminPass123!') {
    res.json({
      token: 'mock-jwt-token-' + Date.now(),
      user: mockData.user
    });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

app.post('/api/auth/logout', (req, res) => {
  res.json({ success: true });
});

// Metrics endpoints
app.get('/api/metrics/dashboard', (req, res) => {
  // Simulate some randomness for real-time feel
  const metrics = {
    ...mockData.metrics,
    activeAgents: 120 + Math.floor(Math.random() * 15),
    callsHandled: 3800 + Math.floor(Math.random() * 100),
    serviceLevel: 92 + Math.random() * 4
  };
  res.json(metrics);
});

app.get('/api/metrics/realtime', (req, res) => {
  res.json({
    ...mockData.metrics,
    timestamp: new Date().toISOString()
  });
});

// Personnel endpoints
app.get('/api/personnel/employees', (req, res) => {
  res.json(mockData.employees);
});

app.get('/api/personnel/employees/:id', (req, res) => {
  const employee = mockData.employees.find(e => e.id === req.params.id);
  if (employee) {
    res.json(employee);
  } else {
    res.status(404).json({ error: 'Employee not found' });
  }
});

// Schedule endpoints
app.get('/api/schedule', (req, res) => {
  res.json(mockData.schedule);
});

// Forecasting endpoints
app.get('/api/forecast', (req, res) => {
  res.json(mockData.forecast);
});

app.get('/api/forecast/accuracy', (req, res) => {
  res.json({ accuracy: mockData.forecast.accuracy });
});

// Reports endpoints
app.get('/api/reports/kpis', (req, res) => {
  res.json({
    serviceLevel: { value: 94.2, target: 90, trend: 'up' },
    avgHandleTime: { value: 245, target: 300, trend: 'down' },
    firstCallResolution: { value: 87.5, target: 85, trend: 'stable' },
    customerSatisfaction: { value: 4.3, target: 4.0, trend: 'up' }
  });
});

app.post('/api/reports/generate', (req, res) => {
  const { type, params } = req.body;
  res.json({
    id: 'report-' + Date.now(),
    type,
    status: 'processing',
    estimatedTime: 30
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`Mock API server running on http://localhost:${PORT}`);
  console.log('Available endpoints:');
  console.log('  POST /api/auth/login');
  console.log('  GET  /api/metrics/dashboard');
  console.log('  GET  /api/personnel/employees');
  console.log('  GET  /api/schedule');
  console.log('  GET  /api/forecast');
  console.log('  GET  /api/reports/kpis');
});