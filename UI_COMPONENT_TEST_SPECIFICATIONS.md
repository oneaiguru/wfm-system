# UI COMPONENT TEST SPECIFICATIONS

## 🎯 **TESTING OVERVIEW**
This document provides comprehensive test specifications for all 5 BDD-compliant UI components, following test-driven development principles and ensuring production readiness through systematic verification.

---

## 📋 **TESTING STRATEGY SUMMARY**

### **Testing Pyramid Structure**:
```typescript
interface TestingPyramid {
  unitTests: {
    coverage: "80%+";
    focus: "Component logic, validation functions, data transformations";
    tools: "Jest, React Testing Library";
    frequency: "Every code change";
  };
  
  integrationTests: {
    coverage: "60%+";
    focus: "API integration, component interaction, data flow";
    tools: "Jest, MSW (Mock Service Worker)";
    frequency: "Every feature completion";
  };
  
  bddTests: {
    coverage: "100% of BDD scenarios";
    focus: "User workflows, scenario compliance, acceptance criteria";
    tools: "Cucumber, Selenium WebDriver";
    frequency: "Every sprint";
  };
  
  e2eTests: {
    coverage: "Critical user paths";
    focus: "Full system integration, real API calls, production simulation";
    tools: "Playwright, Cypress";
    frequency: "Before release";
  };
}
```

### **Test Data Management**:
```typescript
interface TestDataStrategy {
  mockData: {
    purpose: "Unit and integration testing";
    source: "BDD specifications and demo data";
    maintenance: "Version controlled with component code";
  };
  
  fixtureData: {
    purpose: "Consistent test scenarios";
    format: "JSON files with Russian localization";
    coverage: "All BDD scenarios and edge cases";
  };
  
  realData: {
    purpose: "E2E testing and production validation";
    source: "Test database with sanitized production data";
    refresh: "Weekly automated refresh";
  };
}
```

---

## 🔐 **LOGIN COMPONENT TEST SPECIFICATIONS**

### **Unit Tests**:
```typescript
// File: __tests__/components/Login.test.tsx
describe('Login Component Unit Tests', () => {
  
  test('should render Russian interface by default per BDD requirement', () => {
    render(<Login />);
    
    expect(screen.getByText('Вход в систему WFM')).toBeInTheDocument();
    expect(screen.getByText('Имя пользователя')).toBeInTheDocument();
    expect(screen.getByText('Пароль')).toBeInTheDocument();
    expect(screen.getByText('Войти')).toBeInTheDocument();
  });
  
  test('should switch language when language toggle clicked', () => {
    render(<Login />);
    
    fireEvent.click(screen.getByText('English'));
    
    expect(screen.getByText('Login to WFM System')).toBeInTheDocument();
    expect(screen.getByText('Username')).toBeInTheDocument();
    expect(screen.getByText('Password')).toBeInTheDocument();
    expect(screen.getByText('Login')).toBeInTheDocument();
  });
  
  test('should validate required fields with Russian error messages', async () => {
    render(<Login />);
    
    fireEvent.click(screen.getByText('Войти'));
    
    await waitFor(() => {
      expect(screen.getByText('Пожалуйста, введите имя пользователя и пароль')).toBeInTheDocument();
    });
  });
  
  test('should handle API unavailable with Russian error message', async () => {
    // Mock API health check failure
    jest.spyOn(global, 'fetch').mockRejectedValueOnce(new Error('Network error'));
    
    render(<Login />);
    fireEvent.change(screen.getByPlaceholderText('Имя пользователя'), { target: { value: 'admin' } });
    fireEvent.change(screen.getByPlaceholderText('Пароль'), { target: { value: 'password' } });
    fireEvent.click(screen.getByText('Войти'));
    
    await waitFor(() => {
      expect(screen.getByText('Сервер API недоступен. Попробуйте позже.')).toBeInTheDocument();
    });
  });
});
```

