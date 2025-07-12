-- SUBAGENT 1: Data Generation Engine for Load Testing
-- Mission: Generate massive-scale test data for enterprise performance validation
-- Scope: 100K+ calls, 5 months historical, 1000+ agents, 68 queues

-- =====================================================
-- Configuration and Setup
-- =====================================================

-- Load test configuration
CREATE TABLE IF NOT EXISTS load_test_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_name VARCHAR(100) NOT NULL,
    target_calls INTEGER DEFAULT 100000,
    target_queues INTEGER DEFAULT 68,
    target_agents INTEGER DEFAULT 1000,
    historical_months INTEGER DEFAULT 5,
    peak_multiplier DECIMAL(5,2) DEFAULT 2.5,
    seasonal_variation DECIMAL(5,2) DEFAULT 0.3,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Load test tracking
CREATE TABLE IF NOT EXISTS load_test_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_phase VARCHAR(50) NOT NULL,
    phase_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    phase_end TIMESTAMP,
    records_generated INTEGER DEFAULT 0,
    generation_rate_per_second DECIMAL(10,2),
    memory_usage_mb INTEGER,
    status VARCHAR(20) DEFAULT 'running',
    notes TEXT
);

-- Insert default configuration
INSERT INTO load_test_config (test_name, target_calls, target_queues, target_agents, historical_months)
VALUES ('ENTERPRISE_LOAD_TEST', 100000, 68, 1000, 5)
ON CONFLICT DO NOTHING;

-- =====================================================
-- Queue Generation with Realistic Patterns
-- =====================================================

CREATE OR REPLACE FUNCTION generate_enterprise_queues() RETURNS INTEGER AS $$
DECLARE
    queue_count INTEGER := 0;
    queue_templates TEXT[] := ARRAY[
        'SALES_INBOUND', 'SALES_OUTBOUND', 'CUSTOMER_SERVICE', 'TECHNICAL_SUPPORT',
        'BILLING_INQUIRIES', 'ACCOUNT_MANAGEMENT', 'RETENTION_TEAM', 'NEW_CUSTOMER_ONBOARDING',
        'VIP_SUPPORT', 'ENTERPRISE_SUPPORT', 'SMALL_BUSINESS', 'RESIDENTIAL_SUPPORT',
        'SPANISH_SUPPORT', 'FRENCH_SUPPORT', 'CHAT_SUPPORT', 'EMAIL_SUPPORT',
        'SOCIAL_MEDIA_TEAM', 'ESCALATION_QUEUE', 'SUPERVISOR_QUEUE', 'QUALITY_ASSURANCE',
        'TRAINING_QUEUE', 'OVERFLOW_QUEUE', 'AFTER_HOURS', 'WEEKEND_SUPPORT',
        'HOLIDAY_SUPPORT', 'EMERGENCY_SUPPORT', 'OUTAGE_SUPPORT', 'FIELD_SERVICES',
        'INSTALLATION_TEAM', 'REPAIR_SERVICES', 'MAINTENANCE_CREW', 'PROVISIONING_TEAM',
        'ACTIVATION_SERVICES', 'DEACTIVATION_TEAM', 'COLLECTIONS_TEAM', 'FRAUD_PREVENTION',
        'COMPLIANCE_TEAM', 'LEGAL_SUPPORT', 'EXECUTIVE_SUPPORT', 'PARTNER_SUPPORT',
        'DEALER_SUPPORT', 'VENDOR_MANAGEMENT', 'PROCUREMENT_TEAM', 'HR_SUPPORT',
        'IT_HELPDESK', 'FACILITIES_TEAM', 'SECURITY_TEAM', 'AUDIT_TEAM',
        'FINANCE_SUPPORT', 'ACCOUNTING_TEAM', 'PAYROLL_SUPPORT', 'BENEFITS_TEAM',
        'MARKETING_SUPPORT', 'SALES_OPERATIONS', 'BUSINESS_DEVELOPMENT', 'PRODUCT_SUPPORT',
        'ENGINEERING_SUPPORT', 'DEVELOPMENT_TEAM', 'TESTING_TEAM', 'DEPLOYMENT_TEAM',
        'MONITORING_TEAM', 'ANALYTICS_TEAM', 'REPORTING_TEAM', 'DATA_TEAM',
        'RESEARCH_TEAM', 'INNOVATION_LAB', 'BETA_TESTING', 'PILOT_PROGRAMS'
    ];
