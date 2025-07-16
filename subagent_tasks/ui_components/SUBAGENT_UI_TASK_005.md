# 📋 SUBAGENT TASK: UI Component Conversion 005 - Advanced Scheduling Components

## 🎯 Task Information
- **Task ID**: UI_CONVERSION_005
- **Priority**: High
- **Estimated Time**: 35 minutes
- **Dependencies**: RequestForm.tsx pattern, real employee data, advanced scheduling endpoints

## 📊 Components to Convert (7 advanced scheduling components)

### 1. AdvancedScheduleBuilder.tsx (Schedule Creation)
**Location**: `/components/scheduling-advanced/AdvancedScheduleBuilder.tsx`
**Current Status**: Mock scheduling logic
**Target**: Real schedule building with employee UUIDs and constraints

### 2. ShiftPatternDesigner.tsx (Shift Patterns)
**Location**: `/components/scheduling-advanced/ShiftPatternDesigner.tsx`
**Current Status**: Mock shift patterns
**Target**: Real shift pattern creation and assignment

### 3. ScheduleOptimizer.tsx (AI Optimization)
**Location**: `/components/scheduling-advanced/ScheduleOptimizer.tsx`
**Current Status**: Mock optimization results
**Target**: Real schedule optimization with employee availability

### 4. ConflictResolutionCenter.tsx (Conflict Management)
**Location**: `/components/scheduling-advanced/ConflictResolutionCenter.tsx`
**Current Status**: Mock conflict data
**Target**: Real schedule conflict detection and resolution

### 5. ScheduleTemplateLibrary.tsx (Template Management)
**Location**: `/components/scheduling-advanced/ScheduleTemplateLibrary.tsx`
**Current Status**: Mock templates
**Target**: Real schedule templates with employee assignments

### 6. AutoSchedulingEngine.tsx (Automated Scheduling)
**Location**: `/components/scheduling-advanced/AutoSchedulingEngine.tsx`
**Current Status**: Mock automation
**Target**: Real automated schedule generation

### 7. ScheduleComplianceChecker.tsx (Compliance Validation)
**Location**: `/components/scheduling-advanced/ScheduleComplianceChecker.tsx`
**Current Status**: Mock compliance data
**Target**: Real compliance checking with labor law validation

## 🎯 SUCCESS PATTERN (From RequestForm.tsx - PROVEN WORKING)

### Pattern 1: Real Employee Availability and Constraints
```jsx
// Enhanced employee loading with scheduling constraints
const [employees, setEmployees] = useState([]);
const [employeeAvailability, setEmployeeAvailability] = useState([]);
const [scheduleConstraints, setScheduleConstraints] = useState([]);
const [currentSchedules, setCurrentSchedules] = useState([]);
const [selectedEmployees, setSelectedEmployees] = useState([]);
const [loading, setLoading] = useState(true);

useEffect(() => {
  const loadSchedulingData = async () => {
    try {
      console.log('[BDD COMPLIANT] Loading real scheduling data...');
      
      // Load base employees (exact pattern from RequestForm.tsx)
      const employeesResponse = await fetch('/api/v1/employees');
      if (!employeesResponse.ok) throw new Error('Failed to load employees');
      const employeesData = await employeesResponse.json();
      setEmployees(employeesData.employees || employeesData || []);
      
      // Load employee availability with UUIDs
      const availabilityResponse = await fetch('/api/v1/employees/availability');
      if (!availabilityResponse.ok) throw new Error('Failed to load availability');
      const availabilityData = await availabilityResponse.json();
      setEmployeeAvailability(availabilityData.availability || availabilityData || []);
      
      // Load schedule constraints
      const constraintsResponse = await fetch('/api/v1/scheduling/constraints');
      if (!constraintsResponse.ok) throw new Error('Failed to load constraints');
      const constraintsData = await constraintsResponse.json();
      setScheduleConstraints(constraintsData.constraints || constraintsData || []);
      
      // Load current schedules for conflict detection
      const schedulesResponse = await fetch('/api/v1/schedules/current');
      if (!schedulesResponse.ok) throw new Error('Failed to load schedules');
      const schedulesData = await schedulesResponse.json();
      setCurrentSchedules(schedulesData.schedules || schedulesData || []);
      
      // BDD compliance verification
      const hasRussianNames = employeesData.some(emp => 
        emp.name && (emp.name.includes('Иван') || emp.name.includes('Мария'))
      );
      
      const hasValidAvailability = availabilityData.some(avail => 
        avail.employee_id && typeof avail.employee_id === 'string' && avail.employee_id.length > 30
      );
      
      console.log(`[BDD COMPLIANT] Loaded ${employeesData.length} employees, ${availabilityData.length} availability records, hasRussianNames: ${hasRussianNames}, hasValidUUIDs: ${hasValidAvailability}`);
      
    } catch (err) {
      const errorMessage = `Ошибка загрузки данных планирования: ${err.message}`;
      console.error('[BDD COMPLIANT] Scheduling data loading failed:', err);
    } finally {
      setLoading(false);
    }
  };

  loadSchedulingData();
}, []);
```

