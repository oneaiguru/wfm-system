-- =============================================================================
-- 024_shift_templates_kpi.sql
-- SHIFT TEMPLATES + KPI DASHBOARD - Shows Scheduling Capability
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Basic shift templates and KPI dashboard for demo completeness
-- Strategy: Show we can handle scheduling fundamentals without complex optimization
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SHIFT_TEMPLATES - Pre-defined shift patterns
-- =============================================================================
CREATE TABLE shift_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(200) NOT NULL,
    template_code VARCHAR(50) NOT NULL UNIQUE,
    description_ru TEXT,
    
    -- Shift timing
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_hours DECIMAL(4,2) GENERATED ALWAYS AS (
        CASE 
            WHEN end_time > start_time THEN 
                EXTRACT(EPOCH FROM (end_time - start_time)) / 3600.0
            ELSE 
                EXTRACT(EPOCH FROM (end_time + INTERVAL '24 hours' - start_time)) / 3600.0
        END
    ) STORED,
    
    -- Break configuration
    break_duration_minutes INTEGER DEFAULT 30,
    lunch_duration_minutes INTEGER DEFAULT 60,
    
    -- Shift characteristics
    is_night_shift BOOLEAN DEFAULT false,
    requires_special_skills BOOLEAN DEFAULT false,
    max_consecutive_days INTEGER DEFAULT 5,
    
    -- Work pattern
    work_pattern JSONB DEFAULT '{}', -- Flexible work pattern definition
    coverage_profile JSONB DEFAULT '{}', -- Coverage requirements by hour
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used DATE,
    
    -- Template metadata
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    template_category VARCHAR(50) DEFAULT 'standard'
);

-- Insert common shift templates
INSERT INTO shift_templates (template_name, template_code, description_ru, start_time, end_time, break_duration_minutes, lunch_duration_minutes, template_category) VALUES
('Утренняя смена 8 часов', 'MORNING_8H', 'Стандартная утренняя смена с 9:00 до 18:00', '09:00', '18:00', 15, 60, 'standard'),
('Дневная смена 8 часов', 'DAY_8H', 'Дневная смена с 10:00 до 19:00', '10:00', '19:00', 15, 60, 'standard'),
('Вечерняя смена 8 часов', 'EVENING_8H', 'Вечерняя смена с 14:00 до 23:00', '14:00', '23:00', 15, 60, 'standard'),
('Ночная смена 8 часов', 'NIGHT_8H', 'Ночная смена с 23:00 до 08:00', '23:00', '08:00', 15, 60, 'night'),
('Длинная смена 12 часов', 'LONG_12H', 'Удлиненная смена с 08:00 до 20:00', '08:00', '20:00', 30, 60, 'extended'),
('Короткая смена 4 часа', 'SHORT_4H', 'Короткая смена с 17:00 до 21:00', '17:00', '21:00', 15, 0, 'part_time'),
('Гибкий график 6 часов', 'FLEX_6H', 'Гибкий график с 11:00 до 17:00', '11:00', '17:00', 15, 30, 'flexible');

-- Update work patterns and coverage profiles
UPDATE shift_templates SET
    work_pattern = jsonb_build_object(
        'type', 'fixed',
        'breaks', jsonb_build_array(
            jsonb_build_object('type', 'break', 'duration', break_duration_minutes, 'timing', 'flexible'),
            jsonb_build_object('type', 'lunch', 'duration', lunch_duration_minutes, 'timing', 'mid_shift')
        ),
        'overtime_eligible', true
    ),
    coverage_profile = CASE template_code
        WHEN 'MORNING_8H' THEN '{"peak_hours": ["09:00-12:00", "14:00-17:00"], "coverage_level": "high"}'::jsonb
        WHEN 'DAY_8H' THEN '{"peak_hours": ["10:00-13:00", "15:00-18:00"], "coverage_level": "high"}'::jsonb
        WHEN 'EVENING_8H' THEN '{"peak_hours": ["16:00-20:00"], "coverage_level": "medium"}'::jsonb
        WHEN 'NIGHT_8H' THEN '{"peak_hours": ["23:00-02:00"], "coverage_level": "low"}'::jsonb
        ELSE '{"coverage_level": "standard"}'::jsonb
    END;

