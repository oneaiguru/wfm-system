-- =====================================================================================
-- Real-Time Monitoring Schema - Version 1.0
-- Created: 2025-07-11
-- Purpose: Complete real-time monitoring system for WFM with WebSocket integration
-- Performance: <100ms update latency, 1000+ concurrent connections
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =====================================================================================
-- 1. REALTIME_QUEUES - Live queue status tracking
-- =====================================================================================

CREATE TABLE realtime_queues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_id VARCHAR(100) NOT NULL,
    queue_name VARCHAR(200) NOT NULL,
    queue_type VARCHAR(50) NOT NULL DEFAULT 'voice',
    
    -- Current status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    current_calls INTEGER DEFAULT 0,
    waiting_calls INTEGER DEFAULT 0,
    agents_available INTEGER DEFAULT 0,
    agents_busy INTEGER DEFAULT 0,
    agents_total INTEGER DEFAULT 0,
    
    -- Performance metrics
    avg_wait_time DECIMAL(10,2) DEFAULT 0,
    avg_handle_time DECIMAL(10,2) DEFAULT 0,
    service_level DECIMAL(5,2) DEFAULT 0,
    abandon_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Timestamps
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_queues_status_check CHECK (status IN ('active', 'paused', 'disabled')),
    CONSTRAINT realtime_queues_queue_type_check CHECK (queue_type IN ('voice', 'chat', 'email', 'video')),
    CONSTRAINT realtime_queues_metrics_check CHECK (
        current_calls >= 0 AND waiting_calls >= 0 AND
        agents_available >= 0 AND agents_busy >= 0 AND agents_total >= 0
    )
);

-- Indexes for realtime_queues
CREATE UNIQUE INDEX idx_realtime_queues_queue_id ON realtime_queues(queue_id);
CREATE INDEX idx_realtime_queues_status ON realtime_queues(status);
CREATE INDEX idx_realtime_queues_type ON realtime_queues(queue_type);
CREATE INDEX idx_realtime_queues_updated ON realtime_queues(last_updated);
CREATE INDEX idx_realtime_queues_performance ON realtime_queues(service_level, abandon_rate);

-- =====================================================================================
-- 2. REALTIME_AGENTS - Agent status and activity tracking
-- =====================================================================================

CREATE TABLE realtime_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id VARCHAR(100) NOT NULL,
    agent_name VARCHAR(200) NOT NULL,
    
    -- Current status
    status VARCHAR(20) NOT NULL DEFAULT 'offline',
    state VARCHAR(20) NOT NULL DEFAULT 'idle',
    queue_id VARCHAR(100),
    
    -- Current activity
    current_call_id UUID,
    call_start_time TIMESTAMP WITH TIME ZONE,
    session_start_time TIMESTAMP WITH TIME ZONE,
    
    -- Performance metrics
    calls_handled INTEGER DEFAULT 0,
    avg_handle_time DECIMAL(10,2) DEFAULT 0,
    occupancy_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Location and device
    location VARCHAR(100),
    device_type VARCHAR(50),
    ip_address INET,
    
    -- Timestamps
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_agents_status_check CHECK (status IN ('online', 'offline', 'break', 'training')),
    CONSTRAINT realtime_agents_state_check CHECK (state IN ('idle', 'busy', 'wrap_up', 'not_ready')),
    CONSTRAINT realtime_agents_metrics_check CHECK (
        calls_handled >= 0 AND avg_handle_time >= 0 AND
        occupancy_rate >= 0 AND occupancy_rate <= 100
    )
);

-- Indexes for realtime_agents
CREATE UNIQUE INDEX idx_realtime_agents_agent_id ON realtime_agents(agent_id);
CREATE INDEX idx_realtime_agents_status ON realtime_agents(status);
CREATE INDEX idx_realtime_agents_state ON realtime_agents(state);
CREATE INDEX idx_realtime_agents_queue ON realtime_agents(queue_id);
CREATE INDEX idx_realtime_agents_activity ON realtime_agents(last_activity);
CREATE INDEX idx_realtime_agents_current_call ON realtime_agents(current_call_id);

-- =====================================================================================
-- 3. REALTIME_CALLS - Active call tracking
-- =====================================================================================

CREATE TABLE realtime_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id VARCHAR(100) NOT NULL,
    
    -- Call details
    call_type VARCHAR(20) NOT NULL DEFAULT 'inbound',
    queue_id VARCHAR(100),
    agent_id VARCHAR(100),
    
    -- Contact information
    customer_id VARCHAR(100),
    phone_number VARCHAR(20),
    
    -- Call status
    status VARCHAR(20) NOT NULL DEFAULT 'waiting',
    priority INTEGER DEFAULT 1,
    
    -- Timing
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    answer_time TIMESTAMP WITH TIME ZONE,
    wait_time DECIMAL(10,2) DEFAULT 0,
    talk_time DECIMAL(10,2) DEFAULT 0,
    
    -- Additional data
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_calls_type_check CHECK (call_type IN ('inbound', 'outbound', 'internal')),
    CONSTRAINT realtime_calls_status_check CHECK (status IN ('waiting', 'ringing', 'connected', 'hold', 'completed')),
    CONSTRAINT realtime_calls_priority_check CHECK (priority >= 1 AND priority <= 10),
    CONSTRAINT realtime_calls_timing_check CHECK (wait_time >= 0 AND talk_time >= 0)
);

