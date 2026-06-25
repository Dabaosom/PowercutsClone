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
    // Step 1: Create directory
    console.log('[1/5] Creating directory...');
    const r0 = await mcpCall('run_command', { command: 'mkdir -p /var/jb/var/Library/PowercutsClone && echo DIR_OK' });
    console.log('  mkdir:', r0.result ? r0.result.content[0].text : JSON.stringify(r0).substring(0, 200));

    // Step 2: Write Tweak.x
    console.log('[2/5] Writing Tweak.x ...');
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');
    const r1 = await mcpCall('write_file', { path: '/var/jb/var/Library/PowercutsClone/Tweak.x', content: tweakContent, encoding: 'utf8' });
    const err1 = r1.result?.content?.[0]?.text || '';
    console.log('  Tweak.x:', err1.includes('error') || err1.includes('不能') ? 'FAIL: ' + err1 : 'OK (' + tweakContent.length + ' bytes)');

    // Step 3: Write Makefile
    console.log('[3/5] Writing Makefile ...');
    const makefile = `ARCHS = arm64
TARGET := iphone:clang:17.2:14.2
INSTALL_TARGET_PROCESSES = Shortcuts

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_LIBRARIES = MobileCoreServices

include \$(THEOS_MAKE_PATH)/tweak.mk`;
    const r2 = await mcpCall('write_file', { path: '/var/jb/var/Library/PowercutsClone/Makefile', content: makefile, encoding: 'utf8' });
    const err2 = r2.result?.content?.[0]?.text || '';
    console.log('  Makefile:', err2.includes('error') || err2.includes('不能') ? 'FAIL: ' + err2 : 'OK');

    // Step 4: Update install script with correct SRC_DIR
    console.log('[4/5] Updating install script ...');
    const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\install_on_phone.sh', 'utf8');
    const r3 = await mcpCall('write_file', { path: '/var/jb/tmp/install_powercuts.sh', content: scriptContent, encoding: 'utf8' });
    const err3 = r3.result?.content?.[0]?.text || '';
    console.log('  Script:', err3.includes('error') || err3.includes('不能') ? 'FAIL: ' + err3 : 'OK');

    // Step 5: Verify ALL files
    console.log('[5/5] Verifying all files...');
    const r4 = await mcpCall('run_command', { 
        command: 'echo "=== Tweak.x ===" && ls -lh /var/jb/var/Library/PowercutsClone/Tweak.x 2>&1 && echo "=== Makefile ===" && ls -lh /var/jb/var/Library/PowercutsClone/Makefile 2>&1 && echo "=== Script ===" && ls -lh /var/jb/tmp/install_powercuts.sh 2>&1'
    });
    const v = r4.result?.content?.[0]?.text || r4.raw || '';
    console.log('  Verify:\n  ', v.replace(/\\n/g, '\n  '));
    
    if (v.includes('Tweak.x') && v.includes('Makefile') && v.includes('install_powercuts')) {
        console.log('\n✅ ALL FILES READY!');
        console.log('\nOn your iPhone (root terminal), run:');
        console.log('  bash /var/jb/tmp/install_powercuts.sh');
    } else {
        console.log('\n❌ Some files missing. Check output above.');
    }
}

main().catch(e => console.error('Error:', e.message));
