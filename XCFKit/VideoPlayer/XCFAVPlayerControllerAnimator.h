//
//  XCFAVPlayerControllerAnimator.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/20.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCFAVPlayerController.h"

@interface XCFAVPlayerControllerAnimator : NSObject<UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) XCFAVPlayerController *avPlayerController;
@property (nonatomic, weak) UIViewController *presentingController;
@property (nonatomic, assign) BOOL isPresenting;

@property (nonatomic, strong) UIImageView *animateImageView;
@property (nonatomic, assign) CGRect sourceFrame;
@property (nonatomic, assign) CGRect destinationFrame;

@end
