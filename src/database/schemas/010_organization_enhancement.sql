-- =====================================================================================
-- Organization Enhancement Schema - Enterprise RBAC & Multi-Site Support
-- Module: Advanced organizational structure with enterprise features
-- Created for: DATABASE-OPUS Agent - Subagent 3
-- Purpose: Complete enterprise-grade organization management with RBAC, audit trails,
--          multi-site support, succession planning, and competency framework
-- Enhancement of: 005_organization_roles.sql
-- Priority: CRITICAL - Unblocks enterprise deployment
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- 1. ORGANIZATION_HIERARCHY - Enhanced Multi-Level Structure
-- =====================================================================================

CREATE TABLE IF NOT EXISTS organization_hierarchy (
    hierarchy_id SERIAL PRIMARY KEY,
    organization_unit_id INTEGER NOT NULL,
    parent_unit_id INTEGER,
    unit_type VARCHAR(50) NOT NULL CHECK (unit_type IN (
        'enterprise', 'holding', 'company', 'division', 'region', 'area',
        'site', 'department', 'team', 'squad', 'group', 'workgroup'
    )),
    unit_code VARCHAR(100) UNIQUE NOT NULL,
    unit_name VARCHAR(255) NOT NULL,
    unit_name_local VARCHAR(255),
    unit_description TEXT,
    business_unit_type VARCHAR(50) CHECK (business_unit_type IN (
        'operational', 'support', 'strategic', 'project', 'virtual', 'matrix'
    )),
    cost_center_code VARCHAR(100),
    profit_center_code VARCHAR(100),
    budget_code VARCHAR(100),
    legal_entity_code VARCHAR(100),
    geography_code VARCHAR(100),
    time_zone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    currency_code VARCHAR(3) DEFAULT 'RUB',
    materialized_path TEXT NOT NULL,
    hierarchy_level INTEGER NOT NULL DEFAULT 0,
    hierarchy_order INTEGER DEFAULT 0,
    employee_capacity INTEGER,
    current_employee_count INTEGER DEFAULT 0,
    is_virtual BOOLEAN DEFAULT FALSE,
    is_matrix_unit BOOLEAN DEFAULT FALSE,
    requires_security_clearance BOOLEAN DEFAULT FALSE,
    security_level VARCHAR(20) DEFAULT 'standard',
    operational_status VARCHAR(20) DEFAULT 'active' CHECK (operational_status IN (
        'active', 'inactive', 'planned', 'suspended', 'closing', 'closed'
    )),
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_by INTEGER,
    
    CONSTRAINT no_self_parent CHECK (organization_unit_id != parent_unit_id),
    CONSTRAINT valid_hierarchy_level CHECK (hierarchy_level >= 0 AND hierarchy_level <= 15),
    CONSTRAINT valid_effective_period CHECK (effective_until IS NULL OR effective_until > effective_from),
    CONSTRAINT unique_active_unit_code UNIQUE (unit_code, effective_from)
);

-- Indexes for organization_hierarchy
CREATE INDEX idx_org_hierarchy_parent ON organization_hierarchy(parent_unit_id);
CREATE INDEX idx_org_hierarchy_path ON organization_hierarchy(materialized_path);
CREATE INDEX idx_org_hierarchy_level ON organization_hierarchy(hierarchy_level);
CREATE INDEX idx_org_hierarchy_type ON organization_hierarchy(unit_type);
CREATE INDEX idx_org_hierarchy_status ON organization_hierarchy(operational_status);
CREATE INDEX idx_org_hierarchy_effective ON organization_hierarchy(effective_from, effective_until);
CREATE INDEX idx_org_hierarchy_business_type ON organization_hierarchy(business_unit_type);

-- =====================================================================================
-- 2. ROLE_PERMISSIONS - Granular Permission System
-- =====================================================================================

CREATE TABLE IF NOT EXISTS role_permissions_enhanced (
    role_permission_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
    permission_scope VARCHAR(50) DEFAULT 'standard' CHECK (permission_scope IN (
        'global', 'organization', 'division', 'department', 'team', 'personal', 'custom'
    )),
    resource_filter JSONB DEFAULT '{}',
    data_access_level VARCHAR(20) DEFAULT 'read' CHECK (data_access_level IN (
        'none', 'read', 'write', 'delete', 'admin', 'owner'
    )),
    condition_rules JSONB DEFAULT '{}',
    time_restrictions JSONB DEFAULT '{}',
    location_restrictions JSONB DEFAULT '{}',
    delegation_allowed BOOLEAN DEFAULT FALSE,
    inheritance_blocked BOOLEAN DEFAULT FALSE,
    priority_weight INTEGER DEFAULT 100,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    granted_by INTEGER NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_by INTEGER,
    revoked_at TIMESTAMPTZ,
    revocation_reason TEXT,
    approval_required BOOLEAN DEFAULT FALSE,
    approval_workflow_id INTEGER,
    is_emergency_grant BOOLEAN DEFAULT FALSE,
    compliance_tags TEXT[],
    audit_category VARCHAR(50) DEFAULT 'standard',
    
    CONSTRAINT unique_role_permission_scope UNIQUE(role_id, permission_id, permission_scope),
    CONSTRAINT valid_permission_period CHECK (effective_until IS NULL OR effective_until > effective_from),
    CONSTRAINT valid_revocation CHECK (revoked_at IS NULL OR revoked_at > granted_at)
);

-- Indexes for role_permissions_enhanced
CREATE INDEX idx_role_perm_enhanced_role ON role_permissions_enhanced(role_id);
CREATE INDEX idx_role_perm_enhanced_permission ON role_permissions_enhanced(permission_id);
CREATE INDEX idx_role_perm_enhanced_scope ON role_permissions_enhanced(permission_scope);
CREATE INDEX idx_role_perm_enhanced_effective ON role_permissions_enhanced(effective_from, effective_until);
CREATE INDEX idx_role_perm_enhanced_revoked ON role_permissions_enhanced(revoked_at) WHERE revoked_at IS NOT NULL;
CREATE INDEX idx_role_perm_enhanced_compliance ON role_permissions_enhanced USING GIN(compliance_tags);

-- =====================================================================================
-- 3. ROLE_ASSIGNMENTS - Dynamic Role Assignments
-- =====================================================================================

CREATE TABLE IF NOT EXISTS role_assignments_enhanced (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    assignment_type VARCHAR(20) DEFAULT 'permanent' CHECK (assignment_type IN (
        'permanent', 'temporary', 'project', 'matrix', 'acting', 'emergency'
    )),
    assignment_scope VARCHAR(50) DEFAULT 'full' CHECK (assignment_scope IN (
        'full', 'limited', 'read_only', 'specific_functions', 'emergency_only'
    )),
    specific_permissions TEXT[],
    excluded_permissions TEXT[],
    context_restrictions JSONB DEFAULT '{}',
    auto_assignment_rule VARCHAR(255),
    workflow_state VARCHAR(20) DEFAULT 'active' CHECK (workflow_state IN (
        'pending', 'approved', 'active', 'suspended', 'expired', 'revoked'
    )),
    requires_confirmation BOOLEAN DEFAULT FALSE,
    confirmation_by INTEGER,
    confirmation_at TIMESTAMPTZ,
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    auto_extend_days INTEGER,
    max_extensions INTEGER DEFAULT 0,
    current_extensions INTEGER DEFAULT 0,
    assigned_by INTEGER NOT NULL,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    assignment_reason TEXT,
    business_justification TEXT,
    risk_assessment_level VARCHAR(20) DEFAULT 'low' CHECK (risk_assessment_level IN (
        'low', 'medium', 'high', 'critical'
    )),
    compliance_approval_required BOOLEAN DEFAULT FALSE,
    compliance_approved_by INTEGER,
    compliance_approved_at TIMESTAMPTZ,
    last_access_check TIMESTAMPTZ,
    access_review_due DATE,
    review_frequency_days INTEGER DEFAULT 90,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_active_assignment UNIQUE(employee_id, role_id, organization_unit_id, assignment_type),
    CONSTRAINT valid_assignment_period CHECK (valid_until IS NULL OR valid_until > valid_from),
    CONSTRAINT valid_extension_limit CHECK (current_extensions <= max_extensions)
);

