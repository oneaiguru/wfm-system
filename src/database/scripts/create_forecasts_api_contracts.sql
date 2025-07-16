-- API Contracts for forecasts table
-- Comprehensive API documentation with Russian language support for demand forecasting

-- 1. GET /api/v1/forecasts - List forecasts with filtering and accuracy metrics
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
    '/api/v1/forecasts',
    'GET',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "organization_id": {"type": "string", "format": "uuid", "description": "ID организации"},
            "department_id": {"type": "string", "format": "uuid", "description": "ID отдела"},
            "forecast_type": {"type": "string", "enum": ["call_volume", "aht", "occupancy", "abandonment"], "description": "Тип прогноза"},
            "method": {"type": "string", "enum": ["ml", "statistical", "hybrid", "manual"], "description": "Метод прогнозирования"},
            "granularity": {"type": "string", "enum": ["15min", "30min", "1hour", "daily"], "description": "Гранулярность данных"},
            "status": {"type": "string", "enum": ["pending", "running", "completed", "failed"], "description": "Статус прогноза"},
            "date_from": {"type": "string", "format": "date", "description": "Начальная дата"},
            "date_to": {"type": "string", "format": "date", "description": "Конечная дата"},
            "min_accuracy": {"type": "number", "minimum": 0, "maximum": 1, "description": "Минимальная точность (MAPE)"},
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
                        "name": {"type": "string"},
                        "forecast_type": {"type": "string"},
                        "method": {"type": "string"},
                        "granularity": {"type": "string"},
                        "start_date": {"type": "string", "format": "date-time"},
                        "end_date": {"type": "string", "format": "date-time"},
                        "status": {"type": "string"},
                        "accuracy_score": {"type": "number"},
                        "created_at": {"type": "string", "format": "date-time"},
                        "updated_at": {"type": "string", "format": "date-time"}
                    }
                }
            },
            "total": {"type": "integer"},
            "accuracy_summary": {
                "type": "object",
                "properties": {
                    "avg_accuracy": {"type": "number"},
                    "best_method": {"type": "string"},
                    "total_completed": {"type": "integer"}
                }
            }
        }
    }'::jsonb,
    ARRAY['forecasts', 'organizations', 'departments'],
    '{
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "forecast_type": "call_volume",
        "status": "completed",
        "granularity": "30min",
        "min_accuracy": 0.8,
        "limit": 10
    }'::jsonb,
    '{
        "data": [
            {
                "id": "abc12345-e89b-12d3-a456-426614174000",
                "organization_id": "123e4567-e89b-12d3-a456-426614174000",
                "department_id": "789e4567-e89b-12d3-a456-426614174000",
                "name": "Прогноз объема звонков июль 2025",
                "forecast_type": "call_volume",
                "method": "ml",
                "granularity": "30min",
                "start_date": "2025-07-21T00:00:00Z",
                "end_date": "2025-07-27T23:59:59Z",
                "status": "completed",
                "accuracy_score": 0.8756,
                "created_at": "2025-07-15T09:00:00Z",
                "updated_at": "2025-07-15T09:45:00Z"
            }
        ],
        "total": 12,
        "accuracy_summary": {
            "avg_accuracy": 0.8423,
            "best_method": "ml",
            "total_completed": 8
        }
    }'::jsonb,
    'SELECT COUNT(*) FROM forecasts WHERE organization_id IS NOT NULL'
);

