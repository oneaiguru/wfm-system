-- =============================================================================
-- fix_forecast_optimization_link.sql
-- GREEN PHASE: Fix missing link between Forecasting and Optimization
-- =============================================================================
-- Purpose: Connect forecasting_projects data to optimization_projects
-- This enables AI-driven scheduling to use forecast data
-- =============================================================================

-- Add forecasting project reference to optimization projects
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'optimization_projects' 
        AND column_name = 'forecasting_project_id'
    ) THEN
        ALTER TABLE optimization_projects 
        ADD COLUMN forecasting_project_id UUID,
        ADD CONSTRAINT fk_optimization_forecasting 
            FOREIGN KEY (forecasting_project_id) REFERENCES forecasting_projects(id);
    END IF;
END $$;

-- Update coverage_analysis to pull from operator_forecasts
CREATE OR REPLACE FUNCTION sync_coverage_with_forecasts(
    p_optimization_project_id UUID
) RETURNS void AS $$
DECLARE
    v_forecasting_project_id UUID;
    v_optimization_date DATE;
BEGIN
    -- Get linked forecasting project
    SELECT forecasting_project_id, optimization_date
    INTO v_forecasting_project_id, v_optimization_date
    FROM optimization_projects
    WHERE id = p_optimization_project_id;
    
    IF v_forecasting_project_id IS NULL THEN
        RAISE EXCEPTION 'Optimization project % not linked to forecasting', p_optimization_project_id;
    END IF;
    
    -- Clear old coverage analysis
    DELETE FROM coverage_analysis 
    WHERE optimization_project_id = p_optimization_project_id;
    
    -- Insert coverage analysis from forecast data
    INSERT INTO coverage_analysis (
        optimization_project_id,
        time_interval,
        required_agents,
        scheduled_agents,
        coverage_percentage
    )
    SELECT 
        p_optimization_project_id,
        of.interval_datetime,
        of.operator_requirement as required_agents,
        COALESCE(
            (SELECT COUNT(DISTINCT ss.employee_tab_n)
             FROM schedule_suggestions ss
             WHERE ss.optimization_project_id = p_optimization_project_id),
            0
        ) as scheduled_agents,
        CASE 
            WHEN of.operator_requirement > 0 THEN
                LEAST(100, (COALESCE(
                    (SELECT COUNT(DISTINCT ss.employee_tab_n)
                     FROM schedule_suggestions ss
                     WHERE ss.optimization_project_id = p_optimization_project_id),
                    0
                )::DECIMAL / of.operator_requirement) * 100)
            ELSE 100
        END as coverage_percentage
    FROM operator_forecasts of
    WHERE of.project_id = v_forecasting_project_id
    AND of.interval_datetime::date = v_optimization_date;
    
END;
$$ LANGUAGE plpgsql;

-- Create function to initialize optimization from forecast
CREATE OR REPLACE FUNCTION create_optimization_from_forecast(
    p_forecasting_project_id UUID,
    p_optimization_date DATE,
    p_algorithm_version VARCHAR(50) DEFAULT 'AI_GENETIC_V2'
) RETURNS UUID AS $$
DECLARE
    v_optimization_id UUID;
    v_project_name VARCHAR(200);
    v_agents_count INTEGER;
BEGIN
    -- Get forecast project details
    SELECT project_name INTO v_project_name
    FROM forecasting_projects
    WHERE id = p_forecasting_project_id;
    
    -- Count available agents
    SELECT COUNT(*) INTO v_agents_count
    FROM zup_agent_data
    WHERE finish_work IS NULL;
    
    -- Create optimization project
    INSERT INTO optimization_projects (
        project_name,
        project_status,
        optimization_date,
        agents_count,
        algorithm_version,
        forecasting_project_id
    ) VALUES (
        v_project_name || ' - Optimization',
        'ACTIVE',
        p_optimization_date,
        v_agents_count,
        p_algorithm_version,
        p_forecasting_project_id
    ) RETURNING id INTO v_optimization_id;
    
    -- Sync coverage analysis with forecasts
    PERFORM sync_coverage_with_forecasts(v_optimization_id);
    
    RETURN v_optimization_id;
END;
$$ LANGUAGE plpgsql;

-- Create view to show forecast-optimization link
CREATE OR REPLACE VIEW v_forecast_optimization_pipeline AS
SELECT 
    fp.project_name as forecast_project,
    fp.project_status as forecast_status,
    op.project_name as optimization_project,
    op.project_status as optimization_status,
    op.algorithm_version,
    op.agents_count,
    COUNT(DISTINCT ca.id) as coverage_intervals,
    AVG(ca.coverage_percentage) as avg_coverage,
    MAX(of.operator_requirement) as peak_requirement
FROM forecasting_projects fp
LEFT JOIN optimization_projects op ON op.forecasting_project_id = fp.id
LEFT JOIN coverage_analysis ca ON ca.optimization_project_id = op.id
LEFT JOIN operator_forecasts of ON of.project_id = fp.id
GROUP BY fp.id, op.id;

\echo 'Forecasting to optimization link fixed!'
\echo 'Now optimization can use forecast data for AI scheduling!'