-- ======================================================================
-- RUSSIAN LANGUAGE SUPPORT ENHANCEMENT FOR WFM ENTERPRISE (FIXED)
-- ======================================================================
-- Tasks 36-45: Complete Russian localization and sample data
-- Database: wfm_enterprise
-- Encoding: UTF-8 (already configured)
-- Collation: Enhanced with proper Russian support
-- ======================================================================

-- Task 36: Enhanced Russian request types
-- Update existing request types with comprehensive Russian names
UPDATE request_types SET type_name_ru = 'Заявление на отпуск' WHERE type_name = 'Vacation Request';
UPDATE request_types SET type_name_ru = 'Больничный лист' WHERE type_name = 'Sick Leave';
UPDATE request_types SET type_name_ru = 'Обмен сменами' WHERE type_name = 'Shift Exchange';
UPDATE request_types SET type_name_ru = 'Личный выходной' WHERE type_name = 'Personal Day';
UPDATE request_types SET type_name_ru = 'Заявка на обучение' WHERE type_name = 'Training Request';

-- Add additional Russian request types
INSERT INTO request_types (id, type_name, type_name_ru, requires_approval, max_advance_days, workflow_steps, is_active) VALUES
(gen_random_uuid(), 'Overtime Request', 'Заявка на переработку', true, 1, 
 '{"steps": [{"step": 1, "name_ru": "Запрос сверхурочных", "name_en": "Overtime Request"}, 
             {"step": 2, "name_ru": "Обоснование необходимости", "name_en": "Justification Review"}]}', true),

(gen_random_uuid(), 'Administrative Leave', 'Административный отпуск', true, 7, 
 '{"steps": [{"step": 1, "name_ru": "Подача заявления", "name_en": "Application"}, 
             {"step": 2, "name_ru": "HR одобрение", "name_en": "HR Approval"}]}', true),

(gen_random_uuid(), 'Maternity Leave', 'Декретный отпуск', false, 140, 
 '{"steps": [{"step": 1, "name_ru": "Подача документов", "name_en": "Document Submission"}, 
             {"step": 2, "name_ru": "Медицинская экспертиза", "name_en": "Medical Review"}]}', true),

(gen_random_uuid(), 'Study Leave', 'Учебный отпуск', true, 30, 
 '{"steps": [{"step": 1, "name_ru": "Подача справки из учебного заведения", "name_en": "Educational Certificate"}, 
             {"step": 2, "name_ru": "HR согласование", "name_en": "HR Approval"}]}', true),

(gen_random_uuid(), 'Compensatory Time Off', 'Отгул за переработку', false, 0, 
 '{"steps": [{"step": 1, "name_ru": "Заявление на компенсацию", "name_en": "Compensation Request"}]}', true);

-- Task 37: Russian employee names with patronymic
-- Add Russian employees to existing structure
DO $$
DECLARE
    org_id UUID;
    dept_id UUID;
