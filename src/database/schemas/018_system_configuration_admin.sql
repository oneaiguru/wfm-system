-- =============================================================================
-- 018_system_configuration_admin.sql
-- EXACT BDD Implementation: System Configuration and Administration
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: Multi-tenant system configuration, admin roles, and audit logging
-- Purpose: Comprehensive system configuration with multi-tenant support and audit trails
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SYSTEM CONFIGURATION
-- =============================================================================

-- Global system configuration with multi-tenant support
CREATE TABLE system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    config_name VARCHAR(200) NOT NULL,
    config_description TEXT,
    
    -- Configuration hierarchy
    config_category VARCHAR(50) NOT NULL CHECK (config_category IN (
        'system', 'tenant', 'application', 'integration', 'security', 'performance'
    )),
    config_scope VARCHAR(30) NOT NULL CHECK (config_scope IN (
        'global', 'tenant', 'department', 'user'
    )),
    
    -- Multi-tenant configuration
    tenant_id UUID,
    department_id UUID,
    applies_to_all_tenants BOOLEAN DEFAULT false,
    
    -- Configuration value
    config_type VARCHAR(30) NOT NULL CHECK (config_type IN (
        'string', 'integer', 'decimal', 'boolean', 'json', 'array', 'date', 'time'
    )),
    config_value TEXT NOT NULL,
    default_value TEXT,
    
    -- Validation and constraints
    validation_rules JSONB DEFAULT '{}',
    allowed_values JSONB DEFAULT '[]',
    min_value DECIMAL(15,4),
    max_value DECIMAL(15,4),
    is_encrypted BOOLEAN DEFAULT false,
    
    -- Configuration behavior
    requires_restart BOOLEAN DEFAULT false,
    is_user_configurable BOOLEAN DEFAULT true,
    is_visible_in_ui BOOLEAN DEFAULT true,
    requires_admin_approval BOOLEAN DEFAULT false,
    
    -- Configuration metadata
    display_order INTEGER DEFAULT 1,
    display_group VARCHAR(100),
    help_text TEXT,
    configuration_ui_component VARCHAR(50),
    
    -- Change tracking
    last_modified_by UUID,
    change_reason TEXT,
    previous_value TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE,
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. ADMIN ROLES
-- =============================================================================

