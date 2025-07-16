-- =====================================================================================
-- Schema 121: Machine Learning and AI Analytics Platform
-- =====================================================================================
-- Description: Enterprise ML/AI platform for WFM with model lifecycle management,
--             training data management, inference endpoints, and performance monitoring
-- Business Value: Automated forecasting, intelligent scheduling, predictive analytics
-- Dependencies: Schema 001 (base), Schema 073-074 (ML foundations)
-- Complexity: ADVANCED - Full enterprise ML platform with governance
-- =====================================================================================

-- Model Registry and Lifecycle Management
-- =====================================================================================

-- Central model registry for all ML models in the system
CREATE TABLE ml_models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- 'forecasting', 'optimization', 'classification', 'anomaly_detection'
    model_version VARCHAR(20) NOT NULL,
    model_framework VARCHAR(30) NOT NULL, -- 'tensorflow', 'pytorch', 'scikit-learn', 'xgboost'
    
    -- Model metadata
    description TEXT,
    algorithm_type VARCHAR(50), -- 'random_forest', 'neural_network', 'svm', 'lstm', 'transformer'
    hyperparameters JSONB,
    feature_schema JSONB, -- Expected input features and types
    output_schema JSONB, -- Expected output format
    
    -- Model lifecycle
    status VARCHAR(20) DEFAULT 'development', -- 'development', 'training', 'validation', 'production', 'deprecated'
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_trained_at TIMESTAMP WITH TIME ZONE,
    deployment_date TIMESTAMP WITH TIME ZONE,
    retirement_date TIMESTAMP WITH TIME ZONE,
    
    -- Performance metrics
    training_accuracy DECIMAL(5,4),
    validation_accuracy DECIMAL(5,4),
    production_accuracy DECIMAL(5,4),
    inference_latency_ms INTEGER,
    training_duration_hours DECIMAL(8,2),
    
    -- Model artifacts
    model_path TEXT, -- Path to serialized model file
    model_size_mb DECIMAL(10,2),
    training_data_hash VARCHAR(64), -- For reproducibility
    
    -- Business impact
    business_domain VARCHAR(50), -- 'workforce_planning', 'schedule_optimization', 'demand_forecasting'
    target_metric VARCHAR(50), -- 'mape', 'accuracy', 'f1_score', 'auc_roc'
    target_value DECIMAL(8,4),
    
    -- Governance
    approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_by VARCHAR(100),
    approved_at TIMESTAMP WITH TIME ZONE,
    compliance_tags TEXT[],
    
    UNIQUE(model_name, model_version)
);

-- Model training jobs and their execution history
CREATE TABLE ml_training_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ml_models(model_id),
    job_name VARCHAR(100) NOT NULL,
    
    -- Job configuration
    training_config JSONB NOT NULL, -- Complete training configuration
    dataset_id UUID, -- Reference to training dataset
    compute_resources JSONB, -- CPU, memory, GPU requirements
    
    -- Job lifecycle
    status VARCHAR(20) DEFAULT 'queued', -- 'queued', 'running', 'completed', 'failed', 'cancelled'
    submitted_by VARCHAR(100) NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Execution details
    worker_node VARCHAR(100),
    execution_log TEXT,
    error_message TEXT,
    resource_usage JSONB, -- Actual resource consumption
    
    -- Training metrics
    training_metrics JSONB, -- Loss, accuracy per epoch
    validation_metrics JSONB, -- Validation scores
    final_metrics JSONB, -- Final model performance
    
    -- Artifacts
    model_checkpoint_path TEXT,
    tensorboard_log_path TEXT,
    experiment_tracking_url TEXT,
    
    -- Cost and efficiency
    compute_cost_rubles DECIMAL(10,2),
    carbon_footprint_kg DECIMAL(8,3),
    efficiency_score DECIMAL(5,4)
);

