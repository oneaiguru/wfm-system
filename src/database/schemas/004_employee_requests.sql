-- =====================================================================================
-- Employee Request Management Schema
-- Module: Employee Requests, Approvals, and Notifications
-- Created for: DATABASE-OPUS Agent
-- Purpose: Handle sick leave, vacations, shift changes with approval workflows
-- BDD Sources: 02-05 (employee requests and approvals)
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- 1. CORE REQUEST TABLES
-- =====================================================================================

-- Main requests table for all request types
CREATE TABLE IF NOT EXISTS requests (
    request_id SERIAL PRIMARY KEY,
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN (
        'sick_leave', 'day_off', 'unscheduled_vacation', 'shift_exchange'
    )),
    employee_id INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'new' CHECK (status IN (
        'new', 'under_review', 'approved', 'rejected', 'cancelled', 'completed'
    )),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_hours DECIMAL(10,2) GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_date + INTERVAL '1 day' - start_date)) / 3600
    ) STORED,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_by INTEGER,
    
    -- Constraints
    CONSTRAINT chk_request_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_future_dates CHECK (
        request_type != 'sick_leave' OR start_date >= CURRENT_DATE - INTERVAL '7 days'
    )
);

-- Indexes for performance
CREATE INDEX idx_requests_employee ON requests(employee_id);
CREATE INDEX idx_requests_status ON requests(status) WHERE status NOT IN ('completed', 'cancelled');
CREATE INDEX idx_requests_type ON requests(request_type);
CREATE INDEX idx_requests_dates ON requests(start_date, end_date);
CREATE INDEX idx_requests_created ON requests(created_at DESC);

-- Request types configuration
CREATE TABLE IF NOT EXISTS request_types (
    type_id SERIAL PRIMARY KEY,
    type_code VARCHAR(50) UNIQUE NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    type_name_ru VARCHAR(100) NOT NULL,
    requires_approval BOOLEAN DEFAULT TRUE,
    max_duration_days INTEGER,
    advance_notice_days INTEGER DEFAULT 0,
    validation_rules JSONB DEFAULT '{}',
    integration_config JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert standard request types
INSERT INTO request_types (type_code, type_name, type_name_ru, requires_approval, max_duration_days, advance_notice_days, integration_config) VALUES
    ('sick_leave', 'Sick Leave', 'Больничный', TRUE, 180, 0, 
     '{"1c_document": "sick_leave", "time_type": "sick", "code": "B"}'),
    ('day_off', 'Day Off', 'Отгул', TRUE, 3, 1,
     '{"1c_document": "time_off", "absence_type": "NV", "code": "НВ"}'),
    ('unscheduled_vacation', 'Unscheduled Vacation', 'Внеплановый отпуск', TRUE, 14, 3,
     '{"1c_document": "vacation", "vacation_type": "OT", "code": "ОТ"}'),
    ('shift_exchange', 'Shift Exchange', 'Обмен сменами', TRUE, 1, 1,
     '{"requires_peer_approval": true, "update_schedule": true}')
ON CONFLICT (type_code) DO NOTHING;

-- Shift exchange specific details
CREATE TABLE IF NOT EXISTS shift_exchanges (
    exchange_id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL UNIQUE REFERENCES requests(request_id) ON DELETE CASCADE,
    original_shift_id INTEGER NOT NULL,
    exchange_date DATE NOT NULL,
    exchange_shift_id INTEGER,
    accepting_employee_id INTEGER,
    exchange_status VARCHAR(50) DEFAULT 'offered' CHECK (exchange_status IN (
        'offered', 'accepted', 'approved', 'rejected'
    )),
    accepted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_exchange_date CHECK (exchange_date >= CURRENT_DATE),
    CONSTRAINT chk_different_employees CHECK (accepting_employee_id IS NULL OR accepting_employee_id != (
        SELECT employee_id FROM requests WHERE request_id = shift_exchanges.request_id
    ))
);

CREATE INDEX idx_shift_exchanges_status ON shift_exchanges(exchange_status) WHERE exchange_status != 'rejected';
CREATE INDEX idx_shift_exchanges_date ON shift_exchanges(exchange_date);

-- =====================================================================================
-- 2. APPROVAL WORKFLOW TABLES
-- =====================================================================================

-- Approval workflow configuration
CREATE TABLE IF NOT EXISTS approval_workflow_config (
    config_id SERIAL PRIMARY KEY,
    request_type VARCHAR(50) NOT NULL,
    approval_level INTEGER NOT NULL CHECK (approval_level > 0),
    approver_role VARCHAR(50) NOT NULL CHECK (approver_role IN (
        'direct_supervisor', 'department_head', 'hr_manager', 'general_manager'
    )),
    auto_approve_conditions JSONB DEFAULT '{}',
    escalation_hours INTEGER DEFAULT 48,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(request_type, approval_level)
);

-- Default approval workflows
INSERT INTO approval_workflow_config (request_type, approval_level, approver_role, auto_approve_conditions) VALUES
    -- Sick leave: supervisor only
    ('sick_leave', 1, 'direct_supervisor', '{"max_days": 3}'),
    
    -- Day off: supervisor, then department head for > 1 day
    ('day_off', 1, 'direct_supervisor', '{"max_days": 1}'),
    ('day_off', 2, 'department_head', '{}'),
    
    -- Vacation: supervisor, department head, HR for > 7 days
    ('unscheduled_vacation', 1, 'direct_supervisor', '{"max_days": 3}'),
    ('unscheduled_vacation', 2, 'department_head', '{"max_days": 7}'),
    ('unscheduled_vacation', 3, 'hr_manager', '{}'),
    
    -- Shift exchange: peer acceptance, then supervisor
    ('shift_exchange', 1, 'direct_supervisor', '{"peer_accepted": true}')
ON CONFLICT (request_type, approval_level) DO NOTHING;

-- Request approvals tracking
CREATE TABLE IF NOT EXISTS request_approvals (
    approval_id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES requests(request_id) ON DELETE CASCADE,
    approver_id INTEGER NOT NULL,
    approval_level INTEGER NOT NULL DEFAULT 1,
    approval_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'escalated', 'auto_approved'
    )),
    approval_date TIMESTAMPTZ,
    rejection_reason TEXT,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    escalated_at TIMESTAMPTZ,
    
    UNIQUE(request_id, approval_level)
);