### **Integration Tests**:
```typescript
// File: __tests__/integration/Login.integration.test.tsx
describe('Login Integration Tests', () => {
  
  beforeEach(() => {
    // Setup MSW for API mocking
    server.use(
      rest.get('/api/v1/health', (req, res, ctx) => {
        return res(ctx.status(200), ctx.json({ status: 'healthy' }));
      }),
      rest.post('/api/v1/auth/login', (req, res, ctx) => {
        const { username, password } = req.body as LoginRequest;
        
        if (username === 'admin' && password === 'AdminPass123!') {
          return res(ctx.status(200), ctx.json({
            status: 'success',
            access_token: 'mock-jwt-token',
            user: { id: '1', username: 'admin', role: 'admin', name: 'Admin User' }
          }));
        }
        
        return res(ctx.status(401), ctx.json({
          status: 'error',
          message: 'Invalid credentials'
        }));
      })
    );
  });
  
  test('should authenticate with valid credentials', async () => {
    render(<Login />);
    
    fireEvent.change(screen.getByPlaceholderText('Имя пользователя'), { target: { value: 'admin' } });
    fireEvent.change(screen.getByPlaceholderText('Пароль'), { target: { value: 'AdminPass123!' } });
    fireEvent.click(screen.getByText('Войти'));
    
    await waitFor(() => {
      expect(screen.getByText('Добро пожаловать, Admin User!')).toBeInTheDocument();
      expect(screen.getByText('Перенаправление на панель управления...')).toBeInTheDocument();
    });
    
    // Verify token storage
    expect(localStorage.getItem('authToken')).toBe('mock-jwt-token');
  });
  
  test('should handle authentication failure with Russian error', async () => {
    render(<Login />);
    
    fireEvent.change(screen.getByPlaceholderText('Имя пользователя'), { target: { value: 'invalid' } });
    fireEvent.change(screen.getByPlaceholderText('Пароль'), { target: { value: 'invalid' } });
    fireEvent.click(screen.getByText('Войти'));
    
    await waitFor(() => {
      expect(screen.getByText('Ошибка аутентификации. Проверьте ваши учетные данные.')).toBeInTheDocument();
    });
  });
});
```

### **BDD Scenario Tests**:
```typescript
// File: __tests__/bdd/login.steps.ts
import { Given, When, Then } from '@cucumber/cucumber';

Given('I have the WFM login page open', async function () {
  await this.page.goto('/login');
  await this.page.waitForSelector('[data-testid="login-form"]');
});

When('I enter my credentials:', async function (dataTable) {
  const credentials = dataTable.rowsHash();
  await this.page.fill('[placeholder="Имя пользователя"]', credentials.Username);
  await this.page.fill('[placeholder="Пароль"]', credentials.Password);
});

When('I click the login button', async function () {
  await this.page.click('button:has-text("Войти")');
});

Then('I should authenticate via the API', async function () {
  // Wait for API call to complete
  await this.page.waitForResponse(response => 
    response.url().includes('/api/v1/auth/login') && response.status() === 200
  );
});

Then('I should see the Russian interface elements', async function () {
  await expect(this.page.locator('text=Вход в систему WFM')).toBeVisible();
  await expect(this.page.locator('text=Имя пользователя')).toBeVisible();
  await expect(this.page.locator('text=Пароль')).toBeVisible();
  await expect(this.page.locator('text=Войти')).toBeVisible();
});
```

---

## 📊 **DASHBOARD COMPONENT TEST SPECIFICATIONS**

### **Unit Tests**:
```typescript
// File: __tests__/components/DashboardBDD.test.tsx
describe('Dashboard Component Unit Tests', () => {
  
  const mockMetricsData = {
    dashboard_title: "Мониторинг операций в реальном времени",
    operators_online_percent: {
      value: 85.3,
      label: "Операторы онлайн %",
      color: "green",
      threshold: "Зелёный >80%, Жёлтый 70-80%, Красный <70%"
    },
    load_deviation: {
      value: -8.2,
      label: "Отклонение нагрузки",
      color: "green",
      threshold: "±10% Зелёный, ±20% Жёлтый, >20% Красный"
    }
    // ... other metrics
  };
  
  test('should display six key metrics per BDD specification', () => {
    render(<DashboardBDD />);
    
    // Mock successful API response
    jest.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: true,
      json: async () => mockMetricsData
    } as Response);
    
    expect(screen.getByText('Операторы онлайн %')).toBeInTheDocument();
    expect(screen.getByText('Отклонение нагрузки')).toBeInTheDocument();
    expect(screen.getByText('Требуется операторов')).toBeInTheDocument();
    expect(screen.getByText('Производительность SLA')).toBeInTheDocument();
    expect(screen.getByText('Коэффициент ACD')).toBeInTheDocument();
    expect(screen.getByText('Тренд AHT')).toBeInTheDocument();
  });
  
  test('should apply traffic light colors correctly', () => {
    const { getOperatorsOnlineColor } = require('../../src/components/DashboardBDD');
    
    expect(getOperatorsOnlineColor(85)).toBe('green');  // >80%
    expect(getOperatorsOnlineColor(75)).toBe('yellow'); // 70-80%
    expect(getOperatorsOnlineColor(65)).toBe('red');    // <70%
  });
  
  test('should update every 30 seconds per BDD requirement', async () => {
    jest.useFakeTimers();
    const fetchSpy = jest.spyOn(global, 'fetch');
    
    render(<DashboardBDD />);
    
    // Fast-forward 30 seconds
    act(() => {
      jest.advanceTimersByTime(30000);
    });
    
    expect(fetchSpy).toHaveBeenCalledWith('/api/v1/metrics/dashboard');
    
    jest.useRealTimers();
  });
});
```

