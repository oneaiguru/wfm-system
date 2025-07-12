# UI Troubleshooting Guide

## Current Issue
When clicking "Peak Analysis" tab, getting empty HTML response instead of rendered React component.

## Debugging Steps

### 1. Test Simple React App
I've created `/src/main-simple.tsx` that renders a basic React component.
- Run: `npm run dev`
- If you see "WFM Enterprise - Simple Test", React is working

### 2. Check Console Errors
Open browser DevTools (F12) and check:
- Console tab for JavaScript errors
- Network tab for failed resource loads

### 3. Common Issues & Fixes

#### Issue: Module not found errors
```bash
# Install dependencies
cd /main/project
npm install
```

#### Issue: TypeScript errors
```bash
# Try running without type checking
npx vite --mode development
```

#### Issue: Port already in use
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9
# Or use different port
npx vite --port 3001
```

### 4. Test Full App
Once simple app works, switch back to full app:

1. Edit `index.html`:
   ```html
   <script type="module" src="/src/main.tsx"></script>
   ```

2. Verify imports in `/src/main.tsx`:
   ```tsx
   import App from './ui/src/App';
   import './ui/src/index.css';
   ```

### 5. Check Tab Navigation
The Peak Analysis tab requires:
- Historical data to be uploaded first
- Previous tab to be "saved" (click Save button)

### 6. Alternative Solutions

#### Option A: Direct Import
Update `/src/main.tsx`:
```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import WorkflowTabs from './ui/src/pages/WorkflowTabs';
import './ui/src/index.css';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <WorkflowTabs />
  </React.StrictMode>
);
```

#### Option B: Move UI files
Move UI source to simpler structure:
```bash
mv src/ui/src/* src/
rm -rf src/ui
```

### 7. Verify File Structure
```
/main/project/
├── index.html
├── src/
│   ├── main.tsx (or main-simple.tsx for testing)
│   └── ui/
│       └── src/
│           ├── App.tsx
│           ├── index.css
│           ├── components/
│           ├── pages/
│           │   └── WorkflowTabs.tsx
│           └── services/
```

### 8. API Connection
Ensure API is running for full functionality:
```bash
# Terminal 1: Start API
cd /main/project
uvicorn src.api.main:app --reload

# Terminal 2: Start UI
npm run dev
```

## Next Steps
1. Try the simple app first (`main-simple.tsx`)
2. Check browser console for specific errors
3. Share any error messages for targeted fixes