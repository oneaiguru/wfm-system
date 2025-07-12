-- =====================================================================================
-- Quality Management Schema (014_quality_management.sql)
-- =====================================================================================
-- Purpose: Comprehensive quality management system for WFM
-- Author: Subagent 7
-- Date: 2025-07-11
-- Version: 1.0
-- 
-- Tables:
-- 1. sla_definitions - Service level agreements
-- 2. sla_tracking - Real-time SLA performance
-- 3. quality_metrics - Quality measurement definitions
-- 4. quality_evaluations - Call quality assessments
-- 5. coaching_sessions - Agent coaching records
-- 6. performance_reviews - Periodic reviews
-- 7. quality_alerts - Quality threshold alerts
-- 8. compliance_tracking - Regulatory compliance
-- 9. quality_reports - Quality reporting
-- 10. improvement_plans - Performance improvement
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =====================================================================================
-- 1. SLA DEFINITIONS - Service Level Agreements
-- =====================================================================================

CREATE TABLE sla_definitions (
    sla_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sla_name VARCHAR(100) NOT NULL,
    sla_type VARCHAR(50) NOT NULL CHECK (sla_type IN ('response_time', 'resolution_time', 'availability', 'quality_score', 'abandonment_rate', 'first_call_resolution')),
    description TEXT,
    metric_unit VARCHAR(20) NOT NULL CHECK (metric_unit IN ('seconds', 'minutes', 'hours', 'days', 'percentage', 'count')),
    target_value DECIMAL(10,2) NOT NULL,
    threshold_warning DECIMAL(10,2) NOT NULL,
    threshold_critical DECIMAL(10,2) NOT NULL,
    measurement_window_hours INTEGER NOT NULL DEFAULT 24,
    business_hours_only BOOLEAN NOT NULL DEFAULT FALSE,
    priority_levels TEXT[], -- JSON array of priority levels this SLA applies to
    service_categories TEXT[], -- JSON array of service categories
    client_id UUID REFERENCES clients(client_id),
    department_id UUID REFERENCES departments(department_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    escalation_rules JSONB, -- Rules for SLA breach escalation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id)
);

-- Indexes for sla_definitions
CREATE INDEX idx_sla_definitions_type ON sla_definitions(sla_type);
CREATE INDEX idx_sla_definitions_client ON sla_definitions(client_id);
CREATE INDEX idx_sla_definitions_department ON sla_definitions(department_id);
CREATE INDEX idx_sla_definitions_active ON sla_definitions(is_active);
CREATE INDEX idx_sla_definitions_created_at ON sla_definitions(created_at);

-- =====================================================================================
-- 2. SLA TRACKING - Real-time SLA Performance
-- =====================================================================================

CREATE TABLE sla_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sla_id UUID NOT NULL REFERENCES sla_definitions(sla_id),
    measurement_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    measurement_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_value DECIMAL(10,2) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    performance_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN target_value > 0 THEN (actual_value / target_value) * 100
            ELSE 0
        END
    ) STORED,
    status VARCHAR(20) NOT NULL CHECK (status IN ('meeting', 'warning', 'critical', 'breach')),
    sample_size INTEGER, -- Number of transactions measured
    breach_duration_minutes INTEGER, -- How long SLA was breached
    breach_details JSONB, -- Details about the breach
    corrective_actions TEXT[],
    responsible_team VARCHAR(100),
    client_id UUID REFERENCES clients(client_id),
    department_id UUID REFERENCES departments(department_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for sla_tracking
CREATE INDEX idx_sla_tracking_sla_id ON sla_tracking(sla_id);
CREATE INDEX idx_sla_tracking_period ON sla_tracking(measurement_period_start, measurement_period_end);
CREATE INDEX idx_sla_tracking_status ON sla_tracking(status);
CREATE INDEX idx_sla_tracking_client ON sla_tracking(client_id);
CREATE INDEX idx_sla_tracking_department ON sla_tracking(department_id);
CREATE INDEX idx_sla_tracking_performance ON sla_tracking(performance_percentage);

-- =====================================================================================
-- 3. QUALITY METRICS - Quality Measurement Definitions
-- =====================================================================================

CREATE TABLE quality_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_category VARCHAR(50) NOT NULL CHECK (metric_category IN ('communication', 'technical', 'process', 'compliance', 'customer_satisfaction')),
    description TEXT,
    measurement_type VARCHAR(30) NOT NULL CHECK (measurement_type IN ('binary', 'scale', 'percentage', 'count', 'duration')),
    scale_min INTEGER, -- For scale-based metrics
    scale_max INTEGER, -- For scale-based metrics
    weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    is_critical BOOLEAN NOT NULL DEFAULT FALSE, -- Critical metrics can fail entire evaluation
    evaluation_criteria JSONB, -- Detailed criteria for evaluation
    scoring_rules JSONB, -- Rules for converting raw scores to final scores
    department_id UUID REFERENCES departments(department_id),
    service_type VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id)
);

-- Indexes for quality_metrics
CREATE INDEX idx_quality_metrics_category ON quality_metrics(metric_category);
CREATE INDEX idx_quality_metrics_department ON quality_metrics(department_id);
CREATE INDEX idx_quality_metrics_service_type ON quality_metrics(service_type);
CREATE INDEX idx_quality_metrics_active ON quality_metrics(is_active);
CREATE INDEX idx_quality_metrics_critical ON quality_metrics(is_critical);