### **Performance Tests**:
```typescript
// File: __tests__/performance/Dashboard.performance.test.tsx
describe('Dashboard Performance Tests', () => {
  
  test('should load metrics within 2 seconds', async () => {
    const startTime = performance.now();
    
    render(<DashboardBDD />);
    
    await waitFor(() => {
      expect(screen.getByText('Операторы онлайн %')).toBeInTheDocument();
    });
    
    const loadTime = performance.now() - startTime;
    expect(loadTime).toBeLessThan(2000); // Less than 2 seconds
  });
  
  test('should handle rapid updates without memory leaks', async () => {
    const { unmount } = render(<DashboardBDD />);
    
    // Simulate rapid updates
    for (let i = 0; i < 100; i++) {
      act(() => {
        jest.advanceTimersByTime(30000);
      });
    }
    
    unmount();
    
    // Check for memory leaks - component should clean up timers
    expect(jest.getTimerCount()).toBe(0);
  });
});
```

---

## 👥 **EMPLOYEE COMPONENT TEST SPECIFICATIONS**

### **Unit Tests**:
```typescript
// File: __tests__/components/EmployeeListBDD.test.tsx
describe('Employee List Component Unit Tests', () => {
  
  test('should validate Cyrillic names per BDD requirement', () => {
    const { validateCyrillic } = require('../../src/components/EmployeeListBDD');
    
    // Valid Cyrillic names
    expect(validateCyrillic('Иванов')).toBe(true);
    expect(validateCyrillic('Анна-Мария')).toBe(true);
    expect(validateCyrillic('О\'Коннор')).toBe(false); // Apostrophe not allowed
    
    // Invalid Latin names
    expect(validateCyrillic('Smith')).toBe(false);
    expect(validateCyrillic('John')).toBe(false);
    expect(validateCyrillic('123')).toBe(false);
  });
  
  test('should display 5-level department hierarchy', () => {
    render(<EmployeeListBDD />);
    
    fireEvent.click(screen.getByText('Создать сотрудника'));
    fireEvent.click(screen.getByText('Выберите подразделение'));
    
    expect(screen.getByText('Колл-центр')).toBeInTheDocument();               // Level 1
    expect(screen.getByText('Техническая поддержка')).toBeInTheDocument();    // Level 2
    expect(screen.getByText('Отдел продаж')).toBeInTheDocument();             // Level 2
    expect(screen.getByText('Поддержка 1-го уровня')).toBeInTheDocument();    // Level 3
    expect(screen.getByText('Поддержка 2-го уровня')).toBeInTheDocument();    // Level 3
  });
  
  test('should search employees by name and personnel number', async () => {
    const mockEmployees = [
      { id: '1', lastName: 'Иванов', firstName: 'Иван', personnelNumber: '12345' },
      { id: '2', lastName: 'Петрова', firstName: 'Анна', personnelNumber: '12346' }
    ];
    
    render(<EmployeeListBDD />);
    
    // Mock API response
    jest.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: true,
      json: async () => ({ employees: mockEmployees, total: 2 })
    } as Response);
    
    // Search by last name
    fireEvent.change(screen.getByPlaceholderText(/поиск/i), { target: { value: 'Иванов' } });
    
    await waitFor(() => {
      expect(screen.getByText('Иванов Иван')).toBeInTheDocument();
      expect(screen.queryByText('Петрова Анна')).not.toBeInTheDocument();
    });
  });
});
```

