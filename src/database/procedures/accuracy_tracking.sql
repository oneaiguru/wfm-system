-- =============================================
-- Accuracy Tracking Infrastructure for Argus-WFM Comparison
-- =============================================
-- Purpose: Track accuracy metrics, deviations, and patterns between Argus and WFM calculations
-- Created: 2025-07-10
-- =============================================

-- Drop existing objects if they exist
DROP SCHEMA IF EXISTS accuracy CASCADE;
CREATE SCHEMA accuracy;

-- =============================================
-- Core Accuracy Tracking Tables
-- =============================================

-- Main accuracy metrics table for tracking differences
CREATE TABLE accuracy.metrics (
    metric_id SERIAL PRIMARY KEY,
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    business_unit VARCHAR(50) NOT NULL,
    project_code VARCHAR(100),
    interval_type VARCHAR(20) NOT NULL CHECK (interval_type IN ('15min', '30min', '1hour')),
    metric_type VARCHAR(50) NOT NULL,
    argus_value NUMERIC(15,4),
    wfm_value NUMERIC(15,4),
    absolute_difference NUMERIC(15,4),
    percentage_difference NUMERIC(10,4),
    confidence_score NUMERIC(5,2) CHECK (confidence_score BETWEEN 0 AND 100),
    data_quality_score NUMERIC(5,2) CHECK (data_quality_score BETWEEN 0 AND 100),
    is_outlier BOOLEAN DEFAULT FALSE,
    failure_reason TEXT,
    metadata JSONB
);

-- Deviation tracking by scenario type
CREATE TABLE accuracy.deviation_patterns (
    pattern_id SERIAL PRIMARY KEY,
    scenario_type VARCHAR(100) NOT NULL,
    business_unit VARCHAR(50),
    metric_type VARCHAR(50) NOT NULL,
    avg_deviation NUMERIC(10,4),
    std_deviation NUMERIC(10,4),
    min_deviation NUMERIC(10,4),
    max_deviation NUMERIC(10,4),
    sample_count INTEGER NOT NULL,
    confidence_interval_lower NUMERIC(10,4),
    confidence_interval_upper NUMERIC(10,4),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pattern_metadata JSONB
);

-- Multi-skill accuracy specific metrics
CREATE TABLE accuracy.multi_skill_accuracy (
    accuracy_id SERIAL PRIMARY KEY,
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    business_unit VARCHAR(50) NOT NULL,
    skill_combination VARCHAR(500) NOT NULL,
    agent_count INTEGER,
    argus_agent_allocation JSONB,
    wfm_agent_allocation JSONB,
    allocation_difference JSONB,
    skill_coverage_argus NUMERIC(5,2),
    skill_coverage_wfm NUMERIC(5,2),
    routing_accuracy NUMERIC(5,2),
    queue_distribution_accuracy NUMERIC(5,2),
    performance_impact_score NUMERIC(5,2)
);

-- Performance timing comparisons
CREATE TABLE accuracy.performance_metrics (
    performance_id SERIAL PRIMARY KEY,
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation_type VARCHAR(100) NOT NULL,
    data_volume INTEGER NOT NULL,
    interval_type VARCHAR(20),
    argus_processing_time_ms INTEGER,
    wfm_processing_time_ms INTEGER,
    memory_usage_mb INTEGER,
    cpu_usage_percent NUMERIC(5,2),
    error_count INTEGER DEFAULT 0,
    success_rate NUMERIC(5,2),
    metadata JSONB
);

-- Historical accuracy trending
CREATE TABLE accuracy.historical_trends (
    trend_id SERIAL PRIMARY KEY,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    business_unit VARCHAR(50),
    metric_type VARCHAR(50) NOT NULL,
    avg_accuracy NUMERIC(5,2),
    accuracy_trend NUMERIC(5,2), -- positive = improving, negative = declining
    volatility_score NUMERIC(5,2),
    data_points INTEGER NOT NULL,
    trend_confidence NUMERIC(5,2),
    anomaly_count INTEGER DEFAULT 0,
    UNIQUE(period_start, period_end, business_unit, metric_type)
);

-- Failure pattern identification
CREATE TABLE accuracy.failure_patterns (
    failure_id SERIAL PRIMARY KEY,
    detected_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pattern_type VARCHAR(100) NOT NULL,
    failure_category VARCHAR(50) NOT NULL,
    business_unit VARCHAR(50),
    affected_metrics TEXT[],
    root_cause TEXT,
    impact_severity VARCHAR(20) CHECK (impact_severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    occurrence_count INTEGER DEFAULT 1,
    last_occurrence TIMESTAMP WITH TIME ZONE,
    resolution_status VARCHAR(20) DEFAULT 'OPEN',
    mitigation_steps JSONB
);

-- Data quality tracking
CREATE TABLE accuracy.data_quality_issues (
    issue_id SERIAL PRIMARY KEY,
    detected_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255),
    issue_type VARCHAR(50) NOT NULL,
    column_name VARCHAR(100),
    row_count INTEGER,
    severity VARCHAR(20) CHECK (severity IN ('INFO', 'WARNING', 'ERROR', 'CRITICAL')),
    impact_description TEXT,
    auto_corrected BOOLEAN DEFAULT FALSE,
    correction_applied TEXT
);

