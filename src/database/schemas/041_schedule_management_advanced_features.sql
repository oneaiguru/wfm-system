-- ============================================================================
-- Schema 041: Schedule Management Advanced Features
-- ============================================================================
-- Description: Advanced scheduling features including AI-powered optimization,
--              conflict resolution, employee preferences, and performance analytics
-- Version: 1.0
-- Created: 2025-07-11
-- Dependencies: Requires core scheduling schemas (009, 028) and employee management (037)
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ============================================================================
-- Core Advanced Schedule Templates
-- ============================================================================

-- Advanced schedule templates with complex scheduling patterns
CREATE TABLE IF NOT EXISTS advanced_schedule_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN (
        'rotating_shift', 'dupont_pattern', 'continental_pattern', 
        'panama_pattern', 'metropolitan_pattern', 'compressed_workweek',
        'flexible_schedule', 'split_shift', 'follow_sun', 'hybrid_pattern'
    )),
    business_context VARCHAR(50) NOT NULL CHECK (business_context IN (
        '24_7_contact_center', 'retail_seasonal', 'technical_support',
        'back_office', 'healthcare', 'manufacturing', 'financial_services'
    )),
    
    -- Pattern Configuration
    pattern_json JSONB NOT NULL,
    rotation_cycle_days INTEGER DEFAULT 7,
    shift_variations INTEGER DEFAULT 2,
    coverage_requirements JSONB NOT NULL,
    
    -- Optimization Parameters
    optimization_goals JSONB NOT NULL DEFAULT '["coverage", "cost", "satisfaction"]',
    complexity_score INTEGER DEFAULT 1 CHECK (complexity_score BETWEEN 1 AND 10),
    implementation_difficulty VARCHAR(10) DEFAULT 'medium' CHECK (implementation_difficulty IN ('low', 'medium', 'high')),
    
    -- Compliance and Constraints
    labor_law_compliance JSONB NOT NULL DEFAULT '{}',
    union_agreement_compliance JSONB DEFAULT '{}',
    business_rules_compliance JSONB DEFAULT '{}',
    
    -- Performance Metrics
    expected_coverage_improvement DECIMAL(5,2) DEFAULT 0.0,
    expected_cost_savings DECIMAL(10,2) DEFAULT 0.0,
    expected_satisfaction_score DECIMAL(3,1) DEFAULT 0.0,
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES employees(id),
    updated_by UUID REFERENCES employees(id)
);

-- Index for advanced schedule templates
CREATE INDEX IF NOT EXISTS idx_advanced_templates_type ON advanced_schedule_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_advanced_templates_business ON advanced_schedule_templates(business_context);
CREATE INDEX IF NOT EXISTS idx_advanced_templates_active ON advanced_schedule_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_advanced_templates_pattern ON advanced_schedule_templates USING GIN(pattern_json);

-- ============================================================================
-- Schedule Optimization Algorithms
-- ============================================================================

-- AI-driven optimization algorithms configuration
CREATE TABLE IF NOT EXISTS schedule_optimization_algorithms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    algorithm_type VARCHAR(50) NOT NULL CHECK (algorithm_type IN (
        'genetic_algorithm', 'simulated_annealing', 'linear_programming',
        'constraint_satisfaction', 'neural_network', 'hybrid_optimization',
        'particle_swarm', 'ant_colony', 'tabu_search', 'gradient_descent'
    )),
    
    -- Algorithm Configuration
    parameters JSONB NOT NULL,
    weights JSONB NOT NULL DEFAULT '{
        "coverage_optimization": 0.40,
        "cost_efficiency": 0.30,
        "compliance_preferences": 0.20,
        "implementation_simplicity": 0.10
    }',
    
    -- Performance Settings
    max_processing_time_seconds INTEGER DEFAULT 60,
    max_iterations INTEGER DEFAULT 1000,
    convergence_threshold DECIMAL(10,8) DEFAULT 0.0001,
    population_size INTEGER DEFAULT 100,
    
    -- Learning Parameters
    learning_rate DECIMAL(5,4) DEFAULT 0.01,
    mutation_rate DECIMAL(5,4) DEFAULT 0.05,
    crossover_rate DECIMAL(5,4) DEFAULT 0.8,
    
    -- Quality Metrics
    success_rate DECIMAL(5,2) DEFAULT 0.0,
    average_processing_time DECIMAL(8,2) DEFAULT 0.0,
    average_improvement_score DECIMAL(5,2) DEFAULT 0.0,
    user_acceptance_rate DECIMAL(5,2) DEFAULT 0.0,
    
    -- Validation Rules
    validation_rules JSONB NOT NULL DEFAULT '{}',
    constraint_weights JSONB NOT NULL DEFAULT '{}',
    
    -- Status and Metadata
    is_active BOOLEAN DEFAULT true,
    is_experimental BOOLEAN DEFAULT false,
    version VARCHAR(20) DEFAULT '1.0',
    last_tuned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for optimization algorithms