### **Form Validation Tests**:
```typescript
// File: __tests__/validation/EmployeeValidation.test.tsx
describe('Employee Form Validation Tests', () => {
  
  test('should require all mandatory fields', async () => {
    render(<EmployeeListBDD />);
    
    fireEvent.click(screen.getByText('Создать сотрудника'));
    fireEvent.click(screen.getByText('Создать сотрудника')); // Submit empty form
    
    await waitFor(() => {
      expect(screen.getByText('Обязательное поле')).toBeInTheDocument();
    });
  });
  
  test('should validate unique personnel number', async () => {
    const mockEmployees = [
      { id: '1', personnelNumber: '12345' }
    ];
    
    render(<EmployeeListBDD />);
    
    fireEvent.click(screen.getByText('Создать сотрудника'));
    fireEvent.change(screen.getByPlaceholderText('12345'), { target: { value: '12345' } });
    
    await waitFor(() => {
      expect(screen.getByText('Табельный номер должен быть уникальным')).toBeInTheDocument();
    });
  });
  
  test('should validate Cyrillic input in real-time', async () => {
    render(<EmployeeListBDD />);
    
    fireEvent.click(screen.getByText('Создать сотрудника'));
    fireEvent.change(screen.getByPlaceholderText('Иванов'), { target: { value: 'Smith' } });
    
    await waitFor(() => {
      expect(screen.getByText('Используйте только кириллические символы')).toBeInTheDocument();
    });
  });
});
```

---

## 📅 **SCHEDULE COMPONENT TEST SPECIFICATIONS**

### **Drag-and-Drop Tests**:
```typescript
// File: __tests__/components/ScheduleGridBDD.test.tsx
describe('Schedule Grid Drag-and-Drop Tests', () => {
  
  test('should support drag-and-drop shift movement', async () => {
    render(<ScheduleGridBDD />);
    
    const sourceShift = screen.getByTestId('shift-cell-0-5');
    const targetCell = screen.getByTestId('rest-cell-0-6');
    
    // Simulate drag and drop
    fireEvent.mouseDown(sourceShift);
    fireEvent.mouseEnter(targetCell);
    fireEvent.mouseUp(targetCell);
    
    await waitFor(() => {
      expect(targetCell).toHaveClass('work-shift');
      expect(sourceShift).toHaveClass('rest-day');
    });
  });
  
  test('should validate labor compliance during drag operations', async () => {
    render(<ScheduleGridBDD />);
    
    // Try to create violation: consecutive shifts without 11-hour rest
    const shift1 = screen.getByTestId('shift-cell-0-5');
    const adjacentCell = screen.getByTestId('cell-0-6');
    
    fireEvent.mouseDown(shift1);
    fireEvent.mouseEnter(adjacentCell);
    fireEvent.mouseUp(adjacentCell);
    
    await waitFor(() => {
      expect(screen.getByText(/нарушение норм/i)).toBeInTheDocument();
    });
  });
  
  test('should extend shift duration with drag', async () => {
    render(<ScheduleGridBDD />);
    
    const shiftEndHandle = screen.getByTestId('shift-end-handle-0-5');
    
    // Drag to extend shift by 2 hours
    fireEvent.mouseDown(shiftEndHandle);
    fireEvent.mouseMove(shiftEndHandle, { clientX: 100 }); // 2 hours = 100px
    fireEvent.mouseUp(shiftEndHandle);
    
    await waitFor(() => {
      expect(screen.getByText('10 часов')).toBeInTheDocument(); // Extended from 8 to 10 hours
    });
  });
});
```

