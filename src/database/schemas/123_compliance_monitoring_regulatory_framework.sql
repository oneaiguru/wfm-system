-- =====================================================================================
-- Schema 123: Compliance Monitoring and Regulatory Framework
-- =====================================================================================
-- Description: Comprehensive compliance monitoring for Russian labor law, EU GDPR,
--             automated regulatory reporting, and real-time violation detection
-- Business Value: Legal compliance automation, risk mitigation, regulatory reporting
-- Dependencies: Schema 001 (base), Schema 017 (time attendance), Schema 019 (ZUP integration)
-- Complexity: ADVANCED - Full regulatory compliance automation with Russian specifics
-- =====================================================================================

-- Russian Labor Law Compliance Framework
-- =====================================================================================

-- Russian labor law rules and regulations configuration
CREATE TABLE labor_law_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_code VARCHAR(50) NOT NULL, -- e.g., 'TK_RF_108', 'TK_RF_99'
    rule_name VARCHAR(200) NOT NULL,
    rule_category VARCHAR(50) NOT NULL, -- 'working_time', 'overtime', 'breaks', 'vacation', 'night_work'
    
    -- Legal reference
    legal_source VARCHAR(100) NOT NULL, -- 'TK_RF' (Трудовой кодекс РФ), 'Постановление_Правительства', etc.
    article_number VARCHAR(20), -- Article number in legal document
    paragraph_number VARCHAR(10), -- Paragraph within article
    effective_from DATE NOT NULL,
    effective_until DATE, -- NULL if still effective
    
    -- Rule definition
    rule_description TEXT NOT NULL,
    rule_text_ru TEXT, -- Original Russian text
    rule_parameters JSONB, -- Parameters for automated checking
    validation_logic JSONB, -- Logic for automated validation
    
    -- Compliance checking
    check_frequency VARCHAR(20) DEFAULT 'daily', -- 'real_time', 'hourly', 'daily', 'weekly', 'monthly'
    severity_level VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    violation_penalty_type VARCHAR(30), -- 'warning', 'fine', 'administrative', 'criminal'
    
    -- Business impact
    compliance_scope TEXT[], -- ['all_employees', 'shift_workers', 'management', 'part_time']
    exception_conditions JSONB, -- Conditions where rule doesn't apply
    grace_period_days INTEGER DEFAULT 0, -- Grace period for violations
    
    -- Automation
    automated_check BOOLEAN DEFAULT true,
    automated_remedy BOOLEAN DEFAULT false, -- Can violations be auto-fixed?
    notification_required BOOLEAN DEFAULT true,
    
    -- Metadata
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by VARCHAR(100),
    
    UNIQUE(rule_code)
);

