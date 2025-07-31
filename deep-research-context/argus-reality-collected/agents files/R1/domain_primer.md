# R1-AdminSecurity Domain Primer

## 🎯 Your Domain: Admin & Security
- **Scenarios**: 85 total (5 demo-critical)
- **Features**: Auth, roles, user management, SSO, audit

## 📊 Domain-Specific Details

### Primary Components
- `Login.tsx` - Authentication
- `UserManagement.tsx` - User CRUD
- `RolesSettings.tsx` - Role management
- `AuditLog.tsx` - Security audit

### Primary APIs
- `/api/v1/auth/*`
- `/api/v1/users/*`
- `/api/v1/roles/*`
- `/api/v1/audit/*`
- `/api/v1/sso/*`

### Known Patterns
- **Pattern 4**: Admin route separation
- **Pattern 9**: Session management (new)
- SSO integration patterns

### Quick Wins (Start Here)
- SPEC-01-001: Basic login (working!)
- SPEC-02-001: SSO login (marked complete)
- SPEC-26-001: View roles list

## 🔄 Dependencies
- **Provides to**: ALL domains (users/auth)
- **Run FIRST on Day 1**

## 💡 Domain Tips
1. You create the foundation for all tests
2. SSO is already working (quick wins!)
3. Focus on edge cases and security
4. Create test users for other domains