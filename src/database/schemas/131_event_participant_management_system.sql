-- =====================================================================================
-- Schema 131: Event & Participant Management System
-- =====================================================================================
-- Description: Comprehensive event management with participant limits, capacity control,
--              waitlist management, and priority allocation system
-- Version: 1.0.0
-- Last Updated: 2024-07-16
-- BDD Source: 23-event-participant-limits.feature
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "ltree";

-- =====================================================================================
-- CORE EVENT MANAGEMENT TABLES
-- =====================================================================================

-- Table 1: Event Types - Event classification and categorization
CREATE TABLE IF NOT EXISTS event_types (
    event_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    type_name_ru VARCHAR(100) NOT NULL,
    description TEXT,
    description_ru TEXT,
    category VARCHAR(50) NOT NULL, -- 'training', 'meeting', 'conference', 'workshop'
    default_capacity INTEGER NOT NULL DEFAULT 10,
    capacity_type VARCHAR(20) NOT NULL DEFAULT 'fixed', -- 'fixed', 'flexible', 'percentage', 'skill_based', 'resource_based'
    min_participants INTEGER DEFAULT 1,
    max_participants INTEGER DEFAULT 100,
    optimal_participants INTEGER DEFAULT 20,
    duration_minutes INTEGER DEFAULT 60,
    preparation_time_minutes INTEGER DEFAULT 15,
    prerequisites TEXT[],
    required_skills TEXT[],
    resource_requirements JSONB DEFAULT '{}',
    approval_required BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: Event Locations - Venue and location management
CREATE TABLE IF NOT EXISTS event_locations (
    location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(100) NOT NULL,
    location_name_ru VARCHAR(100) NOT NULL,
    location_type VARCHAR(50) NOT NULL, -- 'room', 'hall', 'outdoor', 'virtual'
    address TEXT,
    address_ru TEXT,
    capacity INTEGER NOT NULL,
    floor_number INTEGER,
    building VARCHAR(50),
    equipment JSONB DEFAULT '{}', -- Available equipment and resources
    accessibility_features TEXT[],
    booking_cost DECIMAL(10,2) DEFAULT 0.00,
    time_zone VARCHAR(50) DEFAULT 'Europe/Moscow',
    is_virtual BOOLEAN DEFAULT false,
    virtual_platform VARCHAR(50), -- 'zoom', 'teams', 'webex', etc.
    virtual_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 3: Event Resources - Resource requirements and allocation
CREATE TABLE IF NOT EXISTS event_resources (
    resource_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_name VARCHAR(100) NOT NULL,
    resource_name_ru VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL, -- 'equipment', 'software', 'material', 'personnel'
    description TEXT,
    description_ru TEXT,
    quantity_available INTEGER NOT NULL DEFAULT 1,
    cost_per_unit DECIMAL(10,2) DEFAULT 0.00,
    booking_advance_hours INTEGER DEFAULT 24,
    maintenance_required BOOLEAN DEFAULT false,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    location_id UUID REFERENCES event_locations(location_id),
    vendor_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: Events - Main event instances
CREATE TABLE IF NOT EXISTS events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type_id UUID NOT NULL REFERENCES event_types(event_type_id),
    event_name VARCHAR(200) NOT NULL,
    event_name_ru VARCHAR(200) NOT NULL,
    description TEXT,
    description_ru TEXT,
    location_id UUID REFERENCES event_locations(location_id),
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ NOT NULL,
    registration_start TIMESTAMPTZ NOT NULL,
    registration_end TIMESTAMPTZ NOT NULL,
    max_participants INTEGER NOT NULL,
    min_participants INTEGER DEFAULT 1,
    current_participants INTEGER DEFAULT 0,
    waitlist_size INTEGER DEFAULT 0,
    overbooking_percentage DECIMAL(5,2) DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'planned', -- 'planned', 'open', 'full', 'cancelled', 'completed'
    priority_level INTEGER DEFAULT 1, -- 1-5 scale
    organizer_id UUID NOT NULL, -- Reference to employees
    cost_per_participant DECIMAL(10,2) DEFAULT 0.00,
    budget_allocated DECIMAL(10,2) DEFAULT 0.00,
    budget_used DECIMAL(10,2) DEFAULT 0.00,
    registration_rules JSONB DEFAULT '{}',
    cancellation_policy TEXT,
    cancellation_policy_ru TEXT,
    reminder_schedule JSONB DEFAULT '{}', -- When to send reminders
    feedback_required BOOLEAN DEFAULT false,
    attendance_tracking BOOLEAN DEFAULT true,
    certificate_provided BOOLEAN DEFAULT false,
    external_system_sync BOOLEAN DEFAULT false,
    external_system_id VARCHAR(100),
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern JSONB DEFAULT '{}',
    parent_event_id UUID REFERENCES events(event_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- PARTICIPANT MANAGEMENT TABLES
-- =====================================================================================

-- Table 5: Participant Limits - Capacity and limit configurations
CREATE TABLE IF NOT EXISTS participant_limits (
    limit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    limit_type VARCHAR(50) NOT NULL, -- 'capacity', 'skill', 'department', 'seniority', 'role'
    limit_category VARCHAR(50), -- Additional categorization
    limit_value INTEGER NOT NULL,
    limit_percentage DECIMAL(5,2), -- For percentage-based limits
    priority INTEGER DEFAULT 1,
    enforcement_rule VARCHAR(50) NOT NULL DEFAULT 'hard', -- 'hard', 'soft', 'advisory'
    override_allowed BOOLEAN DEFAULT false,
    override_requires_approval BOOLEAN DEFAULT true,
    violation_action VARCHAR(50) DEFAULT 'reject', -- 'reject', 'waitlist', 'approve', 'escalate'
    applied_conditions JSONB DEFAULT '{}',
    effective_from TIMESTAMPTZ NOT NULL,
    effective_until TIMESTAMPTZ,
    created_by UUID NOT NULL, -- Reference to employees
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 6: Participant Priorities - Priority rules and scoring
CREATE TABLE IF NOT EXISTS participant_priorities (
    priority_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(event_id),
    priority_type VARCHAR(50) NOT NULL, -- 'seniority', 'skill', 'role', 'department', 'registration'
    priority_name VARCHAR(100) NOT NULL,
    priority_name_ru VARCHAR(100) NOT NULL,
    weight_factor DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    calculation_method VARCHAR(50) NOT NULL DEFAULT 'linear', -- 'linear', 'exponential', 'step'
    criteria_definition JSONB NOT NULL DEFAULT '{}',
    tie_breaker_order INTEGER DEFAULT 1,
    applies_to_events JSONB DEFAULT '{}', -- Event types or specific events
    is_global BOOLEAN DEFAULT false,
    created_by UUID NOT NULL, -- Reference to employees
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 7: Event Participants - Participant registrations and tracking
CREATE TABLE IF NOT EXISTS event_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    employee_id UUID NOT NULL, -- Reference to employees
    registration_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registration_method VARCHAR(50) DEFAULT 'self', -- 'self', 'admin', 'auto', 'manager'
    status VARCHAR(20) NOT NULL DEFAULT 'registered', -- 'registered', 'confirmed', 'attended', 'no_show', 'cancelled'
    priority_score DECIMAL(8,2) DEFAULT 0.00,
    priority_breakdown JSONB DEFAULT '{}', -- Detailed priority calculation
    allocation_method VARCHAR(50) DEFAULT 'automatic', -- 'automatic', 'manual', 'lottery'
    confirmed_at TIMESTAMPTZ,
    attended_at TIMESTAMPTZ,
    completion_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'partial'
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    feedback_submitted BOOLEAN DEFAULT false,
    certificate_issued BOOLEAN DEFAULT false,
    cost_charged DECIMAL(10,2) DEFAULT 0.00,
    manager_approval_required BOOLEAN DEFAULT false,
    manager_approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    manager_approval_at TIMESTAMPTZ,
    manager_approval_by UUID, -- Reference to employees
    cancellation_reason TEXT,
    cancellation_reason_ru TEXT,
    cancelled_at TIMESTAMPTZ,
    cancelled_by UUID, -- Reference to employees
    notes TEXT,
    notes_ru TEXT,
    external_system_sync BOOLEAN DEFAULT false,
    external_system_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 8: Participant Queues - Waitlist and queue management
CREATE TABLE IF NOT EXISTS participant_queues (
    queue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    employee_id UUID NOT NULL, -- Reference to employees
    queue_type VARCHAR(50) NOT NULL DEFAULT 'standard', -- 'standard', 'priority', 'skill', 'department'
    queue_position INTEGER NOT NULL,
    original_position INTEGER NOT NULL,
    queue_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    priority_score DECIMAL(8,2) DEFAULT 0.00,
    estimated_wait_time INTEGER, -- Minutes
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMPTZ,
    promotion_available BOOLEAN DEFAULT false,
    promotion_deadline TIMESTAMPTZ,
    promotion_response VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    promotion_response_at TIMESTAMPTZ,
    auto_promotion_enabled BOOLEAN DEFAULT true,
    manual_promotion_reason TEXT,
    manual_promotion_reason_ru TEXT,
    queue_expiry_datetime TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'waiting', -- 'waiting', 'promoted', 'expired', 'cancelled'
    cancellation_reason TEXT,
    cancellation_reason_ru TEXT,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- CAPACITY AND ALLOCATION MANAGEMENT TABLES
-- =====================================================================================

-- Table 9: Participant Allocations - Allocation rules and algorithms
CREATE TABLE IF NOT EXISTS participant_allocations (
    allocation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    allocation_method VARCHAR(50) NOT NULL, -- 'automatic', 'manual', 'hybrid', 'lottery'
    allocation_algorithm VARCHAR(50) NOT NULL, -- 'priority_score', 'fifo', 'random', 'weighted'
    allocation_criteria JSONB NOT NULL DEFAULT '{}',
    allocation_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    allocated_by UUID NOT NULL, -- Reference to employees
    participants_allocated INTEGER DEFAULT 0,
    participants_waitlisted INTEGER DEFAULT 0,
    participants_rejected INTEGER DEFAULT 0,
    allocation_success_rate DECIMAL(5,2) DEFAULT 0.00,
    allocation_notes TEXT,
    allocation_notes_ru TEXT,
    reallocation_count INTEGER DEFAULT 0,
    last_reallocation_at TIMESTAMPTZ,
    is_final BOOLEAN DEFAULT false,
    audit_trail JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 10: Event Capacity History - Capacity tracking and changes
CREATE TABLE IF NOT EXISTS event_capacity_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    change_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_type VARCHAR(50) NOT NULL, -- 'initial', 'increase', 'decrease', 'override'
    previous_capacity INTEGER,
    new_capacity INTEGER NOT NULL,
    capacity_change INTEGER NOT NULL,
    reason VARCHAR(100) NOT NULL,
    reason_ru VARCHAR(100) NOT NULL,
    changed_by UUID NOT NULL, -- Reference to employees
    approval_required BOOLEAN DEFAULT false,
    approved_by UUID, -- Reference to employees
    approved_at TIMESTAMPTZ,
    impact_assessment TEXT,
    impact_assessment_ru TEXT,
    participants_affected INTEGER DEFAULT 0,
    waitlist_affected INTEGER DEFAULT 0,
    notification_sent BOOLEAN DEFAULT false,
    rollback_possible BOOLEAN DEFAULT true,
    rollback_deadline TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 11: Event Schedules - Event timing and scheduling
CREATE TABLE IF NOT EXISTS event_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    schedule_type VARCHAR(50) NOT NULL, -- 'main', 'preparation', 'followup', 'break'
    schedule_name VARCHAR(100) NOT NULL,
    schedule_name_ru VARCHAR(100) NOT NULL,
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL,
    description TEXT,
    description_ru TEXT,
    location_id UUID REFERENCES event_locations(location_id),
    instructor_id UUID, -- Reference to employees
    required_resources JSONB DEFAULT '{}',
    capacity_override INTEGER, -- Override event capacity for this schedule
    is_mandatory BOOLEAN DEFAULT true,
    is_break BOOLEAN DEFAULT false,
    break_duration_minutes INTEGER DEFAULT 15,
    preparation_required BOOLEAN DEFAULT false,
    preparation_time_minutes INTEGER DEFAULT 15,
    materials_needed TEXT[],
    prerequisites TEXT[],
    learning_objectives TEXT[],
    assessment_method VARCHAR(50), -- 'test', 'practical', 'observation', 'none'
    status VARCHAR(20) NOT NULL DEFAULT 'planned', -- 'planned', 'active', 'completed', 'cancelled'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 12: Event Prerequisites - Required qualifications and training
CREATE TABLE IF NOT EXISTS event_prerequisites (
    prerequisite_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    prerequisite_type VARCHAR(50) NOT NULL, -- 'training', 'certification', 'experience', 'skill', 'role'
    prerequisite_name VARCHAR(100) NOT NULL,
    prerequisite_name_ru VARCHAR(100) NOT NULL,
    description TEXT,
    description_ru TEXT,
    is_mandatory BOOLEAN DEFAULT true,
    validation_method VARCHAR(50) NOT NULL, -- 'automatic', 'manual', 'system_check', 'document'
    validation_criteria JSONB DEFAULT '{}',
    grace_period_days INTEGER DEFAULT 0,
    waiver_allowed BOOLEAN DEFAULT false,
    waiver_requires_approval BOOLEAN DEFAULT true,
    substitute_acceptable BOOLEAN DEFAULT false,
    substitute_criteria JSONB DEFAULT '{}',
    verification_expiry_days INTEGER, -- How long verification is valid
    auto_verification_enabled BOOLEAN DEFAULT true,
    manual_verification_required BOOLEAN DEFAULT false,
    priority_order INTEGER DEFAULT 1,
    created_by UUID NOT NULL, -- Reference to employees
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- VIOLATION AND CONFLICT MANAGEMENT TABLES
-- =====================================================================================

-- Table 13: Limit Violations - Capacity and limit violation tracking
CREATE TABLE IF NOT EXISTS limit_violations (
    violation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    employee_id UUID NOT NULL, -- Reference to employees
    violation_type VARCHAR(50) NOT NULL, -- 'capacity', 'skill', 'schedule', 'prerequisite', 'approval'
    violation_severity VARCHAR(20) NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    violation_description TEXT NOT NULL,
    violation_description_ru TEXT NOT NULL,
    violation_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(50) NOT NULL, -- 'system', 'manual', 'admin'
    detection_method VARCHAR(50) NOT NULL, -- 'validation', 'audit', 'report', 'complaint'
    current_value INTEGER,
    limit_value INTEGER,
    violation_percentage DECIMAL(5,2),
    impact_assessment TEXT,
    impact_assessment_ru TEXT,
    resolution_required BOOLEAN DEFAULT true,
    resolution_priority INTEGER DEFAULT 1, -- 1-5 scale
    resolution_deadline TIMESTAMPTZ,
    resolution_status VARCHAR(20) NOT NULL DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'closed'
    resolution_method VARCHAR(50), -- 'override', 'exception', 'capacity_increase', 'participant_removal'
    resolution_description TEXT,
    resolution_description_ru TEXT,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID, -- Reference to employees
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    prevention_measures TEXT,
    prevention_measures_ru TEXT,
    audit_trail JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 14: Event Conflicts - Schedule and resource conflicts
CREATE TABLE IF NOT EXISTS event_conflicts (
    conflict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    primary_event_id UUID NOT NULL REFERENCES events(event_id),
    conflicting_event_id UUID NOT NULL REFERENCES events(event_id),
    conflict_type VARCHAR(50) NOT NULL, -- 'schedule', 'resource', 'location', 'participant', 'instructor'
    conflict_severity VARCHAR(20) NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    conflict_description TEXT NOT NULL,
    conflict_description_ru TEXT NOT NULL,
    conflict_detected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(50) NOT NULL, -- 'system', 'manual', 'admin'
    detection_method VARCHAR(50) NOT NULL, -- 'scheduling', 'validation', 'audit', 'report'
    overlap_duration_minutes INTEGER,
    affected_participants INTEGER DEFAULT 0,
    affected_resources JSONB DEFAULT '{}',
    business_impact VARCHAR(50) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    resolution_options JSONB DEFAULT '{}',
    resolution_priority INTEGER DEFAULT 1, -- 1-5 scale
    resolution_deadline TIMESTAMPTZ,
    resolution_status VARCHAR(20) NOT NULL DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'closed'
    resolution_method VARCHAR(50), -- 'reschedule', 'relocate', 'split', 'merge', 'cancel'
    resolution_description TEXT,
    resolution_description_ru TEXT,
    resolution_cost DECIMAL(10,2) DEFAULT 0.00,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID, -- Reference to employees
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    prevention_measures TEXT,
    prevention_measures_ru TEXT,
    audit_trail JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- NOTIFICATION AND COMMUNICATION TABLES
-- =====================================================================================

-- Table 15: Event Notifications - Notification and communication tracking
CREATE TABLE IF NOT EXISTS event_notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    recipient_id UUID NOT NULL, -- Reference to employees
    notification_type VARCHAR(50) NOT NULL, -- 'registration', 'waitlist', 'promotion', 'reminder', 'cancellation'
    notification_subtype VARCHAR(50), -- 'confirmation', 'queue_position', 'advancement', 'deadline', 'update'
    notification_template VARCHAR(100) NOT NULL,
    notification_title VARCHAR(200) NOT NULL,
    notification_title_ru VARCHAR(200) NOT NULL,
    notification_content TEXT NOT NULL,
    notification_content_ru TEXT NOT NULL,
    delivery_method VARCHAR(50) NOT NULL, -- 'email', 'sms', 'push', 'system', 'all'
    delivery_priority INTEGER DEFAULT 1, -- 1-5 scale
    scheduled_datetime TIMESTAMPTZ NOT NULL,
    sent_datetime TIMESTAMPTZ,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed', 'cancelled'
    delivery_attempts INTEGER DEFAULT 0,
    max_delivery_attempts INTEGER DEFAULT 3,
    delivery_confirmation BOOLEAN DEFAULT false,
    delivery_confirmation_at TIMESTAMPTZ,
    read_confirmation BOOLEAN DEFAULT false,
    read_confirmation_at TIMESTAMPTZ,
    response_required BOOLEAN DEFAULT false,
    response_deadline TIMESTAMPTZ,
    response_received BOOLEAN DEFAULT false,
    response_content TEXT,
    response_received_at TIMESTAMPTZ,
    escalation_required BOOLEAN DEFAULT false,
    escalation_level INTEGER DEFAULT 0,
    escalation_sent_at TIMESTAMPTZ,
    bounce_reason TEXT,
    retry_scheduled_at TIMESTAMPTZ,
    external_message_id VARCHAR(100),
    delivery_cost DECIMAL(6,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 16: Event Cancellations - Cancellation tracking and management
CREATE TABLE IF NOT EXISTS event_cancellations (
    cancellation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    cancellation_type VARCHAR(50) NOT NULL, -- 'full', 'partial', 'postponed', 'relocated'
    cancellation_reason VARCHAR(100) NOT NULL,
    cancellation_reason_ru VARCHAR(100) NOT NULL,
    cancellation_description TEXT,
    cancellation_description_ru TEXT,
    cancellation_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_by UUID NOT NULL, -- Reference to employees
    approval_required BOOLEAN DEFAULT false,
    approved_by UUID, -- Reference to employees
    approved_at TIMESTAMPTZ,
    notice_period_hours INTEGER NOT NULL,
    participants_affected INTEGER DEFAULT 0,
    participants_notified INTEGER DEFAULT 0,
    notification_sent_at TIMESTAMPTZ,
    refund_required BOOLEAN DEFAULT false,
    refund_amount DECIMAL(10,2) DEFAULT 0.00,
    refund_processed BOOLEAN DEFAULT false,
    refund_processed_at TIMESTAMPTZ,
    rescheduled_to UUID REFERENCES events(event_id),
    rescheduled_at TIMESTAMPTZ,
    alternative_offered BOOLEAN DEFAULT false,
    alternative_event_id UUID REFERENCES events(event_id),
    cost_impact DECIMAL(10,2) DEFAULT 0.00,
    business_impact TEXT,
    business_impact_ru TEXT,
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    lessons_learned TEXT,
    lessons_learned_ru TEXT,
    audit_trail JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- HISTORY AND TRACKING TABLES
-- =====================================================================================

-- Table 17: Participant History - Participant activity tracking
CREATE TABLE IF NOT EXISTS participant_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_id UUID NOT NULL REFERENCES event_participants(participant_id),
    event_id UUID NOT NULL REFERENCES events(event_id),
    employee_id UUID NOT NULL, -- Reference to employees
    action_type VARCHAR(50) NOT NULL, -- 'register', 'confirm', 'attend', 'complete', 'cancel', 'no_show'
    action_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action_source VARCHAR(50) NOT NULL, -- 'self', 'admin', 'system', 'manager'
    action_description TEXT,
    action_description_ru TEXT,
    previous_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    action_reason TEXT,
    action_reason_ru TEXT,
    system_user_id UUID, -- Reference to employees who performed action
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 18: Event Modifications - Change tracking for events
CREATE TABLE IF NOT EXISTS event_modifications (
    modification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    modification_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'capacity_change', 'reschedule'
    modification_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID NOT NULL, -- Reference to employees
    modification_source VARCHAR(50) NOT NULL, -- 'admin', 'system', 'integration', 'bulk_update'
    field_name VARCHAR(50) NOT NULL,
    previous_value TEXT,
    new_value TEXT NOT NULL,
    change_reason TEXT,
    change_reason_ru TEXT,
    approval_required BOOLEAN DEFAULT false,
    approved_by UUID, -- Reference to employees
    approved_at TIMESTAMPTZ,
    participants_affected INTEGER DEFAULT 0,
    notification_required BOOLEAN DEFAULT false,
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMPTZ,
    rollback_possible BOOLEAN DEFAULT true,
    rollback_deadline TIMESTAMPTZ,
    rollback_data JSONB DEFAULT '{}',
    business_impact TEXT,
    business_impact_ru TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- ANALYTICS AND REPORTING TABLES
-- =====================================================================================

-- Table 19: Event Analytics - Event performance metrics
CREATE TABLE IF NOT EXISTS event_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    analytics_date DATE NOT NULL,
    analytics_type VARCHAR(50) NOT NULL, -- 'utilization', 'demand', 'efficiency', 'satisfaction'
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(12,4) NOT NULL,
    metric_unit VARCHAR(20) NOT NULL, -- 'percentage', 'count', 'minutes', 'score', 'ratio'
    calculation_method VARCHAR(50) NOT NULL,
    calculation_period VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'event_lifecycle'
    benchmark_value DECIMAL(12,4),
    variance_percentage DECIMAL(8,2),
    trend_direction VARCHAR(20), -- 'up', 'down', 'stable', 'volatile'
    data_quality_score DECIMAL(5,2) DEFAULT 100.00,
    confidence_level DECIMAL(5,2) DEFAULT 95.00,
    sample_size INTEGER,
    calculation_notes TEXT,
    calculation_notes_ru TEXT,
    alert_threshold_low DECIMAL(12,4),
    alert_threshold_high DECIMAL(12,4),
    alert_triggered BOOLEAN DEFAULT false,
    alert_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 20: Event Feedback - Participant feedback and evaluations
CREATE TABLE IF NOT EXISTS event_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    participant_id UUID NOT NULL REFERENCES event_participants(participant_id),
    employee_id UUID NOT NULL, -- Reference to employees
    feedback_type VARCHAR(50) NOT NULL, -- 'satisfaction', 'content', 'instructor', 'logistics', 'overall'
    feedback_category VARCHAR(50) NOT NULL, -- 'rating', 'text', 'suggestion', 'complaint', 'compliment'
    feedback_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating_score INTEGER CHECK (rating_score >= 1 AND rating_score <= 5),
    feedback_text TEXT,
    feedback_text_ru TEXT,
    is_anonymous BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false,
    feedback_tags TEXT[],
    improvement_suggestions TEXT,
    improvement_suggestions_ru TEXT,
    would_recommend BOOLEAN,
    would_attend_again BOOLEAN,
    content_relevance_score INTEGER CHECK (content_relevance_score >= 1 AND content_relevance_score <= 5),
    instructor_effectiveness_score INTEGER CHECK (instructor_effectiveness_score >= 1 AND instructor_effectiveness_score <= 5),
    logistics_satisfaction_score INTEGER CHECK (logistics_satisfaction_score >= 1 AND logistics_satisfaction_score <= 5),
    overall_satisfaction_score INTEGER CHECK (overall_satisfaction_score >= 1 AND overall_satisfaction_score <= 5),
    sentiment_analysis_score DECIMAL(5,2), -- -1 to 1 scale
    sentiment_analysis_confidence DECIMAL(5,2), -- 0 to 1 scale
    moderation_required BOOLEAN DEFAULT false,
    moderation_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'flagged'
    moderated_by UUID, -- Reference to employees
    moderated_at TIMESTAMPTZ,
    response_required BOOLEAN DEFAULT false,
    response_provided BOOLEAN DEFAULT false,
    response_text TEXT,
    response_text_ru TEXT,
    response_provided_at TIMESTAMPTZ,
    response_provided_by UUID, -- Reference to employees
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- RESOURCE AND WAITLIST MANAGEMENT TABLES
-- =====================================================================================

-- Table 21: Event Resources Allocation - Resource assignment tracking
CREATE TABLE IF NOT EXISTS event_resources_allocation (
    allocation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    resource_id UUID NOT NULL REFERENCES event_resources(resource_id),
    allocation_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    allocated_by UUID NOT NULL, -- Reference to employees
    quantity_allocated INTEGER NOT NULL DEFAULT 1,
    allocation_start TIMESTAMPTZ NOT NULL,
    allocation_end TIMESTAMPTZ NOT NULL,
    allocation_duration_minutes INTEGER NOT NULL,
    allocation_cost DECIMAL(10,2) DEFAULT 0.00,
    setup_time_minutes INTEGER DEFAULT 0,
    teardown_time_minutes INTEGER DEFAULT 0,
    preparation_required BOOLEAN DEFAULT false,
    preparation_instructions TEXT,
    preparation_instructions_ru TEXT,
    usage_instructions TEXT,
    usage_instructions_ru TEXT,
    maintenance_required BOOLEAN DEFAULT false,
    maintenance_scheduled_at TIMESTAMPTZ,
    condition_before TEXT,
    condition_after TEXT,
    damage_reported BOOLEAN DEFAULT false,
    damage_description TEXT,
    damage_description_ru TEXT,
    damage_cost DECIMAL(10,2) DEFAULT 0.00,
    allocation_status VARCHAR(20) NOT NULL DEFAULT 'allocated', -- 'allocated', 'in_use', 'returned', 'damaged', 'lost'
    returned_at TIMESTAMPTZ,
    returned_by UUID, -- Reference to employees
    return_condition TEXT,
    usage_notes TEXT,
    usage_notes_ru TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 22: Event Waitlist Management - Advanced waitlist processing
CREATE TABLE IF NOT EXISTS event_waitlist_management (
    waitlist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    queue_id UUID NOT NULL REFERENCES participant_queues(queue_id),
    processing_datetime TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processing_type VARCHAR(50) NOT NULL, -- 'automatic', 'manual', 'batch', 'emergency'
    processing_algorithm VARCHAR(50) NOT NULL, -- 'fifo', 'priority', 'lottery', 'skill_match'
    processing_criteria JSONB DEFAULT '{}',
    processed_by UUID, -- Reference to employees (null for automatic)
    participants_processed INTEGER DEFAULT 0,
    participants_promoted INTEGER DEFAULT 0,
    participants_notified INTEGER DEFAULT 0,
    participants_expired INTEGER DEFAULT 0,
    processing_success_rate DECIMAL(5,2) DEFAULT 0.00,
    processing_duration_seconds INTEGER DEFAULT 0,
    processing_errors INTEGER DEFAULT 0,
    error_details JSONB DEFAULT '{}',
    notification_batch_id UUID,
    notification_success_rate DECIMAL(5,2) DEFAULT 0.00,
    next_processing_scheduled TIMESTAMPTZ,
    processing_notes TEXT,
    processing_notes_ru TEXT,
    business_rules_applied JSONB DEFAULT '{}',
    audit_trail JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 23: Event Templates - Event template management
CREATE TABLE IF NOT EXISTS event_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_name_ru VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_description_ru TEXT,
    event_type_id UUID NOT NULL REFERENCES event_types(event_type_id),
    template_category VARCHAR(50) NOT NULL, -- 'training', 'meeting', 'workshop', 'conference'
    template_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    template_status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'inactive', 'deprecated'
    default_duration_minutes INTEGER NOT NULL DEFAULT 60,
    default_capacity INTEGER NOT NULL DEFAULT 20,
    default_location_type VARCHAR(50) DEFAULT 'room',
    default_resources JSONB DEFAULT '{}',
    default_prerequisites JSONB DEFAULT '{}',
    default_registration_rules JSONB DEFAULT '{}',
    default_notification_schedule JSONB DEFAULT '{}',
    default_agenda JSONB DEFAULT '{}',
    default_materials JSONB DEFAULT '{}',
    cost_template JSONB DEFAULT '{}',
    approval_workflow JSONB DEFAULT '{}',
    customization_options JSONB DEFAULT '{}',
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    created_by UUID NOT NULL, -- Reference to employees
    template_tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    sharing_permissions JSONB DEFAULT '{}',
    version_history JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 24: Event Compliance - Compliance tracking and reporting
CREATE TABLE IF NOT EXISTS event_compliance (
    compliance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id),
    compliance_type VARCHAR(50) NOT NULL, -- 'regulatory', 'internal', 'industry', 'safety', 'quality'
    compliance_requirement VARCHAR(100) NOT NULL,
    compliance_requirement_ru VARCHAR(100) NOT NULL,
    compliance_standard VARCHAR(50) NOT NULL, -- 'ISO', 'GDPR', 'SOX', 'HIPAA', 'internal'
    compliance_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'compliant', 'non_compliant', 'under_review'
    compliance_check_date DATE NOT NULL,
    compliance_deadline DATE,
    compliance_checked_by UUID NOT NULL, -- Reference to employees
    compliance_evidence TEXT,
    compliance_evidence_ru TEXT,
    compliance_score DECIMAL(5,2), -- 0-100 scale
    compliance_gaps TEXT,
    compliance_gaps_ru TEXT,
    remediation_required BOOLEAN DEFAULT false,
    remediation_plan TEXT,
    remediation_plan_ru TEXT,
    remediation_deadline DATE,
    remediation_completed BOOLEAN DEFAULT false,
    remediation_completed_at TIMESTAMPTZ,
    remediation_completed_by UUID, -- Reference to employees
    audit_trail JSONB DEFAULT '{}',
    risk_level VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    risk_assessment TEXT,
    risk_assessment_ru TEXT,
    mitigation_measures TEXT,
    mitigation_measures_ru TEXT,
    next_review_date DATE,
    compliance_notes TEXT,
    compliance_notes_ru TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Event Types indexes
CREATE INDEX IF NOT EXISTS idx_event_types_category ON event_types(category);
CREATE INDEX IF NOT EXISTS idx_event_types_active ON event_types(is_active);
CREATE INDEX IF NOT EXISTS idx_event_types_capacity ON event_types(capacity_type);

-- Event Locations indexes
CREATE INDEX IF NOT EXISTS idx_event_locations_type ON event_locations(location_type);
CREATE INDEX IF NOT EXISTS idx_event_locations_capacity ON event_locations(capacity);
CREATE INDEX IF NOT EXISTS idx_event_locations_active ON event_locations(is_active);

-- Event Resources indexes
CREATE INDEX IF NOT EXISTS idx_event_resources_type ON event_resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_event_resources_location ON event_resources(location_id);
CREATE INDEX IF NOT EXISTS idx_event_resources_active ON event_resources(is_active);

-- Events indexes
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type_id);
CREATE INDEX IF NOT EXISTS idx_events_location ON events(location_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_datetime);
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_datetime);
CREATE INDEX IF NOT EXISTS idx_events_registration_period ON events(registration_start, registration_end);
CREATE INDEX IF NOT EXISTS idx_events_organizer ON events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_capacity ON events(max_participants, current_participants);

-- Participant Limits indexes
CREATE INDEX IF NOT EXISTS idx_participant_limits_event ON participant_limits(event_id);
CREATE INDEX IF NOT EXISTS idx_participant_limits_type ON participant_limits(limit_type);
CREATE INDEX IF NOT EXISTS idx_participant_limits_active ON participant_limits(is_active);
CREATE INDEX IF NOT EXISTS idx_participant_limits_effective ON participant_limits(effective_from, effective_until);

-- Participant Priorities indexes
CREATE INDEX IF NOT EXISTS idx_participant_priorities_event ON participant_priorities(event_id);
CREATE INDEX IF NOT EXISTS idx_participant_priorities_type ON participant_priorities(priority_type);
CREATE INDEX IF NOT EXISTS idx_participant_priorities_global ON participant_priorities(is_global);
CREATE INDEX IF NOT EXISTS idx_participant_priorities_active ON participant_priorities(is_active);

-- Event Participants indexes
CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_employee ON event_participants(employee_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_status ON event_participants(status);
CREATE INDEX IF NOT EXISTS idx_event_participants_registration_date ON event_participants(registration_datetime);
CREATE INDEX IF NOT EXISTS idx_event_participants_priority ON event_participants(priority_score);
CREATE INDEX IF NOT EXISTS idx_event_participants_completion ON event_participants(completion_status);
CREATE INDEX IF NOT EXISTS idx_event_participants_approval ON event_participants(manager_approval_status);

-- Participant Queues indexes
CREATE INDEX IF NOT EXISTS idx_participant_queues_event ON participant_queues(event_id);
CREATE INDEX IF NOT EXISTS idx_participant_queues_employee ON participant_queues(employee_id);
CREATE INDEX IF NOT EXISTS idx_participant_queues_position ON participant_queues(queue_position);
CREATE INDEX IF NOT EXISTS idx_participant_queues_priority ON participant_queues(priority_score);
CREATE INDEX IF NOT EXISTS idx_participant_queues_status ON participant_queues(status);
CREATE INDEX IF NOT EXISTS idx_participant_queues_date ON participant_queues(queue_datetime);

-- Participant Allocations indexes
CREATE INDEX IF NOT EXISTS idx_participant_allocations_event ON participant_allocations(event_id);
CREATE INDEX IF NOT EXISTS idx_participant_allocations_method ON participant_allocations(allocation_method);
CREATE INDEX IF NOT EXISTS idx_participant_allocations_date ON participant_allocations(allocation_datetime);
CREATE INDEX IF NOT EXISTS idx_participant_allocations_success ON participant_allocations(allocation_success_rate);

-- Event Capacity History indexes
CREATE INDEX IF NOT EXISTS idx_event_capacity_history_event ON event_capacity_history(event_id);
CREATE INDEX IF NOT EXISTS idx_event_capacity_history_date ON event_capacity_history(change_datetime);
CREATE INDEX IF NOT EXISTS idx_event_capacity_history_type ON event_capacity_history(change_type);

-- Event Schedules indexes
CREATE INDEX IF NOT EXISTS idx_event_schedules_event ON event_schedules(event_id);
CREATE INDEX IF NOT EXISTS idx_event_schedules_type ON event_schedules(schedule_type);
CREATE INDEX IF NOT EXISTS idx_event_schedules_start ON event_schedules(start_datetime);
CREATE INDEX IF NOT EXISTS idx_event_schedules_instructor ON event_schedules(instructor_id);
CREATE INDEX IF NOT EXISTS idx_event_schedules_status ON event_schedules(status);

-- Event Prerequisites indexes
CREATE INDEX IF NOT EXISTS idx_event_prerequisites_event ON event_prerequisites(event_id);
CREATE INDEX IF NOT EXISTS idx_event_prerequisites_type ON event_prerequisites(prerequisite_type);
CREATE INDEX IF NOT EXISTS idx_event_prerequisites_mandatory ON event_prerequisites(is_mandatory);
CREATE INDEX IF NOT EXISTS idx_event_prerequisites_active ON event_prerequisites(is_active);

-- Limit Violations indexes
CREATE INDEX IF NOT EXISTS idx_limit_violations_event ON limit_violations(event_id);
CREATE INDEX IF NOT EXISTS idx_limit_violations_employee ON limit_violations(employee_id);
CREATE INDEX IF NOT EXISTS idx_limit_violations_type ON limit_violations(violation_type);
CREATE INDEX IF NOT EXISTS idx_limit_violations_severity ON limit_violations(violation_severity);
CREATE INDEX IF NOT EXISTS idx_limit_violations_status ON limit_violations(resolution_status);
CREATE INDEX IF NOT EXISTS idx_limit_violations_date ON limit_violations(violation_datetime);

-- Event Conflicts indexes
CREATE INDEX IF NOT EXISTS idx_event_conflicts_primary ON event_conflicts(primary_event_id);
CREATE INDEX IF NOT EXISTS idx_event_conflicts_conflicting ON event_conflicts(conflicting_event_id);
CREATE INDEX IF NOT EXISTS idx_event_conflicts_type ON event_conflicts(conflict_type);
CREATE INDEX IF NOT EXISTS idx_event_conflicts_severity ON event_conflicts(conflict_severity);
CREATE INDEX IF NOT EXISTS idx_event_conflicts_status ON event_conflicts(resolution_status);

-- Event Notifications indexes
CREATE INDEX IF NOT EXISTS idx_event_notifications_event ON event_notifications(event_id);
CREATE INDEX IF NOT EXISTS idx_event_notifications_recipient ON event_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_event_notifications_type ON event_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_event_notifications_status ON event_notifications(delivery_status);
CREATE INDEX IF NOT EXISTS idx_event_notifications_scheduled ON event_notifications(scheduled_datetime);

-- Event Cancellations indexes
CREATE INDEX IF NOT EXISTS idx_event_cancellations_event ON event_cancellations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_cancellations_type ON event_cancellations(cancellation_type);
CREATE INDEX IF NOT EXISTS idx_event_cancellations_date ON event_cancellations(cancellation_datetime);

-- Participant History indexes
CREATE INDEX IF NOT EXISTS idx_participant_history_participant ON participant_history(participant_id);
CREATE INDEX IF NOT EXISTS idx_participant_history_event ON participant_history(event_id);
CREATE INDEX IF NOT EXISTS idx_participant_history_employee ON participant_history(employee_id);
CREATE INDEX IF NOT EXISTS idx_participant_history_action ON participant_history(action_type);
CREATE INDEX IF NOT EXISTS idx_participant_history_date ON participant_history(action_datetime);

-- Event Modifications indexes
CREATE INDEX IF NOT EXISTS idx_event_modifications_event ON event_modifications(event_id);
CREATE INDEX IF NOT EXISTS idx_event_modifications_type ON event_modifications(modification_type);
CREATE INDEX IF NOT EXISTS idx_event_modifications_date ON event_modifications(modification_datetime);
CREATE INDEX IF NOT EXISTS idx_event_modifications_user ON event_modifications(modified_by);

-- Event Analytics indexes
CREATE INDEX IF NOT EXISTS idx_event_analytics_event ON event_analytics(event_id);
CREATE INDEX IF NOT EXISTS idx_event_analytics_date ON event_analytics(analytics_date);
CREATE INDEX IF NOT EXISTS idx_event_analytics_type ON event_analytics(analytics_type);
CREATE INDEX IF NOT EXISTS idx_event_analytics_metric ON event_analytics(metric_name);

-- Event Feedback indexes
CREATE INDEX IF NOT EXISTS idx_event_feedback_event ON event_feedback(event_id);
CREATE INDEX IF NOT EXISTS idx_event_feedback_participant ON event_feedback(participant_id);
CREATE INDEX IF NOT EXISTS idx_event_feedback_employee ON event_feedback(employee_id);
CREATE INDEX IF NOT EXISTS idx_event_feedback_type ON event_feedback(feedback_type);
CREATE INDEX IF NOT EXISTS idx_event_feedback_rating ON event_feedback(rating_score);
CREATE INDEX IF NOT EXISTS idx_event_feedback_date ON event_feedback(feedback_datetime);

-- Event Resources Allocation indexes
CREATE INDEX IF NOT EXISTS idx_event_resources_allocation_event ON event_resources_allocation(event_id);
CREATE INDEX IF NOT EXISTS idx_event_resources_allocation_resource ON event_resources_allocation(resource_id);
CREATE INDEX IF NOT EXISTS idx_event_resources_allocation_period ON event_resources_allocation(allocation_start, allocation_end);
CREATE INDEX IF NOT EXISTS idx_event_resources_allocation_status ON event_resources_allocation(allocation_status);

-- Event Waitlist Management indexes
CREATE INDEX IF NOT EXISTS idx_event_waitlist_management_event ON event_waitlist_management(event_id);
CREATE INDEX IF NOT EXISTS idx_event_waitlist_management_queue ON event_waitlist_management(queue_id);
CREATE INDEX IF NOT EXISTS idx_event_waitlist_management_date ON event_waitlist_management(processing_datetime);
CREATE INDEX IF NOT EXISTS idx_event_waitlist_management_type ON event_waitlist_management(processing_type);

-- Event Templates indexes
CREATE INDEX IF NOT EXISTS idx_event_templates_type ON event_templates(event_type_id);
CREATE INDEX IF NOT EXISTS idx_event_templates_category ON event_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_event_templates_status ON event_templates(template_status);
CREATE INDEX IF NOT EXISTS idx_event_templates_public ON event_templates(is_public);
CREATE INDEX IF NOT EXISTS idx_event_templates_usage ON event_templates(usage_count);

-- Event Compliance indexes
CREATE INDEX IF NOT EXISTS idx_event_compliance_event ON event_compliance(event_id);
CREATE INDEX IF NOT EXISTS idx_event_compliance_type ON event_compliance(compliance_type);
CREATE INDEX IF NOT EXISTS idx_event_compliance_status ON event_compliance(compliance_status);
CREATE INDEX IF NOT EXISTS idx_event_compliance_deadline ON event_compliance(compliance_deadline);
CREATE INDEX IF NOT EXISTS idx_event_compliance_risk ON event_compliance(risk_level);

-- =====================================================================================
-- COMPREHENSIVE DEMO DATA
-- =====================================================================================

-- Insert Event Types
INSERT INTO event_types (event_type_id, type_name, type_name_ru, description, description_ru, category, default_capacity, capacity_type, min_participants, max_participants, optimal_participants, duration_minutes, prerequisites, required_skills, resource_requirements) VALUES
(uuid_generate_v4(), 'Technical Training', 'Техническое обучение', 'Technical skills development training', 'Обучение развитию технических навыков', 'training', 20, 'skill_based', 5, 30, 20, 480, ARRAY['Basic computer skills', 'Department approval'], ARRAY['Communication', 'Problem solving'], '{"projector": 1, "computers": 20, "whiteboard": 1}'),
(uuid_generate_v4(), 'Team Meeting', 'Командная встреча', 'Regular team coordination meeting', 'Регулярная встреча для координации команды', 'meeting', 15, 'flexible', 3, 25, 15, 60, ARRAY['Team membership'], ARRAY['Communication'], '{"meeting_room": 1, "projector": 1}'),
(uuid_generate_v4(), 'Leadership Workshop', 'Семинар по лидерству', 'Leadership development workshop', 'Семинар по развитию лидерских навыков', 'workshop', 12, 'fixed', 8, 15, 12, 240, ARRAY['Management role', 'HR approval'], ARRAY['Leadership', 'Communication', 'Management'], '{"workshop_room": 1, "flipchart": 2, "materials": 1}'),
(uuid_generate_v4(), 'Safety Training', 'Обучение по безопасности', 'Mandatory safety training', 'Обязательное обучение по технике безопасности', 'training', 25, 'fixed', 10, 25, 25, 120, ARRAY['Employment status'], ARRAY['Safety awareness'], '{"training_room": 1, "safety_equipment": 1}'),
(uuid_generate_v4(), 'Annual Conference', 'Ежегодная конференция', 'Annual company conference', 'Ежегодная конференция компании', 'conference', 100, 'percentage', 50, 200, 100, 480, ARRAY['Company employee'], ARRAY['Professional development'], '{"conference_hall": 1, "audio_system": 1, "catering": 1}');

-- Insert Event Locations
INSERT INTO event_locations (location_id, location_name, location_name_ru, location_type, address, address_ru, capacity, floor_number, building, equipment, accessibility_features) VALUES
(uuid_generate_v4(), 'Training Room A', 'Учебный зал А', 'room', '123 Business Street, Floor 3', 'ул. Деловая, 123, 3 этаж', 30, 3, 'Main Building', '{"projector": 1, "computers": 25, "whiteboard": 2, "air_conditioning": 1}', ARRAY['Wheelchair accessible', 'Hearing loop', 'Adjustable lighting']),
(uuid_generate_v4(), 'Conference Hall', 'Конференц-зал', 'hall', '123 Business Street, Floor 1', 'ул. Деловая, 123, 1 этаж', 150, 1, 'Main Building', '{"projector": 2, "audio_system": 1, "stage": 1, "microphones": 4}', ARRAY['Wheelchair accessible', 'Hearing loop', 'Sign language interpretation']),
(uuid_generate_v4(), 'Workshop Room B', 'Семинарский зал Б', 'room', '123 Business Street, Floor 2', 'ул. Деловая, 123, 2 этаж', 20, 2, 'Main Building', '{"flipchart": 3, "round_tables": 4, "projector": 1}', ARRAY['Wheelchair accessible', 'Adjustable furniture']),
(uuid_generate_v4(), 'Virtual Platform', 'Виртуальная платформа', 'virtual', 'Online Meeting Platform', 'Онлайн платформа для встреч', 500, NULL, 'Virtual', '{"video_conferencing": 1, "screen_sharing": 1, "breakout_rooms": 1}', ARRAY['Closed captions', 'Multi-language support']),
(uuid_generate_v4(), 'Outdoor Training Area', 'Открытая учебная площадка', 'outdoor', 'Company Grounds, Section C', 'Территория компании, участок С', 50, NULL, 'Outdoor', '{"sound_system": 1, "weather_protection": 1, "safety_equipment": 1}', ARRAY['Accessible pathways', 'Seating accommodation']);

-- Insert Event Resources
INSERT INTO event_resources (resource_id, resource_name, resource_name_ru, resource_type, description, description_ru, quantity_available, cost_per_unit, location_id) VALUES
(uuid_generate_v4(), 'Projector HD', 'Проектор HD', 'equipment', 'High-definition projector for presentations', 'Высококачественный проектор для презентаций', 5, 50.00, (SELECT location_id FROM event_locations WHERE location_name = 'Training Room A' LIMIT 1)),
(uuid_generate_v4(), 'Laptop Computer', 'Ноутбук', 'equipment', 'Training laptop with software', 'Учебный ноутбук с программным обеспечением', 30, 25.00, (SELECT location_id FROM event_locations WHERE location_name = 'Training Room A' LIMIT 1)),
(uuid_generate_v4(), 'Flipchart Stand', 'Флипчарт', 'equipment', 'Portable flipchart stand with paper', 'Портативный флипчарт с бумагой', 10, 15.00, (SELECT location_id FROM event_locations WHERE location_name = 'Workshop Room B' LIMIT 1)),
(uuid_generate_v4(), 'Training Materials', 'Учебные материалы', 'material', 'Printed training materials and handouts', 'Печатные учебные материалы и раздаточные материалы', 100, 5.00, NULL),
(uuid_generate_v4(), 'Audio System', 'Аудиосистема', 'equipment', 'Professional audio system with microphones', 'Профессиональная аудиосистема с микрофонами', 2, 100.00, (SELECT location_id FROM event_locations WHERE location_name = 'Conference Hall' LIMIT 1));

-- Insert sample Events
INSERT INTO events (event_id, event_type_id, event_name, event_name_ru, description, description_ru, location_id, start_datetime, end_datetime, registration_start, registration_end, max_participants, current_participants, organizer_id, status, priority_level) VALUES
(uuid_generate_v4(), (SELECT event_type_id FROM event_types WHERE type_name = 'Technical Training' LIMIT 1), 'Advanced SQL Training', 'Продвинутый курс SQL', 'Advanced SQL database training for developers', 'Продвинутое обучение SQL для разработчиков', (SELECT location_id FROM event_locations WHERE location_name = 'Training Room A' LIMIT 1), '2024-08-15 09:00:00+03', '2024-08-15 17:00:00+03', '2024-07-15 00:00:00+03', '2024-08-10 23:59:59+03', 20, 15, uuid_generate_v4(), 'open', 3),
(uuid_generate_v4(), (SELECT event_type_id FROM event_types WHERE type_name = 'Team Meeting' LIMIT 1), 'Q3 Planning Meeting', 'Планирование Q3', 'Quarterly planning and review meeting', 'Квартальное планирование и обзорная встреча', (SELECT location_id FROM event_locations WHERE location_name = 'Conference Hall' LIMIT 1), '2024-07-20 10:00:00+03', '2024-07-20 12:00:00+03', '2024-07-16 00:00:00+03', '2024-07-19 18:00:00+03', 25, 18, uuid_generate_v4(), 'full', 4),
(uuid_generate_v4(), (SELECT event_type_id FROM event_types WHERE type_name = 'Leadership Workshop' LIMIT 1), 'Effective Communication', 'Эффективная коммуникация', 'Leadership communication skills workshop', 'Семинар по лидерским навыкам коммуникации', (SELECT location_id FROM event_locations WHERE location_name = 'Workshop Room B' LIMIT 1), '2024-08-01 09:00:00+03', '2024-08-01 13:00:00+03', '2024-07-16 00:00:00+03', '2024-07-28 23:59:59+03', 15, 12, uuid_generate_v4(), 'open', 2),
(uuid_generate_v4(), (SELECT event_type_id FROM event_types WHERE type_name = 'Safety Training' LIMIT 1), 'Workplace Safety Basics', 'Основы безопасности на рабочем месте', 'Mandatory workplace safety training', 'Обязательное обучение безопасности на рабочем месте', (SELECT location_id FROM event_locations WHERE location_name = 'Training Room A' LIMIT 1), '2024-07-25 14:00:00+03', '2024-07-25 16:00:00+03', '2024-07-16 00:00:00+03', '2024-07-23 23:59:59+03', 25, 25, uuid_generate_v4(), 'full', 5),
(uuid_generate_v4(), (SELECT event_type_id FROM event_types WHERE type_name = 'Annual Conference' LIMIT 1), 'Innovation Summit 2024', 'Саммит инноваций 2024', 'Annual innovation and technology summit', 'Ежегодный саммит инноваций и технологий', (SELECT location_id FROM event_locations WHERE location_name = 'Conference Hall' LIMIT 1), '2024-09-15 09:00:00+03', '2024-09-15 18:00:00+03', '2024-07-16 00:00:00+03', '2024-09-01 23:59:59+03', 150, 89, uuid_generate_v4(), 'open', 5);

-- Insert Participant Limits
INSERT INTO participant_limits (limit_id, event_id, limit_type, limit_value, priority, enforcement_rule, violation_action, effective_from, created_by) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), 'capacity', 20, 1, 'hard', 'waitlist', '2024-07-15 00:00:00+03', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), 'skill', 10, 2, 'soft', 'approve', '2024-07-15 00:00:00+03', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), 'department', 5, 1, 'hard', 'reject', '2024-07-16 00:00:00+03', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Effective Communication' LIMIT 1), 'seniority', 2, 3, 'soft', 'escalate', '2024-07-16 00:00:00+03', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), 'capacity', 150, 1, 'hard', 'waitlist', '2024-07-16 00:00:00+03', uuid_generate_v4());

-- Insert Participant Priorities
INSERT INTO participant_priorities (priority_id, event_id, priority_type, priority_name, priority_name_ru, weight_factor, calculation_method, created_by) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), 'skill', 'SQL Experience', 'Опыт работы с SQL', 2.0, 'linear', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), 'seniority', 'Years of Service', 'Стаж работы', 1.5, 'linear', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Effective Communication' LIMIT 1), 'role', 'Management Position', 'Управленческая позиция', 3.0, 'step', uuid_generate_v4()),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), 'department', 'Department Priority', 'Приоритет отдела', 2.5, 'linear', uuid_generate_v4()),
(uuid_generate_v4(), NULL, 'registration', 'First Come First Served', 'Живая очередь', 1.0, 'linear', uuid_generate_v4());

-- Insert sample Event Participants
INSERT INTO event_participants (participant_id, event_id, employee_id, registration_datetime, status, priority_score, allocation_method, confirmed_at) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), uuid_generate_v4(), '2024-07-16 09:00:00+03', 'confirmed', 85.50, 'automatic', '2024-07-16 09:30:00+03'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), uuid_generate_v4(), '2024-07-16 09:15:00+03', 'confirmed', 92.75, 'automatic', '2024-07-16 09:45:00+03'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), uuid_generate_v4(), '2024-07-16 10:00:00+03', 'confirmed', 78.25, 'manual', '2024-07-16 10:30:00+03'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Effective Communication' LIMIT 1), uuid_generate_v4(), '2024-07-16 11:00:00+03', 'registered', 88.00, 'automatic', NULL),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), uuid_generate_v4(), '2024-07-16 14:00:00+03', 'confirmed', 95.50, 'automatic', '2024-07-16 14:30:00+03');

-- Insert sample Participant Queues
INSERT INTO participant_queues (queue_id, event_id, employee_id, queue_type, queue_position, original_position, priority_score, estimated_wait_time, status) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), uuid_generate_v4(), 'priority', 1, 1, 87.50, 120, 'waiting'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), uuid_generate_v4(), 'standard', 2, 2, 75.25, 240, 'waiting'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Workplace Safety Basics' LIMIT 1), uuid_generate_v4(), 'department', 1, 1, 82.00, 60, 'waiting'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), uuid_generate_v4(), 'priority', 1, 1, 91.75, 480, 'waiting'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), uuid_generate_v4(), 'standard', 2, 2, 79.50, 720, 'waiting');

-- Insert sample Event Notifications
INSERT INTO event_notifications (notification_id, event_id, recipient_id, notification_type, notification_template, notification_title, notification_title_ru, notification_content, notification_content_ru, delivery_method, scheduled_datetime, sent_datetime, delivery_status) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), uuid_generate_v4(), 'registration', 'registration_confirmed', 'Registration Confirmed', 'Регистрация подтверждена', 'Your registration for Advanced SQL Training has been confirmed', 'Ваша регистрация на продвинутый курс SQL подтверждена', 'email', '2024-07-16 09:30:00+03', '2024-07-16 09:30:15+03', 'delivered'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), uuid_generate_v4(), 'waitlist', 'waitlist_added', 'Added to Waitlist', 'Добавлен в очередь ожидания', 'You have been added to the waitlist for Q3 Planning Meeting', 'Вы добавлены в очередь ожидания на встречу планирования Q3', 'email', '2024-07-16 10:00:00+03', '2024-07-16 10:00:20+03', 'delivered'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Effective Communication' LIMIT 1), uuid_generate_v4(), 'reminder', 'event_reminder', 'Event Reminder', 'Напоминание о мероприятии', 'Reminder: Effective Communication workshop is tomorrow', 'Напоминание: семинар по эффективной коммуникации завтра', 'email', '2024-07-31 18:00:00+03', NULL, 'pending'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), uuid_generate_v4(), 'registration', 'registration_confirmed', 'Registration Confirmed', 'Регистрация подтверждена', 'Your registration for Innovation Summit 2024 has been confirmed', 'Ваша регистрация на Саммит инноваций 2024 подтверждена', 'email', '2024-07-16 14:30:00+03', '2024-07-16 14:30:10+03', 'delivered'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Workplace Safety Basics' LIMIT 1), uuid_generate_v4(), 'reminder', 'mandatory_training_reminder', 'Mandatory Training Reminder', 'Напоминание об обязательном обучении', 'Reminder: Mandatory safety training is in 2 days', 'Напоминание: обязательное обучение по безопасности через 2 дня', 'email', '2024-07-23 09:00:00+03', NULL, 'pending');

-- Insert sample Event Analytics
INSERT INTO event_analytics (analytics_id, event_id, analytics_date, analytics_type, metric_name, metric_value, metric_unit, calculation_method, calculation_period, benchmark_value, trend_direction) VALUES
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Advanced SQL Training' LIMIT 1), '2024-07-16', 'utilization', 'Registration Rate', 75.00, 'percentage', 'current/max*100', 'daily', 80.00, 'up'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Q3 Planning Meeting' LIMIT 1), '2024-07-16', 'demand', 'Waitlist Size', 2, 'count', 'sum', 'daily', 3, 'down'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Effective Communication' LIMIT 1), '2024-07-16', 'efficiency', 'Cost per Participant', 125.50, 'currency', 'total_cost/participants', 'event_lifecycle', 150.00, 'down'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Innovation Summit 2024' LIMIT 1), '2024-07-16', 'utilization', 'Registration Rate', 59.33, 'percentage', 'current/max*100', 'daily', 65.00, 'up'),
(uuid_generate_v4(), (SELECT event_id FROM events WHERE event_name = 'Workplace Safety Basics' LIMIT 1), '2024-07-16', 'utilization', 'Capacity Usage', 100.00, 'percentage', 'current/max*100', 'daily', 90.00, 'up');

