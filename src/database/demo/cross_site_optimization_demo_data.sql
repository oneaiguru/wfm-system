-- =====================================================
-- Cross-Site Advanced Schedule Optimization Demo Data
-- =====================================================
-- Comprehensive test data with Russian language support
-- Demonstrates the most complex BDD scenarios:
-- - Multi-site location hierarchy
-- - Advanced scheduling optimization
-- - Cross-site workforce coordination
-- - Genetic algorithm components
-- - Real-time performance monitoring
-- =====================================================

-- Clear existing demo data (if any)
TRUNCATE TABLE genetic_chromosomes CASCADE;
TRUNCATE TABLE genetic_algorithm_populations CASCADE;
TRUNCATE TABLE schedule_optimization_suggestions CASCADE;
TRUNCATE TABLE schedule_optimization_jobs CASCADE;
TRUNCATE TABLE optimization_performance_metrics CASCADE;
TRUNCATE TABLE cross_site_coordination CASCADE;
TRUNCATE TABLE rule_violations CASCADE;
TRUNCATE TABLE optimization_business_rules CASCADE;
TRUNCATE TABLE ml_optimization_features CASCADE;
TRUNCATE TABLE location_configurations CASCADE;
TRUNCATE TABLE location_hierarchy CASCADE;
TRUNCATE TABLE locations CASCADE;

-- ==========================================
-- LOCATION HIERARCHY DATA
-- ==========================================

-- Insert Russian enterprise location hierarchy
INSERT INTO locations (
    location_code, location_name_ru, location_name_en, parent_location_id,
    timezone, capacity, cost_per_hour, operating_hours_start, operating_hours_end,
    min_coverage_percent, max_overtime_percent, shift_pattern_type
) VALUES
-- Corporate headquarters
('RU_HQ', 'Россия - Головной офис', 'Russia - Corporate Headquarters', NULL, 
 'Europe/Moscow', 500, 2000.00, '00:00', '23:59', 95, 10, 'continental'),

-- Regional centers
('MSK_REG', 'Московский регион', 'Moscow Region', 1, 
 'Europe/Moscow', 300, 1800.00, '06:00', '22:00', 90, 12, 'dupont'),
 
('SPB_REG', 'Санкт-Петербургский регион', 'St. Petersburg Region', 1, 
 'Europe/Moscow', 250, 1600.00, '06:00', '22:00', 88, 12, 'rotating_shifts'),
 
('URA_REG', 'Уральский регион', 'Ural Region', 1, 
 'Asia/Yekaterinburg', 200, 1400.00, '07:00', '21:00', 85, 15, 'flexible'),
 
('SIB_REG', 'Сибирский регион', 'Siberian Region', 1, 
 'Asia/Novosibirsk', 180, 1300.00, '08:00', '20:00', 82, 15, 'compressed_work'),
 
('FE_REG', 'Дальневосточный регион', 'Far East Region', 1, 
 'Asia/Vladivostok', 150, 1200.00, '09:00', '19:00', 80, 18, 'follow_the_sun'),

-- Moscow sub-locations
('MSK_CC1', 'Москва ЦОВ-1 (Сокольники)', 'Moscow Call Center 1 (Sokolniki)', 2, 
 'Europe/Moscow', 150, 1750.00, '06:00', '22:00', 92, 10, 'dupont'),
 
('MSK_CC2', 'Москва ЦОВ-2 (Митино)', 'Moscow Call Center 2 (Mitino)', 2, 
 'Europe/Moscow', 120, 1700.00, '07:00', '21:00', 90, 12, 'rotating_shifts'),
 
('MSK_BO', 'Москва Бэк-офис (Белая Площадь)', 'Moscow Back Office (Belaya Ploshchad)', 2, 
 'Europe/Moscow', 80, 1900.00, '09:00', '18:00', 85, 8, 'compressed_work'),

-- St. Petersburg sub-locations
('SPB_CC1', 'СПб ЦОВ-1 (Центральный)', 'SPb Call Center 1 (Central)', 3, 
 'Europe/Moscow', 100, 1550.00, '06:00', '22:00', 88, 12, 'continental'),
 
('SPB_CC2', 'СПб ЦОВ-2 (Московский)', 'SPb Call Center 2 (Moskovsky)', 3, 
 'Europe/Moscow', 90, 1500.00, '08:00', '20:00', 85, 15, 'flexible'),

-- Regional centers
('EKB_CC', 'Екатеринбург ЦОВ', 'Yekaterinburg Call Center', 4, 
 'Asia/Yekaterinburg', 120, 1350.00, '07:00', '21:00', 83, 15, 'rotating_shifts'),
 
('NSK_CC', 'Новосибирск ЦОВ', 'Novosibirsk Call Center', 5, 
 'Asia/Novosibirsk', 100, 1250.00, '08:00', '20:00', 80, 18, 'flexible'),
 
('VLK_CC', 'Владивосток ЦОВ', 'Vladivostok Call Center', 6, 
 'Asia/Vladivostok', 80, 1150.00, '09:00', '19:00', 78, 20, 'follow_the_sun'),

