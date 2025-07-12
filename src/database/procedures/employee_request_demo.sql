-- =====================================================================================
-- Employee Request Management - Demo Data and Procedures
-- Purpose: Generate realistic test data and demo procedures for Employee Request system
-- Created for: DATABASE-OPUS Agent
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- PART 1: TEST DATA GENERATION
-- =====================================================================================

-- 1.1 Generate 100 demo employees with Russian names and roles
CREATE OR REPLACE FUNCTION generate_demo_employees() RETURNS void AS $$
DECLARE
    v_first_names TEXT[] := ARRAY[
        'Александр', 'Михаил', 'Максим', 'Иван', 'Артём', 'Дмитрий', 'Даниил', 'Егор', 'Андрей', 'Кирилл',
        'Анна', 'Мария', 'Елена', 'Ольга', 'Наталья', 'Екатерина', 'Татьяна', 'Ирина', 'Светлана', 'Юлия'
    ];
    v_last_names TEXT[] := ARRAY[
        'Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 'Васильев', 'Соколов', 'Михайлов', 'Новиков',
        'Федоров', 'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Семенов', 'Егоров', 'Павлов', 'Козлов', 'Степанов'
    ];
    v_patronymics TEXT[] := ARRAY[
        'Александрович', 'Михайлович', 'Иванович', 'Сергеевич', 'Андреевич', 'Дмитриевич', 'Владимирович', 'Николаевич',
        'Александровна', 'Михайловна', 'Ивановна', 'Сергеевна', 'Андреевна', 'Дмитриевна', 'Владимировна', 'Николаевна'
    ];
    v_departments TEXT[] := ARRAY[
        'Колл-центр', 'Техподдержка', 'Продажи', 'Клиентский сервис', 'Back-office', 'HR', 'IT', 'Финансы'
    ];
    v_positions TEXT[] := ARRAY[
        'Оператор', 'Старший оператор', 'Супервизор', 'Менеджер', 'Специалист', 'Ведущий специалист'
    ];
    v_employee_id INTEGER;
    v_is_female BOOLEAN;
BEGIN
    -- Create employees table if not exists
    CREATE TABLE IF NOT EXISTS employees (
        employee_id SERIAL PRIMARY KEY,
        full_name VARCHAR(255) NOT NULL,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        patronymic VARCHAR(100),
        department VARCHAR(100),
        position VARCHAR(100),
        supervisor_id INTEGER,
        hire_date DATE,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create users table if not exists (for authentication)
    CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY,
        username VARCHAR(100) UNIQUE,
        email VARCHAR(255),
        role VARCHAR(50),
        employee_id INTEGER REFERENCES employees(employee_id)
    );

    -- Clear existing demo data
    DELETE FROM employees WHERE employee_id BETWEEN 1000 AND 1099;
    DELETE FROM users WHERE user_id BETWEEN 1000 AND 1099;

    -- Generate 100 employees
    FOR v_employee_id IN 1000..1099 LOOP
        v_is_female := (v_employee_id % 2 = 0);
        
        INSERT INTO employees (
            employee_id,
            first_name,
            last_name,
            patronymic,
            full_name,
            department,
            position,
            supervisor_id,
            hire_date
        ) VALUES (
            v_employee_id,
            v_first_names[1 + (v_employee_id % 10) + (CASE WHEN v_is_female THEN 10 ELSE 0 END)],
            v_last_names[1 + (v_employee_id % 20)] || (CASE WHEN v_is_female THEN 'а' ELSE '' END),
            v_patronymics[1 + (v_employee_id % 8) + (CASE WHEN v_is_female THEN 8 ELSE 0 END)],
            v_last_names[1 + (v_employee_id % 20)] || (CASE WHEN v_is_female THEN 'а' ELSE '' END) || ' ' ||
            v_first_names[1 + (v_employee_id % 10) + (CASE WHEN v_is_female THEN 10 ELSE 0 END)] || ' ' ||
            v_patronymics[1 + (v_employee_id % 8) + (CASE WHEN v_is_female THEN 8 ELSE 0 END)],
            v_departments[1 + (v_employee_id % 8)],
            v_positions[1 + (v_employee_id % 6)],
            CASE 
                WHEN v_employee_id % 10 = 0 THEN NULL -- Top managers
                WHEN v_employee_id % 5 = 0 THEN 1000 + ((v_employee_id / 10) * 10) -- Supervisors
                ELSE 1000 + ((v_employee_id / 5) * 5) -- Regular employees
            END,
            CURRENT_DATE - ((random() * 1825)::INTEGER || ' days')::INTERVAL -- 0-5 years
        );

        -- Create corresponding user
        INSERT INTO users (user_id, username, email, role, employee_id) VALUES (
            v_employee_id,
            'user' || v_employee_id,
            'user' || v_employee_id || '@company.ru',
            CASE 
                WHEN v_employee_id % 10 = 0 THEN 'manager'
                WHEN v_employee_id % 5 = 0 THEN 'supervisor'
                ELSE 'employee'
            END,
            v_employee_id
        );
    END LOOP;

    RAISE NOTICE 'Generated 100 demo employees with hierarchy';
