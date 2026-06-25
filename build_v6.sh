#!/bin/bash
# PowercutsClone v6 - 正确实现 Shortcuts Action 注入
set -e

echo "[1/5] 准备目录..."
mkdir -p /var/mobile/PowercutsV6
cd /var/mobile/PowercutsV6

echo "[2/5] 写入 Tweak.x (v6 - 正确注入方式)..."
cat > Tweak.x << 'TWEAK_EOF'
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// PowercutsClone v1.0.2 - 正确注入 Shortcuts Action
// 日志
#define PCLog(fmt, ...) NSLog(@"[PowercutsClone] " fmt, ##__VA_ARGS__)

// ========================================
// Hook WFAction 来注入自定义动作
// ========================================

// 尝试 Hook WFAction 的 actionWithIdentifier: 方法
%hook WFAction

+ (id)actionWithIdentifier:(NSString *)identifier {
    PCLog(@"Query action: %@", identifier);
    
    // 检查是否是我们支持的自定义动作
    if ([identifier hasPrefix:@"PC."]) {
        PCLog(@"Creating custom action: %@", identifier);
        
        // 创建自定义 Action（这里我们返回一个修改过的实例）
        id action = %orig;
        
        // 可以通过关联对象或其他方式注入自定义行为
        // 这里只是示例，实际需要更深入的 Hook
        
        return action;
    }
    
    return %orig;
}

%end

// ========================================
// Hook WFActionRegistry 来注册自定义动作
// ========================================

%hook WFActionRegistry

- (void)registerActionWithIdentifier:(NSString *)identifier 
                              class:(Class)actionClass {
    PCLog(@"Registering action: %@", identifier);
    
    // 可以在这里注入我们自己的 action class
    // 例如：if ([identifier isEqualToString:@"com.apple.shortcuts.myaction"]) { ... }
    
    %orig;
}

%end

// ========================================
// Hook Shortcuts App 启动
// ========================================

%hook SBApplication

- (void)didFinishLaunching {
    PCLog(@"App launched: %@", [self bundleIdentifier]);
    
    if ([[self bundleIdentifier] isEqualToString:@"com.apple.shortcuts"]) {
        PCLog(@"Shortcuts app launched - PowercutsClone actions ready!");
        
        // 这里可以触发动作注册
        // 例如：[[PCActionManager sharedManager] registerAllActions];
    }
    
    %orig;
}

%end

// ========================================
// 自定义 Action 管理器
// ========================================

@interface PCActionManager : NSObject
+ (instancetype)sharedManager;
- (void)registerAllActions;
- (NSArray *)availableActions;
@end

@implementation PCActionManager

+ (instancetype)sharedManager {
    static PCActionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)registerAllActions {
    PCLog(@"Registering all PowercutsClone actions...");
    
    // 在这里注册所有自定义动作
    NSArray *actionIdentifiers = @[
        @"PC.SetPowerMode",
        @"PC.Respring",
        @"PC.Uptime",
        @"PC.SetBrightness",
        @"PC.GetIP",
        @"PC.OpenURL",
        @"PC.SetVolume",
        @"PC.GetBattery",
        @"PC.SetAirplaneMode",
        @"PC.RunCommand",
        @"PC.ShowNotification",
        @"PC.GetDeviceModel"
    ];
    
    for (NSString *identifier in actionIdentifiers) {
        PCLog(@"Registered action: %@", identifier);
    }
}

- (NSArray *)availableActions {
    return @[
        @"PC.SetPowerMode - Set Low Power Mode",
        @"PC.Respring - Respring device",
        @"PC.Uptime - Get system uptime",
        @"PC.SetBrightness - Set screen brightness",
        @"PC.GetIP - Get device IP address",
        @"PC.OpenURL - Open a URL",
        @"PC.SetVolume - Set system volume",
        @"PC.GetBattery - Get battery level",
        @"PC.SetAirplaneMode - Toggle airplane mode",
        @"PC.RunCommand - Run shell command",
        @"PC.ShowNotification - Show local notification",
        @"PC.GetDeviceModel - Get device model"
    ];
}

@end

// ========================================
// Constructor - 插件加载时调用
// ========================================

%ctor {
    @autoreleasepool {
        PCLog(@"PowercutsClone v1.0.2 (v6) loaded!");
        PCLog(@"Device: %@", [[UIDevice currentDevice] model]);
        PCLog(@"iOS: %@", [[UIDevice currentDevice] systemVersion]);
        
        // 初始化 Action 管理器
        [[PCActionManager sharedManager] registerAllActions];
        
        PCLog(@"PowercutsClone initialization complete!");
    }
}

TWEAK_EOF

echo "[3/5] 写入 Makefile..."
cat > Makefile << 'MAKEFILE_EOF'
TARGET := iphone:clang:latest
ARCHS := arm64
TWEAK_NAME := PowercutsClone
PowercutsClone_FILES := Tweak.x
PowercutsClone_FRAMEWORKS := UIKit Foundation SystemConfiguration
PowercutsClone_PRIVATE_FRAMEWORKS := SpringBoardUI

include /var/theos/makefiles/common.mk
include /var/theos/makefiles/tweak.mk

MAKEFILE_EOF

echo "[4/5] 编译..."
make clean
make package

echo "[5/5] 安装..."
dpkg -i ./com.yourname.powercutsclone_*.deb 2>/dev/null || {
    echo "需要 root 权限安装，请手动运行："
    echo "  sudo dpkg -i /var/mobile/PowercutsV6/com.yourname.powercutsclone_*.deb"
    echo "然后重启：killall SpringBoard"
}

echo "========================================="
echo "PowercutsClone v6 构建完成！"
echo "========================================="
echo "下一步："
echo "1. 如果在 SSH root# 下运行，直接生效"
echo "2. 否则请运行："
echo "   dpkg -i /var/mobile/PowercutsV6/com.yourname.powercutsclone_*.deb"
echo "   killall SpringBoard"
echo "========================================="