-- Indexes for realtime_calls
CREATE UNIQUE INDEX idx_realtime_calls_call_id ON realtime_calls(call_id);
CREATE INDEX idx_realtime_calls_status ON realtime_calls(status);
CREATE INDEX idx_realtime_calls_queue ON realtime_calls(queue_id);
CREATE INDEX idx_realtime_calls_agent ON realtime_calls(agent_id);
CREATE INDEX idx_realtime_calls_priority ON realtime_calls(priority DESC);
CREATE INDEX idx_realtime_calls_start_time ON realtime_calls(start_time);
CREATE INDEX idx_realtime_calls_customer ON realtime_calls(customer_id);

-- =====================================================================================
-- 4. REALTIME_PERFORMANCE - Performance metrics tracking
-- =====================================================================================

CREATE TABLE realtime_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    
    -- Metric values
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(20) DEFAULT 'count',
    
    -- Context
    queue_id VARCHAR(100),
    agent_id VARCHAR(100),
    interval_type VARCHAR(20) DEFAULT 'realtime',
    
    -- Timestamps
    measurement_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_performance_entity_type_check CHECK (entity_type IN ('queue', 'agent', 'system', 'campaign')),
    CONSTRAINT realtime_performance_interval_check CHECK (interval_type IN ('realtime', '1min', '5min', '15min', '30min', '1hour'))
);

-- Indexes for realtime_performance
CREATE INDEX idx_realtime_performance_entity ON realtime_performance(entity_type, entity_id);
CREATE INDEX idx_realtime_performance_metric ON realtime_performance(metric_type, metric_name);
CREATE INDEX idx_realtime_performance_time ON realtime_performance(measurement_time);
CREATE INDEX idx_realtime_performance_queue ON realtime_performance(queue_id);
CREATE INDEX idx_realtime_performance_agent ON realtime_performance(agent_id);
CREATE INDEX idx_realtime_performance_interval ON realtime_performance(interval_type);

-- =====================================================================================
-- 5. REALTIME_SLA - Service level tracking
-- =====================================================================================

CREATE TABLE realtime_sla (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sla_name VARCHAR(100) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    
    -- SLA definition
    metric_type VARCHAR(50) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    threshold_warning DECIMAL(10,2),
    threshold_critical DECIMAL(10,2),
    
    -- Current status
    current_value DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ok',
    breach_count INTEGER DEFAULT 0,
    
    -- Timestamps
    last_breach TIMESTAMP WITH TIME ZONE,
    last_calculated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_sla_entity_type_check CHECK (entity_type IN ('queue', 'agent', 'system')),
    CONSTRAINT realtime_sla_status_check CHECK (status IN ('ok', 'warning', 'critical', 'breach')),
    CONSTRAINT realtime_sla_values_check CHECK (
        target_value >= 0 AND current_value >= 0 AND breach_count >= 0
    )
);

-- Indexes for realtime_sla
CREATE INDEX idx_realtime_sla_entity ON realtime_sla(entity_type, entity_id);
CREATE INDEX idx_realtime_sla_name ON realtime_sla(sla_name);
CREATE INDEX idx_realtime_sla_status ON realtime_sla(status);
CREATE INDEX idx_realtime_sla_metric ON realtime_sla(metric_type);
CREATE INDEX idx_realtime_sla_calculated ON realtime_sla(last_calculated);

-- =====================================================================================
-- 6. REALTIME_ALERTS - Alert definitions and tracking
-- =====================================================================================

CREATE TABLE realtime_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_name VARCHAR(100) NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    
    -- Alert conditions
    condition_type VARCHAR(20) NOT NULL DEFAULT 'threshold',
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100),
    metric_name VARCHAR(100) NOT NULL,
    
    -- Thresholds
    threshold_value DECIMAL(15,4) NOT NULL,
    comparison_operator VARCHAR(10) NOT NULL DEFAULT '>',
    severity VARCHAR(20) NOT NULL DEFAULT 'medium',
    
    -- Alert status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    is_triggered BOOLEAN DEFAULT FALSE,
    trigger_count INTEGER DEFAULT 0,
    
    -- Notification settings
    notification_channels TEXT[],
    escalation_rules JSONB DEFAULT '{}',
    
    -- Timestamps
    last_triggered TIMESTAMP WITH TIME ZONE,
    last_checked TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_alerts_condition_check CHECK (condition_type IN ('threshold', 'trend', 'anomaly')),
    CONSTRAINT realtime_alerts_entity_check CHECK (entity_type IN ('queue', 'agent', 'system', 'campaign')),
    CONSTRAINT realtime_alerts_operator_check CHECK (comparison_operator IN ('>', '<', '>=', '<=', '=', '!=')),
    CONSTRAINT realtime_alerts_severity_check CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT realtime_alerts_status_check CHECK (status IN ('active', 'paused', 'disabled'))
);