-- Russian working time classifications and limits
CREATE TABLE working_time_regulations (
    regulation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_type VARCHAR(50) NOT NULL, -- 'normal_hours', 'overtime', 'night_work', 'weekend_work'
    employee_category VARCHAR(50) NOT NULL, -- 'standard', 'pregnant', 'minor', 'disabled', 'night_shift'
    
    -- Time limits (per Russian Labor Code)
    daily_limit_hours DECIMAL(4,2), -- Normal daily limit
    weekly_limit_hours DECIMAL(4,2), -- Normal weekly limit
    monthly_limit_hours DECIMAL(5,2), -- Monthly limit
    annual_limit_hours DECIMAL(6,2), -- Annual limit
    
    -- Overtime regulations
    daily_overtime_limit_hours DECIMAL(4,2), -- Max overtime per day
    monthly_overtime_limit_hours DECIMAL(5,2), -- Max overtime per month
    annual_overtime_limit_hours DECIMAL(6,2), -- Max overtime per year
    
    -- Break requirements
    minimum_break_duration_minutes INTEGER, -- Minimum break duration
    break_frequency_hours DECIMAL(4,2), -- How often breaks are required
    lunch_break_duration_minutes INTEGER, -- Required lunch break
    
    -- Rest periods
    minimum_daily_rest_hours DECIMAL(4,2), -- Between shifts
    minimum_weekly_rest_hours DECIMAL(4,2), -- Weekly rest period
    continuous_work_limit_days INTEGER, -- Max days without rest
    
    -- Night work specifics (22:00-06:00 per Russian law)
    night_work_hour_reduction DECIMAL(3,2), -- Hour reduction for night work
    night_work_age_minimum INTEGER DEFAULT 18, -- Minimum age for night work
    night_work_prohibited_categories TEXT[], -- Who cannot work nights
    
    -- Special conditions
    hazardous_work_limit_hours DECIMAL(4,2), -- Limit for hazardous conditions
    computer_work_limit_hours DECIMAL(4,2), -- VDT work limits
    shift_duration_limit_hours DECIMAL(4,2), -- Maximum shift duration
    
    -- Legal basis
    legal_reference VARCHAR(100) NOT NULL,
    effective_from DATE NOT NULL,
    effective_until DATE,
    
    -- Enforcement
    monitoring_required BOOLEAN DEFAULT true,
    violation_severity VARCHAR(20) DEFAULT 'high',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vacation and leave compliance (Russian specifics)
CREATE TABLE vacation_leave_regulations (
    regulation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leave_type VARCHAR(50) NOT NULL, -- 'annual_vacation', 'sick_leave', 'maternity', 'paternity', 'study'
    employee_category VARCHAR(50) NOT NULL, -- 'standard', 'pregnant', 'minor', 'veteran', 'disabled'
    
    -- Entitlement rules (per Russian Labor Code)
    minimum_days_per_year INTEGER, -- Minimum annual entitlement
    accrual_rate_per_month DECIMAL(4,2), -- Days accrued per month worked
    maximum_carryover_days INTEGER, -- Days that can carry over to next year
    
    -- Timing requirements
    minimum_continuous_days INTEGER, -- Minimum continuous vacation days
    maximum_split_periods INTEGER, -- How many periods vacation can be split into
    advance_notice_days INTEGER, -- Required notice period
    
    -- Scheduling restrictions
    peak_period_restrictions JSONB, -- When vacation may be restricted
    mandatory_vacation_periods JSONB, -- When vacation must be taken
    blackout_periods JSONB, -- When vacation is prohibited
    
    -- Compensation rules
    compensation_calculation_method VARCHAR(50), -- How vacation pay is calculated
    advance_payment_required BOOLEAN DEFAULT true, -- Pay before vacation starts
    unused_vacation_compensation BOOLEAN, -- Pay for unused vacation on termination
    
    -- Special provisions
    additional_days_conditions JSONB, -- Conditions for additional vacation days
    medical_certificate_required BOOLEAN, -- For sick leave
    government_approval_required BOOLEAN, -- For certain types of leave
    
    -- Compliance monitoring
    tracking_required BOOLEAN DEFAULT true,
    documentation_required TEXT[], -- Required documentation
    approval_workflow JSONB, -- Approval process definition
    
    -- Legal basis
    legal_reference VARCHAR(100) NOT NULL,
    effective_from DATE NOT NULL,
    effective_until DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Compliance Monitoring and Violation Detection
-- =====================================================================================

-- Real-time compliance monitoring
CREATE TABLE compliance_monitoring (
    monitor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    monitor_name VARCHAR(100) NOT NULL,
    monitor_type VARCHAR(50) NOT NULL, -- 'real_time', 'batch', 'scheduled', 'event_triggered'
    
    -- Monitoring scope
    scope_type VARCHAR(30) NOT NULL, -- 'employee', 'department', 'site', 'company'
    scope_entities JSONB, -- List of entities being monitored
    
    -- Rules being monitored
    monitored_rules UUID[] NOT NULL, -- Array of labor_law_rules.rule_id
    monitoring_frequency VARCHAR(20) DEFAULT 'daily',
    
    -- Detection configuration
    detection_sensitivity VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high'
    early_warning_enabled BOOLEAN DEFAULT true,
    early_warning_threshold DECIMAL(3,2) DEFAULT 0.8, -- Warn at 80% of limit
    
    -- Notification settings
    immediate_notification BOOLEAN DEFAULT true,
    notification_recipients TEXT[],
    escalation_rules JSONB,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'paused', 'stopped'
    last_check_at TIMESTAMP WITH TIME ZONE,
    next_check_at TIMESTAMP WITH TIME ZONE,
    
    -- Performance
    checks_performed BIGINT DEFAULT 0,
    violations_detected BIGINT DEFAULT 0,
    false_positives BIGINT DEFAULT 0,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Compliance violation records
CREATE TABLE compliance_violations (
    violation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    monitor_id UUID REFERENCES compliance_monitoring(monitor_id),
    rule_id UUID REFERENCES labor_law_rules(rule_id),
    
    -- Violation context
    violation_type VARCHAR(50) NOT NULL, -- 'overtime_excess', 'insufficient_break', 'night_work_violation'
    violation_date DATE NOT NULL,
    detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Affected parties
    employee_id VARCHAR(100) NOT NULL,
    department_id VARCHAR(100),
    manager_id VARCHAR(100),
    site_id VARCHAR(100),
    
    -- Violation details
    violation_description TEXT NOT NULL,
    violation_data JSONB, -- Detailed data about the violation
    threshold_value DECIMAL(10,4), -- What the limit was
    actual_value DECIMAL(10,4), -- What the actual value was
    excess_amount DECIMAL(10,4), -- How much over the limit
    
    -- Risk assessment
    severity_level VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    risk_score DECIMAL(3,2), -- Overall risk score (0.0-1.0)
    legal_risk_level VARCHAR(20), -- Legal consequences risk
    financial_risk_rubles DECIMAL(12,2), -- Potential financial impact
    
    -- Root cause analysis
    root_cause_category VARCHAR(50), -- 'scheduling_error', 'system_failure', 'policy_violation'
    contributing_factors TEXT[],
    systemic_issue BOOLEAN DEFAULT false, -- Is this part of a pattern?
    
    -- Resolution tracking
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'dismissed'
    assigned_to VARCHAR(100), -- Who is responsible for resolution
    resolution_deadline TIMESTAMP WITH TIME ZONE,
    resolution_description TEXT,
    resolution_date TIMESTAMP WITH TIME ZONE,
    
    -- Preventive measures
    preventive_actions_taken TEXT[],
    policy_changes_needed BOOLEAN DEFAULT false,
    training_required BOOLEAN DEFAULT false,
    system_changes_needed BOOLEAN DEFAULT false,
    
    -- Compliance reporting
    reported_to_authorities BOOLEAN DEFAULT false,
    reporting_date TIMESTAMP WITH TIME ZONE,
    authority_response TEXT,
    fine_amount_rubles DECIMAL(10,2),
    
    -- Business impact
    operational_impact VARCHAR(20), -- 'none', 'low', 'medium', 'high'
    customer_impact VARCHAR(20), -- Impact on customer service
    employee_impact VARCHAR(20), -- Impact on affected employee
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (violation_date);

-- Create monthly partitions for compliance violations
CREATE TABLE compliance_violations_2024_01 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE compliance_violations_2024_02 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE compliance_violations_2024_03 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE compliance_violations_2024_04 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE compliance_violations_2024_05 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE compliance_violations_2024_06 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE compliance_violations_2024_07 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE compliance_violations_2024_08 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE compliance_violations_2024_09 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE compliance_violations_2024_10 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE compliance_violations_2024_11 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE compliance_violations_2024_12 PARTITION OF compliance_violations
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE compliance_violations_2025_01 PARTITION OF compliance_violations
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Regulatory Reporting and Documentation
-- =====================================================================================

-- Regulatory reporting requirements
CREATE TABLE regulatory_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_code VARCHAR(50) NOT NULL, -- 'T-13', 'P-4', 'SZV-M', etc.
    report_name VARCHAR(200) NOT NULL,
    regulatory_authority VARCHAR(100) NOT NULL, -- 'Rostrud', 'FNS', 'PFR', 'FSS'
    
    -- Reporting requirements
    reporting_frequency VARCHAR(20) NOT NULL, -- 'monthly', 'quarterly', 'annually', 'on_demand'
    submission_deadline_days INTEGER, -- Days after period end
    submission_method VARCHAR(30), -- 'electronic', 'paper', 'web_portal', 'api'
    
    -- Report structure
    data_requirements JSONB NOT NULL, -- What data needs to be included
    format_specification JSONB, -- File format requirements
    validation_rules JSONB, -- Data validation rules
    
    -- Generation configuration
    data_sources TEXT[], -- Which tables/views provide the data
    calculation_logic JSONB, -- How to calculate report values
    aggregation_rules JSONB, -- How to aggregate data
    
    -- Compliance tracking
    mandatory BOOLEAN DEFAULT true,
    penalties_for_late DECIMAL(10,2), -- Penalty amount for late submission
    penalties_for_incorrect DECIMAL(10,2), -- Penalty for incorrect data
    
    -- Template management
    template_version VARCHAR(20),
    template_effective_from DATE,
    template_path TEXT, -- Path to report template file
    
    -- Automation
    auto_generation BOOLEAN DEFAULT false,
    auto_submission BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT true,
    approval_workflow JSONB,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(report_code, template_version)
);

-- Generated regulatory reports tracking
CREATE TABLE regulatory_report_instances (
    instance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES regulatory_reports(report_id),
    
    -- Reporting period
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    report_year INTEGER GENERATED ALWAYS AS (EXTRACT(YEAR FROM reporting_period_end)) STORED,
    report_month INTEGER GENERATED ALWAYS AS (EXTRACT(MONTH FROM reporting_period_end)) STORED,
    
    -- Generation details
    generation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    generated_by VARCHAR(100) NOT NULL,
    generation_method VARCHAR(20) DEFAULT 'manual', -- 'manual', 'scheduled', 'automated'
    
    -- Report content
    report_data JSONB NOT NULL, -- The actual report data
    data_hash VARCHAR(64), -- Hash for integrity checking
    record_count INTEGER, -- Number of records in report
    
    -- Validation results
    validation_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'passed', 'failed'
    validation_errors JSONB, -- Validation error details
    data_quality_score DECIMAL(3,2), -- Quality score (0.0-1.0)
    
    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_by VARCHAR(100),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Submission tracking
    submission_status VARCHAR(20) DEFAULT 'not_submitted', -- 'not_submitted', 'submitted', 'accepted', 'rejected'
    submission_timestamp TIMESTAMP WITH TIME ZONE,
    submission_method VARCHAR(30),
    submission_reference VARCHAR(100), -- Reference number from authority
    
    -- Response from authority
    authority_response JSONB, -- Response from regulatory authority
    response_received_at TIMESTAMP WITH TIME ZONE,
    acceptance_confirmed BOOLEAN DEFAULT false,
    
    -- File management
    report_file_path TEXT, -- Path to generated report file
    report_file_format VARCHAR(20), -- File format (xlsx, xml, json, etc.)
    report_file_size_kb INTEGER,
    
    -- Corrections and resubmissions
    is_correction BOOLEAN DEFAULT false,
    corrects_instance_id UUID REFERENCES regulatory_report_instances(instance_id),
    correction_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (reporting_period_end);

-- Create yearly partitions for regulatory report instances
CREATE TABLE regulatory_report_instances_2023 PARTITION OF regulatory_report_instances
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE regulatory_report_instances_2024 PARTITION OF regulatory_report_instances
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE regulatory_report_instances_2025 PARTITION OF regulatory_report_instances
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Data Protection and GDPR Compliance
-- =====================================================================================

-- GDPR and Russian personal data law compliance
CREATE TABLE data_protection_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(100) NOT NULL,
    policy_type VARCHAR(50) NOT NULL, -- 'gdpr', 'russian_personal_data', 'corporate'
    
    -- Legal basis
    legal_framework VARCHAR(50) NOT NULL, -- 'GDPR', 'ФЗ-152', 'ФЗ-149'
    regulation_article VARCHAR(20),
    
    -- Policy definition
    policy_description TEXT NOT NULL,
    data_categories_covered TEXT[], -- Types of personal data covered
    processing_purposes TEXT[], -- Legitimate purposes for processing
    legal_basis_for_processing VARCHAR(100), -- GDPR Article 6 basis
    
    -- Data subject rights
    access_right_enabled BOOLEAN DEFAULT true,
    rectification_right_enabled BOOLEAN DEFAULT true,
    erasure_right_enabled BOOLEAN DEFAULT true,
    portability_right_enabled BOOLEAN DEFAULT true,
    objection_right_enabled BOOLEAN DEFAULT true,
    
    -- Technical and organizational measures
    encryption_required BOOLEAN DEFAULT true,
    access_controls JSONB, -- Access control requirements
    retention_period_days INTEGER, -- Data retention period
    deletion_requirements JSONB, -- How to delete data
    
    -- Consent management
    consent_required BOOLEAN DEFAULT true,
    consent_type VARCHAR(20), -- 'explicit', 'implied', 'legitimate_interest'
    consent_withdrawal_method TEXT,
    
    -- Breach notification
    breach_notification_required BOOLEAN DEFAULT true,
    notification_timeline_hours INTEGER DEFAULT 72, -- Hours to notify authority
    
    -- Cross-border transfers
    international_transfers_allowed BOOLEAN DEFAULT false,
    adequacy_decisions TEXT[], -- Countries with adequacy decisions
    safeguards_required JSONB, -- Required safeguards for transfers
    
    -- Compliance monitoring
    audit_frequency VARCHAR(20) DEFAULT 'annually', -- How often to audit
    compliance_officer VARCHAR(100), -- Responsible person
    
    effective_from DATE NOT NULL,
    effective_until DATE,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Personal data processing activities register
CREATE TABLE data_processing_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_name VARCHAR(100) NOT NULL,
    policy_id UUID REFERENCES data_protection_policies(policy_id),
    
    -- Processing details
    data_controller VARCHAR(100) NOT NULL, -- Organization responsible
    data_processor VARCHAR(100), -- Third party processor if applicable
    contact_person VARCHAR(100) NOT NULL,
    
    -- Data categories
    personal_data_categories TEXT[] NOT NULL, -- Types of personal data
    special_categories_data TEXT[], -- Sensitive personal data types
    data_subjects_categories TEXT[] NOT NULL, -- Categories of data subjects
    
    -- Processing purposes
    processing_purposes TEXT[] NOT NULL,
    legal_basis VARCHAR(100) NOT NULL,
    legitimate_interests TEXT, -- If using legitimate interest basis
    
    -- Recipients and transfers
    recipients_categories TEXT[], -- Who receives the data
    third_country_transfers TEXT[], -- International transfers
    safeguards_applied TEXT[], -- Safeguards for transfers
    
    -- Retention and deletion
    retention_criteria TEXT NOT NULL,
    retention_period_days INTEGER,
    deletion_schedule TEXT,
    
    -- Security measures
    technical_measures TEXT[] NOT NULL,
    organizational_measures TEXT[] NOT NULL,
    encryption_methods TEXT[],
    access_controls JSONB,
    
    -- Data subject rights procedures
    access_procedure TEXT,
    rectification_procedure TEXT,
    erasure_procedure TEXT,
    objection_procedure TEXT,
    
    -- Risk assessment
    risk_level VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high'
    dpia_required BOOLEAN DEFAULT false, -- Data Protection Impact Assessment
    dpia_completion_date DATE,
    
    -- Compliance status
    compliance_status VARCHAR(20) DEFAULT 'compliant', -- 'compliant', 'non_compliant', 'under_review'
    last_audit_date DATE,
    next_audit_due DATE,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data breach incident management
CREATE TABLE data_breach_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_number VARCHAR(50) NOT NULL, -- Human-readable incident number
    
    -- Incident details
    incident_title VARCHAR(200) NOT NULL,
    incident_description TEXT NOT NULL,
    discovery_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    estimated_occurrence_time TIMESTAMP WITH TIME ZONE,
    
    -- Breach characteristics
    breach_type VARCHAR(50) NOT NULL, -- 'confidentiality', 'integrity', 'availability'
    breach_cause VARCHAR(50) NOT NULL, -- 'cyber_attack', 'human_error', 'system_failure'
    breach_scope VARCHAR(30) NOT NULL, -- 'limited', 'significant', 'extensive'
    
    -- Affected data
    data_categories_affected TEXT[] NOT NULL,
    estimated_records_affected INTEGER,
    special_category_data_affected BOOLEAN DEFAULT false,
    data_subjects_affected_count INTEGER,
    
    -- Impact assessment
    likelihood_of_harm VARCHAR(20) DEFAULT 'low', -- 'low', 'medium', 'high'
    severity_of_harm VARCHAR(20) DEFAULT 'low', -- 'low', 'medium', 'high'
    overall_risk_level VARCHAR(20) DEFAULT 'low', -- 'low', 'medium', 'high'
    
    -- Containment measures
    containment_actions TEXT[],
    containment_timestamp TIMESTAMP WITH TIME ZONE,
    breach_contained BOOLEAN DEFAULT false,
    
    -- Notification requirements
    authority_notification_required BOOLEAN DEFAULT false,
    data_subject_notification_required BOOLEAN DEFAULT false,
    
    -- Authority notification
    authority_notified BOOLEAN DEFAULT false,
    authority_notification_timestamp TIMESTAMP WITH TIME ZONE,
    authority_reference_number VARCHAR(100),
    authority_response TEXT,
    
    -- Data subject notification
    data_subjects_notified BOOLEAN DEFAULT false,
    notification_method VARCHAR(50), -- 'email', 'letter', 'website', 'media'
    notification_content TEXT,
    notification_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Investigation and remediation
    investigation_status VARCHAR(20) DEFAULT 'ongoing', -- 'ongoing', 'completed', 'closed'
    root_cause_analysis TEXT,
    remediation_actions TEXT[],
    lessons_learned TEXT,
    
    -- Legal and regulatory response
    regulatory_action_taken BOOLEAN DEFAULT false,
    fine_imposed DECIMAL(12,2),
    legal_proceedings BOOLEAN DEFAULT false,
    
    -- Business impact
    operational_impact TEXT,
    financial_impact_rubles DECIMAL(12,2),
    reputational_impact TEXT,
    
    -- Case management
    assigned_to VARCHAR(100) NOT NULL,
    incident_status VARCHAR(20) DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'closed'
    resolution_timestamp TIMESTAMP WITH TIME ZONE,
    
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(incident_number)
);

-- Performance Optimization and Indexes
-- =====================================================================================

-- Labor Law Rules indexes
CREATE INDEX idx_labor_law_rules_category ON labor_law_rules(rule_category);
CREATE INDEX idx_labor_law_rules_effective ON labor_law_rules(effective_from, effective_until);
CREATE INDEX idx_labor_law_rules_severity ON labor_law_rules(severity_level);
CREATE INDEX idx_labor_law_rules_automated ON labor_law_rules(automated_check);

-- Working Time Regulations indexes
CREATE INDEX idx_working_time_regulations_type ON working_time_regulations(regulation_type);
CREATE INDEX idx_working_time_regulations_category ON working_time_regulations(employee_category);
CREATE INDEX idx_working_time_regulations_effective ON working_time_regulations(effective_from, effective_until);

-- Vacation Leave Regulations indexes
CREATE INDEX idx_vacation_leave_regulations_type ON vacation_leave_regulations(leave_type);
CREATE INDEX idx_vacation_leave_regulations_category ON vacation_leave_regulations(employee_category);
CREATE INDEX idx_vacation_leave_regulations_effective ON vacation_leave_regulations(effective_from, effective_until);

-- Compliance Monitoring indexes
CREATE INDEX idx_compliance_monitoring_status ON compliance_monitoring(status);
CREATE INDEX idx_compliance_monitoring_next_check ON compliance_monitoring(next_check_at);
CREATE INDEX idx_compliance_monitoring_scope ON compliance_monitoring(scope_type);

-- Compliance Violations indexes (on partitioned table)
CREATE INDEX idx_compliance_violations_employee ON compliance_violations(employee_id);
CREATE INDEX idx_compliance_violations_rule ON compliance_violations(rule_id);
CREATE INDEX idx_compliance_violations_status ON compliance_violations(status);
CREATE INDEX idx_compliance_violations_severity ON compliance_violations(severity_level);
CREATE INDEX idx_compliance_violations_date ON compliance_violations(violation_date);
CREATE INDEX idx_compliance_violations_detection ON compliance_violations(detection_timestamp);

-- Regulatory Reports indexes
CREATE INDEX idx_regulatory_reports_authority ON regulatory_reports(regulatory_authority);
CREATE INDEX idx_regulatory_reports_frequency ON regulatory_reports(reporting_frequency);
CREATE INDEX idx_regulatory_reports_mandatory ON regulatory_reports(mandatory);

-- Regulatory Report Instances indexes (on partitioned table)
CREATE INDEX idx_regulatory_report_instances_report_id ON regulatory_report_instances(report_id);
CREATE INDEX idx_regulatory_report_instances_period ON regulatory_report_instances(reporting_period_start, reporting_period_end);
CREATE INDEX idx_regulatory_report_instances_status ON regulatory_report_instances(submission_status);
CREATE INDEX idx_regulatory_report_instances_approval ON regulatory_report_instances(approval_status);

-- Data Protection Policies indexes
CREATE INDEX idx_data_protection_policies_type ON data_protection_policies(policy_type);
CREATE INDEX idx_data_protection_policies_framework ON data_protection_policies(legal_framework);
CREATE INDEX idx_data_protection_policies_effective ON data_protection_policies(effective_from, effective_until);

-- Data Processing Activities indexes
CREATE INDEX idx_data_processing_activities_policy ON data_processing_activities(policy_id);
CREATE INDEX idx_data_processing_activities_controller ON data_processing_activities(data_controller);
CREATE INDEX idx_data_processing_activities_risk ON data_processing_activities(risk_level);
CREATE INDEX idx_data_processing_activities_compliance ON data_processing_activities(compliance_status);

-- Data Breach Incidents indexes
CREATE INDEX idx_data_breach_incidents_discovery ON data_breach_incidents(discovery_timestamp);
CREATE INDEX idx_data_breach_incidents_type ON data_breach_incidents(breach_type);
CREATE INDEX idx_data_breach_incidents_status ON data_breach_incidents(incident_status);
CREATE INDEX idx_data_breach_incidents_risk ON data_breach_incidents(overall_risk_level);

-- Advanced Functions for Compliance
-- =====================================================================================

-- Function to check overtime compliance for an employee
CREATE OR REPLACE FUNCTION check_overtime_compliance(
    p_employee_id VARCHAR(100),
    p_check_date DATE,
    p_period_type VARCHAR(20) DEFAULT 'monthly' -- 'daily', 'monthly', 'annual'
)
RETURNS TABLE (
    compliant BOOLEAN,
    violation_type VARCHAR(50),
    limit_value DECIMAL(4,2),
    actual_value DECIMAL(4,2),
    excess_amount DECIMAL(4,2)
) AS $$
DECLARE
    v_employee_category VARCHAR(50);
    v_daily_limit DECIMAL(4,2);
    v_monthly_limit DECIMAL(4,2);
    v_annual_limit DECIMAL(4,2);
    v_actual_hours DECIMAL(8,2);
BEGIN
    -- Get employee category (simplified - would integrate with employee system)
    v_employee_category := 'standard';
    
    -- Get applicable limits
    SELECT daily_overtime_limit_hours, monthly_overtime_limit_hours, annual_overtime_limit_hours
    INTO v_daily_limit, v_monthly_limit, v_annual_limit
    FROM working_time_regulations
    WHERE regulation_type = 'overtime' 
        AND employee_category = v_employee_category
        AND effective_from <= p_check_date
        AND (effective_until IS NULL OR effective_until > p_check_date)
    LIMIT 1;
    
    -- Calculate actual overtime hours based on period
    IF p_period_type = 'daily' THEN
        -- Would calculate from actual time tracking data
        v_actual_hours := 2.5; -- Placeholder
        
        RETURN QUERY SELECT 
            v_actual_hours <= v_daily_limit,
            'daily_overtime_excess'::VARCHAR(50),
            v_daily_limit,
            v_actual_hours,
            GREATEST(0, v_actual_hours - v_daily_limit);
            
    ELSIF p_period_type = 'monthly' THEN
        -- Would calculate monthly total from time tracking
        v_actual_hours := 25.0; -- Placeholder
        
        RETURN QUERY SELECT 
            v_actual_hours <= v_monthly_limit,
            'monthly_overtime_excess'::VARCHAR(50),
            v_monthly_limit,
            v_actual_hours,
            GREATEST(0, v_actual_hours - v_monthly_limit);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to create compliance violation record
CREATE OR REPLACE FUNCTION create_compliance_violation(
    p_rule_id UUID,
    p_employee_id VARCHAR(100),
    p_violation_type VARCHAR(50),
    p_violation_description TEXT,
    p_actual_value DECIMAL(10,4),
    p_threshold_value DECIMAL(10,4),
    p_violation_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID AS $$
DECLARE
    v_violation_id UUID;
    v_severity VARCHAR(20);
    v_risk_score DECIMAL(3,2);
BEGIN
    -- Get rule severity
    SELECT severity_level INTO v_severity
    FROM labor_law_rules
    WHERE rule_id = p_rule_id;
    
    -- Calculate risk score based on excess amount
    v_risk_score := LEAST(1.0, (p_actual_value - p_threshold_value) / p_threshold_value);
    
    INSERT INTO compliance_violations (
        rule_id, employee_id, violation_type, violation_description,
        actual_value, threshold_value, excess_amount, violation_date,
        severity_level, risk_score
    ) VALUES (
        p_rule_id, p_employee_id, p_violation_type, p_violation_description,
        p_actual_value, p_threshold_value, p_actual_value - p_threshold_value, p_violation_date,
        v_severity, v_risk_score
    ) RETURNING violation_id INTO v_violation_id;
    
    RETURN v_violation_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate regulatory report
CREATE OR REPLACE FUNCTION generate_regulatory_report(
    p_report_id UUID,
    p_period_start DATE,
    p_period_end DATE,
    p_generated_by VARCHAR(100)
)
RETURNS UUID AS $$
DECLARE
    v_instance_id UUID;
    v_report_data JSONB;
    v_record_count INTEGER;
BEGIN
    -- Generate report data (simplified - would implement full logic)
    v_report_data := '{"employees": [], "working_hours": [], "violations": []}'::JSONB;
    v_record_count := 0;
    
    INSERT INTO regulatory_report_instances (
        report_id, reporting_period_start, reporting_period_end,
        generated_by, report_data, record_count
    ) VALUES (
        p_report_id, p_period_start, p_period_end,
        p_generated_by, v_report_data, v_record_count
    ) RETURNING instance_id INTO v_instance_id;
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function to log data breach incident
CREATE OR REPLACE FUNCTION log_data_breach(
    p_incident_title VARCHAR(200),
    p_incident_description TEXT,
    p_breach_type VARCHAR(50),
    p_breach_cause VARCHAR(50),
    p_estimated_records_affected INTEGER,
    p_discovered_by VARCHAR(100)
)
RETURNS UUID AS $$
DECLARE
    v_incident_id UUID;
    v_incident_number VARCHAR(50);
BEGIN
    -- Generate incident number
    v_incident_number := 'INC-' || TO_CHAR(NOW(), 'YYYY-MM-DD') || '-' || LPAD(nextval('incident_number_seq')::TEXT, 4, '0');
    
    INSERT INTO data_breach_incidents (
        incident_number, incident_title, incident_description,
        breach_type, breach_cause, estimated_records_affected,
        discovery_timestamp, created_by
    ) VALUES (
        v_incident_number, p_incident_title, p_incident_description,
        p_breach_type, p_breach_cause, p_estimated_records_affected,
        NOW(), p_discovered_by
    ) RETURNING incident_id INTO v_incident_id;
    
    RETURN v_incident_id;
END;
$$ LANGUAGE plpgsql;

-- Sequence for incident numbering
CREATE SEQUENCE incident_number_seq START 1;

-- Views for Compliance Reporting
-- =====================================================================================

-- Compliance dashboard view
CREATE VIEW v_compliance_dashboard AS
SELECT 
    'violations' as metric_type,
    'critical' as severity_level,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as count_7d,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as count_30d
FROM compliance_violations 
WHERE severity_level = 'critical' AND status = 'open'

UNION ALL

SELECT 
    'violations' as metric_type,
    'high' as severity_level,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as count_7d,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as count_30d
FROM compliance_violations 
WHERE severity_level = 'high' AND status = 'open'

UNION ALL

SELECT 
    'overdue_reports' as metric_type,
    'all' as severity_level,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as count_7d,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as count_30d
FROM regulatory_report_instances 
WHERE submission_status = 'not_submitted' 
    AND reporting_period_end + INTERVAL '1 day' * (SELECT submission_deadline_days FROM regulatory_reports WHERE report_id = regulatory_report_instances.report_id) < CURRENT_DATE;

-- Labor law violations summary
CREATE VIEW v_labor_law_violations_summary AS
SELECT 
    llr.rule_category,
    llr.rule_name,
    llr.severity_level,
    COUNT(cv.violation_id) as total_violations,
    COUNT(CASE WHEN cv.status = 'open' THEN 1 END) as open_violations,
    AVG(cv.risk_score) as avg_risk_score,
    SUM(cv.financial_risk_rubles) as total_financial_risk,
    MAX(cv.detection_timestamp) as last_violation_date,
    
    -- Trends
    COUNT(CASE WHEN cv.detection_timestamp >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as violations_30d,
    COUNT(CASE WHEN cv.detection_timestamp >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as violations_7d
    
FROM labor_law_rules llr
LEFT JOIN compliance_violations cv ON llr.rule_id = cv.rule_id
WHERE llr.automated_check = true
GROUP BY llr.rule_id, llr.rule_category, llr.rule_name, llr.severity_level
ORDER BY total_violations DESC, avg_risk_score DESC;

-- GDPR compliance status view
CREATE VIEW v_gdpr_compliance_status AS
SELECT 
    dpa.activity_name,
    dpa.data_controller,
    dpa.risk_level,
    dpa.compliance_status,
    dpa.last_audit_date,
    dpa.next_audit_due,
    
    -- Data breach incidents related to this activity
    COUNT(dbi.incident_id) as related_incidents,
    MAX(dbi.discovery_timestamp) as last_incident_date,
    
    -- Overdue audit indicator
    CASE 
        WHEN dpa.next_audit_due < CURRENT_DATE THEN 'overdue'
        WHEN dpa.next_audit_due < CURRENT_DATE + INTERVAL '30 days' THEN 'due_soon'
        ELSE 'current'
    END as audit_status
    
FROM data_processing_activities dpa
LEFT JOIN data_breach_incidents dbi ON dpa.activity_name = ANY(string_to_array(dbi.incident_description, ' '))
GROUP BY dpa.activity_id, dpa.activity_name, dpa.data_controller, 
         dpa.risk_level, dpa.compliance_status, dpa.last_audit_date, dpa.next_audit_due
ORDER BY dpa.risk_level DESC, dpa.next_audit_due ASC;

-- Demo Data for Compliance Framework
-- =====================================================================================

-- Insert Russian labor law rules
INSERT INTO labor_law_rules (rule_code, rule_name, rule_category, legal_source, article_number, rule_description, rule_parameters, severity_level, created_by) VALUES
('TK_RF_99', 'Продолжительность ежедневной работы', 'working_time', 'TK_RF', '99', 'Продолжительность ежедневной работы (смены) не может превышать 8 часов для нормальных условий труда', '{"max_daily_hours": 8, "exceptions": ["сокращенная_рабочая_неделя", "сверхурочная_работа"]}', 'high', 'legal_compliance_team'),
('TK_RF_108', 'Продолжительность сверхурочной работы', 'overtime', 'TK_RF', '108', 'Сверхурочная работа не должна превышать 4 часов в течение двух дней подряд и 120 часов в год', '{"max_overtime_2days": 4, "max_overtime_annual": 120}', 'critical', 'legal_compliance_team'),
('TK_RF_108_2', 'Ограничения ночной работы', 'night_work', 'TK_RF', '108', 'Продолжительность ночной работы сокращается на один час без последующей отработки', '{"night_hours": "22:00-06:00", "reduction_hours": 1}', 'medium', 'legal_compliance_team'),
('TK_RF_114', 'Ежегодный оплачиваемый отпуск', 'vacation', 'TK_RF', '114', 'Ежегодный основной оплачиваемый отпуск предоставляется работникам продолжительностью 28 календарных дней', '{"min_vacation_days": 28, "calculation_method": "calendar_days"}', 'medium', 'legal_compliance_team');

-- Insert working time regulations
INSERT INTO working_time_regulations (regulation_type, employee_category, daily_limit_hours, weekly_limit_hours, daily_overtime_limit_hours, monthly_overtime_limit_hours, annual_overtime_limit_hours, minimum_daily_rest_hours, legal_reference, effective_from) VALUES
('normal_hours', 'standard', 8.0, 40.0, 4.0, 20.0, 120.0, 11.0, 'TK_RF_Art_91_99', '2002-02-01'),
('normal_hours', 'pregnant', 8.0, 36.0, 0.0, 0.0, 0.0, 11.0, 'TK_RF_Art_259', '2002-02-01'),
('normal_hours', 'minor', 7.0, 35.0, 0.0, 0.0, 0.0, 12.0, 'TK_RF_Art_94', '2002-02-01'),
('overtime', 'standard', NULL, NULL, 4.0, 20.0, 120.0, NULL, 'TK_RF_Art_108', '2002-02-01'),
('night_work', 'standard', 7.0, NULL, NULL, NULL, NULL, NULL, 'TK_RF_Art_108', '2002-02-01');

-- Insert vacation regulations
INSERT INTO vacation_leave_regulations (leave_type, employee_category, minimum_days_per_year, accrual_rate_per_month, maximum_carryover_days, minimum_continuous_days, advance_notice_days, legal_reference, effective_from) VALUES
('annual_vacation', 'standard', 28, 2.33, 0, 14, 14, 'TK_RF_Art_114_115', '2002-02-01'),
('annual_vacation', 'minor', 31, 2.58, 0, 31, 14, 'TK_RF_Art_267', '2002-02-01'),
('sick_leave', 'standard', NULL, NULL, NULL, NULL, 0, 'ФЗ_255', '2007-01-01'),
('maternity', 'standard', 140, NULL, NULL, 140, 0, 'TK_RF_Art_255', '2002-02-01');

-- Insert compliance monitoring configurations
INSERT INTO compliance_monitoring (monitor_name, monitor_type, scope_type, scope_entities, monitored_rules, monitoring_frequency, created_by) VALUES
('Ежедневный контроль сверхурочных', 'scheduled', 'company', '{"all_employees": true}', ARRAY[(SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_108')], 'daily', 'compliance_system'),
('Контроль рабочего времени', 'real_time', 'company', '{"all_employees": true}', ARRAY[(SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_99')], 'real_time', 'compliance_system'),
('Контроль ночной работы', 'scheduled', 'department', '{"departments": ["call_center", "tech_support"]}', ARRAY[(SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_108_2')], 'daily', 'compliance_system');

-- Insert sample violations
INSERT INTO compliance_violations (rule_id, employee_id, violation_type, violation_description, actual_value, threshold_value, excess_amount, violation_date, severity_level, risk_score) VALUES
((SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_108'), 'EMP001', 'monthly_overtime_excess', 'Превышение месячной нормы сверхурочной работы', 25.5, 20.0, 5.5, CURRENT_DATE - 1, 'high', 0.275),
((SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_99'), 'EMP002', 'daily_hours_excess', 'Превышение дневной нормы рабочего времени', 9.2, 8.0, 1.2, CURRENT_DATE, 'medium', 0.15),
((SELECT rule_id FROM labor_law_rules WHERE rule_code = 'TK_RF_108_2'), 'EMP003', 'night_work_violation', 'Нарушение продолжительности ночной работы', 8.0, 7.0, 1.0, CURRENT_DATE - 2, 'medium', 0.143);

-- Insert regulatory reports
INSERT INTO regulatory_reports (report_code, report_name, regulatory_authority, reporting_frequency, submission_deadline_days, data_requirements, mandatory, created_by) VALUES
('T-13', 'Табель учета рабочего времени', 'Rostrud', 'monthly', 5, '{"working_hours": true, "overtime": true, "absences": true, "employee_data": true}', true, 'reporting_team'),
('SZV-M', 'Сведения о работающих застрахованных лицах', 'PFR', 'monthly', 15, '{"employee_list": true, "salary_data": true, "insurance_periods": true}', true, 'reporting_team'),
('P-4', 'Сведения о численности и заработной плате работников', 'Rosstat', 'quarterly', 20, '{"headcount": true, "salary_statistics": true, "working_time": true}', true, 'reporting_team');

-- Insert GDPR policies
INSERT INTO data_protection_policies (policy_name, policy_type, legal_framework, policy_description, data_categories_covered, processing_purposes, retention_period_days, created_by) VALUES
('Employee Data Protection Policy', 'gdpr', 'GDPR', 'Comprehensive policy for processing employee personal data in compliance with GDPR and Russian Federal Law 152-FZ', '["name", "passport_data", "contact_info", "salary", "performance_data"]', '["employment_management", "payroll", "performance_evaluation"]', 2555, 'data_protection_officer'),
('Customer Data Protection Policy', 'russian_personal_data', 'ФЗ-152', 'Policy for processing customer personal data according to Russian personal data law', '["name", "phone", "email", "service_history"]', '["service_delivery", "quality_improvement", "compliance"]', 1825, 'data_protection_officer');

-- Insert data processing activities
INSERT INTO data_processing_activities (activity_name, policy_id, data_controller, contact_person, personal_data_categories, processing_purposes, legal_basis, retention_period_days, risk_level, created_by) VALUES
('Employee Workforce Management', (SELECT policy_id FROM data_protection_policies WHERE policy_name = 'Employee Data Protection Policy'), 'ООО ТехноСервис', 'hr_manager@technoservice.ru', '["employee_id", "working_hours", "schedule_data", "performance_metrics"]', '["schedule_planning", "performance_monitoring", "compliance_reporting"]', 'Employment contract (GDPR Art 6.1.b)', 2555, 'medium', 'hr_department'),
('Call Center Quality Management', (SELECT policy_id FROM data_protection_policies WHERE policy_name = 'Customer Data Protection Policy'), 'ООО ТехноСервис', 'quality_manager@technoservice.ru', '["call_recordings", "customer_feedback", "agent_performance"]', '["quality_assurance", "training", "service_improvement"]', 'Legitimate interest (GDPR Art 6.1.f)', 1095, 'high', 'quality_department');

-- Comments for Documentation
-- =====================================================================================

COMMENT ON TABLE labor_law_rules IS 'Russian labor law rules with automated compliance checking';
COMMENT ON TABLE working_time_regulations IS 'Working time limits and regulations per Russian Labor Code';
COMMENT ON TABLE vacation_leave_regulations IS 'Vacation and leave entitlements per Russian labor law';
COMMENT ON TABLE compliance_monitoring IS 'Real-time and scheduled compliance monitoring configurations';
COMMENT ON TABLE compliance_violations IS 'Compliance violation records with risk assessment (partitioned by date)';
COMMENT ON TABLE regulatory_reports IS 'Russian regulatory report definitions and requirements';
COMMENT ON TABLE regulatory_report_instances IS 'Generated regulatory reports with submission tracking (partitioned by period)';
COMMENT ON TABLE data_protection_policies IS 'GDPR and Russian personal data protection policies';
COMMENT ON TABLE data_processing_activities IS 'GDPR Article 30 processing activities register';
COMMENT ON TABLE data_breach_incidents IS 'Data breach incident management with GDPR notification requirements';

COMMENT ON COLUMN labor_law_rules.rule_parameters IS 'JSON parameters for automated rule checking';
COMMENT ON COLUMN compliance_violations.risk_score IS 'Calculated risk score based on violation severity (0.0-1.0)';
COMMENT ON COLUMN regulatory_reports.data_requirements IS 'JSON specification of required data fields for report';
COMMENT ON COLUMN data_processing_activities.legal_basis IS 'GDPR Article 6 legal basis for processing';
COMMENT ON COLUMN data_breach_incidents.likelihood_of_harm IS 'GDPR risk assessment: likelihood of harm to data subjects';

-- Schema completion marker
INSERT INTO schema_migrations (schema_name, version, description, applied_at) 
VALUES ('123_compliance_monitoring_regulatory_framework', '1.0.0', 'Comprehensive compliance monitoring for Russian labor law and GDPR', NOW());