-- Administrative role definitions
CREATE TABLE admin_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id VARCHAR(50) NOT NULL UNIQUE,
    role_name VARCHAR(200) NOT NULL,
    role_description TEXT,
    
    -- Role hierarchy
    role_level INTEGER DEFAULT 1 CHECK (role_level >= 1 AND role_level <= 10),
    parent_role_id VARCHAR(50),
    role_category VARCHAR(30) NOT NULL CHECK (role_category IN (
        'system_admin', 'tenant_admin', 'department_admin', 'functional_admin', 'read_only'
    )),
    
    -- Scope and permissions
    permission_scope VARCHAR(30) NOT NULL CHECK (permission_scope IN (
        'global', 'tenant', 'department', 'limited'
    )),
    tenant_scope JSONB DEFAULT '[]', -- Allowed tenant IDs
    department_scope JSONB DEFAULT '[]', -- Allowed department IDs
    
    -- Permission sets
    system_permissions JSONB NOT NULL DEFAULT '{}',
    data_permissions JSONB NOT NULL DEFAULT '{}',
    functional_permissions JSONB NOT NULL DEFAULT '{}',
    
    -- Administrative capabilities
    can_create_users BOOLEAN DEFAULT false,
    can_modify_users BOOLEAN DEFAULT false,
    can_delete_users BOOLEAN DEFAULT false,
    can_manage_roles BOOLEAN DEFAULT false,
    can_view_audit_logs BOOLEAN DEFAULT false,
    can_modify_system_config BOOLEAN DEFAULT false,
    can_manage_integrations BOOLEAN DEFAULT false,
    can_access_all_data BOOLEAN DEFAULT false,
    
    -- Security restrictions
    requires_mfa BOOLEAN DEFAULT true,
    session_timeout_minutes INTEGER DEFAULT 480,
    ip_restrictions JSONB DEFAULT '[]',
    allowed_login_hours JSONB DEFAULT '{}',
    max_concurrent_sessions INTEGER DEFAULT 3,
    
    -- Role behavior
    is_assignable BOOLEAN DEFAULT true,
    requires_approval_to_assign BOOLEAN DEFAULT true,
    auto_expire_days INTEGER,
    
    -- Role metadata
    created_by UUID,
    approved_by UUID,
    approval_required BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_role_id) REFERENCES admin_roles(role_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 3. AUDIT LOGS
-- =============================================================================

-- Comprehensive audit logging
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Event identification
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'user_login', 'user_logout', 'data_create', 'data_update', 'data_delete',
        'config_change', 'role_assignment', 'permission_change', 'system_access',
        'integration_call', 'workflow_action', 'report_generation', 'export_data'
    )),
    event_category VARCHAR(30) NOT NULL CHECK (event_category IN (
        'authentication', 'authorization', 'data_modification', 'system_administration',
        'business_process', 'integration', 'security', 'compliance'
    )),
    event_description TEXT NOT NULL,
    
    -- Event context
    user_id UUID,
    session_id VARCHAR(100),
    tenant_id UUID,
    department_id UUID,
    
    -- System context
    source_system VARCHAR(100) DEFAULT 'WFM',
    source_module VARCHAR(100),
    source_function VARCHAR(100),
    client_ip_address INET,
    user_agent TEXT,
    
    -- Data context
    affected_table VARCHAR(100),
    affected_record_id VARCHAR(100),
    affected_record_type VARCHAR(50),
    
    -- Change details
    field_changes JSONB DEFAULT '{}', -- Before/after values
    operation_data JSONB DEFAULT '{}', -- Additional operation context
    request_data JSONB DEFAULT '{}', -- Original request data
    response_data JSONB DEFAULT '{}', -- Response or result data
    
    -- Event outcome
    event_status VARCHAR(20) NOT NULL CHECK (event_status IN (
        'success', 'failure', 'warning', 'error'
    )),
    error_code VARCHAR(50),
    error_message TEXT,
    
    -- Risk and compliance
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN (
        'low', 'medium', 'high', 'critical'
    )),
    compliance_flags JSONB DEFAULT '[]',
    requires_review BOOLEAN DEFAULT false,
    
    -- Timing
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processing_duration_ms INTEGER,
    
    -- Additional metadata
    correlation_id VARCHAR(100), -- Link related events
    parent_audit_id VARCHAR(50), -- Parent event reference
    tags JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_audit_id) REFERENCES audit_logs(audit_id) ON DELETE SET NULL
);

-- =============================================================================
-- 4. USER ROLE ASSIGNMENTS
-- =============================================================================

-- User administrative role assignments
CREATE TABLE user_role_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Assignment details
    user_id UUID NOT NULL,
    role_id VARCHAR(50) NOT NULL,
    
    -- Assignment scope
    tenant_scope JSONB DEFAULT '[]', -- Specific tenants
    department_scope JSONB DEFAULT '[]', -- Specific departments
    assignment_scope VARCHAR(30) DEFAULT 'full' CHECK (assignment_scope IN (
        'full', 'limited', 'temporary', 'delegated'
    )),
    
    -- Assignment period
    effective_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_end TIMESTAMP WITH TIME ZONE,
    is_permanent BOOLEAN DEFAULT true,
    
    -- Assignment approval
    assignment_status VARCHAR(20) DEFAULT 'pending' CHECK (assignment_status IN (
        'pending', 'approved', 'active', 'suspended', 'expired', 'revoked'
    )),
    assigned_by UUID NOT NULL,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Assignment metadata
    assignment_reason TEXT,
    approval_notes TEXT,
    conditions JSONB DEFAULT '{}',
    
    -- Usage tracking
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES admin_roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(user_id, role_id)
);

