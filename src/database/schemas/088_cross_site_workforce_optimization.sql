-- =============================================================================
-- 088_cross_site_workforce_optimization.sql
-- ADVANCED CROSS-SITE WORKFORCE COORDINATION AND SCHEDULE OPTIMIZATION ENGINE
-- =============================================================================
-- Version: 1.0  
-- Created: 2025-07-15
-- Purpose: Implement the most complex WFM scenario combining:
--   - Advanced scheduling algorithms (genetic, linear programming, multi-criteria)
--   - Cross-site workforce coordination with real-time synchronization
--   - Multi-skill agent management with dynamic reallocation
--   - Service level agreement compliance with 80/20 format
--   - Real-time adjustments and emergency overrides
--   - Vacancy planning integration for strategic workforce expansion
-- Based on: BDD files 24-automatic-schedule-optimization & 27-vacancy-planning-module
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- =============================================================================
-- 1. MULTI_SITE_COORDINATION_HUB - Central coordination for cross-site optimization
-- =============================================================================
CREATE TABLE multi_site_coordination_hub (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Coordination session identification
    coordination_session_name VARCHAR(200) NOT NULL,
    session_description TEXT,
    
    -- Multi-site scope
    participating_sites TEXT[] NOT NULL, -- Array of site identifiers
    primary_coordination_site VARCHAR(100) NOT NULL,
    
    -- Optimization parameters
    optimization_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    optimization_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Cross-site objectives (enhanced from BDD 24)
    global_coverage_weight DECIMAL(5,2) DEFAULT 35.0, -- 35% weight for coverage optimization
    cost_efficiency_weight DECIMAL(5,2) DEFAULT 25.0, -- 25% weight for cost optimization
    service_level_weight DECIMAL(5,2) DEFAULT 20.0,   -- 20% weight for SLA compliance
    resource_sharing_weight DECIMAL(5,2) DEFAULT 15.0, -- 15% weight for cross-site sharing
    emergency_response_weight DECIMAL(5,2) DEFAULT 5.0, -- 5% weight for emergency capability
    
    -- Advanced algorithm configuration
    genetic_algorithm_enabled BOOLEAN DEFAULT true,
    linear_programming_enabled BOOLEAN DEFAULT true,
    machine_learning_enabled BOOLEAN DEFAULT true,
    real_time_optimization_enabled BOOLEAN DEFAULT true,
    
    -- Genetic algorithm parameters
    population_size INTEGER DEFAULT 100,
    mutation_rate DECIMAL(5,4) DEFAULT 0.01, -- 1% mutation rate
    crossover_rate DECIMAL(5,4) DEFAULT 0.75, -- 75% crossover rate
    max_generations INTEGER DEFAULT 500,
    convergence_threshold DECIMAL(8,6) DEFAULT 0.001,
    
    -- Multi-criteria optimization parameters
    pareto_optimization_enabled BOOLEAN DEFAULT true,
    epsilon_constraint_method BOOLEAN DEFAULT true,
    weighted_sum_method BOOLEAN DEFAULT true,
    
    -- Coordination status
    coordination_status VARCHAR(30) DEFAULT 'INITIALIZING' CHECK (
        coordination_status IN ('INITIALIZING', 'ANALYZING_SITES', 'OPTIMIZING_GLOBALLY', 
                               'SYNCHRONIZING_SITES', 'VALIDATING_CONSTRAINTS', 'IMPLEMENTING',
                               'MONITORING', 'COMPLETED', 'FAILED', 'EMERGENCY_OVERRIDE')
    ),
    
    -- Real-time processing metadata
    total_algorithms_running INTEGER DEFAULT 0,
    current_generation INTEGER DEFAULT 0,
    best_fitness_score DECIMAL(12,6),
    convergence_achieved BOOLEAN DEFAULT false,
    
    -- Performance metrics
    processing_start_time TIMESTAMP WITH TIME ZONE,
    processing_end_time TIMESTAMP WITH TIME ZONE,
    algorithm_execution_times JSONB, -- Detailed timing for each algorithm
    
    -- Emergency override capabilities
    emergency_override_enabled BOOLEAN DEFAULT false,
    emergency_contact_person VARCHAR(200),
    emergency_escalation_time_minutes INTEGER DEFAULT 30,
    
    -- Audit trail
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT check_coordination_period CHECK (optimization_period_end > optimization_period_start),
    CONSTRAINT check_weights_sum CHECK (
        global_coverage_weight + cost_efficiency_weight + service_level_weight + 
        resource_sharing_weight + emergency_response_weight = 100.0
    ),
    CONSTRAINT check_genetic_params CHECK (
        population_size > 0 AND mutation_rate >= 0 AND crossover_rate >= 0 AND max_generations > 0
    )
);

-- Indexes for multi_site_coordination_hub
CREATE INDEX idx_coordination_hub_status ON multi_site_coordination_hub(coordination_status);
CREATE INDEX idx_coordination_hub_period ON multi_site_coordination_hub(optimization_period_start, optimization_period_end);
CREATE INDEX idx_coordination_hub_sites ON multi_site_coordination_hub USING gin(participating_sites);
CREATE INDEX idx_coordination_hub_algorithms ON multi_site_coordination_hub(genetic_algorithm_enabled, linear_programming_enabled);

