-- Schema 128: Comprehensive Notification and Communication System
-- Based on BDD scenarios from 14-mobile-personal-cabinet.feature, 13-business-process-management-workflows.feature
-- Implements 15 notification system tables for complete multi-channel communication

-- Drop existing tables if they exist
DROP TABLE IF EXISTS notification_audit CASCADE;
DROP TABLE IF EXISTS notification_compliance CASCADE;
DROP TABLE IF EXISTS notification_feedback CASCADE;
DROP TABLE IF EXISTS notification_analytics CASCADE;
DROP TABLE IF EXISTS notification_digest CASCADE;
DROP TABLE IF EXISTS notification_escalations CASCADE;
DROP TABLE IF EXISTS notification_rules CASCADE;
DROP TABLE IF EXISTS notification_subscriptions CASCADE;
DROP TABLE IF EXISTS notification_retries CASCADE;
DROP TABLE IF EXISTS notification_failures CASCADE;
DROP TABLE IF EXISTS notification_history CASCADE;
DROP TABLE IF EXISTS notification_delivery CASCADE;
DROP TABLE IF EXISTS notification_preferences CASCADE;
DROP TABLE IF EXISTS notification_channels CASCADE;
DROP TABLE IF EXISTS notification_templates CASCADE;

-- 1. Notification Templates (Шаблоны уведомлений)
CREATE TABLE notification_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_name_ru VARCHAR(100) NOT NULL UNIQUE,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('EMAIL', 'SMS', 'PUSH', 'SYSTEM', 'DIGEST')),
    category VARCHAR(50) NOT NULL CHECK (category IN ('SCHEDULE', 'REQUEST', 'WORKFLOW', 'REMINDER', 'ALERT', 'SYSTEM', 'DIGEST')),
    subject_template VARCHAR(200),
    subject_template_ru VARCHAR(200),
    body_template TEXT NOT NULL,
    body_template_ru TEXT NOT NULL,
    variable_mapping JSONB, -- Template variables and their data sources
    formatting_rules JSONB, -- Formatting options (HTML, plain text, etc.)
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    is_active BOOLEAN DEFAULT TRUE,
    requires_approval BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Notification Channels (Каналы уведомлений)
CREATE TABLE notification_channels (
    id SERIAL PRIMARY KEY,
    channel_name VARCHAR(50) NOT NULL UNIQUE,
    channel_name_ru VARCHAR(50) NOT NULL UNIQUE,
    channel_type VARCHAR(20) NOT NULL CHECK (channel_type IN ('EMAIL', 'SMS', 'PUSH', 'SYSTEM', 'WEBHOOK')),
    provider VARCHAR(50), -- Email provider, SMS gateway, etc.
    configuration JSONB NOT NULL, -- Channel-specific configuration
    authentication_config JSONB, -- Authentication settings
    rate_limits JSONB, -- Rate limiting configuration
    retry_config JSONB, -- Retry settings
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    health_status VARCHAR(20) DEFAULT 'HEALTHY' CHECK (health_status IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY')),
    last_health_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Notification Preferences (Предпочтения пользователей)
CREATE TABLE notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES employees(id),
    notification_category VARCHAR(50) NOT NULL,
    channel_type VARCHAR(20) NOT NULL CHECK (channel_type IN ('EMAIL', 'SMS', 'PUSH', 'SYSTEM')),
    is_enabled BOOLEAN DEFAULT TRUE,
    priority_threshold VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority_threshold IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    quiet_hours_start TIME, -- Start of quiet hours
    quiet_hours_end TIME, -- End of quiet hours
    quiet_hours_timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    frequency_limit INTEGER DEFAULT 0, -- Max notifications per hour (0 = no limit)
    digest_frequency VARCHAR(20) DEFAULT 'NONE' CHECK (digest_frequency IN ('NONE', 'HOURLY', 'DAILY', 'WEEKLY')),
    language_preference VARCHAR(10) DEFAULT 'RU' CHECK (language_preference IN ('RU', 'EN')),
    format_preference VARCHAR(20) DEFAULT 'HTML' CHECK (format_preference IN ('HTML', 'PLAIN', 'MARKDOWN')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_category, channel_type)
);

-- 4. Notification Delivery (Доставка уведомлений)
CREATE TABLE notification_delivery (
    id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES notification_templates(id),
    channel_id INTEGER REFERENCES notification_channels(id),
    recipient_id INTEGER REFERENCES employees(id),
    recipient_contact VARCHAR(255) NOT NULL, -- Email, phone, device token
    subject VARCHAR(200),
    message_body TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'CANCELLED')),
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    failed_at TIMESTAMP,
    attempts_count INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    tracking_id VARCHAR(100), -- External tracking ID
    metadata JSONB, -- Additional delivery metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Notification History (История уведомлений)
