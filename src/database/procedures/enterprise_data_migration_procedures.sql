-- =====================================================================================
-- Enterprise Data Migration Procedures
-- Purpose: Comprehensive ETL and data migration procedures for WFM enterprise deployment
-- Features: Russian compliance, data validation, transformation pipelines, rollback support
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =====================================================================================
-- 1. DATA MIGRATION VALIDATION PROCEDURES
-- =====================================================================================

-- Comprehensive data validation before migration
CREATE OR REPLACE FUNCTION validate_migration_data(
    p_migration_id UUID,
    p_source_system VARCHAR,
    p_data_entities JSONB
) RETURNS JSONB AS $$
DECLARE
    v_validation_results JSONB := '{"valid": true, "errors": [], "warnings": [], "summary": {}}'::jsonb;
    v_entity JSONB;
    v_entity_type TEXT;
    v_validation_query TEXT;
    v_record_count INTEGER;
    v_error_count INTEGER;
    v_warning_count INTEGER;
BEGIN
    -- Validate each entity type
    FOR v_entity IN SELECT * FROM jsonb_array_elements(p_data_entities)
    LOOP
        v_entity_type := v_entity->>'entity_type';
        
        -- Validate employees data
        IF v_entity_type = 'employees' THEN
            -- Check for required fields
            EXECUTE format('
                SELECT COUNT(*) FROM %I.employees 
                WHERE full_name IS NULL OR personnel_number IS NULL
            ', p_source_system) INTO v_error_count;
            
            IF v_error_count > 0 THEN
                v_validation_results := jsonb_set(
                    v_validation_results,
                    '{valid}',
                    'false'::jsonb
                );
                v_validation_results := jsonb_set(
                    v_validation_results,
                    '{errors}',
                    (v_validation_results->'errors') || jsonb_build_object(
                        'entity', 'employees',
                        'error', format('Missing required fields in %s records', v_error_count),
                        'severity', 'critical'
                    )
                );
            END IF;
            
            -- Check for Russian character encoding
            EXECUTE format('
                SELECT COUNT(*) FROM %I.employees 
                WHERE full_name !~ ''^[А-Яа-яЁёA-Za-z0-9\s\-\.]+$''
            ', p_source_system) INTO v_warning_count;
            
            IF v_warning_count > 0 THEN
                v_validation_results := jsonb_set(
                    v_validation_results,
                    '{warnings}',
                    (v_validation_results->'warnings') || jsonb_build_object(
                        'entity', 'employees',
                        'warning', format('Invalid character encoding in %s employee names', v_warning_count),
                        'severity', 'medium'
                    )
                );
            END IF;
        END IF;
        
        -- Validate schedule data
        IF v_entity_type = 'schedules' THEN
            EXECUTE format('
                SELECT COUNT(*) FROM %I.schedules 
                WHERE schedule_date IS NULL OR employee_id IS NULL
            ', p_source_system) INTO v_error_count;
            
            IF v_error_count > 0 THEN
                v_validation_results := jsonb_set(
                    v_validation_results,
                    '{valid}',
                    'false'::jsonb
                );
                v_validation_results := jsonb_set(
                    v_validation_results,
                    '{errors}',
                    (v_validation_results->'errors') || jsonb_build_object(
                        'entity', 'schedules',
                        'error', format('Missing required fields in %s schedule records', v_error_count),
                        'severity', 'critical'
                    )
                );
            END IF;
        END IF;
        
        -- Get record count for summary
        EXECUTE format('SELECT COUNT(*) FROM %I.%s', p_source_system, v_entity_type) INTO v_record_count;
        v_validation_results := jsonb_set(
            v_validation_results,
            format('{summary,%s}', v_entity_type)::text[],
            to_jsonb(v_record_count)
        );
    END LOOP;
    
    -- Update migration record with validation results
    UPDATE data_migration_management 
    SET validation_rules = v_validation_results,
        updated_at = CURRENT_TIMESTAMP
    WHERE migration_id = p_migration_id;
    
    RETURN v_validation_results;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 2. DATA TRANSFORMATION PROCEDURES
-- =====================================================================================

-- Transform employee data from 1C ZUP format to WFM format
CREATE OR REPLACE FUNCTION transform_employee_data_from_1c(
    p_migration_id UUID,
    p_batch_size INTEGER DEFAULT 1000
) RETURNS JSONB AS $$
DECLARE
    v_processed_count INTEGER := 0;
    v_success_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_batch_record RECORD;
    v_transformed_data JSONB;
    v_result JSONB;
BEGIN
    -- Process employees in batches
    FOR v_batch_record IN 
        SELECT 
            external_id,
            full_name_1c,
            department_1c,
            position_1c,
            hire_date_1c,
            phone_1c,
            email_1c,
            personnel_number_1c
        FROM staging_1c_employees 
        WHERE migration_id = p_migration_id
        AND processing_status = 'pending'
        LIMIT p_batch_size
    LOOP
        BEGIN
            -- Transform data according to WFM schema
            v_transformed_data := jsonb_build_object(
                'external_id', v_batch_record.external_id,
                'full_name', TRIM(v_batch_record.full_name_1c),
                'personnel_number', v_batch_record.personnel_number_1c,
                'department', CASE 
                    WHEN v_batch_record.department_1c = 'ИТ отдел' THEN 'IT Department'
                    WHEN v_batch_record.department_1c = 'Финансы' THEN 'Finance'
                    WHEN v_batch_record.department_1c = 'Кадры' THEN 'HR'
                    ELSE v_batch_record.department_1c
                END,
                'position', v_batch_record.position_1c,
                'hire_date', v_batch_record.hire_date_1c,
                'contact_info', jsonb_build_object(
                    'phone', v_batch_record.phone_1c,
                    'email', LOWER(TRIM(v_batch_record.email_1c))
                ),
                'source_system', '1c_zup',
                'transformation_timestamp', CURRENT_TIMESTAMP
            );
            
            -- Insert transformed data
            INSERT INTO employees (
                external_id, full_name, personnel_number, department, 
                position, hire_date, contact_info, source_system,
                created_at, updated_at
            ) SELECT 
                v_transformed_data->>'external_id',
                v_transformed_data->>'full_name',
                v_transformed_data->>'personnel_number',
                v_transformed_data->>'department',
                v_transformed_data->>'position',
                (v_transformed_data->>'hire_date')::DATE,
                v_transformed_data->'contact_info',
                v_transformed_data->>'source_system',
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP
            ON CONFLICT (external_id) DO UPDATE SET
                full_name = EXCLUDED.full_name,
                department = EXCLUDED.department,
                position = EXCLUDED.position,
                contact_info = EXCLUDED.contact_info,
                updated_at = CURRENT_TIMESTAMP;
            
            -- Mark as processed successfully
            UPDATE staging_1c_employees 
            SET processing_status = 'completed',
                transformed_data = v_transformed_data,
                processed_at = CURRENT_TIMESTAMP
            WHERE external_id = v_batch_record.external_id;
            
            v_success_count := v_success_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Mark as failed and log error
            UPDATE staging_1c_employees 
            SET processing_status = 'failed',
                error_message = SQLERRM,
                processed_at = CURRENT_TIMESTAMP
            WHERE external_id = v_batch_record.external_id;
            
            v_error_count := v_error_count + 1;
        END;
        
        v_processed_count := v_processed_count + 1;
    END LOOP;
    
    -- Update migration progress
    UPDATE data_migration_management 
    SET records_processed = records_processed + v_processed_count,
        records_successful = records_successful + v_success_count,
        records_failed = records_failed + v_error_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE migration_id = p_migration_id;
    
    v_result := jsonb_build_object(
        'processed_count', v_processed_count,
        'success_count', v_success_count,
        'error_count', v_error_count,
        'batch_timestamp', CURRENT_TIMESTAMP
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. MIGRATION ROLLBACK PROCEDURES
-- =====================================================================================

-- Rollback migration with data integrity preservation
CREATE OR REPLACE FUNCTION rollback_migration(
    p_migration_id UUID,
    p_rollback_reason TEXT DEFAULT 'User requested rollback'
) RETURNS JSONB AS $$
DECLARE
    v_migration_record data_migration_management%ROWTYPE;
    v_rollback_result JSONB;
    v_entities_rollback JSONB := '[]'::jsonb;
    v_entity JSONB;
    v_rollback_count INTEGER := 0;
BEGIN
    -- Get migration details
    SELECT * INTO v_migration_record 
    FROM data_migration_management 
    WHERE migration_id = p_migration_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Migration not found'
        );
    END IF;
    
    -- Check if rollback is supported
    IF NOT v_migration_record.rollback_supported THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Rollback not supported for this migration'
        );
    END IF;
    
    -- Begin rollback transaction
    BEGIN
        -- Rollback each entity type
        FOR v_entity IN SELECT * FROM jsonb_array_elements(v_migration_record.data_entities)
        LOOP
            CASE v_entity->>'entity_type'
                WHEN 'employees' THEN
                    -- Rollback employee data
                    DELETE FROM employees 
                    WHERE source_system = v_migration_record.source_system
                    AND created_at >= v_migration_record.actual_start_time;
                    
                    GET DIAGNOSTICS v_rollback_count = ROW_COUNT;
                    
                WHEN 'schedules' THEN
                    -- Rollback schedule data
                    DELETE FROM schedules 
                    WHERE source_system = v_migration_record.source_system
                    AND created_at >= v_migration_record.actual_start_time;
                    
                    GET DIAGNOSTICS v_rollback_count = ROW_COUNT;
                    
                WHEN 'time_tracking' THEN
                    -- Rollback time tracking data
                    DELETE FROM time_tracking 
                    WHERE source_system = v_migration_record.source_system
                    AND created_at >= v_migration_record.actual_start_time;
                    
                    GET DIAGNOSTICS v_rollback_count = ROW_COUNT;
            END CASE;
            
            v_entities_rollback := v_entities_rollback || jsonb_build_object(
                'entity_type', v_entity->>'entity_type',
                'records_rolled_back', v_rollback_count
            );
        END LOOP;
        
        -- Update migration status
        UPDATE data_migration_management 
        SET migration_status = 'rolled_back',
            actual_completion_time = CURRENT_TIMESTAMP,
            error_summary = jsonb_build_object(
                'rollback_reason', p_rollback_reason,
                'rollback_timestamp', CURRENT_TIMESTAMP,
                'entities_rollback', v_entities_rollback
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE migration_id = p_migration_id;
        
        v_rollback_result := jsonb_build_object(
            'success', true,
            'migration_id', p_migration_id,
            'rollback_reason', p_rollback_reason,
            'entities_rollback', v_entities_rollback,
            'rollback_timestamp', CURRENT_TIMESTAMP
        );
        
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        
        v_rollback_result := jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'migration_id', p_migration_id
        );
    END;
    
    RETURN v_rollback_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. MIGRATION MONITORING AND PROGRESS TRACKING
-- =====================================================================================

-- Get comprehensive migration status and progress
CREATE OR REPLACE FUNCTION get_migration_status(p_migration_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_migration_record data_migration_management%ROWTYPE;
    v_progress_details JSONB;
    v_entity_progress JSONB := '[]'::jsonb;
    v_entity JSONB;
    v_entity_stats RECORD;
BEGIN
    -- Get migration record
    SELECT * INTO v_migration_record 
    FROM data_migration_management 
    WHERE migration_id = p_migration_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Migration not found');
    END IF;
    
    -- Get progress for each entity type
    FOR v_entity IN SELECT * FROM jsonb_array_elements(v_migration_record.data_entities)
    LOOP
        -- Get entity-specific progress from staging tables
        EXECUTE format('
            SELECT 
                COUNT(*) as total_records,
                COUNT(*) FILTER (WHERE processing_status = ''completed'') as completed_records,
                COUNT(*) FILTER (WHERE processing_status = ''failed'') as failed_records,
                COUNT(*) FILTER (WHERE processing_status = ''pending'') as pending_records
            FROM staging_1c_%s 
            WHERE migration_id = $1
        ', v_entity->>'entity_type') 
        INTO v_entity_stats 
        USING p_migration_id;
        
        v_entity_progress := v_entity_progress || jsonb_build_object(
            'entity_type', v_entity->>'entity_type',
            'total_records', v_entity_stats.total_records,
            'completed_records', v_entity_stats.completed_records,
            'failed_records', v_entity_stats.failed_records,
            'pending_records', v_entity_stats.pending_records,
            'completion_percentage', CASE 
                WHEN v_entity_stats.total_records > 0 
                THEN ROUND((v_entity_stats.completed_records::DECIMAL / v_entity_stats.total_records) * 100, 2)
                ELSE 0 
            END
        );
    END LOOP;
    
    -- Calculate overall progress and timing
    v_progress_details := jsonb_build_object(
        'migration_id', v_migration_record.migration_id,
        'migration_name', v_migration_record.migration_name,
        'migration_status', v_migration_record.migration_status,
        'progress_percentage', v_migration_record.progress_percentage,
        'timing', jsonb_build_object(
            'scheduled_start', v_migration_record.scheduled_start_time,
            'actual_start', v_migration_record.actual_start_time,
            'estimated_completion', v_migration_record.estimated_completion_time,
            'actual_completion', v_migration_record.actual_completion_time,
            'duration_minutes', CASE 
                WHEN v_migration_record.actual_completion_time IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (v_migration_record.actual_completion_time - v_migration_record.actual_start_time)) / 60
                WHEN v_migration_record.actual_start_time IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_migration_record.actual_start_time)) / 60
                ELSE NULL 
            END
        ),
        'records', jsonb_build_object(
            'total_to_migrate', v_migration_record.total_records_to_migrate,
            'processed', v_migration_record.records_processed,
            'successful', v_migration_record.records_successful,
            'failed', v_migration_record.records_failed,
            'skipped', v_migration_record.records_skipped
        ),
        'quality_metrics', jsonb_build_object(
            'data_quality_score', v_migration_record.data_quality_score,
            'validation_success_rate', v_migration_record.validation_success_rate,
            'transformation_success_rate', v_migration_record.transformation_success_rate
        ),
        'entity_progress', v_entity_progress,
        'errors', jsonb_build_object(
            'critical_errors', v_migration_record.critical_errors_count,
            'warnings', v_migration_record.warning_count,
            'info', v_migration_record.info_count,
            'error_summary', v_migration_record.error_summary
        ),
        'compliance', jsonb_build_object(
            'personal_data_included', v_migration_record.personal_data_included,
            'consent_verification_required', v_migration_record.consent_verification_required,
            'retention_period_years', v_migration_record.retention_period_years,
            'compliance_validation_passed', v_migration_record.compliance_validation_passed
        )
    );
    
    RETURN v_progress_details;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. AUTOMATED MIGRATION SCHEDULING
-- =====================================================================================

-- Schedule recurring migrations
CREATE OR REPLACE FUNCTION schedule_recurring_migration(
    p_migration_template_id UUID,
    p_schedule_expression VARCHAR, -- Cron expression
    p_enabled BOOLEAN DEFAULT true
) RETURNS UUID AS $$
DECLARE
    v_schedule_id UUID;
    v_next_run TIMESTAMP WITH TIME ZONE;
BEGIN
    v_schedule_id := uuid_generate_v4();
    
    -- Calculate next run time based on cron expression
    -- This is a simplified version - in production, use a proper cron parser
    v_next_run := CURRENT_TIMESTAMP + INTERVAL '1 day';
    
    INSERT INTO migration_schedules (
        schedule_id,
        migration_template_id,
        schedule_expression,
        next_run_time,
        is_enabled,
        created_at
    ) VALUES (
        v_schedule_id,
        p_migration_template_id,
        p_schedule_expression,
        v_next_run,
        p_enabled,
        CURRENT_TIMESTAMP
    );
    
    RETURN v_schedule_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. DATA LINEAGE AND AUDIT TRAIL
-- =====================================================================================

-- Track data lineage for compliance and audit
CREATE OR REPLACE FUNCTION record_data_lineage(
    p_migration_id UUID,
    p_source_record_id VARCHAR,
    p_target_record_id UUID,
    p_entity_type VARCHAR,
    p_transformation_details JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO data_lineage_audit (
        lineage_id,
        migration_id,
        source_record_id,
        target_record_id,
        entity_type,
        transformation_applied,
        transformation_timestamp,
        data_quality_score,
        compliance_flags,
        created_at
    ) VALUES (
        uuid_generate_v4(),
        p_migration_id,
        p_source_record_id,
        p_target_record_id,
        p_entity_type,
        p_transformation_details,
        CURRENT_TIMESTAMP,
        (p_transformation_details->>'quality_score')::DECIMAL,
        CASE 
            WHEN p_entity_type IN ('employees', 'personal_data') 
            THEN '["personal_data", "russian_compliance"]'::jsonb
            ELSE '["standard"]'::jsonb
        END,
        CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================================================

-- Migration management indexes
CREATE INDEX IF NOT EXISTS idx_migration_status ON data_migration_management(migration_status);
CREATE INDEX IF NOT EXISTS idx_migration_source_system ON data_migration_management(source_system);
CREATE INDEX IF NOT EXISTS idx_migration_scheduled_start ON data_migration_management(scheduled_start_time);

-- Data lineage indexes
CREATE INDEX IF NOT EXISTS idx_lineage_migration_id ON data_lineage_audit(migration_id);
CREATE INDEX IF NOT EXISTS idx_lineage_entity_type ON data_lineage_audit(entity_type);
CREATE INDEX IF NOT EXISTS idx_lineage_timestamp ON data_lineage_audit(transformation_timestamp);

-- =====================================================================================
-- PERMISSIONS AND SECURITY
-- =====================================================================================

-- Grant necessary permissions for migration operations
GRANT SELECT, INSERT, UPDATE ON data_migration_management TO wfm_migration_admin;
GRANT SELECT ON data_migration_management TO wfm_migration_monitor;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_migration_admin;

-- Create specialized migration user with limited permissions
-- CREATE USER wfm_migration_service WITH PASSWORD 'secure_migration_password';
-- GRANT SELECT, INSERT, UPDATE ON staging_1c_employees TO wfm_migration_service;
-- GRANT SELECT, INSERT, UPDATE ON staging_1c_schedules TO wfm_migration_service;
-- GRANT EXECUTE ON FUNCTION transform_employee_data_from_1c(UUID, INTEGER) TO wfm_migration_service;

-- =====================================================================================
-- MONITORING AND ALERTING SETUP
-- =====================================================================================

-- Create trigger for migration progress alerts
CREATE OR REPLACE FUNCTION migration_progress_alert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Alert if migration fails
    IF NEW.migration_status = 'failed' AND OLD.migration_status != 'failed' THEN
        INSERT INTO system_alerts (
            alert_type,
            alert_severity,
            alert_message,
            alert_details,
            created_at
        ) VALUES (
            'migration_failed',
            'critical',
            format('Migration %s has failed', NEW.migration_name),
            jsonb_build_object(
                'migration_id', NEW.migration_id,
                'error_count', NEW.critical_errors_count,
                'records_processed', NEW.records_processed
            ),
            CURRENT_TIMESTAMP
        );
    END IF;
    
    -- Alert if migration takes too long
    IF NEW.migration_status = 'running' 
       AND NEW.actual_start_time IS NOT NULL 
       AND EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - NEW.actual_start_time)) > 7200 -- 2 hours
    THEN
        INSERT INTO system_alerts (
            alert_type,
            alert_severity,
            alert_message,
            alert_details,
            created_at
        ) VALUES (
            'migration_long_running',
            'warning',
            format('Migration %s has been running for over 2 hours', NEW.migration_name),
            jsonb_build_object(
                'migration_id', NEW.migration_id,
                'runtime_minutes', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - NEW.actual_start_time)) / 60
            ),
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER migration_progress_alert_trigger
    AFTER UPDATE ON data_migration_management
    FOR EACH ROW
    EXECUTE FUNCTION migration_progress_alert_trigger();