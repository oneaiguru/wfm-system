-- API Helper Queries for Mass Assignment Operations (BDD 32)
-- REST API integration support with JSON responses
-- Performance-optimized queries for web interface

-- Helper function: Get mass assignment job details
CREATE OR REPLACE FUNCTION get_mass_assignment_job_details(p_job_id UUID)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT row_to_json(job_details)
        FROM (
            SELECT 
                j.job_id,
                j.job_name,
                j.assignment_type,
                j.created_by,
                j.created_at,
                j.started_at,
                j.completed_at,
                j.status,
                j.total_employees,
                j.processed_employees,
                j.successful_assignments,
                j.failed_assignments,
                j.filter_criteria,
                j.assignment_parameters,
                -- Include preview summary
                (
                    SELECT json_build_object(
                        'total_in_preview', COUNT(*),
                        'will_apply', COUNT(*) FILTER (WHERE assignment_preview_status = 'will_apply'),
                        'will_override', COUNT(*) FILTER (WHERE assignment_preview_status = 'will_override'),
                        'conflicts', COUNT(*) FILTER (WHERE assignment_preview_status = 'conflict')
                    )
                    FROM mass_assignment_employee_preview p
                    WHERE p.job_id = j.job_id
                ) as preview_summary,
                -- Include audit trail
                (
                    SELECT json_agg(
                        json_build_object(
                            'event_type', a.event_type,
                            'event_timestamp', a.event_timestamp,
                            'event_details', a.event_details,
                            'performed_by', a.performed_by
                        )
                        ORDER BY a.event_timestamp DESC
                    )
                    FROM mass_assignment_audit a
                    WHERE a.job_id = j.job_id
                ) as audit_trail
            FROM mass_assignment_jobs j
            WHERE j.job_id = p_job_id
        ) job_details
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Get filtered employee list for UI
CREATE OR REPLACE FUNCTION get_filtered_employees_for_assignment(
    p_filter_criteria JSONB,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Generate mock filtered employee data based on criteria
    -- In production, this would query real employee tables
    SELECT json_build_object(
        'total_count', 125, -- Mock total
        'page_size', p_limit,
        'page_offset', p_offset,
        'employees', json_agg(
            json_build_object(
                'employee_id', employee_id,
                'personnel_number', personnel_number,
                'employee_name', employee_name,
                'department', department_name,
                'employee_type', employee_type,
                'status', status,
                'current_assignment', current_assignment,
                'eligibility_status', 
                    CASE 
                        WHEN random() < 0.9 THEN 'eligible'
                        WHEN random() < 0.95 THEN 'requires_override'
                        ELSE 'not_eligible'
                    END
            )
            ORDER BY employee_name
        )
    ) INTO result
    FROM (
        SELECT 
            uuid_generate_v4() as employee_id,
            '1000' || generate_series(p_offset + 1, p_offset + p_limit) as personnel_number,
            'Employee ' || generate_series(p_offset + 1, p_offset + p_limit) as employee_name,
            CASE 
                WHEN (p_filter_criteria->>'department') IS NOT NULL 
                THEN (p_filter_criteria->'department'->>0)
                ELSE 'Customer Service'
            END as department_name,
            CASE 
                WHEN (p_filter_criteria->>'employee_type') IS NOT NULL 
                THEN (p_filter_criteria->'employee_type'->>0)
                ELSE 'Office'
            END as employee_type,
            'Active' as status,
            CASE 
                WHEN random() < 0.3 THEN 'Current Rule Applied'::text
                ELSE NULL
            END as current_assignment
    ) employees;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Helper function: Get assignment templates for UI dropdown
CREATE OR REPLACE FUNCTION get_assignment_templates(p_assignment_type VARCHAR(50) DEFAULT NULL)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_agg(
            json_build_object(
                'template_id', template_id,
                'template_name', template_name,
                'template_name_ru', template_name_ru,
                'assignment_type', assignment_type,
                'description', template_description,
                'filter_configuration', filter_configuration,
                'assignment_configuration', assignment_configuration,
                'usage_count', usage_count,
                'last_used_at', last_used_at
            )
            ORDER BY template_name
        )
        FROM mass_assignment_templates
        WHERE is_active = true
        AND (p_assignment_type IS NULL OR assignment_type = p_assignment_type)
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Get available filters for UI
CREATE OR REPLACE FUNCTION get_available_filters()
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_agg(
            json_build_object(
                'filter_id', filter_id,
                'filter_name', filter_name,
                'filter_type', filter_type,
                'display_name', display_name,
                'display_name_ru', display_name_ru,
                'parameter_type', parameter_type,
                'available_values', available_values,
                'display_order', display_order
            )
            ORDER BY display_order
        )
        FROM employee_filter_definitions
        WHERE is_active = true
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Create mass assignment job with validation
CREATE OR REPLACE FUNCTION create_mass_assignment_job(
    p_job_name VARCHAR(255),
    p_assignment_type VARCHAR(50),
    p_created_by VARCHAR(255),
    p_filter_criteria JSONB,
    p_assignment_parameters JSONB
)
RETURNS JSON AS $$
DECLARE
    new_job_id UUID;
    validation_result RECORD;
    result JSON;
BEGIN
    -- Validate assignment type
    IF p_assignment_type NOT IN ('business_rules', 'vacation_schemes', 'work_hours') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid assignment type',
            'error_code', 'INVALID_ASSIGNMENT_TYPE'
        );
    END IF;
    
    -- Create the job
    INSERT INTO mass_assignment_jobs (
        job_name, assignment_type, created_by, filter_criteria, assignment_parameters
    ) VALUES (
        p_job_name, p_assignment_type, p_created_by, p_filter_criteria, p_assignment_parameters
    ) RETURNING job_id INTO new_job_id;
    
    -- Generate initial employee preview
    SELECT * INTO validation_result 
    FROM generate_employee_preview(new_job_id, p_filter_criteria);
    
    -- Log job creation in audit
    INSERT INTO mass_assignment_audit (job_id, event_type, event_details, performed_by)
    VALUES (
        new_job_id, 
        'job_created',
        json_build_object(
            'job_name', p_job_name,
            'assignment_type', p_assignment_type,
            'employees_found', validation_result.employee_count
        ),
        p_created_by
    );
    
    -- Return success result
    RETURN json_build_object(
        'success', true,
        'job_id', new_job_id,
        'employees_found', validation_result.employee_count,
        'preview_generated', validation_result.preview_generated
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', 'CREATION_FAILED'
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Execute assignment with detailed results
CREATE OR REPLACE FUNCTION execute_mass_assignment_with_details(p_job_id UUID)
RETURNS JSON AS $$
DECLARE
    execution_result RECORD;
    job_details RECORD;
    result JSON;
BEGIN
    -- Get job details first
    SELECT * INTO job_details FROM mass_assignment_jobs WHERE job_id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Job not found',
            'error_code', 'JOB_NOT_FOUND'
        );
    END IF;
    
    -- Check if job is in valid state for execution
    IF job_details.status NOT IN ('created', 'ready') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Job is not in valid state for execution',
            'error_code', 'INVALID_JOB_STATE',
            'current_status', job_details.status
        );
    END IF;
    
    -- Execute the assignment
    SELECT * INTO execution_result FROM execute_mass_assignment(p_job_id);
    
    -- Return detailed results
    RETURN json_build_object(
        'success', true,
        'job_id', p_job_id,
        'execution_summary', json_build_object(
            'total_processed', execution_result.total_processed,
            'successful_assignments', execution_result.success_count,
            'failed_assignments', execution_result.failure_count,
            'success_rate', 
                CASE 
                    WHEN execution_result.total_processed > 0 
                    THEN ROUND((execution_result.success_count::DECIMAL / execution_result.total_processed) * 100, 2)
                    ELSE 0 
                END
        ),
        'assignment_type', job_details.assignment_type,
        'completed_at', CURRENT_TIMESTAMP
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Update job status to failed
    UPDATE mass_assignment_jobs 
    SET status = 'failed', error_log = SQLERRM
    WHERE job_id = p_job_id;
    
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', 'EXECUTION_FAILED'
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Get assignment history for reporting
CREATE OR REPLACE FUNCTION get_assignment_history(
    p_assignment_type VARCHAR(50) DEFAULT NULL,
    p_created_by VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'total_jobs', COUNT(*),
            'jobs', json_agg(
                json_build_object(
                    'job_id', job_id,
                    'job_name', job_name,
                    'assignment_type', assignment_type,
                    'created_by', created_by,
                    'created_at', created_at,
                    'status', status,
                    'total_employees', total_employees,
                    'successful_assignments', successful_assignments,
                    'failed_assignments', failed_assignments,
                    'completion_rate', 
                        CASE 
                            WHEN processed_employees > 0 
                            THEN ROUND((successful_assignments::DECIMAL / processed_employees) * 100, 2)
                            ELSE 0 
                        END
                )
                ORDER BY created_at DESC
            )
        )
        FROM (
            SELECT *
            FROM mass_assignment_jobs
            WHERE (p_assignment_type IS NULL OR assignment_type = p_assignment_type)
            AND (p_created_by IS NULL OR created_by = p_created_by)
            ORDER BY created_at DESC
            LIMIT p_limit
        ) recent_jobs
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function: Get assignment statistics dashboard
CREATE OR REPLACE FUNCTION get_assignment_statistics()
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'overview', json_build_object(
                'total_jobs', (SELECT COUNT(*) FROM mass_assignment_jobs),
                'active_jobs', (SELECT COUNT(*) FROM mass_assignment_jobs WHERE status IN ('created', 'in_progress')),
                'completed_jobs', (SELECT COUNT(*) FROM mass_assignment_jobs WHERE status = 'completed'),
                'failed_jobs', (SELECT COUNT(*) FROM mass_assignment_jobs WHERE status = 'failed')
            ),
            'by_assignment_type', (
                SELECT json_agg(
                    json_build_object(
                        'assignment_type', assignment_type,
                        'total_jobs', COUNT(*),
                        'total_employees_processed', COALESCE(SUM(processed_employees), 0),
                        'total_successful', COALESCE(SUM(successful_assignments), 0),
                        'average_success_rate', 
                            CASE 
                                WHEN SUM(processed_employees) > 0 
                                THEN ROUND((SUM(successful_assignments)::DECIMAL / SUM(processed_employees)) * 100, 2)
                                ELSE 0 
                            END
                    )
                )
                FROM mass_assignment_jobs
                GROUP BY assignment_type
            ),
            'recent_activity', (
                SELECT json_agg(
                    json_build_object(
                        'date', DATE(created_at),
                        'jobs_created', COUNT(*),
                        'employees_processed', COALESCE(SUM(processed_employees), 0)
                    )
                    ORDER BY DATE(created_at) DESC
                )
                FROM mass_assignment_jobs
                WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(created_at)
                LIMIT 30
            ),
            'template_usage', (
                SELECT json_agg(
                    json_build_object(
                        'template_name', template_name,
                        'usage_count', usage_count,
                        'last_used_at', last_used_at
                    )
                    ORDER BY usage_count DESC
                )
                FROM mass_assignment_templates
                WHERE is_active = true
            )
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Example API endpoint queries for REST implementation

-- GET /api/mass-assignment/jobs/:jobId
-- SELECT get_mass_assignment_job_details('{{job_id}}');

-- GET /api/mass-assignment/employees/filtered
-- SELECT get_filtered_employees_for_assignment('{{filter_criteria}}', {{limit}}, {{offset}});

-- GET /api/mass-assignment/templates?type={{assignment_type}}
-- SELECT get_assignment_templates('{{assignment_type}}');

-- GET /api/mass-assignment/filters
-- SELECT get_available_filters();

-- POST /api/mass-assignment/jobs
-- SELECT create_mass_assignment_job('{{job_name}}', '{{assignment_type}}', '{{created_by}}', '{{filter_criteria}}', '{{assignment_parameters}}');

-- POST /api/mass-assignment/jobs/:jobId/execute
-- SELECT execute_mass_assignment_with_details('{{job_id}}');

-- GET /api/mass-assignment/history?type={{assignment_type}}&created_by={{created_by}}&limit={{limit}}
-- SELECT get_assignment_history('{{assignment_type}}', '{{created_by}}', {{limit}});

-- GET /api/mass-assignment/statistics
-- SELECT get_assignment_statistics();

-- Performance indexes for API queries
CREATE INDEX IF NOT EXISTS idx_mass_jobs_status_created ON mass_assignment_jobs(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mass_jobs_type_created ON mass_assignment_jobs(assignment_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mass_jobs_created_by ON mass_assignment_jobs(created_by, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mass_audit_job_timestamp ON mass_assignment_audit(job_id, event_timestamp DESC);

-- Test the API helper functions
SELECT 'Testing API Helper Functions...' as test_section;

-- Test template retrieval
SELECT 'Available Assignment Templates:' as test_step;
SELECT get_assignment_templates();

-- Test filter retrieval  
SELECT 'Available Filters:' as test_step;
SELECT get_available_filters();

-- Test job creation
SELECT 'Creating Test Job:' as test_step;
SELECT create_mass_assignment_job(
    'API Test Job',
    'business_rules',
    'api_test@company.com',
    '{"department": ["Customer Service"]}'::jsonb,
    '{"rule_name": "API Test Rule"}'::jsonb
);

-- Test statistics
SELECT 'Assignment Statistics:' as test_step;
SELECT get_assignment_statistics();

-- Test assignment history
SELECT 'Assignment History:' as test_step;
SELECT get_assignment_history(NULL, NULL, 5);

SELECT 'API Helper Functions Testing Complete!' as completion_message;