-- =============================================================================
-- 021_argus_request_workflow.sql
-- EXACT ARGUS MULTI-STAGE REQUEST WORKFLOW - Russian Terminology
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT Argus request workflow from BDD specifications
-- Based on: BDD multi-stage approval workflow with Russian UI terms
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ARGUS_REQUEST_TYPES - Request type definitions from BDD
-- =============================================================================
CREATE TABLE argus_request_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_code VARCHAR(50) NOT NULL UNIQUE,
    type_name_ru VARCHAR(200) NOT NULL, -- Exact Russian names from BDD
    type_name_en VARCHAR(200) NOT NULL,
    description_ru TEXT,
    
    -- Request characteristics from BDD specs
    requires_calendar_integration BOOLEAN DEFAULT false,
    requires_manager_approval BOOLEAN DEFAULT true,
    requires_hr_approval BOOLEAN DEFAULT false,
    requires_documentation BOOLEAN DEFAULT false,
    
    -- Time constraints
    advance_notice_days INTEGER DEFAULT 14, -- Days in advance required
    max_duration_days INTEGER, -- Maximum duration if applicable
    
    -- Integration requirements
    creates_zup_document BOOLEAN DEFAULT true,
    zup_document_type VARCHAR(100),
    affects_schedule BOOLEAN DEFAULT true,
    affects_vacation_balance BOOLEAN DEFAULT false,
    
    -- UI configuration
    ui_icon VARCHAR(50),
    ui_color VARCHAR(7) DEFAULT '#2196F3',
    sort_order INTEGER DEFAULT 100,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Insert EXACT request types from BDD specifications
INSERT INTO argus_request_types (
    type_code, type_name_ru, type_name_en, description_ru,
    requires_calendar_integration, requires_manager_approval, requires_hr_approval,
    advance_notice_days, creates_zup_document, zup_document_type, affects_vacation_balance
) VALUES
-- Core vacation requests
('VACATION_ANNUAL', 'Ежегодный отпуск', 'Annual Vacation', 'Заявление на ежегодный оплачиваемый отпуск',
 true, true, true, 14, true, 'Vacation Document', true),

('VACATION_ADDITIONAL', 'Дополнительный отпуск', 'Additional Vacation', 'Дополнительный отпуск за вредные условия',
 true, true, true, 14, true, 'Additional Vacation Document', true),

('VACATION_UNPAID', 'Отпуск без сохранения заработной платы', 'Unpaid Leave', 'Отпуск за свой счет',
 true, true, true, 7, true, 'Unpaid Leave Document', false),

-- Sick leave and medical
('SICK_LEAVE', 'Больничный лист', 'Sick Leave', 'Временная нетрудоспособность',
 true, false, true, 0, true, 'Sick Leave Document', false),

('MEDICAL_APPOINTMENT', 'Визит к врачу', 'Medical Appointment', 'Освобождение для посещения врача',
 false, true, false, 1, false, NULL, false),

-- Time off requests
('TIME_OFF_PERSONAL', 'Отгул за свой счет', 'Personal Time Off', 'Личный отгул без сохранения заработной платы',
 true, true, false, 3, true, 'Time Off Document', false),

('TIME_OFF_EMERGENCY', 'Внеочередной отгул', 'Emergency Time Off', 'Экстренный отгул по семейным обстоятельствам',
 true, true, false, 0, true, 'Emergency Leave Document', false),

-- Schedule changes
('SCHEDULE_CHANGE', 'Изменение графика работы', 'Schedule Change', 'Заявление на изменение рабочего графика',
 true, true, false, 7, true, 'Schedule Change Document', false),

('SHIFT_EXCHANGE', 'Обмен сменами', 'Shift Exchange', 'Обмен рабочими сменами с коллегой',
 true, true, false, 3, false, NULL, false),

-- Training and development
('TRAINING_REQUEST', 'Заявка на обучение', 'Training Request', 'Заявка на повышение квалификации',
 false, true, true, 30, true, 'Training Document', false);

