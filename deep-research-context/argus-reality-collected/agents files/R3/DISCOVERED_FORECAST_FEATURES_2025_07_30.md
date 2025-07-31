# Discovered Forecast Features - R3 Exploration
**Date**: 2025-07-30
**Agent**: R3-ForecastAnalytics
**Method**: Systematic MCP browser exploration

## 🎯 Executive Summary

Discovered several undocumented features in Argus Forecast module:
1. **Forecast Accuracy Analysis** - Working page with comparison capabilities
2. **Mass Forecast Assignment** - Bulk operations for forecast distribution
3. **Hidden UI Elements** - Multiple hidden buttons and forms for advanced operations
4. **Report Catalog** - 13 specific report types with direct URLs

## 📊 Discovered Features

### 1. Forecast Accuracy Analysis ✅
- **Location**: `/ccwfm/views/env/forecast/ForecastAccuracyView.xhtml`
- **Description**: Analyzes forecast accuracy with dual-mode comparison
- **BDD Coverage**: Not covered
- **APIs Found**: Not captured (need DevTools)
- **UI Elements**: 
  - "Анализ точности прогноза": "Forecast Accuracy Analysis"
  - Two modes: "По группе/службе" and "По сегменту"
  - Schema selection for comparison types
- **Implementation Status**: Not built
- **Hidden Features**:
  - Dual comparison modes (by group vs by segment)
  - Multiple schema types for accuracy calculation
  - Timezone-aware comparisons

### 2. Mass Forecast Assignment ✅
- **Location**: `/ccwfm/views/env/assignforecast/MassiveAssignForecastsView.xhtml`
- **Description**: Bulk assignment of forecasts to multiple groups/services
- **BDD Coverage**: Not covered
- **APIs Found**: Not captured
- **UI Elements**:
  - "Массовое назначение прогнозов": "Mass Forecast Assignment"
- **Implementation Status**: Not built
- **Priority**: High - enables efficient forecast distribution

### 3. Hidden Forecast Configuration Elements 🔍
- **Location**: Historical Data View hidden buttons
- **Description**: Advanced configuration dialogs discovered
- **Hidden Elements Found**:
  ```javascript
  - growth_coeff_form (Growth Coefficient)
  - minimum_operators_form (Minimum Operators)
  - stock_coefficient_form (Stock/Safety Coefficient)
  - absenteeism_dialog_form (Absenteeism Settings)
  ```
- **BDD Coverage**: Partially covered (only basic parameters)
- **Implementation Status**: Not built

### 4. Advanced Column Configuration ⚙️
- **Location**: All forecast data tables
- **Description**: Advanced table customization
- **Features**:
  - "Колонки": Column visibility toggle
  - "Сбросить настройку столбцов": Reset column configuration
  - "Расширенный режим": Extended/Advanced mode
- **BDD Coverage**: Not covered
- **Implementation Status**: Not built

### 5. Forecast Data Import Formats 📥
- **Location**: Historical Data View
- **Description**: Multiple import options discovered
- **Schema Types Found**:
  - "Уникальные поступившие" (Unique Incoming)
  - "Уникальные обработанные + Уникальные потерянные" (Unique Processed + Lost)
  - "Уникальные обработанные" (Unique Processed)
  - "Не уникальные поступившие" (Non-unique Incoming)
  - "Не уникальные обработанные + Уникальные потерянные" (Non-unique Processed + Lost)
  - "Не уникальные обработанные" (Non-unique Processed)
- **BDD Coverage**: Not covered
- **Implementation Impact**: Critical for data import functionality

