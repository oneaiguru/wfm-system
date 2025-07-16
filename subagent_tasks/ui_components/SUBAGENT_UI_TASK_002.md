# 📋 SUBAGENT TASK: UI Component Conversion 002 - Request Management Forms

## 🎯 Task Information
- **Task ID**: UI_CONVERSION_002
- **Priority**: Critical
- **Estimated Time**: 30 minutes
- **Dependencies**: RequestForm.tsx success pattern, /api/v1/employees endpoint

## 📊 Components to Convert (4 components)

### 1. RequestManager.tsx (Request Management)
**Location**: `/modules/employee-portal/components/requests/RequestManager.tsx`
**Current Status**: Mock request data
**Target**: Real request management with employee UUIDs

### 2. ShiftExchangeForm.tsx (Shift Exchange)
**Location**: `/modules/schedule-grid-system/components/shifts/ShiftExchangeForm.tsx`
**Current Status**: Hardcoded employee options
**Target**: Real employee selection for shift exchanges

### 3. OvertimeRequestForm.tsx (Overtime Requests)
**Location**: `/modules/employee-portal/components/overtime/OvertimeRequestForm.tsx`
**Current Status**: Mock overtime data
**Target**: Real overtime request submission

### 4. TimeOffForm.tsx (Time Off Requests)
**Location**: `/modules/employee-portal/components/timeoff/TimeOffForm.tsx`
**Current Status**: Hardcoded employee data
**Target**: Real time-off request management

## 🎯 SUCCESS PATTERN (Copy from RequestForm.tsx - PROVEN WORKING)

### Pattern 1: Real Employee Loading (EXACT COPY)
```jsx
// COPY EXACTLY from RequestForm.tsx lines 60-94
const [employees, setEmployees] = useState([]);
const [selectedEmployeeId, setSelectedEmployeeId] = useState('');
const [loading, setLoading] = useState(true);
const [apiError, setApiError] = useState('');

useEffect(() => {
  const loadEmployees = async () => {
    try {
      console.log('[BDD COMPLIANT] Loading real employees from API...');
      const response = await fetch('/api/v1/employees');
      
      if (!response.ok) {
        throw new Error(`Failed to load employees: ${response.status}`);
      }
      
      const data = await response.json();
      setEmployees(data.employees || data || []);
      
      // BDD compliance check for Russian names
      const hasRussianNames = data.some(emp => 
        emp.name && (emp.name.includes('Иван') || emp.name.includes('Мария') || emp.name.includes('Петр'))
      );
      
      console.log(`[BDD COMPLIANT] Loaded ${data.length} employees, hasRussianNames: ${hasRussianNames}`);
      
      if (!hasRussianNames) {
        console.warn('[BDD COMPLIANCE WARNING] No Russian employee names found - check API data');
      }
      
    } catch (err) {
      const errorMessage = `Ошибка загрузки сотрудников: ${err instanceof Error ? err.message : 'Unknown error'}`;
      setApiError(errorMessage);
      console.error('[BDD COMPLIANT] Employee loading failed:', err);
    } finally {
      setLoading(false);
    }
  };

  loadEmployees();
}, []);
```

### Pattern 2: Employee Selection UI (EXACT COPY)
```jsx
// COPY EXACTLY from RequestForm.tsx lines 623-646
<div>
  <label className="block text-sm font-medium text-gray-700 mb-1">
    Select Employee *
  </label>
  <select
    value={selectedEmployeeId}
    onChange={(e) => setSelectedEmployeeId(e.target.value)}
    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
  >
    <option value="">-- Choose Employee --</option>
    {employees.map(emp => (
      <option key={emp.id} value={emp.id}>
        {emp.name} ({emp.email || emp.department || 'Employee'})
      </option>
    ))}
  </select>
  <div className="text-xs text-gray-500 mt-1">
    Loaded employees: {employees.length}
    {employees.length === 0 && apiError && ' - Error loading employees'}
  </div>
  {errors.selectedEmployee && (
    <p className="mt-1 text-sm text-red-600">{errors.selectedEmployee}</p>
  )}
</div>
```

### Pattern 3: UUID Validation & Submission (EXACT COPY)
```jsx
// COPY EXACTLY from RequestForm.tsx lines 253-275
const handleSubmit = async (formData) => {
  // BDD Compliance: Use real selected employee UUID, not hardcoded ID
  if (!selectedEmployeeId) {
    throw new Error('Please select an employee before submitting');
  }
  
  // Prepare real API request with selected employee UUID
  const requestData = {
    employee_id: selectedEmployeeId, // Real UUID from dropdown selection
    // ... other form data
  };

  console.log('[REAL COMPONENT] Submitting request to real API:', requestData);

  // Make REAL API call - NO MOCKS
  const response = await fetch('/api/v1/requests/[type]', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestData)
  });
  
  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  const result = await response.json();
  console.log('[REAL COMPONENT] Request submitted successfully:', result);
  
  // Show real success message
  alert(`Request submitted successfully! ID: ${result.id}`);
};
```

