//
//  XCFVideoLoadProgressView.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/18.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoLoadProgressView.h"

@implementation XCFVideoLoadProgressView

- (void)drawRect:(CGRect)rect {
    CGFloat diameter = MIN(rect.size.width, rect.size.height);
    CGRect displayRect = (CGRect){rect.origin,CGSizeMake(diameter, diameter)};
    displayRect = CGRectOffset(displayRect, (rect.size.width - diameter) / 2, (rect.size.height - diameter)/2);
    
    // fill background
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(ctx, displayRect);
    CGContextSetFillColor(ctx, CGColorGetComponents([self.tintColor CGColor]));
    CGContextFillPath(ctx);
    
    CGPoint center = CGPointMake(displayRect.origin.x + diameter/2, displayRect.origin.y + diameter/2);
    if (self.status == XCFVideoLoadStatusPlay) {
        // drwa play button
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, center.x - diameter / 6, center.y - diameter / 6 * 1.732);
        CGContextAddLineToPoint(ctx, center.x - diameter / 6, center.y + diameter / 6 * 1.732);
        CGContextAddLineToPoint(ctx, center.x + diameter / 3, 0);
        CGContextClosePath(ctx);
        CGContextSetFillColor(ctx, CGColorGetComponents([UIColor.blackColor CGColor]));
        CGContextFillPath(ctx);
    } else {
        CGFloat lineWidth = 2;
        CGContextAddArc(ctx, center.x, center.y, (diameter / 2) - lineWidth, self.progress * 2 * M_PI, 2 * M_PI, 1);
        CGContextSetFillColor(ctx, CGColorGetComponents([UIColor.blackColor CGColor]));
        CGContextFillPath(ctx);
    }
}

- (void) setProgress:(CGFloat)progress
{
    CGFloat p = MIN(MAX(0, progress), 1);
    if (p != _progress) {
        _progress = p;
        
        if (self.status == XCFVideoLoadStatusLoading) {
            [self setNeedsDisplay];
        }
    }
}

- (void) tintColorDidChange
{
    [super tintColorDidChange];
    [self setNeedsDisplay];
}

@end
