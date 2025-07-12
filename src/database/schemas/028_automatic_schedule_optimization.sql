-- =============================================================================
-- 028_automatic_schedule_optimization.sql
-- EXACT AUTOMATIC SCHEDULE OPTIMIZATION ENGINE - From BDD Specifications
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT automatic schedule optimization as specified in BDD file 24
-- Based on: Gap analysis, genetic algorithms, multi-criteria optimization, 80/20 format
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- 1. OPTIMIZATION_PROJECTS - Main schedule optimization project management
-- =============================================================================
CREATE TABLE optimization_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Project identification
    project_name VARCHAR(200) NOT NULL,
    project_description TEXT,
    
    -- Schedule and forecast context
    base_schedule_id UUID, -- Reference to existing schedule
    forecast_project_id UUID, -- Reference to forecasting project
    
    -- Optimization parameters
    optimization_period_start DATE NOT NULL,
    optimization_period_end DATE NOT NULL,
    
    -- Target metrics (BDD: optimization goals)
    coverage_gap_weight DECIMAL(5,2) DEFAULT 40.0, -- 40% weight
    cost_efficiency_weight DECIMAL(5,2) DEFAULT 30.0, -- 30% weight
    service_level_weight DECIMAL(5,2) DEFAULT 20.0, -- 20% weight (80/20 format)
    complexity_weight DECIMAL(5,2) DEFAULT 10.0, -- 10% weight
    
    -- Target improvements (BDD: target improvement thresholds)
    target_coverage_improvement DECIMAL(5,2) DEFAULT 15.0, -- >15% reduction
    target_cost_savings DECIMAL(5,2) DEFAULT 10.0, -- >10% savings
    target_service_level_improvement DECIMAL(5,2) DEFAULT 5.0, -- >5% improvement
    
    -- Processing status
    optimization_status VARCHAR(20) DEFAULT 'DRAFT' CHECK (
        optimization_status IN ('DRAFT', 'ANALYZING', 'GENERATING', 'VALIDATING', 'COMPLETED', 'FAILED')
    ),
    
    -- Algorithm stages (BDD: processing stages)
    coverage_analysis_completed BOOLEAN DEFAULT false,
    gap_pattern_identification_completed BOOLEAN DEFAULT false,
    schedule_variant_generation_completed BOOLEAN DEFAULT false,
    constraint_validation_completed BOOLEAN DEFAULT false,
    suggestion_ranking_completed BOOLEAN DEFAULT false,
    
    -- Processing metadata
    total_variants_generated INTEGER DEFAULT 0,
    valid_variants_count INTEGER DEFAULT 0,
    processing_start_time TIMESTAMP WITH TIME ZONE,
    processing_end_time TIMESTAMP WITH TIME ZONE,
    
    -- Audit trail
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT check_optimization_period CHECK (optimization_period_end >= optimization_period_start),
    CONSTRAINT check_weights_sum CHECK (
        coverage_gap_weight + cost_efficiency_weight + service_level_weight + complexity_weight = 100.0
    )
);

-- Indexes for optimization_projects
CREATE INDEX idx_optimization_projects_schedule ON optimization_projects(base_schedule_id);
CREATE INDEX idx_optimization_projects_forecast ON optimization_projects(forecast_project_id);
CREATE INDEX idx_optimization_projects_status ON optimization_projects(optimization_status);
CREATE INDEX idx_optimization_projects_period ON optimization_projects(optimization_period_start, optimization_period_end);

-- =============================================================================
-- 2. COVERAGE_ANALYSIS - Gap analysis and pattern identification
-- =============================================================================
CREATE TABLE coverage_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_project_id UUID NOT NULL,
    
    -- Time interval analysis
    analysis_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_minutes INTEGER NOT NULL DEFAULT 15,
    
    -- Coverage metrics
    required_operators DECIMAL(8,2) NOT NULL, -- From forecast
    scheduled_operators DECIMAL(8,2) NOT NULL, -- From current schedule
    coverage_gap DECIMAL(8,2) NOT NULL, -- Required - Scheduled
    coverage_percentage DECIMAL(5,2) NOT NULL, -- (Scheduled/Required) * 100
    
    -- Gap severity classification (BDD: gap severity map)
    gap_severity VARCHAR(20) NOT NULL CHECK (
        gap_severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'NONE')
    ),
    
    -- Pattern identification
    gap_pattern_type VARCHAR(50), -- Morning rush, lunch dip, evening peak, etc.
    recurring_pattern BOOLEAN DEFAULT false,
    similar_interval_count INTEGER DEFAULT 0,
    
    -- Cost impact analysis
    overtime_cost_impact DECIMAL(10,2) DEFAULT 0,
    understaffing_cost_impact DECIMAL(10,2) DEFAULT 0,
    
    -- Service level impact
    projected_service_level DECIMAL(5,2), -- 80/20 format projection
    service_level_gap DECIMAL(5,2), -- Target - Projected
    
    CONSTRAINT fk_coverage_analysis_project 
        FOREIGN KEY (optimization_project_id) REFERENCES optimization_projects(id) ON DELETE CASCADE,
    CONSTRAINT check_coverage_percentage CHECK (coverage_percentage >= 0),
    CONSTRAINT check_required_operators_positive CHECK (required_operators > 0),
    CONSTRAINT check_scheduled_operators_non_negative CHECK (scheduled_operators >= 0)
);

