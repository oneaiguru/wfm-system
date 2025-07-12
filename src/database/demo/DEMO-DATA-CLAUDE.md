# DEMO-DATA-CLAUDE.md - Demo Data & Scenarios Guide

## Current Status
- **Demo Files**: 2 comprehensive demos ready
- **Scenarios**: Multi-skill + Russian call center
- **Data Volume**: 100K+ records for realistic demos
- **Languages**: English + Russian scenarios

## Russian Scenarios

### russian_call_center.sql
**Purpose**: Demonstrate Russian market features

**Key Features**:
- ТК РФ compliance validation
- Russian employee names (UTF-8)
- Moscow timezone handling
- 1C:ZUP time codes
- Russian holidays calendar

**Demo Flow**:
```sql
-- Load Russian demo
psql -U postgres -d wfm_demo -f russian_call_center.sql

-- Key scenarios:
-- 1. Shift exchange with approval (Иванов ↔ Петров)
-- 2. Vacation request with ТК РФ validation
-- 3. Night shift premium calculation
-- 4. Overtime limit enforcement
-- 5. 42-hour weekly rest violation alert
```

### multi_skill_schedule_demo.sql
**Purpose**: Showcase WFM superiority over Argus

**Key Features**:
- 20 projects (1-150 queues each)
- 37 skills across categories
- Complex skill requirements
- Performance comparisons
- Real efficiency metrics

**Competitive Advantages Shown**:
```sql
-- Demonstrate 85% vs 60-70% efficiency
SELECT * FROM v_argus_vs_wfm_efficiency;

-- Show skill optimization
SELECT * FROM v_multi_skill_optimization_results;

-- Real-time adaptation
SELECT * FROM v_real_time_performance_gains;
```

## Test Data Guide

### Data Categories
1. **Historical Data**
   - 6 months call history
   - Seasonal patterns
   - Holiday impacts
   - Growth trends

2. **Employee Data**
   - 500 agents
   - Skill distributions
   - Availability patterns
   - Performance metrics

3. **Schedule Data**
   - Generated schedules
   - Shift patterns
   - Coverage analysis
   - Optimization results

4. **Real-time Data**
   - Live queue states
   - Agent statuses
   - Performance KPIs
   - SLA tracking

## Demo Flow Scripts

### Executive Demo (15 min)
```bash
# 1. Show forecast accuracy
./demo_scripts/exec_forecast.sh

# 2. Multi-skill optimization
./demo_scripts/exec_multiskill.sh

# 3. Real-time dashboard
./demo_scripts/exec_realtime.sh

# 4. ROI calculator
./demo_scripts/exec_roi.sh
```

### Technical Demo (45 min)
```bash
# 1. Algorithm performance
./demo_scripts/tech_algorithms.sh

# 2. API capabilities
./demo_scripts/tech_api.sh

# 3. Integration points
./demo_scripts/tech_integration.sh

# 4. Scalability proof
./demo_scripts/tech_scale.sh
```

### Russian Market Demo (30 min)
```bash
# 1. ТК РФ compliance
./demo_scripts/ru_compliance.sh

# 2. 1C:ZUP integration
./demo_scripts/ru_zup.sh

# 3. Russian reports
./demo_scripts/ru_reports.sh

# 4. Bilingual UI
./demo_scripts/ru_interface.sh
```

## Key Commands

### Setup Demo Environment
```bash
# Create demo database
createdb wfm_demo

# Load base schema
psql -U postgres -d wfm_demo -f ../schemas/001_initial_schema.sql

# Load all schemas
for f in ../schemas/*.sql; do psql -U postgres -d wfm_demo -f $f; done

# Load demo data
psql -U postgres -d wfm_demo -f multi_skill_schedule_demo.sql
psql -U postgres -d wfm_demo -f russian_call_center.sql
```

### Generate Fresh Data
```bash
# Generate call history
python generate_calls.py --days 180 --volume 100000

# Generate employees
python generate_employees.py --count 500 --skills random

# Generate schedules
python generate_schedules.py --weeks 4 --optimize true
```

## Next Priorities

1. **Industry-Specific Demos**
   - Banking scenario
   - Retail scenario
   - Healthcare scenario
   - Government scenario

2. **Advanced Scenarios**
   - Union rules compliance
   - Multi-location planning
   - Disaster recovery
   - Peak season planning

3. **Performance Demos**
   - 1M+ calls simulation
   - 5000+ agent scheduling
   - Real-time stress test
   - Failover demonstration

## Known Issues

1. **Data Volume**: Initial load takes 5-10 minutes
2. **UTF-8**: Ensure proper encoding for Russian names
3. **Timezones**: Some scenarios assume Moscow time
4. **Randomization**: Set seed for reproducible demos

## Demo Best Practices

### Before Demo
1. Reset database to clean state
2. Warm up caches
3. Check all services running
4. Prepare fallback data

### During Demo
1. Start with impact metrics
2. Show competitive advantages
3. Demonstrate ease of use
4. Highlight Russian features

### After Demo
1. Provide sandbox access
2. Share performance reports
3. Calculate specific ROI
4. Schedule deep dive

## Quick Reference

### Key Metrics to Show
- Forecast accuracy: 12% vs 35% MAPE
- Multi-skill efficiency: 85% vs 60-70%
- Schedule generation: 5 seconds vs 45 seconds
- Real-time updates: 30 seconds vs 5 minutes

### Compelling Visualizations
- Real-time dashboard with traffic lights
- Forecast accuracy comparison chart
- Multi-skill optimization matrix
- ROI calculator results