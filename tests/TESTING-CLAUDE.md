# TESTING-CLAUDE.md - Testing Framework Documentation

## Current Status
- **Test Categories**: 11 test suites
- **Coverage**: API 85%, Algorithms 90%, Database 80%, UI 23%
- **Test Execution**: Automated CI/CD pipeline
- **Performance Tests**: Load, stress, and endurance ready

## Test Coverage Report

### By Category
```
tests/
├── algorithms/     # 90% coverage - All core algorithms tested
├── api/           # 85% coverage - Most endpoints tested
├── bdd/           # 10% coverage - Needs implementation
├── database/      # 80% coverage - Schema and procedures tested
├── demo_scenarios/# 100% ready - All demos validated
├── e2e/          # 60% coverage - Critical paths tested
├── integration/   # 75% coverage - System integration tests
├── load/         # 100% ready - Load test scenarios
├── performance/   # 100% ready - Performance benchmarks
├── unit/         # 70% coverage - Core logic tested
└── websocket/    # 80% coverage - Real-time features tested
```

## Missing Test Areas

### Critical Gaps
1. **BDD Tests** (10% only)
   - Need Cucumber implementation
   - Step definitions missing
   - Feature file mapping incomplete

2. **UI Tests** (23% only)
   - Component tests needed
   - E2E scenarios incomplete
   - Visual regression missing

3. **Security Tests** (0%)
   - Penetration testing needed
   - OWASP compliance checks
   - Authentication edge cases

### Medium Priority
4. **Integration Tests**
   - 1C:ZUP integration incomplete
   - Argus compatibility gaps
   - Webhook reliability tests

5. **Mobile Tests**
   - Responsive design validation
   - Touch interaction tests
   - Offline mode scenarios

## Test Execution Guide

### Running All Tests
```bash
# Run full test suite
cd /project/tests
pytest -v

# Run with coverage
pytest --cov=src --cov-report=html

# Parallel execution
pytest -n 4
```

### Category-Specific Tests
```bash
# Algorithm tests only
pytest algorithms/ -v

# API tests with markers
pytest api/ -m "not slow"

# Database tests
pytest database/ --database=test_wfm

# Load tests
locust -f load/load_test.py --host=http://localhost:8000
```

### Performance Tests
```bash
# Benchmark algorithms
python performance/benchmark_suite.py

# API performance
python performance/api_performance.py --concurrent=100

# Database performance
python performance/db_performance.py --records=1000000
```

## Key Commands

### Test Management
```bash
# Create new test
python create_test.py --type unit --name test_new_feature

# Run specific test
pytest path/to/test.py::TestClass::test_method

# Debug failing test
pytest --pdb --lf

# Generate test report
pytest --html=report.html --self-contained-html
```

### Coverage Analysis
```bash
# Generate coverage report
coverage run -m pytest
coverage html
open htmlcov/index.html

# Check specific module
coverage run -m pytest src/algorithms
coverage report -m src/algorithms/*
```

### Load Testing
```bash
# Start load test UI
locust -f load/scenarios.py --web-host=0.0.0.0

# Headless load test
locust -f load/scenarios.py --headless -u 1000 -r 100 -t 5m

# Distributed load test
locust -f load/scenarios.py --master
locust -f load/scenarios.py --worker --master-host=localhost
```

## Next Priorities

1. **BDD Implementation**
   - Set up Cucumber framework
   - Map features to tests
   - Create step definitions
   - Achieve 80% BDD coverage

2. **UI Test Automation**
   - Implement Cypress/Playwright
   - Component testing with React Testing Library
   - Visual regression with Percy
   - Accessibility testing

3. **Security Testing**
   - OWASP ZAP integration
   - SQL injection tests
   - XSS prevention validation
   - Authentication fuzzing

4. **CI/CD Enhancement**
   - Parallel test execution
   - Test result trending
   - Automatic reruns for flaky tests
   - Performance regression detection

## Known Issues

1. **Flaky Tests**: WebSocket tests intermittently fail
2. **Test Data**: Cleanup between tests needs improvement
3. **Performance**: Full suite takes 45 minutes
4. **Dependencies**: Some tests require specific services running

## Test Standards

### Test Structure
```python
def test_feature_description():
    """Test that feature works correctly.
    
    Given: Initial state
    When: Action performed
    Then: Expected outcome
    """
    # Arrange
    initial_state = setup_test_data()
    
    # Act
    result = perform_action(initial_state)
    
    # Assert
    assert result.status == "success"
    assert result.value == expected_value
```

### Test Naming
- `test_<feature>_<scenario>_<expected_result>`
- Use descriptive names
- Include ticket/BDD reference

### Test Data
- Use factories for consistency
- Clean up after tests
- Avoid hardcoded values
- Use realistic data

## Quick Test Scenarios

### Smoke Test (5 min)
```bash
pytest -m smoke --maxfail=1
```

### Regression Test (30 min)
```bash
pytest -m "not slow" --parallel
```

### Full Test (45 min)
```bash
pytest --cov=src
```

### Performance Test (15 min)
```bash
python performance/quick_benchmark.py
```