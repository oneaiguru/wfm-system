-- =============================================================================
-- 050_preference_management_enhancements.sql
-- EXACT BDD Implementation: Preference Management Enhancements with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 24-preference-management-enhancements.feature (254 lines)
-- Purpose: Comprehensive employee preference management with analytics and optimization
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. PREFERENCE TYPE DEFINITIONS
-- =============================================================================

-- Preference type classifications from BDD line 18
CREATE TABLE preference_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_id VARCHAR(50) NOT NULL UNIQUE,
    type_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'shift_preferences', 'vacation_preferences', 'skill_preferences',
        'environment_preferences', 'notification_preferences', 'system_preferences'
    )),
    
    -- Weighting and priority from BDD lines 26-27
    weight DECIMAL(3,2) DEFAULT 1.0 CHECK (weight >= 0.0 AND weight <= 10.0),
    default_priority VARCHAR(20) DEFAULT 'medium' CHECK (default_priority IN ('low', 'medium', 'high', 'critical')),
    
    -- Configuration metadata
    configuration_schema JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT false,
    system_managed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. EMPLOYEE PREFERENCES
-- =============================================================================

-- Individual employee preferences from BDD line 19
CREATE TABLE employee_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pref_id VARCHAR(50) NOT NULL,
    employee_id UUID NOT NULL,
    type_id VARCHAR(50) NOT NULL,
    
    -- Preference value and configuration
    preference_value JSONB NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    
    -- Temporal settings from BDD line 19
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Flexibility and optimization from BDD lines 51-52
    flexibility_factor INTEGER DEFAULT 5 CHECK (flexibility_factor >= 1 AND flexibility_factor <= 10),
    seasonal_adjustment JSONB DEFAULT '{}',
    
    -- Status and metadata
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending', 'conflicted')),
    source VARCHAR(30) DEFAULT 'manual' CHECK (source IN ('manual', 'template', 'system', 'imported')),
    
    -- Approval workflow
    requires_approval BOOLEAN DEFAULT false,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES preference_types(type_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(employee_id, type_id, effective_date)
);

-- =============================================================================
-- 3. PREFERENCE CONFLICTS
-- =============================================================================

-- Conflict management from BDD line 20
CREATE TABLE preference_conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conflict_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    
    -- Conflict details
    conflicting_prefs JSONB NOT NULL,
    conflict_type VARCHAR(50) NOT NULL CHECK (conflict_type IN (
        'schedule_overlap', 'resource_conflict', 'skill_mismatch', 
        'policy_violation', 'team_conflict', 'location_conflict'
    )),
    
    -- Resolution from BDD lines 27-28
    resolution_type VARCHAR(30) DEFAULT 'pending' CHECK (resolution_type IN (
        'pending', 'automatic', 'manual', 'escalated', 'resolved', 'ignored'
    )),
    resolution_details TEXT,
    resolved_by UUID,
    resolved_date TIMESTAMP WITH TIME ZONE,
    
    -- Priority and impact
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    impact_assessment TEXT,
    
    -- Tracking
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 4. PREFERENCE ANALYTICS
-- =============================================================================

-- Analytics data from BDD line 21
CREATE TABLE preference_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analytics_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    
    -- Satisfaction metrics from BDD lines 28-29
    satisfaction_score DECIMAL(3,2) CHECK (satisfaction_score >= 0.0 AND satisfaction_score <= 10.0),
    fulfillment_rate DECIMAL(5,2) CHECK (fulfillment_rate >= 0.0 AND fulfillment_rate <= 100.0),
    
    -- Trend and pattern data
    trend_data JSONB DEFAULT '{}',
    pattern_analysis JSONB DEFAULT '{}',
    prediction_data JSONB DEFAULT '{}',
    
    -- Time period
    analysis_period_start DATE NOT NULL,
    analysis_period_end DATE NOT NULL,
    analysis_type VARCHAR(50) DEFAULT 'standard' CHECK (analysis_type IN (
        'standard', 'detailed', 'predictive', 'comparative'
    )),
    
    -- Calculation metadata
    calculation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calculation_version VARCHAR(20) DEFAULT '1.0',
    data_quality_score DECIMAL(3,2) DEFAULT 1.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    CHECK (analysis_period_end >= analysis_period_start)
);

-- =============================================================================
-- 5. PREFERENCE TEMPLATES
-- =============================================================================

