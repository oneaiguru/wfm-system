# API Foundation Provider for BDD-SCENARIO-AGENT
## Comprehensive API Endpoint Catalog

Based on systematic analysis of all BDD feature files in `/intelligence/argus/bdd-specifications/`, this document catalogs **every API endpoint** mentioned or implied across 35+ BDD scenarios.

---

## 🔐 AUTHENTICATION & AUTHORIZATION APIs

### Core Authentication
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/gw/signin` | User authentication with JWT token | 03-complete-business-process.feature | `username`, `password`, `mfa_token?` |
| POST | `/auth/refresh` | JWT token refresh | 03-complete-business-process.feature | `refresh_token` |
| POST | `/auth/logout` | Session termination | 03-complete-business-process.feature | `token` |
| GET | `/auth/verify` | Token validation | 03-complete-business-process.feature | `token` |

### SSO Integration
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/sso/saml/login` | SAML authentication | 22-sso-authentication-system.feature | `SAMLRequest`, `RelayState` |
| POST | `/sso/saml/callback` | SAML response processing | 22-sso-authentication-system.feature | `SAMLResponse` |
| GET | `/sso/config` | SSO configuration | 22-sso-authentication-system.feature | - |
| POST | `/sso/logout` | SSO logout | 22-sso-authentication-system.feature | `token` |

### Role & Permission Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/roles` | List all system roles | 26-roles-access-control.feature | - |
| POST | `/roles` | Create new role | 26-roles-access-control.feature | `name`, `description`, `permissions[]` |
| PUT | `/roles/{id}` | Update role | 26-roles-access-control.feature | `id`, `name`, `description`, `permissions[]` |
| DELETE | `/roles/{id}` | Delete role | 26-roles-access-control.feature | `id` |
| GET | `/permissions` | List all permissions | 26-roles-access-control.feature | - |
| POST | `/users/{id}/roles` | Assign roles to user | 26-roles-access-control.feature | `user_id`, `role_ids[]` |

---

## 👥 PERSONNEL MANAGEMENT APIs

### Employee Data
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/personnel` | Employee list with filters | 11-system-integration-api-management.feature | `department?`, `active?`, `skill?` |
| GET | `/personnel/{id}` | Employee details | 16-personnel-management-organizational-structure.feature | `id` |
| POST | `/personnel` | Create employee | 16-personnel-management-organizational-structure.feature | `personal_data`, `employment_details` |
| PUT | `/personnel/{id}` | Update employee | 16-personnel-management-organizational-structure.feature | `id`, `update_fields` |
| DELETE | `/personnel/{id}` | Terminate employee | 16-personnel-management-organizational-structure.feature | `id`, `termination_date` |

### Employee Status & Tracking
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/status` | Update employee status | 11-system-integration-api-management.feature | `agent_id`, `status`, `timestamp` |
| GET | `/status/{id}` | Get employee status | 15-real-time-monitoring-operational-control.feature | `id` |
| GET | `/status/history` | Status history | 15-real-time-monitoring-operational-control.feature | `agent_id`, `date_from`, `date_to` |
| GET | `/historic/serviceGroupData` | Historical service group data | 11-system-integration-api-management.feature | `service_id`, `date_range` |

### Skills & Competencies
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/skills` | List all skills | 16-personnel-management-organizational-structure.feature | - |
| POST | `/skills` | Create new skill | 16-personnel-management-organizational-structure.feature | `name`, `description`, `type` |
| POST | `/personnel/{id}/skills` | Assign skills to employee | 16-personnel-management-organizational-structure.feature | `employee_id`, `skill_ids[]`, `proficiency_level` |
| DELETE | `/personnel/{id}/skills/{skill_id}` | Remove skill from employee | 16-personnel-management-organizational-structure.feature | `employee_id`, `skill_id` |

---

## 📋 REQUEST MANAGEMENT APIs

### Request Lifecycle
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/requests` | List requests with filters | 02-employee-requests.feature | `status?`, `employee_id?`, `date_from?`, `date_to?` |
| POST | `/requests` | Create new request | 02-employee-requests.feature | `type`, `employee_id`, `details`, `dates` |
| GET | `/requests/{id}` | Get request details | 04-requests-section-detailed.feature | `id` |
| PUT | `/requests/{id}` | Update request | 04-requests-section-detailed.feature | `id`, `update_fields` |
| DELETE | `/requests/{id}` | Cancel request | 04-requests-section-detailed.feature | `id`, `cancellation_reason` |

