import os, hashlib, gzip, tarfile, struct, time, shutil

base = r"C:\Users\Administrator\Desktop\PowercutsClone"
build = os.path.join(base, "build")

# 清理重建
if os.path.exists(build):
    shutil.rmtree(build)

# Rootless 路径
dirs = [
    "DEBIAN",
    os.path.join("var", "jb", "Library", "MobileSubstrate", "DynamicLibraries"),
    os.path.join("var", "jb", "var", "Library", "PowercutsClone"),
]
for d in dirs:
    os.makedirs(os.path.join(build, d), exist_ok=True)

# control 文件
control_text = """Package: com.yourname.powercutsclone
Name: PowercutsClone (Rootless)
Depends: mobilesubstrate
Version: 1.0.1
Architecture: iphoneos-arm64
Description: Pack of actions for the Shortcuts app on jailbroken iOS 17 (Rootless). 25 powerful actions including shell commands, respring, notifications, badge control, unlock, wake screen and more!
Maintainer: YourName <your@email.com>
Author: YourName
Section: Tweaks
"""
with open(os.path.join(build, "DEBIAN", "control"), "w", encoding="utf-8") as f:
    f.write(control_text)

# plist - 注入到 Shortcuts
plist_content = '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }'
plist_path = os.path.join(build, "var", "jb", "Library", "MobileSubstrate", "DynamicLibraries", "PowercutsClone.plist")
with open(plist_path, "w") as f:
    f.write(plist_content)

# 复制源文件到 iPhone 上的编译目录
tweak_dst = os.path.join(build, "var", "jb", "var", "Library", "PowercutsClone")
for fn in ["Tweak.x", "Makefile", "README.md"]:
    src = os.path.join(base, fn)
    if os.path.exists(src):
        shutil.copy2(src, os.path.join(tweak_dst, fn))

print("OK dirs ready")

# === data.tar.gz ===
data_path = os.path.join(build, "data.tar.gz")
with tarfile.open(data_path, "w:gz") as tar:
    for root, dirs, files in os.walk(build):
        rel = os.path.relpath(root, build)
        if rel.startswith("DEBIAN") or rel == ".":
            if rel.startswith("DEBIAN"):
                dirs.clear()
            continue
        for fn in files:
            full = os.path.join(root, fn)
            arcname = os.path.join(rel, fn) if rel != "." else fn
            tar.add(full, arcname=arcname)
print(f"data.tar.gz: {os.path.getsize(data_path)} bytes")

# === control.tar.gz ===
ctl_path = os.path.join(build, "control.tar.gz")
debdir = os.path.join(build, "DEBIAN")
with tarfile.open(ctl_path, "w:gz") as tar:
    for fn in os.listdir(debdir):
        full = os.path.join(debdir, fn)
        info = tar.gettarinfo(full, arcname=fn)
        tar.add(full, arcname=fn)
print(f"control.tar.gz: {os.path.getsize(ctl_path)} bytes")

# === debian-binary ===
bin_path = os.path.join(build, "debian-binary")
with open(bin_path, "wb") as f:
    f.write(b"2.0\n")

# === 组装 .deb ===
deb_out = os.path.join(base, "com.yourname.powercutsclone_1.0.1_iphoneos-arm64.deb")

def ar_header(name, size):
    name_bytes = name.encode()[:16].ljust(16)
    mtime = str(int(time.time())).encode()[:12].ljust(12)
    uid = b'0'.ljust(6)
    gid = b'0'.ljust(6)
    mode = b'100644'.ljust(8)
    size_str = str(size).encode().ljust(10)
    fmag = b'`\n'
    return name_bytes + mtime + uid + gid + mode + size_str + fmag

with open(deb_out, "wb") as f:
    f.write(b"!<arch>\n")
    
    with open(bin_path, "rb") as bf:
        bd = bf.read()
    f.write(ar_header("debian-binary", len(bd)))
    f.write(bd)
    if len(bd) % 2:
        f.write(b"\n")
    
    with open(ctl_path, "rb") as cf:
        cd = cf.read()
    f.write(ar_header("control.tar.gz", len(cd)))
    f.write(cd)
    if len(cd) % 2:
        f.write(b"\n")
    
    with open(data_path, "rb") as df:
        dd = df.read()
    f.write(ar_header("data.tar.gz", len(dd)))
    f.write(dd)
    if len(dd) % 2:
        f.write(b"\n")

deb_size = os.path.getsize(deb_out)
print(f"\nDEB OK!")
print(f"File: {deb_out}")
print(f"Size: {deb_size:,} bytes ({deb_size/1024:.1f} KB)")