BEGIN
    -- Clear existing load test queues
    DELETE FROM queues WHERE queue_id LIKE 'LOAD_QUEUE_%';
    
    -- Generate 68 enterprise queues with realistic configurations
    FOR i IN 1..68 LOOP
        INSERT INTO queues (
            queue_id, queue_name, queue_type, is_active, max_concurrent_calls,
            skill_requirements, priority_level, business_hours_start, business_hours_end,
            timezone, sla_target_seconds, max_wait_time_seconds
        ) VALUES (
            'LOAD_QUEUE_' || LPAD(i::TEXT, 3, '0'),
            CASE 
                WHEN i <= array_length(queue_templates, 1) THEN queue_templates[i]
                ELSE 'ENTERPRISE_QUEUE_' || i
            END,
            CASE (i % 5)
                WHEN 0 THEN 'inbound'
                WHEN 1 THEN 'outbound'
                WHEN 2 THEN 'blended'
                WHEN 3 THEN 'chat'
                ELSE 'email'
            END,
            TRUE,
            CASE 
                WHEN i <= 10 THEN 100 + (i * 10)  -- High volume queues
                WHEN i <= 30 THEN 50 + (i * 5)   -- Medium volume queues
                ELSE 20 + (i * 2)                -- Standard queues
            END,
            CASE (i % 3)
                WHEN 0 THEN '["voice", "chat"]'::jsonb
                WHEN 1 THEN '["voice", "email", "chat"]'::jsonb
                ELSE '["voice"]'::jsonb
            END,
            CASE 
                WHEN i <= 5 THEN 'critical'
                WHEN i <= 20 THEN 'high'
                WHEN i <= 50 THEN 'medium'
                ELSE 'low'
            END,
            TIME '08:00:00',
            TIME '20:00:00',
            'America/New_York',
            CASE 
                WHEN i <= 10 THEN 20  -- Premium SLA
                WHEN i <= 30 THEN 30  -- Standard SLA
                ELSE 60               -- Basic SLA
            END,
            CASE 
                WHEN i <= 10 THEN 120  -- Premium max wait
                WHEN i <= 30 THEN 300  -- Standard max wait
                ELSE 600               -- Basic max wait
            END
        ) ON CONFLICT (queue_id) DO UPDATE SET
            queue_name = EXCLUDED.queue_name,
            max_concurrent_calls = EXCLUDED.max_concurrent_calls;
        
        queue_count := queue_count + 1;
    END LOOP;
    
    RETURN queue_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Agent Generation with Multi-Skill Profiles
-- =====================================================

CREATE OR REPLACE FUNCTION generate_enterprise_agents() RETURNS INTEGER AS $$
DECLARE
    agent_count INTEGER := 0;
    skill_combinations JSONB[] := ARRAY[
        '["voice"]'::jsonb,
        '["voice", "chat"]'::jsonb,
        '["voice", "email"]'::jsonb,
        '["voice", "chat", "email"]'::jsonb,
        '["chat", "email"]'::jsonb,
        '["voice", "technical"]'::jsonb,
        '["voice", "sales"]'::jsonb,
        '["voice", "billing"]'::jsonb,
        '["voice", "spanish"]'::jsonb,
        '["voice", "french"]'::jsonb,
        '["voice", "chat", "technical"]'::jsonb,
        '["voice", "chat", "sales"]'::jsonb,
        '["voice", "email", "billing"]'::jsonb,
        '["supervisor", "voice", "chat"]'::jsonb,
        '["trainer", "voice"]'::jsonb
    ];
