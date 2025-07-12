-- =============================================================================
-- 047_cross_system_integration.sql
-- EXACT BDD Implementation: Cross-System Data Integration and Consistency
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 22-cross-system-integration.feature (180+ lines)
-- Purpose: Seamless data flow between 1C ZUP and ARGUS WFM with consistency validation
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. EMPLOYEE LIFECYCLE CROSS-SYSTEM TRACKING
-- =============================================================================

-- New employee onboarding from BDD lines 18-37
CREATE TABLE cross_system_employee_lifecycle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Employee identification
    employee_external_id VARCHAR(100) NOT NULL, -- 1C ZUP ID
    personnel_number VARCHAR(50) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    
    -- Lifecycle events from BDD lines 20-26
    lifecycle_event VARCHAR(30) NOT NULL CHECK (lifecycle_event IN (
        'onboarding', 'transfer', 'promotion', 'termination', 'reactivation'
    )),
    
    -- Employee details from BDD lines 21-26
    department VARCHAR(200),
    position VARCHAR(200),
    start_date DATE,
    end_date DATE,
    vacation_entitlement INTEGER, -- days/year
    
    -- Cross-system synchronization
    sync_from_system VARCHAR(20) NOT NULL CHECK (sync_from_system IN ('1c_zup', 'argus_wfm')),
    sync_to_system VARCHAR(20) NOT NULL CHECK (sync_to_system IN ('1c_zup', 'argus_wfm')),
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'partial'
    )),
    
    -- Data consistency validation from BDD lines 28-36
    wfm_employee_status VARCHAR(20),
    wfm_department VARCHAR(200),
    wfm_position VARCHAR(200),
    wfm_vacation_balance DECIMAL(5,2),
    zup_vacation_balance DECIMAL(5,2),
    
    data_consistency_validated BOOLEAN DEFAULT false,
    consistency_issues JSONB DEFAULT '[]',
    
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_completed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_employee_event UNIQUE(employee_external_id, lifecycle_event, event_timestamp)
);

-- Employee termination tracking from BDD lines 38-46
CREATE TABLE cross_system_employee_termination (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    employee_external_id VARCHAR(100) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    termination_date DATE NOT NULL,
    
    -- Cross-system status
    zup_termination_processed BOOLEAN DEFAULT false,
    wfm_termination_processed BOOLEAN DEFAULT false,
    
    -- Report visibility rules from BDD lines 44-46
    active_in_reports_before_termination BOOLEAN DEFAULT true,
    inactive_in_reports_after_termination BOOLEAN DEFAULT true,
    historical_reports_accessible BOOLEAN DEFAULT true,
    
    termination_reason VARCHAR(200),
    
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. SCHEDULE INTEGRATION MANAGEMENT
-- =============================================================================

-- Schedule upload and document creation from BDD lines 52-67
CREATE TABLE cross_system_schedule_integration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Schedule identification
    schedule_integration_id VARCHAR(50) NOT NULL UNIQUE,
    employee_external_id VARCHAR(100) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    
    -- Schedule details from BDD lines 54-56
    schedule_period_start DATE NOT NULL,
    schedule_period_end DATE NOT NULL,
    shift_details JSONB NOT NULL, -- Pattern details
    
    -- Upload process tracking from BDD lines 57-66
    wfm_schedule_created BOOLEAN DEFAULT false,
    zup_upload_initiated BOOLEAN DEFAULT false,
    zup_documents_created BOOLEAN DEFAULT false,
    
    upload_api_endpoint VARCHAR(100) DEFAULT 'sendSchedule',
    upload_status VARCHAR(20) DEFAULT 'pending',
    
    -- Document creation results
    documents_created_count INTEGER DEFAULT 0,
    time_types_assigned JSONB, -- {"monday": "I", "tuesday": "I"}
    
    -- Report generation from BDD lines 64-66
    wfm_report_generated BOOLEAN DEFAULT false,
    familiarization_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMP WITH TIME ZONE
);

-- Schedule upload error handling from BDD lines 68-77
CREATE TABLE schedule_upload_error_recovery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    schedule_integration_id VARCHAR(50) REFERENCES cross_system_schedule_integration(schedule_integration_id),
    
    -- Error details from BDD lines 71-73
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    api_response_code INTEGER,
    
    -- Recovery process from BDD lines 73-77
    retry_queued BOOLEAN DEFAULT false,
    retry_attempts INTEGER DEFAULT 0,
    max_retry_attempts INTEGER DEFAULT 3,
    
    -- Resolution tracking
    resolved BOOLEAN DEFAULT false,
    resolution_method VARCHAR(100),
    resolution_timestamp TIMESTAMP WITH TIME ZONE,
    
    error_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. TIME TRACKING INTEGRATION
