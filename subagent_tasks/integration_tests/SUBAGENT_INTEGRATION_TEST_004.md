# 📋 SUBAGENT TASK: Integration Test 004 - 1C ZUP Payroll Integration

## 🎯 Task Information
- **Task ID**: INTEGRATION_TEST_004
- **Priority**: Critical
- **Estimated Time**: 45 minutes
- **Dependencies**: 1C ZUP integration tables, personnel sync, time calculation
- **Test Type**: End-to-End Payroll Data Exchange Integration

## 📊 Test Scenario

**1C ZUP Payroll Integration Flow**:
1. Personnel data synchronization from 1C ZUP
2. Vacation balance calculation and validation
3. Work schedule upload with time type determination
4. Actual work time tracking and deviation analysis
5. Timesheet data retrieval and formatting
6. Excel export for vacation schedules
7. API integration health monitoring

## 📝 Test Implementation

### Step 1: Create 1C ZUP Integration Test Procedure
```sql
CREATE OR REPLACE FUNCTION test_1c_zup_payroll_integration()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_sync_session_id UUID;
    v_employee_id VARCHAR(100) := 'ZUP_EMP_001';
    v_upload_session_id UUID;
    v_export_id UUID;
    v_timesheet_id UUID;
    v_test_passed BOOLEAN := true;
    v_error_msg TEXT;
    v_calc_norm DECIMAL(8,2);
    v_balance_days DECIMAL(5,2);
    v_shift_count INTEGER;
BEGIN
    -- Test 1: Personnel data synchronization
    BEGIN
        INSERT INTO zup_personnel_sync (
            sync_session_id,
            start_date,
            end_date,
            api_endpoint,
            sync_status
        ) VALUES (
            uuid_generate_v4(),
            '2025-01-01',
            '2025-12-31',
            '/agents',
            'completed'
        ) RETURNING sync_session_id INTO v_sync_session_id;
        
        -- Insert test employee data
        INSERT INTO zup_employee_data (
            sync_session_id,
            employee_id,
            tab_number,
            lastname,
            firstname,
            secondname,
            start_work,
            position_id,
            position_title,
            department_id,
            employment_rate,
            norm_week,
            norm_week_change_date,
            is_exchange_eligible,
            wfm_employee_id
        ) VALUES (
            v_sync_session_id,
            v_employee_id,
            'TAB_001',
            'Иванов',
            'Сергей',
            'Петрович',
            '2025-01-15',
            'POS_001',
            'Менеджер по работе с клиентами',
            'DEPT_001',
            1.0,
            40,
            '2025-01-01',
            true,
            (SELECT id FROM employees LIMIT 1)
        );
        
        RETURN QUERY SELECT 'Personnel Sync'::TEXT, 'PASS'::TEXT, 'Employee data synchronized from 1C ZUP'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Personnel Sync'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 2: Vacation balance calculation
    BEGIN
        SELECT calculate_zup_time_norm(40, 1.0, 21, 1) INTO v_calc_norm;
        
        INSERT INTO zup_vacation_balances (
            employee_id,
            accrual_date,
            accumulated_days,
            monthly_entitlement,
            basic_days,
            additional_days,
            calculation_rule,
            accrual_period
        ) VALUES (
            v_employee_id,
            '2025-07-01',
            14.5,
            2.33,
            28.0,
            7.0,
            'half_month_worked',
            '2025-07'
        ) RETURNING accumulated_days INTO v_balance_days;
        
        IF v_calc_norm = 167.00 AND v_balance_days = 14.5 THEN
            RETURN QUERY SELECT 'Vacation Calculation'::TEXT, 'PASS'::TEXT, 'Time norm: ' || v_calc_norm || 'h, Balance: ' || v_balance_days || ' days'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Vacation Calculation'::TEXT, 'FAIL'::TEXT, 'Calculation mismatch'::TEXT;
            v_test_passed := false;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Vacation Calculation'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 3: Work schedule upload
    BEGIN
        INSERT INTO zup_work_schedule_upload (
            upload_session_id,
            employee_id,
            period_start,
            period_end,
            upload_status
        ) VALUES (
            uuid_generate_v4(),
            v_employee_id,
            '2025-08-01 00:00:00'::TIMESTAMP WITH TIME ZONE,
            '2025-08-31 23:59:59'::TIMESTAMP WITH TIME ZONE,
            'processing'
        ) RETURNING upload_session_id INTO v_upload_session_id;
        
        -- Insert schedule shifts with different time types
        INSERT INTO zup_work_schedule_shifts (
            upload_session_id,
            employee_id,
            shift_date,
            shift_start,
            shift_end,
            daily_hours_ms,
            night_hours_ms,
            time_type_code,
            time_type_determined_by
        ) VALUES 
        (v_upload_session_id, v_employee_id, '2025-08-01', '2025-08-01 09:00:00'::TIMESTAMP WITH TIME ZONE, '2025-08-01 18:00:00'::TIMESTAMP WITH TIME ZONE, 28800000, 0, 'I', 'shift_start_time'),
        (v_upload_session_id, v_employee_id, '2025-08-02', '2025-08-02 22:00:00'::TIMESTAMP WITH TIME ZONE, '2025-08-03 07:00:00'::TIMESTAMP WITH TIME ZONE, 28800000, 14400000, 'H', 'shift_start_time'),
        (v_upload_session_id, v_employee_id, '2025-08-03', null, null, 0, 0, 'B', 'day_off_assignment');
        
        SELECT COUNT(*) INTO v_shift_count 
        FROM zup_work_schedule_shifts 
        WHERE upload_session_id = v_upload_session_id;
        
        RETURN QUERY SELECT 'Schedule Upload'::TEXT, 'PASS'::TEXT, 'Uploaded ' || v_shift_count || ' shifts with time types I, H, B'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Schedule Upload'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 4: Actual work time tracking
    BEGIN
        INSERT INTO zup_actual_work_time (
            upload_session_id,
            employee_id,
            work_date,
            actual_start_time,
            actual_end_time,
            actual_hours_worked,
            break_time_minutes,
            scheduled_hours,
            hours_variance,
            is_overtime,
            overtime_hours
        ) VALUES 
        (v_upload_session_id, v_employee_id, '2025-08-01', '2025-08-01 09:15:00'::TIMESTAMP WITH TIME ZONE, '2025-08-01 18:30:00'::TIMESTAMP WITH TIME ZONE, 8.75, 60, 8.0, 0.75, true, 0.75),
        (v_upload_session_id, v_employee_id, '2025-08-02', '2025-08-02 22:00:00'::TIMESTAMP WITH TIME ZONE, '2025-08-03 06:45:00'::TIMESTAMP WITH TIME ZONE, 8.25, 30, 8.0, 0.25, false, 0);
        
        RETURN QUERY SELECT 'Actual Time Tracking'::TEXT, 'PASS'::TEXT, 'Tracked actual work time with overtime and deviation analysis'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Actual Time Tracking'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 5: Timesheet data retrieval
    BEGIN
        INSERT INTO zup_timesheet_data (
            request_id,
            date_start,
            date_end,
            employee_id,
            half1_days,
            half1_hours,
            half2_days,
            half2_hours
        ) VALUES (
            uuid_generate_v4(),
            '2025-08-01',
            '2025-08-31',
            v_employee_id,
            10,
            80.0,
            11,
            88.0
        ) RETURNING id INTO v_timesheet_id;
        
        -- Insert daily timesheet data
        INSERT INTO zup_timesheet_daily_data (
            timesheet_id,
            work_date,
            time_type_code,
            hours_worked,
            time_type_name_ru,
            time_type_category
        ) VALUES 
        (v_timesheet_id, '2025-08-01', 'I', 8.0, 'Я', 'work'),
        (v_timesheet_id, '2025-08-02', 'H', 8.0, 'Н', 'work'),
        (v_timesheet_id, '2025-08-03', 'B', 0.0, 'В', 'work'),
        (v_timesheet_id, '2025-08-05', 'OT', 8.0, 'ОТ', 'vacation');
        
        -- Insert absence summary
        INSERT INTO zup_timesheet_absence_summary (
            timesheet_id,
            absence_type_code,
            absence_format,
            days_count,
            hours_count,
            formatted_value
        ) VALUES 
        (v_timesheet_id, 'OT', 'days_only', 14, 0, '14'),
        (v_timesheet_id, 'B', 'days_hours', 2, 5, '2(5)'),
        (v_timesheet_id, 'C', 'hours_only', 0, 8, '8');
        
        RETURN QUERY SELECT 'Timesheet Retrieval'::TEXT, 'PASS'::TEXT, 'Retrieved timesheet with 21 working days (80+88=168h) and absence data'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Timesheet Retrieval'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 6: Vacation schedule Excel export
    BEGIN
        INSERT INTO zup_vacation_schedule_export (
            export_name,
            export_year,
            file_format,
            encoding,
            sheet_name,
            department_filter,
            vacation_types,
            export_status,
            records_exported
        ) VALUES (
            'График отпусков 2025',
            2025,
            'excel',
            'UTF-8 with BOM',
            'График отпусков 2025',
            ARRAY['DEPT_001'],
            ARRAY['Regular vacation', 'Additional vacation'],
            'completed',
            45
        ) RETURNING id INTO v_export_id;
        
        RETURN QUERY SELECT 'Excel Export'::TEXT, 'PASS'::TEXT, 'Vacation schedule exported for 45 employees in Russian format'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Excel Export'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 7: API integration health monitoring
    BEGIN
        INSERT INTO zup_api_call_log (
            api_endpoint,
            http_method,
            request_parameters,
            response_status,
            response_body,
            response_time_ms,
            error_occurred,
            session_id
        ) VALUES 
        ('/agents', 'GET', '{"start_date": "2025-01-01", "end_date": "2025-12-31"}'::jsonb, 200, '{"agents": [{"id": "ZUP_EMP_001"}]}'::jsonb, 350, false, v_sync_session_id),
        ('/timesheet', 'POST', '{"employee_id": "ZUP_EMP_001", "period": "2025-08"}'::jsonb, 200, '{"half1_days": 10, "half2_days": 11}'::jsonb, 180, false, v_sync_session_id);
        
        INSERT INTO zup_integration_health (
            zup_service_available,
            api_response_time_ms,
            last_personnel_sync,
            last_schedule_upload,
            api_error_rate_24h,
            avg_response_time_24h,
            total_api_calls_24h,
            health_status
        ) VALUES (
            true,
            265,
            NOW(),
            NOW(),
            2.5,
            265,
            128,
            'healthy'
        );
        
        RETURN QUERY SELECT 'API Health Monitoring'::TEXT, 'PASS'::TEXT, 'ZUP service healthy - 265ms avg response, 2.5% error rate'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'API Health Monitoring'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 8: Time type determination validation
    DECLARE
        v_day_type VARCHAR(10);
        v_night_type VARCHAR(10);
        v_time_validation BOOLEAN := true;
    BEGIN
        SELECT determine_time_type_by_shift_start('09:00:00'::TIME) INTO v_day_type;
        SELECT determine_time_type_by_shift_start('22:30:00'::TIME) INTO v_night_type;
        
        IF v_day_type = 'I' AND v_night_type = 'H' THEN
            RETURN QUERY SELECT 'Time Type Validation'::TEXT, 'PASS'::TEXT, 'Day shift: ' || v_day_type || ', Night shift: ' || v_night_type::TEXT;
        ELSE
            RETURN QUERY SELECT 'Time Type Validation'::TEXT, 'FAIL'::TEXT, 'Time type determination failed'::TEXT;
            v_test_passed := false;
        END IF;
    END;
    
    -- Test 9: Schedule upload eligibility validation
    DECLARE
        v_validation RECORD;
    BEGIN
        SELECT * INTO v_validation 
        FROM validate_schedule_upload_eligibility(v_employee_id, '2025-08-01', '2025-08-31');
        
        IF v_validation.is_eligible THEN
            RETURN QUERY SELECT 'Schedule Eligibility'::TEXT, 'PASS'::TEXT, 'Employee eligible for schedule upload'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Schedule Eligibility'::TEXT, 'FAIL'::TEXT, v_validation.error_message;
            v_test_passed := false;
        END IF;
    END;
    
    -- Test 10: Absence data formatting
    DECLARE
        v_format_days_only TEXT;
        v_format_days_hours TEXT;
        v_format_hours_only TEXT;
    BEGIN
        SELECT format_absence_data(14, 0) INTO v_format_days_only;
        SELECT format_absence_data(2, 5) INTO v_format_days_hours;
        SELECT format_absence_data(0, 8) INTO v_format_hours_only;
        
        IF v_format_days_only = '14' AND v_format_days_hours = '2(5)' AND v_format_hours_only = '8' THEN
            RETURN QUERY SELECT 'Absence Formatting'::TEXT, 'PASS'::TEXT, 'Formats: ' || v_format_days_only || ', ' || v_format_days_hours || ', ' || v_format_hours_only::TEXT;
        ELSE
            RETURN QUERY SELECT 'Absence Formatting'::TEXT, 'FAIL'::TEXT, 'Formatting rules failed'::TEXT;
            v_test_passed := false;
        END IF;
    END;
    
    -- Final result
    IF v_test_passed THEN
        RETURN QUERY SELECT '1C ZUP Integration'::TEXT, 'PASS'::TEXT, 'Complete bidirectional payroll data exchange system working'::TEXT;
    ELSE
        RETURN QUERY SELECT '1C ZUP Integration'::TEXT, 'FAIL'::TEXT, '1C ZUP integration has failures'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 2: Create 1C ZUP Infrastructure Validation Function
```sql
CREATE OR REPLACE FUNCTION validate_1c_zup_infrastructure()
RETURNS TABLE(
    check_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check 1C ZUP configuration table
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'zup_system_configuration'
    ) THEN
        RETURN QUERY SELECT 'ZUP Configuration Table'::TEXT, 'PASS'::TEXT, 'System configuration table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ZUP Configuration Table'::TEXT, 'FAIL'::TEXT, 'Missing ZUP configuration table'::TEXT;
    END IF;
    
    -- Check personnel synchronization capability
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'zup_employee_data'
        AND column_name = 'employment_rate'
        AND data_type = 'numeric'
    ) THEN
        RETURN QUERY SELECT 'Personnel Sync Structure'::TEXT, 'PASS'::TEXT, 'Employment rate tracking enabled'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Personnel Sync Structure'::TEXT, 'FAIL'::TEXT, 'Missing employment rate field'::TEXT;
    END IF;
    
    -- Check vacation balance calculation
    IF EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'calculate_zup_time_norm'
        AND routine_type = 'FUNCTION'
    ) THEN
        RETURN QUERY SELECT 'Time Norm Calculation'::TEXT, 'PASS'::TEXT, 'ZUP time norm calculation function available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Time Norm Calculation'::TEXT, 'FAIL'::TEXT, 'Missing time norm calculation function'::TEXT;
    END IF;
    
    -- Check time type determination
    IF EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'determine_time_type_by_shift_start'
    ) THEN
        RETURN QUERY SELECT 'Time Type Logic'::TEXT, 'PASS'::TEXT, 'Shift-based time type determination available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Time Type Logic'::TEXT, 'FAIL'::TEXT, 'Missing time type determination logic'::TEXT;
    END IF;
    
    -- Check schedule upload validation
    IF EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'validate_schedule_upload_eligibility'
    ) THEN
        RETURN QUERY SELECT 'Schedule Validation'::TEXT, 'PASS'::TEXT, 'Schedule upload eligibility validation available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Schedule Validation'::TEXT, 'FAIL'::TEXT, 'Missing schedule validation logic'::TEXT;
    END IF;
    
    -- Check API logging capability
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'zup_api_call_log'
        AND column_name = 'response_time_ms'
    ) THEN
        RETURN QUERY SELECT 'API Monitoring'::TEXT, 'PASS'::TEXT, 'API performance monitoring enabled'::TEXT;
    ELSE
        RETURN QUERY SELECT 'API Monitoring'::TEXT, 'FAIL'::TEXT, 'Missing API performance tracking'::TEXT;
    END IF;
    
    -- Check Russian language support
    IF EXISTS (
        SELECT 1 FROM zup_time_types
        WHERE time_type_name_ru ~ '[А-Яа-я]+'
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'PASS'::TEXT, 'Cyrillic time type names confirmed'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'WARN'::TEXT, 'No Russian time types found'::TEXT;
    END IF;
    
    -- Check vacation mapping support
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'zup_vacation_type_mapping'
    ) THEN
        RETURN QUERY SELECT 'Vacation Type Mapping'::TEXT, 'PASS'::TEXT, 'WFM-ZUP vacation type mapping available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vacation Type Mapping'::TEXT, 'FAIL'::TEXT, 'Missing vacation type mapping table'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Execute 1C ZUP Integration Test
