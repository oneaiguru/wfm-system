-- =============================================================================
-- 037_personnel_management_organizational_structure.sql
-- EXACT BDD Implementation: Personnel Management and Organizational Structure
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 16-personnel-management-organizational-structure.feature (474 lines)
-- Purpose: Complete administrative coverage for HR, organizational hierarchy, and technical infrastructure
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ENHANCED EMPLOYEE MANAGEMENT
-- =============================================================================

-- Enhanced employee profiles from BDD lines 20-43
CREATE TABLE enhanced_employee_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    personnel_number VARCHAR(20) NOT NULL UNIQUE,
    
    -- Personal information with Cyrillic support from BDD lines 25-28
    last_name VARCHAR(100) NOT NULL, -- Cyrillic: Иванов
    first_name VARCHAR(100) NOT NULL, -- Cyrillic: Иван  
    patronymic VARCHAR(100), -- Cyrillic: Иванович
    
    -- Employment details from BDD lines 29-33
    department_id UUID NOT NULL,
    position_id UUID NOT NULL,
    hire_date DATE NOT NULL CHECK (hire_date <= CURRENT_DATE),
    time_zone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    
    -- WFM account credentials from BDD lines 34-39
    wfm_login VARCHAR(50) UNIQUE,
    temporary_password VARCHAR(100), -- TempPass123! format
    force_password_change BOOLEAN DEFAULT true,
    account_expiration_days INTEGER DEFAULT 90,
    password_last_changed TIMESTAMP WITH TIME ZONE,
    
    -- Security and audit
    account_status VARCHAR(20) DEFAULT 'Active' CHECK (account_status IN ('Active', 'Inactive', 'Suspended', 'Terminated')),
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_hire_date CHECK (hire_date <= CURRENT_DATE),
    CONSTRAINT valid_password_policy CHECK (
        temporary_password IS NULL OR 
        (LENGTH(temporary_password) >= 8 AND temporary_password ~ '[A-Z]' AND temporary_password ~ '[0-9]' AND temporary_password ~ '[!@#$%^&*]')
    )
);

-- Employee skills and groups from BDD lines 44-61
CREATE TABLE employee_skill_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES enhanced_employee_profiles(id) ON DELETE CASCADE,
    service_name VARCHAR(200) NOT NULL,
    group_name VARCHAR(200) NOT NULL,
    
    -- Role hierarchy from BDD lines 50-52
    role_type VARCHAR(20) NOT NULL CHECK (role_type IN ('Primary', 'Secondary', 'Backup')),
    proficiency_level VARCHAR(20) NOT NULL CHECK (proficiency_level IN ('Basic', 'Intermediate', 'Expert')),
    
    -- Group relationships from BDD lines 53-57
    is_main_group BOOLEAN NOT NULL DEFAULT false,
    planning_priority INTEGER NOT NULL DEFAULT 1,
    
    assigned_by VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Database constraints
    CONSTRAINT unique_employee_service_group UNIQUE(employee_id, service_name, group_name),
    CONSTRAINT single_main_group_per_employee CHECK (
        NOT is_main_group OR 
        (SELECT COUNT(*) FROM employee_skill_assignments WHERE employee_id = NEW.employee_id AND is_main_group = true) <= 1
    )
);

-- Individual work settings from BDD lines 62-81
CREATE TABLE individual_work_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES enhanced_employee_profiles(id) ON DELETE CASCADE,
    
    -- Work parameters with compliance from BDD lines 67-74
    work_rate DECIMAL(3,2) NOT NULL CHECK (work_rate IN (0.5, 0.75, 1.0, 1.25)), -- Union agreement limits
    night_work_permission BOOLEAN DEFAULT false,
    weekend_work_permission BOOLEAN DEFAULT true,
    overtime_authorization BOOLEAN DEFAULT true,
    weekly_hours_norm INTEGER NOT NULL CHECK (weekly_hours_norm IN (20, 30, 40)),
    daily_hours_limit INTEGER NOT NULL CHECK (daily_hours_limit IN (4, 6, 8, 12)),
    vacation_entitlement_days INTEGER NOT NULL DEFAULT 28,
    
    -- Compliance validation
    labor_law_certified BOOLEAN DEFAULT false,
    union_agreement_compliant BOOLEAN DEFAULT true,
    contract_type_validated BOOLEAN DEFAULT true,
    
    -- System integration tracking from BDD lines 75-80
    planning_service_override BOOLEAN DEFAULT false,
    schedule_algorithm_impact JSONB,
    monitoring_service_thresholds JSONB,
    reporting_service_compliance JSONB,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_work_settings UNIQUE(employee_id)
);

