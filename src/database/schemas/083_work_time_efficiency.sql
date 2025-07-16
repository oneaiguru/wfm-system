-- Schema 083: Work Time Efficiency Configuration (BDD 29)
-- Operator productivity monitoring and calculation
-- Status-based time tracking with Russian compliance

-- 1. Work Status Definitions
CREATE TABLE work_status_definitions (
    status_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_code VARCHAR(20) NOT NULL UNIQUE,
    status_name VARCHAR(100) NOT NULL,
    status_name_ru VARCHAR(100),
    status_type VARCHAR(50), -- available, in_call, after_call, break, offline
    is_productive BOOLEAN DEFAULT true,
    is_net_load BOOLEAN DEFAULT false,
    is_talk_time BOOLEAN DEFAULT false,
    is_break_time BOOLEAN DEFAULT false,
    is_actual_timesheet BOOLEAN DEFAULT true,
    color_code VARCHAR(7), -- Hex color for UI display
    icon_name VARCHAR(50),
    display_order INTEGER,
    is_system BOOLEAN DEFAULT false, -- Cannot be deleted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Efficiency Parameters Configuration
CREATE TABLE efficiency_parameters (
    parameter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parameter_name VARCHAR(100) NOT NULL UNIQUE,
    parameter_code VARCHAR(50) NOT NULL UNIQUE,
    parameter_type VARCHAR(50), -- threshold, formula, weight
    parameter_value DECIMAL(10,4),
    unit_of_measure VARCHAR(20), -- percent, seconds, ratio
    description TEXT,
    description_ru TEXT,
    applies_to VARCHAR(50), -- agent, team, department, global
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Agent Time Tracking
CREATE TABLE agent_time_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    tracking_date DATE NOT NULL,
    shift_start_time TIMESTAMP NOT NULL,
    shift_end_time TIMESTAMP NOT NULL,
    total_shift_time INTEGER, -- seconds
    productive_time INTEGER DEFAULT 0,
    non_productive_time INTEGER DEFAULT 0,
    talk_time INTEGER DEFAULT 0,
    after_call_time INTEGER DEFAULT 0,
    break_time INTEGER DEFAULT 0,
    training_time INTEGER DEFAULT 0,
    meeting_time INTEGER DEFAULT 0,
    offline_time INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_id, tracking_date, shift_start_time)
);

