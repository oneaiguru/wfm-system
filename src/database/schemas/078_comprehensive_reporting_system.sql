-- Schema 078: Comprehensive Reporting System (BDD 23)
-- Enterprise reporting with flexible report editor
-- Russian business compliance and multi-format export

-- 1. Report Definitions
CREATE TABLE report_definitions (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_code VARCHAR(100) UNIQUE NOT NULL,
    report_name VARCHAR(500) NOT NULL,
    report_name_ru VARCHAR(500), -- Russian name
    report_category VARCHAR(100), -- operational, analytical, compliance, custom
    report_type VARCHAR(50), -- scheduled, ad_hoc, real_time
    description TEXT,
    description_ru TEXT,
    data_source_type VARCHAR(50), -- sql, groovy, api, composite
    query_text TEXT, -- SQL or GROOVY code
    status VARCHAR(50) DEFAULT 'draft', -- draft, published, blocked
    version INTEGER DEFAULT 1,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Report Parameters Configuration
CREATE TABLE report_parameters (
    parameter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    parameter_name VARCHAR(255) NOT NULL,
    parameter_label VARCHAR(255),
    parameter_label_ru VARCHAR(255),
    parameter_type VARCHAR(50), -- date, numeric_fractional, numeric_integer, logical, text, query_result
    is_mandatory BOOLEAN DEFAULT false,
    default_value VARCHAR(500),
    validation_regex VARCHAR(500),
    query_for_values TEXT, -- For query_result type
    display_order INTEGER,
    help_text TEXT,
    help_text_ru TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(report_id, parameter_name)
);

-- 3. Report Export Templates
CREATE TABLE report_export_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    template_name VARCHAR(255) NOT NULL,
    template_format VARCHAR(20), -- xlsx, docx, html, xslm, pdf
    template_file_path TEXT,
    template_content BYTEA, -- Binary template storage
    is_default BOOLEAN DEFAULT false,
    supports_russian BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Report Execution History
CREATE TABLE report_execution_history (
    execution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    executed_by VARCHAR(255),
    execution_start TIMESTAMP,
    execution_end TIMESTAMP,
    execution_status VARCHAR(50), -- running, completed, failed, cancelled
    parameters_used JSONB,
    row_count INTEGER,
    file_path TEXT,
    file_size_bytes BIGINT,
    export_format VARCHAR(20),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Scheduled Report Configuration
CREATE TABLE scheduled_reports (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    schedule_name VARCHAR(255),
    schedule_type VARCHAR(50), -- daily, weekly, monthly, custom_cron
    cron_expression VARCHAR(100),
    time_zone VARCHAR(50) DEFAULT 'Europe/Moscow',
    parameters JSONB,
    export_format VARCHAR(20),
    recipients TEXT[], -- Email addresses
    is_active BOOLEAN DEFAULT true,
    last_run TIMESTAMP,
    next_run TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Report Access Control
CREATE TABLE report_access_control (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    access_type VARCHAR(50), -- role, user, department, location
    access_value VARCHAR(255), -- role_name, user_id, dept_id, location_id
    permission_level VARCHAR(50), -- view, execute, edit, delete
    granted_by VARCHAR(255),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE(report_id, access_type, access_value)
);

-- 7. Report Data Sources
CREATE TABLE report_data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(255) UNIQUE NOT NULL,
    source_type VARCHAR(50), -- database, api, file, external_system
    connection_string TEXT,
    credentials_encrypted TEXT,
    refresh_schedule VARCHAR(100),
    last_refresh TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Report Metrics and KPIs
CREATE TABLE report_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    metric_name VARCHAR(255),
    metric_formula TEXT,
    metric_type VARCHAR(50), -- sum, average, count, percentage, custom
    threshold_warning DECIMAL(10,2),
    threshold_critical DECIMAL(10,2),
    trend_direction VARCHAR(20), -- higher_better, lower_better, stable
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Report Distribution Log
CREATE TABLE report_distribution_log (
    distribution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID REFERENCES report_execution_history(execution_id),
    recipient_email VARCHAR(255),
    distribution_method VARCHAR(50), -- email, portal, api, ftp
    sent_at TIMESTAMP,
    delivery_status VARCHAR(50), -- sent, delivered, failed, bounced
    error_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Custom Report Builder Metadata
CREATE TABLE report_builder_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES report_definitions(report_id),
    layout_config JSONB, -- Visual layout configuration
    chart_config JSONB, -- Chart and visualization settings
    filter_config JSONB, -- Interactive filter configuration
    drill_down_config JSONB, -- Drill-down navigation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert standard Russian reports
INSERT INTO report_definitions (report_code, report_name, report_name_ru, report_category, data_source_type, status)
VALUES 
    ('LOGIN_LOGOUT_ACTUAL', 'Actual Operator Login/Logout Report', 'Отчет по фактическим входам/выходам операторов', 'operational', 'sql', 'published'),
    ('T13_TIMESHEET', 'Form T-13 Timesheet', 'Табель учета рабочего времени (форма Т-13)', 'compliance', 'sql', 'published'),
    ('SCHEDULE_COMPLIANCE', 'Schedule Compliance Report', 'Отчет по соблюдению расписания', 'analytical', 'sql', 'published'),
    ('FORECAST_ACCURACY', 'Forecast Accuracy Analysis', 'Анализ точности прогнозирования', 'analytical', 'groovy', 'published');

-- Add parameters for login/logout report
INSERT INTO report_parameters (report_id, parameter_name, parameter_label, parameter_label_ru, parameter_type, is_mandatory, display_order)
SELECT 
    report_id,
    param_name,
    param_label,
    param_label_ru,
    param_type,
    mandatory,
    order_num
FROM report_definitions
CROSS JOIN (VALUES 
    ('date_from', 'Date From', 'Дата с', 'date', true, 1),
    ('date_to', 'Date To', 'Дата по', 'date', true, 2),
    ('department', 'Department', 'Подразделение', 'query_result', true, 3),
    ('employee_name', 'Employee Name', 'ФИО сотрудника', 'text', false, 4)
) AS params(param_name, param_label, param_label_ru, param_type, mandatory, order_num)
WHERE report_code = 'LOGIN_LOGOUT_ACTUAL';

-- Create indexes
CREATE INDEX idx_report_params_report ON report_parameters(report_id);
CREATE INDEX idx_report_execution_report ON report_execution_history(report_id);
CREATE INDEX idx_report_execution_status ON report_execution_history(execution_status);
CREATE INDEX idx_scheduled_reports_active ON scheduled_reports(is_active, next_run);

-- Verify reporting tables
SELECT COUNT(*) as reporting_tables_count FROM information_schema.tables WHERE table_name LIKE 'report_%';