CREATE INDEX idx_approvals_request ON request_approvals(request_id);
CREATE INDEX idx_approvals_approver ON request_approvals(approver_id) WHERE approval_status = 'pending';
CREATE INDEX idx_approvals_status ON request_approvals(approval_status);
CREATE INDEX idx_approvals_escalation ON request_approvals(created_at) WHERE approval_status = 'pending';

-- Valid status transitions
CREATE TABLE IF NOT EXISTS request_status_transitions (
    transition_id SERIAL PRIMARY KEY,
    request_type VARCHAR(50) NOT NULL,
    from_status VARCHAR(50) NOT NULL,
    to_status VARCHAR(50) NOT NULL,
    allowed_roles VARCHAR[] NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    UNIQUE(request_type, from_status, to_status)
);

-- Insert valid transitions
INSERT INTO request_status_transitions (request_type, from_status, to_status, allowed_roles) VALUES
    -- Common transitions
    ('sick_leave', 'new', 'under_review', ARRAY['supervisor', 'hr_manager']),
    ('sick_leave', 'under_review', 'approved', ARRAY['supervisor', 'hr_manager']),
    ('sick_leave', 'under_review', 'rejected', ARRAY['supervisor', 'hr_manager']),
    ('sick_leave', 'new', 'cancelled', ARRAY['employee', 'supervisor']),
    ('sick_leave', 'approved', 'completed', ARRAY['system']),
    
    -- Similar for other types...
    ('shift_exchange', 'new', 'under_review', ARRAY['peer', 'supervisor']),
    ('shift_exchange', 'under_review', 'approved', ARRAY['supervisor']),
    ('shift_exchange', 'under_review', 'rejected', ARRAY['peer', 'supervisor'])
ON CONFLICT DO NOTHING;

-- =====================================================================================
-- 3. NOTIFICATION SYSTEM
-- =====================================================================================

