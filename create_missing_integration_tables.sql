-- Create missing tables required for INTEGRATION_TEST_008
-- This script creates the essential tables needed for cross-system integration testing

-- Employee requests table (simplified version for integration testing)
CREATE TABLE IF NOT EXISTS employee_requests (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    request_type VARCHAR(50) NOT NULL,
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reason TEXT,
    priority_level INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMPTZ,
    approval_notes TEXT,
    last_sync_with_zup TIMESTAMPTZ,
    zup_recovery_strategy VARCHAR(100),
    zup_recovery_attempts INTEGER DEFAULT 0
);

-- Time tracking entries table
CREATE TABLE IF NOT EXISTS time_tracking_entries (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    work_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    time_code VARCHAR(10),
    time_code_description TEXT,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'pending',
    zup_sync_timestamp TIMESTAMPTZ,
    validation_errors TEXT,
    recovery_attempts INTEGER DEFAULT 0,
    last_recovery_attempt TIMESTAMPTZ
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_employee_requests_employee_id ON employee_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_requests_status ON employee_requests(status);
CREATE INDEX IF NOT EXISTS idx_employee_requests_type ON employee_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_employee_requests_sync_timestamp ON employee_requests(last_sync_with_zup);

CREATE INDEX IF NOT EXISTS idx_time_tracking_employee_id ON time_tracking_entries(employee_id);
CREATE INDEX IF NOT EXISTS idx_time_tracking_work_date ON time_tracking_entries(work_date);
CREATE INDEX IF NOT EXISTS idx_time_tracking_sync_status ON time_tracking_entries(sync_status);
CREATE INDEX IF NOT EXISTS idx_time_tracking_sync_timestamp ON time_tracking_entries(zup_sync_timestamp);

-- Grant permissions
GRANT ALL ON employee_requests TO postgres;
GRANT ALL ON time_tracking_entries TO postgres;
GRANT ALL ON employee_requests_id_seq TO postgres;
GRANT ALL ON time_tracking_entries_id_seq TO postgres;

-- Add comments
COMMENT ON TABLE employee_requests IS 'Employee requests for vacation, sick leave, schedule changes, etc.';
COMMENT ON TABLE time_tracking_entries IS 'Time tracking entries for validation with 1C ZUP system';