-- 2. GET /api/v1/forecasts/{id} - Get specific forecast with detailed results
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
    '/api/v1/forecasts/{id}',
    'GET',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID прогноза"},
            "include_results": {"type": "boolean", "default": true, "description": "Включить детальные результаты"},
            "include_accuracy_breakdown": {"type": "boolean", "default": false, "description": "Включить разбивку точности"},
            "format": {"type": "string", "enum": ["json", "csv"], "default": "json", "description": "Формат данных"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "forecast_type": {"type": "string"},
            "method": {"type": "string"},
            "granularity": {"type": "string"},
            "start_date": {"type": "string", "format": "date-time"},
            "end_date": {"type": "string", "format": "date-time"},
            "status": {"type": "string"},
            "accuracy_score": {"type": "number"},
            "parameters": {"type": "object"},
            "results": {"type": "object", "description": "Результаты прогноза"},
            "accuracy_breakdown": {"type": "object", "description": "Детальная точность"},
            "created_at": {"type": "string", "format": "date-time"},
            "updated_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['forecasts', 'forecast_accuracy_metrics'],
    '{"id": "abc12345-e89b-12d3-a456-426614174000", "include_results": true, "include_accuracy_breakdown": true}'::jsonb,
    '{
        "id": "abc12345-e89b-12d3-a456-426614174000",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "name": "Прогноз объема звонков июль 2025",
        "forecast_type": "call_volume",
        "method": "ml",
        "granularity": "30min",
        "start_date": "2025-07-21T00:00:00Z",
        "end_date": "2025-07-27T23:59:59Z",
        "status": "completed",
        "accuracy_score": 0.8756,
        "parameters": {
            "model_type": "LSTM",
            "lookback_days": 30,
            "features": ["historical_volume", "day_of_week", "holidays", "weather"],
            "confidence_intervals": [80, 95]
        },
        "results": {
            "forecast_points": 336,
            "data": [
                {"datetime": "2025-07-21T09:00:00Z", "predicted": 45.2, "confidence_80": [40.1, 50.3], "confidence_95": [37.8, 52.6]},
                {"datetime": "2025-07-21T09:30:00Z", "predicted": 52.7, "confidence_80": [47.5, 57.9], "confidence_95": [45.1, 60.3]}
            ]
        },
        "accuracy_breakdown": {
            "mape": 0.1244,
            "wape": 0.0987,
            "rmse": 8.45,
            "by_hour": {"09:00": 0.0892, "10:00": 0.1156},
            "by_day": {"monday": 0.1089, "tuesday": 0.1234}
        },
        "created_at": "2025-07-15T09:00:00Z",
        "updated_at": "2025-07-15T09:45:00Z"
    }'::jsonb,
    'SELECT 1 FROM forecasts WHERE id = $1'
);

-- 3. POST /api/v1/forecasts - Create new forecast
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
    '/api/v1/forecasts',
    'POST',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "organization_id": {"type": "string", "format": "uuid", "description": "ID организации"},
            "department_id": {"type": "string", "format": "uuid", "description": "ID отдела (опционально)"},
            "name": {"type": "string", "description": "Название прогноза"},
            "forecast_type": {"type": "string", "enum": ["call_volume", "aht", "occupancy", "abandonment"], "description": "Тип прогноза"},
            "method": {"type": "string", "enum": ["ml", "statistical", "hybrid", "manual"], "default": "ml"},
            "granularity": {"type": "string", "enum": ["15min", "30min", "1hour", "daily"], "default": "30min"},
            "start_date": {"type": "string", "format": "date-time", "description": "Начало периода прогноза"},
            "end_date": {"type": "string", "format": "date-time", "description": "Конец периода прогноза"},
            "parameters": {"type": "object", "description": "Параметры алгоритма"},
            "auto_start": {"type": "boolean", "default": true, "description": "Автоматический запуск"}
        },
        "required": ["organization_id", "name", "forecast_type", "start_date", "end_date"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "forecast_type": {"type": "string"},
            "method": {"type": "string"},
            "granularity": {"type": "string"},
            "start_date": {"type": "string", "format": "date-time"},
            "end_date": {"type": "string", "format": "date-time"},
            "status": {"type": "string"},
            "estimated_completion": {"type": "string", "format": "date-time"},
            "created_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['forecasts', 'organizations', 'departments'],
    '{
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "name": "Прогноз AHT август 2025",
        "forecast_type": "aht",
        "method": "ml",
        "granularity": "30min",
        "start_date": "2025-08-01T00:00:00Z",
        "end_date": "2025-08-31T23:59:59Z",
        "parameters": {
            "model_type": "RandomForest",
            "lookback_days": 60,
            "include_seasonal": true,
            "confidence_level": 95
        },
        "auto_start": true
    }'::jsonb,
    '{
        "id": "def45678-e89b-12d3-a456-426614174001",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "name": "Прогноз AHT август 2025",
        "forecast_type": "aht",
        "method": "ml",
        "granularity": "30min",
        "start_date": "2025-08-01T00:00:00Z",
        "end_date": "2025-08-31T23:59:59Z",
        "status": "running",
        "estimated_completion": "2025-07-15T17:30:00Z",
        "created_at": "2025-07-15T16:00:00Z"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM organizations WHERE id = $1)'
);

