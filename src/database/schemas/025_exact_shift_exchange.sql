-- =============================================================================
-- 025_exact_shift_exchange.sql
-- EXACT SHIFT EXCHANGE "БИРЖА" SYSTEM - From BDD Specifications
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT shift exchange system as specified in BDD file 06
-- Based on: Live system testing with tabs "Мои"/"Доступные" and exact UI
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. EXCHANGE_REQUESTS - Main exchange request table (exact BDD structure)
-- =============================================================================
CREATE TABLE exchange_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Request identification
    request_number VARCHAR(50) NOT NULL UNIQUE, -- Auto-generated exchange number
    
    -- Offering employee (who wants to exchange their shift)
    offering_employee_tab_n VARCHAR(50) NOT NULL,
    offering_employee_name VARCHAR(200) NOT NULL, -- Cached for display
    
    -- Requesting employee (who responds to offer, nullable for open offers)
    requesting_employee_tab_n VARCHAR(50),
    requesting_employee_name VARCHAR(200),
    
    -- Exchange period details (exact BDD column: "Период")
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    period_description VARCHAR(500), -- Human readable period like "15-16 января"
    
    -- Exchange name/description (exact BDD column: "Название")
    exchange_name VARCHAR(500) NOT NULL,
    exchange_description TEXT,
    
    -- Timing details (exact BDD columns: "Начало", "Окончание")
    original_start_time TIME NOT NULL,
    original_end_time TIME NOT NULL,
    replacement_start_time TIME, -- When requesting specific replacement
    replacement_end_time TIME,
    
    -- Exchange status (exact BDD column: "Статус")
    exchange_status VARCHAR(50) DEFAULT 'АКТИВНОЕ' CHECK (
        exchange_status IN (
            'АКТИВНОЕ',          -- Active offer (available to respond)
            'В_ОЖИДАНИИ',        -- Waiting for approval/confirmation
            'ПРИНЯТО',           -- Accepted by requesting employee
            'ОТКЛОНЕНО',         -- Declined
            'ЗАВЕРШЕНО',         -- Completed exchange
            'ОТМЕНЕНО',          -- Cancelled by offering employee
            'ЗАКРЫТО'            -- Closed/expired
        )
    ),
    
    -- Exchange type (from other BDD files)
    exchange_type VARCHAR(50) DEFAULT 'ПРЕДЛОЖЕНИЕ' CHECK (
        exchange_type IN (
            'ПРЕДЛОЖЕНИЕ',       -- Open offer
            'ПРЯМОЙ_ОБМЕН',      -- Direct swap with specific person
            'ЗАПРОС',            -- Request for coverage
            'ОТГУЛ'              -- Time off request
        )
    ),
    
    -- Additional details
    compensation_offered VARCHAR(200), -- What's offered in return
    priority_level VARCHAR(20) DEFAULT 'ОБЫЧНЫЙ' CHECK (
        priority_level IN ('ВЫСОКИЙ', 'ОБЫЧНЫЙ', 'НИЗКИЙ')
    ),
    
    -- Timing and expiration
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Approval workflow
    requires_manager_approval BOOLEAN DEFAULT true,
    manager_approval_status VARCHAR(20) DEFAULT 'ОЖИДАНИЕ',
    approved_by VARCHAR(100),
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,
    
    CONSTRAINT fk_exchange_requests_offering 
        FOREIGN KEY (offering_employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT fk_exchange_requests_requesting 
        FOREIGN KEY (requesting_employee_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for exchange_requests
CREATE INDEX idx_exchange_requests_offering ON exchange_requests(offering_employee_tab_n);
CREATE INDEX idx_exchange_requests_requesting ON exchange_requests(requesting_employee_tab_n);
CREATE INDEX idx_exchange_requests_status ON exchange_requests(exchange_status);
CREATE INDEX idx_exchange_requests_period ON exchange_requests(period_start_date, period_end_date);

-- =============================================================================
-- 2. EXCHANGE_RESPONSES - Track responses to exchange offers
-- =============================================================================
CREATE TABLE exchange_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exchange_request_id UUID NOT NULL,
    
    -- Responding employee
    responding_employee_tab_n VARCHAR(50) NOT NULL,
    responding_employee_name VARCHAR(200) NOT NULL,
    
    -- Response details
    response_type VARCHAR(20) NOT NULL CHECK (
        response_type IN ('ОТКЛИК', 'ПРИНЯТИЕ', 'ОТКАЗ', 'ОТЗЫВ')
    ),
    response_message TEXT,
    
    -- Proposed terms (if different from original)
    proposed_start_time TIME,
    proposed_end_time TIME,
    proposed_compensation VARCHAR(200),
    
    -- Response timing
    responded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    response_status VARCHAR(20) DEFAULT 'АКТИВЕН' CHECK (
        response_status IN ('АКТИВЕН', 'ПРИНЯТ', 'ОТКЛОНЕН', 'ОТОЗВАН')
    ),
    
    CONSTRAINT fk_exchange_responses_request 
        FOREIGN KEY (exchange_request_id) REFERENCES exchange_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_exchange_responses_employee 
        FOREIGN KEY (responding_employee_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for exchange_responses
CREATE INDEX idx_exchange_responses_request ON exchange_responses(exchange_request_id);
CREATE INDEX idx_exchange_responses_employee ON exchange_responses(responding_employee_tab_n);

-- =============================================================================
-- 3. EXCHANGE_HISTORY - Complete audit trail
-- =============================================================================
CREATE TABLE exchange_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exchange_request_id UUID NOT NULL,
    
    -- Action details
    action_type VARCHAR(50) NOT NULL, -- 'CREATED', 'RESPONDED', 'APPROVED', 'COMPLETED', etc.
    action_description VARCHAR(500) NOT NULL,
    performed_by_tab_n VARCHAR(50),
    performed_by_name VARCHAR(200),
    
    -- Change details
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    change_details JSONB,
    
    -- Timing
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_exchange_history_request 
        FOREIGN KEY (exchange_request_id) REFERENCES exchange_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_exchange_history_employee 
        FOREIGN KEY (performed_by_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Index for exchange_history
CREATE INDEX idx_exchange_history_request ON exchange_history(exchange_request_id);
CREATE INDEX idx_exchange_history_timestamp ON exchange_history(action_timestamp);

-- =============================================================================
-- FUNCTIONS: Exchange System Logic
-- =============================================================================

-- Function to create exchange offer (exact BDD workflow)
CREATE OR REPLACE FUNCTION create_exchange_offer(
    p_offering_employee_tab_n VARCHAR(50),
    p_exchange_name VARCHAR(500),
    p_period_start_date DATE,
    p_period_end_date DATE,
    p_original_start_time TIME,
    p_original_end_time TIME,
    p_exchange_description TEXT DEFAULT NULL,
    p_compensation_offered VARCHAR(200) DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_request_id UUID;
    v_request_number VARCHAR(50);
    v_offering_employee zup_agent_data%ROWTYPE;
    v_period_description VARCHAR(500);
    v_result JSONB;
BEGIN
    -- Get offering employee details
    SELECT * INTO v_offering_employee
    FROM zup_agent_data
    WHERE tab_n = p_offering_employee_tab_n;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee not found: %', p_offering_employee_tab_n;
    END IF;
    
    -- Generate request number
    v_request_number := 'EXC-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD-HH24MI') || '-' || 
                       SUBSTRING(p_offering_employee_tab_n, 1, 3);
    
    -- Format period description (Russian format)
    v_period_description := TO_CHAR(p_period_start_date, 'DD.MM') || 
                           CASE WHEN p_period_start_date != p_period_end_date 
                                THEN ' - ' || TO_CHAR(p_period_end_date, 'DD.MM.YYYY')
                                ELSE '.YYYY' END;
    
    -- Create exchange request
    INSERT INTO exchange_requests (
        request_number,
        offering_employee_tab_n,
        offering_employee_name,
        period_start_date,
        period_end_date,
        period_description,
        exchange_name,
        exchange_description,
        original_start_time,
        original_end_time,
        exchange_type,
        compensation_offered,
        offer_expires_at
    ) VALUES (
        v_request_number,
        p_offering_employee_tab_n,
        v_offering_employee.lastname || ' ' || v_offering_employee.firstname,
        p_period_start_date,
        p_period_end_date,
        v_period_description,
        p_exchange_name,
        p_exchange_description,
        p_original_start_time,
        p_original_end_time,
        'ПРЕДЛОЖЕНИЕ',
        p_compensation_offered,
        CURRENT_TIMESTAMP + INTERVAL '7 days' -- Default 7-day expiration
    ) RETURNING id INTO v_request_id;
    
    -- Record history
    INSERT INTO exchange_history (
        exchange_request_id,
        action_type,
        action_description,
        performed_by_tab_n,
        performed_by_name,
        new_status
    ) VALUES (
        v_request_id,
        'CREATED',
        'Создано предложение обмена: ' || p_exchange_name,
        p_offering_employee_tab_n,
        v_offering_employee.lastname || ' ' || v_offering_employee.firstname,
        'АКТИВНОЕ'
    );
    
    v_result := jsonb_build_object(
        'request_id', v_request_id,
        'request_number', v_request_number,
        'offering_employee', v_offering_employee.lastname || ' ' || v_offering_employee.firstname,
        'exchange_name', p_exchange_name,
        'period', v_period_description,
        'status', 'АКТИВНОЕ',
        'expires_at', CURRENT_TIMESTAMP + INTERVAL '7 days'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to respond to exchange offer
CREATE OR REPLACE FUNCTION respond_to_exchange(
    p_exchange_request_id UUID,
    p_responding_employee_tab_n VARCHAR(50),
    p_response_type VARCHAR(20), -- 'ОТКЛИК', 'ПРИНЯТИЕ', 'ОТКАЗ'
    p_response_message TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_response_id UUID;
    v_exchange_request exchange_requests%ROWTYPE;
    v_responding_employee zup_agent_data%ROWTYPE;
    v_result JSONB;
BEGIN
    -- Get exchange request
    SELECT * INTO v_exchange_request
    FROM exchange_requests
    WHERE id = p_exchange_request_id AND exchange_status = 'АКТИВНОЕ';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Exchange request not found or not active: %', p_exchange_request_id;
    END IF;
    
    -- Get responding employee
    SELECT * INTO v_responding_employee
    FROM zup_agent_data
    WHERE tab_n = p_responding_employee_tab_n;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee not found: %', p_responding_employee_tab_n;
    END IF;
    
    -- Cannot respond to your own offer
    IF v_exchange_request.offering_employee_tab_n = p_responding_employee_tab_n THEN
        RAISE EXCEPTION 'Cannot respond to your own exchange offer';
    END IF;
    
    -- Create response
    INSERT INTO exchange_responses (
        exchange_request_id,
        responding_employee_tab_n,
        responding_employee_name,
        response_type,
        response_message
    ) VALUES (
        p_exchange_request_id,
        p_responding_employee_tab_n,
        v_responding_employee.lastname || ' ' || v_responding_employee.firstname,
        p_response_type,
        p_response_message
    ) RETURNING id INTO v_response_id;
    
    -- Update exchange request if accepted
    IF p_response_type = 'ПРИНЯТИЕ' THEN
        UPDATE exchange_requests SET
            requesting_employee_tab_n = p_responding_employee_tab_n,
            requesting_employee_name = v_responding_employee.lastname || ' ' || v_responding_employee.firstname,
            exchange_status = 'ПРИНЯТО',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_exchange_request_id;
        
        -- Record history
        INSERT INTO exchange_history (
            exchange_request_id,
            action_type,
            action_description,
            performed_by_tab_n,
            performed_by_name,
            old_status,
            new_status
        ) VALUES (
            p_exchange_request_id,
            'ACCEPTED',
            'Предложение принято сотрудником: ' || v_responding_employee.lastname || ' ' || v_responding_employee.firstname,
            p_responding_employee_tab_n,
            v_responding_employee.lastname || ' ' || v_responding_employee.firstname,
            'АКТИВНОЕ',
            'ПРИНЯТО'
        );
    ELSE
        -- Record response history
        INSERT INTO exchange_history (
            exchange_request_id,
            action_type,
            action_description,
            performed_by_tab_n,
            performed_by_name
        ) VALUES (
            p_exchange_request_id,
            'RESPONDED',
            'Отклик на предложение: ' || p_response_type,
            p_responding_employee_tab_n,
            v_responding_employee.lastname || ' ' || v_responding_employee.firstname
        );
    END IF;
    
    v_result := jsonb_build_object(
        'response_id', v_response_id,
        'exchange_request_id', p_exchange_request_id,
        'responding_employee', v_responding_employee.lastname || ' ' || v_responding_employee.firstname,
        'response_type', p_response_type,
        'exchange_status', CASE WHEN p_response_type = 'ПРИНЯТИЕ' THEN 'ПРИНЯТО' ELSE 'АКТИВНОЕ' END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Exchange System UI Data (Exact BDD Structure)
-- =============================================================================

-- View for "Мои" tab - My exchange requests (both offered and responded to)
CREATE VIEW v_exchange_my_requests AS
SELECT 
    er.id as exchange_id,
    er.request_number,
    
    -- Exact BDD columns
    er.period_description as "Период",
    er.exchange_name as "Название", 
    CASE er.exchange_status
        WHEN 'АКТИВНОЕ' THEN 'Активное'
        WHEN 'В_ОЖИДАНИИ' THEN 'В ожидании'
        WHEN 'ПРИНЯТО' THEN 'Принято'
        WHEN 'ОТКЛОНЕНО' THEN 'Отклонено'
        WHEN 'ЗАВЕРШЕНО' THEN 'Завершено'
        WHEN 'ОТМЕНЕНО' THEN 'Отменено'
        WHEN 'ЗАКРЫТО' THEN 'Закрыто'
    END as "Статус",
    er.original_start_time::TEXT as "Начало",
    er.original_end_time::TEXT as "Окончание",
    
    -- Additional fields for functionality
    er.offering_employee_tab_n,
    er.offering_employee_name,
    er.requesting_employee_tab_n,
    er.requesting_employee_name,
    er.exchange_description,
    er.compensation_offered,
    er.exchange_type,
    er.created_at,
    er.offer_expires_at,
    
    -- Response count
    (SELECT COUNT(*) FROM exchange_responses WHERE exchange_request_id = er.id) as response_count,
    
    -- User's role in this exchange
    'OFFERING' as user_role -- This view shows requests I offered
    
FROM exchange_requests er
WHERE er.offering_employee_tab_n = '{{CURRENT_USER_TAB_N}}' -- To be replaced by application

UNION ALL

-- Exchanges I responded to
SELECT 
    er.id as exchange_id,
    er.request_number,
    
    -- Exact BDD columns  
    er.period_description as "Период",
    er.exchange_name as "Название",
    CASE ers.response_status
        WHEN 'АКТИВЕН' THEN 'Отклик активен'
        WHEN 'ПРИНЯТ' THEN 'Отклик принят'
        WHEN 'ОТКЛОНЕН' THEN 'Отклик отклонен'
        WHEN 'ОТОЗВАН' THEN 'Отклик отозван'
    END as "Статус",
    er.original_start_time::TEXT as "Начало",
    er.original_end_time::TEXT as "Окончание",
    
    -- Additional fields
    er.offering_employee_tab_n,
    er.offering_employee_name,
    er.requesting_employee_tab_n,
    er.requesting_employee_name,
    er.exchange_description,
    er.compensation_offered,
    er.exchange_type,
    er.created_at,
    er.offer_expires_at,
    0 as response_count, -- Not applicable for responded exchanges
    
    'RESPONDING' as user_role -- This shows exchanges I responded to
    
FROM exchange_requests er
JOIN exchange_responses ers ON ers.exchange_request_id = er.id
WHERE ers.responding_employee_tab_n = '{{CURRENT_USER_TAB_N}}' -- To be replaced by application

ORDER BY created_at DESC;

-- View for "Доступные" tab - Available exchanges from others
CREATE VIEW v_exchange_available_requests AS
SELECT 
    er.id as exchange_id,
    er.request_number,
    
    -- Exact BDD columns
    er.period_description as "Период",
    er.exchange_name as "Название",
    CASE er.exchange_status
        WHEN 'АКТИВНОЕ' THEN 'Доступно'
        WHEN 'В_ОЖИДАНИИ' THEN 'В ожидании'
        WHEN 'ПРИНЯТО' THEN 'Принято'
        WHEN 'ОТКЛОНЕНО' THEN 'Отклонено'
        WHEN 'ЗАВЕРШЕНО' THEN 'Завершено'
        WHEN 'ОТМЕНЕНО' THEN 'Отменено'
        WHEN 'ЗАКРЫТО' THEN 'Закрыто'
    END as "Статус",
    er.original_start_time::TEXT as "Начало",
    er.original_end_time::TEXT as "Окончание",
    
    -- Additional display fields
    er.offering_employee_name as offered_by,
    er.exchange_description,
    er.compensation_offered,
    er.priority_level,
    er.created_at,
    er.offer_expires_at,
    
    -- Check if current user already responded
    EXISTS(
        SELECT 1 FROM exchange_responses 
        WHERE exchange_request_id = er.id 
        AND responding_employee_tab_n = '{{CURRENT_USER_TAB_N}}'
    ) as already_responded,
    
    -- Days until expiration
    CASE 
        WHEN er.offer_expires_at IS NOT NULL THEN
            EXTRACT(DAYS FROM (er.offer_expires_at - CURRENT_TIMESTAMP))
        ELSE NULL
    END as days_until_expiration
    
FROM exchange_requests er
WHERE er.exchange_status = 'АКТИВНОЕ'
AND er.offering_employee_tab_n != '{{CURRENT_USER_TAB_N}}' -- Don't show my own offers
AND (er.offer_expires_at IS NULL OR er.offer_expires_at > CURRENT_TIMESTAMP) -- Not expired
ORDER BY er.priority_level DESC, er.created_at DESC;

-- View for empty state handling (BDD: "Отсутствуют данные")
CREATE VIEW v_exchange_empty_state AS
SELECT 
    'no_data' as state_type,
    'Отсутствуют данные' as message_ru,
    'No data available' as message_en,
    CASE 
        WHEN NOT EXISTS(SELECT 1 FROM exchange_requests) THEN 'no_exchanges_exist'
        WHEN NOT EXISTS(SELECT 1 FROM exchange_requests WHERE offering_employee_tab_n = '{{CURRENT_USER_TAB_N}}') THEN 'no_my_exchanges'
        WHEN NOT EXISTS(SELECT 1 FROM exchange_requests WHERE exchange_status = 'АКТИВНОЕ' AND offering_employee_tab_n != '{{CURRENT_USER_TAB_N}}') THEN 'no_available_exchanges'
        ELSE 'unknown'
    END as empty_reason;

-- View for exchange system statistics (for demo)
CREATE VIEW v_exchange_system_stats AS
SELECT 
    'Exchange System Statistics' as section_name,
    COUNT(*) as total_exchanges,
    COUNT(*) FILTER (WHERE exchange_status = 'АКТИВНОЕ') as active_exchanges,
    COUNT(*) FILTER (WHERE exchange_status = 'ПРИНЯТО') as accepted_exchanges,
    COUNT(*) FILTER (WHERE exchange_status = 'ЗАВЕРШЕНО') as completed_exchanges,
    COUNT(DISTINCT offering_employee_tab_n) as employees_offering,
    COUNT(DISTINCT requesting_employee_tab_n) as employees_requesting,
    ROUND(AVG(
        CASE WHEN offer_expires_at IS NOT NULL 
             THEN EXTRACT(EPOCH FROM (offer_expires_at - created_at)) / 86400.0 
             ELSE NULL END
    ), 1) as avg_offer_duration_days,
    'Exact BDD implementation: Мои/Доступные tabs' as implementation_status,
    NOW() as report_time
FROM exchange_requests
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- =============================================================================
-- Sample data for demo
-- =============================================================================

-- Insert sample exchange offers
INSERT INTO exchange_requests (
    request_number, offering_employee_tab_n, offering_employee_name,
    period_start_date, period_end_date, period_description,
    exchange_name, exchange_description, original_start_time, original_end_time,
    exchange_type, compensation_offered
)
SELECT 
    'EXC-' || TO_CHAR(CURRENT_DATE + i, 'YYYYMMDD') || '-' || LPAD(i::TEXT, 3, '0'),
    zda.tab_n,
    zda.lastname || ' ' || zda.firstname,
    CURRENT_DATE + i,
    CURRENT_DATE + i + 1,
    TO_CHAR(CURRENT_DATE + i, 'DD.MM') || ' - ' || TO_CHAR(CURRENT_DATE + i + 1, 'DD.MM.YYYY'),
    CASE (i % 4)
        WHEN 0 THEN 'Обмен вечерней смены на утреннюю'
        WHEN 1 THEN 'Нужен выходной в субботу'
        WHEN 2 THEN 'Готов взять дополнительную смену'
        ELSE 'Обмен смены по семейным обстоятельствам'
    END,
    'Детали обмена: ' || (i * 10) || ' минут дополнительного времени',
    CASE (i % 3)
        WHEN 0 THEN '09:00'::TIME
        WHEN 1 THEN '14:00'::TIME
        ELSE '18:00'::TIME
    END,
    CASE (i % 3)
        WHEN 0 THEN '18:00'::TIME
        WHEN 1 THEN '23:00'::TIME
        ELSE '03:00'::TIME
    END,
    'ПРЕДЛОЖЕНИЕ',
    CASE (i % 2)
        WHEN 0 THEN 'Готов взять смену в ответ'
        ELSE 'Компенсация за неудобство'
    END
FROM generate_series(1, 10) i
CROSS JOIN (SELECT * FROM zup_agent_data LIMIT 5) zda
WHERE random() < 0.3;

COMMENT ON TABLE exchange_requests IS 'Exact shift exchange system from BDD - "Биржа" with Мои/Доступные tabs';
COMMENT ON TABLE exchange_responses IS 'Responses to exchange offers with Russian workflow terms';
COMMENT ON VIEW v_exchange_my_requests IS 'Exact BDD "Мои" tab with columns: Период, Название, Статус, Начало, Окончание';
COMMENT ON VIEW v_exchange_available_requests IS 'Exact BDD "Доступные" tab showing available exchanges from others';