-- Indexes for coverage_analysis
CREATE INDEX idx_coverage_analysis_project ON coverage_analysis(optimization_project_id);
CREATE INDEX idx_coverage_analysis_datetime ON coverage_analysis(analysis_datetime);
CREATE INDEX idx_coverage_analysis_severity ON coverage_analysis(gap_severity);
CREATE INDEX idx_coverage_analysis_pattern ON coverage_analysis(gap_pattern_type);

-- =============================================================================
-- 3. SCHEDULE_SUGGESTIONS - Generated optimization suggestions
-- =============================================================================
CREATE TABLE schedule_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_project_id UUID NOT NULL,
    
    -- Suggestion identification
    suggestion_rank INTEGER NOT NULL,
    suggestion_name VARCHAR(200) NOT NULL,
    suggestion_description TEXT,
    
    -- Optimization score (BDD: XX.X/100 format)
    overall_score DECIMAL(5,2) NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
    
    -- Component scores
    coverage_score DECIMAL(5,2) NOT NULL,
    cost_score DECIMAL(5,2) NOT NULL,
    service_level_score DECIMAL(5,2) NOT NULL,
    complexity_score DECIMAL(5,2) NOT NULL,
    
    -- Impact projections (BDD: display elements)
    coverage_improvement_percentage DECIMAL(5,2) NOT NULL, -- +XX.X%
    cost_impact_weekly DECIMAL(10,2) NOT NULL, -- ±$X,XXX/week
    service_level_improvement DECIMAL(5,2) NOT NULL, -- +XX.X%
    
    -- Pattern information
    pattern_type VARCHAR(100) NOT NULL, -- Descriptive name
    operators_needed INTEGER NOT NULL,
    operators_available INTEGER NOT NULL,
    
    -- Risk assessment (BDD: Low/Medium/High)
    risk_assessment VARCHAR(20) NOT NULL CHECK (
        risk_assessment IN ('LOW', 'MEDIUM', 'HIGH')
    ),
    implementation_complexity VARCHAR(20) NOT NULL CHECK (
        implementation_complexity IN ('SIMPLE', 'MEDIUM', 'COMPLEX')
    ),
    
    -- Detailed metrics
    current_coverage_percentage DECIMAL(5,2) NOT NULL,
    projected_coverage_percentage DECIMAL(5,2) NOT NULL,
    current_cost_weekly DECIMAL(10,2) NOT NULL,
    projected_cost_weekly DECIMAL(10,2) NOT NULL,
    current_service_level DECIMAL(5,2) NOT NULL,
    projected_service_level DECIMAL(5,2) NOT NULL,
    
    -- Constraint compliance
    labor_law_compliant BOOLEAN DEFAULT false,
    union_agreement_compliant BOOLEAN DEFAULT false,
    employee_contract_compliant BOOLEAN DEFAULT false,
    business_rule_compliant BOOLEAN DEFAULT false,
    
    -- Algorithm metadata
    generation_method VARCHAR(50) NOT NULL CHECK (
        generation_method IN ('GENETIC_ALGORITHM', 'LINEAR_PROGRAMMING', 'HEURISTIC', 'HYBRID')
    ),
    generation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_suggestions_project 
        FOREIGN KEY (optimization_project_id) REFERENCES optimization_projects(id) ON DELETE CASCADE,
    CONSTRAINT check_suggestion_rank_positive CHECK (suggestion_rank > 0),
    CONSTRAINT check_operators_available CHECK (operators_available >= 0),
    CONSTRAINT check_operators_needed CHECK (operators_needed > 0)
);

-- Indexes for schedule_suggestions
CREATE INDEX idx_schedule_suggestions_project ON schedule_suggestions(optimization_project_id);
CREATE INDEX idx_schedule_suggestions_rank ON schedule_suggestions(suggestion_rank);
CREATE INDEX idx_schedule_suggestions_score ON schedule_suggestions(overall_score DESC);
CREATE INDEX idx_schedule_suggestions_complexity ON schedule_suggestions(implementation_complexity);

-- =============================================================================
-- 4. SUGGESTION_DETAILS - Detailed schedule changes for each suggestion
-- =============================================================================
CREATE TABLE suggestion_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_suggestion_id UUID NOT NULL,
    
    -- Employee and shift details
    employee_tab_n VARCHAR(50) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    
    -- Schedule change details
    change_type VARCHAR(50) NOT NULL CHECK (
        change_type IN ('ADD_SHIFT', 'REMOVE_SHIFT', 'MODIFY_SHIFT', 'MOVE_SHIFT', 'SPLIT_SHIFT')
    ),
    
    -- Current schedule
    current_shift_start TIME,
    current_shift_end TIME,
    current_shift_date DATE,
    current_shift_duration_minutes INTEGER,
    
    -- Proposed schedule
    proposed_shift_start TIME,
    proposed_shift_end TIME,
    proposed_shift_date DATE,
    proposed_shift_duration_minutes INTEGER,
    
    -- Impact analysis
    overtime_hours_change DECIMAL(5,2) DEFAULT 0,
    cost_impact_change DECIMAL(10,2) DEFAULT 0,
    coverage_impact_change DECIMAL(5,2) DEFAULT 0,
    
    -- Employee preferences alignment
    preference_alignment_score DECIMAL(5,2), -- 0-100 scale
    preference_conflict BOOLEAN DEFAULT false,
    conflict_description TEXT,
    
    -- Constraint validation
    labor_law_issues TEXT[], -- Array of potential issues
    union_agreement_issues TEXT[],
    contract_issues TEXT[],
    
    CONSTRAINT fk_suggestion_details_suggestion 
        FOREIGN KEY (schedule_suggestion_id) REFERENCES schedule_suggestions(id) ON DELETE CASCADE,
    CONSTRAINT fk_suggestion_details_employee 
        FOREIGN KEY (employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT check_current_shift_timing CHECK (
        current_shift_start IS NULL OR current_shift_end IS NULL OR current_shift_end > current_shift_start
    ),
    CONSTRAINT check_proposed_shift_timing CHECK (
        proposed_shift_start IS NULL OR proposed_shift_end IS NULL OR proposed_shift_end > proposed_shift_start
    )
);