## 📋 DETAILED IMPLEMENTATION STEPS

### RequestManager.tsx Conversion:
1. **Replace mock request data** → Copy Pattern 1 (real employee loading)
2. **Add employee selection to request creation** → Copy Pattern 2 (dropdown)
3. **Fix request submission with UUIDs** → Copy Pattern 3 (submission)
4. **Update request display to show real employee names**
5. **Test complete request management workflow**

### ShiftExchangeForm.tsx Conversion:
1. **Remove hardcoded shift participants** → Copy Pattern 1 (load real employees)
2. **Add dual employee selection** (initiator + target) → Adapt Pattern 2
3. **Submit shift exchanges with real UUIDs** → Copy Pattern 3
4. **Add validation for shift exchange rules**
5. **Test with real shift data**

### OvertimeRequestForm.tsx Conversion:
1. **Remove mock overtime data** → Copy Pattern 1 (real employee loading)
2. **Add employee selection for overtime requests** → Copy Pattern 2
3. **Submit to real overtime API with UUIDs** → Copy Pattern 3
4. **Add overtime calculation with real employee data**
5. **Test overtime approval workflow**

### TimeOffForm.tsx Conversion:
1. **Replace hardcoded time-off data** → Copy Pattern 1 (load employees)
2. **Add employee selection for time-off requests** → Copy Pattern 2
3. **Submit to real time-off API with UUIDs** → Copy Pattern 3
4. **Add time-off balance calculation**
5. **Test complete time-off management**

## ✅ SUCCESS CRITERIA

### BDD Compliance Checklist (ALL must pass):
- [ ] **Real Employee Loading**: All forms load from `/api/v1/employees`
- [ ] **UUID Format**: All employee_id fields use UUID strings, not integers
- [ ] **Russian Names**: Employee dropdowns show Russian names (Иван, Мария, etc.)
- [ ] **No Hardcoding**: No hardcoded employee arrays or mock data anywhere
- [ ] **Real API Integration**: All submissions reach real backend endpoints
- [ ] **Error Handling**: Shows real API errors, not fake success messages
- [ ] **Loading States**: Proper loading indicators during all API operations
- [ ] **Form Validation**: Requires valid employee selection before submission

### Component-Specific Tests:

#### RequestManager.tsx:
- [ ] Loads real employee list for request assignment
- [ ] Displays real requests from database
- [ ] Creates new requests with real UUIDs
- [ ] Updates request status with real API calls

#### ShiftExchangeForm.tsx:
- [ ] Dual employee selection (from + to) with real data
- [ ] Validates shift exchange rules with real schedules
- [ ] Submits exchanges with both employee UUIDs
- [ ] Shows real shift conflict detection

#### OvertimeRequestForm.tsx:
- [ ] Employee selection for overtime requests
- [ ] Calculates overtime rates with real employee data
- [ ] Submits to overtime API with UUIDs
- [ ] Displays real overtime approval status

#### TimeOffForm.tsx:
- [ ] Employee selection for time-off requests
- [ ] Shows real time-off balances from database
- [ ] Submits time-off with employee UUIDs
- [ ] Updates balances with real calculations

### API Integration Verification:
```bash
# Test all endpoints work with UUIDs
curl -X GET http://localhost:8000/api/v1/employees
curl -X POST http://localhost:8000/api/v1/requests/overtime -d '{"employee_id": "UUID", ...}'
curl -X POST http://localhost:8000/api/v1/requests/timeoff -d '{"employee_id": "UUID", ...}'
curl -X POST http://localhost:8000/api/v1/schedules/exchange -d '{"from_employee": "UUID", "to_employee": "UUID", ...}'
```

## 📁 FILES TO MODIFY
- `/src/modules/employee-portal/components/requests/RequestManager.tsx`
- `/src/modules/schedule-grid-system/components/shifts/ShiftExchangeForm.tsx`
- `/src/modules/employee-portal/components/overtime/OvertimeRequestForm.tsx`
- `/src/modules/employee-portal/components/timeoff/TimeOffForm.tsx`

## 🔗 API ENDPOINTS REQUIRED
- `GET /api/v1/employees` (employee list)
- `POST /api/v1/requests/overtime` (overtime requests)
- `POST /api/v1/requests/timeoff` (time-off requests)
- `POST /api/v1/schedules/exchange` (shift exchanges)
- `GET /api/v1/requests/my` (user's requests)

## 📊 EXPECTED OUTPUT
- 4 request management components converted to real data
- All components follow proven RequestForm.tsx pattern
- Complete end-to-end request workflows working
- BDD compliance verified for all components

**Success Metric**: 4/4 request forms working with real employee UUIDs + zero hardcoded data