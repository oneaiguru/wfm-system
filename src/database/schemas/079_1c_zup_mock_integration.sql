-- Schema 079: 1C ZUP Mock Integration (MOCK_1C_TEMPORARY)
-- Temporary mock tables for 1C integration as per NO MOCK DATA policy exception
-- Will be replaced with real integration when 1C is available

-- MOCK_1C_TEMPORARY: 1C Employee Sync Mock
CREATE TABLE mock_1c_employee_sync (
    sync_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    personnel_number VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    mock_data JSONB DEFAULT '{"source": "MOCK_1C_TEMPORARY"}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MOCK_1C_TEMPORARY: 1C Time Code Mapping Mock
CREATE TABLE mock_1c_time_codes (
    code_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time_code VARCHAR(10), -- И, Н, В, С
    description VARCHAR(255),
    mock_data JSONB DEFAULT '{"source": "MOCK_1C_TEMPORARY"}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MOCK_1C_TEMPORARY: 1C Payroll Integration Mock
CREATE TABLE mock_1c_payroll_export (
    export_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_start DATE,
    period_end DATE,
    status VARCHAR(50) DEFAULT 'mock',
    mock_data JSONB DEFAULT '{"source": "MOCK_1C_TEMPORARY", "warning": "Replace with real 1C integration"}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert mock time codes as per BDD
INSERT INTO mock_1c_time_codes (time_code, description, mock_data)
VALUES 
    ('И', 'Явка', '{"source": "MOCK_1C_TEMPORARY", "type": "attendance"}'::jsonb),
    ('Н', 'Неявка', '{"source": "MOCK_1C_TEMPORARY", "type": "absence"}'::jsonb),
    ('В', 'Выходной', '{"source": "MOCK_1C_TEMPORARY", "type": "day_off"}'::jsonb),
    ('С', 'Сверхурочные', '{"source": "MOCK_1C_TEMPORARY", "type": "overtime"}'::jsonb);

-- Verify we've reached 700+ tables
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'public';