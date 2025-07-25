# BDD-CLAUDE.md - BDD Specifications Index

## Current Status
- **Total Features**: 36 feature files
- **Total Scenarios**: 580 scenarios
- **Coverage**: 99%+ of Argus features
- **Russian Market**: Fully adapted

## BDD File Index

### Core Business Features
```
Employee Management & Requests:
├── 02-employee-management-structure.feature (13 scenarios)
├── 04-employee-request-submission.feature (19 scenarios)
├── 05-request-approval-workflow.feature (18 scenarios)
└── 16-reference-data-management.feature (15 scenarios)
```

### Planning & Scheduling
```
Schedule & Planning:
├── 09-work-schedule-vacation-planning.feature (23 scenarios)
├── 31-work-schedule-planning-with-vacations.feature (18 scenarios)
├── 07-labor-standards-configuration.feature (13 scenarios)
├── 08-load-forecasting-demand-planning.feature (23 scenarios)
├── 30-load-forecasting-additional.feature (15 scenarios)
└── 10-monthly-intraday-activity-planning.feature (22 scenarios)
```

### System Features
```
System Administration:
├── 18-system-administration-configuration.feature (46 scenarios)
├── 11-system-integration-api-management.feature (40 scenarios)
├── 21-1c-zup-integration.feature (43 scenarios)
├── 22-cross-system-integration.feature (27 scenarios)
└── 17-reference-data-management.feature (18 scenarios)
```

### Advanced Features
```
Advanced Functionality:
├── 24-automatic-schedule-optimization.feature (21 scenarios)
├── 27-vacancy-planning-module.feature (25 scenarios)
├── 19-planning-module-detailed-workflows.feature (36 scenarios)
├── 23-comprehensive-reporting-system.feature (32 scenarios)
└── 15-realtime-monitoring-operational-control.feature (18 scenarios)
```

## Coverage Tracking

### Implementation Status
```
✅ Complete (100%):
- Employee Management
- Request Workflows  
- Labor Standards
- Forecasting
- System Admin
- 1C Integration

⚠️ Partial (80-99%):
- Vacation Planning (missing schema types)
- Mobile Features (basic implementation)
- Cross-system Sync (OKK pending)

❌ Gaps (<80%):
- Service Level Format (X/Y not %)
- Schedule Types (15 of 50 implemented)
```

## Quick Navigation Guide

### By Use Case

**For Managers:**
- Forecasting: Files 08, 22, 30
- Scheduling: Files 09, 24, 31
- Reports: Files 12, 23

**For Employees:**
- Requests: Files 04, 05
- Mobile: File 14
- Schedule View: File 09

**For Admins:**
- System Config: File 18
- Integration: Files 11, 21, 22
- Reference Data: Files 16, 17

**For Planners:**
- Planning: Files 19, 10
- Optimization: File 24
- Vacancy: File 27

## Key Commands

### Search BDD Files
```bash
# Find all scenarios for employee requests
grep -n "Scenario:" *employee*.feature

# Count scenarios per file
for f in *.feature; do echo "$f: $(grep -c "Scenario:" $f)"; done

# Find specific requirement
grep -r "shift exchange" *.feature
```

### Validate Coverage
```bash
# Check implementation status
python validate_bdd_coverage.py

# Generate coverage report
python generate_bdd_report.py > coverage.html

# Find missing scenarios
python find_gaps.py --compare-with /project/src
```

## Next Priorities

1. **Fix Service Level Format**
   - Change from "95%" to "20/80"
   - Update all relevant scenarios

2. **Expand Schedule Types**
   - Current: 15 types
   - Required: 50+ types
   - Add manufacturing patterns

3. **Complete Mobile Scenarios**
   - Offline sync
   - Push notifications
   - Biometric auth

## Known Issues

1. **Translation**: Some Russian terms remain
2. **Versioning**: No version tags on features
3. **Dependencies**: Cross-feature dependencies undocumented
4. **Examples**: Some scenarios lack concrete examples

## BDD Best Practices

### Scenario Structure
```gherkin
Feature: Clear business value statement
  As a [role]
  I want [feature]
  So that [benefit]

  Background:
    Given common setup

  Scenario: Specific test case
    Given initial state
    When action performed
    Then expected outcome
    And additional verification
```

### Tagging Strategy
```gherkin
@core @employee @mobile
Scenario: Tagged for categorization
```

## Integration Points

- **Database**: Each feature maps to schemas
- **API**: Scenarios define endpoints
- **UI**: User journeys in features
- **Algorithms**: Business rules in scenarios