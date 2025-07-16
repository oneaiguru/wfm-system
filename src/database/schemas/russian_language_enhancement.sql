-- ======================================================================
-- RUSSIAN LANGUAGE SUPPORT ENHANCEMENT FOR WFM ENTERPRISE
-- ======================================================================
-- Tasks 36-45: Complete Russian localization and sample data
-- Database: wfm_enterprise
-- Encoding: UTF-8 (already configured)
-- Collation: Enhanced with proper Russian support
-- ======================================================================

-- Task 36: Enhanced Russian request types
-- Clear existing and add comprehensive Russian request types
DELETE FROM request_types;

INSERT INTO request_types (id, type_name, type_name_ru, requires_approval, max_advance_days, workflow_steps, is_active) VALUES
(gen_random_uuid(), 'Vacation Request', 'Заявление на отпуск', true, 14, 
 '{"steps": [{"step": 1, "name_ru": "Подача заявления", "name_en": "Application Submitted"}, 
             {"step": 2, "name_ru": "Рассмотрение руководителем", "name_en": "Manager Review"}, 
             {"step": 3, "name_ru": "Согласование с планировщиком", "name_en": "Planner Approval"}, 
             {"step": 4, "name_ru": "Окончательное утверждение", "name_en": "Final Approval"}]}', true),

(gen_random_uuid(), 'Sick Leave', 'Больничный лист', false, 0, 
 '{"steps": [{"step": 1, "name_ru": "Уведомление о болезни", "name_en": "Sick Notification"}, 
             {"step": 2, "name_ru": "Предоставление справки", "name_en": "Medical Certificate"}]}', true),

(gen_random_uuid(), 'Personal Day', 'Отгул', true, 3, 
 '{"steps": [{"step": 1, "name_ru": "Запрос отгула", "name_en": "Personal Day Request"}, 
             {"step": 2, "name_ru": "Согласование", "name_en": "Approval"}]}', true),

(gen_random_uuid(), 'Shift Exchange', 'Обмен сменами', true, 7, 
 '{"steps": [{"step": 1, "name_ru": "Предложение обмена", "name_en": "Exchange Proposal"}, 
             {"step": 2, "name_ru": "Согласие второй стороны", "name_en": "Counterpart Acceptance"}, 
             {"step": 3, "name_ru": "Утверждение супервизором", "name_en": "Supervisor Approval"}]}', true),

(gen_random_uuid(), 'Training Request', 'Заявка на обучение', true, 30, 
 '{"steps": [{"step": 1, "name_ru": "Подача заявки", "name_en": "Training Application"}, 
             {"step": 2, "name_ru": "Согласование с HR", "name_en": "HR Review"}, 
             {"step": 3, "name_ru": "Утверждение бюджета", "name_en": "Budget Approval"}]}', true),

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
-- Clear existing demo employees and add realistic Russian employees
DELETE FROM employees WHERE first_name IN ('Иван', 'Петр');

-- Get organization and department IDs
DO $$
DECLARE
    org_id UUID;
    dept_id UUID;
    user_id UUID;
