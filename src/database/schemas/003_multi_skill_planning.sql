-- =====================================================================================
-- Multi-Skill Schedule Planning Module Schema
-- Module: модуль планирования графиков (Schedule Planning Module)
-- Created for: DATABASE-OPUS Agent
-- Purpose: Support multi-skill agent scheduling across 20+ projects with varying complexity
-- Demo Date: Next week
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- 1. CORE SKILL MANAGEMENT TABLES
-- =====================================================================================

-- Skills catalog
CREATE TABLE IF NOT EXISTS skills (
    skill_id SERIAL PRIMARY KEY,
    skill_code VARCHAR(50) UNIQUE NOT NULL,
    skill_name VARCHAR(255) NOT NULL,
    skill_category VARCHAR(100), -- 'language', 'technical', 'product', 'soft_skill'
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent skills with proficiency levels
CREATE TABLE IF NOT EXISTS agent_skills (
    agent_skill_id SERIAL PRIMARY KEY,
    agent_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL REFERENCES skills(skill_id),
    proficiency_level INTEGER NOT NULL CHECK (proficiency_level BETWEEN 1 AND 5),
    -- 1: Beginner, 2: Basic, 3: Intermediate, 4: Advanced, 5: Expert
    certified_date DATE,
    expiry_date DATE,
    is_primary_skill BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(agent_id, skill_id)
);

-- Create index for fast agent skill lookups
CREATE INDEX idx_agent_skills_agent ON agent_skills(agent_id) WHERE is_active = TRUE;
CREATE INDEX idx_agent_skills_skill ON agent_skills(skill_id) WHERE is_active = TRUE;
CREATE INDEX idx_agent_skills_proficiency ON agent_skills(proficiency_level) WHERE is_active = TRUE;

-- =====================================================================================
-- 2. PROJECT AND QUEUE MANAGEMENT
-- =====================================================================================

-- Projects table (20+ projects with varying complexity)
CREATE TABLE IF NOT EXISTS projects (
    project_id SERIAL PRIMARY KEY,
    project_code VARCHAR(50) UNIQUE NOT NULL,
    project_name VARCHAR(255) NOT NULL,
    client_name VARCHAR(255),
    project_type VARCHAR(50), -- 'simple', 'complex', 'government', 'enterprise'
    queue_count INTEGER DEFAULT 1,
    priority_level INTEGER DEFAULT 3 CHECK (priority_level BETWEEN 1 AND 5),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert example projects matching specification
INSERT INTO projects (project_code, project_name, client_name, project_type, queue_count, priority_level) VALUES
    ('B', 'Project Б', 'Client B', 'simple', 1, 3),
    ('VTM', 'Project ВТМ', 'VTM Corporation', 'complex', 32, 4),
    ('I', 'Project И', 'Institute I', 'enterprise', 68, 5),
    ('F', 'Project Ф', 'Government Agency F', 'government', 5, 5)
ON CONFLICT (project_code) DO NOTHING;

-- Project queues with skill requirements
CREATE TABLE IF NOT EXISTS project_queues (
    queue_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(project_id),
    queue_code VARCHAR(100) NOT NULL,
    queue_name VARCHAR(255) NOT NULL,
    queue_type VARCHAR(50), -- 'inbound', 'outbound', 'email', 'chat', 'back_office'
    service_level_target DECIMAL(5,2), -- Target in percentage (e.g., 80.00)
    service_level_seconds INTEGER, -- Seconds for SL calculation (e.g., 20)
    priority INTEGER DEFAULT 3,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, queue_code)
);

-- Create index for project queue lookups
CREATE INDEX idx_project_queues_project ON project_queues(project_id) WHERE is_active = TRUE;

-- =====================================================================================
-- 3. SKILL REQUIREMENTS AND PLANNING
-- =====================================================================================

-- Skill requirements per project/queue
CREATE TABLE IF NOT EXISTS skill_requirements (
    requirement_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(project_id),
    queue_id INTEGER REFERENCES project_queues(queue_id),
    skill_id INTEGER NOT NULL REFERENCES skills(skill_id),
    min_agents INTEGER NOT NULL DEFAULT 1,
    preferred_agents INTEGER,
    min_proficiency_level INTEGER DEFAULT 3,
    requirement_type VARCHAR(50) DEFAULT 'mandatory', -- 'mandatory', 'preferred', 'optional'
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT skill_req_unique UNIQUE(project_id, queue_id, skill_id, valid_from)
);

-- Create indexes for requirement lookups
CREATE INDEX idx_skill_requirements_project ON skill_requirements(project_id);
CREATE INDEX idx_skill_requirements_skill ON skill_requirements(skill_id);
CREATE INDEX idx_skill_requirements_validity ON skill_requirements(valid_from, valid_to);

-- =====================================================================================
-- 4. SCHEDULE TEMPLATES AND PATTERNS
-- =====================================================================================

-- Schedule templates for different shift patterns
CREATE TABLE IF NOT EXISTS schedule_templates (
    template_id SERIAL PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    shift_pattern VARCHAR(100) NOT NULL, -- '5x8', '4x10', '3x12', 'flexible'
    work_days_per_week INTEGER,
    hours_per_day DECIMAL(4,2),
    start_time TIME,
    end_time TIME,
    break_minutes INTEGER DEFAULT 60,
    is_rotational BOOLEAN DEFAULT FALSE,
    rotation_weeks INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert common schedule templates
INSERT INTO schedule_templates (template_code, template_name, shift_pattern, work_days_per_week, hours_per_day, start_time, end_time) VALUES
    ('STANDARD_5X8', 'Standard 5x8', '5x8', 5, 8, '09:00', '18:00'),
    ('EARLY_5X8', 'Early 5x8', '5x8', 5, 8, '07:00', '16:00'),
    ('LATE_5X8', 'Late 5x8', '5x8', 5, 8, '14:00', '23:00'),
    ('COMPRESSED_4X10', 'Compressed 4x10', '4x10', 4, 10, '08:00', '19:00'),
    ('WEEKEND_3X12', 'Weekend 3x12', '3x12', 3, 12, '08:00', '20:00')
ON CONFLICT (template_code) DO NOTHING;

-- =====================================================================================
-- 5. MULTI-SKILL ASSIGNMENTS AND SCHEDULING
-- =====================================================================================

-- Multi-skill agent assignments to projects/queues
CREATE TABLE IF NOT EXISTS multi_skill_assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    agent_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL REFERENCES projects(project_id),
    queue_id INTEGER REFERENCES project_queues(queue_id),
    skill_id INTEGER NOT NULL REFERENCES skills(skill_id),
    schedule_template_id INTEGER REFERENCES schedule_templates(template_id),
    assignment_date DATE NOT NULL,
    time_slot_start TIMESTAMPTZ NOT NULL,
    time_slot_end TIMESTAMPTZ NOT NULL,
    assignment_type VARCHAR(50) DEFAULT 'primary', -- 'primary', 'backup', 'overflow'
    utilization_target DECIMAL(5,2) DEFAULT 85.00, -- Target utilization percentage
    is_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER,
    CONSTRAINT assignment_time_check CHECK (time_slot_end > time_slot_start),
    CONSTRAINT assignment_unique UNIQUE(agent_id, time_slot_start, time_slot_end)
);

-- Create indexes for assignment queries
CREATE INDEX idx_assignments_agent_date ON multi_skill_assignments(agent_id, assignment_date);
CREATE INDEX idx_assignments_project_date ON multi_skill_assignments(project_id, assignment_date);
CREATE INDEX idx_assignments_skill_date ON multi_skill_assignments(skill_id, assignment_date);
CREATE INDEX idx_assignments_timeslot ON multi_skill_assignments(time_slot_start, time_slot_end);

-- Assignment conflicts tracking
CREATE TABLE IF NOT EXISTS assignment_conflicts (
    conflict_id SERIAL PRIMARY KEY,
    assignment_id_1 BIGINT NOT NULL REFERENCES multi_skill_assignments(assignment_id),
    assignment_id_2 BIGINT NOT NULL REFERENCES multi_skill_assignments(assignment_id),
    conflict_type VARCHAR(50) NOT NULL, -- 'time_overlap', 'skill_mismatch', 'capacity_exceeded'
    conflict_severity VARCHAR(20) DEFAULT 'warning', -- 'warning', 'error', 'critical'
    resolution_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'resolved', 'ignored'
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by INTEGER
);

-- =====================================================================================
-- 6. SKILL GAP ANALYSIS TABLES
-- =====================================================================================

-- Skill gap tracking
CREATE TABLE IF NOT EXISTS skill_gaps (
    gap_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(project_id),
    queue_id INTEGER REFERENCES project_queues(queue_id),
    skill_id INTEGER NOT NULL REFERENCES skills(skill_id),
    gap_date DATE NOT NULL,
    time_interval_start TIME NOT NULL,
    time_interval_end TIME NOT NULL,
    required_agents INTEGER NOT NULL,
    assigned_agents INTEGER NOT NULL DEFAULT 0,
    gap_count INTEGER GENERATED ALWAYS AS (required_agents - assigned_agents) STORED,
    gap_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN required_agents > 0 
         THEN ((required_agents - assigned_agents)::DECIMAL / required_agents * 100)
         ELSE 0 END) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, queue_id, skill_id, gap_date, time_interval_start)
);

