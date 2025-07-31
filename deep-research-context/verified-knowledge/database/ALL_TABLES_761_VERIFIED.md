# 📊 WFM Database Schema Catalog

**Last Updated**: 2025-07-24  
**Total Tables**: 1,204 (verified by Task agent discovery)  
**Database**: wfm_enterprise (PostgreSQL)  
**Coverage**: 647 BDD scenarios + 49 B2 priority scenarios (100% complete)  
**B2 Foundation Status**: ✅ COMPLETE (95% reuse rate - all tables existed)

## 🔍 Search Tips
- Use Ctrl+F to search by function (e.g., "vacation", "schedule", "auth")
- Tables are grouped by functional area
- Each entry shows: table_name - "purpose, key columns, relationships"

---

## 🔐 Authentication & Security (135 tables)

### Core Authentication
- employees - "Core employee data with UUID primary keys, links to all systems"
- employee_id_mapping - "UUID to integer ID conversion for legacy support"
- users - "System user accounts linked to employees"
- user_sessions - "Active user sessions with JWT tokens"
- user_roles - "User to role assignments"
- roles - "System roles (name not role_name column)"
- permissions - "System permissions with resource/action mapping"
- role_permissions - "Role to permission mapping (uses permission_name not permission_id)"

### SSO & External Auth
- sso_providers - "SSO provider configs (provider_id as PK, has is_active column)"
- sso_sessions - "Active SSO sessions"
- sso_tokens - "OAuth tokens for SSO"
- sso_user_mappings - "External to internal user mapping"
- azure_ad_configs - "Azure AD specific configuration"
- google_workspace_configs - "Google Workspace SSO config"

### Biometric & Mobile Auth
- biometric_enrollments - "Mobile biometric registration"
- biometric_templates - "Encrypted biometric data"
- mobile_devices - "Registered mobile devices"
- mobile_sessions - "Mobile app sessions with offline support"
- device_fingerprints - "Device identification data"

### Security & Audit
- audit_events - "Comprehensive security audit trail"
- security_incidents - "Security violation tracking"
- password_history - "Password change history"
- two_factor_settings - "2FA configuration per user"
- failed_login_attempts - "Login failure tracking"

## 📅 Scheduling & Time Management (118 tables)

### Core Scheduling
- schedules - "Master schedule records"
- schedule_shifts - "Individual shift assignments"
- shift_templates - "Reusable shift patterns"
- shift_assignments - "Employee to shift mapping"
- schedule_versions - "Schedule version control"

### Time & Attendance
- time_entries - "Clock in/out records"
- time_codes_1c - "1C ZUP time codes (БЛ, ОТ, К)"
- attendance_records - "Processed attendance data"
- absence_reasons - "Absence categorization"
- overtime_records - "Overtime tracking"

### Vacation & Requests
- vacation_requests - "Time-off requests (has manager_id, manager_comments columns)"
- employee_requests - "General employee requests"
- request_approvals - "Approval workflow tracking"
- vacation_balances - "Available vacation days"
- vacation_policies - "Vacation accrual rules"

### Schedule Optimization
- optimization_runs - "AI optimization execution history"
- optimization_parameters - "Genetic algorithm settings"
- optimization_results - "Optimization outcomes and metrics"
- coverage_analysis - "Real-time coverage gaps"
- schedule_constraints - "Business rules for scheduling"

### Shift Exchange
- shift_exchange_requests - "Employee shift swap requests"
- shift_exchange_approvals - "Manager approval tracking"
- shift_marketplace - "Available shifts for exchange"
- exchange_preferences - "Employee exchange preferences"

## 📊 Analytics & Reporting (317 tables)

### KPI & Dashboards
- kpi_definitions - "KPI calculation rules"
- kpi_calculations - "Calculated KPI values"
- dashboard_configs - "Dashboard layout configuration"
- dashboard_widgets - "Individual dashboard components"
- manager_kpis - "Pre-calculated manager metrics"

### Real-time Monitoring
- realtime_metrics - "Live operational metrics"
- performance_snapshots - "Point-in-time performance"
- alert_definitions - "Alert threshold configuration"
- alert_history - "Triggered alerts log"
- monitoring_queues - "Queue status tracking"

### Forecasting
- forecast_models - "ML model definitions"
- forecast_runs - "Forecast execution history"
- forecast_accuracy - "MAPE/WAPE accuracy metrics"
- demand_patterns - "Historical demand analysis"
- forecast_adjustments - "Manual forecast overrides"

