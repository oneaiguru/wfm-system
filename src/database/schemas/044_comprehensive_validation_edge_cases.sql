-- =============================================================================
-- 044_comprehensive_validation_edge_cases.sql
-- EXACT BDD Implementation: Comprehensive Business Process Validation & Edge Cases
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 20-comprehensive-validation-edge-cases.feature (350 lines)
-- Purpose: Complete validation framework, edge case handling, and business process coverage validation
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =============================================================================
-- 1. BUSINESS PROCESS VALIDATION FRAMEWORK
-- =============================================================================

-- Business process mapping validation from BDD lines 19-29
CREATE TABLE business_process_validation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_name VARCHAR(200) NOT NULL,
    process_number INTEGER NOT NULL,
    paste_txt_section VARCHAR(50),
    
    -- Coverage tracking from BDD lines 24-29
    bdd_file_coverage TEXT[],
    completion_status VARCHAR(20) DEFAULT 'pending' CHECK (completion_status IN (
        'pending', 'in_progress', 'complete', 'validated'
    )),
    
    -- Process details
    process_steps JSONB NOT NULL DEFAULT '[]',
    validation_criteria JSONB,
    
    -- Testing status
    ui_steps_documented BOOLEAN DEFAULT false,
    algorithms_implemented BOOLEAN DEFAULT false,
    live_testing_completed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Step-by-step process implementation tracking from BDD lines 32-45
CREATE TABLE process_step_validation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_id UUID NOT NULL REFERENCES business_process_validation(id) ON DELETE CASCADE,
    step_identifier VARCHAR(50) NOT NULL,
    step_description TEXT NOT NULL,
    
    -- Implementation details from BDD lines 36-45
    paste_txt_detail TEXT,
    bdd_implementation TEXT,
    live_testing_status VARCHAR(50),
    
    -- UI validation
    exact_ui_steps_documented BOOLEAN DEFAULT false,
    ui_screenshots_captured BOOLEAN DEFAULT false,
    
    -- Coverage status
    implementation_complete BOOLEAN DEFAULT false,
    validation_passed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_process_step UNIQUE(process_id, step_identifier)
);

-- =============================================================================
-- 2. EDGE CASE VALIDATION FRAMEWORK
-- =============================================================================

-- Form validation edge cases from BDD lines 50-62
CREATE TABLE form_validation_edge_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    edge_case_category VARCHAR(100) NOT NULL,
    test_scenario TEXT NOT NULL,
    
    -- Expected behavior
    expected_behavior TEXT NOT NULL,
    actual_behavior TEXT,
    
    -- Validation details
    validation_rules JSONB NOT NULL DEFAULT '{}',
    sanitization_rules JSONB DEFAULT '{}',
    
    -- Coverage tracking
    bdd_coverage TEXT,
    test_status VARCHAR(20) DEFAULT 'pending' CHECK (test_status IN (
        'pending', 'in_progress', 'passed', 'failed', 'blocked'
    )),
    
    -- Security validation
    security_validated BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Authentication security edge cases from BDD lines 63-75
CREATE TABLE authentication_security_edge_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    security_scenario VARCHAR(200) NOT NULL,
    test_case TEXT NOT NULL,
    
    -- Security requirements
    expected_result TEXT NOT NULL,
    implementation_status VARCHAR(50) DEFAULT 'needs_specification',
    
    -- Security parameters
    lockout_threshold INTEGER,
    timeout_seconds INTEGER,
    rate_limit_per_minute INTEGER,
    
    -- Implementation details
    implementation_notes TEXT,
    security_controls JSONB DEFAULT '{}',
    
    -- Validation
    security_audit_passed BOOLEAN DEFAULT false,
    penetration_test_passed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. SYSTEM INTEGRATION FAILURE HANDLING
-- =============================================================================

