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
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = level;
    root.window = window;
    window.rootViewController = root;
    
    [window makeKeyAndVisible];
    
    if (!controller.popoverPresentationController.sourceView) {
        controller.popoverPresentationController.sourceView = root.view;
    }
    [root presentViewController:controller
                       animated:animated
                     completion:^{
                     }];
    
    return root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:^{
        self.window.rootViewController = nil;
        self.window = nil;
        
        if (completion) {
            completion();
        }
    }];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

@end
