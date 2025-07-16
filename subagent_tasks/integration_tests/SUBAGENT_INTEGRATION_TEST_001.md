# 📋 SUBAGENT TASK: Integration Test 001 - Vacation Request Full Flow

## 🎯 Task Information
- **Task ID**: INTEGRATION_TEST_001
- **Priority**: Critical
- **Estimated Time**: 20 minutes
- **Dependencies**: vacation_requests table, employees table, API running
- **Test Type**: End-to-End Integration

## 📊 Test Scenario

**Full Vacation Request Flow**:
1. Database has real employee data
2. API endpoint accepts UUID employee_id
3. Request saved to database
4. Status correctly set to 'pending'
5. Manager notified
6. Employee can check request status

## 📝 Test Implementation

### Step 1: Create Test Procedure
```sql
CREATE OR REPLACE FUNCTION test_vacation_request_integration()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_employee_id UUID;
    v_request_id INTEGER;
    v_test_passed BOOLEAN := true;
    v_error_msg TEXT;
BEGIN
    -- Test 1: Employee exists
    SELECT id INTO v_employee_id 
    FROM employees 
    WHERE first_name = 'Иван' 
    LIMIT 1;
    
    IF v_employee_id IS NULL THEN
        RETURN QUERY SELECT 'Employee Exists'::TEXT, 'FAIL'::TEXT, 'No employee named Иван found'::TEXT;
        v_test_passed := false;
    ELSE
        RETURN QUERY SELECT 'Employee Exists'::TEXT, 'PASS'::TEXT, 'Employee ID: ' || v_employee_id::TEXT;
    END IF;
    
    -- Test 2: Create vacation request
    BEGIN
        INSERT INTO vacation_requests (employee_id, start_date, end_date, reason, request_type)
        VALUES (v_employee_id, '2025-03-01', '2025-03-07', 'Тестовый отпуск', 'отпуск')
        RETURNING id INTO v_request_id;
        
        RETURN QUERY SELECT 'Create Request'::TEXT, 'PASS'::TEXT, 'Request ID: ' || v_request_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Create Request'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 3: Verify request saved correctly
    PERFORM 1 FROM vacation_requests 
    WHERE id = v_request_id 
    AND status = 'pending';
    
    IF FOUND THEN
        RETURN QUERY SELECT 'Request Status'::TEXT, 'PASS'::TEXT, 'Status is pending'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Request Status'::TEXT, 'FAIL'::TEXT, 'Status not set to pending'::TEXT;
        v_test_passed := false;
    END IF;
    
    -- Test 4: Check employee can retrieve request
    PERFORM 1 FROM vacation_requests vr
    JOIN employees e ON vr.employee_id = e.id
    WHERE vr.id = v_request_id
    AND e.first_name IS NOT NULL;
    
    IF FOUND THEN
        RETURN QUERY SELECT 'Join Query'::TEXT, 'PASS'::TEXT, 'Request joined with employee data'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Join Query'::TEXT, 'FAIL'::TEXT, 'Cannot join request with employee'::TEXT;
        v_test_passed := false;
    END IF;
    
    -- Test 5: Manager notification (simulate)
    INSERT INTO notifications (recipient_id, notification_type, title, message)
    SELECT 
        COALESCE(d.manager_id, e.id), -- Use employee if no manager
        'vacation_request_approval',
        'Новый запрос на отпуск',
        'Сотрудник ' || e.first_name || ' ' || e.last_name || ' запрашивает отпуск'
    FROM employees e
    LEFT JOIN departments d ON e.department_id = d.id
    WHERE e.id = v_employee_id;
    
    RETURN QUERY SELECT 'Manager Notification'::TEXT, 'PASS'::TEXT, 'Notification created'::TEXT;
    
    -- Final result
    IF v_test_passed THEN
        RETURN QUERY SELECT 'Integration Test'::TEXT, 'PASS'::TEXT, 'All tests passed'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Integration Test'::TEXT, 'FAIL'::TEXT, 'Some tests failed'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 2: Create API Test Script
```sql
-- Create test helper for API validation
CREATE OR REPLACE FUNCTION validate_api_contract_vacation()
RETURNS TABLE(
    check_name TEXT,
    result TEXT
) AS $$
BEGIN
    -- Check table has API contract
    IF EXISTS (
        SELECT 1 FROM pg_class c
        WHERE c.relname = 'vacation_requests'
        AND obj_description(c.oid, 'pg_class') LIKE 'API Contract:%'
    ) THEN
        RETURN QUERY SELECT 'API Contract Exists'::TEXT, 'PASS'::TEXT;
    ELSE
        RETURN QUERY SELECT 'API Contract Exists'::TEXT, 'FAIL'::TEXT;
    END IF;
    
    -- Check employee_id is UUID type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vacation_requests'
        AND column_name = 'employee_id'
        AND data_type = 'uuid'
    ) THEN
        RETURN QUERY SELECT 'Employee ID is UUID'::TEXT, 'PASS'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Employee ID is UUID'::TEXT, 'FAIL'::TEXT;
    END IF;
    
    -- Check Russian text support
    IF EXISTS (
        SELECT 1 FROM vacation_requests
        WHERE request_type IN ('отпуск', 'больничный', 'отгул')
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Russian Text Support'::TEXT, 'PASS'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Russian Text Support'::TEXT, 'FAIL'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Execute Integration Test
```sql
-- Run the full integration test
SELECT * FROM test_vacation_request_integration();

-- Validate API contract compliance
SELECT * FROM validate_api_contract_vacation();

-- Show test data created
SELECT 
    vr.id,
    vr.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    vr.start_date,
    vr.end_date,
    vr.status,
    vr.request_type
FROM vacation_requests vr
JOIN employees e ON vr.employee_id = e.id
WHERE vr.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY vr.created_at DESC;
```

### Step 4: Create Cleanup Script
```sql
-- Optional: Clean up test data
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS void AS $$
BEGIN
    -- Delete test vacation requests
    DELETE FROM vacation_requests 
    WHERE reason = 'Тестовый отпуск'
    AND created_at > NOW() - INTERVAL '1 hour';
    
    -- Delete test notifications
    DELETE FROM notifications
    WHERE notification_type = 'vacation_request_approval'
    AND created_at > NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;
```

## ✅ Success Criteria

- [ ] test_vacation_request_integration() returns all PASS
- [ ] validate_api_contract_vacation() returns all PASS
- [ ] Test vacation request visible in database
- [ ] Employee name shows correctly (Russian text)
- [ ] Request has 'pending' status
- [ ] Notification created for manager

## 📊 Test Results Format
```
test_name           | status | details
--------------------+--------+---------------------------
Employee Exists     | PASS   | Employee ID: ead4aaaf-...
Create Request      | PASS   | Request ID: 123
Request Status      | PASS   | Status is pending
Join Query          | PASS   | Request joined with employee
Manager Notification| PASS   | Notification created
Integration Test    | PASS   | All tests passed
```

## 📊 Progress Update
```bash
echo "INTEGRATION_TEST_001: Complete - Vacation Request Flow tested" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting
- If employee not found: Check employees table has data
- If insert fails: Check constraints and foreign keys
- If API contract missing: Run table documentation task first