END;
$$ LANGUAGE plpgsql;

-- Execute employee generation
SELECT generate_demo_employees();

-- 1.2 Generate 500+ historical requests with realistic data
CREATE OR REPLACE FUNCTION generate_historical_requests() RETURNS void AS $$
DECLARE
    v_request_id INTEGER;
    v_employee_id INTEGER;
    v_request_type VARCHAR;
    v_start_date DATE;
    v_duration INTEGER;
    v_status VARCHAR;
    v_created_date TIMESTAMPTZ;
    v_reasons_sick TEXT[] := ARRAY[
        'ОРВИ', 'Грипп', 'Больничный лист', 'Плановая операция', 'Травма', 
        'Обследование', 'Лечение зубов', 'Головная боль', 'Высокая температура'
    ];
    v_reasons_dayoff TEXT[] := ARRAY[
        'Семейные обстоятельства', 'Переработка в выходные', 'Личные дела', 
        'Визит к врачу', 'Получение документов', 'Переезд', 'Свадьба друга'
    ];
    v_reasons_vacation TEXT[] := ARRAY[
        'Семейный отдых', 'Поездка за границу', 'Дача', 'Свадьба', 
        'Уход за ребенком', 'Ремонт квартиры', 'Отдых после проекта'
    ];
BEGIN
    -- Clear existing demo requests
    DELETE FROM request_history WHERE request_id IN (
        SELECT request_id FROM requests WHERE employee_id BETWEEN 1000 AND 1099
    );
    DELETE FROM request_approvals WHERE request_id IN (
        SELECT request_id FROM requests WHERE employee_id BETWEEN 1000 AND 1099
    );
    DELETE FROM shift_exchanges WHERE request_id IN (
        SELECT request_id FROM requests WHERE employee_id BETWEEN 1000 AND 1099
    );
    DELETE FROM notifications WHERE recipient_id BETWEEN 1000 AND 1099;
    DELETE FROM requests WHERE employee_id BETWEEN 1000 AND 1099;

    -- Generate 500 requests over the past year
    FOR v_request_id IN 1..500 LOOP
        v_employee_id := 1000 + (random() * 99)::INTEGER;
        v_request_type := (ARRAY['sick_leave', 'day_off', 'unscheduled_vacation', 'shift_exchange'])
            [1 + (random() * 3)::INTEGER];
        
        -- Random date in the past year
        v_created_date := NOW() - ((random() * 365)::INTEGER || ' days')::INTERVAL;
        v_start_date := v_created_date::DATE + ((random() * 30)::INTEGER || ' days')::INTERVAL;
        
        -- Duration based on type
        v_duration := CASE v_request_type
            WHEN 'sick_leave' THEN 1 + (random() * 6)::INTEGER -- 1-7 days
            WHEN 'day_off' THEN 1 + (random() * 2)::INTEGER -- 1-3 days
            WHEN 'unscheduled_vacation' THEN 3 + (random() * 11)::INTEGER -- 3-14 days
            ELSE 1 -- shift exchange is always 1 day
        END;
        
        -- Status distribution: 70% approved, 20% completed, 5% rejected, 5% pending
        v_status := CASE 
            WHEN random() < 0.7 THEN 'approved'
            WHEN random() < 0.9 THEN 'completed'
            WHEN random() < 0.95 THEN 'rejected'
            ELSE 'under_review'
        END;
        
        -- If the request is old and approved, mark as completed
        IF v_status = 'approved' AND v_start_date < CURRENT_DATE THEN
            v_status := 'completed';
        END IF;

        -- Insert request
        INSERT INTO requests (
            request_type, employee_id, status, 
            start_date, end_date, comment,
            created_at, created_by, updated_at
        ) VALUES (
            v_request_type,
            v_employee_id,
            v_status,
            v_start_date,
            v_start_date + (v_duration || ' days')::INTERVAL,
            CASE v_request_type
                WHEN 'sick_leave' THEN v_reasons_sick[1 + (random() * 8)::INTEGER]
                WHEN 'day_off' THEN v_reasons_dayoff[1 + (random() * 6)::INTEGER]
                WHEN 'unscheduled_vacation' THEN v_reasons_vacation[1 + (random() * 6)::INTEGER]
                ELSE 'Обмен сменами с коллегой'
            END,
            v_created_date,
            v_employee_id,
            v_created_date + ((random() * 2)::INTEGER || ' days')::INTERVAL
        );
        
        -- Create approval records
        PERFORM create_demo_approvals(
            currval('requests_request_id_seq')::INTEGER,
            v_employee_id,
            v_request_type,
            v_status,
            v_created_date
        );
    END LOOP;

    RAISE NOTICE 'Generated 500 historical requests';
