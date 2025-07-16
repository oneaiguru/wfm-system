# 📋 SUBAGENT TASK: BDD Scenario 006 - Shift Exchange Request

## 🎯 Task Information
- **Task ID**: BDD_SCENARIO_006
- **Priority**: Critical
- **Estimated Time**: 30 minutes
- **Dependencies**: Tables must exist, employees data loaded
- **BDD File**: `/intelligence/argus/bdd-specifications/06-complete-navigation-exchange-system.feature`

## 📊 BDD Scenario Details

**Scenario**: Employee requests shift exchange with colleague
```gherkin
Given I am logged in as employee "Иван Петров"
And I have a shift on "2025-02-15" from "09:00" to "17:00"
And employee "Мария Иванова" has a shift on "2025-02-16" from "09:00" to "17:00"
When I request to exchange shifts with "Мария Иванова"
Then the exchange request should be created with status "pending"
And "Мария Иванова" should receive a notification
And our manager should be notified for approval
```

## 📝 Implementation Steps

### Step 1: Create/Verify Tables
```sql
-- Ensure shift_exchange_requests table exists
CREATE TABLE IF NOT EXISTS shift_exchange_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES employees(id),
    target_employee_id UUID NOT NULL REFERENCES employees(id),
    requester_shift_id UUID NOT NULL,
    target_shift_id UUID NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add API contract
COMMENT ON TABLE shift_exchange_requests IS
'API Contract: POST /api/v1/shift-exchange/request
expects: {requester_id: UUID, target_employee_id: UUID, requester_shift_date: YYYY-MM-DD, target_shift_date: YYYY-MM-DD, reason?: string}
returns: {id: UUID, status: string, created_at: timestamp}

Helper Queries:
-- Create exchange request
INSERT INTO shift_exchange_requests (requester_id, target_employee_id, requester_shift_id, target_shift_id, reason)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, status, created_at;

-- Get pending requests for employee
SELECT 
    ser.*,
    e1.first_name || '' '' || e1.last_name as requester_name,
    e2.first_name || '' '' || e2.last_name as target_name
FROM shift_exchange_requests ser
JOIN employees e1 ON ser.requester_id = e1.id
JOIN employees e2 ON ser.target_employee_id = e2.id
WHERE (ser.requester_id = $1 OR ser.target_employee_id = $1)
    AND ser.status = ''pending'';';

-- Create employee_shifts table if needed
CREATE TABLE IF NOT EXISTS employee_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    shift_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Step 2: Create Test Data
```sql
-- Get employee IDs
DO $$
DECLARE
    v_ivan_id UUID;
    v_maria_id UUID;
    v_ivan_shift_id UUID;
    v_maria_shift_id UUID;
BEGIN
    -- Get Иван's ID
    SELECT id INTO v_ivan_id FROM employees WHERE first_name = 'Иван' AND last_name = 'Петров' LIMIT 1;
    IF v_ivan_id IS NULL THEN
        SELECT id INTO v_ivan_id FROM employees WHERE first_name = 'Иван' LIMIT 1;
    END IF;
    
    -- Get Мария's ID
    SELECT id INTO v_maria_id FROM employees WHERE first_name = 'Мария' AND last_name = 'Иванова' LIMIT 1;
    IF v_maria_id IS NULL THEN
        SELECT id INTO v_maria_id FROM employees WHERE first_name = 'Мария' LIMIT 1;
    END IF;
    
    -- Create shifts
    INSERT INTO employee_shifts (id, employee_id, shift_date, shift_start, shift_end)
    VALUES 
        (gen_random_uuid(), v_ivan_id, '2025-02-15', '09:00', '17:00'),
        (gen_random_uuid(), v_maria_id, '2025-02-16', '09:00', '17:00')
    RETURNING id INTO v_ivan_shift_id;
    
    -- Get shift IDs
    SELECT id INTO v_ivan_shift_id FROM employee_shifts WHERE employee_id = v_ivan_id AND shift_date = '2025-02-15';
    SELECT id INTO v_maria_shift_id FROM employee_shifts WHERE employee_id = v_maria_id AND shift_date = '2025-02-16';
    
    -- Create exchange request
    INSERT INTO shift_exchange_requests (requester_id, target_employee_id, requester_shift_id, target_shift_id, reason)
    VALUES (v_ivan_id, v_maria_id, v_ivan_shift_id, v_maria_shift_id, 'Личные обстоятельства');
    
    RAISE NOTICE 'Created shift exchange request between % and %', v_ivan_id, v_maria_id;
END $$;
```

### Step 3: Create Notification Records
```sql
-- Create notifications table if needed
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES employees(id),
    notification_type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert notifications
INSERT INTO notifications (recipient_id, notification_type, title, message)
SELECT 
    target_employee_id,
    'shift_exchange_request',
    'Запрос на обмен сменами',
    'Сотрудник ' || (SELECT first_name || ' ' || last_name FROM employees WHERE id = ser.requester_id) || ' запрашивает обмен сменами'
FROM shift_exchange_requests ser
WHERE ser.created_at > NOW() - INTERVAL '1 minute';

-- Manager notification
INSERT INTO notifications (recipient_id, notification_type, title, message)
SELECT DISTINCT
    d.manager_id,
    'shift_exchange_approval',
    'Требуется одобрение обмена сменами',
    'Запрос на обмен сменами между сотрудниками требует вашего одобрения'
FROM shift_exchange_requests ser
JOIN employees e ON ser.requester_id = e.id
JOIN departments d ON e.department_id = d.id
WHERE ser.created_at > NOW() - INTERVAL '1 minute'
    AND d.manager_id IS NOT NULL;
```

### Step 4: Verify Implementation
```sql
-- Test the complete flow
SELECT 
    'Shift Exchange Request' as test_name,
    COUNT(*) as requests_created,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_requests
FROM shift_exchange_requests
WHERE created_at > NOW() - INTERVAL '5 minutes';

-- Check notifications
SELECT 
    'Notifications' as test_name,
    COUNT(*) as total_notifications,
    COUNT(*) FILTER (WHERE notification_type = 'shift_exchange_request') as employee_notifications,
    COUNT(*) FILTER (WHERE notification_type = 'shift_exchange_approval') as manager_notifications
FROM notifications
WHERE created_at > NOW() - INTERVAL '5 minutes';

-- Verify complete scenario
SELECT 
    ser.id,
    e1.first_name || ' ' || e1.last_name as requester,
    e2.first_name || ' ' || e2.last_name as target,
    ser.status,
    ser.created_at
FROM shift_exchange_requests ser
JOIN employees e1 ON ser.requester_id = e1.id
JOIN employees e2 ON ser.target_employee_id = e2.id
WHERE ser.created_at > NOW() - INTERVAL '5 minutes';
```

## ✅ Success Criteria

- [ ] shift_exchange_requests table created with constraints
- [ ] API contract documented
- [ ] Test data created with Иван and Мария
- [ ] Exchange request created with status 'pending'
- [ ] Notification sent to target employee
- [ ] Manager notification created
- [ ] All queries return expected results

## 📊 Progress Update
```bash
echo "BDD_SCENARIO_006: Complete - Shift Exchange Request implemented" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Error Handling
- If employees don't exist, create them first
- If manager_id is NULL, skip manager notification
- Document any deviations in progress log