### **Performance Standards Tests**:
```typescript
// File: __tests__/compliance/PerformanceStandards.test.tsx
describe('Performance Standards Compliance Tests', () => {
  
  test('should display exact BDD employee standards', () => {
    render(<ScheduleGridBDD />);
    
    // Verify exact BDD performance standards
    expect(screen.getByText('Иванов И.И.')).toBeInTheDocument();
    expect(screen.getByText('168')).toBeInTheDocument();  // Monthly hours
    expect(screen.getByText('Петров П.П.')).toBeInTheDocument();
    expect(screen.getByText('2080')).toBeInTheDocument(); // Annual hours
    expect(screen.getByText('Сидорова А.А.')).toBeInTheDocument();
    expect(screen.getByText('40')).toBeInTheDocument();   // Weekly hours
  });
  
  test('should calculate overtime based on performance standards', () => {
    const { calculateOvertime } = require('../../src/components/ScheduleGridBDD');
    
    const employee = {
      performanceStandard: { type: 'weekly', value: 40 }
    };
    
    expect(calculateOvertime(employee, 45)).toBe(5); // 5 hours overtime
    expect(calculateOvertime(employee, 40)).toBe(0); // No overtime
    expect(calculateOvertime(employee, 35)).toBe(0); // Under standard
  });
});
```

---

## 📱 **MOBILE COMPONENT TEST SPECIFICATIONS**

### **Offline Capability Tests**:
```typescript
// File: __tests__/components/MobilePersonalCabinetBDD.test.tsx
describe('Mobile Offline Capability Tests', () => {
  
  test('should detect offline status and update UI', async () => {
    render(<MobilePersonalCabinetBDD />);
    
    // Simulate going offline
    Object.defineProperty(navigator, 'onLine', { value: false, writable: true });
    window.dispatchEvent(new Event('offline'));
    
    await waitFor(() => {
      expect(screen.getByText('Автономный режим')).toBeInTheDocument();
      expect(screen.getByTestId('offline-icon')).toBeInTheDocument();
    });
  });
  
  test('should cache data for offline access', async () => {
    const { cacheScheduleData } = require('../../src/components/MobilePersonalCabinetBDD');
    
    const scheduleData = [
      { id: '1', date: '2025-07-15', startTime: '09:00', endTime: '18:00' }
    ];
    
    await cacheScheduleData(scheduleData);
    
    // Verify data is cached in IndexedDB/localStorage
    const cachedData = await getCachedScheduleData();
    expect(cachedData).toEqual(scheduleData);
  });
  
  test('should sync when connectivity restored', async () => {
    render(<MobilePersonalCabinetBDD />);
    
    // Start offline
    Object.defineProperty(navigator, 'onLine', { value: false, writable: true });
    
    // Go online
    Object.defineProperty(navigator, 'onLine', { value: true, writable: true });
    window.dispatchEvent(new Event('online'));
    
    await waitFor(() => {
      expect(screen.getByText('Синхронизация...')).toBeInTheDocument();
    });
    
    await waitFor(() => {
      expect(screen.getByText('В сети')).toBeInTheDocument();
    });
  });
});
```

### **Biometric Authentication Tests**:
```typescript
// File: __tests__/auth/BiometricAuth.test.tsx
describe('Biometric Authentication Tests', () => {
  
  test('should setup biometric authentication', async () => {
    // Mock WebAuthn API
    const mockCredential = {
      id: 'mock-credential-id',
      rawId: new ArrayBuffer(16),
      type: 'public-key'
    };
    
    Object.defineProperty(navigator, 'credentials', {
      value: {
        create: jest.fn().mockResolvedValue(mockCredential)
      }
    });
    
    render(<MobilePersonalCabinetBDD />);
    
    fireEvent.click(screen.getByText('Настройки'));
    fireEvent.click(screen.getByText(/биометрическая аутентификация/i));
    
    await waitFor(() => {
      expect(navigator.credentials.create).toHaveBeenCalledWith({
        publicKey: expect.objectContaining({
          challenge: expect.any(Uint8Array),
          rp: { name: 'WFM System' },
          authenticatorSelection: {
            authenticatorAttachment: 'platform',
            userVerification: 'required'
          }
        })
      });
    });
  });
  
  test('should handle biometric setup failure gracefully', async () => {
    Object.defineProperty(navigator, 'credentials', {
      value: {
        create: jest.fn().mockRejectedValue(new Error('Not supported'))
      }
    });
    
    render(<MobilePersonalCabinetBDD />);
    
    fireEvent.click(screen.getByText('Настройки'));
    fireEvent.click(screen.getByText(/биометрическая аутентификация/i));
    
    await waitFor(() => {
      expect(screen.getByText(/биометрия недоступна/i)).toBeInTheDocument();
    });
  });
});
```

---

## 📊 **COMPREHENSIVE BDD SCENARIO TESTS**

