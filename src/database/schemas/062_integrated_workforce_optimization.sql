-- =============================================================================
-- 062_integrated_workforce_optimization.sql
-- COMPREHENSIVE BDD Implementation: Integrated Workforce Optimization System
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-15
-- Purpose: Advanced workforce management with Russian holiday integration, 
--          employee preferences, schedule optimization, and resource allocation
-- BDD Sources: 31-vacation-schemes-management.feature, 28-production-calendar-management.feature,
--              24-preference-management-enhancements.feature, 24-automatic-schedule-optimization.feature
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================================================
-- 1. RUSSIAN PRODUCTION CALENDAR INTEGRATION
-- =============================================================================

-- Russian Federation production calendar with XML import support (BDD 28:12-30)
CREATE TABLE russian_production_calendar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Calendar year and metadata (BDD 28:16-21)
    calendar_year INTEGER NOT NULL CHECK (calendar_year >= 2020 AND calendar_year <= 2030),
    source_file VARCHAR(255),
    imported_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'validated', 'error', 'manual_override'
    )),
    
    -- Calendar data structure (BDD 28:16-21)
    work_days JSONB NOT NULL DEFAULT '[]', -- Array of working days
    holidays JSONB NOT NULL DEFAULT '[]',  -- Array of holiday dates
    pre_holidays JSONB NOT NULL DEFAULT '[]', -- Array of pre-holiday shortened days
    weekends JSONB NOT NULL DEFAULT '[]', -- Auto-generated weekends
    
    -- Statistical summary for quick access
    total_work_days INTEGER DEFAULT 247,
    total_holidays INTEGER DEFAULT 12,
    total_pre_holidays INTEGER DEFAULT 4,
    total_weekends INTEGER DEFAULT 104,
    
    -- Validation metadata (BDD 28:22-30)
    validation_errors JSONB DEFAULT '[]',
    edge_cases_handled JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(calendar_year)
);

-- Holiday specifications with multilingual support (BDD 28:61-75)
CREATE TABLE russian_holiday_specifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_id VARCHAR(50) NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    
    -- Holiday details (BDD 28:66-70)
    holiday_name_ru VARCHAR(200) NOT NULL,
    holiday_name_en VARCHAR(200),
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(20) NOT NULL CHECK (holiday_type IN ('federal', 'regional', 'corporate')),
    holiday_description TEXT,
    
    -- Calendar impact (BDD 28:81-89)
    extends_vacation BOOLEAN DEFAULT true,
    creates_bridge BOOLEAN DEFAULT false,
    affects_pre_holiday BOOLEAN DEFAULT true,
    
    -- Legal and business context
    is_official BOOLEAN DEFAULT true,
    labor_code_reference VARCHAR(100),
    business_impact_level VARCHAR(20) DEFAULT 'high' CHECK (business_impact_level IN ('low', 'medium', 'high')),
    
    -- Regional scope
    applies_to_regions JSONB DEFAULT '["all"]',
    industry_specific BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES russian_production_calendar(calendar_year) ON DELETE CASCADE,
    
    UNIQUE(holiday_date, calendar_year)
);

-- =============================================================================
-- 2. ADVANCED VACATION SCHEME MANAGEMENT WITH RUSSIAN INTEGRATION
-- =============================================================================

-- Enhanced vacation schemes with Russian labor law compliance
CREATE TABLE enhanced_vacation_schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_id VARCHAR(50) NOT NULL UNIQUE,
    scheme_name_ru VARCHAR(200) NOT NULL,
    scheme_name_en VARCHAR(200),
    
    -- Basic entitlements (BDD 31:16-20)
    annual_vacation_days INTEGER NOT NULL CHECK (annual_vacation_days > 0),
    max_periods_per_year INTEGER NOT NULL CHECK (max_periods_per_year > 0),
    min_duration_days INTEGER DEFAULT 14 CHECK (min_duration_days >= 14), -- Russian minimum
    max_duration_days INTEGER DEFAULT 28 CHECK (max_duration_days >= 14),
    
    -- Russian labor law compliance
    russian_labor_code_compliant BOOLEAN DEFAULT true,
    minimum_continuous_period INTEGER DEFAULT 14, -- Russian requirement: 14 consecutive days
    additional_days_categories JSONB DEFAULT '{}', -- Special categories (disabled, parents, etc.)
    
    -- Holiday integration (BDD 28:77-89)
    auto_extend_for_holidays BOOLEAN DEFAULT true,
    bridge_weekend_gaps BOOLEAN DEFAULT true,
    include_pre_holidays BOOLEAN DEFAULT true,
    
    -- Calculation methods
    pro_rata_calculation_method VARCHAR(30) DEFAULT 'monthly' CHECK (pro_rata_calculation_method IN (
        'daily', 'weekly', 'monthly', 'anniversary'
    )),
    accrual_method VARCHAR(30) DEFAULT 'linear' CHECK (accrual_method IN (
        'linear', 'front_loaded', 'anniversary_based'
    )),
    
    -- Carry-over rules
    allow_carry_over BOOLEAN DEFAULT true,
    max_carry_over_days INTEGER DEFAULT 14, -- Russian limit
    carry_over_expiry_months INTEGER DEFAULT 18,
    compensation_for_unused BOOLEAN DEFAULT true,
    
    -- Employee scope and applicability
    applies_to_employee_categories JSONB DEFAULT '[]',
    requires_seniority_months INTEGER DEFAULT 6,
    probation_period_restrictions JSONB DEFAULT '{}',
    
    -- Approval and business rules
    requires_manager_approval BOOLEAN DEFAULT true,
    advance_notice_days INTEGER DEFAULT 14,
    blackout_periods_configurable BOOLEAN DEFAULT true,
    team_coverage_required BOOLEAN DEFAULT true,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_by INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    CHECK (max_duration_days >= min_duration_days),
    CHECK (expiry_date IS NULL OR expiry_date > effective_date)
);

