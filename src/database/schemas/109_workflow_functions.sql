-- =====================================================================================
-- Schema 109: Workflow Engine Functions and Procedures
-- =====================================================================================
-- Part 4/5: Core workflow engine functions for state transitions, escalations, 
-- and performance calculations
-- =====================================================================================

-- Function to start a new workflow instance
CREATE OR REPLACE FUNCTION start_workflow_instance(
    p_workflow_name VARCHAR(100),
    p_requester_id INTEGER,
    p_requester_name VARCHAR(100),
    p_request_data JSONB,
    p_priority INTEGER DEFAULT 100,
    p_business_impact VARCHAR(20) DEFAULT 'medium',
    p_urgency VARCHAR(20) DEFAULT 'medium'
)
RETURNS INTEGER AS $$
DECLARE
    v_workflow_id INTEGER;
    v_initial_state_id INTEGER;
    v_initial_state_key VARCHAR(50);
    v_instance_id INTEGER;
    v_instance_key VARCHAR(100);
BEGIN
    -- Get workflow definition
    SELECT id INTO v_workflow_id
    FROM workflow_definitions 
    WHERE workflow_name = p_workflow_name AND is_active = true;
    
    IF v_workflow_id IS NULL THEN
        RAISE EXCEPTION 'Workflow % not found or inactive', p_workflow_name;
    END IF;
    
    -- Get initial state
    SELECT id, state_key INTO v_initial_state_id, v_initial_state_key
    FROM workflow_states 
    WHERE workflow_id = v_workflow_id AND state_type = 'initial' AND is_active = true
    LIMIT 1;
    
    IF v_initial_state_id IS NULL THEN
        RAISE EXCEPTION 'No initial state found for workflow %', p_workflow_name;
    END IF;
    
    -- Generate unique instance key
    v_instance_key := UPPER(LEFT(p_workflow_name, 3)) || '-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || 
                      LPAD(nextval('workflow_instances_id_seq')::TEXT, 6, '0');
    
    -- Create workflow instance
    INSERT INTO workflow_instances (
        workflow_id, instance_key, request_type, requester_id, requester_name,
        current_state_id, current_state_key, process_data, priority, 
        business_impact, urgency, status
    ) VALUES (
        v_workflow_id, v_instance_key, p_workflow_name, p_requester_id, p_requester_name,
        v_initial_state_id, v_initial_state_key, p_request_data, p_priority,
        p_business_impact, p_urgency, 'active'
    ) RETURNING id INTO v_instance_id;
    
    -- Log initial state in history
    INSERT INTO workflow_execution_history (
        instance_id, to_state_id, actor_id, actor_name, action_type,
        action_description_ru, data_after
    ) VALUES (
        v_instance_id, v_initial_state_id, p_requester_id, p_requester_name,
        'transition', 'Создание экземпляра рабочего процесса', p_request_data
    );
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function to execute workflow transition
CREATE OR REPLACE FUNCTION execute_workflow_transition(
    p_instance_id INTEGER,
    p_transition_key VARCHAR(50),
    p_actor_id INTEGER,
    p_actor_name VARCHAR(100),
    p_actor_role VARCHAR(50),
    p_decision_reason TEXT DEFAULT NULL,
    p_comments TEXT DEFAULT NULL,
    p_data_changes JSONB DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_instance RECORD;
    v_transition RECORD;
    v_from_state_id INTEGER;
    v_to_state_id INTEGER;
    v_new_state_key VARCHAR(50);
    v_processing_time INTEGER;
    v_start_time TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Get current instance state
    SELECT * INTO v_instance
    FROM workflow_instances 
    WHERE id = p_instance_id AND status = 'active';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active workflow instance % not found', p_instance_id;
    END IF;
    
    v_from_state_id := v_instance.current_state_id;
    
    -- Get valid transition
    SELECT wt.*, ws_to.state_key, ws_to.state_type
    INTO v_transition
    FROM workflow_transitions wt
    JOIN workflow_states ws_to ON wt.to_state_id = ws_to.id
    WHERE wt.workflow_id = v_instance.workflow_id 
      AND wt.from_state_id = v_from_state_id
      AND wt.transition_key = p_transition_key
      AND wt.is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid transition % from state %', p_transition_key, v_instance.current_state_key;
    END IF;
    
    v_to_state_id := v_transition.to_state_id;
    v_new_state_key := v_transition.state_key;
    
    -- Check if actor has required role (simplified check)
    -- In production, this would integrate with a proper RBAC system
    
    -- Update instance state
    UPDATE workflow_instances SET
        current_state_id = v_to_state_id,
        current_state_key = v_new_state_key,
        updated_at = CURRENT_TIMESTAMP,
        process_data = process_data || p_data_changes,
        -- Mark as completed if final state
        status = CASE WHEN v_transition.state_type = 'final' THEN 'completed' ELSE status END,
        completed_at = CASE WHEN v_transition.state_type = 'final' THEN CURRENT_TIMESTAMP ELSE completed_at END,
        final_decision = CASE WHEN v_transition.state_type = 'final' THEN p_transition_key ELSE final_decision END,
        final_decision_reason = CASE WHEN v_transition.state_type = 'final' THEN p_decision_reason ELSE final_decision_reason END,
        final_decision_by = CASE WHEN v_transition.state_type = 'final' THEN p_actor_id ELSE final_decision_by END,
        final_decision_at = CASE WHEN v_transition.state_type = 'final' THEN CURRENT_TIMESTAMP ELSE final_decision_at END
    WHERE id = p_instance_id;
    
    -- Calculate processing time for this step
    v_processing_time := EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time));
    
    -- Log transition in history
    INSERT INTO workflow_execution_history (
        instance_id, from_state_id, to_state_id, transition_id, transition_key,
        actor_id, actor_name, actor_role, action_type, action_description_ru,
        decision, decision_reason, comments, data_changes, 
        processing_time_seconds
    ) VALUES (
        p_instance_id, v_from_state_id, v_to_state_id, v_transition.id, p_transition_key,
        p_actor_id, p_actor_name, p_actor_role, 'transition', v_transition.transition_name_ru,
        p_transition_key, p_decision_reason, p_comments, p_data_changes,
        v_processing_time
    );
    
    -- Execute transition actions (notifications, assignments, etc.)
    PERFORM execute_transition_actions(p_instance_id, v_transition.actions);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to execute transition actions (simplified implementation)
