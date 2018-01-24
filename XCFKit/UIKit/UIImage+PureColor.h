//
//  UIImage+PureColor.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (PureColor)

+ (UIImage *) xcf_imageWithColor:(UIColor *)color;

+ (UIImage *) xcf_imageWithColor:(UIColor *)color size:(CGSize)size;

@end
