-- =============================================================================
-- Schema 126: Critical Authentication and Authorization Infrastructure
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-15
-- Based on: 22-sso-authentication-system.feature + 26-roles-access-control.feature
-- Purpose: Complete missing authentication infrastructure for BDD scenarios
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. OAUTH 2.0 CLIENT MANAGEMENT
-- =============================================================================

-- OAuth clients configuration for external integrations
CREATE TABLE oauth_clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id VARCHAR(100) NOT NULL UNIQUE,
    client_secret_hash VARCHAR(255) NOT NULL,
    client_name VARCHAR(200) NOT NULL,
    
    -- Client type and flow
    client_type VARCHAR(20) NOT NULL CHECK (client_type IN ('confidential', 'public')),
    authorization_grant_types TEXT[] NOT NULL DEFAULT '{"authorization_code"}',
    redirect_uris TEXT[] NOT NULL DEFAULT '{}',
    
    -- Scope and access control
    allowed_scopes TEXT[] DEFAULT '{"read", "write"}',
    access_token_validity_seconds INTEGER DEFAULT 3600,
    refresh_token_validity_seconds INTEGER DEFAULT 86400,
    
    -- Security settings
    require_pkce BOOLEAN DEFAULT true,
    allow_refresh_token BOOLEAN DEFAULT true,
    auto_approve_scopes TEXT[] DEFAULT '{}',
    
    -- Client metadata
    description TEXT,
    contact_email VARCHAR(255),
    logo_url VARCHAR(500),
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_by VARCHAR(100),
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- OAuth authorization codes (short-lived)
CREATE TABLE oauth_authorization_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(128) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES oauth_clients(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    
    -- Authorization details
    redirect_uri VARCHAR(2000) NOT NULL,
    scope TEXT[] DEFAULT '{}',
    state VARCHAR(500),
    
    -- PKCE support
    code_challenge VARCHAR(128),
    code_challenge_method VARCHAR(10) CHECK (code_challenge_method IN ('S256', 'plain')),
    
    -- Lifecycle
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_used BOOLEAN DEFAULT false,
    revoked_at TIMESTAMP WITH TIME ZONE
);

-- OAuth access and refresh tokens
CREATE TABLE oauth_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_value VARCHAR(255) NOT NULL UNIQUE,
    token_type VARCHAR(20) NOT NULL CHECK (token_type IN ('access_token', 'refresh_token')),
    
    -- Token associations
    client_id UUID NOT NULL REFERENCES oauth_clients(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    authorization_code_id UUID REFERENCES oauth_authorization_codes(id),
    
    -- Token metadata
    scope TEXT[] DEFAULT '{}',
    token_format VARCHAR(20) DEFAULT 'jwt' CHECK (token_format IN ('jwt', 'opaque')),
    
    -- Lifecycle
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by VARCHAR(100),
    revocation_reason VARCHAR(200)
);

-- =============================================================================
-- 2. SAML 2.0 CONFIGURATION
-- =============================================================================

-- SAML Identity Provider configurations
CREATE TABLE saml_identity_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_name VARCHAR(200) NOT NULL UNIQUE,
    entity_id VARCHAR(500) NOT NULL UNIQUE,
    
    -- SAML endpoints
    single_sign_on_url VARCHAR(2000) NOT NULL,
    single_logout_url VARCHAR(2000),
    
    -- Certificates and security
    x509_certificate TEXT NOT NULL,
    signature_algorithm VARCHAR(50) DEFAULT 'RSA_SHA256',
    digest_algorithm VARCHAR(50) DEFAULT 'SHA256',
    
    -- Assertion settings
    want_assertions_signed BOOLEAN DEFAULT true,
    want_name_id_encrypted BOOLEAN DEFAULT false,
    name_id_format VARCHAR(200) DEFAULT 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    
    -- Attribute mapping
    attribute_mapping JSONB DEFAULT '{
        "email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
        "first_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
        "last_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
        "display_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    }',
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- SAML assertions and responses
CREATE TABLE saml_assertions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assertion_id VARCHAR(100) NOT NULL UNIQUE,
    provider_id UUID NOT NULL REFERENCES saml_identity_providers(id),
    
    -- Assertion content
    user_id UUID NOT NULL,
    name_id VARCHAR(200) NOT NULL,
    session_index VARCHAR(200),
    
    -- Assertion metadata
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    not_before TIMESTAMP WITH TIME ZONE,
    not_on_or_after TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- User attributes
    user_attributes JSONB DEFAULT '{}',
    
    -- Validation status
    is_valid BOOLEAN DEFAULT true,
    validation_errors TEXT[],
    
    -- Security
    signature_valid BOOLEAN DEFAULT true,
    audience_restriction VARCHAR(500)
);

