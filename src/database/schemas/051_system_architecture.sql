-- =============================================================================
-- 051_system_architecture.sql
-- EXACT BDD Implementation: Argus WFM System Architecture with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 01-system-architecture.feature (87 lines)
-- Purpose: System architecture management with dual-system support and multi-site hierarchy
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SYSTEM COMPONENTS
-- =============================================================================

-- System component definitions from BDD lines 7-10
CREATE TABLE system_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_id VARCHAR(50) NOT NULL UNIQUE,
    component_name VARCHAR(200) NOT NULL,
    component_type VARCHAR(50) NOT NULL CHECK (component_type IN (
        'administrative_system', 'employee_portal', 'api_gateway', 
        'reporting_service', 'integration_service'
    )),
    
    -- URL and access configuration from BDD lines 8-10
    base_url VARCHAR(500) NOT NULL,
    access_path VARCHAR(200),
    purpose TEXT NOT NULL,
    
    -- System configuration
    authentication_method VARCHAR(50) DEFAULT 'credentials' CHECK (authentication_method IN (
        'credentials', 'sso', 'token_based', 'certificate', 'integrated'
    )),
    requires_internal_network BOOLEAN DEFAULT false,
    
    -- Status and health
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance', 'deprecated')),
    health_check_url VARCHAR(500),
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'degraded', 'unhealthy', 'unknown')),
    
    -- Version and deployment
    version VARCHAR(50),
    deployment_environment VARCHAR(20) DEFAULT 'production' CHECK (deployment_environment IN (
        'development', 'testing', 'staging', 'production'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. SYSTEM ACCESS PERMISSIONS
-- =============================================================================

-- Access control from BDD lines 26-35
CREATE TABLE system_access_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    user_role VARCHAR(50) NOT NULL,
    
    -- Permission configuration
    permission_type VARCHAR(50) NOT NULL CHECK (permission_type IN (
        'read', 'write', 'admin', 'limited', 'full_access', 'view_only'
    )),
    permission_scope VARCHAR(100) NOT NULL,
    
    -- Navigation access from BDD lines 18-24
    allowed_navigation_options JSONB DEFAULT '[]',
    restricted_functions JSONB DEFAULT '[]',
    
    -- Conditional access from BDD lines 45-49
    access_requirements JSONB DEFAULT '{}',
    network_restrictions JSONB DEFAULT '{}',
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES system_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 3. LOCATION HIERARCHY
-- =============================================================================

-- Multi-site location hierarchy from BDD lines 55-60
CREATE TABLE location_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id VARCHAR(50) NOT NULL UNIQUE,
    location_name VARCHAR(200) NOT NULL,
    location_type VARCHAR(50) NOT NULL CHECK (location_type IN (
        'corporate', 'regional', 'city', 'site'
    )),
    
    -- Hierarchy structure from BDD lines 56-60
    hierarchy_level INTEGER NOT NULL CHECK (hierarchy_level >= 1 AND hierarchy_level <= 10),
    parent_location_id VARCHAR(50),
    management_scope TEXT,
    
    -- Location properties from BDD lines 62-68
    full_address TEXT,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    operating_hours JSONB DEFAULT '{}',
    max_capacity INTEGER CHECK (max_capacity > 0),
    
    -- Status from BDD line 68
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance')),
    
    -- Geographic and contact information
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(100),
    manager_employee_id UUID,
    
    -- Business metadata
    cost_center VARCHAR(50),
    business_unit VARCHAR(100),
    region VARCHAR(100),
    country_code VARCHAR(3),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_location_id) REFERENCES location_hierarchy(location_id) ON DELETE SET NULL,
    FOREIGN KEY (manager_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Ensure hierarchy consistency
    CHECK (hierarchy_level = 1 OR parent_location_id IS NOT NULL)
);

-- =============================================================================
-- 4. LOCATION BUSINESS RULES
-- =============================================================================

-- Location-specific business rules from BDD lines 69-74
CREATE TABLE location_business_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    location_id VARCHAR(50) NOT NULL,
    
    -- Business rule configuration from BDD lines 70-74
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN (
        'schedule_coordination', 'resource_sharing', 'reporting_aggregation', 
        'security_isolation', 'capacity_management', 'operational_hours'
    )),
    rule_name VARCHAR(200) NOT NULL,
    rule_description TEXT,
    
    -- Implementation details from BDD lines 70-74
    implementation_method VARCHAR(100),
    enforcement_level VARCHAR(20) DEFAULT 'mandatory' CHECK (enforcement_level IN (
        'mandatory', 'recommended', 'optional', 'advisory'
    )),
    
    -- Rule configuration
    rule_parameters JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    exception_conditions JSONB DEFAULT '{}',
    
    -- Approval and workflow
    requires_approval BOOLEAN DEFAULT false,
    approval_workflow JSONB DEFAULT '{}',
    auto_enforcement BOOLEAN DEFAULT true,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (location_id) REFERENCES location_hierarchy(location_id) ON DELETE CASCADE
);

