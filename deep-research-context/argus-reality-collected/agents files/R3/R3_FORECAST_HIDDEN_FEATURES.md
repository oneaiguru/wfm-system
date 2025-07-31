# R3-ForecastAnalytics Domain-Specific Hidden Features
**Date**: 2025-07-30
**Agent**: R3-ForecastAnalytics
**Time Box**: 3 Hours
**Method**: HTML Analysis + Previous MCP Testing

## 🎯 R3-Specific Hidden Features

### 1. Empty Data Import Recovery Options ⚠️
**Feature**: "Нет исторических данных для прогнозирования" error handling
**Where Found**: 
- `/organized_html/03_analytics/historical/HistoricalDataListView.xhtml`
- Error growl message with recovery options
**Why Not in BDD**: 
- BDD assumes data always exists
- Error recovery flows not specified
**Implementation Impact**: High - need graceful handling of empty forecast scenarios

**Details Found**:
```javascript
msgs:[{
  summary:"Нет исторических данных для прогнозирования",
  detail:"Выберите другие параметры или импортируйте данные",
  severity:'error'
}]
```

### 2. Advanced Coefficient Dialogs 🔧
**Feature**: Hidden modal dialogs for coefficient configuration
**Where Found**: 
- `growth_coeff_dialog` - Growth Coefficient
- `stock_coefficient_dialog` - Stock/Safety Coefficient  
- `minimum_operators_form` - Minimum Operators
- `absenteeism_dialog_form` - Absenteeism Settings
**Why Not in BDD**: 
- BDD only mentions basic coefficient inputs
- Advanced period-based updates not covered
**Implementation Impact**: Medium - requires modal dialog framework

**Hidden Dialog Structure**:
```html
<div id="growth_coeff_dialog" class="ui-hidden-container">
  - "Обновить за указанный период с учетом коэффициента роста"
  - Period date pickers with 15-minute intervals
  - Apply coefficient over date range
</div>
```

### 3. Import Schema Variations 📥
**Feature**: 6 different data processing schemas for import
**Where Found**: 
- Historical Data dropdown options
- Not visible until service selected
**Why Not in BDD**: 
- BDD treats import as single feature
- Schema complexity hidden from specs
**Implementation Impact**: High - affects data processing logic

**Schema Types Discovered**:
1. "Уникальные поступившие" (Unique Incoming)
2. "Уникальные обработанные + Уникальные потерянные" (Unique Processed + Lost)
3. "Уникальные обработанные" (Unique Processed)
4. "Не уникальные поступившие" (Non-unique Incoming)
5. "Не уникальные обработанные + Уникальные потерянные" (Non-unique Processed + Lost)
6. "Не уникальные обработанные" (Non-unique Processed)

### 4. Forecast Update Settings ⚙️
**Feature**: `/ccwfm/views/env/forecast/ForecastUpdateSettingsView.xhtml`
**Where Found**: 
- Menu item "Настройки обновления" in Forecast submenu
- First item in forecast menu (priority placement)
**Why Not in BDD**: 
- Settings/configuration pages often overlooked
- Focus on operational features
**Implementation Impact**: Medium - system-wide forecast behavior

### 5. Special Events Management 🎯
**Feature**: "Особые события" - Special date handling beyond holidays
**Where Found**: 
- `/ccwfm/views/env/forecast/ForecastSpecialEventListView.xhtml`
- Separate from Special Date Analysis
- In Reference Data menu, not Forecast menu
**Why Not in BDD**: 
- Confused with holiday handling
- Cross-module feature
**Implementation Impact**: High - affects forecast accuracy

### 6. Historical Data Validation Rules 🔍
**Feature**: Multi-stage validation before forecast
**Where Found**: 
- Error message: "validationFailed":true in response
- Required: Service + Group + Schema selection
- Date range validation implicit
**Why Not in BDD**: 
- BDD assumes happy path
- Validation rules scattered
**Implementation Impact**: High - data quality gates

### 7. Period-Based Coefficient Application 📅
**Feature**: Apply coefficients to specific date ranges
**Where Found**: 
- Hidden dialogs with period selectors
- "Обновить за указанный период" (Update for specified period)
- 15-minute granularity on timestamps
**Why Not in BDD**: 
- BDD shows global coefficients only
- Temporal variation not specified
**Implementation Impact**: High - changes calculation model

### 8. Forecast Templates (Indirect Evidence) 📋
**Feature**: Template-based forecasting suggested by URL patterns
**Where Found**: 
- Error accessing template-like structures
- Import functionality suggests template support
- "Импорт операторов" separate from "Импорт обращений"
**Why Not in BDD**: 
- No explicit template management spec
- Import specs don't mention templates
**Implementation Impact**: Medium - reusable forecast patterns