-- Indexes for argus_request_types
CREATE INDEX idx_argus_request_types_code ON argus_request_types(type_code);

-- =============================================================================
-- 2. ARGUS_EMPLOYEE_REQUESTS - Main request tracking table
-- =============================================================================
CREATE TABLE argus_employee_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_number VARCHAR(50) NOT NULL UNIQUE, -- Auto-generated request number
    
    -- Request details
    employee_tab_n VARCHAR(50) NOT NULL,
    request_type_id UUID NOT NULL,
    request_title VARCHAR(500) NOT NULL,
    request_description TEXT,
    
    -- Date/time details from BDD specs
    request_start_date DATE,
    request_end_date DATE,
    request_start_time TIME,
    request_end_time TIME,
    total_days DECIMAL(5,2),
    total_hours DECIMAL(8,2),
    
    -- Request status with exact Russian workflow states
    request_status VARCHAR(50) DEFAULT 'СОЗДАНО' CHECK (
        request_status IN (
            'СОЗДАНО',           -- Created (initial state)
            'НА_РАССМОТРЕНИИ',   -- Under review
            'УТВЕРЖДЕНО_РУКОВОДИТЕЛЕМ', -- Approved by manager
            'НА_СОГЛАСОВАНИИ_HR', -- HR approval pending
            'УТВЕРЖДЕНО',        -- Fully approved
            'ОТКЛОНЕНО',         -- Rejected
            'ОТОЗВАНО',          -- Withdrawn by employee
            'ВЫПОЛНЕНО'          -- Completed/Taken
        )
    ),
    
    -- Approval workflow tracking
    manager_approval_status VARCHAR(20) DEFAULT 'ОЖИДАНИЕ',
    manager_approval_date TIMESTAMP WITH TIME ZONE,
    manager_approved_by VARCHAR(100),
    manager_rejection_reason TEXT,
    
    hr_approval_status VARCHAR(20) DEFAULT 'НЕ_ТРЕБУЕТСЯ',
    hr_approval_date TIMESTAMP WITH TIME ZONE,
    hr_approved_by VARCHAR(100),
    hr_rejection_reason TEXT,
    
    -- Documentation
    supporting_documents JSONB DEFAULT '[]', -- Array of document references
    comments JSONB DEFAULT '[]', -- Array of comments with timestamps
    
    -- Integration tracking
    calendar_integration_status VARCHAR(20) DEFAULT 'ОЖИДАНИЕ',
    zup_document_created BOOLEAN DEFAULT false,
    zup_document_id VARCHAR(100),
    schedule_updated BOOLEAN DEFAULT false,
    
    -- Request metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by_tab_n VARCHAR(50),
    submitted_at TIMESTAMP WITH TIME ZONE,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_argus_employee_requests_type 
        FOREIGN KEY (request_type_id) REFERENCES argus_request_types(id),
    CONSTRAINT fk_argus_employee_requests_employee 
        FOREIGN KEY (employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT fk_argus_employee_requests_created_by 
        FOREIGN KEY (created_by_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for argus_employee_requests
CREATE INDEX idx_argus_employee_requests_employee ON argus_employee_requests(employee_tab_n);
CREATE INDEX idx_argus_employee_requests_status ON argus_employee_requests(request_status);
CREATE INDEX idx_argus_employee_requests_dates ON argus_employee_requests(request_start_date, request_end_date);
CREATE INDEX idx_argus_employee_requests_number ON argus_employee_requests(request_number);

-- =============================================================================
-- 3. ARGUS_REQUEST_APPROVAL_CHAIN - Multi-stage approval workflow
-- =============================================================================
CREATE TABLE argus_request_approval_chain (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL,
    
    -- Approval stage details
    approval_stage INTEGER NOT NULL, -- 1, 2, 3, etc.
    stage_name_ru VARCHAR(100) NOT NULL, -- 'Руководитель', 'HR', 'Администратор'
    stage_name_en VARCHAR(100) NOT NULL,
    
    -- Approver details
    approver_role VARCHAR(100) NOT NULL, -- 'manager', 'hr_specialist', 'admin'
    approver_tab_n VARCHAR(50), -- Specific approver if assigned
    approver_department VARCHAR(100),
    
    -- Stage status
    stage_status VARCHAR(20) DEFAULT 'ОЖИДАНИЕ' CHECK (
        stage_status IN ('ОЖИДАНИЕ', 'В_ПРОЦЕССЕ', 'УТВЕРЖДЕНО', 'ОТКЛОНЕНО', 'ПРОПУЩЕНО')
    ),
    
    -- Timing
    stage_started_at TIMESTAMP WITH TIME ZONE,
    stage_completed_at TIMESTAMP WITH TIME ZONE,
    stage_deadline TIMESTAMP WITH TIME ZONE,
    
    -- Decision details
    approval_decision VARCHAR(20), -- 'УТВЕРДИТЬ', 'ОТКЛОНИТЬ', 'ДОРАБОТАТЬ'
    decision_comments TEXT,
    decision_made_by VARCHAR(100),
    
    -- Workflow logic
    is_required BOOLEAN DEFAULT true,
    is_parallel BOOLEAN DEFAULT false, -- Can be processed in parallel with other stages
    auto_approve_conditions JSONB, -- Conditions for automatic approval
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_argus_request_approval_chain_request 
        FOREIGN KEY (request_id) REFERENCES argus_employee_requests(id),
    CONSTRAINT fk_argus_request_approval_chain_approver 
        FOREIGN KEY (approver_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for argus_request_approval_chain
CREATE INDEX idx_argus_request_approval_chain_request ON argus_request_approval_chain(request_id);
CREATE INDEX idx_argus_request_approval_chain_stage ON argus_request_approval_chain(approval_stage);
CREATE INDEX idx_argus_request_approval_chain_status ON argus_request_approval_chain(stage_status);

-- =============================================================================
-- 4. ARGUS_SHIFT_EXCHANGE - "Биржа" (Exchange) system from BDD
-- =============================================================================
CREATE TABLE argus_shift_exchange (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Exchange participants
    offering_employee_tab_n VARCHAR(50) NOT NULL, -- Employee offering shift
    requesting_employee_tab_n VARCHAR(50), -- Employee requesting (NULL if open offer)
    
    -- Shift details
    original_shift_date DATE NOT NULL,
    original_shift_start_time TIME NOT NULL,
    original_shift_end_time TIME NOT NULL,
    requested_replacement_date DATE,
    requested_replacement_start_time TIME,
    requested_replacement_end_time TIME,
    
    -- Exchange type from BDD specs
    exchange_type VARCHAR(50) NOT NULL CHECK (
        exchange_type IN ('ПРЯМОЙ_ОБМЕН', 'ПРЕДЛОЖЕНИЕ', 'ЗАПРОС', 'ОТГУЛ')
    ),
    
    -- Status tracking with Russian terms
    exchange_status VARCHAR(50) DEFAULT 'АКТИВНОЕ' CHECK (
        exchange_status IN (
            'АКТИВНОЕ',          -- Active offer/request
            'В_ОЖИДАНИИ',        -- Waiting for response
            'ПРИНЯТО',           -- Accepted
            'ОТКЛОНЕНО',         -- Declined
            'ЗАВЕРШЕНО',         -- Completed
            'ОТМЕНЕНО'           -- Cancelled
        )
    ),
    
    -- Exchange details
    exchange_reason TEXT,
    compensation_offered VARCHAR(200), -- Additional compensation or benefits
    priority_level VARCHAR(20) DEFAULT 'ОБЫЧНЫЙ' CHECK (
        priority_level IN ('ВЫСОКИЙ', 'ОБЫЧНЫЙ', 'НИЗКИЙ')
    ),
    
    -- Approval and processing
    requires_manager_approval BOOLEAN DEFAULT true,
    manager_approval_status VARCHAR(20) DEFAULT 'ОЖИДАНИЕ',
    approved_by VARCHAR(100),
    approval_date TIMESTAMP WITH TIME ZONE,
    
    -- System integration
    schedule_updated BOOLEAN DEFAULT false,
    zup_documents_created BOOLEAN DEFAULT false,
    
    -- Timing
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT fk_argus_shift_exchange_offering 
        FOREIGN KEY (offering_employee_tab_n) REFERENCES zup_agent_data(tab_n),
    CONSTRAINT fk_argus_shift_exchange_requesting 
        FOREIGN KEY (requesting_employee_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for argus_shift_exchange
CREATE INDEX idx_argus_shift_exchange_offering ON argus_shift_exchange(offering_employee_tab_n);
CREATE INDEX idx_argus_shift_exchange_requesting ON argus_shift_exchange(requesting_employee_tab_n);
CREATE INDEX idx_argus_shift_exchange_status ON argus_shift_exchange(exchange_status);
CREATE INDEX idx_argus_shift_exchange_date ON argus_shift_exchange(original_shift_date);

-- =============================================================================
-- FUNCTIONS: Argus Request Workflow Management
-- =============================================================================

-- Function to create employee request with automatic workflow setup
CREATE OR REPLACE FUNCTION create_argus_employee_request(
    p_employee_tab_n VARCHAR(50),
    p_request_type_code VARCHAR(50),
    p_title VARCHAR(500),
    p_description TEXT,
    p_start_date DATE,
    p_end_date DATE DEFAULT NULL,
    p_start_time TIME DEFAULT NULL,
    p_end_time TIME DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_request_id UUID;
    v_request_number VARCHAR(50);
    v_request_type argus_request_types%ROWTYPE;
    v_total_days DECIMAL(5,2);
    v_total_hours DECIMAL(8,2);
    v_result JSONB;
BEGIN
    -- Get request type
    SELECT * INTO v_request_type 
    FROM argus_request_types 
    WHERE type_code = p_request_type_code AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request type not found: %', p_request_type_code;
    END IF;
    
    -- Generate request number
    v_request_number := 'REQ-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || 
                       LPAD(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::VARCHAR, 10, '0');
    
    -- Calculate duration
    IF p_end_date IS NOT NULL THEN
        v_total_days := p_end_date - p_start_date + 1;
    ELSE
        v_total_days := 1;
    END IF;
    
    IF p_start_time IS NOT NULL AND p_end_time IS NOT NULL THEN
        v_total_hours := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600.0;
    END IF;
    
    -- Create request
    INSERT INTO argus_employee_requests (
        request_number,
        employee_tab_n,
        request_type_id,
        request_title,
        request_description,
        request_start_date,
        request_end_date,
        request_start_time,
        request_end_time,
        total_days,
        total_hours,
        created_by_tab_n,
        submitted_at,
        manager_approval_status,
        hr_approval_status
    ) VALUES (
        v_request_number,
        p_employee_tab_n,
        v_request_type.id,
        p_title,
        p_description,
        p_start_date,
        p_end_date,
        p_start_time,
        p_end_time,
        v_total_days,
        v_total_hours,
        p_employee_tab_n,
        CURRENT_TIMESTAMP,
        CASE WHEN v_request_type.requires_manager_approval THEN 'ОЖИДАНИЕ' ELSE 'НЕ_ТРЕБУЕТСЯ' END,
        CASE WHEN v_request_type.requires_hr_approval THEN 'ОЖИДАНИЕ' ELSE 'НЕ_ТРЕБУЕТСЯ' END
    ) RETURNING id INTO v_request_id;
    
    -- Set up approval chain
    PERFORM setup_approval_chain(v_request_id, v_request_type.id);
    
    v_result := jsonb_build_object(
        'request_id', v_request_id,
        'request_number', v_request_number,
        'employee_tab_n', p_employee_tab_n,
        'request_type', v_request_type.type_name_ru,
        'status', 'СОЗДАНО',
        'total_days', v_total_days,
        'requires_manager_approval', v_request_type.requires_manager_approval,
        'requires_hr_approval', v_request_type.requires_hr_approval
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to set up approval chain based on request type
CREATE OR REPLACE FUNCTION setup_approval_chain(
    p_request_id UUID,
    p_request_type_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_request_type argus_request_types%ROWTYPE;
    v_stages_created INTEGER := 0;
BEGIN
    -- Get request type
    SELECT * INTO v_request_type 
    FROM argus_request_types 
    WHERE id = p_request_type_id;
    
    -- Stage 1: Manager approval (if required)
    IF v_request_type.requires_manager_approval THEN
        INSERT INTO argus_request_approval_chain (
            request_id, approval_stage, stage_name_ru, stage_name_en,
            approver_role, is_required, stage_deadline
        ) VALUES (
            p_request_id, 1, 'Утверждение руководителем', 'Manager Approval',
            'manager', true, CURRENT_TIMESTAMP + INTERVAL '3 days'
        );
        v_stages_created := v_stages_created + 1;
    END IF;
    
    -- Stage 2: HR approval (if required)
    IF v_request_type.requires_hr_approval THEN
        INSERT INTO argus_request_approval_chain (
            request_id, approval_stage, stage_name_ru, stage_name_en,
            approver_role, is_required, stage_deadline
        ) VALUES (
            p_request_id, 2, 'Согласование с HR', 'HR Approval',
            'hr_specialist', true, CURRENT_TIMESTAMP + INTERVAL '5 days'
        );
        v_stages_created := v_stages_created + 1;
    END IF;
    
    -- Stage 3: Final processing
    INSERT INTO argus_request_approval_chain (
        request_id, approval_stage, stage_name_ru, stage_name_en,
        approver_role, is_required, stage_deadline
    ) VALUES (
        p_request_id, 3, 'Финальная обработка', 'Final Processing',
        'system', true, CURRENT_TIMESTAMP + INTERVAL '1 day'
    );
    v_stages_created := v_stages_created + 1;
    
    RETURN v_stages_created;
END;
$$ LANGUAGE plpgsql;

-- Function to process approval stage
CREATE OR REPLACE FUNCTION process_approval_stage(
    p_request_id UUID,
    p_stage_number INTEGER,
    p_decision VARCHAR(20), -- 'УТВЕРДИТЬ', 'ОТКЛОНИТЬ', 'ДОРАБОТАТЬ'
    p_approver_tab_n VARCHAR(50),
    p_comments TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_stage_id UUID;
    v_request argus_employee_requests%ROWTYPE;
    v_next_stage_exists BOOLEAN;
    v_result JSONB;
BEGIN
    -- Update approval stage
    UPDATE argus_request_approval_chain SET
        stage_status = CASE p_decision
            WHEN 'УТВЕРДИТЬ' THEN 'УТВЕРЖДЕНО'
            WHEN 'ОТКЛОНИТЬ' THEN 'ОТКЛОНЕНО'
            ELSE 'В_ПРОЦЕССЕ'
        END,
        stage_completed_at = CURRENT_TIMESTAMP,
        approval_decision = p_decision,
        decision_comments = p_comments,
        decision_made_by = p_approver_tab_n
    WHERE request_id = p_request_id AND approval_stage = p_stage_number
    RETURNING id INTO v_stage_id;
    
    -- Update main request status
    IF p_decision = 'ОТКЛОНИТЬ' THEN
        UPDATE argus_employee_requests SET
            request_status = 'ОТКЛОНЕНО',
            last_updated_at = CURRENT_TIMESTAMP
        WHERE id = p_request_id;
        
    ELSIF p_decision = 'УТВЕРДИТЬ' THEN
        -- Check if there are more stages
        SELECT EXISTS(
            SELECT 1 FROM argus_request_approval_chain 
            WHERE request_id = p_request_id 
            AND approval_stage > p_stage_number 
            AND is_required = true
        ) INTO v_next_stage_exists;
        
        IF v_next_stage_exists THEN
            UPDATE argus_employee_requests SET
                request_status = 'НА_РАССМОТРЕНИИ',
                last_updated_at = CURRENT_TIMESTAMP
            WHERE id = p_request_id;
            
            -- Start next stage
            UPDATE argus_request_approval_chain SET
                stage_status = 'ОЖИДАНИЕ',
                stage_started_at = CURRENT_TIMESTAMP
            WHERE request_id = p_request_id 
            AND approval_stage = p_stage_number + 1;
        ELSE
            -- All stages completed
            UPDATE argus_employee_requests SET
                request_status = 'УТВЕРЖДЕНО',
                last_updated_at = CURRENT_TIMESTAMP
            WHERE id = p_request_id;
        END IF;
    END IF;
    
    v_result := jsonb_build_object(
        'stage_id', v_stage_id,
        'request_id', p_request_id,
        'stage_number', p_stage_number,
        'decision', p_decision,
        'approved_by', p_approver_tab_n,
        'has_next_stage', v_next_stage_exists,
        'processed_at', CURRENT_TIMESTAMP
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Request Management and Workflow
-- =============================================================================

-- Employee requests dashboard (exact Russian terminology)
CREATE VIEW v_argus_employee_requests_dashboard AS
SELECT 
    aer.request_number as "Номер заявки",
    zda.lastname || ' ' || zda.firstname as "Сотрудник",
    art.type_name_ru as "Тип заявки",
    aer.request_title as "Название",
    aer.request_start_date as "Дата начала",
    aer.request_end_date as "Дата окончания",
    aer.total_days as "Количество дней",
    CASE aer.request_status
        WHEN 'СОЗДАНО' THEN 'Создано'
        WHEN 'НА_РАССМОТРЕНИИ' THEN 'На рассмотрении'
        WHEN 'УТВЕРЖДЕНО_РУКОВОДИТЕЛЕМ' THEN 'Утверждено руководителем'
        WHEN 'НА_СОГЛАСОВАНИИ_HR' THEN 'На согласовании HR'
        WHEN 'УТВЕРЖДЕНО' THEN 'Утверждено'
        WHEN 'ОТКЛОНЕНО' THEN 'Отклонено'
        WHEN 'ОТОЗВАНО' THEN 'Отозвано'
        WHEN 'ВЫПОЛНЕНО' THEN 'Выполнено'
    END as "Статус",
    aer.created_at as "Дата создания",
    aer.submitted_at as "Дата подачи"
FROM argus_employee_requests aer
JOIN zup_agent_data zda ON zda.tab_n = aer.employee_tab_n
JOIN argus_request_types art ON art.id = aer.request_type_id
WHERE aer.created_at >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY aer.created_at DESC;

-- Approval workflow status view
CREATE VIEW v_argus_approval_workflow AS
SELECT 
    aer.request_number,
    zda.lastname || ' ' || zda.firstname as employee_name,
    art.type_name_ru as request_type,
    arac.approval_stage,
    arac.stage_name_ru,
    arac.stage_status,
    arac.approver_role,
    arac.stage_started_at,
    arac.stage_deadline,
    arac.decision_comments,
    CASE 
        WHEN arac.stage_deadline < CURRENT_TIMESTAMP AND arac.stage_status = 'ОЖИДАНИЕ' THEN 'ПРОСРОЧЕНО'
        WHEN arac.stage_deadline - CURRENT_TIMESTAMP <= INTERVAL '1 day' AND arac.stage_status = 'ОЖИДАНИЕ' THEN 'СРОЧНО'
        ELSE 'В_СРОК'
    END as urgency_status
FROM argus_employee_requests aer
JOIN zup_agent_data zda ON zda.tab_n = aer.employee_tab_n
JOIN argus_request_types art ON art.id = aer.request_type_id
JOIN argus_request_approval_chain arac ON arac.request_id = aer.id
WHERE aer.request_status NOT IN ('ОТКЛОНЕНО', 'ВЫПОЛНЕНО', 'ОТОЗВАНО')
ORDER BY arac.stage_deadline ASC;

-- Shift exchange "Биржа" view
CREATE VIEW v_argus_shift_exchange_board AS
SELECT 
    ase.id,
    zda1.lastname || ' ' || zda1.firstname as "Предлагает",
    COALESCE(zda2.lastname || ' ' || zda2.firstname, 'Открытое предложение') as "Запрашивает",
    ase.original_shift_date as "Дата смены",
    ase.original_shift_start_time || ' - ' || ase.original_shift_end_time as "Время смены",
    CASE ase.exchange_type
        WHEN 'ПРЯМОЙ_ОБМЕН' THEN 'Прямой обмен'
        WHEN 'ПРЕДЛОЖЕНИЕ' THEN 'Предложение'
        WHEN 'ЗАПРОС' THEN 'Запрос'
        WHEN 'ОТГУЛ' THEN 'Отгул'
    END as "Тип обмена",
    CASE ase.exchange_status
        WHEN 'АКТИВНОЕ' THEN 'Активное'
        WHEN 'В_ОЖИДАНИИ' THEN 'В ожидании'
        WHEN 'ПРИНЯТО' THEN 'Принято'
        WHEN 'ОТКЛОНЕНО' THEN 'Отклонено'
        WHEN 'ЗАВЕРШЕНО' THEN 'Завершено'
        WHEN 'ОТМЕНЕНО' THEN 'Отменено'
    END as "Статус",
    ase.compensation_offered as "Компенсация",
    ase.offer_expires_at as "Срок действия"
FROM argus_shift_exchange ase
JOIN zup_agent_data zda1 ON zda1.tab_n = ase.offering_employee_tab_n
LEFT JOIN zup_agent_data zda2 ON zda2.tab_n = ase.requesting_employee_tab_n
WHERE ase.exchange_status IN ('АКТИВНОЕ', 'В_ОЖИДАНИИ')
ORDER BY ase.created_at DESC;

-- Demo request workflow metrics
CREATE VIEW v_demo_request_workflow AS
SELECT 
    'Argus Request Workflow' as metric_name,
    'Multi-stage Approval System' as category,
    COUNT(DISTINCT aer.id) as total_requests,
    COUNT(DISTINCT aer.id) FILTER (WHERE aer.request_status = 'УТВЕРЖДЕНО') as approved_requests,
    COUNT(DISTINCT arac.id) as total_approval_stages,
    COUNT(DISTINCT arac.id) FILTER (WHERE arac.stage_status = 'УТВЕРЖДЕНО') as completed_stages,
    ROUND(AVG(EXTRACT(EPOCH FROM (arac.stage_completed_at - arac.stage_started_at)) / 3600.0), 1) as avg_approval_time_hours,
    'Exact Russian terminology: СОЗДАНО → НА_РАССМОТРЕНИИ → УТВЕРЖДЕНО' as workflow_states,
    NOW() as measurement_time
FROM argus_employee_requests aer
LEFT JOIN argus_request_approval_chain arac ON arac.request_id = aer.id
WHERE aer.created_at >= CURRENT_DATE - INTERVAL '30 days';

COMMENT ON TABLE argus_request_types IS 'Request types with exact Russian terminology from BDD specs';
COMMENT ON TABLE argus_employee_requests IS 'Employee requests with multi-stage approval workflow';
COMMENT ON TABLE argus_shift_exchange IS 'Shift exchange "Биржа" system from BDD specifications';
COMMENT ON VIEW v_argus_employee_requests_dashboard IS 'Request dashboard with exact Russian column names';