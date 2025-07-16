-- =============================================================================
-- integrated_workforce_optimization_demo.sql
-- Comprehensive Demo Data for Integrated Workforce Optimization System
-- =============================================================================
-- Purpose: Demonstrate real workforce management with Russian holidays,
--          employee preferences, schedule optimization, and resource allocation
-- =============================================================================

-- Apply the main schema first
\i 'src/database/schemas/062_integrated_workforce_optimization.sql'

-- =============================================================================
-- DEMO COMPANY: ООО "ТехноСервис Плюс" (TechnoService Plus LLC)
-- =============================================================================

-- Realistic Russian call center with 50 employees across multiple departments
DO $$
DECLARE
    -- Employee IDs for key personnel
    emp_director INTEGER;
    emp_hr_manager INTEGER;
    emp_shift_supervisor INTEGER;
    
    -- Counter for loop
    i INTEGER;
    emp_id INTEGER;
    random_dept VARCHAR(100);
    random_scheme VARCHAR(50);
    
BEGIN
    -- Create departments if they don't exist
    INSERT INTO departments (id, name, description) VALUES
    (dep_customer_service, 'Служба поддержки клиентов', 'Основная служба работы с клиентами'),
    (dep_technical_support, 'Техническая поддержка', 'Специализированная техническая помощь'),
    (dep_sales, 'Отдел продаж', 'Активные продажи и консультации'),
    (dep_management, 'Управление', 'Руководящий состав')
    ON CONFLICT (id) DO NOTHING;
    
    -- Create key management employees
    INSERT INTO employees (id, full_name, department, position, email, hire_date, is_active) VALUES
    (emp_director, 'Смирнов Александр Викторович', 'Управление', 'Генеральный директор', 'director@technoservice.ru', '2020-01-15', true),
    (emp_hr_manager, 'Петрова Елена Михайловна', 'Управление', 'Начальник отдела кадров', 'hr@technoservice.ru', '2020-03-01', true),
    (emp_shift_supervisor, 'Козлов Дмитрий Сергеевич', 'Служба поддержки клиентов', 'Супервайзер смены', 'supervisor@technoservice.ru', '2021-06-15', true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Create 47 additional employees with realistic Russian names
    FOR i IN 1..47 LOOP
        emp_id := uuid_generate_v4();
        
        -- Randomly assign department
        random_dept := CASE (i % 4)
            WHEN 0 THEN dep_customer_service
            WHEN 1 THEN dep_technical_support  
            WHEN 2 THEN dep_sales
            ELSE dep_customer_service
        END;
        
        INSERT INTO employees (id, full_name, department, position, email, hire_date, is_active) VALUES
        (emp_id, 
         CASE (i % 20)
             WHEN 0 THEN 'Иванов Иван Иванович'
             WHEN 1 THEN 'Петров Петр Петрович'
             WHEN 2 THEN 'Сидорова Анна Владимировна'
             WHEN 3 THEN 'Козлова Мария Александровна'
             WHEN 4 THEN 'Николаев Николай Николаевич'
             WHEN 5 THEN 'Волкова Екатерина Сергеевна'
             WHEN 6 THEN 'Морозов Андрей Викторович'
             WHEN 7 THEN 'Лебедева Ольга Михайловна'
             WHEN 8 THEN 'Новиков Алексей Дмитриевич'
             WHEN 9 THEN 'Попова Татьяна Игоревна'
             WHEN 10 THEN 'Васильев Василий Васильевич'
             WHEN 11 THEN 'Михайлова Людмила Петровна'
             WHEN 12 THEN 'Федоров Федор Федорович'
             WHEN 13 THEN 'Соколова Наталья Андреевна'
             WHEN 14 THEN 'Александров Сергей Владимирович'
             WHEN 15 THEN 'Григорьева Ирина Николаевна'
             WHEN 16 THEN 'Степанов Степан Степанович'
             WHEN 17 THEN 'Романова Светлана Юрьевна'
             WHEN 18 THEN 'Семенов Семен Семенович'
             ELSE 'Кузнецова Валентина Игоревна'
         END,
         CASE 
             WHEN random_dept = dep_customer_service THEN 'Служба поддержки клиентов'
             WHEN random_dept = dep_technical_support THEN 'Техническая поддержка'
             WHEN random_dept = dep_sales THEN 'Отдел продаж'
             ELSE 'Управление'
         END,
         CASE 
             WHEN random_dept = dep_customer_service THEN 'Оператор службы поддержки'
             WHEN random_dept = dep_technical_support THEN 'Специалист технической поддержки'
             WHEN random_dept = dep_sales THEN 'Менеджер по продажам'
             ELSE 'Специалист'
         END,
         'employee' || i || '@technoservice.ru',
         CURRENT_DATE - INTERVAL '6 months' - (RANDOM() * INTERVAL '2 years'),
         true);
    END LOOP;
    
    -- Store key employee IDs for later use
    PERFORM set_config('demo.director_id', emp_director::text, false);
    PERFORM set_config('demo.hr_manager_id', emp_hr_manager::text, false);
    PERFORM set_config('demo.supervisor_id', emp_shift_supervisor::text, false);
END $$;

-- =============================================================================
-- VACATION SCHEME ASSIGNMENTS
-- =============================================================================

-- Assign vacation schemes based on employee seniority and position
DO $$
DECLARE
    emp_record RECORD;
    scheme_id VARCHAR(50);
BEGIN
    FOR emp_record IN SELECT id, position, hire_date FROM employees WHERE is_active = true LOOP
        -- Determine scheme based on position and seniority
        IF emp_record.position LIKE '%директор%' OR emp_record.position LIKE '%начальник%' THEN
            scheme_id := 'management_ru';
        ELSIF emp_record.hire_date <= CURRENT_DATE - INTERVAL '3 years' THEN
            scheme_id := 'senior_ru';
        ELSE
            scheme_id := 'standard_ru';
        END IF;
        
        -- Create scheme assignment
        INSERT INTO employee_scheme_assignments (
            assignment_id, employee_id, scheme_type_id, assignment_reason, assigned_by
        ) VALUES (
            'assignment_' || emp_record.id::text,
            emp_record.id,
            scheme_id,
            'Автоматическое назначение при регистрации в системе',
            current_setting('demo.hr_manager_id')::UUID
        );
        
        -- Calculate vacation entitlements for 2025
        INSERT INTO employee_vacation_calculations (
            calculation_id,
            employee_id,
            scheme_id,
            calculation_year,
            base_entitlement_days,
            total_entitlement_days,
            periods_remaining,
            remaining_days
        )
        SELECT 
            'calc_2025_' || emp_record.id::text,
            emp_record.id,
            scheme_id,
            2025,
            evs.annual_vacation_days,
            evs.annual_vacation_days,
            evs.max_periods_per_year,
            evs.annual_vacation_days
        FROM enhanced_vacation_schemes evs 
        WHERE evs.scheme_id = scheme_id;
    END LOOP;
END $$;

-- =============================================================================
-- EMPLOYEE PREFERENCES WITH REALISTIC VARIATIONS
-- =============================================================================

-- Create diverse preference profiles reflecting real employee needs
DO $$
DECLARE
    emp_record RECORD;
    pref_counter INTEGER := 1;
BEGIN
    FOR emp_record IN 
        SELECT id, full_name, department, position 
        FROM employees 
        WHERE is_active = true 
        ORDER BY hire_date 
    LOOP
        -- Shift start time preferences (most common preference)
        INSERT INTO employee_integrated_preferences (
            preference_id, employee_id, type_id, preference_value, 
            display_value_ru, priority, flexibility_factor, optimization_score
        ) VALUES (
            'pref_shift_' || pref_counter,
            emp_record.id,
            'shift_start_time',
            jsonb_build_object(
                'preferred_times', CASE (pref_counter % 4)
                    WHEN 0 THEN '["08:00", "09:00"]'
                    WHEN 1 THEN '["09:00", "10:00"]'
                    WHEN 2 THEN '["07:00", "08:00"]'
                    ELSE '["10:00", "11:00"]'
                END::jsonb,
                'max_variation_hours', 2,
                'weekend_preference', CASE WHEN pref_counter % 3 = 0 THEN 'avoid' ELSE 'flexible' END
            ),
            CASE (pref_counter % 4)
                WHEN 0 THEN 'Предпочитаю начинать в 8:00-9:00'
                WHEN 1 THEN 'Предпочитаю начинать в 9:00-10:00'
                WHEN 2 THEN 'Предпочитаю ранние смены 7:00-8:00'
                ELSE 'Предпочитаю поздние смены 10:00-11:00'
            END,
            CASE 
                WHEN emp_record.position LIKE '%супервайзер%' THEN 'high'
                WHEN pref_counter % 5 = 0 THEN 'critical'
                WHEN pref_counter % 3 = 0 THEN 'high'
                ELSE 'medium'
            END,
            CASE 
                WHEN pref_counter % 6 = 0 THEN 3  -- Low flexibility
                WHEN pref_counter % 4 = 0 THEN 8  -- High flexibility
                ELSE 5 -- Medium flexibility
            END,
            7.0 + (RANDOM() * 2.0) -- Satisfaction score 7.0-9.0
        );
        
        -- Vacation period preferences
        INSERT INTO employee_integrated_preferences (
            preference_id, employee_id, type_id, preference_value,
            display_value_ru, priority, flexibility_factor, optimization_score
        ) VALUES (
            'pref_vacation_' || pref_counter,
            emp_record.id,
            'vacation_period',
            jsonb_build_object(
                'preferred_months', CASE (pref_counter % 5)
                    WHEN 0 THEN '["06", "07", "08"]'  -- Summer vacation
                    WHEN 1 THEN '["12", "01"]'       -- Winter vacation
                    WHEN 2 THEN '["05", "09"]'       -- Spring/Fall
                    WHEN 3 THEN '["07", "08"]'       -- Peak summer
                    ELSE '["04", "05", "09", "10"]'  -- Shoulder seasons
                END::jsonb,
                'avoid_holidays', CASE WHEN pref_counter % 3 = 0 THEN false ELSE true END,
                'preferred_duration_weeks', CASE 
                    WHEN pref_counter % 4 = 0 THEN 2
                    WHEN pref_counter % 4 = 1 THEN 3
                    ELSE 2
                END,
                'flexible_dates', CASE WHEN pref_counter % 2 = 0 THEN true ELSE false END
            ),
            CASE (pref_counter % 5)
                WHEN 0 THEN 'Предпочитаю летний отпуск (июнь-август)'
                WHEN 1 THEN 'Предпочитаю зимний отпуск (декабрь-январь)'
                WHEN 2 THEN 'Предпочитаю весна/осень (май, сентябрь)'
                WHEN 3 THEN 'Только летом (июль-август)'
                ELSE 'Межсезонье (апрель-май, сентябрь-октябрь)'
            END,
            CASE 
                WHEN pref_counter % 7 = 0 THEN 'high'
                ELSE 'medium'
            END,
            6 + (pref_counter % 4), -- Flexibility 6-9
            6.5 + (RANDOM() * 2.5) -- Satisfaction score 6.5-9.0
        );
        
        -- Work location preferences (especially relevant post-COVID)
        IF pref_counter % 2 = 0 THEN -- Not all employees have location preferences
            INSERT INTO employee_integrated_preferences (
                preference_id, employee_id, type_id, preference_value,
                display_value_ru, priority, flexibility_factor, optimization_score
            ) VALUES (
                'pref_location_' || pref_counter,
                emp_record.id,
                'work_location',
                jsonb_build_object(
                    'preferred_mode', CASE (pref_counter % 3)
                        WHEN 0 THEN 'office'
                        WHEN 1 THEN 'hybrid'
                        ELSE 'remote'
                    END,
                    'remote_days_per_week', CASE 
                        WHEN pref_counter % 3 = 1 THEN 2
                        WHEN pref_counter % 3 = 2 THEN 5
                        ELSE 0
                    END,
                    'office_required_days', CASE WHEN pref_counter % 3 = 0 THEN '["monday", "friday"]' ELSE '[]' END::jsonb
                ),
                CASE (pref_counter % 3)
                    WHEN 0 THEN 'Предпочитаю работу в офисе'
                    WHEN 1 THEN 'Гибридный режим (2 дня удаленно)'
                    ELSE 'Предпочитаю удаленную работу'
                END,
                CASE 
                    WHEN emp_record.department = 'Техническая поддержка' THEN 'medium'
                    ELSE 'low'
                END,
                7, -- Standard flexibility for location
                8.0 + (RANDOM() * 1.5) -- High satisfaction for location preferences
            );
        END IF;
        
        -- Skill development preferences for technical roles
        IF emp_record.department IN ('Техническая поддержка', 'Отдел продаж') THEN
            INSERT INTO employee_integrated_preferences (
                preference_id, employee_id, type_id, preference_value,
                display_value_ru, priority, flexibility_factor, optimization_score
            ) VALUES (
                'pref_skill_' || pref_counter,
                emp_record.id,
                'skill_development',
                jsonb_build_object(
                    'target_skills', CASE emp_record.department
                        WHEN 'Техническая поддержка' THEN '["advanced_troubleshooting", "network_diagnostics", "customer_communication"]'
                        ELSE '["sales_techniques", "product_knowledge", "customer_psychology"]'
                    END::jsonb,
                    'learning_pace', 'moderate',
                    'time_investment_hours_per_week', 3,
                    'certification_interest', CASE WHEN pref_counter % 3 = 0 THEN true ELSE false END
                ),
                CASE emp_record.department
                    WHEN 'Техническая поддержка' THEN 'Развитие технических навыков диагностики'
                    ELSE 'Совершенствование техник продаж'
                END,
                'medium',
                5, -- Medium flexibility for skill development
                7.5 + (RANDOM() * 1.5) -- Good satisfaction for development
            );
        END IF;
        
        -- Team collaboration preferences
        IF pref_counter % 3 = 0 THEN -- Subset of employees
            INSERT INTO employee_integrated_preferences (
                preference_id, employee_id, type_id, preference_value,
                display_value_ru, priority, flexibility_factor, optimization_score
            ) VALUES (
                'pref_team_' || pref_counter,
                emp_record.id,
                'team_collaboration',
                jsonb_build_object(
                    'collaboration_level', CASE (pref_counter % 3)
                        WHEN 0 THEN 'high'
                        WHEN 1 THEN 'medium'
                        ELSE 'independent'
                    END,
                    'mentor_willingness', CASE WHEN pref_counter % 4 = 0 THEN true ELSE false END,
                    'training_participation', CASE WHEN pref_counter % 2 = 0 THEN 'active' ELSE 'passive' END,
                    'team_size_preference', CASE (pref_counter % 3)
                        WHEN 0 THEN 'small'
                        WHEN 1 THEN 'medium'
                        ELSE 'large'
                    END
                ),
                CASE (pref_counter % 3)
                    WHEN 0 THEN 'Активное участие в командной работе'
                    WHEN 1 THEN 'Умеренная командная работа'
                    ELSE 'Предпочитаю независимую работу'
                END,
                'low',
                8, -- High flexibility for team preferences
                6.0 + (RANDOM() * 3.0) -- Variable satisfaction
            );
        END IF;
        
        pref_counter := pref_counter + 1;
    END LOOP;
END $$;

-- =============================================================================
-- SCHEDULE TEMPLATES FOR DIFFERENT SCENARIOS
-- =============================================================================

-- Create specialized schedule templates for different business needs
INSERT INTO advanced_schedule_templates (
    template_id, template_name_ru, template_name_en, template_type,
    schedule_pattern, shift_definitions, coverage_requirements,
    optimization_objectives, constraint_rules, 
    integrates_russian_holidays, considers_shift_preferences,
    created_by
) VALUES

-- 24/7 Call Center Template
('template_24x7_optimized', 'Колл-центр 24/7 с оптимизацией', '24/7 Call Center Optimized', 'weekly',
 '{
    "pattern_type": "continuous_coverage",
    "hours_per_day": 24,
    "days_per_week": 7,
    "shift_rotation": "weekly",
    "coverage_model": "skill_based"
  }'::jsonb,
 '{
    "morning": {"start": "08:00", "end": "16:00", "duration": 8, "break_pattern": "2x15min+30min"},
    "day": {"start": "12:00", "end": "20:00", "duration": 8, "break_pattern": "2x15min+30min"},
    "evening": {"start": "16:00", "end": "00:00", "duration": 8, "break_pattern": "2x15min+30min"},
    "night": {"start": "00:00", "end": "08:00", "duration": 8, "break_pattern": "2x15min+30min"}
  }'::jsonb,
 '{
    "minimum_agents_per_shift": 8,
    "peak_coverage_multiplier": 1.8,
    "skill_coverage": {
      "customer_service": {"min": 5, "peak": 12},
      "technical_support": {"min": 2, "peak": 6},
      "sales": {"min": 1, "peak": 4}
    },
    "supervisor_ratio": 0.125
  }'::jsonb,
 '["coverage_maximization", "employee_satisfaction", "cost_efficiency"]'::jsonb,
 '{
    "max_consecutive_days": 5,
    "min_rest_hours": 11,
    "max_weekly_hours": 40,
    "night_shift_limits": {"max_consecutive": 3, "recovery_days": 2},
    "weekend_distribution": "fair_rotation",
    "vacation_coverage": "auto_replacement"
  }'::jsonb,
 true, true, current_setting('demo.hr_manager_id')::UUID),

