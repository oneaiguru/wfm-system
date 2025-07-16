# 📋 SUBAGENT TASK: BDD Scenario 007 - Employee Profile Management with Cyrillic Support

## 🎯 Task Information
- **Task ID**: BDD_SCENARIO_007
- **Priority**: Critical
- **Estimated Time**: 45 minutes
- **Dependencies**: Enhanced employee profiles tables, Cyrillic character support
- **BDD File**: `/intelligence/argus/bdd-specifications/16-personnel-management-organizational-structure.feature`

## 📊 BDD Scenario Details

**Scenario**: Create New Employee Profile with Complete Technical Integration (Lines 21-43)
```gherkin
Given I navigate to "Personnel" → "Employees"
When I create a new employee by clicking "Create Employee"
Then I should fill mandatory employee information:
  | Field | Type | Validation | Example | Database Storage |
  | Last Name | Text | Required, Cyrillic | Иванов | VARCHAR(100) |
  | First Name | Text | Required, Cyrillic | Иван | VARCHAR(100) |
  | Patronymic | Text | Optional, Cyrillic | Иванович | VARCHAR(100) |
  | Personnel Number | Text | Required, Unique | 12345 | UNIQUE INDEX |
  | Department | Dropdown | Required, Existing | Call Center | FOREIGN KEY |
  | Position | Dropdown | Required, Existing | Operator | FOREIGN KEY |
  | Hire Date | Date | Required, Past/Present | 01.01.2025 | DATE TYPE |
  | Time Zone | Dropdown | Required | Europe/Moscow | TIMEZONE REF |
And create WFM account credentials with security requirements:
  | Field | Requirement | Security | Password Policy |
  | Login | Unique identifier | System-generated or manual | Min 6 chars, alphanumeric |
  | Temporary Password | Initial password | TempPass123! | Min 8 chars, complexity rules |
  | Force Password Change | Security setting | Yes for first login | Mandatory on first access |
  | Account Expiration | Security control | 90 days inactive | Automatic deactivation |
Then the employee profile should be created successfully
And WFM account should require password change on first login
And audit log should record account creation with full details
```

## 📝 Implementation Steps

### Step 1: Verify/Create Required Tables
```sql
-- Check if enhanced_employee_profiles table exists (from Schema 037)
SELECT COUNT(*) as table_exists 
FROM information_schema.tables 
WHERE table_name = 'enhanced_employee_profiles';

-- Create departments table if not exists
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_name VARCHAR(200) NOT NULL UNIQUE,
    department_code VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create positions table if not exists
CREATE TABLE IF NOT EXISTS positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_name VARCHAR(200) NOT NULL,
    position_code VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample departments and positions
INSERT INTO departments (department_name, department_code) VALUES
('Call Center', 'CC'),
('Technical Support', 'TS'),
('Sales Team', 'ST')
ON CONFLICT (department_name) DO NOTHING;

INSERT INTO positions (position_name, position_code) VALUES
('Operator', 'OP'),
('Senior Operator', 'SOP'),
('Team Lead', 'TL'),
('Manager', 'MNG')
ON CONFLICT (position_code) DO NOTHING;
```

### Step 2: Add API Contract to Enhanced Employee Profiles Table
```sql
-- Add API contract comment to enhanced_employee_profiles table
COMMENT ON TABLE enhanced_employee_profiles IS
'API Contract: POST /api/v1/personnel/employees
expects: {
  "personnel_number": "string (required, unique)",
  "last_name": "string (required, Cyrillic support)",
  "first_name": "string (required, Cyrillic support)", 
  "patronymic": "string (optional, Cyrillic support)",
  "department_id": "UUID (required, FK to departments)",
  "position_id": "UUID (required, FK to positions)",
  "hire_date": "date (required, YYYY-MM-DD)",
  "time_zone": "string (default: Europe/Moscow)",
  "wfm_login": "string (optional, unique)",
  "temporary_password": "string (optional, min 8 chars)"
}
returns: {
  "id": "UUID",
  "personnel_number": "string",
  "account_status": "string",
  "force_password_change": "boolean",
  "created_at": "timestamp"
}

Helper Queries:
-- Create employee with Cyrillic support
INSERT INTO enhanced_employee_profiles (
    personnel_number, last_name, first_name, patronymic,
    department_id, position_id, hire_date, time_zone,
    wfm_login, temporary_password, created_by
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING id, personnel_number, account_status, force_password_change, created_at;

-- Get employee with Russian names
SELECT 
    e.id, e.personnel_number,
    e.last_name, e.first_name, e.patronymic,
    d.department_name, p.position_name,
    e.hire_date, e.time_zone, e.account_status
FROM enhanced_employee_profiles e
JOIN departments d ON e.department_id = d.id
JOIN positions p ON e.position_id = p.id
WHERE e.id = $1;';
```