-- =============================================================================
-- 2. SHIFT_ASSIGNMENTS - Template assignments to employees
-- =============================================================================
CREATE TABLE shift_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Assignment details
    employee_tab_n VARCHAR(50) NOT NULL,
    shift_template_id UUID NOT NULL,
    assignment_date DATE NOT NULL,
    
    -- Schedule details
    actual_start_time TIME,
    actual_end_time TIME,
    assignment_status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, confirmed, completed, cancelled
    
    -- Override options
    start_time_override TIME, -- Custom start time if different from template
    end_time_override TIME,   -- Custom end time if different from template
    break_override INTEGER,   -- Custom break duration
    
    -- Assignment metadata
    assigned_by VARCHAR(100),
    assignment_reason VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Notes and comments
    assignment_notes TEXT,
    employee_confirmation BOOLEAN DEFAULT false,
    manager_approval BOOLEAN DEFAULT true,
    
    CONSTRAINT fk_shift_assignments_employee 
        FOREIGN KEY (employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT fk_shift_assignments_template 
        FOREIGN KEY (shift_template_id) REFERENCES shift_templates(id),
    
    UNIQUE(employee_tab_n, assignment_date)
);

-- Indexes for assignments
CREATE INDEX idx_shift_assignments_employee ON shift_assignments(employee_tab_n);
CREATE INDEX idx_shift_assignments_date ON shift_assignments(assignment_date);
CREATE INDEX idx_shift_assignments_template ON shift_assignments(shift_template_id);

-- =============================================================================
-- 3. COVERAGE_VISUALIZATION - Track coverage by time intervals
-- =============================================================================
CREATE TABLE coverage_visualization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Time interval
    coverage_date DATE NOT NULL,
    time_interval TIME NOT NULL, -- 30-minute intervals
    
    -- Coverage metrics
    required_agents INTEGER DEFAULT 1,
    scheduled_agents INTEGER DEFAULT 0,
    available_agents INTEGER DEFAULT 0,
    coverage_percent DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN required_agents > 0 
             THEN (scheduled_agents::DECIMAL / required_agents) * 100 
             ELSE 100 END
    ) STORED,
    
    -- Coverage status
    coverage_status VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN scheduled_agents >= required_agents THEN 'adequate'
            WHEN scheduled_agents >= (required_agents * 0.8) THEN 'warning'
            ELSE 'critical'
        END
    ) STORED,
    
    -- Visual indicators
    coverage_color VARCHAR(7) GENERATED ALWAYS AS (
        CASE 
            WHEN scheduled_agents >= required_agents THEN '#4CAF50'
            WHEN scheduled_agents >= (required_agents * 0.8) THEN '#FF9800'
            ELSE '#F44336'
        END
    ) STORED,
    
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(coverage_date, time_interval)
);

