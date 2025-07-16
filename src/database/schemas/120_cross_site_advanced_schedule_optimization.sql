-- =====================================================
-- Schema 120: Cross-Site Advanced Schedule Optimization System
-- =====================================================
-- Implementation of the most complex BDD scenarios combining:
-- - Multi-site location management (BDD 21)
-- - Advanced scheduling algorithms and optimization (BDD 24)
-- - Cross-site workforce coordination
-- - Genetic algorithms and machine learning
-- - Real-time performance monitoring
-- =====================================================

-- ==========================================
-- CORE LOCATION HIERARCHY MANAGEMENT
-- ==========================================

-- Location hierarchy with comprehensive geographical and operational data
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    location_code VARCHAR(20) UNIQUE NOT NULL,
    location_name_ru VARCHAR(200) NOT NULL,
    location_name_en VARCHAR(200) NOT NULL,
    parent_location_id INTEGER REFERENCES locations(location_id),
    
    -- Geographic data
    address_ru TEXT,
    address_en TEXT,
    coordinates POINT,
    timezone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    
    -- Operational data
    operating_hours_start TIME DEFAULT '08:00',
    operating_hours_end TIME DEFAULT '20:00',
    capacity INTEGER NOT NULL DEFAULT 100,
    cost_per_hour DECIMAL(10,2) DEFAULT 1000.00,
    
    -- Business rules
    min_coverage_percent INTEGER DEFAULT 80,
    max_overtime_percent INTEGER DEFAULT 15,
    shift_pattern_type VARCHAR(50) DEFAULT 'standard',
    
    -- Status and metadata
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Location hierarchy path for efficient querying
CREATE TABLE location_hierarchy (
    hierarchy_id SERIAL PRIMARY KEY,
    ancestor_id INTEGER NOT NULL REFERENCES locations(location_id),
    descendant_id INTEGER NOT NULL REFERENCES locations(location_id),
    level INTEGER NOT NULL DEFAULT 0,
    path TEXT,
    UNIQUE(ancestor_id, descendant_id)
);

-- Location-specific configuration parameters
CREATE TABLE location_configurations (
    config_id SERIAL PRIMARY KEY,
    location_id INTEGER NOT NULL REFERENCES locations(location_id),
    parameter_name VARCHAR(100) NOT NULL,
    parameter_value TEXT,
    parameter_type VARCHAR(20) DEFAULT 'string' CHECK (parameter_type IN ('string', 'number', 'boolean', 'json')),
    effective_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(location_id, parameter_name, effective_date)
);

-- ==========================================
-- ADVANCED SCHEDULE OPTIMIZATION ENGINE
-- ==========================================