-- =============================================================================
-- 5. TENANT CONFIGURATION
-- =============================================================================

-- Tenant-specific configurations
CREATE TABLE tenant_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    tenant_id UUID NOT NULL,
    
    -- Configuration details
    config_name VARCHAR(200) NOT NULL,
    config_category VARCHAR(50) NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(30) NOT NULL,
    
    -- Tenant customization
    inherits_from_global BOOLEAN DEFAULT true,
    overrides_global BOOLEAN DEFAULT false,
    custom_validation_rules JSONB DEFAULT '{}',
    
    -- Configuration behavior
    is_locked BOOLEAN DEFAULT false,
    requires_admin_approval BOOLEAN DEFAULT false,
    can_be_overridden_by_departments BOOLEAN DEFAULT true,
    
    -- Change tracking
    last_modified_by UUID,
    change_reason TEXT,
    previous_value TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(tenant_id, config_name)
);

-- =============================================================================
-- 6. SYSTEM PERMISSIONS
-- =============================================================================

-- Granular system permissions
CREATE TABLE system_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_id VARCHAR(50) NOT NULL UNIQUE,
    permission_name VARCHAR(200) NOT NULL,
    permission_description TEXT,
    
    -- Permission categorization
    permission_category VARCHAR(50) NOT NULL CHECK (permission_category IN (
        'system', 'data', 'functional', 'administrative', 'reporting', 'integration'
    )),
    permission_module VARCHAR(100) NOT NULL,
    permission_action VARCHAR(50) NOT NULL,
    
    -- Permission scope
    applies_to_objects JSONB DEFAULT '[]', -- Tables, entities, or resources
    permission_level VARCHAR(20) DEFAULT 'read' CHECK (permission_level IN (
        'none', 'read', 'write', 'delete', 'admin', 'full'
    )),
    
    -- Permission constraints
    row_level_security BOOLEAN DEFAULT false,
    field_level_security BOOLEAN DEFAULT false,
    time_based_restrictions BOOLEAN DEFAULT false,
    location_based_restrictions BOOLEAN DEFAULT false,
    
    -- Permission behavior
    is_inheritable BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT false,
    can_be_delegated BOOLEAN DEFAULT false,
    risk_level VARCHAR(20) DEFAULT 'low',
    
    -- Metadata
    is_system_permission BOOLEAN DEFAULT false,
    is_custom_permission BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. ROLE PERMISSIONS
-- =============================================================================

-- Role to permission mappings
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id VARCHAR(50) NOT NULL,
    permission_id VARCHAR(50) NOT NULL,
    
    -- Permission granting
    granted BOOLEAN DEFAULT true,
    grant_type VARCHAR(20) DEFAULT 'explicit' CHECK (grant_type IN (
        'explicit', 'inherited', 'delegated', 'temporary'
    )),
    
    -- Permission constraints
    conditions JSONB DEFAULT '{}',
    restrictions JSONB DEFAULT '{}',
    effective_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_end TIMESTAMP WITH TIME ZONE,
    
    -- Granting metadata
    granted_by UUID,
    grant_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (role_id) REFERENCES admin_roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES system_permissions(permission_id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(role_id, permission_id)
);

-- =============================================================================
-- 8. SESSION MANAGEMENT
-- =============================================================================

-- User session tracking and management
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) NOT NULL UNIQUE,
    user_id UUID NOT NULL,
    
    -- Session details
    session_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP WITH TIME ZONE,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Session context
    client_ip_address INET,
    user_agent TEXT,
    login_method VARCHAR(30) DEFAULT 'password',
    mfa_verified BOOLEAN DEFAULT false,
    
    -- Session status
    session_status VARCHAR(20) DEFAULT 'active' CHECK (session_status IN (
        'active', 'expired', 'terminated', 'locked'
    )),
    termination_reason VARCHAR(100),
    
    -- Session metadata
    tenant_id UUID,
    department_id UUID,
    login_location VARCHAR(200),
    session_data JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL
);