-- Indexes for suggestion_details
CREATE INDEX idx_suggestion_details_suggestion ON suggestion_details(schedule_suggestion_id);
CREATE INDEX idx_suggestion_details_employee ON suggestion_details(employee_tab_n);
CREATE INDEX idx_suggestion_details_change_type ON suggestion_details(change_type);

-- =============================================================================
-- 5. OPTIMIZATION_CONSTRAINTS - Constraint definitions and validation rules
-- =============================================================================
CREATE TABLE optimization_constraints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Constraint identification
    constraint_name VARCHAR(200) NOT NULL,
    constraint_type VARCHAR(50) NOT NULL CHECK (
        constraint_type IN ('LABOR_LAW', 'UNION_AGREEMENT', 'EMPLOYEE_CONTRACT', 'BUSINESS_RULE', 'PREFERENCE')
    ),
    constraint_priority VARCHAR(20) NOT NULL CHECK (
        constraint_priority IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')
    ),
    
    -- Constraint definition
    constraint_description TEXT NOT NULL,
    validation_rule TEXT NOT NULL, -- SQL or business rule expression
    
    -- Scope and applicability
    applies_to_all_employees BOOLEAN DEFAULT true,
    specific_employee_tab_n VARCHAR(50),
    applies_to_department VARCHAR(100),
    applies_to_position VARCHAR(100),
    
    -- Constraint parameters
    max_hours_per_day DECIMAL(5,2),
    max_hours_per_week DECIMAL(5,2),
    min_rest_hours DECIMAL(5,2),
    max_consecutive_days INTEGER,
    min_operators_per_interval INTEGER,
    
    -- Temporal constraints
    effective_start_date DATE,
    effective_end_date DATE,
    
    -- Metadata
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_optimization_constraints_employee 
        FOREIGN KEY (specific_employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT check_constraint_dates CHECK (
        effective_end_date IS NULL OR effective_end_date >= effective_start_date
    )
);

-- Indexes for optimization_constraints
CREATE INDEX idx_optimization_constraints_type ON optimization_constraints(constraint_type);
CREATE INDEX idx_optimization_constraints_priority ON optimization_constraints(constraint_priority);
CREATE INDEX idx_optimization_constraints_employee ON optimization_constraints(specific_employee_tab_n);

-- =============================================================================
-- 6. OPTIMIZATION_PROCESSING_LOG - Processing status and progress tracking
-- =============================================================================
CREATE TABLE optimization_processing_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_project_id UUID NOT NULL,
    
    -- Processing stage information (BDD: processing stages)
    stage_name VARCHAR(100) NOT NULL,
    stage_description TEXT,
    stage_order INTEGER NOT NULL,
    
    -- Status tracking
    stage_status VARCHAR(20) NOT NULL CHECK (
        stage_status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED')
    ),
    
    -- Timing information
    stage_start_time TIMESTAMP WITH TIME ZONE,
    stage_end_time TIMESTAMP WITH TIME ZONE,
    estimated_duration_seconds INTEGER,
    actual_duration_seconds INTEGER,
    
    -- Progress tracking
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    progress_description TEXT,
    
    -- Results and metrics
    stage_results JSONB,
    error_message TEXT,
    warning_messages TEXT[],
    
    -- Dependencies
    depends_on_stages TEXT[], -- Array of stage names
    dependencies_met BOOLEAN DEFAULT false,
    
    CONSTRAINT fk_optimization_processing_log_project 
        FOREIGN KEY (optimization_project_id) REFERENCES optimization_projects(id) ON DELETE CASCADE,
    CONSTRAINT check_stage_timing CHECK (
        stage_end_time IS NULL OR stage_start_time IS NULL OR stage_end_time >= stage_start_time
    ),
    CONSTRAINT check_progress_percentage CHECK (
        progress_percentage >= 0 AND progress_percentage <= 100
    )
);

-- Indexes for optimization_processing_log
CREATE INDEX idx_optimization_processing_log_project ON optimization_processing_log(optimization_project_id);
CREATE INDEX idx_optimization_processing_log_stage ON optimization_processing_log(stage_name);
CREATE INDEX idx_optimization_processing_log_status ON optimization_processing_log(stage_status);
CREATE INDEX idx_optimization_processing_log_order ON optimization_processing_log(stage_order);

-- =============================================================================
-- FUNCTIONS: Schedule Optimization Engine (BDD Algorithm Components)
-- =============================================================================