### Pattern 2: Multi-Employee Selection with Real UUIDs
```jsx
// Multi-employee selection for schedule building
const EmployeeMultiSelect = () => {
  const handleEmployeeToggle = (employeeId) => {
    setSelectedEmployees(prev => 
      prev.includes(employeeId) 
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId]
    );
  };

  return (
    <div className="employee-selection">
      <h3>Select Employees for Schedule</h3>
      <div className="employee-grid">
        {employees.map(employee => {
          const availability = employeeAvailability.find(
            avail => avail.employee_id === employee.id
          );
          
          const isSelected = selectedEmployees.includes(employee.id);
          
          return (
            <div 
              key={employee.id} 
              className={`employee-card ${isSelected ? 'selected' : ''}`}
              onClick={() => handleEmployeeToggle(employee.id)}
            >
              <div className="employee-name">{employee.name}</div>
              <div className="employee-department">{employee.department}</div>
              <div className="employee-availability">
                {availability ? 
                  `Available: ${availability.available_hours}h/week` : 
                  'No availability data'
                }
              </div>
              <div className="employee-uuid-debug">
                UUID: {employee.id.substring(0, 8)}...
              </div>
            </div>
          );
        })}
      </div>
      <div className="selection-summary">
        Selected: {selectedEmployees.length} employees
      </div>
    </div>
  );
};
```

### Pattern 3: Real Schedule Generation and Optimization
```jsx
// Generate schedule with real employee UUIDs and constraints
const generateOptimizedSchedule = async (scheduleParams) => {
  if (!selectedEmployees.length) {
    throw new Error('Please select employees before generating schedule');
  }
  
  try {
    console.log('[BDD COMPLIANT] Generating schedule with real data:', {
      employees: selectedEmployees,
      period: scheduleParams.period,
      constraints: scheduleParams.constraints
    });
    
    const response = await fetch('/api/v1/scheduling/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        employee_ids: selectedEmployees, // Array of real UUIDs
        start_date: scheduleParams.startDate,
        end_date: scheduleParams.endDate,
        shift_requirements: scheduleParams.shiftRequirements,
        constraints: scheduleParams.constraints,
        optimization_goals: scheduleParams.optimizationGoals
      })
    });
    
    if (!response.ok) {
      throw new Error(`Schedule generation failed: ${response.status}`);
    }
    
    const result = await response.json();
    console.log('[BDD COMPLIANT] Schedule generated successfully:', result);
    
    // Verify schedule has real employee assignments
    const hasRealAssignments = result.schedule.some(shift => 
      shift.employee_id && typeof shift.employee_id === 'string'
    );
    
    if (!hasRealAssignments) {
      console.warn('[BDD COMPLIANCE WARNING] Generated schedule has no real employee assignments');
    }
    
    return result;
    
  } catch (err) {
    console.error('[BDD COMPLIANT] Schedule generation failed:', err);
    throw err;
  }
};

// Check schedule compliance with real constraints
const checkScheduleCompliance = async (scheduleData) => {
  const response = await fetch('/api/v1/scheduling/compliance/check', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      schedule: scheduleData,
      employee_ids: selectedEmployees,
      compliance_rules: scheduleConstraints
    })
  });
  
  if (!response.ok) {
    throw new Error(`Compliance check failed: ${response.status}`);
  }
  
  return await response.json();
};
```

