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
    
    BOOL isDestinationFrameVisble = NO;
    
    if (self.isPresenting) {
        self.avPlayerController.view.frame = containerView.bounds;
        [containerView addSubview:self.avPlayerController.view];
        
        // 手动设置成全屏
        self.destinationFrame = containerView.bounds;
        isDestinationFrameVisble = YES;
    } else {
        isDestinationFrameVisble = CGRectIntersectsRect(containerView.bounds, self.destinationFrame);
        if (isDestinationFrameVisble) {
            self.avPlayerController.view.alpha = 0;
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
                         } else {
                             self.avPlayerController.view.alpha = 0;
                         }
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:[transitionContext transitionWasCancelled]];
                     }];
}

- (void) animationEnded:(BOOL)transitionCompleted
{
    [self.animateImageView removeFromSuperview];
    self.avPlayerController.view.alpha = 1;
}

@end
