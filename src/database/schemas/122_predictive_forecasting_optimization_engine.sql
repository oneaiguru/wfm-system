-- =====================================================================================
-- Schema 122: Predictive Forecasting and Optimization Engine
-- =====================================================================================
-- Description: Advanced predictive analytics with confidence intervals, multi-horizon
--             forecasting, and AI-powered optimization for workforce management
-- Business Value: Accurate demand prediction, optimal resource allocation, proactive planning
-- Dependencies: Schema 121 (ML platform), Schema 001 (base), Schema 073-074 (ML foundations)
-- Complexity: ADVANCED - Enterprise predictive analytics with optimization
-- =====================================================================================

-- Forecasting Models and Configuration
-- =====================================================================================

-- Advanced forecasting model definitions
CREATE TABLE forecasting_models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- 'arima', 'sarima', 'lstm', 'transformer', 'ensemble'
    forecast_target VARCHAR(50) NOT NULL, -- 'call_volume', 'aht', 'occupancy', 'service_level'
    
    -- Model configuration
    model_config JSONB NOT NULL, -- Model-specific parameters
    feature_config JSONB, -- Feature engineering configuration
    training_config JSONB, -- Training parameters
    
    -- Forecasting capabilities
    min_horizon_minutes INTEGER DEFAULT 15, -- Minimum forecast horizon
    max_horizon_minutes INTEGER DEFAULT 10080, -- Maximum horizon (1 week)
    forecast_resolution_minutes INTEGER DEFAULT 15, -- Forecast granularity
    update_frequency_minutes INTEGER DEFAULT 15, -- How often to update forecasts
    
    -- Model quality
    accuracy_target DECIMAL(5,4) DEFAULT 0.85, -- Target accuracy (MAPE)
    confidence_level DECIMAL(3,2) DEFAULT 0.95, -- Confidence level for intervals
    
    -- Business context
    business_unit VARCHAR(100),
    queue_scope TEXT[], -- Queues this model applies to
    agent_scope TEXT[], -- Agent groups this model applies to
    time_scope JSONB, -- Time periods model is valid for
    
    -- Model lifecycle
    status VARCHAR(20) DEFAULT 'development', -- 'development', 'testing', 'production', 'deprecated'
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_trained_at TIMESTAMP WITH TIME ZONE,
    next_training_due TIMESTAMP WITH TIME ZONE,
    
    -- Performance tracking
    current_mape DECIMAL(8,4), -- Current Mean Absolute Percentage Error
    current_mae DECIMAL(10,2), -- Current Mean Absolute Error
    current_rmse DECIMAL(10,2), -- Current Root Mean Squared Error
    bias_percentage DECIMAL(8,4), -- Forecast bias
    seasonal_accuracy DECIMAL(5,4), -- Accuracy for seasonal patterns
    
    UNIQUE(model_name, business_unit)
);

-- Forecast execution and results storage
CREATE TABLE forecast_executions (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES forecasting_models(model_id),
    
    -- Execution context
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    forecast_date DATE NOT NULL, -- Date this forecast covers
    forecast_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    forecast_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Execution parameters
    execution_config JSONB, -- Runtime configuration
    input_data_hash VARCHAR(64), -- Hash of input data for reproducibility
    feature_importance JSONB, -- Feature importance for this execution
    
    -- Quality metrics
    data_quality_score DECIMAL(3,2), -- Input data quality (0.0-1.0)
    model_confidence DECIMAL(3,2), -- Model confidence in this execution
    execution_time_ms INTEGER, -- Time taken to generate forecast
    
    -- Business context
    business_driver VARCHAR(100), -- What triggered this forecast
    execution_type VARCHAR(30) DEFAULT 'scheduled', -- 'scheduled', 'manual', 'event_triggered'
    triggered_by VARCHAR(100),
    
    -- Results summary
    total_forecast_points INTEGER, -- Number of forecast points generated
    avg_confidence_interval_width DECIMAL(8,2), -- Average CI width
    forecast_trend VARCHAR(20), -- 'increasing', 'decreasing', 'stable', 'volatile'
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'running', -- 'running', 'completed', 'failed', 'cancelled'
    error_message TEXT,
    completion_percentage INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (forecast_date);

-- Create monthly partitions for forecast executions
CREATE TABLE forecast_executions_2024_01 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE forecast_executions_2024_02 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE forecast_executions_2024_03 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE forecast_executions_2024_04 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE forecast_executions_2024_05 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE forecast_executions_2024_06 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE forecast_executions_2024_07 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE forecast_executions_2024_08 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE forecast_executions_2024_09 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE forecast_executions_2024_10 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE forecast_executions_2024_11 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE forecast_executions_2024_12 PARTITION OF forecast_executions
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE forecast_executions_2025_01 PARTITION OF forecast_executions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Detailed forecast results with confidence intervals
CREATE TABLE forecast_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id UUID REFERENCES forecast_executions(execution_id),
    model_id UUID REFERENCES forecasting_models(model_id),
    
    -- Time and target context
    forecast_timestamp TIMESTAMP WITH TIME ZONE NOT NULL, -- When this point was forecast
    target_timestamp TIMESTAMP WITH TIME ZONE NOT NULL, -- Time point being forecast
    horizon_minutes INTEGER NOT NULL, -- Minutes ahead this forecast is for
    
    -- Entity context
    entity_id VARCHAR(100), -- queue_id, agent_id, site_id, etc.
    entity_type VARCHAR(50), -- 'queue', 'agent', 'site', 'global'
    metric_name VARCHAR(50) NOT NULL, -- 'call_volume', 'aht', 'occupancy'
    
    -- Forecast values
    forecast_value DECIMAL(15,6) NOT NULL, -- Main forecast value
    confidence_level DECIMAL(3,2) NOT NULL, -- Confidence level (e.g., 0.95)
    lower_bound DECIMAL(15,6), -- Lower confidence bound
    upper_bound DECIMAL(15,6), -- Upper confidence bound
    
    -- Alternative forecasts (for ensemble models)
    alternative_forecasts JSONB, -- Array of alternative predictions
    forecast_distribution JSONB, -- Full probability distribution if available
    
    -- Quality indicators
    forecast_quality VARCHAR(20), -- 'high', 'medium', 'low', 'uncertain'
    uncertainty_score DECIMAL(3,2), -- Uncertainty level (0.0-1.0)
    seasonality_component DECIMAL(15,6), -- Seasonal component of forecast
    trend_component DECIMAL(15,6), -- Trend component of forecast
    irregular_component DECIMAL(15,6), -- Irregular/random component
    
    -- External factors
    external_factor_impact JSONB, -- Impact of external factors
    weather_adjustment DECIMAL(8,4), -- Weather-based adjustment
    event_adjustment DECIMAL(8,4), -- Special event adjustment
    holiday_adjustment DECIMAL(8,4), -- Holiday adjustment
    
    -- Validation (when actual value becomes known)
    actual_value DECIMAL(15,6), -- Actual observed value
    absolute_error DECIMAL(15,6), -- |forecast - actual|
    percentage_error DECIMAL(8,4), -- (forecast - actual) / actual * 100
    within_confidence_interval BOOLEAN, -- Was actual within CI?
    accuracy_tier VARCHAR(20), -- 'excellent', 'good', 'fair', 'poor'
    
    -- Business impact
    forecast_used_for_decision BOOLEAN DEFAULT false,
    decision_type VARCHAR(50), -- Type of decision made based on this forecast
    business_value_rubles DECIMAL(12,2), -- Value generated by using this forecast
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(execution_id, target_timestamp, entity_id, entity_type, metric_name)
) PARTITION BY RANGE (target_timestamp);

