-- =============================================================================
-- 059_mass_assignment_operations.sql
-- EXACT BDD Implementation: Mass Assignment Operations with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 32-mass-assignment-operations.feature (111 lines)
-- Purpose: Mass assignment operations for business rules, vacation schemes, and work hours
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. MASS ASSIGNMENT OPERATIONS
-- =============================================================================

-- Mass assignment operation tracking from BDD lines 6-14
CREATE TABLE mass_assignment_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_id VARCHAR(50) NOT NULL UNIQUE,
    operation_name VARCHAR(200) NOT NULL,
    
    -- Operation classification from BDD lines 19, 41, 64
    assignment_type VARCHAR(30) NOT NULL CHECK (assignment_type IN (
        'business_rules', 'vacation_schemes', 'work_hours', 'general_assignment'
    )),
    operation_description TEXT,
    
    -- Assignment parameters from BDD lines 65-69
    assignment_period VARCHAR(50),
    assignment_source VARCHAR(30) DEFAULT 'manual' CHECK (assignment_source IN (
        'manual', 'imported', 'automated', 'template'
    )),
    target_department VARCHAR(100),
    target_group VARCHAR(100),
    target_segment VARCHAR(100),
    
    -- Operation metadata
    total_employees_targeted INTEGER DEFAULT 0,
    total_employees_processed INTEGER DEFAULT 0,
    total_employees_successful INTEGER DEFAULT 0,
    total_employees_failed INTEGER DEFAULT 0,
    
    -- Operation status
    operation_status VARCHAR(20) DEFAULT 'pending' CHECK (operation_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'cancelled'
    )),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Execution details
    execution_mode VARCHAR(20) DEFAULT 'batch' CHECK (execution_mode IN (
        'batch', 'individual', 'preview', 'dry_run'
    )),
    batch_size INTEGER DEFAULT 100,
    execution_errors JSONB DEFAULT '[]',
    
    -- User tracking
    created_by INTEGER NOT NULL,
    executed_by INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (executed_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. EMPLOYEE FILTERING CONFIGURATION
-- =============================================================================

-- Employee filtering for mass assignment from BDD lines 20-25, 42-46, 87-94
CREATE TABLE mass_assignment_filters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    filter_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    
    -- Filter configuration from BDD lines 89-94
    filter_type VARCHAR(30) NOT NULL CHECK (filter_type IN (
        'department', 'employee_type', 'status', 'group', 'segment', 'personnel_number'
    )),
    filter_value VARCHAR(200) NOT NULL,
    filter_description TEXT,
    
    -- Filter options from BDD lines 21-24, 43-45, 89-94
    filter_operator VARCHAR(20) DEFAULT 'equals' CHECK (filter_operator IN (
        'equals', 'not_equals', 'contains', 'starts_with', 'in_list', 'not_in_list'
    )),
    is_case_sensitive BOOLEAN DEFAULT false,
    
    -- Filter metadata
    employees_matched INTEGER DEFAULT 0,
    filter_applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE
);

-- =============================================================================
-- 3. EMPLOYEE SELECTION AND ELIGIBILITY
-- =============================================================================

