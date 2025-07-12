# WFM Enterprise Testing Guide

## Overview

This guide provides comprehensive documentation for the WFM Enterprise testing framework, covering unit tests, integration tests, end-to-end tests, and BDD test implementations.

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Test Structure](#test-structure)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [End-to-End Testing](#end-to-end-testing)
6. [BDD Testing](#bdd-testing)
7. [Performance Testing](#performance-testing)
8. [Running Tests](#running-tests)
9. [Best Practices](#best-practices)

## Testing Strategy

### Test Pyramid

```
         /\
        /  \
       / E2E \      <- End-to-End Tests (Cypress)
      /______\
     /        \
    /Integration\   <- API & Integration Tests
   /____________\
  /              \
 /   Unit Tests   \ <- Component & Function Tests
/________________\
```

### Coverage Goals

- Unit Tests: 80% code coverage
- Integration Tests: All critical API endpoints
- E2E Tests: Critical user journeys
- BDD Tests: All business requirements

## Test Structure

```
main/project/tests/
├── unit/                    # Unit tests
│   ├── backend/            # Python unit tests
│   │   ├── algorithms/
│   │   ├── api/
│   │   └── utils/
│   └── frontend/           # React/TypeScript tests
│       ├── components/
│       ├── hooks/
│       └── utils/
├── integration/            # Integration tests
│   ├── api/               # API integration tests
│   ├── database/          # Database integration tests
│   └── websocket/         # WebSocket tests
├── e2e/                   # End-to-end tests
│   ├── cypress/
│   │   ├── fixtures/
│   │   ├── integration/
│   │   └── support/
│   └── scenarios/
├── bdd/                   # BDD tests
│   ├── features/          # Feature files
│   ├── step_definitions/  # Step implementations
│   └── support/           # BDD utilities
├── performance/           # Performance tests
│   ├── load/             # Load tests
│   └── stress/           # Stress tests
└── fixtures/             # Test data
    ├── sample_data/
    └── mock_data/
```

## Unit Testing

### Python Unit Tests (pytest)

#### Basic Test Example

```python
# tests/unit/backend/algorithms/test_erlang_c.py
import pytest
from src.algorithms.erlang_c import ErlangCCalculator

class TestErlangCCalculator:
    def test_calculate_basic(self):
        calculator = ErlangCCalculator()
        result = calculator.calculate(
            call_volume=100,
            average_handle_time=300,
            service_level_target=0.8,
            service_level_seconds=20
        )
        assert result['required_agents'] > 0
        assert result['service_level'] >= 0.8

    @pytest.mark.parametrize("call_volume,aht,expected_min", [
        (50, 180, 5),
        (100, 300, 10),
        (200, 240, 15),
    ])
    def test_various_scenarios(self, call_volume, aht, expected_min):
        calculator = ErlangCCalculator()
        result = calculator.calculate(call_volume, aht, 0.8, 20)
        assert result['required_agents'] >= expected_min

    def test_edge_cases(self):
        calculator = ErlangCCalculator()
        with pytest.raises(ValueError):
            calculator.calculate(-1, 300, 0.8, 20)
```

#### Testing Async Functions

```python
# tests/unit/backend/api/test_schedule_service.py
import pytest
from unittest.mock import AsyncMock, Mock
from src.services.schedule_service import ScheduleService

@pytest.mark.asyncio
async def test_create_schedule():
    # Mock dependencies
    mock_db = AsyncMock()
    mock_algorithm = Mock()
    mock_algorithm.generate_schedule.return_value = {
        'schedule': [...],
        'metrics': {...}
    }
    
    service = ScheduleService(mock_db, mock_algorithm)
    
    result = await service.create_schedule({
        'start_date': '2024-01-01',
        'end_date': '2024-01-07',
        'employees': [1, 2, 3]
    })
    
    assert result['status'] == 'success'
    mock_db.save_schedule.assert_called_once()
```

### React/TypeScript Unit Tests (Jest + React Testing Library)

#### Component Test Example

```typescript
// tests/unit/frontend/components/ScheduleGrid.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { ScheduleGrid } from '@/components/ScheduleGrid';
import { mockScheduleData } from '@/tests/fixtures/scheduleData';

describe('ScheduleGrid', () => {
  it('renders schedule data correctly', () => {
    render(<ScheduleGrid data={mockScheduleData} />);
    
    expect(screen.getByText('Monday')).toBeInTheDocument();
    expect(screen.getByText('Employee 1')).toBeInTheDocument();
    expect(screen.getAllByText('08:00-16:00')).toHaveLength(5);
  });

  it('handles cell click events', () => {
    const handleCellClick = jest.fn();
    render(
      <ScheduleGrid 
        data={mockScheduleData} 
        onCellClick={handleCellClick}
      />
    );
    
    const cell = screen.getByTestId('schedule-cell-1-monday');
    fireEvent.click(cell);
    
    expect(handleCellClick).toHaveBeenCalledWith({
      employeeId: 1,
      day: 'monday',
      shift: '08:00-16:00'
    });
  });

  it('highlights conflicts', () => {
    const dataWithConflicts = {
      ...mockScheduleData,
      conflicts: [{ employeeId: 1, day: 'monday' }]
    };
    
    render(<ScheduleGrid data={dataWithConflicts} />);
    
    const conflictCell = screen.getByTestId('schedule-cell-1-monday');
    expect(conflictCell).toHaveClass('bg-red-100');
  });
});
```

#### Hook Test Example

```typescript
// tests/unit/frontend/hooks/useSchedule.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useSchedule } from '@/hooks/useSchedule';
import { mockApiClient } from '@/tests/mocks/apiClient';

jest.mock('@/api/client', () => ({
  apiClient: mockApiClient
}));

describe('useSchedule', () => {
  it('fetches schedule data on mount', async () => {
    const { result } = renderHook(() => useSchedule('2024-01-01'));
    
    expect(result.current.loading).toBe(true);
    
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
      expect(result.current.data).toEqual(mockScheduleData);
    });
  });

  it('handles errors gracefully', async () => {
    mockApiClient.getSchedule.mockRejectedValueOnce(new Error('Network error'));
    
    const { result } = renderHook(() => useSchedule('2024-01-01'));
    
    await waitFor(() => {
      expect(result.current.error).toBe('Failed to load schedule');
      expect(result.current.data).toBeNull();
    });
  });
});
```

## Integration Testing

### API Integration Tests

```python
# tests/integration/api/test_employee_endpoints.py
import pytest
from httpx import AsyncClient
from src.main import app
from tests.fixtures.test_data import create_test_employee

@pytest.mark.asyncio
async def test_employee_crud_flow():
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create employee
        employee_data = create_test_employee()
        response = await client.post("/api/employees", json=employee_data)
        assert response.status_code == 201
        employee_id = response.json()["id"]
        
        # Read employee
        response = await client.get(f"/api/employees/{employee_id}")
        assert response.status_code == 200
        assert response.json()["name"] == employee_data["name"]
        
        # Update employee
        update_data = {"skills": ["skill1", "skill2"]}
        response = await client.patch(
            f"/api/employees/{employee_id}", 
            json=update_data
        )
        assert response.status_code == 200
        
        # Delete employee
        response = await client.delete(f"/api/employees/{employee_id}")
        assert response.status_code == 204
```

### Database Integration Tests

```python
# tests/integration/database/test_schedule_repository.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from src.repositories.schedule_repository import ScheduleRepository
from tests.fixtures.database import test_database_url

@pytest.mark.asyncio
async def test_schedule_cascade_operations():
    engine = create_async_engine(test_database_url)
    async with AsyncSession(engine) as session:
        repo = ScheduleRepository(session)
        
        # Create schedule with shifts
        schedule = await repo.create_schedule_with_shifts({
            'name': 'Test Schedule',
            'start_date': '2024-01-01',
            'end_date': '2024-01-07',
            'shifts': [
                {'employee_id': 1, 'date': '2024-01-01', 'start': '08:00', 'end': '16:00'},
                {'employee_id': 2, 'date': '2024-01-01', 'start': '16:00', 'end': '00:00'}
            ]
        })
        
        # Verify cascade delete
        await repo.delete_schedule(schedule.id)
        shifts = await repo.get_shifts_by_schedule(schedule.id)
        assert len(shifts) == 0
```

## End-to-End Testing

### Cypress Configuration

```javascript
// cypress.config.js
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    supportFile: 'tests/e2e/cypress/support/index.js',
    specPattern: 'tests/e2e/cypress/integration/**/*.cy.{js,jsx,ts,tsx}',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true,
    env: {
      apiUrl: 'http://localhost:8000',
      coverage: true
    },
    setupNodeEvents(on, config) {
      // Implement code coverage
      require('@cypress/code-coverage/task')(on, config);
      
      // Custom tasks
      on('task', {
        'db:seed': () => {
          // Seed test database
          return null;
        },
        'db:cleanup': () => {
          // Cleanup test data
          return null;
        }
      });
      
      return config;
    }
  }
});
```

### E2E Test Example

```typescript
// tests/e2e/cypress/integration/schedule-management.cy.ts
describe('Schedule Management', () => {
  beforeEach(() => {
    cy.task('db:seed');
    cy.login('admin@test.com', 'password');
  });

  afterEach(() => {
    cy.task('db:cleanup');
  });

  it('creates a new schedule', () => {
    cy.visit('/schedules');
    cy.get('[data-cy=create-schedule-btn]').click();
    
    // Fill schedule form
    cy.get('[data-cy=schedule-name]').type('January Week 1');
    cy.get('[data-cy=start-date]').type('2024-01-01');
    cy.get('[data-cy=end-date]').type('2024-01-07');
    
    // Select employees
    cy.get('[data-cy=employee-select]').click();
    cy.get('[data-cy=employee-option-1]').click();
    cy.get('[data-cy=employee-option-2]').click();
    cy.get('[data-cy=employee-option-3]').click();
    
    // Generate schedule
    cy.get('[data-cy=generate-btn]').click();
    
    // Verify schedule created
    cy.get('[data-cy=schedule-grid]').should('be.visible');
    cy.get('[data-cy=schedule-cell]').should('have.length.greaterThan', 0);
    
    // Save schedule
    cy.get('[data-cy=save-schedule-btn]').click();
    cy.get('[data-cy=success-toast]').should('contain', 'Schedule saved successfully');
  });

  it('handles shift conflicts', () => {
    cy.visit('/schedules/1/edit');
    
    // Create conflicting shift
    cy.get('[data-cy=shift-cell-1-monday]').click();
    cy.get('[data-cy=shift-time-start]').clear().type('08:00');
    cy.get('[data-cy=shift-time-end]').clear().type('20:00');
    cy.get('[data-cy=save-shift]').click();
    
    // Try to create overlapping shift
    cy.get('[data-cy=shift-cell-1-monday-evening]').click();
    cy.get('[data-cy=shift-time-start]').type('16:00');
    cy.get('[data-cy=shift-time-end]').type('00:00');
    cy.get('[data-cy=save-shift]').click();
    
    // Verify conflict warning
    cy.get('[data-cy=conflict-warning]').should('be.visible');
    cy.get('[data-cy=conflict-warning]').should('contain', 'Shift overlap detected');
  });
});
```

## BDD Testing

### Python BDD with pytest-bdd

```python
# tests/bdd/step_definitions/test_employee_requests.py
import pytest
from pytest_bdd import scenarios, given, when, then, parsers
from src.services.request_service import RequestService

scenarios('../features/employee-requests.feature')

@pytest.fixture
def request_service():
    return RequestService()

@given('an employee with ID <employee_id>')
def employee_exists(employee_id):
    # Setup employee in test database
    return {'id': employee_id, 'name': 'Test Employee'}

@when('the employee creates a vacation request from <start_date> to <end_date>')
def create_vacation_request(request_service, employee_id, start_date, end_date):
    return request_service.create_request({
        'employee_id': employee_id,
        'type': 'vacation',
        'start_date': start_date,
        'end_date': end_date
    })

@then('the request should be created with status "pending"')
def verify_request_created(create_vacation_request):
    assert create_vacation_request['status'] == 'pending'
    assert create_vacation_request['id'] is not None

@then('the request should require manager approval')
def verify_approval_required(create_vacation_request):
    assert create_vacation_request['requires_approval'] is True
    assert create_vacation_request['approver_id'] is not None
```

### JavaScript BDD with Cucumber

```javascript
// tests/bdd/step_definitions/schedule.steps.js
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from 'chai';
import { SchedulePage } from '../support/pages/SchedulePage';

let schedulePage;

Given('I am logged in as a manager', async function() {
  await this.page.goto('/login');
  await this.page.fill('[data-cy=email]', 'manager@test.com');
  await this.page.fill('[data-cy=password]', 'password');
  await this.page.click('[data-cy=login-btn]');
  await this.page.waitForSelector('[data-cy=dashboard]');
});

When('I navigate to the schedule page', async function() {
  schedulePage = new SchedulePage(this.page);
  await schedulePage.navigate();
});

When('I create a schedule for {string} with {int} employees', async function(week, employeeCount) {
  await schedulePage.createSchedule(week, employeeCount);
});

Then('I should see a generated schedule with optimal coverage', async function() {
  const schedule = await schedulePage.getScheduleData();
  expect(schedule.shifts).to.have.length.greaterThan(0);
  expect(schedule.coverage).to.satisfy(coverage => 
    Object.values(coverage).every(value => value >= 0.8)
  );
});
```

## Performance Testing

### Load Testing with Locust

```python
# tests/performance/load/locustfile.py
from locust import HttpUser, task, between
import json

class WFMUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login
        response = self.client.post("/api/auth/login", json={
            "email": "test@example.com",
            "password": "password"
        })
        self.token = response.json()["access_token"]
        self.client.headers.update({"Authorization": f"Bearer {self.token}"})
    
    @task(3)
    def view_schedule(self):
        self.client.get("/api/schedules/current")
    
    @task(2)
    def view_employee_list(self):
        self.client.get("/api/employees")
    
    @task(1)
    def create_request(self):
        self.client.post("/api/requests", json={
            "type": "shift_swap",
            "date": "2024-01-15",
            "reason": "Personal appointment"
        })
    
    @task(1)
    def run_forecast(self):
        with self.client.post(
            "/api/forecasts/generate",
            json={
                "start_date": "2024-01-01",
                "end_date": "2024-01-31",
                "skill_groups": ["sales", "support"]
            },
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 5:
                response.failure("Forecast generation too slow")
```

## Running Tests

### Command Line Interface

```bash
# Run all tests
make test

# Run specific test suites
make test-unit          # Unit tests only
make test-integration   # Integration tests only
make test-e2e          # End-to-end tests only
make test-bdd          # BDD tests only
make test-performance  # Performance tests

# Run with coverage
make test-coverage

# Run specific test files
pytest tests/unit/backend/algorithms/test_erlang_c.py
npm test -- ScheduleGrid.test.tsx

# Run tests in watch mode
pytest-watch tests/unit
npm test -- --watch

# Run with specific markers
pytest -m "not slow"
pytest -m "critical"
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      - name: Run backend tests
        run: |
          pytest tests/unit/backend --cov=src --cov-report=xml
          pytest tests/integration -m "not slow"
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
      - name: Run frontend tests
        run: |
          npm test -- --coverage
          npm run lint

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run E2E tests
        run: |
          docker-compose up -d
          npm run test:e2e
      - name: Upload screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: cypress-screenshots
          path: tests/e2e/cypress/screenshots
```

## Best Practices

### Test Organization

1. **Naming Conventions**
   - Test files: `test_*.py` or `*.test.ts`
   - Test classes: `Test<ClassName>`
   - Test methods: `test_<what_it_does>`
   - BDD features: `<feature-name>.feature`

2. **Test Independence**
   - Each test should be independent
   - Use fixtures for test data
   - Clean up after tests
   - Avoid test order dependencies

3. **Test Data Management**
   ```python
   # tests/fixtures/factories.py
   from dataclasses import dataclass
   from datetime import datetime
   import factory

   @dataclass
   class Employee:
       id: int
       name: str
       skills: list[str]
       hire_date: datetime

   class EmployeeFactory(factory.Factory):
       class Meta:
           model = Employee
       
       id = factory.Sequence(lambda n: n)
       name = factory.Faker('name')
       skills = factory.List([
           factory.Faker('job'),
           factory.Faker('job')
       ])
       hire_date = factory.Faker('date_this_year')
   ```

4. **Mocking Best Practices**
   ```python
   # Use dependency injection
   class ScheduleService:
       def __init__(self, db, algorithm_engine, notification_service):
           self.db = db
           self.algorithm_engine = algorithm_engine
           self.notification_service = notification_service
   
   # Easy to mock in tests
   mock_db = Mock()
   mock_algorithm = Mock()
   mock_notifier = Mock()
   service = ScheduleService(mock_db, mock_algorithm, mock_notifier)
   ```

5. **Assertion Guidelines**
   - One logical assertion per test
   - Use descriptive assertion messages
   - Test both positive and negative cases
   - Test edge cases and error conditions

6. **Performance Considerations**
   - Mark slow tests: `@pytest.mark.slow`
   - Use test databases with minimal data
   - Mock external services
   - Parallelize test execution

### Coverage Requirements

1. **Unit Tests**
   - All business logic functions
   - All utility functions
   - All API endpoints
   - All React components

2. **Integration Tests**
   - Database operations
   - API endpoint integration
   - WebSocket connections
   - External service integration

3. **E2E Tests**
   - Critical user journeys
   - Cross-browser compatibility
   - Mobile responsiveness
   - Error scenarios

4. **BDD Tests**
   - All user stories
   - Business requirements
   - Acceptance criteria
   - Edge cases from specifications

## Troubleshooting

### Common Issues

1. **Flaky Tests**
   - Add explicit waits for async operations
   - Use stable selectors
   - Mock time-dependent functions
   - Increase timeout values for CI

2. **Database State**
   - Use transactions and rollback
   - Create fresh test databases
   - Use database fixtures
   - Clear cache between tests

3. **Network Issues**
   - Mock external API calls
   - Use local test servers
   - Implement retry logic
   - Set appropriate timeouts

### Debug Helpers

```python
# tests/helpers/debug.py
import json
import pprint

def debug_response(response):
    """Helper to debug API responses"""
    print(f"Status: {response.status_code}")
    print(f"Headers: {dict(response.headers)}")
    try:
        body = response.json()
        print("Body:")
        pprint.pprint(body)
    except:
        print(f"Body: {response.text}")

def save_test_artifact(data, filename):
    """Save test data for debugging"""
    with open(f"tests/artifacts/{filename}", 'w') as f:
        json.dump(data, f, indent=2)
```

## Resources

- [pytest documentation](https://docs.pytest.org/)
- [Jest documentation](https://jestjs.io/)
- [Cypress documentation](https://docs.cypress.io/)
- [pytest-bdd documentation](https://pytest-bdd.readthedocs.io/)
- [Testing Library documentation](https://testing-library.com/)