-- Indexes for realtime_alerts
CREATE INDEX idx_realtime_alerts_type ON realtime_alerts(alert_type);
CREATE INDEX idx_realtime_alerts_entity ON realtime_alerts(entity_type, entity_id);
CREATE INDEX idx_realtime_alerts_metric ON realtime_alerts(metric_name);
CREATE INDEX idx_realtime_alerts_status ON realtime_alerts(status);
CREATE INDEX idx_realtime_alerts_triggered ON realtime_alerts(is_triggered);
CREATE INDEX idx_realtime_alerts_severity ON realtime_alerts(severity);
CREATE INDEX idx_realtime_alerts_checked ON realtime_alerts(last_checked);

-- =====================================================================================
-- 7. REALTIME_THRESHOLDS - Configurable thresholds
-- =====================================================================================

CREATE TABLE realtime_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    threshold_name VARCHAR(100) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100),
    
    -- Threshold configuration
    metric_name VARCHAR(100) NOT NULL,
    threshold_type VARCHAR(20) NOT NULL DEFAULT 'static',
    
    -- Values
    warning_value DECIMAL(15,4),
    critical_value DECIMAL(15,4),
    target_value DECIMAL(15,4),
    
    -- Dynamic threshold settings
    baseline_period INTEGER DEFAULT 30,
    deviation_factor DECIMAL(5,2) DEFAULT 2.0,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    
    -- Timestamps
    last_calculated TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_thresholds_entity_check CHECK (entity_type IN ('queue', 'agent', 'system', 'campaign')),
    CONSTRAINT realtime_thresholds_type_check CHECK (threshold_type IN ('static', 'dynamic', 'percentage')),
    CONSTRAINT realtime_thresholds_status_check CHECK (status IN ('active', 'inactive')),
    CONSTRAINT realtime_thresholds_values_check CHECK (
        (warning_value IS NULL OR warning_value >= 0) AND
        (critical_value IS NULL OR critical_value >= 0) AND
        (target_value IS NULL OR target_value >= 0)
    )
);

-- Indexes for realtime_thresholds
CREATE INDEX idx_realtime_thresholds_entity ON realtime_thresholds(entity_type, entity_id);
CREATE INDEX idx_realtime_thresholds_metric ON realtime_thresholds(metric_name);
CREATE INDEX idx_realtime_thresholds_type ON realtime_thresholds(threshold_type);
CREATE INDEX idx_realtime_thresholds_status ON realtime_thresholds(status);
CREATE INDEX idx_realtime_thresholds_calculated ON realtime_thresholds(last_calculated);

-- =====================================================================================
-- 8. REALTIME_DASHBOARDS - Dashboard configurations
-- =====================================================================================

CREATE TABLE realtime_dashboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_name VARCHAR(100) NOT NULL,
    dashboard_type VARCHAR(50) NOT NULL,
    
    -- Owner and access
    owner_id VARCHAR(100) NOT NULL,
    access_level VARCHAR(20) NOT NULL DEFAULT 'private',
    
    -- Configuration
    layout_config JSONB NOT NULL DEFAULT '{}',
    widget_config JSONB NOT NULL DEFAULT '{}',
    refresh_interval INTEGER DEFAULT 5,
    
    -- Filters and settings
    default_filters JSONB DEFAULT '{}',
    theme_settings JSONB DEFAULT '{}',
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_dashboards_access_check CHECK (access_level IN ('private', 'team', 'public')),
    CONSTRAINT realtime_dashboards_status_check CHECK (status IN ('active', 'inactive', 'archived')),
    CONSTRAINT realtime_dashboards_refresh_check CHECK (refresh_interval >= 1 AND refresh_interval <= 300)
);

-- Indexes for realtime_dashboards
CREATE INDEX idx_realtime_dashboards_owner ON realtime_dashboards(owner_id);
CREATE INDEX idx_realtime_dashboards_type ON realtime_dashboards(dashboard_type);
CREATE INDEX idx_realtime_dashboards_access ON realtime_dashboards(access_level);
CREATE INDEX idx_realtime_dashboards_status ON realtime_dashboards(status);
CREATE INDEX idx_realtime_dashboards_default ON realtime_dashboards(is_default);
CREATE INDEX idx_realtime_dashboards_accessed ON realtime_dashboards(last_accessed);

-- =====================================================================================
-- 9. REALTIME_NOTIFICATIONS - Notification management
-- =====================================================================================

CREATE TABLE realtime_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_type VARCHAR(50) NOT NULL,
    
    -- Target
    recipient_id VARCHAR(100) NOT NULL,
    recipient_type VARCHAR(20) NOT NULL DEFAULT 'user',
    
    -- Content
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    
    -- Source
    source_type VARCHAR(50) NOT NULL,
    source_id VARCHAR(100),
    alert_id UUID,
    
    -- Delivery
    delivery_method VARCHAR(20) NOT NULL DEFAULT 'websocket',
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'unread',
    is_acknowledged BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_notifications_recipient_check CHECK (recipient_type IN ('user', 'group', 'role')),
    CONSTRAINT realtime_notifications_priority_check CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT realtime_notifications_delivery_method_check CHECK (delivery_method IN ('websocket', 'email', 'sms', 'push')),
    CONSTRAINT realtime_notifications_delivery_status_check CHECK (delivery_status IN ('pending', 'sent', 'failed', 'expired')),
    CONSTRAINT realtime_notifications_status_check CHECK (status IN ('unread', 'read', 'archived'))
);

