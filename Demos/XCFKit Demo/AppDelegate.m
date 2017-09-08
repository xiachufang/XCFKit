//
//  AppDelegate.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "AppDelegate.h"
#import <XCFKit/XCFStringKeywordTransformer.h>

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface XCFTestKeyordProvider : NSObject<XCFStringKeywordDataProvider>
@property (nonatomic, strong) NSArray<NSString *> *keywords;
@end

@implementation XCFTestKeyordProvider
- (NSString *) valueForKeyword:(NSString *)keyword
{
    return @"null";
}

- (BOOL) shouldHandleString:(NSString *)string
{
    return YES;
}
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NS_VALID_UNTIL_END_OF_SCOPE XCFTestKeyordProvider *provider_0 = [XCFTestKeyordProvider new];
    provider_0.keywords = @[@"__\\w*?__"];
    XCFStringKeywordTransformer *t = [XCFStringKeywordTransformer transformerWithDataProviders:@[provider_0]];
    t.matchCase = YES;
    
    NSString *test = @"http://www.xiachufang.com?idfa=__IDFA__&version=__VERSION__&width=__WIDTH__&height=__DEVICE_HEIGHT__&flag=__FLAG__";
    __block NSString *transformed = nil;
    uint64_t time = dispatch_benchmark(1000, ^{
        transformed = [t transformString:test];
    });
    NSLog(@"time : %llu transformed : %@",time,transformed);
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
