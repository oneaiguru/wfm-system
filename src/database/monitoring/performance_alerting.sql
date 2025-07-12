-- =====================================================================================
-- Performance Alerting Framework
-- Purpose: Proactive performance monitoring and alerting system
-- Features: Configurable alerts, notification management, escalation procedures
-- =====================================================================================

-- =====================================================================================
-- 1. ALERTING CONFIGURATION TABLES
-- =====================================================================================

-- Alert rule definitions
CREATE TABLE IF NOT EXISTS db_alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    rule_type VARCHAR(50) NOT NULL, -- 'threshold', 'trend', 'anomaly', 'composite'
    category VARCHAR(50) NOT NULL, -- 'performance', 'capacity', 'availability', 'security'
    severity VARCHAR(20) NOT NULL, -- 'critical', 'major', 'minor', 'warning', 'info'
    
    -- Rule configuration
    metric_query TEXT NOT NULL,
    threshold_value NUMERIC,
    threshold_operator VARCHAR(10) DEFAULT '>', -- '>', '<', '>=', '<=', '=', '!='
    evaluation_window_minutes INTEGER DEFAULT 5,
    trigger_count INTEGER DEFAULT 1, -- Number of consecutive violations to trigger alert
    
    -- Alert content
    alert_title VARCHAR(200) NOT NULL,
    alert_message TEXT NOT NULL,
    recommended_action TEXT,
    documentation_url TEXT,
    
    -- Notification settings
    notification_channels JSONB DEFAULT '["email"]', -- ['email', 'slack', 'webhook', 'sms']
    notification_recipients JSONB DEFAULT '[]',
    escalation_rules JSONB,
    
    -- Rule state
    is_active BOOLEAN DEFAULT true,
    suppress_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by VARCHAR(100),
    
    -- Constraints
    CONSTRAINT db_alert_rules_severity_check CHECK (severity IN ('critical', 'major', 'minor', 'warning', 'info')),
    CONSTRAINT db_alert_rules_operator_check CHECK (threshold_operator IN ('>', '<', '>=', '<=', '=', '!='))
);

-- Alert instances and history
CREATE TABLE IF NOT EXISTS db_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL REFERENCES db_alert_rules(id),
    alert_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Alert data
    metric_value NUMERIC,
    metric_data JSONB,
    alert_title VARCHAR(200) NOT NULL,
    alert_message TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    
    -- Alert state
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'acknowledged', 'resolved', 'suppressed'
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by VARCHAR(100),
    resolved_at TIMESTAMPTZ,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    
    -- Notification tracking
    notifications_sent JSONB DEFAULT '[]',
    escalation_level INTEGER DEFAULT 0,
    last_notification_sent TIMESTAMPTZ,
    
    -- Additional context
    affected_objects JSONB, -- Tables, queries, etc. affected
    environmental_data JSONB, -- System metrics at time of alert
    correlation_id UUID, -- Link related alerts
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alert notification log
CREATE TABLE IF NOT EXISTS db_alert_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID NOT NULL REFERENCES db_alerts(id),
    notification_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Notification details
    channel VARCHAR(50) NOT NULL, -- 'email', 'slack', 'webhook', 'sms'
    recipient VARCHAR(200) NOT NULL,
    subject VARCHAR(200),
    message TEXT NOT NULL,
    
    -- Delivery status
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed'
    attempt_count INTEGER DEFAULT 0,
    last_attempt TIMESTAMPTZ,
    delivery_response TEXT,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alert suppression rules
CREATE TABLE IF NOT EXISTS db_alert_suppressions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suppression_name VARCHAR(100) NOT NULL,
    rule_pattern VARCHAR(200), -- Rule name pattern (can use wildcards)
    category_pattern VARCHAR(50), -- Category pattern
    
    -- Suppression schedule
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    recurring_schedule VARCHAR(100), -- Cron expression for recurring suppressions
    
    -- Suppression details
    reason TEXT NOT NULL,
    created_by VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================================
-- 2. ALERT EVALUATION FUNCTIONS
-- =====================================================================================

