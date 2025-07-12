-- Database Schema Stubs for DATABASE-OPUS
-- Flexible JSONB schemas that can evolve as requirements clarify

-- Universal flexible storage for rapid development
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

-- Indexes for performance
CREATE INDEX idx_universal_type ON universal_data(entity_type);
CREATE INDEX idx_universal_entity ON universal_data(entity_type, entity_id);
CREATE INDEX idx_universal_data ON universal_data USING GIN(data);
CREATE INDEX idx_universal_created ON universal_data(created_at);

-- Forecast storage stub
CREATE TABLE IF NOT EXISTS forecast_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forecast_date DATE NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_minutes INTEGER DEFAULT 15,
    queue_id VARCHAR(255),
    channel_type VARCHAR(50), -- 'voice', 'email', 'chat', etc.
    metrics JSONB NOT NULL, -- {volume, aht, shrinkage, etc.}
    ml_models JSONB, -- {model_type, parameters, accuracy}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(forecast_date, interval_start, queue_id, channel_type)
);

-- Schedule storage stub
CREATE TABLE IF NOT EXISTS schedule_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_date DATE NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    shift_data JSONB NOT NULL, -- {start, end, breaks, activities}
    skills JSONB DEFAULT '[]', -- ['voice', 'email', 'chat']
    optimization_score DECIMAL(5,2),
    constraints JSONB DEFAULT '{}', -- {min_hours, max_hours, preferences}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(schedule_date, agent_id)
);

-- Vacancy tracking stub
CREATE TABLE IF NOT EXISTS vacancy_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vacancy_date DATE NOT NULL,
    interval_start TIME NOT NULL,
    interval_end TIME NOT NULL,
    required_staff INTEGER,
    scheduled_staff INTEGER,
    gap INTEGER GENERATED ALWAYS AS (required_staff - scheduled_staff) STORED,
    skills_required JSONB DEFAULT '[]',
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'partial', 'filled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Real-time metrics stub
CREATE TABLE IF NOT EXISTS realtime_metrics_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metric_type VARCHAR(50) NOT NULL, -- 'queue_status', 'agent_status', 'sla'
    entity_id VARCHAR(255),
    metrics JSONB NOT NULL,
    alerts JSONB DEFAULT '[]',
    PRIMARY KEY (metric_timestamp, metric_type, entity_id)
);

-- Algorithm results stub
CREATE TABLE IF NOT EXISTS algorithm_results_stub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_type VARCHAR(50) NOT NULL, -- 'erlang_c', 'optimization', 'forecast'
    input_params JSONB NOT NULL,
    results JSONB NOT NULL,
    execution_time_ms INTEGER,
    accuracy_metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Helper functions for JSONB operations
CREATE OR REPLACE FUNCTION update_universal_data(
    p_entity_type VARCHAR,
    p_entity_id VARCHAR,
    p_data JSONB
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO universal_data (entity_type, entity_id, data)
    VALUES (p_entity_type, p_entity_id, p_data)
    ON CONFLICT (entity_type, entity_id) 
    DO UPDATE SET 
        data = universal_data.data || p_data,
        updated_at = CURRENT_TIMESTAMP,
        version = universal_data.version + 1
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Example usage for other agents:
/*
-- Store forecast data
SELECT update_universal_data('forecast', '2024-01-15-queue1', 
    '{"date": "2024-01-15", "queue": "queue1", "intervals": [...]}'::jsonb);

-- Store schedule data
INSERT INTO schedule_stub (schedule_date, agent_id, shift_data, skills)
VALUES ('2024-01-15', 'agent123', 
    '{"start": "09:00", "end": "17:00", "breaks": ["12:00-13:00"]}'::jsonb,
    '["voice", "email"]'::jsonb);

-- Query with JSONB
SELECT * FROM universal_data 
WHERE entity_type = 'forecast' 
AND data->>'queue' = 'queue1';
*/