-- Indexes for role_assignments_enhanced
CREATE INDEX idx_role_assign_enhanced_employee ON role_assignments_enhanced(employee_id);
CREATE INDEX idx_role_assign_enhanced_role ON role_assignments_enhanced(role_id);
CREATE INDEX idx_role_assign_enhanced_org_unit ON role_assignments_enhanced(organization_unit_id);
CREATE INDEX idx_role_assign_enhanced_type ON role_assignments_enhanced(assignment_type);
CREATE INDEX idx_role_assign_enhanced_workflow ON role_assignments_enhanced(workflow_state);
CREATE INDEX idx_role_assign_enhanced_validity ON role_assignments_enhanced(valid_from, valid_until);
CREATE INDEX idx_role_assign_enhanced_review ON role_assignments_enhanced(access_review_due);
CREATE INDEX idx_role_assign_enhanced_risk ON role_assignments_enhanced(risk_assessment_level);

-- =====================================================================================
-- 4. DELEGATION_RULES - Advanced Delegation
-- =====================================================================================

CREATE TABLE IF NOT EXISTS delegation_rules_enhanced (
    delegation_id SERIAL PRIMARY KEY,
    delegation_name VARCHAR(255) NOT NULL,
    delegator_id INTEGER NOT NULL REFERENCES employees(employee_id),
    delegate_id INTEGER NOT NULL REFERENCES employees(employee_id),
    delegation_type VARCHAR(50) NOT NULL CHECK (delegation_type IN (
        'full_authority', 'specific_permissions', 'role_based', 'function_based',
        'approval_chain', 'emergency_only', 'time_limited', 'conditional'
    )),
    delegation_scope VARCHAR(50) DEFAULT 'department' CHECK (delegation_scope IN (
        'global', 'organization', 'division', 'department', 'team', 'project', 'specific'
    )),
    specific_roles INTEGER[],
    specific_permissions TEXT[],
    specific_functions TEXT[],
    organization_units INTEGER[],
    delegation_conditions JSONB DEFAULT '{}',
    trigger_conditions JSONB DEFAULT '{}',
    auto_activation_rules JSONB DEFAULT '{}',
    escalation_rules JSONB DEFAULT '{}',
    notification_rules JSONB DEFAULT '{}',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    time_pattern VARCHAR(50), -- 'business_hours', 'weekends', 'nights', 'custom'
    time_restrictions JSONB DEFAULT '{}',
    is_automatic BOOLEAN DEFAULT FALSE,
    is_conditional BOOLEAN DEFAULT FALSE,
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_workflow_id INTEGER,
    approved_by INTEGER,
    approved_at TIMESTAMPTZ,
    priority_level INTEGER DEFAULT 100,
    can_redelegate BOOLEAN DEFAULT FALSE,
    max_redelegation_levels INTEGER DEFAULT 0,
    current_redelegation_level INTEGER DEFAULT 0,
    delegation_chain TEXT[],
    usage_tracking JSONB DEFAULT '{}',
    last_used_at TIMESTAMPTZ,
    usage_count INTEGER DEFAULT 0,
    emergency_override BOOLEAN DEFAULT FALSE,
    compliance_risk_level VARCHAR(20) DEFAULT 'low',
    audit_logging_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT no_self_delegation CHECK (delegator_id != delegate_id),
    CONSTRAINT valid_delegation_period CHECK (end_date > start_date),
    CONSTRAINT valid_redelegation_level CHECK (current_redelegation_level <= max_redelegation_levels)
);

-- Indexes for delegation_rules_enhanced
CREATE INDEX idx_delegation_enhanced_delegator ON delegation_rules_enhanced(delegator_id);
CREATE INDEX idx_delegation_enhanced_delegate ON delegation_rules_enhanced(delegate_id);
CREATE INDEX idx_delegation_enhanced_type ON delegation_rules_enhanced(delegation_type);
CREATE INDEX idx_delegation_enhanced_scope ON delegation_rules_enhanced(delegation_scope);
CREATE INDEX idx_delegation_enhanced_active ON delegation_rules_enhanced(start_date, end_date);
CREATE INDEX idx_delegation_enhanced_approval ON delegation_rules_enhanced(approved_by, approved_at);
CREATE INDEX idx_delegation_enhanced_priority ON delegation_rules_enhanced(priority_level);
CREATE INDEX idx_delegation_enhanced_last_used ON delegation_rules_enhanced(last_used_at);
CREATE INDEX idx_delegation_enhanced_roles ON delegation_rules_enhanced USING GIN(specific_roles);
CREATE INDEX idx_delegation_enhanced_org_units ON delegation_rules_enhanced USING GIN(organization_units);

-- =====================================================================================
-- 5. ACCESS_POLICIES - Row-Level Security
-- =====================================================================================

CREATE TABLE IF NOT EXISTS access_policies (
    policy_id SERIAL PRIMARY KEY,
    policy_name VARCHAR(255) NOT NULL,
    policy_code VARCHAR(100) UNIQUE NOT NULL,
    policy_type VARCHAR(50) NOT NULL CHECK (policy_type IN (
        'row_level_security', 'column_level_security', 'field_level_security',
        'data_classification', 'geographic_restriction', 'time_based_access'
    )),
    target_table VARCHAR(100) NOT NULL,
    target_columns TEXT[],
    policy_expression TEXT NOT NULL,
    policy_conditions JSONB DEFAULT '{}',
    security_classification VARCHAR(20) DEFAULT 'internal' CHECK (security_classification IN (
        'public', 'internal', 'confidential', 'restricted', 'top_secret'
    )),
    data_residency_requirements TEXT[],
    geographic_restrictions TEXT[],
    compliance_framework VARCHAR(100),
    applicable_roles TEXT[],
    applicable_permissions TEXT[],
    exception_roles TEXT[],
    override_conditions JSONB DEFAULT '{}',
    policy_priority INTEGER DEFAULT 100,
    is_enforced BOOLEAN DEFAULT TRUE,
    enforcement_mode VARCHAR(20) DEFAULT 'strict' CHECK (enforcement_mode IN (
        'strict', 'permissive', 'audit_only', 'warn_only'
    )),
    violation_action VARCHAR(50) DEFAULT 'deny' CHECK (violation_action IN (
        'deny', 'allow_with_audit', 'allow_with_warning', 'escalate'
    )),
    audit_required BOOLEAN DEFAULT TRUE,
    performance_impact_level VARCHAR(20) DEFAULT 'low',
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT valid_policy_period CHECK (effective_until IS NULL OR effective_until > effective_from),
    CONSTRAINT valid_priority CHECK (policy_priority >= 1 AND policy_priority <= 1000)
);

-- Indexes for access_policies
CREATE INDEX idx_access_policies_table ON access_policies(target_table);
CREATE INDEX idx_access_policies_type ON access_policies(policy_type);
CREATE INDEX idx_access_policies_classification ON access_policies(security_classification);
CREATE INDEX idx_access_policies_effective ON access_policies(effective_from, effective_until);
CREATE INDEX idx_access_policies_enforced ON access_policies(is_enforced) WHERE is_enforced = TRUE;
CREATE INDEX idx_access_policies_priority ON access_policies(policy_priority);
CREATE INDEX idx_access_policies_roles ON access_policies USING GIN(applicable_roles);
CREATE INDEX idx_access_policies_permissions ON access_policies USING GIN(applicable_permissions);

-- =====================================================================================
-- 6. AUDIT_LOGS - Comprehensive Audit Trail
-- =====================================================================================

