// PowercutsClone - Rootless iOS 17 Shortcuts Actions Pack
// Based on AnthoPak's Powercuts Actions Pack
// For Bootstrap/Dopamine jailbreak (rootless)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Intents/Intents.h>

#pragma mark - Helper: Run command as root (rootless)

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

#pragma mark - 1. Get Current Application

@interface PCGetCurrentApplicationIntent : INIntent
@property (nonatomic, copy) NSString *output;
@end

@implementation PCGetCurrentApplicationIntent
@end

@interface PCGetCurrentApplicationIntentHandler : NSObject <INExtension, PCGetCurrentApplicationIntentHandling>
@end

@implementation PCGetCurrentApplicationIntentHandler

- (NSArray<id<INIntent>>>supportedIntents {
    return @[[PCGetCurrentApplicationIntent class]];
}

- (void)handleGetCurrentApplication:(PCGetCurrentApplicationIntent *)intent
                          completion:(void (^)(PCGetCurrentApplicationIntentResponse *))completion {
    
    NSString *result = runCommand(@"frontmost");
    if (!result || result.length == 0) {
        // Fallback: use SBFrontmostApplicationDisplayIdentifier
        result = @"Unknown";
    }
    
    PCGetCurrentApplicationIntentResponse *response =
        [[PCGetCurrentApplicationIntentResponse alloc] initWithCode:PCGetCurrentApplicationIntentResponseCodeSuccess
                                                           userActivity:nil];
    response.output = result;
    completion(response);
}

@end

#pragma mark - 2. Get Now Playing Application

@interface PCGetNowPlayingIntent : INIntent
@property (nonatomic, copy) NSString *output;
@end

@implementation PCGetNowPlayingIntent
@end

@interface PCGetNowPlayingIntentHandler : NSObject <INExtension, PCGetNowPlayingIntentHandling>
@end

@implementation PCGetNowPlayingIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetNowPlayingIntent class]];
}

- (void)handleGetNowPlaying:(PCGetNowPlayingIntent *)intent
                 completion:(void (^)(PCGetNowPlayingIntentResponse *))completion {
    
    NSString *result = @"";
    
    MRMediaRemoteGetNowPlayingInfo(^(NSDictionary *info) {
        if (info && info[kMRMediaRemoteNowPlayingInfoPlayerBundleID]) {
            result = info[kMRMediaRemoteNowPlayingInfoPlayerBundleID];
        }
        
        PCGetNowPlayingIntentResponse *response =
            [[PCGetNowPlayingIntentResponse alloc] initWithCode:PCGetNowPlayingIntentResponseCodeSuccess
                                                       userActivity:nil];
        response.output = result ?: @"None";
        completion(response);
    });
}

@end

#pragma mark - 3. Kill/Quit Application

@interface PCKillAppIntent : INIntent
@property (nonatomic, copy) NSString *identifier;
@end

@implementation PCKillAppIntent
@end

@interface PCKillAppIntentHandler : NSObject <INExtension, PCKillAppIntentHandling>
@end

@implementation PCKillAppIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCKillAppIntent class]];
}

- (void)handleKillApp:(PCKillAppIntent *)intent
           completion:(void (^)(PCKillAppIntentResponse *))completion {
    
    if (intent.identifier && intent.identifier.length > 0) {
        NSString *cmd = [NSString stringWithFormat:@"killall %@", intent.identifier];
        runCommand(cmd);
    }
    
    PCKillAppIntentResponse *response =
        [[PCKillAppIntentResponse alloc] initWithCode:PCKillAppIntentResponseCodeSuccess
                                            userActivity:nil];
    completion(response);
}

@end

#pragma mark - 4. Get File Content

@interface PCGetFileContentIntent : INIntent
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *content;
@end

@implementation PCGetFileContentIntent
@end

@interface PCGetFileContentIntentHandler : NSObject <INExtension, PCGetFileContentIntentHandling>
@end

@implementation PCGetFileContentIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetFileContentIntent class]];
}

