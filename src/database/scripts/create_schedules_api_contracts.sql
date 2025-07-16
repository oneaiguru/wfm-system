-- API Contracts for schedules table
-- Comprehensive API documentation with Russian language support for workforce management scheduling

-- 1. GET /api/v1/schedules - List schedules with filtering and search
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules',
    'GET',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "organization_id": {"type": "string", "format": "uuid", "description": "ID организации"},
            "department_id": {"type": "string", "format": "uuid", "description": "ID отдела"},
            "status": {"type": "string", "enum": ["draft", "active", "inactive", "archived"], "description": "Статус расписания"},
            "schedule_type": {"type": "string", "enum": ["weekly", "monthly", "shift_based"], "description": "Тип расписания"},
            "date_from": {"type": "string", "format": "date", "description": "Начальная дата периода"},
            "date_to": {"type": "string", "format": "date", "description": "Конечная дата периода"},
            "search": {"type": "string", "description": "Поиск по названию или описанию"},
            "limit": {"type": "integer", "default": 20, "maximum": 100},
            "offset": {"type": "integer", "default": 0}
        }
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "data": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "string", "format": "uuid"},
                        "organization_id": {"type": "string", "format": "uuid"},
                        "department_id": {"type": "string", "format": "uuid"},
                        "forecast_id": {"type": "string", "format": "uuid"},
                        "name": {"type": "string"},
                        "description": {"type": "string"},
                        "schedule_type": {"type": "string"},
                        "start_date": {"type": "string", "format": "date"},
                        "end_date": {"type": "string", "format": "date"},
                        "status": {"type": "string"},
                        "optimization_score": {"type": "number"},
                        "created_at": {"type": "string", "format": "date-time"},
                        "updated_at": {"type": "string", "format": "date-time"}
                    }
                }
            },
            "total": {"type": "integer"},
            "limit": {"type": "integer"},
            "offset": {"type": "integer"}
        }
    }'::jsonb,
    ARRAY['schedules', 'organizations', 'departments'],
    '{
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "status": "active",
        "schedule_type": "weekly",
        "limit": 10,
        "offset": 0
    }'::jsonb,
    '{
        "data": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "organization_id": "123e4567-e89b-12d3-a456-426614174000",
                "department_id": "789e4567-e89b-12d3-a456-426614174000",
                "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
                "name": "Недельное расписание техподдержки",
                "description": "Основное расписание для отдела технической поддержки",
                "schedule_type": "weekly",
                "start_date": "2025-07-21",
                "end_date": "2025-07-27",
                "status": "active",
                "optimization_score": 0.8756,
                "created_at": "2025-07-15T10:00:00Z",
                "updated_at": "2025-07-15T14:30:00Z"
            }
        ],
        "total": 23,
        "limit": 10,
        "offset": 0
    }'::jsonb,
    'SELECT COUNT(*) FROM schedules WHERE organization_id IS NOT NULL'
);

-- 2. GET /api/v1/schedules/{id} - Get specific schedule with details
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules/{id}',
    'GET',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID расписания"},
            "include_shifts": {"type": "boolean", "default": false, "description": "Включить смены в ответ"},
            "include_assignments": {"type": "boolean", "default": false, "description": "Включить назначения агентов"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "forecast_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "description": {"type": "string"},
            "schedule_type": {"type": "string"},
            "start_date": {"type": "string", "format": "date"},
            "end_date": {"type": "string", "format": "date"},
            "status": {"type": "string"},
            "optimization_score": {"type": "number"},
            "parameters": {"type": "object"},
            "metadata": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"},
            "updated_at": {"type": "string", "format": "date-time"},
            "shifts": {"type": "array", "description": "Смены (если include_shifts=true)"},
            "assignments": {"type": "array", "description": "Назначения (если include_assignments=true)"}
        }
    }'::jsonb,
    ARRAY['schedules', 'schedule_shifts', 'agent_assignments'],
    '{"id": "550e8400-e29b-41d4-a716-446655440000", "include_shifts": true}'::jsonb,
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
        "name": "Недельное расписание техподдержки",
        "description": "Основное расписание для отдела технической поддержки на неделю 21-27 июля",
        "schedule_type": "weekly",
        "start_date": "2025-07-21",
        "end_date": "2025-07-27",
        "status": "active",
        "optimization_score": 0.8756,
        "parameters": {
            "shift_duration": 8,
            "break_duration": 60,
            "overlap_minutes": 15,
            "min_staff": 5,
            "max_staff": 15
        },
        "metadata": {
            "created_by": "system",
            "optimization_algorithm": "genetic_v2",
            "last_optimized": "2025-07-15T14:30:00Z"
        },
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T14:30:00Z",
        "shifts": [
            {
                "id": "shift-001",
                "start_time": "09:00",
                "end_time": "17:00",
                "required_agents": 8,
                "date": "2025-07-21"
            }
        ]
    }'::jsonb,
    'SELECT 1 FROM schedules WHERE id = $1'
);