-- Employee vacation calculations with Russian calendar integration
CREATE TABLE employee_vacation_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calculation_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id INTEGER NOT NULL,
    scheme_id VARCHAR(50) NOT NULL,
    calculation_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    
    -- Base entitlements
    base_entitlement_days DECIMAL(4,1) NOT NULL,
    additional_days DECIMAL(4,1) DEFAULT 0.0, -- For special categories
    total_entitlement_days DECIMAL(4,1) NOT NULL,
    
    -- Russian calendar adjustments
    holiday_extensions INTEGER DEFAULT 0,
    bridge_days_added INTEGER DEFAULT 0,
    pre_holiday_adjustments INTEGER DEFAULT 0,
    weekend_optimizations INTEGER DEFAULT 0,
    
    -- Usage tracking
    planned_vacation_days DECIMAL(4,1) DEFAULT 0.0,
    taken_vacation_days DECIMAL(4,1) DEFAULT 0.0,
    pending_requests_days DECIMAL(4,1) DEFAULT 0.0,
    remaining_days DECIMAL(4,1) NOT NULL,
    
    -- Period management
    periods_planned INTEGER DEFAULT 0,
    periods_taken INTEGER DEFAULT 0,
    periods_remaining INTEGER NOT NULL,
    continuous_period_satisfied BOOLEAN DEFAULT false,
    
    -- Carry-over from previous year
    carried_over_days DECIMAL(4,1) DEFAULT 0.0,
    carry_over_expiry_date DATE,
    
    -- Financial calculations
    vacation_pay_reserve DECIMAL(12,2) DEFAULT 0.0,
    unused_compensation_due DECIMAL(12,2) DEFAULT 0.0,
    
    -- Optimization recommendations
    optimal_vacation_plan JSONB DEFAULT '{}',
    holiday_optimization_suggestions JSONB DEFAULT '[]',
    
    -- Status and recalculation
    calculation_status VARCHAR(20) DEFAULT 'current' CHECK (calculation_status IN (
        'current', 'recalculation_needed', 'expired', 'superseded'
    )),
    last_recalculated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (scheme_id) REFERENCES enhanced_vacation_schemes(scheme_id) ON DELETE RESTRICT,
    
    UNIQUE(employee_id, calculation_year),
    
    CHECK (total_entitlement_days = base_entitlement_days + additional_days),
    CHECK (remaining_days = total_entitlement_days + carried_over_days - taken_vacation_days - pending_requests_days)
);

-- =============================================================================
-- 3. INTEGRATED EMPLOYEE PREFERENCE SYSTEM
-- =============================================================================

-- Comprehensive preference types with optimization weights
CREATE TABLE integrated_preference_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_id VARCHAR(50) NOT NULL UNIQUE,
    type_name_ru VARCHAR(200) NOT NULL,
    type_name_en VARCHAR(200),
    
    -- Categorization (BDD 24:24-27)
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'shift_preferences', 'vacation_preferences', 'skill_preferences',
        'environment_preferences', 'notification_preferences', 'schedule_preferences'
    )),
    subcategory VARCHAR(100),
    
    -- Optimization parameters (BDD 24:26-29)
    optimization_weight DECIMAL(3,2) DEFAULT 1.0 CHECK (optimization_weight >= 0.0 AND optimization_weight <= 10.0),
    conflict_resolution_priority INTEGER DEFAULT 5 CHECK (conflict_resolution_priority >= 1 AND conflict_resolution_priority <= 10),
    business_rule_importance VARCHAR(20) DEFAULT 'medium' CHECK (business_rule_importance IN (
        'low', 'medium', 'high', 'critical'
    )),
    
    -- Configuration schema
    configuration_schema JSONB NOT NULL DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    default_values JSONB DEFAULT '{}',
    
    -- Localization support
    display_configuration JSONB DEFAULT '{}',
    help_text_ru TEXT,
    help_text_en TEXT,
    
    -- Integration settings
    affects_scheduling BOOLEAN DEFAULT true,
    affects_vacation_planning BOOLEAN DEFAULT false,
    affects_resource_allocation BOOLEAN DEFAULT false,
    requires_manager_approval BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    version VARCHAR(20) DEFAULT '1.0',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Employee preferences with Russian localization and advanced features
CREATE TABLE employee_integrated_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    preference_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id INTEGER NOT NULL,
    type_id VARCHAR(50) NOT NULL,
    
    -- Preference configuration
    preference_value JSONB NOT NULL,
    display_value_ru TEXT,
    display_value_en TEXT,
    
    -- Priority and flexibility (BDD 24:26-29, 51-52)
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    flexibility_factor INTEGER DEFAULT 5 CHECK (flexibility_factor >= 1 AND flexibility_factor <= 10),
    
    -- Temporal settings
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    seasonal_variations JSONB DEFAULT '{}',
    
    -- Schedule optimization integration (BDD 24:57-61)
    optimization_score DECIMAL(3,2) DEFAULT 5.0,
    satisfaction_threshold DECIMAL(3,2) DEFAULT 7.0,
    affects_team_scheduling BOOLEAN DEFAULT false,
    
    -- Vacation planning integration
    impacts_vacation_timing BOOLEAN DEFAULT false,
    vacation_preference_weight DECIMAL(3,2) DEFAULT 1.0,
    holiday_considerations JSONB DEFAULT '{}',
    
    -- Conflict resolution (BDD 24:58-61)
    conflict_resolution_method VARCHAR(30) DEFAULT 'weighted' CHECK (conflict_resolution_method IN (
        'weighted', 'priority_based', 'seniority_based', 'manual'
    )),
    auto_resolve_conflicts BOOLEAN DEFAULT true,
    
    -- Learning and adaptation
    satisfaction_history JSONB DEFAULT '[]',
    adaptation_enabled BOOLEAN DEFAULT true,
    ml_optimization_enabled BOOLEAN DEFAULT false,
    
    -- Approval workflow
    requires_approval BOOLEAN DEFAULT false,
    approved_by INTEGER,
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN (
        'active', 'inactive', 'pending_approval', 'conflicted', 'expired'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES integrated_preference_types(type_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(employee_id, type_id, effective_date)
);

-- =============================================================================
-- 4. ADVANCED SCHEDULE TEMPLATE OPTIMIZATION
-- =============================================================================

-- Schedule templates with optimization algorithms (BDD 24:42-61)
CREATE TABLE advanced_schedule_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id VARCHAR(50) NOT NULL UNIQUE,
    template_name_ru VARCHAR(200) NOT NULL,
    template_name_en VARCHAR(200),
    
    -- Template classification
    template_type VARCHAR(30) NOT NULL CHECK (template_type IN (
        'daily', 'weekly', 'monthly', 'seasonal', 'event_based', 'dynamic'
    )),
    industry_focus VARCHAR(50) DEFAULT 'call_center',
    complexity_level VARCHAR(20) DEFAULT 'standard' CHECK (complexity_level IN (
        'simple', 'standard', 'advanced', 'expert'
    )),
    
    -- Schedule definition
    schedule_pattern JSONB NOT NULL, -- Core schedule structure
    shift_definitions JSONB NOT NULL, -- Shift types and properties
    break_patterns JSONB DEFAULT '{}',
    rotation_rules JSONB DEFAULT '{}',
    
    -- Optimization parameters
    optimization_objectives JSONB NOT NULL DEFAULT '["coverage", "satisfaction", "cost"]',
    constraint_rules JSONB NOT NULL DEFAULT '{}',
    weight_configuration JSONB DEFAULT '{}',
    
    -- Employee preference integration
    considers_shift_preferences BOOLEAN DEFAULT true,
    considers_vacation_preferences BOOLEAN DEFAULT true,
    considers_skill_preferences BOOLEAN DEFAULT true,
    preference_satisfaction_weight DECIMAL(3,2) DEFAULT 1.0,
    
    -- Russian calendar integration
    integrates_russian_holidays BOOLEAN DEFAULT true,
    auto_adjust_for_holidays BOOLEAN DEFAULT true,
    bridge_optimization_enabled BOOLEAN DEFAULT true,
    pre_holiday_adjustments BOOLEAN DEFAULT true,
    
    -- Business constraints
    coverage_requirements JSONB NOT NULL,
    skill_requirements JSONB DEFAULT '{}',
    labor_law_compliance JSONB DEFAULT '{}',
    cost_constraints JSONB DEFAULT '{}',
    
    -- Optimization algorithms
    primary_algorithm VARCHAR(50) DEFAULT 'genetic_algorithm' CHECK (primary_algorithm IN (
        'genetic_algorithm', 'linear_programming', 'constraint_satisfaction', 'hybrid'
    )),
    secondary_algorithms JSONB DEFAULT '[]',
    optimization_timeout_seconds INTEGER DEFAULT 300,
    solution_quality_threshold DECIMAL(3,2) DEFAULT 8.0,
    
    -- Performance metrics
    average_optimization_time_ms INTEGER,
    success_rate DECIMAL(3,2),
    satisfaction_improvement DECIMAL(3,2),
    cost_reduction_percentage DECIMAL(3,2),
    
    -- Template scope
    applies_to_departments JSONB DEFAULT '[]',
    applies_to_locations JSONB DEFAULT '[]',
    applies_to_skill_groups JSONB DEFAULT '[]',
    team_size_range JSONB DEFAULT '{"min": 5, "max": 50}',
    
    -- Lifecycle management
    is_active BOOLEAN DEFAULT true,
    version VARCHAR(20) DEFAULT '1.0',
    parent_template_id UUID,
    
    -- Effectiveness tracking
    usage_count INTEGER DEFAULT 0,
    success_metrics JSONB DEFAULT '{}',
    improvement_suggestions JSONB DEFAULT '[]',
    
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (parent_template_id) REFERENCES advanced_schedule_templates(id) ON DELETE SET NULL
);

