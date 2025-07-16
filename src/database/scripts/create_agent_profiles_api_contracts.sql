-- API Contracts for agent_profiles table
-- Comprehensive API documentation with Russian language support

-- 1. GET /api/v1/agent-profiles - List all agent profiles with filtering
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles',
    'GET',
    'agent_profiles',
    'Получить список профилей агентов с фильтрацией по отделу и роли',
    '{
        "type": "object",
        "properties": {
            "department": {"type": "string", "description": "Фильтр по отделу"},
            "role": {"type": "string", "description": "Фильтр по роли"},
            "manager_id": {"type": "integer", "description": "ID руководителя"},
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
                        "id": {"type": "integer"},
                        "agent_id": {"type": "integer"},
                        "user_role": {"type": "string"},
                        "department_name": {"type": "string"},
                        "manager_id": {"type": "integer"},
                        "permissions": {"type": "object"},
                        "created_at": {"type": "string", "format": "date-time"}
                    }
                }
            },
            "total": {"type": "integer"},
            "limit": {"type": "integer"},
            "offset": {"type": "integer"}
        }
    }'::jsonb,
    '{
        "department": "техподдержка",
        "role": "agent",
        "limit": 10,
        "offset": 0
    }'::jsonb,
    '{
        "data": [
            {
                "id": 1,
                "agent_id": 100,
                "user_role": "agent",
                "department_name": "техподдержка",
                "manager_id": 50,
                "permissions": {"basic": true, "reports": false},
                "created_at": "2025-07-15T10:00:00Z"
            }
        ],
        "total": 45,
        "limit": 10,
        "offset": 0
    }'::jsonb
);

-- 2. GET /api/v1/agent-profiles/{id} - Get specific agent profile
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles/{id}',
    'GET',
    'agent_profiles',
    'Получить детальную информацию о профиле агента по ID',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer", "description": "ID профиля агента"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer"},
            "agent_id": {"type": "integer"},
            "user_role": {"type": "string"},
            "department_name": {"type": "string"},
            "manager_id": {"type": "integer"},
            "permissions": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"},
            "agent_details": {
                "type": "object",
                "properties": {
                    "first_name": {"type": "string"},
                    "last_name": {"type": "string"},
                    "email": {"type": "string"}
                }
            }
        }
    }'::jsonb,
    '{"id": 1}'::jsonb,
    '{
        "id": 1,
        "agent_id": 100,
        "user_role": "senior_agent",
        "department_name": "техподдержка",
        "manager_id": 50,
        "permissions": {
            "basic": true,
            "reports": true,
            "escalation": true,
            "mentor": false
        },
        "created_at": "2025-07-15T10:00:00Z",
        "agent_details": {
            "first_name": "Анна",
            "last_name": "Петрова",
            "email": "a.petrova@company.ru"
        }
    }'::jsonb
);

-- 3. POST /api/v1/agent-profiles - Create new agent profile
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles',
    'POST',
    'agent_profiles',
    'Создать новый профиль агента с указанием роли и отдела',
    '{
        "type": "object",
        "properties": {
            "agent_id": {"type": "integer", "description": "ID агента из таблицы agents"},
            "user_role": {"type": "string", "enum": ["agent", "senior_agent", "team_lead", "supervisor"], "default": "agent"},
            "department_name": {"type": "string", "description": "Название отдела"},
            "manager_id": {"type": "integer", "description": "ID руководителя"},
            "permissions": {"type": "object", "description": "Права доступа в JSON формате"}
        },
        "required": ["agent_id", "department_name"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer"},
            "agent_id": {"type": "integer"},
            "user_role": {"type": "string"},
            "department_name": {"type": "string"},
            "manager_id": {"type": "integer"},
            "permissions": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    '{
        "agent_id": 105,
        "user_role": "agent",
        "department_name": "продажи",
        "manager_id": 52,
        "permissions": {
            "basic": true,
            "reports": false,
            "escalation": false
        }
    }'::jsonb,
    '{
        "id": 25,
        "agent_id": 105,
        "user_role": "agent",
        "department_name": "продажи",
        "manager_id": 52,
        "permissions": {
            "basic": true,
            "reports": false,
            "escalation": false
        },
        "created_at": "2025-07-15T14:30:00Z"
    }'::jsonb
);

