-- =============================================================================
-- 053_automatic_schedule_optimization.sql
-- EXACT BDD Implementation: Automatic Schedule Suggestion and Optimization Engine
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 24-automatic-schedule-optimization.feature (303 lines)
-- Purpose: Advanced schedule optimization with genetic algorithms and multi-criteria scoring
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. OPTIMIZATION ALGORITHM CONFIGURATIONS
-- =============================================================================

-- Algorithm capabilities from BDD lines 20-27
CREATE TABLE optimization_algorithms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    algorithm_id VARCHAR(50) NOT NULL UNIQUE,
    algorithm_name VARCHAR(200) NOT NULL,
    
    -- Algorithm types from BDD lines 21-26
    algorithm_type VARCHAR(50) NOT NULL CHECK (algorithm_type IN (
        'erlang_c', 'linear_programming', 'genetic_algorithms', 
        'multi_criteria_optimization', 'real_time_optimization'
    )),
    
    -- Competitive advantage from BDD lines 21-26
    argus_capability VARCHAR(100),
    wfm_implementation VARCHAR(200) NOT NULL,
    competitive_advantage TEXT,
    
    -- Algorithm configuration
    algorithm_parameters JSONB DEFAULT '{}',
    performance_characteristics JSONB DEFAULT '{}',
    
    -- Processing specifications
    typical_processing_time_seconds INTEGER,
    max_processing_time_seconds INTEGER DEFAULT 60,
    memory_requirements_mb INTEGER,
    
    -- Status and versioning
    is_active BOOLEAN DEFAULT true,
    algorithm_version VARCHAR(20) DEFAULT '1.0',
    documentation_url VARCHAR(500),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. OPTIMIZATION REQUESTS AND SESSIONS
-- =============================================================================

-- Optimization analysis sessions from BDD lines 34-43
CREATE TABLE optimization_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    
    -- Session context
    planning_period_start DATE NOT NULL,
    planning_period_end DATE NOT NULL,
    service_group_id VARCHAR(50),
    
    -- Processing stages from BDD lines 35-40
    current_stage VARCHAR(50) DEFAULT 'analyzing_coverage' CHECK (current_stage IN (
        'analyzing_coverage', 'identifying_gaps', 'generating_variants', 
        'validating_constraints', 'ranking_suggestions', 'completed', 'cancelled'
    )),
    
    -- Progress tracking from BDD lines 41-43
    progress_percentage DECIMAL(5,2) DEFAULT 0.0 CHECK (progress_percentage >= 0.0 AND progress_percentage <= 100.0),
    estimated_completion_time TIMESTAMP WITH TIME ZONE,
    processing_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processing_end_time TIMESTAMP WITH TIME ZONE,
    
    -- Session configuration
    optimization_goals JSONB DEFAULT '{}',
    constraint_parameters JSONB DEFAULT '{}',
    can_be_cancelled BOOLEAN DEFAULT true,
    
    -- Results summary
    suggestions_generated INTEGER DEFAULT 0,
    session_status VARCHAR(20) DEFAULT 'running' CHECK (session_status IN (
        'running', 'completed', 'failed', 'cancelled', 'timeout'
    )),
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. ALGORITHM COMPONENTS AND PROCESSING
-- =============================================================================

-- Algorithm component execution from BDD lines 49-55
CREATE TABLE algorithm_component_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id VARCHAR(50) NOT NULL UNIQUE,
    session_id VARCHAR(50) NOT NULL,
    
    -- Component details from BDD lines 50-55
    component_name VARCHAR(100) NOT NULL CHECK (component_name IN (
        'gap_analysis_engine', 'constraint_validator', 'pattern_generator', 
        'cost_calculator', 'scoring_engine'
    )),
    algorithm_type VARCHAR(50) NOT NULL,
    input_data_description TEXT,
    output_description TEXT,
    
    -- Processing metrics from BDD lines 50-55
    processing_time_seconds DECIMAL(5,2),
    target_processing_time_seconds INTEGER,
    
    -- Execution status
    execution_status VARCHAR(20) DEFAULT 'pending' CHECK (execution_status IN (
        'pending', 'running', 'completed', 'failed', 'skipped'
    )),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    
    -- Results
    output_data JSONB,
    performance_metrics JSONB DEFAULT '{}',
    error_details TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES optimization_sessions(session_id) ON DELETE CASCADE
);