-- 3. POST /api/v1/schedules - Create new schedule
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules',
    'POST',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "organization_id": {"type": "string", "format": "uuid", "description": "ID организации"},
            "department_id": {"type": "string", "format": "uuid", "description": "ID отдела (опционально)"},
            "forecast_id": {"type": "string", "format": "uuid", "description": "ID прогноза для оптимизации"},
            "name": {"type": "string", "description": "Название расписания"},
            "description": {"type": "string", "description": "Описание расписания"},
            "schedule_type": {"type": "string", "enum": ["weekly", "monthly", "shift_based"], "default": "weekly"},
            "start_date": {"type": "string", "format": "date", "description": "Дата начала"},
            "end_date": {"type": "string", "format": "date", "description": "Дата окончания"},
            "parameters": {"type": "object", "description": "Параметры оптимизации"},
            "auto_optimize": {"type": "boolean", "default": true, "description": "Автоматическая оптимизация"}
        },
        "required": ["organization_id", "name", "start_date", "end_date"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "forecast_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "description": {"type": "string"},
            "schedule_type": {"type": "string"},
            "start_date": {"type": "string", "format": "date"},
            "end_date": {"type": "string", "format": "date"},
            "status": {"type": "string"},
            "optimization_score": {"type": "number"},
            "created_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['schedules', 'organizations', 'departments', 'forecasts'],
    '{
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
        "name": "Августовское расписание продаж",
        "description": "Расписание отдела продаж на август 2025",
        "schedule_type": "weekly",
        "start_date": "2025-08-01",
        "end_date": "2025-08-31",
        "parameters": {
            "min_agents_per_shift": 3,
            "max_agents_per_shift": 12,
            "preferred_shift_length": 8,
            "allow_overtime": true
        },
        "auto_optimize": true
    }'::jsonb,
    '{
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
        "name": "Августовское расписание продаж",
        "description": "Расписание отдела продаж на август 2025",
        "schedule_type": "weekly",
        "start_date": "2025-08-01",
        "end_date": "2025-08-31",
        "status": "draft",
        "optimization_score": null,
        "created_at": "2025-07-15T15:00:00Z"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM organizations WHERE id = $1)'
);

-- 4. PUT /api/v1/schedules/{id} - Update schedule
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules/{id}',
    'PUT',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID расписания"},
            "name": {"type": "string", "description": "Новое название"},
            "description": {"type": "string", "description": "Новое описание"},
            "status": {"type": "string", "enum": ["draft", "active", "inactive", "archived"]},
            "start_date": {"type": "string", "format": "date"},
            "end_date": {"type": "string", "format": "date"},
            "parameters": {"type": "object", "description": "Обновленные параметры"},
            "trigger_optimization": {"type": "boolean", "default": false, "description": "Запустить пересчет"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "forecast_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "description": {"type": "string"},
            "schedule_type": {"type": "string"},
            "start_date": {"type": "string", "format": "date"},
            "end_date": {"type": "string", "format": "date"},
            "status": {"type": "string"},
            "optimization_score": {"type": "number"},
            "parameters": {"type": "object"},
            "metadata": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"},
            "updated_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['schedules'],
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Обновленное недельное расписание",
        "status": "active",
        "parameters": {
            "min_agents_per_shift": 4,
            "max_agents_per_shift": 10,
            "shift_overlap_minutes": 30
        },
        "trigger_optimization": true
    }'::jsonb,
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
        "name": "Обновленное недельное расписание",
        "description": "Основное расписание для отдела технической поддержки",
        "schedule_type": "weekly",
        "start_date": "2025-07-21",
        "end_date": "2025-07-27",
        "status": "active",
        "optimization_score": 0.8901,
        "parameters": {
            "min_agents_per_shift": 4,
            "max_agents_per_shift": 10,
            "shift_overlap_minutes": 30
        },
        "metadata": {
            "last_optimized": "2025-07-15T16:00:00Z",
            "optimization_triggered_by": "api_update"
        },
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T16:00:00Z"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM schedules WHERE id = $1)'
);