CREATE TABLE IF NOT EXISTS audit_logs_comprehensive (
    audit_id BIGSERIAL PRIMARY KEY,
    audit_uuid UUID DEFAULT gen_random_uuid() NOT NULL,
    event_timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(50) NOT NULL,
    event_subcategory VARCHAR(50),
    severity_level VARCHAR(20) DEFAULT 'info' CHECK (severity_level IN (
        'debug', 'info', 'warning', 'error', 'critical', 'security'
    )),
    actor_type VARCHAR(20) NOT NULL CHECK (actor_type IN (
        'user', 'system', 'service', 'batch', 'api', 'external'
    )),
    actor_id INTEGER,
    actor_name VARCHAR(255),
    actor_ip_address INET,
    actor_user_agent TEXT,
    actor_session_id VARCHAR(255),
    target_type VARCHAR(50),
    target_id INTEGER,
    target_name VARCHAR(255),
    target_table VARCHAR(100),
    target_record_id INTEGER,
    action_performed VARCHAR(100) NOT NULL,
    action_status VARCHAR(20) DEFAULT 'success' CHECK (action_status IN (
        'success', 'failure', 'partial', 'cancelled', 'pending'
    )),
    business_context VARCHAR(255),
    transaction_id VARCHAR(255),
    correlation_id VARCHAR(255),
    request_id VARCHAR(255),
    affected_records_count INTEGER DEFAULT 0,
    data_before JSONB,
    data_after JSONB,
    data_changes JSONB,
    sensitive_data_involved BOOLEAN DEFAULT FALSE,
    pii_data_involved BOOLEAN DEFAULT FALSE,
    compliance_relevant BOOLEAN DEFAULT FALSE,
    compliance_framework VARCHAR(100),
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN (
        'low', 'medium', 'high', 'critical'
    )),
    geographic_location VARCHAR(100),
    time_zone VARCHAR(50),
    application_name VARCHAR(100),
    application_version VARCHAR(50),
    api_endpoint VARCHAR(255),
    error_code VARCHAR(100),
    error_message TEXT,
    error_stack_trace TEXT,
    performance_metrics JSONB,
    custom_attributes JSONB DEFAULT '{}',
    retention_period_days INTEGER DEFAULT 2555, -- 7 years
    archival_date DATE,
    is_archived BOOLEAN DEFAULT FALSE,
    hash_signature VARCHAR(512),
    digital_signature TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for audit_logs_comprehensive
CREATE INDEX idx_audit_logs_timestamp ON audit_logs_comprehensive(event_timestamp DESC);
CREATE INDEX idx_audit_logs_event_type ON audit_logs_comprehensive(event_type);
CREATE INDEX idx_audit_logs_category ON audit_logs_comprehensive(event_category);
CREATE INDEX idx_audit_logs_severity ON audit_logs_comprehensive(severity_level);
CREATE INDEX idx_audit_logs_actor ON audit_logs_comprehensive(actor_type, actor_id);
CREATE INDEX idx_audit_logs_target ON audit_logs_comprehensive(target_type, target_id);
CREATE INDEX idx_audit_logs_action ON audit_logs_comprehensive(action_performed);
CREATE INDEX idx_audit_logs_status ON audit_logs_comprehensive(action_status);
CREATE INDEX idx_audit_logs_compliance ON audit_logs_comprehensive(compliance_relevant) WHERE compliance_relevant = TRUE;
CREATE INDEX idx_audit_logs_risk ON audit_logs_comprehensive(risk_level);
CREATE INDEX idx_audit_logs_pii ON audit_logs_comprehensive(pii_data_involved) WHERE pii_data_involved = TRUE;
CREATE INDEX idx_audit_logs_correlation ON audit_logs_comprehensive(correlation_id);
CREATE INDEX idx_audit_logs_transaction ON audit_logs_comprehensive(transaction_id);
CREATE INDEX idx_audit_logs_archival ON audit_logs_comprehensive(archival_date, is_archived);

-- =====================================================================================
-- 7. ORGANIZATION_SETTINGS - Configurable Settings
-- =====================================================================================

CREATE TABLE IF NOT EXISTS organization_settings (
    setting_id SERIAL PRIMARY KEY,
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    setting_category VARCHAR(100) NOT NULL,
    setting_group VARCHAR(100) NOT NULL,
    setting_key VARCHAR(255) NOT NULL,
    setting_name VARCHAR(255) NOT NULL,
    setting_description TEXT,
    setting_type VARCHAR(20) NOT NULL CHECK (setting_type IN (
        'string', 'integer', 'decimal', 'boolean', 'json', 'array', 'date', 'datetime'
    )),
    setting_value TEXT,
    setting_value_json JSONB,
    default_value TEXT,
    allowed_values TEXT[],
    validation_rules JSONB DEFAULT '{}',
    is_required BOOLEAN DEFAULT FALSE,
    is_sensitive BOOLEAN DEFAULT FALSE,
    is_encrypted BOOLEAN DEFAULT FALSE,
    inheritance_mode VARCHAR(20) DEFAULT 'inherit' CHECK (inheritance_mode IN (
        'inherit', 'override', 'merge', 'block'
    )),
    scope_level VARCHAR(20) DEFAULT 'organization' CHECK (scope_level IN (
        'global', 'enterprise', 'organization', 'division', 'department', 'team'
    )),
    configuration_profile VARCHAR(100),
    feature_flag VARCHAR(100),
    environment_specific BOOLEAN DEFAULT FALSE,
    requires_restart BOOLEAN DEFAULT FALSE,
    change_approval_required BOOLEAN DEFAULT FALSE,
    change_approval_workflow_id INTEGER,
    last_changed_by INTEGER,
    last_changed_at TIMESTAMPTZ,
    change_reason TEXT,
    rollback_value TEXT,
    rollback_available BOOLEAN DEFAULT FALSE,
    audit_changes BOOLEAN DEFAULT TRUE,
    compliance_impact BOOLEAN DEFAULT FALSE,
    security_impact BOOLEAN DEFAULT FALSE,
    performance_impact VARCHAR(20) DEFAULT 'none' CHECK (performance_impact IN (
        'none', 'low', 'medium', 'high', 'critical'
    )),
    documentation_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT unique_org_setting UNIQUE(organization_unit_id, setting_category, setting_group, setting_key),
    CONSTRAINT valid_setting_value CHECK (
        (setting_type = 'json' AND setting_value_json IS NOT NULL) OR
        (setting_type != 'json' AND setting_value IS NOT NULL)
    )
);

-- Indexes for organization_settings
CREATE INDEX idx_org_settings_unit ON organization_settings(organization_unit_id);
CREATE INDEX idx_org_settings_category ON organization_settings(setting_category);
CREATE INDEX idx_org_settings_group ON organization_settings(setting_group);
CREATE INDEX idx_org_settings_key ON organization_settings(setting_key);
CREATE INDEX idx_org_settings_scope ON organization_settings(scope_level);
CREATE INDEX idx_org_settings_profile ON organization_settings(configuration_profile);
CREATE INDEX idx_org_settings_feature ON organization_settings(feature_flag);
CREATE INDEX idx_org_settings_sensitive ON organization_settings(is_sensitive) WHERE is_sensitive = TRUE;
CREATE INDEX idx_org_settings_compliance ON organization_settings(compliance_impact) WHERE compliance_impact = TRUE;

-- =====================================================================================
-- 8. LOCATION_MANAGEMENT - Multi-Site Support
-- =====================================================================================