-- Create monthly partitions for forecast results
CREATE TABLE forecast_results_2024_01 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE forecast_results_2024_02 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE forecast_results_2024_03 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE forecast_results_2024_04 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE forecast_results_2024_05 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE forecast_results_2024_06 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE forecast_results_2024_07 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE forecast_results_2024_08 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE forecast_results_2024_09 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE forecast_results_2024_10 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE forecast_results_2024_11 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE forecast_results_2024_12 PARTITION OF forecast_results
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE forecast_results_2025_01 PARTITION OF forecast_results
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Optimization Engine Framework
-- =====================================================================================

-- Optimization problem definitions
CREATE TABLE optimization_problems (
    problem_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem_name VARCHAR(100) NOT NULL,
    problem_type VARCHAR(50) NOT NULL, -- 'schedule_optimization', 'resource_allocation', 'capacity_planning'
    
    -- Problem definition
    objective_function JSONB NOT NULL, -- Definition of what to optimize
    constraints JSONB NOT NULL, -- Constraints and their definitions
    decision_variables JSONB NOT NULL, -- Variables that can be changed
    
    -- Optimization scope
    optimization_scope JSONB, -- What entities this applies to
    time_horizon_hours INTEGER DEFAULT 168, -- Optimization time horizon (1 week default)
    optimization_granularity_minutes INTEGER DEFAULT 15, -- Time granularity
    
    -- Algorithm configuration
    algorithm_type VARCHAR(50) NOT NULL, -- 'genetic', 'simulated_annealing', 'linear_programming', 'ml_hybrid'
    algorithm_config JSONB, -- Algorithm-specific parameters
    max_execution_time_minutes INTEGER DEFAULT 60, -- Maximum optimization time
    
    -- Quality targets
    target_improvement_percentage DECIMAL(5,2), -- Minimum improvement target
    acceptable_constraint_violations INTEGER DEFAULT 0, -- Allowed constraint violations
    
    -- Business context
    business_priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    cost_per_execution_rubles DECIMAL(10,2), -- Cost of running optimization
    expected_savings_rubles DECIMAL(12,2), -- Expected savings from optimization
    
    -- Execution scheduling
    execution_frequency VARCHAR(30), -- 'manual', 'daily', 'weekly', 'event_triggered'
    next_execution_time TIMESTAMP WITH TIME ZONE,
    
    -- Problem lifecycle
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'deprecated'
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(problem_name)
);