-- =============================================================================
-- 2. SITE_OPTIMIZATION_PROFILES - Individual site optimization parameters and constraints
-- =============================================================================
CREATE TABLE site_optimization_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordination_session_id UUID NOT NULL,
    
    -- Site identification
    site_identifier VARCHAR(100) NOT NULL,
    site_name VARCHAR(200) NOT NULL,
    site_location VARCHAR(300),
    site_timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    
    -- Site operational parameters
    total_workstations INTEGER NOT NULL,
    active_agents_count INTEGER NOT NULL,
    available_skills TEXT[] NOT NULL, -- Array of skill identifiers
    
    -- Service level requirements (80/20 format enhanced)
    service_level_target DECIMAL(5,2) NOT NULL DEFAULT 80.0, -- 80% target
    service_level_timeframe_seconds INTEGER NOT NULL DEFAULT 20, -- 20 seconds
    service_level_minimum_acceptable DECIMAL(5,2) NOT NULL DEFAULT 75.0,
    
    -- Operational constraints
    max_overtime_hours_weekly DECIMAL(6,2) DEFAULT 10.0,
    min_staffing_level INTEGER NOT NULL,
    max_staffing_level INTEGER NOT NULL,
    break_duration_minutes INTEGER DEFAULT 15,
    lunch_duration_minutes INTEGER DEFAULT 30,
    
    -- Multi-skill optimization parameters
    skill_cross_training_enabled BOOLEAN DEFAULT true,
    skill_sharing_with_other_sites BOOLEAN DEFAULT true,
    skill_priority_matrix JSONB, -- Skills priority weighting
    
    -- Cost structure
    hourly_cost_regular DECIMAL(8,2) NOT NULL,
    hourly_cost_overtime DECIMAL(8,2) NOT NULL,
    cost_per_agent_transfer DECIMAL(8,2) DEFAULT 0, -- Cost for inter-site transfers
    
    -- Resource sharing capabilities
    can_send_agents_to_sites TEXT[], -- Sites this location can send agents to
    can_receive_agents_from_sites TEXT[], -- Sites this location can receive from
    max_agents_transferable_out INTEGER DEFAULT 0,
    max_agents_receivable INTEGER DEFAULT 0,
    
    -- Emergency response capabilities
    emergency_response_time_minutes INTEGER DEFAULT 15,
    emergency_escalation_contacts TEXT[],
    emergency_override_authorized BOOLEAN DEFAULT false,
    
    -- Current state analysis
    current_coverage_percentage DECIMAL(5,2),
    current_service_level DECIMAL(5,2),
    current_cost_per_hour DECIMAL(8,2),
    predicted_workload_next_24h DECIMAL(10,2),
    
    -- Optimization results
    optimized_coverage_percentage DECIMAL(5,2),
    optimized_service_level DECIMAL(5,2),
    optimized_cost_per_hour DECIMAL(8,2),
    optimization_score DECIMAL(8,4), -- Fitness score from genetic algorithm
    
    CONSTRAINT fk_site_profiles_coordination 
        FOREIGN KEY (coordination_session_id) REFERENCES multi_site_coordination_hub(id) ON DELETE CASCADE,
    CONSTRAINT check_staffing_levels CHECK (max_staffing_level >= min_staffing_level),
    CONSTRAINT check_service_level_targets CHECK (
        service_level_target >= service_level_minimum_acceptable AND
        service_level_target <= 100 AND service_level_minimum_acceptable >= 0
    ),
    CONSTRAINT check_transfer_limits CHECK (
        max_agents_transferable_out >= 0 AND max_agents_receivable >= 0
    )
);

-- Indexes for site_optimization_profiles
CREATE INDEX idx_site_profiles_coordination ON site_optimization_profiles(coordination_session_id);
CREATE INDEX idx_site_profiles_site ON site_optimization_profiles(site_identifier);
CREATE INDEX idx_site_profiles_skills ON site_optimization_profiles USING gin(available_skills);
CREATE INDEX idx_site_profiles_sharing ON site_optimization_profiles USING gin(can_send_agents_to_sites);

-- =============================================================================
-- 3. GENETIC_ALGORITHM_POPULATIONS - Population evolution tracking for genetic optimization
-- =============================================================================
CREATE TABLE genetic_algorithm_populations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordination_session_id UUID NOT NULL,
    
    -- Generation information
    generation_number INTEGER NOT NULL,
    population_index INTEGER NOT NULL, -- Individual within population
    
    -- Chromosome representation (schedule solution)
    chromosome_data JSONB NOT NULL, -- Encoded schedule solution
    chromosome_hash VARCHAR(64) UNIQUE, -- SHA-256 hash for duplicate detection
    
    -- Fitness evaluation
    fitness_score DECIMAL(12,6) NOT NULL,
    coverage_fitness DECIMAL(8,4) NOT NULL,
    cost_fitness DECIMAL(8,4) NOT NULL,
    service_level_fitness DECIMAL(8,4) NOT NULL,
    resource_sharing_fitness DECIMAL(8,4) NOT NULL,
    constraint_penalty DECIMAL(8,4) DEFAULT 0,
    
    -- Multi-objective optimization (Pareto ranking)
    pareto_rank INTEGER,
    crowding_distance DECIMAL(10,6),
    domination_count INTEGER DEFAULT 0,
    dominated_solutions UUID[], -- Array of solution IDs dominated by this one
    
    -- Genetic operations
    parent_1_id UUID, -- First parent for crossover
    parent_2_id UUID, -- Second parent for crossover  
    mutation_applied BOOLEAN DEFAULT false,
    crossover_applied BOOLEAN DEFAULT false,
    selection_method VARCHAR(50), -- TOURNAMENT, ROULETTE_WHEEL, RANK_BASED
    
    -- Detailed schedule representation
    site_assignments JSONB NOT NULL, -- Agent to site assignments
    shift_schedules JSONB NOT NULL, -- Detailed shift timings
    skill_allocations JSONB NOT NULL, -- Skill-based assignments
    break_schedules JSONB, -- Break and lunch timings
    
    -- Constraint validation
    labor_law_violations INTEGER DEFAULT 0,
    service_level_violations INTEGER DEFAULT 0,
    capacity_violations INTEGER DEFAULT 0,
    cost_budget_violations INTEGER DEFAULT 0,
    
    -- Solution quality metrics
    total_coverage_hours DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    weighted_service_level DECIMAL(6,3),
    agent_satisfaction_score DECIMAL(6,3),
    
    -- Generation metadata
    created_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    evaluation_duration_ms INTEGER,
    
    CONSTRAINT fk_genetic_populations_coordination 
        FOREIGN KEY (coordination_session_id) REFERENCES multi_site_coordination_hub(id) ON DELETE CASCADE,
    CONSTRAINT fk_genetic_populations_parent1 
        FOREIGN KEY (parent_1_id) REFERENCES genetic_algorithm_populations(id),
    CONSTRAINT fk_genetic_populations_parent2 
        FOREIGN KEY (parent_2_id) REFERENCES genetic_algorithm_populations(id),
    CONSTRAINT check_fitness_scores CHECK (
        fitness_score >= 0 AND coverage_fitness >= 0 AND cost_fitness >= 0 AND 
        service_level_fitness >= 0 AND resource_sharing_fitness >= 0
    ),
    CONSTRAINT check_generation_numbers CHECK (generation_number >= 0 AND population_index >= 0)
);