-- Schedule optimization results and analytics
CREATE TABLE schedule_optimization_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_id VARCHAR(50) NOT NULL UNIQUE,
    template_id VARCHAR(50) NOT NULL,
    
    -- Optimization context
    optimization_date DATE NOT NULL,
    target_period_start DATE NOT NULL,
    target_period_end DATE NOT NULL,
    optimization_trigger VARCHAR(50) DEFAULT 'scheduled' CHECK (optimization_trigger IN (
        'scheduled', 'manual', 'preference_change', 'calendar_update', 'coverage_gap'
    )),
    
    -- Input parameters
    employee_count INTEGER NOT NULL,
    preference_changes_count INTEGER DEFAULT 0,
    holiday_adjustments_count INTEGER DEFAULT 0,
    constraint_violations_initial INTEGER DEFAULT 0,
    
    -- Algorithm execution
    algorithm_used VARCHAR(50) NOT NULL,
    execution_time_ms INTEGER NOT NULL,
    iterations_performed INTEGER,
    convergence_achieved BOOLEAN DEFAULT false,
    
    -- Solution quality metrics
    overall_score DECIMAL(5,2) NOT NULL,
    coverage_score DECIMAL(5,2) NOT NULL,
    satisfaction_score DECIMAL(5,2) NOT NULL,
    cost_efficiency_score DECIMAL(5,2) NOT NULL,
    preference_fulfillment_rate DECIMAL(5,2),
    
    -- Detailed results
    optimized_schedule JSONB NOT NULL,
    employee_assignments JSONB NOT NULL,
    constraint_satisfaction JSONB DEFAULT '{}',
    preference_accommodations JSONB DEFAULT '{}',
    
    -- Holiday and calendar integration
    holiday_adjustments_made JSONB DEFAULT '[]',
    bridge_optimizations JSONB DEFAULT '[]',
    vacation_integrations JSONB DEFAULT '[]',
    
    -- Comparison with previous solution
    improvement_over_previous DECIMAL(5,2),
    changes_from_previous JSONB DEFAULT '{}',
    
    -- Validation and approval
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'validated', 'approved', 'rejected', 'needs_review'
    )),
    validated_by INTEGER,
    validation_notes TEXT,
    
    -- Implementation tracking
    implementation_status VARCHAR(20) DEFAULT 'planned' CHECK (implementation_status IN (
        'planned', 'implementing', 'implemented', 'rolled_back'
    )),
    implementation_date TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (template_id) REFERENCES advanced_schedule_templates(template_id) ON DELETE RESTRICT,
    FOREIGN KEY (validated_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    CHECK (target_period_end >= target_period_start)
);

-- =============================================================================
-- 5. RESOURCE ALLOCATION AND CAPACITY PLANNING
-- =============================================================================