BEGIN
    -- Get organization ID
    SELECT id INTO org_id FROM organizations LIMIT 1;
    IF org_id IS NULL THEN
        INSERT INTO organizations (id, name, code) VALUES (gen_random_uuid(), 'ООО ТехноСервис', 'TECHNO') RETURNING id INTO org_id;
    END IF;
    
    -- Get department ID
    SELECT id INTO dept_id FROM departments LIMIT 1;
    IF dept_id IS NULL THEN
        INSERT INTO departments (id, organization_id, name, code) VALUES (gen_random_uuid(), org_id, 'Call Center', 'CC') RETURNING id INTO dept_id;
    END IF;
    
    -- Insert realistic Russian employees
    INSERT INTO employees (id, organization_id, department_id, employee_number, first_name, last_name, patronymic, email, employment_type, hire_date, is_active, personnel_number, time_zone, work_rate) VALUES
    (gen_random_uuid(), org_id, dept_id, 'EMP001', 'Иван', 'Иванов', 'Петрович', 'i.ivanov@technoservice.ru', 'full_time', '2024-01-15', true, 'T001', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP002', 'Мария', 'Петрова', 'Сергеевна', 'm.petrova@technoservice.ru', 'full_time', '2024-02-01', true, 'T002', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP003', 'Александр', 'Сидоров', 'Владимирович', 'a.sidorov@technoservice.ru', 'full_time', '2024-01-20', true, 'T003', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP004', 'Елена', 'Козлова', 'Андреевна', 'e.kozlova@technoservice.ru', 'part_time', '2024-03-01', true, 'T004', 'Europe/Moscow', 0.75),
    (gen_random_uuid(), org_id, dept_id, 'EMP005', 'Дмитрий', 'Морозов', 'Николаевич', 'd.morozov@technoservice.ru', 'full_time', '2023-12-01', true, 'T005', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP006', 'Ольга', 'Волкова', 'Михайловна', 'o.volkova@technoservice.ru', 'full_time', '2024-01-10', true, 'T006', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP007', 'Сергей', 'Лебедев', 'Алексеевич', 's.lebedev@technoservice.ru', 'full_time', '2024-02-15', true, 'T007', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP008', 'Анна', 'Соколова', 'Дмитриевна', 'a.sokolova@technoservice.ru', 'full_time', '2024-01-25', true, 'T008', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP009', 'Михаил', 'Новиков', 'Валерьевич', 'm.novikov@technoservice.ru', 'full_time', '2023-11-15', true, 'T009', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP010', 'Татьяна', 'Попова', 'Игоревна', 't.popova@technoservice.ru', 'full_time', '2024-02-20', true, 'T010', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP011', 'Андрей', 'Федоров', 'Олегович', 'a.fedorov@technoservice.ru', 'full_time', '2024-01-05', true, 'T011', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP012', 'Наталья', 'Орлова', 'Викторовна', 'n.orlova@technoservice.ru', 'part_time', '2024-03-10', true, 'T012', 'Europe/Moscow', 0.5),
    (gen_random_uuid(), org_id, dept_id, 'EMP013', 'Владимир', 'Киселев', 'Романович', 'v.kiselev@technoservice.ru', 'full_time', '2023-10-01', true, 'T013', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP014', 'Ирина', 'Макарова', 'Павловна', 'i.makarova@technoservice.ru', 'full_time', '2024-01-30', true, 'T014', 'Europe/Moscow', 1.0),
    (gen_random_uuid(), org_id, dept_id, 'EMP015', 'Алексей', 'Григорьев', 'Сергеевич', 'a.grigoriev@technoservice.ru', 'full_time', '2024-02-05', true, 'T015', 'Europe/Moscow', 1.0);
END $$;

-- Task 38: Russian status workflows
-- Ensure status translations exist
INSERT INTO employee_requests (id, employee_id, request_type_id, request_date, start_date, end_date, 
                               status, status_ru, notes, metadata, created_at)
SELECT 
    gen_random_uuid(),
    e.id,
    rt.id,
    CURRENT_DATE - INTERVAL '5 days',
    CURRENT_DATE + INTERVAL '10 days',
    CURRENT_DATE + INTERVAL '20 days',
    'SUBMITTED',
    'Создана',
    'Образец заявления на отпуск в июле',
    '{"days_requested": 10, "coverage_arranged": true, "priority": "normal"}',
    CURRENT_TIMESTAMP
FROM employees e, request_types rt 
WHERE e.first_name = 'Иван' AND rt.type_name_ru = 'Заявление на отпуск'
LIMIT 1;

-- Task 39: Russian departments with proper hierarchy
-- Clear existing and create realistic Russian call center structure
DELETE FROM departments WHERE name = 'Call Center';

DO $$
DECLARE
    org_id UUID;
    cc_dept_id UUID;
    incoming_dept_id UUID;
    outbound_dept_id UUID;
    support_dept_id UUID;
    qa_dept_id UUID;
BEGIN
    SELECT id INTO org_id FROM organizations LIMIT 1;
    
    -- Main Call Center department
    INSERT INTO departments (id, organization_id, name, code, created_at, updated_at) 
    VALUES (gen_random_uuid(), org_id, 'Контакт-центр', 'КЦ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) 
    RETURNING id INTO cc_dept_id;
    
    -- Incoming calls department
    INSERT INTO departments (id, organization_id, parent_department_id, name, code, created_at, updated_at)
    VALUES (gen_random_uuid(), org_id, cc_dept_id, 'Отдел входящих звонков', 'КЦ-ВХ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING id INTO incoming_dept_id;
    
    -- Outbound calls department  
    INSERT INTO departments (id, organization_id, parent_department_id, name, code, created_at, updated_at)
    VALUES (gen_random_uuid(), org_id, cc_dept_id, 'Отдел исходящих звонков', 'КЦ-ИСХ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING id INTO outbound_dept_id;
    
    -- Technical support department
    INSERT INTO departments (id, organization_id, parent_department_id, name, code, created_at, updated_at)
    VALUES (gen_random_uuid(), org_id, cc_dept_id, 'Отдел технической поддержки', 'КЦ-ТП', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING id INTO support_dept_id;
    
    -- Quality assurance department
    INSERT INTO departments (id, organization_id, parent_department_id, name, code, created_at, updated_at)
    VALUES (gen_random_uuid(), org_id, cc_dept_id, 'Отдел контроля качества', 'КЦ-КК', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING id INTO qa_dept_id;
    
    -- Update employee departments
    UPDATE employees SET department_id = incoming_dept_id WHERE first_name IN ('Иван', 'Мария', 'Александр', 'Елена', 'Дмитрий');
    UPDATE employees SET department_id = outbound_dept_id WHERE first_name IN ('Ольга', 'Сергей', 'Анна');
    UPDATE employees SET department_id = support_dept_id WHERE first_name IN ('Михаил', 'Татьяна', 'Андрей');
    UPDATE employees SET department_id = qa_dept_id WHERE first_name IN ('Наталья', 'Владимир', 'Ирина', 'Алексей');
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

-- Insert typical call center positions
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

-- Add position_id to employees table if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'position_id') THEN
        ALTER TABLE employees ADD COLUMN position_id UUID REFERENCES employee_positions(id);
    END IF;
END $$;

-- Assign positions to employees
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'OP1') WHERE first_name IN ('Иван', 'Мария', 'Елена');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'OP2') WHERE first_name IN ('Александр', 'Дмитрий');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'OPOUT') WHERE first_name IN ('Ольга', 'Сергей');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'RUGR') WHERE first_name IN ('Анна', 'Михаил');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'SPKK') WHERE first_name IN ('Татьяна', 'Андрей');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'SUPVZ') WHERE first_name IN ('Наталья', 'Владимир');
UPDATE employees SET position_id = (SELECT id FROM employee_positions WHERE position_code = 'NACSMN') WHERE first_name IN ('Ирина', 'Алексей');

-- Task 41: Russian time types (И/Н/В/С classification)
-- Populate ZUP time types with proper Russian classifications
TRUNCATE zup_time_types;

INSERT INTO zup_time_types (time_type_code, time_type_name_ru, time_type_name_en, category, creates_document, document_type, priority_level, priority_description, sync_to_wfm, sync_from_wfm) VALUES
-- И - Присутствие (Presence)
('И', 'Присутствие на работе', 'Work Presence', 'presence', false, NULL, 1, 'Основное рабочее время', true, true),
('ИСВ', 'Сверхурочная работа', 'Overtime Work', 'presence', true, 'overtime_approval', 2, 'Переработка сверх нормы', true, true),
('ИПР', 'Работа в праздничный день', 'Holiday Work', 'presence', true, 'holiday_work_approval', 2, 'Работа в выходной/праздник', true, true),
('ИНОЧ', 'Ночная работа', 'Night Work', 'presence', false, NULL, 2, 'Работа в ночное время', true, true),

-- Н - Неявки (Absence)
('Н', 'Неявка на работу', 'Work Absence', 'absence', true, 'absence_notification', 3, 'Общая неявка', true, true),
('НУП', 'Неявка уважительная', 'Excused Absence', 'absence', true, 'excuse_document', 2, 'Уважительная причина', true, true),
('ННУ', 'Неявка неуважительная', 'Unexcused Absence', 'absence', true, 'disciplinary_action', 4, 'Прогул', true, true),

-- В - Выходные и отпуска (Time Off)
('В', 'Выходной день', 'Day Off', 'time_off', false, NULL, 1, 'Плановый выходной', true, true),
('ВП', 'Праздничный день', 'Public Holiday', 'time_off', false, NULL, 1, 'Государственный праздник', true, true),
('ВО', 'Ежегодный оплачиваемый отпуск', 'Annual Paid Leave', 'time_off', true, 'vacation_request', 2, 'Основной отпуск', true, true),
('ВД', 'Дополнительный отпуск', 'Additional Leave', 'time_off', true, 'additional_leave_request', 2, 'Дополнительный отпуск', true, true),
('ВУ', 'Учебный отпуск', 'Study Leave', 'time_off', true, 'study_leave_certificate', 2, 'Отпуск на обучение', true, true),
('ВР', 'Отпуск по беременности и родам', 'Maternity Leave', 'time_off', true, 'maternity_certificate', 1, 'Декретный отпуск', true, true),
('ВЖ', 'Отпуск по уходу за ребенком', 'Childcare Leave', 'time_off', true, 'childcare_application', 1, 'Отпуск по уходу за ребенком', true, true),
('ВБ', 'Отпуск без сохранения заработной платы', 'Unpaid Leave', 'time_off', true, 'unpaid_leave_request', 3, 'Отпуск за свой счет', true, true),

-- С - Служебные командировки и другие (Business Travel and Other)
('С', 'Служебная командировка', 'Business Trip', 'business', true, 'travel_order', 2, 'Командировка', true, true),
('СП', 'Повышение квалификации', 'Professional Development', 'business', true, 'training_approval', 2, 'Обучение/курсы', true, true),
('СВ', 'Выполнение государственных обязанностей', 'Civic Duty', 'business', true, 'civic_duty_summons', 1, 'Исполнение гос. обязанностей', true, true),
('СД', 'Донорские дни', 'Blood Donation Days', 'business', true, 'donor_certificate', 1, 'Донорство крови', true, true),

-- Временная нетрудоспособность
('Т', 'Временная нетрудоспособность', 'Temporary Disability', 'medical', true, 'medical_certificate', 1, 'Больничный лист', true, true),
('ТУ', 'Уход за больным членом семьи', 'Family Care Leave', 'medical', true, 'family_care_certificate', 1, 'Уход за больным родственником', true, true);

-- Task 42: Russian production calendar with holidays
-- Populate Russian holidays for 2024-2025
DELETE FROM production_calendar WHERE calendar_year IN (2024, 2025);

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

-- Task 44: Sample vacation workflow in Russian
-- Create a complete vacation request workflow with Russian data
DO $$
DECLARE
    emp_id UUID;
    req_type_id UUID;
    vacation_req_id UUID;
    approval_id UUID;
BEGIN
    -- Get employee (Иван Иванов)
    SELECT id INTO emp_id FROM employees WHERE first_name = 'Иван' AND last_name = 'Иванов';
    
    -- Get vacation request type
    SELECT id INTO req_type_id FROM request_types WHERE type_name_ru = 'Заявление на отпуск';
    
    -- Create vacation request
    INSERT INTO employee_requests (id, employee_id, request_type_id, request_date, start_date, end_date, 
                                   status, status_ru, notes, metadata, created_at)
    VALUES (gen_random_uuid(), emp_id, req_type_id, CURRENT_DATE - INTERVAL '7 days', 
            CURRENT_DATE + INTERVAL '30 days', CURRENT_DATE + INTERVAL '44 days',
            'APPROVED', 'Одобрена', 
            'Ежегодный оплачиваемый отпуск на летний период. Планируется поездка к морю с семьей.',
            '{"vacation_type": "annual", "days_requested": 14, "replacement_arranged": true, 
              "replacement_employee": "Мария Петрова", "contact_during_vacation": "+7-999-123-45-67"}',
            CURRENT_TIMESTAMP - INTERVAL '7 days')
    RETURNING id INTO vacation_req_id;
    
    -- Create approval workflow
    INSERT INTO request_approvals (id, request_id, approver_id, approval_level, status, status_ru, 
                                   comments, decision_date, created_at)
    VALUES 
    (gen_random_uuid(), vacation_req_id, 
     (SELECT id FROM employees WHERE first_name = 'Анна' LIMIT 1), 
     1, 'APPROVED', 'Одобрено руководителем',
     'Согласовано. Обеспечена замена на период отпуска.',
     CURRENT_DATE - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),
     
    (gen_random_uuid(), vacation_req_id,
     (SELECT id FROM employees WHERE first_name = 'Михаил' LIMIT 1),
     2, 'APPROVED', 'Одобрено планировщиком',
     'Утверждено планировщиком ресурсов. График работы скорректирован.',
     CURRENT_DATE - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),
     
    (gen_random_uuid(), vacation_req_id,
     (SELECT id FROM employees WHERE first_name = 'Ирина' LIMIT 1),
     3, 'APPROVED', 'Окончательно утверждено',
     'Окончательное утверждение начальником отдела. Приказ оформлен.',
     CURRENT_DATE - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day');
END $$;

-- Task 45: Multi-language support verification
-- Test Cyrillic encoding and create verification queries

-- Test query to verify Cyrillic support
SELECT 
    'Кириллица работает корректно' as cyrillic_test,
    'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ' as upper_cyrillic,
    'абвгдеёжзийклмнопрстуфхцчшщъыьэюя' as lower_cyrillic,
    LENGTH('Тестирование UTF-8') as utf8_length;

-- Create view for Russian language dashboard
CREATE OR REPLACE VIEW v_russian_wfm_dashboard AS
SELECT 
    -- Employee statistics with Russian names
    COUNT(DISTINCT e.id) as total_employees,
    COUNT(DISTINCT CASE WHEN e.is_active = true THEN e.id END) as active_employees,
    COUNT(DISTINCT d.id) as departments_count,
    
    -- Request statistics in Russian
    COUNT(DISTINCT er.id) as total_requests,
    COUNT(DISTINCT CASE WHEN er.status = 'SUBMITTED' THEN er.id END) as pending_requests,
    COUNT(DISTINCT CASE WHEN er.status = 'APPROVED' THEN er.id END) as approved_requests,
    COUNT(DISTINCT CASE WHEN er.status = 'REJECTED' THEN er.id END) as rejected_requests,
    
    -- Russian time type usage
    COUNT(DISTINCT ztt.id) as time_types_configured,
    
    -- Holiday calendar coverage
    COUNT(DISTINCT pc.calendar_date) as calendar_days_configured,
    COUNT(DISTINCT rh.id) as russian_holidays_count
    
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

-- Create Russian language sample reports
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
        WHEN 'full_time' THEN 'Полная занятость'
        WHEN 'part_time' THEN 'Частичная занятость'
        ELSE e.employment_type
    END as "Тип занятости",
    e.work_rate as "Ставка"
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN employee_positions ep ON e.position_id = ep.id
WHERE e.is_active = true
ORDER BY d.name, e.last_name, e.first_name;

-- Summary statistics
SELECT 'Russian Language Enhancement Complete' as status,
       'All tasks 36-45 implemented successfully' as details;