-- Specialized departments
('MSK_TEC', 'Москва Техподдержка', 'Moscow Technical Support', 2, 
 'Europe/Moscow', 60, 2200.00, '00:00', '23:59', 95, 5, 'continental'),
 
('SPB_TEC', 'СПб Техподдержка', 'SPb Technical Support', 3, 
 'Europe/Moscow', 40, 2100.00, '06:00', '22:00', 90, 8, 'dupont');

-- ==========================================
-- LOCATION CONFIGURATIONS
-- ==========================================

-- Moscow region configurations
INSERT INTO location_configurations (location_id, parameter_name, parameter_value, parameter_type) VALUES
(2, 'service_level_target', '82.5', 'number'),
(2, 'average_handle_time', '180', 'number'),
(2, 'shrinkage_factor', '0.25', 'number'),
(2, 'erlang_c_enhanced', 'true', 'boolean'),
(2, 'genetic_algorithm_enabled', 'true', 'boolean'),
(2, 'cross_site_sharing_enabled', 'true', 'boolean'),
(2, 'skill_requirements', '{"customer_service": 4, "technical_support": 3, "sales": 2}', 'json'),
(2, 'language_requirements', '["ru", "en"]', 'json'),
(2, 'holiday_calendar', 'ru_federal', 'string'),
(2, 'union_agreement_code', 'MSK_CBA_2024', 'string');

-- St. Petersburg configurations
INSERT INTO location_configurations (location_id, parameter_name, parameter_value, parameter_type) VALUES
(3, 'service_level_target', '80.0', 'number'),
(3, 'average_handle_time', '165', 'number'),
(3, 'shrinkage_factor', '0.22', 'number'),
(3, 'genetic_algorithm_enabled', 'true', 'boolean'),
(3, 'cross_site_sharing_enabled', 'true', 'boolean'),
(3, 'skill_requirements', '{"customer_service": 4, "technical_support": 2}', 'json'),
(3, 'language_requirements', '["ru"]', 'json'),
(3, 'holiday_calendar', 'ru_federal', 'string');

-- Regional configurations
INSERT INTO location_configurations (location_id, parameter_name, parameter_value, parameter_type) VALUES
(4, 'service_level_target', '78.0', 'number'),
(4, 'cross_site_sharing_enabled', 'true', 'boolean'),
(5, 'service_level_target', '75.0', 'number'),
(5, 'cross_site_sharing_enabled', 'true', 'boolean'),
(6, 'service_level_target', '72.0', 'number'),
(6, 'cross_site_sharing_enabled', 'true', 'boolean');

-- ==========================================
-- OPTIMIZATION BUSINESS RULES
-- ==========================================

-- Russian Federal Labor Law Rules
INSERT INTO optimization_business_rules (
    rule_name, rule_category, rule_type, rule_expression, 
    rule_description_ru, rule_description_en, enforcement_level, penalty_weight
) VALUES
('Максимальные рабочие часы в неделю (ТК РФ)', 'labor_law', 'constraint',
 '{"max_weekly_hours": 40, "operator": "<=", "article": "91_TC_RF"}',
 'Нормальная продолжительность рабочего времени не может превышать 40 часов в неделю (ст. 91 ТК РФ)',
 'Normal working hours cannot exceed 40 hours per week (Article 91 Labor Code of RF)',
 'mandatory', 1000.0),

('Минимальный ежедневный отдых (ТК РФ)', 'labor_law', 'constraint',
 '{"min_daily_rest_hours": 11, "operator": ">=", "article": "108_TC_RF"}',
 'Время отдыха между рабочими днями должно составлять не менее 11 часов (ст. 108 ТК РФ)',
 'Rest time between work days must be at least 11 hours (Article 108 Labor Code of RF)',
 'mandatory', 1000.0),

('Максимальная продолжительность сверхурочной работы', 'labor_law', 'constraint',
 '{"max_overtime_hours_year": 120, "max_overtime_hours_2days": 4, "operator": "<="}',
 'Сверхурочные работы не должны превышать для каждого работника 4 часов в течение двух дней подряд и 120 часов в год',
 'Overtime work should not exceed 4 hours within two consecutive days and 120 hours per year for each employee',
 'mandatory', 800.0),

('Еженедельный непрерывный отдых', 'labor_law', 'constraint',
 '{"min_weekly_rest_hours": 42, "operator": ">="}',
 'Продолжительность еженедельного непрерывного отдыха не может быть менее 42 часов',
 'Duration of weekly continuous rest cannot be less than 42 hours',
 'mandatory', 900.0);

