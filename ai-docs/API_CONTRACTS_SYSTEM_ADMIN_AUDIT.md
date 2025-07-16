# WFM System Administration & Audit API Contracts

## Comprehensive API Documentation for Enterprise-Scale WFM System

This document provides complete API contracts for system configuration, administrative roles, audit logging, user management, authentication, and workflow management in the WFM system. All APIs support Russian language and enterprise-scale deployment requirements.

---

## 1. SYSTEM CONFIGURATION APIs

### 1.1 Configuration Management

#### GET /api/v1/system/config
**Получить конфигурации системы**

```json
// Request Parameters
{
  "config_category": "system|tenant|application|integration|security|performance",
  "config_scope": "global|tenant|department|user",
  "tenant_id": "uuid",
  "department_id": "uuid",
  "include_encrypted": false,
  "page": 1,
  "per_page": 50
}

// Response
{
  "success": true,
  "data": {
    "configurations": [
      {
        "id": "uuid",
        "config_id": "session_timeout",
        "config_name": "Session Timeout Minutes",
        "config_name_ru": "Тайм-аут сессии в минутах",
        "config_description": "Maximum session duration before automatic logout",
        "config_description_ru": "Максимальная продолжительность сессии до автоматического выхода",
        "config_category": "security",
        "config_scope": "global",
        "tenant_id": null,
        "department_id": null,
        "applies_to_all_tenants": true,
        "config_type": "integer",
        "config_value": "480",
        "default_value": "480",
        "validation_rules": {
          "min": 60,
          "max": 1440,
          "step": 60
        },
        "allowed_values": [],
        "min_value": 60,
        "max_value": 1440,
        "is_encrypted": false,
        "requires_restart": false,
        "is_user_configurable": true,
        "is_visible_in_ui": true,
        "requires_admin_approval": false,
        "display_order": 1,
        "display_group": "Безопасность",
        "help_text": "Установите время в минутах для автоматического завершения неактивных сессий",
        "configuration_ui_component": "number_input",
        "last_modified_by": "uuid",
        "change_reason": "Security policy update",
        "previous_value": "360",
        "is_active": true,
        "effective_date": "2025-07-15T10:00:00Z",
        "expiry_date": null,
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T10:00:00Z"
      }
    ],
    "total": 125,
    "page": 1,
    "per_page": 50,
    "total_pages": 3
  },
  "meta": {
    "categories_summary": {
      "system": 25,
      "security": 18,
      "tenant": 42,
      "integration": 15,
      "performance": 25
    },
    "encrypted_configs_count": 8,
    "restart_required_count": 3
  }
}
```

#### POST /api/v1/system/config
**Создать новую конфигурацию**

```json
// Request
{
  "config_id": "max_file_upload_size",
  "config_name": "Maximum File Upload Size",
  "config_name_ru": "Максимальный размер загружаемого файла",
  "config_description": "Maximum size in MB for file uploads",
  "config_description_ru": "Максимальный размер файла для загрузки в МБ",
  "config_category": "system",
  "config_scope": "tenant",
  "tenant_id": "uuid",
  "config_type": "integer",
  "config_value": "100",
  "default_value": "50",
  "validation_rules": {
    "min": 1,
    "max": 1000
  },
  "requires_restart": false,
  "is_user_configurable": true,
  "display_group": "Файловая система",
  "help_text": "Ограничение размера файлов для предотвращения перегрузки сервера"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "config_id": "max_file_upload_size",
    "message": "Configuration created successfully",
    "message_ru": "Конфигурация успешно создана",
    "requires_restart": false,
    "change_id": "change_uuid"
  }
}
```

#### PUT /api/v1/system/config/{config_id}
**Обновить конфигурацию**

```json
// Request
{
  "config_value": "200",
  "change_reason": "Increased limit due to user requirements",
  "change_reason_ru": "Увеличен лимит по требованию пользователей",
  "notify_affected_users": true,
  "effective_date": "2025-07-16T00:00:00Z"
}

// Response
{
  "success": true,
  "data": {
    "config_id": "max_file_upload_size",
    "previous_value": "100",
    "new_value": "200",
    "requires_restart": false,
    "affected_tenants": ["uuid1", "uuid2"],
    "affected_users_count": 250,
    "change_id": "change_uuid",
    "message_ru": "Конфигурация успешно обновлена"
  }
}
```

### 1.2 Configuration Templates and Presets

#### GET /api/v1/system/config/templates
**Получить шаблоны конфигураций**

```json
// Response
{
  "success": true,
  "data": {
    "templates": [
      {
        "template_name": "Высокая безопасность",
        "template_description": "Повышенные настройки безопасности для критических систем",
        "category": "security",
        "configurations": [
          {
            "config_id": "session_timeout",
            "value": "240",
            "reason": "Более короткие сессии для повышения безопасности"
          },
          {
            "config_id": "max_concurrent_sessions",
            "value": "1",
            "reason": "Одна активная сессия на пользователя"
          },
          {
            "config_id": "enable_mfa",
            "value": "true",
            "reason": "Обязательная двухфакторная аутентификация"
          }
        ]
      }
    ]
  }
}
```

#### POST /api/v1/system/config/apply-template
**Применить шаблон конфигураций**

```json
// Request
{
  "template_name": "Высокая безопасность",
  "target_scope": "tenant",
  "target_ids": ["tenant_uuid"],
  "override_existing": true,
  "apply_reason": "Security compliance requirements",
  "apply_reason_ru": "Требования соответствия безопасности"
}

// Response
{
  "success": true,
  "data": {
    "applied_configurations": 15,
    "skipped_configurations": 2,
    "affected_users": 500,
    "restart_required": false,
    "change_summary": [
      {
        "config_id": "session_timeout",
        "old_value": "480",
        "new_value": "240",
        "impact": "Пользователи будут автоматически выходить из системы чаще"
      }
    ]
  }
}
```

---

## 2. ADMINISTRATIVE ROLES APIs

### 2.1 Role Management

#### GET /api/v1/admin/roles
**Получить административные роли**