-- =============================================================================

-- Actual time reporting from BDD lines 83-95
CREATE TABLE cross_system_time_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Time tracking identification
    time_tracking_id VARCHAR(50) NOT NULL UNIQUE,
    employee_external_id VARCHAR(100) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    work_date DATE NOT NULL,
    
    -- Planned vs actual time from BDD lines 85-86
    planned_start_time TIME NOT NULL,
    planned_end_time TIME NOT NULL,
    actual_start_time TIME,
    actual_end_time TIME,
    
    -- Time variance analysis
    lateness_minutes INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN actual_start_time IS NOT NULL AND actual_start_time > planned_start_time 
            THEN EXTRACT(EPOCH FROM (actual_start_time - planned_start_time))/60
            ELSE 0 
        END
    ) STORED,
    
    overtime_minutes INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN actual_end_time IS NOT NULL AND actual_end_time > planned_end_time 
            THEN EXTRACT(EPOCH FROM (actual_end_time - planned_end_time))/60
            ELSE 0 
        END
    ) STORED,
    
    -- API submission from BDD line 87
    submitted_via_api VARCHAR(50) DEFAULT 'sendFactWorkTime',
    submission_status VARCHAR(20) DEFAULT 'pending',
    
    -- 1C ZUP document creation from BDD lines 88-91
    zup_absence_document_created BOOLEAN DEFAULT false,
    zup_overtime_document_created BOOLEAN DEFAULT false,
    
    -- Document details
    absence_document_type VARCHAR(50), -- NV (Absence)
    absence_duration_minutes INTEGER,
    overtime_document_type VARCHAR(50), -- C (Overtime)
    overtime_duration_minutes INTEGER,
    
    -- Report integration from BDD lines 92-95
    wfm_lateness_report_updated BOOLEAN DEFAULT false,
    zup_timesheet_data_updated BOOLEAN DEFAULT false,
    
    tracked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 4. DATA CONSISTENCY VALIDATION
-- =============================================================================

-- Cross-system data consistency checks
CREATE TABLE cross_system_data_consistency (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Consistency check configuration
    check_type VARCHAR(50) NOT NULL CHECK (check_type IN (
        'employee_data', 'schedule_data', 'vacation_balance', 'time_tracking', 'document_sync'
    )),
    
    -- Systems involved
    primary_system VARCHAR(20) NOT NULL CHECK (primary_system IN ('1c_zup', 'argus_wfm')),
    secondary_system VARCHAR(20) NOT NULL CHECK (secondary_system IN ('1c_zup', 'argus_wfm')),
    
    -- Check parameters
    check_period_start DATE,
    check_period_end DATE,
    entity_identifier VARCHAR(100), -- Employee ID, Schedule ID, etc.
    
    -- Consistency results
    consistency_status VARCHAR(20) DEFAULT 'pending' CHECK (consistency_status IN (
        'pending', 'consistent', 'inconsistent', 'partial', 'error'
    )),
    
    discrepancies_found JSONB DEFAULT '[]',
    discrepancy_count INTEGER DEFAULT 0,
    
    -- Primary system data
    primary_system_data JSONB,
    primary_system_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Secondary system data
    secondary_system_data JSONB,
    secondary_system_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Resolution tracking
    auto_resolution_attempted BOOLEAN DEFAULT false,
    manual_intervention_required BOOLEAN DEFAULT false,
    resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    
    check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_timestamp TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 5. INTEGRATION MONITORING AND HEALTH
-- =============================================================================

-- Cross-system integration health monitoring
CREATE TABLE cross_system_integration_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    health_check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- System availability
    zup_system_available BOOLEAN NOT NULL,
    wfm_system_available BOOLEAN NOT NULL,
    integration_services_available BOOLEAN NOT NULL,
    
    -- API health
    zup_api_response_time_ms INTEGER,
    wfm_api_response_time_ms INTEGER,
    api_error_rate_24h DECIMAL(5,2),
    
    -- Data flow health
    employee_sync_success_rate_24h DECIMAL(5,2),
    schedule_upload_success_rate_24h DECIMAL(5,2),
    time_tracking_sync_success_rate_24h DECIMAL(5,2),
    
    -- Consistency health
    data_consistency_score DECIMAL(5,2), -- Percentage of consistent data
    unresolved_discrepancies_count INTEGER,
    
    -- Performance metrics
    avg_sync_latency_seconds INTEGER,
    pending_operations_count INTEGER,
    
    overall_health_status VARCHAR(20) CHECK (overall_health_status IN (
        'healthy', 'degraded', 'unhealthy', 'critical'
    ))
);

