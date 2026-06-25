const fs = require('fs');
const http = require('http');

const HOST = '192.168.1.19';
const PORT = 8090;

function mcpCall(toolName, args) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            jsonrpc: '2.0',
            id: Date.now() % 99999,
            method: 'tools/call',
            params: { name: toolName, arguments: args }
        });
        
        const req = http.request({ hostname: HOST, port: PORT, path: '/mcp', method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
        }, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => { try { resolve(JSON.parse(data)); } catch(e) { resolve({raw: data}); } });
        });
        req.on('error', reject);
        req.setTimeout(10000, () => { req.destroy(); reject(new Error('timeout')); });
        req.write(payload);
        req.end();
    });
}

async function main() {
    // Read files
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');
    
    console.log(`Writing Tweak.x (${tweakContent.length} bytes)...`);
    const r1 = await mcpCall('write_file', { path: '/var/jb/var/Library/PowercutsClone/Tweak.x', content: tweakContent, encoding: 'utf8' });
    console.log('write_file result:', JSON.stringify(r1).substring(0, 300));
    
    // Also try base64
    const b64 = Buffer.from(tweakContent).toString('base64');
    console.log(`\nTrying base64 write (${b64.length} chars)...`);
    const r2 = await mcpCall('write_file', { path: '/var/jb/var/Library/PowercutsClone/Tweak.x', content: b64, encoding: 'base64' });
    console.log('base64 result:', JSON.stringify(r2).substring(0, 300));
    
    // Verify
    console.log('\nVerifying...');
    const r3 = await mcpCall('run_command', { command: 'find / -maxdepth 6 -name "Tweak.x" 2>/dev/null; ls /var/jb/var/Library/ 2>/dev/null' });
    console.log('verify:', JSON.stringify(r3).substring(0, 500));
}

main().catch(e => console.error('Error:', e.message));