-- Business Policy Rules
INSERT INTO optimization_business_rules (
    rule_name, rule_category, rule_type, rule_expression,
    rule_description_ru, rule_description_en, enforcement_level, penalty_weight
) VALUES
('Обязательное покрытие пиковых часов', 'business_policy', 'requirement',
 '{"peak_hours": [{"start": "10:00", "end": "12:00"}, {"start": "14:00", "end": "16:00"}], "min_coverage_percent": 90}',
 'Обязательное покрытие 90% агентов в пиковые часы: 10:00-12:00 и 14:00-16:00',
 'Mandatory 90% agent coverage during peak hours: 10:00-12:00 and 14:00-16:00',
 'strong', 500.0),

('Предпочтение утренних смен', 'business_policy', 'preference',
 '{"preferred_start_times": ["08:00", "09:00"], "weight": 0.7}',
 'Предпочтение отдается утренним сменам с началом в 8:00 или 9:00',
 'Preference given to morning shifts starting at 8:00 or 9:00',
 'preferred', 200.0),

('Минимальное количество технических специалистов', 'business_policy', 'requirement',
 '{"skill_type": "technical_support", "min_agents_per_shift": 2, "shift_hours": ["09:00-18:00"]}',
 'В каждой смене должно быть минимум 2 технических специалиста в рабочие часы',
 'Each shift must have minimum 2 technical specialists during business hours',
 'strong', 400.0),

('Балансировка нагрузки между офисами', 'business_policy', 'preference',
 '{"max_utilization_difference": 15, "cross_site_balancing": true}',
 'Разница в загрузке между офисами не должна превышать 15%',
 'Workload difference between offices should not exceed 15%',
 'preferred', 300.0);

-- Union Agreement Rules (Moscow)
INSERT INTO optimization_business_rules (
    rule_name, rule_category, rule_type, rule_expression,
    rule_description_ru, rule_description_en, enforcement_level, penalty_weight,
    location_ids
) VALUES
('Коллективный договор - ночные смены', 'union_agreement', 'constraint',
 '{"night_shift_start": "22:00", "night_shift_end": "06:00", "max_consecutive_nights": 2, "night_premium": 0.4}',
 'По коллективному договору: не более 2 ночных смен подряд, доплата 40%',
 'Union agreement: maximum 2 consecutive night shifts, 40% night premium',
 'mandatory', 700.0, ARRAY[2]),

('Коллективный договор - выходные дни', 'union_agreement', 'constraint',
 '{"weekend_premium": 0.5, "max_weekend_shifts_month": 8}',
 'Работа в выходные: доплата 50%, не более 8 смен в месяц',
 'Weekend work: 50% premium, maximum 8 shifts per month',
 'mandatory', 600.0, ARRAY[2, 3]);

-- ==========================================
-- SCHEDULE OPTIMIZATION JOBS
-- ==========================================

-- Create sample optimization jobs
INSERT INTO schedule_optimization_jobs (
    job_name, location_id, start_date, end_date, optimization_goals, constraints,
    algorithm_type, status, progress_percent, processing_start, processing_end,
    processing_time_seconds, suggestions_generated, best_score, coverage_improvement_percent,
    cost_impact_weekly, created_by
) VALUES
('Комплексная оптимизация Москва Q1 2024', 2, '2024-01-01', '2024-03-31',
 '{"coverage": 40, "cost": 30, "satisfaction": 20, "complexity": 10}'::jsonb,
 '{"maxOvertimePercent": 10, "minRestHours": 11, "skillRequirements": {"customer_service": 4}}'::jsonb,
 'genetic', 'completed', 100, '2024-01-15 09:00:00', '2024-01-15 09:08:45', 525, 12, 94.2, 18.5, -12400.0, 1),

('Межрегиональная координация СПб-Москва', 3, '2024-02-01', '2024-02-29',
 '{"coverage": 35, "cost": 35, "satisfaction": 20, "complexity": 10}'::jsonb,
 '{"maxOvertimePercent": 12, "crossSiteSharing": true}'::jsonb,
 'hybrid', 'completed', 100, '2024-02-05 14:30:00', '2024-02-05 14:37:20', 440, 8, 89.7, 14.2, -8900.0, 1),

('Уральский регион - пиковые нагрузки', 4, '2024-03-01', '2024-03-31',
 '{"coverage": 50, "cost": 25, "satisfaction": 15, "complexity": 10}'::jsonb,
 '{"maxOvertimePercent": 15, "peakHourCoverage": 95}'::jsonb,
 'ml_enhanced', 'running', 65, '2024-03-10 10:15:00', NULL, NULL, 0, NULL, NULL, NULL, 1),

('Дальневосточный регион - следование за солнцем', 6, '2024-04-01', '2024-06-30',
 '{"coverage": 45, "cost": 30, "satisfaction": 25, "complexity": 0}'::jsonb,
 '{"timezoneOptimization": true, "followTheSun": true}'::jsonb,
 'genetic', 'pending', 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, 1);

-- ==========================================
-- OPTIMIZATION SUGGESTIONS
-- ==========================================