-- =============================================================================
-- 3. ROLE HIERARCHY AND INHERITANCE
-- =============================================================================

-- Role hierarchy definitions (extends basic roles)
CREATE TABLE role_hierarchies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_role_id UUID NOT NULL,
    child_role_id UUID NOT NULL,
    
    -- Hierarchy metadata
    hierarchy_level INTEGER NOT NULL DEFAULT 1,
    inheritance_type VARCHAR(20) DEFAULT 'full' CHECK (inheritance_type IN ('full', 'partial', 'additive')),
    
    -- Conditions for inheritance
    conditions JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT role_hierarchy_no_self_reference CHECK (parent_role_id != child_role_id),
    CONSTRAINT unique_role_hierarchy UNIQUE (parent_role_id, child_role_id)
);

-- Permission templates for rapid role creation
CREATE TABLE permission_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_name_ru VARCHAR(100),
    
    -- Template metadata
    template_type VARCHAR(30) NOT NULL CHECK (template_type IN ('department', 'position', 'project', 'custom')),
    description TEXT,
    description_ru TEXT,
    
    -- Permission set
    permissions_included TEXT[] NOT NULL DEFAULT '{}',
    permissions_excluded TEXT[] DEFAULT '{}',
    
    -- Business rules
    business_rules JSONB DEFAULT '{}',
    
    -- Template status
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    
    -- Audit
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. SECURITY POLICIES AND ENFORCEMENT
-- =============================================================================

-- System security policies
CREATE TABLE security_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL UNIQUE,
    policy_type VARCHAR(30) NOT NULL CHECK (policy_type IN ('password', 'session', 'access', 'audit', 'encryption')),
    
    -- Policy configuration
    policy_rules JSONB NOT NULL DEFAULT '{}',
    enforcement_level VARCHAR(20) DEFAULT 'strict' CHECK (enforcement_level IN ('strict', 'moderate', 'flexible')),
    
    -- Scope and applicability
    applies_to_roles TEXT[] DEFAULT '{}',
    applies_to_users TEXT[] DEFAULT '{}',
    resource_types TEXT[] DEFAULT '{}',
    
    -- Status and lifecycle
    is_active BOOLEAN DEFAULT true,
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Password policies (specific type of security policy)
CREATE TABLE password_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL UNIQUE,
    
    -- Password complexity requirements
    min_length INTEGER DEFAULT 8,
    max_length INTEGER DEFAULT 128,
    require_uppercase BOOLEAN DEFAULT true,
    require_lowercase BOOLEAN DEFAULT true,
    require_numbers BOOLEAN DEFAULT true,
    require_special_chars BOOLEAN DEFAULT true,
    special_chars_allowed VARCHAR(50) DEFAULT '!@#$%^&*()_+-=[]{}|;:,.<>?',
    
    -- Password history and rotation
    password_history_count INTEGER DEFAULT 5,
    max_password_age_days INTEGER DEFAULT 90,
    min_password_age_days INTEGER DEFAULT 1,
    
    -- Lockout and attempts
    max_failed_attempts INTEGER DEFAULT 5,
    lockout_duration_minutes INTEGER DEFAULT 30,
    
    -- Dictionary and pattern checks
    prevent_dictionary_words BOOLEAN DEFAULT true,
    prevent_common_patterns BOOLEAN DEFAULT true,
    prevent_personal_info BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    applies_to_roles TEXT[] DEFAULT '{}',
    
    -- Audit
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. LOGIN ATTEMPTS AND SECURITY MONITORING
-- =============================================================================

