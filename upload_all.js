const fs = require('fs');
const http = require('http');

const MCP_HOST = '192.168.1.19';
const MCP_PORT = 8090;

function mcpCall(toolName, args) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            jsonrpc: '2.0',
            id: Date.now(),
            method: 'tools/call',
            params: { name: toolName, arguments: args }
        });
        
        const req = http.request({
            hostname: MCP_HOST,
            port: MCP_PORT,
            path: '/mcp',
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
        }, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); } catch(e) { resolve(data); }
            });
        });
        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

async function main() {
    // 1. Write Tweak.x
    console.log('[1/4] Writing Tweak.x ...');
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');
    const r1 = await mcpCall('write_file', {
        path: '/var/jb/var/Library/PowercutsClone/Tweak.x',
        content: tweakContent,
        encoding: 'utf8'
    });
    console.log('  Tweak.x:', r1.error ? 'FAIL' : 'OK (' + tweakContent.length + ' bytes)');

    // 2. Write Makefile
    console.log('[2/4] Writing Makefile ...');
    const makefileContent = `ARCHS = arm64
TARGET := iphone:clang:17.2:14.2
INSTALL_TARGET_PROCESSES = Shortcuts

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_LIBRARIES = MobileCoreServices

include \$(THEOS_MAKE_PATH)/tweak.mk`;
    const r2 = await mcpCall('write_file', {
        path: '/var/jb/var/Library/PowercutsClone/Makefile',
        content: makefileContent,
        encoding: 'utf8'
    });
    console.log('  Makefile:', r2.error ? 'FAIL' : 'OK');

    // 3. Write install script (root hide compatible)
    console.log('[3/4] Writing install script ...');
    const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\install_on_phone.sh', 'utf8');
    // Fix path for root hide environment
    const fixedScript = scriptContent.replace(
        'SRC_DIR="/var/jb/var/Library/PowercutsClone"',
        'SRC_DIR="/var/jb/var/Library/PowercutsClone"'
    );
    const r3 = await mcpCall('write_file', {
        path: '/var/jb/tmp/install_powercuts.sh',
        content: fixedScript,
        encoding: 'utf8'
    });
    console.log('  Script:', r3.error ? 'FAIL' : 'OK (' + fixedScript.length + ' bytes)');

    // 4. Verify files exist
    console.log('[4/4] Verifying ...');
    const r4 = await mcpCall('run_command', {
        command: 'ls -lh /var/jb/var/Library/PowercutsClone/ 2>/dev/null && echo "---" && ls -lh /var/jb/tmp/install_powercuts.sh 2>/dev/null'
    });
    console.log('  Files on device:');
    if (r4.result && r4.result.content) {
        console.log('  ', r4.result.content[0].text.replace(/\\n/g, '\n  '));
    } else if (r4.output !== undefined) {
        console.log('  ', r4.output.replace(/\\n/g, '\n  '));
    }

    console.log('\nDone! Now run on iPhone (as root):');
    console.log('  bash /var/jb/tmp/install_powercuts.sh');
}

main().catch(console.error);