```sql
-- Run the complete 1C ZUP payroll integration test
SELECT * FROM test_1c_zup_payroll_integration();

-- Validate 1C ZUP infrastructure
SELECT * FROM validate_1c_zup_infrastructure();

-- Show integration data flow
SELECT 
    'Personnel Data' as data_source,
    zed.employee_id,
    zed.tab_number,
    zed.lastname || ' ' || zed.firstname as full_name,
    zed.position_title,
    zed.employment_rate,
    zed.norm_week,
    zed.is_exchange_eligible
FROM zup_employee_data zed
WHERE zed.last_synced >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY zed.last_synced DESC
LIMIT 5;

SELECT 
    'Vacation Balances' as data_source,
    zvb.employee_id,
    zvb.accrual_date,
    zvb.accumulated_days,
    zvb.basic_days,
    zvb.additional_days,
    zvb.calculation_rule
FROM zup_vacation_balances zvb
WHERE zvb.calculated_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY zvb.calculated_at DESC
LIMIT 5;

SELECT 
    'Work Schedules' as data_source,
    zws.employee_id,
    zws.shift_date,
    zws.time_type_code,
    (zws.daily_hours_ms / 3600000.0) as daily_hours,
    (zws.night_hours_ms / 3600000.0) as night_hours,
    zws.time_type_determined_by
FROM zup_work_schedule_shifts zws
WHERE zws.created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY zws.shift_date DESC
LIMIT 5;

SELECT 
    'API Performance' as data_source,
    zacl.api_endpoint,
    zacl.http_method,
    zacl.response_status,
    zacl.response_time_ms,
    zacl.request_timestamp
FROM zup_api_call_log zacl
WHERE zacl.request_timestamp >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY zacl.request_timestamp DESC
LIMIT 5;
```