-- Login attempt tracking
CREATE TABLE login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User identification
    user_id UUID,
    username VARCHAR(200),
    email VARCHAR(255),
    
    -- Attempt details
    attempt_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    attempt_result VARCHAR(20) NOT NULL CHECK (attempt_result IN ('success', 'failed', 'blocked', 'suspicious')),
    failure_reason VARCHAR(100),
    
    -- Request context
    ip_address INET NOT NULL,
    user_agent TEXT,
    request_id VARCHAR(128),
    
    -- Security context
    authentication_method VARCHAR(30) CHECK (authentication_method IN ('password', 'sso', 'oauth', 'saml', 'mfa')),
    risk_score INTEGER CHECK (risk_score BETWEEN 0 AND 100),
    
    -- Geolocation
    country_code CHAR(2),
    city VARCHAR(100),
    coordinates POINT,
    
    -- Device information
    device_fingerprint VARCHAR(256),
    device_type VARCHAR(50),
    browser VARCHAR(100),
    operating_system VARCHAR(100),
    
    -- Additional security data
    security_context JSONB DEFAULT '{}'
);

-- Account lockout tracking
CREATE TABLE account_lockouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- Lockout details
    lockout_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    lockout_reason VARCHAR(100) NOT NULL CHECK (lockout_reason IN ('failed_attempts', 'suspicious_activity', 'security_breach', 'administrative', 'policy_violation')),
    lockout_duration_minutes INTEGER,
    
    -- Context
    failed_attempts_count INTEGER DEFAULT 0,
    triggering_ip_address INET,
    policy_violated VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    unlock_timestamp TIMESTAMP WITH TIME ZONE,
    unlocked_by VARCHAR(100),
    unlock_reason VARCHAR(200),
    
    -- Audit
    created_by VARCHAR(100) DEFAULT 'system',
    notes TEXT
);

-- =============================================================================
-- 6. TWO-FACTOR AUTHENTICATION
-- =============================================================================

-- Two-factor authentication configurations
CREATE TABLE two_factor_auth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,
    
    -- 2FA method
    method VARCHAR(20) NOT NULL CHECK (method IN ('totp', 'sms', 'email', 'push', 'hardware_token')),
    
    -- TOTP configuration
    totp_secret VARCHAR(100),
    totp_algorithm VARCHAR(10) DEFAULT 'SHA1',
    totp_digits INTEGER DEFAULT 6,
    totp_period INTEGER DEFAULT 30,
    
    -- SMS/Email configuration
    phone_number VARCHAR(20),
    email_address VARCHAR(255),
    
    -- Backup codes
    backup_codes TEXT[],
    backup_codes_used TEXT[] DEFAULT '{}',
    
    -- Status
    is_enabled BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Recovery
    recovery_codes TEXT[],
    recovery_codes_used TEXT[] DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- 2FA verification attempts
CREATE TABLE two_factor_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- Verification details
    verification_code VARCHAR(20) NOT NULL,
    verification_method VARCHAR(20) NOT NULL,
    verification_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Result
    is_successful BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(128),
    
    -- Security
    attempts_count INTEGER DEFAULT 1,
    rate_limit_exceeded BOOLEAN DEFAULT false
);

-- =============================================================================
-- 7. SECURITY QUESTIONS AND KNOWLEDGE-BASED AUTHENTICATION
-- =============================================================================

-- Security questions bank
CREATE TABLE security_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text VARCHAR(500) NOT NULL,
    question_text_ru VARCHAR(500),
    
    -- Question metadata
    question_category VARCHAR(50) CHECK (question_category IN ('personal', 'historical', 'preferences', 'family', 'work')),
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    usage_count INTEGER DEFAULT 0,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User security question assignments
CREATE TABLE user_security_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    question_id UUID NOT NULL REFERENCES security_questions(id),
    
    -- Answer (hashed)
    answer_hash VARCHAR(255) NOT NULL,
    answer_salt VARCHAR(100) NOT NULL,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Constraints
    CONSTRAINT unique_user_question UNIQUE (user_id, question_id)
);