-- 4. PUT /api/v1/forecasts/{id} - Update forecast (limited fields when running)
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
    '/api/v1/forecasts/{id}',
    'PUT',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID прогноза"},
            "name": {"type": "string", "description": "Новое название"},
            "status": {"type": "string", "enum": ["pending", "running", "completed", "failed", "cancelled"]},
            "parameters": {"type": "object", "description": "Обновленные параметры (только для pending)"},
            "force_recalculate": {"type": "boolean", "default": false, "description": "Принудительный пересчет"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "organization_id": {"type": "string", "format": "uuid"},
            "department_id": {"type": "string", "format": "uuid"},
            "name": {"type": "string"},
            "forecast_type": {"type": "string"},
            "method": {"type": "string"},
            "granularity": {"type": "string"},
            "start_date": {"type": "string", "format": "date-time"},
            "end_date": {"type": "string", "format": "date-time"},
            "status": {"type": "string"},
            "accuracy_score": {"type": "number"},
            "parameters": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"},
            "updated_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['forecasts'],
    '{
        "id": "abc12345-e89b-12d3-a456-426614174000",
        "name": "Прогноз объема звонков июль 2025 (обновленный)",
        "status": "pending",
        "force_recalculate": true
    }'::jsonb,
    '{
        "id": "abc12345-e89b-12d3-a456-426614174000",
        "organization_id": "123e4567-e89b-12d3-a456-426614174000",
        "department_id": "789e4567-e89b-12d3-a456-426614174000",
        "name": "Прогноз объема звонков июль 2025 (обновленный)",
        "forecast_type": "call_volume",
        "method": "ml",
        "granularity": "30min",
        "start_date": "2025-07-21T00:00:00Z",
        "end_date": "2025-07-27T23:59:59Z",
        "status": "pending",
        "accuracy_score": null,
        "parameters": {
            "model_type": "LSTM",
            "lookback_days": 30,
            "recalculation_requested": true
        },
        "created_at": "2025-07-15T09:00:00Z",
        "updated_at": "2025-07-15T16:30:00Z"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM forecasts WHERE id = $1)'
);

-- 5. DELETE /api/v1/forecasts/{id} - Delete forecast
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
    '/api/v1/forecasts/{id}',
    'DELETE',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID прогноза для удаления"},
            "force": {"type": "boolean", "default": false, "description": "Принудительное удаление (даже если используется)"},
            "cleanup_results": {"type": "boolean", "default": true, "description": "Удалить результаты прогноза"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "success": {"type": "boolean"},
            "message": {"type": "string"},
            "deleted_id": {"type": "string", "format": "uuid"},
            "dependent_schedules": {"type": "array", "description": "Затронутые расписания"}
        }
    }'::jsonb,
    ARRAY['forecasts', 'schedules', 'forecast_results'],
    '{"id": "abc12345-e89b-12d3-a456-426614174000", "force": false, "cleanup_results": true}'::jsonb,
    '{
        "success": true,
        "message": "Прогноз успешно удален",
        "deleted_id": "abc12345-e89b-12d3-a456-426614174000",
        "dependent_schedules": [
            "550e8400-e29b-41d4-a716-446655440000"
        ]
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM forecasts WHERE id = $1)'
);