CREATE TABLE IF NOT EXISTS location_management (
    location_id SERIAL PRIMARY KEY,
    location_code VARCHAR(100) UNIQUE NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    location_name_local VARCHAR(255),
    location_type VARCHAR(50) NOT NULL CHECK (location_type IN (
        'headquarters', 'regional_office', 'branch_office', 'call_center',
        'data_center', 'warehouse', 'retail_store', 'service_center',
        'remote_office', 'virtual_location', 'mobile_unit', 'temporary_site'
    )),
    parent_location_id INTEGER REFERENCES location_management(location_id),
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(3) NOT NULL DEFAULT 'RUS',
    country_name VARCHAR(100),
    geographic_region VARCHAR(100),
    time_zone VARCHAR(50) NOT NULL,
    utc_offset VARCHAR(10),
    coordinates_lat DECIMAL(10, 8),
    coordinates_lon DECIMAL(11, 8),
    elevation_meters INTEGER,
    phone_primary VARCHAR(50),
    phone_secondary VARCHAR(50),
    fax VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    emergency_contact_info JSONB DEFAULT '{}',
    facility_details JSONB DEFAULT '{}',
    capacity_total_seats INTEGER,
    capacity_current_occupied INTEGER DEFAULT 0,
    capacity_reserved_seats INTEGER DEFAULT 0,
    capacity_available_seats INTEGER GENERATED ALWAYS AS (capacity_total_seats - capacity_current_occupied - capacity_reserved_seats) STORED,
    floor_plans JSONB DEFAULT '{}',
    equipment_inventory JSONB DEFAULT '{}',
    security_features JSONB DEFAULT '{}',
    accessibility_features JSONB DEFAULT '{}',
    environmental_conditions JSONB DEFAULT '{}',
    operating_hours JSONB DEFAULT '{}',
    special_schedules JSONB DEFAULT '{}',
    is_24x7_operation BOOLEAN DEFAULT FALSE,
    closure_dates DATE[],
    maintenance_schedule JSONB DEFAULT '{}',
    cost_center_code VARCHAR(100),
    budget_code VARCHAR(100),
    lease_information JSONB DEFAULT '{}',
    compliance_certifications TEXT[],
    safety_certifications TEXT[],
    insurance_details JSONB DEFAULT '{}',
    vendor_information JSONB DEFAULT '{}',
    service_level_agreements JSONB DEFAULT '{}',
    disaster_recovery_site_id INTEGER,
    backup_location_id INTEGER,
    location_status VARCHAR(20) DEFAULT 'active' CHECK (location_status IN (
        'active', 'inactive', 'under_construction', 'maintenance', 'temporary_closed', 'permanently_closed'
    )),
    commissioning_date DATE,
    decommissioning_date DATE,
    last_inspection_date DATE,
    next_inspection_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT valid_coordinates CHECK (
        (coordinates_lat IS NULL AND coordinates_lon IS NULL) OR
        (coordinates_lat IS NOT NULL AND coordinates_lon IS NOT NULL AND
         coordinates_lat BETWEEN -90 AND 90 AND coordinates_lon BETWEEN -180 AND 180)
    ),
    CONSTRAINT valid_capacity CHECK (capacity_total_seats >= 0 AND capacity_current_occupied >= 0),
    CONSTRAINT no_self_parent CHECK (location_id != parent_location_id)
);

-- Indexes for location_management
CREATE INDEX idx_location_mgmt_code ON location_management(location_code);
CREATE INDEX idx_location_mgmt_type ON location_management(location_type);
CREATE INDEX idx_location_mgmt_parent ON location_management(parent_location_id);
CREATE INDEX idx_location_mgmt_org_unit ON location_management(organization_unit_id);
CREATE INDEX idx_location_mgmt_country ON location_management(country_code);
CREATE INDEX idx_location_mgmt_region ON location_management(geographic_region);
CREATE INDEX idx_location_mgmt_status ON location_management(location_status);
CREATE INDEX idx_location_mgmt_coordinates ON location_management(coordinates_lat, coordinates_lon);
CREATE INDEX idx_location_mgmt_capacity ON location_management(capacity_available_seats);
CREATE INDEX idx_location_mgmt_timezone ON location_management(time_zone);

-- =====================================================================================
-- 9. TEAM_STRUCTURES - Team/Squad Management
-- =====================================================================================

CREATE TABLE IF NOT EXISTS team_structures (
    team_id SERIAL PRIMARY KEY,
    team_code VARCHAR(100) UNIQUE NOT NULL,
    team_name VARCHAR(255) NOT NULL,
    team_name_local VARCHAR(255),
    team_type VARCHAR(50) NOT NULL CHECK (team_type IN (
        'permanent', 'temporary', 'project', 'cross_functional', 'virtual',
        'squad', 'tribe', 'chapter', 'guild', 'community_of_practice'
    )),
    team_methodology VARCHAR(50) CHECK (team_methodology IN (
        'agile', 'scrum', 'kanban', 'lean', 'traditional', 'hybrid', 'custom'
    )),
    parent_team_id INTEGER REFERENCES team_structures(team_id),
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    location_id INTEGER REFERENCES location_management(location_id),
    team_lead_id INTEGER REFERENCES employees(employee_id),
    product_owner_id INTEGER REFERENCES employees(employee_id),
    scrum_master_id INTEGER REFERENCES employees(employee_id),
    business_owner_id INTEGER REFERENCES employees(employee_id),
    team_description TEXT,
    team_mission TEXT,
    team_objectives TEXT[],
    key_responsibilities TEXT[],
    success_metrics JSONB DEFAULT '{}',
    team_charter_document TEXT,
    formation_date DATE DEFAULT CURRENT_DATE,
    dissolution_date DATE,
    team_status VARCHAR(20) DEFAULT 'active' CHECK (team_status IN (
        'forming', 'storming', 'norming', 'performing', 'adjourning', 'active', 'inactive', 'dissolved'
    )),
    min_team_size INTEGER DEFAULT 1,
    max_team_size INTEGER DEFAULT 15,
    current_team_size INTEGER DEFAULT 0,
    target_team_size INTEGER,
    skill_requirements JSONB DEFAULT '{}',
    role_definitions JSONB DEFAULT '{}',
    collaboration_tools JSONB DEFAULT '{}',
    communication_protocols JSONB DEFAULT '{}',
    meeting_schedule JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    team_budget_code VARCHAR(100),
    cost_allocation_method VARCHAR(50),
    working_hours_pattern VARCHAR(50),
    time_zone VARCHAR(50),
    remote_work_policy VARCHAR(50),
    security_clearance_required BOOLEAN DEFAULT FALSE,
    compliance_requirements TEXT[],
    escalation_procedures JSONB DEFAULT '{}',
    knowledge_base_links TEXT[],
    training_requirements TEXT[],
    onboarding_process JSONB DEFAULT '{}',
    offboarding_process JSONB DEFAULT '{}',
    team_rituals JSONB DEFAULT '{}',
    retrospective_schedule VARCHAR(50),
    continuous_improvement_process JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT valid_team_size CHECK (
        min_team_size <= max_team_size AND
        current_team_size >= 0 AND
        (target_team_size IS NULL OR target_team_size BETWEEN min_team_size AND max_team_size)
    ),
    CONSTRAINT valid_dissolution CHECK (dissolution_date IS NULL OR dissolution_date > formation_date),
    CONSTRAINT no_self_parent CHECK (team_id != parent_team_id)
);

-- Indexes for team_structures
CREATE INDEX idx_team_structures_code ON team_structures(team_code);
CREATE INDEX idx_team_structures_type ON team_structures(team_type);
CREATE INDEX idx_team_structures_parent ON team_structures(parent_team_id);
CREATE INDEX idx_team_structures_org_unit ON team_structures(organization_unit_id);
CREATE INDEX idx_team_structures_location ON team_structures(location_id);
CREATE INDEX idx_team_structures_lead ON team_structures(team_lead_id);
CREATE INDEX idx_team_structures_status ON team_structures(team_status);
CREATE INDEX idx_team_structures_formation ON team_structures(formation_date);
CREATE INDEX idx_team_structures_size ON team_structures(current_team_size, target_team_size);

-- =====================================================================================
-- 10. REPORTING_RELATIONSHIPS - Manager Chains
-- =====================================================================================

