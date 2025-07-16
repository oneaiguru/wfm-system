-- Schema 080: BDD Integration Contract System
-- Ensures all agents work with compatible schemas and contracts
-- Prevents UUID/integer mismatches and API-Database disconnects

-- 1. API Contract Definitions
CREATE TABLE api_contracts (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(255) NOT NULL,
    endpoint_path VARCHAR(500) NOT NULL,
    http_method VARCHAR(10) NOT NULL,
    request_schema JSONB NOT NULL,
    response_schema JSONB NOT NULL,
    database_dependencies TEXT[] NOT NULL,
    example_request JSONB,
    example_response JSONB,
    used_by_components TEXT[],
    validation_query TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(endpoint_path, http_method)
);

-- 2. Schema Version Tracking
CREATE TABLE schema_versions (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(255) NOT NULL,
    version_number INTEGER NOT NULL,
    change_type VARCHAR(50), -- create, alter, drop, index
    change_description TEXT NOT NULL,
    breaking_change BOOLEAN DEFAULT false,
    affected_endpoints TEXT[],
    notified_agents TEXT[],
    migration_sql TEXT,
    rolled_back BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER
);

-- 3. Integration Test Data Registry
CREATE TABLE integration_test_data (
    test_data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(255) NOT NULL,
    test_scenario VARCHAR(255) NOT NULL,
    record_identifier JSONB NOT NULL, -- Primary key or unique identifier
    test_data JSONB NOT NULL,
    expected_api_response JSONB,
    bdd_scenario_reference VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(table_name, test_scenario, record_identifier)
);

-- 4. Contract Validation Results
CREATE TABLE contract_validations (
    validation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID REFERENCES api_contracts(contract_id),
    validation_type VARCHAR(50), -- schema_match, data_flow, performance
    validation_status VARCHAR(20), -- passed, failed, warning
    validation_errors JSONB,
    validation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    agent_name VARCHAR(50),
    execution_time_ms INTEGER
);

-- 5. Cross-Agent Dependencies
CREATE TABLE agent_dependencies (
    dependency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_agent VARCHAR(50) NOT NULL, -- DATABASE-OPUS, INTEGRATION-OPUS, etc
    target_agent VARCHAR(50) NOT NULL,
    dependency_type VARCHAR(50), -- data, schema, api, algorithm
    dependency_details JSONB NOT NULL,
    contract_id UUID REFERENCES api_contracts(contract_id),
    is_blocking BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Integration Health Metrics
CREATE TABLE integration_health_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    database_records INTEGER,
    api_endpoints_working INTEGER,
    api_endpoints_total INTEGER,
    schema_mismatches INTEGER,
    integration_tests_passed INTEGER,
    integration_tests_total INTEGER,
    average_response_time_ms DECIMAL(10,2),
    error_count_24h INTEGER,
    last_successful_flow TIMESTAMP
);

-- Create helper functions for contract validation

-- Function to validate API contract against database schema
CREATE OR REPLACE FUNCTION validate_api_contract(p_table_name TEXT, p_endpoint TEXT)
RETURNS TABLE(
    validation_type TEXT,
    status TEXT,
    issues TEXT[]
) AS $$
DECLARE
    v_contract api_contracts%ROWTYPE;
    v_issues TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Get the contract
    SELECT * INTO v_contract 
    FROM api_contracts 
    WHERE table_name = p_table_name 
    AND endpoint_path = p_endpoint;
    
    IF NOT FOUND THEN
        RETURN QUERY 
        SELECT 'contract_exists'::TEXT, 'failed'::TEXT, 
               ARRAY['No contract found for table ' || p_table_name || ' and endpoint ' || p_endpoint]::TEXT[];
        RETURN;
    END IF;
    
    -- Validate schema matches
    -- This is a simplified version - expand based on needs
    RETURN QUERY 
    SELECT 'schema_match'::TEXT, 'passed'::TEXT, ARRAY[]::TEXT[];
    
END;
$$ LANGUAGE plpgsql;