-- 5. DELETE /api/v1/schedules/{id} - Delete schedule
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules/{id}',
    'DELETE',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID расписания для удаления"},
            "force": {"type": "boolean", "default": false, "description": "Принудительное удаление"},
            "archive_instead": {"type": "boolean", "default": true, "description": "Архивировать вместо удаления"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "success": {"type": "boolean"},
            "message": {"type": "string"},
            "deleted_id": {"type": "string", "format": "uuid"},
            "action_taken": {"type": "string", "enum": ["deleted", "archived"]}
        }
    }'::jsonb,
    ARRAY['schedules', 'schedule_shifts', 'agent_assignments'],
    '{"id": "550e8400-e29b-41d4-a716-446655440000", "archive_instead": true}'::jsonb,
    '{
        "success": true,
        "message": "Расписание успешно архивировано",
        "deleted_id": "550e8400-e29b-41d4-a716-446655440000",
        "action_taken": "archived"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM schedules WHERE id = $1)'
);

-- 6. POST /api/v1/schedules/{id}/optimize - Trigger schedule optimization
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/schedules/{id}/optimize',
    'POST',
    'schedules',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID расписания"},
            "algorithm": {"type": "string", "enum": ["genetic", "linear_programming", "heuristic"], "default": "genetic"},
            "parameters": {"type": "object", "description": "Параметры алгоритма оптимизации"},
            "async_mode": {"type": "boolean", "default": true, "description": "Асинхронный режим"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "optimization_id": {"type": "string", "format": "uuid"},
            "schedule_id": {"type": "string", "format": "uuid"},
            "status": {"type": "string", "enum": ["started", "completed", "failed"]},
            "algorithm": {"type": "string"},
            "estimated_completion": {"type": "string", "format": "date-time"},
            "progress_url": {"type": "string"},
            "optimization_score": {"type": "number", "description": "Только если завершено синхронно"}
        }
    }'::jsonb,
    ARRAY['schedules', 'optimization_jobs'],
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "algorithm": "genetic",
        "parameters": {
            "population_size": 100,
            "generations": 50,
            "mutation_rate": 0.1
        },
        "async_mode": true
    }'::jsonb,
    '{
        "optimization_id": "opt-770e8400-e29b-41d4-a716-446655440000",
        "schedule_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "started",
        "algorithm": "genetic",
        "estimated_completion": "2025-07-15T16:30:00Z",
        "progress_url": "/api/v1/optimization-jobs/opt-770e8400-e29b-41d4-a716-446655440000"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM schedules WHERE id = $1 AND status != ''archived'')'
);