-- Integration failure scenarios from BDD lines 76-88
CREATE TABLE integration_failure_scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    failure_scenario VARCHAR(200) NOT NULL,
    trigger_condition TEXT NOT NULL,
    
    -- Recovery behavior from BDD lines 81-87
    expected_behavior TEXT NOT NULL,
    recovery_method TEXT NOT NULL,
    
    -- Failure handling configuration
    retry_strategy JSONB DEFAULT '{
        "max_retries": 3,
        "backoff_type": "exponential",
        "initial_delay_ms": 1000
    }',
    
    -- Circuit breaker settings
    circuit_breaker_enabled BOOLEAN DEFAULT true,
    failure_threshold INTEGER DEFAULT 5,
    recovery_timeout_seconds INTEGER DEFAULT 60,
    
    -- Monitoring
    alert_on_failure BOOLEAN DEFAULT true,
    monitoring_dashboard_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. DATA VALIDATION BOUNDARIES
-- =============================================================================

-- Data validation boundary testing from BDD lines 89-101
CREATE TABLE data_validation_boundaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_type VARCHAR(50) NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    
    -- Boundary conditions from BDD lines 94-100
    boundary_condition VARCHAR(100) NOT NULL,
    test_values JSONB NOT NULL,
    expected_results JSONB NOT NULL,
    
    -- Validation rules
    min_value TEXT,
    max_value TEXT,
    pattern_regex TEXT,
    
    -- Unicode and internationalization
    unicode_support_required BOOLEAN DEFAULT true,
    supported_languages TEXT[] DEFAULT ARRAY['ru', 'en'],
    
    -- Test results
    validation_passed BOOLEAN,
    edge_cases_covered BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. PERFORMANCE AND SCALABILITY TESTING
-- =============================================================================

-- Performance edge cases from BDD lines 106-118
CREATE TABLE performance_scalability_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    performance_scenario VARCHAR(200) NOT NULL,
    load_condition TEXT NOT NULL,
    
    -- Expected behavior and monitoring from BDD lines 111-117
    expected_behavior TEXT NOT NULL,
    monitoring_required TEXT NOT NULL,
    
    -- Performance metrics
    target_response_time_ms INTEGER,
    target_throughput_per_second INTEGER,
    max_concurrent_users INTEGER,
    
    -- Test configuration
    test_duration_minutes INTEGER DEFAULT 60,
    ramp_up_time_minutes INTEGER DEFAULT 10,
    
    -- Results
    actual_response_time_p95_ms INTEGER,
    actual_throughput_achieved INTEGER,
    bottlenecks_identified JSONB DEFAULT '[]',
    
    test_status VARCHAR(20) DEFAULT 'pending',
    tested_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. DISASTER RECOVERY SCENARIOS
-- =============================================================================

-- Disaster recovery testing from BDD lines 119-131
CREATE TABLE disaster_recovery_scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disaster_scenario VARCHAR(200) NOT NULL,
    impact_description TEXT NOT NULL,
    
    -- Recovery targets from BDD lines 124-130
    recovery_procedure TEXT NOT NULL,
    rto_hours INTEGER NOT NULL, -- Recovery Time Objective
    rpo_hours INTEGER NOT NULL, -- Recovery Point Objective
    
    -- Recovery validation
    recovery_steps JSONB NOT NULL DEFAULT '[]',
    validation_checklist JSONB DEFAULT '[]',
    
    -- Test results
    last_dr_test_date DATE,
    test_successful BOOLEAN,
    actual_recovery_time_hours INTEGER,
    actual_data_loss_hours INTEGER,
    
    -- Documentation
    runbook_url TEXT,
    post_mortem_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. USER EXPERIENCE AND ACCESSIBILITY
-- =============================================================================

-- UX and accessibility testing from BDD lines 136-148
CREATE TABLE ux_accessibility_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ux_scenario VARCHAR(200) NOT NULL,
    test_condition TEXT NOT NULL,
    
    -- Accessibility requirements from BDD lines 141-147
    expected_behavior TEXT NOT NULL,
    compliance_standard VARCHAR(50) DEFAULT 'WCAG 2.1 AA',
    
    -- Test configuration
    test_tools JSONB DEFAULT '[]',
    browser_versions JSONB DEFAULT '{}',
    device_types JSONB DEFAULT '[]',
    
    -- Results
    compliance_score DECIMAL(5,2),
    issues_found JSONB DEFAULT '[]',
    remediation_required BOOLEAN DEFAULT false,
    
    tested_at TIMESTAMP WITH TIME ZONE,
    tester_name VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. INTERNATIONALIZATION TESTING