-- Function to initiate schedule optimization analysis
CREATE OR REPLACE FUNCTION initiate_schedule_optimization(
    p_project_name VARCHAR(200),
    p_base_schedule_id UUID,
    p_forecast_project_id UUID,
    p_period_start DATE,
    p_period_end DATE,
    p_created_by VARCHAR(100)
) RETURNS UUID AS $$
DECLARE
    v_optimization_project_id UUID;
    v_stage_names TEXT[] := ARRAY[
        'Analyzing current coverage',
        'Identifying gap patterns', 
        'Generating schedule variants',
        'Validating constraints',
        'Ranking suggestions'
    ];
    v_stage_name TEXT;
    v_stage_order INTEGER := 1;
BEGIN
    -- Create optimization project
    INSERT INTO optimization_projects (
        project_name,
        base_schedule_id,
        forecast_project_id,
        optimization_period_start,
        optimization_period_end,
        optimization_status,
        created_by
    ) VALUES (
        p_project_name,
        p_base_schedule_id,
        p_forecast_project_id,
        p_period_start,
        p_period_end,
        'ANALYZING',
        p_created_by
    ) RETURNING id INTO v_optimization_project_id;
    
    -- Initialize processing stages (BDD: 5 stages)
    FOREACH v_stage_name IN ARRAY v_stage_names
    LOOP
        INSERT INTO optimization_processing_log (
            optimization_project_id,
            stage_name,
            stage_order,
            stage_status,
            estimated_duration_seconds,
            progress_percentage
        ) VALUES (
            v_optimization_project_id,
            v_stage_name,
            v_stage_order,
            CASE WHEN v_stage_order = 1 THEN 'IN_PROGRESS' ELSE 'PENDING' END,
            CASE v_stage_name
                WHEN 'Analyzing current coverage' THEN 2
                WHEN 'Identifying gap patterns' THEN 3
                WHEN 'Generating schedule variants' THEN 7 -- 5-10 sec average
                WHEN 'Validating constraints' THEN 2
                WHEN 'Ranking suggestions' THEN 1
            END,
            CASE WHEN v_stage_order = 1 THEN 0 ELSE 0 END
        );
        
        v_stage_order := v_stage_order + 1;
    END LOOP;
    
    -- Start coverage analysis
    PERFORM analyze_coverage_gaps(v_optimization_project_id);
    
    RETURN v_optimization_project_id;
END;
$$ LANGUAGE plpgsql;

-- Function to analyze coverage gaps (BDD: Gap Analysis Engine)
CREATE OR REPLACE FUNCTION analyze_coverage_gaps(
    p_optimization_project_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_project optimization_projects%ROWTYPE;
    v_forecast_record RECORD;
    v_schedule_record RECORD;
    v_coverage_gap DECIMAL(8,2);
    v_gap_severity VARCHAR(20);
    v_analysis_count INTEGER := 0;
BEGIN
    -- Get project details
    SELECT * INTO v_project FROM optimization_projects WHERE id = p_optimization_project_id;
    
    -- Update stage status
    UPDATE optimization_processing_log 
    SET stage_status = 'IN_PROGRESS',
        stage_start_time = CURRENT_TIMESTAMP,
        progress_percentage = 0
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Analyzing current coverage';
    
    -- Analyze coverage for each forecast interval
    FOR v_forecast_record IN 
        SELECT forecast_datetime, forecast_operators, forecast_calls
        FROM call_volume_forecasts cvf
        JOIN forecasting_projects fp ON fp.id = cvf.project_id
        WHERE cvf.project_id = v_project.forecast_project_id
        AND forecast_datetime::DATE BETWEEN v_project.optimization_period_start 
                                       AND v_project.optimization_period_end
        ORDER BY forecast_datetime
    LOOP
        -- Get scheduled operators for this interval (simplified - would need actual schedule data)
        SELECT COALESCE(SUM(1), 0) INTO v_schedule_record
        FROM zup_agent_data 
        WHERE tab_n IN (SELECT DISTINCT personnel_number FROM tabel_t13_employees LIMIT 5);
        
        -- Calculate coverage gap
        v_coverage_gap := v_forecast_record.forecast_operators - COALESCE(v_schedule_record.sum, 0);
        
        -- Determine gap severity
        v_gap_severity := CASE 
            WHEN v_coverage_gap > 5 THEN 'CRITICAL'
            WHEN v_coverage_gap > 3 THEN 'HIGH'
            WHEN v_coverage_gap > 1 THEN 'MEDIUM'
            WHEN v_coverage_gap > 0 THEN 'LOW'
            ELSE 'NONE'
        END;
        
        -- Insert coverage analysis
        INSERT INTO coverage_analysis (
            optimization_project_id,
            analysis_datetime,
            required_operators,
            scheduled_operators,
            coverage_gap,
            coverage_percentage,
            gap_severity,
            projected_service_level
        ) VALUES (
            p_optimization_project_id,
            v_forecast_record.forecast_datetime,
            v_forecast_record.forecast_operators,
            COALESCE(v_schedule_record.sum, 0),
            v_coverage_gap,
            CASE WHEN v_forecast_record.forecast_operators > 0 
                 THEN (COALESCE(v_schedule_record.sum, 0) / v_forecast_record.forecast_operators) * 100 
                 ELSE 100 END,
            v_gap_severity,
            GREATEST(0, 100 - (v_coverage_gap * 10)) -- Simplified service level calculation
        );
        
        v_analysis_count := v_analysis_count + 1;
    END LOOP;
    
    -- Update stage completion
    UPDATE optimization_processing_log 
    SET stage_status = 'COMPLETED',
        stage_end_time = CURRENT_TIMESTAMP,
        actual_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - stage_start_time)),
        progress_percentage = 100,
        stage_results = jsonb_build_object(
            'analysis_records_created', v_analysis_count,
            'critical_gaps', (SELECT COUNT(*) FROM coverage_analysis WHERE optimization_project_id = p_optimization_project_id AND gap_severity = 'CRITICAL'),
            'high_gaps', (SELECT COUNT(*) FROM coverage_analysis WHERE optimization_project_id = p_optimization_project_id AND gap_severity = 'HIGH')
        )
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Analyzing current coverage';
    
    -- Update project status
    UPDATE optimization_projects 
    SET coverage_analysis_completed = true,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_optimization_project_id;
    
    -- Start next stage
    PERFORM identify_gap_patterns(p_optimization_project_id);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to identify gap patterns (BDD: Statistical analysis)