### **Cucumber Feature Tests**:
```gherkin
# File: __tests__/bdd/features/dashboard.feature
Feature: Real-time Monitoring Dashboard
  As a supervisor
  I want to view real-time operational metrics
  So that I can monitor call center performance

  Background:
    Given I am logged in as a supervisor
    And I have access to the monitoring dashboard

  @dashboard @real-time
  Scenario: View Six Key Metrics
    Given I navigate to the monitoring dashboard
    When I access the operational control page
    Then I should see six key real-time metrics:
      | Metric | Label | Update Frequency |
      | Operators Online % | Операторы онлайн % | 30 seconds |
      | Load Deviation | Отклонение нагрузки | 1 minute |
      | Operator Requirement | Требуется операторов | 1 minute |
      | SLA Performance | Производительность SLA | 1 minute |
      | ACD Rate | Коэффициент ACD | 30 seconds |
      | AHT Trend | Тренд AHT | 30 seconds |
    And each metric should display current value, trend arrow, and color coding
    And metrics should update automatically every 30 seconds
```

```typescript
// File: __tests__/bdd/step-definitions/dashboard.steps.ts
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';

Given('I am logged in as a supervisor', async function () {
  await this.page.goto('/login');
  await this.page.fill('[placeholder="Имя пользователя"]', 'supervisor');
  await this.page.fill('[placeholder="Пароль"]', 'SupervisorPass123!');
  await this.page.click('button:has-text("Войти")');
  await this.page.waitForSelector('text=Добро пожаловать');
});

When('I access the operational control page', async function () {
  await this.page.click('text=Мониторинг');
  await this.page.click('text=Операционный контроль');
  await this.page.waitForSelector('[data-testid="dashboard-metrics"]');
});

Then('I should see six key real-time metrics:', async function (dataTable) {
  const metrics = dataTable.hashes();
  
  for (const metric of metrics) {
    await expect(this.page.locator(`text=${metric.Label}`)).toBeVisible();
  }
});
```

### **Visual Regression Tests**:
```typescript
// File: __tests__/visual/ComponentVisuals.test.tsx
describe('Visual Regression Tests', () => {
  
  test('Dashboard should match Russian design specifications', async () => {
    await page.goto('/dashboard');
    await page.waitForSelector('[data-testid="dashboard-metrics"]');
    
    const screenshot = await page.screenshot({
      fullPage: true,
      animations: 'disabled'
    });
    
    expect(screenshot).toMatchSnapshot('dashboard-russian.png');
  });
  
  test('Employee list should display hierarchy correctly', async () => {
    await page.goto('/employees');
    await page.click('text=Создать сотрудника');
    
    const screenshot = await page.screenshot({
      clip: { x: 0, y: 0, width: 800, height: 600 }
    });
    
    expect(screenshot).toMatchSnapshot('employee-form-russian.png');
  });
  
  test('Mobile interface should be responsive', async () => {
    await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE
    await page.goto('/mobile');
    
    const screenshot = await page.screenshot({ fullPage: true });
    expect(screenshot).toMatchSnapshot('mobile-russian-iphone.png');
  });
});
```

---

## 🔄 **TEST AUTOMATION PIPELINE**

### **Continuous Integration Setup**:
```yaml
# File: .github/workflows/ui-testing.yml
name: UI Component Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v3
      
      - name: Start test API server
        run: |
          docker-compose -f docker-compose.test.yml up -d
          sleep 30
      
      - name: Run integration tests
        run: npm run test:integration

  bdd-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run BDD scenarios
        run: npm run test:bdd
      
      - name: Generate BDD report
        run: npm run test:bdd:report

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Playwright
        run: npx playwright install
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

### **Test Data Management**:
```typescript
// File: __tests__/fixtures/testData.ts
export const russianEmployeeFixtures = [
  {
    id: 'emp_001',
    lastName: 'Иванов',
    firstName: 'Иван', 
    patronymic: 'Иванович',
    personnelNumber: '12345',
    department: 'Колл-центр',
    position: 'Оператор',
    hireDate: '2025-01-01',
    timeZone: 'Europe/Moscow',
    performanceStandard: {
      type: 'monthly',
      value: 168,
      period: '2025'
    }
  },
  {
    id: 'emp_002', 
    lastName: 'Петров',
    firstName: 'Петр',
    patronymic: 'Петрович',
    personnelNumber: '12346',
    department: 'Техническая поддержка',
    position: 'Супервизор',
    hireDate: '2024-12-15',
    timeZone: 'Europe/Moscow',
    performanceStandard: {
      type: 'annual',
      value: 2080,
      period: '2025'
    }
  }
];