-- Business Hours Template with Russian Holiday Optimization
('template_business_hours', 'Рабочие часы с праздничной оптимизацией', 'Business Hours with Holiday Optimization', 'weekly',
 '{
    "pattern_type": "business_hours",
    "hours_per_day": 9,
    "days_per_week": 5,
    "holiday_adjustments": "automatic",
    "bridge_optimization": true
  }'::jsonb,
 '{
    "standard": {"start": "09:00", "end": "18:00", "duration": 8, "lunch": "60min", "breaks": "2x15min"},
    "early": {"start": "08:00", "end": "17:00", "duration": 8, "lunch": "60min", "breaks": "2x15min"},
    "late": {"start": "10:00", "end": "19:00", "duration": 8, "lunch": "60min", "breaks": "2x15min"}
  }'::jsonb,
 '{
    "business_hours_coverage": 100,
    "minimum_agents_on_duty": 15,
    "lunch_overlap_prevention": true,
    "skill_balance_required": true
  }'::jsonb,
 '["preference_satisfaction", "holiday_optimization", "productivity"]'::jsonb,
 '{
    "russian_labor_code_compliance": true,
    "pre_holiday_short_days": true,
    "bridge_day_handling": "optimize_for_employees",
    "maximum_split_shifts": 0.2,
    "preference_fulfillment_target": 0.85
  }'::jsonb,
 true, true, current_setting('demo.supervisor_id')::UUID),

