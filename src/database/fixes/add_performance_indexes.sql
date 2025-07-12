-- =============================================================================
-- add_performance_indexes.sql
-- GREEN PHASE: Add critical indexes for <10ms query performance
-- =============================================================================
-- Purpose: Ensure dashboard and optimization queries run fast for demo
-- Target: All queries under 10ms for real-time feel
-- =============================================================================

\echo 'Adding performance indexes for demo...'

-- =============================================================================
-- 1. Real-time dashboard indexes
-- =============================================================================

-- Agent status lookup (most frequent query)
CREATE INDEX IF NOT EXISTS idx_agent_status_realtime_employee 
ON agent_status_realtime(employee_tab_n);

CREATE INDEX IF NOT EXISTS idx_agent_status_realtime_updated 
ON agent_status_realtime(last_updated DESC);

-- Time entries by date
CREATE INDEX IF NOT EXISTS idx_argus_time_entries_date 
ON argus_time_entries(entry_date, employee_tab_n);

-- =============================================================================
-- 2. Forecasting performance indexes
-- =============================================================================

-- Historical data queries
CREATE INDEX IF NOT EXISTS idx_historical_data_datetime 
ON historical_data(data_datetime);

CREATE INDEX IF NOT EXISTS idx_historical_data_project_date 
ON historical_data(project_id, data_datetime);

-- Forecast lookups
CREATE INDEX IF NOT EXISTS idx_call_volume_forecasts_datetime 
ON call_volume_forecasts(forecast_datetime);

CREATE INDEX IF NOT EXISTS idx_operator_forecasts_interval 
ON operator_forecasts(interval_datetime);

-- =============================================================================
-- 3. Optimization query indexes
-- =============================================================================

-- Coverage analysis time-based queries
CREATE INDEX IF NOT EXISTS idx_coverage_analysis_realtime_time 
ON coverage_analysis_realtime(analysis_time DESC);

-- Schedule suggestions by project
CREATE INDEX IF NOT EXISTS idx_schedule_suggestions_project 
ON schedule_suggestions(optimization_project_id, efficiency_score DESC);

-- =============================================================================
-- 4. Service monitoring indexes
-- =============================================================================

-- Service level time-based queries
CREATE INDEX IF NOT EXISTS idx_service_level_monitoring_time 
ON service_level_monitoring(calculation_time DESC);

-- KPI dashboard lookups
CREATE INDEX IF NOT EXISTS idx_executive_kpi_name 
ON executive_kpi_dashboard(kpi_name, last_calculated DESC);

-- =============================================================================
-- 5. Multi-column indexes for complex joins
-- =============================================================================

-- Employee lookups with status
CREATE INDEX IF NOT EXISTS idx_zup_agent_composite 
ON zup_agent_data(tab_n, finish_work) 
WHERE finish_work IS NULL;

-- Time type lookups
CREATE INDEX IF NOT EXISTS idx_argus_time_types_code 
ON argus_time_types(type_code);

-- =============================================================================
-- 6. Partial indexes for common filters
-- =============================================================================

-- Active employees only
CREATE INDEX IF NOT EXISTS idx_agent_status_active 
ON agent_status_realtime(employee_tab_n, last_updated DESC) 
WHERE current_status IN ('Available', 'In Call');

-- Current day forecasts
CREATE INDEX IF NOT EXISTS idx_forecasts_today 
ON call_volume_forecasts(forecast_datetime) 
WHERE forecast_datetime::date = CURRENT_DATE;

-- =============================================================================
-- Analyze tables for query planner
-- =============================================================================
ANALYZE zup_agent_data;
ANALYZE agent_status_realtime;
ANALYZE argus_time_entries;
ANALYZE argus_time_types;
ANALYZE service_level_monitoring;
ANALYZE coverage_analysis_realtime;
ANALYZE executive_kpi_dashboard;
ANALYZE historical_data;
ANALYZE call_volume_forecasts;
ANALYZE operator_forecasts;
ANALYZE optimization_projects;
ANALYZE schedule_suggestions;

\echo 'Performance indexes added!'
\echo 'Dashboard queries should now run in <10ms'