-- Insert sample Event Feedback (will be populated after participants are created)
-- This insert requires participant_id references so will be done after event_participants are created
WITH participants AS (
    SELECT 
        ep.participant_id,
        ep.event_id,
        ep.employee_id,
        e.event_name,
        ROW_NUMBER() OVER (PARTITION BY ep.event_id ORDER BY ep.registration_datetime) as rn
    FROM event_participants ep
    JOIN events e ON ep.event_id = e.event_id
)
INSERT INTO event_feedback (feedback_id, event_id, participant_id, employee_id, feedback_type, feedback_category, rating_score, feedback_text, feedback_text_ru, would_recommend, content_relevance_score, instructor_effectiveness_score, logistics_satisfaction_score, overall_satisfaction_score) 
SELECT 
    uuid_generate_v4(),
    p.event_id,
    p.participant_id,
    p.employee_id,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 'overall'
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 'content'
        WHEN p.event_name = 'Effective Communication' THEN 'instructor'
        WHEN p.event_name = 'Innovation Summit 2024' THEN 'logistics'
        ELSE 'content'
    END as feedback_type,
    'rating' as feedback_category,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 4
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 5
        WHEN p.event_name = 'Effective Communication' THEN 3
        WHEN p.event_name = 'Innovation Summit 2024' THEN 5
        ELSE 4
    END as rating_score,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 'Great training, very informative'
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 'Well organized and productive meeting'
        WHEN p.event_name = 'Effective Communication' THEN 'Good content but could be more interactive'
        WHEN p.event_name = 'Innovation Summit 2024' THEN 'Excellent venue and organization'
        ELSE 'Essential information, well presented'
    END as feedback_text,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 'Отличное обучение, очень информативно'
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 'Хорошо организованная и продуктивная встреча'
        WHEN p.event_name = 'Effective Communication' THEN 'Хорошее содержание, но могло бы быть более интерактивным'
        WHEN p.event_name = 'Innovation Summit 2024' THEN 'Отличное место проведения и организация'
        ELSE 'Основная информация, хорошо представлена'
    END as feedback_text_ru,
    true as would_recommend,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 5
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 5
        WHEN p.event_name = 'Effective Communication' THEN 4
        WHEN p.event_name = 'Innovation Summit 2024' THEN 5
        ELSE 4
    END as content_relevance_score,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 4
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 5
        WHEN p.event_name = 'Effective Communication' THEN 3
        WHEN p.event_name = 'Innovation Summit 2024' THEN 5
        ELSE 4
    END as instructor_effectiveness_score,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 4
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 5
        WHEN p.event_name = 'Effective Communication' THEN 4
        WHEN p.event_name = 'Innovation Summit 2024' THEN 5
        ELSE 4
    END as logistics_satisfaction_score,
    CASE 
        WHEN p.event_name = 'Advanced SQL Training' THEN 4
        WHEN p.event_name = 'Q3 Planning Meeting' THEN 5
        WHEN p.event_name = 'Effective Communication' THEN 3
        WHEN p.event_name = 'Innovation Summit 2024' THEN 5
        ELSE 4
    END as overall_satisfaction_score
