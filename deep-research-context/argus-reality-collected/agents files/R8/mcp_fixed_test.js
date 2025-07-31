#!/usr/bin/env node
// R8: Fixed MCP JSON format for mobile accessibility testing

const { spawn } = require('child_process');

console.log('🎯 R8: Starting fixed MCP mobile accessibility testing...\n');

// Create MCP process
const mcp = spawn('node', ['/Users/m/git/mcp/playwright-human-behavior-mcp.js'], {
  env: {
    ...process.env,
    PLAYWRIGHT_ENHANCED_MODE: 'true',
    PLAYWRIGHT_PROXY_SERVER: 'socks5://127.0.0.1:1080'
  },
  stdio: ['pipe', 'pipe', 'pipe']
});

// BDD Scenario: Mobile Accessibility Testing
const navigationCommand = {
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "navigate",
    "arguments": {
      "url": "https://lkcc1010wfmcc.argustelecom.ru/login",
      "waitForLoad": true
    }
  }
};

console.log('📱 BDD SCENARIO: Mobile accessibility navigation test');
console.log('🔧 MCP COMMAND:', JSON.stringify(navigationCommand, null, 2));

// Send navigation command
mcp.stdin.write(JSON.stringify(navigationCommand) + '\n');

// Handle responses
mcp.stdout.on('data', (data) => {
  console.log('✅ MCP RESPONSE:', data.toString());
});

mcp.stderr.on('data', (data) => {
  console.log('📝 MCP DEBUG:', data.toString());
});

// After 5 seconds, send accessibility audit command
setTimeout(() => {
  const accessibilityCommand = {
    "jsonrpc": "2.0", 
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "execute_javascript",
      "arguments": {
        "code": `
          // R8 Mobile Accessibility Audit
          const accessibilityData = {
            timestamp: new Date().toISOString(),
            viewport: window.innerWidth + 'x' + window.innerHeight,
            focusableElements: document.querySelectorAll('button, input, select, textarea, a[href], [tabindex]').length,
            ariaElements: document.querySelectorAll('[aria-label], [aria-labelledby], [role]').length,
            touchTargets: Array.from(document.querySelectorAll('button, a')).map(el => ({
              width: el.offsetWidth,
              height: el.offsetHeight,
              touchFriendly: el.offsetWidth >= 44 && el.offsetHeight >= 44
            })).length,
            pageTitle: document.title,
            url: window.location.href
          };
          return JSON.stringify(accessibilityData, null, 2);
        `
      }
    }
  };
  
  console.log('\n🔍 EXECUTING: Mobile accessibility audit...');
  mcp.stdin.write(JSON.stringify(accessibilityCommand) + '\n');
}, 5000);

// Close after 10 seconds
setTimeout(() => {
  console.log('\n🎯 R8-MCP-EVIDENCE: Mobile accessibility testing completed');
  mcp.kill();
}, 10000);