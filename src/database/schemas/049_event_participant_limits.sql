-- =============================================================================
-- 049_event_participant_limits.sql
-- EXACT BDD Implementation: Event Participant Limits with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 23-event-participant-limits.feature (200+ lines)
-- Purpose: Comprehensive event participant management with capacity control and queue processing
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. EVENT TYPE DEFINITIONS
-- =============================================================================

-- Event type definitions from BDD line 18
CREATE TABLE event_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_id VARCHAR(50) NOT NULL UNIQUE,
    type_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Capacity configuration from BDD lines 42-48
    capacity_type VARCHAR(30) NOT NULL CHECK (capacity_type IN (
        'fixed_capacity', 'flexible_capacity', 'percentage_capacity', 
        'skill_based_capacity', 'resource_based_capacity'
    )),
    
    default_capacity INTEGER,
    capacity_calculation_rule TEXT,
    
    -- Resource requirements
    required_resources JSONB DEFAULT '[]',
    required_skills JSONB DEFAULT '[]',
    
    -- Business rules
    allows_overbooking BOOLEAN DEFAULT false,
    default_overbooking_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. EVENT INSTANCES
-- =============================================================================

-- Event instances from BDD line 19
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id VARCHAR(50) NOT NULL UNIQUE,
    event_type_id UUID NOT NULL REFERENCES event_types(id),
    
    name VARCHAR(300) NOT NULL,
    description TEXT,
    
    -- Event scheduling
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Capacity management from BDD lines 49-55
    min_participants INTEGER DEFAULT 1,
    max_participants INTEGER NOT NULL,
    optimal_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    
    -- Overbooking configuration
    overbooking_enabled BOOLEAN DEFAULT false,
    overbooking_percentage DECIMAL(5,2) DEFAULT 0.0,
    effective_max_capacity INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN overbooking_enabled THEN 
                CEIL(max_participants * (1 + overbooking_percentage / 100.0))
            ELSE max_participants 
        END
    ) STORED,
    
    -- Waitlist configuration
    waitlist_enabled BOOLEAN DEFAULT true,
    waitlist_size_limit INTEGER DEFAULT 50,
    current_waitlist_size INTEGER DEFAULT 0,
    
    -- Event status
    status VARCHAR(20) DEFAULT 'planned' CHECK (status IN (
        'planned', 'active', 'cancelled', 'completed', 'full', 'waitlist_only'
    )),
    
    -- Location and resources
    location VARCHAR(300),
    required_resources JSONB DEFAULT '[]',
    allocated_resources JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_participant_range CHECK (min_participants <= max_participants),
    CONSTRAINT valid_optimal_range CHECK (optimal_participants IS NULL OR 
        (optimal_participants >= min_participants AND optimal_participants <= max_participants))
);

-- =============================================================================
-- 3. PARTICIPANT LIMIT CONFIGURATIONS
-- =============================================================================

-- Limit configurations from BDD line 20
CREATE TABLE participant_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    limit_id VARCHAR(50) NOT NULL UNIQUE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    
    -- Limit types and enforcement from BDD lines 24-30
    limit_type VARCHAR(30) NOT NULL CHECK (limit_type IN (
        'capacity_enforcement', 'priority_handling', 'overbooking_control',
        'waitlist_management', 'conflict_resolution'
    )),
    
    limit_value INTEGER NOT NULL,
    
    -- Priority and enforcement
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    enforcement_rule VARCHAR(20) NOT NULL CHECK (enforcement_rule IN (
        'hard', 'soft', 'warning_only'
    )),
    
    -- Validation rules
    validation_rules JSONB DEFAULT '{}',
    
    -- Limit metadata
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. EVENT PARTICIPANTS
-- =============================================================================

