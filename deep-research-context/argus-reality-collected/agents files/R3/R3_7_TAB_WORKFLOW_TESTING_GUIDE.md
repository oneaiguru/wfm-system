# R3-ForecastAnalytics 7-Tab Workflow Testing Guide

**Purpose**: Comprehensive guide for navigating and testing Argus forecast 7-tab sequential workflow  
**Critical Discovery**: Tabs must be accessed in sequential order 1→2→3→4→5→6→7  
**Status**: Essential for all R3 forecast scenario testing  
**Last Updated**: 2025-07-28

## 🔄 SEQUENTIAL TAB ARCHITECTURE

### Tab Order & Dependencies
```
Tab 1: Данные (Data/Input)          ← START HERE
    ↓
Tab 2: Импорт (Import)              ← Requires Tab 1 completion
    ↓  
Tab 3: Обработка (Processing)       ← Requires data from Tab 2
    ↓
Tab 4: Прогноз (Forecasting)        ← Requires processed data
    ↓
Tab 5: Результаты (Results)         ← Requires forecast completion
    ↓
Tab 6: Отчеты (Reports)             ← Requires results data
    ↓
Tab 7: Экспорт (Export)             ← Final workflow stage
```

### Critical Rule: NO TAB SKIPPING
- **Cannot jump**: Tab 1 → Tab 4 directly
- **Cannot reverse**: Tab 5 → Tab 2 may reset progress
- **Must progress**: Each tab enables the next in sequence

## 📋 TAB-BY-TAB TESTING PROCEDURES

### TAB 1: Данные (Data/Input)
**Entry Point for All Forecast Testing**

#### MCP Access Pattern:
```bash
# Initial navigation
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/views/forecast/ForecastDataInput.xhtml

# Verify Tab 1 is active
mcp__playwright-human-behavior__wait_and_observe → .tab-data-input → 3000

# Document interface state
mcp__playwright-human-behavior__screenshot → fullPage: true
mcp__playwright-human-behavior__get_content → selector: .data-input-form
```

#### Expected Elements:
- Data input form fields
- Historical data parameters
- Time period selectors
- Russian labels: "Период прогнозирования", "Исторические данные"

#### Testing Validation:
- [ ] Form fields accessible
- [ ] Date pickers functional
- [ ] Validation messages in Russian
- [ ] Save/Next button enabled

---

### TAB 2: Импорт (Import)
**Historical Data Loading**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 1 must be completed first
mcp__playwright-human-behavior__click → .tab-import
mcp__playwright-human-behavior__wait_and_observe → .import-interface → 5000

# Test file upload interface
mcp__playwright-human-behavior__get_content → selector: .file-upload-area
mcp__playwright-human-behavior__click → .file-upload-button
```

#### Expected Elements:
- File upload interface
- Supported format list
- Data validation controls
- Russian labels: "Загрузить файл", "Формат файла", "Проверка данных"

#### Processing Time: 10-30 seconds for data validation

---

### TAB 3: Обработка (Processing)
**Data Processing Configuration**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 2 data import completed
mcp__playwright-human-behavior__click → .tab-processing
mcp__playwright-human-behavior__wait_and_observe → .processing-config → 3000

# Document processing options
mcp__playwright-human-behavior__get_content → selector: .processing-parameters
mcp__playwright-human-behavior__click → .smoothing-options
```

#### Expected Elements:
- Data smoothing options
- Quality assessment tools
- Outlier detection settings
- Russian labels: "Сглаживание данных", "Качество данных", "Выбросы"

#### Processing Time: 5-15 seconds for parameter changes

---

### TAB 4: Прогноз (Forecasting)
**Algorithm Selection & Configuration**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 3 processing completed  
mcp__playwright-human-behavior__click → .tab-forecast
mcp__playwright-human-behavior__wait_and_observe → .forecast-algorithms → 5000

# Test algorithm selection
mcp__playwright-human-behavior__click → .algorithm-dropdown
mcp__playwright-human-behavior__get_content → selector: .algorithm-options
mcp__playwright-human-behavior__click → option[value="exponential-smoothing"]
```

#### Expected Elements:
- Algorithm dropdown (ARIMA, Exponential Smoothing, Linear Regression)
- Parameter configuration fields
- Forecast horizon settings
- Russian labels: "Алгоритм прогнозирования", "Горизонт прогноза"

#### Processing Time: 30-120 seconds for forecast calculations

---

### TAB 5: Результаты (Results)
**Forecast Output Display**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 4 forecast generation completed
mcp__playwright-human-behavior__click → .tab-results
mcp__playwright-human-behavior__wait_and_observe → .forecast-results → 10000

# Document results table
mcp__playwright-human-behavior__get_content → selector: .results-table
mcp__playwright-human-behavior__get_content → selector: .accuracy-metrics
```

#### Expected Elements:
- Forecast values table
- Accuracy metrics display
- Confidence intervals
- Russian labels: "Прогнозные значения", "Точность прогноза", "Доверительный интервал"

#### Processing Time: 5-10 seconds for results loading

---

### TAB 6: Отчеты (Reports)
**Report Generation Interface**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 5 results available
mcp__playwright-human-behavior__click → .tab-reports
mcp__playwright-human-behavior__wait_and_observe → .report-builder → 3000