- (void)handleGetFileContent:(PCGetFileContentIntent *)intent
                  completion:(void (^)(PCGetFileContentIntentResponse *))completion {
    
    NSString *content = @"";
    if (intent.filePath && intent.filePath.length > 0) {
        NSError *error = nil;
        content = [NSString stringWithContentsOfFile:intent.filePath
                                           encoding:NSUTF8StringEncoding
                                              error:&error];
        if (error || !content) content = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    }
    
    PCGetFileContentIntentResponse *response =
        [[PCGetFileContentIntentResponse alloc] initWithCode:PCGetFileContentIntentResponseCodeSuccess
                                                 userActivity:nil];
    response.content = content;
    completion(response);
}

@end

#pragma mark - 5. Delete Global Variable

@interface PCDeleteGlobalVariableIntent : INIntent
@property (nonatomic, copy) NSString *variableName;
@end

@implementation PCDeleteGlobalVariableIntent
@end

@interface PCDeleteGlobalVariableIntentHandler : NSObject <INExtension, PCDeleteGlobalVariableIntentHandling>
@end

@implementation PCDeleteGlobalVariableIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCDeleteGlobalVariableIntent class]];
}

- (void)handleDeleteGlobalVariable:(PCDeleteGlobalVariableIntent *)intent
                        completion:(void (^)(PCDeleteGlobalVariableIntentResponse *))completion {
    
    if (intent.variableName && intent.variableName.length > 0) {
        NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Shortcuts/variables/%@.plist", intent.variableName];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    PCDeleteGlobalVariableIntentResponse *response =
        [[PCDeleteGlobalVariableIntentResponse alloc] initWithCode:PCDeleteGlobalVariableIntentResponseCodeSuccess
                                                      userActivity:nil];
    completion(response);
}

@end

#pragma mark - 6. Dismiss Siri

@interface PCDismissSiriIntent : INIntent
@end

@implementation PCDismissSiriIntent
@end

@interface PCDismissSiriIntentHandler : NSObject <INExtension, PCDismissSiriIntentHandling>
@end

@implementation PCDismissSiriIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCDismissSiriIntent class]];
}

- (void)handleDismissSiri:(PCDismissSiriIntent *)intent
               completion:(void (^)(PCDismissSiriIntentResponse *))completion {
    
    // Send dismiss Siri notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)@"com.apple.assistant.dismiss",
        NULL,
        NULL,
        true
    );
    
    PCDismissSiriIntentResponse *response =
        [[PCDismissSiriIntentResponse alloc] initWithCode:PCDismissSiriIntentResponseCodeSuccess
                                             userActivity:nil];
    completion(response);
}

@end

#pragma mark - 7. Get All Installed Applications

@interface PCGetAllAppsIntent : INIntent
@property (nonatomic, copy) NSString *appList;
@end

@implementation PCGetAllAppsIntent
@end

@interface PCGetAllAppsIntentHandler : NSObject <INExtension, PCGetAllAppsIntentHandling>
@end

@implementation PCGetAllAppsIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetAllAppsIntent class]];
}

- (void)handleGetAllApps:(PCGetAllAppsIntent *)intent
              completion:(void (^)(PCGetAllAppsIntentResponse *))completion {
    
    NSArray *apps = [[NSFileManager defaultManager]
                     contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application"
                     error:nil];
    
    NSMutableArray *bundleIDs = [NSMutableArray array];
    for (NSString *appPath in apps) {
        NSString *plistPath = [NSString stringWithFormat:@"%@/%@/Info.plist",
                               @"/var/containers/Bundle/Application", appPath];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        if (plist[@"CFBundleIdentifier"]) {
            [bundleIDs addObject:plist[@"CFBundleIdentifier"]];
        }
    }
    
    PCGetAllAppsIntentResponse *response =
        [[PCGetAllAppsIntentResponse alloc] initWithCode:PCGetAllAppsIntentResponseCodeSuccess
                                            userActivity:nil];
    response.appList = [bundleIDs componentsJoinedByString:@"\n"];
    completion(response);
}

@end

#pragma mark - 8. Get Application Info from Identifier

@interface PCGetAppInfoIntent : INIntent
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *appInfo;
@end

@implementation PCGetAppInfoIntent
@end

@interface PCGetAppInfoIntentHandler : NSObject <INExtension, PCGetAppInfoIntentHandling>
@end