-- Comprehensive resource allocation with multi-skill optimization
CREATE TABLE resource_allocation_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id VARCHAR(50) NOT NULL UNIQUE,
    model_name_ru VARCHAR(200) NOT NULL,
    model_name_en VARCHAR(200),
    
    -- Model classification
    allocation_type VARCHAR(30) NOT NULL CHECK (allocation_type IN (
        'skill_based', 'preference_based', 'hybrid', 'ml_optimized'
    )),
    planning_horizon VARCHAR(20) NOT NULL CHECK (planning_horizon IN (
        'real_time', 'intraday', 'daily', 'weekly', 'monthly', 'seasonal'
    )),
    
    -- Resource definitions
    resource_types JSONB NOT NULL, -- Skills, equipment, locations
    capacity_definitions JSONB NOT NULL,
    demand_patterns JSONB NOT NULL,
    
    -- Optimization objectives
    primary_objective VARCHAR(50) DEFAULT 'efficiency' CHECK (primary_objective IN (
        'efficiency', 'satisfaction', 'cost_minimization', 'coverage_maximization'
    )),
    secondary_objectives JSONB DEFAULT '[]',
    objective_weights JSONB DEFAULT '{}',
    
    -- Constraint framework
    hard_constraints JSONB NOT NULL, -- Must be satisfied
    soft_constraints JSONB DEFAULT '{}', -- Preferred but flexible
    business_rules JSONB NOT NULL,
    
    -- Employee preference integration
    preference_consideration_level VARCHAR(20) DEFAULT 'high' CHECK (preference_consideration_level IN (
        'low', 'medium', 'high', 'maximum'
    )),
    preference_override_conditions JSONB DEFAULT '{}',
    
    -- Russian calendar integration
    calendar_integration_enabled BOOLEAN DEFAULT true,
    holiday_impact_modeling BOOLEAN DEFAULT true,
    vacation_demand_forecasting BOOLEAN DEFAULT true,
    
    -- Algorithm configuration
    solution_algorithm VARCHAR(50) DEFAULT 'multi_objective' CHECK (solution_algorithm IN (
        'linear_programming', 'genetic_algorithm', 'simulated_annealing', 'multi_objective'
    )),
    algorithm_parameters JSONB DEFAULT '{}',
    convergence_criteria JSONB DEFAULT '{}',
    
    -- Performance characteristics
    typical_solution_time_ms INTEGER,
    solution_quality_range JSONB DEFAULT '{"min": 7.0, "max": 10.0}',
    scalability_limits JSONB DEFAULT '{}',
    
    -- Applicability scope
    applicable_team_sizes JSONB DEFAULT '{"min": 10, "max": 500}',
    industry_specialization JSONB DEFAULT '["call_center"]',
    complexity_rating INTEGER DEFAULT 5 CHECK (complexity_rating >= 1 AND complexity_rating <= 10),
    
    -- Model lifecycle
    is_active BOOLEAN DEFAULT true,
    version VARCHAR(20) DEFAULT '1.0',
    maturity_level VARCHAR(20) DEFAULT 'production' CHECK (maturity_level IN (
        'experimental', 'testing', 'production', 'deprecated'
    )),
    
    -- Effectiveness metrics
    historical_performance JSONB DEFAULT '{}',
    user_satisfaction_rating DECIMAL(3,2),
    
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- Resource allocation execution and results
CREATE TABLE resource_allocation_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id VARCHAR(50) NOT NULL UNIQUE,
    model_id VARCHAR(50) NOT NULL,
    
    -- Execution context
    execution_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    target_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    execution_trigger VARCHAR(50) DEFAULT 'scheduled' CHECK (execution_trigger IN (
        'scheduled', 'demand_change', 'preference_update', 'capacity_change', 'manual'
    )),
    
    -- Input data
    employee_pool_size INTEGER NOT NULL,
    total_demand_units DECIMAL(10,2) NOT NULL,
    available_capacity_units DECIMAL(10,2) NOT NULL,
    constraint_count INTEGER DEFAULT 0,
    preference_count INTEGER DEFAULT 0,
    
    -- Execution parameters
    algorithm_configuration JSONB NOT NULL,
    optimization_timeout_ms INTEGER DEFAULT 300000,
    solution_quality_target DECIMAL(3,2) DEFAULT 8.0,
    
    -- Algorithm performance
    actual_execution_time_ms INTEGER NOT NULL,
    iterations_completed INTEGER,
    convergence_status VARCHAR(20) DEFAULT 'completed' CHECK (convergence_status IN (
        'completed', 'timeout', 'error', 'interrupted'
    )),
    memory_usage_mb DECIMAL(8,2),
    
    -- Solution quality
    overall_quality_score DECIMAL(5,2) NOT NULL,
    efficiency_score DECIMAL(5,2) NOT NULL,
    satisfaction_score DECIMAL(5,2) NOT NULL,
    constraint_satisfaction_rate DECIMAL(5,2) NOT NULL,
    preference_fulfillment_rate DECIMAL(5,2),
    
    -- Detailed allocation results
    resource_assignments JSONB NOT NULL,
    capacity_utilization JSONB NOT NULL,
    unmet_demand JSONB DEFAULT '{}',
    over_allocation JSONB DEFAULT '{}',
    
    -- Employee-specific results
    employee_allocations JSONB NOT NULL,
    workload_distribution JSONB NOT NULL,
    satisfaction_by_employee JSONB DEFAULT '{}',
    preference_accommodations JSONB DEFAULT '{}',
    
    -- Holiday and calendar considerations
    holiday_adjustments JSONB DEFAULT '[]',
    vacation_accommodations JSONB DEFAULT '[]',
    calendar_impact_analysis JSONB DEFAULT '{}',
    
    -- Business impact analysis
    cost_analysis JSONB DEFAULT '{}',
    revenue_impact JSONB DEFAULT '{}',
    service_level_projections JSONB DEFAULT '{}',
    
    -- Validation and approval
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'validated', 'approved', 'rejected', 'implemented'
    )),
    validator_id INTEGER,
    validation_notes TEXT,
    validation_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Implementation tracking
    implementation_status VARCHAR(20) DEFAULT 'planned' CHECK (implementation_status IN (
        'planned', 'in_progress', 'completed', 'failed', 'rolled_back'
    )),
    implementation_start TIMESTAMP WITH TIME ZONE,
    implementation_completion TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (model_id) REFERENCES resource_allocation_models(model_id) ON DELETE RESTRICT,
    FOREIGN KEY (validator_id) REFERENCES employees(id) ON DELETE SET NULL,
    
    CHECK (target_period_end > target_period_start)
);

-- =============================================================================
-- 6. SYSTEM INTEGRATION AND MONITORING
-- =============================================================================

-- Integration status and health monitoring
CREATE TABLE system_integration_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Component status
    component_name VARCHAR(100) NOT NULL,
    component_type VARCHAR(50) NOT NULL CHECK (component_type IN (
        'calendar_integration', 'preference_engine', 'optimization_engine', 
        'vacation_calculator', 'resource_allocator', 'notification_service'
    )),
    
    -- Health metrics
    status VARCHAR(20) DEFAULT 'healthy' CHECK (status IN (
        'healthy', 'warning', 'error', 'maintenance', 'offline'
    )),
    health_score DECIMAL(3,2) DEFAULT 10.0 CHECK (health_score >= 0.0 AND health_score <= 10.0),
    last_health_check TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Performance metrics
    average_response_time_ms DECIMAL(8,2),
    success_rate DECIMAL(5,2),
    error_rate DECIMAL(5,2),
    throughput_per_hour DECIMAL(10,2),
    
    -- Integration metrics
    data_sync_status VARCHAR(20) DEFAULT 'synchronized' CHECK (data_sync_status IN (
        'synchronized', 'pending', 'partial', 'error', 'manual_intervention_required'
    )),
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_error_count INTEGER DEFAULT 0,
    
    -- Dependency tracking
    depends_on_components JSONB DEFAULT '[]',
    dependent_components JSONB DEFAULT '[]',
    critical_path_component BOOLEAN DEFAULT false,
    
    -- Alert configuration
    alert_thresholds JSONB DEFAULT '{}',
    notification_recipients JSONB DEFAULT '[]',
    escalation_rules JSONB DEFAULT '{}',
    
    -- Status history
    status_changes JSONB DEFAULT '[]',
    maintenance_windows JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