-- =============================================================================
-- 9. CONFIGURATION CHANGE HISTORY
-- =============================================================================

-- Configuration change tracking
CREATE TABLE config_change_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    change_id VARCHAR(50) NOT NULL UNIQUE,
    config_id VARCHAR(50) NOT NULL,
    
    -- Change details
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'create', 'update', 'delete', 'activate', 'deactivate'
    )),
    previous_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    
    -- Change context
    changed_by UUID NOT NULL,
    approved_by UUID,
    change_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Impact assessment
    affects_system_restart BOOLEAN DEFAULT false,
    affects_users JSONB DEFAULT '[]',
    affects_tenants JSONB DEFAULT '[]',
    rollback_available BOOLEAN DEFAULT true,
    
    -- Change metadata
    change_notes TEXT,
    validation_results JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (config_id) REFERENCES system_config(config_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 10. SYSTEM HEALTH MONITORING
-- =============================================================================

-- System health and monitoring
CREATE TABLE system_health_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Metric details
    metric_name VARCHAR(200) NOT NULL,
    metric_category VARCHAR(50) NOT NULL CHECK (metric_category IN (
        'performance', 'availability', 'security', 'capacity', 'integration'
    )),
    measurement_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Metric values
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(30),
    threshold_warning DECIMAL(15,4),
    threshold_critical DECIMAL(15,4),
    
    -- System context
    tenant_id UUID,
    system_component VARCHAR(100),
    measurement_source VARCHAR(100),
    
    -- Health status
    health_status VARCHAR(20) DEFAULT 'healthy' CHECK (health_status IN (
        'healthy', 'warning', 'critical', 'unknown'
    )),
    status_reason TEXT,
    
    -- Metadata
    additional_data JSONB DEFAULT '{}',
    correlation_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- System config queries
CREATE INDEX idx_system_config_category ON system_config(config_category);
CREATE INDEX idx_system_config_scope ON system_config(config_scope);
CREATE INDEX idx_system_config_tenant ON system_config(tenant_id);
CREATE INDEX idx_system_config_active ON system_config(is_active) WHERE is_active = true;

-- Admin roles queries
CREATE INDEX idx_admin_roles_category ON admin_roles(role_category);
CREATE INDEX idx_admin_roles_level ON admin_roles(role_level);
CREATE INDEX idx_admin_roles_assignable ON admin_roles(is_assignable) WHERE is_assignable = true;

-- Audit logs queries (critical for performance)
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(event_timestamp);
CREATE INDEX idx_audit_logs_table ON audit_logs(affected_table);
CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_risk ON audit_logs(risk_level);
CREATE INDEX idx_audit_logs_status ON audit_logs(event_status);
CREATE INDEX idx_audit_logs_category ON audit_logs(event_category);
CREATE INDEX idx_audit_logs_correlation ON audit_logs(correlation_id) WHERE correlation_id IS NOT NULL;

-- User role assignments queries
CREATE INDEX idx_user_role_assignments_user ON user_role_assignments(user_id);
CREATE INDEX idx_user_role_assignments_role ON user_role_assignments(role_id);
CREATE INDEX idx_user_role_assignments_status ON user_role_assignments(assignment_status);
CREATE INDEX idx_user_role_assignments_active ON user_role_assignments(assignment_status) WHERE assignment_status = 'active';
CREATE INDEX idx_user_role_assignments_effective ON user_role_assignments(effective_start, effective_end);

-- Tenant configurations queries
CREATE INDEX idx_tenant_configurations_tenant ON tenant_configurations(tenant_id);
CREATE INDEX idx_tenant_configurations_category ON tenant_configurations(config_category);
CREATE INDEX idx_tenant_configurations_name ON tenant_configurations(config_name);

-- System permissions queries
CREATE INDEX idx_system_permissions_category ON system_permissions(permission_category);
CREATE INDEX idx_system_permissions_module ON system_permissions(permission_module);
CREATE INDEX idx_system_permissions_level ON system_permissions(permission_level);

-- Role permissions queries
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);
CREATE INDEX idx_role_permissions_granted ON role_permissions(granted) WHERE granted = true;