-- 6. GET /api/v1/forecasts/{id}/accuracy - Get forecast accuracy metrics
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
    '/api/v1/forecasts/{id}/accuracy',
    'GET',
    'forecasts',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID прогноза"},
            "metric_types": {"type": "array", "items": {"type": "string", "enum": ["mape", "wape", "rmse", "mae"]}, "description": "Типы метрик"},
            "breakdown_by": {"type": "string", "enum": ["hour", "day", "week"], "description": "Группировка"},
            "compare_with_actual": {"type": "boolean", "default": true, "description": "Сравнить с фактическими данными"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "forecast_id": {"type": "string", "format": "uuid"},
            "overall_accuracy": {
                "type": "object",
                "properties": {
                    "mape": {"type": "number"},
                    "wape": {"type": "number"},
                    "rmse": {"type": "number"},
                    "mae": {"type": "number"}
                }
            },
            "accuracy_breakdown": {"type": "object"},
            "actual_vs_predicted": {"type": "array"},
            "confidence_intervals": {"type": "object"},
            "calculation_date": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    ARRAY['forecasts', 'forecast_accuracy_metrics', 'actual_call_data'],
    '{"id": "abc12345-e89b-12d3-a456-426614174000", "metric_types": ["mape", "wape"], "breakdown_by": "day"}'::jsonb,
    '{
        "forecast_id": "abc12345-e89b-12d3-a456-426614174000",
        "overall_accuracy": {
            "mape": 0.1244,
            "wape": 0.0987,
            "rmse": 8.45,
            "mae": 6.23
        },
        "accuracy_breakdown": {
            "by_day": {
                "2025-07-21": {"mape": 0.1089, "wape": 0.0892},
                "2025-07-22": {"mape": 0.1234, "wape": 0.1023},
                "2025-07-23": {"mape": 0.1156, "wape": 0.0945}
            }
        },
        "actual_vs_predicted": [
            {"datetime": "2025-07-21T09:00:00Z", "actual": 47, "predicted": 45.2, "error": 1.8},
            {"datetime": "2025-07-21T09:30:00Z", "actual": 51, "predicted": 52.7, "error": -1.7}
        ],
        "confidence_intervals": {
            "80_percent_hit_rate": 0.823,
            "95_percent_hit_rate": 0.945
        },
        "calculation_date": "2025-07-15T18:00:00Z"
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM forecasts WHERE id = $1 AND status = ''completed'')'
);

-- Helper queries for forecasts API endpoints
INSERT INTO api_helper_queries (
    endpoint_path,
    http_method,
    query_name,
    query_sql,
    parameters,
    description
) VALUES 
-- Query for GET /api/v1/forecasts
('/api/v1/forecasts', 'GET', 'list_forecasts_with_accuracy',
'SELECT 
    f.id,
    f.organization_id,
    f.department_id,
    f.name,
    f.forecast_type,
    f.method,
    f.granularity,
    f.start_date,
    f.end_date,
    f.status,
    f.accuracy_score,
    f.created_at,
    f.updated_at,
    COUNT(*) OVER() as total_count
FROM forecasts f
WHERE ($1::uuid IS NULL OR f.organization_id = $1)
  AND ($2::uuid IS NULL OR f.department_id = $2)
  AND ($3::text IS NULL OR f.forecast_type = $3)
  AND ($4::text IS NULL OR f.method = $4)
  AND ($5::text IS NULL OR f.granularity = $5)
  AND ($6::text IS NULL OR f.status = $6)
  AND ($7::date IS NULL OR f.start_date::date >= $7)
  AND ($8::date IS NULL OR f.end_date::date <= $8)
  AND ($9::numeric IS NULL OR f.accuracy_score >= $9)
ORDER BY f.updated_at DESC
LIMIT $10 OFFSET $11;',
'["organization_id", "department_id", "forecast_type", "method", "granularity", "status", "date_from", "date_to", "min_accuracy", "limit", "offset"]'::jsonb,
'Список прогнозов с фильтрацией и метриками точности'),

-- Query for accuracy summary
('/api/v1/forecasts', 'GET', 'get_accuracy_summary',
'SELECT 
    AVG(accuracy_score) as avg_accuracy,
    (SELECT method FROM forecasts WHERE accuracy_score IS NOT NULL GROUP BY method ORDER BY AVG(accuracy_score) DESC LIMIT 1) as best_method,
    COUNT(*) FILTER (WHERE status = ''completed'') as total_completed
FROM forecasts
WHERE ($1::uuid IS NULL OR organization_id = $1)
  AND accuracy_score IS NOT NULL;',
'["organization_id"]'::jsonb,
'Сводка точности прогнозов'),

