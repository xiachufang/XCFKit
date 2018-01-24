//
//  UIView+XCFHeartbeat.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/23.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UIView+XCFHeartbeat.h"

@implementation UIView (XCFHeartbeat)

- (void) xcf_appleHeartbeatAnimation
{
    NSString *animationKey = NSStringFromSelector(_cmd);
    [self.layer removeAnimationForKey:animationKey];
    
    // 先小再大再复原
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = @[@(0.96),
                               @(0.9),
                               @(1.06),
                               @(1.06),
                               @(1)];
    
    NSTimeInterval duration = 0.1 + (0.2) + 0.01 + 0.1;
    CGFloat keytime_1 = 0.1 / duration;
    CGFloat keytime_2 = (0.2) / duration + keytime_1;
    CGFloat keytime_3 = 0.01 / duration + keytime_2;
    CGFloat keytime_4 = 1;
    bounceAnimation.keyTimes = @[@0,
                                 @(keytime_1),
                                 @(keytime_2),
                                 @(keytime_3),
                                 @(keytime_4)];

    bounceAnimation.duration = duration;
    
    CAMediaTimingFunction *timeFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    bounceAnimation.timingFunctions = @[timeFunction,
                                        timeFunction,
                                        timeFunction,
                                        timeFunction];
    bounceAnimation.removedOnCompletion = YES;
    [self.layer addAnimation:bounceAnimation forKey:animationKey];
}

@end