-- Russian calendar indexes
CREATE INDEX idx_russian_production_calendar_year ON russian_production_calendar(calendar_year);
CREATE INDEX idx_russian_production_calendar_active ON russian_production_calendar(is_active) WHERE is_active = true;
CREATE INDEX idx_russian_holiday_specifications_date ON russian_holiday_specifications(holiday_date);
CREATE INDEX idx_russian_holiday_specifications_year ON russian_holiday_specifications(calendar_year);

-- Vacation scheme indexes
CREATE INDEX idx_enhanced_vacation_schemes_active ON enhanced_vacation_schemes(is_active) WHERE is_active = true;
CREATE INDEX idx_enhanced_vacation_schemes_effective ON enhanced_vacation_schemes(effective_date, expiry_date);
CREATE INDEX idx_employee_vacation_calculations_employee ON employee_vacation_calculations(employee_id);
CREATE INDEX idx_employee_vacation_calculations_year ON employee_vacation_calculations(calculation_year);

-- Preference system indexes
CREATE INDEX idx_integrated_preference_types_category ON integrated_preference_types(category);
CREATE INDEX idx_integrated_preference_types_active ON integrated_preference_types(is_active) WHERE is_active = true;
CREATE INDEX idx_employee_integrated_preferences_employee ON employee_integrated_preferences(employee_id);
CREATE INDEX idx_employee_integrated_preferences_type ON employee_integrated_preferences(type_id);
CREATE INDEX idx_employee_integrated_preferences_status ON employee_integrated_preferences(status) WHERE status = 'active';

-- Schedule template indexes
CREATE INDEX idx_advanced_schedule_templates_type ON advanced_schedule_templates(template_type);
CREATE INDEX idx_advanced_schedule_templates_active ON advanced_schedule_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_schedule_optimization_results_template ON schedule_optimization_results(template_id);
CREATE INDEX idx_schedule_optimization_results_date ON schedule_optimization_results(optimization_date);
CREATE INDEX idx_schedule_optimization_results_period ON schedule_optimization_results(target_period_start, target_period_end);

-- Resource allocation indexes
CREATE INDEX idx_resource_allocation_models_type ON resource_allocation_models(allocation_type);
CREATE INDEX idx_resource_allocation_models_active ON resource_allocation_models(is_active) WHERE is_active = true;
CREATE INDEX idx_resource_allocation_executions_model ON resource_allocation_executions(model_id);
CREATE INDEX idx_resource_allocation_executions_date ON resource_allocation_executions(execution_date);
CREATE INDEX idx_resource_allocation_executions_period ON resource_allocation_executions(target_period_start, target_period_end);

-- System monitoring indexes
CREATE INDEX idx_system_integration_status_component ON system_integration_status(component_type);
CREATE INDEX idx_system_integration_status_health ON system_integration_status(status, health_score);
CREATE INDEX idx_system_integration_status_sync ON system_integration_status(data_sync_status) WHERE data_sync_status != 'synchronized';

-- Composite indexes for complex queries
CREATE INDEX idx_vacation_calc_employee_year ON employee_vacation_calculations(employee_id, calculation_year);
CREATE INDEX idx_preferences_employee_type_status ON employee_integrated_preferences(employee_id, type_id, status);
CREATE INDEX idx_optimization_results_template_date ON schedule_optimization_results(template_id, optimization_date);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_integrated_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER russian_production_calendar_update_trigger
    BEFORE UPDATE ON russian_production_calendar
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER enhanced_vacation_schemes_update_trigger
    BEFORE UPDATE ON enhanced_vacation_schemes
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER employee_vacation_calculations_update_trigger
    BEFORE UPDATE ON employee_vacation_calculations
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER integrated_preference_types_update_trigger
    BEFORE UPDATE ON integrated_preference_types
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER employee_integrated_preferences_update_trigger
    BEFORE UPDATE ON employee_integrated_preferences
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER advanced_schedule_templates_update_trigger
    BEFORE UPDATE ON advanced_schedule_templates
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER resource_allocation_models_update_trigger
    BEFORE UPDATE ON resource_allocation_models
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

CREATE TRIGGER system_integration_status_update_trigger
    BEFORE UPDATE ON system_integration_status
    FOR EACH ROW EXECUTE FUNCTION update_integrated_timestamp();

-- Russian holiday extension calculation function
CREATE OR REPLACE FUNCTION calculate_vacation_with_holidays(
    vacation_start_date DATE,
    vacation_end_date DATE,
    calendar_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
)
RETURNS TABLE (
    original_days INTEGER,
    extended_days INTEGER,
    total_days INTEGER,
    holiday_extensions JSONB
) AS $$
DECLARE
    holiday_record RECORD;
    extension_days INTEGER := 0;
    extensions JSONB := '[]'::JSONB;
BEGIN
    original_days := vacation_end_date - vacation_start_date + 1;
    
    -- Check for holidays within or adjacent to vacation period
    FOR holiday_record IN 
        SELECT holiday_date, holiday_name_ru, extends_vacation
        FROM russian_holiday_specifications rhs
        WHERE rhs.calendar_year = calculate_vacation_with_holidays.calendar_year
          AND rhs.holiday_date BETWEEN vacation_start_date - INTERVAL '2 days' 
                                   AND vacation_end_date + INTERVAL '2 days'
          AND rhs.extends_vacation = true
    LOOP
        extension_days := extension_days + 1;
        extensions := extensions || jsonb_build_object(
            'holiday_date', holiday_record.holiday_date,
            'holiday_name', holiday_record.holiday_name_ru,
            'extension_type', 'automatic'
        );
    END LOOP;
    
    extended_days := extension_days;
    total_days := original_days + extended_days;
    holiday_extensions := extensions;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Preference satisfaction scoring function