BEGIN
    -- Clear existing load test agents
    DELETE FROM agents WHERE agent_id LIKE 'LOAD_AGENT_%';
    
    -- Generate 1000 agents with realistic profiles
    FOR i IN 1..1000 LOOP
        INSERT INTO agents (
            agent_id, agent_name, email, phone, 
            employment_type, hire_date, is_active, max_concurrent_calls, 
            skill_level, skills, shift_pattern, hourly_rate, department,
            manager_id, location, timezone
        ) VALUES (
            'LOAD_AGENT_' || LPAD(i::TEXT, 4, '0'),
            'Agent ' || LPAD(i::TEXT, 4, '0') || ' ' || 
            CASE (i % 10)
                WHEN 0 THEN 'Smith'
                WHEN 1 THEN 'Johnson'
                WHEN 2 THEN 'Williams'
                WHEN 3 THEN 'Brown'
                WHEN 4 THEN 'Jones'
                WHEN 5 THEN 'Garcia'
                WHEN 6 THEN 'Miller'
                WHEN 7 THEN 'Davis'
                WHEN 8 THEN 'Rodriguez'
                ELSE 'Wilson'
            END,
            'agent' || i || '@enterprise.com',
            '+1-555-' || LPAD(i::TEXT, 7, '0'),
            CASE (i % 4)
                WHEN 0 THEN 'full_time'
                WHEN 1 THEN 'part_time'
                WHEN 2 THEN 'contractor'
                ELSE 'intern'
            END,
            CURRENT_DATE - INTERVAL '2 years' + (random() * INTERVAL '730 days'),
            TRUE,
            CASE (i % 4)
                WHEN 0 THEN 1
                WHEN 1 THEN 2
                WHEN 2 THEN 3
                ELSE 4
            END,
            (random() * 5)::INTEGER + 1,
            skill_combinations[1 + (random() * (array_length(skill_combinations, 1) - 1))::INTEGER],
            CASE (i % 5)
                WHEN 0 THEN 'morning'
                WHEN 1 THEN 'afternoon'
                WHEN 2 THEN 'evening'
                WHEN 3 THEN 'night'
                ELSE 'rotating'
            END,
            15.00 + (random() * 25.00),
            CASE (i % 8)
                WHEN 0 THEN 'Customer Service'
                WHEN 1 THEN 'Technical Support'
                WHEN 2 THEN 'Sales'
                WHEN 3 THEN 'Billing'
                WHEN 4 THEN 'Retention'
                WHEN 5 THEN 'Quality'
                WHEN 6 THEN 'Training'
                ELSE 'Support'
            END,
            CASE 
                WHEN i <= 100 THEN 'LOAD_AGENT_' || LPAD(((i / 10) + 1)::TEXT, 4, '0')
                ELSE NULL
            END,
            CASE (i % 5)
                WHEN 0 THEN 'New York'
                WHEN 1 THEN 'Los Angeles'
                WHEN 2 THEN 'Chicago'
                WHEN 3 THEN 'Houston'
                ELSE 'Phoenix'
            END,
            CASE (i % 5)
                WHEN 0 THEN 'America/New_York'
                WHEN 1 THEN 'America/Los_Angeles'
                WHEN 2 THEN 'America/Chicago'
                WHEN 3 THEN 'America/Chicago'
                ELSE 'America/Phoenix'
            END
        ) ON CONFLICT (agent_id) DO UPDATE SET
            agent_name = EXCLUDED.agent_name,
            skills = EXCLUDED.skills;
        
        agent_count := agent_count + 1;
    END LOOP;
    
    RETURN agent_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Historical Call Data Generation (5 Months)
-- =====================================================

CREATE OR REPLACE FUNCTION generate_historical_call_data() RETURNS INTEGER AS $$
DECLARE
    total_calls INTEGER := 0;
    month_offset INTEGER;
    day_offset INTEGER;
    hour_offset INTEGER;
    current_date DATE;
    current_hour INTEGER;
    queue_id TEXT;
    base_volume INTEGER;
    hourly_volume INTEGER;
    seasonal_factor DECIMAL(5,2);
    day_of_week INTEGER;
    is_business_hours BOOLEAN;
    batch_size INTEGER := 1000;
    batch_count INTEGER := 0;