CREATE TABLE notification_history (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES notification_delivery(id),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('CREATED', 'SCHEDULED', 'SENT', 'DELIVERED', 'FAILED', 'CANCELLED', 'RETRY')),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_data JSONB,
    error_details TEXT,
    system_info JSONB, -- System state at event time
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Notification Failures (Сбои уведомлений)
CREATE TABLE notification_failures (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES notification_delivery(id),
    failure_type VARCHAR(50) NOT NULL CHECK (failure_type IN ('NETWORK', 'AUTHENTICATION', 'QUOTA_EXCEEDED', 'INVALID_RECIPIENT', 'CONTENT_REJECTED', 'TIMEOUT')),
    failure_reason TEXT NOT NULL,
    failure_details JSONB,
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_retryable BOOLEAN DEFAULT TRUE,
    retry_after TIMESTAMP,
    escalation_level INTEGER DEFAULT 0,
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Notification Retries (Повторные попытки)
CREATE TABLE notification_retries (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES notification_delivery(id),
    retry_number INTEGER NOT NULL,
    retry_strategy VARCHAR(50) NOT NULL CHECK (retry_strategy IN ('IMMEDIATE', 'EXPONENTIAL_BACKOFF', 'FIXED_DELAY', 'CUSTOM')),
    retry_delay_seconds INTEGER NOT NULL,
    scheduled_retry_at TIMESTAMP NOT NULL,
    attempted_at TIMESTAMP,
    retry_result VARCHAR(20) CHECK (retry_result IN ('SUCCESS', 'FAILED', 'SKIPPED')),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Notification Subscriptions (Подписки на уведомления)
CREATE TABLE notification_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES employees(id),
    subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('INDIVIDUAL', 'GROUP', 'DEPARTMENT', 'ROLE_BASED', 'GLOBAL')),
    target_entity_type VARCHAR(50) NOT NULL, -- 'schedule', 'workflow', 'request', etc.
    target_entity_id INTEGER, -- Specific entity ID if applicable
    filter_criteria JSONB, -- Advanced filtering rules
    notification_categories TEXT[] NOT NULL, -- Array of categories to subscribe to
    preferred_channels TEXT[] NOT NULL, -- Array of preferred delivery channels
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE(user_id, subscription_type, target_entity_type, target_entity_id)
);

-- 9. Notification Rules (Правила уведомлений)
CREATE TABLE notification_rules (
    id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_name_ru VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('TRIGGER', 'FILTER', 'ROUTING', 'ESCALATION', 'THROTTLING')),
    entity_type VARCHAR(50) NOT NULL, -- What triggers the notification
    condition_expression TEXT NOT NULL, -- SQL or logic expression
    action_expression TEXT NOT NULL, -- Action to take when condition is met
    template_id INTEGER REFERENCES notification_templates(id),
    target_channels TEXT[], -- Array of channels to use
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    is_active BOOLEAN DEFAULT TRUE,
    execution_order INTEGER DEFAULT 1,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Notification Escalations (Эскалация уведомлений)