-- Indexes for realtime_notifications
CREATE INDEX idx_realtime_notifications_recipient ON realtime_notifications(recipient_id, recipient_type);
CREATE INDEX idx_realtime_notifications_type ON realtime_notifications(notification_type);
CREATE INDEX idx_realtime_notifications_priority ON realtime_notifications(priority);
CREATE INDEX idx_realtime_notifications_status ON realtime_notifications(status);
CREATE INDEX idx_realtime_notifications_delivery ON realtime_notifications(delivery_status);
CREATE INDEX idx_realtime_notifications_scheduled ON realtime_notifications(scheduled_at);
CREATE INDEX idx_realtime_notifications_alert ON realtime_notifications(alert_id);
CREATE INDEX idx_realtime_notifications_expires ON realtime_notifications(expires_at);

-- =====================================================================================
-- 10. REALTIME_EVENTS - Event stream processing
-- =====================================================================================

CREATE TABLE realtime_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(50) NOT NULL,
    
    -- Source
    source_type VARCHAR(50) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    
    -- Event data
    event_data JSONB NOT NULL DEFAULT '{}',
    event_metadata JSONB DEFAULT '{}',
    
    -- Context
    session_id VARCHAR(100),
    user_id VARCHAR(100),
    correlation_id VARCHAR(100),
    
    -- Processing
    processing_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    processed_at TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER DEFAULT 0,
    
    -- Timestamps
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_events_processing_check CHECK (processing_status IN ('pending', 'processed', 'failed', 'skipped')),
    CONSTRAINT realtime_events_retry_check CHECK (retry_count >= 0 AND retry_count <= 5)
);

-- Indexes for realtime_events
CREATE INDEX idx_realtime_events_type ON realtime_events(event_type);
CREATE INDEX idx_realtime_events_category ON realtime_events(event_category);
CREATE INDEX idx_realtime_events_source ON realtime_events(source_type, source_id);
CREATE INDEX idx_realtime_events_timestamp ON realtime_events(event_timestamp);
CREATE INDEX idx_realtime_events_processing ON realtime_events(processing_status);
CREATE INDEX idx_realtime_events_session ON realtime_events(session_id);
CREATE INDEX idx_realtime_events_user ON realtime_events(user_id);
CREATE INDEX idx_realtime_events_correlation ON realtime_events(correlation_id);

-- =====================================================================================
-- 11. REALTIME_SESSIONS - WebSocket sessions
-- =====================================================================================

CREATE TABLE realtime_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) NOT NULL,
    
    -- User information
    user_id VARCHAR(100) NOT NULL,
    user_type VARCHAR(20) NOT NULL DEFAULT 'agent',
    
    -- Connection details
    connection_id VARCHAR(100) NOT NULL,
    socket_id VARCHAR(100),
    client_info JSONB DEFAULT '{}',
    
    -- Session status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    last_ping TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Connection details
    ip_address INET,
    user_agent TEXT,
    client_version VARCHAR(50),
    
    -- Timestamps
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    disconnected_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT realtime_sessions_user_type_check CHECK (user_type IN ('agent', 'supervisor', 'admin', 'system')),
    CONSTRAINT realtime_sessions_status_check CHECK (status IN ('active', 'idle', 'disconnected', 'expired'))
);

-- Indexes for realtime_sessions
CREATE UNIQUE INDEX idx_realtime_sessions_session_id ON realtime_sessions(session_id);
CREATE INDEX idx_realtime_sessions_user ON realtime_sessions(user_id);
CREATE INDEX idx_realtime_sessions_connection ON realtime_sessions(connection_id);
CREATE INDEX idx_realtime_sessions_status ON realtime_sessions(status);
CREATE INDEX idx_realtime_sessions_activity ON realtime_sessions(last_activity);
CREATE INDEX idx_realtime_sessions_ping ON realtime_sessions(last_ping);
CREATE INDEX idx_realtime_sessions_connected ON realtime_sessions(connected_at);

-- =====================================================================================
-- 12. REALTIME_SUBSCRIPTIONS - Client subscriptions
-- =====================================================================================

CREATE TABLE realtime_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) NOT NULL,
    
    -- Subscription details
    subscription_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100),
    
    -- Filters and options
    filter_criteria JSONB DEFAULT '{}',
    subscription_options JSONB DEFAULT '{}',
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    message_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT realtime_subscriptions_entity_check CHECK (entity_type IN ('queue', 'agent', 'system', 'dashboard', 'all')),
    CONSTRAINT realtime_subscriptions_status_check CHECK (status IN ('active', 'paused', 'expired')),
    CONSTRAINT realtime_subscriptions_count_check CHECK (message_count >= 0)
);