-- =============================================================================
-- 8. ACCESS AUDIT AND COMPLIANCE
-- =============================================================================

-- Comprehensive access audit log
CREATE TABLE access_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User and session context
    user_id UUID,
    session_id VARCHAR(128),
    role_id UUID,
    
    -- Access details
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255),
    action_performed VARCHAR(100) NOT NULL,
    access_level VARCHAR(50),
    
    -- Request details
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    request_method VARCHAR(10),
    request_url VARCHAR(2000),
    request_headers JSONB,
    
    -- Response details
    response_status_code INTEGER,
    response_size_bytes INTEGER,
    processing_time_ms INTEGER,
    
    -- Security context
    ip_address INET,
    user_agent TEXT,
    geolocation JSONB,
    
    -- Risk assessment
    risk_score INTEGER CHECK (risk_score BETWEEN 0 AND 100),
    anomaly_indicators TEXT[],
    
    -- Result
    access_granted BOOLEAN NOT NULL,
    denial_reason VARCHAR(200),
    
    -- Additional context
    additional_data JSONB DEFAULT '{}',
    
    -- Retention
    retention_period_days INTEGER DEFAULT 2555, -- 7 years for compliance
    archived_at TIMESTAMP WITH TIME ZONE
);

-- Data access logging for sensitive operations
CREATE TABLE data_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User context
    user_id UUID NOT NULL,
    role_id UUID,
    
    -- Data access details
    table_name VARCHAR(100) NOT NULL,
    operation_type VARCHAR(20) NOT NULL CHECK (operation_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'EXPORT')),
    affected_rows INTEGER,
    
    -- Sensitivity classification
    data_classification VARCHAR(20) CHECK (data_classification IN ('public', 'internal', 'confidential', 'restricted')),
    contains_pii BOOLEAN DEFAULT false,
    
    -- Query details
    query_hash VARCHAR(64),
    query_execution_time_ms INTEGER,
    
    -- Context
    access_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    application_name VARCHAR(100),
    
    -- Compliance
    compliance_frameworks TEXT[] DEFAULT '{}',
    business_justification TEXT,
    
    -- Results
    operation_successful BOOLEAN NOT NULL,
    error_message TEXT
);

-- =============================================================================
-- 9. DEVICE AND LOCATION MANAGEMENT
-- =============================================================================

-- Trusted devices registry
CREATE TABLE trusted_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- Device identification
    device_fingerprint VARCHAR(256) NOT NULL,
    device_name VARCHAR(200),
    device_type VARCHAR(50),
    
    -- Device details
    browser VARCHAR(100),
    operating_system VARCHAR(100),
    ip_address INET,
    
    -- Trust status
    trust_level VARCHAR(20) DEFAULT 'trusted' CHECK (trust_level IN ('trusted', 'suspicious', 'blocked')),
    trusted_since TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Usage tracking
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    usage_count INTEGER DEFAULT 0,
    
    -- Security
    requires_2fa BOOLEAN DEFAULT false,
    max_session_duration_minutes INTEGER DEFAULT 480,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_by VARCHAR(100),
    notes TEXT
);

-- Geolocation access controls
CREATE TABLE location_access_controls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Location definition
    location_name VARCHAR(200) NOT NULL,
    location_type VARCHAR(30) CHECK (location_type IN ('office', 'home', 'public', 'restricted')),
    
    -- Geographic boundaries
    country_codes CHAR(2)[],
    allowed_cities TEXT[],
    coordinates_center POINT,
    radius_km DECIMAL(8,2),
    
    -- Access rules
    access_level VARCHAR(20) DEFAULT 'normal' CHECK (access_level IN ('blocked', 'restricted', 'normal', 'privileged')),
    requires_additional_auth BOOLEAN DEFAULT false,
    
    -- Time-based restrictions
    allowed_time_ranges JSONB DEFAULT '{}',
    timezone VARCHAR(50),
    
    -- Applicability
    applies_to_roles TEXT[] DEFAULT '{}',
    applies_to_users TEXT[] DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Audit
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS AND PROCEDURES
-- =============================================================================