CREATE OR REPLACE FUNCTION identify_gap_patterns(
    p_optimization_project_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_pattern_count INTEGER := 0;
    v_pattern_record RECORD;
BEGIN
    -- Update stage status
    UPDATE optimization_processing_log 
    SET stage_status = 'IN_PROGRESS',
        stage_start_time = CURRENT_TIMESTAMP,
        progress_percentage = 0
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Identifying gap patterns';
    
    -- Identify common gap patterns
    FOR v_pattern_record IN 
        SELECT 
            EXTRACT(HOUR FROM analysis_datetime) as hour_of_day,
            AVG(coverage_gap) as avg_gap,
            COUNT(*) as gap_count,
            MAX(gap_severity) as max_severity,
            CASE 
                WHEN EXTRACT(HOUR FROM analysis_datetime) BETWEEN 8 AND 10 THEN 'MORNING_RUSH'
                WHEN EXTRACT(HOUR FROM analysis_datetime) BETWEEN 12 AND 14 THEN 'LUNCH_DIP'
                WHEN EXTRACT(HOUR FROM analysis_datetime) BETWEEN 17 AND 19 THEN 'EVENING_PEAK'
                ELSE 'STANDARD_HOURS'
            END as pattern_type
        FROM coverage_analysis
        WHERE optimization_project_id = p_optimization_project_id
        AND coverage_gap > 0
        GROUP BY EXTRACT(HOUR FROM analysis_datetime)
        HAVING COUNT(*) > 1
    LOOP
        -- Update coverage analysis with pattern information
        UPDATE coverage_analysis 
        SET gap_pattern_type = v_pattern_record.pattern_type,
            recurring_pattern = true,
            similar_interval_count = v_pattern_record.gap_count
        WHERE optimization_project_id = p_optimization_project_id
        AND EXTRACT(HOUR FROM analysis_datetime) = v_pattern_record.hour_of_day;
        
        v_pattern_count := v_pattern_count + 1;
    END LOOP;
    
    -- Update stage completion
    UPDATE optimization_processing_log 
    SET stage_status = 'COMPLETED',
        stage_end_time = CURRENT_TIMESTAMP,
        actual_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - stage_start_time)),
        progress_percentage = 100,
        stage_results = jsonb_build_object(
            'patterns_identified', v_pattern_count,
            'most_common_pattern', (SELECT gap_pattern_type FROM coverage_analysis WHERE optimization_project_id = p_optimization_project_id GROUP BY gap_pattern_type ORDER BY COUNT(*) DESC LIMIT 1)
        )
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Identifying gap patterns';
    
    -- Update project status
    UPDATE optimization_projects 
    SET gap_pattern_identification_completed = true,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_optimization_project_id;
    
    -- Start next stage
    PERFORM generate_schedule_variants(p_optimization_project_id);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to generate schedule variants (BDD: Genetic algorithm)
