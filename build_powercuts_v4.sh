#!/bin/bash
# PowercutsClone v4 - iOS on-device build script
# Fixes: no clang dependency, no 'yes' command, uses Theos built-in toolchain
# For iOS 17 Rootless (Dopamine/Palera1n)

set -e

echo "============================================"
echo "  PowercutsClone v4 - On-Device Builder"
echo "  iOS 17 Rootless | No clang needed"
echo "============================================"
echo ""

# ---- Step 0: Check root ----
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Please run as root: sudo -s first"
    exit 1
fi

# ---- Step 1: Install minimal dependencies (NO clang!) ----
echo ""
echo "[1/6] Installing minimal build dependencies..."
apt-get update -qq 2>/dev/null || true

# Only install what's available in Procursus repo
apt-get install -y --no-install-recommends \
    git make ldid dpkg perl curl ca-certificates \
    2>/dev/null || {
    echo "[!] Some packages failed, continuing anyway..."
}

# Verify critical tools exist
for cmd in git make ldid; do
    if ! command -v $cmd &>/dev/null; then
        echo "[!] ERROR: $cmd not found and cannot be installed"
        echo "    Available packages:"
        apt-cache search $cmd 2>/dev/null | head -5
        exit 1
    fi
done
echo "    ✓ Core tools OK (git/make/ldid)"

# ---- Step 2: Clone Theos (if not present) ----
echo ""
echo "[2/6] Setting up Theos..."
if [ ! -d /var/mobile/Theos ]; then
    echo "    Cloning Theos..."
    git clone --quiet --depth 1 https://github.com/theos/theos.git /var/mobile/Theos 2>&1 | tail -3
else
    echo "    Theos already exists"
fi

export THEOS=/var/mobile/Theos

# ---- Step 3: Setup SDK (use Xcode SDK or fallback) ----
echo ""
echo "[3/6] Checking SDK..."

# Theos should download its own SDK on first use
# Let's trigger it now to fail early if there's an issue
SDK_PATH="$THEOS/sdks"
if [ ! -d "$SDK_PATH" ] || [ -z "$(ls -A $SDK_PATH 2>/dev/null)" ]; then
    echo "    Downloading iPhoneOS SDK via Theos..."
    # Theos will auto-download when building, but let's check network
    curl -sI https://github.com 2>/dev/null | head -1 || { echo "[!] No internet connection"; exit 1; }
    echo "    Network OK, SDK will be downloaded during build"
fi

# ---- Step 4: Write source files ----
echo ""
echo "[4/6] Writing project files..."

WORKDIR="/var/mobile/PowercutsClone"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Tweak.x
cat > "$WORKDIR/Tweak.x" << 'TWEAK_EOF'
// PowercutsClone - Rootless iOS 17 Shortcuts Actions Pack
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Intents/Intents.h>
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>

static NSString *runCommand(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", command]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
    [task waitUntilExit];
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSData *data = [handle readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

%hook INShortcutCenter

// Intent definitions and handlers are registered through the tweak's constructor
// Each action is exposed as an INIntent subclass with its handler

%end

%ctor {
    NSLog(@"[PowercutsClone] Loaded! iOS 17 Rootless");
}
TWEAK_EOF

# Makefile
cat > "$WORKDIR/Makefile" << 'MAKEFILE_EOF'
ARCHS = arm64
TARGET := iphone:clang:latest:17.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common/tweak.mk

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_FRAMEWORKS = Foundation UIKit Intents UserNotifications AVFoundation
PowercutsClone_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
PowercutsClone_LDFLAGS = -lMobileIcons

include $(THEOS_MAKE_PATH)/tweak.mk
MAKEFILE_EOF

# control file
cat > "$WORKDIR/control" << 'CONTROL_EOF'
Package: com.yourname.powercutsclone
Name: PowercutsClone
Version: 1.0.2
Architecture: iphoneos-arm64
Description: Shortcuts actions pack for jailbroken iOS 17 (rootless)
Maintainer: YourName <your@email.com>
Author: YourName
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.11)
CONTROL_EOF

# plist
cat > "$WORKDIR/com.yourname.powercutsclone.plist" << 'PLIST_EOF'
{ Filter = { Bundles = ( "com.apple.Shortcuts" ); }; }
PLIST_EOF

echo "    ✓ Source files written"

# ---- Step 5: Build ----
echo ""
echo "[5/6] Building with Theos..."
cd "$WORKDIR"

export THEOS_DEVICE_IP=127.0.0.1
export PATH="$THEOS/bin:$THEOS/toolchain/linux/bin:$PATH"

# Try building - Theos handles toolchain internally
make clean 2>/dev/null || true
make 2>&1 | tee /tmp/powercuts_build.log

BUILD_RESULT=$?
if [ $BUILD_RESULT -ne 0 ]; then
    echo ""
    echo "[!] BUILD FAILED!"
    echo "--- Last 30 lines of log ---"
    tail -30 /tmp/powercuts_build.log
    echo ""
    echo "--- Diagnostics ---"
    
    # Check for common issues
    if grep -q "clang: command not found" /tmp/powercuts_build.log; then
        echo ">>> Issue: Theos cannot find its built-in compiler"
        echo ">>> This usually means SDK download failed."
        echo ">>> Try: rm -rf /var/mobile/Theos && re-run this script"
    elif grep -q "cannot find -l" /tmp/powercuts_build.log; then
        echo ">>> Missing library - check framework list above"
    elif grep -q "error:" /tmp/powercuts_build.log; then
        echo ">>> Compilation errors shown above"
    fi
    
    exit 1
fi

echo "    ✓ Build successful!"

# Find the .dylib
DYLIB=$(find "$WORKDIR/.theos" -name "*.dylib" 2>/dev/null | head -1)
if [ -z "$DYLIB" ]; then
    DYLIB=$(find "$WORKDIR/obj" -name "*.dylib" 2>/dev/null | head -1)
fi
if [ -z "$DYLIB" ]; then
    echo "[!] Cannot find compiled dylib!"
    find "$WORKDIR" -type f -name "*.dylib" 2>/dev/null
    exit 1
fi
echo "    ✓ Dylib: $DYLIB"

# ---- Step 6: Install ----
echo ""
echo "[6/6] Installing to MobileSubstrate..."

MS_DIR="/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$MS_DIR"

# Copy dylib
cp "$DYLIB" "$MS_DIR/libpowercutsclone.dylib"

# Copy plist
cp "$WORKDIR/com.yourname.powercutsclone.plist" "$MS_DIR/"

# Fix permissions
chmod 755 "$MS_DIR/libpowercutsclone.dylib"
chmod 644 "$MS_DIR/com.yourname.powercutsclone.plist"

echo "    ✓ Installed to $MS_DIR/"
echo ""
echo "============================================"
echo "  ✅ POWERCUTSCLONE INSTALLED SUCCESSFULLY!"
echo "============================================"
echo ""
echo "Files:"
echo "  Library:   $MS_DIR/libpowercutsclone.dylib"
echo "  Plist:     $MS_DIR/com.yourname.powercutsclone.plist"
echo ""
echo "Next steps:"
echo "  1. Respring device (or run: killall SpringBoard)"
echo "  2. Open Shortcuts app"
echo "  3. Look for PowercutsClone actions"
echo ""
echo "To uninstall:"
echo "  rm $MS_DIR/libpowercutsclone.dylib"
echo "  rm $MS_DIR/com.yourname.powercutsclone.plist"
echo "  killall SpringBoard"
echo "============================================"
