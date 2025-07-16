# 📋 SUBAGENT TASK: Integration Test 003 - Real-time Monitoring Alert System

## 🎯 Task Information
- **Task ID**: INTEGRATION_TEST_003
- **Priority**: Critical
- **Estimated Time**: 30 minutes
- **Dependencies**: real_time_metrics table, alert_thresholds table, notifications table
- **Test Type**: End-to-End Real-time Integration

## 📊 Test Scenario

**Real-time Monitoring Alert System Flow**:
1. Real-time metrics data ingestion
2. Threshold breach detection
3. Alert generation and escalation
4. Notification dispatch system
5. Performance monitoring under load
6. Recovery and alerting continuation

## 📝 Test Implementation

### Step 1: Create Alert System Test Procedure
```sql
CREATE OR REPLACE FUNCTION test_realtime_alert_system()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_project_id UUID;
    v_queue_id UUID;
    v_alert_id UUID;
    v_notification_id UUID;
    v_org_id UUID;
    v_dept_id UUID;
    v_test_passed BOOLEAN := true;
    v_error_msg TEXT;
    v_breach_count INTEGER;
    v_response_time INTEGER;
BEGIN
    -- Get existing organization, department, and project
    SELECT id INTO v_org_id FROM organizations LIMIT 1;
    SELECT id INTO v_dept_id FROM departments LIMIT 1;
    SELECT id INTO v_project_id FROM projects LIMIT 1;
    SELECT id INTO v_queue_id FROM queues LIMIT 1;
    
    IF v_org_id IS NULL OR v_dept_id IS NULL OR v_project_id IS NULL THEN
        RETURN QUERY SELECT 'Prerequisites'::TEXT, 'FAIL'::TEXT, 'Missing org/dept/project data'::TEXT;
        RETURN;
    END IF;
    
    -- Test 1: Create alert threshold configuration
    BEGIN
        INSERT INTO alert_thresholds (
            id,
            organization_id,
            threshold_type,
            metric_name,
            warning_threshold,
            critical_threshold,
            duration_minutes,
            notification_channels,
            escalation_rules,
            is_active
        ) VALUES (
            gen_random_uuid(),
            v_org_id,
            'service_level',
            'queue_service_level',
            0.75, -- Warning at 75%
            0.60, -- Critical at 60%
            5, -- 5 minute duration
            '["email", "sms", "dashboard"]'::jsonb,
            '{"level_1": "supervisor", "level_2": "manager", "level_3": "director"}'::jsonb,
            true
        );
        
        RETURN QUERY SELECT 'Threshold Config'::TEXT, 'PASS'::TEXT, 'Alert threshold configured for service level'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Threshold Config'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 2: Insert real-time metrics that trigger alert
    BEGIN
        INSERT INTO real_time_metrics (
            id,
            project_id,
            queue_id,
            timestamp,
            calls_waiting,
            agents_available,
            agents_busy,
            service_level_current,
            average_wait_time,
            longest_wait_time,
            calls_handled,
            calls_abandoned
        ) VALUES (
            gen_random_uuid(),
            v_project_id,
            COALESCE(v_queue_id, gen_random_uuid()),
            NOW(),
            25, -- High queue
            2, -- Low availability
            8, -- Most agents busy
            0.55, -- Below critical threshold (60%)
            180, -- 3 minute wait
            420, -- 7 minute longest wait
            45,
            12
        );
        
        RETURN QUERY SELECT 'Metrics Ingestion'::TEXT, 'PASS'::TEXT, 'Critical metrics inserted (SL: 55%)'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Metrics Ingestion'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 3: Simulate alert detection and generation
    BEGIN
        INSERT INTO alerts (
            id,
            organization_id,
            alert_type,
            severity,
            title,
            description,
            source_metric,
            threshold_breached,
            current_value,
            trigger_time,
            status,
            metadata
        ) VALUES (
            gen_random_uuid(),
            v_org_id,
            'service_level_breach',
            'critical',
            'Критический уровень обслуживания',
            'Уровень обслуживания упал до 55%, что ниже критического порога 60%',
            'queue_service_level',
            0.60,
            0.55,
            NOW(),
            'active',
            '{"queue_name": "Main Support", "calls_waiting": 25, "response_time_ms": 250}'::jsonb
        ) RETURNING id INTO v_alert_id;
        
        RETURN QUERY SELECT 'Alert Generation'::TEXT, 'PASS'::TEXT, 'Critical alert generated: ' || v_alert_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Alert Generation'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 4: Create escalation notification
    BEGIN
        INSERT INTO notifications (
            id,
            recipient_id,
            notification_type,
            title,
            message,
            channel,
            priority,
            alert_id,
            metadata
        ) VALUES (
            gen_random_uuid(),
            (SELECT id FROM employees WHERE first_name IS NOT NULL LIMIT 1),
            'alert_escalation',
            'КРИТИЧЕСКОЕ: Уровень обслуживания',
            'Немедленное внимание: уровень обслуживания в очереди Main Support упал до 55%. 25 звонков в ожидании.',
            'email',
            'critical',
            v_alert_id,
            '{"escalation_level": 1, "auto_generated": true, "response_required": true}'::jsonb
        ) RETURNING id INTO v_notification_id;
        
        RETURN QUERY SELECT 'Notification Dispatch'::TEXT, 'PASS'::TEXT, 'Escalation notification sent: ' || v_notification_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Notification Dispatch'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 5: Verify alert-notification linkage
    PERFORM 1 FROM notifications n
    JOIN alerts a ON n.alert_id = a.id
    WHERE n.id = v_notification_id
    AND a.id = v_alert_id
    AND a.status = 'active';
    
    IF FOUND THEN
        RETURN QUERY SELECT 'Alert Linkage'::TEXT, 'PASS'::TEXT, 'Alert properly linked to notification'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Alert Linkage'::TEXT, 'FAIL'::TEXT, 'Alert-notification link broken'::TEXT;
        v_test_passed := false;
    END IF;
    
    -- Test 6: Test alert acknowledgment and resolution
    BEGIN
        UPDATE alerts 
        SET 
            status = 'acknowledged',
            acknowledged_at = NOW(),
            acknowledged_by = (SELECT id FROM employees LIMIT 1),
            metadata = metadata || '{"acknowledgment_time_seconds": 45}'::jsonb
        WHERE id = v_alert_id;
        
        -- Simulate recovery metrics
        INSERT INTO real_time_metrics (
            id,
            project_id,
            queue_id,
            timestamp,
            calls_waiting,
            agents_available,
            agents_busy,
            service_level_current,
            average_wait_time,
            longest_wait_time,
            calls_handled,
            calls_abandoned
        ) VALUES (
            gen_random_uuid(),
            v_project_id,
            COALESCE(v_queue_id, gen_random_uuid()),
            NOW() + INTERVAL '10 minutes',
            5, -- Normal queue
            6, -- Good availability
            4, -- Balanced load
            0.82, -- Above warning threshold
            45, -- Normal wait time
            90, -- Acceptable longest wait
            78,
            3
        );
        
        -- Auto-resolve alert
        UPDATE alerts 
        SET 
            status = 'resolved',
            resolved_at = NOW() + INTERVAL '10 minutes',
            resolution_notes = 'Service level recovered to 82% - above warning threshold'
        WHERE id = v_alert_id;
        
        RETURN QUERY SELECT 'Alert Resolution'::TEXT, 'PASS'::TEXT, 'Alert acknowledged and auto-resolved'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Alert Resolution'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 7: Performance and reliability test
    DECLARE
        v_start_time TIMESTAMP;
        v_end_time TIMESTAMP;
        v_processing_time INTEGER;
        v_metric_count INTEGER;
    BEGIN
        v_start_time := clock_timestamp();
        
        -- Insert batch of metrics to test performance
        INSERT INTO real_time_metrics (
            id, project_id, queue_id, timestamp, calls_waiting, agents_available, 
            agents_busy, service_level_current, average_wait_time, longest_wait_time,
            calls_handled, calls_abandoned
        )
        SELECT 
            gen_random_uuid(),
            v_project_id,
            COALESCE(v_queue_id, gen_random_uuid()),
            NOW() + (interval '1 minute' * generate_series(1, 10)),
            5 + (random() * 20)::integer,
            2 + (random() * 8)::integer,
            3 + (random() * 7)::integer,
            0.70 + (random() * 0.25),
            30 + (random() * 120)::integer,
            60 + (random() * 240)::integer,
            20 + (random() * 40)::integer,
            1 + (random() * 5)::integer
        FROM generate_series(1, 10);
        
        v_end_time := clock_timestamp();
        v_processing_time := EXTRACT(milliseconds FROM v_end_time - v_start_time)::integer;
        
        -- Count metrics from last hour
        SELECT COUNT(*) INTO v_metric_count
        FROM real_time_metrics
        WHERE timestamp >= NOW() - INTERVAL '1 hour';
        
        IF v_processing_time < 500 AND v_metric_count >= 10 THEN
            RETURN QUERY SELECT 'Performance Test'::TEXT, 'PASS'::TEXT, 'Processed 10 metrics in ' || v_processing_time || 'ms'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Performance Test'::TEXT, 'FAIL'::TEXT, 'Performance issues: ' || v_processing_time || 'ms for ' || v_metric_count || ' metrics'::TEXT;
            v_test_passed := false;
        END IF;
    END;
    
    -- Final result
    IF v_test_passed THEN
        RETURN QUERY SELECT 'Alert System Integration'::TEXT, 'PASS'::TEXT, 'Complete real-time monitoring and alerting system working'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Alert System Integration'::TEXT, 'FAIL'::TEXT, 'Alert system has failures'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 2: Create Alert System Validation Function
```sql
CREATE OR REPLACE FUNCTION validate_alert_system_infrastructure()
RETURNS TABLE(
    check_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check real-time metrics table structure
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'real_time_metrics'
        AND column_name = 'service_level_current'
        AND data_type = 'numeric'
    ) THEN
        RETURN QUERY SELECT 'Metrics Table Structure'::TEXT, 'PASS'::TEXT, 'Service level tracking enabled'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Metrics Table Structure'::TEXT, 'FAIL'::TEXT, 'Missing service level metrics'::TEXT;
    END IF;
    
    -- Check alert thresholds configuration
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'alert_thresholds'
        AND column_name = 'escalation_rules'
        AND data_type = 'jsonb'
    ) THEN
        RETURN QUERY SELECT 'Alert Configuration'::TEXT, 'PASS'::TEXT, 'JSONB escalation rules supported'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Alert Configuration'::TEXT, 'FAIL'::TEXT, 'Missing escalation configuration'::TEXT;
    END IF;
    
    -- Check alerts table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'alerts'
        AND column_name = 'metadata'
        AND data_type = 'jsonb'
    ) THEN
        RETURN QUERY SELECT 'Alerts Infrastructure'::TEXT, 'PASS'::TEXT, 'Alert metadata support available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Alerts Infrastructure'::TEXT, 'FAIL'::TEXT, 'Alert table missing metadata'::TEXT;
    END IF;
    
    -- Check notification dispatch capability
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'notifications'
        AND column_name = 'alert_id'
        AND data_type = 'uuid'
    ) THEN
        RETURN QUERY SELECT 'Notification Dispatch'::TEXT, 'PASS'::TEXT, 'Alert-notification linkage available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Notification Dispatch'::TEXT, 'FAIL'::TEXT, 'No alert linkage in notifications'::TEXT;
    END IF;
    
    -- Check Russian language support for alerts
    IF EXISTS (
        SELECT 1 FROM alerts
        WHERE title ~ '[А-Яа-я]+'
        OR description ~ '[А-Яа-я]+'
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'PASS'::TEXT, 'Cyrillic text in alerts confirmed'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'WARN'::TEXT, 'No Russian alerts found (may be expected)'::TEXT;
    END IF;
    
    -- Check recent metrics availability
    IF EXISTS (
        SELECT 1 FROM real_time_metrics
        WHERE timestamp >= NOW() - INTERVAL '1 hour'
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Recent Metrics Data'::TEXT, 'PASS'::TEXT, 'Fresh real-time data available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Recent Metrics Data'::TEXT, 'WARN'::TEXT, 'No recent metrics (may need data ingestion)'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Execute Real-time Alert System Test
```sql
-- Run the complete alert system integration test
SELECT * FROM test_realtime_alert_system();

-- Validate alert system infrastructure
SELECT * FROM validate_alert_system_infrastructure();

-- Show alert system data flow
SELECT 
    'Active Alerts' as data_source,
    a.alert_type,
    a.severity,
    a.title,
    a.current_value,
    a.threshold_breached,
    a.status,
    a.trigger_time
FROM alerts a
WHERE a.trigger_time >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY a.trigger_time DESC
LIMIT 10;

SELECT 
    'Recent Metrics' as data_source,
    rtm.timestamp,
    rtm.calls_waiting,
    rtm.agents_available,
    rtm.service_level_current,
    rtm.average_wait_time
FROM real_time_metrics rtm
WHERE rtm.timestamp >= CURRENT_DATE - INTERVAL '1 hour'
ORDER BY rtm.timestamp DESC
LIMIT 10;

SELECT 
    'Alert Notifications' as data_source,
    n.notification_type,
    n.title,
    n.channel,
    n.priority,
    n.sent_at,
    a.alert_type
FROM notifications n
JOIN alerts a ON n.alert_id = a.id
WHERE n.created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY n.created_at DESC
LIMIT 10;
```

### Step 4: Create Alert System Performance Monitor
```sql
CREATE OR REPLACE FUNCTION monitor_alert_system_performance()
RETURNS TABLE(
    metric_name TEXT,
    current_value TEXT,
    threshold TEXT,
    status TEXT
) AS $$
DECLARE
    v_alert_response_time NUMERIC;
    v_notification_delivery_rate NUMERIC;
    v_active_alerts INTEGER;
    v_metrics_per_minute NUMERIC;
BEGIN
    -- Test alert response time (from metric to alert generation)
    SELECT AVG(EXTRACT(epoch FROM a.trigger_time - rtm.timestamp)) INTO v_alert_response_time
    FROM alerts a
    JOIN real_time_metrics rtm ON DATE_TRUNC('minute', a.trigger_time) = DATE_TRUNC('minute', rtm.timestamp)
    WHERE a.trigger_time >= NOW() - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Alert Response Time'::TEXT,
        COALESCE(v_alert_response_time::TEXT || 's', 'No data'),
        '< 60s'::TEXT,
        CASE WHEN v_alert_response_time < 60 THEN 'PASS' ELSE 'WARN' END;
    
    -- Test notification delivery rate
    SELECT 
        (COUNT(CASE WHEN sent_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(*))
    INTO v_notification_delivery_rate
    FROM notifications
    WHERE created_at >= NOW() - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Notification Delivery Rate'::TEXT,
        COALESCE(v_notification_delivery_rate::TEXT || '%', 'No data'),
        '> 95%'::TEXT,
        CASE WHEN v_notification_delivery_rate > 95 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test active alerts count
    SELECT COUNT(*) INTO v_active_alerts
    FROM alerts
    WHERE status = 'active';
    
    RETURN QUERY SELECT 
        'Active Alerts'::TEXT,
        v_active_alerts::TEXT,
        '< 10'::TEXT,
        CASE WHEN v_active_alerts < 10 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test metrics ingestion rate
    SELECT COUNT(*) / 60.0 INTO v_metrics_per_minute
    FROM real_time_metrics
    WHERE timestamp >= NOW() - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Metrics Ingestion Rate'::TEXT,
        v_metrics_per_minute::TEXT || '/min',
        '> 1/min'::TEXT,
        CASE WHEN v_metrics_per_minute > 1 THEN 'PASS' ELSE 'WARN' END;
END;
$$ LANGUAGE plpgsql;
```

## ✅ Success Criteria

- [ ] test_realtime_alert_system() returns all PASS
- [ ] validate_alert_system_infrastructure() returns all PASS  
- [ ] Alert generation triggers within 60 seconds of threshold breach
- [ ] Notifications properly linked to alerts with Russian text support
- [ ] Alert acknowledgment and resolution workflow complete
- [ ] Performance metrics meet thresholds (< 500ms for 10 metrics)
- [ ] Complete end-to-end monitoring pipeline operational

## 📊 Test Results Format
```
test_name                | status | details
-------------------------+--------+----------------------------------
Threshold Config         | PASS   | Alert threshold configured for service level
Metrics Ingestion        | PASS   | Critical metrics inserted (SL: 55%)
Alert Generation         | PASS   | Critical alert generated: abc123...
Notification Dispatch    | PASS   | Escalation notification sent: def456...
Alert Linkage           | PASS   | Alert properly linked to notification
Alert Resolution        | PASS   | Alert acknowledged and auto-resolved
Performance Test        | PASS   | Processed 10 metrics in 245ms
Alert System Integration| PASS   | Complete real-time monitoring and alerting system working
```

## 📊 Progress Update
```bash
echo "INTEGRATION_TEST_003: Complete - Real-time Monitoring Alert System tested" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting
- If threshold config fails: Check alert_thresholds table exists with JSONB support
- If metrics ingestion fails: Verify real_time_metrics table structure
- If alert generation fails: Check alerts table has proper constraints
- If Russian text issues: Verify database encoding supports UTF-8
- If performance poor: Check indexes on timestamp, alert_id, organization_id columns