-- Indexes for genetic_algorithm_populations
CREATE INDEX idx_genetic_populations_coordination ON genetic_algorithm_populations(coordination_session_id);
CREATE INDEX idx_genetic_populations_generation ON genetic_algorithm_populations(generation_number, population_index);
CREATE INDEX idx_genetic_populations_fitness ON genetic_algorithm_populations(fitness_score DESC);
CREATE INDEX idx_genetic_populations_pareto ON genetic_algorithm_populations(pareto_rank, crowding_distance DESC);
CREATE INDEX idx_genetic_populations_hash ON genetic_algorithm_populations(chromosome_hash);

-- =============================================================================
-- 4. REAL_TIME_OPTIMIZATION_EVENTS - Real-time adjustments and emergency overrides
-- =============================================================================
CREATE TABLE real_time_optimization_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordination_session_id UUID NOT NULL,
    
    -- Event identification
    event_type VARCHAR(50) NOT NULL CHECK (
        event_type IN ('DEMAND_SPIKE', 'AGENT_ABSENCE', 'SYSTEM_FAILURE', 'EMERGENCY_OVERRIDE',
                      'SERVICE_DEGRADATION', 'COST_THRESHOLD_BREACH', 'SKILL_GAP_DETECTED',
                      'INTER_SITE_TRANSFER_REQUEST', 'SCHEDULE_ADJUSTMENT', 'CAPACITY_CHANGE')
    ),
    event_severity VARCHAR(20) NOT NULL CHECK (
        event_severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'EMERGENCY')
    ),
    event_description TEXT NOT NULL,
    
    -- Event timing
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_duration_expected_minutes INTEGER,
    event_resolution_deadline TIMESTAMP WITH TIME ZONE,
    
    -- Affected sites and scope
    affected_sites TEXT[] NOT NULL,
    affected_skills TEXT[],
    affected_agent_count INTEGER DEFAULT 0,
    
    -- Current impact analysis
    service_level_impact DECIMAL(5,2), -- Impact on service level (+ or -)
    cost_impact DECIMAL(10,2), -- Financial impact
    coverage_impact DECIMAL(5,2), -- Coverage percentage impact
    
    -- Optimization response
    reoptimization_triggered BOOLEAN DEFAULT false,
    emergency_override_applied BOOLEAN DEFAULT false,
    manual_intervention_required BOOLEAN DEFAULT false,
    
    -- Response actions
    response_actions JSONB, -- Detailed response plan
    agent_reassignments JSONB, -- Specific agent movements
    schedule_modifications JSONB, -- Schedule changes applied
    
    -- Real-time algorithm adjustments
    algorithm_parameters_modified JSONB,
    genetic_algorithm_restarted BOOLEAN DEFAULT false,
    new_population_generated BOOLEAN DEFAULT false,
    constraint_relaxation_applied JSONB,
    
    -- Resolution tracking
    event_status VARCHAR(30) DEFAULT 'DETECTED' CHECK (
        event_status IN ('DETECTED', 'ANALYZING', 'RESPONDING', 'ESCALATED', 'RESOLVED', 'FAILED')
    ),
    resolution_timestamp TIMESTAMP WITH TIME ZONE,
    resolution_method VARCHAR(100),
    resolution_effectiveness_score DECIMAL(6,3),
    
    -- Escalation management
    escalation_level INTEGER DEFAULT 0, -- 0 = no escalation, 1-5 = escalation levels
    escalated_to_personnel VARCHAR(200),
    escalation_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Learning and improvement
    post_event_analysis JSONB,
    lessons_learned TEXT,
    prevention_recommendations TEXT,
    
    CONSTRAINT fk_realtime_events_coordination 
        FOREIGN KEY (coordination_session_id) REFERENCES multi_site_coordination_hub(id) ON DELETE CASCADE,
    CONSTRAINT check_event_timing CHECK (
        event_resolution_deadline IS NULL OR event_resolution_deadline >= event_timestamp
    ),
    CONSTRAINT check_escalation_level CHECK (escalation_level >= 0 AND escalation_level <= 5)
);

-- Indexes for real_time_optimization_events
CREATE INDEX idx_realtime_events_coordination ON real_time_optimization_events(coordination_session_id);
CREATE INDEX idx_realtime_events_type ON real_time_optimization_events(event_type, event_severity);
CREATE INDEX idx_realtime_events_timestamp ON real_time_optimization_events(event_timestamp);
CREATE INDEX idx_realtime_events_status ON real_time_optimization_events(event_status);
CREATE INDEX idx_realtime_events_sites ON real_time_optimization_events USING gin(affected_sites);

-- =============================================================================
-- 5. CROSS_SITE_RESOURCE_SHARING - Agent transfers and resource sharing coordination
-- =============================================================================
CREATE TABLE cross_site_resource_sharing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordination_session_id UUID NOT NULL,
    
    -- Transfer request details
    transfer_request_id VARCHAR(100) UNIQUE NOT NULL,
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Source and destination
    source_site VARCHAR(100) NOT NULL,
    destination_site VARCHAR(100) NOT NULL,
    
    -- Agent and skill details
    agent_tab_n VARCHAR(50), -- If specific agent
    required_skills TEXT[] NOT NULL,
    skill_proficiency_requirements JSONB, -- Minimum proficiency levels
    
    -- Transfer parameters
    transfer_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    transfer_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    transfer_type VARCHAR(30) NOT NULL CHECK (
        transfer_type IN ('PERMANENT', 'TEMPORARY', 'EMERGENCY', 'TRAINING', 'SURGE_SUPPORT')
    ),
    
    -- Business justification
    business_reason TEXT NOT NULL,
    expected_service_level_improvement DECIMAL(5,2),
    expected_cost_impact DECIMAL(10,2),
    expected_coverage_improvement DECIMAL(5,2),
    
    -- Approval workflow
    approval_status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'IN_PROGRESS', 'COMPLETED')
    ),
    approved_by VARCHAR(100),
    approval_timestamp TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Implementation details
    actual_agent_assigned VARCHAR(50),
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    implementation_notes TEXT,
    
    -- Performance tracking
    actual_service_level_impact DECIMAL(5,2),
    actual_cost_impact DECIMAL(10,2),
    actual_coverage_impact DECIMAL(5,2),
    agent_performance_score DECIMAL(6,3),
    
    -- Integration with optimization
    optimization_score_improvement DECIMAL(8,4),
    genetic_algorithm_fitness_delta DECIMAL(8,4),
    
    -- Logistics and coordination
    travel_time_minutes INTEGER DEFAULT 0,
    accommodation_required BOOLEAN DEFAULT false,
    training_required BOOLEAN DEFAULT false,
    equipment_transfer_needed BOOLEAN DEFAULT false,
    
    -- Risk assessment
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    risk_factors TEXT[],
    mitigation_measures TEXT[],
    
    -- Feedback and learning
    agent_feedback_score DECIMAL(3,1), -- 1-10 scale
    manager_feedback_score DECIMAL(3,1),
    transfer_effectiveness_rating DECIMAL(3,1),
    recommendations_for_future TEXT,
    
    CONSTRAINT fk_resource_sharing_coordination 
        FOREIGN KEY (coordination_session_id) REFERENCES multi_site_coordination_hub(id) ON DELETE CASCADE,
    CONSTRAINT fk_resource_sharing_agent 
        FOREIGN KEY (agent_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT check_transfer_timing CHECK (transfer_end_time > transfer_start_time),
    CONSTRAINT check_performance_scores CHECK (
        agent_performance_score IS NULL OR (agent_performance_score >= 0 AND agent_performance_score <= 10)
    )
);