END;
$$ LANGUAGE plpgsql;

-- Helper function to create approval records
CREATE OR REPLACE FUNCTION create_demo_approvals(
    p_request_id INTEGER,
    p_employee_id INTEGER,
    p_request_type VARCHAR,
    p_status VARCHAR,
    p_created_date TIMESTAMPTZ
) RETURNS void AS $$
DECLARE
    v_supervisor_id INTEGER;
    v_approval_status VARCHAR;
    v_approval_date TIMESTAMPTZ;
BEGIN
    -- Get supervisor
    SELECT supervisor_id INTO v_supervisor_id
    FROM employees WHERE employee_id = p_employee_id;
    
    IF v_supervisor_id IS NULL THEN
        v_supervisor_id := 1000; -- Default to first manager
    END IF;
    
    -- Determine approval status based on request status
    v_approval_status := CASE p_status
        WHEN 'approved' THEN 'approved'
        WHEN 'completed' THEN 'approved'
        WHEN 'rejected' THEN 'rejected'
        WHEN 'under_review' THEN 'pending'
        ELSE 'pending'
    END;
    
    v_approval_date := CASE 
        WHEN v_approval_status = 'pending' THEN NULL
        ELSE p_created_date + ((random() * 2)::INTEGER || ' days')::INTERVAL
    END;
    
    -- Create first level approval
    INSERT INTO request_approvals (
        request_id, approver_id, approval_level, 
        approval_status, approval_date, comments
    ) VALUES (
        p_request_id, v_supervisor_id, 1,
        v_approval_status, v_approval_date,
        CASE v_approval_status
            WHEN 'approved' THEN 'Одобрено'
            WHEN 'rejected' THEN 'Отклонено: ' || (ARRAY['Нет замены', 'Критический период', 'Превышен лимит'])[1 + (random() * 2)::INTEGER]
            ELSE NULL
        END
    );
    
    -- Create second level approval for longer vacations
    IF p_request_type = 'unscheduled_vacation' AND p_status IN ('approved', 'completed') THEN
        INSERT INTO request_approvals (
            request_id, approver_id, approval_level, 
            approval_status, approval_date, comments
        ) VALUES (
            p_request_id, 1000, 2, -- Department head
            'approved', v_approval_date + INTERVAL '1 hour',
            'Согласовано руководством'
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Execute request generation
SELECT generate_historical_requests();

-- =====================================================================================
-- PART 2: DEMO PROCEDURES
-- =====================================================================================

-- 2.1 Create sick leave request with automatic workflow
CREATE OR REPLACE FUNCTION create_sick_leave_request(
    p_employee_id INTEGER,
    p_start_date DATE,
    p_days INTEGER,
    p_reason TEXT DEFAULT 'Больничный лист'
) RETURNS TABLE (
    request_id INTEGER,
    status VARCHAR,
    approver_name VARCHAR,
    message TEXT
) AS $$
DECLARE
    v_request_id INTEGER;
    v_supervisor_id INTEGER;
    v_supervisor_name VARCHAR;
BEGIN
    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        RAISE EXCEPTION 'Employee % not found', p_employee_id;
    END IF;
    
    -- Get supervisor
    SELECT e.supervisor_id, s.full_name 
    INTO v_supervisor_id, v_supervisor_name
    FROM employees e
    LEFT JOIN employees s ON e.supervisor_id = s.employee_id
    WHERE e.employee_id = p_employee_id;
    
    -- Create the request
    v_request_id := create_employee_request(
        'sick_leave',
        p_employee_id,
        p_start_date,
        p_start_date + (p_days - 1),
        p_reason,
        p_employee_id
    );
    
    -- Return summary
    RETURN QUERY
    SELECT 
        v_request_id,
        'under_review'::VARCHAR,
        v_supervisor_name,
        ('Заявка на больничный создана. Ожидает одобрения от ' || COALESCE(v_supervisor_name, 'руководителя'))::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 2.2 Approve request with notification
CREATE OR REPLACE FUNCTION approve_request(
    p_request_id INTEGER,
    p_approver_id INTEGER,
    p_comments TEXT DEFAULT 'Одобрено'
) RETURNS TABLE (
    success BOOLEAN,
    new_status VARCHAR,
    next_approver VARCHAR,
    message TEXT
) AS $$
DECLARE
    v_result BOOLEAN;
    v_request RECORD;
    v_next_approver VARCHAR;
BEGIN
    -- Get request details
    SELECT r.*, e.full_name as employee_name
    INTO v_request
    FROM requests r
    JOIN employees e ON r.employee_id = e.employee_id
    WHERE r.request_id = p_request_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, NULL::VARCHAR, 'Заявка не найдена'::TEXT;
        RETURN;
    END IF;
    
    -- Process approval
    v_result := process_request_approval(p_request_id, p_approver_id, 'approved', p_comments);
    
    -- Get updated status
    SELECT status INTO v_request.status 
    FROM requests WHERE request_id = p_request_id;
    
    -- Check for next approver
    SELECT e.full_name INTO v_next_approver
    FROM request_approvals ra
    JOIN employees e ON ra.approver_id = e.employee_id
    WHERE ra.request_id = p_request_id AND ra.approval_status = 'pending'
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        v_result,
        v_request.status,
        v_next_approver,
        CASE 
            WHEN v_request.status = 'approved' THEN 
                'Заявка полностью одобрена и отправлена в 1С'
            WHEN v_next_approver IS NOT NULL THEN 
                'Заявка одобрена. Ожидает согласования от ' || v_next_approver
            ELSE 
                'Заявка обработана'
        END::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 2.3 Process shift exchange
CREATE OR REPLACE FUNCTION process_shift_exchange(
    p_employee_from INTEGER,
    p_employee_to INTEGER,
    p_exchange_date DATE,
    p_shift_id INTEGER,
    p_reason TEXT DEFAULT 'Личные обстоятельства'
) RETURNS TABLE (
    request_id INTEGER,
    status VARCHAR,
    message TEXT
) AS $$
DECLARE
    v_request_id INTEGER;
    v_exchange_data JSONB;
BEGIN
    -- Validate both employees exist
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_from) OR
       NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_to) THEN
        RAISE EXCEPTION 'Invalid employee IDs';
    END IF;
    
    -- Build exchange data
    v_exchange_data := jsonb_build_object(
        'original_shift_id', p_shift_id,
        'exchange_date', p_exchange_date,
        'accepting_employee_id', p_employee_to
    );
    
    -- Create shift exchange request
    v_request_id := create_employee_request(
        'shift_exchange',
        p_employee_from,
        p_exchange_date,
        p_exchange_date,
        p_reason || '. Обмен с сотрудником ID: ' || p_employee_to,
        p_employee_from,
        v_exchange_data
    );
    
    -- Send notification to accepting employee
    INSERT INTO notifications (
        recipient_id, notification_type, title, message,
        related_entity_type, related_entity_id, priority
    ) 
    SELECT 
        p_employee_to,
        'shift_exchange_offer',
        'Предложение обмена сменой',
        e.full_name || ' предлагает обменяться сменой ' || p_exchange_date,
        'shift_exchange',
        v_request_id,
        'high'
    FROM employees e WHERE e.employee_id = p_employee_from;
    
    RETURN QUERY
    SELECT 
        v_request_id,
        'under_review'::VARCHAR,
        'Запрос на обмен сменами создан. Ожидает подтверждения от коллеги'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 2.4 Generate request analytics
