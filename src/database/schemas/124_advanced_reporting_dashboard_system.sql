-- =====================================================================================
-- Schema 124: Advanced Reporting and Dashboard System
-- =====================================================================================
-- Description: Enterprise reporting platform with real-time streaming, advanced
--             visualization APIs, customizable dashboards, and automated insights
-- Business Value: Real-time business intelligence, automated reporting, data visualization
-- Dependencies: Schema 121 (ML platform), Schema 122 (forecasting), Schema 123 (compliance)
-- Complexity: ADVANCED - Enterprise BI platform with streaming and automation
-- =====================================================================================

-- Dashboard and Report Configuration
-- =====================================================================================

-- Dashboard definitions and configurations
CREATE TABLE dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_name VARCHAR(100) NOT NULL,
    dashboard_type VARCHAR(50) NOT NULL, -- 'operational', 'strategic', 'compliance', 'executive'
    dashboard_category VARCHAR(50) NOT NULL, -- 'workforce', 'performance', 'quality', 'financial'
    
    -- Dashboard configuration
    layout_config JSONB NOT NULL, -- Dashboard layout and grid configuration
    theme_config JSONB, -- Visual theme and styling
    refresh_frequency_seconds INTEGER DEFAULT 300, -- Auto-refresh interval
    real_time_enabled BOOLEAN DEFAULT false, -- Real-time data streaming
    
    -- Access control
    visibility VARCHAR(20) DEFAULT 'private', -- 'private', 'shared', 'public'
    owner_id VARCHAR(100) NOT NULL,
    shared_with TEXT[], -- User IDs who have access
    role_permissions JSONB, -- Role-based access permissions
    
    -- Business context
    business_purpose TEXT,
    target_audience TEXT[], -- 'managers', 'agents', 'executives', 'analysts'
    kpi_focus TEXT[], -- Primary KPIs this dashboard tracks
    
    -- Display settings
    screen_resolution VARCHAR(20) DEFAULT '1920x1080', -- Target screen resolution
    mobile_optimized BOOLEAN DEFAULT false,
    auto_layout BOOLEAN DEFAULT true, -- Automatic layout adjustment
    
    -- Performance
    cache_enabled BOOLEAN DEFAULT true,
    cache_duration_minutes INTEGER DEFAULT 15,
    lazy_loading BOOLEAN DEFAULT true,
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'archived'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_count BIGINT DEFAULT 0,
    
    -- Versioning
    version_number INTEGER DEFAULT 1,
    parent_dashboard_id UUID REFERENCES dashboards(dashboard_id),
    
    UNIQUE(dashboard_name, owner_id)
);

-- Dashboard widgets/components
CREATE TABLE dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_id UUID REFERENCES dashboards(dashboard_id) ON DELETE CASCADE,
    widget_name VARCHAR(100) NOT NULL,
    widget_type VARCHAR(50) NOT NULL, -- 'chart', 'table', 'metric', 'gauge', 'map', 'text'
    
    -- Widget positioning
    position_x INTEGER NOT NULL, -- Grid position X
    position_y INTEGER NOT NULL, -- Grid position Y
    width INTEGER NOT NULL, -- Grid width
    height INTEGER NOT NULL, -- Grid height
    z_index INTEGER DEFAULT 1, -- Layer order
    
    -- Widget configuration
    widget_config JSONB NOT NULL, -- Widget-specific configuration
    data_source_config JSONB NOT NULL, -- Data source and query configuration
    visualization_config JSONB, -- Chart/visualization settings
    
    -- Data refresh
    refresh_frequency_seconds INTEGER, -- Override dashboard refresh
    cache_enabled BOOLEAN DEFAULT true,
    cache_key VARCHAR(128), -- Unique cache key for this widget
    
    -- Interactivity
    interactive BOOLEAN DEFAULT true,
    drill_down_enabled BOOLEAN DEFAULT false,
    drill_down_config JSONB, -- Drill-down configuration
    filters_enabled BOOLEAN DEFAULT true,
    export_enabled BOOLEAN DEFAULT true,
    
    -- Conditional formatting
    alert_rules JSONB, -- Rules for highlighting/alerting
    threshold_config JSONB, -- Thresholds for color coding
    
    -- Performance
    query_timeout_seconds INTEGER DEFAULT 30,
    max_data_points INTEGER DEFAULT 10000,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Report templates and definitions
CREATE TABLE report_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- 'standard', 'custom', 'regulatory', 'executive'
    report_category VARCHAR(50) NOT NULL, -- 'operational', 'analytical', 'compliance', 'financial'
    
    -- Template configuration
    report_structure JSONB NOT NULL, -- Report sections and layout
    data_sources JSONB NOT NULL, -- Data sources and queries
    calculation_logic JSONB, -- Business logic for calculations
    
    -- Output configuration
    output_formats TEXT[] DEFAULT ARRAY['pdf', 'excel'], -- Supported output formats
    page_layout JSONB, -- Page layout and formatting
    branding_config JSONB, -- Logo, colors, company branding
    
    -- Scheduling
    scheduling_enabled BOOLEAN DEFAULT false,
    default_schedule JSONB, -- Default scheduling configuration
    
    -- Parameters
    parameter_definitions JSONB, -- User-configurable parameters
    default_parameters JSONB, -- Default parameter values
    
    -- Access control
    visibility VARCHAR(20) DEFAULT 'private',
    created_by VARCHAR(100) NOT NULL,
    shared_with TEXT[],
    approval_required BOOLEAN DEFAULT false,
    
    -- Business context
    business_purpose TEXT,
    compliance_related BOOLEAN DEFAULT false,
    regulatory_authority VARCHAR(100), -- If compliance report
    
    -- Performance
    estimated_generation_time_minutes INTEGER,
    max_data_rows INTEGER DEFAULT 100000,
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active',
    version_number INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(template_name, created_by)
);

-- Real-time Data Streaming and Analytics
-- =====================================================================================