-- Helper queries for schedules API endpoints
INSERT INTO api_helper_queries (
    endpoint_path,
    http_method,
    query_name,
    query_sql,
    parameters,
    description
) VALUES 
-- Query for GET /api/v1/schedules
('/api/v1/schedules', 'GET', 'list_schedules_with_filters',
'SELECT 
    s.id,
    s.organization_id,
    s.department_id,
    s.forecast_id,
    s.name,
    s.description,
    s.schedule_type,
    s.start_date,
    s.end_date,
    s.status,
    s.optimization_score,
    s.created_at,
    s.updated_at,
    COUNT(*) OVER() as total_count
FROM schedules s
WHERE ($1::uuid IS NULL OR s.organization_id = $1)
  AND ($2::uuid IS NULL OR s.department_id = $2)
  AND ($3::text IS NULL OR s.status = $3)
  AND ($4::text IS NULL OR s.schedule_type = $4)
  AND ($5::date IS NULL OR s.start_date >= $5)
  AND ($6::date IS NULL OR s.end_date <= $6)
  AND ($7::text IS NULL OR (s.name ILIKE ''%'' || $7 || ''%'' OR s.description ILIKE ''%'' || $7 || ''%''))
ORDER BY s.updated_at DESC
LIMIT $8 OFFSET $9;',
'["organization_id", "department_id", "status", "schedule_type", "date_from", "date_to", "search", "limit", "offset"]'::jsonb,
'Список расписаний с фильтрацией и поиском'),

-- Query for GET /api/v1/schedules/{id}
('/api/v1/schedules/{id}', 'GET', 'get_schedule_with_details',
'SELECT 
    s.id,
    s.organization_id,
    s.department_id,
    s.forecast_id,
    s.name,
    s.description,
    s.schedule_type,
    s.start_date,
    s.end_date,
    s.status,
    s.optimization_score,
    s.parameters,
    s.metadata,
    s.created_at,
    s.updated_at
FROM schedules s
WHERE s.id = $1;',
'["id"]'::jsonb,
'Детальная информация о расписании'),

-- Query for POST /api/v1/schedules validation
('/api/v1/schedules', 'POST', 'validate_schedule_creation',
'SELECT 
    EXISTS(SELECT 1 FROM organizations WHERE id = $1) as organization_exists,
    CASE 
        WHEN $2::uuid IS NOT NULL THEN EXISTS(SELECT 1 FROM departments WHERE id = $2)
        ELSE true
    END as department_exists,
    CASE 
        WHEN $3::uuid IS NOT NULL THEN EXISTS(SELECT 1 FROM forecasts WHERE id = $3)
        ELSE true
    END as forecast_exists,
    ($5::date > $4::date) as valid_date_range;',
'["organization_id", "department_id", "forecast_id", "start_date", "end_date"]'::jsonb,
'Валидация данных для создания расписания'),

-- Query for PUT /api/v1/schedules/{id}
('/api/v1/schedules/{id}', 'PUT', 'update_schedule',
'UPDATE schedules 
SET 
    name = COALESCE($2, name),
    description = COALESCE($3, description),
    status = COALESCE($4, status),
    start_date = COALESCE($5, start_date),
    end_date = COALESCE($6, end_date),
    parameters = COALESCE($7, parameters),
    metadata = COALESCE(metadata || $8::jsonb, metadata),
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;',
'["id", "name", "description", "status", "start_date", "end_date", "parameters", "metadata_update"]'::jsonb,
'Обновление расписания с возвратом полных данных'),

-- Query for DELETE /api/v1/schedules/{id}
('/api/v1/schedules/{id}', 'DELETE', 'check_schedule_dependencies',
'SELECT 
    s.id,
    s.status,
    EXISTS(SELECT 1 FROM schedule_shifts ss WHERE ss.schedule_id = s.id) as has_shifts,
    EXISTS(SELECT 1 FROM agent_assignments aa WHERE aa.schedule_id = s.id) as has_assignments,
    (s.status = ''active'' AND s.start_date <= CURRENT_DATE AND s.end_date >= CURRENT_DATE) as is_current_active
FROM schedules s
WHERE s.id = $1;',
'["id"]'::jsonb,
'Проверка зависимостей и статуса перед удалением'),

-- Query for POST /api/v1/schedules/{id}/optimize
('/api/v1/schedules/{id}/optimize', 'POST', 'prepare_schedule_optimization',
'SELECT 
    s.id,
    s.status,
    s.forecast_id,
    s.parameters,
    (s.status IN (''draft'', ''active'')) as can_optimize,
    EXISTS(SELECT 1 FROM forecasts f WHERE f.id = s.forecast_id AND f.status = ''completed'') as has_valid_forecast
FROM schedules s
WHERE s.id = $1;',
'["id"]'::jsonb,
'Подготовка данных для оптимизации расписания');