-- =============================================================================
-- 5. LOCATION SYNCHRONIZATION
-- =============================================================================

-- Location synchronization configuration from BDD lines 75-80
CREATE TABLE location_synchronization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_id VARCHAR(50) NOT NULL UNIQUE,
    source_location_id VARCHAR(50) NOT NULL,
    target_location_id VARCHAR(50),
    
    -- Sync configuration from BDD lines 76-80
    sync_type VARCHAR(50) NOT NULL CHECK (sync_type IN (
        'real_time_events', 'schedule_updates', 'reporting_data', 'configuration_changes'
    )),
    sync_frequency VARCHAR(30) NOT NULL CHECK (sync_frequency IN (
        'immediate', 'every_15_minutes', 'hourly', 'on_demand', 'daily'
    )),
    
    -- Data elements from BDD lines 77-80
    data_elements JSONB NOT NULL,
    
    -- Conflict resolution from BDD lines 77-80
    conflict_resolution_strategy VARCHAR(50) DEFAULT 'timestamp_priority' CHECK (conflict_resolution_strategy IN (
        'timestamp_priority', 'business_rules_validation', 'master_site_wins', 'hierarchical_inheritance'
    )),
    
    -- Sync status and monitoring
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    next_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'skipped'
    )),
    sync_duration_ms INTEGER,
    records_processed INTEGER DEFAULT 0,
    errors_encountered INTEGER DEFAULT 0,
    
    -- Configuration
    is_active BOOLEAN DEFAULT true,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    timeout_seconds INTEGER DEFAULT 300,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (source_location_id) REFERENCES location_hierarchy(location_id) ON DELETE CASCADE,
    FOREIGN KEY (target_location_id) REFERENCES location_hierarchy(location_id) ON DELETE CASCADE
);

-- =============================================================================
-- 6. LOCATION REPORTING CONFIGURATION
-- =============================================================================

-- Location-specific reporting from BDD lines 81-86
CREATE TABLE location_reporting_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_config_id VARCHAR(50) NOT NULL UNIQUE,
    location_id VARCHAR(50) NOT NULL,
    
    -- Report configuration from BDD lines 82-86
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'site_performance', 'regional_summary', 'corporate_dashboard', 'comparative_analysis'
    )),
    report_name VARCHAR(200) NOT NULL,
    report_scope VARCHAR(50) NOT NULL CHECK (report_scope IN (
        'individual_site', 'regional_rollup', 'all_sites', 'cross_site_comparison'
    )),
    
    -- Scheduling from BDD lines 82-86
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN (
        'real_time', 'daily', 'weekly', 'monthly', 'quarterly', 'on_demand'
    )),
    generation_time TIME DEFAULT '06:00:00',
    timezone_for_generation VARCHAR(50) DEFAULT 'UTC',
    
    -- Recipients from BDD lines 82-86
    recipients JSONB NOT NULL,
    recipient_roles JSONB DEFAULT '[]',
    
    -- Report content configuration
    metrics_included JSONB DEFAULT '[]',
    filters_applied JSONB DEFAULT '{}',
    aggregation_rules JSONB DEFAULT '{}',
    
    -- Delivery configuration
    delivery_method VARCHAR(30) DEFAULT 'email' CHECK (delivery_method IN (
        'email', 'dashboard', 'api', 'file_export', 'notification'
    )),
    delivery_format VARCHAR(20) DEFAULT 'pdf' CHECK (delivery_format IN (
        'pdf', 'excel', 'csv', 'json', 'html'
    )),
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    last_generated TIMESTAMP WITH TIME ZONE,
    next_generation TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (location_id) REFERENCES location_hierarchy(location_id) ON DELETE CASCADE
);

