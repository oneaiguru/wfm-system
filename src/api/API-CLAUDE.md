# API-CLAUDE.md - API Architecture Documentation

## Current Status
- **Total Endpoints**: 237 REST endpoints
- **WebSocket Events**: 67 event types
- **Authentication**: JWT, OAuth2, API Keys
- **API Version**: v1 (stable)

## Endpoint Inventory

### REST Endpoints by Category

#### Authentication & Authorization
```
/api/v1/auth/
├── /token              # JWT token generation
├── /refresh            # Token refresh
├── /oauth2/*           # OAuth2 flows (Google, Microsoft, Okta)
├── /api-key/*          # API key management
└── /rbac/*             # Role-based access control
```

#### Argus Compatibility Layer
```
/api/v1/argus/
├── /personnel/*        # Personnel management (Argus-compatible)
├── /historic/*         # Historical data access
├── /online/*           # Real-time data endpoints
├── /ccwfm/*           # Status and monitoring
├── /enhanced/historic/* # Enhanced historical endpoints
└── /enhanced/realtime/* # Enhanced real-time endpoints
```

#### Core Business APIs
```
/api/v1/
├── /personnel/*        # 25 endpoints - Employee management
├── /forecasting/*      # 25 endpoints - ML forecasting
├── /schedules/*        # 35 endpoints - Schedule management
├── /integrations/*     # 25 endpoints - External systems
├── /algorithms/*       # Algorithm execution
├── /workflow/*         # Workflow management
├── /comparison/*       # Competitive analysis
└── /db/*              # Direct database access
```

### WebSocket Implementation
```
Main Endpoint: /api/v1/realtime/ws

Event Categories:
- Forecasting Events (3)
- Schedule Events (44)
- Shift Events (6)
- Real-time Monitoring (3)
- Skill Management (3)
- Vacancy Events (3)
- Algorithm Events (3)
```

## Auth Flow Explanation

### 1. API Key (Simple/Demo)
```python
headers = {"X-API-Key": "demo-admin-key"}
```

### 2. JWT Authentication
```python
# Login
POST /api/v1/auth/token
Body: {"username": "user", "password": "pass"}
Response: {"access_token": "...", "refresh_token": "..."}

# Use token
headers = {"Authorization": "Bearer <access_token>"}
```

### 3. OAuth2 Flows
- Authorization Code (with PKCE)
- Password Flow
- Client Credentials
- Refresh Token

## WebSocket Implementation Status

### Architecture
- Centralized `WebSocketManager` singleton
- Room-based broadcasting
- Event subscription system
- Heartbeat mechanism (30s)
- Auto-reconnection handling

### Connection Example
```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/realtime/ws');
ws.send(JSON.stringify({
  type: 'subscribe',
  events: ['schedule.updated', 'forecast.completed']
}));
```

## Key Commands

### API Server
```bash
# Start API server
cd /project/src/api
uvicorn main:app --reload --port 8000

# Run with production settings
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

# Generate OpenAPI docs
curl http://localhost:8000/api/v1/openapi.json > openapi.json
```

### Testing APIs
```bash
# Health check
curl http://localhost:8000/health

# Test with API key
curl -H "X-API-Key: demo-admin-key" http://localhost:8000/api/v1/personnel/employees

# WebSocket stats
curl http://localhost:8000/api/v1/realtime/ws/stats
```

### Database Queries
```bash
# Direct DB query endpoint
curl -X POST http://localhost:8000/api/v1/db/query \
  -H "X-API-Key: demo-admin-key" \
  -d '{"query": "SELECT * FROM agents LIMIT 10"}'
```

## Next Priorities

1. **Missing Endpoints**
   - Batch schedule operations
   - Advanced reporting APIs
   - Audit log endpoints

2. **WebSocket Enhancements**
   - Implement message queue for reliability
   - Add compression for large payloads
   - Enhanced error recovery

3. **Performance**
   - Implement response caching
   - Add request batching
   - Optimize database connection pooling

## Known Issues

1. **Rate Limiting**: Not fully implemented
2. **API Versioning**: v2 structure not defined
3. **WebSocket Scaling**: Single server limitation
4. **OAuth2**: External providers need configuration

## Quick Navigation

- **Main Entry**: `/project/src/api/main.py`
- **Endpoints**: `/project/src/api/v1/endpoints/`
- **Auth**: `/project/src/api/auth/`
- **Services**: `/project/src/api/services/`
- **WebSocket**: `/project/src/api/websocket/`
- **Models**: `/project/src/api/models/`

## Performance Metrics

- Response timeout: 2 seconds
- Retry attempts: 3
- Connection pool: 100 connections
- WebSocket capacity: 1000 concurrent

## Integration Points

- **Database**: PostgreSQL with AsyncPG
- **Cache**: Redis (configured)
- **Monitoring**: Prometheus metrics
- **Documentation**: Swagger UI at `/api/v1/docs`