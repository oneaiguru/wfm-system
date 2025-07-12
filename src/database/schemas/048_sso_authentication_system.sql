-- =============================================================================
-- 048_sso_authentication_system.sql
-- EXACT BDD Implementation: SSO Authentication System with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 22-sso-authentication-system.feature (200+ lines)
-- Purpose: Single Sign-On authentication with comprehensive database support
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. SSO PROVIDER CONFIGURATIONS
-- =============================================================================

-- SSO provider configurations from BDD lines 16-22
CREATE TABLE sso_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id VARCHAR(50) NOT NULL UNIQUE,
    provider_name VARCHAR(200) NOT NULL,
    
    -- Provider types from BDD lines 42-47
    provider_type VARCHAR(30) NOT NULL CHECK (provider_type IN (
        'active_directory', 'azure_ad', 'google_workspace', 'saml_2_0', 'oauth_2_0'
    )),
    
    -- Protocol configuration
    protocol VARCHAR(20) NOT NULL CHECK (protocol IN (
        'ldap', 'kerberos', 'oauth_2_0', 'openid_connect', 'saml'
    )),
    
    -- Connection settings from BDD lines 49-54
    connection_settings JSONB NOT NULL DEFAULT '{}', -- URLs, ports, certificates
    authentication_flow JSONB NOT NULL DEFAULT '{}', -- Authorization URLs, token endpoints
    user_attributes_mapping JSONB NOT NULL DEFAULT '{}', -- Attribute mapping
    security_settings JSONB NOT NULL DEFAULT '{}', -- Encryption, signing
    timeout_settings JSONB DEFAULT '{
        "connection_timeout": 30,
        "session_timeout": 3600,
        "token_refresh_timeout": 300
    }',
    
    -- Provider priority and failover from BDD lines 55-60
    priority_order INTEGER DEFAULT 1,
    is_primary BOOLEAN DEFAULT false,
    failover_enabled BOOLEAN DEFAULT true,
    health_check_enabled BOOLEAN DEFAULT true,
    health_check_url VARCHAR(500),
    
    -- Status and configuration
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance', 'failed')),
    config_data JSONB NOT NULL DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_health_check TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 2. SSO USER MAPPINGS
-- =============================================================================

-- SSO user mappings from BDD line 19
CREATE TABLE sso_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sso_user_id VARCHAR(100) NOT NULL UNIQUE,
    provider_id UUID NOT NULL REFERENCES sso_providers(id) ON DELETE CASCADE,
    
    -- External identity
    external_user_id VARCHAR(200) NOT NULL,
    external_username VARCHAR(200),
    external_email VARCHAR(300),
    external_display_name VARCHAR(200),
    
    -- Internal mapping
    internal_user_id UUID NOT NULL,
    
    -- Mapping strategies from BDD lines 66-71
    mapping_strategy VARCHAR(30) CHECK (mapping_strategy IN (
        'automatic', 'manual', 'hybrid', 'just_in_time'
    )),
    
    -- Mapping rules from BDD lines 73-77
    mapping_rule_type VARCHAR(30) CHECK (mapping_rule_type IN (
        'email_matching', 'username_matching', 'employee_id', 'custom_attributes'
    )),
    
    -- User attributes synchronization from BDD lines 78-83
    user_attributes JSONB DEFAULT '{}',
    group_memberships TEXT[],
    role_assignments TEXT[],
    
    -- Sync status
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'active',
    account_status VARCHAR(20) DEFAULT 'active' CHECK (account_status IN (
        'active', 'inactive', 'suspended', 'locked'
    )),
    
    created_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_external_user_per_provider UNIQUE(provider_id, external_user_id)
);

-- =============================================================================
-- 3. SSO SESSION MANAGEMENT
-- =============================================================================

-- Active SSO sessions from BDD line 20
CREATE TABLE sso_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(128) NOT NULL UNIQUE,
    sso_user_id UUID NOT NULL REFERENCES sso_users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES sso_providers(id),
    
    -- Session details
    session_token TEXT NOT NULL,
    refresh_token TEXT,
    
    -- Session controls from BDD lines 89-94
    session_timeout_seconds INTEGER DEFAULT 3600,
    max_concurrent_sessions INTEGER DEFAULT 1,
    
    -- Session security from BDD lines 95-100
    source_ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(256),
    
    -- Session lifecycle
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Security tracking
    token_rotated_at TIMESTAMP WITH TIME ZONE,
    is_encrypted BOOLEAN DEFAULT true,
    
    -- Session status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN (
        'active', 'expired', 'invalidated', 'suspended'
    )),
    
    invalidated_at TIMESTAMP WITH TIME ZONE,
    invalidated_by VARCHAR(100),
    invalidation_reason VARCHAR(200)
);

