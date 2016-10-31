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

@end
