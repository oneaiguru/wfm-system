-- Phase 3: Forecasting & Calculations Schema
-- Critical dependency for ALGORITHM-OPUS integration
-- Implements structured tables alongside JSONB stubs for gradual migration

-- =====================================================
-- Core Forecasting Tables
-- =====================================================

-- Forecast models and configurations
CREATE TABLE IF NOT EXISTS forecast_models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(100) NOT NULL UNIQUE,
    model_type VARCHAR(50) NOT NULL, -- 'erlang_c', 'ml_enhanced', 'hybrid', 'custom'
    model_version VARCHAR(20) NOT NULL DEFAULT 'v1.0',
    
    -- Model parameters
    parameters JSONB NOT NULL DEFAULT '{}',
    feature_config JSONB DEFAULT '{}', -- Which features to use
    
    -- Performance metrics
    avg_accuracy DECIMAL(5,2),
    last_training_date TIMESTAMP WITH TIME ZONE,
    training_data_size INTEGER,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    
    CONSTRAINT chk_one_default CHECK (
        (SELECT COUNT(*) FROM forecast_models WHERE is_default = TRUE) <= 1
    )
);

-- Historical patterns for ML training
CREATE TABLE IF NOT EXISTS historical_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_date DATE NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    week_of_year INTEGER NOT NULL CHECK (week_of_year BETWEEN 1 AND 53),
    
    -- Pattern identification
    queue_id VARCHAR(255) NOT NULL,
    channel_type VARCHAR(50) DEFAULT 'voice',
    interval_minutes INTEGER DEFAULT 15,
    
    -- Historical metrics
    avg_volume DECIMAL(10,2),
    avg_handle_time INTEGER, -- seconds
    avg_after_call_work INTEGER, -- seconds
    service_level_pct DECIMAL(5,2),
    
    -- Seasonality factors
    seasonality_factor DECIMAL(5,3) DEFAULT 1.0,
    special_event VARCHAR(100), -- holidays, campaigns, etc.
    
    -- Data quality
    data_points INTEGER NOT NULL,
    confidence_score DECIMAL(5,2),
    
    UNIQUE(pattern_date, queue_id, channel_type, interval_minutes)
);

-- Forecast calculation requests and results
CREATE TABLE IF NOT EXISTS forecast_calculations (
    calculation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forecast_date DATE NOT NULL,
    calculation_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'adhoc'
    
    -- Scope
    queues JSONB NOT NULL DEFAULT '[]', -- List of queue IDs
    channels JSONB DEFAULT '["voice"]',
    date_range_start DATE NOT NULL,
    date_range_end DATE NOT NULL,
    
    -- Model selection
    model_id UUID REFERENCES forecast_models(model_id),
    model_overrides JSONB DEFAULT '{}', -- Override model parameters
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    
    -- Results summary
    total_intervals_calculated INTEGER,
    avg_calculation_time_ms INTEGER,
    accuracy_metrics JSONB DEFAULT '{}',
    
    -- Metadata
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    requested_by VARCHAR(255),
    
    CHECK (date_range_end >= date_range_start)
);

-- Detailed forecast results
CREATE TABLE IF NOT EXISTS forecast_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_id UUID REFERENCES forecast_calculations(calculation_id) ON DELETE CASCADE,
    
    -- Time dimensions
    forecast_date DATE NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Scope
    queue_id VARCHAR(255) NOT NULL,
    channel_type VARCHAR(50) DEFAULT 'voice',
    
    -- Core metrics
    forecasted_volume INTEGER NOT NULL,
    forecasted_aht INTEGER NOT NULL, -- seconds
    forecasted_occupancy DECIMAL(5,2),
    
    -- Staffing calculations
    required_staff DECIMAL(6,2) NOT NULL,
    required_staff_rounded INTEGER NOT NULL,
    shrinkage_factor DECIMAL(5,3) DEFAULT 0.15,
    
    -- Service level targets
    target_service_level DECIMAL(5,2) DEFAULT 80.0,
    target_answer_time INTEGER DEFAULT 20, -- seconds
    expected_service_level DECIMAL(5,2),
    
    -- Confidence and accuracy
    confidence_interval_lower INTEGER,
    confidence_interval_upper INTEGER,
    confidence_level DECIMAL(5,2) DEFAULT 95.0,
    
    -- Algorithm details
    algorithm_used VARCHAR(50),
    calculation_time_ms INTEGER,
    
    -- Adjustments
    manual_adjustment DECIMAL(5,2) DEFAULT 0,
    adjustment_reason TEXT,
    
    UNIQUE(calculation_id, forecast_date, interval_start, queue_id, channel_type)
);

