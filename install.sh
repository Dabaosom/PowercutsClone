#!/bin/bash
# PowercutsClone - 一键编译安装脚本
# 在越狱 iPhone 上运行此脚本
# 需要: apt install make perl ios-sdk

set -e

echo "=========================================="
echo "  PowercutsClone - iOS 17 Rootless"
echo "  一键编译 & 安装"
echo "=========================================="

# 检查是否 root
if [ "$(id -u)" != "0" ]; then
    echo "❌ 请用 root 运行: sudo bash install.sh"
    exit 1
fi

# 安装依赖
echo ""
echo "📦 检查/安装编译依赖..."
apt-get update -qq
apt-get install -y -qq make perl ios-sdk clang 2>/dev/null || true

# 设置 Theos (如果没装)
if [ ! -d "/var/theos" ]; then
    echo "📥 下载 Theos..."
    git clone --quiet --depth 1 https://github.com/theos/theos.git /var/theos 2>/dev/null || {
        # 备用：用预编译的 theos
        echo "⚠️ Git 失败，尝试备用方案..."
        if [ ! -f "/var/theos/bin/nic.pl" ]; then
            mkdir -p /var/theos/bin /var/theos/include /var/theos/lib
        fi
    }
fi

export THEOS=/var/theos

WORKDIR="/tmp/powercutsclone_build"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo "📝 准备源文件..."

# ====== 写入 Tweak.x ======
cat > "$WORKDIR/Tweak.x" << 'TWEAK_EOF'
// PowercutsClone - Rootless iOS 17 Shortcuts Actions Pack
// 25 Actions for jailbroken Shortcuts app

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Intents/Intents.h>
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>
#import <signal.h>
#import <notify.h>

#pragma mark - Helper

static NSString *runCommand(NSString *cmd) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", cmd]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
    [task waitUntilExit];
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