# Test report templates
mcp__playwright-human-behavior__get_content → selector: .report-templates
mcp__playwright-human-behavior__click → .template-forecast-summary
```

#### Expected Elements:
- Report template selection
- Custom report builder
- Format options
- Russian labels: "Шаблон отчета", "Сводка прогноза", "Создать отчет"

#### Processing Time: 15-45 seconds for report generation

---

### TAB 7: Экспорт (Export)
**Data Export Options**

#### MCP Navigation Pattern:
```bash
# PREREQUISITE: Tab 6 reports generated
mcp__playwright-human-behavior__click → .tab-export
mcp__playwright-human-behavior__wait_and_observe → .export-options → 3000

# Test export configuration
mcp__playwright-human-behavior__get_content → selector: .export-formats
mcp__playwright-human-behavior__click → input[value="excel"]
```

#### Expected Elements:
- Export format selection (Excel, CSV, PDF)
- Content selection options
- Download triggers
- Russian labels: "Формат файла", "Excel файл", "Включить графики"

#### Processing Time: 10-30 seconds for export preparation

## 🚨 WORKFLOW TESTING CHALLENGES

### Common Navigation Failures

#### Tab Dependency Violations
**Problem**: Clicking Tab 4 when Tab 1-3 incomplete  
**Symptoms**: Empty interface, loading errors, disabled controls  
**Solution**: Always start from Tab 1, progress sequentially

#### Session Timeout During Processing
**Problem**: Long forecast calculations exceed session limits  
**Symptoms**: "Время жизни страницы истекло" during Tab 4-5  
**Solution**: 
```bash
# Re-login and resume from last completed tab
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
# Standard login sequence
# Navigate back to forecast module
# Resume from highest completed tab
```

#### Data Loss Between Tabs
**Problem**: Tab navigation resets previous configuration  
**Symptoms**: Empty forms when returning to earlier tabs  
**Solution**: Complete entire workflow in single session, document state at each tab

### Processing Time Management

#### Tab-Specific Timeout Patterns
- **Tab 1-3**: 3-5 second navigation
- **Tab 4**: 30-120 seconds (algorithm processing)
- **Tab 5**: 5-10 seconds (results loading)  
- **Tab 6**: 15-45 seconds (report generation)
- **Tab 7**: 10-30 seconds (export preparation)

#### MCP Wait Time Adjustments
```bash
# For heavy processing tabs (4, 6)
mcp__playwright-human-behavior__wait_and_observe → [selector] → 45000

# For standard navigation (1, 2, 3, 5, 7)
mcp__playwright-human-behavior__wait_and_observe → [selector] → 5000
```

## 📝 SCENARIO MAPPING TO TAB WORKFLOW

### Single-Tab Scenarios
- **Scenario 01 (Data Input)**: Tab 1 only
- **Scenario 02 (Import)**: Tab 1 → Tab 2
- **Scenario 04 (Algorithm)**: Tab 1 → Tab 2 → Tab 3 → Tab 4
- **Scenario 05 (Results)**: Full workflow 1→2→3→4→5

### Multi-Tab Scenarios
- **Complete Forecast Workflow**: Tabs 1-7 sequential
- **Data to Results**: Tabs 1-5 (most common testing pattern)
- **Algorithm Comparison**: Multiple Tab 4 configurations

### Scenario Batching Strategy
```
Batch 1 (Tab 1-2 Focus): Scenarios 01, 02, data input scenarios
Batch 2 (Tab 3-4 Focus): Scenarios 03, 04, algorithm scenarios  
Batch 3 (Tab 5-7 Focus): Scenarios 05, 07, 08, results/reports/export
```

## ✅ WORKFLOW TESTING CHECKLIST

### Pre-Session Verification
- [ ] Login successful (Konstantin/12345)
- [ ] Forecast module accessible
- [ ] Tab 1 interface loads properly
- [ ] No immediate session timeout warnings

### During Tab Navigation
- [ ] Each tab clicked in sequential order
- [ ] Processing times documented for heavy operations
- [ ] Russian interface text captured at each tab
- [ ] Screenshots taken showing tab progression
- [ ] Errors/timeouts documented with exact tab context

### Post-Workflow Documentation
- [ ] Complete tab sequence documented for scenario
- [ ] Processing times recorded for each tab
- [ ] Tab dependencies noted for scenario reproduction
- [ ] Workflow failures mapped to specific tab limitations

## 🎯 WORKFLOW MASTERY OBJECTIVES

### Understanding Goals
- **Sequential Navigation**: Automatic progression through tabs 1-7
- **Timing Expectations**: Realistic processing time estimates per tab
- **Dependency Mapping**: Clear understanding of tab prerequisites
- **Error Recovery**: Efficient session recovery at appropriate tab

### Documentation Excellence
- **Tab Context**: Every scenario includes tab workflow context
- **Processing Evidence**: Heavy operations documented with actual timing
- **Russian Terminology**: Tab-specific terms captured systematically
- **Reproduction Clarity**: Tab sequences documented for exact replication

---

**Master the 7-tab workflow to unlock all R3-ForecastAnalytics scenario testing efficiency.**