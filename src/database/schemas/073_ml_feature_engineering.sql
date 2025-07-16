-- Schema 073: ML/AI Feature Engineering Tables
-- Pre-computed features for machine learning models
-- Target: Real-time ML predictions with feature storage

-- 1. Feature Store Master Registry
CREATE TABLE ml_feature_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_name VARCHAR(255) NOT NULL UNIQUE,
    feature_type VARCHAR(50), -- numeric, categorical, text, embedding
    source_table VARCHAR(255),
    source_columns TEXT[],
    computation_sql TEXT,
    feature_description TEXT,
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Agent Performance Features
CREATE TABLE ml_agent_features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    feature_date DATE NOT NULL,
    -- Performance features
    avg_handle_time_30d DECIMAL(10,2),
    avg_handle_time_7d DECIMAL(10,2),
    total_calls_30d INTEGER,
    occupancy_rate_30d DECIMAL(5,2),
    schedule_adherence_30d DECIMAL(5,2),
    -- Skill features
    primary_skill_proficiency DECIMAL(5,2),
    skill_diversity_score DECIMAL(5,2),
    cross_training_level INTEGER,
    -- Pattern features
    peak_hour_performance DECIMAL(5,2),
    consistency_score DECIMAL(5,2),
    improvement_trend DECIMAL(5,2),
    -- Behavioral features
    break_pattern_regularity DECIMAL(5,2),
    overtime_frequency DECIMAL(5,2),
    absence_probability DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_id, feature_date)
);

-- 3. Queue Pattern Features
CREATE TABLE ml_queue_features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_id UUID NOT NULL,
    interval_start TIMESTAMP NOT NULL,
    -- Volume features
    call_volume_ma_15min DECIMAL(10,2),
    call_volume_ma_1h DECIMAL(10,2),
    volume_volatility DECIMAL(10,2),
    -- Temporal features
    hour_of_day INTEGER,
    day_of_week INTEGER,
    is_holiday BOOLEAN,
    days_to_holiday INTEGER,
    -- Seasonality features
    weekly_pattern_strength DECIMAL(5,2),
    monthly_pattern_strength DECIMAL(5,2),
    seasonal_factor DECIMAL(5,2),
    -- External features
    weather_impact_score DECIMAL(5,2),
    marketing_campaign_active BOOLEAN,
    competitor_activity_level INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(queue_id, interval_start)
);

-- 4. Time-Series Feature Extraction
CREATE TABLE ml_timeseries_features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50), -- agent, queue, site
    entity_id UUID NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    -- Statistical features
    mean_value DECIMAL(10,2),
    std_deviation DECIMAL(10,2),
    min_value DECIMAL(10,2),
    max_value DECIMAL(10,2),
    percentile_25 DECIMAL(10,2),
    percentile_50 DECIMAL(10,2),
    percentile_75 DECIMAL(10,2),
    -- Trend features
    linear_trend_slope DECIMAL(10,4),
    exponential_trend_factor DECIMAL(10,4),
    change_point_detected BOOLEAN,
    -- Frequency domain features
    dominant_frequency DECIMAL(10,4),
    spectral_entropy DECIMAL(10,4),
    periodicity_strength DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Categorical Encoding Tables
CREATE TABLE ml_categorical_encodings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_type VARCHAR(100), -- skill, department, location
    category_value VARCHAR(255),
    encoding_method VARCHAR(50), -- onehot, label, target, embedding
    encoded_value JSONB,
    frequency_rank INTEGER,
    target_correlation DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category_type, category_value, encoding_method)
);

-- 6. Feature Importance Tracking
CREATE TABLE ml_feature_importance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL,
    feature_name VARCHAR(255),
    importance_score DECIMAL(10,6),
    importance_method VARCHAR(50), -- shap, permutation, builtin
    evaluation_date TIMESTAMP,
    dataset_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Embedding Storage
CREATE TABLE ml_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50),
    entity_id UUID NOT NULL,
    embedding_type VARCHAR(50), -- skill, behavior, text
    embedding_vector REAL[],
    dimension INTEGER,
    model_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE(entity_type, entity_id, embedding_type)
);

-- 8. Feature Engineering Pipeline Status
CREATE TABLE ml_feature_pipeline_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_name VARCHAR(255),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    features_computed INTEGER,
    rows_processed BIGINT,
    status VARCHAR(50),
    error_message TEXT,
    execution_time_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample feature registry
INSERT INTO ml_feature_registry (feature_name, feature_type, source_table, computation_sql, feature_description)
VALUES 
    ('agent_efficiency_score', 'numeric', 'agent_activity', 
     'AVG(handle_time) / NULLIF(SUM(total_time), 0)', 
     'Agent efficiency based on handle time vs total time'),
    ('queue_complexity_index', 'numeric', 'queue_statistics', 
     'LOG(avg_handle_time * skill_requirements)', 
     'Queue complexity based on handle time and skill needs'),
    ('seasonal_volume_factor', 'numeric', 'forecast_history', 
     'actual_volume / baseline_volume', 
     'Seasonal adjustment factor for volume predictions');

-- Insert sample features
INSERT INTO ml_agent_features (agent_id, feature_date, avg_handle_time_30d, occupancy_rate_30d, schedule_adherence_30d, skill_diversity_score)
VALUES 
    ('a1234567-89ab-cdef-0123-456789abcdef', '2024-01-15', 180.5, 85.2, 92.5, 4.2),
    ('b2345678-9abc-def0-1234-56789abcdef0', '2024-01-15', 165.3, 88.7, 95.1, 3.8);

INSERT INTO ml_categorical_encodings (category_type, category_value, encoding_method, encoded_value, frequency_rank)
VALUES 
    ('skill', 'Продажи', 'onehot', '[1,0,0,0,0]', 1),
    ('skill', 'Техподдержка', 'onehot', '[0,1,0,0,0]', 2),
    ('department', 'Москва-Центр', 'label', '1', 1);

-- Verify ML feature tables
SELECT COUNT(*) as ml_tables_count 
FROM information_schema.tables 
WHERE table_name LIKE 'ml_%';