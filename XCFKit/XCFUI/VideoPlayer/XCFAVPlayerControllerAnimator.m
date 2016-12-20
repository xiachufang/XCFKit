//
//  XCFAVPlayerControllerAnimator.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/20.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerControllerAnimator.h"

@implementation XCFAVPlayerControllerAnimator

- (NSTimeInterval) transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(self.avPlayerController && self.animateImageView);
    
    UIView *containerView = [transitionContext containerView];
    UIView *presentedView = self.avPlayerController.view;
    
    BOOL isDestinationFrameVisble = NO;
    
    if (self.isPresenting) {
        presentedView.frame = containerView.bounds;
        [containerView addSubview:presentedView];
        
        // 手动设置成全屏
        self.destinationFrame = containerView.bounds;
        isDestinationFrameVisble = YES;
        
        for (UIView *subview in presentedView.subviews) {
            subview.alpha = 0;
        }
    } else {
        isDestinationFrameVisble = CGRectIntersectsRect(containerView.bounds, self.destinationFrame);
        
        if (isDestinationFrameVisble) {
            presentedView.alpha = 0;
            for (UIView *subview in presentedView.subviews) {
                subview.alpha = 0;
            }
        }
    }
    
    if (isDestinationFrameVisble) {
        [containerView addSubview:self.animateImageView];
        self.animateImageView.frame = self.sourceFrame;
    }
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         if (isDestinationFrameVisble) {
                             self.animateImageView.frame = self.destinationFrame;
                         }
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];
}

- (void) animationEnded:(BOOL)transitionCompleted
{
    if (self.isPresenting) {
        for (UIView *subview in self.avPlayerController.view.subviews) {
            subview.alpha = 1;
        }
    }
    
    [self.animateImageView removeFromSuperview];
}

@end