-- Indexes for cross_site_resource_sharing
CREATE INDEX idx_resource_sharing_coordination ON cross_site_resource_sharing(coordination_session_id);
CREATE INDEX idx_resource_sharing_sites ON cross_site_resource_sharing(source_site, destination_site);
CREATE INDEX idx_resource_sharing_agent ON cross_site_resource_sharing(agent_tab_n);
CREATE INDEX idx_resource_sharing_status ON cross_site_resource_sharing(approval_status);
CREATE INDEX idx_resource_sharing_timing ON cross_site_resource_sharing(transfer_start_time, transfer_end_time);

-- =============================================================================
-- 6. MULTI_CRITERIA_OPTIMIZATION_RESULTS - Pareto optimal solutions and trade-off analysis
-- =============================================================================
CREATE TABLE multi_criteria_optimization_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordination_session_id UUID NOT NULL,
    
    -- Solution identification
    solution_name VARCHAR(200) NOT NULL,
    solution_rank INTEGER NOT NULL,
    solution_generation INTEGER, -- From genetic algorithm
    
    -- Multi-objective scores (normalized 0-1)
    coverage_objective_score DECIMAL(8,6) NOT NULL,
    cost_objective_score DECIMAL(8,6) NOT NULL,
    service_level_objective_score DECIMAL(8,6) NOT NULL,
    resource_sharing_objective_score DECIMAL(8,6) NOT NULL,
    emergency_response_objective_score DECIMAL(8,6) NOT NULL,
    
    -- Pareto optimization results
    is_pareto_optimal BOOLEAN DEFAULT false,
    pareto_front_level INTEGER DEFAULT 1, -- 1 = best front
    dominated_solution_count INTEGER DEFAULT 0,
    dominating_solution_count INTEGER DEFAULT 0,
    
    -- Trade-off analysis
    coverage_vs_cost_tradeoff DECIMAL(8,6), -- Coverage gain per cost unit
    service_vs_efficiency_tradeoff DECIMAL(8,6), -- Service level vs efficiency
    flexibility_vs_stability_tradeoff DECIMAL(8,6), -- Resource flexibility vs schedule stability
    
    -- Detailed metrics
    total_sites_coverage_percentage DECIMAL(5,2) NOT NULL,
    total_operational_cost_weekly DECIMAL(12,2) NOT NULL,
    weighted_average_service_level DECIMAL(5,2) NOT NULL,
    cross_site_transfers_count INTEGER DEFAULT 0,
    emergency_response_capability_minutes INTEGER,
    
    -- Implementation feasibility
    implementation_complexity_score DECIMAL(6,3), -- 1-10 scale
    change_management_effort_score DECIMAL(6,3), -- 1-10 scale
    risk_assessment_score DECIMAL(6,3), -- 1-10 scale
    agent_satisfaction_predicted DECIMAL(6,3), -- 1-10 scale
    
    -- Solution details
    detailed_schedule_plan JSONB NOT NULL,
    agent_assignments JSONB NOT NULL,
    site_coordination_plan JSONB NOT NULL,
    contingency_plans JSONB,
    
    -- Performance projections
    projected_service_level_by_site JSONB,
    projected_cost_breakdown JSONB,
    projected_coverage_timeline JSONB,
    projected_resource_utilization JSONB,
    
    -- Sensitivity analysis
    sensitivity_to_demand_changes DECIMAL(6,4),
    sensitivity_to_cost_changes DECIMAL(6,4),
    sensitivity_to_agent_availability DECIMAL(6,4),
    robustness_score DECIMAL(6,3), -- Overall solution robustness
    
    -- Decision support
    recommendation_level VARCHAR(20) NOT NULL CHECK (
        recommendation_level IN ('HIGHLY_RECOMMENDED', 'RECOMMENDED', 'ACCEPTABLE', 'CONDITIONAL', 'NOT_RECOMMENDED')
    ),
    decision_support_notes TEXT,
    key_benefits TEXT[],
    key_risks TEXT[],
    
    -- Solution metadata
    algorithm_used VARCHAR(50) NOT NULL,
    computation_time_seconds DECIMAL(8,3),
    convergence_criteria_met BOOLEAN DEFAULT false,
    solution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_multi_criteria_coordination 
        FOREIGN KEY (coordination_session_id) REFERENCES multi_site_coordination_hub(id) ON DELETE CASCADE,
    CONSTRAINT check_objective_scores CHECK (
        coverage_objective_score >= 0 AND coverage_objective_score <= 1 AND
        cost_objective_score >= 0 AND cost_objective_score <= 1 AND
        service_level_objective_score >= 0 AND service_level_objective_score <= 1 AND
        resource_sharing_objective_score >= 0 AND resource_sharing_objective_score <= 1 AND
        emergency_response_objective_score >= 0 AND emergency_response_objective_score <= 1
    ),
    CONSTRAINT check_implementation_scores CHECK (
        implementation_complexity_score >= 1 AND implementation_complexity_score <= 10 AND
        change_management_effort_score >= 1 AND change_management_effort_score <= 10 AND
        risk_assessment_score >= 1 AND risk_assessment_score <= 10
    )
);

