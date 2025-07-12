-- =============================================================================
-- russian_call_center.sql
-- GREEN PHASE: Generate ООО "ТехноСервис" Demo Data
-- =============================================================================
-- Purpose: Create realistic Russian call center scenario showing our superiority
-- Story: 50-agent Moscow call center, March tax season surge (1000→5000 calls)
-- =============================================================================

\echo '================================================================================'
\echo 'GENERATING ООО "ТЕХНОСЕРВИС" DEMO DATA'
\echo 'Moscow call center struggling with tax season'
\echo '================================================================================'

-- Clean up old demo data
DELETE FROM agent_status_realtime WHERE employee_tab_n LIKE 'TS%';
DELETE FROM argus_time_entries WHERE employee_tab_n LIKE 'TS%';
DELETE FROM historical_data WHERE project_id IN (SELECT id FROM forecasting_projects WHERE project_name LIKE '%ТехноСервис%');
DELETE FROM forecasting_projects WHERE project_name LIKE '%ТехноСервис%';
DELETE FROM zup_agent_data WHERE tab_n LIKE 'TS%';

-- =============================================================================
-- 1. Create 50 Russian agents
-- =============================================================================
\echo '\n📊 Creating 50 Russian agents...'

-- Common Russian surnames and names
WITH russian_names AS (
    SELECT * FROM (VALUES
        ('Иванов', 'Иван', 'Петрович'),
        ('Петров', 'Петр', 'Иванович'),
        ('Сидоров', 'Алексей', 'Сергеевич'),
        ('Смирнова', 'Елена', 'Владимировна'),
        ('Козлова', 'Ольга', 'Николаевна'),
        ('Новикова', 'Анна', 'Александровна'),
        ('Морозов', 'Дмитрий', 'Андреевич'),
        ('Волков', 'Михаил', 'Юрьевич'),
        ('Соколов', 'Сергей', 'Павлович'),
        ('Попова', 'Мария', 'Дмитриевна'),
        ('Лебедева', 'Татьяна', 'Игоревна'),
        ('Кузнецов', 'Андрей', 'Викторович'),
        ('Николаев', 'Николай', 'Николаевич'),
        ('Васильева', 'Наталья', 'Сергеевна'),
        ('Федоров', 'Федор', 'Федорович'),
        ('Михайлова', 'Светлана', 'Михайловна'),
        ('Александров', 'Александр', 'Александрович'),
        ('Романова', 'Екатерина', 'Романовна'),
        ('Захаров', 'Павел', 'Олегович'),
        ('Григорьева', 'Людмила', 'Васильевна')
    ) AS t(surname, name, patronymic)
)
INSERT INTO zup_agent_data (tab_n, fio_full, position_name, department, email, mobile_phone, hire_date)
SELECT 
    'TS' || LPAD(row_number()::text, 3, '0') as tab_n,
    rn.surname || ' ' || rn.name || ' ' || rn.patronymic as fio_full,
    CASE 
        WHEN row_number() = 1 THEN 'Supervisor'
        WHEN row_number() <= 5 THEN 'Team Lead'
        WHEN row_number() <= 15 THEN 'Senior Agent'
        ELSE 'Agent'
    END as position_name,
    'ООО ТехноСервис - Call Center' as department,
    lower(rn.name || '.' || rn.surname || '@technoservice.ru') as email,
    '+7 (495) 123-' || LPAD((4000 + row_number())::text, 4, '0') as mobile_phone,
    CURRENT_DATE - INTERVAL '2 years' + (random() * INTERVAL '700 days')::interval as hire_date
FROM russian_names rn
CROSS JOIN generate_series(1, 3) as g(n); -- 20 names x 3 = 60, take first 50