-- Real-time data streams configuration
CREATE TABLE data_streams (
    stream_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_name VARCHAR(100) NOT NULL,
    stream_type VARCHAR(50) NOT NULL, -- 'real_time_metrics', 'events', 'alerts', 'kpi_updates'
    
    -- Stream configuration
    data_source VARCHAR(100) NOT NULL, -- Source system or table
    stream_query TEXT, -- Query or filter for stream data
    sampling_frequency_seconds INTEGER DEFAULT 10, -- How often to sample data
    
    -- Stream processing
    aggregation_window_seconds INTEGER DEFAULT 60, -- Aggregation window
    aggregation_functions JSONB, -- Functions to apply (avg, sum, count, etc.)
    data_transformations JSONB, -- Data transformation rules
    
    -- Output configuration
    output_format VARCHAR(20) DEFAULT 'json', -- Output data format
    compression_enabled BOOLEAN DEFAULT false,
    encryption_enabled BOOLEAN DEFAULT false,
    
    -- Consumer management
    max_consumers INTEGER DEFAULT 10, -- Maximum concurrent consumers
    consumer_timeout_seconds INTEGER DEFAULT 30,
    backpressure_handling VARCHAR(20) DEFAULT 'buffer', -- 'buffer', 'drop', 'block'
    
    -- Quality of service
    delivery_guarantee VARCHAR(20) DEFAULT 'at_least_once', -- 'at_most_once', 'at_least_once', 'exactly_once'
    message_retention_hours INTEGER DEFAULT 24, -- How long to retain messages
    
    -- Monitoring
    throughput_messages_per_second DECIMAL(8,2) DEFAULT 0,
    error_rate_percentage DECIMAL(5,2) DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'paused', 'stopped'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(stream_name)
);

-- Stream consumers and subscriptions
CREATE TABLE stream_subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id UUID REFERENCES data_streams(stream_id) ON DELETE CASCADE,
    subscriber_name VARCHAR(100) NOT NULL,
    subscriber_type VARCHAR(30) NOT NULL, -- 'dashboard', 'widget', 'alert_system', 'external_api'
    
    -- Subscription configuration
    filter_conditions JSONB, -- Conditions for filtering stream data
    delivery_mode VARCHAR(20) DEFAULT 'push', -- 'push', 'pull'
    batch_size INTEGER DEFAULT 1, -- Messages per batch
    
    -- Endpoint configuration
    endpoint_url TEXT, -- For webhook deliveries
    authentication JSONB, -- Authentication configuration
    retry_policy JSONB, -- Retry configuration for failed deliveries
    
    -- Performance settings
    max_delivery_attempts INTEGER DEFAULT 3,
    delivery_timeout_seconds INTEGER DEFAULT 10,
    
    -- Monitoring
    messages_delivered BIGINT DEFAULT 0,
    messages_failed BIGINT DEFAULT 0,
    last_delivery_at TIMESTAMP WITH TIME ZONE,
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(stream_id, subscriber_name)
);

-- Generated Reports Tracking
-- =====================================================================================