```json
// Request Parameters
{
  "role_category": "system_admin|tenant_admin|department_admin|functional_admin|read_only",
  "permission_scope": "global|tenant|department|limited",
  "is_assignable": true,
  "tenant_id": "uuid",
  "include_permissions": true,
  "page": 1,
  "per_page": 20
}

// Response
{
  "success": true,
  "data": {
    "roles": [
      {
        "id": "uuid",
        "role_id": "system_admin",
        "role_name": "System Administrator",
        "role_name_ru": "Системный администратор",
        "role_description": "Full system administration capabilities",
        "role_description_ru": "Полные возможности администрирования системы",
        "role_level": 1,
        "parent_role_id": null,
        "role_category": "system_admin",
        "permission_scope": "global",
        "tenant_scope": [],
        "department_scope": [],
        "system_permissions": {
          "all": true,
          "user_management": true,
          "system_config": true,
          "audit_access": true
        },
        "data_permissions": {
          "all_data_access": true,
          "export_data": true,
          "delete_data": true
        },
        "functional_permissions": {
          "workflow_administration": true,
          "integration_management": true,
          "reporting_administration": true
        },
        "capabilities": {
          "can_create_users": true,
          "can_modify_users": true,
          "can_delete_users": true,
          "can_manage_roles": true,
          "can_view_audit_logs": true,
          "can_modify_system_config": true,
          "can_manage_integrations": true,
          "can_access_all_data": true
        },
        "security_restrictions": {
          "requires_mfa": true,
          "session_timeout_minutes": 480,
          "ip_restrictions": ["192.168.1.0/24"],
          "allowed_login_hours": {
            "monday": "08:00-18:00",
            "tuesday": "08:00-18:00",
            "wednesday": "08:00-18:00",
            "thursday": "08:00-18:00",
            "friday": "08:00-18:00"
          },
          "max_concurrent_sessions": 3
        },
        "role_behavior": {
          "is_assignable": true,
          "requires_approval_to_assign": true,
          "auto_expire_days": null
        },
        "assigned_users_count": 5,
        "active_sessions_count": 3,
        "created_by": "uuid",
        "approved_by": "uuid",
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T10:00:00Z"
      }
    ],
    "total": 25,
    "page": 1,
    "per_page": 20,
    "total_pages": 2
  },
  "meta": {
    "role_categories_summary": {
      "system_admin": 3,
      "tenant_admin": 8,
      "department_admin": 10,
      "functional_admin": 12,
      "read_only": 5
    },
    "permission_scopes_summary": {
      "global": 5,
      "tenant": 15,
      "department": 18,
      "limited": 10
    }
  }
}
```

#### POST /api/v1/admin/roles
**Создать административную роль**

```json
// Request
{
  "role_id": "hr_specialist",
  "role_name": "HR Specialist",
  "role_name_ru": "Специалист по кадрам",
  "role_description": "HR department specialist with employee management capabilities",
  "role_description_ru": "Специалист HR-отдела с возможностями управления персоналом",
  "role_category": "functional_admin",
  "permission_scope": "department",
  "parent_role_id": "department_admin",
  "tenant_scope": ["tenant_uuid"],
  "department_scope": ["hr_dept_uuid"],
  "system_permissions": {
    "user_management": true,
    "view_reports": true
  },
  "functional_permissions": {
    "employee_profiles": true,
    "vacation_management": true,
    "attendance_tracking": true
  },
  "security_restrictions": {
    "requires_mfa": true,
    "session_timeout_minutes": 480,
    "max_concurrent_sessions": 2
  }
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "role_id": "hr_specialist",
    "message": "Administrative role created successfully",
    "message_ru": "Административная роль успешно создана",
    "requires_approval": true,
    "approval_workflow_id": "workflow_uuid"
  }
}
```

### 2.2 Role Assignments

#### GET /api/v1/admin/role-assignments
**Получить назначения ролей**

```json
// Request Parameters
{
  "user_id": "uuid",
  "role_id": "hr_specialist",
  "assignment_status": "pending|approved|active|suspended|expired|revoked",
  "assignment_scope": "full|limited|temporary|delegated",
  "tenant_id": "uuid",
  "department_id": "uuid",
  "include_expired": false,
  "page": 1,
  "per_page": 50
}

// Response
{
  "success": true,
  "data": {
    "assignments": [
      {
        "id": "uuid",
        "assignment_id": "assign_001",
        "user_id": "uuid",
        "user_name": "Иван Петров",
        "user_email": "ivan.petrov@company.ru",
        "role_id": "hr_specialist",
        "role_name": "Специалист по кадрам",
        "tenant_scope": ["tenant_uuid"],
        "department_scope": ["hr_dept_uuid"],
        "assignment_scope": "full",
        "effective_start": "2025-07-15T00:00:00Z",
        "effective_end": "2026-07-15T00:00:00Z",
        "is_permanent": false,
        "assignment_status": "active",
        "assigned_by": "uuid",
        "assigned_by_name": "Администратор Системы",
        "approved_by": "uuid",
        "approved_by_name": "Директор HR",
        "approved_at": "2025-07-15T10:30:00Z",
        "assignment_reason": "Новый сотрудник HR отдела",
        "approval_notes": "Подтверждено руководством HR",
        "conditions": {
          "probation_period": "3 months",
          "requires_mentoring": true
        },
        "usage_tracking": {
          "last_used_at": "2025-07-15T15:30:00Z",
          "usage_count": 45,
          "avg_daily_usage": 2.5
        },
        "created_at": "2025-07-15T09:00:00Z",
        "updated_at": "2025-07-15T10:30:00Z"
      }
    ],
    "total": 150,
    "page": 1,
    "per_page": 50,
    "total_pages": 3
  },
  "meta": {
    "status_summary": {
      "active": 120,
      "pending": 15,
      "suspended": 8,
      "expired": 7
    },
    "scope_summary": {
      "full": 100,
      "limited": 30,
      "temporary": 15,
      "delegated": 5
    }
  }
}
```

#### POST /api/v1/admin/role-assignments
**Назначить роль пользователю**