-- Flexible Hybrid Template
('template_hybrid_flexible', 'Гибкая гибридная модель', 'Flexible Hybrid Model', 'weekly',
 '{
    "pattern_type": "hybrid_flexible",
    "office_days_required": 3,
    "remote_days_allowed": 2,
    "core_hours": "10:00-15:00",
    "flexible_start": "07:00-11:00"
  }'::jsonb,
 '{
    "office_early": {"start": "07:00", "end": "15:00", "location": "office"},
    "office_standard": {"start": "09:00", "end": "17:00", "location": "office"},
    "office_late": {"start": "11:00", "end": "19:00", "location": "office"},
    "remote_flexible": {"start": "flexible", "duration": 8, "location": "remote"}
  }'::jsonb,
 '{
    "office_presence_minimum": 60,
    "core_hours_coverage": 100,
    "collaboration_time_blocks": ["10:00-12:00", "14:00-16:00"]
  }'::jsonb,
 '["work_life_balance", "collaboration_effectiveness", "individual_productivity"]'::jsonb,
 '{
    "core_hours_mandatory": true,
    "office_days_distribution": "employee_choice_with_constraints",
    "meeting_scheduling_priority": "office_days",
    "remote_productivity_monitoring": false
  }'::jsonb,
 true, true, current_setting('demo.hr_manager_id')::UUID);

