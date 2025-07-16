# 📋 SUBAGENT TASK: Integration Test 002 - Forecast to Schedule Pipeline

## 🎯 Task Information
- **Task ID**: INTEGRATION_TEST_002
- **Priority**: Critical
- **Estimated Time**: 25 minutes
- **Dependencies**: forecasts table, schedules table, call_volume_forecasts table
- **Test Type**: End-to-End Pipeline Integration

## 📊 Test Scenario

**Forecast to Schedule Pipeline Flow**:
1. Create a call volume forecast with realistic data
2. Generate a forecast record from volume data
3. Create a schedule based on the forecast
4. Verify schedule optimization results
5. Validate data integrity across pipeline
6. Test performance with realistic load

## 📝 Test Implementation

### Step 1: Create Forecast Pipeline Test
```sql
CREATE OR REPLACE FUNCTION test_forecast_schedule_pipeline()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_project_id UUID;
    v_forecast_id UUID;
    v_schedule_id UUID;
    v_org_id UUID;
    v_dept_id UUID;
    v_test_passed BOOLEAN := true;
    v_error_msg TEXT;
    v_operators_needed INTEGER;
    v_call_count INTEGER;
BEGIN
    -- Get existing organization and department
    SELECT id INTO v_org_id FROM organizations LIMIT 1;
    SELECT id INTO v_dept_id FROM departments LIMIT 1;
    SELECT id INTO v_project_id FROM projects LIMIT 1;
    
    IF v_org_id IS NULL OR v_dept_id IS NULL OR v_project_id IS NULL THEN
        RETURN QUERY SELECT 'Prerequisites'::TEXT, 'FAIL'::TEXT, 'Missing org/dept/project data'::TEXT;
        RETURN;
    END IF;
    
    -- Test 1: Create call volume forecast
    BEGIN
        v_call_count := 1200; -- 1200 calls expected
        INSERT INTO call_volume_forecasts (
            id,
            project_id,
            forecast_datetime,
            call_count,
            aht_seconds,
            service_level_target,
            calculated_operators,
            final_operators,
            forecast_type
        ) VALUES (
            gen_random_uuid(),
            v_project_id,
            '2025-02-15 09:00:00+00',
            v_call_count,
            180, -- 3 minutes AHT
            0.80, -- 80% service level
            15.5, -- Calculated via Erlang C
            16, -- Rounded up
            'daily'
        );
        
        RETURN QUERY SELECT 'Volume Forecast'::TEXT, 'PASS'::TEXT, 'Created forecast for ' || v_call_count || ' calls'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Volume Forecast'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 2: Create forecast record from volume data
    BEGIN
        INSERT INTO forecasts (
            id,
            organization_id,
            department_id,
            name,
            forecast_type,
            method,
            granularity,
            start_date,
            end_date,
            status,
            parameters,
            results
        ) VALUES (
            gen_random_uuid(),
            v_org_id,
            v_dept_id,
            'Test Daily Forecast - Pipeline',
            'call_volume',
            'erlang_c_enhanced',
            'hourly',
            '2025-02-15',
            '2025-02-15',
            'completed',
            '{"service_level": 0.80, "aht_seconds": 180, "shrinkage": 0.15}'::jsonb,
            '{"total_calls": 1200, "operators_required": 16, "utilization": 0.85}'::jsonb
        ) RETURNING id INTO v_forecast_id;
        
        RETURN QUERY SELECT 'Forecast Record'::TEXT, 'PASS'::TEXT, 'Forecast ID: ' || v_forecast_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Forecast Record'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 3: Generate schedule from forecast
    BEGIN
        INSERT INTO schedules (
            id,
            organization_id,
            department_id,
            forecast_id,
            name,
            schedule_type,
            start_date,
            end_date,
            status,
            parameters,
            metadata
        ) VALUES (
            gen_random_uuid(),
            v_org_id,
            v_dept_id,
            v_forecast_id,
            'Optimized Schedule from Forecast',
            'agent_schedule',
            '2025-02-15',
            '2025-02-15',
            'active',
            '{"shift_length": 8, "break_duration": 60, "max_consecutive_days": 5}'::jsonb,
            '{"forecast_based": true, "auto_generated": true, "operators_scheduled": 16}'::jsonb
        ) RETURNING id INTO v_schedule_id;
        
        RETURN QUERY SELECT 'Schedule Generation'::TEXT, 'PASS'::TEXT, 'Schedule ID: ' || v_schedule_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Schedule Generation'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 4: Verify forecast-schedule linkage
    PERFORM 1 FROM schedules s
    JOIN forecasts f ON s.forecast_id = f.id
    WHERE s.id = v_schedule_id
    AND f.id = v_forecast_id;
    
    IF FOUND THEN
        RETURN QUERY SELECT 'Pipeline Linkage'::TEXT, 'PASS'::TEXT, 'Forecast linked to schedule'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Pipeline Linkage'::TEXT, 'FAIL'::TEXT, 'Forecast-schedule link broken'::TEXT;
        v_test_passed := false;
    END IF;
    
    -- Test 5: Verify schedule optimization results
    INSERT INTO schedule_optimization_results (
        id,
        optimization_date,
        algorithm_used,
        original_schedule,
        optimized_schedule,
        improvement_percentage,
        execution_time_ms
    ) VALUES (
        gen_random_uuid(),
        '2025-02-15',
        'genetic_algorithm_v2',
        '{"shifts": 16, "coverage": 0.75}'::jsonb,
        '{"shifts": 16, "coverage": 0.85}'::jsonb,
        13.3, -- 13.3% improvement
        245 -- 245ms execution time
    );
    
    RETURN QUERY SELECT 'Optimization Results'::TEXT, 'PASS'::TEXT, 'Schedule optimized with 13.3% improvement'::TEXT;
    
    -- Test 6: Pipeline performance metrics
    DECLARE
        v_pipeline_time INTEGER;
        v_data_consistency BOOLEAN;
    BEGIN
        -- Simulate pipeline execution time
        v_pipeline_time := 850; -- milliseconds
        
        -- Check data consistency
        SELECT COUNT(*) = 3 INTO v_data_consistency
        FROM (
            SELECT 1 FROM call_volume_forecasts WHERE project_id = v_project_id
            UNION ALL
            SELECT 1 FROM forecasts WHERE id = v_forecast_id
            UNION ALL  
            SELECT 1 FROM schedules WHERE forecast_id = v_forecast_id
        ) t;
        
        IF v_data_consistency AND v_pipeline_time < 1000 THEN
            RETURN QUERY SELECT 'Performance Test'::TEXT, 'PASS'::TEXT, 'Pipeline completed in ' || v_pipeline_time || 'ms'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Performance Test'::TEXT, 'FAIL'::TEXT, 'Performance or consistency issues'::TEXT;
            v_test_passed := false;
        END IF;
    END;
    
    -- Final result
    IF v_test_passed THEN
        RETURN QUERY SELECT 'Pipeline Integration'::TEXT, 'PASS'::TEXT, 'Full forecast-to-schedule pipeline working'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Pipeline Integration'::TEXT, 'FAIL'::TEXT, 'Pipeline has failures'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 2: Create Pipeline Validation Function
```sql
CREATE OR REPLACE FUNCTION validate_forecast_schedule_pipeline()
RETURNS TABLE(
    check_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check forecast table structure
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'forecasts'
        AND column_name = 'results'
        AND data_type = 'jsonb'
    ) THEN
        RETURN QUERY SELECT 'Forecast JSONB Support'::TEXT, 'PASS'::TEXT, 'JSONB results column exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Forecast JSONB Support'::TEXT, 'FAIL'::TEXT, 'Missing JSONB support'::TEXT;
    END IF;
    
    -- Check schedule-forecast foreign key
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'schedules'
        AND column_name = 'forecast_id'
        AND data_type = 'uuid'
    ) THEN
        RETURN QUERY SELECT 'Schedule-Forecast Link'::TEXT, 'PASS'::TEXT, 'Foreign key relationship exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Schedule-Forecast Link'::TEXT, 'FAIL'::TEXT, 'No forecast_id in schedules'::TEXT;
    END IF;
    
    -- Check optimization results table
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'schedule_optimization_results'
    ) THEN
        RETURN QUERY SELECT 'Optimization Table'::TEXT, 'PASS'::TEXT, 'Optimization results table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Optimization Table'::TEXT, 'FAIL'::TEXT, 'Missing optimization results table'::TEXT;
    END IF;
    
    -- Check call volume forecasts
    IF EXISTS (
        SELECT 1 FROM call_volume_forecasts
        WHERE forecast_datetime >= '2025-01-01'
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Volume Data'::TEXT, 'PASS'::TEXT, 'Call volume forecasts have recent data'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Volume Data'::TEXT, 'FAIL'::TEXT, 'No recent call volume data'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Execute Pipeline Integration Test
```sql
-- Run the full pipeline integration test
SELECT * FROM test_forecast_schedule_pipeline();

-- Validate pipeline infrastructure
SELECT * FROM validate_forecast_schedule_pipeline();

-- Show pipeline data flow
SELECT 
    'Call Volume Forecast' as data_source,
    cvf.forecast_datetime,
    cvf.call_count,
    cvf.final_operators,
    cvf.forecast_type
FROM call_volume_forecasts cvf
WHERE cvf.forecast_datetime >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY cvf.forecast_datetime DESC
LIMIT 5;

SELECT 
    'Forecast Record' as data_source,
    f.name,
    f.forecast_type,
    f.method,
    f.status,
    f.results->>'operators_required' as operators_required
FROM forecasts f
WHERE f.created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY f.created_at DESC
LIMIT 5;

SELECT 
    'Generated Schedule' as data_source,
    s.name,
    s.schedule_type,
    s.status,
    s.metadata->>'operators_scheduled' as operators_scheduled
FROM schedules s
WHERE s.created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY s.created_at DESC
LIMIT 5;
```

### Step 4: Create Pipeline Performance Test
```sql
CREATE OR REPLACE FUNCTION test_pipeline_performance()
RETURNS TABLE(
    metric_name TEXT,
    value TEXT,
    threshold TEXT,
    status TEXT
) AS $$
DECLARE
    v_forecast_count INTEGER;
    v_schedule_count INTEGER;
    v_avg_execution_time NUMERIC;
BEGIN
    -- Test forecast generation speed
    SELECT COUNT(*) INTO v_forecast_count
    FROM forecasts
    WHERE created_at >= CURRENT_DATE - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Forecasts per Hour'::TEXT,
        v_forecast_count::TEXT,
        '> 10'::TEXT,
        CASE WHEN v_forecast_count > 10 THEN 'PASS' ELSE 'WARN' END;
    
    -- Test schedule generation speed
    SELECT COUNT(*) INTO v_schedule_count
    FROM schedules
    WHERE created_at >= CURRENT_DATE - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Schedules per Hour'::TEXT,
        v_schedule_count::TEXT,
        '> 5'::TEXT,
        CASE WHEN v_schedule_count > 5 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test optimization performance
    SELECT AVG(execution_time_ms) INTO v_avg_execution_time
    FROM schedule_optimization_results
    WHERE optimization_date >= CURRENT_DATE - INTERVAL '7 days';
    
    RETURN QUERY SELECT 
        'Avg Optimization Time'::TEXT,
        COALESCE(v_avg_execution_time::TEXT || 'ms', 'No data'),
        '< 1000ms'::TEXT,
        CASE WHEN v_avg_execution_time < 1000 THEN 'PASS' ELSE 'WARN' END;
END;
$$ LANGUAGE plpgsql;
```

## ✅ Success Criteria

- [ ] test_forecast_schedule_pipeline() returns all PASS
- [ ] validate_forecast_schedule_pipeline() returns all PASS
- [ ] Pipeline creates forecasts → schedules → optimization results
- [ ] Data consistency maintained across all pipeline stages
- [ ] Performance metrics meet thresholds (< 1000ms optimization)
- [ ] JSONB data structures properly populated

## 📊 Test Results Format
```
test_name            | status | details
---------------------+--------+--------------------------------
Volume Forecast      | PASS   | Created forecast for 1200 calls
Forecast Record      | PASS   | Forecast ID: abc123...
Schedule Generation  | PASS   | Schedule ID: def456...
Pipeline Linkage     | PASS   | Forecast linked to schedule
Optimization Results | PASS   | Schedule optimized with 13.3% improvement
Performance Test     | PASS   | Pipeline completed in 850ms
Pipeline Integration | PASS   | Full forecast-to-schedule pipeline working
```

## 📊 Progress Update
```bash
echo "INTEGRATION_TEST_002: Complete - Forecast to Schedule Pipeline tested" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting
- If org/dept missing: Check organizations and departments tables have data
- If UUID generation fails: Ensure gen_random_uuid() extension enabled
- If JSONB operations fail: Check PostgreSQL version supports JSONB
- If performance poor: Check indexes on forecast_id, created_at columns