-- Moscow optimization suggestions
INSERT INTO schedule_optimization_suggestions (
    job_id, rank, total_score, coverage_score, cost_score, compliance_score, simplicity_score,
    coverage_improvement_percent, cost_impact_weekly, overtime_reduction_percent,
    skill_match_percent, preference_match_percent, pattern_type,
    pattern_description_ru, pattern_description_en, risk_level, implementation_complexity,
    estimated_implementation_weeks, validation_passed, validation_issues, schedule_data
) VALUES
(1, 1, 94.2, 37.5, 28.5, 19.6, 8.6, 18.5, -12400.0, 66.0, 95.0, 78.0, 'dupont_enhanced',
 'Расширенная ДюПон система с генетической оптимизацией: покрытие +18.5%, экономия 12,400₽/неделя, соответствие навыкам 95%',
 'Enhanced DuPont system with genetic optimization: +18.5% coverage, 12,400₽/week savings, 95% skill match',
 'low', 'medium', 3, TRUE, '[]'::jsonb,
 '{"total_shifts": 168, "agents_involved": 42, "pattern_complexity": "medium", "cross_site_coordination": false}'::jsonb),

(1, 2, 91.8, 35.2, 27.8, 19.4, 9.4, 16.2, -8900.0, 58.0, 92.0, 82.0, 'continental_flex',
 'Континентальная система с гибкими интервалами: покрытие +16.2%, экономия 8,900₽/неделя, высокое удовлетворение агентов',
 'Continental system with flexible intervals: +16.2% coverage, 8,900₽/week savings, high agent satisfaction',
 'low', 'simple', 2, TRUE, '[]'::jsonb,
 '{"total_shifts": 156, "agents_involved": 38, "pattern_complexity": "simple", "cross_site_coordination": false}'::jsonb),

(1, 3, 89.5, 32.8, 26.1, 19.8, 10.8, 14.7, -6200.0, 52.0, 88.0, 85.0, 'rotating_optimized',
 'Оптимизированная ротационная система: покрытие +14.7%, экономия 6,200₽/неделя, максимальное соответствие предпочтениям',
 'Optimized rotating system: +14.7% coverage, 6,200₽/week savings, maximum preference matching',
 'low', 'simple', 2, TRUE, '[]'::jsonb,
 '{"total_shifts": 152, "agents_involved": 36, "pattern_complexity": "simple", "cross_site_coordination": false}'::jsonb);

-- St. Petersburg - Moscow coordination suggestions
INSERT INTO schedule_optimization_suggestions (
    job_id, rank, total_score, coverage_score, cost_score, compliance_score, simplicity_score,
    coverage_improvement_percent, cost_impact_weekly, overtime_reduction_percent,
    skill_match_percent, preference_match_percent, pattern_type,
    pattern_description_ru, pattern_description_en, risk_level, implementation_complexity,
    estimated_implementation_weeks, validation_passed, validation_issues, schedule_data
) VALUES
(2, 1, 89.7, 31.2, 31.5, 18.0, 9.0, 14.2, -8900.0, 45.0, 90.0, 72.0, 'cross_site_coordination',
 'Межрегиональная координация СПб-Москва: обмен ресурсами в пиковые часы, экономия на межрегиональных различиях в стоимости',
 'Inter-regional SPb-Moscow coordination: resource sharing during peak hours, savings from regional cost differences',
 'medium', 'complex', 4, TRUE, 
 '[{"type": "timezone_complexity", "severity": "medium", "description": "Требуется координация часовых поясов"}]'::jsonb,
 '{"total_shifts": 284, "agents_involved": 67, "cross_site_coordination": true, "timezone_impact": "minimal"}'::jsonb),

(2, 2, 87.3, 29.8, 30.2, 18.5, 8.8, 12.8, -7200.0, 42.0, 87.0, 75.0, 'hybrid_patterns',
 'Гибридные паттерны с адаптивным распределением: различные схемы для Москвы (ДюПон) и СПб (континентальная)',
 'Hybrid patterns with adaptive distribution: different schemes for Moscow (DuPont) and SPb (continental)',
 'medium', 'medium', 3, TRUE, '[]'::jsonb,
 '{"total_shifts": 267, "agents_involved": 61, "cross_site_coordination": true}'::jsonb);

-- ==========================================
-- GENETIC ALGORITHM DATA
-- ==========================================

-- Population tracking for Moscow optimization
INSERT INTO genetic_algorithm_populations (
    job_id, generation, population_size, fitness_average, fitness_best, fitness_worst,
    diversity_score, mutation_rate, crossover_rate, selection_pressure, processing_time_ms, convergence_indicator
) VALUES
(1, 0, 100, 45.2, 67.8, 23.1, 0.85, 0.01, 0.8, 1.2, 2340, 1.0),
(1, 5, 100, 62.4, 78.9, 41.2, 0.78, 0.01, 0.8, 1.2, 2180, 0.82),
(1, 10, 100, 74.6, 85.3, 58.7, 0.71, 0.01, 0.8, 1.2, 2020, 0.65),
(1, 15, 100, 82.1, 89.7, 67.4, 0.64, 0.01, 0.8, 1.2, 1890, 0.48),
(1, 20, 100, 87.3, 92.4, 75.8, 0.58, 0.01, 0.8, 1.2, 1760, 0.32),
(1, 25, 100, 90.8, 94.2, 82.1, 0.52, 0.01, 0.8, 1.2, 1650, 0.18),
(1, 30, 100, 92.6, 94.2, 87.4, 0.45, 0.01, 0.8, 1.2, 1540, 0.08);