```json
// Request
{
  "user_id": "uuid",
  "role_id": "hr_specialist",
  "tenant_scope": ["tenant_uuid"],
  "department_scope": ["hr_dept_uuid"],
  "assignment_scope": "full",
  "effective_start": "2025-07-16T00:00:00Z",
  "effective_end": "2026-07-16T00:00:00Z",
  "is_permanent": false,
  "assignment_reason": "Promoted to HR specialist position",
  "assignment_reason_ru": "Повышен до должности специалиста по кадрам",
  "conditions": {
    "probation_period": "3 months",
    "requires_training": true,
    "mentor_user_id": "mentor_uuid"
  },
  "notify_user": true,
  "notify_managers": true
}

// Response
{
  "success": true,
  "data": {
    "assignment_id": "assign_002",
    "status": "pending",
    "message": "Role assignment created and pending approval",
    "message_ru": "Назначение роли создано и ожидает одобрения",
    "approval_required": true,
    "approval_workflow_id": "workflow_uuid",
    "estimated_approval_time": "24 hours",
    "next_approver": {
      "name": "Директор HR",
      "email": "hr.director@company.ru"
    }
  }
}
```

---

## 3. AUDIT LOGGING APIs

### 3.1 Audit Log Queries

#### GET /api/v1/audit/logs
**Получить журналы аудита**

```json
// Request Parameters
{
  "event_type": "user_login|user_logout|data_create|data_update|data_delete|config_change|role_assignment|permission_change|system_access|integration_call|workflow_action|report_generation|export_data",
  "event_category": "authentication|authorization|data_modification|system_administration|business_process|integration|security|compliance",
  "user_id": "uuid",
  "tenant_id": "uuid",
  "department_id": "uuid",
  "affected_table": "employees",
  "event_status": "success|failure|warning|error",
  "risk_level": "low|medium|high|critical",
  "start_timestamp": "2025-07-15T00:00:00Z",
  "end_timestamp": "2025-07-15T23:59:59Z",
  "requires_review": true,
  "correlation_id": "correlation_uuid",
  "include_field_changes": true,
  "page": 1,
  "per_page": 100
}

// Response
{
  "success": true,
  "data": {
    "audit_logs": [
      {
        "id": "uuid",
        "audit_id": "audit_001",
        "event_type": "data_update",
        "event_category": "data_modification",
        "event_description": "Employee profile updated",
        "event_description_ru": "Профиль сотрудника обновлен",
        "user_id": "uuid",
        "user_name": "Анна Иванова",
        "user_role": "HR Specialist",
        "session_id": "session_123",
        "tenant_id": "uuid",
        "tenant_name": "ООО ТехноСервис",
        "department_id": "uuid",
        "department_name": "Отдел кадров",
        "system_context": {
          "source_system": "WFM",
          "source_module": "employee_management",
          "source_function": "update_employee_profile",
          "client_ip_address": "192.168.1.100",
          "user_agent": "Mozilla/5.0..."
        },
        "data_context": {
          "affected_table": "employees",
          "affected_record_id": "emp_uuid",
          "affected_record_type": "employee_profile"
        },
        "field_changes": {
          "email": {
            "before": "old.email@company.ru",
            "after": "new.email@company.ru"
          },
          "phone": {
            "before": "+7 (123) 456-78-90",
            "after": "+7 (987) 654-32-10"
          },
          "position_ru": {
            "before": "Младший специалист",
            "after": "Специалист"
          }
        },
        "operation_data": {
          "update_reason": "Employee promotion",
          "update_reason_ru": "Повышение сотрудника",
          "batch_operation": false,
          "validation_passed": true
        },
        "request_data": {
          "request_id": "req_uuid",
          "request_source": "web_ui",
          "request_size_bytes": 1024
        },
        "response_data": {
          "response_code": 200,
          "response_time_ms": 150,
          "records_affected": 1
        },
        "event_outcome": {
          "event_status": "success",
          "error_code": null,
          "error_message": null
        },
        "risk_assessment": {
          "risk_level": "medium",
          "compliance_flags": ["GDPR", "PCI_DSS"],
          "requires_review": false,
          "auto_risk_score": 45
        },
        "timing": {
          "event_timestamp": "2025-07-15T14:30:45Z",
          "processing_duration_ms": 150,
          "server_timezone": "Europe/Moscow"
        },
        "metadata": {
          "correlation_id": "corr_uuid",
          "parent_audit_id": null,
          "tags": ["employee_update", "profile_change"],
          "retention_period_years": 7
        },
        "created_at": "2025-07-15T14:30:45Z"
      }
    ],
    "total": 50000,
    "page": 1,
    "per_page": 100,
    "total_pages": 500
  },
  "meta": {
    "summary_statistics": {
      "total_events": 50000,
      "successful_events": 47500,
      "failed_events": 2500,
      "high_risk_events": 150,
      "requires_review_count": 25
    },
    "event_type_distribution": {
      "user_login": 15000,
      "data_update": 20000,
      "data_create": 8000,
      "config_change": 500,
      "role_assignment": 200
    },
    "time_range_summary": {
      "earliest_event": "2025-07-15T00:01:00Z",
      "latest_event": "2025-07-15T23:58:30Z",
      "peak_activity_hour": "14:00"
    }
  }
}
```

### 3.2 Advanced Audit Analytics

#### GET /api/v1/audit/analytics/user-activity
**Аналитика активности пользователей**

```json
// Request Parameters
{
  "user_id": "uuid",
  "start_date": "2025-07-01",
  "end_date": "2025-07-15",
  "group_by": "day|hour|user|department",
  "include_risk_analysis": true,
  "include_patterns": true
}

// Response
{
  "success": true,
  "data": {
    "user_activity_summary": {
      "user_id": "uuid",
      "user_name": "Анна Иванова",
      "total_events": 1250,
      "successful_operations": 1200,
      "failed_operations": 50,
      "success_rate": 96.0,
      "peak_activity_periods": [
        {
          "period": "09:00-10:00",
          "event_count": 150,
          "avg_events_per_day": 10
        }
      ],
      "risk_profile": {
        "overall_risk_score": 25,
        "risk_level": "low",
        "suspicious_patterns": [],
        "compliance_violations": 0
      }
    },
    "daily_breakdown": [
      {
        "date": "2025-07-15",
        "total_events": 85,
        "login_events": 2,
        "data_modifications": 45,
        "system_access": 30,
        "high_risk_events": 0,
        "peak_hour": "14:00"
      }
    ],
    "operation_patterns": {
      "most_frequent_operations": [
        {
          "operation": "employee_profile_view",
          "count": 300,
          "percentage": 24.0
        },
        {
          "operation": "schedule_view",
          "count": 250,
          "percentage": 20.0
        }
      ],
      "unusual_activities": [
        {
          "description": "Высокая активность в нерабочие часы",
          "occurrences": 5,
          "risk_level": "medium"
        }
      ]
    }
  }
}
```

