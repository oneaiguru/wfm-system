# WFM Enterprise Authentication System Documentation

## 🔐 Complete Authentication & Authorization Framework

### System Overview

The WFM Enterprise API implements a comprehensive authentication and authorization system with:

- **JWT & OAuth2 Support**: Multiple authentication flows
- **Role-Based Access Control (RBAC)**: Fine-grained permissions
- **Rate Limiting**: Advanced multi-strategy rate limiting
- **Multi-tenancy**: Organization and department isolation
- **External Providers**: Google, Microsoft, Okta integration
- **API Keys**: Service-to-service authentication
- **Performance Optimized**: Redis caching, <100ms latency

---

## 🚀 Quick Start Guide

### 1. Basic Authentication

```bash
# Login with username/password
curl -X POST "/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe@company.com",
    "password": "SecurePass123!",
    "remember_me": false
  }'

# Response
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "scope": "read write"
}
```

### 2. Using Access Tokens

```bash
# Authenticated API call
curl -X GET "/api/v1/employees" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3. Token Refresh

```bash
# Refresh expired access token
curl -X POST "/api/v1/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

---

## 🔑 Authentication Endpoints

### Core Authentication

| Endpoint | Method | Description | Rate Limit |
|----------|---------|-------------|------------|
| `/api/v1/auth/login` | POST | User login | 5/min |
| `/api/v1/auth/token` | POST | OAuth2 token (OpenAPI compatible) | 10/min |
| `/api/v1/auth/refresh` | POST | Refresh access token | 100/min |
| `/api/v1/auth/logout` | POST | Logout user | 100/min |
| `/api/v1/auth/revoke` | POST | Revoke token | 100/min |
| `/api/v1/auth/me` | GET | Get current user info | 100/min |

### User Management

| Endpoint | Method | Description | Rate Limit |
|----------|---------|-------------|------------|
| `/api/v1/auth/register` | POST | Register new user | 3/5min |
| `/api/v1/auth/password-reset` | POST | Request password reset | 3/hour |
| `/api/v1/auth/password-reset/confirm` | POST | Confirm password reset | 3/hour |

### OAuth2 Flows

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/api/v1/auth/authorize` | GET | Authorization code flow |
| `/api/v1/auth/token/oauth2` | POST | OAuth2 token exchange |
| `/api/v1/auth/oauth2/{provider}/authorize` | GET | External provider auth |
| `/api/v1/auth/oauth2/{provider}/callback` | POST | External provider callback |

### API Key Management

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/api/v1/auth/api-keys` | POST | Create API key |
| `/api/v1/auth/api-keys` | GET | List user's API keys |
| `/api/v1/auth/api-keys/{key_id}` | DELETE | Revoke API key |

---

## 👥 Role-Based Access Control (RBAC)

### Permission System

Permissions follow the format: `{resource}.{action}`

#### Core Permissions

```
# User Management
users.read           # Read user information
users.write          # Create/update users
users.delete         # Delete users
users.admin          # Full user administration

# Schedule Management
schedules.read       # Read schedules
schedules.write      # Create/update schedules
schedules.delete     # Delete schedules
schedules.publish    # Publish schedules
schedules.optimize   # Optimize schedules

# Employee Management
employees.read       # Read employee data
employees.write      # Create/update employees
employees.delete     # Delete employees
employees.skills     # Manage employee skills

# Forecasting
forecasts.read       # Read forecasts
forecasts.write      # Create/update forecasts
forecasts.generate   # Generate forecasts

# Reporting
reports.read         # Read reports
reports.generate     # Generate reports
reports.schedule     # Schedule reports

# System Administration
system.read          # Read system info
system.config        # Configure system
system.logs          # Access system logs
```

### Default Roles

#### Employee Role
- `schedules.read`
- `employees.read` (own data)
- `requests.write`
- `attendance.write`

#### Supervisor Role
- All Employee permissions
- `schedules.write`
- `employees.write` (team members)
- `requests.approve`
- `attendance.approve`
- `reports.read`

#### Manager Role
- All Supervisor permissions
- `schedules.publish`
- `employees.skills`
- `forecasts.read`
- `forecasts.write`
- `reports.generate`

#### Planner Role
- `schedules.optimize`
- `forecasts.generate`
- `reports.generate`

#### Admin Role
- `users.admin`
- `system.config`
- `integrations.write`
- `api.admin`