CREATE OR REPLACE FUNCTION generate_request_analytics(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    metric VARCHAR,
    value NUMERIC,
    details TEXT
) AS $$
BEGIN
    -- Total requests
    RETURN QUERY
    SELECT 
        'Всего заявок'::VARCHAR,
        COUNT(*)::NUMERIC,
        'За период с ' || p_start_date || ' по ' || p_end_date
    FROM requests
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;
    
    -- By type
    RETURN QUERY
    SELECT 
        'Заявок типа: ' || rt.type_name_ru,
        COUNT(*)::NUMERIC,
        ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER(), 0), 1) || '% от общего числа'
    FROM requests r
    JOIN request_types rt ON r.request_type = rt.type_code
    WHERE r.created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY rt.type_name_ru;
    
    -- By status
    RETURN QUERY
    SELECT 
        'Статус: ' || 
        CASE status
            WHEN 'approved' THEN 'Одобрено'
            WHEN 'rejected' THEN 'Отклонено'
            WHEN 'completed' THEN 'Завершено'
            WHEN 'under_review' THEN 'На рассмотрении'
            ELSE status
        END,
        COUNT(*)::NUMERIC,
        'Средняя длительность: ' || 
        ROUND(AVG(EXTRACT(EPOCH FROM (end_date - start_date)) / 86400), 1) || ' дней'
    FROM requests
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY status;
    
    -- Average processing time
    RETURN QUERY
    SELECT 
        'Среднее время обработки'::VARCHAR,
        ROUND(AVG(
            EXTRACT(EPOCH FROM (ra.approval_date - r.created_at)) / 3600
        ), 1)::NUMERIC,
        'часов от создания до решения'::TEXT
    FROM requests r
    JOIN request_approvals ra ON r.request_id = ra.request_id
    WHERE r.created_at::DATE BETWEEN p_start_date AND p_end_date
        AND ra.approval_date IS NOT NULL
        AND ra.approval_level = 1;
    
    -- Top requesters
    RETURN QUERY
    SELECT 
        'Топ заявитель'::VARCHAR,
        r.employee_id::NUMERIC,
        e.full_name || ' (' || COUNT(*) || ' заявок)'
    FROM requests r
    JOIN employees e ON r.employee_id = e.employee_id
    WHERE r.created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY r.employee_id, e.full_name
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- PART 3: INTEGRATION PROCEDURES
-- =====================================================================================