-- =============================================================================

-- I18n testing from BDD lines 149-161
CREATE TABLE internationalization_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    i18n_scenario VARCHAR(200) NOT NULL,
    test_case TEXT NOT NULL,
    
    -- Expected behavior from BDD lines 154-160
    expected_behavior TEXT NOT NULL,
    implementation_details TEXT,
    
    -- Language configuration
    test_languages TEXT[] DEFAULT ARRAY['ru', 'en', 'ar', 'de'],
    rtl_support_required BOOLEAN DEFAULT false,
    
    -- Locale settings
    date_format_variations JSONB DEFAULT '{}',
    time_zone_handling JSONB DEFAULT '{}',
    currency_formats JSONB DEFAULT '{}',
    
    -- Test results
    all_languages_tested BOOLEAN DEFAULT false,
    issues_by_language JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. REGULATORY COMPLIANCE TESTING
-- =============================================================================

-- Regulatory compliance from BDD lines 166-178
CREATE TABLE regulatory_compliance_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    regulation VARCHAR(50) NOT NULL,
    compliance_scenario TEXT NOT NULL,
    
    -- Test cases from BDD lines 171-177
    test_case TEXT NOT NULL,
    expected_outcome TEXT NOT NULL,
    
    -- Compliance configuration
    applicable_jurisdictions TEXT[] DEFAULT ARRAY['RU', 'EU'],
    compliance_requirements JSONB NOT NULL DEFAULT '{}',
    
    -- Audit requirements
    requires_audit_trail BOOLEAN DEFAULT true,
    retention_period_years INTEGER,
    
    -- Test results
    compliance_achieved BOOLEAN,
    gaps_identified JSONB DEFAULT '[]',
    remediation_plan JSONB DEFAULT '{}',
    
    last_audit_date DATE,
    auditor_name VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. AUDIT TRAIL AND FORENSICS
-- =============================================================================

-- Audit trail testing from BDD lines 179-191
CREATE TABLE audit_forensic_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_scenario VARCHAR(200) NOT NULL,
    investigation_need TEXT NOT NULL,
    
    -- Evidence requirements from BDD lines 184-190
    available_evidence TEXT NOT NULL,
    compliance_requirement TEXT NOT NULL,
    
    -- Audit configuration
    log_retention_days INTEGER DEFAULT 2555, -- 7 years
    log_detail_level VARCHAR(20) DEFAULT 'detailed',
    
    -- Forensic capabilities
    data_reconstruction_possible BOOLEAN DEFAULT true,
    timeline_reconstruction JSONB DEFAULT '{}',
    
    -- Test results
    audit_completeness_score DECIMAL(5,2),
    gaps_in_coverage JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 11. MISSING FUNCTIONALITY TRACKING
-- =============================================================================

-- Gap analysis from BDD lines 196-208
CREATE TABLE functionality_gap_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    functionality_area VARCHAR(200) NOT NULL,
    
    -- Coverage assessment from BDD lines 201-207
    current_coverage TEXT,
    missing_elements TEXT[],
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    
    -- Implementation planning
    estimated_effort_days INTEGER,
    dependencies JSONB DEFAULT '[]',
    business_value VARCHAR(20) CHECK (business_value IN ('low', 'medium', 'high')),
    
    -- Tracking
    identified_date DATE DEFAULT CURRENT_DATE,
    target_completion_date DATE,
    status VARCHAR(20) DEFAULT 'identified',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 12. CROSS-FILE CONSISTENCY VALIDATION
-- =============================================================================