-- Employee termination management from BDD lines 82-105
CREATE TABLE employee_termination_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES enhanced_employee_profiles(id),
    termination_date DATE NOT NULL,
    
    -- Termination workflow from BDD lines 86-92
    planning_service_excluded BOOLEAN DEFAULT false,
    wfm_account_blocked BOOLEAN DEFAULT false,
    historical_data_preserved BOOLEAN DEFAULT true,
    forecasts_updated BOOLEAN DEFAULT false,
    stakeholders_notified BOOLEAN DEFAULT false,
    
    -- Data retention policies from BDD lines 93-98
    personal_data_retention_years INTEGER DEFAULT 7,
    work_records_retention_years INTEGER DEFAULT 10,
    performance_data_retention_years INTEGER DEFAULT 5,
    security_logs_retention_years INTEGER DEFAULT 7,
    
    -- Cleanup tracking from BDD lines 99-104
    active_sessions_removed BOOLEAN DEFAULT false,
    future_assignments_cancelled BOOLEAN DEFAULT false,
    personal_files_archived BOOLEAN DEFAULT false,
    dependencies_updated BOOLEAN DEFAULT false,
    
    initiated_by VARCHAR(50) NOT NULL,
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 2. TECHNICAL INFRASTRUCTURE
-- =============================================================================

