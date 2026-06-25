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
        req.setTimeout(15000, () => { req.destroy(); reject(new Error('timeout')); });
        req.write(payload);
        req.end();
    });
}

async function main() {
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');

    // Step 1: Check what tools are ALREADY available on the phone
    console.log('=== Checking phone environment ===');
    
    const checks = await mcpCall('run_command', {
        command: `echo "=== COMPILERS ===" && which clang clang++ cc gcc 2>&1; echo "=== TOOLS ===" && which make ldid git tar curl python3 dpkg-deb 2>&1; echo "=== THEOS ===" && ls -d /var/theos /opt/theos /root/.theos 2>&1; echo "=== SDK ===" && ls /var/theos/sdks/ 2>/dev/null || ls /usr/share/iphone-sdk/ 2>/dev/null || echo "no sdk found"; echo "=== HEADERS ===" && find /var/jb/usr/include -name "UIKit.h" 2>/dev/null | head -3; echo "=== DONE ==="`
    });
    console.log(checks.result?.content?.[0]?.text || 'no output');

    // Step 2: If we have clang+make but no Theos, try direct compilation with system SDK
    const compileScript = `#!/bin/bash
set -e

echo "=============================================="
echo " PowercutsClone - Direct Compile (No Theos)"
echo "=============================================="

[ "$(id -u)" = "0" ] || { echo "Run as root!"; exit 1; }

# Find what we have
CLANG=\$(which clang 2>/dev/null)
MAKE=\$(which make 2>/dev/null)
LDID=\$(which ldid 2>/dev/null)

echo "[*] clang: \$CLANG"
echo "[*] make: \$MAKE"
echo "[*] ldid: \$LDID"

# Try to find SDK/headers
SDK_PATH=""
for p in /var/theos/sdks/iPhoneOS17.2.sdk /var/theos/sdks/*.sdk /usr/share/iphone-sdk/*.sdk; do
    [ -d "\$p" ] && SDK_PATH="\$p" && break
done
[ -z "\$SDK_PATH" ] && echo "[!] No SDK found, will try without"

# Write source
mkdir -p /tmp/pcc_build
cd /tmp/pcc_build

cat > Tweak.x << 'TXEOF'
${tweakContent}
TXEOF

cat > Makefile << 'MFEOF'
ARCHS = arm64
TARGET := iphone:clang:17.2:14.2
INSTALL_TARGET_PROCESSES = Shortcuts
TWEAK_NAME = PowercutsClone
PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_LIBRARIES = MobileCoreServices
include \$(THEOS_MAKE_PATH)/tweak.mk
MFEOF

# Try with Theos if it exists
if [ -d "/var/theos" ]; then
    export THEOS=/var/theos
    echo ""
    echo "[*] Compiling with Theos..."
    make clean 2>/dev/null || true
    make -j1 2>&1 | tail -30
    
    DYLIB=\$(find . -name "*.dylib" | head -1)
    if [ -n "\$DYLIB" ]; then
        echo ""
        echo "[OK] Compiled! Installing..."
        DST="/var/jb/Library/MobileSubstrate/DynamicLibraries"
        mkdir -p "\$DST"
        cp "\$DYLIB" "\$DST/PowercutsClone.dylib"
        chmod 644 "\$DST/PowercutsClone.dylib"
        echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "\$DST/PowercutsClone.plist"
        killall Shortcuts 2>/dev/null || true
        echo "DONE! Open Shortcuts app!"
        exit 0
    fi
fi

echo ""
echo "=============================================="
echo " NEED THEOS!"
echo ""
echo " Your phone doesn't have Theos yet."
echo " Let me install it for you..."
echo "=============================================="

# Install git first (the only thing we really need)
apt-get update -y 2>/dev/null | tail -1
apt-get install -y git make ldid rsync 2>&1 | tail -3

if ! which git >/dev/null 2>&1; then
    echo "[FATAL] Cannot install git. Aborting."
    exit 1
fi

# Clone Theos
if [ ! -d "/var/theos" ]; then
    echo ""
    echo "[*] Cloning Theos (~2-5 min)..."
    rm -rf /var/theos 2>/dev/null
    git clone --recursive --depth=1 https://github.com/theos/Theos.git /var/theos 2>&1 | tail -10
fi

export THEOS=/var/theos

# Recompile
echo ""
echo "[*] Compiling..."
make clean 2>/dev/null || true
make -j1 2>&1 | tail -30

DYLIB=\$(find . -name "*.dylib" | head -1)
if [ -z "\$DYLIB" ]; then
    echo "COMPILATION FAILED"
    exit 1
fi

DST="/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "\$DST"
cp "\$DYLIB" "\$DST/PowercutsClone.dylib"
chmod 644 "\$DST/PowercutsClone.dylib"
echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "\$DST/PowercutsClone.plist"
killall Shortcuts 2>/dev/null || true
echo ""
echo "DONE! Open Shortcuts app!"
`;

    console.log('\nWriting smart build script...');
    await mcpCall('write_file', { 
        path: '/var/mobile/build_powercuts.sh', 
        content: compileScript, 
        encoding: 'utf8' 
    });

    const v = await mcpCall('run_command', { command: 'ls -lh /var/mobile/build_powercuts.sh' });
    console.log('Ready:', v.result?.content?.[0]?.text);
}

main().catch(e => console.error('Error:', e.message));