-- Confidence scoring history
CREATE TABLE accuracy.confidence_scores (
    score_id SERIAL PRIMARY KEY,
    calculation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metric_type VARCHAR(50) NOT NULL,
    business_unit VARCHAR(50),
    base_confidence NUMERIC(5,2),
    data_quality_factor NUMERIC(5,2),
    historical_accuracy_factor NUMERIC(5,2),
    volume_factor NUMERIC(5,2),
    final_confidence NUMERIC(5,2),
    factors_metadata JSONB
);

-- =============================================
-- Key Indexes for Performance
-- =============================================

CREATE INDEX idx_metrics_timestamp ON accuracy.metrics(measurement_timestamp);
CREATE INDEX idx_metrics_business_unit ON accuracy.metrics(business_unit);
CREATE INDEX idx_metrics_type ON accuracy.metrics(metric_type);
CREATE INDEX idx_metrics_outlier ON accuracy.metrics(is_outlier) WHERE is_outlier = TRUE;

CREATE INDEX idx_multi_skill_timestamp ON accuracy.multi_skill_accuracy(measurement_timestamp);
CREATE INDEX idx_multi_skill_unit ON accuracy.multi_skill_accuracy(business_unit);

CREATE INDEX idx_performance_timestamp ON accuracy.performance_metrics(measurement_timestamp);
CREATE INDEX idx_performance_operation ON accuracy.performance_metrics(operation_type);

CREATE INDEX idx_trends_period ON accuracy.historical_trends(period_start, period_end);
CREATE INDEX idx_failure_patterns_status ON accuracy.failure_patterns(resolution_status) WHERE resolution_status = 'OPEN';

-- =============================================
-- Statistical Analysis Procedures
-- =============================================

