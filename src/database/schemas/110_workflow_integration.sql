-- =====================================================================================
-- Schema 110: Workflow Integration and Sample Configurations
-- =====================================================================================
-- Part 5/5: Integration with existing WFM systems and comprehensive sample data
-- =====================================================================================

-- Integration table for linking workflows with existing WFM entities
CREATE TABLE workflow_entity_links (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- 'employee_request', 'schedule_change', 'shift_assignment'
    entity_id INTEGER NOT NULL,
    entity_table VARCHAR(100) NOT NULL,
    
    -- Link metadata
    link_type VARCHAR(20) NOT NULL, -- 'source', 'target', 'related'
    relationship_data JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'synced', 'failed', 'manual'
    last_sync_at TIMESTAMP WITH TIME ZONE,
    sync_error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(instance_id, entity_type, entity_id),
    
    CONSTRAINT chk_link_type CHECK (link_type IN ('source', 'target', 'related')),
    CONSTRAINT chk_sync_status CHECK (sync_status IN ('pending', 'synced', 'failed', 'manual'))
);

-- Index for entity lookups
CREATE INDEX idx_workflow_entity_links_entity ON workflow_entity_links(entity_type, entity_id);
CREATE INDEX idx_workflow_entity_links_instance ON workflow_entity_links(instance_id);
CREATE INDEX idx_workflow_entity_links_sync ON workflow_entity_links(sync_status, last_sync_at);

-- Workflow templates for common business scenarios
CREATE TABLE workflow_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_name_ru TEXT NOT NULL,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id),
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

-- Index for template management
CREATE INDEX idx_workflow_templates_workflow ON workflow_templates(workflow_id);
CREATE INDEX idx_workflow_templates_category ON workflow_templates(category);
CREATE INDEX idx_workflow_templates_active ON workflow_templates(is_active);

-- Russian business calendar integration for workflow scheduling
CREATE TABLE workflow_business_calendar (
    id SERIAL PRIMARY KEY,
    calendar_date DATE NOT NULL UNIQUE,
    is_business_day BOOLEAN NOT NULL,
    is_holiday BOOLEAN NOT NULL DEFAULT false,
    holiday_name_ru TEXT,
    day_type VARCHAR(20) NOT NULL, -- 'working', 'weekend', 'holiday', 'shortened'
    
    -- Working hours for this specific date
    start_time TIME,
    end_time TIME,
    working_hours DECIMAL(3,1), -- For shortened days
    
    -- Regional specifics
    region VARCHAR(50) DEFAULT 'РФ',
    federal_subject VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_day_type CHECK (day_type IN ('working', 'weekend', 'holiday', 'shortened'))
);

-- Index for calendar lookups
CREATE INDEX idx_workflow_calendar_date ON workflow_business_calendar(calendar_date);
CREATE INDEX idx_workflow_calendar_business ON workflow_business_calendar(is_business_day);

-- Advanced workflow configuration for complex scenarios
CREATE TABLE workflow_complex_configurations (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id),
    configuration_name VARCHAR(100) NOT NULL,
    configuration_name_ru TEXT NOT NULL,
    
    -- Complex routing rules
    conditional_routing JSONB NOT NULL DEFAULT '{}', -- Complex IF-THEN-ELSE routing
    parallel_approval_rules JSONB NOT NULL DEFAULT '{}', -- Parallel approval configurations
    dynamic_assignment_rules JSONB NOT NULL DEFAULT '{}', -- Dynamic assignee calculation
    
    -- Advanced escalation
    multi_level_escalation JSONB NOT NULL DEFAULT '{}', -- Complex escalation chains
    escalation_matrix JSONB NOT NULL DEFAULT '{}', -- Role-based escalation matrix
    
    -- Integration rules
    external_system_hooks JSONB NOT NULL DEFAULT '{}', -- External system integration points
    data_synchronization_rules JSONB NOT NULL DEFAULT '{}', -- Data sync configurations
    
    -- Business logic
    validation_rules JSONB NOT NULL DEFAULT '{}', -- Complex validation logic
    calculation_rules JSONB NOT NULL DEFAULT '{}', -- Business calculation rules
    notification_templates JSONB NOT NULL DEFAULT '{}', -- Notification configurations
    
    -- Metadata
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_from DATE,
    effective_to DATE,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(workflow_id, configuration_name)
);