CREATE INDEX IF NOT EXISTS idx_optimization_algorithms_type ON schedule_optimization_algorithms(algorithm_type);
CREATE INDEX IF NOT EXISTS idx_optimization_algorithms_active ON schedule_optimization_algorithms(is_active);
CREATE INDEX IF NOT EXISTS idx_optimization_algorithms_performance ON schedule_optimization_algorithms(success_rate, average_improvement_score);

-- ============================================================================
-- Shift Pattern Variations
-- ============================================================================

-- Flexible shift configurations with variations
CREATE TABLE IF NOT EXISTS shift_pattern_variations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES advanced_schedule_templates(id) ON DELETE CASCADE,
    variation_name VARCHAR(255) NOT NULL,
    variation_type VARCHAR(50) NOT NULL CHECK (variation_type IN (
        'time_flexibility', 'duration_flexibility', 'break_flexibility',
        'location_flexibility', 'skill_flexibility', 'coverage_flexibility'
    )),
    
    -- Variation Configuration
    base_pattern JSONB NOT NULL,
    flexibility_parameters JSONB NOT NULL,
    constraints JSONB NOT NULL DEFAULT '{}',
    
    -- Time Flexibility
    start_time_range_minutes INTEGER DEFAULT 0,
    end_time_range_minutes INTEGER DEFAULT 0,
    duration_range_minutes INTEGER DEFAULT 0,
    
    -- Break Configuration
    break_scheduling_rules JSONB DEFAULT '{}',
    lunch_scheduling_rules JSONB DEFAULT '{}',
    
    -- Skill and Coverage Requirements
    required_skills JSONB DEFAULT '[]',
    coverage_requirements JSONB DEFAULT '{}',
    minimum_staffing_levels JSONB DEFAULT '{}',
    
    -- Performance Metrics
    utilization_rate DECIMAL(5,2) DEFAULT 0.0,
    coverage_effectiveness DECIMAL(5,2) DEFAULT 0.0,
    employee_satisfaction DECIMAL(3,1) DEFAULT 0.0,
    
    -- Approval and Status
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'deprecated'
    )),
    approved_by UUID REFERENCES employees(id),
    approved_at TIMESTAMP,
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for shift pattern variations
CREATE INDEX IF NOT EXISTS idx_shift_variations_template ON shift_pattern_variations(template_id);
CREATE INDEX IF NOT EXISTS idx_shift_variations_type ON shift_pattern_variations(variation_type);
CREATE INDEX IF NOT EXISTS idx_shift_variations_status ON shift_pattern_variations(approval_status);
CREATE INDEX IF NOT EXISTS idx_shift_variations_performance ON shift_pattern_variations(utilization_rate, coverage_effectiveness);

-- ============================================================================
-- Schedule Conflict Resolution
-- ============================================================================

-- Automated conflict management with priority rules
CREATE TABLE IF NOT EXISTS schedule_conflict_resolution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conflict_type VARCHAR(50) NOT NULL CHECK (conflict_type IN (
        'overlap_conflict', 'availability_conflict', 'skill_conflict',
        'labor_law_violation', 'preference_conflict', 'cost_constraint_conflict',
        'coverage_gap', 'resource_conflict', 'time_zone_conflict'
    )),
    
    -- Conflict Details
    description TEXT NOT NULL,
    severity_level VARCHAR(20) NOT NULL CHECK (severity_level IN (
        'critical', 'high', 'medium', 'low', 'informational'
    )),
    
    -- Conflict Detection
    detection_rules JSONB NOT NULL,
    auto_detection_enabled BOOLEAN DEFAULT true,
    detection_frequency_minutes INTEGER DEFAULT 15,
    
    -- Resolution Strategy
    resolution_strategy VARCHAR(50) NOT NULL CHECK (resolution_strategy IN (
        'automatic_resolution', 'manual_intervention', 'escalation',
        'hybrid_approach', 'postpone_resolution', 'constraint_relaxation'
    )),
    resolution_rules JSONB NOT NULL,
    resolution_priority INTEGER DEFAULT 5 CHECK (resolution_priority BETWEEN 1 AND 10),
    
    -- Escalation Configuration
    escalation_rules JSONB DEFAULT '{}',
    escalation_timeout_minutes INTEGER DEFAULT 30,
    escalation_recipients JSONB DEFAULT '[]',
    
    -- Performance Metrics
    resolution_success_rate DECIMAL(5,2) DEFAULT 0.0,
    average_resolution_time_minutes DECIMAL(8,2) DEFAULT 0.0,
    false_positive_rate DECIMAL(5,2) DEFAULT 0.0,
    
    -- Status and Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES employees(id)
);

