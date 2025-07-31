# Argus Architecture: JSF/PrimeFaces Patterns

## Core Technology Stack

- **Framework**: JavaServer Faces (JSF) 
- **UI Library**: PrimeFaces
- **State Management**: ViewState (server-side)
- **Session Timeout**: 22 minutes
- **Language**: Russian UI

## Common Patterns

### Page Navigation
```
/ccwfm/views/env/[module]/[ViewName].xhtml
```

### AJAX Updates
```javascript
PrimeFaces.ab({
  s: "source_component_id",    // source
  e: "event_type",             // event
  p: "process_component_id",   // process
  u: "update_component_id",    // update
  ps: true                     // partial submit
});
```

### Form Submission
- All forms use POST method
- Include hidden ViewState field
- Character encoding: UTF-8
- Content-Type: application/x-www-form-urlencoded

### Session Management
- ViewState parameter required for all requests
- Session timeout after 22 minutes of inactivity
- ViewExpiredException on expired sessions
- Redirect to login on session expiry

### Component IDs
JSF uses hierarchical component IDs:
- `form:table:0:button` (form > table > row 0 > button)
- IDs generated server-side
- Client-side JavaScript references these IDs

## NOT Used in Argus

- ❌ REST APIs
- ❌ JSON data exchange  
- ❌ React components
- ❌ JWT tokens
- ❌ /api/v1/* endpoints