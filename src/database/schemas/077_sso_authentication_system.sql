-- Schema 077: SSO Authentication System (BDD 22)
-- Enterprise Single Sign-On with multi-provider support
-- Russian enterprise integration ready (AD, 1C, etc.)

-- 1. SSO Provider Configurations
CREATE TABLE sso_providers (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_name VARCHAR(255) NOT NULL UNIQUE,
    provider_type VARCHAR(50) NOT NULL, -- active_directory, azure_ad, google, saml2, oauth2
    provider_status VARCHAR(50) DEFAULT 'active',
    base_url VARCHAR(500),
    authorization_url VARCHAR(500),
    token_url VARCHAR(500),
    userinfo_url VARCHAR(500),
    client_id VARCHAR(255),
    client_secret_encrypted TEXT, -- Encrypted storage
    scope VARCHAR(500),
    redirect_uri VARCHAR(500),
    config_data JSONB, -- Provider-specific configuration
    priority_order INTEGER DEFAULT 100,
    health_check_url VARCHAR(500),
    last_health_check TIMESTAMP,
    health_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. SSO User Mappings
CREATE TABLE sso_users (
    sso_user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES sso_providers(provider_id),
    external_user_id VARCHAR(255) NOT NULL, -- ID from SSO provider
    internal_user_id UUID NOT NULL, -- References employees table
    email VARCHAR(255),
    username VARCHAR(255),
    display_name VARCHAR(255),
    display_name_ru VARCHAR(255), -- Russian name from provider
    employee_number VARCHAR(100), -- For 1C integration
    mapping_type VARCHAR(50), -- automatic, manual, hybrid, jit
    mapping_status VARCHAR(50) DEFAULT 'active',
    last_login TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    attributes JSONB, -- Additional provider attributes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider_id, external_user_id)
);

-- 3. SSO Sessions Management
CREATE TABLE sso_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sso_user_id UUID REFERENCES sso_users(sso_user_id),
    provider_id UUID REFERENCES sso_providers(provider_id),
    session_token TEXT NOT NULL UNIQUE,
    refresh_token TEXT,
    ip_address INET,
    user_agent TEXT,
    device_info JSONB,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    termination_reason VARCHAR(100),
    location_id UUID, -- References locations table for multi-site
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Authentication Tokens
CREATE TABLE sso_tokens (
    token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sso_sessions(session_id),
    token_type VARCHAR(50) NOT NULL, -- access, refresh, id_token
    token_value TEXT NOT NULL,
    token_hash VARCHAR(255) UNIQUE, -- For quick lookup
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    revocation_reason VARCHAR(255),
    scope VARCHAR(500),
    claims JSONB, -- Token claims/attributes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. SSO Audit Log
CREATE TABLE sso_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID, -- Internal user ID
    provider_id UUID REFERENCES sso_providers(provider_id),
    action VARCHAR(100) NOT NULL, -- login, logout, token_refresh, mapping_created, etc.
    action_status VARCHAR(50), -- success, failure, error
    error_code VARCHAR(100),
    error_message TEXT,
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(255),
    response_time_ms INTEGER,
    additional_data JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Provider Health Monitoring
CREATE TABLE sso_provider_health (
    health_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES sso_providers(provider_id),
    check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_type VARCHAR(50), -- connectivity, authentication, performance
    response_time_ms INTEGER,
    status_code INTEGER,
    is_healthy BOOLEAN,
    error_details TEXT,
    metrics JSONB, -- success_rate, avg_response_time, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. User Attribute Mappings
CREATE TABLE sso_attribute_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES sso_providers(provider_id),
    external_attribute VARCHAR(255) NOT NULL, -- Attribute from provider
    internal_attribute VARCHAR(255) NOT NULL, -- WFM system attribute
    transformation_rule TEXT, -- Optional transformation logic
    is_required BOOLEAN DEFAULT false,
    default_value VARCHAR(500),
    validation_regex VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider_id, external_attribute)
);

-- 8. SSO Group Mappings
CREATE TABLE sso_group_mappings (
    group_mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES sso_providers(provider_id),
    external_group_id VARCHAR(255) NOT NULL,
    external_group_name VARCHAR(255),
    internal_role VARCHAR(100), -- Maps to WFM roles
    internal_permissions JSONB,
    mapping_priority INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider_id, external_group_id)
);

-- 9. SSO Configuration Templates
CREATE TABLE sso_config_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) NOT NULL UNIQUE,
    provider_type VARCHAR(50) NOT NULL,
    template_config JSONB NOT NULL, -- Standard configuration
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. SSO Failover Configuration
CREATE TABLE sso_failover_config (
    failover_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    primary_provider_id UUID REFERENCES sso_providers(provider_id),
    secondary_provider_id UUID REFERENCES sso_providers(provider_id),
    failover_type VARCHAR(50), -- automatic, manual, scheduled
    health_check_interval INTERVAL DEFAULT '1 minute',
    failover_threshold INTEGER DEFAULT 3, -- Failed checks before failover
    is_active BOOLEAN DEFAULT true,
    last_failover TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(primary_provider_id, secondary_provider_id)
);

-- Insert sample SSO providers
INSERT INTO sso_providers (provider_name, provider_type, base_url, priority_order, health_status)
VALUES 
    ('Corporate Active Directory', 'active_directory', 'ldap://corp.example.ru', 1, 'healthy'),
    ('1C Authentication', 'oauth2', 'https://1c.example.ru/oauth', 2, 'healthy'),
    ('Backup Local Auth', 'local', 'internal', 999, 'healthy');

-- Insert configuration templates
INSERT INTO sso_config_templates (template_name, provider_type, template_config, is_default)
VALUES 
    ('Russian AD Standard', 'active_directory', 
     '{"domain": "CORP", "use_ssl": true, "port": 636, "base_dn": "DC=corp,DC=ru"}'::jsonb, true),
    ('1C OAuth Standard', 'oauth2',
     '{"grant_type": "authorization_code", "scope": "profile email", "russian_locale": true}'::jsonb, false);

-- Insert attribute mappings for AD
INSERT INTO sso_attribute_mappings (provider_id, external_attribute, internal_attribute, is_required)
SELECT 
    provider_id,
    ext_attr,
    int_attr,
    required
FROM sso_providers
CROSS JOIN (VALUES 
    ('sAMAccountName', 'username', true),
    ('mail', 'email', true),
    ('displayName', 'display_name', true),
    ('employeeNumber', 'employee_number', false)
) AS mappings(ext_attr, int_attr, required)
WHERE provider_type = 'active_directory';

-- Create indexes for performance
CREATE INDEX idx_sso_users_provider ON sso_users(provider_id);
CREATE INDEX idx_sso_users_internal ON sso_users(internal_user_id);
CREATE INDEX idx_sso_sessions_user ON sso_sessions(sso_user_id);
CREATE INDEX idx_sso_sessions_active ON sso_sessions(is_active, expires_at);
CREATE INDEX idx_sso_audit_user_time ON sso_audit_log(user_id, timestamp);
CREATE INDEX idx_sso_tokens_hash ON sso_tokens(token_hash);

-- Verify SSO tables
SELECT COUNT(*) as sso_tables_count FROM information_schema.tables WHERE table_name LIKE 'sso_%';