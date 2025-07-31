# R3-ForecastAnalytics Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements forecast and analytics features through systematic MCP browser testing.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md
@../COMMON_MCP_LOGIN_PROCEDURES.md

## 📊 Your Assignment
- **Total scenarios**: 37 (corrected from initial 73)
- **Focus**: Document Argus forecasting, analytics dashboards, reports
- **Goal**: Create blueprint for our analytics implementation
- **Current Achievement**: 19/37 scenarios (51.4%) with direct MCP evidence

## 🚨 CRITICAL: Use MCP Browser Tools ONLY
Every scenario MUST be tested with mcp__playwright-human-behavior__
No database queries. No assumptions. Evidence required for each scenario.

## 🏗️ R3-SPECIFIC ARCHITECTURE DISCOVERY: 7-Tab Forecast Workflow

### The Most Important Finding:
Argus forecast module is NOT standalone features - it's a **sequential 7-tab workflow**:
1. Коррекция исторических данных по обращениям (Historical Data Correction - Calls)
2. Коррекция исторических данных по АНТ (Historical Data Correction - AHT)
3. Анализ пиков (Peak Analysis)
4. Анализ тренда (Trend Analysis)
5. Анализ сезонных составляющих (Seasonal Components Analysis)
6. Прогнозирование трафика и АНТ (Traffic and AHT Forecasting)
7. Расчет количества операторов (Operator Calculation)

**CRITICAL**: You CANNOT jump to tab 7 directly - must complete workflow in sequence!

## 🔧 WORKING MCP SEQUENCES FOR FORECAST TESTING

### Navigate to Forecast Module:
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/forecast/HistoricalDataListView.xhtml
# Result: "Спрогнозировать нагрузку" page with 7 tabs
```

### Access All Tabs via JavaScript:
```javascript
// When direct clicks fail, use JavaScript:
const tabs = Array.from(document.querySelectorAll('a[role="tab"]'));
const tabTexts = tabs.map(tab => tab.textContent.trim());
console.log('Found tabs:', tabTexts);
// Result: All 7 tabs accessible
```

### Import Forecasts Page:
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/forecast/import/ImportForecastView.xhtml
# Result: Two-tab structure - "Импорт обращений" and "Импорт операторов"
```

### Special Events Analysis:
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/forecast/specialdate/SpecialDateAnalysisView.xhtml
# Result: Coefficient grid with 96 time intervals (15-minute slots)
```

## 🚫 R3-SPECIFIC BLOCKERS & SOLUTIONS

### 1. Gear Icon Context Dependencies (Forecast-Specific)
- **Problem**: Import options only appear after data loaded
- **Solution**: Select service/group first, then check for gear icons
- **Context**: Unique to forecast module's conditional UI rendering

## 📊 R3-SPECIFIC TESTING FOCUS

### Forecast Module Unique Requirements:
✅ Verify 7-tab sequential workflow accessibility
✅ Document coefficient grid structures (96 intervals)
✅ Capture forecast-specific Russian terminology
✅ Test import/export forecast functionality
✅ Validate special date analysis features

## 💡 KEY DISCOVERIES FROM 51.4% TESTING

### Russian Forecast Terminology:
- Спрогнозировать нагрузку = Forecast Load
- Коррекция исторических данных = Historical Data Correction
- Анализ пиков = Peak Analysis
- Расчет количества операторов = Operator Calculation
- Анализ специальных дат = Special Date Analysis
- Импорт прогнозов = Import Forecasts
- Просмотр нагрузки = View Load

### URL Pattern for Forecast Module:
```
/ccwfm/views/env/forecast/[feature].xhtml
Where [feature] = HistoricalDataListView, import/ImportForecastView, ForecastListView, specialdate/SpecialDateAnalysisView
```


## 🎯 FORECAST-SPECIFIC PATTERNS TO DOCUMENT

### When Testing Forecast Features:
1. **Multi-Tab Dependencies**: Document which tabs must be completed before others
2. **Coefficient Grids**: Capture time interval structures (15-min, hourly, daily)
3. **Import Formats**: Document expected file structures for forecast imports
4. **Special Date Logic**: How holidays/events affect forecast calculations
5. **Aggregation Levels**: Service/group/skill forecast hierarchies

Remember: Focus on forecast-unique behaviors that differ from other modules.