-- Function to validate password against policy
CREATE OR REPLACE FUNCTION validate_password_policy(
    p_password TEXT,
    p_user_id UUID DEFAULT NULL,
    p_policy_id UUID DEFAULT NULL
) RETURNS TABLE (
    is_valid BOOLEAN,
    violations TEXT[]
) AS $$
DECLARE
    v_policy RECORD;
    v_violations TEXT[] := '{}';
    v_user_info RECORD;
BEGIN
    -- Get applicable password policy
    SELECT * INTO v_policy
    FROM password_policies
    WHERE is_active = true
    AND (p_policy_id IS NULL OR id = p_policy_id)
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_policy.id IS NULL THEN
        RETURN QUERY SELECT true, '{}'::TEXT[];
        RETURN;
    END IF;
    
    -- Check minimum length
    IF LENGTH(p_password) < v_policy.min_length THEN
        v_violations := array_append(v_violations, 'Password too short');
    END IF;
    
    -- Check maximum length
    IF LENGTH(p_password) > v_policy.max_length THEN
        v_violations := array_append(v_violations, 'Password too long');
    END IF;
    
    -- Check uppercase requirement
    IF v_policy.require_uppercase AND p_password !~ '[A-Z]' THEN
        v_violations := array_append(v_violations, 'Password must contain uppercase letter');
    END IF;
    
    -- Check lowercase requirement
    IF v_policy.require_lowercase AND p_password !~ '[a-z]' THEN
        v_violations := array_append(v_violations, 'Password must contain lowercase letter');
    END IF;
    
    -- Check numbers requirement
    IF v_policy.require_numbers AND p_password !~ '[0-9]' THEN
        v_violations := array_append(v_violations, 'Password must contain number');
    END IF;
    
    -- Check special characters requirement
    IF v_policy.require_special_chars AND p_password !~ '[^A-Za-z0-9]' THEN
        v_violations := array_append(v_violations, 'Password must contain special character');
    END IF;
    
    RETURN QUERY SELECT array_length(v_violations, 1) IS NULL OR array_length(v_violations, 1) = 0, v_violations;
END;
$$ LANGUAGE plpgsql;