## 📋 DETAILED IMPLEMENTATION STEPS

### AdvancedScheduleBuilder.tsx Conversion:
1. **Replace mock schedule building** → Copy Pattern 1 (load real scheduling data)
2. **Add real employee selection** → Copy Pattern 2 (multi-employee selection)
3. **Implement real schedule generation** → Copy Pattern 3 (schedule generation)
4. **Add constraint validation with real employee data**
5. **Test schedule building with database verification**

### ShiftPatternDesigner.tsx Conversion:
1. **Remove mock shift patterns** → Load real shift pattern templates
2. **Add employee assignment to patterns** → Copy Pattern 2 (employee selection)
3. **Save patterns with real employee UUIDs** → Copy Pattern 3 (pattern saving)
4. **Test pattern creation and reuse in scheduling**
5. **Verify patterns work with real employee availability**

### ScheduleOptimizer.tsx Conversion:
1. **Replace mock optimization** → Use real optimization algorithms
2. **Load real employee availability constraints** → Copy Pattern 1
3. **Generate optimized schedules** → Copy Pattern 3 (optimization)
4. **Display real optimization metrics and improvements**
5. **Test optimization results against manual schedules**

### ConflictResolutionCenter.tsx Conversion:
1. **Remove mock conflicts** → Detect real schedule conflicts
2. **Load real employee schedules for conflict analysis** → Copy Pattern 1
3. **Resolve conflicts with real employee reassignment** → Copy Pattern 3
4. **Add automatic conflict prevention**
5. **Test conflict resolution with real scheduling data**

### ScheduleTemplateLibrary.tsx Conversion:
1. **Replace mock templates** → Load real schedule templates
2. **Template creation with real employee assignments** → Copy Pattern 2
3. **Save/load templates with employee UUIDs** → Copy Pattern 3
4. **Add template versioning and history**
5. **Test template application to real schedules**

### AutoSchedulingEngine.tsx Conversion:
1. **Remove mock automation** → Implement real automated scheduling
2. **Use real employee availability and preferences** → Copy Pattern 1
3. **Generate schedules automatically** → Copy Pattern 3 (auto-generation)
4. **Add learning from successful schedules**
5. **Test automated scheduling quality and accuracy**

### ScheduleComplianceChecker.tsx Conversion:
1. **Replace mock compliance data** → Load real compliance rules
2. **Check real schedules against labor laws** → Copy Pattern 3 (compliance)
3. **Validate employee working hours and rest periods**
4. **Generate real compliance reports**
5. **Test compliance checking with various schedule scenarios**

## ✅ SUCCESS CRITERIA

### BDD Compliance Checklist (ALL must pass):
- [ ] **Real Employee Data**: All components load employees from `/api/v1/employees`
- [ ] **UUID Consistency**: All schedule assignments use employee UUIDs
- [ ] **Russian Names**: Employee names display correctly in all scheduling components
- [ ] **No Mock Scheduling**: Zero hardcoded schedule data or fake optimization
- [ ] **Real Constraints**: All scheduling constraints from database/API
- [ ] **Database Persistence**: All schedules persist to real database tables
- [ ] **Algorithm Integration**: Scheduling algorithms use real employee availability
- [ ] **Compliance Validation**: Real labor law and business rule compliance

### Component-Specific Verification:

#### AdvancedScheduleBuilder.tsx:
- [ ] Schedule creation uses real employee UUIDs and availability
- [ ] Generated schedules persist to database with proper employee references
- [ ] Constraint validation works with real employee data
- [ ] Schedule conflicts detected automatically with real data

