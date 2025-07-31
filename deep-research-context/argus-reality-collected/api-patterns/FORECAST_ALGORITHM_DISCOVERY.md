# Forecast Algorithm Discovery - REVISED WITH DISCLAIMERS

**Date**: 2025-07-29 (Updated with proper disclaimers)
**Agent**: R3-ForecastAnalytics  
**Methodology**: MCP Browser Testing + Industry Inference
**Status**: UI Discovery Complete, Backend Algorithms Inferred

## ⚠️ CRITICAL DISCLAIMER

This document separates:
- **OBSERVED**: What was actually seen in Argus UI via MCP testing
- **INFERRED**: What the UI patterns suggest about backend implementation
- **ASSUMED**: Industry standard practices likely used but not confirmed

## What Was Actually Discovered

### OBSERVED via MCP Testing ✅

1. **7-Tab Workflow Structure**:
   - Tab 1: Коррекция исторических данных по обращениям
   - Tab 2: Коррекция исторических данных по АНТ
   - Tab 3: Анализ пиков
   - Tab 4: Анализ тренда
   - Tab 5: Анализ сезонных составляющих
   - Tab 6: Прогнозирование трафика и АНТ
   - Tab 7: Расчет количества операторов

2. **Actual UI Parameters Found**:
   - Коэффициент запаса (Safety Coefficient): numeric input, default 0.0
   - % Absenteeism: numeric input, default 0.0

3. **Technical Architecture**:
   - JSF/PrimeFaces framework
   - ViewState-based navigation
   - Service/Group selection required before tab access

### INFERRED from UI Patterns 🔍

#### 1. Sequential Algorithm Dependencies
```
Tab 1-2: Historical Data → Tab 3: Peak Analysis → Tab 4: Trend Analysis 
→ Tab 5: Seasonal Analysis → Tab 6: Forecasting → Tab 7: Staffing Calculation
```

#### 2. Data Context Flow
- **Service Selection**: Defines data scope for all algorithms
- **Group Selection**: Filters dataset for calculations
- **Parameter Persistence**: Each tab maintains calculation state
- **Validation Chain**: Cannot skip algorithm steps

#### 3. Algorithm Trigger Patterns
- **Button-Activated**: Server-side algorithm execution via button clicks
- **Parameter-Driven**: Input changes trigger recalculation APIs
- **State-Dependent**: Later algorithms depend on earlier results

## Algorithm Implementation Hints Discovered

### Peak Analysis (Tab 3)

**OBSERVED**:
- Tab labeled "Анализ пиков" exists
- Safety Coefficient input field present
- No formulas visible in UI

**INFERRED**:
- Tab name suggests peak/outlier detection functionality
- Safety Coefficient likely used as threshold multiplier

**ASSUMED (Industry Standard)**:
- ASSUMPTION: Likely uses statistical threshold like μ + (k × σ) where k = safety coefficient
- INDUSTRY STANDARD: Peak detection commonly uses 2-sigma or 3-sigma rules
- NOT DIRECTLY OBSERVED: No mathematical formulas displayed in UI

### Trend Analysis (Tab 4)

**OBSERVED**:
- Tab labeled "Анализ тренда" exists
- Tab position suggests it uses data from previous tabs

**INFERRED**:
- Name indicates trend detection/analysis functionality
- Sequential position implies dependency on cleaned data

**ASSUMED (Industry Standard)**:
- ASSUMPTION: Likely uses linear regression or moving averages
- INDUSTRY STANDARD: Trend analysis typically uses y = mx + b regression
- NOT DIRECTLY OBSERVED: No regression formulas or parameters visible yet

### Seasonal Analysis (Tab 5)
```http  
# Expected seasonal pattern detection
POST /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true&javax.faces.source=form:seasonalBtn&javax.faces.partial.execute=form:tabView:4:seasonPanel&javax.faces.partial.render=form:tabView:4:patternResults&javax.faces.ViewState=[viewstate]&form:tabView:4:cycleType=weekly&form:tabView:4:holidayAdjust=true
```

**Algorithm Indicators**:
- Cycle detection (weekly/monthly/yearly)
- Holiday adjustment coefficients
- Pattern recognition algorithms

### Staffing Calculation (Tab 7)

**OBSERVED**:
- Tab labeled "Расчет количества операторов" (Operator Calculation)
- Final tab in sequential workflow
- Absenteeism % parameter found

**INFERRED**:
- Purpose is to calculate required staff numbers
- Uses forecast data from previous tabs
- Absenteeism factor suggests workforce planning calculations

**ASSUMED (Industry Standard)**:
- ASSUMPTION: Contact centers typically use Erlang C for staffing
- INDUSTRY STANDARD: Erlang C is the most common WFM algorithm
- NOT CONFIRMED: No Erlang formula visible in UI
- SPECULATION: Could also use Erlang A or custom formula

## Summary: What We Actually Know vs What We Assume

### CONFIRMED FACTS ✅
1. 7-tab sequential workflow exists
2. 2 numeric parameters found (Safety Coefficient, Absenteeism %)
3. JSF/PrimeFaces framework used
4. Service/Group selection required
5. Tab names suggest algorithm purposes

### REASONABLE INFERENCES 🔍
1. Sequential dependency between tabs
2. Each tab likely performs specific calculations
3. Final tab produces staffing requirements
4. Parameters influence calculation results

### INDUSTRY ASSUMPTIONS ⚠️
1. Peak detection MIGHT use statistical thresholds
2. Trend analysis PROBABLY uses regression
3. Staffing LIKELY uses Erlang C (unconfirmed)
4. NO mathematical formulas were actually observed

## Honest Assessment

**What this document provides**:
- UI workflow that can be replicated
- Parameter names for implementation
- Logical algorithm sequence
- Industry-standard approaches that MIGHT apply

**What this document does NOT provide**:
- Actual mathematical formulas from Argus
- Confirmed algorithm implementations
- Backend calculation methods
- Proprietary Argus modifications

## Recommendation for Implementation

Use this as a starting point but:
1. Implement industry-standard algorithms as baseline
2. Allow for configuration/tuning
3. Don't assume Argus exact match
4. Test thoroughly against expected outputs

**Remember**: This is based on UI observation + industry knowledge, NOT reverse-engineered algorithms.