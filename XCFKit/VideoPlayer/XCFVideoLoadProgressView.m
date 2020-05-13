//
//  XCFVideoLoadProgressView.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/18.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoLoadProgressView.h"

@interface XCFVideoLoadProgressView ()

@property (nonatomic, strong) CAShapeLayer *loadingAnimationLayer;

@end

@implementation XCFVideoLoadProgressView {
    CGFloat _animationLayerLineWidth;
    
    
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialization];
}

- (void)initialization {
    self.opaque = NO;
    _animationLayerLineWidth = 6;
    self.userInteractionEnabled = NO;
}

- (void)drawRect:(CGRect)rect {
    CGFloat diameter = MIN(rect.size.width, rect.size.height);
    CGRect displayRect = (CGRect){rect.origin, CGSizeMake(diameter, diameter)};
    displayRect = CGRectOffset(displayRect, (rect.size.width - diameter) / 2, (rect.size.height - diameter) / 2);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    if (self.status == XCFVideoLoadStatusPlay) {
        // drwa play button
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *image  = [UIImage imageNamed:@"Video.bundle/playButtonLarge" inBundle: bundle compatibleWithTraitCollection:nil];
        CGImageRef reft = image.CGImage;
        CGContextDrawImage(ctx, displayRect, reft);
    } else {
        CGFloat borderWidth = _animationLayerLineWidth;
        CGContextAddEllipseInRect(ctx, CGRectInset(displayRect, borderWidth / 2, borderWidth / 2));
        CGContextSetLineWidth(ctx, borderWidth);
        CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 0.2);
        CGContextStrokePath(ctx);
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _loadingAnimationLayer.frame = self.bounds;
    _loadingAnimationLayer.path = [self loadingAnimationLayerPath];
}

- (void)setProgress:(CGFloat)progress {
    CGFloat p = MIN(MAX(0, progress), 1);
    if (p != _progress) {
        _progress = p;

        if (self.status == XCFVideoLoadStatusProgress) {
            [self updateLoadingLayer];
        }
    }
}

- (void)setStatus:(XCFVideoLoadStatus)status {
    if (_status != status) {
        _status = status;
        [self setNeedsDisplay];

        [self updateLoadingLayer];

        if (_status == XCFVideoLoadStatusLoading) {
            [self animateLoadingLayer];
        } else {
            [self endAnimateLoadingLayer];
        }
    }
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self setNeedsDisplay];
}

#pragma mark - loading && progress

- (CGPathRef)loadingAnimationLayerPath {
    CGRect rect = self.bounds;
    CGFloat diameter = MIN(rect.size.width, rect.size.height);
    CGRect displayRect = (CGRect){rect.origin, CGSizeMake(diameter, diameter)};
    displayRect = CGRectOffset(displayRect, (rect.size.width - diameter) / 2, (rect.size.height - diameter) / 2);
    CGPoint displayCenter = CGPointMake(displayRect.origin.x + diameter / 2, displayRect.origin.y + diameter / 2);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:displayCenter
                                                        radius:diameter / 2 - _animationLayerLineWidth / 2
                                                    startAngle:M_PI_2 * 3
                                                      endAngle:M_PI_2 * 3 + M_PI * 2
                                                     clockwise:YES];
    return path.CGPath;
}

- (CAShapeLayer *)loadingAnimationLayer {
    if (!_loadingAnimationLayer) {
        _loadingAnimationLayer = [CAShapeLayer layer];
        _loadingAnimationLayer.frame = self.bounds;
        _loadingAnimationLayer.actions = @{@"path": [NSNull null]};

        _loadingAnimationLayer.fillColor = [UIColor clearColor].CGColor;

        _loadingAnimationLayer.lineWidth = _animationLayerLineWidth;
        _loadingAnimationLayer.strokeColor = [UIColor whiteColor].CGColor;

        _loadingAnimationLayer.lineCap = kCALineCapRound;

        _loadingAnimationLayer.path = [self loadingAnimationLayerPath];

        [self.layer addSublayer:_loadingAnimationLayer];
    }

    return _loadingAnimationLayer;
}

- (void)updateLoadingLayer {
    switch (self.status) {
        case XCFVideoLoadStatusPlay:
            _loadingAnimationLayer.hidden = YES;
            break;
        case XCFVideoLoadStatusProgress:
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.loadingAnimationLayer.strokeStart = 0;
            self.loadingAnimationLayer.strokeEnd = self.progress;
            [CATransaction commit];
            self.loadingAnimationLayer.hidden = NO;
            break;
        case XCFVideoLoadStatusLoading:
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.loadingAnimationLayer.strokeStart = 0;
            self.loadingAnimationLayer.strokeEnd = 1 / 4.0;
            [CATransaction commit];
            self.loadingAnimationLayer.hidden = NO;
            break;
        default:
            break;
    }
}

- (void)animateLoadingLayer {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 0.68;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = CGFLOAT_MAX;

    [self endAnimateLoadingLayer];
    [self.loadingAnimationLayer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)endAnimateLoadingLayer {
    [_loadingAnimationLayer removeAnimationForKey:@"rotationAnimation"];
}

#pragma mark - size

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat width = MIN(size.width, size.height);
    return CGSizeMake(width, width);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(40, 40);
}

@end