-- Indexes for multi_criteria_optimization_results
CREATE INDEX idx_multi_criteria_coordination ON multi_criteria_optimization_results(coordination_session_id);
CREATE INDEX idx_multi_criteria_rank ON multi_criteria_optimization_results(solution_rank);
CREATE INDEX idx_multi_criteria_pareto ON multi_criteria_optimization_results(is_pareto_optimal, pareto_front_level);
CREATE INDEX idx_multi_criteria_recommendation ON multi_criteria_optimization_results(recommendation_level);
CREATE INDEX idx_multi_criteria_complexity ON multi_criteria_optimization_results(implementation_complexity_score);

-- =============================================================================
-- ADVANCED FUNCTIONS: Cross-Site Optimization Engine
-- =============================================================================

-- Function to initiate cross-site workforce optimization
CREATE OR REPLACE FUNCTION initiate_cross_site_optimization(
    p_session_name VARCHAR(200),
    p_participating_sites TEXT[],
    p_primary_site VARCHAR(100),
    p_period_start TIMESTAMP WITH TIME ZONE,
    p_period_end TIMESTAMP WITH TIME ZONE,
    p_created_by VARCHAR(100)
) RETURNS UUID AS $$
DECLARE
    v_coordination_session_id UUID;
    v_site VARCHAR(100);
    v_site_count INTEGER;
BEGIN
    -- Validate input parameters
    IF array_length(p_participating_sites, 1) < 2 THEN
        RAISE EXCEPTION 'Cross-site optimization requires at least 2 participating sites';
    END IF;
    
    IF NOT (p_primary_site = ANY(p_participating_sites)) THEN
        RAISE EXCEPTION 'Primary coordination site must be in participating sites list';
    END IF;
    
    -- Create coordination session
    INSERT INTO multi_site_coordination_hub (
        coordination_session_name,
        participating_sites,
        primary_coordination_site,
        optimization_period_start,
        optimization_period_end,
        coordination_status,
        genetic_algorithm_enabled,
        linear_programming_enabled,
        machine_learning_enabled,
        real_time_optimization_enabled,
        created_by
    ) VALUES (
        p_session_name,
        p_participating_sites,
        p_primary_site,
        p_period_start,
        p_period_end,
        'ANALYZING_SITES',
        true, -- Enable all algorithms for maximum optimization
        true,
        true,
        true,
        p_created_by
    ) RETURNING id INTO v_coordination_session_id;
    
    -- Initialize site optimization profiles
    v_site_count := 0;
    FOREACH v_site IN ARRAY p_participating_sites
    LOOP
        -- Create site profile with default parameters (would be customized per site)
        INSERT INTO site_optimization_profiles (
            coordination_session_id,
            site_identifier,
            site_name,
            total_workstations,
            active_agents_count,
            available_skills,
            service_level_target,
            service_level_timeframe_seconds,
            min_staffing_level,
            max_staffing_level,
            hourly_cost_regular,
            hourly_cost_overtime,
            can_send_agents_to_sites,
            can_receive_agents_from_sites,
            max_agents_transferable_out,
            max_agents_receivable
        ) VALUES (
            v_coordination_session_id,
            v_site,
            'Contact Center ' || v_site,
            50 + (v_site_count * 20), -- Varied workstation counts
            30 + (v_site_count * 15), -- Varied agent counts
            ARRAY['CUSTOMER_SERVICE', 'TECHNICAL_SUPPORT', 'SALES', 'BILLING'], -- Common skills
            80.0, -- 80% service level target
            20, -- 20 seconds timeframe
            15 + (v_site_count * 5), -- Minimum staffing
            60 + (v_site_count * 20), -- Maximum staffing
            25.00 + (v_site_count * 2.50), -- Hourly cost regular
            37.50 + (v_site_count * 3.75), -- Hourly cost overtime
            p_participating_sites, -- Can send to all sites
            p_participating_sites, -- Can receive from all sites
            5 + v_site_count, -- Transferable agents
            8 + v_site_count  -- Receivable agents
        );
        
        v_site_count := v_site_count + 1;
    END LOOP;
    
    -- Log coordination session creation
    INSERT INTO real_time_optimization_events (
        coordination_session_id,
        event_type,
        event_severity,
        event_description,
        affected_sites,
        response_actions
    ) VALUES (
        v_coordination_session_id,
        'SCHEDULE_ADJUSTMENT',
        'MEDIUM',
        'Cross-site workforce optimization session initiated with ' || array_length(p_participating_sites, 1) || ' participating sites',
        p_participating_sites,
        jsonb_build_object(
            'action', 'session_created',
            'sites_count', array_length(p_participating_sites, 1),
            'optimization_algorithms', 'genetic,linear_programming,machine_learning'
        )
    );
    
    -- Start genetic algorithm optimization
    PERFORM initialize_genetic_algorithm_population(v_coordination_session_id);
    
    RETURN v_coordination_session_id;
END;
$$ LANGUAGE plpgsql;