-- =============================================================================
-- 4. AUTHENTICATION TOKENS
-- =============================================================================

-- Authentication tokens from BDD line 21
CREATE TABLE sso_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_id VARCHAR(128) NOT NULL UNIQUE,
    session_id UUID NOT NULL REFERENCES sso_sessions(id) ON DELETE CASCADE,
    
    -- Token details
    token_type VARCHAR(30) NOT NULL CHECK (token_type IN (
        'access_token', 'refresh_token', 'id_token', 'authorization_code'
    )),
    token_value TEXT NOT NULL,
    
    -- Token metadata
    scope TEXT,
    audience TEXT,
    issuer TEXT,
    
    -- Token lifecycle
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Token security
    is_encrypted BOOLEAN DEFAULT true,
    hash_algorithm VARCHAR(20) DEFAULT 'SHA256',
    token_hash VARCHAR(128),
    
    -- Token status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN (
        'active', 'expired', 'revoked', 'used'
    )),
    
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by VARCHAR(100),
    revocation_reason VARCHAR(200)
);

-- =============================================================================
-- 5. SSO AUDIT LOGGING
-- =============================================================================

-- Authentication audit from BDD line 22
CREATE TABLE sso_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Audit context
    user_id UUID REFERENCES sso_users(id),
    provider_id UUID REFERENCES sso_providers(id),
    session_id UUID REFERENCES sso_sessions(id),
    
    -- Action details
    action VARCHAR(50) NOT NULL CHECK (action IN (
        'login_attempt', 'login_success', 'login_failure', 'logout',
        'token_issued', 'token_refreshed', 'token_revoked',
        'session_created', 'session_expired', 'session_invalidated',
        'user_mapped', 'user_sync', 'provider_failover'
    )),
    
    action_description TEXT,
    action_result VARCHAR(20) CHECK (action_result IN ('success', 'failure', 'partial')),
    
    -- Request context
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(128),
    
    -- Security context
    risk_score INTEGER CHECK (risk_score BETWEEN 0 AND 100),
    anomaly_detected BOOLEAN DEFAULT false,
    geolocation JSONB,
    
    -- Additional data
    audit_data JSONB,
    error_message TEXT,
    
    -- Retention and compliance
    retention_period_days INTEGER DEFAULT 2555, -- 7 years
    is_compliance_required BOOLEAN DEFAULT true
);

-- =============================================================================
-- 6. PROVIDER HEALTH MONITORING
-- =============================================================================

-- Provider health monitoring from BDD lines 55-60
CREATE TABLE sso_provider_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES sso_providers(id),
    
    -- Health check details
    health_check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    health_status VARCHAR(20) CHECK (health_status IN ('healthy', 'degraded', 'unhealthy', 'offline')),
    
    -- Performance metrics
    response_time_ms INTEGER,
    availability_percentage DECIMAL(5,2),
    error_rate_percentage DECIMAL(5,2),
    
    -- Specific checks
    connection_test_passed BOOLEAN,
    authentication_test_passed BOOLEAN,
    token_validation_passed BOOLEAN,
    
    -- Health details
    health_details JSONB,
    error_messages TEXT[],
    
    -- Failover status
    is_primary_available BOOLEAN,
    failover_activated BOOLEAN,
    failover_timestamp TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 7. USER ATTRIBUTE SYNCHRONIZATION
-- =============================================================================