-- =============================================================================
-- 4. KPI_DASHBOARD_METRICS - Executive KPI tracking
-- =============================================================================
CREATE TABLE kpi_dashboard_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- KPI identification
    kpi_name VARCHAR(100) NOT NULL,
    kpi_name_ru VARCHAR(200) NOT NULL,
    kpi_category VARCHAR(50) NOT NULL,
    
    -- Current values
    current_value DECIMAL(15,4) NOT NULL,
    target_value DECIMAL(15,4),
    previous_value DECIMAL(15,4),
    
    -- Time period
    measurement_period VARCHAR(50) DEFAULT 'current', -- current, daily, weekly, monthly
    measurement_date DATE DEFAULT CURRENT_DATE,
    
    -- Performance indicators
    variance_percent DECIMAL(8,2) GENERATED ALWAYS AS (
        CASE WHEN target_value > 0 
             THEN ((current_value - target_value) / target_value) * 100 
             ELSE NULL END
    ) STORED,
    
    trend_direction VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN current_value > previous_value THEN 'up'
            WHEN current_value < previous_value THEN 'down'
            ELSE 'stable'
        END
    ) STORED,
    
    performance_status VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN target_value IS NULL THEN 'no_target'
            WHEN current_value >= target_value THEN 'target_met'
            WHEN current_value >= (target_value * 0.9) THEN 'near_target'
            ELSE 'below_target'
        END
    ) STORED,
    
    -- Display settings
    display_format VARCHAR(20) DEFAULT 'number', -- number, percent, currency, time
    display_unit VARCHAR(20),
    chart_type VARCHAR(20) DEFAULT 'gauge', -- gauge, line, bar, trend
    
    -- Metadata
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calculation_source VARCHAR(100),
    is_visible BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 100
);

-- Insert key KPIs for dashboard
INSERT INTO kpi_dashboard_metrics (kpi_name, kpi_name_ru, kpi_category, current_value, target_value, display_format, display_unit, display_order) VALUES
('schedule_adherence', 'Соблюдение расписания', 'performance', 87.5, 85.0, 'percent', '%', 10),
('forecast_accuracy', 'Точность прогнозирования', 'planning', 85.2, 80.0, 'percent', '%', 20),
('agent_utilization', 'Загрузка агентов', 'efficiency', 82.3, 80.0, 'percent', '%', 30),
('service_level', 'Уровень сервиса', 'service', 88.7, 80.0, 'percent', '%', 40),
('average_handle_time', 'Среднее время обработки', 'service', 285, 300, 'time', 'сек', 50),
('first_call_resolution', 'Решение с первого обращения', 'quality', 76.4, 75.0, 'percent', '%', 60),
('employee_satisfaction', 'Удовлетворенность сотрудников', 'hr', 4.2, 4.0, 'number', '/5', 70),
('cost_per_call', 'Стоимость за звонок', 'financial', 125.50, 130.00, 'currency', 'руб', 80);

-- =============================================================================
-- FUNCTIONS: Shift Template and Coverage Management
-- =============================================================================

-- Function to assign shift template to employee
CREATE OR REPLACE FUNCTION assign_shift_template(
    p_employee_tab_n VARCHAR(50),
    p_template_code VARCHAR(50),
    p_assignment_date DATE,
    p_assigned_by VARCHAR(100) DEFAULT 'system'
) RETURNS JSONB AS $$
DECLARE
    v_template shift_templates%ROWTYPE;
    v_assignment_id UUID;
    v_result JSONB;