-- =============================================================================
-- 7. SYSTEM HEALTH MONITORING
-- =============================================================================

-- System component health tracking
CREATE TABLE system_health_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monitoring_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50) NOT NULL,
    
    -- Health metrics
    response_time_ms INTEGER,
    availability_percentage DECIMAL(5,2) CHECK (availability_percentage >= 0.0 AND availability_percentage <= 100.0),
    error_rate_percentage DECIMAL(5,2) CHECK (error_rate_percentage >= 0.0 AND error_rate_percentage <= 100.0),
    throughput_requests_per_minute INTEGER,
    
    -- Status assessment
    health_status VARCHAR(20) NOT NULL CHECK (health_status IN ('healthy', 'degraded', 'unhealthy', 'unknown')),
    status_details JSONB DEFAULT '{}',
    
    -- Monitoring metadata
    check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    check_type VARCHAR(30) DEFAULT 'automated' CHECK (check_type IN (
        'automated', 'manual', 'synthetic', 'user_reported'
    )),
    monitoring_source VARCHAR(100),
    
    -- Alert configuration
    alert_triggered BOOLEAN DEFAULT false,
    alert_level VARCHAR(20) CHECK (alert_level IN ('info', 'warning', 'critical', 'emergency')),
    alert_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES system_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 8. USER SESSION TRACKING
-- =============================================================================

-- User session tracking for system access
CREATE TABLE user_session_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) NOT NULL UNIQUE,
    user_id VARCHAR(50) NOT NULL,
    component_id VARCHAR(50) NOT NULL,
    
    -- Session details
    login_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    logout_timestamp TIMESTAMP WITH TIME ZONE,
    session_duration_minutes INTEGER,
    
    -- Access information
    access_method VARCHAR(50) DEFAULT 'web' CHECK (access_method IN (
        'web', 'mobile', 'api', 'desktop_app'
    )),
    ip_address INET,
    user_agent TEXT,
    
    -- Navigation tracking from BDD lines 18-24
    navigation_options_accessed JSONB DEFAULT '[]',
    functions_used JSONB DEFAULT '[]',
    restricted_attempts JSONB DEFAULT '[]',
    
    -- Session quality
    pages_visited INTEGER DEFAULT 0,
    actions_performed INTEGER DEFAULT 0,
    errors_encountered INTEGER DEFAULT 0,
    
    -- Status
    session_status VARCHAR(20) DEFAULT 'active' CHECK (session_status IN (
        'active', 'expired', 'terminated', 'timeout'
    )),
    termination_reason VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES system_components(component_id) ON DELETE CASCADE
);

-- =============================================================================
-- 9. SYSTEM CONFIGURATION MANAGEMENT
-- =============================================================================