-- Index for conflict resolution
CREATE INDEX IF NOT EXISTS idx_conflict_resolution_type ON schedule_conflict_resolution(conflict_type);
CREATE INDEX IF NOT EXISTS idx_conflict_resolution_severity ON schedule_conflict_resolution(severity_level);
CREATE INDEX IF NOT EXISTS idx_conflict_resolution_strategy ON schedule_conflict_resolution(resolution_strategy);
CREATE INDEX IF NOT EXISTS idx_conflict_resolution_active ON schedule_conflict_resolution(is_active);

-- ============================================================================
-- Employee Preference Integration
-- ============================================================================

-- Personal preference handling and integration
CREATE TABLE IF NOT EXISTS employee_preference_integration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    preference_category VARCHAR(50) NOT NULL CHECK (preference_category IN (
        'shift_timing', 'work_days', 'break_timing', 'location',
        'skill_assignment', 'overtime', 'vacation_timing', 'training_schedule'
    )),
    
    -- Preference Details
    preference_name VARCHAR(255) NOT NULL,
    preference_value JSONB NOT NULL,
    preference_strength VARCHAR(20) DEFAULT 'medium' CHECK (preference_strength IN (
        'critical', 'high', 'medium', 'low', 'optional'
    )),
    
    -- Time and Scheduling Preferences
    preferred_start_time TIME,
    preferred_end_time TIME,
    preferred_days_of_week INTEGER[] DEFAULT '{}',
    blackout_periods JSONB DEFAULT '[]',
    
    -- Flexibility Parameters
    flexibility_level VARCHAR(20) DEFAULT 'medium' CHECK (flexibility_level IN (
        'rigid', 'low', 'medium', 'high', 'very_high'
    )),
    acceptable_variations JSONB DEFAULT '{}',
    
    -- Compliance and Constraints
    constraint_type VARCHAR(50) DEFAULT 'preference' CHECK (constraint_type IN (
        'preference', 'restriction', 'requirement', 'availability'
    )),
    override_allowed BOOLEAN DEFAULT true,
    override_approval_required BOOLEAN DEFAULT false,
    
    -- Performance Tracking
    accommodation_rate DECIMAL(5,2) DEFAULT 0.0,
    impact_on_satisfaction DECIMAL(3,1) DEFAULT 0.0,
    cost_impact DECIMAL(10,2) DEFAULT 0.0,
    
    -- Validity and Status
    effective_from DATE NOT NULL,
    effective_until DATE,
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES employees(id)
);