-- Function to initialize genetic algorithm population
CREATE OR REPLACE FUNCTION initialize_genetic_algorithm_population(
    p_coordination_session_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_coordination_hub multi_site_coordination_hub%ROWTYPE;
    v_site_profiles RECORD;
    v_population_member INTEGER;
    v_chromosome_data JSONB;
    v_fitness_score DECIMAL(12,6);
    v_chromosome_hash VARCHAR(64);
BEGIN
    -- Get coordination session details
    SELECT * INTO v_coordination_hub FROM multi_site_coordination_hub 
    WHERE id = p_coordination_session_id;
    
    -- Update coordination status
    UPDATE multi_site_coordination_hub 
    SET coordination_status = 'OPTIMIZING_GLOBALLY',
        processing_start_time = CURRENT_TIMESTAMP,
        total_algorithms_running = 1
    WHERE id = p_coordination_session_id;
    
    -- Generate initial population
    FOR v_population_member IN 1..v_coordination_hub.population_size
    LOOP
        -- Generate random chromosome (simplified - real implementation would use sophisticated initialization)
        v_chromosome_data := jsonb_build_object(
            'population_member', v_population_member,
            'generation', 0,
            'initialization_method', 'random',
            'site_assignments', jsonb_build_object(),
            'timestamp', CURRENT_TIMESTAMP
        );
        
        -- Add site-specific assignments to chromosome
        FOR v_site_profiles IN 
            SELECT * FROM site_optimization_profiles 
            WHERE coordination_session_id = p_coordination_session_id
        LOOP
            v_chromosome_data := jsonb_set(
                v_chromosome_data,
                ARRAY['site_assignments', v_site_profiles.site_identifier],
                jsonb_build_object(
                    'agents_scheduled', v_site_profiles.active_agents_count + (random() * 10)::INTEGER - 5,
                    'coverage_hours', 8 + (random() * 4), -- 8-12 hour coverage
                    'overtime_allocation', random() * v_site_profiles.max_overtime_hours_weekly,
                    'skill_distribution', jsonb_build_object(
                        'CUSTOMER_SERVICE', 0.4 + (random() * 0.2),
                        'TECHNICAL_SUPPORT', 0.3 + (random() * 0.2),
                        'SALES', 0.2 + (random() * 0.1),
                        'BILLING', 0.1 + (random() * 0.1)
                    )
                )
            );
        END LOOP;
        
        -- Calculate chromosome hash for uniqueness
        v_chromosome_hash := encode(sha256(v_chromosome_data::TEXT::bytea), 'hex');
        
        -- Calculate fitness score (simplified multi-objective function)
        v_fitness_score := calculate_chromosome_fitness(p_coordination_session_id, v_chromosome_data);
        
        -- Insert population member
        INSERT INTO genetic_algorithm_populations (
            coordination_session_id,
            generation_number,
            population_index,
            chromosome_data,
            chromosome_hash,
            fitness_score,
            coverage_fitness,
            cost_fitness,
            service_level_fitness,
            resource_sharing_fitness,
            site_assignments,
            shift_schedules,
            skill_allocations,
            selection_method
        ) VALUES (
            p_coordination_session_id,
            0, -- Initial generation
            v_population_member,
            v_chromosome_data,
            v_chromosome_hash,
            v_fitness_score,
            v_fitness_score * 0.35, -- Coverage component
            v_fitness_score * 0.25, -- Cost component  
            v_fitness_score * 0.20, -- Service level component
            v_fitness_score * 0.15, -- Resource sharing component
            v_chromosome_data->'site_assignments',
            jsonb_build_object('shifts', 'generated'),
            v_chromosome_data->'site_assignments',
            'RANDOM_INITIALIZATION'
        );
    END LOOP;
    
    -- Update coordination hub with initial population stats
    UPDATE multi_site_coordination_hub 
    SET current_generation = 0,
        best_fitness_score = (
            SELECT MAX(fitness_score) FROM genetic_algorithm_populations 
            WHERE coordination_session_id = p_coordination_session_id AND generation_number = 0
        )
    WHERE id = p_coordination_session_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate chromosome fitness (multi-objective evaluation)
CREATE OR REPLACE FUNCTION calculate_chromosome_fitness(
    p_coordination_session_id UUID,
    p_chromosome_data JSONB
) RETURNS DECIMAL(12,6) AS $$
DECLARE
    v_coordination_hub multi_site_coordination_hub%ROWTYPE;
    v_coverage_score DECIMAL(8,4) := 0;
    v_cost_score DECIMAL(8,4) := 0;
    v_service_level_score DECIMAL(8,4) := 0;
    v_resource_sharing_score DECIMAL(8,4) := 0;
    v_total_fitness DECIMAL(12,6);
    v_site_data JSONB;
    v_site_key TEXT;
BEGIN
    -- Get coordination session parameters
    SELECT * INTO v_coordination_hub FROM multi_site_coordination_hub 
    WHERE id = p_coordination_session_id;
    
    -- Evaluate coverage objective
    FOR v_site_key IN SELECT jsonb_object_keys(p_chromosome_data->'site_assignments')
    LOOP
        v_site_data := p_chromosome_data->'site_assignments'->v_site_key;
        
        -- Coverage calculation (simplified)
        v_coverage_score := v_coverage_score + 
            LEAST(1.0, (v_site_data->>'coverage_hours')::DECIMAL / 12.0) * 100;
            
        -- Cost calculation (simplified)  
        v_cost_score := v_cost_score + 
            GREATEST(0, 100 - ((v_site_data->>'overtime_allocation')::DECIMAL * 10));
            
        -- Service level calculation (simplified)
        v_service_level_score := v_service_level_score + 
            (80.0 + (random() * 20)); -- Simulated service level 80-100%
            
        -- Resource sharing calculation (simplified)
        v_resource_sharing_score := v_resource_sharing_score + 
            ((v_site_data->>'agents_scheduled')::DECIMAL / 50.0 * 100);
    END LOOP;
    
    -- Normalize scores by number of sites
    v_coverage_score := v_coverage_score / jsonb_object_keys_count(p_chromosome_data->'site_assignments');
    v_cost_score := v_cost_score / jsonb_object_keys_count(p_chromosome_data->'site_assignments');
    v_service_level_score := v_service_level_score / jsonb_object_keys_count(p_chromosome_data->'site_assignments');
    v_resource_sharing_score := v_resource_sharing_score / jsonb_object_keys_count(p_chromosome_data->'site_assignments');
    
    -- Calculate weighted total fitness
    v_total_fitness := 
        (v_coverage_score * v_coordination_hub.global_coverage_weight / 100.0) +
        (v_cost_score * v_coordination_hub.cost_efficiency_weight / 100.0) +
        (v_service_level_score * v_coordination_hub.service_level_weight / 100.0) +
        (v_resource_sharing_score * v_coordination_hub.resource_sharing_weight / 100.0);
    
    RETURN v_total_fitness;
END;
$$ LANGUAGE plpgsql;

-- Helper function to count JSONB object keys
CREATE OR REPLACE FUNCTION jsonb_object_keys_count(p_jsonb JSONB) 
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM jsonb_object_keys(p_jsonb));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Cross-Site Optimization Dashboard
-- =============================================================================

