//
//  XCFWindowContextController.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/11/7.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFWindowContextController.h"

@interface XCFWindowContextController ()

@property (nonatomic, weak, readwrite) UIWindow *window;

@end

@implementation XCFWindowContextController

+ (instancetype) presentController:(UIViewController *)controller windowLevel:(UIWindowLevel)level animated:(BOOL)animated
{
    NSParameterAssert(controller);
    
    XCFWindowContextController *root = [self new];
    
    UIWindow *window = [UIWindow new];
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = level;
    root.window = window;
    window.rootViewController = root;
    
    [window makeKeyAndVisible];
    
    [root presentViewController:controller
                       animated:animated
                     completion:^{
                         window.backgroundColor = [UIColor blackColor];
                     }];
    
    return root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    self.window.backgroundColor = [UIColor clearColor];
    [super dismissViewControllerAnimated:flag completion:^{
        self.window.rootViewController = nil;
        self.window = nil;
        
        if (completion) {
            completion();
        }
    }];
}

@end
