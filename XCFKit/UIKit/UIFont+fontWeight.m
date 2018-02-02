//
//  UIFont+fontWeight.m
//  xcf-iphone
//
//  Created by Li Guoyin on 16/6/29.
//
//

#import "UIFont+fontWeight.h"

@implementation UIFont (fontWeight)

+ (NSDictionary<NSString *,id> *) xcf_defaultSystemFontAttribute
{
    static NSDictionary *attribute = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *systemFont = [UIFont systemFontOfSize:10];
        UIFontDescriptor *descriptor = systemFont.fontDescriptor;
        attribute = descriptor.fontAttributes;
    });
    
    return attribute;
}

+ (NSString *) lightSystemFontName
{
    static NSString *lightFontName = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *systemFont = [UIFont systemFontOfSize:10];
        NSString *fontName = systemFont.fontName;
        NSArray *components = [fontName componentsSeparatedByString:@"-"];
        if (components.count == 2) {
            lightFontName = [NSString stringWithFormat:@"%@-Light",components.firstObject];
        }
    });
    
    return lightFontName;
}

+ (NSString *) mediumSystemFontName
{
    static NSString *mediumFontName = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *systemFont = [UIFont systemFontOfSize:10];
        NSString *fontName = systemFont.fontName;
        NSArray *components = [fontName componentsSeparatedByString:@"-"];
        if (components.count == 2) {
            mediumFontName = [NSString stringWithFormat:@"%@-Medium",components.firstObject];
        }
    });
    
    return mediumFontName;
}

+ (NSString *) heavySystemFontName
{
    static NSString *heavySystemFontName = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *systemFont = [UIFont systemFontOfSize:10];
        NSString *fontName = systemFont.fontName;
        NSArray *components = [fontName componentsSeparatedByString:@"-"];
        if (components.count == 2) {
            heavySystemFontName = [NSString stringWithFormat:@"%@-Heavy",components.firstObject];
        }
    });
    
    return heavySystemFontName;
}

+ (UIFont *) xcf_mediumSystemFontWithSize:(CGFloat)size
{
    if (@available(iOS 8.2,*)) { // >= iOS 8.2
        return [self systemFontOfSize:size weight:UIFontWeightMedium];
    } else {
        UIFont *mediumFont = nil;
        NSString *fontName = [self mediumSystemFontName];
        if (fontName) {
            mediumFont = [UIFont fontWithName:fontName size:size];
        }
        
        if (!mediumFont) {
            mediumFont = [UIFont systemFontOfSize:size];
        }
        
        return mediumFont;
    }
}

+ (UIFont *) xcf_lightSystemFontWithSize:(CGFloat)size
{
    if (@available(iOS 8.2,*)) {
        return [self systemFontOfSize:size weight:UIFontWeightLight];
    } else {
        UIFont *lightFont = nil;
        NSString *fontName = [self lightSystemFontName];
        if (fontName) {
            lightFont = [UIFont fontWithName:fontName size:size];
        }
        
        if (!lightFont) {
            lightFont = [UIFont systemFontOfSize:size];
        }
        
        return lightFont;

    }
}

+ (UIFont *) xcf_regularSystemFontWithSize:(CGFloat)size
{
    return [self systemFontOfSize:size];
}

+ (UIFont *) xcf_boldSystemFontWithSize:(CGFloat)size
{
    return [self boldSystemFontOfSize:size];
}

+ (UIFont *) xcf_heavySystemFontWithSize:(CGFloat)size
{
    if (@available(iOS 8.2,*)) {
        return [self systemFontOfSize:size weight:UIFontWeightHeavy];
    } else {
        return [UIFont boldSystemFontOfSize:size];
    }
}
@end