BEGIN
    -- Clear existing historical data
    DELETE FROM contact_statistics WHERE queue_id LIKE 'LOAD_QUEUE_%';
    
    -- Generate 5 months of historical data (January 2025 - May 2025)
    FOR month_offset IN 0..4 LOOP
        FOR day_offset IN 0..29 LOOP -- Approximately 30 days per month
            current_date := DATE '2025-01-01' + (month_offset * INTERVAL '30 days') + (day_offset * INTERVAL '1 day');
            day_of_week := EXTRACT(DOW FROM current_date);
            
            -- Skip weekends for most queues (simulate business patterns)
            IF day_of_week IN (0, 6) THEN
                -- Weekend volume is 30% of weekday
                seasonal_factor := 0.3;
            ELSE
                -- Weekday volume with seasonal variation
                seasonal_factor := 1.0 + (0.2 * sin(month_offset * PI() / 2));
            END IF;
            
            -- Generate hourly data for each day
            FOR hour_offset IN 0..23 LOOP
                current_hour := hour_offset;
                is_business_hours := (current_hour >= 8 AND current_hour <= 20);
                
                -- Generate calls for each queue
                FOR i IN 1..68 LOOP
                    queue_id := 'LOAD_QUEUE_' || LPAD(i::TEXT, 3, '0');
                    
                    -- Base volume varies by queue priority and size
                    base_volume := CASE 
                        WHEN i <= 10 THEN 50 + (random() * 100)::INTEGER  -- High volume
                        WHEN i <= 30 THEN 20 + (random() * 50)::INTEGER   -- Medium volume
                        ELSE 5 + (random() * 20)::INTEGER                 -- Low volume
                    END;
                    
                    -- Apply business hours factor
                    IF is_business_hours THEN
                        hourly_volume := (base_volume * seasonal_factor)::INTEGER;
                    ELSE
                        hourly_volume := (base_volume * seasonal_factor * 0.2)::INTEGER; -- 20% after hours
                    END IF;
                    
                    -- Peak hours adjustment (10AM-2PM and 6PM-8PM)
                    IF current_hour IN (10, 11, 12, 13, 14, 18, 19) THEN
                        hourly_volume := (hourly_volume * 1.5)::INTEGER;
                    END IF;
                    
                    -- Insert call statistics
                    INSERT INTO contact_statistics (
                        interval_start,
                        interval_end,
                        queue_id,
                        offered_calls,
                        answered_calls,
                        abandoned_calls,
                        avg_handle_time,
                        avg_wait_time,
                        service_level_20s,
                        max_wait_time,
                        total_talk_time,
                        total_hold_time,
                        total_after_call_work,
                        occupancy_rate,
                        shrinkage_rate
                    ) VALUES (
                        current_date + (current_hour * INTERVAL '1 hour'),
                        current_date + (current_hour * INTERVAL '1 hour') + INTERVAL '1 hour',
                        queue_id,
                        hourly_volume,
                        GREATEST(0, hourly_volume - (random() * hourly_volume * 0.15)::INTEGER), -- 85-100% answered
                        LEAST(hourly_volume, (random() * hourly_volume * 0.15)::INTEGER), -- 0-15% abandoned
                        120 + (random() * 240)::INTEGER, -- 2-6 minutes AHT
                        5 + (random() * 55)::INTEGER,    -- 5-60 seconds wait
                        CASE 
                            WHEN hourly_volume > 30 THEN 70 + (random() * 25)::INTEGER  -- 70-95% SL
                            ELSE 80 + (random() * 20)::INTEGER                          -- 80-100% SL
                        END,
                        60 + (random() * 540)::INTEGER,  -- 1-10 minutes max wait
                        hourly_volume * (80 + (random() * 160)::INTEGER), -- Talk time
                        hourly_volume * (10 + (random() * 50)::INTEGER),  -- Hold time
                        hourly_volume * (30 + (random() * 90)::INTEGER),  -- ACW time
                        (random() * 0.3 + 0.6)::DECIMAL(5,2), -- 60-90% occupancy
                        (random() * 0.2 + 0.1)::DECIMAL(5,2)  -- 10-30% shrinkage
                    );
                    
                    total_calls := total_calls + hourly_volume;
                    batch_count := batch_count + 1;
                    
                    -- Progress reporting every 1000 records
                    IF batch_count % batch_size = 0 THEN
                        INSERT INTO load_test_tracking (test_phase, records_generated, status, notes)
                        VALUES ('HISTORICAL_DATA_GENERATION', batch_count, 'progress', 
                               'Generated ' || batch_count || ' intervals, ' || total_calls || ' total calls');
                    END IF;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
    
    -- Final tracking entry
    INSERT INTO load_test_tracking (test_phase, records_generated, status, notes)
    VALUES ('HISTORICAL_DATA_GENERATION', batch_count, 'completed', 
           'Generated ' || batch_count || ' intervals, ' || total_calls || ' total calls across 5 months');
    
    RETURN total_calls;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Real-time Data Generation
