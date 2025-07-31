# 📋 Demo Command Documentation Template

**Purpose**: Standard format for proving SPEC functionality

## Required Format for ALL SPECs

```markdown
# SPEC-XX Demo Commands

## 🔍 Prerequisites Tested
D-stage: [✅/❌] psql command and result
I-stage: [✅/❌] curl command and result  
U-stage: [✅/❌] npm/component test result
A-stage: [✅/❌] python algorithm result

## 🚀 My Demo Command
```bash
# Exact command that demonstrates E2E functionality
[command here]
```

## 📊 Actual Output
```
[paste complete output including any errors]
```

## ✅ Success Criteria Met
- [ ] User can complete intended workflow
- [ ] Real data flows through system
- [ ] No mock/placeholder responses
- [ ] Performance < 2 seconds

## 🎯 Status
[WORKING/PARTIAL/BROKEN] - [specific explanation]
```

## Example: SPEC-01 Authentication

```markdown
# SPEC-01 Demo Commands

## 🔍 Prerequisites Tested
D-stage: ✅ users table has test data
I-stage: ✅ /api/v1/auth/login endpoint responds
U-stage: ✅ LoginForm component renders
A-stage: ✅ JWT token generation works

## 🚀 My Demo Command
```bash
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john.doe","password":"password123"}'
```

## 📊 Actual Output
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "john.doe",
    "role": "employee"
  }
}
```

## ✅ Success Criteria Met
- [x] User can complete login workflow
- [x] Real JWT token generated
- [x] No mock responses
- [x] Performance: 94ms

## 🎯 Status
WORKING - Complete authentication E2E flow operational
```

**This template ensures every "complete" claim has executable proof.**