-- User sessions queries
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_status ON user_sessions(session_status);
CREATE INDEX idx_user_sessions_last_activity ON user_sessions(last_activity);
CREATE INDEX idx_user_sessions_active ON user_sessions(session_status) WHERE session_status = 'active';

-- Config change history queries
CREATE INDEX idx_config_change_history_config ON config_change_history(config_id);
CREATE INDEX idx_config_change_history_timestamp ON config_change_history(change_timestamp);
CREATE INDEX idx_config_change_history_changed_by ON config_change_history(changed_by);

-- System health metrics queries
CREATE INDEX idx_system_health_metrics_category ON system_health_metrics(metric_category);
CREATE INDEX idx_system_health_metrics_timestamp ON system_health_metrics(measurement_timestamp);
CREATE INDEX idx_system_health_metrics_tenant ON system_health_metrics(tenant_id);
CREATE INDEX idx_system_health_metrics_status ON system_health_metrics(health_status);

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
CREATE TRIGGER system_config_update_trigger
    BEFORE UPDATE ON system_config
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER admin_roles_update_trigger
    BEFORE UPDATE ON admin_roles
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER user_role_assignments_update_trigger
    BEFORE UPDATE ON user_role_assignments
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER tenant_configurations_update_trigger
    BEFORE UPDATE ON tenant_configurations
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

CREATE TRIGGER user_sessions_update_trigger
    BEFORE UPDATE ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION update_system_timestamp();

-- Configuration change tracking trigger
CREATE OR REPLACE FUNCTION track_config_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO config_change_history (
            change_id, config_id, change_type, previous_value, new_value, 
            changed_by, change_reason
        ) VALUES (
            uuid_generate_v4()::varchar, NEW.config_id, 'update', 
            OLD.config_value, NEW.config_value, NEW.last_modified_by, 
            NEW.change_reason
        );
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO config_change_history (
            change_id, config_id, change_type, new_value, changed_by
        ) VALUES (
            uuid_generate_v4()::varchar, NEW.config_id, 'create', 
            NEW.config_value, NEW.last_modified_by
        );
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER system_config_change_trigger
    AFTER INSERT OR UPDATE ON system_config
    FOR EACH ROW EXECUTE FUNCTION track_config_changes();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active user permissions summary
CREATE VIEW v_user_permissions_summary AS
SELECT 
    e.id as user_id,
    e.full_name,
    e.email,
    STRING_AGG(ar.role_name, ', ') as assigned_roles,
    COUNT(DISTINCT ura.role_id) as total_roles,
    COUNT(DISTINCT rp.permission_id) as total_permissions,
    MAX(ar.role_level) as highest_role_level
FROM employees e
LEFT JOIN user_role_assignments ura ON e.id = ura.user_id AND ura.assignment_status = 'active'
LEFT JOIN admin_roles ar ON ura.role_id = ar.role_id
LEFT JOIN role_permissions rp ON ar.role_id = rp.role_id AND rp.granted = true
GROUP BY e.id, e.full_name, e.email
ORDER BY highest_role_level DESC NULLS LAST, e.full_name;

-- System configuration summary
CREATE VIEW v_system_config_summary AS
SELECT 
    sc.config_category,
    COUNT(*) as total_configs,
    COUNT(CASE WHEN sc.is_active THEN 1 END) as active_configs,
    COUNT(CASE WHEN sc.config_scope = 'global' THEN 1 END) as global_configs,
    COUNT(CASE WHEN sc.config_scope = 'tenant' THEN 1 END) as tenant_configs,
    COUNT(CASE WHEN sc.requires_restart THEN 1 END) as restart_required_configs
FROM system_config sc
GROUP BY sc.config_category
ORDER BY sc.config_category;