### RBAC Endpoints

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/api/v1/rbac/permissions` | GET | List all permissions |
| `/api/v1/rbac/permissions` | POST | Create permission |
| `/api/v1/rbac/roles` | GET | List all roles |
| `/api/v1/rbac/roles` | POST | Create role |
| `/api/v1/rbac/users/{user_id}/roles` | POST | Assign roles to user |
| `/api/v1/rbac/users/{user_id}/permissions` | GET | Get user permissions |
| `/api/v1/rbac/check-permission` | GET | Check user permission |

---

## 🛡️ Rate Limiting

### Rate Limiting Strategies

1. **Fixed Window**: Simple counter per time window
2. **Sliding Window**: Precise rate limiting with Redis sorted sets
3. **Token Bucket**: Burst capacity with refill rate
4. **Leaky Bucket**: Smooth rate limiting

### Default Rate Limits

| User Type | Requests/Min | Strategy |
|-----------|--------------|----------|
| Guest | 20 | Fixed Window |
| Regular User | 100 | Sliding Window |
| Admin | 1000 | Sliding Window |
| Service Account | 10000 | Token Bucket |

### Endpoint-Specific Limits

```python
# Authentication endpoints
/api/v1/auth/login          # 5 requests/min
/api/v1/auth/register       # 3 requests/5min
/api/v1/auth/password-reset # 3 requests/hour