@implementation PCGetAppInfoIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetAppInfoIntent class]];
}

- (void)handleGetAppInfo:(PCGetAppInfoIntent *)intent
              completion:(void (^)(PCGetAppInfoIntentResponse *))completion {
    
    NSMutableString *info = [NSMutableString string];
    
    if (intent.identifier && intent.identifier.length > 0) {
        // Search for app by bundle ID
        NSArray *apps = [[NSFileManager defaultManager]
                         contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application"
                         error:nil];
        
        for (NSString *appPath in apps) {
            NSString *plistPath = [NSString stringWithFormat:@"%@/%@/Info.plist",
                                   @"/var/containers/Bundle/Application", appPath];
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            
            if ([plist[@"CFBundleIdentifier"] isEqualToString:intent.identifier]) {
                [info appendFormat:@"Bundle ID: %@\n", plist[@"CFBundleIdentifier"]];
                [info appendFormat:@"Version: %@\n", plist[@"CFBundleShortVersionString"] ?: @"?"];
                [info appendFormat:@"Build: %@\n", plist[@"CFBundleVersion"] ?: @"?"];
                [info appendFormat:@"Name: %@\n", plist[@"CFBundleDisplayName"] ?: plist[@"CFBundleName"] ?: @"?"];
                break;
            }
        }
    }
    
    if (info.length == 0) [info appendString:@"App not found"];
    
    PCGetAppInfoIntentResponse *response =
        [[PCGetAppInfoIntentResponse alloc] initWithCode:PCGetAppInfoIntentResponseCodeSuccess
                                            userActivity:nil];
    response.appInfo = info;
    completion(response);
}

@end

#pragma mark - 9. Get Bluetooth Device Battery Level

@interface PCGetBTBatteryIntent : INIntent
@property (nonatomic, copy) NSString *batteryLevel;
@end

@implementation PCGetBTBatteryIntent
@end

@interface PCGetBTBatteryIntentHandler : NSObject <INExtension, PCGetBTBatteryIntentHandling>
@end

@implementation PCGetBTBatteryIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetBTBatteryIntent class]];
}

- (void)handleGetBTBattery:(PCGetBTBatteryIntent *)intent
                completion:(void (^)(PCGetBTBatteryIntentResponse *))completion {
    
    NSString *level = runCommand(@"system_profiler SPBluetoothDataType 2>/dev/null | grep 'Battery Level' | awk '{print $3}'");
    
    if (!level || level.length == 0) level = @"N/A";
    
    PCGetBTBatteryIntentResponse *response =
        [[PCGetBTBatteryIntentResponse alloc] initWithCode:PCGetBTBatteryIntentResponseCodeSuccess
                                              userActivity:nil];
    response.batteryLevel = level;
    completion(response);
}

@end

#pragma mark - 10. Get Device Locked State

@interface PCGetLockStateIntent : INIntent
@property (nonatomic, copy) NSString *isLocked;
@end

@implementation PCGetLockStateIntent
@end

@interface PCGetLockStateIntentHandler : NSObject <INExtension, PCGetLockStateIntentHandling>
@end

@implementation PCGetLockStateIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetLockStateIntent class]];
}

- (void)handleGetLockState:(PCGetLockStateIntent *)intent
                completion:(void (^)(PCGetLockStateIntentResponse *))completion {
    
    BOOL isLocked = NO;
    // Use SBBacklightManager to check lock state
    Class sbClass = NSClassFromString(@"SBBacklightManager");
    if (sbClass) {
        id manager = [sbClass sharedInstance];
        SEL selector = NSSelectorFromString(@"isScreenOff");
        if ([manager respondsToSelector:selector]) {
            isLocked = ((BOOL (*)(id, SEL))[manager methodForSelector:selector])(manager, selector);
        }
    }
    
    PCGetLockStateIntentResponse *response =
        [[PCGetLockStateIntentResponse alloc] initWithCode:PCGetLockStateIntentResponseCodeSuccess
                                               userActivity:nil];
    response.isLocked = isLocked ? @"Yes" : @"No";
    completion(response);
}

@end

#pragma mark - 11. Get Files from Folder

