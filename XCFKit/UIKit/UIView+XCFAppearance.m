//
//  UIView+XCFAppearance.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/31.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UIView+XCFAppearance.h"

@implementation UIView (XCFAppearance)

- (void)setXcf_cornerRadius:(CGFloat)xcf_cornerRadius
{
    self.layer.cornerRadius = xcf_cornerRadius;
}

- (CGFloat)xcf_cornerRadius
{
    return self.layer.cornerRadius;
}

- (void)setXcf_borderColor:(UIColor *)xcf_borderColor
{
    self.layer.borderColor = xcf_borderColor.CGColor;
}

- (UIColor *)xcf_borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setXcf_borderWidth:(CGFloat)xcf_borderWidth
{
    self.layer.borderWidth = xcf_borderWidth;
}

- (CGFloat)xcf_borderWidth
{
    return self.layer.borderWidth;
}

@end