-- Sample chromosomes for best generation
INSERT INTO genetic_chromosomes (
    population_id, chromosome_index, genes, fitness_score, coverage_fitness, cost_fitness,
    constraint_fitness, preference_fitness, mutation_applied, crossover_point
) VALUES
(7, 1, 
 '{"schedule_pattern": "dupont_enhanced", "coverage_target": 92.5, "cost_optimization_weight": 0.75, "preference_weight": 0.35, "shift_patterns": [{"start": "08:00", "end": "16:00"}, {"start": "16:00", "end": "24:00"}]}'::jsonb,
 94.2, 37.5, 28.5, 19.6, 8.6, FALSE, NULL),
(7, 2,
 '{"schedule_pattern": "continental_flex", "coverage_target": 89.8, "cost_optimization_weight": 0.68, "preference_weight": 0.42, "shift_patterns": [{"start": "09:00", "end": "17:00"}, {"start": "17:00", "end": "01:00"}]}'::jsonb,
 91.8, 35.2, 27.8, 19.4, 9.4, TRUE, 15);

-- ==========================================
-- CROSS-SITE COORDINATION
-- ==========================================

-- Resource sharing examples
INSERT INTO cross_site_coordination (
    source_location_id, target_location_id, coordination_type, start_datetime, end_datetime,
    agents_required, skills_required, cost_per_hour, travel_time_minutes, status,
    service_level_impact_percent, cost_impact, customer_satisfaction_impact,
    approved_by, approved_at, created_by
) VALUES
-- Moscow helping St. Petersburg during peak load
(7, 10, 'resource_sharing', '2024-03-15 10:00:00', '2024-03-15 16:00:00',
 5, '{"customer_service": 4, "technical_support": 3}'::jsonb, 1650.0, 0, 'completed',
 12.5, -3200.0, 8.5, 1, '2024-03-14 16:30:00', 1),

-- St. Petersburg providing night coverage for Moscow
(10, 7, 'coverage_support', '2024-03-16 22:00:00', '2024-03-17 06:00:00',
 3, '{"customer_service": 4}'::jsonb, 1850.0, 0, 'completed',
 8.7, -1400.0, 6.2, 1, '2024-03-16 14:15:00', 1),

-- Emergency backup from Yekaterinburg
(12, 7, 'emergency_backup', '2024-03-18 14:30:00', '2024-03-18 20:00:00',
 8, '{"customer_service": 3, "technical_support": 2}'::jsonb, 1350.0, 240, 'active',
 15.2, -4800.0, 12.0, 1, '2024-03-18 13:45:00', 1),

-- Skill exchange between regions
(12, 13, 'skill_exchange', '2024-04-01 09:00:00', '2024-04-30 18:00:00',
 2, '{"technical_support": 5, "system_administration": 4}'::jsonb, 1400.0, 360, 'approved',
 5.5, -2800.0, 3.2, 1, '2024-03-25 11:20:00', 1);

-- ==========================================
-- PERFORMANCE METRICS
-- ==========================================

-- Moscow performance tracking
INSERT INTO optimization_performance_metrics (
    location_id, job_id, measurement_timestamp, measurement_period_minutes,
    coverage_actual_percent, coverage_target_percent, service_level_actual, service_level_target,
    labor_cost_actual, labor_cost_budgeted, overtime_hours_actual, overtime_hours_planned,
    agent_satisfaction_score, customer_satisfaction_score, compliance_score_percent,
    utilization_rate_percent, idle_time_minutes, break_adherence_percent, schedule_adherence_percent,
    optimization_accuracy_percent, algorithm_processing_time_seconds, suggestion_acceptance_rate
) VALUES
-- Morning performance
(2, 1, '2024-03-20 09:00:00', 60, 94.2, 90.0, 85.7, 82.5, 87500.0, 92000.0, 2.5, 4.8, 8.1, 8.4, 98.5,
 91.2, 12, 96.8, 94.2, 89.5, 8, 85.0),

-- Peak hour performance
(2, 1, '2024-03-20 11:00:00', 60, 96.8, 95.0, 88.2, 82.5, 105200.0, 98000.0, 3.2, 4.8, 7.9, 8.6, 97.8,
 94.5, 8, 98.2, 95.8, 91.2, 12, 88.0),

-- Afternoon performance
(2, 1, '2024-03-20 15:00:00', 60, 92.1, 90.0, 84.3, 82.5, 91200.0, 89000.0, 2.1, 4.8, 8.3, 8.2, 99.1,
 89.7, 18, 95.4, 92.6, 87.8, 9, 82.0),

