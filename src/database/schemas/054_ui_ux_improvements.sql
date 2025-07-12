-- =============================================================================
-- 054_ui_ux_improvements.sql
-- EXACT BDD Implementation: UI/UX Improvements with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 25-ui-ux-improvements.feature (261 lines)
-- Purpose: Comprehensive UI/UX enhancement tracking with user experience optimization
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. UI THEMES AND VISUAL DESIGN
-- =============================================================================

-- Theme configurations from BDD line 18
CREATE TABLE ui_themes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    theme_id VARCHAR(50) NOT NULL UNIQUE,
    theme_name VARCHAR(200) NOT NULL,
    theme_description TEXT,
    
    -- Theme configuration from BDD line 18
    color_scheme JSONB NOT NULL,
    layout_type VARCHAR(50) NOT NULL CHECK (layout_type IN (
        'fixed', 'fluid', 'responsive', 'adaptive', 'hybrid'
    )),
    accessibility_features JSONB DEFAULT '{}',
    
    -- Design elements from BDD lines 43-48
    css_grid_config JSONB DEFAULT '{}',
    flexbox_config JSONB DEFAULT '{}',
    breakpoint_definitions JSONB DEFAULT '{}',
    typography_scaling JSONB DEFAULT '{}',
    
    -- Color and visual settings
    primary_colors JSONB DEFAULT '{}',
    secondary_colors JSONB DEFAULT '{}',
    accent_colors JSONB DEFAULT '{}',
    neutral_colors JSONB DEFAULT '{}',
    semantic_colors JSONB DEFAULT '{}',
    
    -- Accessibility from BDD lines 68-74
    wcag_compliance_level VARCHAR(10) DEFAULT 'AA' CHECK (wcag_compliance_level IN ('A', 'AA', 'AAA')),
    contrast_ratio_minimum DECIMAL(3,2) DEFAULT 4.5,
    supports_high_contrast BOOLEAN DEFAULT true,
    supports_text_scaling BOOLEAN DEFAULT true,
    supports_screen_readers BOOLEAN DEFAULT true,
    
    -- Theme metadata
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    theme_version VARCHAR(20) DEFAULT '1.0',
    created_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. USER INTERFACE PREFERENCES
-- =============================================================================

-- User UI preferences from BDD line 19
CREATE TABLE user_interface_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pref_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    theme_id VARCHAR(50),
    
    -- Layout preferences from BDD lines 93-98
    layout_preferences JSONB DEFAULT '{}',
    dashboard_customization JSONB DEFAULT '{}',
    widget_configuration JSONB DEFAULT '{}',
    menu_customization JSONB DEFAULT '{}',
    notification_preferences JSONB DEFAULT '{}',
    
    -- Accessibility settings from BDD line 19
    accessibility_settings JSONB DEFAULT '{}',
    screen_reader_enabled BOOLEAN DEFAULT false,
    keyboard_navigation_enabled BOOLEAN DEFAULT true,
    high_contrast_enabled BOOLEAN DEFAULT false,
    text_size_multiplier DECIMAL(3,2) DEFAULT 1.0,
    voice_control_enabled BOOLEAN DEFAULT false,
    
    -- Mobile optimization from BDD lines 50-55
    mobile_preferences JSONB DEFAULT '{}',
    gesture_support_enabled BOOLEAN DEFAULT true,
    offline_capability_enabled BOOLEAN DEFAULT true,
    pwa_features_enabled BOOLEAN DEFAULT true,
    location_services_enabled BOOLEAN DEFAULT false,
    
    -- Personalization from BDD lines 100-105
    adaptive_interface_enabled BOOLEAN DEFAULT true,
    contextual_help_enabled BOOLEAN DEFAULT true,
    workflow_optimizations JSONB DEFAULT '{}',
    content_filtering_preferences JSONB DEFAULT '{}',
    quick_actions_config JSONB DEFAULT '{}',
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    last_updated_component VARCHAR(100),
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('synced', 'pending', 'conflict')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (theme_id) REFERENCES ui_themes(theme_id) ON DELETE SET NULL,
    
    UNIQUE(user_id, pref_id)
);

-- =============================================================================
-- 3. UI COMPONENTS MANAGEMENT
-- =============================================================================