-- Cross-file validation from BDD lines 226-238
CREATE TABLE cross_file_consistency (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consistency_area VARCHAR(100) NOT NULL,
    validation_check TEXT NOT NULL,
    
    -- Files involved from BDD lines 231-237
    files_involved TEXT[] NOT NULL,
    validation_status VARCHAR(20) DEFAULT 'pending',
    
    -- Consistency rules
    consistency_rules JSONB NOT NULL DEFAULT '{}',
    violations_found JSONB DEFAULT '[]',
    
    -- Resolution
    resolution_required BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate business process coverage
CREATE OR REPLACE FUNCTION validate_business_process_coverage()
RETURNS TABLE (
    process_name VARCHAR,
    coverage_percentage DECIMAL,
    missing_steps TEXT[],
    validation_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bpv.process_name,
        COALESCE(
            (COUNT(CASE WHEN psv.implementation_complete THEN 1 END)::DECIMAL / 
             NULLIF(COUNT(psv.id), 0)) * 100,
            0
        ) AS coverage_percentage,
        ARRAY_AGG(
            CASE 
                WHEN NOT psv.implementation_complete 
                THEN psv.step_identifier 
            END
        ) FILTER (WHERE NOT psv.implementation_complete) AS missing_steps,
        bpv.completion_status AS validation_status
    FROM business_process_validation bpv
    LEFT JOIN process_step_validation psv ON bpv.id = psv.process_id
    GROUP BY bpv.id, bpv.process_name, bpv.completion_status;
END;
$$ LANGUAGE plpgsql;

-- Function to check edge case coverage
CREATE OR REPLACE FUNCTION check_edge_case_coverage(
    p_category VARCHAR DEFAULT NULL
) RETURNS TABLE (
    category VARCHAR,
    total_cases INTEGER,
    passed_cases INTEGER,
    failed_cases INTEGER,
    coverage_percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        edge_case_category AS category,
        COUNT(*) AS total_cases,
        COUNT(CASE WHEN test_status = 'passed' THEN 1 END) AS passed_cases,
        COUNT(CASE WHEN test_status = 'failed' THEN 1 END) AS failed_cases,
        (COUNT(CASE WHEN test_status IN ('passed', 'failed') THEN 1 END)::DECIMAL / 
         COUNT(*)) * 100 AS coverage_percentage
    FROM form_validation_edge_cases
    WHERE p_category IS NULL OR edge_case_category = p_category
    GROUP BY edge_case_category;
END;
$$ LANGUAGE plpgsql;

-- Function to assess disaster recovery readiness
CREATE OR REPLACE FUNCTION assess_dr_readiness()
RETURNS TABLE (
    scenario VARCHAR,
    rto_target INTEGER,
    rpo_target INTEGER,
    last_test_days_ago INTEGER,
    readiness_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        disaster_scenario AS scenario,
        rto_hours AS rto_target,
        rpo_hours AS rpo_target,
        CASE 
            WHEN last_dr_test_date IS NOT NULL 
            THEN (CURRENT_DATE - last_dr_test_date)::INTEGER
            ELSE NULL
        END AS last_test_days_ago,
        CASE 
            WHEN last_dr_test_date IS NULL THEN 'untested'
            WHEN (CURRENT_DATE - last_dr_test_date) > 180 THEN 'needs_retest'
            WHEN test_successful THEN 'ready'
            ELSE 'failed'
        END AS readiness_status
    FROM disaster_recovery_scenarios;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_validation_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_business_process_validation_timestamp
    BEFORE UPDATE ON business_process_validation
    FOR EACH ROW
    EXECUTE FUNCTION update_validation_timestamps();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Business process validation indexes
CREATE INDEX idx_business_process_status ON business_process_validation(completion_status);
CREATE INDEX idx_process_steps_process ON process_step_validation(process_id);
CREATE INDEX idx_process_steps_complete ON process_step_validation(implementation_complete);

-- Edge case indexes
CREATE INDEX idx_form_validation_category ON form_validation_edge_cases(edge_case_category);
CREATE INDEX idx_form_validation_status ON form_validation_edge_cases(test_status);
CREATE INDEX idx_auth_security_status ON authentication_security_edge_cases(implementation_status);

-- Performance testing indexes
CREATE INDEX idx_performance_tests_status ON performance_scalability_tests(test_status);
CREATE INDEX idx_performance_tests_date ON performance_scalability_tests(tested_at DESC);

-- Compliance indexes
CREATE INDEX idx_regulatory_compliance_reg ON regulatory_compliance_tests(regulation);
CREATE INDEX idx_regulatory_compliance_achieved ON regulatory_compliance_tests(compliance_achieved);

-- Gap analysis indexes
CREATE INDEX idx_functionality_gaps_priority ON functionality_gap_analysis(priority);
CREATE INDEX idx_functionality_gaps_status ON functionality_gap_analysis(status);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert business processes from paste.txt mapping
INSERT INTO business_process_validation (process_name, process_number, paste_txt_section, bdd_file_coverage, completion_status) VALUES
('Первичная настройка системы', 1, '1.1-1.2', ARRAY['07-labor-standards-configuration.feature'], 'complete'),
('Прогнозирование нагрузки', 2, 'Section 2', ARRAY['08-load-forecasting-demand-planning.feature'], 'complete'),
('Планирование графиков работ и отпусков', 3, 'Section 3', ARRAY['09-work-schedule-vacation-planning.feature'], 'complete'),
('Ежемесячное планирование активностей', 4, 'Section 4', ARRAY['10-monthly-intraday-activity-planning.feature'], 'complete'),
('Создание заявок Оператора', 5, 'Section 5', ARRAY['02-employee-requests.feature', '03-complete-business-process.feature', '04-requests-section-detailed.feature', '05-complete-step-by-step-requests.feature', '06-complete-navigation-exchange-system.feature'], 'complete');

-- Insert edge case categories
INSERT INTO form_validation_edge_cases (edge_case_category, test_scenario, expected_behavior, bdd_coverage) VALUES
('Empty fields', 'All required fields empty', 'Show all validation errors', 'File 05: @request_form @validation_sequence'),
('Maximum length', 'Text beyond field limits', 'Truncate or show error', 'File 05: @edge_cases @live_testable'),
('Special characters', 'Unicode, symbols, emojis', 'Accept or sanitize appropriately', 'File 05: Comment field testing'),
('XSS attempts', 'Script injection attempts', 'Sanitize and block malicious input', 'Security validation needed'),
('SQL injection', 'Database attack attempts', 'Parameterized queries prevent attacks', 'Security validation needed'),
('CSRF attacks', 'Cross-site request forgery', 'Token validation prevents attacks', 'Security validation needed');

-- Insert performance scenarios
INSERT INTO performance_scalability_tests (performance_scenario, load_condition, expected_behavior, monitoring_required, target_response_time_ms, max_concurrent_users) VALUES
('High concurrent users', '1000+ simultaneous users', 'Maintain response time', 'Performance monitoring', 2000, 1000),
('Large data sets', '100K+ employee records', 'Efficient processing', 'Database optimization', 5000, 100),
('Bulk operations', 'Mass schedule updates', 'Progress tracking', 'Operation monitoring', 30000, 50),
('Report generation', 'Complex multi-year reports', 'Reasonable completion time', 'Resource monitoring', 60000, 10),
('Real-time monitoring', 'High-frequency updates', 'Maintain real-time performance', 'System monitoring', 100, 500),
('Integration load', 'Multiple external systems', 'Maintain integration SLAs', 'Integration monitoring', 1000, 200);

-- Insert disaster recovery scenarios
INSERT INTO disaster_recovery_scenarios (disaster_scenario, impact_description, recovery_procedure, rto_hours, rpo_hours) VALUES
('Primary datacenter failure', 'Complete site loss', 'Activate DR site', 8, 4),
('Database corruption', 'Data integrity loss', 'Restore from backup', 4, 1),
('Security breach', 'System compromise', 'Isolate and rebuild', 2, 0),
('Network outage', 'Connectivity loss', 'Activate backup networks', 1, 0),
('Application server failure', 'Service unavailability', 'Failover to standby', 1, 0),
('Integration service failure', 'External data loss', 'Local backup operation', 1, 1);

-- Insert compliance test scenarios
INSERT INTO regulatory_compliance_tests (regulation, compliance_scenario, test_case, expected_outcome) VALUES
('GDPR', 'Right to be forgotten', 'Delete personal data request', 'Complete data removal'),
('GDPR', 'Data portability', 'Export personal data', 'Machine-readable format'),
('GDPR', 'Consent withdrawal', 'Revoke data processing consent', 'Processing stops'),
('SOX', 'Change control', 'Unauthorized system change', 'Change blocked and logged'),
('Labor Law', 'Working time limits', 'Exceed maximum hours', 'System prevents violation'),
('Industry Standards', 'Data retention', 'Exceed retention period', 'Automatic data archival');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_qa;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_developer;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_qa;