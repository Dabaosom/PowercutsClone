const fs = require('fs');
const http = require('http');

// 读取脚本内容
const scriptPath = 'C:\\Users\\Administrator\\Desktop\\PowercutsClone\\install_on_phone.sh';
const scriptContent = fs.readFileSync(scriptPath, 'utf8');

// MCP HTTP 端点
const MCP_URL = 'http://192.168.1.19:8090/mcp';

// 构造 MCP 请求
const payload = JSON.stringify({
  jsonrpc: '2.0',
  id: 1,
  method: 'tools/call',
  params: {
    name: 'write_file',
    arguments: {
      path: '/var/jb/tmp/install_powercuts.sh',
      content: scriptContent,
      encoding: 'utf8'
    }
  }
});

const options = {
  hostname: '192.168.1.19',
  port: 8090,
  path: '/mcp',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

console.log('[1/2] Writing install script to iPhone...');
console.log(`  Destination: /var/jb/tmp/install_powercuts.sh`);
console.log(`  Size: ${scriptContent.length} bytes`);

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log(`\n[2/2] Response (HTTP ${res.statusCode}):`);
    try {
      const result = JSON.parse(data);
      if (result.error) {
        console.error('ERROR:', result.error);
      } else {
        console.log('SUCCESS! Script written to iPhone.');
        console.log('\nNow on your iPhone:');
        console.log('  1. Open NewTerm (or any terminal)');
        console.log('  2. Type: su');
        console.log('  3. Enter root password');
        console.log('  4. Type: bash /var/jb/tmp/install_powercuts.sh');
        console.log('  5. Wait for compilation to finish (~5-10 minutes)');
      }
    } catch (e) {
      console.log('Response:', data.substring(0, 500));
    }
  });
});

req.on('error', (e) => {
  console.error('Request failed:', e.message);
});

req.write(payload);
req.end();