-- Interface components from BDD line 20
CREATE TABLE ui_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_id VARCHAR(50) NOT NULL UNIQUE,
    component_name VARCHAR(200) NOT NULL,
    component_description TEXT,
    
    -- Component configuration from BDD line 20
    component_type VARCHAR(50) NOT NULL CHECK (component_type IN (
        'navigation', 'form', 'display', 'input', 'feedback', 'layout', 'data_visualization', 'collaboration'
    )),
    default_properties JSONB NOT NULL,
    customizable BOOLEAN DEFAULT true,
    
    -- Responsive design from BDD lines 43-48
    responsive_breakpoints JSONB DEFAULT '{}',
    touch_optimization JSONB DEFAULT '{}',
    image_optimization_config JSONB DEFAULT '{}',
    
    -- Accessibility features from BDD lines 68-74
    aria_labels JSONB DEFAULT '{}',
    keyboard_support JSONB DEFAULT '{}',
    screen_reader_support JSONB DEFAULT '{}',
    high_contrast_support BOOLEAN DEFAULT true,
    
    -- Performance configuration from BDD lines 118-123
    load_optimization_config JSONB DEFAULT '{}',
    memory_optimization_config JSONB DEFAULT '{}',
    caching_strategy VARCHAR(30) DEFAULT 'default' CHECK (caching_strategy IN (
        'none', 'memory', 'local_storage', 'session_storage', 'default'
    )),
    
    -- Navigation features from BDD lines 143-148
    navigation_features JSONB DEFAULT '{}',
    search_functionality JSONB DEFAULT '{}',
    filter_sort_capabilities JSONB DEFAULT '{}',
    
    -- Component metadata
    version VARCHAR(20) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT true,
    requires_authentication BOOLEAN DEFAULT true,
    performance_impact VARCHAR(20) DEFAULT 'low' CHECK (performance_impact IN ('low', 'medium', 'high')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. UI CUSTOMIZATIONS TRACKING
-- =============================================================================

-- User customizations from BDD line 21
CREATE TABLE ui_customizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    custom_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    component_id VARCHAR(50) NOT NULL,
    
    -- Customization details from BDD line 21
    custom_properties JSONB NOT NULL,
    applied_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Customization metadata
    customization_type VARCHAR(50) NOT NULL CHECK (customization_type IN (
        'theme', 'layout', 'behavior', 'accessibility', 'performance', 'workflow'
    )),
    source VARCHAR(30) DEFAULT 'manual' CHECK (source IN ('manual', 'automatic', 'template', 'recommendation')),
    
    -- Impact tracking
    performance_impact JSONB DEFAULT '{}',
    accessibility_impact JSONB DEFAULT '{}',
    user_satisfaction_impact DECIMAL(3,2),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    rollback_available BOOLEAN DEFAULT true,
    previous_configuration JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 5. UI ANALYTICS AND USAGE TRACKING
-- =============================================================================

-- Usage analytics from BDD line 22
CREATE TABLE ui_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analytics_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    component_id VARCHAR(50),
    
    -- Interaction tracking from BDD line 22
    interaction_type VARCHAR(50) NOT NULL CHECK (interaction_type IN (
        'click', 'hover', 'scroll', 'keyboard', 'touch', 'voice', 'view', 'focus', 'error'
    )),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100) NOT NULL,
    
    -- Detailed analytics from BDD lines 107-111
    usage_context JSONB DEFAULT '{}',
    device_information JSONB DEFAULT '{}',
    browser_information JSONB DEFAULT '{}',
    screen_resolution VARCHAR(20),
    viewport_size VARCHAR(20),
    
    -- Performance metrics from BDD lines 132-136
    load_time_ms INTEGER,
    response_time_ms INTEGER,
    memory_usage_mb DECIMAL(8,2),
    cpu_usage_percentage DECIMAL(5,2),
    network_latency_ms INTEGER,
    
    -- User flow analytics from BDD lines 157-161
    previous_component VARCHAR(50),
    next_component VARCHAR(50),
    task_completion_status VARCHAR(20) CHECK (task_completion_status IN ('completed', 'abandoned', 'error', 'timeout')),
    error_details JSONB,
    
    -- Accessibility analytics
    accessibility_tool_used VARCHAR(50),
    keyboard_only_navigation BOOLEAN DEFAULT false,
    screen_reader_active BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. UI FEEDBACK COLLECTION
-- =============================================================================