FROM participants p
WHERE p.rn = 1;

-- Insert sample Event Templates
INSERT INTO event_templates (template_id, template_name, template_name_ru, template_description, template_description_ru, event_type_id, template_category, default_duration_minutes, default_capacity, created_by) VALUES
(uuid_generate_v4(), 'Standard Training Template', 'Стандартный шаблон обучения', 'Standard template for technical training events', 'Стандартный шаблон для технических учебных мероприятий', (SELECT event_type_id FROM event_types WHERE type_name = 'Technical Training' LIMIT 1), 'training', 480, 20, uuid_generate_v4()),
(uuid_generate_v4(), 'Team Meeting Template', 'Шаблон командной встречи', 'Template for regular team meetings', 'Шаблон для регулярных командных встреч', (SELECT event_type_id FROM event_types WHERE type_name = 'Team Meeting' LIMIT 1), 'meeting', 60, 15, uuid_generate_v4()),
(uuid_generate_v4(), 'Workshop Template', 'Шаблон семинара', 'Template for interactive workshops', 'Шаблон для интерактивных семинаров', (SELECT event_type_id FROM event_types WHERE type_name = 'Leadership Workshop' LIMIT 1), 'workshop', 240, 12, uuid_generate_v4()),
(uuid_generate_v4(), 'Safety Training Template', 'Шаблон обучения по безопасности', 'Template for mandatory safety training', 'Шаблон для обязательного обучения по безопасности', (SELECT event_type_id FROM event_types WHERE type_name = 'Safety Training' LIMIT 1), 'training', 120, 25, uuid_generate_v4()),
(uuid_generate_v4(), 'Conference Template', 'Шаблон конференции', 'Template for large conference events', 'Шаблон для больших конференций', (SELECT event_type_id FROM event_types WHERE type_name = 'Annual Conference' LIMIT 1), 'conference', 480, 100, uuid_generate_v4());