BEGIN
    -- Get template details
    SELECT * INTO v_template
    FROM shift_templates
    WHERE template_code = p_template_code AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Shift template not found: %', p_template_code;
    END IF;
    
    -- Create assignment
    INSERT INTO shift_assignments (
        employee_tab_n,
        shift_template_id,
        assignment_date,
        actual_start_time,
        actual_end_time,
        assigned_by,
        assignment_reason
    ) VALUES (
        p_employee_tab_n,
        v_template.id,
        p_assignment_date,
        v_template.start_time,
        v_template.end_time,
        p_assigned_by,
        'Template assignment: ' || v_template.template_name
    ) ON CONFLICT (employee_tab_n, assignment_date) 
    DO UPDATE SET
        shift_template_id = EXCLUDED.shift_template_id,
        actual_start_time = EXCLUDED.actual_start_time,
        actual_end_time = EXCLUDED.actual_end_time,
        assignment_reason = EXCLUDED.assignment_reason,
        last_modified = CURRENT_TIMESTAMP
    RETURNING id INTO v_assignment_id;
    
    -- Update template usage
    UPDATE shift_templates SET
        usage_count = usage_count + 1,
        last_used = p_assignment_date
    WHERE id = v_template.id;
    
    -- Update coverage visualization
    PERFORM update_coverage_visualization(p_assignment_date);
    
    v_result := jsonb_build_object(
        'assignment_id', v_assignment_id,
        'employee_tab_n', p_employee_tab_n,
        'template_name', v_template.template_name,
        'assignment_date', p_assignment_date,
        'start_time', v_template.start_time,
        'end_time', v_template.end_time,
        'duration_hours', v_template.duration_hours
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to update coverage visualization
CREATE OR REPLACE FUNCTION update_coverage_visualization(p_date DATE) RETURNS INTEGER AS $$
DECLARE
    v_time_slot TIME;
    v_required INTEGER;
    v_scheduled INTEGER;
    v_updated INTEGER := 0;
BEGIN
    -- Generate 30-minute time slots for the day
    FOR hour IN 0..23 LOOP
        FOR minute IN 0..1 LOOP -- 0 = :00, 1 = :30
            v_time_slot := (hour || ':' || (minute * 30))::TIME;
            
            -- Calculate required agents (simple logic - more during business hours)
            v_required := CASE 
                WHEN v_time_slot BETWEEN '08:00' AND '20:00' THEN 8
                WHEN v_time_slot BETWEEN '20:00' AND '23:00' OR v_time_slot BETWEEN '06:00' AND '08:00' THEN 4
                ELSE 2
            END;
            
            -- Count scheduled agents for this time slot
            SELECT COUNT(*) INTO v_scheduled
            FROM shift_assignments sa
            JOIN shift_templates st ON st.id = sa.shift_template_id
            WHERE sa.assignment_date = p_date
            AND sa.assignment_status = 'scheduled'
            AND v_time_slot BETWEEN 
                COALESCE(sa.start_time_override, st.start_time) AND 
                COALESCE(sa.end_time_override, st.end_time);
            
            -- Insert or update coverage data
            INSERT INTO coverage_visualization (
                coverage_date,
                time_interval,
                required_agents,
                scheduled_agents
            ) VALUES (
                p_date,
                v_time_slot,
                v_required,
                v_scheduled
            ) ON CONFLICT (coverage_date, time_interval) 
            DO UPDATE SET
                required_agents = EXCLUDED.required_agents,
                scheduled_agents = EXCLUDED.scheduled_agents,
                last_updated = CURRENT_TIMESTAMP;
            
            v_updated := v_updated + 1;
        END LOOP;
    END LOOP;
    
    RETURN v_updated;
END;
$$ LANGUAGE plpgsql;

-- Function to update KPI dashboard metrics
CREATE OR REPLACE FUNCTION update_kpi_metrics() RETURNS INTEGER AS $$
DECLARE
    v_updated INTEGER := 0;
BEGIN
    -- Update schedule adherence
    UPDATE kpi_dashboard_metrics SET
        previous_value = current_value,
        current_value = (
            SELECT COALESCE(AVG(todays_adherence_percent), 85)
            FROM realtime_agent_status 
            WHERE is_scheduled_today = true
        ),
        last_updated = CURRENT_TIMESTAMP,
        calculation_source = 'realtime_agent_status'
    WHERE kpi_name = 'schedule_adherence';
    
    -- Update forecast accuracy
    UPDATE kpi_dashboard_metrics SET
        previous_value = current_value,
        current_value = (
            SELECT COALESCE(AVG(agent_accuracy_percent), 85)
            FROM v_forecast_accuracy
            WHERE hour >= CURRENT_DATE - INTERVAL '1 day'
        ),
        last_updated = CURRENT_TIMESTAMP,
        calculation_source = 'v_forecast_accuracy'
    WHERE kpi_name = 'forecast_accuracy';
    
    -- Update agent utilization
    UPDATE kpi_dashboard_metrics SET
        previous_value = current_value,
        current_value = (
            SELECT COALESCE(
                100.0 * COUNT(*) FILTER (WHERE is_productive = true) / 
                NULLIF(COUNT(*), 0), 80
            )
            FROM realtime_agent_status
            WHERE is_scheduled_today = true
        ),
        last_updated = CURRENT_TIMESTAMP,
        calculation_source = 'realtime_agent_status'
    WHERE kpi_name = 'agent_utilization';
    
    -- Update service level
    UPDATE kpi_dashboard_metrics SET
        previous_value = current_value,
        current_value = (
            SELECT COALESCE(AVG(service_level_percent), 85)
            FROM realtime_service_levels
            WHERE interval_start >= CURRENT_DATE
        ),
        last_updated = CURRENT_TIMESTAMP,
        calculation_source = 'realtime_service_levels'
    WHERE kpi_name = 'service_level';
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    
    RETURN v_updated;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Shift Template and KPI Dashboards
-- =============================================================================

-- Shift template library view
CREATE VIEW v_shift_template_library AS
SELECT 
    id,
    template_name,
    template_code,
    description_ru,
    start_time,
    end_time,
    duration_hours,
    break_duration_minutes,
    lunch_duration_minutes,
    is_night_shift,
    template_category,
    
    -- Formatted display
    start_time::TEXT || ' - ' || end_time::TEXT as shift_period,
    duration_hours || ' часов' as duration_formatted,
    
    -- Usage statistics
    usage_count,
    last_used,
    
    -- Category display in Russian
    CASE template_category
        WHEN 'standard' THEN 'Стандартные'
        WHEN 'night' THEN 'Ночные'
        WHEN 'extended' THEN 'Удлиненные'
        WHEN 'part_time' THEN 'Частичная занятость'
        WHEN 'flexible' THEN 'Гибкие'
        ELSE 'Другие'
    END as category_ru,
    
    is_active,
    created_at
FROM shift_templates
ORDER BY template_category, start_time;

-- Daily schedule view with coverage
CREATE VIEW v_daily_schedule_coverage AS
SELECT 
    sa.assignment_date,
    sa.employee_tab_n,
    zda.lastname || ' ' || zda.firstname as employee_name,
    st.template_name,
    COALESCE(sa.start_time_override, st.start_time) as shift_start,
    COALESCE(sa.end_time_override, st.end_time) as shift_end,
    st.duration_hours,
    sa.assignment_status,
    sa.employee_confirmation,
    
    -- Status in Russian
    CASE sa.assignment_status
        WHEN 'scheduled' THEN 'Запланировано'
        WHEN 'confirmed' THEN 'Подтверждено'
        WHEN 'completed' THEN 'Завершено'
        WHEN 'cancelled' THEN 'Отменено'
    END as status_ru,
    
    -- Confirmation status
    CASE 
        WHEN sa.employee_confirmation THEN '✓ Подтверждено'
        ELSE '○ Ожидает подтверждения'
    END as confirmation_status_ru,
    
    sa.assignment_notes,
    sa.created_at
FROM shift_assignments sa
JOIN zup_agent_data zda ON zda.tab_n = sa.employee_tab_n
JOIN shift_templates st ON st.id = sa.shift_template_id
WHERE sa.assignment_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY sa.assignment_date DESC, shift_start;

-- Coverage visualization view
CREATE VIEW v_coverage_heatmap AS
SELECT 
    coverage_date,
    time_interval,
    required_agents,
    scheduled_agents,
    available_agents,
    coverage_percent,
    coverage_status,
    coverage_color,
    
    -- Time formatting
    time_interval::TEXT as time_slot,
    TO_CHAR(coverage_date, 'DD.MM.YYYY') as date_formatted,
    
    -- Status in Russian
    CASE coverage_status
        WHEN 'adequate' THEN 'Достаточно'
        WHEN 'warning' THEN 'Внимание'
        WHEN 'critical' THEN 'Критично'
    END as status_ru,
    
    -- Coverage description
    scheduled_agents || ' / ' || required_agents as coverage_ratio,
    
    last_updated
FROM coverage_visualization
WHERE coverage_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY coverage_date DESC, time_interval;

-- Executive KPI dashboard view
CREATE VIEW v_executive_kpi_dashboard AS
SELECT 
    kpi_name,
    kpi_name_ru,
    kpi_category,
    
    -- Values
    current_value,
    target_value,
    previous_value,
    variance_percent,
    
    -- Formatted values
    CASE display_format
        WHEN 'percent' THEN ROUND(current_value, 1) || '%'
        WHEN 'currency' THEN ROUND(current_value, 2) || ' ' || COALESCE(display_unit, 'руб')
        WHEN 'time' THEN ROUND(current_value, 0) || ' ' || COALESCE(display_unit, 'сек')
        ELSE ROUND(current_value, 1) || ' ' || COALESCE(display_unit, '')
    END as formatted_value,
    
    CASE display_format
        WHEN 'percent' THEN ROUND(target_value, 1) || '%'
        WHEN 'currency' THEN ROUND(target_value, 2) || ' ' || COALESCE(display_unit, 'руб')
        WHEN 'time' THEN ROUND(target_value, 0) || ' ' || COALESCE(display_unit, 'сек')
        ELSE ROUND(target_value, 1) || ' ' || COALESCE(display_unit, '')
    END as formatted_target,
    
    -- Performance indicators
    trend_direction,
    performance_status,
    
    -- Trend arrow
    CASE trend_direction
        WHEN 'up' THEN '↗'
        WHEN 'down' THEN '↘'
        ELSE '→'
    END as trend_arrow,
    
    -- Performance status in Russian
    CASE performance_status
        WHEN 'target_met' THEN 'Цель достигнута'
        WHEN 'near_target' THEN 'Близко к цели'
        WHEN 'below_target' THEN 'Ниже цели'
        ELSE 'Без цели'
    END as status_ru,
    
    -- Color coding
    CASE performance_status
        WHEN 'target_met' THEN '#4CAF50'
        WHEN 'near_target' THEN '#FF9800'
        WHEN 'below_target' THEN '#F44336'
        ELSE '#9E9E9E'
    END as status_color,
    
    -- Category in Russian
    CASE kpi_category
        WHEN 'performance' THEN 'Производительность'
        WHEN 'planning' THEN 'Планирование'
        WHEN 'efficiency' THEN 'Эффективность'
        WHEN 'service' THEN 'Сервис'
        WHEN 'quality' THEN 'Качество'
        WHEN 'hr' THEN 'Персонал'
        WHEN 'financial' THEN 'Финансы'
        ELSE kpi_category
    END as category_ru,
    
    last_updated,
    display_order
FROM kpi_dashboard_metrics
WHERE is_visible = true
ORDER BY display_order;

-- =============================================================================
-- Initialize demo data
-- =============================================================================

-- Assign some shift templates for demo
INSERT INTO shift_assignments (employee_tab_n, shift_template_id, assignment_date, assigned_by)
SELECT 
    zda.tab_n,
    st.id,
    CURRENT_DATE + (random() * 7)::INTEGER,
    'demo_manager'
FROM zup_agent_data zda
CROSS JOIN shift_templates st
WHERE random() < 0.3 -- 30% chance of assignment
AND st.is_active = true
LIMIT 50;

-- Update coverage for next 7 days
SELECT update_coverage_visualization(CURRENT_DATE + i)
FROM generate_series(0, 6) i;

-- Update KPI metrics
SELECT update_kpi_metrics();

COMMENT ON TABLE shift_templates IS 'Pre-defined shift patterns for scheduling';
COMMENT ON TABLE shift_assignments IS 'Shift template assignments to employees';
COMMENT ON TABLE coverage_visualization IS 'Coverage tracking for red/green visualization';
COMMENT ON TABLE kpi_dashboard_metrics IS 'Executive KPI dashboard metrics';
COMMENT ON VIEW v_shift_template_library IS 'Shift template library for scheduling UI';
COMMENT ON VIEW v_executive_kpi_dashboard IS 'Executive KPI dashboard with Russian formatting';