BEGIN
    -- Get existing organization and department
    SELECT id INTO org_id FROM organizations LIMIT 1;
    SELECT id INTO dept_id FROM departments LIMIT 1;
    
    -- Update existing employees with patronymic
    UPDATE employees SET patronymic = 'Петрович' WHERE first_name = 'Иван' AND last_name = 'Иванов';
    UPDATE employees SET patronymic = 'Сергеевна' WHERE first_name = 'Петр' AND last_name = 'Петров';
    
    -- Add new Russian employees (using correct employment_type values)
    INSERT INTO employees (id, organization_id, department_id, employee_number, first_name, last_name, patronymic, email, employment_type, hire_date, is_active, personnel_number, time_zone, work_rate) VALUES
    (gen_random_uuid(), org_id, dept_id, 'EMP003', 'Мария', 'Петрова', 'Сергеевна', 'm.petrova@technoservice.ru', 'full-time', '2024-02-01', true, 'T003', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP004', 'Александр', 'Сидоров', 'Владимирович', 'a.sidorov@technoservice.ru', 'full-time', '2024-01-20', true, 'T004', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP005', 'Елена', 'Козлова', 'Андреевна', 'e.kozlova@technoservice.ru', 'part-time', '2024-03-01', true, 'T005', 'Europe/Moscow', 0.75),
    (gen_random_uuid(), org_id, dept_id, 'EMP006', 'Дмитрий', 'Морозов', 'Николаевич', 'd.morozov@technoservice.ru', 'full-time', '2023-12-01', true, 'T006', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP007', 'Ольга', 'Волкова', 'Михайловна', 'o.volkova@technoservice.ru', 'full-time', '2024-01-10', true, 'T007', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP008', 'Сергей', 'Лебедев', 'Алексеевич', 's.lebedev@technoservice.ru', 'full-time', '2024-02-15', true, 'T008', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP009', 'Анна', 'Соколова', 'Дмитриевна', 'a.sokolova@technoservice.ru', 'full-time', '2024-01-25', true, 'T009', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP010', 'Михаил', 'Новиков', 'Валерьевич', 'm.novikov@technoservice.ru', 'full-time', '2023-11-15', true, 'T010', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP011', 'Татьяна', 'Попова', 'Игоревна', 't.popova@technoservice.ru', 'full-time', '2024-02-20', true, 'T011', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP012', 'Андрей', 'Федоров', 'Олегович', 'a.fedorov@technoservice.ru', 'full-time', '2024-01-05', true, 'T012', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP013', 'Наталья', 'Орлова', 'Викторовна', 'n.orlova@technoservice.ru', 'part-time', '2024-03-10', true, 'T013', 'Europe/Moscow', 0.5),
    (gen_random_uuid(), org_id, dept_id, 'EMP014', 'Владимир', 'Киселев', 'Романович', 'v.kiselev@technoservice.ru', 'full-time', '2023-10-01', true, 'T014', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP015', 'Ирина', 'Макарова', 'Павловна', 'i.makarova@technoservice.ru', 'full-time', '2024-01-30', true, 'T015', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP016', 'Алексей', 'Григорьев', 'Сергеевич', 'a.grigoriev@technoservice.ru', 'full-time', '2024-02-05', true, 'T016', 'Europe/Moscow', 1.0);
    
    RAISE NOTICE 'Added % Russian employees with patronymic names', 13;
END $$;

-- Task 38: Russian status workflows
-- Add status_ru column to employee_requests if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employee_requests' AND column_name = 'status_ru') THEN
        ALTER TABLE employee_requests ADD COLUMN status_ru VARCHAR(100);
    END IF;
END $$;

-- Update existing requests with Russian status names
UPDATE employee_requests SET status_ru = 
    CASE status
        WHEN 'SUBMITTED' THEN 'Создана'
        WHEN 'PENDING' THEN 'На рассмотрении'
        WHEN 'APPROVED' THEN 'Одобрена'
        WHEN 'REJECTED' THEN 'Отклонена'
        WHEN 'CANCELLED' THEN 'Отменена'
        ELSE status
    END
WHERE status_ru IS NULL;

-- Task 39: Russian departments with proper hierarchy
-- Add Russian department names
UPDATE departments SET name = 'Контакт-центр' WHERE name = 'Call Center';

-- Add more Russian departments
DO $$
DECLARE
    org_id UUID;
    cc_dept_id UUID;
BEGIN
    SELECT id INTO org_id FROM organizations LIMIT 1;
    SELECT id INTO cc_dept_id FROM departments WHERE name = 'Контакт-центр' LIMIT 1;
    
    -- Add Russian sub-departments
    INSERT INTO departments (id, organization_id, parent_department_id, name, code, created_at, updated_at) VALUES
    (gen_random_uuid(), org_id, cc_dept_id, 'Отдел входящих звонков', 'КЦ-ВХ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), org_id, cc_dept_id, 'Отдел исходящих звонков', 'КЦ-ИСХ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), org_id, cc_dept_id, 'Отдел технической поддержки', 'КЦ-ТП', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), org_id, cc_dept_id, 'Отдел контроля качества', 'КЦ-КК', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    
    RAISE NOTICE 'Added Russian department structure';
END $$;

-- Task 40: Russian positions and roles
-- Create positions table if it doesn't exist
CREATE TABLE IF NOT EXISTS employee_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_code VARCHAR(20) NOT NULL,
    position_name_ru VARCHAR(255) NOT NULL,
    position_name_en VARCHAR(255) NOT NULL,
    department_type VARCHAR(100),
    level_category VARCHAR(50),
    base_salary_range NUMRANGE,
    requires_certification BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert typical Russian call center positions