-- 4. PUT /api/v1/agent-profiles/{id} - Update agent profile
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles/{id}',
    'PUT',
    'agent_profiles',
    'Обновить профиль агента (роль, отдел, права доступа)',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer", "description": "ID профиля для обновления"},
            "user_role": {"type": "string", "enum": ["agent", "senior_agent", "team_lead", "supervisor"]},
            "department_name": {"type": "string"},
            "manager_id": {"type": "integer"},
            "permissions": {"type": "object", "description": "Обновленные права доступа"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer"},
            "agent_id": {"type": "integer"},
            "user_role": {"type": "string"},
            "department_name": {"type": "string"},
            "manager_id": {"type": "integer"},
            "permissions": {"type": "object"},
            "created_at": {"type": "string", "format": "date-time"},
            "updated_at": {"type": "string", "format": "date-time"}
        }
    }'::jsonb,
    '{
        "id": 1,
        "user_role": "senior_agent",
        "permissions": {
            "basic": true,
            "reports": true,
            "escalation": true,
            "mentor": true
        }
    }'::jsonb,
    '{
        "id": 1,
        "agent_id": 100,
        "user_role": "senior_agent",
        "department_name": "техподдержка",
        "manager_id": 50,
        "permissions": {
            "basic": true,
            "reports": true,
            "escalation": true,
            "mentor": true
        },
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T14:45:00Z"
    }'::jsonb
);

-- 5. DELETE /api/v1/agent-profiles/{id} - Delete agent profile
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles/{id}',
    'DELETE',
    'agent_profiles',
    'Удалить профиль агента (мягкое удаление, если есть связанные записи)',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "integer", "description": "ID профиля для удаления"},
            "force": {"type": "boolean", "default": false, "description": "Принудительное удаление"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "success": {"type": "boolean"},
            "message": {"type": "string"},
            "deleted_id": {"type": "integer"}
        }
    }'::jsonb,
    '{"id": 25, "force": false}'::jsonb,
    '{
        "success": true,
        "message": "Профиль агента успешно удален",
        "deleted_id": 25
    }'::jsonb
);

-- 6. GET /api/v1/agent-profiles/by-department/{department} - Get profiles by department
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    description,
    request_schema,
    response_schema,
    example_request,
    example_response
) VALUES (
    '/api/v1/agent-profiles/by-department/{department}',
    'GET',
    'agent_profiles',
    'Получить все профили агентов определенного отдела с группировкой по ролям',
    '{
        "type": "object",
        "properties": {
            "department": {"type": "string", "description": "Название отдела"},
            "include_permissions": {"type": "boolean", "default": false},
            "group_by_role": {"type": "boolean", "default": true}
        },
        "required": ["department"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "department_name": {"type": "string"},
            "total_agents": {"type": "integer"},
            "roles": {
                "type": "object",
                "patternProperties": {
                    ".*": {
                        "type": "object",
                        "properties": {
                            "count": {"type": "integer"},
                            "agents": {"type": "array"}
                        }
                    }
                }
            }
        }
    }'::jsonb,
    '{
        "department": "техподдержка",
        "include_permissions": true,
        "group_by_role": true
    }'::jsonb,
    '{
        "department_name": "техподдержка",
        "total_agents": 15,
        "roles": {
            "agent": {
                "count": 10,
                "agents": [
                    {"id": 1, "agent_id": 100, "permissions": {"basic": true}},
                    {"id": 2, "agent_id": 101, "permissions": {"basic": true}}
                ]
            },
            "senior_agent": {
                "count": 4,
                "agents": [
                    {"id": 5, "agent_id": 105, "permissions": {"basic": true, "reports": true}}
                ]
            },
            "team_lead": {
                "count": 1,
                "agents": [
                    {"id": 10, "agent_id": 110, "permissions": {"basic": true, "reports": true, "escalation": true}}
                ]
            }
        }
    }'::jsonb
);

-- Helper queries for agent_profiles API endpoints
INSERT INTO api_helper_queries (
    endpoint_path,
    http_method,
    query_name,
    query_sql,
    parameters,
    description
) VALUES 
-- Query for GET /api/v1/agent-profiles
('/api/v1/agent-profiles', 'GET', 'list_agent_profiles_with_filters',
'SELECT 
    ap.id,
    ap.agent_id,
    ap.user_role,
    ap.department_name,
    ap.manager_id,
    ap.permissions,
    ap.created_at,
    COUNT(*) OVER() as total_count
FROM agent_profiles ap
WHERE ($1::text IS NULL OR ap.department_name ILIKE $1)
  AND ($2::text IS NULL OR ap.user_role = $2)
  AND ($3::integer IS NULL OR ap.manager_id = $3)
ORDER BY ap.created_at DESC
LIMIT $4 OFFSET $5;',
'["department", "role", "manager_id", "limit", "offset"]'::jsonb,
'Список профилей агентов с фильтрацией и пагинацией'),

-- Query for GET /api/v1/agent-profiles/{id}
('/api/v1/agent-profiles/{id}', 'GET', 'get_agent_profile_with_details',
'SELECT 
    ap.id,
    ap.agent_id,
    ap.user_role,
    ap.department_name,
    ap.manager_id,
    ap.permissions,
    ap.created_at,
    jsonb_build_object(
        ''first_name'', a.first_name,
        ''last_name'', a.last_name,
        ''email'', a.email
    ) as agent_details
FROM agent_profiles ap
LEFT JOIN agents a ON ap.agent_id = a.id
WHERE ap.id = $1;',
'["id"]'::jsonb,
'Детальная информация о профиле агента с данными агента'),