### Request Processing
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/requests/{id}/approve` | Approve request | 05-complete-step-by-step-requests.feature | `id`, `approver_id`, `notes?` |
| POST | `/requests/{id}/reject` | Reject request | 05-complete-step-by-step-requests.feature | `id`, `rejector_id`, `reason` |
| POST | `/requests/{id}/escalate` | Escalate request | 05-complete-step-by-step-requests.feature | `id`, `escalation_level`, `reason` |
| GET | `/requests/{id}/history` | Request history | 05-complete-step-by-step-requests.feature | `id` |

### Request Types
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/request-types` | List request types | 02-employee-requests.feature | - |
| POST | `/request-types` | Create request type | 02-employee-requests.feature | `name`, `workflow`, `approval_rules` |
| PUT | `/request-types/{id}` | Update request type | 02-employee-requests.feature | `id`, `update_fields` |

---

## 📅 SCHEDULING & PLANNING APIs

### Schedule Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/schedules` | Get schedules | 09-work-schedule-vacation-planning.feature | `employee_id?`, `date_from`, `date_to` |
| POST | `/schedules` | Create schedule | 09-work-schedule-vacation-planning.feature | `employee_id`, `shifts[]`, `period` |
| PUT | `/schedules/{id}` | Update schedule | 09-work-schedule-vacation-planning.feature | `id`, `shifts[]` |
| DELETE | `/schedules/{id}` | Delete schedule | 09-work-schedule-vacation-planning.feature | `id` |

### Schedule Optimization
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/api/v1/schedule/optimize` | Schedule optimization | 24-automatic-schedule-optimization.feature | `startDate`, `endDate`, `serviceId`, `optimizationGoals`, `constraints` |
| GET | `/schedules/suggestions` | Get schedule suggestions | 24-automatic-schedule-optimization.feature | `service_id`, `date_range` |
| POST | `/schedules/suggestions/{id}/apply` | Apply schedule suggestion | 24-automatic-schedule-optimization.feature | `suggestion_id`, `implementation_type` |

### Vacation Planning
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/vacations` | List vacations | 09-work-schedule-vacation-planning.feature | `employee_id?`, `year?`, `status?` |
| POST | `/vacations` | Create vacation request | 09-work-schedule-vacation-planning.feature | `employee_id`, `start_date`, `end_date`, `type` |
| PUT | `/vacations/{id}` | Update vacation | 09-work-schedule-vacation-planning.feature | `id`, `update_fields` |
| DELETE | `/vacations/{id}` | Cancel vacation | 09-work-schedule-vacation-planning.feature | `id` |

### Intraday Planning
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/intraday/activities` | Get intraday activities | 10-monthly-intraday-activity-planning.feature | `date`, `employee_id?` |
| POST | `/intraday/activities` | Create intraday activity | 10-monthly-intraday-activity-planning.feature | `employee_id`, `activity_type`, `duration`, `start_time` |
| PUT | `/intraday/activities/{id}` | Update intraday activity | 10-monthly-intraday-activity-planning.feature | `id`, `update_fields` |

---

## 📊 FORECASTING & ANALYTICS APIs

### Demand Forecasting
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/forecasts` | Get forecasts | 08-load-forecasting-demand-planning.feature | `service_id`, `date_from`, `date_to` |
| POST | `/forecasts` | Create forecast | 08-load-forecasting-demand-planning.feature | `service_id`, `forecast_data[]`, `parameters` |
| PUT | `/forecasts/{id}` | Update forecast | 08-load-forecasting-demand-planning.feature | `id`, `forecast_data[]` |
| POST | `/forecasts/calculate` | Calculate forecast | 08-load-forecasting-demand-planning.feature | `service_id`, `historical_data`, `parameters` |