-- Optimization execution history
CREATE TABLE optimization_executions (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem_id UUID REFERENCES optimization_problems(problem_id),
    
    -- Execution context
    execution_start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    execution_end_time TIMESTAMP WITH TIME ZONE,
    optimization_for_date DATE NOT NULL, -- Date this optimization covers
    
    -- Input data
    input_data_snapshot JSONB, -- Snapshot of input data used
    forecast_data_used JSONB, -- Forecast data that informed optimization
    current_state JSONB, -- Current state before optimization
    
    -- Execution parameters
    algorithm_config_used JSONB, -- Actual algorithm configuration used
    computational_resources JSONB, -- Resources allocated for execution
    random_seed INTEGER, -- For reproducibility
    
    -- Execution progress
    status VARCHAR(20) DEFAULT 'running', -- 'queued', 'running', 'completed', 'failed', 'cancelled'
    progress_percentage INTEGER DEFAULT 0,
    current_iteration INTEGER DEFAULT 0,
    max_iterations INTEGER,
    
    -- Results summary
    objective_value_before DECIMAL(15,6), -- Objective function value before
    objective_value_after DECIMAL(15,6), -- Objective function value after
    improvement_percentage DECIMAL(8,4), -- Percentage improvement achieved
    constraint_violations INTEGER DEFAULT 0, -- Number of constraint violations
    
    -- Solution quality
    solution_feasibility VARCHAR(20), -- 'feasible', 'infeasible', 'partially_feasible'
    solution_optimality VARCHAR(20), -- 'optimal', 'near_optimal', 'good', 'poor'
    convergence_achieved BOOLEAN DEFAULT false,
    
    -- Business metrics
    estimated_cost_savings_rubles DECIMAL(12,2),
    implementation_complexity VARCHAR(20), -- 'low', 'medium', 'high'
    stakeholder_approval_required BOOLEAN DEFAULT false,
    
    -- Technical details
    execution_log TEXT, -- Detailed execution log
    error_message TEXT, -- Error details if failed
    memory_usage_mb INTEGER, -- Peak memory usage
    cpu_time_seconds INTEGER, -- CPU time consumed
    
    triggered_by VARCHAR(100), -- Who/what triggered this execution
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (optimization_for_date);

-- Create monthly partitions for optimization executions
CREATE TABLE optimization_executions_2024_01 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE optimization_executions_2024_02 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE optimization_executions_2024_03 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE optimization_executions_2024_04 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE optimization_executions_2024_05 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE optimization_executions_2024_06 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE optimization_executions_2024_07 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE optimization_executions_2024_08 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE optimization_executions_2024_09 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE optimization_executions_2024_10 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE optimization_executions_2024_11 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE optimization_executions_2024_12 PARTITION OF optimization_executions
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE optimization_executions_2025_01 PARTITION OF optimization_executions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Detailed optimization solutions
CREATE TABLE optimization_solutions (
    solution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id UUID REFERENCES optimization_executions(execution_id),
    problem_id UUID REFERENCES optimization_problems(problem_id),
    
    -- Solution identification
    solution_rank INTEGER DEFAULT 1, -- Rank of this solution (1 = best)
    solution_type VARCHAR(30) DEFAULT 'primary', -- 'primary', 'alternative', 'fallback'
    
    -- Time context
    solution_timestamp TIMESTAMP WITH TIME ZONE NOT NULL, -- When in schedule this applies
    time_slot_start TIMESTAMP WITH TIME ZONE NOT NULL,
    time_slot_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Entity assignments
    entity_id VARCHAR(100) NOT NULL, -- agent_id, resource_id, etc.
    entity_type VARCHAR(50) NOT NULL, -- 'agent', 'resource', 'shift'
    assignment_type VARCHAR(50), -- 'scheduled', 'standby', 'training', 'break'
    
    -- Assignment details
    assigned_activity JSONB, -- Detailed activity assignment
    skill_requirements JSONB, -- Required skills for this assignment
    performance_targets JSONB, -- Expected performance targets
    
    -- Resource allocation
    allocated_capacity DECIMAL(5,4), -- Percentage of capacity allocated (0.0-1.0)
    utilization_target DECIMAL(5,4), -- Target utilization for this assignment
    workload_distribution JSONB, -- How workload is distributed
    
    -- Quality metrics
    assignment_confidence DECIMAL(3,2), -- Confidence in this assignment (0.0-1.0)
    constraint_compliance DECIMAL(3,2), -- How well constraints are met (0.0-1.0)
    objective_contribution DECIMAL(15,6), -- Contribution to objective function
    
    -- Alternative options
    alternative_assignments JSONB, -- Other possible assignments considered
    flexibility_score DECIMAL(3,2), -- How flexible this assignment is (0.0-1.0)
    substitution_options JSONB, -- Possible substitutions if needed
    
    -- Business impact
    productivity_score DECIMAL(5,4), -- Expected productivity impact
    cost_impact_rubles DECIMAL(10,2), -- Cost impact of this assignment
    quality_impact_score DECIMAL(3,2), -- Expected quality impact
    
    -- Implementation details
    implementation_priority INTEGER DEFAULT 1, -- Implementation order
    implementation_complexity VARCHAR(20), -- 'low', 'medium', 'high'
    change_from_current JSONB, -- What changes from current assignment
    approval_required BOOLEAN DEFAULT false,
    
    -- Validation
    actual_performance JSONB, -- Actual performance when implemented
    variance_from_expected DECIMAL(8,4), -- Variance from expected outcome
    implementation_success BOOLEAN, -- Was implementation successful?
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(execution_id, time_slot_start, entity_id, entity_type)
) PARTITION BY RANGE (time_slot_start);

-- Create monthly partitions for optimization solutions
CREATE TABLE optimization_solutions_2024_01 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE optimization_solutions_2024_02 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE optimization_solutions_2024_03 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE optimization_solutions_2024_04 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE optimization_solutions_2024_05 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE optimization_solutions_2024_06 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE optimization_solutions_2024_07 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE optimization_solutions_2024_08 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE optimization_solutions_2024_09 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE optimization_solutions_2024_10 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE optimization_solutions_2024_11 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE optimization_solutions_2024_12 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE optimization_solutions_2025_01 PARTITION OF optimization_solutions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Advanced Analytics and Insights
-- =====================================================================================

-- Predictive insights and pattern detection
CREATE TABLE predictive_insights (
    insight_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_type VARCHAR(50) NOT NULL, -- 'anomaly', 'trend', 'pattern', 'opportunity', 'risk'
    insight_category VARCHAR(50) NOT NULL, -- 'operational', 'strategic', 'tactical', 'compliance'
    
    -- Insight context
    entity_scope JSONB, -- What entities this insight applies to
    time_scope JSONB, -- Time period this insight covers
    business_domain VARCHAR(50), -- 'workforce', 'quality', 'efficiency', 'cost'
    
    -- Insight content
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    supporting_evidence JSONB, -- Data supporting this insight
    confidence_score DECIMAL(3,2), -- Confidence in this insight (0.0-1.0)
    
    -- Predictive elements
    forecast_horizon_days INTEGER, -- How far ahead this insight applies
    probability_score DECIMAL(3,2), -- Probability this will occur (0.0-1.0)
    impact_severity VARCHAR(20), -- 'low', 'medium', 'high', 'critical'
    
    -- Business impact
    estimated_impact_rubles DECIMAL(12,2), -- Financial impact estimate
    impact_type VARCHAR(30), -- 'cost_saving', 'revenue_increase', 'risk_mitigation'
    affected_kpis TEXT[], -- KPIs that will be affected
    
    -- Recommendations
    recommended_actions JSONB, -- Specific actions to take
    action_priority VARCHAR(20), -- 'low', 'medium', 'high', 'urgent'
    implementation_timeline VARCHAR(50), -- When to act
    
    -- Source information
    data_sources TEXT[], -- What data sources contributed
    analysis_method VARCHAR(50), -- How this insight was generated
    model_versions JSONB, -- Models that contributed to this insight
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'acted_upon', 'expired', 'invalid'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    
    -- Validation
    actual_outcome JSONB, -- What actually happened
    prediction_accuracy DECIMAL(3,2), -- How accurate was the prediction
    lessons_learned TEXT, -- Lessons for future insights
    
    -- Metadata
    tags TEXT[], -- Tags for categorization
    related_insights UUID[], -- Related insight IDs
    parent_insight_id UUID REFERENCES predictive_insights(insight_id)
);

-- Scenario analysis and what-if modeling
CREATE TABLE scenario_analyses (
    scenario_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_name VARCHAR(100) NOT NULL,
    scenario_type VARCHAR(50) NOT NULL, -- 'what_if', 'stress_test', 'sensitivity_analysis', 'monte_carlo'
    
    -- Scenario definition
    base_conditions JSONB NOT NULL, -- Baseline conditions
    variable_changes JSONB NOT NULL, -- What variables are changed
    assumption_changes JSONB, -- Changed assumptions
    
    -- Analysis scope
    analysis_scope JSONB, -- What entities/time periods to analyze
    time_horizon_days INTEGER DEFAULT 30, -- Analysis time horizon
    confidence_level DECIMAL(3,2) DEFAULT 0.95, -- Statistical confidence level
    
    -- Execution configuration
    simulation_runs INTEGER DEFAULT 1000, -- For Monte Carlo analysis
    convergence_criteria JSONB, -- When to stop simulation
    random_seed INTEGER, -- For reproducibility
    
    -- Results summary
    execution_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    execution_time_minutes INTEGER,
    convergence_achieved BOOLEAN,
    
    -- Outcome metrics
    outcome_metrics JSONB, -- Key metrics from analysis
    probability_distributions JSONB, -- Probability distributions of outcomes
    risk_metrics JSONB, -- Risk-related metrics (VaR, CVaR, etc.)
    
    -- Key findings
    key_insights TEXT[],
    risk_factors TEXT[],
    opportunities TEXT[],
    sensitivity_factors JSONB, -- Most sensitive variables
    
    -- Business recommendations
    strategic_recommendations TEXT[],
    tactical_recommendations TEXT[],
    contingency_plans JSONB, -- Plans for different scenarios
    
    -- Metadata
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    business_justification TEXT,
    stakeholders TEXT[], -- Who should review this analysis
    
    -- Validation
    validation_results JSONB, -- How well scenario matched reality
    model_performance JSONB -- Performance of models used
);

-- Performance Optimization and Indexes
-- =====================================================================================

-- Forecasting Models indexes
CREATE INDEX idx_forecasting_models_type ON forecasting_models(model_type);
CREATE INDEX idx_forecasting_models_status ON forecasting_models(status);
CREATE INDEX idx_forecasting_models_business_unit ON forecasting_models(business_unit);
CREATE INDEX idx_forecasting_models_target ON forecasting_models(forecast_target);

-- Forecast Executions indexes (on partitioned table)
CREATE INDEX idx_forecast_executions_model_id ON forecast_executions(model_id);
CREATE INDEX idx_forecast_executions_status ON forecast_executions(status);
CREATE INDEX idx_forecast_executions_timestamp ON forecast_executions(execution_timestamp);

-- Forecast Results indexes (on partitioned table)
CREATE INDEX idx_forecast_results_execution_id ON forecast_results(execution_id);
CREATE INDEX idx_forecast_results_model_id ON forecast_results(model_id);
CREATE INDEX idx_forecast_results_entity ON forecast_results(entity_id, entity_type);
CREATE INDEX idx_forecast_results_metric ON forecast_results(metric_name);
CREATE INDEX idx_forecast_results_horizon ON forecast_results(horizon_minutes);
CREATE INDEX idx_forecast_results_quality ON forecast_results(forecast_quality);

-- Optimization Problems indexes
CREATE INDEX idx_optimization_problems_type ON optimization_problems(problem_type);
CREATE INDEX idx_optimization_problems_status ON optimization_problems(status);
CREATE INDEX idx_optimization_problems_priority ON optimization_problems(business_priority);

-- Optimization Executions indexes (on partitioned table)
CREATE INDEX idx_optimization_executions_problem_id ON optimization_executions(problem_id);
CREATE INDEX idx_optimization_executions_status ON optimization_executions(status);
CREATE INDEX idx_optimization_executions_start_time ON optimization_executions(execution_start_time);

-- Optimization Solutions indexes (on partitioned table)
CREATE INDEX idx_optimization_solutions_execution_id ON optimization_solutions(execution_id);
CREATE INDEX idx_optimization_solutions_entity ON optimization_solutions(entity_id, entity_type);
CREATE INDEX idx_optimization_solutions_time_slot ON optimization_solutions(time_slot_start, time_slot_end);
CREATE INDEX idx_optimization_solutions_rank ON optimization_solutions(solution_rank);

-- Predictive Insights indexes
CREATE INDEX idx_predictive_insights_type ON predictive_insights(insight_type);
CREATE INDEX idx_predictive_insights_category ON predictive_insights(insight_category);
CREATE INDEX idx_predictive_insights_status ON predictive_insights(status);
CREATE INDEX idx_predictive_insights_created_at ON predictive_insights(created_at);
CREATE INDEX idx_predictive_insights_confidence ON predictive_insights(confidence_score);

-- Scenario Analyses indexes
CREATE INDEX idx_scenario_analyses_type ON scenario_analyses(scenario_type);
CREATE INDEX idx_scenario_analyses_status ON scenario_analyses(execution_status);
CREATE INDEX idx_scenario_analyses_created_at ON scenario_analyses(created_at);

-- Advanced Functions for Forecasting and Optimization
-- =====================================================================================

-- Function to execute a forecast
CREATE OR REPLACE FUNCTION execute_forecast(
    p_model_id UUID,
    p_forecast_start_time TIMESTAMP WITH TIME ZONE,
    p_forecast_end_time TIMESTAMP WITH TIME ZONE,
    p_execution_config JSONB DEFAULT NULL,
    p_triggered_by VARCHAR(100) DEFAULT 'system'
)
RETURNS UUID AS $$
DECLARE
    v_execution_id UUID;
    v_model_config JSONB;
    v_forecast_date DATE;
BEGIN
    -- Get model configuration
    SELECT model_config INTO v_model_config
    FROM forecasting_models
    WHERE model_id = p_model_id AND status = 'production';
    
    IF v_model_config IS NULL THEN
        RAISE EXCEPTION 'Model not found or not in production status';
    END IF;
    
    v_forecast_date := DATE(p_forecast_start_time);
    
    -- Create execution record
    INSERT INTO forecast_executions (
        model_id, forecast_date, forecast_start_time, forecast_end_time,
        execution_config, triggered_by, status
    ) VALUES (
        p_model_id, v_forecast_date, p_forecast_start_time, p_forecast_end_time,
        COALESCE(p_execution_config, v_model_config), p_triggered_by, 'running'
    ) RETURNING execution_id INTO v_execution_id;
    
    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

-- Function to store forecast results
CREATE OR REPLACE FUNCTION store_forecast_result(
    p_execution_id UUID,
    p_target_timestamp TIMESTAMP WITH TIME ZONE,
    p_entity_id VARCHAR(100),
    p_entity_type VARCHAR(50),
    p_metric_name VARCHAR(50),
    p_forecast_value DECIMAL(15,6),
    p_confidence_level DECIMAL(3,2),
    p_lower_bound DECIMAL(15,6),
    p_upper_bound DECIMAL(15,6),
    p_quality VARCHAR(20) DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    v_result_id UUID;
    v_model_id UUID;
    v_forecast_timestamp TIMESTAMP WITH TIME ZONE;
    v_horizon_minutes INTEGER;
BEGIN
    -- Get execution details
    SELECT model_id, execution_timestamp INTO v_model_id, v_forecast_timestamp
    FROM forecast_executions
    WHERE execution_id = p_execution_id;
    
    v_horizon_minutes := EXTRACT(EPOCH FROM (p_target_timestamp - v_forecast_timestamp))/60;
    
    INSERT INTO forecast_results (
        execution_id, model_id, forecast_timestamp, target_timestamp,
        horizon_minutes, entity_id, entity_type, metric_name,
        forecast_value, confidence_level, lower_bound, upper_bound, forecast_quality
    ) VALUES (
        p_execution_id, v_model_id, v_forecast_timestamp, p_target_timestamp,
        v_horizon_minutes, p_entity_id, p_entity_type, p_metric_name,
        p_forecast_value, p_confidence_level, p_lower_bound, p_upper_bound, p_quality
    ) RETURNING result_id INTO v_result_id;
    
    RETURN v_result_id;
END;
$$ LANGUAGE plpgsql;

-- Function to execute optimization
CREATE OR REPLACE FUNCTION execute_optimization(
    p_problem_id UUID,
    p_optimization_for_date DATE,
    p_algorithm_config JSONB DEFAULT NULL,
    p_triggered_by VARCHAR(100) DEFAULT 'system'
)
RETURNS UUID AS $$
DECLARE
    v_execution_id UUID;
    v_problem_config JSONB;
BEGIN
    -- Get problem configuration
    SELECT algorithm_config INTO v_problem_config
    FROM optimization_problems
    WHERE problem_id = p_problem_id AND status = 'active';
    
    IF v_problem_config IS NULL THEN
        RAISE EXCEPTION 'Optimization problem not found or not active';
    END IF;
    
    INSERT INTO optimization_executions (
        problem_id, optimization_for_date, algorithm_config_used,
        triggered_by, status
    ) VALUES (
        p_problem_id, p_optimization_for_date,
        COALESCE(p_algorithm_config, v_problem_config),
        p_triggered_by, 'queued'
    ) RETURNING execution_id INTO v_execution_id;
    
    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create predictive insight
CREATE OR REPLACE FUNCTION create_predictive_insight(
    p_insight_type VARCHAR(50),
    p_insight_category VARCHAR(50),
    p_title VARCHAR(200),
    p_description TEXT,
    p_confidence_score DECIMAL(3,2),
    p_entity_scope JSONB,
    p_supporting_evidence JSONB DEFAULT NULL,
    p_recommended_actions JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_insight_id UUID;
BEGIN
    INSERT INTO predictive_insights (
        insight_type, insight_category, title, description,
        confidence_score, entity_scope, supporting_evidence, recommended_actions
    ) VALUES (
        p_insight_type, p_insight_category, p_title, p_description,
        p_confidence_score, p_entity_scope, p_supporting_evidence, p_recommended_actions
    ) RETURNING insight_id INTO v_insight_id;
    
    RETURN v_insight_id;
END;
$$ LANGUAGE plpgsql;

-- Views for Analytics and Reporting
-- =====================================================================================

-- Forecast accuracy summary view
CREATE VIEW v_forecast_accuracy_summary AS
SELECT 
    fm.model_id,
    fm.model_name,
    fm.model_type,
    fm.forecast_target,
    fm.business_unit,
    
    -- Overall accuracy metrics
    COUNT(fr.result_id) as total_forecasts,
    COUNT(CASE WHEN fr.actual_value IS NOT NULL THEN 1 END) as validated_forecasts,
    AVG(fr.percentage_error) as avg_percentage_error,
    STDDEV(fr.percentage_error) as stddev_percentage_error,
    
    -- Accuracy by horizon
    AVG(CASE WHEN fr.horizon_minutes <= 60 THEN fr.percentage_error END) as accuracy_1h,
    AVG(CASE WHEN fr.horizon_minutes BETWEEN 61 AND 240 THEN fr.percentage_error END) as accuracy_4h,
    AVG(CASE WHEN fr.horizon_minutes BETWEEN 241 AND 1440 THEN fr.percentage_error END) as accuracy_1d,
    
    -- Confidence interval performance
    COUNT(CASE WHEN fr.within_confidence_interval = true THEN 1 END)::float / 
    COUNT(CASE WHEN fr.actual_value IS NOT NULL THEN 1 END) as ci_coverage_rate,
    
    -- Business value
    SUM(fr.business_value_rubles) as total_business_value,
    AVG(fr.business_value_rubles) as avg_business_value_per_forecast,
    
    -- Recent performance (last 7 days)
    AVG(CASE WHEN fr.created_at >= NOW() - INTERVAL '7 days' THEN fr.percentage_error END) as recent_accuracy,
    
    -- Last update
    MAX(fr.created_at) as last_forecast_date
    
FROM forecasting_models fm
LEFT JOIN forecast_results fr ON fm.model_id = fr.model_id
WHERE fm.status = 'production'
GROUP BY fm.model_id, fm.model_name, fm.model_type, fm.forecast_target, fm.business_unit
ORDER BY validated_forecasts DESC;

-- Optimization performance summary view
CREATE VIEW v_optimization_performance_summary AS
SELECT 
    op.problem_id,
    op.problem_name,
    op.problem_type,
    op.algorithm_type,
    op.business_priority,
    
    -- Execution statistics
    COUNT(oe.execution_id) as total_executions,
    COUNT(CASE WHEN oe.status = 'completed' THEN 1 END) as successful_executions,
    COUNT(CASE WHEN oe.status = 'failed' THEN 1 END) as failed_executions,
    
    -- Performance metrics
    AVG(oe.improvement_percentage) as avg_improvement,
    MAX(oe.improvement_percentage) as best_improvement,
    AVG(oe.objective_value_after - oe.objective_value_before) as avg_objective_improvement,
    
    -- Execution efficiency
    AVG(EXTRACT(EPOCH FROM (oe.execution_end_time - oe.execution_start_time))/60) as avg_execution_time_minutes,
    AVG(oe.constraint_violations) as avg_constraint_violations,
    
    -- Business value
    SUM(oe.estimated_cost_savings_rubles) as total_estimated_savings,
    AVG(oe.estimated_cost_savings_rubles) as avg_savings_per_execution,
    
    -- Solution quality
    COUNT(CASE WHEN oe.solution_feasibility = 'feasible' THEN 1 END)::float / 
    COUNT(CASE WHEN oe.status = 'completed' THEN 1 END) as feasibility_rate,
    
    COUNT(CASE WHEN oe.convergence_achieved = true THEN 1 END)::float / 
    COUNT(CASE WHEN oe.status = 'completed' THEN 1 END) as convergence_rate,
    
    -- Recent activity
    MAX(oe.execution_start_time) as last_execution_date,
    COUNT(CASE WHEN oe.execution_start_time >= NOW() - INTERVAL '7 days' THEN 1 END) as executions_last_7d
    
FROM optimization_problems op
LEFT JOIN optimization_executions oe ON op.problem_id = oe.problem_id
WHERE op.status = 'active'
GROUP BY op.problem_id, op.problem_name, op.problem_type, op.algorithm_type, op.business_priority
ORDER BY total_estimated_savings DESC;

-- Active insights dashboard view
CREATE VIEW v_active_insights_dashboard AS
SELECT 
    pi.insight_id,
    pi.insight_type,
    pi.insight_category,
    pi.title,
    pi.description,
    pi.confidence_score,
    pi.impact_severity,
    pi.estimated_impact_rubles,
    pi.action_priority,
    pi.implementation_timeline,
    pi.recommended_actions,
    
    -- Time context
    pi.created_at,
    pi.expires_at,
    EXTRACT(EPOCH FROM (pi.expires_at - NOW()))/3600 as hours_until_expiration,
    
    -- Priority scoring
    CASE pi.impact_severity
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
    END * pi.confidence_score * COALESCE(pi.estimated_impact_rubles/10000, 1) as priority_score,
    
    -- Categorization
    CASE 
        WHEN pi.insight_type IN ('anomaly', 'risk') THEN 'Alert'
        WHEN pi.insight_type IN ('opportunity', 'optimization') THEN 'Opportunity'
        WHEN pi.insight_type IN ('trend', 'pattern') THEN 'Intelligence'
        ELSE 'Information'
    END as insight_nature
    
FROM predictive_insights pi
WHERE pi.status = 'active'
    AND (pi.expires_at IS NULL OR pi.expires_at > NOW())
ORDER BY priority_score DESC, pi.created_at DESC;

-- Demo Data for Predictive Analytics
-- =====================================================================================

-- Insert sample forecasting models
INSERT INTO forecasting_models (model_name, model_type, forecast_target, model_config, business_unit, status, created_by, current_mape, min_horizon_minutes, max_horizon_minutes) VALUES
('deep_demand_predictor', 'lstm', 'call_volume', '{"layers": 3, "neurons": 128, "lookback_hours": 168, "features": ["temporal", "seasonal", "external"]}', 'customer_service', 'production', 'data_scientist_team', 0.087, 15, 10080),
('ensemble_aht_forecaster', 'ensemble', 'aht', '{"models": ["arima", "lstm", "xgboost"], "weights": [0.3, 0.4, 0.3], "confidence_method": "quantile"}', 'customer_service', 'production', 'ml_engineering', 0.124, 30, 4320),
('occupancy_trend_analyzer', 'sarima', 'occupancy', '{"seasonal_periods": [24, 168], "trend_order": 2, "seasonal_order": 1, "confidence_intervals": true}', 'operations', 'production', 'analytics_team', 0.095, 60, 2160);

-- Insert sample optimization problems
INSERT INTO optimization_problems (problem_name, problem_type, objective_function, constraints, decision_variables, algorithm_type, algorithm_config, target_improvement_percentage, created_by) VALUES
('daily_schedule_optimization', 'schedule_optimization', '{"maximize": "service_level", "minimize": "cost", "weights": {"service_level": 0.7, "cost": 0.3}}', '{"min_staffing": "coverage_requirements", "max_overtime": 0.1, "skill_matching": true, "break_rules": "labor_law_compliance"}', '{"agent_assignments": "binary", "shift_times": "continuous", "skill_allocations": "integer"}', 'genetic', '{"population_size": 200, "generations": 100, "mutation_rate": 0.05, "crossover_rate": 0.8}', 15.0, 'optimization_team'),
('resource_allocation_optimizer', 'resource_allocation', '{"minimize": "total_cost", "constraints_penalty": 1000}', '{"capacity_limits": "agent_availability", "skill_requirements": "queue_needs", "quality_targets": "sla_compliance"}', '{"resource_amounts": "continuous", "allocation_matrix": "binary"}', 'linear_programming', '{"solver": "gurobi", "time_limit": 3600, "gap_tolerance": 0.01}', 12.0, 'operations_research');

-- Insert sample forecast executions
INSERT INTO forecast_executions (model_id, forecast_date, forecast_start_time, forecast_end_time, status, total_forecast_points, forecast_trend, triggered_by) VALUES
((SELECT model_id FROM forecasting_models WHERE model_name = 'deep_demand_predictor'), CURRENT_DATE, NOW(), NOW() + INTERVAL '24 hours', 'completed', 96, 'increasing', 'scheduler'),
((SELECT model_id FROM forecasting_models WHERE model_name = 'ensemble_aht_forecaster'), CURRENT_DATE, NOW(), NOW() + INTERVAL '12 hours', 'completed', 24, 'stable', 'real_time_monitor');

-- Insert sample forecast results
INSERT INTO forecast_results (execution_id, target_timestamp, entity_id, entity_type, metric_name, forecast_value, confidence_level, lower_bound, upper_bound, forecast_quality, horizon_minutes) VALUES
((SELECT execution_id FROM forecast_executions ORDER BY created_at DESC LIMIT 1), NOW() + INTERVAL '1 hour', 'queue_customer_service', 'queue', 'call_volume', 145.5, 0.95, 132.1, 158.9, 'high', 60),
((SELECT execution_id FROM forecast_executions ORDER BY created_at DESC LIMIT 1), NOW() + INTERVAL '2 hours', 'queue_customer_service', 'queue', 'call_volume', 167.2, 0.95, 151.8, 182.6, 'high', 120),
((SELECT execution_id FROM forecast_executions ORDER BY created_at DESC LIMIT 1), NOW() + INTERVAL '4 hours', 'queue_customer_service', 'queue', 'call_volume', 189.7, 0.95, 169.3, 210.1, 'medium', 240);

-- Insert sample optimization executions
INSERT INTO optimization_executions (problem_id, optimization_for_date, status, objective_value_before, objective_value_after, improvement_percentage, estimated_cost_savings_rubles, triggered_by) VALUES
((SELECT problem_id FROM optimization_problems WHERE problem_name = 'daily_schedule_optimization'), CURRENT_DATE + 1, 'completed', 0.847, 0.923, 8.97, 45000, 'daily_scheduler'),
((SELECT problem_id FROM optimization_problems WHERE problem_name = 'resource_allocation_optimizer'), CURRENT_DATE, 'completed', 145600, 132400, 9.07, 13200, 'resource_manager');

-- Insert sample predictive insights
INSERT INTO predictive_insights (insight_type, insight_category, title, description, confidence_score, entity_scope, supporting_evidence, recommended_actions, impact_severity, estimated_impact_rubles) VALUES
('opportunity', 'operational', 'Optimize lunch break scheduling for 15% efficiency gain', 'Analysis shows current lunch break distribution creates unnecessary coverage gaps. Staggered scheduling could improve service levels.', 0.82, '{"queues": ["customer_service", "technical_support"], "time_range": "11:30-14:30"}', '{"current_service_level": 0.847, "simulated_improvement": 0.127, "coverage_analysis": "detailed_breakdown"}', '{"primary": "implement_staggered_breaks", "timeline": "next_week", "pilot_duration": "2_weeks"}', 'medium', 78000),
('risk', 'strategic', 'Predicted agent shortage in Q2 due to seasonal hiring lag', 'Historical patterns and current hiring pipeline indicate 12-15% agent shortage during Q2 peak season.', 0.89, '{"departments": ["all"], "time_range": "Q2_2024", "severity": "high"}', '{"historical_patterns": "5_year_trend", "hiring_pipeline": "current_status", "demand_forecast": "seasonal_model"}', '{"immediate": "accelerate_hiring", "contingency": "contractor_agreements", "long_term": "seasonal_workforce_plan"}', 'high', 450000);

-- Insert sample scenario analysis
INSERT INTO scenario_analyses (scenario_name, scenario_type, base_conditions, variable_changes, outcome_metrics, key_insights, created_by) VALUES
('peak_season_staffing_scenarios', 'what_if', '{"current_staff": 120, "current_service_level": 0.85, "peak_multiplier": 1.4}', '{"staffing_levels": [130, 140, 150, 160], "overtime_rates": [0.05, 0.1, 0.15]}', '{"service_levels": [0.87, 0.91, 0.94, 0.97], "total_costs": [2400000, 2650000, 2890000, 3150000]}', '["sweet_spot_at_150_agents", "diminishing_returns_above_95_percent", "overtime_more_cost_effective_than_hiring"]', 'workforce_planning_team');

-- Comments for Documentation
-- =====================================================================================

COMMENT ON TABLE forecasting_models IS 'Advanced forecasting model configurations with multi-horizon capabilities';
COMMENT ON TABLE forecast_executions IS 'Forecast execution history with performance tracking (partitioned by date)';
COMMENT ON TABLE forecast_results IS 'Detailed forecast results with confidence intervals (partitioned by target time)';
COMMENT ON TABLE optimization_problems IS 'Optimization problem definitions with constraints and objectives';
COMMENT ON TABLE optimization_executions IS 'Optimization execution history with performance metrics (partitioned by date)';
COMMENT ON TABLE optimization_solutions IS 'Detailed optimization solutions and assignments (partitioned by time)';
COMMENT ON TABLE predictive_insights IS 'AI-generated insights with business recommendations';
COMMENT ON TABLE scenario_analyses IS 'What-if scenario modeling and analysis results';

COMMENT ON COLUMN forecast_results.confidence_level IS 'Statistical confidence level for bounds (e.g., 0.95 for 95% CI)';
COMMENT ON COLUMN forecast_results.forecast_distribution IS 'Full probability distribution for advanced uncertainty quantification';
COMMENT ON COLUMN optimization_solutions.flexibility_score IS 'How adaptable this solution is to changes (0.0-1.0)';
COMMENT ON COLUMN predictive_insights.probability_score IS 'Probability this predicted event will occur (0.0-1.0)';
COMMENT ON COLUMN scenario_analyses.probability_distributions IS 'Monte Carlo simulation probability distributions';

-- Schema completion marker
INSERT INTO schema_migrations (schema_name, version, description, applied_at) 
VALUES ('122_predictive_forecasting_optimization_engine', '1.0.0', 'Advanced predictive analytics and optimization platform', NOW());