-- Employee selection for mass assignment from BDD lines 25-26, 46, 76-79, 100-104
CREATE TABLE mass_assignment_employee_selection (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    selection_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    employee_id INTEGER NOT NULL,
    
    -- Selection criteria from BDD lines 101-104
    employee_name VARCHAR(200) NOT NULL,
    personnel_number VARCHAR(50),
    department VARCHAR(100),
    employee_type VARCHAR(30),
    employee_status VARCHAR(30),
    
    -- Eligibility assessment from BDD lines 31-36, 54-57
    is_eligible BOOLEAN DEFAULT true,
    eligibility_reason TEXT,
    
    -- Current vs new assignment from BDD lines 31-33, 54-56, 77-79
    current_assignment_value TEXT,
    new_assignment_value TEXT,
    assignment_action VARCHAR(20) DEFAULT 'apply' CHECK (assignment_action IN (
        'apply', 'override', 'skip', 'conflict'
    )),
    
    -- Compatibility check for vacation schemes from BDD lines 54-56
    compatibility_status VARCHAR(20) DEFAULT 'compatible' CHECK (compatibility_status IN (
        'compatible', 'conflict', 'requires_override', 'not_applicable'
    )),
    compatibility_notes TEXT,
    
    -- Selection metadata
    is_selected BOOLEAN DEFAULT false,
    selection_method VARCHAR(20) DEFAULT 'filter' CHECK (selection_method IN (
        'filter', 'manual', 'search', 'import', 'all'
    )),
    selected_at TIMESTAMP WITH TIME ZONE,
    selected_by INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (selected_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(operation_id, employee_id)
);

-- =============================================================================
-- 4. BUSINESS RULES MASS ASSIGNMENT
-- =============================================================================

-- Business rules mass assignment from BDD lines 17-36
CREATE TABLE mass_assignment_business_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    
    -- Business rule configuration from BDD lines 27-28
    business_rule_id VARCHAR(50) NOT NULL,
    business_rule_name VARCHAR(200) NOT NULL,
    business_rule_description TEXT,
    
    -- Assignment preview from BDD lines 30-33
    total_employees_targeted INTEGER DEFAULT 0,
    employees_with_no_rule INTEGER DEFAULT 0,
    employees_with_custom_rule INTEGER DEFAULT 0,
    employees_requiring_override INTEGER DEFAULT 0,
    
    -- Assignment execution
    assignment_status VARCHAR(20) DEFAULT 'pending' CHECK (assignment_status IN (
        'pending', 'confirmed', 'applied', 'failed', 'cancelled'
    )),
    confirmation_required BOOLEAN DEFAULT true,
    override_existing_rules BOOLEAN DEFAULT false,
    
    -- Result tracking from BDD lines 35-36
    success_message TEXT,
    employees_successfully_assigned INTEGER DEFAULT 0,
    employees_failed_assignment INTEGER DEFAULT 0,
    assignment_errors JSONB DEFAULT '[]',
    
    -- Execution metadata
    applied_at TIMESTAMP WITH TIME ZONE,
    applied_by INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE,
    FOREIGN KEY (applied_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 5. VACATION SCHEMES MASS ASSIGNMENT
-- =============================================================================

-- Vacation schemes mass assignment from BDD lines 38-59
CREATE TABLE mass_assignment_vacation_schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    
    -- Vacation scheme configuration from BDD lines 47-52
    vacation_scheme_id VARCHAR(50) NOT NULL,
    vacation_scheme_name VARCHAR(200) NOT NULL,
    
    -- Scheme parameters from BDD lines 49-52
    minimum_time_between_vacations_days INTEGER DEFAULT 30,
    maximum_vacation_shift_days INTEGER DEFAULT 7,
    multiple_schemes_allowed BOOLEAN DEFAULT true,
    
    -- Validation configuration from BDD lines 53-56
    compatibility_check_required BOOLEAN DEFAULT true,
    allow_override_conflicts BOOLEAN DEFAULT false,
    
    -- Validation results tracking from BDD lines 54-56
    total_employees_compatible INTEGER DEFAULT 0,
    total_employees_conflicts INTEGER DEFAULT 0,
    total_employees_requiring_override INTEGER DEFAULT 0,
    
    -- Assignment execution from BDD lines 57-59
    assignment_status VARCHAR(20) DEFAULT 'pending' CHECK (assignment_status IN (
        'pending', 'validated', 'confirmed', 'applied', 'failed'
    )),
    overrides_confirmed BOOLEAN DEFAULT false,
    
    -- Result tracking
    success_message TEXT,
    employees_successfully_assigned INTEGER DEFAULT 0,
    scheme_configuration_applied BOOLEAN DEFAULT false,
    
    -- Execution metadata
    applied_at TIMESTAMP WITH TIME ZONE,
    applied_by INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE,
    FOREIGN KEY (applied_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. WORK HOURS MASS ASSIGNMENT
-- =============================================================================

-- Work hours mass assignment from BDD lines 61-82
CREATE TABLE mass_assignment_work_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    
    -- Assignment period configuration from BDD lines 67-69
    assignment_period VARCHAR(50) NOT NULL, -- e.g., "2024 Q1"
    hours_source VARCHAR(30) DEFAULT 'manual' CHECK (hours_source IN (
        'manual', 'template', 'calculated', 'imported'
    )),
    target_department VARCHAR(100),
    
    -- Work hours specification from BDD lines 72-75
    work_hours_by_period JSONB NOT NULL, -- Array of period configurations
    
    -- Assignment execution
    assignment_status VARCHAR(20) DEFAULT 'pending' CHECK (assignment_status IN (
        'pending', 'configured', 'confirmed', 'applied', 'failed'
    )),
    
    -- Result tracking from BDD lines 81-82
    success_message TEXT,
    employees_successfully_assigned INTEGER DEFAULT 0,
    periods_successfully_configured INTEGER DEFAULT 0,
    
    -- Execution metadata
    applied_at TIMESTAMP WITH TIME ZONE,
    applied_by INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE,
    FOREIGN KEY (applied_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 7. WORK HOURS PERIOD DETAILS
-- =============================================================================

-- Detailed work hours by period from BDD lines 72-75
CREATE TABLE work_hours_period_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_detail_id VARCHAR(50) NOT NULL UNIQUE,
    work_hours_assignment_id VARCHAR(50) NOT NULL,
    
    -- Period specification from BDD lines 72-75
    period_name VARCHAR(50) NOT NULL, -- e.g., "January 2024"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    work_hours INTEGER NOT NULL,
    period_description TEXT,
    
    -- Period characteristics
    period_type VARCHAR(20) DEFAULT 'monthly' CHECK (period_type IN (
        'weekly', 'monthly', 'quarterly', 'yearly', 'custom'
    )),
    is_standard_period BOOLEAN DEFAULT true,
    adjustment_reason TEXT,
    
    -- Employee assignment tracking from BDD lines 77-79
    employees_targeted INTEGER DEFAULT 0,
    employees_updated INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (work_hours_assignment_id) REFERENCES mass_assignment_work_hours(assignment_id) ON DELETE CASCADE,
    
    -- Ensure valid date range
    CHECK (end_date >= start_date),
    CHECK (work_hours > 0)
);

-- =============================================================================
-- 8. EMPLOYEE WORK HOURS ASSIGNMENTS
-- =============================================================================

-- Individual employee work hours assignments from BDD lines 77-79
CREATE TABLE employee_work_hours_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    period_detail_id VARCHAR(50) NOT NULL,
    employee_id INTEGER NOT NULL,
    
    -- Work hours assignment from BDD lines 77-79
    employee_name VARCHAR(200) NOT NULL,
    department VARCHAR(100),
    current_hours INTEGER,
    new_hours INTEGER NOT NULL,
    
    -- Assignment status from BDD lines 78-79
    assignment_status VARCHAR(20) DEFAULT 'will_update' CHECK (assignment_status IN (
        'will_update', 'updated', 'failed', 'skipped'
    )),
    assignment_notes TEXT,
    
    -- Change tracking
    hours_difference INTEGER,
    percentage_change DECIMAL(5,2),
    change_reason TEXT,
    
    -- Execution metadata
    assigned_at TIMESTAMP WITH TIME ZONE,
    assignment_error TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (period_detail_id) REFERENCES work_hours_period_details(period_detail_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(period_detail_id, employee_id)
);

-- =============================================================================
-- 9. SEARCH AND FILTERING INTERFACE
-- =============================================================================

-- Search functionality from BDD lines 105-110
CREATE TABLE mass_assignment_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    search_id VARCHAR(50) NOT NULL UNIQUE,
    operation_id VARCHAR(50) NOT NULL,
    
    -- Search configuration from BDD lines 105-109
    search_type VARCHAR(20) NOT NULL CHECK (search_type IN (
        'surname', 'full_name', 'personnel_number', 'department', 'position'
    )),
    search_term VARCHAR(200) NOT NULL,
    search_criteria TEXT,
    
    -- Search results from BDD lines 106-109
    total_matches INTEGER DEFAULT 0,
    exact_matches INTEGER DEFAULT 0,
    partial_matches INTEGER DEFAULT 0,
    
    -- Search execution
    search_executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    search_duration_ms INTEGER,
    search_successful BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (operation_id) REFERENCES mass_assignment_operations(operation_id) ON DELETE CASCADE
);

-- =============================================================================
-- 10. SEARCH RESULTS
-- =============================================================================

-- Search results details from BDD lines 107-109
CREATE TABLE mass_assignment_search_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id VARCHAR(50) NOT NULL UNIQUE,
    search_id VARCHAR(50) NOT NULL,
    employee_id INTEGER NOT NULL,
    
    -- Employee information from BDD lines 107-109
    employee_name VARCHAR(200) NOT NULL,
    personnel_number VARCHAR(50),
    department VARCHAR(100),
    
    -- Match details from BDD line 109
    match_type VARCHAR(20) NOT NULL CHECK (match_type IN (
        'name', 'personnel_number', 'department', 'position', 'multiple'
    )),
    match_score DECIMAL(3,2) DEFAULT 1.0,
    match_fields JSONB DEFAULT '[]',
    
    -- Selection capability from BDD line 110
    is_selectable BOOLEAN DEFAULT true,
    selection_restrictions TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (search_id) REFERENCES mass_assignment_searches(search_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    UNIQUE(search_id, employee_id)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Mass assignment operation queries
CREATE INDEX idx_mass_assignment_operations_type ON mass_assignment_operations(assignment_type);
CREATE INDEX idx_mass_assignment_operations_status ON mass_assignment_operations(operation_status);
CREATE INDEX idx_mass_assignment_operations_created_by ON mass_assignment_operations(created_by);
CREATE INDEX idx_mass_assignment_operations_department ON mass_assignment_operations(target_department);
CREATE INDEX idx_mass_assignment_operations_period ON mass_assignment_operations(assignment_period);

-- Filter queries
CREATE INDEX idx_mass_assignment_filters_operation ON mass_assignment_filters(operation_id);
CREATE INDEX idx_mass_assignment_filters_type ON mass_assignment_filters(filter_type);
CREATE INDEX idx_mass_assignment_filters_value ON mass_assignment_filters(filter_value);
CREATE INDEX idx_mass_assignment_filters_active ON mass_assignment_filters(is_active) WHERE is_active = true;

-- Employee selection queries
CREATE INDEX idx_mass_assignment_employee_selection_operation ON mass_assignment_employee_selection(operation_id);
CREATE INDEX idx_mass_assignment_employee_selection_employee ON mass_assignment_employee_selection(employee_id);
CREATE INDEX idx_mass_assignment_employee_selection_eligible ON mass_assignment_employee_selection(is_eligible) WHERE is_eligible = true;
CREATE INDEX idx_mass_assignment_employee_selection_selected ON mass_assignment_employee_selection(is_selected) WHERE is_selected = true;
CREATE INDEX idx_mass_assignment_employee_selection_department ON mass_assignment_employee_selection(department);
CREATE INDEX idx_mass_assignment_employee_selection_personnel ON mass_assignment_employee_selection(personnel_number);

-- Business rules assignment queries
CREATE INDEX idx_mass_assignment_business_rules_operation ON mass_assignment_business_rules(operation_id);
CREATE INDEX idx_mass_assignment_business_rules_rule ON mass_assignment_business_rules(business_rule_id);
CREATE INDEX idx_mass_assignment_business_rules_status ON mass_assignment_business_rules(assignment_status);

-- Vacation schemes assignment queries
CREATE INDEX idx_mass_assignment_vacation_schemes_operation ON mass_assignment_vacation_schemes(operation_id);
CREATE INDEX idx_mass_assignment_vacation_schemes_scheme ON mass_assignment_vacation_schemes(vacation_scheme_id);
CREATE INDEX idx_mass_assignment_vacation_schemes_status ON mass_assignment_vacation_schemes(assignment_status);

-- Work hours assignment queries
CREATE INDEX idx_mass_assignment_work_hours_operation ON mass_assignment_work_hours(operation_id);
CREATE INDEX idx_mass_assignment_work_hours_period ON mass_assignment_work_hours(assignment_period);
CREATE INDEX idx_mass_assignment_work_hours_department ON mass_assignment_work_hours(target_department);
CREATE INDEX idx_mass_assignment_work_hours_status ON mass_assignment_work_hours(assignment_status);

-- Work hours period queries
CREATE INDEX idx_work_hours_period_details_assignment ON work_hours_period_details(work_hours_assignment_id);
CREATE INDEX idx_work_hours_period_details_dates ON work_hours_period_details(start_date, end_date);
CREATE INDEX idx_work_hours_period_details_period ON work_hours_period_details(period_name);

-- Employee work hours queries
CREATE INDEX idx_employee_work_hours_assignments_period ON employee_work_hours_assignments(period_detail_id);
CREATE INDEX idx_employee_work_hours_assignments_employee ON employee_work_hours_assignments(employee_id);
CREATE INDEX idx_employee_work_hours_assignments_status ON employee_work_hours_assignments(assignment_status);
CREATE INDEX idx_employee_work_hours_assignments_department ON employee_work_hours_assignments(department);

-- Search queries
CREATE INDEX idx_mass_assignment_searches_operation ON mass_assignment_searches(operation_id);
CREATE INDEX idx_mass_assignment_searches_type ON mass_assignment_searches(search_type);
CREATE INDEX idx_mass_assignment_searches_term ON mass_assignment_searches(search_term);
CREATE INDEX idx_mass_assignment_searches_executed ON mass_assignment_searches(search_executed_at);

-- Search results queries
CREATE INDEX idx_mass_assignment_search_results_search ON mass_assignment_search_results(search_id);
CREATE INDEX idx_mass_assignment_search_results_employee ON mass_assignment_search_results(employee_id);
CREATE INDEX idx_mass_assignment_search_results_match ON mass_assignment_search_results(match_type);
CREATE INDEX idx_mass_assignment_search_results_selectable ON mass_assignment_search_results(is_selectable) WHERE is_selectable = true;
CREATE INDEX idx_mass_assignment_search_results_personnel ON mass_assignment_search_results(personnel_number);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_mass_assignment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER mass_assignment_operations_update_trigger
    BEFORE UPDATE ON mass_assignment_operations
    FOR EACH ROW EXECUTE FUNCTION update_mass_assignment_timestamp();

-- Calculate work hours difference trigger
CREATE OR REPLACE FUNCTION calculate_work_hours_difference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_hours IS NOT NULL AND NEW.new_hours IS NOT NULL THEN
        NEW.hours_difference = NEW.new_hours - NEW.current_hours;
        IF NEW.current_hours > 0 THEN
            NEW.percentage_change = (NEW.hours_difference::DECIMAL / NEW.current_hours) * 100;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER employee_work_hours_assignments_calculate_trigger
    BEFORE INSERT OR UPDATE ON employee_work_hours_assignments
    FOR EACH ROW EXECUTE FUNCTION calculate_work_hours_difference();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active mass assignment operations summary
CREATE VIEW v_active_mass_assignment_operations AS
SELECT 
    mao.operation_id,
    mao.operation_name,
    mao.assignment_type,
    mao.target_department,
    mao.total_employees_targeted,
    mao.total_employees_processed,
    mao.operation_status,
    CONCAT(e.first_name, ' ', e.last_name) as created_by_name,
    mao.created_at,
    CASE 
        WHEN mao.operation_status = 'pending' THEN 'Ready to Execute'
        WHEN mao.operation_status = 'in_progress' THEN 'Executing'
        WHEN mao.operation_status = 'completed' THEN 'Completed Successfully'
        WHEN mao.operation_status = 'failed' THEN 'Failed - Requires Attention'
        ELSE 'Unknown Status'
    END as status_description
FROM mass_assignment_operations mao
JOIN employees e ON mao.created_by = e.id
WHERE mao.operation_status IN ('pending', 'in_progress')
ORDER BY mao.created_at DESC;

-- Employee selection summary by operation
CREATE VIEW v_employee_selection_summary AS
SELECT 
    maes.operation_id,
    mao.operation_name,
    mao.assignment_type,
    COUNT(maes.id) as total_employees,
    COUNT(CASE WHEN maes.is_selected THEN 1 END) as selected_employees,
    COUNT(CASE WHEN maes.is_eligible THEN 1 END) as eligible_employees,
    COUNT(CASE WHEN maes.compatibility_status = 'conflict' THEN 1 END) as employees_with_conflicts,
    COUNT(CASE WHEN maes.assignment_action = 'override' THEN 1 END) as employees_requiring_override
FROM mass_assignment_employee_selection maes
JOIN mass_assignment_operations mao ON maes.operation_id = mao.operation_id
GROUP BY maes.operation_id, mao.operation_name, mao.assignment_type, mao.created_at
ORDER BY mao.created_at DESC;

-- Work hours assignment summary
CREATE VIEW v_work_hours_assignment_summary AS
SELECT 
    mawh.operation_id,
    mao.operation_name,
    mawh.assignment_period,
    mawh.target_department,
    COUNT(whpd.id) as total_periods,
    COUNT(ewha.id) as total_employee_assignments,
    COUNT(CASE WHEN ewha.assignment_status = 'updated' THEN 1 END) as successful_assignments,
    COUNT(CASE WHEN ewha.assignment_status = 'failed' THEN 1 END) as failed_assignments,
    AVG(ewha.new_hours) as average_new_hours,
    SUM(ewha.hours_difference) as total_hours_adjustment
FROM mass_assignment_work_hours mawh
JOIN mass_assignment_operations mao ON mawh.operation_id = mao.operation_id
LEFT JOIN work_hours_period_details whpd ON mawh.assignment_id = whpd.work_hours_assignment_id
LEFT JOIN employee_work_hours_assignments ewha ON whpd.period_detail_id = ewha.period_detail_id
GROUP BY mawh.operation_id, mao.operation_name, mawh.assignment_period, mawh.target_department, mao.created_at
ORDER BY mao.created_at DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert sample mass assignment operation
INSERT INTO mass_assignment_operations (operation_id, operation_name, assignment_type, target_department, created_by) VALUES
('mass_op_001', 'Q1 2024 Business Rules Assignment', 'business_rules', 'Customer Service', (SELECT id FROM employees LIMIT 1));

-- Insert sample filters
INSERT INTO mass_assignment_filters (filter_id, operation_id, filter_type, filter_value, filter_description) VALUES
('filter_001', 'mass_op_001', 'department', 'Customer Service', 'Target department'),
('filter_002', 'mass_op_001', 'employee_type', 'Office', 'Office operators only'),
('filter_003', 'mass_op_001', 'status', 'Active', 'Active employees only');

-- Insert sample work hours assignment
INSERT INTO mass_assignment_work_hours (assignment_id, operation_id, assignment_period, hours_source, target_department, work_hours_by_period) VALUES
('work_hours_001', 'mass_op_001', '2024 Q1', 'manual', 'Call Center', 
'[
  {"period": "January 2024", "start_date": "2024-01-01", "end_date": "2024-01-31", "work_hours": 168},
  {"period": "February 2024", "start_date": "2024-02-01", "end_date": "2024-02-29", "work_hours": 160},
  {"period": "March 2024", "start_date": "2024-03-01", "end_date": "2024-03-31", "work_hours": 176}
]');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE mass_assignment_operations IS 'BDD Lines 6-14: Mass assignment operations for efficient employee management';
COMMENT ON TABLE mass_assignment_filters IS 'BDD Lines 20-25, 42-46, 87-94: Employee filtering configuration for mass assignment';
COMMENT ON TABLE mass_assignment_employee_selection IS 'BDD Lines 25-26, 46, 76-79, 100-104: Employee selection and eligibility for mass assignment';
COMMENT ON TABLE mass_assignment_business_rules IS 'BDD Lines 17-36: Mass business rules assignment with confirmation dialog';
COMMENT ON TABLE mass_assignment_vacation_schemes IS 'BDD Lines 38-59: Mass vacation schemes assignment with validation and compatibility';
COMMENT ON TABLE mass_assignment_work_hours IS 'BDD Lines 61-82: Mass work hours assignment for reporting periods';
COMMENT ON TABLE work_hours_period_details IS 'BDD Lines 72-75: Detailed work hours specification by period';
COMMENT ON TABLE employee_work_hours_assignments IS 'BDD Lines 77-79: Individual employee work hours assignments';
COMMENT ON TABLE mass_assignment_searches IS 'BDD Lines 105-110: Search functionality for employee selection';
COMMENT ON TABLE mass_assignment_search_results IS 'BDD Lines 107-109: Search results with match details and selection capability';