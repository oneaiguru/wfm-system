# R3-ForecastAnalytics Domain Primer

## 🎯 Your Domain: Forecasting & Analytics
- **Scenarios**: 73 total (4 demo-critical)
- **Features**: Forecast planning, real-time monitoring, KPIs

## 📊 Domain-Specific Details

### Primary Components
- `AnalyticsDashboard.tsx` - KPI display
- `KPICharts.tsx` - Chart components
- `ForecastingWizard.tsx` - Forecast generation
- `MonitoringDashboard.tsx` - Real-time views

### Primary APIs
- `/api/v1/forecasts/*`
- `/api/v1/models/*`
- `/api/v1/analytics/alerts`
- `/api/v1/monitoring/dashboard`

### Expected New Patterns
- **Pattern 8**: Date/time handling (forecast ranges)
- Chart rendering patterns
- Real-time data updates

### Quick Wins (Start Here)
- SPEC-09-001: View forecast dashboard
- SPEC-10-001: Real-time monitoring
- SPEC-09-002: Generate weekly forecast

## 🔄 Dependencies
- **Depends on**: R-SchedulingOptimization (actual data)
- **Provides to**: R-ReportingCompliance (analytics data)

## 💡 Domain Tips
1. Chart components may need specific selectors
2. Date range comparisons are critical
3. Real-time updates use WebSocket
4. Forecast accuracy depends on historical data