CREATE TABLE IF NOT EXISTS reporting_relationships (
    relationship_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    manager_id INTEGER NOT NULL REFERENCES employees(employee_id),
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN (
        'direct_report', 'indirect_report', 'matrix_report', 'functional_report',
        'project_report', 'temporary_report', 'dotted_line', 'dual_report'
    )),
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    team_id INTEGER REFERENCES team_structures(team_id),
    reporting_percentage DECIMAL(5,2) DEFAULT 100.00,
    authority_level VARCHAR(20) DEFAULT 'standard' CHECK (authority_level IN (
        'full', 'limited', 'advisory', 'coordination', 'escalation_only'
    )),
    decision_making_scope TEXT[],
    approval_authorities TEXT[],
    delegation_permissions TEXT[],
    escalation_path INTEGER[],
    backup_manager_id INTEGER REFERENCES employees(employee_id),
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    is_primary_relationship BOOLEAN DEFAULT TRUE,
    relationship_context VARCHAR(255),
    performance_review_responsibility BOOLEAN DEFAULT TRUE,
    budget_approval_limit DECIMAL(15,2),
    hiring_authority BOOLEAN DEFAULT FALSE,
    termination_authority BOOLEAN DEFAULT FALSE,
    compensation_authority BOOLEAN DEFAULT FALSE,
    promotion_authority BOOLEAN DEFAULT FALSE,
    training_approval_authority BOOLEAN DEFAULT FALSE,
    travel_approval_authority BOOLEAN DEFAULT FALSE,
    expense_approval_limit DECIMAL(15,2),
    time_off_approval_authority BOOLEAN DEFAULT TRUE,
    schedule_modification_authority BOOLEAN DEFAULT FALSE,
    goal_setting_authority BOOLEAN DEFAULT TRUE,
    development_plan_authority BOOLEAN DEFAULT TRUE,
    disciplinary_action_authority BOOLEAN DEFAULT FALSE,
    recognition_authority BOOLEAN DEFAULT TRUE,
    confidentiality_level VARCHAR(20) DEFAULT 'standard',
    compliance_responsibilities TEXT[],
    reporting_frequency VARCHAR(20) DEFAULT 'weekly',
    communication_preferences JSONB DEFAULT '{}',
    meeting_schedule JSONB DEFAULT '{}',
    feedback_mechanisms JSONB DEFAULT '{}',
    performance_indicators JSONB DEFAULT '{}',
    relationship_history JSONB DEFAULT '{}',
    transition_plan JSONB DEFAULT '{}',
    succession_readiness BOOLEAN DEFAULT FALSE,
    mentoring_responsibilities BOOLEAN DEFAULT FALSE,
    coaching_responsibilities BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT no_self_reporting CHECK (employee_id != manager_id),
    CONSTRAINT valid_reporting_period CHECK (effective_until IS NULL OR effective_until > effective_from),
    CONSTRAINT valid_percentage CHECK (reporting_percentage >= 0 AND reporting_percentage <= 100),
    CONSTRAINT valid_approval_limits CHECK (
        budget_approval_limit IS NULL OR budget_approval_limit >= 0
    )
);

-- Indexes for reporting_relationships
CREATE INDEX idx_reporting_rels_employee ON reporting_relationships(employee_id);
CREATE INDEX idx_reporting_rels_manager ON reporting_relationships(manager_id);
CREATE INDEX idx_reporting_rels_type ON reporting_relationships(relationship_type);
CREATE INDEX idx_reporting_rels_org_unit ON reporting_relationships(organization_unit_id);
CREATE INDEX idx_reporting_rels_team ON reporting_relationships(team_id);
CREATE INDEX idx_reporting_rels_primary ON reporting_relationships(is_primary_relationship) WHERE is_primary_relationship = TRUE;
CREATE INDEX idx_reporting_rels_effective ON reporting_relationships(effective_from, effective_until);
CREATE INDEX idx_reporting_rels_backup ON reporting_relationships(backup_manager_id);
CREATE INDEX idx_reporting_rels_succession ON reporting_relationships(succession_readiness) WHERE succession_readiness = TRUE;

-- =====================================================================================
-- 11. COMPETENCY_FRAMEWORK - Skills/Competencies
-- =====================================================================================

CREATE TABLE IF NOT EXISTS competency_framework (
    competency_id SERIAL PRIMARY KEY,
    competency_code VARCHAR(100) UNIQUE NOT NULL,
    competency_name VARCHAR(255) NOT NULL,
    competency_name_local VARCHAR(255),
    competency_type VARCHAR(50) NOT NULL CHECK (competency_type IN (
        'core', 'functional', 'technical', 'behavioral', 'leadership',
        'management', 'specialized', 'certification', 'language', 'soft_skill'
    )),
    competency_category VARCHAR(100) NOT NULL,
    competency_subcategory VARCHAR(100),
    competency_description TEXT,
    competency_definition TEXT,
    behavioral_indicators TEXT[],
    proficiency_levels JSONB NOT NULL DEFAULT '{}',
    assessment_criteria JSONB DEFAULT '{}',
    measurement_methods JSONB DEFAULT '{}',
    development_activities JSONB DEFAULT '{}',
    learning_resources JSONB DEFAULT '{}',
    certification_requirements JSONB DEFAULT '{}',
    industry_standard_reference VARCHAR(255),
    external_framework_mapping JSONB DEFAULT '{}',
    prerequisite_competencies INTEGER[],
    related_competencies INTEGER[],
    successor_competencies INTEGER[],
    competency_weight DECIMAL(5,2) DEFAULT 1.00,
    criticality_level VARCHAR(20) DEFAULT 'medium' CHECK (criticality_level IN (
        'low', 'medium', 'high', 'critical', 'strategic'
    )),
    obsolescence_risk VARCHAR(20) DEFAULT 'low' CHECK (obsolescence_risk IN (
        'low', 'medium', 'high', 'obsolete'
    )),
    market_demand_level VARCHAR(20) DEFAULT 'medium',
    internal_demand_level VARCHAR(20) DEFAULT 'medium',
    supply_availability VARCHAR(20) DEFAULT 'medium',
    development_timeframe_months INTEGER,
    maintenance_requirements JSONB DEFAULT '{}',
    refresh_frequency_months INTEGER DEFAULT 12,
    expiration_period_months INTEGER,
    version_number VARCHAR(20) DEFAULT '1.0',
    last_review_date DATE,
    next_review_date DATE,
    review_frequency_months INTEGER DEFAULT 12,
    governance_committee VARCHAR(255),
    subject_matter_experts INTEGER[],
    approval_status VARCHAR(20) DEFAULT 'draft' CHECK (approval_status IN (
        'draft', 'under_review', 'approved', 'published', 'deprecated', 'archived'
    )),
    approved_by INTEGER,
    approved_at TIMESTAMPTZ,
    publication_date DATE,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    applicable_roles TEXT[],
    applicable_positions TEXT[],
    applicable_departments TEXT[],
    applicable_locations TEXT[],
    compliance_mapping JSONB DEFAULT '{}',
    regulatory_requirements TEXT[],
    audit_trail JSONB DEFAULT '{}',
    usage_analytics JSONB DEFAULT '{}',
    feedback_collected JSONB DEFAULT '{}',
    continuous_improvement_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT valid_competency_period CHECK (effective_until IS NULL OR effective_until > effective_from),
    CONSTRAINT valid_weight CHECK (competency_weight >= 0 AND competency_weight <= 10),
    CONSTRAINT valid_development_timeframe CHECK (development_timeframe_months IS NULL OR development_timeframe_months > 0)
);

-- Indexes for competency_framework
CREATE INDEX idx_competency_framework_code ON competency_framework(competency_code);
CREATE INDEX idx_competency_framework_type ON competency_framework(competency_type);
CREATE INDEX idx_competency_framework_category ON competency_framework(competency_category);
CREATE INDEX idx_competency_framework_criticality ON competency_framework(criticality_level);
CREATE INDEX idx_competency_framework_status ON competency_framework(approval_status);
CREATE INDEX idx_competency_framework_effective ON competency_framework(effective_from, effective_until);
CREATE INDEX idx_competency_framework_review ON competency_framework(next_review_date);
CREATE INDEX idx_competency_framework_prerequisites ON competency_framework USING GIN(prerequisite_competencies);
CREATE INDEX idx_competency_framework_roles ON competency_framework USING GIN(applicable_roles);
CREATE INDEX idx_competency_framework_obsolescence ON competency_framework(obsolescence_risk);

-- =====================================================================================
-- 12. SUCCESSION_PLANNING - Backup Plans
-- =====================================================================================

