# UI BDD Gap Analysis - Current Implementation vs Argus Requirements

## Executive Summary
This document maps the current UI implementation to Argus BDD requirements and identifies gaps for Phase 2 development.

## Current UI Tab Mapping to BDD Workflows

### 1. Historical Data Tab → "Historical Data Correction"
**BDD Reference**: `08-load-forecasting-demand-planning.feature`, lines 40-55

| Requirement | Current State | Status | Gap |
|-------------|---------------|---------|-----|
| Excel/CSV upload | ✅ Implemented | Complete | - |
| Drag & drop | ✅ Implemented | Complete | - |
| Format validation | ✅ Basic validation | Partial | Missing exact template format from Table 1 |
| Preview table | ✅ Shows first 10 rows | Complete | - |
| "Gear" menu → Import | ❌ Not implemented | Missing | No gear menu functionality |
| Save before navigation | ❌ Not enforced | Missing | Can navigate without saving |

### 2. Peak Analysis Tab → "Peak Analysis"
**BDD Reference**: `08-load-forecasting-demand-planning.feature`, Peak Analysis workflow

| Requirement | Current State | Status | Gap |
|-------------|---------------|---------|-----|
| Hourly bar chart | ✅ Implemented | Complete | - |
| Weekly pattern line | ✅ Implemented | Complete | - |
| Heatmap visualization | ✅ Implemented | Complete | - |
| Export functionality | ✅ PNG/JPG export | Complete | - |
| Smoothing outliers | ❌ Not implemented | Missing | No outlier smoothing controls |
| "Gear" menu → Save | ❌ Not implemented | Missing | No gear menu functionality |

### 3. Seasonality Tab → "Seasonal Components"
**BDD Reference**: `08-load-forecasting-demand-planning.feature`, Seasonal Components workflow

| Requirement | Current State | Status | Gap |
|-------------|---------------|---------|-----|
| Monthly patterns | ✅ Checkboxes | Complete | - |
| Special events | ✅ Checkboxes | Complete | - |
| Seasonality factor | ✅ Slider 0.5x-2.0x | Complete | - |
| Pattern templates | ❌ Not implemented | Missing | No predefined seasonal templates |
| Historical comparison | ❌ Not implemented | Missing | No year-over-year comparison |

### 4. Forecast Tab → "Traffic and AHT Forecasting"
**BDD Reference**: `08-load-forecasting-demand-planning.feature`, lines 84-95

| Requirement | Current State | Status | Gap |
|-------------|---------------|---------|-----|
| Algorithm selection | ✅ Dropdown (ARIMA, etc.) | Complete | - |
| Forecast visualization | ✅ Line chart | Complete | - |
| Confidence intervals | ✅ Toggle on/off | Complete | - |
| Model comparison | ✅ Comparison table | Complete | - |
| Growth Factor dialog | ❌ Not implemented | Missing | Critical missing feature |
| "Gear" → Growth Factor | ❌ Not implemented | Missing | No gear menu functionality |
| Period selection | ❌ Basic only | Partial | Missing detailed period configuration |

### 5. Calculation Tab → "Operator Calculation"
**BDD Reference**: `08-load-forecasting-demand-planning.feature`, Operator calculation workflow

| Requirement | Current State | Status | Gap |
|-------------|---------------|---------|-----|
| Call volume input | ✅ Input field | Complete | - |
| AHT input | ✅ Input field (seconds) | Complete | - |
| Service level target | ✅ Input field (%) | Complete | - |
| Shrinkage | ✅ Input field (%) | Complete | - |
| Erlang C calculation | ✅ API integration | Complete | - |
| Multi-skill support | ❌ Not implemented | Missing | No multi-skill allocation |
| FTE breakdown | ✅ Basic FTE display | Partial | Missing detailed breakdown |

## Critical Missing Features

### 1. Gear Menu System
**Impact**: High - Required throughout workflow
- No "gear" icon implementation
- Missing menu options: Save, Import, Export, Recalculate, Growth Factor
- Required for data persistence between tabs

### 2. Save Enforcement
**Impact**: High - Data integrity
- No validation before tab navigation
- Missing "Save before proceeding" warnings
- No data persistence confirmation

### 3. Growth Factor Dialog
**Impact**: Critical - Key business requirement
- Completely missing from Forecast tab
- Required for scaling scenarios (1,000 → 5,000 calls)
- Must maintain AHT while scaling volume

### 4. Multi-skill Planning
**Impact**: Medium - Advanced features
- No multi-skill template support
- Missing group aggregation
- No weighted average calculations

### 5. Exact Format Validation
**Impact**: Medium - Data quality
- Missing Table 1 Excel format enforcement:
  - Column A: DD.MM.YYYY HH:MM:SS
  - Column B: Unique incoming (Integer)
  - Column C: Non-unique incoming (Integer)
  - Column D: Average talk time (Seconds)
  - Column E: Post-processing (Seconds)

## Phase 2 Recommendations

### Priority 1 - Core Workflow Compliance
1. Implement gear menu system across all tabs
2. Add save enforcement between tab navigation
3. Create Growth Factor dialog for Forecast tab
4. Implement exact Excel template validation

### Priority 2 - Enhanced Features
1. Add outlier smoothing in Peak Analysis
2. Implement seasonal pattern templates
3. Add multi-skill support in Calculation tab
4. Create aggregated group handling

### Priority 3 - UI/UX Improvements
1. Add tooltips matching BDD descriptions
2. Implement keyboard shortcuts
3. Add progress indicators for long operations
4. Create help documentation links

## Technical Implementation Notes

### Gear Menu Implementation
```typescript
interface GearMenuOptions {
  save?: boolean;
  import?: boolean;
  export?: boolean;
  recalculate?: boolean;
  growthFactor?: boolean;
  requestData?: boolean;
}

// Each tab should have context-specific gear menu options
const gearMenuByTab: Record<string, GearMenuOptions> = {
  historical: { save: true, import: true, requestData: true },
  peak: { save: true, export: true },
  seasonality: { save: true },
  forecast: { save: true, growthFactor: true },
  calculation: { export: true }
};
```

### Save Enforcement
```typescript
// Add to tab navigation logic
const canNavigateToTab = (targetTab: string): boolean => {
  const currentTabRequiresSave = tabs.find(t => t.id === activeTab)?.requiresSave;
  if (currentTabRequiresSave && !savedTabs.has(activeTab)) {
    showWarning("Please save data before proceeding to next tab");
    return false;
  }
  return true;
};
```

### Growth Factor Dialog Structure
```typescript
interface GrowthFactorConfig {
  period: { start: Date; end: Date };
  growthFactor: number;
  applyTo: 'callVolume' | 'both';
  maintainAHT: boolean;
}
```

## Conclusion
The current implementation provides a solid foundation with 60% of core features implemented. Key gaps are in workflow compliance (gear menu, save enforcement) and the critical Growth Factor feature. Phase 2 should prioritize these workflow compliance issues before adding enhanced features.