-- Add remaining agents to reach 50
INSERT INTO zup_agent_data (tab_n, fio_full, position_name, department, email, mobile_phone, hire_date)
SELECT 
    'TS' || LPAD((20 + n)::text, 3, '0') as tab_n,
    CASE n % 10
        WHEN 1 THEN 'Егоров Егор Егорович'
        WHEN 2 THEN 'Белова Вера Ивановна'
        WHEN 3 THEN 'Комаров Артем Денисович'
        WHEN 4 THEN 'Орлова Юлия Андреевна'
        WHEN 5 THEN 'Киселев Илья Романович'
        WHEN 6 THEN 'Макарова Дарья Кирилловна'
        WHEN 7 THEN 'Андреев Кирилл Максимович'
        WHEN 8 THEN 'Ковалева Ксения Артемовна'
        WHEN 9 THEN 'Ильин Максим Ильич'
        ELSE 'Гусева Алина Дмитриевна'
    END as fio_full,
    'Agent' as position_name,
    'ООО ТехноСервис - Call Center' as department,
    'agent' || n || '@technoservice.ru' as email,
    '+7 (495) 124-' || LPAD((n)::text, 4, '0') as mobile_phone,
    CURRENT_DATE - (random() * INTERVAL '500 days')::interval as hire_date
FROM generate_series(1, 30) as n
LIMIT 30;

-- =============================================================================
-- 2. Create Russian holidays
-- =============================================================================
\echo '\n🗓️ Adding Russian holidays...'

INSERT INTO holidays (holiday_date, holiday_name, is_holiday) VALUES
('2025-01-01', 'Новый год', true),
('2025-01-02', 'Новогодние каникулы', true),
('2025-01-03', 'Новогодние каникулы', true),
('2025-01-04', 'Новогодние каникулы', true),
('2025-01-05', 'Новогодние каникулы', true),
('2025-01-06', 'Новогодние каникулы', true),
('2025-01-07', 'Рождество Христово', true),
('2025-01-08', 'Новогодние каникулы', true),
('2025-02-23', 'День защитника Отечества', true),
('2025-03-08', 'Международный женский день', true),
('2025-05-01', 'Праздник Весны и Труда', true),
('2025-05-09', 'День Победы', true),
('2025-06-12', 'День России', true),
('2025-11-04', 'День народного единства', true)
ON CONFLICT (holiday_date) DO NOTHING;

-- =============================================================================
-- 3. Create forecasting project for tax season
-- =============================================================================
\echo '\n📈 Creating tax season forecasting project...'

INSERT INTO forecasting_projects (id, project_name, service_id, group_id, start_date, end_date, project_status)
VALUES (
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'ТехноСервис - Налоговый сезон 2025',
    1,
    1,
    '2025-01-01',
    '2025-03-31',
    'COMPLETED'
);

-- =============================================================================
-- 4. Generate historical data showing surge
-- =============================================================================
\echo '\n📊 Generating historical data (Jan-Mar with surge)...'

-- January-February: Normal load (800-1200 calls/day)
INSERT INTO historical_data (project_id, data_datetime, call_volume, aht_seconds)
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    generate_series(
        '2025-01-01 09:00:00'::timestamp,
        '2025-02-28 18:00:00'::timestamp,
        '1 hour'::interval
    ) as data_datetime,
    CASE 
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 9 AND 11 THEN 80 + (random() * 40)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 12 AND 14 THEN 100 + (random() * 50)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 15 AND 17 THEN 90 + (random() * 30)::int
        ELSE 40 + (random() * 20)::int
    END as call_volume,
    180 + (random() * 60)::int as aht_seconds
WHERE EXTRACT(hour FROM generate_series) BETWEEN 9 AND 18
AND EXTRACT(dow FROM generate_series) BETWEEN 1 AND 5; -- Weekdays only