-- Query for GET /api/v1/forecasts/{id}
('/api/v1/forecasts/{id}', 'GET', 'get_forecast_with_results',
'SELECT 
    f.id,
    f.organization_id,
    f.department_id,
    f.name,
    f.forecast_type,
    f.method,
    f.granularity,
    f.start_date,
    f.end_date,
    f.status,
    f.accuracy_score,
    f.parameters,
    f.results,
    f.created_at,
    f.updated_at
FROM forecasts f
WHERE f.id = $1;',
'["id"]'::jsonb,
'Детальная информация о прогнозе с результатами'),

-- Query for POST /api/v1/forecasts validation
('/api/v1/forecasts', 'POST', 'validate_forecast_creation',
'SELECT 
    EXISTS(SELECT 1 FROM organizations WHERE id = $1) as organization_exists,
    CASE 
        WHEN $2::uuid IS NOT NULL THEN EXISTS(SELECT 1 FROM departments WHERE id = $2)
        ELSE true
    END as department_exists,
    ($5::timestamp > $4::timestamp) as valid_date_range,
    ($5::timestamp > CURRENT_TIMESTAMP) as future_forecast;',
'["organization_id", "department_id", "forecast_type", "start_date", "end_date"]'::jsonb,
'Валидация данных для создания прогноза'),

-- Query for PUT /api/v1/forecasts/{id}
('/api/v1/forecasts/{id}', 'PUT', 'update_forecast_safe',
'UPDATE forecasts 
SET 
    name = COALESCE($2, name),
    status = CASE 
        WHEN status = ''running'' AND $3 NOT IN (''cancelled'', ''failed'') THEN status
        ELSE COALESCE($3, status)
    END,
    parameters = CASE
        WHEN status = ''pending'' THEN COALESCE($4, parameters)
        ELSE parameters
    END,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;',
'["id", "name", "status", "parameters"]'::jsonb,
'Безопасное обновление прогноза с проверкой статуса'),

-- Query for DELETE /api/v1/forecasts/{id}
('/api/v1/forecasts/{id}', 'DELETE', 'check_forecast_dependencies',
'SELECT 
    f.id,
    f.status,
    f.name,
    ARRAY_AGG(s.id) FILTER (WHERE s.id IS NOT NULL) as dependent_schedule_ids,
    COUNT(s.id) as dependent_schedule_count,
    (f.status = ''running'') as is_running
FROM forecasts f
LEFT JOIN schedules s ON s.forecast_id = f.id
WHERE f.id = $1
GROUP BY f.id, f.status, f.name;',
'["id"]'::jsonb,
'Проверка зависимостей перед удалением прогноза'),

-- Query for GET /api/v1/forecasts/{id}/accuracy
('/api/v1/forecasts/{id}/accuracy', 'GET', 'calculate_forecast_accuracy',
'WITH forecast_data AS (
    SELECT f.id, f.results->>''data'' as forecast_results
    FROM forecasts f
    WHERE f.id = $1 AND f.status = ''completed''
),
actual_data AS (
    SELECT acd.datetime, acd.call_volume as actual_value
    FROM actual_call_data acd
    INNER JOIN forecasts f ON f.id = $1
    WHERE acd.datetime BETWEEN f.start_date AND f.end_date
)
SELECT 
    $1 as forecast_id,
    AVG(ABS(fd.predicted - ad.actual_value) / NULLIF(ad.actual_value, 0)) as mape,
    SUM(ABS(fd.predicted - ad.actual_value)) / NULLIF(SUM(ad.actual_value), 0) as wape,
    SQRT(AVG(POWER(fd.predicted - ad.actual_value, 2))) as rmse,
    AVG(ABS(fd.predicted - ad.actual_value)) as mae
FROM forecast_data fd, actual_data ad
WHERE fd.forecast_results IS NOT NULL;',
'["id"]'::jsonb,
'Расчет метрик точности прогноза');