#### POST /api/v1/audit/analytics/compliance-report
**Генерация отчета соответствия**

```json
// Request
{
  "report_type": "GDPR|SOX|HIPAA|PCI_DSS|custom",
  "start_date": "2025-07-01",
  "end_date": "2025-07-15",
  "scope": {
    "tenant_ids": ["uuid"],
    "department_ids": ["uuid"],
    "user_ids": ["uuid"]
  },
  "include_recommendations": true,
  "output_format": "json|pdf|excel",
  "language": "ru"
}

// Response
{
  "success": true,
  "data": {
    "report_id": "compliance_report_uuid",
    "report_type": "GDPR",
    "generation_status": "completed",
    "compliance_summary": {
      "overall_compliance_score": 92,
      "total_violations": 5,
      "high_severity_violations": 1,
      "medium_severity_violations": 2,
      "low_severity_violations": 2
    },
    "key_findings": [
      {
        "finding_type": "data_access_without_consent",
        "severity": "high",
        "description": "Доступ к персональным данным без документированного согласия",
        "affected_records": 15,
        "recommendation": "Обновить процедуры получения согласия",
        "remediation_priority": "immediate"
      }
    ],
    "data_subject_rights": {
      "access_requests": 25,
      "deletion_requests": 8,
      "portability_requests": 3,
      "avg_response_time_days": 12,
      "sla_compliance_rate": 88
    },
    "download_links": {
      "json": "/api/v1/reports/download/compliance_report_uuid.json",
      "pdf": "/api/v1/reports/download/compliance_report_uuid.pdf",
      "excel": "/api/v1/reports/download/compliance_report_uuid.xlsx"
    },
    "generated_at": "2025-07-15T16:00:00Z",
    "valid_until": "2025-07-22T16:00:00Z"
  }
}
```

---

## 4. USER MANAGEMENT APIs

### 4.1 User Session Management

#### GET /api/v1/users/sessions
**Получить активные сессии пользователей**

```json
// Request Parameters
{
  "user_id": "uuid",
  "session_status": "active|expired|terminated|locked",
  "tenant_id": "uuid",
  "department_id": "uuid",
  "client_ip_filter": "192.168.1.0/24",
  "login_method": "password|sso|mfa|api_key",
  "include_session_data": false,
  "page": 1,
  "per_page": 50
}

// Response
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": "uuid",
        "session_id": "session_abc123",
        "user_id": "uuid",
        "user_name": "Петр Сидоров",
        "user_email": "petr.sidorov@company.ru",
        "session_details": {
          "session_start": "2025-07-15T09:00:00Z",
          "session_end": null,
          "last_activity": "2025-07-15T15:45:00Z",
          "session_duration_minutes": 405,
          "idle_time_minutes": 15
        },
        "authentication": {
          "login_method": "sso",
          "mfa_verified": true,
          "mfa_method": "app_authenticator",
          "authentication_strength": "strong"
        },
        "client_information": {
          "client_ip_address": "192.168.1.150",
          "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
          "browser": "Chrome 91.0",
          "operating_system": "Windows 10",
          "device_type": "desktop"
        },
        "session_context": {
          "tenant_id": "uuid",
          "tenant_name": "ООО ТехноСервис",
          "department_id": "uuid",
          "department_name": "IT Отдел",
          "login_location": "Головной офис",
          "login_location_ru": "Головной офис"
        },
        "session_status": {
          "status": "active",
          "is_elevated": false,
          "security_level": "standard",
          "termination_reason": null
        },
        "session_metadata": {
          "concurrent_sessions": 1,
          "session_flags": ["mobile_optimized", "secure_channel"],
          "last_page_visited": "/dashboard",
          "total_page_views": 45
        },
        "security_indicators": {
          "suspicious_activity": false,
          "location_mismatch": false,
          "device_change": false,
          "risk_score": 10
        },
        "created_at": "2025-07-15T09:00:00Z",
        "updated_at": "2025-07-15T15:45:00Z"
      }
    ],
    "total": 250,
    "page": 1,
    "per_page": 50,
    "total_pages": 5
  },
  "meta": {
    "session_statistics": {
      "total_active_sessions": 250,
      "total_concurrent_users": 180,
      "avg_session_duration_minutes": 320,
      "peak_concurrent_sessions": 300,
      "inactive_sessions_count": 45
    },
    "login_method_distribution": {
      "password": 100,
      "sso": 120,
      "mfa": 80,
      "api_key": 15
    },
    "security_alerts": {
      "suspicious_sessions": 2,
      "location_mismatches": 1,
      "multiple_device_logins": 5
    }
  }
}
```

#### DELETE /api/v1/users/sessions/{session_id}
**Завершить сессию пользователя**

```json
// Request Body (optional)
{
  "termination_reason": "administrative_action",
  "termination_reason_ru": "Административное действие",
  "notify_user": true,
  "force_logout_all_devices": false
}

// Response
{
  "success": true,
  "data": {
    "session_id": "session_abc123",
    "user_id": "uuid",
    "user_name": "Петр Сидоров",
    "terminated_at": "2025-07-15T16:00:00Z",
    "termination_reason": "administrative_action",
    "termination_reason_ru": "Административное действие",
    "session_duration_minutes": 420,
    "notification_sent": true,
    "message": "User session terminated successfully",
    "message_ru": "Сессия пользователя успешно завершена"
  }
}
```

