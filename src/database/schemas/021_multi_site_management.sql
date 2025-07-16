-- =============================================================================
-- 021_multi_site_management.sql
-- EXACT BDD Implementation: Multi-Site Management with Cross-Site Rules
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: Multi-site workforce management with cross-site rules and employee mobility
-- Purpose: Comprehensive multi-site management with 500 employees across 5 sites
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SITES
-- =============================================================================

-- Site definitions and management
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id VARCHAR(50) NOT NULL UNIQUE,
    site_name VARCHAR(200) NOT NULL,
    site_description TEXT,
    
    -- Site classification
    site_type VARCHAR(30) NOT NULL CHECK (site_type IN (
        'headquarters', 'regional_office', 'call_center', 'support_center', 
        'branch_office', 'remote_location', 'virtual_site'
    )),
    site_category VARCHAR(30) DEFAULT 'operational' CHECK (site_category IN (
        'operational', 'administrative', 'support', 'hybrid'
    )),
    
    -- Site location and contact
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'Russia',
    
    -- Geographic coordinates for distance calculations
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Site contact information
    primary_phone VARCHAR(50),
    secondary_phone VARCHAR(50),
    email_address VARCHAR(200),
    website_url VARCHAR(500),
    
    -- Site capacity and resources
    total_capacity INTEGER NOT NULL DEFAULT 0,
    current_occupancy INTEGER DEFAULT 0,
    available_workstations INTEGER DEFAULT 0,
    parking_spaces INTEGER DEFAULT 0,
    meeting_rooms INTEGER DEFAULT 0,
    
    -- Site operational details
    time_zone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    business_hours JSONB DEFAULT '{}', -- Operating hours by day
    holiday_calendar VARCHAR(50) DEFAULT 'russia_federal',
    
    -- Site facilities and amenities
    facilities JSONB DEFAULT '[]', -- cafeteria, gym, parking, etc.
    accessibility_features JSONB DEFAULT '[]',
    security_features JSONB DEFAULT '[]',
    technology_infrastructure JSONB DEFAULT '{}',
    
    -- Site management
    site_manager_id UUID,
    hr_contact_id UUID,
    it_contact_id UUID,
    facilities_contact_id UUID,
    
    -- Site financial data
    monthly_operating_cost DECIMAL(12,2),
    cost_center_code VARCHAR(50),
    budget_allocation DECIMAL(12,2),
    
    -- Site status and lifecycle
    site_status VARCHAR(20) DEFAULT 'active' CHECK (site_status IN (
        'planning', 'construction', 'setup', 'active', 'maintenance', 'closing', 'closed'
    )),
    opening_date DATE,
    closing_date DATE,
    
    -- Compliance and certifications
    compliance_certifications JSONB DEFAULT '[]',
    safety_certifications JSONB DEFAULT '[]',
    last_inspection_date DATE,
    next_inspection_due DATE,
    
    -- Site metadata
    is_headquarters BOOLEAN DEFAULT false,
    allows_remote_work BOOLEAN DEFAULT true,
    supports_cross_site_employees BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_manager_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (hr_contact_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (it_contact_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (facilities_contact_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. SITE EMPLOYEES
-- =============================================================================

-- Employee assignments to sites with role and status tracking
CREATE TABLE site_employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Assignment basics
    employee_id UUID NOT NULL,
    site_id VARCHAR(50) NOT NULL,
    
    -- Assignment type and status
    assignment_type VARCHAR(30) NOT NULL CHECK (assignment_type IN (
        'permanent', 'temporary', 'rotating', 'project_based', 'on_demand', 'backup'
    )),
    assignment_status VARCHAR(20) DEFAULT 'active' CHECK (assignment_status IN (
        'active', 'inactive', 'suspended', 'pending', 'transferred', 'terminated'
    )),
    
    -- Assignment period
    assignment_start_date DATE NOT NULL,
    assignment_end_date DATE,
    is_primary_assignment BOOLEAN DEFAULT true,
    
    -- Role at site
    site_role VARCHAR(100),
    reporting_manager_id UUID,
    functional_manager_id UUID,
    
    -- Work arrangement
    work_arrangement VARCHAR(30) DEFAULT 'on_site' CHECK (work_arrangement IN (
        'on_site', 'remote', 'hybrid', 'flexible'
    )),
    workstation_number VARCHAR(50),
    department_at_site VARCHAR(100),
    team_at_site VARCHAR(100),
    
    -- Assignment details
    assignment_percentage DECIMAL(5,2) DEFAULT 100.0, -- % of time at this site
    weekly_hours_at_site DECIMAL(4,1) DEFAULT 40.0,
    preferred_shift VARCHAR(50),
    
    -- Cross-site privileges
    can_work_at_other_sites BOOLEAN DEFAULT false,
    authorized_sites JSONB DEFAULT '[]', -- Other sites employee can work at
    cross_site_approval_required BOOLEAN DEFAULT true,
    
    -- Access and security
    access_card_number VARCHAR(50),
    access_level VARCHAR(30) DEFAULT 'standard',
    security_clearance_level VARCHAR(30),
    authorized_areas JSONB DEFAULT '[]',
    
    -- Emergency information
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(50),
    emergency_contact_relationship VARCHAR(50),
    medical_conditions TEXT,
    
    -- Assignment performance
    performance_rating DECIMAL(3,2),
    last_performance_review DATE,
    performance_notes TEXT,
    
    -- Assignment metadata
    assigned_by UUID,
    assignment_reason TEXT,
    transfer_history JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (reporting_manager_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (functional_manager_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Ensure valid assignment period
    CHECK (assignment_end_date IS NULL OR assignment_end_date >= assignment_start_date),
    -- Ensure assignment percentage is valid
    CHECK (assignment_percentage > 0 AND assignment_percentage <= 100)
);

-- =============================================================================
-- 3. CROSS SITE RULES
-- =============================================================================

-- Rules governing cross-site operations and employee mobility
CREATE TABLE cross_site_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(200) NOT NULL,
    rule_description TEXT,
    
    -- Rule scope and applicability
    rule_type VARCHAR(30) NOT NULL CHECK (rule_type IN (
        'transfer_policy', 'cross_site_work', 'resource_sharing', 'compliance_rule',
        'security_policy', 'cost_allocation', 'performance_standard'
    )),
    rule_category VARCHAR(30) DEFAULT 'operational' CHECK (rule_category IN (
        'operational', 'administrative', 'security', 'financial', 'compliance'
    )),
    
    -- Rule scope
    applies_to_sites JSONB DEFAULT '[]', -- Specific sites or 'all'
    applies_to_employee_types JSONB DEFAULT '[]',
    applies_to_roles JSONB DEFAULT '[]',
    applies_to_departments JSONB DEFAULT '[]',
    
    -- Rule definition
    rule_conditions JSONB NOT NULL, -- When the rule applies
    rule_actions JSONB NOT NULL, -- What actions are required/prohibited
    rule_parameters JSONB DEFAULT '{}', -- Configurable parameters
    
    -- Business logic
    priority_level INTEGER DEFAULT 1 CHECK (priority_level >= 1 AND priority_level <= 10),
    is_mandatory BOOLEAN DEFAULT true,
    allows_exceptions BOOLEAN DEFAULT false,
    exception_approval_required BOOLEAN DEFAULT true,
    
    -- Rule enforcement
    automatic_enforcement BOOLEAN DEFAULT false,
    validation_points JSONB DEFAULT '[]', -- When to check the rule
    enforcement_actions JSONB DEFAULT '{}', -- What to do on violation
    
    -- Rule effectiveness
    effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- Approval and ownership
    rule_owner_id UUID,
    approved_by UUID,
    approval_date DATE,
    
    -- Rule status
    rule_status VARCHAR(20) DEFAULT 'draft' CHECK (rule_status IN (
        'draft', 'review', 'approved', 'active', 'suspended', 'retired'
    )),
    
    -- Compliance tracking
    violation_count INTEGER DEFAULT 0,
    last_violation_date DATE,
    exception_count INTEGER DEFAULT 0,
    last_exception_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (rule_owner_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 4. SITE RELATIONSHIPS
-- =============================================================================

-- Relationships and hierarchies between sites
CREATE TABLE site_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Relationship definition
    parent_site_id VARCHAR(50) NOT NULL,
    child_site_id VARCHAR(50) NOT NULL,
    relationship_type VARCHAR(30) NOT NULL CHECK (relationship_type IN (
        'hierarchical', 'partnership', 'support', 'backup', 'resource_sharing'
    )),
    
    -- Relationship details
    relationship_description TEXT,
    relationship_strength VARCHAR(20) DEFAULT 'medium' CHECK (relationship_strength IN (
        'weak', 'medium', 'strong', 'critical'
    )),
    
    -- Operational aspects
    allows_employee_transfer BOOLEAN DEFAULT true,
    allows_resource_sharing BOOLEAN DEFAULT false,
    shared_services JSONB DEFAULT '[]',
    communication_protocols JSONB DEFAULT '{}',
    
    -- Financial arrangements
    cost_sharing_model VARCHAR(30),
    resource_allocation_rules JSONB DEFAULT '{}',
    billing_arrangements JSONB DEFAULT '{}',
    
    -- Relationship status
    relationship_status VARCHAR(20) DEFAULT 'active' CHECK (relationship_status IN (
        'active', 'inactive', 'pending', 'terminated'
    )),
    effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- Management
    relationship_owner_id UUID,
    primary_contact_parent UUID,
    primary_contact_child UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (child_site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (relationship_owner_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (primary_contact_parent) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (primary_contact_child) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Prevent self-relationships
    CHECK (parent_site_id != child_site_id)
);

-- =============================================================================
-- 5. SITE RESOURCES
-- =============================================================================

-- Site resources and capacity management
CREATE TABLE site_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_id VARCHAR(50) NOT NULL UNIQUE,
    site_id VARCHAR(50) NOT NULL,
    
    -- Resource identification
    resource_name VARCHAR(200) NOT NULL,
    resource_type VARCHAR(30) NOT NULL CHECK (resource_type IN (
        'workstation', 'meeting_room', 'equipment', 'facility', 'system', 'service'
    )),
    resource_category VARCHAR(50),
    
    -- Resource details
    resource_description TEXT,
    capacity INTEGER DEFAULT 1,
    current_utilization INTEGER DEFAULT 0,
    location_within_site VARCHAR(200),
    
    -- Resource availability
    availability_schedule JSONB DEFAULT '{}', -- When resource is available
    booking_required BOOLEAN DEFAULT false,
    advance_booking_days INTEGER DEFAULT 0,
    
    -- Resource specifications
    technical_specifications JSONB DEFAULT '{}',
    access_requirements JSONB DEFAULT '[]',
    usage_restrictions JSONB DEFAULT '[]',
    
    -- Resource management
    resource_owner_id UUID,
    primary_contact_id UUID,
    maintenance_contact_id UUID,
    
    -- Resource status
    resource_status VARCHAR(20) DEFAULT 'available' CHECK (resource_status IN (
        'available', 'occupied', 'maintenance', 'out_of_order', 'retired'
    )),
    
    -- Cost and billing
    hourly_cost DECIMAL(8,2),
    daily_cost DECIMAL(8,2),
    monthly_cost DECIMAL(10,2),
    cost_center_code VARCHAR(50),
    
    -- Usage tracking
    total_usage_hours DECIMAL(10,2) DEFAULT 0,
    utilization_percentage DECIMAL(5,2) DEFAULT 0,
    last_used_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_owner_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (primary_contact_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (maintenance_contact_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. CROSS SITE TRANSFERS
-- =============================================================================

-- Employee transfers between sites
CREATE TABLE cross_site_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Transfer basics
    employee_id UUID NOT NULL,
    source_site_id VARCHAR(50) NOT NULL,
    target_site_id VARCHAR(50) NOT NULL,
    
    -- Transfer type and timing
    transfer_type VARCHAR(30) NOT NULL CHECK (transfer_type IN (
        'permanent', 'temporary', 'project_based', 'emergency', 'voluntary', 'involuntary'
    )),
    transfer_reason VARCHAR(100) NOT NULL,
    
    -- Transfer timeline
    transfer_requested_date DATE NOT NULL DEFAULT CURRENT_DATE,
    planned_transfer_date DATE NOT NULL,
    actual_transfer_date DATE,
    expected_return_date DATE, -- For temporary transfers
    
    -- Transfer approval
    transfer_status VARCHAR(20) DEFAULT 'requested' CHECK (transfer_status IN (
        'requested', 'approved', 'in_progress', 'completed', 'cancelled', 'rejected'
    )),
    requested_by UUID NOT NULL,
    approved_by UUID,
    approval_date DATE,
    
    -- Transfer details
    new_role_at_target VARCHAR(100),
    reporting_manager_at_target UUID,
    cost_center_change BOOLEAN DEFAULT false,
    salary_adjustment DECIMAL(10,2) DEFAULT 0,
    
    -- Logistics and support
    relocation_required BOOLEAN DEFAULT false,
    relocation_assistance_provided BOOLEAN DEFAULT false,
    temporary_accommodation BOOLEAN DEFAULT false,
    travel_arrangements JSONB DEFAULT '{}',
    
    -- Impact assessment
    business_impact_assessment TEXT,
    skills_gap_analysis JSONB DEFAULT '{}',
    replacement_plan TEXT,
    knowledge_transfer_plan TEXT,
    
    -- Transfer completion
    transfer_completion_notes TEXT,
    onboarding_completed BOOLEAN DEFAULT false,
    performance_review_scheduled BOOLEAN DEFAULT false,
    
    -- Financial impact
    transfer_cost DECIMAL(10,2),
    cost_allocation JSONB DEFAULT '{}',
    budget_approval_required BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (source_site_id) REFERENCES sites(site_id) ON DELETE RESTRICT,
    FOREIGN KEY (target_site_id) REFERENCES sites(site_id) ON DELETE RESTRICT,
    FOREIGN KEY (requested_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (reporting_manager_at_target) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Prevent transfers to same site
    CHECK (source_site_id != target_site_id)
);

-- =============================================================================
-- 7. SITE PERFORMANCE METRICS
-- =============================================================================

-- Performance metrics and KPIs for sites
CREATE TABLE site_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id VARCHAR(50) NOT NULL UNIQUE,
    site_id VARCHAR(50) NOT NULL,
    
    -- Measurement period
    measurement_date DATE NOT NULL,
    measurement_period VARCHAR(20) NOT NULL CHECK (measurement_period IN (
        'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
    )),
    
    -- Operational metrics
    total_employees INTEGER DEFAULT 0,
    active_employees INTEGER DEFAULT 0,
    employee_turnover_rate DECIMAL(5,2),
    absenteeism_rate DECIMAL(5,2),
    overtime_hours DECIMAL(10,2),
    
    -- Capacity metrics
    workstation_utilization DECIMAL(5,2),
    meeting_room_utilization DECIMAL(5,2),
    capacity_utilization DECIMAL(5,2),
    resource_efficiency DECIMAL(5,2),
    
    -- Financial metrics
    operating_cost DECIMAL(12,2),
    cost_per_employee DECIMAL(10,2),
    revenue_per_employee DECIMAL(10,2),
    budget_variance_percentage DECIMAL(5,2),
    
    -- Quality metrics
    employee_satisfaction_score DECIMAL(3,2),
    customer_satisfaction_score DECIMAL(3,2),
    safety_incident_count INTEGER DEFAULT 0,
    compliance_score DECIMAL(3,2),
    
    -- Performance indicators
    productivity_index DECIMAL(5,2),
    quality_index DECIMAL(5,2),
    efficiency_index DECIMAL(5,2),
    overall_performance_score DECIMAL(3,2),
    
    -- Comparative metrics
    benchmark_comparison JSONB DEFAULT '{}',
    year_over_year_change DECIMAL(5,2),
    target_achievement_percentage DECIMAL(5,2),
    
    -- Additional metrics
    technology_adoption_rate DECIMAL(5,2),
    training_hours_per_employee DECIMAL(6,2),
    innovation_index DECIMAL(3,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_id) REFERENCES sites(site_id) ON DELETE CASCADE
);

-- =============================================================================
-- 8. SITE COMMUNICATIONS
-- =============================================================================

-- Communications and announcements for sites
CREATE TABLE site_communications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    communication_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Communication basics
    communication_type VARCHAR(30) NOT NULL CHECK (communication_type IN (
        'announcement', 'policy_update', 'emergency_notice', 'event_notification', 
        'training_notice', 'system_update', 'general_information'
    )),
    communication_priority VARCHAR(20) DEFAULT 'medium' CHECK (communication_priority IN (
        'low', 'medium', 'high', 'urgent', 'critical'
    )),
    
    -- Communication content
    subject VARCHAR(200) NOT NULL,
    message_content TEXT NOT NULL,
    additional_details JSONB DEFAULT '{}',
    attachments JSONB DEFAULT '[]',
    
    -- Communication scope
    target_sites JSONB NOT NULL, -- Which sites receive this communication
    target_employee_groups JSONB DEFAULT '[]',
    target_roles JSONB DEFAULT '[]',
    target_departments JSONB DEFAULT '[]',
    
    -- Communication scheduling
    publish_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP WITH TIME ZONE,
    is_scheduled BOOLEAN DEFAULT false,
    
    -- Communication channels
    delivery_channels JSONB DEFAULT '["email", "intranet"]',
    requires_acknowledgment BOOLEAN DEFAULT false,
    acknowledgment_deadline TIMESTAMP WITH TIME ZONE,
    
    -- Communication status
    communication_status VARCHAR(20) DEFAULT 'draft' CHECK (communication_status IN (
        'draft', 'approved', 'published', 'expired', 'cancelled'
    )),
    
    -- Communication tracking
    total_recipients INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    messages_delivered INTEGER DEFAULT 0,
    acknowledgments_received INTEGER DEFAULT 0,
    
    -- Communication metadata
    created_by UUID NOT NULL,
    approved_by UUID,
    approval_required BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 9. SITE COMPLIANCE TRACKING
-- =============================================================================

-- Compliance tracking for sites across various regulations
CREATE TABLE site_compliance_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compliance_id VARCHAR(50) NOT NULL UNIQUE,
    site_id VARCHAR(50) NOT NULL,
    
    -- Compliance requirement
    compliance_type VARCHAR(30) NOT NULL CHECK (compliance_type IN (
        'safety', 'environmental', 'labor_law', 'data_protection', 'building_code',
        'fire_safety', 'accessibility', 'industry_specific'
    )),
    regulation_name VARCHAR(200) NOT NULL,
    regulation_reference VARCHAR(100),
    
    -- Compliance status
    compliance_status VARCHAR(20) NOT NULL CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'partially_compliant', 'under_review', 'not_applicable'
    )),
    last_assessment_date DATE,
    next_assessment_due DATE,
    
    -- Assessment details
    assessment_method VARCHAR(50),
    assessor_name VARCHAR(200),
    assessment_score DECIMAL(5,2),
    compliance_percentage DECIMAL(5,2),
    
    -- Non-compliance details
    violations_identified JSONB DEFAULT '[]',
    corrective_actions_required JSONB DEFAULT '[]',
    corrective_actions_completed JSONB DEFAULT '[]',
    
    -- Timeline and deadlines
    compliance_deadline DATE,
    remediation_deadline DATE,
    final_compliance_date DATE,
    
    -- Documentation
    assessment_report_url VARCHAR(500),
    supporting_documents JSONB DEFAULT '[]',
    certifications JSONB DEFAULT '[]',
    
    -- Responsible parties
    compliance_officer_id UUID,
    site_contact_id UUID,
    external_assessor VARCHAR(200),
    
    -- Risk and impact
    risk_level VARCHAR(20) DEFAULT 'medium' CHECK (risk_level IN (
        'low', 'medium', 'high', 'critical'
    )),
    potential_penalties DECIMAL(12,2),
    business_impact_assessment TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (compliance_officer_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (site_contact_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 10. SITE EMERGENCY PROCEDURES
-- =============================================================================

-- Emergency procedures and contact information for sites
CREATE TABLE site_emergency_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procedure_id VARCHAR(50) NOT NULL UNIQUE,
    site_id VARCHAR(50) NOT NULL,
    
    -- Emergency type and classification
    emergency_type VARCHAR(30) NOT NULL CHECK (emergency_type IN (
        'fire', 'medical', 'security', 'natural_disaster', 'power_outage', 
        'system_failure', 'evacuation', 'lockdown', 'chemical_spill'
    )),
    severity_level VARCHAR(20) NOT NULL CHECK (severity_level IN (
        'low', 'medium', 'high', 'critical'
    )),
    
    -- Procedure details
    procedure_name VARCHAR(200) NOT NULL,
    procedure_description TEXT NOT NULL,
    step_by_step_instructions JSONB NOT NULL,
    
    -- Activation and notification
    activation_criteria JSONB DEFAULT '{}',
    notification_procedures JSONB DEFAULT '{}',
    escalation_procedures JSONB DEFAULT '{}',
    
    -- Emergency contacts
    primary_emergency_contact VARCHAR(200),
    primary_contact_phone VARCHAR(50),
    secondary_emergency_contact VARCHAR(200),
    secondary_contact_phone VARCHAR(50),
    external_emergency_services JSONB DEFAULT '{}',
    
    -- Resource requirements
    required_equipment JSONB DEFAULT '[]',
    required_personnel JSONB DEFAULT '[]',
    assembly_points JSONB DEFAULT '[]',
    evacuation_routes JSONB DEFAULT '[]',
    
    -- Communication protocols
    internal_communication_methods JSONB DEFAULT '[]',
    external_communication_methods JSONB DEFAULT '[]',
    media_communication_protocol TEXT,
    
    -- Recovery procedures
    damage_assessment_procedures JSONB DEFAULT '{}',
    business_continuity_procedures JSONB DEFAULT '{}',
    recovery_timeline JSONB DEFAULT '{}',
    
    -- Training and drills
    training_requirements JSONB DEFAULT '[]',
    drill_frequency VARCHAR(50),
    last_drill_date DATE,
    next_drill_scheduled DATE,
    
    -- Procedure status
    procedure_status VARCHAR(20) DEFAULT 'active' CHECK (procedure_status IN (
        'active', 'inactive', 'under_review', 'outdated'
    )),
    last_review_date DATE,
    next_review_due DATE,
    
    -- Responsibility and approval
    procedure_owner_id UUID,
    approved_by UUID,
    approval_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (site_id) REFERENCES sites(site_id) ON DELETE CASCADE,
    FOREIGN KEY (procedure_owner_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Sites queries
CREATE INDEX idx_sites_type ON sites(site_type);
CREATE INDEX idx_sites_status ON sites(site_status);
CREATE INDEX idx_sites_city ON sites(city);
CREATE INDEX idx_sites_country ON sites(country);
CREATE INDEX idx_sites_manager ON sites(site_manager_id);
CREATE INDEX idx_sites_active ON sites(site_status) WHERE site_status = 'active';

-- Site employees queries
CREATE INDEX idx_site_employees_employee ON site_employees(employee_id);
CREATE INDEX idx_site_employees_site ON site_employees(site_id);
CREATE INDEX idx_site_employees_status ON site_employees(assignment_status);
CREATE INDEX idx_site_employees_primary ON site_employees(is_primary_assignment) WHERE is_primary_assignment = true;
CREATE INDEX idx_site_employees_dates ON site_employees(assignment_start_date, assignment_end_date);
CREATE INDEX idx_site_employees_manager ON site_employees(reporting_manager_id);

-- Cross site rules queries
CREATE INDEX idx_cross_site_rules_type ON cross_site_rules(rule_type);
CREATE INDEX idx_cross_site_rules_status ON cross_site_rules(rule_status);
CREATE INDEX idx_cross_site_rules_priority ON cross_site_rules(priority_level);
CREATE INDEX idx_cross_site_rules_effective ON cross_site_rules(effective_start_date, effective_end_date);
CREATE INDEX idx_cross_site_rules_owner ON cross_site_rules(rule_owner_id);

-- Site relationships queries
CREATE INDEX idx_site_relationships_parent ON site_relationships(parent_site_id);
CREATE INDEX idx_site_relationships_child ON site_relationships(child_site_id);
CREATE INDEX idx_site_relationships_type ON site_relationships(relationship_type);
CREATE INDEX idx_site_relationships_status ON site_relationships(relationship_status);

-- Site resources queries
CREATE INDEX idx_site_resources_site ON site_resources(site_id);
CREATE INDEX idx_site_resources_type ON site_resources(resource_type);
CREATE INDEX idx_site_resources_status ON site_resources(resource_status);
CREATE INDEX idx_site_resources_available ON site_resources(resource_status) WHERE resource_status = 'available';

-- Cross site transfers queries
CREATE INDEX idx_cross_site_transfers_employee ON cross_site_transfers(employee_id);
CREATE INDEX idx_cross_site_transfers_source ON cross_site_transfers(source_site_id);
CREATE INDEX idx_cross_site_transfers_target ON cross_site_transfers(target_site_id);
CREATE INDEX idx_cross_site_transfers_status ON cross_site_transfers(transfer_status);
CREATE INDEX idx_cross_site_transfers_date ON cross_site_transfers(planned_transfer_date);
CREATE INDEX idx_cross_site_transfers_requested_by ON cross_site_transfers(requested_by);

-- Site performance metrics queries
CREATE INDEX idx_site_performance_metrics_site ON site_performance_metrics(site_id);
CREATE INDEX idx_site_performance_metrics_date ON site_performance_metrics(measurement_date);
CREATE INDEX idx_site_performance_metrics_period ON site_performance_metrics(measurement_period);

-- Site communications queries
CREATE INDEX idx_site_communications_type ON site_communications(communication_type);
CREATE INDEX idx_site_communications_priority ON site_communications(communication_priority);
CREATE INDEX idx_site_communications_status ON site_communications(communication_status);
CREATE INDEX idx_site_communications_publish ON site_communications(publish_date);
CREATE INDEX idx_site_communications_created_by ON site_communications(created_by);

-- Site compliance tracking queries
CREATE INDEX idx_site_compliance_tracking_site ON site_compliance_tracking(site_id);
CREATE INDEX idx_site_compliance_tracking_type ON site_compliance_tracking(compliance_type);
CREATE INDEX idx_site_compliance_tracking_status ON site_compliance_tracking(compliance_status);
CREATE INDEX idx_site_compliance_tracking_risk ON site_compliance_tracking(risk_level);
CREATE INDEX idx_site_compliance_tracking_assessment ON site_compliance_tracking(next_assessment_due);

-- Site emergency procedures queries
CREATE INDEX idx_site_emergency_procedures_site ON site_emergency_procedures(site_id);
CREATE INDEX idx_site_emergency_procedures_type ON site_emergency_procedures(emergency_type);
CREATE INDEX idx_site_emergency_procedures_severity ON site_emergency_procedures(severity_level);
CREATE INDEX idx_site_emergency_procedures_status ON site_emergency_procedures(procedure_status);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_site_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER sites_update_trigger
    BEFORE UPDATE ON sites
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_employees_update_trigger
    BEFORE UPDATE ON site_employees
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER cross_site_rules_update_trigger
    BEFORE UPDATE ON cross_site_rules
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_relationships_update_trigger
    BEFORE UPDATE ON site_relationships
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_resources_update_trigger
    BEFORE UPDATE ON site_resources
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER cross_site_transfers_update_trigger
    BEFORE UPDATE ON cross_site_transfers
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_communications_update_trigger
    BEFORE UPDATE ON site_communications
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_compliance_tracking_update_trigger
    BEFORE UPDATE ON site_compliance_tracking
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

CREATE TRIGGER site_emergency_procedures_update_trigger
    BEFORE UPDATE ON site_emergency_procedures
    FOR EACH ROW EXECUTE FUNCTION update_site_timestamp();

-- Site occupancy calculation trigger
CREATE OR REPLACE FUNCTION calculate_site_occupancy()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sites SET 
        current_occupancy = (
            SELECT COUNT(*) 
            FROM site_employees 
            WHERE site_id = NEW.site_id 
            AND assignment_status = 'active'
        )
    WHERE site_id = NEW.site_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER site_employees_occupancy_trigger
    AFTER INSERT OR UPDATE OR DELETE ON site_employees
    FOR EACH ROW EXECUTE FUNCTION calculate_site_occupancy();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Site summary with employee counts
CREATE VIEW v_site_summary AS
SELECT 
    s.site_id,
    s.site_name,
    s.site_type,
    s.city,
    s.site_status,
    s.total_capacity,
    s.current_occupancy,
    COUNT(se.id) as total_assignments,
    COUNT(CASE WHEN se.assignment_status = 'active' THEN 1 END) as active_assignments,
    COUNT(CASE WHEN se.is_primary_assignment THEN 1 END) as primary_assignments,
    s.site_manager_id,
    e.full_name as site_manager_name
FROM sites s
LEFT JOIN site_employees se ON s.site_id = se.site_id
LEFT JOIN employees e ON s.site_manager_id = e.id
GROUP BY s.site_id, s.site_name, s.site_type, s.city, s.site_status, 
         s.total_capacity, s.current_occupancy, s.site_manager_id, e.full_name
ORDER BY s.site_name;

-- Employee multi-site assignments
CREATE VIEW v_employee_multi_site_assignments AS
SELECT 
    e.id as employee_id,
    e.full_name,
    COUNT(se.id) as total_site_assignments,
    COUNT(CASE WHEN se.assignment_status = 'active' THEN 1 END) as active_assignments,
    STRING_AGG(CASE WHEN se.assignment_status = 'active' THEN s.site_name END, ', ') as active_sites,
    MAX(CASE WHEN se.is_primary_assignment THEN s.site_name END) as primary_site
FROM employees e
LEFT JOIN site_employees se ON e.id = se.employee_id
LEFT JOIN sites s ON se.site_id = s.site_id
GROUP BY e.id, e.full_name
HAVING COUNT(se.id) > 0
ORDER BY total_site_assignments DESC, e.full_name;

-- Cross-site transfer activity summary
CREATE VIEW v_cross_site_transfer_activity AS
SELECT 
    source_site.site_name as source_site,
    target_site.site_name as target_site,
    cst.transfer_type,
    COUNT(*) as total_transfers,
    COUNT(CASE WHEN cst.transfer_status = 'completed' THEN 1 END) as completed_transfers,
    COUNT(CASE WHEN cst.transfer_status = 'in_progress' THEN 1 END) as in_progress_transfers,
    AVG(EXTRACT(DAYS FROM (cst.actual_transfer_date - cst.transfer_requested_date))) as avg_processing_days
FROM cross_site_transfers cst
JOIN sites source_site ON cst.source_site_id = source_site.site_id
JOIN sites target_site ON cst.target_site_id = target_site.site_id
WHERE cst.transfer_requested_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY source_site.site_name, target_site.site_name, cst.transfer_type
ORDER BY total_transfers DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING (5 sites with 500 employees)
-- =============================================================================

-- Insert sample sites
INSERT INTO sites (site_id, site_name, site_type, city, country, total_capacity, time_zone, site_status) VALUES
('moscow_hq', 'Moscow Headquarters', 'headquarters', 'Moscow', 'Russia', 200, 'Europe/Moscow', 'active'),
('spb_office', 'St. Petersburg Office', 'regional_office', 'St. Petersburg', 'Russia', 150, 'Europe/Moscow', 'active'),
('ekb_center', 'Ekaterinburg Call Center', 'call_center', 'Ekaterinburg', 'Russia', 100, 'Asia/Yekaterinburg', 'active'),
('nsk_support', 'Novosibirsk Support Center', 'support_center', 'Novosibirsk', 'Russia', 75, 'Asia/Novosibirsk', 'active'),
('kzn_branch', 'Kazan Branch Office', 'branch_office', 'Kazan', 'Russia', 50, 'Europe/Moscow', 'active');

-- Insert cross-site rules
INSERT INTO cross_site_rules (rule_id, rule_name, rule_type, rule_conditions, rule_actions, priority_level, rule_status) VALUES
('transfer_approval', 'Cross-Site Transfer Approval Required', 'transfer_policy', 
'{"transfer_type": ["permanent", "temporary"], "approval_level": "manager"}',
'{"require_approval": true, "approval_levels": ["direct_manager", "hr_manager"]}',
8, 'active'),
('remote_work_policy', 'Remote Work Authorization Policy', 'cross_site_work',
'{"work_arrangement": "remote", "site_distance": ">100km"}',
'{"require_authorization": true, "max_remote_days": 10}',
6, 'active'),
('emergency_backup', 'Emergency Site Backup Procedures', 'resource_sharing',
'{"emergency_type": ["fire", "natural_disaster"], "site_unavailable": true}',
'{"activate_backup_site": true, "notify_employees": true}',
10, 'active');

-- Insert sample site relationships
INSERT INTO site_relationships (relationship_id, parent_site_id, child_site_id, relationship_type, allows_employee_transfer, allows_resource_sharing) VALUES
('moscow_spb', 'moscow_hq', 'spb_office', 'hierarchical', true, true),
('moscow_ekb', 'moscow_hq', 'ekb_center', 'hierarchical', true, false),
('moscow_nsk', 'moscow_hq', 'nsk_support', 'hierarchical', true, false),
('moscow_kzn', 'moscow_hq', 'kzn_branch', 'hierarchical', true, false),
('spb_ekb', 'spb_office', 'ekb_center', 'support', true, true);

-- Insert sample site resources
INSERT INTO site_resources (resource_id, site_id, resource_name, resource_type, capacity, resource_status) VALUES
('moscow_meeting_room_1', 'moscow_hq', 'Executive Conference Room', 'meeting_room', 20, 'available'),
('moscow_meeting_room_2', 'moscow_hq', 'Training Room A', 'meeting_room', 30, 'available'),
('spb_workstation_block_a', 'spb_office', 'Workstation Block A', 'workstation', 50, 'available'),
('ekb_call_center_floor_1', 'ekb_center', 'Call Center Floor 1', 'workstation', 60, 'available'),
('nsk_support_lab', 'nsk_support', 'Technical Support Lab', 'facility', 10, 'available');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE sites IS 'Site definitions and management with capacity, location, and operational details';
COMMENT ON TABLE site_employees IS 'Employee assignments to sites with role, status, and cross-site privilege tracking';
COMMENT ON TABLE cross_site_rules IS 'Rules governing cross-site operations, employee mobility, and resource sharing';
COMMENT ON TABLE site_relationships IS 'Relationships and hierarchies between sites with operational arrangements';
COMMENT ON TABLE site_resources IS 'Site resources and capacity management with utilization tracking';
COMMENT ON TABLE cross_site_transfers IS 'Employee transfers between sites with approval workflow and logistics';
COMMENT ON TABLE site_performance_metrics IS 'Performance metrics and KPIs for sites with comparative analysis';
COMMENT ON TABLE site_communications IS 'Communications and announcements for sites with multi-channel delivery';
COMMENT ON TABLE site_compliance_tracking IS 'Compliance tracking for sites across various regulations and standards';
COMMENT ON TABLE site_emergency_procedures IS 'Emergency procedures and contact information for crisis management';