-- User feedback from BDD line 23
CREATE TABLE ui_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feedback_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    component_id VARCHAR(50),
    
    -- Feedback details from BDD line 23
    feedback_type VARCHAR(50) NOT NULL CHECK (feedback_type IN (
        'bug_report', 'feature_request', 'usability_issue', 'accessibility_issue', 
        'performance_issue', 'satisfaction_rating', 'suggestion', 'complaint'
    )),
    rating INTEGER CHECK (rating >= 1 AND rating <= 10),
    comments TEXT,
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Feedback context from BDD lines 218-223
    context_information JSONB DEFAULT '{}',
    reproduction_steps TEXT,
    expected_behavior TEXT,
    actual_behavior TEXT,
    
    -- Feedback processing
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(20) DEFAULT 'submitted' CHECK (status IN (
        'submitted', 'reviewed', 'in_progress', 'resolved', 'closed', 'duplicate'
    )),
    assigned_to UUID,
    resolution_notes TEXT,
    resolution_date TIMESTAMP WITH TIME ZONE,
    
    -- Impact assessment
    affects_accessibility BOOLEAN DEFAULT false,
    affects_performance BOOLEAN DEFAULT false,
    affects_functionality BOOLEAN DEFAULT false,
    user_impact_level VARCHAR(20) DEFAULT 'medium' CHECK (user_impact_level IN ('low', 'medium', 'high')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 7. RESPONSIVE DESIGN CONFIGURATION
-- =============================================================================

-- Responsive design implementation from BDD lines 42-61
CREATE TABLE responsive_design_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    
    -- Design elements from BDD lines 43-48
    flexible_layout_config JSONB NOT NULL,
    breakpoint_management JSONB NOT NULL,
    touch_optimization_config JSONB DEFAULT '{}',
    image_optimization_config JSONB DEFAULT '{}',
    typography_scaling_config JSONB DEFAULT '{}',
    
    -- Mobile features from BDD lines 50-55
    gesture_support_config JSONB DEFAULT '{}',
    offline_capability_config JSONB DEFAULT '{}',
    pwa_features_config JSONB DEFAULT '{}',
    performance_optimization_config JSONB DEFAULT '{}',
    location_services_config JSONB DEFAULT '{}',
    
    -- Device optimizations from BDD lines 57-61
    screen_adaptation_config JSONB DEFAULT '{}',
    input_optimization_config JSONB DEFAULT '{}',
    network_optimization_config JSONB DEFAULT '{}',
    battery_optimization_config JSONB DEFAULT '{}',
    
    -- Configuration metadata
    target_devices JSONB DEFAULT '[]',
    testing_status VARCHAR(20) DEFAULT 'pending' CHECK (testing_status IN (
        'pending', 'tested', 'passed', 'failed', 'needs_review'
    )),
    performance_score DECIMAL(3,2),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 8. ACCESSIBILITY COMPLIANCE TRACKING
-- =============================================================================

-- Accessibility compliance from BDD lines 67-86
CREATE TABLE accessibility_compliance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compliance_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    
    -- Accessibility features from BDD lines 68-74
    screen_reader_support_level VARCHAR(20) DEFAULT 'full' CHECK (screen_reader_support_level IN (
        'none', 'partial', 'full', 'enhanced'
    )),
    keyboard_navigation_support BOOLEAN DEFAULT true,
    high_contrast_support BOOLEAN DEFAULT true,
    text_scaling_support BOOLEAN DEFAULT true,
    voice_control_support BOOLEAN DEFAULT false,
    
    -- Inclusive design features from BDD lines 75-80
    color_blind_support BOOLEAN DEFAULT true,
    cognitive_accessibility_score DECIMAL(3,2),
    motor_accessibility_score DECIMAL(3,2),
    hearing_accessibility_score DECIMAL(3,2),
    multi_language_support BOOLEAN DEFAULT false,
    
    -- WCAG compliance
    wcag_level VARCHAR(10) DEFAULT 'AA' CHECK (wcag_level IN ('A', 'AA', 'AAA')),
    compliance_percentage DECIMAL(5,2) CHECK (compliance_percentage >= 0.0 AND compliance_percentage <= 100.0),
    
    -- Monitoring from BDD lines 82-86
    last_compliance_check TIMESTAMP WITH TIME ZONE,
    automated_testing_results JSONB DEFAULT '{}',
    manual_testing_results JSONB DEFAULT '{}',
    user_feedback_summary JSONB DEFAULT '{}',
    
    -- Issues and improvements
    identified_issues JSONB DEFAULT '[]',
    improvement_recommendations JSONB DEFAULT '[]',
    compliance_score DECIMAL(3,2),
    
    -- Status
    compliance_status VARCHAR(20) DEFAULT 'compliant' CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'partial', 'testing', 'unknown'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 9. PERFORMANCE OPTIMIZATION TRACKING
-- =============================================================================

-- Performance optimization from BDD lines 117-136
CREATE TABLE ui_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metrics_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    user_id UUID,
    
    -- Performance optimizations from BDD lines 118-123
    load_time_ms INTEGER,
    runtime_performance_score DECIMAL(3,2),
    memory_usage_mb DECIMAL(8,2),
    network_requests_count INTEGER,
    cache_hit_rate_percentage DECIMAL(5,2),
    
    -- Speed enhancements from BDD lines 125-130
    lazy_loading_enabled BOOLEAN DEFAULT false,
    prefetching_enabled BOOLEAN DEFAULT false,
    compression_ratio DECIMAL(3,2),
    minification_enabled BOOLEAN DEFAULT false,
    cdn_usage BOOLEAN DEFAULT false,
    
    -- Performance targets and thresholds
    target_load_time_ms INTEGER DEFAULT 3000,
    target_memory_usage_mb DECIMAL(8,2) DEFAULT 50.0,
    performance_budget_kb INTEGER DEFAULT 2000,
    
    -- Monitoring metrics from BDD lines 132-136
    real_time_performance_score DECIMAL(3,2),
    user_experience_score DECIMAL(3,2),
    resource_usage_score DECIMAL(3,2),
    error_rate_percentage DECIMAL(5,2),
    
    -- Measurement metadata
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    measurement_context JSONB DEFAULT '{}',
    device_type VARCHAR(30),
    network_type VARCHAR(30),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 10. DATA VISUALIZATION CONFIGURATION
-- =============================================================================

-- Data visualization from BDD lines 167-186
CREATE TABLE data_visualization_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viz_config_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    
    -- Visualization types from BDD lines 168-173
    chart_types_supported JSONB DEFAULT '[]',
    dashboard_layout_config JSONB DEFAULT '{}',
    real_time_update_config JSONB DEFAULT '{}',
    data_filtering_config JSONB DEFAULT '{}',
    export_capabilities JSONB DEFAULT '{}',
    
    -- Information design from BDD lines 175-180
    information_hierarchy JSONB DEFAULT '{}',
    visual_indicators_config JSONB DEFAULT '{}',
    color_coding_rules JSONB DEFAULT '{}',
    typography_config JSONB DEFAULT '{}',
    white_space_config JSONB DEFAULT '{}',
    
    -- Visualization analytics from BDD lines 182-186
    usage_analytics_enabled BOOLEAN DEFAULT true,
    effectiveness_tracking_enabled BOOLEAN DEFAULT true,
    performance_monitoring_enabled BOOLEAN DEFAULT true,
    feedback_collection_enabled BOOLEAN DEFAULT true,
    
    -- Configuration metadata
    default_chart_type VARCHAR(50),
    refresh_interval_seconds INTEGER DEFAULT 30,
    data_point_limit INTEGER DEFAULT 1000,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 11. COLLABORATION FEATURES CONFIGURATION
-- =============================================================================

-- Collaboration features from BDD lines 192-211
CREATE TABLE collaboration_features_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collab_config_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    
    -- Collaboration enhancements from BDD lines 193-198
    real_time_collaboration_enabled BOOLEAN DEFAULT false,
    commenting_system_enabled BOOLEAN DEFAULT false,
    activity_feeds_enabled BOOLEAN DEFAULT false,
    notification_system_enabled BOOLEAN DEFAULT true,
    presence_indicators_enabled BOOLEAN DEFAULT false,
    
    -- Team experience features from BDD lines 200-205
    team_dashboards_enabled BOOLEAN DEFAULT false,
    permission_visualization_enabled BOOLEAN DEFAULT true,
    workflow_visualization_enabled BOOLEAN DEFAULT false,
    team_performance_metrics_enabled BOOLEAN DEFAULT false,
    shared_resources_enabled BOOLEAN DEFAULT false,
    
    -- Collaboration configuration
    max_concurrent_collaborators INTEGER DEFAULT 10,
    comment_moderation_enabled BOOLEAN DEFAULT false,
    activity_retention_days INTEGER DEFAULT 30,
    notification_batching_enabled BOOLEAN DEFAULT true,
    
    -- Analytics from BDD lines 207-211
    collaboration_metrics_enabled BOOLEAN DEFAULT true,
    team_performance_tracking_enabled BOOLEAN DEFAULT true,
    communication_analysis_enabled BOOLEAN DEFAULT false,
    resource_utilization_tracking_enabled BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES ui_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 12. DESIGN SYSTEM AND CONSISTENCY
-- =============================================================================

-- Design system from BDD lines 243-261
CREATE TABLE design_system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    design_config_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Consistency features from BDD lines 243-248
    design_language_definition JSONB NOT NULL,
    component_library_config JSONB NOT NULL,
    style_guide_rules JSONB NOT NULL,
    interaction_patterns JSONB NOT NULL,
    information_architecture JSONB NOT NULL,
    
    -- System cohesion from BDD lines 250-255
    cross_module_navigation_config JSONB DEFAULT '{}',
    shared_state_management_config JSONB DEFAULT '{}',
    common_terminology JSONB DEFAULT '{}',
    integrated_help_system_config JSONB DEFAULT '{}',
    unified_search_config JSONB DEFAULT '{}',
    
    -- Monitoring from BDD lines 257-261
    consistency_audit_schedule VARCHAR(30) DEFAULT 'weekly',
    last_consistency_audit TIMESTAMP WITH TIME ZONE,
    consistency_score DECIMAL(3,2),
    integration_test_results JSONB DEFAULT '{}',
    
    -- Version control
    version VARCHAR(20) DEFAULT '1.0',
    change_log JSONB DEFAULT '[]',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Theme and preference queries
CREATE INDEX idx_ui_themes_active ON ui_themes(is_active) WHERE is_active = true;
CREATE INDEX idx_ui_themes_default ON ui_themes(is_default) WHERE is_default = true;
CREATE INDEX idx_user_interface_preferences_user ON user_interface_preferences(user_id);
CREATE INDEX idx_user_interface_preferences_theme ON user_interface_preferences(theme_id);
CREATE INDEX idx_user_interface_preferences_active ON user_interface_preferences(is_active) WHERE is_active = true;

-- Component and customization queries
CREATE INDEX idx_ui_components_type ON ui_components(component_type);
CREATE INDEX idx_ui_components_active ON ui_components(is_active) WHERE is_active = true;
CREATE INDEX idx_ui_customizations_user ON ui_customizations(user_id);
CREATE INDEX idx_ui_customizations_component ON ui_customizations(component_id);
CREATE INDEX idx_ui_customizations_active ON ui_customizations(is_active) WHERE is_active = true;

-- Analytics queries
CREATE INDEX idx_ui_analytics_user ON ui_analytics(user_id);
CREATE INDEX idx_ui_analytics_component ON ui_analytics(component_id);
CREATE INDEX idx_ui_analytics_timestamp ON ui_analytics(timestamp);
CREATE INDEX idx_ui_analytics_session ON ui_analytics(session_id);
CREATE INDEX idx_ui_analytics_interaction ON ui_analytics(interaction_type);

-- Feedback queries
CREATE INDEX idx_ui_feedback_user ON ui_feedback(user_id);
CREATE INDEX idx_ui_feedback_component ON ui_feedback(component_id);
CREATE INDEX idx_ui_feedback_type ON ui_feedback(feedback_type);
CREATE INDEX idx_ui_feedback_status ON ui_feedback(status);
CREATE INDEX idx_ui_feedback_priority ON ui_feedback(priority);

-- Configuration queries
CREATE INDEX idx_responsive_design_config_component ON responsive_design_config(component_id);
CREATE INDEX idx_responsive_design_config_active ON responsive_design_config(is_active) WHERE is_active = true;
CREATE INDEX idx_accessibility_compliance_component ON accessibility_compliance(component_id);
CREATE INDEX idx_accessibility_compliance_status ON accessibility_compliance(compliance_status);

-- Performance queries
CREATE INDEX idx_ui_performance_metrics_component ON ui_performance_metrics(component_id);
CREATE INDEX idx_ui_performance_metrics_timestamp ON ui_performance_metrics(measurement_timestamp);
CREATE INDEX idx_ui_performance_metrics_user ON ui_performance_metrics(user_id);

-- Visualization and collaboration queries
CREATE INDEX idx_data_visualization_config_component ON data_visualization_config(component_id);
CREATE INDEX idx_data_visualization_config_active ON data_visualization_config(is_active) WHERE is_active = true;
CREATE INDEX idx_collaboration_features_config_component ON collaboration_features_config(component_id);
CREATE INDEX idx_collaboration_features_config_active ON collaboration_features_config(is_active) WHERE is_active = true;

-- Design system queries
CREATE INDEX idx_design_system_config_active ON design_system_config(is_active) WHERE is_active = true;
CREATE INDEX idx_design_system_config_version ON design_system_config(version);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_ui_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER ui_themes_update_trigger
    BEFORE UPDATE ON ui_themes
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER user_interface_preferences_update_trigger
    BEFORE UPDATE ON user_interface_preferences
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER ui_components_update_trigger
    BEFORE UPDATE ON ui_components
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER ui_customizations_update_trigger
    BEFORE UPDATE ON ui_customizations
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER ui_feedback_update_trigger
    BEFORE UPDATE ON ui_feedback
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER responsive_design_config_update_trigger
    BEFORE UPDATE ON responsive_design_config
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER accessibility_compliance_update_trigger
    BEFORE UPDATE ON accessibility_compliance
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER data_visualization_config_update_trigger
    BEFORE UPDATE ON data_visualization_config
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER collaboration_features_config_update_trigger
    BEFORE UPDATE ON collaboration_features_config
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

CREATE TRIGGER design_system_config_update_trigger
    BEFORE UPDATE ON design_system_config
    FOR EACH ROW EXECUTE FUNCTION update_ui_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active user preferences with theme information
CREATE VIEW v_user_ui_preferences AS
SELECT 
    uip.user_id,
    e.full_name as user_name,
    uip.theme_id,
    ut.theme_name,
    uip.accessibility_settings,
    uip.mobile_preferences,
    uip.adaptive_interface_enabled,
    uip.last_updated_component,
    uip.sync_status
FROM user_interface_preferences uip
JOIN employees e ON uip.user_id = e.id
LEFT JOIN ui_themes ut ON uip.theme_id = ut.theme_id
WHERE uip.is_active = true
ORDER BY e.full_name;

-- Component performance summary
CREATE VIEW v_component_performance_summary AS
SELECT 
    uc.component_id,
    uc.component_name,
    uc.component_type,
    AVG(upm.load_time_ms) as avg_load_time_ms,
    AVG(upm.memory_usage_mb) as avg_memory_usage_mb,
    AVG(upm.real_time_performance_score) as avg_performance_score,
    COUNT(upm.id) as measurement_count,
    MAX(upm.measurement_timestamp) as last_measurement
FROM ui_components uc
LEFT JOIN ui_performance_metrics upm ON uc.component_id = upm.component_id
WHERE uc.is_active = true
  AND upm.measurement_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY uc.component_id, uc.component_name, uc.component_type
ORDER BY avg_performance_score DESC;

-- Accessibility compliance overview
CREATE VIEW v_accessibility_compliance_overview AS
SELECT 
    uc.component_id,
    uc.component_name,
    ac.wcag_level,
    ac.compliance_percentage,
    ac.compliance_status,
    ac.screen_reader_support_level,
    ac.keyboard_navigation_support,
    ac.high_contrast_support,
    ac.last_compliance_check
FROM ui_components uc
JOIN accessibility_compliance ac ON uc.component_id = ac.component_id
WHERE uc.is_active = true
ORDER BY ac.compliance_percentage DESC, uc.component_name;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert default UI themes
INSERT INTO ui_themes (theme_id, theme_name, color_scheme, layout_type, accessibility_features) VALUES
('default_light', 'Default Light Theme', '{"primary": "#007bff", "secondary": "#6c757d", "background": "#ffffff", "text": "#212529"}', 'responsive', '{"high_contrast": true, "screen_reader": true, "keyboard_nav": true}'),
('default_dark', 'Default Dark Theme', '{"primary": "#0d6efd", "secondary": "#6c757d", "background": "#212529", "text": "#ffffff"}', 'responsive', '{"high_contrast": true, "screen_reader": true, "keyboard_nav": true}'),
('high_contrast', 'High Contrast Theme', '{"primary": "#000000", "secondary": "#333333", "background": "#ffffff", "text": "#000000"}', 'responsive', '{"high_contrast": true, "screen_reader": true, "keyboard_nav": true, "color_blind": true}');

-- Update default theme
UPDATE ui_themes SET is_default = true WHERE theme_id = 'default_light';

-- Insert sample UI components
INSERT INTO ui_components (component_id, component_name, component_type, default_properties) VALUES
('nav_main', 'Main Navigation', 'navigation', '{"position": "top", "collapsed": false, "search_enabled": true}'),
('dashboard_widget', 'Dashboard Widget', 'display', '{"refresh_interval": 30, "chart_type": "line", "data_points": 100}'),
('employee_form', 'Employee Form', 'form', '{"validation_enabled": true, "auto_save": true, "required_fields": ["name", "email"]}'),
('data_table', 'Data Table', 'data_visualization', '{"pagination": true, "sorting": true, "filtering": true, "export": true}');

-- Insert sample responsive design configurations
INSERT INTO responsive_design_config (config_id, component_id, flexible_layout_config, breakpoint_management) VALUES
('nav_responsive', 'nav_main', '{"type": "flexbox", "direction": "row", "wrap": true}', '{"mobile": "768px", "tablet": "1024px", "desktop": "1200px"}'),
('dashboard_responsive', 'dashboard_widget', '{"type": "css_grid", "columns": "auto", "gap": "1rem"}', '{"mobile": "768px", "tablet": "1024px", "desktop": "1200px"}');

-- Insert accessibility compliance records
INSERT INTO accessibility_compliance (compliance_id, component_id, wcag_level, compliance_percentage) VALUES
('nav_accessibility', 'nav_main', 'AA', 95.0),
('dashboard_accessibility', 'dashboard_widget', 'AA', 90.0),
('form_accessibility', 'employee_form', 'AAA', 98.0);

-- Insert design system configuration
INSERT INTO design_system_config (design_config_id, design_language_definition, component_library_config, style_guide_rules, interaction_patterns, information_architecture) VALUES
('main_design_system', 
 '{"typography": {"primary": "Inter", "secondary": "Source Code Pro"}, "spacing": {"base": "8px", "scale": 1.5}}',
 '{"version": "2.0", "components_count": 45, "updated": "2025-07-12"}',
 '{"colors": "Material Design 3.0", "spacing": "8px grid", "typography": "Type scale"}',
 '{"buttons": "outlined primary", "forms": "floating labels", "navigation": "persistent drawer"}',
 '{"hierarchy": "3 levels", "navigation": "breadcrumb + sidebar", "search": "global + contextual"}'
);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE ui_themes IS 'BDD Line 18: Theme configurations with color schemes, layouts, and accessibility features';
COMMENT ON TABLE user_interface_preferences IS 'BDD Line 19: User UI preferences with personalization and accessibility settings';
COMMENT ON TABLE ui_components IS 'BDD Line 20: Interface components with responsive design and accessibility support';
COMMENT ON TABLE ui_customizations IS 'BDD Line 21: User customizations tracking with performance and accessibility impact';
COMMENT ON TABLE ui_analytics IS 'BDD Line 22: Usage analytics with interaction tracking and performance metrics';
COMMENT ON TABLE ui_feedback IS 'BDD Line 23: User feedback collection with processing and resolution tracking';

COMMENT ON TABLE responsive_design_config IS 'BDD Lines 42-61: Responsive design implementation with mobile optimization';
COMMENT ON TABLE accessibility_compliance IS 'BDD Lines 67-86: Accessibility compliance tracking with WCAG standards';
COMMENT ON TABLE ui_performance_metrics IS 'BDD Lines 117-136: Performance optimization tracking with speed enhancements';
COMMENT ON TABLE data_visualization_config IS 'BDD Lines 167-186: Data visualization configuration with information design';
COMMENT ON TABLE collaboration_features_config IS 'BDD Lines 192-211: Collaboration features with team experience enhancements';
COMMENT ON TABLE design_system_config IS 'BDD Lines 243-261: Design system consistency with integration monitoring';