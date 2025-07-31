# Argus WFM System Exploration Summary

## Overview
Successfully explored the Argus WFM system using human-like browser automation. The system is currently running at https://cc1010wfmcc.argustelecom.ru/ccwfm/

## Key Findings

### 1. System Architecture
- **Technology Stack**: Vue.js-based SPA with PrimeFaces components
- **Language**: Russian interface with English language option
- **Authentication**: Username/password login (tested with admin credentials)

### 2. Main Modules Explored

#### Dashboard
- Shows summary statistics:
  - 9 Services (Службы)
  - 19 Groups (Группы) 
  - 513 Employees (Сотрудники)
- Quick access cards for main functional areas
- Notifications panel showing recent reports

#### Forecasting (Прогнозирование)
- **URL**: /ccwfm/views/env/forecast/ForecastListView.xhtml
- Features:
  - View Load (Просмотр нагрузки)
  - Create Forecasts (Спрогнозировать нагрузку)
  - Import Forecasts (Импорт прогнозов)
  - Forecast Accuracy Analysis (Анализ точности прогноза)
  - Mass Assignment of Forecasts (Массовое назначение прогнозов)
  - Special Dates Analysis (Анализ специальных дат)

#### Planning (Планирование)
- **URL**: /ccwfm/views/env/planning/ActualSchedulePlanView.xhtml
- Features:
  - Current Schedule (Актуальное расписание)
  - Schedule Adjustments (Корректировка графиков работ)
  - Multi-skill Planning (Мультискильное планирование)
  - Schedule Creation (Создание расписаний)
  - Planning Criteria (Критерии планирования)
  - Work Schedule Planning (Планирование графиков работ)
  - Vacation Planning (Планирование вакансий)

#### Monitoring (Мониторинг)
- **URL**: /ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml
- Features:
  - Group Management (Управление группами)
  - Operational Control (Оперативный контроль)
  - Operator Statuses (Статусы операторов)
  - Update and Notification Settings (Настройка обновлений и оповещений)
  - Threshold Settings (Настройка пороговых значений)
  - Exchange (Биржа)

#### Reports (Отчёты)
- **URL**: /ccwfm/views/env/tmp/ReportTypeMapView.xhtml
- Extensive reporting capabilities including:
  - Report Editor (Редактор отчётов)
  - Report Building Tasks (Задачи на построение отчётов)
  - Schedule Compliance (Соблюдение расписания)
  - Payroll Calculation (Расчёт заработной платы)
  - Forecast vs Plan Report (Отчёт по прогнозу и плану)
  - Various operational reports (AHT, Ready%, Absenteeism, etc.)

#### Personnel (Персонал)
- **URL**: /ccwfm/views/env/personnel/WorkerListView.xhtml
- Features:
  - Employee Management (513 employees currently)
  - Groups Management
  - Services Management
  - Group Structure
  - Departments
  - Personnel Synchronization
  - Operator Data Collection/Transfer

#### Business Rules (Бизнес-правила)
- **URL**: /ccwfm/views/env/personnel/NormHoursView.xhtml
- Features:
  - Production (Выработка)
  - Work Rules Configuration
  - Role Management
  - Performance Standards

### 3. Navigation Structure
The system uses a comprehensive left-side navigation menu with expandable sections for each major module. The menu remains consistent across all pages.

### 4. Data Captured
- Screenshots of all major modules
- Full HTML page saved in `argus-exploration-data/_1753461928976.html`
- Page content extracted showing forms, filters, and data structures

## Next Steps
1. Explore employee portal at https://lkcc1010wfmcc.argustelecom.ru/
2. Analyze specific workflows within each module
3. Document API endpoints and data structures
4. Create BDD scenarios based on observed functionality