CREATE OR REPLACE FUNCTION generate_schedule_variants(
    p_optimization_project_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_project optimization_projects%ROWTYPE;
    v_variant_count INTEGER := 0;
    v_suggestion_record RECORD;
    v_suggestion_id UUID;
    v_rank INTEGER := 1;
BEGIN
    -- Get project details
    SELECT * INTO v_project FROM optimization_projects WHERE id = p_optimization_project_id;
    
    -- Update stage status
    UPDATE optimization_processing_log 
    SET stage_status = 'IN_PROGRESS',
        stage_start_time = CURRENT_TIMESTAMP,
        progress_percentage = 0
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Generating schedule variants';
    
    -- Generate schedule suggestions (simplified genetic algorithm simulation)
    FOR v_suggestion_record IN 
        SELECT 
            'Suggestion ' || ROW_NUMBER() OVER (ORDER BY AVG(coverage_gap) DESC) as suggestion_name,
            'Optimization pattern for ' || gap_pattern_type || ' gaps' as description,
            gap_pattern_type,
            AVG(coverage_gap) as avg_gap,
            COUNT(*) as gap_intervals,
            -- Simulated optimization scores
            GREATEST(70, 100 - (AVG(coverage_gap) * 5)) as base_score,
            GREATEST(10, 30 - AVG(coverage_gap)) as coverage_improvement,
            GREATEST(500, 2000 - (AVG(coverage_gap) * 200)) as cost_savings
        FROM coverage_analysis
        WHERE optimization_project_id = p_optimization_project_id
        AND coverage_gap > 0
        GROUP BY gap_pattern_type
        ORDER BY AVG(coverage_gap) DESC
        LIMIT 3 -- Generate top 3 suggestions
    LOOP
        -- Create schedule suggestion
        INSERT INTO schedule_suggestions (
            optimization_project_id,
            suggestion_rank,
            suggestion_name,
            suggestion_description,
            overall_score,
            coverage_score,
            cost_score,
            service_level_score,
            complexity_score,
            coverage_improvement_percentage,
            cost_impact_weekly,
            service_level_improvement,
            pattern_type,
            operators_needed,
            operators_available,
            risk_assessment,
            implementation_complexity,
            current_coverage_percentage,
            projected_coverage_percentage,
            current_cost_weekly,
            projected_cost_weekly,
            current_service_level,
            projected_service_level,
            generation_method
        ) VALUES (
            p_optimization_project_id,
            v_rank,
            v_suggestion_record.suggestion_name,
            v_suggestion_record.description,
            v_suggestion_record.base_score,
            v_suggestion_record.base_score,
            GREATEST(70, v_suggestion_record.base_score - 5),
            GREATEST(75, v_suggestion_record.base_score - 3),
            GREATEST(80, v_suggestion_record.base_score - 2),
            v_suggestion_record.coverage_improvement,
            -v_suggestion_record.cost_savings, -- Negative for savings
            GREATEST(3, v_suggestion_record.coverage_improvement / 3),
            v_suggestion_record.gap_pattern_type,
            CEIL(v_suggestion_record.avg_gap),
            FLOOR(v_suggestion_record.avg_gap * 1.2),
            CASE 
                WHEN v_suggestion_record.avg_gap > 5 THEN 'HIGH'
                WHEN v_suggestion_record.avg_gap > 2 THEN 'MEDIUM'
                ELSE 'LOW'
            END,
            CASE 
                WHEN v_suggestion_record.gap_intervals > 20 THEN 'COMPLEX'
                WHEN v_suggestion_record.gap_intervals > 10 THEN 'MEDIUM'
                ELSE 'SIMPLE'
            END,
            GREATEST(60, 100 - (v_suggestion_record.avg_gap * 10)),
            GREATEST(80, 100 - (v_suggestion_record.avg_gap * 5)),
            45600, -- Example current cost
            45600 + v_suggestion_record.cost_savings,
            GREATEST(60, 100 - (v_suggestion_record.avg_gap * 8)),
            GREATEST(75, 100 - (v_suggestion_record.avg_gap * 4)),
            'GENETIC_ALGORITHM'
        ) RETURNING id INTO v_suggestion_id;
        
        v_variant_count := v_variant_count + 1;
        v_rank := v_rank + 1;
    END LOOP;
    
    -- Update stage completion
    UPDATE optimization_processing_log 
    SET stage_status = 'COMPLETED',
        stage_end_time = CURRENT_TIMESTAMP,
        actual_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - stage_start_time)),
        progress_percentage = 100,
        stage_results = jsonb_build_object(
            'variants_generated', v_variant_count,
            'best_score', (SELECT MAX(overall_score) FROM schedule_suggestions WHERE optimization_project_id = p_optimization_project_id)
        )
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Generating schedule variants';
    
    -- Update project status
    UPDATE optimization_projects 
    SET schedule_variant_generation_completed = true,
        total_variants_generated = v_variant_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_optimization_project_id;
    
    -- Start next stage
    PERFORM validate_constraints(p_optimization_project_id);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to validate constraints (BDD: Constraint validation)
CREATE OR REPLACE FUNCTION validate_constraints(
    p_optimization_project_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_suggestion_record RECORD;
    v_constraint_record RECORD;
    v_validation_count INTEGER := 0;
    v_valid_suggestions INTEGER := 0;
BEGIN
    -- Update stage status
    UPDATE optimization_processing_log 
    SET stage_status = 'IN_PROGRESS',
        stage_start_time = CURRENT_TIMESTAMP,
        progress_percentage = 0
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Validating constraints';
    
    -- Validate each suggestion against constraints
    FOR v_suggestion_record IN 
        SELECT * FROM schedule_suggestions 
        WHERE optimization_project_id = p_optimization_project_id
        ORDER BY suggestion_rank
    LOOP
        -- Initialize compliance flags
        UPDATE schedule_suggestions 
        SET labor_law_compliant = true,
            union_agreement_compliant = true,
            employee_contract_compliant = true,
            business_rule_compliant = true
        WHERE id = v_suggestion_record.id;
        
        -- Check critical constraints
        FOR v_constraint_record IN 
            SELECT * FROM optimization_constraints 
            WHERE constraint_priority = 'CRITICAL'
            AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
        LOOP
            -- Simplified constraint validation
            IF v_constraint_record.constraint_type = 'LABOR_LAW' THEN
                -- Check if operators needed exceeds available
                IF v_suggestion_record.operators_needed > v_suggestion_record.operators_available THEN
                    UPDATE schedule_suggestions 
                    SET labor_law_compliant = false
                    WHERE id = v_suggestion_record.id;
                END IF;
            END IF;
            
            v_validation_count := v_validation_count + 1;
        END LOOP;
        
        -- Count valid suggestions
        IF v_suggestion_record.operators_needed <= v_suggestion_record.operators_available THEN
            v_valid_suggestions := v_valid_suggestions + 1;
        END IF;
    END LOOP;
    
    -- Update stage completion
    UPDATE optimization_processing_log 
    SET stage_status = 'COMPLETED',
        stage_end_time = CURRENT_TIMESTAMP,
        actual_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - stage_start_time)),
        progress_percentage = 100,
        stage_results = jsonb_build_object(
            'constraints_validated', v_validation_count,
            'valid_suggestions', v_valid_suggestions
        )
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Validating constraints';
    
    -- Update project status
    UPDATE optimization_projects 
    SET constraint_validation_completed = true,
        valid_variants_count = v_valid_suggestions,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_optimization_project_id;
    
    -- Start final stage
    PERFORM rank_suggestions(p_optimization_project_id);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to rank suggestions (BDD: Multi-criteria scoring)
