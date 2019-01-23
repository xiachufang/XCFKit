//
//  XCFImageContentMaskLayer.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFImageContentMaskLayer.h"
#import <UIKit/UIKit.h>

@implementation XCFImageContentMaskLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        CGColorRef startColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
        CGColorRef endColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        self.colors = @[(__bridge id)startColor, (__bridge id)endColor];
        self.startPoint = CGPointMake(0.5, 0);
        self.endPoint = CGPointMake(0.5, 1);
    }
    return self;
}

@end

CAGradientLayer *XCFCreateImageContentMaskLayerWithColors(CGColorRef startColor, CGColorRef endColor) {
    CAGradientLayer *layer = [CAGradientLayer new];
    layer.colors = @[(__bridge id)startColor, (__bridge id)endColor];
    layer.startPoint = CGPointMake(0.5, 0);
    layer.endPoint = CGPointMake(0.5, 1);
    //    layer.drawsAsynchronously = YES;
    layer.actions = @{@"bounds": [NSNull null],
                      @"frame": [NSNull null],
                      @"position": [NSNull null],
                      @"hidden": [NSNull null]};

    layer.shouldRasterize = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;
    return layer;
}

CAGradientLayer *XCFCreateImageContentMaskLayer() {

    CGColorRef startColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
    CGColorRef endColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    CAGradientLayer *layer = XCFCreateImageContentMaskLayerWithColors(startColor, endColor);
    return layer;
}