-- =============================================================================
-- 4. CONSTRAINT VALIDATION FRAMEWORK
-- =============================================================================

-- Constraint validation from BDD lines 56-62
CREATE TABLE optimization_constraints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    constraint_id VARCHAR(50) NOT NULL UNIQUE,
    constraint_name VARCHAR(200) NOT NULL,
    
    -- Constraint types from BDD lines 57-62
    constraint_type VARCHAR(50) NOT NULL CHECK (constraint_type IN (
        'labor_laws', 'union_agreements', 'employee_contracts', 'business_rules', 'employee_preferences'
    )),
    
    -- Rules and validation from BDD lines 57-62
    rules_applied JSONB NOT NULL,
    validation_method VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    
    -- Enforcement configuration
    is_mandatory BOOLEAN DEFAULT true,
    violation_handling VARCHAR(30) DEFAULT 'reject' CHECK (violation_handling IN (
        'reject', 'warn', 'adjust', 'ignore'
    )),
    
    -- Constraint parameters
    constraint_parameters JSONB DEFAULT '{}',
    validation_query TEXT,
    error_message_template TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. OPTIMIZATION GOALS AND TARGETS
-- =============================================================================

-- Optimization targets from BDD lines 64-68
CREATE TABLE optimization_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_id VARCHAR(50) NOT NULL UNIQUE,
    goal_name VARCHAR(200) NOT NULL,
    
    -- Goal configuration from BDD lines 64-68
    weight_percentage DECIMAL(5,2) NOT NULL CHECK (weight_percentage >= 0.0 AND weight_percentage <= 100.0),
    measurement_method TEXT NOT NULL,
    target_improvement VARCHAR(50),
    
    -- Goal types from BDD lines 65-68
    goal_type VARCHAR(50) NOT NULL CHECK (goal_type IN (
        'coverage_gaps', 'cost_efficiency', 'service_level_achievement', 'implementation_complexity'
    )),
    
    -- Measurement configuration
    baseline_calculation_method TEXT,
    improvement_calculation_method TEXT,
    success_criteria TEXT,
    
    -- Target thresholds
    minimum_improvement_threshold DECIMAL(5,2),
    target_improvement_threshold DECIMAL(5,2),
    exceptional_improvement_threshold DECIMAL(5,2),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. SCHEDULE SUGGESTIONS AND RANKINGS
-- =============================================================================

-- Schedule suggestions from BDD lines 75-86
CREATE TABLE schedule_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_id VARCHAR(50) NOT NULL UNIQUE,
    session_id VARCHAR(50) NOT NULL,
    
    -- Ranking and scoring from BDD lines 76-78
    suggestion_rank INTEGER NOT NULL,
    optimization_score DECIMAL(5,2) NOT NULL CHECK (optimization_score >= 0.0 AND optimization_score <= 100.0),
    
    -- Impact metrics from BDD lines 76-78
    coverage_improvement_percentage DECIMAL(5,2),
    cost_impact_per_week DECIMAL(10,2),
    
    -- Suggestion details from BDD lines 79-86
    pattern_type VARCHAR(100),
    operators_needed INTEGER,
    operators_available INTEGER,
    risk_assessment VARCHAR(20) CHECK (risk_assessment IN ('low', 'medium', 'high')),
    
    -- Detailed scoring breakdown
    coverage_score DECIMAL(5,2),
    cost_score DECIMAL(5,2),
    compliance_score DECIMAL(5,2),
    implementation_score DECIMAL(5,2),
    
    -- Schedule data
    schedule_pattern JSONB NOT NULL,
    affected_operators JSONB DEFAULT '[]',
    implementation_timeline TEXT,
    
    -- Status and user interaction
    suggestion_status VARCHAR(20) DEFAULT 'pending' CHECK (suggestion_status IN (
        'pending', 'previewed', 'applied', 'rejected', 'modified'
    )),
    user_feedback TEXT,
    application_timestamp TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES optimization_sessions(session_id) ON DELETE CASCADE
);

