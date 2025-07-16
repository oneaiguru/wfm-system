-- =============================================================================
-- 061_multi_site_operations_infrastructure.sql
-- Multi-Site Operations Infrastructure (Tasks 11-15)
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-14
-- Purpose: Enterprise-scale multi-site management capabilities
-- Tasks: 11-15 (Site Resource Pools, Cross-Site Assignments, Location Hierarchy, Communication Logs, Global Optimization Cache)
-- Focus: Resource sharing, employee mobility, hierarchical structure, inter-site coordination, optimization caching
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================================================
-- TASK 11: SITE RESOURCE POOLS - Shared resource management across sites
-- =============================================================================

-- Resource pools for sharing employees/equipment between Moscow, St. Petersburg, Kazan
CREATE TABLE site_resource_pools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_id VARCHAR(50) NOT NULL UNIQUE,
    pool_name VARCHAR(200) NOT NULL,
    pool_description TEXT,
    
    -- Pool classification
    pool_type VARCHAR(30) NOT NULL CHECK (pool_type IN (
        'employee_pool', 'equipment_pool', 'facility_pool', 'skill_pool', 
        'backup_pool', 'emergency_pool', 'shared_services'
    )),
    pool_category VARCHAR(30) DEFAULT 'operational' CHECK (pool_category IN (
        'operational', 'strategic', 'emergency', 'seasonal', 'project_based'
    )),
    
    -- Pool scope and geography
    participating_sites JSONB NOT NULL DEFAULT '[]', -- Sites that contribute to/use this pool
    primary_site_id VARCHAR(50), -- Main coordination site
    backup_site_id VARCHAR(50), -- Backup coordination site
    geographical_scope VARCHAR(30) DEFAULT 'regional' CHECK (geographical_scope IN (
        'local', 'regional', 'national', 'international'
    )),
    
    -- Resource capacity and availability
    total_pool_capacity INTEGER NOT NULL DEFAULT 0,
    available_capacity INTEGER DEFAULT 0,
    reserved_capacity INTEGER DEFAULT 0,
    emergency_reserve_capacity INTEGER DEFAULT 0,
    
    -- Pool utilization metrics
    current_utilization_percentage DECIMAL(5,2) DEFAULT 0.0,
    peak_utilization_percentage DECIMAL(5,2) DEFAULT 0.0,
    average_utilization_percentage DECIMAL(5,2) DEFAULT 0.0,
    utilization_trend VARCHAR(20) DEFAULT 'stable',
    
    -- Allocation rules and priorities
    allocation_strategy VARCHAR(30) DEFAULT 'round_robin' CHECK (allocation_strategy IN (
        'round_robin', 'load_balanced', 'priority_based', 'skill_matched', 
        'proximity_based', 'cost_optimized'
    )),
    priority_rules JSONB DEFAULT '{}', -- Rules for resource allocation priority
    allocation_constraints JSONB DEFAULT '{}', -- Constraints on resource allocation
    
    -- Pool management
    pool_manager_id UUID,
    deputy_manager_id UUID,
    coordination_team JSONB DEFAULT '[]',
    escalation_contacts JSONB DEFAULT '[]',
    
    -- Operating schedule
    operating_hours JSONB DEFAULT '{}', -- When pool resources are available
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    maintenance_windows JSONB DEFAULT '[]',
    
    -- Financial management
    pool_budget DECIMAL(12,2),
    cost_sharing_formula JSONB DEFAULT '{}', -- How costs are shared between sites
    billing_model VARCHAR(30) DEFAULT 'usage_based',
    monthly_operating_cost DECIMAL(10,2),
    
    -- Performance tracking
    sla_targets JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    quality_standards JSONB DEFAULT '{}',
    
    -- Pool status and lifecycle
    pool_status VARCHAR(20) DEFAULT 'active' CHECK (pool_status IN (
        'planning', 'setup', 'active', 'maintenance', 'suspended', 'decommissioned'
    )),
    activation_date DATE,
    deactivation_date DATE,
    
    -- Communication and collaboration
    communication_channels JSONB DEFAULT '[]',
    collaboration_tools JSONB DEFAULT '[]',
    reporting_frequency VARCHAR(20) DEFAULT 'weekly',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Resource pool allocations tracking