-- 3.1 Mock 1C ZUP sync procedure
CREATE OR REPLACE FUNCTION mock_1c_zup_sync() RETURNS TABLE (
    processed INTEGER,
    success INTEGER,
    failed INTEGER,
    details TEXT
) AS $$
DECLARE
    v_record RECORD;
    v_processed INTEGER := 0;
    v_success INTEGER := 0;
    v_failed INTEGER := 0;
BEGIN
    -- Process pending integration queue items
    FOR v_record IN 
        SELECT * FROM integration_queue 
        WHERE integration_type = '1c_zup' 
            AND status = 'pending'
            AND scheduled_at <= NOW()
        ORDER BY created_at
        LIMIT 50
    LOOP
        v_processed := v_processed + 1;
        
        -- Simulate processing with 95% success rate
        IF random() > 0.05 THEN
            -- Success
            UPDATE integration_queue
            SET status = 'completed',
                processed_at = NOW(),
                response_data = jsonb_build_object(
                    'document_number', 'БЛ-' || to_char(NOW(), 'YYYYMMDD') || '-' || v_record.queue_id,
                    'status', 'registered',
                    'processed_by', '1C:ЗУП 3.1'
                )
            WHERE queue_id = v_record.queue_id;
            
            v_success := v_success + 1;
        ELSE
            -- Failure
            UPDATE integration_queue
            SET status = 'failed',
                attempts = attempts + 1,
                error_message = (ARRAY[
                    'Connection timeout',
                    'Invalid employee ID in 1C',
                    'Document already exists',
                    'Permission denied'
                ])[1 + (random() * 3)::INTEGER],
                next_retry_at = NOW() + (v_record.attempts + 1) * INTERVAL '10 minutes'
            WHERE queue_id = v_record.queue_id;
            
            v_failed := v_failed + 1;
        END IF;
    END LOOP;
    
    RETURN QUERY
    SELECT 
        v_processed,
        v_success,
        v_failed,
        ('Обработано записей: ' || v_processed || 
         ', успешно: ' || v_success || 
         ', с ошибками: ' || v_failed)::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 3.2 Update schedule after approval