-- Test data for schedules (Russian language support)
INSERT INTO integration_test_data (
    table_name,
    test_scenario,
    record_identifier,
    test_data,
    bdd_scenario_reference,
    is_active
) VALUES 
('schedules', 'weekly_support_schedule',
'{"id": "550e8400-e29b-41d4-a716-446655440000"}'::jsonb,
'{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "789e4567-e89b-12d3-a456-426614174000",
    "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
    "name": "Недельное расписание техподдержки",
    "description": "Основное расписание для отдела технической поддержки",
    "schedule_type": "weekly",
    "start_date": "2025-07-21",
    "end_date": "2025-07-27",
    "status": "active",
    "optimization_score": 0.8756,
    "parameters": {
        "shift_duration": 8,
        "break_duration": 60,
        "min_staff": 5,
        "max_staff": 15
    }
}'::jsonb,
'schedule-management.feature:25', true),

('schedules', 'monthly_sales_schedule',
'{"id": "660e8400-e29b-41d4-a716-446655440001"}'::jsonb,
'{
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "890e4567-e89b-12d3-a456-426614174000", 
    "forecast_id": "def12345-e89b-12d3-a456-426614174000",
    "name": "Месячное расписание продаж",
    "description": "Расписание отдела продаж на август 2025",
    "schedule_type": "monthly",
    "start_date": "2025-08-01",
    "end_date": "2025-08-31",
    "status": "draft",
    "optimization_score": null,
    "parameters": {
        "min_agents_per_shift": 3,
        "max_agents_per_shift": 12,
        "allow_overtime": true
    }
}'::jsonb,
'schedule-management.feature:55', true),

('schedules', 'shift_based_consulting',
'{"id": "770e8400-e29b-41d4-a716-446655440002"}'::jsonb,
'{
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "901e4567-e89b-12d3-a456-426614174000",
    "forecast_id": null,
    "name": "Сменное расписание консультаций",
    "description": "Гибкое расписание для отдела консультаций с динамическими сменами",
    "schedule_type": "shift_based",
    "start_date": "2025-07-20",
    "end_date": "2025-08-20",
    "status": "inactive",
    "optimization_score": 0.7234,
    "parameters": {
        "flexible_shifts": true,
        "min_shift_duration": 4,
        "max_shift_duration": 10,
        "overlap_required": false
    }
}'::jsonb,
'schedule-management.feature:85', true),

('schedules', 'optimization_test_cases',
'{"type": "optimization"}'::jsonb,
'{
    "algorithms": ["genetic", "linear_programming", "heuristic"],
    "test_parameters": {
        "genetic": {
            "population_size": [50, 100, 200],
            "generations": [25, 50, 100],
            "mutation_rate": [0.05, 0.1, 0.2]
        },
        "linear_programming": {
            "solver": ["CPLEX", "Gurobi", "COIN-OR"],
            "time_limit": [300, 600, 1200]
        },
        "heuristic": {
            "strategy": ["greedy", "best_fit", "balanced"],
            "iterations": [10, 25, 50]
        }
    }
}'::jsonb,
'schedule-optimization.feature:15', true);

\echo ''
\echo '======================================'
\echo 'SCHEDULES API CONTRACTS SUMMARY'
\echo '======================================'
\echo 'Updated tables: api_contracts, api_helper_queries, integration_test_data'
\echo 'Total API endpoints: 6'
\echo 'Total helper queries: 6' 
\echo 'Total test scenarios: 4'
\echo ''
\echo 'API Endpoints Created:'
\echo '- GET /api/v1/schedules (list with filters)'
\echo '- GET /api/v1/schedules/{id} (get by id with details)' 
\echo '- POST /api/v1/schedules (create new schedule)'
\echo '- PUT /api/v1/schedules/{id} (update schedule)'
\echo '- DELETE /api/v1/schedules/{id} (delete/archive)'
\echo '- POST /api/v1/schedules/{id}/optimize (trigger optimization)'
\echo ''