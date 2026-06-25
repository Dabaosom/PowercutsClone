#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ========================================
// PowercutsClone - iOS 17 Shortcuts Actions
// 正确方式：Hook WFAction 来注册自定义动作
// ========================================

// 日志宏
#define PCLog(fmt, ...) NSLog(@"[PowercutsClone] " fmt, ##__VA_ARGS__)

// ========================================
// 自定义 Action 基类
// ========================================

@interface PCBaseAction : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
- (void)runWithCompletion:(void (^)(id result, NSError *error))completion;
@end

@implementation PCBaseAction
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    completion(nil, nil);
}
@end

// ========================================
// 12 个自定义 Action 实现
// ========================================

// 1. Set Power Mode (省电模式)
@interface PCSetPowerModeAction : PCBaseAction
@end
@implementation PCSetPowerModeAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCSetPowerMode";
        _name = @"Set Power Mode";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    // 切换省电模式
    @try {
        __block BOOL currentMode = NO;
        if ([NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)]) {
            currentMode = [[NSProcessInfo processInfo] isLowPowerModeEnabled];
        }
        BOOL newMode = !currentMode;
        
        // 通过 libMobileGestalt 或直接写设置
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/pmset";
        task.arguments = @[@"-a", @"lowpower", newMode ? @"1" : @"0"];
        [task launch];
        [task waitUntilExit];
        
        PCLog(@"Power mode set to: %@", newMode ? @"LOW" : @"NORMAL");
    } @catch (NSException *e) {
        PCLog(@"Error setting power mode: %@", e);
    }
    completion(@YES, nil);
}
@end

// 2. Respring
@interface PCRespringAction : PCBaseAction
@end
@implementation PCRespringAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCRespring";
        _name = @"Respring";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"Triggering Respring...");
    @try {
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/killall";
        task.arguments = @[@"SpringBoard"];
        [task launch];
    } @catch (NSException *e) {
        PCLog(@"Error respringing: %@", e);
    }
    completion(@YES, nil);
}
@end

// 3. Uptime
@interface PCUptimeAction : PCBaseAction
@end
@implementation PCUptimeAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCUptime";
        _name = @"Get Uptime";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        struct timespec boottime;
        size_t len = sizeof(boottime);
        sysctlbyname("kern.boottime", &boottime, &len, NULL, 0);
        NSDate *bootDate = [NSDate dateWithTimeIntervalSince1970:boottime.tv_sec];
        NSTimeInterval uptime = [[NSDate date] timeIntervalSinceDate:bootDate];
        PCLog(@"Uptime: %.0f seconds", uptime);
        completion([NSNumber numberWithDouble:uptime], nil);
    } @catch (NSException *e) {
        completion(@0, nil);
    }
}
@end

// 4. Set Brightness
@interface PCSetBrightnessAction : PCBaseAction
@end
@implementation PCSetBrightnessAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCSetBrightness";
        _name = @"Set Brightness";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        // 获取主屏幕
        id screen = [UIScreen mainScreen];
        if ([screen respondsToSelector:@selector(setBrightness:)]) {
            CGFloat brightness = 0.5; // 默认 50%，可以从参数获取
            [screen setBrightness:brightness];
            PCLog(@"Brightness set to: %.0f%%", brightness * 100);
        }
    } @catch (NSException *e) {
        PCLog(@"Error setting brightness: %@", e);
    }
    completion(@YES, nil);
}
@end

// 5. Get IP Address
@interface PCGetIPAction : PCBaseAction
@end
@implementation PCGetIPAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCGetIP";
        _name = @"Get IP Address";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        NSString *ip = @"127.0.0.1";
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = getifaddrs(&interfaces);
        if (success == 0) {
            temp_addr = interfaces;
            while (temp_addr != NULL) {
                if (temp_addr->ifa_addr->sa_family == AF_INET) {
                    NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    if ([name isEqualToString:@"en0"]) {
                        ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                        break;
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        freeifaddrs(interfaces);
        PCLog(@"IP Address: %@", ip);
        completion(ip, nil);
    } @catch (NSException *e) {
        completion(@"Unknown", nil);
    }
}
@end

// 6. OpenURL
@interface PCOpenURLAction : PCBaseAction
@end
@implementation PCOpenURLAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCOpenURL";
        _name = @"Open URL";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            PCLog(@"Opened URL: %@", url);
        }
    } @catch (NSException *e) {
        PCLog(@"Error opening URL: %@", e);
    }
    completion(@YES, nil);
}
@end

// 7. Set Volume
@interface PCSetVolumeAction : PCBaseAction
@end
@implementation PCSetVolumeAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCSetVolume";
        _name = @"Set Volume";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        // 使用 MediaPlayer 框架
        Class mpVolume = NSClassFromString(@"MPVolumeView");
        if (mpVolume) {
            PCLog(@"Setting volume...");
            // 实际实现需要通过私有 API 或 MediaPlayer
        }
    } @catch (NSException *e) {
        PCLog(@"Error setting volume: %@", e);
    }
    completion(@YES, nil);
}
@end