CREATE TABLE IF NOT EXISTS succession_planning (
    succession_plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(255) NOT NULL,
    plan_code VARCHAR(100) UNIQUE NOT NULL,
    target_position_id INTEGER REFERENCES positions(position_id),
    target_employee_id INTEGER REFERENCES employees(employee_id),
    organization_unit_id INTEGER REFERENCES organization_hierarchy(organization_unit_id),
    team_id INTEGER REFERENCES team_structures(team_id),
    plan_type VARCHAR(50) NOT NULL CHECK (plan_type IN (
        'individual', 'position', 'department', 'critical_role', 'emergency',
        'leadership_pipeline', 'knowledge_transfer', 'cross_training'
    )),
    succession_scenario VARCHAR(50) NOT NULL CHECK (succession_scenario IN (
        'planned_retirement', 'promotion', 'transfer', 'resignation',
        'emergency_absence', 'termination', 'expansion', 'restructuring'
    )),
    timeline_type VARCHAR(20) NOT NULL CHECK (timeline_type IN (
        'immediate', 'short_term', 'medium_term', 'long_term', 'continuous'
    )),
    readiness_timeframe VARCHAR(50),
    priority_level VARCHAR(20) DEFAULT 'medium' CHECK (priority_level IN (
        'low', 'medium', 'high', 'critical', 'strategic'
    )),
    risk_assessment JSONB DEFAULT '{}',
    impact_analysis JSONB DEFAULT '{}',
    business_continuity_requirements JSONB DEFAULT '{}',
    succession_candidates JSONB DEFAULT '{}',
    readiness_assessment JSONB DEFAULT '{}',
    development_plans JSONB DEFAULT '{}',
    required_competencies INTEGER[],
    competency_gaps JSONB DEFAULT '{}',
    development_activities JSONB DEFAULT '{}',
    mentoring_assignments JSONB DEFAULT '{}',
    coaching_requirements JSONB DEFAULT '{}',
    cross_training_matrix JSONB DEFAULT '{}',
    knowledge_transfer_plan JSONB DEFAULT '{}',
    documentation_requirements TEXT[],
    handover_procedures JSONB DEFAULT '{}',
    transition_timeline JSONB DEFAULT '{}',
    interim_arrangements JSONB DEFAULT '{}',
    backup_options JSONB DEFAULT '{}',
    external_recruitment_plan JSONB DEFAULT '{}',
    vendor_alternatives JSONB DEFAULT '{}',
    budget_implications JSONB DEFAULT '{}',
    approval_requirements JSONB DEFAULT '{}',
    stakeholder_communication_plan JSONB DEFAULT '{}',
    success_metrics JSONB DEFAULT '{}',
    monitoring_schedule JSONB DEFAULT '{}',
    review_frequency_months INTEGER DEFAULT 6,
    last_review_date DATE,
    next_review_date DATE,
    plan_status VARCHAR(20) DEFAULT 'draft' CHECK (plan_status IN (
        'draft', 'under_review', 'approved', 'active', 'implemented', 'completed', 'cancelled'
    )),
    activation_triggers JSONB DEFAULT '{}',
    activation_date DATE,
    completion_date DATE,
    effectiveness_rating INTEGER CHECK (effectiveness_rating BETWEEN 1 AND 5),
    lessons_learned TEXT,
    improvement_recommendations TEXT,
    compliance_considerations JSONB DEFAULT '{}',
    legal_requirements JSONB DEFAULT '{}',
    confidentiality_level VARCHAR(20) DEFAULT 'confidential',
    access_restrictions JSONB DEFAULT '{}',
    audit_trail JSONB DEFAULT '{}',
    version_number VARCHAR(20) DEFAULT '1.0',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INTEGER,
    
    CONSTRAINT valid_timeframe CHECK (
        (activation_date IS NULL OR activation_date >= CURRENT_DATE) AND
        (completion_date IS NULL OR activation_date IS NULL OR completion_date >= activation_date)
    ),
    CONSTRAINT valid_effectiveness CHECK (effectiveness_rating IS NULL OR effectiveness_rating BETWEEN 1 AND 5),
    CONSTRAINT valid_review_frequency CHECK (review_frequency_months > 0)
);

-- Indexes for succession_planning
CREATE INDEX idx_succession_planning_code ON succession_planning(plan_code);
CREATE INDEX idx_succession_planning_position ON succession_planning(target_position_id);
CREATE INDEX idx_succession_planning_employee ON succession_planning(target_employee_id);
CREATE INDEX idx_succession_planning_org_unit ON succession_planning(organization_unit_id);
CREATE INDEX idx_succession_planning_team ON succession_planning(team_id);
CREATE INDEX idx_succession_planning_type ON succession_planning(plan_type);
CREATE INDEX idx_succession_planning_scenario ON succession_planning(succession_scenario);
CREATE INDEX idx_succession_planning_timeline ON succession_planning(timeline_type);
CREATE INDEX idx_succession_planning_priority ON succession_planning(priority_level);
CREATE INDEX idx_succession_planning_status ON succession_planning(plan_status);
CREATE INDEX idx_succession_planning_review ON succession_planning(next_review_date);
CREATE INDEX idx_succession_planning_activation ON succession_planning(activation_date);
CREATE INDEX idx_succession_planning_competencies ON succession_planning USING GIN(required_competencies);

-- =====================================================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- Enhanced organizational hierarchy view
CREATE OR REPLACE VIEW v_organization_hierarchy_enhanced AS
WITH RECURSIVE org_tree AS (
    SELECT 
        oh.hierarchy_id,
        oh.organization_unit_id,
        oh.parent_unit_id,
        oh.unit_type,
        oh.unit_code,
        oh.unit_name,
        oh.materialized_path,
        oh.hierarchy_level,
        oh.operational_status,
        oh.current_employee_count,
        oh.employee_capacity,
        lm.location_name,
        lm.city,
        lm.country_name,
        lm.time_zone,
        0 as depth
    FROM organization_hierarchy oh
    LEFT JOIN location_management lm ON oh.organization_unit_id = lm.organization_unit_id
    WHERE oh.parent_unit_id IS NULL
    AND oh.operational_status = 'active'
    
    UNION ALL
    
    SELECT 
        oh.hierarchy_id,
        oh.organization_unit_id,
        oh.parent_unit_id,
        oh.unit_type,
        oh.unit_code,
        oh.unit_name,
        oh.materialized_path,
        oh.hierarchy_level,
        oh.operational_status,
        oh.current_employee_count,
        oh.employee_capacity,
        lm.location_name,
        lm.city,
        lm.country_name,
        lm.time_zone,
        ot.depth + 1
    FROM organization_hierarchy oh
    JOIN org_tree ot ON oh.parent_unit_id = ot.organization_unit_id
    LEFT JOIN location_management lm ON oh.organization_unit_id = lm.organization_unit_id
    WHERE oh.operational_status = 'active'
)
SELECT * FROM org_tree
ORDER BY materialized_path;

-- Employee permissions with delegation view
CREATE OR REPLACE VIEW v_employee_permissions_with_delegation AS
SELECT DISTINCT
    e.employee_id,
    e.full_name,
    p.permission_code,
    p.permission_name,
    p.permission_group,
    CASE 
        WHEN era.assignment_id IS NOT NULL THEN 'direct'
        WHEN dr.delegation_id IS NOT NULL THEN 'delegated'
        ELSE 'inherited'
    END as permission_source,
    COALESCE(era.organization_unit_id, dr.delegator_id) as scope_reference,
    CASE 
        WHEN era.assignment_id IS NOT NULL THEN era.valid_until
        WHEN dr.delegation_id IS NOT NULL THEN dr.end_date::DATE
        ELSE NULL
    END as expires_on
FROM employees e
-- Direct role assignments
LEFT JOIN role_assignments_enhanced era ON e.employee_id = era.employee_id 
    AND era.workflow_state = 'active'
    AND CURRENT_DATE BETWEEN era.valid_from AND COALESCE(era.valid_until, CURRENT_DATE + 1)
LEFT JOIN role_permissions_enhanced rpe ON era.role_id = rpe.role_id
    AND rpe.revoked_at IS NULL
    AND CURRENT_DATE BETWEEN rpe.effective_from AND COALESCE(rpe.effective_until, CURRENT_DATE + 1)
LEFT JOIN permissions p ON rpe.permission_id = p.permission_id
-- Delegated permissions
LEFT JOIN delegation_rules_enhanced dr ON e.employee_id = dr.delegate_id
    AND NOW() BETWEEN dr.start_date AND dr.end_date
LEFT JOIN permissions p2 ON p2.permission_code = ANY(dr.specific_permissions)
WHERE e.is_active = TRUE
AND (p.permission_code IS NOT NULL OR p2.permission_code IS NOT NULL);

