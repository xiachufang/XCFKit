//
//  UIColor+XCFAppearance.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UIColor+XCFAppearance.h"
#import "UIColor+Hex.h"

@implementation UIColor (XCFAppearance)

+ (instancetype)xcf_navigationBarBlackTintColor
{
    return [UIColor xcf_colorWithHexString:@"#38382F"];
}

+ (instancetype)xcf_mainBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#FAFAF8"];
}

+ (UIColor *)xcf_subBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#EFEFEA"];
}

+ (instancetype)xcf_grayBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#F7F7F7"];
}

+ (instancetype)xcf_searchBarTextFieldBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#F0F0EF"];
}

+ (instancetype)xcf_mainTextColor
{
    return [UIColor xcf_colorWithHexString:@"#383831"];
}

+ (instancetype)xcf_supplementaryTextColor
{
    return [UIColor xcf_colorWithHexString:@"#95958F"];
}

+ (instancetype)xcf_linkColor
{
    return [UIColor xcf_colorWithHexString:@"#FA6650"];
}

+ (instancetype)xcf_highlightLinkColor
{
    return [UIColor xcf_colorWithHexString:@"#FF1610"];
}

+ (instancetype)xcf_separatorColor
{
    return [UIColor xcf_colorWithHexString:@"#E5E5E3"];
}

+ (instancetype)xcf_blueColor
{
    return [UIColor xcf_colorWithHexString:@"#6DC4E5"];
}

+ (instancetype)xcf_lightBlueBackgroundColor {
    return [UIColor xcf_colorWithHexString:@"#E8F8FD"];
}

+ (instancetype)xcf_yellowButtonAndLabelBGColor
{
    return [UIColor xcf_colorWithHexString:@"#FFBB00"];
}

+ (instancetype)xcf_yellowTextColor
{
    return [UIColor xcf_colorWithHexString:@"#FF9900"];
}

+ (instancetype)xcf_grayColor
{
    return [UIColor xcf_colorWithHexString:@"#C6C6BD"];
}

+ (instancetype)xcf_greenColor
{
    return [UIColor xcf_colorWithHexString:@"#3EAE68"];
}

+ (instancetype)xcf_greenHighlightedColor
{
    return [UIColor xcf_colorWithHexString:@"#2C9E53"];
}

+ (instancetype)xcf_graySelectedBorder{
    return [UIColor xcf_colorWithHexString:@"#EAEAE0"];
}

+ (instancetype)xcf_yellowBackgroundColor{
    return [UIColor xcf_colorWithHexString:@"#EAEAC6"];
}

+ (instancetype)xcf_blueBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#72A3D3"];
}

+ (instancetype)xcf_blueHighlightedBackgroundColor
{
    return [UIColor xcf_colorWithHexString:@"#4A6C8E"];
}

+ (instancetype)xcf_selectedButtonColor
{
    return [UIColor xcf_colorWithHexString:@"#C6C6BD"];
}

+ (instancetype)xcf_wechatGreenColor
{
    return [UIColor xcf_colorWithHexString:@"#6fbd53"];
}

+ (instancetype)xcf_followGaryColor
{
    return [UIColor xcf_colorWithHexString:@"#dddddd"];
}
@end