### 4.2 User Permission Analysis

#### GET /api/v1/users/{user_id}/permissions/effective
**Получить эффективные разрешения пользователя**

```json
// Response
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "user_name": "Мария Козлова",
    "effective_permissions": {
      "system_permissions": [
        {
          "permission_id": "user_management",
          "permission_name": "User Management",
          "permission_name_ru": "Управление пользователями",
          "permission_level": "write",
          "granted_through": [
            {
              "role_id": "hr_specialist",
              "role_name": "Специалист по кадрам",
              "grant_type": "explicit"
            }
          ],
          "effective_scope": {
            "scope_type": "department",
            "scope_ids": ["hr_dept_uuid"],
            "scope_names": ["Отдел кадров"]
          },
          "conditions": {
            "time_restrictions": null,
            "location_restrictions": null,
            "approval_required": false
          }
        }
      ],
      "data_permissions": [
        {
          "table_name": "employees",
          "table_name_ru": "Сотрудники",
          "permissions": {
            "read": true,
            "write": true,
            "delete": false,
            "export": true
          },
          "field_level_permissions": {
            "personal_data": "restricted",
            "salary_data": "none",
            "contact_info": "full"
          },
          "row_level_filters": {
            "department_filter": "hr_dept_uuid",
            "tenant_filter": "tenant_uuid"
          }
        }
      ],
      "functional_permissions": [
        {
          "module": "employee_management",
          "module_name_ru": "Управление персоналом",
          "functions": [
            {
              "function_id": "create_employee_profile",
              "function_name_ru": "Создание профиля сотрудника",
              "allowed": true,
              "restrictions": ["requires_supervisor_approval"]
            },
            {
              "function_id": "modify_work_schedule",
              "function_name_ru": "Изменение рабочего расписания",
              "allowed": true,
              "restrictions": ["own_department_only"]
            }
          ]
        }
      ]
    },
    "permission_inheritance": {
      "direct_role_assignments": [
        {
          "role_id": "hr_specialist",
          "role_name": "Специалист по кадрам",
          "assignment_scope": "department"
        }
      ],
      "inherited_permissions": [
        {
          "source_role": "department_admin",
          "inherited_via": "hr_specialist",
          "permissions_count": 15
        }
      ],
      "delegated_permissions": []
    },
    "access_restrictions": {
      "ip_restrictions": [],
      "time_restrictions": {
        "allowed_hours": "08:00-18:00",
        "timezone": "Europe/Moscow"
      },
      "location_restrictions": ["main_office"],
      "device_restrictions": ["registered_devices_only"]
    },
    "calculated_at": "2025-07-15T16:00:00Z",
    "cache_expires_at": "2025-07-15T17:00:00Z"
  }
}
```

---

## 5. SSO AUTHENTICATION APIs

### 5.1 SSO Provider Management

#### GET /api/v1/sso/providers
**Получить провайдеров SSO**

```json
// Response
{
  "success": true,
  "data": {
    "providers": [
      {
        "provider_id": "uuid",
        "provider_name": "Corporate Active Directory",
        "provider_name_ru": "Корпоративный Active Directory",
        "provider_type": "active_directory",
        "provider_status": "active",
        "configuration": {
          "base_url": "ldap://corp.example.ru",
          "authorization_url": "https://corp.example.ru/auth",
          "token_url": "https://corp.example.ru/token",
          "userinfo_url": "https://corp.example.ru/userinfo",
          "client_id": "wfm_application",
          "scope": "profile email groups",
          "redirect_uri": "https://wfm.company.ru/auth/callback"
        },
        "provider_specific_config": {
          "domain": "CORP",
          "use_ssl": true,
          "port": 636,
          "base_dn": "DC=corp,DC=ru",
          "user_search_filter": "(sAMAccountName={0})",
          "group_search_base": "OU=Groups,DC=corp,DC=ru"
        },
        "priority_order": 1,
        "health_status": {
          "status": "healthy",
          "last_check": "2025-07-15T15:55:00Z",
          "response_time_ms": 150,
          "uptime_percentage": 99.8
        },
        "usage_statistics": {
          "total_users": 1250,
          "active_sessions": 320,
          "login_attempts_today": 450,
          "successful_logins_today": 440,
          "failed_logins_today": 10
        },
        "created_at": "2025-01-15T10:00:00Z",
        "updated_at": "2025-07-15T12:00:00Z"
      }
    ]
  }
}
```

#### POST /api/v1/sso/providers/{provider_id}/test-connection
**Тестировать подключение к провайдеру SSO**

```json
// Request
{
  "test_type": "connectivity|authentication|user_lookup|group_lookup",
  "test_credentials": {
    "username": "test.user@corp.ru",
    "password": "encrypted_test_password"
  },
  "timeout_seconds": 30
}

// Response
{
  "success": true,
  "data": {
    "test_results": {
      "connectivity": {
        "status": "success",
        "response_time_ms": 145,
        "ssl_certificate_valid": true,
        "dns_resolution": "success"
      },
      "authentication": {
        "status": "success",
        "user_found": true,
        "authentication_method": "LDAP",
        "groups_retrieved": 5
      },
      "user_attributes": {
        "username": "test.user",
        "display_name": "Тестовый Пользователь",
        "email": "test.user@corp.ru",
        "employee_number": "EMP001",
        "department": "IT Отдел"
      },
      "group_memberships": [
        "WFM_Users",
        "IT_Department", 
        "All_Employees"
      ]
    },
    "overall_status": "healthy",
    "recommendations": [
      "Соединение работает корректно",
      "Рекомендуется включить кэширование групп для улучшения производительности"
    ]
  }
}
```

### 5.2 SSO User Mapping

#### GET /api/v1/sso/users/mappings
**Получить сопоставления пользователей SSO**