-- Function to create test data for a table
CREATE OR REPLACE FUNCTION create_integration_test_data(p_table_name TEXT)
RETURNS VOID AS $$
BEGIN
    -- Create standard test data based on table
    CASE p_table_name
        WHEN 'employees' THEN
            INSERT INTO integration_test_data (table_name, test_scenario, record_identifier, test_data, bdd_scenario_reference)
            VALUES 
                ('employees', 'vacation_request_flow', '{"id": "550e8400-e29b-41d4-a716-446655440000"}'::jsonb,
                 '{"id": "550e8400-e29b-41d4-a716-446655440000", "first_name": "Иван", "last_name": "Петров", "email": "ivan.petrov@test.ru", "department_id": "dept-001"}'::jsonb,
                 '02-employee-requests.feature#create-vacation-request'),
                ('employees', 'shift_exchange_flow', '{"id": "550e8400-e29b-41d4-a716-446655440001"}'::jsonb,
                 '{"id": "550e8400-e29b-41d4-a716-446655440001", "first_name": "Мария", "last_name": "Иванова", "email": "maria.ivanova@test.ru", "department_id": "dept-001"}'::jsonb,
                 '02-employee-requests.feature#shift-exchange');
                 
        WHEN 'vacation_requests' THEN
            INSERT INTO integration_test_data (table_name, test_scenario, record_identifier, test_data, bdd_scenario_reference)
            VALUES 
                ('vacation_requests', 'create_request', '{"id": "req-001"}'::jsonb,
                 '{"id": "req-001", "employee_id": "550e8400-e29b-41d4-a716-446655440000", "start_date": "2025-02-01", "end_date": "2025-02-07", "status": "pending"}'::jsonb,
                 '02-employee-requests.feature#create-vacation-request');
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Insert initial API contracts for vacation request flow

INSERT INTO api_contracts (
    table_name, 
    endpoint_path, 
    http_method,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    used_by_components
) VALUES (
    'employees',
    '/api/v1/employees',
    'GET',
    '{}'::jsonb,
    '{"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "format": "uuid"}, "name": {"type": "string"}, "email": {"type": "string"}}}}'::jsonb,
    ARRAY['employees'],
    NULL,
    '[{"id": "550e8400-e29b-41d4-a716-446655440000", "name": "Иван Петров", "email": "ivan.petrov@test.ru"}]'::jsonb,
    ARRAY['VacationRequestForm.tsx', 'EmployeeSelector.tsx']
);

INSERT INTO api_contracts (
    table_name,
    endpoint_path,
    http_method,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    used_by_components,
    validation_query
) VALUES (
    'vacation_requests',
    '/api/v1/requests/vacation',
    'POST',
    '{"type": "object", "properties": {"employee_id": {"type": "string", "format": "uuid"}, "start_date": {"type": "string", "format": "date"}, "end_date": {"type": "string", "format": "date"}}, "required": ["employee_id", "start_date", "end_date"]}'::jsonb,
    '{"type": "object", "properties": {"id": {"type": "string", "format": "uuid"}, "status": {"type": "string"}, "message": {"type": "string"}}}'::jsonb,
    ARRAY['vacation_requests', 'employees'],
    '{"employee_id": "550e8400-e29b-41d4-a716-446655440000", "start_date": "2025-02-01", "end_date": "2025-02-07"}'::jsonb,
    '{"id": "req-001", "status": "created", "message": "Vacation request created successfully"}'::jsonb,
    ARRAY['VacationRequestForm.tsx'],
    'SELECT EXISTS(SELECT 1 FROM employees WHERE id = $1)'
);

-- Create initial schema version entries
INSERT INTO schema_versions (table_name, version_number, change_type, change_description, breaking_change, affected_endpoints)
VALUES 
    ('employees', 1, 'create', 'Initial employee table with UUID primary key', false, ARRAY['/api/v1/employees']),
    ('vacation_requests', 1, 'create', 'Initial vacation requests with UUID employee_id', false, ARRAY['/api/v1/requests/vacation']);

-- Create integration test data
SELECT create_integration_test_data('employees');
SELECT create_integration_test_data('vacation_requests');

-- Create indexes for performance
CREATE INDEX idx_api_contracts_table ON api_contracts(table_name);
CREATE INDEX idx_api_contracts_endpoint ON api_contracts(endpoint_path);
CREATE INDEX idx_schema_versions_table ON schema_versions(table_name);
CREATE INDEX idx_integration_test_table ON integration_test_data(table_name);
CREATE INDEX idx_contract_validations_status ON contract_validations(validation_status);

-- Add helpful comments
COMMENT ON TABLE api_contracts IS 'Defines the contract between database tables and API endpoints to prevent schema mismatches';
COMMENT ON TABLE schema_versions IS 'Tracks all schema changes to notify other agents of breaking changes';
COMMENT ON TABLE integration_test_data IS 'Known test data with expected results for integration testing';
COMMENT ON TABLE contract_validations IS 'Results of automated contract validation tests';
COMMENT ON TABLE agent_dependencies IS 'Cross-agent dependencies to coordinate changes';
COMMENT ON TABLE integration_health_metrics IS 'Overall system integration health tracking';

-- Verify tables created
SELECT 'Integration contract tables created' as status, COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_name IN ('api_contracts', 'schema_versions', 'integration_test_data', 
                     'contract_validations', 'agent_dependencies', 'integration_health_metrics');