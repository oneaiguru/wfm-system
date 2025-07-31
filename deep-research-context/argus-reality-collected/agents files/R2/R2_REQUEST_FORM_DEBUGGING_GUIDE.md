# R2 Request Form Debugging Guide - Critical Blocker Resolution

**CRITICAL BLOCKER**: Request form validation persists despite all visible fields completed
**IMPACT**: Blocks 8+ dependent scenarios (core employee self-service functionality)
**STATUS**: Active investigation needed

## 🎯 THE EXACT PROBLEM

### Current State
- **Form loads**: ✅ Calendar → "Создать" button works
- **Fields fill**: ✅ All visible fields can be completed
- **Validation fails**: ❌ "Поле должно быть заполнено" persists
- **Submission blocked**: ❌ Form won't submit

### Known Working Fields
```bash
# These fields can be filled successfully:
#input-181 → "2025-08-15" (date text field)
#input-198 → "Тестовая заявка" (comment textarea) 
#input-245 → "Личные обстоятельства" (reason field)
select → "Заявка на создание отгула" (request type dropdown)
calendar-day → Date 15 clicked (calendar selection)
```

### Persistent Validation Messages
- "Поле должно быть заполнено" (Field must be filled)
- "Заполните дату в календаре" (Fill in date in calendar)

## 🔍 SYSTEMATIC DEBUGGING APPROACH

### Step 1: Admin Portal Comparison (2 hours)
```bash
# Test admin portal request creation for employees
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]

# Find employee request management
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/personnel/request/UserRequestView.xhtml
# Test if admin can create requests FOR employees
```

### Step 2: Alternative User Testing (1 hour)
```bash
# Try different employee credentials
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
mcp__playwright-human-behavior__type → input[type="text"] → "pupkin_vo"
mcp__playwright-human-behavior__type → input[type="password"] → "Balkhash22"
# Test if different user has form submission permissions
```

### Step 3: JavaScript Field Analysis (1 hour)
```bash
# Complete form state analysis
mcp__playwright-human-behavior__execute_javascript → 
`const formState = {
  allInputs: Array.from(document.querySelectorAll('input, textarea, select')).map(el => ({
    id: el.id, type: el.type, value: el.value, required: el.required, 
    valid: el.checkValidity(), validationMessage: el.validationMessage
  })),
  hiddenInputs: Array.from(document.querySelectorAll('input[type="hidden"]')).map(el => ({
    id: el.id, value: el.value, name: el.name
  })),
  formValidation: document.querySelector('form')?.checkValidity() || 'No form element',
  requiredEmpty: Array.from(document.querySelectorAll('[required]')).filter(el => !el.value)
};
return formState;`
```

### Step 4: Date Format Testing (30 minutes)
```bash
# Test Russian date format
mcp__playwright-human-behavior__type → #input-181 → "15.08.2025"
mcp__playwright-human-behavior__click → button:has-text('Добавить')

# Test alternative formats
mcp__playwright-human-behavior__type → #input-181 → "15/08/2025"
mcp__playwright-human-behavior__type → #input-181 → "2025-08-15"
```

### Step 5: Network Monitoring (30 minutes)
```bash
# Monitor API calls during submission attempt
# Use browser dev tools to capture actual requests
# Document backend validation vs frontend validation
```

## 🎯 RESOLUTION PATHWAYS

### Pathway A: Permission Issue
**If admin portal works OR alternative user works**
→ test/test user has insufficient permissions
→ Document permission boundaries
→ Use working user for request scenarios

### Pathway B: Date Synchronization Issue  
**If date format testing resolves validation**
→ Calendar picker and text input not synchronized
→ Document working date format
→ Update all request scenarios with correct format

### Pathway C: Hidden Field Requirements
**If JavaScript analysis reveals missing required fields**
→ Form has invisible validation requirements
→ Document all required fields
→ Update form completion sequence

### Pathway D: Architectural Limitation
**If no resolution found after systematic testing**
→ Employee portal request creation not fully implemented
→ Document limitation honestly
→ Mark dependent scenarios as @architecture-blocked

## 📋 SUCCESS CRITERIA

### Resolution Achieved When:
- [ ] Form submits successfully without validation errors
- [ ] Request appears in "Мои" tab after creation
- [ ] Clear understanding of working user/format/fields
- [ ] 8+ dependent scenarios can proceed

### If Resolution Not Possible:
- [ ] Clear documentation of exact limitation
- [ ] Permission boundaries mapped (which users can/cannot)
- [ ] Alternative workflows documented (admin-side request creation)
- [ ] Honest scenario marking (@blocked vs @user-dependent)

## 🚨 TESTING SEQUENCE (Next Session)

1. **Start here**: Admin portal employee request testing (highest probability)
2. **If admin blocked**: Alternative employee user testing  
3. **If user works**: Document permission matrix, proceed with working user
4. **If all users fail**: JavaScript analysis and hidden field discovery
5. **If technical issue**: Date format and synchronization testing
6. **If all fails**: Document as architectural limitation

**Expected time to resolution**: 2-4 hours of systematic testing

This guide focuses exclusively on resolving THE critical blocker preventing R2 domain completion.