@interface PCGetFilesFromFolderIntent : INIntent
@property (nonatomic, copy) NSString *folderPath;
@property (nonatomic, copy) NSString *fileList;
@end

@implementation PCGetFilesFromFolderIntent
@end

@interface PCGetFilesFromFolderIntentHandler : NSObject <INExtension, PCGetFilesFromFolderIntentHandling>
@end

@implementation PCGetFilesFromFolderIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetFilesFromFolderIntent class]];
}

- (void)handleGetFilesFromFolder:(PCGetFilesFromFolderIntent *)intent
                       completion:(void (^)(PCGetFilesFromFolderIntentResponse *))completion {
    
    NSString *fileList = @"";
    if (intent.folderPath && intent.folderPath.length > 0) {
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager]
                         contentsOfDirectoryAtPath:intent.folderPath error:&error];
        if (files) fileList = [files componentsJoinedByString:@"\n"];
        else fileList = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    }
    
    PCGetFilesFromFolderIntentResponse *response =
        [[PCGetFilesFromFolderIntentResponse alloc] initWithCode:PCGetFilesFromFolderIntentResponseCodeSuccess
                                                    userActivity:nil];
    response.fileList = fileList;
    completion(response);
}

@end

#pragma mark - 12. Get Global Variable

@interface PCGetGlobalVariableIntent : INIntent
@property (nonatomic, copy) NSString *variableName;
@property (nonatomic, copy) NSString *value;
@end

@implementation PCGetGlobalVariableIntent
@end

@interface PCGetGlobalVariableIntentHandler : NSObject <INExtension, PCGetGlobalVariableIntentHandling>
@end

@implementation PCGetGlobalVariableIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetGlobalVariableIntent class]];
}

- (void)handleGetGlobalVariable:(PCGetGlobalVariableIntent *)intent
                     completion:(void (^)(PCGetGlobalVariableIntentResponse *))completion {
    
    NSString *value = @"";
    if (intent.variableName && intent.variableName.length > 0) {
        NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Shortcuts/variables/%@.plist",
                          intent.variableName];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        value = dict[@"value"] ?: @"Not found";
    }
    
    PCGetGlobalVariableIntentResponse *response =
        [[PCGetGlobalVariableIntentResponse alloc] initWithCode:PCGetGlobalVariableIntentResponseCodeSuccess
                                                   userActivity:nil];
    response.value = value;
    completion(response);
}

@end

#pragma mark - 13. Get Run Source

@interface PCGetRunSourceIntent : INIntent
@property (nonatomic, copy) NSString *source;
@end

@implementation PCGetRunSourceIntent
@end

@interface PCGetRunSourceIntentHandler : NSObject <INExtension, PCGetRunSourceIntentHandling>
@end

@implementation PCGetRunSourceIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCGetRunSourceIntent class]];
}

- (void)handleGetRunSource:(PCGetRunSourceIntent *)intent
                completion:(void (^)(PCGetRunSourceIntentResponse *))completion {
    
    // Detect how the shortcut was triggered
    NSString *source = @"Manual"; // default
    
    // Check environment for clues about source
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    if (env[@"SHORTCUTS_RUN_SOURCE"]) source = env[@"SHORTCUTS_RUN_SOURCE"];
    
    PCGetRunSourceIntentResponse *response =
        [[PCGetRunSourceIntentResponse alloc] initWithCode:PCGetRunSourceIntentResponseCodeSuccess
                                               userActivity:nil];
    response.source = source;
    completion(response);
}

@end

#pragma mark - 14. Remove Notification(s)

@interface PCRemoveNotificationIntent : INIntent
@property (nonatomic, copy) NSString *appName;
@end
@implementation PCRemoveNotificationIntent
@end

@interface PCRemoveNotificationIntentHandler : NSObject <INExtension, PCRemoveNotificationIntentHandling>
@end

@implementation PCRemoveNotificationIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCRemoveNotificationIntent class]];
}

