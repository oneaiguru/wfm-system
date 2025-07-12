-- Phase 3: Flexible JSONB Schemas for Rapid Development
-- Implements stub schemas that can evolve as requirements clarify
-- Enables immediate integration with ALGORITHM-OPUS, UI-OPUS, and INTEGRATION-OPUS

-- =====================================================
-- Universal Storage Pattern
-- =====================================================
-- Flexible storage that accepts any data format from other agents
CREATE TABLE IF NOT EXISTS universal_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL, -- 'forecast', 'schedule', 'vacancy', etc.
    entity_id VARCHAR(255),
    data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    version INTEGER DEFAULT 1,
    UNIQUE(entity_type, entity_id)
);

-- High-performance indexes for JSONB queries
CREATE INDEX IF NOT EXISTS idx_universal_type ON universal_data(entity_type);
CREATE INDEX IF NOT EXISTS idx_universal_entity ON universal_data(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_universal_data ON universal_data USING GIN(data);
CREATE INDEX IF NOT EXISTS idx_universal_created ON universal_data(created_at);
CREATE INDEX IF NOT EXISTS idx_universal_updated ON universal_data(updated_at);

-- =====================================================
-- Forecasting & Calculations (for ALGORITHM-OPUS)
-- =====================================================
CREATE TABLE IF NOT EXISTS forecast_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forecast_date DATE NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_minutes INTEGER DEFAULT 15,
    queue_id VARCHAR(255),
    channel_type VARCHAR(50) DEFAULT 'voice', -- 'voice', 'email', 'chat', etc.
    
    -- Flexible metrics storage
    metrics JSONB NOT NULL DEFAULT '{}', -- {volume, aht, shrinkage, etc.}
    ml_models JSONB DEFAULT '{}', -- {model_type, parameters, accuracy}
    
    -- Algorithm integration
    algorithm_input JSONB DEFAULT '{}', -- Raw input for ALGORITHM-OPUS
    algorithm_output JSONB DEFAULT '{}', -- Results from ALGORITHM-OPUS
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    
    UNIQUE(forecast_date, interval_start, queue_id, channel_type)
);

-- Indexes for forecast queries
CREATE INDEX IF NOT EXISTS idx_forecast_date ON forecast_stub(forecast_date);
CREATE INDEX IF NOT EXISTS idx_forecast_queue ON forecast_stub(queue_id);
CREATE INDEX IF NOT EXISTS idx_forecast_metrics ON forecast_stub USING GIN(metrics);
CREATE INDEX IF NOT EXISTS idx_forecast_interval ON forecast_stub(interval_start);

-- Partitioning for scale (monthly)
CREATE TABLE IF NOT EXISTS forecast_stub_2025_01 PARTITION OF forecast_stub
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE IF NOT EXISTS forecast_stub_2025_02 PARTITION OF forecast_stub
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- =====================================================
-- Schedule Management (for UI-OPUS display)
-- =====================================================
CREATE TABLE IF NOT EXISTS schedule_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_date DATE NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    
    -- Flexible schedule storage
    shift_data JSONB NOT NULL DEFAULT '{}', -- {start, end, breaks, activities}
    skills JSONB DEFAULT '[]', -- ['voice', 'email', 'chat']
    
    -- Optimization data
    optimization_score DECIMAL(5,2),
    optimization_details JSONB DEFAULT '{}',
    constraints JSONB DEFAULT '{}', -- {min_hours, max_hours, preferences}
    
    -- UI display hints
    ui_metadata JSONB DEFAULT '{}', -- Color coding, display preferences
    
    -- Tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(255),
    version INTEGER DEFAULT 1,
    
    UNIQUE(schedule_date, agent_id)
);

-- Indexes for schedule queries
CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule_stub(schedule_date);
CREATE INDEX IF NOT EXISTS idx_schedule_agent ON schedule_stub(agent_id);
CREATE INDEX IF NOT EXISTS idx_schedule_skills ON schedule_stub USING GIN(skills);
CREATE INDEX IF NOT EXISTS idx_schedule_shift ON schedule_stub USING GIN(shift_data);