CREATE OR REPLACE FUNCTION calculate_preference_satisfaction(
    employee_id_param UUID,
    evaluation_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    overall_satisfaction DECIMAL(3,2),
    category_scores JSONB,
    improvement_suggestions JSONB
) AS $$
DECLARE
    pref_record RECORD;
    total_weight DECIMAL(5,2) := 0;
    weighted_satisfaction DECIMAL(5,2) := 0;
    category_scores_obj JSONB := '{}'::JSONB;
    suggestions JSONB := '[]'::JSONB;
BEGIN
    FOR pref_record IN
        SELECT 
            p.category,
            p.optimization_weight,
            ep.satisfaction_threshold,
            ep.optimization_score,
            ep.priority
        FROM employee_integrated_preferences ep
        JOIN integrated_preference_types p ON ep.type_id = p.type_id
        WHERE ep.employee_id = employee_id_param
          AND ep.status = 'active'
          AND ep.effective_date <= evaluation_date
          AND (ep.expiry_date IS NULL OR ep.expiry_date > evaluation_date)
    LOOP
        total_weight := total_weight + pref_record.optimization_weight;
        weighted_satisfaction := weighted_satisfaction + 
            (pref_record.optimization_score * pref_record.optimization_weight);
        
        -- Build category scores
        category_scores_obj := category_scores_obj || jsonb_build_object(
            pref_record.category, pref_record.optimization_score
        );
        
        -- Generate improvement suggestions
        IF pref_record.optimization_score < pref_record.satisfaction_threshold THEN
            suggestions := suggestions || jsonb_build_object(
                'category', pref_record.category,
                'current_score', pref_record.optimization_score,
                'target_score', pref_record.satisfaction_threshold,
                'priority', pref_record.priority,
                'suggestion', 'Consider adjusting ' || pref_record.category || ' to improve satisfaction'
            );
        END IF;
    END LOOP;
    
    IF total_weight > 0 THEN
        overall_satisfaction := weighted_satisfaction / total_weight;
    ELSE
        overall_satisfaction := 0.0;
    END IF;
    
    category_scores := category_scores_obj;
    improvement_suggestions := suggestions;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS FOR COMPLEX QUERIES AND REPORTING
-- =============================================================================

-- Comprehensive employee vacation status with Russian calendar integration
CREATE VIEW v_employee_vacation_status_integrated AS
SELECT 
    e.id as employee_id,
    (e.first_name || ' ' || e.last_name) as employee_name,
    d.department_name as department_name,
    
    -- Current year vacation status
    evc.calculation_year,
    evc.total_entitlement_days,
    evc.taken_vacation_days,
    evc.pending_requests_days,
    evc.remaining_days,
    evc.carried_over_days,
    
    -- Holiday integration benefits
    evc.holiday_extensions,
    evc.bridge_days_added,
    evc.weekend_optimizations,
    
    -- Vacation scheme details
    evs.scheme_name_ru,
    evs.min_duration_days,
    evc.continuous_period_satisfied,
    
    -- Status assessment
    CASE 
        WHEN evc.remaining_days <= 7 THEN 'Критический остаток'
        WHEN evc.remaining_days <= 14 THEN 'Низкий остаток'
        WHEN evc.carry_over_expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'Истекает перенос'
        ELSE 'Нормальный статус'
    END as status_ru,
    
    CASE 
        WHEN evc.remaining_days <= 7 THEN 'Critical Balance'
        WHEN evc.remaining_days <= 14 THEN 'Low Balance'
        WHEN evc.carry_over_expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'Carry-over Expiring'
        ELSE 'Normal Status'
    END as status_en,
    
    -- Optimization suggestions
    evc.optimal_vacation_plan,
    evc.holiday_optimization_suggestions

FROM employees e
LEFT JOIN departments d ON e.department_id::text = d.department_id  
JOIN employee_vacation_calculations evc ON e.id = evc.employee_id
JOIN enhanced_vacation_schemes evs ON evc.scheme_id = evs.scheme_id
WHERE evc.calculation_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND evc.calculation_status = 'current'
ORDER BY (e.first_name || ' ' || e.last_name);

-- Employee preference satisfaction dashboard
CREATE VIEW v_employee_preference_satisfaction AS
SELECT 
    e.id as employee_id,
    (e.first_name || ' ' || e.last_name) as employee_name,
    d.department_name,
    
    -- Overall satisfaction metrics
    COUNT(ep.id) as total_preferences,
    AVG(ep.optimization_score) as avg_satisfaction_score,
    
    -- Satisfaction by category
    AVG(CASE WHEN pt.category = 'shift_preferences' THEN ep.optimization_score END) as shift_satisfaction,
    AVG(CASE WHEN pt.category = 'vacation_preferences' THEN ep.optimization_score END) as vacation_satisfaction,
    AVG(CASE WHEN pt.category = 'skill_preferences' THEN ep.optimization_score END) as skill_satisfaction,
    AVG(CASE WHEN pt.category = 'environment_preferences' THEN ep.optimization_score END) as environment_satisfaction,
    
    -- Flexibility and priority analysis
    AVG(ep.flexibility_factor) as avg_flexibility,
    COUNT(CASE WHEN ep.priority = 'high' OR ep.priority = 'critical' THEN 1 END) as high_priority_preferences,
    
    -- Status distribution
    COUNT(CASE WHEN ep.status = 'active' THEN 1 END) as active_preferences,
    COUNT(CASE WHEN ep.status = 'conflicted' THEN 1 END) as conflicted_preferences,
    
    -- Improvement opportunities
    COUNT(CASE WHEN ep.optimization_score < ep.satisfaction_threshold THEN 1 END) as below_threshold_count

FROM employees e
LEFT JOIN departments d ON e.department_id::text = d.department_id
LEFT JOIN employee_integrated_preferences ep ON e.id = ep.employee_id 
    AND ep.status = 'active'
    AND ep.effective_date <= CURRENT_DATE
    AND (ep.expiry_date IS NULL OR ep.expiry_date > CURRENT_DATE)
LEFT JOIN integrated_preference_types pt ON ep.type_id = pt.type_id
GROUP BY e.id, e.first_name, e.last_name, d.department_name
ORDER BY avg_satisfaction_score DESC NULLS LAST;