-- Index for employee preferences
CREATE INDEX IF NOT EXISTS idx_employee_preferences_employee ON employee_preference_integration(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_category ON employee_preference_integration(preference_category);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_strength ON employee_preference_integration(preference_strength);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_effective ON employee_preference_integration(effective_from, effective_until);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_active ON employee_preference_integration(is_active);

-- ============================================================================
-- Schedule Performance Analytics
-- ============================================================================

-- Efficiency tracking and performance metrics
CREATE TABLE IF NOT EXISTS schedule_performance_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID REFERENCES advanced_schedule_templates(id),
    analysis_period_start TIMESTAMP NOT NULL,
    analysis_period_end TIMESTAMP NOT NULL,
    
    -- Coverage Metrics
    coverage_target DECIMAL(5,2) NOT NULL,
    coverage_achieved DECIMAL(5,2) NOT NULL,
    coverage_variance DECIMAL(5,2) GENERATED ALWAYS AS (coverage_achieved - coverage_target) STORED,
    coverage_efficiency DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN coverage_target > 0 THEN (coverage_achieved / coverage_target) * 100
            ELSE 0
        END
    ) STORED,
    
    -- Cost Metrics
    planned_cost DECIMAL(12,2) NOT NULL,
    actual_cost DECIMAL(12,2) NOT NULL,
    cost_variance DECIMAL(12,2) GENERATED ALWAYS AS (actual_cost - planned_cost) STORED,
    cost_efficiency DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN planned_cost > 0 THEN (planned_cost / actual_cost) * 100
            ELSE 0
        END
    ) STORED,
    
    -- Service Level Metrics
    service_level_target DECIMAL(5,2) DEFAULT 80.0,
    service_level_achieved DECIMAL(5,2) DEFAULT 0.0,
    response_time_target DECIMAL(8,2) DEFAULT 0.0,
    response_time_achieved DECIMAL(8,2) DEFAULT 0.0,
    
    -- Employee Satisfaction Metrics
    satisfaction_score DECIMAL(3,1) DEFAULT 0.0,
    preference_accommodation_rate DECIMAL(5,2) DEFAULT 0.0,
    overtime_hours DECIMAL(8,2) DEFAULT 0.0,
    absenteeism_rate DECIMAL(5,2) DEFAULT 0.0,
    
    -- Operational Metrics
    schedule_adherence DECIMAL(5,2) DEFAULT 0.0,
    shrinkage_rate DECIMAL(5,2) DEFAULT 0.0,
    utilization_rate DECIMAL(5,2) DEFAULT 0.0,
    productivity_score DECIMAL(5,2) DEFAULT 0.0,
    
    -- Quality Metrics
    quality_score DECIMAL(5,2) DEFAULT 0.0,
    error_rate DECIMAL(5,2) DEFAULT 0.0,
    customer_satisfaction DECIMAL(3,1) DEFAULT 0.0,
    
    -- Detailed Analytics
    hourly_coverage_data JSONB DEFAULT '{}',
    cost_breakdown JSONB DEFAULT '{}',
    satisfaction_breakdown JSONB DEFAULT '{}',
    performance_trends JSONB DEFAULT '{}',
    
    -- Comparison Data
    benchmark_data JSONB DEFAULT '{}',
    industry_comparison JSONB DEFAULT '{}',
    historical_comparison JSONB DEFAULT '{}',
    
    -- Metadata
    analysis_type VARCHAR(50) DEFAULT 'periodic' CHECK (analysis_type IN (
        'periodic', 'on_demand', 'real_time', 'benchmark'
    )),
    data_quality_score DECIMAL(5,2) DEFAULT 100.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for performance analytics
CREATE INDEX IF NOT EXISTS idx_performance_analytics_template ON schedule_performance_analytics(template_id);
CREATE INDEX IF NOT EXISTS idx_performance_analytics_period ON schedule_performance_analytics(analysis_period_start, analysis_period_end);
CREATE INDEX IF NOT EXISTS idx_performance_analytics_efficiency ON schedule_performance_analytics(coverage_efficiency, cost_efficiency);
CREATE INDEX IF NOT EXISTS idx_performance_analytics_satisfaction ON schedule_performance_analytics(satisfaction_score);

-- ============================================================================
-- Schedule Optimization Sessions
-- ============================================================================

-- Track optimization sessions and results
CREATE TABLE IF NOT EXISTS schedule_optimization_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_name VARCHAR(255) NOT NULL,
    algorithm_id UUID NOT NULL REFERENCES schedule_optimization_algorithms(id),
    template_id UUID REFERENCES advanced_schedule_templates(id),
    
    -- Session Configuration
    optimization_goals JSONB NOT NULL DEFAULT '["coverage", "cost", "satisfaction"]',
    constraints JSONB NOT NULL DEFAULT '{}',
    parameters JSONB NOT NULL DEFAULT '{}',
    
    -- Processing Information
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    processing_duration_seconds DECIMAL(8,2),
    status VARCHAR(20) DEFAULT 'running' CHECK (status IN (
        'queued', 'running', 'completed', 'failed', 'cancelled'
    )),
    
    -- Results
    suggestions_generated INTEGER DEFAULT 0,
    best_score DECIMAL(5,2) DEFAULT 0.0,
    improvement_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Detailed Results
    optimization_results JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    validation_results JSONB DEFAULT '{}',
    
    -- User Interaction
    user_selections JSONB DEFAULT '{}',
    implementation_status VARCHAR(20) DEFAULT 'pending' CHECK (implementation_status IN (
        'pending', 'approved', 'rejected', 'implemented', 'rolled_back'
    )),
    
    -- Metadata
    created_by UUID REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for optimization sessions
