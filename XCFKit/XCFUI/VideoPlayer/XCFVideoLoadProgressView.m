//
//  XCFVideoLoadProgressView.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/18.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoLoadProgressView.h"

@implementation XCFVideoLoadProgressView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.opaque = NO;
}

- (void)drawRect:(CGRect)rect {
    CGFloat diameter = MIN(rect.size.width, rect.size.height);
    CGRect displayRect = (CGRect){rect.origin,CGSizeMake(diameter, diameter)};
    displayRect = CGRectOffset(displayRect, (rect.size.width - diameter) / 2, (rect.size.height - diameter)/2);
    
    // fill background
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    CGContextAddEllipseInRect(ctx, displayRect);
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.8);
    CGContextFillPath(ctx);

    CGPoint center = CGPointMake(displayRect.origin.x + diameter/2, displayRect.origin.y + diameter/2);
    if (self.status == XCFVideoLoadStatusPlay) {
        // drwa play button
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, center.x - diameter / 8, center.y - diameter / 8 * 1.732);
        CGContextAddLineToPoint(ctx, center.x - diameter / 8, center.y + diameter / 8 * 1.732);
        CGContextAddLineToPoint(ctx, center.x + diameter / 4, center.y);
        CGContextClosePath(ctx);
    } else {
        CGFloat lineWidth = 2;
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGFloat start = (self.progress - 0.25) * 2 * M_PI;
        CGFloat end = 0.75 * 2 * M_PI;
        CGContextAddArc(ctx, center.x, center.y, (diameter / 2) - lineWidth, start, end, 0);
        CGContextClosePath(ctx);
    }
    
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.8);
    CGContextFillPath(ctx);
}

- (void) setProgress:(CGFloat)progress
{
    CGFloat p = MIN(MAX(0, progress), 1);
    if (p != _progress) {
        _progress = p;
        
        if (self.status == XCFVideoLoadStatusProgress) {
            [self setNeedsDisplay];
        }
    }
}

- (void) setStatus:(XCFVideoLoadStatus)status
{
    if (_status != status) {
        _status = status;
        [self setNeedsDisplay];
    }
}

- (void) tintColorDidChange
{
    [super tintColorDidChange];
    [self setNeedsDisplay];
}

#pragma mark - size

- (CGSize) sizeThatFits:(CGSize)size
{
    CGFloat width = MIN(size.width, size.height);
    return CGSizeMake(width, width);
}

- (CGSize) intrinsicContentSize
{
    return CGSizeMake(40, 40);
}

@end