-- Evening performance
(2, 1, '2024-03-20 19:00:00', 60, 88.5, 85.0, 81.9, 82.5, 78300.0, 82000.0, 1.8, 4.8, 8.0, 7.8, 98.9,
 86.3, 25, 94.1, 89.7, 85.2, 7, 78.0);

-- St. Petersburg performance tracking
INSERT INTO optimization_performance_metrics (
    location_id, job_id, measurement_timestamp, measurement_period_minutes,
    coverage_actual_percent, coverage_target_percent, service_level_actual, service_level_target,
    labor_cost_actual, labor_cost_budgeted, overtime_hours_actual, overtime_hours_planned,
    agent_satisfaction_score, customer_satisfaction_score, compliance_score_percent,
    utilization_rate_percent, idle_time_minutes, break_adherence_percent, schedule_adherence_percent,
    optimization_accuracy_percent, algorithm_processing_time_seconds, suggestion_acceptance_rate
) VALUES
(3, 2, '2024-03-20 10:00:00', 60, 87.2, 85.0, 82.1, 80.0, 62500.0, 68000.0, 1.8, 3.2, 7.8, 8.1, 97.2,
 88.4, 15, 94.5, 91.3, 84.7, 6, 79.0),

(3, 2, '2024-03-20 14:00:00', 60, 89.8, 88.0, 83.5, 80.0, 71200.0, 73000.0, 2.2, 3.2, 8.0, 8.3, 98.1,
 90.8, 12, 96.1, 93.7, 86.9, 8, 82.0);

-- ==========================================
-- MACHINE LEARNING FEATURES
-- ==========================================

-- Moscow ML features for optimization
INSERT INTO ml_optimization_features (
    location_id, feature_date, feature_hour, day_of_week, is_holiday,
    historical_coverage_avg, historical_service_level_avg, historical_cost_per_hour,
    historical_agent_satisfaction, call_volume_predicted, aht_predicted_seconds,
    skill_mix_required, special_events, weather_impact_score, seasonal_adjustment_factor,
    actual_coverage_percent, actual_service_level, actual_cost, optimization_success_score
) VALUES
-- Monday morning peak
(2, '2024-03-18', 9, 1, FALSE, 92.5, 84.2, 1750.0, 8.1, 285, 178,
 '{"customer_service": 15, "technical_support": 8, "sales": 3}'::jsonb,
 '["new_product_launch", "marketing_campaign"]'::jsonb, 7.5, 1.05,
 94.2, 85.7, 1720.0, 91.5),

-- Monday lunch dip
(2, '2024-03-18', 13, 1, FALSE, 78.2, 79.8, 1650.0, 7.9, 195, 165,
 '{"customer_service": 10, "technical_support": 4, "sales": 2}'::jsonb,
 '[]'::jsonb, 7.5, 1.05,
 82.1, 81.2, 1680.0, 86.3),

-- Tuesday peak
(2, '2024-03-19', 11, 2, FALSE, 94.8, 86.1, 1780.0, 8.0, 312, 182,
 '{"customer_service": 18, "technical_support": 10, "sales": 4}'::jsonb,
 '["system_maintenance"]'::jsonb, 6.8, 1.02,
 96.8, 88.2, 1740.0, 93.2);

-- St. Petersburg features
INSERT INTO ml_optimization_features (
    location_id, feature_date, feature_hour, day_of_week, is_holiday,
    historical_coverage_avg, historical_service_level_avg, historical_cost_per_hour,
    historical_agent_satisfaction, call_volume_predicted, aht_predicted_seconds,
    skill_mix_required, special_events, weather_impact_score, seasonal_adjustment_factor,
    actual_coverage_percent, actual_service_level, actual_cost, optimization_success_score
) VALUES
(3, '2024-03-18', 10, 1, FALSE, 86.8, 81.5, 1550.0, 7.8, 198, 162,
 '{"customer_service": 12, "technical_support": 5}'::jsonb,
 '[]'::jsonb, 8.2, 0.98,
 87.2, 82.1, 1520.0, 88.7),

(3, '2024-03-19', 14, 2, FALSE, 89.2, 83.2, 1580.0, 8.1, 231, 171,
 '{"customer_service": 14, "technical_support": 6}'::jsonb,
 '["regional_event"]'::jsonb, 7.9, 0.99,
 89.8, 83.5, 1565.0, 90.1);

-- ==========================================
-- RULE VIOLATIONS TRACKING
-- ==========================================

-- Sample violations for learning
INSERT INTO rule_violations (
    rule_id, job_id, suggestion_id, violation_type, violation_severity,
    violation_description_ru, violation_description_en, affected_agents,
    affected_time_periods, violation_impact, resolution_status, resolution_action
) VALUES
(2, 1, NULL, 'min_rest_period', 'medium',
 'Агент #1047: только 10.5 часов отдыха между сменами (требуется 11 часов)',
 'Agent #1047: only 10.5 hours rest between shifts (11 hours required)',
 ARRAY[1047], 
 '[{"date": "2024-03-18", "shift1_end": "22:00", "shift2_start": "08:30"}]'::jsonb,
 '{"fatigue_risk": "medium", "performance_impact": "low", "legal_risk": "medium"}'::jsonb,
 'resolved', 'Смена перенесена на 30 минут позже'),