-- =====================================================
-- Vacancy & Coverage Tracking
-- =====================================================
CREATE TABLE IF NOT EXISTS vacancy_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vacancy_date DATE NOT NULL,
    interval_start TIME NOT NULL,
    interval_end TIME NOT NULL,
    queue_id VARCHAR(255),
    
    -- Staffing requirements
    required_staff INTEGER DEFAULT 0,
    scheduled_staff INTEGER DEFAULT 0,
    gap INTEGER GENERATED ALWAYS AS (required_staff - scheduled_staff) STORED,
    
    -- Flexible requirements
    skills_required JSONB DEFAULT '[]',
    channel_requirements JSONB DEFAULT '{}', -- Per-channel staffing
    
    -- Status tracking
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'partial', 'filled', 'overstaffed'
    alerts JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for vacancy queries
CREATE INDEX IF NOT EXISTS idx_vacancy_date ON vacancy_stub(vacancy_date);
CREATE INDEX IF NOT EXISTS idx_vacancy_gap ON vacancy_stub(gap) WHERE gap != 0;
CREATE INDEX IF NOT EXISTS idx_vacancy_status ON vacancy_stub(status);
CREATE INDEX IF NOT EXISTS idx_vacancy_priority ON vacancy_stub(priority);

-- =====================================================
-- Real-time Monitoring (for INTEGRATION-OPUS WebSocket)
-- =====================================================
CREATE TABLE IF NOT EXISTS realtime_metrics_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metric_type VARCHAR(50) NOT NULL, -- 'queue_status', 'agent_status', 'sla', 'performance'
    entity_id VARCHAR(255), -- Queue ID, Agent ID, etc.
    
    -- Flexible metric storage
    metrics JSONB NOT NULL DEFAULT '{}',
    thresholds JSONB DEFAULT '{}', -- Alert thresholds
    alerts JSONB DEFAULT '[]',
    
    -- WebSocket metadata
    websocket_channel VARCHAR(100),
    broadcast_required BOOLEAN DEFAULT FALSE,
    
    -- Retention
    ttl_hours INTEGER DEFAULT 24 -- Auto-cleanup after N hours
);

-- Partition by hour for real-time data
CREATE INDEX IF NOT EXISTS idx_realtime_timestamp ON realtime_metrics_stub(metric_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_realtime_type ON realtime_metrics_stub(metric_type);
CREATE INDEX IF NOT EXISTS idx_realtime_entity ON realtime_metrics_stub(entity_id);
CREATE INDEX IF NOT EXISTS idx_realtime_metrics ON realtime_metrics_stub USING GIN(metrics);

-- =====================================================
-- Algorithm Results Storage
-- =====================================================
CREATE TABLE IF NOT EXISTS algorithm_results_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_type VARCHAR(50) NOT NULL, -- 'erlang_c', 'optimization', 'forecast', 'ml_prediction'
    algorithm_version VARCHAR(20) DEFAULT 'v1',
    
    -- Input/Output
    input_params JSONB NOT NULL,
    results JSONB NOT NULL,
    
    -- Performance tracking
    execution_time_ms INTEGER,
    memory_usage_mb INTEGER,
    
    -- Accuracy tracking
    accuracy_metrics JSONB DEFAULT '{}',
    comparison_data JSONB DEFAULT '{}', -- For A/B testing
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    
    -- Debugging
    debug_info JSONB DEFAULT '{}'
);