# Bulk operations
/api/v1/*/bulk              # 5 requests/5min (cost: 5)

# Report generation
/api/v1/reports/generate    # 10 requests/5min (cost: 3)
```

### Rate Limit Headers

All responses include rate limit headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642780800
Retry-After: 60  # Only on 429 responses
```

---

## 🔧 Configuration

### Environment Variables

```bash
# JWT Configuration
JWT_SECRET_KEY=your-secret-key-change-in-production
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# Redis Configuration
REDIS_URL=redis://localhost:6379

# OAuth2 Providers
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
MICROSOFT_CLIENT_ID=your-microsoft-client-id
MICROSOFT_CLIENT_SECRET=your-microsoft-client-secret
OKTA_DOMAIN=your-okta-domain
OKTA_CLIENT_ID=your-okta-client-id
OKTA_CLIENT_SECRET=your-okta-client-secret
```

### Database Setup

```sql
-- Create default permissions and roles
INSERT INTO permissions (name, description, resource, action) VALUES 
('users.read', 'Read user information', 'users', 'read'),
('users.write', 'Create and update users', 'users', 'write'),
-- ... more permissions

INSERT INTO roles (name, description) VALUES 
('employee', 'Regular employee'),
('supervisor', 'Team supervisor'),
('manager', 'Department manager'),
('admin', 'System administrator');

-- Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id) 
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'employee' AND p.name IN ('schedules.read', 'employees.read');
```

---

## 🔌 Integration Examples

### FastAPI Dependency Usage

```python
from fastapi import Depends, APIRouter
from api.auth.dependencies import (
    get_current_user, 
    require_permissions,
    require_roles
)

router = APIRouter()

@router.get("/protected")
async def protected_endpoint(
    current_user: User = Depends(get_current_user)
):
    return {"user": current_user.username}

@router.post("/schedules")
async def create_schedule(
    schedule_data: ScheduleCreate,
    current_user: User = Depends(require_permissions(["schedules.write"]))
):
    # Only users with schedules.write permission can access
    return {"message": "Schedule created"}

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    current_user: User = Depends(require_roles(["admin", "superuser"]))
):
    # Only admins and superusers can delete users
    return {"message": "User deleted"}
```

### Custom Permission Checks

```python
from api.auth.dependencies import get_user_permissions

@router.get("/custom-check")
async def custom_permission_check(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_permissions = await get_user_permissions(current_user)
    
    if "schedules.optimize" in user_permissions:
        # User can optimize schedules
        return {"can_optimize": True}
    else:
        return {"can_optimize": False}
```

### Multi-tenant Access Control

```python
from api.auth.dependencies import organization_access_required

@router.get("/organizations/{org_id}/employees")
async def get_org_employees(
    org_id: str,
    current_user: User = Depends(organization_access_required(
        allow_admin=True,
        allow_cross_org=False
    ))
):
    # Only users from the same organization can access
    return {"employees": []}
```

---

## 📊 Security Features

### Token Security

- **JWT Signatures**: HS256 algorithm with secret key
- **Token Expiration**: Short-lived access tokens (30 min)
- **Refresh Tokens**: Longer-lived (7 days) with rotation
- **Token Revocation**: Blacklist support with Redis
- **JTI Claims**: Unique token identifiers for tracking

### Password Security

- **Bcrypt Hashing**: Secure password storage
- **Password Complexity**: Minimum 8 chars, mixed case, numbers
- **Reset Tokens**: Time-limited password reset tokens
- **Brute Force Protection**: Rate limiting on auth endpoints

### API Security

- **CORS Configuration**: Proper cross-origin handling
- **Request Validation**: Pydantic model validation
- **SQL Injection Prevention**: SQLAlchemy ORM protection
- **XSS Protection**: JSON-only responses
- **HTTPS Only**: SSL/TLS encryption required

---

## 🔍 Monitoring & Logging

### Security Events

All authentication events are logged:

```python
# Login attempts
{
    "event": "login_attempt",
    "user": "john.doe@company.com",
    "ip": "192.168.1.100",
    "success": true,
    "timestamp": "2025-01-11T10:30:00Z"
}

# Permission checks
{
    "event": "permission_check",
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "permission": "schedules.write",
    "resource": "schedule_123",
    "allowed": true,
    "timestamp": "2025-01-11T10:30:00Z"
}
```

### Metrics

- **Authentication Success Rate**: % of successful logins
- **Token Refresh Rate**: Frequency of token refreshes
- **Permission Denials**: Rate of access denials
- **Rate Limit Hits**: Rate limiting effectiveness
- **API Key Usage**: Service account activity

### Alerts

- **Failed Login Attempts**: Multiple failures from same IP
- **Token Anomalies**: Unusual token patterns
- **Permission Escalation**: Privilege escalation attempts
- **Rate Limit Breaches**: Sustained high request rates

---

## 🚨 Error Handling

### Authentication Errors

```json
{
  "error": "authentication_required",
  "message": "Valid authentication token required",
  "code": 401
}

{
  "error": "token_expired",
  "message": "Token has expired",
  "code": 401
}

{
  "error": "invalid_credentials",
  "message": "Username or password is incorrect",
  "code": 401
}
```

### Authorization Errors

```json
{
  "error": "insufficient_permissions",
  "message": "Missing required permission: schedules.write",
  "code": 403
}

{
  "error": "organization_access_denied",
  "message": "Access denied: organization mismatch",
  "code": 403
}
```

### Rate Limiting Errors

```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Try again in 60 seconds.",
  "limit": 100,
  "remaining": 0,
  "reset": 1642780800,
  "code": 429
}
```

---

## 🔄 Migration Guide

### From Basic Auth to JWT

1. **Install Dependencies**
```bash
pip install python-jose[cryptography] passlib[bcrypt] redis
```

2. **Update Middleware**
```python
from api.middleware.rate_limiter import RateLimitMiddleware

app.add_middleware(RateLimitMiddleware, redis_url="redis://localhost:6379")
```

3. **Add Auth Routes**
```python
from api.v1.endpoints.auth import router as auth_router
from api.v1.endpoints.rbac import router as rbac_router

app.include_router(auth_router, prefix="/api/v1")
app.include_router(rbac_router, prefix="/api/v1")
```

4. **Update Dependencies**
```python
# Old
def get_current_user(token: str = Depends(oauth2_scheme)):
    # Basic validation
    return user

# New
from api.auth.dependencies import get_current_user, require_permissions

@router.get("/protected")
async def protected(current_user: User = Depends(get_current_user)):
    return {"user": current_user}
```

---

## 🎯 Best Practices

### Security Best Practices

1. **Use HTTPS Only**: Never transmit tokens over HTTP
2. **Rotate Secrets**: Regularly rotate JWT secrets
3. **Short Token Lifetimes**: Use short-lived access tokens
4. **Secure Storage**: Store refresh tokens securely
5. **Monitor Anomalies**: Track unusual authentication patterns

### Performance Best Practices

1. **Cache Permissions**: Use Redis for permission caching
2. **Optimize Queries**: Use eager loading for roles/permissions
3. **Connection Pooling**: Use connection pools for Redis
4. **Async Operations**: Use async/await for all I/O operations
5. **Batch Operations**: Batch permission checks when possible

### Development Best Practices

1. **Test Coverage**: Write comprehensive auth tests
2. **Documentation**: Keep API documentation updated
3. **Error Handling**: Provide clear error messages
4. **Logging**: Log all security events
5. **Monitoring**: Set up alerts for auth failures

---

## 📖 API Reference

Complete OpenAPI documentation available at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

### Authentication Schemas

See `/api/v1/schemas/auth.py` for complete Pydantic models:

- `TokenResponse`: JWT token response
- `UserResponse`: User information
- `RoleResponse`: Role with permissions
- `PermissionResponse`: Permission details
- `OAuth2TokenRequest`: OAuth2 token request
- `APIKeyResponse`: API key information

---

## 🛠️ Troubleshooting

### Common Issues

1. **Token Validation Errors**
   - Check JWT secret key configuration
   - Verify token format and expiration
   - Ensure Redis is running for blacklist checks

2. **Permission Denied**
   - Verify user has required permissions
   - Check role assignments
   - Validate organization/department access

3. **Rate Limiting Issues**
   - Check Redis connection
   - Verify rate limit configuration
   - Monitor request patterns

4. **OAuth2 Integration**
   - Verify provider credentials
   - Check redirect URI configuration
   - Validate scope permissions

### Debug Commands

```bash
# Check Redis connection
redis-cli ping

# Verify JWT tokens
python -c "
import jwt
token = 'your-jwt-token-here'
print(jwt.decode(token, options={'verify_signature': False}))
"

# Check rate limits
redis-cli get rate_limit:sliding:user:123:/api/v1/auth/login
```

---

## 📞 Support

For authentication system support:

1. **Documentation**: This guide and inline code docs
2. **API Reference**: OpenAPI documentation
3. **Error Logs**: Check application logs for details
4. **Performance**: Monitor Redis and database performance
5. **Security**: Review security event logs

---

*Last Updated: January 11, 2025*  
*Version: 1.0.0*  
*API Version: v1*