-- Template preferences from BDD line 22
CREATE TABLE preference_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id VARCHAR(50) NOT NULL UNIQUE,
    template_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Template scope
    department_id UUID,
    role_id UUID,
    skill_group VARCHAR(100),
    location_id UUID,
    
    -- Template content from BDD line 22
    preference_set JSONB NOT NULL,
    default_values JSONB DEFAULT '{}',
    
    -- Template behavior
    inheritance_type VARCHAR(20) DEFAULT 'override' CHECK (inheritance_type IN (
        'override', 'merge', 'append', 'conditional'
    )),
    auto_apply BOOLEAN DEFAULT false,
    requires_consent BOOLEAN DEFAULT true,
    
    -- Version control
    version VARCHAR(20) DEFAULT '1.0',
    parent_template_id UUID,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (parent_template_id) REFERENCES preference_templates(id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. PREFERENCE HISTORY
-- =============================================================================

-- Change history from BDD line 23
CREATE TABLE preference_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    history_id VARCHAR(50) NOT NULL,
    employee_id UUID NOT NULL,
    preference_id UUID,
    
    -- Change tracking from BDD line 23
    old_value JSONB,
    new_value JSONB,
    change_type VARCHAR(30) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'activated', 'deactivated', 'resolved'
    )),
    
    -- Change context
    change_reason TEXT,
    change_source VARCHAR(30) CHECK (change_source IN (
        'user', 'admin', 'system', 'template', 'import', 'api'
    )),
    
    -- Change metadata
    changed_by UUID NOT NULL,
    change_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    
    -- Impact assessment
    impact_level VARCHAR(20) DEFAULT 'low' CHECK (impact_level IN ('low', 'medium', 'high')),
    affected_schedules INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (preference_id) REFERENCES employee_preferences(id) ON DELETE SET NULL,
    FOREIGN KEY (changed_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 7. SHIFT PREFERENCES
-- =============================================================================

-- Advanced shift preferences from BDD lines 42-61
CREATE TABLE shift_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_name VARCHAR(100) NOT NULL,
    
    -- Shift timing preferences from BDD lines 44-48
    preferred_start_times TIME[],
    preferred_duration INTERVAL,
    preferred_patterns JSONB DEFAULT '[]',
    preferred_break_times TIME[],
    overtime_preference VARCHAR(20) DEFAULT 'conditional' CHECK (overtime_preference IN (
        'yes', 'no', 'conditional', 'emergency_only'
    )),
    
    -- Advanced parameters from BDD lines 51-55
    flexibility_factor INTEGER DEFAULT 5 CHECK (flexibility_factor >= 1 AND flexibility_factor <= 10),
    seasonal_adjustment JSONB DEFAULT '{}',
    skill_based_preference JSONB DEFAULT '{}',
    team_preference JSONB DEFAULT '{}',
    location_preference JSONB DEFAULT '{}',
    
    -- Optimization settings from BDD lines 57-61
    preference_weight DECIMAL(3,2) DEFAULT 1.0 CHECK (preference_weight >= 0.0 AND preference_weight <= 10.0),
    conflict_resolution_priority INTEGER DEFAULT 5,
    satisfaction_threshold DECIMAL(3,2) DEFAULT 7.0,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(employee_id, preference_name, effective_date)
);

-- =============================================================================
-- 8. VACATION PREFERENCES
-- =============================================================================

-- Vacation and time-off preferences from BDD lines 64-86
CREATE TABLE vacation_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_name VARCHAR(100) NOT NULL,
    
    -- Vacation timing from BDD lines 68-73
    preferred_periods JSONB DEFAULT '[]', -- Date ranges
    preferred_duration_weeks INTEGER[],
    blackout_periods JSONB DEFAULT '[]',
    vacation_patterns JSONB DEFAULT '{}',
    emergency_flexibility BOOLEAN DEFAULT true,
    
    -- Planning parameters from BDD lines 75-80
    advance_notice_days INTEGER DEFAULT 30,
    approval_priority_factor DECIMAL(3,2) DEFAULT 1.0,
    conflict_resolution_preference VARCHAR(30) DEFAULT 'automatic' CHECK (conflict_resolution_preference IN (
        'automatic', 'manual', 'seniority_based', 'skill_based'
    )),
    seasonal_weighting JSONB DEFAULT '{}',
    team_coordination_required BOOLEAN DEFAULT true,
    
    -- Optimization settings from BDD lines 82-86
    demand_smoothing_weight DECIMAL(3,2) DEFAULT 1.0,
    satisfaction_priority DECIMAL(3,2) DEFAULT 1.0,
    business_alignment_priority DECIMAL(3,2) DEFAULT 1.0,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(employee_id, preference_name, effective_year)
);

