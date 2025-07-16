# 📋 SUBAGENT TASK: UI Component Conversion 003 - Scheduling & Analytics Components

## 🎯 Task Information
- **Task ID**: UI_CONVERSION_003
- **Priority**: High
- **Estimated Time**: 35 minutes
- **Dependencies**: RequestForm.tsx pattern, real employee data, scheduling endpoints

## 📊 Components to Convert (5 components)

### 1. ScheduleGrid.tsx (Schedule Display)
**Location**: `/modules/schedule-grid-system/components/ScheduleGrid.tsx`
**Current Status**: Mock schedule data
**Target**: Real schedule data with employee UUIDs

### 2. ForecastingAnalytics.tsx (Demand Forecasting)
**Location**: `/modules/forecasting-analytics/ForecastingAnalytics.tsx`
**Current Status**: Mock forecast data
**Target**: Real forecasting data from database

### 3. ReportsDashboard.tsx (Analytics Dashboard)
**Location**: `/modules/reports-analytics/ReportsDashboard.tsx`
**Current Status**: Hardcoded metrics
**Target**: Real metrics from employee and schedule data

### 4. ShiftTemplateManager.tsx (Shift Templates)
**Location**: `/modules/schedule-grid-system/components/templates/ShiftTemplateManager.tsx`
**Current Status**: Mock template data
**Target**: Real shift templates with employee assignments

### 5. CalendarView.tsx (Calendar Interface)
**Location**: `/modules/schedule-grid-system/components/calendar/CalendarView.tsx`
**Current Status**: Hardcoded events
**Target**: Real calendar events from schedules and requests

## 🎯 SUCCESS PATTERN (Copy from RequestForm.tsx - PROVEN WORKING)

### Pattern 1: Real Data Loading with Multiple Endpoints
```jsx
// ADAPT from RequestForm.tsx for multiple data sources
const [employees, setEmployees] = useState([]);
const [schedules, setSchedules] = useState([]);
const [forecasts, setForecastData] = useState([]);
const [loading, setLoading] = useState(true);
const [errors, setErrors] = useState({});

useEffect(() => {
  const loadAllData = async () => {
    try {
      console.log('[BDD COMPLIANT] Loading real data from multiple APIs...');
      
      // Load employees (copy exact pattern from RequestForm.tsx)
      const employeesResponse = await fetch('/api/v1/employees');
      if (!employeesResponse.ok) throw new Error('Failed to load employees');
      const employeesData = await employeesResponse.json();
      setEmployees(employeesData.employees || employeesData || []);
      
      // Load schedules with real employee references
      const schedulesResponse = await fetch('/api/v1/schedules');
      if (!schedulesResponse.ok) throw new Error('Failed to load schedules');
      const schedulesData = await schedulesResponse.json();
      setSchedules(schedulesData.schedules || schedulesData || []);
      
      // Load forecast data (real historical data)
      const forecastResponse = await fetch('/api/v1/forecasting/historical');
      if (!forecastResponse.ok) throw new Error('Failed to load forecasts');
      const forecastData = await forecastResponse.json();
      setForecastData(forecastData.forecasts || forecastData || []);
      
      // BDD compliance verification
      const hasRussianNames = employeesData.some(emp => 
        emp.name && emp.name.includes('Иван')
      );
      
      const hasRealSchedules = schedulesData.some(schedule => 
        schedule.employee_id && typeof schedule.employee_id === 'string'
      );
      
      console.log(`[BDD COMPLIANT] Loaded ${employeesData.length} employees, ${schedulesData.length} schedules, hasRussianNames: ${hasRussianNames}, hasRealSchedules: ${hasRealSchedules}`);
      
    } catch (err) {
      const errorMessage = `Ошибка загрузки данных: ${err.message}`;
      setErrors(prev => ({ ...prev, general: errorMessage }));
      console.error('[BDD COMPLIANT] Data loading failed:', err);
    } finally {
      setLoading(false);
    }
  };

  loadAllData();
}, []);
```

### Pattern 2: Employee-Schedule Mapping (Real UUIDs)
```jsx
// Map schedules to employee names using real UUIDs
const getEmployeeName = (employeeId) => {
  const employee = employees.find(emp => emp.id === employeeId);
  return employee ? employee.name : 'Unknown Employee';
};

// Display real schedule data
const renderScheduleCell = (schedule) => {
  if (!schedule.employee_id) {
    return <div className="empty-cell">No assignment</div>;
  }
  
  return (
    <div className="schedule-cell" key={schedule.id}>
      <div className="employee-name">
        {getEmployeeName(schedule.employee_id)}
      </div>
      <div className="shift-time">
        {schedule.start_time} - {schedule.end_time}
      </div>
      <div className="employee-id-debug">
        ID: {schedule.employee_id.substring(0, 8)}...
      </div>
    </div>
  );
};
```

### Pattern 3: Real Analytics Calculations
```jsx
// Calculate real metrics from actual data (no mocks)
const calculateRealMetrics = () => {
  if (!employees.length || !schedules.length) {
    return { coverage: 0, utilization: 0, efficiency: 0 };
  }
  
  // Real coverage calculation
  const totalHours = schedules.reduce((sum, schedule) => {
    const start = new Date(`2000-01-01 ${schedule.start_time}`);
    const end = new Date(`2000-01-01 ${schedule.end_time}`);
    return sum + (end - start) / (1000 * 60 * 60); // hours
  }, 0);
  
  // Real utilization calculation
  const availableHours = employees.length * 8; // 8 hours per employee
  const utilization = (totalHours / availableHours) * 100;
  
  // Real efficiency from forecast data
  const latestForecast = forecasts[forecasts.length - 1];
  const efficiency = latestForecast ? latestForecast.accuracy_percentage : 0;
  
  return {
    coverage: Math.round((totalHours / 24) * 100), // 24-hour coverage
    utilization: Math.round(utilization),
    efficiency: Math.round(efficiency)
  };
};
```