-- Personnel database infrastructure from BDD lines 110-132
CREATE TABLE personnel_database_infrastructure (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    infrastructure_name VARCHAR(200) NOT NULL,
    
    -- Database specifications from BDD lines 115-119
    database_engine VARCHAR(50) DEFAULT 'PostgreSQL 10.x',
    connection_pool_size INTEGER DEFAULT 100,
    backup_strategy VARCHAR(100) DEFAULT 'Daily full + hourly incremental',
    replication_type VARCHAR(50) DEFAULT 'Master-Slave streaming',
    
    -- Performance targets
    query_response_target_seconds DECIMAL(3,1) DEFAULT 2.0,
    pool_utilization_target_pct DECIMAL(5,2) DEFAULT 95.0,
    rpo_hours DECIMAL(3,1) DEFAULT 1.0, -- Recovery Point Objective
    rto_hours DECIMAL(3,1) DEFAULT 4.0, -- Recovery Time Objective
    replication_lag_target_seconds DECIMAL(3,1) DEFAULT 1.0,
    
    -- Optimization configuration from BDD lines 120-125
    indexing_strategy JSONB, -- B-tree configurations
    partitioning_config JSONB, -- Department and hire_date partitioning
    connection_pooling_config JSONB, -- PgBouncer settings
    query_optimization_config JSONB, -- Prepared statements
    
    -- Monitoring thresholds from BDD lines 126-131
    connection_usage_alert_pct DECIMAL(5,2) DEFAULT 85.0,
    query_response_alert_seconds DECIMAL(3,1) DEFAULT 5.0,
    disk_space_alert_pct DECIMAL(5,2) DEFAULT 80.0,
    replication_lag_alert_seconds DECIMAL(3,1) DEFAULT 5.0,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Application server configuration from BDD lines 133-155
CREATE TABLE application_server_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_name VARCHAR(200) NOT NULL,
    
    -- Resource allocation from BDD lines 138-142
    cpu_cores INTEGER NOT NULL, -- 1 core per 50 concurrent users
    memory_gb INTEGER NOT NULL, -- 4GB base + 100MB per user
    jvm_heap_gb INTEGER NOT NULL, -- 70% of allocated RAM
    thread_pool_size INTEGER NOT NULL, -- 256 threads per HTTP port
    concurrent_users_capacity INTEGER NOT NULL,
    
    -- Service parameters from BDD lines 144-148
    session_timeout_minutes INTEGER DEFAULT 30,
    max_file_upload_mb INTEGER DEFAULT 10,
    connection_timeout_seconds INTEGER DEFAULT 60,
    request_timeout_seconds INTEGER DEFAULT 120,
    
    -- Monitoring configuration from BDD lines 149-154
    jvm_heap_alert_pct DECIMAL(5,2) DEFAULT 85.0,
    thread_pool_alert_pct DECIMAL(5,2) DEFAULT 80.0,
    response_time_alert_seconds DECIMAL(3,1) DEFAULT 3.0,
    error_rate_alert_pct DECIMAL(5,2) DEFAULT 5.0,
    
    deployed_by VARCHAR(50) NOT NULL,
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Integration service configuration from BDD lines 156-178
CREATE TABLE integration_service_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(200) NOT NULL,
    
    -- Integration architecture from BDD lines 161-165
    technology_stack VARCHAR(100) DEFAULT 'Spring Boot application',
    deployment_type VARCHAR(50) DEFAULT 'Standalone JAR',
    message_queue_type VARCHAR(50) DEFAULT 'RabbitMQ',
    etl_technology VARCHAR(50) DEFAULT 'Custom Java',
    error_handling_pattern VARCHAR(50) DEFAULT 'Circuit breaker',
    
    -- Synchronization parameters from BDD lines 166-171
    sync_frequency_critical VARCHAR(20) DEFAULT 'Real-time',
    sync_frequency_bulk VARCHAR(20) DEFAULT 'Daily',
    batch_size INTEGER DEFAULT 1000,
    retry_attempts INTEGER DEFAULT 3,
    conflict_resolution_strategy VARCHAR(100) DEFAULT 'HR system wins for personal data',
    
    -- Data mapping configuration from BDD lines 172-177
    field_mappings JSONB NOT NULL,
    transformation_rules JSONB,
    validation_rules JSONB,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. SECURITY AND ACCESS CONTROL
-- =============================================================================

-- Multi-layer security implementation from BDD lines 183-205
CREATE TABLE security_access_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    security_policy_name VARCHAR(200) NOT NULL,
    
    -- Security layers from BDD lines 187-192
    authentication_method VARCHAR(50) DEFAULT 'Multi-factor authentication',
    authorization_model VARCHAR(50) DEFAULT 'Role-based access control',
    encryption_at_rest VARCHAR(20) DEFAULT 'AES-256',
    encryption_in_transit VARCHAR(20) DEFAULT 'TLS 1.2+',
    audit_logging_enabled BOOLEAN DEFAULT true,
    
    -- Compliance alignment
    gdpr_article_32_compliant BOOLEAN DEFAULT true,
    sox_compliant BOOLEAN DEFAULT true,
    pci_dss_compliant BOOLEAN DEFAULT true,
    
    -- Role-based permissions from BDD lines 193-198
    role_permissions JSONB NOT NULL,
    
    -- Data protection controls from BDD lines 199-204
    field_level_encryption_fields TEXT[],
    data_masking_environments TEXT[],
    access_logging_scope VARCHAR(50) DEFAULT 'Complete audit trail',
    data_retention_management BOOLEAN DEFAULT true,
    
    implemented_by VARCHAR(50) NOT NULL,
    implemented_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User account lifecycle management from BDD lines 206-228
CREATE TABLE user_account_lifecycle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES enhanced_employee_profiles(id),
    
    -- Account management policies from BDD lines 210-215
    password_policy JSONB NOT NULL, -- Min 8 chars, complexity, 90-day expiry
    account_lockout_config JSONB NOT NULL, -- 5 failed attempts, 30-minute lockout
    privileged_access_approval BOOLEAN DEFAULT false,
    quarterly_access_review BOOLEAN DEFAULT true,
    
    -- Account provisioning from BDD lines 216-221
    provisioning_automation_level VARCHAR(20) DEFAULT 'Semi-automated',
    hr_approval_required BOOLEAN DEFAULT true,
    manager_approval_required BOOLEAN DEFAULT true,
    workflow_system_integration BOOLEAN DEFAULT true,
    
    -- Security monitoring from BDD lines 222-227
    behavioral_analysis_enabled BOOLEAN DEFAULT true,
    permission_change_monitoring BOOLEAN DEFAULT true,
    failed_access_monitoring BOOLEAN DEFAULT true,
    data_export_monitoring BOOLEAN DEFAULT true,
    
    -- Account status tracking
    account_created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP WITH TIME ZONE,
    next_password_change_required TIMESTAMP WITH TIME ZONE,
    
    managed_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. SYSTEM MONITORING AND MAINTENANCE
-- =============================================================================

-- System monitoring infrastructure from BDD lines 233-255
CREATE TABLE system_monitoring_infrastructure (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monitoring_component VARCHAR(100) NOT NULL,
    
    -- Monitoring components from BDD lines 238-242
    component_type VARCHAR(50) NOT NULL CHECK (component_type IN (
        'Zabbix agents', 'Application monitoring', 'Database monitoring', 'Integration monitoring'
    )),
    configuration JSONB NOT NULL,
    alert_thresholds JSONB NOT NULL,
    
    -- KPIs from BDD lines 244-248
    target_response_time_seconds DECIMAL(3,1) DEFAULT 2.0,
    target_throughput_req_per_min INTEGER DEFAULT 1000,
    target_data_completeness_pct DECIMAL(5,2) DEFAULT 99.0,
    target_data_accuracy_pct DECIMAL(5,2) DEFAULT 99.5,
    target_integration_success_rate_pct DECIMAL(5,2) DEFAULT 99.0,
    target_integration_latency_seconds DECIMAL(3,1) DEFAULT 5.0,
    
    -- Proactive monitoring from BDD lines 249-254
    predictive_alerts_enabled BOOLEAN DEFAULT true,
    capacity_planning_enabled BOOLEAN DEFAULT true,
    performance_baselines_enabled BOOLEAN DEFAULT true,
    sla_monitoring_enabled BOOLEAN DEFAULT true,
    
    deployed_by VARCHAR(50) NOT NULL,
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Backup and recovery procedures from BDD lines 256-277
CREATE TABLE backup_recovery_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procedure_name VARCHAR(200) NOT NULL,
    
    -- Backup strategy from BDD lines 260-265
    backup_type VARCHAR(50) NOT NULL CHECK (backup_type IN (
        'Full database backup', 'Incremental backup', 'Application backup', 'Configuration backup'
    )),
    backup_frequency VARCHAR(50) NOT NULL,
    retention_period VARCHAR(50) NOT NULL,
    storage_location VARCHAR(100) NOT NULL,
    backup_purpose TEXT NOT NULL,
    
    -- Recovery procedures from BDD lines 266-271
    rto_target_hours DECIMAL(4,1), -- Recovery Time Objective
    rpo_target_hours DECIMAL(4,1), -- Recovery Point Objective
    recovery_procedure TEXT NOT NULL,
    validation_method TEXT NOT NULL,
    
    -- Backup validation from BDD lines 272-276
    integrity_validation_schedule VARCHAR(50),
    recovery_testing_schedule VARCHAR(50),
    performance_testing_schedule VARCHAR(50),
    success_criteria TEXT,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. ORGANIZATIONAL STRUCTURE MANAGEMENT
-- =============================================================================

-- Department hierarchy with technical controls from BDD lines 282-302
CREATE TABLE department_hierarchy_enhanced (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_name VARCHAR(200) NOT NULL UNIQUE,
    parent_department_id UUID REFERENCES department_hierarchy_enhanced(id),
    manager_employee_id UUID REFERENCES enhanced_employee_profiles(id),
    
    -- Hierarchy constraints
    hierarchy_level INTEGER NOT NULL DEFAULT 1,
    hierarchy_path TEXT, -- Materialized path for fast queries
    
    -- Department properties from BDD lines 294-298
    participates_in_approval BOOLEAN DEFAULT true,
    budget_responsibility BOOLEAN DEFAULT false,
    budget_center_code VARCHAR(50),
    scheduling_authority_level VARCHAR(20) CHECK (scheduling_authority_level IN ('None', 'Limited', 'Full')),
    
    -- System integration
    bpms_integration_enabled BOOLEAN DEFAULT true,
    erp_integration_enabled BOOLEAN DEFAULT false,
    planning_service_integration BOOLEAN DEFAULT true,
    reporting_service_integration BOOLEAN DEFAULT true,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent circular references
    CONSTRAINT no_self_reference CHECK (id != parent_department_id),
    CONSTRAINT valid_hierarchy_level CHECK (hierarchy_level BETWEEN 1 AND 10)
);

-- Deputy management with workflow automation from BDD lines 303-323
CREATE TABLE deputy_management_workflow (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES department_hierarchy_enhanced(id),
    deputy_employee_id UUID NOT NULL REFERENCES enhanced_employee_profiles(id),
    
    -- Deputy assignment from BDD lines 308-313
    assignment_type VARCHAR(20) DEFAULT 'Temporary deputy',
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    assignment_reason TEXT NOT NULL,
    notification_scope VARCHAR(50) DEFAULT 'All department',
    
    -- Authority and workflow from BDD lines 314-319
    schedule_approval_authority BOOLEAN DEFAULT true,
    request_approval_authority BOOLEAN DEFAULT true,
    workflow_participation_enabled BOOLEAN DEFAULT true,
    team_management_authority BOOLEAN DEFAULT true,
    
    -- System integration
    planning_service_role_assigned BOOLEAN DEFAULT false,
    bpms_approval_routing_updated BOOLEAN DEFAULT false,
    workflow_engine_authority_delegated BOOLEAN DEFAULT false,
    permissions_inherited BOOLEAN DEFAULT false,
    
    -- Automation tracking
    notification_sent BOOLEAN DEFAULT false,
    permissions_activated BOOLEAN DEFAULT false,
    permissions_will_revert_automatically BOOLEAN DEFAULT true,
    
    assigned_by VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_deputy_period CHECK (period_end > period_start),
    CONSTRAINT future_period_start CHECK (period_start >= CURRENT_DATE)
);

-- =============================================================================
-- 6. BULK OPERATIONS AND ENTERPRISE INTEGRATION
-- =============================================================================

-- Enterprise-scale bulk operations from BDD lines 328-351
CREATE TABLE bulk_operations_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_name VARCHAR(200) NOT NULL,
    
    -- Bulk operation types from BDD lines 333-338
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN (
        'Department transfer', 'Work rule assignment', 'Skill group changes', 
        'Performance standard updates', 'Mass termination'
    )),
    operation_scope VARCHAR(50) NOT NULL,
    target_employee_count INTEGER NOT NULL,
    
    -- Enterprise features from BDD lines 340-344
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    error_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    rollback_capability BOOLEAN DEFAULT true,
    parallel_processing_enabled BOOLEAN DEFAULT true,
    
    -- Performance optimization
    batch_size INTEGER DEFAULT 1000,
    thread_count INTEGER DEFAULT 4,
    processing_start_time TIMESTAMP WITH TIME ZONE,
    estimated_completion_time TIMESTAMP WITH TIME ZONE,
    
    -- Operation status
    operation_status VARCHAR(20) DEFAULT 'Pending' CHECK (operation_status IN (
        'Pending', 'Running', 'Completed', 'Failed', 'Rolled Back'
    )),
    
    -- Reporting from BDD lines 345-350
    operation_summary JSONB,
    error_analysis JSONB,
    impact_assessment JSONB,
    compliance_report JSONB,
    
    initiated_by VARCHAR(50) NOT NULL,
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Enterprise personnel synchronization from BDD lines 352-374
CREATE TABLE enterprise_integration_sync (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_name VARCHAR(200) NOT NULL,
    
    -- Enterprise-scale integration from BDD lines 357-361
    integration_type VARCHAR(50) NOT NULL CHECK (integration_type IN (
        'Multi-system sync', 'Real-time events', 'Batch processing', 'Error resilience'
    )),
    scale_capacity VARCHAR(100), -- 5+ HR systems, 10K records/hour
    performance_target VARCHAR(100),
    
    -- Complex synchronization scenarios from BDD lines 362-367
    resolution_strategy VARCHAR(100),
    data_quality_target_pct DECIMAL(5,2) DEFAULT 99.9,
    conflict_resolution_rules JSONB,
    
    -- Enterprise monitoring from BDD lines 368-373
    success_rate_per_system JSONB,
    data_completeness_metrics JSONB,
    data_accuracy_metrics JSONB,
    performance_metrics JSONB,
    error_categorization JSONB,
    
    -- Status tracking
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    next_sync_scheduled TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'Active',
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. COMPLIANCE AND REGULATORY MANAGEMENT
-- =============================================================================

-- Regulatory compliance management from BDD lines 379-401
CREATE TABLE regulatory_compliance_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    regulation_name VARCHAR(100) NOT NULL,
    
    -- Regulatory frameworks from BDD lines 384-388
    regulation_type VARCHAR(50) NOT NULL CHECK (regulation_type IN (
        'GDPR', 'SOX', 'Labor Law', 'Industry Standards'
    )),
    requirements_description TEXT NOT NULL,
    implementation_details JSONB NOT NULL,
    monitoring_configuration JSONB,
    
    -- Compliance automation from BDD lines 389-394
    data_retention_automated BOOLEAN DEFAULT true,
    access_review_automated BOOLEAN DEFAULT true,
    privacy_impact_assessment_automated BOOLEAN DEFAULT true,
    audit_trail_automated BOOLEAN DEFAULT true,
    
    -- Compliance reporting from BDD lines 395-400
    privacy_compliance_reporting BOOLEAN DEFAULT true,
    security_compliance_reporting BOOLEAN DEFAULT true,
    regulatory_compliance_reporting BOOLEAN DEFAULT true,
    audit_readiness_reporting BOOLEAN DEFAULT true,
    
    compliance_status VARCHAR(20) DEFAULT 'Compliant' CHECK (compliance_status IN (
        'Compliant', 'Non-Compliant', 'Under Review', 'Remediation Required'
    )),
    
    last_assessment_date DATE,
    next_assessment_due DATE,
    
    managed_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Comprehensive audit management from BDD lines 402-424
CREATE TABLE audit_management_comprehensive (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_category VARCHAR(50) NOT NULL CHECK (audit_category IN (
        'Data access', 'Data modifications', 'System access', 'Administrative actions'
    )),
    
    -- Audit data capture from BDD lines 407-411
    captured_data_types JSONB NOT NULL,
    retention_period_years INTEGER NOT NULL,
    access_control_rules JSONB NOT NULL,
    
    -- Audit analytics from BDD lines 412-417
    access_pattern_analysis_enabled BOOLEAN DEFAULT true,
    data_change_tracking_enabled BOOLEAN DEFAULT true,
    compliance_monitoring_enabled BOOLEAN DEFAULT true,
    performance_impact_monitoring BOOLEAN DEFAULT true,
    
    -- Analytics configuration
    machine_learning_anomaly_detection BOOLEAN DEFAULT true,
    rule_based_analysis BOOLEAN DEFAULT true,
    automated_compliance_checking BOOLEAN DEFAULT true,
    
    -- Audit reporting from BDD lines 418-423
    access_reports_enabled BOOLEAN DEFAULT true,
    change_reports_enabled BOOLEAN DEFAULT true,
    compliance_reports_enabled BOOLEAN DEFAULT true,
    security_reports_enabled BOOLEAN DEFAULT true,
    
    -- Report automation
    self_service_reporting BOOLEAN DEFAULT true,
    automated_generation BOOLEAN DEFAULT true,
    scheduled_delivery BOOLEAN DEFAULT true,
    automated_distribution BOOLEAN DEFAULT true,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. DISASTER RECOVERY AND BUSINESS CONTINUITY
-- =============================================================================

-- Disaster recovery planning from BDD lines 429-451
CREATE TABLE disaster_recovery_planning (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_component VARCHAR(100) NOT NULL,
    
    -- Recovery requirements from BDD lines 434-438
    criticality_level VARCHAR(20) NOT NULL CHECK (criticality_level IN ('Critical', 'Important', 'Standard')),
    rto_target_hours DECIMAL(4,1) NOT NULL, -- Recovery Time Objective
    rpo_target_minutes DECIMAL(6,1) NOT NULL, -- Recovery Point Objective
    recovery_priority INTEGER NOT NULL,
    
    -- Recovery procedures from BDD lines 439-444
    recovery_scenario VARCHAR(100) NOT NULL,
    recovery_procedure TEXT NOT NULL,
    required_resources JSONB,
    validation_steps JSONB,
    
    -- Business continuity from BDD lines 445-450
    alternative_access_methods JSONB,
    data_synchronization_config JSONB,
    communication_plan JSONB,
    staff_readiness_procedures JSONB,
    
    -- Testing and validation
    last_test_date DATE,
    test_frequency VARCHAR(50),
    test_results JSONB,
    improvement_actions JSONB,
    
    planned_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance optimization for enterprise scale from BDD lines 452-474
CREATE TABLE performance_optimization_enterprise (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_layer VARCHAR(50) NOT NULL CHECK (optimization_layer IN (
        'Database layer', 'Application layer', 'Network layer', 'Storage layer'
    )),
    
    -- Optimization techniques from BDD lines 457-461
    optimization_techniques JSONB NOT NULL,
    expected_improvement_pct DECIMAL(5,2),
    monitoring_metrics JSONB,
    
    -- Caching strategies from BDD lines 462-467
    cache_type VARCHAR(50),
    cache_implementation JSONB,
    cache_use_case TEXT,
    performance_gain_target_pct DECIMAL(5,2),
    
    -- Performance monitoring from BDD lines 468-473
    response_time_target_seconds DECIMAL(3,1) DEFAULT 2.0,
    throughput_target_req_per_min INTEGER DEFAULT 1000,
    error_rate_target_pct DECIMAL(4,2) DEFAULT 0.1,
    resource_utilization_target_pct DECIMAL(5,2) DEFAULT 70.0,
    
    -- Alert thresholds
    response_time_alert_seconds DECIMAL(3,1) DEFAULT 3.0,
    throughput_alert_req_per_min INTEGER DEFAULT 500,
    error_rate_alert_pct DECIMAL(4,2) DEFAULT 1.0,
    resource_utilization_alert_pct DECIMAL(5,2) DEFAULT 85.0,
    
    implemented_by VARCHAR(50) NOT NULL,
    implemented_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate department hierarchy (prevent cycles)
CREATE OR REPLACE FUNCTION validate_department_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    v_cycle_check INTEGER;
BEGIN
    -- Check for circular references in department hierarchy
    WITH RECURSIVE hierarchy_check AS (
        SELECT id, parent_department_id, 1 as level
        FROM department_hierarchy_enhanced
        WHERE id = NEW.id
        
        UNION ALL
        
        SELECT d.id, d.parent_department_id, h.level + 1
        FROM department_hierarchy_enhanced d
        INNER JOIN hierarchy_check h ON d.id = h.parent_department_id
        WHERE h.level < 10 -- Prevent infinite recursion
    )
    SELECT COUNT(*) INTO v_cycle_check
    FROM hierarchy_check
    WHERE parent_department_id = NEW.id;
    
    IF v_cycle_check > 0 THEN
        RAISE EXCEPTION 'Circular reference detected in department hierarchy';
    END IF;
    
    -- Update hierarchy path
    NEW.hierarchy_path := (
        SELECT STRING_AGG(dept_name, ' > ' ORDER BY level)
        FROM (
            WITH RECURSIVE path AS (
                SELECT id, department_name as dept_name, 1 as level
                FROM department_hierarchy_enhanced
                WHERE id = NEW.id
                
                UNION ALL
                
                SELECT d.id, d.department_name, p.level + 1
                FROM department_hierarchy_enhanced d
                INNER JOIN path p ON d.id = NEW.parent_department_id
            )
            SELECT dept_name, level FROM path
        ) path_query
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to manage deputy permissions
CREATE OR REPLACE FUNCTION manage_deputy_permissions(
    p_deputy_id UUID,
    p_department_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS void AS $$
BEGIN
    -- Activate deputy permissions if period is current
    IF CURRENT_DATE BETWEEN p_start_date AND p_end_date THEN
        UPDATE deputy_management_workflow
        SET permissions_activated = true,
            planning_service_role_assigned = true,
            bpms_approval_routing_updated = true,
            workflow_engine_authority_delegated = true,
            permissions_inherited = true
        WHERE deputy_employee_id = p_deputy_id 
        AND department_id = p_department_id;
        
    -- Deactivate if period has ended
    ELSIF CURRENT_DATE > p_end_date THEN
        UPDATE deputy_management_workflow
        SET permissions_activated = false,
            planning_service_role_assigned = false,
            bpms_approval_routing_updated = false,
            workflow_engine_authority_delegated = false,
            permissions_inherited = false
        WHERE deputy_employee_id = p_deputy_id 
        AND department_id = p_department_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to track bulk operation progress
CREATE OR REPLACE FUNCTION update_bulk_operation_progress(
    p_operation_id UUID,
    p_processed_count INTEGER,
    p_success_count INTEGER,
    p_error_count INTEGER
) RETURNS void AS $$
DECLARE
    v_total_count INTEGER;
    v_progress_pct DECIMAL(5,2);
BEGIN
    -- Get total count
    SELECT target_employee_count INTO v_total_count
    FROM bulk_operations_tracking
    WHERE id = p_operation_id;
    
    -- Calculate progress percentage
    v_progress_pct := (p_processed_count::DECIMAL / v_total_count) * 100;
    
    -- Update progress
    UPDATE bulk_operations_tracking
    SET progress_percentage = v_progress_pct,
        success_count = p_success_count,
        error_count = p_error_count,
        operation_status = CASE 
            WHEN v_progress_pct >= 100 THEN 'Completed'
            WHEN p_error_count > (p_processed_count * 0.1) THEN 'Failed'
            ELSE 'Running'
        END
    WHERE id = p_operation_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to validate department hierarchy
CREATE TRIGGER trigger_validate_department_hierarchy
    BEFORE INSERT OR UPDATE ON department_hierarchy_enhanced
    FOR EACH ROW
    EXECUTE FUNCTION validate_department_hierarchy();

-- Trigger to auto-manage deputy permissions
CREATE OR REPLACE FUNCTION auto_manage_deputy_permissions()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM manage_deputy_permissions(
        NEW.deputy_employee_id,
        NEW.department_id,
        NEW.period_start,
        NEW.period_end
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_manage_deputy_permissions
    AFTER INSERT OR UPDATE ON deputy_management_workflow
    FOR EACH ROW
    EXECUTE FUNCTION auto_manage_deputy_permissions();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Employee management indexes
CREATE INDEX idx_enhanced_employees_personnel_number ON enhanced_employee_profiles(personnel_number);
CREATE INDEX idx_enhanced_employees_department ON enhanced_employee_profiles(department_id);
CREATE INDEX idx_enhanced_employees_status ON enhanced_employee_profiles(account_status);
CREATE INDEX idx_employee_skills_employee ON employee_skill_assignments(employee_id);
CREATE INDEX idx_employee_skills_main_group ON employee_skill_assignments(employee_id, is_main_group);

-- Department hierarchy indexes
CREATE INDEX idx_department_hierarchy_parent ON department_hierarchy_enhanced(parent_department_id);
CREATE INDEX idx_department_hierarchy_manager ON department_hierarchy_enhanced(manager_employee_id);
CREATE INDEX idx_department_hierarchy_path ON department_hierarchy_enhanced USING gin(to_tsvector('english', hierarchy_path));

-- Deputy management indexes
CREATE INDEX idx_deputy_management_department ON deputy_management_workflow(department_id);
CREATE INDEX idx_deputy_management_deputy ON deputy_management_workflow(deputy_employee_id);
CREATE INDEX idx_deputy_management_period ON deputy_management_workflow(period_start, period_end);

-- Bulk operations indexes
CREATE INDEX idx_bulk_operations_status ON bulk_operations_tracking(operation_status);
CREATE INDEX idx_bulk_operations_type ON bulk_operations_tracking(operation_type);
CREATE INDEX idx_bulk_operations_initiated ON bulk_operations_tracking(initiated_at);

-- Compliance and audit indexes
CREATE INDEX idx_regulatory_compliance_type ON regulatory_compliance_management(regulation_type);
CREATE INDEX idx_audit_management_category ON audit_management_comprehensive(audit_category);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample department hierarchy
INSERT INTO department_hierarchy_enhanced (
    department_name, parent_department_id, hierarchy_level, 
    participates_in_approval, scheduling_authority_level, created_by
) VALUES 
('Regional Call Center', NULL, 1, true, 'Full', 'admin'),
('Technical Support', (SELECT id FROM department_hierarchy_enhanced WHERE department_name = 'Regional Call Center'), 2, true, 'Full', 'admin'),
('Sales Team', (SELECT id FROM department_hierarchy_enhanced WHERE department_name = 'Regional Call Center'), 2, true, 'Limited', 'admin');

-- Sample enhanced employee profile
INSERT INTO enhanced_employee_profiles (
    personnel_number, last_name, first_name, patronymic,
    department_id, position_id, hire_date, wfm_login, created_by
) VALUES (
    'EMP001', 'Иванов', 'Иван', 'Иванович',
    (SELECT id FROM department_hierarchy_enhanced WHERE department_name = 'Technical Support'),
    uuid_generate_v4(), '2025-01-01', 'i.ivanov', 'admin'
);

-- Sample regulatory compliance
INSERT INTO regulatory_compliance_management (
    regulation_name, regulation_type, requirements_description,
    implementation_details, managed_by
) VALUES 
('GDPR Compliance', 'GDPR', 'Data protection and privacy rights', 
 '{"consent_management": true, "data_encryption": true}'::jsonb, 'admin'),
('SOX Financial Controls', 'SOX', 'Financial controls and audit trails',
 '{"change_management": true, "access_controls": true}'::jsonb, 'admin');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO hr_administrators;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO department_managers;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO hr_administrators;