-- Test data for forecasts (Russian language support)
INSERT INTO integration_test_data (
    table_name,
    test_scenario,
    record_identifier,
    test_data,
    bdd_scenario_reference,
    is_active
) VALUES 
('forecasts', 'call_volume_forecast_ml',
'{"id": "abc12345-e89b-12d3-a456-426614174000"}'::jsonb,
'{
    "id": "abc12345-e89b-12d3-a456-426614174000",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "789e4567-e89b-12d3-a456-426614174000",
    "name": "Прогноз объема звонков июль 2025",
    "forecast_type": "call_volume",
    "method": "ml",
    "granularity": "30min",
    "start_date": "2025-07-21T00:00:00Z",
    "end_date": "2025-07-27T23:59:59Z",
    "status": "completed",
    "accuracy_score": 0.8756,
    "parameters": {
        "model_type": "LSTM",
        "lookback_days": 30,
        "features": ["historical_volume", "day_of_week", "holidays"]
    },
    "results": {
        "forecast_points": 336,
        "confidence_intervals": [80, 95]
    }
}'::jsonb,
'forecast-management.feature:25', true),

('forecasts', 'aht_forecast_statistical',
'{"id": "def45678-e89b-12d3-a456-426614174001"}'::jsonb,
'{
    "id": "def45678-e89b-12d3-a456-426614174001",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "890e4567-e89b-12d3-a456-426614174000",
    "name": "Прогноз среднего времени обработки",
    "forecast_type": "aht",
    "method": "statistical",
    "granularity": "1hour",
    "start_date": "2025-08-01T00:00:00Z",
    "end_date": "2025-08-31T23:59:59Z",
    "status": "running",
    "accuracy_score": null,
    "parameters": {
        "model_type": "ARIMA",
        "seasonal_periods": [24, 168],
        "confidence_level": 95
    }
}'::jsonb,
'forecast-management.feature:55', true),

('forecasts', 'occupancy_forecast_hybrid',
'{"id": "ghi78901-e89b-12d3-a456-426614174002"}'::jsonb,
'{
    "id": "ghi78901-e89b-12d3-a456-426614174002",
    "organization_id": "123e4567-e89b-12d3-a456-426614174000",
    "department_id": "901e4567-e89b-12d3-a456-426614174000",
    "name": "Прогноз загрузки агентов",
    "forecast_type": "occupancy",
    "method": "hybrid",
    "granularity": "15min",
    "start_date": "2025-07-28T00:00:00Z",
    "end_date": "2025-08-03T23:59:59Z",
    "status": "completed",
    "accuracy_score": 0.9123,
    "parameters": {
        "ml_weight": 0.7,
        "statistical_weight": 0.3,
        "ensemble_models": ["LSTM", "RandomForest", "ARIMA"]
    }
}'::jsonb,
'forecast-management.feature:85', true),

('forecasts', 'accuracy_test_scenarios',
'{"type": "accuracy"}'::jsonb,
'{
    "metrics": ["mape", "wape", "rmse", "mae"],
    "benchmarks": {
        "excellent": {"mape": "< 0.10", "wape": "< 0.08"},
        "good": {"mape": "0.10-0.20", "wape": "0.08-0.15"},
        "acceptable": {"mape": "0.20-0.30", "wape": "0.15-0.25"},
        "poor": {"mape": "> 0.30", "wape": "> 0.25"}
    },
    "confidence_intervals": [80, 90, 95, 99],
    "breakdown_dimensions": ["hour", "day", "week", "month"]
}'::jsonb,
'forecast-accuracy.feature:15', true);

\echo ''
\echo '======================================'
\echo 'FORECASTS API CONTRACTS SUMMARY'
\echo '======================================'
\echo 'Updated tables: api_contracts, api_helper_queries, integration_test_data'
\echo 'Total API endpoints: 6'
\echo 'Total helper queries: 6' 
\echo 'Total test scenarios: 4'
\echo ''
\echo 'API Endpoints Created:'
\echo '- GET /api/v1/forecasts (list with accuracy metrics)'
\echo '- GET /api/v1/forecasts/{id} (get detailed forecast)' 
\echo '- POST /api/v1/forecasts (create new forecast)'
\echo '- PUT /api/v1/forecasts/{id} (update forecast)'
\echo '- DELETE /api/v1/forecasts/{id} (delete forecast)'
\echo '- GET /api/v1/forecasts/{id}/accuracy (accuracy metrics)'
\echo ''