-- 4. Status Change Log
CREATE TABLE agent_status_changes (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    from_status_id UUID REFERENCES work_status_definitions(status_id),
    to_status_id UUID REFERENCES work_status_definitions(status_id),
    change_timestamp TIMESTAMP NOT NULL,
    duration_seconds INTEGER, -- Time spent in from_status
    reason_code VARCHAR(50),
    reason_text TEXT,
    initiated_by VARCHAR(50), -- system, agent, supervisor
    location_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Productivity Calculations
CREATE TABLE productivity_calculations (
    calculation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID,
    team_id UUID,
    department_id UUID,
    calculation_date DATE NOT NULL,
    calculation_period VARCHAR(20), -- daily, weekly, monthly
    total_time_seconds INTEGER,
    productive_time_seconds INTEGER,
    productivity_percent DECIMAL(5,2),
    occupancy_percent DECIMAL(5,2),
    utilization_percent DECIMAL(5,2),
    efficiency_score DECIMAL(5,2),
    calculation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Break Management Rules
CREATE TABLE break_management_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255) NOT NULL,
    break_type VARCHAR(50), -- short, lunch, training, personal
    minimum_duration_minutes INTEGER,
    maximum_duration_minutes INTEGER,
    frequency_per_shift INTEGER,
    time_window_start TIME,
    time_window_end TIME,
    is_paid BOOLEAN DEFAULT true,
    counts_as_work_time BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT false,
    priority INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Efficiency Thresholds
CREATE TABLE efficiency_thresholds (
    threshold_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    threshold_level VARCHAR(20), -- critical, warning, target, excellent
    min_value DECIMAL(10,2),
    max_value DECIMAL(10,2),
    color_indicator VARCHAR(7), -- Hex color
    alert_enabled BOOLEAN DEFAULT false,
    alert_recipients TEXT[],
    applies_to_roles TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Time Category Mappings
CREATE TABLE time_category_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_id UUID REFERENCES work_status_definitions(status_id),
    time_category VARCHAR(50), -- productive, auxiliary, break, unavailable
    productivity_weight DECIMAL(5,2) DEFAULT 1.0, -- 0.0 to 1.0
    reporting_category VARCHAR(50),
    payroll_category VARCHAR(50), -- For 1C integration
    is_billable BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Real-time Efficiency Monitoring
CREATE TABLE realtime_efficiency_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    metric_timestamp TIMESTAMP NOT NULL,
    current_status_id UUID REFERENCES work_status_definitions(status_id),
    status_duration_seconds INTEGER,
    productivity_last_hour DECIMAL(5,2),
    productivity_current_shift DECIMAL(5,2),
    breaks_taken INTEGER,
    breaks_remaining INTEGER,
    efficiency_trend VARCHAR(20), -- improving, stable, declining
    alert_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Efficiency Reports Configuration
CREATE TABLE efficiency_report_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(50), -- individual, team, department
    metrics_included JSONB, -- Array of metric names
    calculation_formulas JSONB,
    grouping_options JSONB,
    time_periods TEXT[], -- daily, weekly, monthly, custom
    export_formats TEXT[], -- xlsx, pdf, csv
    schedule_frequency VARCHAR(50),
    recipients TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default work statuses
INSERT INTO work_status_definitions (status_code, status_name, status_name_ru, status_type, is_productive, is_net_load, is_talk_time, is_break_time, color_code, display_order)
VALUES 
    ('AVL', 'Available', 'Доступен', 'available', true, true, false, false, '#90EE90', 1),
    ('CALL', 'In Call', 'На звонке', 'in_call', true, true, true, false, '#4169E1', 2),
    ('ACW', 'After Call Work', 'Постобработка', 'after_call', true, true, false, false, '#87CEEB', 3),
    ('BRK', 'Break', 'Перерыв', 'break', false, false, false, true, '#FFD700', 4),
    ('LUN', 'Lunch', 'Обед', 'break', false, false, false, true, '#FFA500', 5),
    ('TRN', 'Training', 'Обучение', 'available', true, false, false, false, '#9370DB', 6),
    ('MTG', 'Meeting', 'Совещание', 'available', true, false, false, false, '#FF69B4', 7),
    ('OFF', 'Offline', 'Недоступен', 'offline', false, false, false, false, '#DC143C', 8);

-- Insert efficiency parameters
INSERT INTO efficiency_parameters (parameter_name, parameter_code, parameter_type, parameter_value, unit_of_measure, applies_to)
VALUES 
    ('Target Productivity', 'TARGET_PROD', 'threshold', 85.0, 'percent', 'global'),
    ('Minimum Occupancy', 'MIN_OCCUPANCY', 'threshold', 70.0, 'percent', 'agent'),
    ('Maximum Break Time', 'MAX_BREAK', 'threshold', 60.0, 'seconds', 'agent'),
    ('Efficiency Weight', 'EFF_WEIGHT', 'formula', 0.4, 'ratio', 'global');

-- Insert break rules
INSERT INTO break_management_rules (rule_name, break_type, minimum_duration_minutes, maximum_duration_minutes, frequency_per_shift, is_paid)
VALUES 
    ('Short Break', 'short', 10, 15, 2, true),
    ('Lunch Break', 'lunch', 30, 60, 1, false),
    ('Training Break', 'training', 15, 120, 1, true);

-- Create indexes
CREATE INDEX idx_status_changes_agent ON agent_status_changes(agent_id, change_timestamp);
CREATE INDEX idx_time_tracking_date ON agent_time_tracking(tracking_date, agent_id);
CREATE INDEX idx_productivity_calc_date ON productivity_calculations(calculation_date, agent_id);
CREATE INDEX idx_realtime_metrics_agent ON realtime_efficiency_metrics(agent_id, metric_timestamp);

-- Verify efficiency tables
SELECT COUNT(*) as efficiency_tables FROM information_schema.tables 
WHERE table_name LIKE '%efficiency%' OR table_name LIKE '%productivity%' OR table_name LIKE '%status%';