-- Generated report instances
CREATE TABLE report_instances (
    instance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES report_templates(template_id),
    report_name VARCHAR(200) NOT NULL,
    
    -- Generation context
    generation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    generated_by VARCHAR(100) NOT NULL,
    generation_trigger VARCHAR(30) DEFAULT 'manual', -- 'manual', 'scheduled', 'event_triggered'
    
    -- Report parameters
    report_parameters JSONB, -- Parameters used for this generation
    date_range_start TIMESTAMP WITH TIME ZONE,
    date_range_end TIMESTAMP WITH TIME ZONE,
    
    -- Generation process
    generation_status VARCHAR(20) DEFAULT 'generating', -- 'generating', 'completed', 'failed', 'cancelled'
    generation_progress_percentage INTEGER DEFAULT 0,
    generation_start_time TIMESTAMP WITH TIME ZONE,
    generation_end_time TIMESTAMP WITH TIME ZONE,
    generation_duration_seconds INTEGER,
    
    -- Report content
    data_row_count INTEGER, -- Number of data rows in report
    report_size_kb INTEGER, -- Size of generated report
    output_format VARCHAR(20), -- Format of generated report
    
    -- File management
    file_path TEXT, -- Path to generated report file
    file_url TEXT, -- URL for downloading report
    file_retention_until TIMESTAMP WITH TIME ZONE, -- When file will be deleted
    
    -- Quality metrics
    data_completeness_percentage DECIMAL(5,2), -- Percentage of expected data present
    data_accuracy_score DECIMAL(3,2), -- Accuracy score if validation performed
    generation_errors JSONB, -- Any errors encountered during generation
    
    -- Access tracking
    download_count INTEGER DEFAULT 0,
    last_downloaded_at TIMESTAMP WITH TIME ZONE,
    downloaded_by TEXT[], -- Users who downloaded this report
    
    -- Business impact
    business_value_score DECIMAL(3,2), -- Estimated business value (0.0-1.0)
    decision_impact BOOLEAN DEFAULT false, -- Was this report used for decisions?
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (generation_timestamp);

-- Create monthly partitions for report instances
CREATE TABLE report_instances_2024_01 PARTITION OF report_instances
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE report_instances_2024_02 PARTITION OF report_instances
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE report_instances_2024_03 PARTITION OF report_instances
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE report_instances_2024_04 PARTITION OF report_instances
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE report_instances_2024_05 PARTITION OF report_instances
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE report_instances_2024_06 PARTITION OF report_instances
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE report_instances_2024_07 PARTITION OF report_instances
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE report_instances_2024_08 PARTITION OF report_instances
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE report_instances_2024_09 PARTITION OF report_instances
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE report_instances_2024_10 PARTITION OF report_instances
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE report_instances_2024_11 PARTITION OF report_instances
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE report_instances_2024_12 PARTITION OF report_instances
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE report_instances_2025_01 PARTITION OF report_instances
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Visualization and Analytics Engine
-- =====================================================================================

-- Visualization configurations and templates
CREATE TABLE visualizations (
    visualization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visualization_name VARCHAR(100) NOT NULL,
    visualization_type VARCHAR(50) NOT NULL, -- 'line_chart', 'bar_chart', 'pie_chart', 'heatmap', 'gauge', 'table'
    
    -- Data configuration
    data_source_type VARCHAR(30) NOT NULL, -- 'sql_query', 'api_endpoint', 'stream', 'static_data'
    data_source_config JSONB NOT NULL, -- Configuration for data source
    data_transformations JSONB, -- Data transformation pipeline
    
    -- Chart configuration
    chart_config JSONB NOT NULL, -- Chart-specific configuration
    axis_config JSONB, -- Axis labels, scales, formatting
    series_config JSONB, -- Data series configuration
    color_scheme JSONB, -- Color palette and theming
    
    -- Interactivity
    zoom_enabled BOOLEAN DEFAULT true,
    pan_enabled BOOLEAN DEFAULT true,
    selection_enabled BOOLEAN DEFAULT true,
    tooltip_config JSONB, -- Tooltip configuration
    legend_config JSONB, -- Legend positioning and styling
    
    -- Responsiveness
    responsive_enabled BOOLEAN DEFAULT true,
    breakpoint_config JSONB, -- Responsive breakpoints
    mobile_config JSONB, -- Mobile-specific configuration
    
    -- Performance
    data_limit INTEGER DEFAULT 10000, -- Maximum data points
    lazy_loading BOOLEAN DEFAULT true,
    virtualization_enabled BOOLEAN DEFAULT false, -- For large datasets
    
    -- Animation
    animation_enabled BOOLEAN DEFAULT true,
    animation_config JSONB, -- Animation settings
    transition_duration_ms INTEGER DEFAULT 300,
    
    -- Export options
    export_formats TEXT[] DEFAULT ARRAY['png', 'svg', 'pdf'], -- Supported export formats
    export_config JSONB, -- Export-specific settings
    
    -- Business context
    business_metric VARCHAR(100), -- Primary business metric displayed
    target_value DECIMAL(15,6), -- Target value for this metric
    benchmark_values JSONB, -- Benchmark or comparison values
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active',
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(visualization_name, created_by)
);

-- KPI definitions and tracking
CREATE TABLE kpi_definitions (
    kpi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_name VARCHAR(100) NOT NULL,
    kpi_category VARCHAR(50) NOT NULL, -- 'operational', 'financial', 'quality', 'efficiency'
    kpi_subcategory VARCHAR(50), -- More specific categorization
    
    -- KPI specification
    description TEXT NOT NULL,
    calculation_formula TEXT NOT NULL, -- Human-readable formula
    calculation_logic JSONB NOT NULL, -- Machine-readable calculation logic
    data_sources TEXT[] NOT NULL, -- Required data sources
    
    -- Measurement details
    unit_of_measurement VARCHAR(30) NOT NULL, -- 'percentage', 'count', 'hours', 'rubles'
    measurement_frequency VARCHAR(20) DEFAULT 'daily', -- 'real_time', 'hourly', 'daily', 'weekly', 'monthly'
    aggregation_method VARCHAR(20) DEFAULT 'average', -- 'sum', 'average', 'min', 'max', 'count'
    
    -- Targets and thresholds
    target_value DECIMAL(15,6), -- Target value for this KPI
    upper_threshold DECIMAL(15,6), -- Upper alert threshold
    lower_threshold DECIMAL(15,6), -- Lower alert threshold
    critical_upper DECIMAL(15,6), -- Critical upper threshold
    critical_lower DECIMAL(15,6), -- Critical lower threshold
    
    -- Trending and analysis
    trend_direction VARCHAR(20) DEFAULT 'higher_better', -- 'higher_better', 'lower_better', 'target_optimal'
    seasonality_pattern VARCHAR(30), -- 'none', 'daily', 'weekly', 'monthly', 'quarterly', 'annual'
    baseline_calculation_method TEXT, -- How to calculate baseline/benchmark
    
    -- Business context
    business_owner VARCHAR(100) NOT NULL, -- Business owner responsible for this KPI
    strategic_importance VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    related_kpis UUID[], -- Array of related KPI IDs
    
    -- Automation
    automated_calculation BOOLEAN DEFAULT true,
    automated_alerts BOOLEAN DEFAULT true,
    alert_recipients TEXT[], -- Who to notify on threshold breaches
    
    -- Quality assurance
    data_quality_checks JSONB, -- Data quality validation rules
    validation_rules JSONB, -- Business logic validation
    
    -- Lifecycle
    status VARCHAR(20) DEFAULT 'active',
    effective_from DATE NOT NULL,
    effective_until DATE,
    review_frequency VARCHAR(20) DEFAULT 'quarterly', -- How often to review KPI definition
    last_reviewed_at DATE,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(kpi_name)
);

-- KPI measurements and historical tracking
CREATE TABLE kpi_measurements (
    measurement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_id UUID REFERENCES kpi_definitions(kpi_id) ON DELETE CASCADE,
    
    -- Measurement context
    measurement_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    measurement_date DATE GENERATED ALWAYS AS (DATE(measurement_timestamp)) STORED,
    measurement_period VARCHAR(20) NOT NULL, -- 'real_time', 'hourly', 'daily', 'weekly', 'monthly'
    
    -- Measured values
    measured_value DECIMAL(15,6) NOT NULL,
    target_value DECIMAL(15,6), -- Target for this measurement period
    variance_from_target DECIMAL(15,6), -- Actual - Target
    variance_percentage DECIMAL(8,4), -- (Actual - Target) / Target * 100
    
    -- Status indicators
    status VARCHAR(20) NOT NULL, -- 'good', 'warning', 'critical', 'unknown'
    threshold_breached VARCHAR(20), -- 'none', 'upper', 'lower', 'critical_upper', 'critical_lower'
    
    -- Trend analysis
    trend_direction VARCHAR(20), -- 'up', 'down', 'stable', 'volatile'
    period_over_period_change DECIMAL(15,6), -- Change from previous period
    period_over_period_percentage DECIMAL(8,4), -- Percentage change from previous period
    
    -- Data quality
    data_completeness_percentage DECIMAL(5,2) DEFAULT 100.0,
    data_sources_used TEXT[], -- Which data sources contributed
    calculation_confidence DECIMAL(3,2) DEFAULT 1.0, -- Confidence in calculation (0.0-1.0)
    
    -- Business context
    business_driver VARCHAR(100), -- What drove this measurement
    external_factors TEXT[], -- External factors affecting this measurement
    anomaly_detected BOOLEAN DEFAULT false,
    anomaly_explanation TEXT,
    
    -- Forecasting
    forecasted_value DECIMAL(15,6), -- If forecast was available
    forecast_accuracy DECIMAL(8,4), -- How accurate was the forecast
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (measurement_date);

-- Create monthly partitions for KPI measurements
CREATE TABLE kpi_measurements_2024_01 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE kpi_measurements_2024_02 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE kpi_measurements_2024_03 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE kpi_measurements_2024_04 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE kpi_measurements_2024_05 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE kpi_measurements_2024_06 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE kpi_measurements_2024_07 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE kpi_measurements_2024_08 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE kpi_measurements_2024_09 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE kpi_measurements_2024_10 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE kpi_measurements_2024_11 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE kpi_measurements_2024_12 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE kpi_measurements_2025_01 PARTITION OF kpi_measurements
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Automated Insights and Alerts
-- =====================================================================================

-- Automated insight generation
CREATE TABLE automated_insights (
    insight_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_type VARCHAR(50) NOT NULL, -- 'anomaly', 'trend', 'correlation', 'forecast', 'recommendation'
    insight_category VARCHAR(50) NOT NULL, -- 'performance', 'quality', 'efficiency', 'compliance'
    
    -- Insight content
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    insight_summary TEXT, -- Brief summary for notifications
    
    -- Detection details
    detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    detection_method VARCHAR(50) NOT NULL, -- 'statistical_analysis', 'ml_model', 'rule_based', 'pattern_recognition'
    confidence_score DECIMAL(3,2) NOT NULL, -- Confidence in this insight (0.0-1.0)
    
    -- Data context
    data_sources TEXT[] NOT NULL,
    affected_entities JSONB, -- Entities affected by this insight
    time_period JSONB, -- Time period this insight covers
    
    -- Insight details
    insight_data JSONB NOT NULL, -- Detailed insight data and evidence
    supporting_charts JSONB, -- Chart configurations supporting this insight
    statistical_significance DECIMAL(5,4), -- Statistical significance if applicable
    
    -- Business impact
    impact_level VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    estimated_impact_rubles DECIMAL(12,2), -- Financial impact estimate
    affected_kpis TEXT[], -- KPIs affected by this insight
    
    -- Recommendations
    recommended_actions JSONB, -- Specific actions recommended
    action_priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    implementation_complexity VARCHAR(20), -- 'low', 'medium', 'high'
    
    -- Follow-up
    requires_attention BOOLEAN DEFAULT true,
    assigned_to VARCHAR(100),
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'new', -- 'new', 'reviewing', 'acknowledged', 'acting', 'resolved', 'dismissed'
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    -- Validation
    accuracy_validated BOOLEAN DEFAULT false,
    validation_score DECIMAL(3,2), -- How accurate was this insight (0.0-1.0)
    validation_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alert definitions and rules
CREATE TABLE alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL, -- 'threshold', 'anomaly', 'trend', 'compliance', 'forecast'
    alert_category VARCHAR(50) NOT NULL, -- 'operational', 'quality', 'performance', 'system'
    
    -- Rule definition
    description TEXT NOT NULL,
    condition_logic JSONB NOT NULL, -- Alert condition logic
    data_sources TEXT[] NOT NULL, -- Data sources to monitor
    
    -- Trigger conditions
    threshold_config JSONB, -- Threshold-based conditions
    time_window_minutes INTEGER DEFAULT 5, -- Time window for evaluation
    min_occurrences INTEGER DEFAULT 1, -- Minimum occurrences to trigger
    
    -- Severity levels
    severity_level VARCHAR(20) NOT NULL, -- 'info', 'warning', 'error', 'critical'
    escalation_rules JSONB, -- Escalation configuration
    
    -- Notification settings
    notification_enabled BOOLEAN DEFAULT true,
    notification_channels TEXT[] DEFAULT ARRAY['email'], -- 'email', 'sms', 'slack', 'webhook'
    notification_recipients TEXT[] NOT NULL,
    notification_template TEXT,
    
    -- Suppression rules
    suppression_enabled BOOLEAN DEFAULT false,
    suppression_duration_minutes INTEGER DEFAULT 60, -- Suppress similar alerts
    suppression_conditions JSONB, -- Conditions for suppression
    
    -- Business context
    business_impact VARCHAR(20) DEFAULT 'medium', -- Business impact of this alert
    sla_related BOOLEAN DEFAULT false,
    compliance_related BOOLEAN DEFAULT false,
    
    -- Activation
    active BOOLEAN DEFAULT true,
    active_hours JSONB, -- When this rule is active (24/7 or business hours)
    maintenance_mode BOOLEAN DEFAULT false,
    
    -- Performance
    evaluation_frequency_seconds INTEGER DEFAULT 60, -- How often to evaluate
    max_alerts_per_hour INTEGER DEFAULT 10, -- Rate limiting
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(rule_name)
);

-- Alert instances and tracking
CREATE TABLE alert_instances (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES alert_rules(rule_id) ON DELETE CASCADE,
    
    -- Alert details
    alert_title VARCHAR(200) NOT NULL,
    alert_message TEXT NOT NULL,
    severity_level VARCHAR(20) NOT NULL,
    
    -- Trigger details
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    trigger_data JSONB NOT NULL, -- Data that triggered the alert
    condition_details JSONB, -- Details about which conditions were met
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'acknowledged', 'investigating', 'resolved', 'false_positive'
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(100),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    -- Notification tracking
    notifications_sent INTEGER DEFAULT 0,
    notification_channels_used TEXT[],
    last_notification_at TIMESTAMP WITH TIME ZONE,
    
    -- Business impact
    actual_business_impact VARCHAR(20), -- Actual impact observed
    downtime_minutes INTEGER, -- If this caused downtime
    financial_impact_rubles DECIMAL(10,2),
    
    -- Root cause analysis
    root_cause VARCHAR(100),
    contributing_factors TEXT[],
    preventive_actions TEXT[],
    
    -- False positive tracking
    false_positive BOOLEAN DEFAULT false,
    false_positive_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (triggered_at);

-- Create monthly partitions for alert instances
CREATE TABLE alert_instances_2024_01 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE alert_instances_2024_02 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE alert_instances_2024_03 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE alert_instances_2024_04 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE alert_instances_2024_05 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE alert_instances_2024_06 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE alert_instances_2024_07 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE alert_instances_2024_08 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE alert_instances_2024_09 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE alert_instances_2024_10 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE alert_instances_2024_11 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE alert_instances_2024_12 PARTITION OF alert_instances
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE alert_instances_2025_01 PARTITION OF alert_instances
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Performance Optimization and Indexes
-- =====================================================================================

-- Dashboards indexes
CREATE INDEX idx_dashboards_type ON dashboards(dashboard_type);
CREATE INDEX idx_dashboards_category ON dashboards(dashboard_category);
CREATE INDEX idx_dashboards_owner ON dashboards(owner_id);
CREATE INDEX idx_dashboards_status ON dashboards(status);
CREATE INDEX idx_dashboards_last_accessed ON dashboards(last_accessed_at);

-- Dashboard Widgets indexes
CREATE INDEX idx_dashboard_widgets_dashboard_id ON dashboard_widgets(dashboard_id);
CREATE INDEX idx_dashboard_widgets_type ON dashboard_widgets(widget_type);
CREATE INDEX idx_dashboard_widgets_position ON dashboard_widgets(position_x, position_y);

-- Report Templates indexes
CREATE INDEX idx_report_templates_type ON report_templates(template_type);
CREATE INDEX idx_report_templates_category ON report_templates(report_category);
CREATE INDEX idx_report_templates_created_by ON report_templates(created_by);
CREATE INDEX idx_report_templates_status ON report_templates(status);

-- Data Streams indexes
CREATE INDEX idx_data_streams_type ON data_streams(stream_type);
CREATE INDEX idx_data_streams_status ON data_streams(status);
CREATE INDEX idx_data_streams_last_activity ON data_streams(last_activity_at);

-- Stream Subscriptions indexes
CREATE INDEX idx_stream_subscriptions_stream_id ON stream_subscriptions(stream_id);
CREATE INDEX idx_stream_subscriptions_type ON stream_subscriptions(subscriber_type);
CREATE INDEX idx_stream_subscriptions_status ON stream_subscriptions(status);

-- Report Instances indexes (on partitioned table)
CREATE INDEX idx_report_instances_template_id ON report_instances(template_id);
CREATE INDEX idx_report_instances_generated_by ON report_instances(generated_by);
CREATE INDEX idx_report_instances_status ON report_instances(generation_status);
CREATE INDEX idx_report_instances_generation_time ON report_instances(generation_timestamp);

-- Visualizations indexes
CREATE INDEX idx_visualizations_type ON visualizations(visualization_type);
CREATE INDEX idx_visualizations_created_by ON visualizations(created_by);
CREATE INDEX idx_visualizations_status ON visualizations(status);

-- KPI Definitions indexes
CREATE INDEX idx_kpi_definitions_category ON kpi_definitions(kpi_category);
CREATE INDEX idx_kpi_definitions_owner ON kpi_definitions(business_owner);
CREATE INDEX idx_kpi_definitions_importance ON kpi_definitions(strategic_importance);
CREATE INDEX idx_kpi_definitions_status ON kpi_definitions(status);

-- KPI Measurements indexes (on partitioned table)
CREATE INDEX idx_kpi_measurements_kpi_id ON kpi_measurements(kpi_id);
CREATE INDEX idx_kpi_measurements_timestamp ON kpi_measurements(measurement_timestamp);
CREATE INDEX idx_kpi_measurements_period ON kpi_measurements(measurement_period);
CREATE INDEX idx_kpi_measurements_status ON kpi_measurements(status);

-- Automated Insights indexes
CREATE INDEX idx_automated_insights_type ON automated_insights(insight_type);
CREATE INDEX idx_automated_insights_category ON automated_insights(insight_category);
CREATE INDEX idx_automated_insights_status ON automated_insights(status);
CREATE INDEX idx_automated_insights_impact ON automated_insights(impact_level);
CREATE INDEX idx_automated_insights_detection ON automated_insights(detection_timestamp);

-- Alert Rules indexes
CREATE INDEX idx_alert_rules_type ON alert_rules(rule_type);
CREATE INDEX idx_alert_rules_category ON alert_rules(alert_category);
CREATE INDEX idx_alert_rules_severity ON alert_rules(severity_level);
CREATE INDEX idx_alert_rules_active ON alert_rules(active);

-- Alert Instances indexes (on partitioned table)
CREATE INDEX idx_alert_instances_rule_id ON alert_instances(rule_id);
CREATE INDEX idx_alert_instances_status ON alert_instances(status);
CREATE INDEX idx_alert_instances_severity ON alert_instances(severity_level);
CREATE INDEX idx_alert_instances_triggered_at ON alert_instances(triggered_at);

-- Advanced Functions for Reporting and Analytics
-- =====================================================================================

-- Function to create a new dashboard
CREATE OR REPLACE FUNCTION create_dashboard(
    p_dashboard_name VARCHAR(100),
    p_dashboard_type VARCHAR(50),
    p_dashboard_category VARCHAR(50),
    p_owner_id VARCHAR(100),
    p_layout_config JSONB,
    p_theme_config JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_dashboard_id UUID;
BEGIN
    INSERT INTO dashboards (
        dashboard_name, dashboard_type, dashboard_category,
        owner_id, layout_config, theme_config
    ) VALUES (
        p_dashboard_name, p_dashboard_type, p_dashboard_category,
        p_owner_id, p_layout_config, p_theme_config
    ) RETURNING dashboard_id INTO v_dashboard_id;
    
    RETURN v_dashboard_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add widget to dashboard
CREATE OR REPLACE FUNCTION add_dashboard_widget(
    p_dashboard_id UUID,
    p_widget_name VARCHAR(100),
    p_widget_type VARCHAR(50),
    p_position_x INTEGER,
    p_position_y INTEGER,
    p_width INTEGER,
    p_height INTEGER,
    p_widget_config JSONB,
    p_data_source_config JSONB
)
RETURNS UUID AS $$
DECLARE
    v_widget_id UUID;
BEGIN
    INSERT INTO dashboard_widgets (
        dashboard_id, widget_name, widget_type,
        position_x, position_y, width, height,
        widget_config, data_source_config
    ) VALUES (
        p_dashboard_id, p_widget_name, p_widget_type,
        p_position_x, p_position_y, p_width, p_height,
        p_widget_config, p_data_source_config
    ) RETURNING widget_id INTO v_widget_id;
    
    RETURN v_widget_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate report from template
CREATE OR REPLACE FUNCTION generate_report(
    p_template_id UUID,
    p_report_name VARCHAR(200),
    p_generated_by VARCHAR(100),
    p_parameters JSONB DEFAULT NULL,
    p_date_range_start TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_date_range_end TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_instance_id UUID;
BEGIN
    INSERT INTO report_instances (
        template_id, report_name, generated_by,
        report_parameters, date_range_start, date_range_end,
        generation_status
    ) VALUES (
        p_template_id, p_report_name, p_generated_by,
        p_parameters, p_date_range_start, p_date_range_end,
        'generating'
    ) RETURNING instance_id INTO v_instance_id;
    
    -- Here would be the actual report generation logic
    -- For now, just mark as completed
    UPDATE report_instances 
    SET generation_status = 'completed',
        generation_end_time = NOW(),
        generation_duration_seconds = 10
    WHERE instance_id = v_instance_id;
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function to record KPI measurement
CREATE OR REPLACE FUNCTION record_kpi_measurement(
    p_kpi_id UUID,
    p_measured_value DECIMAL(15,6),
    p_measurement_period VARCHAR(20),
    p_target_value DECIMAL(15,6) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_measurement_id UUID;
    v_variance DECIMAL(15,6);
    v_variance_pct DECIMAL(8,4);
    v_status VARCHAR(20);
    v_upper_threshold DECIMAL(15,6);
    v_lower_threshold DECIMAL(15,6);
BEGIN
    -- Get thresholds from KPI definition
    SELECT upper_threshold, lower_threshold 
    INTO v_upper_threshold, v_lower_threshold
    FROM kpi_definitions 
    WHERE kpi_id = p_kpi_id;
    
    -- Calculate variance if target provided
    IF p_target_value IS NOT NULL THEN
        v_variance := p_measured_value - p_target_value;
        v_variance_pct := CASE 
            WHEN p_target_value != 0 THEN (v_variance / p_target_value) * 100 
            ELSE NULL 
        END;
    END IF;
    
    -- Determine status based on thresholds
    v_status := CASE
        WHEN v_upper_threshold IS NOT NULL AND p_measured_value > v_upper_threshold THEN 'critical'
        WHEN v_lower_threshold IS NOT NULL AND p_measured_value < v_lower_threshold THEN 'critical'
        WHEN v_variance_pct IS NOT NULL AND ABS(v_variance_pct) > 10 THEN 'warning'
        ELSE 'good'
    END;
    
    INSERT INTO kpi_measurements (
        kpi_id, measured_value, measurement_period,
        target_value, variance_from_target, variance_percentage, status
    ) VALUES (
        p_kpi_id, p_measured_value, p_measurement_period,
        p_target_value, v_variance, v_variance_pct, v_status
    ) RETURNING measurement_id INTO v_measurement_id;
    
    RETURN v_measurement_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create automated insight
CREATE OR REPLACE FUNCTION create_automated_insight(
    p_insight_type VARCHAR(50),
    p_insight_category VARCHAR(50),
    p_title VARCHAR(200),
    p_description TEXT,
    p_confidence_score DECIMAL(3,2),
    p_impact_level VARCHAR(20),
    p_data_sources TEXT[],
    p_insight_data JSONB
)
RETURNS UUID AS $$
DECLARE
    v_insight_id UUID;
BEGIN
    INSERT INTO automated_insights (
        insight_type, insight_category, title, description,
        confidence_score, impact_level, data_sources, insight_data
    ) VALUES (
        p_insight_type, p_insight_category, p_title, p_description,
        p_confidence_score, p_impact_level, p_data_sources, p_insight_data
    ) RETURNING insight_id INTO v_insight_id;
    
    RETURN v_insight_id;
END;
$$ LANGUAGE plpgsql;

-- Function to trigger alert
CREATE OR REPLACE FUNCTION trigger_alert(
    p_rule_id UUID,
    p_alert_title VARCHAR(200),
    p_alert_message TEXT,
    p_trigger_data JSONB
)
RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
    v_severity VARCHAR(20);
BEGIN
    -- Get rule severity
    SELECT severity_level INTO v_severity
    FROM alert_rules
    WHERE rule_id = p_rule_id AND active = true;
    
    IF v_severity IS NULL THEN
        RAISE EXCEPTION 'Alert rule not found or not active';
    END IF;
    
    INSERT INTO alert_instances (
        rule_id, alert_title, alert_message,
        severity_level, trigger_data
    ) VALUES (
        p_rule_id, p_alert_title, p_alert_message,
        v_severity, p_trigger_data
    ) RETURNING alert_id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- Views for Reporting and Analytics
-- =====================================================================================

-- Dashboard usage analytics view
CREATE VIEW v_dashboard_usage_analytics AS
SELECT 
    d.dashboard_id,
    d.dashboard_name,
    d.dashboard_type,
    d.dashboard_category,
    d.owner_id,
    d.access_count,
    d.last_accessed_at,
    
    -- Widget count
    COUNT(dw.widget_id) as widget_count,
    COUNT(CASE WHEN dw.widget_type = 'chart' THEN 1 END) as chart_count,
    COUNT(CASE WHEN dw.widget_type = 'table' THEN 1 END) as table_count,
    COUNT(CASE WHEN dw.widget_type = 'metric' THEN 1 END) as metric_count,
    
    -- Usage patterns
    CASE 
        WHEN d.last_accessed_at >= NOW() - INTERVAL '7 days' THEN 'active'
        WHEN d.last_accessed_at >= NOW() - INTERVAL '30 days' THEN 'occasional'
        WHEN d.last_accessed_at >= NOW() - INTERVAL '90 days' THEN 'infrequent'
        ELSE 'dormant'
    END as usage_pattern,
    
    -- Performance indicators
    d.refresh_frequency_seconds,
    d.real_time_enabled,
    d.cache_enabled
    
FROM dashboards d
LEFT JOIN dashboard_widgets dw ON d.dashboard_id = dw.dashboard_id
WHERE d.status = 'active'
GROUP BY d.dashboard_id, d.dashboard_name, d.dashboard_type, d.dashboard_category, 
         d.owner_id, d.access_count, d.last_accessed_at, d.refresh_frequency_seconds,
         d.real_time_enabled, d.cache_enabled
ORDER BY d.access_count DESC, d.last_accessed_at DESC;

-- KPI performance summary view
CREATE VIEW v_kpi_performance_summary AS
SELECT 
    kd.kpi_id,
    kd.kpi_name,
    kd.kpi_category,
    kd.unit_of_measurement,
    kd.target_value,
    kd.business_owner,
    kd.strategic_importance,
    
    -- Current performance
    km_current.measured_value as current_value,
    km_current.status as current_status,
    km_current.variance_from_target as current_variance,
    km_current.measurement_timestamp as last_measurement,
    
    -- Trend analysis (last 30 days)
    AVG(km_trend.measured_value) as avg_30d,
    STDDEV(km_trend.measured_value) as stddev_30d,
    COUNT(km_trend.measurement_id) as measurements_30d,
    
    -- Performance indicators
    COUNT(CASE WHEN km_trend.status = 'good' THEN 1 END)::float / 
    COUNT(km_trend.measurement_id) as success_rate_30d,
    
    COUNT(CASE WHEN km_trend.status = 'critical' THEN 1 END) as critical_count_30d,
    
    -- Trend direction
    CASE 
        WHEN AVG(km_recent.measured_value) > AVG(km_older.measured_value) THEN 'improving'
        WHEN AVG(km_recent.measured_value) < AVG(km_older.measured_value) THEN 'declining'
        ELSE 'stable'
    END as trend_direction
    
FROM kpi_definitions kd
LEFT JOIN LATERAL (
    SELECT * FROM kpi_measurements km 
    WHERE km.kpi_id = kd.kpi_id 
    ORDER BY measurement_timestamp DESC 
    LIMIT 1
) km_current ON true
LEFT JOIN kpi_measurements km_trend ON kd.kpi_id = km_trend.kpi_id
    AND km_trend.measurement_timestamp >= NOW() - INTERVAL '30 days'
LEFT JOIN kpi_measurements km_recent ON kd.kpi_id = km_recent.kpi_id
    AND km_recent.measurement_timestamp >= NOW() - INTERVAL '7 days'
LEFT JOIN kpi_measurements km_older ON kd.kpi_id = km_older.kpi_id
    AND km_older.measurement_timestamp BETWEEN NOW() - INTERVAL '14 days' AND NOW() - INTERVAL '7 days'
WHERE kd.status = 'active'
GROUP BY kd.kpi_id, kd.kpi_name, kd.kpi_category, kd.unit_of_measurement,
         kd.target_value, kd.business_owner, kd.strategic_importance,
         km_current.measured_value, km_current.status, km_current.variance_from_target,
         km_current.measurement_timestamp
ORDER BY kd.strategic_importance DESC, critical_count_30d DESC;

-- Alert effectiveness analytics view
CREATE VIEW v_alert_effectiveness_analytics AS
SELECT 
    ar.rule_id,
    ar.rule_name,
    ar.rule_type,
    ar.alert_category,
    ar.severity_level,
    
    -- Alert volume
    COUNT(ai.alert_id) as total_alerts,
    COUNT(CASE WHEN ai.triggered_at >= NOW() - INTERVAL '7 days' THEN 1 END) as alerts_7d,
    COUNT(CASE WHEN ai.triggered_at >= NOW() - INTERVAL '30 days' THEN 1 END) as alerts_30d,
    
    -- Response metrics
    AVG(EXTRACT(EPOCH FROM (ai.acknowledged_at - ai.triggered_at))/60) as avg_response_time_minutes,
    AVG(EXTRACT(EPOCH FROM (ai.resolved_at - ai.triggered_at))/60) as avg_resolution_time_minutes,
    
    -- Quality metrics
    COUNT(CASE WHEN ai.status = 'resolved' THEN 1 END)::float / 
    COUNT(ai.alert_id) as resolution_rate,
    
    COUNT(CASE WHEN ai.false_positive = true THEN 1 END)::float / 
    COUNT(ai.alert_id) as false_positive_rate,
    
    -- Business impact
    SUM(ai.financial_impact_rubles) as total_financial_impact,
    AVG(ai.financial_impact_rubles) as avg_financial_impact,
    
    -- Recent activity
    MAX(ai.triggered_at) as last_alert_time,
    COUNT(CASE WHEN ai.status = 'open' THEN 1 END) as open_alerts
    
FROM alert_rules ar
LEFT JOIN alert_instances ai ON ar.rule_id = ai.rule_id
WHERE ar.active = true
GROUP BY ar.rule_id, ar.rule_name, ar.rule_type, ar.alert_category, ar.severity_level
ORDER BY total_alerts DESC, false_positive_rate ASC;

-- Demo Data for Reporting Platform
-- =====================================================================================

-- Insert sample dashboards
INSERT INTO dashboards (dashboard_name, dashboard_type, dashboard_category, owner_id, layout_config, target_audience) VALUES
('Операционная панель WFM', 'operational', 'workforce', 'manager_operations', '{"grid": {"columns": 12, "rows": 8}, "widgets": []}', ARRAY['managers', 'supervisors']),
('Исполнительная панель', 'executive', 'performance', 'director_wfm', '{"grid": {"columns": 6, "rows": 4}, "widgets": []}', ARRAY['executives', 'directors']),
('Панель качества обслуживания', 'operational', 'quality', 'manager_quality', '{"grid": {"columns": 8, "rows": 6}, "widgets": []}', ARRAY['quality_managers', 'team_leads']),
('Панель соответствия требованиям', 'compliance', 'compliance', 'compliance_officer', '{"grid": {"columns": 10, "rows": 8}, "widgets": []}', ARRAY['compliance_officers', 'hr_managers']);

-- Insert sample widgets
INSERT INTO dashboard_widgets (dashboard_id, widget_name, widget_type, position_x, position_y, width, height, widget_config, data_source_config) VALUES
((SELECT dashboard_id FROM dashboards WHERE dashboard_name = 'Операционная панель WFM'), 'Service Level Real-time', 'gauge', 0, 0, 3, 3, '{"min": 0, "max": 100, "target": 80, "unit": "%"}', '{"query": "SELECT service_level FROM realtime_metrics WHERE metric_date = CURRENT_DATE"}'),
((SELECT dashboard_id FROM dashboards WHERE dashboard_name = 'Операционная панель WFM'), 'Call Volume Forecast', 'line_chart', 3, 0, 6, 4, '{"forecast_enabled": true, "confidence_intervals": true}', '{"query": "SELECT timestamp, forecast_value FROM forecast_results WHERE target_timestamp >= NOW()"}'),
((SELECT dashboard_id FROM dashboards WHERE dashboard_name = 'Исполнительная панель'), 'Key Metrics Overview', 'metric', 0, 0, 6, 2, '{"metrics": ["service_level", "aht", "occupancy", "shrinkage"]}', '{"query": "SELECT * FROM kpi_measurements WHERE measurement_date = CURRENT_DATE"}');

-- Insert sample KPI definitions
INSERT INTO kpi_definitions (kpi_name, kpi_category, description, calculation_formula, calculation_logic, data_sources, unit_of_measurement, target_value, upper_threshold, lower_threshold, business_owner, created_by) VALUES
('Service Level 80/20', 'operational', 'Percentage of calls answered within 20 seconds', 'Calls answered within 20 seconds / Total calls * 100', '{"numerator": "calls_answered_20s", "denominator": "total_calls", "multiply": 100}', ARRAY['call_statistics'], 'percentage', 80.0, 90.0, 70.0, 'operations_manager', 'kpi_admin'),
('Average Handle Time', 'operational', 'Average time spent handling customer calls', 'Total handle time / Number of calls handled', '{"numerator": "total_handle_time_seconds", "denominator": "calls_handled"}', ARRAY['agent_statistics'], 'seconds', 240.0, 300.0, 180.0, 'operations_manager', 'kpi_admin'),
('Agent Occupancy', 'efficiency', 'Percentage of time agents are handling calls vs. available time', 'Total talk time / Total available time * 100', '{"numerator": "total_talk_time", "denominator": "total_available_time", "multiply": 100}', ARRAY['agent_statistics'], 'percentage', 85.0, 95.0, 75.0, 'workforce_manager', 'kpi_admin'),
('Schedule Adherence', 'quality', 'Percentage of time agents follow their scheduled times', 'Adherent time / Scheduled time * 100', '{"numerator": "adherent_time", "denominator": "scheduled_time", "multiply": 100}', ARRAY['schedule_adherence'], 'percentage', 90.0, 95.0, 85.0, 'workforce_manager', 'kpi_admin');

-- Insert sample KPI measurements
INSERT INTO kpi_measurements (kpi_id, measured_value, measurement_period, target_value, status) VALUES
((SELECT kpi_id FROM kpi_definitions WHERE kpi_name = 'Service Level 80/20'), 82.5, 'daily', 80.0, 'good'),
((SELECT kpi_id FROM kpi_definitions WHERE kpi_name = 'Average Handle Time'), 235.0, 'daily', 240.0, 'good'),
((SELECT kpi_id FROM kpi_definitions WHERE kpi_name = 'Agent Occupancy'), 87.2, 'daily', 85.0, 'good'),
((SELECT kpi_id FROM kpi_definitions WHERE kpi_name = 'Schedule Adherence'), 88.7, 'daily', 90.0, 'warning');

-- Insert sample report templates
INSERT INTO report_templates (template_name, template_type, report_category, report_structure, data_sources, created_by) VALUES
('Daily Operations Report', 'standard', 'operational', '{"sections": ["executive_summary", "service_metrics", "agent_performance", "forecast_accuracy"]}', '["kpi_measurements", "agent_statistics", "forecast_results"]', 'reporting_team'),
('Weekly WFM Performance', 'analytical', 'analytical', '{"sections": ["weekly_trends", "schedule_optimization", "capacity_analysis", "recommendations"]}', '["optimization_results", "schedule_adherence", "capacity_utilization"]', 'reporting_team'),
('Monthly Compliance Report', 'regulatory', 'compliance', '{"sections": ["labor_law_compliance", "working_time_analysis", "violation_summary", "corrective_actions"]}', '["compliance_violations", "working_time_regulations", "labor_law_rules"]', 'compliance_team');

-- Insert sample data streams
INSERT INTO data_streams (stream_name, stream_type, data_source, stream_query, sampling_frequency_seconds) VALUES
('Real-time Service Level', 'real_time_metrics', 'call_statistics', 'SELECT queue_id, service_level, calls_waiting FROM queue_metrics', 10),
('Agent Status Updates', 'events', 'agent_status', 'SELECT agent_id, status, timestamp FROM agent_status_changes', 5),
('System Alerts', 'alerts', 'alert_instances', 'SELECT * FROM alert_instances WHERE status = ''open''', 30);

-- Insert sample alert rules
INSERT INTO alert_rules (rule_name, rule_type, alert_category, description, condition_logic, data_sources, severity_level, notification_recipients, created_by) VALUES
('Critical Service Level Drop', 'threshold', 'operational', 'Alert when service level drops below 70%', '{"metric": "service_level", "operator": "<", "value": 70, "duration_minutes": 5}', ARRAY['queue_metrics'], 'critical', ARRAY['operations_manager@company.com', 'director@company.com'], 'alert_admin'),
('High Agent Overtime', 'threshold', 'compliance', 'Alert when agent overtime exceeds daily limits', '{"metric": "daily_overtime_hours", "operator": ">", "value": 4, "entity": "agent"}', ARRAY['working_time_logs'], 'high', ARRAY['hr_manager@company.com', 'compliance_officer@company.com'], 'alert_admin'),
('Forecast Accuracy Degradation', 'trend', 'performance', 'Alert when forecast accuracy drops significantly', '{"metric": "forecast_mape", "trend": "increasing", "threshold": 15, "period": "7days"}', ARRAY['forecast_accuracy'], 'warning', ARRAY['forecast_manager@company.com'], 'alert_admin');

-- Insert sample automated insights
INSERT INTO automated_insights (insight_type, insight_category, title, description, confidence_score, impact_level, data_sources, insight_data) VALUES
('anomaly', 'performance', 'Unusual spike in call volume detected', 'Call volume is 25% higher than expected for this time period, potentially due to system outage or marketing campaign', 0.89, 'high', ARRAY['call_statistics', 'forecast_results'], '{"expected_volume": 150, "actual_volume": 187, "deviation": 24.7, "time_period": "14:00-15:00"}'),
('trend', 'efficiency', 'Improving schedule adherence trend', 'Schedule adherence has improved by 5% over the last 2 weeks, indicating better workforce management practices', 0.92, 'medium', ARRAY['schedule_adherence'], '{"trend_direction": "improving", "improvement_percentage": 5.2, "period": "14_days", "confidence_interval": [4.1, 6.3]}'),
('recommendation', 'operational', 'Optimize break scheduling for better coverage', 'Current break scheduling creates coverage gaps during peak hours. Staggered breaks could improve service level by 3-5%', 0.78, 'medium', ARRAY['schedule_data', 'service_metrics'], '{"current_service_level": 79.5, "potential_improvement": 4.2, "implementation_effort": "medium"}');

-- Comments for Documentation
-- =====================================================================================

COMMENT ON TABLE dashboards IS 'Dashboard definitions with layout and access control';
COMMENT ON TABLE dashboard_widgets IS 'Individual widgets within dashboards with positioning and configuration';
COMMENT ON TABLE report_templates IS 'Report template definitions with structure and data sources';
COMMENT ON TABLE data_streams IS 'Real-time data streaming configurations';
COMMENT ON TABLE stream_subscriptions IS 'Subscriptions to data streams for real-time updates';
COMMENT ON TABLE report_instances IS 'Generated report instances with tracking (partitioned by generation time)';
COMMENT ON TABLE visualizations IS 'Visualization configurations and templates';
COMMENT ON TABLE kpi_definitions IS 'KPI definitions with calculation logic and thresholds';
COMMENT ON TABLE kpi_measurements IS 'KPI measurements and historical tracking (partitioned by date)';
COMMENT ON TABLE automated_insights IS 'AI-generated insights with business recommendations';
COMMENT ON TABLE alert_rules IS 'Alert rule definitions with conditions and notifications';
COMMENT ON TABLE alert_instances IS 'Alert instances and tracking (partitioned by trigger time)';

COMMENT ON COLUMN dashboards.layout_config IS 'JSON configuration for dashboard grid layout and positioning';
COMMENT ON COLUMN dashboard_widgets.widget_config IS 'Widget-specific configuration including chart settings';
COMMENT ON COLUMN data_streams.aggregation_window_seconds IS 'Time window for aggregating streaming data';
COMMENT ON COLUMN kpi_definitions.calculation_logic IS 'Machine-readable calculation logic for automated KPI computation';
COMMENT ON COLUMN alert_rules.condition_logic IS 'JSON-based alert condition logic for automated evaluation';

-- Schema completion marker
INSERT INTO schema_migrations (schema_name, version, description, applied_at) 
VALUES ('124_advanced_reporting_dashboard_system', '1.0.0', 'Enterprise reporting platform with real-time streaming and advanced analytics', NOW());