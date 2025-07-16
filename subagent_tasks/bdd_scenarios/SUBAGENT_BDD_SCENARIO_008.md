# 📋 SUBAGENT TASK: BDD Scenario 008 - Real-time Queue Monitoring with Alerts

## 🎯 Task Information
- **Task ID**: BDD_SCENARIO_008
- **Priority**: Critical
- **Estimated Time**: 60 minutes
- **Dependencies**: Real-time monitoring infrastructure, Alert threshold configuration
- **BDD File**: `/intelligence/argus/bdd-specifications/15-real-time-monitoring-operational-control.feature`

## 📊 BDD Scenario Details

**Scenario**: Configure and Respond to Threshold-Based Alerts (Lines 67-83)
```gherkin
Given monitoring thresholds are configured
When operational metrics exceed critical thresholds
Then automated alerts should trigger:
  | Alert Trigger | Threshold | Response Actions |
  | Critical understaffing | Online % <70% | SMS + email to management |
  | Service level breach | 80/20 format <70% for 5 minutes | Immediate escalation |
  | System overload | Queue >20 contacts | Emergency staffing protocol |
  | Extended outages | No data for 10 minutes | Technical team alert |
And alert responses should include:
  | Response Element | Content | Purpose |
  | Alert description | What threshold was breached | Clear problem identification |
  | Current values | Actual vs target metrics | Quantify severity |
  | Suggested actions | Recommended responses | Guidance for resolution |
  | Escalation timeline | When to escalate further | Progressive response |
```

## 📝 Implementation Steps

### Step 1: Create Real-time Queue Monitoring Tables
```sql
-- Create queue metrics table for real-time monitoring
CREATE TABLE IF NOT EXISTS real_time_queue_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    queue_name VARCHAR(100) NOT NULL,
    metric_timestamp TIMESTAMP DEFAULT NOW(),
    contacts_waiting INTEGER DEFAULT 0,
    contacts_offered INTEGER DEFAULT 0,
    contacts_answered INTEGER DEFAULT 0,
    operators_online INTEGER DEFAULT 0,
    operators_planned INTEGER DEFAULT 0,
    service_level_80_20 DECIMAL(5,2) DEFAULT 0.00,
    average_handle_time INTEGER DEFAULT 0,
    load_deviation_percent DECIMAL(5,2) DEFAULT 0.00,
    acd_rate_percent DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for time-based queries
CREATE INDEX IF NOT EXISTS idx_queue_metrics_timestamp 
ON real_time_queue_metrics (queue_name, metric_timestamp DESC);

-- Create alert thresholds configuration table
CREATE TABLE IF NOT EXISTS alert_thresholds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threshold_name VARCHAR(100) NOT NULL UNIQUE,
    threshold_type VARCHAR(50) NOT NULL,
    warning_threshold DECIMAL(10,2),
    critical_threshold DECIMAL(10,2),
    evaluation_window_minutes INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create alerts log table
CREATE TABLE IF NOT EXISTS alert_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(100) NOT NULL,
    threshold_name VARCHAR(100) NOT NULL,
    trigger_value DECIMAL(10,2),
    threshold_value DECIMAL(10,2),
    severity_level VARCHAR(20) NOT NULL,
    alert_description TEXT,
    current_values JSONB,
    suggested_actions TEXT,
    escalation_timeline TEXT,
    is_acknowledged BOOLEAN DEFAULT false,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create alert recipients table
CREATE TABLE IF NOT EXISTS alert_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(100) NOT NULL,
    recipient_type VARCHAR(50) NOT NULL, -- SMS, EMAIL, DASHBOARD
    recipient_address VARCHAR(200) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Step 2: Configure Alert Thresholds (BDD Requirements)
```sql
-- Insert BDD-specified alert thresholds
INSERT INTO alert_thresholds (
    threshold_name, 
    threshold_type, 
    warning_threshold, 
    critical_threshold, 
    evaluation_window_minutes
) VALUES
('Critical Understaffing', 'operators_online_percent', 80.0, 70.0, 1),
('Service Level Breach', 'service_level_80_20', 75.0, 70.0, 5),
('System Overload', 'contacts_waiting', 15.0, 20.0, 1),
('Extended Outages', 'data_freshness_minutes', 5.0, 10.0, 1)
ON CONFLICT (threshold_name) DO UPDATE SET
    warning_threshold = EXCLUDED.warning_threshold,
    critical_threshold = EXCLUDED.critical_threshold,
    evaluation_window_minutes = EXCLUDED.evaluation_window_minutes,
    updated_at = NOW();