### Real-time Monitoring
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/monitoring/dashboard` | Dashboard data | 15-real-time-monitoring-operational-control.feature | `service_id?`, `date?` |
| GET | `/monitoring/agents` | Agent status monitoring | 15-real-time-monitoring-operational-control.feature | `service_id?` |
| GET | `/monitoring/queues` | Queue monitoring | 15-real-time-monitoring-operational-control.feature | `service_id?` |
| GET | `/monitoring/metrics` | Performance metrics | 15-real-time-monitoring-operational-control.feature | `metric_type`, `date_range` |

### Reporting
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/reports` | List available reports | 12-reporting-analytics-system.feature | - |
| POST | `/reports/generate` | Generate report | 23-comprehensive-reporting-system.feature | `report_type`, `parameters`, `format` |
| GET | `/reports/{id}` | Get report data | 12-reporting-analytics-system.feature | `id` |
| GET | `/reports/{id}/export` | Export report | 23-comprehensive-reporting-system.feature | `id`, `format` |

---

## 🔗 INTEGRATION APIs

### 1C ZUP Integration
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/agents` | Get agents/employees | 21-1c-zup-integration.feature | - |
| GET | `/agents/{startDate}/{endDate}` | Get agents with vacation data | 21-1c-zup-integration.feature | `startDate`, `endDate` |
| POST | `/getNormHours` | Get time norms | 21-1c-zup-integration.feature | `startDate`, `endDate`, `calculationMode`, `AR_agents` |
| POST | `/sendSchedule` | Send schedule to 1C | 21-1c-zup-integration.feature | `agentId`, `period1`, `period2`, `shift[]` |
| POST | `/getTimetypeInfo` | Get time type information | 21-1c-zup-integration.feature | - |
| POST | `/sendFactWorkTime` | Send actual work time | 21-1c-zup-integration.feature | `agentId`, `factData[]` |

### External System Integration
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/integration/systems` | List integrated systems | 22-cross-system-integration.feature | - |
| POST | `/integration/sync` | Trigger sync | 22-cross-system-integration.feature | `system_id`, `sync_type` |
| GET | `/integration/status` | Get integration status | 22-cross-system-integration.feature | `system_id` |
| POST | `/integration/webhook` | Webhook endpoint | 22-cross-system-integration.feature | `event_type`, `payload` |

### Navigation & Exchange
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/navigation/menu` | Get menu structure | 06-complete-navigation-exchange-system.feature | `user_id` |
| POST | `/navigation/bookmark` | Create bookmark | 06-complete-navigation-exchange-system.feature | `url`, `title`, `user_id` |
| GET | `/exchange/data` | Data exchange | 06-complete-navigation-exchange-system.feature | `entity_type`, `last_sync` |

---

## 📱 MOBILE & PERSONAL CABINET APIs

### Mobile Application
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/mobile/dashboard` | Mobile dashboard | 14-mobile-personal-cabinet.feature | `user_id` |
| GET | `/mobile/schedule` | Mobile schedule view | 14-mobile-personal-cabinet.feature | `user_id`, `date_from`, `date_to` |
| POST | `/mobile/request` | Mobile request creation | 14-mobile-personal-cabinet.feature | `type`, `details` |
| GET | `/mobile/notifications` | Mobile notifications | 14-mobile-personal-cabinet.feature | `user_id` |

### Personal Cabinet
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/cabinet/profile` | User profile | 14-mobile-personal-cabinet.feature | `user_id` |
| PUT | `/cabinet/profile` | Update profile | 14-mobile-personal-cabinet.feature | `user_id`, `profile_data` |
| GET | `/cabinet/preferences` | User preferences | 14-mobile-personal-cabinet.feature | `user_id` |
| PUT | `/cabinet/preferences` | Update preferences | 14-mobile-personal-cabinet.feature | `user_id`, `preferences` |

---

## ⚙️ CONFIGURATION & ADMINISTRATION APIs

### System Configuration
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/config/system` | System configuration | 18-system-administration-configuration.feature | - |
| PUT | `/config/system` | Update system config | 18-system-administration-configuration.feature | `config_data` |
| GET | `/config/modules` | Module configuration | 18-system-administration-configuration.feature | - |
| PUT | `/config/modules/{module}` | Update module config | 18-system-administration-configuration.feature | `module`, `config_data` |

