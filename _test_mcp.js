const fs = require('fs');
const http = require('http');

const MCP_URL = 'http://192.168.1.19:8090/mcp';

function mcpCall(toolName, params) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      jsonrpc: '2.0',
      id: Date.now(),
      method: 'tools/call',
      params: {
        name: toolName,
        arguments: params
      }
    });

    const url = new URL(MCP_URL);
    const options = {
      hostname: url.hostname,
      port: url.port || 80,
      path: url.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          console.log(`[RAW ${toolName}] ${JSON.stringify(result).substring(0, 300)}`);
          if (result.error) reject(new Error(JSON.stringify(result.error)));
          else resolve(result.result);
        } catch(e) {
          reject(new Error(`Parse: ${data.substring(0,300)}`));
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  try {
    // Test with a simple command first
    const r = await mcpCall('run_command', { command: 'echo HELLO_TEST', timeout: 5 });
    console.log('\nFull result:', JSON.stringify(r, null, 2));
  } catch(e) {
    console.error('Error:', e.message);
  }
}

main();