(1, 1, NULL, 'max_weekly_hours', 'high',
 'Агент #1023: 42.5 часа в неделю превышает лимит 40 часов',
 'Agent #1023: 42.5 hours per week exceeds 40 hour limit',
 ARRAY[1023],
 '[{"week": "2024-03-11", "total_hours": 42.5, "overtime": 2.5}]'::jsonb,
 '{"legal_risk": "high", "cost_impact": 850.0, "compliance_risk": "critical"}'::jsonb,
 'resolved', 'Сверхурочные часы перераспределены между агентами'),

(5, 2, NULL, 'peak_coverage', 'medium',
 'Покрытие 87% в пиковые часы 14:00-16:00 ниже требуемых 90%',
 'Coverage 87% during peak hours 14:00-16:00 below required 90%',
 ARRAY[2001, 2002, 2003],
 '[{"date": "2024-02-15", "period": "14:00-16:00", "coverage": 87, "required": 90}]'::jsonb,
 '{"service_level_risk": "medium", "customer_satisfaction_impact": "low"}'::jsonb,
 'investigating', 'Анализ возможности межрегионального обмена ресурсами');

-- ==========================================
-- ANALYTICS SUMMARY
-- ==========================================

-- Weekly summary for Moscow region
INSERT INTO optimization_analytics_summary (
    aggregation_level, location_ids, period_start, period_end, period_type,
    avg_coverage_percent, avg_service_level, total_cost, cost_savings_vs_budget,
    optimization_jobs_completed, suggestions_implemented, avg_suggestion_score,
    avg_implementation_success_rate, coverage_trend, cost_trend, satisfaction_trend,
    optimization_investment, savings_realized, roi_percent, payback_period_months,
    key_insights, recommended_actions
) VALUES
('region', ARRAY[2, 7, 8, 9], '2024-03-11', '2024-03-17', 'weekly',
 91.8, 84.5, 1247500.0, 87200.0, 1, 3, 91.9, 88.5, 'improving', 'improving', 'stable',
 15000.0, 87200.0, 581.3, 0.2,
 '[
   {"type": "coverage", "insight": "Genetic algorithm показал 18.5% улучшение покрытия", "confidence": 0.95},
   {"type": "cost", "insight": "Межрегиональная координация дает экономию 12,400₽/неделя", "confidence": 0.87},
   {"type": "satisfaction", "insight": "Агенты предпочитают гибридные паттерны (+15% удовлетворенность)", "confidence": 0.82}
 ]'::jsonb,
 '[
   {"priority": "high", "action": "Внедрить генетический алгоритм в производство", "timeline": "2 weeks"},
   {"priority": "medium", "action": "Расширить межрегиональную координацию на Урал", "timeline": "1 month"},
   {"priority": "low", "action": "Изучить применение ML для прогнозирования нагрузки", "timeline": "3 months"}
 ]'::jsonb);

-- Monthly summary for enterprise level
INSERT INTO optimization_analytics_summary (
    aggregation_level, location_ids, period_start, period_end, period_type,
    avg_coverage_percent, avg_service_level, total_cost, cost_savings_vs_budget,
    optimization_jobs_completed, suggestions_implemented, avg_suggestion_score,
    avg_implementation_success_rate, coverage_trend, cost_trend, satisfaction_trend,
    optimization_investment, savings_realized, roi_percent, payback_period_months,
    key_insights, recommended_actions
) VALUES
('enterprise', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16], '2024-03-01', '2024-03-31', 'monthly',
 87.2, 81.8, 4892300.0, 156800.0, 3, 8, 89.1, 85.2, 'improving', 'stable', 'improving',
 45000.0, 245600.0, 545.8, 0.2,
 '[
   {"type": "regional", "insight": "Московский регион лидирует по внедрению оптимизации", "confidence": 0.92},
   {"type": "algorithm", "insight": "Генетические алгоритмы превосходят линейные на 23%", "confidence": 0.89},
   {"type": "coordination", "insight": "Межрегиональная координация экономит 15-20% на издержках", "confidence": 0.85}
 ]'::jsonb,
 '[
   {"priority": "critical", "action": "Масштабировать генетическую оптимизацию на все регионы", "timeline": "6 weeks"},
   {"priority": "high", "action": "Создать центр межрегиональной координации", "timeline": "8 weeks"},
   {"priority": "medium", "action": "Внедрить ML прогнозирование для сезонных паттернов", "timeline": "12 weeks"}
 ]'::jsonb);

-- ==========================================
-- SYNC EVENTS
-- ==========================================