-- System-wide configuration management
CREATE TABLE system_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    component_id VARCHAR(50),
    location_id VARCHAR(50),
    
    -- Configuration details
    config_category VARCHAR(50) NOT NULL CHECK (config_category IN (
        'authentication', 'security', 'performance', 'feature_flags', 
        'integration', 'ui_customization', 'business_rules'
    )),
    config_name VARCHAR(200) NOT NULL,
    config_value JSONB NOT NULL,
    config_type VARCHAR(30) DEFAULT 'application' CHECK (config_type IN (
        'system', 'application', 'user', 'location', 'global'
    )),
    
    -- Inheritance and overrides
    inherits_from VARCHAR(50),
    override_level INTEGER DEFAULT 1,
    can_be_overridden BOOLEAN DEFAULT true,
    
    -- Validation and constraints
    validation_schema JSONB DEFAULT '{}',
    constraints JSONB DEFAULT '{}',
    default_value JSONB,
    
    -- Change management
    version VARCHAR(20) DEFAULT '1.0',
    change_reason TEXT,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (component_id) REFERENCES system_components(component_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES location_hierarchy(location_id) ON DELETE CASCADE,
    FOREIGN KEY (inherits_from) REFERENCES system_configuration(config_id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- System component queries
CREATE INDEX idx_system_components_type ON system_components(component_type);
CREATE INDEX idx_system_components_status ON system_components(status) WHERE status = 'active';
CREATE INDEX idx_system_components_health ON system_components(health_status);

-- Access permission queries
CREATE INDEX idx_system_access_permissions_component ON system_access_permissions(component_id);
CREATE INDEX idx_system_access_permissions_role ON system_access_permissions(user_role);
CREATE INDEX idx_system_access_permissions_active ON system_access_permissions(is_active) WHERE is_active = true;

-- Location hierarchy queries
CREATE INDEX idx_location_hierarchy_type ON location_hierarchy(location_type);
CREATE INDEX idx_location_hierarchy_parent ON location_hierarchy(parent_location_id);
CREATE INDEX idx_location_hierarchy_level ON location_hierarchy(hierarchy_level);
CREATE INDEX idx_location_hierarchy_status ON location_hierarchy(status) WHERE status = 'active';

-- Business rules queries
CREATE INDEX idx_location_business_rules_location ON location_business_rules(location_id);
CREATE INDEX idx_location_business_rules_type ON location_business_rules(rule_type);
CREATE INDEX idx_location_business_rules_active ON location_business_rules(is_active) WHERE is_active = true;

-- Synchronization queries
CREATE INDEX idx_location_sync_source ON location_synchronization(source_location_id);
CREATE INDEX idx_location_sync_target ON location_synchronization(target_location_id);
CREATE INDEX idx_location_sync_type ON location_synchronization(sync_type);
CREATE INDEX idx_location_sync_next ON location_synchronization(next_sync_timestamp) WHERE sync_status = 'pending';

-- Reporting queries
CREATE INDEX idx_location_reporting_location ON location_reporting_config(location_id);
CREATE INDEX idx_location_reporting_type ON location_reporting_config(report_type);
CREATE INDEX idx_location_reporting_frequency ON location_reporting_config(frequency);
CREATE INDEX idx_location_reporting_next ON location_reporting_config(next_generation);

-- Health monitoring queries
CREATE INDEX idx_system_health_component ON system_health_monitoring(component_id);
CREATE INDEX idx_system_health_timestamp ON system_health_monitoring(check_timestamp);
CREATE INDEX idx_system_health_status ON system_health_monitoring(health_status);
CREATE INDEX idx_system_health_alerts ON system_health_monitoring(alert_triggered) WHERE alert_triggered = true;

-- Session tracking queries
CREATE INDEX idx_user_session_user ON user_session_tracking(user_id);
CREATE INDEX idx_user_session_component ON user_session_tracking(component_id);
CREATE INDEX idx_user_session_login ON user_session_tracking(login_timestamp);
CREATE INDEX idx_user_session_status ON user_session_tracking(session_status);

-- Configuration queries
CREATE INDEX idx_system_config_component ON system_configuration(component_id);
CREATE INDEX idx_system_config_location ON system_configuration(location_id);
CREATE INDEX idx_system_config_category ON system_configuration(config_category);
CREATE INDEX idx_system_config_active ON system_configuration(is_active) WHERE is_active = true;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_system_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER system_components_update_trigger
    BEFORE UPDATE ON system_components
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER system_access_permissions_update_trigger
    BEFORE UPDATE ON system_access_permissions
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER location_hierarchy_update_trigger
    BEFORE UPDATE ON location_hierarchy
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER location_business_rules_update_trigger
    BEFORE UPDATE ON location_business_rules
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER location_synchronization_update_trigger
    BEFORE UPDATE ON location_synchronization
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER location_reporting_config_update_trigger
    BEFORE UPDATE ON location_reporting_config
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER user_session_tracking_update_trigger
    BEFORE UPDATE ON user_session_tracking
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER system_configuration_update_trigger
    BEFORE UPDATE ON system_configuration
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active system components with health status
CREATE VIEW v_active_system_components AS
SELECT 
    sc.id,
    sc.component_id,
    sc.component_name,
    sc.component_type,
    sc.base_url,
    sc.status,
    sc.health_status,
    sc.last_health_check,
    sc.version
FROM system_components sc
WHERE sc.status = 'active'
ORDER BY sc.component_type, sc.component_name;

-- Location hierarchy with parent information
CREATE VIEW v_location_hierarchy_tree AS
SELECT 
    lh.id,
    lh.location_id,
    lh.location_name,
    lh.location_type,
    lh.hierarchy_level,
    lh.parent_location_id,
    parent.location_name as parent_location_name,
    lh.status,
    lh.timezone,
    lh.max_capacity
FROM location_hierarchy lh
LEFT JOIN location_hierarchy parent ON lh.parent_location_id = parent.location_id
WHERE lh.status = 'active'
ORDER BY lh.hierarchy_level, lh.location_name;

-- Pending synchronization tasks
CREATE VIEW v_pending_synchronization_tasks AS
SELECT 
    ls.id,
    ls.sync_id,
    ls.sync_type,
    ls.sync_frequency,
    source.location_name as source_location,
    target.location_name as target_location,
    ls.next_sync_timestamp,
    ls.retry_count,
    EXTRACT(MINUTES FROM CURRENT_TIMESTAMP - ls.next_sync_timestamp) as minutes_overdue
FROM location_synchronization ls
JOIN location_hierarchy source ON ls.source_location_id = source.location_id
LEFT JOIN location_hierarchy target ON ls.target_location_id = target.location_id
WHERE ls.is_active = true
  AND ls.sync_status = 'pending'
  AND ls.next_sync_timestamp <= CURRENT_TIMESTAMP
ORDER BY ls.next_sync_timestamp ASC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert system components from BDD lines 8-10
INSERT INTO system_components (component_id, component_name, component_type, base_url, purpose) VALUES
('argus_admin', 'Argus Administrative System', 'administrative_system', 'https://cc1010wfmcc.argustelecom.ru', 'Backend management and configuration'),
('argus_employee', 'Argus Employee Portal', 'employee_portal', 'https://lkcc1010wfmcc.argustelecom.ru', 'Employee self-service functions');

-- Insert location hierarchy sample
INSERT INTO location_hierarchy (location_id, location_name, location_type, hierarchy_level, timezone) VALUES
('corp_hq', 'Corporate Headquarters', 'corporate', 1, 'UTC'),
('region_moscow', 'Moscow Regional Office', 'regional', 2, 'Europe/Moscow'),
('city_moscow_center', 'Moscow City Center', 'city', 3, 'Europe/Moscow'),
('site_moscow_cc1', 'Moscow Call Center 1', 'site', 4, 'Europe/Moscow');

-- Update hierarchy relationships
UPDATE location_hierarchy SET parent_location_id = 'corp_hq' WHERE location_id = 'region_moscow';
UPDATE location_hierarchy SET parent_location_id = 'region_moscow' WHERE location_id = 'city_moscow_center';
UPDATE location_hierarchy SET parent_location_id = 'city_moscow_center' WHERE location_id = 'site_moscow_cc1';

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE system_components IS 'BDD Lines 7-10: Dual system architecture with administrative and employee portal components';
COMMENT ON TABLE system_access_permissions IS 'BDD Lines 26-35: Access control and permission management for system components';
COMMENT ON TABLE location_hierarchy IS 'BDD Lines 55-68: Multi-site location management with hierarchical structure';
COMMENT ON TABLE location_business_rules IS 'BDD Lines 69-74: Location-specific business rules and enforcement';
COMMENT ON TABLE location_synchronization IS 'BDD Lines 75-80: Inter-location synchronization configuration and tracking';
COMMENT ON TABLE location_reporting_config IS 'BDD Lines 81-86: Location-specific reporting configuration and scheduling';

COMMENT ON TABLE system_health_monitoring IS 'System component health tracking and monitoring';
COMMENT ON TABLE user_session_tracking IS 'User session and navigation tracking for system components';
COMMENT ON TABLE system_configuration IS 'System-wide configuration management with inheritance support';