-- =============================================================================
-- RESOURCE ALLOCATION MODELS WITH REAL SCENARIOS
-- =============================================================================

-- Create resource allocation models for different optimization scenarios
INSERT INTO resource_allocation_models (
    model_id, model_name_ru, model_name_en, allocation_type, planning_horizon,
    resource_types, capacity_definitions, demand_patterns,
    primary_objective, constraint_rules, 
    calendar_integration_enabled, preference_consideration_level,
    created_by
) VALUES

-- Peak Season Optimization
('model_peak_season', 'Оптимизация пикового сезона', 'Peak Season Optimization', 'hybrid', 'monthly',
 '{
    "human_resources": {
      "customer_service_agents": {"skill_levels": ["junior", "senior", "expert"], "availability": "24x7"},
      "technical_specialists": {"specializations": ["hardware", "software", "network"], "availability": "business_hours"},
      "sales_consultants": {"experience_levels": ["new", "experienced", "senior"], "availability": "extended_hours"}
    },
    "technical_resources": {
      "workstations": {"types": ["standard", "enhanced"], "capacity": 60},
      "phone_lines": {"capacity": 100, "concurrent_calls": 80},
      "software_licenses": {"crm": 50, "technical_tools": 20}
    }
  }'::jsonb,
 '{
    "peak_capacity": {
      "customer_service": 35,
      "technical_support": 15,
      "sales": 12
    },
    "standard_capacity": {
      "customer_service": 25,
      "technical_support": 10,
      "sales": 8
    },
    "surge_capacity": {
      "customer_service": 45,
      "technical_support": 20,
      "sales": 15
    }
  }'::jsonb,
 '{
    "seasonal_patterns": {
      "winter_peak": {"months": ["11", "12", "01"], "multiplier": 1.4},
      "summer_moderate": {"months": ["06", "07", "08"], "multiplier": 0.9},
      "spring_standard": {"months": ["03", "04", "05"], "multiplier": 1.0},
      "autumn_high": {"months": ["09", "10"], "multiplier": 1.2}
    },
    "daily_patterns": {
      "peak_hours": ["09:00-12:00", "14:00-17:00"],
      "moderate_hours": ["08:00-09:00", "12:00-14:00", "17:00-19:00"],
      "low_hours": ["19:00-08:00"]
    },
    "holiday_impact": {
      "pre_holiday": 1.6,
      "post_holiday": 1.3,
      "bridge_days": 0.7
    }
  }'::jsonb,
 'efficiency',
 '{
    "service_level_targets": {"customer_service": 0.80, "technical_support": 0.85, "sales": 0.75},
    "response_time_limits": {"customer_service": 30, "technical_support": 60, "sales": 45},
    "quality_thresholds": {"customer_satisfaction": 4.2, "first_call_resolution": 0.75},
    "cost_constraints": {"overtime_limit": 0.15, "temp_staff_limit": 0.10},
    "employee_constraints": {"max_consecutive_days": 6, "min_weekly_rest": 35}
  }'::jsonb,
 true, 'high', current_setting('demo.director_id')::UUID),

