-- =============================================================================
-- init_test_db.sql
-- Quick database initialization for integration testing
-- =============================================================================
-- Purpose: Create minimal tables needed to run integration tests
-- This is a temporary solution for Day 2 integration testing
-- =============================================================================

-- Create database if needed (run as superuser)
-- CREATE DATABASE wfm_test;
-- \c wfm_test;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- CORE FOUNDATION TABLES (Minimal for testing)
-- =============================================================================

-- Master employee table (from schema 019)
CREATE TABLE IF NOT EXISTS zup_agent_data (
    tab_n VARCHAR(50) PRIMARY KEY,
    fio_full VARCHAR(300) NOT NULL,
    position_name VARCHAR(200),
    department VARCHAR(200),
    email VARCHAR(100),
    mobile_phone VARCHAR(50),
    work_phone VARCHAR(50),
    supervisor_tab_n VARCHAR(50),
    hire_date DATE,
    finish_work DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Time type classification (from schema 018)
CREATE TABLE IF NOT EXISTS argus_time_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_code VARCHAR(10) NOT NULL UNIQUE,
    type_code_ru VARCHAR(10) NOT NULL UNIQUE,
    type_name_en VARCHAR(100) NOT NULL,
    type_name_ru VARCHAR(100) NOT NULL,
    is_work_time BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Time entries (from schema 018)
CREATE TABLE IF NOT EXISTS argus_time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    entry_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    argus_time_type_id UUID REFERENCES argus_time_types(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Production calendar (from schema 016)
CREATE TABLE IF NOT EXISTS holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_date DATE NOT NULL UNIQUE,
    holiday_name VARCHAR(200) NOT NULL,
    is_holiday BOOLEAN DEFAULT true,
    is_shortened BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FORECASTING TABLES (Minimal for testing)
-- =============================================================================

-- Forecasting projects (from schema 027)
CREATE TABLE IF NOT EXISTS forecasting_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(200) NOT NULL,
    project_status VARCHAR(50) DEFAULT 'ACTIVE',
    service_id INTEGER,
    group_id INTEGER,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Historical data (from schema 027)
CREATE TABLE IF NOT EXISTS historical_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES forecasting_projects(id),
    data_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    call_volume INTEGER NOT NULL,
    aht_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Call volume forecasts (from schema 027)
CREATE TABLE IF NOT EXISTS call_volume_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES forecasting_projects(id),
    forecast_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    forecast_value DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Operator forecasts (from schema 027)
CREATE TABLE IF NOT EXISTS operator_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES forecasting_projects(id),
    interval_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    operator_requirement INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- OPTIMIZATION TABLES (Minimal for testing)
-- =============================================================================

-- Optimization projects (from schema 028)
CREATE TABLE IF NOT EXISTS optimization_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(200) NOT NULL,
    project_status VARCHAR(50) DEFAULT 'ACTIVE',
    optimization_date DATE NOT NULL,
    agents_count INTEGER NOT NULL,
    algorithm_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Coverage analysis (from schema 028)
CREATE TABLE IF NOT EXISTS coverage_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_project_id UUID REFERENCES optimization_projects(id),
    time_interval TIMESTAMP WITH TIME ZONE NOT NULL,
    required_agents INTEGER NOT NULL,
    scheduled_agents INTEGER NOT NULL,
    coverage_percentage DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Schedule suggestions (from schema 028)
CREATE TABLE IF NOT EXISTS schedule_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    optimization_project_id UUID REFERENCES optimization_projects(id),
    employee_tab_n VARCHAR(50) REFERENCES zup_agent_data(tab_n),
    suggestion_status VARCHAR(50) DEFAULT 'PENDING',
    efficiency_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- PROCESS MANAGEMENT TABLES (Minimal for testing)
-- =============================================================================

-- Process definitions (from schema 030)
CREATE TABLE IF NOT EXISTS process_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_name VARCHAR(200) NOT NULL UNIQUE,
    process_status VARCHAR(50) DEFAULT 'ACTIVE',
    execution_time_estimate INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Process instances (from schema 030)
CREATE TABLE IF NOT EXISTS process_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID REFERENCES process_definitions(id),
    process_status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Workflow tasks (from schema 030)
CREATE TABLE IF NOT EXISTS workflow_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID REFERENCES process_instances(id),
    task_status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- REPORTING TABLES (Minimal for testing)
-- =============================================================================

-- Report definitions (from schema 029)
CREATE TABLE IF NOT EXISTS report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(200) NOT NULL,
    report_category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- T-13 headers (from schema 026)
CREATE TABLE IF NOT EXISTS tabel_t13_headers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    month_year DATE NOT NULL,
    department VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Operational reports data (from schema 029)
CREATE TABLE IF NOT EXISTS operational_reports_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- OTHER REQUIRED TABLES
-- =============================================================================

-- Vacation calculations (from schema 020)
CREATE TABLE IF NOT EXISTS vacation_balance_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) REFERENCES zup_agent_data(tab_n),
    calculation_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Employee requests (from schema 021)
CREATE TABLE IF NOT EXISTS employee_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) REFERENCES zup_agent_data(tab_n),
    request_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Request approval stages (from schema 021)
CREATE TABLE IF NOT EXISTS request_approval_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES employee_requests(id),
    stage_status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Skills (from schema 003)
CREATE TABLE IF NOT EXISTS skill_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    skill_id INTEGER,
    skill_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Employee skills (from schema 003)
CREATE TABLE IF NOT EXISTS employee_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID,
    skill_id INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Insert minimal test data
-- =============================================================================

-- Insert time types
INSERT INTO argus_time_types (type_code, type_code_ru, type_name_en, type_name_ru) VALUES
('I', 'Я', 'Present', 'Явка'),
('H', 'Н', 'Night work', 'Ночные часы'),
('B', 'В', 'Weekend work', 'Работа в выходной'),
('C', 'С', 'Overtime', 'Сверхурочные')
ON CONFLICT (type_code) DO NOTHING;

-- Insert test employee
INSERT INTO zup_agent_data (tab_n, fio_full, position_name, department) VALUES
('00001', 'Иванов Иван Иванович', 'Supervisor', 'Call Center')
ON CONFLICT (tab_n) DO NOTHING;

\echo 'Test database initialized successfully!'