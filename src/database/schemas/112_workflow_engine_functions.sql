-- =====================================================================================
-- Schema 112: Workflow Engine Functions and Sample Data
-- =====================================================================================
-- Complete implementation with functions, sample configurations, and test data
-- =====================================================================================

-- Function to start a new workflow instance
CREATE OR REPLACE FUNCTION start_wfm_workflow_instance(
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
    FROM wfm_workflow_definitions 
    WHERE workflow_name = p_workflow_name AND is_active = true;
    
    IF v_workflow_id IS NULL THEN
        RAISE EXCEPTION 'Workflow % not found or inactive', p_workflow_name;
    END IF;
    
    -- Get initial state
    SELECT id, state_key INTO v_initial_state_id, v_initial_state_key
    FROM wfm_workflow_states 
    WHERE workflow_id = v_workflow_id AND state_type = 'initial' AND is_active = true
    LIMIT 1;
    
    IF v_initial_state_id IS NULL THEN
        RAISE EXCEPTION 'No initial state found for workflow %', p_workflow_name;
    END IF;
    
    -- Generate unique instance key
    v_instance_key := UPPER(LEFT(p_workflow_name, 3)) || '-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || 
                      LPAD(nextval('wfm_workflow_process_instances_id_seq')::TEXT, 6, '0');
    
    -- Create workflow instance
    INSERT INTO wfm_workflow_process_instances (
        workflow_id, instance_key, request_type, requester_id, requester_name,
        current_state_id, current_state_key, process_data, priority, 
        business_impact, urgency, status
    ) VALUES (
        v_workflow_id, v_instance_key, p_workflow_name, p_requester_id, p_requester_name,
        v_initial_state_id, v_initial_state_key, p_request_data, p_priority,
        p_business_impact, p_urgency, 'active'
    ) RETURNING id INTO v_instance_id;
    
    -- Log initial state in history
    INSERT INTO wfm_workflow_execution_history (
        instance_id, to_state_id, actor_id, actor_name, action_type,
        action_description_ru, data_after
    ) VALUES (
        v_instance_id, v_initial_state_id, p_requester_id, p_requester_name,
        'transition', 'Создание экземпляра рабочего процесса', p_request_data
    );
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate workflow performance metrics
CREATE OR REPLACE FUNCTION calculate_wfm_workflow_metrics(
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
        FROM wfm_workflow_definitions
        WHERE (p_workflow_id IS NULL OR id = p_workflow_id)
          AND is_active = true
    LOOP
        -- Insert or update daily metrics
        INSERT INTO wfm_workflow_performance_metrics (
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
        FROM wfm_workflow_process_instances
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

-- Insert approval routing rules
INSERT INTO wfm_approval_routing_rules (workflow_id, rule_name, rule_name_ru, priority, conditions, approval_chain, escalation_rules, created_by) VALUES

-- Vacation approval rules
(1, 'standard_vacation', 'Стандартный отпуск', 100, 
'{"vacation_days": {"$lte": 14}, "employee_level": "standard", "advance_days": {"$gte": 14}}',
'[{"role": "supervisor", "timeout_hours": 48}, {"role": "hr_specialist", "timeout_hours": 24}]',
'{"supervisor": {"timeout_hours": 72, "escalate_to": "manager"}, "hr_specialist": {"timeout_hours": 48, "escalate_to": "hr_manager"}}', 1),

(1, 'extended_vacation', 'Продленный отпуск', 90,
'{"vacation_days": {"$gt": 14}, "vacation_days": {"$lte": 28}}',
'[{"role": "supervisor", "timeout_hours": 24}, {"role": "manager", "timeout_hours": 24}, {"role": "hr_manager", "timeout_hours": 24}]',
'{"supervisor": {"timeout_hours": 48, "escalate_to": "manager"}, "manager": {"timeout_hours": 48, "escalate_to": "department_head"}}', 1),

-- Overtime approval rules
(2, 'standard_overtime', 'Стандартная сверхурочная работа', 100,
'{"overtime_hours": {"$lte": 4}, "weekly_overtime": {"$lte": 8}}',
'[{"role": "supervisor", "timeout_hours": 24}, {"role": "manager", "timeout_hours": 12}]',
'{"supervisor": {"timeout_hours": 36, "escalate_to": "manager"}, "manager": {"timeout_hours": 24, "escalate_to": "department_head"}}', 1),

(2, 'extended_overtime', 'Повышенная сверхурочная работа', 90,
'{"overtime_hours": {"$gt": 4}, "weekly_overtime": {"$gt": 8}}',
'[{"role": "supervisor", "timeout_hours": 12}, {"role": "manager", "timeout_hours": 12}, {"role": "department_head", "timeout_hours": 24}]',
'{"supervisor": {"timeout_hours": 24, "escalate_to": "manager"}, "manager": {"timeout_hours": 24, "escalate_to": "department_head"}}', 1),

-- Shift exchange approval rules
(3, 'same_skill_exchange', 'Обмен в рамках одного навыка', 100,
'{"skill_level_match": true, "same_department": true, "advance_hours": {"$gte": 24}}',
'[{"role": "supervisor", "timeout_hours": 8}]',
'{"supervisor": {"timeout_hours": 16, "escalate_to": "manager"}}', 1),

(3, 'cross_skill_exchange', 'Межнавыковый обмен', 80,
'{"skill_level_match": false, "cross_department": true}',
'[{"role": "supervisor", "timeout_hours": 8}, {"role": "manager", "timeout_hours": 12}]',
'{"supervisor": {"timeout_hours": 16, "escalate_to": "manager"}, "manager": {"timeout_hours": 24, "escalate_to": "department_head"}}', 1);

-- Insert escalation rules
INSERT INTO wfm_escalation_rules (workflow_id, state_id, escalation_name, escalation_name_ru, trigger_type, timeout_minutes, escalation_actions, escalation_level, created_by) VALUES

-- Vacation escalation rules
(1, 2, 'supervisor_timeout', 'Превышение времени ожидания руководителя', 'time_based', 2880, -- 48 hours
'{"notify": ["manager", "hr_specialist"], "escalate_to": "manager", "add_urgency": true}', 1, 1),

(1, 3, 'hr_timeout', 'Превышение времени ожидания HR', 'time_based', 1440, -- 24 hours
'{"notify": ["hr_manager", "supervisor"], "escalate_to": "hr_manager", "mark_urgent": true}', 1, 1),

-- Overtime escalation rules
(2, 7, 'supervisor_overtime_timeout', 'Превышение времени согласования сверхурочной работы', 'time_based', 1440, -- 24 hours
'{"notify": ["manager"], "escalate_to": "manager", "highlight_business_impact": true}', 1, 1),

(2, 8, 'manager_overtime_timeout', 'Превышение времени утверждения сверхурочной работы', 'time_based', 720, -- 12 hours
'{"notify": ["department_head"], "escalate_to": "department_head", "mark_critical": true}', 1, 1),

-- Shift exchange escalation rules
(3, 12, 'counterpart_response_timeout', 'Превышение времени ответа коллеги', 'time_based', 720, -- 12 hours
'{"notify": ["supervisor", "requester"], "send_reminder": true, "mark_urgent": true}', 1, 1),

(3, 13, 'supervisor_exchange_timeout', 'Превышение времени согласования обмена', 'time_based', 480, -- 8 hours
'{"notify": ["manager"], "escalate_to": "manager", "highlight_operational_impact": true}', 1, 1);

-- Sample workflow templates table
CREATE TABLE wfm_workflow_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_name_ru TEXT NOT NULL,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id),
    category VARCHAR(50) NOT NULL,
    
    -- Template configuration
    default_data JSONB NOT NULL DEFAULT '{}',
    field_configurations JSONB NOT NULL DEFAULT '{}', -- Field types, validation, UI hints
    business_rules JSONB NOT NULL DEFAULT '{}',
    
    -- Usage information
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2),
    avg_completion_time_hours INTEGER,
    
    -- Template metadata
    description_ru TEXT,
    instructions_ru TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Insert workflow templates for common scenarios
INSERT INTO wfm_workflow_templates (template_name, template_name_ru, workflow_id, category, default_data, field_configurations, business_rules, description_ru, created_by) VALUES

-- Vacation templates
('annual_vacation_2weeks', 'Ежегодный отпуск (2 недели)', 1, 'vacation', 
'{"vacation_type": "annual", "days": 14, "advance_notice_days": 21}',
'{"vacation_start": {"type": "date", "required": true, "min_advance_days": 14}, "vacation_end": {"type": "date", "required": true}, "reason": {"type": "textarea", "max_length": 500}}',
'{"max_consecutive_days": 28, "min_advance_notice": 14, "requires_coverage": true}',
'Стандартный шаблон для планового ежегодного отпуска продолжительностью 2 недели', 1),

('maternity_leave', 'Отпуск по беременности и родам', 1, 'vacation',
'{"vacation_type": "maternity", "days": 140, "advance_notice_days": 7}',
'{"expected_date": {"type": "date", "required": true}, "medical_certificate": {"type": "file", "required": true}, "contact_info": {"type": "text", "required": true}}',
'{"automatic_approval": true, "no_coverage_required": true, "priority": "high"}',
'Шаблон для отпуска по беременности и родам с автоматическим согласованием', 1),

-- Overtime templates
('urgent_overtime', 'Срочная сверхурочная работа', 2, 'overtime',
'{"overtime_type": "urgent", "max_hours": 4, "business_justification": true}',
'{"overtime_date": {"type": "date", "required": true}, "hours": {"type": "number", "min": 1, "max": 8}, "justification": {"type": "textarea", "required": true, "min_length": 50}}',
'{"max_daily_hours": 8, "requires_manager_approval": true, "priority": "high"}',
'Шаблон для срочной сверхурочной работы с ускоренным согласованием', 1),

('planned_overtime', 'Плановая сверхурочная работа', 2, 'overtime',
'{"overtime_type": "planned", "advance_notice_hours": 48}',
'{"overtime_dates": {"type": "date_range", "required": true}, "total_hours": {"type": "number", "max": 20}, "project_code": {"type": "select", "required": true}}',
'{"max_weekly_hours": 20, "advance_notice_required": 48, "budget_check": true}',
'Шаблон для плановой сверхурочной работы по проектам', 1),

-- Shift exchange templates
('emergency_shift_exchange', 'Экстренный обмен сменами', 3, 'shift_exchange',
'{"exchange_type": "emergency", "advance_notice_hours": 2}',
'{"original_shift": {"type": "shift_selector", "required": true}, "proposed_shift": {"type": "shift_selector", "required": true}, "emergency_reason": {"type": "textarea", "required": true}}',
'{"min_advance_hours": 2, "emergency_approval": true, "skill_match_required": false}',
'Шаблон для экстренного обмена сменами в случае форс-мажора', 1),

('voluntary_shift_exchange', 'Добровольный обмен сменами', 3, 'shift_exchange',
'{"exchange_type": "voluntary", "advance_notice_hours": 24}',
'{"counterpart_employee": {"type": "employee_selector", "required": true}, "exchange_reason": {"type": "select", "options": ["personal", "training", "vacation", "other"]}}',
'{"advance_notice_hours": 24, "mutual_consent": true, "skill_level_match": true}',
'Стандартный шаблон для добровольного обмена сменами между сотрудниками', 1);

-- Create comprehensive views for workflow analytics
CREATE OR REPLACE VIEW wfm_workflow_dashboard AS
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
    COUNT(*) FILTER (WHERE wi.due_date < CURRENT_TIMESTAMP AND wi.status = 'active') as overdue_count,
    COUNT(DISTINCT ws.id) as states_count,
    COUNT(DISTINCT arr.id) as approval_rules_count
FROM wfm_workflow_definitions wd
LEFT JOIN wfm_workflow_process_instances wi ON wd.id = wi.workflow_id
LEFT JOIN wfm_workflow_states ws ON wd.id = ws.workflow_id
LEFT JOIN wfm_approval_routing_rules arr ON wd.id = arr.workflow_id
WHERE wd.is_active = true
GROUP BY wd.id, wd.workflow_name, wd.display_name_ru, wd.workflow_type
ORDER BY wd.workflow_type, wd.workflow_name;

-- Create sample workflow instances for testing
DO $$
DECLARE
    v_instance_id INTEGER;
BEGIN
    -- Test vacation workflow
    SELECT start_wfm_workflow_instance(
        'vacation_standard',
        101,
        'Иванова Анна Петровна',
        jsonb_build_object(
            'vacation_type', 'annual',
            'vacation_start', '2025-08-01',
            'vacation_end', '2025-08-15',
            'days', 14,
            'reason', 'Плановый ежегодный отпуск',
            'employee_level', 'standard',
            'department', 'Customer Service'
        ),
        100,
        'medium',
        'medium'
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created vacation workflow instance: %', v_instance_id;
    
    -- Test overtime workflow
    SELECT start_wfm_workflow_instance(
        'overtime_standard',
        102,
        'Петров Сергей Иванович',
        jsonb_build_object(
            'overtime_type', 'urgent',
            'overtime_date', '2025-07-15',
            'hours', 4,
            'justification', 'Срочная обработка критических заявок клиентов',
            'project_code', 'URGENT-2025-001'
        ),
        50,
        'high',
        'urgent'
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created overtime workflow instance: %', v_instance_id;
    
    -- Test shift exchange workflow
    SELECT start_wfm_workflow_instance(
        'shift_exchange',
        103,
        'Сидорова Елена Александровна',
        jsonb_build_object(
            'exchange_type', 'voluntary',
            'counterpart_employee_id', 104,
            'counterpart_name', 'Козлов Дмитрий Владимирович',
            'original_shift_date', '2025-07-20',
            'proposed_shift_date', '2025-07-22',
            'exchange_reason', 'personal'
        ),
        100,
        'medium',
        'medium'
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created shift exchange workflow instance: %', v_instance_id;
END $$;

-- Final comprehensive verification query
SELECT 
    'Workflow Definitions' as component,
    COUNT(*) as count,
    string_agg(workflow_name, ', ') as details
FROM wfm_workflow_definitions
WHERE is_active = true

UNION ALL

SELECT 
    'Workflow States' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' states across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as details
FROM wfm_workflow_states
WHERE is_active = true

UNION ALL

SELECT 
    'Approval Rules' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' rules across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as details
FROM wfm_approval_routing_rules
WHERE is_active = true

UNION ALL

SELECT 
    'Escalation Rules' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' rules across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as details
FROM wfm_escalation_rules
WHERE is_active = true

UNION ALL

SELECT 
    'Workflow Templates' as component,
    COUNT(*) as count,
    string_agg(template_name_ru, ', ') as details
FROM wfm_workflow_templates
WHERE is_active = true

UNION ALL

SELECT 
    'Active Process Instances' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' instances currently active' as details
FROM wfm_workflow_process_instances
WHERE status = 'active';

-- Performance test query
SELECT 
    'Workflow Performance Dashboard' as test_name,
    COUNT(*) as workflows_configured
FROM wfm_workflow_dashboard;

-- Comments for documentation
COMMENT ON FUNCTION start_wfm_workflow_instance IS 'Запуск нового экземпляра рабочего процесса с валидацией и аудитом';
COMMENT ON FUNCTION calculate_wfm_workflow_metrics IS 'Расчет метрик производительности рабочих процессов за указанную дату';
COMMENT ON VIEW wfm_workflow_dashboard IS 'Панель управления рабочими процессами с ключевыми метриками';
COMMENT ON TABLE wfm_workflow_templates IS 'Шаблоны рабочих процессов для быстрого создания типовых заявок';