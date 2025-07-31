# R7-SchedulingOptimization Domain Primer

## 🎯 Your Domain: Scheduling & Optimization
- **Scenarios**: 86 total (7 demo-critical)
- **Features**: AI optimization, shift management, templates

## 📊 Domain-Specific Details

### Primary Components
- `ScheduleView.tsx` - Schedule display
- `ScheduleEditor.tsx` - Schedule editing
- `VirtualizedScheduleGrid.tsx` - Large schedule handling
- `OptimizationWizard.tsx` - AI optimization

### Primary APIs
- `/api/v1/schedules/*`
- `/api/v1/shifts/*`
- `/api/v1/schedule/optimize`
- `/api/v1/templates/*`

### Expected New Patterns
- **Pattern 7**: Calendar integration (likely)
- **Pattern 8**: Date/time handling
- Performance patterns for large data

### Quick Wins (Start Here)
- SPEC-24-001: View weekly schedule
- SPEC-08-001: Basic shift creation
- SPEC-24-002: Run optimization (demo!)

## 🔄 Dependencies
- **Provides to**: R-IntegrationGateway (schedules for export)
- **Provides to**: R-ForecastAnalytics (actual vs forecast)

## 💡 Domain Tips
1. Calendar widget integration is new territory
2. AI optimization has 30s timeout - be patient
3. Large schedules (1000+ employees) test virtualization
4. Drag-and-drop shift editing is complex