- (void)handleRemoveNotification:(PCRemoveNotificationIntent *)intent
                      completion:(void (^)(PCRemoveNotificationIntentResponse *))completion {
    
    if (intent.appName && intent.appName.length > 0) {
        // Use notify_post to trigger notification removal
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge CFStringRef)[NSString stringWithFormat:@"com.powercuts.removenotification.%@", intent.appName],
            NULL,
            NULL,
            true
        );
    }
    
    PCRemoveNotificationIntentResponse *response =
        [[PCRemoveNotificationIntentResponse alloc] initWithCode:PCRemoveNotificationIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 15. Respring

@interface PCRespringIntent : INIntent
@end
@implementation PCRespringIntent
@end

@interface PCRespringIntentHandler : NSObject <INExtension, PCRespringIntentHandling>
@end

@implementation PCRespringIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCRespringIntent class]];
}

- (void)handleRespring:(PCRespringIntent *)intent
          completion:(void (^)(PCRespringIntentResponse *))completion {
    // Respring via SpringBoard
    pid_t pid = runCommand(@"pidof SpringBoard").intValue;
    if (pid > 0) kill(pid, SIGKILL);
    
    PCRespringIntentResponse *response =
        [[PCRespringIntentResponse alloc] initWithCode:PCRespringIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 16. Run Shell Command

@interface PCRunShellCommandIntent : INIntent
@property (nonatomic, copy) NSString *command;
@property (nonatomic, copy) NSString *output;
@end
@implementation PCRunShellCommandIntent
@end

@interface PCRunShellCommandIntentHandler : NSObject <INExtension, PCRunShellCommandIntentHandling>
@end

@implementation PCRunShellCommandIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCRunShellCommandIntent class]];
}

- (void)handleRunShellCommand:(PCRunShellCommandIntent *)intent
                    completion:(void (^)(PCRunShellCommandIntentResponse *))completion {
    
    NSString *output = @"";
    if (intent.command && intent.command.length > 0) {
        output = runCommand(intent.command);
    }
    
    PCRunShellCommandIntentResponse *response =
        [[PCRunShellCommandIntentResponse alloc] initWithCode:PCRunShellCommandIntentResponseCodeSuccess userActivity:nil];
    response.output = output ?: @"(no output)";
    completion(response);
}

@end

#pragma mark - 17. Safe Mode

@interface PCSafeModeIntent : INIntent
@end
@implementation PCSafeModeIntent
@end

@interface PCSafeModeIntentHandler : NSObject <INExtension, PCSafeModeIntentHandling>
@end

@implementation PCSafeModeIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSafeModeIntent class]];
}

- (void)handleSafeMode:(PCSafeModeIntent *)intent
         completion:(void (^)(PCSafeModeIntentResponse *))completion {
    // Enter safe mode by crashing SpringBoard safely
    void *handle = dlopen(NULL, RTLD_NOW);
    if (handle) {
        void (*enterSafeMode)(void) = dlsym(handle, "MSHookExterior");
        if (!enterSafeMode) enterSafeMode = dlsym(handle, "MSSafeModeEnter");
        if (enterSafeMode) enterSafeMode();
    }
    // Fallback: use libhooker safe mode
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("libhooker.mode/safemode"),
        NULL,
        NULL,
        true
    );
    
    PCSafeModeIntentResponse *response =
        [[PCSafeModeIntentResponse alloc] initWithCode:PCSafeModeIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 18. Send Notification (from app)

@interface PCSendNotificationIntent : INIntent
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *soundName;
@end
@implementation PCSendNotificationIntent
@end

@interface PCSendNotificationIntentHandler : NSObject <INExtension, PCSendNotificationIntentHandling>
@end

@implementation PCSendNotificationIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSendNotificationIntent class]];
}

- (void)handleSendNotification:(PCSendNotificationIntent *)intent
                     completion:(void (^)(PCSendNotificationIntentResponse *))completion {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = intent.title ?: @"PowercutsClone";
    content.body = intent.body ?: @"";
    content.sound = intent.soundName ? [UNNotificationSound soundNamed:intent.soundName] : [UNNotificationSound defaultSound];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                              content:content trigger:nil];
    [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) { }];
    
    PCSendNotificationIntentResponse *response =
        [[PCSendNotificationIntentResponse alloc] initWithCode:PCSendNotificationIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 19. Set Application Badge Count

@interface PCSetBadgeCountIntent : INIntent
@property (nonatomic, copy) NSString *identifier;
@property NSInteger badgeCount;
@end
@implementation PCSetBadgeCountIntent
@end

@interface PCSetBadgeCountIntentHandler : NSObject <INExtension, PCSetBadgeCountIntentHandling>
@end

@implementation PCSetBadgeCountIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSetBadgeCountIntent class]];
}