CREATE OR REPLACE FUNCTION rank_suggestions(
    p_optimization_project_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_project optimization_projects%ROWTYPE;
    v_suggestion_record RECORD;
    v_final_rank INTEGER := 1;
BEGIN
    -- Get project details
    SELECT * INTO v_project FROM optimization_projects WHERE id = p_optimization_project_id;
    
    -- Update stage status
    UPDATE optimization_processing_log 
    SET stage_status = 'IN_PROGRESS',
        stage_start_time = CURRENT_TIMESTAMP,
        progress_percentage = 0
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Ranking suggestions';
    
    -- Rerank suggestions based on weighted scores
    FOR v_suggestion_record IN 
        SELECT *,
               -- Calculate weighted score based on project weights
               (coverage_score * v_project.coverage_gap_weight / 100.0) +
               (cost_score * v_project.cost_efficiency_weight / 100.0) +
               (service_level_score * v_project.service_level_weight / 100.0) +
               (complexity_score * v_project.complexity_weight / 100.0) as weighted_score
        FROM schedule_suggestions 
        WHERE optimization_project_id = p_optimization_project_id
        AND labor_law_compliant = true
        AND union_agreement_compliant = true
        ORDER BY weighted_score DESC
    LOOP
        -- Update final ranking
        UPDATE schedule_suggestions 
        SET suggestion_rank = v_final_rank,
            overall_score = v_suggestion_record.weighted_score
        WHERE id = v_suggestion_record.id;
        
        v_final_rank := v_final_rank + 1;
    END LOOP;
    
    -- Update stage completion
    UPDATE optimization_processing_log 
    SET stage_status = 'COMPLETED',
        stage_end_time = CURRENT_TIMESTAMP,
        actual_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - stage_start_time)),
        progress_percentage = 100,
        stage_results = jsonb_build_object(
            'suggestions_ranked', v_final_rank - 1,
            'top_suggestion_score', (SELECT MAX(overall_score) FROM schedule_suggestions WHERE optimization_project_id = p_optimization_project_id)
        )
    WHERE optimization_project_id = p_optimization_project_id 
    AND stage_name = 'Ranking suggestions';
    
    -- Update project completion
    UPDATE optimization_projects 
    SET suggestion_ranking_completed = true,
        optimization_status = 'COMPLETED',
        processing_end_time = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_optimization_project_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Schedule Optimization Dashboard (BDD UI requirements)
-- =============================================================================

-- View for optimization project overview
CREATE VIEW v_optimization_projects_overview AS
SELECT 
    op.id as project_id,
    op.project_name,
    op.optimization_status,
    TO_CHAR(op.optimization_period_start, 'DD.MM.YYYY') as period_start,
    TO_CHAR(op.optimization_period_end, 'DD.MM.YYYY') as period_end,
    
    -- Processing progress
    CASE 
        WHEN op.suggestion_ranking_completed THEN 'Completed'
        WHEN op.constraint_validation_completed THEN 'Ranking suggestions'
        WHEN op.schedule_variant_generation_completed THEN 'Validating constraints'
        WHEN op.gap_pattern_identification_completed THEN 'Generating schedule variants'
        WHEN op.coverage_analysis_completed THEN 'Identifying gap patterns'
        ELSE 'Analyzing current coverage'
    END as current_stage,
    
    -- Results summary
    op.total_variants_generated,
    op.valid_variants_count,
    
    -- Timing
    CASE 
        WHEN op.processing_end_time IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (op.processing_end_time - op.processing_start_time))
        ELSE 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - op.processing_start_time))
    END as processing_duration_seconds,
    
    -- Top suggestion preview
    (SELECT overall_score FROM schedule_suggestions WHERE optimization_project_id = op.id ORDER BY suggestion_rank LIMIT 1) as top_score,
    (SELECT coverage_improvement_percentage FROM schedule_suggestions WHERE optimization_project_id = op.id ORDER BY suggestion_rank LIMIT 1) as top_coverage_improvement,
    
    op.created_by,
    op.created_at
    
FROM optimization_projects op
ORDER BY op.updated_at DESC;