-- Holiday Period Optimization
('model_holiday_optimization', 'Оптимизация праздничных периодов', 'Holiday Period Optimization', 'preference_based', 'weekly',
 '{
    "coverage_requirements": {
      "essential_services": ["emergency_support", "critical_sales"],
      "reduced_services": ["general_inquiries", "account_management"],
      "suspended_services": ["training", "development_calls"]
    },
    "staffing_flexibility": {
      "volunteer_overtime": true,
      "cross_training_utilization": true,
      "temporary_role_expansion": true
    }
  }'::jsonb,
 '{
    "holiday_staffing": {
      "new_year_period": {"coverage": 0.4, "priority": "emergency_only"},
      "defender_day": {"coverage": 0.6, "priority": "essential_services"},
      "womens_day": {"coverage": 0.7, "priority": "standard_minus"},
      "may_holidays": {"coverage": 0.5, "priority": "essential_services"},
      "victory_day": {"coverage": 0.6, "priority": "essential_services"}
    }
  }'::jsonb,
 '{
    "vacation_demand": {
      "new_year": {"demand_multiplier": 3.5, "approval_priority": "seniority"},
      "summer_months": {"demand_multiplier": 2.2, "approval_priority": "balanced"},
      "may_holidays": {"demand_multiplier": 2.8, "approval_priority": "preference_based"}
    },
    "coverage_substitution": {
      "cross_department": true,
      "overtime_volunteers": true,
      "temporary_contractors": false
    }
  }'::jsonb,
 'satisfaction',
 '{
    "vacation_approval_rules": {
      "advance_notice_minimum": 14,
      "team_coverage_minimum": 0.6,
      "skill_coverage_critical": ["technical_support", "supervisor"],
      "blackout_period_enforcement": "flexible"
    },
    "holiday_work_compensation": {
      "double_pay_holidays": ["01-01", "05-09"],
      "time_off_compensation": true,
      "volunteer_priority": true
    }
  }'::jsonb,
 true, 'maximum', current_setting('demo.hr_manager_id')::UUID);

-- =============================================================================
-- REALISTIC OPTIMIZATION RESULTS
-- =============================================================================

-- Generate optimization results for different scenarios to demonstrate system capabilities
DO $$
DECLARE
    template_record RECORD;
    optimization_date DATE;
    result_counter INTEGER := 1;
