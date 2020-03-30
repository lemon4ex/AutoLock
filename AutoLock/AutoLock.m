//
//  AutoLock.m
//  AutoLock
//
//  Created by h4ck on 2020/3/30.
//  Copyright (c) 2020 ___ORGANIZATIONNAME___. All rights reserved.
//

#import "AutoLock.h"
#import <CaptainHook/CaptainHook.h>

@interface MCProfileConnection : NSObject
+ (instancetype)sharedConnection;
- (NSDictionary *)effectiveParametersForValueSetting:(NSString *)arg1;
- (void)setValue:(id)arg1 forSetting:(NSString *)arg2;
@end

@interface SBUIController : NSObject
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (void)ACPowerChanged; // 交流电源(插入USB)状态改变通知
- (_Bool)isOnAC; // 是否已连接电源(插入USB)，状态改变时候可使用此方法获取当前状态
-(int)batteryCapacityAsPercentage;
@end

static NSDictionary *readPerferences(){
    NSString *settingsPath = @"/var/mobile/Library/Preferences/net.ymlab.dev.AutoLock.plist";
    return [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
}

static int g_origMaxInactivity = 30; ///< 默认的锁屏时间

CHDeclareClass(SBUIController)
CHMethod0(void, SBUIController, ACPowerChanged){
    CHSuper0(SBUIController, ACPowerChanged);
    
    NSDictionary *prefs = readPerferences();
    if([prefs[@"autoLockEnable"] boolValue]){
        MCProfileConnection *profileConn = [objc_getClass("MCProfileConnection") sharedConnection];
        int maxInactivityValue = INT32_MAX;
        NSString *alertBody = nil;
        if([self isOnAC]){
            NSDictionary *params = [profileConn effectiveParametersForValueSetting:@"maxInactivity"];
            int maxInactivity = [params[@"value"] intValue];
            if(maxInactivity != INT32_MAX){
                g_origMaxInactivity = maxInactivity;
            }
            maxInactivityValue = INT32_MAX;
            alertBody = @"禁用";
        }else{
            maxInactivityValue = g_origMaxInactivity;
            alertBody = @"启用";
        }

        if(maxInactivityValue > 0){
            [profileConn setValue:[NSNumber numberWithInt:maxInactivityValue] forSetting:@"maxInactivity"];
        }
    }
}

CHConstructor // code block that runs immediately upon load
{
    NSLog(@"++++++++ AutoLock loaded ++++++++");
    
    CHLoadLateClass(SBUIController);
    CHHook0(SBUIController, ACPowerChanged);
}