-- Partitioning for forecast results (monthly)
-- Handled via trigger for automatic partition creation

-- Forecast accuracy tracking
CREATE TABLE IF NOT EXISTS forecast_accuracy (
    accuracy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forecast_date DATE NOT NULL,
    queue_id VARCHAR(255) NOT NULL,
    channel_type VARCHAR(50) DEFAULT 'voice',
    
    -- Comparison data
    forecasted_volume INTEGER,
    actual_volume INTEGER,
    volume_variance DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN actual_volume > 0 THEN ((forecasted_volume - actual_volume)::DECIMAL / actual_volume * 100)
            ELSE 0
        END
    ) STORED,
    
    forecasted_aht INTEGER,
    actual_aht INTEGER,
    aht_variance DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN actual_aht > 0 THEN ((forecasted_aht - actual_aht)::DECIMAL / actual_aht * 100)
            ELSE 0
        END
    ) STORED,
    
    -- Accuracy metrics
    mape DECIMAL(5,2), -- Mean Absolute Percentage Error
    rmse DECIMAL(10,2), -- Root Mean Square Error
    mae DECIMAL(10,2), -- Mean Absolute Error
    
    -- Model info
    model_id UUID REFERENCES forecast_models(model_id),
    calculation_id UUID REFERENCES forecast_calculations(calculation_id),
    
    -- Timestamp
    evaluated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(forecast_date, queue_id, channel_type)
);

-- Special events and overrides
CREATE TABLE IF NOT EXISTS forecast_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'holiday', 'campaign', 'system_outage', 'weather', 'custom'
    
    -- Event timing
    event_date DATE,
    start_time TIME,
    end_time TIME,
    
    -- Impact configuration
    affected_queues JSONB DEFAULT '[]', -- Empty means all queues
    impact_factor DECIMAL(5,3) DEFAULT 1.0, -- Multiplier for volume
    impact_type VARCHAR(20) DEFAULT 'multiply', -- 'multiply', 'add', 'override'
    
    -- Overrides
    volume_override INTEGER,
    aht_override INTEGER,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    auto_apply BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    notes TEXT
);

-- =====================================================
-- Calculation Functions
-- =====================================================

