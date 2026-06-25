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
    const BASE = '/var/mobile/PowercutsClone';

    // Read source files
    const tweakContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\Tweak.x', 'utf8');
    const makefileContent = `ARCHS = arm64
TARGET := iphone:clang:17.2:14.2
INSTALL_TARGET_PROCESSES = Shortcuts

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_LIBRARIES = MobileCoreServices

include \$(THEOS_MAKE_PATH)/tweak.mk`;

    // Write a COMPLETE self-contained script that includes ALL source inline (no file copy needed)
    // This avoids all path/permission issues
    const installScript = `#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=============================================="
echo " PowercutsClone - Full Build & Install"
echo " iOS 17 Rootless Jailbreak"
echo "=============================================="

# Check root
[ "$(id -u)" = "0" ] || { echo "ERROR: Run as root!"; exit 1; }
echo "[OK] Root confirmed"

# Install ALL build tools including git
echo ""
echo "[*] Installing build dependencies (git, make, clang, etc)..."
apt-get update -y 2>/dev/null | tail -3
apt-get install -y make clang ldid git curl tar rsync python3 2>&1 | tail -5
which git >/dev/null 2>&1 && echo "[OK] Git installed" || { echo "ERROR: Git install failed!"; exit 1; }
echo "[OK] Dependencies ready"

# Install Theos
THEOS_DIR="/var/theos"
if [ ! -d "$THEOS_DIR" ]; then
    echo ""
    echo "[*] Cloning Theos (this takes a few minutes)..."
    git clone --recursive --depth=1 https://github.com/theos/Theos.git "$THEOS_DIR" 2>&1 | tail -5
fi
export THEOS="$THEOS_DIR"
echo "[OK] Theos at $THEOS_DIR"

# Create project dir and write files via heredoc
BUILD_DIR="/var/jb/var/Library/PowercutsClone"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo ""
echo "[*] Writing Tweak.x ..."
cat > Tweak.x << 'TWEAK_EOF'
${tweakContent}
TWEAK_EOF
echo "[OK] Tweak.x written ($(wc -c < Tweak.x) bytes)"

echo "[*] Writing Makefile ..."
cat > Makefile << 'MAKEFILE_EOF'
${makefileContent}
MAKEFILE_EOF
echo "[OK] Makefile written"

# Compile
echo ""
echo "[*] Compiling PowercutsClone..."
make clean 2>/dev/null || true
make 2>&1 | tail -25

DYLIB=$(find . -name "*.dylib" -type f 2>/dev/null | head -1)
if [ -z "$DYLIB" ]; then
    echo ""
    echo "[!] Trying with SDK fix..."
    "$THEOS/bin/sdk" 2>/dev/null || true
    make 2>&1 | tail -25
    DYLIB=$(find . -name "*.dylib" -type f 2>/dev/null | head -1)
fi

if [ -z "$DYLIB" ]; then
    echo ""
    echo "=============================================="
    echo " COMPILATION FAILED!"
    echo " Check errors above for details."
    echo "=============================================="
    exit 1
fi

echo ""
echo "[OK] Compiled: $DYLIB"

# Install
DST="/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$DST"
cp -f "$DYLIB" "$DST/PowercutsClone.dylib"
chmod 644 "$DST/PowercutsClone.dylib"
echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "$DST/PowercutsClone.plist"
chmod 644 "$DST/PowercutsClone.plist"
echo "[OK] Installed to $DST/"

# Restart Shortcuts
killall Shortcuts 2>/dev/null || true
sleep 1

echo ""
echo "=============================================="
echo " DONE! Open Shortcuts app now!"
echo "=============================================="
`;

    console.log('Writing complete install script (with embedded source)...');
    
    // Write the script to mobile-accessible path
    const r = await mcpCall('write_file', { 
        path: '/var/mobile/build_powercuts.sh', 
        content: installScript, 
        encoding: 'utf8' 
    });
    const errText = r.result?.content?.[0]?.text || '';
    if (errText.includes('Cannot')) {
        console.log('FAIL:', errText);
        return;
    }
    
    // Verify
    const r2 = await mcpCall('run_command', { 
        command: 'ls -lh /var/mobile/build_powercuts.sh 2>&1' 
    });
    const v = r2.result?.content?.[0]?.text || '';
    console.log('Verify:', v);
    
    if (v.includes('build_powercuts')) {
        console.log('\n=== READY! ===\n');
        console.log('On your iPhone ROOT terminal, run:');
        console.log('  bash /var/mobile/build_powercuts.sh');
        console.log('\nThis script has ALL source code embedded - no file copy needed!');
        console.log('It will auto-install git -> clone Theos -> compile -> install.');
    }
}

main().catch(e => console.error('Error:', e.message));