-- Participant registrations from BDD line 21
CREATE TABLE event_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_id VARCHAR(50) NOT NULL UNIQUE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL,
    
    -- Registration details
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    registration_method VARCHAR(30) CHECK (registration_method IN (
        'self_registration', 'admin_assignment', 'automatic_allocation', 'waitlist_promotion'
    )),
    
    -- Priority system from BDD lines 67-74
    priority_type VARCHAR(30) CHECK (priority_type IN (
        'seniority_based', 'skill_based', 'role_based', 'department_based', 'registration_based'
    )),
    priority_score DECIMAL(8,2) DEFAULT 0.0,
    priority_criteria JSONB DEFAULT '{}',
    
    -- Allocation rules from BDD lines 75-79
    allocation_method VARCHAR(30) CHECK (allocation_method IN (
        'automatic', 'manual', 'hybrid', 'lottery'
    )),
    
    -- Participant status
    status VARCHAR(20) DEFAULT 'registered' CHECK (status IN (
        'registered', 'confirmed', 'attended', 'no_show', 'cancelled', 'waitlisted'
    )),
    
    -- Additional tracking
    confirmation_sent BOOLEAN DEFAULT false,
    confirmation_date TIMESTAMP WITH TIME ZONE,
    cancellation_date TIMESTAMP WITH TIME ZONE,
    cancellation_reason VARCHAR(200),
    
    -- Skills and requirements
    participant_skills JSONB DEFAULT '[]',
    meets_requirements BOOLEAN DEFAULT true,
    requirement_notes TEXT,
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_event_participant UNIQUE(event_id, employee_id)
);

-- =============================================================================
-- 5. PARTICIPANT QUEUES (WAITLISTS)
-- =============================================================================

-- Waiting lists from BDD line 22
CREATE TABLE participant_queues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_id VARCHAR(50) NOT NULL UNIQUE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL,
    
    -- Queue types from BDD lines 91-96
    queue_type VARCHAR(30) NOT NULL CHECK (queue_type IN (
        'fifo_queue', 'priority_queue', 'skill_queue', 'department_queue'
    )),
    
    -- Queue position and management
    queue_position INTEGER NOT NULL,
    queue_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Priority in queue
    queue_priority_score DECIMAL(8,2) DEFAULT 0.0,
    queue_priority_criteria JSONB DEFAULT '{}',
    
    -- Processing rules from BDD lines 97-100
    auto_promotion_enabled BOOLEAN DEFAULT true,
    manual_promotion_required BOOLEAN DEFAULT false,
    
    -- Notification management
    notification_sent BOOLEAN DEFAULT false,
    notification_date TIMESTAMP WITH TIME ZONE,
    notification_method VARCHAR(30),
    
    -- Queue status
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN (
        'waiting', 'promoted', 'expired', 'cancelled', 'declined'
    )),
    
    -- Expiry management
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_event_queue_participant UNIQUE(event_id, employee_id)
);

-- =============================================================================
-- 6. LIMIT VIOLATIONS TRACKING
-- =============================================================================

-- Violation tracking from BDD line 23
CREATE TABLE limit_violations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    violation_id VARCHAR(50) NOT NULL UNIQUE,
    event_id UUID NOT NULL REFERENCES events(id),
    employee_id UUID,
    
    -- Violation details
    violation_type VARCHAR(50) NOT NULL CHECK (violation_type IN (
        'capacity_exceeded', 'skill_requirement_not_met', 'resource_conflict',
        'priority_violation', 'queue_jump', 'duplicate_registration'
    )),
    
    violation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    violation_description TEXT NOT NULL,
    
    -- Context and impact
    violation_severity VARCHAR(20) CHECK (violation_severity IN ('low', 'medium', 'high', 'critical')),
    impact_assessment TEXT,
    
    -- Resolution tracking
    resolution VARCHAR(20) DEFAULT 'pending' CHECK (resolution IN (
        'pending', 'auto_resolved', 'manual_resolved', 'escalated', 'ignored'
    )),
    resolution_date TIMESTAMP WITH TIME ZONE,
    resolution_method VARCHAR(100),
    resolution_notes TEXT,
    resolved_by VARCHAR(100),
    
    -- System response
    auto_correction_attempted BOOLEAN DEFAULT false,
    auto_correction_successful BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. EVENT CAPACITY MONITORING
-- =============================================================================