CREATE OR REPLACE FUNCTION execute_transition_actions(
    p_instance_id INTEGER,
    p_actions JSONB
)
RETURNS VOID AS $$
DECLARE
    v_action_key TEXT;
    v_action_value JSONB;
BEGIN
    -- Process each action defined in the transition
    FOR v_action_key, v_action_value IN SELECT * FROM jsonb_each(p_actions)
    LOOP
        CASE v_action_key
            WHEN 'send_notification' THEN
                -- Log notification action (in production, integrate with notification service)
                INSERT INTO workflow_execution_history (
                    instance_id, actor_id, actor_name, action_type, action_description_ru
                ) VALUES (
                    p_instance_id, 0, 'System', 'notification', 'Отправлено уведомление'
                );
                
            WHEN 'assign_to_supervisor' THEN
                -- Create assignment record
                INSERT INTO workflow_assignments (
                    instance_id, assignee_id, assignee_name, assignee_role,
                    assignment_type, assigned_by
                ) VALUES (
                    p_instance_id, 0, 'Supervisor', 'supervisor', 'approval', 0
                );
                
            WHEN 'assign_to_hr' THEN
                -- Create HR assignment
                INSERT INTO workflow_assignments (
                    instance_id, assignee_id, assignee_name, assignee_role,
                    assignment_type, assigned_by
                ) VALUES (
                    p_instance_id, 0, 'HR Specialist', 'hr_specialist', 'approval', 0
                );
                
            WHEN 'update_calendar' THEN
                -- Log calendar update action
                INSERT INTO workflow_execution_history (
                    instance_id, actor_id, actor_name, action_type, action_description_ru
                ) VALUES (
                    p_instance_id, 0, 'System', 'data_update', 'Обновлен календарь'
                );
                
            ELSE
                -- Log unknown action
                INSERT INTO workflow_execution_history (
                    instance_id, actor_id, actor_name, action_type, action_description_ru
                ) VALUES (
                    p_instance_id, 0, 'System', 'data_update', 'Выполнено действие: ' || v_action_key
                );
        END CASE;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to check for workflow escalations
CREATE OR REPLACE FUNCTION check_workflow_escalations()
RETURNS INTEGER AS $$
DECLARE
    v_escalation_count INTEGER := 0;
    v_instance RECORD;
    v_escalation RECORD;
    v_timeout_minutes INTEGER;
    v_time_in_state INTERVAL;