-- User attribute sync from BDD lines 78-83
CREATE TABLE sso_user_attribute_sync (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sso_user_id UUID NOT NULL REFERENCES sso_users(id),
    
    -- Sync configuration
    sync_frequency VARCHAR(20) CHECK (sync_frequency IN ('real_time', 'hourly', 'daily', 'on_demand')),
    sync_direction VARCHAR(20) CHECK (sync_direction IN ('bi_directional', 'provider_to_wfm', 'wfm_to_provider')),
    
    -- Sync elements from BDD lines 79-83
    sync_element VARCHAR(30) CHECK (sync_element IN (
        'user_attributes', 'group_memberships', 'role_assignments', 'account_status'
    )),
    
    -- Conflict resolution
    conflict_resolution_strategy VARCHAR(30) CHECK (conflict_resolution_strategy IN (
        'provider_wins', 'wfm_wins', 'administrator_decision', 'manual_merge'
    )),
    
    -- Sync status
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    next_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    -- Sync results
    attributes_synced JSONB,
    conflicts_detected JSONB DEFAULT '[]',
    errors_encountered JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. SSO CONFIGURATION MANAGEMENT
-- =============================================================================

-- SSO system configuration
CREATE TABLE sso_system_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    config_category VARCHAR(50) NOT NULL,
    config_name VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    
    -- Configuration metadata
    description TEXT,
    is_sensitive BOOLEAN DEFAULT false,
    
    -- Environment and scope
    environment VARCHAR(20) DEFAULT 'production',
    scope VARCHAR(30) DEFAULT 'global' CHECK (scope IN ('global', 'provider_specific', 'user_specific')),
    
    -- Validation
    validation_rules JSONB,
    
    -- Lifecycle
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_config_name UNIQUE(config_category, config_name)
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate session expiry
CREATE OR REPLACE FUNCTION validate_sso_session(p_session_id VARCHAR)
RETURNS TABLE (
    is_valid BOOLEAN,
    session_status VARCHAR,
    time_remaining_seconds INTEGER
) AS $$
DECLARE
    v_session RECORD;
    v_time_remaining INTEGER;
BEGIN
    -- Get session details
    SELECT * INTO v_session
    FROM sso_sessions
    WHERE session_id = p_session_id;
    
    IF v_session.id IS NULL THEN
        RETURN QUERY SELECT false, 'not_found'::VARCHAR, 0;
        RETURN;
    END IF;
    
    -- Calculate time remaining
    v_time_remaining := EXTRACT(EPOCH FROM (v_session.expires_at - CURRENT_TIMESTAMP))::INTEGER;
    
    -- Check session validity
    IF v_session.status != 'active' THEN
        RETURN QUERY SELECT false, v_session.status, 0;
    ELSIF CURRENT_TIMESTAMP > v_session.expires_at THEN
        -- Update session to expired
        UPDATE sso_sessions SET status = 'expired' WHERE id = v_session.id;
        RETURN QUERY SELECT false, 'expired'::VARCHAR, 0;
    ELSE
        -- Update last activity
        UPDATE sso_sessions SET last_activity = CURRENT_TIMESTAMP WHERE id = v_session.id;
        RETURN QUERY SELECT true, v_session.status, v_time_remaining;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to rotate session tokens
CREATE OR REPLACE FUNCTION rotate_session_token(p_session_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    v_new_token VARCHAR(128);
    v_session RECORD;
BEGIN
    -- Generate new token
    v_new_token := encode(gen_random_bytes(64), 'hex');
    
    -- Get current session
    SELECT * INTO v_session FROM sso_sessions WHERE id = p_session_id;
    
    -- Revoke old tokens
    UPDATE sso_tokens 
    SET status = 'revoked', revoked_at = CURRENT_TIMESTAMP, revocation_reason = 'token_rotation'
    WHERE session_id = p_session_id AND status = 'active';
    
    -- Update session with new token
    UPDATE sso_sessions 
    SET session_token = v_new_token, token_rotated_at = CURRENT_TIMESTAMP
    WHERE id = p_session_id;
    
    -- Create new access token
    INSERT INTO sso_tokens (token_id, session_id, token_type, token_value, expires_at)
    VALUES (
        encode(gen_random_bytes(32), 'hex'),
        p_session_id,
        'access_token',
        v_new_token,
        CURRENT_TIMESTAMP + INTERVAL '1 hour'
    );
    
    RETURN v_new_token;
END;
$$ LANGUAGE plpgsql;

-- Function to check provider health
CREATE OR REPLACE FUNCTION check_provider_health(p_provider_id UUID)
RETURNS TABLE (
    health_status VARCHAR,
    response_time_ms INTEGER,
    error_message TEXT
) AS $$
DECLARE
    v_provider RECORD;
    v_health_status VARCHAR := 'healthy';
    v_response_time INTEGER := 0;
    v_error_message TEXT := NULL;
BEGIN
    -- Get provider details
    SELECT * INTO v_provider FROM sso_providers WHERE id = p_provider_id;
    
    IF v_provider.id IS NULL THEN
        RETURN QUERY SELECT 'not_found'::VARCHAR, 0, 'Provider not found';
        RETURN;
    END IF;
    
    -- Simulate health check (in real implementation, this would make actual HTTP calls)
    IF v_provider.status = 'active' THEN
        v_health_status := 'healthy';
        v_response_time := 100; -- Simulated response time
    ELSE
        v_health_status := 'unhealthy';
        v_error_message := 'Provider is not active';
    END IF;
    
    -- Record health check
    INSERT INTO sso_provider_health (
        provider_id, health_status, response_time_ms, 
        connection_test_passed, authentication_test_passed, token_validation_passed
    ) VALUES (
        p_provider_id, v_health_status, v_response_time,
        v_health_status = 'healthy',
        v_health_status = 'healthy',
        v_health_status = 'healthy'
    );
    
    RETURN QUERY SELECT v_health_status, v_response_time, v_error_message;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to enforce concurrent session limits
CREATE OR REPLACE FUNCTION enforce_session_limits()
RETURNS TRIGGER AS $$
DECLARE
    v_active_sessions INTEGER;
    v_max_sessions INTEGER;
    v_oldest_session_id UUID;
BEGIN
    -- Get max concurrent sessions for this user
    SELECT max_concurrent_sessions INTO v_max_sessions
    FROM sso_sessions ss
    WHERE ss.id = NEW.id;
    
    -- Count active sessions for this user
    SELECT COUNT(*) INTO v_active_sessions
    FROM sso_sessions
    WHERE sso_user_id = NEW.sso_user_id
    AND status = 'active'
    AND expires_at > CURRENT_TIMESTAMP;
    
    -- If over limit, invalidate oldest session
    IF v_active_sessions > v_max_sessions THEN
        SELECT id INTO v_oldest_session_id
        FROM sso_sessions
        WHERE sso_user_id = NEW.sso_user_id
        AND status = 'active'
        AND id != NEW.id
        ORDER BY last_activity ASC
        LIMIT 1;
        
        UPDATE sso_sessions
        SET status = 'invalidated',
            invalidated_at = CURRENT_TIMESTAMP,
            invalidated_by = 'system',
            invalidation_reason = 'concurrent_session_limit_exceeded'
        WHERE id = v_oldest_session_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_session_limits_trigger
    AFTER INSERT ON sso_sessions
    FOR EACH ROW
    EXECUTE FUNCTION enforce_session_limits();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Provider indexes
CREATE INDEX idx_sso_providers_type ON sso_providers(provider_type);
CREATE INDEX idx_sso_providers_status ON sso_providers(status);
CREATE INDEX idx_sso_providers_priority ON sso_providers(priority_order);

-- User mapping indexes
CREATE INDEX idx_sso_users_provider ON sso_users(provider_id);
CREATE INDEX idx_sso_users_external_id ON sso_users(external_user_id);
CREATE INDEX idx_sso_users_internal_id ON sso_users(internal_user_id);
CREATE INDEX idx_sso_users_email ON sso_users(external_email);

-- Session indexes
CREATE INDEX idx_sso_sessions_user ON sso_sessions(sso_user_id);
CREATE INDEX idx_sso_sessions_token ON sso_sessions(session_token);
CREATE INDEX idx_sso_sessions_expires ON sso_sessions(expires_at);
CREATE INDEX idx_sso_sessions_status ON sso_sessions(status);
CREATE INDEX idx_sso_sessions_active ON sso_sessions(sso_user_id, status) WHERE status = 'active';

-- Token indexes
CREATE INDEX idx_sso_tokens_session ON sso_tokens(session_id);
CREATE INDEX idx_sso_tokens_type ON sso_tokens(token_type);
CREATE INDEX idx_sso_tokens_expires ON sso_tokens(expires_at);
CREATE INDEX idx_sso_tokens_status ON sso_tokens(status);

-- Audit indexes
CREATE INDEX idx_sso_audit_user ON sso_audit_log(user_id);
CREATE INDEX idx_sso_audit_timestamp ON sso_audit_log(timestamp DESC);
CREATE INDEX idx_sso_audit_action ON sso_audit_log(action);
CREATE INDEX idx_sso_audit_ip ON sso_audit_log(ip_address);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert default SSO providers
INSERT INTO sso_providers (provider_id, provider_name, provider_type, protocol, status) VALUES
('azure-ad-primary', 'Azure Active Directory', 'azure_ad', 'oauth_2_0', 'active'),
('google-workspace', 'Google Workspace', 'google_workspace', 'oauth_2_0', 'active'),
('on-premises-ad', 'On-Premises Active Directory', 'active_directory', 'ldap', 'active');

-- Update provider priorities
UPDATE sso_providers SET priority_order = 1, is_primary = true WHERE provider_id = 'azure-ad-primary';
UPDATE sso_providers SET priority_order = 2 WHERE provider_id = 'google-workspace';
UPDATE sso_providers SET priority_order = 3 WHERE provider_id = 'on-premises-ad';

-- Insert default configuration
INSERT INTO sso_system_configuration (config_category, config_name, config_value, description) VALUES
('session', 'default_timeout_seconds', '3600', 'Default session timeout in seconds'),
('session', 'max_concurrent_sessions', '3', 'Maximum concurrent sessions per user'),
('security', 'token_rotation_enabled', 'true', 'Enable automatic token rotation'),
('security', 'require_device_validation', 'false', 'Require device fingerprint validation'),
('sync', 'user_attribute_sync_frequency', '"hourly"', 'Default user attribute sync frequency');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_sso_admin;
-- GRANT SELECT ON sso_audit_log, sso_sessions, sso_users TO wfm_security_analyst;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_sso_admin;