### Step 3: Create Test Data with Cyrillic Support
```sql
-- Test Cyrillic character support and create sample employees
DO $$
DECLARE
    v_dept_id UUID;
    v_pos_id UUID;
    v_employee_id UUID;
BEGIN
    -- Get department and position IDs
    SELECT id INTO v_dept_id FROM departments WHERE department_code = 'CC';
    SELECT id INTO v_pos_id FROM positions WHERE position_code = 'OP';
    
    -- Create employee with Cyrillic names (BDD example)
    INSERT INTO enhanced_employee_profiles (
        personnel_number, last_name, first_name, patronymic,
        department_id, position_id, hire_date, time_zone,
        wfm_login, temporary_password, created_by
    ) VALUES (
        '12345', 'Иванов', 'Иван', 'Иванович',
        v_dept_id, v_pos_id, '2025-01-01', 'Europe/Moscow',
        'i.ivanov', 'TempPass123!', 'admin'
    ) RETURNING id INTO v_employee_id;
    
    RAISE NOTICE 'Created employee with Cyrillic name: % (ID: %)', 'Иван Иванович Иванов', v_employee_id;
    
    -- Create more test employees with different Cyrillic names
    INSERT INTO enhanced_employee_profiles (
        personnel_number, last_name, first_name, patronymic,
        department_id, position_id, hire_date, time_zone,
        wfm_login, temporary_password, created_by
    ) VALUES 
    ('12346', 'Петрова', 'Мария', 'Сергеевна', v_dept_id, v_pos_id, '2025-01-02', 'Europe/Moscow', 'm.petrova', 'TempPass456!', 'admin'),
    ('12347', 'Сидоров', 'Алексей', 'Владимирович', v_dept_id, v_pos_id, '2025-01-03', 'Europe/Moscow', 'a.sidorov', 'TempPass789!', 'admin'),
    ('12348', 'Козлова', 'Елена', 'Михайловна', v_dept_id, v_pos_id, '2025-01-04', 'Europe/Moscow', 'e.kozlova', 'TempPass012!', 'admin'),
    ('12349', 'Федоров', 'Дмитрий', 'Андреевич', v_dept_id, v_pos_id, '2025-01-05', 'Europe/Moscow', 'd.fedorov', 'TempPass345!', 'admin');
    
    RAISE NOTICE 'Created 5 employees with Russian names and Cyrillic support';
END $$;
```

### Step 4: Create User Account Lifecycle Records
```sql
-- Create account lifecycle records for test employees
INSERT INTO user_account_lifecycle (
    employee_id, 
    password_policy,
    account_lockout_config,
    managed_by
)
SELECT 
    e.id,
    '{
        "min_length": 8,
        "complexity_required": true,
        "expiry_days": 90,
        "history_count": 5
    }'::jsonb,
    '{
        "max_failed_attempts": 5,
        "lockout_duration_minutes": 30,
        "reset_after_success": true
    }'::jsonb,
    'admin'
FROM enhanced_employee_profiles e
WHERE e.created_at > NOW() - INTERVAL '5 minutes';
```

### Step 5: Create Audit Trail
```sql
-- Create audit entries for account creation
CREATE TABLE IF NOT EXISTS employee_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES enhanced_employee_profiles(id),
    action_type VARCHAR(50) NOT NULL,
    action_details JSONB,
    performed_by VARCHAR(50) NOT NULL,
    performed_at TIMESTAMP DEFAULT NOW()
);

-- Log account creation events
INSERT INTO employee_audit_log (employee_id, action_type, action_details, performed_by)
SELECT 
    e.id,
    'ACCOUNT_CREATED',
    jsonb_build_object(
        'personnel_number', e.personnel_number,
        'full_name', e.last_name || ' ' || e.first_name || COALESCE(' ' || e.patronymic, ''),
        'department', d.department_name,
        'position', p.position_name,
        'wfm_login', e.wfm_login,
        'force_password_change', e.force_password_change,
        'account_expiration_days', e.account_expiration_days
    ),
    'admin'
FROM enhanced_employee_profiles e
JOIN departments d ON e.department_id = d.id
JOIN positions p ON e.position_id = p.id
WHERE e.created_at > NOW() - INTERVAL '5 minutes';
```