-- =============================================================================
-- 7. DETAILED SCORING METHODOLOGY
-- =============================================================================

-- Scoring breakdown from BDD lines 121-133
CREATE TABLE suggestion_scoring_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scoring_id VARCHAR(50) NOT NULL UNIQUE,
    suggestion_id VARCHAR(50) NOT NULL,
    
    -- Main score components from BDD lines 122-125
    coverage_optimization_weight DECIMAL(5,2) DEFAULT 40.0,
    coverage_optimization_points DECIMAL(5,2),
    coverage_optimization_max DECIMAL(5,2) DEFAULT 40.0,
    
    cost_efficiency_weight DECIMAL(5,2) DEFAULT 30.0,
    cost_efficiency_points DECIMAL(5,2),
    cost_efficiency_max DECIMAL(5,2) DEFAULT 30.0,
    
    compliance_preferences_weight DECIMAL(5,2) DEFAULT 20.0,
    compliance_preferences_points DECIMAL(5,2),
    compliance_preferences_max DECIMAL(5,2) DEFAULT 20.0,
    
    implementation_simplicity_weight DECIMAL(5,2) DEFAULT 10.0,
    implementation_simplicity_points DECIMAL(5,2),
    implementation_simplicity_max DECIMAL(5,2) DEFAULT 10.0,
    
    -- Sub-component details from BDD lines 127-133
    gap_reduction_score DECIMAL(5,2),
    peak_coverage_score DECIMAL(5,2),
    skill_match_score DECIMAL(5,2),
    overtime_reduction_score DECIMAL(5,2),
    labor_law_compliance_score DECIMAL(5,2),
    employee_preferences_score DECIMAL(5,2),
    
    -- Calculation methods and explanations
    scoring_methodology JSONB DEFAULT '{}',
    calculation_details JSONB DEFAULT '{}',
    score_explanations JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (suggestion_id) REFERENCES schedule_suggestions(suggestion_id) ON DELETE CASCADE
);

-- =============================================================================
-- 8. BUSINESS CONTEXT AND PATTERN GENERATION
-- =============================================================================

-- Business context patterns from BDD lines 144-155
CREATE TABLE business_context_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id VARCHAR(50) NOT NULL UNIQUE,
    business_type VARCHAR(50) NOT NULL,
    
    -- Pattern types from BDD lines 145-149
    suggested_patterns JSONB NOT NULL,
    optimization_focus TEXT NOT NULL,
    
    -- Operational constraints from BDD lines 151-155
    constraint_adaptations JSONB DEFAULT '{}',
    
    -- Service level optimization from BDD lines 157-160
    service_level_factors JSONB DEFAULT '{}',
    expected_outcomes JSONB DEFAULT '{}',
    
    -- Pattern metadata
    pattern_description TEXT,
    implementation_complexity VARCHAR(20) DEFAULT 'medium' CHECK (implementation_complexity IN ('simple', 'medium', 'complex')),
    success_rate_percentage DECIMAL(5,2),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. VALIDATION RESULTS AND BUSINESS RULES
-- =============================================================================