-- Calculate confidence score based on multiple factors
CREATE OR REPLACE FUNCTION accuracy.calculate_confidence_score(
    p_metric_type VARCHAR,
    p_business_unit VARCHAR,
    p_data_quality_score NUMERIC,
    p_sample_size INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    v_base_confidence NUMERIC := 50.0;
    v_historical_accuracy NUMERIC;
    v_volume_factor NUMERIC;
    v_final_confidence NUMERIC;
BEGIN
    -- Get historical accuracy for this metric/unit combination
    SELECT AVG(avg_accuracy) INTO v_historical_accuracy
    FROM accuracy.historical_trends
    WHERE metric_type = p_metric_type
      AND (business_unit = p_business_unit OR p_business_unit IS NULL)
      AND period_end >= CURRENT_DATE - INTERVAL '30 days';
    
    -- Calculate volume factor (higher sample size = higher confidence)
    v_volume_factor := LEAST(100, GREATEST(10, LOG(p_sample_size + 1) * 20));
    
    -- Calculate final confidence
    v_final_confidence := (
        v_base_confidence * 0.2 +
        COALESCE(v_historical_accuracy, 50) * 0.3 +
        p_data_quality_score * 0.3 +
        v_volume_factor * 0.2
    );
    
    -- Log confidence calculation
    INSERT INTO accuracy.confidence_scores (
        metric_type, business_unit, base_confidence,
        data_quality_factor, historical_accuracy_factor,
        volume_factor, final_confidence, factors_metadata
    ) VALUES (
        p_metric_type, p_business_unit, v_base_confidence,
        p_data_quality_score, COALESCE(v_historical_accuracy, 50),
        v_volume_factor, v_final_confidence,
        jsonb_build_object(
            'sample_size', p_sample_size,
            'calculation_method', 'weighted_average'
        )
    );
    
    RETURN v_final_confidence;
END;
$$ LANGUAGE plpgsql;

-- Track accuracy metrics between Argus and WFM
CREATE OR REPLACE FUNCTION accuracy.track_metric_accuracy(
    p_business_unit VARCHAR,
    p_project_code VARCHAR,
    p_interval_type VARCHAR,
    p_metric_type VARCHAR,
    p_argus_value NUMERIC,
    p_wfm_value NUMERIC,
    p_metadata JSONB DEFAULT '{}'
) RETURNS TABLE (
    metric_id INTEGER,
    absolute_difference NUMERIC,
    percentage_difference NUMERIC,
    confidence_score NUMERIC,
    is_outlier BOOLEAN
) AS $$
DECLARE
    v_abs_diff NUMERIC;
    v_pct_diff NUMERIC;
    v_confidence NUMERIC;
    v_is_outlier BOOLEAN := FALSE;
    v_data_quality NUMERIC := 100.0;
    v_metric_id INTEGER;
    v_std_dev NUMERIC;
BEGIN
    -- Calculate differences
    v_abs_diff := ABS(p_argus_value - p_wfm_value);
    
    -- Calculate percentage difference (handle zero values)
    IF p_argus_value = 0 AND p_wfm_value = 0 THEN
        v_pct_diff := 0;
    ELSIF p_argus_value = 0 THEN
        v_pct_diff := 100;
    ELSE
        v_pct_diff := (v_abs_diff / ABS(p_argus_value)) * 100;
    END IF;
    
    -- Check for data quality issues
    IF p_argus_value IS NULL OR p_wfm_value IS NULL THEN
        v_data_quality := 0;
    ELSIF p_metadata->>'has_mixed_types' = 'true' THEN
        v_data_quality := 50;
    END IF;
    
    -- Calculate confidence score
    v_confidence := accuracy.calculate_confidence_score(
        p_metric_type,
        p_business_unit,
        v_data_quality,
        1  -- Single measurement
    );
    
    -- Detect outliers using statistical method
    SELECT stddev(percentage_difference) INTO v_std_dev
    FROM accuracy.metrics
    WHERE metric_type = p_metric_type
      AND business_unit = p_business_unit
      AND measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days';
    
    IF v_std_dev IS NOT NULL AND v_pct_diff > v_std_dev * 3 THEN
        v_is_outlier := TRUE;
    END IF;
    
    -- Insert metric record
    INSERT INTO accuracy.metrics (
        business_unit, project_code, interval_type, metric_type,
        argus_value, wfm_value, absolute_difference, percentage_difference,
        confidence_score, data_quality_score, is_outlier, metadata
    ) VALUES (
        p_business_unit, p_project_code, p_interval_type, p_metric_type,
        p_argus_value, p_wfm_value, v_abs_diff, v_pct_diff,
        v_confidence, v_data_quality, v_is_outlier, p_metadata
    ) RETURNING metrics.metric_id INTO v_metric_id;
    
    -- Update deviation patterns
    PERFORM accuracy.update_deviation_patterns(
        p_metric_type, p_business_unit, v_pct_diff
    );
    
    RETURN QUERY SELECT v_metric_id, v_abs_diff, v_pct_diff, v_confidence, v_is_outlier;
END;
$$ LANGUAGE plpgsql;

-- Track multi-skill accuracy
CREATE OR REPLACE FUNCTION accuracy.track_multi_skill_accuracy(
    p_business_unit VARCHAR,
    p_skill_combination VARCHAR,
    p_agent_count INTEGER,
    p_argus_allocation JSONB,
    p_wfm_allocation JSONB
) RETURNS INTEGER AS $$
DECLARE
    v_accuracy_id INTEGER;
    v_skill_coverage_argus NUMERIC;
    v_skill_coverage_wfm NUMERIC;
    v_routing_accuracy NUMERIC;
    v_queue_accuracy NUMERIC;
    v_allocation_diff JSONB;
BEGIN
    -- Calculate skill coverage percentages
    v_skill_coverage_argus := (p_argus_allocation->>'covered_skills')::NUMERIC / 
                              (p_argus_allocation->>'total_skills')::NUMERIC * 100;
    v_skill_coverage_wfm := (p_wfm_allocation->>'covered_skills')::NUMERIC / 
                            (p_wfm_allocation->>'total_skills')::NUMERIC * 100;
    
    -- Calculate routing accuracy
    v_routing_accuracy := 100 - ABS(v_skill_coverage_argus - v_skill_coverage_wfm);
    
    -- Calculate queue distribution accuracy
    v_queue_accuracy := accuracy.calculate_queue_distribution_accuracy(
        p_argus_allocation->'queue_distribution',
        p_wfm_allocation->'queue_distribution'
    );
    
    -- Calculate allocation differences
    v_allocation_diff := accuracy.calculate_allocation_differences(
        p_argus_allocation,
        p_wfm_allocation
    );
    
    -- Insert record
    INSERT INTO accuracy.multi_skill_accuracy (
        business_unit, skill_combination, agent_count,
        argus_agent_allocation, wfm_agent_allocation, allocation_difference,
        skill_coverage_argus, skill_coverage_wfm,
        routing_accuracy, queue_distribution_accuracy,
        performance_impact_score
    ) VALUES (
        p_business_unit, p_skill_combination, p_agent_count,
        p_argus_allocation, p_wfm_allocation, v_allocation_diff,
        v_skill_coverage_argus, v_skill_coverage_wfm,
        v_routing_accuracy, v_queue_accuracy,
        (v_routing_accuracy + v_queue_accuracy) / 2
    ) RETURNING accuracy_id INTO v_accuracy_id;
    
    RETURN v_accuracy_id;
END;
$$ LANGUAGE plpgsql;

-- Calculate queue distribution accuracy
CREATE OR REPLACE FUNCTION accuracy.calculate_queue_distribution_accuracy(
    p_argus_dist JSONB,
    p_wfm_dist JSONB
) RETURNS NUMERIC AS $$
DECLARE
    v_accuracy NUMERIC := 100.0;
    v_queue_key TEXT;
    v_argus_pct NUMERIC;
    v_wfm_pct NUMERIC;
    v_total_diff NUMERIC := 0;
    v_queue_count INTEGER := 0;
BEGIN
    -- Compare distribution percentages for each queue
    FOR v_queue_key IN SELECT jsonb_object_keys(p_argus_dist)
    LOOP
        v_argus_pct := (p_argus_dist->>v_queue_key)::NUMERIC;
        v_wfm_pct := COALESCE((p_wfm_dist->>v_queue_key)::NUMERIC, 0);
        v_total_diff := v_total_diff + ABS(v_argus_pct - v_wfm_pct);
        v_queue_count := v_queue_count + 1;
    END LOOP;
    
    -- Check for queues only in WFM
    FOR v_queue_key IN SELECT jsonb_object_keys(p_wfm_dist)
    LOOP
        IF NOT p_argus_dist ? v_queue_key THEN
            v_wfm_pct := (p_wfm_dist->>v_queue_key)::NUMERIC;
            v_total_diff := v_total_diff + v_wfm_pct;
            v_queue_count := v_queue_count + 1;
        END IF;
    END LOOP;
    
    IF v_queue_count > 0 THEN
        v_accuracy := GREATEST(0, 100 - (v_total_diff / v_queue_count));
    END IF;
    
    RETURN v_accuracy;
END;
$$ LANGUAGE plpgsql;

-- Calculate allocation differences
CREATE OR REPLACE FUNCTION accuracy.calculate_allocation_differences(
    p_argus_alloc JSONB,
    p_wfm_alloc JSONB
) RETURNS JSONB AS $$
DECLARE
    v_differences JSONB := '{}';
    v_key TEXT;
    v_argus_val NUMERIC;
    v_wfm_val NUMERIC;
BEGIN
    -- Compare all allocation metrics
    FOR v_key IN SELECT jsonb_object_keys(p_argus_alloc)
    LOOP
        v_argus_val := (p_argus_alloc->>v_key)::NUMERIC;
        v_wfm_val := COALESCE((p_wfm_alloc->>v_key)::NUMERIC, 0);
        
        v_differences := v_differences || jsonb_build_object(
            v_key, jsonb_build_object(
                'argus', v_argus_val,
                'wfm', v_wfm_val,
                'difference', v_argus_val - v_wfm_val,
                'pct_difference', CASE 
                    WHEN v_argus_val = 0 THEN NULL
                    ELSE ((v_argus_val - v_wfm_val) / v_argus_val * 100)
                END
            )
        );
    END LOOP;
    
    RETURN v_differences;
END;
$$ LANGUAGE plpgsql;

-- Update deviation patterns
CREATE OR REPLACE FUNCTION accuracy.update_deviation_patterns(
    p_metric_type VARCHAR,
    p_business_unit VARCHAR,
    p_deviation NUMERIC
) RETURNS VOID AS $$
DECLARE
    v_existing RECORD;
    v_new_avg NUMERIC;
    v_new_std NUMERIC;
    v_scenario_type VARCHAR;
BEGIN
    -- Determine scenario type based on metric
    v_scenario_type := CASE
        WHEN p_metric_type LIKE '%agent%' THEN 'agent_calculation'
        WHEN p_metric_type LIKE '%service_level%' THEN 'service_level'
        WHEN p_metric_type LIKE '%occupancy%' THEN 'occupancy'
        WHEN p_metric_type LIKE '%multi_skill%' THEN 'multi_skill'
        ELSE 'general'
    END;
    
    -- Check if pattern exists
    SELECT * INTO v_existing
    FROM accuracy.deviation_patterns
    WHERE scenario_type = v_scenario_type
      AND metric_type = p_metric_type
      AND (business_unit = p_business_unit OR (business_unit IS NULL AND p_business_unit IS NULL));
    
    IF FOUND THEN
        -- Update existing pattern
        v_new_avg := (v_existing.avg_deviation * v_existing.sample_count + p_deviation) / 
                     (v_existing.sample_count + 1);
        
        UPDATE accuracy.deviation_patterns
        SET avg_deviation = v_new_avg,
            min_deviation = LEAST(min_deviation, p_deviation),
            max_deviation = GREATEST(max_deviation, p_deviation),
            sample_count = sample_count + 1,
            last_updated = CURRENT_TIMESTAMP
        WHERE pattern_id = v_existing.pattern_id;
    ELSE
        -- Insert new pattern
        INSERT INTO accuracy.deviation_patterns (
            scenario_type, business_unit, metric_type,
            avg_deviation, std_deviation, min_deviation, max_deviation,
            sample_count, confidence_interval_lower, confidence_interval_upper
        ) VALUES (
            v_scenario_type, p_business_unit, p_metric_type,
            p_deviation, 0, p_deviation, p_deviation,
            1, p_deviation - 1.96, p_deviation + 1.96
        );
    END IF;
    
    -- Recalculate standard deviation if enough samples
    IF v_existing.sample_count >= 10 THEN
        PERFORM accuracy.recalculate_pattern_statistics(v_existing.pattern_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Recalculate pattern statistics
CREATE OR REPLACE FUNCTION accuracy.recalculate_pattern_statistics(
    p_pattern_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_std_dev NUMERIC;
    v_avg NUMERIC;
    v_count INTEGER;
BEGIN
    -- Calculate statistics from recent metrics
    SELECT 
        AVG(percentage_difference),
        STDDEV(percentage_difference),
        COUNT(*)
    INTO v_avg, v_std_dev, v_count
    FROM accuracy.metrics m
    JOIN accuracy.deviation_patterns p ON p.pattern_id = p_pattern_id
    WHERE m.metric_type = p.metric_type
      AND (m.business_unit = p.business_unit OR (m.business_unit IS NULL AND p.business_unit IS NULL))
      AND m.measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    -- Update pattern with new statistics
    UPDATE accuracy.deviation_patterns
    SET std_deviation = COALESCE(v_std_dev, 0),
        confidence_interval_lower = v_avg - (1.96 * COALESCE(v_std_dev, 0) / SQRT(v_count)),
        confidence_interval_upper = v_avg + (1.96 * COALESCE(v_std_dev, 0) / SQRT(v_count))
    WHERE pattern_id = p_pattern_id;
END;
$$ LANGUAGE plpgsql;

-- Track performance timing
CREATE OR REPLACE FUNCTION accuracy.track_performance_timing(
    p_operation_type VARCHAR,
    p_data_volume INTEGER,
    p_interval_type VARCHAR,
    p_argus_time_ms INTEGER,
    p_wfm_time_ms INTEGER,
    p_memory_mb INTEGER DEFAULT NULL,
    p_cpu_percent NUMERIC DEFAULT NULL,
    p_error_count INTEGER DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    v_performance_id INTEGER;
    v_success_rate NUMERIC;
BEGIN
    -- Calculate success rate based on errors
    v_success_rate := CASE
        WHEN p_error_count = 0 THEN 100.0
        WHEN p_data_volume > 0 THEN (1 - (p_error_count::NUMERIC / p_data_volume)) * 100
        ELSE 0.0
    END;
    
    INSERT INTO accuracy.performance_metrics (
        operation_type, data_volume, interval_type,
        argus_processing_time_ms, wfm_processing_time_ms,
        memory_usage_mb, cpu_usage_percent, error_count, success_rate
    ) VALUES (
        p_operation_type, p_data_volume, p_interval_type,
        p_argus_time_ms, p_wfm_time_ms,
        p_memory_mb, p_cpu_percent, p_error_count, v_success_rate
    ) RETURNING performance_id INTO v_performance_id;
    
    -- Check for performance degradation
    PERFORM accuracy.detect_performance_anomalies(p_operation_type);
    
    RETURN v_performance_id;
END;
$$ LANGUAGE plpgsql;

-- Detect performance anomalies
CREATE OR REPLACE FUNCTION accuracy.detect_performance_anomalies(
    p_operation_type VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_avg_time NUMERIC;
    v_recent_time NUMERIC;
    v_threshold NUMERIC := 2.0; -- 2x slower than average
BEGIN
    -- Get average processing time for this operation
    SELECT AVG(wfm_processing_time_ms) INTO v_avg_time
    FROM accuracy.performance_metrics
    WHERE operation_type = p_operation_type
      AND measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days';
    
    -- Get most recent processing time
    SELECT wfm_processing_time_ms INTO v_recent_time
    FROM accuracy.performance_metrics
    WHERE operation_type = p_operation_type
    ORDER BY measurement_timestamp DESC
    LIMIT 1;
    
    -- Check if recent performance is degraded
    IF v_recent_time > v_avg_time * v_threshold THEN
        INSERT INTO accuracy.failure_patterns (
            pattern_type, failure_category, affected_metrics,
            root_cause, impact_severity
        ) VALUES (
            'performance_degradation', 'PERFORMANCE', ARRAY[p_operation_type],
            'Processing time ' || v_recent_time || 'ms exceeds threshold of ' || 
            (v_avg_time * v_threshold)::INTEGER || 'ms',
            'HIGH'
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Generate historical trends
CREATE OR REPLACE FUNCTION accuracy.generate_historical_trends(
    p_start_date DATE,
    p_end_date DATE
) RETURNS INTEGER AS $$
DECLARE
    v_business_unit VARCHAR;
    v_metric_type VARCHAR;
    v_trend_count INTEGER := 0;
BEGIN
    -- Generate trends for each business unit and metric type combination
    FOR v_business_unit, v_metric_type IN
        SELECT DISTINCT business_unit, metric_type
        FROM accuracy.metrics
        WHERE measurement_timestamp::DATE BETWEEN p_start_date AND p_end_date
    LOOP
        INSERT INTO accuracy.historical_trends (
            period_start, period_end, business_unit, metric_type,
            avg_accuracy, accuracy_trend, volatility_score, data_points
        )
        SELECT
            p_start_date,
            p_end_date,
            v_business_unit,
            v_metric_type,
            100 - AVG(percentage_difference) AS avg_accuracy,
            -- Calculate trend (positive = improving)
            CASE 
                WHEN COUNT(*) < 2 THEN 0
                ELSE (100 - AVG(CASE WHEN measurement_timestamp::DATE > p_start_date + (p_end_date - p_start_date) / 2 
                                    THEN percentage_difference END)) -
                     (100 - AVG(CASE WHEN measurement_timestamp::DATE <= p_start_date + (p_end_date - p_start_date) / 2 
                                    THEN percentage_difference END))
            END AS accuracy_trend,
            STDDEV(percentage_difference) AS volatility_score,
            COUNT(*) AS data_points
        FROM accuracy.metrics
        WHERE business_unit = v_business_unit
          AND metric_type = v_metric_type
          AND measurement_timestamp::DATE BETWEEN p_start_date AND p_end_date
        GROUP BY v_business_unit, v_metric_type
        ON CONFLICT (period_start, period_end, business_unit, metric_type) 
        DO UPDATE SET
            avg_accuracy = EXCLUDED.avg_accuracy,
            accuracy_trend = EXCLUDED.accuracy_trend,
            volatility_score = EXCLUDED.volatility_score,
            data_points = EXCLUDED.data_points;
        
        v_trend_count := v_trend_count + 1;
    END LOOP;
    
    RETURN v_trend_count;
END;
$$ LANGUAGE plpgsql;

-- Identify failure patterns
CREATE OR REPLACE FUNCTION accuracy.identify_failure_patterns() RETURNS INTEGER AS $$
DECLARE
    v_pattern RECORD;
    v_failure_count INTEGER := 0;
BEGIN
    -- Check for consistent high deviations
    FOR v_pattern IN
        SELECT 
            metric_type,
            business_unit,
            COUNT(*) as error_count,
            AVG(percentage_difference) as avg_deviation
        FROM accuracy.metrics
        WHERE percentage_difference > 10  -- 10% threshold
          AND measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
        GROUP BY metric_type, business_unit
        HAVING COUNT(*) > 5  -- At least 5 occurrences
    LOOP
        INSERT INTO accuracy.failure_patterns (
            pattern_type, failure_category, business_unit,
            affected_metrics, root_cause, impact_severity, occurrence_count
        ) VALUES (
            'high_deviation', 'ACCURACY', v_pattern.business_unit,
            ARRAY[v_pattern.metric_type],
            'Consistent deviation of ' || ROUND(v_pattern.avg_deviation, 2) || '% detected',
            CASE 
                WHEN v_pattern.avg_deviation > 25 THEN 'CRITICAL'
                WHEN v_pattern.avg_deviation > 15 THEN 'HIGH'
                ELSE 'MEDIUM'
            END,
            v_pattern.error_count
        ) ON CONFLICT DO NOTHING;
        
        v_failure_count := v_failure_count + 1;
    END LOOP;
    
    -- Check for data quality issues
    FOR v_pattern IN
        SELECT 
            issue_type,
            COUNT(*) as issue_count,
            MAX(severity) as max_severity
        FROM accuracy.data_quality_issues
        WHERE detected_timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
        GROUP BY issue_type
        HAVING COUNT(*) > 10
    LOOP
        INSERT INTO accuracy.failure_patterns (
            pattern_type, failure_category,
            affected_metrics, root_cause, impact_severity, occurrence_count
        ) VALUES (
            'data_quality', 'DATA_QUALITY',
            ARRAY[v_pattern.issue_type],
            'Recurring data quality issue: ' || v_pattern.issue_type,
            v_pattern.max_severity,
            v_pattern.issue_count
        ) ON CONFLICT DO NOTHING;
        
        v_failure_count := v_failure_count + 1;
    END LOOP;
    
    RETURN v_failure_count;
END;
$$ LANGUAGE plpgsql;

-- Log data quality issues
CREATE OR REPLACE FUNCTION accuracy.log_data_quality_issue(
    p_source_file VARCHAR,
    p_issue_type VARCHAR,
    p_column_name VARCHAR,
    p_row_count INTEGER,
    p_severity VARCHAR,
    p_impact TEXT,
    p_auto_correct BOOLEAN DEFAULT FALSE,
    p_correction TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_issue_id INTEGER;
BEGIN
    INSERT INTO accuracy.data_quality_issues (
        source_file, issue_type, column_name, row_count,
        severity, impact_description, auto_corrected, correction_applied
    ) VALUES (
        p_source_file, p_issue_type, p_column_name, p_row_count,
        p_severity, p_impact, p_auto_correct, p_correction
    ) RETURNING issue_id INTO v_issue_id;
    
    -- Update data quality scores for affected metrics
    UPDATE accuracy.metrics
    SET data_quality_score = data_quality_score * 0.9  -- Reduce by 10%
    WHERE metadata->>'source_file' = p_source_file
      AND measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    RETURN v_issue_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Reporting Views
-- =============================================

-- Current accuracy dashboard
CREATE OR REPLACE VIEW accuracy.current_accuracy_dashboard AS
SELECT 
    m.business_unit,
    m.metric_type,
    COUNT(*) as measurement_count,
    AVG(m.percentage_difference) as avg_deviation,
    MIN(m.percentage_difference) as min_deviation,
    MAX(m.percentage_difference) as max_deviation,
    AVG(m.confidence_score) as avg_confidence,
    SUM(CASE WHEN m.is_outlier THEN 1 ELSE 0 END) as outlier_count,
    MAX(m.measurement_timestamp) as last_measurement
FROM accuracy.metrics m
WHERE m.measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY m.business_unit, m.metric_type
ORDER BY avg_deviation DESC;

-- Multi-skill accuracy summary
CREATE OR REPLACE VIEW accuracy.multi_skill_summary AS
SELECT 
    ms.business_unit,
    COUNT(DISTINCT ms.skill_combination) as unique_combinations,
    AVG(ms.routing_accuracy) as avg_routing_accuracy,
    AVG(ms.queue_distribution_accuracy) as avg_queue_accuracy,
    AVG(ms.performance_impact_score) as avg_performance_impact,
    MIN(ms.routing_accuracy) as worst_routing_accuracy,
    MAX(ms.measurement_timestamp) as last_measurement
FROM accuracy.multi_skill_accuracy ms
WHERE ms.measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY ms.business_unit;

-- Active failure patterns
CREATE OR REPLACE VIEW accuracy.active_failures AS
SELECT 
    fp.failure_id,
    fp.pattern_type,
    fp.failure_category,
    fp.business_unit,
    fp.affected_metrics,
    fp.impact_severity,
    fp.occurrence_count,
    fp.detected_timestamp,
    fp.last_occurrence
FROM accuracy.failure_patterns fp
WHERE fp.resolution_status = 'OPEN'
ORDER BY 
    CASE fp.impact_severity 
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
    END,
    fp.occurrence_count DESC;

-- Performance comparison
CREATE OR REPLACE VIEW accuracy.performance_comparison AS
SELECT 
    pm.operation_type,
    pm.interval_type,
    AVG(pm.argus_processing_time_ms) as avg_argus_time,
    AVG(pm.wfm_processing_time_ms) as avg_wfm_time,
    AVG(pm.wfm_processing_time_ms::NUMERIC / NULLIF(pm.argus_processing_time_ms, 0)) as time_ratio,
    AVG(pm.success_rate) as avg_success_rate,
    COUNT(*) as operation_count
FROM accuracy.performance_metrics pm
WHERE pm.measurement_timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY pm.operation_type, pm.interval_type
ORDER BY time_ratio DESC;

-- =============================================
-- Scheduled Maintenance Procedures
-- =============================================

-- Clean up old data (run daily)
CREATE OR REPLACE FUNCTION accuracy.cleanup_old_data(
    p_retention_days INTEGER DEFAULT 90
) RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_cutoff_date := CURRENT_TIMESTAMP - (p_retention_days || ' days')::INTERVAL;
    
    -- Delete old metrics
    DELETE FROM accuracy.metrics
    WHERE measurement_timestamp < v_cutoff_date;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Delete old performance metrics
    DELETE FROM accuracy.performance_metrics
    WHERE measurement_timestamp < v_cutoff_date;
    
    -- Delete old confidence scores
    DELETE FROM accuracy.confidence_scores
    WHERE calculation_timestamp < v_cutoff_date;
    
    -- Delete resolved failure patterns older than 30 days
    DELETE FROM accuracy.failure_patterns
    WHERE resolution_status != 'OPEN'
      AND last_occurrence < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Generate daily accuracy report
CREATE OR REPLACE FUNCTION accuracy.generate_daily_report(
    p_date DATE DEFAULT CURRENT_DATE - 1
) RETURNS TABLE (
    report_section VARCHAR,
    metric_name VARCHAR,
    metric_value NUMERIC,
    trend VARCHAR,
    alert_level VARCHAR
) AS $$
BEGIN
    -- Overall accuracy metrics
    RETURN QUERY
    SELECT 
        'Overall Accuracy'::VARCHAR,
        'Average Deviation'::VARCHAR,
        AVG(percentage_difference)::NUMERIC,
        CASE 
            WHEN AVG(percentage_difference) < 5 THEN 'GOOD'
            WHEN AVG(percentage_difference) < 10 THEN 'ACCEPTABLE'
            ELSE 'POOR'
        END::VARCHAR,
        CASE 
            WHEN AVG(percentage_difference) > 15 THEN 'HIGH'
            WHEN AVG(percentage_difference) > 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END::VARCHAR
    FROM accuracy.metrics
    WHERE measurement_timestamp::DATE = p_date;
    
    -- Business unit breakdown
    RETURN QUERY
    SELECT 
        'Business Unit: ' || business_unit::VARCHAR,
        metric_type::VARCHAR,
        AVG(percentage_difference)::NUMERIC,
        'N/A'::VARCHAR,
        CASE 
            WHEN AVG(percentage_difference) > 20 THEN 'HIGH'
            WHEN AVG(percentage_difference) > 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END::VARCHAR
    FROM accuracy.metrics
    WHERE measurement_timestamp::DATE = p_date
    GROUP BY business_unit, metric_type
    ORDER BY AVG(percentage_difference) DESC
    LIMIT 10;
    
    -- Multi-skill accuracy
    RETURN QUERY
    SELECT 
        'Multi-Skill Accuracy'::VARCHAR,
        business_unit::VARCHAR,
        AVG(routing_accuracy)::NUMERIC,
        'N/A'::VARCHAR,
        CASE 
            WHEN AVG(routing_accuracy) < 80 THEN 'HIGH'
            WHEN AVG(routing_accuracy) < 90 THEN 'MEDIUM'
            ELSE 'LOW'
        END::VARCHAR
    FROM accuracy.multi_skill_accuracy
    WHERE measurement_timestamp::DATE = p_date
    GROUP BY business_unit;
    
    -- Performance metrics
    RETURN QUERY
    SELECT 
        'Performance'::VARCHAR,
        operation_type::VARCHAR,
        AVG(wfm_processing_time_ms)::NUMERIC,
        CASE 
            WHEN AVG(wfm_processing_time_ms) < AVG(argus_processing_time_ms) THEN 'FASTER'
            ELSE 'SLOWER'
        END::VARCHAR,
        CASE 
            WHEN AVG(success_rate) < 95 THEN 'HIGH'
            WHEN AVG(success_rate) < 99 THEN 'MEDIUM'
            ELSE 'LOW'
        END::VARCHAR
    FROM accuracy.performance_metrics
    WHERE measurement_timestamp::DATE = p_date
    GROUP BY operation_type;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Grants and Permissions
-- =============================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA accuracy TO wfm_app;
GRANT USAGE ON SCHEMA accuracy TO wfm_readonly;

-- Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA accuracy TO wfm_app;
GRANT SELECT ON ALL TABLES IN SCHEMA accuracy TO wfm_readonly;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA accuracy TO wfm_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA accuracy TO wfm_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA accuracy TO wfm_readonly;

-- =============================================
-- Initial Setup and Testing
-- =============================================

-- Create initial test data
DO $$
BEGIN
    -- Test basic metric tracking
    PERFORM accuracy.track_metric_accuracy(
        'Бизнес', 'TEST001', '30min', 'agent_count',
        100.0, 95.0, '{"test": true}'::jsonb
    );
    
    -- Test multi-skill tracking
    PERFORM accuracy.track_multi_skill_accuracy(
        'ВТМ', 'SKILL_A,SKILL_B,SKILL_C', 50,
        '{"covered_skills": 3, "total_skills": 3, "queue_distribution": {"Q1": 40, "Q2": 60}}'::jsonb,
        '{"covered_skills": 3, "total_skills": 3, "queue_distribution": {"Q1": 45, "Q2": 55}}'::jsonb
    );
    
    -- Test performance tracking
    PERFORM accuracy.track_performance_timing(
        'data_import', 1000, '15min', 500, 450, 128, 45.5, 0
    );
    
    RAISE NOTICE 'Accuracy tracking infrastructure created and tested successfully';
END $$;