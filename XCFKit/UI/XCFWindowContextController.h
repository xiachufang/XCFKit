//
//  XCFWindowContextController.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/11/7.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCFWindowContextController : UIViewController

@property (nonatomic, weak, readonly) UIWindow *window;

+ (instancetype) presentController:(UIViewController *)controller
                       windowLevel:(UIWindowLevel)level
                          animated:(BOOL)animated;

@end
