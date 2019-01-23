//
//  XCFAVPlayerControllerAnimator.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/20.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerControllerAnimator.h"

@implementation XCFAVPlayerControllerAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSParameterAssert(self.avPlayerController && self.animateImageView);

    if (self.isPresenting) {
        [self animatePresentTransition:transitionContext];
    } else {
        [self animateDismissTransition:transitionContext];
    }
}

- (void)animatePresentTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];

    UIViewController *presentingController = self.presentingController;
    UIView *presentingView = presentingController.view;

    CGRect sourceFrame = [containerView convertRect:self.sourceFrame fromView:presentingView];

    self.avPlayerController.view.frame = containerView.frame;
    [containerView addSubview:self.avPlayerController.view];

    CGRect destinationFrame = self.avPlayerController.view.bounds;
    UIImage *animateImage = self.animateImageView.image;
    CGFloat destinationHeight = animateImage.size.height / animateImage.size.width * destinationFrame.size.width;
    CGFloat paddingY = (destinationFrame.size.height - destinationHeight) / 2;
    destinationFrame = CGRectInset(destinationFrame, 0, paddingY);
    destinationFrame = [containerView convertRect:destinationFrame fromView:self.avPlayerController.view];

    self.animateImageView.frame = sourceFrame;
    [containerView addSubview:self.animateImageView];
    [self.avPlayerController beginPresentAnimation];

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
        animations:^{
            self.animateImageView.frame = destinationFrame;
        }
        completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
}

- (void)animateDismissTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *presentingController = self.presentingController;
    UIView *presentingView = presentingController.view;

    CGRect sourceFrame = [containerView convertRect:self.sourceFrame fromView:self.avPlayerController.view];
    CGRect destinationFrame = [containerView convertRect:self.destinationFrame fromView:presentingView];

    self.animateImageView.frame = sourceFrame;
    [containerView addSubview:self.animateImageView];

    [self.avPlayerController beginDismissAnimation];

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
        animations:^{
            self.animateImageView.frame = destinationFrame;
            self.avPlayerController.view.alpha = 0;
        }
        completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
}

- (void)animationEnded:(BOOL)transitionCompleted {
    if (self.isPresenting) {
        [self.avPlayerController endPresentAnimation];
    } else {
        [self.avPlayerController endDismissAnimation];
    }
    [self.animateImageView removeFromSuperview];
}

@end