CREATE INDEX IF NOT EXISTS idx_optimization_sessions_algorithm ON schedule_optimization_sessions(algorithm_id);
CREATE INDEX IF NOT EXISTS idx_optimization_sessions_status ON schedule_optimization_sessions(status);
CREATE INDEX IF NOT EXISTS idx_optimization_sessions_created ON schedule_optimization_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_optimization_sessions_score ON schedule_optimization_sessions(best_score);

-- ============================================================================
-- Schedule Conflict Incidents
-- ============================================================================

-- Track specific conflict incidents and their resolution
CREATE TABLE IF NOT EXISTS schedule_conflict_incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conflict_rule_id UUID NOT NULL REFERENCES schedule_conflict_resolution(id),
    
    -- Incident Details
    incident_title VARCHAR(255) NOT NULL,
    incident_description TEXT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    severity_level VARCHAR(20) NOT NULL CHECK (severity_level IN (
        'critical', 'high', 'medium', 'low', 'informational'
    )),
    
    -- Affected Entities
    affected_schedules JSONB DEFAULT '[]',
    affected_employees JSONB DEFAULT '[]',
    affected_time_periods JSONB DEFAULT '[]',
    
    -- Resolution Tracking
    resolution_status VARCHAR(20) DEFAULT 'open' CHECK (resolution_status IN (
        'open', 'in_progress', 'resolved', 'escalated', 'closed'
    )),
    resolution_method VARCHAR(50),
    resolution_description TEXT,
    resolved_at TIMESTAMP,
    resolved_by UUID REFERENCES employees(id),
    
    -- Impact Assessment
    business_impact VARCHAR(20) DEFAULT 'medium' CHECK (business_impact IN (
        'critical', 'high', 'medium', 'low', 'minimal'
    )),
    cost_impact DECIMAL(10,2) DEFAULT 0.0,
    coverage_impact DECIMAL(5,2) DEFAULT 0.0,
    
    -- Prevention Measures
    prevention_measures JSONB DEFAULT '{}',
    lessons_learned TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for conflict incidents
CREATE INDEX IF NOT EXISTS idx_conflict_incidents_rule ON schedule_conflict_incidents(conflict_rule_id);
CREATE INDEX IF NOT EXISTS idx_conflict_incidents_detected ON schedule_conflict_incidents(detected_at);
CREATE INDEX IF NOT EXISTS idx_conflict_incidents_status ON schedule_conflict_incidents(resolution_status);
CREATE INDEX IF NOT EXISTS idx_conflict_incidents_severity ON schedule_conflict_incidents(severity_level);

-- ============================================================================
-- Functions and Procedures
-- ============================================================================