-- =====================================================================================
-- 4. QUALITY EVALUATIONS - Call Quality Assessments
-- =====================================================================================

CREATE TABLE quality_evaluations (
    evaluation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES employees(employee_id),
    evaluator_id UUID NOT NULL REFERENCES employees(employee_id),
    evaluation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    evaluation_type VARCHAR(30) NOT NULL CHECK (evaluation_type IN ('call_monitoring', 'chat_monitoring', 'email_monitoring', 'self_assessment', 'customer_feedback')),
    interaction_id VARCHAR(100), -- Reference to call/chat/email ID
    interaction_date TIMESTAMP WITH TIME ZONE,
    customer_id UUID,
    overall_score DECIMAL(5,2), -- Calculated overall score
    max_possible_score DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    performance_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN max_possible_score > 0 THEN (overall_score / max_possible_score) * 100
            ELSE 0
        END
    ) STORED,
    metric_scores JSONB, -- Individual metric scores
    strengths TEXT[],
    areas_for_improvement TEXT[],
    specific_feedback TEXT,
    action_items TEXT[],
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_date DATE,
    calibration_session_id UUID, -- Reference to calibration session
    is_calibrated BOOLEAN NOT NULL DEFAULT FALSE,
    client_id UUID REFERENCES clients(client_id),
    department_id UUID REFERENCES departments(department_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for quality_evaluations
CREATE INDEX idx_quality_evaluations_agent ON quality_evaluations(agent_id);
CREATE INDEX idx_quality_evaluations_evaluator ON quality_evaluations(evaluator_id);
CREATE INDEX idx_quality_evaluations_date ON quality_evaluations(evaluation_date);
CREATE INDEX idx_quality_evaluations_type ON quality_evaluations(evaluation_type);
CREATE INDEX idx_quality_evaluations_score ON quality_evaluations(overall_score);
CREATE INDEX idx_quality_evaluations_client ON quality_evaluations(client_id);
CREATE INDEX idx_quality_evaluations_department ON quality_evaluations(department_id);
CREATE INDEX idx_quality_evaluations_follow_up ON quality_evaluations(follow_up_required, follow_up_date);

-- =====================================================================================
-- 5. COACHING SESSIONS - Agent Coaching Records
-- =====================================================================================

CREATE TABLE coaching_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES employees(employee_id),
    coach_id UUID NOT NULL REFERENCES employees(employee_id),
    session_date TIMESTAMP WITH TIME ZONE NOT NULL,
    session_type VARCHAR(30) NOT NULL CHECK (session_type IN ('formal', 'informal', 'corrective', 'developmental', 'recognition')),
    session_duration_minutes INTEGER,
    trigger_evaluation_id UUID REFERENCES quality_evaluations(evaluation_id),
    goals_discussed TEXT[],
    action_items TEXT[],
    resources_provided TEXT[],
    agent_feedback TEXT,
    coach_observations TEXT,
    improvement_areas TEXT[],
    strengths_reinforced TEXT[],
    next_session_date DATE,
    session_status VARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (session_status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')),
    session_notes TEXT,
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_date DATE,
    effectiveness_rating INTEGER CHECK (effectiveness_rating BETWEEN 1 AND 5),
    agent_satisfaction_rating INTEGER CHECK (agent_satisfaction_rating BETWEEN 1 AND 5),
    department_id UUID REFERENCES departments(department_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for coaching_sessions
CREATE INDEX idx_coaching_sessions_agent ON coaching_sessions(agent_id);
CREATE INDEX idx_coaching_sessions_coach ON coaching_sessions(coach_id);
CREATE INDEX idx_coaching_sessions_date ON coaching_sessions(session_date);
CREATE INDEX idx_coaching_sessions_type ON coaching_sessions(session_type);
CREATE INDEX idx_coaching_sessions_status ON coaching_sessions(session_status);
CREATE INDEX idx_coaching_sessions_follow_up ON coaching_sessions(follow_up_required, follow_up_date);
CREATE INDEX idx_coaching_sessions_department ON coaching_sessions(department_id);

-- =====================================================================================
-- 6. PERFORMANCE REVIEWS - Periodic Reviews
-- =====================================================================================

CREATE TABLE performance_reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES employees(employee_id),
    reviewer_id UUID NOT NULL REFERENCES employees(employee_id),
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    review_type VARCHAR(30) NOT NULL CHECK (review_type IN ('monthly', 'quarterly', 'semi_annual', 'annual', 'probationary', 'ad_hoc')),
    overall_rating INTEGER NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
    quality_score_average DECIMAL(5,2),
    sla_performance_average DECIMAL(5,2),
    coaching_sessions_count INTEGER DEFAULT 0,
    evaluations_count INTEGER DEFAULT 0,
    customer_satisfaction_score DECIMAL(5,2),
    attendance_score DECIMAL(5,2),
    productivity_metrics JSONB,
    strengths TEXT[],
    development_areas TEXT[],
    goals_met TEXT[],
    goals_missed TEXT[],
    new_goals TEXT[],
    career_development_plan TEXT,
    training_recommendations TEXT[],
    salary_review_eligible BOOLEAN NOT NULL DEFAULT FALSE,
    promotion_eligible BOOLEAN NOT NULL DEFAULT FALSE,
    improvement_plan_required BOOLEAN NOT NULL DEFAULT FALSE,
    reviewer_comments TEXT,
    agent_comments TEXT,
    manager_approval_required BOOLEAN NOT NULL DEFAULT FALSE,
    manager_approved_by UUID REFERENCES employees(employee_id),
    manager_approved_at TIMESTAMP WITH TIME ZONE,
    review_status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (review_status IN ('draft', 'pending_approval', 'approved', 'published')),
    department_id UUID REFERENCES departments(department_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance_reviews
CREATE INDEX idx_performance_reviews_agent ON performance_reviews(agent_id);
CREATE INDEX idx_performance_reviews_reviewer ON performance_reviews(reviewer_id);
CREATE INDEX idx_performance_reviews_period ON performance_reviews(review_period_start, review_period_end);
CREATE INDEX idx_performance_reviews_type ON performance_reviews(review_type);
CREATE INDEX idx_performance_reviews_rating ON performance_reviews(overall_rating);
CREATE INDEX idx_performance_reviews_status ON performance_reviews(review_status);
CREATE INDEX idx_performance_reviews_department ON performance_reviews(department_id);

-- =====================================================================================
-- 7. QUALITY ALERTS - Quality Threshold Alerts
-- =====================================================================================

CREATE TABLE quality_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('sla_breach', 'quality_decline', 'performance_issue', 'compliance_violation', 'trend_alert')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    alert_title VARCHAR(200) NOT NULL,
    alert_description TEXT,
    affected_entity_type VARCHAR(30) NOT NULL CHECK (affected_entity_type IN ('agent', 'team', 'department', 'client', 'service')),
    affected_entity_id UUID,
    trigger_metric VARCHAR(100),
    trigger_value DECIMAL(10,2),
    threshold_value DECIMAL(10,2),
    alert_data JSONB, -- Additional alert-specific data
    alert_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (alert_status IN ('active', 'acknowledged', 'resolved', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID REFERENCES employees(employee_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES employees(employee_id),
    resolution_notes TEXT,
    escalation_level INTEGER NOT NULL DEFAULT 0,
    escalated_to UUID REFERENCES employees(employee_id),
    escalated_at TIMESTAMP WITH TIME ZONE,
    department_id UUID REFERENCES departments(department_id),
    client_id UUID REFERENCES clients(client_id)
);

-- Indexes for quality_alerts
CREATE INDEX idx_quality_alerts_type ON quality_alerts(alert_type);
CREATE INDEX idx_quality_alerts_severity ON quality_alerts(severity);
CREATE INDEX idx_quality_alerts_status ON quality_alerts(alert_status);
CREATE INDEX idx_quality_alerts_entity ON quality_alerts(affected_entity_type, affected_entity_id);
CREATE INDEX idx_quality_alerts_created_at ON quality_alerts(created_at);
CREATE INDEX idx_quality_alerts_department ON quality_alerts(department_id);
CREATE INDEX idx_quality_alerts_client ON quality_alerts(client_id);

-- =====================================================================================
-- 8. COMPLIANCE TRACKING - Regulatory Compliance
-- =====================================================================================

CREATE TABLE compliance_tracking (
    compliance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compliance_type VARCHAR(50) NOT NULL CHECK (compliance_type IN ('regulatory', 'internal_policy', 'client_requirement', 'industry_standard', 'certification')),
    compliance_name VARCHAR(100) NOT NULL,
    description TEXT,
    regulatory_body VARCHAR(100),
    compliance_level VARCHAR(30) NOT NULL CHECK (compliance_level IN ('agent', 'team', 'department', 'organization')),
    applicable_to_roles TEXT[], -- Array of roles this compliance applies to
    compliance_requirements JSONB, -- Detailed requirements
    assessment_frequency VARCHAR(30) NOT NULL CHECK (assessment_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'annually', 'as_needed')),
    last_assessment_date DATE,
    next_assessment_date DATE,
    current_status VARCHAR(20) NOT NULL CHECK (current_status IN ('compliant', 'non_compliant', 'pending_review', 'remediation_required')),
    compliance_score DECIMAL(5,2),
    violations_count INTEGER DEFAULT 0,
    recent_violations JSONB, -- Recent violation details
    remediation_plan TEXT,
    responsible_person UUID REFERENCES employees(employee_id),
    documentation_links TEXT[],
    training_requirements TEXT[],
    audit_trail JSONB, -- Audit trail for compliance changes
    department_id UUID REFERENCES departments(department_id),
    client_id UUID REFERENCES clients(client_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for compliance_tracking
CREATE INDEX idx_compliance_tracking_type ON compliance_tracking(compliance_type);
CREATE INDEX idx_compliance_tracking_level ON compliance_tracking(compliance_level);
CREATE INDEX idx_compliance_tracking_status ON compliance_tracking(current_status);
CREATE INDEX idx_compliance_tracking_assessment ON compliance_tracking(next_assessment_date);
CREATE INDEX idx_compliance_tracking_responsible ON compliance_tracking(responsible_person);
CREATE INDEX idx_compliance_tracking_department ON compliance_tracking(department_id);
CREATE INDEX idx_compliance_tracking_client ON compliance_tracking(client_id);

-- =====================================================================================
-- 9. QUALITY REPORTS - Quality Reporting
-- =====================================================================================

CREATE TABLE quality_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(200) NOT NULL,
    report_type VARCHAR(30) NOT NULL CHECK (report_type IN ('quality_scorecard', 'sla_performance', 'compliance_status', 'coaching_summary', 'trend_analysis', 'comparative_analysis')),
    report_scope VARCHAR(30) NOT NULL CHECK (report_scope IN ('agent', 'team', 'department', 'client', 'organization')),
    scope_entity_id UUID,
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    report_data JSONB, -- The actual report data
    report_summary TEXT,
    key_insights TEXT[],
    recommendations TEXT[],
    charts_config JSONB, -- Configuration for charts and visualizations
    report_format VARCHAR(20) NOT NULL CHECK (report_format IN ('dashboard', 'pdf', 'excel', 'csv')),
    is_automated BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_frequency VARCHAR(30) CHECK (schedule_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'annually')),
    next_generation_date DATE,
    recipients TEXT[], -- List of email addresses or user IDs
    report_status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (report_status IN ('draft', 'generating', 'ready', 'sent', 'error')),
    generated_by UUID REFERENCES employees(employee_id),
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_sent_at TIMESTAMP WITH TIME ZONE,
    department_id UUID REFERENCES departments(department_id),
    client_id UUID REFERENCES clients(client_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for quality_reports
CREATE INDEX idx_quality_reports_type ON quality_reports(report_type);
CREATE INDEX idx_quality_reports_scope ON quality_reports(report_scope, scope_entity_id);
CREATE INDEX idx_quality_reports_period ON quality_reports(reporting_period_start, reporting_period_end);
CREATE INDEX idx_quality_reports_status ON quality_reports(report_status);
CREATE INDEX idx_quality_reports_generated_by ON quality_reports(generated_by);
CREATE INDEX idx_quality_reports_department ON quality_reports(department_id);
CREATE INDEX idx_quality_reports_client ON quality_reports(client_id);

-- =====================================================================================
-- 10. IMPROVEMENT PLANS - Performance Improvement
-- =====================================================================================

CREATE TABLE improvement_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES employees(employee_id),
    plan_name VARCHAR(200) NOT NULL,
    plan_type VARCHAR(30) NOT NULL CHECK (plan_type IN ('performance', 'quality', 'compliance', 'development', 'corrective')),
    trigger_source VARCHAR(30) NOT NULL CHECK (trigger_source IN ('performance_review', 'quality_evaluation', 'sla_breach', 'compliance_violation', 'manager_discretion')),
    trigger_reference_id UUID, -- Reference to the triggering record
    plan_status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (plan_status IN ('draft', 'active', 'completed', 'cancelled', 'extended')),
    start_date DATE NOT NULL,
    target_completion_date DATE NOT NULL,
    actual_completion_date DATE,
    plan_description TEXT,
    current_performance_level DECIMAL(5,2),
    target_performance_level DECIMAL(5,2),
    success_criteria TEXT[],
    action_items JSONB, -- Structured action items with deadlines
    milestones JSONB, -- Key milestones and checkpoints
    resources_provided TEXT[],
    training_required TEXT[],
    support_needed TEXT[],
    progress_updates JSONB, -- Progress tracking entries
    barriers_identified TEXT[],
    manager_id UUID NOT NULL REFERENCES employees(employee_id),
    hr_approved BOOLEAN NOT NULL DEFAULT FALSE,
    hr_approved_by UUID REFERENCES employees(employee_id),
    hr_approved_at TIMESTAMP WITH TIME ZONE,
    agent_agreement BOOLEAN NOT NULL DEFAULT FALSE,
    agent_agreed_at TIMESTAMP WITH TIME ZONE,
    review_frequency VARCHAR(30) NOT NULL DEFAULT 'weekly' CHECK (review_frequency IN ('daily', 'weekly', 'bi_weekly', 'monthly')),
    next_review_date DATE,
    final_outcome VARCHAR(30) CHECK (final_outcome IN ('successful', 'partially_successful', 'unsuccessful', 'extended', 'cancelled')),
    final_assessment TEXT,
    lessons_learned TEXT[],
    department_id UUID REFERENCES departments(department_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for improvement_plans
CREATE INDEX idx_improvement_plans_agent ON improvement_plans(agent_id);
CREATE INDEX idx_improvement_plans_manager ON improvement_plans(manager_id);
CREATE INDEX idx_improvement_plans_type ON improvement_plans(plan_type);
CREATE INDEX idx_improvement_plans_status ON improvement_plans(plan_status);
CREATE INDEX idx_improvement_plans_dates ON improvement_plans(start_date, target_completion_date);
CREATE INDEX idx_improvement_plans_review ON improvement_plans(next_review_date);
CREATE INDEX idx_improvement_plans_department ON improvement_plans(department_id);

-- =====================================================================================
-- INTEGRATION FUNCTIONS FOR UI-OPUS
-- =====================================================================================

-- Function to get agent quality dashboard data
CREATE OR REPLACE FUNCTION get_agent_quality_dashboard(
    p_agent_id UUID,
    p_period_start DATE DEFAULT (CURRENT_DATE - INTERVAL '30 days'),
    p_period_end DATE DEFAULT CURRENT_DATE
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    avg_quality_score DECIMAL(5,2);
    evaluations_count INTEGER;
    coaching_sessions_count INTEGER;
    active_improvement_plans INTEGER;
    recent_alerts_count INTEGER;
BEGIN
    -- Get average quality score
    SELECT AVG(overall_score) INTO avg_quality_score
    FROM quality_evaluations
    WHERE agent_id = p_agent_id
    AND evaluation_date BETWEEN p_period_start AND p_period_end;
    
    -- Get evaluations count
    SELECT COUNT(*) INTO evaluations_count
    FROM quality_evaluations
    WHERE agent_id = p_agent_id
    AND evaluation_date BETWEEN p_period_start AND p_period_end;
    
    -- Get coaching sessions count
    SELECT COUNT(*) INTO coaching_sessions_count
    FROM coaching_sessions
    WHERE agent_id = p_agent_id
    AND session_date BETWEEN p_period_start AND p_period_end;
    
    -- Get active improvement plans
    SELECT COUNT(*) INTO active_improvement_plans
    FROM improvement_plans
    WHERE agent_id = p_agent_id
    AND plan_status = 'active';
    
    -- Get recent alerts
    SELECT COUNT(*) INTO recent_alerts_count
    FROM quality_alerts
    WHERE affected_entity_type = 'agent'
    AND affected_entity_id = p_agent_id
    AND alert_status = 'active'
    AND created_at >= p_period_start;
    
    -- Build result
    result := jsonb_build_object(
        'agent_id', p_agent_id,
        'period_start', p_period_start,
        'period_end', p_period_end,
        'average_quality_score', COALESCE(avg_quality_score, 0),
        'evaluations_count', evaluations_count,
        'coaching_sessions_count', coaching_sessions_count,
        'active_improvement_plans', active_improvement_plans,
        'recent_alerts_count', recent_alerts_count,
        'generated_at', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate SLA performance
CREATE OR REPLACE FUNCTION calculate_sla_performance(
    p_sla_id UUID,
    p_period_start TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP - INTERVAL '24 hours'),
    p_period_end TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) RETURNS JSONB AS $$
DECLARE
    sla_record RECORD;
    performance_data JSONB;
    current_value DECIMAL(10,2);
    performance_percentage DECIMAL(5,2);
    status VARCHAR(20);
BEGIN
    -- Get SLA definition
    SELECT * INTO sla_record
    FROM sla_definitions
    WHERE sla_id = p_sla_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'SLA not found');
    END IF;
    
    -- Calculate current performance (simplified example)
    -- This would need to be customized based on actual data sources
    current_value := 0.0;
    
    -- Calculate performance percentage
    performance_percentage := CASE 
        WHEN sla_record.target_value > 0 THEN 
            (current_value / sla_record.target_value) * 100
        ELSE 0
    END;
    
    -- Determine status
    status := CASE
        WHEN current_value <= sla_record.target_value THEN 'meeting'
        WHEN current_value <= sla_record.threshold_warning THEN 'warning'
        WHEN current_value <= sla_record.threshold_critical THEN 'critical'
        ELSE 'breach'
    END;
    
    -- Build result
    performance_data := jsonb_build_object(
        'sla_id', p_sla_id,
        'sla_name', sla_record.sla_name,
        'period_start', p_period_start,
        'period_end', p_period_end,
        'current_value', current_value,
        'target_value', sla_record.target_value,
        'performance_percentage', performance_percentage,
        'status', status,
        'calculated_at', CURRENT_TIMESTAMP
    );
    
    RETURN performance_data;
END;
$$ LANGUAGE plpgsql;

-- Function to generate quality evaluation
CREATE OR REPLACE FUNCTION generate_quality_evaluation(
    p_agent_id UUID,
    p_evaluator_id UUID,
    p_interaction_id VARCHAR(100),
    p_evaluation_type VARCHAR(30),
    p_metric_scores JSONB
) RETURNS UUID AS $$
DECLARE
    evaluation_id UUID;
    overall_score DECIMAL(5,2);
    max_score DECIMAL(5,2);
    metric_record RECORD;
    score_value DECIMAL(5,2);
BEGIN
    -- Generate evaluation ID
    evaluation_id := uuid_generate_v4();
    
    -- Calculate overall score
    overall_score := 0;
    max_score := 0;
    
    FOR metric_record IN 
        SELECT metric_id, weight_percentage, scale_max
        FROM quality_metrics
        WHERE is_active = TRUE
    LOOP
        score_value := COALESCE((p_metric_scores->metric_record.metric_id::text)::DECIMAL(5,2), 0);
        overall_score := overall_score + (score_value * metric_record.weight_percentage / 100);
        max_score := max_score + (COALESCE(metric_record.scale_max, 100) * metric_record.weight_percentage / 100);
    END LOOP;
    
    -- Insert evaluation
    INSERT INTO quality_evaluations (
        evaluation_id,
        agent_id,
        evaluator_id,
        evaluation_type,
        interaction_id,
        overall_score,
        max_possible_score,
        metric_scores
    ) VALUES (
        evaluation_id,
        p_agent_id,
        p_evaluator_id,
        p_evaluation_type,
        p_interaction_id,
        overall_score,
        max_score,
        p_metric_scores
    );
    
    RETURN evaluation_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create improvement plan
CREATE OR REPLACE FUNCTION create_improvement_plan(
    p_agent_id UUID,
    p_manager_id UUID,
    p_plan_name VARCHAR(200),
    p_plan_type VARCHAR(30),
    p_trigger_source VARCHAR(30),
    p_trigger_reference_id UUID,
    p_target_completion_date DATE,
    p_action_items JSONB
) RETURNS UUID AS $$
DECLARE
    plan_id UUID;
BEGIN
    plan_id := uuid_generate_v4();
    
    INSERT INTO improvement_plans (
        plan_id,
        agent_id,
        manager_id,
        plan_name,
        plan_type,
        trigger_source,
        trigger_reference_id,
        start_date,
        target_completion_date,
        action_items,
        plan_status
    ) VALUES (
        plan_id,
        p_agent_id,
        p_manager_id,
        p_plan_name,
        p_plan_type,
        p_trigger_source,
        p_trigger_reference_id,
        CURRENT_DATE,
        p_target_completion_date,
        p_action_items,
        'active'
    );
    
    RETURN plan_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SAMPLE DATA GENERATORS
-- =====================================================================================

-- Function to generate sample SLA definitions
CREATE OR REPLACE FUNCTION generate_sample_sla_definitions()
RETURNS VOID AS $$
BEGIN
    -- Response Time SLA
    INSERT INTO sla_definitions (sla_name, sla_type, description, metric_unit, target_value, threshold_warning, threshold_critical, measurement_window_hours)
    VALUES 
    ('Call Response Time', 'response_time', 'Average time to answer incoming calls', 'seconds', 20, 30, 45, 24),
    ('Chat Response Time', 'response_time', 'Average time to respond to chat messages', 'seconds', 60, 90, 120, 24),
    ('Email Response Time', 'response_time', 'Average time to respond to emails', 'hours', 4, 8, 24, 24),
    ('Service Availability', 'availability', 'System uptime percentage', 'percentage', 99.5, 99.0, 95.0, 24),
    ('Call Abandonment Rate', 'abandonment_rate', 'Percentage of calls abandoned', 'percentage', 5.0, 10.0, 15.0, 24),
    ('First Call Resolution', 'first_call_resolution', 'Percentage of calls resolved on first contact', 'percentage', 85.0, 80.0, 75.0, 24);
    
    RAISE NOTICE 'Sample SLA definitions generated successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample quality metrics
CREATE OR REPLACE FUNCTION generate_sample_quality_metrics()
RETURNS VOID AS $$
BEGIN
    INSERT INTO quality_metrics (metric_name, metric_category, description, measurement_type, scale_min, scale_max, weight_percentage, is_critical)
    VALUES 
    ('Communication Clarity', 'communication', 'How clearly the agent communicates', 'scale', 1, 5, 15.0, FALSE),
    ('Active Listening', 'communication', 'Agent demonstrates active listening skills', 'scale', 1, 5, 10.0, FALSE),
    ('Problem Resolution', 'technical', 'Agent ability to resolve customer issues', 'scale', 1, 5, 20.0, TRUE),
    ('Product Knowledge', 'technical', 'Agent knowledge of products and services', 'scale', 1, 5, 15.0, FALSE),
    ('Process Adherence', 'process', 'Following standard operating procedures', 'scale', 1, 5, 10.0, TRUE),
    ('Call Control', 'process', 'Agent ability to manage call flow', 'scale', 1, 5, 10.0, FALSE),
    ('Compliance Adherence', 'compliance', 'Following regulatory requirements', 'binary', 0, 1, 20.0, TRUE);
    
    RAISE NOTICE 'Sample quality metrics generated successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample data for all tables
CREATE OR REPLACE FUNCTION generate_sample_quality_data()
RETURNS VOID AS $$
BEGIN
    -- Generate SLA definitions
    PERFORM generate_sample_sla_definitions();
    
    -- Generate quality metrics
    PERFORM generate_sample_quality_metrics();
    
    RAISE NOTICE 'All sample quality management data generated successfully';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SLA MONITORING CAPABILITIES
-- =====================================================================================

-- Function to check SLA breaches
CREATE OR REPLACE FUNCTION check_sla_breaches()
RETURNS VOID AS $$
DECLARE
    sla_record RECORD;
    current_performance DECIMAL(10,2);
    alert_id UUID;
BEGIN
    FOR sla_record IN 
        SELECT * FROM sla_definitions WHERE is_active = TRUE
    LOOP
        -- Calculate current performance (simplified)
        current_performance := 0.0;
        
        -- Check if SLA is breached
        IF current_performance > sla_record.threshold_critical THEN
            -- Create critical alert
            INSERT INTO quality_alerts (
                alert_type,
                severity,
                alert_title,
                alert_description,
                affected_entity_type,
                trigger_metric,
                trigger_value,
                threshold_value,
                alert_data
            ) VALUES (
                'sla_breach',
                'critical',
                'SLA Breach: ' || sla_record.sla_name,
                'SLA has been breached for ' || sla_record.sla_name,
                'service',
                sla_record.sla_name,
                current_performance,
                sla_record.target_value,
                jsonb_build_object('sla_id', sla_record.sla_id, 'sla_type', sla_record.sla_type)
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to update SLA tracking
CREATE OR REPLACE FUNCTION update_sla_tracking(
    p_sla_id UUID,
    p_actual_value DECIMAL(10,2),
    p_sample_size INTEGER DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    sla_record RECORD;
    tracking_status VARCHAR(20);
BEGIN
    -- Get SLA definition
    SELECT * INTO sla_record FROM sla_definitions WHERE sla_id = p_sla_id;
    
    -- Determine status
    tracking_status := CASE
        WHEN p_actual_value <= sla_record.target_value THEN 'meeting'
        WHEN p_actual_value <= sla_record.threshold_warning THEN 'warning'
        WHEN p_actual_value <= sla_record.threshold_critical THEN 'critical'
        ELSE 'breach'
    END;
    
    -- Insert tracking record
    INSERT INTO sla_tracking (
        sla_id,
        measurement_period_start,
        measurement_period_end,
        actual_value,
        target_value,
        status,
        sample_size
    ) VALUES (
        p_sla_id,
        CURRENT_TIMESTAMP - INTERVAL '1 hour',
        CURRENT_TIMESTAMP,
        p_actual_value,
        sla_record.target_value,
        tracking_status,
        p_sample_size
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- QUALITY SCORING SYSTEM
-- =====================================================================================

-- Function to calculate quality score
CREATE OR REPLACE FUNCTION calculate_quality_score(
    p_metric_scores JSONB
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    metric_record RECORD;
    total_score DECIMAL(5,2) := 0;
    total_weight DECIMAL(5,2) := 0;
    metric_score DECIMAL(5,2);
    weighted_score DECIMAL(5,2);
BEGIN
    FOR metric_record IN 
        SELECT metric_id, weight_percentage, scale_max, is_critical
        FROM quality_metrics
        WHERE is_active = TRUE
    LOOP
        -- Get metric score
        metric_score := COALESCE((p_metric_scores->metric_record.metric_id::text)::DECIMAL(5,2), 0);
        
        -- Check if critical metric failed
        IF metric_record.is_critical AND metric_score < (metric_record.scale_max * 0.6) THEN
            -- Critical failure - return 0
            RETURN 0;
        END IF;
        
        -- Calculate weighted score
        weighted_score := (metric_score / metric_record.scale_max) * metric_record.weight_percentage;
        total_score := total_score + weighted_score;
        total_weight := total_weight + metric_record.weight_percentage;
    END LOOP;
    
    -- Return normalized score
    RETURN CASE 
        WHEN total_weight > 0 THEN (total_score / total_weight) * 100
        ELSE 0
    END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COACHING AND PERFORMANCE TRACKING
-- =====================================================================================

-- Function to track coaching effectiveness
CREATE OR REPLACE FUNCTION track_coaching_effectiveness(
    p_agent_id UUID,
    p_period_months INTEGER DEFAULT 3
) RETURNS JSONB AS $$
DECLARE
    coaching_stats JSONB;
    quality_improvement DECIMAL(5,2);
    sessions_count INTEGER;
    avg_effectiveness DECIMAL(5,2);
BEGIN
    -- Get coaching sessions count
    SELECT COUNT(*) INTO sessions_count
    FROM coaching_sessions
    WHERE agent_id = p_agent_id
    AND session_date >= CURRENT_DATE - INTERVAL '1 month' * p_period_months;
    
    -- Get average effectiveness rating
    SELECT AVG(effectiveness_rating) INTO avg_effectiveness
    FROM coaching_sessions
    WHERE agent_id = p_agent_id
    AND session_date >= CURRENT_DATE - INTERVAL '1 month' * p_period_months
    AND effectiveness_rating IS NOT NULL;
    
    -- Calculate quality improvement
    WITH quality_before AS (
        SELECT AVG(overall_score) as avg_score
        FROM quality_evaluations
        WHERE agent_id = p_agent_id
        AND evaluation_date BETWEEN 
            CURRENT_DATE - INTERVAL '1 month' * (p_period_months * 2)
            AND CURRENT_DATE - INTERVAL '1 month' * p_period_months
    ),
    quality_after AS (
        SELECT AVG(overall_score) as avg_score
        FROM quality_evaluations
        WHERE agent_id = p_agent_id
        AND evaluation_date >= CURRENT_DATE - INTERVAL '1 month' * p_period_months
    )
    SELECT 
        COALESCE(qa.avg_score, 0) - COALESCE(qb.avg_score, 0)
    INTO quality_improvement
    FROM quality_before qb, quality_after qa;
    
    -- Build result
    coaching_stats := jsonb_build_object(
        'agent_id', p_agent_id,
        'period_months', p_period_months,
        'sessions_count', sessions_count,
        'avg_effectiveness_rating', COALESCE(avg_effectiveness, 0),
        'quality_improvement', COALESCE(quality_improvement, 0),
        'calculated_at', CURRENT_TIMESTAMP
    );
    
    RETURN coaching_stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================================================

-- Update timestamps trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
CREATE TRIGGER update_sla_definitions_updated_at
    BEFORE UPDATE ON sla_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sla_tracking_updated_at
    BEFORE UPDATE ON sla_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quality_metrics_updated_at
    BEFORE UPDATE ON quality_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quality_evaluations_updated_at
    BEFORE UPDATE ON quality_evaluations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_coaching_sessions_updated_at
    BEFORE UPDATE ON coaching_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_performance_reviews_updated_at
    BEFORE UPDATE ON performance_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compliance_tracking_updated_at
    BEFORE UPDATE ON compliance_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quality_reports_updated_at
    BEFORE UPDATE ON quality_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_improvement_plans_updated_at
    BEFORE UPDATE ON improvement_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================================================

COMMENT ON TABLE sla_definitions IS 'Service Level Agreement definitions and thresholds';
COMMENT ON TABLE sla_tracking IS 'Real-time SLA performance tracking and monitoring';
COMMENT ON TABLE quality_metrics IS 'Quality measurement definitions and scoring criteria';
COMMENT ON TABLE quality_evaluations IS 'Individual quality assessments and evaluations';
COMMENT ON TABLE coaching_sessions IS 'Agent coaching sessions and development tracking';
COMMENT ON TABLE performance_reviews IS 'Periodic performance reviews and ratings';
COMMENT ON TABLE quality_alerts IS 'Quality threshold alerts and notifications';
COMMENT ON TABLE compliance_tracking IS 'Regulatory compliance monitoring and tracking';
COMMENT ON TABLE quality_reports IS 'Quality reporting and analytics';
COMMENT ON TABLE improvement_plans IS 'Performance improvement plans and tracking';

-- =====================================================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- View for agent quality summary
CREATE VIEW agent_quality_summary AS
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department_id,
    COUNT(qe.evaluation_id) as total_evaluations,
    AVG(qe.overall_score) as avg_quality_score,
    COUNT(cs.session_id) as coaching_sessions,
    COUNT(CASE WHEN qa.alert_status = 'active' THEN 1 END) as active_alerts,
    COUNT(CASE WHEN ip.plan_status = 'active' THEN 1 END) as active_improvement_plans
FROM employees e
LEFT JOIN quality_evaluations qe ON e.employee_id = qe.agent_id
LEFT JOIN coaching_sessions cs ON e.employee_id = cs.agent_id
LEFT JOIN quality_alerts qa ON e.employee_id = qa.affected_entity_id AND qa.affected_entity_type = 'agent'
LEFT JOIN improvement_plans ip ON e.employee_id = ip.agent_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department_id;

-- View for SLA performance dashboard
CREATE VIEW sla_performance_dashboard AS
SELECT 
    sd.sla_id,
    sd.sla_name,
    sd.sla_type,
    sd.target_value,
    st.actual_value,
    st.performance_percentage,
    st.status,
    st.measurement_period_start,
    st.measurement_period_end,
    CASE 
        WHEN st.status = 'meeting' THEN 'success'
        WHEN st.status = 'warning' THEN 'warning'
        WHEN st.status IN ('critical', 'breach') THEN 'danger'
        ELSE 'info'
    END as status_color
FROM sla_definitions sd
LEFT JOIN LATERAL (
    SELECT * FROM sla_tracking st2
    WHERE st2.sla_id = sd.sla_id
    ORDER BY st2.measurement_period_end DESC
    LIMIT 1
) st ON true
WHERE sd.is_active = TRUE;

-- =====================================================================================
-- SCHEMA VALIDATION
-- =====================================================================================

-- Function to validate schema integrity
CREATE OR REPLACE FUNCTION validate_quality_schema()
RETURNS BOOLEAN AS $$
DECLARE
    table_count INTEGER;
    expected_tables INTEGER := 10;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN (
        'sla_definitions',
        'sla_tracking',
        'quality_metrics',
        'quality_evaluations',
        'coaching_sessions',
        'performance_reviews',
        'quality_alerts',
        'compliance_tracking',
        'quality_reports',
        'improvement_plans'
    );
    
    IF table_count = expected_tables THEN
        RAISE NOTICE 'Quality management schema validation: PASSED (% tables found)', table_count;
        RETURN TRUE;
    ELSE
        RAISE NOTICE 'Quality management schema validation: FAILED (% of % tables found)', table_count, expected_tables;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Run schema validation
SELECT validate_quality_schema();

-- =====================================================================================
-- END OF QUALITY MANAGEMENT SCHEMA
-- =====================================================================================

-- Final success message
DO $$
BEGIN
    RAISE NOTICE 'Quality Management Schema (014_quality_management.sql) created successfully!';
    RAISE NOTICE 'Tables created: 10';
    RAISE NOTICE 'Functions created: 12';
    RAISE NOTICE 'Views created: 2';
    RAISE NOTICE 'Triggers created: 9';
    RAISE NOTICE 'Schema supports: SLA monitoring, quality scoring, coaching tracking, compliance management';
END $$;