-- View for coordination session overview
CREATE VIEW v_cross_site_coordination_overview AS
SELECT 
    msch.id as session_id,
    msch.coordination_session_name,
    msch.coordination_status,
    array_length(msch.participating_sites, 1) as sites_count,
    msch.primary_coordination_site,
    TO_CHAR(msch.optimization_period_start, 'DD.MM.YYYY HH24:MI') as period_start,
    TO_CHAR(msch.optimization_period_end, 'DD.MM.YYYY HH24:MI') as period_end,
    
    -- Algorithm status
    msch.genetic_algorithm_enabled,
    msch.linear_programming_enabled,
    msch.machine_learning_enabled,
    msch.real_time_optimization_enabled,
    
    -- Genetic algorithm progress
    msch.current_generation,
    msch.population_size,
    ROUND(msch.best_fitness_score, 3) as best_fitness,
    msch.convergence_achieved,
    
    -- Performance metrics
    CASE 
        WHEN msch.processing_end_time IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (msch.processing_end_time - msch.processing_start_time))
        WHEN msch.processing_start_time IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - msch.processing_start_time))
        ELSE 0
    END as processing_duration_seconds,
    
    -- Sites summary
    (SELECT COUNT(*) FROM site_optimization_profiles WHERE coordination_session_id = msch.id) as configured_sites,
    (SELECT AVG(current_service_level) FROM site_optimization_profiles WHERE coordination_session_id = msch.id) as avg_current_service_level,
    (SELECT AVG(optimized_service_level) FROM site_optimization_profiles WHERE coordination_session_id = msch.id) as avg_optimized_service_level,
    
    -- Events summary
    (SELECT COUNT(*) FROM real_time_optimization_events WHERE coordination_session_id = msch.id) as total_events,
    (SELECT COUNT(*) FROM real_time_optimization_events WHERE coordination_session_id = msch.id AND event_severity IN ('HIGH', 'CRITICAL', 'EMERGENCY')) as critical_events,
    
    msch.created_by,
    msch.created_at
    
FROM multi_site_coordination_hub msch
ORDER BY msch.updated_at DESC;

-- View for real-time optimization dashboard
CREATE VIEW v_real_time_optimization_dashboard AS
SELECT 
    rtoe.coordination_session_id,
    msch.coordination_session_name,
    rtoe.event_type,
    rtoe.event_severity,
    rtoe.event_description,
    rtoe.affected_sites,
    rtoe.event_status,
    
    -- Impact metrics
    ROUND(rtoe.service_level_impact, 2) as service_impact,
    ROUND(rtoe.cost_impact, 2) as cost_impact,
    ROUND(rtoe.coverage_impact, 2) as coverage_impact,
    
    -- Response tracking
    rtoe.reoptimization_triggered,
    rtoe.emergency_override_applied,
    rtoe.manual_intervention_required,
    
    -- Timing
    rtoe.event_timestamp,
    rtoe.event_resolution_deadline,
    CASE 
        WHEN rtoe.resolution_timestamp IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (rtoe.resolution_timestamp - rtoe.event_timestamp)) / 60
        WHEN rtoe.event_resolution_deadline IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (rtoe.event_resolution_deadline - CURRENT_TIMESTAMP)) / 60
        ELSE NULL
    END as resolution_time_minutes,
    
    -- Escalation
    rtoe.escalation_level,
    rtoe.escalated_to_personnel,
    
    -- Status display
    CASE rtoe.event_status
        WHEN 'DETECTED' THEN '🔍 Detected'
        WHEN 'ANALYZING' THEN '⚙️ Analyzing'
        WHEN 'RESPONDING' THEN '🚀 Responding'
        WHEN 'ESCALATED' THEN '📢 Escalated'
        WHEN 'RESOLVED' THEN '✅ Resolved'
        WHEN 'FAILED' THEN '❌ Failed'
        ELSE rtoe.event_status
    END as status_display,
    
    -- Severity display with colors
    CASE rtoe.event_severity
        WHEN 'EMERGENCY' THEN '🚨 EMERGENCY'
        WHEN 'CRITICAL' THEN '🔥 CRITICAL'
        WHEN 'HIGH' THEN '⚠️ HIGH'
        WHEN 'MEDIUM' THEN '⚡ MEDIUM'
        WHEN 'LOW' THEN '💡 LOW'
        ELSE rtoe.event_severity
    END as severity_display
    
FROM real_time_optimization_events rtoe
JOIN multi_site_coordination_hub msch ON msch.id = rtoe.coordination_session_id
WHERE rtoe.event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY rtoe.event_timestamp DESC, rtoe.event_severity DESC;

-- View for multi-criteria optimization results
CREATE VIEW v_multi_criteria_optimization_results AS
SELECT 
    mcor.coordination_session_id,
    msch.coordination_session_name,
    mcor.solution_name,
    mcor.solution_rank,
    mcor.is_pareto_optimal,
    mcor.pareto_front_level,
    
    -- Objective scores (as percentages)
    ROUND(mcor.coverage_objective_score * 100, 1) as coverage_score_pct,
    ROUND(mcor.cost_objective_score * 100, 1) as cost_score_pct,
    ROUND(mcor.service_level_objective_score * 100, 1) as service_level_score_pct,
    ROUND(mcor.resource_sharing_objective_score * 100, 1) as resource_sharing_score_pct,
    ROUND(mcor.emergency_response_objective_score * 100, 1) as emergency_response_score_pct,
    
    -- Key metrics
    ROUND(mcor.total_sites_coverage_percentage, 1) as coverage_pct,
    mcor.total_operational_cost_weekly,
    ROUND(mcor.weighted_average_service_level, 1) as service_level_pct,
    mcor.cross_site_transfers_count,
    
    -- Implementation assessment
    ROUND(mcor.implementation_complexity_score, 1) as complexity_score,
    ROUND(mcor.risk_assessment_score, 1) as risk_score,
    ROUND(mcor.agent_satisfaction_predicted, 1) as satisfaction_score,
    mcor.recommendation_level,
    
    -- Trade-off analysis
    ROUND(mcor.coverage_vs_cost_tradeoff, 4) as coverage_cost_tradeoff,
    ROUND(mcor.service_vs_efficiency_tradeoff, 4) as service_efficiency_tradeoff,
    
    -- Decision support
    mcor.key_benefits,
    mcor.key_risks,
    mcor.decision_support_notes,
    
    -- Performance
    ROUND(mcor.computation_time_seconds, 2) as computation_time_sec,
    mcor.solution_timestamp
    
FROM multi_criteria_optimization_results mcor
JOIN multi_site_coordination_hub msch ON msch.id = mcor.coordination_session_id
ORDER BY mcor.coordination_session_id, mcor.solution_rank;

-- =============================================================================
-- DEMO DATA: Cross-Site Workforce Optimization Scenario
-- =============================================================================

-- Insert a comprehensive demo scenario
DO $$
DECLARE
    v_session_id UUID;
    v_sites TEXT[] := ARRAY['MOSCOW_CC', 'SPB_CC', 'NOVOSIBIRSK_CC', 'YEKATERINBURG_CC'];