-- =============================================================================
-- 9. SKILL PREFERENCES
-- =============================================================================

-- Skill development preferences from BDD lines 89-111
CREATE TABLE skill_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_name VARCHAR(100) NOT NULL,
    
    -- Skill development from BDD lines 93-98
    skill_development_goals JSONB DEFAULT '[]',
    skill_utilization_preferences JSONB DEFAULT '{}',
    cross_training_interests JSONB DEFAULT '[]',
    expertise_sharing_willingness BOOLEAN DEFAULT false,
    skill_challenge_level VARCHAR(20) DEFAULT 'moderate' CHECK (skill_challenge_level IN (
        'beginner', 'moderate', 'advanced', 'expert'
    )),
    
    -- Learning parameters from BDD lines 100-105
    learning_pace VARCHAR(20) DEFAULT 'moderate' CHECK (learning_pace IN ('slow', 'moderate', 'fast')),
    complexity_level VARCHAR(20) DEFAULT 'intermediate' CHECK (complexity_level IN (
        'beginner', 'intermediate', 'advanced', 'expert'
    )),
    time_investment_hours_per_week INTEGER DEFAULT 2,
    certification_goals JSONB DEFAULT '[]',
    peer_collaboration_preference BOOLEAN DEFAULT true,
    
    -- Optimization settings from BDD lines 107-111
    skill_gap_priority DECIMAL(3,2) DEFAULT 1.0,
    learning_path_flexibility DECIMAL(3,2) DEFAULT 0.5,
    resource_allocation_preference JSONB DEFAULT '{}',
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    review_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(employee_id, preference_name, effective_date)
);

-- =============================================================================
-- 10. ENVIRONMENT PREFERENCES
-- =============================================================================

-- Work environment preferences from BDD lines 114-136
CREATE TABLE environment_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_name VARCHAR(100) NOT NULL,
    
    -- Environment settings from BDD lines 118-123
    work_location_preference VARCHAR(20) DEFAULT 'hybrid' CHECK (work_location_preference IN (
        'office', 'remote', 'hybrid', 'flexible'
    )),
    preferred_team_size_min INTEGER DEFAULT 3,
    preferred_team_size_max INTEGER DEFAULT 8,
    communication_style VARCHAR(30) DEFAULT 'balanced' CHECK (communication_style IN (
        'formal', 'informal', 'collaborative', 'independent', 'balanced'
    )),
    workspace_setup_preferences JSONB DEFAULT '{}',
    technology_preferences JSONB DEFAULT '{}',
    
    -- Adaptation parameters from BDD lines 125-130
    flexibility_level INTEGER DEFAULT 5 CHECK (flexibility_level >= 1 AND flexibility_level <= 10),
    collaboration_preference VARCHAR(30) DEFAULT 'balanced' CHECK (collaboration_preference IN (
        'individual', 'team_based', 'balanced', 'leadership'
    )),
    noise_tolerance VARCHAR(20) DEFAULT 'moderate' CHECK (noise_tolerance IN (
        'quiet', 'moderate', 'active', 'flexible'
    )),
    technology_comfort_level INTEGER DEFAULT 7 CHECK (technology_comfort_level >= 1 AND technology_comfort_level <= 10),
    mobility_preference VARCHAR(20) DEFAULT 'moderate' CHECK (mobility_preference IN (
        'static', 'moderate', 'mobile', 'flexible'
    )),
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    review_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(employee_id, preference_name, effective_date)
);

-- =============================================================================
-- 11. NOTIFICATION PREFERENCES
-- =============================================================================