-- Notification templates
CREATE TABLE IF NOT EXISTS notification_templates (
    template_id SERIAL PRIMARY KEY,
    notification_type VARCHAR(50) UNIQUE NOT NULL,
    title_template VARCHAR(255) NOT NULL,
    message_template TEXT NOT NULL,
    delivery_methods VARCHAR[] DEFAULT ARRAY['in_app'],
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert notification templates
INSERT INTO notification_templates (notification_type, title_template, message_template, priority) VALUES
    ('request_created', 'Новая заявка: {request_type}', 
     'Сотрудник {employee_name} создал заявку на {request_type} с {start_date} по {end_date}', 'normal'),
    
    ('approval_required', 'Требуется согласование', 
     'Заявка #{request_id} от {employee_name} ожидает вашего согласования', 'high'),
    
    ('status_changed', 'Статус заявки изменен', 
     'Ваша заявка #{request_id} {request_type} была {new_status}', 'normal'),
    
    ('shift_exchange_offer', 'Предложение обмена сменой', 
     '{employee_name} предлагает обменяться сменой на {exchange_date}', 'high'),
    
    ('approval_escalated', 'Заявка эскалирована', 
     'Заявка #{request_id} была эскалирована из-за отсутствия решения', 'urgent')
ON CONFLICT (notification_type) DO NOTHING;

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    recipient_id INTEGER NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id INTEGER,
    priority VARCHAR(20) DEFAULT 'normal',
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    delivery_methods VARCHAR[] DEFAULT ARRAY['in_app'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_unread ON notifications(recipient_id, is_read) WHERE NOT is_read;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_expires ON notifications(expires_at) WHERE NOT is_read;

-- =====================================================================================
-- 4. AUDIT AND HISTORY TRACKING
-- =====================================================================================

-- Request history tracking
CREATE TABLE IF NOT EXISTS request_history (
    history_id BIGSERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES requests(request_id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER NOT NULL,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    change_reason TEXT,
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX idx_request_history_request ON request_history(request_id);
CREATE INDEX idx_request_history_timestamp ON request_history(changed_at DESC);
CREATE INDEX idx_request_history_action ON request_history(action);

-- =====================================================================================
-- 5. INTEGRATION MANAGEMENT
-- =====================================================================================

-- Integration queue for external systems
CREATE TABLE IF NOT EXISTS integration_queue (
    queue_id BIGSERIAL PRIMARY KEY,
    integration_type VARCHAR(50) NOT NULL CHECK (integration_type IN (
        '1c_zup', 'schedule_system', 'email_system'
    )),
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    operation VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled'
    )),
    priority INTEGER DEFAULT 5,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    next_retry_at TIMESTAMPTZ,
    error_message TEXT,
    response_data JSONB
);

CREATE INDEX idx_integration_queue_status ON integration_queue(status, scheduled_at) 
    WHERE status IN ('pending', 'processing');
CREATE INDEX idx_integration_queue_created ON integration_queue(created_at);
CREATE INDEX idx_integration_queue_entity ON integration_queue(entity_type, entity_id);

-- =====================================================================================
-- 6. VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- Active requests view
CREATE OR REPLACE VIEW v_active_requests AS
SELECT 
    r.request_id,
    r.request_type,
    rt.type_name,
    rt.type_name_ru,
    r.employee_id,
    r.status,
    r.start_date,
    r.end_date,
    r.duration_hours,
    r.comment,
    r.created_at,
    r.created_by,
    CASE 
        WHEN se.exchange_id IS NOT NULL THEN 
            jsonb_build_object(
                'exchange_date', se.exchange_date,
                'accepting_employee_id', se.accepting_employee_id,
                'exchange_status', se.exchange_status
            )
        ELSE NULL
    END as shift_exchange_details
FROM requests r
JOIN request_types rt ON r.request_type = rt.type_code
LEFT JOIN shift_exchanges se ON r.request_id = se.request_id
WHERE r.status NOT IN ('completed', 'cancelled')
    AND rt.is_active = TRUE;

-- Pending approvals view
CREATE OR REPLACE VIEW v_pending_approvals AS
SELECT 
    ra.approval_id,
    ra.request_id,
    ra.approver_id,
    ra.approval_level,
    r.request_type,
    r.employee_id,
    r.start_date,
    r.end_date,
    r.created_at as request_created_at,
    ra.created_at as approval_created_at,
    EXTRACT(HOURS FROM NOW() - ra.created_at) as pending_hours,
    awc.escalation_hours,
    CASE 
        WHEN EXTRACT(HOURS FROM NOW() - ra.created_at) > awc.escalation_hours 
        THEN TRUE 
        ELSE FALSE 
    END as needs_escalation
FROM request_approvals ra
JOIN requests r ON ra.request_id = r.request_id
JOIN approval_workflow_config awc ON 
    r.request_type = awc.request_type AND 
    ra.approval_level = awc.approval_level
WHERE ra.approval_status = 'pending'
    AND r.status = 'under_review';

-- Employee request summary
CREATE OR REPLACE VIEW v_employee_request_summary AS
SELECT 
    employee_id,
    COUNT(*) FILTER (WHERE status = 'approved' AND request_type = 'sick_leave') as sick_leave_count,
    COUNT(*) FILTER (WHERE status = 'approved' AND request_type = 'day_off') as day_off_count,
    COUNT(*) FILTER (WHERE status = 'approved' AND request_type = 'unscheduled_vacation') as vacation_count,
    COUNT(*) FILTER (WHERE status IN ('new', 'under_review')) as pending_requests,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected_requests,
    SUM(duration_hours) FILTER (WHERE status = 'approved') as total_approved_hours
FROM requests
WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY employee_id;

-- =====================================================================================
-- 7. FUNCTIONS AND PROCEDURES
-- =====================================================================================

-- Function to create a new request with approval workflow
CREATE OR REPLACE FUNCTION create_employee_request(
    p_request_type VARCHAR,
    p_employee_id INTEGER,
    p_start_date DATE,
    p_end_date DATE,
    p_comment TEXT,
    p_created_by INTEGER,
    p_shift_exchange_data JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_request_id INTEGER;
    v_approval_level INTEGER;
    v_approver_id INTEGER;
BEGIN
    -- Validate request type
    IF NOT EXISTS (SELECT 1 FROM request_types WHERE type_code = p_request_type AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Invalid request type: %', p_request_type;
    END IF;
    
    -- Create the request
    INSERT INTO requests (request_type, employee_id, start_date, end_date, comment, created_by)
    VALUES (p_request_type, p_employee_id, p_start_date, p_end_date, p_comment, p_created_by)
    RETURNING request_id INTO v_request_id;
    
    -- Create shift exchange details if applicable
    IF p_request_type = 'shift_exchange' AND p_shift_exchange_data IS NOT NULL THEN
        INSERT INTO shift_exchanges (
            request_id, 
            original_shift_id, 
            exchange_date,
            exchange_shift_id,
            accepting_employee_id
        ) VALUES (
            v_request_id,
            (p_shift_exchange_data->>'original_shift_id')::INTEGER,
            (p_shift_exchange_data->>'exchange_date')::DATE,
            (p_shift_exchange_data->>'exchange_shift_id')::INTEGER,
            (p_shift_exchange_data->>'accepting_employee_id')::INTEGER
        );
    END IF;
    
    -- Initialize approval workflow
    FOR v_approval_level IN 
        SELECT approval_level 
        FROM approval_workflow_config 
        WHERE request_type = p_request_type 
            AND is_active = TRUE 
        ORDER BY approval_level
    LOOP
        -- Get approver based on role (simplified - would need proper role resolution)
        v_approver_id := get_approver_for_employee(p_employee_id, v_approval_level);
        
        INSERT INTO request_approvals (request_id, approver_id, approval_level)
        VALUES (v_request_id, v_approver_id, v_approval_level);
        
        -- Only create first level approval initially
        EXIT;
    END LOOP;
    
    -- Create notifications
    PERFORM create_request_notifications(v_request_id, 'request_created');
    
    -- Add to integration queue if needed
    PERFORM queue_integration_task(v_request_id, 'request', 'create');
    
    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql;

-- Function to approve/reject request
CREATE OR REPLACE FUNCTION process_request_approval(
    p_request_id INTEGER,
    p_approver_id INTEGER,
    p_decision VARCHAR, -- 'approved' or 'rejected'
    p_comments TEXT DEFAULT NULL,
    p_rejection_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_approval_level INTEGER;
    v_next_level INTEGER;
    v_request_type VARCHAR;
    v_new_status VARCHAR;
BEGIN
    -- Get current approval level
    SELECT approval_level, r.request_type 
    INTO v_approval_level, v_request_type
    FROM request_approvals ra
    JOIN requests r ON ra.request_id = r.request_id
    WHERE ra.request_id = p_request_id 
        AND ra.approver_id = p_approver_id 
        AND ra.approval_status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No pending approval found for this approver';
    END IF;
    
    -- Update approval record
    UPDATE request_approvals
    SET approval_status = p_decision,
        approval_date = NOW(),
        comments = p_comments,
        rejection_reason = p_rejection_reason
    WHERE request_id = p_request_id 
        AND approver_id = p_approver_id 
        AND approval_status = 'pending';
    
    -- Determine next action
    IF p_decision = 'rejected' THEN
        v_new_status := 'rejected';
    ELSE
        -- Check if there are more approval levels
        SELECT MIN(approval_level) INTO v_next_level
        FROM approval_workflow_config
        WHERE request_type = v_request_type 
            AND approval_level > v_approval_level 
            AND is_active = TRUE;
        
        IF v_next_level IS NOT NULL THEN
            -- Create next level approval
            INSERT INTO request_approvals (request_id, approver_id, approval_level)
            VALUES (p_request_id, get_approver_for_level(p_request_id, v_next_level), v_next_level);
            
            v_new_status := 'under_review';
        ELSE
            v_new_status := 'approved';
        END IF;
    END IF;
    
    -- Update request status
    UPDATE requests
    SET status = v_new_status,
        updated_at = NOW(),
        updated_by = p_approver_id
    WHERE request_id = p_request_id;
    
    -- Create notifications
    PERFORM create_request_notifications(p_request_id, 'status_changed');
    
    -- Queue integration tasks if approved
    IF v_new_status = 'approved' THEN
        PERFORM queue_integration_task(p_request_id, 'request', 'approved');
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to handle notification creation
CREATE OR REPLACE FUNCTION create_request_notifications(
    p_request_id INTEGER,
    p_notification_type VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_template RECORD;
    v_request RECORD;
    v_recipient_id INTEGER;
    v_title VARCHAR;
    v_message TEXT;
BEGIN
    -- Get template
    SELECT * INTO v_template
    FROM notification_templates
    WHERE notification_type = p_notification_type
        AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Get request details
    SELECT r.*, rt.type_name_ru 
    INTO v_request
    FROM requests r
    JOIN request_types rt ON r.request_type = rt.type_code
    WHERE r.request_id = p_request_id;
    
    -- Determine recipients based on notification type
    CASE p_notification_type
        WHEN 'request_created' THEN
            -- Notify approvers
            FOR v_recipient_id IN 
                SELECT approver_id 
                FROM request_approvals 
                WHERE request_id = p_request_id 
                    AND approval_status = 'pending'
            LOOP
                -- Build notification (simplified - would use proper template engine)
                v_title := REPLACE(v_template.title_template, '{request_type}', v_request.type_name_ru);
                v_message := REPLACE(v_template.message_template, '{request_type}', v_request.type_name_ru);
                
                INSERT INTO notifications (
                    recipient_id, notification_type, title, message,
                    related_entity_type, related_entity_id, priority
                ) VALUES (
                    v_recipient_id, p_notification_type, v_title, v_message,
                    'request', p_request_id, v_template.priority
                );
            END LOOP;
            
        WHEN 'status_changed' THEN
            -- Notify employee
            v_title := REPLACE(v_template.title_template, '{request_id}', p_request_id::TEXT);
            v_message := REPLACE(v_template.message_template, '{new_status}', v_request.status);
            
            INSERT INTO notifications (
                recipient_id, notification_type, title, message,
                related_entity_type, related_entity_id, priority
            ) VALUES (
                v_request.employee_id, p_notification_type, v_title, v_message,
                'request', p_request_id, v_template.priority
            );
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get approver (simplified)
CREATE OR REPLACE FUNCTION get_approver_for_employee(
    p_employee_id INTEGER,
    p_approval_level INTEGER
) RETURNS INTEGER AS $$
BEGIN
    -- This would implement actual org structure lookup
    -- For now, return a dummy supervisor ID
    RETURN 1000 + p_approval_level;
END;
$$ LANGUAGE plpgsql;

-- Helper function to queue integration tasks
CREATE OR REPLACE FUNCTION queue_integration_task(
    p_entity_id INTEGER,
    p_entity_type VARCHAR,
    p_operation VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_request RECORD;
    v_integration_config JSONB;
BEGIN
    -- Get request and integration config
    SELECT r.*, rt.integration_config 
    INTO v_request
    FROM requests r
    JOIN request_types rt ON r.request_type = rt.type_code
    WHERE r.request_id = p_entity_id;
    
    v_integration_config := v_request.integration_config;
    
    -- Queue 1C ZUP integration if configured
    IF v_integration_config ? '1c_document' THEN
        INSERT INTO integration_queue (
            integration_type, entity_type, entity_id, operation, payload
        ) VALUES (
            '1c_zup', p_entity_type, p_entity_id, p_operation,
            jsonb_build_object(
                'document_type', v_integration_config->>'1c_document',
                'employee_id', v_request.employee_id,
                'start_date', v_request.start_date,
                'end_date', v_request.end_date,
                'request_data', row_to_json(v_request)
            )
        );
    END IF;
    
    -- Queue schedule update if needed
    IF v_request.status = 'approved' AND v_request.request_type != 'sick_leave' THEN
        INSERT INTO integration_queue (
            integration_type, entity_type, entity_id, operation, payload
        ) VALUES (
            'schedule_system', p_entity_type, p_entity_id, 'update_schedule',
            jsonb_build_object(
                'employee_id', v_request.employee_id,
                'dates', jsonb_build_array(v_request.start_date, v_request.end_date),
                'absence_type', v_integration_config->>'code'
            )
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 8. TRIGGERS
-- =====================================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_requests_updated_at 
    BEFORE UPDATE ON requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create audit history on changes
CREATE OR REPLACE FUNCTION create_request_history()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO request_history (
        request_id, action, old_values, new_values, changed_by
    ) VALUES (
        NEW.request_id,
        CASE 
            WHEN TG_OP = 'INSERT' THEN 'created'
            WHEN OLD.status != NEW.status THEN 'status_changed'
            ELSE 'updated'
        END,
        CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
        to_jsonb(NEW),
        COALESCE(NEW.updated_by, NEW.created_by)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER requests_audit_trail 
    AFTER INSERT OR UPDATE ON requests
    FOR EACH ROW EXECUTE FUNCTION create_request_history();

-- Auto-escalate overdue approvals
CREATE OR REPLACE FUNCTION escalate_overdue_approvals() RETURNS void AS $$
DECLARE
    v_approval RECORD;
BEGIN
    FOR v_approval IN 
        SELECT ra.*, awc.escalation_hours
        FROM request_approvals ra
        JOIN requests r ON ra.request_id = r.request_id
        JOIN approval_workflow_config awc ON 
            r.request_type = awc.request_type AND 
            ra.approval_level = awc.approval_level
        WHERE ra.approval_status = 'pending'
            AND r.status = 'under_review'
            AND EXTRACT(HOURS FROM NOW() - ra.created_at) > awc.escalation_hours
    LOOP
        -- Mark as escalated
        UPDATE request_approvals
        SET approval_status = 'escalated',
            escalated_at = NOW()
        WHERE approval_id = v_approval.approval_id;
        
        -- Create escalation notification
        PERFORM create_request_notifications(v_approval.request_id, 'approval_escalated');
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. PERMISSIONS
-- =====================================================================================

-- Grant appropriate permissions (adjust users as needed)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_app_user;

-- =====================================================================================
-- 10. INITIAL DATA AND CONFIGURATION
-- =====================================================================================

-- Add comments for documentation
COMMENT ON TABLE requests IS 'Main table for all employee requests including sick leave, vacations, and shift changes';
COMMENT ON TABLE shift_exchanges IS 'Specific details for shift exchange requests between employees';
COMMENT ON TABLE request_approvals IS 'Tracks multi-level approval workflow for requests';
COMMENT ON TABLE notifications IS 'System notifications for request status changes and required actions';
COMMENT ON TABLE integration_queue IS 'Queue for integrating with external systems like 1C ZUP';

-- Create scheduled job for escalations (using pg_cron or similar)
-- SELECT cron.schedule('escalate-approvals', '0 * * * *', 'SELECT escalate_overdue_approvals();');

COMMIT;

-- =====================================================================================
-- USAGE EXAMPLES
-- =====================================================================================

/*
-- Create a sick leave request
SELECT create_employee_request(
    'sick_leave',
    123, -- employee_id
    '2025-02-15',
    '2025-02-17',
    'Flu symptoms',
    123 -- created_by
);

-- Create a shift exchange request
SELECT create_employee_request(
    'shift_exchange',
    456, -- employee_id
    '2025-02-20',
    '2025-02-20',
    'Need to attend appointment',
    456, -- created_by
    jsonb_build_object(
        'original_shift_id', 789,
        'exchange_date', '2025-02-20',
        'accepting_employee_id', 321
    )
);

-- Approve a request
SELECT process_request_approval(
    1, -- request_id
    1001, -- approver_id
    'approved',
    'Approved per policy'
);

-- View pending approvals for a supervisor
SELECT * FROM v_pending_approvals WHERE approver_id = 1001;

-- Check employee request summary
SELECT * FROM v_employee_request_summary WHERE employee_id = 123;
*/