-- =============================================================================
-- fix_time_code_dashboard_link.sql
-- GREEN PHASE: Fix missing link between Time Classification and Dashboard
-- =============================================================================
-- Purpose: Connect argus_time_types to agent_status_realtime for Russian display
-- This enables dashboard to show И/Н/В/С codes with descriptions
-- =============================================================================

-- First, add time_type_id column to agent_status_realtime if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'agent_status_realtime' 
        AND column_name = 'time_type_id'
    ) THEN
        ALTER TABLE agent_status_realtime 
        ADD COLUMN time_type_id UUID,
        ADD CONSTRAINT fk_agent_status_time_type 
            FOREIGN KEY (time_type_id) REFERENCES argus_time_types(id);
    END IF;
END $$;

-- Update the view to properly join time codes
CREATE OR REPLACE VIEW v_realtime_dashboard AS
SELECT 
    asr.employee_tab_n,
    asr.employee_name,
    asr.current_status,
    asr.status_russian,
    COALESCE(
        att.type_code || ' - ' || att.type_name_ru,
        asr.time_code || ' - ' || asr.time_code_display
    ) as time_code_display,
    asr.last_updated,
    
    -- Service level data
    slm.current_service_level,
    slm.target_service_level,
    
    -- Coverage data  
    car.coverage_percentage,
    car.coverage_gap,
    
    -- Executive KPIs
    (SELECT kpi_value FROM executive_kpi_dashboard WHERE kpi_name = 'Forecast Accuracy' LIMIT 1) as forecast_accuracy
    
FROM agent_status_realtime asr
LEFT JOIN argus_time_types att ON att.id = asr.time_type_id
CROSS JOIN LATERAL (
    SELECT * FROM service_level_monitoring 
    ORDER BY calculation_time DESC 
    LIMIT 1
) slm
CROSS JOIN LATERAL (
    SELECT * FROM coverage_analysis_realtime 
    ORDER BY analysis_time DESC 
    LIMIT 1
) car
ORDER BY asr.last_updated DESC;

-- Create function to update agent status with proper time code
CREATE OR REPLACE FUNCTION update_agent_realtime_status(
    p_employee_tab_n VARCHAR(50),
    p_status VARCHAR(50),
    p_time_code VARCHAR(10)
) RETURNS void AS $$
DECLARE
    v_time_type_id UUID;
    v_status_russian VARCHAR(100);
BEGIN
    -- Get time type ID
    SELECT id INTO v_time_type_id
    FROM argus_time_types
    WHERE type_code = p_time_code;
    
    -- Translate status to Russian
    v_status_russian := CASE p_status
        WHEN 'Available' THEN 'Доступен'
        WHEN 'In Call' THEN 'В работе'
        WHEN 'Break' THEN 'На перерыве'
        WHEN 'Lunch' THEN 'Обед'
        WHEN 'Not Ready' THEN 'Недоступен'
        ELSE p_status
    END;
    
    -- Update or insert agent status
    INSERT INTO agent_status_realtime (
        employee_tab_n,
        employee_name,
        current_status,
        status_russian,
        time_code,
        time_type_id,
        last_updated
    )
    SELECT 
        p_employee_tab_n,
        zad.fio_full,
        p_status,
        v_status_russian,
        p_time_code,
        v_time_type_id,
        CURRENT_TIMESTAMP
    FROM zup_agent_data zad
    WHERE zad.tab_n = p_employee_tab_n
    ON CONFLICT (employee_tab_n) DO UPDATE SET
        current_status = EXCLUDED.current_status,
        status_russian = EXCLUDED.status_russian,
        time_code = EXCLUDED.time_code,
        time_type_id = EXCLUDED.time_type_id,
        last_updated = EXCLUDED.last_updated;
END;
$$ LANGUAGE plpgsql;

-- Add unique constraint for employee_tab_n if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'agent_status_realtime_employee_tab_n_key'
    ) THEN
        ALTER TABLE agent_status_realtime 
        ADD CONSTRAINT agent_status_realtime_employee_tab_n_key UNIQUE (employee_tab_n);
    END IF;
END $$;

\echo 'Time code to dashboard link fixed!'
\echo 'Now dashboard can show: И - Явка, Н - Ночные часы, etc.'