### 6. Report Catalog Deep Dive 📊
- **Location**: `/ccwfm/views/env/tmp/ReportTypeMapView.xhtml`
- **Description**: Complete report listing with direct URLs
- **Working Reports Found**:
  1. Соблюдение расписания → WorkerScheduleAdherenceReportView.xhtml
  2. Расчёт заработной платы → T13FormReportView.xhtml
  3. Отчёт по прогнозу и плану → ForecastAndPlanReportView.xhtml
  4. Отчёт по опозданиям операторов → OperatorLateReportView.xhtml
  5. Отчёт по AHT → AhtReportView.xhtml
  6. Отчёт о %Ready → ReadyReportView.xhtml ✅ (Previously verified)
  7. Отчёт по предпочтениям → WorkerWishReportView.xhtml
  8. График работы сотрудников → WorkerScheduleReportView.xhtml
  9. Отчёт по %absenteeism новый → AbsenteeismNewReportView.xhtml
  10. Отчёт по итогу планирования вакансий → ResultsOfVacancyPlanningReportView.xhtml
  11. Общий отчет по рабочему времени (Custom report)
  12. Отчет по ролям с подразделением (Custom report)
  13. Отчет по Логированию (Custom report)
- **BDD Coverage**: Minimal (only basic reports covered)

### 7. Timezone Configuration 🌍
- **Location**: Multiple forecast views
- **Description**: Advanced timezone handling
- **Available Timezones**:
  - Москва (Moscow)
  - Владивосток (Vladivostok)
  - Екатеринбург (Yekaterinburg)
  - Калининград (Kaliningrad)
- **BDD Coverage**: Not covered
- **Implementation Priority**: Medium - affects all time-based calculations

### 8. Advanced Mode Toggle 🔧
- **Location**: Historical Data tables
- **Description**: "Расширенный режим" (Extended Mode) button
- **Potential Features**:
  - Additional columns in data view
  - Advanced filtering options
  - Expert-level parameters
- **BDD Coverage**: Not covered
- **Implementation Status**: Not built

## 🚨 Critical Gaps Found

### Missing Features Not in BDD:
1. **Forecast Accuracy Tracking** - Essential for forecast improvement
2. **Mass Assignment Tools** - Critical for large deployments
3. **Advanced Import Schemas** - 6 different data processing modes
4. **Report Scheduling** - Found UI hints but not accessible
5. **Custom Report Builder** - Evidence of custom reports but no builder UI

### Architecture Insights:
1. **Hidden Dialogs Pattern**: Multiple forms with `display:none` suggest modal-based advanced settings
2. **Coefficient Management**: Separate forms for each coefficient type (growth, stock, minimum)
3. **Dual-Mode Analysis**: Accuracy analysis has two distinct modes (group vs segment)
4. **Report Task System**: Reports run as background tasks with notification on completion

## 📈 Priority Recommendations

### High Priority (Daily Use):
1. Forecast Accuracy Analysis - Critical for continuous improvement
2. Mass Forecast Assignment - Essential for scaling
3. Advanced Import Schemas - Needed for varied data sources

### Medium Priority (Weekly Use):
1. Column Configuration - User experience enhancement
2. Extended Mode - Power user features
3. Custom Report Parameters - Flexibility

### Low Priority (Occasional Use):
1. Timezone variations beyond Moscow
2. Advanced coefficient dialogs
3. Report scheduling automation

## 🔧 Technical Discoveries

### UI Framework Patterns:
- PrimeFaces dialogs with hidden forms
- Coefficient inputs use spinner pattern
- Tables have built-in column state management
- Reports use task-based async execution

### Navigation Patterns:
- Direct URLs work for most report views
- Some views require session context (404 without proper navigation)
- Tab-based interfaces maintain state via hidden inputs

### Integration Points:
- Report Task system suggests job queue architecture
- Import functionality indicates ETL capabilities
- Mass assignment implies batch processing APIs

## 📋 Next Steps

1. **API Discovery**: Need to capture actual API calls using DevTools
2. **Export Testing**: Test all discovered export formats
3. **Report Verification**: Test each of the 13 report URLs
4. **Dialog Exploration**: Trigger hidden dialogs to document parameters
5. **Permission Testing**: Check role-based access to discovered features

This exploration revealed significant functionality gaps between BDD specs and actual Argus capabilities, particularly in reporting, bulk operations, and advanced configuration.