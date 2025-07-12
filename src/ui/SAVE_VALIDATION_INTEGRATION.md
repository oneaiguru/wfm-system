# Save Validation System Integration Guide

## Overview

This guide explains how to integrate and use the comprehensive save validation system that has been implemented for the WFM Enterprise UI project.

## Key Features

1. **Dirty State Tracking**: Automatically detects when form data changes
2. **Navigation Guards**: Prevents users from navigating away with unsaved changes
3. **Save Warnings**: Shows dialog when attempting to leave with unsaved data
4. **Keyboard Shortcuts**: Ctrl+S / Cmd+S for quick saving
5. **Visual Indicators**: Shows save status in tabs and content areas
6. **Browser Warning**: Warns users before closing browser with unsaved changes
7. **Auto-save Support**: Optional auto-save functionality with configurable delay
8. **Form Tracking**: Automatic detection of form changes

## Components Created

### 1. Save State Context (`/src/context/SaveStateContext.tsx`)
- Global state management for save states across all tabs
- Tracks dirty state, last saved time, and data for each tab
- Provides hooks for common save-related operations

### 2. Save Validation Hook (`/src/hooks/useSaveValidation.ts`)
- Core hook for managing save validation logic
- Handles save operations, dirty state, and error handling
- Supports auto-save functionality

### 3. Form Tracker Hook (`/src/hooks/useFormTracker.ts`)
- Automatically tracks form changes
- Detects when any input field changes
- Supports excluding specific fields from tracking

### 4. Save Warning Dialog (`/src/components/common/SaveWarningDialog.tsx`)
- Modal dialog for unsaved changes warning
- Options: Save, Discard, Cancel
- Shows loading state during save operations

### 5. Save Indicator (`/src/components/common/SaveIndicator.tsx`)
- Visual component showing save status
- Shows: Unsaved changes, Saving..., Saved (with timestamp)

### 6. Enhanced Workflow Tabs (`/src/pages/EnhancedWorkflowTabs.tsx`)
- Full implementation with save validation integrated
- Replaces the original WorkflowTabs component

## Integration Steps

### Step 1: Replace App Component

Replace the content of `/src/App.tsx` with:

```typescript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import EnhancedWorkflowTabs from './pages/EnhancedWorkflowTabs';
import './index.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<EnhancedWorkflowTabs />} />
          <Route path="/workflow" element={<EnhancedWorkflowTabs />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
```

### Step 2: Update Package Dependencies

Ensure your `package.json` includes all necessary dependencies:

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.0.0",
    "chart.js": "^4.0.0",
    "react-chartjs-2": "^5.0.0",
    "axios": "^1.0.0",
    "typescript": "^5.0.0"
  }
}
```

### Step 3: Run the Application

```bash
npm install
npm run dev
```

## Usage Examples

### Basic Save Validation in a Component

```typescript
import { useSaveValidation } from '@/hooks/useSaveValidation';
import { useSaveState } from '@/context/SaveStateContext';

const MyComponent = () => {
  const { setTabDirty } = useSaveState();
  const { state, save, markDirty } = useSaveValidation({
    tabId: 'myTab',
    onSave: async (data) => {
      // Your save logic here
      await api.saveData(data);
    }
  });

  const handleInputChange = () => {
    markDirty();
  };

  return (
    <div>
      <input onChange={handleInputChange} />
      {state.isDirty && <span>Unsaved changes</span>}
      <button onClick={() => save()}>Save</button>
    </div>
  );
};
```

### Using Form Tracker

```typescript
import { useFormTracker } from '@/hooks/useFormTracker';

const MyForm = () => {
  const formRef = useRef<HTMLDivElement>(null);
  const { initializeTracking, resetTracking } = useFormTracker({
    tabId: 'myForm',
    excludeSelectors: ['.no-track'] // Exclude elements with this class
  });

  useEffect(() => {
    if (formRef.current) {
      initializeTracking(formRef.current);
    }
  }, []);

  return (
    <div ref={formRef}>
      <input name="field1" />
      <input name="field2" />
      <input className="no-track" /> {/* This won't be tracked */}
    </div>
  );
};
```

## API Integration

The save validation system integrates with your existing API endpoints:

1. **Historical Data**: `POST /api/v1/argus/historic/upload`
2. **Peak Analysis**: `POST /api/v1/algorithms/peak/save`
3. **Seasonality**: `POST /api/v1/algorithms/seasonality/save`
4. **Forecast**: `POST /api/v1/algorithms/forecast/save`
5. **Calculation**: `POST /api/v1/algorithms/calculation/save`

## Customization Options

### 1. Auto-save Configuration

```typescript
const { save } = useSaveValidation({
  tabId: 'myTab',
  autoSave: true,
  autoSaveDelay: 5000, // 5 seconds
  onSave: async (data) => { /* ... */ }
});
```

### 2. Custom Save Indicators

```typescript
<SaveIndicator 
  isDirty={customDirtyState}
  isSaving={customSavingState}
  lastSavedAt={customSaveTime}
  className="custom-styling"
/>
```

### 3. Disable Navigation Guards

To disable navigation guards for specific tabs:

```typescript
const tabs = [
  { id: 'tab1', requiresSave: false }, // No save validation
  { id: 'tab2', requiresSave: true },  // Save validation enabled
];
```

## Keyboard Shortcuts

- **Ctrl+S / Cmd+S**: Save current tab (if it has unsaved changes)
- **Escape**: Close save warning dialog (cancels navigation)

## Best Practices

1. **Always provide save handlers**: Each tab should have its own save logic
2. **Use form tracking**: Automatic change detection reduces code complexity
3. **Handle errors gracefully**: Show user-friendly error messages
4. **Test navigation flows**: Ensure users can't lose data accidentally
5. **Provide visual feedback**: Use save indicators consistently

## Troubleshooting

### Issue: Changes not being detected
- Ensure form elements have `name` or `id` attributes
- Check if elements are excluded with `.no-track` class
- Verify form tracker is initialized after DOM is ready

### Issue: Save not working
- Check console for API errors
- Verify save handler is properly async
- Ensure API endpoints are accessible

### Issue: Navigation guards not working
- Verify `requiresSave` is set to `true` for the tab
- Check that dirty state is being set correctly
- Ensure SaveStateProvider wraps the component

## Testing

### Manual Testing Checklist

1. ✅ Make changes in a tab and try to navigate away
2. ✅ Press Ctrl+S to save
3. ✅ Try closing the browser with unsaved changes
4. ✅ Test Save/Discard/Cancel in warning dialog
5. ✅ Verify save indicators update correctly
6. ✅ Test with network errors (offline mode)
7. ✅ Verify form tracking detects all input types

### Automated Testing

```typescript
import { renderHook } from '@testing-library/react-hooks';
import { useSaveValidation } from '@/hooks/useSaveValidation';

test('marks dirty when data changes', () => {
  const { result } = renderHook(() => 
    useSaveValidation({ tabId: 'test' })
  );
  
  expect(result.current.state.isDirty).toBe(false);
  
  act(() => {
    result.current.markDirty();
  });
  
  expect(result.current.state.isDirty).toBe(true);
});
```

## Future Enhancements

1. **Conflict Resolution**: Handle concurrent edits
2. **Offline Support**: Queue saves when offline
3. **Undo/Redo**: Track change history
4. **Collaborative Editing**: Real-time multi-user support
5. **Advanced Auto-save**: Smart timing based on user activity

## Support

For questions or issues with the save validation system:
1. Check the console for error messages
2. Review the integration guide
3. Check the BDD specifications for expected behavior
4. Contact the development team