-- Indexes for realtime_subscriptions
CREATE INDEX idx_realtime_subscriptions_session ON realtime_subscriptions(session_id);
CREATE INDEX idx_realtime_subscriptions_type ON realtime_subscriptions(subscription_type);
CREATE INDEX idx_realtime_subscriptions_entity ON realtime_subscriptions(entity_type, entity_id);
CREATE INDEX idx_realtime_subscriptions_status ON realtime_subscriptions(status);
CREATE INDEX idx_realtime_subscriptions_expires ON realtime_subscriptions(expires_at);
CREATE INDEX idx_realtime_subscriptions_message ON realtime_subscriptions(last_message_at);

-- =====================================================================================
-- 13. REALTIME_CACHE - Performance optimization
-- =====================================================================================

CREATE TABLE realtime_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(255) NOT NULL,
    cache_type VARCHAR(50) NOT NULL,
    
    -- Cache data
    cache_data JSONB NOT NULL,
    cache_metadata JSONB DEFAULT '{}',
    
    -- Cache control
    ttl_seconds INTEGER DEFAULT 300,
    version INTEGER DEFAULT 1,
    
    -- Access tracking
    access_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '5 minutes'),
    
    -- Constraints
    CONSTRAINT realtime_cache_ttl_check CHECK (ttl_seconds > 0 AND ttl_seconds <= 3600),
    CONSTRAINT realtime_cache_version_check CHECK (version >= 1),
    CONSTRAINT realtime_cache_access_check CHECK (access_count >= 0)
);

-- Indexes for realtime_cache
CREATE UNIQUE INDEX idx_realtime_cache_key ON realtime_cache(cache_key);
CREATE INDEX idx_realtime_cache_type ON realtime_cache(cache_type);
CREATE INDEX idx_realtime_cache_expires ON realtime_cache(expires_at);
CREATE INDEX idx_realtime_cache_accessed ON realtime_cache(last_accessed);
CREATE INDEX idx_realtime_cache_version ON realtime_cache(version);

-- =====================================================================================
-- 14. REALTIME_HISTORY - Short-term history
-- =====================================================================================

CREATE TABLE realtime_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    history_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    
    -- Historical data
    snapshot_data JSONB NOT NULL,
    change_type VARCHAR(20) NOT NULL DEFAULT 'update',
    
    -- Context
    changed_by VARCHAR(100),
    change_reason VARCHAR(200),
    
    -- Timestamps
    snapshot_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    retention_until TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    
    -- Constraints
    CONSTRAINT realtime_history_entity_check CHECK (entity_type IN ('queue', 'agent', 'call', 'performance', 'sla')),
    CONSTRAINT realtime_history_change_check CHECK (change_type IN ('insert', 'update', 'delete', 'snapshot'))
);

-- Indexes for realtime_history
CREATE INDEX idx_realtime_history_entity ON realtime_history(entity_type, entity_id);
CREATE INDEX idx_realtime_history_type ON realtime_history(history_type);
CREATE INDEX idx_realtime_history_snapshot ON realtime_history(snapshot_time);
CREATE INDEX idx_realtime_history_retention ON realtime_history(retention_until);
CREATE INDEX idx_realtime_history_change ON realtime_history(change_type);

-- =====================================================================================
-- 15. REALTIME_AGGREGATIONS - Real-time aggregations
-- =====================================================================================

CREATE TABLE realtime_aggregations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aggregation_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100),
    
    -- Aggregation settings
    metric_name VARCHAR(100) NOT NULL,
    aggregation_function VARCHAR(20) NOT NULL,
    time_window INTEGER NOT NULL,
    
    -- Aggregated values
    current_value DECIMAL(15,4) DEFAULT 0,
    previous_value DECIMAL(15,4) DEFAULT 0,
    change_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Window data
    window_start TIMESTAMP WITH TIME ZONE,
    window_end TIMESTAMP WITH TIME ZONE,
    data_points INTEGER DEFAULT 0,
    
    -- Timestamps
    last_calculated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    next_calculation TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT realtime_aggregations_entity_check CHECK (entity_type IN ('queue', 'agent', 'system', 'campaign')),
    CONSTRAINT realtime_aggregations_function_check CHECK (aggregation_function IN ('sum', 'avg', 'min', 'max', 'count', 'rate')),
    CONSTRAINT realtime_aggregations_window_check CHECK (time_window > 0 AND time_window <= 3600),
    CONSTRAINT realtime_aggregations_points_check CHECK (data_points >= 0)
);

-- Indexes for realtime_aggregations
CREATE INDEX idx_realtime_aggregations_entity ON realtime_aggregations(entity_type, entity_id);
CREATE INDEX idx_realtime_aggregations_type ON realtime_aggregations(aggregation_type);
CREATE INDEX idx_realtime_aggregations_metric ON realtime_aggregations(metric_name);
CREATE INDEX idx_realtime_aggregations_function ON realtime_aggregations(aggregation_function);
CREATE INDEX idx_realtime_aggregations_calculated ON realtime_aggregations(last_calculated);
CREATE INDEX idx_realtime_aggregations_window ON realtime_aggregations(window_start, window_end);