-- Query for POST /api/v1/agent-profiles validation
('/api/v1/agent-profiles', 'POST', 'validate_agent_profile_creation',
'SELECT 
    EXISTS(SELECT 1 FROM agents WHERE id = $1) as agent_exists,
    EXISTS(SELECT 1 FROM agent_profiles WHERE agent_id = $1) as profile_exists,
    CASE 
        WHEN $3::integer IS NOT NULL THEN EXISTS(SELECT 1 FROM agents WHERE id = $3)
        ELSE true
    END as manager_exists;',
'["agent_id", "department_name", "manager_id"]'::jsonb,
'Валидация данных для создания профиля агента'),

-- Query for PUT /api/v1/agent-profiles/{id}
('/api/v1/agent-profiles/{id}', 'PUT', 'update_agent_profile',
'UPDATE agent_profiles 
SET 
    user_role = COALESCE($2, user_role),
    department_name = COALESCE($3, department_name),
    manager_id = COALESCE($4, manager_id),
    permissions = COALESCE($5, permissions)
WHERE id = $1
RETURNING id, agent_id, user_role, department_name, manager_id, permissions, created_at, now() as updated_at;',
'["id", "user_role", "department_name", "manager_id", "permissions"]'::jsonb,
'Обновление профиля агента с возвратом обновленных данных'),

-- Query for DELETE /api/v1/agent-profiles/{id}
('/api/v1/agent-profiles/{id}', 'DELETE', 'check_agent_profile_dependencies',
'SELECT 
    EXISTS(SELECT 1 FROM task_assignments WHERE agent_profile_id = $1) as has_task_assignments,
    COUNT(*) as dependency_count
FROM (
    SELECT 1 FROM task_assignments WHERE agent_profile_id = $1
) deps;',
'["id"]'::jsonb,
'Проверка зависимостей перед удалением профиля агента'),

-- Query for GET /api/v1/agent-profiles/by-department/{department}
('/api/v1/agent-profiles/by-department/{department}', 'GET', 'get_department_profiles_grouped',
'SELECT 
    department_name,
    user_role,
    COUNT(*) as count,
    jsonb_agg(
        jsonb_build_object(
            ''id'', id,
            ''agent_id'', agent_id,
            ''permissions'', CASE WHEN $2::boolean THEN permissions ELSE null END
        )
    ) as agents
FROM agent_profiles
WHERE department_name ILIKE $1
GROUP BY department_name, user_role
ORDER BY user_role;',
'["department", "include_permissions"]'::jsonb,
'Группировка профилей агентов по отделу и роли');

-- Test data for agent_profiles
INSERT INTO integration_test_data (
    table_name,
    test_scenario,
    test_data,
    bdd_scenario_reference,
    is_active
) VALUES 
('agent_profiles', 'standard_agent_profile',
'{
    "id": 100,
    "agent_id": 1001,
    "user_role": "agent",
    "department_name": "техподдержка",
    "manager_id": 2001,
    "permissions": {"basic": true, "reports": false},
    "created_at": "2025-07-15T09:00:00Z"
}'::jsonb,
'agent-profiles-management.feature:15', true),

('agent_profiles', 'senior_agent_profile',
'{
    "id": 101,
    "agent_id": 1002,
    "user_role": "senior_agent",
    "department_name": "продажи",
    "manager_id": 2002,
    "permissions": {"basic": true, "reports": true, "escalation": true},
    "created_at": "2025-07-15T09:30:00Z"
}'::jsonb,
'agent-profiles-management.feature:45', true),

('agent_profiles', 'team_lead_profile',
'{
    "id": 102,
    "agent_id": 1003,
    "user_role": "team_lead",
    "department_name": "техподдержка",
    "manager_id": null,
    "permissions": {"basic": true, "reports": true, "escalation": true, "mentor": true, "team_management": true},
    "created_at": "2025-07-15T08:00:00Z"
}'::jsonb,
'agent-profiles-management.feature:75', true),

('agent_profiles', 'russian_department_names',
'{
    "departments": [
        {"name": "техподдержка", "english": "technical_support"},
        {"name": "продажи", "english": "sales"},
        {"name": "консультации", "english": "consulting"},
        {"name": "удержание клиентов", "english": "retention"}
    ]
}'::jsonb,
'agent-profiles-management.feature:95', true);

\echo 'Agent Profiles API contracts created successfully!'
\echo 'Tables updated: api_contracts, api_helper_queries, integration_test_data'
\echo 'Total API endpoints: 6 (GET list, GET by id, POST create, PUT update, DELETE, GET by department)'
\echo 'Total helper queries: 6'
\echo 'Total test scenarios: 4'