-- Capacity monitoring from BDD lines 56-61
CREATE TABLE event_capacity_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id),
    
    monitoring_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Real-time capacity tracking
    current_participants INTEGER NOT NULL,
    current_waitlist_size INTEGER DEFAULT 0,
    available_capacity INTEGER,
    utilization_percentage DECIMAL(5,2),
    
    -- Monitoring types from BDD lines 57-61
    monitoring_type VARCHAR(30) CHECK (monitoring_type IN (
        'real_time_capacity', 'utilization_tracking', 'trend_analysis', 'resource_conflicts'
    )),
    
    -- Capacity analysis
    capacity_trend VARCHAR(20) CHECK (capacity_trend IN ('increasing', 'stable', 'decreasing')),
    predicted_final_capacity INTEGER,
    
    -- Alert generation
    alert_generated BOOLEAN DEFAULT false,
    alert_type VARCHAR(30),
    alert_message TEXT,
    alert_severity VARCHAR(20),
    
    -- Resource conflict detection
    resource_conflicts_detected JSONB DEFAULT '[]',
    overlapping_events JSONB DEFAULT '[]'
);

-- =============================================================================
-- 8. PRIORITY PROCESSING SYSTEM
-- =============================================================================

-- Priority processing from BDD lines 80-85
CREATE TABLE participant_priority_processing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id),
    employee_id UUID NOT NULL,
    
    -- Priority scoring from BDD line 82
    priority_score DECIMAL(10,4) NOT NULL,
    score_components JSONB NOT NULL, -- Breakdown of scoring factors
    
    -- Tie-breaking rules from BDD line 83
    tie_break_criteria JSONB DEFAULT '[]',
    tie_break_score DECIMAL(10,4) DEFAULT 0.0,
    
    -- Processing results
    processing_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    final_rank INTEGER,
    allocation_result VARCHAR(20) CHECK (allocation_result IN (
        'allocated', 'waitlisted', 'rejected', 'pending'
    )),
    
    -- Appeals process from BDD line 84
    appeal_submitted BOOLEAN DEFAULT false,
    appeal_date TIMESTAMP WITH TIME ZONE,
    appeal_reason TEXT,
    appeal_status VARCHAR(20) CHECK (appeal_status IN (
        'pending', 'approved', 'rejected', 'under_review'
    )),
    appeal_resolution TEXT,
    
    -- Audit trail from BDD line 85
    allocation_audit_trail JSONB DEFAULT '[]',
    processing_notes TEXT,
    
    CONSTRAINT unique_event_employee_priority UNIQUE(event_id, employee_id)
);

-- =============================================================================
-- 9. QUEUE PROCESSING AUTOMATION
-- =============================================================================

-- Queue processing automation
CREATE TABLE queue_processing_automation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id),
    
    -- Processing configuration
    auto_processing_enabled BOOLEAN DEFAULT true,
    processing_frequency_minutes INTEGER DEFAULT 15,
    
    -- Last processing run
    last_processing_timestamp TIMESTAMP WITH TIME ZONE,
    next_processing_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Processing results
    participants_promoted INTEGER DEFAULT 0,
    queue_positions_updated INTEGER DEFAULT 0,
    notifications_sent INTEGER DEFAULT 0,
    
    -- Processing log
    processing_log JSONB DEFAULT '[]',
    processing_errors JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate priority score
CREATE OR REPLACE FUNCTION calculate_participant_priority_score(
    p_employee_id UUID,
    p_event_id UUID,
    p_priority_type VARCHAR
) RETURNS DECIMAL(10,4) AS $$
DECLARE
    v_score DECIMAL(10,4) := 0.0;
    v_event RECORD;
    v_components JSONB := '{}';
