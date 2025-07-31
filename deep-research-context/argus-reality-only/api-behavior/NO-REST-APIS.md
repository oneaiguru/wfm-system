# ❌ CRITICAL: Argus Has NO REST APIs

## The Reality

Argus is a **JSF/PrimeFaces application** that does NOT use REST APIs. All the `/api/v1/*` endpoints in our documentation are for our new system, not Argus.

## What Argus Actually Uses

### JSF POST Requests
- All interactions use POST to `.xhtml` URLs
- Include `javax.faces.ViewState` parameter
- Session-based state management

### PrimeFaces AJAX
```javascript
// Actual Argus pattern:
PrimeFaces.ab({
  s: "form:button",
  e: "click", 
  p: "form:button",
  u: "form:panel"
});
```

### Example Real Request
```
POST /ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.ViewState=stateless&
javax.faces.source=form:refreshButton&
javax.faces.partial.ajax=true
```

## What This Means

1. **No JSON APIs** - Argus uses form-encoded data
2. **No REST endpoints** - Everything is JSF lifecycle
3. **No /api/v1/** - These are OUR planned endpoints
4. **Session-based** - 22-minute timeout, ViewState required

## For Domain Packages

Domain packages should NOT include any REST API references. Only document the JSF/PrimeFaces patterns that actually exist.