-- =====================================================

CREATE OR REPLACE FUNCTION generate_realtime_data() RETURNS INTEGER AS $$
DECLARE
    records_generated INTEGER := 0;
    queue_id TEXT;
    agent_id TEXT;
BEGIN
    -- Clear existing real-time data
    DELETE FROM realtime_queues WHERE queue_id LIKE 'LOAD_QUEUE_%';
    DELETE FROM realtime_agents WHERE agent_id LIKE 'LOAD_AGENT_%';
    
    -- Generate real-time queue data
    FOR i IN 1..68 LOOP
        queue_id := 'LOAD_QUEUE_' || LPAD(i::TEXT, 3, '0');
        
        INSERT INTO realtime_queues (
            queue_id, queue_name, queue_status, calls_waiting, calls_in_progress,
            agents_available, agents_busy, agents_unavailable, longest_wait_time,
            avg_wait_time, service_level_current, calls_today, abandoned_today,
            avg_handle_time_today, peak_concurrent_calls, total_agents_assigned
        ) VALUES (
            queue_id,
            (SELECT queue_name FROM queues WHERE queue_id = queue_id),
            'active',
            (random() * 25)::INTEGER,  -- 0-25 calls waiting
            (random() * 40)::INTEGER,  -- 0-40 calls in progress
            (random() * 15)::INTEGER + 1,  -- 1-15 agents available
            (random() * 20)::INTEGER,      -- 0-20 agents busy
            (random() * 8)::INTEGER,       -- 0-8 agents unavailable
            (random() * 450)::INTEGER + 10, -- 10-460 seconds longest wait
            (random() * 90)::INTEGER + 5,   -- 5-95 seconds average wait
            (random() * 30)::INTEGER + 70,  -- 70-100% current service level
            (random() * 800)::INTEGER + 200, -- 200-1000 calls today
            (random() * 120)::INTEGER + 10,  -- 10-130 abandoned today
            (random() * 180)::INTEGER + 120, -- 120-300 seconds AHT today
            (random() * 60)::INTEGER + 20,   -- 20-80 peak concurrent
            (random() * 30)::INTEGER + 10    -- 10-40 total agents assigned
        ) ON CONFLICT (queue_id) DO UPDATE SET
            calls_waiting = EXCLUDED.calls_waiting,
            calls_in_progress = EXCLUDED.calls_in_progress,
            agents_available = EXCLUDED.agents_available,
            agents_busy = EXCLUDED.agents_busy,
            updated_at = CURRENT_TIMESTAMP;
        
        records_generated := records_generated + 1;
    END LOOP;
    
    -- Generate real-time agent data
    FOR i IN 1..1000 LOOP
        agent_id := 'LOAD_AGENT_' || LPAD(i::TEXT, 4, '0');
        
        INSERT INTO realtime_agents (
            agent_id, agent_name, current_state, current_queue_id,
            state_duration, calls_today, avg_handle_time_today,
            last_call_end, next_break_time, calls_handled_today,
            total_talk_time_today, total_hold_time_today, adherence_percentage
        ) VALUES (
            agent_id,
            (SELECT agent_name FROM agents WHERE agent_id = agent_id),
            CASE ((random() * 6)::INTEGER)
                WHEN 0 THEN 'available'
                WHEN 1 THEN 'busy'
                WHEN 2 THEN 'on_call'
                WHEN 3 THEN 'break'
                WHEN 4 THEN 'lunch'
                ELSE 'unavailable'
            END,
            'LOAD_QUEUE_' || LPAD(((random() * 67)::INTEGER + 1)::TEXT, 3, '0'),
            (random() * 7200)::INTEGER + 60,  -- 1-7200 seconds in current state
            (random() * 50)::INTEGER + 5,     -- 5-55 calls today
            (random() * 200)::INTEGER + 100,  -- 100-300 seconds AHT today
            CURRENT_TIMESTAMP - (random() * INTERVAL '4 hours'),
            CURRENT_TIMESTAMP + (random() * INTERVAL '6 hours'),
            (random() * 45)::INTEGER + 5,     -- 5-50 calls handled today
            (random() * 14400)::INTEGER + 3600, -- 1-5 hours talk time today
            (random() * 1800)::INTEGER + 300,   -- 5-35 minutes hold time today
            (random() * 20)::INTEGER + 80       -- 80-100% adherence
        ) ON CONFLICT (agent_id) DO UPDATE SET
            current_state = EXCLUDED.current_state,
            current_queue_id = EXCLUDED.current_queue_id,
            state_duration = EXCLUDED.state_duration,
            updated_at = CURRENT_TIMESTAMP;
        
        records_generated := records_generated + 1;
    END LOOP;
    
    RETURN records_generated;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Master Data Generation Function
