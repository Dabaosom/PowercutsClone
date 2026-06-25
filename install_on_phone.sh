#!/bin/bash
# ============================================================
#  PowercutsClone - iOS 17 Rootless 一键编译安装脚本
#  适用: Dopamine / Palera1n (Bootstrap/rootless)
#  用法: su (输入root密码) 后粘贴此脚本运行
# ============================================================

set -e
export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}[i]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_err()     { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "=============================================="
echo "  PowercutsClone - One-Click Build & Install"
echo "  for iOS 17 Rootless Jailbreak"
echo "=============================================="
echo ""

# ---- Step 1: 检查 root ----
log_info "Checking root..."
if [ "$(id -u)" != "0" ]; then
    log_err "Please run as root! Type 'su' first."
    exit 1
fi
log_ok "Root OK"

# ---- Step 2: 更新 apt + 安装依赖 ----
log_info "Updating apt & installing build dependencies..."
apt-get update -y 2>/dev/null | tail -3
apt-get install -y make clang ldid git curl tar rsync 2>&1 | tail -5
log_ok "Dependencies installed"

# ---- Step 3: 安装 Theos ----
THEOS_DIR="/var/theos"
if [ ! -d "$THEOS_DIR" ]; then
    log_info "Cloning Theos to $THEOS_DIR ..."
    git clone --recursive --depth=1 https://github.com/theos/Theos.git "$THEOS_DIR" 2>&1 | tail -5
else
    log_warn "Theos already exists, updating..."
    cd "$THEOS_DIR" && git pull 2>/dev/null || true
fi
export THEOS="$THEOS_DIR"
log_ok "Theos ready at $THEOS_DIR"

# ---- Step 4: 编译 Tweak.x -> dylib ----
SRC_DIR="/var/jb/var/Library/PowercutsClone"
cd "$SRC_DIR"

log_info "Compiling PowercutsClone..."
export THEOS_DEVICE_IP=localhost
make clean 2>/dev/null || true
make 2>&1 | tail -20

# 查找生成的 dylib
DYLIB=$(find . -maxdepth 2 -name "*.dylib" -type f 2>/dev/null | head -1)
if [ -z "$DYLIB" ]; then
    # 尝试在 theos 构建目录找
    DYLIB=$(find /var/theos -name "*.dylib" -path "*PowercutsClone*" -type f 2>/dev/null | head -1)
fi

if [ -z "$DYLIB" ]; then
    log_err "Compilation failed! No .dylib found."
    log_err "Trying debug build..."
    make DEBUG=0 2>&1 | tail -30
    DYLIB=$(find . -name "*.dylib" -type f 2>/dev/null | head -1)
fi

if [ -z "$DYLIB" ]; then
    log_err "Still no dylib. Check errors above."
    log_info "You may need SDK. Installing SDK..."
    # 尝试安装 SDK
    "$THEOS/bin/sdk" 2>/dev/null || true
    make 2>&1 | tail -20
    DYLIB=$(find . -name "*.dylib" -type f 2>/dev/null | head -1)
fi

if [ ! -z "$DYLIB" ]; then
    log_ok "Compiled: $DYLIB"
else
    log_err "Compilation FAILED. Please check the error output above."
    log_info "Possible fixes:"
    log_info "  1. Make sure you have internet connection"
    log_info "  2. Try running: $THEOS/bin/sdk"
    log_info "  3. Re-run this script"
    exit 1
fi

# ---- Step 5: 复制 dylib 到注入目录 ----
DST_DIR="/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$DST_DIR"
cp -f "$DYLIB" "$DST_DIR/PowercutsClone.dylib"
chmod 644 "$DST_DIR/PowercutsClone.dylib"
log_ok "Installed dylib to $DST_DIR/"

# ---- Step 6: 确保 plist 存在 ----
PLIST="$DST_DIR/PowercutsClone.plist"
if [ ! -f "$PLIST" ]; then
    echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "$PLIST"
fi
chmod 644 "$PLIST"
log_ok "Plist ready"

# ---- Step 7: 重启快捷指令 ----
log_info "Killing Shortcuts app..."
killall Shortcuts 2>/dev/null || true
sleep 1

echo ""
echo "=============================================="
log_ok "ALL DONE!"
echo "=============================================="
echo ""
echo "Now open the Shortcuts app and create a new shortcut."
echo "You should see these actions:"
echo "  - Run Shell Command"
echo "  - Respring Device"
echo "  - Send Notification"
echo "  - Set Badge Count"
echo "  - Unlock Device"
echo "  - Wake Screen"
echo "  - Set Brightness"
echo "  - Set Volume"
echo "  - Open URL"
echo "  - Get Clipboard"
echo "  - Set Clipboard"
echo "  - Vibrate Device"
echo "  - ... and more!"
echo ""
echo "Enjoy! :)"
echo ""