#### ShiftPatternDesigner.tsx:
- [ ] Shift patterns created with real employee assignments
- [ ] Pattern templates work with real employee availability
- [ ] Pattern saving/loading maintains UUID references
- [ ] Patterns integrate with schedule generation

#### ScheduleOptimizer.tsx:
- [ ] Optimization algorithms process real employee data
- [ ] Optimization results improve real schedule metrics
- [ ] Optimized schedules maintain employee UUID assignments
- [ ] Performance improvements measurable with real data

#### ConflictResolutionCenter.tsx:
- [ ] Conflict detection works with real schedule overlaps
- [ ] Resolution suggestions use real employee alternatives
- [ ] Conflict resolution updates persist to database
- [ ] Automatic prevention works with real-time scheduling

#### ScheduleTemplateLibrary.tsx:
- [ ] Templates save with real employee UUID assignments
- [ ] Template application works with current employee roster
- [ ] Template versioning maintains employee reference integrity
- [ ] Templates integrate with automated scheduling

#### AutoSchedulingEngine.tsx:
- [ ] Automated generation uses real employee availability
- [ ] Generated schedules meet real business requirements
- [ ] Learning algorithms improve from real schedule success
- [ ] Automation respects real employee preferences and constraints

#### ScheduleComplianceChecker.tsx:
- [ ] Compliance checking uses real labor law rules
- [ ] Schedule validation works with actual employee working hours
- [ ] Compliance reports reflect real schedule violations
- [ ] Automatic compliance enforcement prevents violations

### API Integration Tests:
```bash
# Test all advanced scheduling endpoints
curl -X GET http://localhost:8000/api/v1/employees/availability
curl -X GET http://localhost:8000/api/v1/scheduling/constraints
curl -X POST http://localhost:8000/api/v1/scheduling/generate -d '{"employee_ids": ["UUID1", "UUID2"], ...}'
curl -X POST http://localhost:8000/api/v1/scheduling/optimize -d '{"schedule_id": "UUID", ...}'
curl -X POST http://localhost:8000/api/v1/scheduling/compliance/check -d '{"schedule": {...}}'

# Verify database consistency
psql -d wfm_enterprise -c "SELECT COUNT(*) FROM schedules WHERE employee_id IS NOT NULL;"
psql -d wfm_enterprise -c "SELECT COUNT(*) FROM schedule_templates WHERE created_by IS NOT NULL;"
```

## 📁 FILES TO MODIFY
- `/src/components/scheduling-advanced/AdvancedScheduleBuilder.tsx`
- `/src/components/scheduling-advanced/ShiftPatternDesigner.tsx`
- `/src/components/scheduling-advanced/ScheduleOptimizer.tsx`
- `/src/components/scheduling-advanced/ConflictResolutionCenter.tsx`
- `/src/components/scheduling-advanced/ScheduleTemplateLibrary.tsx`
- `/src/components/scheduling-advanced/AutoSchedulingEngine.tsx`
- `/src/components/scheduling-advanced/ScheduleComplianceChecker.tsx`

## 🔗 API ENDPOINTS REQUIRED
- `GET /api/v1/employees` (base employee data)
- `GET /api/v1/employees/availability` (employee availability)
- `GET /api/v1/scheduling/constraints` (scheduling constraints)
- `GET /api/v1/schedules/current` (current schedules)
- `POST /api/v1/scheduling/generate` (schedule generation)
- `POST /api/v1/scheduling/optimize` (schedule optimization)
- `POST /api/v1/scheduling/compliance/check` (compliance validation)
- `GET /api/v1/scheduling/templates` (schedule templates)

## 📊 EXPECTED OUTPUT
- 7 advanced scheduling components converted to real data
- All components use consistent employee UUID patterns
- Complete automated scheduling workflow with real optimization
- Real-time compliance checking and conflict resolution

**Success Metric**: 7/7 advanced scheduling components working with real employee data and zero mock scheduling logic