-- =====================================================

CREATE OR REPLACE FUNCTION execute_load_test_data_generation() RETURNS TEXT AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    total_duration INTERVAL;
    queues_generated INTEGER;
    agents_generated INTEGER;
    calls_generated INTEGER;
    realtime_generated INTEGER;
    result_summary TEXT;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    
    -- Track start of data generation
    INSERT INTO load_test_tracking (test_phase, status, notes)
    VALUES ('LOAD_TEST_DATA_GENERATION', 'started', 'Beginning enterprise-scale data generation');
    
    -- Phase 1: Generate Queues
    RAISE NOTICE 'Phase 1: Generating 68 enterprise queues...';
    SELECT generate_enterprise_queues() INTO queues_generated;
    
    -- Phase 2: Generate Agents
    RAISE NOTICE 'Phase 2: Generating 1000 agents with multi-skill profiles...';
    SELECT generate_enterprise_agents() INTO agents_generated;
    
    -- Phase 3: Generate Historical Call Data
    RAISE NOTICE 'Phase 3: Generating 5 months of historical call data...';
    SELECT generate_historical_call_data() INTO calls_generated;
    
    -- Phase 4: Generate Real-time Data
    RAISE NOTICE 'Phase 4: Generating real-time monitoring data...';
    SELECT generate_realtime_data() INTO realtime_generated;
    
    end_time := CURRENT_TIMESTAMP;
    total_duration := end_time - start_time;
    
    -- Final tracking entry
    INSERT INTO load_test_tracking (test_phase, phase_end, records_generated, status, notes)
    VALUES ('LOAD_TEST_DATA_GENERATION', end_time, 
           queues_generated + agents_generated + calls_generated + realtime_generated,
           'completed', 'All data generation phases completed successfully');
    
    -- Build result summary
    result_summary := format(
        'LOAD TEST DATA GENERATION COMPLETED
        =================================
        Duration: %s
        Queues Generated: %s
        Agents Generated: %s
        Historical Calls: %s
        Real-time Records: %s
        Total Records: %s
        
        Database ready for enterprise-scale load testing!',
        total_duration,
        queues_generated,
        agents_generated,
        calls_generated,
        realtime_generated,
        queues_generated + agents_generated + calls_generated + realtime_generated
    );
    
    RAISE NOTICE '%', result_summary;
    
    RETURN result_summary;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Data Generation Monitoring Views
-- =====================================================