-- Configure alert recipients (BDD requirements)
INSERT INTO alert_recipients (alert_type, recipient_type, recipient_address) VALUES
('Critical Understaffing', 'EMAIL', 'management@technoservice.ru'),
('Critical Understaffing', 'SMS', '+7-900-123-4567'),
('Service Level Breach', 'EMAIL', 'operations@technoservice.ru'),
('Service Level Breach', 'DASHBOARD', 'immediate_escalation'),
('System Overload', 'EMAIL', 'emergency@technoservice.ru'),
('System Overload', 'SMS', '+7-900-123-4568'),
('Extended Outages', 'EMAIL', 'technical@technoservice.ru'),
('Extended Outages', 'DASHBOARD', 'technical_alert')
ON CONFLICT DO NOTHING;
```

### Step 3: Create Alert Monitoring Functions
```sql
-- Function to calculate operators online percentage
CREATE OR REPLACE FUNCTION calculate_operators_online_percent(
    p_queue_name VARCHAR
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_online INTEGER;
    v_planned INTEGER;
    v_percentage DECIMAL(5,2);
BEGIN
    SELECT operators_online, operators_planned
    INTO v_online, v_planned
    FROM real_time_queue_metrics
    WHERE queue_name = p_queue_name
    ORDER BY metric_timestamp DESC
    LIMIT 1;
    
    IF v_planned > 0 THEN
        v_percentage := (v_online::DECIMAL / v_planned::DECIMAL) * 100;
    ELSE
        v_percentage := 0.00;
    END IF;
    
    RETURN v_percentage;
END;
$$ LANGUAGE plpgsql;

-- Function to check alert thresholds and trigger alerts
CREATE OR REPLACE FUNCTION check_and_trigger_alerts()
RETURNS TABLE(
    alert_triggered BOOLEAN,
    alert_type VARCHAR,
    current_value DECIMAL,
    threshold_breached VARCHAR
) AS $$
DECLARE
    r RECORD;
    v_current_value DECIMAL(10,2);
    v_alert_data JSONB;
BEGIN
    -- Check Critical Understaffing
    FOR r IN SELECT DISTINCT queue_name FROM real_time_queue_metrics LOOP
        v_current_value := calculate_operators_online_percent(r.queue_name);
        
        IF v_current_value < 70.0 THEN
            v_alert_data := jsonb_build_object(
                'queue_name', r.queue_name,
                'operators_online_percent', v_current_value,
                'threshold', 70.0,
                'operators_online', (SELECT operators_online FROM real_time_queue_metrics WHERE queue_name = r.queue_name ORDER BY metric_timestamp DESC LIMIT 1),
                'operators_planned', (SELECT operators_planned FROM real_time_queue_metrics WHERE queue_name = r.queue_name ORDER BY metric_timestamp DESC LIMIT 1)
            );
            
            INSERT INTO alert_log (
                alert_type, threshold_name, trigger_value, threshold_value,
                severity_level, alert_description, current_values,
                suggested_actions, escalation_timeline
            ) VALUES (
                'Critical Understaffing',
                'Critical Understaffing',
                v_current_value,
                70.0,
                'CRITICAL',
                'Critical understaffing detected in queue ' || r.queue_name || '. Online operators: ' || v_current_value || '% (threshold: 70%)',
                v_alert_data,
                'Immediate action required: 1) Call additional operators to work 2) Reassign operators from other queues 3) Activate emergency staffing protocol',
                'Escalate to management if not resolved in 15 minutes'
            );
            
            RETURN QUERY SELECT true, 'Critical Understaffing'::VARCHAR, v_current_value, 'operators_online_percent'::VARCHAR;
        END IF;
    END LOOP;
    
    -- Check Service Level Breach
    FOR r IN SELECT DISTINCT queue_name FROM real_time_queue_metrics LOOP
        SELECT service_level_80_20 INTO v_current_value
        FROM real_time_queue_metrics
        WHERE queue_name = r.queue_name
          AND metric_timestamp >= NOW() - INTERVAL '5 minutes'
        ORDER BY metric_timestamp DESC
        LIMIT 1;
        
        IF v_current_value < 70.0 THEN
            v_alert_data := jsonb_build_object(
                'queue_name', r.queue_name,
                'service_level_80_20', v_current_value,
                'threshold', 70.0,
                'duration_minutes', 5
            );
            
            INSERT INTO alert_log (
                alert_type, threshold_name, trigger_value, threshold_value,
                severity_level, alert_description, current_values,
                suggested_actions, escalation_timeline
            ) VALUES (
                'Service Level Breach',
                'Service Level Breach',
                v_current_value,
                70.0,
                'CRITICAL',
                'Service level breach in queue ' || r.queue_name || '. Current SL: ' || v_current_value || '% (threshold: 70% for 5 minutes)',
                v_alert_data,
                'Immediate escalation required: 1) Add more operators to queue 2) Review call routing 3) Implement emergency procedures',
                'Escalate to operations manager immediately'
            );
            
            RETURN QUERY SELECT true, 'Service Level Breach'::VARCHAR, v_current_value, 'service_level_80_20'::VARCHAR;
        END IF;
    END LOOP;
    
    -- Check System Overload
    FOR r IN SELECT DISTINCT queue_name FROM real_time_queue_metrics LOOP
        SELECT contacts_waiting INTO v_current_value
        FROM real_time_queue_metrics
        WHERE queue_name = r.queue_name
        ORDER BY metric_timestamp DESC
        LIMIT 1;
        
        IF v_current_value > 20 THEN
            v_alert_data := jsonb_build_object(
                'queue_name', r.queue_name,
                'contacts_waiting', v_current_value,
                'threshold', 20
            );
            
            INSERT INTO alert_log (
                alert_type, threshold_name, trigger_value, threshold_value,
                severity_level, alert_description, current_values,
                suggested_actions, escalation_timeline
            ) VALUES (
                'System Overload',
                'System Overload',
                v_current_value,
                20.0,
                'CRITICAL',
                'System overload detected in queue ' || r.queue_name || '. Contacts waiting: ' || v_current_value || ' (threshold: 20)',
                v_alert_data,
                'Emergency staffing protocol: 1) Activate all available operators 2) Redirect calls to other queues 3) Implement overflow procedures',
                'Escalate to duty manager if queue continues growing'
            );
            
            RETURN QUERY SELECT true, 'System Overload'::VARCHAR, v_current_value, 'contacts_waiting'::VARCHAR;
        END IF;
    END LOOP;
    
    -- If no alerts triggered
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'No alerts'::VARCHAR, 0.0::DECIMAL, 'none'::VARCHAR;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 4: Create Test Data to Demonstrate Alert Triggers
```sql
-- Insert test queue metrics that will trigger alerts
INSERT INTO real_time_queue_metrics (
    queue_name, metric_timestamp, contacts_waiting, contacts_offered, contacts_answered,
    operators_online, operators_planned, service_level_80_20, average_handle_time,
    load_deviation_percent, acd_rate_percent
) VALUES
-- Normal scenario (no alerts)
('Customer_Support', NOW() - INTERVAL '10 minutes', 5, 120, 115, 8, 10, 85.5, 180, 5.2, 95.8),
-- Critical understaffing scenario (will trigger alert)
('Technical_Support', NOW() - INTERVAL '5 minutes', 12, 85, 75, 3, 8, 75.0, 220, 15.5, 88.2),
-- Service level breach scenario (will trigger alert)
('Sales_Queue', NOW() - INTERVAL '3 minutes', 8, 95, 80, 6, 8, 65.0, 190, 8.7, 84.2),
-- System overload scenario (will trigger alert)
('Emergency_Line', NOW() - INTERVAL '1 minute', 25, 150, 120, 5, 6, 68.0, 240, 25.8, 80.0),
-- Recent normal data
('Customer_Support', NOW(), 3, 125, 122, 9, 10, 87.2, 175, 2.1, 97.6);
```

### Step 5: Test Alert System and Create Alert Responses
```sql
-- Test the alert monitoring system
DO $$
DECLARE
    alert_result RECORD;
    alert_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Testing Real-time Queue Monitoring Alert System';
    RAISE NOTICE '================================================';
    
    -- Execute alert checking function
    FOR alert_result IN 
        SELECT * FROM check_and_trigger_alerts()
    LOOP
        IF alert_result.alert_triggered THEN
            alert_count := alert_count + 1;
            RAISE NOTICE 'ALERT TRIGGERED: % - Current Value: % (Threshold: %)', 
                alert_result.alert_type, 
                alert_result.current_value, 
                alert_result.threshold_breached;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Alert monitoring test completed. Alerts triggered: %', alert_count;
END $$;

-- View triggered alerts with full details
SELECT 
    'Alert Dashboard' as report_type,
    al.alert_type as "Alert Type",
    al.severity_level as "Severity",
    al.trigger_value as "Current Value",
    al.threshold_value as "Threshold",
    al.alert_description as "Description",
    al.suggested_actions as "Suggested Actions",
    al.escalation_timeline as "Escalation Timeline",
    al.created_at as "Triggered At"
FROM alert_log al
WHERE al.created_at > NOW() - INTERVAL '1 hour'
ORDER BY al.created_at DESC;
```

### Step 6: Create Alert Management Views and Reports
```sql
-- Create view for real-time monitoring dashboard
CREATE OR REPLACE VIEW real_time_monitoring_dashboard AS
SELECT 
    rm.queue_name as "Queue Name",
    rm.metric_timestamp as "Last Update",
    rm.contacts_waiting as "Contacts Waiting",
    rm.operators_online as "Operators Online",
    rm.operators_planned as "Operators Planned",
    ROUND((rm.operators_online::DECIMAL / NULLIF(rm.operators_planned, 0)) * 100, 2) as "Online %",
    rm.service_level_80_20 as "Service Level 80/20",
    rm.acd_rate_percent as "ACD Rate %",
    rm.average_handle_time as "AHT (seconds)",
    CASE 
        WHEN (rm.operators_online::DECIMAL / NULLIF(rm.operators_planned, 0)) * 100 < 70 THEN 'CRITICAL'
        WHEN (rm.operators_online::DECIMAL / NULLIF(rm.operators_planned, 0)) * 100 < 80 THEN 'WARNING'
        ELSE 'NORMAL'
    END as "Staffing Status",
    CASE 
        WHEN rm.service_level_80_20 < 70 THEN 'CRITICAL'
        WHEN rm.service_level_80_20 < 75 THEN 'WARNING'
        ELSE 'NORMAL'
    END as "Service Level Status",
    CASE 
        WHEN rm.contacts_waiting > 20 THEN 'CRITICAL'
        WHEN rm.contacts_waiting > 15 THEN 'WARNING'
        ELSE 'NORMAL'
    END as "Queue Status"
FROM real_time_queue_metrics rm
WHERE rm.metric_timestamp = (
    SELECT MAX(metric_timestamp) 
    FROM real_time_queue_metrics rm2 
    WHERE rm2.queue_name = rm.queue_name
);

-- Create alert summary report
CREATE OR REPLACE VIEW alert_summary_report AS
SELECT 
    DATE(al.created_at) as alert_date,
    al.alert_type,
    COUNT(*) as alert_count,
    COUNT(*) FILTER (WHERE al.severity_level = 'CRITICAL') as critical_alerts,
    COUNT(*) FILTER (WHERE al.is_acknowledged = true) as acknowledged_alerts,
    COUNT(*) FILTER (WHERE al.resolved_at IS NOT NULL) as resolved_alerts,
    AVG(EXTRACT(EPOCH FROM (COALESCE(al.resolved_at, NOW()) - al.created_at))/60) as avg_resolution_minutes
FROM alert_log al
WHERE al.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(al.created_at), al.alert_type
ORDER BY alert_date DESC, al.alert_type;
```

### Step 7: Verify BDD Scenario Implementation
```sql
-- Comprehensive BDD Scenario 008 verification
SELECT 
    'BDD Scenario 008 Verification' as scenario_name,
    'Real-time Queue Monitoring with Alerts' as scenario_description,
    COUNT(DISTINCT at.threshold_name) as configured_thresholds,
    COUNT(DISTINCT al.alert_type) as alert_types_triggered,
    COUNT(*) FILTER (WHERE al.severity_level = 'CRITICAL') as critical_alerts_triggered,
    COUNT(DISTINCT ar.alert_type) as alert_recipients_configured,
    CASE 
        WHEN COUNT(DISTINCT at.threshold_name) >= 4 
             AND COUNT(DISTINCT al.alert_type) >= 3
             AND COUNT(*) FILTER (WHERE al.severity_level = 'CRITICAL') >= 3
        THEN 'PASS'
        ELSE 'FAIL'
    END as bdd_scenario_status
FROM alert_thresholds at
CROSS JOIN alert_log al
CROSS JOIN alert_recipients ar
WHERE at.is_active = true 
  AND al.created_at > NOW() - INTERVAL '1 hour';

-- Show real-time monitoring dashboard
SELECT * FROM real_time_monitoring_dashboard;

-- Show alert summary
SELECT * FROM alert_summary_report WHERE alert_date = CURRENT_DATE;

-- Verify alert response elements (BDD requirement)
SELECT 
    'Alert Response Verification' as test_name,
    al.alert_type as "Alert Type",
    CASE WHEN al.alert_description IS NOT NULL THEN 'YES' ELSE 'NO' END as "Has Description",
    CASE WHEN al.current_values IS NOT NULL THEN 'YES' ELSE 'NO' END as "Has Current Values",
    CASE WHEN al.suggested_actions IS NOT NULL THEN 'YES' ELSE 'NO' END as "Has Suggested Actions",
    CASE WHEN al.escalation_timeline IS NOT NULL THEN 'YES' ELSE 'NO' END as "Has Escalation Timeline",
    CASE 
        WHEN al.alert_description IS NOT NULL 
             AND al.current_values IS NOT NULL 
             AND al.suggested_actions IS NOT NULL 
             AND al.escalation_timeline IS NOT NULL 
        THEN 'COMPLETE'
        ELSE 'INCOMPLETE'
    END as "BDD Compliance"
FROM alert_log al
WHERE al.created_at > NOW() - INTERVAL '1 hour'
ORDER BY al.created_at DESC;
```

## ✅ Success Criteria

- [ ] Real-time queue monitoring tables created (real_time_queue_metrics, alert_thresholds, alert_log, alert_recipients)
- [ ] Alert thresholds configured per BDD specifications:
  - [ ] Critical understaffing: Online % <70%
  - [ ] Service level breach: 80/20 format <70% for 5 minutes
  - [ ] System overload: Queue >20 contacts
  - [ ] Extended outages: No data for 10 minutes
- [ ] Alert response elements implemented:
  - [ ] Alert description (clear problem identification)
  - [ ] Current values (actual vs target metrics)
  - [ ] Suggested actions (recommended responses)
  - [ ] Escalation timeline (progressive response)
- [ ] Alert recipients configured (SMS + email to management)
- [ ] Test data demonstrating all alert triggers
- [ ] Alert monitoring functions working
- [ ] Real-time monitoring dashboard view created
- [ ] Alert summary reporting implemented
- [ ] Complete BDD scenario verification passing

## 📊 Progress Update
```bash
echo "BDD_SCENARIO_008: Complete - Real-time Queue Monitoring with Alerts implemented" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Error Handling
- If alert thresholds are not properly configured, validate threshold values
- If alert functions fail, check database permissions and function syntax
- If test data doesn't trigger alerts, verify threshold calculations
- Document any deviations in progress log

## 🔧 Additional Notes
- This scenario implements BDD lines 67-83 from 15-real-time-monitoring-operational-control.feature
- Focuses on threshold-based alert system with automated responses
- Includes comprehensive alert management and escalation procedures
- Tests real monitoring scenarios with Russian call center context
- Validates all BDD requirements for alert response elements