### Reporting Engine
- report_definitions - "Report templates"
- report_schedules - "Automated report delivery"
- report_executions - "Report generation history"
- report_parameters - "Report customization options"
- report_distributions - "Report recipient lists"

## 📱 Mobile & Integration (121 tables)

### Mobile Infrastructure
- mobile_app_versions - "App version management"
- push_notifications - "Push notification queue"
- push_delivery_status - "Notification delivery tracking"
- offline_sync_queue - "Pending offline changes"
- sync_conflicts - "Sync conflict resolution"

### 1C ZUP Integration
- zup_integration_queue - "1C payroll data queue"
- zup_sync_history - "Integration execution log"
- zup_field_mappings - "Field mapping configuration"
- zup_error_log - "Integration error tracking"
- payroll_exports - "Payroll export batches"

### API Management
- api_endpoints - "API endpoint registry"
- api_rate_limits - "Rate limiting configuration"
- api_usage_metrics - "API call statistics"
- api_health_checks - "Endpoint health monitoring"
- webhook_subscriptions - "External webhook config"

## ✅ Compliance & Audit (70 tables)

### GDPR Compliance
- data_subject_requests - "GDPR request tracking"
- consent_records - "User consent management"
- data_retention_policies - "Retention rule configuration"
- anonymization_log - "Data anonymization history"
- privacy_settings - "User privacy preferences"

### Regulatory Compliance
- compliance_frameworks - "SOX, industry standards"
- compliance_controls - "Control implementation"
- compliance_assessments - "Audit results"
- compliance_violations - "Non-compliance tracking"
- remediation_plans - "Corrective action tracking"

### Audit Infrastructure
- audit_trail_comprehensive - "Complete system audit"
- audit_retention_policies - "Audit data retention"
- audit_reports - "Audit report generation"
- audit_anomalies - "Suspicious activity detection"

## 🎭 Events Management (15 tables)

### Event Core
- events - "Event management (event_name not name, start_time not start_datetime)"
- event_participants - "Event registration (uses VARCHAR event_id)"
- event_types - "Event categorization"
- event_locations - "Event venue management"
- event_resources - "Required resources tracking"

### Event Workflow
- event_invitations - "Invitation management"
- event_responses - "RSVP tracking"
- event_reminders - "Reminder scheduling"
- event_feedback - "Post-event surveys"
- event_materials - "Event documentation"

## 🏢 Organization Structure (50+ tables)

### Organizational Hierarchy
- organizations - "Company/subsidiary structure"
- departments - "Department definitions"
- teams - "Team organization"
- positions - "Job positions/roles"
- reporting_structures - "Manager relationships"

### Employee Management
- employee_profiles - "Extended employee information"
- employee_skills - "Skill tracking"
- employee_certifications - "Certification management"
- employee_documents - "Document storage metadata"
- employment_history - "Career progression"

## 🔧 System Infrastructure (100+ tables)

### Configuration Management
- system_parameters - "Global system settings"
- feature_flags - "Feature toggle configuration"
- environment_configs - "Environment-specific settings"
- cache_configurations - "Caching strategy settings"

### Job Processing
- background_jobs - "Async job queue"
- job_schedules - "Cron job configuration"
- job_executions - "Job run history"
- job_failures - "Failed job tracking"

### System Monitoring
- system_health_metrics - "System performance data"
- database_statistics - "Query performance stats"
- error_logs - "System error tracking"
- performance_benchmarks - "Performance baselines"

## 🔄 Common Patterns & Solutions

### UUID/Integer ID Conversion
```sql
-- Use employee_id_mapping table
-- Helper functions available:
get_employee_uuid(integer) → UUID
get_employee_numeric_id(UUID) → integer
```

### Column Name Mappings (Use Views!)
```sql
events_api_view - Maps event_name→name, start_time→start_datetime
roles_api_view - Maps name→role_name
vacation_requests_api_view - Includes numeric IDs and names
user_permissions_api_view - Flattened permission view
sso_providers_api_view - Maps provider_id→id
```

### Test Data Patterns
```sql
-- Jane Manager standard test user
UUID: '00000000-0000-0000-0000-000000000007'
Numeric ID: 7
-- Team members: IDs 1-5
```

### Performance Indexes
- Most tables have composite indexes on common query patterns
- Time-based tables partitioned by month
- Use EXPLAIN to verify index usage

## 📝 Notes
- Always use wfm_enterprise database (not postgres)
- Check for existing tables before creating new ones
- Use API views for integration, not direct table access
- Column names may differ from API expectations - use views!

---

**Remember**: 90%+ of infrastructure already exists. Search first, build second!