```json
// Request Parameters
{
  "provider_id": "uuid",
  "mapping_status": "active|inactive|pending|error",
  "mapping_type": "automatic|manual|hybrid|jit",
  "internal_user_id": "uuid",
  "external_user_id": "external_123",
  "include_last_login": true,
  "page": 1,
  "per_page": 50
}

// Response
{
  "success": true,
  "data": {
    "user_mappings": [
      {
        "sso_user_id": "uuid",
        "provider_id": "uuid",
        "provider_name": "Corporate Active Directory",
        "external_user_id": "EMP001",
        "internal_user_id": "uuid",
        "user_details": {
          "email": "ivan.petrov@corp.ru",
          "username": "ivan.petrov",
          "display_name": "Ivan Petrov",
          "display_name_ru": "Иван Петров",
          "employee_number": "EMP001"
        },
        "mapping_configuration": {
          "mapping_type": "automatic",
          "mapping_status": "active",
          "auto_create_user": true,
          "auto_update_attributes": true,
          "sync_groups": true
        },
        "login_statistics": {
          "last_login": "2025-07-15T08:30:00Z",
          "login_count": 245,
          "avg_logins_per_month": 22,
          "last_login_location": "Головной офис"
        },
        "provider_attributes": {
          "department": "IT Отдел",
          "title": "Системный администратор",
          "manager": "sergey.manager@corp.ru",
          "phone": "+7 (123) 456-78-90",
          "office_location": "Москва"
        },
        "sync_status": {
          "last_sync": "2025-07-15T06:00:00Z",
          "sync_status": "success",
          "attributes_updated": 3,
          "sync_errors": []
        },
        "created_at": "2025-01-15T10:00:00Z",
        "updated_at": "2025-07-15T06:00:00Z"
      }
    ],
    "total": 1250,
    "page": 1,
    "per_page": 50,
    "total_pages": 25
  },
  "meta": {
    "mapping_statistics": {
      "total_mappings": 1250,
      "active_mappings": 1200,
      "automatic_mappings": 1100,
      "manual_mappings": 150,
      "sync_errors": 5
    },
    "provider_summary": {
      "active_directory": 1000,
      "azure_ad": 200,
      "google_workspace": 50
    }
  }
}
```

#### POST /api/v1/sso/users/mappings/sync
**Синхронизировать пользователей SSO**

```json
// Request
{
  "provider_id": "uuid",
  "sync_type": "full|incremental|specific_users",
  "user_filter": {
    "departments": ["IT", "HR"],
    "active_only": true,
    "last_login_after": "2025-01-01T00:00:00Z"
  },
  "sync_options": {
    "create_new_users": true,
    "update_existing_users": true,
    "disable_removed_users": true,
    "sync_group_memberships": true,
    "dry_run": false
  },
  "notification_settings": {
    "notify_on_completion": true,
    "notify_on_errors": true,
    "notification_emails": ["admin@company.ru"]
  }
}

// Response
{
  "success": true,
  "data": {
    "sync_job_id": "sync_job_uuid",
    "sync_status": "in_progress",
    "estimated_completion": "2025-07-15T17:00:00Z",
    "progress": {
      "total_users": 1250,
      "processed_users": 0,
      "created_users": 0,
      "updated_users": 0,
      "disabled_users": 0,
      "errors": 0
    },
    "message": "User synchronization started",
    "message_ru": "Синхронизация пользователей запущена",
    "status_endpoint": "/api/v1/sso/sync-jobs/sync_job_uuid/status"
  }
}
```

---

## 6. WORKFLOW MANAGEMENT APIs

### 6.1 Workflow Definition Management

#### GET /api/v1/workflows/definitions
**Получить определения рабочих процессов**

```json
// Request Parameters
{
  "workflow_type": "vacation|overtime|shift_exchange|absence|schedule_change|training|performance_review|equipment_request|custom",
  "is_active": true,
  "include_states": true,
  "include_business_rules": true,
  "page": 1,
  "per_page": 20
}

// Response
{
  "success": true,
  "data": {
    "workflow_definitions": [
      {
        "id": 1,
        "workflow_name": "vacation_standard",
        "workflow_type": "vacation",
        "display_name_ru": "Стандартный отпуск",
        "description_ru": "Стандартный процесс согласования отпуска",
        "version": 1,
        "is_active": true,
        "state_machine_config": {
          "states": ["draft", "pending_supervisor", "pending_hr", "approved", "rejected"],
          "initial_state": "draft",
          "transitions": {
            "draft": ["pending_supervisor", "cancelled"],
            "pending_supervisor": ["pending_hr", "rejected", "returned_to_draft"],
            "pending_hr": ["approved", "rejected", "returned_to_supervisor"],
            "approved": [],
            "rejected": []
          }
        },
        "business_rules": {
          "min_advance_days": 14,
          "max_vacation_days": 28,
          "requires_coverage": true,
          "blackout_periods": ["2025-12-25", "2025-12-31"],
          "max_concurrent_requests": 3
        },
        "default_settings": {
          "approval_timeout_hours": 48,
          "escalation_timeout_hours": 72,
          "auto_reminder_hours": 24,
          "notification_templates": {
            "request_submitted": "vacation_request_submitted_ru",
            "approval_required": "vacation_approval_required_ru",
            "request_approved": "vacation_request_approved_ru"
          }
        },
        "workflow_states": [
          {
            "id": 1,
            "state_key": "draft",
            "state_name_ru": "Черновик",
            "description_ru": "Заявка создана, но не отправлена",
            "state_type": "initial",
            "state_config": {
              "editable": true,
              "timeout_hours": 24,
              "auto_save": true
            },
            "color_code": "#F3F4F6",
            "icon_name": "edit",
            "sort_order": 1
          },
          {
            "id": 2,
            "state_key": "pending_supervisor",
            "state_name_ru": "Ожидает руководителя",
            "description_ru": "Ожидает согласования непосредственного руководителя",
            "state_type": "intermediate",
            "state_config": {
              "timeout_hours": 48,
              "escalation_hours": 72,
              "reminder_hours": 24
            },
            "color_code": "#FEF3C7",
            "icon_name": "clock",
            "sort_order": 2
          }
        ],
        "performance_metrics": {
          "avg_processing_time_hours": 18,
          "approval_rate_percentage": 92,
          "escalation_rate_percentage": 8,
          "active_instances": 25
        },
        "created_by": 1,
        "created_at": "2025-07-15T10:00:00Z",
        "updated_at": "2025-07-15T10:00:00Z"
      }
    ],
    "total": 15,
    "page": 1,
    "per_page": 20,
    "total_pages": 1
  }
}
```

