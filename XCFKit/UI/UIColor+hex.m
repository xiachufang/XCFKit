//
//  UIColor+hex.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+(UIColor *) xcf_colorWithHexString:(NSString *)stringWithHex {
    NSString *hexString;
    if ([stringWithHex hasPrefix:@"#"])
        hexString = [stringWithHex substringFromIndex:1];
    else if([stringWithHex hasPrefix:@"0x"])
        hexString = [stringWithHex substringFromIndex:2];
    else
        hexString = stringWithHex;
    UIColor *returnColor;
    @try {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        unsigned hex;
        if (![scanner scanHexInt:&hex]) return nil;
        int r = (hex >> 16) & 0xFF;
        int g = (hex >> 8 ) & 0xFF;
        int b = (hex      ) & 0xFF;
        
        returnColor =  [UIColor colorWithRed:r / 255.0f
                                       green:g / 255.0f
                                        blue:b / 255.0f
                                       alpha:1.0f];
        
    }
    @catch (NSException *exception) {
        returnColor = [UIColor clearColor];
    }
    @finally {
        return returnColor;
    }
}

+ (NSString *) xcf_hexStringWithColor:(UIColor *)color {
    NSString *hex = nil;
    
    if (color && CGColorGetNumberOfComponents(color.CGColor) == 4) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);

        CGFloat red, green, blue;
        red = roundf(components[0] * 255.0);
        green = roundf(components[1] * 255.0);
        blue = roundf(components[2] * 255.0);
        
        hex = [[NSString alloc]initWithFormat:@"#%02x%02x%02x", (int)red, (int)green, (int)blue];
    }
    
    return hex;
}

+ (UIColor *) xcf_contrastColorWithColor:(UIColor *)color {
    if (color && CGColorGetNumberOfComponents(color.CGColor) == 4) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        
        CGFloat d = 0;
        CGFloat luma = 0.229 * components[0] + 0.587 * components[1] + 0.114 * components[2];
        CGFloat alpha = components[3];
        
        if (luma < 0.5) d = 1;
        
        return [UIColor colorWithRed:d green:d blue:d alpha:alpha];
    }
    
    return color;
}

@end