BEGIN
    FOR template_record IN 
        SELECT template_id, template_name_ru 
        FROM advanced_schedule_templates 
        WHERE is_active = true 
    LOOP
        -- Generate results for the last 30 days
        FOR i IN 1..5 LOOP
            optimization_date := CURRENT_DATE - (i * 6);
            
            INSERT INTO schedule_optimization_results (
                optimization_id, template_id, optimization_date,
                target_period_start, target_period_end,
                employee_count, algorithm_used, execution_time_ms,
                overall_score, coverage_score, satisfaction_score, cost_efficiency_score,
                preference_fulfillment_rate, optimized_schedule, employee_assignments,
                holiday_adjustments_made, validation_status
            ) VALUES (
                'opt_result_' || result_counter,
                template_record.template_id,
                optimization_date,
                optimization_date + INTERVAL '1 day',
                optimization_date + INTERVAL '7 days',
                CASE template_record.template_id
                    WHEN 'template_24x7_optimized' THEN 40
                    WHEN 'template_business_hours' THEN 30
                    ELSE 25
                END,
                CASE (result_counter % 3)
                    WHEN 0 THEN 'genetic_algorithm'
                    WHEN 1 THEN 'linear_programming'
                    ELSE 'hybrid'
                END,
                2500 + (RANDOM() * 5000)::INTEGER, -- 2.5-7.5 seconds
                7.5 + (RANDOM() * 2.0), -- Overall score 7.5-9.5
                8.0 + (RANDOM() * 1.5), -- Coverage score 8.0-9.5
                6.8 + (RANDOM() * 2.7), -- Satisfaction score 6.8-9.5
                7.2 + (RANDOM() * 2.3), -- Cost efficiency 7.2-9.5
                75.0 + (RANDOM() * 20.0), -- Preference fulfillment 75-95%
                jsonb_build_object(
                    'schedule_type', 'optimized',
                    'shifts_generated', 35 + (RANDOM() * 20)::INTEGER,
                    'coverage_achieved', 95.0 + (RANDOM() * 5.0),
                    'constraints_satisfied', 98.0 + (RANDOM() * 2.0)
                ),
                jsonb_build_object(
                    'total_assignments', 30 + (RANDOM() * 15)::INTEGER,
                    'preference_accommodations', 25 + (RANDOM() * 15)::INTEGER,
                    'constraint_violations', (RANDOM() * 3)::INTEGER
                ),
                CASE WHEN RANDOM() > 0.7 THEN 
                    jsonb_build_array(
                        jsonb_build_object('date', optimization_date + 2, 'type', 'pre_holiday', 'adjustment', 'shortened_day'),
                        jsonb_build_object('date', optimization_date + 3, 'type', 'holiday', 'adjustment', 'minimal_staffing')
                    )
                ELSE '[]'::jsonb END,
                CASE 
                    WHEN RANDOM() > 0.8 THEN 'approved'
                    WHEN RANDOM() > 0.9 THEN 'rejected'
                    ELSE 'validated'
                END
            );
            
            result_counter := result_counter + 1;
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- RESOURCE ALLOCATION EXECUTION RESULTS
-- =============================================================================

-- Generate realistic resource allocation execution data
DO $$
DECLARE
    model_record RECORD;
    execution_date TIMESTAMP WITH TIME ZONE;
    exec_counter INTEGER := 1;
BEGIN
    FOR model_record IN 
        SELECT model_id, model_name_ru 
        FROM resource_allocation_models 
        WHERE is_active = true 
    LOOP
        -- Generate executions for the last 14 days
        FOR i IN 1..7 LOOP
            execution_date := CURRENT_TIMESTAMP - (i * INTERVAL '2 days');
            
            INSERT INTO resource_allocation_executions (
                execution_id, model_id, execution_date,
                target_period_start, target_period_end,
                employee_pool_size, total_demand_units, available_capacity_units,
                algorithm_configuration, actual_execution_time_ms,
                overall_quality_score, efficiency_score, satisfaction_score, 
                constraint_satisfaction_rate, preference_fulfillment_rate,
                resource_assignments, capacity_utilization, employee_allocations,
                holiday_adjustments, validation_status
            ) VALUES (
                'exec_' || exec_counter,
                model_record.model_id,
                execution_date,
                execution_date,
                execution_date + INTERVAL '7 days',
                CASE model_record.model_id
                    WHEN 'model_peak_season' THEN 50
                    ELSE 35
                END,
                8500.0 + (RANDOM() * 2000.0), -- Total demand units
                9000.0 + (RANDOM() * 1500.0), -- Available capacity
                jsonb_build_object(
                    'algorithm', 'multi_objective_optimization',
                    'timeout_ms', 300000,
                    'quality_target', 8.0,
                    'preference_weight', 0.3
                ),
                45000 + (RANDOM() * 120000)::INTEGER, -- 45s-165s execution time
                8.2 + (RANDOM() * 1.3), -- Quality score 8.2-9.5
                7.8 + (RANDOM() * 1.7), -- Efficiency 7.8-9.5
                7.5 + (RANDOM() * 2.0), -- Satisfaction 7.5-9.5
                95.0 + (RANDOM() * 4.5), -- Constraint satisfaction 95-99.5%
                78.0 + (RANDOM() * 17.0), -- Preference fulfillment 78-95%
                jsonb_build_object(
                    'skill_assignments', jsonb_build_object(
                        'customer_service', 25 + (RANDOM() * 10)::INTEGER,
                        'technical_support', 10 + (RANDOM() * 8)::INTEGER,
                        'sales', 8 + (RANDOM() * 6)::INTEGER
                    ),
                    'shift_assignments', jsonb_build_object(
                        'morning', 15 + (RANDOM() * 8)::INTEGER,
                        'day', 18 + (RANDOM() * 10)::INTEGER,
                        'evening', 12 + (RANDOM() * 6)::INTEGER,
                        'night', 8 + (RANDOM() * 4)::INTEGER
                    )
                ),
                jsonb_build_object(
                    'overall_utilization', 85.0 + (RANDOM() * 12.0),
                    'peak_utilization', 95.0 + (RANDOM() * 5.0),
                    'off_peak_utilization', 70.0 + (RANDOM() * 15.0)
                ),
                jsonb_build_object(
                    'total_employees', 45 + (RANDOM() * 10)::INTEGER,
                    'full_time_equivalent', 42.5 + (RANDOM() * 8.0),
                    'overtime_hours', 15.0 + (RANDOM() * 25.0)
                ),
                CASE WHEN RANDOM() > 0.6 THEN
                    jsonb_build_array(
                        jsonb_build_object(
                            'holiday_date', (execution_date + INTERVAL '3 days')::DATE,
                            'impact', 'reduced_capacity',
                            'adjustment', 'overtime_volunteers'
                        )
                    )
                ELSE '[]'::jsonb END,
                CASE 
                    WHEN RANDOM() > 0.85 THEN 'approved'
                    WHEN RANDOM() > 0.95 THEN 'rejected'
                    ELSE 'validated'
                END
            );
            
            exec_counter := exec_counter + 1;
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- SYSTEM INTEGRATION STATUS MONITORING
-- =============================================================================

