# SPEC-15 Real-Time Monitoring Test Plan

## Current Status
- **Progress**: 5/49 priority specs tested (10.2%)
- **Next Target**: SPEC-15 Real-time Monitoring Operational Control
- **BDD File**: `15-real-time-monitoring-operational-control.feature`
- **Module**: Мониторинг → Operational Control

## Test Objectives
1. Verify real-time operational dashboards exist in Argus
2. Document 6 key metrics: Operators Online %, Load Deviation, Operator Requirement, SLA Performance, ACD Rate, AHT Trend
3. Test drill-down functionality for detailed breakdowns
4. Compare with our current monitoring implementation
5. Update BDD spec with REALITY tags

## Expected Argus Features to Test
- **Six Real-time Metrics**:
  - Operators Online % (30s updates)
  - Load Deviation (1min updates) 
  - Operator Requirement (real-time)
  - SLA Performance (1min updates)
  - ACD Rate (real-time)
  - AHT Trend (5min updates)

- **Visual Elements**:
  - Traffic light color coding (Green/Yellow/Red)
  - Trend arrows (up/down/stable)
  - Large number displays
  - Historical context (sparklines)

- **Drill-Down Capability**:
  - Schedule adherence 24h
  - By timetable status
  - Actually online agents
  - Individual agent status
  - Deviation timeline

## Testing Method
1. Login to cc1010wfmcc.argustelecom.ru/ccwfm/ (Konstantin/12345)
2. Navigate to "Мониторинг" menu
3. Look for "Operational Control" or similar monitoring dashboards
4. Document actual metrics displayed
5. Test click-through functionality
6. Screenshot key interfaces for documentation

## Expected Implementation Changes
Based on testing, will likely need:
- **D Agent**: Create monitoring tables for real-time metrics
- **E Agent**: Build WebSocket endpoints for 30s/1min/5min updates
- **U Agent**: Implement dashboard with traffic light indicators and drill-downs

## Documentation Updates
- Add # REALITY: tags to BDD spec with actual Argus behavior
- Note any missing features or different terminology
- Document update frequencies and thresholds
- Create implementation guidance for D/E/U agents