-- Active succession plans dashboard
CREATE OR REPLACE VIEW v_succession_plans_dashboard AS
SELECT 
    sp.plan_code,
    sp.plan_name,
    sp.plan_type,
    sp.succession_scenario,
    sp.priority_level,
    sp.plan_status,
    sp.timeline_type,
    oh.unit_name as target_unit,
    pos.position_name as target_position,
    e.full_name as target_employee,
    sp.next_review_date,
    CASE 
        WHEN sp.next_review_date < CURRENT_DATE THEN 'overdue'
        WHEN sp.next_review_date <= CURRENT_DATE + 30 THEN 'due_soon'
        ELSE 'current'
    END as review_status,
    jsonb_array_length(sp.succession_candidates) as candidate_count,
    jsonb_array_length(sp.required_competencies) as required_competencies_count
FROM succession_planning sp
LEFT JOIN organization_hierarchy oh ON sp.organization_unit_id = oh.organization_unit_id
LEFT JOIN positions pos ON sp.target_position_id = pos.position_id
LEFT JOIN employees e ON sp.target_employee_id = e.employee_id
WHERE sp.plan_status IN ('approved', 'active')
ORDER BY sp.priority_level DESC, sp.next_review_date ASC;

-- Competency gap analysis view
CREATE OR REPLACE VIEW v_competency_gap_analysis AS
SELECT 
    e.employee_id,
    e.full_name,
    cf.competency_code,
    cf.competency_name,
    cf.competency_type,
    cf.competency_category,
    cf.criticality_level,
    -- This would need to be populated from employee assessments
    -- Placeholder for actual competency levels
    NULL as current_level,
    NULL as required_level,
    NULL as gap_severity,
    cf.development_timeframe_months,
    cf.development_activities
FROM employees e
CROSS JOIN competency_framework cf
WHERE e.is_active = TRUE
AND cf.approval_status = 'published'
AND cf.effective_from <= CURRENT_DATE
AND (cf.effective_until IS NULL OR cf.effective_until > CURRENT_DATE);

-- =====================================================================================
-- TRIGGERS AND FUNCTIONS
-- =====================================================================================

-- Function to update organization hierarchy materialized path
CREATE OR REPLACE FUNCTION update_organization_hierarchy_path()
RETURNS TRIGGER AS $$
DECLARE
    v_parent_path TEXT;
    v_parent_level INTEGER;
BEGIN
    IF NEW.parent_unit_id IS NULL THEN
        NEW.materialized_path := '/' || NEW.organization_unit_id || '/';
        NEW.hierarchy_level := 0;
    ELSE
        SELECT materialized_path, hierarchy_level 
        INTO v_parent_path, v_parent_level
        FROM organization_hierarchy 
        WHERE organization_unit_id = NEW.parent_unit_id;
        
        IF v_parent_path IS NULL THEN
            RAISE EXCEPTION 'Parent organization unit % not found', NEW.parent_unit_id;
        END IF;
        
        NEW.materialized_path := v_parent_path || NEW.organization_unit_id || '/';
        NEW.hierarchy_level := v_parent_level + 1;
        
        -- Check for circular reference
        IF NEW.materialized_path LIKE '%/' || NEW.organization_unit_id || '/%' THEN
            RAISE EXCEPTION 'Circular reference detected in organization hierarchy';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER maintain_organization_hierarchy_path
    BEFORE INSERT OR UPDATE OF parent_unit_id ON organization_hierarchy
    FOR EACH ROW EXECUTE FUNCTION update_organization_hierarchy_path();

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_event_type VARCHAR,
    p_event_category VARCHAR,
    p_actor_id INTEGER,
    p_action_performed VARCHAR,
    p_target_table VARCHAR DEFAULT NULL,
    p_target_id INTEGER DEFAULT NULL,
    p_data_before JSONB DEFAULT NULL,
    p_data_after JSONB DEFAULT NULL,
    p_severity VARCHAR DEFAULT 'info'
) RETURNS UUID AS $$
DECLARE
    v_audit_uuid UUID;
BEGIN
    INSERT INTO audit_logs_comprehensive (
        event_type, event_category, actor_id, action_performed,
        target_table, target_id, data_before, data_after, severity_level
    ) VALUES (
        p_event_type, p_event_category, p_actor_id, p_action_performed,
        p_target_table, p_target_id, p_data_before, p_data_after, p_severity
    ) RETURNING audit_uuid INTO v_audit_uuid;
    
    RETURN v_audit_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to check delegation authority