-- =============================================================================
-- 6. INTEGRATION AUDIT TRAIL
-- =============================================================================

-- Comprehensive audit trail for cross-system operations
CREATE TABLE cross_system_audit_trail (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Operation identification
    operation_id VARCHAR(50) NOT NULL,
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN (
        'employee_sync', 'schedule_upload', 'time_tracking_submit', 
        'data_validation', 'error_recovery', 'manual_intervention'
    )),
    
    -- Systems involved
    source_system VARCHAR(20) NOT NULL,
    target_system VARCHAR(20) NOT NULL,
    
    -- Operation details
    entity_type VARCHAR(50), -- employee, schedule, timesheet
    entity_identifier VARCHAR(100),
    
    -- Data payload
    request_data JSONB,
    response_data JSONB,
    
    -- Execution details
    operation_status VARCHAR(20) NOT NULL,
    execution_time_ms INTEGER,
    
    -- User context
    initiated_by VARCHAR(100), -- User ID or system process
    user_role VARCHAR(50),
    
    -- Error handling
    error_occurred BOOLEAN DEFAULT false,
    error_message TEXT,
    error_code VARCHAR(20),
    
    operation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate cross-system data consistency
CREATE OR REPLACE FUNCTION validate_cross_system_consistency(
    p_check_type VARCHAR,
    p_entity_id VARCHAR,
    p_primary_system VARCHAR,
    p_secondary_system VARCHAR
) RETURNS TABLE (
    is_consistent BOOLEAN,
    discrepancies JSONB,
    resolution_required BOOLEAN
) AS $$
DECLARE
    v_primary_data JSONB;
    v_secondary_data JSONB;
    v_discrepancies JSONB := '[]'::jsonb;
    v_consistent BOOLEAN := true;
BEGIN
    -- Get data from both systems (simplified example)
    SELECT primary_system_data, secondary_system_data 
    INTO v_primary_data, v_secondary_data
    FROM cross_system_data_consistency
    WHERE check_type = p_check_type 
    AND entity_identifier = p_entity_id
    ORDER BY check_timestamp DESC
    LIMIT 1;
    
    -- Compare key fields based on check type
    IF p_check_type = 'employee_data' THEN
        -- Compare employee fields
        IF (v_primary_data->>'name') != (v_secondary_data->>'name') THEN
            v_consistent := false;
            v_discrepancies := v_discrepancies || jsonb_build_object(
                'field', 'name',
                'primary_value', v_primary_data->>'name',
                'secondary_value', v_secondary_data->>'name'
            );
        END IF;
    END IF;
    
    RETURN QUERY
    SELECT 
        v_consistent,
        v_discrepancies,
        NOT v_consistent AS resolution_required;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate integration health score
CREATE OR REPLACE FUNCTION calculate_integration_health_score()
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_availability_score DECIMAL(5,2);
    v_performance_score DECIMAL(5,2);
    v_consistency_score DECIMAL(5,2);
    v_overall_score DECIMAL(5,2);
BEGIN
    -- Get latest health metrics
    SELECT 
        CASE 
            WHEN zup_system_available AND wfm_system_available AND integration_services_available 
            THEN 100.0 
            ELSE 0.0 
        END,
        CASE 
            WHEN api_error_rate_24h < 1.0 THEN 100.0
            WHEN api_error_rate_24h < 5.0 THEN 80.0
            ELSE 50.0
        END,
        COALESCE(data_consistency_score, 0.0)
    INTO v_availability_score, v_performance_score, v_consistency_score
    FROM cross_system_integration_health
    ORDER BY health_check_timestamp DESC
    LIMIT 1;
    
    -- Calculate weighted average
    v_overall_score := (
        v_availability_score * 0.4 + 
        v_performance_score * 0.3 + 
        v_consistency_score * 0.3
    );
    
    RETURN v_overall_score;