-- Communication preferences from BDD lines 139-161
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_name VARCHAR(100) NOT NULL,
    
    -- Communication channels from BDD lines 143-148
    notification_channels JSONB DEFAULT '["email"]',
    preferred_timing_windows JSONB DEFAULT '{}',
    message_frequency_preference VARCHAR(20) DEFAULT 'normal' CHECK (message_frequency_preference IN (
        'minimal', 'normal', 'frequent', 'real_time'
    )),
    content_preferences JSONB DEFAULT '{}',
    urgency_handling_rules JSONB DEFAULT '{}',
    
    -- Communication parameters from BDD lines 150-155
    expected_response_time_hours INTEGER DEFAULT 24,
    language_preference VARCHAR(10) DEFAULT 'en',
    format_preference VARCHAR(20) DEFAULT 'html' CHECK (format_preference IN (
        'text', 'html', 'rich_content', 'mobile_optimized'
    )),
    privacy_settings JSONB DEFAULT '{}',
    accessibility_needs JSONB DEFAULT '{}',
    
    -- Optimization settings from BDD lines 157-161
    delivery_optimization_enabled BOOLEAN DEFAULT true,
    engagement_tracking_enabled BOOLEAN DEFAULT true,
    adaptive_learning_enabled BOOLEAN DEFAULT true,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(employee_id, preference_name, effective_date)
);

-- =============================================================================
-- 12. PREFERENCE SYNCHRONIZATION STATUS
-- =============================================================================