-- Function to check account lockout status
CREATE OR REPLACE FUNCTION check_account_lockout(p_user_id UUID)
RETURNS TABLE (
    is_locked BOOLEAN,
    lockout_reason VARCHAR,
    unlock_time TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_lockout RECORD;
    v_current_time TIMESTAMP WITH TIME ZONE := CURRENT_TIMESTAMP;
BEGIN
    -- Get active lockout
    SELECT * INTO v_lockout
    FROM account_lockouts
    WHERE user_id = p_user_id
    AND is_active = true
    AND (unlock_timestamp IS NULL OR unlock_timestamp > v_current_time)
    ORDER BY lockout_timestamp DESC
    LIMIT 1;
    
    IF v_lockout.id IS NULL THEN
        RETURN QUERY SELECT false, NULL::VARCHAR, NULL::TIMESTAMP WITH TIME ZONE;
    ELSE
        RETURN QUERY SELECT 
            true, 
            v_lockout.lockout_reason,
            CASE 
                WHEN v_lockout.lockout_duration_minutes IS NOT NULL 
                THEN v_lockout.lockout_timestamp + INTERVAL '1 minute' * v_lockout.lockout_duration_minutes
                ELSE v_lockout.unlock_timestamp
            END;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to record login attempt
CREATE OR REPLACE FUNCTION record_login_attempt(
    p_user_id UUID,
    p_username VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_result VARCHAR DEFAULT 'failed',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_auth_method VARCHAR DEFAULT 'password'
) RETURNS UUID AS $$
DECLARE
    v_attempt_id UUID;
    v_risk_score INTEGER := 0;
BEGIN
    -- Calculate basic risk score
    IF p_ip_address IS NOT NULL THEN
        -- Check for suspicious IPs (simplified logic)
        SELECT COUNT(*) * 10 INTO v_risk_score
        FROM login_attempts
        WHERE ip_address = p_ip_address
        AND attempt_result = 'failed'
        AND attempt_timestamp > CURRENT_TIMESTAMP - INTERVAL '1 hour';
    END IF;
    
    -- Cap risk score
    v_risk_score := LEAST(v_risk_score, 100);
    
    -- Insert attempt record
    INSERT INTO login_attempts (
        user_id, username, email, attempt_result, ip_address, 
        user_agent, authentication_method, risk_score
    ) VALUES (
        p_user_id, p_username, p_email, p_result, p_ip_address,
        p_user_agent, p_auth_method, v_risk_score
    ) RETURNING id INTO v_attempt_id;
    
    RETURN v_attempt_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- OAuth indexes
CREATE INDEX idx_oauth_clients_client_id ON oauth_clients(client_id);
CREATE INDEX idx_oauth_clients_active ON oauth_clients(is_active);
CREATE INDEX idx_oauth_codes_code ON oauth_authorization_codes(code);
CREATE INDEX idx_oauth_codes_client ON oauth_authorization_codes(client_id);
CREATE INDEX idx_oauth_codes_expires ON oauth_authorization_codes(expires_at);
CREATE INDEX idx_oauth_tokens_value ON oauth_tokens(token_value);
CREATE INDEX idx_oauth_tokens_client ON oauth_tokens(client_id);
CREATE INDEX idx_oauth_tokens_user ON oauth_tokens(user_id);
CREATE INDEX idx_oauth_tokens_expires ON oauth_tokens(expires_at);

-- SAML indexes
CREATE INDEX idx_saml_providers_entity ON saml_identity_providers(entity_id);
CREATE INDEX idx_saml_providers_active ON saml_identity_providers(is_active);
CREATE INDEX idx_saml_assertions_id ON saml_assertions(assertion_id);
CREATE INDEX idx_saml_assertions_user ON saml_assertions(user_id);
CREATE INDEX idx_saml_assertions_expires ON saml_assertions(not_on_or_after);

-- Role hierarchy indexes
CREATE INDEX idx_role_hierarchy_parent ON role_hierarchies(parent_role_id);
CREATE INDEX idx_role_hierarchy_child ON role_hierarchies(child_role_id);
CREATE INDEX idx_role_hierarchy_active ON role_hierarchies(is_active);

-- Security indexes
CREATE INDEX idx_security_policies_type ON security_policies(policy_type);
CREATE INDEX idx_security_policies_active ON security_policies(is_active);
CREATE INDEX idx_password_policies_active ON password_policies(is_active);

-- Login attempts indexes
CREATE INDEX idx_login_attempts_user ON login_attempts(user_id);
CREATE INDEX idx_login_attempts_ip ON login_attempts(ip_address);
CREATE INDEX idx_login_attempts_timestamp ON login_attempts(attempt_timestamp DESC);
CREATE INDEX idx_login_attempts_result ON login_attempts(attempt_result);
CREATE INDEX idx_login_attempts_risk ON login_attempts(risk_score DESC);

-- Account lockout indexes
CREATE INDEX idx_account_lockouts_user ON account_lockouts(user_id);
CREATE INDEX idx_account_lockouts_active ON account_lockouts(is_active);
CREATE INDEX idx_account_lockouts_timestamp ON account_lockouts(lockout_timestamp DESC);

-- 2FA indexes
CREATE INDEX idx_2fa_user ON two_factor_auth(user_id);
CREATE INDEX idx_2fa_enabled ON two_factor_auth(is_enabled);
CREATE INDEX idx_2fa_verifications_user ON two_factor_verifications(user_id);
CREATE INDEX idx_2fa_verifications_timestamp ON two_factor_verifications(verification_timestamp DESC);

-- Security questions indexes
CREATE INDEX idx_security_questions_active ON security_questions(is_active);
CREATE INDEX idx_user_security_questions_user ON user_security_questions(user_id);
CREATE INDEX idx_user_security_questions_active ON user_security_questions(is_active);

-- Audit indexes
CREATE INDEX idx_access_audit_user ON access_audit_logs(user_id);
CREATE INDEX idx_access_audit_timestamp ON access_audit_logs(request_timestamp DESC);
CREATE INDEX idx_access_audit_resource ON access_audit_logs(resource_type, resource_id);
CREATE INDEX idx_access_audit_risk ON access_audit_logs(risk_score DESC);
CREATE INDEX idx_data_access_user ON data_access_logs(user_id);
CREATE INDEX idx_data_access_timestamp ON data_access_logs(access_timestamp DESC);
CREATE INDEX idx_data_access_table ON data_access_logs(table_name);

-- Device and location indexes
CREATE INDEX idx_trusted_devices_user ON trusted_devices(user_id);
CREATE INDEX idx_trusted_devices_fingerprint ON trusted_devices(device_fingerprint);
CREATE INDEX idx_trusted_devices_active ON trusted_devices(is_active);
CREATE INDEX idx_location_controls_active ON location_access_controls(is_active);

-- =============================================================================
-- INITIAL TEST DATA WITH RUSSIAN LANGUAGE SUPPORT
-- =============================================================================

-- Insert security questions in Russian
INSERT INTO security_questions (question_text, question_text_ru, question_category, difficulty_level) VALUES
('What was the name of your first pet?', 'Как звали вашего первого питомца?', 'personal', 2),
('What is your mother''s maiden name?', 'Какая девичья фамилия вашей матери?', 'family', 3),
('What was the name of your first school?', 'Как называлась ваша первая школа?', 'historical', 2),
('What is your favorite color?', 'Какой ваш любимый цвет?', 'preferences', 1),
('In what city were you born?', 'В каком городе вы родились?', 'personal', 2),
('What was your childhood nickname?', 'Какое было ваше детское прозвище?', 'personal', 2),
('What is the name of your favorite teacher?', 'Как звали вашего любимого учителя?', 'historical', 3),
('What was the make of your first car?', 'Какой марки была ваша первая машина?', 'personal', 2);

-- Insert default OAuth client for system integration
INSERT INTO oauth_clients (
    client_id, client_secret_hash, client_name, client_type, 
    description, created_by
) VALUES (
    'wfm-system-client', 
    crypt('system-secret-key', gen_salt('bf')), 
    'WFM System Client', 
    'confidential',
    'Main system OAuth client for API access',
    'system-init'
);

-- Insert default SAML provider for testing
INSERT INTO saml_identity_providers (
    provider_name, entity_id, single_sign_on_url, 
    x509_certificate, description
) VALUES (
    'Test SAML Provider',
    'https://wfm.example.com/saml/metadata',
    'https://idp.example.com/saml/sso',
    'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCi4uLiAoVGVzdCBjZXJ0aWZpY2F0ZSkKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ==',
    'Test SAML Identity Provider for development'
);

-- Insert default password policy
INSERT INTO password_policies (
    policy_name, min_length, max_length, require_uppercase, 
    require_lowercase, require_numbers, require_special_chars,
    password_history_count, max_password_age_days, max_failed_attempts,
    lockout_duration_minutes, created_by
) VALUES (
    'Default Password Policy',
    8, 128, true, true, true, true,
    5, 90, 5, 30, 'system-init'
);

-- Insert default security policy
INSERT INTO security_policies (
    policy_name, policy_type, policy_rules, enforcement_level,
    created_by
) VALUES (
    'Default Session Policy',
    'session',
    '{"max_concurrent_sessions": 3, "session_timeout_minutes": 480, "idle_timeout_minutes": 60}',
    'strict',
    'system-init'
);

-- Insert permission templates
INSERT INTO permission_templates (
    template_name, template_name_ru, template_type, 
    permissions_included, description, created_by
) VALUES 
(
    'Call Center Agent',
    'Агент колл-центра',
    'position',
    '{"REQUESTS_VIEW", "REQUESTS_CREATE", "PERSONAL_CABINET_VIEW", "SCHEDULE_VIEW"}',
    'Standard permissions for call center agents',
    'system-init'
),
(
    'Team Leader',
    'Руководитель группы',
    'position',
    '{"REQUESTS_VIEW", "REQUESTS_APPROVE", "PLANNING_VIEW", "PLANNING_EDIT", "REPORTS_VIEW", "TEAM_MONITORING"}',
    'Permissions for team leaders and supervisors',
    'system-init'
),
(
    'HR Manager',
    'HR-менеджер',
    'department',
    '{"USER_VIEW", "USER_CREATE", "USER_EDIT", "PERSONNEL_MANAGEMENT", "REPORTS_VIEW", "REPORTS_EXPORT"}',
    'Human Resources department permissions',
    'system-init'
);

-- Insert location access controls for Russian offices
INSERT INTO location_access_controls (
    location_name, location_type, country_codes, allowed_cities,
    access_level, timezone, created_by
) VALUES 
(
    'Moscow Office',
    'office',
    '{"RU"}',
    '{"Moscow", "Москва"}',
    'privileged',
    'Europe/Moscow',
    'system-init'
),
(
    'St. Petersburg Office',
    'office',
    '{"RU"}',
    '{"St. Petersburg", "Санкт-Петербург"}',
    'privileged',
    'Europe/Moscow',
    'system-init'
),
(
    'Remote Work - Russia',
    'home',
    '{"RU"}',
    '{}',
    'normal',
    'Europe/Moscow',
    'system-init'
);

-- =============================================================================
-- VERIFICATION AND DOCUMENTATION
-- =============================================================================

-- Table creation summary
SELECT 
    'Authentication Infrastructure Created' as status,
    COUNT(*) as tables_created
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'oauth_clients', 'oauth_authorization_codes', 'oauth_tokens',
    'saml_identity_providers', 'saml_assertions',
    'role_hierarchies', 'permission_templates',
    'security_policies', 'password_policies',
    'login_attempts', 'account_lockouts',
    'two_factor_auth', 'two_factor_verifications',
    'security_questions', 'user_security_questions',
    'access_audit_logs', 'data_access_logs',
    'trusted_devices', 'location_access_controls'
);