#### POST /api/v1/workflows/definitions
**Создать определение рабочего процесса**

```json
// Request
{
  "workflow_name": "equipment_request_standard",
  "workflow_type": "equipment_request",
  "display_name_ru": "Стандартный запрос оборудования",
  "description_ru": "Процесс согласования запросов на получение оборудования",
  "state_machine_config": {
    "states": ["draft", "pending_manager", "pending_it", "pending_finance", "approved", "rejected"],
    "initial_state": "draft",
    "transitions": {
      "draft": ["pending_manager"],
      "pending_manager": ["pending_it", "rejected"],
      "pending_it": ["pending_finance", "approved", "rejected"],
      "pending_finance": ["approved", "rejected"],
      "approved": [],
      "rejected": []
    }
  },
  "business_rules": {
    "max_request_amount": 50000,
    "requires_budget_approval": true,
    "requires_it_approval": true,
    "advance_notice_days": 7
  },
  "default_settings": {
    "approval_timeout_hours": 72,
    "escalation_timeout_hours": 120,
    "auto_reminder_hours": 48
  }
}

// Response
{
  "success": true,
  "data": {
    "id": 4,
    "workflow_name": "equipment_request_standard",
    "message": "Workflow definition created successfully",
    "message_ru": "Определение рабочего процесса успешно создано",
    "next_steps": [
      "Настройте состояния рабочего процесса",
      "Определите правила маршрутизации одобрений",
      "Настройте уведомления"
    ]
  }
}
```

### 6.2 Workflow Process Instance Management

#### GET /api/v1/workflows/instances
**Получить экземпляры рабочих процессов**

```json
// Request Parameters
{
  "workflow_id": 1,
  "workflow_type": "vacation",
  "status": "active|completed|cancelled|escalated|suspended",
  "requester_id": "uuid",
  "current_assignee_id": "uuid",
  "priority": "low|medium|high|urgent",
  "business_impact": "low|medium|high|critical",
  "start_date": "2025-07-01",
  "end_date": "2025-07-15",
  "overdue_only": false,
  "include_process_data": true,
  "page": 1,
  "per_page": 25
}

// Response
{
  "success": true,
  "data": {
    "workflow_instances": [
      {
        "id": 1,
        "workflow_id": 1,
        "workflow_name": "vacation_standard",
        "workflow_type": "vacation",
        "instance_key": "VAC-2025-001",
        "request_details": {
          "request_type": "annual_vacation",
          "requester_id": "uuid",
          "requester_name": "Алексей Иванов",
          "requester_email": "aleksey.ivanov@company.ru",
          "department_id": "dept_uuid",
          "department_name": "Отдел разработки"
        },
        "current_state": {
          "state_id": 2,
          "state_key": "pending_supervisor",
          "state_name_ru": "Ожидает руководителя",
          "current_assignee_id": "supervisor_uuid",
          "current_assignee_name": "Сергей Петрович",
          "current_assignee_role": "Руководитель отдела"
        },
        "process_data": {
          "vacation_start_date": "2025-08-01",
          "vacation_end_date": "2025-08-14",
          "vacation_days": 14,
          "vacation_type": "annual",
          "coverage_arrangements": {
            "coverage_person": "Мария Сидорова",
            "coverage_confirmed": true,
            "handover_completed": false
          },
          "additional_notes": "Планируется семейный отпуск на море"
        },
        "timing_information": {
          "started_at": "2025-07-15T09:00:00Z",
          "completed_at": null,
          "due_date": "2025-07-17T17:00:00Z",
          "escalated_at": null,
          "time_in_current_state_hours": 8,
          "total_processing_time_hours": 8,
          "is_overdue": false,
          "sla_status": "on_track"
        },
        "status_tracking": {
          "status": "active",
          "priority": "medium",
          "business_impact": "low",
          "urgency": "medium",
          "escalation_count": 0
        },
        "performance_metrics": {
          "approval_time_hours": null,
          "processing_efficiency": "on_schedule",
          "step_completion_rate": 25
        },
        "metadata": {
          "created_via": "web_interface",
          "last_activity": "Создана заявка на отпуск",
          "next_action": "Ожидает рассмотрения руководителем",
          "estimated_completion": "2025-07-17T17:00:00Z"
        }
      }
    ],
    "total": 150,
    "page": 1,
    "per_page": 25,
    "total_pages": 6
  },
  "meta": {
    "status_summary": {
      "active": 120,
      "completed": 800,
      "cancelled": 15,
      "escalated": 10,
      "suspended": 5
    },
    "workload_summary": {
      "pending_supervisor_approval": 45,
      "pending_hr_approval": 25,
      "pending_finance_approval": 10,
      "overdue_instances": 8
    },
    "performance_summary": {
      "avg_processing_time_hours": 24,
      "avg_approval_time_hours": 18,
      "sla_compliance_rate": 92,
      "escalation_rate": 6
    }
  }
}
```

#### POST /api/v1/workflows/instances/{instance_id}/actions
**Выполнить действие в рабочем процессе**