CREATE TABLE site_resource_pool_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    allocation_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Allocation basics
    pool_id VARCHAR(50) NOT NULL,
    requesting_site_id VARCHAR(50) NOT NULL,
    providing_site_id VARCHAR(50),
    resource_type VARCHAR(50) NOT NULL,
    resource_identifier VARCHAR(100), -- Employee ID, equipment ID, etc.
    
    -- Allocation details
    allocation_type VARCHAR(30) NOT NULL CHECK (allocation_type IN (
        'temporary', 'permanent', 'emergency', 'scheduled', 'on_demand', 'backup'
    )),
    allocation_reason VARCHAR(100) NOT NULL,
    business_justification TEXT,
    
    -- Timeline and scheduling
    allocation_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    allocation_end_date TIMESTAMP WITH TIME ZONE,
    planned_duration_hours INTEGER,
    actual_duration_hours INTEGER,
    
    -- Allocation status
    allocation_status VARCHAR(20) DEFAULT 'requested' CHECK (allocation_status IN (
        'requested', 'approved', 'allocated', 'in_use', 'completed', 'cancelled', 'expired'
    )),
    
    -- Approval workflow
    requested_by UUID NOT NULL,
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Resource requirements
    skill_requirements JSONB DEFAULT '[]',
    equipment_specifications JSONB DEFAULT '{}',
    service_level_requirements JSONB DEFAULT '{}',
    
    -- Cost and billing
    allocation_cost DECIMAL(10,2),
    cost_calculation_method VARCHAR(30),
    billing_period VARCHAR(20) DEFAULT 'daily',
    actual_cost DECIMAL(10,2),
    
    -- Performance and satisfaction
    service_quality_rating DECIMAL(3,2),
    requester_satisfaction_rating DECIMAL(3,2),
    provider_satisfaction_rating DECIMAL(3,2),
    performance_notes TEXT,
    
    -- Completion tracking
    completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    deliverables_completed JSONB DEFAULT '[]',
    issues_encountered JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (pool_id) REFERENCES site_resource_pools(pool_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES agents(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES agents(id) ON DELETE SET NULL
);

-- =============================================================================
-- TASK 12: CROSS-SITE ASSIGNMENT MANAGEMENT - Employee assignments across multiple sites
-- =============================================================================

-- Cross-site assignments for project work and coverage
CREATE TABLE cross_site_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Assignment basics
    employee_id UUID NOT NULL,
    home_site_id VARCHAR(50) NOT NULL,
    host_site_id VARCHAR(50) NOT NULL,
    assignment_name VARCHAR(200) NOT NULL,
    assignment_description TEXT,
    
    -- Assignment classification
    assignment_type VARCHAR(30) NOT NULL CHECK (assignment_type IN (
        'project_assignment', 'coverage_assignment', 'skill_exchange', 'training_assignment',
        'emergency_coverage', 'seasonal_support', 'strategic_initiative'
    )),
    assignment_category VARCHAR(30) DEFAULT 'operational' CHECK (assignment_category IN (
        'operational', 'strategic', 'developmental', 'emergency'
    )),
    
    -- Assignment scope and requirements
    assignment_scope VARCHAR(30) DEFAULT 'full_time' CHECK (assignment_scope IN (
        'full_time', 'part_time', 'flex_time', 'on_call', 'project_based'
    )),
    workload_percentage DECIMAL(5,2) DEFAULT 100.0, -- % of employee's time
    required_skills JSONB DEFAULT '[]',
    preferred_qualifications JSONB DEFAULT '[]',
    
    -- Timeline and scheduling
    assignment_start_date DATE NOT NULL,
    assignment_end_date DATE,
    planned_duration_weeks INTEGER,
    actual_duration_weeks INTEGER,
    
    -- Work arrangement details
    work_arrangement VARCHAR(30) DEFAULT 'on_site' CHECK (work_arrangement IN (
        'on_site', 'remote', 'hybrid', 'rotational', 'flexible'
    )),
    reporting_structure VARCHAR(30) DEFAULT 'matrix' CHECK (reporting_structure IN (
        'direct', 'matrix', 'dotted_line', 'project_lead'
    )),
    host_site_manager_id UUID,
    project_lead_id UUID,
    
    -- Assignment status and approval
    assignment_status VARCHAR(20) DEFAULT 'requested' CHECK (assignment_status IN (
        'requested', 'approved', 'active', 'on_hold', 'completed', 'cancelled', 'terminated'
    )),
    requested_by UUID NOT NULL,
    approved_by UUID,
    approval_date DATE,
    
    -- Logistics and support
    accommodation_required BOOLEAN DEFAULT false,
    accommodation_type VARCHAR(30),
    accommodation_cost DECIMAL(8,2),
    travel_arrangements JSONB DEFAULT '{}',
    equipment_provided JSONB DEFAULT '[]',
    
    -- Integration and onboarding
    onboarding_plan JSONB DEFAULT '{}',
    local_buddy_assigned_id UUID,
    orientation_completed BOOLEAN DEFAULT false,
    system_access_granted BOOLEAN DEFAULT false,
    
    -- Performance and deliverables
    assignment_objectives JSONB DEFAULT '[]',
    key_deliverables JSONB DEFAULT '[]',
    success_metrics JSONB DEFAULT '{}',
    progress_milestones JSONB DEFAULT '[]',
    
    -- Performance tracking
    current_progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    performance_rating DECIMAL(3,2),
    mid_assignment_review_date DATE,
    final_review_date DATE,
    
    -- Knowledge transfer and handover
    knowledge_transfer_plan JSONB DEFAULT '{}',
    documentation_requirements JSONB DEFAULT '[]',
    handover_notes TEXT,
    successor_identified BOOLEAN DEFAULT false,
    
    -- Cost and budget
    assignment_budget DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    cost_center_allocation JSONB DEFAULT '{}',
    billing_arrangements JSONB DEFAULT '{}',
    
    -- Feedback and lessons learned
    employee_feedback TEXT,
    manager_feedback TEXT,
    lessons_learned JSONB DEFAULT '[]',
    recommendations JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES agents(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (host_site_manager_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (project_lead_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (local_buddy_assigned_id) REFERENCES agents(id) ON DELETE SET NULL,
    
    -- Ensure valid assignment period
    CHECK (assignment_end_date IS NULL OR assignment_end_date >= assignment_start_date),
    -- Ensure valid workload percentage
    CHECK (workload_percentage > 0 AND workload_percentage <= 100)
);

-- Assignment task tracking
CREATE TABLE cross_site_assignment_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id VARCHAR(50) NOT NULL UNIQUE,
    assignment_id VARCHAR(50) NOT NULL,
    
    -- Task details
    task_name VARCHAR(200) NOT NULL,
    task_description TEXT,
    task_type VARCHAR(30) NOT NULL CHECK (task_type IN (
        'deliverable', 'milestone', 'training', 'documentation', 'handover', 'review'
    )),
    
    -- Task scheduling
    planned_start_date DATE,
    planned_end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,
    estimated_hours DECIMAL(6,2),
    actual_hours DECIMAL(6,2),
    
    -- Task status and progress
    task_status VARCHAR(20) DEFAULT 'planned' CHECK (task_status IN (
        'planned', 'in_progress', 'completed', 'on_hold', 'cancelled'
    )),
    completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    quality_rating DECIMAL(3,2),
    
    -- Dependencies and relationships
    depends_on_tasks JSONB DEFAULT '[]',
    blocking_tasks JSONB DEFAULT '[]',
    related_tasks JSONB DEFAULT '[]',
    
    -- Resources and requirements
    required_resources JSONB DEFAULT '[]',
    skill_requirements JSONB DEFAULT '[]',
    support_contacts JSONB DEFAULT '[]',
    
    -- Deliverables and outcomes
    deliverable_type VARCHAR(50),
    deliverable_location VARCHAR(200),
    acceptance_criteria JSONB DEFAULT '[]',
    review_required BOOLEAN DEFAULT false,
    reviewer_id UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (assignment_id) REFERENCES cross_site_assignments(assignment_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- =============================================================================
-- TASK 13: LOCATION HIERARCHY MANAGEMENT - Complex organizational location structures
-- =============================================================================

-- Location hierarchies with headquarters and regional structure
CREATE TABLE location_hierarchies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id VARCHAR(50) NOT NULL UNIQUE,
    location_name VARCHAR(200) NOT NULL,
    location_code VARCHAR(20) NOT NULL UNIQUE,
    
    -- Hierarchical structure
    parent_location_id VARCHAR(50),
    hierarchy_level INTEGER NOT NULL DEFAULT 1,
    hierarchy_path VARCHAR(500), -- Full path from root (e.g., "/RU/Moscow/HQ")
    sort_order INTEGER DEFAULT 0,
    
    -- Location classification
    location_type VARCHAR(30) NOT NULL CHECK (location_type IN (
        'country', 'region', 'city', 'headquarters', 'office', 'branch', 
        'department', 'floor', 'building', 'zone', 'virtual'
    )),
    location_category VARCHAR(30) DEFAULT 'physical' CHECK (location_category IN (
        'physical', 'logical', 'administrative', 'functional'
    )),
    
    -- Geographic information
    country VARCHAR(100) DEFAULT 'Russia',
    region_state VARCHAR(100),
    city VARCHAR(100),
    district VARCHAR(100),
    address_full TEXT,
    postal_code VARCHAR(20),
    
    -- Coordinates for distance calculations
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    
    -- Administrative details
    administrative_code VARCHAR(50), -- OKATO, KLADR, etc.
    tax_jurisdiction VARCHAR(100),
    legal_entity VARCHAR(200),
    cost_center_code VARCHAR(50),
    
    -- Capacity and resources
    total_capacity INTEGER DEFAULT 0,
    current_occupancy INTEGER DEFAULT 0,
    maximum_capacity INTEGER DEFAULT 0,
    available_space_sqm DECIMAL(10,2),
    
    -- Operational information
    operational_status VARCHAR(20) DEFAULT 'active' CHECK (operational_status IN (
        'active', 'inactive', 'maintenance', 'construction', 'planning', 'decommissioned'
    )),
    opening_date DATE,
    closing_date DATE,
    business_hours JSONB DEFAULT '{}',
    
    -- Management and contacts
    location_manager_id UUID,
    administrative_contact_id UUID,
    facilities_contact_id UUID,
    security_contact_id UUID,
    
    -- Hierarchical permissions and inheritance
    inherits_from_parent BOOLEAN DEFAULT true,
    override_parent_settings JSONB DEFAULT '{}',
    local_configurations JSONB DEFAULT '{}',
    access_restrictions JSONB DEFAULT '[]',
    
    -- Financial and budget information
    budget_allocation DECIMAL(12,2),
    monthly_operating_cost DECIMAL(10,2),
    revenue_attribution DECIMAL(12,2),
    cost_allocation_rules JSONB DEFAULT '{}',
    
    -- Compliance and certifications
    regulatory_requirements JSONB DEFAULT '[]',
    compliance_status JSONB DEFAULT '{}',
    certifications JSONB DEFAULT '[]',
    last_audit_date DATE,
    
    -- Services and capabilities
    available_services JSONB DEFAULT '[]',
    supported_functions JSONB DEFAULT '[]',
    technology_infrastructure JSONB DEFAULT '{}',
    facilities_amenities JSONB DEFAULT '[]',
    
    -- Relationships and dependencies
    sister_locations JSONB DEFAULT '[]',
    backup_locations JSONB DEFAULT '[]',
    shared_resources_with JSONB DEFAULT '[]',
    
    -- Metadata and classification
    tags JSONB DEFAULT '[]',
    custom_attributes JSONB DEFAULT '{}',
    external_references JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_location_id) REFERENCES location_hierarchies(location_id) ON DELETE RESTRICT,
    FOREIGN KEY (location_manager_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (administrative_contact_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (facilities_contact_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (security_contact_id) REFERENCES agents(id) ON DELETE SET NULL,
    
    -- Prevent self-referencing
    CHECK (location_id != parent_location_id),
    -- Ensure valid capacity values
    CHECK (current_occupancy <= total_capacity),
    CHECK (total_capacity <= maximum_capacity)
);

-- Location relationships and connections
CREATE TABLE location_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Relationship definition
    source_location_id VARCHAR(50) NOT NULL,
    target_location_id VARCHAR(50) NOT NULL,
    relationship_type VARCHAR(30) NOT NULL CHECK (relationship_type IN (
        'parent_child', 'sister', 'backup', 'shared_resources', 'reporting',
        'dependency', 'communication', 'workflow', 'escalation'
    )),
    
    -- Relationship characteristics
    relationship_strength VARCHAR(20) DEFAULT 'medium' CHECK (relationship_strength IN (
        'weak', 'medium', 'strong', 'critical'
    )),
    relationship_direction VARCHAR(20) DEFAULT 'bidirectional' CHECK (relationship_direction IN (
        'unidirectional', 'bidirectional'
    )),
    
    -- Relationship details
    relationship_description TEXT,
    business_justification TEXT,
    operational_impact JSONB DEFAULT '{}',
    
    -- Relationship rules and constraints
    relationship_rules JSONB DEFAULT '{}',
    access_permissions JSONB DEFAULT '{}',
    resource_sharing_rules JSONB DEFAULT '{}',
    communication_protocols JSONB DEFAULT '{}',
    
    -- Status and lifecycle
    relationship_status VARCHAR(20) DEFAULT 'active' CHECK (relationship_status IN (
        'active', 'inactive', 'pending', 'suspended', 'terminated'
    )),
    effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- Management and approval
    established_by UUID,
    approved_by UUID,
    approval_date DATE,
    last_review_date DATE,
    next_review_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (source_location_id) REFERENCES location_hierarchies(location_id) ON DELETE CASCADE,
    FOREIGN KEY (target_location_id) REFERENCES location_hierarchies(location_id) ON DELETE CASCADE,
    FOREIGN KEY (established_by) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES agents(id) ON DELETE SET NULL,
    
    -- Prevent self-relationships
    CHECK (source_location_id != target_location_id)
);

-- =============================================================================
-- TASK 14: SITE COMMUNICATION LOGS - Inter-site communication and coordination tracking
-- =============================================================================

-- Communication logs for coordination between sites
CREATE TABLE site_communication_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    communication_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Communication participants
    source_site_id VARCHAR(50) NOT NULL,
    target_sites JSONB NOT NULL DEFAULT '[]', -- Can be multiple sites
    initiator_id UUID NOT NULL,
    participants JSONB DEFAULT '[]', -- All participants in the communication
    
    -- Communication classification
    communication_type VARCHAR(30) NOT NULL CHECK (communication_type IN (
        'operational_update', 'resource_request', 'emergency_notification', 'policy_announcement',
        'coordination_meeting', 'status_report', 'escalation', 'knowledge_sharing',
        'training_coordination', 'project_update', 'incident_report'
    )),
    priority_level VARCHAR(20) DEFAULT 'medium' CHECK (priority_level IN (
        'low', 'medium', 'high', 'urgent', 'critical'
    )),
    urgency_level VARCHAR(20) DEFAULT 'normal' CHECK (urgency_level IN (
        'normal', 'urgent', 'immediate'
    )),
    
    -- Communication content
    subject VARCHAR(200) NOT NULL,
    message_content TEXT NOT NULL,
    communication_summary TEXT, -- Auto-generated summary
    key_points JSONB DEFAULT '[]',
    action_items JSONB DEFAULT '[]',
    
    -- Communication context
    related_to_type VARCHAR(30), -- What this communication is about
    related_to_id VARCHAR(50), -- Reference to specific record
    business_context TEXT,
    background_information TEXT,
    
    -- Communication timeline
    communication_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    response_deadline TIMESTAMP WITH TIME ZONE,
    follow_up_date TIMESTAMP WITH TIME ZONE,
    
    -- Communication channels and methods
    primary_channel VARCHAR(30) NOT NULL CHECK (primary_channel IN (
        'email', 'phone', 'video_conference', 'instant_message', 'intranet',
        'mobile_app', 'face_to_face', 'letter', 'system_notification'
    )),
    additional_channels JSONB DEFAULT '[]',
    communication_tools JSONB DEFAULT '[]',
    
    -- Status and tracking
    communication_status VARCHAR(20) DEFAULT 'sent' CHECK (communication_status IN (
        'draft', 'sent', 'delivered', 'read', 'responded', 'acknowledged', 'closed'
    )),
    delivery_confirmation BOOLEAN DEFAULT false,
    read_confirmation BOOLEAN DEFAULT false,
    response_required BOOLEAN DEFAULT false,
    acknowledgment_required BOOLEAN DEFAULT false,
    
    -- Response and feedback tracking
    response_count INTEGER DEFAULT 0,
    acknowledgment_count INTEGER DEFAULT 0,
    expected_response_count INTEGER DEFAULT 0,
    response_rate_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Attachments and references
    attachments JSONB DEFAULT '[]',
    referenced_documents JSONB DEFAULT '[]',
    related_communications JSONB DEFAULT '[]',
    external_references JSONB DEFAULT '[]',
    
    -- Quality and effectiveness
    communication_effectiveness_rating DECIMAL(3,2),
    clarity_rating DECIMAL(3,2),
    timeliness_rating DECIMAL(3,2),
    recipient_satisfaction_rating DECIMAL(3,2),
    
    -- Compliance and audit
    retention_period_days INTEGER DEFAULT 2555, -- 7 years
    compliance_tags JSONB DEFAULT '[]',
    audit_trail JSONB DEFAULT '[]',
    privacy_level VARCHAR(20) DEFAULT 'internal',
    
    -- Automation and system integration
    auto_generated BOOLEAN DEFAULT false,
    system_triggered BOOLEAN DEFAULT false,
    template_used VARCHAR(50),
    workflow_id VARCHAR(50),
    
    -- Follow-up and escalation
    requires_follow_up BOOLEAN DEFAULT false,
    follow_up_completed BOOLEAN DEFAULT false,
    escalation_level INTEGER DEFAULT 0,
    escalated_to_id UUID,
    escalation_reason TEXT,
    
    -- Geographic and timezone considerations
    sender_timezone VARCHAR(50),
    delivery_timezone VARCHAR(50),
    time_sensitive BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (initiator_id) REFERENCES agents(id) ON DELETE RESTRICT,
    FOREIGN KEY (escalated_to_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- Communication responses and acknowledgments
CREATE TABLE site_communication_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id VARCHAR(50) NOT NULL UNIQUE,
    communication_id VARCHAR(50) NOT NULL,
    
    -- Response details
    responder_id UUID NOT NULL,
    responder_site_id VARCHAR(50),
    response_type VARCHAR(20) NOT NULL CHECK (response_type IN (
        'acknowledgment', 'reply', 'escalation', 'delegation', 'completion'
    )),
    
    -- Response content
    response_content TEXT,
    response_summary TEXT,
    action_taken TEXT,
    additional_information JSONB DEFAULT '{}',
    
    -- Response timing
    response_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_time_hours DECIMAL(8,2), -- Time from original communication
    within_deadline BOOLEAN DEFAULT true,
    
    -- Response status
    response_status VARCHAR(20) DEFAULT 'submitted' CHECK (response_status IN (
        'draft', 'submitted', 'acknowledged', 'processed', 'escalated'
    )),
    
    -- Follow-up requirements
    requires_further_action BOOLEAN DEFAULT false,
    follow_up_required BOOLEAN DEFAULT false,
    next_action_due_date TIMESTAMP WITH TIME ZONE,
    assigned_to_id UUID,
    
    -- Quality and satisfaction
    response_quality_rating DECIMAL(3,2),
    helpfulness_rating DECIMAL(3,2),
    completeness_rating DECIMAL(3,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (communication_id) REFERENCES site_communication_logs(communication_id) ON DELETE CASCADE,
    FOREIGN KEY (responder_id) REFERENCES agents(id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_to_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- =============================================================================
-- TASK 15: GLOBAL OPTIMIZATION CACHE - Cached optimization results for multi-site operations
-- =============================================================================

-- Optimization cache for schedule and resource allocation
CREATE TABLE global_optimization_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Optimization identification
    optimization_type VARCHAR(30) NOT NULL CHECK (optimization_type IN (
        'schedule_optimization', 'resource_allocation', 'workforce_planning', 'capacity_planning',
        'cost_optimization', 'performance_optimization', 'risk_optimization', 'cross_site_balancing'
    )),
    optimization_scope VARCHAR(30) NOT NULL CHECK (optimization_scope IN (
        'single_site', 'multi_site', 'regional', 'global', 'department', 'skill_group'
    )),
    optimization_algorithm VARCHAR(50) NOT NULL,
    algorithm_version VARCHAR(20),
    
    -- Input parameters and context
    input_parameters JSONB NOT NULL,
    context_data JSONB DEFAULT '{}',
    constraints JSONB DEFAULT '{}',
    objectives JSONB DEFAULT '{}',
    
    -- Scope and sites
    affected_sites JSONB NOT NULL DEFAULT '[]',
    affected_departments JSONB DEFAULT '[]',
    affected_skill_groups JSONB DEFAULT '[]',
    affected_time_period JSONB NOT NULL, -- Start/end dates and times
    
    -- Optimization results
    optimization_results JSONB NOT NULL,
    solution_quality_score DECIMAL(5,2),
    convergence_achieved BOOLEAN DEFAULT false,
    optimization_status VARCHAR(20) DEFAULT 'completed' CHECK (optimization_status IN (
        'running', 'completed', 'failed', 'interrupted', 'cached', 'expired'
    )),
    
    -- Performance metrics
    execution_time_seconds DECIMAL(10,3),
    memory_usage_mb DECIMAL(10,2),
    cpu_utilization_percentage DECIMAL(5,2),
    iterations_completed INTEGER,
    
    -- Quality and validation
    solution_feasibility BOOLEAN DEFAULT true,
    constraints_satisfied BOOLEAN DEFAULT true,
    validation_results JSONB DEFAULT '{}',
    quality_metrics JSONB DEFAULT '{}',
    
    -- Improvement and comparison
    baseline_comparison JSONB DEFAULT '{}',
    improvement_percentage DECIMAL(5,2),
    cost_savings DECIMAL(12,2),
    efficiency_gain DECIMAL(5,2),
    
    -- Cache management
    cache_created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cache_expires_at TIMESTAMP WITH TIME ZONE,
    cache_hit_count INTEGER DEFAULT 0,
    cache_priority INTEGER DEFAULT 5, -- 1-10 scale
    
    -- Usage tracking
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    reused_count INTEGER DEFAULT 0,
    adaptation_count INTEGER DEFAULT 0,
    
    -- Cache validity and dependencies
    is_valid BOOLEAN DEFAULT true,
    invalidation_reason TEXT,
    dependent_on_data JSONB DEFAULT '[]', -- What data this depends on
    invalidated_by_changes JSONB DEFAULT '[]',
    
    -- Versioning and lineage
    parent_cache_id VARCHAR(50), -- If derived from another optimization
    child_cache_ids JSONB DEFAULT '[]',
    optimization_lineage JSONB DEFAULT '[]',
    version_number INTEGER DEFAULT 1,
    
    -- Optimization metadata
    optimization_triggered_by VARCHAR(30) CHECK (optimization_triggered_by IN (
        'scheduled', 'manual', 'event_driven', 'threshold_based', 'real_time'
    )),
    triggered_by_user_id UUID,
    optimization_reason TEXT,
    business_impact TEXT,
    
    -- Deployment and implementation
    implementation_status VARCHAR(20) DEFAULT 'pending' CHECK (implementation_status IN (
        'pending', 'approved', 'deployed', 'active', 'rolled_back', 'superseded'
    )),
    deployed_at TIMESTAMP WITH TIME ZONE,
    deployed_by_id UUID,
    rollback_plan JSONB DEFAULT '{}',
    
    -- Monitoring and feedback
    actual_performance JSONB DEFAULT '{}',
    performance_variance JSONB DEFAULT '{}',
    user_feedback JSONB DEFAULT '[]',
    lessons_learned TEXT,
    
    -- Integration and API access
    api_access_count INTEGER DEFAULT 0,
    integration_usage JSONB DEFAULT '{}',
    export_formats JSONB DEFAULT '[]',
    sharing_permissions JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_cache_id) REFERENCES global_optimization_cache(cache_id) ON DELETE SET NULL,
    FOREIGN KEY (triggered_by_user_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (deployed_by_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- Optimization cache usage tracking
CREATE TABLE optimization_cache_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usage_id VARCHAR(50) NOT NULL UNIQUE,
    cache_id VARCHAR(50) NOT NULL,
    
    -- Usage details
    used_by_user_id UUID,
    used_by_system VARCHAR(50),
    usage_type VARCHAR(20) NOT NULL CHECK (usage_type IN (
        'direct_access', 'api_call', 'scheduled_job', 'real_time_query', 'batch_process'
    )),
    
    -- Usage context
    usage_purpose TEXT,
    requesting_site_id VARCHAR(50),
    business_context VARCHAR(100),
    
    -- Usage timing
    usage_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_time_ms DECIMAL(10,3),
    data_freshness_hours DECIMAL(8,2),
    
    -- Usage outcome
    usage_successful BOOLEAN DEFAULT true,
    error_message TEXT,
    result_quality_rating DECIMAL(3,2),
    user_satisfaction_rating DECIMAL(3,2),
    
    -- Performance impact
    cache_hit BOOLEAN DEFAULT true,
    computation_avoided BOOLEAN DEFAULT true,
    time_saved_seconds DECIMAL(10,3),
    cost_saved DECIMAL(8,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cache_id) REFERENCES global_optimization_cache(cache_id) ON DELETE CASCADE,
    FOREIGN KEY (used_by_user_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Site Resource Pools indexes
CREATE INDEX idx_site_resource_pools_type ON site_resource_pools(pool_type);
CREATE INDEX idx_site_resource_pools_status ON site_resource_pools(pool_status);
CREATE INDEX idx_site_resource_pools_sites ON site_resource_pools USING gin(participating_sites);
CREATE INDEX idx_site_resource_pools_manager ON site_resource_pools(pool_manager_id);
CREATE INDEX idx_site_resource_pools_utilization ON site_resource_pools(current_utilization_percentage);

-- Site Resource Pool Allocations indexes
CREATE INDEX idx_pool_allocations_pool ON site_resource_pool_allocations(pool_id);
CREATE INDEX idx_pool_allocations_requesting_site ON site_resource_pool_allocations(requesting_site_id);
CREATE INDEX idx_pool_allocations_providing_site ON site_resource_pool_allocations(providing_site_id);
CREATE INDEX idx_pool_allocations_status ON site_resource_pool_allocations(allocation_status);
CREATE INDEX idx_pool_allocations_dates ON site_resource_pool_allocations(allocation_start_date, allocation_end_date);
CREATE INDEX idx_pool_allocations_requested_by ON site_resource_pool_allocations(requested_by);

-- Cross-Site Assignments indexes
CREATE INDEX idx_cross_site_assignments_employee ON cross_site_assignments(employee_id);
CREATE INDEX idx_cross_site_assignments_home_site ON cross_site_assignments(home_site_id);
CREATE INDEX idx_cross_site_assignments_host_site ON cross_site_assignments(host_site_id);
CREATE INDEX idx_cross_site_assignments_type ON cross_site_assignments(assignment_type);
CREATE INDEX idx_cross_site_assignments_status ON cross_site_assignments(assignment_status);
CREATE INDEX idx_cross_site_assignments_dates ON cross_site_assignments(assignment_start_date, assignment_end_date);
CREATE INDEX idx_cross_site_assignments_requested_by ON cross_site_assignments(requested_by);

-- Cross-Site Assignment Tasks indexes
CREATE INDEX idx_assignment_tasks_assignment ON cross_site_assignment_tasks(assignment_id);
CREATE INDEX idx_assignment_tasks_status ON cross_site_assignment_tasks(task_status);
CREATE INDEX idx_assignment_tasks_dates ON cross_site_assignment_tasks(planned_start_date, planned_end_date);
CREATE INDEX idx_assignment_tasks_type ON cross_site_assignment_tasks(task_type);

-- Location Hierarchies indexes
CREATE INDEX idx_location_hierarchies_parent ON location_hierarchies(parent_location_id);
CREATE INDEX idx_location_hierarchies_type ON location_hierarchies(location_type);
CREATE INDEX idx_location_hierarchies_level ON location_hierarchies(hierarchy_level);
CREATE INDEX idx_location_hierarchies_path ON location_hierarchies(hierarchy_path);
CREATE INDEX idx_location_hierarchies_status ON location_hierarchies(operational_status);
CREATE INDEX idx_location_hierarchies_manager ON location_hierarchies(location_manager_id);
CREATE INDEX idx_location_hierarchies_coordinates ON location_hierarchies(latitude, longitude);
CREATE INDEX idx_location_hierarchies_city ON location_hierarchies(city);

-- Location Relationships indexes
CREATE INDEX idx_location_relationships_source ON location_relationships(source_location_id);
CREATE INDEX idx_location_relationships_target ON location_relationships(target_location_id);
CREATE INDEX idx_location_relationships_type ON location_relationships(relationship_type);
CREATE INDEX idx_location_relationships_status ON location_relationships(relationship_status);

-- Site Communication Logs indexes
CREATE INDEX idx_site_communication_logs_source ON site_communication_logs(source_site_id);
CREATE INDEX idx_site_communication_logs_targets ON site_communication_logs USING gin(target_sites);
CREATE INDEX idx_site_communication_logs_type ON site_communication_logs(communication_type);
CREATE INDEX idx_site_communication_logs_priority ON site_communication_logs(priority_level);
CREATE INDEX idx_site_communication_logs_status ON site_communication_logs(communication_status);
CREATE INDEX idx_site_communication_logs_date ON site_communication_logs(communication_date);
CREATE INDEX idx_site_communication_logs_initiator ON site_communication_logs(initiator_id);
CREATE INDEX idx_site_communication_logs_deadline ON site_communication_logs(response_deadline);

-- Site Communication Responses indexes
CREATE INDEX idx_site_communication_responses_comm ON site_communication_responses(communication_id);
CREATE INDEX idx_site_communication_responses_responder ON site_communication_responses(responder_id);
CREATE INDEX idx_site_communication_responses_site ON site_communication_responses(responder_site_id);
CREATE INDEX idx_site_communication_responses_type ON site_communication_responses(response_type);
CREATE INDEX idx_site_communication_responses_date ON site_communication_responses(response_date);

-- Global Optimization Cache indexes
CREATE INDEX idx_global_optimization_cache_type ON global_optimization_cache(optimization_type);
CREATE INDEX idx_global_optimization_cache_scope ON global_optimization_cache(optimization_scope);
CREATE INDEX idx_global_optimization_cache_status ON global_optimization_cache(optimization_status);
CREATE INDEX idx_global_optimization_cache_sites ON global_optimization_cache USING gin(affected_sites);
CREATE INDEX idx_global_optimization_cache_created ON global_optimization_cache(cache_created_at);
CREATE INDEX idx_global_optimization_cache_expires ON global_optimization_cache(cache_expires_at);
CREATE INDEX idx_global_optimization_cache_valid ON global_optimization_cache(is_valid) WHERE is_valid = true;
CREATE INDEX idx_global_optimization_cache_priority ON global_optimization_cache(cache_priority);
CREATE INDEX idx_global_optimization_cache_accessed ON global_optimization_cache(last_accessed_at);

-- Optimization Cache Usage indexes
CREATE INDEX idx_optimization_cache_usage_cache ON optimization_cache_usage(cache_id);
CREATE INDEX idx_optimization_cache_usage_user ON optimization_cache_usage(used_by_user_id);
CREATE INDEX idx_optimization_cache_usage_timestamp ON optimization_cache_usage(usage_timestamp);
CREATE INDEX idx_optimization_cache_usage_type ON optimization_cache_usage(usage_type);
CREATE INDEX idx_optimization_cache_usage_site ON optimization_cache_usage(requesting_site_id);

-- =============================================================================
-- TRIGGERS AND FUNCTIONS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_multi_site_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER site_resource_pools_update_trigger
    BEFORE UPDATE ON site_resource_pools
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER site_resource_pool_allocations_update_trigger
    BEFORE UPDATE ON site_resource_pool_allocations
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER cross_site_assignments_update_trigger
    BEFORE UPDATE ON cross_site_assignments
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER cross_site_assignment_tasks_update_trigger
    BEFORE UPDATE ON cross_site_assignment_tasks
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER location_hierarchies_update_trigger
    BEFORE UPDATE ON location_hierarchies
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER location_relationships_update_trigger
    BEFORE UPDATE ON location_relationships
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER site_communication_logs_update_trigger
    BEFORE UPDATE ON site_communication_logs
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER site_communication_responses_update_trigger
    BEFORE UPDATE ON site_communication_responses
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

CREATE TRIGGER global_optimization_cache_update_trigger
    BEFORE UPDATE ON global_optimization_cache
    FOR EACH ROW EXECUTE FUNCTION update_multi_site_timestamp();

-- Resource pool utilization calculation
CREATE OR REPLACE FUNCTION calculate_pool_utilization()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE site_resource_pools SET 
        available_capacity = total_pool_capacity - reserved_capacity,
        current_utilization_percentage = CASE 
            WHEN total_pool_capacity > 0 THEN 
                (reserved_capacity::DECIMAL / total_pool_capacity::DECIMAL) * 100
            ELSE 0
        END
    WHERE pool_id = NEW.pool_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pool_allocations_utilization_trigger
    AFTER INSERT OR UPDATE OR DELETE ON site_resource_pool_allocations
    FOR EACH ROW EXECUTE FUNCTION calculate_pool_utilization();

-- Cache access tracking
CREATE OR REPLACE FUNCTION track_cache_access()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE global_optimization_cache SET 
        last_accessed_at = CURRENT_TIMESTAMP,
        access_count = access_count + 1
    WHERE cache_id = NEW.cache_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cache_usage_tracking_trigger
    AFTER INSERT ON optimization_cache_usage
    FOR EACH ROW EXECUTE FUNCTION track_cache_access();

-- Hierarchy path maintenance
CREATE OR REPLACE FUNCTION maintain_hierarchy_path()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_location_id IS NULL THEN
        NEW.hierarchy_path = '/' || NEW.location_code;
        NEW.hierarchy_level = 1;
    ELSE
        SELECT 
            hierarchy_path || '/' || NEW.location_code,
            hierarchy_level + 1
        INTO 
            NEW.hierarchy_path,
            NEW.hierarchy_level
        FROM location_hierarchies 
        WHERE location_id = NEW.parent_location_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER location_hierarchy_path_trigger
    BEFORE INSERT OR UPDATE ON location_hierarchies
    FOR EACH ROW EXECUTE FUNCTION maintain_hierarchy_path();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Resource pool utilization summary
CREATE VIEW v_resource_pool_utilization AS
SELECT 
    srp.pool_id,
    srp.pool_name,
    srp.pool_type,
    srp.total_pool_capacity,
    srp.available_capacity,
    srp.reserved_capacity,
    srp.current_utilization_percentage,
    COUNT(srpa.id) as active_allocations,
    AVG(srpa.allocation_cost) as average_allocation_cost,
    array_agg(DISTINCT srpa.requesting_site_id) as requesting_sites
FROM site_resource_pools srp
LEFT JOIN site_resource_pool_allocations srpa ON srp.pool_id = srpa.pool_id 
    AND srpa.allocation_status = 'allocated'
WHERE srp.pool_status = 'active'
GROUP BY srp.pool_id, srp.pool_name, srp.pool_type, srp.total_pool_capacity, 
         srp.available_capacity, srp.reserved_capacity, srp.current_utilization_percentage
ORDER BY srp.current_utilization_percentage DESC;

-- Cross-site assignment summary
CREATE VIEW v_cross_site_assignment_summary AS
SELECT 
    csa.home_site_id,
    csa.host_site_id,
    csa.assignment_type,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN csa.assignment_status = 'active' THEN 1 END) as active_assignments,
    AVG(csa.workload_percentage) as average_workload,
    AVG(csa.assignment_budget) as average_budget,
    AVG(csa.performance_rating) as average_performance
FROM cross_site_assignments csa
WHERE csa.assignment_start_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY csa.home_site_id, csa.host_site_id, csa.assignment_type
ORDER BY total_assignments DESC;

-- Location hierarchy tree view
CREATE VIEW v_location_hierarchy_tree AS
WITH RECURSIVE location_tree AS (
    -- Root nodes
    SELECT 
        location_id,
        location_name,
        location_code,
        parent_location_id,
        hierarchy_level,
        hierarchy_path,
        location_type,
        operational_status,
        ARRAY[location_name] as path_names
    FROM location_hierarchies 
    WHERE parent_location_id IS NULL

    UNION ALL

    -- Child nodes
    SELECT 
        lh.location_id,
        lh.location_name,
        lh.location_code,
        lh.parent_location_id,
        lh.hierarchy_level,
        lh.hierarchy_path,
        lh.location_type,
        lh.operational_status,
        lt.path_names || lh.location_name
    FROM location_hierarchies lh
    INNER JOIN location_tree lt ON lh.parent_location_id = lt.location_id
)
SELECT 
    location_id,
    location_name,
    location_code,
    parent_location_id,
    hierarchy_level,
    hierarchy_path,
    location_type,
    operational_status,
    array_to_string(path_names, ' > ') as full_path_name
FROM location_tree
ORDER BY hierarchy_path;

-- Communication effectiveness metrics
CREATE VIEW v_communication_effectiveness AS
SELECT 
    scl.source_site_id,
    scl.communication_type,
    COUNT(*) as total_communications,
    AVG(scl.communication_effectiveness_rating) as avg_effectiveness,
    AVG(scl.response_rate_percentage) as avg_response_rate,
    COUNT(CASE WHEN scl.communication_status = 'closed' THEN 1 END) as closed_communications,
    AVG(EXTRACT(HOURS FROM (scr.response_date - scl.communication_date))) as avg_response_time_hours
FROM site_communication_logs scl
LEFT JOIN site_communication_responses scr ON scl.communication_id = scr.communication_id
WHERE scl.communication_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY scl.source_site_id, scl.communication_type
ORDER BY avg_effectiveness DESC;

-- Optimization cache efficiency
CREATE VIEW v_optimization_cache_efficiency AS
SELECT 
    goc.optimization_type,
    goc.optimization_scope,
    COUNT(*) as total_optimizations,
    AVG(goc.cache_hit_count) as avg_cache_hits,
    AVG(goc.solution_quality_score) as avg_quality_score,
    AVG(goc.execution_time_seconds) as avg_execution_time,
    SUM(goc.cost_savings) as total_cost_savings,
    COUNT(CASE WHEN goc.is_valid THEN 1 END) as valid_caches
FROM global_optimization_cache goc
WHERE goc.cache_created_at >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY goc.optimization_type, goc.optimization_scope
ORDER BY total_cost_savings DESC;

-- =============================================================================
-- SAMPLE DATA FOR RUSSIAN MULTI-SITE OPERATIONS
-- =============================================================================

-- Insert Russian location hierarchy
INSERT INTO location_hierarchies (location_id, location_name, location_code, parent_location_id, location_type, country, city, operational_status) VALUES
('RU', 'Russia', 'RU', NULL, 'country', 'Russia', NULL, 'active'),
('RU_MOSCOW_REGION', 'Moscow Region', 'MSK_REG', 'RU', 'region', 'Russia', 'Moscow', 'active'),
('RU_SPB_REGION', 'St. Petersburg Region', 'SPB_REG', 'RU', 'region', 'Russia', 'St. Petersburg', 'active'),
('RU_KAZAN_REGION', 'Tatarstan Republic', 'KZN_REG', 'RU', 'region', 'Russia', 'Kazan', 'active'),
('MSK_HQ', 'Moscow Headquarters', 'MSK_HQ', 'RU_MOSCOW_REGION', 'headquarters', 'Russia', 'Moscow', 'active'),
('SPB_OFFICE', 'St. Petersburg Office', 'SPB_OFF', 'RU_SPB_REGION', 'office', 'Russia', 'St. Petersburg', 'active'),
('KZN_BRANCH', 'Kazan Branch Office', 'KZN_BR', 'RU_KAZAN_REGION', 'branch', 'Russia', 'Kazan', 'active');

-- Insert resource pools for Russian sites
INSERT INTO site_resource_pools (pool_id, pool_name, pool_type, participating_sites, primary_site_id, total_pool_capacity, pool_status) VALUES
('RU_TECH_SPECIALISTS', 'Russian Technical Specialists Pool', 'employee_pool', 
'["MSK_HQ", "SPB_OFFICE", "KZN_BRANCH"]', 'MSK_HQ', 150, 'active'),
('RU_EQUIPMENT_SHARE', 'Shared Equipment Pool', 'equipment_pool',
'["MSK_HQ", "SPB_OFFICE", "KZN_BRANCH"]', 'MSK_HQ', 75, 'active'),
('RU_EMERGENCY_BACKUP', 'Emergency Backup Resources', 'emergency_pool',
'["MSK_HQ", "SPB_OFFICE", "KZN_BRANCH"]', 'MSK_HQ', 50, 'active');

-- Insert sample cross-site assignments
INSERT INTO cross_site_assignments (assignment_id, employee_id, home_site_id, host_site_id, assignment_name, assignment_type, assignment_start_date, assignment_status) VALUES
('ASSIGN_MSK_SPB_001', (SELECT id FROM agents LIMIT 1), 'MSK_HQ', 'SPB_OFFICE', 
'Project Alpha - St. Petersburg Implementation', 'project_assignment', CURRENT_DATE, 'active'),
('ASSIGN_SPB_KZN_001', (SELECT id FROM agents LIMIT 1 OFFSET 1), 'SPB_OFFICE', 'KZN_BRANCH',
'Skills Transfer - Customer Service Excellence', 'skill_exchange', CURRENT_DATE + INTERVAL '1 week', 'approved');

-- Insert communication logs
INSERT INTO site_communication_logs (communication_id, source_site_id, target_sites, initiator_id, communication_type, subject, message_content, priority_level) VALUES
('COMM_MSK_ALL_001', 'MSK_HQ', '["SPB_OFFICE", "KZN_BRANCH"]', 
(SELECT id FROM agents LIMIT 1), 'operational_update', 
'Q3 Operational Review and Resource Allocation',
'Уважаемые коллеги, направляем обзор операционной деятельности за Q3 и план распределения ресурсов на Q4.',
'high'),
('COMM_SPB_MSK_001', 'SPB_OFFICE', '["MSK_HQ"]',
(SELECT id FROM agents LIMIT 1), 'resource_request',
'Request for Additional Technical Support',
'Требуется дополнительная техническая поддержка для проекта модернизации системы.',
'medium');

-- Insert optimization cache entries
INSERT INTO global_optimization_cache (cache_id, optimization_type, optimization_scope, optimization_algorithm, input_parameters, optimization_results, affected_sites, affected_time_period, solution_quality_score, optimization_status) VALUES
('OPT_MULTISITE_SCHEDULE_001', 'schedule_optimization', 'multi_site', 'genetic_algorithm_v2',
'{"sites": ["MSK_HQ", "SPB_OFFICE", "KZN_BRANCH"], "period": "2025-07-15 to 2025-07-21", "constraints": ["skill_matching", "cost_optimization"]}',
'{"optimized_schedules": {"MSK_HQ": {...}, "SPB_OFFICE": {...}, "KZN_BRANCH": {...}}, "efficiency_gain": 15.8, "cost_savings": 125000}',
'["MSK_HQ", "SPB_OFFICE", "KZN_BRANCH"]',
'{"start_date": "2025-07-15", "end_date": "2025-07-21", "time_range": "00:00-23:59"}',
92.5, 'completed');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE site_resource_pools IS 'Task 11: Shared resource management across sites with capacity tracking and utilization metrics';
COMMENT ON TABLE site_resource_pool_allocations IS 'Resource pool allocation tracking with approval workflow and performance metrics';
COMMENT ON TABLE cross_site_assignments IS 'Task 12: Employee assignments across multiple sites for projects and coverage';
COMMENT ON TABLE cross_site_assignment_tasks IS 'Task tracking for cross-site assignments with deliverables and milestones';
COMMENT ON TABLE location_hierarchies IS 'Task 13: Complex organizational location structures with hierarchical relationships';
COMMENT ON TABLE location_relationships IS 'Relationships and connections between locations in the hierarchy';
COMMENT ON TABLE site_communication_logs IS 'Task 14: Inter-site communication and coordination tracking';
COMMENT ON TABLE site_communication_responses IS 'Responses and acknowledgments to inter-site communications';
COMMENT ON TABLE global_optimization_cache IS 'Task 15: Cached optimization results for multi-site operations';
COMMENT ON TABLE optimization_cache_usage IS 'Usage tracking for optimization cache with performance metrics';