-- Schedule optimization performance analytics
CREATE VIEW v_schedule_optimization_analytics AS
SELECT 
    ast.template_id,
    ast.template_name_ru,
    ast.template_type,
    ast.primary_algorithm,
    
    -- Usage statistics
    ast.usage_count,
    COUNT(sor.id) as optimization_runs,
    
    -- Performance metrics
    AVG(sor.execution_time_ms) as avg_execution_time_ms,
    AVG(sor.overall_score) as avg_quality_score,
    AVG(sor.satisfaction_score) as avg_satisfaction_score,
    AVG(sor.preference_fulfillment_rate) as avg_preference_fulfillment,
    
    -- Success rates
    COUNT(CASE WHEN sor.convergence_achieved THEN 1 END)::DECIMAL / COUNT(sor.id) * 100 as convergence_rate,
    COUNT(CASE WHEN sor.validation_status = 'approved' THEN 1 END)::DECIMAL / COUNT(sor.id) * 100 as approval_rate,
    COUNT(CASE WHEN sor.implementation_status = 'completed' THEN 1 END)::DECIMAL / COUNT(sor.id) * 100 as implementation_rate,
    
    -- Recent performance
    AVG(CASE WHEN sor.optimization_date >= CURRENT_DATE - INTERVAL '30 days' THEN sor.overall_score END) as recent_quality,
    
    -- Holiday integration effectiveness
    AVG(jsonb_array_length(COALESCE(sor.holiday_adjustments_made, '[]'::jsonb))) as avg_holiday_adjustments

FROM advanced_schedule_templates ast
LEFT JOIN schedule_optimization_results sor ON ast.template_id = sor.template_id
WHERE ast.is_active = true
GROUP BY ast.template_id, ast.template_name_ru, ast.template_type, ast.primary_algorithm, ast.usage_count
ORDER BY avg_quality_score DESC NULLS LAST;

-- =============================================================================
-- SAMPLE DATA FOR TESTING AND DEMONSTRATION
-- =============================================================================

-- Insert Russian production calendar for 2025
INSERT INTO russian_production_calendar (calendar_id, calendar_year, work_days, holidays, pre_holidays) VALUES
('ru_calendar_2025', 2025, 
 '["2025-01-02", "2025-01-03", "2025-01-06", "2025-01-07", "2025-01-08"]'::jsonb,
 '["2025-01-01", "2025-01-02", "2025-01-03", "2025-01-06", "2025-01-07", "2025-01-08", "2025-02-23", "2025-03-08", "2025-05-01", "2025-05-09", "2025-06-12", "2025-11-04"]'::jsonb,
 '["2025-02-22", "2025-03-07", "2025-04-30", "2025-05-08", "2025-06-11", "2025-11-03"]'::jsonb);

-- Insert major Russian holidays for 2025
INSERT INTO russian_holiday_specifications (holiday_id, calendar_year, holiday_name_ru, holiday_name_en, holiday_date, holiday_type) VALUES
('new_year_2025', 2025, 'Новогодние праздники', 'New Year Holidays', '2025-01-01', 'federal'),
('defender_day_2025', 2025, 'День защитника Отечества', 'Defender of the Fatherland Day', '2025-02-23', 'federal'),
('womens_day_2025', 2025, 'Международный женский день', 'International Women''s Day', '2025-03-08', 'federal'),
('labor_day_2025', 2025, 'Праздник Весны и Труда', 'Spring and Labor Day', '2025-05-01', 'federal'),
('victory_day_2025', 2025, 'День Победы', 'Victory Day', '2025-05-09', 'federal'),
('russia_day_2025', 2025, 'День России', 'Russia Day', '2025-06-12', 'federal'),
('unity_day_2025', 2025, 'День народного единства', 'Unity Day', '2025-11-04', 'federal');

-- Insert enhanced vacation schemes
INSERT INTO enhanced_vacation_schemes (scheme_id, scheme_name_ru, scheme_name_en, annual_vacation_days, max_periods_per_year, russian_labor_code_compliant, created_by) VALUES
('standard_ru', 'Стандартная схема отпусков', 'Standard Vacation Scheme', 28, 2, true, (SELECT id FROM employees LIMIT 1)),
('senior_ru', 'Схема для старших сотрудников', 'Senior Employee Scheme', 35, 3, true, (SELECT id FROM employees LIMIT 1)),
('management_ru', 'Управленческая схема', 'Management Scheme', 42, 4, true, (SELECT id FROM employees LIMIT 1));

-- Insert preference types with Russian localization
INSERT INTO integrated_preference_types (type_id, type_name_ru, type_name_en, category, optimization_weight) VALUES
('shift_start_time', 'Предпочитаемое время начала смены', 'Preferred Shift Start Time', 'shift_preferences', 8.0),
('vacation_period', 'Предпочитаемый период отпуска', 'Preferred Vacation Period', 'vacation_preferences', 7.0),
('skill_development', 'Развитие навыков', 'Skill Development', 'skill_preferences', 6.0),
('work_location', 'Место работы', 'Work Location', 'environment_preferences', 5.0),
('team_collaboration', 'Командная работа', 'Team Collaboration', 'environment_preferences', 6.5);

-- Insert schedule templates
INSERT INTO advanced_schedule_templates (template_id, template_name_ru, template_name_en, template_type, schedule_pattern, shift_definitions, coverage_requirements, created_by) VALUES
('call_center_24x7', 'Колл-центр 24/7', 'Call Center 24/7', 'weekly',
 '{"pattern_type": "continuous", "hours_per_day": 24, "days_per_week": 7}'::jsonb,
 '{"morning": {"start": "08:00", "duration": 8}, "evening": {"start": "16:00", "duration": 8}, "night": {"start": "00:00", "duration": 8}}'::jsonb,
 '{"minimum_agents_per_shift": 5, "peak_coverage_multiplier": 1.5}'::jsonb,
 (SELECT id FROM employees LIMIT 1));

-- Insert resource allocation model
INSERT INTO resource_allocation_models (model_id, model_name_ru, model_name_en, allocation_type, planning_horizon, resource_types, capacity_definitions, demand_patterns, hard_constraints, business_rules, created_by) VALUES
('multi_skill_optimization', 'Многонавыковая оптимизация', 'Multi-Skill Optimization', 'hybrid', 'weekly',
 '{"skills": ["customer_service", "technical_support", "sales"], "equipment": ["workstation", "headset"], "locations": ["moscow", "spb"]}'::jsonb,
 '{"agents_per_skill": {"customer_service": 20, "technical_support": 15, "sales": 10}}'::jsonb,
 '{"peak_hours": ["09:00-12:00", "14:00-17:00"], "seasonal_factors": {"winter": 1.2, "summer": 0.8}}'::jsonb,
 '{"minimum_coverage": 0.8, "max_overtime": 0.15}'::jsonb,
 '{"skill_matching": true, "coverage_requirements": true}'::jsonb,
 (SELECT id FROM employees LIMIT 1));

-- =============================================================================
-- BUSINESS LOGIC FUNCTIONS
-- =============================================================================