CREATE OR REPLACE FUNCTION update_schedule_after_approval(
    p_request_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_request RECORD;
    v_date DATE;
BEGIN
    -- Get approved request details
    SELECT r.*, rt.integration_config
    INTO v_request
    FROM requests r
    JOIN request_types rt ON r.request_type = rt.type_code
    WHERE r.request_id = p_request_id
        AND r.status = 'approved';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Create schedule entries for each day of absence
    FOR v_date IN 
        SELECT generate_series(v_request.start_date, v_request.end_date, '1 day'::INTERVAL)::DATE
    LOOP
        -- This would integrate with actual schedule system
        -- For demo, we'll insert into a mock table
        INSERT INTO integration_queue (
            integration_type, entity_type, entity_id, operation, payload
        ) VALUES (
            'schedule_system',
            'absence',
            p_request_id,
            'mark_absence',
            jsonb_build_object(
                'employee_id', v_request.employee_id,
                'date', v_date,
                'absence_type', v_request.integration_config->>'code',
                'reason', v_request.request_type,
                'hours', 8
            )
        );
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 3.3 Notification queue processor
CREATE OR REPLACE FUNCTION process_notification_queue() RETURNS TABLE (
    sent INTEGER,
    failed INTEGER,
    details TEXT
) AS $$
DECLARE
    v_notification RECORD;
    v_sent INTEGER := 0;
    v_failed INTEGER := 0;
BEGIN
    -- Process unset notifications
    FOR v_notification IN 
        SELECT * FROM notifications 
        WHERE NOT is_sent 
            AND created_at > NOW() - INTERVAL '7 days'
        ORDER BY priority DESC, created_at
        LIMIT 100
    LOOP
        -- Simulate sending (email, push, etc.)
        IF 'email' = ANY(v_notification.delivery_methods) THEN
            -- Mock email sending
            UPDATE notifications
            SET is_sent = TRUE,
                sent_at = NOW()
            WHERE notification_id = v_notification.notification_id;
            
            v_sent := v_sent + 1;
        ELSE
            -- In-app only
            UPDATE notifications
            SET is_sent = TRUE,
                sent_at = NOW()
            WHERE notification_id = v_notification.notification_id;
            
            v_sent := v_sent + 1;
        END IF;
    END LOOP;
    
    RETURN QUERY
    SELECT 
        v_sent,
        v_failed,
        ('Отправлено уведомлений: ' || v_sent)::TEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- PART 4: DEMO SCENARIOS
-- =====================================================================================

-- 4.1 Create a complete demo scenario
CREATE OR REPLACE FUNCTION run_demo_scenario() RETURNS TABLE (
    step INTEGER,
    action TEXT,
    result TEXT
) AS $$
DECLARE
    v_request_id INTEGER;
    v_step INTEGER := 0;
BEGIN
    -- Step 1: Create sick leave request
    v_step := v_step + 1;
    SELECT request_id INTO v_request_id
    FROM create_sick_leave_request(
        1025, -- Employee: regular operator
        CURRENT_DATE + 2,
        3,
        'Плановое медицинское обследование'
    );
    
    RETURN QUERY SELECT v_step, 'Создание заявки на больничный'::TEXT, 
        'Заявка #' || v_request_id || ' создана'::TEXT;
    
    -- Step 2: Show pending approval
    v_step := v_step + 1;
    RETURN QUERY 
    SELECT 
        v_step, 
        'Проверка ожидающих согласований'::TEXT,
        'Ожидает: ' || COUNT(*) || ' заявок'::TEXT
    FROM v_pending_approvals
    WHERE approver_id = 1020; -- Supervisor
    
    -- Step 3: Approve request
    v_step := v_step + 1;
    RETURN QUERY
    SELECT 
        v_step,
        'Согласование заявки'::TEXT,
        message
    FROM approve_request(v_request_id, 1020, 'Согласовано. Выздоравливайте!');
    
    -- Step 4: Process integrations
    v_step := v_step + 1;
    RETURN QUERY
    SELECT 
        v_step,
        'Синхронизация с 1С:ЗУП'::TEXT,
        details
    FROM mock_1c_zup_sync();
    
    -- Step 5: Show analytics
    v_step := v_step + 1;
    RETURN QUERY
    SELECT 
        v_step,
        'Аналитика за текущий месяц'::TEXT,
        'Всего заявок: ' || value::TEXT
    FROM generate_request_analytics()
    WHERE metric = 'Всего заявок'
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- PART 5: USEFUL QUERIES FOR DEMO
-- =====================================================================================

-- View current workload
CREATE OR REPLACE VIEW v_supervisor_workload AS
SELECT 
    s.employee_id as supervisor_id,
    s.full_name as supervisor_name,
    COUNT(DISTINCT e.employee_id) as team_size,
    COUNT(DISTINCT ra.request_id) FILTER (WHERE ra.approval_status = 'pending') as pending_approvals,
    COUNT(DISTINCT r.request_id) FILTER (WHERE r.created_at > NOW() - INTERVAL '30 days') as monthly_requests,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (ra.approval_date - ra.created_at)) / 3600
    ) FILTER (WHERE ra.approval_date IS NOT NULL), 1) as avg_approval_time_hours