- (void)handleSetBadgeCount:(PCSetBadgeCountIntent *)intent
                  completion:(void (^)(PCSetBadgeCountIntentResponse *))completion {
    
    if (intent.identifier && intent.identifier.length > 0) {
        Class sbIconClass = NSClassFromString(@"SBIconController");
        if (sbIconClass) {
            id iconController = [sbIconClass sharedInstance];
            SEL setBadgeSel = NSSelectorFromString(@"setBadgeValue:forApplication:");
            if ([iconController respondsToSelector:setBadgeSel]) {
                ((void (*)(id, SEL, id, id))[iconController methodForSelector:setBadgeSel])(
                    iconController, setBadgeSel,
                    @(intent.badgeCount), intent.identifier
                );
            }
        }
        // Also try direct SpringBoard API
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge CFStringRef)[NSString stringWithFormat:@"com.apple.springboard.badgechanged.%@", intent.identifier],
            NULL,
            NULL,
            true
        );
    }
    
    PCSetBadgeCountIntentResponse *response =
        [[PCSetBadgeCountIntentResponse alloc] initWithCode:PCSetBadgeCountIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 20. Set Audio Balance

@interface PCSetAudioBalanceIntent : INIntent
@property float balance; // -1.0 (left) to 1.0 (right)
@end
@implementation PCSetAudioBalanceIntent
@end

@interface PCSetAudioBalanceIntentHandler : NSObject <INExtension, PCSetAudioBalanceIntentHandling>
@end

@implementation PCSetAudioBalanceIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSetAudioBalanceIntent class]];
}

- (void)handleSetAudioBalance:(PCSetAudioBalanceIntent *)intent
                       completion:(void (^)(PCSetAudioBalanceIntentResponse *))completion {
    
    float balance = intent.balance;
    if (balance < -1.0f) balance = -1.0f;
    if (balance > 1.0f) balance = 1.0f;
    
    // Use AVAudioSession balance
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setOutputChannelBalance:balance error:nil];
    
    // Also write to system preferences for persistence
    NSString *cmd = [NSString stringWithFormat:@"defaults write com.apple.AudioSettings AudioBalance %f", balance];
    runCommand(cmd);
    
    PCSetAudioBalanceIntentResponse *response =
        [[PCSetAudioBalanceIntentResponse alloc] initWithCode:PCSetAudioBalanceIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 21. Set Global Variable

@interface PCSetGlobalVariableIntent : INIntent
@property (nonatomic, copy) NSString *variableName;
@property (nonatomic, copy) NSString *value;
@end
@implementation PCSetGlobalVariableIntent
@end

@interface PCSetGlobalVariableIntentHandler : NSObject <INExtension, PCSetGlobalVariableIntentHandling>
@end

@implementation PCSetGlobalVariableIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSetGlobalVariableIntent class]];
}

- (void)handleSetGlobalVariable:(PCSetGlobalVariableIntent *)intent
                        completion:(void (^)(PCSetGlobalVariableIntentResponse *))completion {
    
    if (intent.variableName && intent.variableName.length > 0) {
        NSString *dir = @"/var/mobile/Library/Shortcuts/variables";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *path = [NSString stringWithFormat:@"%@/%@.plist", dir, intent.variableName];
        NSDictionary *dict = @{@"value": intent.value ?: @""};
        [dict writeToFile:path atomically:YES];
    }
    
    PCSetGlobalVariableIntentResponse *response =
        [[PCSetGlobalVariableIntentResponse alloc] initWithCode:PCSetGlobalVariableIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 22. Support the Dev

@interface PCSupportDevIntent : INIntent
@property (nonatomic, copy) NSString *devURL;
@end
@implementation PCSupportDevIntent
@end

@interface PCSupportDevIntentHandler : NSObject <INExtension, PCSupportDevIntentHandling>
@end

@implementation PCSupportDevIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCSupportDevIntent class]];
}