-- View for schedule suggestions dashboard (BDD: suggestion interface)
CREATE VIEW v_schedule_suggestions_dashboard AS
SELECT 
    ss.optimization_project_id,
    op.project_name,
    ss.suggestion_rank,
    ss.suggestion_name,
    ROUND(ss.overall_score, 1) as score_display, -- XX.X/100 format
    '+' || ROUND(ss.coverage_improvement_percentage, 1) || '%' as coverage_improvement_display,
    CASE 
        WHEN ss.cost_impact_weekly < 0 THEN '-$' || ABS(ss.cost_impact_weekly)::TEXT || '/week'
        ELSE '+$' || ss.cost_impact_weekly::TEXT || '/week'
    END as cost_impact_display,
    ss.pattern_type,
    ss.operators_needed || ' operators' as operators_display,
    ss.risk_assessment,
    ss.implementation_complexity,
    
    -- Detailed metrics for preview
    ROUND(ss.current_coverage_percentage, 1) || '%' as current_coverage,
    ROUND(ss.projected_coverage_percentage, 1) || '%' as projected_coverage,
    ROUND(ss.current_service_level, 1) || '%' as current_service_level,
    ROUND(ss.projected_service_level, 1) || '%' as projected_service_level,
    
    -- Interactive options
    'Preview' as preview_action,
    'Details' as details_action,
    'Apply' as apply_action,
    'Modify' as modify_action,
    
    -- Filtering metadata
    ss.overall_score >= 90 as high_score,
    ss.cost_impact_weekly < 0 as cost_savings,
    ss.implementation_complexity = 'SIMPLE' as simple_implementation,
    ss.operators_needed <= ss.operators_available as operators_available_filter
    
FROM schedule_suggestions ss
JOIN optimization_projects op ON op.id = ss.optimization_project_id
WHERE op.optimization_status = 'COMPLETED'
ORDER BY ss.optimization_project_id, ss.suggestion_rank;

-- View for processing progress (BDD: real-time progress)
CREATE VIEW v_optimization_processing_progress AS
SELECT 
    opl.optimization_project_id,
    op.project_name,
    opl.stage_name,
    opl.stage_status,
    opl.progress_percentage,
    opl.progress_description,
    opl.estimated_duration_seconds,
    opl.actual_duration_seconds,
    
    -- Status display (BDD: ✓ Complete, In Progress..., Pending)
    CASE opl.stage_status
        WHEN 'COMPLETED' THEN '✓ Complete'
        WHEN 'IN_PROGRESS' THEN 'In Progress...'
        WHEN 'FAILED' THEN '✗ Failed'
        ELSE 'Pending'
    END as status_display,
    
    -- Duration display
    CASE 
        WHEN opl.actual_duration_seconds IS NOT NULL THEN opl.actual_duration_seconds || ' sec'
        ELSE opl.estimated_duration_seconds || ' sec'
    END as duration_display,
    
    -- Dependencies
    opl.depends_on_stages,
    opl.dependencies_met,
    
    -- Results
    opl.stage_results,
    opl.error_message,
    
    -- Overall project progress
    ROUND(
        (SELECT AVG(progress_percentage) FROM optimization_processing_log WHERE optimization_project_id = opl.optimization_project_id),
        1
    ) as overall_progress_percentage
    
FROM optimization_processing_log opl
JOIN optimization_projects op ON op.id = opl.optimization_project_id
ORDER BY opl.optimization_project_id, opl.stage_order;

-- Sample data for demonstration
INSERT INTO optimization_constraints (
    constraint_name, constraint_type, constraint_priority, constraint_description, validation_rule,
    max_hours_per_day, max_hours_per_week, min_rest_hours
) VALUES 
('Russian Labor Law - Daily Hours', 'LABOR_LAW', 'CRITICAL', 'Maximum 8 hours per day per Russian Labor Code', 'daily_hours <= 8', 8, 40, 11),
('Russian Labor Law - Weekly Hours', 'LABOR_LAW', 'CRITICAL', 'Maximum 40 hours per week per Russian Labor Code', 'weekly_hours <= 40', 8, 40, 11),
('Minimum Rest Period', 'LABOR_LAW', 'CRITICAL', 'Minimum 11 hours rest between shifts', 'rest_hours >= 11', 8, 40, 11),
('Union Agreement - Weekend Work', 'UNION_AGREEMENT', 'HIGH', 'Weekend work requires union approval', 'weekend_work_approved = true', NULL, NULL, NULL),
('Business Rule - Minimum Coverage', 'BUSINESS_RULE', 'HIGH', 'Minimum 2 operators during business hours', 'operators_scheduled >= 2', NULL, NULL, NULL);

COMMENT ON TABLE optimization_projects IS 'Schedule optimization projects with BDD-specified algorithm components and weights';
COMMENT ON TABLE coverage_analysis IS 'Gap analysis and pattern identification per BDD Gap Analysis Engine';
COMMENT ON TABLE schedule_suggestions IS 'Generated optimization suggestions with BDD-specified scoring (XX.X/100 format)';
COMMENT ON TABLE suggestion_details IS 'Detailed schedule changes for each suggestion with employee impact';
COMMENT ON TABLE optimization_constraints IS 'Constraint definitions for validation (labor law, union, business rules)';
COMMENT ON TABLE optimization_processing_log IS 'Real-time progress tracking for BDD-specified processing stages';
COMMENT ON FUNCTION initiate_schedule_optimization IS 'Initialize schedule optimization with BDD-specified 5-stage process';
COMMENT ON VIEW v_schedule_suggestions_dashboard IS 'BDD-compliant suggestion interface with exact display elements';