-- Function to suggest optimal vacation periods considering Russian holidays
CREATE OR REPLACE FUNCTION suggest_optimal_vacation_periods(
    employee_id_param UUID,
    target_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    vacation_days_needed INTEGER DEFAULT 14
)
RETURNS TABLE (
    suggested_start_date DATE,
    suggested_end_date DATE,
    total_calendar_days INTEGER,
    work_days_used INTEGER,
    holiday_benefits INTEGER,
    optimization_score DECIMAL(3,2),
    suggestion_reason TEXT
) AS $$
DECLARE
    holiday_period RECORD;
    suggestion RECORD;
    base_date DATE;
    max_score DECIMAL(3,2) := 0;
BEGIN
    -- Analyze holiday periods for optimal vacation placement
    FOR holiday_period IN
        SELECT 
            rhs.holiday_date,
            rhs.holiday_name_ru,
            rhs.extends_vacation,
            rhs.creates_bridge
        FROM russian_holiday_specifications rhs
        WHERE rhs.calendar_year = target_year
          AND rhs.extends_vacation = true
        ORDER BY rhs.holiday_date
    LOOP
        -- Calculate vacation period around each major holiday
        base_date := holiday_period.holiday_date - INTERVAL '7 days';
        
        -- Return suggestion with scoring
        suggested_start_date := base_date;
        suggested_end_date := base_date + vacation_days_needed;
        total_calendar_days := vacation_days_needed + 1;
        work_days_used := vacation_days_needed;
        holiday_benefits := CASE WHEN holiday_period.extends_vacation THEN 1 ELSE 0 END;
        optimization_score := 7.5 + (holiday_benefits * 2.0);
        suggestion_reason := 'Период включает праздник: ' || holiday_period.holiday_name_ru;
        
        RETURN NEXT;
    END LOOP;
    
    -- Add general suggestions for optimal periods
    FOR i IN 1..4 LOOP
        suggested_start_date := DATE(target_year || '-' || (i*3) || '-01');
        suggested_end_date := suggested_start_date + vacation_days_needed;
        total_calendar_days := vacation_days_needed + 1;
        work_days_used := vacation_days_needed;
        holiday_benefits := 0;
        optimization_score := 6.0;
        suggestion_reason := 'Стандартный оптимальный период';
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- API INTEGRATION SUPPORT
-- =============================================================================

-- Function to get comprehensive employee workforce data for API responses
CREATE OR REPLACE FUNCTION get_employee_workforce_summary(employee_id_param UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB := '{}'::JSONB;
    vacation_data JSONB;
    preference_data JSONB;
    satisfaction_data JSONB;
BEGIN
    -- Get vacation status
    SELECT jsonb_build_object(
        'total_entitlement', evc.total_entitlement_days,
        'remaining_days', evc.remaining_days,
        'holiday_extensions', evc.holiday_extensions,
        'optimization_suggestions', evc.holiday_optimization_suggestions,
        'scheme_name', evs.scheme_name_ru
    )
    INTO vacation_data
    FROM employee_vacation_calculations evc
    JOIN enhanced_vacation_schemes evs ON evc.scheme_id = evs.scheme_id
    WHERE evc.employee_id = employee_id_param
      AND evc.calculation_year = EXTRACT(YEAR FROM CURRENT_DATE);
    
    -- Get preference summary
    SELECT jsonb_agg(jsonb_build_object(
        'type', pt.type_name_ru,
        'category', pt.category,
        'satisfaction_score', ep.optimization_score,
        'priority', ep.priority,
        'flexibility', ep.flexibility_factor
    ))
    INTO preference_data
    FROM employee_integrated_preferences ep
    JOIN integrated_preference_types pt ON ep.type_id = pt.type_id
    WHERE ep.employee_id = employee_id_param
      AND ep.status = 'active';
    
    -- Get satisfaction metrics
    SELECT jsonb_build_object(
        'overall_satisfaction', pss.overall_satisfaction,
        'category_scores', pss.category_scores,
        'improvement_suggestions', pss.improvement_suggestions
    )
    INTO satisfaction_data
    FROM calculate_preference_satisfaction(employee_id_param) pss;
    
    -- Build comprehensive result
    result := jsonb_build_object(
        'employee_id', employee_id_param,
        'vacation_status', COALESCE(vacation_data, '{}'::JSONB),
        'preferences', COALESCE(preference_data, '[]'::JSONB),
        'satisfaction_metrics', COALESCE(satisfaction_data, '{}'::JSONB),
        'last_updated', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE russian_production_calendar IS 'BDD 28:12-30: Russian Federation production calendar with XML import validation';
COMMENT ON TABLE russian_holiday_specifications IS 'BDD 28:61-75: Holiday specifications with multilingual support and vacation integration';
COMMENT ON TABLE enhanced_vacation_schemes IS 'BDD 31:16-27: Enhanced vacation schemes with Russian labor law compliance';
COMMENT ON TABLE employee_vacation_calculations IS 'Employee vacation calculations with Russian calendar integration and optimization';
COMMENT ON TABLE integrated_preference_types IS 'BDD 24:24-29: Comprehensive preference types with optimization weights';
COMMENT ON TABLE employee_integrated_preferences IS 'BDD 24:51-61: Employee preferences with satisfaction tracking and optimization';
COMMENT ON TABLE advanced_schedule_templates IS 'BDD 24:42-61: Advanced schedule templates with multi-objective optimization';
COMMENT ON TABLE schedule_optimization_results IS 'Schedule optimization execution results with performance analytics';
COMMENT ON TABLE resource_allocation_models IS 'Comprehensive resource allocation models with preference integration';
COMMENT ON TABLE resource_allocation_executions IS 'Resource allocation execution tracking with detailed results';
COMMENT ON TABLE system_integration_status IS 'System integration health monitoring and status tracking';

COMMENT ON FUNCTION calculate_vacation_with_holidays IS 'Calculates vacation extensions based on Russian holiday calendar';
COMMENT ON FUNCTION calculate_preference_satisfaction IS 'Calculates comprehensive employee preference satisfaction scores';
COMMENT ON FUNCTION suggest_optimal_vacation_periods IS 'Suggests optimal vacation periods considering Russian holidays';
COMMENT ON FUNCTION get_employee_workforce_summary IS 'Returns comprehensive employee workforce data for API integration';

COMMENT ON VIEW v_employee_vacation_status_integrated IS 'Comprehensive vacation status with Russian calendar integration';
COMMENT ON VIEW v_employee_preference_satisfaction IS 'Employee preference satisfaction dashboard metrics';
COMMENT ON VIEW v_schedule_optimization_analytics IS 'Schedule optimization performance analytics and trends';