-- Evaluate a single alert rule
CREATE OR REPLACE FUNCTION evaluate_alert_rule(rule_id UUID)
RETURNS JSONB AS $$
DECLARE
    rule_record db_alert_rules%ROWTYPE;
    metric_value NUMERIC;
    metric_data JSONB;
    should_alert BOOLEAN := false;
    alert_id UUID;
    existing_active_alert UUID;
    consecutive_violations INTEGER := 0;
    result JSONB;
    error_msg TEXT;
BEGIN
    -- Get rule configuration
    SELECT * INTO rule_record FROM db_alert_rules WHERE id = rule_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Alert rule not found or inactive'
        );
    END IF;
    
    -- Check if rule is suppressed
    IF rule_record.suppress_until IS NOT NULL AND rule_record.suppress_until > NOW() THEN
        RETURN jsonb_build_object(
            'success', true,
            'suppressed', true,
            'suppress_until', rule_record.suppress_until
        );
    END IF;
    
    -- Check for active suppression rules
    IF EXISTS (
        SELECT 1 FROM db_alert_suppressions 
        WHERE is_active = true 
        AND start_time <= NOW() 
        AND end_time >= NOW()
        AND (rule_pattern IS NULL OR rule_record.rule_name LIKE rule_pattern)
        AND (category_pattern IS NULL OR rule_record.category LIKE category_pattern)
    ) THEN
        RETURN jsonb_build_object(
            'success', true,
            'suppressed', true,
            'reason', 'Active suppression rule'
        );
    END IF;
    
    -- Execute metric query
    BEGIN
        EXECUTE rule_record.metric_query INTO metric_value, metric_data;
        
        -- Evaluate threshold
        IF rule_record.threshold_value IS NOT NULL AND metric_value IS NOT NULL THEN
            CASE rule_record.threshold_operator
                WHEN '>' THEN should_alert := metric_value > rule_record.threshold_value;
                WHEN '<' THEN should_alert := metric_value < rule_record.threshold_value;
                WHEN '>=' THEN should_alert := metric_value >= rule_record.threshold_value;
                WHEN '<=' THEN should_alert := metric_value <= rule_record.threshold_value;
                WHEN '=' THEN should_alert := metric_value = rule_record.threshold_value;
                WHEN '!=' THEN should_alert := metric_value != rule_record.threshold_value;
            END CASE;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        should_alert := false;
    END;
    
    -- Check for existing active alert
    SELECT id INTO existing_active_alert 
    FROM db_alerts 
    WHERE rule_id = rule_record.id 
    AND status = 'active' 
    AND alert_timestamp > NOW() - INTERVAL '1 hour';
    
    IF should_alert THEN
        -- Check consecutive violations if required
        IF rule_record.trigger_count > 1 THEN
            -- Count recent violations (simplified - in production would track state)
            consecutive_violations := 1;
        ELSE
            consecutive_violations := rule_record.trigger_count;
        END IF;
        
        -- Create alert if threshold met and no existing active alert
        IF consecutive_violations >= rule_record.trigger_count AND existing_active_alert IS NULL THEN
            INSERT INTO db_alerts (
                rule_id, metric_value, metric_data, alert_title, alert_message,
                severity, affected_objects, environmental_data
            ) VALUES (
                rule_record.id, metric_value, metric_data, rule_record.alert_title,
                rule_record.alert_message, rule_record.severity,
                jsonb_build_object('metric_value', metric_value),
                jsonb_build_object('timestamp', NOW(), 'rule_evaluation', true)
            ) RETURNING id INTO alert_id;
            
            -- Send notifications
            PERFORM send_alert_notifications(alert_id);
            
            result := jsonb_build_object(
                'success', true,
                'alert_triggered', true,
                'alert_id', alert_id,
                'metric_value', metric_value,
                'threshold_value', rule_record.threshold_value,
                'severity', rule_record.severity
            );
        ELSE
            result := jsonb_build_object(
                'success', true,
                'alert_triggered', false,
                'reason', CASE 
                    WHEN existing_active_alert IS NOT NULL THEN 'Active alert already exists'
                    ELSE 'Consecutive violations threshold not met'
                END,
                'consecutive_violations', consecutive_violations,
                'required_violations', rule_record.trigger_count
            );
        END IF;
    ELSE
        -- Resolve existing active alert if metric is back to normal
        IF existing_active_alert IS NOT NULL THEN
            UPDATE db_alerts 
            SET status = 'resolved',
                resolved_at = NOW(),
                resolved_by = 'system',
                resolution_notes = 'Metric returned to normal'
            WHERE id = existing_active_alert;
            
            result := jsonb_build_object(
                'success', true,
                'alert_resolved', true,
                'resolved_alert_id', existing_active_alert,
                'metric_value', metric_value
            );
        ELSE
            result := jsonb_build_object(
                'success', true,
                'alert_triggered', false,
                'metric_value', metric_value,
                'threshold_value', rule_record.threshold_value,
                'within_threshold', true
            );
        END IF;
    END IF;
    
    -- Add error info if any
    IF error_msg IS NOT NULL THEN
        result := result || jsonb_build_object('error_message', error_msg);
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. NOTIFICATION SYSTEM
-- =====================================================================================