-- Cross-site synchronization events
INSERT INTO schedule_sync_events (
    sync_type, affected_locations, event_type, event_data, event_timestamp,
    processed_at, processing_time_ms, conflicts_detected, conflict_resolution_method,
    status, sync_result
) VALUES
('real_time', ARRAY[2,3], 'resource_sharing_request',
 '{"source": 2, "target": 3, "agents_needed": 5, "time_period": "14:00-18:00", "skills": ["customer_service"]}'::jsonb,
 '2024-03-20 13:45:00', '2024-03-20 13:45:02', 2150, FALSE, NULL, 'completed',
 '{"status": "success", "agents_allocated": 5, "estimated_impact": "+12% coverage"}'::jsonb),

('batch', ARRAY[2,3,4], 'schedule_synchronization',
 '{"sync_period": "2024-03-21", "pattern_updates": 15, "agent_reassignments": 8}'::jsonb,
 '2024-03-20 22:00:00', '2024-03-20 22:03:15', 195000, TRUE, 'timestamp_based',
 'completed',
 '{"conflicts_resolved": 3, "successful_updates": 12, "failed_updates": 0}'::jsonb),

('emergency', ARRAY[4,5], 'system_outage_coordination',
 '{"outage_location": 5, "backup_location": 4, "duration_minutes": 45, "affected_agents": 23}'::jsonb,
 '2024-03-18 11:30:00', '2024-03-18 11:32:45', 165000, FALSE, NULL, 'completed',
 '{"backup_activated": true, "service_continuity": "maintained", "customer_impact": "minimal"}'::jsonb);

-- ==========================================
-- SUMMARY AND VERIFICATION
-- ==========================================

-- Create summary view of demo data
CREATE OR REPLACE VIEW v_demo_data_summary AS
SELECT 
    'Locations' as entity_type,
    COUNT(*) as count,
    'Иерархия офисов с географическим распределением' as description_ru,
    'Office hierarchy with geographical distribution' as description_en
FROM locations
UNION ALL
SELECT 
    'Business Rules' as entity_type,
    COUNT(*) as count,
    'Бизнес-правила включая ТК РФ и коллективные договоры' as description_ru,
    'Business rules including Labor Code and union agreements' as description_en
FROM optimization_business_rules
UNION ALL
SELECT 
    'Optimization Jobs' as entity_type,
    COUNT(*) as count,
    'Задания оптимизации с различными алгоритмами' as description_ru,
    'Optimization jobs with different algorithms' as description_en
FROM schedule_optimization_jobs
UNION ALL
SELECT 
    'Suggestions Generated' as entity_type,
    COUNT(*) as count,
    'Сгенерированные предложения по оптимизации' as description_ru,
    'Generated optimization suggestions' as description_en
FROM schedule_optimization_suggestions
UNION ALL
SELECT 
    'Performance Metrics' as entity_type,
    COUNT(*) as count,
    'Метрики производительности в реальном времени' as description_ru,
    'Real-time performance metrics' as description_en
FROM optimization_performance_metrics
UNION ALL
SELECT 
    'Cross-Site Coordination' as entity_type,
    COUNT(*) as count,
    'События межрегиональной координации' as description_ru,
    'Cross-site coordination events' as description_en
FROM cross_site_coordination
UNION ALL
SELECT 
    'ML Features' as entity_type,
    COUNT(*) as count,
    'Признаки машинного обучения для оптимизации' as description_ru,
    'Machine learning features for optimization' as description_en
FROM ml_optimization_features;

-- Display summary
SELECT 
    '🎯 Cross-Site Advanced Schedule Optimization Demo Data Loaded Successfully!' as status,
    COUNT(*) as total_entities
FROM (
    SELECT * FROM v_demo_data_summary
) summary;

-- Show key metrics
SELECT 
    entity_type,
    count,
    description_ru,
    description_en
FROM v_demo_data_summary
ORDER BY count DESC;

-- Performance validation query
WITH optimization_performance AS (
    SELECT 
        l.location_name_ru,
        soj.job_name,
        soj.best_score,
        soj.coverage_improvement_percent,
        soj.cost_impact_weekly,
        sos.total_score as best_suggestion_score
    FROM schedule_optimization_jobs soj
    JOIN locations l ON soj.location_id = l.location_id
    LEFT JOIN schedule_optimization_suggestions sos ON soj.job_id = sos.job_id AND sos.rank = 1
    WHERE soj.status = 'completed'
)
SELECT 
    '📊 Optimization Performance Summary' as metric_type,
    AVG(best_score) as avg_optimization_score,
    AVG(coverage_improvement_percent) as avg_coverage_improvement,
    SUM(cost_impact_weekly) as total_weekly_savings_rub
FROM optimization_performance;

COMMENT ON VIEW v_demo_data_summary IS 'Summary view of comprehensive cross-site optimization demo data with Russian and English descriptions';

-- Final success message
SELECT '✅ Cross-Site Advanced Schedule Optimization Demo Data Successfully Loaded' as final_status,
       'Демонстрационные данные для кросс-региональной оптимизации успешно загружены' as final_status_ru;