-- Validation results from BDD lines 166-183
CREATE TABLE suggestion_validation_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    validation_id VARCHAR(50) NOT NULL UNIQUE,
    suggestion_id VARCHAR(50) NOT NULL,
    
    -- Validation categories from BDD lines 167-172
    labor_law_compliance_status VARCHAR(20) DEFAULT 'pending' CHECK (labor_law_compliance_status IN (
        'pending', 'passed', 'failed', 'warning'
    )),
    union_agreement_compliance_status VARCHAR(20) DEFAULT 'pending' CHECK (union_agreement_compliance_status IN (
        'pending', 'passed', 'failed', 'warning'
    )),
    minimum_coverage_status VARCHAR(20) DEFAULT 'pending' CHECK (minimum_coverage_status IN (
        'pending', 'passed', 'failed', 'warning'
    )),
    skill_distribution_status VARCHAR(20) DEFAULT 'pending' CHECK (skill_distribution_status IN (
        'pending', 'passed', 'failed', 'warning'
    )),
    budget_constraints_status VARCHAR(20) DEFAULT 'pending' CHECK (budget_constraints_status IN (
        'pending', 'passed', 'failed', 'warning'
    )),
    
    -- Issue detection from BDD lines 174-178
    identified_issues JSONB DEFAULT '[]',
    resolution_suggestions JSONB DEFAULT '[]',
    
    -- Overall validation summary from BDD lines 180-183
    overall_validation_result VARCHAR(20) DEFAULT 'pending' CHECK (overall_validation_result IN (
        'pending', 'fully_compliant', 'minor_issues', 'major_violations'
    )),
    validation_summary TEXT,
    action_required TEXT,
    
    -- Validation execution
    validation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    validation_duration_seconds DECIMAL(5,2),
    validator_component VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (suggestion_id) REFERENCES schedule_suggestions(suggestion_id) ON DELETE CASCADE
);

-- =============================================================================
-- 10. BULK OPERATIONS AND IMPLEMENTATION
-- =============================================================================