// 8. Get Battery Level
@interface PCGetBatteryAction : PCBaseAction
@end
@implementation PCGetBatteryAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCGetBattery";
        _name = @"Get Battery Level";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        UIDevice *device = [UIDevice currentDevice];
        [device setBatteryMonitoringEnabled:YES];
        float level = device.batteryLevel * 100.0;
        PCLog(@"Battery level: %.0f%%", level);
        completion([NSNumber numberWithFloat:level], nil);
    } @catch (NSException *e) {
        completion(@0, nil);
    }
}
@end

// 9. Set Airplane Mode
@interface PCSetAirplaneModeAction : PCBaseAction
@end
@implementation PCSetAirplaneModeAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCSetAirplaneMode";
        _name = @"Set Airplane Mode";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"Airplane Mode toggle requested");
    // 需要私有框架，这里只是占位
    completion(@YES, nil);
}
@end

// 10. Run Command
@interface PCRunCommandAction : PCBaseAction
@end
@implementation PCRunCommandAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCRunCommand";
        _name = @"Run Command";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/ls";
        task.arguments = @[@@"/var/mobile"];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        [task launch];
        [task waitUntilExit];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        PCLog(@"Command output: %@", output);
        completion(output, nil);
    } @catch (NSException *e) {
        completion(@"Error", nil);
    }
}
@end

// 11. Show Notification
@interface PCShowNotificationAction : PCBaseAction
@end
@implementation PCShowNotificationAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCShowNotification";
        _name = @"Show Notification";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        if (notif) {
            notif.alertBody = @"PowercutsClone Action Triggered!";
            notif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
            PCLog(@"Notification shown");
        }
    } @catch (NSException *e) {
        PCLog(@"Error showing notification: %@", e);
    }
    completion(@YES, nil);
}
@end

// 12. Get Device Model
@interface PCGetDeviceModelAction : PCBaseAction
@end
@implementation PCGetDeviceModelAction
- (id)init {
    if (self = [super init]) {
        _identifier = @"PCGetDeviceModel";
        _name = @"Get Device Model";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    @try {
        NSString *model = [[UIDevice currentDevice] model];
        PCLog(@"Device model: %@", model);
        completion(model, nil);
    } @catch (NSException *e) {
        completion(@"Unknown", nil);
    }
}
@end

// ========================================
// Hook WFActionProvider 来注册自定义动作
// ========================================

%ctor {
    PCLog(@"PowercutsClone v1.0.2 loaded!");
    
    // 创建所有 Action 实例
    NSArray *actions = @[
        [[PCSetPowerModeAction alloc] init],
        [[PCRespringAction alloc] init],
        [[PCUptimeAction alloc] init],
        [[PCSetBrightnessAction alloc] init],
        [[PCGetIPAction alloc] init],
        [[PCOpenURLAction alloc] init],
        [[PCSetVolumeAction alloc] init],
        [[PCGetBatteryAction alloc] init],
        [[PCSetAirplaneModeAction alloc] init],
        [[PCRunCommandAction alloc] init],
        [[PCShowNotificationAction alloc] init],
        [[PCGetDeviceModelAction alloc] init]
    ];
    
    // 保存到全局字典
    NSMutableDictionary *actionDict = [NSMutableDictionary dictionary];
    for (PCBaseAction *action in actions) {
        [actionDict setObject:action forKey:action.identifier];
    }
    
    // 导出到全局（供 Shortcuts 调用）
    objc_setAssociatedObject([NSObject class], "PCActions", actionDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    PCLog(@"Registered %lu custom actions", (unsigned long)actions.count);
}

// ========================================
// Hook WFAction (Shortcuts 的 Action 类)
// ========================================

%hook WFAction

// 尝试 Hook actionWithIdentifier: 来注入我们的自定义动作
+ (id)actionWithIdentifier:(NSString *)identifier {
    PCLog(@"Looking for action: %@", identifier);
    
    // 检查是否是我们的自定义动作
    NSDictionary *actions = objc_getAssociatedObject([NSObject class], "PCActions");
    if (actions[identifier]) {
        PCLog(@"Found custom action: %@", identifier);
        // 返回我们的自定义 Action
        return actions[identifier];
    }
    
    return %orig;
}

%end

// ========================================
// Hook WFActionRegistry (动作注册表)
// ========================================

%hook WFActionRegistry

- (void)registerActionWithIdentifier:(NSString *)identifier class:(Class)actionClass {
    PCLog(@"Registering action: %@", identifier);
    %orig;
}

%end

// ========================================
// Constructor
// ========================================

%ctor {
    @autoreleasepool {
        PCLog(@"PowercutsClone v1.0.2 initialized");
        PCLog(@"Device: %@", [[UIDevice currentDevice] model]);
        PCLog(@"iOS: %@", [[UIDevice currentDevice] systemVersion]);
    }
}
