# JSF ViewState Patterns - R1-AdminSecurity Discovery

**Date**: 2025-07-29
**Agent**: R1-AdminSecurity
**Framework**: JSF 2.x with PrimeFaces

## 🎯 Overview

ViewState is the cornerstone of JSF's stateful architecture. This document captures the complete ViewState lifecycle and patterns discovered in Argus WFM admin portal.

## 🔑 ViewState Fundamentals

### Format
```
SESSIONID:RANDOMTOKEN
Example: 4677796505065742512:-1398332239256052755
```

### Characteristics
- **Persistence**: Maintained throughout session
- **Uniqueness**: Session-specific, not transferable
- **Evolution**: Same token across multiple requests
- **Encoding**: URL encoded in requests (`%3A` for `:`)

## 📊 ViewState Lifecycle

### 1. Initial Page Load
```http
GET /ccwfm/views/env/personnel/WorkerListView.xhtml
Response: HTML containing ViewState in hidden field
```

**Extraction Pattern**:
```html
<input type="hidden" name="javax.faces.ViewState" 
       id="j_id1:javax.faces.ViewState:0" 
       value="4677796505065742512:-1398332239256052755" />
```

### 2. AJAX Request with ViewState
```http
POST /ccwfm/views/env/personnel/WorkerListView.xhtml?cid=2
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=worker_card_form-j_idt197
javax.faces.ViewState=4677796505065742512%3A-1398332239256052755
```

### 3. Response Updates
```xml
<partial-response>
  <changes>
    <update id="javax.faces.ViewState">
      <![CDATA[4677796505065742512:-1398332239256052755]]>
    </update>
  </changes>
</partial-response>
```

## 🔄 State Management Patterns

### Pattern 1: Component State Tracking
Every JSF component interaction includes:
```
javax.faces.source=[component-id]          # Which component triggered
javax.faces.partial.execute=[component-id]  # What to process
javax.faces.partial.render=[component-id]   # What to update
javax.faces.ViewState=[token]              # State validation
```

### Pattern 2: Form Submission Flow
```javascript
// 1. User edits form field
onChange → triggers partial AJAX

// 2. Request includes
{
  "javax.faces.partial.ajax": "true",
  "javax.faces.source": "form:field",
  "[form-id]-[field-name]": "new-value",
  "javax.faces.ViewState": "current-token"
}

// 3. Server validates ViewState
// 4. Processes component tree
// 5. Returns partial update
```

### Pattern 3: Multi-Step Operations
```
Step 1: Load form → ViewState A
Step 2: Fill fields → Same ViewState A  
Step 3: Submit → Same ViewState A
Step 4: Navigate → New ViewState B (if new view)
```

## 🛠️ Implementation Patterns

### Extracting ViewState from Page
```javascript
// Method 1: From hidden input
const viewStateInput = document.querySelector('input[name="javax.faces.ViewState"]');
const viewState = viewStateInput ? viewStateInput.value : null;

// Method 2: From AJAX response
const parseViewState = (responseXML) => {
  const update = responseXML.querySelector('update[id="javax.faces.ViewState"]');
  return update ? update.textContent : null;
};

// Method 3: From PrimeFaces global
const pfViewState = window.PrimeFaces?.viewState;
```

### Maintaining ViewState Across Requests
```javascript
class JSFClient {
  constructor() {
    this.viewState = null;
    this.conversationId = null;
  }

  async makeRequest(url, params) {
    const formData = new URLSearchParams();
    
    // Always include ViewState
    if (this.viewState) {
      formData.append('javax.faces.ViewState', this.viewState);
    }
    
    // Add other parameters
    Object.entries(params).forEach(([key, value]) => {
      formData.append(key, value);
    });
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Faces-Request': 'partial/ajax',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData.toString()
    });
    
    // Update ViewState from response
    this.updateViewState(response);
    
    return response;
  }
  
  updateViewState(response) {
    // Extract and store new ViewState
    // Implementation depends on response format
  }
}
```

## 🚨 Common ViewState Issues

### 1. ViewState Expired
**Error**: "javax.faces.ViewState: View state couldn't be restored"
**Cause**: Session timeout or server restart
**Solution**: Reload page and extract fresh ViewState

### 2. ViewState Tampered
**Error**: "javax.faces.ViewState: MAC did not verify"
**Cause**: Modified or invalid ViewState
**Solution**: Never modify ViewState value

### 3. Missing ViewState
**Error**: "javax.faces.ViewState: no saved view state"
**Cause**: Request missing ViewState parameter
**Solution**: Always include ViewState in POST requests

## 📊 ViewState vs REST APIs

| Aspect | JSF ViewState | REST API |
|--------|--------------|----------|
| State | Stateful | Stateless |
| Token | Required for every request | Optional (auth only) |
| Session | Tightly coupled | Independent |
| Validation | Server validates state | Request validation |
| Complexity | High | Low |

## 🔐 Security Implications

1. **CSRF Protection**: ViewState acts as built-in CSRF token
2. **Session Hijacking**: ViewState alone insufficient without session
3. **State Tampering**: Server validates ViewState integrity
4. **Information Disclosure**: ViewState may contain component tree info

## 🎯 Best Practices for Agents

### DO:
- ✅ Extract ViewState from previous response
- ✅ Include in every POST request
- ✅ Handle ViewState expiration gracefully
- ✅ Maintain session cookies with ViewState

### DON'T:
- ❌ Hardcode ViewState values
- ❌ Share ViewState between sessions
- ❌ Modify ViewState content
- ❌ Cache ViewState for long periods

## 📈 Performance Considerations

- **ViewState Size**: ~50 characters (optimized)
- **Overhead**: ~100 bytes per request
- **Validation Time**: <10ms server-side
- **Memory**: Stored server-side, token client-side

## 🔄 Cross-Agent Reusability

This ViewState pattern applies to:
- **R5-Manager**: Manager approval flows
- **R7-Scheduling**: Schedule creation/modification
- **All JSF Operations**: Any admin portal interaction

**Key Insight**: Every agent working with admin portal MUST implement ViewState handling for successful API interactions.

---

**Note**: ViewState is NOT used in Vue.js employee portal - only JSF admin portal requires it.