```json
// Request
{
  "action_type": "approve|reject|return|escalate|delegate|add_comment|request_information",
  "decision": "approved",
  "decision_reason": "Vacation request meets all requirements",
  "decision_reason_ru": "Заявка на отпуск соответствует всем требованиям",
  "comments": "Approved with coverage arrangements confirmed",
  "comments_ru": "Одобрено с подтвержденными договоренностями о замещении",
  "next_assignee_id": "hr_specialist_uuid",
  "conditions": {
    "requires_confirmation": false,
    "effective_date": "2025-07-16T00:00:00Z"
  },
  "notification_preferences": {
    "notify_requester": true,
    "notify_next_assignee": true,
    "notification_method": "email_and_system"
  }
}

// Response
{
  "success": true,
  "data": {
    "instance_id": 1,
    "action_id": "action_uuid",
    "previous_state": "pending_supervisor",
    "new_state": "pending_hr",
    "action_performed": "approved",
    "next_assignee": {
      "id": "hr_specialist_uuid",
      "name": "Елена Петрова",
      "role": "Специалист HR"
    },
    "process_advancement": {
      "completion_percentage": 50,
      "estimated_remaining_time_hours": 24,
      "next_milestone": "HR approval",
      "next_milestone_ru": "Одобрение HR"
    },
    "notifications_sent": [
      {
        "recipient": "Алексей Иванов",
        "type": "approval_progress",
        "method": "email",
        "status": "sent"
      },
      {
        "recipient": "Елена Петрова",
        "type": "action_required",
        "method": "email",
        "status": "sent"
      }
    ],
    "audit_entry": {
      "audit_id": "audit_uuid",
      "action_timestamp": "2025-07-15T16:30:00Z",
      "actor_name": "Сергей Петрович"
    },
    "message": "Workflow action completed successfully",
    "message_ru": "Действие в рабочем процессе успешно выполнено"
  }
}
```

### 6.3 Workflow Analytics and Performance

#### GET /api/v1/workflows/analytics/performance
**Получить аналитику производительности рабочих процессов**

```json
// Request Parameters
{
  "workflow_id": 1,
  "workflow_type": "vacation",
  "date_range": {
    "start_date": "2025-07-01",
    "end_date": "2025-07-15"
  },
  "aggregation_level": "daily|weekly|monthly",
  "department_id": "dept_uuid",
  "include_bottlenecks": true,
  "include_trends": true
}

// Response
{
  "success": true,
  "data": {
    "workflow_performance": {
      "workflow_id": 1,
      "workflow_name": "vacation_standard",
      "workflow_type": "vacation",
      "analysis_period": {
        "start_date": "2025-07-01",
        "end_date": "2025-07-15",
        "total_days": 15
      },
      "volume_metrics": {
        "instances_started": 45,
        "instances_completed": 38,
        "instances_cancelled": 3,
        "instances_escalated": 4,
        "completion_rate": 84.4,
        "cancellation_rate": 6.7,
        "escalation_rate": 8.9
      },
      "timing_metrics": {
        "avg_processing_time_hours": 22.5,
        "median_processing_time_hours": 18.0,
        "min_processing_time_hours": 4.5,
        "max_processing_time_hours": 72.0,
        "p95_processing_time_hours": 48.0,
        "avg_approval_time_hours": 16.2,
        "median_approval_time_hours": 12.0
      },
      "approval_metrics": {
        "approval_rate": 89.5,
        "rejection_rate": 10.5,
        "first_pass_approval_rate": 76.3,
        "avg_approval_steps": 2.1,
        "avg_escalations_per_instance": 0.09
      },
      "efficiency_metrics": {
        "avg_queue_size": 8,
        "max_queue_size": 15,
        "avg_assignee_workload": 3.2,
        "sla_compliance_rate": 92.1,
        "return_rate": 13.2
      },
      "quality_metrics": {
        "data_quality_score": 91.5,
        "avg_comments_per_instance": 1.8,
        "customer_satisfaction_score": 4.2
      }
    },
    "bottleneck_analysis": [
      {
        "bottleneck_state": "pending_supervisor",
        "bottleneck_state_ru": "Ожидает руководителя",
        "avg_wait_time_hours": 28.5,
        "instance_count": 25,
        "impact_score": 85.2,
        "primary_cause": "workload",
        "primary_cause_ru": "рабочая нагрузка",
        "recommendations": [
          "Рассмотреть делегирование полномочий одобрения",
          "Установить автоматические напоминания через 24 часа",
          "Добавить заместителя для обработки заявок"
        ]
      }
    ],
    "trend_analysis": {
      "processing_time_trend": "decreasing",
      "volume_trend": "increasing",
      "quality_trend": "stable",
      "efficiency_improvements": [
        "Сокращение времени обработки на 15% за последний месяц",
        "Увеличение показателя первичного одобрения на 8%"
      ]
    },
    "recommendations": {
      "priority_actions": [
        {
          "priority": "high",
          "action": "Автоматизировать простые запросы отпуска",
          "expected_impact": "Сокращение времени обработки на 30%"
        },
        {
          "priority": "medium",
          "action": "Улучшить шаблоны уведомлений",
          "expected_impact": "Повышение качества коммуникации"
        }
      ]
    }
  }
}
```

---

## Security Considerations

### Authentication and Authorization
- All APIs require valid JWT tokens with appropriate scopes
- Role-based access control enforced at endpoint and data level
- Multi-factor authentication required for administrative functions
- Session management with configurable timeouts and concurrent session limits

### Data Protection
- Field-level encryption for sensitive configuration values
- Row-level security for multi-tenant data isolation
- Audit logging for all data access and modifications
- GDPR-compliant data handling with retention policies

### API Security
- Rate limiting on all endpoints
- Input validation and sanitization
- SQL injection prevention
- XSS protection for user-generated content

### Monitoring and Alerting
- Real-time security event monitoring
- Automated threat detection
- Performance monitoring with SLA tracking
- Health check endpoints for all critical services

---

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "message_ru": "Недопустимые входные параметры",
    "details": {
      "field": "config_value",
      "constraint": "Value must be between 1 and 1000",
      "constraint_ru": "Значение должно быть от 1 до 1000"
    },
    "request_id": "req_uuid",
    "timestamp": "2025-07-15T16:00:00Z"
  }
}
```

### Common Error Codes
- `AUTHENTICATION_REQUIRED` - Valid authentication token required
- `AUTHORIZATION_DENIED` - Insufficient permissions for requested operation
- `VALIDATION_ERROR` - Input validation failed
- `RESOURCE_NOT_FOUND` - Requested resource does not exist
- `CONFLICT_ERROR` - Resource conflict (e.g., duplicate configuration)
- `RATE_LIMIT_EXCEEDED` - Too many requests within time window
- `SYSTEM_UNAVAILABLE` - Backend system temporarily unavailable

---

This comprehensive API documentation provides enterprise-ready interfaces for system administration, audit logging, user management, SSO authentication, and workflow management with full Russian language support and advanced security features.