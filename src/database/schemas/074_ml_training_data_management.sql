-- Schema 074: ML Training Data Management
-- Versioned datasets for model training and validation
-- Target: Reproducible ML experiments with data lineage

-- 1. Training Dataset Registry
CREATE TABLE ml_training_datasets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_name VARCHAR(255) NOT NULL,
    dataset_type VARCHAR(50), -- classification, regression, timeseries, clustering
    version VARCHAR(50) NOT NULL,
    description TEXT,
    source_query TEXT,
    row_count BIGINT,
    feature_count INTEGER,
    target_column VARCHAR(255),
    class_distribution JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(dataset_name, version)
);

-- 2. Train/Test/Validation Splits
CREATE TABLE ml_dataset_splits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    split_type VARCHAR(20), -- train, test, validation
    split_method VARCHAR(50), -- random, stratified, temporal, custom
    split_ratio DECIMAL(5,2),
    row_count BIGINT,
    random_seed INTEGER,
    temporal_cutoff TIMESTAMP,
    stratify_column VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Feature Engineering History
CREATE TABLE ml_feature_transformations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    feature_name VARCHAR(255),
    transformation_type VARCHAR(50), -- scale, normalize, encode, impute, derive
    transformation_params JSONB,
    input_columns TEXT[],
    output_column VARCHAR(255),
    transformation_order INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Data Quality Metrics
CREATE TABLE ml_data_quality_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    metric_type VARCHAR(50), -- completeness, consistency, accuracy, timeliness
    metric_value DECIMAL(10,4),
    details JSONB,
    check_timestamp TIMESTAMP,
    passed_threshold BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Synthetic Data Generation
CREATE TABLE ml_synthetic_data_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    generation_method VARCHAR(50), -- gan, smote, bootstrap, augmentation
    target_rows BIGINT,
    generation_params JSONB,
    quality_score DECIMAL(5,2),
    generation_time_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Data Versioning and Lineage
CREATE TABLE ml_data_lineage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    parent_dataset_id UUID,
    transformation_type VARCHAR(100),
    transformation_details TEXT,
    input_tables TEXT[],
    sql_query TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Label Management
CREATE TABLE ml_label_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    label_name VARCHAR(255),
    label_type VARCHAR(50), -- binary, multiclass, multilabel, continuous
    label_values JSONB,
    positive_class_definition TEXT,
    labeling_rules TEXT,
    manual_labels_count INTEGER,
    auto_labels_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Data Drift Monitoring
CREATE TABLE ml_data_drift_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_dataset_id UUID REFERENCES ml_training_datasets(id),
    current_dataset_id UUID REFERENCES ml_training_datasets(id),
    feature_name VARCHAR(255),
    drift_metric VARCHAR(50), -- kl_divergence, wasserstein, chi_square
    drift_score DECIMAL(10,6),
    threshold DECIMAL(10,6),
    is_drifted BOOLEAN,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Sampling Strategies
CREATE TABLE ml_sampling_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES ml_training_datasets(id),
    sampling_method VARCHAR(50), -- random, stratified, systematic, cluster
    sample_size INTEGER,
    sampling_ratio DECIMAL(5,2),
    stratification_columns TEXT[],
    cluster_count INTEGER,
    seed INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample training datasets
INSERT INTO ml_training_datasets (dataset_name, dataset_type, version, description, row_count, feature_count, target_column)
VALUES 
    ('agent_performance_prediction', 'regression', 'v1.0', 'Predict agent performance metrics', 50000, 45, 'performance_score'),
    ('call_volume_forecast', 'timeseries', 'v2.1', 'Hourly call volume predictions', 87600, 25, 'call_volume'),
    ('employee_attrition', 'classification', 'v1.5', 'Predict employee turnover risk', 10000, 60, 'will_leave');

-- Insert sample splits
INSERT INTO ml_dataset_splits (dataset_id, split_type, split_method, split_ratio, row_count, random_seed)
SELECT 
    id, 
    split_type,
    'stratified',
    CASE split_type 
        WHEN 'train' THEN 0.70
        WHEN 'validation' THEN 0.15
        WHEN 'test' THEN 0.15
    END,
    CASE split_type 
        WHEN 'train' THEN 35000
        WHEN 'validation' THEN 7500
        WHEN 'test' THEN 7500
    END,
    42
FROM ml_training_datasets
CROSS JOIN (VALUES ('train'), ('validation'), ('test')) AS s(split_type)
WHERE dataset_name = 'agent_performance_prediction';

-- Insert sample data quality metrics
INSERT INTO ml_data_quality_metrics (dataset_id, metric_type, metric_value, passed_threshold, check_timestamp)
SELECT 
    id,
    'completeness',
    0.985,
    true,
    CURRENT_TIMESTAMP
FROM ml_training_datasets
WHERE dataset_name = 'agent_performance_prediction';

-- Verify ML training tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_name LIKE 'ml_%' 
ORDER BY table_name;