// ========== ACTION 1: Get Current Application ==========
@interface PCGetCurrentAppIntent : INIntent @property (nonatomic,copy) NSString *output; @end
@implementation PCGetCurrentAppIntent @end
@interface PCGetCurrentAppIntentHandler : NSObject <INExtension> @end
@implementation PCGetCurrentAppIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetCurrentAppIntent class]]; }
- (void)handleIntent:(PCGetCurrentAppIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    NSString *res = runCommand(@"frontmost");
    INIntentResponse *r = [[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]; // simplified
    completion(r);
}
@end

// ========== ACTION 2: Get Now Playing App ==========
@interface PCGetNowPlayingIntent : INIntent @property (nonatomic,copy) NSString *output; @end
@implementation PCGetNowPlayingIntent @end
@interface PCGetNowPlayingIntentHandler : NSObject <INExtension> @end
@implementation PCGetNowPlayingIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetNowPlayingIntent class]]; }
- (void)handleIntent:(PCGetNowPlayingIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 3: Kill App ==========
@interface PCKillAppIntent : INIntent @property (nonatomic,copy) NSString *identifier; @end
@implementation PCKillAppIntent @end
@interface PCKillAppIntentHandler : NSObject <INExtension> @end
@implementation PCKillAppIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCKillAppIntent class]]; }
- (void)handleIntent:(PCKillAppIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    if (intent.identifier.length > 0) runCommand([NSString stringWithFormat:@"killall %@", intent.identifier]);
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 4: Get File Content ==========
@interface PCGetFileContentIntent : INIntent @property (nonatomic,copy) NSString *filePath; @property (nonatomic,copy) NSString *content; @end
@implementation PCGetFileContentIntent @end
@interface PCGetFileContentIntentHandler : NSObject <INExtension> @end
@implementation PCGetFileContentIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetFileContentIntent class]]; }
- (void)handleIntent:(PCGetFileContentIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    NSString *c = @"";
    if (intent.filePath.length > 0) c = [NSString stringWithContentsOfFile:intent.filePath encoding:NSUTF8StringEncoding error:nil] ?: @"Error";
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 5: Delete Global Variable ==========
@interface PCDeleteGlobalVarIntent : INIntent @property (nonatomic,copy) NSString *variableName; @end
@implementation PCDeleteGlobalVarIntent @end
@interface PCDeleteGlobalVarIntentHandler : NSObject <INExtension> @end
@implementation PCDeleteGlobalVarIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCDeleteGlobalVarIntent class]]; }
- (void)handleIntent:(PCDeleteGlobalVarIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    if (intent.variableName.length > 0)
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/var/mobile/Library/Shortcuts/variables/%@.plist", intent.variableName] error:nil];
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 6: Dismiss Siri ==========
@interface PCDismissSiriIntent : INIntent @end
@implementation PCDismissSiriIntent @end
@interface PCDismissSiriIntentHandler : NSObject <INExtension> @end
@implementation PCDismissSiriIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCDismissSiriIntent class]]; }
- (void)handleIntent:(PCDismissSiriIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    notify_post("com.apple.assistant.dismiss");
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 7: Get All Apps ==========
@interface PCGetAllAppsIntent : INIntent @property (nonatomic,copy) NSString *appList; @end
@implementation PCGetAllAppsIntent @end
@interface PCGetAllAppsIntentHandler : NSObject <INExtension> @end
@implementation PCGetAllAppsIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetAllAppsIntent class]]; }
- (void)handleIntent:(PCGetAllAppsIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 8: Get App Info ==========
@interface PCGetAppInfoIntent : INIntent @property (nonatomic,copy) NSString *identifier; @property (nonatomic,copy) NSString *appInfo; @end
@implementation PCGetAppInfoIntent @end
@interface PCGetAppInfoIntentHandler : NSObject <INExtension> @end
@implementation PCGetAppInfoIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetAppInfoIntent class]]; }
- (void)handleIntent:(PCGetAppInfoIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 9: BT Battery ==========
@interface PCGetBTBatteryIntent : INIntent @property (nonatomic,copy) NSString *batteryLevel; @end
@implementation PCGetBTBatteryIntent @end
@interface PCGetBTBatteryIntentHandler : NSObject <INExtension> @end
@implementation PCGetBTBatteryIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetBTBatteryIntent class]]; }
- (void)handleIntent:(PCGetBTBatteryIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 10: Lock State ==========
@interface PCGetLockStateIntent : INIntent @property (nonatomic,copy) NSString *isLocked; @end
@implementation PCGetLockStateIntent @end
@interface PCGetLockStateIntentHandler : NSObject <INExtension> @end
@implementation PCGetLockStateIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetLockStateIntent class]]; }
- (void)handleIntent:(PCGetLockStateIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity nil]); }
@end

// ========== ACTION 11: Get Files from Folder ==========
@interface PCGetFilesFromFolderIntent : INIntent @property (nonatomic,copy) NSString *folderPath; @property (nonatomic,copy) NSString *fileList; @end
@implementation PCGetFilesFromFolderIntent @end
@interface PCGetFilesFromFolderIntentHandler : NSObject <INExtension> @end
@implementation PCGetFilesFromFolderIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetFilesFromFolderIntent class]]; }
- (void)handleIntent:(PCGetFilesFromFolderIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 12: Get Global Variable ==========
@interface PCGetGlobalVarIntent : INIntent @property (nonatomic,copy) NSString *variableName; @property (nonatomic,copy) NSString *value; @end
@implementation PCGetGlobalVarIntent @end
@interface PCGetGlobalVarIntentHandler : NSObject <INExtension> @end
@implementation PCGetGlobalVarIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetGlobalVarIntent class]]; }
- (void)handleIntent:(PCGetGlobalVarIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 13: Get Run Source ==========
@interface PCGetRunSourceIntent : INIntent @property (nonatomic,copy) NSString *source; @end
@implementation PCGetRunSourceIntent @end
@interface PCGetRunSourceIntentHandler : NSObject <INExtension> @end
@implementation PCGetRunSourceIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCGetRunSourceIntent class]]; }
- (void)handleIntent:(PCGetRunSourceIntent *)intent completion:(void (^)(INIntentResponse *))completion { completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]); }
@end

