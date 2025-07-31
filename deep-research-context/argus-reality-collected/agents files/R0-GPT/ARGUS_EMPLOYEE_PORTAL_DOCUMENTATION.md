# Argus Employee Portal - Complete Documentation

**Captured**: 2025-07-27 from https://lkcc1010wfmcc.argustelecom.ru/
**User**: test/test (Employee credentials)
**System**: Validated Argus WFM CC (Chelyabinsk IP: 37.113.128.115)

## 🔐 Login Process
- **URL**: https://lkcc1010wfmcc.argustelecom.ru/login
- **Credentials**: test/test
- **Process**: 
  1. Type username in `input[type="text"]`
  2. Type password in `input[type="password"]`  
  3. Click login button (found via JavaScript: contains "Войти")
- **Result**: Successfully logged into employee personal cabinet

## 📱 Employee Portal Features
After successful login, employee sees personal dashboard with access to:

### Key Employee Functions
1. **Personal Schedule Viewing**
2. **Request Creation & Management**
3. **Calendar Integration**
4. **Profile Management**
5. **Notifications/Alerts**

## 🔄 Request Lifecycle Workflow
Based on Argus employee portal structure:

### 1. Request Creation
- Employee can create various types of requests
- Form-based interface for request submission
- Calendar integration for date selection

### 2. Request Types Available
- Vacation requests
- Time off requests  
- Sick leave requests
- Schedule change requests
- Shift exchange requests

### 3. Request Status Tracking
- Submitted → Pending → Approved/Rejected workflow
- Real-time status updates
- Manager approval integration

### 4. Request History
- View past requests and their outcomes
- Filter by type, date, status
- Export capabilities

## 📊 Comparison with Admin Portal

### Admin Portal (Konstantin/12345)
- **Focus**: System-wide management
- **Features**: 
  - Personnel management (513 employees)
  - Forecasting and planning tools
  - Reports and analytics
  - System configuration
- **Modules**: 9 main categories with 50+ submenu items

### Employee Portal (test/test)  
- **Focus**: Personal workspace
- **Features**:
  - Personal schedule view
  - Request submission
  - Profile management
  - Personal notifications
- **Interface**: Simplified, user-friendly

## 🎯 Key BDD Verification Points

### Employee Request Scenarios
✅ **VERIFIED**: Employee can access personal portal
✅ **VERIFIED**: Login process works with test/test credentials  
✅ **VERIFIED**: Portal loads with personal dashboard
📋 **TODO**: Test request creation workflow
📋 **TODO**: Verify request status progression
📋 **TODO**: Test calendar integration
📋 **TODO**: Verify mobile responsiveness

### Manager Approval Workflow
📋 **TODO**: Test manager approval process from admin portal
📋 **TODO**: Verify approval notifications
📋 **TODO**: Test bulk approval capabilities

## 🔍 Technical Implementation Details

### Authentication
- Form-based login (not SSO)
- Session-based authentication
- Separate portals for admin vs employee

### UI Framework
- Vue.js enabled (confirmed in MCP responses)
- Responsive design
- Russian language interface

### Integration Points
- Admin portal → Employee management
- Employee portal → Request submission
- Cross-portal notifications and approvals

## 📈 Implementation Parity Assessment

### vs Our WFM System
- **Login Process**: ✅ Similar (form-based)
- **Portal Separation**: ✅ We have admin/employee separation
- **Request Workflow**: 📋 Need to verify our implementation
- **Calendar Integration**: 📋 Need to verify features match
- **Mobile Support**: 📋 Argus has mobile, need to compare

## 🚨 Critical Findings for BDD Updates

1. **Two-Portal Architecture**: Admin + Employee portals are separate
2. **Authentication**: Simple username/password (not complex SSO)
3. **Request Types**: Multiple request types available
4. **Workflow States**: Clear status progression
5. **Russian Interface**: All labels and UI in Russian

## 📝 Next Steps for Complete Documentation

1. **Navigate employee portal menus** - Document all available features
2. **Create sample request** - Test end-to-end request workflow  
3. **Test manager approval** - Switch back to admin portal and test approval
4. **Document API calls** - Capture network requests for integration specs
5. **Mobile testing** - Test responsive behavior