export const dashboardMetricsFixtures = {
  normal: {
    operators_online_percent: { value: 85.3, color: 'green' },
    load_deviation: { value: -8.2, color: 'green' },
    sla_performance: { value: 79.8, color: 'green' }
  },
  warning: {
    operators_online_percent: { value: 75.0, color: 'yellow' },
    load_deviation: { value: 15.0, color: 'yellow' },
    sla_performance: { value: 73.0, color: 'yellow' }
  },
  critical: {
    operators_online_percent: { value: 65.0, color: 'red' },
    load_deviation: { value: 25.0, color: 'red' },
    sla_performance: { value: 65.0, color: 'red' }
  }
};
```

---

## 📈 **TEST METRICS AND REPORTING**

### **Coverage Requirements**:
```typescript
interface CoverageTargets {
  statements: 85;     // 85% statement coverage
  branches: 80;       // 80% branch coverage  
  functions: 90;      // 90% function coverage
  lines: 85;          // 85% line coverage
  
  // BDD scenario coverage
  bddScenarios: 100;  // 100% of BDD scenarios tested
  
  // Component-specific targets
  components: {
    Login: { statements: 90, bdd: 100 };
    Dashboard: { statements: 85, bdd: 100 };
    Employee: { statements: 85, bdd: 100 };
    Schedule: { statements: 80, bdd: 100 };
    Mobile: { statements: 85, bdd: 100 };
  };
}
```

### **Test Reporting Dashboard**:
```typescript
interface TestReportingConfig {
  reporters: [
    'jest-html-reporter',
    'jest-junit',
    '@cucumber/pretty-formatter',
    'allure-playwright'
  ];
  
  outputs: {
    unitTests: 'test-results/unit/';
    integrationTests: 'test-results/integration/';
    bddTests: 'test-results/bdd/';
    e2eTests: 'test-results/e2e/';
    coverage: 'coverage/';
    visualRegression: 'visual-tests/';
  };
  
  notifications: {
    slack: process.env.SLACK_WEBHOOK;
    email: ['dev-team@company.com'];
    onFailure: true;
    onSuccess: false;
    onCoverageBelow: 80;
  };
}
```

---

## 🚀 **PRODUCTION READINESS CHECKLIST**

### **Pre-Release Testing Checklist**:
```typescript
interface ProductionReadinessChecklist {
  unitTests: {
    coverage: "✅ >85% statement coverage achieved";
    russian: "✅ All Russian text elements tested";
    validation: "✅ Cyrillic validation patterns verified";
    performance: "✅ Component render times <2s";
  };
  
  integrationTests: {
    apis: "✅ All API endpoints tested with real responses";
    errorHandling: "✅ Network failures handled gracefully";
    authentication: "✅ JWT and biometric auth flows verified";
    dataFlow: "✅ Component data transformations tested";
  };
  
  bddTests: {
    scenarios: "✅ 100% BDD scenario coverage achieved";
    userJourneys: "✅ Complete user workflows tested";
    compliance: "✅ Labor law compliance validated";
    localization: "✅ Russian language requirements met";
  };
  
  e2eTests: {
    criticalPaths: "✅ Login → Dashboard → Employee → Schedule flows";
    browserSupport: "✅ Chrome, Firefox, Safari, Edge tested";
    mobileDevices: "✅ iOS, Android responsive design verified";
    accessibility: "✅ WCAG 2.1 AA compliance validated";
  };
  
  performanceTests: {
    loadTimes: "✅ All components load <3s on 3G";
    memoryUsage: "✅ No memory leaks detected";
    renderPerformance: "✅ 60fps interactions maintained";
    apiResponseTimes: "✅ <2s for data operations";
  };
}
```

---

**This comprehensive test specification ensures that all 5 BDD-compliant UI components meet production quality standards through systematic testing at unit, integration, BDD scenario, and end-to-end levels, with specific focus on Russian localization and labor compliance requirements.**