-- Indexes for algorithm results
CREATE INDEX IF NOT EXISTS idx_algo_type ON algorithm_results_stub(algorithm_type);
CREATE INDEX IF NOT EXISTS idx_algo_created ON algorithm_results_stub(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_algo_execution ON algorithm_results_stub(execution_time_ms);

-- =====================================================
-- Helper Functions for JSONB Operations
-- =====================================================

-- Universal data upsert
CREATE OR REPLACE FUNCTION update_universal_data(
    p_entity_type VARCHAR,
    p_entity_id VARCHAR,
    p_data JSONB
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO universal_data (entity_type, entity_id, data, updated_at, version)
    VALUES (p_entity_type, p_entity_id, p_data, CURRENT_TIMESTAMP, 1)
    ON CONFLICT (entity_type, entity_id) 
    DO UPDATE SET 
        data = universal_data.data || p_data,
        updated_at = CURRENT_TIMESTAMP,
        version = universal_data.version + 1
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Get latest version of entity
CREATE OR REPLACE FUNCTION get_universal_data(
    p_entity_type VARCHAR,
    p_entity_id VARCHAR
) RETURNS JSONB AS $$
BEGIN
    RETURN (
        SELECT data 
        FROM universal_data 
        WHERE entity_type = p_entity_type 
        AND entity_id = p_entity_id
    );
END;
$$ LANGUAGE plpgsql;

-- Store forecast from ALGORITHM-OPUS
CREATE OR REPLACE FUNCTION store_forecast(
    p_date DATE,
    p_interval TIMESTAMP WITH TIME ZONE,
    p_queue VARCHAR,
    p_metrics JSONB,
    p_ml_model JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO forecast_stub (
        forecast_date, interval_start, queue_id, metrics, ml_models
    ) VALUES (
        p_date, p_interval, p_queue, p_metrics, COALESCE(p_ml_model, '{}')
    )
    ON CONFLICT (forecast_date, interval_start, queue_id, channel_type)
    DO UPDATE SET
        metrics = forecast_stub.metrics || p_metrics,
        ml_models = CASE 
            WHEN p_ml_model IS NOT NULL THEN forecast_stub.ml_models || p_ml_model
            ELSE forecast_stub.ml_models
        END,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Store schedule from optimization
CREATE OR REPLACE FUNCTION store_schedule(
    p_date DATE,
    p_agent VARCHAR,
    p_shift JSONB,
    p_skills JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO schedule_stub (
        schedule_date, agent_id, shift_data, skills, version
    ) VALUES (
        p_date, p_agent, p_shift, p_skills, 1
    )
    ON CONFLICT (schedule_date, agent_id)
    DO UPDATE SET
        shift_data = p_shift,
        skills = p_skills,
        updated_at = CURRENT_TIMESTAMP,
        version = schedule_stub.version + 1
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Store real-time metrics from INTEGRATION-OPUS
CREATE OR REPLACE FUNCTION store_realtime_metric(
    p_type VARCHAR,
    p_entity VARCHAR,
    p_metrics JSONB,
    p_broadcast BOOLEAN DEFAULT FALSE
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO realtime_metrics_stub (
        metric_type, entity_id, metrics, broadcast_required
    ) VALUES (
        p_type, p_entity, p_metrics, p_broadcast
    ) RETURNING id INTO v_id;
    
    -- Trigger WebSocket broadcast if needed
    IF p_broadcast THEN
        PERFORM pg_notify('realtime_update', json_build_object(
            'type', p_type,
            'entity', p_entity,
            'metrics', p_metrics
        )::text);
    END IF;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Views for Other Agents
-- =====================================================

-- Forecast summary for UI-OPUS
CREATE OR REPLACE VIEW v_forecast_summary AS
SELECT 
    forecast_date,
    queue_id,
    SUM((metrics->>'volume')::INTEGER) as total_volume,
    AVG((metrics->>'aht')::INTEGER) as avg_handle_time,
    COUNT(*) as interval_count
FROM forecast_stub
WHERE forecast_date >= CURRENT_DATE
GROUP BY forecast_date, queue_id;

-- Schedule overview for UI-OPUS
CREATE OR REPLACE VIEW v_schedule_overview AS
SELECT 
    schedule_date,
    COUNT(DISTINCT agent_id) as scheduled_agents,
    COUNT(DISTINCT shift_data->>'start') as unique_shifts,
    jsonb_agg(DISTINCT skills) as all_skills
FROM schedule_stub
WHERE schedule_date >= CURRENT_DATE
GROUP BY schedule_date;

-- Real-time dashboard for INTEGRATION-OPUS
CREATE OR REPLACE VIEW v_realtime_dashboard AS
SELECT 
    metric_type,
    entity_id,
    metrics,
    alerts,
    metric_timestamp
FROM realtime_metrics_stub
WHERE metric_timestamp > CURRENT_TIMESTAMP - INTERVAL '5 minutes'
ORDER BY metric_timestamp DESC;

-- Vacancy alerts for scheduling
CREATE OR REPLACE VIEW v_vacancy_alerts AS
SELECT 
    vacancy_date,
    COUNT(*) FILTER (WHERE gap > 0) as understaffed_intervals,
    COUNT(*) FILTER (WHERE gap < 0) as overstaffed_intervals,
    SUM(gap) as total_gap,
    jsonb_agg(
        jsonb_build_object(
            'interval', interval_start || '-' || interval_end,
            'gap', gap,
            'priority', priority
        ) ORDER BY gap DESC
    ) as critical_intervals
FROM vacancy_stub
WHERE vacancy_date >= CURRENT_DATE
AND status != 'filled'
GROUP BY vacancy_date;

-- =====================================================
-- Migration Path Documentation
-- =====================================================
COMMENT ON TABLE universal_data IS 'Flexible storage for any entity type - will be migrated to specific tables as schemas solidify';
COMMENT ON TABLE forecast_stub IS 'Forecasting data stub - accepts any format from ALGORITHM-OPUS, will evolve to structured schema';
COMMENT ON TABLE schedule_stub IS 'Schedule storage stub - flexible format for UI-OPUS integration, supports iterative development';
COMMENT ON TABLE realtime_metrics_stub IS 'Real-time metrics stub - WebSocket ready, accepts any metric format from INTEGRATION-OPUS';

-- =====================================================
-- Example Usage for Integration
-- =====================================================
/*
-- ALGORITHM-OPUS can store any forecast format:
SELECT store_forecast(
    '2025-01-15'::date,
    '2025-01-15 09:00:00+00'::timestamptz,
    'SALES_QUEUE_1',
    '{"volume": 150, "aht": 180, "shrinkage": 0.15}'::jsonb,
    '{"model": "enhanced_erlang", "accuracy": 0.92}'::jsonb
);

-- UI-OPUS can query schedules flexibly:
SELECT agent_id, shift_data->>'start' as shift_start, skills
FROM schedule_stub
WHERE schedule_date = '2025-01-15'
AND skills ? 'voice';

-- INTEGRATION-OPUS can push real-time updates:
SELECT store_realtime_metric(
    'queue_status',
    'SALES_QUEUE_1',
    '{"calls_waiting": 5, "longest_wait": 120, "agents_available": 3}'::jsonb,
    true -- Broadcast via WebSocket
);

-- Universal storage for any new requirement:
SELECT update_universal_data(
    'dashboard_config',
    'supervisor_main',
    '{"layout": "grid", "widgets": ["queue_status", "agent_performance"]}'::jsonb
);
*/

-- =====================================================
-- Maintenance & Cleanup
-- =====================================================

-- Auto-cleanup old real-time data
CREATE OR REPLACE FUNCTION cleanup_old_realtime_data() RETURNS void AS $$
BEGIN
    DELETE FROM realtime_metrics_stub
    WHERE metric_timestamp < CURRENT_TIMESTAMP - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup job (run daily)
-- SELECT cron.schedule('cleanup-realtime', '0 2 * * *', 'SELECT cleanup_old_realtime_data();');

-- =====================================================
-- Performance Monitoring
-- =====================================================

-- Track JSONB query performance
CREATE OR REPLACE FUNCTION analyze_jsonb_performance() RETURNS TABLE(
    table_name TEXT,
    index_name TEXT,
    index_size TEXT,
    index_scans BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname||'.'||tablename,
        indexname,
        pg_size_pretty(pg_relation_size(indexname::regclass)),
        idx_scan
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE '%jsonb%' OR indexname LIKE '%gin%'
    ORDER BY idx_scan DESC;
END;
$$ LANGUAGE plpgsql;

-- Success! All stub schemas ready for immediate use by other agents