# 📋 SUBAGENT TASK: UI Component Conversion 004 - Advanced Employee Components

## 🎯 Task Information
- **Task ID**: UI_CONVERSION_004
- **Priority**: High
- **Estimated Time**: 40 minutes
- **Dependencies**: RequestForm.tsx pattern, real employee data, advanced HR endpoints

## 📊 Components to Convert (6 advanced employee components)

### 1. SkillsMatrixManager.tsx (Skills Management)
**Location**: `/components/employee-enhanced/SkillsMatrixManager.tsx`
**Current Status**: Mock skills data
**Target**: Real employee skills with UUID references

### 2. PerformanceTracker.tsx (Performance Monitoring)
**Location**: `/components/employee-enhanced/PerformanceTracker.tsx`
**Current Status**: Mock performance data
**Target**: Real employee performance metrics

### 3. CareerDevelopmentPlanner.tsx (Career Planning)
**Location**: `/components/employee-enhanced/CareerDevelopmentPlanner.tsx`
**Current Status**: Mock career paths
**Target**: Real career development with employee UUIDs

### 4. TrainingProgramManager.tsx (Training Management)
**Location**: `/components/employee-enhanced/TrainingProgramManager.tsx`
**Current Status**: Mock training data
**Target**: Real training programs with employee enrollment

### 5. EmployeeOnboardingPortal.tsx (Onboarding)
**Location**: `/components/employee-enhanced/EmployeeOnboardingPortal.tsx`
**Current Status**: Mock onboarding steps
**Target**: Real onboarding process tracking

### 6. CompetencyAssessmentCenter.tsx (Assessments)
**Location**: `/components/employee-enhanced/CompetencyAssessmentCenter.tsx`
**Current Status**: Mock assessment data
**Target**: Real competency assessments and results

## 🎯 SUCCESS PATTERN (From RequestForm.tsx - PROVEN WORKING)

### Pattern 1: Real Employee Data with Skills/Performance
```jsx
// Enhanced employee loading with additional HR data
const [employees, setEmployees] = useState([]);
const [employeeSkills, setEmployeeSkills] = useState([]);
const [performanceData, setPerformanceData] = useState([]);
const [loading, setLoading] = useState(true);
const [selectedEmployeeId, setSelectedEmployeeId] = useState('');

useEffect(() => {
  const loadEmployeeHRData = async () => {
    try {
      console.log('[BDD COMPLIANT] Loading real employee HR data...');
      
      // Load base employees (exact pattern from RequestForm.tsx)
      const employeesResponse = await fetch('/api/v1/employees');
      if (!employeesResponse.ok) throw new Error('Failed to load employees');
      const employeesData = await employeesResponse.json();
      setEmployees(employeesData.employees || employeesData || []);
      
      // Load employee skills with UUIDs
      const skillsResponse = await fetch('/api/v1/employees/skills');
      if (!skillsResponse.ok) throw new Error('Failed to load skills');
      const skillsData = await skillsResponse.json();
      setEmployeeSkills(skillsData.skills || skillsData || []);
      
      // Load performance data with UUIDs
      const performanceResponse = await fetch('/api/v1/employees/performance');
      if (!performanceResponse.ok) throw new Error('Failed to load performance');
      const performanceData = await performanceResponse.json();
      setPerformanceData(performanceData.performance || performanceData || []);
      
      // BDD compliance verification
      const hasRussianNames = employeesData.some(emp => 
        emp.name && (emp.name.includes('Иван') || emp.name.includes('Мария'))
      );
      
      const hasValidSkillReferences = skillsData.some(skill => 
        skill.employee_id && typeof skill.employee_id === 'string' && skill.employee_id.length > 30
      );
      
      console.log(`[BDD COMPLIANT] Loaded ${employeesData.length} employees, ${skillsData.length} skills, hasRussianNames: ${hasRussianNames}, hasValidUUIDs: ${hasValidSkillReferences}`);
      
    } catch (err) {
      const errorMessage = `Ошибка загрузки HR данных: ${err.message}`;
      console.error('[BDD COMPLIANT] HR data loading failed:', err);
    } finally {
      setLoading(false);
    }
  };

  loadEmployeeHRData();
}, []);
```

