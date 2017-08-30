//
//  AppDelegate.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "AppDelegate.h"
#import <XCFKit/XCFStringKeywordTransformer.h>

@interface XCFTestKeyordProvider : NSObject<XCFStringKeywordDataProvider>
@property (nonatomic, strong) NSArray<NSString *> *keywords;
@property (nonatomic, strong) NSString *value;
@end

@implementation XCFTestKeyordProvider
- (NSString *) valueForKeyword:(NSString *)keyword
{
    return self.value;
}
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NS_VALID_UNTIL_END_OF_SCOPE XCFTestKeyordProvider *provider_0 = [XCFTestKeyordProvider new];
    provider_0.keywords = @[@"__IDFA__"];
    provider_0.value = [[NSUUID UUID] UUIDString];
    XCFTestKeyordProvider *provider_1 = [XCFTestKeyordProvider new];
    provider_1.keywords = @[@"{IDFA}",@"{VERSION}"];
    provider_1.value = @"provider_1";
    XCFTestKeyordProvider *provider_2 = [XCFTestKeyordProvider new];
    provider_2.keywords = @[@"{WIDTH}",@"{HEIGHT}"];
    provider_2.value = @"provider_2";
    XCFTestKeyordProvider *provider_3 = [XCFTestKeyordProvider new];
    provider_3.keywords = @[@"{FLAG}",@"{NAME}"];
    provider_3.value = @"provider_3";
    XCFTestKeyordProvider *provider_4 = [XCFTestKeyordProvider new];
//    provider_4.keywords = @[@"\\{[^}]*+\\}"];
    provider_4.keywords = @[@"{*}"];
    provider_4.value = @"YIPLEE";
    XCFStringKeywordTransformer *t = [XCFStringKeywordTransformer transformerWithDataProviders:@[provider_0,provider_1,provider_2,provider_3,provider_4]];
    t.matchCase = NO;
    NSString *test = @"http://www.xiachufang.com?idfa={{IDFA}&version={VERSION}&width={WIDTH}&height={HEIGHT}&flag={FLAG}&name={NAME}&query={OTHER}{NAME}&idfa=__IDFA__hahahahah";
    NSString *transformed = [t transformString:test];
    NSLog(@"transformed : %@",transformed);
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
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
