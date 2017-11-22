//
//  UIScrollView+XCFKit.m
//  XCFKit iOS
//
//  Created by Li Guoyin on 2017/11/22.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "UIScrollView+XCFKit.h"

@implementation UIScrollView (XCFKit)

- (UIEdgeInsets) xcf_contentInset
{
#ifdef __IPHONE_11_0
    if (@available(iOS 11,*)) {
        return self.adjustedContentInset;
    } else {
        return self.contentInset;
    }
#else
    return self.contentInset;
#endif
}

@end