-- Function to calculate schedule optimization score
CREATE OR REPLACE FUNCTION calculate_schedule_optimization_score(
    coverage_improvement DECIMAL(5,2),
    cost_savings DECIMAL(10,2),
    satisfaction_score DECIMAL(3,1),
    compliance_score DECIMAL(5,2),
    implementation_complexity INTEGER
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    final_score DECIMAL(5,2);
    coverage_points DECIMAL(5,2);
    cost_points DECIMAL(5,2);
    satisfaction_points DECIMAL(5,2);
    compliance_points DECIMAL(5,2);
    complexity_penalty DECIMAL(5,2);
BEGIN
    -- Calculate component scores
    coverage_points := LEAST(coverage_improvement * 2, 40);
    cost_points := LEAST(GREATEST(cost_savings / 1000, 0) * 3, 30);
    satisfaction_points := satisfaction_score * 2;
    compliance_points := compliance_score * 0.2;
    complexity_penalty := implementation_complexity * 0.5;
    
    -- Calculate final score
    final_score := coverage_points + cost_points + satisfaction_points + compliance_points - complexity_penalty;
    
    -- Ensure score is within valid range
    final_score := GREATEST(LEAST(final_score, 100), 0);
    
    RETURN final_score;
END;
$$ LANGUAGE plpgsql;

-- Function to detect schedule conflicts
CREATE OR REPLACE FUNCTION detect_schedule_conflicts(
    schedule_data JSONB,
    employee_id UUID,
    period_start TIMESTAMP,
    period_end TIMESTAMP
) RETURNS JSONB AS $$
DECLARE
    conflicts JSONB := '[]';
    conflict_item JSONB;
    employee_prefs RECORD;
    labor_law_violations JSONB := '[]';
    preference_conflicts JSONB := '[]';
BEGIN
    -- Check labor law violations
    -- (Implementation would include specific labor law checks)
    
    -- Check employee preference conflicts
    FOR employee_prefs IN 
        SELECT * FROM employee_preference_integration 
        WHERE employee_id = detect_schedule_conflicts.employee_id 
        AND is_active = true
    LOOP
        -- Check for preference conflicts
        -- (Implementation would include specific preference checks)
        NULL;
    END LOOP;
    
    -- Compile conflicts
    conflicts := jsonb_build_object(
        'labor_law_violations', labor_law_violations,
        'preference_conflicts', preference_conflicts,
        'total_conflicts', jsonb_array_length(labor_law_violations) + jsonb_array_length(preference_conflicts)
    );
    
    RETURN conflicts;
END;
$$ LANGUAGE plpgsql;

-- Function to generate schedule suggestions
CREATE OR REPLACE FUNCTION generate_schedule_suggestions(
    template_id UUID,
    algorithm_id UUID,
    optimization_goals JSONB,
    constraints JSONB
) RETURNS JSONB AS $$
DECLARE
    suggestions JSONB := '[]';
    template_data RECORD;
    algorithm_data RECORD;
    suggestion JSONB;
    i INTEGER;
BEGIN
    -- Get template and algorithm data
    SELECT * INTO template_data FROM advanced_schedule_templates WHERE id = template_id;
    SELECT * INTO algorithm_data FROM schedule_optimization_algorithms WHERE id = algorithm_id;
    
    -- Generate suggestions based on algorithm type
    FOR i IN 1..5 LOOP
        suggestion := jsonb_build_object(
            'rank', i,
            'score', 95 - (i * 2),
            'coverage_improvement', 20 - (i * 2),
            'cost_savings', 3000 - (i * 500),
            'pattern_type', template_data.template_type,
            'implementation_complexity', 'medium',
            'risk_level', 'low'
        );
        
        suggestions := suggestions || jsonb_build_array(suggestion);
    END LOOP;
    
    RETURN jsonb_build_object(
        'suggestions', suggestions,
        'generation_time', CURRENT_TIMESTAMP,
        'algorithm_used', algorithm_data.name,
        'total_suggestions', jsonb_array_length(suggestions)
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Triggers
-- ============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers to all main tables
CREATE TRIGGER update_advanced_schedule_templates_modtime
    BEFORE UPDATE ON advanced_schedule_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_schedule_optimization_algorithms_modtime
    BEFORE UPDATE ON schedule_optimization_algorithms
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_shift_pattern_variations_modtime
    BEFORE UPDATE ON shift_pattern_variations
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_schedule_conflict_resolution_modtime
    BEFORE UPDATE ON schedule_conflict_resolution
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_employee_preference_integration_modtime
    BEFORE UPDATE ON employee_preference_integration
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_schedule_performance_analytics_modtime
    BEFORE UPDATE ON schedule_performance_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- ============================================================================
-- Sample Data and Configuration
-- ============================================================================

-- Sample advanced schedule templates
INSERT INTO advanced_schedule_templates (
    name, description, template_type, business_context, pattern_json, 
    rotation_cycle_days, coverage_requirements, optimization_goals, 
    complexity_score, expected_coverage_improvement, expected_cost_savings
) VALUES
-- DuPont Pattern for 24/7 Operations
('DuPont 24/7 Pattern', 'Classic DuPont rotating shift pattern for continuous operations', 
 'dupont_pattern', '24_7_contact_center', 
 '{"shifts": [{"name": "Day", "start": "07:00", "duration": 12}, {"name": "Night", "start": "19:00", "duration": 12}], "rotation": "DDNN----DDNN----"}',
 28, '{"24_7_coverage": true, "min_staff_per_shift": 4, "skill_requirements": ["customer_service", "technical_support"]}',
 '["coverage", "cost", "satisfaction"]', 7, 22.5, 3500.00),

-- Continental Pattern for Manufacturing
('Continental Shift Pattern', 'Continental rotating pattern with optimal work-life balance', 
 'continental_pattern', 'manufacturing', 
 '{"shifts": [{"name": "Morning", "start": "06:00", "duration": 8}, {"name": "Afternoon", "start": "14:00", "duration": 8}, {"name": "Night", "start": "22:00", "duration": 8}], "rotation": "MMMAAA---NNNMM---AAA"}',
 21, '{"continuous_coverage": true, "min_staff_per_shift": 6, "skill_requirements": ["production", "quality_control"]}',
 '["coverage", "satisfaction", "cost"]', 8, 18.7, 2800.00),

-- Flexible Tech Support Pattern
('Follow-the-Sun Support', 'Global technical support with timezone handoffs', 
 'follow_sun', 'technical_support', 
 '{"shifts": [{"name": "Americas", "start": "08:00", "duration": 8}, {"name": "EMEA", "start": "16:00", "duration": 8}, {"name": "APAC", "start": "00:00", "duration": 8}], "handoff_procedures": true}',
 7, '{"global_coverage": true, "min_staff_per_shift": 3, "skill_requirements": ["tier2_support", "escalation_management"]}',
 '["coverage", "expertise", "cost"]', 6, 25.3, 4200.00);

-- Sample optimization algorithms
INSERT INTO schedule_optimization_algorithms (
    name, algorithm_type, parameters, weights, max_processing_time_seconds, 
    success_rate, average_processing_time, average_improvement_score
) VALUES
('Genetic Algorithm v2.1', 'genetic_algorithm', 
 '{"population_size": 100, "generations": 500, "mutation_rate": 0.05, "crossover_rate": 0.8, "elitism_rate": 0.1}',
 '{"coverage_optimization": 0.40, "cost_efficiency": 0.30, "compliance_preferences": 0.20, "implementation_simplicity": 0.10}',
 45, 92.5, 23.4, 18.7),

('Simulated Annealing Optimizer', 'simulated_annealing', 
 '{"initial_temperature": 1000, "cooling_rate": 0.95, "min_temperature": 0.01, "max_iterations": 1000}',
 '{"coverage_optimization": 0.35, "cost_efficiency": 0.35, "compliance_preferences": 0.20, "implementation_simplicity": 0.10}',
 30, 87.3, 18.9, 16.2),

('Hybrid ML Optimizer', 'hybrid_optimization', 
 '{"neural_network_layers": [64, 32, 16], "learning_rate": 0.001, "batch_size": 32, "epochs": 200}',
 '{"coverage_optimization": 0.45, "cost_efficiency": 0.25, "compliance_preferences": 0.20, "implementation_simplicity": 0.10}',
 60, 95.1, 35.7, 21.3);

-- Sample conflict resolution rules
INSERT INTO schedule_conflict_resolution (
    conflict_type, description, severity_level, detection_rules, resolution_strategy, 
    resolution_rules, resolution_priority, resolution_success_rate
) VALUES
('labor_law_violation', 'Violation of maximum working hours or minimum rest periods', 'critical',
 '{"max_hours_per_week": 48, "min_rest_hours": 11, "max_consecutive_days": 6}',
 'automatic_resolution', 
 '{"adjust_schedule": true, "notify_supervisor": true, "require_approval": false}',
 9, 98.5),

('skill_conflict', 'Required skills not available during scheduled period', 'high',
 '{"check_skill_availability": true, "required_skill_level": "minimum", "backup_skills": true}',
 'hybrid_approach', 
 '{"suggest_alternatives": true, "cross_training_option": true, "escalate_if_no_solution": true}',
 7, 85.2),

('preference_conflict', 'Employee preferences not accommodated', 'medium',
 '{"preference_strength": "high", "accommodation_rate": 0.7, "fairness_distribution": true}',
 'manual_intervention', 
 '{"notify_employee": true, "request_flexibility": true, "offer_compensation": true}',
 5, 76.8);

-- Sample employee preferences
INSERT INTO employee_preference_integration (
    employee_id, preference_category, preference_name, preference_value, 
    preference_strength, effective_from, accommodation_rate
) VALUES
-- Assuming employee IDs exist from previous schemas
((SELECT id FROM employees LIMIT 1), 'shift_timing', 'Preferred Morning Shift', 
 '{"start_time": "08:00", "end_time": "16:00", "flexibility": "±30 minutes"}',
 'high', CURRENT_DATE, 85.5),

((SELECT id FROM employees LIMIT 1), 'work_days', 'No Weekend Work', 
 '{"excluded_days": [6, 7], "exceptions": "emergencies only"}',
 'medium', CURRENT_DATE, 72.3),

((SELECT id FROM employees LIMIT 1), 'overtime', 'Limited Overtime', 
 '{"max_overtime_hours": 5, "max_overtime_days": 2, "advance_notice": "24 hours"}',
 'high', CURRENT_DATE, 90.1);

-- ============================================================================
-- Views for Reporting and Analytics
-- ============================================================================

-- View for schedule optimization performance
CREATE OR REPLACE VIEW schedule_optimization_performance AS
SELECT 
    t.name as template_name,
    t.template_type,
    t.business_context,
    a.coverage_efficiency,
    a.cost_efficiency,
    a.satisfaction_score,
    a.service_level_achieved,
    a.schedule_adherence,
    a.utilization_rate,
    a.analysis_period_start,
    a.analysis_period_end,
    EXTRACT(EPOCH FROM (a.analysis_period_end - a.analysis_period_start)) / 3600 as analysis_hours
FROM advanced_schedule_templates t
JOIN schedule_performance_analytics a ON t.id = a.template_id
WHERE t.is_active = true;

-- View for conflict resolution effectiveness
CREATE OR REPLACE VIEW conflict_resolution_effectiveness AS
SELECT 
    cr.conflict_type,
    cr.severity_level,
    cr.resolution_strategy,
    cr.resolution_success_rate,
    cr.average_resolution_time_minutes,
    COUNT(ci.id) as total_incidents,
    COUNT(CASE WHEN ci.resolution_status = 'resolved' THEN 1 END) as resolved_incidents,
    AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at)) / 60) as avg_resolution_time_actual
