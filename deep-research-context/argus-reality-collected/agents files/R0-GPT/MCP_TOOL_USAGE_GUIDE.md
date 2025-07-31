# 🚨 CRITICAL: MCP Tool Usage Guide

## Two Different MCP Servers - USE THE RIGHT ONE!

### 1. For Argus Systems (cc1010wfmcc.argustelecom.ru)
**Tool**: `mcp__playwright-human-behavior__`
- Handles anti-bot measures
- Simulates human-like behavior
- Required for Argus due to security measures

### 2. For Our Localhost System (localhost:3000)
**Tool**: `mcp__playwright-official__`
- Faster, direct automation
- No anti-bot needed
- Use for all localhost testing

## Common Mistake
❌ Using `mcp__playwright-official__` for Argus = 403 Forbidden
✅ Using `mcp__playwright-human-behavior__` for Argus = Access granted

## Example Usage

### Argus Access:
```javascript
// Navigate
await mcp__playwright-human-behavior__navigate({
  url: "https://lkcc1010wfmcc.argustelecom.ru/",
  waitForLoad: true
});

// Type with human-like behavior
await mcp__playwright-human-behavior__type({
  selector: 'input[name="username"]',
  text: "test",
  humanTyping: true,
  clearFirst: true
});

// Click with human behavior
await mcp__playwright-human-behavior__click({
  selector: 'button[type="submit"]',
  humanBehavior: true
});
```

### Localhost Access:
```javascript
// Navigate
await mcp__playwright-official__browser_navigate({
  url: "http://localhost:3000"
});

// Type normally
await mcp__playwright-official__browser_type({
  element: "Username input",
  ref: "[name='username']",
  text: "admin"
});

// Click normally
await mcp__playwright-official__browser_click({
  element: "Login button",
  ref: "[type='submit']"
});
```

## Credentials Reference
- **Argus Employee**: test/test at https://lkcc1010wfmcc.argustelecom.ru/
- **Argus Admin**: Konstantin/12345 at https://cc1010wfmcc.argustelecom.ru/ccwfm/
- **Our System**: admin/password or john.doe/test at http://localhost:3000