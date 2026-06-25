const fs = require('fs');
const http = require('http');

const MCP_URL = 'http://192.168.1.19:8090/mcp';

function mcpCall(toolName, params) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      jsonrpc: '2.0',
      id: Date.now(),
      method: 'tools/call',
      params: { name: toolName, arguments: params }
    });
    const url = new URL(MCP_URL);
    const req = http.request({
      hostname: url.hostname, port: url.port||80, path: url.pathname,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const r = JSON.parse(data);
          if (r.error) return reject(new Error(JSON.stringify(r.error)));
          // Extract actual tool output from MCP wrapper
          const content = r.result?.content;
          if (content && content[0]?.text) {
            const parsed = JSON.parse(content[0].text);
            resolve(parsed);
          } else {
            resolve(r.result);
          }
        } catch(e) { reject(new Error(`Parse: ${data.substring(0,300)}`)); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  try {
    // Step 1: Check if chunk files exist from previous _push3.js run
    console.log('[0/4] Checking previous chunks...');
    const r0 = await mcpCall('run_command', {
      command: 'ls -la /var/mobile/b64_chunk_*.txt 2>/dev/null && echo "CHUNKS_EXIST" || echo "NO_CHUNKS"',
      timeout: 10
    });
    console.log('  ', r0.output?.trim());

    if (!r0.output?.includes('CHUNKS_EXIST')) {
      console.log('  Chunks not found, re-uploading...');
      // Re-upload chunks
      const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v4.sh', 'utf8');
      const b64 = Buffer.from(scriptContent).toString('base64');
      const CHUNK_SIZE = 2000;
      const chunks = [];
      for (let i = 0; i < b64.length; i += CHUNK_SIZE) chunks.push(b64.substring(i, i + CHUNK_SIZE));
      for (let i = 0; i < chunks.length; i++) {
        console.log(`  Uploading chunk ${i+1}/${chunks.length}...`);
        await mcpCall('write_file', { path: `/var/mobile/b64_chunk_${i}.txt`, content: chunks[i] });
      }
      console.log('  All chunks uploaded.');
    }

    // Step 2: Assemble chunks
    console.log('[1/4] Assembling chunks...');
    const r1 = await mcpCall('run_command', {
      command: 'cat /var/mobile/b64_chunk_0.txt /var/mobile/b64_chunk_1.txt /var/mobile/b64_chunk_2.txt /var/mobile/b64_chunk_3.txt /var/mobile/b64_chunk_4.txt > /var/mobile/b64_full.txt && echo "ASM_DONE_$(wc -c < /var/mobile/b64_full.txt)"',
      timeout: 15
    });
    console.log('  ', r1.output?.trim());

    // Step 3: Decode
    console.log('[2/4] Decoding...');
    const r2 = await mcpCall('run_command', {
      command: 'base64 -d /var/mobile/b64_full.txt > /var/mobile/build_powercuts_v4.sh && chmod +x /var/mobile/build_powercuts_v4.sh && echo "DEC_DONE_$(wc -c < /var/mobile/build_powercuts_v4.sh)"',
      timeout: 15
    });
    console.log('  ', r2.output?.trim());

    // Step 4: Verify
    console.log('[3/4] Verifying...');
    const r3 = await mcpCall('run_command', {
      command: 'head -2 /var/mobile/build_powercuts_v4.sh && echo "---" && tail -2 /var/mobile/build_powercuts_v4.sh && echo "---" && md5 /var/mobile/build_powercuts_v4.sh',
      timeout: 10
    });
    console.log('  ', r3.output?.trim());

    // Step 5: Cleanup
    console.log('[4/4] Cleanup...');
    const r4 = await mcpCall('run_command', {
      command: 'rm -f /var/mobile/b64_chunk_*.txt /var/mobile/b64_full.txt',
      timeout: 10
    });
    console.log('  ', r4.output?.trim() || 'OK');

    console.log('\n✅ build_powercuts_v4.sh is ready on iPhone!');
    console.log('   Path: /var/mobile/build_powercuts_v4.sh');
    console.log('   Run: bash /var/mobile/build_powercuts_v4.sh');

  } catch(e) {
    console.error('\n❌ Error:', e.message);
    process.exit(1);
  }
}

main();