### Step 6: Verify Cyrillic Character Support
```sql
-- Test Cyrillic character storage and retrieval
SELECT 
    'Cyrillic Support Test' as test_name,
    e.personnel_number,
    e.last_name as "Фамилия",
    e.first_name as "Имя", 
    e.patronymic as "Отчество",
    e.last_name || ' ' || e.first_name || COALESCE(' ' || e.patronymic, '') as "Полное имя",
    d.department_name as "Отдел",
    p.position_name as "Должность",
    e.hire_date as "Дата найма"
FROM enhanced_employee_profiles e
JOIN departments d ON e.department_id = d.id
JOIN positions p ON e.position_id = p.id
WHERE e.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY e.last_name;

-- Verify character encoding and length constraints
SELECT 
    'Character Encoding Test' as test_name,
    LENGTH(e.last_name) as lastname_length,
    LENGTH(e.first_name) as firstname_length,
    LENGTH(e.patronymic) as patronymic_length,
    pg_column_size(e.last_name) as lastname_bytes,
    pg_column_size(e.first_name) as firstname_bytes,
    pg_column_size(e.patronymic) as patronymic_bytes
FROM enhanced_employee_profiles e
WHERE e.personnel_number = '12345';
```

### Step 7: Test Password Policy Validation
```sql
-- Test password policy enforcement
SELECT 
    'Password Policy Test' as test_name,
    e.personnel_number,
    e.wfm_login,
    CASE 
        WHEN e.temporary_password ~ '[A-Z]' 
             AND e.temporary_password ~ '[0-9]' 
             AND e.temporary_password ~ '[!@#$%^&*]'
             AND LENGTH(e.temporary_password) >= 8
        THEN 'PASS'
        ELSE 'FAIL'
    END as password_policy_check,
    e.force_password_change,
    e.account_expiration_days
FROM enhanced_employee_profiles e
WHERE e.created_at > NOW() - INTERVAL '5 minutes';
```

### Step 8: Verify Complete BDD Scenario Implementation
```sql
-- Comprehensive verification query
SELECT 
    'BDD Scenario 007 Verification' as scenario_name,
    COUNT(*) as employees_created,
    COUNT(*) FILTER (WHERE last_name SIMILAR TO '[А-Яё]+') as cyrillic_lastnames,
    COUNT(*) FILTER (WHERE first_name SIMILAR TO '[А-Яё]+') as cyrillic_firstnames,
    COUNT(*) FILTER (WHERE patronymic SIMILAR TO '[А-Яё]+') as cyrillic_patronymics,
    COUNT(*) FILTER (WHERE force_password_change = true) as force_password_change_enabled,
    COUNT(*) FILTER (WHERE account_expiration_days = 90) as proper_expiration_set,
    COUNT(*) FILTER (WHERE time_zone = 'Europe/Moscow') as moscow_timezone_set
FROM enhanced_employee_profiles
WHERE created_at > NOW() - INTERVAL '5 minutes';

-- Show created employees with full Russian names
SELECT 
    'Created Employees' as report_type,
    ROW_NUMBER() OVER (ORDER BY e.personnel_number) as employee_number,
    e.personnel_number as "Табельный номер",
    e.last_name || ' ' || e.first_name || COALESCE(' ' || e.patronymic, '') as "ФИО",
    d.department_name as "Отдел",
    p.position_name as "Должность",
    e.wfm_login as "Логин WFM",
    e.hire_date as "Дата приема",
    e.account_status as "Статус аккаунта"
FROM enhanced_employee_profiles e
JOIN departments d ON e.department_id = d.id
JOIN positions p ON e.position_id = p.id
WHERE e.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY e.personnel_number;

-- Audit trail verification
SELECT 
    'Audit Trail' as report_type,
    a.action_type,
    a.action_details->>'personnel_number' as personnel_number,
    a.action_details->>'full_name' as full_name,
    a.performed_by,
    a.performed_at
FROM employee_audit_log a
WHERE a.performed_at > NOW() - INTERVAL '5 minutes';
```

## ✅ Success Criteria

- [ ] enhanced_employee_profiles table verified/created with Cyrillic support
- [ ] departments and positions reference tables created
- [ ] API contract documented on table
- [ ] 5 test employees created with Russian Cyrillic names
- [ ] WFM account credentials created with security requirements
- [ ] Password policies enforced (8+ chars, complexity, expiration)
- [ ] Force password change enabled for all new accounts
- [ ] User account lifecycle records created
- [ ] Complete audit trail logged for account creation
- [ ] Cyrillic character encoding verified (UTF-8)
- [ ] All field length constraints validated
- [ ] Moscow timezone set as default
- [ ] All BDD scenario requirements implemented

## 📊 Progress Update
```bash
echo "BDD_SCENARIO_007: Complete - Employee Profile Management with Cyrillic Support implemented" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Error Handling
- If Schema 037 tables don't exist, create minimal versions
- If Cyrillic characters display incorrectly, verify database encoding is UTF-8
- If password validation fails, update constraints
- Document any deviations in progress log

## 🔧 Additional Notes
- This scenario implements BDD lines 21-43 from 16-personnel-management-organizational-structure.feature
- Focuses on core employee profile creation with full Cyrillic support
- Includes security requirements and audit trail as specified in BDD
- Tests real Russian names and character encoding
- Validates all database constraints and business rules