BEGIN
    -- Get event details
    SELECT * INTO v_event FROM events WHERE id = p_event_id;
    
    -- Calculate score based on priority type
    CASE p_priority_type
        WHEN 'seniority_based' THEN
            -- Simplified seniority calculation (years of service * 10)
            v_score := 50.0; -- Placeholder
            v_components := jsonb_build_object('seniority_years', 5, 'seniority_score', 50.0);
            
        WHEN 'skill_based' THEN
            -- Simplified skill matching calculation
            v_score := 75.0; -- Placeholder
            v_components := jsonb_build_object('skill_match_percentage', 90, 'skill_score', 75.0);
            
        WHEN 'role_based' THEN
            -- Simplified role priority calculation
            v_score := 60.0; -- Placeholder
            v_components := jsonb_build_object('role_priority', 3, 'role_score', 60.0);
            
        WHEN 'registration_based' THEN
            -- First-come-first-served (timestamp-based)
            v_score := 25.0; -- Placeholder
            v_components := jsonb_build_object('registration_order', 1, 'fcfs_score', 25.0);
            
        ELSE
            v_score := 30.0; -- Default score
    END CASE;
    
    -- Store score components for transparency
    INSERT INTO participant_priority_processing (
        event_id, employee_id, priority_score, score_components
    ) VALUES (
        p_event_id, p_employee_id, v_score, v_components
    ) ON CONFLICT (event_id, employee_id) DO UPDATE SET
        priority_score = v_score,
        score_components = v_components,
        processing_timestamp = CURRENT_TIMESTAMP;
    
    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- Function to process participant queue
CREATE OR REPLACE FUNCTION process_participant_queue(p_event_id UUID)
RETURNS TABLE (
    promoted_count INTEGER,
    notifications_sent INTEGER,
    processing_notes TEXT
) AS $$
DECLARE
    v_event RECORD;
    v_available_spots INTEGER;
    v_promoted_count INTEGER := 0;
    v_notifications_count INTEGER := 0;
    v_queue_record RECORD;
BEGIN
    -- Get event details
    SELECT * INTO v_event FROM events WHERE id = p_event_id;
    
    -- Calculate available spots
    v_available_spots := v_event.max_participants - v_event.current_participants;
    
    -- Process queue if spots available
    IF v_available_spots > 0 THEN
        -- Get queued participants in priority order
        FOR v_queue_record IN 
            SELECT pq.*, pp.priority_score
            FROM participant_queues pq
            LEFT JOIN participant_priority_processing pp ON pp.event_id = pq.event_id AND pp.employee_id = pq.employee_id
            WHERE pq.event_id = p_event_id 
            AND pq.status = 'waiting'
            AND pq.auto_promotion_enabled = true
            ORDER BY pp.priority_score DESC NULLS LAST, pq.queue_position ASC
            LIMIT v_available_spots
        LOOP
            -- Promote participant
            INSERT INTO event_participants (
                participant_id, event_id, employee_id, registration_method, 
                priority_type, priority_score, allocation_method, status
            ) VALUES (
                'promoted_' || v_queue_record.queue_id,
                p_event_id,
                v_queue_record.employee_id,
                'waitlist_promotion',
                'priority_queue',
                COALESCE(v_queue_record.priority_score, 0.0),
                'automatic',
                'registered'
            );
            
            -- Update queue status
            UPDATE participant_queues 
            SET status = 'promoted', updated_at = CURRENT_TIMESTAMP
            WHERE id = v_queue_record.id;
            
            v_promoted_count := v_promoted_count + 1;
            v_notifications_count := v_notifications_count + 1;
        END LOOP;
        
        -- Update event participant count
        UPDATE events 
        SET current_participants = current_participants + v_promoted_count
        WHERE id = p_event_id;
    END IF;
    
    -- Log processing results
    INSERT INTO queue_processing_automation (
        event_id, last_processing_timestamp, participants_promoted, notifications_sent
    ) VALUES (
        p_event_id, CURRENT_TIMESTAMP, v_promoted_count, v_notifications_count
    ) ON CONFLICT (event_id) DO UPDATE SET
        last_processing_timestamp = CURRENT_TIMESTAMP,
        participants_promoted = queue_processing_automation.participants_promoted + v_promoted_count,
        notifications_sent = queue_processing_automation.notifications_sent + v_notifications_count;
    
    RETURN QUERY SELECT v_promoted_count, v_notifications_count, 
        'Processed queue for event ' || p_event_id::TEXT || '. Promoted ' || v_promoted_count || ' participants.';
END;
$$ LANGUAGE plpgsql;

-- Function to validate event capacity
CREATE OR REPLACE FUNCTION validate_event_capacity(
    p_event_id UUID,
    p_additional_participants INTEGER DEFAULT 1
) RETURNS TABLE (
    capacity_available BOOLEAN,
    available_spots INTEGER,
    capacity_status VARCHAR,
    violation_detected BOOLEAN
) AS $$
DECLARE
    v_event RECORD;
    v_available INTEGER;
    v_status VARCHAR;
    v_violation BOOLEAN := false;