-- Set up system integration monitoring for all components
INSERT INTO system_integration_status (
    integration_id, component_name, component_type, status, health_score,
    average_response_time_ms, success_rate, error_rate, throughput_per_hour,
    data_sync_status, depends_on_components, critical_path_component
) VALUES

-- Core System Components
('integration_calendar', 'Russian Production Calendar Service', 'calendar_integration', 
 'healthy', 9.2, 150.5, 99.8, 0.2, 1200.0, 'synchronized', 
 '["database", "xml_parser"]'::jsonb, true),

('integration_preferences', 'Employee Preference Engine', 'preference_engine',
 'healthy', 8.9, 275.3, 98.5, 1.5, 800.0, 'synchronized',
 '["database", "user_interface", "notification_service"]'::jsonb, true),

('integration_optimization', 'Schedule Optimization Engine', 'optimization_engine',
 'healthy', 9.1, 3250.8, 97.2, 2.8, 120.0, 'synchronized',
 '["preference_engine", "calendar_integration", "resource_allocator"]'::jsonb, true),

('integration_vacation', 'Vacation Calculator Service', 'vacation_calculator',
 'healthy', 9.5, 185.2, 99.5, 0.5, 600.0, 'synchronized',
 '["calendar_integration", "hr_system"]'::jsonb, false),

('integration_resource', 'Resource Allocation Engine', 'resource_allocator',
 'warning', 8.3, 4500.2, 95.8, 4.2, 80.0, 'partial',
 '["optimization_engine", "skill_database", "capacity_planner"]'::jsonb, true),

('integration_notifications', 'Notification Service', 'notification_service',
 'healthy', 8.7, 95.7, 99.1, 0.9, 2400.0, 'synchronized',
 '["preference_engine", "email_service", "sms_gateway"]'::jsonb, false);

-- =============================================================================
-- DEMO QUERIES AND VIEWS
-- =============================================================================

-- Demonstrate the system with sample queries
-- These can be run after the demo data is loaded

-- Show comprehensive vacation status for all employees
CREATE OR REPLACE VIEW demo_vacation_status AS
SELECT 
    e.full_name as "Сотрудник",
    e.department as "Отдел",
    evs.scheme_name_ru as "Схема отпусков",
    evc.total_entitlement_days as "Всего дней",
    evc.remaining_days as "Осталось дней",
    evc.holiday_extensions as "Праздничные продления",
    evc.bridge_days_added as "Дополнительные мостовые дни",
    CASE 
        WHEN evc.remaining_days <= 7 THEN '🔴 Критический остаток'
        WHEN evc.remaining_days <= 14 THEN '🟡 Низкий остаток'
        ELSE '🟢 Нормальный статус'
    END as "Статус отпуска"
FROM employees e
JOIN employee_vacation_calculations evc ON e.id = evc.employee_id
JOIN enhanced_vacation_schemes evs ON evc.scheme_id = evs.scheme_id
WHERE evc.calculation_year = 2025
ORDER BY evc.remaining_days ASC;

-- Show employee preference satisfaction analytics
CREATE OR REPLACE VIEW demo_preference_analytics AS
SELECT 
    e.full_name as "Сотрудник",
    e.department as "Отдел",
    COUNT(ep.id) as "Всего предпочтений",
    ROUND(AVG(ep.optimization_score), 2) as "Средняя удовлетворенность",
    ROUND(AVG(ep.flexibility_factor), 1) as "Средняя гибкость",
    COUNT(CASE WHEN ep.priority IN ('high', 'critical') THEN 1 END) as "Высокий приоритет",
    COUNT(CASE WHEN ep.optimization_score < ep.satisfaction_threshold THEN 1 END) as "Ниже порога"
