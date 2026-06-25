#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 简单测试 Tweak - 验证加载和 Hook
// 日志宏 - 同时输出到 syslog 和文件

static void PCLogToFile(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *logPath = @"/var/mobile/powercuts_test.log";
    NSString *logEntry = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logEntry writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSLog(@"[PowercutsClone] %@", message);
}

// ========================================
// Hook 1: SpringBoard 启动
// ========================================
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 {
    PCLogToFile(@"SpringBoard launched!");
    %orig;
}

%end

// ========================================
// Hook 2: 任何 App 启动
// ========================================
%hook UIApplication

- (void)_applicationDidFinishLaunching:(id)arg1 {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    PCLogToFile(@"App launched: %@", bundleId ?: @"unknown");
    %orig;
}

%end

// ========================================
// Hook 3: Shortcuts Action 查询
// ========================================
%hook WFAction

+ (id)actionWithIdentifier:(NSString *)identifier {
    PCLogToFile(@"WFAction requested: %@", identifier);
    return %orig;
}

%end

// ========================================
// Hook 4: WFActionRegistry
// ========================================
%hook WFActionRegistry

- (void)registerActionWithIdentifier:(NSString *)identifier class:(Class)cls {
    PCLogToFile(@"Registering action: %@ -> %@", identifier, NSStringFromClass(cls));
    %orig;
}

%end

// ========================================
// Constructor
// ========================================
%ctor {
    @autoreleasepool {
        PCLogToFile(@"==========================================");
        PCLogToFile(@"PowercutsClone TEST TWEAK LOADED!");
        PCLogToFile(@"Device: %@", [[UIDevice currentDevice] model]);
        PCLogToFile(@"iOS Version: %@", [[UIDevice currentDevice] systemVersion]);
        PCLogToFile(@"==========================================");
    }
}