-- =====================================================================================
-- VERIFICATION QUERY
-- =====================================================================================

-- Verify the schema deployment
SELECT 
    'Schema 131: Event & Participant Management System' as schema_name,
    'DEPLOYED' as status,
    24 as total_tables,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE '%event%') as event_tables_created,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE '%participant%') as participant_tables_created,
    CURRENT_TIMESTAMP as deployment_timestamp;

-- Table count verification
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN (
    'event_types', 'event_locations', 'event_resources', 'events', 
    'participant_limits', 'participant_priorities', 'event_participants', 
    'participant_queues', 'participant_allocations', 'event_capacity_history',
    'event_schedules', 'event_prerequisites', 'limit_violations', 
    'event_conflicts', 'event_notifications', 'event_cancellations',
    'participant_history', 'event_modifications', 'event_analytics', 
    'event_feedback', 'event_resources_allocation', 'event_waitlist_management',
    'event_templates', 'event_compliance'
)
ORDER BY table_name;

-- Demo data verification
SELECT 
    'Demo Data Summary' as summary,
    (SELECT COUNT(*) FROM event_types) as event_types_count,
    (SELECT COUNT(*) FROM event_locations) as locations_count,
    (SELECT COUNT(*) FROM event_resources) as resources_count,
    (SELECT COUNT(*) FROM events) as events_count,
    (SELECT COUNT(*) FROM event_participants) as participants_count,
    (SELECT COUNT(*) FROM participant_queues) as queue_count,
    (SELECT COUNT(*) FROM event_notifications) as notifications_count,
    (SELECT COUNT(*) FROM event_analytics) as analytics_count,
    (SELECT COUNT(*) FROM event_feedback) as feedback_count,
    (SELECT COUNT(*) FROM event_templates) as templates_count;

-- =====================================================================================
-- SCHEMA DEPLOYMENT COMPLETE
-- =====================================================================================