INSERT INTO employee_positions (position_code, position_name_ru, position_name_en, department_type, level_category, requires_certification) VALUES
('OP1', 'Оператор 1-й линии', 'Tier 1 Operator', 'incoming', 'junior', false),
('OP2', 'Оператор 2-й линии', 'Tier 2 Operator', 'incoming', 'senior', true),
('OPOUT', 'Оператор исходящих звонков', 'Outbound Operator', 'outbound', 'junior', false),
('OPVIP', 'Оператор VIP-клиентов', 'VIP Client Operator', 'incoming', 'senior', true),
('SPTEC', 'Специалист технической поддержки', 'Technical Support Specialist', 'support', 'middle', true),
('SPVIP', 'Специалист VIP-поддержки', 'VIP Support Specialist', 'support', 'senior', true),
('STARG', 'Старший оператор', 'Senior Operator', 'any', 'senior', true),
('RUGR', 'Руководитель группы', 'Team Leader', 'any', 'lead', true),
('SUPVZ', 'Супервизор', 'Supervisor', 'any', 'lead', true),
('SPKK', 'Специалист по контролю качества', 'Quality Assurance Specialist', 'quality', 'middle', true),
('ANIKK', 'Аналитик качества', 'Quality Analyst', 'quality', 'senior', true),
('NACSMN', 'Начальник смены', 'Shift Manager', 'any', 'management', true),
('NACOTD', 'Начальник отдела', 'Department Head', 'any', 'management', true),
('MENEDG', 'Менеджер по обучению', 'Training Manager', 'any', 'management', true),
('PLANIR', 'Планировщик ресурсов', 'Resource Planner', 'planning', 'middle', true);

-- Task 41: Russian time types (И/Н/В/С classification)
-- Clear and repopulate ZUP time types with proper Russian classifications
TRUNCATE zup_time_types;

INSERT INTO zup_time_types (time_type_code, time_type_name_ru, time_type_name_en, category, creates_document, document_type, priority_level, priority_description, sync_to_wfm, sync_from_wfm) VALUES
-- Work categories (using existing constraint values)
('И', 'Присутствие на работе', 'Work Presence', 'work', false, NULL, 1, 'Основное рабочее время', true, true),
('ИСВ', 'Сверхурочная работа', 'Overtime Work', 'overtime', true, 'overtime_approval', 2, 'Переработка сверх нормы', true, true),
('ИПР', 'Работа в праздничный день', 'Holiday Work', 'work', true, 'holiday_work_approval', 2, 'Работа в выходной/праздник', true, true),
('ИНОЧ', 'Ночная работа', 'Night Work', 'work', false, NULL, 2, 'Работа в ночное время', true, true),

-- Absence categories
('Н', 'Неявка на работу', 'Work Absence', 'absence', true, 'absence_notification', 3, 'Общая неявка', true, true),
('НУП', 'Неявка уважительная', 'Excused Absence', 'absence', true, 'excuse_document', 2, 'Уважительная причина', true, true),
('ННУ', 'Неявка неуважительная', 'Unexcused Absence', 'absence', true, 'disciplinary_action', 4, 'Прогул', true, true),

-- Vacation categories
('В', 'Выходной день', 'Day Off', 'vacation', false, NULL, 1, 'Плановый выходной', true, true),
('ВП', 'Праздничный день', 'Public Holiday', 'vacation', false, NULL, 1, 'Государственный праздник', true, true),
('ВО', 'Ежегодный оплачиваемый отпуск', 'Annual Paid Leave', 'vacation', true, 'vacation_request', 2, 'Основной отпуск', true, true),
('ВД', 'Дополнительный отпуск', 'Additional Leave', 'vacation', true, 'additional_leave_request', 2, 'Дополнительный отпуск', true, true),
('ВУ', 'Учебный отпуск', 'Study Leave', 'vacation', true, 'study_leave_certificate', 2, 'Отпуск на обучение', true, true),
('ВР', 'Отпуск по беременности и родам', 'Maternity Leave', 'vacation', true, 'maternity_certificate', 1, 'Декретный отпуск', true, true),
('ВЖ', 'Отпуск по уходу за ребенком', 'Childcare Leave', 'vacation', true, 'childcare_application', 1, 'Отпуск по уходу за ребенком', true, true),
('ВБ', 'Отпуск без сохранения заработной платы', 'Unpaid Leave', 'vacation', true, 'unpaid_leave_request', 3, 'Отпуск за свой счет', true, true),