-- March: Tax season surge (3000-5000 calls/day)
INSERT INTO historical_data (project_id, data_datetime, call_volume, aht_seconds)
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    generate_series(
        '2025-03-01 09:00:00'::timestamp,
        '2025-03-31 18:00:00'::timestamp,
        '1 hour'::interval
    ) as data_datetime,
    CASE 
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 9 AND 11 THEN 400 + (random() * 200)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 12 AND 14 THEN 500 + (random() * 250)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 15 AND 17 THEN 450 + (random() * 150)::int
        ELSE 200 + (random() * 100)::int
    END as call_volume,
    240 + (random() * 120)::int as aht_seconds -- Longer calls during tax season
WHERE EXTRACT(hour FROM generate_series) BETWEEN 9 AND 18
AND EXTRACT(dow FROM generate_series) BETWEEN 1 AND 5;

-- =============================================================================
-- 5. Generate forecasts showing the surge
-- =============================================================================
\echo '\n🔮 Generating forecasts for March surge...'

-- Call volume forecasts
INSERT INTO call_volume_forecasts (project_id, forecast_datetime, forecast_value)
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    generate_series(
        CURRENT_DATE::timestamp,
        (CURRENT_DATE + INTERVAL '7 days')::timestamp,
        '1 hour'::interval
    ) as forecast_datetime,
    CASE 
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 9 AND 11 THEN 450 + (random() * 100)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 12 AND 14 THEN 550 + (random() * 100)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 15 AND 17 THEN 500 + (random() * 100)::int
        ELSE 250 + (random() * 50)::int
    END as forecast_value
WHERE EXTRACT(hour FROM generate_series) BETWEEN 9 AND 18;

-- Operator requirements (showing understaffing)
INSERT INTO operator_forecasts (project_id, interval_datetime, operator_requirement)
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    generate_series(
        CURRENT_DATE::timestamp,
        (CURRENT_DATE + INTERVAL '7 days')::timestamp,
        '30 minutes'::interval
    ) as interval_datetime,
    CASE 
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 9 AND 11 THEN 55 + (random() * 10)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 12 AND 14 THEN 65 + (random() * 10)::int
        WHEN EXTRACT(hour FROM generate_series) BETWEEN 15 AND 17 THEN 60 + (random() * 10)::int
        ELSE 30 + (random() * 10)::int
    END as operator_requirement
WHERE EXTRACT(hour FROM generate_series) BETWEEN 9 AND 18;

-- =============================================================================
-- 6. Create real-time monitoring data
-- =============================================================================
\echo '\n⚡ Populating real-time dashboards...'

-- Current agent status (45 working, 5 on break)
INSERT INTO agent_status_realtime (employee_tab_n, employee_name, current_status, status_russian, time_code, last_updated)
SELECT 
    tab_n,
    fio_full,
    CASE 
        WHEN random() < 0.7 THEN 'In Call'
        WHEN random() < 0.85 THEN 'Available'
        WHEN random() < 0.95 THEN 'Break'
        ELSE 'Not Ready'
    END as current_status,
    CASE 
        WHEN random() < 0.7 THEN 'В работе'
        WHEN random() < 0.85 THEN 'Доступен'
        WHEN random() < 0.95 THEN 'На перерыве'
        ELSE 'Недоступен'
    END as status_russian,
    'I' as time_code,
    CURRENT_TIMESTAMP - (random() * INTERVAL '30 minutes')
FROM zup_agent_data
WHERE tab_n LIKE 'TS%'
LIMIT 50;

-- Service level monitoring (showing degradation)
INSERT INTO service_level_monitoring (
    service_name, current_service_level, target_service_level,
    calls_offered, calls_answered, calls_abandoned, average_wait_time
) VALUES (
    'ТехноСервис - Основная линия',
    58.5, -- Below target!
    80.0,
    4500,
    2633,
    1867,
    245.7 -- Long wait time
);

-- Coverage analysis showing gap
INSERT INTO coverage_analysis_realtime (
    time_interval, required_agents, available_agents, 
    coverage_gap, coverage_percentage, status
) VALUES (
    CURRENT_TIMESTAMP,
    65, -- Need 65 agents
    45, -- Only 45 available
    20, -- Gap of 20!
    69.2,
    'CRITICAL'
);

