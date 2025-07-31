# Forecast Analytics API Documentation

## Forecast Workflow Endpoints

### Initial Forecast Page
```http
GET /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Accept: text/html,application/xhtml+xml

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8
```

### Service Selection (Expected)
```http
POST /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:serviceSelect&javax.faces.partial.execute=form:serviceSelect&javax.faces.partial.render=form:groupSelect&javax.faces.ViewState=[viewstate]&form:serviceSelect=КЦКЦ

# Response
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
```

### Group Selection (Expected)
```http
POST /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:groupSelect&javax.faces.partial.execute=form:groupSelect&javax.faces.partial.render=form:forecastTabs&javax.faces.ViewState=[viewstate]&form:groupSelect=2тест

# Response
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
```

### Tab Navigation (Expected)
```http
POST /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:tabView:1&javax.faces.partial.execute=form:tabView&javax.faces.partial.render=form:tabView&javax.faces.ViewState=[viewstate]&form:tabView_activeIndex=1

# Response
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
```

### Analysis Calculation (Expected)
```http
POST /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:analyzeButton&javax.faces.partial.execute=form:tabView:2:analysisPanel&javax.faces.partial.render=form:tabView:2:resultsPanel&javax.faces.ViewState=[viewstate]&form:tabView:2:analysisButton=Анализировать

# Response
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
```

## Import Forecast Endpoints

### Import Page
```http
GET /ccwfm/views/env/forecast/import/ImportForecastView.xhtml
Accept: text/html,application/xhtml+xml

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8
```

### File Upload (Expected)
```http
POST /ccwfm/views/env/forecast/import/ImportForecastView.xhtml
Content-Type: multipart/form-data

javax.faces.ViewState=[viewstate]&importForm:fileUpload=[file_data]&importForm:uploadButton=Загрузить

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8
```

## Special Events Analysis

### Special Events Page
```http
GET /ccwfm/views/env/forecast/specialdate/SpecialDateAnalysisView.xhtml
Accept: text/html,application/xhtml+xml

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8
```

### Coefficient Update (Expected)
```http
POST /ccwfm/views/env/forecast/specialdate/SpecialDateAnalysisView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:coeffGrid:0:coeffValue&javax.faces.partial.execute=form:coeffGrid:0:coeffValue&javax.faces.partial.render=form:coeffGrid&javax.faces.ViewState=[viewstate]&form:coeffGrid:0:coeffValue=1.2

# Response
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
```

## Authentication Required
All endpoints require valid session authentication via:
```http
POST /ccwfm/j_security_check
Content-Type: application/x-www-form-urlencoded

j_username=Konstantin&j_password=12345
```

## 🔍 Technical Implementation

### Navigation Pattern:
- **Client-Side**: Tab UI switching without page reload
- **Server State**: JSF maintains workflow state server-side
- **Validation**: Each tab validates before allowing progression
- **Data Persistence**: Temporary state maintained during workflow

### Service/Group Dependency:
- **Required Selection**: Workflow requires service and group selection
- **Data Context**: Selection determines available historical data
- **Filtering**: All analysis based on selected service/group scope

## 📊 Workflow State Management

### Tab Dependencies:
1. **Tab 1-2**: Historical data loading and correction
2. **Tab 3-5**: Analysis phases (peak, trend, seasonal)
3. **Tab 6**: Forecast generation based on analysis
4. **Tab 7**: Operator calculation from forecast results

### Data Flow:
```
Service/Group Selection → Historical Data → Analysis → Forecasting → Staffing
```

## 🚨 Discovery Limitations

### Current Session Results:
- **Total API Calls Captured**: 0
- **JSF AJAX Calls**: 0  
- **Fetch API Calls**: 0

### Potential Reasons:
1. **Pre-loaded Data**: Interface may pre-load all necessary data
2. **Static Navigation**: Tab switching is purely client-side
3. **Lazy Loading**: APIs triggered only when specific actions performed
4. **Session State**: Already authenticated session may cache data

## 🔄 Recommended Next Steps

### Enhanced API Discovery:
1. **Fresh Session**: Start with cleared cache and new login
2. **Service Selection**: Focus on service/group change events
3. **Button Interactions**: Click all analysis and calculation buttons
4. **Form Submissions**: Test any form inputs within tabs
5. **Network Panel**: Use browser DevTools as backup verification

### Missing API Patterns to Capture:
- Historical data retrieval endpoints
- Peak/trend/seasonal analysis calculations
- Forecast generation algorithms
- Operator calculation formulas
- Export/save functionality

## 💡 Implementation Insights

### For Development Team:
1. **Sequential Workflow**: Implement tab progression validation
2. **State Management**: Use session state for workflow persistence
3. **Data Dependencies**: Service/group selection drives all analysis
4. **Calculation Engine**: Server-side algorithms for all analysis phases
5. **Result Persistence**: Save workflow results between sessions

### Architecture Pattern:
- **Single Page Application**: Within JSF framework
- **Progressive Disclosure**: Each tab reveals next step
- **State Validation**: Prevent skipping required steps
- **Data Context**: Maintain selected parameters throughout workflow

## 🎯 Completion Status

**API Discovery**: Partial - Navigation patterns documented, calculation APIs need deeper investigation  
**Workflow Understanding**: Complete - 7-tab sequence fully mapped  
**Next Priority**: Enhanced session with focused API capture on calculation triggers  

This document provides the foundation for implementing Argus-compatible forecast workflow with proper state management and sequential processing architecture.