CREATE OR REPLACE FUNCTION check_delegation_authority(
    p_delegator_id INTEGER,
    p_delegate_id INTEGER,
    p_permission_codes TEXT[],
    p_organization_unit_id INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_authority BOOLEAN := FALSE;
    v_permission TEXT;
BEGIN
    -- Check if delegator has the permissions they want to delegate
    FOREACH v_permission IN ARRAY p_permission_codes
    LOOP
        SELECT EXISTS (
            SELECT 1 FROM v_employee_permissions_with_delegation
            WHERE employee_id = p_delegator_id
            AND permission_code = v_permission
            AND permission_source = 'direct'
        ) INTO v_has_authority;
        
        IF NOT v_has_authority THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    -- Log the delegation check
    PERFORM log_audit_event(
        'DELEGATION_CHECK',
        'ACCESS_CONTROL',
        p_delegator_id,
        'Checked delegation authority for ' || array_to_string(p_permission_codes, ', '),
        'delegation_rules_enhanced',
        NULL,
        NULL,
        jsonb_build_object(
            'delegate_id', p_delegate_id,
            'permissions', p_permission_codes,
            'organization_unit_id', p_organization_unit_id,
            'result', TRUE
        )
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate competency coverage
CREATE OR REPLACE FUNCTION calculate_competency_coverage(
    p_organization_unit_id INTEGER DEFAULT NULL,
    p_competency_type VARCHAR DEFAULT NULL
) RETURNS TABLE (
    competency_code VARCHAR,
    competency_name VARCHAR,
    required_employees INTEGER,
    qualified_employees INTEGER,
    coverage_percentage DECIMAL,
    risk_level VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cf.competency_code,
        cf.competency_name,
        -- This would need actual employee competency assessments
        -- Placeholder logic
        CASE 
            WHEN p_organization_unit_id IS NOT NULL THEN 
                (SELECT current_employee_count FROM organization_hierarchy WHERE organization_unit_id = p_organization_unit_id)
            ELSE 100
        END as required_employees,
        0 as qualified_employees, -- Placeholder
        0.0 as coverage_percentage, -- Placeholder
        CASE 
            WHEN 0 < 50 THEN 'high'
            WHEN 0 < 80 THEN 'medium'
            ELSE 'low'
        END as risk_level
    FROM competency_framework cf
    WHERE cf.approval_status = 'published'
    AND (p_competency_type IS NULL OR cf.competency_type = p_competency_type)
    ORDER BY cf.criticality_level DESC, cf.competency_name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SAMPLE DATA GENERATORS
-- =====================================================================================

-- Function to generate sample organization hierarchy
CREATE OR REPLACE FUNCTION generate_sample_organization_data()
RETURNS VOID AS $$
BEGIN
    -- Insert sample organization units
    INSERT INTO organization_hierarchy (
        organization_unit_id, unit_code, unit_name, unit_type, 
        parent_unit_id, business_unit_type, created_by
    ) VALUES
    (1, 'ENTERPRISE', 'Enterprise Holdings', 'enterprise', NULL, 'strategic', 1),
    (2, 'CORP', 'Corporate Division', 'division', 1, 'strategic', 1),
    (3, 'OPS', 'Operations Division', 'division', 1, 'operational', 1),
    (4, 'SUPPORT', 'Support Services', 'division', 1, 'support', 1),
    (5, 'REGION_MSK', 'Moscow Region', 'region', 3, 'operational', 1),
    (6, 'REGION_SPB', 'St. Petersburg Region', 'region', 3, 'operational', 1),
    (7, 'CC_MSK_01', 'Moscow Call Center 1', 'site', 5, 'operational', 1),
    (8, 'CC_MSK_02', 'Moscow Call Center 2', 'site', 5, 'operational', 1),
    (9, 'CC_SPB_01', 'St. Petersburg Call Center', 'site', 6, 'operational', 1),
    (10, 'TEAM_MSK_01_A', 'Moscow Team Alpha', 'team', 7, 'operational', 1)
    ON CONFLICT (organization_unit_id) DO NOTHING;
    
    -- Insert sample locations
    INSERT INTO location_management (
        location_code, location_name, location_type, organization_unit_id,
        city, country_code, time_zone, capacity_total_seats, created_by
    ) VALUES
    ('MSK_HQ', 'Moscow Headquarters', 'headquarters', 2, 'Moscow', 'RUS', 'Europe/Moscow', 500, 1),
    ('MSK_CC_01', 'Moscow Call Center 1', 'call_center', 7, 'Moscow', 'RUS', 'Europe/Moscow', 200, 1),
    ('MSK_CC_02', 'Moscow Call Center 2', 'call_center', 8, 'Moscow', 'RUS', 'Europe/Moscow', 150, 1),
    ('SPB_CC_01', 'St. Petersburg Call Center', 'call_center', 9, 'St. Petersburg', 'RUS', 'Europe/Moscow', 180, 1)
    ON CONFLICT (location_code) DO NOTHING;
    
    -- Insert sample competencies
    INSERT INTO competency_framework (
        competency_code, competency_name, competency_type, competency_category,
        criticality_level, development_timeframe_months, created_by
    ) VALUES
    ('CUST_SERVICE', 'Customer Service Excellence', 'core', 'Customer Relations', 'critical', 3, 1),
    ('PHONE_ETIQUETTE', 'Phone Communication Skills', 'functional', 'Communication', 'high', 1, 1),
    ('CONFLICT_RESOLUTION', 'Conflict Resolution', 'behavioral', 'Soft Skills', 'high', 6, 1),
    ('CRM_SYSTEM', 'CRM System Proficiency', 'technical', 'Software Systems', 'medium', 2, 1),
    ('TEAM_LEADERSHIP', 'Team Leadership', 'leadership', 'Management', 'critical', 12, 1)
    ON CONFLICT (competency_code) DO NOTHING;
    
    RAISE NOTICE 'Sample organization data generated successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample team structures
CREATE OR REPLACE FUNCTION generate_sample_team_data()
RETURNS VOID AS $$
BEGIN
    INSERT INTO team_structures (
        team_code, team_name, team_type, organization_unit_id,
        min_team_size, max_team_size, target_team_size, created_by
    ) VALUES
    ('ALPHA_TEAM', 'Alpha Customer Service Team', 'permanent', 7, 8, 12, 10, 1),
    ('BETA_TEAM', 'Beta Technical Support Team', 'permanent', 7, 6, 10, 8, 1),
    ('GAMMA_SQUAD', 'Gamma Sales Squad', 'squad', 8, 5, 8, 6, 1),
    ('DELTA_PROJECT', 'Delta Innovation Project', 'project', 2, 3, 6, 5, 1)
    ON CONFLICT (team_code) DO NOTHING;
    
    RAISE NOTICE 'Sample team data generated successfully';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SECURITY POLICIES
-- =====================================================================================

-- Enable row-level security on sensitive tables
ALTER TABLE role_assignments_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs_comprehensive ENABLE ROW LEVEL SECURITY;
ALTER TABLE succession_planning ENABLE ROW LEVEL SECURITY;
ALTER TABLE competency_framework ENABLE ROW LEVEL SECURITY;

-- Create policies for organization settings
CREATE POLICY organization_settings_policy ON organization_settings
    FOR ALL TO authenticated_users
    USING (
        EXISTS (
            SELECT 1 FROM v_employee_permissions_with_delegation
            WHERE employee_id = current_user_id()
            AND permission_code = 'org.manage_settings'
        )
    );

-- =====================================================================================
-- PERFORMANCE OPTIMIZATIONS
-- =====================================================================================

-- Partial indexes for better performance
CREATE INDEX idx_role_assignments_active ON role_assignments_enhanced(employee_id, role_id) 
    WHERE workflow_state = 'active';

CREATE INDEX idx_audit_logs_recent ON audit_logs_comprehensive(event_timestamp DESC) 
    WHERE event_timestamp > NOW() - INTERVAL '90 days';

CREATE INDEX idx_succession_plans_critical ON succession_planning(plan_status, priority_level) 
    WHERE plan_status IN ('approved', 'active') AND priority_level IN ('critical', 'high');

-- =====================================================================================
-- FINAL SETUP AND CONSTRAINTS
-- =====================================================================================

-- Add foreign key constraints to existing tables if they don't exist
DO $$
BEGIN
    -- Add organization_unit_id to employees table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'employees' AND column_name = 'organization_unit_id') THEN
        ALTER TABLE employees ADD COLUMN organization_unit_id INTEGER 
            REFERENCES organization_hierarchy(organization_unit_id);
    END IF;
    
    -- Add team_id to employees table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'employees' AND column_name = 'team_id') THEN
        ALTER TABLE employees ADD COLUMN team_id INTEGER 
            REFERENCES team_structures(team_id);
    END IF;
END $$;

-- Add table comments for documentation
COMMENT ON TABLE organization_hierarchy IS 'Enhanced multi-level organizational structure with enterprise features';
COMMENT ON TABLE role_permissions_enhanced IS 'Granular permission system with advanced scoping and conditions';
COMMENT ON TABLE role_assignments_enhanced IS 'Dynamic role assignments with workflow management';
COMMENT ON TABLE delegation_rules_enhanced IS 'Advanced delegation system with conditional rules';
COMMENT ON TABLE access_policies IS 'Row-level security policies and data access controls';
COMMENT ON TABLE audit_logs_comprehensive IS 'Comprehensive audit trail with enterprise-grade logging';
COMMENT ON TABLE organization_settings IS 'Configurable organizational settings and parameters';
COMMENT ON TABLE location_management IS 'Multi-site location management with detailed facility information';
COMMENT ON TABLE team_structures IS 'Team and squad management with agile methodology support';
COMMENT ON TABLE reporting_relationships IS 'Manager chains and reporting structures';
COMMENT ON TABLE competency_framework IS 'Skills and competency management framework';
COMMENT ON TABLE succession_planning IS 'Succession planning and backup management';

-- Generate sample data
SELECT generate_sample_organization_data();
SELECT generate_sample_team_data();

COMMIT;

-- =====================================================================================
-- USAGE EXAMPLES AND DOCUMENTATION
-- =====================================================================================

/*
USAGE EXAMPLES:

1. Create an organization unit:
INSERT INTO organization_hierarchy (organization_unit_id, unit_code, unit_name, unit_type, parent_unit_id, created_by)
VALUES (100, 'NEW_DEPT', 'New Department', 'department', 3, 1);

2. Assign enhanced role with conditions:
INSERT INTO role_assignments_enhanced (employee_id, role_id, organization_unit_id, assignment_type, assigned_by)
VALUES (1001, 5, 100, 'permanent', 1);

3. Create delegation rule:
INSERT INTO delegation_rules_enhanced (
    delegation_name, delegator_id, delegate_id, delegation_type, 
    start_date, end_date, created_by
) VALUES (
    'Vacation Coverage', 1001, 1002, 'specific_permissions',
    '2025-08-01', '2025-08-15', 1001
);

4. Add competency to framework:
INSERT INTO competency_framework (competency_code, competency_name, competency_type, competency_category, created_by)
VALUES ('NEW_SKILL', 'New Required Skill', 'technical', 'Software Systems', 1);

5. Create succession plan:
INSERT INTO succession_planning (plan_code, plan_name, target_position_id, plan_type, created_by)
VALUES ('SUCC_001', 'Manager Succession Plan', 10, 'position', 1);

6. Query organization hierarchy:
SELECT * FROM v_organization_hierarchy_enhanced WHERE unit_type = 'department';

7. Check employee permissions:
SELECT * FROM v_employee_permissions_with_delegation WHERE employee_id = 1001;

8. Monitor succession plans:
SELECT * FROM v_succession_plans_dashboard WHERE review_status = 'overdue';
*/