-- Real-time progress monitoring
CREATE OR REPLACE VIEW load_test_progress AS
SELECT 
    test_phase,
    phase_start,
    phase_end,
    records_generated,
    status,
    CASE 
        WHEN phase_end IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (phase_end - phase_start))
        ELSE 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - phase_start))
    END as duration_seconds,
    CASE 
        WHEN phase_end IS NOT NULL AND records_generated > 0 THEN 
            records_generated / EXTRACT(EPOCH FROM (phase_end - phase_start))
        ELSE NULL
    END as records_per_second,
    notes
FROM load_test_tracking
ORDER BY phase_start DESC;

-- Data generation summary
CREATE OR REPLACE VIEW load_test_summary AS
SELECT 
    'Load Test Data Summary' as metric,
    (SELECT COUNT(*) FROM queues WHERE queue_id LIKE 'LOAD_QUEUE_%') as queues,
    (SELECT COUNT(*) FROM agents WHERE agent_id LIKE 'LOAD_AGENT_%') as agents,
    (SELECT COUNT(*) FROM contact_statistics WHERE queue_id LIKE 'LOAD_QUEUE_%') as historical_intervals,
    (SELECT COUNT(*) FROM realtime_queues WHERE queue_id LIKE 'LOAD_QUEUE_%') as realtime_queues,
    (SELECT COUNT(*) FROM realtime_agents WHERE agent_id LIKE 'LOAD_AGENT_%') as realtime_agents,
    (SELECT SUM(offered_calls) FROM contact_statistics WHERE queue_id LIKE 'LOAD_QUEUE_%') as total_calls,
    pg_size_pretty(pg_total_relation_size('contact_statistics')) as contact_stats_size,
    pg_size_pretty(pg_database_size(current_database())) as total_db_size;

-- Performance metrics during generation
CREATE OR REPLACE VIEW load_test_performance AS
SELECT 
    test_phase,
    records_generated,
    ROUND(records_generated / EXTRACT(EPOCH FROM (COALESCE(phase_end, CURRENT_TIMESTAMP) - phase_start)), 2) as records_per_second,
    memory_usage_mb,
    status,
    phase_start,
    phase_end
FROM load_test_tracking
WHERE records_generated > 0
ORDER BY phase_start DESC;

-- =====================================================
-- Cleanup Function
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_load_test_data() RETURNS TEXT AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete all load test data
    DELETE FROM contact_statistics WHERE queue_id LIKE 'LOAD_QUEUE_%';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    DELETE FROM realtime_queues WHERE queue_id LIKE 'LOAD_QUEUE_%';
    DELETE FROM realtime_agents WHERE agent_id LIKE 'LOAD_AGENT_%';
    DELETE FROM queues WHERE queue_id LIKE 'LOAD_QUEUE_%';
    DELETE FROM agents WHERE agent_id LIKE 'LOAD_AGENT_%';
    DELETE FROM load_test_tracking;
    
    RETURN format('Cleanup completed. Deleted %s call records and all associated test data.', deleted_count);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Usage Instructions
-- =====================================================

/*
SUBAGENT 1: DATA GENERATION ENGINE - USAGE INSTRUCTIONS

1. Execute full data generation:
   SELECT execute_load_test_data_generation();

2. Monitor progress:
   SELECT * FROM load_test_progress;

3. View generation summary:
   SELECT * FROM load_test_summary;

4. Check performance during generation:
   SELECT * FROM load_test_performance;

5. Cleanup all test data:
   SELECT cleanup_load_test_data();

GENERATED DATA INCLUDES:
- 68 enterprise queues with realistic configurations
- 1000 agents with multi-skill profiles
- 5 months of historical call data (500K+ calls)
- Real-time monitoring data for current state
- Seasonal patterns and business hour variations
- Peak/off-peak call distributions
- Multi-skill agent assignments
- Realistic performance metrics

The generated data provides comprehensive coverage for:
- Peak load testing (100K+ calls/day)
- Historical analysis (5 months of data)
- Multi-skill query complexity
- Real-time monitoring scenarios
- Enterprise-scale performance validation
*/