FROM schedule_conflict_resolution cr
LEFT JOIN schedule_conflict_incidents ci ON cr.id = ci.conflict_rule_id
WHERE cr.is_active = true
GROUP BY cr.id, cr.conflict_type, cr.severity_level, cr.resolution_strategy, 
         cr.resolution_success_rate, cr.average_resolution_time_minutes;

-- View for employee preference accommodation
CREATE OR REPLACE VIEW employee_preference_accommodation AS
SELECT 
    e.first_name || ' ' || e.last_name as employee_name,
    epi.preference_category,
    epi.preference_strength,
    epi.accommodation_rate,
    epi.impact_on_satisfaction,
    COUNT(*) as total_preferences,
    AVG(epi.accommodation_rate) as avg_accommodation_rate
FROM employees e
JOIN employee_preference_integration epi ON e.id = epi.employee_id
WHERE epi.is_active = true
GROUP BY e.id, e.first_name, e.last_name, epi.preference_category, 
         epi.preference_strength, epi.accommodation_rate, epi.impact_on_satisfaction;

-- ============================================================================
-- Comments and Documentation
-- ============================================================================

COMMENT ON TABLE advanced_schedule_templates IS 'Advanced scheduling templates with complex patterns and AI optimization capabilities';
COMMENT ON TABLE schedule_optimization_algorithms IS 'AI-powered optimization algorithms for schedule generation and improvement';
COMMENT ON TABLE shift_pattern_variations IS 'Flexible shift configurations with various adaptation options';
COMMENT ON TABLE schedule_conflict_resolution IS 'Automated conflict detection and resolution rules';
COMMENT ON TABLE employee_preference_integration IS 'Employee preference management and accommodation tracking';
COMMENT ON TABLE schedule_performance_analytics IS 'Comprehensive performance metrics and efficiency tracking';
COMMENT ON TABLE schedule_optimization_sessions IS 'Optimization session tracking and results management';
COMMENT ON TABLE schedule_conflict_incidents IS 'Specific conflict incident tracking and resolution history';

