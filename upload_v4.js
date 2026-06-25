const fs = require('fs');
const http = require('http');

const HOST = '192.168.1.19';
const PORT = 8090;

function mcpCall(toolName, args) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            jsonrpc: '2.0', id: Date.now() % 99999,
            method: 'tools/call', params: { name: toolName, arguments: args }
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
    const BASE = '/var/mobile/PowercutsClone';
    const SCRIPT = '/var/mobile/install_powercuts.sh';

    // Step 1: Create dir
    console.log('[1/4] Creating directory...');
    await mcpCall('run_command', { command: `mkdir -p ${BASE} && echo OK` });

    // Step 2: Write Tweak.x
    console.log('[2/4] Writing Tweak.x ...');
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');
    const r1 = await mcpCall('write_file', { path: `${BASE}/Tweak.x`, content: tweakContent, encoding: 'utf8' });
    console.log('  Tweak.x:', r1.result?.content?.[0]?.text?.includes('Cannot') ? 'FAIL: ' + r1.result.content[0].text : 'OK (' + tweakContent.length + ' bytes)');

    // Step 3: Write Makefile  
    console.log('[3/4] Writing Makefile ...');
    const makefileContent = `ARCHS = arm64
TARGET := iphone:clang:17.2:14.2
INSTALL_TARGET_PROCESSES = Shortcuts

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_LIBRARIES = MobileCoreServices

include \$(THEOS_MAKE_PATH)/tweak.mk`;
    const r2 = await mcpCall('write_file', { path: `${BASE}/Makefile`, content: makefileContent, encoding: 'utf8' });
    console.log('  Makefile:', r2.result?.content?.[0]?.text?.includes('Cannot') ? 'FAIL' : 'OK');

    // Step 4: Write install script (read from file to avoid escaping issues)
    console.log('[4/4] Writing install script ...');
    const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\install_on_phone.sh', 'utf8');
    // Patch SRC_DIR for root hide
    const patchedScript = scriptContent.replace(
        /SRC_DIR="[^"]*"/,
        'SRC_DIR="/var/jb/var/Library/PowercutsClone"'
    ).replace(
        /cd "\$SRC_DIR"/,
        'cd "$SRC_DIR"\n# Copy from mobile-accessible location\ncp -f /var/mobile/PowercutsClone/Tweak.x "$SRC_DIR/Tweak.x" 2>/dev/null || true\ncp -f /var/mobile/PowercutsClone/Makefile "$SRC_DIR/Makefile" 2>/dev/null || true\nmkdir -p "$SRC_DIR"'
    );
    const r3 = await mcpCall('write_file', { path: SCRIPT, content: patchedScript, encoding: 'utf8' });
    console.log('  Script:', r3.result?.content?.[0]?.text?.includes('Cannot') ? 'FAIL: ' + r3.result.content[0].text : 'OK (' + patchedScript.length + ' bytes)');

    // Verify
    console.log('\nVerifying...');
    const r4 = await mcpCall('run_command', { command: `ls -lh ${BASE}/ 2>&1 && echo === && ls -lh ${SCRIPT} 2>&1` });
    const v = r4.result?.content?.[0]?.text || '';
    // Clean up output for display
    const cleanV = typeof v === 'string' ? v : JSON.stringify(v);
    console.log('  ' + cleanV.split('\\n').join('\n  '));
    
    if (cleanV.includes('Tweak.x')) {
        console.log('\n=== ALL FILES READY! ===');
        console.log('\nOn your iPhone (root# terminal), run:');
        console.log('  bash /var/mobile/install_powercuts.sh');
    }
}

main().catch(e => console.error('Error:', e.message));