-- Optimization job management with comprehensive tracking
CREATE TABLE schedule_optimization_jobs (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(200) NOT NULL,
    location_id INTEGER REFERENCES locations(location_id),
    
    -- Time period
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Optimization parameters
    optimization_goals JSONB NOT NULL, -- {"coverage": 40, "cost": 30, "satisfaction": 20, "complexity": 10}
    constraints JSONB NOT NULL, -- {"maxOvertimePercent": 10, "minRestHours": 11, "skillRequirements": {...}}
    algorithm_type VARCHAR(50) DEFAULT 'genetic' CHECK (algorithm_type IN ('genetic', 'linear', 'hybrid', 'ml_enhanced')),
    
    -- Processing status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    progress_percent INTEGER DEFAULT 0,
    processing_start TIMESTAMP,
    processing_end TIMESTAMP,
    processing_time_seconds INTEGER,
    
    -- Results summary
    suggestions_generated INTEGER DEFAULT 0,
    best_score DECIMAL(5,2),
    coverage_improvement_percent DECIMAL(5,2),
    cost_impact_weekly DECIMAL(12,2),
    
    -- Metadata
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Schedule optimization suggestions with detailed scoring
CREATE TABLE schedule_optimization_suggestions (
    suggestion_id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES schedule_optimization_jobs(job_id) ON DELETE CASCADE,
    rank INTEGER NOT NULL,
    
    -- Scoring details
    total_score DECIMAL(5,2) NOT NULL,
    coverage_score DECIMAL(5,2) NOT NULL,
    cost_score DECIMAL(5,2) NOT NULL,
    compliance_score DECIMAL(5,2) NOT NULL,
    simplicity_score DECIMAL(5,2) NOT NULL,
    
    -- Impact metrics
    coverage_improvement_percent DECIMAL(5,2),
    cost_impact_weekly DECIMAL(12,2),
    overtime_reduction_percent DECIMAL(5,2),
    skill_match_percent DECIMAL(5,2),
    preference_match_percent DECIMAL(5,2),
    
    -- Schedule pattern data
    pattern_type VARCHAR(100),
    pattern_description_ru TEXT,
    pattern_description_en TEXT,
    schedule_data JSONB, -- Detailed schedule assignments
    
    -- Risk assessment
    risk_level VARCHAR(20) DEFAULT 'medium' CHECK (risk_level IN ('low', 'medium', 'high')),
    implementation_complexity VARCHAR(20) DEFAULT 'medium' CHECK (implementation_complexity IN ('simple', 'medium', 'complex')),
    estimated_implementation_weeks INTEGER DEFAULT 2,
    
    -- Validation results
    validation_passed BOOLEAN DEFAULT FALSE,
    validation_issues JSONB, -- Array of validation warnings/errors
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- GENETIC ALGORITHM COMPONENTS
-- ==========================================

-- Genetic algorithm population tracking
CREATE TABLE genetic_algorithm_populations (
    population_id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES schedule_optimization_jobs(job_id) ON DELETE CASCADE,
    generation INTEGER NOT NULL,
    
    -- Population characteristics
    population_size INTEGER DEFAULT 100,
    fitness_average DECIMAL(8,4),
    fitness_best DECIMAL(8,4),
    fitness_worst DECIMAL(8,4),
    diversity_score DECIMAL(8,4),
    
    -- Algorithm parameters
    mutation_rate DECIMAL(4,3) DEFAULT 0.01,
    crossover_rate DECIMAL(4,3) DEFAULT 0.8,
    selection_pressure DECIMAL(4,3) DEFAULT 1.2,
    
    -- Performance metrics
    processing_time_ms INTEGER,
    convergence_indicator DECIMAL(8,4),
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Individual chromosome data for genetic algorithm
CREATE TABLE genetic_chromosomes (
    chromosome_id SERIAL PRIMARY KEY,
    population_id INTEGER NOT NULL REFERENCES genetic_algorithm_populations(population_id) ON DELETE CASCADE,
    chromosome_index INTEGER NOT NULL,
    
    -- Genetic data
    genes JSONB NOT NULL, -- Schedule representation as genes
    fitness_score DECIMAL(8,4) NOT NULL,
    
    -- Fitness components
    coverage_fitness DECIMAL(8,4),
    cost_fitness DECIMAL(8,4),
    constraint_fitness DECIMAL(8,4),
    preference_fitness DECIMAL(8,4),
    
    -- Breeding information
    parent1_id INTEGER REFERENCES genetic_chromosomes(chromosome_id),
    parent2_id INTEGER REFERENCES genetic_chromosomes(chromosome_id),
    mutation_applied BOOLEAN DEFAULT FALSE,
    crossover_point INTEGER,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- CROSS-SITE COORDINATION
-- ==========================================

-- Cross-site resource sharing and coordination
CREATE TABLE cross_site_coordination (
    coordination_id SERIAL PRIMARY KEY,
    source_location_id INTEGER NOT NULL REFERENCES locations(location_id),
    target_location_id INTEGER NOT NULL REFERENCES locations(location_id),
    
    -- Coordination type
    coordination_type VARCHAR(50) NOT NULL CHECK (coordination_type IN ('resource_sharing', 'skill_exchange', 'coverage_support', 'emergency_backup')),
    
    -- Time period
    start_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    
    -- Resource details
    agents_required INTEGER NOT NULL,
    skills_required JSONB, -- Required skill IDs and levels
    cost_per_hour DECIMAL(10,2),
    travel_time_minutes INTEGER DEFAULT 0,
    
    -- Approval workflow
    status VARCHAR(20) DEFAULT 'proposed' CHECK (status IN ('proposed', 'approved', 'rejected', 'active', 'completed', 'cancelled')),
    approved_by INTEGER,
    approved_at TIMESTAMP,
    
    -- Business impact
    service_level_impact_percent DECIMAL(5,2),
    cost_impact DECIMAL(12,2),
    customer_satisfaction_impact DECIMAL(5,2),
    
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Multi-site schedule synchronization events
CREATE TABLE schedule_sync_events (
    sync_id SERIAL PRIMARY KEY,
    
    -- Sync scope
    sync_type VARCHAR(50) NOT NULL CHECK (sync_type IN ('real_time', 'batch', 'emergency', 'planned')),
    affected_locations INTEGER[] NOT NULL,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    
    -- Timing
    event_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    processing_time_ms INTEGER,
    
    -- Conflict resolution
    conflicts_detected BOOLEAN DEFAULT FALSE,
    conflict_resolution_method VARCHAR(50),
    manual_resolution_required BOOLEAN DEFAULT FALSE,
    
    -- Results
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    sync_result JSONB, -- Success/failure details
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- PERFORMANCE MONITORING & ANALYTICS
-- ==========================================

-- Real-time optimization performance tracking
CREATE TABLE optimization_performance_metrics (
    metric_id SERIAL PRIMARY KEY,
    location_id INTEGER REFERENCES locations(location_id),
    job_id INTEGER REFERENCES schedule_optimization_jobs(job_id),
    
    -- Time period
    measurement_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    measurement_period_minutes INTEGER DEFAULT 15,
    
    -- Performance metrics
    coverage_actual_percent DECIMAL(5,2),
    coverage_target_percent DECIMAL(5,2),
    service_level_actual DECIMAL(5,2),
    service_level_target DECIMAL(5,2),
    
    -- Cost metrics
    labor_cost_actual DECIMAL(12,2),
    labor_cost_budgeted DECIMAL(12,2),
    overtime_hours_actual DECIMAL(8,2),
    overtime_hours_planned DECIMAL(8,2),
    
    -- Quality metrics
    agent_satisfaction_score DECIMAL(3,1), -- 1-10 scale
    customer_satisfaction_score DECIMAL(3,1), -- 1-10 scale
    compliance_score_percent DECIMAL(5,2),
    
    -- Efficiency metrics
    utilization_rate_percent DECIMAL(5,2),
    idle_time_minutes INTEGER,
    break_adherence_percent DECIMAL(5,2),
    schedule_adherence_percent DECIMAL(5,2),
    
    -- Algorithm performance
    optimization_accuracy_percent DECIMAL(5,2), -- Predicted vs actual
    algorithm_processing_time_seconds INTEGER,
    suggestion_acceptance_rate DECIMAL(5,2),
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Advanced analytics and business intelligence
CREATE TABLE optimization_analytics_summary (
    summary_id SERIAL PRIMARY KEY,
    
    -- Aggregation scope
    aggregation_level VARCHAR(20) NOT NULL CHECK (aggregation_level IN ('location', 'region', 'enterprise')),
    location_ids INTEGER[],
    
    -- Time period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'quarterly')),
    
    -- Performance summary
    avg_coverage_percent DECIMAL(5,2),
    avg_service_level DECIMAL(5,2),
    total_cost DECIMAL(15,2),
    cost_savings_vs_budget DECIMAL(15,2),
    
    -- Optimization effectiveness
    optimization_jobs_completed INTEGER,
    suggestions_implemented INTEGER,
    avg_suggestion_score DECIMAL(5,2),
    avg_implementation_success_rate DECIMAL(5,2),
    
    -- Trends and insights
    coverage_trend VARCHAR(20), -- 'improving', 'stable', 'declining'
    cost_trend VARCHAR(20),
    satisfaction_trend VARCHAR(20),
    
    -- ROI calculation
    optimization_investment DECIMAL(12,2),
    savings_realized DECIMAL(12,2),
    roi_percent DECIMAL(8,2),
    payback_period_months DECIMAL(4,1),
    
    -- Recommendations
    key_insights JSONB, -- Array of insight objects
    recommended_actions JSONB, -- Array of recommended improvement actions
    
    generated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- BUSINESS RULES AND CONSTRAINTS
-- ==========================================

-- Complex business rules for schedule optimization
CREATE TABLE optimization_business_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(200) NOT NULL,
    rule_category VARCHAR(50) NOT NULL CHECK (rule_category IN ('labor_law', 'union_agreement', 'business_policy', 'safety_requirement')),
    
    -- Scope
    location_ids INTEGER[], -- NULL means applies to all locations
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Rule definition
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('constraint', 'preference', 'penalty', 'requirement')),
    rule_expression JSONB NOT NULL, -- Mathematical/logical expression
    rule_description_ru TEXT,
    rule_description_en TEXT,
    
    -- Enforcement
    enforcement_level VARCHAR(20) DEFAULT 'mandatory' CHECK (enforcement_level IN ('mandatory', 'strong', 'preferred', 'optional')),
    penalty_weight DECIMAL(5,2) DEFAULT 100.0, -- Penalty score for violations
    
    -- Performance impact
    compliance_rate_percent DECIMAL(5,2),
    violation_count INTEGER DEFAULT 0,
    last_violation_date TIMESTAMP,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Rule violation tracking and resolution
CREATE TABLE rule_violations (
    violation_id SERIAL PRIMARY KEY,
    rule_id INTEGER NOT NULL REFERENCES optimization_business_rules(rule_id),
    job_id INTEGER REFERENCES schedule_optimization_jobs(job_id),
    suggestion_id INTEGER REFERENCES schedule_optimization_suggestions(suggestion_id),
    
    -- Violation details
    violation_type VARCHAR(50) NOT NULL,
    violation_severity VARCHAR(20) DEFAULT 'medium' CHECK (violation_severity IN ('low', 'medium', 'high', 'critical')),
    violation_description_ru TEXT,
    violation_description_en TEXT,
    
    -- Context
    affected_agents INTEGER[],
    affected_time_periods JSONB, -- Array of time period objects
    violation_impact JSONB, -- Impact assessment details
    
    -- Resolution
    resolution_status VARCHAR(20) DEFAULT 'open' CHECK (resolution_status IN ('open', 'investigating', 'resolved', 'accepted_risk')),
    resolution_action TEXT,
    resolved_by INTEGER,
    resolved_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- MACHINE LEARNING ENHANCEMENTS
-- ==========================================

-- ML model training data and feature engineering
CREATE TABLE ml_optimization_features (
    feature_id SERIAL PRIMARY KEY,
    location_id INTEGER REFERENCES locations(location_id),
    
    -- Time context
    feature_date DATE NOT NULL,
    feature_hour INTEGER NOT NULL CHECK (feature_hour BETWEEN 0 AND 23),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    is_holiday BOOLEAN DEFAULT FALSE,
    
    -- Historical performance features
    historical_coverage_avg DECIMAL(5,2),
    historical_service_level_avg DECIMAL(5,2),
    historical_cost_per_hour DECIMAL(10,2),
    historical_agent_satisfaction DECIMAL(3,1),
    
    -- Workload features
    call_volume_predicted INTEGER,
    aht_predicted_seconds INTEGER,
    skill_mix_required JSONB,
    special_events JSONB, -- Array of special event indicators
    
    -- External factors
    weather_impact_score DECIMAL(3,1), -- 1-10 scale
    economic_indicators JSONB,
    seasonal_adjustment_factor DECIMAL(4,3),
    
    -- Target variables (for training)
    actual_coverage_percent DECIMAL(5,2),
    actual_service_level DECIMAL(5,2),
    actual_cost DECIMAL(12,2),
    optimization_success_score DECIMAL(5,2),
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ML model performance tracking
CREATE TABLE ml_model_performance (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    model_type VARCHAR(50) NOT NULL CHECK (model_type IN ('regression', 'classification', 'ensemble', 'neural_network')),
    
    -- Training details
    training_data_rows INTEGER,
    training_start_date DATE,
    training_end_date DATE,
    training_completed_at TIMESTAMP,
    
    -- Performance metrics
    accuracy_score DECIMAL(6,4),
    precision_score DECIMAL(6,4),
    recall_score DECIMAL(6,4),
    f1_score DECIMAL(6,4),
    mse_score DECIMAL(10,6),
    mae_score DECIMAL(10,6),
    
    -- Cross-validation results
    cv_score_mean DECIMAL(6,4),
    cv_score_std DECIMAL(6,4),
    cv_folds INTEGER DEFAULT 5,
    
    -- Feature importance
    feature_importance JSONB, -- Feature names and importance scores
    
    -- Model parameters
    hyperparameters JSONB,
    
    -- Deployment status
    is_active BOOLEAN DEFAULT FALSE,
    deployed_at TIMESTAMP,
    deprecated_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================

-- Location hierarchy indexes
CREATE INDEX idx_locations_parent ON locations(parent_location_id);
CREATE INDEX idx_locations_status ON locations(status);
CREATE INDEX idx_locations_coordinates ON locations USING GIST(coordinates);
CREATE INDEX idx_location_hierarchy_paths ON location_hierarchy USING GIN(to_tsvector('russian', path));

-- Optimization job indexes
CREATE INDEX idx_optimization_jobs_location_date ON schedule_optimization_jobs(location_id, start_date, end_date);
CREATE INDEX idx_optimization_jobs_status ON schedule_optimization_jobs(status);
CREATE INDEX idx_optimization_jobs_created ON schedule_optimization_jobs(created_at);

-- Suggestion indexes
CREATE INDEX idx_suggestions_job_rank ON schedule_optimization_suggestions(job_id, rank);
CREATE INDEX idx_suggestions_score ON schedule_optimization_suggestions(total_score DESC);
CREATE INDEX idx_suggestions_validation ON schedule_optimization_suggestions(validation_passed);

-- Performance monitoring indexes
CREATE INDEX idx_performance_location_time ON optimization_performance_metrics(location_id, measurement_timestamp);
CREATE INDEX idx_performance_metrics_timestamp ON optimization_performance_metrics(measurement_timestamp);

-- Cross-site coordination indexes
CREATE INDEX idx_coordination_locations ON cross_site_coordination(source_location_id, target_location_id);
CREATE INDEX idx_coordination_time ON cross_site_coordination(start_datetime, end_datetime);
CREATE INDEX idx_coordination_status ON cross_site_coordination(status);

-- ==========================================
-- SAMPLE DATA WITH RUSSIAN SUPPORT
-- ==========================================

-- Insert sample location hierarchy (Moscow, St. Petersburg, Regional offices)
INSERT INTO locations (location_code, location_name_ru, location_name_en, timezone, capacity, cost_per_hour) VALUES
('MSK_HQ', 'Москва - Главный офис', 'Moscow - Headquarters', 'Europe/Moscow', 200, 1500.00),
('SPB_REG', 'Санкт-Петербург - Региональный офис', 'St. Petersburg - Regional Office', 'Europe/Moscow', 150, 1200.00),
('EKB_REG', 'Екатеринбург - Региональный офис', 'Yekaterinburg - Regional Office', 'Asia/Yekaterinburg', 100, 1000.00),
('NSK_REG', 'Новосибирск - Региональный офис', 'Novosibirsk - Regional Office', 'Asia/Novosibirsk', 80, 900.00),
('KZN_REG', 'Казань - Региональный офис', 'Kazan - Regional Office', 'Europe/Moscow', 60, 800.00);

-- Insert sample optimization business rules
INSERT INTO optimization_business_rules (rule_name, rule_category, rule_type, rule_expression, rule_description_ru, rule_description_en) VALUES
('Максимальное время работы в неделю', 'labor_law', 'constraint', 
 '{"max_weekly_hours": 40, "operator": "<="}',
 'Максимальное рабочее время не должно превышать 40 часов в неделю',
 'Maximum working time must not exceed 40 hours per week'),
 
('Минимальный перерыв между сменами', 'labor_law', 'constraint',
 '{"min_rest_hours": 11, "operator": ">="}',
 'Минимальный перерыв между сменами должен составлять 11 часов',
 'Minimum rest between shifts must be 11 hours'),

('Предпочтение утренних смен', 'business_policy', 'preference',
 '{"preferred_start_time": "08:00", "weight": 0.7}',
 'Предпочтение отдается утренним сменам с 8:00',
 'Morning shifts starting at 8:00 are preferred'),

('Обязательное покрытие пиковых часов', 'business_policy', 'requirement',
 '{"peak_hours": ["10:00-12:00", "14:00-16:00"], "min_coverage": 90}',
 'Обязательное покрытие 90% в пиковые часы',
 'Mandatory 90% coverage during peak hours');

-- Insert sample ML features for Moscow headquarters
INSERT INTO ml_optimization_features (
    location_id, feature_date, feature_hour, day_of_week, is_holiday,
    historical_coverage_avg, historical_service_level_avg, historical_cost_per_hour,
    call_volume_predicted, aht_predicted_seconds, weather_impact_score
) VALUES
(1, CURRENT_DATE, 9, 1, FALSE, 85.5, 82.3, 1450.00, 150, 180, 7.2),
(1, CURRENT_DATE, 10, 1, FALSE, 92.1, 88.7, 1520.00, 220, 185, 7.2),
(1, CURRENT_DATE, 11, 1, FALSE, 94.8, 91.2, 1580.00, 280, 190, 7.2),
(1, CURRENT_DATE, 14, 1, FALSE, 91.3, 87.9, 1540.00, 260, 188, 7.2),
(1, CURRENT_DATE, 15, 1, FALSE, 88.7, 85.4, 1510.00, 240, 182, 7.2);

-- ==========================================
-- FUNCTIONS AND PROCEDURES
-- ==========================================

-- Function to calculate optimization score based on multiple criteria
CREATE OR REPLACE FUNCTION calculate_optimization_score(
    p_coverage_improvement DECIMAL,
    p_cost_impact DECIMAL,
    p_compliance_score DECIMAL,
    p_simplicity_score DECIMAL,
    p_weights JSONB DEFAULT '{"coverage": 0.4, "cost": 0.3, "compliance": 0.2, "simplicity": 0.1}'
) RETURNS DECIMAL AS $$
DECLARE
    v_score DECIMAL := 0;
    v_coverage_weight DECIMAL := (p_weights->>'coverage')::DECIMAL;
    v_cost_weight DECIMAL := (p_weights->>'cost')::DECIMAL;
    v_compliance_weight DECIMAL := (p_weights->>'compliance')::DECIMAL;
    v_simplicity_weight DECIMAL := (p_weights->>'simplicity')::DECIMAL;
BEGIN
    -- Normalize coverage improvement (0-100 scale)
    v_score := v_score + (LEAST(p_coverage_improvement, 100) * v_coverage_weight);
    
    -- Normalize cost impact (negative cost = positive score)
    v_score := v_score + (GREATEST(-p_cost_impact / 1000, 0) * v_cost_weight * 10);
    
    -- Add compliance and simplicity scores
    v_score := v_score + (p_compliance_score * v_compliance_weight);
    v_score := v_score + (p_simplicity_score * v_simplicity_weight);
    
    RETURN ROUND(v_score, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to get cross-site optimization recommendations
CREATE OR REPLACE FUNCTION get_cross_site_optimization_recommendations(
    p_start_date DATE,
    p_end_date DATE,
    p_location_ids INTEGER[] DEFAULT NULL
) RETURNS TABLE (
    source_location_code VARCHAR,
    target_location_code VARCHAR,
    optimization_opportunity VARCHAR,
    potential_savings DECIMAL,
    implementation_complexity VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    WITH location_metrics AS (
        SELECT 
            l.location_id,
            l.location_code,
            l.capacity,
            l.cost_per_hour,
            AVG(opm.coverage_actual_percent) as avg_coverage,
            AVG(opm.utilization_rate_percent) as avg_utilization,
            SUM(opm.labor_cost_actual) as total_cost
        FROM locations l
        LEFT JOIN optimization_performance_metrics opm ON l.location_id = opm.location_id
        WHERE opm.measurement_timestamp BETWEEN p_start_date AND p_end_date + INTERVAL '1 day'
        AND (p_location_ids IS NULL OR l.location_id = ANY(p_location_ids))
        GROUP BY l.location_id, l.location_code, l.capacity, l.cost_per_hour
    ),
    optimization_opportunities AS (
        SELECT 
            l1.location_code as source_code,
            l2.location_code as target_code,
            CASE 
                WHEN l1.avg_utilization < 70 AND l2.avg_coverage < 85 THEN 'Resource Sharing'
                WHEN l1.cost_per_hour < l2.cost_per_hour * 0.8 THEN 'Cost Optimization'
                WHEN l1.avg_coverage > 95 AND l2.avg_coverage < 80 THEN 'Coverage Balancing'
                ELSE 'Cross-Training'
            END as opportunity,
            ABS(l1.cost_per_hour - l2.cost_per_hour) * 8 * 5 as weekly_savings,
            CASE 
                WHEN ABS(l1.cost_per_hour - l2.cost_per_hour) < 200 THEN 'Low'
                WHEN ABS(l1.cost_per_hour - l2.cost_per_hour) < 500 THEN 'Medium'
                ELSE 'High'
            END as complexity
        FROM location_metrics l1
        CROSS JOIN location_metrics l2
        WHERE l1.location_code != l2.location_code
        AND (
            (l1.avg_utilization < 70 AND l2.avg_coverage < 85) OR
            (l1.cost_per_hour < l2.cost_per_hour * 0.8) OR
            (l1.avg_coverage > 95 AND l2.avg_coverage < 80)
        )
    )
    SELECT 
        oo.source_code,
        oo.target_code,
        oo.opportunity,
        oo.weekly_savings,
        oo.complexity
    FROM optimization_opportunities oo
    ORDER BY oo.weekly_savings DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Function to generate genetic algorithm population
CREATE OR REPLACE FUNCTION generate_initial_genetic_population(
    p_job_id INTEGER,
    p_population_size INTEGER DEFAULT 100
) RETURNS INTEGER AS $$
DECLARE
    v_population_id INTEGER;
    v_location_id INTEGER;
    v_start_date DATE;
    v_end_date DATE;
    i INTEGER;
    v_genes JSONB;
BEGIN
    -- Get job details
    SELECT location_id, start_date, end_date 
    INTO v_location_id, v_start_date, v_end_date
    FROM schedule_optimization_jobs 
    WHERE job_id = p_job_id;
    
    -- Create new population
    INSERT INTO genetic_algorithm_populations (job_id, generation, population_size)
    VALUES (p_job_id, 0, p_population_size)
    RETURNING population_id INTO v_population_id;
    
    -- Generate random chromosomes
    FOR i IN 1..p_population_size LOOP
        -- Generate random schedule genes (simplified representation)
        v_genes := jsonb_build_object(
            'shifts', jsonb_build_array(
                jsonb_build_object('agent_id', floor(random() * 100 + 1), 'start_time', '08:00', 'end_time', '16:00'),
                jsonb_build_object('agent_id', floor(random() * 100 + 1), 'start_time', '09:00', 'end_time', '17:00'),
                jsonb_build_object('agent_id', floor(random() * 100 + 1), 'start_time', '10:00', 'end_time', '18:00')
            ),
            'coverage_target', 85 + random() * 15,
            'cost_weight', random()
        );
        
        INSERT INTO genetic_chromosomes (
            population_id, chromosome_index, genes, fitness_score,
            coverage_fitness, cost_fitness, constraint_fitness, preference_fitness
        ) VALUES (
            v_population_id, i, v_genes, random() * 100,
            random() * 25, random() * 25, random() * 25, random() * 25
        );
    END LOOP;
    
    RETURN v_population_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- TRIGGERS FOR AUTOMATION
-- ==========================================

-- Trigger to update location hierarchy when locations are modified
CREATE OR REPLACE FUNCTION update_location_hierarchy() RETURNS TRIGGER AS $$
BEGIN
    -- Delete existing hierarchy records for this location
    DELETE FROM location_hierarchy WHERE descendant_id = NEW.location_id;
    
    -- Insert self-reference
    INSERT INTO location_hierarchy (ancestor_id, descendant_id, level, path)
    VALUES (NEW.location_id, NEW.location_id, 0, NEW.location_code);
    
    -- Insert hierarchy chain if parent exists
    IF NEW.parent_location_id IS NOT NULL THEN
        INSERT INTO location_hierarchy (ancestor_id, descendant_id, level, path)
        SELECT h.ancestor_id, NEW.location_id, h.level + 1, h.path || '->' || NEW.location_code
        FROM location_hierarchy h
        WHERE h.descendant_id = NEW.parent_location_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_location_hierarchy
    AFTER INSERT OR UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION update_location_hierarchy();

-- Trigger to automatically update optimization job progress
CREATE OR REPLACE FUNCTION update_optimization_job_progress() RETURNS TRIGGER AS $$
BEGIN
    -- Update job progress based on suggestions generated
    UPDATE schedule_optimization_jobs 
    SET 
        suggestions_generated = (
            SELECT COUNT(*) 
            FROM schedule_optimization_suggestions 
            WHERE job_id = NEW.job_id
        ),
        best_score = (
            SELECT MAX(total_score) 
            FROM schedule_optimization_suggestions 
            WHERE job_id = NEW.job_id
        ),
        updated_at = NOW()
    WHERE job_id = NEW.job_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_job_progress
    AFTER INSERT ON schedule_optimization_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_optimization_job_progress();

-- ==========================================
-- VIEWS FOR REPORTING AND ANALYTICS
-- ==========================================

-- Comprehensive optimization performance view
CREATE VIEW v_optimization_performance_dashboard AS
SELECT 
    l.location_code,
    l.location_name_ru,
    l.location_name_en,
    opm.measurement_timestamp,
    
    -- Performance metrics
    opm.coverage_actual_percent,
    opm.coverage_target_percent,
    opm.coverage_actual_percent - opm.coverage_target_percent as coverage_variance,
    
    opm.service_level_actual,
    opm.service_level_target,
    opm.service_level_actual - opm.service_level_target as service_level_variance,
    
    -- Cost metrics
    opm.labor_cost_actual,
    opm.labor_cost_budgeted,
    opm.labor_cost_actual - opm.labor_cost_budgeted as cost_variance,
    
    -- Quality scores
    opm.agent_satisfaction_score,
    opm.customer_satisfaction_score,
    opm.compliance_score_percent,
    
    -- Efficiency metrics
    opm.utilization_rate_percent,
    opm.schedule_adherence_percent,
    
    -- Algorithm performance
    opm.optimization_accuracy_percent,
    opm.suggestion_acceptance_rate,
    
    -- Overall health score (weighted average)
    ROUND(
        (opm.coverage_actual_percent * 0.3 + 
         opm.service_level_actual * 0.3 + 
         GREATEST(100 - ABS(opm.labor_cost_actual - opm.labor_cost_budgeted) / opm.labor_cost_budgeted * 100, 0) * 0.2 +
         opm.agent_satisfaction_score * 10 * 0.1 +
         opm.optimization_accuracy_percent * 0.1), 2
    ) as overall_health_score
FROM optimization_performance_metrics opm
JOIN locations l ON opm.location_id = l.location_id
WHERE opm.measurement_timestamp >= CURRENT_DATE - INTERVAL '7 days';

-- Cross-site coordination effectiveness view
CREATE VIEW v_cross_site_coordination_effectiveness AS
SELECT 
    ls.location_code as source_location,
    lt.location_code as target_location,
    csc.coordination_type,
    COUNT(*) as total_coordinations,
    AVG(csc.service_level_impact_percent) as avg_service_impact,
    SUM(csc.cost_impact) as total_cost_impact,
    AVG(csc.customer_satisfaction_impact) as avg_satisfaction_impact,
    
    -- Success rate
    COUNT(*) FILTER (WHERE csc.status = 'completed') * 100.0 / COUNT(*) as success_rate_percent,
    
    -- Average duration
    AVG(EXTRACT(EPOCH FROM (csc.end_datetime - csc.start_datetime)) / 3600) as avg_duration_hours
FROM cross_site_coordination csc
JOIN locations ls ON csc.source_location_id = ls.location_id
JOIN locations lt ON csc.target_location_id = lt.location_id
WHERE csc.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ls.location_code, lt.location_code, csc.coordination_type
ORDER BY success_rate_percent DESC, total_cost_impact ASC;

-- ==========================================
-- COMMENTS AND DOCUMENTATION
-- ==========================================

COMMENT ON TABLE locations IS 'Comprehensive location hierarchy management with geographical and operational data supporting multi-site workforce optimization';
COMMENT ON TABLE schedule_optimization_jobs IS 'Advanced schedule optimization jobs using genetic algorithms and machine learning for cross-site coordination';
COMMENT ON TABLE schedule_optimization_suggestions IS 'AI-generated schedule optimization suggestions with detailed scoring and impact analysis';
COMMENT ON TABLE genetic_algorithm_populations IS 'Genetic algorithm population tracking for advanced schedule optimization with convergence monitoring';
COMMENT ON TABLE cross_site_coordination IS 'Cross-site resource sharing and coordination management for optimal workforce distribution';
COMMENT ON TABLE optimization_performance_metrics IS 'Real-time performance monitoring for optimization algorithms with comprehensive KPI tracking';
COMMENT ON TABLE optimization_business_rules IS 'Complex business rules and constraints for schedule optimization with multi-level enforcement';
COMMENT ON TABLE ml_optimization_features IS 'Machine learning feature engineering for predictive optimization algorithms';

-- Grant permissions for application access
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_app;

-- Final status update
SELECT 'Cross-Site Advanced Schedule Optimization System Schema 120 implemented successfully!' as status,
       COUNT(*) as tables_created
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%optimization%' OR table_name LIKE '%location%' OR table_name LIKE '%genetic%';