-- Model inference endpoints and their configurations
CREATE TABLE ml_inference_endpoints (
    endpoint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ml_models(model_id),
    endpoint_name VARCHAR(100) NOT NULL,
    endpoint_url TEXT NOT NULL,
    
    -- Deployment configuration
    deployment_config JSONB,
    scaling_config JSONB, -- Auto-scaling parameters
    resource_limits JSONB, -- Memory, CPU limits
    
    -- Endpoint lifecycle
    status VARCHAR(20) DEFAULT 'deploying', -- 'deploying', 'active', 'inactive', 'error'
    deployed_at TIMESTAMP WITH TIME ZONE,
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) DEFAULT 'unknown', -- 'healthy', 'degraded', 'unhealthy'
    
    -- Performance SLA
    max_latency_ms INTEGER DEFAULT 1000,
    max_throughput_rps INTEGER DEFAULT 100,
    availability_target DECIMAL(5,4) DEFAULT 0.999, -- 99.9% uptime
    
    -- Security
    auth_required BOOLEAN DEFAULT true,
    api_key_hash VARCHAR(128),
    rate_limit_rps INTEGER DEFAULT 10,
    allowed_origins TEXT[],
    
    -- Monitoring
    request_count BIGINT DEFAULT 0,
    error_count BIGINT DEFAULT 0,
    last_request_at TIMESTAMP WITH TIME ZONE,
    average_latency_ms DECIMAL(8,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI/ML Feature Store
-- =====================================================================================

-- Central feature store for ML features
CREATE TABLE ml_features (
    feature_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_name VARCHAR(100) NOT NULL,
    feature_group VARCHAR(50) NOT NULL, -- 'temporal', 'agent_profile', 'workload', 'external'
    
    -- Feature definition
    description TEXT,
    data_type VARCHAR(30) NOT NULL, -- 'numeric', 'categorical', 'text', 'datetime', 'boolean'
    calculation_logic TEXT, -- SQL or formula for feature calculation
    source_tables TEXT[], -- Tables used to calculate this feature
    
    -- Feature quality
    completeness_percentage DECIMAL(5,2), -- % of non-null values
    uniqueness_percentage DECIMAL(5,2), -- % of unique values
    validity_rules JSONB, -- Data validation rules
    
    -- Feature lifecycle
    status VARCHAR(20) DEFAULT 'development', -- 'development', 'production', 'deprecated'
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_computed_at TIMESTAMP WITH TIME ZONE,
    computation_frequency VARCHAR(20), -- 'real_time', 'hourly', 'daily', 'weekly'
    
    -- Business context
    business_meaning TEXT,
    importance_score DECIMAL(3,2), -- 0.0 to 1.0
    correlation_with_target DECIMAL(4,3), -- -1.0 to 1.0
    
    -- Technical metadata
    storage_format VARCHAR(20) DEFAULT 'numeric', -- 'numeric', 'categorical', 'embedding'
    dimensionality INTEGER DEFAULT 1,
    encoding_method VARCHAR(30), -- 'one_hot', 'label', 'target', 'embedding'
    
    UNIQUE(feature_name)
);

-- Feature values storage (time-series)
CREATE TABLE ml_feature_values (
    value_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_id UUID REFERENCES ml_features(feature_id),
    entity_id VARCHAR(100) NOT NULL, -- agent_id, queue_id, etc.
    entity_type VARCHAR(50) NOT NULL, -- 'agent', 'queue', 'site', 'global'
    
    -- Time context
    timestamp_value TIMESTAMP WITH TIME ZONE NOT NULL,
    date_partition DATE GENERATED ALWAYS AS (DATE(timestamp_value)) STORED,
    
    -- Feature values
    numeric_value DECIMAL(15,6),
    categorical_value VARCHAR(200),
    text_value TEXT,
    boolean_value BOOLEAN,
    json_value JSONB,
    
    -- Metadata
    confidence_score DECIMAL(3,2), -- Quality confidence 0.0-1.0
    data_source VARCHAR(50), -- Source system that provided this value
    computation_method VARCHAR(50), -- How this value was computed
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(feature_id, entity_id, entity_type, timestamp_value)
) PARTITION BY RANGE (date_partition);

-- Create monthly partitions for feature values
CREATE TABLE ml_feature_values_2024_01 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE ml_feature_values_2024_02 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE ml_feature_values_2024_03 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE ml_feature_values_2024_04 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE ml_feature_values_2024_05 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE ml_feature_values_2024_06 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE ml_feature_values_2024_07 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE ml_feature_values_2024_08 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE ml_feature_values_2024_09 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE ml_feature_values_2024_10 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE ml_feature_values_2024_11 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE ml_feature_values_2024_12 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE ml_feature_values_2025_01 PARTITION OF ml_feature_values
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- AI Model Predictions and Results
-- =====================================================================================

-- Store predictions from ML models
CREATE TABLE ml_predictions (
    prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ml_models(model_id),
    endpoint_id UUID REFERENCES ml_inference_endpoints(endpoint_id),
    
    -- Prediction context
    entity_id VARCHAR(100) NOT NULL, -- What we're predicting for
    entity_type VARCHAR(50) NOT NULL, -- 'agent', 'queue', 'schedule', 'demand'
    prediction_type VARCHAR(50) NOT NULL, -- 'forecast', 'classification', 'optimization', 'anomaly'
    
    -- Time context
    prediction_made_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    prediction_for_time TIMESTAMP WITH TIME ZONE, -- When prediction applies
    horizon_minutes INTEGER, -- How far into future (for forecasts)
    
    -- Input features
    input_features JSONB NOT NULL, -- Feature values used for prediction
    feature_hash VARCHAR(64), -- Hash of input features for deduplication
    
    -- Prediction results
    predicted_value DECIMAL(15,6),
    predicted_category VARCHAR(100),
    prediction_probability DECIMAL(5,4), -- Confidence/probability
    prediction_bounds JSONB, -- Confidence intervals: {"lower": x, "upper": y}
    
    -- Multiple predictions (for multi-output models)
    all_predictions JSONB, -- Array of all prediction results
    prediction_metadata JSONB, -- Model-specific metadata
    
    -- Quality metrics
    certainty_score DECIMAL(3,2), -- How certain the model is (0.0-1.0)
    feature_importance JSONB, -- Importance of each input feature
    
    -- Validation (when actual outcome is known)
    actual_value DECIMAL(15,6),
    actual_category VARCHAR(100),
    prediction_error DECIMAL(15,6),
    absolute_error DECIMAL(15,6),
    error_percentage DECIMAL(8,4),
    
    -- Business impact
    business_value_rubles DECIMAL(12,2), -- Estimated value of this prediction
    decision_made BOOLEAN DEFAULT false, -- Was this prediction acted upon?
    action_taken TEXT, -- What action was taken based on prediction
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (prediction_made_at);

-- Create monthly partitions for predictions
CREATE TABLE ml_predictions_2024_01 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE ml_predictions_2024_02 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE ml_predictions_2024_03 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE ml_predictions_2024_04 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE ml_predictions_2024_05 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE ml_predictions_2024_06 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE ml_predictions_2024_07 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE ml_predictions_2024_08 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE ml_predictions_2024_09 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE ml_predictions_2024_10 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE ml_predictions_2024_11 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE ml_predictions_2024_12 PARTITION OF ml_predictions
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE ml_predictions_2025_01 PARTITION OF ml_predictions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- AI Recommendation Engine
-- =====================================================================================

-- AI-powered recommendations for WFM decisions
CREATE TABLE ai_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ml_models(model_id),
    
    -- Recommendation context
    recommendation_type VARCHAR(50) NOT NULL, -- 'schedule_adjustment', 'staffing_change', 'training_need'
    target_entity_id VARCHAR(100) NOT NULL,
    target_entity_type VARCHAR(50) NOT NULL, -- 'agent', 'queue', 'department', 'site'
    
    -- Recommendation details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    recommended_action JSONB, -- Structured action to take
    rationale TEXT, -- Why this recommendation was made
    
    -- Priority and impact
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    confidence_score DECIMAL(3,2), -- How confident AI is (0.0-1.0)
    expected_impact JSONB, -- {"metric": "service_level", "improvement": 0.05}
    estimated_value_rubles DECIMAL(12,2),
    
    -- Implementation
    implementation_effort VARCHAR(20), -- 'low', 'medium', 'high'
    implementation_timeline VARCHAR(50), -- 'immediate', 'within_day', 'within_week'
    required_approvals TEXT[], -- Who needs to approve this
    
    -- Time context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE, -- When recommendation expires
    applicable_from TIMESTAMP WITH TIME ZONE, -- When it can be implemented
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'implemented'
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    implementation_notes TEXT,
    
    -- Feedback loop
    actual_impact JSONB, -- Measured impact after implementation
    user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
    user_feedback TEXT,
    
    -- Related data
    supporting_data JSONB, -- Data that supports this recommendation
    alternative_actions JSONB, -- Other possible actions considered
    risk_factors TEXT[] -- Potential risks of implementing
);

-- Performance Monitoring and Analytics
-- =====================================================================================

-- ML model performance monitoring
CREATE TABLE ml_model_performance (
    performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ml_models(model_id),
    
    -- Time period
    measurement_date DATE NOT NULL,
    measurement_hour INTEGER CHECK (measurement_hour BETWEEN 0 AND 23),
    
    -- Performance metrics
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    auc_roc DECIMAL(5,4),
    
    -- Regression metrics
    mae DECIMAL(10,4), -- Mean Absolute Error
    mse DECIMAL(10,4), -- Mean Squared Error
    rmse DECIMAL(10,4), -- Root Mean Squared Error
    mape DECIMAL(8,4), -- Mean Absolute Percentage Error
    r_squared DECIMAL(5,4),
    
    -- Prediction quality
    prediction_count INTEGER,
    successful_predictions INTEGER,
    failed_predictions INTEGER,
    average_confidence DECIMAL(3,2),
    
    -- Business metrics
    business_accuracy_percentage DECIMAL(5,2), -- Accuracy from business perspective
    false_positive_cost_rubles DECIMAL(12,2),
    false_negative_cost_rubles DECIMAL(12,2),
    total_business_value_rubles DECIMAL(12,2),
    
    -- Drift detection
    data_drift_score DECIMAL(5,4), -- How much input data has changed
    concept_drift_score DECIMAL(5,4), -- How much relationships have changed
    drift_alert BOOLEAN DEFAULT false,
    
    -- System performance
    average_inference_time_ms DECIMAL(8,2),
    max_inference_time_ms INTEGER,
    throughput_requests_per_second DECIMAL(8,2),
    error_rate_percentage DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(model_id, measurement_date, measurement_hour)
);

-- A/B testing framework for ML models
CREATE TABLE ml_ab_tests (
    test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_name VARCHAR(100) NOT NULL,
    
    -- Test configuration
    control_model_id UUID REFERENCES ml_models(model_id),
    treatment_model_id UUID REFERENCES ml_models(model_id),
    traffic_split DECIMAL(3,2) DEFAULT 0.5, -- % traffic to treatment (0.0-1.0)
    
    -- Test scope
    target_entities JSONB, -- Which entities to include in test
    exclusion_criteria JSONB, -- Entities to exclude
    
    -- Test timeline
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'planning', -- 'planning', 'running', 'completed', 'stopped'
    
    -- Success criteria
    primary_metric VARCHAR(50) NOT NULL, -- What we're optimizing for
    success_threshold DECIMAL(8,4), -- Minimum improvement needed
    statistical_significance DECIMAL(3,2) DEFAULT 0.95, -- Required confidence level
    
    -- Results
    control_sample_size INTEGER DEFAULT 0,
    treatment_sample_size INTEGER DEFAULT 0,
    control_metric_value DECIMAL(10,4),
    treatment_metric_value DECIMAL(10,4),
    improvement_percentage DECIMAL(8,4),
    p_value DECIMAL(10,8),
    confidence_interval JSONB, -- {"lower": x, "upper": y}
    
    -- Decision
    test_conclusion VARCHAR(20), -- 'treatment_wins', 'control_wins', 'no_difference', 'inconclusive'
    decision_notes TEXT,
    decided_by VARCHAR(100),
    decided_at TIMESTAMP WITH TIME ZONE,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for Performance
-- =====================================================================================

-- ML Models indexes
CREATE INDEX idx_ml_models_status ON ml_models(status);
CREATE INDEX idx_ml_models_type ON ml_models(model_type);
CREATE INDEX idx_ml_models_business_domain ON ml_models(business_domain);
CREATE INDEX idx_ml_models_created_at ON ml_models(created_at);

-- Training Jobs indexes
CREATE INDEX idx_ml_training_jobs_model_id ON ml_training_jobs(model_id);
CREATE INDEX idx_ml_training_jobs_status ON ml_training_jobs(status);
CREATE INDEX idx_ml_training_jobs_submitted_at ON ml_training_jobs(submitted_at);

-- Inference Endpoints indexes
CREATE INDEX idx_ml_inference_endpoints_model_id ON ml_inference_endpoints(model_id);
CREATE INDEX idx_ml_inference_endpoints_status ON ml_inference_endpoints(status);
CREATE INDEX idx_ml_inference_endpoints_health_status ON ml_inference_endpoints(health_status);

-- Features indexes
CREATE INDEX idx_ml_features_group ON ml_features(feature_group);
CREATE INDEX idx_ml_features_status ON ml_features(status);
CREATE INDEX idx_ml_features_importance ON ml_features(importance_score);

-- Feature Values indexes (on partitioned table)
CREATE INDEX idx_ml_feature_values_feature_id ON ml_feature_values(feature_id);
CREATE INDEX idx_ml_feature_values_entity ON ml_feature_values(entity_id, entity_type);
CREATE INDEX idx_ml_feature_values_timestamp ON ml_feature_values(timestamp_value);

-- Predictions indexes (on partitioned table)
CREATE INDEX idx_ml_predictions_model_id ON ml_predictions(model_id);
CREATE INDEX idx_ml_predictions_entity ON ml_predictions(entity_id, entity_type);
CREATE INDEX idx_ml_predictions_type ON ml_predictions(prediction_type);
CREATE INDEX idx_ml_predictions_for_time ON ml_predictions(prediction_for_time);

-- Recommendations indexes
CREATE INDEX idx_ai_recommendations_type ON ai_recommendations(recommendation_type);
CREATE INDEX idx_ai_recommendations_target ON ai_recommendations(target_entity_id, target_entity_type);
CREATE INDEX idx_ai_recommendations_status ON ai_recommendations(status);
CREATE INDEX idx_ai_recommendations_priority ON ai_recommendations(priority);
CREATE INDEX idx_ai_recommendations_created_at ON ai_recommendations(created_at);

-- Performance indexes
CREATE INDEX idx_ml_model_performance_model_date ON ml_model_performance(model_id, measurement_date);
CREATE INDEX idx_ml_model_performance_accuracy ON ml_model_performance(accuracy);

-- A/B Testing indexes
CREATE INDEX idx_ml_ab_tests_status ON ml_ab_tests(status);
CREATE INDEX idx_ml_ab_tests_models ON ml_ab_tests(control_model_id, treatment_model_id);
CREATE INDEX idx_ml_ab_tests_dates ON ml_ab_tests(start_date, end_date);

-- Functions for ML Operations
-- =====================================================================================

-- Function to register a new ML model
CREATE OR REPLACE FUNCTION register_ml_model(
    p_model_name VARCHAR(100),
    p_model_type VARCHAR(50),
    p_model_version VARCHAR(20),
    p_framework VARCHAR(30),
    p_description TEXT,
    p_created_by VARCHAR(100),
    p_hyperparameters JSONB DEFAULT NULL,
    p_feature_schema JSONB DEFAULT NULL,
    p_output_schema JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_model_id UUID;
BEGIN
    INSERT INTO ml_models (
        model_name, model_type, model_version, model_framework,
        description, created_by, hyperparameters, feature_schema, output_schema
    ) VALUES (
        p_model_name, p_model_type, p_model_version, p_framework,
        p_description, p_created_by, p_hyperparameters, p_feature_schema, p_output_schema
    ) RETURNING model_id INTO v_model_id;
    
    RETURN v_model_id;
END;
$$ LANGUAGE plpgsql;

-- Function to deploy model to inference endpoint
CREATE OR REPLACE FUNCTION deploy_model_endpoint(
    p_model_id UUID,
    p_endpoint_name VARCHAR(100),
    p_endpoint_url TEXT,
    p_deployment_config JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_endpoint_id UUID;
BEGIN
    INSERT INTO ml_inference_endpoints (
        model_id, endpoint_name, endpoint_url, deployment_config, status
    ) VALUES (
        p_model_id, p_endpoint_name, p_endpoint_url, p_deployment_config, 'deploying'
    ) RETURNING endpoint_id INTO v_endpoint_id;
    
    -- Update model status to production
    UPDATE ml_models 
    SET status = 'production', deployment_date = NOW()
    WHERE model_id = p_model_id;
    
    RETURN v_endpoint_id;
END;
$$ LANGUAGE plpgsql;

-- Function to record model prediction
CREATE OR REPLACE FUNCTION record_ml_prediction(
    p_model_id UUID,
    p_endpoint_id UUID,
    p_entity_id VARCHAR(100),
    p_entity_type VARCHAR(50),
    p_prediction_type VARCHAR(50),
    p_input_features JSONB,
    p_predicted_value DECIMAL(15,6) DEFAULT NULL,
    p_predicted_category VARCHAR(100) DEFAULT NULL,
    p_prediction_probability DECIMAL(5,4) DEFAULT NULL,
    p_prediction_bounds JSONB DEFAULT NULL,
    p_prediction_for_time TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_prediction_id UUID;
    v_feature_hash VARCHAR(64);
BEGIN
    -- Calculate hash of input features
    v_feature_hash := encode(digest(p_input_features::text, 'sha256'), 'hex');
    
    INSERT INTO ml_predictions (
        model_id, endpoint_id, entity_id, entity_type, prediction_type,
        input_features, feature_hash, predicted_value, predicted_category,
        prediction_probability, prediction_bounds, prediction_for_time
    ) VALUES (
        p_model_id, p_endpoint_id, p_entity_id, p_entity_type, p_prediction_type,
        p_input_features, v_feature_hash, p_predicted_value, p_predicted_category,
        p_prediction_probability, p_prediction_bounds, p_prediction_for_time
    ) RETURNING prediction_id INTO v_prediction_id;
    
    -- Update endpoint request count
    UPDATE ml_inference_endpoints 
    SET request_count = request_count + 1, last_request_at = NOW()
    WHERE endpoint_id = p_endpoint_id;
    
    RETURN v_prediction_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create AI recommendation
CREATE OR REPLACE FUNCTION create_ai_recommendation(
    p_model_id UUID,
    p_recommendation_type VARCHAR(50),
    p_target_entity_id VARCHAR(100),
    p_target_entity_type VARCHAR(50),
    p_title VARCHAR(200),
    p_description TEXT,
    p_recommended_action JSONB,
    p_confidence_score DECIMAL(3,2),
    p_expected_impact JSONB DEFAULT NULL,
    p_priority VARCHAR(20) DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    v_recommendation_id UUID;
BEGIN
    INSERT INTO ai_recommendations (
        model_id, recommendation_type, target_entity_id, target_entity_type,
        title, description, recommended_action, confidence_score,
        expected_impact, priority
    ) VALUES (
        p_model_id, p_recommendation_type, p_target_entity_id, p_target_entity_type,
        p_title, p_description, p_recommended_action, p_confidence_score,
        p_expected_impact, p_priority
    ) RETURNING recommendation_id INTO v_recommendation_id;
    
    RETURN v_recommendation_id;
END;
$$ LANGUAGE plpgsql;

-- Views for Analytics and Reporting
-- =====================================================================================

-- Model performance summary view
CREATE VIEW v_ml_model_performance_summary AS
SELECT 
    m.model_id,
    m.model_name,
    m.model_type,
    m.model_version,
    m.status,
    
    -- Latest performance metrics
    p.accuracy,
    p.mape,
    p.f1_score,
    p.business_accuracy_percentage,
    
    -- Trend indicators (last 7 days vs previous 7 days)
    LAG(p.accuracy, 7) OVER (PARTITION BY m.model_id ORDER BY p.measurement_date) as accuracy_7d_ago,
    p.accuracy - LAG(p.accuracy, 7) OVER (PARTITION BY m.model_id ORDER BY p.measurement_date) as accuracy_trend,
    
    -- Prediction volume
    SUM(p.prediction_count) OVER (PARTITION BY m.model_id ORDER BY p.measurement_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as predictions_7d,
    
    -- Business value
    SUM(p.total_business_value_rubles) OVER (PARTITION BY m.model_id ORDER BY p.measurement_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as business_value_7d,
    
    p.measurement_date,
    p.created_at
FROM ml_models m
JOIN ml_model_performance p ON m.model_id = p.model_id
WHERE p.measurement_date >= CURRENT_DATE - INTERVAL '30 days';

-- Active recommendations view
CREATE VIEW v_active_ai_recommendations AS
SELECT 
    r.recommendation_id,
    r.recommendation_type,
    r.target_entity_id,
    r.target_entity_type,
    r.title,
    r.description,
    r.priority,
    r.confidence_score,
    r.expected_impact,
    r.estimated_value_rubles,
    r.implementation_effort,
    r.implementation_timeline,
    r.created_at,
    r.valid_until,
    
    -- Model information
    m.model_name,
    m.model_type,
    
    -- Time until expiration
    EXTRACT(EPOCH FROM (r.valid_until - NOW()))/3600 as hours_until_expiration,
    
    -- Priority scoring for ranking
    CASE r.priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
    END * r.confidence_score * COALESCE(r.estimated_value_rubles/1000, 1) as priority_score
    
FROM ai_recommendations r
JOIN ml_models m ON r.model_id = m.model_id
WHERE r.status = 'pending'
    AND (r.valid_until IS NULL OR r.valid_until > NOW())
ORDER BY priority_score DESC;

-- Feature usage analytics view
CREATE VIEW v_ml_feature_usage AS
SELECT 
    f.feature_id,
    f.feature_name,
    f.feature_group,
    f.data_type,
    f.importance_score,
    f.status,
    
    -- Usage statistics (last 30 days)
    COUNT(fv.value_id) as usage_count_30d,
    COUNT(DISTINCT fv.entity_id) as unique_entities_30d,
    AVG(fv.confidence_score) as avg_confidence_30d,
    
    -- Data quality metrics
    COUNT(CASE WHEN fv.numeric_value IS NOT NULL THEN 1 END) as non_null_count,
    COUNT(CASE WHEN fv.numeric_value IS NOT NULL THEN 1 END)::float / COUNT(*) as completeness_rate,
    
    -- Value statistics (for numeric features)
    AVG(fv.numeric_value) as avg_value,
    STDDEV(fv.numeric_value) as stddev_value,
    MIN(fv.numeric_value) as min_value,
    MAX(fv.numeric_value) as max_value,
    
    -- Time metrics
    MAX(fv.timestamp_value) as last_updated,
    MIN(fv.timestamp_value) as first_recorded
    
FROM ml_features f
LEFT JOIN ml_feature_values fv ON f.feature_id = fv.feature_id
    AND fv.timestamp_value >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY f.feature_id, f.feature_name, f.feature_group, f.data_type, f.importance_score, f.status
ORDER BY usage_count_30d DESC;

-- Demo Data for ML Platform
-- =====================================================================================

-- Insert sample ML models
INSERT INTO ml_models (model_name, model_type, model_version, model_framework, description, created_by, hyperparameters, feature_schema, business_domain, target_metric, status) VALUES
('workforce_demand_predictor_v2', 'forecasting', '2.1.0', 'tensorflow', 'Deep learning model for predicting workforce demand with LSTM architecture', 'data_scientist_1', '{"layers": 3, "neurons": 128, "dropout": 0.2, "learning_rate": 0.001}', '{"temporal_features": ["hour", "day_of_week", "month"], "external_features": ["weather", "events"]}', 'workforce_planning', 'mape', 'production'),
('schedule_optimizer_ml', 'optimization', '1.3.0', 'scikit-learn', 'Genetic algorithm with ML for optimal schedule generation', 'ml_engineer_2', '{"population_size": 100, "generations": 50, "mutation_rate": 0.1}', '{"agent_features": ["skills", "preferences", "availability"], "constraints": ["labor_rules", "coverage_requirements"]}', 'schedule_optimization', 'efficiency_score', 'production'),
('agent_performance_classifier', 'classification', '1.1.0', 'xgboost', 'Classifies agent performance levels for training recommendations', 'data_scientist_3', '{"n_estimators": 200, "max_depth": 6, "learning_rate": 0.1}', '{"performance_metrics": ["aht", "quality_score", "attendance"], "behavioral_features": ["login_patterns", "break_patterns"]}', 'workforce_planning', 'f1_score', 'production'),
('anomaly_detector_realtime', 'anomaly_detection', '1.0.0', 'pytorch', 'Real-time anomaly detection for queue metrics', 'ml_engineer_1', '{"encoder_layers": [64, 32, 16], "decoder_layers": [16, 32, 64], "threshold": 0.95}', '{"queue_metrics": ["calls_waiting", "avg_wait_time", "service_level"], "temporal_context": ["time_of_day", "recent_trend"]}', 'workforce_planning', 'auc_roc', 'validation');

-- Insert sample features
INSERT INTO ml_features (feature_name, feature_group, data_type, description, importance_score, status, business_meaning) VALUES
('agent_aht_7d_avg', 'agent_profile', 'numeric', 'Average handle time for agent over last 7 days', 0.85, 'production', 'Key indicator of agent efficiency and training needs'),
('queue_calls_hourly', 'workload', 'numeric', 'Number of calls in queue per hour', 0.92, 'production', 'Primary driver of staffing requirements'),
('day_of_week', 'temporal', 'categorical', 'Day of week (1-7)', 0.78, 'production', 'Strong predictor of call volume patterns'),
('agent_skill_coverage', 'agent_profile', 'numeric', 'Percentage of required skills covered by agent', 0.73, 'production', 'Determines agent assignment flexibility'),
('historical_service_level', 'workload', 'numeric', 'Service level achieved in same period last week', 0.89, 'production', 'Baseline for performance expectations'),
('weather_impact_score', 'external', 'numeric', 'Weather impact on call volume (0-1)', 0.45, 'development', 'External factor affecting demand patterns'),
('agent_satisfaction_score', 'agent_profile', 'numeric', 'Agent satisfaction survey score (1-10)', 0.67, 'production', 'Predictor of performance and retention');

-- Insert sample training jobs
INSERT INTO ml_training_jobs (model_id, job_name, training_config, status, submitted_by, started_at, completed_at, final_metrics) VALUES
((SELECT model_id FROM ml_models WHERE model_name = 'workforce_demand_predictor_v2'), 'retrain_q1_2024', '{"dataset": "Q1_2024_full", "epochs": 50, "batch_size": 32}', 'completed', 'data_scientist_1', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '30 minutes', '{"final_mape": 0.087, "validation_loss": 0.234, "training_accuracy": 0.934}'),
((SELECT model_id FROM ml_models WHERE model_name = 'schedule_optimizer_ml'), 'optimization_update', '{"dataset": "optimization_cases_2024", "cross_validation": 5}', 'completed', 'ml_engineer_2', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '1 hour', '{"efficiency_improvement": 0.15, "constraint_violations": 0.02, "convergence_time": 45}');

-- Insert sample endpoints
INSERT INTO ml_inference_endpoints (model_id, endpoint_name, endpoint_url, status, max_latency_ms, max_throughput_rps) VALUES
((SELECT model_id FROM ml_models WHERE model_name = 'workforce_demand_predictor_v2'), 'demand_forecast_api', 'https://api.wfm.local/ml/v1/demand/forecast', 'active', 500, 100),
((SELECT model_id FROM ml_models WHERE model_name = 'schedule_optimizer_ml'), 'schedule_optimization_api', 'https://api.wfm.local/ml/v1/schedule/optimize', 'active', 2000, 10),
((SELECT model_id FROM ml_models WHERE model_name = 'agent_performance_classifier'), 'performance_classification_api', 'https://api.wfm.local/ml/v1/agent/classify', 'active', 200, 50);

-- Insert sample recommendations
INSERT INTO ai_recommendations (model_id, recommendation_type, target_entity_id, target_entity_type, title, description, recommended_action, confidence_score, expected_impact, priority) VALUES
((SELECT model_id FROM ml_models WHERE model_name = 'workforce_demand_predictor_v2'), 'staffing_change', 'queue_customer_service', 'queue', 'Increase staffing for peak hours tomorrow', 'Model predicts 15% higher call volume 14:00-16:00 tomorrow due to promotional campaign', '{"action": "add_agents", "time_slot": "14:00-16:00", "additional_agents": 3}', 0.87, '{"metric": "service_level", "improvement": 0.08, "cost_avoidance": 15000}', 'high'),
((SELECT model_id FROM ml_models WHERE model_name = 'agent_performance_classifier'), 'training_need', 'agent_001', 'agent', 'Recommend advanced call handling training', 'Agent shows declining performance pattern that responds well to advanced training', '{"action": "schedule_training", "training_type": "advanced_call_handling", "priority": "medium"}', 0.72, '{"metric": "agent_performance", "improvement": 0.12, "value": 8000}', 'medium');

-- Insert sample performance data
INSERT INTO ml_model_performance (model_id, measurement_date, measurement_hour, accuracy, mape, prediction_count, business_value_rubles) VALUES
((SELECT model_id FROM ml_models WHERE model_name = 'workforce_demand_predictor_v2'), CURRENT_DATE, 14, 0.923, 0.087, 156, 45000),
((SELECT model_id FROM ml_models WHERE model_name = 'schedule_optimizer_ml'), CURRENT_DATE, 14, 0.856, NULL, 24, 78000),
((SELECT model_id FROM ml_models WHERE model_name = 'agent_performance_classifier'), CURRENT_DATE, 14, 0.891, NULL, 89, 23000);

-- Comments for Documentation
-- =====================================================================================

COMMENT ON TABLE ml_models IS 'Central registry for all ML models with lifecycle management';
COMMENT ON TABLE ml_training_jobs IS 'Training job execution history and configuration';
COMMENT ON TABLE ml_inference_endpoints IS 'Production ML model endpoints and monitoring';
COMMENT ON TABLE ml_features IS 'Feature store for ML model inputs';
COMMENT ON TABLE ml_feature_values IS 'Time-series storage for feature values (partitioned)';
COMMENT ON TABLE ml_predictions IS 'ML model predictions and validation results (partitioned)';
COMMENT ON TABLE ai_recommendations IS 'AI-powered recommendations for WFM decisions';
COMMENT ON TABLE ml_model_performance IS 'Model performance monitoring and drift detection';
COMMENT ON TABLE ml_ab_tests IS 'A/B testing framework for model comparison';

COMMENT ON COLUMN ml_models.hyperparameters IS 'Model hyperparameters as JSON for reproducibility';
COMMENT ON COLUMN ml_models.feature_schema IS 'Expected input feature schema and types';
COMMENT ON COLUMN ml_models.output_schema IS 'Expected output format and structure';
COMMENT ON COLUMN ml_predictions.prediction_bounds IS 'Confidence intervals for predictions';
COMMENT ON COLUMN ml_model_performance.data_drift_score IS 'Measure of input data distribution change';
COMMENT ON COLUMN ml_model_performance.concept_drift_score IS 'Measure of target relationship change';

-- Schema completion marker
INSERT INTO schema_migrations (schema_name, version, description, applied_at) 
VALUES ('121_machine_learning_ai_analytics_platform', '1.0.0', 'Enterprise ML/AI platform with full lifecycle management', NOW());