### 9. Dual Import Modes 🔄
**Feature**: Separate tabs for importing calls vs operators
**Where Found**: 
- ImportForecastView.xhtml with tab structure
- "Импорт обращений" (Import Calls)
- "Импорт операторов" (Import Operators)
**Why Not in BDD**: 
- BDD treats import as single feature
- Operator import suggests staffing templates
**Implementation Impact**: High - different data structures

### 10. Time Zone Complexity 🌍
**Feature**: 4 timezone options with specific cities
**Where Found**: 
- All forecast views have timezone selector
- Moscow, Vladivostok, Yekaterinburg, Kaliningrad
- Affects all time-based calculations
**Why Not in BDD**: 
- BDD assumes single timezone
- Multi-region support not specified
**Implementation Impact**: High - all datetime handling

## 🚨 Critical Discoveries

### What-If Scenarios: NOT FOUND ❌
- No evidence of what-if UI in HTML
- No scenario comparison features
- Possible confusion with accuracy analysis "modes"

### Forecast Error Recovery
- Growl notifications for all errors
- "Try again" implicit in parameter change message
- Session timeout (22min) affects long forecasts

### Hidden Menu Access
- "Особые события" in Reference menu, not Forecast
- "Настройки обновления" as first forecast menu item
- Cross-module dependencies not obvious

## 📈 Implementation Priorities

### Must Have (Breaking Features):
1. 6 Import Schema Types - data won't import correctly
2. Service/Group/Schema validation chain
3. Timezone handling for all calculations
4. Error state recovery flows

### Should Have (User Experience):
1. Period-based coefficient updates
2. Dual import modes (calls vs operators)
3. Advanced column configuration
4. Special events beyond holidays

### Nice to Have (Advanced):
1. Template management (inferred)
2. Forecast update settings
3. Extended validation messages
4. 15-minute time granularity

## 🔍 Technical Insights

### Dialog Pattern
All advanced settings use hidden PrimeFaces dialogs:
- Initially display:none
- Modal with specific positioning
- Triggered by hidden buttons
- Contains complex forms

### Validation Pattern
Multi-field dependency validation:
1. Service selection enables groups
2. Group selection enables schema
3. Schema selection enables forecast
4. All three required for any operation

### Import Architecture
Suggests three-tier import:
1. Raw data (calls)
2. Calculated requirements (operators)  
3. Templates/patterns (inferred)

## 🔍 LIVE MCP DISCOVERIES (2025-07-30)

### 11. Automatic Forecast Updates ⏰
**Feature**: Scheduled daily forecast data refresh
**Where Found**: 
- `/ccwfm/views/env/forecast/ForecastUpdateSettingsView.xhtml` (NOW WORKING!)
- Daily updates at 02:15:00 Europe/Moscow timezone
- Frequency options: Daily, Weekly, Monthly
**Why Not in BDD**: 
- System administration feature overlooked
- Focus on manual forecast generation
**Implementation Impact**: HIGH - affects data freshness and system load

**Configuration Found**:
```
Частота получения: Ежедневно
Время: 02:15:00  
Часовой пояс: Europe/Moscow
```

### 12. Special Events with Real Coefficients 🎯
**Feature**: Event-based forecast multipliers with date ranges
**Where Found**: 
- `/ccwfm/views/env/forecast/ForecastSpecialEventListView.xhtml` (NOW WORKING!)
- Real data: "Прогноз событие 1" with 5.0 coefficient
- Date range: 24.07.2025 - 31.08.2025
**Why Not in BDD**: 
- Located in Reference menu, not Forecast menu
- Cross-module feature dependency
**Implementation Impact**: HIGH - affects forecast accuracy significantly

**Real Events Found**:
- "Прогноз событие 1 тест загрузки": Coefficient 5.0
- "акция приведи друга": Coefficient 2.0
- Date-specific multipliers for call volume

### 13. Bulk Assignment Operations ⚙️
**Feature**: "Назначить параметры" (Assign Parameters) bulk action
**Where Found**: 
- Mass Assignment page with working "Назначить параметры" button
- Confirmation dialog infrastructure
- Error handling dialog: "ajax_error_dlg"
**Why Not in BDD**: 
- Administrative bulk operations not specified
- Focus on individual forecast assignment
**Implementation Impact**: MEDIUM - operational efficiency

### 14. Cross-Timezone Configuration 🌍
**Feature**: Full timezone support beyond Moscow
**Where Found**: 
- All forecast update settings have 4 timezone options
- Europe/Moscow as default
- Vladivostok, Екатеринбург, Калининград options
**Why Not in BDD**: 
- Assumed single timezone deployment
- Multi-region complexity not considered
**Implementation Impact**: HIGH - all datetime calculations affected

## 📝 Notes

- **MCP SUCCESS**: Live testing revealed 4 additional major features
- Focus was on R3-specific forecast domain features  
- Avoided duplication with common features (search, notifications, etc.)
- HTML analysis + Live testing = complete picture
- What-if scenarios appear to be misunderstood - no direct evidence found
- **CRITICAL**: Automatic updates at 2:15 AM could conflict with user workflows