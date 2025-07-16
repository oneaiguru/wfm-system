-- =====================================================================================
-- Schema 108: Workflow States and Transitions Setup
-- =====================================================================================
-- Part 3/5: Complete state and transition configuration for all workflow types
-- =====================================================================================

-- Insert states for vacation workflow
INSERT INTO workflow_states (workflow_id, state_key, state_name_ru, description_ru, state_type, state_config, color_code, icon_name, sort_order) VALUES
-- Vacation workflow states (workflow_id = 1)
(1, 'draft', 'Черновик', 'Заявка создана, но не отправлена', 'initial', '{"editable": true, "timeout_hours": 24}', '#F3F4F6', 'edit', 1),
(1, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования непосредственного руководителя', 'intermediate', '{"timeout_hours": 48, "escalation_hours": 72}', '#FEF3C7', 'clock', 2),
(1, 'pending_hr', 'Ожидает HR', 'Ожидает согласования отдела кадров', 'intermediate', '{"timeout_hours": 24, "escalation_hours": 48}', '#DBEAFE', 'users', 3),
(1, 'approved', 'Одобрено', 'Заявка одобрена и обработана', 'final', '{"notify_requester": true, "update_calendar": true}', '#D1FAE5', 'check-circle', 4),
(1, 'rejected', 'Отклонено', 'Заявка отклонена', 'final', '{"notify_requester": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),
(1, 'cancelled', 'Отменено', 'Заявка отменена заявителем', 'final', '{"notify_approvers": true}', '#F3F4F6', 'ban', 6),

-- Overtime workflow states (workflow_id = 2)
(2, 'draft', 'Черновик', 'Заявка на сверхурочную работу создана', 'initial', '{"editable": true, "timeout_hours": 12}', '#F3F4F6', 'edit', 1),
(2, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования руководителя', 'intermediate', '{"timeout_hours": 24, "escalation_hours": 36}', '#FEF3C7', 'clock', 2),
(2, 'pending_manager', 'Ожидает менеджера', 'Ожидает согласования менеджера отдела', 'intermediate', '{"timeout_hours": 12, "escalation_hours": 24}', '#DBEAFE', 'briefcase', 3),
(2, 'approved', 'Одобрено', 'Сверхурочная работа одобрена', 'final', '{"notify_requester": true, "update_schedule": true}', '#D1FAE5', 'check-circle', 4),
(2, 'rejected', 'Отклонено', 'Заявка на сверхурочную работу отклонена', 'final', '{"notify_requester": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),

-- Shift exchange workflow states (workflow_id = 3)
(3, 'draft', 'Черновик', 'Предложение обмена сменами создано', 'initial', '{"editable": true, "timeout_hours": 6}', '#F3F4F6', 'edit', 1),
(3, 'pending_counterpart', 'Ожидает согласия коллеги', 'Ожидает согласия от второй стороны обмена', 'intermediate', '{"timeout_hours": 12, "auto_remind_hours": 6}', '#FEF3C7', 'user-plus', 2),
(3, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования руководителя', 'intermediate', '{"timeout_hours": 8, "escalation_hours": 16}', '#DBEAFE', 'clock', 3),
(3, 'approved', 'Одобрено', 'Обмен сменами одобрен', 'final', '{"notify_both_parties": true, "update_schedules": true}', '#D1FAE5', 'check-circle', 4),
(3, 'rejected', 'Отклонено', 'Обмен сменами отклонен', 'final', '{"notify_both_parties": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),
(3, 'counterpart_declined', 'Коллега отказался', 'Вторая сторона отказалась от обмена', 'final', '{"notify_requester": true}', '#FEE2E2', 'user-x', 6);

-- Insert transitions for vacation workflow
INSERT INTO workflow_transitions (workflow_id, from_state_id, to_state_id, transition_key, transition_name_ru, conditions, actions, required_roles, button_text_ru, button_color, icon_name, sort_order) VALUES

-- Vacation workflow transitions
-- From draft
(1, 1, 2, 'submit', 'Отправить на согласование', '{"min_advance_days": 14, "max_vacation_days": 28}', '{"send_notification": true, "assign_to_supervisor": true}', '["employee", "supervisor"]', 'Отправить', '#3B82F6', 'send', 1),
(1, 1, 6, 'cancel', 'Отменить', '{}', '{"notify_stakeholders": false}', '["employee"]', 'Отменить', '#6B7280', 'trash', 2),

-- From pending_supervisor
(1, 2, 3, 'approve_supervisor', 'Согласовать', '{"coverage_available": true}', '{"send_notification": true, "assign_to_hr": true}', '["supervisor", "manager"]', 'Согласовать', '#10B981', 'check', 1),
(1, 2, 5, 'reject_supervisor', 'Отклонить', '{}', '{"send_notification": true, "require_reason": true}', '["supervisor", "manager"]', 'Отклонить', '#EF4444', 'x', 2),
(1, 2, 1, 'return_for_correction', 'Вернуть на доработку', '{}', '{"send_notification": true, "add_comments": true}', '["supervisor", "manager"]', 'Вернуть', '#F59E0B', 'arrow-left', 3),

-- From pending_hr
(1, 3, 4, 'approve_hr', 'Утвердить', '{"vacation_balance_sufficient": true}', '{"send_notification": true, "update_calendar": true, "book_vacation": true}', '["hr_specialist", "hr_manager"]', 'Утвердить', '#10B981', 'check-circle', 1),
(1, 3, 5, 'reject_hr', 'Отклонить', '{}', '{"send_notification": true, "require_reason": true}', '["hr_specialist", "hr_manager"]', 'Отклонить', '#EF4444', 'x-circle', 2),
(1, 3, 2, 'return_to_supervisor', 'Вернуть руководителю', '{}', '{"send_notification": true, "add_comments": true}', '["hr_specialist", "hr_manager"]', 'Вернуть', '#F59E0B', 'arrow-left', 3);

-- Insert transitions for overtime workflow
INSERT INTO workflow_transitions (workflow_id, from_state_id, to_state_id, transition_key, transition_name_ru, conditions, actions, required_roles, button_text_ru, button_color, icon_name, sort_order) VALUES

-- Overtime workflow transitions (states 7-11)
-- From draft (state 7)
(2, 7, 8, 'submit', 'Отправить на согласование', '{"max_daily_overtime": 4, "justification_provided": true}', '{"send_notification": true, "assign_to_supervisor": true}', '["employee", "supervisor"]', 'Отправить', '#3B82F6', 'send', 1),
(2, 7, 7, 'save_draft', 'Сохранить черновик', '{}', '{"save_data": true}', '["employee"]', 'Сохранить', '#6B7280', 'save', 2),

-- From pending_supervisor (state 8)
(2, 8, 9, 'approve_supervisor', 'Согласовать', '{"business_justification": true}', '{"send_notification": true, "assign_to_manager": true}', '["supervisor"]', 'Согласовать', '#10B981', 'check', 1),
(2, 8, 11, 'reject_supervisor', 'Отклонить', '{}', '{"send_notification": true, "require_reason": true}', '["supervisor"]', 'Отклонить', '#EF4444', 'x', 2),

-- From pending_manager (state 9)
(2, 9, 10, 'approve_manager', 'Утвердить', '{"budget_available": true, "compliance_check": true}', '{"send_notification": true, "update_schedule": true}', '["manager", "department_head"]', 'Утвердить', '#10B981', 'check-circle', 1),
(2, 9, 11, 'reject_manager', 'Отклонить', '{}', '{"send_notification": true, "require_reason": true}', '["manager", "department_head"]', 'Отклонить', '#EF4444', 'x-circle', 2);

-- Insert transitions for shift exchange workflow
INSERT INTO workflow_transitions (workflow_id, from_state_id, to_state_id, transition_key, transition_name_ru, conditions, actions, required_roles, button_text_ru, button_color, icon_name, sort_order) VALUES

-- Shift exchange workflow transitions (states 12-17)
-- From draft (state 12)
(3, 12, 13, 'propose_exchange', 'Предложить обмен', '{"advance_notice_hours": 24, "counterpart_identified": true}', '{"send_notification": true, "notify_counterpart": true}', '["employee"]', 'Предложить', '#3B82F6', 'send', 1),

-- From pending_counterpart (state 13)
(3, 13, 14, 'accept_exchange', 'Принять обмен', '{"skill_level_match": true, "availability_confirmed": true}', '{"send_notification": true, "assign_to_supervisor": true}', '["counterpart_employee"]', 'Принять', '#10B981', 'check', 1),
(3, 13, 17, 'decline_exchange', 'Отклонить обмен', '{}', '{"send_notification": true, "notify_requester": true}', '["counterpart_employee"]', 'Отклонить', '#EF4444', 'x', 2),

-- From pending_supervisor (state 14)
(3, 14, 15, 'approve_exchange', 'Согласовать обмен', '{"coverage_maintained": true, "operational_impact_minimal": true}', '{"send_notification": true, "update_schedules": true, "notify_both_parties": true}', '["supervisor", "manager"]', 'Согласовать', '#10B981', 'check-circle', 1),
(3, 14, 16, 'reject_exchange', 'Отклонить обмен', '{}', '{"send_notification": true, "notify_both_parties": true, "require_reason": true}', '["supervisor", "manager"]', 'Отклонить', '#EF4444', 'x-circle', 2);

-- Insert approval routing rules
INSERT INTO approval_routing_rules (workflow_id, rule_name, rule_name_ru, priority, conditions, approval_chain, escalation_rules, created_by) VALUES

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
INSERT INTO escalation_rules (workflow_id, state_id, escalation_name, escalation_name_ru, trigger_type, timeout_minutes, escalation_actions, escalation_level, created_by) VALUES

-- Vacation escalation rules
(1, 2, 'supervisor_timeout', 'Превышение времени ожидания руководителя', 'time_based', 2880, -- 48 hours
'{"notify": ["manager", "hr_specialist"], "escalate_to": "manager", "add_urgency": true}', 1, 1),

(1, 3, 'hr_timeout', 'Превышение времени ожидания HR', 'time_based', 1440, -- 24 hours
'{"notify": ["hr_manager", "supervisor"], "escalate_to": "hr_manager", "mark_urgent": true}', 1, 1),

-- Overtime escalation rules
(2, 8, 'supervisor_overtime_timeout', 'Превышение времени согласования сверхурочной работы', 'time_based', 1440, -- 24 hours
'{"notify": ["manager"], "escalate_to": "manager", "highlight_business_impact": true}', 1, 1),

(2, 9, 'manager_overtime_timeout', 'Превышение времени утверждения сверхурочной работы', 'time_based', 720, -- 12 hours
'{"notify": ["department_head"], "escalate_to": "department_head", "mark_critical": true}', 1, 1),

-- Shift exchange escalation rules
(3, 13, 'counterpart_response_timeout', 'Превышение времени ответа коллеги', 'time_based', 720, -- 12 hours
'{"notify": ["supervisor", "requester"], "send_reminder": true, "mark_urgent": true}', 1, 1),

(3, 14, 'supervisor_exchange_timeout', 'Превышение времени согласования обмена', 'time_based', 480, -- 8 hours
'{"notify": ["manager"], "escalate_to": "manager", "highlight_operational_impact": true}', 1, 1);

-- Test query to verify complete workflow configuration
SELECT 
    wd.workflow_name,
    wd.display_name_ru,
    COUNT(DISTINCT ws.id) as states_count,
    COUNT(DISTINCT wt.id) as transitions_count,
    COUNT(DISTINCT arr.id) as approval_rules_count,
    COUNT(DISTINCT er.id) as escalation_rules_count
FROM workflow_definitions wd
LEFT JOIN workflow_states ws ON wd.id = ws.workflow_id
LEFT JOIN workflow_transitions wt ON wd.id = wt.workflow_id
LEFT JOIN approval_routing_rules arr ON wd.id = arr.workflow_id
LEFT JOIN escalation_rules er ON wd.id = er.workflow_id
GROUP BY wd.id, wd.workflow_name, wd.display_name_ru
ORDER BY wd.workflow_name;

-- Verification query for state machine completeness
SELECT 
    wd.workflow_name,
    ws.state_key,
    ws.state_name_ru,
    ws.state_type,
    COUNT(wt_from.id) as outgoing_transitions,
    COUNT(wt_to.id) as incoming_transitions
FROM workflow_definitions wd
JOIN workflow_states ws ON wd.id = ws.workflow_id
LEFT JOIN workflow_transitions wt_from ON ws.id = wt_from.from_state_id
LEFT JOIN workflow_transitions wt_to ON ws.id = wt_to.to_state_id
GROUP BY wd.id, wd.workflow_name, ws.id, ws.state_key, ws.state_name_ru, ws.state_type
ORDER BY wd.workflow_name, ws.sort_order;