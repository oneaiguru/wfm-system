-- Schema 080: Automatic Schedule Optimization Engine (BDD 24)
-- Advanced optimization beyond Argus capabilities
-- Genetic algorithms, multi-criteria optimization, real-time adjustments

-- 1. Schedule Optimization Requests
CREATE TABLE schedule_optimization_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_period_start DATE NOT NULL,
    planning_period_end DATE NOT NULL,
    department_id UUID,
    location_id UUID,
    request_type VARCHAR(50), -- full_optimization, gap_filling, cost_reduction
    requested_by VARCHAR(255),
    request_status VARCHAR(50) DEFAULT 'pending',
    optimization_score DECIMAL(5,2), -- Final score out of 100
    processing_start TIMESTAMP,
    processing_end TIMESTAMP,
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Gap Analysis Results
CREATE TABLE schedule_gap_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES schedule_optimization_requests(request_id),
    interval_timestamp TIMESTAMP NOT NULL,
    required_staff INTEGER NOT NULL,
    scheduled_staff INTEGER NOT NULL,
    gap_size INTEGER GENERATED ALWAYS AS (required_staff - scheduled_staff) STORED,
    gap_severity VARCHAR(20), -- critical, high, medium, low
    service_level_impact DECIMAL(5,2),
    cost_impact DECIMAL(10,2),
    skill_gaps JSONB, -- {"skill": "gap_count"}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Optimization Algorithm Components
CREATE TABLE optimization_algorithm_runs (
    run_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES schedule_optimization_requests(request_id),
    component_name VARCHAR(100), -- gap_analysis, constraint_validator, pattern_generator, etc.
    algorithm_type VARCHAR(50), -- genetic, linear_programming, statistical, rule_based
    input_data JSONB,
    output_data JSONB,
    processing_time_ms INTEGER,
    status VARCHAR(50),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Schedule Suggestions Generated
CREATE TABLE schedule_suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES schedule_optimization_requests(request_id),
    suggestion_rank INTEGER,
    optimization_score DECIMAL(5,2), -- Out of 100
    coverage_improvement_percent DECIMAL(5,2),
    cost_impact_weekly DECIMAL(10,2),
    service_level_improvement DECIMAL(5,2),
    pattern_type VARCHAR(100), -- rotating_shifts, compressed_week, flexible_hours
    operators_needed INTEGER,
    availability_status VARCHAR(50), -- available, requires_hiring, requires_training
    risk_assessment VARCHAR(20), -- low, medium, high
    implementation_complexity VARCHAR(20), -- simple, medium, complex
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Constraint Validation Results
CREATE TABLE optimization_constraints (
    constraint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_id UUID REFERENCES schedule_suggestions(suggestion_id),
    constraint_type VARCHAR(50), -- labor_law, union_agreement, employee_contract, business_rule
    constraint_name VARCHAR(255),
    constraint_rule TEXT,
    validation_result VARCHAR(20), -- passed, failed, warning
    violation_details TEXT,
    priority VARCHAR(20), -- critical, high, medium, low
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Multi-Criteria Scoring Details
CREATE TABLE optimization_scoring_criteria (
    scoring_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_id UUID REFERENCES schedule_suggestions(suggestion_id),
    criterion_name VARCHAR(100),
    criterion_weight DECIMAL(5,2), -- Percentage weight
    raw_score DECIMAL(10,4),
    weighted_score DECIMAL(10,4),
    target_value DECIMAL(10,4),
    achieved_value DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Genetic Algorithm Population
CREATE TABLE genetic_algorithm_population (
    population_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES schedule_optimization_requests(request_id),
    generation_number INTEGER NOT NULL,
    chromosome_id UUID NOT NULL,
    fitness_score DECIMAL(10,4),
    schedule_pattern JSONB, -- Encoded schedule representation
    mutation_rate DECIMAL(5,4),
    crossover_points INTEGER[],
    parent1_id UUID,
    parent2_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Real-time Optimization Adjustments
CREATE TABLE realtime_optimization_triggers (
    trigger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_type VARCHAR(50), -- absence_coverage, volume_spike, skill_shortage
    trigger_timestamp TIMESTAMP NOT NULL,
    affected_interval_start TIMESTAMP,
    affected_interval_end TIMESTAMP,
    adjustment_urgency VARCHAR(20), -- immediate, urgent, planned
    current_gap INTEGER,
    proposed_solution JSONB,
    solution_applied BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Schedule Pattern Library
CREATE TABLE schedule_pattern_templates (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_name VARCHAR(255) NOT NULL,
    pattern_name_ru VARCHAR(255),
    pattern_type VARCHAR(50), -- standard, rotating, compressed, flexible
    shift_sequence JSONB, -- Array of shift definitions
    cycle_length_days INTEGER,
    weekly_hours DECIMAL(5,2),
    compliance_verified BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Optimization Progress Tracking
CREATE TABLE optimization_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES schedule_optimization_requests(request_id),
    stage_name VARCHAR(100),
    stage_status VARCHAR(50), -- pending, in_progress, complete, failed
    percentage_complete INTEGER,
    estimated_duration_seconds INTEGER,
    actual_duration_seconds INTEGER,
    stage_order INTEGER,
    dependencies_met BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert standard optimization criteria
INSERT INTO schedule_pattern_templates (pattern_name, pattern_name_ru, pattern_type, shift_sequence, cycle_length_days, weekly_hours)
VALUES 
    ('5-Day Standard', '5-дневная стандартная', 'standard', 
     '[{"day": 1, "start": "09:00", "end": "18:00"}, {"day": 2, "start": "09:00", "end": "18:00"}]'::jsonb, 7, 40),
    ('4-Day Compressed', '4-дневная сжатая', 'compressed',
     '[{"day": 1, "start": "08:00", "end": "18:30"}, {"day": 2, "start": "08:00", "end": "18:30"}]'::jsonb, 7, 40),
    ('Rotating 3-Shift', 'Ротация 3 смены', 'rotating',
     '[{"shift": "morning", "start": "06:00", "end": "14:00"}, {"shift": "afternoon", "start": "14:00", "end": "22:00"}]'::jsonb, 21, 40);

-- Insert optimization algorithm components
INSERT INTO optimization_algorithm_runs (request_id, component_name, algorithm_type, processing_time_ms, status)
VALUES 
    (uuid_generate_v4(), 'Gap Analysis Engine', 'statistical', 2500, 'completed'),
    (uuid_generate_v4(), 'Pattern Generator', 'genetic', 7500, 'completed'),
    (uuid_generate_v4(), 'Scoring Engine', 'multi_criteria', 1500, 'completed');

-- Create indexes for performance
CREATE INDEX idx_gap_analysis_severity ON schedule_gap_analysis(gap_severity, service_level_impact);
CREATE INDEX idx_suggestions_score ON schedule_suggestions(optimization_score DESC);
CREATE INDEX idx_constraints_validation ON optimization_constraints(validation_result, priority);
CREATE INDEX idx_genetic_fitness ON genetic_algorithm_population(generation_number, fitness_score DESC);
CREATE INDEX idx_realtime_triggers ON realtime_optimization_triggers(trigger_timestamp, adjustment_urgency);

-- Verify optimization tables
SELECT COUNT(*) as optimization_tables FROM information_schema.tables 
WHERE table_name LIKE '%optimization%' OR table_name LIKE '%genetic%' OR table_name LIKE '%suggestion%';