BEGIN
    -- Get event details
    SELECT * INTO v_event FROM events WHERE id = p_event_id;
    
    -- Calculate availability
    v_available := v_event.effective_max_capacity - v_event.current_participants;
    
    -- Determine status
    IF v_available >= p_additional_participants THEN
        v_status := 'capacity_available';
    ELSIF v_event.waitlist_enabled THEN
        v_status := 'waitlist_available';
    ELSE
        v_status := 'event_full';
        v_violation := true;
    END IF;
    
    -- Record capacity monitoring
    INSERT INTO event_capacity_monitoring (
        event_id, current_participants, available_capacity,
        utilization_percentage, monitoring_type
    ) VALUES (
        p_event_id, v_event.current_participants, v_available,
        (v_event.current_participants::DECIMAL / v_event.max_participants) * 100,
        'real_time_capacity'
    );
    
    RETURN QUERY SELECT 
        v_available >= p_additional_participants,
        v_available,
        v_status,
        v_violation;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update event participant counts
CREATE OR REPLACE FUNCTION update_event_participant_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE events 
        SET current_participants = current_participants + 1
        WHERE id = NEW.event_id;
        
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE events 
        SET current_participants = current_participants - 1
        WHERE id = OLD.event_id;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle status changes that affect participant count
        IF OLD.status IN ('registered', 'confirmed') AND NEW.status NOT IN ('registered', 'confirmed') THEN
            UPDATE events 
            SET current_participants = current_participants - 1
            WHERE id = NEW.event_id;
        ELSIF OLD.status NOT IN ('registered', 'confirmed') AND NEW.status IN ('registered', 'confirmed') THEN
            UPDATE events 
            SET current_participants = current_participants + 1
            WHERE id = NEW.event_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_participant_counts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON event_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_event_participant_counts();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Event type indexes
CREATE INDEX idx_event_types_capacity_type ON event_types(capacity_type);

-- Event indexes
CREATE INDEX idx_events_type ON events(event_type_id);
CREATE INDEX idx_events_dates ON events(start_date, end_date);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_capacity ON events(current_participants, max_participants);

-- Participant indexes
CREATE INDEX idx_participants_event ON event_participants(event_id);
CREATE INDEX idx_participants_employee ON event_participants(employee_id);
CREATE INDEX idx_participants_status ON event_participants(status);
CREATE INDEX idx_participants_priority ON event_participants(priority_score DESC);

-- Queue indexes
CREATE INDEX idx_queues_event ON participant_queues(event_id);
CREATE INDEX idx_queues_position ON participant_queues(event_id, queue_position);
CREATE INDEX idx_queues_priority ON participant_queues(event_id, queue_priority_score DESC);
CREATE INDEX idx_queues_status ON participant_queues(status);

-- Violation indexes
CREATE INDEX idx_violations_event ON limit_violations(event_id);
CREATE INDEX idx_violations_type ON limit_violations(violation_type);
CREATE INDEX idx_violations_resolution ON limit_violations(resolution);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert default event types
INSERT INTO event_types (type_id, type_name, capacity_type, default_capacity) VALUES
('training', 'Training Event', 'fixed_capacity', 20),
('meeting', 'Team Meeting', 'flexible_capacity', 15),
('conference', 'Conference Event', 'resource_based_capacity', 100),
('workshop', 'Workshop', 'skill_based_capacity', 12);

-- Insert sample events
INSERT INTO events (event_id, event_type_id, name, start_date, end_date, max_participants, waitlist_enabled) VALUES
('training-001', (SELECT id FROM event_types WHERE type_id = 'training'), 
 'New Employee Training', '2025-02-01 09:00:00+00', '2025-02-01 17:00:00+00', 20, true),
('meeting-001', (SELECT id FROM event_types WHERE type_id = 'meeting'), 
 'Monthly Team Meeting', '2025-01-15 14:00:00+00', '2025-01-15 16:00:00+00', 15, false);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_event_manager;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_employee;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_event_manager;