//
//  XCFWindowContextController.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/11/7.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 *  这个类用来在一个新的 window 中 present 一个 controller
 *  调用 - dismissViewControllerAnimated:completion: 方法来 dismiss
 */
@interface XCFWindowContextController : UIViewController

@property (nonatomic, weak, readonly) UIWindow *window;

+ (instancetype) presentController:(UIViewController *)controller
                       windowLevel:(UIWindowLevel)level
                          animated:(BOOL)animated;

@end