-- Recent audit activity summary
CREATE VIEW v_recent_audit_activity AS
SELECT 
    al.event_type,
    al.event_category,
    COUNT(*) as event_count,
    COUNT(CASE WHEN al.event_status = 'success' THEN 1 END) as successful_events,
    COUNT(CASE WHEN al.event_status = 'failure' THEN 1 END) as failed_events,
    COUNT(CASE WHEN al.risk_level = 'high' THEN 1 END) as high_risk_events,
    MAX(al.event_timestamp) as latest_event
FROM audit_logs al
WHERE al.event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY al.event_type, al.event_category
ORDER BY event_count DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING (Multi-tenant configs)
-- =============================================================================

-- Insert core system permissions
INSERT INTO system_permissions (permission_id, permission_name, permission_category, permission_module, permission_action, permission_level) VALUES
('sys_admin_full', 'Full System Administration', 'system', 'administration', 'all', 'full'),
('user_management', 'User Management', 'administrative', 'users', 'crud', 'admin'),
('config_management', 'Configuration Management', 'system', 'configuration', 'crud', 'admin'),
('audit_view', 'View Audit Logs', 'administrative', 'audit', 'read', 'read'),
('data_export', 'Data Export', 'data', 'reporting', 'export', 'write');

-- Insert sample admin roles
INSERT INTO admin_roles (role_id, role_name, role_category, permission_scope, system_permissions, can_create_users, can_modify_users, can_view_audit_logs, can_modify_system_config, created_by) VALUES
('system_admin', 'System Administrator', 'system_admin', 'global', 
'{"all": true}', true, true, true, true,
(SELECT id FROM employees LIMIT 1)),
('tenant_admin', 'Tenant Administrator', 'tenant_admin', 'tenant',
'{"tenant_management": true, "user_management": true}', true, true, false, false,
(SELECT id FROM employees LIMIT 1)),
('read_only_admin', 'Read-Only Administrator', 'read_only', 'limited',
'{"read_access": true}', false, false, true, false,
(SELECT id FROM employees LIMIT 1));

-- Insert sample system configurations
INSERT INTO system_config (config_id, config_name, config_category, config_scope, config_type, config_value, default_value, is_user_configurable) VALUES
('session_timeout', 'Session Timeout Minutes', 'security', 'global', 'integer', '480', '480', true),
('max_concurrent_sessions', 'Maximum Concurrent Sessions', 'security', 'global', 'integer', '3', '3', true),
('audit_retention_days', 'Audit Log Retention Days', 'system', 'global', 'integer', '365', '365', false),
('enable_mfa', 'Enable Multi-Factor Authentication', 'security', 'tenant', 'boolean', 'true', 'true', true),
('backup_frequency_hours', 'Backup Frequency Hours', 'system', 'global', 'integer', '24', '24', false);

-- Insert sample audit log entry
INSERT INTO audit_logs (audit_id, event_type, event_category, event_description, user_id, event_status, risk_level) VALUES
('audit_001', 'system_access', 'authentication', 'System administrator login', 
(SELECT id FROM employees LIMIT 1), 'success', 'medium');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE system_config IS 'Global and tenant-specific system configuration with multi-tenant support';
COMMENT ON TABLE admin_roles IS 'Administrative role definitions with hierarchical permissions and security controls';
COMMENT ON TABLE audit_logs IS 'Comprehensive audit logging for compliance and security monitoring';
COMMENT ON TABLE user_role_assignments IS 'User administrative role assignments with approval workflow';
COMMENT ON TABLE tenant_configurations IS 'Tenant-specific configuration overrides and customizations';
COMMENT ON TABLE system_permissions IS 'Granular system permissions for role-based access control';
COMMENT ON TABLE role_permissions IS 'Role to permission mappings with conditional access';
COMMENT ON TABLE user_sessions IS 'User session tracking and management for security';
COMMENT ON TABLE config_change_history IS 'Configuration change tracking for audit and rollback';
COMMENT ON TABLE system_health_metrics IS 'System health monitoring and alerting metrics';