## 📋 DETAILED IMPLEMENTATION STEPS

### ScheduleGrid.tsx Conversion:
1. **Remove mock schedule data** → Copy Pattern 1 (load real employees + schedules)
2. **Map schedule cells to real employee UUIDs** → Copy Pattern 2 (UUID mapping)
3. **Display real employee names in schedule grid**
4. **Add real-time schedule updates from API**
5. **Test with database verification of displayed data**

### ForecastingAnalytics.tsx Conversion:
1. **Replace mock forecast data** → Load from `/api/v1/forecasting/historical`
2. **Use real historical patterns** (DATABASE-OPUS provided 1,404 records)
3. **Calculate real accuracy metrics** → Copy Pattern 3 (real calculations)
4. **Display real trend analysis from database**
5. **Test forecasting algorithms with real data**

### ReportsDashboard.tsx Conversion:
1. **Remove hardcoded metrics** → Copy Pattern 1 (load all real data)
2. **Calculate real KPIs from employee + schedule data** → Copy Pattern 3
3. **Display real employee performance metrics**
4. **Add real-time dashboard updates**
5. **Test all metrics match database queries**

### ShiftTemplateManager.tsx Conversion:
1. **Replace mock templates** → Load from `/api/v1/templates/shifts`
2. **Add real employee assignment to templates** → Copy Pattern 2 (UUID mapping)
3. **Create new templates with real employee UUIDs**
4. **Test template creation and assignment**
5. **Verify templates work in schedule generation**

### CalendarView.tsx Conversion:
1. **Remove hardcoded calendar events** → Load real schedules + requests
2. **Display real employee schedules by date** → Copy Pattern 2 (mapping)
3. **Show real vacation/time-off requests on calendar**
4. **Add real event creation with employee selection**
5. **Test calendar synchronization with schedules**

## ✅ SUCCESS CRITERIA

### BDD Compliance Checklist (ALL must pass):
- [ ] **Real Data Loading**: All components load from real API endpoints
- [ ] **UUID References**: All employee references use UUID strings consistently
- [ ] **Russian Names**: Employee names display correctly in all components
- [ ] **No Mock Data**: Zero hardcoded or simulated data anywhere
- [ ] **Real Calculations**: All metrics calculated from actual database data
- [ ] **API Integration**: All data updates reach real backend endpoints
- [ ] **Error Handling**: Real API errors handled gracefully
- [ ] **Performance**: Components handle real data volumes efficiently

### Component-Specific Verification:

#### ScheduleGrid.tsx:
- [ ] Displays real employee names from UUIDs in schedule cells
- [ ] Shows actual work shifts from database
- [ ] Updates reflect real schedule changes
- [ ] Grid correctly maps time slots to real assignments

#### ForecastingAnalytics.tsx:
- [ ] Uses real historical data (1,404+ records from DATABASE-OPUS)
- [ ] Calculates real accuracy metrics (MAPE, WAPE)
- [ ] Shows actual demand patterns, not simulated
- [ ] Forecasting algorithms process real database records

#### ReportsDashboard.tsx:
- [ ] All KPIs calculated from real employee + schedule data
- [ ] Coverage metrics match actual schedule coverage
- [ ] Utilization reflects real employee assignments
- [ ] Performance metrics based on actual work data

#### ShiftTemplateManager.tsx:
- [ ] Templates use real employee UUIDs for assignments
- [ ] Creates templates that work with real scheduling
- [ ] Employee assignments persist to database
- [ ] Template generation uses real employee availability

#### CalendarView.tsx:
- [ ] Calendar events show real employee schedules
- [ ] Vacation requests display with real employee names
- [ ] Event creation assigns real employee UUIDs
- [ ] Calendar synchronizes with actual schedule data

### API Integration Tests:
```bash
# Verify all endpoints return real data
curl -X GET http://localhost:8000/api/v1/employees # Employee UUIDs
curl -X GET http://localhost:8000/api/v1/schedules # Real schedule assignments
curl -X GET http://localhost:8000/api/v1/forecasting/historical # Real forecast data
curl -X GET http://localhost:8000/api/v1/templates/shifts # Real shift templates

# Test data consistency
psql -d wfm_enterprise -c "SELECT COUNT(*) FROM schedules WHERE employee_id IS NOT NULL;"
# Should match schedule count displayed in UI
```

## 📁 FILES TO MODIFY
- `/src/modules/schedule-grid-system/components/ScheduleGrid.tsx`
- `/src/modules/forecasting-analytics/ForecastingAnalytics.tsx`
- `/src/modules/reports-analytics/ReportsDashboard.tsx`
- `/src/modules/schedule-grid-system/components/templates/ShiftTemplateManager.tsx`
- `/src/modules/schedule-grid-system/components/calendar/CalendarView.tsx`

## 🔗 API ENDPOINTS REQUIRED
- `GET /api/v1/employees` (employee data)
- `GET /api/v1/schedules` (schedule assignments)
- `GET /api/v1/forecasting/historical` (real forecast data)
- `GET /api/v1/templates/shifts` (shift templates)
- `POST /api/v1/schedules` (schedule creation)
- `PUT /api/v1/schedules/{id}` (schedule updates)

## 📊 EXPECTED OUTPUT
- 5 scheduling/analytics components converted to real data
- All components use proven employee UUID patterns
- Real-time data synchronization working
- Complete analytics based on actual database records

**Success Metric**: 5/5 components displaying real employee schedules and metrics with zero mock data