-- =====================================================================================
-- WEBSOCKET INTEGRATION FUNCTIONS
-- =====================================================================================

-- Function to broadcast real-time updates
CREATE OR REPLACE FUNCTION broadcast_realtime_update(
    p_channel VARCHAR(50),
    p_entity_type VARCHAR(20),
    p_entity_id VARCHAR(100),
    p_data JSONB
) RETURNS VOID AS $$
BEGIN
    PERFORM pg_notify(p_channel, json_build_object(
        'entity_type', p_entity_type,
        'entity_id', p_entity_id,
        'data', p_data,
        'timestamp', CURRENT_TIMESTAMP
    )::TEXT);
END;
$$ LANGUAGE plpgsql;

-- Function to update queue status with notification
CREATE OR REPLACE FUNCTION update_queue_status(
    p_queue_id VARCHAR(100),
    p_status_data JSONB
) RETURNS VOID AS $$
BEGIN
    UPDATE realtime_queues 
    SET 
        current_calls = COALESCE((p_status_data->>'current_calls')::INTEGER, current_calls),
        waiting_calls = COALESCE((p_status_data->>'waiting_calls')::INTEGER, waiting_calls),
        agents_available = COALESCE((p_status_data->>'agents_available')::INTEGER, agents_available),
        agents_busy = COALESCE((p_status_data->>'agents_busy')::INTEGER, agents_busy),
        agents_total = COALESCE((p_status_data->>'agents_total')::INTEGER, agents_total),
        avg_wait_time = COALESCE((p_status_data->>'avg_wait_time')::DECIMAL, avg_wait_time),
        avg_handle_time = COALESCE((p_status_data->>'avg_handle_time')::DECIMAL, avg_handle_time),
        service_level = COALESCE((p_status_data->>'service_level')::DECIMAL, service_level),
        abandon_rate = COALESCE((p_status_data->>'abandon_rate')::DECIMAL, abandon_rate),
        last_updated = CURRENT_TIMESTAMP
    WHERE queue_id = p_queue_id;
    
    -- Broadcast update
    PERFORM broadcast_realtime_update('queue_updates', 'queue', p_queue_id, p_status_data);
END;
$$ LANGUAGE plpgsql;

-- Function to update agent status with notification
CREATE OR REPLACE FUNCTION update_agent_status(
    p_agent_id VARCHAR(100),
    p_status_data JSONB
) RETURNS VOID AS $$
BEGIN
    UPDATE realtime_agents 
    SET 
        status = COALESCE((p_status_data->>'status')::VARCHAR, status),
        state = COALESCE((p_status_data->>'state')::VARCHAR, state),
        queue_id = COALESCE((p_status_data->>'queue_id')::VARCHAR, queue_id),
        current_call_id = COALESCE((p_status_data->>'current_call_id')::UUID, current_call_id),
        last_activity = CURRENT_TIMESTAMP,
        status_changed_at = CASE 
            WHEN (p_status_data->>'status') IS NOT NULL AND (p_status_data->>'status')::VARCHAR != status 
            THEN CURRENT_TIMESTAMP 
            ELSE status_changed_at 
        END
    WHERE agent_id = p_agent_id;
    
    -- Broadcast update
    PERFORM broadcast_realtime_update('agent_updates', 'agent', p_agent_id, p_status_data);
END;
$$ LANGUAGE plpgsql;

-- Function to process real-time events
CREATE OR REPLACE FUNCTION process_realtime_event(
    p_event_type VARCHAR(50),
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(100),
    p_event_data JSONB
) RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    -- Insert event
    INSERT INTO realtime_events (event_type, event_category, source_type, source_id, event_data)
    VALUES (p_event_type, 'realtime', p_source_type, p_source_id, p_event_data)
    RETURNING id INTO v_event_id;
    
    -- Process based on event type
    CASE p_event_type
        WHEN 'queue_update' THEN
            PERFORM update_queue_status(p_source_id, p_event_data);
        WHEN 'agent_update' THEN
            PERFORM update_agent_status(p_source_id, p_event_data);
        WHEN 'call_update' THEN
            PERFORM broadcast_realtime_update('call_updates', 'call', p_source_id, p_event_data);
        ELSE
            PERFORM broadcast_realtime_update('system_updates', p_source_type, p_source_id, p_event_data);
    END CASE;
    
    -- Mark as processed
    UPDATE realtime_events 
    SET processing_status = 'processed', processed_at = CURRENT_TIMESTAMP
    WHERE id = v_event_id;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions() RETURNS INTEGER AS $$
DECLARE
    v_cleaned_count INTEGER := 0;
BEGIN
    -- Clean up expired sessions (no activity for 30 minutes)
    UPDATE realtime_sessions 
    SET status = 'expired', disconnected_at = CURRENT_TIMESTAMP
    WHERE status = 'active' 
    AND last_activity < CURRENT_TIMESTAMP - INTERVAL '30 minutes';
    
    GET DIAGNOSTICS v_cleaned_count = ROW_COUNT;
    
    -- Clean up expired subscriptions
    DELETE FROM realtime_subscriptions 
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    -- Clean up expired cache entries
    DELETE FROM realtime_cache 
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    -- Clean up old history (older than retention period)
    DELETE FROM realtime_history 
    WHERE retention_until < CURRENT_TIMESTAMP;
    
    RETURN v_cleaned_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SAMPLE DATA GENERATORS
