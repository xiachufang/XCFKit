//
//  UIColor+hex.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *) xcf_colorWithHexString:(NSString *)stringWithHex;

+ (NSString *) xcf_hexStringWithColor:(UIColor *)color;

+ (UIColor *) xcf_contrastColorWithColor:(UIColor *)color;

@end