-- Synchronization tracking from BDD lines 32-36
CREATE TABLE preference_sync_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    sync_type VARCHAR(30) NOT NULL CHECK (sync_type IN (
        'real_time_updates', 'batch_processing', 'template_updates', 'analytics_sync'
    )),
    
    -- Sync scheduling from BDD lines 33-36
    sync_schedule VARCHAR(20) DEFAULT 'immediate' CHECK (sync_schedule IN (
        'immediate', 'hourly', 'daily', 'on_demand'
    )),
    last_sync_at TIMESTAMP WITH TIME ZONE,
    next_sync_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync status
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'skipped'
    )),
    sync_details JSONB DEFAULT '{}',
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Conflict resolution from BDD lines 33-36
    conflict_resolution_strategy VARCHAR(30) DEFAULT 'employee_priority' CHECK (conflict_resolution_strategy IN (
        'employee_priority', 'business_rules', 'template_priority', 'latest_wins'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- =============================================================================
-- 13. PREFERENCE SATISFACTION SCORES
-- =============================================================================

-- Detailed satisfaction tracking from BDD lines 168-184
CREATE TABLE preference_satisfaction_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    preference_type VARCHAR(50) NOT NULL,
    
    -- Satisfaction metrics from BDD lines 169-172
    fulfillment_rate DECIMAL(5,2) CHECK (fulfillment_rate >= 0.0 AND fulfillment_rate <= 100.0),
    satisfaction_score DECIMAL(3,2) CHECK (satisfaction_score >= 0.0 AND satisfaction_score <= 10.0),
    impact_score DECIMAL(3,2) CHECK (impact_score >= 0.0 AND impact_score <= 10.0),
    
    -- Analysis periods from BDD line 169
    measurement_period_start DATE NOT NULL,
    measurement_period_end DATE NOT NULL,
    measurement_frequency VARCHAR(20) DEFAULT 'weekly' CHECK (measurement_frequency IN (
        'daily', 'weekly', 'monthly', 'quarterly'
    )),
    
    -- Trend analysis from BDD lines 180-184
    trend_direction VARCHAR(20) DEFAULT 'stable' CHECK (trend_direction IN (
        'improving', 'stable', 'declining', 'volatile'
    )),
    predicted_satisfaction DECIMAL(3,2),
    confidence_level DECIMAL(3,2) DEFAULT 0.8,
    
    -- Data quality
    data_completeness DECIMAL(3,2) DEFAULT 1.0,
    calculation_method VARCHAR(50) DEFAULT 'weighted_average',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (preference_type) REFERENCES preference_types(type_id) ON DELETE RESTRICT,
    
    CHECK (measurement_period_end >= measurement_period_start)
);

-- =============================================================================
-- 14. PREFERENCE API ACCESS
-- =============================================================================

-- API integration audit from BDD lines 210-231
CREATE TABLE preference_api_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    access_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- API endpoint information from BDD lines 214-219
    endpoint_path VARCHAR(200) NOT NULL,
    http_method VARCHAR(10) NOT NULL CHECK (http_method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
    request_purpose VARCHAR(100),
    
    -- Authentication from BDD line 215
    authentication_type VARCHAR(30) DEFAULT 'token_based' CHECK (authentication_type IN (
        'token_based', 'oauth', 'api_key', 'session_based'
    )),
    authenticated_user_id UUID,
    client_application VARCHAR(100),
    
    -- Request details
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    request_data JSONB,
    response_status INTEGER,
    response_time_ms INTEGER,
    response_data JSONB,
    
    -- Monitoring from BDD lines 227-231
    performance_score DECIMAL(3,2),
    data_consistency_check BOOLEAN DEFAULT true,
    usage_pattern VARCHAR(50),
    
    -- Security and validation from BDD line 225
    security_validation_passed BOOLEAN DEFAULT true,
    validation_details JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (authenticated_user_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Core preference queries
CREATE INDEX idx_employee_preferences_employee_type ON employee_preferences(employee_id, type_id);
CREATE INDEX idx_employee_preferences_effective_date ON employee_preferences(effective_date);
CREATE INDEX idx_employee_preferences_status ON employee_preferences(status) WHERE status = 'active';

-- Conflict resolution
CREATE INDEX idx_preference_conflicts_employee ON preference_conflicts(employee_id);
CREATE INDEX idx_preference_conflicts_resolution ON preference_conflicts(resolution_type) WHERE resolution_type = 'pending';
CREATE INDEX idx_preference_conflicts_severity ON preference_conflicts(severity);

-- Analytics and reporting
CREATE INDEX idx_preference_analytics_employee ON preference_analytics(employee_id);
CREATE INDEX idx_preference_analytics_period ON preference_analytics(analysis_period_start, analysis_period_end);
CREATE INDEX idx_preference_satisfaction_employee ON preference_satisfaction_scores(employee_id);
CREATE INDEX idx_preference_satisfaction_period ON preference_satisfaction_scores(measurement_period_start, measurement_period_end);

-- Template management
CREATE INDEX idx_preference_templates_department ON preference_templates(department_id) WHERE is_active = true;
CREATE INDEX idx_preference_templates_active ON preference_templates(is_active, effective_date);

-- History and audit
CREATE INDEX idx_preference_history_employee ON preference_history(employee_id);
CREATE INDEX idx_preference_history_date ON preference_history(change_date);
CREATE INDEX idx_preference_history_type ON preference_history(change_type);

-- Domain-specific preferences
CREATE INDEX idx_shift_preferences_employee ON shift_preferences(employee_id) WHERE is_active = true;
CREATE INDEX idx_vacation_preferences_employee ON vacation_preferences(employee_id, effective_year);
CREATE INDEX idx_skill_preferences_employee ON skill_preferences(employee_id) WHERE is_active = true;
CREATE INDEX idx_environment_preferences_employee ON environment_preferences(employee_id) WHERE is_active = true;
CREATE INDEX idx_notification_preferences_employee ON notification_preferences(employee_id) WHERE is_active = true;

-- Synchronization and API
CREATE INDEX idx_preference_sync_status_employee ON preference_sync_status(employee_id);
CREATE INDEX idx_preference_sync_next_sync ON preference_sync_status(next_sync_at) WHERE sync_status = 'pending';
CREATE INDEX idx_preference_api_access_timestamp ON preference_api_access(request_timestamp);
CREATE INDEX idx_preference_api_access_endpoint ON preference_api_access(endpoint_path, http_method);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_preference_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER preference_types_update_trigger
    BEFORE UPDATE ON preference_types
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER employee_preferences_update_trigger
    BEFORE UPDATE ON employee_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER preference_conflicts_update_trigger
    BEFORE UPDATE ON preference_conflicts
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER preference_templates_update_trigger
    BEFORE UPDATE ON preference_templates
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER shift_preferences_update_trigger
    BEFORE UPDATE ON shift_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER vacation_preferences_update_trigger
    BEFORE UPDATE ON vacation_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER skill_preferences_update_trigger
    BEFORE UPDATE ON skill_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER environment_preferences_update_trigger
    BEFORE UPDATE ON environment_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER notification_preferences_update_trigger
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

CREATE TRIGGER preference_sync_status_update_trigger
    BEFORE UPDATE ON preference_sync_status
    FOR EACH ROW EXECUTE FUNCTION update_preference_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active employee preferences with type information
CREATE VIEW v_active_employee_preferences AS
SELECT 
    ep.id,
    ep.employee_id,
    e.full_name as employee_name,
    pt.type_name,
    pt.category,
    ep.preference_value,
    ep.priority,
    ep.effective_date,
    ep.expiry_date,
    ep.flexibility_factor,
    ep.status
FROM employee_preferences ep
JOIN employees e ON ep.employee_id = e.id
JOIN preference_types pt ON ep.type_id = pt.type_id
WHERE ep.status = 'active'
  AND ep.effective_date <= CURRENT_DATE
  AND (ep.expiry_date IS NULL OR ep.expiry_date > CURRENT_DATE);

-- Preference conflicts requiring attention
CREATE VIEW v_pending_preference_conflicts AS
SELECT 
    pc.id,
    pc.conflict_id,
    pc.employee_id,
    e.full_name as employee_name,
    pc.conflict_type,
    pc.severity,
    pc.conflicting_prefs,
    pc.detected_at,
    EXTRACT(DAYS FROM CURRENT_TIMESTAMP - pc.detected_at) as days_pending
FROM preference_conflicts pc
JOIN employees e ON pc.employee_id = e.id
WHERE pc.resolution_type = 'pending'
ORDER BY pc.severity DESC, pc.detected_at ASC;

-- Preference satisfaction summary
CREATE VIEW v_preference_satisfaction_summary AS
SELECT 
    pss.employee_id,
    e.full_name as employee_name,
    pss.preference_type,
    AVG(pss.satisfaction_score) as avg_satisfaction,
    AVG(pss.fulfillment_rate) as avg_fulfillment,
    COUNT(*) as measurement_count,
    MAX(pss.measurement_period_end) as latest_measurement
FROM preference_satisfaction_scores pss
JOIN employees e ON pss.employee_id = e.id
WHERE pss.measurement_period_end >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY pss.employee_id, e.full_name, pss.preference_type;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert preference types
INSERT INTO preference_types (type_id, type_name, description, category, weight) VALUES
('shift_start_time', 'Shift Start Time Preference', 'Preferred start times for work shifts', 'shift_preferences', 8.0),
('vacation_period', 'Vacation Period Preference', 'Preferred vacation time periods', 'vacation_preferences', 7.0),
('skill_development', 'Skill Development Preference', 'Desired skill development areas', 'skill_preferences', 6.0),
('work_location', 'Work Location Preference', 'Preferred work location settings', 'environment_preferences', 5.0),
('notification_channel', 'Notification Channel Preference', 'Preferred communication channels', 'notification_preferences', 4.0);

-- Insert sample template
INSERT INTO preference_templates (template_id, template_name, description, preference_set, created_by)
VALUES (
    'default_agent_template',
    'Default Call Center Agent Preferences',
    'Standard preference template for call center agents',
    '{"shift_preferences": {"preferred_start": "09:00", "max_overtime": 2}, "notification_preferences": {"channels": ["email", "sms"], "frequency": "normal"}}',
    (SELECT id FROM employees LIMIT 1)
);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE preference_types IS 'BDD Line 18: Preference classifications and type definitions';
COMMENT ON TABLE employee_preferences IS 'BDD Line 19: Individual employee preferences with priority and temporal settings';
COMMENT ON TABLE preference_conflicts IS 'BDD Line 20: Conflict detection and resolution tracking system';
COMMENT ON TABLE preference_analytics IS 'BDD Line 21: Analytics data for satisfaction and fulfillment tracking';
COMMENT ON TABLE preference_templates IS 'BDD Line 22: Template preferences for departments and roles';
COMMENT ON TABLE preference_history IS 'BDD Line 23: Complete audit trail of preference changes';

COMMENT ON TABLE shift_preferences IS 'BDD Lines 42-61: Advanced shift preference management with optimization';
COMMENT ON TABLE vacation_preferences IS 'BDD Lines 64-86: Vacation and time-off preference management';
COMMENT ON TABLE skill_preferences IS 'BDD Lines 89-111: Skill development and utilization preferences';
COMMENT ON TABLE environment_preferences IS 'BDD Lines 114-136: Work environment and workplace preferences';
COMMENT ON TABLE notification_preferences IS 'BDD Lines 139-161: Communication and notification preferences';

COMMENT ON TABLE preference_sync_status IS 'BDD Lines 32-36: Preference synchronization tracking and conflict resolution';
COMMENT ON TABLE preference_satisfaction_scores IS 'BDD Lines 168-184: Detailed satisfaction and trend analysis';
COMMENT ON TABLE preference_api_access IS 'BDD Lines 210-231: API integration audit and monitoring';