-- Executive KPIs
INSERT INTO executive_kpi_dashboard (kpi_name, kpi_value, kpi_target, kpi_unit, kpi_status) VALUES
('Service Level', 58.5, 80.0, '%', 'CRITICAL'),
('Agent Utilization', 94.5, 85.0, '%', 'WARNING'),
('Forecast Accuracy', 85.0, 60.0, '%', 'EXCELLENT'),
('Average Wait Time', 245.7, 60.0, 'seconds', 'CRITICAL'),
('Schedule Optimization Time', 87, 415, 'ms', 'EXCELLENT'),
('Calls per Agent', 100, 80, 'calls', 'WARNING');

-- =============================================================================
-- 7. Multi-skill configuration for tax specialists
-- =============================================================================
\echo '\n🎓 Configuring multi-skill agents...'

-- Create tax-related skills
INSERT INTO skill_requirements (skill_id, skill_name) VALUES
(101, 'Налоговые консультации'),
(102, 'Техподдержка 1С'),
(103, 'Общие вопросы'),
(104, 'VIP обслуживание')
ON CONFLICT DO NOTHING;

-- Assign skills to agents (multi-skill distribution)
INSERT INTO employee_skills (employee_id, skill_id)
SELECT 
    gen_random_uuid(),
    CASE 
        WHEN position_name = 'Senior Agent' THEN 101 -- Tax specialists
        WHEN position_name = 'Team Lead' THEN 102 -- 1C support
        ELSE 103 -- General questions
    END
FROM zup_agent_data
WHERE tab_n LIKE 'TS%';

-- Some agents have multiple skills
INSERT INTO employee_skills (employee_id, skill_id)
SELECT 
    gen_random_uuid(),
    104 -- VIP service
FROM zup_agent_data
WHERE position_name IN ('Team Lead', 'Supervisor')
AND tab_n LIKE 'TS%';

-- =============================================================================
-- 8. Create optimization project showing our superiority
-- =============================================================================
\echo '\n🚀 Creating AI optimization project...'

INSERT INTO optimization_projects (
    id, project_name, optimization_date, agents_count, 
    algorithm_version, forecasting_project_id, project_status
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'ТехноСервис - AI оптимизация (налоговый сезон)',
    CURRENT_DATE,
    50,
    'AI_GENETIC_V2',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'ACTIVE'
);

-- Generate optimized schedule suggestions
INSERT INTO schedule_suggestions (
    optimization_project_id, employee_tab_n, 
    suggestion_status, efficiency_score
)
SELECT 
    '550e8400-e29b-41d4-a716-446655440000',
    tab_n,
    'PENDING',
    0.85 + (random() * 0.10) -- 85-95% efficiency
FROM zup_agent_data
WHERE tab_n LIKE 'TS%';

-- =============================================================================
-- 9. Create process for quick demo
-- =============================================================================
\echo '\n⚙️ Setting up demo process...'

INSERT INTO process_definitions (
    process_name, process_status, execution_time_estimate
) VALUES (
    'Schedule Optimization',
    'ACTIVE',
    500 -- 500ms execution
) ON CONFLICT (process_name) DO NOTHING;

\echo '\n================================================================================'
\echo '✅ DEMO DATA READY!'
\echo ''
\echo 'Scenario: ООО "ТехноСервис" - 50 agents in Moscow'
\echo 'Problem: March tax season surge (5000 calls vs 1000 normal)'
\echo 'Argus fails: Service level drops to 58.5% (target 80%)'
\echo 'Our solution: AI optimization maintains 85% efficiency'
\echo ''
\echo 'Key metrics:'
\echo '- Coverage gap: 20 agents short'
\echo '- Wait time: 245 seconds (vs 60 target)'
\echo '- Our optimization: 87ms (vs Argus 415ms)'
\echo '- Multi-skill agents handle tax + general queries'
\echo '================================================================================'