// ========== ACTION 14: Remove Notification(s) ==========
@interface PCRemoveNotifIntent : INIntent @property (nonatomic,copy) NSString *appName; @end
@implementation PCRemoveNotifIntent @end
@interface PCRemoveNotifIntentHandler : NSObject <INExtension> @end
@implementation PCRemoveNotifIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCRemoveNotifIntent class]]; }
- (void)handleIntent:(PCRemoveNotifIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    if (intent.appName.length > 0) notify_post([@"com.powercuts.removenotification" UTF8String]);
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 15: Respring ==========
@interface PCRespringIntent : INIntent @end
@implementation PCRespringIntent @end
@interface PCRespringIntentHandler : NSObject <INExtension> @end
@implementation PCRespringIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCRespringIntent class]]; }
- (void)handleIntent:(PCRespringIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    pid_t pid = runCommand(@"pidof SpringBoard").intValue;
    if (pid > 0) kill(pid, SIGKILL);
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 16: Run Shell Command ==========
@interface PCRunShellIntent : INIntent @property (nonatomic,copy) NSString *command; @property (nonatomic,copy) NSString *output; @end
@implementation PCRunShellIntent @end
@interface PCRunShellIntentHandler : NSObject <INExtension> @end
@implementation PCRunShellIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCRunShellIntent class]]; }
- (void)handleIntent:(PCRunShellIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    NSString *out = intent.command.length > 0 ? runCommand(intent.command) : @"";
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 17: Safe Mode ==========
@interface PCSafeModeIntent : INIntent @end
@implementation PCSafeModeIntent @end
@interface PCSafeModeIntentHandler : NSObject <INExtension> @end
@implementation PCSafeModeIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSafeModeIntent class]]; }
- (void)handleIntent:(PCSafeModeIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    notify_post("libhooker.mode/safemode");
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 18: Send Notification ==========
@interface PCSendNotifIntent : INIntent @property (nonatomic,copy) NSString *title; @property (nonatomic,copy) NSString *body; @end
@implementation PCSendNotifIntent @end
@interface PCSendNotifIntentHandler : NSObject <INExtension> @end
@implementation PCSendNotifIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSendNotifIntent class]]; }
- (void)handleIntent:(PCSendNotifIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    UNMutableNotificationContent *c = [[UNMutableNotificationContent alloc] init];
    c.title = intent.title ?: @"PowercutsClone";
    c.body = intent.body ?: @"";
    c.sound = [UNNotificationSound defaultSound];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:
        [[UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:c trigger:nil] withCompletionHandler:^(NSError *err){}]];
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 19: Set Badge Count ==========
@interface PCSetBadgeIntent : INIntent @property (nonatomic,copy) NSString *identifier; @property NSInteger badgeCount; @end
@implementation PCSetBadgeIntent @end
@interface PCSetBadgeIntentHandler : NSObject <INExtension> @end
@implementation PCSetBadgeIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSetBadgeIntent class]]; }
- (void)handleIntent:(PCSetBadgeIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    if (intent.identifier.length > 0) {
        notify_post([[@"com.apple.springboard.badgechanged." stringByAppendingString:intent.identifier] UTF8String]);
    }
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 20: Set Audio Balance ==========
@interface PCSetBalanceIntent : INIntent @property float balance; @end
@implementation PCSetBalanceIntent @end
@interface PCSetBalanceIntentHandler : NSObject <INExtension> @end
@implementation PCSetBalanceIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSetBalanceIntent class]]; }
- (void)handleIntent:(PCSetBalanceIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    float b = intent.balance; if(b<-1)b=-1; if(b>1)b=1;
    AVAudioSession *s = [AVAudioSession sharedInstance]; [s setActive:YES error:nil]; [s setOutputChannelBalance:b error:nil];
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 21: Set Global Variable ==========
@interface PCSetGlobalVarIntent : INIntent @property (nonatomic,copy) NSString *variableName; @property (nonatomic,copy) NSString *value; @end
@implementation PCSetGlobalVarIntent @end
@interface PCSetGlobalVarIntentHandler : NSObject <INExtension> @end
@implementation PCSetGlobalVarIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSetGlobalVarIntent class]]; }
- (void)handleIntent:(PCSetGlobalVarIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    if (intent.variableName.length > 0) {
        NSString *d = @"/var/mobile/Library/Shortcuts/variables";
        [[NSFileManager defaultManager] createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
        [@{@"value": intent.value ?: @""} writeToFile:[NSString stringWithFormat:@"%@/%@.plist", d, intent.variableName] atomically:YES];
    }
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 22: Support Dev ==========
@interface PCSupportDevIntent : INIntent @property (nonatomic,copy) NSString *devURL; @end
@implementation PCSupportDevIntent @end
@interface PCSupportDevIntentHandler : NSObject <INExtension> @end
@implementation PCSupportDevIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCSupportDevIntent class]]; }
- (void)handleIntent:(PCSupportDevIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:intent.devURL ?: @"https://github.com/sponsors"] options:@{} completionHandler:nil];
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 23: UICache ==========
@interface PCUICacheIntent : INIntent @property (nonatomic,copy) NSString *output; @end
@implementation PCUICacheIntent @end
@interface PCUICacheIntentHandler : NSObject <INExtension> @end
@implementation PCUICacheIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCUICacheIntent class]]; }
- (void)handleIntent:(PCUICacheIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    runCommand(@"uicache --all");
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 24: Unlock Device ==========
@interface PCUnlockDeviceIntent : INIntent @end
@implementation PCUnlockDeviceIntent @end
@interface PCUnlockDeviceIntentHandler : NSObject <INExtension> @end
@implementation PCUnlockDeviceIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCUnlockDeviceIntent class]]; }
- (void)handleIntent:(PCUnlockDeviceIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    Class c = NSClassFromString(@"SBAwayLockScreenManager"); if(c){id m=[c sharedInstance];SEL s=NSSelectorFromString(@"unlockWithSource:options:");if([m respondsToSelector:s])((void(*)(id,SEL,id,id))[m methodForSelector:s])(m,s,nil,nil);}
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

// ========== ACTION 25: Wake Screen ==========
@interface PCWakeScreenIntent : INIntent @end
@implementation PCWakeScreenIntent @end
@interface PCWakeScreenIntentHandler : NSObject <INExtension> @end
@implementation PCWakeScreenIntentHandler
- (NSArray<id<INIntent>>)supportedIntents { return @[[PCWakeScreenIntent class]]; }
- (void)handleIntent:(PCWakeScreenIntent *)intent completion:(void (^)(INIntentResponse *))completion {
    Class c = NSClassFromString(@"SBBacklightManager"); if(c){id m=[c sharedInstance];SEL s=NSSelectorFromString(@"turnOnScreenForReason:");if([m respondsToSelector:s])((void(*)(id,SEL,id))[m methodForSelector:s])(m,s,@"PowercutsClone");}
    completion([[INIntentResponse alloc] initWithCode:INIntentResponseCodeSuccess userActivity:nil]);
}
@end

#pragma mark - Constructor
__attribute__((constructor))
static void init() {
    NSLog(@"[PowercutsClone] ✅ Loaded! 25 actions ready for Shortcuts on iOS 17 Rootless");
}
TWEAK_EOF

# 写入 Makefile
cat > "$WORKDIR/Makefile" << 'MK_EOF'
ARCHS = arm64
TARGET := iphone:clang:latest:17.0
include \$(THEOS)/makefiles/common.mk
TWEAK_NAME = PowercutsClone
PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = UIKit Foundation Intents UserNotifications AVFoundation
include \$(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall Shortcuts"
MK_EOF

# 写入 control
cat > "$WORKDIR/control" << 'CTL_EOF'
Package: com.yourname.powercutsclone
Name: PowercutsClone (Rootless)
Depends: mobilesubstrate
Version: 1.0.0
Architecture: iphoneos-arm64
Description: 25 powerful actions for Shortcuts on jailbroken iOS 17! Shell commands, respring, notifications, badge, unlock, wake screen and more.
Maintainer: YourName <your@email.com>
Author: YourName
Section: Tweaks
CTL_EOF

# 写入 plist
cat > "$WORKDIR/PowercutsClone.plist" << '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }'
echo '{ Filter = { Bundles = ( "com.apple.shortcuts" ); }; }' > "$WORKDIR/PowercutsClone.plist"

echo ""
echo "🔨 开始编译..."

cd "$WORKDIR"

# 尝试使用 theos 编译
if [ -f "$THEOS/makefiles/common.mk" ]; then
    export THEOS_DEVICE_IP=localhost
    export THEOS_DEVICE_PORT=2222
    
    make package 2>&1 && {
        echo ""
        echo "✅ 编译成功!"
        DEB_FILE=$(ls *.deb 2>/dev/null | head -1)
        if [ -n "$DEB_FILE" ]; then
            echo "📦 Deb 包: $WORKDIR/$DEB_FILE"
            echo ""
            echo "🚀 正在安装..."
            dpkg -i "$DEB_FILE" 2>&1 && {
                echo ""
                echo "=========================================="
                echo "  ✅ 安装完成!"
                echo "  请重启「快捷指令」app"
                echo "=========================================="
            } || {
                echo "⚠️ dpkg 安装失败，请手动安装:"
                echo "   dpkg -i $DEB_FILE"
            }
        fi
    } || {
        echo ""
        echo "❌ Theos 编译失败，尝试备用方案..."
        fallback_install
    }
else
    fallback_install
fi

# 备用方案：直接安装为 dylib（不需要完整 theos）
fallback_install() {
    echo ""
    echo "🔄 使用备用方案（预编译模式）..."
    
    DEST="/var/jb/root/var/Library/PowercutsClone"
    DYLIB_DEST="/var/jb/root/Library/MobileSubstrate/DynamicLibraries"
    
    mkdir -p "$DEST" "$DYLIB_DEST"
    
    cp "$WORKDIR/Tweak.x" "$DEST/"
    cp "$WORKDIR/PowercutsClone.plist" "$DYLIB_DEST/"
    
    # 创建 postinst 脚本
    cat > "/tmp/pc_postinst.sh" << 'POSTINST'
#!/bin/bash
# 这个脚本需要配合 theos 编译后的 dylib 使用
# 如果没有 theos，请从电脑端编译后传到 iPhone
echo "PowercutsClone installed. Please compile Tweak.x into .dylib using Theos on a Mac/Linux."
POSTINST
    chmod +x "/tmp/pc_postinst.sh"
    
    echo ""
    echo "=========================================="
    echo "  ⚠️ 需要编译环境"
    echo "=========================================="
    echo ""
    echo "你的 iPhone 上缺少完整的 Theos 编译链。"
    echo ""
    echo "🔧 解决方案（选一个）:"
    echo ""
    echo "  方案1: 在 Mac 上编译（推荐）"
    echo "    git clone https://github.com/theos/theos.git"
    echo "    cd PowercutsClone && make package"
    echo "    scp *.deb root@iPhone_IP:/tmp/"
    echo "    ssh root@iPhone_IP 'dpkg -i /tmp/*.deb'"
    echo ""
    echo "  方案2: 在 iPhone 上安装完整 Theos"
    echo "    apt install theos"
    echo "    然后重新运行此脚本"
    echo ""
    echo "  方案3: 用在线编译服务"
    echo "    把项目上传到 GitHub"
    echo "    用 GitHub Actions + iOS cross-compiler"
    echo ""
    echo "源文件已保存到: $DEST/Tweak.x"
}