CREATE TABLE notification_escalations (
    id SERIAL PRIMARY KEY,
    original_delivery_id INTEGER REFERENCES notification_delivery(id),
    escalation_level INTEGER NOT NULL CHECK (escalation_level BETWEEN 1 AND 5),
    escalation_reason VARCHAR(100) NOT NULL,
    escalation_reason_ru VARCHAR(100) NOT NULL,
    escalated_to_user_id INTEGER REFERENCES employees(id),
    escalated_to_role VARCHAR(100),
    escalation_template_id INTEGER REFERENCES notification_templates(id),
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Notification Digest (Дайджест уведомлений)
CREATE TABLE notification_digest (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES employees(id),
    digest_type VARCHAR(20) NOT NULL CHECK (digest_type IN ('HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY')),
    digest_period_start TIMESTAMP NOT NULL,
    digest_period_end TIMESTAMP NOT NULL,
    notification_count INTEGER DEFAULT 0,
    digest_content JSONB NOT NULL, -- Grouped notifications
    digest_status VARCHAR(20) DEFAULT 'PENDING' CHECK (digest_status IN ('PENDING', 'GENERATED', 'SENT', 'FAILED')),
    generated_at TIMESTAMP,
    sent_at TIMESTAMP,
    template_id INTEGER REFERENCES notification_templates(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Notification Analytics (Аналитика уведомлений)
CREATE TABLE notification_analytics (
    id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    metric_hour INTEGER CHECK (metric_hour BETWEEN 0 AND 23),
    channel_type VARCHAR(20) NOT NULL,
    template_id INTEGER REFERENCES notification_templates(id),
    notifications_sent INTEGER DEFAULT 0,
    notifications_delivered INTEGER DEFAULT 0,
    notifications_failed INTEGER DEFAULT 0,
    delivery_rate DECIMAL(5,2), -- Percentage
    average_delivery_time_seconds INTEGER,
    bounce_rate DECIMAL(5,2), -- Percentage
    engagement_rate DECIMAL(5,2), -- Percentage (for push notifications)
    cost_per_notification DECIMAL(10,4), -- Cost tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(metric_date, metric_hour, channel_type, template_id)
);

-- 13. Notification Feedback (Обратная связь)
CREATE TABLE notification_feedback (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES notification_delivery(id),
    user_id INTEGER REFERENCES employees(id),
    feedback_type VARCHAR(50) NOT NULL CHECK (feedback_type IN ('CLICK', 'OPEN', 'DISMISS', 'UNSUBSCRIBE', 'SPAM_REPORT', 'RATING')),
    feedback_value VARCHAR(100), -- Rating value, click URL, etc.
    feedback_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    additional_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Notification Compliance (Соответствие требованиям)
CREATE TABLE notification_compliance (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES notification_delivery(id),
    compliance_type VARCHAR(50) NOT NULL CHECK (compliance_type IN ('GDPR', 'SPAM_COMPLIANCE', 'RETENTION_POLICY', 'AUDIT_TRAIL')),
    compliance_status VARCHAR(20) NOT NULL CHECK (compliance_status IN ('COMPLIANT', 'NON_COMPLIANT', 'PENDING_REVIEW')),
    compliance_details JSONB,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    action_required TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. Notification Audit (Аудит уведомлений)
CREATE TABLE notification_audit (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    action_ru VARCHAR(50) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    performed_by INTEGER REFERENCES employees(id),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    additional_context JSONB
);

-- Indexes for performance optimization

-- Core notification delivery indexes
CREATE INDEX idx_notification_delivery_status ON notification_delivery(status);
CREATE INDEX idx_notification_delivery_recipient ON notification_delivery(recipient_id);
CREATE INDEX idx_notification_delivery_scheduled ON notification_delivery(scheduled_at);
CREATE INDEX idx_notification_delivery_channel ON notification_delivery(channel_id);
CREATE INDEX idx_notification_delivery_template ON notification_delivery(template_id);
CREATE INDEX idx_notification_delivery_priority ON notification_delivery(priority);

-- Notification preferences indexes
CREATE INDEX idx_notification_preferences_user ON notification_preferences(user_id);
CREATE INDEX idx_notification_preferences_category ON notification_preferences(notification_category);
CREATE INDEX idx_notification_preferences_enabled ON notification_preferences(is_enabled);

-- Notification history indexes
CREATE INDEX idx_notification_history_delivery ON notification_history(delivery_id);
CREATE INDEX idx_notification_history_event_type ON notification_history(event_type);
CREATE INDEX idx_notification_history_timestamp ON notification_history(event_timestamp);

-- Notification failures indexes
CREATE INDEX idx_notification_failures_delivery ON notification_failures(delivery_id);
CREATE INDEX idx_notification_failures_type ON notification_failures(failure_type);
CREATE INDEX idx_notification_failures_retryable ON notification_failures(is_retryable);
CREATE INDEX idx_notification_failures_occurred ON notification_failures(occurred_at);

-- Notification retries indexes
CREATE INDEX idx_notification_retries_delivery ON notification_retries(delivery_id);
CREATE INDEX idx_notification_retries_scheduled ON notification_retries(scheduled_retry_at);
CREATE INDEX idx_notification_retries_result ON notification_retries(retry_result);

-- Notification subscriptions indexes
CREATE INDEX idx_notification_subscriptions_user ON notification_subscriptions(user_id);
CREATE INDEX idx_notification_subscriptions_type ON notification_subscriptions(subscription_type);
CREATE INDEX idx_notification_subscriptions_entity ON notification_subscriptions(target_entity_type, target_entity_id);
CREATE INDEX idx_notification_subscriptions_active ON notification_subscriptions(is_active);

-- Notification rules indexes
CREATE INDEX idx_notification_rules_type ON notification_rules(rule_type);
CREATE INDEX idx_notification_rules_entity ON notification_rules(entity_type);
CREATE INDEX idx_notification_rules_active ON notification_rules(is_active);
CREATE INDEX idx_notification_rules_order ON notification_rules(execution_order);

-- Notification escalations indexes
CREATE INDEX idx_notification_escalations_original ON notification_escalations(original_delivery_id);
CREATE INDEX idx_notification_escalations_level ON notification_escalations(escalation_level);
CREATE INDEX idx_notification_escalations_user ON notification_escalations(escalated_to_user_id);
CREATE INDEX idx_notification_escalations_resolved ON notification_escalations(is_resolved);

-- Notification digest indexes
CREATE INDEX idx_notification_digest_user ON notification_digest(user_id);
CREATE INDEX idx_notification_digest_type ON notification_digest(digest_type);
CREATE INDEX idx_notification_digest_period ON notification_digest(digest_period_start, digest_period_end);
CREATE INDEX idx_notification_digest_status ON notification_digest(digest_status);

-- Notification analytics indexes
CREATE INDEX idx_notification_analytics_date ON notification_analytics(metric_date);
CREATE INDEX idx_notification_analytics_channel ON notification_analytics(channel_type);
CREATE INDEX idx_notification_analytics_template ON notification_analytics(template_id);
CREATE INDEX idx_notification_analytics_composite ON notification_analytics(metric_date, channel_type, template_id);

-- Notification feedback indexes
CREATE INDEX idx_notification_feedback_delivery ON notification_feedback(delivery_id);
CREATE INDEX idx_notification_feedback_user ON notification_feedback(user_id);
CREATE INDEX idx_notification_feedback_type ON notification_feedback(feedback_type);
CREATE INDEX idx_notification_feedback_timestamp ON notification_feedback(feedback_timestamp);

-- Notification compliance indexes
CREATE INDEX idx_notification_compliance_delivery ON notification_compliance(delivery_id);
CREATE INDEX idx_notification_compliance_type ON notification_compliance(compliance_type);
CREATE INDEX idx_notification_compliance_status ON notification_compliance(compliance_status);
CREATE INDEX idx_notification_compliance_expires ON notification_compliance(expires_at);

-- Notification audit indexes
CREATE INDEX idx_notification_audit_entity ON notification_audit(entity_type, entity_id);
CREATE INDEX idx_notification_audit_performed_by ON notification_audit(performed_by);
CREATE INDEX idx_notification_audit_performed_at ON notification_audit(performed_at);
CREATE INDEX idx_notification_audit_action ON notification_audit(action);

-- JSONB indexes for efficient queries
CREATE INDEX idx_notification_templates_variables ON notification_templates USING GIN (variable_mapping);
CREATE INDEX idx_notification_channels_config ON notification_channels USING GIN (configuration);
CREATE INDEX idx_notification_delivery_metadata ON notification_delivery USING GIN (metadata);
CREATE INDEX idx_notification_subscriptions_filter ON notification_subscriptions USING GIN (filter_criteria);
CREATE INDEX idx_notification_digest_content ON notification_digest USING GIN (digest_content);
-- Complex analytics JSON indexing removed due to mutability constraints

-- Composite indexes for common queries
CREATE INDEX idx_notification_delivery_status_scheduled ON notification_delivery(status, scheduled_at);
CREATE INDEX idx_notification_delivery_recipient_status ON notification_delivery(recipient_id, status);
CREATE INDEX idx_notification_preferences_user_category ON notification_preferences(user_id, notification_category);
CREATE INDEX idx_notification_rules_entity_active ON notification_rules(entity_type, is_active);
CREATE INDEX idx_notification_failures_type_retryable ON notification_failures(failure_type, is_retryable);

-- Insert initial notification channels
INSERT INTO notification_channels (channel_name, channel_name_ru, channel_type, provider, configuration, rate_limits) VALUES
('System Email', 'Системная почта', 'EMAIL', 'SMTP', 
 '{"smtp_host": "smtp.company.com", "smtp_port": 587, "use_tls": true, "from_address": "noreply@company.com"}',
 '{"max_per_minute": 100, "max_per_hour": 1000, "max_per_day": 10000}'),
('SMS Gateway', 'SMS шлюз', 'SMS', 'SMS_PROVIDER', 
 '{"api_endpoint": "https://sms.provider.com/api", "username": "api_user", "sender_id": "WFM"}',
 '{"max_per_minute": 50, "max_per_hour": 500, "max_per_day": 2000}'),
('Push Notifications', 'Push уведомления', 'PUSH', 'FIREBASE', 
 '{"firebase_server_key": "xxx", "project_id": "wfm-mobile"}',
 '{"max_per_minute": 1000, "max_per_hour": 5000, "max_per_day": 50000}'),
('System Internal', 'Системные внутренние', 'SYSTEM', 'INTERNAL', 
 '{"queue_type": "internal", "persistence": true}',
 '{"max_per_minute": 10000, "max_per_hour": 100000, "max_per_day": 1000000}');

-- Insert notification templates for key scenarios
INSERT INTO notification_templates (template_name, template_name_ru, template_type, category, subject_template, subject_template_ru, body_template, body_template_ru, variable_mapping, priority) VALUES
('Break Reminder', 'Напоминание о перерыве', 'PUSH', 'REMINDER', 'Break time in 5 minutes', 'Перерыв через 5 минут', 
 'Your break is scheduled to start in 5 minutes. Please prepare to wrap up your current call.', 
 'Ваш перерыв запланирован через 5 минут. Пожалуйста, подготовьтесь к завершению текущего звонка.',
 '{"break_time": "timestamp", "break_duration": "integer"}', 'MEDIUM'),
('Lunch Reminder', 'Напоминание об обеде', 'PUSH', 'REMINDER', 'Lunch time in 10 minutes', 'Обед через 10 минут',
 'Your lunch break is scheduled to start in 10 minutes. Please prepare to wrap up your current activities.',
 'Ваш обеденный перерыв запланирован через 10 минут. Пожалуйста, подготовьтесь к завершению текущих дел.',
 '{"lunch_time": "timestamp", "lunch_duration": "integer"}', 'MEDIUM'),
('Schedule Change', 'Изменение расписания', 'EMAIL', 'ALERT', 'Schedule Update - {{schedule_date}}', 'Обновление расписания - {{schedule_date}}',
 'Your work schedule has been updated for {{schedule_date}}. Please review the changes and acknowledge receipt.',
 'Ваше рабочее расписание обновлено на {{schedule_date}}. Пожалуйста, ознакомьтесь с изменениями и подтвердите получение.',
 '{"schedule_date": "date", "changes": "array", "acknowledgment_url": "string"}', 'HIGH'),
('Request Status Update', 'Обновление статуса заявки', 'EMAIL', 'WORKFLOW', 'Request {{request_id}} Status: {{status}}', 'Заявка {{request_id}} Статус: {{status}}',
 'Your request #{{request_id}} ({{request_type}}) has been {{status}}. {{additional_info}}',
 'Ваша заявка #{{request_id}} ({{request_type}}) была {{status}}. {{additional_info}}',
 '{"request_id": "string", "request_type": "string", "status": "string", "additional_info": "string"}', 'MEDIUM'),
('Meeting Reminder', 'Напоминание о встрече', 'EMAIL', 'REMINDER', 'Meeting Reminder: {{meeting_title}}', 'Напоминание о встрече: {{meeting_title}}',
 'This is a reminder about your upcoming meeting "{{meeting_title}}" scheduled for {{meeting_time}}.',
 'Это напоминание о предстоящей встрече "{{meeting_title}}", запланированной на {{meeting_time}}.',
 '{"meeting_title": "string", "meeting_time": "timestamp", "meeting_location": "string"}', 'MEDIUM'),
('Shift Exchange Response', 'Ответ на обмен сменами', 'PUSH', 'WORKFLOW', 'Shift Exchange Update', 'Обновление обмена сменами',
 'Your shift exchange request has been {{action}} by {{responder_name}}. {{additional_details}}',
 'Ваш запрос на обмен сменами был {{action}} пользователем {{responder_name}}. {{additional_details}}',
 '{"action": "string", "responder_name": "string", "additional_details": "string"}', 'HIGH'),
('Task Escalation', 'Эскалация задачи', 'EMAIL', 'ALERT', 'Task Escalation: {{task_title}}', 'Эскалация задачи: {{task_title}}',
 'Task "{{task_title}}" has been escalated to you due to {{escalation_reason}}. Please take action by {{due_date}}.',
 'Задача "{{task_title}}" была эскалирована вам из-за {{escalation_reason}}. Пожалуйста, примите меры до {{due_date}}.',
 '{"task_title": "string", "escalation_reason": "string", "due_date": "timestamp"}', 'URGENT'),
('Daily Digest', 'Ежедневный дайджест', 'EMAIL', 'DIGEST', 'Daily Summary - {{date}}', 'Ежедневная сводка - {{date}}',
 'Your daily summary for {{date}}: {{notification_count}} notifications received. {{summary_content}}',
 'Ваша ежедневная сводка за {{date}}: получено {{notification_count}} уведомлений. {{summary_content}}',
 '{"date": "date", "notification_count": "integer", "summary_content": "string"}', 'LOW');

-- Insert notification rules for automatic triggers
INSERT INTO notification_rules (rule_name, rule_name_ru, rule_type, entity_type, condition_expression, action_expression, template_id, target_channels, priority) VALUES
('Break Reminder Rule', 'Правило напоминания о перерыве', 'TRIGGER', 'schedule', 
 'break_start_time - CURRENT_TIMESTAMP = INTERVAL ''5 minutes''', 
 'send_notification_to_employee', 1, ARRAY['PUSH'], 'MEDIUM'),
('Lunch Reminder Rule', 'Правило напоминания об обеде', 'TRIGGER', 'schedule',
 'lunch_start_time - CURRENT_TIMESTAMP = INTERVAL ''10 minutes''',
 'send_notification_to_employee', 2, ARRAY['PUSH'], 'MEDIUM'),
('Schedule Change Rule', 'Правило изменения расписания', 'TRIGGER', 'schedule',
 'schedule_status = ''UPDATED'' AND notification_sent = FALSE',
 'send_notification_to_affected_employees', 3, ARRAY['EMAIL', 'PUSH'], 'HIGH'),
('Request Status Rule', 'Правило статуса заявки', 'TRIGGER', 'employee_request',
 'status_changed = TRUE AND status != ''PENDING''',
 'send_notification_to_requester', 4, ARRAY['EMAIL', 'SYSTEM'], 'MEDIUM'),
('Task Escalation Rule', 'Правило эскалации задач', 'TRIGGER', 'workflow_task',
 'due_date < CURRENT_TIMESTAMP AND status = ''PENDING''',
 'escalate_to_supervisor', 7, ARRAY['EMAIL', 'SMS'], 'URGENT');

-- Insert sample notification preferences for different user types
INSERT INTO notification_preferences (user_id, notification_category, channel_type, is_enabled, priority_threshold, quiet_hours_start, quiet_hours_end) VALUES
(1, 'SCHEDULE', 'EMAIL', TRUE, 'MEDIUM', '22:00', '08:00'),
(1, 'SCHEDULE', 'PUSH', TRUE, 'HIGH', '22:00', '08:00'),
(1, 'REQUEST', 'EMAIL', TRUE, 'MEDIUM', '22:00', '08:00'),
(1, 'REQUEST', 'PUSH', TRUE, 'HIGH', '22:00', '08:00'),
(1, 'WORKFLOW', 'EMAIL', TRUE, 'MEDIUM', '22:00', '08:00'),
(1, 'REMINDER', 'PUSH', TRUE, 'MEDIUM', '22:00', '08:00'),
(1, 'ALERT', 'EMAIL', TRUE, 'HIGH', NULL, NULL),
(1, 'ALERT', 'SMS', TRUE, 'URGENT', NULL, NULL),
(2, 'SCHEDULE', 'EMAIL', TRUE, 'MEDIUM', '23:00', '07:00'),
(2, 'SCHEDULE', 'PUSH', TRUE, 'HIGH', '23:00', '07:00'),
(2, 'REQUEST', 'EMAIL', TRUE, 'MEDIUM', '23:00', '07:00'),
(2, 'WORKFLOW', 'EMAIL', TRUE, 'MEDIUM', '23:00', '07:00'),
(2, 'REMINDER', 'PUSH', TRUE, 'MEDIUM', '23:00', '07:00'),
(2, 'ALERT', 'EMAIL', TRUE, 'HIGH', NULL, NULL);

-- Insert sample notification subscriptions
INSERT INTO notification_subscriptions (user_id, subscription_type, target_entity_type, notification_categories, preferred_channels, filter_criteria) VALUES
(1, 'INDIVIDUAL', 'schedule', ARRAY['SCHEDULE', 'REMINDER'], ARRAY['EMAIL', 'PUSH'], 
 '{"only_my_schedule": true, "include_changes": true}'),
(1, 'INDIVIDUAL', 'employee_request', ARRAY['REQUEST', 'WORKFLOW'], ARRAY['EMAIL', 'SYSTEM'],
 '{"only_my_requests": true, "include_status_updates": true}'),
(1, 'DEPARTMENT', 'schedule', ARRAY['ALERT'], ARRAY['EMAIL'],
 '{"department_id": 1, "priority_only": "HIGH"}'),
(2, 'INDIVIDUAL', 'schedule', ARRAY['SCHEDULE', 'REMINDER'], ARRAY['EMAIL', 'PUSH'],
 '{"only_my_schedule": true, "include_changes": true}'),
(2, 'ROLE_BASED', 'workflow_task', ARRAY['WORKFLOW', 'ALERT'], ARRAY['EMAIL', 'SMS'],
 '{"role": "supervisor", "escalation_level": 1}');

-- Add table comments for documentation
COMMENT ON TABLE notification_templates IS 'Шаблоны уведомлений с поддержкой мультиязычности';
COMMENT ON TABLE notification_channels IS 'Каналы доставки уведомлений (Email, SMS, Push, System)';
COMMENT ON TABLE notification_preferences IS 'Пользовательские предпочтения уведомлений';
COMMENT ON TABLE notification_delivery IS 'Доставка уведомлений с отслеживанием статуса';
COMMENT ON TABLE notification_history IS 'История событий уведомлений';
COMMENT ON TABLE notification_failures IS 'Сбои доставки уведомлений и их обработка';
COMMENT ON TABLE notification_retries IS 'Повторные попытки доставки уведомлений';
COMMENT ON TABLE notification_subscriptions IS 'Подписки пользователей на уведомления';
COMMENT ON TABLE notification_rules IS 'Правила автоматической отправки уведомлений';
COMMENT ON TABLE notification_escalations IS 'Эскалация уведомлений при сбоях';
COMMENT ON TABLE notification_digest IS 'Дайджест уведомлений по расписанию';
COMMENT ON TABLE notification_analytics IS 'Аналитика эффективности уведомлений';
COMMENT ON TABLE notification_feedback IS 'Обратная связь по уведомлениям';
COMMENT ON TABLE notification_compliance IS 'Соответствие требованиям (GDPR, etc.)';
COMMENT ON TABLE notification_audit IS 'Аудиторский след действий с уведомлениями';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Success message
SELECT 'Schema 128: Comprehensive Notification and Communication System created successfully with 15 tables, 4 channels, 8 templates, and Russian language support' AS status;