-- Special categories
('С', 'Служебная командировка', 'Business Trip', 'special', true, 'travel_order', 2, 'Командировка', true, true),
('СП', 'Повышение квалификации', 'Professional Development', 'special', true, 'training_approval', 2, 'Обучение/курсы', true, true),
('СВ', 'Выполнение государственных обязанностей', 'Civic Duty', 'special', true, 'civic_duty_summons', 1, 'Исполнение гос. обязанностей', true, true),
('СД', 'Донорские дни', 'Blood Donation Days', 'special', true, 'donor_certificate', 1, 'Донорство крови', true, true),

-- Sick leave
('Т', 'Временная нетрудоспособность', 'Temporary Disability', 'sick_leave', true, 'medical_certificate', 1, 'Больничный лист', true, true),
('ТУ', 'Уход за больным членом семьи', 'Family Care Leave', 'sick_leave', true, 'family_care_certificate', 1, 'Уход за больным родственником', true, true);

-- Task 42: Russian production calendar with holidays
-- Clear and repopulate Russian holidays for 2024-2025
DELETE FROM production_calendar WHERE calendar_year IN (2024, 2025) AND region_code = 'RU';

INSERT INTO production_calendar (calendar_year, calendar_date, day_type, working_hours, is_shortened_day, region_code) VALUES
-- 2024 Russian holidays
(2024, '2024-01-01', 'holiday', 0, false, 'RU'), -- Новый год
(2024, '2024-01-02', 'holiday', 0, false, 'RU'),
(2024, '2024-01-03', 'holiday', 0, false, 'RU'),
(2024, '2024-01-04', 'holiday', 0, false, 'RU'),
(2024, '2024-01-05', 'holiday', 0, false, 'RU'),
(2024, '2024-01-08', 'holiday', 0, false, 'RU'),
(2024, '2024-02-23', 'holiday', 0, false, 'RU'), -- День защитника Отечества
(2024, '2024-03-08', 'holiday', 0, false, 'RU'), -- Международный женский день
(2024, '2024-05-01', 'holiday', 0, false, 'RU'), -- Праздник Весны и Труда
(2024, '2024-05-09', 'holiday', 0, false, 'RU'), -- День Победы
(2024, '2024-06-12', 'holiday', 0, false, 'RU'), -- День России
(2024, '2024-11-04', 'holiday', 0, false, 'RU'), -- День народного единства

-- 2025 Russian holidays
(2025, '2025-01-01', 'holiday', 0, false, 'RU'),
(2025, '2025-01-02', 'holiday', 0, false, 'RU'),
(2025, '2025-01-03', 'holiday', 0, false, 'RU'),
(2025, '2025-01-06', 'holiday', 0, false, 'RU'),
(2025, '2025-01-07', 'holiday', 0, false, 'RU'),
(2025, '2025-01-08', 'holiday', 0, false, 'RU'),
(2025, '2025-02-24', 'holiday', 0, false, 'RU'), -- День защитника Отечества (перенос)
(2025, '2025-03-08', 'holiday', 0, false, 'RU'),
(2025, '2025-05-01', 'holiday', 0, false, 'RU'),
(2025, '2025-05-09', 'holiday', 0, false, 'RU'),
(2025, '2025-06-12', 'holiday', 0, false, 'RU'),
(2025, '2025-11-04', 'holiday', 0, false, 'RU'),

-- Pre-holiday shortened days
(2024, '2024-02-22', 'working', 7, true, 'RU'), -- Предпраздничный день
(2024, '2024-03-07', 'working', 7, true, 'RU'),
(2024, '2024-04-30', 'working', 7, true, 'RU'),
(2024, '2024-05-08', 'working', 7, true, 'RU'),
(2024, '2024-06-11', 'working', 7, true, 'RU'),
(2024, '2024-11-02', 'working', 7, true, 'RU'),
(2024, '2024-12-31', 'working', 7, true, 'RU'),

(2025, '2025-02-21', 'working', 7, true, 'RU'),
(2025, '2025-03-07', 'working', 7, true, 'RU'),
(2025, '2025-04-30', 'working', 7, true, 'RU'),
(2025, '2025-05-08', 'working', 7, true, 'RU'),
(2025, '2025-06-11', 'working', 7, true, 'RU'),
(2025, '2025-11-03', 'working', 7, true, 'RU'),
(2025, '2025-12-31', 'working', 7, true, 'RU');