-- Create indexes for gap analysis
CREATE INDEX idx_skill_gaps_project_date ON skill_gaps(project_id, gap_date);
CREATE INDEX idx_skill_gaps_severity ON skill_gaps(gap_percentage) WHERE gap_percentage > 0;

-- =====================================================================================
-- 7. OPTIMIZATION TRACKING
-- =====================================================================================

-- Optimization run history
CREATE TABLE IF NOT EXISTS optimization_runs (
    run_id SERIAL PRIMARY KEY,
    optimization_type VARCHAR(50) NOT NULL, -- 'skill_coverage', 'cost', 'balanced'
    run_date DATE NOT NULL,
    projects_included INTEGER[],
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    initial_coverage DECIMAL(5,2),
    optimized_coverage DECIMAL(5,2),
    assignments_created INTEGER DEFAULT 0,
    assignments_modified INTEGER DEFAULT 0,
    run_status VARCHAR(50) DEFAULT 'running', -- 'running', 'completed', 'failed'
    error_message TEXT,
    created_by INTEGER
);

-- =====================================================================================
-- 8. KEY PROCEDURES FOR MULTI-SKILL OPTIMIZATION
-- =====================================================================================

-- Assign multi-skill agents to projects based on requirements
CREATE OR REPLACE FUNCTION assign_multi_skill_agents(
    p_project_id INTEGER,
    p_date DATE,
    p_optimization_mode VARCHAR DEFAULT 'balanced' -- 'coverage', 'cost', 'balanced'
)
RETURNS TABLE (
    assigned_count INTEGER,
    coverage_percentage DECIMAL,
    skill_gaps INTEGER,
    execution_time_ms INTEGER
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_assigned_count INTEGER := 0;
    v_total_requirements INTEGER;
    v_covered_requirements INTEGER;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Implementation placeholder - detailed logic to be added
    -- This will include:
    -- 1. Get all skill requirements for the project
    -- 2. Find available agents with matching skills
    -- 3. Optimize assignments based on mode
    -- 4. Create assignment records
    -- 5. Calculate coverage metrics
    
    -- For now, return sample metrics
    RETURN QUERY
    SELECT 
        v_assigned_count,
        85.5::DECIMAL as coverage_percentage,
        3 as skill_gaps,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Optimize skill coverage across all projects
CREATE OR REPLACE FUNCTION optimize_skill_coverage(
    p_date DATE,
    p_time_window_hours INTEGER DEFAULT 8
)
RETURNS TABLE (
    project_id INTEGER,
    initial_coverage DECIMAL,
    optimized_coverage DECIMAL,
    agents_reassigned INTEGER
) AS $$
BEGIN
    -- Implementation placeholder
    -- This will include:
    -- 1. Analyze current skill coverage by project
    -- 2. Identify underutilized agents
    -- 3. Reassign agents to maximize coverage
    -- 4. Respect agent skill levels and preferences
    -- 5. Return optimization results
    
    RETURN QUERY
    SELECT 
        p.project_id,
        75.0::DECIMAL as initial_coverage,
        88.5::DECIMAL as optimized_coverage,
        5 as agents_reassigned
    FROM projects p
    WHERE p.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Calculate skill gaps for planning period
CREATE OR REPLACE FUNCTION calculate_skill_gaps(
    p_project_id INTEGER DEFAULT NULL,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    project_name VARCHAR,
    skill_name VARCHAR,
    gap_date DATE,
    time_period VARCHAR,
    required_agents INTEGER,
    available_agents INTEGER,
    gap_count INTEGER,
    gap_severity VARCHAR
) AS $$
BEGIN
    -- Implementation placeholder
    -- This will include:
    -- 1. Calculate requirements by time period
    -- 2. Count available skilled agents
    -- 3. Identify gaps and severity
    -- 4. Prioritize critical gaps
    
    RETURN QUERY
    SELECT 
        'Project VTM'::VARCHAR,
        'English B2'::VARCHAR,
        CURRENT_DATE,
        '14:00-18:00'::VARCHAR,
        15,
        12,
        3,
        'medium'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. HELPER FUNCTIONS AND VIEWS
-- =====================================================================================

-- View for agent availability by skill
CREATE OR REPLACE VIEW v_agent_skill_availability AS
SELECT 
    a.agent_id,
    a.skill_id,
    s.skill_name,
    a.proficiency_level,
    COUNT(DISTINCT ma.assignment_date) as days_assigned,
    AVG(EXTRACT(HOUR FROM ma.time_slot_end - ma.time_slot_start)) as avg_hours_per_day
FROM agent_skills a
JOIN skills s ON a.skill_id = s.skill_id
LEFT JOIN multi_skill_assignments ma ON a.agent_id = ma.agent_id 
    AND ma.assignment_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE a.is_active = TRUE
GROUP BY a.agent_id, a.skill_id, s.skill_name, a.proficiency_level;

-- View for project skill coverage
CREATE OR REPLACE VIEW v_project_skill_coverage AS
SELECT 
    p.project_id,
    p.project_name,
    sr.skill_id,
    s.skill_name,
    sr.min_agents as required,
    COUNT(DISTINCT ma.agent_id) as assigned,
    CASE 
        WHEN sr.min_agents > 0 
        THEN (COUNT(DISTINCT ma.agent_id)::DECIMAL / sr.min_agents * 100)
        ELSE 100 
    END as coverage_percentage
FROM projects p
JOIN skill_requirements sr ON p.project_id = sr.project_id
JOIN skills s ON sr.skill_id = s.skill_id
LEFT JOIN multi_skill_assignments ma ON 
    p.project_id = ma.project_id 
    AND sr.skill_id = ma.skill_id
    AND ma.assignment_date >= CURRENT_DATE
WHERE p.is_active = TRUE
    AND sr.valid_from <= CURRENT_DATE
    AND (sr.valid_to IS NULL OR sr.valid_to >= CURRENT_DATE)
GROUP BY p.project_id, p.project_name, sr.skill_id, s.skill_name, sr.min_agents;

-- =====================================================================================
-- 10. PERMISSIONS AND COMMENTS
-- =====================================================================================

-- Add table comments
COMMENT ON TABLE agent_skills IS 'Tracks agent skills with proficiency levels for multi-skill scheduling';
COMMENT ON TABLE skill_requirements IS 'Defines minimum skill requirements per project/queue';
COMMENT ON TABLE multi_skill_assignments IS 'Agent assignments to projects with specific skills and time slots';
COMMENT ON TABLE projects IS 'Projects with varying complexity: B (1 queue), VTM (32+ queues), I (68+ queues), F (5 queues)';

-- Grant appropriate permissions (adjust user as needed)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_api_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_api_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_api_user;