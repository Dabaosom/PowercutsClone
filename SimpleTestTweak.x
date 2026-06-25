#import <Foundation/Foundation.h>

%ctor {
    NSString *logPath = @"/var/mobile/tweak_loaded.txt";
    NSString *msg = [NSString stringWithFormat:@"TWEAK LOADED AT: %@\n", [NSDate date]];
    NSError *err = nil;
    [msg writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    NSLog(@"[SimpleTest] Tweak loaded!");
}