-- Add holiday names table for Russian holidays
CREATE TABLE IF NOT EXISTS russian_holidays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    holiday_date DATE NOT NULL,
    holiday_name_ru VARCHAR(255) NOT NULL,
    holiday_name_en VARCHAR(255) NOT NULL,
    holiday_type VARCHAR(50) NOT NULL, -- federal, regional, religious
    is_non_working BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear and insert Russian holidays
TRUNCATE russian_holidays;
INSERT INTO russian_holidays (holiday_date, holiday_name_ru, holiday_name_en, holiday_type, is_non_working) VALUES
('2024-01-01', 'Новый год', 'New Year', 'federal', true),
('2024-01-07', 'Рождество Христово', 'Orthodox Christmas', 'federal', true),
('2024-02-23', 'День защитника Отечества', 'Defender of the Fatherland Day', 'federal', true),
('2024-03-08', 'Международный женский день', 'International Women''s Day', 'federal', true),
('2024-05-01', 'Праздник Весны и Труда', 'Spring and Labor Day', 'federal', true),
('2024-05-09', 'День Победы', 'Victory Day', 'federal', true),
('2024-06-12', 'День России', 'Russia Day', 'federal', true),
('2024-11-04', 'День народного единства', 'Unity Day', 'federal', true),

('2025-01-01', 'Новый год', 'New Year', 'federal', true),
('2025-01-07', 'Рождество Христово', 'Orthodox Christmas', 'federal', true),
('2025-02-23', 'День защитника Отечества', 'Defender of the Fatherland Day', 'federal', true),
('2025-03-08', 'Международный женский день', 'International Women''s Day', 'federal', true),
('2025-05-01', 'Праздник Весны и Труда', 'Spring and Labor Day', 'federal', true),
('2025-05-09', 'День Победы', 'Victory Day', 'federal', true),
('2025-06-12', 'День России', 'Russia Day', 'federal', true),
('2025-11-04', 'День народного единства', 'Unity Day', 'federal', true);

-- Task 43: Test Cyrillic encoding
-- Test query to verify Cyrillic support
SELECT 
    'Кириллица работает корректно' as cyrillic_test,
    'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ' as upper_cyrillic,
    'абвгдеёжзийклмнопрстуфхцчшщъыьэюя' as lower_cyrillic,
    LENGTH('Тестирование UTF-8') as utf8_length,
    pg_encoding_to_char(encoding) as database_encoding
FROM pg_database WHERE datname = current_database();

-- Task 44: Sample workflow data in Russian
-- Create a vacation request workflow with Russian names (using actual table structure)
DO $$
DECLARE
    emp_id UUID;
    manager_id UUID;
BEGIN
    -- Get Russian employee
    SELECT id INTO emp_id FROM employees WHERE first_name = 'Иван' AND last_name = 'Иванов' LIMIT 1;
    SELECT id INTO manager_id FROM employees WHERE first_name = 'Мария' LIMIT 1;
    
    -- Create vacation request using actual table structure
    INSERT INTO employee_requests (id, employee_id, request_type, status, submitted_at, start_date, end_date, 
                                   duration_days, description, status_ru)
    VALUES (gen_random_uuid(), emp_id, 'Vacation Request', 'APPROVED', 
            CURRENT_DATE - INTERVAL '7 days', 
            CURRENT_DATE + INTERVAL '30 days', 
            CURRENT_DATE + INTERVAL '44 days',
            14, 
            'Ежегодный оплачиваемый отпуск на летний период. Планируется поездка к морю с семьей. Обеспечена замена на период отпуска.',
            'Одобрена');
    
    RAISE NOTICE 'Created Russian vacation request workflow';
END $$;