BEGIN
    -- Check all active instances for potential escalations
    FOR v_instance IN 
        SELECT wi.*, ws.state_key
        FROM workflow_instances wi
        JOIN workflow_states ws ON wi.current_state_id = ws.id
        WHERE wi.status = 'active'
          AND wi.escalated_at IS NULL
    LOOP
        -- Check escalation rules for this workflow and state
        FOR v_escalation IN
            SELECT er.*
            FROM escalation_rules er
            WHERE er.workflow_id = v_instance.workflow_id
              AND (er.state_id IS NULL OR er.state_id = v_instance.current_state_id)
              AND er.is_active = true
              AND er.trigger_type = 'time_based'
              AND er.timeout_minutes IS NOT NULL
            ORDER BY er.priority
        LOOP
            -- Calculate time in current state
            SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - wi.updated_at)) / 60
            INTO v_timeout_minutes
            FROM workflow_instances wi
            WHERE wi.id = v_instance.id;
            
            -- Check if escalation is needed
            IF v_timeout_minutes >= v_escalation.timeout_minutes THEN
                -- Execute escalation
                PERFORM execute_escalation(v_instance.id, v_escalation.id);
                v_escalation_count := v_escalation_count + 1;
                
                -- Mark instance as escalated
                UPDATE workflow_instances 
                SET escalated_at = CURRENT_TIMESTAMP,
                    escalation_count = escalation_count + 1
                WHERE id = v_instance.id;
                
                -- Exit loop after first applicable escalation
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN v_escalation_count;
END;
$$ LANGUAGE plpgsql;

-- Function to execute escalation actions
CREATE OR REPLACE FUNCTION execute_escalation(
    p_instance_id INTEGER,
    p_escalation_rule_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_escalation RECORD;
    v_instance RECORD;
BEGIN
    -- Get escalation rule details
    SELECT * INTO v_escalation
    FROM escalation_rules
    WHERE id = p_escalation_rule_id;
    
    -- Get instance details
    SELECT * INTO v_instance
    FROM workflow_instances
    WHERE id = p_instance_id;
    
    -- Log escalation in history
    INSERT INTO workflow_execution_history (
        instance_id, actor_id, actor_name, action_type, action_description_ru,
        comments
    ) VALUES (
        p_instance_id, 0, 'System', 'escalation', 
        'Эскалация: ' || v_escalation.escalation_name_ru,
        'Превышено время ожидания: ' || v_escalation.timeout_minutes || ' минут'
    );
    
    -- Create escalation assignment if specified in actions
    IF v_escalation.escalation_actions ? 'escalate_to' THEN
        INSERT INTO workflow_assignments (
            instance_id, assignee_id, assignee_name, assignee_role,
            assignment_type, assigned_by, escalation_level
        ) VALUES (
            p_instance_id, 0, 
            v_escalation.escalation_actions->>'escalate_to',
            v_escalation.escalation_actions->>'escalate_to',
            'escalation', 0, v_escalation.escalation_level
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate workflow performance metrics
CREATE OR REPLACE FUNCTION calculate_workflow_metrics(
    p_date DATE DEFAULT CURRENT_DATE,
    p_workflow_id INTEGER DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_metrics_count INTEGER := 0;
    v_workflow RECORD;
BEGIN
    -- Calculate metrics for specified workflow or all workflows
    FOR v_workflow IN
        SELECT id, workflow_type
        FROM workflow_definitions
        WHERE (p_workflow_id IS NULL OR id = p_workflow_id)
          AND is_active = true
    LOOP
        -- Insert or update daily metrics
        INSERT INTO workflow_performance_metrics (
            metric_date, workflow_id, workflow_type,
            instances_started, instances_completed, instances_cancelled, instances_escalated,
            avg_processing_time, median_processing_time, min_processing_time, max_processing_time,
            approval_rate, rejection_rate, escalation_rate,
            sla_met_count, sla_missed_count
        )
        SELECT
            p_date,
            v_workflow.id,
            v_workflow.workflow_type,
            COUNT(*) FILTER (WHERE DATE(started_at) = p_date),
            COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND status = 'completed'),
            COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND status = 'cancelled'),
            COUNT(*) FILTER (WHERE escalation_count > 0 AND DATE(started_at) = p_date),
            AVG(total_processing_time_minutes) FILTER (WHERE DATE(completed_at) = p_date),
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_processing_time_minutes) FILTER (WHERE DATE(completed_at) = p_date),
            MIN(total_processing_time_minutes) FILTER (WHERE DATE(completed_at) = p_date),
            MAX(total_processing_time_minutes) FILTER (WHERE DATE(completed_at) = p_date),
            (COUNT(*) FILTER (WHERE final_decision = 'approved' AND DATE(completed_at) = p_date) * 100.0 / 
             NULLIF(COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND status = 'completed'), 0)),
            (COUNT(*) FILTER (WHERE final_decision LIKE '%reject%' AND DATE(completed_at) = p_date) * 100.0 / 
             NULLIF(COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND status = 'completed'), 0)),
            (COUNT(*) FILTER (WHERE escalation_count > 0 AND DATE(started_at) = p_date) * 100.0 / 
             NULLIF(COUNT(*) FILTER (WHERE DATE(started_at) = p_date), 0)),
            COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND total_processing_time_minutes <= 2880), -- 48 hours SLA
            COUNT(*) FILTER (WHERE DATE(completed_at) = p_date AND total_processing_time_minutes > 2880)
        FROM workflow_instances
        WHERE workflow_id = v_workflow.id
          AND (DATE(started_at) = p_date OR DATE(completed_at) = p_date)
        GROUP BY v_workflow.id, v_workflow.workflow_type
        HAVING COUNT(*) > 0
        ON CONFLICT (metric_date, workflow_id, department_id) 
        DO UPDATE SET
            instances_started = EXCLUDED.instances_started,
            instances_completed = EXCLUDED.instances_completed,
            instances_cancelled = EXCLUDED.instances_cancelled,
            instances_escalated = EXCLUDED.instances_escalated,
            avg_processing_time = EXCLUDED.avg_processing_time,
            median_processing_time = EXCLUDED.median_processing_time,
            min_processing_time = EXCLUDED.min_processing_time,
            max_processing_time = EXCLUDED.max_processing_time,
            approval_rate = EXCLUDED.approval_rate,
            rejection_rate = EXCLUDED.rejection_rate,
            escalation_rate = EXCLUDED.escalation_rate,
            sla_met_count = EXCLUDED.sla_met_count,
            sla_missed_count = EXCLUDED.sla_missed_count,
            calculated_at = CURRENT_TIMESTAMP;
        
        v_metrics_count := v_metrics_count + 1;
    END LOOP;
    
    RETURN v_metrics_count;