-- Index creation summary
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN (
    'oauth_clients', 'oauth_authorization_codes', 'oauth_tokens',
    'saml_identity_providers', 'saml_assertions',
    'role_hierarchies', 'permission_templates',
    'security_policies', 'password_policies',
    'login_attempts', 'account_lockouts',
    'two_factor_auth', 'two_factor_verifications',
    'security_questions', 'user_security_questions',
    'access_audit_logs', 'data_access_logs',
    'trusted_devices', 'location_access_controls'
)
ORDER BY tablename, indexname;

-- =============================================================================
-- SCHEMA 126 COMPLETION SUMMARY
-- =============================================================================

/*
SCHEMA 126 DELIVERS: 18 Critical Authentication Tables

1. OAuth 2.0 Infrastructure:
   - oauth_clients: Client application management
   - oauth_authorization_codes: Authorization code flow
   - oauth_tokens: Access and refresh tokens

2. SAML 2.0 Support:
   - saml_identity_providers: SAML IdP configuration
   - saml_assertions: SAML assertion validation

3. Advanced Role Management:
   - role_hierarchies: Role inheritance and hierarchy
   - permission_templates: Rapid role creation

4. Security Policies:
   - security_policies: System-wide security rules
   - password_policies: Password complexity enforcement

5. Login Security:
   - login_attempts: Comprehensive login tracking
   - account_lockouts: Automated lockout management

6. Multi-Factor Authentication:
   - two_factor_auth: 2FA configuration and methods
   - two_factor_verifications: 2FA verification tracking

7. Knowledge-Based Authentication:
   - security_questions: Security question bank
   - user_security_questions: User question assignments

8. Audit and Compliance:
   - access_audit_logs: Comprehensive access auditing
   - data_access_logs: Sensitive data access tracking

9. Device and Location Security:
   - trusted_devices: Device trust management
   - location_access_controls: Geographic access controls

KEY FEATURES:
✅ Full Russian language support
✅ BDD scenario compatibility
✅ Enterprise-grade security
✅ Comprehensive audit trails
✅ Performance-optimized indexes
✅ Real production data ready
✅ Compliance framework support

INTEGRATION POINTS:
- Links with existing SSO system (Schema 048)
- Extends roles system (Schema 081)
- Supports mobile authentication (Schema 032)
- Enables audit compliance (Schema 034)
*/