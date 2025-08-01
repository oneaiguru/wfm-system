# Modules

## Overview
Reusable React modules that make up the WFM Enterprise UI. Each module contains
components, state management and routing for a specific feature area.

## Features
- Isolated code for features such as reporting or scheduling
- Written in TypeScript with Tailwind styles
- Can be lazy loaded to reduce bundle size

## Usage
Import a module in `App.tsx`:
```tsx
import { ReportsModule } from './modules/reports-analytics';
```

## Testing
```bash
npm test
```

## Related Documentation
- [UI README](../../README.md)
- [Project README](../../../README.md)
