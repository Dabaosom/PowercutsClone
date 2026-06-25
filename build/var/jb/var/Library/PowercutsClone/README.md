# PowercutsClone - Rootless iOS 17 Shortcuts Actions Pack

## 简介
类似 AnthoPak 的 Powercuts Actions Pack，为 iOS 17 越狱设备（Bootstrap/Dopamine）的快捷指令（Shortcuts）提供额外的 Action。

## 功能列表（共 25 个 Action）

| # | Action | 说明 |
|---|--------|------|
| 1 | Get Current Application | 获取当前前台应用 |
| 2 | Get Now Playing Application | 获取正在播放的应用 |
| 3 | Kill/Quit Application | 强制关闭指定应用 |
| 4 | Get File Content | 读取文件内容 |
| 5 | Delete Global Variable | 删除快捷指令全局变量 |
| 6 | Dismiss Siri | 关闭 Siri |
| 7 | Get All Installed Applications | 获取所有已安装应用 |
| 8 | Get Application Info from Identifier | 根据Bundle ID获取应用信息 |
| 9 | Get Bluetooth Device Battery Level | 获取蓝牙设备电量 |
| 10 | Get Device Locked State | 获取设备锁定状态 |
| 11 | Get Files from Folder | 获取文件夹内文件列表 |
| 12 | Get Global Variable | 获取全局变量值 |
| 13 | Get Run Source | 获取快捷指令运行来源 |
| 14 | Remove notification(s) | 清除指定应用通知 |
| 15 | Respring | 重启 SpringBoard |
| 16 | Run shell command | 执行任意 Shell 命令 |
| 17 | Safe mode | 进入安全模式 |
| 18 | Send notification (from app) | 发送本地通知 |
| 19 | Set application badge count | 设置应用角标数 |
| 20 | Set audio balance | 设置左右声道平衡 |
| 21 | Set global variable | 设置全局变量值 |
| 22 | Support the dev | 打开开发者赞助链接 |
| 23 | UICache | 刷新图标缓存 |
| 24 | Unlock device | 解锁设备 |
| 25 | Wake screen | 唤醒屏幕 |

## 编译环境要求

- **Theos** (最新版)
- **iOS SDK** (支持 rootless)
- **Xcode** (命令行工具)
- **Bootstrap/Dopamine** 越狱

## 安装方法

### 方法一：本地编译
```bash
# 在 Mac/Linux 上安装 Theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# 进入项目目录
cd PowercutsClone

# 编译
make package

# 安装到设备
make install THEOS_DEVICE_IP=localhost THEOS_DEVICE_PORT=2222
```

### 方法二：直接安装 deb 包
编译后生成 `com.yourname.powercutsclone_1.0.0_iphoneos-arm64.deb`，通过 Sileo/Zebra 安装。

## 使用方法

1. 安装插件后，重启 Shortcuts 应用
2. 打开快捷指令编辑器
3. 在 Apps 分类下找到 **PowercutsClone** 相关的 Action
4. 将 Action 拖入你的快捷指令中使用

## 注意事项

- ⚠️ 仅适用于 **rootless** 越狱（Dopamine/Palera1n）
- ⚠️ 需要安装 **mobilesubstrate** 或 **libhooker**
- ⚠️ 部分功能需要 root 权限
- ⚠️ iOS 17+ 兼容

## 自定义修改

- 修改 `control` 文件中的包名和作者信息
- 在 `Tweak.x` 中添加新的 Intent 类即可扩展更多 Action
- 修改 `PowercutsClone.plist` 调整注入目标

## License

MIT License - Free to use and modify!
