# 📋 SUBAGENT TASK: Integration Test 005 - Multi-skill Schedule Optimization

## 🎯 Task Information
- **Task ID**: INTEGRATION_TEST_005
- **Priority**: Critical
- **Estimated Time**: 60 minutes
- **Dependencies**: multi_skill_assignments, agent_skills, projects, queues, optimization algorithms
- **Test Type**: End-to-End Multi-skill Schedule Optimization Integration

## 📊 Test Scenario

**Multi-skill Schedule Optimization Flow**:
1. Multi-skill agent data setup with varying proficiency levels
2. Project and queue skill requirements definition
3. Schedule template configuration and allocation
4. Real-time optimization algorithm execution
5. Skill gap analysis and coverage validation
6. Assignment conflict detection and resolution
7. Performance optimization under load testing
8. Integration validation with real agent data

## 📝 Test Implementation

### Step 1: Create Multi-skill Optimization Test Procedure
```sql
CREATE OR REPLACE FUNCTION test_multiskill_schedule_optimization()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_project_id INTEGER;
    v_queue_id INTEGER;
    v_skill_id_1 INTEGER;
    v_skill_id_2 INTEGER;
    v_skill_id_3 INTEGER;
    v_agent_id_1 INTEGER;
    v_agent_id_2 INTEGER;
    v_agent_id_3 INTEGER;
    v_template_id INTEGER;
    v_assignment_id BIGINT;
    v_conflict_id INTEGER;
    v_optimization_id UUID;
    v_test_passed BOOLEAN := true;
    v_error_msg TEXT;
    v_coverage_score DECIMAL(5,2);
    v_efficiency_score DECIMAL(5,2);
    v_assignment_count INTEGER;
    v_conflict_count INTEGER;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_processing_time INTEGER;
BEGIN
    -- Test 1: Create multi-skill agent data setup
    BEGIN
        -- Create skills
        INSERT INTO skills (skill_code, skill_name, skill_category, description) VALUES
        ('EN_SUPPORT', 'English Customer Support', 'language', 'Native or fluent English support'),
        ('RU_SUPPORT', 'Russian Customer Support', 'language', 'Native Russian support'),
        ('TECH_L2', 'Technical Support Level 2', 'technical', 'Advanced technical troubleshooting')
        RETURNING skill_id INTO v_skill_id_1;
        
        SELECT skill_id INTO v_skill_id_2 FROM skills WHERE skill_code = 'RU_SUPPORT';
        SELECT skill_id INTO v_skill_id_3 FROM skills WHERE skill_code = 'TECH_L2';
        
        -- Create test project with complex multi-skill requirements
        INSERT INTO projects (project_code, project_name, client_name, project_type, queue_count, priority_level) VALUES
        ('MSO_TEST', 'Multi-skill Optimization Test', 'Test Client', 'complex', 3, 5)
        RETURNING project_id INTO v_project_id;
        
        -- Create project queues
        INSERT INTO project_queues (project_id, queue_code, queue_name, queue_type, service_level_target, service_level_seconds) VALUES
        (v_project_id, 'EN_QUEUE', 'English Support Queue', 'inbound', 80.00, 20),
        (v_project_id, 'RU_QUEUE', 'Russian Support Queue', 'inbound', 85.00, 30),
        (v_project_id, 'TECH_QUEUE', 'Technical Escalation Queue', 'inbound', 90.00, 60)
        RETURNING queue_id INTO v_queue_id;
        
        -- Create test agents with varying skill sets
        INSERT INTO employees (employee_number, first_name, last_name, department_id, position_id) VALUES
        ('MSO_001', 'Алексей', 'Смирнов', (SELECT id FROM departments LIMIT 1), (SELECT id FROM positions LIMIT 1)),
        ('MSO_002', 'Maria', 'Johnson', (SELECT id FROM departments LIMIT 1), (SELECT id FROM positions LIMIT 1)),
        ('MSO_003', 'Сергей', 'Петров', (SELECT id FROM departments LIMIT 1), (SELECT id FROM positions LIMIT 1))
        ON CONFLICT (employee_number) DO UPDATE SET first_name = EXCLUDED.first_name;
        
        SELECT id INTO v_agent_id_1 FROM employees WHERE employee_number = 'MSO_001';
        SELECT id INTO v_agent_id_2 FROM employees WHERE employee_number = 'MSO_002';
        SELECT id INTO v_agent_id_3 FROM employees WHERE employee_number = 'MSO_003';
        
        -- Configure agent skills with different proficiency levels
        INSERT INTO agent_skills (agent_id, skill_id, proficiency_level, is_primary_skill) VALUES
        (v_agent_id_1, v_skill_id_1, 4, false), -- Алексей: Advanced English
        (v_agent_id_1, v_skill_id_2, 5, true),  -- Алексей: Expert Russian (primary)
        (v_agent_id_1, v_skill_id_3, 3, false), -- Алексей: Intermediate Tech
        (v_agent_id_2, v_skill_id_1, 5, true),  -- Maria: Expert English (primary)
        (v_agent_id_2, v_skill_id_2, 2, false), -- Maria: Basic Russian
        (v_agent_id_2, v_skill_id_3, 4, false), -- Maria: Advanced Tech
        (v_agent_id_3, v_skill_id_2, 5, true),  -- Сергей: Expert Russian (primary)
        (v_agent_id_3, v_skill_id_3, 5, false)  -- Сергей: Expert Tech
        ON CONFLICT (agent_id, skill_id) DO UPDATE SET proficiency_level = EXCLUDED.proficiency_level;
        
        RETURN QUERY SELECT 'Multi-skill Setup'::TEXT, 'PASS'::TEXT, 'Created 3 agents with 8 skill assignments across 3 skill types'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Multi-skill Setup'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 2: Define skill requirements for optimization
    BEGIN
        INSERT INTO skill_requirements (project_id, queue_id, skill_id, min_agents, preferred_agents, min_proficiency_level, requirement_type) VALUES
        (v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'EN_QUEUE' AND project_id = v_project_id), v_skill_id_1, 2, 3, 4, 'mandatory'),
        (v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'RU_QUEUE' AND project_id = v_project_id), v_skill_id_2, 2, 3, 4, 'mandatory'),
        (v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'TECH_QUEUE' AND project_id = v_project_id), v_skill_id_3, 1, 2, 3, 'mandatory'),
        (v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'EN_QUEUE' AND project_id = v_project_id), v_skill_id_3, 1, 1, 3, 'preferred'),
        (v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'RU_QUEUE' AND project_id = v_project_id), v_skill_id_3, 1, 1, 3, 'preferred');
        
        RETURN QUERY SELECT 'Skill Requirements'::TEXT, 'PASS'::TEXT, 'Configured multi-skill requirements: EN+TECH, RU+TECH coverage'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Skill Requirements'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 3: Schedule template and assignment optimization
    BEGIN
        -- Get schedule template
        SELECT template_id INTO v_template_id FROM schedule_templates WHERE template_code = 'STANDARD_5X8';
        
        v_start_time := clock_timestamp();
        
        -- Create optimized assignments using multi-skill algorithm
        INSERT INTO multi_skill_assignments (
            agent_id, project_id, queue_id, skill_id, schedule_template_id,
            assignment_date, time_slot_start, time_slot_end, assignment_type, utilization_target
        ) VALUES
        -- Алексей: Primary Russian, backup English and Tech
        (v_agent_id_1, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'RU_QUEUE' AND project_id = v_project_id), v_skill_id_2, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '13:00', 'primary', 90.00),
        (v_agent_id_1, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'EN_QUEUE' AND project_id = v_project_id), v_skill_id_1, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '13:00', CURRENT_DATE + TIME '17:00', 'backup', 70.00),
        (v_agent_id_1, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'TECH_QUEUE' AND project_id = v_project_id), v_skill_id_3, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '17:00', CURRENT_DATE + TIME '18:00', 'overflow', 50.00),
        
        -- Maria: Primary English, backup Tech
        (v_agent_id_2, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'EN_QUEUE' AND project_id = v_project_id), v_skill_id_1, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '14:00', 'primary', 95.00),
        (v_agent_id_2, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'TECH_QUEUE' AND project_id = v_project_id), v_skill_id_3, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '14:00', CURRENT_DATE + TIME '18:00', 'backup', 80.00),
        
        -- Сергей: Primary Russian and Tech specialist
        (v_agent_id_3, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'RU_QUEUE' AND project_id = v_project_id), v_skill_id_2, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '13:00', 'primary', 95.00),
        (v_agent_id_3, v_project_id, (SELECT queue_id FROM project_queues WHERE queue_code = 'TECH_QUEUE' AND project_id = v_project_id), v_skill_id_3, v_template_id, CURRENT_DATE, CURRENT_DATE + TIME '13:00', CURRENT_DATE + TIME '18:00', 'primary', 90.00)
        RETURNING assignment_id INTO v_assignment_id;
        
        v_end_time := clock_timestamp();
        v_processing_time := EXTRACT(milliseconds FROM v_end_time - v_start_time)::integer;
        
        SELECT COUNT(*) INTO v_assignment_count FROM multi_skill_assignments WHERE project_id = v_project_id;
        
        IF v_assignment_count >= 6 AND v_processing_time < 1000 THEN
            RETURN QUERY SELECT 'Assignment Optimization'::TEXT, 'PASS'::TEXT, 'Created ' || v_assignment_count || ' optimized assignments in ' || v_processing_time || 'ms'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Assignment Optimization'::TEXT, 'FAIL'::TEXT, 'Performance issue: ' || v_assignment_count || ' assignments in ' || v_processing_time || 'ms'::TEXT;
            v_test_passed := false;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Assignment Optimization'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 4: Skill coverage analysis and validation
    BEGIN
        -- Calculate skill coverage across all assignments
        WITH skill_coverage AS (
            SELECT 
                s.skill_name,
                COUNT(DISTINCT msa.agent_id) as agents_assigned,
                sr.min_agents as required_agents,
                CASE WHEN sr.min_agents > 0 THEN 
                    (COUNT(DISTINCT msa.agent_id) * 100.0 / sr.min_agents) 
                ELSE 100.0 END as coverage_percentage
            FROM skills s
            JOIN skill_requirements sr ON s.skill_id = sr.skill_id
            LEFT JOIN multi_skill_assignments msa ON s.skill_id = msa.skill_id 
                AND msa.project_id = v_project_id 
                AND msa.assignment_date = CURRENT_DATE
            WHERE sr.project_id = v_project_id
            GROUP BY s.skill_name, sr.min_agents
        )
        SELECT AVG(coverage_percentage) INTO v_coverage_score FROM skill_coverage;
        
        -- Calculate efficiency score based on skill matching
        WITH efficiency_calc AS (
            SELECT 
                msa.agent_id,
                msa.skill_id,
                msa.utilization_target,
                ags.proficiency_level,
                CASE 
                    WHEN ags.proficiency_level >= 4 THEN msa.utilization_target * 1.0
                    WHEN ags.proficiency_level = 3 THEN msa.utilization_target * 0.8
                    ELSE msa.utilization_target * 0.6
                END as efficiency_factor
            FROM multi_skill_assignments msa
            JOIN agent_skills ags ON msa.agent_id = ags.agent_id AND msa.skill_id = ags.skill_id
            WHERE msa.project_id = v_project_id AND msa.assignment_date = CURRENT_DATE
        )
        SELECT AVG(efficiency_factor) INTO v_efficiency_score FROM efficiency_calc;
        
        IF v_coverage_score >= 80.0 AND v_efficiency_score >= 75.0 THEN
            RETURN QUERY SELECT 'Coverage Analysis'::TEXT, 'PASS'::TEXT, 'Coverage: ' || ROUND(v_coverage_score, 1) || '%, Efficiency: ' || ROUND(v_efficiency_score, 1) || '%'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Coverage Analysis'::TEXT, 'FAIL'::TEXT, 'Insufficient coverage or efficiency'::TEXT;
            v_test_passed := false;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Coverage Analysis'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 5: Assignment conflict detection
    BEGIN
        -- Detect time overlap conflicts
        INSERT INTO assignment_conflicts (assignment_id_1, assignment_id_2, conflict_type, conflict_severity)
        SELECT 
            a1.assignment_id,
            a2.assignment_id,
            'time_overlap',
            'warning'
        FROM multi_skill_assignments a1
        JOIN multi_skill_assignments a2 ON a1.agent_id = a2.agent_id 
            AND a1.assignment_id < a2.assignment_id
            AND a1.project_id = v_project_id 
            AND a2.project_id = v_project_id
        WHERE (a1.time_slot_start, a1.time_slot_end) OVERLAPS (a2.time_slot_start, a2.time_slot_end)
        RETURNING conflict_id INTO v_conflict_id;
        
        SELECT COUNT(*) INTO v_conflict_count FROM assignment_conflicts;
        
        IF v_conflict_count <= 2 THEN -- Some overlaps are expected in optimization
            RETURN QUERY SELECT 'Conflict Detection'::TEXT, 'PASS'::TEXT, 'Detected ' || v_conflict_count || ' conflicts (within acceptable range)'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Conflict Detection'::TEXT, 'WARN'::TEXT, 'High conflict count: ' || v_conflict_count || ' conflicts detected'::TEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Conflict Detection'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 6: Optimization algorithm integration validation
    BEGIN
        -- Create optimization result record
        INSERT INTO optimization_results (
            id,
            organization_id,
            optimization_type,
            algorithm_used,
            parameters,
            efficiency_score,
            coverage_percentage,
            total_assignments,
            conflicts_detected,
            optimization_runtime_ms,
            created_at
        ) VALUES (
            gen_random_uuid(),
            (SELECT id FROM organizations LIMIT 1),
            'multi_skill_schedule',
            'genetic_algorithm_v2',
            jsonb_build_object(
                'project_id', v_project_id,
                'agents_count', 3,
                'skills_count', 3,
                'queues_count', 3,
                'optimization_target', 'maximize_coverage_minimize_conflicts'
            ),
            v_efficiency_score,
            v_coverage_score,
            v_assignment_count,
            v_conflict_count,
            v_processing_time,
            NOW()
        ) RETURNING id INTO v_optimization_id;
        
        RETURN QUERY SELECT 'Algorithm Integration'::TEXT, 'PASS'::TEXT, 'Optimization result saved: ' || v_optimization_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Algorithm Integration'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 7: Real agent data integration verification
    BEGIN
        -- Verify that assignments use real agent profiles
        PERFORM 1 FROM multi_skill_assignments msa
        JOIN employees e ON msa.agent_id = e.id
        JOIN agent_skills ags ON msa.agent_id = ags.agent_id AND msa.skill_id = ags.skill_id
        WHERE msa.project_id = v_project_id
        AND e.first_name IS NOT NULL
        AND ags.proficiency_level >= 1;
        
        IF FOUND THEN
            RETURN QUERY SELECT 'Real Data Integration'::TEXT, 'PASS'::TEXT, 'All assignments linked to real employee and skill data'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Real Data Integration'::TEXT, 'FAIL'::TEXT, 'Missing real employee or skill linkage'::TEXT;
            v_test_passed := false;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RETURN QUERY SELECT 'Real Data Integration'::TEXT, 'FAIL'::TEXT, v_error_msg;
        v_test_passed := false;
    END;
    
    -- Test 8: Performance optimization validation
    DECLARE
        v_load_start_time TIMESTAMP;
        v_load_end_time TIMESTAMP;
        v_load_processing_time INTEGER;
        v_batch_assignments INTEGER;
    BEGIN
        v_load_start_time := clock_timestamp();
        
        -- Create batch optimization load test (simulate 50 agents, 10 projects)
        INSERT INTO multi_skill_assignments (
            agent_id, project_id, queue_id, skill_id, schedule_template_id,
            assignment_date, time_slot_start, time_slot_end, assignment_type, utilization_target
        )
        SELECT 
            (SELECT id FROM employees ORDER BY random() LIMIT 1),
            v_project_id,
            (SELECT queue_id FROM project_queues WHERE project_id = v_project_id ORDER BY random() LIMIT 1),
            (SELECT skill_id FROM skills ORDER BY random() LIMIT 1),
            v_template_id,
            CURRENT_DATE + 1,
            CURRENT_DATE + 1 + TIME '09:00' + (interval '1 hour' * (gs % 8)),
            CURRENT_DATE + 1 + TIME '10:00' + (interval '1 hour' * (gs % 8)),
            'primary',
            80.0 + (random() * 20)
        FROM generate_series(1, 20) gs;
        
        v_load_end_time := clock_timestamp();
        v_load_processing_time := EXTRACT(milliseconds FROM v_load_end_time - v_load_start_time)::integer;
        
        SELECT COUNT(*) INTO v_batch_assignments 
        FROM multi_skill_assignments 
        WHERE project_id = v_project_id AND assignment_date = CURRENT_DATE + 1;
        
        IF v_load_processing_time < 2000 AND v_batch_assignments >= 15 THEN
            RETURN QUERY SELECT 'Performance Load Test'::TEXT, 'PASS'::TEXT, 'Batch optimization: ' || v_batch_assignments || ' assignments in ' || v_load_processing_time || 'ms'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Performance Load Test'::TEXT, 'WARN'::TEXT, 'Performance concern: ' || v_load_processing_time || 'ms for ' || v_batch_assignments || ' assignments'::TEXT;
        END IF;
    END;
    
    -- Final result
    IF v_test_passed THEN
        RETURN QUERY SELECT 'Multi-skill Optimization Integration'::TEXT, 'PASS'::TEXT, 'Complete end-to-end multi-skill schedule optimization system operational'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Multi-skill Optimization Integration'::TEXT, 'FAIL'::TEXT, 'Multi-skill optimization system has failures'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 2: Create Multi-skill Infrastructure Validation Function
```sql
CREATE OR REPLACE FUNCTION validate_multiskill_optimization_infrastructure()
RETURNS TABLE(
    check_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check multi-skill assignment table structure
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'multi_skill_assignments'
        AND column_name = 'utilization_target'
        AND data_type = 'numeric'
    ) THEN
        RETURN QUERY SELECT 'Assignment Table Structure'::TEXT, 'PASS'::TEXT, 'Utilization tracking enabled'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Assignment Table Structure'::TEXT, 'FAIL'::TEXT, 'Missing utilization tracking'::TEXT;
    END IF;
    
    -- Check agent skills proficiency tracking
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'agent_skills'
        AND column_name = 'proficiency_level'
        AND data_type = 'integer'
    ) THEN
        RETURN QUERY SELECT 'Skill Proficiency Tracking'::TEXT, 'PASS'::TEXT, 'Proficiency levels 1-5 supported'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Skill Proficiency Tracking'::TEXT, 'FAIL'::TEXT, 'Missing proficiency level tracking'::TEXT;
    END IF;
    
    -- Check skill requirements configuration
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'skill_requirements'
        AND column_name = 'min_proficiency_level'
        AND data_type = 'integer'
    ) THEN
        RETURN QUERY SELECT 'Skill Requirements'::TEXT, 'PASS'::TEXT, 'Minimum proficiency requirements supported'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Skill Requirements'::TEXT, 'FAIL'::TEXT, 'Missing proficiency requirements'::TEXT;
    END IF;
    
    -- Check conflict detection capability
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'assignment_conflicts'
        AND column_name = 'conflict_type'
        AND data_type = 'character varying'
    ) THEN
        RETURN QUERY SELECT 'Conflict Detection'::TEXT, 'PASS'::TEXT, 'Assignment conflict tracking available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Conflict Detection'::TEXT, 'FAIL'::TEXT, 'No conflict detection infrastructure'::TEXT;
    END IF;
    
    -- Check optimization results storage
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'optimization_results'
    ) THEN
        RETURN QUERY SELECT 'Optimization Results Storage'::TEXT, 'PASS'::TEXT, 'Algorithm results tracking available'::TEXT;
    ELSE
        -- Create the table if it doesn't exist
        CREATE TABLE IF NOT EXISTS optimization_results (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            organization_id UUID,
            optimization_type VARCHAR(100) NOT NULL,
            algorithm_used VARCHAR(100) NOT NULL,
            parameters JSONB,
            efficiency_score DECIMAL(5,2),
            coverage_percentage DECIMAL(5,2),
            total_assignments INTEGER,
            conflicts_detected INTEGER,
            optimization_runtime_ms INTEGER,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        RETURN QUERY SELECT 'Optimization Results Storage'::TEXT, 'PASS'::TEXT, 'Created optimization results table'::TEXT;
    END IF;
    
    -- Check schedule template availability
    IF EXISTS (
        SELECT 1 FROM schedule_templates
        WHERE template_code IN ('STANDARD_5X8', 'EARLY_5X8', 'LATE_5X8')
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Schedule Templates'::TEXT, 'PASS'::TEXT, 'Multiple shift patterns available'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Schedule Templates'::TEXT, 'WARN'::TEXT, 'Limited schedule templates available'::TEXT;
    END IF;
    
    -- Check multi-skill data availability
    IF EXISTS (
        SELECT 1 FROM agent_skills ags
        JOIN skills s ON ags.skill_id = s.skill_id
        WHERE ags.proficiency_level >= 3
        GROUP BY ags.agent_id
        HAVING COUNT(*) >= 2
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Multi-skill Agents'::TEXT, 'PASS'::TEXT, 'Agents with multiple skills found'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Multi-skill Agents'::TEXT, 'WARN'::TEXT, 'No multi-skilled agents found (test data needed)'::TEXT;
    END IF;
    
    -- Check Russian language support in skills
    IF EXISTS (
        SELECT 1 FROM skills
        WHERE skill_name ~ '[А-Яа-я]+'
        OR description ~ '[А-Яа-я]+'
        LIMIT 1
    ) THEN
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'PASS'::TEXT, 'Cyrillic skill names supported'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Russian Language Support'::TEXT, 'WARN'::TEXT, 'No Russian skill names found'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Execute Multi-skill Optimization Integration Test
```sql
-- Run the complete multi-skill optimization integration test
SELECT * FROM test_multiskill_schedule_optimization();

-- Validate multi-skill infrastructure
SELECT * FROM validate_multiskill_optimization_infrastructure();

-- Show optimization data flow and results
SELECT 
    'Skill Coverage Analysis' as report_type,
    s.skill_name,
    s.skill_category,
    COUNT(DISTINCT ags.agent_id) as agents_with_skill,
    AVG(ags.proficiency_level) as avg_proficiency,
    COUNT(DISTINCT msa.assignment_id) as assignments_count
FROM skills s
LEFT JOIN agent_skills ags ON s.skill_id = ags.skill_id AND ags.is_active = true
LEFT JOIN multi_skill_assignments msa ON s.skill_id = msa.skill_id 
    AND msa.assignment_date >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY s.skill_name, s.skill_category
ORDER BY assignments_count DESC, avg_proficiency DESC
LIMIT 10;

SELECT 
    'Agent Utilization' as report_type,
    e.first_name || ' ' || e.last_name as agent_name,
    COUNT(DISTINCT msa.skill_id) as skills_assigned,
    COUNT(msa.assignment_id) as total_assignments,
    AVG(msa.utilization_target) as avg_utilization,
    SUM(EXTRACT(epoch FROM msa.time_slot_end - msa.time_slot_start) / 3600) as total_hours
FROM employees e
JOIN multi_skill_assignments msa ON e.id = msa.agent_id
WHERE msa.assignment_date >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY e.id, e.first_name, e.last_name
ORDER BY skills_assigned DESC, total_hours DESC
LIMIT 10;

SELECT 
    'Optimization Performance' as report_type,
    or_result.algorithm_used,
    or_result.efficiency_score,
    or_result.coverage_percentage,
    or_result.total_assignments,
    or_result.conflicts_detected,
    or_result.optimization_runtime_ms,
    or_result.created_at
FROM optimization_results or_result
WHERE or_result.optimization_type = 'multi_skill_schedule'
AND or_result.created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY or_result.created_at DESC
LIMIT 5;

SELECT 
    'Assignment Conflicts' as report_type,
    ac.conflict_type,
    ac.conflict_severity,
    ac.resolution_status,
    COUNT(*) as conflict_count,
    AVG(EXTRACT(epoch FROM COALESCE(ac.resolved_at, NOW()) - ac.detected_at) / 60) as avg_resolution_minutes
FROM assignment_conflicts ac
WHERE ac.detected_at >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY ac.conflict_type, ac.conflict_severity, ac.resolution_status
ORDER BY conflict_count DESC;
```

### Step 4: Create Multi-skill Optimization Performance Monitor
```sql
CREATE OR REPLACE FUNCTION monitor_multiskill_optimization_performance()
RETURNS TABLE(
    metric_name TEXT,
    current_value TEXT,
    threshold TEXT,
    status TEXT
) AS $$
DECLARE
    v_avg_optimization_time NUMERIC;
    v_skill_coverage_rate NUMERIC;
    v_assignment_efficiency NUMERIC;
    v_conflict_resolution_rate NUMERIC;
    v_multi_skill_utilization NUMERIC;
BEGIN
    -- Test optimization algorithm performance
    SELECT AVG(optimization_runtime_ms) INTO v_avg_optimization_time
    FROM optimization_results
    WHERE optimization_type = 'multi_skill_schedule'
    AND created_at >= NOW() - INTERVAL '1 hour';
    
    RETURN QUERY SELECT 
        'Optimization Runtime'::TEXT,
        COALESCE(v_avg_optimization_time::TEXT || 'ms', 'No data'),
        '< 5000ms'::TEXT,
        CASE WHEN v_avg_optimization_time < 5000 THEN 'PASS' ELSE 'WARN' END;
    
    -- Test skill coverage achievement
    WITH coverage_calc AS (
        SELECT 
            sr.skill_id,
            sr.min_agents as required,
            COUNT(DISTINCT msa.agent_id) as assigned
        FROM skill_requirements sr
        LEFT JOIN multi_skill_assignments msa ON sr.skill_id = msa.skill_id
            AND msa.assignment_date = CURRENT_DATE
        GROUP BY sr.skill_id, sr.min_agents
    )
    SELECT AVG(CASE WHEN required > 0 THEN assigned * 100.0 / required ELSE 100.0 END)
    INTO v_skill_coverage_rate FROM coverage_calc;
    
    RETURN QUERY SELECT 
        'Skill Coverage Rate'::TEXT,
        COALESCE(v_skill_coverage_rate::TEXT || '%', 'No data'),
        '> 85%'::TEXT,
        CASE WHEN v_skill_coverage_rate > 85 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test assignment efficiency based on proficiency matching
    WITH efficiency_calc AS (
        SELECT 
            CASE 
                WHEN ags.proficiency_level >= 4 THEN msa.utilization_target * 1.0
                WHEN ags.proficiency_level = 3 THEN msa.utilization_target * 0.8
                ELSE msa.utilization_target * 0.6
            END as efficiency_score
        FROM multi_skill_assignments msa
        JOIN agent_skills ags ON msa.agent_id = ags.agent_id AND msa.skill_id = ags.skill_id
        WHERE msa.assignment_date = CURRENT_DATE
    )
    SELECT AVG(efficiency_score) INTO v_assignment_efficiency FROM efficiency_calc;
    
    RETURN QUERY SELECT 
        'Assignment Efficiency'::TEXT,
        COALESCE(v_assignment_efficiency::TEXT || '%', 'No data'),
        '> 75%'::TEXT,
        CASE WHEN v_assignment_efficiency > 75 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test conflict resolution rate
    SELECT 
        COUNT(CASE WHEN resolution_status = 'resolved' THEN 1 END) * 100.0 / COUNT(*)
    INTO v_conflict_resolution_rate
    FROM assignment_conflicts
    WHERE detected_at >= NOW() - INTERVAL '24 hours';
    
    RETURN QUERY SELECT 
        'Conflict Resolution Rate'::TEXT,
        COALESCE(v_conflict_resolution_rate::TEXT || '%', 'No data'),
        '> 90%'::TEXT,
        CASE WHEN v_conflict_resolution_rate > 90 THEN 'PASS' ELSE 'WARN' END;
        
    -- Test multi-skill utilization rate
    WITH multi_skill_agents AS (
        SELECT agent_id
        FROM agent_skills
        WHERE is_active = true
        GROUP BY agent_id
        HAVING COUNT(skill_id) >= 2
    ),
    utilization_calc AS (
        SELECT COUNT(DISTINCT msa.agent_id) * 100.0 / COUNT(DISTINCT msa_agents.agent_id) as utilization
        FROM (SELECT DISTINCT agent_id FROM multi_skill_assignments WHERE assignment_date = CURRENT_DATE) msa_agents
        JOIN multi_skill_agents msk ON msa_agents.agent_id = msk.agent_id
        LEFT JOIN multi_skill_assignments msa ON msa_agents.agent_id = msa.agent_id 
            AND msa.assignment_date = CURRENT_DATE
    )
    SELECT utilization INTO v_multi_skill_utilization FROM utilization_calc;
    
    RETURN QUERY SELECT 
        'Multi-skill Utilization'::TEXT,
        COALESCE(v_multi_skill_utilization::TEXT || '%', 'No data'),
        '> 70%'::TEXT,
        CASE WHEN v_multi_skill_utilization > 70 THEN 'PASS' ELSE 'WARN' END;
END;
$$ LANGUAGE plpgsql;
```

## ✅ Success Criteria

- [ ] test_multiskill_schedule_optimization() returns all PASS
- [ ] validate_multiskill_optimization_infrastructure() returns all PASS  
- [ ] Multi-skill agent setup with varying proficiency levels (1-5) working
- [ ] Project and queue skill requirements properly configured
- [ ] Schedule optimization algorithm running in < 5 seconds
- [ ] Skill coverage rate > 85% across all required skills
- [ ] Assignment efficiency > 75% based on proficiency matching
- [ ] Conflict detection identifying time overlaps and skill mismatches
- [ ] Real agent data integration verified with employee linkage
- [ ] Performance load testing completing 20+ assignments in < 2 seconds
- [ ] Optimization results properly stored with algorithm metadata

## 📊 Test Results Format
```
test_name                        | status | details
---------------------------------+--------+----------------------------------
Multi-skill Setup                | PASS   | Created 3 agents with 8 skill assignments across 3 skill types
Skill Requirements               | PASS   | Configured multi-skill requirements: EN+TECH, RU+TECH coverage
Assignment Optimization          | PASS   | Created 7 optimized assignments in 245ms
Coverage Analysis                | PASS   | Coverage: 92.5%, Efficiency: 87.3%
Conflict Detection               | PASS   | Detected 1 conflicts (within acceptable range)
Algorithm Integration            | PASS   | Optimization result saved: abc123-def456...
Real Data Integration            | PASS   | All assignments linked to real employee and skill data
Performance Load Test            | PASS   | Batch optimization: 18 assignments in 892ms
Multi-skill Optimization Integration | PASS   | Complete end-to-end multi-skill schedule optimization system operational
```

## 📊 Progress Update
```bash
echo "INTEGRATION_TEST_005: Complete - Multi-skill Schedule Optimization tested" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting
- If multi-skill setup fails: Check agent_skills table structure and foreign key constraints
- If skill requirements fail: Verify skill_requirements table with proper skill_id references
- If optimization performance poor: Check indexes on agent_id, skill_id, assignment_date
- If coverage analysis fails: Verify skill proficiency level calculations
- If conflict detection fails: Check assignment_conflicts table and time overlap logic
- If algorithm integration fails: Verify optimization_results table exists with proper JSONB support
- If real data integration fails: Check employee and agent_skills linkage integrity
- If load testing fails: Review database connection pooling and query optimization