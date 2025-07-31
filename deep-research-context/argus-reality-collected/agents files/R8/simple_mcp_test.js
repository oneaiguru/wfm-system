#!/usr/bin/env node
// R8: Simple MCP test with longer timeout

const { exec } = require('child_process');
const fs = require('fs');

// Create MCP command file
const mcpCommand = {
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call", 
  "params": {
    "name": "navigate",
    "arguments": {
      "url": "https://lkcc1010wfmcc.argustelecom.ru/login"
    }
  }
};

fs.writeFileSync('/tmp/mcp_command.json', JSON.stringify(mcpCommand));

console.log('🎯 R8: Simple MCP navigation test with extended timeout...');

exec('timeout 30 node /Users/m/git/mcp/playwright-human-behavior-mcp.js < /tmp/mcp_command.json', {
  env: {
    ...process.env,
    PLAYWRIGHT_ENHANCED_MODE: 'true',
    PLAYWRIGHT_PROXY_SERVER: 'socks5://127.0.0.1:1080'
  }
}, (error, stdout, stderr) => {
  console.log('✅ R8-MCP-RESULT:');
  if (stdout) console.log('📊 STDOUT:', stdout);
  if (stderr) console.log('📝 STDERR:', stderr);
  if (error) console.log('⚠️ ERROR:', error.message);
  
  console.log('\n🎯 R8-EVIDENCE: MCP browser automation attempted with extended timeout');
});