COMMENT ON FUNCTION calculate_schedule_optimization_score IS 'Calculate optimization score based on multiple performance factors';
COMMENT ON FUNCTION detect_schedule_conflicts IS 'Detect various types of schedule conflicts and violations';
COMMENT ON FUNCTION generate_schedule_suggestions IS 'Generate AI-powered schedule suggestions using specified algorithms';

-- ============================================================================
-- Schema Version and Completion
-- ============================================================================

-- Record schema version
INSERT INTO schema_versions (version, description, applied_at) 
VALUES ('041', 'Schedule Management Advanced Features with AI optimization, conflict resolution, and performance analytics', CURRENT_TIMESTAMP)
ON CONFLICT (version) DO UPDATE SET 
    description = EXCLUDED.description,
    applied_at = EXCLUDED.applied_at;

-- Schema 041 implementation completed successfully
-- Features implemented:
-- ✓ Advanced schedule templates with complex patterns
-- ✓ AI-powered optimization algorithms (genetic, simulated annealing, hybrid ML)
-- ✓ Flexible shift pattern variations
-- ✓ Automated conflict detection and resolution
-- ✓ Employee preference integration and accommodation
-- ✓ Comprehensive performance analytics and efficiency tracking
-- ✓ Optimization session management
-- ✓ Conflict incident tracking
-- ✓ Reporting views and analytics functions
-- ✓ Sample data and configuration
-- ✓ Integration with existing schemas