FROM employees s
LEFT JOIN employees e ON s.employee_id = e.supervisor_id
LEFT JOIN request_approvals ra ON s.employee_id = ra.approver_id
LEFT JOIN requests r ON e.employee_id = r.employee_id
WHERE s.position IN ('Супервизор', 'Менеджер')
GROUP BY s.employee_id, s.full_name
ORDER BY pending_approvals DESC;

-- Dashboard summary
CREATE OR REPLACE VIEW v_request_dashboard AS
SELECT 
    COUNT(*) FILTER (WHERE created_at::DATE = CURRENT_DATE) as today_requests,
    COUNT(*) FILTER (WHERE status = 'under_review') as pending_requests,
    COUNT(*) FILTER (WHERE status = 'approved' AND created_at > NOW() - INTERVAL '7 days') as week_approved,
    COUNT(*) FILTER (WHERE status = 'rejected' AND created_at > NOW() - INTERVAL '7 days') as week_rejected,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'approved' AND created_at > NOW() - INTERVAL '30 days') * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '30 days'), 0), 
        1
    ) as approval_rate_pct,
    COUNT(DISTINCT employee_id) FILTER (WHERE created_at > NOW() - INTERVAL '30 days') as active_requesters
FROM requests;

COMMIT;

-- =====================================================================================
-- DEMO EXECUTION EXAMPLES
-- =====================================================================================

/*
-- 1. Run complete demo scenario
SELECT * FROM run_demo_scenario();

-- 2. View supervisor workload
SELECT * FROM v_supervisor_workload;

-- 3. Check dashboard
SELECT * FROM v_request_dashboard;

-- 4. Create various request types
SELECT * FROM create_sick_leave_request(1050, CURRENT_DATE + 1, 2, 'Простуда');

-- 5. Process shift exchange
SELECT * FROM process_shift_exchange(1030, 1031, CURRENT_DATE + 5, 101);

-- 6. Generate monthly analytics
SELECT * FROM generate_request_analytics(
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'
);

-- 7. Process integration queues
SELECT * FROM mock_1c_zup_sync();
SELECT * FROM process_notification_queue();

-- 8. View pending approvals for specific supervisor
SELECT * FROM v_pending_approvals WHERE approver_id = 1015;

-- 9. Check employee request history
SELECT * FROM v_employee_request_summary WHERE employee_id = 1025;
*/