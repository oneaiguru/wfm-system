# UI-CLAUDE.md - UI Component Documentation

## Current Status
- **Total Components**: 89 TSX files (27 core + 62 module)
- **Naumen Migration**: 4/7 modules complete
- **BDD Coverage**: 3 test files only (minimal)
- **Framework**: React + TypeScript + Tailwind CSS

## Component Inventory

### Core Components (27)
```
components/
├── adapted/grid/           # 6 - Naumen-adapted grid system
│   ├── DraggableShift.tsx
│   ├── GridCell.tsx
│   ├── GridHeader.tsx
│   ├── GridShowcase.tsx
│   ├── ScheduleGrid.tsx
│   └── VirtualizedScheduleGrid.tsx
├── charts/                 # 2 - Data visualization
│   ├── ForecastChart.tsx
│   └── PeakAnalysisChart.tsx
├── common/                 # 3 - Shared UI elements
│   ├── GearMenu.tsx
│   ├── SaveIndicator.tsx
│   └── SaveWarningDialog.tsx
├── dashboard/              # 1 - Live metrics
│   └── RealTimeDashboard.tsx
├── demo/                   # 3 - Demo mode
│   ├── ComparisonView.tsx
│   ├── DemoMode.tsx
│   └── GuidedTour.tsx
├── multiskill/            # 3 - Multi-skill optimization
│   ├── QueueManager.tsx
│   ├── SkillMatrix.tsx
│   └── SkillOptimizer.tsx
└── Base Components        # 9 - Core functionality
    ├── Dashboard.tsx
    ├── Login.tsx
    ├── ExcelUploader.tsx
    └── [others]
```

### Module Components (62)
```
modules/
├── schedule-grid-system/    # 11 ✅ Migrated from Naumen
├── employee-portal/         # 11 ✅ Migrated 
├── reports-analytics/       # 4  ✅ Migrated
├── mobile-personal-cabinet/ # 6  ✅ Migrated
├── employee-management/     # 7  ⚠️  Started
├── wfm-integration/        # 6  ⚠️  Started
├── demo-plus-estimates/    # 6  ⚠️  Started
├── forecasting-analytics/  # 4  🔨 In progress
├── real-time-monitoring/   # 2  🔨 In progress
├── planning-workflows/     # 1  📝 Planned
├── business-process/       # 1  📝 Planned
└── system-administration/  # 3  📝 Planned
```

## Naumen Adaptation Guide

### Completed Migrations
1. **schedule-grid-system**
   - Russian → English translations
   - Traffic light indicators (🟢🟡🔴)
   - 30-second real-time updates
   - Drag-drop shift management

2. **employee-portal**
   - Personal schedule view
   - Shift marketplace
   - Request management
   - Mobile-responsive

3. **reports-analytics**
   - Executive dashboards
   - KPI metrics
   - Forecast accuracy displays
   - Traffic light status

4. **mobile-personal-cabinet**
   - Touch-optimized UI
   - Offline capability
   - Push notifications ready

### Migration Patterns
```typescript
// Naumen pattern
<StatusIndicator status={getTrafficLight(metric)} />

// Our implementation
const getTrafficLight = (value: number): 'green' | 'yellow' | 'red' => {
  if (value >= 90) return 'green';
  if (value >= 70) return 'yellow';
  return 'red';
};
```

## BDD Mapping Status

### Current Test Coverage
```
✅ apiIntegration.test.ts
✅ Dashboard.test.tsx  
✅ Login.test.tsx
❌ No .feature files
❌ No BDD scenarios
```

### Components Needing BDD
1. **Critical**: ScheduleGrid, SkillMatrix, ForecastChart
2. **High**: EmployeePortal, ShiftMarketplace
3. **Medium**: Reports, RealTimeDashboard
4. **Low**: Admin panels, Settings

## Key Commands

### Development
```bash
# Start UI development server
cd /project/src/ui
npm install
npm run dev

# Build for production
npm run build

# Run tests (limited)
npm test

# Type checking
npm run type-check
```

### Component Generation
```bash
# Generate new component
npx plop component MyComponent

# Generate module component
npx plop module employee-management MyFeature
```

## Next Priorities

1. **Complete Naumen Migrations**
   - employee-management module
   - wfm-integration module
   - demo-plus-estimates (ROI demos)

2. **BDD Test Coverage**
   - Create .feature files for each module
   - Implement Cucumber step definitions
   - Achieve 80% coverage target

3. **Performance Optimization**
   - Implement React.memo for grid cells
   - Add virtualization to all lists
   - Optimize re-renders in real-time components

4. **UI Enhancements**
   - Dark mode support
   - Accessibility (WCAG 2.1)
   - Internationalization (i18n)

## Known Issues

1. **Virtual Scrolling**: Occasional flicker in large grids
2. **Real-time Updates**: WebSocket reconnection needs improvement
3. **Mobile**: Some desktop features not adapted
4. **State Management**: Consider Redux for complex state

## Quick Navigation

- **Components**: `/project/src/ui/src/components/`
- **Modules**: `/project/src/ui/src/modules/`
- **Services**: `/project/src/ui/src/services/`
- **Types**: `/project/src/ui/src/types/`
- **Tests**: `/project/src/ui/src/__tests__/`

## UI Patterns

### Traffic Lights
```tsx
<div className={`status-indicator ${status}`}>
  {status === 'green' && '🟢'}
  {status === 'yellow' && '🟡'}
  {status === 'red' && '🔴'}
</div>
```

### Real-time Updates
```tsx
useEffect(() => {
  const interval = setInterval(fetchData, 30000);
  return () => clearInterval(interval);
}, []);
```

### Responsive Grid
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Grid items */}
</div>
```