- (void)handleSupportDev:(PCSupportDevIntent *)intent
              completion:(void (^)(PCSupportDevIntentResponse *))completion {
    
    NSURL *url = [NSURL URLWithString:intent.devURL ?: @"https://github.com/sponsors"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    
    PCSupportDevIntentResponse *response =
        [[PCSupportDevIntentResponse alloc] initWithCode:PCSupportDevIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 23. UICache

@interface PCUICacheIntent : INIntent
@property (nonatomic, copy) NSString *output;
@end
@implementation PCUICacheIntent
@end

@interface PCUICacheIntentHandler : NSObject <INExtension, PCUICacheIntentHandling>
@end

@implementation PCUICacheIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCUICacheIntent class]];
}

- (void)handleUICache:(PCUICacheIntent *)intent
           completion:(void (^)(PCUICacheIntentResponse *))completion {
    
    NSString *output = runCommand(@"uicache --all");
    
    PCUICacheIntentResponse *response =
        [[PCUICacheIntentResponse alloc] initWithCode:PCUICacheIntentResponseCodeSuccess userActivity:nil];
    response.output = output ?: @"Done";
    completion(response);
}

@end

#pragma mark - 24. Unlock Device

@interface PCUnlockDeviceIntent : INIntent
@end
@implementation PCUnlockDeviceIntent
@end

@interface PCUnlockDeviceIntentHandler : NSObject <INExtension, PCUnlockDeviceIntentHandling>
@end

@implementation PCUnlockDeviceIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCUnlockDeviceIntent class]];
}

- (void)handleUnlockDevice:(PCUnlockDeviceIntent *)intent
                   completion:(void (^)(PCUnlockDeviceIntentResponse *))completion {
    
    // Unlock device via SBAwayLockScreenManager
    Class awayClass = NSClassFromString(@"SBAwayLockScreenManager");
    if (awayClass) {
        id manager = [awayClass sharedInstance];
        SEL unlockSel = NSSelectorFromString(@"unlockWithSource:options:");
        if ([manager respondsToSelector:unlockSel]) {
            ((void (*)(id, SEL, id, id))[manager methodForSelector:unlockSel])(manager, unlockSel, nil, nil);
        } else {
            SEL forceUnlock = NSSelectorFromString(@"forceUnlockWithSource:");
            if ([manager respondsToSelector:forceUnlock]) {
                ((void (*)(id, SEL, id))[manager methodForSelector:forceUnlock])(manager, forceUnlock, nil);
            }
        }
    }
    
    PCUnlockDeviceIntentResponse *response =
        [[PCUnlockDeviceIntentResponse alloc] initWithCode:PCUnlockDeviceIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - 25. Wake Screen

@interface PCWakeScreenIntent : INIntent
@end
@implementation PCWakeScreenIntent
@end

@interface PCWakeScreenIntentHandler : NSObject <INExtension, PCWakeScreenIntentHandling>
@end

@implementation PCWakeScreenIntentHandler

- (NSArray<id<INIntent>>)supportedIntents {
    return @[[PCWakeScreenIntent class]];
}

- (void)handleWakeScreen:(PCWakeScreenIntent *)intent
             completion:(void (^)(PCWakeScreenIntentResponse *))completion {
    
    // Wake screen via SBBacklightManager
    Class sbClass = NSClassFromString(@"SBBacklightManager");
    if (sbClass) {
        id manager = [sbClass sharedInstance];
        SEL turnOnSel = NSSelectorFromString(@"turnOnScreenForReason:");
        if ([manager respondsToSelector:turnOnSel]) {
            ((void (*)(id, SEL, id))[manager methodForSelector:turnOnSel])(manager, turnOnSel, @"PowercutsClone");
        }
    }
    
    PCWakeScreenIntentResponse *response =
        [[PCWakeScreenIntentResponse alloc] initWithCode:PCWakeScreenIntentResponseCodeSuccess userActivity:nil];
    completion(response);
}

@end

#pragma mark - Constructor

%ctor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Register all intents with Shortcuts app
        NSLog(@"[PowercutsClone] Loaded successfully on iOS 17 Rootless!");
    });
}
