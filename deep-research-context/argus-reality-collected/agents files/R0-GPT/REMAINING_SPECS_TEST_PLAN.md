# Remaining 19 Priority Specs - Test Plan

**Agent**: R0-GPT (Reality Tester)
**Date**: 2025-07-27
**Completed**: 30/49 specs (61.2%)
**Remaining**: 19 specs (38.8%)

## 🎯 Specs Requiring Admin Portal Access (High Priority)

### Monitoring Module (3 specs)
1. **SPEC-42**: Real-time Operator Status
   - URL: `/ccwfm/views/env/monitoring/OperatorStatusesView.xhtml`
   - Expected: Live operator status table with columns
   - Test: Check for real-time updates, status categories

2. **SPEC-43**: Queue Monitoring  
   - URL: `/ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml`
   - Expected: Queue metrics and KPIs
   - Test: Auto-refresh, queue statistics

3. **SPEC-44**: Alert Configuration
   - URL: `/ccwfm/views/env/monitoring/UpdateSettingsView.xhtml`
   - Expected: Alert thresholds and notification settings
   - Test: Configuration options, update intervals

### Personnel Module (3 specs)
4. **SPEC-09**: Team Management
   - URL: `/ccwfm/views/env/personnel/GroupListView.xhtml`
   - Expected: Team CRUD operations
   - Test: Create/edit/delete teams

5. **SPEC-10**: Employee Profiles (Admin View)
   - URL: `/ccwfm/views/env/personnel/WorkerListView.xhtml`
   - Expected: Full employee management
   - Test: Add/edit/deactivate employees

6. **SPEC-11**: Skills Assignment (Already verified in DB)
   - URL: Within employee edit interface
   - Expected: Skill assignment UI
   - Test: Multi-skill assignment interface

### Forecasting Module (3 specs)
7. **SPEC-31**: Demand Forecasting (Partially tested)
   - URL: `/ccwfm/views/env/forecasting/ForecastLoadView.xhtml`
   - Expected: Historical data analysis
   - Test: Forecasting parameters and algorithms

8. **SPEC-32**: What-if Scenarios (Partially tested)
   - URL: `/ccwfm/views/env/forecasting/ForecastSpecialEventListView.xhtml`
   - Expected: Special event configuration
   - Test: Event coefficients, scenario modeling

9. **SPEC-33**: Forecast Accuracy (DB verified)
   - URL: `/ccwfm/views/env/forecasting/ForecastAccuracyView.xhtml`
   - Expected: MAPE/WAPE calculations
   - Test: Accuracy reports and metrics

## 🔄 Specs Potentially Testable via Employee Portal

### Request/Workflow Testing (4 specs)
10. **SPEC-20**: Manager View Modes
    - Test: Calendar view switching (Month/Week/Day)
    - Started testing but MCP tools lost

11. **SPEC-21**: View Mode Switching
    - Related to SPEC-20
    - Test: Different calendar perspectives

12. **SPEC-23**: Request Status Progression
    - Test: Create actual request and track status
    - Requires creating real request data

13. **SPEC-35**: Compliance Tracking
    - May relate to acknowledgments system
    - Already found at `/introduce`

## 📊 Specs Requiring Special Access or Data

### System/Integration (3 specs)
14. **SPEC-34**: Performance Dashboard
    - Likely in admin monitoring module
    - Test: KPI metrics display

15. **SPEC-36**: System Integration
    - API/backend testing required
    - May not be UI testable

16. **SPEC-37**: Data Export
    - Test: Report export functionality
    - Check both portals for export options

### Advanced Features (3 specs)  
17. **SPEC-38**: Bulk Operations
    - Admin function for mass updates
    - Test: Multi-select and bulk actions

18. **SPEC-39**: Audit Trail
    - System logging and history
    - Test: Change tracking interface

19. **SPEC-40**: Advanced Search
    - Cross-system search capabilities
    - Test: Search filters and results

## 🚀 Recommended Testing Strategy

### Phase 1: Admin Portal Stabilization
1. Try admin login with fresh session immediately
2. Use Konstantin/12345 credentials
3. Test monitoring module first (most critical)
4. Capture as much as possible before timeout

### Phase 2: Employee Portal Completion
1. Complete calendar view mode testing
2. Create actual vacation request to test workflow
3. Check for any export/report features
4. Look for advanced search capabilities

### Phase 3: Integration/API Testing
1. Check browser network tab for API calls
2. Document endpoint patterns
3. Verify integration touchpoints

## 🔑 Critical Success Factors

1. **Admin Access**: Must solve session timeout issue
   - Try different browser/incognito mode
   - Login and navigate quickly
   - Prioritize high-value specs

2. **Real Data**: Create actual requests/data
   - Submit real vacation request
   - Track through approval cycle
   - Document state transitions

3. **Systematic Approach**: 
   - Test related specs together
   - Document immediately
   - Update BDD files in batches

## 📝 Notes for Next Session

- Start with admin portal immediately while session fresh
- Have all URLs ready for quick navigation  
- Prepare JavaScript snippets for rapid testing
- Focus on UI presence over deep functionality
- Document Russian terminology discovered

With proper admin access, these remaining 19 specs could be tested in 1-2 focused sessions.