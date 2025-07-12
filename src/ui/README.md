# WFM Enterprise UI

## Overview
React-based UI for the WFM Enterprise system implementing the 5-tab workflow from Argus specifications.

## Quick Start

### Prerequisites
- Node.js 18+ and npm
- API server running on port 8000

### Installation & Running
```bash
# From project root (/main/project)
npm install
npm run dev

# UI will be available at http://localhost:3000
```

### Build for Production
```bash
npm run build
# Output in /main/project/dist
```

## Project Structure

```
/main/project/
├── index.html              # Entry point
├── package.json           # Dependencies
├── vite.config.ts         # Build configuration
├── tsconfig.json          # TypeScript config
├── tailwind.config.js     # Tailwind CSS config
└── src/
    ├── main.tsx          # React entry point
    └── ui/
        └── src/
            ├── index.css          # Global styles
            ├── App.tsx           # Main app component
            ├── components/       # Reusable components
            │   ├── charts/      # Data visualization
            │   │   ├── PeakAnalysisChart.tsx
            │   │   └── ForecastChart.tsx
            │   └── upload/      # File handling
            │       └── ExcelUploader.tsx
            ├── pages/           # Page components
            │   └── WorkflowTabs.tsx
            ├── services/        # API integration
            │   ├── apiClient.ts    # Base HTTP client
            │   └── wfmService.ts   # WFM API calls
            └── types/           # TypeScript types
                └── ChartTypes.ts
```

## Component Architecture

### WorkflowTabs.tsx
Main workflow component implementing 5-tab navigation:
1. **Historical Data** - Excel/CSV upload and preview
2. **Peak Analysis** - Hourly/weekly patterns and heatmap
3. **Seasonality Config** - Monthly patterns and events
4. **Forecast Results** - Multi-model comparison
5. **Operator Calculation** - Erlang C personnel calculation

### Key Components

#### ExcelUploader.tsx
- Drag & drop file upload
- Format validation (.xlsx, .xls, .csv)
- Progress indicator
- Data preview table (first 10 rows)

#### PeakAnalysisChart.tsx
- Hourly bar chart
- Weekly line chart
- Hour × Day heatmap
- Export to PNG/JPG

#### ForecastChart.tsx
- Historical vs forecast comparison
- Confidence intervals
- Model selection
- Accuracy metrics display

## API Integration

### Base Configuration
```typescript
// src/ui/src/services/apiClient.ts
const apiClient = new ApiClient({
  baseURL: '/api/v1',  // Proxied to http://localhost:8000
  timeout: 30000
});
```

### Key Endpoints

#### Historical Data
```typescript
// Upload file
await wfmService.uploadHistoricalData(file, onProgress);

// Retrieve data
await wfmService.getHistoricalData(dataId);
```

#### Algorithm Integration
```typescript
// List available algorithms
await wfmService.getAvailableAlgorithms();

// Personnel calculation
await wfmService.calculatePersonnel({
  callVolume: 100,
  avgHandleTime: 180,
  serviceLevelTarget: 80,
  shrinkage: 30
});
```

#### System Status
```typescript
// Check integration
await wfmService.testIntegration();

// System health
await wfmService.getSystemStatus();
```

## State Management
Currently using React's built-in useState hooks. Key state:
- `activeTab` - Current workflow tab
- `savedTabs` - Tracks which tabs have saved data
- `uploadedData` - Historical data from file upload
- `calculationResults` - Personnel calculation results

## Styling
- **Tailwind CSS** for utility-first styling
- **Responsive design** with mobile breakpoints
- **Color scheme**: Blue primary, gray secondary
- **Components**: Cards, buttons, inputs, tables

## Dependencies

### Core
- `react` & `react-dom` - UI framework
- `react-router-dom` - Routing
- `typescript` - Type safety
- `vite` - Build tool

### UI Components
- `chart.js` & `react-chartjs-2` - Charts
- `chartjs-adapter-date-fns` - Date handling
- `date-fns` - Date utilities

### Data Handling
- `axios` - HTTP client
- `xlsx` - Excel file parsing

### Styling
- `tailwindcss` - Utility CSS
- `clsx` - Conditional classes

## Environment Variables
None required. API proxy configured in vite.config.ts.

## Known Issues

### Phase 1 Complete
- ✅ 5-tab workflow implemented
- ✅ API integration working
- ✅ Data visualization functional
- ✅ Excel upload with preview

### Phase 2 Required (BDD Gaps)
1. **Gear Menu System** - Missing across all tabs
2. **Save Validation** - No enforcement between tabs
3. **Growth Factor Dialog** - Critical missing feature
4. **Excel Format Validation** - Not enforcing exact template

## Testing
```bash
# Run tests (when implemented)
npm test

# Manual testing checklist:
1. Upload Excel file in Historical tab
2. View charts in Peak Analysis
3. Configure seasonality settings
4. Check forecast visualization
5. Calculate personnel requirements
6. Test "Test API Integration" button
```

## Troubleshooting

### API Connection Issues
1. Ensure API server is running on port 8000
2. Check browser console for CORS errors
3. Verify proxy configuration in vite.config.ts

### Chart Display Issues
1. Check if chartjs-adapter-date-fns is installed
2. Verify data format matches ChartTypes.ts interfaces
3. Check browser console for Chart.js errors

### File Upload Issues
1. Verify file format (.xlsx, .xls, .csv)
2. Check file size (max 10MB)
3. Ensure proper Excel structure

## Future Enhancements
See `/main/project/docs/UI_BDD_GAP_ANALYSIS.md` for detailed Phase 2 requirements.