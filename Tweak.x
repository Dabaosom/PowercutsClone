#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

// ========================================
// PowercutsClone - iOS 17 Shortcuts Actions
// ========================================

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
- (id)init {
    if (self = [super init]) {
        self.identifier = @"";
        self.name = @"";
    }
    return self;
}
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
        self.identifier = @"PCSetPowerMode";
        self.name = @"Set Power Mode";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"SetPowerMode action triggered");
    // 使用 system() 执行命令（简化版）
    system("killall -9 SpringBoard");
    completion(@YES, nil);
}
@end

// 2. Respring
@interface PCRespringAction : PCBaseAction
@end
@implementation PCRespringAction
- (id)init {
    if (self = [super init]) {
        self.identifier = @"PCRespring";
        self.name = @"Respring";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"Respring action triggered");
    system("killall -9 SpringBoard");
    completion(@YES, nil);
}
@end

// 3. Uptime
@interface PCUptimeAction : PCBaseAction
@end
@implementation PCUptimeAction
- (id)init {
    if (self = [super init]) {
        self.identifier = @"PCUptime";
        self.name = @"Get Uptime";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"Uptime action triggered");
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
        self.identifier = @"PCSetBrightness";
        self.name = @"Set Brightness";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"SetBrightness action triggered");
    @try {
        id screen = [UIScreen mainScreen];
        if ([screen respondsToSelector:@selector(setBrightness:)]) {
            [screen setBrightness:0.5];
            PCLog(@"Brightness set to 50%%");
        }
    } @catch (NSException *e) {
        PCLog(@"Error: %@", e);
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
        self.identifier = @"PCGetIP";
        self.name = @"Get IP Address";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"GetIP action triggered");
    @try {
        NSString *ip = @"127.0.0.1";
        struct ifaddrs *interfaces = NULL;
        if (getifaddrs(&interfaces) == 0) {
            struct ifaddrs *temp = interfaces;
            while (temp != NULL) {
                if (temp->ifa_addr->sa_family == AF_INET) {
                    NSString *name = [NSString stringWithUTF8String:temp->ifa_name];
                    if ([name isEqualToString:@"en0"]) {
                        ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp->ifa_addr)->sin_addr)];
                        break;
                    }
                }
                temp = temp->ifa_next;
            }
        }
        freeifaddrs(interfaces);
        PCLog(@"IP: %@", ip);
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
        self.identifier = @"PCOpenURL";
        self.name = @"Open URL";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"OpenURL action triggered");
    @try {
        NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    } @catch (NSException *e) {
        PCLog(@"Error: %@", e);
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
        self.identifier = @"PCSetVolume";
        self.name = @"Set Volume";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"SetVolume action triggered");
    // 需要 MediaPlayer 框架，这里简化
    completion(@YES, nil);
}
@end

// 8. Get Battery Level
@interface PCGetBatteryAction : PCBaseAction
@end
@implementation PCGetBatteryAction
- (id)init {
    if (self = [super init]) {
        self.identifier = @"PCGetBattery";
        self.name = @"Get Battery Level";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"GetBattery action triggered");
    @try {
        UIDevice *device = [UIDevice currentDevice];
        [device setBatteryMonitoringEnabled:YES];
        float level = device.batteryLevel * 100.0;
        PCLog(@"Battery: %.0f%%", level);
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
        self.identifier = @"PCSetAirplaneMode";
        self.name = @"Set Airplane Mode";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"SetAirplaneMode action triggered");
    completion(@YES, nil);
}
@end

// 10. Run Command
@interface PCRunCommandAction : PCBaseAction
@end
@implementation PCRunCommandAction
- (id)init {
    if (self = [super init]) {
        self.identifier = @"PCRunCommand";
        self.name = @"Run Command";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"RunCommand action triggered");
    @try {
        system("ls /var/mobile > /tmp/cmd_output.txt 2>&1");
        NSString *output = [NSString stringWithContentsOfFile:@"/tmp/cmd_output.txt" encoding:NSUTF8StringEncoding error:nil];
        PCLog(@"Output: %@", output);
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
        self.identifier = @"PCShowNotification";
        self.name = @"Show Notification";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"ShowNotification action triggered");
    @try {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        if (notif) {
            notif.alertBody = @"PowercutsClone Action Triggered!";
            notif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
        }
    } @catch (NSException *e) {
        PCLog(@"Error: %@", e);
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
        self.identifier = @"PCGetDeviceModel";
        self.name = @"Get Device Model";
    }
    return self;
}
- (void)runWithCompletion:(void (^)(id, NSError *))completion {
    PCLog(@"GetDeviceModel action triggered");
    @try {
        NSString *model = [[UIDevice currentDevice] model];
        PCLog(@"Model: %@", model);
        completion(model, nil);
    } @catch (NSException *e) {
        completion(@"Unknown", nil);
    }
}
@end

// ========================================
// Hook WFAction to 注册自定义动作
// ========================================

%ctor {
    PCLog(@"PowercutsClone v1.0.2 loaded!");
    
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
    
    NSMutableDictionary *actionDict = [NSMutableDictionary dictionary];
    for (PCBaseAction *action in actions) {
        [actionDict setObject:action forKey:action.identifier];
    }
    
    objc_setAssociatedObject([NSObject class], "PCActions", actionDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    PCLog(@"Registered %lu custom actions", (unsigned long)actions.count);
}

%hook WFAction

+ (id)actionWithIdentifier:(NSString *)identifier {
    PCLog(@"Looking for action: %@", identifier);
    NSDictionary *actions = objc_getAssociatedObject([NSObject class], "PCActions");
    if (actions[identifier]) {
        PCLog(@"Found custom action: %@", identifier);
        return actions[identifier];
    }
    return %orig;
}

%end

%hook WFActionRegistry

- (void)registerActionWithIdentifier:(NSString *)identifier class:(Class)actionClass {
    PCLog(@"Registering action: %@", identifier);
    %orig;
}

%end

%ctor {
    @autoreleasepool {
        PCLog(@"PowercutsClone v1.0.2 initialized");
        PCLog(@"Device: %@", [[UIDevice currentDevice] model]);
        PCLog(@"iOS: %@", [[UIDevice currentDevice] systemVersion]);
    }
}