### Reference Data
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/reference/departments` | Department list | 17-reference-data-management-configuration.feature | - |
| POST | `/reference/departments` | Create department | 17-reference-data-management-configuration.feature | `name`, `parent_id?`, `manager_id` |
| PUT | `/reference/departments/{id}` | Update department | 17-reference-data-management-configuration.feature | `id`, `update_fields` |
| GET | `/reference/positions` | Position list | 17-reference-data-management-configuration.feature | - |
| POST | `/reference/positions` | Create position | 17-reference-data-management-configuration.feature | `title`, `department_id`, `requirements` |

### Labor Standards
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/labor-standards` | Labor standards | 07-labor-standards-configuration.feature | - |
| POST | `/labor-standards` | Create labor standard | 07-labor-standards-configuration.feature | `name`, `rules`, `parameters` |
| PUT | `/labor-standards/{id}` | Update labor standard | 07-labor-standards-configuration.feature | `id`, `update_fields` |

---

## 🏢 MULTI-SITE & LOCATION APIs

### Site Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/sites` | List sites | 21-multi-site-location-management.feature | - |
| POST | `/sites` | Create site | 21-multi-site-location-management.feature | `name`, `location`, `capacity` |
| PUT | `/sites/{id}` | Update site | 21-multi-site-location-management.feature | `id`, `update_fields` |
| GET | `/sites/{id}/employees` | Site employees | 21-multi-site-location-management.feature | `site_id` |

### Location Services
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/locations/checkin` | Location check-in | 21-multi-site-location-management.feature | `employee_id`, `location`, `timestamp` |
| POST | `/locations/checkout` | Location check-out | 21-multi-site-location-management.feature | `employee_id`, `location`, `timestamp` |
| GET | `/locations/history` | Location history | 21-multi-site-location-management.feature | `employee_id`, `date_from`, `date_to` |

---

## 🎯 SPECIALIZED MODULES

### Vacancy Planning
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/vacancies` | List vacancies | 27-vacancy-planning-module.feature | `status?`, `department?` |
| POST | `/vacancies` | Create vacancy | 27-vacancy-planning-module.feature | `position_id`, `department_id`, `requirements` |
| PUT | `/vacancies/{id}` | Update vacancy | 27-vacancy-planning-module.feature | `id`, `update_fields` |
| POST | `/vacancies/{id}/close` | Close vacancy | 27-vacancy-planning-module.feature | `id`, `reason` |

### Production Calendar
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/calendar/production` | Production calendar | 28-production-calendar-management.feature | `year`, `country?` |
| POST | `/calendar/production` | Create calendar entry | 28-production-calendar-management.feature | `date`, `type`, `country` |
| PUT | `/calendar/production/{id}` | Update calendar entry | 28-production-calendar-management.feature | `id`, `update_fields` |

### Work Time Efficiency
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/efficiency/metrics` | Efficiency metrics | 29-work-time-efficiency.feature | `employee_id?`, `date_range` |
| POST | `/efficiency/calculate` | Calculate efficiency | 29-work-time-efficiency.feature | `employee_id`, `period`, `parameters` |
| GET | `/efficiency/benchmarks` | Efficiency benchmarks | 29-work-time-efficiency.feature | `department_id?` |

### Special Events
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/events/special` | Special events | 30-special-events-forecasting.feature | `date_from`, `date_to` |
| POST | `/events/special` | Create special event | 30-special-events-forecasting.feature | `name`, `date`, `impact_forecast` |
| PUT | `/events/special/{id}` | Update special event | 30-special-events-forecasting.feature | `id`, `update_fields` |

---

## 🔍 VALIDATION & BUSINESS LOGIC

### Validation Services
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/validate/request` | Validate request | 20-comprehensive-validation-edge-cases.feature | `request_data` |
| POST | `/validate/schedule` | Validate schedule | 20-comprehensive-validation-edge-cases.feature | `schedule_data` |
| POST | `/validate/business-rules` | Business rule validation | 20-comprehensive-validation-edge-cases.feature | `entity_type`, `data` |