-- Index for complex configurations
CREATE INDEX idx_complex_config_workflow ON workflow_complex_configurations(workflow_id);
CREATE INDEX idx_complex_config_active ON workflow_complex_configurations(is_active);
CREATE INDEX idx_complex_config_effective ON workflow_complex_configurations(effective_from, effective_to);

-- Insert sample business calendar data (2025)
INSERT INTO workflow_business_calendar (calendar_date, is_business_day, is_holiday, holiday_name_ru, day_type, start_time, end_time, working_hours) VALUES
-- January 2025
('2025-01-01', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-02', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-03', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-04', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-05', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-06', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
('2025-01-07', false, true, 'Рождество Христово', 'holiday', null, null, 0),
('2025-01-08', false, true, 'Новогодние каникулы', 'holiday', null, null, 0),
-- February 2025
('2025-02-23', false, true, 'День защитника Отечества', 'holiday', null, null, 0),
('2025-02-24', false, false, 'Перенесенный выходной', 'weekend', null, null, 0),
-- March 2025
('2025-03-08', false, true, 'Международный женский день', 'holiday', null, null, 0),
('2025-03-10', false, false, 'Перенесенный выходной', 'weekend', null, null, 0),
-- Standard working days pattern
('2025-07-14', true, false, null, 'working', '09:00', '18:00', 8.0),
('2025-07-15', true, false, null, 'working', '09:00', '18:00', 8.0),
('2025-07-16', true, false, null, 'working', '09:00', '18:00', 8.0),
('2025-07-17', true, false, null, 'working', '09:00', '18:00', 8.0),
('2025-07-18', true, false, null, 'working', '09:00', '17:00', 7.0), -- Friday - shortened day
('2025-07-19', false, false, null, 'weekend', null, null, 0),
('2025-07-20', false, false, null, 'weekend', null, null, 0);

-- Insert workflow templates for common scenarios
INSERT INTO workflow_templates (template_name, template_name_ru, workflow_id, category, default_data, field_configurations, business_rules, description_ru, created_by) VALUES

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

-- Insert complex configurations for advanced scenarios
INSERT INTO workflow_complex_configurations (workflow_id, configuration_name, configuration_name_ru, conditional_routing, parallel_approval_rules, multi_level_escalation, external_system_hooks, created_by) VALUES

-- Complex vacation approval based on amount and seniority
(1, 'senior_employee_vacation', 'Отпуск для ведущих сотрудников',
'{"conditions": [{"if": {"employee_level": "senior", "vacation_days": {"$gte": 21}}, "then": {"route_to": ["supervisor", "department_head", "hr_manager"], "parallel": false}}, {"if": {"employee_level": "senior", "vacation_days": {"$lt": 21}}, "then": {"route_to": ["supervisor", "hr_specialist"], "parallel": false}}]}',
'{"senior_long_vacation": {"approvers": ["supervisor", "department_head"], "mode": "sequential", "timeout_hours": 24}}',
'{"level_1": {"timeout_hours": 48, "escalate_to": "manager"}, "level_2": {"timeout_hours": 24, "escalate_to": "department_head"}, "level_3": {"timeout_hours": 12, "escalate_to": "hr_director"}}',
'{"calendar_update": {"endpoint": "/api/calendar/vacation", "method": "POST"}, "payroll_notification": {"endpoint": "/api/payroll/vacation", "method": "POST"}}', 1),

-- Complex overtime with budget and compliance checks
(2, 'budget_controlled_overtime', 'Сверхурочная работа с контролем бюджета',
'{"conditions": [{"if": {"monthly_overtime_budget": {"$gt": 0}, "employee_overtime_limit": {"$gt": 0}}, "then": {"auto_approve": true}}, {"if": {"monthly_overtime_budget": {"$lte": 0}}, "then": {"route_to": ["finance_manager", "department_head"], "require_budget_approval": true}}]}',
'{"budget_approval": {"approvers": ["supervisor", "finance_manager"], "mode": "parallel", "required_votes": 2}}',
'{"budget_exceeded": {"immediate_escalation": true, "escalate_to": "finance_director"}, "compliance_issue": {"escalate_to": "hr_compliance_officer"}}',
'{"budget_check": {"endpoint": "/api/finance/budget-check", "method": "GET"}, "compliance_validation": {"endpoint": "/api/compliance/overtime-check", "method": "POST"}}', 1),

-- Complex shift exchange with skill matching and coverage analysis
(3, 'skill_matched_exchange', 'Обмен сменами с проверкой навыков',
'{"conditions": [{"if": {"skill_compatibility": {"$gte": 0.8}, "coverage_impact": {"$eq": "none"}}, "then": {"auto_approve": true}}, {"if": {"skill_compatibility": {"$lt": 0.8}}, "then": {"require_training_manager_approval": true}}, {"if": {"coverage_impact": {"$ne": "none"}}, "then": {"require_operations_manager_approval": true}}]}',
'{"skill_verification": {"approvers": ["training_manager", "supervisor"], "mode": "parallel"}, "coverage_approval": {"approvers": ["operations_manager"], "mode": "sequential"}}',
'{"skill_mismatch": {"escalate_to": "training_director"}, "coverage_risk": {"escalate_to": "operations_director"}}',
'{"skill_analysis": {"endpoint": "/api/skills/compatibility", "method": "POST"}, "coverage_calculation": {"endpoint": "/api/forecasting/coverage-impact", "method": "POST"}}', 1);

-- Function to get workflow configuration for business hours calculation
CREATE OR REPLACE FUNCTION get_business_hours_between(
    start_timestamp TIMESTAMP WITH TIME ZONE,
    end_timestamp TIMESTAMP WITH TIME ZONE
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    business_hours DECIMAL(10,2) := 0;
    current_date DATE;
    calendar_day RECORD;
    day_start TIMESTAMP WITH TIME ZONE;
    day_end TIMESTAMP WITH TIME ZONE;
    overlap_start TIMESTAMP WITH TIME ZONE;
    overlap_end TIMESTAMP WITH TIME ZONE;
    overlap_hours DECIMAL(10,2);
BEGIN
    current_date := start_timestamp::DATE;
    
    WHILE current_date <= end_timestamp::DATE LOOP
        -- Get calendar information for this date
        SELECT * INTO calendar_day
        FROM workflow_business_calendar
        WHERE calendar_date = current_date;
        
        -- If no calendar entry, assume standard working day
        IF NOT FOUND THEN
            calendar_day.is_business_day := EXTRACT(DOW FROM current_date) BETWEEN 1 AND 5;
            calendar_day.start_time := '09:00'::TIME;
            calendar_day.end_time := '18:00'::TIME;
            calendar_day.working_hours := 8.0;
        END IF;
        
        -- Only count business days
        IF calendar_day.is_business_day THEN
            -- Calculate business hours for this day
            day_start := current_date + calendar_day.start_time;
            day_end := current_date + calendar_day.end_time;
            
            -- Find overlap between business hours and our time range
            overlap_start := GREATEST(start_timestamp, day_start);
            overlap_end := LEAST(end_timestamp, day_end);
            
            -- Add overlap hours if positive
            IF overlap_end > overlap_start THEN
                overlap_hours := EXTRACT(EPOCH FROM (overlap_end - overlap_start)) / 3600.0;
                business_hours := business_hours + overlap_hours;
            END IF;
        END IF;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    RETURN business_hours;
END;
$$ LANGUAGE plpgsql;

-- Enhanced view for workflow analytics with business hours calculation
CREATE OR REPLACE VIEW workflow_analytics_detailed AS
SELECT 
    wi.id,
    wi.instance_key,
    wi.workflow_id,
    wd.workflow_name,
    wd.display_name_ru,
    wi.request_type,
    wi.requester_name,
    wi.current_state_key,
    wi.status,
    wi.business_impact,
    wi.urgency,
    wi.priority,
    wi.started_at,
    wi.completed_at,
    wi.total_processing_time_minutes,
    
    -- Business hours calculation
    CASE 
        WHEN wi.completed_at IS NOT NULL THEN
            get_business_hours_between(wi.started_at, wi.completed_at)
        ELSE
            get_business_hours_between(wi.started_at, CURRENT_TIMESTAMP)
    END as business_hours_elapsed,
    
    -- Performance indicators
    CASE 
        WHEN wi.total_processing_time_minutes <= 1440 THEN 'Быстро' -- ≤ 24 hours
        WHEN wi.total_processing_time_minutes <= 2880 THEN 'Нормально' -- ≤ 48 hours
        WHEN wi.total_processing_time_minutes <= 4320 THEN 'Медленно' -- ≤ 72 hours
        ELSE 'Критично'
    END as processing_speed,
    
    wi.escalation_count,
    wi.final_decision,
    wi.final_decision_reason,
    
    -- Linked entities
    STRING_AGG(DISTINCT wel.entity_type || ':' || wel.entity_id, ', ') as linked_entities,
    
    -- Template information
    wt.template_name_ru,
    
    -- Current assignment
    wa.assignee_name as current_assignee,
    wa.assignee_role as current_assignee_role,
    wa.due_date as assignment_due_date

FROM workflow_instances wi
JOIN workflow_definitions wd ON wi.workflow_id = wd.id
LEFT JOIN workflow_entity_links wel ON wi.id = wel.instance_id
LEFT JOIN workflow_templates wt ON wi.process_data->>'template_id' = wt.id::text
LEFT JOIN workflow_assignments wa ON wi.id = wa.instance_id AND wa.status = 'pending'
GROUP BY wi.id, wd.workflow_name, wd.display_name_ru, wt.template_name_ru, wa.assignee_name, wa.assignee_role, wa.due_date
ORDER BY wi.started_at DESC;

-- Test complex workflow scenarios
DO $$
DECLARE
    v_instance_id INTEGER;
BEGIN
    -- Test vacation workflow with template
    SELECT start_workflow_instance(
        'vacation_standard',
        102,
        'Петрова Анна Сергеевна',
        jsonb_build_object(
            'template_id', 1,
            'vacation_type', 'annual',
            'vacation_start', '2025-08-01',
            'vacation_end', '2025-08-15',
            'days', 14,
            'reason', 'Плановый ежегодный отпуск',
            'employee_level', 'senior',
            'department', 'Customer Service'
        )
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created vacation workflow instance: %', v_instance_id;
    
    -- Test overtime workflow
    SELECT start_workflow_instance(
        'overtime_standard',
        103,
        'Иванов Петр Михайлович',
        jsonb_build_object(
            'template_id', 3,
            'overtime_type', 'urgent',
            'overtime_date', '2025-07-15',
            'hours', 4,
            'justification', 'Срочная обработка критических заявок клиентов',
            'project_code', 'URGENT-2025-001'
        )
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created overtime workflow instance: %', v_instance_id;
    
    -- Test shift exchange workflow
    SELECT start_workflow_instance(
        'shift_exchange',
        104,
        'Сидоров Алексей Владимирович',
        jsonb_build_object(
            'template_id', 6,
            'exchange_type', 'voluntary',
            'counterpart_employee_id', 105,
            'counterpart_name', 'Козлова Елена Игоревна',
            'original_shift_date', '2025-07-20',
            'proposed_shift_date', '2025-07-22',
            'exchange_reason', 'personal'
        )
    ) INTO v_instance_id;
    
    RAISE NOTICE 'Created shift exchange workflow instance: %', v_instance_id;
END $$;

-- Final verification query
SELECT 
    'Workflow Definitions' as component,
    COUNT(*) as count,
    string_agg(workflow_name, ', ') as items
FROM workflow_definitions
WHERE is_active = true

UNION ALL

SELECT 
    'Workflow States' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' states across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as items
FROM workflow_states
WHERE is_active = true

UNION ALL

SELECT 
    'Workflow Transitions' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' transitions across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as items
FROM workflow_transitions
WHERE is_active = true

UNION ALL

SELECT 
    'Approval Rules' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' rules across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as items
FROM approval_routing_rules
WHERE is_active = true

UNION ALL

SELECT 
    'Escalation Rules' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' rules across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as items
FROM escalation_rules
WHERE is_active = true

UNION ALL

SELECT 
    'Workflow Templates' as component,
    COUNT(*) as count,
    string_agg(template_name_ru, ', ') as items
FROM workflow_templates
WHERE is_active = true

UNION ALL

SELECT 
    'Complex Configurations' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' configurations across ' || COUNT(DISTINCT workflow_id)::text || ' workflows' as items
FROM workflow_complex_configurations
WHERE is_active = true

UNION ALL

SELECT 
    'Active Workflow Instances' as component,
    COUNT(*) as count,
    COUNT(*)::text || ' instances currently active' as items
FROM workflow_instances
WHERE status = 'active';

-- Comments for documentation
COMMENT ON TABLE workflow_entity_links IS 'Связи экземпляров рабочих процессов с сущностями WFM системы';
COMMENT ON TABLE workflow_templates IS 'Шаблоны рабочих процессов для типовых бизнес-сценариев';
COMMENT ON TABLE workflow_business_calendar IS 'Российский производственный календарь для расчета рабочего времени';
COMMENT ON TABLE workflow_complex_configurations IS 'Сложные конфигурации рабочих процессов для нестандартных сценариев';
COMMENT ON FUNCTION get_business_hours_between IS 'Расчет количества рабочих часов между двумя временными метками';