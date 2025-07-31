# R4-IntegrationGateway: Clean API Documentation

**Date**: 2025-07-29  
**Agent**: R4-IntegrationGateway  
**Format**: Following R0's structured API documentation format  

## 🔐 ADMIN AUTHENTICATION

### Login to Argus Admin Portal
```http
POST /ccwfm/j_security_check
Content-Type: application/x-www-form-urlencoded

j_username=Konstantin&j_password=12345

# Response
HTTP/1.1 302 Found
Location: /ccwfm/views/env/home/HomeView.xhtml
Set-Cookie: JSESSIONID=ABC123...
```

## 📡 EXTERNAL SYSTEM INTEGRATION

### 1C ZUP Personnel Sync
```http
GET /services/personnel/agents/{startDate}/{endDate}
Host: 192.168.45.162:8090
Authorization: Basic a29uc3RhbnRpbjoxMjM0NQ==
Content-Type: application/json
Accept: application/json

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "agents": [
    {
      "agent_id": "12345",
      "tab_number": "67890", 
      "lastname": "Иванов",
      "firstname": "Иван",
      "secondname": "Иванович",
      "start_work": "2023-01-15",
      "position_id": "POS001",
      "department_id": "DEPT001"
    }
  ]
}
```

### Send Schedule to 1C ZUP
```http
POST /services/personnel/sendSchedule
Host: 192.168.45.162:8090
Authorization: Basic a29uc3RhbnRpbjoxMjM0NQ==
Content-Type: application/json

{
  "period_start": "2025-08-01",
  "period_end": "2025-08-31", 
  "schedules": [
    {
      "employee_id": "12345",
      "shifts": [
        {
          "date": "2025-08-01",
          "start_time": "09:00",
          "end_time": "18:00",
          "break_minutes": 60
        }
      ]
    }
  ]
}

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "processed": 1,
  "errors": []
}
```

### Get Work Time Norms
```http
GET /services/personnel/getNormHours
Host: 192.168.45.162:8090
Authorization: Basic a29uc3RhbnRpbjoxMjM0NQ==
Content-Type: application/json

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "norm_hours": {
    "weekly": 40,
    "monthly": 160,
    "annual": 1920
  }
}
```

### Send Actual Work Time
```http
POST /services/personnel/sendFactWorkTime
Host: 192.168.45.162:8090
Authorization: Basic a29uc3RhbnRpbjoxMjM0NQ==
Content-Type: application/json

{
  "period": "2025-07",
  "timesheet": [
    {
      "employee_id": "12345",
      "date": "2025-07-01",
      "hours_worked": 8.0,
      "overtime": 0.0
    }
  ]
}

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "accepted",
  "timesheet_id": "TS202507001"
}
```

### Get Time Type Information
```http
GET /services/personnel/getTimetypeInfo/{timeTypeId}
Host: 192.168.45.162:8090
Authorization: Basic a29uc3RhbnRpbjoxMjM0NQ==

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "time_type_id": "WORK",
  "description": "Рабочее время",
  "coefficient": 1.0,
  "is_overtime": false
}
```

## 📞 MCE/OKTELL INTEGRATION

### WebSocket Agent Status
```http
GET /ws/agent-status
Host: 192.168.45.162:8090
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==

# WebSocket Messages
{
  "type": "agent_status",
  "agent_id": "AGT001", 
  "status": "online",
  "timestamp": "2025-07-29T10:30:00Z"
}
```

### REST Fallback for Agents
```http
GET /api/v1/agents
Host: 192.168.45.162:8090
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "agents": [
    {
      "id": "AGT001",
      "name": "Operator1",
      "status": "online",
      "last_activity": "2025-07-29T10:30:00Z"
    }
  ]
}
```

## 🔄 INTEGRATION QUEUE MANAGEMENT

### Get Queue Status
```http
GET /ccwfm/api/integration/queue/status
Authorization: Bearer session_token
Content-Type: application/json

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "pending": 3,
  "processing": 1, 
  "failed": 0,
  "operations": [
    {
      "id": "OP001",
      "type": "personnel_sync",
      "status": "pending",
      "priority": 2,
      "created_at": "2025-07-29T10:00:00Z"
    }
  ]
}
```

### Queue Operation
```http
POST /ccwfm/api/integration/queue/operations
Authorization: Bearer session_token
Content-Type: application/json

{
  "operation_type": "personnel_sync",
  "priority": 2,
  "operation_data": {
    "start_date": "2025-07-01",
    "end_date": "2025-07-31"
  }
}

# Response
HTTP/1.1 201 Created
Content-Type: application/json

{
  "operation_id": "OP002",
  "status": "queued",
  "estimated_start": "2025-07-29T10:35:00Z"
}
```

## 📊 HEALTH MONITORING

### Integration Health Check
```http
GET /ccwfm/api/integration/health
Authorization: Bearer session_token

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "healthy",
  "checks": {
    "external_api": {
      "status": "healthy",
      "response_time": "150ms"
    },
    "queue": {
      "status": "healthy", 
      "pending": 3,
      "processing": 1
    },
    "database": {
      "status": "healthy"
    }
  },
  "timestamp": "2025-07-29T10:30:00Z"
}
```

### API Call Metrics
```http
GET /ccwfm/api/integration/metrics
Authorization: Bearer session_token

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "endpoints": {
    "GET /services/personnel/agents": {
      "success": 45,
      "failed": 2
    }
  },
  "performance": {
    "avg_duration": "245ms",
    "p95_duration": "580ms"
  }
}
```

---

**R4-IntegrationGateway**  
*Clean API documentation following R0's format*