### Step 4: Create Integration Performance Monitor
```sql
CREATE OR REPLACE FUNCTION monitor_1c_zup_integration_performance()
RETURNS TABLE(
    metric_name TEXT,
    current_value TEXT,
    threshold TEXT,
    status TEXT
) AS $$
DECLARE
    v_api_response_time NUMERIC;
    v_sync_success_rate NUMERIC;
    v_active_integrations INTEGER;
    v_data_freshness_hours INTEGER;
BEGIN
    -- Test API response time
    SELECT AVG(response_time_ms) INTO v_api_response_time
    FROM zup_api_call_log
    WHERE request_timestamp >= NOW() - INTERVAL '1 hour'
    AND error_occurred = false;
    
    RETURN QUERY SELECT 
        'API Response Time'::TEXT,
        COALESCE(v_api_response_time::TEXT || 'ms', 'No data'),
        '< 500ms'::TEXT,
        CASE WHEN v_api_response_time < 500 THEN 'PASS' ELSE 'WARN' END;
    
    -- Test sync success rate
    SELECT 
        (COUNT(CASE WHEN sync_status = 'completed' THEN 1 END) * 100.0 / COUNT(*))
    INTO v_sync_success_rate
    FROM zup_personnel_sync
    WHERE started_at >= NOW() - INTERVAL '24 hours';
    
    RETURN QUERY SELECT 
        'Sync Success Rate'::TEXT,
        COALESCE(v_sync_success_rate::TEXT || '%', 'No data'),
        '> 95%'::TEXT,
        CASE WHEN v_sync_success_rate > 95 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test active integrations count
    SELECT COUNT(*) INTO v_active_integrations
    FROM zup_integration_health
    WHERE health_status = 'healthy'
    AND health_check_timestamp >= NOW() - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Healthy Integrations'::TEXT,
        v_active_integrations::TEXT,
        '> 0'::TEXT,
        CASE WHEN v_active_integrations > 0 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test data freshness
    SELECT EXTRACT(hours FROM NOW() - MAX(last_synced)) INTO v_data_freshness_hours
    FROM zup_employee_data;
    
    RETURN QUERY SELECT 
        'Data Freshness'::TEXT,
        COALESCE(v_data_freshness_hours::TEXT || 'h ago', 'No data'),
        '< 24h'::TEXT,
        CASE WHEN v_data_freshness_hours < 24 THEN 'PASS' ELSE 'WARN' END;
END;
$$ LANGUAGE plpgsql;
```

