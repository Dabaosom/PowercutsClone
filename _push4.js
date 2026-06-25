const fs = require('fs');
const https = require('https');
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
          if (result.error) reject(new Error(JSON.stringify(result.error)));
          else resolve(result.result);
        } catch(e) {
          reject(new Error(`Parse error: ${data.substring(0,200)}`));
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
    // Step 1: Concatenate base64 chunks (use run_command with simple command)
    console.log('[1/3] Concatenating chunks...');
    // Use simple approach: write a small assemble script, then run it
    const assembleScript = '#!/bin/bash\ncat /var/mobile/b64_chunk_0.txt /var/mobile/b64_chunk_1.txt /var/mobile/b64_chunk_2.txt /var/mobile/b64_chunk_3.txt /var/mobile/b64_chunk_4.txt > /var/mobile/b64_full.txt\necho "CAT_DONE_$(wc -c < /var/mobile/b64_full.txt)"\n';
    
    await mcpCall('write_file', {
      path: '/var/mobile/assemble.sh',
      content: assembleScript
    });
    console.log('  assemble.sh written');
    
    const r1 = await mcpCall('run_command', {
      command: 'bash /var/mobile/assemble.sh',
      timeout: 15
    });
    console.log('  Result:', r1.output?.trim());
    
    // Step 2: Decode base64
    console.log('[2/3] Decoding base64...');
    const r2 = await mcpCall('run_command', {
      command: 'base64 -d /var/mobile/b64_full.txt > /var/mobile/build_powercuts_v4.sh && chmod +x /var/mobile/build_powercuts_v4.sh && echo "DECODE_DONE_$(wc -c < /var/mobile/build_powercuts_v4.sh)"',
      timeout: 15
    });
    console.log('  Result:', r2.output?.trim());
    
    // Step 3: Cleanup
    console.log('[3/3] Cleaning up...');
    const r3 = await mcpCall('run_command', {
      command: 'rm -f /var/mobile/b64_chunk_*.txt /var/mobile/b64_full.txt /var/mobile/assemble.sh && echo CLEANED',
      timeout: 10
    });
    console.log('  Result:', r3.output?.trim());
    
    // Verify
    const r4 = await mcpCall('run_command', {
      command: 'head -3 /var/mobile/build_powercuts_v4.sh && echo "---" && tail -3 /var/mobile/build_powercuts_v4.sh',
      timeout: 10
    });
    console.log('\nVerify (first/last 3 lines):');
    console.log(r4.output);
    
    console.log('\n✅ Script pushed and assembled successfully!');
    console.log('   On iPhone, run: bash /var/mobile/build_powercuts_v4.sh');
    
  } catch(e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
}

main();