END;
$$ LANGUAGE plpgsql;

-- View for current workflow workload
CREATE OR REPLACE VIEW current_workflow_workload AS
SELECT 
    wi.current_assignee_id,
    COUNT(*) as total_assignments,
    COUNT(*) FILTER (WHERE wi.priority < 50) as high_priority_count,
    COUNT(*) FILTER (WHERE wi.business_impact = 'critical') as critical_count,
    COUNT(*) FILTER (WHERE wi.due_date < CURRENT_TIMESTAMP) as overdue_count,
    COUNT(*) FILTER (WHERE wi.escalation_count > 0) as escalated_count,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - wi.updated_at)) / 3600) as avg_age_hours
FROM workflow_instances wi
WHERE wi.status = 'active'
  AND wi.current_assignee_id IS NOT NULL
GROUP BY wi.current_assignee_id;

-- View for workflow performance dashboard
CREATE OR REPLACE VIEW workflow_performance_dashboard AS
SELECT 
    wd.workflow_name,
    wd.display_name_ru,
    wd.workflow_type,
    COUNT(wi.id) as total_instances,
    COUNT(*) FILTER (WHERE wi.status = 'active') as active_instances,
    COUNT(*) FILTER (WHERE wi.status = 'completed') as completed_instances,
    COUNT(*) FILTER (WHERE wi.escalation_count > 0) as escalated_instances,
    ROUND(AVG(wi.total_processing_time_minutes), 0) as avg_processing_minutes,
    ROUND(
        COUNT(*) FILTER (WHERE wi.final_decision LIKE '%approv%') * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE wi.status = 'completed'), 0), 
        1
    ) as approval_rate_percent,
    COUNT(*) FILTER (WHERE wi.due_date < CURRENT_TIMESTAMP AND wi.status = 'active') as overdue_count
FROM workflow_definitions wd
LEFT JOIN workflow_instances wi ON wd.id = wi.workflow_id
WHERE wd.is_active = true
GROUP BY wd.id, wd.workflow_name, wd.display_name_ru, wd.workflow_type
ORDER BY wd.workflow_type, wd.workflow_name;

-- Test the functions with sample data
SELECT start_workflow_instance(
    'vacation_standard', 
    101, 
    'Тестовый Пользователь',
    '{"vacation_start": "2025-08-15", "vacation_end": "2025-08-29", "days": 14, "reason": "Плановый отпуск"}'::jsonb,
    100,
    'medium',
    'medium'
) as created_instance_id;

-- Verify workflow performance dashboard
SELECT * FROM workflow_performance_dashboard;