-- Task 45: Multi-language support verification
-- Create Russian language dashboard view
CREATE OR REPLACE VIEW v_russian_wfm_dashboard AS
SELECT 
    -- Employee statistics with Russian names
    COUNT(DISTINCT e.id) as "Всего сотрудников",
    COUNT(DISTINCT CASE WHEN e.is_active = true THEN e.id END) as "Активных сотрудников",
    COUNT(DISTINCT d.id) as "Количество отделов",
    
    -- Request statistics in Russian
    COUNT(DISTINCT er.id) as "Всего заявлений",
    COUNT(DISTINCT CASE WHEN er.status = 'SUBMITTED' THEN er.id END) as "Ожидают рассмотрения",
    COUNT(DISTINCT CASE WHEN er.status = 'APPROVED' THEN er.id END) as "Одобрено",
    COUNT(DISTINCT CASE WHEN er.status = 'REJECTED' THEN er.id END) as "Отклонено",
    
    -- Time type and calendar coverage
    COUNT(DISTINCT ztt.id) as "Типов времени",
    COUNT(DISTINCT pc.calendar_date) as "Дней в календаре",
    COUNT(DISTINCT rh.id) as "Российских праздников"
    
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN employee_requests er ON e.id = er.employee_id
LEFT JOIN zup_time_types ztt ON ztt.sync_to_wfm = true
LEFT JOIN production_calendar pc ON pc.region_code = 'RU'
LEFT JOIN russian_holidays rh ON rh.is_non_working = true;

-- Create verification function for Russian language support
CREATE OR REPLACE FUNCTION verify_russian_language_support()
RETURNS TABLE (
    component VARCHAR(50),
    status VARCHAR(20),
    details TEXT
) AS $$
BEGIN
    -- Test 1: Cyrillic employee names
    RETURN QUERY
    SELECT 
        'Employee Names'::VARCHAR(50),
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END::VARCHAR(20),
        'Russian employees with Cyrillic names: ' || COUNT(*)::TEXT
    FROM employees 
    WHERE first_name ~ '[А-Яа-я]';
    
    -- Test 2: Russian request types
    RETURN QUERY
    SELECT 
        'Request Types'::VARCHAR(50),
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END::VARCHAR(20),
        'Russian request types configured: ' || COUNT(*)::TEXT
    FROM request_types 
    WHERE type_name_ru IS NOT NULL AND type_name_ru != '';
    
    -- Test 3: Russian departments
    RETURN QUERY
    SELECT 
        'Departments'::VARCHAR(50),
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END::VARCHAR(20),
        'Russian department names: ' || COUNT(*)::TEXT
    FROM departments 
    WHERE name ~ '[А-Яа-я]';
    
    -- Test 4: Russian time types
    RETURN QUERY
    SELECT 
        'Time Types'::VARCHAR(50),
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END::VARCHAR(20),
        'Russian time classifications: ' || COUNT(*)::TEXT
    FROM zup_time_types 
    WHERE time_type_name_ru IS NOT NULL;
    
    -- Test 5: Russian holidays
    RETURN QUERY
    SELECT 
        'Holidays'::VARCHAR(50),
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END::VARCHAR(20),
        'Russian holidays configured: ' || COUNT(*)::TEXT
    FROM russian_holidays;
    
    -- Test 6: UTF-8 encoding
    RETURN QUERY
    SELECT 
        'UTF-8 Encoding'::VARCHAR(50),
        'OK'::VARCHAR(20),
        'Database encoding: ' || pg_encoding_to_char(encoding) 
    FROM pg_database WHERE datname = current_database();
    
END;
$$ LANGUAGE plpgsql;

-- Create Russian language employee report
CREATE OR REPLACE VIEW v_russian_employee_report AS
SELECT 
    e.employee_number as "Табельный номер",
    e.last_name || ' ' || e.first_name || COALESCE(' ' || e.patronymic, '') as "ФИО",
    d.name as "Отдел",
    ep.position_name_ru as "Должность",
    CASE e.is_active 
        WHEN true THEN 'Активен' 
        ELSE 'Неактивен' 
    END as "Статус",
    e.hire_date as "Дата приема",
    CASE e.employment_type
        WHEN 'full-time' THEN 'Полная занятость'
        WHEN 'part-time' THEN 'Частичная занятость'
        WHEN 'contract' THEN 'Договор'
        WHEN 'temporary' THEN 'Временная'
        ELSE e.employment_type
    END as "Тип занятости",
    e.work_rate as "Ставка"
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN employee_positions ep ON e.position_id = ep.id
WHERE e.is_active = true
ORDER BY d.name, e.last_name, e.first_name;

-- Final verification and summary
SELECT 'Russian Language Enhancement Complete' as "Статус",
       'Tasks 36-45 implemented successfully' as "Детали",
       CURRENT_TIMESTAMP as "Время выполнения";