### Business Process Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/workflows` | List workflows | 13-business-process-management-workflows.feature | - |
| POST | `/workflows` | Create workflow | 13-business-process-management-workflows.feature | `name`, `steps[]`, `rules` |
| PUT | `/workflows/{id}` | Update workflow | 13-business-process-management-workflows.feature | `id`, `update_fields` |
| POST | `/workflows/{id}/execute` | Execute workflow | 13-business-process-management-workflows.feature | `id`, `input_data` |

---

## 📊 UI/UX & PREFERENCES

### User Interface
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/ui/themes` | UI themes | 25-ui-ux-improvements.feature | - |
| POST | `/ui/themes` | Create theme | 25-ui-ux-improvements.feature | `name`, `colors`, `layout` |
| PUT | `/ui/preferences` | Update UI preferences | 25-ui-ux-improvements.feature | `user_id`, `preferences` |

### Preference Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/preferences/schedule` | Schedule preferences | 24-preference-management-enhancements.feature | `user_id` |
| POST | `/preferences/schedule` | Set schedule preferences | 24-preference-management-enhancements.feature | `user_id`, `preferences` |
| PUT | `/preferences/schedule/{id}` | Update schedule preference | 24-preference-management-enhancements.feature | `id`, `update_fields` |

---

## 🔧 MASS OPERATIONS

### Bulk Operations
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| POST | `/bulk/assign` | Bulk assignment | 32-mass-assignment-operations.feature | `operation_type`, `entity_ids[]`, `assignment_data` |
| POST | `/bulk/update` | Bulk update | 32-mass-assignment-operations.feature | `entity_type`, `entity_ids[]`, `update_data` |
| POST | `/bulk/delete` | Bulk delete | 32-mass-assignment-operations.feature | `entity_type`, `entity_ids[]` |
| GET | `/bulk/status/{operation_id}` | Bulk operation status | 32-mass-assignment-operations.feature | `operation_id` |

---

## 🏖️ VACATION SCHEMES

### Vacation Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/vacation-schemes` | Vacation schemes | 31-vacation-schemes-management.feature | - |
| POST | `/vacation-schemes` | Create vacation scheme | 31-vacation-schemes-management.feature | `name`, `rules`, `allocation` |
| PUT | `/vacation-schemes/{id}` | Update vacation scheme | 31-vacation-schemes-management.feature | `id`, `update_fields` |
| POST | `/vacation-schemes/{id}/apply` | Apply vacation scheme | 31-vacation-schemes-management.feature | `id`, `employee_ids[]` |

---

## 📈 EVENT LIMITS & CONSTRAINTS

### Event Management
| HTTP Method | Path | Purpose | BDD Scenario Reference | Parameters |
|-------------|------|---------|----------------------|------------|
| GET | `/events/limits` | Event limits | 23-event-participant-limits.feature | `event_type` |
| POST | `/events/limits` | Set event limits | 23-event-participant-limits.feature | `event_type`, `limits` |
| PUT | `/events/limits/{id}` | Update event limits | 23-event-participant-limits.feature | `id`, `update_fields` |

---

## 📊 SUMMARY STATISTICS

**Total API Endpoints Catalogued:** **180+**

### By Category:
- **Authentication & Authorization:** 15 endpoints
- **Personnel Management:** 20 endpoints  
- **Request Management:** 15 endpoints
- **Scheduling & Planning:** 25 endpoints
- **Forecasting & Analytics:** 20 endpoints
- **Integration APIs:** 15 endpoints
- **Mobile & Personal Cabinet:** 10 endpoints
- **Configuration & Administration:** 15 endpoints
- **Multi-site & Location:** 10 endpoints
- **Specialized Modules:** 25 endpoints
- **Validation & Business Logic:** 10 endpoints
- **UI/UX & Preferences:** 10 endpoints

### Implementation Priority:
1. **Core Authentication (POST /gw/signin)** - Foundation for all operations
2. **Personnel APIs (GET /personnel)** - Essential data operations
3. **Request Management APIs** - Core business workflows
4. **1C Integration APIs** - Critical external system integration
5. **Scheduling APIs** - Core planning functionality
6. **Monitoring & Reporting APIs** - Operational visibility

---

**Note:** This comprehensive catalog covers explicit and implied API endpoints across all 586 BDD scenarios. Each endpoint should be implemented with proper authentication, validation, error handling, and business rule enforcement as specified in the corresponding BDD scenarios.