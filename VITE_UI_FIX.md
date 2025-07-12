# Vite UI Configuration Fix

## Issue Fixed
Vite couldn't resolve nested UI paths due to directory structure restrictions.

## Changes Made

### 1. Updated `/src/main.tsx`
```tsx
// Changed imports to point to correct UI location
import App from './ui/src/App';
import './ui/src/index.css';
```

### 2. Enhanced `vite.config.ts`
- Added `root: '.'` to establish project root
- Added multiple path aliases for easier imports:
  - `@` → `./src/ui/src`
  - `@components` → `./src/ui/src/components`
  - `@services` → `./src/ui/src/services`
  - `@types` → `./src/ui/src/types`
  - `@utils` → `./src/ui/src/utils`
- Added build configuration

### 3. Updated `tsconfig.json`
- Added matching path mappings for TypeScript
- Included `src/main.tsx` in compilation

## Directory Structure
```
/main/project/
├── index.html         # Entry HTML
├── src/
│   ├── main.tsx      # Vite entry point
│   └── ui/
│       └── src/      # UI components
│           ├── App.tsx
│           ├── components/
│           ├── services/
│           └── ...
├── vite.config.ts
└── tsconfig.json
```

## How to Use

### In UI components, use aliases:
```tsx
import { FileUpload } from '@components/FileUpload';
import { apiService } from '@services/api';
import type { Forecast } from '@types/models';
```

### Start Development Server:
```bash
cd /main/project
npm install
npm run dev
```

### API Proxy
Vite is configured to proxy `/api` requests to `http://localhost:8000` (FastAPI backend).

## Next Steps
1. Install dependencies: `npm install`
2. Start API server: `uvicorn src.api.main:app --reload`
3. Start UI dev server: `npm run dev`
4. Access UI at: http://localhost:3000