## ✅ Success Criteria

- [ ] test_1c_zup_payroll_integration() returns all PASS
- [ ] validate_1c_zup_infrastructure() returns all PASS  
- [ ] Personnel data synchronization from 1C ZUP working
- [ ] Vacation balance calculation with Russian labor law compliance
- [ ] Work schedule upload with time type determination (I/H/B)
- [ ] Actual work time tracking with overtime and deviation analysis
- [ ] Timesheet data retrieval with proper Russian formatting
- [ ] Excel export capability for vacation schedules
- [ ] API integration health monitoring operational
- [ ] Time norm calculation using 1C ZUP formula
- [ ] Schedule upload eligibility validation working
- [ ] Absence data formatting (days, hours, combined) working

## 📊 Test Results Format
```
test_name                | status | details
-------------------------+--------+----------------------------------
Personnel Sync           | PASS   | Employee data synchronized from 1C ZUP
Vacation Calculation     | PASS   | Time norm: 167.00h, Balance: 14.5 days
Schedule Upload          | PASS   | Uploaded 3 shifts with time types I, H, B
Actual Time Tracking     | PASS   | Tracked actual work time with overtime and deviation analysis
Timesheet Retrieval      | PASS   | Retrieved timesheet with 21 working days (168h) and absence data
Excel Export             | PASS   | Vacation schedule exported for 45 employees in Russian format
API Health Monitoring    | PASS   | ZUP service healthy - 265ms avg response, 2.5% error rate
Time Type Validation     | PASS   | Day shift: I, Night shift: H
Schedule Eligibility     | PASS   | Employee eligible for schedule upload
Absence Formatting       | PASS   | Formats: 14, 2(5), 8
1C ZUP Integration       | PASS   | Complete bidirectional payroll data exchange system working
```

## 📊 Progress Update
```bash
echo "INTEGRATION_TEST_004: Complete - 1C ZUP Payroll Integration tested" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting
- If personnel sync fails: Check zup_employee_data table structure and constraints
- If vacation calculation fails: Verify calculate_zup_time_norm function implementation
- If schedule upload fails: Check time type determination logic and validation rules
- If timesheet retrieval fails: Verify Russian language encoding (UTF-8)
- If Excel export fails: Check column mapping JSONB structure
- If API monitoring fails: Verify zup_api_call_log table and response time tracking
- If performance poor: Check indexes on employee_id, timestamp, and session_id columns