### Pattern 2: Skills/Performance Matrix with Real UUIDs
```jsx
// Create skills matrix using real employee UUIDs
const createSkillsMatrix = () => {
  return employees.map(employee => {
    const employeeSkillsData = employeeSkills.filter(
      skill => skill.employee_id === employee.id // Real UUID matching
    );
    
    const employeePerformance = performanceData.find(
      perf => perf.employee_id === employee.id // Real UUID matching
    );
    
    return {
      id: employee.id, // Real UUID
      name: employee.name, // Real Russian name
      department: employee.department,
      skills: employeeSkillsData.map(skill => ({
        name: skill.skill_name,
        level: skill.proficiency_level,
        certified: skill.is_certified,
        lastAssessed: skill.last_assessment_date
      })),
      performance: employeePerformance ? {
        efficiency: employeePerformance.efficiency_rating,
        quality: employeePerformance.quality_score,
        attendance: employeePerformance.attendance_percentage
      } : null
    };
  });
};
```

### Pattern 3: Real HR Operations (Skills, Training, Assessments)
```jsx
// Update employee skills with real API calls
const updateEmployeeSkill = async (employeeId, skillId, newLevel) => {
  if (!employeeId || typeof employeeId !== 'string') {
    throw new Error('Invalid employee ID: Must be UUID string');
  }
  
  try {
    console.log('[BDD COMPLIANT] Updating employee skill:', { employeeId, skillId, newLevel });
    
    const response = await fetch(`/api/v1/employees/${employeeId}/skills/${skillId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        proficiency_level: newLevel,
        last_updated: new Date().toISOString(),
        updated_by: 'system' // In real app, would be current user
      })
    });
    
    if (!response.ok) {
      throw new Error(`Failed to update skill: ${response.status}`);
    }
    
    const result = await response.json();
    console.log('[BDD COMPLIANT] Skill updated successfully:', result);
    
    // Reload skills data to reflect changes
    await loadEmployeeHRData();
    
  } catch (err) {
    console.error('[BDD COMPLIANT] Skill update failed:', err);
    throw err;
  }
};