-- Function to create forecast calculation request
CREATE OR REPLACE FUNCTION create_forecast_calculation(
    p_forecast_date DATE,
    p_date_start DATE,
    p_date_end DATE,
    p_queues JSONB DEFAULT '[]',
    p_model_name VARCHAR DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_calculation_id UUID;
    v_model_id UUID;
BEGIN
    -- Get model ID
    IF p_model_name IS NOT NULL THEN
        SELECT model_id INTO v_model_id
        FROM forecast_models
        WHERE model_name = p_model_name AND is_active = TRUE;
    ELSE
        SELECT model_id INTO v_model_id
        FROM forecast_models
        WHERE is_default = TRUE AND is_active = TRUE;
    END IF;
    
    -- Create calculation request
    INSERT INTO forecast_calculations (
        forecast_date,
        calculation_type,
        queues,
        date_range_start,
        date_range_end,
        model_id,
        status
    ) VALUES (
        p_forecast_date,
        'adhoc',
        p_queues,
        p_date_start,
        p_date_end,
        v_model_id,
        'pending'
    ) RETURNING calculation_id INTO v_calculation_id;
    
    -- Notify ALGORITHM-OPUS
    PERFORM pg_notify('forecast_requested', json_build_object(
        'calculation_id', v_calculation_id,
        'forecast_date', p_forecast_date,
        'model_id', v_model_id
    )::text);
    
    RETURN v_calculation_id;
END;
$$ LANGUAGE plpgsql;

-- Function to store forecast results from ALGORITHM-OPUS
CREATE OR REPLACE FUNCTION store_forecast_results(
    p_calculation_id UUID,
    p_results JSONB
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_result JSONB;
BEGIN
    -- Update calculation status
    UPDATE forecast_calculations
    SET status = 'running',
        started_at = CURRENT_TIMESTAMP
    WHERE calculation_id = p_calculation_id;
    
    -- Insert results
    FOR v_result IN SELECT * FROM jsonb_array_elements(p_results)
    LOOP
        INSERT INTO forecast_results (
            calculation_id,
            forecast_date,
            interval_start,
            interval_end,
            queue_id,
            channel_type,
            forecasted_volume,
            forecasted_aht,
            required_staff,
            required_staff_rounded,
            algorithm_used,
            calculation_time_ms
        ) VALUES (
            p_calculation_id,
            (v_result->>'forecast_date')::DATE,
            (v_result->>'interval_start')::TIMESTAMP WITH TIME ZONE,
            (v_result->>'interval_end')::TIMESTAMP WITH TIME ZONE,
            v_result->>'queue_id',
            COALESCE(v_result->>'channel_type', 'voice'),
            (v_result->>'volume')::INTEGER,
            (v_result->>'aht')::INTEGER,
            (v_result->>'required_staff')::DECIMAL,
            ROUND((v_result->>'required_staff')::DECIMAL),
            v_result->>'algorithm',
            (v_result->>'calc_time_ms')::INTEGER
        ) ON CONFLICT (calculation_id, forecast_date, interval_start, queue_id, channel_type)
        DO UPDATE SET
            forecasted_volume = EXCLUDED.forecasted_volume,
            forecasted_aht = EXCLUDED.forecasted_aht,
            required_staff = EXCLUDED.required_staff,
            required_staff_rounded = EXCLUDED.required_staff_rounded;
            
        v_count := v_count + 1;
    END LOOP;
    
    -- Update calculation status
    UPDATE forecast_calculations
    SET status = 'completed',
        completed_at = CURRENT_TIMESTAMP,
        total_intervals_calculated = v_count
    WHERE calculation_id = p_calculation_id;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate forecast accuracy
CREATE OR REPLACE FUNCTION calculate_forecast_accuracy(
    p_forecast_date DATE,
    p_queue_id VARCHAR DEFAULT NULL
) RETURNS TABLE(
    queue_id VARCHAR,
    volume_mape DECIMAL,
    aht_mape DECIMAL,
    overall_accuracy DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    WITH accuracy_calc AS (
        SELECT 
            fr.queue_id,
            AVG(ABS(fr.forecasted_volume - cs.offered_calls) / NULLIF(cs.offered_calls, 0) * 100) as vol_mape,
            AVG(ABS(fr.forecasted_aht - cs.avg_handle_time) / NULLIF(cs.avg_handle_time, 0) * 100) as aht_mape
        FROM forecast_results fr
        JOIN contact_statistics cs ON 
            cs.interval_start = fr.interval_start
            AND cs.queue_id = fr.queue_id
        WHERE fr.forecast_date = p_forecast_date
        AND (p_queue_id IS NULL OR fr.queue_id = p_queue_id)
        GROUP BY fr.queue_id
    )
    SELECT 
        ac.queue_id,
        ROUND(ac.vol_mape, 2),
        ROUND(ac.aht_mape, 2),
        ROUND(100 - (ac.vol_mape + ac.aht_mape) / 2, 2) as overall_accuracy
    FROM accuracy_calc ac;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Views for Integration
-- =====================================================

-- Current forecast summary
CREATE OR REPLACE VIEW v_current_forecasts AS
SELECT 
    fc.forecast_date,
    fc.status,
    fm.model_name,
    fm.model_type,
    COUNT(DISTINCT fr.queue_id) as queues_forecasted,
    SUM(fr.forecasted_volume) as total_volume,
    AVG(fr.required_staff_rounded) as avg_required_staff,
    fc.completed_at
FROM forecast_calculations fc
LEFT JOIN forecast_models fm ON fc.model_id = fm.model_id
LEFT JOIN forecast_results fr ON fc.calculation_id = fr.calculation_id
WHERE fc.forecast_date >= CURRENT_DATE
GROUP BY fc.calculation_id, fc.forecast_date, fc.status, fm.model_name, fm.model_type, fc.completed_at
ORDER BY fc.forecast_date DESC;

-- Forecast vs Actual comparison
CREATE OR REPLACE VIEW v_forecast_accuracy_summary AS
SELECT 
    fa.forecast_date,
    COUNT(DISTINCT fa.queue_id) as queues_evaluated,
    AVG(fa.mape) as avg_mape,
    MIN(fa.mape) as best_mape,
    MAX(fa.mape) as worst_mape,
    AVG(ABS(fa.volume_variance)) as avg_volume_variance_pct,
    AVG(ABS(fa.aht_variance)) as avg_aht_variance_pct
FROM forecast_accuracy fa
WHERE fa.forecast_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY fa.forecast_date
ORDER BY fa.forecast_date DESC;

-- Model performance comparison
CREATE OR REPLACE VIEW v_model_performance AS
SELECT 
    fm.model_name,
    fm.model_type,
    COUNT(DISTINCT fa.forecast_date) as days_evaluated,
    AVG(fa.mape) as avg_mape,
    STDDEV(fa.mape) as mape_stddev,
    MIN(fa.mape) as best_mape,
    MAX(fa.mape) as worst_mape,
    fm.is_active,
    fm.is_default
FROM forecast_models fm
LEFT JOIN forecast_accuracy fa ON fm.model_id = fa.model_id
WHERE fa.evaluated_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY fm.model_id, fm.model_name, fm.model_type, fm.is_active, fm.is_default
ORDER BY avg_mape ASC NULLS LAST;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Forecast models
CREATE INDEX IF NOT EXISTS idx_forecast_models_active ON forecast_models(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_forecast_models_default ON forecast_models(is_default) WHERE is_default = TRUE;

-- Historical patterns
CREATE INDEX IF NOT EXISTS idx_patterns_queue_date ON historical_patterns(queue_id, pattern_date);
CREATE INDEX IF NOT EXISTS idx_patterns_dow ON historical_patterns(day_of_week);
CREATE INDEX IF NOT EXISTS idx_patterns_special ON historical_patterns(special_event) WHERE special_event IS NOT NULL;

-- Forecast calculations
CREATE INDEX IF NOT EXISTS idx_calculations_status ON forecast_calculations(status);
CREATE INDEX IF NOT EXISTS idx_calculations_date ON forecast_calculations(forecast_date);
CREATE INDEX IF NOT EXISTS idx_calculations_requested ON forecast_calculations(requested_at);

-- Forecast results
CREATE INDEX IF NOT EXISTS idx_results_calculation ON forecast_results(calculation_id);
CREATE INDEX IF NOT EXISTS idx_results_date_queue ON forecast_results(forecast_date, queue_id);
CREATE INDEX IF NOT EXISTS idx_results_interval ON forecast_results(interval_start);
CREATE INDEX IF NOT EXISTS idx_results_staff ON forecast_results(required_staff_rounded);

-- Forecast accuracy
CREATE INDEX IF NOT EXISTS idx_accuracy_date ON forecast_accuracy(forecast_date);
CREATE INDEX IF NOT EXISTS idx_accuracy_queue ON forecast_accuracy(queue_id);
CREATE INDEX IF NOT EXISTS idx_accuracy_variance ON forecast_accuracy(volume_variance);

-- Forecast events
CREATE INDEX IF NOT EXISTS idx_events_date ON forecast_events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_active ON forecast_events(is_active) WHERE is_active = TRUE;

-- =====================================================
-- Migration from JSONB Stubs
-- =====================================================

-- Migrate forecast data from stub to structured
CREATE OR REPLACE FUNCTION migrate_forecast_from_stub() RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Insert into forecast_results from forecast_stub
    INSERT INTO forecast_results (
        forecast_date,
        interval_start,
        interval_end,
        queue_id,
        channel_type,
        forecasted_volume,
        forecasted_aht,
        required_staff,
        required_staff_rounded,
        algorithm_used
    )
    SELECT 
        forecast_date,
        interval_start,
        interval_start + (interval_minutes || ' minutes')::INTERVAL,
        queue_id,
        channel_type,
        (metrics->>'volume')::INTEGER,
        (metrics->>'aht')::INTEGER,
        (metrics->>'required_staff')::DECIMAL,
        ROUND((metrics->>'required_staff')::DECIMAL),
        COALESCE(algorithm_output->>'algorithm', 'erlang_c')
    FROM forecast_stub
    WHERE NOT EXISTS (
        SELECT 1 FROM forecast_results fr
        WHERE fr.forecast_date = forecast_stub.forecast_date
        AND fr.interval_start = forecast_stub.interval_start
        AND fr.queue_id = forecast_stub.queue_id
    );
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Initial Data
-- =====================================================

-- Insert default forecast models
INSERT INTO forecast_models (model_name, model_type, parameters, is_default) VALUES
('Standard Erlang C', 'erlang_c', '{"target_service_level": 80, "target_answer_time": 20}', TRUE),
('Enhanced Erlang C', 'erlang_c', '{"target_service_level": 80, "target_answer_time": 20, "multi_skill": true}', FALSE),
('ML Forecast Model', 'ml_enhanced', '{"features": ["historical", "seasonality", "events"], "algorithm": "xgboost"}', FALSE)
ON CONFLICT (model_name) DO NOTHING;

-- Insert common special events
INSERT INTO forecast_events (event_name, event_type, event_date, impact_factor) VALUES
('New Year', 'holiday', '2025-01-01', 0.3),
('Christmas', 'holiday', '2025-12-25', 0.2),
('Black Friday', 'campaign', '2025-11-29', 2.5)
ON CONFLICT DO NOTHING;

-- Success! Forecasting & Calculations schema ready for ALGORITHM-OPUS integration