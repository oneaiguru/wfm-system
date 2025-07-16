# UI Component Priority List - Next Session Targets

## 🎯 **Truth Keeper Strategy: Quality Over Quantity**

**Current Status**: 2/104 real components (1.92%) ✅ VERIFIED  
**Next Target**: 2 → 10 real components (9.6%)  
**Approach**: Test backend first, then systematic conversion

## 📋 **Next 8 Components - Priority Order**

### **HIGH PRIORITY (Foundation Components)**

#### **1. EmployeeListContainer.tsx** 🥇
- **Location**: `src/ui/src/modules/employee-management/components/crud/EmployeeListContainer.tsx`
- **Endpoint Needed**: `GET /api/v1/personnel/employees`
- **Service to Create**: `realEmployeeService.ts`
- **Why Critical**: Foundation for many other employee-related components
- **Estimated Time**: 45 minutes
- **Dependencies**: JWT auth (already working)

#### **2. Dashboard.tsx** 🥈  
- **Location**: `src/ui/src/components/Dashboard.tsx`
- **Endpoint Needed**: `GET /api/v1/metrics/dashboard`
- **Service to Create**: Update existing to remove mocks
- **Why Critical**: High visibility, real business metrics
- **Estimated Time**: 30 minutes
- **Dependencies**: JWT auth (already working)

#### **3. ProfileView.tsx** 🥉
- **Location**: `src/ui/src/modules/employee-portal/components/profile/ProfileView.tsx`
- **Endpoint Needed**: `GET /api/v1/profile/me`, `PUT /api/v1/profile/me`
- **Service to Create**: `realProfileService.ts`
- **Why Critical**: Uses authenticated user context from Login.tsx
- **Estimated Time**: 40 minutes
- **Dependencies**: JWT auth (already working)

### **MEDIUM PRIORITY (Business Value)**

#### **4. RequestList.tsx**
- **Location**: `src/ui/src/modules/employee-portal/components/requests/RequestList.tsx`
- **Endpoint Needed**: `GET /api/v1/requests/my`
- **Service to Create**: Extend `realRequestService.ts`
- **Why Important**: Pairs with working RequestForm.tsx
- **Estimated Time**: 35 minutes
- **Dependencies**: JWT auth + RequestForm pattern

#### **5. OperationalControlDashboard.tsx**
- **Location**: `src/ui/src/modules/real-time-monitoring/components/OperationalControlDashboard.tsx`
- **Endpoint Needed**: `GET /api/v1/monitoring/operational`
- **Service to Create**: `realMonitoringService.ts`
- **Why Important**: Real-time business monitoring
- **Estimated Time**: 50 minutes
- **Dependencies**: JWT auth + real-time updates

#### **6. ScheduleGridContainer.tsx**
- **Location**: `src/ui/src/modules/schedule-grid-system/components/ScheduleGridContainer.tsx`
- **Endpoint Needed**: `GET /api/v1/schedules/current`
- **Service to Create**: `realScheduleService.ts`
- **Why Important**: Core WFM functionality
- **Estimated Time**: 60 minutes
- **Dependencies**: JWT auth + complex data structures

### **LOWER PRIORITY (Analytics & Reports)**

#### **7. ReportsPortal.tsx**
- **Location**: `src/ui/src/modules/reports-analytics/components/ReportsPortal.tsx`
- **Endpoint Needed**: `GET /api/v1/reports/list`
- **Service to Create**: `realReportsService.ts`
- **Why Useful**: Business intelligence value
- **Estimated Time**: 40 minutes
- **Dependencies**: JWT auth + report generation

#### **8. ExportManager.tsx**
- **Location**: Search needed - likely in shared components
- **Endpoint Needed**: `POST /api/v1/exports/create`
- **Service to Create**: `realExportService.ts`
- **Why Useful**: Data export functionality
- **Estimated Time**: 45 minutes
- **Dependencies**: JWT auth + file handling

## 🔧 **API Server Startup Instructions**

### **Primary Method**
```bash
cd /Users/m/Documents/wfm/main/project
python main.py
```

**Expected Output**:
```
🚀 Starting WFM Multi-Agent Intelligence Framework
📊 BDD Coverage: 60% (14 files complete)
🔧 Endpoints: 580+ working endpoints
🌐 Documentation: http://localhost:8000/docs
💚 Health Check: http://localhost:8000/health
```

### **Alternative Method**
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### **Verification Commands**
```bash
curl -X GET http://localhost:8000/health
curl -X GET http://localhost:8000/docs
```

## 📊 **Required Endpoints Status**

### ✅ **WORKING (Verified)**
- `POST /api/v1/requests/vacation` - RequestForm.tsx ready
- `POST /api/v1/auth/login` - Login.tsx ready
- `GET /api/v1/auth/verify` - Login.tsx ready  
- `POST /api/v1/auth/logout` - Login.tsx ready
- `GET /api/v1/health` - Both components ready

### ⚠️ **NEEDED (Must Verify)**
- `GET /api/v1/personnel/employees` - EmployeeListContainer
- `GET /api/v1/metrics/dashboard` - Dashboard
- `GET /api/v1/profile/me` - ProfileView
- `GET /api/v1/requests/my` - RequestList
- `GET /api/v1/monitoring/operational` - OperationalControl
- `GET /api/v1/schedules/current` - ScheduleGrid
- `GET /api/v1/reports/list` - ReportsPortal
- `POST /api/v1/exports/create` - ExportManager

## 🎯 **Session Success Metrics**

### **Minimum Success** (2 → 4 components)
- Test RequestForm.tsx with real backend ✅
- Test Login.tsx with real backend ✅
- Convert EmployeeListContainer.tsx
- Convert Dashboard.tsx

### **Good Success** (2 → 6 components)
- Above + ProfileView.tsx
- Above + RequestList.tsx

### **Excellent Success** (2 → 8-10 components)
- Above + OperationalControlDashboard.tsx
- Above + ScheduleGridContainer.tsx
- Above + ReportsPortal.tsx
- Above + ExportManager.tsx

## 🏆 **Truth Keeper Commitments**

### **Honest Progress Reporting**
- Only count components that work end-to-end with backend
- Distinguish "service ready" from "fully working"
- Document blockers and missing endpoints
- Update COMPONENT_CONVERSION_TRACKER.md accurately

### **Quality Standards**
- Real API calls (no mock fallbacks)
- Proper error handling
- Real user value delivery
- Backend integration testing

### **Documentation Requirements**
- Update progress tracker after each component
- Note which endpoints work vs need implementation
- Document learnings and patterns
- Maintain handoff documentation

---

**NEXT SESSION PRIORITY**: Start API server → Test 2 existing components → Convert 8 new components systematically

**TRUTH KEEPER STANDARD**: Real functionality > inflated numbers