-- Send notifications for an alert
CREATE OR REPLACE FUNCTION send_alert_notifications(alert_id UUID)
RETURNS JSONB AS $$
DECLARE
    alert_record db_alerts%ROWTYPE;
    rule_record db_alert_rules%ROWTYPE;
    notification_id UUID;
    channel TEXT;
    recipient TEXT;
    notifications_sent INTEGER := 0;
    notifications_failed INTEGER := 0;
    result JSONB;
BEGIN
    -- Get alert and rule information
    SELECT a.*, r.notification_channels, r.notification_recipients
    INTO alert_record, rule_record
    FROM db_alerts a
    JOIN db_alert_rules r ON a.rule_id = r.id
    WHERE a.id = alert_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Alert not found'
        );
    END IF;
    
    -- Send notifications to each channel and recipient
    FOR channel IN SELECT jsonb_array_elements_text(rule_record.notification_channels)
    LOOP
        FOR recipient IN SELECT jsonb_array_elements_text(rule_record.notification_recipients)
        LOOP
            -- Create notification record
            INSERT INTO db_alert_notifications (
                alert_id, channel, recipient, subject, message, status
            ) VALUES (
                alert_id, channel, recipient,
                '[' || alert_record.severity || '] ' || alert_record.alert_title,
                alert_record.alert_message,
                'pending'
            ) RETURNING id INTO notification_id;
            
            -- Simulate notification sending (in production would integrate with actual services)
            BEGIN
                -- Update notification status
                UPDATE db_alert_notifications 
                SET status = 'sent',
                    last_attempt = NOW(),
                    attempt_count = attempt_count + 1,
                    delivery_response = 'Simulated delivery success'
                WHERE id = notification_id;
                
                notifications_sent := notifications_sent + 1;
                
            EXCEPTION WHEN OTHERS THEN
                UPDATE db_alert_notifications 
                SET status = 'failed',
                    last_attempt = NOW(),
                    attempt_count = attempt_count + 1,
                    error_message = SQLERRM
                WHERE id = notification_id;
                
                notifications_failed := notifications_failed + 1;
            END;
        END LOOP;
    END LOOP;
    
    -- Update alert with notification info
    UPDATE db_alerts 
    SET last_notification_sent = NOW(),
        notifications_sent = notifications_sent || jsonb_build_object(
            'timestamp', NOW(),
            'sent_count', notifications_sent,
            'failed_count', notifications_failed
        )
    WHERE id = alert_id;
    
    result := jsonb_build_object(
        'success', true,
        'alert_id', alert_id,
        'notifications_sent', notifications_sent,
        'notifications_failed', notifications_failed
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. ALERT ORCHESTRATION
-- =====================================================================================

-- Evaluate all active alert rules
CREATE OR REPLACE FUNCTION evaluate_all_alert_rules()
RETURNS JSONB AS $$
DECLARE
    rule_record RECORD;
    evaluation_result JSONB;
    all_results JSONB := jsonb_build_array();
    total_rules INTEGER := 0;
    alerts_triggered INTEGER := 0;
    alerts_resolved INTEGER := 0;
    errors INTEGER := 0;
    start_time TIMESTAMPTZ;
    execution_time_ms NUMERIC;
BEGIN
    start_time := clock_timestamp();
    
    -- Evaluate each active rule
    FOR rule_record IN 
        SELECT id, rule_name FROM db_alert_rules WHERE is_active = true
    LOOP
        total_rules := total_rules + 1;
        
        evaluation_result := evaluate_alert_rule(rule_record.id);
        evaluation_result := evaluation_result || jsonb_build_object('rule_name', rule_record.rule_name);
        
        all_results := all_results || evaluation_result;
        
        -- Count results
        IF evaluation_result->>'alert_triggered' = 'true' THEN
            alerts_triggered := alerts_triggered + 1;
        END IF;
        
        IF evaluation_result->>'alert_resolved' = 'true' THEN
            alerts_resolved := alerts_resolved + 1;
        END IF;
        
        IF evaluation_result->>'success' = 'false' THEN
            errors := errors + 1;
        END IF;
    END LOOP;
    
    execution_time_ms := EXTRACT(EPOCH FROM (clock_timestamp() - start_time)) * 1000;
    
    RETURN jsonb_build_object(
        'timestamp', NOW(),
        'execution_time_ms', execution_time_ms,
        'summary', jsonb_build_object(
            'total_rules_evaluated', total_rules,
            'alerts_triggered', alerts_triggered,
            'alerts_resolved', alerts_resolved,
            'errors', errors,
            'active_alerts', (SELECT COUNT(*) FROM db_alerts WHERE status = 'active'),
            'critical_alerts', (SELECT COUNT(*) FROM db_alerts WHERE status = 'active' AND severity = 'critical')
        ),
        'results', all_results
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. PREDEFINED ALERT RULES
-- =====================================================================================

-- Insert standard alert rules
INSERT INTO db_alert_rules (
    rule_name, rule_type, category, severity, metric_query, threshold_value, 
    threshold_operator, alert_title, alert_message, recommended_action, 
    notification_channels, notification_recipients
) VALUES
(
    'High Database Connections',
    'threshold',
    'performance',
    'critical',
    'SELECT COUNT(*) FROM pg_stat_activity WHERE state = ''active'' AND pid != pg_backend_pid()',
    80,
    '>',
    'Database Connection Limit Approaching',
    'Active database connections have exceeded the critical threshold. This may indicate connection pool exhaustion or connection leaks.',
    'Review application connection usage and consider increasing connection limits or optimizing connection pooling.',
    '["email", "slack"]',
    '["dba@company.com", "ops-team@company.com"]'
),
(
    'Slow Query Performance',
    'threshold',
    'performance',
    'major',
    'SELECT COALESCE(AVG(mean_exec_time), 0) FROM pg_stat_statements WHERE last_call > NOW() - INTERVAL ''5 minutes''',
    1000,
    '>',
    'Database Query Performance Degraded',
    'Average query execution time has exceeded acceptable thresholds. Database performance may be impacted.',
    'Review slow query log and optimize problematic queries. Consider index optimization.',
    '["email"]',
    '["dba@company.com"]'
),
(
    'Low Cache Hit Ratio',
    'threshold',
    'performance',
    'major',
    'SELECT ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) FROM pg_statio_user_tables',
    85,
    '<',
    'Database Cache Hit Ratio Too Low',
    'Buffer cache hit ratio has dropped below optimal levels. This may indicate insufficient memory allocation.',
    'Review shared_buffers configuration and consider increasing memory allocation.',
    '["email"]',
    '["dba@company.com"]'
),
(
    'High Lock Contention',
    'threshold',
    'performance',
    'critical',
    'SELECT COUNT(*) FROM pg_locks WHERE NOT granted',
    5,
    '>',
    'High Database Lock Contention',
    'Multiple processes are waiting for locks. This may indicate deadlock conditions or long-running transactions.',
    'Review current transactions and identify blocking queries. Consider query optimization.',
    '["email", "slack"]',
    '["dba@company.com", "ops-team@company.com"]'
),
(
    'Database Size Growth',
    'threshold',
    'capacity',
    'warning',
    'SELECT pg_database_size(current_database()) / 1024.0 / 1024.0 / 1024.0',
    50,
    '>',
    'Database Size Approaching Limits',
    'Database size has grown significantly and may require attention.',
    'Review data retention policies and consider archiving old data.',
    '["email"]',
    '["dba@company.com"]'
),
(
    'Demo Performance SLA',
    'threshold',
    'performance',
    'minor',
    'SELECT COALESCE(AVG(mean_exec_time), 0) FROM pg_stat_statements WHERE query LIKE ''%demo_%'' AND last_call > NOW() - INTERVAL ''5 minutes''',
    10,
    '>',
    'Demo Query Performance Alert',
    'Demo queries are exceeding the 10ms SLA threshold.',
    'Review demo query performance and optimize if necessary.',
    '["email"]',
    '["demo-team@company.com"]'
)
ON CONFLICT (rule_name) DO UPDATE SET
    metric_query = EXCLUDED.metric_query,
    threshold_value = EXCLUDED.threshold_value,
    alert_message = EXCLUDED.alert_message,
    updated_at = NOW();

-- =====================================================================================
-- 6. ALERT MANAGEMENT FUNCTIONS
-- =====================================================================================

-- Get active alerts dashboard
CREATE OR REPLACE FUNCTION get_alerts_dashboard()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH alert_summary AS (
        SELECT 
            severity,
            COUNT(*) as count,
            MIN(alert_timestamp) as oldest_alert,
            MAX(alert_timestamp) as newest_alert
        FROM db_alerts
        WHERE status = 'active'
        GROUP BY severity
    ),
    recent_alerts AS (
        SELECT 
            a.id,
            a.alert_title,
            a.alert_message,
            a.severity,
            a.alert_timestamp,
            a.metric_value,
            r.rule_name
        FROM db_alerts a
        JOIN db_alert_rules r ON a.rule_id = r.id
        WHERE a.status = 'active'
        ORDER BY a.alert_timestamp DESC
        LIMIT 10
    )
    SELECT jsonb_build_object(
        'timestamp', NOW(),
        'summary', jsonb_object_agg(
            severity, 
            jsonb_build_object(
                'count', count,
                'oldest', oldest_alert,
                'newest', newest_alert
            )
        ),
        'recent_alerts', jsonb_agg(
            jsonb_build_object(
                'id', id,
                'title', alert_title,
                'message', alert_message,
                'severity', severity,
                'timestamp', alert_timestamp,
                'metric_value', metric_value,
                'rule_name', rule_name
            )
        ),
        'total_active', (SELECT COUNT(*) FROM db_alerts WHERE status = 'active')
    ) INTO result
    FROM alert_summary
    GROUP BY ()
    HAVING COUNT(*) > 0;
    
    -- Handle case with no active alerts
    IF result IS NULL THEN
        result := jsonb_build_object(
            'timestamp', NOW(),
            'summary', jsonb_build_object(),
            'recent_alerts', jsonb_build_array(),
            'total_active', 0
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_alert_rules_active ON db_alert_rules(is_active, rule_type);
CREATE INDEX IF NOT EXISTS idx_alerts_status_timestamp ON db_alerts(status, alert_timestamp);
CREATE INDEX IF NOT EXISTS idx_alerts_severity_status ON db_alerts(severity, status);
CREATE INDEX IF NOT EXISTS idx_alert_notifications_status ON db_alert_notifications(status, notification_timestamp);
CREATE INDEX IF NOT EXISTS idx_alert_suppressions_active ON db_alert_suppressions(is_active, start_time, end_time);

-- Grant permissions
GRANT SELECT ON db_alert_rules TO demo_user;
GRANT SELECT ON db_alerts TO demo_user;
GRANT SELECT ON db_alert_notifications TO demo_user;
GRANT SELECT ON db_alert_suppressions TO demo_user;
GRANT EXECUTE ON FUNCTION evaluate_alert_rule(UUID) TO demo_user;
GRANT EXECUTE ON FUNCTION evaluate_all_alert_rules() TO demo_user;
GRANT EXECUTE ON FUNCTION get_alerts_dashboard() TO demo_user;