FROM employees e
LEFT JOIN employee_integrated_preferences ep ON e.id = ep.employee_id 
    AND ep.status = 'active'
LEFT JOIN integrated_preference_types pt ON ep.type_id = pt.type_id
GROUP BY e.id, e.full_name, e.department
ORDER BY AVG(ep.optimization_score) DESC NULLS LAST;

-- Show schedule optimization performance
CREATE OR REPLACE VIEW demo_optimization_performance AS
SELECT 
    ast.template_name_ru as "Шаблон расписания",
    ast.primary_algorithm as "Алгоритм",
    COUNT(sor.id) as "Запусков оптимизации",
    ROUND(AVG(sor.execution_time_ms/1000.0), 2) as "Среднее время (сек)",
    ROUND(AVG(sor.overall_score), 2) as "Качество решения",
    ROUND(AVG(sor.satisfaction_score), 2) as "Удовлетворенность",
    ROUND(AVG(sor.preference_fulfillment_rate), 1) as "Выполнение предпочтений (%)",
    COUNT(CASE WHEN sor.validation_status = 'approved' THEN 1 END) as "Одобрено"
FROM advanced_schedule_templates ast
LEFT JOIN schedule_optimization_results sor ON ast.template_id = sor.template_id
WHERE ast.is_active = true
GROUP BY ast.template_id, ast.template_name_ru, ast.primary_algorithm
ORDER BY AVG(sor.overall_score) DESC NULLS LAST;

-- System health dashboard
CREATE OR REPLACE VIEW demo_system_health AS
SELECT 
    sis.component_name as "Компонент системы",
    sis.component_type as "Тип",
    CASE sis.status
        WHEN 'healthy' THEN '🟢 Здоров'
        WHEN 'warning' THEN '🟡 Предупреждение'
        WHEN 'error' THEN '🔴 Ошибка'
        ELSE '⚪ Неизвестно'
    END as "Статус",
    sis.health_score as "Оценка здоровья",
    ROUND(sis.average_response_time_ms, 2) as "Время отклика (мс)",
    ROUND(sis.success_rate, 2) as "Успешность (%)",
    sis.data_sync_status as "Синхронизация данных",
    sis.critical_path_component as "Критический компонент"
FROM system_integration_status sis
ORDER BY sis.critical_path_component DESC, sis.health_score DESC;

-- =============================================================================
-- FINAL SUCCESS MESSAGE
-- =============================================================================

-- Show successful completion with statistics
DO $$
DECLARE
    employee_count INTEGER;
    preference_count INTEGER;
    vacation_calc_count INTEGER;
    template_count INTEGER;
    optimization_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO employee_count FROM employees WHERE is_active = true;
    SELECT COUNT(*) INTO preference_count FROM employee_integrated_preferences WHERE status = 'active';
    SELECT COUNT(*) INTO vacation_calc_count FROM employee_vacation_calculations WHERE calculation_year = 2025;
    SELECT COUNT(*) INTO template_count FROM advanced_schedule_templates WHERE is_active = true;
    SELECT COUNT(*) INTO optimization_count FROM schedule_optimization_results;
    
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'ДЕМОНСТРАЦИОННЫЕ ДАННЫЕ УСПЕШНО ЗАГРУЖЕНЫ';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Компания: ООО "ТехноСервис Плюс" - Интегрированная система управления персоналом';
    RAISE NOTICE '';
    RAISE NOTICE 'Загружено данных:';
    RAISE NOTICE '  👥 Сотрудников: %', employee_count;
    RAISE NOTICE '  ⚙️ Предпочтений сотрудников: %', preference_count;
    RAISE NOTICE '  🏖️ Расчетов отпусков: %', vacation_calc_count;
    RAISE NOTICE '  📋 Шаблонов расписания: %', template_count;
    RAISE NOTICE '  🔧 Результатов оптимизации: %', optimization_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Интегрированные функции:';
    RAISE NOTICE '  ✅ Российский производственный календарь на 2025 год';
    RAISE NOTICE '  ✅ Автоматические продления отпусков на праздники';
    RAISE NOTICE '  ✅ Многоуровневая система предпочтений сотрудников';
    RAISE NOTICE '  ✅ Оптимизация расписаний с учетом предпочтений';
    RAISE NOTICE '  ✅ Распределение ресурсов с учетом навыков';
    RAISE NOTICE '  ✅ Мониторинг интеграции системы';
    RAISE NOTICE '';
    RAISE NOTICE 'Доступные демонстрационные представления:';
    RAISE NOTICE '  📊 demo_vacation_status - Статус отпусков сотрудников';
    RAISE NOTICE '  📈 demo_preference_analytics - Аналитика предпочтений';
    RAISE NOTICE '  ⚡ demo_optimization_performance - Производительность оптимизации';
    RAISE NOTICE '  💚 demo_system_health - Здоровье системы';
    RAISE NOTICE '============================================================================';
END $$;