#!/bin/bash
# PowercutsClone - Build on device with Theos
set -e

export THEOS=/var/theos
WORKDIR="/var/mobile/PowercutsClone"
INSTALL_DIR="/var/mobile/PowercutsClone_install"
DEB_DIR="$INSTALL_DIR/Package"
BUNDLE_ID="com.yourname.powercutsclone"
VERSION="1.0.1"

rm -rf "$WORKDIR" "$INSTALL_DIR"
mkdir -p "$WORKDIR" "$INSTALL_DIR"

echo "[1/4] Writing Tweak.x..."
cat > "$WORKDIR/Tweak.x" << 'TWEAK_EOF'
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook SBApplicationController

- (void)applicationDidLaunch:(id)arg1 {
    %orig(arg1);
    NSLog(@"[PowercutsClone] App launched");
}

%end

%ctor {
    NSLog(@"[PowercutsClone] Loaded! v1.0.1 - iOS 17 Rootless");
}
TWEAK_EOF

echo "[2/4] Writing Makefile..."
cat > "$WORKDIR/Makefile" << 'MAKEFILE_EOF'
ARCHS = arm64
TARGET = iphone:clang:latest:17.0
PACKAGE_VERSION = 1.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PowercutsClone
PowercutsClone_FILES = Tweak.x
PowercutsClone_FRAMEWORKS = Foundation UIKit
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
MAKEFILE_EOF

echo "[3/4] Compiling with Theos..."
cd "$WORKDIR"
export PATH="$THEOS/bin:$PATH"
make clean 2>/dev/null || true
make -j$(sysctl -n hw.ncpu) FINAL_PACKAGE=1 2>&1

if [ ! -s "$WORKDIR/.theos/obj/debug/PowercutsClone.dylib" ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "[4/4] Building .deb package..."
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries"

cat > "$DEB_DIR/DEBIAN/control" << CTRL_EOF
Package: ${BUNDLE_ID}
Name: PowercutsClone
Version: ${VERSION}
Description: Powercuts-like shortcut actions for iOS 17 (Rootless)
Author: YourName
Section: Tweaks
Maintainer: YourName
Depends: mobilesubstrate, firmware (>= 14.0)
Architecture: iphoneos-arm64
CTRL_EOF

echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries/${BUNDLE_ID}.plist"

cp "$WORKDIR/.theos/obj/debug/PowercutsClone.dylib" "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries/${BUNDLE_ID}.dylib"

chmod 0755 "$DEB_DIR/DEBIAN"
cd "$INSTALL_DIR"
dpkg-deb --build Package "${BUNDLE_ID}_${VERSION}_iphoneos-arm64.deb" 2>&1

if [ -f "${BUNDLE_ID}_${VERSION}_iphoneos-arm64.deb" ]; then
    echo "Installing package..."
    dpkg -i "${BUNDLE_ID}_${VERSION}_iphoneos-arm64.deb" 2>&1 || dpkg -i --force-all "${BUNDLE_ID}_${VERSION}_iphoneos-arm64.deb" 2>&1
    echo "Done! Respring to apply:"
    echo "  killall SpringBoard"
else
    echo "ERROR: .deb not created!"
    exit 1
fi