END;
$$ LANGUAGE plpgsql;

-- Function to process time tracking discrepancies
CREATE OR REPLACE FUNCTION process_time_tracking_discrepancies(
    p_employee_id VARCHAR,
    p_work_date DATE,
    p_lateness_minutes INTEGER,
    p_overtime_minutes INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_documents_to_create JSONB := '[]'::jsonb;
BEGIN
    -- Check for lateness (NV - Absence)
    IF p_lateness_minutes > 0 THEN
        v_documents_to_create := v_documents_to_create || jsonb_build_object(
            'type', 'NV',
            'description', 'Absence',
            'duration_minutes', p_lateness_minutes,
            'document_type', 'Absence document'
        );
    END IF;
    
    -- Check for overtime (C - Overtime)
    IF p_overtime_minutes > 0 THEN
        v_documents_to_create := v_documents_to_create || jsonb_build_object(
            'type', 'C',
            'description', 'Overtime',
            'duration_minutes', p_overtime_minutes,
            'document_type', 'Overtime work document'
        );
    END IF;
    
    RETURN v_documents_to_create;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to auto-calculate time variances
CREATE OR REPLACE FUNCTION calculate_time_variances()
RETURNS TRIGGER AS $$
BEGIN
    -- Update related reports when time tracking data changes
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Mark WFM lateness report for update if there's lateness
        IF NEW.lateness_minutes > 0 THEN
            NEW.wfm_lateness_report_updated := false; -- Trigger report update
        END IF;
        
        -- Mark ZUP timesheet for update if there are time variances
        IF NEW.lateness_minutes > 0 OR NEW.overtime_minutes > 0 THEN
            NEW.zup_timesheet_data_updated := false; -- Trigger timesheet update
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_time_variances_trigger
    BEFORE INSERT OR UPDATE ON cross_system_time_tracking
    FOR EACH ROW
    EXECUTE FUNCTION calculate_time_variances();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Employee lifecycle indexes
CREATE INDEX idx_employee_lifecycle_external_id ON cross_system_employee_lifecycle(employee_external_id);
CREATE INDEX idx_employee_lifecycle_event ON cross_system_employee_lifecycle(lifecycle_event);
CREATE INDEX idx_employee_lifecycle_sync_status ON cross_system_employee_lifecycle(sync_status);

-- Schedule integration indexes
CREATE INDEX idx_schedule_integration_employee ON cross_system_schedule_integration(employee_external_id);
CREATE INDEX idx_schedule_integration_period ON cross_system_schedule_integration(schedule_period_start, schedule_period_end);
CREATE INDEX idx_schedule_integration_status ON cross_system_schedule_integration(upload_status);

-- Time tracking indexes
CREATE INDEX idx_time_tracking_employee_date ON cross_system_time_tracking(employee_external_id, work_date);
CREATE INDEX idx_time_tracking_lateness ON cross_system_time_tracking(lateness_minutes) WHERE lateness_minutes > 0;
CREATE INDEX idx_time_tracking_overtime ON cross_system_time_tracking(overtime_minutes) WHERE overtime_minutes > 0;

-- Data consistency indexes
CREATE INDEX idx_data_consistency_type ON cross_system_data_consistency(check_type);
CREATE INDEX idx_data_consistency_status ON cross_system_data_consistency(consistency_status);
CREATE INDEX idx_data_consistency_entity ON cross_system_data_consistency(entity_identifier);

-- Audit trail indexes
CREATE INDEX idx_audit_trail_operation_id ON cross_system_audit_trail(operation_id);
CREATE INDEX idx_audit_trail_timestamp ON cross_system_audit_trail(operation_timestamp DESC);
CREATE INDEX idx_audit_trail_entity ON cross_system_audit_trail(entity_type, entity_identifier);

-- =============================================================================
-- INITIAL DATA AND CONFIGURATION
-- =============================================================================

-- Insert default consistency check configurations
INSERT INTO cross_system_data_consistency (check_type, primary_system, secondary_system, consistency_status) VALUES
('employee_data', '1c_zup', 'argus_wfm', 'pending'),
('vacation_balance', '1c_zup', 'argus_wfm', 'pending'),
('schedule_data', 'argus_wfm', '1c_zup', 'pending'),
('time_tracking', 'argus_wfm', '1c_zup', 'pending');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_integration_admin;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_integration_monitor;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_integration_admin;