-- =====================================================================================

-- Function to generate sample queue data
CREATE OR REPLACE FUNCTION generate_sample_queue_data() RETURNS VOID AS $$
BEGIN
    INSERT INTO realtime_queues (queue_id, queue_name, queue_type, status, current_calls, waiting_calls, agents_available, agents_busy, agents_total, avg_wait_time, avg_handle_time, service_level, abandon_rate) VALUES
    ('Q001', 'Customer Service', 'voice', 'active', 12, 8, 5, 12, 17, 45.5, 180.2, 85.6, 3.2),
    ('Q002', 'Technical Support', 'voice', 'active', 6, 3, 8, 6, 14, 32.1, 240.8, 92.1, 1.8),
    ('Q003', 'Sales', 'voice', 'active', 15, 12, 3, 15, 18, 62.3, 150.7, 78.9, 5.1),
    ('Q004', 'Live Chat', 'chat', 'active', 8, 2, 4, 8, 12, 12.8, 300.5, 95.2, 0.8),
    ('Q005', 'Email Support', 'email', 'active', 0, 25, 6, 0, 6, 0, 0, 0, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample agent data
CREATE OR REPLACE FUNCTION generate_sample_agent_data() RETURNS VOID AS $$
BEGIN
    INSERT INTO realtime_agents (agent_id, agent_name, status, state, queue_id, calls_handled, avg_handle_time, occupancy_rate, location, device_type) VALUES
    ('A001', 'John Smith', 'online', 'busy', 'Q001', 23, 178.5, 85.2, 'New York', 'desktop'),
    ('A002', 'Sarah Johnson', 'online', 'idle', 'Q001', 18, 165.8, 72.3, 'Los Angeles', 'desktop'),
    ('A003', 'Mike Davis', 'online', 'busy', 'Q002', 15, 245.2, 91.7, 'Chicago', 'desktop'),
    ('A004', 'Emily Wilson', 'online', 'wrap_up', 'Q002', 12, 225.7, 68.9, 'Houston', 'mobile'),
    ('A005', 'David Brown', 'break', 'not_ready', 'Q003', 8, 142.3, 45.6, 'Phoenix', 'desktop'),
    ('A006', 'Lisa Garcia', 'online', 'busy', 'Q003', 19, 158.9, 88.4, 'Philadelphia', 'desktop'),
    ('A007', 'Robert Miller', 'online', 'idle', 'Q004', 32, 285.6, 76.8, 'San Antonio', 'desktop'),
    ('A008', 'Jennifer Taylor', 'online', 'busy', 'Q004', 28, 310.2, 89.1, 'San Diego', 'desktop');
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample call data
CREATE OR REPLACE FUNCTION generate_sample_call_data() RETURNS VOID AS $$
BEGIN
    INSERT INTO realtime_calls (call_id, call_type, queue_id, agent_id, customer_id, phone_number, status, priority, wait_time, talk_time) VALUES
    ('C001', 'inbound', 'Q001', 'A001', 'CUST001', '+1234567890', 'connected', 1, 45.5, 120.3),
    ('C002', 'inbound', 'Q001', NULL, 'CUST002', '+1234567891', 'waiting', 2, 38.2, 0),
    ('C003', 'inbound', 'Q002', 'A003', 'CUST003', '+1234567892', 'connected', 1, 32.1, 180.7),
    ('C004', 'inbound', 'Q003', 'A006', 'CUST004', '+1234567893', 'connected', 3, 62.3, 95.2),
    ('C005', 'inbound', 'Q004', 'A008', 'CUST005', NULL, 'connected', 1, 12.8, 45.6),
    ('C006', 'outbound', 'Q003', NULL, 'CUST006', '+1234567894', 'ringing', 1, 0, 0);
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- MIGRATION FROM JSONB STUBS
-- =====================================================================================

-- Function to migrate from JSONB stub data
CREATE OR REPLACE FUNCTION migrate_from_jsonb_stubs() RETURNS INTEGER AS $$
DECLARE
    v_migrated_count INTEGER := 0;
BEGIN
    -- This function would be implemented based on existing JSONB structure
    -- For now, we'll just return 0 as a placeholder
    RETURN v_migrated_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- PERFORMANCE OPTIMIZATION FUNCTIONS
-- =====================================================================================

-- Function to optimize for <100ms latency
CREATE OR REPLACE FUNCTION optimize_realtime_performance() RETURNS VOID AS $$
BEGIN
    -- Analyze tables for query planning
    ANALYZE realtime_queues;
    ANALYZE realtime_agents;
    ANALYZE realtime_calls;
    ANALYZE realtime_performance;
    ANALYZE realtime_events;
    
    -- Update table statistics
    UPDATE pg_stat_user_tables SET n_tup_upd = n_tup_upd + 1 WHERE schemaname = 'public';
    
    -- Reindex critical tables
    REINDEX TABLE realtime_queues;
    REINDEX TABLE realtime_agents;
    REINDEX TABLE realtime_calls;
END;
$$ LANGUAGE plpgsql;

-- Function to monitor connection count
CREATE OR REPLACE FUNCTION monitor_connection_count() RETURNS INTEGER AS $$
DECLARE
    v_active_sessions INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_active_sessions
    FROM realtime_sessions
    WHERE status = 'active';
    
    RETURN v_active_sessions;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- TRIGGERS FOR REAL-TIME UPDATES
-- =====================================================================================

-- Trigger function for queue updates
CREATE OR REPLACE FUNCTION trigger_queue_update() RETURNS TRIGGER AS $$
BEGIN
    PERFORM broadcast_realtime_update('queue_updates', 'queue', NEW.queue_id, 
        json_build_object(
            'queue_id', NEW.queue_id,
            'current_calls', NEW.current_calls,
            'waiting_calls', NEW.waiting_calls,
            'agents_available', NEW.agents_available,
            'agents_busy', NEW.agents_busy,
            'service_level', NEW.service_level,
            'last_updated', NEW.last_updated
        )::JSONB
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for agent updates
CREATE OR REPLACE FUNCTION trigger_agent_update() RETURNS TRIGGER AS $$
BEGIN
    PERFORM broadcast_realtime_update('agent_updates', 'agent', NEW.agent_id,
        json_build_object(
            'agent_id', NEW.agent_id,
            'status', NEW.status,
            'state', NEW.state,
            'queue_id', NEW.queue_id,
            'current_call_id', NEW.current_call_id,
            'last_activity', NEW.last_activity
        )::JSONB
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER realtime_queues_update_trigger
    AFTER UPDATE ON realtime_queues
    FOR EACH ROW
    EXECUTE FUNCTION trigger_queue_update();

CREATE TRIGGER realtime_agents_update_trigger
    AFTER UPDATE ON realtime_agents
    FOR EACH ROW
    EXECUTE FUNCTION trigger_agent_update();

-- =====================================================================================
-- CLEANUP AND MAINTENANCE
-- =====================================================================================

-- Create cleanup job function
CREATE OR REPLACE FUNCTION run_realtime_maintenance() RETURNS VOID AS $$
BEGIN
    -- Clean up expired sessions
    PERFORM cleanup_expired_sessions();
    
    -- Optimize performance
    PERFORM optimize_realtime_performance();
    
    -- Clean up old events (older than 24 hours)
    DELETE FROM realtime_events 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '24 hours'
    AND processing_status = 'processed';
    
    -- Clean up old notifications (older than 7 days)
    DELETE FROM realtime_notifications 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '7 days'
    AND status = 'archived';
    
    -- Update aggregation calculations
    UPDATE realtime_aggregations 
    SET last_calculated = CURRENT_TIMESTAMP,
        next_calculation = CURRENT_TIMESTAMP + (time_window || ' seconds')::INTERVAL
    WHERE next_calculation < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- FINAL SETUP AND COMMENTS
-- =====================================================================================

-- Add table comments
COMMENT ON TABLE realtime_queues IS 'Live queue status and performance metrics';
COMMENT ON TABLE realtime_agents IS 'Real-time agent status and activity tracking';
COMMENT ON TABLE realtime_calls IS 'Active call tracking and monitoring';
COMMENT ON TABLE realtime_performance IS 'Performance metrics collection and storage';
COMMENT ON TABLE realtime_sla IS 'Service level agreement tracking and monitoring';
COMMENT ON TABLE realtime_alerts IS 'Alert definitions and trigger management';
COMMENT ON TABLE realtime_thresholds IS 'Configurable thresholds for monitoring';
COMMENT ON TABLE realtime_dashboards IS 'Dashboard configurations and settings';
COMMENT ON TABLE realtime_notifications IS 'Notification management and delivery';
COMMENT ON TABLE realtime_events IS 'Event stream processing and tracking';
COMMENT ON TABLE realtime_sessions IS 'WebSocket session management';
COMMENT ON TABLE realtime_subscriptions IS 'Client subscription management';
COMMENT ON TABLE realtime_cache IS 'Performance optimization cache';
COMMENT ON TABLE realtime_history IS 'Short-term historical data storage';
COMMENT ON TABLE realtime_aggregations IS 'Real-time metric aggregations';

-- Grant permissions (adjust as needed)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_app;

-- =====================================================================================
-- SCHEMA VALIDATION
-- =====================================================================================

-- Validate that all 15 tables exist
DO $$
DECLARE
    v_table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name LIKE 'realtime_%';
    
    IF v_table_count != 15 THEN
        RAISE EXCEPTION 'Expected 15 real-time tables, found %', v_table_count;
    END IF;
    
    RAISE NOTICE 'Real-time monitoring schema created successfully with % tables', v_table_count;
END;
$$;

-- =====================================================================================
-- END OF SCHEMA
-- =====================================================================================