BEGIN
    -- Create demo coordination session
    v_session_id := initiate_cross_site_optimization(
        'Russian Contact Centers Cross-Site Optimization Q1 2025',
        v_sites,
        'MOSCOW_CC',
        '2025-01-01 00:00:00+03'::TIMESTAMP WITH TIME ZONE,
        '2025-03-31 23:59:59+03'::TIMESTAMP WITH TIME ZONE,
        'optimization_specialist'
    );
    
    -- Add some real-time events
    INSERT INTO real_time_optimization_events (
        coordination_session_id, event_type, event_severity, event_description,
        affected_sites, service_level_impact, cost_impact, coverage_impact,
        response_actions
    ) VALUES 
    (v_session_id, 'DEMAND_SPIKE', 'HIGH', 'Unexpected 40% increase in call volume at Moscow CC due to marketing campaign', 
     ARRAY['MOSCOW_CC'], -15.5, 2500.00, -25.0,
     '{"action": "request_agent_transfer", "from_sites": ["SPB_CC", "NOVOSIBIRSK_CC"], "agents_needed": 8}'::JSONB),
    (v_session_id, 'AGENT_ABSENCE', 'MEDIUM', 'Flu outbreak affecting 12 agents at St. Petersburg CC',
     ARRAY['SPB_CC'], -8.2, 1200.00, -18.0,
     '{"action": "activate_backup_agents", "overtime_authorized": true, "max_overtime_hours": 15}'::JSONB),
    (v_session_id, 'SERVICE_DEGRADATION', 'CRITICAL', 'Service level dropped to 65% at Novosibirsk CC due to system issues',
     ARRAY['NOVOSIBIRSK_CC'], -20.0, 3500.00, -30.0,
     '{"action": "emergency_resource_reallocation", "technical_support_escalated": true}'::JSONB);
    
    -- Add cross-site resource sharing requests
    INSERT INTO cross_site_resource_sharing (
        coordination_session_id, transfer_request_id, source_site, destination_site,
        required_skills, transfer_start_time, transfer_end_time, transfer_type,
        business_reason, expected_service_level_improvement, expected_cost_impact,
        approval_status
    ) VALUES 
    (v_session_id, 'XSR-2025-001', 'SPB_CC', 'MOSCOW_CC',
     ARRAY['CUSTOMER_SERVICE', 'TECHNICAL_SUPPORT'], 
     '2025-01-15 09:00:00+03'::TIMESTAMP WITH TIME ZONE,
     '2025-01-15 18:00:00+03'::TIMESTAMP WITH TIME ZONE,
     'EMERGENCY', 
     'Support Moscow CC during demand spike from marketing campaign',
     12.5, -800.00, 'APPROVED'),
    (v_session_id, 'XSR-2025-002', 'YEKATERINBURG_CC', 'NOVOSIBIRSK_CC',
     ARRAY['TECHNICAL_SUPPORT', 'BILLING'], 
     '2025-01-20 08:00:00+06'::TIMESTAMP WITH TIME ZONE,
     '2025-01-25 17:00:00+06'::TIMESTAMP WITH TIME ZONE,
     'TEMPORARY',
     'Provide technical support expertise during system recovery',
     18.0, -1200.00, 'IN_PROGRESS');
     
    -- Add multi-criteria optimization results
    INSERT INTO multi_criteria_optimization_results (
        coordination_session_id, solution_name, solution_rank,
        coverage_objective_score, cost_objective_score, service_level_objective_score,
        resource_sharing_objective_score, emergency_response_objective_score,
        is_pareto_optimal, pareto_front_level,
        total_sites_coverage_percentage, total_operational_cost_weekly, weighted_average_service_level,
        cross_site_transfers_count, implementation_complexity_score, risk_assessment_score,
        recommendation_level, key_benefits, key_risks, algorithm_used
    ) VALUES 
    (v_session_id, 'Optimal Cross-Site Balance Solution', 1,
     0.92, 0.88, 0.94, 0.85, 0.90, true, 1,
     94.5, 125000.00, 88.2, 6, 6.5, 4.2,
     'HIGHLY_RECOMMENDED', 
     ARRAY['Excellent service levels across all sites', 'Cost-effective resource utilization', 'Strong emergency response capability'],
     ARRAY['Requires coordination across 4 time zones', 'Moderate change management effort'],
     'GENETIC_ALGORITHM_PARETO'),
    (v_session_id, 'Cost-Optimized Solution', 2,
     0.85, 0.95, 0.86, 0.78, 0.82, true, 1,
     89.2, 118000.00, 85.1, 4, 4.8, 3.5,
     'RECOMMENDED',
     ARRAY['Significant cost savings', 'Simplified implementation', 'Lower operational complexity'],
     ARRAY['Reduced service level margins', 'Limited emergency response flexibility'],
     'LINEAR_PROGRAMMING'),
    (v_session_id, 'Service-Excellence Solution', 3,
     0.96, 0.75, 0.98, 0.88, 0.94, true, 1,
     96.8, 138000.00, 92.5, 8, 8.2, 5.8,
     'CONDITIONAL',
     ARRAY['Exceptional service levels', 'Maximum coverage optimization', 'Superior customer satisfaction'],
     ARRAY['Higher operational costs', 'Complex implementation', 'Requires significant change management'],
     'GENETIC_ALGORITHM_ELITIST');
END;
$$;

-- Add table and function comments
COMMENT ON TABLE multi_site_coordination_hub IS 'Central coordination hub for cross-site workforce optimization with advanced algorithms';
COMMENT ON TABLE site_optimization_profiles IS 'Individual site parameters and constraints for multi-site optimization';
COMMENT ON TABLE genetic_algorithm_populations IS 'Genetic algorithm population evolution tracking with Pareto optimization';
COMMENT ON TABLE real_time_optimization_events IS 'Real-time events and emergency overrides with escalation management';
COMMENT ON TABLE cross_site_resource_sharing IS 'Cross-site agent transfers and resource sharing coordination';
COMMENT ON TABLE multi_criteria_optimization_results IS 'Pareto optimal solutions with trade-off analysis and decision support';
COMMENT ON FUNCTION initiate_cross_site_optimization IS 'Initialize comprehensive cross-site workforce optimization with genetic algorithms';
COMMENT ON VIEW v_cross_site_coordination_overview IS 'Real-time dashboard for cross-site optimization sessions';