// Enroll employee in training with real UUIDs
const enrollInTraining = async (employeeId, programId) => {
  if (!employeeId || !programId) {
    throw new Error('Employee ID and Program ID required');
  }
  
  const response = await fetch(`/api/v1/training/enroll`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      employee_id: employeeId, // Real UUID
      program_id: programId,   // Real program UUID
      enrollment_date: new Date().toISOString()
    })
  });
  
  if (!response.ok) {
    throw new Error(`Training enrollment failed: ${response.status}`);
  }
  
  return await response.json();
};
```

## 📋 DETAILED IMPLEMENTATION STEPS

### SkillsMatrixManager.tsx Conversion:
1. **Replace mock skills data** → Copy Pattern 1 (load real employee skills)
2. **Create real skills matrix with UUIDs** → Copy Pattern 2 (matrix creation)
3. **Implement skill level updates** → Copy Pattern 3 (skill updates)
4. **Add skill certification tracking with real data**
5. **Test skills matrix reflects database changes**

### PerformanceTracker.tsx Conversion:
1. **Remove mock performance metrics** → Load real performance data
2. **Display real employee performance with UUIDs** → Copy Pattern 2
3. **Calculate real KPIs from database performance records**
4. **Add performance history tracking**
5. **Test performance updates persist to database**

### CareerDevelopmentPlanner.tsx Conversion:
1. **Replace mock career paths** → Load real career development data
2. **Map career plans to employee UUIDs** → Copy Pattern 2 (UUID mapping)
3. **Create/update career plans with real employee selection** → Copy Pattern 3
4. **Add milestone tracking with real progress data**
5. **Test career planning workflow end-to-end**

### TrainingProgramManager.tsx Conversion:
1. **Remove mock training programs** → Load real training data
2. **Add real employee enrollment** → Copy Pattern 3 (enrollment)
3. **Track training progress with real UUIDs**
4. **Display real training completion status**
5. **Test training program management workflow**

### EmployeeOnboardingPortal.tsx Conversion:
1. **Replace mock onboarding steps** → Load real onboarding processes
2. **Track real employee onboarding progress** → Copy Pattern 2 (UUID tracking)
3. **Update onboarding status with real API calls** → Copy Pattern 3
4. **Display real onboarding metrics and completion rates**
5. **Test complete onboarding workflow**

### CompetencyAssessmentCenter.tsx Conversion:
1. **Remove mock assessment data** → Load real assessment records
2. **Schedule assessments for real employees** → Copy Pattern 3 (scheduling)
3. **Track assessment results with employee UUIDs** → Copy Pattern 2
4. **Generate real competency reports from database**
5. **Test assessment scheduling and completion workflow**

## ✅ SUCCESS CRITERIA

### BDD Compliance Checklist (ALL must pass):
- [ ] **Real Employee Data**: All components load employees from `/api/v1/employees`
- [ ] **UUID Consistency**: All employee references use consistent UUID format
- [ ] **Russian Names**: Employee names display correctly in all HR components
- [ ] **No Mock Data**: Zero hardcoded HR data (skills, performance, training)
- [ ] **Real HR Operations**: All HR updates (skills, training, assessments) reach API
- [ ] **Database Persistence**: All HR changes persist to real database tables
- [ ] **Cross-Component Integration**: HR data consistent across all 6 components
- [ ] **Performance**: Components handle real HR data volumes efficiently

### Component-Specific Verification:

#### SkillsMatrixManager.tsx:
- [ ] Skills matrix displays real employee UUIDs and names
- [ ] Skill level updates persist to database
- [ ] Certification tracking works with real data
- [ ] Skills gaps calculated from real skill assessments

#### PerformanceTracker.tsx:
- [ ] Performance metrics calculated from real employee data
- [ ] Performance history shows actual historical records
- [ ] KPI calculations match database query results
- [ ] Performance trends based on real time-series data

#### CareerDevelopmentPlanner.tsx:
- [ ] Career paths assigned to real employee UUIDs
- [ ] Milestone tracking updates database correctly
- [ ] Career progression reflects real employee development
- [ ] Development plans created with real employee selection

#### TrainingProgramManager.tsx:
- [ ] Training enrollment uses real employee UUIDs
- [ ] Training progress tracked in database
- [ ] Program completion rates calculated from real data
- [ ] Training schedules integrate with real employee calendars

#### EmployeeOnboardingPortal.tsx:
- [ ] Onboarding steps tracked for real new employees
- [ ] Progress updates persist to database
- [ ] Onboarding metrics reflect actual completion data
- [ ] New employee workflow uses real employee creation

#### CompetencyAssessmentCenter.tsx:
- [ ] Assessments scheduled for real employees with UUIDs
- [ ] Assessment results stored with employee references
- [ ] Competency reports generated from real assessment data
- [ ] Assessment scheduling integrates with real employee availability

### API Integration Tests:
```bash
# Test all HR endpoints
curl -X GET http://localhost:8000/api/v1/employees/skills
curl -X GET http://localhost:8000/api/v1/employees/performance  
curl -X GET http://localhost:8000/api/v1/training/programs
curl -X GET http://localhost:8000/api/v1/assessments
curl -X POST http://localhost:8000/api/v1/training/enroll -d '{"employee_id": "UUID", "program_id": "UUID"}'

# Verify database consistency
psql -d wfm_enterprise -c "SELECT COUNT(*) FROM employee_skills WHERE employee_id IS NOT NULL;"
psql -d wfm_enterprise -c "SELECT COUNT(*) FROM employee_performance WHERE employee_id IS NOT NULL;"
```

## 📁 FILES TO MODIFY
- `/src/components/employee-enhanced/SkillsMatrixManager.tsx`
- `/src/components/employee-enhanced/PerformanceTracker.tsx`
- `/src/components/employee-enhanced/CareerDevelopmentPlanner.tsx`
- `/src/components/employee-enhanced/TrainingProgramManager.tsx`
- `/src/components/employee-enhanced/EmployeeOnboardingPortal.tsx`
- `/src/components/employee-enhanced/CompetencyAssessmentCenter.tsx`

## 🔗 API ENDPOINTS REQUIRED
- `GET /api/v1/employees` (base employee data)
- `GET /api/v1/employees/skills` (employee skills)
- `GET /api/v1/employees/performance` (performance data)
- `GET /api/v1/training/programs` (training programs)
- `GET /api/v1/assessments` (competency assessments)
- `POST /api/v1/training/enroll` (training enrollment)
- `PUT /api/v1/employees/{id}/skills/{skill_id}` (skill updates)
- `POST /api/v1/assessments/schedule` (assessment scheduling)

## 📊 EXPECTED OUTPUT
- 6 advanced HR components converted to real data
- All components use consistent employee UUID patterns
- Complete HR workflow integration (skills → training → assessments)
- Real-time HR data synchronization across all components

**Success Metric**: 6/6 advanced employee components working with real HR data and zero mock dependencies