-- Bulk suggestion operations from BDD lines 189-210
CREATE TABLE bulk_suggestion_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_id VARCHAR(50) NOT NULL UNIQUE,
    session_id VARCHAR(50) NOT NULL,
    user_id UUID NOT NULL,
    
    -- Operation configuration
    selected_suggestions JSONB NOT NULL,
    operation_type VARCHAR(30) DEFAULT 'apply' CHECK (operation_type IN (
        'apply', 'preview', 'validate', 'rollback'
    )),
    
    -- Combined impact analysis from BDD lines 190-194
    combined_coverage_improvement DECIMAL(5,2),
    combined_cost_savings DECIMAL(10,2),
    operators_affected INTEGER,
    implementation_complexity VARCHAR(20) CHECK (implementation_complexity IN ('low', 'medium', 'high')),
    
    -- Validation results from BDD lines 196-200
    conflict_detection_result VARCHAR(20) DEFAULT 'pending' CHECK (conflict_detection_result IN (
        'pending', 'no_conflicts', 'conflicts_found', 'resolution_needed'
    )),
    resource_availability_result VARCHAR(20) DEFAULT 'pending',
    budget_impact_result VARCHAR(20) DEFAULT 'pending',
    timeline_feasibility_result VARCHAR(20) DEFAULT 'pending',
    
    -- Implementation options from BDD lines 202-205
    implementation_option VARCHAR(30) DEFAULT 'phased' CHECK (implementation_option IN (
        'immediate_full', 'phased', 'pilot_program'
    )),
    implementation_timeline_weeks INTEGER,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high')),
    
    -- Rollback configuration from BDD lines 207-210
    rollback_triggers JSONB DEFAULT '{}',
    recovery_procedures JSONB DEFAULT '{}',
    
    -- Operation status
    operation_status VARCHAR(20) DEFAULT 'pending' CHECK (operation_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'cancelled'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES optimization_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 11. API INTEGRATION INTERFACE
-- =============================================================================

-- API access from BDD lines 216-243
CREATE TABLE optimization_api_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Request parameters from BDD lines 217-222
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    service_id VARCHAR(50),
    optimization_goals JSONB DEFAULT '{}',
    constraints JSONB DEFAULT '{}',
    
    -- API request metadata
    requesting_system VARCHAR(100),
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    api_version VARCHAR(10) DEFAULT 'v1',
    authentication_method VARCHAR(30),
    
    -- Response metadata from BDD lines 238-243
    processing_time_seconds DECIMAL(5,2),
    algorithms_used JSONB DEFAULT '[]',
    data_quality_score DECIMAL(3,2),
    recommendation_confidence_percentage DECIMAL(5,2),
    
    -- Request status
    request_status VARCHAR(20) DEFAULT 'pending' CHECK (request_status IN (
        'pending', 'processing', 'completed', 'failed', 'timeout'
    )),
    
    -- Response data
    response_data JSONB,
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 12. CONFIGURATION AND ADMIN SETTINGS
-- =============================================================================

-- Admin configuration from BDD lines 249-267
CREATE TABLE optimization_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    config_category VARCHAR(50) NOT NULL,
    
    -- Algorithm tuning from BDD lines 251-255
    optimization_aggressiveness INTEGER DEFAULT 5 CHECK (optimization_aggressiveness >= 1 AND optimization_aggressiveness <= 10),
    cost_coverage_balance DECIMAL(3,2) DEFAULT 0.5 CHECK (cost_coverage_balance >= 0.0 AND cost_coverage_balance <= 1.0),
    max_processing_time_seconds INTEGER DEFAULT 30 CHECK (max_processing_time_seconds >= 5 AND max_processing_time_seconds <= 60),
    pattern_complexity_level INTEGER DEFAULT 3 CHECK (pattern_complexity_level >= 1 AND pattern_complexity_level <= 5),
    historical_data_window_months INTEGER DEFAULT 12 CHECK (historical_data_window_months >= 1 AND historical_data_window_months <= 24),
    
    -- Business rule configuration from BDD lines 257-261
    service_level_thresholds JSONB DEFAULT '{}',
    budget_limits JSONB DEFAULT '{}',
    compliance_parameters JSONB DEFAULT '{}',
    preference_weights JSONB DEFAULT '{}',
    
    -- Performance monitoring from BDD lines 263-267
    processing_time_threshold_seconds INTEGER DEFAULT 30,
    success_rate_threshold_percentage DECIMAL(5,2) DEFAULT 80.0,
    user_acceptance_threshold_percentage DECIMAL(5,2) DEFAULT 70.0,
    cost_accuracy_variance_threshold_percentage DECIMAL(5,2) DEFAULT 5.0,
    
    -- Configuration metadata
    config_description TEXT,
    last_modified_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 13. PERFORMANCE MONITORING AND TRACKING
-- =============================================================================

-- Performance tracking from BDD lines 280-297
CREATE TABLE optimization_performance_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_id VARCHAR(50) NOT NULL UNIQUE,
    session_id VARCHAR(50),
    suggestion_id VARCHAR(50),
    
    -- Performance metrics from BDD lines 281-285
    coverage_improvement_actual DECIMAL(5,2),
    coverage_improvement_projected DECIMAL(5,2),
    coverage_improvement_target DECIMAL(5,2) DEFAULT 15.0,
    
    cost_savings_actual DECIMAL(10,2),
    cost_savings_projected DECIMAL(10,2),
    cost_savings_target_percentage DECIMAL(5,2) DEFAULT 10.0,
    
    service_level_achievement_actual DECIMAL(5,2),
    service_level_achievement_target DECIMAL(5,2) DEFAULT 85.0,
    
    implementation_time_weeks DECIMAL(3,1),
    implementation_time_target_weeks DECIMAL(3,1) DEFAULT 3.0,
    
    user_acceptance_percentage DECIMAL(5,2),
    user_acceptance_target_percentage DECIMAL(5,2) DEFAULT 80.0,
    
    -- Feedback collection from BDD lines 287-291
    algorithm_accuracy_feedback JSONB DEFAULT '{}',
    user_satisfaction_feedback JSONB DEFAULT '{}',
    business_impact_feedback JSONB DEFAULT '{}',
    system_performance_feedback JSONB DEFAULT '{}',
    
    -- Learning components from BDD lines 293-297
    pattern_effectiveness_data JSONB DEFAULT '{}',
    constraint_importance_data JSONB DEFAULT '{}',
    user_preference_data JSONB DEFAULT '{}',
    business_impact_data JSONB DEFAULT '{}',
    
    -- Quality metrics from BDD lines 299-303
    suggestion_accuracy_score DECIMAL(3,2),
    compliance_rate_percentage DECIMAL(5,2),
    user_engagement_score DECIMAL(3,2),
    business_value_score DECIMAL(3,2),
    
    -- Monitoring metadata
    monitoring_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    monitoring_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES optimization_sessions(session_id) ON DELETE SET NULL,
    FOREIGN KEY (suggestion_id) REFERENCES schedule_suggestions(suggestion_id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Algorithm and session queries
CREATE INDEX idx_optimization_algorithms_type ON optimization_algorithms(algorithm_type);
CREATE INDEX idx_optimization_algorithms_active ON optimization_algorithms(is_active) WHERE is_active = true;
CREATE INDEX idx_optimization_sessions_user ON optimization_sessions(user_id);
CREATE INDEX idx_optimization_sessions_status ON optimization_sessions(session_status);
CREATE INDEX idx_optimization_sessions_period ON optimization_sessions(planning_period_start, planning_period_end);

-- Component execution queries
CREATE INDEX idx_algorithm_component_executions_session ON algorithm_component_executions(session_id);
CREATE INDEX idx_algorithm_component_executions_component ON algorithm_component_executions(component_name);
CREATE INDEX idx_algorithm_component_executions_status ON algorithm_component_executions(execution_status);

-- Constraint and goal queries
CREATE INDEX idx_optimization_constraints_type ON optimization_constraints(constraint_type);
CREATE INDEX idx_optimization_constraints_priority ON optimization_constraints(priority);
CREATE INDEX idx_optimization_constraints_active ON optimization_constraints(is_active) WHERE is_active = true;
CREATE INDEX idx_optimization_goals_type ON optimization_goals(goal_type);
CREATE INDEX idx_optimization_goals_active ON optimization_goals(is_active) WHERE is_active = true;

-- Suggestion queries
CREATE INDEX idx_schedule_suggestions_session ON schedule_suggestions(session_id);
CREATE INDEX idx_schedule_suggestions_score ON schedule_suggestions(optimization_score);
CREATE INDEX idx_schedule_suggestions_rank ON schedule_suggestions(suggestion_rank);
CREATE INDEX idx_schedule_suggestions_status ON schedule_suggestions(suggestion_status);

-- Scoring and validation queries
CREATE INDEX idx_suggestion_scoring_details_suggestion ON suggestion_scoring_details(suggestion_id);
CREATE INDEX idx_suggestion_validation_results_suggestion ON suggestion_validation_results(suggestion_id);
CREATE INDEX idx_suggestion_validation_results_overall ON suggestion_validation_results(overall_validation_result);

-- Business pattern queries
CREATE INDEX idx_business_context_patterns_type ON business_context_patterns(business_type);
CREATE INDEX idx_business_context_patterns_active ON business_context_patterns(is_active) WHERE is_active = true;

-- Bulk operation queries
CREATE INDEX idx_bulk_suggestion_operations_session ON bulk_suggestion_operations(session_id);
CREATE INDEX idx_bulk_suggestion_operations_user ON bulk_suggestion_operations(user_id);
CREATE INDEX idx_bulk_suggestion_operations_status ON bulk_suggestion_operations(operation_status);

-- API and configuration queries
CREATE INDEX idx_optimization_api_requests_service ON optimization_api_requests(service_id);
CREATE INDEX idx_optimization_api_requests_timestamp ON optimization_api_requests(request_timestamp);
CREATE INDEX idx_optimization_api_requests_status ON optimization_api_requests(request_status);
CREATE INDEX idx_optimization_configuration_category ON optimization_configuration(config_category);
CREATE INDEX idx_optimization_configuration_active ON optimization_configuration(is_active) WHERE is_active = true;

-- Performance tracking queries
CREATE INDEX idx_optimization_performance_tracking_session ON optimization_performance_tracking(session_id);
CREATE INDEX idx_optimization_performance_tracking_suggestion ON optimization_performance_tracking(suggestion_id);
CREATE INDEX idx_optimization_performance_tracking_period ON optimization_performance_tracking(monitoring_period_start, monitoring_period_end);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_optimization_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER optimization_algorithms_update_trigger
    BEFORE UPDATE ON optimization_algorithms
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER optimization_sessions_update_trigger
    BEFORE UPDATE ON optimization_sessions
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER optimization_constraints_update_trigger
    BEFORE UPDATE ON optimization_constraints
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER optimization_goals_update_trigger
    BEFORE UPDATE ON optimization_goals
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER schedule_suggestions_update_trigger
    BEFORE UPDATE ON schedule_suggestions
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER business_context_patterns_update_trigger
    BEFORE UPDATE ON business_context_patterns
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER bulk_suggestion_operations_update_trigger
    BEFORE UPDATE ON bulk_suggestion_operations
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER optimization_api_requests_update_trigger
    BEFORE UPDATE ON optimization_api_requests
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

CREATE TRIGGER optimization_configuration_update_trigger
    BEFORE UPDATE ON optimization_configuration
    FOR EACH ROW EXECUTE FUNCTION update_optimization_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active optimization sessions with progress
CREATE VIEW v_active_optimization_sessions AS
SELECT 
    os.id,
    os.session_id,
    e.full_name as user_name,
    os.current_stage,
    os.progress_percentage,
    os.estimated_completion_time,
    os.suggestions_generated,
    EXTRACT(MINUTES FROM CURRENT_TIMESTAMP - os.processing_start_time) as runtime_minutes
FROM optimization_sessions os
JOIN employees e ON os.user_id = e.id
WHERE os.session_status = 'running'
ORDER BY os.processing_start_time ASC;

-- Top-scored suggestions with details
CREATE VIEW v_top_schedule_suggestions AS
SELECT 
    ss.suggestion_id,
    ss.session_id,
    ss.suggestion_rank,
    ss.optimization_score,
    ss.coverage_improvement_percentage,
    ss.cost_impact_per_week,
    ss.pattern_type,
    ss.risk_assessment,
    svr.overall_validation_result,
    ssd.coverage_optimization_points,
    ssd.cost_efficiency_points
FROM schedule_suggestions ss
LEFT JOIN suggestion_validation_results svr ON ss.suggestion_id = svr.suggestion_id
LEFT JOIN suggestion_scoring_details ssd ON ss.suggestion_id = ssd.suggestion_id
WHERE ss.optimization_score >= 85.0
ORDER BY ss.optimization_score DESC, ss.suggestion_rank ASC;

-- Performance tracking summary
CREATE VIEW v_optimization_performance_summary AS
SELECT 
    opt.tracking_id,
    opt.session_id,
    opt.coverage_improvement_actual,
    opt.coverage_improvement_projected,
    (opt.coverage_improvement_actual >= opt.coverage_improvement_target) as coverage_target_met,
    opt.cost_savings_actual,
    opt.cost_savings_projected,
    opt.user_acceptance_percentage,
    (opt.user_acceptance_percentage >= opt.user_acceptance_target_percentage) as acceptance_target_met,
    opt.suggestion_accuracy_score,
    opt.business_value_score
FROM optimization_performance_tracking opt
WHERE opt.monitoring_period_end >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY opt.measurement_timestamp DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert optimization algorithms
INSERT INTO optimization_algorithms (algorithm_id, algorithm_name, algorithm_type, argus_capability, wfm_implementation, competitive_advantage) VALUES
('erlang_c_enhanced', 'Enhanced Erlang C Formula', 'erlang_c', 'Basic improved formula', 'Enhanced with service corridors', 'Advanced mathematical implementation'),
('genetic_scheduler', 'Genetic Algorithm Scheduler', 'genetic_algorithms', 'Not documented', 'Schedule generation optimization', 'Automated schedule creation'),
('multi_criteria_optimizer', 'Multi-Criteria Optimization Engine', 'multi_criteria_optimization', 'Not documented', '8-dimensional scoring system', 'Sophisticated decision making'),
('linear_programming_engine', 'Linear Programming Optimizer', 'linear_programming', 'Linear staffing model only', 'Full optimization engine', 'Cost and resource optimization');

-- Insert optimization constraints
INSERT INTO optimization_constraints (constraint_id, constraint_name, constraint_type, rules_applied, validation_method, priority) VALUES
('labor_law_compliance', 'Labor Law Compliance', 'labor_laws', '{"max_hours_per_week": 40, "min_rest_hours": 11, "max_overtime_percentage": 20}', 'mandatory_validation', 'critical'),
('union_agreement_compliance', 'Union Agreement Compliance', 'union_agreements', '{"shift_patterns": ["standard", "rotating"], "overtime_ratios": 0.15}', 'contract_compliance', 'critical'),
('business_rule_coverage', 'Minimum Coverage Requirements', 'business_rules', '{"min_coverage_percentage": 80, "service_level_target": 85}', 'policy_validation', 'high');

-- Insert optimization goals
INSERT INTO optimization_goals (goal_id, goal_name, goal_type, weight_percentage, measurement_method, target_improvement) VALUES
('coverage_gap_reduction', 'Coverage Gap Reduction', 'coverage_gaps', 40.0, 'Interval-by-interval analysis', '>15% reduction'),
('cost_optimization', 'Cost Efficiency Optimization', 'cost_efficiency', 30.0, 'Total labor cost', '>10% savings'),
('service_level_achievement', '80/20 Format Achievement', 'service_level_achievement', 20.0, 'Service level projection', '>5% improvement'),
('implementation_simplicity', 'Implementation Complexity Minimization', 'implementation_complexity', 10.0, 'Change management effort', 'Minimize disruption');

-- Insert business context patterns
INSERT INTO business_context_patterns (pattern_id, business_type, suggested_patterns, optimization_focus) VALUES
('contact_center_24x7', '24/7 Contact Center', '["rotating_shifts", "dupont", "continental"]', 'Continuous coverage'),
('retail_seasonal', 'Retail/Seasonal', '["flex_schedules", "part_time_mix", "split_shifts"]', 'Demand variability'),
('technical_support', 'Technical Support', '["follow_the_sun", "escalation_tiers", "overlap_shifts"]', 'Expertise availability');

-- Insert sample configuration
INSERT INTO optimization_configuration (config_id, config_category, optimization_aggressiveness, max_processing_time_seconds) VALUES
('default_config', 'algorithm_tuning', 5, 30),
('performance_monitoring', 'monitoring', 5, 30);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE optimization_algorithms IS 'BDD Lines 20-27: Algorithm capabilities beyond Argus documented methods with competitive advantages';
COMMENT ON TABLE optimization_sessions IS 'BDD Lines 34-43: Optimization analysis sessions with real-time progress tracking';
COMMENT ON TABLE algorithm_component_executions IS 'BDD Lines 49-55: Algorithm component processing with timing and dependencies';
COMMENT ON TABLE optimization_constraints IS 'BDD Lines 56-62: Constraint validation framework with priority enforcement';
COMMENT ON TABLE optimization_goals IS 'BDD Lines 64-68: Optimization targets with weighted multi-criteria scoring';
COMMENT ON TABLE schedule_suggestions IS 'BDD Lines 75-86: Generated schedule suggestions with ranking and impact analysis';
COMMENT ON TABLE suggestion_scoring_details IS 'BDD Lines 121-133: Detailed scoring methodology with transparent calculations';
COMMENT ON TABLE business_context_patterns IS 'BDD Lines 144-155: Context-aware pattern generation for different business types';
COMMENT ON TABLE suggestion_validation_results IS 'BDD Lines 166-183: Business rule validation with compliance checking';
COMMENT ON TABLE bulk_suggestion_operations IS 'BDD Lines 189-210: Bulk operations with conflict detection and rollback procedures';
COMMENT ON TABLE optimization_api_requests IS 'BDD Lines 216-243: API integration interface with structured responses';
COMMENT ON TABLE optimization_configuration IS 'BDD Lines 249-267: Admin configuration with algorithm tuning and monitoring';
COMMENT ON TABLE optimization_performance_tracking IS 'BDD Lines 280-297: Performance monitoring with learning and feedback collection';